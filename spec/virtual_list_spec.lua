package.path = "./?.lua;./?/init.lua;" .. package.path

local Components = require("glyph.components")
local VirtualList = require("glyph.virtual_list")

describe("virtual list", function()
  it("mounts only the visible range plus overscan", function()
    local ranges = {}
    local runtime = {
      scrollOffsets = {
        ["root.k:list"] = 84,
      },
    }

    local list = VirtualList.build(runtime, Components, {
      key = "list",
      width = 200,
      height = 60,
      itemCount = 20,
      itemHeight = 20,
      overscan = 1,
      itemKey = function(index)
        return "row-" .. tostring(index)
      end,
      renderItem = function(index)
        return Components.text("row " .. tostring(index))
      end,
      onRangeChange = function(first, last, info)
        ranges[#ranges + 1] = { first = first, last = last, info = info }
      end,
    })

    assert.are.equal("scrollView", list.type)
    assert.are.equal(200, list.props.width)
    assert.are.equal(60, list.props.height)
    assert.are.equal(7, #list.children)
    assert.are.equal(60, list.children[1].props.height)
    assert.are.equal("row 4", list.children[2].value)
    assert.are.equal("row-4", list.children[2].props.key)
    assert.are.equal(20, list.children[2].props.height)
    assert.are.equal("row 8", list.children[6].value)
    assert.are.equal(240, list.children[7].props.height)
    assert.are.equal(4, ranges[1].first)
    assert.are.equal(8, ranges[1].last)
    assert.are.equal(5, ranges[1].info.mounted)
    assert.are.equal(84, ranges[1].info.scrollOffset)
  end)

  it("returns an empty scroll view when required props are missing", function()
    local list = VirtualList.build({ scrollOffsets = {} }, Components, {
      width = 100,
      height = 80,
      itemCount = 10,
    })

    assert.are.equal("scrollView", list.type)
    assert.are.equal(0, #list.children)
  end)

  it("uses visibleCount when height is not numeric", function()
    local list = VirtualList.build({ scrollOffsets = {} }, Components, {
      width = 100,
      height = "100%",
      visibleCount = 3,
      itemCount = 10,
      itemHeight = 12,
      overscan = 0,
      renderItem = function(index)
        return Components.text("row " .. tostring(index))
      end,
    })

    assert.are.equal("100%", list.props.height)
    assert.is_nil(list.props.visibleCount)
    assert.are.equal(4, #list.children)
    assert.are.equal("row 1", list.children[1].value)
    assert.are.equal("row 3", list.children[3].value)
    assert.are.equal(84, list.children[4].props.height)
  end)
end)
