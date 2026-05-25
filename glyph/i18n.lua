local I18n = {}

---@type GlyphI18nConfig
local config = {}
---@type table<string, string>
local cache = {}
local locale = nil
local version = 0
---@type fun()|nil
local onInvalidate = nil

---@param value any
---@return string
local function stablePart(value)
  if type(value) ~= "table" then
    return tostring(value)
  end

  local keys = {}
  for key in pairs(value) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)

  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = tostring(key) .. "=" .. stablePart(value[key])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

---@return any
local function currentLocale()
  if type(config.getLocale) == "function" then
    local current = config.getLocale()
    if current ~= nil then
      return current
    end
  end
  return locale
end

---@param key string
---@param params? table
---@param opts? GlyphI18nTranslateOpts
---@return string|nil
local function missingValue(key, params, opts)
  if type(config.missing) == "function" then
    local value = config.missing(key, params, opts)
    if value ~= nil then
      return value
    end
  end

  opts = opts or {}
  if opts.fallback ~= nil then
    return opts.fallback
  end
  if opts.default ~= nil then
    return opts.default
  end
  return key
end

---@param key string
---@param params? table
---@param opts? GlyphI18nTranslateOpts
---@return string|nil
local function cacheKey(key, params, opts)
  opts = opts or {}
  local keyFallback = opts.fallback
  if keyFallback == nil then
    keyFallback = opts.default
  end

  if params == nil then
    return table.concat({
      tostring(version),
      stablePart(currentLocale()),
      tostring(key),
      stablePart(keyFallback),
    }, "\31")
  end

  if opts.cacheKey ~= nil then
    return table.concat({
      tostring(version),
      stablePart(currentLocale()),
      tostring(key),
      stablePart(keyFallback),
      stablePart(opts.cacheKey),
    }, "\31")
  end

  return nil
end

---@param opts? GlyphI18nConfig|fun(key: string, params?: table, opts?: GlyphI18nTranslateOpts): string|nil
---@return nil
function I18n.configure(opts)
  if type(opts) == "function" then
    opts = { translate = opts }
  end

  config = opts or {}
  if config.locale ~= nil then
    locale = config.locale
  end
  I18n.invalidate()
end

---@param fn fun()|nil
---@return nil
function I18n.setInvalidationCallback(fn)
  onInvalidate = fn
end

---@return nil
function I18n.invalidate()
  cache = {}
  version = version + 1
  if type(onInvalidate) == "function" then
    onInvalidate()
  end
end

---@param nextLocale any
---@return nil
function I18n.setLocale(nextLocale)
  if type(config.setLocale) == "function" then
    config.setLocale(nextLocale)
  end
  locale = nextLocale
  I18n.invalidate()
end

---@return any
function I18n.locale()
  return currentLocale()
end

---@return number
function I18n.version()
  return version
end

---@param key string|nil
---@param params? table
---@param opts? GlyphI18nTranslateOpts
---@return string
function I18n.t(key, params, opts)
  if key == nil then
    return ""
  end

  opts = opts or {}
  local memoKey = cacheKey(key, params, opts)
  if memoKey and cache[memoKey] ~= nil then
    return cache[memoKey]
  end

  local value = nil
  if type(config.translate) == "function" then
    value = config.translate(key, params, opts)
  end
  if value == nil then
    value = missingValue(key, params, opts)
  end

  value = tostring(value)
  if memoKey then
    cache[memoKey] = value
  end
  return value
end

---@param key? string
---@param params? table
---@param fallback? string
---@param cacheKeyValue? string|number
---@return string|nil
function I18n.resolve(key, params, fallback, cacheKeyValue)
  if key == nil then
    return nil
  end
  return I18n.t(key, params, {
    fallback = fallback,
    cacheKey = cacheKeyValue,
  })
end

---@param value string
---@param props? GlyphTextProps
---@return string
function I18n.resolveText(value, props)
  props = props or {}
  return I18n.resolve(props.textKey, props.textParams, props.textFallback, props.textCacheKey) or value
end

---@param props? GlyphButtonProps|GlyphMeterProps|GlyphTab|table
---@return string|nil
function I18n.resolveLabel(props)
  props = props or {}
  return I18n.resolve(props.labelKey, props.labelParams, props.labelFallback, props.labelCacheKey) or props.label
end

---@param props? GlyphInputProps
---@return string|nil
function I18n.resolvePlaceholder(props)
  props = props or {}
  return I18n.resolve(props.placeholderKey, props.placeholderParams, props.placeholderFallback, props.placeholderCacheKey) or props.placeholder
end

---@param props? GlyphPanelProps
---@return string|nil
function I18n.resolveTitle(props)
  props = props or {}
  return I18n.resolve(props.titleKey, props.titleParams, props.titleFallback, props.titleCacheKey) or props.title
end

return I18n
