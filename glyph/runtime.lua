local CallbackBus = require("glyph.callback_bus")
local Layout = require("glyph.layout")
local Responsive = require("glyph.responsive")
local Style = require("glyph.style")
local theme = require("glyph.theme")

local runtimeCallbacks = {
  "beforeUpdate",
  "afterUpdate",
  "beforeRender",
  "afterRender",
  "layout",
  "focusChanged",
  "hoverChanged",
  "event",
}

local Runtime = {}
Runtime.__index = Runtime

local function sameDeps(a, b)
  if a == b then
    return true
  end

  if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then
    return false
  end

  for index = 1, #a do
    if a[index] ~= b[index] then
      return false
    end
  end

  return true
end

local function absoluteWalk(node, parentX, parentY, fn)
  local layout = node.layout or {}
  local x = parentX + (layout.x or 0)
  local y = parentY + (layout.y or 0)

  fn(node, x, y)

  for _, child in ipairs(node.children or {}) do
    absoluteWalk(child, x, y, fn)
  end
end

local function assignPaths(node, path, parent)
  node.path = path
  node.parent = parent

  for index, child in ipairs(node.children or {}) do
    assignPaths(child, path .. "." .. index, node)
  end
end

local function findByPath(node, path)
  if not node or not path then
    return nil
  end

  if node.path == path then
    return node
  end

  for _, child in ipairs(node.children or {}) do
    local found = findByPath(child, path)
    if found then
      return found
    end
  end

  return nil
end

local function contains(node, x, y, absX, absY)
  local layout = node.layout or {}
  return x >= absX and y >= absY and x <= absX + (layout.width or 0) and y <= absY + (layout.height or 0)
end

function Runtime.new()
  return setmetatable({
    root = nil,
    rootComponent = nil,
    hooks = {},
    hookCursor = 0,
    effects = {},
    pendingEffects = {},
    needsRender = true,
    bus = CallbackBus.new(runtimeCallbacks),
    theme = theme,
    hoverNode = nil,
    hoverPath = nil,
    focusNode = nil,
    mouseDownNode = nil,
    mouseDownPath = nil,
    scrollOffsets = {},
    inputCursors = {},
    focusPath = nil,
    memoCache = setmetatable({}, { __mode = "k" }),
    styleCache = {},
    previousStyles = {},
    animatedStyles = {},
    styleClock = 0,
    lastDt = 0,
    responsive = Responsive.new(),
    love = nil,
  }, Runtime)
end

function Runtime:setLove(loveModule)
  self.love = loveModule
end

function Runtime:register(name, fn, opts)
  return self.bus:register(name, fn, opts)
end

function Runtime:dispatch(name, ...)
  return self.bus:dispatch(name, ...)
end

function Runtime:markDirty()
  self.needsRender = true
end

function Runtime:useState(initial)
  self.hookCursor = self.hookCursor + 1
  local index = self.hookCursor

  if self.hooks[index] == nil then
    if type(initial) == "function" then
      self.hooks[index] = initial()
    else
      self.hooks[index] = initial
    end
  end

  local function setState(nextValue)
    if type(nextValue) == "function" then
      self.hooks[index] = nextValue(self.hooks[index])
    else
      self.hooks[index] = nextValue
    end

    self:markDirty()
  end

  return self.hooks[index], setState
end

function Runtime:useEffect(fn, deps)
  self.hookCursor = self.hookCursor + 1
  local index = self.hookCursor
  local previous = self.effects[index]

  if previous == nil or not sameDeps(previous.deps, deps) then
    self.pendingEffects[#self.pendingEffects + 1] = {
      index = index,
      fn = fn,
      deps = deps,
      cleanup = previous and previous.cleanup or nil,
    }
  end
end

function Runtime:runEffects()
  for _, effect in ipairs(self.pendingEffects) do
    if type(effect.cleanup) == "function" then
      effect.cleanup()
    end

    local cleanup = effect.fn()
    self.effects[effect.index] = {
      deps = effect.deps,
      cleanup = cleanup,
    }
  end

  self.pendingEffects = {}
end

function Runtime:build(component)
  self.rootComponent = component or self.rootComponent
  if not self.rootComponent then
    return nil
  end

  self.hookCursor = 0
  local root = self.rootComponent()
  assignPaths(root, "0", nil)
  self.root = root
  self.focusNode = findByPath(root, self.focusPath)
  self.hoverNode = findByPath(root, self.hoverPath)
  self.mouseDownNode = findByPath(root, self.mouseDownPath)
  self.needsRender = false
  self:runEffects()
  return root
end

function Runtime:layoutRoot(root)
  local context = {
    theme = self.theme,
    measureText = function(text, props)
      local love = self.love or _G.love
      local font = props.font or self.theme.font or (love and love.graphics and love.graphics.getFont and love.graphics.getFont())
      if font and font.getWidth and font.getHeight then
        return font:getWidth(text), font:getHeight()
      end

      return #text * 7, self.theme.lineHeight
    end,
  }

  Layout.compute(root, context)
  self.bus:dispatch("layout", root)
end

function Runtime:update(dt)
  self.lastDt = dt or 0
  self.styleClock = self.styleClock + (dt or 0)
  self.bus:dispatch("beforeUpdate", dt)
  self.bus:dispatch("afterUpdate", dt)
end

function Runtime:render(component)
  self.bus:dispatch("beforeRender")
  local root = self.root

  if self.needsRender or component ~= self.rootComponent or self.root == nil then
    root = self:build(component)
  end

  if root then
    self:layoutRoot(root)
    self:draw(root)
  end

  self.bus:dispatch("afterRender", root)
end

function Runtime:hitTest(x, y)
  local hit = nil

  if not self.root then
    return nil
  end

  absoluteWalk(self.root, 0, 0, function(node, absX, absY)
    if node.props and node.props.interactive ~= false and contains(node, x, y, absX, absY) then
      hit = node
      node.absoluteX = absX
      node.absoluteY = absY
    end
  end)

  return hit
end

function Runtime:setHover(node)
  if self.hoverNode ~= node then
    local previous = self.hoverNode
    self.hoverNode = node
    self.hoverPath = node and node.path or nil
    self.bus:dispatch("hoverChanged", node, previous)
  end
end

function Runtime:setFocus(node)
  if self.focusNode ~= node then
    local previous = self.focusNode
    self.focusNode = node
    self.focusPath = node and node.path or nil
    self.bus:dispatch("focusChanged", node, previous)
    self:markDirty()
  end
end

function Runtime:cursorKey(node)
  return node and node.path or nil
end

function Runtime:mousemoved(x, y)
  local node = self:hitTest(x, y)
  self:setHover(node)
  self.bus:dispatch("event", "mousemoved", x, y, node)
end

function Runtime:mousepressed(x, y, button)
  local node = self:hitTest(x, y)
  self.mouseDownNode = node
  self.mouseDownPath = node and node.path or nil
  self:setHover(node)

  if node and (node.type == "input" or node.type == "button" or node.props.focusable) then
    self:setFocus(node)
    if node.type == "input" then
      self.inputCursors[self:cursorKey(node)] = #tostring(node.props.value or "")
    end
  else
    self:setFocus(nil)
  end

  if node and node.props and type(node.props.onMousePressed) == "function" then
    node.props.onMousePressed(x, y, button, node)
  end

  self.bus:dispatch("event", "mousepressed", x, y, button, node)
  self:markDirty()
end

function Runtime:mousereleased(x, y, button)
  local node = self:hitTest(x, y)
  local down = self.mouseDownNode
  local downPath = self.mouseDownPath
  self.mouseDownNode = nil
  self.mouseDownPath = nil

  if node and (node == down or node.path == downPath) and node.type == "button" and node.props and not node.props.disabled and type(node.props.onClick) == "function" then
    node.props.onClick(node)
  end

  if node and node.props and type(node.props.onMouseReleased) == "function" then
    node.props.onMouseReleased(x, y, button, node)
  end

  self.bus:dispatch("event", "mousereleased", x, y, button, node)
  self:markDirty()
end

function Runtime:wheelmoved(dx, dy)
  local node = self.hoverNode
  while node do
    if node.type == "scrollView" then
      local scrollKey = node.path
      self.scrollOffsets[scrollKey] = math.max(0, (self.scrollOffsets[scrollKey] or 0) - dy * 24)
      self:markDirty()
      break
    end
    node = node.parent
  end

  self.bus:dispatch("event", "wheelmoved", dx, dy, node)
end

function Runtime:textinput(text)
  local node = self.focusNode
  if node and node.type == "input" and node.props and type(node.props.onChange) == "function" then
    local value = tostring(node.props.value or "")
    local key = self:cursorKey(node)
    local cursor = self.inputCursors[key] or #value
    local nextValue = value:sub(1, cursor) .. text .. value:sub(cursor + 1)
    self.inputCursors[key] = cursor + #text
    node.props.onChange(nextValue)
    self:markDirty()
  end

  self.bus:dispatch("event", "textinput", text, node)
end

function Runtime:keypressed(key)
  local node = self.focusNode

  if node and node.type == "input" and node.props and type(node.props.onChange) == "function" then
    local value = tostring(node.props.value or "")
    local cursorKey = self:cursorKey(node)
    local cursor = self.inputCursors[cursorKey] or #value
    if key == "backspace" then
      if cursor > 0 then
        node.props.onChange(value:sub(1, cursor - 1) .. value:sub(cursor + 1))
        self.inputCursors[cursorKey] = cursor - 1
        self:markDirty()
      end
    elseif key == "delete" then
      if cursor < #value then
        node.props.onChange(value:sub(1, cursor) .. value:sub(cursor + 2))
        self:markDirty()
      end
    elseif key == "left" then
      self.inputCursors[cursorKey] = math.max(0, cursor - 1)
      self:markDirty()
    elseif key == "right" then
      self.inputCursors[cursorKey] = math.min(#value, cursor + 1)
      self:markDirty()
    end
  elseif node and node.type == "button" and (key == "return" or key == "space") and node.props and type(node.props.onClick) == "function" then
    node.props.onClick(node)
    self:markDirty()
  end

  self.bus:dispatch("event", "keypressed", key, node)
end

local function color(love, value)
  if love and love.graphics and value then
    love.graphics.setColor(value[1] or 1, value[2] or 1, value[3] or 1, value[4] or 1)
  end
end

local function drawRect(love, mode, x, y, width, height, radius)
  if love and love.graphics then
    love.graphics.rectangle(mode, x, y, width, height, radius or 0, radius or 0)
  end
end

local function withOpacity(value, opacity)
  if not Style.isColor(value) then
    return value
  end

  return {
    value[1],
    value[2],
    value[3],
    (value[4] or 1) * (opacity or 1),
  }
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function lerpColor(a, b, t)
  return {
    lerp(a[1] or 1, b[1] or 1, t),
    lerp(a[2] or 1, b[2] or 1, t),
    lerp(a[3] or 1, b[3] or 1, t),
    lerp(a[4] or 1, b[4] or 1, t),
  }
end

function Runtime:animatedStyle(node, resolved)
  local transition = resolved.transition
  if type(transition) ~= "table" or not node.path then
    self.previousStyles[node.path] = Style.copyValue(resolved)
    return resolved
  end

  local previous = self.previousStyles[node.path]
  local animated = Style.copyValue(resolved)

  if previous then
    for field, duration in pairs(transition) do
      if type(duration) == "number" and duration > 0 then
        local from = previous[field]
        local to = resolved[field]

        if type(from) == "number" and type(to) == "number" then
          local t = math.min(1, (self.lastDt > 0 and self.lastDt or 1 / 60) / duration)
          animated[field] = lerp(from, to, t)
        elseif Style.isColor(from) and Style.isColor(to) then
          local t = math.min(1, (self.lastDt > 0 and self.lastDt or 1 / 60) / duration)
          animated[field] = lerpColor(from, to, t)
        end
      end
    end
  end

  self.previousStyles[node.path] = Style.copyValue(animated)
  return animated
end

local function applyDrawState(love, style, node, runtime)
  local graphics = love and love.graphics
  if not graphics then
    return function() end
  end

  local previous = {}

  if graphics.getLineWidth and graphics.setLineWidth then
    previous.lineWidth = graphics.getLineWidth()
    local lineWidth = style.lineWidth or (style.borderWidth and style.borderWidth > 0 and style.borderWidth) or previous.lineWidth
    graphics.setLineWidth(lineWidth)
  end

  if graphics.getShader and graphics.setShader then
    previous.hasShader = true
    previous.shader = graphics.getShader()
    local shader = style.shader
    if type(shader) == "function" then
      shader = shader(node, runtime)
    end
    if shader ~= nil then
      graphics.setShader(shader)
    end
  end

  if graphics.getBlendMode and graphics.setBlendMode and style.blendMode then
    previous.blendMode, previous.alphaMode = graphics.getBlendMode()
    graphics.setBlendMode(style.blendMode)
  end

  if graphics.getFont and graphics.setFont and style.font then
    previous.font = graphics.getFont()
    graphics.setFont(style.font)
  end

  return function()
    if previous.font then
      graphics.setFont(previous.font)
    end
    if previous.blendMode then
      graphics.setBlendMode(previous.blendMode, previous.alphaMode)
    end
    if previous.hasShader then
      graphics.setShader(previous.shader)
    end
    if previous.lineWidth then
      graphics.setLineWidth(previous.lineWidth)
    end
  end
end

function Runtime:drawNode(node, x, y)
  local love = self.love or _G.love
  if not love or not love.graphics then
    return
  end

  local props = node.props or {}
  local layout = node.layout or {}
  local absX = x + (layout.x or 0)
  local absY = y + (layout.y or 0)
  local width = layout.width or 0
  local height = layout.height or 0
  local style = self:animatedStyle(node, Style.resolve(node, self))
  local restore = applyDrawState(love, style, node, self)
  local radius = style.radius or self.theme.radius
  local opacity = style.opacity or 1

  if type(props.draw) == "function" then
    props.draw(node, absX, absY, width, height, love, style)
  elseif node.type == "text" then
    color(love, withOpacity(style.color or self.theme.textColor, opacity))
    local text = tostring(node.value or "")
    if props.wrap or node.wrappedText then
      local limit = (node.wrappedText and node.wrappedText.width) or props.wrapWidth or props.width or width
      local align = props.textAlign or "left"
      if love.graphics.printf then
        love.graphics.printf(text, absX, absY, limit, align)
      else
        local lineHeight = props.lineHeight or self.theme.lineHeight
        local lines = node.wrappedText and node.wrappedText.lines or { text }
        for index, line in ipairs(lines) do
          love.graphics.print(line, absX, absY + (index - 1) * lineHeight)
        end
      end
    else
      love.graphics.print(text, absX, absY)
    end
  elseif node.type == "button" then
    if style.background then
      color(love, withOpacity(style.background, opacity))
      drawRect(love, "fill", absX, absY, width, height, radius)
    end
    if style.borderColor and (style.borderWidth or 0) > 0 then
      color(love, withOpacity(style.borderColor, opacity))
      drawRect(love, "line", absX, absY, width, height, radius)
    end
    color(love, withOpacity(style.color or self.theme.textColor, opacity))
    love.graphics.print(tostring(props.label or ""), absX + 10, absY + 5)
  elseif node.type == "input" then
    if style.background then
      color(love, withOpacity(style.background, opacity))
      drawRect(love, "fill", absX, absY, width, height, radius)
    end
    if style.borderColor and (style.borderWidth or 0) > 0 then
      color(love, withOpacity(style.borderColor, opacity))
      drawRect(love, "line", absX, absY, width, height, radius)
    end
    local value = tostring(props.value or "")
    color(love, withOpacity(value == "" and (style.placeholderColor or self.theme.mutedTextColor) or (style.color or self.theme.textColor), opacity))
    love.graphics.print(value ~= "" and value or tostring(props.placeholder or ""), absX + 8, absY + 6)
    if self.focusNode == node then
      local cursor = self.inputCursors[self:cursorKey(node)] or #value
      local prefix = value:sub(1, cursor)
      local font = love.graphics.getFont and love.graphics.getFont()
      local cursorX = absX + 8 + (font and font:getWidth(prefix) or #prefix * 7)
      color(love, withOpacity(style.cursorColor or self.theme.accentColor, opacity))
      love.graphics.rectangle("fill", cursorX, absY + 6, self.theme.inputCursorWidth, math.max(12, height - 12))
    end
  else
    if style.background then
      color(love, withOpacity(style.background, opacity))
      drawRect(love, "fill", absX, absY, width, height, radius)
    end
    if style.borderColor and (style.borderWidth or 0) > 0 then
      color(love, withOpacity(style.borderColor, opacity))
      drawRect(love, "line", absX, absY, width, height, radius)
    end
  end

  restore()

  if node.type == "scrollView" and love.graphics.push then
    love.graphics.push()
    love.graphics.setScissor(absX, absY, width, height)
    local offset = self.scrollOffsets[node.path] or 0
    for _, child in ipairs(node.children or {}) do
      self:drawNode(child, absX, absY - offset)
    end
    love.graphics.setScissor()
    love.graphics.pop()
  else
    for _, child in ipairs(node.children or {}) do
      self:drawNode(child, absX, absY)
    end
  end
end

function Runtime:draw(root)
  self:drawNode(root, 0, 0)
end

function Runtime:memo(component, deps)
  local cached = self.memoCache[component]
  if cached and sameDeps(cached.deps, deps) then
    cached.node.dirty = cached.node.dirty or {}
    cached.node.dirty.layout = false
    return cached.node
  end

  local node = component()
  node.memoized = true
  self.memoCache[component] = {
    deps = deps,
    node = node,
  }
  return node
end

return Runtime
