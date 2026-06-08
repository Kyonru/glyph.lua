package.path = "./?.lua;./?/init.lua;" .. package.path

local Layout = require("glyph.layout")
local ui = require("glyph")

local context = {
  theme = ui.theme,
  measureText = function(text)
    return #text * 10, 20
  end,
}

describe("layout", function()
  it("sizes a column with padding and gap", function()
    local tree = ui.column({ padding = 4, gap = 2 }, {
      ui.text("aa"),
      ui.text("bbbb"),
    })

    Layout.compute(tree, context)

    assert.are.equal(48, tree.layout.width)
    assert.are.equal(50, tree.layout.height)
    assert.are.equal(4, tree.children[1].layout.x)
    assert.are.equal(4, tree.children[1].layout.y)
    assert.are.equal(26, tree.children[2].layout.y)
  end)

  it("sizes a row and aligns children", function()
    local tree = ui.row({ padding = { x = 3, y = 5 }, gap = 7, align = "center", height = 40 }, {
      ui.text("a"),
      ui.text("bb"),
    })

    Layout.compute(tree, context)

    assert.are.equal(43, tree.layout.width)
    assert.are.equal(40, tree.layout.height)
    assert.are.equal(3, tree.children[1].layout.x)
    assert.are.equal(10, tree.children[1].layout.y)
    assert.are.equal(20, tree.children[2].layout.x)
  end)

  it("justifies row children along the main axis", function()
    local tree = ui.row({ width = 100, gap = 10, justify = "center" }, {
      ui.box({ width = 20, height = 10 }),
      ui.box({ width = 30, height = 10 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(20, tree.children[1].layout.x)
    assert.are.equal(50, tree.children[2].layout.x)
  end)

  it("justifies column children along the main axis", function()
    local tree = ui.column({ height = 100, gap = 10, justify = "center" }, {
      ui.box({ width = 20, height = 20 }),
      ui.box({ width = 30, height = 30 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(20, tree.children[1].layout.y)
    assert.are.equal(50, tree.children[2].layout.y)
  end)

  it("distributes grow space", function()
    local tree = ui.row({ width = 100, gap = 0 }, {
      ui.box({ width = 10, height = 10, grow = 1 }),
      ui.box({ width = 10, height = 10, grow = 3 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(30, tree.children[1].layout.width)
    assert.are.equal(70, tree.children[2].layout.width)
  end)

  it("supports flex as a grow alias", function()
    local tree = ui.row({ width = 120, gap = 10 }, {
      ui.box({ width = 20, height = 10 }),
      ui.box({ height = 10, flex = 1 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(20, tree.children[1].layout.width)
    assert.are.equal(90, tree.children[2].layout.width)
  end)

  it("supports percent widths against available parent space", function()
    local tree = ui.column({ width = 240, padding = 20 }, {
      ui.box({ width = "100%", height = 10 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(200, tree.children[1].layout.width)
  end)

  it("does not leak unresolved percent widths into arithmetic", function()
    local tree = ui.row({ width = 240 }, {
      ui.box({ width = "100%", height = 10 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(240, tree.children[1].layout.width)
    assert.are.equal(240, tree.children[1].layout.contentWidth)
  end)

  it("remeasures nested flex children with assigned width", function()
    local tree = ui.row({ width = 120, gap = 10 }, {
      ui.box({ width = 20, height = 10 }),
      ui.column({ flex = 1 }, {
        ui.text("alpha beta gamma", { wrap = true }),
      }),
    })

    Layout.compute(tree, context)

    assert.are.equal(90, tree.children[2].layout.width)
    assert.are.equal(60, tree.children[2].layout.height)
    assert.are.same({ "alpha", "beta", "gamma" }, tree.children[2].children[1].wrappedText.lines)
  end)

  it("remeasures percent children inside flex containers after assignment", function()
    local tree = ui.row({ width = 300 }, {
      ui.box({ width = 80, height = 10 }),
      ui.column({ flex = 1, padding = 10 }, {
        ui.box({ width = "100%", height = 10 }),
      }),
    })

    Layout.compute(tree, context)

    local flexColumn = tree.children[2]
    assert.are.equal(220, flexColumn.layout.width)
    assert.are.equal(200, flexColumn.children[1].layout.width)
  end)

  it("supports nested rows and columns", function()
    local tree = ui.column({ padding = 2, gap = 3 }, {
      ui.row({ gap = 2 }, {
        ui.text("a"),
        ui.text("b"),
      }),
      ui.text("ccc"),
    })

    Layout.compute(tree, context)

    assert.are.equal(34, tree.layout.width)
    assert.are.equal(47, tree.layout.height)
  end)

  it("lays out fixed grid children row-major", function()
    local tree = ui.grid({ columns = 3, cellWidth = 20, cellHeight = 12, gap = 4 }, {
      ui.box({}),
      ui.box({}),
      ui.box({}),
      ui.box({}),
    })

    Layout.compute(tree, context)

    assert.are.equal(68, tree.layout.width)
    assert.are.equal(28, tree.layout.height)
    assert.are.equal(0, tree.children[1].layout.x)
    assert.are.equal(0, tree.children[1].layout.y)
    assert.are.equal(24, tree.children[2].layout.x)
    assert.are.equal(0, tree.children[2].layout.y)
    assert.are.equal(0, tree.children[4].layout.x)
    assert.are.equal(16, tree.children[4].layout.y)
  end)

  it("keeps ui.grid callable while exposing helper methods", function()
    local tree = ui.grid({ columns = 2, cellWidth = 16, gap = 2 }, {
      ui.box({}),
      ui.box({}),
      ui.box({}),
    })

    Layout.compute(tree, context)

    assert.are.equal("table", type(ui.grid))
    assert.are.equal("function", type(ui.grid.pointToCell))
    assert.are.equal("grid", tree.type)
    assert.are.equal(34, tree.layout.width)
    assert.are.equal(34, tree.layout.height)
  end)

  it("defaults grid cell height to cell width", function()
    local tree = ui.grid({ columns = 2, cellWidth = 18, gap = 3 }, {
      ui.box({}),
      ui.box({}),
      ui.box({}),
    })

    Layout.compute(tree, context)

    assert.are.equal(18, tree.children[1].layout.height)
    assert.are.equal(39, tree.layout.width)
    assert.are.equal(39, tree.layout.height)
  end)

  it("uses responsive grid columns from available width", function()
    local tree = ui.grid({ width = 250, minCellWidth = 70, maxColumns = 3, gap = 10 }, {
      ui.box({}),
      ui.box({}),
      ui.box({}),
      ui.box({}),
    })

    Layout.compute(tree, context)

    assert.are.equal(250, tree.layout.width)
    assert.are.equal(76, tree.children[1].layout.width)
    assert.are.equal(0, tree.children[1].layout.x)
    assert.are.equal(86, tree.children[2].layout.x)
    assert.are.equal(172, tree.children[3].layout.x)
    assert.are.equal(86, tree.children[4].layout.y)
  end)

  it("remeasures grid children with assigned cell size", function()
    local tree = ui.grid({ columns = 1, cellWidth = 50, cellHeight = 30 }, {
      ui.text("alpha beta gamma", { wrap = true }),
    })

    Layout.compute(tree, context)

    assert.are.equal(50, tree.children[1].layout.width)
    assert.are.equal(30, tree.children[1].layout.height)
    assert.are.same({ "alpha", "beta", "gamma" }, tree.children[1].wrappedText.lines)
  end)

  it("combines grid padding and gap", function()
    local tree = ui.grid({ columns = 2, cellWidth = 20, cellHeight = 10, gap = 5, padding = { x = 3, y = 4 } }, {
      ui.box({}),
      ui.box({}),
      ui.box({}),
    })

    Layout.compute(tree, context)

    assert.are.equal(51, tree.layout.width)
    assert.are.equal(33, tree.layout.height)
    assert.are.equal(3, tree.children[1].layout.x)
    assert.are.equal(4, tree.children[1].layout.y)
    assert.are.equal(28, tree.children[2].layout.x)
    assert.are.equal(19, tree.children[3].layout.y)
  end)

  it("keeps absolute children out of grid flow", function()
    local tree = ui.grid({ columns = 2, cellWidth = 20, cellHeight = 10, gap = 5, padding = 2 }, {
      ui.box({ width = 8, height = 8 }),
      ui.box({ position = "absolute", width = 6, height = 6, right = 1, bottom = 1 }),
      ui.box({ width = 8, height = 8 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(49, tree.layout.width)
    assert.are.equal(14, tree.layout.height)
    assert.are.equal(27, tree.children[3].layout.x)
    assert.are.equal(2, tree.children[3].layout.y)
    assert.are.equal(40, tree.children[2].layout.x)
    assert.are.equal(5, tree.children[2].layout.y)
  end)

  it("justifies and aligns the grid inside explicit bounds", function()
    local tree = ui.grid({
      width = 100,
      height = 80,
      columns = 2,
      cellWidth = 20,
      cellHeight = 10,
      gap = 5,
      justify = "center",
      align = "end",
    }, {
      ui.box({}),
      ui.box({}),
      ui.box({}),
    })

    Layout.compute(tree, context)

    assert.are.equal(27.5, tree.children[1].layout.x)
    assert.are.equal(55, tree.children[1].layout.y)
    assert.are.equal(52.5, tree.children[2].layout.x)
    assert.are.equal(70, tree.children[3].layout.y)
  end)

  it("does not shrink grid flow size below its cells", function()
    local tree = ui.column({ height = 70, gap = 5 }, {
      ui.grid({ columns = 1, cellWidth = 40, cellHeight = 30 }, {
        ui.box({}),
        ui.box({}),
        ui.box({}),
      }),
      ui.box({ width = 10, height = 10 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(90, tree.children[1].layout.height)
    assert.are.equal(95, tree.children[2].layout.y)
  end)

  it("maps pointer coordinates into fixed grid cells", function()
    local bounds = { x = 10, y = 20, width = 81, height = 43 }
    local props = {
      columns = 3,
      cellWidth = 20,
      cellHeight = 10,
      gap = 5,
      padding = { x = 2, y = 3 },
      count = 5,
    }

    local cell = ui.grid.pointToCell(bounds, props, 40, 25)

    assert.are.same({ column = 2, row = 1, index = 2, localX = 3, localY = 2 }, cell)
    assert.is_nil(ui.grid.pointToCell(bounds, props, 34, 25))
    assert.is_nil(ui.grid.pointToCell(bounds, props, 63, 39))
  end)

  it("maps responsive grid cells using the same column math as layout", function()
    local bounds = { x = 5, y = 7, width = 250, height = 180 }
    local props = {
      minCellWidth = 70,
      maxColumns = 3,
      gap = 10,
      count = 4,
    }

    local third = ui.grid.pointToCell(bounds, props, 5 + 172 + 10, 12)
    local fourth = ui.grid.pointToCell(bounds, props, 12, 7 + 86 + 3)

    assert.are.same({ column = 3, row = 1, index = 3, localX = 10, localY = 5 }, third)
    assert.are.same({ column = 1, row = 2, index = 4, localX = 7, localY = 3 }, fourth)
  end)

  it("honors grid helper offsets from justify and align", function()
    local bounds = { x = 0, y = 0, width = 100, height = 80 }
    local props = {
      columns = 2,
      cellWidth = 20,
      cellHeight = 10,
      gap = 5,
      justify = "center",
      align = "end",
      count = 3,
    }

    assert.are.same({ column = 1, row = 1, index = 1, localX = 2.5, localY = 0 }, ui.grid.pointToCell(bounds, props, 30, 55))
    assert.is_nil(ui.grid.pointToCell(bounds, props, 10, 55))
  end)

  it("lays out stack children at the same origin", function()
    local tree = ui.stack({ width = 100, height = 80, padding = 5 }, {
      ui.box({ width = 30, height = 20 }),
      ui.box({ width = 40, height = 25 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(100, tree.layout.width)
    assert.are.equal(80, tree.layout.height)
    assert.are.equal(5, tree.children[1].layout.x)
    assert.are.equal(5, tree.children[1].layout.y)
    assert.are.equal(5, tree.children[2].layout.x)
    assert.are.equal(5, tree.children[2].layout.y)
  end)

  it("supports absolute inset positioning", function()
    local tree = ui.stack({ width = 100, height = 80, padding = 5 }, {
      ui.box({ position = "absolute", inset = 10 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(15, tree.children[1].layout.x)
    assert.are.equal(15, tree.children[1].layout.y)
    assert.are.equal(70, tree.children[1].layout.width)
    assert.are.equal(50, tree.children[1].layout.height)
  end)

  it("supports absolute right and bottom positioning", function()
    local tree = ui.stack({ width = 120, height = 90 }, {
      ui.box({ position = "absolute", width = 30, height = 20, right = 8, bottom = 6 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(82, tree.children[1].layout.x)
    assert.are.equal(64, tree.children[1].layout.y)
  end)

  it("supports absolute x and y positioning", function()
    local tree = ui.stack({ width = 120, height = 90 }, {
      ui.box({ position = "absolute", width = 30, height = 20, x = 14, y = 18 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(14, tree.children[1].layout.x)
    assert.are.equal(18, tree.children[1].layout.y)
  end)

  it("derives absolute size from opposing edges", function()
    local tree = ui.stack({ width = 140, height = 100 }, {
      ui.box({ position = "absolute", left = 10, right = 20, top = 5, bottom = 15 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(110, tree.children[1].layout.width)
    assert.are.equal(80, tree.children[1].layout.height)
  end)

  it("resolves absolute percent sizes against parent content bounds", function()
    local tree = ui.stack({ width = 200, height = 100, padding = 10 }, {
      ui.box({ position = "absolute", width = "50%", height = "25%" }),
    })

    Layout.compute(tree, context)

    assert.are.equal(90, tree.children[1].layout.width)
    assert.are.equal(20, tree.children[1].layout.height)
  end)

  it("keeps absolute children out of row flow", function()
    local tree = ui.row({ gap = 10 }, {
      ui.box({ width = 30, height = 10 }),
      ui.box({ position = "absolute", width = 200, height = 200 }),
      ui.box({ width = 40, height = 10 }),
    })

    Layout.compute(tree, context)

    assert.are.equal(80, tree.layout.width)
    assert.are.equal(40, tree.children[3].layout.x)
  end)

  it("creates root-scoped portals without affecting parent flow", function()
    local tree = ui.column({ gap = 4 }, {
      ui.box({ width = 20, height = 10 }),
      ui.portal({ left = 3, top = 4, width = 200, height = 100, zIndex = 50 }),
    })

    Layout.compute(tree, context)

    assert.are.equal("portal", tree.children[2].type)
    assert.are.equal("absolute", tree.children[2].props.position)
    assert.are.equal("root", tree.children[2].props.zScope)
    assert.are.equal("stack", tree.children[2].props.display)
    assert.are.equal(20, tree.layout.width)
    assert.are.equal(10, tree.layout.height)
    assert.are.equal(3, tree.children[2].layout.x)
    assert.are.equal(4, tree.children[2].layout.y)
  end)

  it("wraps text to a fixed width", function()
    local tree = ui.text("alpha beta gamma", {
      width = 100,
      wrap = true,
    })

    Layout.compute(tree, context)

    assert.are.equal(100, tree.layout.width)
    assert.are.equal(40, tree.layout.height)
    assert.are.same({ "alpha beta", "gamma" }, tree.wrappedText.lines)
  end)

  it("hard-wraps words that are wider than the fixed width", function()
    local tree = ui.text("abcdefghij", {
      width = 30,
      wrap = true,
    })

    Layout.compute(tree, context)

    assert.are.equal(30, tree.layout.width)
    assert.are.equal(80, tree.layout.height)
    assert.are.same({ "abc", "def", "ghi", "j" }, tree.wrappedText.lines)
  end)

  it("uses typography font size and text scale when no measurement hook is available", function()
    local theme = {
      fontSize = 10,
      lineHeight = 14,
      textScale = 2,
      typography = {
        text = { fontSize = 10, lineHeight = 14 },
        h1 = { fontSize = 20, lineHeight = 26 },
      },
    }
    local tree = ui.text("aa", { textStyle = "h1" })

    Layout.compute(tree, { theme = theme })

    assert.is_true(tree.layout.width > 40)
    assert.are.equal(52, tree.layout.height)
  end)

  it("uses component typography when measuring button labels", function()
    local theme = {
      fontSize = 10,
      lineHeight = 14,
      textScale = 1,
      typography = {
        text = { fontSize = 10, lineHeight = 14 },
        button = { fontSize = 18, lineHeight = 24 },
      },
    }
    local tree = ui.button({ label = "Go" })

    Layout.compute(tree, { theme = theme })

    assert.is_true(tree.layout.width > 38)
    assert.are.equal(34, tree.layout.height)
  end)

  it("falls back to literal source measurement when sysl backend is missing", function()
    local theme = {
      fontSize = 10,
      lineHeight = 14,
      textScale = 1,
      typography = {
        text = { fontSize = 10, lineHeight = 14 },
      },
    }
    local tree = ui.richText("[color=#ff0000]alpha beta[/color]", {
      wrap = true,
      width = 42,
    })

    Layout.compute(tree, { theme = theme })

    assert.are.equal(42, tree.layout.width)
    assert.are.equal(18, tree.layout.height)
    assert.is_true(tree.richText.fallback)
  end)

  it("measures images from source natural size", function()
    local source = {
      getWidth = function() return 96 end,
      getHeight = function() return 48 end,
    }
    local tree = ui.image({ source = source })

    Layout.compute(tree, context)

    assert.are.equal(96, tree.layout.width)
    assert.are.equal(48, tree.layout.height)
  end)

  it("measures images from quad viewport size", function()
    local source = {
      getWidth = function() return 96 end,
      getHeight = function() return 48 end,
    }
    local quad = {
      getViewport = function() return 8, 12, 24, 16 end,
    }
    local tree = ui.image({ source = source, quad = quad })

    Layout.compute(tree, context)

    assert.are.equal(24, tree.layout.width)
    assert.are.equal(16, tree.layout.height)
  end)

  it("lets explicit image sizes override natural size", function()
    local source = {
      getWidth = function() return 96 end,
      getHeight = function() return 48 end,
    }
    local tree = ui.column({ width = 300 }, {
      ui.image({
        source = source,
        width = "50%",
        height = 32,
      }),
    })

    Layout.compute(tree, context)

    assert.are.equal(150, tree.children[1].layout.width)
    assert.are.equal(32, tree.children[1].layout.height)
  end)

  it("measures missing image sources as explicit size or zero", function()
    local explicit = ui.image({ width = 80, height = 40 })
    local empty = ui.image()

    Layout.compute(explicit, context)
    Layout.compute(empty, context)

    assert.are.equal(80, explicit.layout.width)
    assert.are.equal(40, explicit.layout.height)
    assert.are.equal(0, empty.layout.width)
    assert.are.equal(0, empty.layout.height)
  end)
end)
