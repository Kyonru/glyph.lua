local ui = require("glyph")

local borderPulseShader = nil
local backgroundWaveShader = nil
local activeItemShader = nil

local function shaderTime(speed)
	return ui.time() * (speed or 1)
end

local function sendTime(shader, speed)
	if shader and shader.send then
		shader:send("time", shaderTime(speed))
	end
	return shader
end

local function backgroundShaderStyle()
	return sendTime(backgroundWaveShader, 1.6)
end

local function activeItemShaderStyle(node, runtime)
	if runtime and runtime.focusNode == node then
		return nil
	end
	return sendTime(activeItemShader, 4.4)
end

local buttonStyle = ui.style({
	background = { 0.12, 0.13, 0.16, 1 },
	borderColor = { 0.27, 0.3, 0.36, 1 },
	borderWidth = 1,
	focused = {
		background = { 0.18, 0.36, 0.62, 1 },
		borderColor = { 0.62, 0.82, 1, 1 },
		borderWidth = 2,
		color = { 0.96, 0.98, 1, 1 },
	},
})

local selectedButtonStyle = ui.style({
	background = { 0.16, 0.28, 0.22, 1 },
	borderColor = { 0.32, 0.58, 0.43, 1 },
	borderWidth = 1,
	focused = {
		background = { 0.18, 0.36, 0.62, 1 },
		borderColor = { 0.62, 0.82, 1, 1 },
		borderWidth = 2,
		color = { 0.96, 0.98, 1, 1 },
	},
})

local panelStyle = ui.style({
	background = { 0.08, 0.09, 0.11, 1 },
	borderColor = { 0.25, 0.28, 0.34, 1 },
	borderWidth = 1,
	radius = 6,
})

local accentPanelStyle = ui.style({
	background = { 0.1, 0.13, 0.12, 1 },
	borderColor = { 0.26, 0.48, 0.38, 1 },
	borderWidth = 1,
	radius = 6,
})

local classicPanelStyle = ui.style({
	background = { 0.04, 0.08, 0.25, 1 },
	borderColor = { 0.82, 0.88, 1, 1 },
	borderWidth = 2,
	radius = 4,
})

local classicButtonStyle = ui.style({
	background = { 0.06, 0.12, 0.34, 1 },
	borderColor = { 0.32, 0.42, 0.72, 1 },
	borderWidth = 1,
	color = { 0.94, 0.96, 1, 1 },
	focused = {
		background = { 0.82, 0.86, 1, 1 },
		borderColor = { 1, 1, 1, 1 },
		borderWidth = 2,
		color = { 0.04, 0.08, 0.25, 1 },
	},
})

local classicSelectedButtonStyle = ui.style({
	background = { 0.12, 0.25, 0.52, 1 },
	borderColor = { 0.68, 0.78, 1, 1 },
	borderWidth = 1,
	color = { 0.94, 0.96, 1, 1 },
	shader = activeItemShaderStyle,
	focused = {
		background = { 0.82, 0.86, 1, 1 },
		borderColor = { 1, 1, 1, 1 },
		borderWidth = 2,
		color = { 0.04, 0.08, 0.25, 1 },
	},
})

local function drawBorderPulsePanel(_, x, y, width, height, loveModule, style)
	local graphics = loveModule.graphics
	local radius = style.radius or 0
	local previousShader = graphics.getShader and graphics.getShader() or nil
	local previousLineWidth = graphics.getLineWidth and graphics.getLineWidth() or nil

	graphics.setColor(style.background)
	graphics.rectangle("fill", x, y, width, height, radius, radius)

	if borderPulseShader and graphics.setShader then
		borderPulseShader:send("time", shaderTime(3))
		graphics.setShader(borderPulseShader)
	end

	graphics.setColor(style.borderColor)
	if graphics.setLineWidth then
		graphics.setLineWidth(style.borderWidth or 1)
	end
	graphics.rectangle("line", x, y, width, height, radius, radius)

	if graphics.setShader then
		graphics.setShader(previousShader)
	end
	if previousLineWidth and graphics.setLineWidth then
		graphics.setLineWidth(previousLineWidth)
	end
end

local function setup()
	if not love or not love.graphics or not love.graphics.newShader then
		return
	end

	borderPulseShader = love.graphics.newShader([[
		extern number time;

		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
			vec4 pixel = Texel(texture, texture_coords) * color;
			number pulse = 0.5 + 0.5 * sin(time + screen_coords.x * 0.06 + screen_coords.y * 0.04);
			vec3 glow = mix(pixel.rgb, vec3(0.72, 0.90, 1.0), pulse * 0.65);
			return vec4(glow, pixel.a);
		}
	]])

	backgroundWaveShader = love.graphics.newShader([[
		extern number time;

		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
			vec4 pixel = Texel(texture, texture_coords) * color;
			number wave = 0.5 + 0.5 * sin(time + screen_coords.y * 0.055);
			number sweep = 0.5 + 0.5 * sin(time * 0.7 + screen_coords.x * 0.026);
			vec3 blue = pixel.rgb + (vec3(0.02, 0.05, 0.16) * wave + vec3(0.02, 0.03, 0.08) * sweep) * pixel.a;
			return vec4(blue, pixel.a);
		}
	]])

	activeItemShader = love.graphics.newShader([[
		extern number time;

		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
			vec4 pixel = Texel(texture, texture_coords) * color;
			number glow = 0.12 + 0.10 * sin(time + screen_coords.x * 0.08);
			return vec4(pixel.rgb + vec3(glow, glow * 0.85, glow * 0.35) * pixel.a, pixel.a);
		}
	]])
end

local function App()
	local activeTab, setActiveTab = ui.useState("Gear")
	local activeCategory, setActiveCategory = ui.useState("Weapons")
	local selected, setSelected = ui.useState("Rift Blade")
	local activeCommand, setActiveCommand = ui.useState("Attack")
	local openBattleSubmenu, setOpenBattleSubmenu = ui.useState(nil)
	local selectedSpell, setSelectedSpell = ui.useState("Fire")
	local selectedBattleItem, setSelectedBattleItem = ui.useState("Potion")
	local selectedTarget, setSelectedTarget = ui.useState("Ari")
	local submenuOpen, setSubmenuOpen = ui.useState(false)
	local lastAction, setLastAction = ui.useState("Ready")

	local function activate(label)
		setSelected(label)
		setLastAction(label)
	end

	local function btn(label, opts)
		opts = opts or {}
		return ui.button({
			label = label,
			width = opts.width or 96,
			height = opts.height or 34,
			grow = opts.grow,
			navGroup = opts.navGroup,
			style = opts.selected and selectedButtonStyle or buttonStyle,
			onClick = opts.onClick or function()
				activate(label)
			end,
		})
	end

	local function tab(label)
		return btn(label, {
			width = 92,
			selected = activeTab == label,
			navGroup = "top-tabs",
			onClick = function()
				setActiveTab(label)
				setLastAction("Tab: " .. label)
			end,
		})
	end

	local function category(label)
		return btn(label, {
			width = 126,
			selected = activeCategory == label,
			navGroup = "categories",
			onClick = function()
				setActiveCategory(label)
				setLastAction("Category: " .. label)
			end,
		})
	end

	local function item(label, width)
		return btn(label, {
			width = width or 116,
			navGroup = "inventory-grid",
			selected = selected == label,
		})
	end

	local commandOpeners = {}

	local function closeBattleSubmenu()
		setOpenBattleSubmenu(nil)
	end

	local function command(label, submenu)
		local node
		node = ui.button({
			label = label,
			width = 118,
			height = 32,
			navGroup = "battle-commands",
			style = activeCommand == label and classicSelectedButtonStyle or classicButtonStyle,
			onClick = function()
				setActiveCommand(label)
				if submenu then
					setOpenBattleSubmenu(submenu)
					setLastAction(label .. " menu")
				else
					closeBattleSubmenu()
					setLastAction(label .. " command")
				end
			end,
		})
		commandOpeners[submenu or label] = node
		return node
	end

	local function submenuChoice(label, opts)
		opts = opts or {}
		return ui.button({
			label = label,
			width = opts.width or 154,
			height = 32,
			navGroup = "battle-submenu",
			style = opts.selected and classicSelectedButtonStyle or classicButtonStyle,
			onClick = function()
				if opts.onPick then
					opts.onPick(label)
				end
				closeBattleSubmenu()
				if opts.opener then
					ui.setFocus(opts.opener)
				end
			end,
		})
	end

	local moreButton
	local flyout = nil

	moreButton = btn("More", {
		width = 92,
		navGroup = "bottom-actions",
		selected = submenuOpen,
		onClick = function()
			setSubmenuOpen(true)
			setLastAction("More")
		end,
	})

	if submenuOpen then
		flyout = ui.panel({
			position = "absolute",
			right = 24,
			bottom = 70,
			width = 190,
			gap = 8,
			padding = 10,
			navScope = true,
			navTrap = true,
			zIndex = 10,
			style = accentPanelStyle,
			onNavigateExit = function(direction)
				if direction == "left" or direction == "down" then
					setSubmenuOpen(false)
					return moreButton
				end
				return false
			end,
		}, {
			ui.text("Actions", { style = { color = ui.theme.mutedTextColor } }),
			btn("Compare", { width = 168, onClick = function() setLastAction("Compare " .. selected) end }),
			btn("Favorite", { width = 168, onClick = function() setLastAction("Favorite " .. selected) end }),
			btn("Salvage", { width = 168, onClick = function() setLastAction("Salvage " .. selected) end }),
		})
	end

	local attackCommand = command("Attack", "attack")
	local magicCommand = command("Magic", "magic")
	local itemCommand = command("Item", "item")
	local guardCommand = command("Guard")
	local runCommand = command("Run")

	local battleSubmenu = nil
	local battleSubmenuTitle = nil
	local battleSubmenuChoices = nil
	local battleSubmenuOpener = nil

	if openBattleSubmenu == "attack" then
		battleSubmenuTitle = "Target"
		battleSubmenuChoices = { "Ari", "Noa", "Drone A", "Drone B" }
		battleSubmenuOpener = commandOpeners.attack
	elseif openBattleSubmenu == "magic" then
		battleSubmenuTitle = "Magic"
		battleSubmenuChoices = { "Fire", "Blizzard", "Cure", "Thunder" }
		battleSubmenuOpener = commandOpeners.magic
	elseif openBattleSubmenu == "item" then
		battleSubmenuTitle = "Item"
		battleSubmenuChoices = { "Potion", "Ether", "Phoenix", "Elixir" }
		battleSubmenuOpener = commandOpeners.item
	end

	if battleSubmenuChoices then
		local choices = {
			ui.text(battleSubmenuTitle, { style = { color = { 0.94, 0.96, 1, 1 } } }),
		}
		for _, label in ipairs(battleSubmenuChoices) do
			local selectedChoice = label == selectedSpell or label == selectedBattleItem or label == selectedTarget
			choices[#choices + 1] = submenuChoice(label, {
				selected = selectedChoice,
				opener = battleSubmenuOpener,
				onPick = function(value)
					if openBattleSubmenu == "attack" then
						setSelectedTarget(value)
						setLastAction("Attack -> " .. value)
					elseif openBattleSubmenu == "magic" then
						setSelectedSpell(value)
						setLastAction("Magic -> " .. value)
					elseif openBattleSubmenu == "item" then
						setSelectedBattleItem(value)
						setLastAction("Item -> " .. value)
					end
				end,
			})
		end

		battleSubmenu = ui.column({
			position = "absolute",
			left = 344,
			bottom = 106,
			width = 180,
			gap = 6,
			padding = 8,
			zIndex = 8,
			navScope = true,
			navTrap = true,
			style = ui.composeStyles(classicPanelStyle, { shader = backgroundShaderStyle }),
			onNavigateExit = function(direction)
				if direction == "left" or direction == "down" then
					closeBattleSubmenu()
					return battleSubmenuOpener
				end
				return false
			end,
		}, choices)
	end

	local queuedBattle = activeCommand
	if activeCommand == "Attack" then
		queuedBattle = "Attack -> " .. selectedTarget
	elseif activeCommand == "Magic" then
		queuedBattle = "Magic -> " .. selectedSpell
	elseif activeCommand == "Item" then
		queuedBattle = "Item -> " .. selectedBattleItem
	end

	return ui.stack({ width = "100%", height = "100%" }, {
		ui.column({ padding = 24, gap = 14, width = "100%", height = "100%" }, {
			ui.row({ gap = 8, navGroup = "top-tabs" }, {
				tab("Gear"),
				tab("Stats"),
				tab("Map"),
				tab("Codex"),
				ui.box({ grow = 1, height = 1, interactive = false }),
				btn("Sort", { width = 78, navGroup = "top-tools", onClick = function() setLastAction("Sort") end }),
				btn("Filter", { width = 86, navGroup = "top-tools", onClick = function() setLastAction("Filter") end }),
			}),

			ui.row({ gap = 14, grow = 1 }, {
				ui.panel({ width = 150, height = "100%", gap = 8, navGroup = "categories", style = panelStyle }, {
					ui.text("Vault", { style = { color = ui.theme.mutedTextColor } }),
					category("Weapons"),
					category("Armor"),
					category("Relics"),
					category("Consumables"),
					category("Quest"),
				}),

				ui.panel({ grow = 1, height = "100%", gap = 10, style = panelStyle }, {
					ui.row({ gap = 8, navGroup = "inventory-grid" }, {
						item("Rift Blade", 124),
						item("Echo Wand", 116),
						item("Iron Pike", 108),
					}),
					ui.row({ gap = 8, navGroup = "inventory-grid" }, {
						item("Pulse Shield", 142),
						item("Wayfinder", 118),
					}),
					ui.row({ gap = 8, navGroup = "inventory-grid" }, {
						item("Mist Boots", 112),
						item("Sun Charm", 118),
						item("Field Kit", 100),
						item("Old Key", 88),
					}),
					ui.row({ gap = 10, navGroup = "battle-commands" }, {
						ui.column({ width = 148, gap = 6, padding = 8, style = classicPanelStyle, draw = drawBorderPulsePanel }, {
							ui.text("Command", { style = { color = { 0.94, 0.96, 1, 1 } } }),
							attackCommand,
							magicCommand,
							itemCommand,
							guardCommand,
							runCommand,
						}),
						ui.panel({ grow = 1, gap = 6, padding = 8, style = ui.composeStyles(classicPanelStyle, { shader = backgroundShaderStyle }) }, {
							ui.text("Party", { style = { color = { 0.94, 0.96, 1, 1 } } }),
							ui.row({ gap = 8 }, {
								ui.text("Ari", { style = { color = { 0.94, 0.96, 1, 1 } } }),
								ui.text("HP  482/520", { style = { color = { 0.72, 0.9, 1, 1 } } }),
								ui.text("MP  44/60", { style = { color = { 0.72, 0.9, 1, 1 } } }),
							}),
							ui.row({ gap = 8 }, {
								ui.text("Noa", { style = { color = { 0.94, 0.96, 1, 1 } } }),
								ui.text("HP  391/410", { style = { color = { 0.72, 0.9, 1, 1 } } }),
								ui.text("MP  78/88", { style = { color = { 0.72, 0.9, 1, 1 } } }),
							}),
							ui.text("Queued: " .. queuedBattle, { style = { color = { 1, 0.94, 0.68, 1 } } }),
						}),
					}),
					ui.text("Selected: " .. selected, { style = { color = ui.theme.accentColor } }),
				}),

				ui.panel({ width = 210, height = "100%", gap = 10, navGroup = "inspector", style = panelStyle }, {
					ui.text("Inspector", { style = { color = ui.theme.mutedTextColor } }),
					ui.text(selected),
					ui.text("Power  142", { style = { color = ui.theme.mutedTextColor } }),
					ui.text("Weight  7.4", { style = { color = ui.theme.mutedTextColor } }),
					btn("Equip", { width = 188, navGroup = "inspector", onClick = function() setLastAction("Equip " .. selected) end }),
					btn("Upgrade", { width = 188, navGroup = "inspector", onClick = function() setLastAction("Upgrade " .. selected) end }),
					btn("Inspect", { width = 188, navGroup = "inspector", onClick = function() setLastAction("Inspect " .. selected) end }),
				}),
			}),

			ui.row({ gap = 8, navGroup = "bottom-actions" }, {
				btn("Confirm", { width = 116, onClick = function() setLastAction("Confirm " .. selected) end }),
				btn("Cancel", { width = 96, onClick = function() setLastAction("Cancel") end }),
				moreButton,
				ui.box({ grow = 1, height = 1, interactive = false }),
				ui.text(lastAction, { style = { color = ui.theme.mutedTextColor } }),
			}),
		}),

		battleSubmenu,
		flyout,
	})
end

return {
	id = "navigate",
	label = "Navigation",
	setup = setup,
	window = { width = 860, height = 560, title = "Navigation - glyph.lua", resizable = true },
	install = {
		gamepad = true,
	},
	keypressed = function(key)
		if key == "up" then
			ui.navigate("up")
		elseif key == "down" then
			ui.navigate("down")
		elseif key == "left" then
			ui.navigate("left")
		elseif key == "right" then
			ui.navigate("right")
		end
	end,
	component = function()
		return App()
	end,
}
