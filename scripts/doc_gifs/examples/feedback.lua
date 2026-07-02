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
		id = "feedback",
		title = "Feedback",
		docs = { "docs/feedback.md" },
		alt = "Animated GIF showing Glyph feedback sequences, visual animation, audio metadata, and emitted events.",
		setup = function(ctx)
			ctx.events = {}
			ctx.feedbackBursts = {}
			ctx.audioCount = 0
			ctx.emitCount = 0
			ctx.callbackCount = 0
			ctx.feedbackEnergy = 0

			local function spawnBurst(kind, color)
				local burst = {
					time = ctx.time or 0,
					kind = kind or "feedback",
					color = color or palette.teal,
					index = #ctx.feedbackBursts + 1,
				}
				ctx.feedbackBursts[#ctx.feedbackBursts + 1] = burst
				while #ctx.feedbackBursts > 8 do
					table.remove(ctx.feedbackBursts, 1)
				end
			end

			ui.feedback.clear()
			ui.feedback.define("docs.pop", {
				{
					kind = "parallel",
					steps = {
						{
							kind = "animate",
							to = { scale = 1.18, y = -8, rotation = -0.025 },
							duration = 0.08,
							ease = "quadout",
						},
						{ kind = "audio", cue = "ui-pop" },
						{ kind = "emit", event = "spark-ring", payload = { count = 16 } },
						{
							kind = "callback",
							callback = function()
								ctx.callbackCount = (ctx.callbackCount or 0) + 1
								spawnBurst("callback", palette.violet)
								remember(ctx, "callback: marked run " .. tostring(ctx.callbackCount), 5)
							end,
						},
					},
				},
				{ kind = "wait", duration = 0.04 },
				{ kind = "animate", to = { scale = 1, y = 0, rotation = 0 }, duration = 0.24, ease = "backout" },
			})
			ui.on("feedback", function(event)
				ctx.emitCount = (ctx.emitCount or 0) + 1
				spawnBurst("emit", palette.coral)
				remember(ctx, "emit: " .. tostring(event.event or event.kind or "spark"), 5)
			end)
			ui.on("audio", function(event)
				ctx.audioCount = (ctx.audioCount or 0) + 1
				spawnBurst("audio", palette.gold)
				remember(ctx, "audio: " .. tostring(event.cue or "cue"), 5)
			end)
		end,
		update = function(ctx)
			local energy = 0
			for index = #ctx.feedbackBursts, 1, -1 do
				local burst = ctx.feedbackBursts[index]
				local age = (ctx.time or 0) - (burst.time or 0)
				if age > 1 then
					table.remove(ctx.feedbackBursts, index)
				elseif age >= 0 then
					local p = age / 1
					energy = energy + (1 - p) * (1 - p)
				end
			end
			ctx.feedbackEnergy = math.min(1, energy)
		end,
		actions = {
			{
				at = 0.48,
				run = function(ctx)
					local b = ctx.feedbackButtonBounds or { x = 94, y = 186, width = 340, height = 96 }
					ui.mousepressed(b.x + b.width / 2, b.y + b.height / 2, 1)
				end,
			},
			{
				at = 0.62,
				run = function(ctx)
					local b = ctx.feedbackButtonBounds or { x = 94, y = 186, width = 340, height = 96 }
					ui.mousereleased(b.x + b.width / 2, b.y + b.height / 2, 1)
				end,
			},
			{
				at = 1.46,
				run = function(ctx)
					local b = ctx.feedbackButtonBounds or { x = 94, y = 186, width = 340, height = 96 }
					ui.mousepressed(b.x + b.width / 2, b.y + b.height / 2, 1)
				end,
			},
			{
				at = 1.6,
				run = function(ctx)
					local b = ctx.feedbackButtonBounds or { x = 94, y = 186, width = 340, height = 96 }
					ui.mousereleased(b.x + b.width / 2, b.y + b.height / 2, 1)
				end,
			},
		},
		component = function(ctx)
			local activeCount = #(ui.feedback.active() or {})
			local energy = ctx.feedbackEnergy or 0
			local function feedbackMetric(label, value, color)
				return ui.box({
					flex = 1,
					height = 48,
					padding = 7,
					display = "column",
					gap = 2,
					style = {
						background = cloneColor(color or palette.teal, 0.12),
						borderColor = cloneColor(color or palette.teal, 0.42),
						borderWidth = 1,
						radius = 6,
					},
				}, {
					ui.text(label, { textStyle = "caption", style = { color = palette.muted } }),
					ui.text(value, { textStyle = "h2", style = { color = color or palette.text } }),
				})
			end
			local function fxLayer()
				return ui.box({
					position = "absolute",
					inset = 0,
					interactive = false,
					draw = function(_, x, y, width, height, loveModule, _, drawCtx)
						local g = loveModule.graphics
						local cx = x + width * 0.5
						local cy = y + height * 0.48
						local previousLineWidth = g.getLineWidth and g.getLineWidth() or nil

						g.setColor(palette.teal[1], palette.teal[2], palette.teal[3], 0.08 + energy * 0.16)
						g.rectangle("fill", x + 6, y + 6, width - 12, height - 12, 10, 10)

						for _, burst in ipairs(ctx.feedbackBursts or {}) do
							local age = (ctx.time or 0) - (burst.time or 0)
							if age >= 0 and age <= 1 then
								local p = age / 1
								local fade = 1 - p
								local color = burst.color or palette.teal
								local ringRadius = 38 + p * 124 + (burst.index % 3) * 10
								if g.setLineWidth then
									g.setLineWidth(2 + fade * 3)
								end
								g.setColor(color[1], color[2], color[3], fade * 0.58)
								if g.circle then
									g.circle("line", cx, cy, ringRadius)
								end

								local count = 16
								for particle = 1, count do
									local angle = (particle / count) * math.pi * 2 + burst.index * 0.41
									local distance = 22 + p * (96 + (particle % 4) * 9)
									local px = cx + math.cos(angle) * distance
									local py = cy + math.sin(angle) * distance * 0.62
									local size = 3 + fade * 5 + (particle % 3)
									g.setColor(color[1], color[2], color[3], fade * 0.72)
									if g.circle then
										g.circle("fill", px, py, size)
									else
										drawCtx:rect("fill", px - size / 2, py - size / 2, size, size, size / 2)
									end
								end
							end
						end

						if previousLineWidth and g.setLineWidth then
							g.setLineWidth(previousLineWidth)
						end
					end,
				})
			end

			return stage(
				ctx,
				"Feedback",
				"Sequences compose animation, audio metadata, and app-owned FX.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("triggerable sequence", { flex = 1, height = 308, gap = 10 }, {
						ui.stack({ width = "100%", height = 194 }, {
							fxLayer(),
							ui.button({
								label = activeCount > 0 and "Feedback Running" or "Launch Pulse",
								position = "absolute",
								left = 36,
								top = 48,
								width = 338,
								height = 96,
								onLayout = function(bounds)
									ctx.feedbackButtonBounds = bounds
								end,
								feedback = {
									press = "docs.pop",
									activate = "docs.pop",
								},
								style = {
									background = activeCount > 0 and cloneColor(palette.teal, 0.42)
										or cloneColor(palette.teal, 0.24),
									borderColor = activeCount > 0 and palette.gold or palette.teal,
									borderWidth = 3,
									radius = 10,
									color = palette.text,
									pressed = {
										background = cloneColor(palette.gold, 0.34),
										borderColor = palette.gold,
									},
								},
							}),
						}),
						ui.row({ width = "100%", gap = 10 }, {
							feedbackMetric("audio", tostring(ctx.audioCount or 0), palette.gold),
							feedbackMetric("emit", tostring(ctx.emitCount or 0), palette.coral),
							feedbackMetric("active", tostring(activeCount), palette.teal),
						}),
						ui.meter({
							value = 24 + energy * 76,
							max = 100,
							height = 16,
							fillStyle = { background = palette.coral },
							trackStyle = { background = { 1, 1, 1, 0.08 } },
						}),
					}),
					eventList(ctx, "app-owned events"),
				})
			)
		end,
	})
end
