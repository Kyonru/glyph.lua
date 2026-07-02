local ui = require("glyph")

local offAudio = nil
local sources = {}
local log = {}
local muted = false

local function pushLog(text)
  table.insert(log, 1, text)
  while #log > 8 do
    table.remove(log)
  end
end

local function makeTone(frequency, duration)
  if not love or not love.sound or not love.audio then
    return nil
  end

  local sampleRate = 44100
  local sampleCount = math.floor(sampleRate * duration)
  local data = love.sound.newSoundData(sampleCount, sampleRate, 16, 1)
  for index = 0, sampleCount - 1 do
    local t = index / sampleRate
    local fade = math.max(0, 1 - t / duration)
    data:setSample(index, math.sin(t * frequency * math.pi * 2) * 0.22 * fade)
  end
  return love.audio.newSource(data)
end

local function setup()
  sources = {
    hover = makeTone(720, 0.045),
    press = makeTone(360, 0.055),
    activate = makeTone(960, 0.08),
    focus = makeTone(520, 0.06),
    danger = makeTone(260, 0.16),
  }

  ui.setTheme({
    backgroundColor = { 0.045, 0.052, 0.068, 1 },
    surfaceColor = { 0.095, 0.11, 0.14, 1 },
    surfaceHoverColor = { 0.14, 0.18, 0.22, 1 },
    surfacePressedColor = { 0.06, 0.075, 0.1, 1 },
    accentColor = { 0.2, 0.68, 0.95, 1 },
    components = {
      button = {
        focused = {
          borderColor = { 0.2, 0.68, 0.95, 1 },
          borderWidth = 2,
        },
        audio = {
          hover = "hover",
          press = "press",
          activate = "activate",
          focus = "focus",
        },
        variants = {
          danger = {
            background = { 0.6, 0.14, 0.16, 1 },
            color = { 1, 1, 1, 1 },
            hover = { background = { 0.76, 0.2, 0.22, 1 } },
            pressed = { background = { 0.42, 0.08, 0.1, 1 } },
            audio = {
              activate = "danger",
            },
          },
          ghost = {
            background = { 0, 0, 0, 0 },
            borderColor = { 1, 1, 1, 0.18 },
            hover = { background = { 1, 1, 1, 0.06 } },
          },
        },
      },
    },
  })

  if offAudio then
    offAudio()
  end

  offAudio = ui.on("audio", function(event)
    pushLog(string.format("%s -> %s (%s)", event.kind, event.cue, event.label or event.type))
    if muted then
      return
    end

    local source = sources[event.cue]
    if source then
      source:stop()
      source:play()
    end
  end)
end

local function teardown()
  if offAudio then
    offAudio()
    offAudio = nil
  end
  sources = {}
  log = {}
end

local function App()
  local rows = {}
  for index, entry in ipairs(log) do
    rows[#rows + 1] = ui.text(entry, {
      width = 360,
      style = { color = index == 1 and ui.theme.textColor or ui.theme.mutedTextColor },
    })
  end
  if #rows == 0 then
    rows[1] = ui.text("Interact with controls to emit audio cue events.", {
      style = { color = ui.theme.mutedTextColor },
    })
  end

  return ui.stack({ width = "100%", height = "100%" }, {
    ui.column({ padding = 20, gap = 12, width = 460 }, {
      ui.row({ gap = 8 }, {
        ui.button({ label = "Default", width = 104, navGroup = "audio-cues", onClick = function() end }),
        ui.button({ label = "Primary", width = 104, variant = "primary", navGroup = "audio-cues", onClick = function() end }),
        ui.button({
          label = "Danger",
          width = 104,
          variant = "danger",
          navGroup = "audio-cues",
          onClick = function()
            pushLog("Danger activated")
          end,
        }),
      }),
      ui.row({ gap = 8 }, {
        ui.button({
          label = "Custom",
          width = 104,
          navGroup = "audio-cues",
          onClick = function() end,
          audio = {
            hover = "focus",
            press = "press",
            activate = "danger",
          },
        }),
        ui.button({
          label = "Silent",
          width = 104,
          variant = "ghost",
          navGroup = "audio-cues",
          audio = false,
        }),
        ui.button({
          label = muted and "Unmute" or "Mute",
          width = 104,
          variant = muted and "ghost" or "primary",
          navGroup = "audio-cues",
          audio = false,
          onClick = function()
            muted = not muted
          end,
        }),
      }),
      ui.panel({ title = "Events", width = 420, gap = 6 }, rows),
    }),
  })
end

return {
  id = "audio-cues",
  label = "Audio Cues",
  description = "Press button variants and watch Glyph emit cue metadata while the app plays tiny Love2D tones.",
  setup = setup,
  teardown = teardown,
  window = {
    width = 760,
    height = 440,
    resizable = true,
    title = "glyph - audio cues",
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
