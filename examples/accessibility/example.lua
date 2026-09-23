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
  neutralFill = { 0.58, 0.56, 0.51, 1 },
}

local locale = "en"
local threat = 42
local shield = 76
local selectedMode = "scan"
local eventLog = {}
local offAccessibility = nil
local offAfterRender = nil
local inspectorRefreshPending = false

local translations = {
  en = {
    ["app.title"] = "Accessibility workbench",
    ["app.subtitle"] = "Move focus, activate a semantic control, then inspect the adapter event and tree snapshot.",
    ["mode.scan"] = "Scan",
    ["mode.guard"] = "Guard",
    ["mode.recall"] = "Recall",
    ["mode.scan.description"] = "Read nearby signals",
    ["mode.guard.description"] = "Raise defensive posture",
    ["mode.recall.description"] = "Return squad to safe range",
    ["status.title"] = "Squad status",
    ["status.live"] = "Threat level %{threat} percent. Shield %{shield} percent.",
    ["status.threat"] = "Threat %{value}%",
    ["status.shield"] = "Shield %{value}%",
    ["locale.en"] = "EN",
    ["locale.pseudo"] = "PSEUDO",
    ["adapter.title"] = "Adapter event stream",
    ["snapshot.title"] = "Semantic tree snapshot",
    ["decorative"] = "Decorative service marker hidden from accessibility",
  },
  pseudo = {
    ["app.title"] = "[loc] Accessibility workbench",
    ["app.subtitle"] = "[loc] Move focus, activate a semantic control, then inspect the adapter event and tree snapshot.",
    ["mode.scan"] = "[loc] Scan",
    ["mode.guard"] = "[loc] Guard",
    ["mode.recall"] = "[loc] Recall",
    ["mode.scan.description"] = "[loc] Read nearby signals",
    ["mode.guard.description"] = "[loc] Raise defensive posture",
    ["mode.recall.description"] = "[loc] Return squad to safe range",
    ["status.title"] = "[loc] Squad status",
    ["status.live"] = "[loc] Threat level %{threat} percent. Shield %{shield} percent.",
    ["status.threat"] = "[loc] Threat %{value}%",
    ["status.shield"] = "[loc] Shield %{value}%",
    ["locale.en"] = "EN",
    ["locale.pseudo"] = "PSEUDO",
    ["adapter.title"] = "[loc] Adapter event stream",
    ["snapshot.title"] = "[loc] Semantic tree snapshot",
    ["decorative"] = "[loc] Decorative service marker hidden from accessibility",
  },
}

local function interpolate(value, params)
  if type(value) ~= "string" or type(params) ~= "table" then
    return value
  end

  return (value:gsub("%%{([%w_]+)}", function(name)
    local replacement = params[name]
    return replacement ~= nil and tostring(replacement) or "%{" .. name .. "}"
  end))
end

local function translate(key, params, opts)
  local tableForLocale = translations[locale] or translations.en
  local value = tableForLocale[key] or translations.en[key]
  if value == nil and opts and opts.fallback then
    return opts.fallback
  end
  return interpolate(value, params)
end

local function pushLog(text)
  table.insert(eventLog, 1, text)
  while #eventLog > 8 do
    table.remove(eventLog)
  end
end

local function setup()
  ui.setTheme({
    backgroundColor = colors.chassis,
    surfaceColor = colors.surface,
    surfaceHoverColor = { 0.13, 0.14, 0.14, 1 },
    surfacePressedColor = colors.field,
    textColor = colors.text,
    mutedTextColor = colors.muted,
    borderColor = colors.rule,
    accentColor = colors.amber,
    components = {
      button = {
        background = colors.surface,
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
        color = colors.text,
        hover = {
          background = { 0.13, 0.14, 0.14, 1 },
          borderColor = colors.muted,
        },
        pressed = {
          background = colors.field,
          borderColor = colors.text,
        },
        focused = {
          borderColor = colors.text,
          borderWidth = 2,
        },
        active = {
          background = colors.amber,
          color = colors.amberDark,
        },
      },
      input = {
        background = colors.field,
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
        focused = {
          borderColor = colors.text,
          borderWidth = 2,
        },
      },
      panel = {
        background = colors.field,
        borderColor = colors.rule,
        borderWidth = 1,
        radius = 0,
      },
    },
  })

  ui.i18n.configure({
    translate = translate,
    setLocale = function(nextLocale)
      locale = nextLocale
    end,
    getLocale = function()
      return locale
    end,
  })

  ui.accessibility.configure({
    enabled = true,
    announceOnFocus = true,
    announceOnActivate = true,
  })

  if offAccessibility then
    offAccessibility()
  end
  offAccessibility = ui.on("accessibility", function(event)
    pushLog(string.format("%s: %s", event.kind, event.message or event.label or event.role or "event"))
    inspectorRefreshPending = true
  end)

  if offAfterRender then
    offAfterRender()
  end
  offAfterRender = ui.on("afterRender", function()
    if not inspectorRefreshPending then
      return
    end
    inspectorRefreshPending = false
    if ui.runtime and ui.runtime.markDirty then
      ui.runtime:markDirty()
    end
  end)
  inspectorRefreshPending = true
end

local function teardown()
  if offAccessibility then
    offAccessibility()
    offAccessibility = nil
  end
  if offAfterRender then
    offAfterRender()
    offAfterRender = nil
  end
  inspectorRefreshPending = false
  ui.accessibility.configure({})
  ui.i18n.configure({})
  locale = "en"
  threat = 42
  shield = 76
  selectedMode = "scan"
  eventLog = {}
end

local function rule(color)
  return ui.box({
    width = "100%",
    height = 1,
    interactive = false,
    accessibilityHidden = true,
    style = { background = color or colors.rule },
  })
end

local function verticalRule()
  return ui.box({
    width = 1,
    height = "100%",
    interactive = false,
    accessibilityHidden = true,
    style = { background = colors.rule },
  })
end

local function sectionLabel(label)
  return ui.text(label:upper(), {
    textStyle = "caption",
    accessibilityHidden = true,
    style = { color = colors.muted },
  })
end

local function statusMarker(active)
  return ui.box({
    width = 7,
    height = 7,
    interactive = false,
    accessibilityHidden = true,
    style = { background = active and colors.amber or colors.rule, radius = 0 },
  })
end

local function modeButton(id)
  return ui.button({
    labelKey = "mode." .. id,
    active = selectedMode == id,
    width = "100%",
    height = 35,
    navGroup = "accessibility",
    accessibilityLabelKey = "mode." .. id,
    accessibilityDescriptionKey = "mode." .. id .. ".description",
    onClick = function()
      selectedMode = id
      threat = math.max(0, math.min(100, threat + (id == "guard" and -8 or id == "recall" and -14 or 6)))
      shield = math.max(0, math.min(100, shield + (id == "guard" and 8 or id == "recall" and -4 or -3)))
    end,
  })
end

local function meter(labelKey, value, fill)
  return ui.meter({
    value = value,
    max = 100,
    height = 19,
    width = "100%",
    shape = { kind = "rect", radius = 0 },
    style = { color = colors.text, borderColor = colors.ruleSoft, borderWidth = 1 },
    fillStyle = { background = fill, radius = 0 },
    trackStyle = { background = colors.field, radius = 0 },
    labelKey = labelKey,
    labelParams = { value = value },
    labelCacheKey = labelKey .. ":" .. tostring(value),
    accessibilityLabelKey = labelKey,
    accessibilityLabelParams = { value = value },
    accessibilityLabelCacheKey = "label:" .. labelKey .. ":" .. tostring(value),
    accessibilityValue = value,
    accessibilityValueTextKey = labelKey,
    accessibilityValueTextParams = { value = value },
    accessibilityValueTextCacheKey = "value:" .. labelKey .. ":" .. tostring(value),
  })
end

local function registerHeading(key, count)
  return ui.column({ width = "100%", gap = 6 }, {
    ui.row({ width = "100%", height = 24, align = "center", gap = 8 }, {
      statusMarker(count > 0),
      ui.textKey(key, {
        flex = 1,
        textStyle = "h2",
        accessibilityHidden = true,
        style = { color = colors.text },
      }),
      ui.text(string.format("%02d", count), {
        textStyle = "code",
        accessibilityHidden = true,
        style = { color = count > 0 and colors.amber or colors.muted },
      }),
    }),
    rule(),
  })
end

local function eventHeader()
  return ui.row({
    width = "100%",
    height = 24,
    align = "center",
    padding = { x = 4 },
    accessibilityHidden = true,
    style = { background = colors.surface },
  }, {
    ui.text("SEQ", { width = 42, textStyle = "caption", style = { color = colors.muted } }),
    ui.text("TYPE", { width = 78, textStyle = "caption", style = { color = colors.muted } }),
    ui.text("ANNOUNCEMENT", { flex = 1, textStyle = "caption", style = { color = colors.muted } }),
  })
end

local function eventRows()
  local rows = {}
  for index, entry in ipairs(eventLog) do
    local kind, message = entry:match("^([^:]+):%s*(.*)$")
    kind = kind or "event"
    message = message or entry
    rows[#rows + 1] = ui.stack({
      width = "100%",
      minHeight = 31,
      accessibilityHidden = true,
    }, {
      ui.row({ width = "100%", minHeight = 30, align = "center", padding = { x = 4 } }, {
        ui.text(string.format("%02d", #eventLog - index + 1), {
          width = 42,
          textStyle = "code",
          style = { color = index == 1 and colors.amber or colors.muted },
        }),
        ui.text(kind:upper(), {
          width = 78,
          textStyle = "code",
          style = { color = colors.muted },
        }),
        ui.text(message, {
          flex = 1,
          wrap = true,
          style = { color = index == 1 and colors.text or colors.muted },
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

  if #rows == 0 then
    rows[1] = ui.column({
      width = "100%",
      height = 72,
      justify = "center",
      gap = 3,
      padding = { x = 4 },
      accessibilityHidden = true,
    }, {
      ui.text("Waiting for a semantic event", { style = { color = colors.text } }),
      ui.text("Move focus or activate a control to populate this register.", {
        wrap = true,
        textStyle = "caption",
        style = { color = colors.muted },
      }),
    })
  end
  return rows
end

local function snapshotHeader()
  return ui.row({
    width = "100%",
    height = 24,
    align = "center",
    padding = { x = 4 },
    accessibilityHidden = true,
    style = { background = colors.surface },
  }, {
    ui.text("#", { width = 34, textStyle = "caption", style = { color = colors.muted } }),
    ui.text("ROLE", { width = 76, textStyle = "caption", style = { color = colors.muted } }),
    ui.text("RESOLVED LABEL", { flex = 1, textStyle = "caption", style = { color = colors.muted } }),
  })
end

local function snapshotRows(snapshot)
  local rows = {}
  for index, item in ipairs(snapshot) do
    local focused = item.node == ui.runtime.focusNode
    rows[#rows + 1] = ui.stack({
      width = "100%",
      minHeight = 31,
      accessibilityHidden = true,
    }, {
      ui.row({ width = "100%", minHeight = 30, align = "center", padding = { x = 4 } }, {
        ui.text(string.format("%02d", index), {
          width = 34,
          textStyle = "code",
          style = { color = focused and colors.amber or colors.muted },
        }),
        ui.text((item.role or "-"):upper(), {
          width = 76,
          textStyle = "code",
          style = { color = colors.muted },
        }),
        ui.text(item.label or item.valueText or item.type or "-", {
          flex = 1,
          wrap = true,
          style = { color = focused and colors.text or colors.muted },
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

  if #rows == 0 then
    rows[1] = ui.column({
      width = "100%",
      height = 72,
      justify = "center",
      gap = 3,
      padding = { x = 4 },
      accessibilityHidden = true,
    }, {
      ui.text("Tree not sampled yet", { style = { color = colors.text } }),
      ui.text("The semantic snapshot appears after the first committed frame.", {
        wrap = true,
        textStyle = "caption",
        style = { color = colors.muted },
      }),
    })
  end
  return rows
end

local function registerBody(rows, compact)
  if compact then
    return ui.column({ width = "100%", gap = 0 }, rows)
  end
  return ui.scrollView({
    width = "100%",
    grow = 1,
    minHeight = 150,
    gap = 0,
    padding = { right = 4 },
    style = { background = colors.field },
  }, rows)
end

local function eventRegister(compact)
  return ui.column({
    width = "100%",
    flex = compact and nil or 1,
    height = compact and nil or "100%",
    gap = 0,
    role = "group",
    accessibilityLabelKey = "adapter.title",
  }, {
    registerHeading("adapter.title", #eventLog),
    eventHeader(),
    registerBody(eventRows(), compact),
  })
end

local function snapshotRegister(snapshot, compact)
  return ui.column({
    width = "100%",
    flex = compact and nil or 1,
    height = compact and nil or "100%",
    gap = 0,
    role = "group",
    accessibilityLabelKey = "snapshot.title",
  }, {
    registerHeading("snapshot.title", #snapshot),
    snapshotHeader(),
    registerBody(snapshotRows(snapshot), compact),
  })
end

local function flowStep(index, label, active, compact)
  return ui.row({
    width = compact and "100%" or nil,
    flex = compact and nil or 1,
    minWidth = 150,
    height = 34,
    align = "center",
    gap = 8,
    padding = { x = 8 },
    accessibilityHidden = true,
    style = { background = colors.field },
  }, {
    ui.text(string.format("%02d", index), {
      width = 24,
      textStyle = "code",
      style = { color = active and colors.amber or colors.muted },
    }),
    statusMarker(active),
    ui.text(label, {
      flex = 1,
      textStyle = "caption",
      style = { color = active and colors.text or colors.muted },
    }),
  })
end

local function flowStrip(compact, focused, snapshotCount)
  local children = {
    flowStep(1, "FOCUS CONTROL", focused, compact),
    flowStep(2, "ADAPTER EVENT", #eventLog > 0, compact),
    flowStep(3, "TREE SNAPSHOT", snapshotCount > 0, compact),
  }
  if compact then
    return ui.column({ width = "100%", gap = 1 }, children)
  end
  return ui.row({ width = "100%", gap = 1 }, children)
end

local function statusRegister(compact)
  local meters = {
    meter("status.threat", threat, colors.amber),
    meter("status.shield", shield, colors.neutralFill),
  }

  return ui.column({
    width = "100%",
    gap = 7,
    role = "group",
    accessibilityLabelKey = "status.title",
  }, {
    ui.row({ width = "100%", height = 24, align = "center", gap = 8 }, {
      statusMarker(true),
      ui.textKey("status.title", {
        flex = 1,
        textStyle = "h2",
        accessibilityHidden = true,
        style = { color = colors.text },
      }),
      ui.text(selectedMode:upper(), {
        textStyle = "code",
        accessibilityHidden = true,
        style = { color = colors.amber },
      }),
    }),
    rule(),
    ui.textKey("status.live", {
      textParams = { threat = threat, shield = shield },
      textCacheKey = tostring(threat) .. ":" .. tostring(shield),
      wrap = true,
      accessibilityLive = "polite",
      style = { color = colors.text },
    }),
    compact
      and ui.column({ width = "100%", gap = 6 }, meters)
      or ui.row({ width = "100%", gap = 12 }, {
        ui.box({ flex = 1, display = "column" }, { meters[1] }),
        ui.box({ flex = 1, display = "column" }, { meters[2] }),
      }),
    rule(colors.ruleSoft),
  })
end

local function focusLabel()
  local focused = ui.accessibility.focused()
  return focused and (focused.label or focused.valueText or focused.role) or "No control focused"
end

local function commandRail(compact)
  local focus = ui.accessibility.focused()
  local children = {
    sectionLabel("Semantic controls"),
    modeButton("scan"),
    modeButton("guard"),
    modeButton("recall"),
    ui.textKey("mode." .. selectedMode .. ".description", {
      width = "100%",
      wrap = true,
      textStyle = "caption",
      style = { color = colors.muted },
    }),
    rule(),
    sectionLabel("Locale adapter"),
    ui.row({ width = "100%", gap = 6 }, {
      ui.button({
        labelKey = "locale.en",
        active = locale == "en",
        flex = 1,
        height = 32,
        navGroup = "accessibility",
        onClick = function()
          ui.i18n.setLocale("en")
        end,
      }),
      ui.button({
        labelKey = "locale.pseudo",
        active = locale == "pseudo",
        flex = 1,
        height = 32,
        navGroup = "accessibility",
        onClick = function()
          ui.i18n.setLocale("pseudo")
        end,
      }),
    }),
    rule(),
    sectionLabel("Current focus"),
    ui.row({ width = "100%", gap = 8, align = "center", accessibilityHidden = true }, {
      statusMarker(focus ~= nil),
      ui.text(focusLabel(), {
        flex = 1,
        wrap = true,
        textStyle = "code",
        style = { color = focus and colors.text or colors.muted },
      }),
    }),
    ui.text("Arrow keys or d-pad move focus. Return, Space, or A activates.", {
      width = "100%",
      wrap = true,
      textStyle = "caption",
      accessibilityHidden = true,
      style = { color = colors.muted },
    }),
  }

  if not compact then
    children[#children + 1] = ui.box({ width = "100%", grow = 1, interactive = false })
  end

  children[#children + 1] = ui.row({
    width = "100%",
    gap = 8,
    align = "center",
    accessibilityHidden = true,
  }, {
    statusMarker(true),
    ui.textKey("decorative", {
      flex = 1,
      wrap = true,
      textStyle = "caption",
      accessibilityHidden = true,
      style = { color = colors.muted },
    }),
  })

  local content = ui.column({
    width = "100%",
    height = compact and nil or "100%",
    padding = compact and 0 or { left = 18, right = 18, top = 18, bottom = 15 },
    gap = 8,
    role = "group",
    accessibilityLabel = "Commands",
    style = { background = compact and colors.chassis or colors.rail },
  }, children)

  if compact then
    return content
  end

  return ui.stack({ width = 236, height = "100%" }, {
    content,
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
end

local function pageHeader(compact)
  return ui.column({ width = "100%", gap = 3 }, {
    ui.row({ width = "100%", align = "center", gap = 10 }, {
      ui.textKey("app.title", {
        flex = 1,
        textStyle = "h1",
        wrap = true,
        style = { color = colors.text },
      }),
      ui.row({ gap = 7, align = "center", accessibilityHidden = true }, {
        statusMarker(true),
        ui.text("ADAPTER ONLINE", {
          textStyle = "code",
          style = { color = colors.muted },
        }),
      }),
    }),
    ui.textKey("app.subtitle", {
      width = compact and "100%" or 690,
      wrap = true,
      style = { color = colors.muted },
    }),
  })
end

local function App()
  local viewport = ui.viewport()
  local compact = viewport.width < 900
  local snapshot = ui.accessibility.snapshot()
  local focused = ui.accessibility.focused() ~= nil

  if compact then
    return ui.scrollView({
      width = "100%",
      height = "100%",
      padding = 12,
      gap = 14,
      style = { background = colors.chassis },
    }, {
      pageHeader(true),
      flowStrip(true, focused, #snapshot),
      commandRail(true),
      statusRegister(true),
      eventRegister(true),
      snapshotRegister(snapshot, true),
    })
  end

  local registers = ui.row({
    width = "100%",
    grow = 1,
    minHeight = 220,
    gap = 14,
    align = "stretch",
  }, {
    eventRegister(false),
    verticalRule(),
    snapshotRegister(snapshot, false),
  })

  local workfield = ui.column({
    flex = 1,
    height = "100%",
    padding = { left = 22, right = 18, top = 15, bottom = 13 },
    gap = 10,
    style = { background = colors.chassis },
  }, {
    pageHeader(false),
    flowStrip(false, focused, #snapshot),
    statusRegister(false),
    registers,
  })

  return ui.row({
    width = "100%",
    height = "100%",
    style = { background = colors.chassis },
  }, {
    commandRail(false),
    workfield,
  })
end

return {
  id = "accessibility",
  label = "Accessibility",
  description = "Inspect semantic controls, focus and live announcements, adapter events, and the accessibility tree in a flat service workbench.",
  setup = setup,
  teardown = teardown,
  window = {
    width = 1040,
    height = 640,
    resizable = true,
    title = "glyph - accessibility",
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
    elseif key == "kpenter" then
      return ui.keypressed("return")
    end
    return ui.keypressed(key)
  end,
  keyreleased = function(key)
    if key == "kpenter" then
      return ui.keyreleased("return")
    end
    return ui.keyreleased(key)
  end,
}
