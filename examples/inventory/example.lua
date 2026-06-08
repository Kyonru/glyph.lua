local ui = require("glyph")

local SPRITE_WIDTH = 16
local SPRITE_HEIGHT = 24

local SATCHEL_COLUMNS = 8
local SATCHEL_ROWS = 9
local SATCHEL_SLOT_COUNT = SATCHEL_COLUMNS * SATCHEL_ROWS
local SATCHEL_SLOT_SIZE = 58
local SLOT_GAP = 8

local PAGE_COLUMNS = 6
local PAGE_ROWS = 3
local PAGE_SIZE = PAGE_COLUMNS * PAGE_ROWS
local PAGE_SLOT_COUNT = PAGE_SIZE * 3
local PAGE_SLOT_SIZE = 72

local CASE_COLUMNS = 9
local CASE_ROWS = 6
local CASE_CELL = 52
local CASE_GAP = 4
local CASE_PADDING = 10
local CASE_GRID_PROPS = {
	columns = CASE_COLUMNS,
	cellWidth = CASE_CELL,
	cellHeight = CASE_CELL,
	gap = CASE_GAP,
	count = CASE_COLUMNS * CASE_ROWS,
}

local colors = {
	bg = { 0.025, 0.024, 0.023, 1 },
	stone = { 0.075, 0.082, 0.088, 0.98 },
	stoneDark = { 0.035, 0.038, 0.044, 0.98 },
	leatherDark = { 0.058, 0.038, 0.029, 0.98 },
	parchment = { 0.92, 0.82, 0.58, 1 },
	parchmentDim = { 0.66, 0.56, 0.39, 1 },
	gold = { 0.96, 0.66, 0.22, 1 },
	bronze = { 0.62, 0.39, 0.18, 1 },
	iron = { 0.36, 0.39, 0.42, 1 },
	ink = { 0.1, 0.078, 0.058, 1 },
	red = { 0.82, 0.19, 0.16, 1 },
	green = { 0.2, 0.72, 0.42, 1 },
	blue = { 0.28, 0.54, 0.92, 1 },
}

local rarityColors = {
	common = { 0.72, 0.68, 0.58, 1 },
	uncommon = { 0.25, 0.86, 0.48, 1 },
	rare = { 0.32, 0.58, 1, 1 },
	epic = { 0.68, 0.42, 1, 1 },
	legendary = { 1, 0.64, 0.18, 1 },
}

local rarityNames = {
	common = "common",
	uncommon = "uncommon",
	rare = "rare",
	epic = "epic",
	legendary = "legendary",
}

local potionSheet = nil
local potionSprites = nil
local potionPreviewAnimation = nil
local assetError = nil

local activeTab = 1
local currentPage = 1
local pointerX = 0
local pointerY = 0
local keyboardCarry = nil
local pendingDrag = nil
local drag = nil
local status = "Drag potions to reorganize the active inventory."
local statusTone = "neutral"
local feedbackParticles = {}
local feedbackBounds = {}
local offFeedback = nil

local satchelSlots = {}
local pageSlots = {}
local caseEntries = {}
local satchelBounds = {}
local pageBounds = {}
local caseBoardBounds = nil
local feedbackNodes = {}
local inventoryDragStart = nil
local validCasePlacement = nil

local catalog = {
	{ id = "minor_health", name = "Minor Health", quad = 1, rarity = "common", count = 9 },
	{ id = "field_health", name = "Field Health", quad = 2, rarity = "common", count = 6 },
	{ id = "major_health", name = "Major Health", quad = 3, rarity = "uncommon", count = 4 },
	{ id = "royal_health", name = "Royal Health", quad = 4, rarity = "rare", count = 2 },
	{ id = "ember_health", name = "Ember Health", quad = 5, rarity = "epic", count = 1 },
	{ id = "mana_vial", name = "Mana Vial", quad = 11, rarity = "common", count = 8 },
	{ id = "mana_flask", name = "Mana Flask", quad = 12, rarity = "uncommon", count = 5 },
	{ id = "astral_mana", name = "Astral Mana", quad = 13, rarity = "rare", count = 3 },
	{ id = "deep_mana", name = "Deep Mana", quad = 14, rarity = "epic", count = 1 },
	{ id = "stamina_draught", name = "Stamina Draught", quad = 21, rarity = "common", count = 7 },
	{ id = "swift_tonic", name = "Swift Tonic", quad = 22, rarity = "uncommon", count = 4 },
	{ id = "giant_tonic", name = "Giant Tonic", quad = 23, rarity = "rare", count = 2 },
	{ id = "stone_skin", name = "Stone Skin", quad = 24, rarity = "rare", count = 2 },
	{ id = "dragon_breath", name = "Dragon Breath", quad = 25, rarity = "legendary", count = 1 },
	{ id = "antidote", name = "Antidote", quad = 31, rarity = "common", count = 6 },
	{ id = "cleanse", name = "Cleanse", quad = 32, rarity = "uncommon", count = 3 },
	{ id = "night_eye", name = "Night Eye", quad = 33, rarity = "rare", count = 2 },
	{ id = "ghost_step", name = "Ghost Step", quad = 34, rarity = "epic", count = 1 },
	{ id = "sun_bloom", name = "Sun Bloom", quad = 35, rarity = "legendary", count = 1 },
	{ id = "frost_ward", name = "Frost Ward", quad = 41, rarity = "uncommon", count = 4 },
	{ id = "flame_ward", name = "Flame Ward", quad = 42, rarity = "uncommon", count = 4 },
	{ id = "storm_ward", name = "Storm Ward", quad = 43, rarity = "rare", count = 2 },
	{ id = "spirit_ward", name = "Spirit Ward", quad = 44, rarity = "epic", count = 1 },
	{ id = "wyrm_ward", name = "Wyrm Ward", quad = 45, rarity = "legendary", count = 1 },
	{ id = "focus_phial", name = "Focus Phial", quad = 51, rarity = "common", count = 5 },
	{ id = "sage_phial", name = "Sage Phial", quad = 52, rarity = "uncommon", count = 4 },
	{ id = "oracle_drop", name = "Oracle Drop", quad = 53, rarity = "rare", count = 2 },
	{ id = "moon_salve", name = "Moon Salve", quad = 54, rarity = "epic", count = 1 },
	{ id = "phoenix_seed", name = "Phoenix Seed", quad = 55, rarity = "legendary", count = 1 },
	{ id = "iron_bark", name = "Iron Bark", quad = 61, rarity = "common", count = 4 },
	{ id = "silver_bark", name = "Silver Bark", quad = 62, rarity = "uncommon", count = 3 },
	{ id = "aether_bark", name = "Aether Bark", quad = 63, rarity = "rare", count = 2 },
	{ id = "void_bark", name = "Void Bark", quad = 64, rarity = "epic", count = 1 },
	{ id = "king_bark", name = "King Bark", quad = 65, rarity = "legendary", count = 1 },
	{ id = "quick_mend", name = "Quick Mend", quad = 71, rarity = "common", count = 10 },
	{ id = "battle_mend", name = "Battle Mend", quad = 72, rarity = "uncommon", count = 5 },
	{ id = "war_mend", name = "War Mend", quad = 73, rarity = "rare", count = 3 },
	{ id = "crown_mend", name = "Crown Mend", quad = 74, rarity = "epic", count = 1 },
	{ id = "ancient_mend", name = "Ancient Mend", quad = 75, rarity = "legendary", count = 1 },
	{ id = "mist_bottle", name = "Mist Bottle", quad = 81, rarity = "common", count = 5 },
	{ id = "thorn_bottle", name = "Thorn Bottle", quad = 82, rarity = "uncommon", count = 4 },
	{ id = "rift_bottle", name = "Rift Bottle", quad = 83, rarity = "rare", count = 2 },
}

local itemById = {}
for _, item in ipairs(catalog) do
	itemById[item.id] = item
end

local exampleTheme = {
	backgroundColor = colors.bg,
	surfaceColor = colors.stone,
	surfaceHoverColor = { 0.15, 0.12, 0.078, 0.98 },
	surfacePressedColor = { 0.09, 0.06, 0.045, 0.98 },
	borderColor = colors.bronze,
	textColor = colors.parchment,
	mutedTextColor = colors.parchmentDim,
	accentColor = colors.gold,
	accentTextColor = colors.ink,
	fontSize = 13,
	lineHeight = 18,
	radius = 5,
	components = {
		button = {
			background = { 0.12, 0.078, 0.048, 0.96 },
			color = colors.parchment,
			borderColor = { 0.72, 0.48, 0.22, 0.72 },
			borderWidth = 1,
			radius = 5,
			hover = { background = { 0.18, 0.12, 0.07, 0.98 }, borderColor = colors.gold },
			focused = { background = { 0.18, 0.12, 0.07, 0.98 }, borderColor = colors.gold },
			pressed = { background = { 0.08, 0.05, 0.035, 0.98 } },
			active = { background = { 0.28, 0.18, 0.07, 0.98 }, color = { 1, 0.88, 0.55, 1 } },
		},
		tab = {
			background = { 0.08, 0.058, 0.044, 0.96 },
			color = colors.parchmentDim,
			borderColor = { 0.54, 0.35, 0.15, 0.76 },
			borderWidth = 1,
			radius = 5,
			hover = { background = { 0.15, 0.1, 0.06, 0.98 }, color = colors.parchment },
			focused = { background = { 0.15, 0.1, 0.06, 0.98 }, color = colors.parchment, borderColor = colors.gold },
			pressed = { background = { 0.07, 0.046, 0.032, 0.98 } },
			active = { background = { 0.33, 0.22, 0.09, 0.98 }, color = { 1, 0.88, 0.56, 1 } },
		},
		scrollBar = {
			width = 8,
			padding = 4,
			radius = 4,
			trackColor = { 0.025, 0.02, 0.016, 0.8 },
			thumbColor = { 0.72, 0.48, 0.22, 0.9 },
		},
	},
	typography = {
		h1 = { fontSize = 28, lineHeight = 34 },
		h2 = { fontSize = 22, lineHeight = 28 },
		caption = { fontSize = 11, lineHeight = 15 },
		button = { fontSize = 14, lineHeight = 18 },
	},
}

local function setStatus(text, tone)
	status = text
	statusTone = tone or "neutral"
end

local function toneColor()
	if statusTone == "good" then
		return colors.green
	elseif statusTone == "bad" then
		return colors.red
	elseif statusTone == "hint" then
		return colors.blue
	end
	return colors.parchmentDim
end

local function readBytes(path)
	local loveModule = _G.love
	if loveModule and loveModule.filesystem and loveModule.filesystem.getInfo and loveModule.filesystem.getInfo(path) then
		return loveModule.filesystem.read(path)
	end

	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local data = file:read("*a")
	file:close()
	return data
end

local function imageFromBytes(data)
	local loveModule = _G.love
	if
		not data
		or not loveModule
		or not loveModule.filesystem
		or not loveModule.filesystem.newFileData
		or not loveModule.image
		or not loveModule.image.newImageData
		or not loveModule.graphics
	then
		return nil
	end

	local ok, image = pcall(function()
		local fileData = loveModule.filesystem.newFileData(data, "potions.png")
		local imageData = loveModule.image.newImageData(fileData)
		return loveModule.graphics.newImage(imageData)
	end)
	if ok then
		return image
	end
	return nil
end

local function loadPotionSheet()
	if assetError then
		return
	end

	local loveModule = _G.love
	if not loveModule or not loveModule.graphics then
		return
	end

	if not potionSheet then
		local candidates = {
			"potions.png",
			"inventory/potions.png",
			"examples/inventory/potions.png",
			"../inventory/potions.png",
		}

		for _, path in ipairs(candidates) do
			local ok, image = pcall(loveModule.graphics.newImage, path)
			if ok and image then
				potionSheet = image
				break
			end

			local data = readBytes(path)
			image = imageFromBytes(data)
			if image then
				potionSheet = image
				break
			end
		end
	end

	if not potionSheet then
		assetError = "Could not load examples/inventory/potions.png"
		return
	end

	if potionSheet.setFilter then
		potionSheet:setFilter("nearest", "nearest")
	end

	if not potionSprites then
		local okAnim8, anim8 = pcall(require, "feel.vendor.anim8")
		potionSprites = ui.spriteSheet(potionSheet, {
			frameWidth = SPRITE_WIDTH,
			frameHeight = SPRITE_HEIGHT,
			anim8 = okAnim8 and anim8 or nil,
		})

		if okAnim8 then
			local okAnimation, animation = pcall(function()
				return potionSprites:animation({ "1-4", 1 }, 0.14)
			end)
			if okAnimation then
				potionPreviewAnimation = animation
			end
		end
	end
end

local function resetArrangements()
	satchelSlots = {}
	pageSlots = {}

	for index = 1, SATCHEL_SLOT_COUNT do
		local item = catalog[index]
		if item then
			satchelSlots[index] = item.id
		else
			satchelSlots[index] = nil
		end
	end

	satchelSlots[7], satchelSlots[29], satchelSlots[43], satchelSlots[58] = nil, nil, nil, nil
	satchelSlots[60] = "minor_health"
	satchelSlots[63] = "mana_vial"

	for index = 1, PAGE_SLOT_COUNT do
		local item = catalog[index]
		pageSlots[index] = item and item.id or nil
	end
	pageSlots[PAGE_SIZE + 4] = nil
	pageSlots[PAGE_SIZE * 2 - 1] = "quick_mend"

	caseEntries = {
		{ id = "case-1", itemId = "royal_health", col = 1, row = 1, w = 2, h = 2 },
		{ id = "case-2", itemId = "mana_flask", col = 3, row = 1, w = 1, h = 2 },
		{ id = "case-3", itemId = "dragon_breath", col = 4, row = 1, w = 2, h = 1 },
		{ id = "case-4", itemId = "stone_skin", col = 6, row = 1, w = 3, h = 2 },
		{ id = "case-5", itemId = "antidote", col = 1, row = 3, w = 1, h = 2 },
		{ id = "case-6", itemId = "swift_tonic", col = 2, row = 3, w = 2, h = 1 },
		{ id = "case-7", itemId = "ghost_step", col = 4, row = 3, w = 1, h = 3 },
		{ id = "case-8", itemId = "frost_ward", col = 5, row = 3, w = 2, h = 2 },
		{ id = "case-9", itemId = "oracle_drop", col = 7, row = 3, w = 2, h = 1 },
		{ id = "case-10", itemId = "phoenix_seed", col = 8, row = 4, w = 2, h = 2 },
	}

	activeTab = 1
	currentPage = 1
	keyboardCarry = nil
	pendingDrag = nil
	drag = nil
	satchelBounds = {}
	pageBounds = {}
	caseBoardBounds = nil
	feedbackNodes = {}
	setStatus("Drag potions to reorganize the active inventory.", "neutral")
end

local function metrics(mode)
	local viewport = ui.viewport()
	local showcaseInset = mode == "showcase" and 188 or 0
	local margin = 18
	local usableHeight = math.max(540, viewport.height - margin * 2)
	local contentHeight = math.max(420, usableHeight - 72 - 12 - 40)
	local contentWidth = math.max(0, viewport.width - (margin + showcaseInset) - margin)

	return {
		width = viewport.width,
		height = viewport.height,
		margin = margin,
		left = margin + showcaseInset,
		right = margin,
		contentWidth = contentWidth,
		contentHeight = contentHeight,
		caseBoardWidth = CASE_PADDING * 2 + CASE_COLUMNS * CASE_CELL + (CASE_COLUMNS - 1) * CASE_GAP,
		caseBoardHeight = CASE_PADDING * 2 + CASE_ROWS * CASE_CELL + (CASE_ROWS - 1) * CASE_GAP,
	}
end

local function withLineWidth(graphics, width, fn)
	local previous = graphics and graphics.getLineWidth and graphics.getLineWidth() or nil
	if graphics and graphics.setLineWidth and width then
		graphics.setLineWidth(width)
	end
	fn()
	if graphics and graphics.setLineWidth and previous then
		graphics.setLineWidth(previous)
	end
end

local function drawBackdrop(_, x, y, width, height, loveModule, _, ctx)
	local g = loveModule.graphics
	ctx:color(colors.bg)
	ctx:rect("fill", x, y, width, height)

	for row = -20, height + 40, 28 do
		local offset = (row % 56 == 0) and 0 or 18
		ctx:color({ 1, 0.86, 0.48, 0.026 })
		ctx:line(x + offset, y + row, x + width, y + row + width * 0.12)
	end

	for column = 0, width + 64, 64 do
		ctx:color({ 0.3, 0.42, 0.44, 0.04 })
		ctx:rect("fill", x + column, y, 1, height)
	end

	ctx:color({ 0, 0, 0, 0.22 })
	ctx:rect("fill", x, y, width, 82)
	ctx:rect("fill", x, y + height - 110, width, 110)

	if g.setLineWidth then
		withLineWidth(g, 2, function()
			ctx:color({ 0.9, 0.6, 0.22, 0.11 })
			ctx:line(x + 18, y + 18, x + width - 18, y + 18)
			ctx:line(x + 18, y + height - 18, x + width - 18, y + height - 18)
		end)
	end
end

local function drawPanelFrame(_, x, y, width, height, loveModule, _, ctx)
	local g = loveModule.graphics
	ctx:color(colors.stoneDark)
	ctx:rect("fill", x, y, width, height, 7)
	ctx:color(colors.leatherDark, 0.84)
	ctx:rect("fill", x + 5, y + 5, width - 10, height - 10, 5)
	ctx:color({ 1, 1, 1, 0.035 })
	ctx:rect("fill", x + 7, y + 7, width - 14, math.max(0, height * 0.38), 4)

	withLineWidth(g, 2, function()
		ctx:color(colors.bronze)
		ctx:rect("line", x + 1, y + 1, width - 2, height - 2, 7)
		ctx:color({ 1, 0.78, 0.35, 0.45 })
		ctx:rect("line", x + 5, y + 5, width - 10, height - 10, 5)
	end)

	local ornament = 12
	ctx:color(colors.gold, 0.82)
	ctx:polygon("fill", { x + 12, y + 4, x + 12 + ornament, y + 4, x + 8, y + 4 + ornament })
	ctx:polygon("fill", { x + width - 12, y + 4, x + width - 12 - ornament, y + 4, x + width - 8, y + 4 + ornament })
	ctx:polygon("fill", { x + 12, y + height - 4, x + 12 + ornament, y + height - 4, x + 8, y + height - 4 - ornament })
	ctx:polygon("fill", { x + width - 12, y + height - 4, x + width - 12 - ornament, y + height - 4, x + width - 8, y + height - 4 - ornament })
end

local function panel(props, children)
	props = props or {}
	props.draw = props.draw or drawPanelFrame
	props.style = props.style or {}
	props.style.background = props.style.background or { 0, 0, 0, 0 }
	props.style.borderColor = props.style.borderColor or { 0, 0, 0, 0 }
	props.style.borderWidth = props.style.borderWidth or 0
	return ui.box(props, children)
end

local function drawHeader(_, x, y, width, height, loveModule, _, ctx)
	drawPanelFrame(_, x, y, width, height, loveModule, _, ctx)
	ctx:color({ 0, 0, 0, 0.22 })
	ctx:rect("fill", x + 12, y + height - 14, width - 24, 1)
	ctx:color(colors.gold, 0.5)
	ctx:rect("fill", x + 12, y + 12, width - 24, 1)
end

local function itemFor(id)
	return id and itemById[id] or nil
end

local function itemImageNode(item, props)
	props = props or {}
	if not potionSheet or not potionSprites or not item then
		return ui.box({
			position = props.position,
			left = props.left,
			top = props.top,
			right = props.right,
			bottom = props.bottom,
			width = props.width,
			height = props.height,
			interactive = false,
			draw = function(_, x, y, width, height, _, _, ctx)
				ctx:color(rarityColors[item and item.rarity or "common"], 0.45)
				ctx:rect("fill", x + 4, y + 4, width - 8, height - 8, 4)
			end,
		})
	end

	return ui.image({
		source = potionSheet,
		quad = potionSprites:quad(item.quad),
		fit = "contain",
		tint = props.tint or { 1, 1, 1, props.opacity or 1 },
		position = props.position,
		left = props.left,
		top = props.top,
		right = props.right,
		bottom = props.bottom,
		width = props.width,
		height = props.height,
		interactive = false,
		accessibilityHidden = true,
	})
end

local function pointIn(bounds, x, y)
	return bounds
		and x >= bounds.x
		and y >= bounds.y
		and x <= bounds.x + bounds.width
		and y <= bounds.y + bounds.height
end

local function recordBounds(store, index, x, y, width, height)
	store[index] = {
		x = x,
		y = y,
		width = width,
		height = height,
	}
end

local function findSlotAt(store, x, y)
	for index, bounds in pairs(store) do
		if pointIn(bounds, x, y) then
			return index
		end
	end
	return nil
end

local function swapSlots(slots, a, b)
	if not a or not b or a == b then
		return
	end
	slots[a], slots[b] = slots[b], slots[a]
end

local function markDirty()
	if ui.runtime and ui.runtime.markDirty then
		ui.runtime:markDirty()
	end
end

local function copyColor(color, alpha)
	color = color or colors.gold
	return {
		color[1] or 1,
		color[2] or 1,
		color[3] or 1,
		(color[4] or 1) * (alpha or 1),
	}
end

local function boundsCenter(bounds)
	if not bounds then
		if pointerX == 0 and pointerY == 0 then
			local viewport = ui.viewport()
			return viewport.width / 2, viewport.height / 2
		end
		return pointerX, pointerY
	end
	return bounds.x + bounds.width / 2, bounds.y + bounds.height / 2
end

local function pointToBoundsCenter(bounds)
	if bounds then
		pointerX, pointerY = boundsCenter(bounds)
	end
end

local function boundsForNode(node)
	local key = node and node.props and node.props.key or nil
	return key and feedbackBounds[key] or nil
end

local function recordFeedbackNode(node, bounds)
	local key = node and node.props and node.props.key or nil
	if key then
		feedbackBounds[key] = bounds
		feedbackNodes[key] = node
	end
end

local function spawnFeedbackParticles(bounds, opts)
	opts = opts or {}
	local cx, cy = boundsCenter(bounds)
	local count = opts.count or 8
	local color = opts.color or colors.gold
	local speed = opts.speed or 56
	local spread = opts.spread or 1

	for index = 1, count do
		local angle = (index / count) * math.pi * 2 + math.random() * 0.45
		local velocity = speed * (0.45 + math.random() * 0.75) * spread
		feedbackParticles[#feedbackParticles + 1] = {
			x = cx + (math.random() - 0.5) * ((bounds and bounds.width or 20) * 0.5),
			y = cy + (math.random() - 0.5) * ((bounds and bounds.height or 20) * 0.5),
			vx = math.cos(angle) * velocity,
			vy = math.sin(angle) * velocity - 18,
			life = opts.life or (0.34 + math.random() * 0.18),
			age = 0,
			size = opts.size or (2 + math.random() * 3),
			color = copyColor(color, opts.opacity or 1),
		}
	end
	markDirty()
end

local function handleFeedbackEvent(event)
	if type(event) ~= "table" or type(event.kind) ~= "string" or not event.kind:match("^inventory%.") then
		return
	end

	local payload = event.payload or {}
	local bounds = boundsForNode(event.node)
	if event.kind == "inventory.glint" then
		spawnFeedbackParticles(bounds, {
			count = payload.count or 3,
			color = payload.color or colors.gold,
			speed = 34,
			life = 0.24,
			size = 2,
			opacity = 0.86,
		})
	elseif event.kind == "inventory.spark" then
		spawnFeedbackParticles(bounds, {
			count = payload.count or 5,
			color = payload.color or colors.blue,
			speed = 44,
			life = 0.28,
			size = 2.4,
			opacity = 0.78,
		})
	elseif event.kind == "inventory.drop.good" then
		spawnFeedbackParticles(nil, {
			count = payload.count or 16,
			color = payload.color or colors.green,
			speed = 82,
			spread = 1.2,
			life = 0.42,
			size = 3,
		})
	elseif event.kind == "inventory.drop.bad" then
		spawnFeedbackParticles(nil, {
			count = payload.count or 12,
			color = payload.color or colors.red,
			speed = 70,
			spread = 0.8,
			life = 0.3,
			size = 2.5,
		})
	end
end

local function updateFeedbackParticles(dt)
	if #feedbackParticles == 0 then
		return
	end

	local write = 1
	for read = 1, #feedbackParticles do
		local particle = feedbackParticles[read]
		particle.age = particle.age + dt
		if particle.age < particle.life then
			particle.vy = particle.vy + 92 * dt
			particle.x = particle.x + particle.vx * dt
			particle.y = particle.y + particle.vy * dt
			feedbackParticles[write] = particle
			write = write + 1
		end
	end
	for index = write, #feedbackParticles do
		feedbackParticles[index] = nil
	end
	markDirty()
end

local function drawFeedbackParticles(_, _, _, _, _, _, _, ctx)
	for _, particle in ipairs(feedbackParticles) do
		local t = math.max(0, 1 - particle.age / particle.life)
		ctx:color(particle.color, t)
		ctx:rect("fill", particle.x - particle.size / 2, particle.y - particle.size / 2, particle.size, particle.size, 2)
	end
end

local function feedbackOverlay()
	if #feedbackParticles == 0 then
		return nil
	end

	local viewport = ui.viewport()
	return ui.portal({
		left = 0,
		top = 0,
		width = viewport.width,
		height = viewport.height,
		zIndex = 470,
		interactive = false,
		draw = drawFeedbackParticles,
	})
end

local function playNodeFeedback(name, node, trigger)
	ui.feedback.play(name, node, {
		trigger = trigger or "manual",
		restart = true,
		key = name,
	})
end

local function previewDrag()
	return drag or pendingDrag or keyboardCarry
end

local function defineInventoryFeedback()
	ui.feedback.clear()
	ui.feedback.define("inventory.slot.hover", {
		{
			kind = "parallel",
			steps = {
				{ kind = "animate", to = { scale = 1.025, y = -1 }, duration = 0.08, ease = "quadout" },
				{
					kind = "random",
					options = {
						{ weight = 4, step = { kind = "emit", event = "inventory.glint", payload = { count = 2, color = colors.gold } } },
						{ weight = 1, step = { kind = "emit", event = "inventory.spark", payload = { count = 3, color = colors.blue } } },
					},
				},
			},
		},
		{ kind = "animate", to = { scale = 1, y = 0 }, duration = 0.14, ease = "backout" },
	})
	ui.feedback.define("inventory.slot.focus", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-focus" },
			{ kind = "emit", event = "inventory.glint", payload = { count = 2, color = colors.parchment } },
			{ kind = "animate", to = { scale = 1.035 }, duration = 0.09, ease = "quadout" },
		} },
		{ kind = "animate", to = { scale = 1 }, duration = 0.16, ease = "backout" },
	})
	ui.feedback.define("inventory.slot.press", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-press" },
			{ kind = "animate", to = { scale = 0.94, y = 1 }, duration = 0.055, ease = "quadin" },
		} },
	})
	ui.feedback.define("inventory.slot.release", {
		{ kind = "animate", to = { scale = 1, y = 0 }, duration = 0.13, ease = "backout" },
	})
	ui.feedback.define("inventory.slot.activate", {
		{ kind = "play", name = "inventory.slot.release", opts = { restart = true, key = "slot.release" } },
		{ kind = "emit", event = "inventory.spark", payload = { count = 6, color = colors.gold } },
	})
	ui.feedback.define("inventory.empty.activate", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-empty" },
			{ kind = "emit", event = "inventory.glint", payload = { count = 1, color = colors.iron } },
			{ kind = "animate", to = { opacity = 0.72 }, duration = 0.06 },
		} },
		{ kind = "animate", to = { opacity = 1 }, duration = 0.16 },
	})
	ui.feedback.define("inventory.drag.start", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-lift" },
			{ kind = "emit", event = "inventory.glint", payload = { count = 4, color = colors.gold } },
			{ kind = "animate", to = { scale = 1.06, y = -2 }, duration = 0.08, ease = "quadout" },
		} },
	})
	ui.feedback.define("inventory.drop.good", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-drop-good" },
			{ kind = "emit", event = "inventory.drop.good", payload = { count = 18, color = colors.green } },
			{
				kind = "repeat",
				count = 1,
				step = {
					{ kind = "animate", to = { scale = 1.09, y = -1 }, duration = 0.06, ease = "quadout" },
					{ kind = "animate", to = { scale = 1, y = 0 }, duration = 0.16, ease = "backout" },
				},
			},
		} },
	})
	ui.feedback.define("inventory.drop.bad", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-drop-bad" },
			{ kind = "emit", event = "inventory.drop.bad", payload = { count = 12, color = colors.red } },
			{
				kind = "repeat",
				count = 2,
				step = {
					{ kind = "animate", to = { x = -5 }, duration = 0.035, ease = "quadout" },
					{ kind = "animate", to = { x = 5 }, duration = 0.035, ease = "quadout" },
				},
			},
		} },
		{ kind = "animate", to = { x = 0, scale = 1, y = 0 }, duration = 0.09, ease = "backout" },
	})
	ui.feedback.define("inventory.nav.change", {
		{ kind = "parallel", steps = {
			{ kind = "audio", cue = "inventory-page" },
			{ kind = "emit", event = "inventory.glint", payload = { count = 3, color = colors.parchment } },
		} },
	})
end

local function updateDragPointer(ctx)
	pointerX = ctx.x or pointerX
	pointerY = ctx.y or pointerY
	if drag then
		markDirty()
	end
end

local function focusedBounds()
	local node = ui.runtime and ui.runtime.focusNode or nil
	return boundsForNode(node)
end

local function carryBounds(carry)
	if not carry then
		return nil
	end
	if carry.kind == "case" and caseBoardBounds then
		local stride = CASE_CELL + CASE_GAP
		local width = carry.entry.w * CASE_CELL + (carry.entry.w - 1) * CASE_GAP
		local height = carry.entry.h * CASE_CELL + (carry.entry.h - 1) * CASE_GAP
		return {
			x = caseBoardBounds.x + ((carry.candidateCol or carry.entry.col) - 1) * stride,
			y = caseBoardBounds.y + ((carry.candidateRow or carry.entry.row) - 1) * stride,
			width = width,
			height = height,
		}
	end
	return focusedBounds() or boundsForNode(carry.sourceNode) or carry.sourceBounds
end

local function cancelKeyboardCarry()
	if not keyboardCarry then
		return false
	end
	setStatus("Placement cancelled.", "neutral")
	keyboardCarry = nil
	markDirty()
	return true
end

local function moveCaseCarry(direction)
	if not keyboardCarry or keyboardCarry.kind ~= "case" then
		return false
	end

	local dx, dy = 0, 0
	if direction == "left" then
		dx = -1
	elseif direction == "right" then
		dx = 1
	elseif direction == "up" then
		dy = -1
	elseif direction == "down" then
		dy = 1
	else
		return false
	end

	local maxCol = CASE_COLUMNS - keyboardCarry.entry.w + 1
	local maxRow = CASE_ROWS - keyboardCarry.entry.h + 1
	keyboardCarry.candidateCol = math.max(1, math.min(maxCol, (keyboardCarry.candidateCol or keyboardCarry.entry.col) + dx))
	keyboardCarry.candidateRow = math.max(1, math.min(maxRow, (keyboardCarry.candidateRow or keyboardCarry.entry.row) + dy))
	local valid = validCasePlacement(keyboardCarry.entry, keyboardCarry.candidateCol, keyboardCarry.candidateRow)
	setStatus(valid and "Space is open. Press Enter or A to place." or "That space collides. Move to a clear area.", valid and "hint" or "bad")
	markDirty()
	return true
end

local function startUniformDrag(kind, sourceIndex, itemId, x, y, button, node)
	local item = itemFor(itemId)
	if not item then
		return
	end
	local data = {
		kind = kind,
		sourceIndex = sourceIndex,
		itemId = itemId,
		item = item,
		page = currentPage,
		size = kind == "page" and PAGE_SLOT_SIZE or SATCHEL_SLOT_SIZE,
		sourceNode = node,
	}
	keyboardCarry = nil
	pendingDrag = data
	pointerX = x
	pointerY = y
	if inventoryDragStart then
		inventoryDragStart(x, y, button or 1, node, data)
	end
	markDirty()
end

local function rectsOverlap(a, b)
	return a.col < b.col + b.w
		and b.col < a.col + a.w
		and a.row < b.row + b.h
		and b.row < a.row + a.h
end

function validCasePlacement(entry, col, row)
	if not entry or not col or not row then
		return false
	end
	if col < 1 or row < 1 or col + entry.w - 1 > CASE_COLUMNS or row + entry.h - 1 > CASE_ROWS then
		return false
	end

	local candidate = { col = col, row = row, w = entry.w, h = entry.h }
	for _, other in ipairs(caseEntries) do
		if other.id ~= entry.id and rectsOverlap(candidate, other) then
			return false
		end
	end
	return true
end

local function pointerCell()
	if not caseBoardBounds then
		return nil, nil
	end

	local cell = ui.grid.pointToCell(caseBoardBounds, CASE_GRID_PROPS, pointerX, pointerY)
	if not cell then
		return nil, nil
	end

	return cell.column, cell.row
end

local function caseCandidate()
	if keyboardCarry and keyboardCarry.kind == "case" then
		local col = keyboardCarry.candidateCol or keyboardCarry.entry.col
		local row = keyboardCarry.candidateRow or keyboardCarry.entry.row
		return {
			entry = keyboardCarry.entry,
			col = col,
			row = row,
			valid = validCasePlacement(keyboardCarry.entry, col, row),
		}
	end

	if not drag or drag.kind ~= "case" then
		return nil
	end

	local col, row = pointerCell()
	if not col or not row then
		return {
			entry = drag.entry,
			col = nil,
			row = nil,
			valid = false,
		}
	end

	col = col - (drag.anchorCol or 1) + 1
	row = row - (drag.anchorRow or 1) + 1

	return {
		entry = drag.entry,
		col = col,
		row = row,
		valid = validCasePlacement(drag.entry, col, row),
	}
end

local function startCaseDrag(entry, x, y, button, node)
	local item = itemFor(entry.itemId)
	if not item then
		return
	end

	local anchorCol = 1
	local anchorRow = 1
	if caseBoardBounds then
		local stride = CASE_CELL + CASE_GAP
		local itemX = caseBoardBounds.x + (entry.col - 1) * stride
		local itemY = caseBoardBounds.y + (entry.row - 1) * stride
		anchorCol = math.max(1, math.min(entry.w, math.floor((x - itemX) / stride) + 1))
		anchorRow = math.max(1, math.min(entry.h, math.floor((y - itemY) / stride) + 1))
	end

	local data = {
		kind = "case",
		entryId = entry.id,
		entry = entry,
		itemId = entry.itemId,
		item = item,
		size = math.min(92, CASE_CELL * math.max(entry.w, entry.h)),
		anchorCol = anchorCol,
		anchorRow = anchorRow,
		sourceNode = node,
	}
	keyboardCarry = nil
	pendingDrag = data
	pointerX = x
	pointerY = y
	if inventoryDragStart then
		inventoryDragStart(x, y, button or 1, node, data)
	end
	markDirty()
end

local function finishDrag(ctx)
	if not drag then
		return
	end

	local sourceNode = drag.sourceNode
	local targetNode = ctx and ctx.targetNode or nil
	local accepted = false
	if drag.kind == "satchel" then
		local target = findSlotAt(satchelBounds, pointerX, pointerY)
		if target then
			swapSlots(satchelSlots, drag.sourceIndex, target)
			setStatus("Satchel reordered.", "good")
			targetNode = feedbackNodes["satchel-slot-" .. tostring(target)] or targetNode
			accepted = true
		else
			setStatus("Satchel drop missed the grid.", "bad")
		end
	elseif drag.kind == "page" then
		local target = findSlotAt(pageBounds, pointerX, pointerY)
		if target and drag.page == currentPage then
			swapSlots(pageSlots, drag.sourceIndex, target)
			setStatus("Page slot updated.", "good")
			targetNode = feedbackNodes["page-slot-" .. tostring(target)] or targetNode
			accepted = true
		else
			setStatus("Drop inside the current page.", "bad")
		end
	elseif drag.kind == "case" then
		local candidate = caseCandidate()
		if candidate and candidate.valid then
			drag.entry.col = candidate.col
			drag.entry.row = candidate.row
			setStatus("Case placement accepted.", "good")
			targetNode = feedbackNodes["case-entry-" .. tostring(drag.entry.id)] or targetNode
			accepted = true
		else
			setStatus("That space is blocked or outside the case.", "bad")
		end
	end

	local feedbackNode = accepted and (targetNode or sourceNode) or (sourceNode or targetNode)
	playNodeFeedback(accepted and "inventory.drop.good" or "inventory.drop.bad", feedbackNode, accepted and "drop" or "error")
	drag = nil
	pendingDrag = nil
	markDirty()
end

inventoryDragStart = ui.drag({
	minDistance = 6,
	onStart = function(ctx)
		drag = ctx.data
		pendingDrag = nil
		updateDragPointer(ctx)
		if drag and drag.item then
			if drag.kind == "case" then
				setStatus("Find a legal space for " .. drag.item.name .. ".", "hint")
			else
				setStatus("Drop " .. drag.item.name .. " onto another slot.", "hint")
			end
			playNodeFeedback("inventory.drag.start", ctx.sourceNode, "drag")
		end
		markDirty()
	end,
	onMove = updateDragPointer,
	onDrop = function(ctx)
		updateDragPointer(ctx)
		finishDrag(ctx)
	end,
	onCancel = function(ctx)
		updateDragPointer(ctx)
		if drag then
			setStatus("Drag cancelled.", "neutral")
		end
		drag = nil
		pendingDrag = nil
		markDirty()
	end,
})

local function slotDraw(store, index, itemId)
	return function(node, x, y, width, height, loveModule, _, ctx)
		local item = itemFor(itemId)
		local rarity = item and item.rarity or "common"
		local accent = rarityColors[rarity] or rarityColors.common
		local visibleDrag = previewDrag()
		local isTarget = drag and pointIn(store[index], pointerX, pointerY)
		local isSource = visibleDrag and visibleDrag.itemId == itemId and (visibleDrag.sourceIndex == index)
		local isHot = ctx.hot or isTarget
		local g = loveModule.graphics

		ctx:color(isHot and { 0.18, 0.13, 0.074, 1 } or { 0.052, 0.046, 0.04, 1 })
		ctx:rect("fill", x, y, width, height, 5)
		ctx:color({ 0, 0, 0, 0.36 })
		ctx:rect("fill", x + 4, y + 4, width - 8, height - 8, 4)
		ctx:color(accent, item and 0.33 or 0.09)
		ctx:rect("fill", x + 6, y + 6, width - 12, 4, 2)

		withLineWidth(g, isTarget and 3 or 1.5, function()
			ctx:color(isTarget and colors.gold or { 0.54, 0.38, 0.2, 0.92 })
			ctx:rect("line", x + 1, y + 1, width - 2, height - 2, 5)
			ctx:color(isSource and { 1, 1, 1, 0.42 } or { 1, 0.83, 0.43, 0.24 })
			ctx:rect("line", x + 6, y + 6, width - 12, height - 12, 3)
		end)

		if not item then
			ctx:color({ 1, 1, 1, 0.055 })
			ctx:line(x + 18, y + height - 18, x + width - 18, y + 18)
			ctx:line(x + 18, y + 18, x + width - 18, y + height - 18)
		end
	end
end

local function countBadge(item, size)
	if not item or not item.count or item.count <= 1 then
		return nil
	end
	return ui.text(tostring(item.count), {
		position = "absolute",
		right = 5,
		bottom = 3,
		interactive = false,
		style = {
			color = { 1, 0.9, 0.62, 1 },
			fontSize = size >= 68 and 12 or 11,
		},
	})
end

local function activateSlot(kind, slots, index, itemId, node)
	pendingDrag = nil
	if keyboardCarry then
		if keyboardCarry.kind ~= kind then
			setStatus("That item belongs to another inventory model.", "bad")
			playNodeFeedback("inventory.drop.bad", node or keyboardCarry.sourceNode, "error")
			markDirty()
			return
		end
		if kind == "page" and keyboardCarry.page ~= currentPage then
			setStatus("Turn back to the carried item's page.", "bad")
			playNodeFeedback("inventory.drop.bad", node or keyboardCarry.sourceNode, "error")
			markDirty()
			return
		end

		swapSlots(slots, keyboardCarry.sourceIndex, index)
		setStatus(string.format("%s placed.", keyboardCarry.item.name), "good")
		pointToBoundsCenter(boundsForNode(node))
		playNodeFeedback("inventory.drop.good", node or keyboardCarry.sourceNode, "drop")
		keyboardCarry = nil
		markDirty()
		return
	end

	local item = itemFor(itemId)
	if item then
		keyboardCarry = {
			keyboard = true,
			kind = kind,
			sourceIndex = index,
			itemId = itemId,
			item = item,
			page = currentPage,
			slots = slots,
			size = kind == "page" and PAGE_SLOT_SIZE or SATCHEL_SLOT_SIZE,
			sourceNode = node,
			sourceBounds = boundsForNode(node),
		}
		setStatus(string.format("Picked up %s. Move focus, then press Enter or A to place.", item.name), "hint")
		playNodeFeedback("inventory.drag.start", node, "drag")
	else
		setStatus(string.format("%s slot %d is empty.", kind:gsub("^%l", string.upper), index), "neutral")
	end
	markDirty()
end

local function slotNode(kind, store, slots, index, size)
	local itemId = slots[index]
	local item = itemFor(itemId)
	local children = {}
	local visibleDrag = previewDrag()
	local isDraggingSource = visibleDrag and visibleDrag.kind == kind and visibleDrag.sourceIndex == index

	if item then
		children[#children + 1] = itemImageNode(item, {
			position = "absolute",
			left = size >= 68 and 13 or 10,
			top = size >= 68 and 12 or 9,
			width = size >= 68 and 46 or 38,
			height = size >= 68 and 46 or 38,
			opacity = isDraggingSource and 0.34 or 1,
		})
		children[#children + 1] = countBadge(item, size)
	end

	return ui.stack({
		key = kind .. "-slot-" .. index,
		width = size,
		height = size,
		role = "button",
		focusable = true,
		navGroup = kind .. "-grid",
		feedback = {
			hover = item and "inventory.slot.hover" or nil,
			focus = "inventory.slot.focus",
			press = "inventory.slot.press",
			release = "inventory.slot.release",
			activate = item and "inventory.slot.activate" or "inventory.empty.activate",
		},
		onClick = function(node)
			activateSlot(kind, slots, index, itemId, node)
		end,
		onMousePressed = function(x, y, button, node)
			if button == 1 and itemId then
				startUniformDrag(kind, index, itemId, x, y, button, node)
			end
		end,
		onLayout = function(bounds, node)
			recordBounds(store, index, bounds.x, bounds.y, bounds.width, bounds.height)
			recordFeedbackNode(node, bounds)
		end,
		accessibilityLabel = item and (item.name .. " " .. rarityNames[item.rarity]) or "Empty slot",
		draw = slotDraw(store, index, itemId),
	}, children)
end

local function slotNodes(kind, store, slots, first, count, size)
	local nodes = {}
	for offset = 0, count - 1 do
		local index = first + offset
		nodes[#nodes + 1] = slotNode(kind, store, slots, index, size)
	end
	return nodes
end

local function bodyText(text, props)
	props = props or {}
	return ui.text(text, {
		width = props.width or "100%",
		wrap = true,
		textStyle = props.textStyle or "caption",
		style = {
			color = props.color or colors.parchmentDim,
			fontSize = props.fontSize,
			lineHeight = props.lineHeight or 17,
		},
	})
end

local function panelLabel(text)
	return ui.text(text, {
		textStyle = "caption",
		style = { color = colors.gold },
	})
end

local function sectionTitle(title, caption, props)
	props = props or {}
	return ui.column({ gap = 2, width = props.width or "100%", flex = props.flex }, {
		ui.text(title, {
			textStyle = "h2",
			style = { color = colors.parchment },
		}),
		ui.text(caption, {
			width = "100%",
			wrap = true,
			textStyle = "caption",
			style = { color = colors.parchmentDim, lineHeight = 15 },
		}),
	})
end

local function legend()
	local nodes = {}
	for _, rarity in ipairs({ "common", "uncommon", "rare", "epic", "legendary" }) do
		nodes[#nodes + 1] = ui.row({ width = "100%", gap = 7, align = "center" }, {
			ui.box({
				width = 12,
				height = 12,
				interactive = false,
				style = {
					background = rarityColors[rarity],
					borderColor = { 0, 0, 0, 0.45 },
					borderWidth = 1,
					radius = 2,
				},
			}),
			ui.text(rarityNames[rarity], {
				textStyle = "caption",
				style = { color = colors.parchmentDim },
			}),
		})
	end
	return ui.grid({
		width = "100%",
		minCellWidth = 104,
		maxColumns = 2,
		cellHeight = 17,
		gap = 4,
	}, nodes)
end

local function previewQuad()
	if potionSprites and potionPreviewAnimation then
		local ok, quad = pcall(function()
			return potionSprites:currentQuad(potionPreviewAnimation)
		end)
		if ok and quad then
			return quad
		end
	end

	return potionSprites and potionSprites:quad(1) or nil
end

local function animatedPotionPreview()
	local quad = previewQuad()
	if not potionSheet or not quad then
		return nil
	end

	return ui.row({ width = "100%", gap = 8, align = "center", height = 46 }, {
		ui.stack({
			width = 42,
			height = 42,
			draw = function(_, x, y, width, height, loveModule, _, ctx)
				local g = loveModule.graphics
				ctx:color({ 0.04, 0.026, 0.018, 0.98 })
				ctx:rect("fill", x, y, width, height, 5)
				ctx:color(colors.gold, 0.18)
				ctx:rect("fill", x + 5, y + 5, width - 10, height - 10, 4)
				withLineWidth(g, 1.5, function()
					ctx:color(colors.gold, 0.68)
					ctx:rect("line", x + 1, y + 1, width - 2, height - 2, 5)
				end)
			end,
		}, {
			ui.image({
				source = potionSheet,
				quad = quad,
				width = 34,
				height = 34,
				position = "absolute",
				left = 4,
				top = 4,
				fit = "contain",
				interactive = false,
			}),
		}),
		ui.column({ gap = 2, grow = 1 }, {
			ui.text("Potion Atlas", {
				textStyle = "caption",
				style = { color = colors.gold },
			}),
			ui.text("animated frames", {
				textStyle = "caption",
				style = { color = colors.parchmentDim },
			}),
		}),
	})
end

local function statusPanel(height, width)
	local children = {
		panelLabel("Quartermaster"),
		ui.text(status, {
			width = "100%",
			wrap = true,
			style = { color = toneColor(), fontSize = 13, lineHeight = 17 },
		}),
	}
	local preview = animatedPotionPreview()
	if preview then
		children[#children + 1] = preview
	end
	children[#children + 1] = ui.box({
		width = "100%",
		height = 1,
		interactive = false,
		style = { background = { 0.9, 0.68, 0.34, 0.24 } },
	})
	children[#children + 1] = legend()

	return panel({
		width = width or "100%",
		height = height,
		padding = 14,
		display = "column",
		gap = 8,
	}, children)
end

local function satchelPanel(m)
	satchelBounds = {}
	local gridWidth = SATCHEL_COLUMNS * SATCHEL_SLOT_SIZE + (SATCHEL_COLUMNS - 1) * SLOT_GAP
	local leftWidth = gridWidth + 28
	local sideWidth = math.max(280, m.contentWidth - leftWidth - 16)
	local scrollHeight = math.max(260, m.contentHeight - 106)

	return ui.row({ width = "100%", height = m.contentHeight, gap = 16 }, {
		panel({
			width = leftWidth,
			height = m.contentHeight,
			padding = 14,
			display = "column",
			gap = 12,
		}, {
			sectionTitle("Satchel", "scrollable slots, visible drop targets"),
			ui.scrollView({
				key = "inventory-satchel-scroll",
				width = gridWidth + 12,
				height = scrollHeight,
				padding = { right = 10 },
				gap = SLOT_GAP,
				showScrollbar = true,
				style = {
					background = { 0.025, 0.022, 0.02, 0.58 },
					borderColor = { 0.66, 0.45, 0.22, 0.35 },
					borderWidth = 1,
					radius = 5,
				},
			}, ui.grid({
				columns = SATCHEL_COLUMNS,
				cellWidth = SATCHEL_SLOT_SIZE,
				cellHeight = SATCHEL_SLOT_SIZE,
				gap = SLOT_GAP,
			}, slotNodes("satchel", satchelBounds, satchelSlots, 1, SATCHEL_SLOT_COUNT, SATCHEL_SLOT_SIZE))),
		}),
		ui.column({ width = sideWidth, gap = 14 }, {
			statusPanel(math.max(222, math.floor(m.contentHeight * 0.52)), sideWidth),
			panel({
				width = "100%",
				grow = 1,
				padding = 14,
				display = "column",
				gap = 10,
			}, {
				panelLabel("Satchel Notes"),
				bodyText("Large potion bags stay compact. Drop onto an occupied slot to swap, or onto an empty slot to move.", {
					lineHeight = 17,
				}),
			}),
		}),
	})
end

local function pageButton(label, enabled, onClick)
	return ui.button({
		label = label,
		width = 44,
		height = 32,
		disabled = not enabled,
		onClick = onClick,
		navGroup = "page-controls",
		feedback = {
			hover = "inventory.slot.hover",
			focus = "inventory.slot.focus",
			press = "inventory.slot.press",
			release = "inventory.slot.release",
			activate = "inventory.nav.change",
		},
		style = {
			background = enabled and { 0.14, 0.09, 0.052, 0.96 } or { 0.06, 0.05, 0.044, 0.82 },
			color = enabled and colors.parchment or { 0.5, 0.45, 0.36, 1 },
			borderColor = enabled and { 0.72, 0.5, 0.22, 0.72 } or { 0.3, 0.25, 0.18, 0.42 },
			borderWidth = 1,
			radius = 5,
			hover = { background = { 0.2, 0.13, 0.066, 0.98 } },
		},
	})
end

local function pagesPanel(m)
	pageBounds = {}
	local pageCount = math.ceil(PAGE_SLOT_COUNT / PAGE_SIZE)
	local first = (currentPage - 1) * PAGE_SIZE + 1
	local gridWidth = PAGE_COLUMNS * PAGE_SLOT_SIZE + (PAGE_COLUMNS - 1) * SLOT_GAP
	local leftWidth = gridWidth + 28
	local sideWidth = math.max(280, m.contentWidth - leftWidth - 16)

	return ui.row({ width = "100%", height = m.contentHeight, gap = 16 }, {
		panel({
			width = leftWidth,
			height = m.contentHeight,
			padding = 14,
			display = "column",
			gap = 12,
		}, {
			ui.row({ align = "center", width = "100%" }, {
				sectionTitle("Pages", "fixed pages for controller browsing", { flex = 1 }),
				ui.row({ gap = 8, align = "center" }, {
					pageButton("<", currentPage > 1, function()
						currentPage = math.max(1, currentPage - 1)
						keyboardCarry = nil
						pendingDrag = nil
						drag = nil
						setStatus("Turned to the previous inventory page.", "neutral")
					end),
					ui.text(string.format("%d / %d", currentPage, pageCount), {
						width = 54,
						textAlign = "center",
						style = { color = colors.parchment },
					}),
					pageButton(">", currentPage < pageCount, function()
						currentPage = math.min(pageCount, currentPage + 1)
						keyboardCarry = nil
						pendingDrag = nil
						drag = nil
						setStatus("Turned to the next inventory page.", "neutral")
					end),
				}),
			}),
			ui.grid({
				columns = PAGE_COLUMNS,
				cellWidth = PAGE_SLOT_SIZE,
				cellHeight = PAGE_SLOT_SIZE,
				gap = SLOT_GAP,
			}, slotNodes("page", pageBounds, pageSlots, first, PAGE_SIZE, PAGE_SLOT_SIZE)),
		}),
		ui.column({ width = sideWidth, gap = 14 }, {
			statusPanel(math.max(222, math.floor(m.contentHeight * 0.52)), sideWidth),
			panel({
				width = "100%",
				grow = 1,
				padding = 14,
				display = "column",
				gap = 10,
			}, {
				panelLabel("Page Model"),
				bodyText("Only the current page accepts drops. Hidden pages stay untouched, which keeps controller play predictable.", {
					lineHeight = 17,
				}),
			}),
		}),
	})
end

local function drawCaseBoard(_, x, y, width, height, loveModule, _, ctx)
	local g = loveModule.graphics
	drawPanelFrame(_, x, y, width, height, loveModule, _, ctx)

	local boardBounds = caseBoardBounds or {
		x = x + CASE_PADDING,
		y = y + CASE_PADDING,
		width = CASE_COLUMNS * CASE_CELL + (CASE_COLUMNS - 1) * CASE_GAP,
		height = CASE_ROWS * CASE_CELL + (CASE_ROWS - 1) * CASE_GAP,
	}

	ctx:color({ 0.022, 0.022, 0.02, 0.86 })
	ctx:rect("fill", boardBounds.x, boardBounds.y, boardBounds.width, boardBounds.height, 4)

	for row = 1, CASE_ROWS do
		for col = 1, CASE_COLUMNS do
			local cx = boardBounds.x + (col - 1) * (CASE_CELL + CASE_GAP)
			local cy = boardBounds.y + (row - 1) * (CASE_CELL + CASE_GAP)
			ctx:color((row + col) % 2 == 0 and { 0.085, 0.076, 0.064, 0.8 } or { 0.058, 0.053, 0.048, 0.8 })
			ctx:rect("fill", cx, cy, CASE_CELL, CASE_CELL, 3)
			ctx:color({ 0.82, 0.58, 0.28, 0.18 })
			ctx:rect("line", cx + 0.5, cy + 0.5, CASE_CELL - 1, CASE_CELL - 1, 3)
		end
	end

	local candidate = caseCandidate()
	if candidate and candidate.col and candidate.row then
		local valid = candidate.valid
		local overlay = valid and colors.green or colors.red
		local cx = boardBounds.x + (candidate.col - 1) * (CASE_CELL + CASE_GAP)
		local cy = boardBounds.y + (candidate.row - 1) * (CASE_CELL + CASE_GAP)
		local cw = candidate.entry.w * CASE_CELL + (candidate.entry.w - 1) * CASE_GAP
		local ch = candidate.entry.h * CASE_CELL + (candidate.entry.h - 1) * CASE_GAP
		ctx:color(overlay, valid and 0.26 or 0.34)
		ctx:rect("fill", cx, cy, cw, ch, 4)
		withLineWidth(g, 3, function()
			ctx:color(overlay, 0.95)
			ctx:rect("line", cx + 1, cy + 1, cw - 2, ch - 2, 4)
		end)
	end
end

local function activateCaseEntry(entry, node)
	pendingDrag = nil
	if keyboardCarry then
		if keyboardCarry.kind ~= "case" then
			setStatus("That item cannot be placed inside the case.", "bad")
			playNodeFeedback("inventory.drop.bad", node or keyboardCarry.sourceNode, "error")
			markDirty()
			return
		end

		local col = keyboardCarry.candidateCol or keyboardCarry.entry.col
		local row = keyboardCarry.candidateRow or keyboardCarry.entry.row
		if validCasePlacement(keyboardCarry.entry, col, row) then
			keyboardCarry.entry.col = col
			keyboardCarry.entry.row = row
			setStatus(string.format("%s placed inside the case.", keyboardCarry.item.name), "good")
			pointToBoundsCenter(carryBounds(keyboardCarry))
			playNodeFeedback("inventory.drop.good", node or keyboardCarry.sourceNode, "drop")
			keyboardCarry = nil
		else
			setStatus("That space is blocked or outside the case.", "bad")
			playNodeFeedback("inventory.drop.bad", node or keyboardCarry.sourceNode, "error")
		end
		markDirty()
		return
	end

	local item = itemFor(entry and entry.itemId)
	if item then
		keyboardCarry = {
			keyboard = true,
			kind = "case",
			entryId = entry.id,
			entry = entry,
			itemId = entry.itemId,
			item = item,
			size = math.min(92, CASE_CELL * math.max(entry.w, entry.h)),
			candidateCol = entry.col,
			candidateRow = entry.row,
			sourceNode = node,
			sourceBounds = boundsForNode(node),
		}
		setStatus(string.format("Picked up %s. Move with arrows or d-pad, then press Enter or A to place.", item.name), "hint")
		playNodeFeedback("inventory.drag.start", node, "drag")
	end
	markDirty()
end

local function caseItemNode(entry)
	local item = itemFor(entry.itemId)
	local stride = CASE_CELL + CASE_GAP
	local width = entry.w * CASE_CELL + (entry.w - 1) * CASE_GAP
	local height = entry.h * CASE_CELL + (entry.h - 1) * CASE_GAP
	local visibleDrag = previewDrag()
	local isDragging = visibleDrag and visibleDrag.kind == "case" and visibleDrag.entryId == entry.id
	local accent = item and (rarityColors[item.rarity] or rarityColors.common) or colors.iron
	local imageSize = math.max(36, math.min(70, width - 18, height - 18))

	local children = {
		itemImageNode(item, {
			position = "absolute",
			left = math.floor((width - imageSize) / 2),
			top = math.floor((height - imageSize) / 2) - (height > 82 and 8 or 0),
			width = imageSize,
			height = imageSize,
			opacity = isDragging and 0.42 or 1,
		}),
	}

	if item and width >= 92 and height >= 74 then
		children[#children + 1] = ui.text(item.name, {
			position = "absolute",
			left = 8,
			right = 8,
			bottom = 6,
			textAlign = "center",
			interactive = false,
			style = {
				color = { 1, 0.88, 0.58, isDragging and 0.42 or 0.92 },
				fontSize = 11,
			},
		})
	end

	return ui.stack({
		key = "case-entry-" .. entry.id,
		position = "absolute",
		left = CASE_PADDING + (entry.col - 1) * stride,
		top = CASE_PADDING + (entry.row - 1) * stride,
		width = width,
		height = height,
		zIndex = isDragging and 30 or 5,
		role = "button",
		focusable = true,
		navGroup = "case-grid",
		feedback = {
			hover = "inventory.slot.hover",
			focus = "inventory.slot.focus",
			press = "inventory.slot.press",
			release = "inventory.slot.release",
			activate = "inventory.slot.activate",
		},
		onClick = function(node)
			activateCaseEntry(entry, node)
		end,
		onMousePressed = function(x, y, button, node)
			if button == 1 then
				startCaseDrag(entry, x, y, button, node)
			end
		end,
		onLayout = function(bounds, node)
			recordFeedbackNode(node, bounds)
		end,
		accessibilityLabel = item and (item.name .. " case item") or "Case item",
		draw = function(_, x, y, nodeWidth, nodeHeight, loveModule, _, ctx)
			local g = loveModule.graphics
			local hot = ctx.hot or ctx.focused
			ctx:color(hot and { 0.085, 0.058, 0.038, isDragging and 0.52 or 0.98 } or { 0.055, 0.043, 0.034, isDragging and 0.52 or 0.96 })
			ctx:rect("fill", x, y, nodeWidth, nodeHeight, 5)
			ctx:color(accent, hot and 0.4 or (isDragging and 0.18 or 0.32))
			ctx:rect("fill", x + 5, y + 5, nodeWidth - 10, nodeHeight - 10, 4)
			ctx:color({ 0, 0, 0, isDragging and 0.18 or 0.34 })
			ctx:rect("fill", x + 9, y + 9, nodeWidth - 18, nodeHeight - 18, 3)
			withLineWidth(g, hot and 3 or (isDragging and 1 or 2), function()
				ctx:color(accent, isDragging and 0.52 or 0.95)
				ctx:rect("line", x + 1, y + 1, nodeWidth - 2, nodeHeight - 2, 5)
				ctx:color({ 1, 0.86, 0.45, isDragging and 0.18 or 0.3 })
				ctx:rect("line", x + 6, y + 6, nodeWidth - 12, nodeHeight - 12, 4)
			end)
		end,
	}, children)
end

local function caseBoard(m)
	local children = {}
	for _, entry in ipairs(caseEntries) do
		children[#children + 1] = caseItemNode(entry)
	end

	return ui.stack({
		width = m.caseBoardWidth,
		height = m.caseBoardHeight,
		onLayout = function(bounds)
			caseBoardBounds = {
				x = bounds.x + CASE_PADDING,
				y = bounds.y + CASE_PADDING,
				width = CASE_COLUMNS * CASE_CELL + (CASE_COLUMNS - 1) * CASE_GAP,
				height = CASE_ROWS * CASE_CELL + (CASE_ROWS - 1) * CASE_GAP,
			}
		end,
		draw = drawCaseBoard,
	}, children)
end

local function caseRulesPanel(props)
	props = props or {}

	return panel({
		width = props.width or "100%",
		height = props.height,
		grow = props.grow,
		padding = 14,
		display = "column",
		gap = 10,
	}, {
		panelLabel("Case Rules"),
		bodyText("Items keep rectangular spans. Green previews fit; red previews collide or leave the case.", {
			lineHeight = 17,
		}),
	})
end

local function casePanel(m)
	local boardPanelWidth = m.caseBoardWidth + 28
	local compact = m.contentWidth < boardPanelWidth + 16 + 320
	local sideWidth = math.max(280, m.contentWidth - boardPanelWidth - 16)

	if compact then
		local compactPanelWidth = math.max(280, math.min(boardPanelWidth, m.contentWidth - 10))
		return ui.scrollView({
			key = "inventory-case-scroll",
			width = "100%",
			height = m.contentHeight,
			padding = { right = 10 },
			gap = 14,
			showScrollbar = true,
			style = {
				background = { 0.025, 0.022, 0.02, 0.58 },
				borderColor = { 0.66, 0.45, 0.22, 0.35 },
				borderWidth = 1,
				radius = 5,
			},
		}, {
			panel({
				width = boardPanelWidth,
				height = m.caseBoardHeight + 90,
				padding = 14,
				display = "column",
				gap = 12,
			}, {
				sectionTitle("Case", "variable-size placement with collision checks"),
				caseBoard(m),
			}),
			statusPanel(214, compactPanelWidth),
			caseRulesPanel({ width = compactPanelWidth, height = 132 }),
		})
	end

	return ui.row({ width = "100%", height = m.contentHeight, gap = 16 }, {
		panel({
			width = boardPanelWidth,
			height = m.contentHeight,
			padding = 14,
			display = "column",
			gap = 12,
		}, {
			sectionTitle("Case", "variable-size placement with collision checks"),
			caseBoard(m),
		}),
		ui.column({ width = sideWidth, gap = 14 }, {
			statusPanel(math.max(222, math.floor(m.contentHeight * 0.52)), sideWidth),
			caseRulesPanel({ grow = 1 }),
		}),
	})
end

local function dragPreview()
	local visibleDrag = previewDrag()
	if not visibleDrag or not visibleDrag.item then
		return nil
	end

	local size = math.max(64, math.min(96, visibleDrag.size or 72))
	local item = visibleDrag.item
	local accent = rarityColors[item.rarity] or rarityColors.common
	local previewBounds = visibleDrag.keyboard and carryBounds(visibleDrag) or nil
	local previewX = previewBounds and (previewBounds.x + previewBounds.width / 2) or pointerX
	local previewY = previewBounds and (previewBounds.y + previewBounds.height / 2) or pointerY

	return ui.portal({
		left = previewX - size / 2,
		top = previewY - size / 2,
		width = size,
		height = size,
		zIndex = 500,
		interactive = false,
		draw = function(_, x, y, width, height, loveModule, _, ctx)
			local g = loveModule.graphics
			ctx:color({ 0.02, 0.018, 0.016, 0.7 })
			ctx:rect("fill", x + 5, y + 7, width, height, 8)
			ctx:color({ 0.09, 0.064, 0.042, 0.94 })
			ctx:rect("fill", x, y, width, height, 7)
			ctx:color(accent, 0.28)
			ctx:rect("fill", x + 6, y + 6, width - 12, height - 12, 5)
			withLineWidth(g, 2, function()
				ctx:color(colors.gold)
				ctx:rect("line", x + 1, y + 1, width - 2, height - 2, 7)
			end)
		end,
	}, {
		itemImageNode(item, {
			position = "absolute",
			left = 12,
			top = 10,
			width = size - 24,
			height = size - 24,
		}),
	})
end

local function header()
	return ui.box({
		width = "100%",
		height = 72,
		padding = { x = 18, y = 12 },
		display = "row",
		align = "center",
		draw = drawHeader,
	}, {
		ui.column({ gap = 2 }, {
			ui.text("ALCHEMIST'S INVENTORY", {
				textStyle = "h1",
				style = { color = colors.parchment },
			}),
			ui.text("MMO inventory patterns built with Glyph primitives", {
				textStyle = "caption",
				style = { color = colors.parchmentDim },
			}),
		}),
		ui.box({ grow = 1, interactive = false }),
		ui.row({ gap = 10, align = "center" }, {
			ui.text("Spritesheet", {
				textStyle = "caption",
				style = { color = colors.parchmentDim },
			}),
			ui.box({
				width = 122,
				height = 34,
				padding = { x = 10, y = 7 },
				display = "row",
				gap = 8,
				align = "center",
				style = {
					background = { 0.055, 0.041, 0.032, 0.96 },
					borderColor = { 0.8, 0.55, 0.25, 0.68 },
					borderWidth = 1,
					radius = 5,
				},
			}, {
				itemImageNode(itemFor("minor_health"), { width = 22, height = 22 }),
				itemImageNode(itemFor("mana_vial"), { width = 22, height = 22 }),
				itemImageNode(itemFor("dragon_breath"), { width = 22, height = 22 }),
			}),
		}),
	})
end

local function errorPanel(m)
	return panel({
		width = "100%",
		height = m.contentHeight,
		padding = 18,
		display = "column",
		gap = 10,
	}, {
		ui.text("Inventory asset missing", {
			textStyle = "h2",
			style = { color = colors.red },
		}),
		ui.text(assetError or "Potion spritesheet was not loaded.", {
			width = "100%",
			wrap = true,
			style = { color = colors.parchment },
		}),
	})
end

local function tabs(m)
	if assetError then
		return errorPanel(m)
	end

	return ui.tabs({
		active = activeTab,
		onChange = function(index)
			activeTab = index
			keyboardCarry = nil
			pendingDrag = nil
			drag = nil
			setStatus("Switched inventory model.", "neutral")
			ui.feedback.play("inventory.nav.change", nil, {
				trigger = "activate",
				restart = true,
				key = "inventory.nav.change",
			})
		end,
		width = "100%",
		grow = 1,
		gap = 8,
		tabWidth = 124,
		tabHeight = 40,
		tabPadding = { x = 16, y = 9 },
		style = {
			background = { 0, 0, 0, 0 },
		},
		tabStyle = {
			background = { 0.08, 0.058, 0.044, 0.96 },
			color = colors.parchmentDim,
			borderColor = { 0.54, 0.35, 0.15, 0.76 },
			borderWidth = 1,
			radius = 5,
			hover = { background = { 0.15, 0.1, 0.06, 0.98 }, color = colors.parchment },
			focused = { background = { 0.15, 0.1, 0.06, 0.98 }, color = colors.parchment, borderColor = colors.gold },
			pressed = { background = { 0.07, 0.046, 0.032, 0.98 } },
			active = {
				background = { 0.33, 0.22, 0.09, 0.98 },
				color = { 1, 0.88, 0.56, 1 },
				borderColor = colors.gold,
			},
		},
	}, {
		{ label = "Satchel", content = satchelPanel(m) },
		{ label = "Pages", content = pagesPanel(m) },
		{ label = "Case", content = casePanel(m) },
	})
end

local function App(mode)
	loadPotionSheet()
	local m = metrics(mode)
	local children = {
		ui.box({ position = "absolute", inset = 0, interactive = false, draw = drawBackdrop }),
		ui.column({
			position = "absolute",
			top = m.margin,
			bottom = m.margin,
			left = m.left,
			right = m.right,
			gap = 12,
		}, {
			header(),
			tabs(m),
		}),
	}

	local overlay = feedbackOverlay()
	if overlay then
		children[#children + 1] = overlay
	end

	local preview = dragPreview()
	if preview then
		children[#children + 1] = preview
	end

	return ui.stack({
		width = m.width,
		height = m.height,
	}, children)
end

local function setup()
	ui.setTheme(exampleTheme)
	defineInventoryFeedback()
	if offFeedback then
		offFeedback()
	end
	offFeedback = ui.on("feedback", handleFeedbackEvent)
	feedbackParticles = {}
	loadPotionSheet()
	resetArrangements()
end

local function update(dt)
	updateFeedbackParticles(dt or 0)
	if potionPreviewAnimation and type(potionPreviewAnimation.update) == "function" then
		potionPreviewAnimation:update(dt or 0)
		markDirty()
	end
end

local function teardown()
	keyboardCarry = nil
	pendingDrag = nil
	drag = nil
	satchelBounds = {}
	pageBounds = {}
	caseBoardBounds = nil
	feedbackBounds = {}
	feedbackNodes = {}
	feedbackParticles = {}
	if offFeedback then
		offFeedback()
		offFeedback = nil
	end
	ui.feedback.clear()
end

local function switchActiveTab(delta)
	local nextTab = math.max(1, math.min(3, activeTab + delta))
	if nextTab ~= activeTab then
		activeTab = nextTab
		keyboardCarry = nil
		pendingDrag = nil
		drag = nil
		setStatus("Switched inventory model.", "neutral")
		ui.feedback.play("inventory.nav.change", nil, {
			trigger = "activate",
			restart = true,
			key = "inventory.nav.change",
		})
		markDirty()
	end
end

local function turnPage(delta)
	local pageCount = math.ceil(PAGE_SLOT_COUNT / PAGE_SIZE)
	local nextPage = math.max(1, math.min(pageCount, currentPage + delta))
	if nextPage ~= currentPage then
		currentPage = nextPage
		keyboardCarry = nil
		pendingDrag = nil
		drag = nil
		setStatus(string.format("Turned to inventory page %d.", currentPage), "neutral")
		ui.feedback.play("inventory.nav.change", nil, {
			trigger = "activate",
			restart = true,
			key = "inventory.nav.change",
		})
		markDirty()
	end
end

local function keypressed(key)
	local directions = {
		up = "up",
		down = "down",
		left = "left",
		right = "right",
	}
	if key == "escape" and cancelKeyboardCarry() then
		return true
	end
	if directions[key] then
		if moveCaseCarry(directions[key]) then
			return true
		end
		ui.navigate(directions[key])
		return true
	elseif key == "tab" then
		switchActiveTab(1)
		return true
	elseif key == "pageup" then
		turnPage(-1)
		return true
	elseif key == "pagedown" then
		turnPage(1)
		return true
	end
end

local function gamepadpressed(_, button)
	local directions = {
		dpup = "up",
		dpdown = "down",
		dpleft = "left",
		dpright = "right",
	}
	local direction = directions[button]
	if direction then
		if moveCaseCarry(direction) then
			return true
		end
		ui.navigate(direction)
		return true
	elseif button == "a" then
		ui.keypressed("return")
		return true
	elseif button == "b" then
		if cancelKeyboardCarry() then
			return true
		end
		ui.keypressed("escape")
		return true
	end
	return nil
end

local function gamepadreleased(_, button)
	if button == "a" then
		ui.keyreleased("return")
		return true
	elseif button == "b" then
		ui.keyreleased("escape")
		return true
	end
	return nil
end

return {
	id = "inventory",
	label = "Inventory",
	install = {
		gamepad = false,
	},
	setup = setup,
	update = update,
	teardown = teardown,
	keypressed = keypressed,
	gamepadpressed = gamepadpressed,
	gamepadreleased = gamepadreleased,
	window = {
		width = 1180,
		height = 720,
		minWidth = 960,
		minHeight = 620,
		resizable = true,
		breakpoints = { md = 900 },
		title = "Inventory - glyph.lua",
	},
	component = function(mode)
		return App(mode or "standalone")
	end,
}
