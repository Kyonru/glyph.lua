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

Run tests with Busted:

```sh
busted
```

## Examples

```sh
love examples/basic
love examples/performance
```

The performance example keeps a 10,000-event dataset but mounts only a small
visible window, reuses static row nodes, and shows render/layout timing in the UI.
