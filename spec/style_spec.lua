package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("glyph.runtime")
local Style = require("glyph.style")
local Components = require("glyph.components")

local function color(value)
  return { value, value, value, 1 }
end

describe("style", function()
  it("resolves theme, component, variant, state, and inline precedence", function()
    local runtime = Runtime.new()
    runtime.theme = {
      version = 1,
      base = {
        color = color(1),
        background = color(1),
      },
      components = {
        button = {
          background = color(2),
          color = color(2),
          hover = {
            background = color(3),
          },
          variants = {
            primary = {
              color = color(4),
              hover = {
                background = color(5),
              },
            },
          },
        },
      },
    }

    local node = Components.button({
      variant = "primary",
      style = {
        color = color(6),
        hover = {
          background = color(7),
        },
      },
    })
    node.path = "0"

    local resolved = Style.resolve(node, runtime, { hover = true })

    assert.are.same(color(7), resolved.background)
    assert.are.same(color(6), resolved.color)
  end)

  it("normalizes legacy visual props", function()
    local runtime = Runtime.new()
    local node = Components.box({
      backgroundColor = color(2),
      borderColor = color(3),
      borderWidth = 4,
      radius = 5,
    })
    node.path = "0"

    local resolved = Style.resolve(node, runtime, {})

    assert.are.same(color(2), resolved.background)
    assert.are.same(color(3), resolved.borderColor)
    assert.are.equal(4, resolved.borderWidth)
    assert.are.equal(5, resolved.radius)
  end)

  it("uses active and disabled state styles", function()
    local runtime = Runtime.new()
    runtime.theme = {
      version = 1,
      base = {},
      components = {
        tab = {
          background = color(1),
          active = {
            background = color(2),
          },
          disabled = {
            color = color(3),
          },
        },
      },
    }

    local node = Components.button({
      active = true,
      disabled = true,
    })
    node.type = "tab"
    node.path = "0"

    local resolved = Style.resolve(node, runtime, {
      active = true,
      disabled = true,
    })

    assert.are.same(color(2), resolved.background)
    assert.are.same(color(3), resolved.color)
  end)

  it("invalidates static style cache when theme version changes", function()
    local runtime = Runtime.new()
    runtime.theme = {
      version = 1,
      base = { color = color(1) },
      components = {},
    }

    local node = Components.static(Components.text("Cached"))
    node.path = "0"

    local first = Style.resolve(node, runtime, {})
    local second = Style.resolve(node, runtime, {})
    runtime.theme.version = 2
    runtime.theme.base.color = color(2)
    local third = Style.resolve(node, runtime, {})

    assert.are.equal(first, second)
    assert.are_not.equal(second, third)
    assert.are.same(color(2), third.color)
  end)

  it("draw context applies styles and restores Love2D state", function()
    local runtime = Runtime.new()
    local calls = {}
    local currentLineWidth = 1
    local currentShader = nil

    local fakeLove = {
      graphics = {
        getLineWidth = function()
          return currentLineWidth
        end,
        setLineWidth = function(value)
          currentLineWidth = value
          calls[#calls + 1] = { "lineWidth", value }
        end,
        getShader = function()
          return currentShader
        end,
        setShader = function(value)
          currentShader = value
          calls[#calls + 1] = { "shader", value }
        end,
        setColor = function(r, g, b, a)
          calls[#calls + 1] = { "color", r, g, b, a }
        end,
        rectangle = function(mode, x, y, width, height, rx)
          calls[#calls + 1] = { "rect", mode, width, height, rx }
        end,
        print = function(text)
          calls[#calls + 1] = { "print", text }
        end,
      },
    }

    runtime:setLove(fakeLove)

    local shader = {}
    local function App()
      return Components.button({
        label = "Run",
        style = {
          background = color(2),
          borderColor = color(3),
          borderWidth = 3,
          radius = 6,
          color = color(4),
          shader = shader,
        },
      })
    end

    runtime:build(App)
    runtime.root.layout = { x = 0, y = 0, width = 80, height = 24 }
    runtime:draw(runtime.root)

    assert.are.equal(1, currentLineWidth)
    assert.is_nil(currentShader)
    assert.are.same({ "lineWidth", 3 }, calls[1])
    assert.are.same({ "shader", shader }, calls[2])
    assert.are.same({ "rect", "fill", 80, 24, 6 }, calls[4])
  end)

  it("updates derived component defaults from top-level theme colors", function()
    local theme = dofile("glyph/theme.lua")
    local nextSurface = color(8)

    theme.merge({
      surfaceColor = nextSurface,
      components = {
        button = {
          variants = {
            warning = {
              background = color(9),
            },
          },
        },
      },
    })

    assert.are.same(nextSurface, theme.components.button.background)
    assert.are.same(color(9), theme.components.button.variants.warning.background)
  end)
end)
