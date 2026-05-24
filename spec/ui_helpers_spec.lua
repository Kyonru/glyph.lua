package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("glyph.runtime")
local Components = require("glyph.components")
local ui = require("glyph")

describe("ui helpers", function()
  it("mixes numbers and colors", function()
    assert.are.equal(15, ui.mix(10, 20, 0.5))
    assert.are.same({ 0.5, 0.25, 0.75, 1 }, ui.mixColor({ 0, 0, 1, 1 }, { 1, 0.5, 0.5, 1 }, 0.5))
  end)

  it("builds skewed polygon boxes", function()
    assert.are.same({
      2,
      2,
      88,
      2,
      98,
      48,
      12,
      48,
    }, ui.polygonBox(0, 0, 100, 50, { skew = 10, inset = 2 }))
  end)

  it("creates custom button nodes", function()
    local custom = ui.customButton({ width = 100, height = 20 })

    assert.are.equal("button", custom.type)
  end)

  it("passes draw context to custom draw callbacks", function()
    local runtime = Runtime.new()
    local received

    runtime:setLove({
      timer = {
        getTime = function()
          return 2
        end,
      },
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getShader = function()
          return nil
        end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        polygon = function() end,
      },
    })

    local function App()
      return Components.box({
        width = 100,
        height = 40,
        active = true,
        draw = function(_, _, _, _, _, _, _, ctx)
          received = ctx
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(100, received.width)
    assert.are.equal(40, received.height)
    assert.is_true(received.active)
    assert.is_true(received.hot)
    assert.are.equal(2, received.time)
    assert.are.equal("table", type(received:skewBox({ skew = 4 })))
  end)
end)
