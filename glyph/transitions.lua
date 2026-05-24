local Transitions = {}

local function easeOutCubic(t)
  return 1 - ((1 - t) * (1 - t) * (1 - t))
end

local function directionOffset(direction, progress, width, height, exiting)
  local t = exiting and progress or (1 - progress)
  if direction == "top" then
    return 0, -height * t
  elseif direction == "left" then
    return -width * t, 0
  elseif direction == "right" then
    return width * t, 0
  end

  return 0, height * t
end

local builtins = {
  none = function(ctx)
    return ctx.drawLayer()
  end,

  fade = function(ctx)
    local graphics = ctx.love and ctx.love.graphics
    if not graphics then
      return ctx.drawLayer()
    end

    local alpha = ctx.phase == "exit" and (1 - ctx.progress) or ctx.progress
    graphics.setColor(1, 1, 1, alpha)
    return ctx.drawLayer()
  end,

  slide = function(ctx)
    local graphics = ctx.love and ctx.love.graphics
    if not graphics then
      return ctx.drawLayer()
    end

    local opts = ctx.transition or {}
    local progress = easeOutCubic(ctx.progress)
    local ox, oy = directionOffset(opts.direction or "bottom", progress, ctx.bounds.width, ctx.bounds.height, ctx.phase == "exit")

    graphics.translate(ox, oy)
    return ctx.drawLayer()
  end,

  scale = function(ctx)
    local graphics = ctx.love and ctx.love.graphics
    if not graphics then
      return ctx.drawLayer()
    end

    local progress = easeOutCubic(ctx.progress)
    local scale = ctx.phase == "exit" and (1 - progress) or progress
    scale = math.max(0.001, scale)

    local cx = ctx.bounds.x + ctx.bounds.width / 2
    local cy = ctx.bounds.y + ctx.bounds.height / 2
    graphics.translate(cx, cy)
    graphics.scale(scale, scale)
    graphics.translate(-cx, -cy)
    return ctx.drawLayer()
  end,
}

local function normalize(spec)
  if spec == nil then
    return {
      name = "none",
      duration = 0,
      draw = builtins.none,
    }
  end

  if type(spec) == "string" then
    return {
      name = spec,
      duration = spec == "none" and 0 or 0.25,
      draw = builtins[spec] or builtins.fade,
    }
  end

  if type(spec) == "function" then
    return {
      name = "custom",
      duration = 0.25,
      draw = spec,
    }
  end

  local name = spec.name or spec.type or spec[1] or "fade"
  local draw = spec.draw or spec.apply or builtins[name] or builtins.fade
  local normalized = {}

  for key, value in pairs(spec) do
    normalized[key] = value
  end

  normalized.name = name
  normalized.draw = draw
  normalized.duration = normalized.duration or (name == "none" and 0 or 0.25)
  normalized.exitDuration = normalized.exitDuration or normalized.duration
  return normalized
end

function Transitions.resolve(spec)
  return normalize(spec)
end

function Transitions.custom(spec)
  if type(spec) == "function" then
    return {
      name = "custom",
      duration = 0.25,
      draw = spec,
    }
  end

  spec = spec or {}
  spec.name = spec.name or "custom"
  return normalize(spec)
end

for name, draw in pairs(builtins) do
  Transitions[name] = function(opts)
    opts = opts or {}
    opts.name = name
    opts.draw = draw
    return normalize(opts)
  end
end

Transitions.builtins = builtins

return Transitions
