local ui = require("glyph")

local backend = "shove"
local fit = "aspect"
local filter = "nearest"
local clicks = 0
local backendError = nil
local pointer = {
  screenX = 0,
  screenY = 0,
  inside = false,
  viewX = 0,
  viewY = 0,
}

local fits = {
  { id = "aspect", label = "Aspect" },
  { id = "pixel", label = "Pixel" },
  { id = "stretch", label = "Stretch" },
  { id = "none", label = "None" },
}

local filters = {
  { id = "nearest", label = "Nearest" },
  { id = "linear", label = "Linear" },
}

local function loadBackendInstance(name)
  if name == "native" then
    return nil, nil
  end

  local ok, instance = pcall(require, name)
  if ok then
    return instance, nil
  end
  return nil, tostring(instance)
end

local function configureViewport()
  local instance, loadError = loadBackendInstance(backend)
  if backend == "native" then
    backendError = nil
    if ui.runtime.viewportBackend then
      ui.runtime.viewportBackend:disable()
    end
    ui.configureWindow({
      width = 960,
      height = 540,
      resizable = true,
      minWidth = 420,
      minHeight = 260,
      breakpoints = { md = 520, lg = 720 },
    })
    return
  end

  if not instance then
    backendError = loadError
    if ui.runtime.viewportBackend then
      ui.runtime.viewportBackend:disable()
    end
    ui.resize(960, 540)
    return
  end

  local ok, err = pcall(ui.configureWindow, {
    width = 960,
    height = 540,
    resizable = true,
    minWidth = 420,
    minHeight = 260,
    breakpoints = { md = 520, lg = 620 },
    viewport = {
      backend = backend,
      instance = instance,
      width = 640,
      height = 360,
      fit = fit,
      filter = filter,
      canvas = false,
      renderMode = "direct",
      managed = true,
    },
  })

  if ok then
    backendError = nil
  else
    backendError = tostring(err)
    if ui.runtime.viewportBackend then
      ui.runtime.viewportBackend:disable()
    end
    ui.resize(960, 540)
  end
end

local function setup()
  ui.setTheme({
    backgroundColor = { 0.035, 0.04, 0.055, 1 },
    surfaceColor = { 0.09, 0.11, 0.14, 1 },
    surfaceHoverColor = { 0.14, 0.18, 0.24, 1 },
    surfacePressedColor = { 0.055, 0.07, 0.095, 1 },
    borderColor = { 0.28, 0.35, 0.43, 1 },
    textColor = { 0.92, 0.95, 0.98, 1 },
    mutedTextColor = { 0.58, 0.66, 0.74, 1 },
    accentColor = { 0.1, 0.78, 0.68, 1 },
    components = {
      button = {
        variants = {
          ghost = {
            background = { 0, 0, 0, 0 },
            borderColor = { 1, 1, 1, 0.18 },
            hover = { background = { 0.14, 0.18, 0.24, 0.94 } },
          },
        },
      },
    },
  })
  configureViewport()
end

local function teardown(mode)
  if mode == "showcase" and ui.runtime.viewportBackend then
    ui.runtime.viewportBackend:disable()
    if love and love.graphics and love.graphics.getDimensions then
      ui.resize(love.graphics.getDimensions())
    end
  end
end

local function update()
  if love and love.mouse and love.mouse.getPosition then
    pointer.screenX, pointer.screenY = love.mouse.getPosition()
    if ui.viewportBackend.isEnabled() then
      pointer.inside, pointer.viewX, pointer.viewY = ui.viewportBackend.screenToViewport(pointer.screenX, pointer.screenY)
    else
      pointer.inside = true
      pointer.viewX = pointer.screenX
      pointer.viewY = pointer.screenY
    end
    ui.runtime:markDirty()
  end
end

local function backendButton(id, label)
  return ui.button({
    label = label,
    width = 88,
    active = backend == id,
    variant = backend == id and "primary" or "ghost",
    onClick = function()
      backend = id
      configureViewport()
    end,
  })
end

local function fitButton(item)
  return ui.button({
    label = item.label,
    width = 74,
    active = fit == item.id,
    variant = fit == item.id and "primary" or "ghost",
    onClick = function()
      fit = item.id
      configureViewport()
    end,
  })
end

local function filterButton(item)
  return ui.button({
    label = item.label,
    width = 78,
    active = filter == item.id,
    variant = filter == item.id and "primary" or "ghost",
    onClick = function()
      filter = item.id
      configureViewport()
    end,
  })
end

local function openModal()
  ui.modal.open("viewport-proof", function()
    return ui.panel({
      title = "Scaled Modal",
      width = 260,
      gap = 8,
    }, {
      ui.text("Scenes and modals render inside the same virtual viewport.", {
        width = 236,
        wrap = true,
      }),
      ui.button({
        label = "Close",
        width = 96,
        variant = "primary",
        onClick = function()
          ui.modal.close("viewport-proof")
        end,
      }),
    })
  end, {
    transition = ui.transitions.animate({
      enter = { duration = 0.18, from = { opacity = 0, scale = 0.92 }, to = { opacity = 1, scale = 1 } },
      exit = { duration = 0.12, to = { opacity = 0, scale = 0.96 } },
    }),
  })
end

local function gridBackground()
  return ui.box({
    position = "absolute",
    inset = 0,
    interactive = false,
    draw = function(_, x, y, width, height, loveModule, _, ctx)
      local graphics = loveModule.graphics
      ctx:color(ui.theme.backgroundColor)
      graphics.rectangle("fill", x, y, width, height)
      ctx:color({ 1, 1, 1, 0.05 })
      for gx = 0, width, 24 do
        graphics.line(x + gx, y, x + gx, y + height)
      end
      for gy = 0, height, 24 do
        graphics.line(x, y + gy, x + width, y + gy)
      end
    end,
  })
end

local function pointerPanel(width)
  local view = ui.viewport()
  local statusText = backendError and "backend error" or tostring(view.backend or "none")
  local statusColor = backendError and { 0.96, 0.36, 0.32, 1 } or ui.theme.textColor
  local children = {
    ui.text("backend: " .. statusText, { style = { color = statusColor } }),
    ui.text(string.format("virtual: %dx%d", view.width or 0, view.height or 0)),
  }

  if backendError then
    children[#children + 1] = ui.text(backendError, {
      style = { color = { 0.96, 0.58, 0.52, 1 } },
    })
  end

  children[#children + 1] = ui.text(string.format("screen: %d,%d", pointer.screenX, pointer.screenY), {
    style = { color = ui.theme.mutedTextColor },
  })
  children[#children + 1] = ui.text(pointer.inside and string.format("viewport: %d,%d", pointer.viewX, pointer.viewY) or "outside viewport", {
    style = { color = pointer.inside and ui.theme.textColor or { 0.9, 0.34, 0.34, 1 } },
  })
  children[#children + 1] = ui.button({
    label = "Click target " .. tostring(clicks),
    variant = "primary",
    onClick = function()
      clicks = clicks + 1
    end,
  })

  return ui.panel({
    title = "Coordinates",
    width = width,
    gap = 8,
  }, children)
end

local function scrollProof(width)
  local rows = {}
  for index = 1, 18 do
    rows[#rows + 1] = ui.button({
      label = string.format("Scaled scroll row %02d", index),
      width = width - 24,
      variant = index % 3 == 0 and "primary" or "ghost",
      onClick = function()
        clicks = clicks + 1
      end,
    })
  end

  return ui.panel({
    title = "Hover + Scroll",
    width = width,
    height = 140,
    gap = 8,
  }, {
    ui.scrollView({
      width = "100%",
      height = 96,
      gap = 5,
      padding = 4,
    }, rows),
  })
end

local function App()
  local view = ui.viewport()
  local compact = ui.below("lg")
  local contentWidth = view.width - 24
  local sideWidth = compact and contentWidth or 188
  local mainWidth = compact and contentWidth or contentWidth - sideWidth - 12

  local fitButtons = {}
  for _, item in ipairs(fits) do
    fitButtons[#fitButtons + 1] = fitButton(item)
  end
  local filterButtons = {}
  for _, item in ipairs(filters) do
    filterButtons[#filterButtons + 1] = filterButton(item)
  end

  local controls = ui.panel({
    title = "Options",
    width = sideWidth,
    gap = 8,
  }, {
    ui.column({ gap = 6 }, fitButtons),
    ui.row({ gap = 6 }, filterButtons),
    ui.button({
      label = "Open Modal",
      width = 120,
      variant = "primary",
      onClick = openModal,
    }),
  })

  local main = ui.column({ gap = 10, width = mainWidth }, {
    ui.panel({
      title = "Fixed Virtual UI",
      width = mainWidth,
      gap = 8,
    }, {
      ui.text("This entire screen is laid out at 640x360 and scaled by the selected backend.", {
        width = math.max(120, mainWidth - 24),
        wrap = true,
      }),
      ui.meter({
        value = pointer.inside and pointer.viewX or 0,
        min = 0,
        max = view.width,
        width = "100%",
        height = 10,
        fillStyle = { background = ui.theme.accentColor },
        trackStyle = { background = { 0, 0, 0, 0.25 } },
      }),
    }),
    pointerPanel(mainWidth),
    scrollProof(mainWidth),
  })

  return ui.stack({ width = view.width, height = view.height }, {
    gridBackground(),
    ui.column({ padding = 12, gap = 10, width = "100%", height = "100%" }, {
      ui.row({ gap = 6, width = contentWidth }, {
        backendButton("native", "Native"),
        backendButton("push", "Push"),
        backendButton("shove", "Shove"),
      }),
      compact and ui.column({ gap = 10, width = contentWidth }, {
        controls,
        main,
      }) or ui.row({ gap = 12, width = contentWidth }, {
        controls,
        main,
      }),
    }),
  })
end

return {
  id = "viewport",
  label = "Viewport",
  description = "Compare native, Push, and Shove virtual viewports with pointer conversion, scroll rows, and modal hit tests.",
  setup = setup,
  teardown = teardown,
  update = update,
  window = {
    width = 960,
    height = 540,
    resizable = true,
    minWidth = 420,
    minHeight = 260,
    title = "glyph - viewport backend",
  },
  component = function()
    return App()
  end,
}
