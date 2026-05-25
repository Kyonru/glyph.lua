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
end)
