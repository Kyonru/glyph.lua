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

The `ui.dialogue` **adapter** needs no library changes: it adds the methods it
uses (`renderModel`, `selectChoice`, `isFinished`, and a renderless-aware `draw`)
to each instance at runtime.

## Local patches

This snapshot carries one small, upstreamable gameplay fix (marked
`-- Glyph patch` in the source), otherwise it is upstream:

- `LoveDialogue/LoveDialogue.lua` — `[move:]` now **blocks** until its tween
  completes (mirroring how `[fade:]` already pauses processing), so consecutive
  `[move:]` commands play in sequence (e.g. a bounce) instead of all starting at
  once and cancelling out. Upstream processes `[move:]` non-blocking, which makes
  chained moves overwrite each other on the same character.

This patch is unrelated to the adapter — it fixes demo motion and is a good
upstream PR candidate.
