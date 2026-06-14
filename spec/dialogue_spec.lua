package.path = "./?.lua;./?/init.lua;" .. package.path

local Dialogue = require("glyph.dialogue")

local fakeUi = {
  theme = {
    textColor = { 1, 1, 1, 1 },
    accent = { 1, 0.8, 0.3, 1 },
  },
}

-- Stub instance exposing the Glyph adapter methods (renderModel/selectChoice/...).
local function methodStub(state)
  local instance = { state = state, calls = { advance = 0, selected = nil, updated = 0, key = nil } }
  function instance:renderModel()
    local s = self.state
    return {
      active = s.isActive,
      status = s.status,
      opacity = s.boxOpacity,
      speaker = { name = s.currentCharacter, color = s.nameColor },
      text = { full = s.fullText, shown = s.displayedText, waiting = s.waitingForInput },
      effects = s.effects,
      choiceMode = s.choiceMode,
      selectedChoice = s.selectedChoice,
      choices = s.choices,
    }
  end
  function instance:selectChoice(index)
    self.calls.selected = index
    self.state.selectedChoice = index
    return index
  end
  function instance:isFinished()
    return not self.state.isActive
  end
  function instance:advance()
    self.calls.advance = self.calls.advance + 1
  end
  function instance:update()
    self.calls.updated = self.calls.updated + 1
  end
  function instance:keypressed(key)
    self.calls.key = key
  end
  return instance
end

-- Stub exposing only `.state` (no Glyph methods): exercises the fallback path.
local function stateStub(state)
  return { state = state }
end

local function collect(node, kind, out)
  out = out or {}
  if node.type == kind then
    out[#out + 1] = node
  end
  for _, child in ipairs(node.children or {}) do
    collect(child, kind, out)
  end
  return out
end

-- The portrait box (vs. the body box) is the drawable box with a numeric width.
local function findPortraitBox(node)
  if node.type == "box" and node.props and node.props.draw and type(node.props.width) == "number" then
    return node
  end
  for _, child in ipairs(node.children or {}) do
    local found = findPortraitBox(child)
    if found then
      return found
    end
  end
end

describe("dialogue adapter", function()
  it("normalizes the model from renderModel()", function()
    local instance = methodStub({
      isActive = true,
      status = "active",
      boxOpacity = 1,
      currentCharacter = "Hero",
      nameColor = { 0.2, 0.6, 1, 1 },
      fullText = "Hello",
      displayedText = "Hel",
      waitingForInput = false,
      choiceMode = false,
      selectedChoice = 1,
      choices = {},
    })
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    local model = adapter:model()

    assert.is_true(model.active)
    assert.are.equal("Hero", model.speaker.name)
    assert.are.equal("Hel", model.text.shown)
    assert.is_true(adapter:isActive())
  end)

  it("builds the model from .state for an instance without methods", function()
    local instance = stateStub({
      isActive = true,
      status = "active",
      boxOpacity = 1,
      currentCharacter = "Guide",
      characters = { Guide = { nameColor = { 1, 0, 0, 1 } } },
      fullText = "Pick one",
      displayedText = "Pick one",
      waitingForInput = false,
      choiceMode = true,
      selectedChoice = 1,
      activeChoices = {
        { parsedText = "Yes", target = "yes" },
        { text = "No", target = "no" },
      },
    })
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    local model = adapter:model()

    assert.are.equal("Guide", model.speaker.name)
    assert.are.same({ 1, 0, 0, 1 }, model.speaker.color)
    assert.are.equal(2, #model.choices)
    assert.are.equal("Yes", model.choices[1].text)
    assert.are.equal("No", model.choices[2].text)
  end)

  it("returns nil when not active", function()
    local adapter = Dialogue.new(fakeUi, { instance = methodStub({ isActive = false, choices = {} }) })
    assert.is_nil(adapter:component())
  end)

  it("builds speaker + body with no choices while speaking", function()
    local adapter = Dialogue.new(fakeUi, {
      instance = methodStub({
        isActive = true,
        status = "active",
        boxOpacity = 1,
        currentCharacter = "Hero",
        fullText = "Line",
        displayedText = "Line",
        waitingForInput = true,
        choiceMode = false,
        selectedChoice = 1,
        choices = {},
      }),
    })
    local node = adapter:component()
    assert.is_not_nil(node)

    local texts = collect(node, "text")
    local foundSpeaker = false
    for _, t in ipairs(texts) do
      if t.value == "Hero" then
        foundSpeaker = true
      end
    end
    assert.is_true(foundSpeaker)
    assert.are.equal(0, #collect(node, "button"))
    assert.is_true(#collect(node, "box") >= 1)
  end)

  it("renders choices as buttons and highlights the selected one", function()
    local instance = methodStub({
      isActive = true,
      status = "active",
      boxOpacity = 1,
      currentCharacter = "Hero",
      fullText = "Pick",
      displayedText = "Pick",
      waitingForInput = false,
      choiceMode = true,
      selectedChoice = 2,
      choices = {
        { text = "Alpha" },
        { text = "Beta" },
        { text = "Gamma" },
      },
    })
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    local node = adapter:component()

    local buttons = collect(node, "button")
    assert.are.equal(3, #buttons)
    assert.are.equal("Beta", buttons[2].props.label)
    -- selected uses the accent color; others use the text color
    assert.are.same(fakeUi.theme.accent, buttons[2].props.style.color)
    assert.are.same(fakeUi.theme.textColor, buttons[1].props.style.color)

    -- clicking a choice selects it and advances
    buttons[1].props.onClick()
    assert.are.equal(1, instance.calls.selected)
    assert.are.equal(1, instance.calls.advance)
  end)

  it("select() sets the chosen choice index", function()
    local instance = stateStub({ choiceMode = true, selectedChoice = 1, activeChoices = { {}, {}, {} } })
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    adapter:select(3)
    assert.are.equal(3, instance.state.selectedChoice)
  end)

  it("augments a wrapped instance with adapter methods at runtime", function()
    local instance = stateStub({ isActive = true, choiceMode = false })
    Dialogue.new(fakeUi, { instance = instance })
    assert.are.equal("function", type(instance.renderModel))
    assert.are.equal("function", type(instance.selectChoice))
    assert.are.equal("function", type(instance.isFinished))
    assert.is_false(instance:isFinished())
  end)

  it("wraps draw to honor config.renderless without editing the library", function()
    local drawn = 0
    local instance = { state = { isActive = true }, config = {}, draw = function()
      drawn = drawn + 1
    end }
    Dialogue.new(fakeUi, { instance = instance })

    instance:draw() -- renderless not set: draws
    assert.are.equal(1, drawn)

    instance.config.renderless = true
    instance:draw() -- suppressed
    assert.are.equal(1, drawn)
  end)

  it("forwards update and keypressed to the instance", function()
    local instance = methodStub({ isActive = true, choices = {} })
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    adapter:update(0.5)
    adapter:keypressed("space")
    assert.are.equal(1, instance.calls.updated)
    assert.are.equal("space", instance.calls.key)
    assert.is_true(adapter.elapsed >= 0.5)
  end)

  it("builds the portrait from the active character/expression", function()
    local instance = {
      config = { portraitEnabled = true, portraitSize = 120, portraitFlipH = true },
      state = {
        isActive = true,
        currentCharacter = "Hero",
        currentExpression = "Happy", -- not defined -> falls back to Default
        characters = {
          Hero = { expressions = { Default = { texture = "TEX", quad = "Q", w = 100, h = 108 } }, alpha = 1 },
        },
        activeChoices = {},
      },
    }
    local model = Dialogue.new(fakeUi, { instance = instance }):model()
    assert.is_not_nil(model.portrait)
    assert.are.equal("TEX", model.portrait.texture)
    assert.are.equal("Q", model.portrait.quad)
    assert.are.equal(120, model.portrait.size)
    assert.are.equal(100, model.portrait.width)
    assert.is_true(model.portrait.flipH)
    assert.are.equal(1, model.portrait.scale)
  end)

  it("omits the portrait when portraits are disabled", function()
    local instance = {
      config = { portraitEnabled = false, portraitSize = 120 },
      state = {
        isActive = true,
        currentCharacter = "Hero",
        currentExpression = "Default",
        characters = { Hero = { expressions = { Default = { texture = "TEX", w = 100, h = 108 } } } },
        activeChoices = {},
      },
    }
    assert.is_nil(Dialogue.new(fakeUi, { instance = instance }):model().portrait)
  end)

  it("places content in a row beside the portrait when present", function()
    local withPortrait = {
      renderModel = function()
        return {
          active = true,
          speaker = { name = "Hero" },
          text = { shown = "Hi", full = "Hi", waiting = false },
          choices = {},
          portrait = { texture = "TEX", quad = "Q", width = 100, height = 108, size = 120, flipH = false },
        }
      end,
    }
    local withoutPortrait = {
      renderModel = function()
        return { active = true, speaker = { name = "Hero" }, text = { shown = "Hi" }, choices = {} }
      end,
    }
    assert.are.equal(1, #collect(Dialogue.new(fakeUi, { instance = withPortrait }):component(), "row"))
    assert.are.equal(0, #collect(Dialogue.new(fakeUi, { instance = withoutPortrait }):component(), "row"))
  end)

  local function portraitStub(getExpression)
    return {
      update = function() end,
      renderModel = function()
        return {
          active = true,
          speaker = { name = "Hero" },
          expression = getExpression(),
          text = { shown = "" },
          choices = {},
          portrait = { texture = "T", width = 100, height = 100, size = 100, scale = 1 },
        }
      end,
    }
  end

  it("pops the portrait scale on speaker/expression change", function()
    local expr = "A"
    local adapter = Dialogue.new(fakeUi, { instance = portraitStub(function()
      return expr
    end) })

    adapter:update(0) -- first appearance: pop starts
    assert.is_true(adapter:portraitPopScale() < 1)

    adapter:update(1.0) -- past the pop duration: settled
    assert.are.equal(1, adapter:portraitPopScale())

    expr = "B" -- expression changes
    adapter:update(0) -- detect change: pop restarts
    assert.is_true(adapter:portraitPopScale() < 1)
  end)

  it("portraitPop = false disables the pop", function()
    local adapter = Dialogue.new(fakeUi, {
      instance = portraitStub(function()
        return "A"
      end),
      portraitPop = false,
    })
    adapter:update(0)
    assert.are.equal(1, adapter:portraitPopScale())
  end)

  it("grows the box height to fit choices", function()
    local choiceMode = false
    local instance = {
      update = function() end,
      renderModel = function()
        return {
          active = true,
          status = "active",
          speaker = { name = "H" },
          text = { shown = "" },
          choiceMode = choiceMode,
          choices = choiceMode and { { text = "a" }, { text = "b" }, { text = "c" } } or {},
        }
      end,
    }
    local adapter = Dialogue.new(fakeUi, { instance = instance, height = 160 })
    adapter:update(0.016)
    local base = adapter.boxHeight
    choiceMode = true
    for _ = 1, 120 do
      adapter:update(0.016)
    end
    assert.is_true(adapter.boxHeight > base)
  end)

  it("expands the box open from 0 while active", function()
    local instance = {
      update = function() end,
      renderModel = function()
        return { active = true, status = "active", speaker = { name = "H" }, text = { shown = "" }, choiceMode = false, choices = {} }
      end,
    }
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    adapter:update(0.016)
    assert.is_true(adapter.open > 0 and adapter.open < 1)
    for _ = 1, 240 do
      adapter:update(0.016)
    end
    assert.is_true(adapter.open > 0.99)
  end)

  it("clamps the grown height to maxHeight", function()
    local instance = {
      update = function() end,
      renderModel = function()
        return {
          active = true,
          status = "active",
          speaker = { name = "H" },
          text = { shown = "" },
          choiceMode = true,
          choices = { { text = "a" }, { text = "b" }, { text = "c" }, { text = "d" }, { text = "e" } },
        }
      end,
    }
    local adapter = Dialogue.new(fakeUi, { instance = instance, height = 200, choiceHeight = 40, maxHeight = 260 })
    for _ = 1, 200 do
      adapter:update(0.016)
    end
    assert.is_true(adapter.boxHeight <= 260.5)
  end)

  it("anchors the portrait per portraitAlign", function()
    local function portraitDrawY(align)
      local instance = {
        renderModel = function()
          return {
            active = true,
            speaker = { name = "H" },
            text = { shown = "" },
            choices = {},
            portrait = { texture = "T", quad = "Q", width = 100, height = 100, size = 120, scale = 1 },
          }
        end,
      }
      local node = Dialogue.new(fakeUi, { instance = instance, portraitAlign = align }):component()
      local portraitBox = findPortraitBox(node)
      local capturedY
      local fakeLove = {
        graphics = setmetatable({
          draw = function(_, _, _, y)
            capturedY = y
          end,
        }, { __index = function()
          return function() end
        end }),
      }
      portraitBox.props.draw(portraitBox, 0, 0, 120, 200, fakeLove)
      return capturedY
    end

    assert.are.equal(0, portraitDrawY("top")) -- top of the box
    assert.are.equal(80, portraitDrawY("bottom")) -- 200 - 120
    assert.are.equal(40, portraitDrawY("center")) -- (200 - 120) / 2
  end)

  it("portraitFit clamps the portrait to the box height", function()
    local function drawnSize(fit, boxHeight)
      local instance = {
        renderModel = function()
          return {
            active = true,
            speaker = { name = "H" },
            text = { shown = "" },
            choices = {},
            portrait = { texture = "T", quad = "Q", width = 100, height = 100, size = 120, scale = 1 },
          }
        end,
      }
      local node = Dialogue.new(fakeUi, { instance = instance, portraitFit = fit }):component()
      local portraitBox = findPortraitBox(node)
      local capturedSx
      local fakeLove = {
        graphics = setmetatable({
          draw = function(_, _, _, _, _, sx)
            capturedSx = sx
          end,
        }, { __index = function()
          return function() end
        end }),
      }
      portraitBox.props.draw(portraitBox, 0, 0, 120, boxHeight, fakeLove)
      return capturedSx * 100 -- scaled size = sx * native width
    end

    assert.are.equal(120, drawnSize(false, 80)) -- overflow: drawn at full 120 in an 80px box
    assert.are.equal(80, drawnSize(true, 80)) -- contained: clamped to the 80px box
    assert.are.equal(120, drawnSize(true, 200)) -- box is tall enough: stays 120
  end)

  it("applies portraitFilter to the portrait texture", function()
    local minFilter, magFilter
    local texture = {
      setFilter = function(_, min, mag)
        minFilter, magFilter = min, mag
      end,
    }
    local instance = {
      renderModel = function()
        return {
          active = true,
          speaker = { name = "H" },
          text = { shown = "" },
          choices = {},
          portrait = { texture = texture, quad = "Q", width = 100, height = 100, size = 120, scale = 1 },
        }
      end,
    }
    local node = Dialogue.new(fakeUi, { instance = instance, portraitFilter = "nearest" }):component()
    local portraitBox = findPortraitBox(node)
    local fakeLove = {
      graphics = setmetatable({}, { __index = function()
        return function() end
      end }),
    }
    portraitBox.props.draw(portraitBox, 0, 0, 120, 200, fakeLove)
    assert.are.equal("nearest", minFilter)
    assert.are.equal("nearest", magFilter)
  end)

  it("grows the box to fit tall wrapped text", function()
    local instance = {
      update = function() end,
      renderModel = function()
        return { active = true, status = "active", speaker = { name = "H" }, text = { shown = "", full = "x" }, choiceMode = false, choices = {} }
      end,
    }
    local adapter = Dialogue.new(fakeUi, { instance = instance, height = 130 })
    adapter:update(0.016)
    local baseH = adapter.boxHeight
    adapter.bodyTextHeight = 300 -- simulate a tall measured body
    for _ = 1, 200 do
      adapter:update(0.016)
    end
    assert.is_true(adapter.boxHeight > baseH + 100)
  end)

  it("measures the wrapped body text height from the draw", function()
    local longText = string.rep("word ", 40)
    local instance = {
      renderModel = function()
        return { active = true, speaker = { name = "H" }, text = { shown = "", full = longText }, choices = {} }
      end,
    }
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    local node = adapter:component()
    local bodyBox
    local function find(n)
      if n.type == "box" and n.props and type(n.props.draw) == "function" then
        bodyBox = n
      end
      for _, c in ipairs(n.children or {}) do
        find(c)
      end
    end
    find(node)

    local function stubFont()
      return setmetatable({}, { __index = function()
        return function()
          return 16
        end
      end })
    end
    local fakeLove = {
      graphics = setmetatable({
        getFont = function()
          return stubFont()
        end,
        setFont = function() end,
      }, { __index = function()
        return function() end
      end }),
    }
    bodyBox.props.draw(bodyBox, 0, 0, 100, 80, fakeLove)
    assert.is_true(adapter.bodyTextHeight > 0)
  end)

  it("aligns the body text left/center/right", function()
    local function firstPrintX(align)
      local instance = {
        renderModel = function()
          return { active = true, speaker = { name = "H" }, text = { shown = "hi", full = "hi" }, choices = {} }
        end,
      }
      local node = Dialogue.new(fakeUi, { instance = instance, textAlign = align }):component()
      local bodyBox
      local function find(n)
        if n.type == "box" and n.props and type(n.props.draw) == "function" and n.props.width == "100%" then
          bodyBox = n
        end
        for _, c in ipairs(n.children or {}) do
          find(c)
        end
      end
      find(node)
      local firstX
      local fakeLove = {
        graphics = setmetatable({
          getFont = function()
            return setmetatable({}, { __index = function()
              return function()
                return 16
              end
            end })
          end,
          setFont = function() end,
          print = function(_, px)
            firstX = firstX or px
          end,
        }, { __index = function()
          return function() end
        end }),
      }
      bodyBox.props.draw(bodyBox, 0, 0, 300, 100, fakeLove)
      return firstX
    end

    -- "hi" = 2 × 16px = 32 wide in a 300px line
    assert.are.equal(0, firstPrintX("left"))
    assert.are.equal(268, firstPrintX("right")) -- 300 - 32
    assert.are.equal(134, firstPrintX("center")) -- (300 - 32) / 2
  end)

  it("prefers per-call textAlign and keeps align as a back-compat alias", function()
    local function firstPrintX(props)
      local instance = {
        renderModel = function()
          return { active = true, speaker = { name = "H" }, text = { shown = "hi", full = "hi" }, choices = {} }
        end,
      }
      local node = Dialogue.new(fakeUi, { instance = instance }):component(props)
      local bodyBox
      local function find(n)
        if n.type == "box" and n.props and type(n.props.draw) == "function" and n.props.width == "100%" then
          bodyBox = n
        end
        for _, c in ipairs(n.children or {}) do
          find(c)
        end
      end
      find(node)
      local firstX
      local fakeLove = {
        graphics = setmetatable({
          getFont = function()
            return setmetatable({}, { __index = function()
              return function()
                return 16
              end
            end })
          end,
          setFont = function() end,
          print = function(_, px)
            firstX = firstX or px
          end,
        }, { __index = function()
          return function() end
        end }),
      }
      bodyBox.props.draw(bodyBox, 0, 0, 300, 100, fakeLove)
      return firstX
    end

    assert.are.equal(268, firstPrintX({ textAlign = "right" })) -- 300 - 32
    assert.are.equal(268, firstPrintX({ align = "right" })) -- legacy alias
    assert.are.equal(0, firstPrintX({ textAlign = "left" }))
  end)

  it("draws {bold} glyphs multiple times (faux bold)", function()
    local function printCount(effects)
      local instance = {
        renderModel = function()
          return { active = true, speaker = { name = "H" }, text = { shown = "ab", full = "ab" }, choices = {}, effects = effects }
        end,
      }
      local node = Dialogue.new(fakeUi, { instance = instance }):component()
      local bodyBox
      local function find(n)
        if n.type == "box" and n.props and type(n.props.draw) == "function" and n.props.width == "100%" then
          bodyBox = n
        end
        for _, c in ipairs(n.children or {}) do
          find(c)
        end
      end
      find(node)
      local count = 0
      local fakeLove = {
        graphics = setmetatable({
          getFont = function()
            return setmetatable({}, { __index = function()
              return function()
                return 16
              end
            end })
          end,
          setFont = function() end,
          print = function()
            count = count + 1
          end,
        }, { __index = function()
          return function() end
        end }),
      }
      bodyBox.props.draw(bodyBox, 0, 0, 300, 100, fakeLove)
      return count
    end

    assert.are.equal(2, printCount(nil)) -- "ab" plain: one print per glyph
    assert.are.equal(8, printCount({ { type = "bold", startIndex = 1, endIndex = 2 } })) -- 2 glyphs × 4 offsets
  end)

  it("exposes the fade transition from .state (and omits it at alpha 0)", function()
    local active = Dialogue.new(fakeUi, {
      instance = stateStub({ isActive = true, transition = { color = { 1, 1, 1 }, alpha = 0.7 }, activeChoices = {} }),
    }):model()
    assert.is_not_nil(active.transition)
    assert.are.equal(0.7, active.transition.alpha)
    assert.are.same({ 1, 1, 1 }, active.transition.color)

    local idle = Dialogue.new(fakeUi, {
      instance = stateStub({ isActive = true, transition = { color = { 0, 0, 0 }, alpha = 0 }, activeChoices = {} }),
    }):model()
    assert.is_nil(idle.transition)
  end)

  it("renders a fade overlay only while a transition is active", function()
    local alpha = 0
    local instance = {
      renderModel = function()
        return {
          active = true,
          speaker = { name = "H" },
          text = { shown = "" },
          choices = {},
          transition = alpha > 0 and { color = { 0, 0, 0 }, alpha = alpha } or nil,
        }
      end,
    }
    local adapter = Dialogue.new(fakeUi, { instance = instance })
    assert.is_nil(adapter:overlay()) -- no fade

    alpha = 0.5
    local node = adapter:overlay({ zIndex = 9 })
    assert.is_not_nil(node)
    assert.are.equal("box", node.type)
    assert.are.equal(9, node.props.zIndex)
  end)

  local function portraitModelStub()
    return {
      renderModel = function()
        return {
          active = true,
          speaker = { name = "H" },
          text = { shown = "" },
          choices = {},
          portrait = { texture = "T", quad = "Q", width = 100, height = 100, size = 120, flipH = false },
        }
      end,
    }
  end

  local function findRow(node)
    local row
    local function walk(n)
      if n.type == "row" then
        row = n
        return
      end
      for _, c in ipairs(n.children or {}) do
        walk(c)
      end
    end
    walk(node)
    return row
  end

  it("places the portrait on the requested side", function()
    local function portraitIndex(side)
      local row = findRow(Dialogue.new(fakeUi, { instance = portraitModelStub(), portraitSide = side }):component())
      for i, c in ipairs(row.children) do
        if findPortraitBox(c) then -- the portrait+name column
          return i
        end
      end
    end
    assert.are.equal(1, portraitIndex("left")) -- portrait first
    assert.are.equal(2, portraitIndex("right")) -- portrait last
  end)

  it("drops the inline portrait with portrait = false", function()
    local node = Dialogue.new(fakeUi, { instance = portraitModelStub() }):component({ portrait = false })
    assert.is_nil(findRow(node))
  end)

  it("auto-flips the portrait when on the right", function()
    local function sxSign(side)
      local pbox = findPortraitBox(Dialogue.new(fakeUi, { instance = portraitModelStub(), portraitSide = side }):component())
      local sx
      local fakeLove = {
        graphics = setmetatable({
          draw = function(_, _, _, _, _, s)
            sx = s
          end,
        }, { __index = function()
          return function()
            return 16
          end
        end }),
      }
      pbox.props.draw(pbox, 0, 0, 120, 200, fakeLove)
      return sx
    end
    assert.is_true(sxSign("left") > 0) -- not flipped (base flipH = false)
    assert.is_true(sxSign("right") < 0) -- auto-flipped on the right
  end)

  it("returns a standalone portrait node with layout (nil without a portrait)", function()
    local node = Dialogue.new(fakeUi, { instance = portraitModelStub() }):portrait({
      width = 120,
      height = 160,
      layout = { position = "absolute", zIndex = 7 },
    })
    assert.are.equal("box", node.type)
    assert.are.equal(7, node.props.zIndex)
    assert.are.equal("absolute", node.props.position)

    local none = Dialogue.new(fakeUi, {
      instance = { renderModel = function()
        return { active = true, speaker = { name = "H" }, text = { shown = "" }, choices = {} }
      end },
    })
    assert.is_nil(none:portrait())

    -- inactive dialogue: nil (its textures are released once it ends)
    local inactive = Dialogue.new(fakeUi, {
      instance = { renderModel = function()
        return { active = false, speaker = { name = "H" }, text = { shown = "" }, choices = {}, portrait = { texture = "T", width = 100, height = 100, size = 120 } }
      end },
    })
    assert.is_nil(inactive:portrait())
  end)

  it("uses a custom box frame instead of the default border", function()
    local instance = {
      renderModel = function()
        return { active = true, speaker = { name = "H" }, text = { shown = "" }, choices = {} }
      end,
    }
    local framed = false
    local node = Dialogue.new(fakeUi, { instance = instance }):component({
      frame = function()
        framed = true
      end,
    })
    assert.are.equal("function", type(node.props.draw))
    assert.is_nil(node.props.style.borderColor) -- default border replaced
    node.props.draw(node, 0, 0, 100, 50, { graphics = setmetatable({}, { __index = function()
      return function() end
    end }) }, nil, {})
    assert.is_true(framed)
  end)

  it("returns a flow node (not absolutely positioned) with flow = true", function()
    local instance = {
      renderModel = function()
        return { active = true, speaker = { name = "H" }, text = { shown = "" }, choices = {} }
      end,
    }
    local flow = Dialogue.new(fakeUi, { instance = instance }):component({ flow = true })
    assert.is_nil(flow.props.position) -- composable in a column/row
    assert.are.equal("100%", flow.props.width)

    local absolute = Dialogue.new(fakeUi, { instance = instance }):component()
    assert.are.equal("absolute", absolute.props.position)
  end)

  it("applies a nine-slice frame and stencil mask via the draw context", function()
    local node = Dialogue.new(fakeUi, { instance = portraitModelStub() }):portrait({
      frame = { image = "IMG" },
      stencil = { kind = "circle" },
    })
    local seen = {}
    local ctx = {
      nineSlice = function(_, image)
        seen.nineSlice = image
      end,
      stencil = function(_, shape, fn)
        seen.stencil = shape
        if fn then
          fn()
        end
      end,
    }
    local fakeLove = {
      graphics = setmetatable({
        draw = function()
          seen.drew = true
        end,
      }, { __index = function()
        return function()
          return 16
        end
      end }),
    }
    node.props.draw(node, 0, 0, 120, 120, fakeLove, nil, ctx)
    assert.are.equal("IMG", seen.nineSlice)
    assert.are.same({ kind = "circle" }, seen.stencil)
    assert.is_true(seen.drew) -- image drawn inside the stencil
  end)
end)
