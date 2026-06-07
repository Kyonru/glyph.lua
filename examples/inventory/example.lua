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
local potionQuads = {}
local assetError = nil
local eventOff = nil

local activeTab = 1
local currentPage = 1
local pointerX = 0
local pointerY = 0
local drag = nil
local status = "Drag potions to reorganize the active inventory."
local statusTone = "neutral"

local satchelSlots = {}
local pageSlots = {}
local caseEntries = {}
local satchelBounds = {}
local pageBounds = {}
local caseBoardBounds = nil

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
	if potionSheet or assetError then
		return
	end

	local loveModule = _G.love
	if not loveModule or not loveModule.graphics then
		return
	end

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

	if not potionSheet then
		assetError = "Could not load examples/inventory/potions.png"
		return
	end

	if potionSheet.setFilter then
		potionSheet:setFilter("nearest", "nearest")
	end

	local sheetColumns = math.floor(potionSheet:getWidth() / SPRITE_WIDTH)
	local sheetRows = math.floor(potionSheet:getHeight() / SPRITE_HEIGHT)

	potionQuads = {}
	for row = 0, sheetRows - 1 do
		for column = 0, sheetColumns - 1 do
			potionQuads[#potionQuads + 1] = loveModule.graphics.newQuad(
				column * SPRITE_WIDTH,
				row * SPRITE_HEIGHT,
				SPRITE_WIDTH,
				SPRITE_HEIGHT,
				potionSheet:getWidth(),
				potionSheet:getHeight()
			)
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
	drag = nil
	satchelBounds = {}
	pageBounds = {}
	caseBoardBounds = nil
	setStatus("Drag potions to reorganize the active inventory.", "neutral")
end

local function metrics(mode)
	local viewport = ui.viewport()
	local showcaseInset = mode == "showcase" and 188 or 0
	local margin = 18
	local usableHeight = math.max(540, viewport.height - margin * 2)
	local contentHeight = math.max(420, usableHeight - 72 - 12 - 40)

	return {
		width = viewport.width,
		height = viewport.height,
		margin = margin,
		left = margin + showcaseInset,
		right = margin,
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
	if not potionSheet or not item then
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
		quad = potionQuads[item.quad],
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

local function startUniformDrag(kind, sourceIndex, itemId, x, y)
	local item = itemFor(itemId)
	if not item then
		return
	end
	drag = {
		kind = kind,
		sourceIndex = sourceIndex,
		itemId = itemId,
		item = item,
		page = currentPage,
		size = kind == "page" and PAGE_SLOT_SIZE or SATCHEL_SLOT_SIZE,
	}
	pointerX = x
	pointerY = y
	setStatus("Drop " .. item.name .. " onto another slot.", "hint")
	markDirty()
end

local function rectsOverlap(a, b)
	return a.col < b.col + b.w
		and b.col < a.col + a.w
		and a.row < b.row + b.h
		and b.row < a.row + a.h
end

local function validCasePlacement(entry, col, row)
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
	local stride = CASE_CELL + CASE_GAP
	local localX = pointerX - caseBoardBounds.x
	local localY = pointerY - caseBoardBounds.y
	if localX < 0 or localY < 0 then
		return nil, nil
	end
	local col = math.floor(localX / stride) + 1
	local row = math.floor(localY / stride) + 1
	if col < 1 or row < 1 or col > CASE_COLUMNS or row > CASE_ROWS then
		return nil, nil
	end
	return col, row
end

local function caseCandidate()
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

local function startCaseDrag(entry, x, y)
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

	drag = {
		kind = "case",
		entryId = entry.id,
		entry = entry,
		itemId = entry.itemId,
		item = item,
		size = math.min(92, CASE_CELL * math.max(entry.w, entry.h)),
		anchorCol = anchorCol,
		anchorRow = anchorRow,
	}
	pointerX = x
	pointerY = y
	setStatus("Find a legal space for " .. item.name .. ".", "hint")
	markDirty()
end

local function finishDrag()
	if not drag then
		return
	end

	if drag.kind == "satchel" then
		local target = findSlotAt(satchelBounds, pointerX, pointerY)
		if target then
			swapSlots(satchelSlots, drag.sourceIndex, target)
			setStatus("Satchel reordered.", "good")
		else
			setStatus("Satchel drop missed the grid.", "bad")
		end
	elseif drag.kind == "page" then
		local target = findSlotAt(pageBounds, pointerX, pointerY)
		if target and drag.page == currentPage then
			swapSlots(pageSlots, drag.sourceIndex, target)
			setStatus("Page slot updated.", "good")
		else
			setStatus("Drop inside the current page.", "bad")
		end
	elseif drag.kind == "case" then
		local candidate = caseCandidate()
		if candidate and candidate.valid then
			drag.entry.col = candidate.col
			drag.entry.row = candidate.row
			setStatus("Case placement accepted.", "good")
		else
			setStatus("That space is blocked or outside the case.", "bad")
		end
	end

	drag = nil
	markDirty()
end

local function slotDraw(store, index, itemId)
	return function(node, x, y, width, height, loveModule, _, ctx)
		recordBounds(store, index, x, y, width, height)

		local item = itemFor(itemId)
		local rarity = item and item.rarity or "common"
		local accent = rarityColors[rarity] or rarityColors.common
		local isTarget = drag and pointIn(store[index], pointerX, pointerY)
		local isSource = drag and drag.itemId == itemId and (drag.sourceIndex == index)
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

local function slotNode(kind, store, slots, index, size)
	local itemId = slots[index]
	local item = itemFor(itemId)
	local children = {}
	local isDraggingSource = drag and drag.kind == kind and drag.sourceIndex == index

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
		onMousePressed = function(x, y, button)
			if button == 1 and itemId then
				startUniformDrag(kind, index, itemId, x, y)
			end
		end,
		role = "button",
		accessibilityLabel = item and (item.name .. " " .. rarityNames[item.rarity]) or "Empty slot",
		draw = slotDraw(store, index, itemId),
	}, children)
end

local function slotRows(kind, store, slots, count, columns, size)
	local rows = {}
	for row = 1, math.ceil(count / columns) do
		local children = {}
		for column = 1, columns do
			local index = (row - 1) * columns + column
			if index <= count then
				children[#children + 1] = slotNode(kind, store, slots, index, size)
			end
		end
		rows[#rows + 1] = ui.row({ gap = SLOT_GAP }, children)
	end
	return rows
end

local function sectionTitle(title, caption)
	return ui.column({ gap = 2 }, {
		ui.text(title, {
			textStyle = "h2",
			style = { color = colors.parchment },
		}),
		ui.text(caption, {
			textStyle = "caption",
			style = { color = colors.parchmentDim },
		}),
	})
end

local function legend()
	local nodes = {}
	for _, rarity in ipairs({ "common", "uncommon", "rare", "epic", "legendary" }) do
		nodes[#nodes + 1] = ui.row({ gap = 8, align = "center" }, {
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
	return ui.column({ gap = 6 }, nodes)
end

local function statusPanel(height)
	return panel({
		width = "100%",
		height = height,
		padding = 14,
		display = "column",
		gap = 10,
	}, {
		ui.text("Quartermaster", {
			textStyle = "caption",
			style = { color = colors.gold },
		}),
		ui.text(status, {
			width = "100%",
			wrap = true,
			style = { color = toneColor(), fontSize = 14, lineHeight = 19 },
		}),
		ui.box({
			width = "100%",
			height = 1,
			interactive = false,
			style = { background = { 0.9, 0.68, 0.34, 0.24 } },
		}),
		legend(),
	})
end

local function satchelPanel(m)
	satchelBounds = {}
	local gridWidth = SATCHEL_COLUMNS * SATCHEL_SLOT_SIZE + (SATCHEL_COLUMNS - 1) * SLOT_GAP
	local scrollHeight = math.max(260, m.contentHeight - 106)

	return ui.row({ height = m.contentHeight, gap = 16 }, {
		panel({
			width = gridWidth + 28,
			height = m.contentHeight,
			padding = 14,
			display = "column",
			gap = 12,
		}, {
			sectionTitle("Satchel", "scrollable uniform slots with swap or move drops"),
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
			}, slotRows("satchel", satchelBounds, satchelSlots, SATCHEL_SLOT_COUNT, SATCHEL_COLUMNS, SATCHEL_SLOT_SIZE)),
		}),
		ui.column({ grow = 1, gap = 14 }, {
			statusPanel(math.max(196, math.floor(m.contentHeight * 0.46))),
			panel({
				width = "100%",
				grow = 1,
				padding = 14,
				display = "column",
				gap = 10,
			}, {
				ui.text("Satchel Notes", { style = { color = colors.gold } }),
				ui.text("The scrollable tab keeps a large potion list compact. Dropping on an occupied slot swaps; dropping on an empty slot moves.", {
					width = "100%",
					wrap = true,
					style = { color = colors.parchmentDim, lineHeight = 19 },
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
	local gridRows = {}

	for row = 1, PAGE_ROWS do
		local children = {}
		for column = 1, PAGE_COLUMNS do
			local absoluteIndex = first + (row - 1) * PAGE_COLUMNS + column - 1
			children[#children + 1] = slotNode("page", pageBounds, pageSlots, absoluteIndex, PAGE_SLOT_SIZE)
		end
		gridRows[#gridRows + 1] = ui.row({ gap = SLOT_GAP }, children)
	end

	return ui.row({ height = m.contentHeight, gap = 16 }, {
		panel({
			width = gridWidth + 28,
			height = m.contentHeight,
			padding = 14,
			display = "column",
			gap = 12,
		}, {
			ui.row({ align = "center", width = "100%" }, {
				sectionTitle("Pages", "fixed page inventory for predictable controller-style browsing"),
				ui.box({ grow = 1, interactive = false }),
				ui.row({ gap = 8, align = "center" }, {
					pageButton("<", currentPage > 1, function()
						currentPage = math.max(1, currentPage - 1)
						drag = nil
					end),
					ui.text(string.format("%d / %d", currentPage, pageCount), {
						width = 54,
						textAlign = "center",
						style = { color = colors.parchment },
					}),
					pageButton(">", currentPage < pageCount, function()
						currentPage = math.min(pageCount, currentPage + 1)
						drag = nil
					end),
				}),
			}),
			ui.column({ gap = SLOT_GAP }, gridRows),
		}),
		ui.column({ grow = 1, gap = 14 }, {
			statusPanel(math.max(196, math.floor(m.contentHeight * 0.46))),
			panel({
				width = "100%",
				grow = 1,
				padding = 14,
				display = "column",
				gap = 10,
			}, {
				ui.text("Page Model", { style = { color = colors.gold } }),
				ui.text("Each page has its own visible bounds. Dragging between hidden pages is intentionally rejected so the example stays deterministic.", {
					width = "100%",
					wrap = true,
					style = { color = colors.parchmentDim, lineHeight = 19 },
				}),
			}),
		}),
	})
end

local function drawCaseBoard(_, x, y, width, height, loveModule, _, ctx)
	local g = loveModule.graphics
	drawPanelFrame(_, x, y, width, height, loveModule, _, ctx)

	caseBoardBounds = {
		x = x + CASE_PADDING,
		y = y + CASE_PADDING,
		width = CASE_COLUMNS * CASE_CELL + (CASE_COLUMNS - 1) * CASE_GAP,
		height = CASE_ROWS * CASE_CELL + (CASE_ROWS - 1) * CASE_GAP,
	}

	ctx:color({ 0.022, 0.022, 0.02, 0.86 })
	ctx:rect("fill", caseBoardBounds.x, caseBoardBounds.y, caseBoardBounds.width, caseBoardBounds.height, 4)

	for row = 1, CASE_ROWS do
		for col = 1, CASE_COLUMNS do
			local cx = caseBoardBounds.x + (col - 1) * (CASE_CELL + CASE_GAP)
			local cy = caseBoardBounds.y + (row - 1) * (CASE_CELL + CASE_GAP)
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
		local cx = caseBoardBounds.x + (candidate.col - 1) * (CASE_CELL + CASE_GAP)
		local cy = caseBoardBounds.y + (candidate.row - 1) * (CASE_CELL + CASE_GAP)
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

local function caseItemNode(entry)
	local item = itemFor(entry.itemId)
	local stride = CASE_CELL + CASE_GAP
	local width = entry.w * CASE_CELL + (entry.w - 1) * CASE_GAP
	local height = entry.h * CASE_CELL + (entry.h - 1) * CASE_GAP
	local isDragging = drag and drag.kind == "case" and drag.entryId == entry.id
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
		onMousePressed = function(x, y, button)
			if button == 1 then
				startCaseDrag(entry, x, y)
			end
		end,
		role = "button",
		accessibilityLabel = item and (item.name .. " case item") or "Case item",
		draw = function(_, x, y, nodeWidth, nodeHeight, loveModule, _, ctx)
			local g = loveModule.graphics
			ctx:color({ 0.055, 0.043, 0.034, isDragging and 0.52 or 0.96 })
			ctx:rect("fill", x, y, nodeWidth, nodeHeight, 5)
			ctx:color(accent, isDragging and 0.18 or 0.32)
			ctx:rect("fill", x + 5, y + 5, nodeWidth - 10, nodeHeight - 10, 4)
			ctx:color({ 0, 0, 0, isDragging and 0.18 or 0.34 })
			ctx:rect("fill", x + 9, y + 9, nodeWidth - 18, nodeHeight - 18, 3)
			withLineWidth(g, isDragging and 1 or 2, function()
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
		draw = drawCaseBoard,
	}, children)
end

local function casePanel(m)
	return ui.row({ height = m.contentHeight, gap = 16 }, {
		panel({
			width = m.caseBoardWidth + 28,
			height = m.contentHeight,
			padding = 14,
			display = "column",
			gap = 12,
		}, {
			sectionTitle("Case", "variable-size cells with collision and bounds rejection"),
			caseBoard(m),
		}),
		ui.column({ grow = 1, gap = 14 }, {
			statusPanel(math.max(196, math.floor(m.contentHeight * 0.46))),
			panel({
				width = "100%",
				grow = 1,
				padding = 14,
				display = "column",
				gap = 10,
			}, {
				ui.text("Case Rules", { style = { color = colors.gold } }),
				ui.text("Items keep their rectangular spans. The preview turns green for a valid space and red when the item would collide or leave the case.", {
					width = "100%",
					wrap = true,
					style = { color = colors.parchmentDim, lineHeight = 19 },
				}),
			}),
		}),
	})
end

local function dragPreview()
	if not drag or not drag.item then
		return nil
	end

	local size = math.max(64, math.min(96, drag.size or 72))
	local item = drag.item
	local accent = rarityColors[item.rarity] or rarityColors.common

	return ui.stack({
		position = "absolute",
		left = pointerX - size / 2,
		top = pointerY - size / 2,
		width = size,
		height = size,
		zScope = "root",
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
			ui.text("medieval MMO inventory patterns built from Glyph primitives", {
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
			drag = nil
			setStatus("Switched inventory model.", "neutral")
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

	return ui.stack({
		width = m.width,
		height = m.height,
	}, {
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
		dragPreview(),
	})
end

local function setup()
	ui.setTheme(exampleTheme)
	loadPotionSheet()
	resetArrangements()

	if eventOff then
		eventOff()
	end

	eventOff = ui.on("event", function(kind, x, y, button)
		if kind == "mousemoved" or kind == "mousepressed" or kind == "mousereleased" then
			pointerX = x or pointerX
			pointerY = y or pointerY
			if drag then
				markDirty()
			end
		end

		if kind == "mousereleased" and drag and button == 1 then
			finishDrag()
		end
	end)
end

local function teardown()
	if eventOff then
		eventOff()
		eventOff = nil
	end
	drag = nil
	satchelBounds = {}
	pageBounds = {}
	caseBoardBounds = nil
end

return {
	id = "inventory",
	label = "Inventory",
	setup = setup,
	teardown = teardown,
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
