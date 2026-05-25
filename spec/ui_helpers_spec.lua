package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("glyph.runtime")
local Components = require("glyph.components")
local ui = require("glyph")

describe("ui helpers", function()
  it("mixes numbers and colors", function()
    assert.are.equal(15, ui.mix(10, 20, 0.5))
    assert.are.same({ 0.5, 0.25, 0.75, 1 }, ui.mixColor({ 0, 0, 1, 1 }, { 1, 0.5, 0.5, 1 }, 0.5))
  end)

  it("builds skewed polygon boxes", function()
    assert.are.same({
      2,
      2,
      88,
      2,
      98,
      48,
      12,
      48,
    }, ui.polygonBox(0, 0, 100, 50, { skew = 10, inset = 2 }))
  end)

  it("creates custom button nodes", function()
    local custom = ui.customButton({ width = 100, height = 20 })

    assert.are.equal("button", custom.type)
  end)

  it("creates generic meter nodes", function()
    local meter = ui.meter({
      value = 7,
      max = 10,
      width = 120,
      shape = { kind = "skew", skew = 10 },
    })

    assert.are.equal("meter", meter.type)
    assert.are.equal(7, meter.props.value)
    assert.are.equal("linear", meter.props.kind)
    assert.are.equal("right", meter.props.direction)
    assert.are.equal("skew", meter.props.shape.kind)
  end)

  it("creates rich text and typography convenience nodes", function()
    local rich = ui.richText("Ready [color=#ffff00]go[/color]")
    local title = ui.h1("Mission")
    local paragraph = ui.p("Long copy")

    assert.are.equal("text", rich.type)
    assert.are.equal("sysl", rich.props.format)
    assert.are.equal("h1", title.props.textStyle)
    assert.are.equal("paragraph", paragraph.props.textStyle)
  end)

  it("creates image nodes", function()
    local source = {
      getWidth = function() return 64 end,
      getHeight = function() return 32 end,
    }
    local quad = {
      getViewport = function() return 0, 0, 16, 16 end,
    }
    local image = ui.image({
      source = source,
      quad = quad,
      width = 120,
      height = 80,
      fit = "cover",
      align = "end",
      valign = "start",
      tint = { 1, 0.5, 0.25, 1 },
    })

    assert.are.equal("image", image.type)
    assert.are.equal(source, image.props.source)
    assert.are.equal(quad, image.props.quad)
    assert.are.equal("cover", image.props.fit)
    assert.are.equal("end", image.props.align)
    assert.are.equal("start", image.props.valign)
  end)

  it("draws images with contain fit and restores color", function()
    local runtime = Runtime.new()
    local calls = {}
    local currentColor = { 0.2, 0.3, 0.4, 0.5 }
    local source = {
      getWidth = function() return 100 end,
      getHeight = function() return 50 end,
    }

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getColor = function()
          return currentColor[1], currentColor[2], currentColor[3], currentColor[4]
        end,
        setColor = function(r, g, b, a)
          currentColor = { r, g, b, a }
          calls[#calls + 1] = { "color", r, g, b, a }
        end,
        draw = function(image, x, y, rotation, sx, sy)
          calls[#calls + 1] = { "draw", image, x, y, rotation, sx, sy }
        end,
      },
    })

    runtime:build(function()
      return ui.image({
        source = source,
        width = 200,
        height = 200,
        tint = { 1, 0.5, 0.25, 0.8 },
        opacity = 0.5,
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "color", 1, 0.5, 0.25, 0.4 }, calls[1])
    assert.are.same({ "draw", source, 0, 50, 0, 2, 2 }, calls[2])
    assert.are.same({ "color", 0.2, 0.3, 0.4, 0.5 }, calls[3])
  end)

  it("draws image quads with cover fit and alignment offsets", function()
    local runtime = Runtime.new()
    local drawCall
    local source = {
      getWidth = function() return 100 end,
      getHeight = function() return 100 end,
    }
    local quad = {
      getViewport = function() return 10, 20, 50, 25 end,
    }

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getColor = function() return 1, 1, 1, 1 end,
        setColor = function() end,
        draw = function(image, imageQuad, x, y, rotation, sx, sy)
          drawCall = { image, imageQuad, x, y, rotation, sx, sy }
        end,
      },
    })

    runtime:build(function()
      return ui.image({
        source = source,
        quad = quad,
        width = 100,
        height = 100,
        fit = "cover",
        align = "end",
        valign = "center",
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ source, quad, -100, 0, 0, 4, 4 }, drawCall)
  end)

  it("draws images with stretch and none fit", function()
    local runtime = Runtime.new()
    local draws = {}
    local source = {
      getWidth = function() return 40 end,
      getHeight = function() return 20 end,
    }

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getColor = function() return 1, 1, 1, 1 end,
        setColor = function() end,
        draw = function(image, x, y, rotation, sx, sy)
          draws[#draws + 1] = { image, x, y, rotation, sx, sy }
        end,
      },
    })

    runtime:build(function()
      return ui.column({ gap = 0 }, {
        ui.image({ source = source, width = 80, height = 80, fit = "stretch" }),
        ui.image({ source = source, width = 80, height = 80, fit = "none", align = "end", valign = "end" }),
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ source, 0, 0, 0, 2, 4 }, draws[1])
    assert.are.same({ source, 40, 140, 0, 1, 1 }, draws[2])
  end)

  it("clips image drawing without changing rectangular hit bounds", function()
    local runtime = Runtime.new()
    local calls = {}
    local source = {
      getWidth = function() return 40 end,
      getHeight = function() return 40 end,
    }

    runtime:setLove({
      graphics = {
        getLineWidth = function() return 1 end,
        setLineWidth = function() end,
        getColor = function() return 1, 1, 1, 1 end,
        setColor = function() end,
        getScissor = function() return nil end,
        setScissor = function(x, y, width, height)
          calls[#calls + 1] = { "scissor", x, y, width, height }
        end,
        draw = function()
          calls[#calls + 1] = { "draw" }
        end,
      },
    })

    runtime:build(function()
      return ui.image({
        source = source,
        width = 40,
        height = 40,
        clip = true,
        interactive = true,
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "scissor", 0, 0, 40, 40 }, calls[1])
    assert.are.same({ "draw" }, calls[2])
    assert.are.equal(runtime.root, runtime:hitTest(38, 38))
  end)

  it("does not draw linear meter fill when value is zero", function()
    local runtime = Runtime.new()
    local fills = {}

    runtime:setLove({
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getShader = function()
          return nil
        end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function(mode, x, y, width, height)
          if mode == "fill" then
            fills[#fills + 1] = { x = x, y = y, width = width, height = height }
          end
        end,
        print = function() end,
      },
    })

    local function App()
      return Components.meter({
        value = 0,
        max = 10,
        width = 120,
        height = 12,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(1, #fills)
    assert.are.equal(120, fills[1].width)
  end)

  it("does not draw radial meter fill arc when value is zero", function()
    local runtime = Runtime.new()
    local arcs = {}

    runtime:setLove({
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getShader = function()
          return nil
        end,
        setShader = function() end,
        setColor = function() end,
        arc = function(mode, x, y, radius, startAngle, endAngle)
          arcs[#arcs + 1] = {
            mode = mode,
            x = x,
            y = y,
            radius = radius,
            startAngle = startAngle,
            endAngle = endAngle,
          }
        end,
        rectangle = function() end,
        print = function() end,
      },
    })

    local function App()
      return Components.meter({
        kind = "arc",
        value = 0,
        max = 10,
        width = 80,
        height = 80,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(1, #arcs)
    assert.is_true(arcs[1].endAngle > arcs[1].startAngle)
  end)

  it("converts pointer input through the viewport backend", function()
    local previousBackend = ui.runtime.viewportBackend
    local clicks = 0

    ui.runtime.viewportBackend = {
      isEnabled = function() return true end,
      screenToViewport = function(x, y)
        if x < 0 then
          return false, false, false
        end
        return true, x / 2, y / 2
      end,
      viewportToScreen = function(x, y)
        return x * 2, y * 2
      end,
    }

    local function App()
      return Components.button({
        label = "Scaled",
        width = 40,
        height = 30,
        onClick = function()
          clicks = clicks + 1
        end,
      })
    end

    ui.runtime:build(App)
    ui.runtime:layoutRoot(ui.runtime.root, 100, 100)
    ui.mousemoved(20, 20)
    assert.are.equal("Scaled", ui.runtime.hoverNode.props.label)

    ui.mousepressed(20, 20, 1)
    ui.mousereleased(20, 20, 1)
    assert.are.equal(1, clicks)

    ui.mousemoved(-1, 20)
    assert.is_nil(ui.runtime.hoverNode)
    ui.runtime.viewportBackend = previousBackend
  end)

  it("reports viewport backend helpers", function()
    local previousBackend = ui.runtime.viewportBackend
    ui.runtime.viewportBackend = {
      isEnabled = function() return true end,
      backend = function() return "push" end,
      screenToViewport = function(x, y) return true, x / 2, y / 2 end,
      viewportToScreen = function(x, y) return x * 2, y * 2 end,
      beginDraw = function() return true end,
      endDraw = function() return true end,
      raw = function() return { name = "fake" } end,
    }

    assert.is_true(ui.viewportBackend.isEnabled())
    assert.are.equal("push", ui.viewportBackend.backend())
    assert.are.same({ true, 10, 12 }, { ui.viewportBackend.screenToViewport(20, 24) })
    assert.are.same({ 20, 24 }, { ui.viewportBackend.viewportToScreen(10, 12) })
    assert.are.equal("fake", ui.viewportBackend.raw().name)

    ui.runtime.viewportBackend = previousBackend
  end)

  it("keeps responsive viewport dimensions virtual while resizing a backend", function()
    local previousBackend = ui.runtime.viewportBackend
    local previousWidth = ui.runtime.responsive.width
    local previousHeight = ui.runtime.responsive.height
    local resized
    ui.runtime.viewportBackend = {
      isEnabled = function() return true end,
      resize = function(width, height)
        resized = { width, height }
      end,
      dimensions = function()
        return 320, 180
      end,
      backend = function() return "shove" end,
      getViewport = function()
        return { x = 0, y = 0, width = 960, height = 540 }
      end,
    }

    ui.resize(960, 540)
    local viewport = ui.viewport()

    assert.are.same({ 960, 540 }, resized)
    assert.are.equal(320, viewport.width)
    assert.are.equal(180, viewport.height)
    assert.are.equal("shove", viewport.backend)
    assert.is_true(viewport.virtual)

    ui.runtime.viewportBackend = previousBackend
    ui.runtime.responsive.width = previousWidth
    ui.runtime.responsive.height = previousHeight
  end)

  it("lays out meter children as overlays", function()
    local runtime = Runtime.new()

    local function App()
      return Components.meter({
        value = 7,
        max = 10,
        width = 120,
        height = 16,
      }, {
        Components.text("70%"),
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)

    assert.are.equal(120, runtime.root.layout.width)
    assert.are.equal(16, runtime.root.layout.height)
    assert.are.equal(0, runtime.root.children[1].layout.x)
    assert.are.equal(0, runtime.root.children[1].layout.y)
  end)

  it("passes draw context to custom draw callbacks", function()
    local runtime = Runtime.new()
    local received
    local receivedPolygon

    runtime:setLove({
      timer = {
        getTime = function()
          return 2
        end,
      },
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getShader = function()
          return nil
        end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        polygon = function(_, ...)
          receivedPolygon = { ... }
        end,
      },
    })

    local function App()
      return Components.box({
        width = 100,
        height = 40,
        active = true,
        draw = function(_, _, _, _, _, _, _, ctx)
          received = ctx
          ctx:shape("fill", { kind = "skew", skew = 8 })
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(100, received.width)
    assert.are.equal(40, received.height)
    assert.is_true(received.active)
    assert.is_true(received.hot)
    assert.are.equal(2, received.time)
    assert.are.equal("table", type(received:skewBox({ skew = 4 })))
    assert.are.equal("table", type(receivedPolygon))
    assert.are.equal(8, receivedPolygon[7])
  end)

  it("resolves registered typography fonts and restores graphics font", function()
    local runtime = Runtime.new()
    local calls = {}
    local defaultFont = {
      getWidth = function(_, text)
        return #text * 6
      end,
      getHeight = function()
        return 12
      end,
    }
    local headingFont = {
      getWidth = function(_, text)
        return #text * 12
      end,
      getHeight = function()
        return 24
      end,
    }
    local currentFont = defaultFont
    local previousHeadingFont = runtime.theme.fonts.heading
    local previousH1Font = runtime.theme.typography.h1.font

    runtime.theme.fonts.heading = headingFont
    runtime.theme.typography.h1.font = "heading"
    runtime:setLove({
      graphics = {
        getFont = function()
          return currentFont
        end,
        setFont = function(font)
          currentFont = font
          calls[#calls + 1] = { "font", font }
        end,
        setColor = function() end,
        print = function(text)
          calls[#calls + 1] = { "print", text }
        end,
      },
    })

    runtime:build(function()
      return ui.h1("Title")
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(defaultFont, currentFont)
    assert.are.same({ "font", headingFont }, calls[1])
    assert.are.same({ "print", "Title" }, calls[2])

    runtime.theme.fonts.heading = previousHeadingFont
    runtime.theme.typography.h1.font = previousH1Font
  end)

  it("vertically aligns plain text inside an explicit text box height", function()
    local runtime = Runtime.new()
    local printedY

    runtime:setLove({
      graphics = {
        getFont = function() return nil end,
        setFont = function() end,
        setColor = function() end,
        print = function(_, _, y)
          printedY = y
        end,
      },
    })

    runtime:build(function()
      return ui.text("Centered", {
        height = 40,
        lineHeight = 10,
        textVerticalAlign = "center",
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(15, printedY)
  end)

  it("falls back to literal plain text when sysl rich backend is missing", function()
    ui.richTextBackend.clear()
    local runtime = Runtime.new()
    local printed = {}

    runtime:setLove({
      graphics = {
        getFont = function() return nil end,
        setFont = function() end,
        setColor = function() end,
        print = function(text)
          printed[#printed + 1] = text
        end,
      },
    })

    runtime:build(function()
      return ui.richText("A [color=#ff0000]B[/color] [nope]C")
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same({ "A [color=#ff0000]B[/color] [nope]C" }, printed)
  end)

  it("vertically aligns sysl rich text using textbox metrics", function()
    local runtime = Runtime.new()
    local drawY
    local fakeSysl = {
      configure = {
        function_command_enable = function() end,
      },
      new = function()
        local textbox = {
          get = { width = 40, height = 12, lines = 1 },
        }
        function textbox:send() end
        function textbox:draw(_, y)
          drawY = y
        end
        return textbox
      end,
    }

    ui.richTextBackend.configure({ sysl = fakeSysl })
    runtime:setLove({
      graphics = {
        getFont = function() return nil end,
        setFont = function() end,
        setColor = function() end,
        print = function() end,
      },
    })

    runtime:build(function()
      return ui.richText("Rich", {
        height = 40,
        textVerticalAlign = "bottom",
      })
    end)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.equal(28, drawY)
    ui.richTextBackend.clear()
  end)

  it("uses configured sysl textbox metrics for rich text layout and draw", function()
    local RichTextBackend = require("glyph.rich_text_backend")
    local runtime = Runtime.new()
    local calls = {}
    local fakeSysl = {
      configure = {
        function_command_enable = function(value)
          calls[#calls + 1] = { "function_command_enable", value }
        end,
      },
      new = function(align, defaults)
        calls[#calls + 1] = { "new", align, defaults.kind }
        local textbox = {
          get = { width = 123, height = 45, lines = 3 },
        }
        function textbox:send(text, width, showAll)
          calls[#calls + 1] = { "send", text, width, showAll }
        end
        function textbox:draw(x, y)
          calls[#calls + 1] = { "draw", x, y }
        end
        return textbox
      end,
    }

    ui.richTextBackend.configure({
      sysl = fakeSysl,
      defaults = { kind = "demo" },
    })
    runtime:setLove({
      graphics = {
        getFont = function() return nil end,
        setFont = function() end,
        setColor = function() end,
        print = function() end,
      },
    })

    runtime:build(function()
      return ui.richText("Hello", { width = 200, wrap = true, textAlign = "center" })
    end)
    runtime:layoutRoot(runtime.root)
    assert.are.equal(123, runtime.root.layout.width)
    assert.are.equal(45, runtime.root.layout.height)
    assert.are.equal(3, runtime.root.richText.lines)
    runtime:draw(runtime.root)

    assert.are.same({ "function_command_enable", false }, calls[1])
    assert.are.same({ "new", "center", "demo" }, calls[2])
    assert.are.same({ "send", "Hello", 200, true }, calls[3])
    assert.are.same({ "draw", 0, 0 }, calls[4])
    RichTextBackend.clear()
  end)

  it("recreates sysl textboxes when rich text width changes", function()
    local runtime = Runtime.new()
    local sends = {}
    local fakeSysl = {
      configure = {
        function_command_enable = function() end,
      },
      new = function()
        local textbox = {
          get = { width = 10, height = 10, lines = 1 },
        }
        function textbox:send(text, width)
          sends[#sends + 1] = { text, width }
        end
        function textbox:draw() end
        return textbox
      end,
    }

    ui.richTextBackend.configure({ sysl = fakeSysl })
    runtime:setLove({
      graphics = {
        getFont = function() return nil end,
        setFont = function() end,
        setColor = function() end,
        print = function() end,
      },
    })

    local width = 120
    runtime:build(function()
      return ui.richText("Hello", { width = width, wrap = true })
    end)
    runtime:layoutRoot(runtime.root)

    width = 180
    runtime:build(function()
      return ui.richText("Hello", { width = width, wrap = true })
    end)
    runtime:layoutRoot(runtime.root)

    assert.are.same({ "Hello", 120 }, sends[1])
    assert.are.same({ "Hello", 180 }, sends[2])
    ui.richTextBackend.clear()
  end)

  it("resolves rich text keys before sending to sysl", function()
    local sent
    ui.richTextBackend.configure({
      sysl = {
        configure = {
          function_command_enable = function() end,
        },
        new = function()
          local textbox = {
            get = { width = 20, height = 10, lines = 1 },
          }
          function textbox:send(text)
            sent = text
          end
          function textbox:draw() end
          return textbox
        end,
      },
    })
    ui.i18n.configure({
      translate = function(key)
        if key == "ready" then
          return "[color=#00ff00]Ready[/color]"
        end
      end,
    })

    local node = ui.richTextKey("ready")
    local runtime = Runtime.new()

    runtime:build(function()
      return node
    end)
    runtime:layoutRoot(runtime.root)

    assert.are.equal("[color=#00ff00]Ready[/color]", sent)
    ui.richTextBackend.clear()
    ui.i18n.configure({})
  end)

  it("translates keys with fallback and custom missing behavior", function()
    ui.i18n.configure({
      translate = function(key)
        if key == "hello" then
          return "Hello"
        end
      end,
      missing = function(key, _, opts)
        if opts and opts.fallback then
          return opts.fallback
        end
        return "missing:" .. key
      end,
    })

    assert.are.equal("Hello", ui.t("hello"))
    assert.are.equal("missing:unknown", ui.t("unknown"))
    assert.are.equal("Fallback", ui.t("unknown", nil, { fallback = "Fallback" }))

    ui.i18n.configure({})
  end)

  it("invalidates cached translations when locale changes", function()
    local calls = 0
    local locale = "en"
    ui.i18n.configure({
      getLocale = function()
        return locale
      end,
      setLocale = function(nextLocale)
        locale = nextLocale
      end,
      translate = function(key)
        calls = calls + 1
        return locale .. ":" .. key
      end,
    })

    local version = ui.i18n.version()
    assert.are.equal("en:menu.play", ui.t("menu.play"))
    assert.are.equal("en:menu.play", ui.t("menu.play"))
    assert.are.equal(1, calls)

    ui.runtime.needsRender = false
    ui.i18n.setLocale("es")
    assert.is_true(ui.i18n.version() > version)
    assert.is_true(ui.runtime.needsRender)
    assert.are.equal("es:menu.play", ui.t("menu.play"))
    assert.are.equal(2, calls)

    ui.i18n.configure({})
  end)

  it("caches params only when a cache key is provided", function()
    local calls = 0
    ui.i18n.configure({
      translate = function(_, params)
        calls = calls + 1
        return "Count " .. tostring(params.count)
      end,
    })

    local params = { count = 1 }
    assert.are.equal("Count 1", ui.t("count", params))
    params.count = 2
    assert.are.equal("Count 2", ui.t("count", params))
    assert.are.equal(2, calls)

    assert.are.equal("Count 2", ui.t("count", params, { cacheKey = "two" }))
    params.count = 3
    assert.are.equal("Count 2", ui.t("count", params, { cacheKey = "two" }))
    assert.are.equal(3, calls)

    ui.i18n.configure({})
  end)

  it("resolves keyed component props before layout and drawing", function()
    ui.i18n.configure({
      translate = function(key, params, opts)
        local values = {
          title = "Status",
          message = "Ready",
          button = "Launch",
          input = "Filter",
          tab = "Log",
          meter = "Power " .. tostring(params and params.value or ""),
        }
        return values[key] or (opts and opts.fallback)
      end,
    })

    local tree = ui.panel({ titleKey = "title" }, {
      ui.textKey("message"),
      ui.button({ labelKey = "button" }),
      ui.input({ value = "", placeholderKey = "input" }),
      ui.tabs({ active = 1 }, {
        { labelKey = "tab", content = ui.text("tab content") },
      }),
      ui.meter({
        value = 7,
        max = 10,
        labelKey = "meter",
        labelParams = { value = 7 },
        labelCacheKey = "7",
      }),
      ui.text("unchanged"),
      ui.textKey("missing", { textFallback = "Fallback" }),
    })

    assert.are.equal("Status", tree.children[1].value)
    assert.are.equal("Ready", tree.children[2].value)
    assert.are.equal("Launch", tree.children[3].props.label)
    assert.are.equal("Filter", tree.children[4].props.placeholder)
    assert.are.equal("Log", tree.children[5].children[1].children[1].props.label)
    assert.are.equal("Power 7", tree.children[6].props.label)
    assert.are.equal("unchanged", tree.children[7].value)
    assert.are.equal("Fallback", tree.children[8].value)

    ui.i18n.configure({})
  end)

  it("describes default accessibility semantics", function()
    local button = ui.button({ label = "Launch" })
    local input = ui.input({ value = "Nova", placeholder = "Name" })
    local meter = ui.meter({ value = 7, max = 10, label = "Power" })
    local panel = ui.panel({ title = "Status" }, {})

    assert.are.equal("button", ui.accessibility.describe(button).role)
    assert.are.equal("Launch", ui.accessibility.describe(button).label)
    assert.are.equal("input", ui.accessibility.describe(input).role)
    assert.are.equal("Name", ui.accessibility.describe(input).label)
    assert.are.equal("Nova", ui.accessibility.describe(input).valueText)
    assert.are.equal("meter", ui.accessibility.describe(meter).role)
    assert.are.equal("Power", ui.accessibility.describe(meter).label)
    assert.are.equal("Power", ui.accessibility.describe(meter).valueText)
    assert.are.equal("panel", ui.accessibility.describe(panel).role)
    assert.are.equal("Status", ui.accessibility.describe(panel).label)
  end)

  it("defines, plays, and clears feedback sequences", function()
    local events = {}
    local unregister = ui.on("feedback", function(event)
      events[#events + 1] = event.kind
    end)

    ui.feedback.define("test.ping", {
      { kind = "emit", event = "ping" },
    })
    ui.feedback.play("test.ping", nil, { trigger = "error" })

    assert.are.same({ "ping" }, events)
    ui.feedback.clear()
    assert.is_nil(ui.feedback.play("test.ping"))

    unregister()
  end)

  it("draws deterministic blob shapes from the draw context", function()
    local runtime = Runtime.new()
    local first
    local second
    local polygon

    runtime:setLove({
      graphics = {
        getLineWidth = function()
          return 1
        end,
        setLineWidth = function() end,
        getShader = function()
          return nil
        end,
        setShader = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        polygon = function(_, ...)
          polygon = { ... }
        end,
      },
    })

    local function App()
      return Components.box({
        width = 100,
        height = 50,
        draw = function(_, _, _, _, _, _, _, ctx)
          first = ctx:blob(nil, { points = 8, variance = 0.2, seed = "same" })
          second = ctx:blob(nil, { points = 8, variance = 0.2, seed = "same" })
          ctx:shape("fill", { kind = "blob", points = 8, variance = 0.2, seed = "same" })
        end,
      })
    end

    runtime:build(App)
    runtime:layoutRoot(runtime.root)
    runtime:draw(runtime.root)

    assert.are.same(first, second)
    assert.are.equal(16, #first)
    assert.are.equal(16, #polygon)
  end)

  it("uses explicit accessibility props and i18n semantic keys", function()
    ui.i18n.configure({
      translate = function(key)
        local values = {
          label = "Translated Launch",
          description = "Starts the mission",
          value = "Armed",
        }
        return values[key]
      end,
    })

    local node = ui.button({
      label = "Launch",
      accessibilityLabelKey = "label",
      accessibilityDescriptionKey = "description",
      accessibilityValueTextKey = "value",
    })
    local description = ui.accessibility.describe(node)

    assert.are.equal("Translated Launch", description.label)
    assert.are.equal("Starts the mission", description.description)
    assert.are.equal("Armed", description.valueText)

    ui.i18n.configure({})
  end)

  it("omits hidden and none-role nodes from accessibility snapshots", function()
    local tree = ui.column({}, {
      ui.text("Visible"),
      ui.text("Decorative", { accessibilityHidden = true }),
      ui.button({ label = "Skip", role = "none" }),
      ui.button({ label = "Go" }),
    })

    local snapshot = ui.accessibility.snapshot(tree)

    assert.are.equal(2, #snapshot)
    assert.are.equal("Visible", snapshot[1].label)
    assert.are.equal("Go", snapshot[2].label)
  end)
end)
