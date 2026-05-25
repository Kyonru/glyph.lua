# Glyph Development Guide

This repository is `glyph.lua`: a declarative UI runtime for Love2D 11.x, shaped for game tools, debugger panels, and in-game HUDs. Treat it as a small UI engine, not an app-specific widget pack.

## Project Shape

- Public entrypoint: `glyph.lua`
- Core runtime: `glyph/runtime.lua`
- Components: `glyph/components.lua`
- Layout engine: `glyph/layout.lua`
- Styling: `glyph/style.lua`, `glyph/theme.lua`
- Animation: `glyph/animation.lua`, vendored `glyph/vendor/flux.lua`
- Navigation: `glyph/navigate.lua`
- I18n/accessibility adapters: `glyph/i18n.lua`, `glyph/accessibility.lua`
- Fixed virtual viewport adapters: `glyph/viewport_backend.lua`
- Scene/modal layers: `glyph/scene.lua`, `glyph/modal.lua`, `glyph/transitions.lua`
- Type definitions: `glyph/types.lua` (LuaLS annotations, no runtime effect)
- LuaLS config: `.luarc.json`
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

This project uses [LuaLS annotations](https://luals.github.io/wiki/annotations/) for IDE type support. When adding or changing public API, annotate with `---@param`, `---@return`, `---@class`, etc. Shared types live in `glyph/types.lua`.

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
- Generic visual primitives: `meter`, shape descriptors, clipping/stencil masks, and draw context helpers.
- Layout primitives: flex row/column, stack/absolute layout, percent sizing, padding/gap, grow/flex, text wrapping.
- Runtime systems: hooks, memo/static helpers, event routing, focus/hover/press state, scroll state, callback bus.
- Input systems: pointer/touch, keyboard activation, spatial navigation, and opt-in digital gamepad mapping.
- Style systems: themes, variants, state styles, transitions, shaders, custom draw context, and audio cue metadata.
- Scene systems: scene stack, overlays, modals, layer transitions, input blocking/pass-through.
- Adapter systems: backend-agnostic i18n, accessibility semantics/events, optional Push/Shove fixed viewport support.
- Animation systems: first-class visual-only enter/exit animation powered by vendored Flux.
- Generic helpers for building custom game UI, such as draw context helpers and color/math helpers.

Keep game-specific widgets out of core. Examples may include things like HUD buttons, meters, blob transitions, particle backgrounds, animated menus, or game-themed controls, but core should expose the primitives that make those easy.

Good core API examples:

- `ui.stack`
- `ui.transitions.custom`
- `ui.scene.push`
- `ctx:polygon`
- `ui.meter`
- `ui.i18n.configure`
- `ui.accessibility.snapshot`
- `style.shader`

Poor core API examples:

- `ui.hudButton`
- `ui.personaMenu`
- `ui.healthBar`
- `ui.blobModal`
- `ui.finalFantasyMenu`
- `ui.personaHud`
- Any widget whose look or behavior belongs to one game or one example.

## Design Principles

- Prefer declarative Lua tables over CSS strings or selector systems.
- Keep layout props explicit and fast; keep visual styling in `style`.
- Preserve existing public APIs unless there is a clear reason to break them.
- Make static UI cheap: support `ui.memo`, `ui.static`, dirty flags, and stable layer roots.
- Prefer reusable draw/event/layout primitives over one-off components.
- Custom draw, shaders, stencil, and transitions are first-class because Glyph is for games.
- Avoid adding dependencies unless the abstraction boundary is clear. Flux is vendored for animation; Push/Shove are optional user-provided viewport backends. Yoga may be an optional backend later, but pure Lua remains the default.
- Public API changes require LuaLS annotations in `glyph/types.lua` and on touched functions in `glyph/`.

## Layout Rules

- `row` and `column` lay out children in flex flow.
- `stack` layers children; later children draw above earlier children unless `zIndex` changes the order.
- `position = "absolute"` removes a child from parent flow.
- Absolute children support `x`, `y`, `top`, `right`, `bottom`, `left`, `inset`, `zIndex`, width/height, percent sizes, and min/max sizes.
- Absolute children never determine parent size. Parent size must come from explicit dimensions, flex, percent size, or normal flow children.
- Plain `box` is a visual/container primitive. If children need layout, set `display = "row"`, `display = "column"`, or use `ui.stack`.
- Text with wrapping must draw with a numeric resolved width. Do not let percent-size strings leak into Love2D `printf`.

## Runtime And Input Rules

- Draw order and hit-test order must match. If a child visually appears above another child, it should receive pointer events first.
- Non-interactive decoration must set `interactive = false` so events pass through.
- Touch is installed automatically by `ui.install` / `ui.load`; gamepad mapping is opt-in with `install.gamepad = true` or manual `ui.gamepadpressed/released`.
- Mouse/touch and keyboard/gamepad activation should use the same press/release lifecycle so pressed styles, audio cues, and accessibility activation events stay consistent.
- Fixed viewport backends convert pointer coordinates before hit testing. Pointer events outside the virtual viewport should not hit UI.
- Spatial navigation should stay layout-agnostic. Use `navGroup` for soft grouping and `navScope`/`navTrap`/`onNavigateExit` for submenus.
- Scene layers route input top-down. Blocking layers stop input from reaching lower layers; non-blocking overlays pass through.
- Modals are scene layers with `kind = "modal"`, not a separate runtime.
- Escape should close the top eligible scene/modal layer unless `escapeToClose = false`.

## Adapter Systems

- I18n belongs in `glyph/i18n.lua` as a backend-agnostic adapter. Glyph should not own locale files, plural rules, or formatting policy.
- Cache no-param translations automatically. Cache parameterized translations only with explicit `cacheKey`; mutable params without `cacheKey` must resolve fresh.
- Accessibility belongs in `glyph/accessibility.lua` as metadata, snapshots, and events. Glyph should not pretend Love2D has native OS screen-reader widgets.
- Accessibility events are adapter-owned: apps decide whether to log, speak via TTS, bridge to native APIs, or expose DOM live regions in Love.js.
- Semantic props should resolve through i18n key props before snapshots, focus/activate events, and live-region announcements use them.
- Viewport support belongs in `glyph/viewport_backend.lua` behind `ui.viewportBackend`; do not add primary `ui.push` or `ui.shove` APIs.

## Styling Rules

- Prefer `style = { ... }` for visual concerns.
- Keep backward-compatible visual props working where already supported.
- Style precedence should remain: theme base, component defaults, variant, state, inline style.
- Use state tables for interaction: `hover`, `pressed`, `focused`, `active`, `disabled`.
- Shaders may be values or functions. Always restore Love2D graphics state after applying shader/blend/line/font/scissor/stencil changes.
- `style.audio` / component `audio` tables are cue metadata only. Glyph emits events; apps load and play sounds.
- `style.transition` is state-style interpolation; `enter`/`exit` animation props are visual-only node lifecycle animation.
- Shape, clip, stencil, and meter drawing must not alter layout or hit-testing geometry unless a later explicit API adds shape-aware hit tests.

## Animation Rules

- Animations are powered by vendored `rxi/flux` through `glyph/animation.lua`.
- Node `enter`/`exit` and `ui.transitions.animate` use the same animation spec shape.
- Animations are visual-only: they must not change layout, hit testing, focus/navigation geometry, or semantic snapshots.
- Apply transforms with graphics push/pop and transform around the node center. Opacity multiplies resolved style opacity.
- Exiting nodes may be retained as visual ghosts until exit completes. Avoid duplicate exit animations for descendants of an exiting parent.

## Example Standards

Examples should demonstrate real workflows, not marketing pages:

- `examples/accessibility`: semantic labels, snapshots, live regions, fake adapter log.
- `examples/animations`: enter/exit, movement, selection, size, and meter animation.
- `examples/audio-cues`: cue metadata and app-owned sound playback.
- `examples/basic`: minimal API usage.
- `examples/performance`: large data, memo/static, bounded work.
- `examples/styles`: themes, variants, transitions, shader styling.
- `examples/dashboard`: dense debugger/admin UI.
- `examples/hud-primitives`: meters, shapes, clipping, stencil, dynamic HUD panels.
- `examples/i18n`: backend-agnostic translation, cache keys, memoization.
- `examples/hud-menu`: custom draw and animated game UI.
- `examples/modal`: scene-backed modals, custom shader/stencil transitions, moving background.
- `examples/navigate`: spatial navigation, nav scopes, submenu patterns.
- `examples/scene`: scene replacement, overlays, pause modal, paused/unpaused motion.
- `examples/themes`: complex theme presets and token tweaks.
- `examples/viewport`: optional fixed virtual viewport adapters.

When adding an example, use Glyph’s real primitives and keep it runnable with `love examples/name`.

## Testing Expectations

Add tests when touching shared behavior:

- Layout changes: `spec/layout_spec.lua`
- Runtime input/render changes: `spec/runtime_spec.lua`
- Scene/modal behavior: `spec/modal_spec.lua`
- Style/theme behavior: `spec/style_spec.lua`
- Callback bus behavior: `spec/callback_bus_spec.lua`
- Install/load callback behavior: `spec/install_spec.lua`
- Navigation behavior: `spec/navigate_spec.lua`
- I18n, accessibility, helper primitives: `spec/ui_helpers_spec.lua`

For layout and input changes, test both the geometry and the interaction result.

## Documentation Expectations

Glyph is intended to be a public library. Every change that adds or changes public API, subsystem behavior, example patterns, or user-facing constraints must update `docs/` in the same change.

At minimum:

- New component or prop: update `docs/components.md` or `docs/layout.md`.
- Style/theme change: update `docs/styling.md`.
- Runtime, hooks, or input behavior: update `docs/runtime.md`.
- Scene/modal/transition behavior: update `docs/scenes-and-modals.md` or `docs/transitions.md`.
- Navigation/focus behavior: update `docs/navigation.md`.
- I18n behavior: update `docs/i18n.md`.
- Accessibility behavior: update `docs/accessibility.md`.
- Fixed viewport behavior: update `docs/responsive.md` and `docs/runtime.md` when input conversion changes.
- Performance pattern: update `docs/performance.md`.
- New example: update `docs/examples.md`.

If a change needs tests, it probably needs documentation too.
If a change introduces a new subsystem, public workflow, reusable example pattern,
or recurring implementation rule, update `AGENTS.md` and the relevant local skill
in `skills/` so future agents inherit the guidance.

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
- Do not vendor optional libraries like Push/Shove into Glyph core; examples may use `dev/vendor`, apps should provide instances or modules.
- Do not make i18n or accessibility own app policy. They are adapters and metadata/event surfaces.
