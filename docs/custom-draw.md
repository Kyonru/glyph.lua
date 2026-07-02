---
icon: lucide/pen-tool
---

# Custom Draw And Helpers

<!-- glyph:feature-gif custom-draw -->
![Animated GIF showing Glyph custom draw helpers, vector path reveal, morphing, clipping, and masks.](assets/feature-gifs/custom-draw.gif)
<!-- /glyph:feature-gif custom-draw -->

> [!TIP]
> See it in action: [`examples/path-feedback`](examples.md) covers draw
> helpers, paths, morphing, and masks.

Glyph supports custom drawing on any node through `props.draw`.

## Custom Draw Signature

```lua
draw = function(node, x, y, width, height, love, style, ctx)
  -- draw here
end
```

Arguments:

- `node`: current virtual node
- `x`, `y`, `width`, `height`: absolute drawing bounds
- `love`: Love2D module
- `style`: resolved style
- `ctx`: draw helper context

## Draw Context

Useful fields:

- `ctx.node`
- `ctx.props`
- `ctx.x`, `ctx.y`, `ctx.width`, `ctx.height`
- `ctx.love`
- `ctx.graphics`
- `ctx.style`
- `ctx.runtime`
- `ctx.hovered`
- `ctx.pressed`
- `ctx.focused`
- `ctx.active`
- `ctx.hot`
- `ctx.time`

Useful methods:

- `ctx:color(color, alpha)`
- `ctx:rect(mode, x, y, width, height, radius)`
- `ctx:line(...)`
- `ctx:polygon(mode, points)`
- `ctx:shape(mode, shape, bounds?)`
- `ctx:circle(mode, bounds?)` — shorthand for `ctx:shape(mode, { kind = "circle" }, bounds)`
- `ctx:ellipse(mode, bounds?)` — shorthand for `ctx:shape(mode, { kind = "ellipse" }, bounds)`
- `ctx:triangle(mode, cx, cy, width, height)` — isosceles triangle centered on `(cx, cy)`, pointing right
- `ctx:triangleEquilateral(mode, cx, cy, width)` — equilateral triangle centered on `(cx, cy)`, pointing right
- `ctx:arc(mode, x, y, radius, a1, a2, arctype?)` — arc from angle `a1` to `a2` (`arctype` defaults to `"pie"`)
- `ctx:roundedRect(mode, cx, cy, width, height, radius?)` — rectangle centered on `(cx, cy)` with optional corner radius
- `ctx:dashedLine(x1, y1, x2, y2, dashSize, gapSize)` — dashed line segment
- `ctx:dashedRectangle(cx, cy, width, height, dashSize, gapSize)` — dashed rectangle centered on `(cx, cy)`
- `ctx:roundedLine(x1, y1, x2, y2, width)` — line of thickness `width` with rounded ends
- `ctx:blob(bounds?, opts?)`
- `ctx:clip(shape, fn)`
- `ctx:stencil(shapeOrFn, fn, opts?)`
- `ctx:meter(bounds, opts)`
- `ctx:nineSlice(image, bounds, opts)`
- `ctx:path(mode, path, bounds, opts)`
- `ctx:text(value, x, y, opts?)`
- `ctx:printf(value, x, y, limit, align, opts?)`
- `ctx:pulse(speed, phase)`
- `ctx:skewBox(opts)`

### Timing and procedural shapes

A few methods are worth spelling out:

- `ctx:pulse(speed?, phase?)` — a `0..1` sine oscillator driven by `ctx.time`
  (`(sin(time * speed + phase) + 1) / 2`). Use it for breathing glows, blinking
  cursors, or pulsing borders without tracking your own clock:

  ```lua
  ctx:color({ 1, 1, 1, 0.3 + 0.4 * ctx:pulse(3) })
  ctx:rect("line", ctx.x, ctx.y, ctx.width, ctx.height, 6)
  ```

- `ctx:text` and `ctx:printf` resolve typography through the node/theme before
  drawing, including `fontFallbacks` for scripts the selected font cannot
  render. Pass `opts` such as `{ textStyle = "caption" }` or
  `{ font = "japanese" }` when a custom-drawn label should use a different
  preset than the node itself. The current color still comes from `ctx:color` or
  Love2D graphics state.

- `ctx:skewBox(opts?)` — returns the four corner points of the node's box,
  optionally sheared, for `ctx:polygon`. `opts.skew` is the horizontal shear in
  pixels (see the example below).

- `ctx:blob(bounds?, opts?)` — returns the points of an organic, wobbly polygon
  inscribed in `bounds` (defaults to the node box), for `ctx:polygon`. `opts`:
  `points`/`segments` (vertex count, min 5, default 10), `variance` (0–0.85
  wobble, default 0.16), `phase` (advance to animate the wobble), `seed`
  (deterministic shape), and `inset`:

  ```lua
  ctx:color({ 0.2, 0.8, 0.6, 1 })
  ctx:polygon("fill", ctx:blob(nil, { variance = 0.3, phase = ctx.time }))
  ```

`ctx:nineSlice` is covered under [Nine-Slice Frames](#nine-slice-frames) below.

## Example

```lua
ui.box({
  width = 240,
  height = 64,
  style = {
    background = { 0.1, 0.1, 0.14, 1 },
    color = { 0.9, 0.95, 1, 1 },
  },
  draw = function(node, x, y, width, height, love, style, ctx)
    ctx:color(style.background)
    ctx:polygon("fill", ctx:skewBox({ skew = 16 }))
    ctx:color(ctx.hot and { 1, 1, 1, 1 } or style.color)
    ctx:text("COMMAND", x + 18, y + 22)
  end,
})
```

For ordinary images, prefer `ui.image` over custom draw. It handles fit,
alignment, tint, opacity, clipping, and quads:

```lua
ui.image({
  source = portrait,
  width = 96,
  height = 96,
  fit = "cover",
  clip = { kind = "circle" },
  interactive = false,
})
```

Use custom draw when the image itself needs custom shader setup, multi-pass
composition, procedural effects, or app-specific atlas behavior beyond a single
optional quad.

## Shapes And Stencils

Glyph shape descriptors are plain tables:

```lua
{ kind = "rect", radius = 8 }
{ kind = "skew", skew = 18, inset = 2 }
{ kind = "polygon", points = { 0, 0, 140, 10, 120, 64, 8, 56 } }
{ kind = "circle" }
{ kind = "ellipse" }
{ kind = "blob", points = 10, variance = 0.16, seed = "play-button" }
```

Polygon points are local to the node bounds unless `absolute = true` is set.
Shape functions may also return local points or a mask/draw function when a shape
needs animation or custom geometry.

Use `clip` to mask children visually:

```lua
ui.stack({
  width = 220,
  height = 120,
  clip = { kind = "skew", skew = 24 },
}, {
  ui.box({
    position = "absolute",
    inset = 0,
    interactive = false,
    draw = drawAnimatedBackground,
  }),
  ui.text("MASKED PANEL", { x = 16, y = 16 }),
})
```

Use `stencil` when you want explicit inside/outside masking:

```lua
ui.box({
  width = 160,
  height = 160,
  stencil = {
    shape = { kind = "circle" },
    mode = "inside",
  },
}, {
  portraitNode,
})
```

> [!NOTE]
> `clip` and `stencil` are visual-only. Layout and hit testing still use the node's
> rectangular bounds.

Inside custom draw callbacks, use the same primitives:

```lua
draw = function(_, x, y, width, height, love, style, ctx)
  ctx:clip({ kind = "skew", skew = 18 }, function()
    ctx:color(style.background)
    ctx:rect("fill", x, y, width, height)
    ctx:meter({ x = x + 16, y = y + height - 22, width = width - 32, height = 10 }, {
      value = 72,
      max = 100,
      shape = { kind = "skew", skew = 8 },
      fillStyle = { background = { 0.1, 0.9, 0.55, 1 } },
    })
  end)
end
```

`ctx:blob(bounds, opts)` returns deterministic polygon points for organic
buttons, panels, masks, and meters:

```lua
draw = function(_, x, y, width, height, love, style, ctx)
  local shape = {
    kind = "blob",
    points = 12,
    variance = 0.18,
    seed = "launch",
    phase = ctx.time,
  }

  ctx:clip(shape, function()
    ctx:color(style.background)
    ctx:rect("fill", x, y, width, height)
  end)

  ctx:color(ctx.focused and { 1, 0.9, 0.2, 1 } or style.borderColor)
  ctx:shape("line", shape)
end
```

Blob, stencil, shader, particle, and splat-style visuals are usually app or
example code. Keep the core primitive generic, then layer the visual identity in
custom draw and feedback sequences.

## Vector Paths

Use `ctx:path(mode, path, bounds, opts)` for custom vector accents, animated
strokes, icons, route lines, HUD traces, and game-specific frame details.

```lua
draw = function(_, x, y, width, height, love, style, ctx)
  ctx:path("line", "M0 80 C60 8 120 152 180 40", {
    x = x + 18,
    y = y + 18,
    width = width - 36,
    height = height - 36,
  }, {
    stroke = { 0.1, 0.9, 0.75, 1 },
    strokeWidth = 4,
    progress = ctx:pulse(0.8), -- 0..1 stroke reveal
  })
end
```

`ctx:path` accepts the same options as `ui.path`: `stroke`, `strokeWidth`,
`fill`, `opacity`, `progress`, `morphTo`, `morph`, `morphMode`, `samples`, `fit`,
`align`, and `valign`. Fill drawing targets simple closed single-contour paths.

> [!NOTE]
> Glyph supports SVG path `d` data, not full SVG files. Arcs, gradients,
> document transforms, CSS, masks, holes, and winding rules are out of scope for
> v1.

## Nine-Slice Frames

Use `ctx:nineSlice` when a Love2D image should scale like a game UI frame,
window, tooltip, or item slot. Glyph draws the nine patches and caches the quads;
the artwork and style still belong to the app.

```lua
ui.box({
  width = 320,
  height = 180,
  draw = function(_, x, y, width, height, love, style, ctx)
    ctx:nineSlice(frameImage, {
      x = x,
      y = y,
      width = width,
      height = height,
    }, {
      border = { left = 12, right = 12, top = 14, bottom = 14 },
      tint = { 1, 0.92, 0.72, 1 },
      opacity = style.opacity,
    })
  end,
}, content)
```

Pass `border = 8` for an even border, or `center = false` to draw only the
frame. V1 stretches edges and center patches; tiled/repeated edges are left to
app-specific custom draw. `filter = "nearest"` or
`filter = { min = "nearest", mag = "linear" }` temporarily changes the frame
image's Love2D filter for the nine-slice draw and restores it afterward.

## Public Helper APIs

- `ui.isHovered(node)`
- `ui.isPressed(node)`
- `ui.isFocused(node)`
- `ui.isActive(node)`
- `ui.isHot(node)`
- `ui.mix(a, b, t)`
- `ui.mixColor(a, b, t)`
- `ui.setColor(loveModule, color, alpha)`
- `ui.time()`
- `ui.pulse(speed, phase)`
- `ui.polygonBox(x, y, width, height, opts)`
- `ui.meter(props)`
- `ui.path.parse(d)`
- `ui.path.bounds(path)`
- `ui.path.flatten(path, opts)`
- `ui.path.length(path, opts)`
- `ui.customButton(props)`

### Path geometry helpers

`ui.path(props)` renders a vector path node; the `ui.path.*` functions are the
underlying geometry, useful in custom draw to measure or sample a shape. They
accept either an SVG path **string** or a parsed **command list**.

- `ui.path.parse(d)` — parse an SVG path data string (e.g. `"M0 0 L10 0 Q20 0
  20 10"`) into a command list (`{ "M", x, y }`, `{ "L", x, y }`, `{ "C", x1, y1,
  x2, y2, x, y }`, `{ "Q", x1, y1, x, y }`). Results are cached per string.
- `ui.path.bounds(path)` — the tight bounding box `{ x, y, width, height }` of a
  string or command list (handy to scale/center a path into a node's rect).
- `ui.path.flatten(path, opts?)` — a flat polyline `{ x1, y1, x2, y2, ... }`
  approximating the path; `opts.samples` sets per-curve subdivision (higher =
  smoother).
- `ui.path.length(path, opts?)` — total length of the flattened path (or of a
  flat point array you pass directly). `opts.samples` is forwarded to `flatten`.

```lua
-- Place markers evenly along a route inside a node's box:
local d = "M0 40 Q60 -20 120 40 T240 40"
local points = ui.path.flatten(d, { samples = 24 })
local box = ui.path.bounds(d)

ui.box({ width = 240, height = 60, draw = function(_, x, y, _, _, _, _, ctx)
  ctx:path("line", d, { x = x, y = y - box.y, width = box.width, height = box.height })
  for i = 1, #points, 2 do
    ctx:circle("fill", { x = x + points[i] - 2, y = y + points[i + 1] - 2, width = 4, height = 4 })
  end
end })
```

For animating a path's stroke or morphing between shapes, use the `ui.path` node
props (`progress`, `morphTo`) covered in [Vector Paths](#vector-paths) above.

## Core Boundary

Use custom draw for game-specific UI. If a widget is visually specific to one game or example, keep it out of core and build it from primitives.
