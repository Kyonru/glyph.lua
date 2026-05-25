local prefix = ...
if not prefix or prefix == "" then
  prefix = "glyph"
elseif prefix:sub(-5) == ".init" then
  prefix = prefix:sub(1, -6)
end

local Accessibility = require(prefix .. ".accessibility")
local Animation = require(prefix .. ".animation")
local Components = require(prefix .. ".components")
local CallbackBus = require(prefix .. ".callback_bus")
local Feedback = require(prefix .. ".feedback")
local I18n = require(prefix .. ".i18n")
local Modal = require(prefix .. ".modal")
local Navigate = require(prefix .. ".navigate")
local RichTextBackend = require(prefix .. ".rich_text_backend")
local Responsive = require(prefix .. ".responsive")
local Runtime = require(prefix .. ".runtime")
local Style = require(prefix .. ".style")
local Transitions = require(prefix .. ".transitions")
local theme = require(prefix .. ".theme")

local runtime = Runtime.new()

---@class glyph
---@field text fun(value: string, props?: GlyphTextProps): GlyphNode
---@field textKey fun(key: string, props?: GlyphTextProps): GlyphNode
---@field richText fun(value: string, props?: GlyphTextProps): GlyphNode
---@field richTextKey fun(key: string, props?: GlyphTextProps): GlyphNode
---@field h1 fun(value: string, props?: GlyphTextProps): GlyphNode
---@field h2 fun(value: string, props?: GlyphTextProps): GlyphNode
---@field p fun(value: string, props?: GlyphTextProps): GlyphNode
---@field caption fun(value: string, props?: GlyphTextProps): GlyphNode
---@field box fun(props?: GlyphProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field row fun(props?: GlyphProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field column fun(props?: GlyphProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field stack fun(props?: GlyphProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field button fun(props?: GlyphButtonProps): GlyphNode
---@field input fun(props?: GlyphInputProps): GlyphNode
---@field meter fun(props?: GlyphMeterProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field scrollView fun(props?: GlyphProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field panel fun(props?: GlyphPanelProps, children?: GlyphNode[]|GlyphNode): GlyphNode
---@field static fun(node: GlyphNode): GlyphNode
---@field animation GlyphAnimationApi
---@field accessibility GlyphAccessibilityApi
---@field feedback GlyphFeedbackApi
---@field i18n GlyphI18nApi
---@field richTextBackend GlyphRichTextBackendApi
---@field t fun(key: string, params?: table, opts?: GlyphI18nTranslateOpts): string
---@field viewportBackend GlyphViewportBackendApi
---@field transitions GlyphTransitionApi
---@field scene GlyphSceneApi
---@field modal GlyphModalApi
---@field setFocus fun(node?: GlyphNode)
---@field navigate fun(direction: "up"|"down"|"left"|"right"): GlyphNode|nil
---@field keypressed fun(key: string)
---@field keyreleased fun(key: string)
---@field gamepadpressed fun(joystick: any, button: string, opts?: boolean|GlyphGamepadMapperOpts): any
---@field gamepadreleased fun(joystick: any, button: string, opts?: boolean|GlyphGamepadMapperOpts): any
local ui = {
  accessibility = nil,
  CallbackBus = CallbackBus,
  animation = Animation,
  feedback = nil,
  i18n = I18n,
  richTextBackend = nil,
  Navigate = Navigate,
  Responsive = Responsive,
  Style = Style,
  transitions = Transitions,
  runtime = runtime,
  theme = theme,
}

I18n.setInvalidationCallback(function()
  runtime:markDirty()
end)

ui.accessibility = {
  ---@param opts? GlyphAccessibilityConfig
  ---@return nil
  configure = function(opts)
    Accessibility.configure(opts)
    runtime:markDirty()
  end,
  ---@param node? GlyphNode
  ---@return GlyphAccessibilityDescription|nil
  describe = function(node)
    return Accessibility.describe(node)
  end,
  ---@param root? GlyphNode
  ---@return GlyphAccessibilityDescription[]
  snapshot = function(root)
    return Accessibility.snapshot(root or runtime)
  end,
  ---@return GlyphAccessibilityDescription|nil
  focused = function()
    return Accessibility.focused(runtime)
  end,
  ---@param message string
  ---@param opts? GlyphAccessibilityAnnounceOpts
  ---@return GlyphAccessibilityEvent|nil
  announce = function(message, opts)
    return Accessibility.announce(runtime, message, opts)
  end,
}

ui.feedback = {
  ---@param name string
  ---@param sequence GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)
  ---@return GlyphFeedbackSequence|nil
  define = function(name, sequence)
    return Feedback.define(name, sequence)
  end,
  ---@param nameOrSequence any
  ---@param node? GlyphNode
  ---@param opts? GlyphFeedbackPlayOpts
  ---@return GlyphFeedbackContext|nil
  play = function(nameOrSequence, node, opts)
    return Feedback.play(runtime, nameOrSequence, node, opts)
  end,
  ---@return nil
  clear = function()
    Feedback.clear(runtime)
  end,
}

ui.richTextBackend = {
  ---@param opts? GlyphRichTextBackendConfig
  ---@return nil
  configure = function(opts)
    RichTextBackend.configure(opts)
    runtime:markDirty()
  end,
  ---@return nil
  clear = function()
    RichTextBackend.clear()
    runtime:markDirty()
  end,
}

for name, fn in pairs(Components) do
  ui[name] = fn
end

---@param props? GlyphTabsProps
---@param tabs? GlyphTab[]
---@return GlyphNode
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

---@generic T
---@param initial T|fun(): T
---@return T, fun(value: T|fun(prev: T): T)
function ui.useState(initial)
  return runtime:useState(initial)
end

---@param fn fun(): (fun()|nil)
---@param deps? any[]
function ui.useEffect(fn, deps)
  return runtime:useEffect(fn, deps)
end

---@param component fun(): GlyphNode
---@param deps? any[]
---@return GlyphNode
function ui.memo(component, deps)
  return runtime:memo(component, deps)
end

---@param key string
---@param params? table
---@param opts? GlyphI18nTranslateOpts
---@return string
function ui.t(key, params, opts)
  return I18n.t(key, params, opts)
end

---@param nextTheme GlyphTheme
function ui.setTheme(nextTheme)
  theme.merge(nextTheme)
  runtime.styleCache = {}
  runtime:markDirty()
end

---@return GlyphTheme
function ui.getTheme()
  return theme
end

---@param style GlyphStyle
---@return GlyphStyle
function ui.style(style)
  return Style.create(style)
end

---@param name string
---@param style? GlyphStyle
---@return GlyphVariant
function ui.variant(name, style)
  return Style.variant(name, style)
end

---@param ... GlyphStyle
---@return GlyphStyle
function ui.composeStyles(...)
  return Style.compose(...)
end

---@param loveModule table
function ui.setLove(loveModule)
  runtime:setLove(loveModule)
end

---@param opts GlyphWindowOpts
function ui.configureWindow(opts)
  return Responsive.configureWindow(runtime, opts)
end

---@param width number
---@param height number
function ui.resize(width, height)
  if runtime.viewportBackend and runtime.viewportBackend:isEnabled() then
    runtime.viewportBackend:resize(width, height)
    local viewportWidth, viewportHeight = runtime.viewportBackend:dimensions()
    Responsive.resize(runtime.responsive, viewportWidth, viewportHeight)
  else
    Responsive.resize(runtime.responsive, width, height)
  end
  runtime:markDirty()
end

---@return GlyphViewport
function ui.viewport()
  local viewport = Responsive.viewport(runtime.responsive)
  if runtime.viewportBackend and runtime.viewportBackend:isEnabled() then
    viewport.backend = runtime.viewportBackend:backend()
    viewport.virtual = true
    viewport.screen = runtime.viewportBackend:getViewport()
  end
  return viewport
end

---@return string
function ui.breakpoint()
  return Responsive.breakpoint(runtime.responsive)
end

---@param name string
---@return boolean
function ui.atLeast(name)
  return Responsive.atLeast(runtime.responsive, name)
end

---@param name string
---@return boolean
function ui.below(name)
  return Responsive.below(runtime.responsive, name)
end

---@param values table
---@return any
function ui.responsive(values)
  return Responsive.pick(runtime.responsive, values)
end

---@param containerWidth number
---@param opts? table
---@return any
function ui.columns(containerWidth, opts)
  return Responsive.columns(containerWidth, opts)
end

---@param value number
---@param minValue number
---@param maxValue number
---@return number
function ui.clamp(value, minValue, maxValue)
  return Responsive.clamp(value, minValue, maxValue)
end

---@param node? GlyphNode
---@return boolean
function ui.isHovered(node)
  return node ~= nil and (runtime.hoverNode == node or runtime.hoverPath == node.path)
end

---@param node? GlyphNode
---@return boolean
function ui.isPressed(node)
  return node ~= nil and (runtime.mouseDownNode == node or runtime.mouseDownPath == node.path or runtime.keyDownNode == node or runtime.keyDownPath == node.path)
end

---@param node? GlyphNode
---@return boolean
function ui.isFocused(node)
  return node ~= nil and (runtime.focusNode == node or runtime.focusPath == node.path)
end

---@param node? GlyphNode
---@return boolean
function ui.isActive(node)
  return node ~= nil and node.props and node.props.active == true
end

---@param node? GlyphNode
---@return boolean
function ui.isHot(node)
  return ui.isHovered(node) or ui.isPressed(node) or ui.isFocused(node) or ui.isActive(node)
end

---@param node? GlyphNode
function ui.setFocus(node)
  return runtime:setFocus(node)
end

---@param a number
---@param b number
---@param t number
---@return number
function ui.mix(a, b, t)
  return a + (b - a) * t
end

---@param a GlyphColor
---@param b GlyphColor
---@param t number
---@return GlyphColor
function ui.mixColor(a, b, t)
  return {
    ui.mix(a[1] or 0, b[1] or 0, t),
    ui.mix(a[2] or 0, b[2] or 0, t),
    ui.mix(a[3] or 0, b[3] or 0, t),
    ui.mix(a[4] or 1, b[4] or 1, t),
  }
end

---@param loveModule table
---@param color GlyphColor
---@param alpha? number
function ui.setColor(loveModule, color, alpha)
  if loveModule and loveModule.graphics and color then
    loveModule.graphics.setColor(color[1] or 1, color[2] or 1, color[3] or 1, (color[4] or 1) * (alpha or 1))
  end
end

---@return number
function ui.time()
  local loveModule = runtime.love or _G.love
  if loveModule and loveModule.timer and loveModule.timer.getTime then
    return loveModule.timer.getTime()
  end

  return runtime.styleClock
end

---@param speed? number
---@param phase? number
---@return number
function ui.pulse(speed, phase)
  return (math.sin(ui.time() * (speed or 1) + (phase or 0)) + 1) / 2
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param opts? table skew and inset numbers
---@return number[]
function ui.polygonBox(x, y, width, height, opts)
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

---@param props? GlyphButtonProps
---@return GlyphNode
function ui.customButton(props)
  return Components.button(props)
end

---@param name string
---@param fn fun(...): any
---@param opts? table
---@return fun() unregister
function ui.on(name, fn, opts)
  return runtime:register(name, fn, opts)
end

---@param name string
---@param ... any
function ui.dispatch(name, ...)
  return runtime:dispatch(name, ...)
end

---@param dt number
function ui.update(dt)
  return runtime:update(dt)
end

---@param component fun(): GlyphNode
function ui.render(component)
  return runtime:render(component)
end

local viewportPoint
local clearPointerTarget

local defaultGamepadNavigation = {
  dpup = "up",
  dpdown = "down",
  dpleft = "left",
  dpright = "right",
}

local defaultGamepadButtons = {
  a = "return",
  b = "escape",
}

---@param defaults table<string, any>
---@param overrides? table<string, any>
---@return table<string, any>
local function mergeMapping(defaults, overrides)
  local result = {}
  for key, value in pairs(defaults) do
    result[key] = value
  end

  if type(overrides) == "table" then
    for key, value in pairs(overrides) do
      result[key] = value
    end
  end

  return result
end

---@param opts? boolean|GlyphGamepadMapperOpts
---@return table
local function gamepadMapper(opts)
  if opts == false then
    return { navigation = {}, buttons = {} }
  end
  opts = type(opts) == "table" and opts or {}
  return {
    navigation = mergeMapping(defaultGamepadNavigation, opts.navigation),
    buttons = mergeMapping(defaultGamepadButtons, opts.buttons),
  }
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function ui.mousemoved(x, y, dx, dy)
  local inside, viewX, viewY = viewportPoint(x, y)
  if not inside then
    clearPointerTarget(false)
    return nil
  end
  return runtime:mousemoved(viewX, viewY, dx, dy)
end

---@param x number
---@param y number
---@param button number
function ui.mousepressed(x, y, button)
  local inside, viewX, viewY = viewportPoint(x, y)
  if not inside then
    clearPointerTarget(true)
    return nil
  end
  return runtime:mousepressed(viewX, viewY, button)
end

---@param x number
---@param y number
---@param button number
function ui.mousereleased(x, y, button)
  local inside, viewX, viewY = viewportPoint(x, y)
  if not inside then
    clearPointerTarget(false)
    return nil
  end
  return runtime:mousereleased(viewX, viewY, button)
end

---@param dx number
---@param dy number
function ui.wheelmoved(dx, dy)
  return runtime:wheelmoved(dx, dy)
end

---@param text string
function ui.textinput(text)
  return runtime:textinput(text)
end

---@param key string
function ui.keypressed(key)
  return runtime:keypressed(key)
end

---@param key string
function ui.keyreleased(key)
  return runtime:keyreleased(key)
end

---@param joystick any
---@param button string
---@param opts? boolean|GlyphGamepadMapperOpts
---@return any
function ui.gamepadpressed(joystick, button, opts)
  runtime:dispatch("event", "gamepadpressed", joystick, button)

  local mapper = gamepadMapper(opts)
  local direction = mapper.navigation[button]
  if direction then
    return ui.navigate(direction)
  end

  local key = mapper.buttons[button]
  if key then
    return ui.keypressed(key)
  end

  return nil
end

---@param joystick any
---@param button string
---@param opts? boolean|GlyphGamepadMapperOpts
---@return any
function ui.gamepadreleased(joystick, button, opts)
  runtime:dispatch("event", "gamepadreleased", joystick, button)

  local mapper = gamepadMapper(opts)
  local key = mapper.buttons[button]
  if key then
    return ui.keyreleased(key)
  end

  return nil
end

---@param direction "up"|"down"|"left"|"right"
---@return GlyphNode|nil
function ui.navigate(direction)
  return Navigate.move(runtime, direction)
end

---@param x number
---@param y number
---@return boolean
---@return number|false
---@return number|false
function viewportPoint(x, y)
  if runtime.viewportBackend and runtime.viewportBackend:isEnabled() then
    return runtime.viewportBackend:screenToViewport(x, y)
  end
  return true, x, y
end

---@param clearFocus boolean
---@return nil
function clearPointerTarget(clearFocus)
  runtime:setHover(nil)
  runtime.mouseDownNode = nil
  runtime.mouseDownPath = nil
  runtime.keyDownNode = nil
  runtime.keyDownPath = nil
  runtime.keyDownKey = nil
  if clearFocus then
    runtime:setFocus(nil)
  end
end

---@type GlyphViewportBackendApi
ui.viewportBackend = {
  ---@return boolean
  isEnabled = function()
    return runtime.viewportBackend and runtime.viewportBackend:isEnabled() or false
  end,
  ---@return "push"|"shove"|nil
  backend = function()
    return runtime.viewportBackend and runtime.viewportBackend:backend() or nil
  end,
  ---@param x number
  ---@param y number
  ---@return boolean
  ---@return number|false
  ---@return number|false
  screenToViewport = function(x, y)
    return viewportPoint(x, y)
  end,
  ---@param x number
  ---@param y number
  ---@return number
  ---@return number
  viewportToScreen = function(x, y)
    if runtime.viewportBackend then
      return runtime.viewportBackend:viewportToScreen(x, y)
    end
    return x, y
  end,
  ---@return boolean
  beginDraw = function()
    return runtime.viewportBackend and runtime.viewportBackend:beginDraw() or false
  end,
  ---@return boolean
  endDraw = function()
    return runtime.viewportBackend and runtime.viewportBackend:endDraw() or false
  end,
  ---@return table|nil
  raw = function()
    return runtime.viewportBackend and runtime.viewportBackend:raw() or nil
  end,
}

local autoCallbacks = {
  resize = function(width, height)
    ui.resize(width, height)
  end,
  mousemoved = function(x, y, dx, dy, istouch)
    ui.mousemoved(x, y, dx, dy, istouch)
  end,
  mousepressed = function(x, y, button, istouch, presses)
    ui.mousepressed(x, y, button, istouch, presses)
  end,
  mousereleased = function(x, y, button, istouch, presses)
    ui.mousereleased(x, y, button, istouch, presses)
  end,
  wheelmoved = function(dx, dy)
    ui.wheelmoved(dx, dy)
  end,
  textinput = function(text)
    ui.textinput(text)
  end,
  keypressed = function(key, scancode, isrepeat)
    ui.keypressed(key, scancode, isrepeat)
  end,
  keyreleased = function(key, scancode)
    ui.keyreleased(key, scancode)
  end,
  mousefocus = function(focused)
    ui.dispatch("event", "mousefocus", focused)
  end,
  focus = function(focused)
    ui.dispatch("event", "focus", focused)
  end,
  visible = function(visible)
    ui.dispatch("event", "visible", visible)
  end,
  quit = function()
    ui.dispatch("event", "quit")
  end,
  touchpressed = function(id, x, y, dx, dy, pressure)
    ui.dispatch("event", "touchpressed", id, x, y, dx, dy, pressure)
    ui.mousepressed(x, y, 1)
  end,
  touchmoved = function(id, x, y, dx, dy, pressure)
    ui.dispatch("event", "touchmoved", id, x, y, dx, dy, pressure)
    ui.mousemoved(x, y, dx, dy)
  end,
  touchreleased = function(id, x, y, dx, dy, pressure)
    ui.dispatch("event", "touchreleased", id, x, y, dx, dy, pressure)
    ui.mousereleased(x, y, 1)
  end,
}

---@param previous? function
---@param nextCallback function
---@param order? "before"|"after"
---@return function
local function chainCallback(previous, nextCallback, order)
  if order == "before" then
    return function(...)
      nextCallback(...)
      if previous then
        return previous(...)
      end
    end
  end

  return function(...)
    local results
    if previous then
      results = { previous(...) }
    end
    nextCallback(...)
    if results then
      return (table.unpack or unpack)(results)
    end
  end
end

---@param loveModule? table
---@param opts? GlyphInstallOpts
---@return fun() uninstall
function ui.install(loveModule, opts)
  opts = opts or {}
  loveModule = loveModule or _G.love

  if not loveModule then
    error("[glyph] love module is required to install callbacks", 2)
  end

  ui.setLove(loveModule)

  local order = opts.order or "after"
  local callbacks = opts.callbacks or autoCallbacks
  local previousCallbacks = {}
  local installedNames = {}
  local installedByName = {}

  local function installCallback(name, callback)
    if installedByName[name] then
      return
    end
    installedByName[name] = true
    previousCallbacks[name] = loveModule[name]
    installedNames[#installedNames + 1] = name
    loveModule[name] = chainCallback(loveModule[name], callback, order)
  end

  for name, callback in pairs(callbacks) do
    local enabled = opts[name]
    if enabled ~= false then
      installCallback(name, callback)
    end
  end

  if opts.gamepad then
    if opts.gamepadpressed ~= false then
      installCallback("gamepadpressed", function(joystick, button)
        ui.gamepadpressed(joystick, button, opts.gamepad)
      end)
    end
    if opts.gamepadreleased ~= false then
      installCallback("gamepadreleased", function(joystick, button)
        ui.gamepadreleased(joystick, button, opts.gamepad)
      end)
    end
  end

  if opts.app then
    previousCallbacks.update = loveModule.update
    previousCallbacks.draw = loveModule.draw
    installedNames[#installedNames + 1] = "update"
    installedNames[#installedNames + 1] = "draw"
    loveModule.update = chainCallback(loveModule.update, function(dt)
      ui.update(dt)
    end, order)

    loveModule.draw = chainCallback(loveModule.draw, function()
      ui.render(opts.app)
    end, order)
  end

  runtime.installedLove = loveModule
  return function()
    for _, name in ipairs(installedNames) do
      loveModule[name] = previousCallbacks[name]
    end
  end
end

ui.attachLove = ui.install

ui.scene = {
  set = function(id, component, opts)
    return runtime.scene:set(id, component, opts)
  end,
  push = function(id, component, opts)
    return runtime.scene:push(id, component, opts)
  end,
  pop = function(id)
    return runtime.scene:pop(id)
  end,
  close = function(id)
    return runtime.scene:close(id)
  end,
  clear = function(predicate)
    return runtime.scene:clear(predicate)
  end,
  current = function()
    return runtime.scene:current()
  end,
  isOpen = function(id)
    return runtime.scene:isOpen(id)
  end,
  layers = function()
    return runtime.scene.layers
  end,
}

ui.modal = {
  open = function(id, component, opts)
    return Modal.open(runtime.scene, id, component, opts)
  end,
  close = function(id)
    return Modal.close(runtime.scene, id)
  end,
  closeAll = function()
    return Modal.closeAll(runtime.scene)
  end,
  isOpen = function(id)
    return Modal.isOpen(runtime.scene, id)
  end,
  transitions = Transitions,
}

---@param opts? GlyphLoadOpts
---@return fun() uninstall
function ui.load(opts)
  opts = opts or {}
  local loveModule = opts.love or _G.love

  if opts.theme then
    ui.setTheme(opts.theme)
  end

  if opts.window then
    ui.setLove(loveModule)
    ui.configureWindow(opts.window)
  elseif loveModule then
    ui.setLove(loveModule)
  end

  local installOptions = opts.install or {}
  for key, value in pairs(opts) do
    if key ~= "window" and key ~= "theme" and key ~= "love" and key ~= "install" then
      installOptions[key] = value
    end
  end

  return ui.install(loveModule, installOptions)
end

return ui
