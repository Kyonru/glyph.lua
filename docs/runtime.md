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

function love.keyreleased(key)
  ui.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
  ui.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
  ui.gamepadreleased(joystick, button)
end
```

`ui.install` and `ui.load` can install common callbacks automatically.
Gamepad callbacks are installed only when `install.gamepad` is enabled.

> [!NOTE]
> If a fixed viewport backend is active, Glyph converts mouse and touch screen
> coordinates into virtual viewport coordinates before hover, focus, click, and
> scroll routing. Pointer events outside the virtual viewport do not hit UI.

Buttons use the same press lifecycle for pointer and keyboard activation:
mouse/touch down and Return/Space down enter the pressed state, and release
activates the button when focus is still on the same node. This keeps pressed
styles and audio cues consistent across mouse, keyboard, and gamepad mappings
that forward to `ui.keypressed` / `ui.keyreleased`.

Touch callbacks are wired automatically by `ui.install` / `ui.load`. Gamepad
mapping is opt-in:

```lua
ui.load({
  app = App,
  install = {
    gamepad = true,
  },
})
```

## Runtime Callbacks

Use `ui.on(name, fn, opts)` to subscribe to runtime callbacks.

Supported names:

- `beforeUpdate`
- `afterUpdate`
- `beforeRender`
- `afterRender`
- `layout`
- `audio`
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

## Audio Cue Events

Glyph emits `audio` callbacks when configured cues resolve for interaction
events. It does not load or play sounds.

```lua
local sounds = {
  hover = love.audio.newSource("hover.wav", "static"),
}

ui.on("audio", function(event)
  local source = sounds[event.cue]
  if source then
    source:stop()
    source:play()
  end
end)
```

The event includes `cue`, `kind`, `node`, `type`, `path`, `variant`,
`styleType`, and a best-effort `label`. Supported cue kinds are `hover`,
`press`, `activate`, and `focus`.

## Future Accessibility

Glyph does not implement accessibility behavior yet. The intended shape is
layout-agnostic metadata and app-provided resolvers rather than fixed widgets:

- semantic props such as `role`, `label`, `description`, and `valueText`
- queryable runtime metadata for tools, overlays, and platform adapters

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
