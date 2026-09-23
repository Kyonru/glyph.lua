package.path = "./?.lua;./?/init.lua;" .. package.path

local Components = require("glyph.components")

describe("component props ownership", function()
  local constructors = {
    { "text", function(props) return Components.text("value", props) end },
    { "textKey", function(props) return Components.textKey("copy.key", props) end },
    { "richText", function(props) return Components.richText("value", props) end },
    { "richTextKey", function(props) return Components.richTextKey("copy.rich", props) end },
    { "h1", function(props) return Components.h1("value", props) end },
    { "h2", function(props) return Components.h2("value", props) end },
    { "p", function(props) return Components.p("value", props) end },
    { "caption", function(props) return Components.caption("value", props) end },
    { "image", function(props) return Components.image(props) end },
    { "path", function(props) return Components.path(props) end },
    { "box", function(props) return Components.box(props, {}) end },
    { "stack", function(props) return Components.stack(props, {}) end },
    { "row", function(props) return Components.row(props, {}) end },
    { "column", function(props) return Components.column(props, {}) end },
    { "grid", function(props) return Components.grid(props, {}) end },
    { "portal", function(props) return Components.portal(props, {}) end },
    { "button", function(props) return Components.button(props) end },
    { "input", function(props) return Components.input(props) end },
    { "meter", function(props) return Components.meter(props, {}) end },
    { "scrollView", function(props) return Components.scrollView(props, {}) end },
    { "tabs", function(props) return Components.tabs(props, {}) end },
    { "panel", function(props) return Components.panel(props, {}) end },
  }

  for _, case in ipairs(constructors) do
    it(case[1] .. " keeps caller-owned props unchanged", function()
      local props = { marker = "caller" }
      local node = case[2](props)

      assert.are.same({ marker = "caller" }, props)
      assert.are_not.equal(props, node.props)
      assert.are.equal("caller", node.props.marker)
    end)
  end

  it("applies text shorthand defaults only to the node copy", function()
    local props = { rich = true }
    local node = Components.text("rich", props)

    assert.are.same({ rich = true }, props)
    assert.are.equal("sysl", node.props.format)
  end)

  it("allows one props table to be reused without changing earlier nodes", function()
    local style = { opacity = 0.5 }
    local props = { gap = 4, style = style }

    local row = Components.row(props, {})
    local column = Components.column(props, {})
    props.gap = 12

    assert.is_nil(props.display)
    assert.are.equal("row", row.props.display)
    assert.are.equal("column", column.props.display)
    assert.are.equal(4, row.props.gap)
    assert.are.equal(4, column.props.gap)
    assert.are.equal(style, row.props.style)
    assert.are.equal(style, column.props.style)
  end)
end)
