local ui = require("glyph")

local activeTheme = "command"
local radiusLevel = 2
local borderLevel = 2
local density = "comfortable"
local accentName = "theme"
local activeTab = 1
local selectedMission = 1
local selectedUnit = 1
local filter = "reactor"

local radiusValues = { 0, 5, 10, 18 }
local borderValues = { 0, 1, 2, 3 }

local densityValues = {
  compact = { label = "Compact", fontSize = 12, lineHeight = 16, gap = 7, pad = 9, row = 30, button = 28 },
  comfortable = { label = "Comfort", fontSize = 13, lineHeight = 18, gap = 10, pad = 12, row = 36, button = 32 },
  spacious = { label = "Spacious", fontSize = 14, lineHeight = 21, gap = 13, pad = 16, row = 44, button = 38 },
}

local densityOrder = { "compact", "comfortable", "spacious" }

local accents = {
  { id = "theme", label = "Theme" },
  { id = "teal", label = "Teal", color = { 0.08, 0.76, 0.66, 1 } },
  { id = "ember", label = "Ember", color = { 0.95, 0.28, 0.16, 1 } },
  { id = "violet", label = "Violet", color = { 0.62, 0.36, 0.95, 1 } },
  { id = "lime", label = "Lime", color = { 0.62, 0.86, 0.16, 1 } },
}

local missions = {
  { name = "Reactor Sweep", zone = "North Array", risk = "High", progress = 82, signal = 64 },
  { name = "Relay Defense", zone = "Harbor Grid", risk = "Medium", progress = 56, signal = 47 },
  { name = "Archive Trace", zone = "Deep Vault", risk = "Low", progress = 35, signal = 91 },
  { name = "Convoy Shadow", zone = "Outer Ring", risk = "Critical", progress = 18, signal = 32 },
}

local units = {
  { name = "Vera", role = "Signal", hp = 88, energy = 62, status = "Ready" },
  { name = "Mako", role = "Shield", hp = 74, energy = 45, status = "Guard" },
  { name = "Iris", role = "Tactics", hp = 66, energy = 83, status = "Focus" },
  { name = "Noor", role = "Runner", hp = 51, energy = 70, status = "Moving" },
}

local activity = {
  { time = "08:12", level = "info", text = "Theme token pass applied to command surfaces." },
  { time = "08:15", level = "warn", text = "Border intensity changed on tactical cards." },
  { time = "08:18", level = "info", text = "Density profile recalculated layout rhythm." },
  { time = "08:22", level = "error", text = "Critical mission requires operator review." },
  { time = "08:27", level = "info", text = "Scroll bar inherits theme thumb and width." },
  { time = "08:30", level = "warn", text = "Accent override pushed to buttons and tabs." },
  { time = "08:34", level = "info", text = "Focused and active states remain visible." },
}

local function rgba(color, alpha)
  return { color[1], color[2], color[3], alpha ~= nil and alpha or (color[4] or 1) }
end

local function accentColor(base)
  if accentName == "theme" then
    return base.accent
  end

  for _, item in ipairs(accents) do
    if item.id == accentName and item.color then
      return item.color
    end
  end

  return base.accent
end

local function themeFrom(base, tweaks)
  local d = densityValues[tweaks.density]
  local radius = radiusValues[tweaks.radiusLevel]
  local border = borderValues[tweaks.borderLevel]
  local accent = accentColor(base)

  return {
    backgroundColor = base.background,
    surfaceColor = base.surface,
    surfaceHoverColor = base.hover,
    surfacePressedColor = base.pressed,
    borderColor = base.border,
    textColor = base.text,
    mutedTextColor = base.muted,
    accentColor = accent,
    accentTextColor = base.accentText,
    disabledColor = base.disabled,
    inputColor = base.input,
    scrollbarColor = rgba(accent, 0.72),
    fontSize = d.fontSize,
    lineHeight = d.lineHeight,
    radius = radius,
    borderWidth = border,
    scrollbarWidth = math.max(4, 4 + border * 2),
    components = {
      panel = {
        background = base.surface,
        borderColor = base.border,
        borderWidth = border,
        radius = radius,
      },
      button = {
        background = base.surfaceAlt,
        color = base.text,
        borderColor = base.border,
        borderWidth = border,
        radius = radius,
        hover = { background = base.hover, borderColor = accent },
        pressed = { background = base.pressed },
        active = {
          background = rgba(accent, 0.28),
          borderColor = accent,
          color = base.text,
        },
        focused = {
          borderColor = base.focus,
        },
        disabled = {
          background = base.disabled,
          color = base.muted,
          opacity = 0.72,
        },
        variants = {
          primary = {
            background = accent,
            color = base.accentText,
            borderColor = rgba(base.accentText, 0.25),
            hover = { background = rgba(accent, 0.86) },
            pressed = { background = rgba(accent, 0.68) },
          },
          ghost = {
            background = rgba(base.surface, 0),
            color = base.text,
            borderColor = rgba(base.border, 0.75),
            hover = { background = rgba(accent, 0.16), borderColor = accent },
            active = { background = rgba(accent, 0.22), borderColor = accent },
          },
          danger = {
            background = base.danger,
            color = base.dangerText,
            borderColor = rgba(base.dangerText, 0.22),
            hover = { background = rgba(base.danger, 0.82) },
            pressed = { background = rgba(base.danger, 0.64) },
          },
          warning = {
            background = base.warning,
            color = base.warningText,
            borderColor = rgba(base.warningText, 0.22),
            hover = { background = rgba(base.warning, 0.82) },
          },
        },
      },
      input = {
        background = base.input,
        color = base.text,
        placeholderColor = base.muted,
        borderColor = base.border,
        borderWidth = border,
        radius = radius,
        focused = {
          borderColor = accent,
        },
      },
      tab = {
        background = base.surfaceAlt,
        color = base.text,
        borderColor = base.border,
        borderWidth = border,
        radius = radius,
        active = {
          background = rgba(accent, 0.24),
          color = base.text,
          borderColor = accent,
        },
        hover = {
          background = base.hover,
        },
        pressed = {
          background = base.pressed,
        },
      },
      scrollBar = {
        width = math.max(4, 4 + border * 2),
        padding = 2,
        minThumbSize = 26,
        radius = math.max(2, radius),
        trackColor = rgba(base.surfaceAlt, 0.38),
        thumbColor = rgba(accent, 0.76),
      },
    },
  }
end

local presetBuilders = {
  command = function(tweaks)
    return themeFrom({
      background = { 0.035, 0.043, 0.055, 1 },
      surface = { 0.075, 0.09, 0.115, 1 },
      surfaceAlt = { 0.105, 0.125, 0.155, 1 },
      hover = { 0.15, 0.18, 0.22, 1 },
      pressed = { 0.055, 0.066, 0.086, 1 },
      border = { 0.28, 0.34, 0.42, 1 },
      text = { 0.92, 0.95, 0.98, 1 },
      muted = { 0.58, 0.65, 0.72, 1 },
      accent = { 0.1, 0.74, 0.68, 1 },
      accentText = { 0.02, 0.045, 0.05, 1 },
      input = { 0.045, 0.055, 0.072, 1 },
      disabled = { 0.09, 0.1, 0.12, 1 },
      focus = { 0.72, 0.92, 1, 1 },
      danger = { 0.68, 0.12, 0.18, 1 },
      dangerText = { 1, 0.95, 0.95, 1 },
      warning = { 0.86, 0.58, 0.16, 1 },
      warningText = { 0.08, 0.06, 0.02, 1 },
    }, tweaks)
  end,
  solar = function(tweaks)
    return themeFrom({
      background = { 0.91, 0.84, 0.66, 1 },
      surface = { 0.98, 0.93, 0.78, 1 },
      surfaceAlt = { 0.86, 0.72, 0.46, 1 },
      hover = { 0.94, 0.79, 0.5, 1 },
      pressed = { 0.76, 0.58, 0.36, 1 },
      border = { 0.38, 0.25, 0.12, 1 },
      text = { 0.12, 0.085, 0.045, 1 },
      muted = { 0.42, 0.31, 0.18, 1 },
      accent = { 0.0, 0.42, 0.64, 1 },
      accentText = { 0.96, 0.99, 1, 1 },
      input = { 1, 0.96, 0.83, 1 },
      disabled = { 0.72, 0.65, 0.5, 1 },
      focus = { 0.0, 0.52, 0.78, 1 },
      danger = { 0.74, 0.22, 0.11, 1 },
      dangerText = { 1, 0.96, 0.9, 1 },
      warning = { 0.98, 0.66, 0.16, 1 },
      warningText = { 0.14, 0.08, 0.02, 1 },
    }, tweaks)
  end,
  neon = function(tweaks)
    return themeFrom({
      background = { 0.025, 0.02, 0.045, 1 },
      surface = { 0.08, 0.045, 0.12, 1 },
      surfaceAlt = { 0.12, 0.06, 0.18, 1 },
      hover = { 0.18, 0.08, 0.28, 1 },
      pressed = { 0.05, 0.025, 0.08, 1 },
      border = { 0.44, 0.22, 0.72, 1 },
      text = { 0.98, 0.93, 1, 1 },
      muted = { 0.72, 0.62, 0.82, 1 },
      accent = { 0.95, 0.22, 0.78, 1 },
      accentText = { 0.04, 0.02, 0.05, 1 },
      input = { 0.045, 0.03, 0.072, 1 },
      disabled = { 0.12, 0.1, 0.14, 1 },
      focus = { 0.2, 0.92, 1, 1 },
      danger = { 1, 0.18, 0.34, 1 },
      dangerText = { 1, 1, 1, 1 },
      warning = { 0.1, 0.86, 0.92, 1 },
      warningText = { 0.02, 0.04, 0.05, 1 },
    }, tweaks)
  end,
  paper = function(tweaks)
    return themeFrom({
      background = { 0.94, 0.94, 0.9, 1 },
      surface = { 0.99, 0.985, 0.95, 1 },
      surfaceAlt = { 0.9, 0.9, 0.84, 1 },
      hover = { 0.86, 0.89, 0.86, 1 },
      pressed = { 0.76, 0.8, 0.76, 1 },
      border = { 0.2, 0.23, 0.2, 1 },
      text = { 0.08, 0.095, 0.08, 1 },
      muted = { 0.38, 0.42, 0.38, 1 },
      accent = { 0.12, 0.42, 0.24, 1 },
      accentText = { 0.98, 1, 0.96, 1 },
      input = { 1, 1, 0.97, 1 },
      disabled = { 0.8, 0.8, 0.74, 1 },
      focus = { 0.1, 0.36, 0.22, 1 },
      danger = { 0.72, 0.18, 0.16, 1 },
      dangerText = { 1, 0.96, 0.94, 1 },
      warning = { 0.86, 0.68, 0.18, 1 },
      warningText = { 0.1, 0.08, 0.02, 1 },
    }, tweaks)
  end,
}

local themeLabels = {
  command = "Command Dark",
  solar = "Solar Console",
  neon = "Arcade Neon",
  paper = "Paper Ops",
}

local function buildTheme(preset, tweaks)
  return (presetBuilders[preset] or presetBuilders.command)(tweaks)
end

local function currentTweaks()
  return {
    radiusLevel = radiusLevel,
    borderLevel = borderLevel,
    density = density,
  }
end

local function applyTheme()
  ui.setTheme(buildTheme(activeTheme, currentTweaks()))
end

local function metrics()
  local d = densityValues[density]
  return {
    gap = d.gap,
    pad = d.pad,
    row = d.row,
    button = d.button,
    radius = radiusValues[radiusLevel],
    border = borderValues[borderLevel],
  }
end

local function themeButton(id, width)
  return ui.button({
    label = themeLabels[id],
    width = width,
    height = metrics().button,
    variant = activeTheme == id and "primary" or "ghost",
    active = activeTheme == id,
    onClick = function()
      activeTheme = id
      accentName = "theme"
      applyTheme()
    end,
  })
end

local function tokenControl(label, valueText, onMinus, onPlus, width)
  local m = metrics()
  local labelWidth = width < 230 and 56 or 84
  local valueWidth = math.max(34, width - labelWidth - 78)
  return ui.row({ gap = 6, align = "center", width = width }, {
    ui.text(label, { width = labelWidth, style = { color = ui.theme.mutedTextColor } }),
    ui.button({ label = "-", width = 30, height = m.button, variant = "ghost", onClick = onMinus }),
    ui.text(valueText, { width = valueWidth }),
    ui.button({ label = "+", width = 30, height = m.button, variant = "ghost", onClick = onPlus }),
  })
end

local function swatchButton(item, width)
  local active = accentName == item.id
  local color = item.color or ui.theme.accentColor
  return ui.button({
    label = item.label,
    width = width or 74,
    height = metrics().button,
    active = active,
    variant = active and "primary" or "ghost",
    onClick = function()
      accentName = item.id
      applyTheme()
    end,
    style = {
      borderColor = color,
      focused = {
        borderColor = color,
      },
    },
  })
end

local function metricCard(label, value, max, variant, width)
  local fill = ui.theme.accentColor
  if variant == "danger" then
    fill = { 0.86, 0.18, 0.22, 1 }
  elseif variant == "warning" then
    fill = { 0.9, 0.64, 0.16, 1 }
  end

  return ui.panel({
    width = width,
    padding = metrics().pad,
    gap = 7,
    style = {
      background = rgba(ui.theme.surfaceColor, 0.96),
    },
  }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.text(label, { style = { color = ui.theme.mutedTextColor } }),
      ui.box({ grow = 1, height = 1, interactive = false }),
      ui.text(tostring(value) .. "%"),
    }),
    ui.meter({
      value = value,
      min = 0,
      max = max,
      height = 10,
      width = "100%",
      shape = { kind = "skew", skew = -8 },
      trackStyle = { background = rgba(ui.theme.backgroundColor, 0.78) },
      fillStyle = { background = fill },
    }),
  })
end

local function missionRow(index, mission, width)
  local selected = selectedMission == index
  local variant = mission.risk == "Critical" and "danger" or (mission.risk == "High" and "warning" or "ghost")
  return ui.button({
    label = string.format("%s  %s  %d%%", mission.name, mission.risk, mission.progress),
    width = width,
    height = metrics().row,
    active = selected,
    variant = selected and "primary" or variant,
    onClick = function()
      selectedMission = index
    end,
  })
end

local function unitCard(index, unit, width)
  local selected = selectedUnit == index
  return ui.panel({
    width = width,
    padding = metrics().pad,
    gap = 7,
    style = {
      background = selected and rgba(ui.theme.accentColor, 0.16) or ui.theme.surfaceColor,
      borderColor = selected and ui.theme.accentColor or ui.theme.borderColor,
      borderWidth = math.max(1, metrics().border),
    },
  }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.button({
        label = unit.name,
        width = 88,
        active = selected,
        variant = selected and "primary" or "ghost",
        onClick = function()
          selectedUnit = index
        end,
      }),
      ui.text(unit.role, { style = { color = ui.theme.mutedTextColor } }),
      ui.box({ grow = 1, height = 1, interactive = false }),
      ui.text(unit.status),
    }),
    ui.meter({
      value = unit.hp,
      min = 0,
      max = 100,
      height = 8,
      width = "100%",
      trackStyle = { background = rgba(ui.theme.backgroundColor, 0.68) },
      fillStyle = { background = { 0.22, 0.78, 0.42, 1 } },
    }),
    ui.meter({
      value = unit.energy,
      min = 0,
      max = 100,
      height = 8,
      width = "100%",
      trackStyle = { background = rgba(ui.theme.backgroundColor, 0.68) },
      fillStyle = { background = ui.theme.accentColor },
    }),
  })
end

local function activityRow(entry, width)
  local color = ui.theme.mutedTextColor
  if entry.level == "warn" then
    color = { 0.9, 0.62, 0.16, 1 }
  elseif entry.level == "error" then
    color = { 0.9, 0.18, 0.22, 1 }
  end

  return ui.row({ gap = 10, width = width, align = "center" }, {
    ui.text(entry.time, { width = 48, style = { color = ui.theme.mutedTextColor } }),
    ui.box({
      width = 8,
      height = 8,
      style = {
        background = color,
        radius = 4,
      },
    }),
    ui.text(entry.text, { width = math.max(180, width - 82), wrap = true }),
  })
end

local function tokenPanel(width)
  local m = metrics()
  local controlWidth = width - m.pad * 2
  local compact = controlWidth < 290
  local compactButtonWidth = math.max(74, math.floor((controlWidth - 6) / 2))
  local densityButtons = {}
  for _, id in ipairs(densityOrder) do
    densityButtons[#densityButtons + 1] = ui.button({
      label = densityValues[id].label,
      width = compact and compactButtonWidth or 92,
      height = m.button,
      active = density == id,
      variant = density == id and "primary" or "ghost",
      onClick = function()
        density = id
        applyTheme()
      end,
    })
  end

  local swatches = {}
  for _, item in ipairs(accents) do
    swatches[#swatches + 1] = swatchButton(item, compact and compactButtonWidth or 74)
  end
  local densityControl = compact and ui.column({ gap = 6 }, {
    ui.row({ gap = 6 }, { densityButtons[1], densityButtons[2] }),
    densityButtons[3],
  }) or ui.row({ gap = 6 }, densityButtons)
  local swatchControl = compact and ui.column({ gap = 6 }, {
    ui.row({ gap = 6 }, { swatches[1], swatches[2] }),
    ui.row({ gap = 6 }, { swatches[3], swatches[4] }),
    swatches[5],
  }) or ui.row({ gap = 6 }, swatches)

  return ui.panel({
    title = "Theme Tokens",
    width = width,
    padding = m.pad,
    gap = m.gap,
  }, {
    tokenControl("Radius", tostring(radiusValues[radiusLevel]), function()
      radiusLevel = math.max(1, radiusLevel - 1)
      applyTheme()
    end, function()
      radiusLevel = math.min(#radiusValues, radiusLevel + 1)
      applyTheme()
    end, controlWidth),
    tokenControl("Border", tostring(borderValues[borderLevel]), function()
      borderLevel = math.max(1, borderLevel - 1)
      applyTheme()
    end, function()
      borderLevel = math.min(#borderValues, borderLevel + 1)
      applyTheme()
    end, controlWidth),
    densityControl,
    swatchControl,
  })
end

local function sidebar(width)
  local m = metrics()
  return ui.column({ gap = m.gap, width = width }, {
    ui.panel({
      title = "Presets",
      width = width,
      padding = m.pad,
      gap = 7,
    }, {
      themeButton("command", width - m.pad * 2),
      themeButton("solar", width - m.pad * 2),
      themeButton("neon", width - m.pad * 2),
      themeButton("paper", width - m.pad * 2),
    }),
    tokenPanel(width),
  })
end

local function chartBox(width)
  return ui.box({
    width = width,
    height = 118,
    style = {
      background = rgba(ui.theme.backgroundColor, 0.6),
      borderColor = ui.theme.borderColor,
      borderWidth = math.max(1, metrics().border),
      radius = metrics().radius,
    },
    draw = function(_, x, y, w, h, loveModule, style, ctx)
      local graphics = loveModule.graphics
      ctx:color(style.background)
      graphics.rectangle("fill", x, y, w, h, style.radius, style.radius)
      ctx:color(style.borderColor)
      graphics.rectangle("line", x, y, w, h, style.radius, style.radius)
      for i = 1, 8 do
        local px = x + 18 + (i - 1) * ((w - 36) / 7)
        local bar = 24 + ((i * 17) % 58)
        ctx:color(ui.theme.accentColor, 0.24 + i * 0.035)
        graphics.rectangle("fill", px - 7, y + h - 18 - bar, 14, bar, 4, 4)
      end
      ctx:color(ui.theme.textColor)
      graphics.print("Resolved style powers custom draw too", x + 14, y + 12)
    end,
  })
end

local function missionContent(width)
  local m = metrics()
  local selected = missions[selectedMission]
  local missionRows = {}
  for index, mission in ipairs(missions) do
    missionRows[#missionRows + 1] = missionRow(index, mission, width - m.pad * 2)
  end

  return ui.column({ gap = m.gap, width = width }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.input({
        value = filter,
        placeholder = "Filter missions...",
        width = math.min(260, width - 148),
        onChange = function(value)
          filter = value
        end,
      }),
      ui.button({ label = "Sync", variant = "primary", width = 72 }),
      ui.button({ label = "Hold", variant = "warning", width = 72 }),
      ui.button({ label = "Abort", variant = "danger", width = 72, disabled = selected.risk ~= "Critical" }),
    }),
    ui.column({ gap = 7 }, missionRows),
  })
end

local function loadoutContent(width)
  local m = metrics()
  local cardWidth = width >= 620 and math.floor((width - m.gap) / 2) or width
  local cards = {}
  for index, unit in ipairs(units) do
    cards[#cards + 1] = unitCard(index, unit, cardWidth)
  end

  if width >= 620 then
    return ui.column({ gap = m.gap, width = width }, {
      ui.row({ gap = m.gap }, { cards[1], cards[2] }),
      ui.row({ gap = m.gap }, { cards[3], cards[4] }),
    })
  end

  return ui.column({ gap = m.gap, width = width }, cards)
end

local function telemetryContent(width)
  return ui.column({ gap = metrics().gap, width = width }, {
    chartBox(width),
    ui.row({ gap = 8 }, {
      ui.button({ label = "Focused target", width = 140, variant = "ghost", active = true }),
      ui.button({ label = "Disabled action", width = 140, disabled = true }),
    }),
  })
end

local function mainPanel(width)
  local m = metrics()
  local metricWidth = width >= 560 and math.floor((width - m.gap * 2) / 3) or width
  local metricsRow = width >= 560 and ui.row({ gap = m.gap }, {
    metricCard("Mission", missions[selectedMission].progress, 100, "primary", metricWidth),
    metricCard("Signal", missions[selectedMission].signal, 100, "warning", metricWidth),
    metricCard("Risk", missions[selectedMission].risk == "Critical" and 94 or 58, 100, "danger", metricWidth),
  }) or ui.column({ gap = m.gap }, {
    metricCard("Mission", missions[selectedMission].progress, 100, "primary", metricWidth),
    metricCard("Signal", missions[selectedMission].signal, 100, "warning", metricWidth),
    metricCard("Risk", missions[selectedMission].risk == "Critical" and 94 or 58, 100, "danger", metricWidth),
  })

  return ui.panel({
    title = "Operations",
    width = width,
    padding = m.pad,
    gap = m.gap,
  }, {
    metricsRow,
    ui.tabs({
      active = activeTab,
      onChange = function(index)
        activeTab = index
      end,
      tabStyle = {
        borderWidth = math.max(1, m.border),
        radius = m.radius,
      },
    }, {
      { label = "Missions", content = missionContent(width - m.pad * 2) },
      { label = "Loadout", content = loadoutContent(width - m.pad * 2) },
      { label = "Telemetry", content = telemetryContent(width - m.pad * 2) },
    }),
  })
end

local function inspectorPanel(width)
  local m = metrics()
  local mission = missions[selectedMission]
  local unit = units[selectedUnit]
  return ui.panel({
    title = "Inspector",
    width = width,
    padding = m.pad,
    gap = m.gap,
  }, {
    ui.text(mission.name),
    ui.text(mission.zone .. " / " .. mission.risk, {
      style = {
        color = ui.theme.mutedTextColor,
      },
    }),
    ui.meter({
      value = mission.progress,
      min = 0,
      max = 100,
      height = 12,
      width = "100%",
      shape = { kind = "skew", skew = 10 },
      trackStyle = { background = rgba(ui.theme.backgroundColor, 0.72) },
      fillStyle = { background = ui.theme.accentColor },
    }),
    ui.panel({
      title = "Assigned Unit",
      width = "100%",
      padding = math.max(8, m.pad - 2),
      gap = 6,
      style = {
        background = rgba(ui.theme.backgroundColor, 0.36),
      },
    }, {
      ui.text(unit.name .. " / " .. unit.role),
      ui.text(unit.status, { style = { color = ui.theme.mutedTextColor } }),
      ui.row({ gap = 8 }, {
        ui.button({ label = "Promote", width = 92, variant = "primary" }),
        ui.button({ label = "Bench", width = 74, variant = "ghost" }),
      }),
    }),
  })
end

local function activityPanel(width)
  local m = metrics()
  local rows = {}
  for _, entry in ipairs(activity) do
    rows[#rows + 1] = activityRow(entry, width - m.pad * 2 - 12)
  end

  return ui.panel({
    title = "Activity Log",
    width = width,
    height = 190,
    padding = m.pad,
    gap = 8,
  }, {
    ui.scrollView({
      width = "100%",
      height = 132,
      gap = 8,
      padding = 4,
      style = {
        background = rgba(ui.theme.backgroundColor, 0.28),
      },
    }, rows),
  })
end

local function header(width)
  local m = metrics()
  local compact = width < 760
  local title = ui.column({ gap = 2, width = compact and width or math.max(260, width - 438) }, {
    ui.text("Theme Command Deck"),
    ui.text("Preset themes plus live tokens for color, radius, borders, density, states, and scrollbars.", {
      wrap = true,
      width = "100%",
      style = {
        color = ui.theme.mutedTextColor,
      },
    }),
  })
  local actions = ui.row({ gap = 8 }, {
    ui.button({ label = "Primary", variant = "primary", width = 92, height = m.button }),
    ui.button({ label = "Ghost", variant = "ghost", width = 78, height = m.button }),
    ui.button({ label = "Warning", variant = "warning", width = 92, height = m.button }),
    ui.button({ label = "Danger", variant = "danger", width = 84, height = m.button }),
  })

  if compact then
    return ui.column({ gap = m.gap, width = width }, { title, actions })
  end

  return ui.row({ gap = m.gap, align = "center", width = width }, {
    title,
    ui.box({ grow = 1, height = 1, interactive = false }),
    actions,
  })
end

local function App()
  local viewport = ui.viewport()
  local compact = ui.below("md")
  local medium = ui.below("lg")
  local m = metrics()
  local outerPad = compact and 12 or 16
  local contentWidth = math.max(360, viewport.width - outerPad * 2)
  local sideWidth = compact and contentWidth or 206
  local inspectorWidth = medium and contentWidth - sideWidth - m.gap or 292
  local mainWidth = contentWidth

  local body
  if compact then
    body = ui.column({ gap = m.gap, width = contentWidth }, {
      sidebar(contentWidth),
      mainPanel(contentWidth),
      inspectorPanel(contentWidth),
    })
  elseif medium then
    mainWidth = contentWidth - sideWidth - m.gap
    body = ui.row({ gap = m.gap, width = contentWidth, align = "stretch" }, {
      sidebar(sideWidth),
      ui.column({ gap = m.gap, width = mainWidth }, {
        mainPanel(mainWidth),
        inspectorPanel(mainWidth),
      }),
    })
  else
    mainWidth = contentWidth - sideWidth - inspectorWidth - m.gap * 2
    body = ui.row({ gap = m.gap, width = contentWidth, align = "stretch" }, {
      sidebar(sideWidth),
      mainPanel(mainWidth),
      inspectorPanel(inspectorWidth),
    })
  end

  return ui.stack({ width = viewport.width, height = viewport.height }, {
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = false,
      style = {
        background = ui.theme.backgroundColor,
      },
    }),
    ui.scrollView({ width = "100%", height = "100%" }, {
      ui.column({
        width = "100%",
        padding = outerPad,
        gap = m.gap,
      }, {
        header(contentWidth),
        body,
        activityPanel(contentWidth),
      }),
    }),
  })
end

local function setup()
  applyTheme()
end

return {
  id = "themes",
  label = "Themes",
  window = {
    width = 1180,
    height = 760,
    resizable = true,
    minWidth = 720,
    minHeight = 520,
    breakpoints = { md = 760, lg = 1080 },
    title = "glyph - themes",
  },
  setup = setup,
  component = function()
    return App()
  end,
}
