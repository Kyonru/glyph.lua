return function(env)
	local ui = env.ui
	local palette = env.palette
	local cloneColor = env.cloneColor
	local lerp = env.lerp
	local wave = env.wave
	local remember = env.remember
	local panelProps = env.panelProps
	local panel = env.panel
	local pill = env.pill
	local metric = env.metric
	local header = env.header
	local stage = env.stage
	local codeBlock = env.codeBlock
	local eventList = env.eventList
	local makeProceduralImage = env.makeProceduralImage
	local loadInventoryExample = env.loadInventoryExample
	local runtimeBoundsForKey = env.runtimeBoundsForKey
	local moveCapturePointer = env.moveCapturePointer
	local centerOf = env.centerOf
	local driveInventoryDrag = env.driveInventoryDrag
	local target = env.target

	return target({
		id = "inventory-drag-drop",
		title = "Inventory Drag And Drop",
		docs = { "README.md" },
		gallery = false,
		width = 960,
		height = 540,
		duration = 3.1,
		alt = "Animated GIF showing the Glyph inventory example with potion drag and drop.",
		setup = function(ctx)
			local example = loadInventoryExample()
			example.setup()
			ctx.pointerX = nil
			ctx.pointerY = nil
			ctx.inventoryDragStarted = false
			ctx.inventoryDragReleased = false
		end,
		update = function(ctx, t, dt)
			local example = loadInventoryExample()
			if type(example.update) == "function" then
				example.update(dt)
			end
			driveInventoryDrag(ctx, t)
		end,
		component = function()
			return loadInventoryExample().component("docs-gif")
		end,
	})
end
