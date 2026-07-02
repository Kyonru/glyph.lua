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
		id = "custom-draw",
		title = "Custom Draw And Helpers",
		docs = { "docs/custom-draw.md" },
		alt = "Animated GIF showing Glyph custom draw helpers, vector path reveal, morphing, clipping, and masks.",
		update = function(ctx)
			ctx.phase = wave(ctx, 3)
			ctx.pathProgress = math.min(1, ((ctx.time or 0) % 2.4) / 1.7)
			ctx.pathMorph = wave(ctx, 2.6, -0.8)
		end,
		component = function(ctx)
			local arcValue = 40 + (ctx.phase or 0) * 55
			local pathProgress = ctx.pathProgress or 0
			local pathMorph = ctx.pathMorph or 0
			-- A labeled strip of the shape-primitive helpers (ctx:triangle, arc,
			-- roundedRect, dashed/rounded lines) drawn in evenly spaced cells.
			local primitivesPanel = panel("shape primitives", { width = "100%", height = 124 }, {
				ui.box({
					width = "100%",
					height = 84,
					interactive = false,
					accessibilityHidden = true,
					draw = function(_, x, y, width, height, _, _, drawCtx)
						local cells = {
							{ label = "triangle", color = palette.teal },
							{ label = "equilateral", color = palette.blue },
							{ label = "arc", color = palette.coral },
							{ label = "roundedRect", color = palette.gold },
							{ label = "dashedLine", color = palette.violet },
							{ label = "dashedRect", color = palette.teal },
							{ label = "roundedLine", color = palette.gold },
						}
						local count = #cells
						local cellWidth = width / count
						local glyphY = y + 30
						for index, cell in ipairs(cells) do
							local cellX = x + (index - 1) * cellWidth
							local cx = cellX + cellWidth / 2
							drawCtx:color(cloneColor(cell.color, 0.95))
							if cell.label == "triangle" then
								drawCtx:triangle("fill", cx, glyphY, 30, 34)
							elseif cell.label == "equilateral" then
								drawCtx:triangleEquilateral("line", cx, glyphY, 34)
							elseif cell.label == "arc" then
								drawCtx:arc("fill", cx, glyphY, 20, 0, math.pi * 2 * (ctx.phase or 0))
								drawCtx:color(cloneColor(cell.color, 0.3))
								drawCtx:arc("line", cx, glyphY, 20, 0, math.pi * 2)
							elseif cell.label == "roundedRect" then
								drawCtx:roundedRect("line", cx, glyphY, 46, 32, 8)
							elseif cell.label == "dashedLine" then
								drawCtx:dashedLine(cx - 26, glyphY, cx + 26, glyphY, 6, 4)
							elseif cell.label == "dashedRect" then
								drawCtx:dashedRectangle(cx, glyphY, 46, 32, 5, 4)
							elseif cell.label == "roundedLine" then
								drawCtx:roundedLine(cx - 26, glyphY + 8, cx + 26, glyphY - 8, 7)
							end
							drawCtx:color(palette.muted)
							drawCtx:printf(cell.label, cellX, y + 60, cellWidth, "center")
						end
					end,
				}),
			})
			return stage(
				ctx,
				"Custom Draw",
				"Game-specific visuals stay in app draw functions.",
				ui.column({ width = "100%", gap = 14 }, {
					ui.row({ gap = 14, width = "100%", align = "stretch" }, {
						panel("draw context", { flex = 1, height = 292 }, {
							ui.box({
								width = "100%",
								height = 205,
								draw = function(_, x, y, width, height, _, _, drawCtx)
									drawCtx:color({ 0.03, 0.04, 0.055, 1 })
									drawCtx:rect("fill", x, y, width, height, 8)

									drawCtx:color({ 1, 1, 1, 0.035 })
									for ix = 28, width - 28, 32 do
										drawCtx:line(x + ix, y + 18, x + ix, y + height - 18)
									end

									local hull = { x = x + 32, y = y + 34, width = width - 64, height = 82 }
									local hullPoints =
										ui.polygonBox(hull.x, hull.y, hull.width, hull.height, { skew = 24 })
									local hullShape = function()
										return function(mode)
											drawCtx:polygon(mode, hullPoints)
										end
									end

									drawCtx:color(cloneColor(palette.teal, 0.26))
									drawCtx:polygon("fill", hullPoints)
									drawCtx:clip(hullShape, function()
										local scanX = hull.x - 70 + (ctx.phase or 0) * (hull.width + 140)
										drawCtx:color(cloneColor(palette.blue, 0.3))
										drawCtx:rect("fill", scanX, hull.y - 10, 86, hull.height + 20)
										drawCtx:color(cloneColor(palette.coral, 0.34))
										drawCtx:shape("fill", { kind = "circle", segments = 40 }, {
											x = hull.x + hull.width - 100,
											y = hull.y + 4,
											width = 92,
											height = 92,
										})
										drawCtx:color({ 1, 1, 1, 0.07 })
										for stripe = 0, 8 do
											drawCtx:line(
												hull.x - 20,
												hull.y + stripe * 12,
												hull.x + hull.width + 20,
												hull.y + stripe * 12
											)
										end
									end)
									drawCtx:color(cloneColor(palette.text, 0.78))
									drawCtx:polygon("line", hullPoints)

									local traceBounds = { x = x + 36, y = y + 134, width = width - 72, height = 60 }
									local trace = "M0 44 C38 0 86 76 132 32 C174 4 210 54 252 18"
									drawCtx:path("line", trace, traceBounds, {
										stroke = cloneColor(palette.gold, 0.16),
										strokeWidth = 6,
										fit = "stretch",
										samples = 42,
									})
									drawCtx:path("line", trace, traceBounds, {
										stroke = palette.gold,
										strokeWidth = 4,
										progress = pathProgress,
										fit = "stretch",
										samples = 42,
									})
									local revealX = traceBounds.x + traceBounds.width * pathProgress
									drawCtx:color(palette.gold)
									drawCtx:shape("fill", { kind = "circle", segments = 16 }, {
										x = revealX - 5,
										y = traceBounds.y + 28 + math.sin((ctx.time or 0) * 5.2) * 16 - 5,
										width = 10,
										height = 10,
									})
								end,
							}),
						}),
						panel("helper primitives", { width = 320, height = 292 }, {
							ui.box({
								width = "100%",
								height = 205,
								draw = function(_, x, y, width, height, _, _, drawCtx)
									drawCtx:color({ 0.03, 0.04, 0.055, 1 })
									drawCtx:rect("fill", x, y, width, height, 8)
									drawCtx:color({ 1, 1, 1, 0.04 })
									drawCtx:rect("line", x + 12, y + 12, width - 24, height - 24, 6)

									local arcBounds = { x = x + 28, y = y + 26, width = 132, height = 132 }
									drawCtx:meter(arcBounds, {
										kind = "arc",
										value = arcValue,
										max = 100,
										thickness = 13,
										segments = 56,
										trackStyle = { background = { 1, 1, 1, 0.11 } },
										fillStyle = { background = palette.coral },
									})
									drawCtx:color(palette.text)
									drawCtx:printf(
										tostring(math.floor(arcValue + 0.5)) .. "%",
										arcBounds.x,
										arcBounds.y + 56,
										arcBounds.width,
										"center"
									)

									local blobBounds = { x = x + 194, y = y + 42, width = 78, height = 66 }
									local blob = drawCtx:blob(blobBounds, {
										points = 10,
										variance = 0.18,
										phase = (ctx.time or 0) * 1.8,
										seed = 23,
									})
									drawCtx:color(cloneColor(palette.violet, 0.34))
									drawCtx:polygon("fill", blob)
									drawCtx:color(palette.violet)
									drawCtx:polygon("line", blob)

									local morphBounds = { x = x + 24, y = y + 136, width = width - 48, height = 48 }
									drawCtx:color({ 1, 1, 1, 0.045 })
									drawCtx:rect(
										"fill",
										morphBounds.x,
										morphBounds.y,
										morphBounds.width,
										morphBounds.height,
										6
									)
									drawCtx:path("both", "M12 26 L44 6 L214 6 L246 26 L214 46 L44 46 Z", morphBounds, {
										morphTo = "M126 4 L246 18 L202 48 L126 38 L50 48 L6 18 Z",
										morph = pathMorph,
										morphMode = "resample",
										fill = cloneColor(palette.teal, 0.18),
										stroke = palette.teal,
										strokeWidth = 3,
										fit = "stretch",
										samples = 48,
									})
									drawCtx:color(palette.text)
									drawCtx:printf(
										"morph",
										morphBounds.x,
										morphBounds.y + 15,
										morphBounds.width,
										"center"
									)
								end,
							}),
							ui.row({ width = "100%", gap = 8 }, {
								metric("path", tostring(math.floor(pathProgress * 100 + 0.5)) .. "%", palette.gold),
								metric("morph", tostring(math.floor(pathMorph * 100 + 0.5)) .. "%", palette.teal),
							}),
						}),
					}),
					primitivesPanel,
				})
			)
		end,
	})
end
