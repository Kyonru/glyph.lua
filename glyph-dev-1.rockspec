rockspec_format = "3.0"

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
    ["glyph.accessibility"] = "glyph/accessibility.lua",
    ["glyph.animation"] = "glyph/animation.lua",
    ["glyph.init"] = "glyph/init.lua",
    ["glyph.callback_bus"] = "glyph/callback_bus.lua",
    ["glyph.components"] = "glyph/components.lua",
    ["glyph.dialogue"] = "glyph/dialogue.lua",
    ["glyph.feedback"] = "glyph/feedback.lua",
    ["glyph.filter"] = "glyph/filter.lua",
    ["glyph.grid_math"] = "glyph/grid_math.lua",
    ["glyph.i18n"] = "glyph/i18n.lua",
    ["glyph.layout"] = "glyph/layout.lua",
    ["glyph.menori"] = "glyph/menori.lua",
    ["glyph.modal"] = "glyph/modal.lua",
    ["glyph.navigate"] = "glyph/navigate.lua",
    ["glyph.path"] = "glyph/path.lua",
    ["glyph.responsive"] = "glyph/responsive.lua",
    ["glyph.rich_text_backend"] = "glyph/rich_text_backend.lua",
    ["glyph.runtime"] = "glyph/runtime.lua",
    ["glyph.scene"] = "glyph/scene.lua",
    ["glyph.sprite_sheet"] = "glyph/sprite_sheet.lua",
    ["glyph.style"] = "glyph/style.lua",
    ["glyph.surface"] = "glyph/surface.lua",
    ["glyph.theme"] = "glyph/theme.lua",
    ["glyph.transitions"] = "glyph/transitions.lua",
    ["glyph.types"] = "glyph/types.lua",
    ["glyph.typography"] = "glyph/typography.lua",
    ["glyph.viewport_backend"] = "glyph/viewport_backend.lua",
    ["glyph.virtual_list"] = "glyph/virtual_list.lua",
    ["glyph.vendor.feel"] = "glyph/vendor/feel.lua",
    ["glyph.vendor.feel.feedbacks"] = "glyph/vendor/feel/feedbacks.lua",
    ["glyph.vendor.feel.g3d"] = "glyph/vendor/feel/g3d.lua",
    ["glyph.vendor.feel.init"] = "glyph/vendor/feel/init.lua",
    ["glyph.vendor.feel.love"] = "glyph/vendor/feel/love.lua",
    ["glyph.vendor.feel.menori"] = "glyph/vendor/feel/menori.lua",
    ["glyph.vendor.feel.presets"] = "glyph/vendor/feel/presets.lua",
    ["glyph.vendor.feel.types.feel-feedbacks"] = "glyph/vendor/feel/types/feel-feedbacks.lua",
    ["glyph.vendor.feel.types.feel-g3d"] = "glyph/vendor/feel/types/feel-g3d.lua",
    ["glyph.vendor.feel.types.feel-love"] = "glyph/vendor/feel/types/feel-love.lua",
    ["glyph.vendor.feel.types.feel-menori"] = "glyph/vendor/feel/types/feel-menori.lua",
    ["glyph.vendor.feel.types.feel"] = "glyph/vendor/feel/types/feel.lua",
    ["glyph.vendor.feel.validate"] = "glyph/vendor/feel/validate.lua",
    ["glyph.vendor.feel.vendor.flux"] = "glyph/vendor/feel/vendor/flux.lua",
    ["glyph.vendor.flux"] = "glyph/vendor/flux.lua",
  },
}
