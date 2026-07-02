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
		id = "layout",
		title = "Layout",
		docs = { "docs/layout.md" },
		alt = "Animated GIF showing Glyph rows, columns, responsive grids, stack layering, and absolute positioning.",
		update = function(ctx)
			ctx.slide = wave(ctx, 2.2)
			ctx.layoutWidth = math.floor(286 + wave(ctx, 1.55, 0.45) * 110)
		end,
		component = function(ctx)
			local slide = ctx.slide or 0
			local demoWidth = ctx.layoutWidth or 340
			local responsivePlan = ui.columns(demoWidth - 20, { min = 64, maxCount = 5, gap = 5 })
			local gridColors = { palette.teal, palette.gold, palette.coral, palette.blue, palette.violet, palette.teal }
			local gridCells = {}
			for index = 1, 20 do
				local colorValue = gridColors[((index - 1) % #gridColors) + 1]
				local active = index == 7 or index == 14 or index == 19
				gridCells[#gridCells + 1] = ui.box({
					style = {
						background = cloneColor(
							colorValue,
							active and (0.3 + wave(ctx, 5 + index * 0.1) * 0.18) or 0.18
						),
						borderColor = colorValue,
						borderWidth = active and 2 or 1,
						radius = 5,
					},
				})
			end

			return stage(
				ctx,
				"Layout",
				"Responsive flow, grid, and absolute overlays share one tree.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("responsive flow and grid", { width = 430 }, {
						ui.row({ width = "100%", gap = 8 }, {
							metric("container", tostring(demoWidth) .. "px", palette.teal),
							metric("columns", tostring(responsivePlan.count), palette.gold),
						}),
						ui.column({ width = "100%", align = "center" }, {
							ui.column({
								width = demoWidth,
								padding = 10,
								gap = 8,
								style = {
									background = { 0.03, 0.04, 0.055, 1 },
									borderColor = cloneColor(palette.blue, 0.46),
									borderWidth = 1,
									radius = 8,
								},
							}, {
								ui.row({ width = "100%", height = 44, gap = 6, align = "stretch" }, {
									ui.box({
										flex = 1,
										padding = 6,
										display = "column",
										justify = "center",
										style = {
											background = cloneColor(palette.teal, 0.18),
											borderColor = palette.teal,
											borderWidth = 1,
											radius = 6,
										},
									}, {
										ui.text("nav", { textStyle = "caption", style = { color = palette.text } }),
									}),
									ui.box({
										flex = 1.55,
										padding = 6,
										display = "column",
										justify = "center",
										style = {
											background = cloneColor(palette.gold, 0.16),
											borderColor = palette.gold,
											borderWidth = 1,
											radius = 6,
										},
									}, {
										ui.text("content", { textStyle = "caption", style = { color = palette.text } }),
									}),
									ui.box({
										flex = 1,
										padding = 6,
										display = "column",
										justify = "center",
										style = {
											background = cloneColor(palette.coral, 0.18),
											borderColor = palette.coral,
											borderWidth = 1,
											radius = 6,
										},
									}, {
										ui.text("tools", { textStyle = "caption", style = { color = palette.text } }),
									}),
								}),
								ui.grid({
									width = "100%",
									minCellWidth = 64,
									maxColumns = 5,
									cellHeight = 18,
									gap = 5,
								}, gridCells),
							}),
						}),
						ui.row({ width = "100%", height = 26, gap = 8, align = "center" }, {
							ui.text(
								"percent",
								{ width = 70, textStyle = "caption", style = { color = palette.muted } }
							),
							ui.box({
								width = "72%",
								height = 20,
								style = {
									background = cloneColor(palette.violet, 0.2),
									borderColor = palette.violet,
									borderWidth = 1,
									radius = 6,
								},
							}),
						}),
					}),
					panel("stack and absolute", { flex = 1, height = 292 }, {
						ui.stack({ width = "100%", height = 214 }, {
							ui.box({
								position = "absolute",
								inset = 0,
								interactive = false,
								style = {
									background = { 0.03, 0.04, 0.055, 1 },
									borderColor = palette.border,
									borderWidth = 1,
									radius = 8,
								},
							}),
							ui.box({
								position = "absolute",
								left = tostring(math.floor(8 + slide * 26)) .. "%",
								top = 46,
								width = "38%",
								height = 78,
								zScope = "root",
								zIndex = 8,
								style = {
									background = cloneColor(palette.teal, 0.22),
									borderColor = palette.teal,
									borderWidth = 2,
									radius = 8,
								},
							}, {
								ui.text(
									"root absolute",
									{ position = "absolute", left = 16, top = 26, style = { color = palette.text } }
								),
							}),
							ui.box({
								position = "absolute",
								right = "6%",
								bottom = "10%",
								width = "42%",
								height = 78,
								zIndex = 3,
								style = {
									background = cloneColor(palette.coral, 0.24),
									borderColor = palette.coral,
									borderWidth = 2,
									radius = 8,
								},
							}, {
								ui.text(
									"percent anchored",
									{ position = "absolute", left = 18, top = 26, style = { color = palette.text } }
								),
							}),
						}),
					}),
				})
			)
		end,
	})
end
