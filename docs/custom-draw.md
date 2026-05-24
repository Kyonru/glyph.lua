---
icon: lucide/pen-tool
---

# Custom Draw And Helpers

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
- `ctx:text(value, x, y)`
- `ctx:printf(value, x, y, limit, align)`
- `ctx:pulse(speed, phase)`
- `ctx:skewBox(opts)`

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
- `ui.customButton(props)`

## Core Boundary

Use custom draw for game-specific UI. If a widget is visually specific to one game or example, keep it out of core and build it from primitives.
