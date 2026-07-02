# Product

## Register

product

## Users

Game developers and tool builders using Love2D who need reliable in-game UI primitives for HUDs, inventory flows, menus, debugger panels, scene overlays, and editor-like controls. They are usually working inside a running game loop, tuning interactions where input, visual feedback, and readable state matter more than marketing gloss.

## Product Purpose

Glyph is a small declarative UI runtime for Love2D 11.x. It exists to make game-shaped interfaces easier to build from reusable primitives: layout, styling, input routing, navigation, animation, feedback, scenes, accessibility metadata, i18n adapters, and custom drawing. Success means examples feel like practical patterns that can be lifted into real games without dragging game-specific widgets into core.

## Brand Personality

Capable, tactile, and pragmatic. Glyph should feel like a craft tool for game UI: direct, responsive, readable, and expressive where interaction benefits from game feel.

## Anti-references

Avoid generic SaaS dashboards, marketing-page hero composition, ornamental card grids, game-specific core widgets, and example UI that looks detached from a real workflow. Avoid over-decorated controls that obscure state, text that clips at small windows, and visual effects that do not support interaction.

## Design Principles

- Demonstrate workflows, not showcases: examples should model real game UI problems such as inventory management, HUD state, navigation, feedback, and drag/drop.
- Keep core reusable: examples can be themed and game-specific, but core APIs should remain primitive and composable.
- Preserve task clarity: state, target areas, selected items, and allowed actions should be legible at a glance.
- Let feedback teach the system: hover, focus, drag, drop, invalid placement, and success states should explain themselves through restrained motion and color.
- Stay responsive within declared windows: examples must avoid clipping, overlap, and fragile fixed-position layouts.

## Accessibility & Inclusion

Prefer readable contrast, keyboard/gamepad reachable controls, focus states, semantic labels where available, and reduced-motion-friendly feedback. Glyph exposes accessibility metadata and events, while apps own the adapter policy.
