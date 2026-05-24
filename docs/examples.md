---
icon: lucide/play
---

# Examples

Run examples with Love2D:

```sh
love examples/basic
love examples/dashboard
love examples/hud-menu
love examples/modal
love examples/scene
love examples/styles
love examples/performance
```

## Basic

Minimal component, state, button, input, and scroll usage.

## Dashboard

A dense shadcn-inspired dashboard translated into Glyph primitives. Useful for panels, metric cards, chart drawing, filters, tabs-style controls, and scrollable tables.

## HUD Menu

Custom-drawn game UI with animated command buttons. This example demonstrates what belongs in app/example code rather than Glyph core.

## Modal

Scene-backed modals, moving background, shader transitions, stencil/blob transition implemented outside core, isolated modal hook state, and backdrop dismissal.

## Scene

Scene replacement, non-blocking debug overlays, blocking pause modal, modal-driven pause behavior, and scene-local motion.

## Styles

Theme switching, variants, state styles, transitions, custom draw, and shader-backed styling.

## Performance

Large dataset workflow with a visible window of mounted rows, static row reuse, and timing display.

## Example Standards

Examples should show real UI workflows:

- Prefer usable screens over landing pages.
- Use Glyph primitives honestly.
- Keep game-specific visuals in examples, not core.
- Make interaction states visible.
- Keep examples runnable with `love examples/name`.
