local ui = require("glyph")

local selected = "LOADOUT"
local App
local buttonState = {}
local particles = {}
local unregisterHover = nil
local unregisterNavigate = nil

local commands = {
	{
		label = "LOADOUT",
		subtitle = "Tune weapons and modules",
		hotkey = "01",
		color = { 1.0, 0.12, 0.34, 1 },
		accent = { 0.1, 0.84, 1.0, 1 },
	},
	{
		label = "TACTICS",
		subtitle = "Assign squad behavior",
		hotkey = "02",
		color = { 1.0, 0.72, 0.12, 1 },
		accent = { 0.95, 0.1, 0.86, 1 },
	},
	{
		label = "SOCIAL",
		subtitle = "Crew bonds and briefings",
		hotkey = "03",
		color = { 0.48, 1.0, 0.32, 1 },
		accent = { 0.12, 0.35, 1.0, 1 },
	},
	{
		label = "SYSTEM",
		subtitle = "Save, config, network",
		hotkey = "04",
		color = { 0.18, 0.5, 1.0, 1 },
		accent = { 1.0, 0.18, 0.34, 1 },
	},
}

local exampleTheme = {
	backgroundColor = { 0.02, 0.018, 0.032, 1 },
	textColor = { 1, 1, 1, 1 },
	mutedTextColor = { 0.74, 0.82, 0.92, 1 },
	surfaceColor = { 0.09, 0.08, 0.12, 1 },
	surfaceHoverColor = { 0.16, 0.12, 0.18, 1 },
	surfacePressedColor = { 0.22, 0.08, 0.14, 1 },
	borderColor = { 0.95, 0.95, 1, 0.22 },
	accentColor = { 1, 0.12, 0.34, 1 },
}

local function stateFor(command)
	local state = buttonState[command.label]
	if not state then
		state = {
			spring = ui.spring(1, { stiffness = 180, damping = 14 }),
			hot = false,
			pressed = false,
			bounds = nil,
			impactTime = nil,
		}
		buttonState[command.label] = state
	end
	return state
end

local function commandByLabel(label)
	for _, command in ipairs(commands) do
		if command.label == label then
			return command
		end
	end
	return nil
end

local function selectCommand(label)
	if commandByLabel(label) then
		selected = label
	end
end

local function randomRange(minValue, maxValue)
	return minValue + (maxValue - minValue) * math.random()
end

local function pointOnEdge(points, edgeIndex, ratio)
	local a = edgeIndex * 2 - 1
	local b = (edgeIndex % 4) * 2 + 1
	local x1, y1 = points[a], points[a + 1]
	local x2, y2 = points[b], points[b + 1]
	return x1 + (x2 - x1) * ratio, y1 + (y2 - y1) * ratio
end

local function spawnButtonBurst(command)
	local state = stateFor(command)
	local bounds = state.bounds
	if not bounds then
		return
	end

	local inset = 7
	local points = ui.polygonBox(bounds.x + inset, bounds.y + inset, bounds.width - inset * 2, bounds.height - inset * 2, { skew = 18 })
	local cx = bounds.x + bounds.width / 2
	local cy = bounds.y + bounds.height / 2

	for index = 1, 24 do
		local px, py = pointOnEdge(points, math.random(1, 4), math.random())
		local dx = px - cx
		local dy = py - cy
		local length = math.max(1, math.sqrt(dx * dx + dy * dy))
		local speed = randomRange(135, 265)
		local color = index % 3 == 0 and command.accent or command.color
		particles[#particles + 1] = {
			x = px,
			y = py,
			vx = dx / length * speed + randomRange(-36, 36),
			vy = dy / length * speed + randomRange(-36, 36),
			life = randomRange(0.34, 0.58),
			maxLife = 0.58,
			width = randomRange(14, 28),
			height = randomRange(5, 10),
			angle = randomRange(-0.6, 0.6),
			spin = randomRange(-5.2, 5.2),
			color = color,
			skew = randomRange(4, 9),
		}
	end
end

local function activateCommand(command)
	selectCommand(command.label)
	local state = stateFor(command)
	state.impactTime = 0
	state.spring:pull(-0.14, 260, 18)
	spawnButtonBurst(command)
end

local function updateSprings(dt)
	for _, command in ipairs(commands) do
		local state = stateFor(command)
		local active = selected == command.label
		local target = active and 1.025 or 1

		if state.hot then
			target = 1.09
		end
		if state.pressed then
			target = 0.94
		end
		if state.impactTime then
			state.impactTime = state.impactTime + dt
			if state.impactTime < 0.055 then
				target = 0.91
			elseif state.impactTime < 0.22 then
				target = 1.14
			else
				state.impactTime = nil
			end
		end

		if state.hot and not state.wasHot then
			state.spring:pull(0.035, 220, 15)
		end
		state.wasHot = state.hot

		state.spring:animate(target)
		state.spring:update(dt)
	end
end

local function updateParticles(dt)
	for index = #particles, 1, -1 do
		local particle = particles[index]
		particle.life = particle.life - dt
		particle.x = particle.x + particle.vx * dt
		particle.y = particle.y + particle.vy * dt
		particle.vx = particle.vx * math.max(0, 1 - 1.2 * dt)
		particle.vy = particle.vy + 180 * dt
		particle.angle = particle.angle + particle.spin * dt
		if particle.life <= 0 then
			table.remove(particles, index)
		end
	end
end

local function drawParticleLayer(_, _, _, _, _, love)
	local graphics = love.graphics
	for _, particle in ipairs(particles) do
		local alpha = math.max(0, particle.life / particle.maxLife)
		local color = particle.color
		local halfW = particle.width / 2
		local halfH = particle.height / 2
		local skew = particle.skew
		local points = {
			-halfW,
			-halfH,
			halfW - skew,
			-halfH,
			halfW,
			halfH,
			-halfW + skew,
			halfH,
		}

		graphics.push()
		graphics.translate(particle.x, particle.y)
		graphics.rotate(particle.angle)
		graphics.setColor(color[1], color[2], color[3], alpha * 0.82)
		graphics.polygon("fill", points)
		graphics.setColor(1, 1, 1, alpha * 0.38)
		graphics.polygon("line", points)
		graphics.pop()
	end
end

local function hudButton(command, width)
	return ui.customButton({
		key = "hud-menu-" .. command.label,
		width = width,
		height = 76,
		active = selected == command.label,
		command = command.label,
		navGroup = "hud-menu",
		onClick = function()
			activateCommand(command)
		end,
		style = {
			background = { 0.055, 0.045, 0.08, 0.92 },
			color = { 1, 1, 1, 1 },
			borderColor = command.color,
			borderWidth = 2,
			radius = 0,
			hover = {
				background = { 0.1, 0.07, 0.12, 0.96 },
				color = command.accent,
			},
			pressed = {
				background = { 0.16, 0.03, 0.07, 1 },
			},
			focused = {
				background = { 0.1, 0.07, 0.12, 0.98 },
				borderColor = command.accent,
				borderWidth = 3,
				color = command.accent,
			},
			active = {
				background = { 0.085, 0.055, 0.11, 0.96 },
				borderColor = command.accent,
			},
			transition = {
				background = 0.12,
				color = 0.1,
				borderColor = 0.12,
			},
		},
		draw = function(node, x, y, buttonWidth, buttonHeight, love, style, ctx)
			local state = stateFor(command)
			local hovered = ui.isHovered(node)
			local focused = ui.isFocused(node)
			local pressed = ui.isPressed(node)
			local active = selected == command.label
			state.hot = hovered or focused
			state.pressed = pressed
			state.bounds = { x = x, y = y, width = buttonWidth, height = buttonHeight }

			local graphics = love.graphics
			local previousLineWidth = graphics.getLineWidth and graphics.getLineWidth() or nil
			local scale = math.max(0.82, math.min(1.18, state.spring.x or 1))
			local cx = x + buttonWidth / 2
			local cy = y + buttonHeight / 2

			graphics.push()
			graphics.translate(cx, cy)
			graphics.scale(scale, scale)
			graphics.translate(-cx, -cy)

			local beat = ctx:pulse(5, tonumber(command.hotkey) or 0)
			local hot = hovered or focused or pressed or active
			local edge = hot and command.accent or command.color
			local fill = hot and ui.mixColor(style.background, command.color, 0.12) or style.background

			ctx:color(command.color, (hot and 0.55 + beat * 0.25 or 0.16) * 0.35)
			ctx:polygon("fill", ui.polygonBox(x - 8, y + 8, buttonWidth + 16, buttonHeight - 16, { skew = 18 }))

			ctx:color(fill)
			ctx:polygon("fill", ctx:skewBox({ skew = 18 }))

			love.graphics.setLineWidth(hot and 3 or 2)
			ctx:color(edge, hot and 1 or 0.68)
			ctx:polygon("line", ctx:skewBox({ skew = 18 }))

			ctx:color(command.accent, hot and 0.95 or 0.38)
			ctx:rect("fill", x + 16, y + 14, 42 + beat * 8, 4)
			ctx:rect("fill", x + buttonWidth - 68 - beat * 12, y + buttonHeight - 18, 48 + beat * 12, 3)

			ctx:color({ 0, 0, 0, 0.26 })
			for line = 1, 4 do
				ctx:rect("fill", x + 10, y + line * 14, buttonWidth - 28, 1)
			end

			ctx:color({ 1, 1, 1, hot and 1 or 0.9 })
			ctx:text(command.hotkey, x + 18, y + 24)
			ctx:text(command.label, x + 72, y + 18)
			ctx:color(ui.theme.mutedTextColor, hot and 1 or 0.72)
			ctx:text(command.subtitle, x + 72, y + 42)

			if previousLineWidth and graphics.setLineWidth then
				graphics.setLineWidth(previousLineWidth)
			end
			graphics.pop()
		end,
	})
end

local function statusPanel(width)
	return ui.box({
		width = width,
		height = 116,
		style = {
			background = { 0.04, 0.04, 0.07, 0.82 },
			borderColor = { 1, 1, 1, 0.18 },
			borderWidth = 1,
		},
		draw = function(_, x, y, panelWidth, height, love, style, ctx)
			ctx:color(style.background)
			ctx:rect("fill", x, y, panelWidth, height)
			ctx:color(style.borderColor)
			ctx:rect("line", x, y, panelWidth, height)

			for index = 1, 18 do
				local px = x + 20 + index * ((panelWidth - 40) / 18)
				local barHeight = 12 + ctx:pulse(3, index) * 56
				ctx:color(index % 3 == 0 and { 1, 0.12, 0.34, 1 } or { 0.1, 0.84, 1, 1 }, 0.76)
				ctx:rect("fill", px, y + height - 20 - barHeight, 5, barHeight)
			end

			ctx:color({ 1, 1, 1, 1 })
			ctx:text("SYNC " .. selected, x + 18, y + 16)
			ctx:color(ui.theme.mutedTextColor)
			ctx:text("D-pad focus / shaped bursts", x + 18, y + 38)
		end,
	})
end

App = function()
	local viewport = ui.viewport()
	local compact = ui.below("md")
	local menuWidth = compact and math.max(440, viewport.width - 48) or 420
	local panelWidth = compact and menuWidth or math.max(300, viewport.width - menuWidth - 72)

	local buttons = {}
	for _, command in ipairs(commands) do
		buttons[#buttons + 1] = hudButton(command, menuWidth)
	end

	local menu = ui.column({ gap = 12, width = menuWidth }, buttons)
	local info = ui.column({ gap = 12, width = panelWidth }, {
		statusPanel(panelWidth),
		ui.box({
			width = "100%",
			height = compact and 110 or 260,
			style = {
				background = { 0.08, 0.03, 0.08, 0.76 },
				borderColor = { 1, 0.12, 0.34, 0.55 },
				borderWidth = 2,
			},
			draw = function(_, x, y, width, height, love, style, ctx)
				ctx:color({ 0.08, 0.03, 0.08, 0.72 })
				ctx:rect("fill", x, y, width, height)
				for index = 1, 12 do
					local cy = y + (index / 12) * height
					local offset = math.sin(ctx.time * 2 + index) * 18
					ctx:color(index % 2 == 0 and { 0.1, 0.84, 1, 1 } or { 1, 0.12, 0.34, 1 }, 0.22)
					ctx:line(x + 14 + offset, cy, x + width - 14 + offset * 0.25, cy - 18)
				end
				ctx:color({ 1, 1, 1, 0.95 })
				ctx:text("HUD CHANNEL", x + 18, y + 18)
				ctx:color(ui.theme.mutedTextColor)
				ctx:text("Current command: " .. selected, x + 18, y + 44)
			end,
		}),
	})

	local content = ui.column({
		width = viewport.width,
		height = viewport.height,
		padding = 24,
		gap = 18,
		style = {
			background = ui.theme.backgroundColor,
		},
	}, {
		ui.text("VELVET//OPS", {
			style = {
				color = { 1, 1, 1, 1 },
			},
		}),
		ui.row({
			gap = 24,
			align = "start",
		}, compact and {
			ui.column({ gap = 16, width = "100%" }, { menu, info }),
		} or {
			menu,
			info,
		}),
	})

	return ui.stack({ width = viewport.width, height = viewport.height }, {
		content,
		ui.box({
			position = "absolute",
			inset = 0,
			interactive = false,
			accessibilityHidden = true,
			draw = drawParticleLayer,
		}),
	})
end

local function setup()
	ui.setTheme(exampleTheme)
	particles = {}
	buttonState = {}

	if unregisterHover then
		unregisterHover()
	end
	if unregisterNavigate then
		unregisterNavigate()
	end

	unregisterHover = ui.on("hoverChanged", function(node)
		local props = node and node.props or {}
		if props.command then
			selectCommand(props.command)
		end
	end)
	unregisterNavigate = ui.on("navigate", function(_, target)
		local props = target and target.props or {}
		if props.command then
			selectCommand(props.command)
		end
	end)
end

local function teardown()
	if unregisterHover then
		unregisterHover()
		unregisterHover = nil
	end
	if unregisterNavigate then
		unregisterNavigate()
		unregisterNavigate = nil
	end
	particles = {}
	buttonState = {}
end

local function update(dt)
	updateSprings(dt or 0)
	updateParticles(dt or 0)
end

local function keypressed(key)
	if key == "up" then
		return ui.navigate("up")
	elseif key == "down" then
		return ui.navigate("down")
	elseif key == "left" then
		return ui.navigate("left")
	elseif key == "right" then
		return ui.navigate("right")
	elseif key == "kpenter" then
		return ui.keypressed("return")
	end

	local index = tonumber(key)
	if index and commands[index] then
		activateCommand(commands[index])
		return true
	end

	return ui.keypressed(key)
end

local function keyreleased(key)
	if key == "kpenter" then
		return ui.keyreleased("return")
	end
	return ui.keyreleased(key)
end

return {
	id = "hud-menu",
	label = "HUD Menu",
	description = "D-pad navigation / springy buttons / shaped bursts.",
	setup = setup,
	teardown = teardown,
	update = update,
	window = {
		width = 920,
		height = 620,
		resizable = true,
		minWidth = 520,
		minHeight = 460,
		breakpoints = { md = 760 },
	},
	install = {
		gamepad = true,
	},
	keypressed = keypressed,
	keyreleased = keyreleased,
	component = function()
		return App()
	end,
}
