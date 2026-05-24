# Glyph Development Skill

Use this skill when changing Glyph internals: components, layout, runtime, style resolution, scenes/modals, transitions, callback bus, or performance behavior.

## First Pass

1. Read the relevant module before editing.
2. Check nearby specs for expected behavior.
3. Identify whether the change is a core primitive, an example-only pattern, or game-specific sugar.
4. Keep the public API small and composable.
5. Update `docs/` for any public API, behavior, subsystem, or example pattern change.

Core belongs in `glyph/` only when it is reusable across many games and tools. Game-specific widgets and visual motifs belong in `examples/`.

## Core Boundaries

Add to core:

- Layout primitives and constraints.
- Event routing and focus/hover/press behavior.
- Generic style, theme, shader, and transition hooks.
- Scene/layer/modal mechanics.
- Generic custom-draw helpers.

Keep out of core:

- Persona-style menu widgets.
- Health/mana meters.
- Blob-specific transitions.
- Dashboard-specific cards or tables.
- Feather-specific inspectors, logs, or debugger panels.

If a feature feels specific, implement it as an example using existing primitives. If that example reveals missing primitives, add the primitive instead.

## Layout Work

The layout engine is pure Lua in `glyph/layout.lua`.

Follow these rules:

- `row` and `column` own flex flow.
- `stack` owns layered children.
- `position = "absolute"` removes a child from flow.
- Absolute children never affect parent size.
- Percent sizes resolve against available/content bounds, not strings carried into arithmetic.
- Text wrapping must use measurement hooks and should not assume Love2D exists in tests.

When layout changes, add focused tests in `spec/layout_spec.lua`.

## Runtime Work

The runtime in `glyph/runtime.lua` owns:

- Hook state.
- Tree building.
- Layout invocation.
- Draw traversal.
- Hit testing.
- Focus, hover, press, input, scroll state.
- Scene layer rendering.

Draw order and hit order must match. If `zIndex` or stack order changes drawing, hit testing must follow the same order in reverse.

For input changes, add runtime tests that press and release controls, not just geometry assertions.

## Scene And Modal Work

Scenes live in `glyph/scene.lua`; modals are wrappers in `glyph/modal.lua`.

Keep this invariant:

- Modals are scene layers.
- Layers own hook scopes.
- Transitions receive context and call `ctx.drawLayer()`.
- Blocking layers stop input from reaching lower layers.
- Non-blocking overlays pass input through.

Do not reintroduce a separate modal runtime.

## Style And Draw Work

Style resolution lives in `glyph/style.lua`; defaults live in `glyph/theme.lua`.

Rules:

- Prefer `style` tables for visual fields.
- Keep state style tables explicit: `hover`, `pressed`, `focused`, `active`, `disabled`.
- Custom draw receives `style` and `ctx`.
- Any shader, blend, line width, font, scissor, stencil, canvas, or transform mutation must be restored.

## Performance Work

Glyph is for debug panels and game UI, so avoid needless rebuilds and layout churn.

- Preserve `ui.memo` and `ui.static` behavior.
- Keep dirty flags meaningful.
- Avoid selector systems, cascading ancestry scans, string parsing, or global style queries.
- Prefer stable layer roots and stable subtree identity where possible.
- Examples should show bounded rendering for large lists.

## Verification

Run:

```sh
.luarocks/bin/busted
```

For syntax checks:

```sh
luac -p glyph.lua glyph/*.lua examples/*/main.lua spec/*_spec.lua
```

When a Love2D visual behavior changes, update or add an example that makes the behavior obvious.

Documentation is required for public-library work. Update the matching `docs/*.md` page before finishing.
