local ui = require("glyph")

local TOTAL_EVENTS = 10000
local WINDOW_SIZE = 42

local colors = {
  chassis = { 0.045, 0.05, 0.052, 1 },
  rail = { 0.065, 0.072, 0.074, 1 },
  field = { 0.035, 0.04, 0.042, 1 },
  surface = { 0.085, 0.095, 0.098, 1 },
  surfaceQuiet = { 0.062, 0.068, 0.07, 1 },
  rule = { 0.27, 0.28, 0.28, 1 },
  ruleSoft = { 0.27, 0.28, 0.28, 0.52 },
  text = { 0.93, 0.91, 0.86, 1 },
  muted = { 0.66, 0.64, 0.59, 1 },
  amber = { 0.74, 0.45, 0.08, 1 },
  amberWash = { 0.15, 0.105, 0.045, 1 },
  amberStrong = { 0.2, 0.12, 0.035, 1 },
}

local events = {}
local rowCache = {}
local filter = ""
local setWindowStart = nil
local visibleRows = {}
local visibleWindowStart = nil
local visibleFilter = nil

local metrics = {
  frame = 0,
  fps = 0,
  renderMs = 0,
  layoutPasses = 0,
  rootBuilds = 0,
  work = "PENDING",
  visibleRows = 0,
  rowBuilds = 0,
  cachedRows = 0,
  windowStart = 1,
  windowEnd = 0,
}

local renderStartedAt = 0
local rootBuildsBeforeRender = 0
local captionText = { textStyle = "caption" }
local measureText = { textStyle = "code", fontSize = 15 }

local function currentFps()
  if love and love.timer and love.timer.getFPS then
    return love.timer.getFPS()
  end
  return 0
end

for index = 1, TOTAL_EVENTS do
  local level = index % 11 == 0 and "warn" or index % 17 == 0 and "error" or "info"
  events[index] = {
    index = index,
    level = level,
    message = string.format("event.%05d %s subsystem=%02d frame=%06d", index, level, index % 23, index * 7),
  }
end

local exampleTheme = {
  backgroundColor = colors.chassis,
  surfaceColor = colors.surface,
  surfaceHoverColor = { 0.14, 0.15, 0.15, 1 },
  surfacePressedColor = colors.field,
  borderColor = colors.rule,
  textColor = colors.text,
  mutedTextColor = colors.muted,
  accentColor = colors.amber,
  accentTextColor = colors.field,
  inputColor = colors.field,
  radius = 2,
  borderWidth = 1,
  lineHeight = 18,
}

ui.on("beforeRender", function()
  renderStartedAt = love.timer.getTime()
  rootBuildsBeforeRender = metrics.rootBuilds
  metrics.layoutPasses = 0
end)

ui.on("layout", function()
  metrics.layoutPasses = metrics.layoutPasses + 1
end)

ui.on("afterRender", function()
  metrics.renderMs = (love.timer.getTime() - renderStartedAt) * 1000
  metrics.work = metrics.rootBuilds > rootBuildsBeforeRender and "DIRTY / BUILD" or "IDLE / REUSE"
end)

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end

  if value > maxValue then
    return maxValue
  end

  return value
end

local function rule()
  return ui.box({
    width = "100%",
    height = 1,
    interactive = false,
    accessibilityHidden = true,
    style = { background = colors.rule },
  })
end

local function sectionLabel(label)
  return ui.text(label:upper(), {
    textStyle = "caption",
    style = { color = colors.muted },
  })
end

local function railRegister(label, value)
  return ui.stack({ width = "100%", height = 27 }, {
    ui.row({
      width = "100%",
      height = 26,
      gap = 8,
      align = "center",
    }, {
      ui.text(label:upper(), {
        width = 68,
        textStyle = "caption",
        style = { color = colors.muted },
      }),
      ui.text(value, {
        flex = 1,
        textStyle = "code",
        style = { color = colors.text },
      }),
    }),
    ui.box({
      position = "absolute",
      left = 0,
      right = 0,
      bottom = 0,
      height = 1,
      interactive = false,
      accessibilityHidden = true,
      style = { background = colors.ruleSoft },
    }),
  })
end

local function rowColor(event)
  if event.level == "error" then
    return colors.amberStrong
  end

  if event.level == "warn" then
    return colors.amberWash
  end

  return event.index % 2 == 0 and colors.surfaceQuiet or colors.field
end

local ledgerHeader = ui.static(ui.row({
  width = "100%",
  height = 25,
  align = "center",
  padding = { x = 7 },
  style = { background = colors.surface },
}, {
  ui.text("SEQ", { width = 70, textStyle = "caption", style = { color = colors.muted } }),
  ui.text("LEVEL", { width = 70, textStyle = "caption", style = { color = colors.muted } }),
  ui.text("EVENT", { flex = 1, textStyle = "caption", style = { color = colors.muted } }),
}))

local function getRow(event)
  local cached = rowCache[event.index]
  if cached then
    metrics.cachedRows = metrics.cachedRows + 1
    return cached
  end

  metrics.rowBuilds = metrics.rowBuilds + 1
  local levelColor = event.level == "info" and colors.muted or colors.amber

  cached = ui.static(ui.stack({ width = "100%", height = 25 }, {
    ui.row({
      width = "100%",
      height = 24,
      align = "center",
      padding = { x = 7 },
      style = { background = rowColor(event) },
    }, {
      ui.text(string.format("%05d", event.index), {
        width = 70,
        textStyle = "code",
        style = { color = colors.text },
      }),
      ui.text(event.level:upper(), {
        width = 70,
        textStyle = "code",
        style = { color = levelColor },
      }),
      ui.text(event.message, { flex = 1, style = { color = colors.text } }),
    }),
    ui.box({
      position = "absolute",
      left = 0,
      right = 0,
      bottom = 0,
      height = 1,
      interactive = false,
      accessibilityHidden = true,
      style = { background = colors.ruleSoft },
    }),
  }))

  rowCache[event.index] = cached
  return cached
end

local function matches(event)
  return filter == ""
    or event.message:find(filter, 1, true) ~= nil
    or event.level:find(filter, 1, true) ~= nil
end

local function rebuildVisibleRows(startIndex)
  if visibleWindowStart == startIndex and visibleFilter == filter then
    return
  end

  visibleWindowStart = startIndex
  visibleFilter = filter
  visibleRows = {}
  metrics.cachedRows = 0
  metrics.windowStart = startIndex
  metrics.windowEnd = startIndex - 1

  local index = startIndex
  while index <= TOTAL_EVENTS and #visibleRows < WINDOW_SIZE do
    local event = events[index]
    if matches(event) then
      visibleRows[#visibleRows + 1] = getRow(event)
      metrics.windowEnd = event.index
    end
    index = index + 1
  end

  metrics.visibleRows = #visibleRows
end

local function VisibleRows()
  return ui.column({ width = "100%", gap = 0 }, visibleRows)
end

local function moveWindow(delta)
  if setWindowStart then
    setWindowStart(function(current)
      return clamp(current + delta, 1, TOTAL_EVENTS)
    end)
  end
end

local instruments = {
  { label = "WORK", value = function() return metrics.work end, color = colors.amber },
  { label = "FPS", value = function() return metrics.fps end },
  { label = "LAST TOTAL", value = function() return string.format("%.2f MS", metrics.renderMs) end },
  { label = "FRAME", value = function() return metrics.frame end },
  { label = "ROOT BUILDS", value = function() return metrics.rootBuilds end },
  { label = "LAYOUT PASSES", value = function() return metrics.layoutPasses end },
  { label = "MOUNTED", value = function() return string.format("%02d / 10K", metrics.visibleRows) end },
  { label = "CACHE HITS", value = function() return metrics.cachedRows end },
}

local function drawInstrumentRegister(_, x, y, width, height, _, _, ctx)
  local columns = 4
  local cellWidth = width / columns
  local cellHeight = height / 2

  ctx:color(colors.field)
  ctx:rect("fill", x, y, width, height)
  ctx:color(colors.rule)
  ctx:rect("line", x, y, width, height, 0)
  ctx:line(x, y + cellHeight, x + width, y + cellHeight)

  for column = 1, columns - 1 do
    local lineX = x + column * cellWidth
    ctx:line(lineX, y, lineX, y + height)
  end

  for index, instrument in ipairs(instruments) do
    local column = (index - 1) % columns
    local row = math.floor((index - 1) / columns)
    local cellX = x + column * cellWidth + 9
    local cellY = y + row * cellHeight
    ctx:color(colors.muted)
    ctx:text(instrument.label, cellX, cellY + 6, captionText)
    ctx:color(instrument.color or colors.text)
    ctx:text(instrument.value(), cellX, cellY + 22, measureText)
  end
end

local function stepButton(label, delta)
  return ui.button({
    label = label,
    height = 30,
    flex = 1,
    style = {
      radius = 0,
      background = colors.surface,
      borderColor = colors.rule,
      hover = { background = { 0.14, 0.15, 0.15, 1 } },
      pressed = { background = colors.field },
      focused = { borderColor = colors.text, borderWidth = 2 },
    },
    onClick = function()
      moveWindow(delta)
    end,
  })
end

local function App()
  metrics.rootBuilds = metrics.rootBuilds + 1
  local windowStart, nextWindowStart = ui.useState(1)
  setWindowStart = nextWindowStart

  rebuildVisibleRows(windowStart)

  local rail = ui.stack({
    width = "23%",
    minWidth = 208,
    maxWidth = 252,
    height = "100%",
    style = { background = colors.rail },
  }, {
    ui.column({
      width = "100%",
      height = "100%",
      padding = { left = 16, right = 16, top = 15, bottom = 13 },
      gap = 9,
      style = { background = colors.rail },
    }, {
      sectionLabel("Window control"),
      ui.text(string.format("%05d—%05d", metrics.windowStart, metrics.windowEnd), {
        font = "mono",
        fontSize = 20,
        lineHeight = 26,
        style = { color = colors.text },
      }),
      ui.text("42-row mounted window", {
        textStyle = "caption",
        style = { color = colors.muted },
      }),
      ui.row({ width = "100%", gap = 5 }, {
        stepButton("-1000", -1000),
        stepButton("-100", -100),
        stepButton("-10", -10),
      }),
      ui.row({ width = "100%", gap = 5 }, {
        stepButton("+10", 10),
        stepButton("+100", 100),
        stepButton("+1000", 1000),
      }),
      rule(),
      sectionLabel("Exact filter"),
      ui.input({
        width = "100%",
        height = 32,
        value = filter,
        placeholder = "info, warn, error",
        style = { radius = 0 },
        onChange = function(nextFilter)
          filter = nextFilter
          moveWindow(0)
        end,
      }),
      rule(),
      sectionLabel("Synthetic dataset"),
      ui.column({ width = "100%", gap = 0 }, {
        railRegister("Source", "10,000"),
        railRegister("Window", "42 max"),
        railRegister("Storage", "app-owned"),
      }),
      ui.box({ width = "100%", grow = 1, interactive = false }),
      ui.text("WHEEL / HOME / END", {
        width = "100%",
        wrap = true,
        textStyle = "caption",
        style = { color = colors.muted },
      }),
    }),
    ui.box({
      position = "absolute",
      top = 0,
      right = 0,
      bottom = 0,
      width = 1,
      interactive = false,
      accessibilityHidden = true,
      style = { background = colors.rule },
    }),
  })

  local workfield = ui.column({
    flex = 1,
    height = "100%",
    padding = { left = 20, right = 18, top = 13, bottom = 12 },
    gap = 7,
    style = { background = colors.chassis },
  }, {
    ui.row({ width = "100%", height = 30, align = "center", gap = 10 }, {
      ui.text("Runtime ledger", {
        textStyle = "h1",
        style = { color = colors.text },
      }),
      ui.box({ flex = 1, height = 1, interactive = false }),
      ui.box({
        width = 7,
        height = 7,
        interactive = false,
        accessibilityHidden = true,
        style = { background = colors.amber, radius = 0 },
      }),
      ui.text("BOUNDED WINDOW", {
        textStyle = "caption",
        style = { color = colors.muted },
      }),
    }),
    sectionLabel("Runtime instruments"),
    ui.box({
      width = "100%",
      height = 88,
      interactive = false,
      draw = drawInstrumentRegister,
    }),
    ui.row({ width = "100%", height = 18, align = "center", gap = 10 }, {
      sectionLabel("Event register"),
      ui.box({ flex = 1, height = 1, interactive = false }),
      ui.text(string.format("%05d—%05d", metrics.windowStart, metrics.windowEnd), {
        textStyle = "code",
        style = { color = colors.amber },
      }),
    }),
    ledgerHeader,
    ui.scrollView({
      width = "100%",
      flex = 1,
      gap = 0,
      padding = { right = 4 },
      style = {
        background = colors.field,
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
      },
    }, {
      ui.memo(VisibleRows, { windowStart, filter }),
    }),
    ui.text("Idle frames reuse the root; interaction rebuilds it. Layout, callback publication, and draw still run every frame.", {
      width = "100%",
      wrap = true,
      textStyle = "caption",
      style = { color = colors.muted },
    }),
  })

  return ui.row({ width = "100%", height = "100%" }, {
    rail,
    workfield,
  })
end

local function update(dt)
  metrics.frame = metrics.frame + 1
  metrics.fps = currentFps()
  if metrics.fps <= 0 and dt and dt > 0 then
    metrics.fps = math.floor(1 / dt + 0.5)
  end
end

local function wheelmoved(_, dy)
  moveWindow(-dy * 6)
end

local function keypressed(key)
  if key == "home" then
    moveWindow(-TOTAL_EVENTS)
  elseif key == "end" then
    moveWindow(TOTAL_EVENTS)
  end
end

local function setup()
  ui.setTheme(exampleTheme)
end

return {
  id = "performance",
  label = "Performance",
  description = "A 10k-event service workbench that separates clean-root reuse from interaction-driven rebuilds.",
  window = {
    width = 960,
    height = 640,
    minWidth = 820,
    minHeight = 560,
    resizable = true,
    title = "glyph - performance",
  },
  setup = setup,
  update = update,
  wheelmoved = wheelmoved,
  keypressed = keypressed,
  component = function()
    return App()
  end,
}
