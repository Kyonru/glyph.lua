---
icon: lucide/cpu
---

# Runtime, Hooks, And Events

<!-- glyph:feature-gif runtime -->
![Animated GIF showing Glyph runtime updates, input events, focus, and render callbacks.](assets/feature-gifs/runtime.gif)
<!-- /glyph:feature-gif runtime -->

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
- `accessibility`
- `feedback`
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

## Node Layout Callbacks

Use `onBounds` and `onLayout` when app code needs node geometry for drag/drop,
tooltips, popovers, minimap markers, overlays, or contextual menus.

`onBounds(bounds, node)` receives the node’s local parent-relative layout:

```lua
ui.box({
  width = 64,
  height = 64,
  onBounds = function(bounds, node)
    print(bounds.x, bounds.y, bounds.width, bounds.height)
  end,
})
```

`onLayout(bounds, node)` receives viewport-space bounds in the same coordinate
space as routed pointer input. It includes parent offsets, scene/modal layer
offsets, and `scrollView` visual scroll offsets.

```lua
ui.button({
  label = "Drag",
  onLayout = function(bounds)
    dragTargets.primary = bounds
  end,
})
```

Both callbacks fire after layout publication and before drawing, only when the
reported rectangle changes for that node path or when the callback function
identity changes. Reported bounds are rectangular layout geometry; they do not
include visual-only animation, feedback, shape, clip, stencil, or custom
transition transforms.

## Pointer Drag Helper

Use `ui.drag` when app code needs a captured pointer lifecycle without wiring a
global `ui.on("event")` listener. Glyph owns the pointer start/move/drop/cancel
callbacks; your app still owns target lookup, validation, swapping, placement,
and previews.

```lua
local startDrag = ui.drag({
  onStart = function(ctx)
    dragging = ctx.data
  end,
  onMove = function(ctx)
    pointer = { x = ctx.x, y = ctx.y }
  end,
  onDrop = function(ctx)
    dropItem(ctx.data, ctx.x, ctx.y)
  end,
  onCancel = function(ctx)
    dragging = nil
  end,
})

ui.button({
  label = "Potion",
  onMousePressed = function(x, y, button, node)
    if button == 1 then
      startDrag(x, y, button, node, { itemId = "potion" })
    end
  end,
})
```

`ctx` includes `x`, `y`, `startX`, `startY`, `previousX`, `previousY`, `dx`,
`dy`, `totalDx`, `totalDy`, `button`, `sourceNode`, `sourcePath`,
`targetNode`, `targetPath`, `data`, `runtime`, `reason`, and
`cancel(reason)`.

Set `minDistance` to delay `onStart` until the pointer moves far enough.
Releasing before the threshold preserves normal button activation. Once a drag
has started, release calls `onDrop` and suppresses the source button’s normal
`onClick`. Active drags cancel on Escape, viewport exit, focus loss, or when a
new drag starts.

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

## Feedback Events

Glyph emits `feedback` callbacks from `ui.feedback` `emit` steps. These events
are for app-owned effects such as particles, camera shake, haptics, splats, or
custom shader systems.

```lua
ui.on("feedback", function(event)
  if event.kind == "particles" then
    spawnParticles(event.node, event.name)
  end
end)
```

Feedback events include `kind`, `name`, `trigger`, `node`, `path`, `payload`,
and the original `step`. See [Feedback](feedback.md) for sequence definitions.

## Accessibility Events

Glyph exposes Love2D-friendly accessibility semantics through metadata and
runtime events. It does not speak text or create native OS controls; apps own
TTS, platform bridges, logs, or Love.js DOM adapters.

```lua
ui.on("accessibility", function(event)
  print(event.kind, event.message)
end)
```

Focus changes, button activation, manual announcements, and live-region updates
can emit events with `kind`, `message`, `node`, `path`, `role`, `label`,
`description`, `valueText`, and `live`. See [Accessibility](accessibility.md)
for semantic props, snapshots, i18n keys, and adapter patterns.

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
- `ui.portal` is promoted above normal content in the current render root and
  hit-tested before local content. The lower-level form is `position = "absolute"`
  with `zScope = "root"`.
- Later stack children draw above earlier children and receive events first.
- `interactive = false` lets decorative nodes pass events through.
- Scene layers route input top-down.
