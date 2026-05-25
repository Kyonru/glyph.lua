package.path = "./?.lua;./?/init.lua;" .. package.path

local ViewportBackend = require("glyph.viewport_backend")
local Responsive = require("glyph.responsive")
local Runtime = require("glyph.runtime")

describe("viewport backend", function()
  it("configures a managed shove backend", function()
    local backend = ViewportBackend.new()
    local calls = {}
    local shove = {
      setResolution = function(width, height, opts)
        calls[#calls + 1] = { "setResolution", width, height, opts.fitMethod, opts.scalingFilter }
      end,
      setWindowMode = function(width, height, flags)
        calls[#calls + 1] = { "setWindowMode", width, height, flags.resizable }
      end,
      getViewportDimensions = function()
        return 320, 180
      end,
    }

    backend:configure({
      backend = "shove",
      instance = shove,
      width = 320,
      height = 180,
      fit = "pixel",
      filter = "nearest",
    }, {
      width = 960,
      height = 540,
      resizable = true,
    })

    assert.is_true(backend:isEnabled())
    assert.are.equal("shove", backend:backend())
    assert.are.same({ "setResolution", 320, 180, "pixel", "nearest" }, calls[1])
    assert.are.same({ "setWindowMode", 960, 540, true }, calls[2])
  end)

  it("configures a managed push backend with mapped fit values", function()
    local backend = ViewportBackend.new()
    local configured
    local push = {
      setupScreen = function(width, height, opts)
        configured = { width = width, height = height, upscale = opts.upscale, canvas = opts.canvas }
      end,
      getDimensions = function()
        return 400, 240
      end,
    }

    backend:configure({
      backend = "push",
      instance = push,
      width = 400,
      height = 240,
      fit = "pixel",
      canvas = true,
    }, {})

    assert.are.same({ width = 400, height = 240, upscale = "pixel-perfect", canvas = true }, configured)
  end)

  it("restores graphics state around managed push drawing", function()
    local backend = ViewportBackend.new()
    local calls = {}
    local push = {
      setupScreen = function() end,
      start = function()
        calls[#calls + 1] = "start"
      end,
      finish = function()
        calls[#calls + 1] = "finish"
      end,
    }
    local love = {
      graphics = {
        push = function(mode)
          calls[#calls + 1] = "push:" .. tostring(mode)
        end,
        pop = function()
          calls[#calls + 1] = "pop"
        end,
      },
    }

    backend:configure({
      backend = "push",
      instance = push,
      width = 400,
      height = 240,
    }, {}, love)

    assert.is_true(backend:beginDraw())
    assert.is_true(backend:endDraw())
    assert.are.same({ "push:all", "start", "finish", "pop" }, calls)
  end)

  it("does not initialize an attached backend", function()
    local backend = ViewportBackend.new()
    local setupCalls = 0
    local drawCalls = 0
    local push = {
      setupScreen = function()
        setupCalls = setupCalls + 1
      end,
      start = function()
        drawCalls = drawCalls + 1
      end,
      getDimensions = function()
        return 640, 360
      end,
    }

    backend:configure({
      backend = "push",
      instance = push,
      managed = false,
    }, {})

    assert.are.equal(0, setupCalls)
    assert.is_true(backend:beginDraw())
    assert.are.equal(1, drawCalls)
    assert.are.equal(640, ({ backend:dimensions() })[1])
  end)

  it("normalizes coordinate conversion", function()
    local backend = ViewportBackend.new()
    local push = {
      toGame = function(x, y)
        if x < 0 then
          return false, false
        end
        return x / 2, y / 2
      end,
      toReal = function(x, y)
        return x * 2, y * 2
      end,
    }

    backend:configure({
      backend = "push",
      instance = push,
      width = 320,
      height = 180,
      managed = false,
    }, {})

    assert.are.same({ true, 10, 12 }, { backend:screenToViewport(20, 24) })
    assert.are.same({ false, false, false }, { backend:screenToViewport(-1, 24) })
    assert.are.same({ 20, 24 }, { backend:viewportToScreen(10, 12) })
  end)

  it("keeps attached backends from mutating the window", function()
    local runtime = Runtime.new()
    local setModeCalls = 0
    runtime:setLove({
      window = {
        setMode = function()
          setModeCalls = setModeCalls + 1
        end,
      },
    })

    Responsive.configureWindow(runtime, {
      width = 960,
      height = 540,
      viewport = {
        backend = "push",
        instance = {
          getDimensions = function()
            return 320, 180
          end,
        },
        managed = false,
      },
    })

    assert.are.equal(0, setModeCalls)
    assert.are.equal(320, runtime.responsive.width)
    assert.are.equal(180, runtime.responsive.height)
  end)
end)
