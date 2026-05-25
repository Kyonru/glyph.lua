package.path = "./?.lua;./?/init.lua;" .. package.path

local Components = require("glyph.components")
local Runtime = require("glyph.runtime")
local Modal = require("glyph.modal")
local Transitions = require("glyph.transitions")
local Accessibility = require("glyph.accessibility")

local function textComponent(value)
  return function()
    return Components.text(value)
  end
end

local function makeLove(overrides)
  overrides = overrides or {}
  local calls = overrides.calls or {}
  local g = {
    setColor = overrides.setColor or function(...)
      calls[#calls + 1] = { "setColor", ... }
    end,
    rectangle = overrides.rectangle or function(...)
      calls[#calls + 1] = { "rectangle", ... }
    end,
    push = overrides.push or function(...)
      calls[#calls + 1] = { "push", ... }
    end,
    pop = overrides.pop or function()
      calls[#calls + 1] = { "pop" }
    end,
    translate = overrides.translate or function(...)
      calls[#calls + 1] = { "translate", ... }
    end,
    scale = overrides.scale or function(...)
      calls[#calls + 1] = { "scale", ... }
    end,
    rotate = overrides.rotate or function(...)
      calls[#calls + 1] = { "rotate", ... }
    end,
    getDimensions = overrides.getDimensions or function()
      return 800, 600
    end,
    getLineWidth = function()
      return 1
    end,
    setLineWidth = function(...) calls[#calls + 1] = { "setLineWidth", ... } end,
    getShader = function()
      return "previous-shader"
    end,
    setShader = function(...) calls[#calls + 1] = { "setShader", ... } end,
    getBlendMode = function()
      return "alpha", "alphamultiply"
    end,
    setBlendMode = function(...) calls[#calls + 1] = { "setBlendMode", ... } end,
    getFont = function()
      return nil
    end,
    setFont = function(...) calls[#calls + 1] = { "setFont", ... } end,
    print = function(...) calls[#calls + 1] = { "print", ... } end,
    setScissor = function(...) calls[#calls + 1] = { "setScissor", ... } end,
    setStencilTest = function(...) calls[#calls + 1] = { "setStencilTest", ... } end,
  }
  return { graphics = g, calls = calls }
end

describe("Scene manager", function()
  it("set replaces the stack with a root scene", function()
    local runtime = Runtime.new()

    runtime.scene:push("overlay", textComponent("overlay"), { kind = "overlay" })
    runtime.scene:set("main", textComponent("main"))

    assert.are.equal(1, #runtime.scene.layers)
    assert.are.equal("main", runtime.scene.layers[1].id)
    assert.are.equal("scene", runtime.scene.layers[1].kind)
  end)

  it("push replaces duplicate ids instead of stacking duplicates", function()
    local runtime = Runtime.new()

    runtime.scene:push("a", textComponent("A"))
    runtime.scene:push("a", textComponent("B"))

    assert.are.equal(1, #runtime.scene.layers)
    assert.are.equal("a", runtime.scene.layers[1].id)
  end)

  it("close transitions a layer out and removes it after update", function()
    local runtime = Runtime.new()
    local closed = false

    runtime.scene:push("a", textComponent("A"), {
      transition = "fade",
      duration = 0,
      exitDuration = 0.5,
      onClose = function()
        closed = true
      end,
    })

    runtime.scene:close("a")
    assert.are.equal("exiting", runtime.scene.layers[1].state)

    runtime:update(0.5)
    assert.are.equal(0, #runtime.scene.layers)
    assert.is_true(closed)
  end)

  it("current returns the topmost non-exiting layer", function()
    local runtime = Runtime.new()

    runtime.scene:push("a", textComponent("A"))
    runtime.scene:push("b", textComponent("B"))
    runtime.scene:close("b")

    assert.are.equal("a", runtime.scene:current().id)
  end)

  it("modal wrapper maps to modal scene layers", function()
    local runtime = Runtime.new()

    Modal.open(runtime.scene, "settings", textComponent("settings"), { width = 200, height = 100 })

    assert.is_true(Modal.isOpen(runtime.scene, "settings"))
    assert.are.equal("modal", runtime.scene.layers[1].kind)
    assert.is_true(runtime.scene.layers[1].blocking)

    Modal.close(runtime.scene, "settings")
    assert.is_false(Modal.isOpen(runtime.scene, "settings"))
  end)
end)

describe("Scene runtime integration", function()
  before_each(function()
    Accessibility.configure({})
  end)

  it("isolates hook state per layer", function()
    local runtime = Runtime.new()
    local setA
    local setB

    runtime:setLove(makeLove())

    local function A()
      local count, setCount = runtime:useState(1)
      setA = setCount
      return Components.text("a:" .. count)
    end

    local function B()
      local count, setCount = runtime:useState(10)
      setB = setCount
      return Components.text("b:" .. count)
    end

    runtime.scene:push("a", A, { transition = "none" })
    runtime.scene:push("b", B, { transition = "none", kind = "overlay", blocking = false })
    runtime:render()

    setA(2)
    setB(11)
    runtime:render()

    assert.are.equal("a:2", runtime.scene.layers[1].root.value)
    assert.are.equal("b:11", runtime.scene.layers[2].root.value)
  end)

  it("routes clicks to the topmost blocking layer", function()
    local runtime = Runtime.new()
    local mainClicks = 0
    local modalClicks = 0

    runtime:setLove(makeLove())

    local function Main()
      return Components.button({ label = "main", onClick = function() mainClicks = mainClicks + 1 end })
    end

    local function Dialog()
      return Components.button({ label = "modal", width = 200, height = 40, onClick = function() modalClicks = modalClicks + 1 end })
    end

    runtime:render(Main)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)
    assert.are.equal(1, mainClicks)

    Modal.open(runtime.scene, "dialog", Dialog, { transition = "none", width = 200, height = 40 })
    runtime:render(Main)
    runtime:mousepressed(301, 281, 1)
    runtime:mousereleased(301, 281, 1)

    assert.are.equal(1, mainClicks)
    assert.are.equal(1, modalClicks)
  end)

  it("lets non-blocking overlays pass clicks through", function()
    local runtime = Runtime.new()
    local clicks = 0

    runtime:setLove(makeLove())

    local function Main()
      return Components.button({ label = "main", onClick = function() clicks = clicks + 1 end })
    end

    runtime.scene:push("hud", textComponent("hud"), {
      kind = "overlay",
      input = false,
      blocking = false,
      transition = "none",
    })

    runtime:render(Main)
    runtime:mousepressed(1, 1, 1)
    runtime:mousereleased(1, 1, 1)

    assert.are.equal(1, clicks)
  end)

  it("dismisses a modal when clicking its backdrop", function()
    local runtime = Runtime.new()

    runtime:setLove(makeLove())
    Modal.open(runtime.scene, "dialog", textComponent("dialog"), {
      transition = "none",
      width = 100,
      height = 100,
      dismissOnBackdrop = true,
    })
    runtime:render()

    runtime:mousepressed(700, 500, 1)
    assert.are.equal("exiting", runtime.scene.layers[1].state)
  end)

  it("escape closes the top escapable layer", function()
    local runtime = Runtime.new()

    Modal.open(runtime.scene, "dialog", textComponent("dialog"), { transition = "none" })
    runtime:keypressed("escape")

    assert.are.equal("exiting", runtime.scene.layers[1].state)
  end)

  it("includes modal layer semantics in accessibility snapshots", function()
    local runtime = Runtime.new()
    runtime:setLove(makeLove())

    local function Main()
      return Components.button({ label = "Main" })
    end

    local function Dialog()
      return Components.panel({
        title = "Settings",
        role = "dialog",
      }, {
        Components.button({ label = "Close" }),
      })
    end

    Modal.open(runtime.scene, "settings", Dialog, {
      transition = "none",
      width = 240,
      height = 120,
    })
    runtime:render(Main)

    local snapshot = Accessibility.snapshot(runtime)

    assert.are.equal("button", snapshot[1].role)
    assert.are.equal("Main", snapshot[1].label)
    assert.are.equal("dialog", snapshot[2].role)
    assert.are.equal("Settings", snapshot[2].label)
    assert.are.equal("button", snapshot[4].role)
    assert.are.equal("Close", snapshot[4].label)
  end)
end)

describe("transitions", function()
  it("normalizes named built-in transitions", function()
    local transition = Transitions.resolve("slide")

    assert.are.equal("slide", transition.name)
    assert.is_function(transition.draw)
  end)

  it("custom transitions receive context and can draw the layer", function()
    local runtime = Runtime.new()
    local called = false
    local drew = false

    runtime:setLove(makeLove())
    runtime.scene:push("custom", textComponent("custom"), {
      transition = Transitions.custom({
        duration = 0,
        draw = function(ctx)
          called = ctx.layer.id == "custom" and ctx.phase == "enter"
          ctx.drawLayer()
          drew = true
        end,
      }),
    })

    runtime:render()

    assert.is_true(called)
    assert.is_true(drew)
  end)

  it("rendering a transition restores graphics state", function()
    local runtime = Runtime.new()
    local loveModule = makeLove()

    runtime:setLove(loveModule)
    runtime.scene:push("a", textComponent("A"), { transition = "fade", duration = 0 })
    runtime:render()

    local hasPushAll = false
    local hasPop = false
    for _, call in ipairs(loveModule.calls) do
      if call[1] == "push" and call[2] == "all" then
        hasPushAll = true
      elseif call[1] == "pop" then
        hasPop = true
      end
    end

    assert.is_true(hasPushAll)
    assert.is_true(hasPop)
  end)

  it("animates layer transitions with animation specs", function()
    local runtime = Runtime.new()
    local loveModule = makeLove()

    runtime:setLove(loveModule)
    runtime.scene:push("animated", textComponent("A"), {
      transition = Transitions.animate({
        enter = {
          duration = 1,
          from = { y = 20, scale = 0.5 },
          to = { y = 0, scale = 1 },
        },
        exit = {
          duration = 1,
          to = { y = 20, scale = 0.8 },
        },
      }),
    })
    runtime:render()

    local translated = false
    local scaled = false
    for _, call in ipairs(loveModule.calls) do
      if call[1] == "translate" then
        translated = true
      elseif call[1] == "scale" then
        scaled = true
      end
    end

    assert.is_true(translated)
    assert.is_true(scaled)
  end)
end)
