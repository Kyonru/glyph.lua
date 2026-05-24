---
icon: lucide/gauge
---

# Performance

Glyph is intended for debugger panels and game UI, so performance matters.

## Principles

- Keep layout explicit and cheap.
- Avoid CSS-like selectors, global queries, string parsing, or cascading ancestry scans.
- Keep static UI static.
- Mount only what needs to be visible for large lists.
- Prefer primitives that compose over specialized components.

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

## Large Lists

For large log/table views:

- Keep the dataset outside the UI tree.
- Mount a visible window of rows.
- Reuse stable row components where possible.
- Use `scrollView` bounds and scroll offsets to clamp work.

See `examples/performance`.

## Scenes And Layers

Scene layers keep isolated hook scopes and cached roots. Use layers for overlays and modals instead of rebuilding unrelated UI inside the main tree.

## Custom Draw

Custom draw runs every render. Avoid hot-path allocation when possible:

- Reuse tables for repeated geometry when practical.
- Avoid building huge arrays every frame.
- Keep shader/state changes localized.
- Mark decorative overlays `interactive = false` to keep hit testing clean.
