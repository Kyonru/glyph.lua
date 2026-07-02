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
		id = "performance",
		title = "Performance",
		docs = { "docs/performance.md" },
		alt = "Animated GIF showing Glyph memoized rows, static nodes, visible windows, FPS, and bounded work.",
		setup = function(ctx)
			ctx.offset = 1
		end,
		update = function(ctx)
			ctx.offset = 1 + math.floor(wave(ctx, 1.7) * 16)
		end,
		component = function(ctx)
			local rows = {}
			for i = 0, 7 do
				local index = ctx.offset + i
				rows[#rows + 1] = ui.row({
					height = 28,
					width = "100%",
					gap = 8,
					align = "center",
					style = {
						background = i % 2 == 0 and { 1, 1, 1, 0.035 } or { 1, 1, 1, 0.015 },
						radius = 4,
					},
				}, {
					ui.text("#" .. tostring(index), { width = 54, style = { color = palette.muted } }),
					ui.meter({
						value = (index * 13) % 100,
						max = 100,
						height = 10,
						flex = 1,
						fillStyle = { background = ({ palette.teal, palette.gold, palette.coral })[index % 3 + 1] },
					}),
					ui.text("static row", { width = 92, textStyle = "caption", style = { color = palette.text } }),
				})
			end

			return stage(
				ctx,
				"Performance",
				"Memo, static nodes, and visible windows keep work bounded.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("visible rows", { flex = 1, height = 310 }, rows),
					panel("work budget", { width = 318, height = 310 }, {
						metric("fps", tostring(ctx.fps or 18), palette.blue),
						metric("mounted rows", "8 / 10k", palette.teal),
						metric("memo hits", tostring(80 + math.floor(wave(ctx, 4.5) * 18)) .. "%", palette.gold),
						metric("layout pass", wave(ctx, 7) > 0.5 and "dirty" or "clean", palette.coral),
						ui.text("Large data demos should show bounded rendering, not full-list churn.", {
							wrap = true,
							width = "100%",
							style = { color = palette.muted },
						}),
					}),
				})
			)
		end,
	})
end
