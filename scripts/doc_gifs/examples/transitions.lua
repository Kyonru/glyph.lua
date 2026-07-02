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
		id = "transitions",
		title = "Transitions",
		docs = { "docs/transitions.md" },
		alt = "Animated GIF showing Glyph fade, slide, shader-style, and animated layer transitions.",
		update = function(ctx)
			ctx.progress = wave(ctx, 2.1)
		end,
		component = function(ctx)
			local p = ctx.progress or 0
			return stage(
				ctx,
				"Transitions",
				"Layers can fade, slide, animate, or delegate custom drawing.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("built-ins", { flex = 1, height = 284 }, {
						ui.stack({ width = "100%", height = 190 }, {
							ui.box({
								position = "absolute",
								left = 20,
								top = 22,
								width = 280,
								height = 128,
								style = {
									background = cloneColor(palette.blue, 0.22),
									borderColor = palette.blue,
									borderWidth = 1,
									radius = 8,
								},
							}),
							ui.box({
								position = "absolute",
								left = 72 + p * 190,
								top = 52,
								width = 240,
								height = 128,
								style = {
									background = cloneColor(palette.teal, 0.18 + p * 0.18),
									borderColor = palette.teal,
									borderWidth = 2,
									radius = 8,
								},
							}, {
								ui.text(
									"slide + fade",
									{ position = "absolute", left = 22, top = 52, style = { color = palette.text } }
								),
							}),
						}),
					}),
					panel("custom transition", { width = 320, height = 284 }, {
						ui.box({
							width = 250,
							height = 150,
							draw = function(_, x, y, width, height, loveModule)
								local g = loveModule.graphics
								g.setColor(0.03, 0.04, 0.055, 1)
								g.rectangle("fill", x, y, width, height, 8, 8)
								for i = 1, 9 do
									local alpha = math.max(0, 0.42 - math.abs(i / 9 - p) * 0.8)
									g.setColor(palette.coral[1], palette.coral[2], palette.coral[3], alpha)
									g.rectangle("fill", x + i * 22, y + 14, 14, height - 28, 7, 7)
								end
								g.setColor(1, 1, 1, 0.74)
								g.rectangle("line", x, y, width, height, 8, 8)
							end,
						}),
						ui.text("ctx.drawLayer() stays app-composable.", { style = { color = palette.muted } }),
					}),
				})
			)
		end,
	})
end
