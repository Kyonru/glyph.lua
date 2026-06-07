local ViewportBackend = {}
ViewportBackend.__index = ViewportBackend

local FIT_SHOVE = {
  aspect = "aspect",
  pixel = "pixel",
  stretch = "stretch",
  none = "none",
}

local FIT_PUSH = {
  aspect = "normal",
  pixel = "pixel-perfect",
  stretch = "stretched",
}

---@param windowOpts? GlyphWindowOpts|table
---@return table
local function windowFlags(windowOpts)
  windowOpts = windowOpts or {}
  return {
    resizable = windowOpts.resizable ~= false,
    minwidth = windowOpts.minWidth or windowOpts.minwidth,
    minheight = windowOpts.minHeight or windowOpts.minheight,
    highdpi = windowOpts.highdpi,
    fullscreen = windowOpts.fullscreen,
    vsync = windowOpts.vsync,
  }
end

---@param windowOpts? GlyphWindowOpts|table
---@param fallbackWidth number
---@param fallbackHeight number
---@return number
---@return number
local function windowSize(windowOpts, fallbackWidth, fallbackHeight)
  windowOpts = windowOpts or {}
  return windowOpts.width or fallbackWidth, windowOpts.height or fallbackHeight
end

---@param graphics? table
---@return boolean
local function pushGraphicsState(graphics)
  if not graphics or not graphics.push then
    return false
  end

  local ok = pcall(graphics.push, "all")
  if not ok then
    graphics.push()
  end
  return true
end

---@param graphics? table
---@return nil
local function popGraphicsState(graphics)
  if graphics and graphics.pop then
    graphics.pop()
  end
end

---@param name "push"|"shove"|string
---@return table
local function requireBackend(name)
  if name == "push" then
    local ok, backend = pcall(require, "push")
    if ok then
      return backend
    end
    error("viewport backend 'push' is not available; install Push or pass viewport.instance (" .. tostring(backend) .. ")", 3)
  elseif name ~= "shove" then
    error("unsupported viewport backend '" .. tostring(name) .. "'", 3)
  end

  local ok, backend = pcall(require, "shove")
  if ok then
    return backend
  end
  error("viewport backend 'shove' is not available; install Shove or pass viewport.instance (" .. tostring(backend) .. ")", 3)
end

---@return GlyphViewportBackend
function ViewportBackend.new()
  return setmetatable({
    enabled = false,
    name = nil,
    instance = nil,
    managed = true,
    width = nil,
    height = nil,
    lastScreenWidth = nil,
    lastScreenHeight = nil,
    loveModule = nil,
    pushedGraphicsState = false,
  }, ViewportBackend)
end

---@param backend? table
---@param name string
---@param ... any
---@return any
function ViewportBackend.call(backend, name, ...)
  if not backend then
    return nil
  end

  local fn = backend[name]
  if type(fn) ~= "function" then
    return nil
  end

  local ok, a, b, c, d, e = pcall(fn, ...)
  if ok then
    return a, b, c, d, e
  end

  return fn(backend, ...)
end

---@return nil
function ViewportBackend:disable()
  self.enabled = false
  self.name = nil
  self.instance = nil
  self.managed = true
  self.width = nil
  self.height = nil
  self.lastScreenWidth = nil
  self.lastScreenHeight = nil
  self.loveModule = nil
  self.pushedGraphicsState = false
end

---@param opts? GlyphViewportBackendOpts
---@return boolean
function ViewportBackend:willHandleWindow(opts)
  opts = opts or {}
  local backend = opts.backend or "shove"
  local managed = opts.managed ~= false
  return managed and backend == "shove"
end

---@param opts? GlyphViewportBackendOpts
---@param windowOpts? GlyphWindowOpts|table
---@param loveModule? table
---@return nil
function ViewportBackend:configure(opts, windowOpts, loveModule)
  opts = opts or {}
  local backend = opts.backend or "shove"
  local instance = opts.instance or requireBackend(backend)
  local managed = opts.managed ~= false
  local width = opts.width
  local height = opts.height

  if (not width or not height) and backend == "shove" and instance.getViewportDimensions then
    width, height = instance.getViewportDimensions()
  elseif (not width or not height) and backend == "push" and instance.getDimensions then
    width, height = instance.getDimensions()
  end

  width = width or (windowOpts and windowOpts.width) or 800
  height = height or (windowOpts and windowOpts.height) or 600

  self.enabled = true
  self.name = backend
  self.instance = instance
  self.managed = managed
  self.width = width
  self.height = height
  self.loveModule = loveModule
  self.pushedGraphicsState = false

  if not managed then
    return
  end

  if backend == "shove" then
    if instance.setResolution then
      instance.setResolution(width, height, {
        fitMethod = FIT_SHOVE[opts.fit or opts.fitMethod or "aspect"] or "aspect",
        renderMode = opts.renderMode or "direct",
        scalingFilter = opts.filter or opts.scalingFilter,
      })
    end
    if instance.setWindowMode then
      local screenWidth, screenHeight = windowSize(windowOpts, width, height)
      instance.setWindowMode(screenWidth, screenHeight, windowFlags(windowOpts))
      self.lastScreenWidth = screenWidth
      self.lastScreenHeight = screenHeight
    end
  elseif backend == "push" then
    if loveModule and loveModule.graphics and loveModule.graphics.setDefaultFilter and opts.filter then
      loveModule.graphics.setDefaultFilter(opts.filter, opts.filter)
    end
    if instance.setupScreen then
      local fit = opts.fit or opts.fitMethod or "aspect"
      instance.setupScreen(width, height, {
        upscale = FIT_PUSH[fit],
        canvas = opts.canvas,
      })
    end
  end
end

---@return boolean
function ViewportBackend:isEnabled()
  return self.enabled == true
end

---@return "push"|"shove"|nil
function ViewportBackend:backend()
  return self.name
end

---@return boolean
function ViewportBackend:isManaged()
  return self.enabled and self.managed ~= false
end

---@return number|nil
---@return number|nil
function ViewportBackend:dimensions()
  if not self.enabled then
    return nil, nil
  end

  local instance = self.instance
  if self.name == "shove" and instance then
    if instance.getViewportDimensions then
      local width, height = instance.getViewportDimensions()
      return width or self.width, height or self.height
    end
    if instance.getViewportWidth and instance.getViewportHeight then
      return instance.getViewportWidth(), instance.getViewportHeight()
    end
  elseif self.name == "push" and instance then
    if instance.getDimensions then
      local width, height = instance.getDimensions()
      return width or self.width, height or self.height
    end
    if instance.getWidth and instance.getHeight then
      return instance.getWidth(), instance.getHeight()
    end
  end

  return self.width, self.height
end

---@param width number
---@param height number
---@return nil
function ViewportBackend:resize(width, height)
  if not self.enabled or not self.instance then
    return
  end

  self.lastScreenWidth = width
  self.lastScreenHeight = height
  if self.instance.resize then
    self.instance.resize(width, height)
  end
end

---@return boolean
function ViewportBackend:beginDraw()
  if not self.enabled or not self.instance then
    return false
  end

  if self.name == "shove" and self.instance.beginDraw then
    self.instance.beginDraw()
    return true
  elseif self.name == "push" and self.instance.start then
    local graphics = self.loveModule and self.loveModule.graphics
    self.pushedGraphicsState = pushGraphicsState(graphics)
    self.instance.start()
    return true
  end

  return false
end

---@return boolean
function ViewportBackend:endDraw()
  if not self.enabled or not self.instance then
    return false
  end

  if self.name == "shove" and self.instance.endDraw then
    self.instance.endDraw()
    return true
  elseif self.name == "push" and self.instance.finish then
    self.instance.finish()
    if self.pushedGraphicsState then
      local graphics = self.loveModule and self.loveModule.graphics
      popGraphicsState(graphics)
      self.pushedGraphicsState = false
    end
    return true
  end

  return false
end

---@param x number
---@param y number
---@return boolean
---@return number|false
---@return number|false
function ViewportBackend:screenToViewport(x, y)
  if not self.enabled or not self.instance then
    return true, x, y
  end

  if self.name == "shove" and self.instance.screenToViewport then
    local inside, viewX, viewY = self.instance.screenToViewport(x, y)
    return inside == true, viewX, viewY
  elseif self.name == "push" and self.instance.toGame then
    local viewX, viewY = self.instance.toGame(x, y)
    return viewX ~= false and viewY ~= false, viewX, viewY
  end

  return true, x, y
end

---@param x number
---@param y number
---@return number
---@return number
function ViewportBackend:viewportToScreen(x, y)
  if not self.enabled or not self.instance then
    return x, y
  end

  if self.name == "shove" and self.instance.viewportToScreen then
    return self.instance.viewportToScreen(x, y)
  elseif self.name == "push" and self.instance.toReal then
    return self.instance.toReal(x, y)
  end

  return x, y
end

---@return GlyphBounds|nil
function ViewportBackend:getViewport()
  if not self.enabled then
    return nil
  end

  if self.name == "shove" and self.instance and self.instance.getViewport then
    local x, y, width, height = self.instance.getViewport()
    return { x = x, y = y, width = width, height = height }
  end

  local width, height = self:dimensions()
  local x, y = self:viewportToScreen(0, 0)
  local x2, y2 = self:viewportToScreen(width or 0, height or 0)
  return {
    x = x,
    y = y,
    width = (x2 or 0) - (x or 0),
    height = (y2 or 0) - (y or 0),
  }
end

---@return table|nil
function ViewportBackend:raw()
  return self.instance
end

return ViewportBackend
