package.path = "./?.lua;./?/init.lua;" .. package.path

local Glyph = require("glyph")
local Instance = Glyph.instance

local function fakeLove()
  local font = {
    getWidth = function(_, text)
      return #(tostring(text or "")) * 8
    end,
    getHeight = function()
      return 16
    end,
  }
  local graphics = {}
  function graphics.getDimensions() return 320, 180 end
  function graphics.getLineWidth() return 1 end
  function graphics.setLineWidth() end
  function graphics.getShader() return nil end
  function graphics.setShader() end
  function graphics.getColor() return 1, 1, 1, 1 end
  function graphics.setColor() end
  function graphics.rectangle() end
  function graphics.print() end
  function graphics.printf() end
  function graphics.push() end
  function graphics.pop() end
  function graphics.translate() end
  function graphics.scale() end
  function graphics.rotate() end
  function graphics.setScissor() end
  function graphics.setStencilTest() end
  function graphics.getFont() return font end
  function graphics.setFont(nextFont) font = nextFont or font end
  return { graphics = graphics }
end

describe("screen-space instance", function()
  it("renders an isolated scoped tree directly to the screen", function()
    local setFirst
    local setSecond
    local first = Instance.new({
      love = fakeLove(),
      component = function(ui)
        local value, setValue = ui.useState(1)
        setFirst = setValue
        return ui.text("first:" .. value)
      end,
    })
    local second = Instance.new({
      love = fakeLove(),
      component = function(ui)
        local value, setValue = ui.useState(10)
        setSecond = setValue
        return ui.text("second:" .. value)
      end,
    })

    first:render()
    second:render()
    setFirst(2)
    setSecond(20)

    assert.are.equal("first:2", first:render().value)
    assert.are.equal("second:20", second:render().value)
  end)

  it("exposes hit testing, focus, and boolean pointer consumption", function()
    local clicks = 0
    local instance = Instance.new({
      love = fakeLove(),
      component = function(ui)
        return ui.button({
          width = 80,
          height = 32,
          label = "Run",
          onClick = function()
            clicks = clicks + 1
          end,
        })
      end,
    })
    instance:render()

    assert.is_not_nil(instance:hitTest(10, 10))
    assert.is_nil(instance:hitTest(100, 100))
    assert.is_true(instance:mousemoved(10, 10))
    assert.is_false(instance:mousemoved(100, 100))
    assert.is_true(instance:mousepressed(10, 10, 1))
    assert.is_true(instance:hasFocus())
    assert.is_true(instance:mousereleased(10, 10, 1))
    assert.are.equal(1, clicks)
    assert.is_false(instance:mousepressed(100, 100, 1))
    assert.is_false(instance:hasFocus())
  end)

  it("claims keyboard and text events while an input owns focus", function()
    local value = ""
    local instance = Instance.new({
      love = fakeLove(),
      component = function(ui)
        return ui.input({
          width = 120,
          height = 32,
          value = value,
          onChange = function(nextValue)
            value = nextValue
          end,
        })
      end,
    })
    instance:render()

    assert.is_true(instance:mousepressed(10, 10, 1))
    assert.is_true(instance:textinput("a"))
    assert.is_true(instance:keypressed("s"))
    assert.is_true(instance:keyreleased("s"))
    assert.are.equal("a", value)
  end)

  it("claims wheel events over UI and releases events outside it", function()
    local instance = Instance.new({
      love = fakeLove(),
      component = function(ui)
        return ui.box({ width = 100, height = 60 })
      end,
    })
    instance:render()

    instance:mousemoved(10, 10)
    assert.is_true(instance:wheelmoved(0, -1))
    instance:mousemoved(200, 100)
    assert.is_false(instance:wheelmoved(0, -1))
    assert.is_false(instance:keypressed("s"))
    assert.is_false(instance:keyreleased("s"))
    assert.is_false(instance:textinput("a"))
  end)

  it("claims input behind a blocking modal", function()
    local instance = Instance.new({
      love = fakeLove(),
      component = function(ui)
        return ui.box({ width = 20, height = 20, interactive = false })
      end,
    })
    instance:render()
    instance.ui.modal.open("confirm", function()
      return instance.ui.panel({ width = 80, height = 50 })
    end, { transition = "none" })
    instance:render()

    assert.is_true(instance:mousemoved(300, 170))
    assert.is_true(instance:mousepressed(300, 170, 1))
    assert.is_true(instance:mousereleased(300, 170, 1))
    assert.is_true(instance:wheelmoved(0, -1))
    assert.is_true(instance:keypressed("s"))
    assert.is_true(instance:keyreleased("s"))
    assert.is_true(instance:textinput("a"))
  end)

  it("disposes effects and becomes inert exactly once", function()
    local calls = {}
    local instance = Instance.new({
      love = fakeLove(),
      component = function(ui)
        ui.useEffect(function()
          calls[#calls + 1] = "effect"
          return function()
            calls[#calls + 1] = "cleanup"
          end
        end, {})
        return ui.box({ width = 20, height = 20 })
      end,
    })
    instance:render()
    instance.ui.scene.push("overlay", function()
      instance.ui.useEffect(function()
        calls[#calls + 1] = "layer effect"
        return function()
          calls[#calls + 1] = "layer cleanup"
        end
      end, {})
      return instance.ui.box({ width = 10, height = 10 })
    end, { blocking = false, transition = "none" })
    instance:render()
    instance:destroy()
    instance:destroy()

    assert.are.same({ "effect", "layer effect", "cleanup", "layer cleanup" }, calls)
    assert.is_nil(instance:render())
    assert.is_nil(instance:hitTest(1, 1))
    assert.is_false(instance:mousepressed(1, 1, 1))
    assert.is_false(instance:keypressed("return"))
  end)
end)
