local ui = require("glyph")

local BG      = { 0.06, 0.06, 0.10, 1 }
local SURFACE = { 0.11, 0.10, 0.17, 0.99 }
local BORDER  = { 0.42, 0.56, 1.0, 0.18 }
local ACCENT  = { 0.42, 0.56, 1.0, 1 }
local TEXT    = { 0.92, 0.92, 0.96, 1 }
local MUTED   = { 0.52, 0.52, 0.62, 1 }
local GREEN   = { 0.32, 0.88, 0.56, 1 }
local RED     = { 0.95, 0.32, 0.32, 1 }

local exampleTheme = {
  backgroundColor = BG,
  textColor       = TEXT,
  borderColor     = BORDER,
  accentColor     = ACCENT,
  radius          = 10,
}

-- ─── persisted values (written on Save) ──────────────────────────────────────

local saved = {
  masterVol   = 80,
  musicVol    = 60,
  sfxVol      = 90,
  muted       = false,
  quality     = "High",
  fullscreen  = false,
  vsync       = true,
  difficulty  = "Normal",
  autosave    = true,
  hints       = true,
  cameraShake = true,
}

-- ─── primitive controls ───────────────────────────────────────────────────────

local function stepBtn(label, onClick)
  return ui.button({
    label   = label,
    onClick = onClick,
    padding = { top = 5, bottom = 5, left = 13, right = 13 },
    style   = {
      background  = { 0.16, 0.15, 0.24, 1 },
      borderColor = BORDER,
      borderWidth = 1,
      radius      = 6,
      color       = TEXT,
      hover = { background = { 0.22, 0.20, 0.32, 1 } },
    },
  })
end

local function volumeBar(value)
  return ui.box({
    style = {
      width  = 150,
      height = 4,
      radius = 2,
      draw   = function(_, x, y, w, h, love)
        love.graphics.setColor(0.18, 0.18, 0.28, 1)
        love.graphics.rectangle("fill", x, y, w, h, 2)
        local fill = w * (value / 100)
        if fill > 1 then
          love.graphics.setColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.85)
          love.graphics.rectangle("fill", x, y, fill, h, 2)
        end
        love.graphics.setColor(1, 1, 1, 1)
      end,
    },
  })
end

local function toggle(value, setValue)
  return ui.button({
    label   = value and "ON" or "OFF",
    onClick = function() setValue(not value) end,
    padding = { top = 4, bottom = 4, left = 14, right = 14 },
    style   = {
      background  = value and { GREEN[1], GREEN[2], GREEN[3], 0.16 }
                           or { 0.16, 0.15, 0.24, 1 },
      borderColor = value and { GREEN[1], GREEN[2], GREEN[3], 0.50 }
                           or BORDER,
      borderWidth = 1,
      radius      = 20,
      color       = value and { GREEN[1], GREEN[2], GREEN[3], 1 } or MUTED,
    },
  })
end

local function optionBtn(label, active, onClick)
  return ui.button({
    label   = label,
    onClick = onClick,
    padding = { top = 4, bottom = 4, left = 12, right = 12 },
    style   = {
      background  = active and { ACCENT[1], ACCENT[2], ACCENT[3], 0.18 }
                           or  { 0.13, 0.12, 0.20, 1 },
      borderColor = active and { ACCENT[1], ACCENT[2], ACCENT[3], 0.55 }
                           or  BORDER,
      borderWidth = 1,
      radius      = 6,
      color       = active and TEXT or MUTED,
    },
  })
end

-- ─── setting row layouts ──────────────────────────────────────────────────────

local ROW_STYLE = {
  alignItems      = "center",
  justifyContent  = "space-between",
  paddingTop      = 11,
  paddingBottom   = 11,
}

local function volumeRow(label, value, setValue)
  return ui.row({ style = ROW_STYLE }, {
    ui.text(label, { style = { color = TEXT, fontSize = 13 } }),
    ui.row({ style = { alignItems = "center", gap = 10 } }, {
      stepBtn("−", function() setValue(math.max(0, value - 5)) end),
      volumeBar(value),
      stepBtn("+", function() setValue(math.min(100, value + 5)) end),
      ui.text(string.format("%3d%%", value), {
        style = { color = MUTED, fontSize = 12 },
      }),
    }),
  })
end

local function toggleRow(label, sublabel, value, setValue)
  local children = {
    ui.column({ style = { gap = 2 } }, {
      ui.text(label,    { style = { color = TEXT,  fontSize = 13 } }),
      sublabel and ui.text(sublabel, { style = { color = MUTED, fontSize = 11 } }) or ui.box({}),
    }),
    toggle(value, setValue),
  }
  return ui.row({ style = ROW_STYLE }, children)
end

local function selectorRow(label, options, value, setValue)
  local btns = {}
  for _, opt in ipairs(options) do
    btns[#btns + 1] = optionBtn(opt, opt == value, function() setValue(opt) end)
  end
  return ui.row({ style = ROW_STYLE }, {
    ui.text(label, { style = { color = TEXT, fontSize = 13 } }),
    ui.row({ style = { gap = 4 } }, btns),
  })
end

-- ─── section helpers ──────────────────────────────────────────────────────────

local function sep()
  return ui.box({
    style = { height = 1, background = { BORDER[1], BORDER[2], BORDER[3], 0.5 } },
  })
end

local function sectionHeader(label)
  return ui.text(label, {
    style = { color = MUTED, fontSize = 10, marginTop = 18, marginBottom = 4 },
  })
end

-- ─── tab button ───────────────────────────────────────────────────────────────

local function tabBtn(label, active, onClick)
  return ui.button({
    label   = label,
    onClick = onClick,
    padding = { top = 7, bottom = 7, left = 18, right = 18 },
    style   = {
      background  = active and { ACCENT[1], ACCENT[2], ACCENT[3], 0.14 }
                           or  { 0, 0, 0, 0 },
      borderColor = active and { ACCENT[1], ACCENT[2], ACCENT[3], 0.45 }
                           or  { 0, 0, 0, 0 },
      borderWidth = active and 1 or 0,
      radius      = 7,
      color       = active and TEXT or MUTED,
      hover = {
        background = { ACCENT[1], ACCENT[2], ACCENT[3], 0.08 },
        color      = TEXT,
      },
    },
  })
end

-- ─── settings modal ───────────────────────────────────────────────────────────

local MW, MH = 660, 520

local function SettingsModal()
  local tab, setTab = ui.useState("Audio")

  local masterVol,   setMasterVol   = ui.useState(saved.masterVol)
  local musicVol,    setMusicVol    = ui.useState(saved.musicVol)
  local sfxVol,      setSfxVol      = ui.useState(saved.sfxVol)
  local muted,       setMuted       = ui.useState(saved.muted)

  local quality,     setQuality     = ui.useState(saved.quality)
  local fullscreen,  setFullscreen  = ui.useState(saved.fullscreen)
  local vsync,       setVsync       = ui.useState(saved.vsync)

  local difficulty,  setDifficulty  = ui.useState(saved.difficulty)
  local autosave,    setAutosave    = ui.useState(saved.autosave)
  local hints,       setHints       = ui.useState(saved.hints)
  local cameraShake, setCameraShake = ui.useState(saved.cameraShake)

  -- ── tab content ─────────────────────────────────────────────────────────────

  local content

  if tab == "Audio" then
    content = ui.column({ style = { gap = 0 } }, {
      sectionHeader("VOLUME"),
      volumeRow("Master Volume", masterVol, setMasterVol),
      sep(),
      volumeRow("Music",         musicVol,  setMusicVol),
      sep(),
      volumeRow("SFX / UI",      sfxVol,    setSfxVol),
      sectionHeader("OUTPUT"),
      toggleRow("Mute All", "Silence every audio channel", muted, setMuted),
    })

  elseif tab == "Graphics" then
    content = ui.column({ style = { gap = 0 } }, {
      sectionHeader("QUALITY"),
      selectorRow("Preset", { "Low", "Medium", "High", "Ultra" }, quality, setQuality),
      sectionHeader("DISPLAY"),
      toggleRow("Fullscreen",  "Toggle borderless fullscreen",     fullscreen, setFullscreen),
      sep(),
      toggleRow("V-Sync",      "Cap framerate to display refresh", vsync, setVsync),
    })

  elseif tab == "Gameplay" then
    content = ui.column({ style = { gap = 0 } }, {
      sectionHeader("CHALLENGE"),
      selectorRow("Difficulty", { "Easy", "Normal", "Hard", "Nightmare" }, difficulty, setDifficulty),
      sectionHeader("FEATURES"),
      toggleRow("Auto-save",     "Save progress automatically",       autosave,    setAutosave),
      sep(),
      toggleRow("Show Hints",    "Display contextual tips in-game",   hints,       setHints),
      sep(),
      toggleRow("Camera Shake",  "Shake on impacts and explosions",   cameraShake, setCameraShake),
    })
  end

  -- ── shell ────────────────────────────────────────────────────────────────────

  return ui.column({
    width = MW,
    height = MH,
    style  = {
      background  = SURFACE,
      borderColor = BORDER,
      borderWidth = 1,
      radius      = 16,
    },
  }, {

    -- Header
    ui.row({
      padding = { top = 22, bottom = 20, left = 36, right = 28 },
      style   = { alignItems = "center", justifyContent = "space-between" },
    }, {
      ui.column({ style = { gap = 3 } }, {
        ui.text("Game Settings", { style = { fontSize = 17, color = TEXT } }),
        ui.text("Changes apply when you press Save.", { style = { fontSize = 11, color = MUTED } }),
      }),
      ui.button({
        label   = "✕",
        onClick = function() ui.modal.close("settings") end,
        padding = { top = 5, bottom = 5, left = 9, right = 9 },
        style   = {
          background  = { 0, 0, 0, 0 },
          borderColor = { 0, 0, 0, 0 },
          color       = MUTED,
          radius      = 6,
          hover = { background = { 1, 1, 1, 0.06 }, color = TEXT },
        },
      }),
    }),

    -- Tab bar
    ui.box({
      style = { borderColor = BORDER, borderWidth = 1, height = 1 },
    }),
    ui.row({
      padding = { top = 14, bottom = 10, left = 28, right = 28 },
      style   = { gap = 4 },
    }, {
      tabBtn("Audio",    tab == "Audio",    function() setTab("Audio")    end),
      tabBtn("Graphics", tab == "Graphics", function() setTab("Graphics") end),
      tabBtn("Gameplay", tab == "Gameplay", function() setTab("Gameplay") end),
    }),

    -- Content
    ui.box({
      style = {
        flex        = 1,
        paddingTop  = 2,
        paddingLeft = 36, paddingRight = 36,
      },
    }, { content }),

    -- Footer
    ui.box({
      style = { borderColor = BORDER, borderWidth = 1, height = 1 },
    }),
    ui.row({
      padding = { top = 18, bottom = 20, left = 36, right = 36 },
      style   = { justifyContent = "flex-end", alignItems = "center", gap = 10 },
    }, {
      ui.button({
        label   = "Cancel",
        onClick = function() ui.modal.close("settings") end,
        padding = { top = 9, bottom = 9, left = 22, right = 22 },
        style   = {
          background  = { 0, 0, 0, 0 },
          borderColor = BORDER,
          borderWidth = 1,
          radius      = 8,
          color       = MUTED,
          hover = { background = { 1, 1, 1, 0.05 }, color = TEXT },
        },
      }),
      ui.button({
        label   = "Save Changes",
        onClick = function()
          saved.masterVol   = masterVol
          saved.musicVol    = musicVol
          saved.sfxVol      = sfxVol
          saved.muted       = muted
          saved.quality     = quality
          saved.fullscreen  = fullscreen
          saved.vsync       = vsync
          saved.difficulty  = difficulty
          saved.autosave    = autosave
          saved.hints       = hints
          saved.cameraShake = cameraShake
          ui.modal.close("settings")
        end,
        padding = { top = 9, bottom = 9, left = 22, right = 22 },
        style   = {
          background  = ACCENT,
          borderColor = { 0.60, 0.72, 1.0, 0.55 },
          borderWidth = 1,
          radius      = 8,
          color       = { 0.06, 0.06, 0.12, 1 },
          hover = { background = { 0.52, 0.66, 1.0, 1 } },
        },
      }),
    }),
  })
end

-- ─── app shell ────────────────────────────────────────────────────────────────

local function App()
  return ui.column({
    width  = "100%",
    height = "100%",
    style  = {
      alignItems     = "center",
      justifyContent = "center",
      gap            = 14,
      background     = BG,
    },
  }, {
    ui.text("Dragon's Keep", {
      style = { fontSize = 30, color = { 0.72, 0.60, 0.38, 1 } },
    }),
    ui.text("Paused — the world waits for you.", {
      style = { fontSize = 13, color = MUTED },
    }),
    ui.box({ style = { height = 8 } }),
    ui.button({
      label   = "⚙  Settings",
      onClick = function()
        ui.modal.open("settings", SettingsModal, {
          transition         = "scale",
          duration           = 0.22,
          width              = MW,
          height             = MH,
          dismissOnBackdrop  = false,
        })
      end,
      padding = { top = 13, bottom = 13, left = 32, right = 32 },
      style   = {
        background  = { 0.16, 0.15, 0.24, 1 },
        borderColor = { ACCENT[1], ACCENT[2], ACCENT[3], 0.35 },
        borderWidth = 1,
        radius      = 9,
        color       = TEXT,
        hover = {
          background  = { 0.22, 0.20, 0.32, 1 },
          borderColor = { ACCENT[1], ACCENT[2], ACCENT[3], 0.6 },
        },
      },
    }),
    ui.text("Esc to close any open modal", {
      style = { fontSize = 11, color = { MUTED[1], MUTED[2], MUTED[3], 0.5 } },
    }),
  })
end

local function beforeDraw()
  love.graphics.clear(BG[1], BG[2], BG[3], 1)
end

local function keypressed(key)
  if key == "escape" then
    ui.modal.closeAll()
  end
end

local function setup()
	ui.setTheme(exampleTheme)
end

return {
  id = "settings",
  label = "Settings",
  setup = setup,
  window = {
    width     = 960,
    height    = 600,
    resizable = true,
    title     = "glyph — settings",
  },
  beforeDraw = beforeDraw,
  keypressed = keypressed,
  teardown = function()
    ui.modal.closeAll()
  end,
  component = function()
    return App()
  end,
}
