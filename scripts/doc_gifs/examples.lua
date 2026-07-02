local ui = require("glyph")

local palette = {
	bg = { 0.035, 0.043, 0.058, 1 },
	panel = { 0.075, 0.092, 0.118, 0.96 },
	panel2 = { 0.105, 0.075, 0.12, 0.95 },
	border = { 1, 1, 1, 0.16 },
	text = { 0.93, 0.96, 0.98, 1 },
	muted = { 0.58, 0.66, 0.73, 1 },
	teal = { 0.1, 0.78, 0.68, 1 },
	blue = { 0.22, 0.48, 0.92, 1 },
	gold = { 0.94, 0.66, 0.18, 1 },
	coral = { 0.92, 0.24, 0.3, 1 },
	violet = { 0.66, 0.38, 0.96, 1 },
}

local function cloneColor(color, alpha)
	return { color[1], color[2], color[3], alpha ~= nil and alpha or color[4] or 1 }
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function wave(ctx, speed, phase)
	return (math.sin((ctx.time or 0) * (speed or 1) + (phase or 0)) + 1) / 2
end

local function remember(ctx, value, limit)
	ctx.events = ctx.events or {}
	ctx.events[#ctx.events + 1] = value
	while #ctx.events > (limit or 5) do
		table.remove(ctx.events, 1)
	end
end

local function panelProps(extra)
	local props = {
		padding = 14,
		gap = 8,
		style = {
			background = palette.panel,
			borderColor = palette.border,
			borderWidth = 1,
			radius = 8,
		},
	}

	for key, value in pairs(extra or {}) do
		props[key] = value
	end

	return props
end

local function panel(title, props, children)
	props = panelProps(props)
	props.title = title
	props.titleTextStyle = "caption"
	props.titleColor = palette.muted
	return ui.panel(props, children)
end

local function pill(label, color)
	color = color or palette.teal
	return ui.box({
		width = 118,
		height = 28,
		padding = 6,
		display = "column",
		align = "center",
		justify = "center",
		style = {
			background = cloneColor(color, 0.18),
			borderColor = cloneColor(color, 0.72),
			borderWidth = 1,
			radius = 14,
		},
	}, {
		ui.text(label, { textStyle = "caption", style = { color = palette.text } }),
	})
end

local function metric(label, value, color)
	return ui.column({ gap = 5, width = 148 }, {
		ui.text(label, { textStyle = "caption", style = { color = palette.muted } }),
		ui.text(value, { textStyle = "h2", style = { color = color or palette.text } }),
	})
end

local function header(title, subtitle)
	return ui.row({ width = "100%", height = 64, align = "center", gap = 16 }, {
		ui.column({ gap = 4, flex = 1 }, {
			ui.h1(title, { style = { color = palette.text } }),
			ui.text(subtitle, { style = { color = palette.muted } }),
		}),
		pill("live UI", palette.teal),
	})
end

local function stage(ctx, title, subtitle, children)
	return ui.stack({ width = ctx.width, height = ctx.height }, {
		ui.column({
			position = "absolute",
			left = 36,
			top = 26,
			width = ctx.width - 72,
			gap = 14,
		}, {
			header(title, subtitle),
			children,
		}),
	})
end

local function codeBlock(lines)
	local nodes = {}
	for _, line in ipairs(lines) do
		nodes[#nodes + 1] = ui.text(line, {
			textStyle = "caption",
			style = { color = line:find("^%s") and palette.muted or palette.teal },
		})
	end

	return panel("declarative Lua", { width = 384, height = 260 }, nodes)
end

local function eventList(ctx, title)
	local rows = {}
	for index, event in ipairs(ctx.events or {}) do
		rows[#rows + 1] = ui.row({ height = 28, gap = 8, align = "center" }, {
			ui.box({
				width = 8,
				height = 8,
				style = {
					background = ({ palette.teal, palette.gold, palette.coral, palette.blue, palette.violet })[(index - 1) % 5 + 1],
					radius = 4,
				},
			}),
			ui.text(event, { style = { color = palette.text } }),
		})
	end

	while #rows < 5 do
		rows[#rows + 1] = ui.text("waiting for scripted event", { style = { color = cloneColor(palette.muted, 0.5) } })
	end

	return panel(title or "event stream", { width = 336, height = 212 }, rows)
end

local function makeProceduralImage(ctx, id)
	if ctx.images and ctx.images[id] then
		return ctx.images[id]
	end

	local loveModule = ctx.love or _G.love
	if not loveModule or not loveModule.image or not loveModule.graphics then
		return nil
	end

	ctx.images = ctx.images or {}
	local imageData = loveModule.image.newImageData(64, 64)

	for y = 0, 63 do
		for x = 0, 63 do
			local dx = x - 31.5
			local dy = y - 31.5
			local radius = math.sqrt(dx * dx + dy * dy) / 45
			local stripe = ((math.floor((x + y) / 8) % 2) == 0) and 0.12 or 0
			imageData:setPixel(x, y, 0.12 + radius * 0.2, 0.58 + stripe, 0.74 + radius * 0.18, 1)
		end
	end

	ctx.images[id] = loveModule.graphics.newImage(imageData)
	return ctx.images[id]
end

local function target(opts)
	opts.duration = opts.duration or 2.6
	opts.fps = opts.fps or 18
	return opts
end

local inventoryExample = nil

local function loadInventoryExample()
	if not inventoryExample then
		inventoryExample = require("examples.inventory.example")
	end
	return inventoryExample
end

local function runtimeBoundsForKey(key)
	local runtime = ui.runtime
	local root = runtime and runtime.root or nil
	if not root then
		return nil
	end

	local found = nil
	local function walk(node, parentX, parentY)
		local layout = node.layout or {}
		local x = parentX + (layout.x or 0)
		local y = parentY + (layout.y or 0)
		local props = node.props or {}

		if props.key == key then
			found = {
				x = x,
				y = y,
				width = layout.width or 0,
				height = layout.height or 0,
			}
			return true
		end

		local childX = x
		local childY = y
		if node.type == "scrollView" then
			childY = y - ((runtime.scrollOffsets and runtime.scrollOffsets[node.path]) or 0)
		end

		for _, child in ipairs(node.children or {}) do
			if walk(child, childX, childY) then
				return true
			end
		end
		return false
	end

	walk(root, 0, 0)
	return found
end

local function moveCapturePointer(ctx, x, y)
	local previousX = ctx.pointerX or x
	local previousY = ctx.pointerY or y
	ui.mousemoved(x, y, x - previousX, y - previousY)
	ctx.pointerX = x
	ctx.pointerY = y
end

local function centerOf(bounds)
	return bounds.x + bounds.width / 2, bounds.y + bounds.height / 2
end

local function driveInventoryDrag(ctx, t)
	local source = runtimeBoundsForKey("satchel-slot-3")
	local targetSlot = runtimeBoundsForKey("satchel-slot-7")
	if not source or not targetSlot then
		return
	end

	local startX, startY = centerOf(source)
	local targetX, targetY = centerOf(targetSlot)
	local startTime = 0.5
	local releaseTime = 2.05

	if t < startTime then
		moveCapturePointer(ctx, startX, startY)
		return
	end

	if not ctx.inventoryDragStarted then
		moveCapturePointer(ctx, startX, startY)
		ui.mousepressed(startX, startY, 1)
		ctx.inventoryDragStarted = true
	end

	if not ctx.inventoryDragReleased then
		local progress = math.min(1, math.max(0, (t - startTime) / (releaseTime - startTime)))
		local eased = progress * progress * (3 - 2 * progress)
		local x = lerp(startX, targetX, eased)
		local y = lerp(startY, targetY, eased) - math.sin(progress * math.pi) * 42
		moveCapturePointer(ctx, x, y)

		if t >= releaseTime then
			moveCapturePointer(ctx, targetX, targetY)
			ui.mousereleased(targetX, targetY, 1)
			ctx.inventoryDragReleased = true
		end
	end
end

local targetModules = {
	"inventory_drag_drop",
	"getting_started",
	"components",
	"layout",
	"styling",
	"runtime",
	"callback_bus",
	"i18n",
	"accessibility",
	"responsive",
	"custom_draw",
	"animations",
	"feedback",
	"scenes_modals",
	"transitions",
	"navigation",
	"menori",
	"dialogue",
	"performance"
}

local targetEnv = {
	ui = ui,
	palette = palette,
	cloneColor = cloneColor,
	lerp = lerp,
	wave = wave,
	remember = remember,
	panelProps = panelProps,
	panel = panel,
	pill = pill,
	metric = metric,
	header = header,
	stage = stage,
	codeBlock = codeBlock,
	eventList = eventList,
	makeProceduralImage = makeProceduralImage,
	loadInventoryExample = loadInventoryExample,
	runtimeBoundsForKey = runtimeBoundsForKey,
	moveCapturePointer = moveCapturePointer,
	centerOf = centerOf,
	driveInventoryDrag = driveInventoryDrag,
	target = target
}

local targets = {}

for _, moduleName in ipairs(targetModules) do
	local buildTarget = require("doc_gifs.examples." .. moduleName)
	targets[#targets + 1] = buildTarget(targetEnv)
end

return targets
