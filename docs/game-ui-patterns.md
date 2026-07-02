---
icon: lucide/gamepad-2
---

# Game UI Patterns

Game UI is not just menu screens. Glyph is built for the whole loop: shop
choices, HUD state, live combat overlays, tooltips, controller focus, feedback
bursts, and debug/tuning panels that run beside the game.

> [!TIP]
> See the ingredients in action: [`examples/viewport`](examples.md) for fixed
> virtual coordinates, [`examples/hud-menu`](examples.md) for custom-drawn
> command UI, [`examples/inventory`](examples.md) for dense item grids,
> [`examples/juice`](examples.md) for interaction feedback,
> [`examples/navigate`](examples.md) for controller focus, and
> [`examples/dashboard`](examples.md) for dense debugger-style panels.

## Pattern Map

| Game need | Glyph primitives |
| --- | --- |
| Fixed 480x270 or 640x360 UI | `window.viewport`, `ui.viewport()`, `ui.viewportBackend` |
| Shop cards and passive cards | `ui.grid`, `ui.row`, `ui.button`, custom `draw`, state styles |
| HUD meters and combat overlays | `ui.stack`, `ui.meter`, `ui.portal`, scenes with overlays |
| Class icons and status pips | `ui.image`, `ui.spriteSheet`, `ctx:shape`, `ctx:meter` |
| Rich stat text | `ui.richText` with an app-provided SYSL backend |
| Hover, buy, reroll, level-up feel | `feedback` props, `ui.feedback.play`, audio/feedback events |
| Controller focus | `ui.navigate`, `navGroup`, `navScope`, opt-in gamepad install |
| Live tuning and debug panels | `ui.scene.push` overlays, `ui.scrollView`, `ui.input`, `ui.tabs` |

## Virtual Resolution First

Keep the game and UI in the same virtual coordinate system. Glyph lays out,
draws, and hit-tests in virtual coordinates when a viewport backend is active,
and installed mouse/touch callbacks convert screen input before routing it.

```lua
ui.load({
  window = {
    width = 960,
    height = 540,
    resizable = true,
    viewport = {
      backend = "shove", -- or "push"
      width = 480,
      height = 270,
      fit = "aspect",
      filter = "nearest",
      canvas = true,
    },
  },
  install = {
    gamepad = true,
  },
  app = App,
})
```

For app-owned Push/Shove setup, attach the existing instance instead of letting
Glyph configure the backend:

```lua
ui.configureWindow({
  viewport = {
    backend = "push",
    instance = push,
    width = 480,
    height = 270,
    managed = false,
  },
})
```

Use `ui.viewportBackend.screenToViewport(x, y)` when gameplay systems also need
the pointer in virtual coordinates.

## Shop Flow

Build compact shop cards from ordinary focusable nodes. Keep purchase rules in
app state, but let Glyph own layout, focus, hit testing, state styles, audio cue
metadata, and feedback triggers.

```lua
local function shopCard(unit)
  local affordable = gold >= unit.cost
  local locked = unit.locked == true

  return ui.button({
    key = "shop:" .. unit.id,
    label = "",
    width = 80,
    height = 90,
    disabled = locked,
    navGroup = "shop",
    accessibilityLabel = unit.name .. ", cost " .. unit.cost,
    feedback = {
      hover = "shop.card.hover",
      focus = "shop.card.hover",
      press = affordable and "shop.card.press" or false,
      activate = affordable and "shop.card.buy" or false,
    },
    onClick = function(node)
      if locked then
        return
      end

      if not affordable then
        ui.feedback.play("shop.card.denied", node, {
          trigger = "error",
          restart = true,
          key = "shop.card.denied",
        })
        return
      end

      buy(unit)
      ui.feedback.play("shop.purchase", node, {
        trigger = "purchase",
        restart = true,
        key = "shop.purchase",
      })
    end,
    style = {
      radius = 4,
      background = { 0.06, 0.07, 0.09, 0.96 },
      borderColor = unit.color,
      borderWidth = 1,
      hover = { background = { 0.1, 0.11, 0.14, 0.98 } },
      focused = { borderColor = { 1, 1, 1, 1 }, borderWidth = 2 },
      pressed = { background = { 0.03, 0.04, 0.06, 1 } },
      disabled = { opacity = 0.48 },
    },
    draw = function(_, x, y, width, height, _, style, ctx)
      ctx:color(style.background)
      ctx:rect("fill", x, y, width, height, style.radius)
      ctx:color(style.borderColor)
      ctx:rect("line", x, y, width, height, style.radius)

      ctx:color(unit.color)
      ctx:rect("fill", x + 8, y + 8, 14, 14, 3)
      ctx:color(style.color or ui.theme.textColor)
      ctx:text(unit.name, x + 8, y + 32)
      ctx:text("$" .. tostring(unit.cost), x + 8, y + height - 18)
    end,
  })
end
```

Use `ui.grid` for uniform shop slots, `ui.row` for reroll/lock/level controls,
and `ui.portal` for card tooltips that should float above the shop.

## Tooltips And Rich Stat Text

Capture card geometry with `onLayout`, then render a tooltip in a portal. This
keeps tooltip placement app-owned while preserving Glyph's draw and hit order.

```lua
local tooltipAnchor = nil

local card = ui.button({
  label = "",
  onLayout = function(bounds)
    tooltipAnchor = bounds
  end,
})

local tooltip = tooltipAnchor and ui.portal({
  left = tooltipAnchor.x + tooltipAnchor.width + 6,
  top = tooltipAnchor.y,
  width = 160,
  interactive = false,
}, {
  ui.panel({ padding = 6, gap = 4 }, {
    ui.richText("[color=#ffd166]+18%[/color] attack speed", {
      width = 148,
      wrap = true,
      textStyle = "caption",
    }),
  }),
})
```

If a game already has tag-like strings such as `[fg]` or `[yellow]`, translate
that app markup into the rich text backend format before calling `ui.richText`.
Glyph should stay parser-agnostic; the app owns color names, stat vocabulary,
typewriter pacing, and sound/image tags.

## HUD And Combat Overlays

Use a root `ui.stack` for layered combat UI. Decorative layers are
non-interactive; HUD controls and overlays opt into focus and input.

```lua
local function CombatHud()
  local view = ui.viewport()

  return ui.stack({ width = view.width, height = view.height }, {
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = false,
      accessibilityHidden = true,
      draw = drawArenaFrame,
    }),

    ui.row({
      position = "absolute",
      left = 8,
      bottom = 8,
      gap = 5,
    }, unitMeters()),

    ui.column({
      position = "absolute",
      right = 8,
      top = 8,
      gap = 4,
      interactive = false,
    }, waveStatusRows()),
  })
end
```

Use scene overlays for transient combat UI: boss warnings, countdowns, pause
menus, inspectors, and read-only telemetry. Non-blocking overlays pass input to
lower layers when they do not hit an interactive node.

```lua
ui.scene.push("spawn-warning", WarningOverlay, {
  kind = "overlay",
  blocking = false,
  input = false,
  transition = ui.transitions.animate({
    enter = { from = { opacity = 0, y = -8 }, to = { opacity = 1, y = 0 } },
    exit = { to = { opacity = 0, y = -8 } },
  }),
})
```

## Debug And Tuning Panels

Debug UI is a first-class game workflow. Use overlays for live enemy tuning,
spawn controls, wave inspectors, performance panels, and accessibility logs.

```lua
ui.scene.push("debug", DebugPanel, {
  kind = "overlay",
  align = "top-right",
  width = 220,
  height = 270,
  blocking = false,
  input = true,
  transition = "none",
})
```

Inside the panel, prefer dense primitives: `ui.tabs` for views, `ui.scrollView`
for long inspectors, `ui.input` for numeric tuning, `ui.button` for spawn and
toggle commands, and `ui.meter` for live timings. Keep the game simulation and
debug data ownership outside Glyph; the panel reads and writes app state through
normal callbacks.

## Core Boundary

Promote primitives, not game nouns. A reusable feature belongs in core when it
helps many games build their own shop/HUD/debug UI: virtual viewport adapters,
focus routing, feedback hooks, rich text backend integration, draw helpers,
meters, portals, surfaces, and scenes.

Keep these as app or example code:

- `shopCard`
- `classIcon`
- passive-card rules
- reroll economy rules
- enemy spawner policy
- camera shake and particles
- game-specific text tags and sound packs
