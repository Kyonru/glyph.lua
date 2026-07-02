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
		id = "accessibility",
		title = "Accessibility",
		docs = { "docs/accessibility.md" },
		alt = "Animated GIF showing Glyph semantic labels, focus events, live announcements, and snapshots.",
		setup = function(ctx)
			ctx.events = { "semantic tree ready" }
			ui.accessibility.configure({
				enabled = true,
				announceOnFocus = true,
				announceOnActivate = true,
			})
			ctx.offAccessibility = ui.on("accessibility", function(event)
				remember(ctx, (event.kind or "event") .. ": " .. tostring(event.message or event.label or ""), 5)
			end)
		end,
		actions = {
			{
				at = 0.55,
				run = function()
					ui.accessibility.announce("Autosave complete", { kind = "live", live = "polite" })
				end,
			},
			{
				at = 1.2,
				run = function(ctx)
					remember(ctx, "snapshot: button, meter, log", 5)
				end,
			},
			{
				at = 1.85,
				run = function()
					ui.accessibility.announce("Modal opened", { kind = "announce" })
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Accessibility",
				"Metadata, snapshots, and events for app-owned adapters.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("semantic nodes", { flex = 1, height = 286 }, {
						ui.button({
							label = "Launch",
							accessibilityLabel = "Launch mission",
							accessibilityDescription = "Starts the selected mission",
						}),
						ui.meter({
							value = 60 + wave(ctx, 2) * 30,
							max = 100,
							label = "Power",
							accessibilityValueText = "Power level changing",
							height = 16,
							fillStyle = { background = palette.gold },
						}),
						ui.text("Live status: autosave complete", {
							accessibilityLive = "polite",
							style = { color = palette.text },
						}),
					}),
					eventList(ctx, "adapter events"),
				})
			)
		end,
	})
end
