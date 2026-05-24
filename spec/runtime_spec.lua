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
end)
