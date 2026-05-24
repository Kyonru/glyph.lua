---
icon: lucide/monitor
---

# Responsive Helpers

Glyph tracks viewport size and breakpoints for resizable Love2D windows.

## Configure The Window

```lua
ui.configureWindow({
  width = 928,
  height = 720,
  resizable = true,
  minWidth = 420,
  minHeight = 520,
  breakpoints = { md = 760, lg = 1100 },
})
```

Or through `ui.load`:

```lua
ui.load({
  window = {
    width = 928,
    height = 720,
    resizable = true,
    breakpoints = { md = 760 },
  },
  app = App,
})
```

## Resize

When callbacks are not installed automatically:

```lua
function love.resize(width, height)
  ui.resize(width, height)
end
```

## Query Helpers

- `ui.viewport()`
- `ui.breakpoint()`
- `ui.atLeast(name)`
- `ui.below(name)`
- `ui.responsive(values)`
- `ui.columns(containerWidth, opts)`
- `ui.clamp(value, minValue, maxValue)`

Example:

```lua
local viewport = ui.viewport()
local compact = ui.below("md")
local cards = ui.columns(viewport.width - 28, {
  min = compact and 150 or 180,
  maxCount = compact and 2 or 4,
  gap = 10,
})
```

Responsive helpers are intentionally small. Keep layout decisions explicit in the component.
