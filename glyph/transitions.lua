local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local Animation = require(prefix .. ".animation")

local Transitions = {}

---@param t number
---@return number
local function easeOutCubic(t)
  return 1 - ((1 - t) * (1 - t) * (1 - t))
end

---@param direction "top"|"bottom"|"left"|"right"|string
---@param progress number
---@param width number
---@param height number
---@param exiting boolean
---@return number
---@return number
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

---@type table<string, fun(ctx: GlyphTransitionCtx): any>
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

---@param ctx GlyphTransitionCtx
---@param spec? GlyphAnimationSpec|false
---@return any
local function drawAnimatedLayer(ctx, spec)
  local graphics = ctx.love and ctx.love.graphics
  if not graphics then
    return ctx.drawLayer()
  end

  local values = Animation.sample(spec, ctx.phase, ctx.progress)
  local cx = ctx.bounds.x + ctx.bounds.width / 2
  local cy = ctx.bounds.y + ctx.bounds.height / 2
  local scale = values.scale or 1
  local scaleX = values.scaleX or 1
  local scaleY = values.scaleY or 1

  if graphics.push then
    graphics.push()
  end
  if graphics.translate then
    graphics.translate(cx + (values.x or 0), cy + (values.y or 0))
  end
  if graphics.rotate and (values.rotation or 0) ~= 0 then
    graphics.rotate(values.rotation)
  end
  if graphics.scale and (scale ~= 1 or scaleX ~= 1 or scaleY ~= 1) then
    graphics.scale(scale * scaleX, scale * scaleY)
  end
  if graphics.translate then
    graphics.translate(-cx, -cy)
  end
  if graphics.setColor then
    graphics.setColor(1, 1, 1, values.opacity or 1)
  end

  ctx.drawLayer()

  if graphics.pop then
    graphics.pop()
  end
end

---@param spec? string|GlyphTransition|fun(ctx: GlyphTransitionCtx)
---@return GlyphTransition
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

---@param spec? string|GlyphTransition|fun(ctx: GlyphTransitionCtx)
---@return GlyphTransition
function Transitions.resolve(spec)
  return normalize(spec)
end

---@param spec? GlyphTransition|fun(ctx: GlyphTransitionCtx)
---@return GlyphTransition
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
  ---@param opts? table
  ---@return GlyphTransition
  Transitions[name] = function(opts)
    opts = opts or {}
    opts.name = name
    opts.draw = draw
    return normalize(opts)
  end
end

---@param opts? { enter?: GlyphAnimationSpec, exit?: GlyphAnimationSpec, duration?: number, exitDuration?: number }
---@return GlyphTransition
function Transitions.animate(opts)
  opts = opts or {}
  local transition = {
    name = "animate",
    duration = (opts.enter and opts.enter.duration) or opts.duration or 0.25,
    exitDuration = (opts.exit and opts.exit.duration) or opts.exitDuration or opts.duration or 0.2,
  }

  for key, value in pairs(opts) do
    transition[key] = value
  end

  transition.draw = function(ctx)
    local spec = ctx.phase == "exit" and (transition.exit or transition.enter) or transition.enter
    return drawAnimatedLayer(ctx, spec or transition)
  end

  return normalize(transition)
end

Transitions.builtins = builtins

return Transitions
