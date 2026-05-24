---
icon: lucide/cpu
---

# Runtime, Hooks, And Events

Glyph has one shared runtime exposed through `ui.update`, `ui.render`, input forwarding functions, hooks, and helper APIs.

## Rendering

Manual wiring:

```lua
function love.update(dt)
  ui.update(dt)
end

function love.draw()
  ui.render(App)
end
```

Automatic wiring:

```lua
ui.load({
  window = { width = 900, height = 600, resizable = true },
  app = App,
})
```

## Hooks

`ui.useState(initial)` stores state by component tree position:

```lua
local count, setCount = ui.useState(0)
```

`ui.useEffect(fn, deps)` runs effects when dependencies change:

```lua
ui.useEffect(function()
  print("mounted or changed")
  return function()
    print("cleanup")
  end
end, { id })
```

Hook identity is tree-position based. Keyed reconciliation is not part of v0.1.

## Input Forwarding

Manual input forwarding:

```lua
function love.mousemoved(x, y, dx, dy)
  ui.mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button)
  ui.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  ui.mousereleased(x, y, button)
end

function love.wheelmoved(dx, dy)
  ui.wheelmoved(dx, dy)
end

function love.textinput(text)
  ui.textinput(text)
end

function love.keypressed(key)
  ui.keypressed(key)
end
```

`ui.install` and `ui.load` can install common callbacks automatically.

## Runtime Callbacks

Use `ui.on(name, fn, opts)` to subscribe to runtime callbacks.

Supported names:

- `beforeUpdate`
- `afterUpdate`
- `beforeRender`
- `afterRender`
- `layout`
- `focusChanged`
- `hoverChanged`
- `event`

Unregister with the returned closure:

```lua
local off = ui.on("event", function(kind, ...)
  print(kind)
end)

off()
```

## Interaction Helpers

Helpers:

- `ui.isHovered(node)`
- `ui.isPressed(node)`
- `ui.isFocused(node)`
- `ui.isActive(node)`
- `ui.isHot(node)`

These are useful inside custom draw callbacks.

## Event Routing

- Hit testing follows visual order.
- Higher `zIndex` wins among siblings.
- Later stack children draw above earlier children and receive events first.
- `interactive = false` lets decorative nodes pass events through.
- Scene layers route input top-down.
