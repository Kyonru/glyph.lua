local Style = {}

local STATE_KEYS = {
  hover = true,
  pressed = true,
  focused = true,
  active = true,
  disabled = true,
}

local VISUAL_ALIASES = {
  backgroundColor = "background",
  color = "color",
  borderColor = "borderColor",
  borderWidth = "borderWidth",
  radius = "radius",
  lineWidth = "lineWidth",
  font = "font",
  fontSize = "fontSize",
  opacity = "opacity",
  shader = "shader",
  blendMode = "blendMode",
}

local function isArray(value)
  return type(value) == "table" and value[1] ~= nil
end

local function copyValue(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, child in pairs(value) do
    copy[key] = copyValue(child)
  end
  return copy
end

local function mergeInto(target, source)
  if type(source) ~= "table" then
    return target
  end

  for key, value in pairs(source) do
    if not STATE_KEYS[key] and key ~= "variants" then
      if type(value) == "table" and type(target[key]) == "table" and not isArray(value) then
        mergeInto(target[key], value)
      else
        target[key] = copyValue(value)
      end
    end
  end

  return target
end

local function normalizeLegacyProps(props)
  local style = {}

  for propName, styleName in pairs(VISUAL_ALIASES) do
    if props[propName] ~= nil then
      style[styleName] = copyValue(props[propName])
    end
  end

  return style
end

local function stateKey(state)
  return table.concat({
    state.hover and "h" or "-",
    state.pressed and "p" or "-",
    state.focused and "f" or "-",
    state.active and "a" or "-",
    state.disabled and "d" or "-",
  }, "")
end

local function applyState(resolved, source, name, enabled)
  if enabled and type(source) == "table" and type(source[name]) == "table" then
    mergeInto(resolved, source[name])
  end
end

local function cacheKey(node, runtime, state)
  local props = node.props or {}
  return table.concat({
    tostring(runtime.theme.version or 0),
    node.path or "",
    props.styleType or node.type or "",
    tostring(props.variant or ""),
    stateKey(state),
    tostring(props.style),
  }, "|")
end

local function componentTheme(theme, node)
  local components = theme.components or {}
  local props = node.props or {}
  return components[props.styleType or node.type] or {}
end

local function mergeAudio(target, source)
  if type(source) ~= "table" then
    return target
  end

  for key, value in pairs(source) do
    target[key] = copyValue(value)
  end

  return target
end

function Style.stateFor(node, runtime)
  local props = node.props or {}
  return {
    hover = runtime.hoverNode == node or runtime.hoverPath == node.path,
    pressed = runtime.mouseDownNode == node or runtime.mouseDownPath == node.path or runtime.keyDownNode == node or runtime.keyDownPath == node.path,
    focused = runtime.focusNode == node or runtime.focusPath == node.path,
    active = props.active == true,
    disabled = props.disabled == true,
  }
end

function Style.resolve(node, runtime, state)
  state = state or Style.stateFor(node, runtime)
  runtime.styleCache = runtime.styleCache or {}

  local key = cacheKey(node, runtime, state)
  local cached = runtime.styleCache[node.path]
  if cached and cached.key == key then
    node.resolvedStyle = cached.style
    return cached.style
  end

  local props = node.props or {}
  local theme = runtime.theme
  local resolved = {}
  local component = componentTheme(theme, node)
  local variant = component.variants and props.variant and component.variants[props.variant] or nil

  mergeInto(resolved, theme.base)
  mergeInto(resolved, component)
  mergeInto(resolved, variant)

  applyState(resolved, component, "hover", state.hover)
  applyState(resolved, component, "pressed", state.pressed)
  applyState(resolved, component, "focused", state.focused)
  applyState(resolved, component, "active", state.active)
  applyState(resolved, component, "disabled", state.disabled)

  applyState(resolved, variant, "hover", state.hover)
  applyState(resolved, variant, "pressed", state.pressed)
  applyState(resolved, variant, "focused", state.focused)
  applyState(resolved, variant, "active", state.active)
  applyState(resolved, variant, "disabled", state.disabled)

  mergeInto(resolved, normalizeLegacyProps(props))
  mergeInto(resolved, props.style)
  applyState(resolved, props.style, "hover", state.hover)
  applyState(resolved, props.style, "pressed", state.pressed)
  applyState(resolved, props.style, "focused", state.focused)
  applyState(resolved, props.style, "active", state.active)
  applyState(resolved, props.style, "disabled", state.disabled)

  node.resolvedStyle = resolved
  runtime.styleCache[node.path] = {
    key = key,
    style = resolved,
  }

  return resolved
end

function Style.resolveAudio(node, runtime, kind)
  local props = node and node.props or {}
  if props.audio == false then
    return nil
  end

  local theme = runtime.theme or {}
  local component = componentTheme(theme, node)
  local variant = component.variants and props.variant and component.variants[props.variant] or nil
  local resolved = {}

  mergeAudio(resolved, component.audio)
  mergeAudio(resolved, variant and variant.audio)
  mergeAudio(resolved, props.audio)

  return resolved[kind]
end

---@param ... GlyphStyle
---@return GlyphStyle
function Style.compose(...)
  local result = {}
  for index = 1, select("#", ...) do
    mergeInto(result, select(index, ...))
  end
  return result
end

---@param style? GlyphStyle
---@return GlyphStyle
function Style.create(style)
  return copyValue(style or {})
end

---@param name string
---@param style? GlyphStyle
---@return GlyphVariant
function Style.variant(name, style)
  return {
    name = name,
    style = Style.create(style),
  }
end

function Style.isColor(value)
  return type(value) == "table" and type(value[1]) == "number" and type(value[2]) == "number" and type(value[3]) == "number"
end

function Style.copyValue(value)
  return copyValue(value)
end

return Style
