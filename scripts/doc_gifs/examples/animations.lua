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
		id = "animations",
		title = "Animations",
		docs = { "docs/animations.md" },
		alt = "Animated GIF showing Glyph enter, exit, meter, and movement animations.",
		setup = function(ctx)
			ctx.values = { meter = 28, x = 0, rotation = 0 }
			ctx.show = true
		end,
		actions = {
			{
				at = 0.35,
				run = function(ctx)
					ui.animation.to(ctx.values, 0.45, { meter = 88, x = 180, rotation = 0.5 }, { ease = "backout" })
				end,
			},
			{
				at = 1.2,
				run = function(ctx)
					ctx.show = false
				end,
			},
			{
				at = 1.75,
				run = function(ctx)
					ctx.show = true
					ui.animation.to(ctx.values, 0.4, { meter = 42, x = 24, rotation = -0.25 }, { ease = "quadinout" })
				end,
			},
		},
		component = function(ctx)
			local card = nil
			if ctx.show then
				card = ui.box({
					key = "doc-animation-card",
					width = 260,
					height = 86,
					enter = {
						duration = 0.24,
						from = { opacity = 0, y = 18, scale = 0.9 },
						to = { opacity = 1, y = 0, scale = 1 },
						ease = "backout",
					},
					exit = { duration = 0.18, to = { opacity = 0, y = -14, scale = 0.94 }, ease = "quadin" },
					style = {
						background = cloneColor(palette.teal, 0.22),
						borderColor = palette.teal,
						borderWidth = 2,
						radius = 8,
					},
				}, {
					ui.text(
						"enter / exit node",
						{ position = "absolute", left = 18, top = 32, style = { color = palette.text } }
					),
				})
			end

			return stage(
				ctx,
				"Animations",
				"Flux-backed visual animation leaves layout stable.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("animated state", { flex = 1, height = 292 }, {
						ui.meter({
							value = ctx.values.meter,
							max = 100,
							height = 18,
							fillStyle = { background = palette.gold },
						}),
						ui.box({
							width = "100%",
							height = 124,
							style = {
								background = { 0.03, 0.04, 0.055, 1 },
								borderColor = palette.border,
								borderWidth = 1,
								radius = 8,
							},
						}, {
							ui.box({
								position = "absolute",
								left = 36 + ctx.values.x,
								top = 42,
								width = 54,
								height = 54,
								style = { background = palette.coral, radius = 7 },
								draw = function(_, x, y, width, height, loveModule, style)
									loveModule.graphics.push()
									loveModule.graphics.translate(x + width / 2, y + height / 2)
									loveModule.graphics.rotate(ctx.values.rotation)
									loveModule.graphics.setColor(style.background)
									loveModule.graphics.rectangle("fill", -width / 2, -height / 2, width, height, 7, 7)
									loveModule.graphics.pop()
								end,
							}),
						}),
					}),
					panel("lifecycle", { width = 320, height = 292 }, { card or ui.box({ width = 260, height = 86 }) }),
				})
			)
		end,
	})
end
