---
icon: lucide/book-open
---

# Glyph Documentation

Glyph is a declarative UI runtime for Love2D 11.x. It is designed for game tools, debugger panels, HUDs, overlays, and in-game menus.

## Start Here

- [Getting Started](getting-started.md)
- [Architecture & Mental Model](architecture.md)
- [Components](components.md)
- [Layout](layout.md)
- [Styling And Themes](styling.md)
- [Runtime, Hooks, And Events](runtime.md)

## Systems

- [Callback Bus](callback-bus.md)
- [Responsive Helpers](responsive.md)
- [Scenes And Modals](scenes-and-modals.md)
- [Transitions](transitions.md)
- [Custom Draw And Helpers](custom-draw.md)
- [Sprite Sheets](sprite-sheet.md)
- [Drag](drag.md)
- [Offscreen Surfaces](surface.md)
- [Performance](performance.md)
- [Examples](examples.md)

## Project Status

Glyph is **pre-1.0** (`dev`) and developed in the open. The API is largely
stable but may still change before a 1.0 tag; there is no formal changelog yet —
follow the Git history for changes.

A couple of things worth knowing up front (covered in
[Architecture](architecture.md)):

- A node's state, focus, and animation are tied to its **position in the tree**.
  When you render a dynamic list, give each item a stable `key` so its identity
  follows the data, not the index.
- Install by adding the repo to your Love2D project's `package.path` (see
  [Installation](installation.md)); a LuaRocks rockspec exists but is not the
  primary distribution path.

## Documentation Rule

Glyph is intended to become a public library. Any user-facing API, behavior change, subsystem, or example pattern should be documented in `docs/` as part of the same change.
