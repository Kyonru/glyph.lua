---
icon: lucide/rocket
---

# glyph.lua

Declarative UI for Love2D — components, hooks, flex layout, scenes, modals, and transitions.
Built for game tooling, HUDs, debug panels, and in-game interfaces.

## Installation

Install with [Feather](https://kyonru.github.io/feather/):

```sh
feather package install glyph
```

Then require it at the top of your project:

```lua
local ui = require("glyph")
```

## Quick setup

Wire glyph into your Love2D callbacks with a single call:

```lua
function love.load()
  ui.load({
    window = { width = 960, height = 600, title = "My Game" },
    app    = App,
  })
end

function love.update(dt) ui.update(dt) end
function love.draw()     ui.render(App) end
```

`ui.load` automatically installs `mousemoved`, `mousepressed`, `mousereleased`,
`keypressed`, `keyreleased`, `textinput`, `wheelmoved`, and `resize` callbacks
so you don't have to wire each one manually.

---

## Example — sign-in screen

A centered card with email and password fields:

```lua
local ui = require("glyph")

local BG      = { 0.07, 0.07, 0.11, 1 }
local SURFACE = { 0.12, 0.11, 0.18, 1 }
local BORDER  = { 1, 1, 1, 0.08 }
local ACCENT  = { 0.42, 0.56, 1.0, 1 }
local TEXT    = { 0.92, 0.92, 0.96, 1 }
local MUTED   = { 0.52, 0.52, 0.62, 1 }

local function field(label, value, onChange, placeholder)
  return ui.column({ style = { gap = 6 } }, {
    ui.text(label, { style = { fontSize = 11, color = MUTED } }),
    ui.input({
      value       = value,
      onChange    = onChange,
      placeholder = placeholder,
      style = {
        background  = { 0.08, 0.08, 0.14, 1 },
        borderColor = BORDER,
        borderWidth = 1,
        radius      = 8,
        color       = TEXT,
        fontSize    = 13,
        focus = {
          borderColor = { ACCENT[1], ACCENT[2], ACCENT[3], 0.6 },
        },
      },
    }),
  })
end

local function SignIn()
  local email,    setEmail    = ui.useState("")
  local password, setPassword = ui.useState("")

  return ui.column({
    width  = "100%",
    height = "100%",
    style  = {
      alignItems     = "center",
      justifyContent = "center",
      background     = BG,
    },
  }, {
    ui.column({
      style = {
        width       = 360,
        background  = SURFACE,
        borderColor = BORDER,
        borderWidth = 1,
        radius      = 14,
        padding     = 36,
        gap         = 20,
      },
    }, {

      -- Header
      ui.column({ style = { gap = 4, marginBottom = 4 } }, {
        ui.text("Welcome back", { style = { fontSize = 22, color = TEXT } }),
        ui.text("Sign in to continue.", { style = { fontSize = 13, color = MUTED } }),
      }),

      field("Email",    email,    setEmail,    "you@example.com"),
      field("Password", password, setPassword, "••••••••"),

      -- Sign-in button
      ui.button({
        label   = "Sign in",
        onClick = function()
          -- handle authentication
        end,
        style = {
          background  = ACCENT,
          borderColor = { 0.60, 0.72, 1.0, 0.4 },
          borderWidth = 1,
          radius      = 8,
          color       = { 0.06, 0.06, 0.12, 1 },
          fontSize    = 13,
          hover = { background = { 0.52, 0.66, 1.0, 1 } },
        },
      }),

      -- Footer link
      ui.button({
        label   = "Forgot password?",
        onClick = function() end,
        style   = {
          background = { 0, 0, 0, 0 },
          color      = MUTED,
          fontSize   = 12,
          hover      = { color = TEXT },
        },
      }),
    }),
  })
end

function love.load()
  ui.load({ window = { width = 800, height = 600, title = "Sign in" }, app = SignIn })
end

function love.update(dt) ui.update(dt) end
function love.draw()
  love.graphics.clear(BG[1], BG[2], BG[3])
  ui.render(SignIn)
end
```

---

## Next steps

- [Getting Started](getting-started.md) — hooks, state, and effects
- [Components](components.md) — full component reference
- [Scenes & Modals](scenes-and-modals.md) — layered UI and transitions
