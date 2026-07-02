local ui = require("glyph")

local locale = "en"
local threat = 42
local shield = 76
local selectedMode = "scan"
local eventLog = {}
local offAccessibility = nil

local translations = {
  en = {
    ["app.title"] = "ACCESS CONSOLE",
    ["app.subtitle"] = "Semantic events for keyboard, gamepad, pointer, live regions, and localized labels.",
    ["mode.scan"] = "Scan",
    ["mode.guard"] = "Guard",
    ["mode.recall"] = "Recall",
    ["mode.scan.description"] = "Read nearby signals",
    ["mode.guard.description"] = "Raise defensive posture",
    ["mode.recall.description"] = "Return squad to safe range",
    ["status.title"] = "Squad Status",
    ["status.live"] = "Threat level %{threat} percent. Shield %{shield} percent.",
    ["status.threat"] = "Threat %{value}%",
    ["status.shield"] = "Shield %{value}%",
    ["locale.en"] = "EN",
    ["locale.pseudo"] = "PSEUDO",
    ["adapter.title"] = "Adapter Log",
    ["snapshot.title"] = "Semantic Snapshot",
    ["decorative"] = "Decorative scanline hidden from accessibility",
  },
  pseudo = {
    ["app.title"] = "[loc] ACCESS CONSOLE",
    ["app.subtitle"] = "[loc] Semantic events for keyboard, gamepad, pointer, live regions, and localized labels.",
    ["mode.scan"] = "[loc] Scan",
    ["mode.guard"] = "[loc] Guard",
    ["mode.recall"] = "[loc] Recall",
    ["mode.scan.description"] = "[loc] Read nearby signals",
    ["mode.guard.description"] = "[loc] Raise defensive posture",
    ["mode.recall.description"] = "[loc] Return squad to safe range",
    ["status.title"] = "[loc] Squad Status",
    ["status.live"] = "[loc] Threat level %{threat} percent. Shield %{shield} percent.",
    ["status.threat"] = "[loc] Threat %{value}%",
    ["status.shield"] = "[loc] Shield %{value}%",
    ["locale.en"] = "EN",
    ["locale.pseudo"] = "PSEUDO",
    ["adapter.title"] = "[loc] Adapter Log",
    ["snapshot.title"] = "[loc] Semantic Snapshot",
    ["decorative"] = "[loc] Decorative scanline hidden from accessibility",
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
    backgroundColor = { 0.025, 0.03, 0.045, 1 },
    surfaceColor = { 0.055, 0.075, 0.105, 1 },
    surfaceHoverColor = { 0.08, 0.12, 0.16, 1 },
    surfacePressedColor = { 0.025, 0.045, 0.07, 1 },
    textColor = { 0.92, 0.97, 1, 1 },
    mutedTextColor = { 0.55, 0.7, 0.78, 1 },
    borderColor = { 0.16, 0.44, 0.58, 1 },
    accentColor = { 0.1, 0.84, 1, 1 },
    components = {
      button = {
        background = { 0.05, 0.11, 0.16, 1 },
        borderColor = { 0.1, 0.84, 1, 0.36 },
        focused = { borderColor = { 1, 0.86, 0.2, 1 }, borderWidth = 2 },
        active = { background = { 0.1, 0.84, 1, 0.22 }, borderColor = { 0.1, 0.84, 1, 1 } },
      },
      panel = {
        background = { 0.04, 0.055, 0.085, 0.95 },
        borderColor = { 0.1, 0.84, 1, 0.28 },
        borderWidth = 1,
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
  end)
end

local function teardown()
  if offAccessibility then
    offAccessibility()
    offAccessibility = nil
  end
  ui.accessibility.configure({})
  ui.i18n.configure({})
  locale = "en"
  threat = 42
  shield = 76
  selectedMode = "scan"
  eventLog = {}
end

local function modeButton(id)
  return ui.button({
    labelKey = "mode." .. id,
    active = selectedMode == id,
    width = "100%",
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

local function meter(labelKey, value, color)
  return ui.meter({
    value = value,
    max = 100,
    height = 18,
    width = "100%",
    shape = { kind = "skew", skew = 10 },
    fillStyle = { background = color },
    trackStyle = { background = { 0, 0, 0, 0.34 } },
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

local function eventRows()
  local rows = {}
  for index, entry in ipairs(eventLog) do
    rows[#rows + 1] = ui.text(entry, {
      wrap = true,
      accessibilityHidden = true,
      style = { color = index == 1 and ui.theme.textColor or ui.theme.mutedTextColor },
    })
  end
  if #rows == 0 then
    rows[1] = ui.text("Focus or activate controls to emit semantic events.", {
      wrap = true,
      accessibilityHidden = true,
      style = { color = ui.theme.mutedTextColor },
    })
  end
  return rows
end

local function snapshotRows()
  local rows = {}
  local snapshot = ui.accessibility.snapshot()
  for index, item in ipairs(snapshot) do
    rows[#rows + 1] = ui.text(string.format("%02d  %s  %s", index, item.role or "-", item.label or item.valueText or item.type), {
      wrap = true,
      accessibilityHidden = true,
      style = { color = item.node == ui.runtime.focusNode and { 1, 0.86, 0.2, 1 } or ui.theme.mutedTextColor },
    })
  end
  if #rows == 0 then
    rows[1] = ui.text("Snapshot appears after the first rendered frame.", {
      accessibilityHidden = true,
      style = { color = ui.theme.mutedTextColor },
    })
  end
  return rows
end

local function statusPanel()
  return ui.panel({
    titleKey = "status.title",
    role = "group",
    gap = 10,
    accessibilityLabelKey = "status.title",
  }, {
    ui.textKey("status.live", {
      textParams = { threat = threat, shield = shield },
      textCacheKey = tostring(threat) .. ":" .. tostring(shield),
      wrap = true,
      accessibilityLive = "polite",
    }),
    meter("status.threat", threat, { 1, 0.22, 0.32, 1 }),
    meter("status.shield", shield, { 0.1, 0.84, 1, 1 }),
  })
end

local function App()
  local viewport = ui.viewport()
  local narrow = viewport.width < 760
  local medium = viewport.width < 1040
  local contentGap = narrow and 10 or 14
  local body = {
    ui.panel({ title = "Commands", role = "group", gap = 8, width = narrow and "100%" or 220 }, {
      modeButton("scan"),
      modeButton("guard"),
      modeButton("recall"),
      ui.row({ gap = 8 }, {
        ui.button({
          labelKey = "locale.en",
          active = locale == "en",
          width = 88,
          navGroup = "accessibility",
          onClick = function()
            ui.i18n.setLocale("en")
          end,
        }),
        ui.button({
          labelKey = "locale.pseudo",
          active = locale == "pseudo",
          width = 104,
          navGroup = "accessibility",
          onClick = function()
            ui.i18n.setLocale("pseudo")
          end,
        }),
      }),
    }),
    ui.column({ gap = contentGap, flex = 1, minWidth = narrow and nil or 320 }, {
      statusPanel(),
      ui.panel({
        titleKey = "adapter.title",
        role = "group",
        gap = 6,
      }, eventRows()),
    }),
    ui.panel({
      titleKey = "snapshot.title",
      role = "group",
      gap = 6,
      width = narrow and "100%" or medium and "100%" or 320,
    }, snapshotRows()),
  }

  local main = (narrow or medium)
    and ui.column({ gap = contentGap, width = "100%" }, body)
    or ui.row({ gap = contentGap, width = "100%", align = "stretch" }, body)

  return ui.stack({ width = "100%", height = "100%" }, {
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = false,
      accessibilityHidden = true,
      draw = function(_, x, y, w, h, love)
        local g = love and love.graphics
        if not g then
          return
        end
        g.setColor(0.1, 0.84, 1, 0.035)
        for line = y, y + h, 18 do
          g.rectangle("fill", x, line, w, 1)
        end
      end,
    }),
    ui.scrollView({
      width = "100%",
      height = "100%",
      padding = narrow and 12 or 18,
      gap = contentGap,
    }, {
      ui.textKey("app.title", {
        style = { color = { 0.1, 0.84, 1, 1 } },
      }),
      ui.textKey("app.subtitle", {
        width = narrow and nil or 680,
        wrap = true,
        style = { color = ui.theme.mutedTextColor },
      }),
      main,
      ui.textKey("decorative", {
        accessibilityHidden = true,
        style = { color = { 0.1, 0.84, 1, 0.35 } },
      }),
    }),
  })
end

return {
  id = "accessibility",
  label = "Accessibility",
  description = "Drive a ship-console UI with keyboard or gamepad while Glyph emits fake screen-reader events, focus changes, and live-region updates.",
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
