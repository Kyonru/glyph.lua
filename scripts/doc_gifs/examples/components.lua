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
		id = "components",
		title = "Components",
		docs = { "docs/components.md" },
		alt = "Animated GIF showing Glyph text, image, button, input, meter, tabs, and panel components.",
		setup = function(ctx)
			ctx.tab = 1
			ctx.input = "pilot"
			makeProceduralImage(ctx, "components")
		end,
		update = function(ctx)
			ctx.meter = 42 + math.floor(wave(ctx, 2.7) * 48)
		end,
		actions = {
			{
				at = 0.7,
				run = function(ctx)
					ctx.tab = 2
				end,
			},
			{
				at = 1.35,
				run = function(ctx)
					ctx.input = "pilot ready"
				end,
			},
			{
				at = 1.95,
				run = function(ctx)
					ctx.tab = 3
				end,
			},
		},
		component = function(ctx)
			local image = ctx.images and ctx.images.components
			local function tabCard(children)
				return ui.box({
					width = "100%",
					height = 174,
					padding = 12,
					display = "column",
					gap = 8,
					style = {
						background = { 0.03, 0.04, 0.055, 1 },
						borderColor = cloneColor(palette.blue, 0.3),
						borderWidth = 1,
						radius = 8,
					},
				}, children)
			end
			local function chip(label, color, width)
				color = color or palette.teal
				return ui.box({
					width = width or 76,
					height = 22,
					padding = 4,
					display = "column",
					align = "center",
					justify = "center",
					style = {
						background = cloneColor(color, 0.16),
						borderColor = cloneColor(color, 0.62),
						borderWidth = 1,
						radius = 11,
					},
				}, {
					ui.text(label, { textStyle = "caption", style = { color = palette.text } }),
				})
			end
			local function miniMetric(label, value, color)
				return ui.box({
					flex = 1,
					height = 48,
					padding = 7,
					display = "column",
					gap = 2,
					style = {
						background = cloneColor(color or palette.teal, 0.12),
						borderColor = cloneColor(color or palette.teal, 0.38),
						borderWidth = 1,
						radius = 6,
					},
				}, {
					ui.text(label, { textStyle = "caption", style = { color = palette.muted } }),
					ui.text(value, { textStyle = "h2", style = { color = color or palette.text } }),
				})
			end
			local function hudButton(label, active)
				return ui.button({
					label = label,
					width = 74,
					height = 28,
					padding = { x = 8, y = 4 },
					active = active,
					style = {
						background = active and cloneColor(palette.teal, 0.24) or { 1, 1, 1, 0.055 },
						borderColor = active and palette.teal or cloneColor(palette.text, 0.18),
						borderWidth = 1,
						radius = 6,
						color = palette.text,
					},
				})
			end
			local textTab = tabCard({
				ui.row({ width = "100%", gap = 8, align = "center" }, {
					chip("label", palette.teal),
					ui.text(
						"Status copy resolves through text styles.",
						{ flex = 1, wrap = true, style = { color = palette.text } }
					),
				}),
				ui.box({
					width = "100%",
					height = 54,
					padding = 10,
					display = "column",
					gap = 4,
					style = {
						background = cloneColor(palette.teal, 0.14),
						borderColor = cloneColor(palette.teal, 0.42),
						borderWidth = 1,
						radius = 7,
					},
				}, {
					ui.text("MISSION LOG", { textStyle = "caption", style = { color = palette.teal } }),
					ui.text("Compact, readable UI text inside a reusable panel.", { style = { color = palette.text } }),
				}),
			})
			local layoutTab = tabCard({
				ui.row({ width = "100%", height = 38, gap = 8, align = "stretch" }, {
					ui.box({
						flex = 1,
						style = {
							background = cloneColor(palette.teal, 0.22),
							borderColor = palette.teal,
							borderWidth = 1,
							radius = 6,
						},
					}),
					ui.box({
						flex = 1.6,
						style = {
							background = cloneColor(palette.gold, 0.2),
							borderColor = palette.gold,
							borderWidth = 1,
							radius = 6,
						},
					}),
					ui.box({
						flex = 1,
						style = {
							background = cloneColor(palette.coral, 0.2),
							borderColor = palette.coral,
							borderWidth = 1,
							radius = 6,
						},
					}),
				}),
				ui.column({ width = "100%", gap = 6 }, {
					ui.meter({
						value = 78,
						max = 100,
						height = 10,
						fillStyle = { background = palette.teal },
						trackStyle = { background = { 1, 1, 1, 0.08 } },
					}),
					ui.meter({
						value = 52,
						max = 100,
						height = 10,
						fillStyle = { background = palette.gold },
						trackStyle = { background = { 1, 1, 1, 0.08 } },
					}),
					ui.meter({
						value = 34,
						max = 100,
						height = 10,
						fillStyle = { background = palette.coral },
						trackStyle = { background = { 1, 1, 1, 0.08 } },
					}),
				}),
			})
			local hudTab = tabCard({
				ui.row({ width = "100%", height = 84, gap = 10, align = "stretch" }, {
					ui.box({
						width = 82,
						padding = 8,
						display = "column",
						align = "center",
						justify = "center",
						style = {
							background = cloneColor(palette.blue, 0.14),
							borderColor = cloneColor(palette.blue, 0.42),
							borderWidth = 1,
							radius = 8,
						},
					}, {
						image
								and ui.image({
									source = image,
									width = 50,
									height = 50,
									fit = "cover",
									clip = { kind = "circle" },
									interactive = false,
								})
							or ui.box({ width = 50, height = 50, style = { background = palette.blue, radius = 25 } }),
					}),
					ui.column({ flex = 1, gap = 6 }, {
						ui.row({ height = 30, gap = 8, align = "center" }, {
							ui.text("HUD", { width = 62, textStyle = "h2", style = { color = palette.text } }),
							chip("armed", palette.coral, 78),
						}),
						ui.meter({
							value = ctx.meter,
							max = 100,
							height = 12,
							fillStyle = { background = palette.gold },
							trackStyle = { background = { 1, 1, 1, 0.08 } },
						}),
						ui.row({ width = "100%", gap = 8 }, {
							hudButton("Ping", ctx.tab == 3),
							hudButton("Dock", false),
						}),
					}),
				}),
				ui.row({ width = "100%", height = 48, gap = 8 }, {
					miniMetric("signal", "clear", palette.teal),
					miniMetric("fuel", tostring(math.floor(ctx.meter or 0)) .. "%", palette.gold),
					miniMetric("mode", "auto", palette.blue),
				}),
			})
			return stage(
				ctx,
				"Components",
				"The core widget set stays generic and composable.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("primitives", { width = 418, height = 294 }, {
						ui.h2("Mission Console", { style = { color = palette.text } }),
						ui.row({ gap = 12, align = "center" }, {
							image and ui.image({
								source = image,
								width = 78,
								height = 78,
								fit = "cover",
								clip = { kind = "circle" },
								interactive = false,
							}) or ui.box({ width = 78, height = 78 }),
							ui.column({ gap = 7, flex = 1 }, {
								ui.input({ value = ctx.input, width = "100%" }),
								ui.button({ label = "Queue Action", active = ctx.tab == 2 }),
								ui.meter({
									value = ctx.meter,
									max = 100,
									height = 14,
									fillStyle = { background = palette.gold },
								}),
							}),
						}),
					}),
					panel("tabs and panels", { flex = 1, height = 294 }, {
						ui.tabs({
							active = ctx.tab,
							width = "100%",
							tabHeight = 26,
							tabWidth = 74,
							tabPadding = { x = 8, y = 4 },
							gap = 6,
							tabStyle = {
								background = { 1, 1, 1, 0.045 },
								borderColor = cloneColor(palette.text, 0.18),
								borderWidth = 1,
								radius = 6,
								color = palette.muted,
								hover = { background = { 1, 1, 1, 0.075 } },
								active = {
									background = cloneColor(palette.teal, 0.24),
									borderColor = palette.teal,
									color = palette.text,
								},
							},
						}, {
							{ label = "Text", content = textTab },
							{ label = "Layout", content = layoutTab },
							{ label = "HUD", content = hudTab },
						}),
					}),
				})
			)
		end,
	})
end
