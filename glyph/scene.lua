local Transitions = require("glyph.transitions")

local Scene = {}
Scene.__index = Scene

local function copyOptions(opts)
  local copied = {}
  for key, value in pairs(opts or {}) do
    copied[key] = value
  end
  return copied
end

local function newScope()
  return {
    hooks = {},
    effects = {},
    pendingEffects = {},
  }
end

local function resolveTransition(opts)
  local transition = opts.transition
  if transition == nil and opts.transitionName then
    transition = opts.transitionName
  end
  if transition == nil and opts.kind == "modal" then
    transition = "fade"
  end

  local resolved = Transitions.resolve(transition)
  if opts.duration ~= nil then
    resolved.duration = opts.duration
  end
  if opts.exitDuration ~= nil then
    resolved.exitDuration = opts.exitDuration
  end
  if opts.transitionOpts then
    for key, value in pairs(opts.transitionOpts) do
      resolved[key] = value
    end
  end
  return resolved
end

local function sortLayers(layers)
  table.sort(layers, function(a, b)
    if (a.zIndex or 0) == (b.zIndex or 0) then
      return a.order < b.order
    end
    return (a.zIndex or 0) < (b.zIndex or 0)
  end)
end

function Scene.new(runtime)
  return setmetatable({
    runtime = runtime,
    layers = {},
    order = 0,
  }, Scene)
end

function Scene:createLayer(id, component, opts)
  opts = copyOptions(opts)
  self.order = self.order + 1

  local kind = opts.kind or "scene"
  local transition = resolveTransition(opts)
  local layer = {
    id = id,
    kind = kind,
    component = component,
    props = opts.props,
    order = self.order,
    zIndex = opts.zIndex or (kind == "modal" and 1000 or kind == "overlay" and 500 or 0),
    state = "entering",
    progress = transition.duration == 0 and 1 or 0,
    transition = transition,
    width = opts.width,
    height = opts.height,
    align = opts.align or (kind == "modal" and "center" or "stretch"),
    blocking = opts.blocking,
    input = opts.input,
    backdrop = opts.backdrop,
    backdropColor = opts.backdropColor or { 0, 0, 0, 0.5 },
    dismissOnBackdrop = opts.dismissOnBackdrop == true,
    escapeToClose = opts.escapeToClose,
    onEnter = opts.onEnter,
    onExit = opts.onExit,
    onClose = opts.onClose,
    onUpdate = opts.onUpdate,
    onEvent = opts.onEvent,
    root = nil,
    offsetX = 0,
    offsetY = 0,
    bounds = { x = 0, y = 0, width = 0, height = 0 },
    needsRender = true,
    scope = newScope(),
  }
  layer.scope.layer = layer

  if layer.blocking == nil then
    layer.blocking = kind == "modal" or kind == "scene"
  end
  if layer.input == nil then
    layer.input = true
  end
  if layer.backdrop == nil then
    layer.backdrop = kind == "modal"
  end
  if layer.escapeToClose == nil then
    layer.escapeToClose = kind ~= "scene"
  end

  if layer.state == "entering" and layer.progress >= 1 then
    layer.state = "open"
  end

  if type(layer.onEnter) == "function" then
    layer.onEnter(layer)
  end

  return layer
end

function Scene:findIndex(id)
  for index, layer in ipairs(self.layers) do
    if layer.id == id then
      return index, layer
    end
  end
  return nil, nil
end

---@param id string|number
---@param component fun(): GlyphNode
---@param opts? GlyphLayerOpts
---@return GlyphLayer
function Scene:set(id, component, opts)
  opts = copyOptions(opts)
  opts.kind = opts.kind or "scene"
  opts.blocking = opts.blocking ~= false
  self.layers = {}
  local layer = self:createLayer(id, component, opts)
  self.layers[1] = layer
  self.runtime:markDirty()
  return layer
end

---@param id string|number
---@param component fun(): GlyphNode
---@param opts? GlyphLayerOpts
---@return GlyphLayer
function Scene:push(id, component, opts)
  local existingIndex = self:findIndex(id)
  if existingIndex then
    table.remove(self.layers, existingIndex)
  end

  local layer = self:createLayer(id, component, opts)
  self.layers[#self.layers + 1] = layer
  sortLayers(self.layers)
  self.runtime:markDirty()
  return layer
end

---@param id string|number
---@return GlyphLayer|nil
function Scene:close(id)
  local _, layer = self:findIndex(id)
  if layer and layer.state ~= "exiting" then
    layer.state = "exiting"
    layer.progress = 0
    if type(layer.onExit) == "function" then
      layer.onExit(layer)
    end
    self.runtime:markDirty()
  end
  return layer
end

---@param id? string|number
---@return GlyphLayer|nil
function Scene:pop(id)
  if id ~= nil then
    return self:close(id)
  end

  for index = #self.layers, 1, -1 do
    local layer = self.layers[index]
    if layer.state ~= "exiting" then
      return self:close(layer.id)
    end
  end
  return nil
end

---@param predicate? fun(layer: GlyphLayer): boolean
function Scene:clear(predicate)
  for _, layer in ipairs(self.layers) do
    if layer.state ~= "exiting" and (predicate == nil or predicate(layer)) then
      layer.state = "exiting"
      layer.progress = 0
      if type(layer.onExit) == "function" then
        layer.onExit(layer)
      end
    end
  end
  self.runtime:markDirty()
end

---@return GlyphLayer|nil
function Scene:current()
  for index = #self.layers, 1, -1 do
    if self.layers[index].state ~= "exiting" then
      return self.layers[index]
    end
  end
  return nil
end

---@param id string|number
---@return boolean
function Scene:isOpen(id)
  local _, layer = self:findIndex(id)
  return layer ~= nil and layer.state ~= "exiting"
end

function Scene:update(dt)
  local remove = {}

  for index, layer in ipairs(self.layers) do
    if type(layer.onUpdate) == "function" then
      layer.onUpdate(layer, dt)
    end

    if layer.state == "entering" then
      local duration = layer.transition.duration or 0
      layer.progress = duration <= 0 and 1 or math.min(1, layer.progress + dt / duration)
      layer.needsRender = true
      self.runtime:markDirty()
      if layer.progress >= 1 then
        layer.state = "open"
        layer.progress = 1
      end
    elseif layer.state == "exiting" then
      local duration = layer.transition.exitDuration or layer.transition.duration or 0
      layer.progress = duration <= 0 and 1 or math.min(1, layer.progress + dt / duration)
      layer.needsRender = true
      self.runtime:markDirty()
      if layer.progress >= 1 then
        if type(layer.onClose) == "function" then
          layer.onClose(layer)
        end
        remove[#remove + 1] = index
      end
    end
  end

  for index = #remove, 1, -1 do
    table.remove(self.layers, remove[index])
  end
end

function Scene:closeTopEscapable()
  for index = #self.layers, 1, -1 do
    local layer = self.layers[index]
    if layer.state ~= "exiting" and layer.escapeToClose ~= false then
      self:close(layer.id)
      return layer
    end
    if layer.blocking then
      return nil
    end
  end
  return nil
end

function Scene:topInteractiveHit(x, y, hitTest)
  for index = #self.layers, 1, -1 do
    local layer = self.layers[index]
    if layer.state ~= "exiting" and layer.input ~= false then
      local hit = nil
      if layer.root then
        hit = hitTest(layer.root, layer.offsetX or 0, layer.offsetY or 0, x, y)
      end
      if hit or layer.blocking then
        return hit, layer
      end
    elseif layer.blocking then
      return nil, layer
    end
  end
  return nil, nil
end

function Scene:modalLayers()
  local result = {}
  for _, layer in ipairs(self.layers) do
    if layer.kind == "modal" then
      result[#result + 1] = layer
    end
  end
  return result
end

return Scene
