package.path = "./?.lua;./?/init.lua;" .. package.path

local Responsive = require("glyph.responsive")
local Runtime = require("glyph.runtime")

describe("responsive", function()
  it("tracks viewport size and breakpoint", function()
    local state = Responsive.new()
    Responsive.resize(state, 800, 600)

    local viewport = Responsive.viewport(state)

    assert.are.equal(800, viewport.width)
    assert.are.equal(600, viewport.height)
    assert.are.equal("md", viewport.breakpoint)
    assert.is_true(Responsive.atLeast(state, "md"))
    assert.is_false(Responsive.below(state, "md"))
  end)

  it("picks responsive values by current breakpoint", function()
    local state = Responsive.new()
    Responsive.resize(state, 700, 600)

    assert.are.equal(2, Responsive.pick(state, {
      default = 1,
      sm = 2,
      md = 3,
    }))
  end)

  it("computes fluid columns", function()
    local columns = Responsive.columns(700, {
      min = 160,
      maxCount = 4,
      gap = 10,
    })

    assert.are.equal(4, columns.count)
    assert.are.equal(167, columns.width)
  end)

  it("configures runtime viewport without Love2D", function()
    local runtime = Runtime.new()

    Responsive.configureWindow(runtime, {
      width = 928,
      height = 720,
      breakpoints = {
        md = 760,
      },
    })

    assert.are.equal(928, runtime.responsive.width)
    assert.are.equal(720, runtime.responsive.height)
    assert.are.equal("md", Responsive.breakpoint(runtime.responsive))
    assert.is_true(runtime.needsRender)
  end)
end)
