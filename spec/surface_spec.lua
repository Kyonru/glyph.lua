package.path = "./?.lua;./?/init.lua;" .. package.path

local Surface = require("glyph.surface")

local function fakeLove()
  local graphics = {}
  local currentCanvas = nil
  local newCanvasCalls = {}
  local setCanvasCalls = {}
  local font = {
    getWidth = function(_, text)
      return #(tostring(text or "")) * 8
    end,
    getHeight = function()
      return 16
    end,
  }

  function graphics.newCanvas(width, height, options)
    newCanvasCalls[#newCanvasCalls + 1] = { width = width, height = height, options = options }
    return {
      width = width,
      height = height,
      options = options,
      getWidth = function(self)
        return self.width
      end,
      getHeight = function(self)
        return self.height
      end,
      getDimensions = function(self)
        return self.width, self.height
      end,
    }
  end
  function graphics.setCanvas(canvas)
    setCanvasCalls[#setCanvasCalls + 1] = canvas
    currentCanvas = canvas
  end
  function graphics.getCanvas()
    return currentCanvas
  end
  function graphics.getDimensions()
    return 640, 360
  end
  function graphics.clear() end
  function graphics.push() end
  function graphics.pop() end
  function graphics.translate() end
  function graphics.scale() end
  function graphics.rotate() end
  function graphics.setColor() end
  function graphics.getColor()
    return 1, 1, 1, 1
  end
  function graphics.rectangle() end
  function graphics.print() end
  function graphics.printf() end
  function graphics.setShader() end
  function graphics.getShader()
    return nil
  end
  function graphics.getLineWidth()
    return 1
  end
  function graphics.setLineWidth() end
  function graphics.getFont()
    return font
  end
  function graphics.setFont(nextFont)
    font = nextFont or font
  end

  return {
    graphics = graphics,
    newCanvasCalls = newCanvasCalls,
    setCanvasCalls = setCanvasCalls,
  }
end

describe("surface", function()
  it("keeps scoped hook state isolated between surfaces", function()
    local love = fakeLove()
    local setA
    local setB

    local surfaceA = Surface.new({
      width = 120,
      height = 60,
      love = love,
      component = function(ui)
        local count, setCount = ui.useState(0)
        setA = setCount
        return ui.text("A:" .. count)
      end,
    })
    local surfaceB = Surface.new({
      width = 120,
      height = 60,
      love = love,
      component = function(ui)
        local count, setCount = ui.useState(10)
        setB = setCount
        return ui.text("B:" .. count)
      end,
    })

    surfaceA:render()
    surfaceB:render()
    setA(3)
    setB(function(value)
      return value + 1
    end)
    surfaceA:render()
    surfaceB:render()

    assert.are.equal("A:3", surfaceA.runtime.root.value)
    assert.are.equal("B:11", surfaceB.runtime.root.value)
  end)

  it("renders to a fixed-size canvas and resizes it explicitly", function()
    local love = fakeLove()
    local surface = Surface.new({
      width = 128,
      height = 64,
      love = love,
      component = function(ui)
        return ui.box({ width = "100%", height = "100%" })
      end,
    })

    surface:render()
    assert.are.equal(128, surface.canvas:getWidth())
    assert.are.equal(64, surface.canvas:getHeight())
    assert.is_nil(love.newCanvasCalls[1].options)
    assert.is_true(love.setCanvasCalls[1].stencil)

    surface:resize(256, 96)
    surface:render()
    assert.are.equal(256, surface.canvas:getWidth())
    assert.are.equal(96, surface.canvas:getHeight())
  end)

  it("preserves explicit canvas options while defaulting stencil support at draw time", function()
    local love = fakeLove()
    local surface = Surface.new({
      width = 32,
      height = 32,
      love = love,
      canvasOptions = { msaa = 4, stencil = false },
      component = function(ui)
        return ui.box({ width = "100%", height = "100%" })
      end,
    })
    surface:render()

    assert.are.equal(4, love.newCanvasCalls[1].options.msaa)
    assert.are.equal(surface.canvas, love.setCanvasCalls[1])
  end)

  it("routes pointer input to the surface runtime", function()
    local clicks = 0
    local surface = Surface.new({
      width = 120,
      height = 60,
      love = fakeLove(),
      component = function(ui)
        return ui.button({
          label = "Click",
          width = 80,
          height = 40,
          onClick = function()
            clicks = clicks + 1
          end,
        })
      end,
    })

    surface:render()
    surface:mousepressed(10, 10, 1)
    surface:mousereleased(10, 10, 1)

    assert.are.equal(1, clicks)
  end)

  it("uses the surface runtime for drag helpers", function()
    local calls = {}
    local surface = Surface.new({
      width = 120,
      height = 60,
      love = fakeLove(),
      component = function(ui)
        local startDrag = ui.drag({
          onStart = function(ctx)
            calls[#calls + 1] = { "start", ctx.sourcePath, ctx.x, ctx.y }
          end,
          onDrop = function(ctx)
            calls[#calls + 1] = { "drop", ctx.targetPath, ctx.x, ctx.y }
          end,
        })

        return ui.box({
          width = 80,
          height = 40,
          onMousePressed = function(x, y, button, node)
            startDrag(x, y, button, node)
          end,
        })
      end,
    })

    surface:render()
    surface:mousepressed(8, 9, 1)
    surface:mousemoved(20, 24)
    surface:mousereleased(20, 24, 1)

    assert.are.same({ "start", "0", 8, 9 }, calls[1])
    assert.are.same({ "drop", "0", 20, 24 }, calls[2])
    assert.is_nil(require("glyph").runtime.activeDrag)
  end)
end)
