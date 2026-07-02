local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"

local Accessibility = require(prefix .. ".accessibility")
local Animation = require(prefix .. ".animation")
local Components = require(prefix .. ".components")
local Dialogue = require(prefix .. ".dialogue")
local Filter = require(prefix .. ".filter")
local Feedback = require(prefix .. ".feedback")
local GridMath = require(prefix .. ".grid_math")
local I18n = require(prefix .. ".i18n")
local Navigate = require(prefix .. ".navigate")
local Path = require(prefix .. ".path")
local Responsive = require(prefix .. ".responsive")
local Runtime = require(prefix .. ".runtime")
local SpriteSheet = require(prefix .. ".sprite_sheet")
local Style = require(prefix .. ".style")
local Transitions = require(prefix .. ".transitions")
local theme = require(prefix .. ".theme")

local Surface = {}
local SurfaceInstance = {}
SurfaceInstance.__index = SurfaceInstance

local function graphicsOf(surface)
  local loveModule = surface.love or _G.love
  return loveModule, loveModule and loveModule.graphics or nil
end

local function canvasSize(canvas)
  if not canvas then
    return nil, nil
  end
  local width = canvas.getWidth and canvas:getWidth() or nil
  local height = canvas.getHeight and canvas:getHeight() or nil
  if (not width or not height) and canvas.getDimensions then
    width, height = canvas:getDimensions()
  end
  return width, height
end

local function clearCanvas(graphics, colorValue)
  if not graphics or not graphics.clear then
    return
  end

  colorValue = colorValue or { 0, 0, 0, 0 }
  local ok = pcall(graphics.clear, colorValue[1] or 0, colorValue[2] or 0, colorValue[3] or 0, colorValue[4] or 0, true, true)
  if not ok then
    pcall(graphics.clear, colorValue)
  end
end

local function pushAll(graphics)
  if not graphics or not graphics.push then
    return function() end
  end

  local ok = pcall(graphics.push, "all")
  if not ok then
    graphics.push()
  end

  return function()
    if graphics.pop then
      graphics.pop()
    end
  end
end

local function surfaceCanvasConfig(opts)
  local source = opts and opts.canvasOptions or nil
  local canvasOptions = {}
  local stencil = true
  local reserved = {
    filter = true,
    min = true,
    mag = true,
    minFilter = true,
    magFilter = true,
    anisotropy = true,
  }
  if type(source) == "table" then
    for key, value in pairs(source) do
      if key == "stencil" then
        stencil = value ~= false
      elseif not reserved[key] then
        canvasOptions[key] = value
      end
    end
  end
  if opts and opts.stencil ~= nil then
    stencil = opts.stencil ~= false
  end
  if next(canvasOptions) == nil then
    canvasOptions = nil
  end
  return canvasOptions, stencil
end

local function makeFeedbackApi(runtime)
  return {
    define = function(name, sequence)
      return Feedback.define(name, sequence)
    end,
    get = function(name)
      return Feedback.get(name)
    end,
    validate = function(sequence)
      return Feedback.validate(sequence)
    end,
    play = function(nameOrSequence, node, opts)
      return Feedback.play(runtime, nameOrSequence, node, opts)
    end,
    active = function()
      return Feedback.active()
    end,
    isPlaying = function(node, key)
      return Feedback.isPlaying(runtime, node, key)
    end,
    clear = function(node)
      Feedback.clear(runtime, node)
    end,
  }
end

---@param runtime table
---@param surface? table
---@return table
function Surface.scopedUi(runtime, surface)
  local ui = {
    accessibility = {
      describe = Accessibility.describe,
      snapshot = function(root)
        return Accessibility.snapshot(root or runtime)
      end,
      focused = function()
        return Accessibility.focused(runtime)
      end,
      announce = function(message, opts)
        return Accessibility.announce(runtime, message, opts)
      end,
    },
    animation = Animation,
    feedback = makeFeedbackApi(runtime),
    i18n = I18n,
    Navigate = Navigate,
    Responsive = Responsive,
    Style = Style,
    transitions = Transitions,
    runtime = runtime,
    surface = surface,
    theme = runtime.theme or theme,
  }

  for name, fn in pairs(Components) do
    ui[name] = fn
  end

  ui.grid = setmetatable({
    pointToCell = GridMath.pointToCell,
  }, {
    __call = function(_, props, children)
      return Components.grid(props, children)
    end,
  })

  ui.path = setmetatable({
    parse = Path.parse,
    bounds = Path.bounds,
    flatten = Path.flatten,
    length = Path.length,
  }, {
    __call = function(_, props)
      return Components.path(props)
    end,
  })

  function ui.tabs(props, tabs)
    props = props or {}
    if props.active ~= nil then
      return Components.tabs(props, tabs)
    end

    local active, setActive = runtime:useState(props.defaultActive or 1)
    local nextProps = {}
    for key, value in pairs(props) do
      nextProps[key] = value
    end
    nextProps.active = active
    nextProps.onChange = function(index, tab)
      setActive(index)
      if props.onChange then
        props.onChange(index, tab)
      end
    end
    return Components.tabs(nextProps, tabs)
  end

  function ui.useState(initial)
    return runtime:useState(initial)
  end

  function ui.useEffect(fn, deps)
    return runtime:useEffect(fn, deps)
  end

  function ui.memo(component, deps)
    return runtime:memo(component, deps)
  end

  ui.dialogue = {
    new = function(opts)
      return Dialogue.new(ui, opts)
    end,
  }

  function ui.drag(opts)
    return runtime:drag(opts)
  end

  function ui.t(key, params, opts)
    return I18n.t(key, params, opts)
  end

  function ui.setTheme(nextTheme)
    runtime.theme = nextTheme or theme
    ui.theme = runtime.theme
    runtime.styleCache = {}
    runtime:markDirty()
  end

  function ui.getTheme()
    return runtime.theme
  end

  ui.style = Style.create
  ui.variant = Style.variant
  ui.composeStyles = Style.compose

  function ui.setLove(loveModule)
    runtime:setLove(loveModule)
  end

  function ui.isHovered(node)
    return node ~= nil and (runtime.hoverNode == node or runtime.hoverPath == node.path)
  end

  function ui.isPressed(node)
    return node ~= nil and (runtime.mouseDownNode == node or runtime.mouseDownPath == node.path or runtime.keyDownNode == node or runtime.keyDownPath == node.path)
  end

  function ui.isFocused(node)
    return node ~= nil and (runtime.focusNode == node or runtime.focusPath == node.path)
  end

  function ui.isActive(node)
    return node ~= nil and node.props and node.props.active == true
  end

  function ui.isHot(node)
    return ui.isHovered(node) or ui.isPressed(node) or ui.isFocused(node) or ui.isActive(node)
  end

  function ui.setFocus(node)
    return runtime:setFocus(node)
  end

  function ui.on(name, fn, opts)
    return runtime:register(name, fn, opts)
  end

  function ui.dispatch(name, ...)
    return runtime:dispatch(name, ...)
  end

  function ui.update(dt)
    return runtime:update(dt)
  end

  function ui.render(component)
    if surface then
      surface.component = component
      return surface:render()
    end
    return runtime:render(component)
  end

  function ui.navigate(direction)
    return Navigate.move(runtime, direction)
  end

  function ui.mousemoved(x, y)
    return runtime:mousemoved(x, y)
  end

  function ui.mousepressed(x, y, button)
    return runtime:mousepressed(x, y, button)
  end

  function ui.mousereleased(x, y, button)
    return runtime:mousereleased(x, y, button)
  end

  function ui.keypressed(key)
    return runtime:keypressed(key)
  end

  function ui.keyreleased(key)
    return runtime:keyreleased(key)
  end

  function ui.textinput(text)
    return runtime:textinput(text)
  end

  function ui.wheelmoved(dx, dy)
    return runtime:wheelmoved(dx, dy)
  end

  function ui.spriteSheet(image, opts)
    return SpriteSheet.new(image, opts)
  end

  return ui
end

function SurfaceInstance:ensureCanvas()
  local _, graphics = graphicsOf(self)
  if not graphics or not graphics.newCanvas then
    return self.canvas
  end

  local currentWidth, currentHeight = canvasSize(self.canvas)
  if self.canvas and currentWidth == self.width and currentHeight == self.height then
    Filter.apply(self.canvas, self.filter)
    return self.canvas
  end

  local ok, canvas = pcall(graphics.newCanvas, self.width, self.height, self.canvasOptions)
  if ok then
    Filter.apply(canvas, self.filter)
    self.canvas = canvas
  end
  return self.canvas
end

function SurfaceInstance:resize(width, height)
  self.width = math.max(1, math.floor(tonumber(width) or self.width or 1))
  self.height = math.max(1, math.floor(tonumber(height) or self.height or 1))
  self.ctx.width = self.width
  self.ctx.height = self.height
  self.canvas = nil
  self.runtime:markDirty()
  return self
end

function SurfaceInstance:markDirty()
  self.runtime:markDirty()
  return self
end

function SurfaceInstance:update(dt)
  self.runtime:update(dt or 0)
  return self
end

function SurfaceInstance:render(component)
  if component ~= nil then
    self.component = component
  end
  if type(self.component) ~= "function" then
    return self.canvas
  end

  self:ensureCanvas()
  local loveModule, graphics = graphicsOf(self)
  self.runtime:setLove(loveModule)
  self.ctx.width = self.width
  self.ctx.height = self.height

  local function buildSurface()
    return self.component(self.ui, self.ctx)
  end

  local restore = pushAll(graphics)
  if graphics and self.canvas and graphics.setCanvas then
    if self.stencil ~= false then
      graphics.setCanvas({ self.canvas, stencil = true })
    else
      graphics.setCanvas(self.canvas)
    end
    clearCanvas(graphics, self.clearColor)
  end

  self.runtime:build(buildSurface)
  if self.runtime.root then
    self.runtime:layoutRoot(self.runtime.root, self.width, self.height)
    self.runtime:publishLayoutCallbacks(self.runtime.root, 0, 0)
    self.runtime:draw(self.runtime.root)
  end

  if self.runtime.scene then
    for _, layer in ipairs(self.runtime.scene.layers) do
      self.runtime:renderLayer(layer, self.width, self.height)
    end
  end

  if graphics and self.canvas and graphics.setCanvas then
    graphics.setCanvas()
  end
  restore()
  return self.canvas
end

function SurfaceInstance:mousemoved(x, y)
  return self.runtime:mousemoved(x, y)
end

function SurfaceInstance:mousepressed(x, y, button)
  return self.runtime:mousepressed(x, y, button)
end

function SurfaceInstance:mousereleased(x, y, button)
  return self.runtime:mousereleased(x, y, button)
end

function SurfaceInstance:wheelmoved(dx, dy)
  return self.runtime:wheelmoved(dx, dy)
end

function SurfaceInstance:keypressed(key)
  return self.runtime:keypressed(key)
end

function SurfaceInstance:textinput(text)
  return self.runtime:textinput(text)
end

function SurfaceInstance:keyreleased(key)
  return self.runtime:keyreleased(key)
end

function SurfaceInstance:destroy()
  Feedback.clear(self.runtime)
  self.canvas = nil
  self.runtime.root = nil
  self.runtime.rootComponent = nil
  return self
end

function Surface.new(opts)
  opts = opts or {}
  local runtime = Runtime.new()
  local loveModule = opts.love or _G.love
  runtime:setLove(loveModule)
  runtime.theme = opts.theme or theme
  local canvasOptions, stencil = surfaceCanvasConfig(opts)
  local filter = Filter.fromFields(opts) or Filter.fromFields(opts.canvasOptions)

  local self = setmetatable({
    runtime = runtime,
    love = loveModule,
    width = math.max(1, math.floor(tonumber(opts.width) or 1)),
    height = math.max(1, math.floor(tonumber(opts.height) or 1)),
    component = opts.component,
    clearColor = opts.clearColor or { 0, 0, 0, 0 },
    canvasOptions = canvasOptions,
    stencil = stencil,
    filter = filter,
    canvas = opts.canvas,
    ctx = {},
  }, SurfaceInstance)

  self.ctx = {
    surface = self,
    runtime = runtime,
    width = self.width,
    height = self.height,
  }
  self.ui = Surface.scopedUi(runtime, self)
  self:ensureCanvas()
  return self
end

return Surface
