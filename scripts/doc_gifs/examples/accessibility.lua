return function(env)
	local ui = env.ui
	local wave = env.wave
	local remember = env.remember
	local target = env.target
	local colors = {
		chassis = { 0.045, 0.05, 0.052, 1 },
		rail = { 0.065, 0.072, 0.074, 1 },
		field = { 0.035, 0.04, 0.042, 1 },
		surface = { 0.085, 0.095, 0.098, 1 },
		rule = { 0.27, 0.28, 0.28, 1 },
		ruleSoft = { 0.27, 0.28, 0.28, 0.52 },
		text = { 0.93, 0.91, 0.86, 1 },
		muted = { 0.66, 0.64, 0.59, 1 },
		amber = { 0.74, 0.45, 0.08, 1 },
		amberText = { 0.12, 0.085, 0.035, 1 },
	}

	local function rule(color)
		return ui.box({
			width = "100%",
			height = 1,
			interactive = false,
			accessibilityHidden = true,
			style = { background = color or colors.rule },
		})
	end

	local function sectionLabel(label)
		return ui.text(label:upper(), {
			textStyle = "caption",
			accessibilityHidden = true,
			style = { color = colors.muted },
		})
	end

	local function serviceStrip(ctx)
		return ui.stack({ width = ctx.width, height = 52 }, {
			ui.row({
				width = "100%",
				height = 51,
				padding = { x = 18, y = 10 },
				gap = 10,
				align = "center",
				style = { background = colors.surface },
			}, {
				ui.text("Glyph", { textStyle = "h2", style = { color = colors.text } }),
				ui.text("/", { style = { color = colors.amber } }),
				ui.text("Accessibility", { textStyle = "h2", style = { color = colors.muted } }),
				ui.box({ flex = 1, height = 1, interactive = false }),
				ui.box({
					width = 7,
					height = 7,
					interactive = false,
					accessibilityHidden = true,
					style = { background = colors.amber, radius = 0 },
				}),
				ui.text("Adapter online", { textStyle = "caption", style = { color = colors.muted } }),
			}),
			ui.box({
				position = "absolute",
				left = 0,
				right = 0,
				bottom = 0,
				height = 1,
				interactive = false,
				accessibilityHidden = true,
				style = { background = colors.rule },
			}),
		})
	end

	local function eventRows(ctx)
		local rows = {}
		local events = ctx.events or {}
		for position = #events, 1, -1 do
			local entry = events[position]
			local kind, message = entry:match("^([^:]+):%s*(.*)$")
			kind = kind or "event"
			message = message or entry
			local latest = position == #events
			rows[#rows + 1] = ui.stack({ width = "100%", minHeight = 34 }, {
				ui.row({
					width = "100%",
					minHeight = 33,
					align = "center",
					padding = { x = 6 },
				}, {
					ui.text(string.format("%02d", #events - position + 1), {
						width = 42,
						textStyle = "code",
						style = { color = latest and colors.amber or colors.muted },
					}),
					ui.text(kind:upper(), {
						width = 88,
						textStyle = "code",
						style = { color = colors.muted },
					}),
					ui.text(message, {
						flex = 1,
						wrap = true,
						style = { color = latest and colors.text or colors.muted },
					}),
				}),
				ui.box({
					position = "absolute",
					left = 0,
					right = 0,
					bottom = 0,
					height = 1,
					interactive = false,
					accessibilityHidden = true,
					style = { background = colors.ruleSoft },
				}),
			})
		end
		return rows
	end

	local function scene(ctx)
		local power = 60 + wave(ctx, 2) * 30
		local events = eventRows(ctx)
		local rail = ui.stack({ width = 232, height = ctx.height - 52 }, {
			ui.column({
				width = "100%",
				height = "100%",
				padding = { left = 18, right = 18, top = 18, bottom = 15 },
				gap = 11,
				style = { background = colors.rail },
			}, {
				sectionLabel("Semantic control"),
				ui.button({
					label = "Launch",
					width = "100%",
					height = 36,
					accessibilityLabel = "Launch mission",
					accessibilityDescription = "Starts the selected mission",
					style = {
						background = colors.amber,
						color = colors.amberText,
						borderColor = colors.amber,
						borderWidth = 1,
						radius = 0,
						hover = { background = { 0.9, 0.59, 0.16, 1 } },
						pressed = { background = { 0.62, 0.36, 0.05, 1 } },
						focused = { borderColor = colors.text, borderWidth = 2 },
					},
				}),
				rule(),
				sectionLabel("Power signal"),
				ui.meter({
					value = power,
					max = 100,
					label = "Power",
					accessibilityValueText = "Power level changing",
					width = "100%",
					height = 19,
					shape = { kind = "rect", radius = 0 },
					style = { color = colors.text, borderColor = colors.rule, borderWidth = 1 },
					trackStyle = { background = colors.field, radius = 0 },
					fillStyle = { background = colors.amber, radius = 0 },
				}),
				ui.text(string.format("%02d / 100", math.floor(power + 0.5)), {
					textStyle = "code",
					style = { color = colors.muted },
				}),
				rule(),
				sectionLabel("Live region"),
				ui.text("Autosave complete", {
					width = "100%",
					wrap = true,
					accessibilityLive = "polite",
					style = { color = colors.text },
				}),
				ui.text("polite announcement", {
					textStyle = "caption",
					style = { color = colors.muted },
				}),
				ui.box({ width = "100%", grow = 1, interactive = false }),
				ui.text("KEYBOARD / GAMEPAD / POINTER", {
					width = "100%",
					wrap = true,
					textStyle = "caption",
					style = { color = colors.muted },
				}),
			}),
			ui.box({
				position = "absolute",
				top = 0,
				right = 0,
				bottom = 0,
				width = 1,
				interactive = false,
				accessibilityHidden = true,
				style = { background = colors.rule },
			}),
		})

		local workfield = ui.column({
			flex = 1,
			height = ctx.height - 52,
			padding = { left = 24, right = 20, top = 18, bottom = 16 },
			gap = 10,
			style = { background = colors.chassis },
		}, {
			ui.row({ width = "100%", align = "center", gap = 10 }, {
				ui.text("Semantic event ledger", { textStyle = "h1", style = { color = colors.text } }),
				ui.box({ flex = 1, height = 1, interactive = false }),
				ui.text(string.format("%02d EVENTS", #(ctx.events or {})), {
					textStyle = "code",
					style = { color = colors.amber },
				}),
			}),
			ui.text("Metadata remains app-owned; Glyph reports focus, activation, live regions, and snapshots.", {
				width = "100%",
				wrap = true,
				textStyle = "caption",
				style = { color = colors.muted },
			}),
			rule(),
			sectionLabel("Adapter events"),
			ui.row({
				width = "100%",
				height = 25,
				align = "center",
				padding = { x = 6 },
				style = { background = colors.surface },
			}, {
				ui.text("SEQ", { width = 42, textStyle = "caption", style = { color = colors.muted } }),
				ui.text("TYPE", { width = 88, textStyle = "caption", style = { color = colors.muted } }),
				ui.text("ANNOUNCEMENT", { flex = 1, textStyle = "caption", style = { color = colors.muted } }),
			}),
			ui.scrollView({
				width = "100%",
				grow = 1,
				gap = 0,
				padding = { right = 4 },
				style = { background = colors.field },
			}, events),
		})

		return ui.stack({ width = ctx.width, height = ctx.height }, {
			ui.box({
				position = "absolute",
				inset = 0,
				interactive = false,
				accessibilityHidden = true,
				style = { background = colors.chassis },
			}),
			serviceStrip(ctx),
			ui.row({
				position = "absolute",
				left = 0,
				top = 52,
				width = ctx.width,
				height = ctx.height - 52,
			}, { rail, workfield }),
		})
	end

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
			return scene(ctx)
		end,
	})
end
