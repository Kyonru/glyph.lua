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
		id = "scenes-modals",
		title = "Scenes And Modals",
		docs = { "docs/scenes-and-modals.md" },
		alt = "Animated GIF showing Glyph scene layers, overlays, modal blocking, and backdrop behavior.",
		setup = function(ctx)
			ctx.modal = false
		end,
		actions = {
			{
				at = 0.75,
				run = function(ctx)
					ctx.modal = true
				end,
			},
			{
				at = 1.75,
				run = function(ctx)
					ctx.modal = false
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Scenes And Modals",
				"Layered roots route input from top to bottom.",
				ui.stack({ width = "100%", height = 304 }, {
					ui.box({
						position = "absolute",
						left = 20,
						top = 18,
						width = 480,
						height = 226,
						style = {
							background = cloneColor(palette.blue, 0.2),
							borderColor = palette.blue,
							borderWidth = 2,
							radius = 8,
						},
					}, {
						ui.text(
							"main scene",
							{ position = "absolute", left = 18, top = 18, style = { color = palette.text } }
						),
						ui.meter({
							position = "absolute",
							left = 18,
							top = 68,
							width = 360,
							height = 16,
							value = 70,
							max = 100,
							fillStyle = { background = palette.teal },
						}),
					}),
					ui.box({
						position = "absolute",
						right = 36,
						top = 42,
						width = 260,
						height = 112,
						zIndex = 3,
						style = {
							background = cloneColor(palette.gold, 0.2),
							borderColor = palette.gold,
							borderWidth = 2,
							radius = 8,
						},
					}, {
						ui.text(
							"non-blocking overlay",
							{ position = "absolute", left = 16, top = 40, style = { color = palette.text } }
						),
					}),
					ctx.modal and ui.box({
						position = "absolute",
						inset = 0,
						zIndex = 10,
						style = { background = { 0, 0, 0, 0.42 }, radius = 8 },
					}, {
						ui.box({
							position = "absolute",
							left = 294,
							top = 76,
							width = 300,
							height = 142,
							style = {
								background = palette.panel2,
								borderColor = palette.coral,
								borderWidth = 2,
								radius = 8,
							},
						}, {
							ui.text(
								"modal layer",
								{ position = "absolute", left = 22, top = 28, style = { color = palette.text } }
							),
							ui.text(
								"blocking input",
								{ position = "absolute", left = 22, top = 66, style = { color = palette.muted } }
							),
						}),
					}) or nil,
				})
			)
		end,
	})
end
