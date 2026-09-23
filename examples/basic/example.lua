local ui = require("glyph")

local function rule()
  return ui.box({
    width = "100%",
    height = 1,
    interactive = false,
    accessibilityHidden = true,
    style = { background = ui.theme.borderColor },
  })
end

local function App()
  local count, setCount = ui.useState(0)

  return ui.column({
    width = "100%",
    height = "100%",
    padding = { x = 24, y = 22 },
    gap = 14,
  }, {
    ui.text("COUNTER / BASIC STATE", {
      textStyle = "caption",
      style = { color = ui.theme.mutedTextColor },
    }),
    rule(),
    ui.row({ width = "100%", align = "center", gap = 18 }, {
      ui.column({ gap = 4, flex = 1 }, {
        ui.text("Count", {
          style = { color = ui.theme.mutedTextColor },
        }),
        ui.text(string.format("%02d", count), {
          font = "monoDisplay",
          lineHeight = 40,
        }),
      }),
      ui.button({
        label = "Increment",
        variant = "primary",
        width = 126,
        height = 36,
        onClick = function()
          setCount(count + 1)
        end,
      }),
      ui.button({
        label = "Reset",
        width = 88,
        height = 36,
        disabled = count == 0,
        onClick = function()
          setCount(0)
        end,
      }),
    }),
    rule(),
    ui.text("This is the complete state loop: declare state, render it, and update it from a button.", {
      width = "100%",
      wrap = true,
      textStyle = "paragraph",
      style = { color = ui.theme.mutedTextColor },
    }),
    ui.box({ grow = 1, width = "100%", interactive = false }),
    ui.text("ARROWS / DPAD  MOVE FOCUS    ENTER / A  ACTIVATE", {
      width = "100%",
      wrap = true,
      textStyle = "code",
      style = { color = ui.theme.mutedTextColor },
    }),
  })
end

return {
  id = "basic",
  label = "Basic",
  description = "The smallest complete Glyph state and button example.",
  window = {
    width = 640,
    height = 360,
    minWidth = 480,
    minHeight = 280,
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
