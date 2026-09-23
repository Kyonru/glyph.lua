---
icon: lucide/package
---

# Installation

Four ways to add glyph to your Love2D project.

---

## Option 1 — Feather (recommended)

[Feather](https://kyonru.github.io/feather/) is a curated package installer for LÖVE libraries.
It verifies every install with a SHA-256 checksum and records exact versions in a lockfile.

```sh
feather package install glyph
```

Feather places the files inside your project and adds an entry to `feather.lock.json` so the
install is reproducible. To restore dependencies on a fresh clone:

```sh
feather package install
```

---

## Option 2 — Release zip

Download the latest zip from the
[GitHub Releases](https://github.com/Kyonru/glyph.lua/releases) page.

1. Unzip the archive.
2. Copy the two items into your project root (or a `lib/` subfolder):

```
your-game/
├── glyph.lua
└── glyph/
    ├── components.lua
    ├── runtime.lua
    └── ...
```

3. Add the location to `package.path` if you placed them in a subfolder:

```lua
package.path = "lib/?.lua;lib/?/init.lua;" .. package.path

local ui = require("glyph")
```

If you copied them straight to the project root no path change is needed.

---

## Option 3 — Clone the repository

Clone and copy the two items that make up glyph:

```sh
git clone https://github.com/Kyonru/glyph.lua.git
```

Then copy `glyph.lua` and the `glyph/` folder into your project:

```sh
cp glyph.lua/glyph.lua   your-game/
cp -r glyph.lua/glyph/   your-game/glyph/
```

If you prefer to keep glyph as a submodule instead:

```sh
cd your-game
git submodule add https://github.com/Kyonru/glyph.lua.git lib/glyph
```

Then point `package.path` at the submodule:

```lua
package.path = "lib/glyph/?.lua;lib/glyph/?/init.lua;" .. package.path

local ui = require("glyph")
```

---

## Option 4 — LuaRocks

Install the rock directly from the terminal:

```sh
luarocks install glyph
```

LuaRocks installs Glyph into the selected Lua tree. A system Lua configured for
that tree can require it directly:

```lua
local ui = require("glyph")
```

> [!NOTE]
> Love2D uses its own bundled Lua rather than the system one, so its
> `package.path` usually does not include the LuaRocks tree. Add the snippet
> below to the top of `main.lua` to bridge them.

```lua
local handle = io.popen("luarocks path --lr-path 2>/dev/null")
if handle then
  local rockPath = handle:read("*l")
  handle:close()
  if rockPath and rockPath ~= "" then
    package.path = rockPath .. ";" .. package.path
  end
end
```

---

## Verify the install

Paste this into `main.lua` and run with `love .` — a white label should appear:

```lua
local ui = require("glyph")

local function App()
  return ui.text("glyph is working!")
end

function love.load()
  ui.load({ app = App })
end
```

Passing `app = App` installs Glyph's update, draw, and common input callbacks.
Do not also call `ui.update` or `ui.render` from your Love2D callbacks when using
this automatic setup.
