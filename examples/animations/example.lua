local ui = require("glyph")

local showCard = true
local selected = 1
local movementTarget = 1
local sizeTarget = 1

local meters = { hp = 76, mp = 42, charge = 0.34 }
local mover = { x = 30, y = 42, rotation = 0 }
local sizeBox = { width = 116, height = 88 }

local options = {
  { label = "Scout", color = { 0.1, 0.6, 0.92, 1 } },
  { label = "Guard", color = { 0.9, 0.62, 0.14, 1 } },
  { label = "Focus", color = { 0.74, 0.34, 0.92, 1 } },
  { label = "Burst", color = { 0.92, 0.18, 0.24, 1 } },
}

local moveTargets = {
  { x = 30, y = 42, rotation = 0 },
  { x = 214, y = 54, rotation = 0.35 },
  { x = 142, y = 122, rotation = -0.45 },
  { x = 54, y = 112, rotation = 0.72 },
}

local sizeTargets = {
  { width = 116, height = 88 },
  { width = 190, height = 118 },
  { width = 94, height = 132 },
}

local function setup()
  ui.setTheme({
    backgroundColor = { 0.035, 0.04, 0.055, 1 },
    surfaceColor = { 0.09, 0.11, 0.14, 1 },
    surfaceHoverColor = { 0.14, 0.18, 0.22, 1 },
    surfacePressedColor = { 0.06, 0.075, 0.095, 1 },
    borderColor = { 0.28, 0.35, 0.43, 1 },
    textColor = { 0.92, 0.95, 0.98, 1 },
    mutedTextColor = { 0.58, 0.65, 0.72, 1 },
    accentColor = { 0.1, 0.78, 0.68, 1 },
    components = {
      button = {
        variants = {
          ghost = {
            background = { 0, 0, 0, 0 },
            borderColor = { 1, 1, 1, 0.18 },
            color = { 0.86, 0.92, 0.96, 1 },
            hover = { background = { 0.16, 0.2, 0.25, 0.92 } },
          },
        },
      },
    },
  })

  ui.animation.clear()
end

local panelStyle = ui.style({
  background = { 0.075, 0.09, 0.12, 0.96 },
  borderColor = { 1, 1, 1, 0.14 },
  borderWidth = 1,
  radius = 8,
})

local labelStyle = ui.style({
  color = { 0.58, 0.66, 0.74, 1 },
})

local function animateMeters()
  ui.animation.to(meters, 0.36, {
    hp = meters.hp > 48 and 31 or 86,
    mp = meters.mp > 30 and 18 or 64,
    charge = meters.charge > 0.65 and 0.18 or 0.92,
  }, {
    ease = "quadinout",
  })
end

local function animateMover()
  movementTarget = movementTarget % #moveTargets + 1
  ui.animation.to(mover, 0.42, moveTargets[movementTarget], {
    ease = "backout",
  })
end

local function animateSize()
  sizeTarget = sizeTarget % #sizeTargets + 1
  ui.animation.to(sizeBox, 0.34, sizeTargets[sizeTarget], {
    ease = "backout",
  })
end

local function meterRow(label, value, max, fill)
  return ui.column({ gap = 5 }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.text(label, { style = labelStyle }),
      ui.box({ grow = 1, height = 1, interactive = false }),
      ui.text(string.format("%03d / %03d", math.floor(value + 0.5), max)),
    }),
    ui.meter({
      value = value,
      min = 0,
      max = max,
      height = 16,
      shape = { kind = "skew", skew = -10 },
      trackStyle = { background = { 0.02, 0.025, 0.035, 1 } },
      fillStyle = { background = fill },
      style = {
        borderColor = { 1, 1, 1, 0.16 },
        borderWidth = 1,
      },
    }),
  })
end

local function selectionButton(index, item)
  local active = selected == index
  return ui.button({
    label = item.label,
    width = 66,
    height = 48,
    active = active,
    onClick = function()
      selected = index
    end,
    style = {
      background = active and { item.color[1], item.color[2], item.color[3], 0.24 } or { 0.045, 0.055, 0.075, 1 },
      borderColor = active and item.color or { 1, 1, 1, 0.14 },
      borderWidth = 2,
      radius = 7,
      focused = {
        background = { 0.18, 0.26, 0.32, 1 },
        borderColor = { 1, 1, 1, 0.9 },
      },
    },
  })
end

local function animatedCard(width)
  if not showCard then
    return nil
  end

  return ui.box({
    key = "animation-example-card",
    width = width or 280,
    height = 102,
    enter = {
      duration = 0.28,
      ease = "backout",
      from = { opacity = 0, y = 20, scale = 0.88 },
      to = { opacity = 1, y = 0, scale = 1 },
    },
    exit = {
      duration = 0.18,
      ease = "quadin",
      to = { opacity = 0, y = -18, scale = 0.94 },
    },
    style = {
      background = { 0.12, 0.19, 0.24, 1 },
      borderColor = ui.theme.accentColor,
      borderWidth = 2,
      radius = 8,
    },
    draw = function(_, x, y, width, height, loveModule, style, ctx)
      ctx:color(style.background, style.opacity)
      loveModule.graphics.rectangle("fill", x, y, width, height, style.radius, style.radius)
      ctx:color(style.borderColor, style.opacity)
      loveModule.graphics.rectangle("line", x, y, width, height, style.radius, style.radius)
      ctx:color({ 0.86, 1, 0.96, 1 }, style.opacity)
      loveModule.graphics.print("Declarative enter / exit", x + 16, y + 18)
      ctx:color({ 0.56, 0.68, 0.76, 1 }, style.opacity)
      loveModule.graphics.print("Toggled nodes stay drawable while exiting.", x + 16, y + 48)
    end,
  })
end

local function movementPanel(width)
  return ui.box({
    width = width or 294,
    height = 174,
    style = {
      background = { 0.035, 0.045, 0.065, 1 },
      borderColor = { 1, 1, 1, 0.12 },
      borderWidth = 1,
      radius = 8,
    },
    draw = function(_, x, y, width, height, loveModule)
      local graphics = loveModule.graphics
      graphics.setColor(0.08, 0.11, 0.15, 1)
      graphics.rectangle("fill", x, y, width, height, 8, 8)
      graphics.setColor(1, 1, 1, 0.08)
      for i = 1, 4 do
        graphics.line(x + 20, y + i * 34, x + width - 20, y + i * 34)
      end
      graphics.push()
      graphics.translate(x + mover.x, y + mover.y)
      graphics.rotate(mover.rotation)
      graphics.setColor(0.1, 0.78, 0.68, 1)
      graphics.rectangle("fill", -18, -18, 36, 36, 6, 6)
      graphics.setColor(1, 1, 1, 0.8)
      graphics.rectangle("line", -18, -18, 36, 36, 6, 6)
      graphics.setColor(0.02, 0.05, 0.06, 1)
      graphics.print("MOVE", -15, -5)
      graphics.pop()
    end,
  })
end

local function sizePanel(width)
  return ui.column({
    width = width or 294,
    height = 174,
    padding = 12,
    align = "center",
    style = {
      background = { 0.04, 0.045, 0.06, 1 },
      borderColor = { 1, 1, 1, 0.12 },
      borderWidth = 1,
      radius = 8,
    },
  }, {
    ui.box({ grow = 1, height = 1, interactive = false }),
    ui.column({
      width = sizeBox.width,
      height = sizeBox.height,
      padding = 10,
      gap = 6,
      clip = true,
      style = {
        background = { 0.74, 0.34, 0.92, 0.9 },
        borderColor = { 1, 1, 1, 0.82 },
        borderWidth = 1,
        radius = 10,
      },
    }, {
      ui.text("Payload"),
      ui.text("Content wraps and the meter stays in flow.", {
        wrap = true,
        width = "100%",
        style = {
          color = { 0.92, 0.9, 1, 0.74 },
        },
      }),
      ui.box({ grow = 1, height = 1, interactive = false }),
      ui.meter({
        value = 66,
        min = 0,
        max = 100,
        width = "100%",
        height = 8,
        trackStyle = { background = { 0.06, 0.07, 0.09, 0.9 } },
        fillStyle = { background = { 0.1, 0.78, 0.68, 1 } },
      }),
    }),
    ui.box({ grow = 1, height = 1, interactive = false }),
  })
end

local function selectedPreview()
  local item = options[selected]
  return ui.box({
    key = "selected-preview-" .. tostring(selected),
    width = 260,
    height = 80,
    enter = {
      duration = 0.2,
      ease = "backout",
      from = { opacity = 0, x = 18, scale = 0.94 },
      to = { opacity = 1, x = 0, scale = 1 },
    },
    style = {
      background = { item.color[1], item.color[2], item.color[3], 0.18 },
      borderColor = item.color,
      borderWidth = 2,
      radius = 8,
    },
    draw = function(_, x, y, width, height, loveModule, style, ctx)
      ctx:color(style.background, style.opacity)
      loveModule.graphics.rectangle("fill", x, y, width, height, style.radius, style.radius)
      ctx:color(style.borderColor, style.opacity)
      loveModule.graphics.rectangle("line", x, y, width, height, style.radius, style.radius)
      ctx:color({ 1, 1, 1, 1 }, style.opacity)
      loveModule.graphics.print("Selected: " .. item.label, x + 16, y + 28)
    end,
  })
end

local function App()
  local viewport = ui.viewport()
  local compact = ui.below("md")
  local medium = ui.below("lg")
  local padding = compact and 12 or 16
  local contentWidth = math.max(320, viewport.width - padding * 2)
  local topAsRow = not medium and contentWidth >= 900
  local bottomAsRow = not compact and contentWidth >= 760
  local topPanelWidth = topAsRow and math.floor((contentWidth - 24) / 3) or contentWidth
  local bottomPanelWidth = bottomAsRow and math.floor((contentWidth - 12) / 2) or contentWidth
  local innerTopWidth = math.max(220, topPanelWidth - 24)
  local innerBottomWidth = math.max(220, bottomPanelWidth - 24)
  local selectionButtons = {}
  for index, item in ipairs(options) do
    selectionButtons[#selectionButtons + 1] = selectionButton(index, item)
  end

  local headerControls = ui.row({ gap = 8 }, {
    ui.button({
      label = showCard and "Hide card" or "Show card",
      onClick = function()
        showCard = not showCard
      end,
    }),
    ui.button({ label = "Meters", onClick = animateMeters }),
    ui.button({ label = "Move", onClick = animateMover }),
    ui.button({ label = "Resize", onClick = animateSize }),
  })

  local header = compact and ui.column({ gap = 10, width = "100%" }, {
    ui.column({ gap = 2 }, {
      ui.text("Animation Lab", {
        style = {
          color = { 0.96, 0.98, 1, 1 },
        },
      }),
      ui.text("Flux-backed enter, exit, value, movement, selection, and size tweens.", {
        wrap = true,
        width = "100%",
        style = labelStyle,
      }),
    }),
    headerControls,
  }) or ui.row({ gap = 12, align = "center", width = "100%" }, {
      ui.column({ gap = 2 }, {
        ui.text("Animation Lab", {
          style = {
            color = { 0.96, 0.98, 1, 1 },
          },
        }),
        ui.text("Flux-backed enter, exit, value, movement, selection, and size tweens.", {
          wrap = true,
          width = math.max(260, contentWidth - 420),
          style = labelStyle,
        }),
      }),
      ui.box({ grow = 1, height = 1, interactive = false }),
      headerControls,
    })

  local topPanels = {
      ui.panel({
        title = "Showing And Hiding",
        width = topPanelWidth,
        height = 174,
        padding = 12,
        gap = 10,
        style = panelStyle,
      }, {
        animatedCard(math.min(280, innerTopWidth)),
      }),

      ui.panel({
        title = "Animated Meters",
        width = topPanelWidth,
        height = 174,
        padding = 12,
        gap = 10,
        style = panelStyle,
      }, {
        meterRow("HP", meters.hp, 100, { 0.12, 0.78, 0.4, 1 }),
        meterRow("MP", meters.mp, 80, { 0.14, 0.48, 0.94, 1 }),
        meterRow("Charge", meters.charge * 100, 100, { 0.94, 0.68, 0.16, 1 }),
      }),

      ui.panel({
        title = "Selection",
        width = topPanelWidth,
        height = 174,
        padding = 12,
        gap = 10,
        style = panelStyle,
      }, {
        ui.row({ gap = 7 }, selectionButtons),
        selectedPreview(),
      }),
    }

  local bottomPanels = {
      ui.panel({
        title = "Movement",
        width = bottomPanelWidth,
        padding = 12,
        gap = 10,
        style = panelStyle,
      }, {
        movementPanel(innerBottomWidth),
      }),
      ui.panel({
        title = "Size Change",
        width = bottomPanelWidth,
        padding = 12,
        gap = 10,
        style = panelStyle,
      }, {
        sizePanel(innerBottomWidth),
      }),
    }

  return ui.stack({ width = viewport.width, height = viewport.height }, {
    ui.box({
      position = "absolute",
      inset = 0,
      interactive = false,
      style = {
        background = ui.theme.backgroundColor,
      },
    }),
    ui.scrollView({ width = "100%", height = "100%" }, {
      ui.column({
        gap = 12,
        padding = padding,
        width = "100%",
      }, {
        header,
        topAsRow and ui.row({ gap = 12, align = "stretch", width = "100%" }, topPanels) or ui.column({ gap = 12, width = "100%" }, topPanels),
        bottomAsRow and ui.row({ gap = 12, width = "100%" }, bottomPanels) or ui.column({ gap = 12, width = "100%" }, bottomPanels),
      }),
    }),
  })
end

return {
  id = "animations",
  label = "Animations",
  window = {
    width = 980,
    height = 590,
    resizable = true,
    minWidth = 420,
    minHeight = 360,
    breakpoints = { md = 760, lg = 980 },
    title = "glyph - animations",
  },
  setup = setup,
  component = function()
    return App()
  end,
}
