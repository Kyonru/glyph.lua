local theme = {
  version = 0,
  font = nil,
  textColor = { 0.93, 0.91, 0.86, 1 },
  mutedTextColor = { 0.66, 0.64, 0.59, 1 },
  backgroundColor = { 0.045, 0.05, 0.052, 1 },
  surfaceColor = { 0.085, 0.095, 0.098, 1 },
  surfaceHoverColor = { 0.14, 0.15, 0.15, 1 },
  surfacePressedColor = { 0.06, 0.065, 0.067, 1 },
  borderColor = { 0.27, 0.28, 0.28, 1 },
  accentColor = { 0.74, 0.45, 0.08, 1 },
  accentHoverColor = { 0.95, 0.68, 0.24, 1 },
  accentPressedColor = { 0.7, 0.42, 0.07, 1 },
  accentTextColor = { 0.07, 0.06, 0.045, 1 },
  disabledColor = { 0.14, 0.145, 0.145, 1 },
  inputColor = { 0.035, 0.04, 0.042, 1 },
  scrollbarColor = { 0.45, 0.44, 0.4, 0.9 },
  fontSize = 13,
  lineHeight = 18,
  textScale = 1,
  fontFilter = "nearest",
  radius = 2,
  borderWidth = 1,
  inputCursorWidth = 1,
  tabHeight = 30,
  scrollbarWidth = 6,
}

theme.fonts = {
  body = nil,
  heading = nil,
  mono = nil,
}
theme.fontFallbacks = {}

theme.typography = {
  text = {
    font = "body",
    fontSize = theme.fontSize,
    lineHeight = theme.lineHeight,
  },
  h1 = {
    font = "heading",
    fontSize = 24,
    lineHeight = 30,
  },
  h2 = {
    font = "heading",
    fontSize = 18,
    lineHeight = 24,
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
    radius = 1,
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
    focused = {
      borderColor = theme.textColor,
      borderWidth = 2,
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
          background = theme.accentHoverColor,
        },
        pressed = {
          background = theme.accentPressedColor,
        },
        focused = {
          borderColor = theme.accentTextColor,
          borderWidth = 2,
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
      borderWidth = 2,
    },
    disabled = {
      background = theme.disabledColor,
      color = theme.mutedTextColor,
      placeholderColor = theme.mutedTextColor,
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
    focused = {
      borderColor = theme.textColor,
      borderWidth = 2,
    },
    disabled = {
      background = theme.disabledColor,
      color = theme.mutedTextColor,
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

local function mixColor(color, target, amount)
  if type(color) ~= "table" then
    return color
  end

  return {
    color[1] + (target - color[1]) * amount,
    color[2] + (target - color[2]) * amount,
    color[3] + (target - color[3]) * amount,
    color[4] or 1,
  }
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
  theme.components.button.focused.borderColor = theme.textColor
  theme.components.button.focused.borderWidth = 2
  theme.components.button.disabled.background = theme.disabledColor
  theme.components.button.disabled.color = theme.mutedTextColor
  theme.components.button.variants.primary.background = theme.accentColor
  theme.components.button.variants.primary.color = theme.accentTextColor
  theme.components.button.variants.primary.hover.background = theme.accentHoverColor
  theme.components.button.variants.primary.pressed.background = theme.accentPressedColor
  theme.components.button.variants.primary.focused.borderColor = theme.accentTextColor
  theme.components.button.variants.primary.focused.borderWidth = 2

  theme.components.input.background = theme.inputColor
  theme.components.input.color = theme.textColor
  theme.components.input.placeholderColor = theme.mutedTextColor
  theme.components.input.borderColor = theme.borderColor
  theme.components.input.borderWidth = theme.borderWidth
  theme.components.input.radius = theme.radius
  theme.components.input.focused.borderColor = theme.accentColor
  theme.components.input.focused.borderWidth = 2
  theme.components.input.disabled.background = theme.disabledColor
  theme.components.input.disabled.color = theme.mutedTextColor
  theme.components.input.disabled.placeholderColor = theme.mutedTextColor

  theme.components.tab.background = theme.surfaceColor
  theme.components.tab.color = theme.textColor
  theme.components.tab.borderColor = theme.borderColor
  theme.components.tab.active.background = theme.accentColor
  theme.components.tab.active.color = theme.accentTextColor
  theme.components.tab.hover.background = theme.surfaceHoverColor
  theme.components.tab.pressed.background = theme.surfacePressedColor
  theme.components.tab.focused.borderColor = theme.textColor
  theme.components.tab.focused.borderWidth = 2
  theme.components.tab.disabled.background = theme.disabledColor
  theme.components.tab.disabled.color = theme.mutedTextColor
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

    if nextTheme.accentColor ~= nil then
      if nextTheme.accentHoverColor == nil then
        theme.accentHoverColor = mixColor(theme.accentColor, 1, 0.2)
      end
      if nextTheme.accentPressedColor == nil then
        theme.accentPressedColor = mixColor(theme.accentColor, 0, 0.2)
      end
    end
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
