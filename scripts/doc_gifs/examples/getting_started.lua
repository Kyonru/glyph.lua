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
		id = "getting-started",
		title = "Getting Started",
		docs = { "docs/getting-started.md" },
		alt = "Animated GIF showing a minimal Glyph counter app rendering and updating.",
		setup = function(ctx)
			ctx.count = 0
			ctx.input = "debugger"
		end,
		update = function(ctx)
			ctx.flash = wave(ctx, 7) > 0.58
		end,
		actions = {
			{
				at = 0.55,
				run = function(ctx)
					ctx.count = ctx.count + 1
				end,
			},
			{
				at = 1.15,
				run = function(ctx)
					ctx.input = "debugger panel"
				end,
			},
			{
				at = 1.75,
				run = function(ctx)
					ctx.count = ctx.count + 1
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Getting Started",
				"A small app function becomes a live UI tree.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					codeBlock({
						"local function App()",
						"  local count = " .. tostring(ctx.count),
						"  return ui.column({ gap = 8 }, {",
						'    ui.button({ label = "Increment" })',
						'    ui.text("Count: " .. count)',
						"  })",
						"end",
						"",
						"ui.render(App)",
					}),
					panel("running preview", { flex = 1, height = 260 }, {
						ui.input({
							value = ctx.input,
							width = "100%",
							placeholder = "Panel name",
						}),
						ui.button({
							label = "Increment",
							active = ctx.flash,
							style = {
								background = ctx.flash and cloneColor(palette.teal, 0.28)
									or cloneColor(palette.blue, 0.22),
								borderColor = ctx.flash and palette.teal or palette.border,
								borderWidth = 1,
								radius = 7,
							},
						}),
						ui.text(
							"Count: " .. tostring(ctx.count),
							{ textStyle = "h2", style = { color = palette.gold } }
						),
						ui.meter({
							value = ctx.count,
							max = 3,
							height = 16,
							fillStyle = { background = palette.teal },
						}),
					}),
				})
			)
		end,
	})
end
