---
icon: lucide/workflow
---

# Architecture & Mental Model

Glyph is a React/Ink-style **immediate-mode-ish** UI runtime: you describe the UI
as a tree of nodes built by plain functions of state, and the runtime turns that
tree into layout, drawing, and input each frame. This page is the mental model
that ties the feature pages together — read it once, then the rest of the docs
make more sense.

## The frame

Your game loop calls two things:

```lua
function love.update(dt) ui.update(dt) end
function love.draw()     ui.render(App) end
```

- **`ui.update(dt)`** advances the animation, feedback, and style clocks and the
  active scene. It marks the tree "dirty" only when something actually changed
  (an animation tick, a scene update) — it does not rebuild on its own.
- **`ui.render(App)`** does the work:
  1. **Build** — *if the tree is dirty* (a `useState` setter ran, input changed
     focus/hover, an animation is mid-flight, or the root component changed), it
     calls your `App` function, which calls child component functions, producing
     a fresh node tree. On an idle frame it reuses the existing tree.
  2. **Layout** — `Layout.compute` sizes and positions every node (see below).
     Static/unchanged subtrees short-circuit, so idle frames are cheap.
  3. **Draw** — it walks the tree, resolves each node's style, and paints it.
  4. **Input** — pointer/keyboard events you forward are hit-tested against the
     laid-out tree and dispatched to handlers and focus.

The takeaway: **building is change-driven; layout and draw run every frame.** You
never mutate nodes by hand — you change state, the affected subtree rebuilds, and
the next render reflects it.

## State and identity

Hooks (`useState`, `useEffect`, `memo`) are stored per render scope **by call
order**, and a node's identity is its **position in the tree** (its path). Two
consequences:

- Call hooks unconditionally at the top of a component, in the same order every
  render — don't put them behind branches.
- A node keeps its state/focus/animation as long as it stays at the same tree
  position. If you render a **dynamic list** and reorder or insert items, give
  each item a stable `key` so its identity (and its in-progress edits, focus, and
  enter/exit animation) follows it instead of snapping to a sibling.

```lua
for _, row in ipairs(rows) do
  ui.box({ key = row.id }, { ... }) -- identity follows row.id, not the index
end
```

State changes mark the tree dirty; the next `ui.render` rebuilds. See
[Runtime, Hooks, and Events](runtime.md).

## Layout

`Layout.compute` is a single top-down pass. Each container resolves its own size
from `width`/`height` (numbers or `"%"` strings), `flex`/`grow`/`shrink`,
`min*`/`max*`, then sizes and places its children:

- **Flow** — `ui.row` / `ui.column` distribute children along a main axis with
  `gap`, `justify` (main axis), `align` (cross axis), per-child `flex` and
  `margin`.
- **Grid** — `ui.grid` lays uniform cells row-major.
- **Stack** — `ui.stack` overlaps children in the same box.
- **Absolute** — `position = "absolute"` takes a node out of flow, positioned
  with `left`/`right`/`top`/`bottom`/`inset`; it never affects parent size.

Sizes flow down (available space), intrinsic/content sizes flow up. Details and
pitfalls live in [Layout](layout.md).

## Draw

Drawing is a recursive walk, ordered by `zIndex` within each stacking scope.
Each node's [style](styling.md) is resolved (theme → component → variant → state
→ inline), cached, and applied. A node's custom `draw` callback **replaces** the
default background/border, and receives a [draw context](custom-draw.md) with
helpers for shapes, clips, stencils, paths, and nine-slice frames. `scrollView`
clips its content with a scissor.

## Input and focus

You forward Love2D events (`ui.mousemoved`, `ui.mousepressed`, `ui.keypressed`,
`ui.wheelmoved`, gamepad…) and Glyph routes them:

- **Pointer** events hit-test the laid-out tree honoring `zIndex`/`zScope`, then
  update `hover`/`pressed` and call the node's handlers (`onClick`,
  `onMousePressed`, …).
- **Focus** is tracked on the runtime; keyboard and gamepad move it with spatial
  [navigation](navigation.md). Mouse and keyboard are kept consistent — a click
  focuses and activates the same node the keyboard would.
- **Adapters** that own their own surface (the [Menori adapter](menori.md),
  [offscreen surfaces](surface.md)) can route a pointer into their space first.

Query interaction state in custom draw with `ui.isHovered/isPressed/isFocused/
isActive/isHot(node)`.

## Where things live

- **Core** (`glyph/*.lua`) owns the runtime, layout, styling, components, input,
  and the helper APIs.
- **Adapters** (`ui.menori`, `ui.dialogue`) bridge app-provided libraries; they
  render from a normalized model and never own that library's logic.
- **Your app** owns game state, assets, audio, and anything visually specific to
  one game — built from primitives and custom draw, kept out of core.

For the reasoning behind these boundaries and per-subsystem rules, see
`AGENTS.md` in the repository root.
