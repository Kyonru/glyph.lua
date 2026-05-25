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

  it("creates generic meter nodes", function()
    local meter = ui.meter({
      value = 7,
      max = 10,
      width = 120,
      shape = { kind = "skew", skew = 10 },
    })

    assert.are.equal("meter", meter.type)
    assert.are.equal(7, meter.props.value)
    assert.are.equal("linear", meter.props.kind)
    assert.are.equal("right", meter.props.direction)
    assert.are.equal("skew", meter.props.shape.kind)
  end)

  it("converts pointer input through the viewport backend", function()
    local previousBackend = ui.runtime.viewportBackend
    local clicks = 0

    ui.runtime.viewportBackend = {
      isEnabled = function() return true end,
      screenToViewport = function(x, y)
        if x < 0 then
          return false, false, false
        end
        return true, x / 2, y / 2
      end,
      viewportToScreen = function(x, y)
        return x * 2, y * 2
      end,
    }

    local function App()
      return Components.button({
        label = "Scaled",
        width = 40,
        height = 30,
        onClick = function()
          clicks = clicks + 1
        end,
      })
    end

    ui.runtime:build(App)
    ui.runtime:layoutRoot(ui.runtime.root, 100, 100)
    ui.mousemoved(20, 20)
    assert.are.equal("Scaled", ui.runtime.hoverNode.props.label)

    ui.mousepressed(20, 20, 1)
    ui.mousereleased(20, 20, 1)
    assert.are.equal(1, clicks)

    ui.mousemoved(-1, 20)
    assert.is_nil(ui.runtime.hoverNode)
    ui.runtime.viewportBackend = previousBackend
  end)

  it("reports viewport backend helpers", function()
    local previousBackend = ui.runtime.viewportBackend
    ui.runtime.viewportBackend = {
      isEnabled = function() return true end,
      backend = function() return "push" end,
      screenToViewport = function(x, y) return true, x / 2, y / 2 end,
      viewportToScreen = function(x, y) return x * 2, y * 2 end,
      beginDraw = function() return true end,
      endDraw = function() return true end,
      raw = function() return { name = "fake" } end,
    }

    assert.is_true(ui.viewportBackend.isEnabled())
    assert.are.equal("push", ui.viewportBackend.backend())
    assert.are.same({ true, 10, 12 }, { ui.viewportBackend.screenToViewport(20, 24) })
    assert.are.same({ 20, 24 }, { ui.viewportBackend.viewportToScreen(10, 12) })
    assert.are.equal("fake", ui.viewportBackend.raw().name)

    ui.runtime.viewportBackend = previousBackend
  end)

  it("keeps responsive viewport dimensions virtual while resizing a backend", function()
    local previousBackend = ui.runtime.viewportBackend
    local previousWidth = ui.runtime.responsive.width
    local previousHeight = ui.runtime.responsive.height
    local resized
    ui.runtime.viewportBackend = {
      isEnabled = function() return true end,
      resize = function(width, height)
        resized = { width, height }
      end,
      dimensions = function()
        return 320, 180
      end,
      backend = function() return "shove" end,
      getViewport = function()
        return { x = 0, y = 0, width = 960, height = 540 }
      end,
    }

    ui.resize(960, 540)
    local viewport = ui.viewport()

    assert.are.same({ 960, 540 }, resized)
    assert.are.equal(320, viewport.width)
    assert.are.equal(180, viewport.height)
    assert.are.equal("shove", viewport.backend)
    assert.is_true(viewport.virtual)

    ui.runtime.viewportBackend = previousBackend
    ui.runtime.responsive.width = previousWidth
    ui.runtime.responsive.height = previousHeight
  end)

  it("lays out meter children as overlays", function()
    local runtime = Runtime.new()

    local function App()
      return Components.meter({
        value = 7,
        max = 10,
        width = 120,
        height = 16,
      }, {
        Components.text("70%"),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)

    assert.are.equal(120, runtime.root.layout.width)
    assert.are.equal(16, runtime.root.layout.height)
    assert.are.equal(0, runtime.root.children[1].layout.x)
    assert.are.equal(0, runtime.root.children[1].layout.y)
  end)

  it("passes draw context to custom draw callbacks", function()
    local runtime = Runtime.new()
    local received
    local receivedPolygon

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
        polygon = function(_, ...)
          receivedPolygon = { ... }
        end,
      },
    })

    local function App()
      return Components.box({
        width = 100,
        height = 40,
        active = true,
        draw = function(_, _, _, _, _, _, _, ctx)
          received = ctx
          ctx:shape("fill", { kind = "skew", skew = 8 })
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
    assert.are.equal("table", type(receivedPolygon))
    assert.are.equal(8, receivedPolygon[7])
  end)
end)
