package = "glyph"
version = "dev-1"
source = {
  url = "git://github.com/Kyonru/glyph.lua.git",
}
description = {
  summary = "Declarative UI for Love2D",
  detailed = "A React/Ink-style Lua UI runtime for Love2D debugger panels and game tooling.",
  homepage = "https://github.com/Kyonru/glyph.lua",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
}
test_dependencies = {
  "busted",
}
build = {
  type = "builtin",
  modules = {
    glyph = "glyph.lua",
    ["glyph.init"] = "glyph/init.lua",
    ["glyph.callback_bus"] = "glyph/callback_bus.lua",
    ["glyph.components"] = "glyph/components.lua",
    ["glyph.layout"] = "glyph/layout.lua",
    ["glyph.modal"] = "glyph/modal.lua",
    ["glyph.navigate"] = "glyph/navigate.lua",
    ["glyph.responsive"] = "glyph/responsive.lua",
    ["glyph.runtime"] = "glyph/runtime.lua",
    ["glyph.scene"] = "glyph/scene.lua",
    ["glyph.style"] = "glyph/style.lua",
    ["glyph.theme"] = "glyph/theme.lua",
    ["glyph.transitions"] = "glyph/transitions.lua",
  },
}
