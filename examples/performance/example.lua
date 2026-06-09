local ui = require("glyph")

local TOTAL_EVENTS = 10000
local WINDOW_SIZE = 42

local events = {}
local rowCache = {}
local filter = ""
local setWindowStart = nil

local metrics = {
  frame = 0,
  fps = 0,
  renderMs = 0,
  layoutCount = 0,
  visibleRows = 0,
  rowBuilds = 0,
  cachedRows = 0,
}

local renderStartedAt = 0

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
  backgroundColor = { 0.05, 0.055, 0.065, 1 },
  surfaceColor = { 0.105, 0.12, 0.14, 1 },
  surfaceHoverColor = { 0.16, 0.18, 0.21, 1 },
  borderColor = { 0.22, 0.26, 0.31, 1 },
  textColor = { 0.88, 0.91, 0.94, 1 },
  mutedTextColor = { 0.48, 0.54, 0.61, 1 },
  accentColor = { 0.12, 0.68, 0.55, 1 },
  lineHeight = 16,
}

ui.on("beforeRender", function()
  renderStartedAt = love.timer.getTime()
  metrics.layoutCount = 0
end)

ui.on("layout", function()
  metrics.layoutCount = metrics.layoutCount + 1
end)

ui.on("afterRender", function()
  metrics.renderMs = (love.timer.getTime() - renderStartedAt) * 1000
end)

local header = ui.static(ui.row({
  gap = 8,
  padding = { x = 8, y = 4 },
  backgroundColor = { 0.08, 0.095, 0.11, 1 },
  borderColor = ui.theme.borderColor,
}, {
  ui.text("#", { width = 64, color = ui.theme.mutedTextColor }),
  ui.text("level", { width = 64, color = ui.theme.mutedTextColor }),
  ui.text("message", { width = 560, color = ui.theme.mutedTextColor }),
}))

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end

  if value > maxValue then
    return maxValue
  end

  return value
end

local function rowColor(event)
  if event.level == "error" then
    return { 0.18, 0.075, 0.08, 1 }
  end

  if event.level == "warn" then
    return { 0.18, 0.14, 0.07, 1 }
  end

  return nil
end

local function getRow(event)
  local cached = rowCache[event.index]
  if cached then
    metrics.cachedRows = metrics.cachedRows + 1
    return cached
  end

  metrics.rowBuilds = metrics.rowBuilds + 1

  cached = ui.static(ui.row({
    gap = 8,
    padding = { x = 8, y = 3 },
    backgroundColor = rowColor(event),
  }, {
    ui.text(string.format("%05d", event.index), { width = 64, color = ui.theme.mutedTextColor }),
    ui.text(event.level, { width = 64 }),
    ui.text(event.message, { width = 560 }),
  }))

  rowCache[event.index] = cached
  return cached
end

local function matches(event)
  return filter == "" or event.message:find(filter, 1, true) ~= nil or event.level:find(filter, 1, true) ~= nil
end

local function withAlpha(color, alpha)
  return { color[1], color[2], color[3], alpha }
end

local function metricCard(label, value, accent)
  accent = accent or ui.theme.accentColor
  return ui.column({
    width = 124,
    padding = { x = 10, y = 8 },
    gap = 2,
    style = {
      background = { 0.085, 0.1, 0.12, 1 },
      borderColor = withAlpha(accent, 0.52),
      borderWidth = 1,
      radius = 6,
    },
  }, {
    ui.text(label, {
      textStyle = "caption",
      style = { color = ui.theme.mutedTextColor },
    }),
    ui.text(value, {
      textStyle = "h3",
      style = { color = accent },
    }),
  })
end

local visibleRows = {}
local visibleWindowStart = nil
local visibleFilter = nil

local function rebuildVisibleRows(startIndex)
  if visibleWindowStart == startIndex and visibleFilter == filter then
    return
  end

  visibleWindowStart = startIndex
  visibleFilter = filter
  visibleRows = {}
  metrics.cachedRows = 0

  local index = startIndex
  while index <= TOTAL_EVENTS and #visibleRows < WINDOW_SIZE do
    local event = events[index]
    if matches(event) then
      visibleRows[#visibleRows + 1] = getRow(event)
    end
    index = index + 1
  end

  metrics.visibleRows = #visibleRows
end

local function VisibleRows()
  return ui.column({ gap = 1 }, visibleRows)
end

local function moveWindow(delta)
  if setWindowStart then
    setWindowStart(function(current)
      return clamp(current + delta, 1, TOTAL_EVENTS)
    end)
  end
end

local function App()
  local windowStart, nextWindowStart = ui.useState(1)
  setWindowStart = nextWindowStart

  rebuildVisibleRows(windowStart)

  return ui.column({
    gap = 10,
    padding = 12,
    width = 820,
    backgroundColor = ui.theme.backgroundColor,
  }, {
    ui.row({ width = "100%", gap = 12, align = "center" }, {
      ui.column({ flex = 1, gap = 2 }, {
        ui.text("Performance", { textStyle = "h2" }),
        ui.text("10k event log with a mounted window, static row cache, and live frame metrics.", {
          style = { color = ui.theme.mutedTextColor },
        }),
      }),
      metricCard("fps", tostring(metrics.fps), ui.theme.accentColor),
    }),

    ui.row({ gap = 8, align = "center" }, {
      ui.button({ label = "-1000", onClick = function() moveWindow(-1000) end }),
      ui.button({ label = "-100", onClick = function() moveWindow(-100) end }),
      ui.button({ label = "-10", onClick = function() moveWindow(-10) end }),
      ui.text(string.format("window %05d / %05d", windowStart, TOTAL_EVENTS), { width = 190 }),
      ui.button({ label = "+10", onClick = function() moveWindow(10) end }),
      ui.button({ label = "+100", onClick = function() moveWindow(100) end }),
      ui.button({ label = "+1000", onClick = function() moveWindow(1000) end }),
    }),

    ui.row({ gap = 8, align = "center" }, {
      ui.input({
        width = 260,
        value = filter,
        placeholder = "Exact filter: info, warn, error...",
        onChange = function(nextFilter)
          filter = nextFilter
          moveWindow(0)
        end,
      }),
      ui.text("filter keeps data outside the UI tree; counters below show mounted work only", {
        flex = 1,
        color = ui.theme.mutedTextColor,
      }),
    }),

    ui.row({ gap = 8, width = "100%", align = "stretch", wrap = true }, {
      metricCard("visible", string.format("%02d", metrics.visibleRows), { 0.12, 0.68, 0.55, 1 }),
      metricCard("row builds", tostring(metrics.rowBuilds), { 0.34, 0.58, 0.92, 1 }),
      metricCard("cache hits", tostring(metrics.cachedRows), { 0.95, 0.68, 0.22, 1 }),
      metricCard("layouts", tostring(metrics.layoutCount), { 0.76, 0.48, 0.95, 1 }),
      metricCard("render", string.format("%.2fms", metrics.renderMs), { 0.92, 0.36, 0.4, 1 }),
      metricCard("frame", tostring(metrics.frame), { 0.52, 0.62, 0.7, 1 }),
    }),

    ui.text(string.format(
      "visible=%02d rowBuilds=%d cachedHits=%d layouts=%d render=%.2fms fps=%d",
      metrics.visibleRows,
      metrics.rowBuilds,
      metrics.cachedRows,
      metrics.layoutCount,
      metrics.renderMs,
      metrics.fps
    ), {
      textStyle = "caption",
      color = ui.theme.mutedTextColor,
    }),

    header,
    ui.memo(VisibleRows, { windowStart, filter }),

    ui.text("Mouse wheel moves the virtual window. Only visible rows are mounted; rows are reused from a static cache."),
  })
end

local function update(dt)
  metrics.frame = metrics.frame + 1
  metrics.fps = currentFps()
  if metrics.fps <= 0 and dt and dt > 0 then
    metrics.fps = math.floor(1 / dt + 0.5)
  end
end

local function wheelmoved(dx, dy)
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
  setup = setup,
  update = update,
  wheelmoved = wheelmoved,
  keypressed = keypressed,
  component = function()
    return App()
  end,
}
