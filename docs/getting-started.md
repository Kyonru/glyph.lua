---
icon: lucide/map
---

# Getting Started

Require Glyph from Love2D:

```lua
local ui = require("glyph")
```

Create components as Lua functions:

```lua
local function App()
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
```

Wire Love2D manually:

```lua
function love.update(dt)
  ui.update(dt)
end

function love.draw()
  ui.render(App)
end

function love.mousepressed(x, y, button)
  ui.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  ui.mousereleased(x, y, button)
end
```

Or let Glyph install common callbacks:

```lua
function love.load()
  ui.load({
    window = {
      width = 928,
      height = 720,
      resizable = true,
      title = "Glyph App",
    },
    app = App,
  })
end
```

`ui.load` uses the global `love` module by default. Use `ui.install(love, opts)` when you only want callback wiring.

## Tests

Run the pure Lua test suite with:

```sh
.luarocks/bin/busted
```
