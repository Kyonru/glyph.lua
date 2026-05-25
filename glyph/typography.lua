local Typography = {}

local fontCache = {}

local DEFAULT_STYLE_BY_TYPE = {
  button = "button",
  input = "input",
  text = "text",
  meter = "text",
  panel = "text",
}

---@param value any
---@return table|nil
local function copyTable(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, child in pairs(value) do
    copy[key] = copyTable(child)
  end
  return copy
end

---@param target table
---@param source? table
---@return table
local function mergeInto(target, source)
  if type(source) ~= "table" then
    return target
  end

  for key, value in pairs(source) do
    if key ~= "variants" and key ~= "hover" and key ~= "pressed" and key ~= "focused" and key ~= "active" and key ~= "disabled" then
      if type(value) == "table" and type(target[key]) == "table" and value[1] == nil then
        mergeInto(target[key], value)
      else
        target[key] = copyTable(value)
      end
    end
  end

  return target
end

---@param value any
---@return boolean
local function isFontObject(value)
  return type(value) == "table" and type(value.getWidth) == "function" and type(value.getHeight) == "function"
end

---@param value any
---@param theme table
---@return any
local function resolveFontRef(value, theme)
  if type(value) == "string" and theme and type(theme.fonts) == "table" and theme.fonts[value] ~= nil then
    return theme.fonts[value]
  end

  return value
end

---@param spec table
---@param size number
---@param graphics table
---@param cacheKey string
---@return any
local function loadSpecFont(spec, size, graphics, cacheKey)
  if not graphics or type(graphics.newFont) ~= "function" then
    return nil
  end

  if fontCache[cacheKey] then
    return fontCache[cacheKey]
  end

  local ok, font
  if spec.path then
    ok, font = pcall(graphics.newFont, spec.path, size, spec.hinting)
  else
    ok, font = pcall(graphics.newFont, size)
  end

  if ok then
    fontCache[cacheKey] = font
    return font
  end

  return nil
end

---@param theme table
---@param name? string
---@return table|nil
local function typographyStyle(theme, name)
  if type(theme) ~= "table" or type(theme.typography) ~= "table" then
    return nil
  end

  return theme.typography[name or "text"]
end

---@param theme table
---@param props? table
---@param baseStyle? table
---@param defaultStyle? string
---@return table
function Typography.resolve(theme, props, baseStyle, defaultStyle)
  props = props or {}
  theme = theme or {}
  local styleName = props.textStyle or defaultStyle or DEFAULT_STYLE_BY_TYPE[props.type] or "text"
  local resolved = {}

  mergeInto(resolved, typographyStyle(theme, "text"))
  if styleName ~= "text" then
    mergeInto(resolved, typographyStyle(theme, styleName))
  end
  mergeInto(resolved, baseStyle)

  if props.font ~= nil then
    resolved.font = props.font
  end
  if props.fontSize ~= nil then
    resolved.fontSize = props.fontSize
  end
  if props.lineHeight ~= nil then
    resolved.lineHeight = props.lineHeight
  end
  if props.color ~= nil then
    resolved.color = props.color
  end

  local textScale = theme.textScale or 1
  resolved.fontSize = (resolved.fontSize or theme.fontSize or 13) * textScale
  resolved.lineHeight = (resolved.lineHeight or theme.lineHeight or resolved.fontSize or 18) * textScale
  resolved.font = resolved.font or theme.font
  resolved.color = resolved.color or theme.textColor

  return resolved
end

---@param theme table
---@param props? table
---@param baseStyle? table
---@param defaultStyle? string
---@param loveModule? table
---@return table
function Typography.resolveDrawable(theme, props, baseStyle, defaultStyle, loveModule)
  local resolved = Typography.resolve(theme, props, baseStyle, defaultStyle)
  local graphics = loveModule and loveModule.graphics
  local fontRef = resolveFontRef(resolved.font, theme)
  local fontSize = math.max(1, math.floor((resolved.fontSize or theme.fontSize or 13) + 0.5))

  if isFontObject(fontRef) then
    resolved.font = fontRef
    return resolved
  end

  if type(fontRef) == "table" then
    local specSize = resolved.fontSize or fontRef.size or theme.fontSize or 13
    local size = math.max(1, math.floor(specSize + 0.5))
    local key = table.concat({
      "spec",
      tostring(fontRef.path or ""),
      tostring(size),
      tostring(fontRef.hinting or ""),
    }, "|")
    resolved.font = loadSpecFont(fontRef, size, graphics, key)
    return resolved
  end

  if graphics and type(graphics.newFont) == "function" then
    local key = "default|" .. tostring(fontSize)
    resolved.font = loadSpecFont({}, fontSize, graphics, key)
  else
    resolved.font = fontRef
  end

  return resolved
end

---@param text string
---@param props? table
---@param theme table
---@param loveModule? table
---@param baseStyle? table
---@param defaultStyle? string
---@return number, number
function Typography.measurePlain(text, props, theme, loveModule, baseStyle, defaultStyle)
  local resolved = Typography.resolveDrawable(theme, props, baseStyle, defaultStyle, loveModule)
  local font = resolved.font

  if isFontObject(font) then
    return font:getWidth(text), resolved.lineHeight or font:getHeight()
  end

  local fontSize = resolved.fontSize or theme.fontSize or 13
  return #tostring(text) * fontSize * 0.54, resolved.lineHeight or theme.lineHeight or fontSize
end

---@param props? table
---@return boolean
function Typography.isRich(props)
  return type(props) == "table" and props.format == "sysl"
end

---@return nil
function Typography.clearCache()
  fontCache = {}
end

return Typography
