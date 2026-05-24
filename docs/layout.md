---
icon: lucide/layout-grid
---

# Layout

Glyph uses a small pure-Lua layout engine. The model is explicit and game-friendly, not CSS.

## Flow Layout

`ui.row` lays children horizontally. `ui.column` lays children vertically.

Common props:

- `width`, `height`
- `minWidth`, `maxWidth`, `minHeight`, `maxHeight`
- `padding`
- `gap`
- `align = "start" | "center" | "end" | "stretch"`
- `grow`
- `flex`
- `shrink`
- `basis` or `flexBasis`

`flex = 1` means “take remaining space” using a zero basis unless width or height is provided.

```lua
ui.row({ width = 600, gap = 8 }, {
  ui.button({ label = "Fixed" }),
  ui.input({ flex = 1, value = query, onChange = setQuery }),
})
```

## Percent Sizes

Percent sizes resolve against the parent’s available content bounds.

```lua
ui.column({ width = 600, padding = 12 }, {
  ui.box({ width = "100%", height = 180 }),
})
```

## Stack Layout

`ui.stack` layers children on top of each other.

```lua
ui.stack({ width = "100%", height = "100%" }, {
  ui.box({ width = "100%", height = "100%" }),
  ui.text("Overlay"),
})
```

Later children draw above earlier children unless `zIndex` changes the order.

## Absolute Positioning

Absolute children are removed from parent flow and positioned within the parent content bounds.

Supported props:

- `position = "absolute"`
- `x`, `y`
- `top`, `right`, `bottom`, `left`
- `inset`
- `zIndex`
- `width`, `height`, percent sizes, min/max sizes

Examples:

```lua
ui.box({ position = "absolute", x = 12, y = 16, width = 80, height = 24 })
ui.box({ position = "absolute", right = 8, bottom = 8, width = 32, height = 32 })
ui.box({ position = "absolute", inset = 0 })
```

When both `left` and `right` are set, Glyph derives width. When both `top` and `bottom` are set, Glyph derives height.

Absolute children never affect parent size. Give the parent explicit dimensions, `flex`, percent size, or normal-flow children.

## Text Wrapping

Use `wrap = true` with a known width:

```lua
ui.text(longMessage, {
  wrap = true,
  width = 320,
})
```

Text measurement uses Love2D fonts at runtime and test-friendly measurement hooks outside Love2D.

## Common Pitfalls

- Do not use plain `ui.box` as a stack. Use `ui.stack`.
- Do not expect absolute children to size parents.
- Do not use percent size without a parent that has known bounds.
