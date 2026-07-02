local ui = require("glyph")

local selected = "LOADOUT"
local App

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

local function hudButton(command, width)
	return ui.customButton({
		width = width,
		height = 76,
		active = selected == command.label,
		command = command.label,
		onClick = function()
			selected = command.label
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
			transition = {
				background = 0.12,
				color = 0.1,
				borderColor = 0.12,
			},
		},
		draw = function(_, x, y, buttonWidth, buttonHeight, love, style, ctx)
			local beat = ctx:pulse(5, tonumber(command.hotkey) or 0)
			local hot = ctx.hot
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
			ctx:text("Animated custom draw + hover/press style transitions", x + 18, y + 38)
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

	return ui.column({
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
end

local function setup()
	ui.setTheme(exampleTheme)
end

return {
	id = "hud-menu",
	label = "HUD Menu",
	description = "A neon command deck with custom drawing, animated selection, and d-pad friendly menu structure.",
	setup = setup,
	window = {
		width = 920,
		height = 620,
		resizable = true,
		minWidth = 520,
		minHeight = 460,
		breakpoints = { md = 760 },
	},
	component = function()
		return App()
	end,
}
