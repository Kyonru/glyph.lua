package.path = "./?.lua;./?/init.lua;./examples/?.lua;" .. package.path

local ui = require("glyph")
local example = require("examples.juice.example")

local function activePadLabel()
  local found = nil

  local function walk(node)
    if node.type == "button" and node.props and node.props.active then
      found = node.props.label
      return
    end
    for _, child in ipairs(node.children or {}) do
      walk(child)
    end
  end

  walk(example.component())
  return found
end

describe("juice example", function()
  local originalMarkDirty
  local dirtyCount

  before_each(function()
    example.teardown()
    originalMarkDirty = ui.runtime.markDirty
    dirtyCount = 0
    ui.runtime.markDirty = function()
      dirtyCount = dirtyCount + 1
    end
  end)

  after_each(function()
    ui.runtime.markDirty = originalMarkDirty
    example.teardown()
  end)

  it("replays the pattern from its first pad after every completed round", function()
    example.update(0.01)
    assert.are.equal("Pulse\n1", activePadLabel())

    example.update(0.43)
    example.update(0.17)
    assert.are.equal("Spark\n3", activePadLabel())

    example.update(0.43)
    example.update(0.17)
    assert.are.equal("Bloom\n2", activePadLabel())

    example.update(0.43)
    example.update(0.17)
    assert.is_nil(activePadLabel())

    example.keypressed("1")
    example.update(0.19)
    example.keypressed("3")
    example.update(0.19)
    example.keypressed("2")

    assert.is_nil(activePadLabel())
    dirtyCount = 0
    example.update(0.01)

    assert.are.equal("Pulse\n1", activePadLabel())
    assert.are.equal(1, dirtyCount)
  end)
end)
