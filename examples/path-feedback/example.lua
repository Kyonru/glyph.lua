local ui = require("glyph")
local feel = require("glyph.vendor.feel")

local TAU = math.pi * 2

local colors = {
	bg = { 0.025, 0.03, 0.043, 1 },
	panel = { 0.052, 0.065, 0.088, 0.94 },
	panelDeep = { 0.026, 0.033, 0.05, 0.96 },
	border = { 0.56, 0.76, 0.96, 0.24 },
	text = { 0.92, 0.96, 1, 1 },
	muted = { 0.54, 0.63, 0.72, 1 },
	teal = { 0.09, 0.86, 0.74, 1 },
	blue = { 0.28, 0.52, 1, 1 },
	gold = { 1, 0.72, 0.24, 1 },
	coral = { 1, 0.28, 0.38, 1 },
	violet = { 0.68, 0.42, 1, 1 },
}

local routePath = "M0 86 C62 8 108 142 166 66 C222 -12 284 116 360 32"
local runeA = "M50 4 L90 30 L82 88 L50 110 L18 88 L10 30 Z"
local runeB = "M50 0 L62 34 L98 34 L68 56 L80 98 L50 72 L20 98 L32 56 L2 34 L38 34 Z"
local ringPath = "M50 0 C77.6 0 100 22.4 100 50 C100 77.6 77.6 100 50 100 C22.4 100 0 77.6 0 50 C0 22.4 22.4 0 50 0 Z"
local circuitPath = "M8 40 L36 40 L48 18 L64 74 L78 40 L112 40"

local sigilTarget = nil
local particles = {}
local particleSeed = 1
local stageBounds = nil
local status = "trace channel"
local statusColor = colors.teal
local activeCommand = "Trace"
local autoCycle = true
local autoTimer = 0
local commandIndex = 1

local commands = {}

local function clamp(value, minValue, maxValue)
	value = tonumber(value) or 0
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end
	return value
end

local function alpha(color, opacity)
	return { color[1], color[2], color[3], opacity ~= nil and opacity or color[4] or 1 }
end

local function mix(a, b, t)
	return a + (b - a) * t
end

local function mixColor(a, b, t, opacity)
	return {
		mix(a[1], b[1], t),
		mix(a[2], b[2], t),
		mix(a[3], b[3], t),
		opacity ~= nil and opacity or mix(a[4] or 1, b[4] or 1, t),
	}
end

local function pseudoRandom(seed)
	local x = math.sin(seed * 12.9898) * 43758.5453
	return x - math.floor(x)
end

local function markDirty()
	if ui.runtime and ui.runtime.markDirty then
		ui.runtime:markDirty()
	end
end

local function ensureTarget()
	if sigilTarget then
		return sigilTarget
	end

	sigilTarget = feel.target({
		label = "vector path sigil",
		values = {
			progress = 1,
			morph = 0,
			glow = 0.28,
			ring = 0,
			scan = 0,
			shake = 0,
			pulse = 0,
		},
	})
	return sigilTarget
end

local function values()
	return ensureTarget().values
end

local function setStatus(label, color)
	status = label
	statusColor = color or colors.teal
	activeCommand = label
end

local function spawnParticles(payload)
	payload = payload or {}
	local bounds = stageBounds or { x = 210, y = 96, width = 560, height = 410 }
	local count = payload.count or 14
	local color = payload.color or colors.teal
	local spread = payload.spread or 1
	local cx = payload.x or (bounds.x + bounds.width * (payload.anchorX or 0.58))
	local cy = payload.y or (bounds.y + bounds.height * (payload.anchorY or 0.5))

	for index = 1, count do
		local seed = particleSeed + index * 17
		local angle = (index / count) * TAU + pseudoRandom(seed) * 0.8
		local speed = (48 + pseudoRandom(seed + 4) * 128) * spread
		particles[#particles + 1] = {
			x = cx + (pseudoRandom(seed + 8) - 0.5) * 22,
			y = cy + (pseudoRandom(seed + 12) - 0.5) * 22,
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed,
			life = 0.48 + pseudoRandom(seed + 16) * 0.45,
			age = 0,
			size = 2.4 + pseudoRandom(seed + 20) * 4.2,
			color = color,
		}
	end

	particleSeed = particleSeed + count * 31
	markDirty()
end

local function handleFeelEvent(event)
	if event and event.kind == "path.spark" then
		spawnParticles(event.payload)
	elseif event and event.kind == "path.flare" then
		local payload = event.payload or {}
		payload.count = payload.count or 28
		payload.spread = payload.spread or 1.35
		spawnParticles(payload)
	end
end

local function playPathSequence(sequence, trigger)
	return feel.play(sequence, ensureTarget(), {
		trigger = trigger or "manual",
		restart = true,
		key = "path-feedback-sigil",
		markDirty = markDirty,
		emit = handleFeelEvent,
	})
end

local function playTrace()
	local v = values()
	v.progress = 0
	v.scan = 0
	v.ring = 0
	v.shake = 0
	v.glow = 0.26
	setStatus("Trace", colors.teal)
	playPathSequence({
		{
			kind = "emit",
			event = "path.spark",
			payload = { count = 18, color = colors.teal, anchorX = 0.2, anchorY = 0.42 },
		},
		{
			kind = "parallel",
			steps = {
				{ kind = "animate", to = { progress = 1 }, duration = 0.9, ease = "quadout" },
				{ kind = "animate", to = { scan = 1 }, duration = 0.88, ease = "quadout" },
				{ kind = "animate", to = { glow = 0.95 }, duration = 0.16, ease = "quadout" },
			},
		},
		{ kind = "animate", to = { glow = 0.3, scan = 0 }, duration = 0.42, ease = "quadinout" },
	}, "trace")
end

local function playMorph()
	local v = values()
	local targetMorph = v.morph < 0.5 and 1 or 0
	v.ring = 0
	v.glow = 0.36
	v.shake = 0
	setStatus("Morph", colors.violet)
	playPathSequence({
		{
			kind = "emit",
			event = "path.spark",
			payload = { count = 22, color = colors.violet, anchorX = 0.6, anchorY = 0.5 },
		},
		{
			kind = "parallel",
			steps = {
				{ kind = "animate", to = { morph = targetMorph }, duration = 0.62, ease = "backout" },
				{ kind = "animate", to = { ring = 1 }, duration = 0.34, ease = "quadout" },
				{ kind = "animate", to = { glow = 0.92 }, duration = 0.2, ease = "quadout" },
			},
		},
		{ kind = "animate", to = { ring = 0, glow = 0.34 }, duration = 0.32, ease = "quadinout" },
	}, "morph")
end

local function playPulse()
	local v = values()
	v.ring = 0
	v.pulse = 0
	v.shake = 0
	v.glow = 0.5
	setStatus("Pulse", colors.gold)
	playPathSequence({
		{
			kind = "parallel",
			steps = {
				{
					kind = "repeat",
					count = 3,
					step = {
						{ kind = "animate", to = { ring = 1, pulse = 1, glow = 1 }, duration = 0.1, ease = "quadout" },
						{
							kind = "animate",
							to = { ring = 0, pulse = 0, glow = 0.38 },
							duration = 0.18,
							ease = "quadinout",
						},
					},
				},
				{
					kind = "emit",
					event = "path.flare",
					payload = { count = 32, color = colors.gold, spread = 1.05, anchorX = 0.58, anchorY = 0.5 },
				},
			},
		},
		{ kind = "animate", to = { glow = 0.3, ring = 0, pulse = 0 }, duration = 0.18 },
	}, "pulse")
end

local function playOverload()
	local v = values()
	v.progress = 0
	v.scan = 1
	v.ring = 0
	v.glow = 0.9
	setStatus("Overload", colors.coral)
	playPathSequence({
		{
			kind = "parallel",
			steps = {
				{ kind = "animate", to = { progress = 1 }, duration = 0.22, ease = "quadout" },
				{
					kind = "repeat",
					count = 3,
					step = {
						{ kind = "animate", to = { shake = 8 }, duration = 0.035, ease = "quadout" },
						{ kind = "animate", to = { shake = -7 }, duration = 0.04, ease = "quadout" },
					},
				},
				{
					kind = "random",
					options = {
						{
							weight = 3,
							step = {
								kind = "emit",
								event = "path.flare",
								payload = { count = 34, color = colors.coral, spread = 1.55 },
							},
						},
						{
							weight = 1,
							step = {
								kind = "emit",
								event = "path.flare",
								payload = { count = 34, color = colors.blue, spread = 1.45 },
							},
						},
					},
				},
				{ kind = "animate", to = { ring = 1, pulse = 1 }, duration = 0.16, ease = "quadout" },
			},
		},
		{
			kind = "animate",
			to = { shake = 0, ring = 0, pulse = 0, scan = 0, glow = 0.32 },
			duration = 0.28,
			ease = "backout",
		},
	}, "overload")
end

commands = {
	{ id = "trace", label = "Trace", color = colors.teal, run = playTrace },
	{ id = "morph", label = "Morph", color = colors.violet, run = playMorph },
	{ id = "pulse", label = "Pulse", color = colors.gold, run = playPulse },
	{ id = "overload", label = "Overload", color = colors.coral, run = playOverload },
}

local function runCommand(index)
	local command = commands[index]
	if not command then
		return
	end
	commandIndex = index
	autoTimer = 3.0
	command.run()
end

local function defineFeedback()
	ui.feedback.clear()
	ui.feedback.define("path.command.press", {
		{ kind = "animate", to = { scaleX = 1.035, scaleY = 0.95, y = 2 }, duration = 0.055, ease = "quadout" },
	})
	ui.feedback.define("path.command.release", {
		{ kind = "animate", to = { scale = 1, scaleX = 1, scaleY = 1, y = 0 }, duration = 0.14, ease = "backout" },
	})
	ui.feedback.define("path.command.activate", {
		{ kind = "play", name = "path.command.release", opts = { restart = true, key = "path.command.release" } },
		{ kind = "animate", to = { scale = 1.045 }, duration = 0.06, ease = "quadout" },
		{ kind = "animate", to = { scale = 1 }, duration = 0.12, ease = "backout" },
	})
end

local function updateParticles(dt)
	if #particles == 0 then
		return
	end

	local write = 1
	for read = 1, #particles do
		local particle = particles[read]
		particle.age = particle.age + dt
		if particle.age < particle.life then
			particle.x = particle.x + particle.vx * dt
			particle.y = particle.y + particle.vy * dt
			particle.vx = particle.vx * (1 - math.min(0.92, dt * 1.8))
			particle.vy = particle.vy * (1 - math.min(0.92, dt * 1.8))
			particles[write] = particle
			write = write + 1
		end
	end

	for index = write, #particles do
		particles[index] = nil
	end

	if #particles > 0 then
		markDirty()
	end
end

local function drawParticles(ctx)
	for _, particle in ipairs(particles) do
		local life = 1 - particle.age / particle.life
		ctx:color(alpha(particle.color, life * 0.78))
		ctx:shape("fill", { kind = "circle", segments = 12 }, {
			x = particle.x - particle.size * 0.5,
			y = particle.y - particle.size * 0.5,
			width = particle.size,
			height = particle.size,
		})
	end
end

local function drawStage(_, x, y, width, height, _, _, ctx)
	local v = values()
	local glow = clamp(v.glow or 0, 0, 1)
	local scan = clamp(v.scan or 0, 0, 1)

	ctx:color(colors.panelDeep)
	ctx:rect("fill", x, y, width, height, 8)

	ctx:color({ 1, 1, 1, 0.045 })
	for gx = 28, width - 20, 34 do
		ctx:line(x + gx, y + 22, x + gx, y + height - 22)
	end
	for gy = 28, height - 20, 34 do
		ctx:line(x + 22, y + gy, x + width - 22, y + gy)
	end

	local traceBounds = { x = x + 58, y = y + 58, width = width - 116, height = 122 }
	ctx:path("line", routePath, traceBounds, {
		stroke = alpha(colors.blue, 0.18 + glow * 0.12),
		strokeWidth = 8,
		fit = "stretch",
		samples = 64,
	})

	if scan > 0 then
		local sx = traceBounds.x + traceBounds.width * scan
		ctx:color(alpha(colors.teal, 0.08 + glow * 0.08))
		ctx:rect("fill", sx - 42, traceBounds.y - 22, 84, traceBounds.height + 44, 10)
	end

	local coreBounds = { x = x + width * 0.5 - 78, y = y + height * 0.5 - 78, width = 156, height = 156 }

	ctx:path("line", circuitPath, {
		x = x + 44,
		y = y + height - 92,
		width = 190,
		height = 56,
	}, {
		stroke = alpha(colors.gold, 0.22 + glow * 0.18),
		strokeWidth = 3,
		progress = 0.34 + (v.progress or 0) * 0.66,
		fit = "stretch",
		samples = 24,
	})

	drawParticles(ctx)
end

local function stageView()
	local v = values()
	local glow = clamp(v.glow or 0, 0, 1)
	local ring = clamp(v.ring or 0, 0, 1)
	local pulse = clamp(v.pulse or 0, 0, 1)
	local shake = v.shake or 0
	local offsetX = math.sin((ui.time() or 0) * 70) * shake
	local offsetY = math.cos((ui.time() or 0) * 51) * shake * 0.55
	local stageWidth = stageBounds and stageBounds.width or 520
	local stageHeight = stageBounds and stageBounds.height or 390
	local margin = clamp(stageWidth * 0.09, 34, 60)
	local routeWidth = math.max(180, stageWidth - margin * 2)
	local routeHeight = clamp(stageHeight * 0.28, 82, 122)
	local routeTop = clamp(stageHeight * 0.13, 42, 58)
	local runeSize = clamp(math.min(stageWidth, stageHeight) * 0.42, 118, 178)
	local runeCenterX = stageWidth * 0.56
	local runeCenterY = stageHeight * 0.52
	local maxRingSize = math.max(96, math.min(stageWidth - 28, stageHeight - 28))
	local ringSize = clamp(runeSize + 76 + ring * 54, runeSize + 40, maxRingSize)

	return ui.stack({
		key = "path-feedback-stage",
		flex = 1,
		minHeight = 390,
		onLayout = function(bounds)
			if
				not stageBounds
				or stageBounds.x ~= bounds.x
				or stageBounds.y ~= bounds.y
				or stageBounds.width ~= bounds.width
				or stageBounds.height ~= bounds.height
			then
				stageBounds = { x = bounds.x, y = bounds.y, width = bounds.width, height = bounds.height }
				markDirty()
			end
		end,
		style = {
			background = colors.panelDeep,
			borderColor = alpha(mixColor(colors.blue, colors.teal, glow), 0.42 + glow * 0.28),
			borderWidth = 1,
			radius = 8,
		},
	}, {
		ui.box({
			position = "absolute",
			inset = 0,
			interactive = false,
			accessibilityHidden = true,
			draw = drawStage,
		}),
		ui.path({
			position = "absolute",
			left = margin + offsetX,
			top = routeTop + offsetY,
			width = routeWidth,
			height = routeHeight,
			d = routePath,
			stroke = alpha(colors.teal, 0.9),
			strokeWidth = 4 + glow * 2,
			progress = clamp(v.progress or 0, 0, 1),
			fit = "stretch",
			samples = 72,
			interactive = false,
		}),
		ui.path({
			position = "absolute",
			left = runeCenterX - runeSize * 0.5 + offsetX,
			top = runeCenterY - runeSize * 0.5 + offsetY,
			width = runeSize,
			height = runeSize,
			d = runeA,
			morphTo = runeB,
			morph = clamp(v.morph or 0, 0, 1),
			morphMode = "resample",
			mode = "both",
			fill = alpha(mixColor(colors.teal, colors.violet, clamp(v.morph or 0, 0, 1)), 0.14 + glow * 0.16),
			stroke = mixColor(colors.teal, colors.violet, clamp(v.morph or 0, 0, 1), 1),
			strokeWidth = 3 + glow * 2,
			fit = "stretch",
			samples = 96,
			interactive = false,
		}),
		ui.path({
			position = "absolute",
			left = runeCenterX - ringSize * 0.5 + offsetX,
			top = runeCenterY - ringSize * 0.5 + offsetY,
			width = ringSize,
			height = ringSize,
			d = ringPath,
			stroke = alpha(colors.gold, ring * 0.85),
			strokeWidth = 3 + pulse * 7,
			fill = alpha(colors.gold, ring * 0.035),
			mode = "both",
			fit = "stretch",
			samples = 120,
			interactive = false,
		}),
		ui.column({
			position = "absolute",
			left = 28,
			bottom = 24,
			gap = 4,
			interactive = false,
			accessibilityHidden = true,
		}, {
			ui.text(activeCommand, {
				textStyle = "h2",
				style = { color = statusColor },
			}),
			ui.text("vector resonance", {
				textStyle = "caption",
				style = { color = colors.muted },
			}),
		}),
	})
end

local function statMeter(label, value, color)
	return ui.column({ gap = 5, width = "100%" }, {
		ui.row({ width = "100%", justify = "center", align = "center" }, {
			ui.text(label, { flex = 1, textStyle = "caption", style = { color = colors.muted } }),
			ui.text(
				tostring(math.floor(value * 100 + 0.5)) .. "%",
				{ textStyle = "caption", style = { color = color } }
			),
		}),
		ui.meter({
			value = value,
			max = 1,
			height = 9,
			shape = { kind = "skew", skew = 8 },
			trackStyle = { background = { 1, 1, 1, 0.07 } },
			fillStyle = { background = color },
		}),
	})
end

local function commandButton(command, index)
	return ui.button({
		key = "path-feedback-command-" .. command.id,
		label = command.label,
		width = "100%",
		height = 42,
		onClick = function()
			autoCycle = false
			runCommand(index)
		end,
		feedback = {
			press = "path.command.press",
			release = "path.command.release",
			activate = "path.command.activate",
		},
		style = {
			background = command.label == activeCommand and alpha(command.color, 0.28) or { 1, 1, 1, 0.055 },
			color = colors.text,
			borderColor = command.label == activeCommand and alpha(command.color, 0.9) or { 1, 1, 1, 0.16 },
			borderWidth = 1,
			radius = 6,
			hover = {
				background = alpha(command.color, 0.18),
				borderColor = alpha(command.color, 0.76),
			},
			focused = {
				borderColor = alpha(command.color, 1),
				borderWidth = 2,
			},
			pressed = {
				background = alpha(command.color, 0.32),
			},
		},
	})
end

local function sidePanel()
	local v = values()
	local activeRuns = ui.feedback.active()
	local buttons = {}
	for index, command in ipairs(commands) do
		buttons[#buttons + 1] = commandButton(command, index)
	end

	return ui.column({
		width = 286,
		padding = 16,
		gap = 13,
		style = {
			background = colors.panel,
			borderColor = colors.border,
			borderWidth = 1,
			radius = 8,
		},
	}, {
		ui.column({ gap = 2 }, {
			ui.text("Signal", { textStyle = "caption", style = { color = colors.muted } }),
			ui.text(status, { textStyle = "h2", style = { color = statusColor } }),
		}),
		ui.column({ gap = 9 }, buttons),
		ui.box({ width = "100%", height = 1, style = { background = { 1, 1, 1, 0.1 } } }),
		statMeter("stroke", clamp(v.progress or 0, 0, 1), colors.teal),
		statMeter("morph", clamp(v.morph or 0, 0, 1), colors.violet),
		statMeter("glow", clamp(v.glow or 0, 0, 1), colors.gold),
		ui.row({ width = "100%", gap = 8, align = "center" }, {
			ui.box({
				width = 10,
				height = 10,
				style = {
					background = #activeRuns > 0 and colors.teal or colors.muted,
					radius = 5,
				},
			}),
			ui.text("active runs " .. tostring(#activeRuns), { style = { color = colors.muted } }),
		}),
		ui.button({
			key = "path-feedback-cycle",
			label = autoCycle and "Cycle On" or "Cycle Off",
			width = "100%",
			height = 36,
			onClick = function()
				autoCycle = not autoCycle
				autoTimer = 0.25
				markDirty()
			end,
			feedback = {
				press = "path.command.press",
				release = "path.command.release",
				activate = "path.command.activate",
			},
			style = {
				background = autoCycle and alpha(colors.blue, 0.22) or { 1, 1, 1, 0.05 },
				color = colors.text,
				borderColor = autoCycle and alpha(colors.blue, 0.8) or { 1, 1, 1, 0.14 },
				borderWidth = 1,
				radius = 6,
			},
		}),
	})
end

local function background()
	return ui.box({
		position = "absolute",
		inset = 0,
		interactive = false,
		accessibilityHidden = true,
		draw = function(_, x, y, width, height, _, _, ctx)
			ctx:color(colors.bg)
			ctx:rect("fill", x, y, width, height)
			ctx:color({ 1, 1, 1, 0.035 })
			for index = -80, width + 160, 42 do
				ctx:line(x + index, y, x + index - 180, y + height)
			end
			ctx:path("line", ringPath, {
				x = x + width - 220,
				y = y - 70,
				width = 300,
				height = 300,
			}, {
				stroke = alpha(colors.blue, 0.08),
				strokeWidth = 2,
				fit = "stretch",
				samples = 96,
			})
		end,
	})
end

local function App()
	return ui.stack({
		width = "100%",
		height = "100%",
	}, {
		ui.column({
			position = "absolute",
			left = 28,
			right = 28,
			top = 24,
			bottom = 24,
			gap = 16,
		}, {
			ui.row({ width = "100%", align = "center", gap = 14 }, {
				ui.column({ gap = 3, flex = 1 }, {
					ui.text("Vector Relay", {
						textStyle = "h1",
						style = { color = colors.text },
					}),
					ui.text("feel-driven path state", {
						textStyle = "caption",
						style = { color = colors.muted },
					}),
				}),
				ui.box({
					width = 136,
					height = 30,
					display = "column",
					align = "center",
					justify = "center",
					style = {
						background = alpha(statusColor, 0.16),
						borderColor = alpha(statusColor, 0.72),
						borderWidth = 1,
						radius = 15,
					},
				}, {
					ui.text(activeCommand, { textStyle = "caption", style = { color = colors.text } }),
				}),
			}),
			ui.row({
				width = "100%",
				flex = 1,
				gap = 16,
				align = "stretch",
			}, {
				stageView(),
				sidePanel(),
			}),
		}),
	})
end

local function setup()
	sigilTarget = nil
	particles = {}
	stageBounds = nil
	particleSeed = 1
	activeCommand = "Trace"
	status = "trace channel"
	statusColor = colors.teal
	autoCycle = true
	autoTimer = 2.6
	commandIndex = 1
	defineFeedback()
	ensureTarget()
	playTrace()
end

local function teardown()
	ui.feedback.clear()
	sigilTarget = nil
	particles = {}
	stageBounds = nil
end

local function update(dt)
	updateParticles(dt or 0)
	if autoCycle then
		autoTimer = autoTimer - (dt or 0)
		if autoTimer <= 0 then
			commandIndex = commandIndex % #commands + 1
			runCommand(commandIndex)
			autoCycle = true
		end
	end
end

return {
	id = "path-feedback",
	label = "Path Feedback",
	description = "Trace a vector relay with path reveal, a morphing sigil, pulse rings, particles, and feedback targets.",
	setup = setup,
	teardown = teardown,
	update = update,
	window = {
		width = 980,
		height = 640,
		resizable = true,
		minWidth = 780,
		minHeight = 520,
		title = "glyph - path feedback",
	},
	install = {
		gamepad = true,
	},
	component = function()
		return App()
	end,
	keypressed = function(key)
		if key == "up" then
			return ui.navigate("up")
		elseif key == "down" then
			return ui.navigate("down")
		elseif key == "left" then
			return ui.navigate("left")
		elseif key == "right" then
			return ui.navigate("right")
		elseif key == "1" or key == "2" or key == "3" or key == "4" then
			autoCycle = false
			runCommand(tonumber(key))
			return true
		end
		return ui.keypressed(key)
	end,
	keyreleased = function(key)
		return ui.keyreleased(key)
	end,
}
