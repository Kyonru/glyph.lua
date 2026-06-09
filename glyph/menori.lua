local moduleName = ...
local prefix = moduleName and moduleName:match("^(.*)%.menori$") or "glyph"

local Components = require(prefix .. ".components")
local Surface = require(prefix .. ".surface")

local Menori = {}
local Adapter = {}
Adapter.__index = Adapter

local adapters = setmetatable({}, { __mode = "k" })

local function copyTable(value)
  local result = {}
  for key, item in pairs(value or {}) do
    result[key] = item
  end
  return result
end

local function call(object, method, ...)
  local fn = object and object[method]
  if type(fn) == "function" then
    return fn(object, ...)
  end
  return nil
end

local function isCallable(value)
  if type(value) == "function" then
    return true
  end
  local meta = type(value) == "table" and getmetatable(value) or nil
  return meta and type(meta.__call) == "function"
end

local function tryRequire(name)
  local ok, value = pcall(require, name)
  if ok then
    return value
  end
  return nil
end

local function resolveFeel(opts)
  opts = opts or {}
  local feel = opts.feel or tryRequire(prefix .. ".vendor.feel") or tryRequire("feel")
  local feelMenori = opts.feelMenori
    or tryRequire(prefix .. ".vendor.feel.menori")
    or tryRequire("feel.menori")

  return feel, feelMenori
end

local function loveOf(adapter)
  return adapter.love or _G.love
end

local function graphicsOf(adapter)
  local loveModule = loveOf(adapter)
  return loveModule and loveModule.graphics or nil
end

local function graphicsSize(graphics)
  if graphics and graphics.getDimensions then
    return graphics.getDimensions()
  end
  return 800, 600
end

local function canvasSize(canvas)
  if not canvas then
    return nil, nil
  end
  local width = canvas.getWidth and canvas:getWidth() or nil
  local height = canvas.getHeight and canvas:getHeight() or nil
  if (not width or not height) and canvas.getDimensions then
    width, height = canvas:getDimensions()
  end
  return width, height
end

local function ensureCanvas(adapter, state, width, height)
  local graphics = graphicsOf(adapter)
  if not graphics or not graphics.newCanvas then
    return state.canvas
  end

  width = math.max(1, math.floor(width or 1))
  height = math.max(1, math.floor(height or 1))
  local currentWidth, currentHeight = canvasSize(state.canvas)
  if state.canvas and currentWidth == width and currentHeight == height then
    return state.canvas
  end

  local ok, canvas = pcall(graphics.newCanvas, width, height, state.canvasOptions)
  if ok then
    state.canvas = canvas
    state.width = width
    state.height = height
  end
  return state.canvas
end

local function pushAll(graphics)
  if not graphics or not graphics.push then
    return function() end
  end

  local ok = pcall(graphics.push, "all")
  if not ok then
    graphics.push()
  end

  return function()
    if graphics.pop then
      graphics.pop()
    end
  end
end

local function setColor(graphics, colorValue, opacity)
  if graphics and graphics.setColor and colorValue then
    graphics.setColor(colorValue[1] or 1, colorValue[2] or 1, colorValue[3] or 1, (colorValue[4] or 1) * (opacity or 1))
  end
end

local function clearGraphics(graphics, colorValue)
  if not graphics or not graphics.clear then
    return
  end

  colorValue = colorValue or { 0, 0, 0, 0 }
  local ok = pcall(graphics.clear, colorValue[1] or 0, colorValue[2] or 0, colorValue[3] or 0, colorValue[4] or 0, true, true)
  if not ok then
    pcall(graphics.clear, colorValue)
  end
end

local function resolveSpec(value)
  if type(value) == "function" then
    return value()
  end
  return value or {}
end

local function stripViewProps(props)
  local layoutProps = copyTable(props)
  layoutProps.scene = nil
  layoutProps.root = nil
  layoutProps.environment = nil
  layoutProps.renderStates = nil
  layoutProps.filter = nil
  layoutProps.update = nil
  layoutProps.overlay = nil
  layoutProps.clearColor = nil
  layoutProps.autoUpdate = nil
  layoutProps.canvasOptions = nil
  return layoutProps
end

local function findViewCanvas(node)
  if not node then
    return nil
  end

  local props = node.props or {}
  local state = props._menoriViewState
  if state and state.canvas then
    return state.canvas
  end

  for _, child in ipairs(node.children or {}) do
    local canvas = findViewCanvas(child)
    if canvas then
      return canvas
    end
  end
  return nil
end

local function vec(x, y, z)
  if type(x) == "table" then
    return { x = x.x or x[1] or 0, y = x.y or x[2] or 0, z = x.z or x[3] or 0 }
  end
  return { x = x or 0, y = y or 0, z = z or 0 }
end

local function add(a, b)
  return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

local function sub(a, b)
  return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end

local function mul(a, s)
  return { x = a.x * s, y = a.y * s, z = a.z * s }
end

local function dot(a, b)
  return a.x * b.x + a.y * b.y + a.z * b.z
end

local function cross(a, b)
  return {
    x = a.y * b.z - a.z * b.y,
    y = a.z * b.x - a.x * b.z,
    z = a.x * b.y - a.y * b.x,
  }
end

local function length(a)
  return math.sqrt(dot(a, a))
end

local function normalize(a, fallback)
  local len = length(a)
  if len <= 0.000001 then
    return fallback or { x = 0, y = 0, z = 1 }
  end
  return { x = a.x / len, y = a.y / len, z = a.z / len }
end

local function cameraEye(camera)
  return vec(camera and camera.eye or { x = 0, y = 0, z = 6 })
end

local function cameraUp(camera)
  return normalize(vec(camera and camera.up or { x = 0, y = 1, z = 0 }), { x = 0, y = 1, z = 0 })
end

local function viewportFor(adapter)
  local graphics = graphicsOf(adapter)
  local width, height = graphicsSize(graphics)
  return { 0, 0, width, height }
end

local function rayFor(entry, x, y)
  local camera = entry.camera or (entry.environment and entry.environment.camera) or entry.adapter.defaultCamera
  if not camera then
    return nil
  end
  if type(camera.screen_point_to_ray) == "function" then
    return camera:screen_point_to_ray(x, y, viewportFor(entry.adapter))
  end
  if type(camera.ray) == "function" then
    return camera:ray(x, y)
  end
  return nil
end

local function newVec3(menori, x, y, z)
  local vec3 = menori and menori.ml and menori.ml.vec3
  if isCallable(vec3) then
    return vec3(x or 0, y or 0, z or 0)
  end
  return { x = x or 0, y = y or 0, z = z or 0 }
end

local function setNodePosition(entry)
  if entry.node and type(entry.node.set_position) == "function" then
    entry.node:set_position(entry.x or 0, entry.y or 0, entry.z or 0)
  end
end

local function setNodeBillboard(entry)
  if not entry.node or entry.billboard == false or type(entry.node.set_rotation) ~= "function" then
    return
  end

  local menori = entry.adapter.menori
  local quat = menori and menori.ml and menori.ml.quat
  if not quat or type(quat.from_direction) ~= "function" then
    return
  end

  local camera = entry.camera or (entry.environment and entry.environment.camera) or entry.adapter.defaultCamera
  if not camera then
    return
  end

  local planePos = vec(entry.x, entry.y, entry.z)
  local direction = normalize(sub(cameraEye(camera), planePos), { x = 0, y = 0, z = 1 })
  if entry.billboard == "yaw" then
    direction.y = 0
    direction = normalize(direction, { x = 0, y = 0, z = 1 })
  end
  entry.node:set_rotation(quat.from_direction(newVec3(menori, direction.x, direction.y, direction.z), newVec3(menori, 0, 1, 0)))
end

local function localPointFor(entry, x, y)
  local ray = rayFor(entry, x, y)
  if not ray then
    return nil
  end

  local origin = vec(ray.origin)
  local direction = normalize(vec(ray.direction), { x = 0, y = 0, z = -1 })
  local planePos = vec(entry.x, entry.y, entry.z)
  local camera = entry.camera or (entry.environment and entry.environment.camera) or entry.adapter.defaultCamera
  local normal
  local up

  if entry.billboard == false then
    normal = { x = 0, y = 0, z = 1 }
    up = { x = 0, y = 1, z = 0 }
  else
    normal = normalize(sub(cameraEye(camera), planePos), { x = 0, y = 0, z = 1 })
    if entry.billboard == "yaw" then
      normal.y = 0
      normal = normalize(normal, { x = 0, y = 0, z = 1 })
    end
    up = cameraUp(camera)
  end

  local denom = dot(direction, normal)
  if math.abs(denom) <= 0.000001 then
    return nil
  end

  local t = dot(sub(planePos, origin), normal) / denom
  if t < 0 then
    return nil
  end

  local hit = add(origin, mul(direction, t))
  local right = normalize(cross(up, normal), { x = 1, y = 0, z = 0 })
  local planeUp = normalize(cross(normal, right), { x = 0, y = 1, z = 0 })
  local delta = sub(hit, planePos)
  local worldWidth = entry.worldWidth or 1
  local worldHeight = entry.worldHeight or 1
  local localWorldX = dot(delta, right) + worldWidth / 2
  local localWorldY = dot(delta, planeUp) + worldHeight / 2

  if localWorldX < 0 or localWorldY < 0 or localWorldX > worldWidth or localWorldY > worldHeight then
    return nil
  end

  return {
    x = (localWorldX / worldWidth) * entry.surface.width,
    y = (1 - localWorldY / worldHeight) * entry.surface.height,
    distance = t,
    entry = entry,
  }
end

function Adapter:updateSpec(spec, layer, dt)
  spec = resolveSpec(spec)
  if type(spec.update) == "function" then
    spec.update(spec, layer, dt, self)
  end
  if spec.autoUpdate ~= false and spec.scene and spec.root and spec.environment and type(spec.scene.update_nodes) == "function" then
    spec.scene:update_nodes(spec.root, spec.environment)
  end
end

function Adapter:drawView(state, props, x, y, width, height, loveModule)
  local spec = resolveSpec(props)
  local graphics = loveModule and loveModule.graphics or graphicsOf(self)
  if not graphics then
    return
  end

  local canvas = ensureCanvas(self, state, width, height)
  if not canvas then
    if spec.scene and spec.root and spec.environment and type(spec.scene.render_nodes) == "function" then
      spec.scene:render_nodes(spec.root, spec.environment, spec.renderStates, spec.filter)
    end
    return
  end

  self:renderBillboards()

  local restore = pushAll(graphics)
  if graphics.setCanvas then
    graphics.setCanvas(canvas)
  end
  clearGraphics(graphics, spec.clearColor)
  if spec.scene and spec.root and spec.environment and type(spec.scene.render_nodes) == "function" then
    local renderStates = copyTable(spec.renderStates or {})
    renderStates.clear = renderStates.clear == true
    spec.scene:render_nodes(spec.root, spec.environment, renderStates, spec.filter)
  end
  if graphics.setCanvas then
    graphics.setCanvas()
  end
  restore()

  if graphics.draw then
    local canvasWidth, canvasHeight = canvasSize(canvas)
    local scaleX = canvasWidth and canvasWidth > 0 and width / canvasWidth or 1
    local scaleY = canvasHeight and canvasHeight > 0 and height / canvasHeight or 1
    setColor(graphics, { 1, 1, 1, 1 })
    graphics.draw(canvas, x, y, 0, scaleX, scaleY)
  end
end

function Adapter:view(props, overlayChildren)
  props = props or {}
  local state = {
    canvasOptions = props.canvasOptions,
  }
  local layoutProps = stripViewProps(props)
  layoutProps.display = "stack"

  local viewNode = Components.box({
    position = "absolute",
    inset = 0,
    interactive = false,
    _menoriViewState = state,
    draw = function(_, x, y, width, height, loveModule)
      return self:drawView(state, props, x, y, width, height, loveModule)
    end,
  })

  local children = { viewNode }
  local overlay = overlayChildren or props.overlay
  if type(overlay) == "function" then
    overlay = overlay(self, props)
  end
  if overlay then
    if overlay.type then
      children[#children + 1] = overlay
    else
      for _, child in ipairs(overlay) do
        children[#children + 1] = child
      end
    end
  end

  return Components.stack(layoutProps, children)
end

function Adapter:layerComponent(spec)
  return function()
    local resolved = resolveSpec(spec)
    return self:view(resolved, resolved.overlay)
  end
end

function Adapter:layerOpts(spec, opts)
  local layerOpts = copyTable(opts or {})
  local previousOnUpdate = layerOpts.onUpdate
  layerOpts.onUpdate = function(layer, dt)
    self:updateSpec(spec, layer, dt)
    if previousOnUpdate then
      previousOnUpdate(layer, dt)
    end
  end
  return layerOpts
end

function Adapter:pushScene(method, id, spec, opts)
  return self.ui.scene[method](id, self:layerComponent(spec), self:layerOpts(spec, opts))
end

function Adapter:replaceScene(id, spec, opts)
  opts = copyTable(opts or {})
  local current = self.ui.scene.current and self.ui.scene.current() or nil
  if opts.transition == nil then
    opts.transition = self.transitions.crossfade({
      previousCanvas = current and findViewCanvas(current.root) or nil,
      duration = opts.duration or 0.32,
    })
  end
  return self:pushScene("set", id, spec, opts)
end

function Adapter:openLoading(id, opts)
  opts = opts or {}
  local state = {
    progress = opts.progress or 0,
    message = opts.message or "Loading",
    detail = opts.detail,
  }
  local adapter = self

  local function loadingComponent()
    local backdrop = opts.backdropSpec and adapter:view(opts.backdropSpec) or nil
    local panel = Components.panel({
      position = "absolute",
      width = opts.width or 360,
      height = opts.height or 148,
      left = opts.left,
      top = opts.top,
      right = opts.right or 32,
      bottom = opts.bottom or 32,
      padding = 16,
      gap = 10,
      style = opts.style or {
        background = { 0.03, 0.035, 0.045, 0.88 },
        borderColor = { 0.6, 0.75, 1, 0.42 },
        borderWidth = 1,
        radius = 8,
      },
    }, {
      Components.text(state.message or "Loading", { textStyle = opts.titleTextStyle or "h2" }),
      Components.meter({
        width = "100%",
        height = 12,
        value = state.progress or 0,
        max = 1,
        style = opts.meterStyle,
      }),
      Components.text(state.detail or string.format("%d%%", math.floor((state.progress or 0) * 100 + 0.5)), {
        textStyle = opts.detailTextStyle or "caption",
      }),
    })

    local children = {}
    if backdrop then
      children[#children + 1] = backdrop
    end
    children[#children + 1] = panel
    return Components.stack({ width = "100%", height = "100%" }, children)
  end

  local layer = self.ui.scene.push(id, loadingComponent, {
    kind = opts.kind or "overlay",
    blocking = opts.blocking ~= false,
    input = opts.input ~= false,
    transition = opts.transition or self.transitions.loadingFade(opts.transitionOpts),
    zIndex = opts.zIndex or 900,
  })

  return {
    layer = layer,
    state = state,
    update = function(_, nextState)
      for key, value in pairs(nextState or {}) do
        state[key] = value
      end
      self.ui.runtime:markDirty()
    end,
    close = function()
      return self.ui.scene.close(id)
    end,
  }
end

function Adapter:createBillboardNode(entry)
  local menori = self.menori
  assert(isCallable(menori.Plane), "menori.Plane is required for Glyph billboards")
  assert(isCallable(menori.Material), "menori.Material is required for Glyph billboards")
  assert(isCallable(menori.ModelNode), "menori.ModelNode is required for Glyph billboards")

  local material = entry.material or menori.Material({ name = entry.name or "glyph.billboard" })
  local function configureBillboardMaterial(target)
    if type(target.set) == "function" then
      target:set("baseColor", entry.baseColor or { 1, 1, 1, 1 })
      target:set("alphaCutoff", entry.alphaCutoff or 0)
      target:set("opaque", false)
      target:set("emissiveFactor", entry.emissiveFactor or { 0, 0, 0 })
    end
    target.main_texture = entry.surface.canvas
    target.alpha_mode = entry.alphaMode or "BLEND"
    target.mesh_cull_mode = entry.meshCullMode or "none"
    target._needs_update = true
  end
  configureBillboardMaterial(material)

  local mesh = entry.mesh or menori.Plane(entry.worldWidth or 1, entry.worldHeight or 1)
  local node = entry.node or menori.ModelNode(mesh, material)
  if node.material then
    configureBillboardMaterial(node.material)
  end
  node.name = entry.name or node.name or "glyph.billboard"
  entry.material = node.material or material
  entry.mesh = mesh
  entry.node = node
  setNodePosition(entry)
  setNodeBillboard(entry)

  if entry.parent and type(entry.parent.attach) == "function" and not entry.attached then
    entry.parent:attach(node)
    entry.attached = true
  end

  return node
end

function Adapter:billboard(opts)
  opts = opts or {}
  local surface = Surface.new({
    width = opts.width or 256,
    height = opts.height or 128,
    component = opts.component,
    theme = opts.theme,
    love = opts.love or self.love,
    clearColor = opts.clearColor,
    canvasOptions = opts.canvasOptions,
  })
  surface:render()

  local entry = {
    adapter = self,
    surface = surface,
    name = opts.name,
    material = opts.material,
    mesh = opts.mesh,
    node = opts.node,
    parent = opts.parent,
    camera = opts.camera,
    environment = opts.environment or self.defaultEnvironment,
    x = opts.x or 0,
    y = opts.y or 0,
    z = opts.z or 0,
    worldWidth = opts.worldWidth or 1,
    worldHeight = opts.worldHeight or ((opts.worldWidth or 1) * (surface.height / math.max(1, surface.width))),
    billboard = opts.billboard == nil and "full" or opts.billboard,
    interactive = opts.interactive ~= false,
    inputPriority = opts.inputPriority or "behind-ui",
    alphaMode = opts.alphaMode,
    meshCullMode = opts.meshCullMode,
    baseColor = opts.baseColor,
    alphaCutoff = opts.alphaCutoff,
    emissiveFactor = opts.emissiveFactor,
  }
  entry.node = self:createBillboardNode(entry)

  self.billboards[#self.billboards + 1] = entry

  function entry:update(dt)
    self.surface:update(dt or 0)
    self.surface:render()
    if self.material then
      self.material.main_texture = self.surface.canvas
    end
    setNodePosition(self)
    setNodeBillboard(self)
    return self
  end

  function entry:destroy()
    self.destroyed = true
    self.surface:destroy()
    return self
  end

  return entry
end

function Adapter:renderBillboards()
  for index = #self.billboards, 1, -1 do
    local entry = self.billboards[index]
    if entry.destroyed then
      table.remove(self.billboards, index)
    else
      entry:update(self.lastDt or 0)
    end
  end
end

function Adapter:update(dt)
  self.lastDt = dt or 0
  if self.updateFeel ~= false and self.feel and type(self.feel.update) == "function" and self.feel ~= self.glyphFeel then
    self.feel.update(dt or 0)
  end
  self:renderBillboards()
  return self
end

function Adapter:pickBillboard(x, y, opts)
  opts = opts or {}
  local best = nil
  for _, entry in ipairs(self.billboards) do
    if not entry.destroyed and entry.interactive ~= false then
      local priority = entry.inputPriority or "behind-ui"
      local include = opts.priority == "active"
        or (opts.priority == "always" and priority == "always")
        or (opts.priority == "behind-ui" and priority ~= "always")
        or opts.priority == nil
      if include then
        local hit = localPointFor(entry, x, y)
        if hit and (not best or hit.distance < best.distance) then
          best = hit
        end
      end
    end
  end
  return best
end

function Adapter:routePointer(kind, x, y, button, opts)
  opts = opts or {}
  if opts.priority == "active" and not self.activeBillboard then
    return false
  end

  if kind == "mousemoved" then
    local hit = self.activeBillboard and localPointFor(self.activeBillboard, x, y) or self:pickBillboard(x, y, opts)
    if hit then
      self.hoverBillboard = hit.entry
      hit.entry.surface:mousemoved(hit.x, hit.y)
      return true
    elseif opts.priority ~= "active" and self.hoverBillboard then
      self.hoverBillboard.surface:mousemoved(-1, -1)
      self.hoverBillboard = nil
    end
    return false
  elseif kind == "mousepressed" then
    local hit = self:pickBillboard(x, y, opts)
    if hit then
      self.activeBillboard = hit.entry
      self.focusBillboard = hit.entry
      hit.entry.surface:mousepressed(hit.x, hit.y, button or 1)
      return true
    end
    return false
  elseif kind == "mousereleased" then
    local entry = self.activeBillboard
    if entry then
      local hit = localPointFor(entry, x, y) or { x = -1, y = -1, entry = entry }
      entry.surface:mousereleased(hit.x, hit.y, button or 1)
      self.activeBillboard = nil
      return true
    end
    local hit = self:pickBillboard(x, y, opts)
    if hit then
      hit.entry.surface:mousereleased(hit.x, hit.y, button or 1)
      return true
    end
  end
  return false
end

function Adapter:routeKey(kind, key)
  local entry = self.focusBillboard
  if not entry or entry.destroyed then
    return false
  end
  if kind == "keypressed" then
    entry.surface:keypressed(key)
  else
    entry.surface:keyreleased(key)
  end
  return true
end

function Adapter:feelAdapter(opts)
  if not self.feelMenori or type(self.feelMenori.new) ~= "function" then
    return nil
  end
  return self.feelMenori.new(self.menori, opts or { environment = self.defaultEnvironment })
end

function Adapter:destroy()
  if self.unregisterUpdate then
    self.unregisterUpdate()
    self.unregisterUpdate = nil
  end
  adapters[self] = nil
  for _, entry in ipairs(self.billboards) do
    if entry.destroy then
      entry:destroy()
    end
  end
  self.billboards = {}
end

local function makeTransitions(rootUi)
  return {
    fade = function(opts)
      return rootUi.transitions.fade(opts)
    end,
    crossfade = function(opts)
      opts = opts or {}
      local transition = {
        name = "menori.crossfade",
        duration = opts.duration or 0.32,
        exitDuration = opts.exitDuration or opts.duration or 0.32,
      }
      transition.draw = function(ctx)
        local graphics = ctx.love and ctx.love.graphics
        if not graphics then
          return ctx.drawLayer()
        end
        local previous = opts.previousCanvas or opts.previous
        if previous and graphics.draw then
          setColor(graphics, { 1, 1, 1, 1 }, 1 - ctx.progress)
          graphics.draw(previous, ctx.bounds.x, ctx.bounds.y)
        end
        setColor(graphics, { 1, 1, 1, 1 }, ctx.phase == "exit" and (1 - ctx.progress) or ctx.progress)
        ctx.drawLayer()
      end
      return transition
    end,
    loadingFade = function(opts)
      opts = opts or {}
      local transition = rootUi.transitions.fade({ duration = opts.duration or 0.22 })
      transition.name = "menori.loadingFade"
      return transition
    end,
  }
end

function Menori.new(rootUi, opts)
  opts = opts or {}
  assert(type(opts.menori) == "table", "ui.menori.new requires opts.menori")

  local feel, feelMenori = resolveFeel(opts)
  local adapter = setmetatable({
    ui = rootUi,
    menori = opts.menori,
    love = opts.love or _G.love,
    feel = feel,
    feelMenori = feelMenori,
    glyphFeel = tryRequire(prefix .. ".vendor.feel"),
    updateFeel = opts.updateFeel,
    defaultCamera = opts.camera or (opts.environment and opts.environment.camera),
    defaultEnvironment = opts.environment,
    billboards = {},
    capabilities = {
      feelMenori = feelMenori ~= nil,
    },
  }, Adapter)

  adapter.transitions = makeTransitions(rootUi)
  adapter.scene = {
    set = function(id, spec, sceneOpts)
      return adapter:pushScene("set", id, spec, sceneOpts)
    end,
    push = function(id, spec, sceneOpts)
      return adapter:pushScene("push", id, spec, sceneOpts)
    end,
    replace = function(id, spec, sceneOpts)
      return adapter:replaceScene(id, spec, sceneOpts)
    end,
  }
  adapter.loading = {
    open = function(id, loadingOpts)
      return adapter:openLoading(id, loadingOpts)
    end,
  }

  adapters[adapter] = true
  if rootUi and type(rootUi.on) == "function" then
    adapter.unregisterUpdate = rootUi.on("beforeUpdate", function(dt)
      adapter:update(dt or 0)
    end)
  end
  return adapter
end

function Menori.routePointer(kind, x, y, button, opts)
  for adapter in pairs(adapters) do
    if adapter:routePointer(kind, x, y, button, opts) then
      return true
    end
  end
  return false
end

function Menori.routeKey(kind, key, opts)
  opts = opts or {}
  for adapter in pairs(adapters) do
    local shouldRoute = opts.priority == "always" or not (adapter.ui and adapter.ui.runtime and adapter.ui.runtime.focusNode)
    if shouldRoute and adapter:routeKey(kind, key) then
      return true
    end
  end
  return false
end

return Menori
