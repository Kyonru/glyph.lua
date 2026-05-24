# Glyph Development Guide

This repository is `glyph.lua`: a declarative UI runtime for Love2D 11.x, shaped for game tools, debugger panels, and in-game HUDs. Treat it as a small UI engine, not an app-specific widget pack.

## Project Shape

- Public entrypoint: `glyph.lua`
- Core runtime: `glyph/runtime.lua`
- Components: `glyph/components.lua`
- Layout engine: `glyph/layout.lua`
- Styling: `glyph/style.lua`, `glyph/theme.lua`
- Scene/modal layers: `glyph/scene.lua`, `glyph/modal.lua`, `glyph/transitions.lua`
- Examples: `examples/*/main.lua`
- Tests: `spec/*_spec.lua`
- Public docs: `docs/*.md`

Run tests with:

```sh
make test
# or directly: .luarocks/bin/busted
```

Syntax-check Lua files with:

```sh
luac -p glyph.lua glyph/*.lua examples/*/main.lua spec/*_spec.lua
```

Run an example:

```sh
make <example>   # e.g. make settings, make modal
```

Serve docs locally:

```sh
make docs
```

## What Belongs In Glyph

Glyph should provide primitives and reusable systems:

- Core components: `text`, `box`, `stack`, `row`, `column`, `button`, `input`, `scrollView`, `tabs`, `panel`.
- Layout primitives: flex row/column, stack/absolute layout, percent sizing, padding/gap, grow/flex, text wrapping.
- Runtime systems: hooks, memo/static helpers, event routing, focus/hover/press state, scroll state, callback bus.
- Style systems: themes, variants, state styles, transitions, shaders, custom draw context.
- Scene systems: scene stack, overlays, modals, layer transitions, input blocking/pass-through.
- Generic helpers for building custom game UI, such as draw context helpers and color/math helpers.

Keep game-specific widgets out of core. Examples may include things like HUD buttons, meters, blob transitions, particle backgrounds, animated menus, or game-themed controls, but core should expose the primitives that make those easy.

Good core API examples:

- `ui.stack`
- `ui.transitions.custom`
- `ui.scene.push`
- `ctx:polygon`
- `style.shader`

Poor core API examples:

- `ui.hudButton`
- `ui.personaMenu`
- `ui.healthBar`
- `ui.blobModal`
- Any widget whose look or behavior belongs to one game or one example.

## Design Principles

- Prefer declarative Lua tables over CSS strings or selector systems.
- Keep layout props explicit and fast; keep visual styling in `style`.
- Preserve existing public APIs unless there is a clear reason to break them.
- Make static UI cheap: support `ui.memo`, `ui.static`, dirty flags, and stable layer roots.
- Prefer reusable draw/event/layout primitives over one-off components.
- Custom draw, shaders, stencil, and transitions are first-class because Glyph is for games.
- Avoid adding dependencies unless the abstraction boundary is clear. Yoga may be an optional backend later, but pure Lua remains the default.

## Layout Rules

- `row` and `column` lay out children in flex flow.
- `stack` layers children; later children draw above earlier children unless `zIndex` changes the order.
- `position = "absolute"` removes a child from parent flow.
- Absolute children support `x`, `y`, `top`, `right`, `bottom`, `left`, `inset`, `zIndex`, width/height, percent sizes, and min/max sizes.
- Absolute children never determine parent size. Parent size must come from explicit dimensions, flex, percent size, or normal flow children.
- Plain `box` is a visual/container primitive. If children need layout, set `display = "row"`, `display = "column"`, or use `ui.stack`.

## Runtime And Input Rules

- Draw order and hit-test order must match. If a child visually appears above another child, it should receive pointer events first.
- Non-interactive decoration must set `interactive = false` so events pass through.
- Scene layers route input top-down. Blocking layers stop input from reaching lower layers; non-blocking overlays pass through.
- Modals are scene layers with `kind = "modal"`, not a separate runtime.
- Escape should close the top eligible scene/modal layer unless `escapeToClose = false`.

## Styling Rules

- Prefer `style = { ... }` for visual concerns.
- Keep backward-compatible visual props working where already supported.
- Style precedence should remain: theme base, component defaults, variant, state, inline style.
- Use state tables for interaction: `hover`, `pressed`, `focused`, `active`, `disabled`.
- Shaders may be values or functions. Always restore Love2D graphics state after applying shader/blend/line/font/scissor/stencil changes.

## Example Standards

Examples should demonstrate real workflows, not marketing pages:

- `examples/basic`: minimal API usage.
- `examples/performance`: large data, memo/static, bounded work.
- `examples/styles`: themes, variants, transitions, shader styling.
- `examples/dashboard`: dense debugger/admin UI.
- `examples/hud-menu`: custom draw and animated game UI.
- `examples/modal`: scene-backed modals, custom shader/stencil transitions, moving background.
- `examples/scene`: scene replacement, overlays, pause modal, paused/unpaused motion.

When adding an example, use Glyph’s real primitives and keep it runnable with `love examples/name`.

## Testing Expectations

Add tests when touching shared behavior:

- Layout changes: `spec/layout_spec.lua`
- Runtime input/render changes: `spec/runtime_spec.lua`
- Scene/modal behavior: `spec/modal_spec.lua`
- Style/theme behavior: `spec/style_spec.lua`
- Callback bus behavior: `spec/callback_bus_spec.lua`
- Install/load callback behavior: `spec/install_spec.lua`

For layout and input changes, test both the geometry and the interaction result.

## Documentation Expectations

Glyph is intended to be a public library. Every change that adds or changes public API, subsystem behavior, example patterns, or user-facing constraints must update `docs/` in the same change.

At minimum:

- New component or prop: update `docs/components.md` or `docs/layout.md`.
- Style/theme change: update `docs/styling.md`.
- Runtime, hooks, or input behavior: update `docs/runtime.md`.
- Scene/modal/transition behavior: update `docs/scenes-and-modals.md` or `docs/transitions.md`.
- Performance pattern: update `docs/performance.md`.
- New example: update `docs/examples.md`.

If a change needs tests, it probably needs documentation too.

When writing docs:

- Use `> [!NOTE]` / `> [!TIP]` / `> [!WARNING]` callout syntax. Never use `!!! note` admonition
  syntax — the formatter strips its required indentation on save.
- Do not put fenced code blocks inside a callout. Place them after as a top-level block.
- Every new `docs/*.md` file needs a `lucide/*` icon in YAML frontmatter and an entry in the
  `nav` array in `zensical.toml`.

## Common Pitfalls

- Do not use a plain `ui.box` as a stack. Use `ui.stack`.
- Do not let absolute children affect row/column size.
- Do not add game-specific components to `glyph/components.lua`.
- Do not bypass style resolution in draw code unless there is a measured reason.
- Do not make modal-specific hook logic; use generic scene/layer hook scopes.
- Do not forget graphics state restoration around shader/stencil/custom transition code.
