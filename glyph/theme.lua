local theme = {
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
  radius = 4,
  borderWidth = 1,
  inputCursorWidth = 1,
  tabHeight = 28,
  scrollbarWidth = 6,
}

local function copyColor(color)
  if type(color) ~= "table" then
    return color
  end

  return { color[1], color[2], color[3], color[4] }
end

function theme.merge(nextTheme)
  for key, value in pairs(nextTheme or {}) do
    if type(value) == "table" then
      theme[key] = copyColor(value)
    else
      theme[key] = value
    end
  end
end

return theme
