local ui = require("glyph")

local offFeedback = nil
local offAudio = nil
local offEvents = nil
local sources = {}
local pattern = { 1, 3, 2 }
local inputIndex = 1
local score = 0
local best = 0
local showing = true
local showIndex = 1
local showTimer = 0
local litPad = nil
local padFlashTimer = 0
local paused = false
local status = "Watch the pattern"
local muted = false
local particles = {}
local ripples = {}
local shake = 0
local screenFlash = 0
local pointerX = nil
local pointerY = nil
local pointerFresh = 0

local pads = {
  { label = "Pulse", color = { 0.08, 0.72, 1, 1 }, key = "1" },
  { label = "Bloom", color = { 0.85, 0.24, 1, 1 }, key = "2" },
  { label = "Spark", color = { 1, 0.76, 0.18, 1 }, key = "3" },
  { label = "Leaf", color = { 0.45, 0.95, 0.28, 1 }, key = "4" },
}

local function rgba(color, alpha)
  return { color[1], color[2], color[3], alpha }
end

local function makeTone(frequency, duration, volume)
  if not love or not love.sound or not love.audio then
    return nil
  end

  local sampleRate = 44100
  local sampleCount = math.floor(sampleRate * duration)
  local data = love.sound.newSoundData(sampleCount, sampleRate, 16, 1)
  for index = 0, sampleCount - 1 do
    local t = index / sampleRate
    local fade = math.max(0, 1 - t / duration)
    local sample = math.sin(t * frequency * math.pi * 2) * (volume or 0.2) * fade
    data:setSample(index, sample)
  end
  return love.audio.newSource(data)
end

local function nodeCenter(node)
  local viewport = ui.viewport()
  if pointerX and pointerY and pointerFresh > 0 then
    return pointerX, pointerY
  end
  if node and node.layout then
    return (node.absoluteX or 0) + (node.layout.width or 0) / 2,
      (node.absoluteY or 0) + (node.layout.height or 0) / 2
  end
  return viewport.width / 2, viewport.height / 2
end

local function pushParticle(x, y, color, power)
  local angle = math.random() * math.pi * 2
  local speed = (power or 120) * (0.45 + math.random() * 0.75)
  particles[#particles + 1] = {
    x = x,
    y = y,
    vx = math.cos(angle) * speed,
    vy = math.sin(angle) * speed - 50,
    life = 0.55 + math.random() * 0.28,
    maxLife = 0.75,
    size = 3 + math.random() * 7,
    color = color,
  }
end

local function burst(node, color, count, power)
  local x, y = nodeCenter(node)
  for _ = 1, count or 16 do
    pushParticle(x, y, color, power)
  end
  ripples[#ripples + 1] = {
    x = x,
    y = y,
    life = 0.34,
    maxLife = 0.34,
    radius = 18,
    color = color,
  }
end

local function resetGame()
  pattern = { 1, 3, 2 }
  inputIndex = 1
  score = 0
  showing = true
  showIndex = 1
  showTimer = 0
  litPad = nil
  padFlashTimer = 0
  paused = false
  status = "Watch the pattern"
  screenFlash = 0
end

local function addStep()
  pattern[#pattern + 1] = love and love.math and love.math.random(1, #pads) or math.random(1, #pads)
end

local function beginPlayback()
  showing = true
  showIndex = 1
  showTimer = 0
  litPad = nil
  padFlashTimer = 0
  inputIndex = 1
  status = "Watch the pattern"
end

local function setup()
  math.randomseed(18)
  sources = {
    ["pattern-hit"] = makeTone(920, 0.075, 0.24),
    ["pattern-miss"] = makeTone(180, 0.18, 0.28),
    ["pattern-ui"] = makeTone(520, 0.06, 0.18),
  }

  ui.setTheme({
    backgroundColor = { 0.025, 0.03, 0.045, 1 },
    surfaceColor = { 0.055, 0.065, 0.09, 1 },
    textColor = { 0.96, 0.98, 1, 1 },
    mutedTextColor = { 0.62, 0.7, 0.82, 1 },
    accentColor = { 0.78, 0.25, 1, 1 },
    radius = 10,
    components = {
      button = {
        background = { 0.085, 0.095, 0.13, 0.96 },
        color = { 1, 1, 1, 1 },
        borderColor = { 1, 1, 1, 0.16 },
        borderWidth = 1,
        radius = 10,
        hover = { background = { 0.13, 0.12, 0.18, 1 }, borderColor = { 1, 1, 1, 0.32 } },
        pressed = { background = { 0.2, 0.14, 0.28, 1 }, borderColor = { 1, 1, 1, 0.5 } },
        focused = { borderColor = { 1, 0.88, 0.22, 1 }, borderWidth = 3 },
        active = { borderColor = { 1, 1, 1, 0.85 }, borderWidth = 3 },
        disabled = { opacity = 0.5 },
      },
      panel = {
        background = { 0.045, 0.055, 0.08, 0.92 },
        borderColor = { 1, 1, 1, 0.12 },
        borderWidth = 1,
        radius = 12,
      },
    },
  })

  ui.feedback.clear()
  ui.feedback.define("pad.press", {
    { kind = "animate", duration = 0.05, to = { scaleX = 1.04, scaleY = 0.94, y = 2 }, ease = "quadout" },
  })
  ui.feedback.define("pad.release", {
    { kind = "animate", duration = 0.14, to = { scaleX = 1, scaleY = 1, y = 0 }, ease = "backout" },
  })
  ui.feedback.define("pad.hit", {
    { kind = "audio", cue = "pattern-hit" },
    { kind = "emit", event = "flash", payload = { color = { 1, 1, 1, 1 } } },
    { kind = "animate", duration = 0.09, to = { scale = 1.08 }, ease = "quadout" },
    { kind = "animate", duration = 0.16, to = { scale = 1 }, ease = "backout" },
  })
  ui.feedback.define("pad.miss", {
    { kind = "audio", cue = "pattern-miss" },
    { kind = "emit", event = "shake", payload = { amount = 7 } },
    { kind = "animate", duration = 0.05, to = { x = -7 }, ease = "quadout" },
    { kind = "animate", duration = 0.07, to = { x = 7 }, ease = "quadout" },
    { kind = "animate", duration = 0.14, to = { x = 0 }, ease = "backout" },
  })

  if offFeedback then
    offFeedback()
  end
  offFeedback = ui.on("feedback", function(event)
    if event.kind == "shake" then
      status = "Missed it. Try again."
      shake = math.max(shake, event.payload and event.payload.amount or 6)
    elseif event.kind == "flash" then
      status = event.trigger == "activate" and "Good hit" or status
      burst(event.node, event.payload and event.payload.color or { 1, 1, 1, 1 }, 8, 80)
    end
  end)

  if offAudio then
    offAudio()
  end
  offAudio = ui.on("audio", function(event)
    if muted then
      return
    end

    local source = sources[event.cue] or sources["pattern-ui"]
    if source then
      source:stop()
      source:play()
    end
  end)

  if offEvents then
    offEvents()
  end
  offEvents = ui.on("event", function(kind, x, y)
    if kind == "mousemoved" or kind == "mousepressed" or kind == "mousereleased" then
      pointerX = x
      pointerY = y
      pointerFresh = kind == "mousemoved" and 0.08 or 0.35
    end
  end)

  resetGame()
end

local function teardown()
  if offFeedback then
    offFeedback()
    offFeedback = nil
  end
  if offAudio then
    offAudio()
    offAudio = nil
  end
  if offEvents then
    offEvents()
    offEvents = nil
  end
  ui.feedback.clear()
  sources = {}
  particles = {}
  ripples = {}
  shake = 0
  pointerX = nil
  pointerY = nil
  pointerFresh = 0
  resetGame()
end

local function update(dt)
  pointerFresh = math.max(0, pointerFresh - dt)

  for index = #particles, 1, -1 do
    local particle = particles[index]
    particle.life = particle.life - dt
    particle.x = particle.x + particle.vx * dt
    particle.y = particle.y + particle.vy * dt
    particle.vy = particle.vy + 230 * dt
    if particle.life <= 0 then
      table.remove(particles, index)
    end
  end

  for index = #ripples, 1, -1 do
    local ripple = ripples[index]
    ripple.life = ripple.life - dt
    ripple.radius = ripple.radius + 150 * dt
    if ripple.life <= 0 then
      table.remove(ripples, index)
    end
  end

  shake = math.max(0, shake - dt * 28)
  screenFlash = math.max(0, screenFlash - dt * 2.6)

  if paused then
    return
  end

  if showing then
    showTimer = showTimer - dt
    if showTimer <= 0 then
      if litPad then
        litPad = nil
        showTimer = 0.16
      elseif showIndex <= #pattern then
        litPad = pattern[showIndex]
        showIndex = showIndex + 1
        showTimer = 0.42
      else
        showing = false
        inputIndex = 1
        litPad = nil
        status = "Repeat it"
      end
    end
  elseif litPad then
    padFlashTimer = padFlashTimer - dt
    if padFlashTimer <= 0 then
      litPad = nil
    end
  end
end

local function handlePad(index, node)
  if paused or showing then
    return
  end

  litPad = index
  padFlashTimer = 0.18
  if pattern[inputIndex] == index then
    ui.feedback.play("pad.hit", node, { trigger = "activate" })
    burst(node, pads[index].color, 18, 140)
    inputIndex = inputIndex + 1
    if inputIndex > #pattern then
      score = score + 1
      best = math.max(best, score)
      screenFlash = 0.36
      addStep()
      beginPlayback()
      status = "Round clear. Watch again."
    else
      status = "Good. Keep going."
    end
  else
    ui.feedback.play("pad.miss", node, { trigger = "error" })
    burst(node, { 1, 0.18, 0.28, 1 }, 24, 180)
    score = 0
    beginPlayback()
    status = "Missed it. Watch again."
  end
end

local function drawBackdrop(_, x, y, width, height, love, _, ctx)
  local g = love.graphics
  g.setColor(0.018, 0.022, 0.035, 1)
  g.rectangle("fill", x, y, width, height)

  g.setColor(0.78, 0.25, 1, 0.06)
  g.circle("fill", x + width * 0.2, y + height * 0.18, width * 0.24 + ctx:pulse(0.7) * 18)
  g.setColor(0.08, 0.72, 1, 0.045)
  g.circle("fill", x + width * 0.82, y + height * 0.82, width * 0.28 + ctx:pulse(0.9, 1) * 20)

  g.setColor(1, 1, 1, 0.035)
  for line = y + 26, y + height, 34 do
    g.rectangle("fill", x, line + math.sin(ctx.time * 1.2 + line) * 4, width, 1)
  end
  for col = x + 26, x + width, 48 do
    g.rectangle("fill", col + math.sin(ctx.time + col) * 3, y, 1, height)
  end
end

local function drawFx(_, _, _, _, _, love)
  local g = love.graphics
  for _, ripple in ipairs(ripples) do
    local alpha = math.max(0, ripple.life / ripple.maxLife)
    local color = ripple.color
    g.setColor(color[1], color[2], color[3], alpha * 0.46)
    g.setLineWidth(2)
    g.circle("line", ripple.x, ripple.y, ripple.radius)
    g.setLineWidth(1)
  end

  for _, particle in ipairs(particles) do
    local alpha = math.max(0, particle.life / particle.maxLife)
    local color = particle.color
    g.setColor(color[1], color[2], color[3], alpha)
    g.circle("fill", particle.x, particle.y, particle.size * alpha)
  end

  if screenFlash > 0 then
    g.setColor(1, 1, 1, screenFlash * 0.16)
    local viewport = ui.viewport()
    g.rectangle("fill", 0, 0, viewport.width, viewport.height)
  end
end

local function metric(label, value, color)
  color = color or { 1, 1, 1, 1 }
  return ui.panel({
    gap = 5,
    padding = 10,
    flex = 1,
    style = {
      background = rgba(color, 0.12),
      borderColor = rgba(color, 0.38),
      borderWidth = 1,
      radius = 10,
    },
  }, {
    ui.text(label, { style = { color = ui.theme.mutedTextColor } }),
    ui.text(value, { style = { color = color } }),
  })
end

local function sequenceReadout()
  local rows = {}
  local maxVisible = 10
  for index = 1, math.min(#pattern, maxVisible) do
    local pad = pads[pattern[index]]
    local current = showing and showIndex - 1 == index or (not showing and inputIndex == index)
    rows[#rows + 1] = ui.box({
      width = 18,
      height = 18,
      style = {
        background = current and rgba(pad.color, 0.95) or rgba(pad.color, 0.28),
        borderColor = current and { 1, 1, 1, 0.95 } or rgba(pad.color, 0.5),
        borderWidth = current and 2 or 1,
        radius = 9,
      },
      interactive = false,
      accessibilityHidden = true,
    })
  end
  if #pattern > maxVisible then
    rows[#rows + 1] = ui.text("+" .. tostring(#pattern - maxVisible), {
      style = { color = ui.theme.mutedTextColor },
    })
  end
  return ui.row({ gap = 6, width = "100%", align = "center" }, rows)
end

local function ruleText(text, accent)
  return ui.row({ gap = 8, width = "100%" }, {
    ui.box({
      width = 8,
      height = 8,
      style = { background = accent, radius = 4 },
      interactive = false,
      accessibilityHidden = true,
    }),
    ui.text(text, {
      wrap = true,
      width = "100%",
      flex = 1,
      style = { color = ui.theme.mutedTextColor },
    }),
  })
end

local function padButton(index)
  local pad = pads[index]
  local active = litPad == index
  return ui.button({
    label = pad.label .. "\n" .. pad.key,
    width = "100%",
    height = 126,
    navGroup = "pattern",
    active = active,
    disabled = paused or showing,
    feedback = {
      press = "pad.press",
      release = "pad.release",
      activate = false,
    },
    style = {
      background = active and rgba(pad.color, 0.82) or rgba(pad.color, 0.2),
      color = { 1, 1, 1, 1 },
      borderColor = active and { 1, 1, 1, 0.92 } or rgba(pad.color, 0.5),
      borderWidth = active and 3 or 1,
      radius = 12,
      hover = { background = rgba(pad.color, 0.36), borderColor = rgba(pad.color, 0.85) },
      pressed = { background = rgba(pad.color, 0.72), borderColor = { 1, 1, 1, 0.9 } },
      focused = { borderColor = { 1, 0.88, 0.22, 1 }, borderWidth = 3 },
      disabled = { opacity = showing and 0.72 or 0.48 },
    },
    onClick = function(node)
      handlePad(index, node)
    end,
  })
end

local function patternPreview()
  local dots = {}
  for index, value in ipairs(pattern) do
    local color = pads[value].color
    dots[#dots + 1] = ui.box({
      width = 22,
      height = 22,
      style = {
        background = index < inputIndex and rgba(color, 0.9) or rgba(color, 0.36),
        borderColor = litPad == value and { 1, 1, 1, 0.9 } or rgba(color, 0.55),
        borderWidth = litPad == value and 2 or 1,
        radius = 11,
      },
      interactive = false,
      accessibilityHidden = true,
    })
  end
  return ui.row({ gap = 7, width = "100%" }, dots)
end

local function controls()
  return ui.row({ gap = 10, width = "100%" }, {
    ui.button({
      label = showing and "Playing..." or "Replay",
      flex = 1,
      navGroup = "pattern",
      disabled = paused,
      feedback = { press = "pad.press", release = "pad.release", activate = "pad.hit" },
      onClick = beginPlayback,
    }),
    ui.button({
      label = paused and "Resume" or "Pause",
      flex = 1,
      navGroup = "pattern",
      feedback = { press = "pad.press", release = "pad.release", activate = "pad.hit" },
      onClick = function()
        paused = not paused
      end,
    }),
    ui.button({
      label = muted and "Audio Off" or "Audio On",
      flex = 1,
      navGroup = "pattern",
      feedback = { press = "pad.press", release = "pad.release", activate = "pad.hit" },
      onClick = function()
        muted = not muted
      end,
    }),
  })
end

local function gamePanel(compact)
  local grid = compact
      and ui.column({ gap = 10, width = "100%" }, {
        padButton(1),
        padButton(2),
        padButton(3),
        padButton(4),
      })
    or ui.column({ gap = 12, width = "100%" }, {
      ui.row({ gap = 12, width = "100%" }, { padButton(1), padButton(2) }),
      ui.row({ gap = 12, width = "100%" }, { padButton(3), padButton(4) }),
    })

  return ui.panel({ title = "Pattern Repeat", gap = 12, padding = compact and 12 or 16, flex = 1 }, {
    ui.row({ gap = 10, width = "100%", align = "center" }, {
      ui.text(showing and "Playback" or "Your turn", {
        style = { color = showing and { 0.08, 0.72, 1, 1 } or { 1, 0.86, 0.24, 1 } },
      }),
      ui.box({ grow = 1, height = 1, interactive = false }),
      ui.text("Round " .. tostring(score + 1), { style = { color = ui.theme.mutedTextColor } }),
    }),
    grid,
    patternPreview(),
    controls(),
  })
end

local function sidePanel(compact)
  return ui.column({ gap = 12, width = compact and "100%" or 270, height = compact and nil or "100%" }, {
    ui.panel({ title = "Run Stats", gap = 12, padding = 14, width = "100%" }, {
      ui.text(showing and "Playback scanner armed" or "Input window open", {
        style = { color = showing and { 0.08, 0.72, 1, 1 } or { 1, 0.86, 0.24, 1 } },
      }),
      ui.row({ gap = 10, width = "100%" }, {
        metric("Score", tostring(score), { 0.78, 0.25, 1, 1 }),
        metric("Best", tostring(best), { 1, 0.76, 0.18, 1 }),
      }),
      ui.row({ gap = 10, width = "100%" }, {
        metric("Length", tostring(#pattern), { 0.08, 0.72, 1, 1 }),
        metric("Step", tostring(math.min(inputIndex, #pattern)) .. "/" .. tostring(#pattern), { 0.45, 0.95, 0.28, 1 }),
      }),
      ui.meter({
        value = math.min(inputIndex - 1, #pattern),
        max = math.max(1, #pattern),
        height = 12,
        width = "100%",
        fillStyle = { background = { 0.78, 0.25, 1, 1 } },
        trackStyle = { background = { 1, 1, 1, 0.1 } },
      }),
      sequenceReadout(),
      ui.text(status, { wrap = true, style = { color = { 1, 0.86, 0.24, 1 } } }),
    }),
    ui.panel({ title = "Rules And Tips", gap = 10, padding = 14, flex = compact and nil or 1, width = "100%" }, {
      ui.text("Repeat the glowing sequence exactly. Each clear round adds one more pad, so the pressure rises while the controls stay simple.", {
        wrap = true,
        width = "100%",
        style = { color = { 0.9, 0.94, 1, 1 } },
      }),
      ruleText("Mouse clicks spawn particles at the cursor. Keyboard and gamepad activations fall back to the focused button center.", { 0.08, 0.72, 1, 1 }),
      ruleText("Use 1-4 for direct pad input, arrows or d-pad to move focus, and Return, Space, or gamepad A to activate.", { 0.78, 0.25, 1, 1 }),
      ruleText("Escape opens the pause menu. The menu traps navigation so you can resume, restart, or toggle audio without losing the current run.", { 1, 0.76, 0.18, 1 }),
    }),
  })
end

local function pauseMenu()
  if not paused then
    return nil
  end

  return ui.stack({ position = "absolute", inset = 0, zIndex = 10 }, {
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = true,
      style = { background = { 0, 0, 0, 0.58 } },
    }),
    ui.column({
      position = "absolute",
      inset = 0,
      align = "center",
      justify = "center",
    }, {
      ui.panel({
        width = 320,
        title = "Paused",
        gap = 10,
        padding = 18,
        navScope = true,
        navTrap = true,
      }, {
        ui.text("Take a breather. The current pattern is waiting.", {
          wrap = true,
          width = "100%",
          style = { color = ui.theme.mutedTextColor },
        }),
        ui.button({
          label = "Resume",
          width = "100%",
          navGroup = "pause",
          feedback = { press = "pad.press", release = "pad.release", activate = "pad.hit" },
          onClick = function()
            paused = false
          end,
        }),
        ui.button({
          label = "Restart",
          width = "100%",
          navGroup = "pause",
          feedback = { press = "pad.press", release = "pad.release", activate = "pad.hit" },
          onClick = resetGame,
        }),
        ui.button({
          label = muted and "Audio Off" or "Audio On",
          width = "100%",
          navGroup = "pause",
          feedback = { press = "pad.press", release = "pad.release", activate = "pad.hit" },
          onClick = function()
            muted = not muted
          end,
        }),
      }),
    }),
  })
end

local function App()
  local viewport = ui.viewport()
  local compact = viewport.width < 760
  local shakeX = shake > 0 and math.sin(ui.time() * 70) * shake or 0
  local shakeY = shake > 0 and math.cos(ui.time() * 58) * shake * 0.45 or 0
  local content = compact
      and ui.column({ gap = 14, width = "100%" }, {
        gamePanel(true),
        sidePanel(true),
      })
    or ui.row({ gap = 14, width = "100%", align = "stretch" }, {
      gamePanel(false),
      sidePanel(false),
    })

  return ui.stack({ width = "100%", height = "100%" }, {
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = false,
      accessibilityHidden = true,
      draw = drawBackdrop,
    }),
    ui.stack({ x = shakeX, y = shakeY, width = "100%", height = "100%" }, {
      ui.scrollView({ width = "100%", height = "100%", padding = compact and 12 or 22 }, {
        ui.column({ gap = 14, width = "100%" }, {
          ui.row({ gap = 10, width = "100%", align = "center" }, {
            ui.text("Juice Lab", { style = { color = { 0.78, 0.25, 1, 1 } } }),
            ui.box({ grow = 1, height = 1, interactive = false }),
            ui.text(status, { style = { color = { 1, 0.86, 0.24, 1 } } }),
          }),
          content,
        }),
      }),
    }),
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = false,
      accessibilityHidden = true,
      draw = drawFx,
    }),
    pauseMenu(),
  })
end

return {
  id = "juice",
  label = "Juice",
  setup = setup,
  teardown = teardown,
  update = update,
  window = {
    width = 840,
    height = 620,
    resizable = true,
    title = "glyph - juice",
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
    elseif key == "escape" then
      paused = not paused
      return true
    elseif key == "1" or key == "2" or key == "3" or key == "4" then
      local index = tonumber(key)
      if index then
        handlePad(index)
      end
      return true
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
