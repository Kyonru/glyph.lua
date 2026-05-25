local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local CallbackBus = require(prefix .. ".callback_bus")
local Layout = require(prefix .. ".layout")
local Responsive = require(prefix .. ".responsive")
local Scene = require(prefix .. ".scene")
local Style = require(prefix .. ".style")
local theme = require(prefix .. ".theme")

local runtimeCallbacks = {
  "beforeUpdate",
  "afterUpdate",
  "beforeRender",
  "afterRender",
  "layout",
  "navigate",
  "focusChanged",
  "hoverChanged",
  "event",
}

local Runtime = {}
Runtime.__index = Runtime

local function orderedChildren(node, reverse)
  local source = node.children or {}
  if #source <= 1 then
    return source
  end

  local ordered = {}
  for index, child in ipairs(source) do
    ordered[index] = {
      index = index,
      node = child,
      zIndex = (child.props and child.props.zIndex) or 0,
    }
  end

  table.sort(ordered, function(a, b)
    if a.zIndex == b.zIndex then
      if reverse then
        return a.index > b.index
      end
      return a.index < b.index
    end
    if reverse then
      return a.zIndex > b.zIndex
    end
    return a.zIndex < b.zIndex
  end)

  local result = {}
  for index, entry in ipairs(ordered) do
    result[index] = entry.node
  end
  return result
end

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

  for _, child in ipairs(orderedChildren(node)) do
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
  local self = setmetatable({
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
    scene = nil,
    currentScope = nil,
  }, Runtime)
  self.scene = Scene.new(self)
  return self
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
  local hooks = self.hooks
  local scope = self.currentScope

  if hooks[index] == nil then
    if type(initial) == "function" then
      hooks[index] = initial()
    else
      hooks[index] = initial
    end
  end

  local function setState(nextValue)
    if type(nextValue) == "function" then
      hooks[index] = nextValue(hooks[index])
    else
      hooks[index] = nextValue
    end

    if scope then
      scope.needsRender = true
      if scope.layer then
        scope.layer.needsRender = true
      end
    end
    self:markDirty()
  end

  return hooks[index], setState
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

function Runtime:withHookScope(scope, fn)
  scope = scope or {}
  local saved = {
    hooks = self.hooks,
    hookCursor = self.hookCursor,
    effects = self.effects,
    pendingEffects = self.pendingEffects,
    currentScope = self.currentScope,
  }

  self.hooks = scope.hooks or {}
  self.effects = scope.effects or {}
  self.pendingEffects = scope.pendingEffects or {}
  self.hookCursor = 0
  self.currentScope = scope

  local ok, result = pcall(fn)

  scope.hooks = self.hooks
  scope.effects = self.effects
  scope.pendingEffects = self.pendingEffects
  scope.needsRender = false

  self.hooks = saved.hooks
  self.hookCursor = saved.hookCursor
  self.effects = saved.effects
  self.pendingEffects = saved.pendingEffects
  self.currentScope = saved.currentScope

  if not ok then
    error(result, 0)
  end

  return result
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

function Runtime:buildLayer(layer)
  local root = self:withHookScope(layer.scope, function()
    local nextRoot = layer.component(layer.props)
    assignPaths(nextRoot, "layer:" .. tostring(layer.id), nil)
    self:runEffects()
    return nextRoot
  end)

  layer.root = root
  layer.needsRender = false
  return root
end

function Runtime:layoutRoot(root, availableWidth, availableHeight)
  local context = {
    theme = self.theme,
    availableWidth = availableWidth,
    availableHeight = availableHeight,
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
  if self.scene then
    self.scene:update(dt or 0)
  end
  self.bus:dispatch("afterUpdate", dt)
end

local viewportSize

function Runtime:render(component)
  self.bus:dispatch("beforeRender")
  local root = self.root

  local hasSceneRoot = self.scene and #self.scene.layers > 0 and component == nil

  if not hasSceneRoot and (self.needsRender or component ~= self.rootComponent or self.root == nil) then
    root = self:build(component)
  end

  if not hasSceneRoot and root then
    local loveModule = self.love or _G.love
    local viewportWidth, viewportHeight = viewportSize(loveModule)
    self:layoutRoot(root, viewportWidth, viewportHeight)
    self:draw(root)
  end

  if self.scene then
    self:renderLayers()
  end

  self.bus:dispatch("afterRender", root)
end

local function graphicsPushAll(graphics)
  if not graphics or not graphics.push then
    return function() end
  end

  local ok = pcall(function()
    graphics.push("all")
  end)
  if not ok then
    graphics.push()
  end

  return function()
    if graphics.pop then
      graphics.pop()
    end
    if graphics.setStencilTest then
      graphics.setStencilTest()
    end
    if graphics.setScissor then
      graphics.setScissor()
    end
  end
end

function viewportSize(loveModule)
  if loveModule and loveModule.graphics and loveModule.graphics.getDimensions then
    return loveModule.graphics.getDimensions()
  end
  return 800, 600
end

local function resolveLayerBounds(layer, viewportWidth, viewportHeight)
  local root = layer.root
  local layout = root and root.layout or {}
  local width = layer.width or layout.width or viewportWidth
  local height = layer.height or layout.height or viewportHeight
  local align = layer.align or "stretch"
  local x, y = 0, 0

  if align == "center" then
    x = (viewportWidth - width) / 2
    y = (viewportHeight - height) / 2
  elseif align == "top" then
    x = (viewportWidth - width) / 2
  elseif align == "bottom" then
    x = (viewportWidth - width) / 2
    y = viewportHeight - height
  elseif align == "right" then
    x = viewportWidth - width
  elseif align == "stretch" then
    width = layer.width or viewportWidth
    height = layer.height or viewportHeight
  end

  layer.offsetX = x
  layer.offsetY = y
  layer.bounds = {
    x = x,
    y = y,
    width = width,
    height = height,
  }
  return layer.bounds
end

function Runtime:drawLayerBackdrop(layer, graphics, viewportWidth, viewportHeight)
  if not layer.backdrop or not graphics then
    return
  end

  local colorValue = layer.backdropColor or { 0, 0, 0, 0.5 }
  local progress = layer.state == "exiting" and (1 - layer.progress) or layer.progress
  local alpha = (colorValue[4] or 0.5) * progress
  graphics.setColor(colorValue[1] or 0, colorValue[2] or 0, colorValue[3] or 0, alpha)
  graphics.rectangle("fill", 0, 0, viewportWidth, viewportHeight)
end

function Runtime:renderLayer(layer, viewportWidth, viewportHeight)
  local loveModule = self.love or _G.love
  local graphics = loveModule and loveModule.graphics
  if not graphics then
    return
  end

  if layer.needsRender or not layer.root or layer.scope.needsRender then
    self:buildLayer(layer)
  end

  if not layer.root then
    return
  end

  self:layoutRoot(layer.root, layer.width or viewportWidth, layer.height or viewportHeight)
  local bounds = resolveLayerBounds(layer, viewportWidth, viewportHeight)

  local progress = layer.state == "open" and 1 or layer.progress
  local phase = layer.state == "exiting" and "exit" or "enter"
  local transition = layer.transition or {}

  local function drawLayer()
    graphics.push()
    graphics.translate(bounds.x, bounds.y)
    self:draw(layer.root)
    graphics.pop()
  end

  local restore = graphicsPushAll(graphics)
  self:drawLayerBackdrop(layer, graphics, viewportWidth, viewportHeight)
  local ctx = {
    progress = progress,
    phase = phase,
    layer = layer,
    bounds = bounds,
    love = loveModule,
    runtime = self,
    transition = transition,
    drawLayer = drawLayer,
  }

  if transition.draw then
    transition.draw(ctx)
  else
    drawLayer()
  end
  restore()
end

function Runtime:renderLayers()
  if not self.scene or #self.scene.layers == 0 then
    return
  end

  local loveModule = self.love or _G.love
  local viewportWidth, viewportHeight = viewportSize(loveModule)
  for _, layer in ipairs(self.scene.layers) do
    self:renderLayer(layer, viewportWidth, viewportHeight)
  end
end

local function hitTestNode(node, parentX, parentY, x, y)
  local layout = node.layout or {}
  local absX = parentX + (layout.x or 0)
  local absY = parentY + (layout.y or 0)

  for _, child in ipairs(orderedChildren(node, true)) do
    local hit = hitTestNode(child, absX, absY, x, y)
    if hit then
      return hit
    end
  end

  if node.props and node.props.interactive ~= false and contains(node, x, y, absX, absY) then
    node.absoluteX = absX
    node.absoluteY = absY
    return node
  end

  return nil
end

local function walkHitTest(root, ox, oy, x, y)
  return hitTestNode(root, ox, oy, x, y)
end

function Runtime:hitTest(x, y)
  if self.scene then
    local node, layer = self.scene:topInteractiveHit(x, y, walkHitTest)
    if node or layer then
      return node
    end
  end

  if not self.root then
    return nil
  end

  return walkHitTest(self.root, 0, 0, x, y)
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
  local node, activeLayer = nil, nil

  if self.scene then
    node, activeLayer = self.scene:topInteractiveHit(x, y, walkHitTest)
  end

  if activeLayer then
    if not node then
      if activeLayer.dismissOnBackdrop then
        self.scene:close(activeLayer.id)
      end
      self:markDirty()
      return
    end
  else
    node = self:hitTest(x, y)
  end
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
      local maxScroll = math.max(0, ((node.layout and node.layout.scrollContentHeight) or 0) - ((node.layout and node.layout.height) or 0))
      self.scrollOffsets[scrollKey] = math.min(maxScroll, math.max(0, (self.scrollOffsets[scrollKey] or 0) - dy * 24))
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

  if key == "escape" and self.scene and self.scene:closeTopEscapable() then
    self.bus:dispatch("event", "keypressed", key, node)
    self:markDirty()
    return
  end

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

local function mergeScrollbarStyle(theme, style, props)
  local result = {}
  local defaults = theme.components and theme.components.scrollBar or {}

  for key, value in pairs(defaults) do
    result[key] = value
  end

  if type(style.scrollbar) == "table" then
    for key, value in pairs(style.scrollbar) do
      result[key] = value
    end
  end

  if type(props.scrollbar) == "table" then
    for key, value in pairs(props.scrollbar) do
      result[key] = value
    end
  end

  return result
end

local function polygonBox(x, y, width, height, opts)
  opts = opts or {}
  local skew = opts.skew or 0
  local inset = opts.inset or 0

  return {
    x + inset,
    y + inset,
    x + width - skew - inset,
    y + inset,
    x + width - inset,
    y + height - inset,
    x + skew + inset,
    y + height - inset,
  }
end

local function boundsFor(x, y, width, height)
  return {
    x = x,
    y = y,
    width = width,
    height = height,
  }
end

local function normalizePoints(points, bounds, absolute)
  local result = {}

  if not points then
    return result
  end

  if type(points[1]) == "table" then
    for _, point in ipairs(points) do
      local px = point.x or point[1] or 0
      local py = point.y or point[2] or 0
      result[#result + 1] = absolute and px or bounds.x + px
      result[#result + 1] = absolute and py or bounds.y + py
    end
  else
    for index = 1, #points, 2 do
      local px = points[index] or 0
      local py = points[index + 1] or 0
      result[#result + 1] = absolute and px or bounds.x + px
      result[#result + 1] = absolute and py or bounds.y + py
    end
  end

  return result
end

local function ellipsePoints(bounds, segments)
  local result = {}
  local count = segments or 32
  local cx = bounds.x + bounds.width / 2
  local cy = bounds.y + bounds.height / 2
  local rx = bounds.width / 2
  local ry = bounds.height / 2

  for index = 0, count - 1 do
    local angle = (index / count) * math.pi * 2
    result[#result + 1] = cx + math.cos(angle) * rx
    result[#result + 1] = cy + math.sin(angle) * ry
  end

  return result
end

local function shapePoints(shape, bounds, ctx)
  shape = shape or { kind = "rect" }
  if type(shape) == "function" then
    local value = shape(ctx)
    if type(value) == "table" and value.kind == nil then
      return normalizePoints(value, bounds, false)
    end
    shape = value or { kind = "rect" }
  end

  if shape == true then
    shape = { kind = "rect" }
  end

  if type(shape) == "table" and shape.kind == nil and shape[1] ~= nil then
    return normalizePoints(shape, bounds, false)
  end

  local kind = shape.kind or "rect"
  if kind == "skew" then
    return polygonBox(bounds.x, bounds.y, bounds.width, bounds.height, shape)
  elseif kind == "polygon" then
    return normalizePoints(shape.points, bounds, shape.absolute == true)
  elseif kind == "circle" or kind == "ellipse" then
    return ellipsePoints(bounds, shape.segments)
  end

  return {
    bounds.x,
    bounds.y,
    bounds.x + bounds.width,
    bounds.y,
    bounds.x + bounds.width,
    bounds.y + bounds.height,
    bounds.x,
    bounds.y + bounds.height,
  }
end

local function drawShape(graphics, mode, shape, bounds, ctx)
  if not graphics then
    return
  end

  shape = shape or { kind = "rect" }
  if type(shape) == "function" then
    local value = shape(ctx)
    if type(value) == "function" then
      value(mode, bounds, ctx)
      return
    end
    shape = value or { kind = "rect" }
  end

  if shape == true then
    shape = { kind = "rect" }
  end

  if type(shape) == "table" and shape.kind == nil and shape[1] ~= nil then
    if graphics.polygon then
      local points = normalizePoints(shape, bounds, false)
      if #points >= 6 then
        graphics.polygon(mode, (table.unpack or unpack)(points))
      end
    end
    return
  end

  local kind = shape.kind or "rect"
  if kind == "rect" and graphics.rectangle then
    graphics.rectangle(mode, bounds.x, bounds.y, bounds.width, bounds.height, shape.radius or 0, shape.radius or 0)
  elseif (kind == "circle" or kind == "ellipse") and graphics.ellipse then
    graphics.ellipse(mode, bounds.x + bounds.width / 2, bounds.y + bounds.height / 2, bounds.width / 2, bounds.height / 2)
  elseif graphics.polygon then
    local points = shapePoints(shape, bounds, ctx)
    if #points >= 6 then
      graphics.polygon(mode, (table.unpack or unpack)(points))
    end
  end
end

local function currentScissor(graphics)
  if graphics and graphics.getScissor then
    local sx, sy, sw, sh = graphics.getScissor()
    if sx ~= nil then
      return { sx, sy, sw, sh }
    end
  end
  return nil
end

local function restoreScissor(graphics, previous)
  if previous then
    graphics.setScissor(previous[1], previous[2], previous[3], previous[4])
  else
    graphics.setScissor()
  end
end

local function setScissorBounds(graphics, bounds, previous)
  if previous then
    local x1 = math.max(previous[1], bounds.x)
    local y1 = math.max(previous[2], bounds.y)
    local x2 = math.min(previous[1] + previous[3], bounds.x + bounds.width)
    local y2 = math.min(previous[2] + previous[4], bounds.y + bounds.height)
    graphics.setScissor(x1, y1, math.max(0, x2 - x1), math.max(0, y2 - y1))
  else
    graphics.setScissor(bounds.x, bounds.y, bounds.width, bounds.height)
  end
end

local function runWithRestore(fn, restore)
  local ok, result = pcall(fn)
  restore()
  if not ok then
    error(result, 0)
  end
end

local function withClip(graphics, shape, bounds, ctx, fn)
  if not graphics then
    fn()
    return
  end

  if shape == true then
    if graphics.setScissor then
      local previous = currentScissor(graphics)
      setScissorBounds(graphics, bounds, previous)
      runWithRestore(fn, function()
        restoreScissor(graphics, previous)
      end)
      return
    end

    fn()
    return
  end

  if graphics.stencil and graphics.setStencilTest then
    local previousCompare, previousValue
    if graphics.getStencilTest then
      previousCompare, previousValue = graphics.getStencilTest()
    end

    graphics.stencil(function()
      drawShape(graphics, "fill", shape, bounds, ctx)
    end, "replace", 1)
    graphics.setStencilTest("equal", 1)
    runWithRestore(fn, function()
      if previousCompare then
        graphics.setStencilTest(previousCompare, previousValue)
      else
        graphics.setStencilTest()
      end
    end)
  else
    fn()
  end
end

local function withStencil(graphics, spec, bounds, ctx, fn)
  spec = spec or {}
  local shape = spec.shape or spec
  local mode = spec.mode or "inside"

  if not graphics or not graphics.stencil or not graphics.setStencilTest then
    fn()
    return
  end

  local previousCompare, previousValue
  if graphics.getStencilTest then
    previousCompare, previousValue = graphics.getStencilTest()
  end

  graphics.stencil(function()
    if type(shape) == "function" then
      local value = shape(ctx)
      if type(value) == "function" then
        value("fill", bounds, ctx)
      else
        drawShape(graphics, "fill", value, bounds, ctx)
      end
    else
      drawShape(graphics, "fill", shape, bounds, ctx)
    end
  end, "replace", 1)

  graphics.setStencilTest(mode == "outside" and "notequal" or "equal", 1)
  runWithRestore(fn, function()
    if previousCompare then
      graphics.setStencilTest(previousCompare, previousValue)
    else
      graphics.setStencilTest()
    end
  end)
end

local function clamp01(value)
  if value < 0 then
    return 0
  elseif value > 1 then
    return 1
  end
  return value
end

local function meterRatio(props)
  local minValue = props.min or 0
  local maxValue = props.max or 1
  local span = maxValue - minValue
  if span == 0 then
    return 0, 0
  end

  local raw = ((props.value or 0) - minValue) / span
  return clamp01(raw), math.max(0, raw - 1)
end

local function partStyle(base, override, fallback)
  local style = Style.compose(fallback or {}, override or {})
  if style.background == nil and style.color == nil and base then
    style.background = base
  end
  return style
end

local function linearFillBounds(bounds, ratio, direction)
  ratio = clamp01(ratio)
  direction = direction or "right"

  if direction == "left" then
    local width = bounds.width * ratio
    return { x = bounds.x + bounds.width - width, y = bounds.y, width = width, height = bounds.height }
  elseif direction == "up" then
    local height = bounds.height * ratio
    return { x = bounds.x, y = bounds.y + bounds.height - height, width = bounds.width, height = height }
  elseif direction == "down" then
    return { x = bounds.x, y = bounds.y, width = bounds.width, height = bounds.height * ratio }
  end

  return { x = bounds.x, y = bounds.y, width = bounds.width * ratio, height = bounds.height }
end

local drawMeter

local function drawMeterPart(graphics, bounds, shape, style, ctx)
  if style.background or style.color then
    color(ctx.love, style.background or style.color)
    drawShape(graphics, "fill", shape, bounds, ctx)
  end

  if style.borderColor and (style.borderWidth or 0) > 0 then
    color(ctx.love, style.borderColor)
    local previousLineWidth = graphics.getLineWidth and graphics.getLineWidth() or nil
    if graphics.setLineWidth then
      graphics.setLineWidth(style.borderWidth)
    end
    drawShape(graphics, "line", shape, bounds, ctx)
    if previousLineWidth and graphics.setLineWidth then
      graphics.setLineWidth(previousLineWidth)
    end
  end
end

local function drawLinearMeter(graphics, bounds, props, style, ctx)
  local ratio, overfill = meterRatio(props)
  local shape = props.shape or style.shape or { kind = "rect", radius = style.radius or 0 }
  local track = partStyle(style.background, props.trackStyle, { background = { 0, 0, 0, 0.28 } })
  local fill = partStyle(style.color, props.fillStyle, { background = style.color or { 0.16, 0.72, 0.48, 1 } })
  local over = partStyle(nil, props.overfillStyle, { background = { 1, 0.82, 0.18, 1 } })
  local segments = props.segments or 0
  local gap = props.gap or 0

  drawMeterPart(graphics, bounds, shape, track, ctx)

  if segments > 1 then
    local horizontal = props.direction ~= "up" and props.direction ~= "down"
    local totalGap = gap * (segments - 1)
    local segmentLength = math.max(0, ((horizontal and bounds.width or bounds.height) - totalGap) / segments)
    local filled = ratio * segments
    for index = 1, segments do
      local amount = clamp01(filled - (index - 1))
      if amount > 0 then
        local segmentBounds
        if horizontal then
          local x = bounds.x + (index - 1) * (segmentLength + gap)
          segmentBounds = { x = x, y = bounds.y, width = segmentLength * amount, height = bounds.height }
        else
          local y = bounds.y + bounds.height - index * segmentLength - (index - 1) * gap
          segmentBounds = { x = bounds.x, y = y + segmentLength * (1 - amount), width = bounds.width, height = segmentLength * amount }
        end
        drawMeterPart(graphics, segmentBounds, shape, fill, ctx)
      end
    end
  else
    drawMeterPart(graphics, linearFillBounds(bounds, ratio, props.direction), shape, fill, ctx)
  end

  if overfill > 0 then
    drawMeterPart(graphics, linearFillBounds(bounds, clamp01(overfill), props.direction), shape, over, ctx)
  end
end

local function drawRadialMeter(graphics, bounds, props, style, ctx)
  local ratio = meterRatio(props)
  local track = partStyle(nil, props.trackStyle, { color = style.background or { 0, 0, 0, 0.3 } })
  local fill = partStyle(nil, props.fillStyle, { color = style.color or { 0.16, 0.72, 0.48, 1 } })
  local thickness = props.thickness or style.lineWidth or style.borderWidth or 8
  local radius = math.max(0, math.min(bounds.width, bounds.height) / 2 - thickness / 2)
  local cx = bounds.x + bounds.width / 2
  local cy = bounds.y + bounds.height / 2
  local startAngle = props.startAngle or (props.kind == "arc" and math.rad(135) or -math.pi / 2)
  local endAngle = props.endAngle or (props.kind == "arc" and math.rad(405) or (startAngle + math.pi * 2))
  local fillEnd = startAngle + (endAngle - startAngle) * ratio
  local previousLineWidth = graphics.getLineWidth and graphics.getLineWidth() or nil

  if graphics.setLineWidth then
    graphics.setLineWidth(thickness)
  end

  if graphics.arc then
    color(ctx.love, track.color or track.background)
    graphics.arc("line", cx, cy, radius, startAngle, endAngle, props.segments or 32)
    color(ctx.love, fill.color or fill.background)
    graphics.arc("line", cx, cy, radius, startAngle, fillEnd, props.segments or 32)
  end

  if previousLineWidth and graphics.setLineWidth then
    graphics.setLineWidth(previousLineWidth)
  end
end

drawMeter = function(graphics, bounds, props, style, ctx)
  if not graphics then
    return
  end

  local background = props.backgroundStyle
  if background and background.background then
    color(ctx.love, background.background)
    drawShape(graphics, "fill", props.shape or style.shape, bounds, ctx)
  end

  if props.kind == "radial" or props.kind == "arc" then
    drawRadialMeter(graphics, bounds, props, style, ctx)
  else
    drawLinearMeter(graphics, bounds, props, style, ctx)
  end
end

local function createDrawContext(runtime, node, x, y, width, height, love, style)
  local props = node.props or {}
  local graphics = love and love.graphics
  local ctx = {
    node = node,
    props = props,
    x = x,
    y = y,
    width = width,
    height = height,
    love = love,
    graphics = graphics,
    style = style,
    runtime = runtime,
    hovered = runtime.hoverNode == node or runtime.hoverPath == node.path,
    pressed = runtime.mouseDownNode == node or runtime.mouseDownPath == node.path,
    focused = runtime.focusNode == node or runtime.focusPath == node.path,
    active = props.active == true,
    time = love and love.timer and love.timer.getTime and love.timer.getTime() or runtime.styleClock,
  }

  ctx.hot = ctx.hovered or ctx.pressed or ctx.focused or ctx.active

  function ctx:pulse(speed, phase)
    return (math.sin(self.time * (speed or 1) + (phase or 0)) + 1) / 2
  end

  function ctx:color(value, alpha)
    color(love, withOpacity(value, alpha))
  end

  function ctx:rect(mode, rx, ry, rw, rh, radius)
    drawRect(love, mode, rx, ry, rw, rh, radius)
  end

  function ctx:line(...)
    if graphics and graphics.line then
      graphics.line(...)
    end
  end

  function ctx:polygon(mode, points)
    if graphics and graphics.polygon then
      graphics.polygon(mode, (table.unpack or unpack)(points))
    end
  end

  function ctx:shape(mode, shape, bounds)
    drawShape(graphics, mode, shape or props.shape, bounds or self, self)
  end

  function ctx:clip(shape, fn)
    if type(fn) == "function" then
      withClip(graphics, shape or true, self, self, fn)
    end
  end

  function ctx:stencil(shapeOrFn, fn, opts)
    if type(fn) == "function" then
      opts = opts or {}
      opts.shape = shapeOrFn
      withStencil(graphics, opts, self, self, fn)
    end
  end

  function ctx:meter(bounds, opts)
    drawMeter(graphics, bounds or self, opts or {}, style, self)
  end

  function ctx:text(value, tx, ty)
    if graphics and graphics.print then
      graphics.print(tostring(value), tx, ty)
    end
  end

  function ctx:printf(value, tx, ty, limit, align)
    if graphics and graphics.printf then
      graphics.printf(tostring(value), tx, ty, limit, align or "left")
    elseif graphics and graphics.print then
      graphics.print(tostring(value), tx, ty)
    end
  end

  function ctx:skewBox(opts)
    return polygonBox(self.x, self.y, self.width, self.height, opts)
  end

  return ctx
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

  local ctx = nil

  if type(props.draw) == "function" then
    ctx = createDrawContext(self, node, absX, absY, width, height, love, style)
    props.draw(node, absX, absY, width, height, love, style, ctx)
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
  elseif node.type == "meter" then
    ctx = createDrawContext(self, node, absX, absY, width, height, love, style)
    drawMeter(love.graphics, boundsFor(absX, absY, width, height), props, style, ctx)
    if props.label then
      local label = props.label
      if type(label) == "function" then
        label = label(props.value or 0, props.min or 0, props.max or 1)
      end
      color(love, withOpacity(style.color or self.theme.textColor, opacity))
      love.graphics.print(tostring(label), absX + 8, absY + math.max(2, height / 2 - (self.theme.lineHeight or 14) / 2))
    end
  else
    local nodeShape = props.shape or style.shape
    local shapeCtx = nodeShape and (ctx or createDrawContext(self, node, absX, absY, width, height, love, style)) or nil
    if style.background then
      color(love, withOpacity(style.background, opacity))
      if nodeShape then
        drawShape(love.graphics, "fill", nodeShape, boundsFor(absX, absY, width, height), shapeCtx)
      else
        drawRect(love, "fill", absX, absY, width, height, radius)
      end
    end
    if style.borderColor and (style.borderWidth or 0) > 0 then
      color(love, withOpacity(style.borderColor, opacity))
      if nodeShape then
        drawShape(love.graphics, "line", nodeShape, boundsFor(absX, absY, width, height), shapeCtx)
      else
        drawRect(love, "line", absX, absY, width, height, radius)
      end
    end
  end

  restore()

  local function drawChildren()
    if node.type == "scrollView" and love.graphics.push then
      love.graphics.push()
      local previousScissor = nil
      if love.graphics.setScissor then
        previousScissor = currentScissor(love.graphics)
        setScissorBounds(love.graphics, boundsFor(absX, absY, width, height), previousScissor)
      end
      local maxScroll = math.max(0, ((layout.scrollContentHeight or 0) - height))
      local offset = math.min(maxScroll, math.max(0, self.scrollOffsets[node.path] or 0))
      self.scrollOffsets[node.path] = offset
      runWithRestore(function()
        for _, child in ipairs(orderedChildren(node)) do
          self:drawNode(child, absX, absY - offset)
        end
      end, function()
        if love.graphics.setScissor then
          restoreScissor(love.graphics, previousScissor)
        end
        love.graphics.pop()
      end)

      local scrollbar = mergeScrollbarStyle(self.theme, style, props)
      local showScrollbar = props.showScrollbar ~= false and maxScroll > 0
      if showScrollbar then
        local barWidth = scrollbar.width or self.theme.scrollbarWidth
        local padding = scrollbar.padding or 0
        local trackX = absX + width - barWidth - padding
        local trackY = absY + padding
        local trackHeight = math.max(0, height - padding * 2)
        local contentHeight = layout.scrollContentHeight or height
        local thumbHeight = math.max(scrollbar.minThumbSize or 18, trackHeight * (height / contentHeight))
        thumbHeight = math.min(trackHeight, thumbHeight)
        local thumbTravel = math.max(0, trackHeight - thumbHeight)
        local thumbY = trackY + (maxScroll > 0 and (offset / maxScroll) * thumbTravel or 0)
        local barRadius = scrollbar.radius or barWidth / 2

        if scrollbar.trackColor then
          color(love, withOpacity(scrollbar.trackColor, opacity))
          drawRect(love, "fill", trackX, trackY, barWidth, trackHeight, barRadius)
        end

        color(love, withOpacity(scrollbar.thumbColor or self.theme.scrollbarColor, opacity))
        drawRect(love, "fill", trackX, thumbY, barWidth, thumbHeight, barRadius)
      end
    else
      for _, child in ipairs(orderedChildren(node)) do
        self:drawNode(child, absX, absY)
      end
    end
  end

  if props.clip or props.stencil then
    local clipCtx = ctx or createDrawContext(self, node, absX, absY, width, height, love, style)
    local childBounds = boundsFor(absX, absY, width, height)
    local function drawClippedChildren()
      if props.stencil then
        withStencil(love.graphics, props.stencil, childBounds, clipCtx, drawChildren)
      else
        drawChildren()
      end
    end

    if props.clip then
      withClip(love.graphics, props.clip, childBounds, clipCtx, drawClippedChildren)
    else
      drawClippedChildren()
    end
  else
    drawChildren()
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
