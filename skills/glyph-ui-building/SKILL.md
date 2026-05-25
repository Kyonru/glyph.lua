---
name: glyph-ui-building
description: Use when building Glyph examples, game HUDs, panels, overlays, menus, accessible/localized UI, animated or juicy feedback screens, themed demos, or Love2D UI workflows.
---

# Glyph UI Building Skill

Use this skill when building screens, panels, HUDs, overlays, debug tools, examples, or app UI with Glyph.

## Mental Model

Glyph UI is:

```text
Lua components -> virtual tree -> layout -> event routing -> Love2D draw calls
```

Build with declarative components where useful, and use custom draw for game-specific visuals.

Core owns primitives. Game-specific look belongs in examples/app code.

## Choosing Layout

Use:

- `ui.column` for vertical panels, forms, lists, inspectors, sidebars.
- `ui.row` for toolbars, table rows, split panes, button groups.
- `ui.stack` for layered UI, animated backgrounds, badges, overlays, floating controls, HUD composition.
- `ui.scrollView` for logs, tables, inspector rows, and long content.
- `ui.panel` for framed tool sections.
- `ui.meter` for generic progress, HP/MP, cooldowns, gauges, arcs, and radial values.

Do not use plain `ui.box` as a stack. If children need layout, use `row`, `column`, `stack`, or set `display`.

## Flex And Sizing

- Use `flex = 1` for “take remaining space.”
- Use `width = "100%"` or `height = "100%"` when the parent has known bounds.
- Use explicit width/height for fixed-format widgets.
- Use `ui.responsive`, `ui.viewport`, `ui.breakpoint`, `ui.columns`, and `ui.clamp` for resizable windows.
- Use `wrap = true` for text that may overflow. If setting a text width, prefer numeric or resolved widths; avoid passing percent width strings into wrapped text draw paths.
- Use theme typography presets (`textStyle`, `ui.h1`, `ui.h2`, `ui.p`, `ui.caption`) for repeated type hierarchy, and `ui.richText` only when SYSL-backed rich/game text is needed.
- Use stable dimensions or aspect ratios for fixed-format widgets like gauges, command buttons, grids, and HUD cards.

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

Use theme typography for repeated text language:

```lua
ui.h1("Mission Briefing")
ui.p("Hold the point until extraction.", { wrap = true, width = "100%" })
ui.richText("Status: [color=#7cffae]online[/color]", { wrap = true, width = 320 })
```

Configure `ui.richTextBackend` with an app-provided SYSL module before using
rich text. Dialogue pacing, sound/image tags, and typewriter effects belong in
app/example code unless the user specifically asks for a text engine.

Interaction states should be visually obvious:

- `hover` for pointer hover.
- `pressed` for mouse/touch down and keyboard/gamepad confirm down.
- `focused` for keyboard/d-pad/gamepad navigation.
- `active` for selected/toggled state.
- `disabled` for unavailable controls.

When a control is both active and focused, focused/highlighted visuals should remain clearly visible.

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

Use `ctx` helpers for color, rectangles, lines, polygons, shapes, clips, stencils, meters, text, pulse, hot/hover/pressed/focused state, and skew boxes.

For Persona-style or JRPG-style HUD shapes, prefer generic primitives:

- `shape = { kind = "skew", skew = 12 }`
- `shape = { kind = "blob", points = 10, variance = 0.14, seed = "command" }`
- `clip = true` or `clip = shape`
- `stencil = { shape = ..., mode = "inside" }`
- `ctx:shape`, `ctx:clip`, `ctx:stencil`, and `ctx:meter`

Decorative layers should use `interactive = false` and usually `accessibilityHidden = true`.

## Meters And Gauges

Use `ui.meter` for generic value displays:

```lua
ui.meter({
  value = hp,
  max = maxHp,
  width = 180,
  height = 14,
  shape = { kind = "skew", skew = 10 },
  fillStyle = { background = { 0.1, 0.9, 0.55, 1 } },
})
```

For radial or arc gauges, add centered content as children:

```lua
ui.meter({
  kind = "arc",
  value = charge,
  max = 100,
  width = 72,
  height = 72,
  thickness = 8,
}, {
  ui.text("EX"),
})
```

Keep “health bar” as an app/example pattern, not a core component.

## Navigation And Submenus

Wire arrows or d-pad to `ui.navigate` unless using opt-in gamepad install:

```lua
function love.keypressed(key)
  if key == "up" then return ui.navigate("up") end
  if key == "down" then return ui.navigate("down") end
  if key == "left" then return ui.navigate("left") end
  if key == "right" then return ui.navigate("right") end
  return ui.keypressed(key)
end
```

Submenus are ordinary containers with scope props:

- `navScope = true` on the submenu root.
- `navTrap = true` while open.
- `onNavigateExit` to close/return focus to the opener.

Do not build an opinionated `ui.menu` unless the user explicitly asks for app code.

## Animation

Use node `enter`/`exit` for show/hide and `ui.transitions.animate` for scenes or modals. Animations are visual-only, so layout and hit testing should remain stable.

```lua
ui.panel({
  key = "inventory",
  enter = { from = { opacity = 0, y = 16 }, to = { opacity = 1, y = 0 } },
  exit = { to = { opacity = 0, y = -12 } },
}, children)
```

When animating size in examples, include real content and let layout handle spacing with rows/columns/gaps rather than manual overlap calculations.

## Feedback And Juice

Use `ui.feedback` for game-feel stacks that respond to interaction without creating app-specific widgets:

```lua
ui.feedback.define("button.pop", {
  { kind = "animate", to = { scaleX = 1.08, scaleY = 0.92 }, duration = 0.06 },
  { kind = "audio", cue = "ui-pop" },
  { kind = "emit", event = "particles", name = "spark" },
  { kind = "animate", to = { scale = 1 }, duration = 0.16, ease = "backout" },
})

ui.button({
  label = "Play",
  feedback = {
    hover = "button.hover",
    press = "button.squash",
    release = "button.release",
    activate = "button.pop",
  },
})
```

Keep particles, shake, splats, haptics, and sound playback in app/example code by listening for `"feedback"` and `"audio"` events. Use custom draw, blob shapes, clipping, and stencil masks for organic buttons or ink reveals; avoid adding `ui.splatButton`-style widgets to core.

## I18n

Use `ui.i18n.configure` with an app-owned translator. Glyph does not own locale files or pluralization policy.

Use keyed props:

- `textKey`
- `labelKey`
- `placeholderKey`
- `titleKey`
- semantic accessibility keys like `accessibilityLabelKey`

For params, provide `cacheKey` when the translation is stable:

```lua
ui.textKey("messages", {
  textParams = { count = count },
  textCacheKey = "messages:" .. count,
})
```

Use `ui.i18n.version()` in `ui.memo` deps for translated static subtrees.

## Accessibility

Love2D has no native screen-reader widgets. Glyph provides semantics and events; apps own TTS, logs, platform bridges, or Love.js live regions.

Add useful semantic props:

```lua
ui.button({
  labelKey = "actions.launch",
  accessibilityLabelKey = "a11y.launch",
  accessibilityDescriptionKey = "a11y.launch_help",
})
```

Use:

- `role`
- `accessibilityLabel`
- `accessibilityDescription`
- `accessibilityValueText`
- `accessibilityHidden`
- `accessibilityLive`

Listen with `ui.on("accessibility", fn)` for focus, activate, live, and manual announcements. Use `ui.accessibility.snapshot()` when building debug/adaptor panels.

## Audio Cues

Glyph emits cue events; apps play sounds.

Set global cues in theme component defaults or variants, override per node, or disable with `audio = false`:

```lua
ui.on("audio", function(event)
  sounds[event.cue]:play()
end)
```

Keep cue values as stable app-owned string IDs.

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

Use `ui.transitions.animate({ enter = ..., exit = ... })` when a scene/modal transition should share animation specs with nodes.

## Fixed Virtual Viewports

If an app uses Push or Shove, configure Glyph through `window.viewport` or attach an existing backend instance. Keep the UI in virtual coordinates and compare with `ui.viewport()`.

Do not expose Push/Shove-specific assumptions in examples unless the example is specifically about viewport backends.

## Performance Patterns

- Use `ui.memo(component, deps)` for stable repeated subtrees.
- Use `ui.static(node)` for labels, icons, and fixed repeated rows.
- Use i18n cache keys and `ui.i18n.version()` to keep translated subtrees cheap.
- In long lists, mount only visible rows when possible.
- Keep custom draw cheap and avoid allocating large tables every frame in hot paths.
- Use scene layers and stack only where layering is needed.

## What Not To Do

- Do not add game-specific widgets to core Glyph.
- Do not use `ui.box` as an implicit layout container.
- Do not let decorative layers capture clicks.
- Do not build huge invisible lists when a scroll window can mount a visible slice.
- Do not use shader/stencil/canvas state without restoring it.
- Do not put interactive behavior on decorative backgrounds.
- Do not hide important text only inside custom draw; expose semantics when needed.

## Skill Maintenance

When a new example introduces a reusable UI pattern, accessibility/i18n/audio/navigation convention, or design rule that future examples should follow, update this skill. If the pattern is about core internals rather than app/example UI, update `glyph-development` instead.
