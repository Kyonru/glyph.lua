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
  before_each(function()
    Typography.clearCache()
  end)

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

  it("instantiates source descriptors at resolved sizes and reuses cached fonts", function()
    local source = {}
    local calls = {}
    local fakeLove = {
      graphics = {
        newFont = function(received, size)
          calls[#calls + 1] = { source = received, size = size }
          return {
            source = received,
            size = size,
            getWidth = function(_, text)
              return #text * size
            end,
            getHeight = function()
              return size
            end,
            hasGlyphs = function()
              return true
            end,
            setFilter = function() end,
          }
        end,
      },
    }
    local theme = {
      fontSize = 12,
      textScale = 1,
      typography = { text = { font = "body", fontSize = 12 } },
      fonts = { body = { source = source, filter = "linear" } },
    }

    local first = Typography.resolveDrawable(theme, {}, nil, nil, fakeLove, "alpha")
    local repeated = Typography.resolveDrawable(theme, {}, nil, nil, fakeLove, "beta")
    local large = Typography.resolveDrawable(theme, { fontSize = 24 }, nil, nil, fakeLove, "large")
    theme.textScale = 2
    local scaled = Typography.resolveDrawable(theme, {}, nil, nil, fakeLove, "scaled")

    assert.are.equal(2, #calls)
    assert.are.equal(source, calls[1].source)
    assert.are.equal(12, calls[1].size)
    assert.are.equal(24, calls[2].size)
    assert.are.equal(first.font, repeated.font)
    assert.are.equal(large.font, scaled.font)
  end)

  it("keeps prebuilt font objects fixed when fontSize changes", function()
    local fixed = {
      getWidth = function(_, text)
        return #text * 8
      end,
      getHeight = function()
        return 16
      end,
    }
    local created = 0
    local fakeLove = {
      graphics = {
        newFont = function()
          created = created + 1
        end,
      },
    }
    local theme = {
      fontSize = 13,
      typography = { text = { font = "body" } },
      fonts = { body = fixed },
    }

    local resolved = Typography.resolveDrawable(theme, { fontSize = 40 }, nil, nil, fakeLove, "fixed")

    assert.are.equal(fixed, resolved.font)
    assert.are.equal(0, created)
  end)

  it("loads source-descriptor fallbacks at the selected effective size", function()
    local fallbackSource = {}
    local createdSize = nil
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
    local fakeLove = {
      graphics = {
        newFont = function(source, size)
          createdSize = size
          return {
            source = source,
            getWidth = function(_, text)
              return #text * 2
            end,
            getHeight = function()
              return size
            end,
            hasGlyphs = function()
              return true
            end,
            setFilter = function() end,
          }
        end,
      },
    }
    local theme = {
      fontSize = 13,
      typography = { text = { font = "body" } },
      fonts = {
        body = latinFont,
        japanese = { source = fallbackSource },
      },
      fontFallbacks = { "japanese" },
    }

    local resolved = Typography.resolveDrawable(theme, { fontSize = 19 }, nil, nil, fakeLove, "言語")

    assert.are.equal(fallbackSource, resolved.font.source)
    assert.are.equal(19, createdSize)
  end)
end)
