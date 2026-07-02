package.path = "./?.lua;./?/init.lua;" .. package.path

local Typography = require("glyph.typography")

describe("typography measurement cache", function()
  before_each(function()
    Typography.clearCache()
  end)

  it("caches font:getWidth per (font, text)", function()
    local widthCalls = 0
    local font = {
      getWidth = function(_, text)
        widthCalls = widthCalls + 1
        return #text * 8
      end,
      getHeight = function()
        return 16
      end,
    }
    local theme = { fontSize = 13, lineHeight = 18, typography = {} }
    local props = { font = font }

    local w1, h1 = Typography.measurePlain("hello", props, theme)
    local w2, h2 = Typography.measurePlain("hello", props, theme)

    assert.are.equal(40, w1) -- 5 chars * 8
    assert.are.equal(w1, w2)
    assert.are.equal(h1, h2)
    assert.are.equal(1, widthCalls) -- second measurement served from cache
  end)

  it("measures distinct strings separately but reuses each", function()
    local calls = 0
    local font = {
      getWidth = function(_, text)
        calls = calls + 1
        return #text
      end,
      getHeight = function()
        return 12
      end,
    }
    local theme = { fontSize = 13, typography = {} }
    local props = { font = font }

    Typography.measurePlain("a", props, theme)
    Typography.measurePlain("bb", props, theme)
    Typography.measurePlain("a", props, theme)

    assert.are.equal(2, calls) -- "a" cached, only "a" and "bb" measured
  end)

  it("clearCache drops cached measurements", function()
    local calls = 0
    local font = {
      getWidth = function()
        calls = calls + 1
        return 10
      end,
      getHeight = function()
        return 12
      end,
    }
    local theme = { fontSize = 13, typography = {} }
    local props = { font = font }

    Typography.measurePlain("x", props, theme)
    Typography.clearCache()
    Typography.measurePlain("x", props, theme)

    assert.are.equal(2, calls)
  end)
end)

describe("typography font resolution", function()
  it("resolves caption typography through the named theme font", function()
    local latinFont = {
      getWidth = function(_, text)
        return #text
      end,
      getHeight = function()
        return 12
      end,
    }
    local japaneseFont = {
      getWidth = function(_, text)
        return #text * 2
      end,
      getHeight = function()
        return 14
      end,
    }
    local theme = {
      fontSize = 13,
      lineHeight = 18,
      typography = {
        text = { font = "body" },
        caption = { font = "japanese" },
      },
      fonts = {
        body = latinFont,
        japanese = japaneseFont,
      },
    }

    local resolved = Typography.resolveDrawable(theme, { textStyle = "caption" })

    assert.are.equal(japaneseFont, resolved.font)
  end)

  it("falls back to a registered font when the selected font lacks glyphs", function()
    local latinFont = {
      getWidth = function(_, text)
        return #text
      end,
      getHeight = function()
        return 12
      end,
      hasGlyphs = function(_, text)
        return not tostring(text):find("言", 1, true)
      end,
    }
    local japaneseFont = {
      getWidth = function(_, text)
        return #text * 2
      end,
      getHeight = function()
        return 14
      end,
      hasGlyphs = function()
        return true
      end,
    }
    local theme = {
      fontSize = 13,
      lineHeight = 18,
      typography = {
        text = { font = "body" },
        caption = { font = "body" },
      },
      fonts = {
        body = latinFont,
        japanese = japaneseFont,
      },
      fontFallbacks = { "japanese" },
    }

    local resolved = Typography.resolveDrawable(theme, { textStyle = "caption" }, nil, nil, nil, "言語: 日本語")
    local width = Typography.measurePlain("言語: 日本語", { textStyle = "caption" }, theme)

    assert.are.equal(japaneseFont, resolved.font)
    assert.are.equal(#("言語: 日本語") * 2, width)
  end)
end)
