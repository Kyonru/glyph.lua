---
icon: lucide/play
---

# Examples

Run examples with Love2D:

```sh
love examples/animations
love examples/audio-cues
love examples/basic
love examples/dashboard
love examples/hud-menu
love examples/hud-primitives
love examples/i18n
love examples/modal
love examples/navigate
love examples/scene
love examples/showcase
love examples/styles
love examples/themes
love examples/viewport
love examples/performance
```

## Animations

Flux-backed animation lab for declarative show/hide, animated meters, custom-drawn movement, selection feedback, and size tweens.

## Audio Cues

Theme and variant driven interaction cue events with app-owned Love2D tone playback, per-node overrides, and silent controls.

## Basic

Minimal component, state, button, input, and scroll usage.

## Dashboard

A dense shadcn-inspired dashboard translated into Glyph primitives. Useful for panels, metric cards, chart drawing, filters, tabs-style controls, and scrollable tables.

## HUD Menu

Custom-drawn game UI with animated command buttons. This example demonstrates what belongs in app/example code rather than Glyph core.

## HUD Primitives

Native meters, filled sweep gauges with centered overlays, d-pad/card navigation, shape descriptors, visual clipping, stencil masks, and dynamic backgrounds for game HUDs without adding game-specific core widgets.

## I18n

Backend-agnostic localization adapter demo with locale switching, keyed text/labels/placeholders/tabs, fallback text, cached parameter translations, and `ui.i18n.version()` in memo deps.

## Navigate

Arrow key and d-pad spatial navigation across a denser game-tool layout. Demonstrates
`ui.navigate`, beam-aware movement, `navGroup` scoping, trapped `navScope` submenus, focus
visibility, gamepad d-pad forwarding, and shader-backed JRPG command submenus.

## Modal

Scene-backed modals, moving background, shader transitions, stencil/blob transition implemented outside core, isolated modal hook state, and backdrop dismissal.

## Scene

Scene replacement, non-blocking debug overlays, blocking pause modal, modal-driven pause behavior, and scene-local motion.

## Showcase

A combined runnable app that keeps the standalone examples unchanged while
mounting their shared example modules into one scene-driven app. Use it to resize
one window and compare how the real demos adapt.

## Styles

Theme switching, variants, state styles, transitions, custom draw, and shader-backed styling.

## Themes

A full-screen game-tool HUD showing four theme presets, live radius/border/density/accent token controls, component variants, inputs, tabs, meters, and themed scrollbars.

## Viewport

Fixed virtual-resolution rendering with backend-agnostic Push/Shove adapters, scaled pointer input, fit/filter controls, scrolling, and modal rendering.

This demo uses development copies of Push and Shove from `dev/vendor`; Glyph apps should install or provide their own viewport backend.

## Performance

Large dataset workflow with a visible window of mounted rows, static row reuse, and timing display.

## Example Standards

Examples should show real UI workflows:

- Prefer usable screens over landing pages.
- Use Glyph primitives honestly.
- Keep game-specific visuals in examples, not core.
- Make interaction states visible.
- Keep examples runnable with `love examples/name`.
