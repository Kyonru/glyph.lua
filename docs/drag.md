---
icon: lucide/move
---

# Drag

`ui.drag` is a generic pointer-drag lifecycle: you give it `onStart` / `onMove`
/ `onDrop` / `onCancel` callbacks and it returns a **start function** you call
from a press handler. Glyph then tracks the pointer across moves and the release,
threading a single, stable context object through every callback. It owns the
gesture bookkeeping (distance threshold, deltas, source/target nodes); your app
owns what the drag *means* (reordering, drag-and-drop, sliders, dragging a map).

```lua
local startDrag = ui.drag({
  minDistance = 6,
  onStart = function(ctx) ... end,
  onMove  = function(ctx) ... end,
  onDrop  = function(ctx) ... end,
  onCancel = function(ctx) ... end,
})
```

## `ui.drag(opts)` → start function

`opts` (`GlyphDragProps`):

| field | type | meaning |
| --- | --- | --- |
| `minDistance` | number? | pointer travel (px) before the drag "arms"; below it, a release is a click, not a drop (default `0`) |
| `onStart` | fun(ctx)? | the gesture armed (immediately, or once `minDistance` is crossed) |
| `onMove` | fun(ctx)? | the pointer moved while dragging |
| `onDrop` | fun(ctx)? | the pointer was released while dragging |
| `onCancel` | fun(ctx)? | the gesture was cancelled (released under `minDistance`, or `ctx.cancel()`) |

It returns a **start function**:

```text
startDrag(x, y, button, node?, data?)
```

Call it from a press — a node's `onMousePressed` handler, or your global
`mousepressed` — passing the pointer position, the mouse button, the originating
`node`, and any `data` payload you want carried on the context.

```lua
ui.box({
  onMousePressed = function(x, y, button, node)
    if button == 1 then
      startDrag(x, y, button, node, { item = item, from = slotIndex })
    end
  end,
})
```

## The drag context

Every callback receives one `GlyphDragContext`:

| field | meaning |
| --- | --- |
| `x`, `y` | current pointer position |
| `startX`, `startY` | position where the drag began |
| `dx`, `dy` | delta since the previous event |
| `totalDx`, `totalDy` | delta since the start |
| `button` | the mouse button |
| `data` | the payload you passed to the start function |
| `sourceNode`, `sourcePath` | the node the drag started on |
| `targetNode`, `targetPath` | the node under the pointer now (for drop hit-testing) |
| `reason` | why the callback fired (`"start"`, `"move"`, `"drop"`, `"threshold"`, `"cancel"`) |
| `cancel(reason?)` | call to end the gesture as a cancel |

Use `ctx.targetNode` on `onDrop` to decide where the payload landed:

```lua
onDrop = function(ctx)
  local dropSlot = ctx.targetNode and ctx.targetNode.props.key
  if dropSlot then moveItem(ctx.data, dropSlot) end
end,
```

> [!NOTE]
> Glyph does not register "drop zones" for you — `onDrop` reports the node under
> the pointer; matching it to a valid target (a slot, a bin, a grid cell) is your
> app's logic. Pair it with [`ui.grid.pointToCell`](layout.md) when dropping onto
> a grid.

## Keyboard / mouse consistency

`ui.drag` is pointer-only. To keep mouse and keyboard interactions consistent
(per the [input rules](runtime.md)), drive selection/activation through focus and
keys, and reserve `ui.drag` for the pointer gesture — don't hand-roll a parallel
mouse path.

See it in action in [`examples/inventory`](examples.md) (drag items between
satchel and case slots, with a `minDistance` threshold so taps still click).
