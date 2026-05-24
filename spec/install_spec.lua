package.path = "./?.lua;./?/init.lua;" .. package.path

local ui = require("glyph")

describe("install", function()
  it("chains Love2D input callbacks and resize", function()
    local calls = {}
    local fakeLove = {
      mousepressed = function(x, y, button)
        calls[#calls + 1] = { "previous", x, y, button }
      end,
    }

    local unregister = ui.install(fakeLove)

    fakeLove.resize(800, 600)
    fakeLove.mousepressed(10, 20, 1)

    assert.are.equal(800, ui.viewport().width)
    assert.are.equal(600, ui.viewport().height)
    assert.are.same({ "previous", 10, 20, 1 }, calls[1])

    unregister()
    assert.is_nil(fakeLove.resize)
    assert.is_not_nil(fakeLove.mousepressed)
  end)

  it("can install update and draw for an app component", function()
    local fakeLove = {}
    local renders = 0
    local previousRender = ui.render

    ui.render = function(app)
      renders = renders + 1
      assert.are.equal("function", type(app))
    end

    local unregister = ui.install(fakeLove, {
      app = function()
        return ui.text("ok")
      end,
    })

    fakeLove.update(0.016)
    fakeLove.draw()

    assert.are.equal(1, renders)

    unregister()
    ui.render = previousRender
  end)

  it("forwards extra Love2D callbacks to the event bus", function()
    local fakeLove = {}
    local events = {}
    local off = ui.on("event", function(name, ...)
      events[#events + 1] = name
    end)

    local unregister = ui.install(fakeLove)

    fakeLove.keyreleased("escape", "escape")
    fakeLove.focus(false)
    fakeLove.visible(true)

    assert.are.same({ "keyreleased", "focus", "visible" }, events)

    unregister()
    off()
  end)

  it("loads window configuration and installs callbacks with a default app", function()
    local fakeLove = {}
    fakeLove.window = {
      setMode = function(width, height, opts)
        fakeLove.mode = { width = width, height = height, opts = opts }
      end,
    }
    fakeLove.graphics = {
      getDimensions = function()
        return 640, 480
      end,
    }
    local previousGlobalLove = _G.love
    _G.love = fakeLove

    local renders = 0
    local previousRender = ui.render
    ui.render = function(app)
      renders = renders + 1
      assert.are.equal("function", type(app))
    end

    local unregister = ui.load({
      window = {
        width = 800,
        height = 600,
        resizable = true,
        minWidth = 320,
      },
      app = function()
        return ui.text("ok")
      end,
    })

    fakeLove.draw()

    assert.are.equal(800, fakeLove.mode.width)
    assert.are.equal(600, fakeLove.mode.height)
    assert.is_true(fakeLove.mode.opts.resizable)
    assert.are.equal(640, ui.viewport().width)
    assert.are.equal(480, ui.viewport().height)
    assert.are.equal(1, renders)

    unregister()
    ui.render = previousRender
    _G.love = previousGlobalLove
  end)
end)
