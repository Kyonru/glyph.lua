package.path = "./?.lua;./?/init.lua;" .. package.path

local Path = require("glyph.path")
local Runtime = require("glyph.runtime")
local ui = require("glyph")

describe("path", function()
  it("parses absolute, relative, repeated, and close SVG commands", function()
    local commands = Path.parse("M0 0 h10 v10 l-10 0 z")

    assert.are.same({
      { "M", 0, 0 },
      { "L", 10, 0 },
      { "L", 10, 10 },
      { "L", 0, 10 },
      { "Z" },
    }, commands)
  end)

  it("parses repeated moveto and lineto coordinates", function()
    local commands = Path.parse("M 1 2 3 4 5 6 L 7 8 9 10")

    assert.are.same({
      { "M", 1, 2 },
      { "L", 3, 4 },
      { "L", 5, 6 },
      { "L", 7, 8 },
      { "L", 9, 10 },
    }, commands)
  end)

  it("rejects invalid syntax and unsupported SVG arcs clearly", function()
    assert.has_error(function()
      Path.parse("M0 0 L")
    end)

    assert.has_error(function()
      Path.parse("M0 0 A 10 10 0 0 1 20 20")
    end, "unsupported SVG path command A; arcs are not supported in Glyph path v1")
  end)

  it("computes bounds, flattening, length, and reveal prefixes", function()
    local commands = {
      { "M", 0, 0 },
      { "L", 100, 0 },
      { "Q", 150, 50, 100, 100 },
    }

    local bounds = Path.bounds(commands)
    local flat = Path.flatten(commands, { samples = 4 })
    local reveal = Path.reveal({ 0, 0, 100, 0, 100, 100 }, 0.5)

    assert.are.same({ x = 0, y = 0, width = 150, height = 100 }, bounds)
    assert.are.equal(12, #flat)
    assert.are.equal(200, Path.length({ 0, 0, 100, 0, 100, 100 }))
    assert.are.same({ 0, 0, 100, 0 }, reveal)
  end)

  it("morphs compatible command sequences", function()
    local result = Path.morphCompatible({
      { "M", 0, 0 },
      { "L", 10, 0 },
    }, {
      { "M", 0, 10 },
      { "L", 20, 10 },
    }, 0.5)

    assert.are.same({
      { "M", 0, 5 },
      { "L", 15, 5 },
    }, result)
  end)

  it("morphs incompatible paths through resampled polylines", function()
    local result = Path.morphResample("M0 0 L10 0", "M0 10 L10 10 L20 10", 0.5, { samples = 3 })

    assert.are.equal(6, #result)
    assert.are.equal(0, result[1])
    assert.are.equal(5, result[2])
    assert.are.equal(15, result[5])
    assert.are.equal(5, result[6])
  end)

  it("exposes ui.path as a callable helper namespace", function()
    local node = ui.path({
      d = "M0 0 L10 0",
      width = 10,
      height = 10,
    })

    assert.are.equal("path", node.type)
    assert.are.equal("function", type(ui.path.parse))
    assert.are.same({ "M", 0, 0 }, ui.path.parse("M0 0")[1])
  end)

  it("draws path components with progress and restores graphics state", function()
    local runtime = Runtime.new()
    local calls = {}
    local lineWidth = 7
    local currentColor = { 0.2, 0.3, 0.4, 0.5 }

    runtime:setLove({
      graphics = {
        getLineWidth = function()
          return lineWidth
        end,
        setLineWidth = function(width)
          lineWidth = width
          calls[#calls + 1] = { "lineWidth", width }
        end,
        getColor = function()
          return currentColor[1], currentColor[2], currentColor[3], currentColor[4]
        end,
        setColor = function(r, g, b, a)
          currentColor = { r, g, b, a }
          calls[#calls + 1] = { "color", r, g, b, a }
        end,
        line = function(...)
          calls[#calls + 1] = { "line", ... }
        end,
      },
    })

    runtime:build(function()
      return ui.path({
        d = "M0 0 L100 0 L100 100",
        width = 100,
        height = 100,
        stroke = { 1, 0, 0, 0.8 },
        strokeWidth = 4,
        progress = 0.5,
        opacity = 0.5,
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "lineWidth", 1 }, calls[1])
    assert.are.same({ "lineWidth", 4 }, calls[2])
    assert.are.same({ "color", 1, 0, 0, 0.4 }, calls[3])
    assert.are.same({ "line", 0, 0, 100, 0 }, calls[4])
    assert.are.same({ "lineWidth", 1 }, calls[5])
    assert.are.same({ "color", 0.2, 0.3, 0.4, 0.5 }, calls[6])
    assert.are.same({ "lineWidth", 7 }, calls[7])
  end)

  it("defaults fill-only path components to fill mode", function()
    local runtime = Runtime.new()
    local polygons = 0
    local lines = 0

    runtime:setLove({
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getColor = function()
          return 1, 1, 1, 1
        end,
        setColor = function() end,
        polygon = function()
          polygons = polygons + 1
        end,
        line = function()
          lines = lines + 1
        end,
      },
    })

    runtime:build(function()
      return ui.path({
        d = "M0 0 L10 0 L10 10 Z",
        width = 10,
        height = 10,
        fill = { 0, 1, 0, 1 },
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(1, polygons)
    assert.are.equal(0, lines)
  end)

  it("triangulates concave filled path components when available", function()
    local runtime = Runtime.new()
    local triangulated
    local polygons = {}

    runtime:setLove({
      math = {
        triangulate = function(points)
          triangulated = points
          return {
            { 0, 0, 20, 0, 20, 20 },
            { 0, 0, 20, 20, 10, 10 },
            { 0, 0, 10, 10, 0, 20 },
          }
        end,
      },
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getColor = function()
          return 1, 1, 1, 1
        end,
        setColor = function() end,
        polygon = function(mode, ...)
          polygons[#polygons + 1] = { mode, ... }
        end,
      },
    })

    runtime:build(function()
      return ui.path({
        d = "M0 0 L20 0 L20 20 L10 10 L0 20 Z",
        width = 20,
        height = 20,
        fill = { 0, 1, 0, 1 },
        fit = "stretch",
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ 0, 0, 20, 0, 20, 20, 10, 10, 0, 20 }, triangulated)
    assert.are.equal(3, #polygons)
    assert.are.same({ "fill", 0, 0, 20, 0, 20, 20 }, polygons[1])
    assert.are.same({ "fill", 0, 0, 20, 20, 10, 10 }, polygons[2])
    assert.are.same({ "fill", 0, 0, 10, 10, 0, 20 }, polygons[3])
  end)

  it("draws ctx paths with fill, morphing, and local state restoration", function()
    local runtime = Runtime.new()
    local calls = {}
    local lineWidth = 5
    local currentColor = { 0.1, 0.2, 0.3, 0.4 }

    runtime:setLove({
      graphics = {
        getLineWidth = function()
          return lineWidth
        end,
        setLineWidth = function(width)
          lineWidth = width
          calls[#calls + 1] = { "lineWidth", width }
        end,
        getColor = function()
          return currentColor[1], currentColor[2], currentColor[3], currentColor[4]
        end,
        setColor = function(r, g, b, a)
          currentColor = { r, g, b, a }
          calls[#calls + 1] = { "color", r, g, b, a }
        end,
        polygon = function(mode, ...)
          calls[#calls + 1] = { "polygon", mode, ... }
        end,
        line = function(...)
          calls[#calls + 1] = { "line", ... }
        end,
      },
    })

    runtime:build(function()
      return ui.box({
        width = 20,
        height = 20,
        style = { opacity = 0.5 },
        draw = function(_, _, _, _, _, _, _, ctx)
          ctx:path("both", "M0 0 L10 0 L10 10 Z", {
            x = 0,
            y = 0,
            width = 20,
            height = 20,
          }, {
            morphTo = "M0 0 L20 0 L20 20 Z",
            morph = 0.5,
            fill = { 0, 1, 0, 0.8 },
            stroke = { 0, 0, 1, 1 },
            strokeWidth = 3,
            fit = "stretch",
          })
        end,
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "lineWidth", 1 }, calls[1])
    assert.are.same({ "color", 0, 1, 0, 0.4 }, calls[2])
    assert.are.equal("polygon", calls[3][1])
    assert.are.same({ "lineWidth", 3 }, calls[4])
    assert.are.same({ "color", 0, 0, 1, 0.5 }, calls[5])
    assert.are.equal("line", calls[6][1])
    assert.are.same({ "lineWidth", 1 }, calls[7])
    assert.are.same({ "color", 0.1, 0.2, 0.3, 0.4 }, calls[8])
    assert.are.same({ "lineWidth", 5 }, calls[9])
  end)
end)
