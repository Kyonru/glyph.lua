# Love-Dialogue Vendor Snapshot

- Source: https://github.com/Miisan-png/Love-Dialogue
- License: MIT, as declared by the upstream `README.md` ("## License — MIT License")
- Vendored for: `examples/dialogue`

Included files:

- `LoveDialogue/` (the full library: `init.lua` plus its internal modules and the
  `plugins/` folder)

Glyph core does not depend on Love-Dialogue. This vendored copy only keeps the
`examples/dialogue` demo runnable without a separate install step. An app using
Glyph would provide its own copy of Love-Dialogue (for example via git submodule
or `luarocks`) rather than relying on this snapshot.

The upstream repository does not ship a standalone `LICENSE` file; the MIT grant
is stated in its `README.md`. To refresh this snapshot, clone the upstream repo
and copy its `LoveDialogue/` directory here.

This snapshot is **unmodified** — byte-for-byte upstream. Glyph's `ui.dialogue`
adapter adds the methods it needs (`renderModel`, `selectChoice`, `isFinished`,
and a renderless-aware `draw`) to each instance at runtime, so the vendored
library does not need to be edited.
