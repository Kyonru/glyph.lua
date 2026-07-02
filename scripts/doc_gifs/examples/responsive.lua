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
		id = "responsive",
		title = "Responsive Helpers",
		docs = { "docs/responsive.md" },
		alt = "Animated GIF showing Glyph responsive breakpoints, columns, and virtual viewport mapping.",
		setup = function(ctx)
			ctx.simWidth = 680
		end,
		update = function(ctx)
			ctx.simWidth = math.floor(620 + wave(ctx, 1.8) * 320)
		end,
		component = function(ctx)
			local plan = ui.columns(ctx.simWidth, { min = 210, maxCount = 3, gap = 10 })
			local breakpoint = ctx.simWidth >= 860 and "lg" or ctx.simWidth >= 720 and "md" or "sm"
			local cards = {}
			local labels = { "systems", "party", "map" }
			local colors = { palette.teal, palette.gold, palette.coral }
			for index = 1, plan.count do
				cards[index] = ui.box({
					width = plan.width,
					height = 104,
					style = {
						background = cloneColor(colors[index], 0.2),
						borderColor = colors[index],
						borderWidth = 1,
						radius = 8,
					},
					draw = function(_, x, y, width, height, loveModule)
						local g = loveModule.graphics
						g.setColor(colors[index][1], colors[index][2], colors[index][3], 0.16)
						for stripe = 0, 4 do
							g.rectangle("fill", x + 16 + stripe * 18, y + height - 24, 10, 6, 3, 3)
						end
						g.setColor(1, 1, 1, 0.08)
						g.rectangle("line", x + 10, y + 10, width - 20, height - 20, 6, 6)
					end,
				}, {
					ui.text(labels[index], {
						position = "absolute",
						left = 18,
						top = 22,
						textStyle = "h2",
						style = { color = palette.text },
					}),
					ui.text("column " .. tostring(index), {
						position = "absolute",
						left = 18,
						top = 62,
						textStyle = "caption",
						style = { color = cloneColor(palette.text, 0.72) },
					}),
				})
			end

			return stage(
				ctx,
				"Responsive",
				"Breakpoints and viewport adapters keep game UI predictable.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("adaptive command deck", { flex = 1, height = 308 }, {
						ui.row({ width = "100%", gap = 12, align = "center" }, {
							metric("container", tostring(ctx.simWidth) .. "px", palette.teal),
							metric("breakpoint", breakpoint, palette.gold),
							metric("columns", tostring(plan.count), palette.coral),
						}),
						ui.box({
							width = "100%",
							height = 148,
							padding = 12,
							display = "column",
							style = {
								background = { 0.025, 0.034, 0.046, 1 },
								borderColor = cloneColor(palette.blue, 0.42),
								borderWidth = 1,
								radius = 8,
							},
						}, {
							ui.row({ gap = plan.gap, width = "100%" }, cards),
						}),
						ui.meter({
							value = ctx.simWidth - 600,
							min = 0,
							max = 360,
							height = 14,
							fillStyle = { background = palette.blue },
							trackStyle = { background = { 1, 1, 1, 0.08 } },
						}),
					}),
					panel("virtual viewport", { width = 318, height = 308 }, {
						ui.row({ gap = 10, align = "center" }, {
							pill("960x540", palette.blue),
							ui.text("screen", { style = { color = palette.muted } }),
						}),
						ui.box({
							width = 270,
							height = 164,
							style = {
								background = cloneColor(palette.blue, 0.15),
								borderColor = palette.blue,
								borderWidth = 1,
								radius = 8,
							},
							draw = function(_, x, y, width, height, loveModule)
								local g = loveModule.graphics
								g.setColor(1, 1, 1, 0.055)
								for gx = 24, width - 24, 28 do
									g.line(x + gx, y + 16, x + gx, y + height - 16)
								end
								for gy = 24, height - 24, 28 do
									g.line(x + 16, y + gy, x + width - 16, y + gy)
								end
								g.setColor(palette.teal[1], palette.teal[2], palette.teal[3], 0.18)
								g.rectangle("fill", x + 64, y + 50, 120, 54, 8, 8)
							end,
						}, {
							ui.box({
								position = "absolute",
								left = 44 + wave(ctx, 3.2) * 148,
								top = 58,
								width = 28,
								height = 28,
								style = {
									background = palette.teal,
									borderColor = { 1, 1, 1, 0.58 },
									borderWidth = 1,
									radius = 14,
								},
							}),
							ui.text(
								"virtual 320x180",
								{ position = "absolute", left = 18, bottom = 18, style = { color = palette.text } }
							),
						}),
						ui.text("Pointer math stays inside the virtual frame.", {
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
