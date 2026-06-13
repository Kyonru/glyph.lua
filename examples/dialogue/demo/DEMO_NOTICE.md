# Love-Dialogue Demo Snapshot

- Source: https://github.com/Miisan-png/Love-Dialogue/tree/main/demo
- License: MIT, as declared by the upstream `README.md`
- Vendored for: `examples/dialogue`

This is a snapshot of the upstream `demo/` folder (scripts, character atlases,
sfx, and UI assets) so `examples/dialogue` can run the real Love-Dialogue demo
without a separate install step. `examples/dialogue/example.lua` is a port of the
upstream `demo/main.lua` adapted to the Glyph example runner.

Differences from upstream:

- `assets/font/fusion_pixel_font.ttf` (and its `font/LICENSE/`, `font/OFL.txt`)
  is **not** vendored. The demo config and `theme.ld` set no font path, so the
  demo runs on Love2D's default font and the ~2.8 MB TTF would be unused.
- `demo/main.lua` is replaced by `../example.lua` (the Glyph-hosted port).

Paths inside the scripts and config (for example `demo/scripts/story.ld` and
`demo/assets/ui/indicator.png`) are kept verbatim, so they resolve relative to
the Love2D source root when the example is run with `love examples/dialogue`.
