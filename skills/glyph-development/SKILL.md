---
name: glyph-development
description: Use when changing glyph.lua internals, public APIs, runtime behavior, layout, styling, animation, feedback, navigation, i18n, accessibility, viewport backends, tests, or docs.
---

# Glyph Development Skill

Use this skill when changing Glyph internals: components, layout, runtime, style resolution, scenes/modals, transitions, animation, feedback, navigation, i18n, accessibility, viewport backends, callback bus, or performance behavior.

## First Pass

1. Read the relevant module before editing.
2. Check nearby specs for expected behavior.
3. Identify whether the change is a core primitive, an example-only pattern, or game-specific sugar.
4. Keep the public API small and composable.
5. Add or update LuaLS annotations for public API and touched internal helpers.
6. Update `docs/` for any public API, behavior, subsystem, or example pattern change.

Core belongs in `glyph/` only when it is reusable across many games and tools. Game-specific widgets and visual motifs belong in `examples/`.

## Core Boundaries

Add to core:

- Layout primitives and constraints.
- Event routing and focus/hover/press behavior.
- Generic style, theme, shader, and transition hooks.
- Generic meters, shapes, clipping, stencil, and custom draw helpers.
- Theme-driven typography, font refs, text scaling, and optional SYSL-backed rich text.
- Scene/layer/modal mechanics.
- Spatial navigation primitives and opt-in gamepad mapping.
- Backend-agnostic i18n and accessibility adapter surfaces.
- Backend-agnostic fixed viewport adapter hooks.
- Visual-only animation primitives.
- Modular feedback primitives for node animation, audio cue metadata, callbacks, and app-owned FX events.

Keep out of core:

- Persona-style menu widgets.
- Health/mana-specific widgets; use generic `ui.meter`.
- Branded blob/splat/sticker button widgets.
- Push/Shove-specific public APIs such as `ui.push` or `ui.shove`.
- Native screen-reader, TTS, locale-file, plural-rule, or app-policy ownership.
- Dashboard-specific cards or tables.
- Feather-specific inspectors, logs, or debugger panels.
- Full app-owned dialogue/textbox policy, sound/image assets, or branded text effects.

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
- Wrapped text drawing must use a numeric resolved width; avoid passing percent strings to `love.graphics.printf`.

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
- Audio cue and accessibility event emission.
- Feedback trigger lifecycle and event emission.
- Viewport coordinate conversion for pointer/touch input.

Draw order and hit order must match. If `zIndex` or stack order changes drawing, hit testing must follow the same order in reverse.

For input changes, add runtime tests that press and release controls, not just geometry assertions.

Keyboard, mouse, touch, and mapped gamepad activation should share the same press/release lifecycle so pressed styles, audio cues, and accessibility activation remain consistent.

## Navigation And Input

Spatial navigation lives in `glyph/navigate.lua`.

- Keep `ui.navigate(direction)` and `navGroup` backward compatible.
- Use beam-aware movement and edge distance for uneven game-style layouts.
- `navGroup` is soft: stay inside when a directional candidate exists, escape when it does not.
- `navScope` is layout-agnostic. Use `navTrap` and `onNavigateExit` for submenus/flyouts without creating menu widgets.
- Gamepad mapping is opt-in through `install.gamepad` or manual `ui.gamepadpressed/released`.
- Touch callbacks remain automatic through install/load.

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
- `style.audio` and component `audio` tables are cue metadata; core emits events only.
- Shape/clip/stencil/meter drawing is visual-only. Hit testing remains rectangular unless an explicit shape-hit API is added later.

## Typography Work

Typography lives in `glyph/typography.lua` and is shared by layout and runtime drawing. SYSL-backed rich text uses `glyph/rich_text_backend.lua`.

- Keep `ui.text` plain by default; rich text is opt-in through `ui.richText` / `format = "sysl"`.
- Resolve text through theme typography presets, registered fonts, and `theme.textScale` before measuring and drawing.
- Font refs may be Love font objects, theme font names, or lazy font specs; do not load fonts repeatedly in component builds.
- Do not add a custom rich text parser in core. Delegate rich/game text to app-provided SYSL and use textbox `get.width`, `get.height`, and `get.lines` for layout.
- Keep SYSL optional and user-provided for apps; examples may use `dev/vendor`.
- Disable SYSL function/scripting commands by default. Apps that intentionally enable them should own that risk in app code.

## Animation Work

Animation lives in `glyph/animation.lua` and uses vendored Flux.

- Node `enter`/`exit` and `ui.transitions.animate` share animation specs.
- Animations are visual-only and must not affect layout, hit testing, focus, navigation geometry, or semantic snapshots.
- Apply transforms with graphics push/pop and restore state.
- Exit ghosts should render only until exit completes; avoid duplicate descendant exits for an exiting parent.

## Feedback Work

Feedback lives in `glyph/feedback.lua`.

- Public API is `ui.feedback`, not `ui.juice`.
- Feedback steps should stay generic: `animate`, `audio`, `emit`, and `callback`.
- Feedback animation composes with node animation and remains visual-only.
- Trigger hooks should follow the shared lifecycle: hover enter, focus enter, press down, release up, activate before successful button click.
- Disabled controls should not emit press/release/activate feedback.
- `emit` steps dispatch app-owned `"feedback"` events for particles, shake, haptics, splats, or custom shader systems.
- Core should not own particles, cameras, sound playback, or branded visual widgets.
- Generic blob shape support is acceptable; more specific shape packs should start in examples.

## Adapter Work

I18n lives in `glyph/i18n.lua`.

- Do not own translation tables, locale files, plural rules, number/date formatting, or fallback policy.
- Cache no-param translations automatically.
- Cache param translations only with explicit `cacheKey`; mutable params without a key must resolve fresh.
- Locale changes must invalidate cache, bump version, and mark runtime dirty.

Accessibility lives in `glyph/accessibility.lua`.

- Do not pretend Love2D has native OS widgets. Expose semantic metadata, snapshots, focus/activate/live events, and let apps adapt them.
- Hidden or `role = "none"` nodes should not appear in snapshots or announcements.
- Semantic key props resolve through `ui.i18n`.
- Live regions announce changes after initial build, not on first mount.

Viewport support lives in `glyph/viewport_backend.lua`.

- Keep Push/Shove optional and user-provided. Development examples may use `dev/vendor`.
- Public API is `ui.viewportBackend`; backend-specific escape hatch is `raw()`.
- Managed mode may configure backend/window; attached mode must not mutate app-owned setup.

## Performance Work

Glyph is for debug panels and game UI, so avoid needless rebuilds and layout churn.

- Preserve `ui.memo` and `ui.static` behavior.
- Keep dirty flags meaningful.
- Avoid selector systems, cascading ancestry scans, string parsing, or global style queries.
- Prefer stable layer roots and stable subtree identity where possible.
- Examples should show bounded rendering for large lists.

## Types And Docs

- Shared public types live in `glyph/types.lua`.
- Add `---@param`, `---@return`, and `---@class` annotations when adding/changing public APIs or substantial internal helpers.
- New docs pages need `lucide/*` frontmatter and `zensical.toml` nav entries.
- Use GitHub callouts (`> [!NOTE]`) rather than `!!! note`.
- When introducing a new subsystem, public workflow, reusable example pattern, or recurring implementation rule, update `AGENTS.md` and the relevant `skills/*/SKILL.md`.
- Create a new local skill only when the workflow is distinct enough that future agents should load it separately; otherwise update `glyph-development` or `glyph-ui-building`.

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

If the local Lua toolchain is unavailable, still run `git diff --check` and clearly report blocked `busted`/`luac` commands.
