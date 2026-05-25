local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local flux = require(prefix .. ".vendor.flux")

local Animation = {}

local group = flux.group()

local DEFAULTS = {
  opacity = 1,
  x = 0,
  y = 0,
  scale = 1,
  scaleX = 1,
  scaleY = 1,
  rotation = 0,
}

local ANIM_FIELDS = {
  "opacity",
  "x",
  "y",
  "scale",
  "scaleX",
  "scaleY",
  "rotation",
}

local function copyFields(source)
  local result = {}
  source = source or {}
  for _, key in ipairs(ANIM_FIELDS) do
    if source[key] ~= nil then
      result[key] = source[key]
    end
  end
  return result
end

local function copyNumericFields(source)
  local result = {}
  source = source or {}
  for key, value in pairs(source) do
    if type(value) == "number" then
      result[key] = value
    end
  end
  return result
end

local function withDefaults(values)
  local result = {}
  values = values or {}
  for key, value in pairs(DEFAULTS) do
    result[key] = values[key] ~= nil and values[key] or value
  end
  return result
end

local function mergeFields(base, overlay)
  local result = copyFields(base)
  for key, value in pairs(copyFields(overlay)) do
    result[key] = value
  end
  return result
end

local function defaultFrom(phase)
  if phase == "exit" then
    return withDefaults()
  end
  return withDefaults({ opacity = 0 })
end

local function defaultTo(phase)
  if phase == "exit" then
    return withDefaults({ opacity = 0 })
  end
  return withDefaults()
end

function Animation.normalize(spec, phase)
  if spec == false then
    return nil
  end

  spec = spec or {}
  if type(spec) ~= "table" then
    spec = {}
  end

  local normalized = {}
  for key, value in pairs(spec) do
    normalized[key] = value
  end

  normalized.duration = normalized.duration or 0.2
  normalized.delay = normalized.delay or 0
  normalized.ease = normalized.ease or "quadout"
  normalized.from = mergeFields(defaultFrom(phase), spec.from)
  normalized.to = mergeFields(defaultTo(phase), spec.to)
  return normalized
end

function Animation.subject(values)
  return withDefaults(values)
end

function Animation.to(subject, duration, target, opts)
  opts = opts or {}
  subject = subject or {}
  target = copyNumericFields(target)

  local tween = group:to(subject, duration or 0, target)

  if opts.ease then
    tween:ease(opts.ease)
  end
  if opts.delay then
    tween:delay(opts.delay)
  end
  if opts.onStart then
    tween:onstart(function()
      opts.onStart(subject)
    end)
  end
  if opts.onUpdate then
    tween:onupdate(function()
      opts.onUpdate(subject)
    end)
  end
  if opts.onComplete then
    tween:oncomplete(function()
      opts.onComplete(subject)
    end)
  end

  return tween
end

function Animation.start(spec, phase, subject, opts)
  local normalized = Animation.normalize(spec, phase)
  if not normalized then
    return nil, nil
  end

  subject = subject or Animation.subject(normalized.from)
  for key, value in pairs(normalized.from) do
    subject[key] = value
  end

  local tween = Animation.to(subject, normalized.duration, normalized.to, {
    ease = normalized.ease,
    delay = normalized.delay,
    onStart = normalized.onStart,
    onUpdate = normalized.onUpdate,
    onComplete = function(current)
      if normalized.onComplete then
        normalized.onComplete(current)
      end
      if opts and opts.onComplete then
        opts.onComplete(current)
      end
    end,
  })

  return subject, tween, normalized
end

function Animation.sample(spec, phase, progress)
  local normalized = Animation.normalize(spec, phase)
  if not normalized then
    return Animation.subject()
  end

  local easing = flux.easing[normalized.ease] or flux.easing.quadout or flux.easing.linear
  local t = math.max(0, math.min(1, progress or 0))
  t = easing(t)

  local result = {}
  for _, key in ipairs(ANIM_FIELDS) do
    local from = normalized.from[key] ~= nil and normalized.from[key] or DEFAULTS[key]
    local to = normalized.to[key] ~= nil and normalized.to[key] or DEFAULTS[key]
    result[key] = from + (to - from) * t
  end
  return result
end

function Animation.update(dt)
  local hadActive = #group > 0
  group:update(dt or 0)
  return hadActive or #group > 0
end

function Animation.clear()
  for index = #group, 1, -1 do
    group:remove(index)
  end
end

function Animation.active()
  return #group
end

Animation.flux = flux
Animation.fields = ANIM_FIELDS

return Animation
