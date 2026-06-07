package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("glyph.runtime")
local Components = require("glyph.components")
local Modal = require("glyph.modal")
local ViewportBackend = require("glyph.viewport_backend")
local ui = require("glyph")

local function build(runtime, component)
  runtime:build(component)
  runtime:layoutRoot(runtime.root, 200, 120)
end

describe("drag helper", function()
  after_each(function()
    ui.runtime.activeDrag = nil
    ui.runtime.viewportBackend = ViewportBackend.new()
  end)

  it("runs immediate start, move, and drop callbacks with pointer context", function()
    local runtime = Runtime.new()
    local calls = {}
    local startDrag

    build(runtime, function()
      startDrag = runtime:drag({
        onStart = function(ctx)
          calls[#calls + 1] = { "start", ctx.x, ctx.y, ctx.totalDx, ctx.totalDy, ctx.data.id, ctx.sourcePath }
        end,
        onMove = function(ctx)
          calls[#calls + 1] = { "move", ctx.x, ctx.y, ctx.dx, ctx.dy, ctx.totalDx, ctx.totalDy }
        end,
        onDrop = function(ctx)
          calls[#calls + 1] = { "drop", ctx.x, ctx.y, ctx.dx, ctx.dy, ctx.totalDx, ctx.totalDy }
        end,
      })

      return Components.box({
        width = 80,
        height = 60,
        onMousePressed = function(x, y, button, node)
          startDrag(x, y, button, node, { id = "item-a" })
        end,
      })
    end)

    runtime:mousepressed(10, 12, 1)
    runtime:mousemoved(25, 30)
    runtime:mousereleased(40, 42, 1)

    assert.are.same({ "start", 10, 12, 0, 0, "item-a", "0" }, calls[1])
    assert.are.same({ "move", 25, 30, 15, 18, 15, 18 }, calls[2])
    assert.are.same({ "drop", 40, 42, 15, 12, 30, 30 }, calls[3])
  end)

  it("preserves normal click behavior when release happens before minDistance", function()
    local runtime = Runtime.new()
    local clicks = 0
    local starts = 0
    local drops = 0
    local startDrag

    build(runtime, function()
      startDrag = runtime:drag({
        minDistance = 10,
        onStart = function()
          starts = starts + 1
        end,
        onDrop = function()
          drops = drops + 1
        end,
      })

      return Components.button({
        label = "drag",
        width = 80,
        height = 40,
        onClick = function()
          clicks = clicks + 1
        end,
        onMousePressed = function(x, y, button, node)
          startDrag(x, y, button, node)
        end,
      })
    end)

    runtime:mousepressed(10, 10, 1)
    runtime:mousemoved(13, 14)
    runtime:mousereleased(13, 14, 1)

    assert.are.equal(0, starts)
    assert.are.equal(0, drops)
    assert.are.equal(1, clicks)
  end)

  it("suppresses button clicks when an active drag owns release", function()
    local runtime = Runtime.new()
    local clicks = 0
    local drops = 0
    local startDrag

    build(runtime, function()
      startDrag = runtime:drag({
        onDrop = function()
          drops = drops + 1
        end,
      })

      return Components.button({
        label = "drag",
        width = 80,
        height = 40,
        onClick = function()
          clicks = clicks + 1
        end,
        onMousePressed = function(x, y, button, node)
          startDrag(x, y, button, node)
        end,
      })
    end)

    runtime:mousepressed(10, 10, 1)
    runtime:mousereleased(10, 10, 1)

    assert.are.equal(1, drops)
    assert.are.equal(0, clicks)
  end)

  it("updates target nodes through hit testing on move and drop", function()
    local runtime = Runtime.new()
    local seenMoveTarget = nil
    local seenDropTarget = nil
    local startDrag

    build(runtime, function()
      startDrag = runtime:drag({
        onMove = function(ctx)
          seenMoveTarget = ctx.targetPath
        end,
        onDrop = function(ctx)
          seenDropTarget = ctx.targetPath
        end,
      })

      return Components.row({}, {
        Components.box({
          width = 50,
          height = 50,
          onMousePressed = function(x, y, button, node)
            startDrag(x, y, button, node)
          end,
        }),
        Components.box({
          width = 50,
          height = 50,
        }),
      })
    end)

    runtime:mousepressed(10, 10, 1)
    runtime:mousemoved(70, 10)
    runtime:mousereleased(70, 10, 1)

    assert.are.equal("0.2", seenMoveTarget)
    assert.are.equal("0.2", seenDropTarget)
  end)

  it("supports app cancellation and replacement cancellation", function()
    local runtime = Runtime.new()
    local reasons = {}
    local startDrag = runtime:drag({
      onMove = function(ctx)
        ctx.cancel("app")
      end,
      onCancel = function(ctx)
        reasons[#reasons + 1] = ctx.reason .. ":" .. tostring(ctx.data)
      end,
    })

    startDrag(0, 0, 1, nil, "first")
    runtime:mousemoved(2, 2)
    startDrag(5, 5, 1, nil, "second")
    startDrag(6, 6, 1, nil, "third")

    assert.are.same({ "app:first", "replaced:second" }, reasons)
  end)

  it("cancels active drags on escape before closing scene layers", function()
    local runtime = Runtime.new()
    local reason = nil
    local startDrag = runtime:drag({
      onCancel = function(ctx)
        reason = ctx.reason
      end,
    })

    Modal.open(runtime.scene, "dialog", function()
      return Components.text("dialog")
    end, { transition = "none" })
    startDrag(0, 0, 1)
    runtime:keypressed("escape")

    assert.are.equal("escape", reason)
    assert.are.equal("open", runtime.scene.layers[1].state)
  end)

  it("cancels active drags when the pointer leaves the viewport", function()
    local reason = nil
    local startDrag = ui.drag({
      onCancel = function(ctx)
        reason = ctx.reason
      end,
    })

    ui.runtime.viewportBackend = {
      isEnabled = function()
        return true
      end,
      screenToViewport = function()
        return false, nil, nil
      end,
    }

    startDrag(4, 4, 1)
    ui.mousemoved(200, 200)

    assert.are.equal("viewport", reason)
  end)

  it("cancels active drags from installed focus callbacks", function()
    local fakeLove = {}
    local reason = nil
    local unregister = ui.install(fakeLove)
    local startDrag = ui.drag({
      onCancel = function(ctx)
        reason = ctx.reason
      end,
    })

    startDrag(4, 4, 1)
    fakeLove.focus(false)
    unregister()

    assert.are.equal("focus", reason)
  end)
end)
