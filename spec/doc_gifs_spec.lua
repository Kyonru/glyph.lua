package.path = "./?.lua;./?/init.lua;./scripts/?.lua;./scripts/?/init.lua;" .. package.path

local Markdown = require("doc_gifs.markdown")

local target = {
  id = "animations",
  title = "Animations",
  docs = { "docs/animations.md" },
  alt = "Animated GIF showing Glyph enter, exit, meter, and movement animations.",
}

describe("doc GIF Markdown updater", function()
  it("inserts missing feature blocks after the page heading", function()
    local content = table.concat({
      "---",
      "icon: lucide/sparkles",
      "---",
      "",
      "# Animations",
      "",
      "Glyph includes animation.",
      "",
    }, "\n")

    local updated = Markdown.updateFeatureDoc(content, target, "docs/animations.md")

    assert.is_true(updated:find("# Animations\n\n<!-- glyph:feature-gif animations -->", 1, true) ~= nil)
    assert.is_true(updated:find("assets/feature-gifs/animations.gif", 1, true) ~= nil)
    assert.is_true(updated:find("Glyph includes animation%.") ~= nil)
  end)

  it("replaces existing feature blocks idempotently", function()
    local content = table.concat({
      "# Animations",
      "",
      "<!-- glyph:feature-gif animations -->",
      "old image",
      "<!-- /glyph:feature-gif animations -->",
      "",
      "Body",
      "",
    }, "\n")

    local once = Markdown.updateFeatureDoc(content, target, "docs/animations.md")
    local twice = Markdown.updateFeatureDoc(once, target, "docs/animations.md")

    assert.are.equal(once, twice)
    assert.is_true(once:find("old image", 1, true) == nil)
    assert.is_true(once:find("Body", 1, true) ~= nil)
  end)

  it("preserves surrounding Markdown when updating the gallery", function()
    local content = table.concat({
      "# Examples",
      "",
      "Run examples with Love2D.",
      "",
      "## Example Standards",
      "",
      "- Keep examples runnable.",
      "",
    }, "\n")

    local updated = Markdown.updateGalleryDoc(content, { target }, "docs/examples.md")

    assert.is_true(updated:find("Run examples with Love2D%.") ~= nil)
    assert.is_true(updated:find("## Feature GIF Gallery", 1, true) ~= nil)
    assert.is_true(updated:find("## Example Standards", 1, true) ~= nil)
    assert.is_true(updated:find("%[Animations%]%(animations%.md%)") ~= nil)
  end)

  it("rejects duplicate manifest ids", function()
    assert.has_error(function()
      Markdown.validateTargets({
        target,
        {
          id = "animations",
          title = "Duplicate",
          docs = { "docs/animations.md" },
          alt = "Duplicate preview.",
        },
      })
    end, "duplicate doc GIF target id: animations")
  end)
end)
