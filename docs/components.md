---
icon: lucide/boxes
---

# Components

Glyph components return virtual nodes. Components are plain Lua functions; there is no class system.

## Text

```lua
ui.text("Hello", {
  wrap = true,
  width = 240,
  style = { color = { 1, 1, 1, 1 } },
})
```

Use `wrap = true` with a known width for text that may overflow.

## Box

`ui.box(props, children)` is a visual/container primitive. It does not lay out children unless you provide a layout mode with `display`, or use `ui.row`, `ui.column`, or `ui.stack`.

```lua
ui.box({
  width = 200,
  height = 80,
  style = { background = { 0.1, 0.1, 0.12, 1 } },
})
```

## Row And Column

Use `ui.row` and `ui.column` for normal flex-style flow.

```lua
ui.row({ gap = 8, width = "100%" }, {
  ui.input({ flex = 1, value = filter, onChange = setFilter }),
  ui.button({ label = "Clear", onClick = clearFilter }),
})
```

## Stack

Use `ui.stack` for layered UI.

```lua
ui.stack({ width = "100%", height = "100%" }, {
  ui.box({ position = "absolute", inset = 0, interactive = false, draw = drawBackground }),
  ui.column({ position = "absolute", top = 24, left = 24 }, {
    ui.text("HUD"),
  }),
})
```

Later children draw above earlier children unless `zIndex` changes the order.

## Button

```lua
ui.button({
  label = "Run",
  onClick = run,
  style = {
    background = { 0.1, 0.5, 0.9, 1 },
    color = { 1, 1, 1, 1 },
    hover = { background = { 0.15, 0.6, 1, 1 } },
  },
})
```

Buttons are focusable by default.

## Input

```lua
ui.input({
  value = query,
  placeholder = "Filter logs...",
  onChange = setQuery,
  flex = 1,
})
```

Inputs are controlled: keep the value in state and update it through `onChange`.

## Meter

`ui.meter(props)` draws generic value displays such as health, mana, cooldown,
durability, progress, or debug telemetry. It is intentionally not a game-specific
`healthBar` component.

```lua
ui.meter({
  value = hp,
  min = 0,
  max = maxHp,
  width = 180,
  height = 14,
  shape = { kind = "skew", skew = 12 },
  trackStyle = { background = { 0, 0, 0, 0.35 } },
  fillStyle = { background = { 0.1, 0.9, 0.55, 1 } },
})
```

Meters support:

- `kind = "linear" | "radial" | "arc"`
- `direction = "right" | "left" | "up" | "down"` for linear meters
- `shape` for rectangular, skewed, polygon, circle, or ellipse fills
- `segments`, `gap`, `thickness`, `startAngle`, and `endAngle`
- `label`, children overlays, `trackStyle`, `fillStyle`, `overfillStyle`, and `backgroundStyle`

```lua
ui.meter({
  kind = "arc",
  value = charge,
  max = 100,
  width = 72,
  height = 72,
  thickness = 8,
  startAngle = math.rad(135),
  endAngle = math.rad(405),
  fillStyle = { color = { 1, 0.8, 0.2, 1 } },
})
```

## Scroll View

```lua
ui.scrollView({ width = "100%", height = 300 }, rows)
```

Scroll views clamp scrolling to content bounds and support optional scroll indicators.

## Tabs

Uncontrolled tabs:

```lua
ui.tabs({ defaultActive = 1 }, {
  { label = "Logs", content = LogsPanel() },
  { label = "Stats", content = StatsPanel() },
})
```

Controlled tabs:

```lua
ui.tabs({
  active = activeTab,
  onChange = setActiveTab,
}, tabs)
```

## Panel

`ui.panel` is a small convenience component for framed tool sections:

```lua
ui.panel({ title = "Logs", width = "100%", flex = 1 }, {
  ui.text("Ready"),
})
```
