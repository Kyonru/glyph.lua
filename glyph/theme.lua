local theme = {
  version = 0,
  font = nil,
  textColor = { 0.9, 0.92, 0.95, 1 },
  mutedTextColor = { 0.58, 0.62, 0.68, 1 },
  backgroundColor = { 0.08, 0.09, 0.11, 1 },
  surfaceColor = { 0.13, 0.15, 0.18, 1 },
  surfaceHoverColor = { 0.18, 0.21, 0.25, 1 },
  surfacePressedColor = { 0.1, 0.12, 0.15, 1 },
  borderColor = { 0.28, 0.32, 0.38, 1 },
  accentColor = { 0.24, 0.54, 0.95, 1 },
  accentTextColor = { 1, 1, 1, 1 },
  disabledColor = { 0.18, 0.19, 0.21, 1 },
  inputColor = { 0.08, 0.09, 0.11, 1 },
  scrollbarColor = { 0.34, 0.38, 0.45, 0.85 },
  fontSize = 13,
  lineHeight = 18,
  textScale = 1,
  radius = 4,
  borderWidth = 1,
  inputCursorWidth = 1,
  tabHeight = 28,
  scrollbarWidth = 6,
}

theme.fonts = {
  body = nil,
  heading = nil,
  mono = nil,
}

theme.typography = {
  text = {
    font = "body",
    fontSize = theme.fontSize,
    lineHeight = theme.lineHeight,
  },
  h1 = {
    font = "heading",
    fontSize = 30,
    lineHeight = 36,
  },
  h2 = {
    font = "heading",
    fontSize = 22,
    lineHeight = 28,
  },
  paragraph = {
    font = "body",
    fontSize = theme.fontSize,
    lineHeight = 20,
  },
  caption = {
    font = "body",
    fontSize = 11,
    lineHeight = 15,
  },
  code = {
    font = "mono",
    fontSize = 12,
    lineHeight = 17,
  },
  button = {
    font = "body",
    fontSize = theme.fontSize,
    lineHeight = theme.lineHeight,
  },
  input = {
    font = "body",
    fontSize = theme.fontSize,
    lineHeight = theme.lineHeight,
  },
}

theme.base = {
  color = theme.textColor,
  borderWidth = theme.borderWidth,
  radius = theme.radius,
  opacity = 1,
}

theme.components = {
  text = {
    color = theme.textColor,
  },
  box = {},
  path = {},
  row = {},
  column = {},
  grid = {},
  portal = {},
  scrollView = {},
  scrollBar = {
    width = theme.scrollbarWidth,
    padding = 3,
    minThumbSize = 24,
    radius = 3,
    trackColor = { 0, 0, 0, 0 },
    thumbColor = theme.scrollbarColor,
  },
  panel = {
    background = theme.surfaceColor,
    borderColor = theme.borderColor,
    borderWidth = theme.borderWidth,
    radius = theme.radius,
  },
  button = {
    background = theme.surfaceColor,
    color = theme.textColor,
    borderColor = theme.borderColor,
    borderWidth = theme.borderWidth,
    radius = theme.radius,
    hover = {
      background = theme.surfaceHoverColor,
    },
    pressed = {
      background = theme.surfacePressedColor,
    },
    disabled = {
      background = theme.disabledColor,
      color = theme.mutedTextColor,
    },
    variants = {
      primary = {
        background = theme.accentColor,
        color = theme.accentTextColor,
        hover = {
          background = { 0.3, 0.62, 1, 1 },
        },
        pressed = {
          background = { 0.16, 0.42, 0.78, 1 },
        },
      },
    },
  },
  input = {
    background = theme.inputColor,
    color = theme.textColor,
    placeholderColor = theme.mutedTextColor,
    borderColor = theme.borderColor,
    borderWidth = theme.borderWidth,
    radius = theme.radius,
    focused = {
      borderColor = theme.accentColor,
    },
  },
  tabs = {},
  tab = {
    background = theme.surfaceColor,
    color = theme.textColor,
    borderColor = theme.borderColor,
    active = {
      background = theme.accentColor,
      color = theme.accentTextColor,
    },
    hover = {
      background = theme.surfaceHoverColor,
    },
    pressed = {
      background = theme.surfacePressedColor,
    },
  },
}

local function copyColor(color)
  if type(color) ~= "table" then
    return color
  end

  local copy = {}
  for key, value in pairs(color) do
    copy[key] = copyColor(value)
  end
  return copy
end

local function mergeInto(target, source)
  for key, value in pairs(source or {}) do
    if type(value) == "table" and type(target[key]) == "table" and value[1] == nil then
      mergeInto(target[key], value)
    else
      target[key] = copyColor(value)
    end
  end
end

local function syncDerivedDefaults(nextTheme)
  local typographyOverrides = nextTheme and nextTheme.typography or nil

  local function syncTypography(name)
    theme.typography[name] = theme.typography[name] or {}
    local override = type(typographyOverrides) == "table" and typographyOverrides[name] or nil
    if not (type(override) == "table" and override.fontSize ~= nil) then
      theme.typography[name].fontSize = theme.fontSize
    end
    if not (type(override) == "table" and override.lineHeight ~= nil) then
      theme.typography[name].lineHeight = theme.lineHeight
    end
  end

  theme.base.color = theme.textColor
  theme.base.borderWidth = theme.borderWidth
  theme.base.radius = theme.radius

  theme.components.text.color = theme.textColor
  theme.components.panel.background = theme.surfaceColor
  theme.components.panel.borderColor = theme.borderColor
  theme.components.panel.borderWidth = theme.borderWidth
  theme.components.panel.radius = theme.radius

  theme.components.button.background = theme.surfaceColor
  theme.components.button.color = theme.textColor
  theme.components.button.borderColor = theme.borderColor
  theme.components.button.borderWidth = theme.borderWidth
  theme.components.button.radius = theme.radius
  theme.components.button.hover.background = theme.surfaceHoverColor
  theme.components.button.pressed.background = theme.surfacePressedColor
  theme.components.button.disabled.background = theme.disabledColor
  theme.components.button.disabled.color = theme.mutedTextColor
  theme.components.button.variants.primary.background = theme.accentColor
  theme.components.button.variants.primary.color = theme.accentTextColor

  theme.components.input.background = theme.inputColor
  theme.components.input.color = theme.textColor
  theme.components.input.placeholderColor = theme.mutedTextColor
  theme.components.input.borderColor = theme.borderColor
  theme.components.input.borderWidth = theme.borderWidth
  theme.components.input.radius = theme.radius
  theme.components.input.focused.borderColor = theme.accentColor

  theme.components.tab.background = theme.surfaceColor
  theme.components.tab.color = theme.textColor
  theme.components.tab.borderColor = theme.borderColor
  theme.components.tab.active.background = theme.accentColor
  theme.components.tab.active.color = theme.accentTextColor
  theme.components.tab.hover.background = theme.surfaceHoverColor
  theme.components.tab.pressed.background = theme.surfacePressedColor
  theme.components.scrollBar.width = theme.scrollbarWidth
  theme.components.scrollBar.thumbColor = theme.scrollbarColor

  if nextTheme and (nextTheme.fontSize ~= nil or nextTheme.lineHeight ~= nil) then
    syncTypography("text")
    syncTypography("button")
    syncTypography("input")
  end
end

function theme.merge(nextTheme)
  local componentOverrides = nextTheme and nextTheme.components or nil
  local hasTopLevelOverrides = false

  if nextTheme then
    local topLevel = {}
    for key, value in pairs(nextTheme) do
      if key ~= "components" then
        topLevel[key] = value
        hasTopLevelOverrides = true
      end
    end

    mergeInto(theme, topLevel)
  end

  if hasTopLevelOverrides then
    syncDerivedDefaults(nextTheme)
  end

  if componentOverrides then
    mergeInto(theme.components, componentOverrides)
  end

  theme.version = (theme.version or 0) + 1
end

return theme
