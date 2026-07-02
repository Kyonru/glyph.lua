---
icon: lucide/frame
---

# Offscreen Surfaces

`ui.surface` renders a Glyph tree into its own Love2D `Canvas` instead of
straight to the screen. Each surface has an **isolated runtime** (its own hooks,
focus, layout, and input state) and a scoped `ui`, so it is independent from the
main `ui.render` tree. Use it for UI you want to treat as a texture: world-space
panels mapped onto 3D geometry, minimaps, tooltips/overlays composited with a
shader, or expensive UI you cache and redraw only when it changes.

```lua
local panel = ui.surface.new({
  width = 256,
  height = 128,
  component = function(ui, ctx)
    return ui.column({ width = "100%", height = "100%", padding = 8 }, {
      ui.text("Objective"),
      ui.meter({ value = 0.6 }),
    })
  end,
})
```

## `ui.surface.new(opts)`

| field | type | meaning |
| --- | --- | --- |
| `width`, `height` | number | canvas size in pixels |
| `component` | fun(ui, ctx)? | builds the tree; receives the surface's scoped `ui` and a context (`{ surface, runtime, width, height }`). Can be passed to `:render` instead |
| `theme` | GlyphTheme? | theme for this surface (defaults to the global theme) |
| `clearColor` | GlyphColor? | canvas clear color each render (default transparent `{0,0,0,0}`) |
| `filter` | `"linear"`/`"nearest"` or table? | canvas texture filtering; table form accepts `min`, `mag`, and `anisotropy` |
| `stencil` | boolean? | request a stencil-enabled canvas (default on) so clips/masks work |
| `love` | table? | Love2D module (defaults to the global `love`) |
| `canvas`, `canvasOptions` | any? | bring your own canvas / `newCanvas` options |

## Loop

Drive it like a mini app, then draw its canvas wherever you want:

```lua
function love.update(dt)
  panel:update(dt)
end

function love.draw()
  local canvas = panel:render() -- builds + lays out + draws into the canvas
  love.graphics.draw(canvas, 320, 80)
end
```

- `surface:render(component?)` — build/layout/draw into the canvas and return it.
  Pass a `component` to (re)set the tree; omit it to redraw the current one.
- `surface:update(dt)` — advance the surface's runtime (hooks, animations, feedback).
- `surface:resize(width, height)` — change the canvas size (drops the old canvas).
- `surface:markDirty()` — flag a redraw (for change-driven caching).
- `surface:destroy()` — release the canvas and clear the runtime.

## Input

A surface has its own focus/hover/press state, so forward pointer and keyboard
events to it — in the surface's **local coordinates** (subtract the on-screen
origin you drew the canvas at, and undo any scale):

```lua
function love.mousemoved(x, y)
  panel:mousemoved(x - 320, y - 80)
end

function love.mousepressed(x, y, button)
  panel:mousepressed(x - 320, y - 80, button)
end
```

`mousereleased`, `keypressed`, and `keyreleased` forward the same way. For UI
mapped onto 3D geometry, convert the hit point to surface UV space first — the
same pattern the [Menori adapter](menori.md) uses for world-space billboards.

> [!NOTE]
> A surface is fully isolated: its hooks and focus do not interact with the main
> `ui.render` tree. Keep one surface per logical panel, and remember to forward
> input — a surface that is only drawn (never sent events) is display-only.
