package.path = "./?.lua;./?/init.lua;" .. package.path

local Animation = require("glyph.animation")
local Transitions = require("glyph.transitions")
local ui = require("glyph")

describe("animation", function()
  before_each(function()
    Animation.clear()
  end)

  it("loads vendored flux through Glyph", function()
    assert.are.equal("0.1.5", Animation.flux._version)
  end)

  it("updates numeric subject fields through ui.animation.to", function()
    local subject = { x = 0 }
    ui.animation.to(subject, 1, { x = 10 }, { ease = "linear" })

    ui.animation.update(0.5)

    assert.are.equal(5, subject.x)
  end)

  it("samples animation transition specs", function()
    local transition = Transitions.animate({
      enter = {
        duration = 0.2,
        ease = "linear",
        from = { y = 20, scale = 0.5 },
        to = { y = 0, scale = 1 },
      },
    })

    assert.are.equal("animate", transition.name)
    assert.are.equal(0.2, transition.duration)
    assert.is_function(transition.draw)
  end)
end)
