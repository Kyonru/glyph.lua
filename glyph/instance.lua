local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"

local Runtime = require(prefix .. ".runtime")
local Surface = require(prefix .. ".surface")
local theme = require(prefix .. ".theme")

local Instance = {}
local InstanceObject = {}
InstanceObject.__index = InstanceObject

local function dimensions(instance)
  local loveModule = instance.love or _G.love
  local graphics = loveModule and loveModule.graphics
  if graphics and type(graphics.getDimensions) == "function" then
    return graphics.getDimensions()
  end
  return instance.width or 800, instance.height or 600
end

---@return GlyphInstance
function InstanceObject:markDirty()
  if not self.destroyed then
    self._runtime:markDirty()
  end
  return self
end

---@param width number
---@param height number
---@return GlyphInstance
function InstanceObject:resize(width, height)
  self.width = math.max(1, math.floor(tonumber(width) or self.width or 1))
  self.height = math.max(1, math.floor(tonumber(height) or self.height or 1))
  self.ctx.width = self.width
  self.ctx.height = self.height
  self.ui.resize(self.width, self.height)
  return self
end

---@param dt? number
---@return GlyphInstance
function InstanceObject:update(dt)
  if not self.destroyed then
    self._runtime:update(dt or 0)
  end
  return self
end

---@param component? fun(ui: GlyphScopedUi, ctx: GlyphInstanceContext): GlyphNode
---@return GlyphNode|nil
function InstanceObject:render(component)
  if self.destroyed then
    return nil
  end
  if component ~= nil and component ~= self.component then
    self.component = component
    self._runtime:markDirty()
  end
  if type(self.component) ~= "function" then
    return nil
  end

  local width, height = dimensions(self)
  if width ~= self.width or height ~= self.height then
    self.ui.resize(width, height)
  end
  self.width = width
  self.height = height
  self.ctx.width = width
  self.ctx.height = height
  self._runtime:render(self._rootComponent)
  return self._runtime.root
end

---@param x number
---@param y number
---@return GlyphNode|nil
function InstanceObject:hitTest(x, y)
  if self.destroyed then
    return nil
  end
  return self._runtime:hitTest(x, y)
end

---@return GlyphNode|nil
function InstanceObject:focused()
  if self.destroyed then
    return nil
  end
  return self._runtime:activeFocusNode()
end

---@return boolean
function InstanceObject:hasFocus()
  return self:focused() ~= nil
end

---@param reverse? boolean
---@return boolean
function InstanceObject:focusNext(reverse)
  if self.destroyed then
    return false
  end
  return self.ui.focusNext(reverse)
end

---@param focused boolean
---@return boolean released whether any focus or input-capture state was cleared
function InstanceObject:focus(focused)
  if self.destroyed then
    return false
  end
  return self._runtime:focus(focused)
end

---@param node? GlyphNode
---@return GlyphInstance
function InstanceObject:setFocus(node)
  if not self.destroyed then
    self._runtime:setFocus(node)
  end
  return self
end

---@param x number
---@param y number
---@param dx? number
---@param dy? number
---@return boolean
function InstanceObject:mousemoved(x, y, dx, dy)
  if self.destroyed then
    return false
  end
  return self._runtime:mousemoved(x, y, dx, dy) == true
end

---@param x number
---@param y number
---@param button number
---@return boolean
function InstanceObject:mousepressed(x, y, button)
  if self.destroyed then
    return false
  end
  return self._runtime:mousepressed(x, y, button) == true
end

---@param x number
---@param y number
---@param button number
---@return boolean
function InstanceObject:mousereleased(x, y, button)
  if self.destroyed then
    return false
  end
  return self._runtime:mousereleased(x, y, button) == true
end

---@param dx number
---@param dy number
---@return boolean
function InstanceObject:wheelmoved(dx, dy)
  if self.destroyed then
    return false
  end
  return self._runtime:wheelmoved(dx, dy) == true
end

---@param key string
---@return boolean
function InstanceObject:keypressed(key)
  if self.destroyed then
    return false
  end
  return self._runtime:keypressed(key) == true
end

---@param key string
---@return boolean
function InstanceObject:keyreleased(key)
  if self.destroyed then
    return false
  end
  return self._runtime:keyreleased(key) == true
end

---@param text string
---@return boolean
function InstanceObject:textinput(text)
  if self.destroyed then
    return false
  end
  return self._runtime:textinput(text) == true
end

---@return GlyphInstance
function InstanceObject:destroy()
  if self.destroyed then
    return self
  end
  self.destroyed = true
  self._runtime:destroy()
  self.component = nil
  return self
end

---@param opts? GlyphInstanceOptions
---@return GlyphInstance
function Instance.new(opts)
  opts = opts or {}
  local runtime = Runtime.new()
  local loveModule = opts.love or _G.love
  runtime:setLove(loveModule)
  runtime.theme = opts.theme or theme

  local self = setmetatable({
    _runtime = runtime,
    love = loveModule,
    component = opts.component,
    width = math.max(1, math.floor(tonumber(opts.width) or 800)),
    height = math.max(1, math.floor(tonumber(opts.height) or 600)),
    destroyed = false,
    ctx = {},
  }, InstanceObject)

  self.ctx = {
    instance = self,
    width = self.width,
    height = self.height,
  }
  self.ui = Surface.scopedUi(runtime)
  self.ui.instance = self
  self._rootComponent = function()
    return self.component(self.ui, self.ctx)
  end
  return self
end

return Instance
