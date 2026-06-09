package.path = "./?.lua;./?/init.lua;" .. package.path

local Menori = require("glyph.menori")
local Runtime = require("glyph.runtime")

local function fakeLove()
  local calls = {}
  local graphics = {}
  local font = {
    getWidth = function(_, text)
      return #(tostring(text or "")) * 8
    end,
    getHeight = function()
      return 16
    end,
  }

  function graphics.newCanvas(width, height)
    calls[#calls + 1] = { "newCanvas", width, height }
    return {
      width = width,
      height = height,
      getWidth = function(self)
        return self.width
      end,
      getHeight = function(self)
        return self.height
      end,
      getDimensions = function(self)
        return self.width, self.height
      end,
    }
  end
  function graphics.setCanvas(canvas)
    calls[#calls + 1] = { "setCanvas", canvas }
  end
  function graphics.getDimensions()
    return 320, 180
  end
  function graphics.clear() end
  function graphics.push() end
  function graphics.pop() end
  function graphics.translate() end
  function graphics.scale() end
  function graphics.rotate() end
  function graphics.setColor() end
  function graphics.getColor()
    return 1, 1, 1, 1
  end
  function graphics.rectangle() end
  function graphics.print() end
  function graphics.printf() end
  function graphics.draw(...)
    calls[#calls + 1] = { "draw", ... }
  end
  function graphics.setShader() end
  function graphics.getShader()
    return nil
  end
  function graphics.getLineWidth()
    return 1
  end
  function graphics.setLineWidth() end
  function graphics.getFont()
    return font
  end
  function graphics.setFont(nextFont)
    font = nextFont or font
  end

  return {
    calls = calls,
    graphics = graphics,
  }
end

local function fakeMenori()
  local menori = {}
  local function callable(constructor)
    return setmetatable({}, {
      __call = function(_, ...)
        return constructor(...)
      end,
    })
  end

  local vec3Meta = {}
  vec3Meta.__index = vec3Meta

  function vec3Meta:clone()
    return setmetatable({ x = self.x, y = self.y, z = self.z }, vec3Meta)
  end

  function vec3Meta:normalize()
    return self
  end

  menori.ml = {
    vec3 = callable(function(x, y, z)
      return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, vec3Meta)
    end),
    quat = {
      from_direction = function(direction, up)
        if type(direction.clone) ~= "function" then
          error("direction must be a Menori-style vec3")
        end
        if type(up.clone) ~= "function" then
          error("up must be a Menori-style vec3")
        end
        return { direction = direction, up = up }
      end,
    },
  }

  menori.Plane = callable(function(width, height)
    return { kind = "plane", width = width, height = height }
  end)

  menori.Material = callable(function(opts)
    return {
      name = opts and opts.name or "material",
      clone = function(self)
        local copy = {}
        for key, value in pairs(self) do
          copy[key] = value
        end
        return copy
      end,
      set = function(self, key, value)
        self[key] = value
      end,
    }
  end)

  menori.ModelNode = callable(function(mesh, material)
    return {
      mesh = mesh,
      material = material and material:clone() or material,
      set_position = function(self, x, y, z)
        self.position = { x = x, y = y, z = z }
      end,
      set_rotation = function(self, rotation)
        self.rotation = rotation
      end,
      set_scale = function(self, sx, sy, sz)
        self.scale = { sx, sy, sz }
      end,
    }
  end)

  return menori
end

local function fakeCamera()
  return {
    eye = { x = 0, y = 0, z = 5 },
    up = { x = 0, y = 1, z = 0 },
    screen_point_to_ray = function()
      return {
        origin = { x = 0, y = 0, z = 5 },
        direction = { x = 0, y = 0, z = -1 },
      }
    end,
  }
end

local function rootUi()
  local layers = {}
  local ui = {
    runtime = {
      markDirty = function() end,
    },
    transitions = require("glyph.transitions"),
  }
  ui.scene = {
    set = function(id, component, opts)
      layers = { { id = id, component = component, opts = opts, root = nil } }
      return layers[1]
    end,
    push = function(id, component, opts)
      layers[#layers + 1] = { id = id, component = component, opts = opts, root = nil }
      return layers[#layers]
    end,
    close = function(id)
      for _, layer in ipairs(layers) do
        if layer.id == id then
          layer.closed = true
          return layer
        end
      end
      return nil
    end,
    current = function()
      return layers[#layers]
    end,
    layers = function()
      return layers
    end,
  }
  ui.on = function()
    return function() end
  end
  ui._layers = layers
  return ui
end

describe("menori adapter", function()
  it("constructs without requiring Menori globally", function()
    local adapter = Menori.new(rootUi(), {
      menori = fakeMenori(),
      love = fakeLove(),
    })

    assert.are.equal("boolean", type(adapter.capabilities.feelMenori))
    assert.are.equal("table", type(adapter.scene))
    adapter:destroy()
  end)

  it("renders a Menori view through scene:render_nodes", function()
    local love = fakeLove()
    local adapter = Menori.new(rootUi(), {
      menori = fakeMenori(),
      love = love,
    })
    local renderArgs
    local scene = {
      render_nodes = function(_, root, environment, renderStates, filter)
        renderArgs = { root = root, environment = environment, renderStates = renderStates, filter = filter }
      end,
    }
    local root = {}
    local environment = {}
    local filter = function() end
    local runtime = Runtime.new()
    runtime:setLove(love)

    runtime:build(function()
      return adapter:view({
        width = 120,
        height = 80,
        scene = scene,
        root = root,
        environment = environment,
        filter = filter,
      })
    end)
    runtime:layoutRoot(runtime.root, 120, 80)
    runtime:draw(runtime.root)

    assert.are.equal(root, renderArgs.root)
    assert.are.equal(environment, renderArgs.environment)
    assert.are.equal(filter, renderArgs.filter)
    assert.are.equal(false, renderArgs.renderStates.clear)
    adapter:destroy()
  end)

  it("scene wrappers call Menori updates and preserve layer options", function()
    local ui = rootUi()
    local adapter = Menori.new(ui, {
      menori = fakeMenori(),
      love = fakeLove(),
    })
    local updated = 0
    local sceneUpdated = 0
    local spec = {
      scene = {
        update_nodes = function()
          sceneUpdated = sceneUpdated + 1
        end,
      },
      root = {},
      environment = {},
      update = function()
        updated = updated + 1
      end,
    }

    local layer = adapter.scene.push("world", spec, { kind = "scene", zIndex = 12 })
    layer.opts.onUpdate(layer, 0.1)

    assert.are.equal("world", layer.id)
    assert.are.equal("scene", layer.opts.kind)
    assert.are.equal(12, layer.opts.zIndex)
    assert.are.equal(1, updated)
    assert.are.equal(1, sceneUpdated)
    adapter:destroy()
  end)

  it("loading handles update state and close their layer", function()
    local ui = rootUi()
    local adapter = Menori.new(ui, {
      menori = fakeMenori(),
      love = fakeLove(),
    })

    local handle = adapter.loading.open("load", { progress = 0.1 })
    handle:update({ progress = 0.6, message = "Streaming", detail = "terrain" })
    handle:close()

    assert.are.equal(0.6, handle.state.progress)
    assert.are.equal("Streaming", handle.state.message)
    assert.are.equal("terrain", handle.state.detail)
    assert.is_true(handle.layer.closed)
    adapter:destroy()
  end)

  it("creates billboards from Glyph surfaces and refreshes their material texture", function()
    local love = fakeLove()
    local environment = { camera = fakeCamera() }
    local adapter = Menori.new(rootUi(), {
      menori = fakeMenori(),
      love = love,
      environment = environment,
    })
    local parent = {
      attached = {},
      attach = function(self, node)
        self.attached[#self.attached + 1] = node
      end,
    }

    local billboard = adapter:billboard({
      width = 128,
      height = 64,
      worldWidth = 2,
      component = function(ui)
        return ui.text("marker")
      end,
      parent = parent,
      environment = environment,
    })
    local firstCanvas = billboard.surface.canvas
    billboard:update(0.016)

    assert.are.equal("plane", billboard.mesh.kind)
    assert.are.equal(billboard.node, parent.attached[1])
    assert.are.equal(firstCanvas, billboard.material.main_texture)
    assert.are.same({ x = 0, y = 0, z = 0 }, billboard.node.position)
    adapter:destroy()
  end)

  it("routes pointer input into billboard-local surface coordinates", function()
    local clicks = 0
    local environment = { camera = fakeCamera() }
    local adapter = Menori.new(rootUi(), {
      menori = fakeMenori(),
      love = fakeLove(),
      environment = environment,
    })

    adapter:billboard({
      width = 200,
      height = 100,
      worldWidth = 2,
      worldHeight = 1,
      environment = environment,
      component = function(ui)
        return ui.button({
          label = "World",
          width = 200,
          height = 100,
          onClick = function()
            clicks = clicks + 1
          end,
        })
      end,
    })

    assert.is_true(adapter:routePointer("mousepressed", 160, 90, 1, { priority = "behind-ui" }))
    assert.is_true(adapter:routePointer("mousereleased", 160, 90, 1, { priority = "active" }))
    assert.are.equal(1, clicks)
    adapter:destroy()
  end)

  it("honors screen UI priority for billboard input", function()
    local environment = { camera = fakeCamera() }
    local adapter = Menori.new(rootUi(), {
      menori = fakeMenori(),
      love = fakeLove(),
      environment = environment,
    })

    adapter:billboard({
      width = 200,
      height = 100,
      worldWidth = 2,
      worldHeight = 1,
      environment = environment,
      component = function(ui)
        return ui.box({ width = 200, height = 100 })
      end,
    })

    assert.is_false(adapter:routePointer("mousepressed", 0, 0, 1, { priority = "always" }))
    assert.is_true(adapter:routePointer("mousepressed", 0, 0, 1, { priority = "behind-ui" }))
    adapter:destroy()

    local alwaysAdapter = Menori.new(rootUi(), {
      menori = fakeMenori(),
      love = fakeLove(),
      environment = environment,
    })
    alwaysAdapter:billboard({
      width = 200,
      height = 100,
      worldWidth = 2,
      worldHeight = 1,
      environment = environment,
      inputPriority = "always",
      component = function(ui)
        return ui.box({ width = 200, height = 100 })
      end,
    })

    assert.is_true(alwaysAdapter:routePointer("mousepressed", 0, 0, 1, { priority = "always" }))
    alwaysAdapter:destroy()
  end)
end)
