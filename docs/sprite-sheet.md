---
icon: lucide/grid-2x2
---

# Sprite Sheets

`ui.spriteSheet` slices a Love2D image into uniform frames and hands back the
`Quad`s, so you can draw a single frame in a [custom draw](custom-draw.md) or
feed frame ranges to [anim8](https://github.com/kikito/anim8) for animation. It
owns the frame geometry (size, margins, gaps) and caches the quads; the optional
`anim8` backend owns playback.

```lua
local image = love.graphics.newImage("assets/potions.png")
local sheet = ui.spriteSheet(image, { frameWidth = 32, frameHeight = 32 })
```

## `ui.spriteSheet(image, opts)`

Returns a sprite sheet bound to `image`. `opts`:

| field | type | meaning |
| --- | --- | --- |
| `frameWidth` | number | **required** — frame width in pixels |
| `frameHeight` | number | **required** — frame height in pixels |
| `imageWidth` | number? | source width; defaults to `image:getWidth()` |
| `imageHeight` | number? | source height; defaults to `image:getHeight()` |
| `left` | number? | left margin before the first column (default `0`) |
| `top` | number? | top margin before the first row (default `0`) |
| `border` | number? | gap between frames (default `0`) |
| `anim8` | table? | anim8 module for this sheet (overrides the global backend) |

The returned sheet exposes `image`, `frameWidth`, `frameHeight`, `imageWidth`,
`imageHeight`, `left`, `top`, `border`, and the derived `columns`/`rows`. Frame
size and margins are validated — a frame size that does not fit the image errors
early.

## Drawing a single frame

`quad`/`quadAt` need no backend — they return cached `love.graphics.Quad`s you
draw yourself:

```lua
-- 1-based linear index (row-major) or explicit column/row
local first = sheet:quad(1)
local cell = sheet:quadAt(2, 1) -- column 2, row 1

ui.box({
  width = 32, height = 32,
  draw = function(_, x, y, _, _, love)
    love.graphics.draw(sheet.image, cell, x, y)
  end,
})
```

The image-node form takes a quad directly:

```lua
ui.image({ source = sheet.image, quad = sheet:quad(3), width = 32, height = 32 })
```

- `sheet:quad(index)` — `Quad` for the 1-based row-major frame `index`.
- `sheet:quadAt(column, row)` — `Quad` for the 1-based `column`/`row`.

Both clamp-check their range and error if the frame is out of bounds.

## Animation (anim8)

Frame ranges and animations require an [anim8](https://github.com/kikito/anim8)
module — register it once, or pass `anim8` per sheet:

```lua
ui.spriteSheetBackend.configure({ anim8 = require("anim8") })
```

Then:

```lua
local idle = sheet:animation({ "1-4", 1 }, 0.14) -- frames, durations, onLoop?

function love.update(dt) idle:update(dt) end
-- draw the current frame in a custom draw:
ui.box({ width = 32, height = 32, draw = function(_, x, y, _, _, love)
  idle:draw(sheet.image, x, y)
end })
```

- `sheet:frames(...)` — passes anim8 grid syntax (e.g. `"1-4", 1`) through to the
  underlying anim8 grid and returns the frame list.
- `sheet:animation(frameArgs, durations, onLoop?)` — builds an anim8 animation;
  `frameArgs` is the table of grid arguments (e.g. `{ "1-4", 1 }`).
- `sheet:currentQuad(animation)` — the `Quad` for an animation's current frame,
  handy when you want to draw it through Glyph's `ui.image`/quad path.

Calling any of these without an anim8 backend raises a clear error, so the
no-animation `quad`/`quadAt` path stays dependency-free.

## Backend configuration

- `ui.spriteSheetBackend.configure({ anim8 = require("anim8") })` — set the
  default anim8 module for every sheet.
- `ui.spriteSheetBackend.clear()` — remove it (sheets fall back to a per-call
  `anim8`).

> [!NOTE]
> anim8 is an app-provided peer dependency — Glyph does not vendor it. Drawing
> static frames needs only Love2D; only ranges/animations need anim8.

See it in action in [`examples/inventory`](examples.md) (animated potion
sprites driven by `ui.spriteSheet` + anim8).
