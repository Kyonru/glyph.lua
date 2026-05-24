local ui = require("glyph")

local activeTab = 1
local themeName = "dark"
local shader = nil
local shaderEnabled = false

local themes = {
  dark = {
    backgroundColor = { 0.045, 0.05, 0.06, 1 },
    surfaceColor = { 0.105, 0.12, 0.145, 1 },
    surfaceHoverColor = { 0.15, 0.18, 0.215, 1 },
    surfacePressedColor = { 0.075, 0.09, 0.11, 1 },
    borderColor = { 0.26, 0.32, 0.38, 1 },
    textColor = { 0.9, 0.93, 0.96, 1 },
    mutedTextColor = { 0.52, 0.58, 0.65, 1 },
    accentColor = { 0.08, 0.68, 0.58, 1 },
    components = {
      button = {
        variants = {
          danger = {
            background = { 0.62, 0.12, 0.16, 1 },
            color = { 1, 1, 1, 1 },
            hover = { background = { 0.76, 0.16, 0.2, 1 } },
            pressed = { background = { 0.44, 0.08, 0.1, 1 } },
          },
          ghost = {
            background = { 0, 0, 0, 0 },
            borderColor = { 0.36, 0.42, 0.5, 1 },
            color = { 0.78, 0.86, 0.92, 1 },
            hover = { background = { 0.18, 0.22, 0.27, 0.75 } },
          },
        },
      },
    },
  },
  light = {
    backgroundColor = { 0.93, 0.94, 0.94, 1 },
    surfaceColor = { 0.98, 0.985, 0.98, 1 },
    surfaceHoverColor = { 0.88, 0.92, 0.94, 1 },
    surfacePressedColor = { 0.78, 0.84, 0.86, 1 },
    borderColor = { 0.58, 0.64, 0.68, 1 },
    textColor = { 0.08, 0.1, 0.12, 1 },
    mutedTextColor = { 0.36, 0.42, 0.48, 1 },
    accentColor = { 0.0, 0.43, 0.78, 1 },
  },
}

local softCard = ui.style({
  background = { 0.14, 0.16, 0.2, 0.86 },
  borderColor = { 0.38, 0.45, 0.54, 1 },
  borderWidth = 2,
  radius = 6,
  opacity = 0.96,
})

local accentButton = ui.style({
  borderWidth = 2,
  radius = 6,
  transition = {
    background = 0.14,
    color = 0.12,
  },
})

local function applyTheme(name)
  themeName = name
  ui.setTheme(themes[name])
end

local function setup()
  applyTheme(themeName)

  if love.graphics and love.graphics.newShader then
    shader = love.graphics.newShader([[
      extern number time;

      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        number glow = 0.08 * sin(time + screen_coords.x * 0.035);
        return vec4(color.rgb + glow, color.a);
      }
    ]])
  end
end

local function shaderStyle()
  if shader and shaderEnabled then
    shader:send("time", love.timer.getTime() * 5)
    return shader
  end

  return nil
end

local function swatch(label, color)
  return ui.row({ gap = 8, align = "center" }, {
    ui.box({
      width = 28,
      height = 18,
      style = {
        background = color,
        borderColor = ui.theme.borderColor,
        borderWidth = 1,
        radius = 3,
      },
    }),
    ui.text(label),
  })
end

local function App()
  return ui.column({
    gap = 12,
    padding = 14,
    width = 620,
    style = {
      background = ui.theme.backgroundColor,
    },
  }, {
    ui.panel({
      title = "Style Lab",
      padding = 12,
      gap = 10,
      style = softCard,
    }, {
      ui.row({ gap = 8, align = "center" }, {
        ui.button({
          label = "Dark",
          variant = themeName == "dark" and "primary" or "ghost",
          onClick = function() applyTheme("dark") end,
          style = accentButton,
        }),
        ui.button({
          label = "Light",
          variant = themeName == "light" and "primary" or "ghost",
          onClick = function() applyTheme("light") end,
          style = accentButton,
        }),
        ui.button({
          label = shaderEnabled and "Shader on" or "Shader off",
          variant = shaderEnabled and "primary" or nil,
          onClick = function()
            shaderEnabled = not shaderEnabled
          end,
          style = ui.composeStyles(accentButton, {
            shader = shaderStyle,
          }),
        }),
        ui.button({
          label = "Danger",
          variant = "danger",
          style = accentButton,
        }),
      }),

      ui.tabs({
        active = activeTab,
        onChange = function(index)
          activeTab = index
        end,
        tabStyle = {
          borderWidth = 2,
          radius = 5,
          active = {
            borderColor = ui.theme.accentColor,
          },
        },
      }, {
        {
          label = "Palette",
          content = ui.column({ gap = 8, padding = { y = 8 } }, {
            swatch("background", ui.theme.backgroundColor),
            swatch("surface", ui.theme.surfaceColor),
            swatch("accent", ui.theme.accentColor),
            swatch("border", ui.theme.borderColor),
          }),
        },
        {
          label = "Custom Draw",
          content = ui.box({
            width = 520,
            height = 104,
            style = {
              background = { 0.05, 0.08, 0.09, 1 },
              borderColor = ui.theme.accentColor,
              borderWidth = 3,
              radius = 8,
              shader = shaderStyle,
            },
            draw = function(_, x, y, width, height, loveModule, style)
              loveModule.graphics.setColor(style.background)
              loveModule.graphics.rectangle("fill", x, y, width, height, style.radius, style.radius)
              loveModule.graphics.setColor(style.borderColor)
              loveModule.graphics.setLineWidth(style.borderWidth)
              loveModule.graphics.rectangle("line", x, y, width, height, style.radius, style.radius)
              loveModule.graphics.setColor(style.color or ui.theme.textColor)
              loveModule.graphics.print("Custom draw receives resolved style, including shader and border width.", x + 14, y + 40)
            end,
          }),
        },
        {
          label = "States",
          content = ui.column({ gap = 8, padding = { y = 8 } }, {
            ui.text("Hover and press these buttons to see state styles and transitions."),
            ui.button({
              label = "Inline hover",
              style = {
                background = { 0.16, 0.2, 0.25, 1 },
                borderColor = ui.theme.borderColor,
                borderWidth = 2,
                radius = 6,
                hover = { background = { 0.24, 0.44, 0.56, 1 } },
                pressed = { background = { 0.1, 0.28, 0.36, 1 } },
                transition = { background = 0.16 },
              },
            }),
            ui.button({
              label = "Disabled style",
              disabled = true,
            }),
          }),
        },
      }),
    }),
  })
end

return {
  id = "styles",
  label = "Styles",
  setup = setup,
  component = function()
    return App()
  end,
}
