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

  it("does not install gamepad callbacks by default", function()
    local previousPressed = function() end
    local fakeLove = {
      gamepadpressed = previousPressed,
    }

    local unregister = ui.install(fakeLove)

    assert.are.equal(previousPressed, fakeLove.gamepadpressed)

    unregister()
    assert.are.equal(previousPressed, fakeLove.gamepadpressed)
  end)

  it("installs opt-in gamepad callbacks and chains previous callbacks", function()
    local calls = {}
    local previousNavigate = ui.navigate
    local fakeLove = {
      gamepadpressed = function(_, button)
        calls[#calls + 1] = "previous:" .. button
      end,
    }
    ui.navigate = function(direction)
      calls[#calls + 1] = "navigate:" .. direction
    end

    local unregister = ui.install(fakeLove, { gamepad = true })

    fakeLove.gamepadpressed("joystick", "dpdown")

    assert.are.same({
      "previous:dpdown",
      "navigate:down",
    }, calls)

    unregister()
    ui.navigate = previousNavigate
  end)

  it("maps default gamepad buttons to navigation and key press lifecycle", function()
    local calls = {}
    local events = {}
    local previousNavigate = ui.navigate
    local previousKeypressed = ui.keypressed
    local previousKeyreleased = ui.keyreleased
    local off = ui.on("event", function(name, _, button)
      if name == "gamepadpressed" or name == "gamepadreleased" then
        events[#events + 1] = name .. ":" .. button
      end
    end)

    ui.navigate = function(direction)
      calls[#calls + 1] = "navigate:" .. direction
    end
    ui.keypressed = function(key)
      calls[#calls + 1] = "keypressed:" .. key
    end
    ui.keyreleased = function(key)
      calls[#calls + 1] = "keyreleased:" .. key
    end

    ui.gamepadpressed("joystick", "dpup")
    ui.gamepadpressed("joystick", "a")
    ui.gamepadreleased("joystick", "a")
    ui.gamepadpressed("joystick", "b")
    ui.gamepadreleased("joystick", "b")

    assert.are.same({
      "navigate:up",
      "keypressed:return",
      "keyreleased:return",
      "keypressed:escape",
      "keyreleased:escape",
    }, calls)
    assert.are.same({
      "gamepadpressed:dpup",
      "gamepadpressed:a",
      "gamepadreleased:a",
      "gamepadpressed:b",
      "gamepadreleased:b",
    }, events)

    off()
    ui.navigate = previousNavigate
    ui.keypressed = previousKeypressed
    ui.keyreleased = previousKeyreleased
  end)

  it("supports custom gamepad mappings and false disables defaults", function()
    local calls = {}
    local previousNavigate = ui.navigate
    local previousKeypressed = ui.keypressed
    local previousKeyreleased = ui.keyreleased
    local mapping = {
      navigation = {
        dpup = false,
        x = "left",
      },
      buttons = {
        a = "space",
        b = false,
      },
    }

    ui.navigate = function(direction)
      calls[#calls + 1] = "navigate:" .. direction
    end
    ui.keypressed = function(key)
      calls[#calls + 1] = "keypressed:" .. key
    end
    ui.keyreleased = function(key)
      calls[#calls + 1] = "keyreleased:" .. key
    end

    ui.gamepadpressed("joystick", "dpup", mapping)
    ui.gamepadpressed("joystick", "x", mapping)
    ui.gamepadpressed("joystick", "a", mapping)
    ui.gamepadreleased("joystick", "a", mapping)
    ui.gamepadpressed("joystick", "b", mapping)
    ui.gamepadreleased("joystick", "b", mapping)

    assert.are.same({
      "navigate:left",
      "keypressed:space",
      "keyreleased:space",
    }, calls)

    ui.navigate = previousNavigate
    ui.keypressed = previousKeypressed
    ui.keyreleased = previousKeyreleased
  end)

  it("refreshes hover from the mouse position before wheel scrolling", function()
    local fakeLove = {
      mouse = {
        getPosition = function()
          return 10, 10
        end,
      },
    }
    local unregister = ui.install(fakeLove)

    ui.runtime:build(function()
      local rows = {}
      for index = 1, 10 do
        rows[index] = ui.box({ width = 100, height = 20 })
      end
      return ui.scrollView({
        key = "wheel-list",
        width = 100,
        height = 60,
        gap = 0,
      }, rows)
    end)
    ui.runtime:layoutRoot(ui.runtime.root)

    fakeLove.wheelmoved(0, -1)

    assert.are.equal(24, ui.getScrollOffset("wheel-list"))

    unregister()
    ui.runtime:setLove(nil)
  end)

  it("does not activate disabled focused buttons through gamepad helpers", function()
    local clicks = 0

    ui.runtime:build(function()
      return ui.button({
        label = "Disabled",
        disabled = true,
        onClick = function()
          clicks = clicks + 1
        end,
      })
    end)
    ui.runtime:layoutRoot(ui.runtime.root)
    ui.setFocus(ui.runtime.root)

    ui.gamepadpressed("joystick", "a")
    ui.gamepadreleased("joystick", "a")

    assert.are.equal(0, clicks)
    ui.setFocus(nil)
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
