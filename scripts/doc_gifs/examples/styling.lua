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
		id = "styling",
		title = "Styling And Themes",
		docs = { "docs/styling.md" },
		alt = "Animated GIF showing Glyph theme colors, variants, and state styles.",
		setup = function(ctx)
			ctx.mode = 1
		end,
		update = function(ctx)
			ctx.glow = wave(ctx, 4.8)
		end,
		actions = {
			{
				at = 0.7,
				run = function(ctx)
					ctx.mode = 2
				end,
			},
			{
				at = 1.4,
				run = function(ctx)
					ctx.mode = 3
				end,
			},
			{
				at = 2.1,
				run = function(ctx)
					ctx.mode = 1
				end,
			},
		},
		component = function(ctx)
			local accents = { palette.teal, palette.gold, palette.coral }
			local accent = accents[ctx.mode or 1]
			return stage(
				ctx,
				"Styling",
				"Theme tokens, variants, and states resolve into draw styles.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("theme tokens", { width = 336, height = 286 }, {
						ui.row({ gap = 10 }, {
							ui.box({ width = 56, height = 56, style = { background = palette.teal, radius = 8 } }),
							ui.box({ width = 56, height = 56, style = { background = palette.gold, radius = 8 } }),
							ui.box({ width = 56, height = 56, style = { background = palette.coral, radius = 8 } }),
							ui.box({ width = 56, height = 56, style = { background = palette.violet, radius = 8 } }),
						}),
						ui.meter({
							value = 35 + ctx.glow * 60,
							max = 100,
							height = 16,
							fillStyle = { background = accent },
						}),
						ui.text(
							"Active accent follows scripted variant changes.",
							{ wrap = true, width = "100%", style = { color = palette.muted } }
						),
					}),
					panel("state styles", { flex = 1, height = 286 }, {
						ui.row({ gap = 10 }, {
							ui.button({
								label = "Default",
								width = 132,
								style = { borderWidth = 1, radius = 7 },
							}),
							ui.button({
								label = "Active",
								width = 132,
								active = true,
								style = {
									background = cloneColor(accent, 0.24),
									borderColor = accent,
									borderWidth = 2,
									radius = 7,
								},
							}),
							ui.button({
								label = "Pressed",
								width = 132,
								active = ctx.glow > 0.48,
								style = {
									background = ctx.glow > 0.48 and cloneColor(palette.coral, 0.32)
										or cloneColor(palette.blue, 0.2),
									borderColor = ctx.glow > 0.48 and palette.coral or palette.border,
									borderWidth = 2,
									radius = 7,
									transition = { background = 0.16 },
								},
							}),
						}),
						ui.box({
							height = 112,
							width = "100%",
							style = {
								background = cloneColor(accent, 0.14 + ctx.glow * 0.12),
								borderColor = cloneColor(accent, 0.62),
								borderWidth = 1,
								radius = 8,
							},
						}, {
							ui.text("style.transition blends visual state without changing layout", {
								position = "absolute",
								left = 18,
								top = 40,
								style = { color = palette.text },
							}),
						}),
					}),
				})
			)
		end,
	})
end
