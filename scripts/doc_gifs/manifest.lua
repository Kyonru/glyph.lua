local ui = require("glyph")

local Manifest = {}

local palette = {
  bg = { 0.035, 0.043, 0.058, 1 },
  panel = { 0.075, 0.092, 0.118, 0.96 },
  panel2 = { 0.105, 0.075, 0.12, 0.95 },
  border = { 1, 1, 1, 0.16 },
  text = { 0.93, 0.96, 0.98, 1 },
  muted = { 0.58, 0.66, 0.73, 1 },
  teal = { 0.1, 0.78, 0.68, 1 },
  blue = { 0.22, 0.48, 0.92, 1 },
  gold = { 0.94, 0.66, 0.18, 1 },
  coral = { 0.92, 0.24, 0.3, 1 },
  violet = { 0.66, 0.38, 0.96, 1 },
}

local function cloneColor(color, alpha)
  return { color[1], color[2], color[3], alpha ~= nil and alpha or color[4] or 1 }
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function wave(ctx, speed, phase)
  return (math.sin((ctx.time or 0) * (speed or 1) + (phase or 0)) + 1) / 2
end

local function remember(ctx, value, limit)
  ctx.events = ctx.events or {}
  ctx.events[#ctx.events + 1] = value
  while #ctx.events > (limit or 5) do
    table.remove(ctx.events, 1)
  end
end

local function panelProps(extra)
  local props = {
    padding = 14,
    gap = 8,
    style = {
      background = palette.panel,
      borderColor = palette.border,
      borderWidth = 1,
      radius = 8,
    },
  }

  for key, value in pairs(extra or {}) do
    props[key] = value
  end

  return props
end

local function panel(title, props, children)
  props = panelProps(props)
  props.title = title
  props.titleTextStyle = "caption"
  props.titleColor = palette.muted
  return ui.panel(props, children)
end

local function pill(label, color)
  color = color or palette.teal
  return ui.box({
    width = 118,
    height = 28,
    padding = 6,
    display = "column",
    align = "center",
    justify = "center",
    style = {
      background = cloneColor(color, 0.18),
      borderColor = cloneColor(color, 0.72),
      borderWidth = 1,
      radius = 14,
    },
  }, {
    ui.text(label, { textStyle = "caption", style = { color = palette.text } }),
  })
end

local function metric(label, value, color)
  return ui.column({ gap = 5, width = 148 }, {
    ui.text(label, { textStyle = "caption", style = { color = palette.muted } }),
    ui.text(value, { textStyle = "h2", style = { color = color or palette.text } }),
  })
end

local function header(title, subtitle)
  return ui.row({ width = "100%", height = 64, align = "center", gap = 16 }, {
    ui.column({ gap = 4, flex = 1 }, {
      ui.h1(title, { style = { color = palette.text } }),
      ui.text(subtitle, { style = { color = palette.muted } }),
    }),
    pill("docs GIF", palette.teal),
  })
end

local function background(ctx)
  return ui.box({
    position = "absolute",
    inset = 0,
    interactive = false,
    accessibilityHidden = true,
    draw = function(_, x, y, width, height, loveModule)
      local g = loveModule.graphics
      g.setColor(palette.bg)
      g.rectangle("fill", x, y, width, height)
      g.setColor(1, 1, 1, 0.045)
      for ix = -80, width, 40 do
        g.line(x + ix + wave(ctx, 1.1) * 26, y, x + ix + 120, y + height)
      end
      g.setColor(palette.teal[1], palette.teal[2], palette.teal[3], 0.06)
      g.circle("fill", x + width * 0.16, y + height * 0.18, 150)
      g.setColor(palette.coral[1], palette.coral[2], palette.coral[3], 0.055)
      g.circle("fill", x + width * 0.84, y + height * 0.78, 190)
    end,
  })
end

local function stage(ctx, title, subtitle, children)
  return ui.stack({ width = ctx.width, height = ctx.height }, {
    background(ctx),
    ui.column({
      position = "absolute",
      left = 36,
      top = 26,
      width = ctx.width - 72,
      gap = 14,
    }, {
      header(title, subtitle),
      children,
    }),
  })
end

local function codeBlock(lines)
  local nodes = {}
  for _, line in ipairs(lines) do
    nodes[#nodes + 1] = ui.text(line, {
      textStyle = "caption",
      style = { color = line:find("^%s") and palette.muted or palette.teal },
    })
  end

  return panel("declarative Lua", { width = 384, height = 260 }, nodes)
end

local function eventList(ctx, title)
  local rows = {}
  for index, event in ipairs(ctx.events or {}) do
    rows[#rows + 1] = ui.row({ height = 28, gap = 8, align = "center" }, {
      ui.box({
        width = 8,
        height = 8,
        style = {
          background = ({ palette.teal, palette.gold, palette.coral, palette.blue, palette.violet })[(index - 1) % 5 + 1],
          radius = 4,
        },
      }),
      ui.text(event, { style = { color = palette.text } }),
    })
  end

  while #rows < 5 do
    rows[#rows + 1] = ui.text("waiting for scripted event", { style = { color = cloneColor(palette.muted, 0.5) } })
  end

  return panel(title or "event stream", { width = 336, height = 212 }, rows)
end

local function makeProceduralImage(ctx, id)
  if ctx.images and ctx.images[id] then
    return ctx.images[id]
  end

  local loveModule = ctx.love or _G.love
  if not loveModule or not loveModule.image or not loveModule.graphics then
    return nil
  end

  ctx.images = ctx.images or {}
  local imageData = loveModule.image.newImageData(64, 64)

  for y = 0, 63 do
    for x = 0, 63 do
      local dx = x - 31.5
      local dy = y - 31.5
      local radius = math.sqrt(dx * dx + dy * dy) / 45
      local stripe = ((math.floor((x + y) / 8) % 2) == 0) and 0.12 or 0
      imageData:setPixel(x, y, 0.12 + radius * 0.2, 0.58 + stripe, 0.74 + radius * 0.18, 1)
    end
  end

  ctx.images[id] = loveModule.graphics.newImage(imageData)
  return ctx.images[id]
end

local function target(opts)
  opts.duration = opts.duration or 2.6
  opts.fps = opts.fps or 18
  return opts
end

local targets = {
  target({
    id = "getting-started",
    title = "Getting Started",
    docs = { "docs/getting-started.md" },
    alt = "Animated GIF showing a minimal Glyph counter app rendering and updating.",
    setup = function(ctx)
      ctx.count = 0
      ctx.input = "debugger"
    end,
    update = function(ctx)
      ctx.flash = wave(ctx, 7) > 0.58
    end,
    actions = {
      { at = 0.55, run = function(ctx) ctx.count = ctx.count + 1 end },
      { at = 1.15, run = function(ctx) ctx.input = "debugger panel" end },
      { at = 1.75, run = function(ctx) ctx.count = ctx.count + 1 end },
    },
    component = function(ctx)
      return stage(ctx, "Getting Started", "A small app function becomes a live UI tree.", ui.row({ gap = 14 }, {
        codeBlock({
          "local function App()",
          "  local count = " .. tostring(ctx.count),
          "  return ui.column({ gap = 8 }, {",
          "    ui.button({ label = \"Increment\" })",
          "    ui.text(\"Count: \" .. count)",
          "  })",
          "end",
          "",
          "ui.render(App)",
        }),
        panel("running preview", { flex = 1, height = 260 }, {
          ui.input({
            value = ctx.input,
            width = "100%",
            placeholder = "Panel name",
          }),
          ui.button({
            label = "Increment",
            active = ctx.flash,
            style = {
              background = ctx.flash and cloneColor(palette.teal, 0.28) or cloneColor(palette.blue, 0.22),
              borderColor = ctx.flash and palette.teal or palette.border,
              borderWidth = 1,
              radius = 7,
            },
          }),
          ui.text("Count: " .. tostring(ctx.count), { textStyle = "h2", style = { color = palette.gold } }),
          ui.meter({
            value = ctx.count,
            max = 3,
            height = 16,
            fillStyle = { background = palette.teal },
          }),
        }),
      }))
    end,
  }),

  target({
    id = "components",
    title = "Components",
    docs = { "docs/components.md" },
    alt = "Animated GIF showing Glyph text, image, button, input, meter, tabs, and panel components.",
    setup = function(ctx)
      ctx.tab = 1
      ctx.input = "pilot"
      makeProceduralImage(ctx, "components")
    end,
    update = function(ctx)
      ctx.meter = 42 + math.floor(wave(ctx, 2.7) * 48)
    end,
    actions = {
      { at = 0.7, run = function(ctx) ctx.tab = 2 end },
      { at = 1.35, run = function(ctx) ctx.input = "pilot ready" end },
      { at = 1.95, run = function(ctx) ctx.tab = 3 end },
    },
    component = function(ctx)
      local image = ctx.images and ctx.images.components
      return stage(ctx, "Components", "The core widget set stays generic and composable.", ui.row({ gap = 14 }, {
        panel("primitives", { width = 418, height = 294 }, {
          ui.h2("Mission Console", { style = { color = palette.text } }),
          ui.row({ gap = 12, align = "center" }, {
            image and ui.image({
              source = image,
              width = 78,
              height = 78,
              fit = "cover",
              clip = { kind = "circle" },
              interactive = false,
            }) or ui.box({ width = 78, height = 78 }),
            ui.column({ gap = 7, flex = 1 }, {
              ui.input({ value = ctx.input, width = "100%" }),
              ui.button({ label = "Queue Action", active = ctx.tab == 2 }),
              ui.meter({
                value = ctx.meter,
                max = 100,
                height = 14,
                fillStyle = { background = palette.gold },
              }),
            }),
          }),
        }),
        panel("tabs and panels", { flex = 1, height = 294 }, {
          ui.tabs({
            active = ctx.tab,
            width = "100%",
            activeColor = cloneColor(palette.teal, 0.25),
          }, {
            { label = "Text", content = ui.text("Readable labels and rich text hooks.", { style = { color = palette.text } }) },
            { label = "Layout", content = ui.text("Rows, columns, stacks, and scroll views.", { style = { color = palette.text } }) },
            { label = "HUD", content = ui.text("Images, meters, panels, and buttons.", { style = { color = palette.text } }) },
          }),
          ui.row({ gap = 8 }, {
            pill("button", palette.blue),
            pill("input", palette.gold),
            pill("meter", palette.coral),
          }),
        }),
      }))
    end,
  }),

  target({
    id = "layout",
    title = "Layout",
    docs = { "docs/layout.md" },
    alt = "Animated GIF showing Glyph rows, columns, stack layering, and absolute positioning.",
    update = function(ctx)
      ctx.slide = wave(ctx, 2.2)
    end,
    component = function(ctx)
      local slide = ctx.slide or 0
      return stage(ctx, "Layout", "Flow layout and absolute overlays share one tree.", ui.row({ gap = 14 }, {
        panel("row and column flow", { width = 390, height = 292 }, {
          ui.row({ gap = 8, height = 58 }, {
            ui.box({ flex = 1, style = { background = cloneColor(palette.teal, 0.28), radius = 6 } }),
            ui.box({ flex = 2, style = { background = cloneColor(palette.gold, 0.28), radius = 6 } }),
            ui.box({ flex = 1, style = { background = cloneColor(palette.coral, 0.28), radius = 6 } }),
          }),
          ui.column({ gap = 8 }, {
            ui.box({ height = 34, width = "100%", style = { background = cloneColor(palette.blue, 0.22), radius = 6 } }),
            ui.box({ height = 34, width = "72%", style = { background = cloneColor(palette.violet, 0.22), radius = 6 } }),
            ui.box({ height = 34, width = "46%", style = { background = cloneColor(palette.teal, 0.22), radius = 6 } }),
          }),
        }),
        panel("stack and absolute", { flex = 1, height = 292 }, {
          ui.stack({ width = "100%", height = 214 }, {
            ui.box({
              position = "absolute",
              inset = 0,
              interactive = false,
              style = { background = { 0.03, 0.04, 0.055, 1 }, borderColor = palette.border, borderWidth = 1, radius = 8 },
            }),
            ui.box({
              position = "absolute",
              left = 34 + slide * 190,
              top = 46,
              width = 172,
              height = 78,
              style = { background = cloneColor(palette.teal, 0.22), borderColor = palette.teal, borderWidth = 2, radius = 8 },
            }, {
              ui.text("absolute child", { position = "absolute", left = 16, top = 26, style = { color = palette.text } }),
            }),
            ui.box({
              position = "absolute",
              right = 24,
              bottom = 22,
              width = 188,
              height = 78,
              zIndex = 3,
              style = { background = cloneColor(palette.coral, 0.24), borderColor = palette.coral, borderWidth = 2, radius = 8 },
            }, {
              ui.text("higher zIndex", { position = "absolute", left = 18, top = 26, style = { color = palette.text } }),
            }),
          }),
        }),
      }))
    end,
  }),

  target({
    id = "styling",
    title = "Styling And Themes",
    docs = { "docs/styling.md" },
    alt = "Animated GIF showing Glyph theme colors, variants, and state styles.",
    setup = function(ctx)
      ctx.mode = 1
    end,
    update = function(ctx)
      ctx.glow = wave(ctx, 4.8)
    end,
    actions = {
      { at = 0.7, run = function(ctx) ctx.mode = 2 end },
      { at = 1.4, run = function(ctx) ctx.mode = 3 end },
      { at = 2.1, run = function(ctx) ctx.mode = 1 end },
    },
    component = function(ctx)
      local accents = { palette.teal, palette.gold, palette.coral }
      local accent = accents[ctx.mode or 1]
      return stage(ctx, "Styling", "Theme tokens, variants, and states resolve into draw styles.", ui.row({ gap = 14 }, {
        panel("theme tokens", { width = 336, height = 286 }, {
          ui.row({ gap = 10 }, {
            ui.box({ width = 56, height = 56, style = { background = palette.teal, radius = 8 } }),
            ui.box({ width = 56, height = 56, style = { background = palette.gold, radius = 8 } }),
            ui.box({ width = 56, height = 56, style = { background = palette.coral, radius = 8 } }),
            ui.box({ width = 56, height = 56, style = { background = palette.violet, radius = 8 } }),
          }),
          ui.meter({
            value = 35 + ctx.glow * 60,
            max = 100,
            height = 16,
            fillStyle = { background = accent },
          }),
          ui.text("Active accent follows scripted variant changes.", { wrap = true, width = "100%", style = { color = palette.muted } }),
        }),
        panel("state styles", { flex = 1, height = 286 }, {
          ui.row({ gap = 10 }, {
            ui.button({
              label = "Default",
              width = 132,
              style = { borderWidth = 1, radius = 7 },
            }),
            ui.button({
              label = "Active",
              width = 132,
              active = true,
              style = {
                background = cloneColor(accent, 0.24),
                borderColor = accent,
                borderWidth = 2,
                radius = 7,
              },
            }),
            ui.button({
              label = "Pressed",
              width = 132,
              active = ctx.glow > 0.48,
              style = {
                background = ctx.glow > 0.48 and cloneColor(palette.coral, 0.32) or cloneColor(palette.blue, 0.2),
                borderColor = ctx.glow > 0.48 and palette.coral or palette.border,
                borderWidth = 2,
                radius = 7,
                transition = { background = 0.16 },
              },
            }),
          }),
          ui.box({
            height = 112,
            width = "100%",
            style = {
              background = cloneColor(accent, 0.14 + ctx.glow * 0.12),
              borderColor = cloneColor(accent, 0.62),
              borderWidth = 1,
              radius = 8,
            },
          }, {
            ui.text("style.transition blends visual state without changing layout", {
              position = "absolute",
              left = 18,
              top = 40,
              style = { color = palette.text },
            }),
          }),
        }),
      }))
    end,
  }),

  target({
    id = "runtime",
    title = "Runtime, Hooks, And Events",
    docs = { "docs/runtime.md" },
    alt = "Animated GIF showing Glyph runtime updates, input events, focus, and render callbacks.",
    setup = function(ctx)
      ctx.events = { "ui.render(App)", "beforeUpdate" }
      ctx.focus = 1
    end,
    actions = {
      { at = 0.45, run = function(ctx) ctx.focus = 2; remember(ctx, "mousepressed: Run", 5) end },
      { at = 0.95, run = function(ctx) remember(ctx, "keypressed: return", 5) end },
      { at = 1.45, run = function(ctx) ctx.focus = 3; remember(ctx, "focusChanged: Filter", 5) end },
      { at = 2.0, run = function(ctx) remember(ctx, "afterRender", 5) end },
    },
    component = function(ctx)
      return stage(ctx, "Runtime", "One runtime owns hooks, event routing, and draw traversal.", ui.row({ gap = 14 }, {
        panel("interactive tree", { flex = 1, height = 294 }, {
          ui.row({ gap = 10 }, {
            ui.button({ label = "Inspect", active = ctx.focus == 1, width = 130 }),
            ui.button({ label = "Run", active = ctx.focus == 2, width = 130 }),
            ui.input({ value = "Filter", width = 190, active = ctx.focus == 3 }),
          }),
          ui.row({ gap = 14 }, {
            metric("hover", ctx.focus == 1 and "node.1" or "none", palette.teal),
            metric("focus", "node." .. tostring(ctx.focus), palette.gold),
            metric("dirty", wave(ctx, 6) > 0.45 and "true" or "false", palette.coral),
          }),
          ui.meter({
            value = 40 + wave(ctx, 3.6) * 55,
            max = 100,
            height = 14,
            fillStyle = { background = palette.blue },
          }),
        }),
        eventList(ctx, "runtime callbacks"),
      }))
    end,
  }),

  target({
    id = "callback-bus",
    title = "Callback Bus",
    docs = { "docs/callback-bus.md" },
    alt = "Animated GIF showing Glyph callback bus priority order and event dispatch.",
    setup = function(ctx)
      ctx.events = {}
      ctx.bus = ui.CallbackBus.new({ "event" })
      ctx.bus:register("event", function(name) remember(ctx, "priority -10: " .. name, 6) end, { priority = -10 })
      ctx.bus:register("event", function(name) remember(ctx, "priority 0: " .. name, 6) end)
      ctx.bus:register("event", function(name) remember(ctx, "priority 10: " .. name, 6) end, { priority = 10 })
    end,
    actions = {
      { at = 0.45, run = function(ctx) ctx.bus:dispatch("event", "beforeRender") end },
      { at = 1.2, run = function(ctx) ctx.bus:dispatch("event", "feedback") end },
      { at = 1.85, run = function(ctx) ctx.bus:dispatch("event", "afterRender") end },
    },
    component = function(ctx)
      return stage(ctx, "Callback Bus", "Registrations run by priority with snapshot-safe dispatch.", ui.row({ gap = 14 }, {
        panel("registered handlers", { width = 430, height = 282 }, {
          ui.row({ gap = 8, align = "center" }, {
            pill("priority -10", palette.teal),
            ui.text("adapter first", { style = { color = palette.muted } }),
          }),
          ui.row({ gap = 8, align = "center" }, {
            pill("priority 0", palette.gold),
            ui.text("default work", { style = { color = palette.muted } }),
          }),
          ui.row({ gap = 8, align = "center" }, {
            pill("priority 10", palette.coral),
            ui.text("late observer", { style = { color = palette.muted } }),
          }),
          ui.text("dispatch(\"event\", name)", { textStyle = "caption", style = { color = palette.text } }),
        }),
        eventList(ctx, "dispatch log"),
      }))
    end,
  }),

  target({
    id = "i18n",
    title = "I18n",
    docs = { "docs/i18n.md" },
    alt = "Animated GIF showing Glyph localized text, labels, placeholders, and cache-aware values.",
    setup = function(ctx)
      ctx.locale = "en"
      local copy = {
        en = { title = "Ready", action = "Launch", status = "Charge %d%%", input = "Pilot name" },
        es = { title = "Listo", action = "Lanzar", status = "Carga %d%%", input = "Nombre" },
      }
      ui.i18n.configure({
        locale = ctx.locale,
        translate = function(key, params)
          local value = copy[ctx.locale] and copy[ctx.locale][key]
          if key == "status" and value then
            return string.format(value, params and params.value or 0)
          end
          return value
        end,
      })
    end,
    update = function(ctx)
      ctx.charge = math.floor(45 + wave(ctx, 2.5) * 50)
    end,
    actions = {
      { at = 0.8, run = function(ctx) ctx.locale = "es"; ui.i18n.setLocale("es") end },
      { at = 1.65, run = function(ctx) ctx.locale = "en"; ui.i18n.setLocale("en") end },
    },
    component = function(ctx)
      return stage(ctx, "I18n", "Glyph resolves keys while apps own locale policy.", ui.row({ gap = 14 }, {
        panel("keyed props", { flex = 1, height = 280 }, {
          ui.h2(ui.t("title"), { style = { color = palette.gold } }),
          ui.input({ placeholderKey = "input", value = "", width = "100%" }),
          ui.button({ labelKey = "action", width = 190, active = ctx.locale == "es" }),
          ui.meter({
            value = ctx.charge,
            max = 100,
            labelKey = "status",
            labelParams = { value = ctx.charge },
            labelCacheKey = "charge:" .. tostring(ctx.charge),
            height = 18,
            fillStyle = { background = palette.teal },
          }),
        }),
        panel("locale state", { width = 320, height = 280 }, {
          metric("locale", ctx.locale, palette.teal),
          metric("version", tostring(ui.i18n.version()), palette.gold),
          ui.text("Parameterized translations refresh unless a cache key pins the value.", {
            wrap = true,
            width = "100%",
            style = { color = palette.muted },
          }),
        }),
      }))
    end,
  }),

  target({
    id = "accessibility",
    title = "Accessibility",
    docs = { "docs/accessibility.md" },
    alt = "Animated GIF showing Glyph semantic labels, focus events, live announcements, and snapshots.",
    setup = function(ctx)
      ctx.events = { "semantic tree ready" }
      ui.accessibility.configure({
        enabled = true,
        announceOnFocus = true,
        announceOnActivate = true,
      })
      ctx.offAccessibility = ui.on("accessibility", function(event)
        remember(ctx, (event.kind or "event") .. ": " .. tostring(event.message or event.label or ""), 5)
      end)
    end,
    actions = {
      { at = 0.55, run = function() ui.accessibility.announce("Autosave complete", { kind = "live", live = "polite" }) end },
      { at = 1.2, run = function(ctx) remember(ctx, "snapshot: button, meter, log", 5) end },
      { at = 1.85, run = function() ui.accessibility.announce("Modal opened", { kind = "announce" }) end },
    },
    component = function(ctx)
      return stage(ctx, "Accessibility", "Metadata, snapshots, and events for app-owned adapters.", ui.row({ gap = 14 }, {
        panel("semantic nodes", { flex = 1, height = 286 }, {
          ui.button({
            label = "Launch",
            accessibilityLabel = "Launch mission",
            accessibilityDescription = "Starts the selected mission",
          }),
          ui.meter({
            value = 60 + wave(ctx, 2) * 30,
            max = 100,
            label = "Power",
            accessibilityValueText = "Power level changing",
            height = 16,
            fillStyle = { background = palette.gold },
          }),
          ui.text("Live status: autosave complete", {
            accessibilityLive = "polite",
            style = { color = palette.text },
          }),
        }),
        eventList(ctx, "adapter events"),
      }))
    end,
  }),

  target({
    id = "responsive",
    title = "Responsive Helpers",
    docs = { "docs/responsive.md" },
    alt = "Animated GIF showing Glyph responsive breakpoints, columns, and virtual viewport mapping.",
    setup = function(ctx)
      ctx.simWidth = 620
    end,
    update = function(ctx)
      ctx.simWidth = math.floor(620 + wave(ctx, 1.8) * 300)
    end,
    component = function(ctx)
      local columns = ctx.simWidth > 820 and 3 or ctx.simWidth > 700 and 2 or 1
      local cards = {}
      for index = 1, columns do
        cards[index] = ui.box({
          flex = 1,
          height = 92,
          style = {
            background = cloneColor(({ palette.teal, palette.gold, palette.coral })[index], 0.24),
            borderColor = ({ palette.teal, palette.gold, palette.coral })[index],
            borderWidth = 1,
            radius = 8,
          },
        }, {
          ui.text("column " .. tostring(index), { position = "absolute", left = 16, top = 36, style = { color = palette.text } }),
        })
      end

      return stage(ctx, "Responsive", "Breakpoints and viewport adapters keep game UI predictable.", ui.row({ gap = 14 }, {
        panel("adaptive columns", { flex = 1, height = 284 }, {
          metric("simulated width", tostring(ctx.simWidth) .. "px", palette.teal),
          ui.row({ gap = 10, width = "100%" }, cards),
          ui.meter({ value = ctx.simWidth - 600, min = 0, max = 340, height = 14, fillStyle = { background = palette.blue } }),
        }),
        panel("virtual viewport", { width = 320, height = 284 }, {
          ui.text("screen 960x540", { style = { color = palette.muted } }),
          ui.box({
            width = 252,
            height = 142,
            style = { background = cloneColor(palette.blue, 0.16), borderColor = palette.blue, borderWidth = 1, radius = 8 },
          }, {
            ui.box({
              position = "absolute",
              left = 38 + wave(ctx, 3.2) * 112,
              top = 48,
              width = 26,
              height = 26,
              style = { background = palette.teal, radius = 13 },
            }),
            ui.text("virtual 320x180", { position = "absolute", left = 18, bottom = 16, style = { color = palette.text } }),
          }),
        }),
      }))
    end,
  }),

  target({
    id = "custom-draw",
    title = "Custom Draw And Helpers",
    docs = { "docs/custom-draw.md" },
    alt = "Animated GIF showing Glyph custom draw helpers, shapes, clipping, and stencil-like masks.",
    update = function(ctx)
      ctx.phase = wave(ctx, 3)
    end,
    component = function(ctx)
      return stage(ctx, "Custom Draw", "Game-specific visuals stay in app draw functions.", ui.row({ gap = 14 }, {
        panel("draw context", { flex = 1, height = 292 }, {
          ui.box({
            width = "100%",
            height = 205,
            draw = function(_, x, y, width, height, loveModule)
              local g = loveModule.graphics
              g.setColor(0.03, 0.04, 0.055, 1)
              g.rectangle("fill", x, y, width, height, 8, 8)
              local points = ui.polygonBox(x + 34, y + 34, width - 68, 76, { skew = 22 })
              g.setColor(palette.teal)
              g.polygon("fill", points)
              g.setColor(1, 1, 1, 0.82)
              g.polygon("line", points)
              g.setColor(palette.gold)
              for i = 1, 18 do
                local px = x + 34 + i * ((width - 80) / 18)
                local py = y + 156 + math.sin(i * 0.8 + (ctx.time or 0) * 5) * 28
                g.circle("fill", px, py, 4 + ctx.phase * 2)
              end
              g.setColor(palette.coral[1], palette.coral[2], palette.coral[3], 0.24)
              g.circle("fill", x + width - 86, y + 74, 44)
            end,
          }),
        }),
        panel("visual-only masks", { width = 320, height = 292 }, {
          ui.meter({
            kind = "arc",
            value = 40 + ctx.phase * 55,
            max = 100,
            width = 128,
            height = 128,
            thickness = 12,
            fillStyle = { background = palette.coral },
          }, {
            ui.text("ARC", { style = { color = palette.text } }),
          }),
          ui.text("Shape, clip, stencil, and helper drawing do not change layout geometry.", {
            wrap = true,
            width = "100%",
            style = { color = palette.muted },
          }),
        }),
      }))
    end,
  }),

  target({
    id = "animations",
    title = "Animations",
    docs = { "docs/animations.md" },
    alt = "Animated GIF showing Glyph enter, exit, meter, and movement animations.",
    setup = function(ctx)
      ctx.values = { meter = 28, x = 0, rotation = 0 }
      ctx.show = true
    end,
    actions = {
      { at = 0.35, run = function(ctx) ui.animation.to(ctx.values, 0.45, { meter = 88, x = 180, rotation = 0.5 }, { ease = "backout" }) end },
      { at = 1.2, run = function(ctx) ctx.show = false end },
      { at = 1.75, run = function(ctx) ctx.show = true; ui.animation.to(ctx.values, 0.4, { meter = 42, x = 24, rotation = -0.25 }, { ease = "quadinout" }) end },
    },
    component = function(ctx)
      local card = nil
      if ctx.show then
        card = ui.box({
          key = "doc-animation-card",
          width = 260,
          height = 86,
          enter = { duration = 0.24, from = { opacity = 0, y = 18, scale = 0.9 }, to = { opacity = 1, y = 0, scale = 1 }, ease = "backout" },
          exit = { duration = 0.18, to = { opacity = 0, y = -14, scale = 0.94 }, ease = "quadin" },
          style = { background = cloneColor(palette.teal, 0.22), borderColor = palette.teal, borderWidth = 2, radius = 8 },
        }, {
          ui.text("enter / exit node", { position = "absolute", left = 18, top = 32, style = { color = palette.text } }),
        })
      end

      return stage(ctx, "Animations", "Flux-backed visual animation leaves layout stable.", ui.row({ gap = 14 }, {
        panel("animated state", { flex = 1, height = 292 }, {
          ui.meter({ value = ctx.values.meter, max = 100, height = 18, fillStyle = { background = palette.gold } }),
          ui.box({
            width = "100%",
            height = 124,
            style = { background = { 0.03, 0.04, 0.055, 1 }, borderColor = palette.border, borderWidth = 1, radius = 8 },
          }, {
            ui.box({
              position = "absolute",
              left = 36 + ctx.values.x,
              top = 42,
              width = 54,
              height = 54,
              style = { background = palette.coral, radius = 7 },
              draw = function(_, x, y, width, height, loveModule, style)
                loveModule.graphics.push()
                loveModule.graphics.translate(x + width / 2, y + height / 2)
                loveModule.graphics.rotate(ctx.values.rotation)
                loveModule.graphics.setColor(style.background)
                loveModule.graphics.rectangle("fill", -width / 2, -height / 2, width, height, 7, 7)
                loveModule.graphics.pop()
              end,
            }),
          }),
        }),
        panel("lifecycle", { width = 320, height = 292 }, { card or ui.box({ width = 260, height = 86 }) }),
      }))
    end,
  }),

  target({
    id = "feedback",
    title = "Feedback",
    docs = { "docs/feedback.md" },
    alt = "Animated GIF showing Glyph feedback sequences, visual animation, audio metadata, and emitted events.",
    setup = function(ctx)
      ctx.events = {}
      ui.feedback.clear()
      ui.feedback.define("docs.pop", {
        { kind = "animate", to = { scaleX = 1.08, scaleY = 0.9 }, duration = 0.06 },
        { kind = "audio", cue = "ui-pop" },
        { kind = "emit", event = "particles", payload = { name = "spark" } },
        { kind = "animate", to = { scale = 1 }, duration = 0.18, ease = "backout" },
      })
      ui.on("feedback", function(event)
        remember(ctx, "feedback: " .. tostring(event.event or event.kind or "emit"), 5)
      end)
      ui.on("audio", function(event)
        remember(ctx, "audio: " .. tostring(event.cue or "cue"), 5)
      end)
    end,
    actions = {
      { at = 0.6, run = function() ui.mousepressed(160, 282, 1) end },
      { at = 0.74, run = function() ui.mousereleased(160, 282, 1) end },
      { at = 1.55, run = function() ui.mousepressed(160, 282, 1) end },
      { at = 1.69, run = function() ui.mousereleased(160, 282, 1) end },
    },
    component = function(ctx)
      return stage(ctx, "Feedback", "Sequences compose animation, audio metadata, and app-owned FX.", ui.row({ gap = 14 }, {
        panel("triggerable sequence", { flex = 1, height = 286 }, {
          ui.button({
            label = "Launch Pulse",
            width = 220,
            height = 62,
            feedback = {
              press = "docs.pop",
              activate = "docs.pop",
            },
            style = {
              background = cloneColor(palette.teal, 0.24),
              borderColor = palette.teal,
              borderWidth = 2,
              radius = 8,
            },
          }),
          ui.text("Pointer actions are scripted by the capture runner.", { style = { color = palette.muted } }),
          ui.meter({ value = 35 + wave(ctx, 6) * 60, max = 100, height = 14, fillStyle = { background = palette.coral } }),
        }),
        eventList(ctx, "app-owned events"),
      }))
    end,
  }),

  target({
    id = "scenes-modals",
    title = "Scenes And Modals",
    docs = { "docs/scenes-and-modals.md" },
    alt = "Animated GIF showing Glyph scene layers, overlays, modal blocking, and backdrop behavior.",
    setup = function(ctx)
      ctx.modal = false
    end,
    actions = {
      { at = 0.75, run = function(ctx) ctx.modal = true end },
      { at = 1.75, run = function(ctx) ctx.modal = false end },
    },
    component = function(ctx)
      return stage(ctx, "Scenes And Modals", "Layered roots route input from top to bottom.", ui.stack({ width = "100%", height = 304 }, {
        ui.box({
          position = "absolute",
          left = 20,
          top = 18,
          width = 480,
          height = 226,
          style = { background = cloneColor(palette.blue, 0.2), borderColor = palette.blue, borderWidth = 2, radius = 8 },
        }, {
          ui.text("main scene", { position = "absolute", left = 18, top = 18, style = { color = palette.text } }),
          ui.meter({ position = "absolute", left = 18, top = 68, width = 360, height = 16, value = 70, max = 100, fillStyle = { background = palette.teal } }),
        }),
        ui.box({
          position = "absolute",
          right = 36,
          top = 42,
          width = 260,
          height = 112,
          zIndex = 3,
          style = { background = cloneColor(palette.gold, 0.2), borderColor = palette.gold, borderWidth = 2, radius = 8 },
        }, {
          ui.text("non-blocking overlay", { position = "absolute", left = 16, top = 40, style = { color = palette.text } }),
        }),
        ctx.modal and ui.box({
          position = "absolute",
          inset = 0,
          zIndex = 10,
          style = { background = { 0, 0, 0, 0.42 }, radius = 8 },
        }, {
          ui.box({
            position = "absolute",
            left = 294,
            top = 76,
            width = 300,
            height = 142,
            style = { background = palette.panel2, borderColor = palette.coral, borderWidth = 2, radius = 8 },
          }, {
            ui.text("modal layer", { position = "absolute", left = 22, top = 28, style = { color = palette.text } }),
            ui.text("blocking input", { position = "absolute", left = 22, top = 66, style = { color = palette.muted } }),
          }),
        }) or nil,
      }))
    end,
  }),

  target({
    id = "transitions",
    title = "Transitions",
    docs = { "docs/transitions.md" },
    alt = "Animated GIF showing Glyph fade, slide, shader-style, and animated layer transitions.",
    update = function(ctx)
      ctx.progress = wave(ctx, 2.1)
    end,
    component = function(ctx)
      local p = ctx.progress or 0
      return stage(ctx, "Transitions", "Layers can fade, slide, animate, or delegate custom drawing.", ui.row({ gap = 14 }, {
        panel("built-ins", { flex = 1, height = 284 }, {
          ui.stack({ width = "100%", height = 190 }, {
            ui.box({ position = "absolute", left = 20, top = 22, width = 280, height = 128, style = { background = cloneColor(palette.blue, 0.22), borderColor = palette.blue, borderWidth = 1, radius = 8 } }),
            ui.box({
              position = "absolute",
              left = 72 + p * 190,
              top = 52,
              width = 240,
              height = 128,
              style = { background = cloneColor(palette.teal, 0.18 + p * 0.18), borderColor = palette.teal, borderWidth = 2, radius = 8 },
            }, {
              ui.text("slide + fade", { position = "absolute", left = 22, top = 52, style = { color = palette.text } }),
            }),
          }),
        }),
        panel("custom transition", { width = 320, height = 284 }, {
          ui.box({
            width = 250,
            height = 150,
            draw = function(_, x, y, width, height, loveModule)
              local g = loveModule.graphics
              g.setColor(0.03, 0.04, 0.055, 1)
              g.rectangle("fill", x, y, width, height, 8, 8)
              for i = 1, 9 do
                local alpha = math.max(0, 0.42 - math.abs(i / 9 - p) * 0.8)
                g.setColor(palette.coral[1], palette.coral[2], palette.coral[3], alpha)
                g.rectangle("fill", x + i * 22, y + 14, 14, height - 28, 7, 7)
              end
              g.setColor(1, 1, 1, 0.74)
              g.rectangle("line", x, y, width, height, 8, 8)
            end,
          }),
          ui.text("ctx.drawLayer() stays app-composable.", { style = { color = palette.muted } }),
        }),
      }))
    end,
  }),

  target({
    id = "navigation",
    title = "Spatial Navigation",
    docs = { "docs/navigation.md" },
    alt = "Animated GIF showing Glyph spatial navigation focus moving through buttons and scoped groups.",
    setup = function(ctx)
      ctx.focus = 1
    end,
    actions = {
      { at = 0.45, run = function(ctx) ctx.focus = 2 end },
      { at = 0.9, run = function(ctx) ctx.focus = 4 end },
      { at = 1.35, run = function(ctx) ctx.focus = 5 end },
      { at = 1.95, run = function(ctx) ctx.focus = 3 end },
    },
    component = function(ctx)
      local buttons = {}
      for index, label in ipairs({ "Scan", "Map", "Load", "Stats", "Party", "Exit" }) do
        buttons[index] = ui.button({
          label = label,
          width = 138,
          height = 58,
          active = ctx.focus == index,
          navGroup = index <= 3 and "top" or "bottom",
          style = {
            background = ctx.focus == index and cloneColor(palette.teal, 0.28) or cloneColor(palette.blue, 0.12),
            borderColor = ctx.focus == index and palette.teal or palette.border,
            borderWidth = ctx.focus == index and 2 or 1,
            radius = 7,
          },
        })
      end

      return stage(ctx, "Navigation", "Directional focus works without layout-specific widgets.", ui.row({ gap = 14 }, {
        panel("focus grid", { flex = 1, height = 286 }, {
          ui.row({ gap = 10 }, { buttons[1], buttons[2], buttons[3] }),
          ui.row({ gap = 10 }, { buttons[4], buttons[5], buttons[6] }),
          ui.text("Scripted arrows move through focusable nodes and nav groups.", { style = { color = palette.muted } }),
        }),
        panel("scope", { width = 320, height = 286 }, {
          metric("focused", tostring(ctx.focus), palette.gold),
          ui.box({
            width = 252,
            height = 96,
            style = { background = cloneColor(palette.violet, 0.18), borderColor = palette.violet, borderWidth = 1, radius = 8 },
          }, {
            ui.text("navScope submenu", { position = "absolute", left = 18, top = 34, style = { color = palette.text } }),
          }),
        }),
      }))
    end,
  }),

  target({
    id = "performance",
    title = "Performance",
    docs = { "docs/performance.md" },
    alt = "Animated GIF showing Glyph memoized rows, static nodes, visible windows, and bounded work.",
    setup = function(ctx)
      ctx.offset = 1
    end,
    update = function(ctx)
      ctx.offset = 1 + math.floor(wave(ctx, 1.7) * 16)
    end,
    component = function(ctx)
      local rows = {}
      for i = 0, 7 do
        local index = ctx.offset + i
        rows[#rows + 1] = ui.row({
          height = 28,
          width = "100%",
          gap = 8,
          align = "center",
          style = {
            background = i % 2 == 0 and { 1, 1, 1, 0.035 } or { 1, 1, 1, 0.015 },
            radius = 4,
          },
        }, {
          ui.text("#" .. tostring(index), { width = 54, style = { color = palette.muted } }),
          ui.meter({ value = (index * 13) % 100, max = 100, height = 10, flex = 1, fillStyle = { background = ({ palette.teal, palette.gold, palette.coral })[index % 3 + 1] } }),
          ui.text("static row", { width = 92, textStyle = "caption", style = { color = palette.text } }),
        })
      end

      return stage(ctx, "Performance", "Memo, static nodes, and visible windows keep work bounded.", ui.row({ gap = 14 }, {
        panel("visible rows", { flex = 1, height = 310 }, rows),
        panel("work budget", { width = 318, height = 310 }, {
          metric("mounted rows", "8 / 10k", palette.teal),
          metric("memo hits", tostring(80 + math.floor(wave(ctx, 4.5) * 18)) .. "%", palette.gold),
          metric("layout pass", wave(ctx, 7) > 0.5 and "dirty" or "clean", palette.coral),
          ui.text("Large data demos should show bounded rendering, not full-list churn.", {
            wrap = true,
            width = "100%",
            style = { color = palette.muted },
          }),
        }),
      }))
    end,
  }),
}

function Manifest.targets()
  return targets
end

function Manifest.find(id)
  for _, item in ipairs(targets) do
    if item.id == id then
      return item
    end
  end
  return nil
end

return Manifest
