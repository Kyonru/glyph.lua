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
end)
