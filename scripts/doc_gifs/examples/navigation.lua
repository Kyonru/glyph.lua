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
		id = "navigation",
		title = "Spatial Navigation",
		docs = { "docs/navigation.md" },
		alt = "Animated GIF showing Glyph spatial navigation focus moving through buttons and scoped groups.",
		setup = function(ctx)
			ctx.focus = 1
		end,
		actions = {
			{
				at = 0.45,
				run = function(ctx)
					ctx.focus = 2
				end,
			},
			{
				at = 0.9,
				run = function(ctx)
					ctx.focus = 4
				end,
			},
			{
				at = 1.35,
				run = function(ctx)
					ctx.focus = 5
				end,
			},
			{
				at = 1.95,
				run = function(ctx)
					ctx.focus = 3
				end,
			},
		},
		component = function(ctx)
			local buttons = {}
			for index, label in ipairs({ "Scan", "Map", "Load", "Stats", "Party", "Exit" }) do
				buttons[index] = ui.button({
					label = label,
					width = 138,
					height = 58,
					active = ctx.focus == index,
					navGroup = index <= 3 and "top" or "bottom",
					style = {
						background = ctx.focus == index and cloneColor(palette.teal, 0.28)
							or cloneColor(palette.blue, 0.12),
						borderColor = ctx.focus == index and palette.teal or palette.border,
						borderWidth = ctx.focus == index and 2 or 1,
						radius = 7,
					},
				})
			end

			return stage(
				ctx,
				"Navigation",
				"Directional focus works without layout-specific widgets.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("focus grid", { flex = 1, height = 286 }, {
						ui.row({ gap = 10 }, { buttons[1], buttons[2], buttons[3] }),
						ui.row({ gap = 10 }, { buttons[4], buttons[5], buttons[6] }),
						ui.text(
							"Scripted arrows move through focusable nodes and nav groups.",
							{ style = { color = palette.muted } }
						),
					}),
					panel("scope", { width = 320, height = 286 }, {
						metric("focused", tostring(ctx.focus), palette.gold),
						ui.box({
							width = 252,
							height = 96,
							style = {
								background = cloneColor(palette.violet, 0.18),
								borderColor = palette.violet,
								borderWidth = 1,
								radius = 8,
							},
						}, {
							ui.text(
								"navScope submenu",
								{ position = "absolute", left = 18, top = 34, style = { color = palette.text } }
							),
						}),
					}),
				})
			)
		end,
	})
end
