---
icon: lucide/gauge
---

# Performance

<!-- glyph:feature-gif performance -->
![Animated GIF showing Glyph memoized rows, static nodes, visible windows, FPS, and bounded work.](assets/feature-gifs/performance.gif)
<!-- /glyph:feature-gif performance -->

> [!NOTE]
> The docs GIF is captured at a fixed 18 FPS for deterministic encoding. The
> runnable `examples/performance` demo reports the live Love2D FPS on your machine.

Glyph is intended for debugger panels and game UI, so performance matters.

## Principles

- Keep layout explicit and cheap.
- Avoid CSS-like selectors, global queries, string parsing, or cascading ancestry scans.
- Keep static UI static.
- Mount only what needs to be visible for large lists.
- Prefer primitives that compose over specialized components.

## Typography

Theme font specs are loaded lazily and cached by resolved size, and wrapped-text
measurement (`font:getWidth`) is cached per `(font, text)` so re-laying out the
same labels each frame does not re-measure them. Prefer named fonts and
`textStyle` presets over creating Love2D fonts inside component functions.

SYSL-backed rich text is opt-in. Use plain `ui.text` for hot-path labels, and
reserve `ui.richText` for copy that actually needs rich formatting, images,
effects, or dialogue-style behavior.

## Memo

Use `ui.memo(component, deps)` to reuse a subtree when dependencies are unchanged.

```lua
local rows = ui.memo(function()
  return buildRows(data)
end, { dataVersion })
```

## Static Nodes

Use `ui.static(node)` for stable labels, icons, or repeated rows that do not need rebuild/layout churn.

```lua
local label = ui.static(ui.text("Ready"))
```

## Reactivity model

A render rebuilds the tree only when it is **dirty** — a `useState` setter ran,
input changed focus/hover, or an animation is in flight — then lays out and
draws. On an idle frame the existing tree is reused; layout short-circuits
unchanged/static subtrees, so idle cost is low. (See
[Architecture](architecture.md).)

Glyph does not yet do fine-grained diffing or automatic memoization: a dirty
render rebuilds and re-allocates the affected tree. For large or rapidly-changing
UIs the tools above — `ui.memo`, `ui.static`, stable `key`s, and a mounted
visible window — are how you keep that bounded. Finer-grained reactivity is a
possible future direction, not something you need to design around today.

## Images

Load Love2D image assets once in app setup, then pass the image object to
`ui.image`. Glyph caches the derived fit/alignment plan for each image node, but
it does not own filesystem loading or asset lifetime.

```lua
local icon = love.graphics.newImage("assets/icon.png")
local iconNode = ui.static(ui.image({ source = icon, width = 32, height = 32 }))
```

For repeated inventory cells or portraits, combine reused image objects with
`ui.memo` or `ui.static`. Use custom draw only when a single image draw is not
enough for the effect.

## I18n

Glyph caches translations that are safe to reuse. Plain keys are cached until
`ui.i18n.invalidate()` or `ui.i18n.setLocale(locale)`.

```lua
ui.textKey("menu.play")
```

Parameterized translations are translated fresh unless you provide a stable
cache key:

```lua
ui.textKey("messages", {
  textParams = { count = count },
  textCacheKey = "messages:" .. tostring(count),
})
```

For memoized translated subtrees, include `ui.i18n.version()` in the deps so
locale changes rebuild the cached nodes:

```lua
local panel = ui.memo(buildPanel, { ui.i18n.version(), dataVersion })
```

## Large Lists

For large log/table views:

- Keep the dataset outside the UI tree.
- Mount a visible window of rows.
- Reuse stable row components where possible.
- Give each row a stable `key` so its identity — focus, hover, a mid-edit input
  cursor, and cached style — follows the data when rows are inserted, removed, or
  reordered, instead of snapping to whichever sibling now sits at that index.
- Use `scrollView` bounds and scroll offsets to clamp work.
- Show coarse live counters such as FPS, render time, layout passes, and mounted
  row counts so performance examples explain their budget at a glance.

See `examples/performance`.

## Scenes And Layers

Scene layers keep isolated hook scopes and cached roots. Use layers for overlays and modals instead of rebuilding unrelated UI inside the main tree.

## Custom Draw

Custom draw runs every render. Avoid hot-path allocation when possible:

- Reuse tables for repeated geometry when practical.
- Avoid building huge arrays every frame.
- Keep shader/state changes localized.
- Mark decorative overlays `interactive = false` to keep hit testing clean.
