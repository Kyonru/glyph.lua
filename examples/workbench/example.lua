local ui = require("glyph")
local workbenchCommands = {}

local colors = {
  chassis = { 0.045, 0.05, 0.052, 1 },
  rail = { 0.065, 0.072, 0.074, 1 },
  field = { 0.035, 0.04, 0.042, 1 },
  surface = { 0.085, 0.095, 0.098, 1 },
  surfaceRaised = { 0.115, 0.125, 0.128, 1 },
  progressTrack = { 0.14, 0.155, 0.165, 1 },
  rule = { 0.27, 0.28, 0.28, 1 },
  ruleSoft = { 0.27, 0.28, 0.28, 0.52 },
  text = { 0.93, 0.91, 0.86, 1 },
  muted = { 0.66, 0.64, 0.59, 1 },
  amber = { 0.74, 0.45, 0.08, 1 },
  amberBright = { 0.98, 0.70, 0.22, 1 },
  amberWash = { 0.23, 0.165, 0.045, 1 },
}

local seedLogs = {
  { time = "0008", kind = "runtime", message = "Renderer attached" },
  { time = "0007", kind = "layout", message = "Responsive flow measured" },
  { time = "0006", kind = "input", message = "Inspector focused" },
  { time = "0005", kind = "draw", message = "Signal field redrawn" },
  { time = "0004", kind = "state", message = "Counter ready" },
  { time = "0003", kind = "mount", message = "Workbench mounted" },
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
    font = "mono",
    fontSize = 13,
    lineHeight = 16,
    style = { color = colors.muted },
  })
end

local function commandButton(label, shortcut, compact, active, onClick)
  local children = {
    ui.row({
      width = "100%",
      height = "100%",
      align = "center",
      padding = { x = 10, y = 5 },
      interactive = false,
      accessibilityHidden = true,
    }, {
      ui.text(label, {
        font = "mono",
        fontSize = compact and 14 or 16,
        lineHeight = compact and 18 or 20,
        interactive = false,
        style = { color = active and colors.amberBright or colors.text },
      }),
      ui.box({ flex = 1, height = 1, interactive = false }),
      ui.text("[" .. shortcut .. "]", {
        textStyle = "code",
        interactive = false,
        style = { color = colors.muted },
      }),
    }),
  }

  if active then
    local markLength = compact and 8 or 10
    local markWidth = 2
    local function mark(props)
      props.interactive = false
      props.accessibilityHidden = true
      props.style = { background = colors.amberBright, radius = 0 }
      return ui.box(props)
    end

    children[#children + 1] = mark({ position = "absolute", left = 0, top = 0, bottom = 0, width = markWidth })
    children[#children + 1] = mark({ position = "absolute", right = 0, top = 0, bottom = 0, width = markWidth })
    children[#children + 1] = mark({ position = "absolute", left = 0, top = 0, width = markLength, height = markWidth })
    children[#children + 1] = mark({ position = "absolute", left = 0, bottom = 0, width = markLength, height = markWidth })
    children[#children + 1] = mark({ position = "absolute", right = 0, top = 0, width = markLength, height = markWidth })
    children[#children + 1] = mark({ position = "absolute", right = 0, bottom = 0, width = markLength, height = markWidth })
  end

  return ui.stack({
    key = "command-" .. label:lower(),
    role = "button",
    focusable = true,
    accessibilityLabel = label,
    width = "100%",
    height = compact and 36 or 38,
    style = {
      background = colors.surfaceRaised,
      borderColor = colors.rule,
      borderWidth = active and 0 or 1,
      radius = 0,
      hover = { background = active and colors.amberWash or colors.field },
      pressed = { background = colors.surface },
      focused = { borderColor = colors.text, borderWidth = 2 },
    },
    onClick = onClick,
  }, children)
end

local function instrumentMeter(progress)
  return function(_, x, y, width, height, _, _, ctx)
    local fillWidth = math.floor(width * progress + 0.5)

    ctx:color(colors.progressTrack)
    ctx:rect("fill", x, y, width, height)
    ctx:color({ 0.2, 0.215, 0.225, 0.8 })
    ctx:rect("fill", x, y, width, 1)

    if fillWidth > 0 then
      ctx:color(colors.amber)
      ctx:rect("fill", x, y, fillWidth, height)
      ctx:color(colors.amberBright)
      ctx:rect("fill", x, y + 1, fillWidth, math.max(1, height - 3))
      ctx:color({ 1, 0.79, 0.34, 0.9 })
      ctx:rect("fill", x, y, fillWidth, 1)
      ctx:color({ 0.58, 0.3, 0.035, 0.9 })
      ctx:rect("fill", x, y + height - 1, fillWidth, 1)
    end
  end
end

local function metricRow(label, value, compact)
  local height = compact and 32 or 36
  return ui.stack({ width = "100%", height = height }, {
    ui.row({
      width = "100%",
      height = height - 1,
      align = "center",
      gap = compact and 12 or 16,
      padding = { x = 4 },
    }, {
      ui.text(label:upper(), {
        width = compact and 116 or 175,
        font = "mono",
        fontSize = compact and 11 or 13,
        lineHeight = 16,
        style = { color = colors.muted },
      }),
      ui.text(value, {
        flex = 1,
        font = "mono",
        fontSize = compact and 13 or 16,
        lineHeight = compact and 16 or 20,
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
    shrink = 0,
    align = "center",
    padding = { x = 4 },
    style = { background = colors.surface },
  }, {
    ui.text("SEQ", {
      width = 144,
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
  return ui.stack({ width = "100%", minHeight = 30 }, {
    ui.row({
      width = "100%",
      minHeight = 29,
      align = "center",
      padding = { x = 4 },
    }, {
      ui.text(entry.time, {
        width = 144,
        textStyle = "code",
        style = { color = colors.text },
      }),
      ui.text(entry.kind:upper() .. " / " .. entry.message, {
        flex = 1,
        wrap = true,
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

local function activityRegister(logs, filter, setFilter, expanded, limit)
  local rows = {}
  local query = filter:lower()
  for _, entry in ipairs(logs) do
    local haystack = (entry.kind .. " " .. entry.message):lower()
    if query == "" or haystack:find(query, 1, true) then
      rows[#rows + 1] = logRow(entry)
      if limit and #rows >= limit then
        break
      end
    end
  end
  if #rows == 0 then
    rows[1] = emptyState()
  end

  local children = {}
  if expanded then
    children[#children + 1] = ui.input({
      key = "activity-filter",
      width = "100%",
      height = 32,
      shrink = 0,
      placeholder = "Filter activity register",
      value = filter,
      onChange = setFilter,
    })
  end
  children[#children + 1] = logHeader()
  children[#children + 1] = ui.scrollView({
    width = "100%",
    flex = 1,
    minHeight = 60,
    padding = { right = 4 },
    gap = 0,
    style = { background = colors.field },
  }, rows)

  return ui.column({ width = "100%", flex = 1, gap = 6 }, children)
end

local function App()
  local viewport = ui.viewport()
  local compact = viewport.width < 820 or viewport.height < 560
  local count, setCount = ui.useState(4)
  local activeCommand, setActiveCommand = ui.useState("increment")
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
    setActiveCommand("increment")
    setCount(nextCount)
    record("state", "Counter changed to " .. tostring(nextCount))
  end

  local function reset()
    setActiveCommand("reset")
    setCount(0)
    setFilter("")
    setLogs(copyLogs())
  end

  workbenchCommands.increment = increment
  workbenchCommands.reset = reset

  local progress = math.min(1, count / 6)

  local overview = ui.column({ width = "100%", flex = 1, gap = compact and 7 or 11 }, {
    sectionLabel("Activity register"),
    activityRegister(logs, "", function() end, false, 3),
  })

  local activity = ui.column({ width = "100%", flex = 1, gap = 7 }, {
    sectionLabel("Activity register / filter"),
    activityRegister(logs, filter, setFilter, true),
  })

  local custom = ui.column({ width = "100%", flex = 1, gap = 8 }, {
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

  local modeNames = { "Overview", "Activity", "Custom" }
  local panes = { overview, activity, custom }

  local function switchMode(index)
    if index == activeTab then
      return
    end
    setActiveTab(index)
    record("input", "Mode changed to " .. modeNames[index])
  end

  local function modeButton(index)
    local name = modeNames[index]
    local selected = activeTab == index
    local children = {
      ui.row({
        width = "100%",
        height = "100%",
        align = "center",
        gap = compact and 5 or 8,
        padding = { left = compact and 12 or 28, right = 8, y = 5 },
        interactive = false,
        accessibilityHidden = true,
      }, {
        ui.text(selected and ">" or "", {
          width = compact and 12 or 20,
          font = "mono",
          fontSize = compact and 15 or 18,
          lineHeight = 20,
          interactive = false,
          style = { color = colors.amberBright },
        }),
        ui.text(name:upper(), {
          flex = 1,
          font = "mono",
          fontSize = compact and 15 or 18,
          lineHeight = 20,
          interactive = false,
          style = { color = selected and colors.amberBright or colors.muted },
        }),
      }),
    }
    if selected then
      children[#children + 1] = ui.box({
        position = "absolute",
        left = 0,
        top = 0,
        bottom = 0,
        width = 2,
        interactive = false,
        accessibilityHidden = true,
        style = { background = colors.amberBright, radius = 0 },
      })
    end

    return ui.stack({
      key = "mode-" .. name:lower(),
      role = "tab",
      styleType = "tab",
      accessibilityLabel = name,
      focusable = true,
      active = selected,
      navGroup = "workbench-modes",
      width = "100%",
      height = 34,
      style = {
        background = selected and colors.amberWash or colors.surfaceRaised,
        color = colors.muted,
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
        hover = { background = selected and colors.amberWash or colors.surface, color = colors.text },
        pressed = { background = colors.field },
        focused = { borderColor = colors.text, borderWidth = 2 },
        active = { background = colors.amberWash, color = colors.amberBright },
      },
      onClick = function()
        switchMode(index)
      end,
    }, children)
  end

  local topBarHeight = compact and 34 or 35
  local topBar = ui.stack({ width = "100%", height = topBarHeight, shrink = 0 }, {
    ui.row({
      width = "100%",
      height = topBarHeight - 1,
      padding = { x = compact and 14 or 20, y = 5 },
      gap = compact and 8 or 10,
      align = "center",
      style = { background = colors.surface },
    }, {
      ui.text("GLYPH", {
        font = "subheader",
        fontSize = compact and 16 or 18,
        lineHeight = 22,
        style = { color = colors.text },
      }),
      ui.text("/", { textStyle = "code", style = { color = colors.amber } }),
      ui.text("MISSION CONSOLE", { textStyle = "code", style = { color = colors.muted } }),
      ui.box({ flex = 1, height = 1, interactive = false }),
      ui.box({
        width = 7,
        height = 7,
        interactive = false,
        accessibilityHidden = true,
        style = { background = colors.amber, radius = 4 },
      }),
      ui.text("RUNTIME READY", { textStyle = "code", style = { color = colors.muted } }),
    }),
    ui.box({
      position = "absolute",
      left = 0,
      right = 0,
      bottom = 0,
      height = 1,
      interactive = false,
      accessibilityHidden = true,
      style = { background = colors.rule },
    }),
  })

  local rail = ui.stack({
    width = "20%",
    minWidth = 168,
    maxWidth = 230,
    height = "100%",
  }, {
    ui.column({
      width = "100%",
      height = "100%",
      padding = {
        left = compact and 14 or 20,
        right = compact and 14 or 20,
        top = compact and 18 or 26,
        bottom = compact and 12 or 18,
      },
      gap = compact and 8 or 10,
      style = { background = colors.rail },
    }, {
      sectionLabel("Commands"),
      commandButton("INCREMENT", "I", compact, activeCommand == "increment", increment),
      commandButton("RESET", "R", compact, activeCommand == "reset", reset),
      ui.box({ width = "100%", height = compact and 0 or 5, shrink = 0, interactive = false }),
      rule(),
      ui.box({ width = "100%", height = 0, shrink = 0, interactive = false }),
      sectionLabel("Count"),
      ui.text(string.format("%02d", count), {
        font = "mono",
        fontSize = compact and 36 or 44,
        lineHeight = compact and 40 or 50,
        style = { color = colors.text },
      }),
      rule(),
      ui.box({ width = "100%", height = 0, shrink = 0, interactive = false }),
      sectionLabel("Modes"),
      ui.column({
        width = "100%",
        gap = compact and 7 or 9,
        role = "tablist",
        accessibilityLabel = "Workbench modes",
      }, {
        modeButton(1),
        modeButton(2),
        modeButton(3),
      }),
      ui.box({ grow = 1, width = "100%", interactive = false }),
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
    padding = {
      left = compact and 24 or 30,
      right = compact and 20 or 24,
      top = compact and 20 or 32,
      bottom = compact and 14 or 18,
    },
    gap = compact and 8 or 12,
    style = { background = colors.chassis },
  }, {
    ui.row({ width = "100%", height = compact and 42 or 48, align = "center", gap = 12, shrink = 0 }, {
      ui.text("MISSION SYNC", {
        font = "mono",
        fontSize = compact and 30 or 40,
        lineHeight = compact and 38 or 48,
        style = { color = colors.text },
      }),
    }),
    ui.row({ width = "100%", height = compact and 18 or 21, gap = 12, align = "center", shrink = 0 }, {
      ui.meter({
        value = progress,
        max = 1,
        flex = 1,
        height = compact and 8 or 21,
        draw = instrumentMeter(progress),
      }),
      ui.text(string.format("%02d%%", math.floor(progress * 100 + 0.5)), {
        width = compact and 60 or 68,
        font = "mono",
        fontSize = compact and 18 or 23,
        lineHeight = compact and 20 or 25,
        style = { color = colors.amberBright },
      }),
    }),
    ui.box({ width = "100%", height = compact and 12 or 9, shrink = 0, interactive = false }),
    ui.column({ width = "100%", gap = 0 }, {
      metricRow("Input route", "Keyboard + Gamepad", compact),
      metricRow("Event rows", tostring(#logs), compact),
      metricRow("Focus path", modeNames[activeTab], compact),
    }),
    ui.box({ width = "100%", height = compact and 0 or 12, shrink = 0, interactive = false }),
    rule(),
    ui.stack({
      key = "pane-" .. tostring(activeTab),
      width = "100%",
      flex = 1,
      clip = true,
      role = "tabpanel",
      accessibilityLabel = modeNames[activeTab] .. " workbench panel",
    }, {
      panes[activeTab],
    }),
  })

  return ui.column({ width = "100%", height = "100%", style = { background = colors.chassis } }, {
    topBar,
    ui.row({ width = "100%", flex = 1 }, {
      rail,
      workfield,
    }),
  })
end

return {
  id = "workbench",
  label = "Workbench",
  title = "Mission console",
  description = "State, input, semantic modes, metrics, and custom drawing arranged as a compact service workbench.",
  chrome = false,
  window = {
    width = 1024,
    height = 680,
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
    local focused = ui.accessibility.focused()
    if not (focused and focused.type == "input") then
      if key == "i" and workbenchCommands.increment then
        workbenchCommands.increment()
        return true
      elseif key == "r" and workbenchCommands.reset then
        workbenchCommands.reset()
        return true
      end
    end
    if focused and focused.type == "input" and (key == "left" or key == "right") then
      return ui.keypressed(key)
    end
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
