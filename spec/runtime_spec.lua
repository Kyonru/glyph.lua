package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("glyph.runtime")
local Components = require("glyph.components")

describe("runtime", function()
  it("persists useState values across renders", function()
    local runtime = Runtime.new()
    local setCount

    local function App()
      local count, nextCount = runtime:useState(0)
      setCount = nextCount
      return Components.text("Count: " .. count)
    end

    runtime:build(App)
    assert.are.equal("Count: 0", runtime.root.value)

    setCount(2)
    runtime:build(App)
    assert.are.equal("Count: 2", runtime.root.value)
  end)

  it("runs effects when deps change and cleans up previous effect", function()
    local runtime = Runtime.new()
    local dep = 1
    local calls = {}

    local function App()
      local captured = dep
      runtime:useEffect(function()
        calls[#calls + 1] = "effect " .. captured
        return function()
          calls[#calls + 1] = "cleanup " .. captured
        end
      end, { dep })

      return Components.text("ok")
    end

    runtime:build(App)
    runtime:build(App)
    dep = 2
    runtime:build(App)

    assert.are.same({ "effect 1", "cleanup 1", "effect 2" }, calls)
  end)

  it("memo returns cached nodes for unchanged deps", function()
    local runtime = Runtime.new()
    local builds = 0

    local function subtree()
      builds = builds + 1
      return Components.text("static")
    end

    local first = runtime:memo(subtree, { 1 })
    local second = runtime:memo(subtree, { 1 })
    local third = runtime:memo(subtree, { 2 })

    assert.are.equal(first, second)
    assert.are_not.equal(second, third)
    assert.are.equal(2, builds)
  end)

  it("routes button clicks", function()
    local runtime = Runtime.new()
    local clicks = 0

    local function App()
      return Components.button({
        label = "Go",
        onClick = function()
          clicks = clicks + 1
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.equal(1, clicks)
  end)

  it("keeps button taps valid across a rerender between press and release", function()
    local runtime = Runtime.new()
    local clicks = 0

    local function App()
      return Components.button({
        label = "Go",
        onClick = function()
          clicks = clicks + 1
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousereleased(1, 1, 1)

    assert.are.equal(1, clicks)
  end)

  it("keeps tab taps valid across a rerender between press and release", function()
    local runtime = Runtime.new()
    local active

    local function App()
      return Components.tabs({
        active = active or 1,
        onChange = function(index)
          active = index
        end,
      }, {
        { label = "A", content = Components.text("a") },
        { label = "B", content = Components.text("b") },
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(36, 1, 1)
    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousereleased(36, 1, 1)

    assert.are.equal(2, active)
  end)

  it("routes controlled input text", function()
    local runtime = Runtime.new()
    local value = ""

    local function App()
      return Components.input({
        value = value,
        onChange = function(nextValue)
          value = nextValue
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:textinput("a")
    runtime:build(App)
    runtime:keypressed("backspace")

    assert.are.equal("", value)
  end)

  it("clamps scroll views to their content bounds", function()
    local runtime = Runtime.new()

    local function App()
      local rows = {}
      for index = 1, 10 do
        rows[index] = Components.box({ width = 100, height = 20 })
      end

      return Components.scrollView({
        width = 100,
        height = 60,
        gap = 0,
      }, rows)
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:setHover(runtime.root)
    runtime:wheelmoved(0, -100)

    assert.are.equal(140, runtime.scrollOffsets["0"])

    runtime:wheelmoved(0, 100)
    assert.are.equal(0, runtime.scrollOffsets["0"])
  end)

  it("draws a customizable scroll indicator when content overflows", function()
    local runtime = Runtime.new()
    local rects = {}

    runtime:setLove({
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
        rectangle = function(mode, x, y, width, height)
          rects[#rects + 1] = { mode = mode, x = x, y = y, width = width, height = height }
        end,
        print = function() end,
        push = function() end,
        pop = function() end,
        setScissor = function() end,
      },
    })

    local function App()
      local rows = {}
      for index = 1, 10 do
        rows[index] = Components.box({ width = 100, height = 20 })
      end

      return Components.scrollView({
        width = 100,
        height = 60,
        scrollbar = {
          width = 8,
          padding = 2,
          trackColor = { 0, 0, 0, 1 },
          thumbColor = { 1, 1, 1, 1 },
        },
      }, rows)
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(2, #rects)
    assert.are.equal(8, rects[1].width)
    assert.are.equal(8, rects[2].width)
    assert.is_true(rects[2].height < 56)
  end)

  it("routes overlapping stack clicks to the topmost child", function()
    local runtime = Runtime.new()
    local clicked = nil

    local function App()
      return Components.stack({ width = 100, height = 100 }, {
        Components.button({ label = "Bottom", width = 100, height = 100, onClick = function() clicked = "bottom" end }),
        Components.button({ label = "Top", width = 100, height = 100, onClick = function() clicked = "top" end }),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(10, 10, 1)
    runtime:mousereleased(10, 10, 1)

    assert.are.equal("top", clicked)
  end)

  it("uses zIndex for stack hit testing", function()
    local runtime = Runtime.new()
    local clicked = nil

    local function App()
      return Components.stack({ width = 100, height = 100 }, {
        Components.button({ label = "Top", width = 100, height = 100, zIndex = 10, onClick = function() clicked = "z" end }),
        Components.button({ label = "Later", width = 100, height = 100, onClick = function() clicked = "later" end }),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(10, 10, 1)
    runtime:mousereleased(10, 10, 1)

    assert.are.equal("z", clicked)
  end)

  it("lets non-interactive absolute decoration pass clicks through", function()
    local runtime = Runtime.new()
    local clicked = false

    local function App()
      return Components.stack({ width = 100, height = 100 }, {
        Components.button({ label = "Button", width = 100, height = 100, onClick = function() clicked = true end }),
        Components.box({ position = "absolute", inset = 0, zIndex = 10, interactive = false }),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(10, 10, 1)
    runtime:mousereleased(10, 10, 1)

    assert.is_true(clicked)
  end)

  it("restores stencil state after clipped child drawing", function()
    local runtime = Runtime.new()
    local calls = {}

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        getStencilTest = function() return "greater", 2 end,
        stencil = function(fn, action, value)
          calls[#calls + 1] = { "stencil", action, value }
          fn()
        end,
        setStencilTest = function(compare, value)
          calls[#calls + 1] = { "stencilTest", compare, value }
        end,
        setColor = function() end,
        rectangle = function() end,
        polygon = function() end,
        print = function() end,
      },
    })

    local function App()
      return Components.box({
        width = 100,
        height = 60,
        clip = { kind = "skew", skew = 12 },
      }, {
        Components.text("inside"),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "stencil", "replace", 1 }, calls[1])
    assert.are.same({ "stencilTest", "equal", 1 }, calls[2])
    assert.are.same({ "stencilTest", "greater", 2 }, calls[#calls])
  end)

  it("restores rectangular clip scissor state", function()
    local runtime = Runtime.new()
    local scissor = { 10, 8, 200, 200 }
    local calls = {}

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        getScissor = function()
          if scissor then
            return scissor[1], scissor[2], scissor[3], scissor[4]
          end
          return nil
        end,
        setScissor = function(x, y, width, height)
          calls[#calls + 1] = { x, y, width, height }
          if x == nil then
            scissor = nil
          else
            scissor = { x, y, width, height }
          end
        end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
      },
    })

    local function App()
      return Components.box({
        width = 100,
        height = 60,
        clip = true,
      }, {
        Components.text("inside"),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ 10, 8, 90, 52 }, calls[1])
    assert.are.same({ 10, 8, 200, 200 }, calls[#calls])
  end)

  it("keeps clipping visual-only for hit testing", function()
    local runtime = Runtime.new()
    local clicked = false

    local function App()
      return Components.box({
        width = 100,
        height = 60,
        clip = { kind = "circle" },
      }, {
        Components.button({
          label = "wide",
          width = 100,
          height = 60,
          onClick = function()
            clicked = true
          end,
        }),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(2, 2, 1)
    runtime:mousereleased(2, 2, 1)

    assert.is_true(clicked)
  end)
end)
