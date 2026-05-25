local RichTextBackend = {}

local config = {
  sysl = nil,
  defaults = nil,
  configure = nil,
  configured = false,
}

local cache = {}

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

local function alignFor(props)
  local align = props and props.textAlign or nil
  if align == "right" then
    return "right"
  elseif align == "center" then
    return "center"
  elseif align == "justify" or align == "full" then
    return "full"
  end

  return "left"
end

local function cacheKey(node, text, width, props, themeVersion)
  return table.concat({
    node and (node.path or node.props and node.props.key or "") or "",
    tostring(text or ""),
    tostring(width or ""),
    alignFor(props),
    tostring(themeVersion or 0),
  }, "|")
end

local function fallbackMeasure(text, width)
  return {
    fallback = true,
    width = width or #tostring(text or "") * 7,
    height = 18,
    lines = 1,
  }
end

local function ensureConfigured()
  if config.configured then
    return
  end

  config.configured = true
  if type(config.configure) == "function" then
    config.configure(config.sysl)
  end

  local configure = config.sysl and config.sysl.configure
  if configure and type(configure.function_command_enable) == "function" then
    configure.function_command_enable(false)
  end
end

local function createTextbox(props)
  local sysl = config.sysl
  if not sysl or type(sysl.new) ~= "function" then
    return nil
  end

  ensureConfigured()
  return sysl.new(alignFor(props), copyTable(config.defaults or {}))
end

---@param opts? GlyphRichTextBackendConfig
---@return nil
function RichTextBackend.configure(opts)
  opts = opts or {}
  config.sysl = opts.sysl
  config.defaults = opts.defaults
  config.configure = opts.configure
  config.configured = false
  cache = {}
end

---@return nil
function RichTextBackend.clear()
  config.sysl = nil
  config.defaults = nil
  config.configure = nil
  config.configured = false
  cache = {}
end

---@return boolean
function RichTextBackend.isConfigured()
  return config.sysl ~= nil and type(config.sysl.new) == "function"
end

---@param node GlyphNode
---@param text string
---@param width? number
---@param props table
---@param themeVersion? number
---@return table
function RichTextBackend.prepare(node, text, width, props, themeVersion)
  text = tostring(text or "")
  props = props or {}

  if not RichTextBackend.isConfigured() then
    return fallbackMeasure(text, width)
  end

  local key = cacheKey(node, text, width, props, themeVersion)
  local cached = cache[key]
  if cached then
    return cached
  end

  local textbox = createTextbox(props)
  if not textbox or type(textbox.send) ~= "function" then
    return fallbackMeasure(text, width)
  end

  textbox:send(text, width, width ~= nil)
  local get = textbox.get or {}
  cached = {
    key = key,
    textbox = textbox,
    width = get.width or width or 0,
    height = get.height or 0,
    lines = get.lines or 1,
  }
  cache[key] = cached
  return cached
end

---@param entry table
---@param x number
---@param y number
---@return boolean
function RichTextBackend.draw(entry, x, y)
  if entry and entry.textbox and type(entry.textbox.draw) == "function" then
    entry.textbox:draw(x, y)
    return true
  end

  return false
end

return RichTextBackend
