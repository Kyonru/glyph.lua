local ui = require("glyph")

local colors = {
  panel = { 0.055, 0.068, 0.092, 0.96 },
  panelDeep = { 0.028, 0.036, 0.054, 0.98 },
  border = { 1, 1, 1, 0.14 },
  text = { 0.92, 0.96, 1, 1 },
  muted = { 0.58, 0.66, 0.74, 1 },
  teal = { 0.1, 0.82, 0.72, 1 },
  blue = { 0.28, 0.52, 1, 1 },
  gold = { 1, 0.72, 0.22, 1 },
  coral = { 1, 0.32, 0.38, 1 },
  violet = { 0.68, 0.42, 1, 1 },
}

local seedLogs = {
  { kind = "runtime", message = "Renderer attached", color = colors.teal },
  { kind = "layout", message = "Responsive grid measured", color = colors.blue },
  { kind = "input", message = "Inspector focused", color = colors.gold },
  { kind = "draw", message = "Custom graph redrawn", color = colors.violet },
  { kind = "state", message = "Counter ready", color = colors.coral },
}

local function alpha(color, value)
  return { color[1], color[2], color[3], value ~= nil and value or color[4] or 1 }
end

local function clamp(value, minValue, maxValue)
  value = tonumber(value) or 0
  if value < minValue then
    return minValue
  elseif value > maxValue then
    return maxValue
  end
  return value
end

local function copyLogs()
  local result = {}
  for index, entry in ipairs(seedLogs) do
    result[index] = {
      kind = entry.kind,
      message = entry.message,
      color = entry.color,
    }
  end
  return result
end

local function pushLog(logs, entry)
  local nextLogs = {
    {
      kind = entry.kind,
      message = entry.message,
      color = entry.color,
    },
  }

  for index = 1, math.min(#logs, 11) do
    nextLogs[#nextLogs + 1] = logs[index]
  end

  return nextLogs
end

local function drawSparkline(count)
  return function(_, x, y, width, height, _, _, ctx)
    ctx:color(colors.panelDeep)
    ctx:rect("fill", x, y, width, height, 8)

    ctx:color({ 1, 1, 1, 0.05 })
    for gx = 24, width - 16, 32 do
      ctx:line(x + gx, y + 16, x + gx, y + height - 16)
    end

    local points = {}
    local samples = 18
    for index = 0, samples do
      local ratio = index / samples
      local value = 0.5 + math.sin(ratio * math.pi * 2.4 + count * 0.28) * 0.26
      value = value + math.cos(ratio * math.pi * 3.8 + count * 0.12) * 0.12
      points[#points + 1] = x + 18 + ratio * (width - 36)
      points[#points + 1] = y + 18 + (1 - clamp(value, 0.08, 0.92)) * (height - 36)
    end

    ctx:color(alpha(colors.blue, 0.28))
    ctx:line((table.unpack or unpack)(points))
    ctx:color(colors.teal)
    for index = 1, #points, 8 do
      ctx:shape("fill", { kind = "circle", segments = 12 }, {
        x = points[index] - 3,
        y = points[index + 1] - 3,
        width = 6,
        height = 6,
      })
    end
  end
end

local function statCard(label, value, color, detail)
  return ui.box({
    padding = 10,
    display = "column",
    gap = 5,
    style = {
      background = alpha(color, 0.14),
      borderColor = alpha(color, 0.58),
      borderWidth = 1,
      radius = 8,
    },
  }, {
    ui.text(label, { textStyle = "caption", style = { color = colors.muted } }),
    ui.text(value, { textStyle = "h2", style = { color = colors.text } }),
    ui.text(detail, { textStyle = "caption", style = { color = alpha(color, 0.88) } }),
  })
end

local function logRow(entry)
  return ui.row({
    width = "100%",
    minHeight = 30,
    gap = 8,
    align = "center",
  }, {
    ui.box({
      width = 8,
      height = 8,
      style = {
        background = entry.color or colors.teal,
        radius = 4,
      },
    }),
    ui.text(entry.kind, {
      width = 58,
      textStyle = "caption",
      style = { color = entry.color or colors.muted },
    }),
    ui.text(entry.message, {
      flex = 1,
      wrap = true,
      style = { color = colors.text },
    }),
  })
end

local function emptyState()
  return ui.column({
    width = "100%",
    height = 110,
    align = "center",
    justify = "center",
    gap = 4,
  }, {
    ui.text("No events match that filter.", { style = { color = colors.text } }),
    ui.text("Adjust the filter to widen the feed.", {
      textStyle = "caption",
      style = { color = colors.muted },
    }),
  })
end

local function App()
  local count, setCount = ui.useState(0)
  local activeTab, setActiveTab = ui.useState(1)
  local filter, setFilter = ui.useState("")
  local logs, setLogs = ui.useState(copyLogs)

  local function record(kind, message, color)
    setLogs(function(previous)
      return pushLog(previous, {
        kind = kind,
        message = message,
        color = color,
      })
    end)
  end

  local filtered = {}
  local query = filter:lower()
  for _, entry in ipairs(logs) do
    local haystack = (entry.kind .. " " .. entry.message):lower()
    if query == "" or haystack:find(query, 1, true) then
      filtered[#filtered + 1] = logRow(entry)
    end
  end
  if #filtered == 0 then
    filtered[1] = emptyState()
  end

  local progress = (count % 12) / 12
  local status = count == 0 and "ready" or (count % 3 == 0 and "sync" or "live")

  local overview = ui.column({ width = "100%", gap = 12 }, {
    ui.grid({
      width = "100%",
      minCellWidth = 150,
      maxColumns = 3,
      cellHeight = 86,
      gap = 10,
    }, {
      statCard("counter", tostring(count), colors.teal, "12-step loop"),
      statCard("events", tostring(#logs), colors.gold, "live feed"),
      statCard("status", status, colors.violet, "ready / sync / live"),
    }),
    ui.box({
      width = "100%",
      height = 118,
      interactive = false,
      draw = drawSparkline(count),
    }),
    ui.meter({
      value = progress,
      max = 1,
      height = 12,
      shape = { kind = "skew", skew = 10 },
      trackStyle = { background = { 1, 1, 1, 0.08 } },
      fillStyle = { background = colors.teal },
    }),
  })

  local activity = ui.column({ width = "100%", gap = 10 }, {
    ui.input({
      width = "100%",
      placeholder = "Filter activity...",
      value = filter,
      onChange = function(nextValue)
        setFilter(nextValue)
      end,
    }),
    ui.scrollView({
      width = "100%",
      height = 202,
      gap = 6,
      padding = 8,
      style = {
        background = colors.panelDeep,
        borderColor = colors.border,
        borderWidth = 1,
        radius = 8,
      },
    }, filtered),
  })

  local custom = ui.column({ width = "100%", gap = 10 }, {
    ui.box({
      width = "100%",
      height = 164,
      interactive = false,
      draw = function(_, x, y, width, height, _, _, ctx)
        ctx:color(colors.panelDeep)
        ctx:rect("fill", x, y, width, height, 8)
        ctx:color(alpha(colors.blue, 0.18))
        ctx:shape("fill", { kind = "blob", points = 12, variance = 0.12, seed = "basic" }, {
          x = x + width * 0.08,
          y = y + 24,
          width = width * 0.46,
          height = height - 48,
        })
        ctx:color(alpha(colors.gold, 0.2))
        ctx:shape("fill", { kind = "skew", skew = 24 }, {
          x = x + width * 0.42,
          y = y + 36,
          width = width * 0.48,
          height = height - 72,
        })
        ctx:color(colors.text)
        ctx:printf("signal field", x + 18, y + height - 36, width - 36, "center")
      end,
    }),
    ui.text("A compact custom-drawn panel can sit beside normal controls without changing layout rules.", {
      wrap = true,
      width = "100%",
      style = { color = colors.muted },
    }),
  })

  return ui.scrollView({
    width = "100%",
    height = "100%",
    padding = { left = 28, right = 28, top = 24, bottom = 24 },
    gap = 14,
    align = "center",
  }, {
    ui.panel({
      title = "Mission Console",
      width = "100%",
      maxWidth = 860,
      padding = 14,
      gap = 12,
      style = {
        background = colors.panel,
        borderColor = colors.border,
        borderWidth = 1,
        radius = 8,
      },
    }, {
      ui.row({ width = "100%", gap = 10, align = "center" }, {
        ui.button({
          label = "Increment",
          onClick = function()
            local nextCount = count + 1
            setCount(nextCount)
            record("state", "Counter changed to " .. tostring(nextCount), colors.teal)
          end,
        }),
        ui.button({
          label = "Reset",
          onClick = function()
            setCount(0)
            setFilter("")
            setLogs(copyLogs())
          end,
        }),
        ui.text("Count: " .. tostring(count), {
          flex = 1,
          style = { color = colors.text },
        }),
      }),
      ui.tabs({
        width = "100%",
        active = activeTab,
        onChange = function(index)
          setActiveTab(index)
          record("input", "Switched to tab " .. tostring(index), colors.gold)
        end,
        tabWidth = 96,
        tabHeight = 34,
        tabStyle = {
          background = { 1, 1, 1, 0.055 },
          color = colors.muted,
          borderColor = colors.border,
          borderWidth = 1,
          radius = 8,
          hover = { background = { 1, 1, 1, 0.09 }, color = colors.text },
          active = {
            background = alpha(colors.teal, 0.22),
            color = colors.text,
            borderColor = alpha(colors.teal, 0.78),
          },
        },
      }, {
        { label = "Overview", content = overview },
        { label = "Activity", content = activity },
        { label = "Custom", content = custom },
      }),
    }),
  })
end

return {
  id = "basic",
  label = "Basic",
  description = "A mission-console starter with state, tabs, a controlled input, a meter, an event log, and a custom sparkline.",
  window = {
    width = 840,
    height = 560,
    minWidth = 680,
    minHeight = 480,
    resizable = true,
    title = "glyph - basic",
  },
  install = {
    gamepad = true,
  },
  component = function()
    return App()
  end,
  keypressed = function(key)
    if key == "up" then
      return ui.navigate("up")
    elseif key == "down" then
      return ui.navigate("down")
    elseif key == "left" then
      return ui.navigate("left")
    elseif key == "right" then
      return ui.navigate("right")
    end
    return ui.keypressed(key)
  end,
  keyreleased = function(key)
    return ui.keyreleased(key)
  end,
}
