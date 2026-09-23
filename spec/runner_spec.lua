package.path = "./?.lua;./?/init.lua;./examples/?.lua;" .. package.path

local Runner = require("runner")
local ui = require("glyph")

describe("example runner", function()
  local previousLove
  local previousRender

  before_each(function()
    previousLove = _G.love
    previousRender = ui.render
    _G.love = {}
  end)

  after_each(function()
    ui.render = previousRender
    _G.love = previousLove
  end)

  it("passes a stable root component so clean draws do not rebuild", function()
    local renderedRoot = nil
    local rootBuilds = 0

    ui.render = function(root)
      if root ~= renderedRoot then
        renderedRoot = root
        rootBuilds = rootBuilds + 1
        root()
      end
    end

    Runner.run({
      chrome = false,
      component = function()
        return ui.box({ width = 10, height = 10 })
      end,
    })

    love.draw()
    local firstRoot = renderedRoot
    love.draw()

    assert.is_function(firstRoot)
    assert.are.equal(firstRoot, renderedRoot)
    assert.are.equal(1, rootBuilds)
  end)

  it("keeps scene-owned examples on the component-free render path", function()
    local renderedRoot = "not-called"
    ui.render = function(root)
      renderedRoot = root
    end

    Runner.run({ usesScene = true })
    love.draw()

    assert.is_nil(renderedRoot)
  end)
end)
