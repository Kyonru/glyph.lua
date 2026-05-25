package.path = "./?.lua;./?/init.lua;" .. package.path

local Components = require("glyph.components")
local Runtime = require("glyph.runtime")
local Navigate = require("glyph.navigate")
local ui = require("glyph")

local function layout(runtime, root, width, height)
  runtime.root = root
  runtime:layoutRoot(root, width or 400, height or 400)
  return root
end

local function labels(candidates)
  local result = {}
  for _, candidate in ipairs(candidates) do
    result[#result + 1] = candidate.node.props.label
  end
  return result
end

local function fakeLove()
  return {
    graphics = {
      getDimensions = function() return 400, 300 end,
      getLineWidth = function() return 1 end,
      setLineWidth = function() end,
      getShader = function() return nil end,
      setShader = function() end,
      getBlendMode = function() return "alpha", "alphamultiply" end,
      setBlendMode = function() end,
      getFont = function() return nil end,
      setFont = function() end,
      setColor = function() end,
      rectangle = function() end,
      print = function() end,
      push = function() end,
      pop = function() end,
      translate = function() end,
      setScissor = function() end,
      setStencilTest = function() end,
    },
  }
end

describe("spatial navigation", function()
  it("chooses the top-left focusable node when nothing is focused", function()
    local runtime = Runtime.new()
    layout(runtime, Components.stack({ width = 300, height = 200 }, {
      Components.button({ label = "b", position = "absolute", left = 80, top = 20 }),
      Components.button({ label = "a", position = "absolute", left = 10, top = 20 }),
    }))

    local node = Navigate.move(runtime, "right")

    assert.are.equal("a", node.props.label)
    assert.are.equal(node, runtime.focusNode)
  end)

  it("moves spatially in all directions", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 300, height = 240 }, {
      Components.button({ label = "center", position = "absolute", left = 100, top = 90, width = 50, height = 30 }),
      Components.button({ label = "right", position = "absolute", left = 210, top = 90, width = 50, height = 30 }),
      Components.button({ label = "left", position = "absolute", left = 10, top = 90, width = 50, height = 30 }),
      Components.button({ label = "up", position = "absolute", left = 100, top = 10, width = 50, height = 30 }),
      Components.button({ label = "down", position = "absolute", left = 100, top = 180, width = 50, height = 30 }),
    }))

    runtime:setFocus(root.children[1])
    assert.are.equal("right", Navigate.move(runtime, "right").props.label)
    runtime:setFocus(root.children[1])
    assert.are.equal("left", Navigate.move(runtime, "left").props.label)
    runtime:setFocus(root.children[1])
    assert.are.equal("up", Navigate.move(runtime, "up").props.label)
    runtime:setFocus(root.children[1])
    assert.are.equal("down", Navigate.move(runtime, "down").props.label)
  end)

  it("includes custom focusable nodes and excludes disabled or non-interactive nodes", function()
    local runtime = Runtime.new()
    layout(runtime, Components.row({ gap = 8 }, {
      Components.box({ focusable = true, width = 20, height = 20, label = "custom" }),
      Components.button({ label = "disabled", disabled = true }),
      Components.button({ label = "hidden", interactive = false }),
      Components.button({ label = "off", focusable = false }),
      Components.input({ value = "input" }),
    }))

    assert.are.same({ "custom", nil }, labels(Navigate.collect(runtime)))
  end)

  it("limits candidates to a blocking modal layer", function()
    local runtime = Runtime.new()
    runtime:setLove(fakeLove())

    runtime.scene:set("main", function()
      return Components.button({ label = "main", width = 100, height = 40 })
    end, { transition = "none" })
    runtime.scene:push("dialog", function()
      return Components.button({ label = "modal", width = 100, height = 40 })
    end, { kind = "modal", transition = "none", width = 100, height = 40 })

    runtime:render()

    assert.are.same({ "modal" }, labels(Navigate.collect(runtime)))
  end)

  it("includes candidates below non-blocking overlays", function()
    local runtime = Runtime.new()
    runtime:setLove(fakeLove())

    runtime.scene:set("main", function()
      return Components.button({ label = "main", width = 100, height = 40 })
    end, { transition = "none" })
    runtime.scene:push("overlay", function()
      return Components.button({ label = "overlay", width = 100, height = 40 })
    end, { kind = "overlay", blocking = false, transition = "none", width = 100, height = 40 })

    runtime:render()

    assert.are.same({ "overlay", "main" }, labels(Navigate.collect(runtime)))
  end)

  it("allows navigate callbacks to cancel movement", function()
    local runtime = Runtime.new()
    layout(runtime, Components.row({ gap = 8 }, {
      Components.button({ label = "a" }),
      Components.button({ label = "b" }),
    }))
    runtime:setFocus(runtime.root.children[1])

    runtime:register("navigate", function()
      return false
    end)

    assert.is_nil(Navigate.move(runtime, "right"))
    assert.are.equal("a", runtime.focusNode.props.label)
  end)

  it("allows navigate callbacks to override the target", function()
    local runtime = Runtime.new()
    layout(runtime, Components.row({ gap = 8 }, {
      Components.button({ label = "a" }),
      Components.button({ label = "b" }),
      Components.button({ label = "c" }),
    }))
    runtime:setFocus(runtime.root.children[1])

    runtime:register("navigate", function()
      return runtime.root.children[3]
    end)

    assert.are.equal("c", Navigate.move(runtime, "right").props.label)
  end)

  it("passes origin, target, candidates, and scope metadata to navigate callbacks", function()
    local runtime = Runtime.new()
    local seen = nil
    local root = layout(runtime, Components.stack({ width = 300, height = 200 }, {
      Components.column({ navScope = true, position = "absolute", left = 10, top = 10, gap = 8 }, {
        Components.button({ label = "a", width = 80, height = 30 }),
        Components.button({ label = "b", width = 80, height = 30 }),
      }),
    }))
    runtime:setFocus(root.children[1].children[1])

    runtime:register("navigate", function(direction, target, candidates, context)
      seen = {
        direction = direction,
        target = target,
        candidates = candidates,
        origin = context.origin,
        scope = context.scope,
      }
    end)

    Navigate.move(runtime, "down")

    assert.are.equal("down", seen.direction)
    assert.are.equal(root.children[1].children[2], seen.target)
    assert.are.equal(root.children[1].children[1], seen.origin)
    assert.are.equal(root.children[1], seen.scope)
    assert.are.equal(2, #seen.candidates)
  end)

  it("stays inside nav groups when a directional candidate exists", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.row({ gap = 16 }, {
      Components.panel({ navGroup = "left", gap = 8 }, {
        Components.button({ label = "left-a" }),
        Components.button({ label = "left-b" }),
      }),
      Components.panel({ navGroup = "right", gap = 8 }, {
        Components.button({ label = "right-a" }),
      }),
    }))

    runtime:setFocus(root.children[1].children[1])
    assert.are.equal("left-b", Navigate.move(runtime, "down").props.label)
  end)

  it("falls back outside nav groups when no scoped candidate exists", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.row({ gap = 16 }, {
      Components.panel({ navGroup = "left", gap = 8 }, {
        Components.button({ label = "left-a" }),
      }),
      Components.panel({ navGroup = "right", gap = 8 }, {
        Components.button({ label = "right-a" }),
      }),
    }))

    runtime:setFocus(root.children[1].children[1])
    assert.are.equal("right-a", Navigate.move(runtime, "right").props.label)
  end)
end)

describe("row-end fallback and complex layouts", function()
  it("prefers a beam-overlap candidate over a nearer angled candidate", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 420, height = 320 }, {
      Components.button({ label = "origin", position = "absolute", left = 100, top = 40, width = 60, height = 30 }),
      Components.button({ label = "angled", position = "absolute", left = 175, top = 95, width = 70, height = 30 }),
      Components.button({ label = "beam", position = "absolute", left = 105, top = 210, width = 70, height = 30 }),
    }))

    runtime:setFocus(root.children[1])
    assert.are.equal("beam", Navigate.move(runtime, "down").props.label)
  end)

  it("keeps vertical movement in the current beam on uneven rows", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 420, height = 260 }, {
      Components.button({ label = "origin", position = "absolute", left = 150, top = 20, width = 70, height = 30 }),
      Components.button({ label = "near-left", position = "absolute", left = 35, top = 75, width = 70, height = 30 }),
      Components.button({ label = "column", position = "absolute", left = 165, top = 105, width = 70, height = 30 }),
    }))

    runtime:setFocus(root.children[1])
    assert.are.equal("column", Navigate.move(runtime, "down").props.label)
  end)

  it("down outside cone goes to leftmost item of nearest row below", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 400, height = 200 }, {
      -- top row
      Components.button({ label = "a", position = "absolute", left = 10,  top = 10, width = 80, height = 30 }),
      Components.button({ label = "b", position = "absolute", left = 100, top = 10, width = 80, height = 30 }),
      Components.button({ label = "c", position = "absolute", left = 190, top = 10, width = 80, height = 30 }),
      -- bottom row, shifted left — all outside the 45° cone from c
      Components.button({ label = "d", position = "absolute", left = 10,  top = 80, width = 80, height = 30 }),
      Components.button({ label = "e", position = "absolute", left = 100, top = 80, width = 80, height = 30 }),
    }))

    runtime:setFocus(root.children[3]) -- c (rightmost top)
    assert.are.equal("d", Navigate.move(runtime, "down").props.label)
  end)

  it("up outside cone goes to rightmost item of nearest row above", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 400, height = 200 }, {
      -- top row
      Components.button({ label = "a", position = "absolute", left = 10,  top = 10, width = 80, height = 30 }),
      Components.button({ label = "b", position = "absolute", left = 100, top = 10, width = 80, height = 30 }),
      Components.button({ label = "c", position = "absolute", left = 190, top = 10, width = 80, height = 30 }),
      -- single item far right — all top buttons are outside its 45° cone going up
      Components.button({ label = "d", position = "absolute", left = 290, top = 80, width = 80, height = 30 }),
    }))

    runtime:setFocus(root.children[4]) -- d (far right bottom)
    assert.are.equal("c", Navigate.move(runtime, "up").props.label)
  end)

  it("right at end of a row does nothing when no item is within the directional cone", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 400, height = 200 }, {
      Components.button({ label = "a", position = "absolute", left = 10,  top = 10, width = 80, height = 30 }),
      Components.button({ label = "b", position = "absolute", left = 100, top = 10, width = 80, height = 30 }),
      -- c is mostly below b, not to the right — should not be reached via right
      Components.button({ label = "c", position = "absolute", left = 105, top = 80, width = 80, height = 30 }),
    }))

    runtime:setFocus(root.children[2]) -- b
    assert.is_nil(Navigate.move(runtime, "right"))
  end)

  it("navigates a 2x2 grid in all four directions", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 300, height = 200 }, {
      Components.button({ label = "tl", position = "absolute", left = 10,  top = 10, width = 80, height = 30 }),
      Components.button({ label = "tr", position = "absolute", left = 150, top = 10, width = 80, height = 30 }),
      Components.button({ label = "bl", position = "absolute", left = 10,  top = 80, width = 80, height = 30 }),
      Components.button({ label = "br", position = "absolute", left = 150, top = 80, width = 80, height = 30 }),
    }))

    runtime:setFocus(root.children[1])
    assert.are.equal("tr", Navigate.move(runtime, "right").props.label)
    runtime:setFocus(root.children[2])
    assert.are.equal("br", Navigate.move(runtime, "down").props.label)
    runtime:setFocus(root.children[4])
    assert.are.equal("bl", Navigate.move(runtime, "left").props.label)
    runtime:setFocus(root.children[3])
    assert.are.equal("tl", Navigate.move(runtime, "up").props.label)
  end)

  it("down from end of navGroup row reaches first item of the next row", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 500, height = 300 }, {
      -- tabs row (navGroup = "tabs") — Items is far right so all gear items fall outside its 45° down-cone
      Components.button({ label = "Attack", navGroup = "tabs", position = "absolute", left = 10,  top = 10, width = 90, height = 30 }),
      Components.button({ label = "Magic",  navGroup = "tabs", position = "absolute", left = 110, top = 10, width = 90, height = 30 }),
      Components.button({ label = "Items",  navGroup = "tabs", position = "absolute", left = 280, top = 10, width = 90, height = 30 }),
      -- gear row offset left — all outside the 45° down-cone from Items (cx=325, dy=70, all |dx|>=95)
      Components.button({ label = "Sword",  navGroup = "gear", position = "absolute", left = 10,  top = 80, width = 80, height = 30 }),
      Components.button({ label = "Shield", navGroup = "gear", position = "absolute", left = 100, top = 80, width = 80, height = 30 }),
      Components.button({ label = "Helmet", navGroup = "gear", position = "absolute", left = 190, top = 80, width = 80, height = 30 }),
    }))

    runtime:setFocus(root.children[3]) -- Items (rightmost tab)
    assert.are.equal("Sword", Navigate.move(runtime, "down").props.label)
  end)
end)

describe("navigation scopes", function()
  it("keeps focus inside a trapped nav scope", function()
    local runtime = Runtime.new()
    local root = layout(runtime, Components.stack({ width = 360, height = 180 }, {
      Components.column({ navScope = true, navTrap = true, position = "absolute", left = 10, top = 10, gap = 8 }, {
        Components.button({ label = "top", width = 80, height = 30 }),
        Components.button({ label = "bottom", width = 80, height = 30 }),
      }),
      Components.button({ label = "outside", position = "absolute", left = 220, top = 52, width = 90, height = 30 }),
    }))

    runtime:setFocus(root.children[1].children[2])

    assert.are.equal("top", Navigate.move(runtime, "up").props.label)
    runtime:setFocus(root.children[1].children[2])
    assert.is_nil(Navigate.move(runtime, "right"))
    assert.are.equal("bottom", runtime.focusNode.props.label)
  end)

  it("lets a nav scope redirect exit movement", function()
    local runtime = Runtime.new()
    local exitDirection, exitOrigin, exitScope
    local root = nil
    root = layout(runtime, Components.stack({ width = 360, height = 180 }, {
      Components.column({
        navScope = true,
        navTrap = true,
        position = "absolute",
        left = 10,
        top = 10,
        gap = 8,
        onNavigateExit = function(direction, origin, scope)
          exitDirection = direction
          exitOrigin = origin
          exitScope = scope
          return root.children[2]
        end,
      }, {
        Components.button({ label = "submenu-a", width = 100, height = 30 }),
        Components.button({ label = "submenu-b", width = 100, height = 30 }),
      }),
      Components.button({ label = "opener", position = "absolute", left = 220, top = 52, width = 90, height = 30 }),
    }))

    runtime:setFocus(root.children[1].children[2])

    assert.are.equal("opener", Navigate.move(runtime, "right").props.label)
    assert.are.equal("right", exitDirection)
    assert.are.equal(root.children[1].children[2], exitOrigin)
    assert.are.equal(root.children[1], exitScope)
  end)

  it("allows scene layers to act as trapped nav scopes", function()
    local runtime = Runtime.new()
    runtime:setLove(fakeLove())

    runtime.scene:set("main", function()
      return Components.button({ label = "main", position = "absolute", left = 10, top = 120, width = 100, height = 30 })
    end, { transition = "none" })
    runtime.scene:push("overlay", function()
      return Components.button({ label = "overlay", position = "absolute", left = 10, top = 10, width = 100, height = 30 })
    end, { kind = "overlay", blocking = false, transition = "none", width = 300, height = 200, navScope = true, navTrap = true })

    runtime:render()
    runtime:setFocus(runtime.scene.layers[2].root)

    assert.is_nil(Navigate.move(runtime, "down"))
    assert.are.equal("overlay", runtime.focusNode.props.label)
  end)

  it("exposes ui.setFocus as a public focus helper", function()
    local node = Components.button({ label = "public" })

    ui.setFocus(nil)
    ui.setFocus(node)

    assert.are.equal(node, ui.runtime.focusNode)

    ui.setFocus(nil)
    assert.is_nil(ui.runtime.focusNode)
  end)
end)
