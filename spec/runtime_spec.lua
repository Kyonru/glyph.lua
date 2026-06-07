package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("glyph.runtime")
local Components = require("glyph.components")
local Accessibility = require("glyph.accessibility")
local Animation = require("glyph.animation")
local Feedback = require("glyph.feedback")
local Style = require("glyph.style")

describe("runtime", function()
  before_each(function()
    Animation.clear()
    Accessibility.configure({})
    Feedback.clear()
  end)

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

  it("emits audio cues for hover, press, and activate", function()
    local runtime = Runtime.new()
    local cues = {}
    local clicks = 0
    runtime.theme = {
      version = 1,
      base = {},
      components = {
        button = {
          audio = {
            hover = "ui-hover",
            press = "ui-press",
            activate = "ui-activate",
          },
        },
      },
    }
    runtime:register("audio", function(event)
      cues[#cues + 1] = event.kind .. ":" .. event.cue .. ":" .. tostring(event.label)
    end)

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
    runtime:mousemoved(1, 1)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.equal(1, clicks)
    assert.are.same({
      "hover:ui-hover:Go",
      "press:ui-press:Go",
      "activate:ui-activate:Go",
    }, cues)
  end)

  it("emits audio cues for focus and keyboard press/release activation", function()
    local runtime = Runtime.new()
    local cues = {}
    local clicks = 0
    runtime.theme = {
      version = 1,
      base = {},
      components = {
        button = {
          audio = {
            focus = "ui-focus",
            press = "ui-press",
            activate = "ui-activate",
          },
        },
      },
    }
    runtime:register("audio", function(event)
      cues[#cues + 1] = event.kind .. ":" .. event.cue
    end)

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
    runtime:setFocus(runtime.root)
    runtime:keypressed("return")
    assert.are.equal(0, clicks)
    runtime:keyreleased("return")

    assert.are.equal(1, clicks)
    assert.are.same({
      "focus:ui-focus",
      "press:ui-press",
      "activate:ui-activate",
    }, cues)
  end)

  it("uses the pressed state for keyboard activation until release", function()
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
    runtime:setFocus(runtime.root)

    runtime:keypressed("space")
    assert.is_true(Style.stateFor(runtime.root, runtime).pressed)
    assert.are.equal(0, clicks)

    runtime:keyreleased("space")
    assert.is_false(Style.stateFor(runtime.root, runtime).pressed)
    assert.are.equal(1, clicks)
  end)

  it("does not emit press or activate audio for disabled buttons", function()
    local runtime = Runtime.new()
    local cues = {}
    runtime.theme = {
      version = 1,
      base = {},
      components = {
        button = {
          audio = {
            press = "ui-press",
            activate = "ui-activate",
          },
        },
      },
    }
    runtime:register("audio", function(event)
      cues[#cues + 1] = event.kind
    end)

    local function App()
      return Components.button({
        label = "Nope",
        disabled = true,
        onClick = function() end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)
    runtime:keypressed("return")

    assert.are.same({}, cues)
  end)

  it("does not emit audio when no cue resolves", function()
    local runtime = Runtime.new()
    local count = 0
    runtime:register("audio", function()
      count = count + 1
    end)

    local function App()
      return Components.button({ label = "Quiet", onClick = function() end })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousemoved(1, 1)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.equal(0, count)
  end)

  it("emits accessibility focus announcements", function()
    local runtime = Runtime.new()
    local events = {}

    runtime:register("accessibility", function(event)
      events[#events + 1] = event.kind .. ":" .. event.message
    end)

    local function App()
      return Components.button({
        label = "Go",
        accessibilityDescription = "Starts the mission",
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:setFocus(runtime.root)

    assert.are.same({
      "focus:Go, button, Starts the mission",
    }, events)
  end)

  it("emits accessibility activation announcements for mouse and keyboard activation", function()
    local runtime = Runtime.new()
    local events = {}
    local clicks = 0

    runtime:register("accessibility", function(event)
      if event.kind == "activate" then
        events[#events + 1] = event.message
      end
    end)

    local function App()
      return Components.button({
        label = "Confirm",
        onClick = function()
          clicks = clicks + 1
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)
    runtime:setFocus(runtime.root)
    runtime:keypressed("return")
    runtime:keyreleased("return")

    assert.are.equal(2, clicks)
    assert.are.same({ "Confirm, button", "Confirm, button" }, events)
  end)

  it("does not emit accessibility activation for disabled buttons", function()
    local runtime = Runtime.new()
    local events = {}

    runtime:register("accessibility", function(event)
      events[#events + 1] = event.kind
    end)

    local function App()
      return Components.button({
        label = "Locked",
        disabled = true,
        onClick = function() end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)
    runtime:setFocus(runtime.root)
    runtime:keypressed("return")
    runtime:keyreleased("return")

    assert.are.same({ "focus" }, events)
  end)

  it("announces live region changes once after the initial build", function()
    local runtime = Runtime.new()
    local events = {}
    local status = "Ready"

    runtime:register("accessibility", function(event)
      if event.kind == "live" then
        events[#events + 1] = event.message
      end
    end)

    local function App()
      return Components.text(status, {
        accessibilityLive = "polite",
      })
    end

    runtime:build(App)
    assert.are.same({}, events)
    status = "Enemy sighted"
    runtime:build(App)
    runtime:build(App)

    assert.are.same({ "Enemy sighted" }, events)
  end)

  it("emits feedback for hover, focus, press, release, and activate triggers", function()
    local runtime = Runtime.new()
    local events = {}

    Feedback.define("mark", {
      { kind = "emit", event = "mark" },
    })
    runtime:register("feedback", function(event)
      events[#events + 1] = event.trigger .. ":" .. event.kind
    end)

    local function App()
      return Components.button({
        label = "Go",
        feedback = {
          hover = "mark",
          focus = "mark",
          press = "mark",
          release = "mark",
          activate = "mark",
        },
        onClick = function() end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousemoved(1, 1)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.same({
      "hover:mark",
      "press:mark",
      "focus:mark",
      "release:mark",
      "activate:mark",
    }, events)
  end)

  it("does not emit activate feedback for disabled buttons", function()
    local runtime = Runtime.new()
    local events = {}

    Feedback.define("mark", {
      { kind = "emit", event = "mark" },
    })
    runtime:register("feedback", function(event)
      events[#events + 1] = event.trigger
    end)

    local function App()
      return Components.button({
        label = "Nope",
        disabled = true,
        feedback = {
          activate = "mark",
        },
        onClick = function() end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.same({}, events)
  end)

  it("runs manual error feedback", function()
    local runtime = Runtime.new()
    local events = {}

    Feedback.define("error.bump", {
      { kind = "emit", event = "error" },
    })
    runtime:register("feedback", function(event)
      events[#events + 1] = event.trigger .. ":" .. event.kind
    end)

    local function App()
      return Components.button({ label = "Go" })
    end

    runtime:build(App)
    Feedback.play(runtime, "error.bump", runtime.root, { trigger = "error" })

    assert.are.same({ "error:error" }, events)
  end)

  it("runs feedback animation without changing layout or hit testing", function()
    local runtime = Runtime.new()

    Feedback.define("shift", {
      {
        kind = "animate",
        duration = 0.1,
        to = { x = 10, scale = 1.2 },
      },
    })

    local function App()
      return Components.button({
        label = "Go",
        width = 80,
        height = 30,
        feedback = {
          press = "shift",
        },
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    local layoutX = runtime.root.layout.x
    local layoutWidth = runtime.root.layout.width

    runtime:mousepressed(1, 1, 1)
    runtime:update(0.1)

    assert.are.equal(layoutX, runtime.root.layout.x)
    assert.are.equal(layoutWidth, runtime.root.layout.width)
    assert.are.equal(10, runtime.root._glyphFeedback.x)
    assert.are.equal(1.2, runtime.root._glyphFeedback.scale)
    assert.are.equal(runtime.root, runtime:hitTest(1, 1))
  end)

  it("emits audio from feedback steps", function()
    local runtime = Runtime.new()
    local cues = {}

    Feedback.define("pop", {
      { kind = "audio", cue = "ui-pop" },
    })
    runtime:register("audio", function(event)
      cues[#cues + 1] = event.kind .. ":" .. event.cue .. ":" .. tostring(event.label)
    end)

    local function App()
      return Components.button({
        label = "Go",
        feedback = {
          activate = "pop",
        },
        onClick = function() end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.same({ "feedback:ui-pop:Go" }, cues)
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

  it("hit tests scroll view children at their scrolled visual position", function()
    local runtime = Runtime.new()
    local clicked = nil

    local function App()
      local rows = {}
      for index = 1, 6 do
        rows[index] = Components.button({
          label = "Row " .. index,
          width = 100,
          height = 20,
          onClick = function()
            clicked = index
          end,
        })
      end

      return Components.scrollView({
        width = 100,
        height = 60,
        gap = 0,
      }, rows)
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime.scrollOffsets["0"] = 40

    runtime:mousemoved(10, 10)
    assert.are.equal("Row 3", runtime.hoverNode.props.label)

    runtime:mousepressed(10, 10, 1)
    runtime:mousereleased(10, 10, 1)
    assert.are.equal(3, clicked)
  end)

  it("does not hit scroll view children outside the clipped viewport", function()
    local runtime = Runtime.new()

    local function App()
      local rows = {}
      for index = 1, 6 do
        rows[index] = Components.button({
          label = "Row " .. index,
          width = 100,
          height = 20,
        })
      end

      return Components.scrollView({
        width = 100,
        height = 60,
        gap = 0,
      }, rows)
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)

    assert.is_nil(runtime:hitTest(10, 80))
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

  it("draws root-scoped absolute nodes above later sibling branches", function()
    local runtime = Runtime.new()
    local calls = {}

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
      },
    })

    local function App()
      return Components.row({ width = 220, height = 120 }, {
        Components.box({ width = 100, height = 100 }, {
          Components.box({
            position = "absolute",
            left = 80,
            top = 0,
            width = 100,
            height = 100,
            zScope = "root",
            zIndex = 5,
            draw = function()
              calls[#calls + 1] = "floating"
            end,
          }),
        }),
        Components.box({
          width = 100,
          height = 100,
          draw = function()
            calls[#calls + 1] = "later"
          end,
        }),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "later", "floating" }, calls)
  end)

  it("hit tests root-scoped absolute nodes before later sibling branches", function()
    local runtime = Runtime.new()
    local clicked = nil

    local function App()
      return Components.row({ width = 220, height = 120 }, {
        Components.box({ width = 100, height = 100 }, {
          Components.button({
            label = "Floating",
            position = "absolute",
            left = 80,
            top = 0,
            width = 100,
            height = 100,
            zScope = "root",
            zIndex = 5,
            onClick = function()
              clicked = "floating"
            end,
          }),
        }),
        Components.button({
          label = "Later",
          width = 100,
          height = 100,
          onClick = function()
            clicked = "later"
          end,
        }),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(110, 20, 1)
    runtime:mousereleased(110, 20, 1)

    assert.are.equal("floating", clicked)
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

  it("converts rectangular clip scissor bounds through the viewport backend", function()
    local runtime = Runtime.new()
    local calls = {}

    runtime.viewportBackend = {
      isEnabled = function()
        return true
      end,
      viewportToScreen = function(x, y)
        return 20 + x * 2, 30 + y * 2
      end,
    }

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        getScissor = function() return nil end,
        setScissor = function(x, y, width, height)
          calls[#calls + 1] = { x, y, width, height }
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

    assert.are.same({ 20, 30, 200, 120 }, calls[1])
    assert.is_nil(calls[#calls][1])
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

  it("starts enter animations on mounted nodes", function()
    local runtime = Runtime.new()
    local colors = {}

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        setColor = function(...)
          colors[#colors + 1] = { ... }
        end,
        rectangle = function() end,
        print = function() end,
        push = function() end,
        pop = function() end,
        translate = function() end,
        scale = function() end,
      },
    })

    local function App()
      return Components.box({
        key = "animated",
        width = 20,
        height = 20,
        enter = {
          duration = 1,
          ease = "linear",
          from = { opacity = 0 },
          to = { opacity = 1 },
        },
        style = { background = { 1, 1, 1, 1 } },
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)
    assert.are.equal(0, colors[1][4])

    runtime:update(0.5)
    colors = {}
    runtime:draw(runtime.root)
    assert.are.equal(0.5, colors[1][4])
  end)

  it("keeps removed nodes drawable until exit animation completes", function()
    local runtime = Runtime.new()
    local show = true
    local rects = 0

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function()
          rects = rects + 1
        end,
        print = function() end,
        push = function() end,
        pop = function() end,
        translate = function() end,
        scale = function() end,
      },
    })

    local function App()
      local children = {}
      if show then
        children[1] = Components.box({
          key = "panel",
          width = 20,
          height = 20,
          exit = {
            duration = 1,
            ease = "linear",
            to = { opacity = 0, x = 10 },
          },
          style = { background = { 1, 1, 1, 1 } },
        })
      end
      return Components.column({ width = 100, height = 100 }, children)
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    show = false
    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    rects = 0
    runtime:draw(runtime.root)
    assert.are.equal(1, rects)

    runtime:update(1)
    assert.are.equal(0, #runtime.exitAnimations)
  end)

  it("keeps animation visual-only for hit testing", function()
    local runtime = Runtime.new()
    local clicked = false

    local function App()
      return Components.button({
        label = "Move visually",
        width = 100,
        height = 40,
        enter = {
          duration = 1,
          from = { x = 120 },
          to = { x = 120 },
        },
        onClick = function()
          clicked = true
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:mousepressed(10, 10, 1)
    runtime:mousereleased(10, 10, 1)

    assert.is_true(clicked)
  end)

  it("renders inside a managed viewport backend", function()
    local runtime = Runtime.new()
    local calls = {}

    runtime.viewportBackend = {
      isEnabled = function() return true end,
      isManaged = function() return true end,
      dimensions = function() return 320, 180 end,
      beginDraw = function()
        calls[#calls + 1] = "begin"
        return true
      end,
      endDraw = function()
        calls[#calls + 1] = "end"
        return true
      end,
    }
    runtime:setLove({
      graphics = {
        getDimensions = function() return 999, 999 end,
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
      },
    })

    runtime:render(function()
      return Components.box({
        width = "100%",
        height = "100%",
        style = { background = { 1, 1, 1, 1 } },
      })
    end)

    assert.are.same({ "begin", "end" }, calls)
    assert.are.equal(320, runtime.root.layout.width)
    assert.are.equal(180, runtime.root.layout.height)
  end)

  it("does not wrap rendering when the viewport backend is attached", function()
    local runtime = Runtime.new()
    local calls = 0

    runtime.viewportBackend = {
      isEnabled = function() return true end,
      isManaged = function() return false end,
      dimensions = function() return 320, 180 end,
      beginDraw = function()
        calls = calls + 1
        return false
      end,
      endDraw = function()
        calls = calls + 1
      end,
    }
    runtime:setLove({
      graphics = {
        getDimensions = function() return 999, 999 end,
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getShader = function() return nil end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
      },
    })

    runtime:render(function()
      return Components.box({ width = "100%", height = "100%" })
    end)

    assert.are.equal(0, calls)
    assert.are.equal(320, runtime.root.layout.width)
  end)
end)
