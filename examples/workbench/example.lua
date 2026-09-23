local ui = require("glyph")

local colors = {
  chassis = { 0.045, 0.05, 0.052, 1 },
  rail = { 0.065, 0.072, 0.074, 1 },
  field = { 0.035, 0.04, 0.042, 1 },
  surface = { 0.085, 0.095, 0.098, 1 },
  rule = { 0.27, 0.28, 0.28, 1 },
  ruleSoft = { 0.27, 0.28, 0.28, 0.52 },
  text = { 0.93, 0.91, 0.86, 1 },
  muted = { 0.66, 0.64, 0.59, 1 },
  amber = { 0.74, 0.45, 0.08, 1 },
  amberDark = { 0.12, 0.085, 0.035, 1 },
}

local seedLogs = {
  { time = "0008", kind = "runtime", message = "Renderer attached" },
  { time = "0007", kind = "layout", message = "Responsive flow measured" },
  { time = "0006", kind = "input", message = "Inspector focused" },
  { time = "0005", kind = "draw", message = "Signal field redrawn" },
  { time = "0004", kind = "state", message = "Counter ready" },
  { time = "0003", kind = "theme", message = "Service palette resolved" },
  { time = "0002", kind = "focus", message = "Navigation graph built" },
  { time = "0001", kind = "mount", message = "Workbench mounted" },
}

local function copyLogs()
  local result = {}
  for index, entry in ipairs(seedLogs) do
    result[index] = {
      time = entry.time,
      kind = entry.kind,
      message = entry.message,
    }
  end
  return result
end

local function pushLog(logs, entry)
  local nextLogs = { entry }
  for index = 1, math.min(#logs, 11) do
    nextLogs[#nextLogs + 1] = logs[index]
  end
  return nextLogs
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

local function metricRow(label, value)
  return ui.stack({ width = "100%", height = 31 }, {
    ui.row({
      width = "100%",
      height = 30,
      align = "center",
      gap = 12,
      padding = { x = 4 },
    }, {
      ui.text(label:upper(), {
        width = 126,
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

local function logHeader()
  return ui.row({
    width = "100%",
    height = 24,
    align = "center",
    padding = { x = 4 },
    style = { background = colors.surface },
  }, {
    ui.text("SEQ", {
      width = 78,
      textStyle = "caption",
      style = { color = colors.muted },
    }),
    ui.text("CHANNEL", {
      width = 84,
      textStyle = "caption",
      style = { color = colors.muted },
    }),
    ui.text("EVENT", {
      flex = 1,
      textStyle = "caption",
      style = { color = colors.muted },
    }),
  })
end

local function logRow(entry)
  return ui.stack({ width = "100%", minHeight = 27 }, {
    ui.row({
      width = "100%",
      minHeight = 26,
      align = "center",
      padding = { x = 4 },
    }, {
      ui.text(entry.time, {
        width = 78,
        textStyle = "code",
        style = { color = colors.text },
      }),
      ui.text(entry.kind:upper(), {
        width = 84,
        textStyle = "caption",
        style = { color = colors.muted },
      }),
      ui.text(entry.message, {
        flex = 1,
        wrap = true,
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

local function emptyState()
  return ui.column({
    width = "100%",
    height = 90,
    align = "center",
    justify = "center",
    gap = 3,
  }, {
    ui.text("No matching events", { style = { color = colors.text } }),
    ui.text("Clear the filter to restore the register.", {
      textStyle = "caption",
      style = { color = colors.muted },
    }),
  })
end

local function signalField(count)
  return function(_, x, y, width, height, _, _, ctx)
    ctx:color(colors.field)
    ctx:rect("fill", x, y, width, height)

    ctx:color(colors.ruleSoft)
    for index = 1, 5 do
      local lineX = x + width * index / 6
      ctx:line(lineX, y + 14, lineX, y + height - 14)
    end
    ctx:line(x + 14, y + height * 0.5, x + width - 14, y + height * 0.5)

    local points = {}
    local samples = 22
    for index = 0, samples do
      local ratio = index / samples
      local value = 0.5
        + math.sin(ratio * math.pi * 2.4 + count * 0.28) * 0.26
        + math.cos(ratio * math.pi * 3.8 + count * 0.12) * 0.1
      points[#points + 1] = x + 14 + ratio * (width - 28)
      points[#points + 1] = y + 14 + (1 - value) * (height - 28)
    end

    ctx:color(colors.amber)
    ctx:line((table.unpack or unpack)(points))
  end
end

local function activityRegister(logs, filter, setFilter, expanded)
  local rows = {}
  local query = filter:lower()
  for _, entry in ipairs(logs) do
    local haystack = (entry.kind .. " " .. entry.message):lower()
    if query == "" or haystack:find(query, 1, true) then
      rows[#rows + 1] = logRow(entry)
    end
  end
  if #rows == 0 then
    rows[1] = emptyState()
  end

  local children = {}
  if expanded then
    children[#children + 1] = ui.input({
      width = "100%",
      height = 32,
      placeholder = "Filter activity register",
      value = filter,
      onChange = setFilter,
    })
  end
  children[#children + 1] = logHeader()
  children[#children + 1] = ui.scrollView({
    width = "100%",
    grow = 1,
    minHeight = expanded and 126 or 108,
    padding = { right = 4 },
    gap = 0,
    style = { background = colors.field },
  }, rows)

  return ui.column({ width = "100%", grow = 1, gap = 6 }, children)
end

local function App()
  local count, setCount = ui.useState(4)
  local activeTab, setActiveTab = ui.useState(1)
  local filter, setFilter = ui.useState("")
  local logs, setLogs = ui.useState(copyLogs)

  local function record(kind, message)
    setLogs(function(previous)
      local sequence = (tonumber(previous[1] and previous[1].time) or 0) + 1
      return pushLog(previous, {
        time = string.format("%04d", sequence),
        kind = kind,
        message = message,
      })
    end)
  end

  local function increment()
    local nextCount = count + 1
    setCount(nextCount)
    record("state", "Counter changed to " .. tostring(nextCount))
  end

  local function reset()
    setCount(0)
    setFilter("")
    setLogs(copyLogs())
  end

  local progress = (count % 12) / 12
  local status = count == 0 and "READY" or (count % 3 == 0 and "SYNC" or "LIVE")

  local overview = ui.column({ width = "100%", grow = 1, gap = 7 }, {
    sectionLabel("Activity register"),
    activityRegister(logs, "", function() end, false),
  })

  local activity = ui.column({ width = "100%", grow = 1, gap = 7 }, {
    sectionLabel("Activity register / filter"),
    activityRegister(logs, filter, setFilter, true),
  })

  local custom = ui.column({ width = "100%", grow = 1, gap = 8 }, {
    sectionLabel("Custom draw / signal field"),
    ui.box({
      width = "100%",
      height = 132,
      interactive = false,
      draw = signalField(count),
      style = {
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
      },
    }),
    ui.text("Custom drawing shares the same measured workfield as normal controls.", {
      width = "100%",
      wrap = true,
      textStyle = "caption",
      style = { color = colors.muted },
    }),
  })

  local rail = ui.stack({
    width = "23%",
    minWidth = 190,
    maxWidth = 300,
    height = "100%",
  }, {
    ui.column({
      width = "100%",
      height = "100%",
      padding = { left = 18, right = 18, top = 20, bottom = 16 },
      gap = 12,
      style = { background = colors.rail },
    }, {
      sectionLabel("Commands"),
      ui.button({
        label = "Increment",
        width = "100%",
        height = 36,
        variant = "primary",
        onClick = increment,
      }),
      ui.button({
        label = "Reset",
        width = "100%",
        height = 36,
        onClick = reset,
      }),
      rule(),
      sectionLabel("Count"),
      ui.text(string.format("%02d", count), {
        font = "monoDisplay",
        lineHeight = 40,
        style = { color = colors.text },
      }),
      ui.text("12-step loop", {
        textStyle = "code",
        style = { color = colors.muted },
      }),
      rule(),
      sectionLabel("Status"),
      ui.row({ width = "100%", gap = 8, align = "center" }, {
        ui.box({
          width = 8,
          height = 8,
          interactive = false,
          style = { background = colors.amber, radius = 0 },
        }),
        ui.text(status, {
          textStyle = "code",
          style = { color = colors.text },
        }),
      }),
      ui.box({ grow = 1, width = "100%", interactive = false }),
      ui.text("KEYBOARD + GAMEPAD", {
        textStyle = "caption",
        wrap = true,
        width = "100%",
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
    padding = { left = 24, right = 20, top = 17, bottom = 14 },
    gap = 9,
    style = { background = colors.chassis },
  }, {
    ui.row({ width = "100%", align = "center", gap = 12 }, {
      ui.text("Mission sync", {
        textStyle = "h1",
        style = { color = colors.text },
      }),
      ui.box({ flex = 1, height = 1, interactive = false }),
      ui.text(status, {
        textStyle = "code",
        style = { color = colors.muted },
      }),
    }),
    ui.row({ width = "100%", height = 18, gap = 12, align = "center" }, {
      ui.meter({
        value = progress,
        max = 1,
        flex = 1,
        height = 8,
        trackStyle = { background = colors.surface, radius = 0 },
        fillStyle = { background = colors.amber, radius = 0 },
      }),
      ui.text(string.format("%02d%%", math.floor(progress * 100 + 0.5)), {
        width = 46,
        textStyle = "code",
        style = { color = colors.amber },
      }),
    }),
    ui.column({ width = "100%", gap = 0 }, {
      metricRow("Input route", "Keyboard + Gamepad"),
      metricRow("Event rows", tostring(#logs)),
      metricRow("Focus path", ({ "Overview", "Activity", "Custom" })[activeTab]),
    }),
    ui.tabs({
      width = "100%",
      grow = 1,
      active = activeTab,
      onChange = function(index)
        setActiveTab(index)
        record("input", "Mode changed to " .. ({ "Overview", "Activity", "Custom" })[index])
      end,
      tabWidth = 104,
      tabHeight = 30,
      gap = 6,
      tabStyle = {
        background = colors.surface,
        color = colors.muted,
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
        hover = { background = { 0.14, 0.15, 0.15, 1 }, color = colors.text },
        pressed = { background = colors.field },
        focused = { borderColor = colors.text, borderWidth = 2 },
        active = {
          background = colors.amber,
          color = colors.amberDark,
        },
      },
    }, {
      { label = "Overview", content = overview },
      { label = "Activity", content = activity },
      { label = "Custom", content = custom },
    }),
  })

  return ui.row({ width = "100%", height = "100%" }, {
    rail,
    workfield,
  })
end

return {
  id = "workbench",
  label = "Workbench",
  description = "State, input, tabs, metrics, and custom drawing arranged as a compact service workbench.",
  window = {
    width = 840,
    height = 560,
    minWidth = 680,
    minHeight = 480,
    resizable = true,
    title = "glyph - workbench",
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
