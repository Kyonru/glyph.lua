local Components = require("glyph.components")
local CallbackBus = require("glyph.callback_bus")
local Responsive = require("glyph.responsive")
local Runtime = require("glyph.runtime")
local Style = require("glyph.style")
local theme = require("glyph.theme")

local runtime = Runtime.new()

local ui = {
  CallbackBus = CallbackBus,
  Responsive = Responsive,
  Style = Style,
  runtime = runtime,
  theme = theme,
}

for name, fn in pairs(Components) do
  ui[name] = fn
end

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

function ui.setTheme(nextTheme)
  theme.merge(nextTheme)
  runtime.styleCache = {}
  runtime:markDirty()
end

function ui.getTheme()
  return theme
end

function ui.style(style)
  return Style.create(style)
end

function ui.variant(name, style)
  return Style.variant(name, style)
end

function ui.composeStyles(...)
  return Style.compose(...)
end

function ui.setLove(loveModule)
  runtime:setLove(loveModule)
end

function ui.configureWindow(opts)
  return Responsive.configureWindow(runtime, opts)
end

function ui.resize(width, height)
  Responsive.resize(runtime.responsive, width, height)
  runtime:markDirty()
end

function ui.viewport()
  return Responsive.viewport(runtime.responsive)
end

function ui.breakpoint()
  return Responsive.breakpoint(runtime.responsive)
end

function ui.atLeast(name)
  return Responsive.atLeast(runtime.responsive, name)
end

function ui.below(name)
  return Responsive.below(runtime.responsive, name)
end

function ui.responsive(values)
  return Responsive.pick(runtime.responsive, values)
end

function ui.columns(containerWidth, opts)
  return Responsive.columns(containerWidth, opts)
end

function ui.clamp(value, minValue, maxValue)
  return Responsive.clamp(value, minValue, maxValue)
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
  return runtime:render(component)
end

function ui.mousemoved(x, y, dx, dy)
  return runtime:mousemoved(x, y, dx, dy)
end

function ui.mousepressed(x, y, button)
  return runtime:mousepressed(x, y, button)
end

function ui.mousereleased(x, y, button)
  return runtime:mousereleased(x, y, button)
end

function ui.wheelmoved(dx, dy)
  return runtime:wheelmoved(dx, dy)
end

function ui.textinput(text)
  return runtime:textinput(text)
end

function ui.keypressed(key)
  return runtime:keypressed(key)
end

return ui
