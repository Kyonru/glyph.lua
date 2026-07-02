local ui = require("glyph")

local colors = {
	bg = { 0.016, 0.02, 0.03, 1 },
	panel = { 0.025, 0.032, 0.046, 0.9 },
	panelDeep = { 0.012, 0.016, 0.026, 0.94 },
	text = { 0.94, 0.97, 1, 1 },
	muted = { 0.56, 0.64, 0.74, 1 },
	cyan = { 0.1, 0.8, 1, 1 },
	blue = { 0.18, 0.45, 1, 1 },
	gold = { 1, 0.72, 0.22, 1 },
	violet = { 0.72, 0.46, 1, 1 },
	coral = { 1, 0.32, 0.42, 1 },
	green = { 0.22, 0.96, 0.66, 1 },
}

local sceneDefs = {
	{
		id = "dock",
		title = "Aether Dock",
		subtitle = "command-deck scene with live world billboards",
		route = "north gate",
		clear = { 0.014, 0.02, 0.034, 1 },
		accent = colors.cyan,
		accent2 = colors.violet,
		core = { 0.08, 0.78, 1, 1 },
		pylon = { 0.6, 0.38, 1, 1 },
		platform = { 0.08, 0.095, 0.13, 1 },
		tile = { 0.1, 0.18, 0.27, 1 },
		consoleText = "Live dock controls rendered by Glyph into a Menori plane. The buttons below are clickable world-space UI.",
		relayText = "Relay link accepts pointer input only when screen HUD panels are not covering the cursor.",
		cameraEye = { 0.75, 1.72, 5.7 },
		cameraCenter = { 0, -0.12, 0.2 },
		console = { x = 0, y = 1.25, z = -0.8, worldWidth = 1.95, worldHeight = 1.08 },
		relay = { x = 2.24, y = 0.72, z = 0.28, worldWidth = 1.18, worldHeight = 0.72 },
	},
	{
		id = "forge",
		title = "Ember Forge",
		subtitle = "different Menori root, camera, materials, and layout",
		route = "ember lift",
		clear = { 0.036, 0.022, 0.022, 1 },
		accent = colors.gold,
		accent2 = colors.coral,
		core = { 1, 0.5, 0.18, 1 },
		pylon = { 1, 0.28, 0.35, 1 },
		platform = { 0.13, 0.08, 0.065, 1 },
		tile = { 0.3, 0.13, 0.07, 1 },
		consoleText = "Forge scene uses a different Menori root, camera, and geometry while the same Glyph overlay API keeps working.",
		relayText = "This smaller billboard is a separate scoped Glyph runtime with its own focus and feedback state.",
		cameraEye = { -0.9, 1.95, 6.25 },
		cameraCenter = { 0.18, -0.18, 0 },
		console = { x = -1.05, y = 1.25, z = -0.98, worldWidth = 1.95, worldHeight = 1.08 },
		relay = { x = 2.34, y = 0.86, z = -0.2, worldWidth = 1.18, worldHeight = 0.72 },
	},
	{
		id = "busy",
		title = "Signal Swarm",
		subtitle = "busy scene built in chunks behind a loading overlay",
		route = "swarm sector",
		clear = { 0.012, 0.018, 0.028, 1 },
		accent = colors.green,
		accent2 = colors.blue,
		core = { 0.22, 0.96, 0.66, 1 },
		pylon = { 0.18, 0.45, 1, 1 },
		platform = { 0.045, 0.065, 0.08, 1 },
		tile = { 0.09, 0.18, 0.16, 1 },
		consoleText = "Signal Swarm was built in chunks behind the loading overlay, then handed off to the Menori scene layer.",
		relayText = "Busy scene billboard stays interactive while hundreds of Menori nodes animate behind it.",
		cameraEye = { 0.45, 2.35, 7.2 },
		cameraCenter = { 0, -0.12, 0.25 },
		console = { x = -0.55, y = 1.55, z = -1.18, worldWidth = 2.0, worldHeight = 1.1 },
		relay = { x = 2.52, y = 0.94, z = 0.62, worldWidth = 1.2, worldHeight = 0.74 },
	},
}

local okMenori = false
local menori = nil
local menoriLoadError = nil
local adapter = nil
local activeContext = nil
local activeDef = sceneDefs[1]
local scene = nil
local rootNode = nil
local camera = nil
local environment = nil
local nodes = {}
local billboards = {}
local menorifx = nil
local coreTarget = nil
local loading = nil
local buildJob = nil
local loadingTimer = 0
local time = 0
local docGifMode = os.getenv("GLYPH_MENORI_DOC_GIF") == "1"
local docGifTime = 0
local docGifActions = {}

local station = {
	energy = 0.72,
	shield = 0.84,
	traffic = 0.42,
	pulse = 0,
	beaconArmed = false,
	route = "north gate",
	selection = "screen HUD",
	nodeCount = 0,
}
local logs = {}
local worldSpec
local sceneSpec

local function log(message)
	logs[#logs + 1] = message
	while #logs > 5 do
		table.remove(logs, 1)
	end
end

local function loadMenori()
	local ok, module = pcall(require, "vendor.menori")
	if ok then
		menoriLoadError = nil
		return true, module
	end

	menoriLoadError = module
	ok, module = pcall(require, "menori")
	if ok then
		menoriLoadError = nil
		return true, module
	end

	menoriLoadError = menoriLoadError or module
	return false, module
end

local function markDirty()
	if ui.runtime and ui.runtime.markDirty then
		ui.runtime:markDirty()
	end
end

local function colorWithAlpha(color, alpha)
	return { color[1], color[2], color[3], alpha == nil and (color[4] or 1) or alpha }
end

local function tint(color, amount)
	return {
		math.min(1, color[1] * amount),
		math.min(1, color[2] * amount),
		math.min(1, color[3] * amount),
		color[4] or 1,
	}
end

local function percent(value)
	return string.format("%d%%", math.floor(value * 100 + 0.5))
end

local function material(name, color)
	local mat = menori.Material({ name = name })
	if mat.set then
		mat:set("baseColor", color)
	end
	mat.alpha_mode = (color[4] and color[4] < 1) and "BLEND" or "OPAQUE"
	return mat
end

local function modelNode(ctx, name, mesh, color, opts)
	opts = opts or {}
	local node = menori.ModelNode(mesh, material(name .. ".material", color))
	node.name = name
	node.base = {
		x = opts.x or 0,
		y = opts.y or 0,
		z = opts.z or 0,
	}
	node.spin = opts.spin or 0
	node.wave = opts.wave or 0
	node.phase = opts.phase or 0
	node.drift = opts.drift or 0
	node:set_position(node.base.x, node.base.y, node.base.z)
	if opts.scale then
		node:set_scale(opts.scale[1], opts.scale[2], opts.scale[3])
	end
	if opts.rotation then
		node:set_rotation(menori.ml.quat.from_euler_angles(opts.rotation[1], opts.rotation[2], opts.rotation[3]))
	end
	ctx.root:attach(node)
	ctx.nodes[name] = node
	ctx.nodeCount = ctx.nodeCount + 1
	if node.spin ~= 0 or node.wave ~= 0 or node.drift ~= 0 then
		ctx.animated[#ctx.animated + 1] = node
	end
	return node
end

local function createContext(def)
	local width, height = love.graphics.getDimensions()
	local ctx = {
		def = def,
		scene = menori.Scene(),
		root = menori.Node("glyph-menori-" .. def.id),
		nodes = {},
		animated = {},
		nodeCount = 0,
		busyBuilt = 0,
		meshes = {},
	}
	ctx.camera = menori.PerspectiveCamera(58, width / height, 0.2, 256)
	ctx.environment = menori.Environment(ctx.camera)
	if ctx.environment.set then
		ctx.environment:set("ambientColor", { 0.42, 0.47, 0.6, 1 })
	end
	ctx.camera.eye:set(def.cameraEye[1], def.cameraEye[2], def.cameraEye[3])
	ctx.camera.center:set(def.cameraCenter[1], def.cameraCenter[2], def.cameraCenter[3])
	ctx.camera.up:set(0, 1, 0)
	ctx.camera:update_view_matrix()
	return ctx
end

local function ensureAdapter(ctx)
	if adapter then
		adapter.defaultEnvironment = ctx.environment
		adapter.defaultCamera = ctx.camera
		adapter.love = love
		return
	end

	adapter = ui.menori.new({
		menori = menori,
		love = love,
		environment = ctx.environment,
		camera = ctx.camera,
	})
end

local function clearBillboards()
	for _, billboard in ipairs(billboards) do
		if billboard.destroy then
			billboard:destroy()
		end
	end
	billboards = {}
	if adapter then
		adapter.hoverBillboard = nil
		adapter.focusBillboard = nil
		adapter.activeBillboard = nil
	end
end

local function setupFeelTargets(ctx)
	menorifx = nil
	coreTarget = nil
	if not adapter or not adapter.capabilities.feelMenori then
		return
	end
	menorifx = adapter:feelAdapter({ environment = ctx.environment })
	if menorifx and type(menorifx.node) == "function" and ctx.nodes.core then
		local base = ctx.nodes.core.base or { x = 0, y = 0, z = 0 }
		coreTarget = menorifx:node("core", ctx.nodes.core, {
			values = { x = base.x, y = base.y, z = base.z, rx = 0, ry = 0, rz = 0, scale = 1 },
		})
	end
end

local buttonFeedback = {
	press = { kind = "animate", to = { scale = 0.97 }, duration = 0.05 },
	release = { kind = "animate", to = { scale = 1 }, duration = 0.14, ease = "backout" },
}

local function buttonStyle(accent)
	return {
		background = { accent[1] * 0.18, accent[2] * 0.18, accent[3] * 0.18, 0.78 },
		color = colors.text,
		borderColor = colorWithAlpha(accent, 0.58),
		borderWidth = 1,
		radius = 6,
		hover = {
			background = { accent[1] * 0.26, accent[2] * 0.26, accent[3] * 0.26, 0.92 },
			borderColor = colorWithAlpha(accent, 0.9),
		},
		pressed = {
			background = { accent[1] * 0.34, accent[2] * 0.34, accent[3] * 0.34, 1 },
		},
	}
end

local function panelStyle(accent, alpha)
	return {
		background = { 0.02, 0.026, 0.04, alpha or 0.9 },
		borderColor = colorWithAlpha(accent, 0.48),
		borderWidth = 1,
		radius = 8,
	}
end

local function meterLine(label, value, accent)
	return ui.column({ width = "100%", gap = 5 }, {
		ui.row({ width = "100%", gap = 8, align = "center" }, {
			ui.text(label, { textStyle = "caption", width = 92, style = { color = colors.muted } }),
			ui.text(percent(value), { textStyle = "caption", width = 44, style = { color = colors.text } }),
		}),
		ui.meter({
			value = value,
			max = 1,
			width = "100%",
			height = 8,
			trackStyle = {
				background = { 0, 0, 0, 0.35 },
				borderColor = { 1, 1, 1, 0.08 },
				borderWidth = 1,
			},
			fillStyle = { background = colorWithAlpha(accent, 0.95) },
			shape = { kind = "rect", radius = 4 },
		}),
	})
end

local function pulseCore(source)
	station.pulse = 1
	station.energy = math.min(1, station.energy + 0.08)
	log((source or "command") .. ": core pulse")

	if menorifx and adapter and adapter.feel and type(menorifx.handlers) == "function" then
		adapter.feel.play({
			{
				kind = "emit",
				event = "menori.node.scalePunch",
				payload = { name = "core", amount = 0.22, duration = 0.06 },
			},
			{ kind = "emit", event = "menori.camera.shake", payload = { amount = 0.045, duration = 0.12 } },
		}, nil, menorifx:handlers({ markDirty = markDirty }))
	end
end

local function toggleBeacon()
	station.beaconArmed = not station.beaconArmed
	station.traffic = station.beaconArmed and 0.88 or 0.38
	log(station.beaconArmed and "world beacon armed" or "world beacon parked")
end

local function buildDockScene(ctx)
	local def = ctx.def
	modelNode(ctx, "platform", menori.Box(7.8, 0.22, 4.8), def.platform, { y = -0.92, z = 0.05 })
	modelNode(ctx, "bridge", menori.Box(1.0, 0.16, 3.8), def.tile, { y = -0.72, z = -0.2 })
	modelNode(ctx, "core", menori.Box(0.82, 0.82, 0.82), def.core, { y = -0.08, spin = 0.7 })
	modelNode(
		ctx,
		"innerCore",
		menori.Sphere(0.35, 14, 18),
		colorWithAlpha(def.accent, 0.82),
		{ y = -0.08, spin = -0.5 }
	)
	modelNode(
		ctx,
		"leftPylon",
		menori.Box(0.44, 1.56, 0.44),
		def.pylon,
		{ x = -2.0, y = -0.18, z = -0.55, spin = 0.28 }
	)
	modelNode(
		ctx,
		"rightPylon",
		menori.Box(0.5, 1.24, 0.5),
		def.accent2,
		{ x = 2.0, y = -0.28, z = 0.66, spin = -0.24 }
	)

	for index = 1, 8 do
		local column = (index - 4.5) * 0.48
		modelNode(
			ctx,
			"tile" .. index,
			menori.Box(0.34, 0.08, 0.74),
			index % 2 == 0 and def.tile or tint(def.tile, 1.25),
			{
				x = column,
				y = -0.56,
				z = 1.42,
				wave = 0.04,
				phase = index * 0.52,
			}
		)
	end

	local beaconPositions = {
		{ -3.0, -0.38, -1.72 },
		{ 3.0, -0.38, -1.72 },
		{ -3.0, -0.38, 1.92 },
		{ 3.0, -0.38, 1.92 },
	}
	for index, pos in ipairs(beaconPositions) do
		modelNode(ctx, "beacon" .. index, menori.Sphere(0.16, 8, 12), index % 2 == 0 and def.accent or def.accent2, {
			x = pos[1],
			y = pos[2],
			z = pos[3],
			wave = 0.06,
			phase = index * 1.1,
		})
	end
end

local function buildForgeScene(ctx)
	local def = ctx.def
	modelNode(ctx, "platform", menori.Box(6.9, 0.26, 5.4), def.platform, { y = -0.94, z = 0.18 })
	modelNode(ctx, "forgeDeck", menori.Box(3.0, 0.18, 1.35), tint(def.platform, 1.45), { y = -0.58, z = -0.62 })
	modelNode(ctx, "core", menori.Sphere(0.52, 16, 20), def.core, { y = -0.1, z = -0.22, spin = 0.45 })
	modelNode(
		ctx,
		"innerCore",
		menori.Box(0.34, 0.34, 0.34),
		colorWithAlpha(def.accent, 0.88),
		{ y = -0.1, z = -0.22, spin = -0.8 }
	)
	modelNode(
		ctx,
		"leftPylon",
		menori.Box(0.58, 1.82, 0.48),
		def.pylon,
		{ x = -1.75, y = -0.08, z = 0.24, spin = 0.18 }
	)
	modelNode(
		ctx,
		"rightPylon",
		menori.Box(0.58, 1.82, 0.48),
		def.accent2,
		{ x = 1.75, y = -0.08, z = 0.24, spin = -0.18 }
	)
	modelNode(
		ctx,
		"archTop",
		menori.Box(4.3, 0.28, 0.46),
		colorWithAlpha(def.accent, 0.72),
		{ y = 1.02, z = 0.24, wave = 0.025 }
	)

	for index = 1, 10 do
		local side = index % 2 == 0 and 1 or -1
		local row = math.floor((index - 1) / 2)
		modelNode(
			ctx,
			"forgeVent" .. index,
			menori.Box(0.28, 0.18, 0.82),
			index % 2 == 0 and def.accent or def.accent2,
			{
				x = side * (0.75 + row * 0.34),
				y = -0.45,
				z = 1.25,
				wave = 0.035,
				phase = index * 0.7,
			}
		)
	end
	for index = 1, 12 do
		local angle = (index / 12) * math.pi * 2
		modelNode(ctx, "ember" .. index, menori.Sphere(0.09, 7, 9), index % 2 == 0 and def.accent or def.accent2, {
			x = math.cos(angle) * 2.65,
			y = -0.25 + (index % 3) * 0.08,
			z = math.sin(angle) * 1.55,
			wave = 0.1,
			phase = index * 0.8,
		})
	end
end

local function buildBusyBase(ctx)
	local def = ctx.def
	ctx.meshes.unitBox = menori.Box(1, 1, 1)
	ctx.meshes.nodeSphere = menori.Sphere(0.12, 7, 9)
	modelNode(ctx, "platform", menori.Box(8.6, 0.18, 5.7), def.platform, { y = -1.02, z = 0.12 })
	modelNode(ctx, "core", menori.Sphere(0.46, 16, 22), def.core, { y = -0.16, z = 0, spin = 0.62 })
	modelNode(
		ctx,
		"innerCore",
		menori.Box(0.28, 0.28, 0.28),
		colorWithAlpha(def.accent2, 0.88),
		{ y = -0.16, z = 0, spin = -1.0 }
	)
	modelNode(
		ctx,
		"leftPylon",
		menori.Box(0.36, 2.15, 0.36),
		def.pylon,
		{ x = -3.05, y = -0.02, z = -0.9, spin = 0.12 }
	)
	modelNode(
		ctx,
		"rightPylon",
		menori.Box(0.36, 2.15, 0.36),
		def.accent2,
		{ x = 3.05, y = -0.02, z = -0.9, spin = -0.12 }
	)
	modelNode(ctx, "swarmRail", menori.Box(6.8, 0.1, 0.28), tint(def.tile, 1.3), { y = -0.5, z = 1.72 })
end

local function buildBusyChunk(ctx, chunk)
	local def = ctx.def
	local perChunk = 28
	local columns = 28
	for offset = 1, perChunk do
		local index = (chunk - 1) * perChunk + offset
		local col = (index - 1) % columns
		local row = math.floor((index - 1) / columns)
		local x = (col - (columns - 1) / 2) * 0.25
		local z = -1.72 + row * 0.34
		local height = 0.08 + ((index * 7) % 9) * 0.032
		local width = 0.1 + ((index * 5) % 5) * 0.015
		local accent = index % 3 == 0 and def.accent or index % 3 == 1 and def.accent2 or tint(def.tile, 1.6)
		modelNode(ctx, "swarmCell" .. index, ctx.meshes.unitBox, colorWithAlpha(accent, 0.9), {
			x = x,
			y = -0.72 + height * 0.5,
			z = z,
			scale = { width, height, 0.12 },
			wave = 0.025 + (index % 5) * 0.004,
			phase = index * 0.17,
			spin = index % 11 == 0 and 0.22 or 0,
		})

		if index % 14 == 0 then
			modelNode(ctx, "swarmBeacon" .. index, ctx.meshes.nodeSphere, colorWithAlpha(def.accent, 0.86), {
				x = x,
				y = -0.22,
				z = z,
				wave = 0.13,
				phase = index * 0.23,
			})
		end
	end
	ctx.busyBuilt = ctx.busyBuilt + perChunk
end

local function buildScene(ctx)
	if ctx.def.id == "dock" then
		buildDockScene(ctx)
	elseif ctx.def.id == "forge" then
		buildForgeScene(ctx)
	else
		buildBusyBase(ctx)
		for chunk = 1, 10 do
			buildBusyChunk(ctx, chunk)
		end
	end
end

local function buildWorldConsole(worldUi)
	local def = activeDef
	return worldUi.column({
		width = 320,
		height = 176,
		padding = 12,
		gap = 7,
		style = {
			background = { 0.014, 0.026, 0.04, 0.9 },
			borderColor = colorWithAlpha(def.accent, 0.7),
			borderWidth = 2,
			radius = 8,
		},
	}, {
		worldUi.row({ width = "100%", gap = 8, align = "center" }, {
			worldUi.text("scene console", { textStyle = "caption", width = 124, style = { color = colors.muted } }),
			worldUi.text(station.route, { textStyle = "caption", flex = 1, style = { color = def.accent } }),
		}),
		worldUi.text(def.consoleText, {
			textStyle = "caption",
			wrap = true,
			width = 296,
			style = { color = colors.text },
		}),
		worldUi.row({ width = "100%", gap = 8, align = "center" }, {
			worldUi.text("energy bus", { textStyle = "caption", flex = 1, style = { color = colors.muted } }),
			worldUi.text(
				percent(station.energy),
				{ textStyle = "caption", width = 40, align = "right", style = { color = def.accent } }
			),
		}),
		worldUi.meter({
			value = station.energy,
			max = 1,
			width = "100%",
			height = 9,
			trackStyle = { background = { 0, 0, 0, 0.35 } },
			fillStyle = { background = def.accent },
			shape = { kind = "rect", radius = 4 },
		}),
		worldUi.row({ width = "100%", gap = 8 }, {
			worldUi.button({
				label = "Pulse",
				width = 148,
				height = 36,
				feedback = buttonFeedback,
				style = buttonStyle(def.accent),
				onClick = function()
					station.selection = "world console"
					pulseCore("billboard")
				end,
			}),
			worldUi.button({
				label = "Beacon",
				width = 148,
				height = 36,
				feedback = buttonFeedback,
				style = buttonStyle(def.accent2),
				onClick = function()
					station.selection = "world console"
					toggleBeacon()
				end,
			}),
		}),
	})
end

local function buildBeaconPanel(worldUi)
	local def = activeDef
	local armed = station.beaconArmed
	return worldUi.column({
		width = 220,
		height = 132,
		padding = 10,
		gap = 6,
		style = {
			background = { 0.025, 0.018, 0.03, 0.88 },
			borderColor = armed and colorWithAlpha(colors.green, 0.78) or colorWithAlpha(def.accent2, 0.6),
			borderWidth = 2,
			radius = 8,
		},
	}, {
		worldUi.text(
			def.id == "busy" and "swarm relay" or "beacon relay",
			{ textStyle = "caption", style = { color = colors.muted } }
		),
		worldUi.text(
			armed and "armed" or "standby",
			{ textStyle = "h3", style = { color = armed and colors.green or def.accent2 } }
		),
		worldUi.text(def.relayText, {
			textStyle = "caption",
			wrap = true,
			width = 200,
			style = { color = colors.text },
		}),
		worldUi.button({
			label = armed and "Park" or "Arm",
			width = "100%",
			height = 32,
			feedback = buttonFeedback,
			style = buttonStyle(armed and colors.green or def.accent2),
			onClick = function()
				station.selection = "relay billboard"
				toggleBeacon()
			end,
		}),
	})
end

local function createBillboards()
	local def = activeDef
	local console = def.console
	local relay = def.relay
	local consoleBillboard = adapter:billboard({
		name = "glyph-console-" .. def.id,
		parent = rootNode,
		environment = environment,
		camera = camera,
		x = console.x,
		y = console.y,
		z = console.z,
		width = 320,
		height = 176,
		worldWidth = console.worldWidth,
		worldHeight = console.worldHeight,
		inputPriority = "behind-ui",
		component = buildWorldConsole,
	})
	billboards[#billboards + 1] = consoleBillboard

	local relayBillboard = adapter:billboard({
		name = "glyph-relay-" .. def.id,
		parent = rootNode,
		environment = environment,
		camera = camera,
		x = relay.x,
		y = relay.y,
		z = relay.z,
		width = 220,
		height = 132,
		worldWidth = relay.worldWidth,
		worldHeight = relay.worldHeight,
		inputPriority = "behind-ui",
		component = buildBeaconPanel,
	})
	billboards[#billboards + 1] = relayBillboard
end

local function installContext(ctx)
	activeContext = ctx
	activeDef = ctx.def
	scene = ctx.scene
	rootNode = ctx.root
	camera = ctx.camera
	environment = ctx.environment
	nodes = ctx.nodes
	station.route = ctx.def.route
	station.nodeCount = ctx.nodeCount
	station.selection = ctx.def.title
	station.beaconArmed = false
	ensureAdapter(ctx)
	clearBillboards()
	createBillboards()
	setupFeelTargets(ctx)
end

local function activateContext(ctx, opts)
	opts = opts or {}
	installContext(ctx)
	local layerOpts = {
		kind = "scene",
		zIndex = 0,
		transition = opts.transition,
	}
	if opts.initial then
		adapter.scene.set("menori-world", sceneSpec(), layerOpts)
	elseif opts.preserveOverlays then
		adapter.scene.push("menori-world", sceneSpec(), layerOpts)
	else
		adapter.scene.replace("menori-world", sceneSpec(), layerOpts)
	end
end

local function buildSimpleScene(def)
	local ctx = createContext(def)
	buildScene(ctx)
	return ctx
end

local function nextSceneDef()
	if activeDef.id == "dock" then
		return sceneDefs[2]
	end
	return sceneDefs[1]
end

local function replaceWorld()
	if buildJob then
		return
	end
	local ctx = buildSimpleScene(nextSceneDef())
	activateContext(ctx, {
		transition = adapter.transitions.crossfade({ duration = 0.38 }),
	})
	log("scene replaced: " .. activeDef.title)
end

local function openBusyLoading()
	if buildJob then
		return
	end
	local def = sceneDefs[3]
	local ctx = createContext(def)
	loadingTimer = 0
	buildJob = {
		ctx = ctx,
		def = def,
		chunk = 0,
		totalChunks = 11,
		timer = 0,
		elapsed = 0,
		minDuration = docGifMode and 1.1 or 1.7,
	}
	loading = adapter.loading.open("menori-loading", {
		progress = 0,
		message = "Loading Signal Swarm",
		detail = "allocating Menori nodes",
		backdropSpec = worldSpec and worldSpec({ visualOnly = true }) or nil,
		style = {
			background = { 0.018, 0.022, 0.032, 0.92 },
			borderColor = colorWithAlpha(def.accent, 0.58),
			borderWidth = 1,
			radius = 8,
		},
		meterStyle = {
			background = { 0, 0, 0, 0.32 },
			color = def.accent,
			borderColor = { 1, 1, 1, 0.1 },
			borderWidth = 1,
		},
	})
	log("loading busy scene in chunks")
end

worldSpec = function(opts)
	opts = opts or {}
	return {
		scene = scene,
		root = rootNode,
		environment = environment,
		clearColor = activeDef.clear,
		renderStates = {
			node_sort_comp = menori.Scene.alpha_mode_comp,
		},
		autoUpdate = opts.visualOnly and false or nil,
		update = opts.visualOnly and nil or function(_, _, dt)
			time = time + (dt or 0)
			station.energy = math.max(0.12, station.energy - (dt or 0) * 0.018)
			station.shield = 0.72 + math.sin(time * 0.7) * 0.12
			station.traffic = station.beaconArmed and (0.72 + math.sin(time * 1.4) * 0.12)
				or (0.32 + math.sin(time * 0.9) * 0.06)
			station.pulse = math.max(0, station.pulse - (dt or 0) * 1.8)

			local pulse = station.pulse
			local coreScale = 1 + pulse * 0.22 + math.sin(time * 2.1) * 0.035
			if coreTarget then
				coreTarget.values.ry = time * 0.55
				coreTarget.values.rz = math.sin(time * 0.85) * 0.2
				coreTarget.values.scale = coreScale
			elseif nodes.core then
				nodes.core:set_rotation(
					menori.ml.quat.from_euler_angles(
						math.sin(time * 0.55) * 0.14,
						time * 0.55,
						math.cos(time * 0.6) * 0.12
					)
				)
				nodes.core:set_scale(coreScale, coreScale, coreScale)
			end
			if nodes.innerCore then
				local innerScale = 0.92 + pulse * 0.36 + math.sin(time * 2.8) * 0.05
				nodes.innerCore:set_rotation(menori.ml.quat.from_euler_angles(0, -time * 0.72, time * 0.2))
				nodes.innerCore:set_scale(innerScale, innerScale, innerScale)
			end

			if activeContext then
				for _, node in ipairs(activeContext.animated) do
					if node.wave and node.wave > 0 then
						node:set_position(
							node.base.x + math.sin(time * 0.7 + node.phase) * (node.drift or 0),
							node.base.y + math.sin(time * 1.8 + node.phase) * node.wave,
							node.base.z
						)
					end
					if node.spin and node.spin ~= 0 then
						node:set_rotation(
							menori.ml.quat.from_euler_angles(
								0,
								time * node.spin,
								math.sin(time * 0.45 + node.phase) * 0.08
							)
						)
					end
				end
			end

			local orbit = math.sin(time * 0.22) * (activeDef.id == "busy" and 0.75 or 0.58)
			camera.eye:set(
				activeDef.cameraEye[1] + orbit,
				activeDef.cameraEye[2] + math.sin(time * 0.18) * 0.12,
				activeDef.cameraEye[3]
			)
			camera.center:set(
				activeDef.cameraCenter[1],
				activeDef.cameraCenter[2] + math.sin(time * 0.2) * 0.04,
				activeDef.cameraCenter[3]
			)
			camera:update_view_matrix()

			if menorifx and type(menorifx.update) == "function" then
				menorifx:update(dt or 0)
			end
		end,
	}
end

local function hudButton(label, width, accent, onClick)
	return ui.button({
		label = label,
		width = width,
		height = 38,
		feedback = buttonFeedback,
		style = buttonStyle(accent),
		onClick = onClick,
	})
end

local function hudOverlay()
	local def = activeDef
	local topPanel = ui.column({
		position = "absolute",
		left = 22,
		top = 20,
		width = 386,
		padding = 15,
		gap = 10,
		style = panelStyle(def.accent, 0.9),
	}, {
		ui.row({ width = "100%", gap = 8, align = "center" }, {
			ui.text(def.title, { textStyle = "h2", flex = 1, style = { color = colors.text } }),
			ui.text("LIVE", {
				textStyle = "caption",
				width = 46,
				align = "center",
				style = {
					color = def.accent,
					background = { def.accent[1] * 0.16, def.accent[2] * 0.16, def.accent[3] * 0.16, 0.72 },
					borderColor = colorWithAlpha(def.accent, 0.52),
					borderWidth = 1,
					radius = 5,
				},
			}),
		}),
		ui.text(def.subtitle, {
			wrap = true,
			width = 346,
			style = { color = colors.muted },
		}),
		meterLine("energy", station.energy, def.accent),
		meterLine("shields", station.shield, colors.green),
		meterLine("traffic", station.traffic, def.accent2),
		ui.row({ width = "100%", gap = 8, wrap = true }, {
			hudButton("Pulse", 108, def.accent, function()
				station.selection = "screen HUD"
				pulseCore("HUD")
			end),
			hudButton("Next", 108, colors.gold, replaceWorld),
			hudButton("Load Busy", 124, def.accent2, openBusyLoading),
		}),
	})

	local rightPanel = ui.column({
		position = "absolute",
		right = 22,
		top = 20,
		width = 300,
		padding = 14,
		gap = 8,
		style = panelStyle(def.accent2, 0.84),
	}, {
		ui.text("adapter surfaces", { textStyle = "h3", style = { color = colors.text } }),
		ui.text("Screen UI wins pointer input. World billboards receive it when the HUD is not under the cursor.", {
			wrap = true,
			width = 268,
			style = { color = colors.muted },
		}),
		ui.row({ gap = 8, align = "center" }, {
			ui.text("last target", { textStyle = "caption", width = 84, style = { color = colors.muted } }),
			ui.text(station.selection, { textStyle = "caption", flex = 1, style = { color = def.accent } }),
		}),
		ui.row({ gap = 8, align = "center" }, {
			ui.text("scene nodes", { textStyle = "caption", width = 84, style = { color = colors.muted } }),
			ui.text(tostring(station.nodeCount), { textStyle = "caption", flex = 1, style = { color = def.accent2 } }),
		}),
		ui.row({ gap = 8, align = "center" }, {
			ui.text("beacon", { textStyle = "caption", width = 84, style = { color = colors.muted } }),
			ui.text(station.beaconArmed and "armed" or "standby", {
				textStyle = "caption",
				flex = 1,
				style = { color = station.beaconArmed and colors.green or def.accent2 },
			}),
		}),
	})

	local logPanel = ui.column({
		position = "absolute",
		right = 22,
		bottom = 20,
		width = 334,
		padding = 13,
		gap = 5,
		style = {
			background = colors.panelDeep,
			borderColor = { 1, 1, 1, 0.16 },
			borderWidth = 1,
			radius = 8,
		},
	}, {
			ui.text("event stream", { textStyle = "caption", width = 308, style = { color = colors.muted } }),
			ui.text(logs[#logs - 3] or "", { textStyle = "caption", wrap = true, width = 308, style = { color = colors.muted } }),
			ui.text(logs[#logs - 2] or "", { textStyle = "caption", wrap = true, width = 308, style = { color = colors.muted } }),
			ui.text(logs[#logs - 1] or "", { textStyle = "caption", wrap = true, width = 308, style = { color = colors.muted } }),
			ui.text(logs[#logs] or "", { textStyle = "caption", wrap = true, width = 308, style = { color = colors.text } }),
		})

	return ui.stack({ width = "100%", height = "100%" }, {
		topPanel,
		rightPanel,
		logPanel,
	})
end

sceneSpec = function()
	local spec = worldSpec()
	spec.overlay = hudOverlay
	return spec
end

local function updateBuildJob(dt)
	if not buildJob then
		return
	end

	local job = buildJob
	job.elapsed = job.elapsed + (dt or 0)
	job.timer = job.timer + (dt or 0)

	if job.chunk == 0 or job.timer >= (docGifMode and 0.055 or 0.11) then
		job.timer = 0
		job.chunk = job.chunk + 1
		if job.chunk == 1 then
			buildBusyBase(job.ctx)
		elseif job.chunk <= job.totalChunks then
			buildBusyChunk(job.ctx, job.chunk - 1)
		end
	end

	local buildProgress = math.min(1, job.chunk / job.totalChunks)
	local timeProgress = math.min(1, job.elapsed / job.minDuration)
	local progress = math.min(0.98, buildProgress * 0.82 + timeProgress * 0.18)
	if loading then
		loading:update({
			progress = progress,
			detail = string.format("built %d nodes", job.ctx.nodeCount),
		})
	end

	if buildProgress >= 1 and job.elapsed >= job.minDuration then
		activateContext(job.ctx, {
			preserveOverlays = true,
			transition = adapter.transitions.fade({ duration = 0.24 }),
		})
		if loading then
			loading:update({ progress = 1, detail = "handoff complete" })
			loading:close()
			loading = nil
		end
		buildJob = nil
		log("busy scene ready: " .. tostring(activeContext.nodeCount) .. " nodes")
	end
end

local function MissingMenori()
	return ui.column({
		width = "100%",
		height = "100%",
		padding = 28,
		gap = 12,
		style = { background = colors.bg },
	}, {
		ui.text("Menori adapter example", { textStyle = "h1", style = { color = colors.text } }),
		ui.text(
			"Menori is vendored under examples/menori/vendor for this demo. This fallback appears if the vendored copy is missing or Love cannot load its shader files.",
			{
				wrap = true,
				width = 620,
				style = { color = colors.muted },
			}
		),
		ui.text(
			"The example normally shows distinct Menori scenes, a busy-scene loading overlay, screen-space HUD controls, and interactive world-space Glyph billboards.",
			{
				wrap = true,
				width = 620,
				style = { color = colors.muted },
			}
		),
		ui.text(tostring(menoriLoadError or ""), {
			wrap = true,
			width = 620,
			textStyle = "caption",
			style = { color = colors.coral },
		}),
	})
end

local function setup()
	docGifTime = 0
	docGifActions = {}
	time = 0
	logs = {}
	station.energy = 0.72
	station.shield = 0.84
	station.traffic = 0.42
	station.pulse = 0
	station.beaconArmed = false
	station.route = "north gate"
	station.selection = "screen HUD"
	station.nodeCount = 0

	okMenori, menori = loadMenori()
	if not okMenori then
		ui.scene.set("menori-missing", MissingMenori, { transition = "none" })
		return
	end

	local ctx = buildSimpleScene(sceneDefs[1])
	activateContext(ctx, { initial = true, transition = "none" })
	log(
		adapter.capabilities.feelMenori and "feel.menori adapter available"
			or "feel.menori not installed; UI feedback still active"
	)
	log("world billboards accept pointer input behind the HUD")
end

local function runDocGifScript(dt)
	if not docGifMode or not okMenori then
		return
	end

	docGifTime = docGifTime + (dt or 0)

	if not docGifActions.pulse and docGifTime >= 0.36 then
		docGifActions.pulse = true
		pulseCore("docs GIF")
	elseif not docGifActions.beacon and docGifTime >= 0.78 then
		docGifActions.beacon = true
		toggleBeacon()
	elseif not docGifActions.replace and docGifTime >= 1.16 then
		docGifActions.replace = true
		replaceWorld()
	elseif not docGifActions.busy and docGifTime >= 2.12 then
		docGifActions.busy = true
		openBusyLoading()
	elseif not docGifActions.finalPulse and docGifTime >= 3.58 and not buildJob then
		docGifActions.finalPulse = true
		pulseCore("busy scene")
	end
end

local function update(dt)
	runDocGifScript(dt)
	updateBuildJob(dt)
	if loading and not buildJob then
		loadingTimer = loadingTimer + (dt or 0)
		local progress = math.min(1, loadingTimer / 1.5)
		loading:update({
			progress = progress,
			detail = progress >= 1 and "ready"
				or string.format("streaming surfaces %d%%", math.floor(progress * 100 + 0.5)),
		})
		if progress >= 1 then
			loading:close()
			loading = nil
			log("loading overlay closed")
		end
	end
end

local function teardown()
	if adapter then
		adapter:destroy()
	end
	adapter = nil
	activeContext = nil
	activeDef = sceneDefs[1]
	menorifx = nil
	coreTarget = nil
	billboards = {}
	nodes = {}
	loading = nil
	buildJob = nil
	docGifTime = 0
	docGifActions = {}
	ui.scene.clear()
end

return {
	id = "menori",
	label = "Menori",
	description = "Menori scenes with Glyph HUD panels, a loading overlay, transitions, and clickable world-space billboards.",
	setup = setup,
	teardown = teardown,
	update = update,
	usesScene = true,
	window = {
		width = 1040,
		height = 660,
		resizable = true,
		minWidth = 820,
		minHeight = 560,
		title = "glyph - menori adapter",
	},
	install = {
		gamepad = true,
	},
	keypressed = function(key)
		if key == "up" then
			return ui.navigate("up")
		elseif key == "down" then
			return ui.navigate("down")
		elseif key == "left" then
			return ui.navigate("left")
		elseif key == "right" then
			return ui.navigate("right")
		end
		return ui.keypressed(key)
	end,
	keyreleased = function(key)
		return ui.keyreleased(key)
	end,
}
