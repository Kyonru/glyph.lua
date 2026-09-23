return function(env)
	local ui = env.ui
	local wave = env.wave
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
		return ui.text(label:upper(), { textStyle = "caption", style = { color = colors.muted } })
	end

	local function registerRow(label, value, highlighted)
		return ui.column({ width = "100%", gap = 0 }, {
			ui.row({ width = "100%", minHeight = 31, align = "center", gap = 8 }, {
				ui.text(label:upper(), {
					width = 92,
					textStyle = "caption",
					style = { color = colors.muted },
				}),
				ui.text(value, {
					flex = 1,
					textStyle = "code",
					style = { color = highlighted and colors.amber or colors.text },
				}),
			}),
			ui.box({
				width = "100%",
				height = 1,
				interactive = false,
				accessibilityHidden = true,
				style = { background = colors.ruleSoft },
			}),
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
				ui.text("Performance", { textStyle = "h2", style = { color = colors.muted } }),
				ui.box({ flex = 1, height = 1, interactive = false }),
				ui.box({
					width = 7,
					height = 7,
					interactive = false,
					accessibilityHidden = true,
					style = { background = colors.amber, radius = 0 },
				}),
				ui.text("Bounded work", { textStyle = "caption", style = { color = colors.muted } }),
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

	local function ledgerRow(index)
		local load = (index * 13) % 100
		return ui.column({ width = "100%", gap = 0 }, {
			ui.row({ width = "100%", height = 33, align = "center", gap = 10, padding = { x = 6 } }, {
				ui.text(string.format("%05d", index), {
					width = 72,
					textStyle = "code",
					style = { color = colors.text },
				}),
				ui.meter({
					value = load,
					max = 100,
					flex = 1,
					height = 7,
					shape = { kind = "rect", radius = 0 },
					trackStyle = { background = colors.surface, radius = 0 },
					fillStyle = { background = colors.amber, radius = 0 },
				}),
				ui.text(string.format("%02d%%", load), {
					width = 46,
					textStyle = "code",
					style = { color = colors.muted },
				}),
				ui.text("STATIC / MEMO", {
					width = 112,
					textStyle = "caption",
					style = { color = colors.muted },
				}),
			}),
			ui.box({
				width = "100%",
				height = 1,
				interactive = false,
				accessibilityHidden = true,
				style = { background = colors.ruleSoft },
			}),
		})
	end

	local function scene(ctx)
		local offset = ctx.offset or 1
		local memoHits = 80 + math.floor(wave(ctx, 4.5) * 18)
		local pass = wave(ctx, 7) > 0.5 and "DIRTY" or "CLEAN"
		local rows = {}
		for index = offset, offset + 7 do
			rows[#rows + 1] = ledgerRow(index)
		end

		local rail = ui.stack({ width = 232, height = ctx.height - 52 }, {
			ui.column({
				width = "100%",
				height = "100%",
				padding = { left = 18, right = 18, top = 18, bottom = 15 },
				gap = 10,
				style = { background = colors.rail },
			}, {
				sectionLabel("Visible window"),
				ui.text(string.format("%05d—%05d", offset, offset + 7), {
					font = "monoDisplay",
					lineHeight = 36,
					style = { color = colors.text },
				}),
				ui.text("8 mounted / 10,000 source rows", {
					width = "100%",
					wrap = true,
					textStyle = "caption",
					style = { color = colors.muted },
				}),
				rule(),
				sectionLabel("Work register"),
				registerRow("FPS", tostring(ctx.fps or 18), false),
				registerRow("Mounted", "8 / 10K", false),
				registerRow("Memo hits", tostring(memoHits) .. "%", false),
				registerRow("Layout", pass, pass == "DIRTY"),
				ui.box({ width = "100%", grow = 1, interactive = false }),
				ui.text("WINDOWED / STATIC / MEMO", {
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
				ui.text("Runtime ledger", { textStyle = "h1", style = { color = colors.text } }),
				ui.box({ flex = 1, height = 1, interactive = false }),
				ui.text("8 / 10K MOUNTED", { textStyle = "code", style = { color = colors.amber } }),
			}),
			ui.text("Memoized rows and a moving visible window keep mounted work bounded.", {
				width = "100%",
				wrap = true,
				textStyle = "caption",
				style = { color = colors.muted },
			}),
			rule(),
			sectionLabel("Visible rows"),
			ui.row({
				width = "100%",
				height = 25,
				align = "center",
				gap = 10,
				padding = { x = 6 },
				style = { background = colors.surface },
			}, {
				ui.text("SEQ", { width = 72, textStyle = "caption", style = { color = colors.muted } }),
				ui.text("MOUNTED LOAD", { flex = 1, textStyle = "caption", style = { color = colors.muted } }),
				ui.text("UTIL", { width = 46, textStyle = "caption", style = { color = colors.muted } }),
				ui.text("WORK", { width = 112, textStyle = "caption", style = { color = colors.muted } }),
			}),
			ui.column({ width = "100%", gap = 0, style = { background = colors.field } }, rows),
			ui.box({ width = "100%", grow = 1, interactive = false }),
			ui.text("Large datasets stay app-owned; Glyph mounts the bounded window shown above.", {
				width = "100%",
				wrap = true,
				textStyle = "caption",
				style = { color = colors.muted },
			}),
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
			return scene(ctx)
		end,
	})
end
