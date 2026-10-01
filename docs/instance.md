---
icon: lucide/panels-top-left
---

# Isolated Screen Instances

`ui.instance.new` creates a screen-space Glyph tree with its own hooks, focus,
hover, press, scroll, scene, modal, drag, and feedback state. It draws directly
to the current Love2D screen instead of allocating a `Canvas`.

Use an instance when an existing application owns the Love callbacks and needs
to arbitrate between Glyph UI and another interactive system, such as a level
editor canvas, game viewport, graph, or timeline. Use the default `ui.*`
runtime for a single Glyph root, and use [`ui.surface`](surface.md) when the UI
must render to a texture.

```lua
local glyph = require("glyph")

local editorUi = glyph.instance.new({
  component = function(ui, ctx)
    return ui.row({ width = ctx.width, height = ctx.height, interactive = false }, {
      ui.panel({ width = 280, height = "100%" }, {
        ui.input({ value = filter, onChange = setFilter }),
      }),
      ui.box({ flex = 1, interactive = false }), -- app-owned canvas region
    })
  end,
})
```

The component receives a runtime-scoped `ui` API and a context containing
`instance`, `width`, and `height`. Always create nodes and call hooks with that
scoped `ui`; its state is independent from the default Glyph runtime and every
other instance.

## Loop And Lifecycle

```lua
function love.update(dt)
  editorUi:update(dt)
end

function love.draw()
  drawWorldEditor()
  editorUi:render()
end

function love.resize(width, height)
  editorUi:resize(width, height)
end

function unloadEditor()
  editorUi:destroy()
end
```

- `instance:update(dt)` advances animation, feedback, scenes, and runtime time.
- `instance:render(component?)` builds when dirty, lays out, and draws directly
  to the current screen. Passing a component replaces the mounted component.
- `instance:resize(width, height)` updates responsive state and invalidates the
  tree. Rendering also reads the current Love graphics dimensions.
- `instance:markDirty()` invalidates app-owned state that changed outside Glyph
  hooks or input callbacks.
- `instance:destroy()` runs root and scene effect cleanups, clears feedback and
  input captures, and makes the instance inert. It is safe to call more than
  once.

## Input Arbitration

Every instance input method returns a strict boolean. A `true` result means
Glyph claimed the event; a `false` result means the application can route it to
the editor canvas or game.

```lua
function love.mousepressed(x, y, button)
  if editorUi:mousepressed(x, y, button) then
    return
  end
  editorCanvas.mousepressed(x, y, button)
end

function love.keypressed(key)
  if editorUi:keypressed(key) then
    return
  end
  editorShortcuts.keypressed(key)
end
```

Forward the matching methods as needed:

- `mousemoved(x, y, dx, dy)`
- `mousepressed(x, y, button)`
- `mousereleased(x, y, button)`
- `wheelmoved(dx, dy)`
- `keypressed(key)` and `keyreleased(key)`
- `textinput(text)`

Pointer events are claimed over interactive Glyph nodes. A release remains
claimed when Glyph captured the matching press or drag, even if the pointer was
moved outside the original node. Blocking scene/modal backdrops also claim
pointer input.

Wheel input is claimed whenever the current hover target is interactive UI.
This prevents an editor canvas from zooming behind a panel, including when a
nested scroll view has reached its limit.

A focused input claims key press/release and text events, including keys it
does not edit directly, so app shortcuts do not fire while the user types.
Buttons claim their Return/Space activation lifecycle. A blocking scene or
modal claims keyboard and text events even when none of its controls has focus.

> [!NOTE]
> `wheelmoved` has no pointer coordinates in Love2D and uses Glyph's current
> hover target. Forward `mousemoved` to the instance so that target stays
> current.

## Hit Testing And Focus

Instances expose supported queries without requiring access to runtime fields:

```lua
local node = editorUi:hitTest(mouseX, mouseY)
local focused = editorUi:focused()

if editorUi:hasFocus() then
  -- suppress global editor shortcuts, draw an app-owned focus indicator, etc.
end
```

- `hitTest(x, y)` returns the top interactive `GlyphNode`, or `nil`.
- `focused()` returns the current reachable focused node, or `nil`.
- `hasFocus()` is the boolean form.
- `setFocus(node)` focuses a known node; pass `nil` to clear focus.

Hit testing requires a rendered tree. Decorative or pass-through regions and
their covering container ancestors should set `interactive = false`; interactive
children still participate in hit testing. This is especially important for a
root editor shell surrounding a central app-owned canvas.

## Choosing The Runtime Form

| API | Rendering target | Runtime ownership | Typical use |
| --- | --- | --- | --- |
| default `ui.render` | screen | shared singleton | Glyph owns the primary app UI |
| `ui.instance.new` | screen | isolated | editor shell around an app-owned canvas |
| `ui.surface.new` | Canvas/texture | isolated | world-space panel, cached UI, shader composition |
