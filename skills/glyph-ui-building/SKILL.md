# Glyph UI Building Skill

Use this skill when building screens, panels, HUDs, overlays, debug tools, examples, or app UI with Glyph.

## Mental Model

Glyph UI is:

```text
Lua components -> virtual tree -> layout -> event routing -> Love2D draw calls
```

Build with declarative components where useful, and use custom draw for game-specific visuals.

## Choosing Layout

Use:

- `ui.column` for vertical panels, forms, lists, inspectors, sidebars.
- `ui.row` for toolbars, table rows, split panes, button groups.
- `ui.stack` for layered UI, animated backgrounds, badges, overlays, floating controls, HUD composition.
- `ui.scrollView` for logs, tables, inspector rows, and long content.
- `ui.panel` for framed tool sections.

Do not use plain `ui.box` as a stack. If children need layout, use `row`, `column`, `stack`, or set `display`.

## Flex And Sizing

- Use `flex = 1` for “take remaining space.”
- Use `width = "100%"` or `height = "100%"` when the parent has known bounds.
- Use explicit width/height for fixed-format widgets.
- Use `ui.responsive`, `ui.viewport`, `ui.breakpoint`, `ui.columns`, and `ui.clamp` for resizable windows.
- Use `wrap = true` with a width for text that may overflow.

Example:

```lua
ui.row({ width = "100%", gap = 8 }, {
  ui.input({ flex = 1, value = filter, onChange = setFilter }),
  ui.button({ label = "Clear", onClick = clearFilter }),
})
```

## Stack And Absolute Patterns

Use `ui.stack` for layered game UI:

```lua
ui.stack({ width = "100%", height = "100%" }, {
  ui.box({
    position = "absolute",
    inset = 0,
    interactive = false,
    draw = drawBackground,
  }),

  ui.column({
    position = "absolute",
    top = 24,
    left = 24,
    gap = 8,
  }, {
    ui.text("Status"),
    ui.button({ label = "Open" }),
  }),
})
```

Rules:

- Absolute children do not affect parent size.
- Use `interactive = false` on decorative layers.
- Later children appear above earlier children unless `zIndex` changes the order.
- Use `inset = 0` for full-fill backgrounds.
- Use `right`/`bottom` for pinned HUD controls.

## Styling

Prefer `style` tables:

```lua
ui.button({
  label = "Run",
  variant = "primary",
  style = {
    background = { 0.1, 0.5, 0.9, 1 },
    color = { 1, 1, 1, 1 },
    borderWidth = 1,
    radius = 4,
    hover = { background = { 0.15, 0.6, 1, 1 } },
    pressed = { background = { 0.05, 0.35, 0.7, 1 } },
    transition = { background = 0.12 },
  },
})
```

Use theme variants for repeated visual language. Use inline style for one-off tuning.

## Custom Draw

Use custom draw for game-specific visuals rather than adding one-off widgets to Glyph core.

```lua
ui.box({
  width = 240,
  height = 64,
  draw = function(node, x, y, width, height, love, style, ctx)
    ctx:color(style.background)
    ctx:polygon("fill", ctx:skewBox({ skew = 16 }))
    ctx:color(ctx.hot and { 1, 1, 1, 1 } or style.color)
    ctx:text("COMMAND", x + 18, y + 22)
  end,
})
```

Use `ctx` helpers for color, rectangles, lines, polygons, text, pulse, hot/hover/pressed/focused state, and skew boxes.

## Scenes, Overlays, And Modals

Use scenes for screens:

```lua
ui.scene.set("main", MainScene, { transition = "none" })
ui.scene.push("pause", PauseMenu, {
  kind = "modal",
  width = 420,
  height = 260,
  dismissOnBackdrop = true,
  transition = ui.transitions.scale({ duration = 0.18 }),
})
```

Use:

- `ui.scene.set` for replacing the main screen.
- `ui.scene.push` for overlays, pushed screens, pause menus.
- `ui.modal.open` for dialog convenience.
- `blocking = false` and `input = false` for debug overlays that should not pause or intercept the game.
- `escapeToClose = false` for important modals that should require explicit action.

## Transitions

Built-ins:

- `ui.transitions.none`
- `ui.transitions.fade`
- `ui.transitions.slide`
- `ui.transitions.scale`

Use custom transitions for shaders, stencils, masks, or canvas effects:

```lua
local wipe = ui.transitions.custom({
  duration = 0.4,
  draw = function(ctx)
    local g = ctx.love.graphics
    g.stencil(function()
      g.circle("fill", ctx.bounds.x + ctx.bounds.width / 2, ctx.bounds.y + ctx.bounds.height / 2, ctx.progress * 600)
    end, "replace", 1)
    g.setStencilTest("equal", 1)
    ctx.drawLayer()
    g.setStencilTest()
  end,
})
```

Keep shape-specific transitions in examples or app code unless the primitive is broadly useful.

## Performance Patterns

- Use `ui.memo(component, deps)` for stable repeated subtrees.
- Use `ui.static(node)` for labels, icons, and fixed repeated rows.
- In long lists, mount only visible rows when possible.
- Keep custom draw cheap and avoid allocating large tables every frame in hot paths.
- Use scene layers and stack only where layering is needed.

## What Not To Do

- Do not add game-specific widgets to core Glyph.
- Do not use `ui.box` as an implicit layout container.
- Do not let decorative layers capture clicks.
- Do not build huge invisible lists when a scroll window can mount a visible slice.
- Do not use shader/stencil/canvas state without restoring it.
