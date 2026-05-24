# glyph.lua

Declarative UI for Love2D 11.x, shaped for debugger panels and game tooling.

```lua
local ui = require("glyph")

function App()
  local count, setCount = ui.useState(0)

  return ui.column({ gap = 8, padding = 12 }, {
    ui.text("Feather Debugger"),
    ui.button({
      label = "Increment",
      onClick = function()
        setCount(count + 1)
      end,
    }),
    ui.text("Count: " .. count),
  })
end

function love.update(dt)
  ui.update(dt)
end

function love.draw()
  ui.render(App)
end
```

## v0.1

- Components: `text`, `box`, `row`, `column`, `button`, `input`, `scrollView`, `tabs`, `panel`.
- Hooks: `useState`, `useEffect`.
- Runtime callbacks via `ui.on(name, fn, opts)`.
- Performance helpers: `ui.memo(component, deps)` and `ui.static(node)`.
- Pure-Lua layout backend with Yoga-compatible concepts and an adapter boundary for future Yoga integration.

## Styling

Use Lua tables for styles. Existing visual props such as `backgroundColor`,
`borderColor`, `color`, and `radius` still work, but `style` is the preferred
API.

```lua
ui.button({
  label = "Run",
  variant = "primary",
  style = {
    background = { 0.1, 0.5, 0.9, 1 },
    color = { 1, 1, 1, 1 },
    borderWidth = 2,
    radius = 4,
    hover = { background = { 0.15, 0.6, 1, 1 } },
    pressed = { background = { 0.05, 0.35, 0.7, 1 } },
    transition = { background = 0.12 },
  },
})
```

Theme component defaults and variants live under `theme.components`:

```lua
ui.setTheme({
  components = {
    button = {
      variants = {
        danger = {
          background = { 0.72, 0.12, 0.16, 1 },
          color = { 1, 1, 1, 1 },
          hover = { background = { 0.86, 0.18, 0.22, 1 } },
        },
      },
    },
  },
})
```

Supported visual fields include `background`, `color`, `borderColor`,
`borderWidth`, `radius`, `lineWidth`, `font`, `opacity`, `shader`, and
`blendMode`. Custom draw callbacks receive the resolved style as the last
argument.

## Responsive Layout

Glyph tracks a viewport for resizable Love2D windows and exposes small helpers
for breakpoint-based UI:

```lua
function love.load()
  ui.configureWindow({
    width = 928,
    height = 720,
    resizable = true,
    minWidth = 420,
    minHeight = 520,
    breakpoints = { md = 760 },
  })
end

function love.resize(width, height)
  ui.resize(width, height)
end

function App()
  local viewport = ui.viewport()
  local compact = ui.below("md")
  local cards = ui.columns(viewport.width - 28, {
    min = compact and 150 or 160,
    maxCount = compact and 2 or 4,
    gap = 10,
  })

  return ui.row({ width = viewport.width, height = viewport.height }, {
    -- use `cards.count`, `cards.width`, `ui.clamp`, and `ui.responsive`
  })
end
```

Glyph can also install common Love2D callbacks for you:

```lua
function love.load()
  ui.load({
    window = { width = 928, height = 720, resizable = true },
    app = App,
  })
end
```

`ui.load` configures the window and installs common Love2D callbacks using the
global `love` module by default. The lower-level `ui.install` API is still
available when you only want callback wiring.

## Game UI Helpers

Custom draw callbacks receive a draw context as the final argument:

```lua
ui.customButton({
  width = 240,
  height = 64,
  draw = function(node, x, y, width, height, love, style, ctx)
    ctx:color(style.background)
    ctx:polygon("fill", ctx:skewBox({ skew = 16 }))
    ctx:color(ctx.hot and ui.theme.accentColor or style.color)
    ctx:text("COMMAND", x + 18, y + 22)
  end,
})
```

Useful helpers include `ui.isHovered`, `ui.isPressed`, `ui.isFocused`,
`ui.isActive`, `ui.isHot`, `ui.mix`, `ui.mixColor`, `ui.setColor`,
`ui.time`, `ui.pulse`, `ui.polygonBox`, and `ui.customButton`.

Children can take remaining space with `flex = 1`, similar to Tailwind's
`flex-1`. `grow` still expands from the measured or explicit size, while
`flex = 1` uses a zero basis unless a width or height is provided. Containers
and leaf nodes can also use percent sizes such as `width = "100%"`:

```lua
ui.row({ width = 600, gap = 8 }, {
  ui.button({ label = "Fixed" }),
  ui.input({ flex = 1, value = query, onChange = setQuery }),
})

ui.column({ width = 600, padding = 12 }, {
  ui.box({ width = "100%", height = 180 }),
})
```

Run tests with Busted:

```sh
busted
```

## Examples

```sh
love examples/basic
love examples/dashboard
love examples/hud-menu
love examples/styles
love examples/performance
```

The performance example keeps a 10,000-event dataset but mounts only a small
visible window, reuses static row nodes, and shows render/layout timing in the UI.
The styles example demonstrates theme switching, variants, state styles,
transitions, custom draw, and shader-backed styling.
The dashboard example is inspired by shadcn/ui `dashboard-01`, translated into
Glyph panels, metric cards, chart drawing, filters, tabs-style buttons, and a
documents table.
The HUD menu example shows animated custom-drawn game buttons, hover/press
transitions, and colorful command-panel styling.
