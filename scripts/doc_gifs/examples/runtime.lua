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
		id = "runtime",
		title = "Runtime, Hooks, And Events",
		docs = { "docs/runtime.md" },
		alt = "Animated GIF showing Glyph runtime updates, input events, focus, and render callbacks.",
		setup = function(ctx)
			ctx.events = { "ui.render(App)", "beforeUpdate" }
			ctx.focus = 1
		end,
		actions = {
			{
				at = 0.45,
				run = function(ctx)
					ctx.focus = 2
					remember(ctx, "mousepressed: Run", 5)
				end,
			},
			{
				at = 0.95,
				run = function(ctx)
					remember(ctx, "keypressed: return", 5)
				end,
			},
			{
				at = 1.45,
				run = function(ctx)
					ctx.focus = 3
					remember(ctx, "focusChanged: Filter", 5)
				end,
			},
			{
				at = 2.0,
				run = function(ctx)
					remember(ctx, "afterRender", 5)
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Runtime",
				"One runtime owns hooks, event routing, and draw traversal.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("interactive tree", { flex = 1, height = 294 }, {
						ui.row({ gap = 10 }, {
							ui.button({ label = "Inspect", active = ctx.focus == 1, width = 130 }),
							ui.button({ label = "Run", active = ctx.focus == 2, width = 130 }),
							ui.input({ value = "Filter", width = 190, active = ctx.focus == 3 }),
						}),
						ui.row({ gap = 14, width = "100%", align = "stretch" }, {
							metric("hover", ctx.focus == 1 and "node.1" or "none", palette.teal),
							metric("focus", "node." .. tostring(ctx.focus), palette.gold),
							metric("dirty", wave(ctx, 6) > 0.45 and "true" or "false", palette.coral),
						}),
						ui.meter({
							value = 40 + wave(ctx, 3.6) * 55,
							max = 100,
							height = 14,
							fillStyle = { background = palette.blue },
						}),
					}),
					eventList(ctx, "runtime callbacks"),
				})
			)
		end,
	})
end
