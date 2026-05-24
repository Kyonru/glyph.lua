local Responsive = {}

local DEFAULT_BREAKPOINTS = {
  xs = 0,
  sm = 480,
  md = 760,
  lg = 1024,
  xl = 1280,
}

local ORDER = { "xs", "sm", "md", "lg", "xl" }

local function copyBreakpoints(breakpoints)
  local copy = {}
  for key, value in pairs(DEFAULT_BREAKPOINTS) do
    copy[key] = value
  end

  for key, value in pairs(breakpoints or {}) do
    copy[key] = value
  end

  return copy
end

function Responsive.new()
  return {
    width = 0,
    height = 0,
    breakpoints = copyBreakpoints(),
  }
end

function Responsive.clamp(value, minValue, maxValue)
  if minValue ~= nil and value < minValue then
    return minValue
  end

  if maxValue ~= nil and value > maxValue then
    return maxValue
  end

  return value
end

function Responsive.setBreakpoints(state, breakpoints)
  state.breakpoints = copyBreakpoints(breakpoints)
end

function Responsive.resize(state, width, height)
  state.width = width
  state.height = height
end

function Responsive.viewport(state)
  return {
    width = state.width,
    height = state.height,
    breakpoint = Responsive.breakpoint(state),
  }
end

function Responsive.breakpoint(state)
  local width = state.width or 0
  local current = "xs"

  for _, name in ipairs(ORDER) do
    local minimum = state.breakpoints[name]
    if minimum ~= nil and width >= minimum then
      current = name
    end
  end

  return current
end

function Responsive.atLeast(state, name)
  return (state.width or 0) >= (state.breakpoints[name] or 0)
end

function Responsive.below(state, name)
  return (state.width or 0) < (state.breakpoints[name] or 0)
end

function Responsive.pick(state, values)
  local selected = values.default
  for _, name in ipairs(ORDER) do
    if state.width >= (state.breakpoints[name] or 0) and values[name] ~= nil then
      selected = values[name]
    end
  end

  return selected
end

function Responsive.columns(containerWidth, opts)
  opts = opts or {}
  local count = opts.count or 1
  local gap = opts.gap or 0
  local min = opts.min
  local max = opts.max

  if min then
    count = math.max(1, math.floor((containerWidth + gap) / (min + gap)))
  end

  if opts.maxCount then
    count = math.min(count, opts.maxCount)
  end

  local width = (containerWidth - gap * (count - 1)) / count
  if max and width > max then
    width = max
  end

  return {
    count = count,
    gap = gap,
    width = math.floor(width),
  }
end

function Responsive.configureWindow(runtime, opts)
  opts = opts or {}
  local love = runtime.love or _G.love

  if opts.breakpoints then
    Responsive.setBreakpoints(runtime.responsive, opts.breakpoints)
  end

  if love and love.window and love.window.setMode then
    love.window.setMode(opts.width or runtime.responsive.width, opts.height or runtime.responsive.height, {
      resizable = opts.resizable ~= false,
      minwidth = opts.minWidth,
      minheight = opts.minHeight,
      highdpi = opts.highdpi,
      fullscreen = opts.fullscreen,
      vsync = opts.vsync,
    })
  end

  if love and love.graphics and love.graphics.getDimensions then
    local width, height = love.graphics.getDimensions()
    Responsive.resize(runtime.responsive, width, height)
  else
    Responsive.resize(runtime.responsive, opts.width or runtime.responsive.width, opts.height or runtime.responsive.height)
  end

  runtime:markDirty()
end

return Responsive
