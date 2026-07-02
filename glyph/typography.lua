local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local Filter = require(prefix .. ".filter")

local Typography = {}

local fontCache = {}

-- Measuring wrapped text calls font:getWidth() once per word/candidate every
-- layout pass, so cache it per (font, text). Outer tables are weak-keyed by the
-- font object, so a font that goes out of scope drops its entries; a count cap
-- bounds growth from many distinct strings.
local widthCache = setmetatable({}, { __mode = "k" })
local heightCache = setmetatable({}, { __mode = "k" })
local widthCacheCount = 0
local WIDTH_CACHE_LIMIT = 8192

local function cachedWidth(font, text)
  local key = tostring(text)
  local perFont = widthCache[font]
  if not perFont then
    perFont = {}
    widthCache[font] = perFont
  end

  local width = perFont[key]
  if width == nil then
    width = font:getWidth(key)
    perFont[key] = width
    widthCacheCount = widthCacheCount + 1
    if widthCacheCount > WIDTH_CACHE_LIMIT then
      widthCache = setmetatable({}, { __mode = "k" })
      widthCacheCount = 0
    end
  end

  return width
end

local function cachedHeight(font)
  local height = heightCache[font]
  if height == nil then
    height = font:getHeight()
    heightCache[font] = height
  end
  return height
end

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
  local valueType = type(value)
  if valueType ~= "table" and valueType ~= "userdata" then
    return false
  end

  return type(value.getWidth) == "function" and type(value.getHeight) == "function"
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

local function fontHasText(font, text)
  if text == nil or text == "" or not isFontObject(font) or type(font.hasGlyphs) ~= "function" then
    return true
  end

  local ok, hasGlyphs = pcall(font.hasGlyphs, font, tostring(text))
  if not ok then
    return true
  end
  return hasGlyphs ~= false
end

---@param spec table
---@param size number
---@param graphics table
---@param cacheKey string
---@return any
local function loadSpecFont(spec, size, graphics, cacheKey, filterSpec)
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
    Filter.apply(font, filterSpec or Filter.fromFields(spec))
    fontCache[cacheKey] = font
    return font
  end

  return nil
end

local function loadResolvedFont(fontRef, resolved, theme, graphics, fontFilter, allowDefault)
  if isFontObject(fontRef) then
    return fontRef, fontFilter
  end

  if type(fontRef) == "table" then
    local specSize = resolved.fontSize or fontRef.size or theme.fontSize or 13
    local size = math.max(1, math.floor(specSize + 0.5))
    local specFilter = Filter.fromFields(fontRef, fontFilter)
    local key = table.concat({
      "spec",
      tostring(fontRef.path or ""),
      tostring(size),
      tostring(fontRef.hinting or ""),
      Filter.key(specFilter),
    }, "|")
    return loadSpecFont(fontRef, size, graphics, key, specFilter), specFilter
  end

  if allowDefault and graphics and type(graphics.newFont) == "function" then
    local fontSize = math.max(1, math.floor((resolved.fontSize or theme.fontSize or 13) + 0.5))
    local key = "default|" .. tostring(fontSize) .. "|" .. Filter.key(fontFilter)
    return loadSpecFont({}, fontSize, graphics, key, fontFilter), fontFilter
  end

  return fontRef, fontFilter
end

local function appendFallback(target, seen, ref)
  if ref == nil then
    return
  end

  local key = tostring(ref)
  if type(ref) == "table" and ref.path then
    key = "path:" .. tostring(ref.path)
  end
  if seen[key] then
    return
  end

  seen[key] = true
  target[#target + 1] = ref
end

local function fontFallbacks(theme, props, resolved)
  local fallbacks = {}
  local seen = {}
  local explicit = props and props.fontFallbacks or resolved and resolved.fontFallbacks or theme and theme.fontFallbacks or nil

  if type(explicit) == "string" then
    appendFallback(fallbacks, seen, explicit)
  elseif type(explicit) == "table" then
    for _, ref in ipairs(explicit) do
      appendFallback(fallbacks, seen, ref)
    end
  end

  local fonts = theme and theme.fonts or nil
  if type(fonts) == "table" then
    local names = {}
    for name in pairs(fonts) do
      names[#names + 1] = name
    end
    table.sort(names, function(a, b)
      return tostring(a) < tostring(b)
    end)
    for _, name in ipairs(names) do
      appendFallback(fallbacks, seen, name)
    end
  end

  return fallbacks
end

local function applyTextFallback(theme, props, resolved, graphics, text)
  if fontHasText(resolved.font, text) then
    return resolved
  end

  for _, ref in ipairs(fontFallbacks(theme, props, resolved)) do
    local fontRef = resolveFontRef(ref, theme)
    local font, filter = loadResolvedFont(fontRef, resolved, theme, graphics, resolved.fontFilter, false)
    if font ~= resolved.font and fontHasText(font, text) then
      resolved.font = font
      resolved.fontFilter = filter
      return resolved
    end
  end

  return resolved
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
  if props.fontFilter ~= nil then
    resolved.fontFilter = props.fontFilter
  end
  if props.fontFallbacks ~= nil then
    resolved.fontFallbacks = props.fontFallbacks
  end
  if props.color ~= nil then
    resolved.color = props.color
  end

  local textScale = theme.textScale or 1
  resolved.fontSize = (resolved.fontSize or theme.fontSize or 13) * textScale
  resolved.lineHeight = (resolved.lineHeight or theme.lineHeight or resolved.fontSize or 18) * textScale
  resolved.font = resolved.font or theme.font
  resolved.fontFilter = resolved.fontFilter or theme.fontFilter
  resolved.color = resolved.color or theme.textColor

  return resolved
end

---@param theme table
---@param props? table
---@param baseStyle? table
---@param defaultStyle? string
---@param loveModule? table
---@param text? string
---@return table
function Typography.resolveDrawable(theme, props, baseStyle, defaultStyle, loveModule, text)
  theme = theme or {}
  local resolved = Typography.resolve(theme, props, baseStyle, defaultStyle)
  local graphics = loveModule and loveModule.graphics
  local fontRef = resolveFontRef(resolved.font, theme)
  local fontFilter = Filter.resolve(resolved.fontFilter)
  resolved.fontFilter = fontFilter

  resolved.font, resolved.fontFilter = loadResolvedFont(fontRef, resolved, theme, graphics, fontFilter, true)

  return applyTextFallback(theme, props, resolved, graphics, text)
end

---@param text string
---@param props? table
---@param theme table
---@param loveModule? table
---@param baseStyle? table
---@param defaultStyle? string
---@return number, number
function Typography.measurePlain(text, props, theme, loveModule, baseStyle, defaultStyle)
  local resolved = Typography.resolveDrawable(theme, props, baseStyle, defaultStyle, loveModule, text)
  local font = resolved.font

  if isFontObject(font) then
    return cachedWidth(font, text), resolved.lineHeight or cachedHeight(font)
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
  widthCache = setmetatable({}, { __mode = "k" })
  heightCache = setmetatable({}, { __mode = "k" })
  widthCacheCount = 0
end

return Typography
