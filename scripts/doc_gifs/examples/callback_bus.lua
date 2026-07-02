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
		id = "callback-bus",
		title = "Callback Bus",
		docs = { "docs/callback-bus.md" },
		alt = "Animated GIF showing Glyph callback bus priority order and event dispatch.",
		setup = function(ctx)
			ctx.events = {}
			ctx.bus = ui.CallbackBus.new({ "event" })
			ctx.bus:register("event", function(name)
				remember(ctx, "priority -10: " .. name, 6)
			end, { priority = -10 })
			ctx.bus:register("event", function(name)
				remember(ctx, "priority 0: " .. name, 6)
			end)
			ctx.bus:register("event", function(name)
				remember(ctx, "priority 10: " .. name, 6)
			end, { priority = 10 })
		end,
		actions = {
			{
				at = 0.45,
				run = function(ctx)
					ctx.bus:dispatch("event", "beforeRender")
				end,
			},
			{
				at = 1.2,
				run = function(ctx)
					ctx.bus:dispatch("event", "feedback")
				end,
			},
			{
				at = 1.85,
				run = function(ctx)
					ctx.bus:dispatch("event", "afterRender")
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Callback Bus",
				"Registrations run by priority with snapshot-safe dispatch.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("registered handlers", { width = 430, height = 282 }, {
						ui.row({ gap = 8, align = "center" }, {
							pill("priority -10", palette.teal),
							ui.text("adapter first", { style = { color = palette.muted } }),
						}),
						ui.row({ gap = 8, align = "center" }, {
							pill("priority 0", palette.gold),
							ui.text("default work", { style = { color = palette.muted } }),
						}),
						ui.row({ gap = 8, align = "center" }, {
							pill("priority 10", palette.coral),
							ui.text("late observer", { style = { color = palette.muted } }),
						}),
						ui.text('dispatch("event", name)', { textStyle = "caption", style = { color = palette.text } }),
					}),
					eventList(ctx, "dispatch log"),
				})
			)
		end,
	})
end
