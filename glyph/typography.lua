local Typography = {}

local fontCache = {}

local DEFAULT_STYLE_BY_TYPE = {
  button = "button",
  input = "input",
  text = "text",
  meter = "text",
  panel = "text",
}

local STACK_TAGS = {
  color = true,
  font = true,
  size = true,
  style = true,
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

---@param value string|nil
---@return GlyphColor|nil
local function parseColor(value)
  if not value or value == "" then
    return nil
  end

  if value:sub(1, 1) == "#" then
    local hex = value:sub(2)
    if #hex == 6 or #hex == 8 then
      local r = tonumber(hex:sub(1, 2), 16)
      local g = tonumber(hex:sub(3, 4), 16)
      local b = tonumber(hex:sub(5, 6), 16)
      local a = #hex == 8 and tonumber(hex:sub(7, 8), 16) or 255
      if r and g and b and a then
        return { r / 255, g / 255, b / 255, a / 255 }
      end
    end
  end

  local parts = {}
  for part in value:gmatch("[^,]+") do
    parts[#parts + 1] = tonumber(part)
  end

  if #parts >= 3 and parts[1] and parts[2] and parts[3] then
    return { parts[1], parts[2], parts[3], parts[4] or 1 }
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
  return type(props) == "table" and (props.rich == true or props.format == "tags")
end

---@param source any
---@param theme table
---@param props? table
---@return table[]
function Typography.parse(source, theme, props)
  local text = tostring(source or "")
  local segments = {}
  local stack = {}
  local current = {}
  local buffer = {}
  local index = 1

  local function pushText(value)
    if value and value ~= "" then
      segments[#segments + 1] = {
        text = value,
        style = copyTable(current) or {},
      }
    end
  end

  local function flush()
    if #buffer > 0 then
      pushText(table.concat(buffer))
      buffer = {}
    end
  end

  local function rebuildStyle()
    current = {}
    for _, frame in ipairs(stack) do
      mergeInto(current, frame.style)
    end
  end

  local function openTag(name, value)
    local style = {}
    if name == "color" then
      local color = parseColor(value)
      if not color then
        return false
      end
      style.color = color
    elseif name == "font" then
      if not value or value == "" then
        return false
      end
      style.font = value
    elseif name == "size" then
      local size = tonumber(value)
      if not size then
        return false
      end
      style.fontSize = size
    elseif name == "style" then
      local preset = typographyStyle(theme, value)
      if not preset then
        return false
      end
      mergeInto(style, preset)
    else
      return false
    end

    stack[#stack + 1] = { name = name, style = style }
    rebuildStyle()
    return true
  end

  local function closeTag(name)
    if not STACK_TAGS[name] then
      return false
    end

    for frameIndex = #stack, 1, -1 do
      if stack[frameIndex].name == name then
        table.remove(stack, frameIndex)
        rebuildStyle()
        return true
      end
    end

    return false
  end

  while index <= #text do
    local char = text:sub(index, index)
    if char == "[" then
      if text:sub(index, index + 1) == "[[" then
        buffer[#buffer + 1] = "["
        index = index + 2
      else
        local closeIndex = text:find("]", index + 1, true)
        if closeIndex then
          local tag = text:sub(index + 1, closeIndex - 1)
          local handled = false
          if tag == "br" then
            flush()
            segments[#segments + 1] = { br = true }
            handled = true
          elseif tag:sub(1, 1) == "/" then
            flush()
            handled = closeTag(tag:sub(2))
          else
            local name, value = tag:match("^([%w_%-]+)=(.*)$")
            if name then
              flush()
              handled = openTag(name, value)
            end
          end

          if handled then
            index = closeIndex + 1
          else
            buffer[#buffer + 1] = text:sub(index, closeIndex)
            index = closeIndex + 1
          end
        else
          buffer[#buffer + 1] = char
          index = index + 1
        end
      end
    else
      buffer[#buffer + 1] = char
      index = index + 1
    end
  end

  flush()

  if #segments == 0 then
    segments[1] = { text = "", style = {} }
  end

  return segments
end

---@param theme table
---@param props? table
---@param baseStyle? table
---@param segmentStyle? table
---@return table
local function mergedProps(theme, props, baseStyle, segmentStyle)
  local merged = {}
  mergeInto(merged, props)
  mergeInto(merged, segmentStyle)
  return merged
end

---@param segments table[]
---@param props table
---@param theme table
---@param widthLimit? number
---@param loveModule? table
---@param baseStyle? table
---@param defaultStyle? string
---@return table
function Typography.layoutRich(segments, props, theme, widthLimit, loveModule, baseStyle, defaultStyle)
  local limit = widthLimit and math.max(1, widthLimit) or nil
  local base = Typography.resolve(theme, props, baseStyle, defaultStyle)
  local lines = {}
  local line = { segments = {}, width = 0, height = base.lineHeight or theme.lineHeight or 18, baseline = 0 }
  local units = {}
  local pendingSpace = ""

  local function pushLine()
    lines[#lines + 1] = line
    line = { segments = {}, width = 0, height = base.lineHeight or theme.lineHeight or 18, baseline = 0 }
  end

  local function addChunk(text, style)
    if text == "" then
      return
    end

    local chunkProps = mergedProps(theme, props, baseStyle, style)
    local width, height = Typography.measurePlain(text, chunkProps, theme, loveModule, baseStyle, defaultStyle)
    line.segments[#line.segments + 1] = {
      text = text,
      style = copyTable(style) or {},
      width = width,
      height = height,
    }
    line.width = line.width + width
    line.height = math.max(line.height, height)
    line.baseline = math.max(line.baseline or 0, height)
  end

  local function pushPendingSpace(style)
    if pendingSpace ~= "" then
      units[#units + 1] = { text = pendingSpace, style = style or {}, whitespace = true }
      pendingSpace = ""
    end
  end

  local function appendSegmentText(text, style)
    local index = 1
    while index <= #text do
      local char = text:sub(index, index)
      if char == "\n" then
        pushPendingSpace(style)
        units[#units + 1] = { br = true }
        index = index + 1
      elseif char:match("%s") then
        local nextIndex = index
        while nextIndex <= #text and text:sub(nextIndex, nextIndex):match("%s") and text:sub(nextIndex, nextIndex) ~= "\n" do
          nextIndex = nextIndex + 1
        end
        pendingSpace = pendingSpace .. text:sub(index, nextIndex - 1)
        index = nextIndex
      else
        local nextIndex = index
        while nextIndex <= #text and not text:sub(nextIndex, nextIndex):match("%s") do
          nextIndex = nextIndex + 1
        end
        units[#units + 1] = {
          text = pendingSpace .. text:sub(index, nextIndex - 1),
          style = style,
        }
        pendingSpace = ""
        index = nextIndex
      end
    end
  end

  for _, segment in ipairs(segments) do
    if segment.br then
      pushPendingSpace(segment.style)
      units[#units + 1] = { br = true }
    else
      appendSegmentText(segment.text or "", segment.style)
    end
  end
  pushPendingSpace({})

  local function placeUnit(unit)
    if unit.br then
      pushLine()
      return
    end

    local text = unit.text or ""
    if text == "" or (line.width == 0 and text:match("^%s+$")) then
      return
    end

    local tokenProps = mergedProps(theme, props, baseStyle, unit.style)
    local width = Typography.measurePlain(text, tokenProps, theme, loveModule, baseStyle, defaultStyle)
    if limit and line.width > 0 and line.width + width > limit then
      pushLine()
      text = text:gsub("^%s+", "")
      if text == "" then
        return
      end
      width = Typography.measurePlain(text, tokenProps, theme, loveModule, baseStyle, defaultStyle)
    end

    if limit and line.width == 0 and width > limit and #text > 1 then
      local current = ""
      for charIndex = 1, #text do
        local nextText = current .. text:sub(charIndex, charIndex)
        local nextWidth = Typography.measurePlain(nextText, tokenProps, theme, loveModule, baseStyle, defaultStyle)
        if current ~= "" and nextWidth > limit then
          addChunk(current, unit.style)
          pushLine()
          current = text:sub(charIndex, charIndex)
        else
          current = nextText
        end
      end
      addChunk(current, unit.style)
      return
    end

    addChunk(text, unit.style)
  end

  for _, unit in ipairs(units) do
    placeUnit(unit)
  end

  if #line.segments > 0 or #lines == 0 then
    pushLine()
  end

  local width = limit or 0
  local height = 0
  for _, item in ipairs(lines) do
    width = math.max(width, item.width or 0)
    height = height + (item.height or base.lineHeight or theme.lineHeight or 18)
  end

  return {
    lines = lines,
    width = width,
    height = height,
  }
end

---@return nil
function Typography.clearCache()
  fontCache = {}
end

return Typography
