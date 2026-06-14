---
icon: lucide/palette
---

# Styling And Themes

<!-- glyph:feature-gif styling -->
![Animated GIF showing Glyph theme colors, variants, and state styles.](assets/feature-gifs/styling.gif)
<!-- /glyph:feature-gif styling -->

> [!TIP]
> See it in action: [`examples/themes`](examples.md) swaps full themes, and
> [`examples/styles`](examples.md) shows variants and state styles.

Glyph uses Lua tables for styling, not CSS syntax.

## Inline Style

```lua
ui.button({
  label = "Run",
  style = {
    background = { 0.1, 0.5, 0.9, 1 },
    color = { 1, 1, 1, 1 },
    borderColor = { 1, 1, 1, 0.2 },
    borderWidth = 1,
    radius = 4,
  },
})
```

Supported visual fields include:

- `background`
- `color`
- `borderColor`
- `borderWidth`
- `radius`
- `lineWidth`
- `font`
- `fontSize`
- `lineHeight`
- `opacity`
- `padding`
- `shader`
- `blendMode`

Existing compatibility props such as `backgroundColor`, `borderColor`, `color`, and `radius` still work, but `style` is preferred.

## Typography

Themes can define a font registry, typography presets, and a global text scale:

```lua
ui.setTheme({
  textScale = 1.15,
  fonts = {
    body = love.graphics.newFont(14),
    heading = love.graphics.newFont(24),
  },
  typography = {
    text = { font = "body", fontSize = 14, lineHeight = 20 },
    h1 = { font = "heading", fontSize = 30, lineHeight = 36 },
    caption = { font = "body", fontSize = 11, lineHeight = 15 },
  },
})
```

`font` may be a Love2D font object, a registered font name, or a font spec table
such as `{ path = "assets/ui.ttf", size = 14 }`. Font specs are loaded lazily and
cached when Love2D font creation is available.

Text nodes select presets with `textStyle`:

```lua
ui.text("ALERT", { textStyle = "h1" })
ui.richText("[font=mono]Optional SYSL text[/font]")
```

## State Styles

State styles are nested tables:

```lua
style = {
  background = { 0.1, 0.1, 0.12, 1 },
  hover = { background = { 0.16, 0.16, 0.2, 1 } },
  pressed = { background = { 0.08, 0.08, 0.1, 1 } },
  focused = { borderColor = { 0.4, 0.7, 1, 1 } },
  disabled = { opacity = 0.5 },
}
```

Supported states:

- `hover`
- `pressed`
- `focused`
- `active`
- `disabled`

`button`, `input`, and `tab` ship a default `disabled` style (a muted
background and text), so setting `disabled = true` dims them without any per-app
styling. Override the theme component's `disabled` table to customize it.

Tabs should use `active` state styling rather than ad hoc active colors.

> [!NOTE]
> `textAlign` (`"left" | "center" | "right"`) aligns **text** within a node. Do
> not confuse it with the flex `align` prop, which controls cross-axis alignment
> of a container's children (see [Layout](layout.md)).

## Themes

Set a theme globally:

```lua
ui.setTheme({
  textColor = { 0.92, 0.92, 0.96, 1 },
  components = {
    button = {
      background = { 0.12, 0.12, 0.16, 1 },
      variants = {
        primary = {
          background = { 0.1, 0.5, 0.9, 1 },
          color = { 1, 1, 1, 1 },
        },
      },
    },
  },
})
```

Read the current theme:

```lua
local theme = ui.getTheme()
```

## Variants

Use `variant` to select component theme variants:

```lua
ui.button({
  label = "Save",
  variant = "primary",
})
```

## Precedence

A node's draw style is resolved by merging sources in order, **later wins**:

1. `theme.base`
2. `theme.components[type]` — component defaults (e.g. `button`, `input`)
3. the selected `variant` (`theme.components[type].variants[variant]`)
4. **component** state styles for the active states
5. **variant** state styles for the active states
6. legacy top-level props (`background`, `color`, `radius`, …)
7. inline `props.style`
8. inline `props.style` state styles for the active states

So inline `style` overrides the theme, and a node's own state style (e.g.
`style = { hover = {...} }`) overrides the component/variant state style. When
several states are active at once, they apply in the order **hover → pressed →
focused → active → disabled**, so `disabled` wins over `active`, which wins over
`focused`, and so on.

Resolved styles are cached per node and invalidated when the node's state, the
inputs, or the theme `version` change.

## Audio Cues

Glyph can resolve UI audio cue names from theme components, variants, and node
props. Glyph only emits cue events; your app owns Love2D sources and playback.

```lua
ui.setTheme({
  components = {
    button = {
      audio = {
        hover = "ui-hover",
        press = "ui-press",
        activate = "ui-activate",
        focus = "ui-focus",
      },
      variants = {
        danger = {
          audio = { activate = "danger-confirm" },
        },
      },
    },
  },
})
```

Per-node `audio` overrides the theme, and `audio = false` silences that node:

```lua
ui.button({
  label = "Silent",
  audio = false,
})

ui.button({
  label = "No confirm sound",
  audio = { activate = false },
})
```

Listen with `ui.on("audio", handler)` and play app-owned sources there.

## Style Helpers

- `ui.style(table)`
- `ui.variant(name, table)`
- `ui.composeStyles(...)`

## Transitions

Style transitions are lightweight interpolation tables:

```lua
style = {
  background = { 0.1, 0.1, 0.12, 1 },
  hover = { background = { 0.2, 0.2, 0.26, 1 } },
  transition = { background = 0.12, opacity = 0.08 },
}
```

Style transitions should only mark style dirty unless animating layout fields.

For mount/unmount motion, use node `enter` and `exit` animations instead. Those
animations are visual transforms powered by Glyph's vendored flux runner and do
not affect layout or input geometry.

## Feedback Vs Transitions

Use state styles for steady interaction appearance, such as hover colors or
focused borders. Use `style.transition` to interpolate those style fields.

Use `enter` / `exit` for lifecycle motion when nodes mount or unmount.

Use `ui.feedback` for triggerable game-feel stacks such as squash/stretch on
press, a pop on activation, audio cue metadata, or app-owned particle/shake
events. Feedback animation is visual-only and composes with node enter/exit
animation during drawing.
