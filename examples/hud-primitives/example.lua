local ui = require("glyph")

local selected = "Vanguard"
local unregisterNavigate = nil

local panelStyle = ui.style({
	background = { 0.035, 0.045, 0.07, 0.94 },
	borderColor = { 1, 1, 1, 0.18 },
	borderWidth = 1,
})

local accentStyle = ui.style({
	background = { 0.08, 0.08, 0.12, 0.9 },
	borderColor = { 0.1, 0.84, 1, 0.72 },
	borderWidth = 2,
	shape = { kind = "skew", skew = 18 },
})

local units = {
	{
		name = "Vanguard",
		role = "front line",
		hp = 86,
		mp = 42,
		charge = 72,
		color = { 0.1, 0.84, 1, 1 },
	},
	{
		name = "Cipher",
		role = "support",
		hp = 62,
		mp = 91,
		charge = 48,
		color = { 1, 0.18, 0.42, 1 },
	},
	{
		name = "Lumen",
		role = "tactics",
		hp = 74,
		mp = 66,
		charge = 88,
		color = { 1, 0.82, 0.2, 1 },
	},
}

local function fallbackSweepPoints(x, y, size, value, max)
	local cx = x + size / 2
	local cy = y + size / 2
	local radius = size / 2
	local startAngle = math.rad(135)
	local endAngle = math.rad(405)
	local ratio = math.max(0, math.min(1, (value or 0) / (max or 100)))
	local fillEnd = startAngle + (endAngle - startAngle) * ratio
	local segments = math.max(3, math.ceil(24 * ratio))
	local points = { cx, cy }

	for index = 0, segments do
		local angle = startAngle + (fillEnd - startAngle) * (index / segments)
		points[#points + 1] = cx + math.cos(angle) * radius
		points[#points + 1] = cy + math.sin(angle) * radius
	end

	return points
end

local function drawSweepGauge(ctx, x, y, size, value, colorValue)
	local bounds = { x = x, y = y, width = size, height = size }
	local graphics = ctx.graphics
	local cx = x + size / 2
	local cy = y + size / 2
	local radius = size / 2
	local startAngle = math.rad(135)
	local endAngle = math.rad(405)
	local ratio = math.max(0, math.min(1, (value or 0) / 100))
	local fillEnd = startAngle + (endAngle - startAngle) * ratio
	local segments = 32

	ctx:color({ 0, 0, 0, 0.28 })
	ctx:shape("fill", { kind = "circle", segments = 40 }, bounds)
	ctx:color(colorValue, 0.86)
	if graphics and graphics.arc then
		graphics.arc("fill", cx, cy, radius, startAngle, fillEnd, segments)
		ctx:color(colorValue, 1)
		graphics.arc("line", "open", cx, cy, radius, startAngle, fillEnd, segments)
	else
		ctx:polygon("fill", fallbackSweepPoints(x, y, size, value, 100))
	end
	ctx:color({ 1, 1, 1, 0.22 })
	ctx:shape("line", { kind = "circle", segments = 40 }, bounds)
end

local function drawGridBackground(_, x, y, width, height, _, _, ctx)
	ctx:color({ 0.015, 0.018, 0.028, 1 })
	ctx:rect("fill", x, y, width, height)

	for index = 1, 18 do
		local offset = (ctx.time * 26 + index * 31) % (width + 90)
		ctx:color(index % 2 == 0 and { 0.1, 0.84, 1, 0.12 } or { 1, 0.18, 0.42, 0.1 })
		ctx:line(x - 70 + offset, y, x - 20 + offset, y + height)
	end

	for row = 1, 8 do
		local py = y + row * (height / 9)
		ctx:color({ 1, 1, 1, 0.045 })
		ctx:line(x, py, x + width, py)
	end
end

local function drawTelemetry(_, x, y, width, height, _, _, ctx)
	ctx:color({ 0.04, 0.05, 0.075, 0.9 })
	ctx:shape("fill", { kind = "polygon", points = { 0, 10, width - 16, 0, width, height - 10, 18, height } })
	ctx:color({ 1, 1, 1, 0.18 })
	ctx:shape("line", { kind = "polygon", points = { 0, 10, width - 16, 0, width, height - 10, 18, height } })

	for index = 1, 5 do
		local value = 30 + ctx:pulse(2.4, index) * 70
		ctx:meter({
			x = x + 18,
			y = y + 18 + index * 16,
			width = width - 36,
			height = 8,
		}, {
			value = value,
			max = 100,
			shape = { kind = "skew", skew = 7 },
			trackStyle = { background = { 0, 0, 0, 0.28 } },
			fillStyle = {
				background = index % 2 == 0 and { 0.1, 0.84, 1, 0.85 } or { 1, 0.18, 0.42, 0.85 },
			},
		})
	end
end

local function unitCard(unit)
	local active = selected == unit.name

	return ui.button({
		label = "",
		width = 248,
		height = 148,
		active = active,
		navGroup = "units",
		unitName = unit.name,
		onClick = function()
			selected = unit.name
		end,
		style = ui.composeStyles(accentStyle, {
			background = active and { 0.08, 0.14, 0.18, 0.96 } or { 0.035, 0.045, 0.07, 0.94 },
			borderColor = active and unit.color or { 1, 1, 1, 0.18 },
			focused = {
				background = { 0.14, 0.22, 0.28, 0.98 },
				borderColor = { 1, 1, 1, 1 },
			},
		}),
		draw = function(_, x, y, width, height, _, style, ctx)
			ctx:color(style.background)
			ctx:shape("fill", style.shape)
			ctx:color(style.borderColor)
			ctx:shape("line", style.shape)

			ctx:clip({ kind = "skew", skew = 18, inset = 2 }, function()
				for band = 1, 5 do
					ctx:color(band % 2 == 0 and unit.color or { 1, 1, 1, 1 }, active and 0.12 or 0.06)
					ctx:rect("fill", x + band * 38 + ctx:pulse(2, band) * 18, y, 18, height)
				end
			end)

			ctx:color({ 1, 1, 1, 1 })
			ctx:text(unit.name, x + 18, y + 18)
			ctx:color({ 0.72, 0.82, 0.9, 1 })
			ctx:text(unit.role, x + 18, y + 40)

			ctx:color({ 0.82, 0.9, 1, 1 })
			ctx:text("HP", x + 18, y + height - 48)
			ctx:meter({ x = x + 52, y = y + height - 46, width = 154, height = 12 }, {
				value = unit.hp,
				max = 100,
				shape = { kind = "skew", skew = 10 },
				trackStyle = { background = { 0, 0, 0, 0.34 } },
				fillStyle = { background = { 0.1, 0.9, 0.56, 1 } },
			})

			ctx:text("MP", x + 18, y + height - 26)
			ctx:meter({ x = x + 52, y = y + height - 24, width = 154, height = 12 }, {
				value = unit.mp,
				max = 100,
				shape = { kind = "skew", skew = 10 },
				trackStyle = { background = { 0, 0, 0, 0.34 } },
				fillStyle = { background = { 0.36, 0.58, 1, 1 } },
			})

			local gaugeX = x + width - 72
			local gaugeY = y + 18
			drawSweepGauge(ctx, gaugeX, gaugeY, 54, unit.charge, unit.color)
			ctx:color({ 1, 1, 1, 0.96 })
			ctx:text(tostring(unit.charge), gaugeX + 18, gaugeY + 18)
			ctx:color({ 0.72, 0.82, 0.9, 0.86 })
			ctx:text("CHG", gaugeX + 16, gaugeY + 34)
		end,
	})
end

local function portraitPanel()
	local frameShape = { kind = "polygon", points = { 18, 0, 280, 0, 254, 236, 0, 214 } }

	return ui.stack({
		width = 280,
		height = 236,
		style = ui.composeStyles(panelStyle, { shape = frameShape }),
		clip = frameShape,
	}, {
		ui.box({ position = "absolute", inset = 0, interactive = false, draw = drawGridBackground }),
		ui.stack({
			position = "absolute",
			right = 24,
			top = 26,
			width = 96,
			height = 96,
			stencil = { shape = { kind = "circle" }, mode = "inside" },
		}, {
			ui.box({
				position = "absolute",
				inset = 0,
				interactive = false,
				draw = function(_, x, y, width, height, _, _, ctx)
					ctx:color({ 0.04, 0.08, 0.14, 1 })
					ctx:rect("fill", x, y, width, height)
					ctx:color({ 0.1, 0.84, 1, 0.8 })
					ctx:rect("fill", x + 20, y + 16, 56, 70, 14)
					ctx:color({ 1, 1, 1, 0.9 })
					ctx:rect("fill", x + 34, y + 32, 12, 8)
					ctx:rect("fill", x + 54, y + 32, 12, 8)
				end,
			}),
		}),
		ui.text("CLIPPED STATUS FRAME", {
			position = "absolute",
			left = 22,
			top = 24,
			style = { color = { 1, 1, 1, 1 } },
		}),
		ui.text("polygon clip + circle stencil", {
			position = "absolute",
			left = 22,
			top = 50,
			style = { color = { 0.72, 0.86, 1, 1 } },
		}),
		ui.meter({
			position = "absolute",
			left = 22,
			bottom = 34,
			value = 118,
			max = 100,
			width = 190,
			height = 16,
			shape = { kind = "skew", skew = 14 },
			trackStyle = { background = { 0, 0, 0, 0.3 } },
			fillStyle = { background = { 0.1, 0.9, 0.56, 1 } },
			overfillStyle = { background = { 1, 0.82, 0.2, 1 } },
			label = "OVERFILL",
		}),
	})
end

local function App()
	local viewport = ui.viewport()
	local compact = ui.below("md")
	local cardColumnWidth = compact and math.max(280, viewport.width - 48) or 530

	local cards = {}
	for _, unit in ipairs(units) do
		cards[#cards + 1] = unitCard(unit)
	end
	local cardRows = nil
	if compact then
		cardRows = ui.column({ gap = 12, width = cardColumnWidth }, cards)
	else
		cardRows = ui.column({ gap = 12, width = cardColumnWidth }, {
			ui.row({ gap = 12 }, {
				cards[1],
				cards[2],
			}),
			cards[3],
		})
	end

	local rightPanel = nil
	if not compact then
		local selectedUnit = units[1]
		for _, unit in ipairs(units) do
			if unit.name == selected then
				selectedUnit = unit
				break
			end
		end

		rightPanel = ui.column({ gap = 14, grow = 1 }, {
			portraitPanel(),
			ui.box({
				width = "100%",
				height = 120,
				style = panelStyle,
				draw = drawTelemetry,
			}),
			ui.box({
				width = 76,
				height = 76,
				interactive = false,
				draw = function(_, x, y, width, _, _, _, ctx)
					drawSweepGauge(ctx, x, y, width, selectedUnit.charge, selectedUnit.color)
					ctx:color({ 1, 1, 1, 1 })
					ctx:text(tostring(selectedUnit.charge), x + 27, y + 22)
					ctx:color({ 0.72, 0.82, 0.9, 1 })
					ctx:text("SYNC", x + 20, y + 42)
				end,
			}),
		})
	end

	return ui.stack({ width = viewport.width, height = viewport.height }, {
		ui.box({ position = "absolute", inset = 0, interactive = false, draw = drawGridBackground }),
		ui.column({ padding = 24, gap = 16, width = "100%", height = "100%" }, {
			ui.row({ gap = 12, align = "center" }, {
				ui.text("HUD PRIMITIVES", { style = { color = { 1, 1, 1, 1 } } }),
				ui.text("meter + shape + clip + stencil", { style = { color = { 0.72, 0.82, 0.9, 1 } } }),
			}),
			ui.row({ gap = 18, grow = 1 }, {
				cardRows,
				rightPanel,
			}),
			ui.text("Selected: " .. selected, { style = { color = ui.theme.accentColor } }),
		}),
	})
end

local function setup()
	if unregisterNavigate then
		unregisterNavigate()
	end

	unregisterNavigate = ui.on("navigate", function(_, target)
		local props = target and target.props or {}
		if props.unitName then
			selected = props.unitName
		end
	end)
end

local function teardown()
	if unregisterNavigate then
		unregisterNavigate()
		unregisterNavigate = nil
	end
end

local function navigateButton(button)
	if button == "dpup" then
		return ui.navigate("up")
	elseif button == "dpdown" then
		return ui.navigate("down")
	elseif button == "dpleft" then
		return ui.navigate("left")
	elseif button == "dpright" then
		return ui.navigate("right")
	elseif button == "a" then
		return ui.keypressed("return")
	end
end

return {
	id = "hud-primitives",
	label = "HUD Primitives",
	setup = setup,
	teardown = teardown,
	window = {
		width = 900,
		height = 580,
		title = "HUD Primitives - glyph.lua",
		resizable = true,
		breakpoints = { md = 760 },
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
	gamepadpressed = function(_, button)
		return navigateButton(button)
	end,
	component = function()
		return App()
	end,
}
