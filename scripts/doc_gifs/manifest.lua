local ui = require("glyph")

local Manifest = {}

local palette = {
	bg = { 0.035, 0.043, 0.058, 1 },
	panel = { 0.075, 0.092, 0.118, 0.96 },
	panel2 = { 0.105, 0.075, 0.12, 0.95 },
	border = { 1, 1, 1, 0.16 },
	text = { 0.93, 0.96, 0.98, 1 },
	muted = { 0.58, 0.66, 0.73, 1 },
	teal = { 0.1, 0.78, 0.68, 1 },
	blue = { 0.22, 0.48, 0.92, 1 },
	gold = { 0.94, 0.66, 0.18, 1 },
	coral = { 0.92, 0.24, 0.3, 1 },
	violet = { 0.66, 0.38, 0.96, 1 },
}

local function cloneColor(color, alpha)
	return { color[1], color[2], color[3], alpha ~= nil and alpha or color[4] or 1 }
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function wave(ctx, speed, phase)
	return (math.sin((ctx.time or 0) * (speed or 1) + (phase or 0)) + 1) / 2
end

local function remember(ctx, value, limit)
	ctx.events = ctx.events or {}
	ctx.events[#ctx.events + 1] = value
	while #ctx.events > (limit or 5) do
		table.remove(ctx.events, 1)
	end
end

local function panelProps(extra)
	local props = {
		padding = 14,
		gap = 8,
		style = {
			background = palette.panel,
			borderColor = palette.border,
			borderWidth = 1,
			radius = 8,
		},
	}

	for key, value in pairs(extra or {}) do
		props[key] = value
	end

	return props
end

local function panel(title, props, children)
	props = panelProps(props)
	props.title = title
	props.titleTextStyle = "caption"
	props.titleColor = palette.muted
	return ui.panel(props, children)
end

local function pill(label, color)
	color = color or palette.teal
	return ui.box({
		width = 118,
		height = 28,
		padding = 6,
		display = "column",
		align = "center",
		justify = "center",
		style = {
			background = cloneColor(color, 0.18),
			borderColor = cloneColor(color, 0.72),
			borderWidth = 1,
			radius = 14,
		},
	}, {
		ui.text(label, { textStyle = "caption", style = { color = palette.text } }),
	})
end

local function metric(label, value, color)
	return ui.column({ gap = 5, width = 148 }, {
		ui.text(label, { textStyle = "caption", style = { color = palette.muted } }),
		ui.text(value, { textStyle = "h2", style = { color = color or palette.text } }),
	})
end

local function header(title, subtitle)
	return ui.row({ width = "100%", height = 64, align = "center", gap = 16 }, {
		ui.column({ gap = 4, flex = 1 }, {
			ui.h1(title, { style = { color = palette.text } }),
			ui.text(subtitle, { style = { color = palette.muted } }),
		}),
		pill("live UI", palette.teal),
	})
end

local function background(ctx)
	return ui.box({
		position = "absolute",
		inset = 0,
		interactive = false,
		accessibilityHidden = true,
		draw = function(_, x, y, width, height, loveModule)
			local g = loveModule.graphics
			g.setColor(palette.bg)
			g.rectangle("fill", x, y, width, height)

			local drift = wave(ctx, 1.1) * 28
			g.setColor(1, 1, 1, 0.035)
			for ix = -120, width + 120, 36 do
				g.line(x + ix + drift, y, x + ix + 116 + drift, y + height)
			end
			g.setColor(1, 1, 1, 0.025)
			for iy = 36, height, 46 do
				g.line(x, y + iy, x + width, y + iy)
			end

			g.setColor(palette.teal[1], palette.teal[2], palette.teal[3], 0.08)
			g.polygon("fill", x, y + 54, x + 172, y + 30, x + 260, y + height, x, y + height)
			g.setColor(palette.coral[1], palette.coral[2], palette.coral[3], 0.07)
			g.polygon(
				"fill",
				x + width * 0.68,
				y + height,
				x + width,
				y + height * 0.54,
				x + width,
				y + height,
				x + width * 0.82,
				y + height
			)
			g.setColor(palette.blue[1], palette.blue[2], palette.blue[3], 0.055)
			g.rectangle("fill", x, y + height - 74, width, 24)
		end,
	})
end

local function stage(ctx, title, subtitle, children)
	return ui.stack({ width = ctx.width, height = ctx.height }, {
		background(ctx),
		ui.column({
			position = "absolute",
			left = 36,
			top = 26,
			width = ctx.width - 72,
			gap = 14,
		}, {
			header(title, subtitle),
			children,
		}),
	})
end

local function codeBlock(lines)
	local nodes = {}
	for _, line in ipairs(lines) do
		nodes[#nodes + 1] = ui.text(line, {
			textStyle = "caption",
			style = { color = line:find("^%s") and palette.muted or palette.teal },
		})
	end

	return panel("declarative Lua", { width = 384, height = 260 }, nodes)
end

local function eventList(ctx, title)
	local rows = {}
	for index, event in ipairs(ctx.events or {}) do
		rows[#rows + 1] = ui.row({ height = 28, gap = 8, align = "center" }, {
			ui.box({
				width = 8,
				height = 8,
				style = {
					background = ({ palette.teal, palette.gold, palette.coral, palette.blue, palette.violet })[(index - 1) % 5 + 1],
					radius = 4,
				},
			}),
			ui.text(event, { style = { color = palette.text } }),
		})
	end

	while #rows < 5 do
		rows[#rows + 1] = ui.text("waiting for scripted event", { style = { color = cloneColor(palette.muted, 0.5) } })
	end

	return panel(title or "event stream", { width = 336, height = 212 }, rows)
end

local function makeProceduralImage(ctx, id)
	if ctx.images and ctx.images[id] then
		return ctx.images[id]
	end

	local loveModule = ctx.love or _G.love
	if not loveModule or not loveModule.image or not loveModule.graphics then
		return nil
	end

	ctx.images = ctx.images or {}
	local imageData = loveModule.image.newImageData(64, 64)

	for y = 0, 63 do
		for x = 0, 63 do
			local dx = x - 31.5
			local dy = y - 31.5
			local radius = math.sqrt(dx * dx + dy * dy) / 45
			local stripe = ((math.floor((x + y) / 8) % 2) == 0) and 0.12 or 0
			imageData:setPixel(x, y, 0.12 + radius * 0.2, 0.58 + stripe, 0.74 + radius * 0.18, 1)
		end
	end

	ctx.images[id] = loveModule.graphics.newImage(imageData)
	return ctx.images[id]
end

local function target(opts)
	opts.duration = opts.duration or 2.6
	opts.fps = opts.fps or 18
	return opts
end

local inventoryExample = nil

local function loadInventoryExample()
	if not inventoryExample then
		inventoryExample = require("examples.inventory.example")
	end
	return inventoryExample
end

local function runtimeBoundsForKey(key)
	local runtime = ui.runtime
	local root = runtime and runtime.root or nil
	if not root then
		return nil
	end

	local found = nil
	local function walk(node, parentX, parentY)
		local layout = node.layout or {}
		local x = parentX + (layout.x or 0)
		local y = parentY + (layout.y or 0)
		local props = node.props or {}

		if props.key == key then
			found = {
				x = x,
				y = y,
				width = layout.width or 0,
				height = layout.height or 0,
			}
			return true
		end

		local childX = x
		local childY = y
		if node.type == "scrollView" then
			childY = y - ((runtime.scrollOffsets and runtime.scrollOffsets[node.path]) or 0)
		end

		for _, child in ipairs(node.children or {}) do
			if walk(child, childX, childY) then
				return true
			end
		end
		return false
	end

	walk(root, 0, 0)
	return found
end

local function moveCapturePointer(ctx, x, y)
	local previousX = ctx.pointerX or x
	local previousY = ctx.pointerY or y
	ui.mousemoved(x, y, x - previousX, y - previousY)
	ctx.pointerX = x
	ctx.pointerY = y
end

local function centerOf(bounds)
	return bounds.x + bounds.width / 2, bounds.y + bounds.height / 2
end

local function driveInventoryDrag(ctx, t)
	local source = runtimeBoundsForKey("satchel-slot-3")
	local targetSlot = runtimeBoundsForKey("satchel-slot-7")
	if not source or not targetSlot then
		return
	end

	local startX, startY = centerOf(source)
	local targetX, targetY = centerOf(targetSlot)
	local startTime = 0.5
	local releaseTime = 2.05

	if t < startTime then
		moveCapturePointer(ctx, startX, startY)
		return
	end

	if not ctx.inventoryDragStarted then
		moveCapturePointer(ctx, startX, startY)
		ui.mousepressed(startX, startY, 1)
		ctx.inventoryDragStarted = true
	end

	if not ctx.inventoryDragReleased then
		local progress = math.min(1, math.max(0, (t - startTime) / (releaseTime - startTime)))
		local eased = progress * progress * (3 - 2 * progress)
		local x = lerp(startX, targetX, eased)
		local y = lerp(startY, targetY, eased) - math.sin(progress * math.pi) * 42
		moveCapturePointer(ctx, x, y)

		if t >= releaseTime then
			moveCapturePointer(ctx, targetX, targetY)
			ui.mousereleased(targetX, targetY, 1)
			ctx.inventoryDragReleased = true
		end
	end
end

local targets = {
	target({
		id = "inventory-drag-drop",
		title = "Inventory Drag And Drop",
		docs = { "README.md" },
		gallery = false,
		width = 960,
		height = 540,
		duration = 3.1,
		alt = "Animated GIF showing the Glyph inventory example with potion drag and drop.",
		setup = function(ctx)
			local example = loadInventoryExample()
			example.setup()
			ctx.pointerX = nil
			ctx.pointerY = nil
			ctx.inventoryDragStarted = false
			ctx.inventoryDragReleased = false
		end,
		update = function(ctx, t, dt)
			local example = loadInventoryExample()
			if type(example.update) == "function" then
				example.update(dt)
			end
			driveInventoryDrag(ctx, t)
		end,
		component = function()
			return loadInventoryExample().component("docs-gif")
		end,
	}),

	target({
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
	}),

	target({
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
	}),

	target({
		id = "layout",
		title = "Layout",
		docs = { "docs/layout.md" },
		alt = "Animated GIF showing Glyph rows, columns, responsive grids, stack layering, and absolute positioning.",
		update = function(ctx)
			ctx.slide = wave(ctx, 2.2)
			ctx.layoutWidth = math.floor(286 + wave(ctx, 1.55, 0.45) * 110)
		end,
		component = function(ctx)
			local slide = ctx.slide or 0
			local demoWidth = ctx.layoutWidth or 340
			local responsivePlan = ui.columns(demoWidth - 20, { min = 64, maxCount = 5, gap = 5 })
			local gridColors = { palette.teal, palette.gold, palette.coral, palette.blue, palette.violet, palette.teal }
			local gridCells = {}
			for index = 1, 20 do
				local colorValue = gridColors[((index - 1) % #gridColors) + 1]
				local active = index == 7 or index == 14 or index == 19
				gridCells[#gridCells + 1] = ui.box({
					style = {
						background = cloneColor(
							colorValue,
							active and (0.3 + wave(ctx, 5 + index * 0.1) * 0.18) or 0.18
						),
						borderColor = colorValue,
						borderWidth = active and 2 or 1,
						radius = 5,
					},
				})
			end

			return stage(
				ctx,
				"Layout",
				"Responsive flow, grid, and absolute overlays share one tree.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("responsive flow and grid", { width = 430 }, {
						ui.row({ width = "100%", gap = 8 }, {
							metric("container", tostring(demoWidth) .. "px", palette.teal),
							metric("columns", tostring(responsivePlan.count), palette.gold),
						}),
						ui.column({ width = "100%", align = "center" }, {
							ui.column({
								width = demoWidth,
								padding = 10,
								gap = 8,
								style = {
									background = { 0.03, 0.04, 0.055, 1 },
									borderColor = cloneColor(palette.blue, 0.46),
									borderWidth = 1,
									radius = 8,
								},
							}, {
								ui.row({ width = "100%", height = 44, gap = 6, align = "stretch" }, {
									ui.box({
										flex = 1,
										padding = 6,
										display = "column",
										justify = "center",
										style = {
											background = cloneColor(palette.teal, 0.18),
											borderColor = palette.teal,
											borderWidth = 1,
											radius = 6,
										},
									}, {
										ui.text("nav", { textStyle = "caption", style = { color = palette.text } }),
									}),
									ui.box({
										flex = 1.55,
										padding = 6,
										display = "column",
										justify = "center",
										style = {
											background = cloneColor(palette.gold, 0.16),
											borderColor = palette.gold,
											borderWidth = 1,
											radius = 6,
										},
									}, {
										ui.text("content", { textStyle = "caption", style = { color = palette.text } }),
									}),
									ui.box({
										flex = 1,
										padding = 6,
										display = "column",
										justify = "center",
										style = {
											background = cloneColor(palette.coral, 0.18),
											borderColor = palette.coral,
											borderWidth = 1,
											radius = 6,
										},
									}, {
										ui.text("tools", { textStyle = "caption", style = { color = palette.text } }),
									}),
								}),
								ui.grid({
									width = "100%",
									minCellWidth = 64,
									maxColumns = 5,
									cellHeight = 18,
									gap = 5,
								}, gridCells),
							}),
						}),
						ui.row({ width = "100%", height = 26, gap = 8, align = "center" }, {
							ui.text(
								"percent",
								{ width = 70, textStyle = "caption", style = { color = palette.muted } }
							),
							ui.box({
								width = "72%",
								height = 20,
								style = {
									background = cloneColor(palette.violet, 0.2),
									borderColor = palette.violet,
									borderWidth = 1,
									radius = 6,
								},
							}),
						}),
					}),
					panel("stack and absolute", { flex = 1, height = 292 }, {
						ui.stack({ width = "100%", height = 214 }, {
							ui.box({
								position = "absolute",
								inset = 0,
								interactive = false,
								style = {
									background = { 0.03, 0.04, 0.055, 1 },
									borderColor = palette.border,
									borderWidth = 1,
									radius = 8,
								},
							}),
							ui.box({
								position = "absolute",
								left = tostring(math.floor(8 + slide * 26)) .. "%",
								top = 46,
								width = "38%",
								height = 78,
								zScope = "root",
								zIndex = 8,
								style = {
									background = cloneColor(palette.teal, 0.22),
									borderColor = palette.teal,
									borderWidth = 2,
									radius = 8,
								},
							}, {
								ui.text(
									"root absolute",
									{ position = "absolute", left = 16, top = 26, style = { color = palette.text } }
								),
							}),
							ui.box({
								position = "absolute",
								right = "6%",
								bottom = "10%",
								width = "42%",
								height = 78,
								zIndex = 3,
								style = {
									background = cloneColor(palette.coral, 0.24),
									borderColor = palette.coral,
									borderWidth = 2,
									radius = 8,
								},
							}, {
								ui.text(
									"percent anchored",
									{ position = "absolute", left = 18, top = 26, style = { color = palette.text } }
								),
							}),
						}),
					}),
				})
			)
		end,
	}),

	target({
		id = "styling",
		title = "Styling And Themes",
		docs = { "docs/styling.md" },
		alt = "Animated GIF showing Glyph theme colors, variants, and state styles.",
		setup = function(ctx)
			ctx.mode = 1
		end,
		update = function(ctx)
			ctx.glow = wave(ctx, 4.8)
		end,
		actions = {
			{
				at = 0.7,
				run = function(ctx)
					ctx.mode = 2
				end,
			},
			{
				at = 1.4,
				run = function(ctx)
					ctx.mode = 3
				end,
			},
			{
				at = 2.1,
				run = function(ctx)
					ctx.mode = 1
				end,
			},
		},
		component = function(ctx)
			local accents = { palette.teal, palette.gold, palette.coral }
			local accent = accents[ctx.mode or 1]
			return stage(
				ctx,
				"Styling",
				"Theme tokens, variants, and states resolve into draw styles.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("theme tokens", { width = 336, height = 286 }, {
						ui.row({ gap = 10 }, {
							ui.box({ width = 56, height = 56, style = { background = palette.teal, radius = 8 } }),
							ui.box({ width = 56, height = 56, style = { background = palette.gold, radius = 8 } }),
							ui.box({ width = 56, height = 56, style = { background = palette.coral, radius = 8 } }),
							ui.box({ width = 56, height = 56, style = { background = palette.violet, radius = 8 } }),
						}),
						ui.meter({
							value = 35 + ctx.glow * 60,
							max = 100,
							height = 16,
							fillStyle = { background = accent },
						}),
						ui.text(
							"Active accent follows scripted variant changes.",
							{ wrap = true, width = "100%", style = { color = palette.muted } }
						),
					}),
					panel("state styles", { flex = 1, height = 286 }, {
						ui.row({ gap = 10 }, {
							ui.button({
								label = "Default",
								width = 132,
								style = { borderWidth = 1, radius = 7 },
							}),
							ui.button({
								label = "Active",
								width = 132,
								active = true,
								style = {
									background = cloneColor(accent, 0.24),
									borderColor = accent,
									borderWidth = 2,
									radius = 7,
								},
							}),
							ui.button({
								label = "Pressed",
								width = 132,
								active = ctx.glow > 0.48,
								style = {
									background = ctx.glow > 0.48 and cloneColor(palette.coral, 0.32)
										or cloneColor(palette.blue, 0.2),
									borderColor = ctx.glow > 0.48 and palette.coral or palette.border,
									borderWidth = 2,
									radius = 7,
									transition = { background = 0.16 },
								},
							}),
						}),
						ui.box({
							height = 112,
							width = "100%",
							style = {
								background = cloneColor(accent, 0.14 + ctx.glow * 0.12),
								borderColor = cloneColor(accent, 0.62),
								borderWidth = 1,
								radius = 8,
							},
						}, {
							ui.text("style.transition blends visual state without changing layout", {
								position = "absolute",
								left = 18,
								top = 40,
								style = { color = palette.text },
							}),
						}),
					}),
				})
			)
		end,
	}),

	target({
		id = "runtime",
		title = "Runtime, Hooks, And Events",
		docs = { "docs/runtime.md" },
		alt = "Animated GIF showing Glyph runtime updates, input events, focus, and render callbacks.",
		setup = function(ctx)
			ctx.events = { "ui.render(App)", "beforeUpdate" }
			ctx.focus = 1
		end,
		actions = {
			{
				at = 0.45,
				run = function(ctx)
					ctx.focus = 2
					remember(ctx, "mousepressed: Run", 5)
				end,
			},
			{
				at = 0.95,
				run = function(ctx)
					remember(ctx, "keypressed: return", 5)
				end,
			},
			{
				at = 1.45,
				run = function(ctx)
					ctx.focus = 3
					remember(ctx, "focusChanged: Filter", 5)
				end,
			},
			{
				at = 2.0,
				run = function(ctx)
					remember(ctx, "afterRender", 5)
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Runtime",
				"One runtime owns hooks, event routing, and draw traversal.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("interactive tree", { flex = 1, height = 294 }, {
						ui.row({ gap = 10 }, {
							ui.button({ label = "Inspect", active = ctx.focus == 1, width = 130 }),
							ui.button({ label = "Run", active = ctx.focus == 2, width = 130 }),
							ui.input({ value = "Filter", width = 190, active = ctx.focus == 3 }),
						}),
						ui.row({ gap = 14, width = "100%", align = "stretch" }, {
							metric("hover", ctx.focus == 1 and "node.1" or "none", palette.teal),
							metric("focus", "node." .. tostring(ctx.focus), palette.gold),
							metric("dirty", wave(ctx, 6) > 0.45 and "true" or "false", palette.coral),
						}),
						ui.meter({
							value = 40 + wave(ctx, 3.6) * 55,
							max = 100,
							height = 14,
							fillStyle = { background = palette.blue },
						}),
					}),
					eventList(ctx, "runtime callbacks"),
				})
			)
		end,
	}),

	target({
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
	}),

	target({
		id = "i18n",
		title = "I18n",
		docs = { "docs/i18n.md" },
		alt = "Animated GIF showing Glyph localized text, labels, placeholders, and cache-aware values.",
		setup = function(ctx)
			ctx.locale = "en"
			local copy = {
				en = { title = "Ready", action = "Launch", status = "Charge %d%%", input = "Pilot name" },
				es = { title = "Listo", action = "Lanzar", status = "Carga %d%%", input = "Nombre" },
			}
			ui.i18n.configure({
				locale = ctx.locale,
				translate = function(key, params)
					local value = copy[ctx.locale] and copy[ctx.locale][key]
					if key == "status" and value then
						return string.format(value, params and params.value or 0)
					end
					return value
				end,
			})
		end,
		update = function(ctx)
			ctx.charge = math.floor(45 + wave(ctx, 2.5) * 50)
		end,
		actions = {
			{
				at = 0.8,
				run = function(ctx)
					ctx.locale = "es"
					ui.i18n.setLocale("es")
				end,
			},
			{
				at = 1.65,
				run = function(ctx)
					ctx.locale = "en"
					ui.i18n.setLocale("en")
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"I18n",
				"Glyph resolves keys while apps own locale policy.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("keyed props", { flex = 1, height = 280 }, {
						ui.h2(ui.t("title"), { style = { color = palette.gold } }),
						ui.input({ placeholderKey = "input", value = "", width = "100%" }),
						ui.button({ labelKey = "action", width = 190, active = ctx.locale == "es" }),
						ui.meter({
							value = ctx.charge,
							max = 100,
							labelKey = "status",
							labelParams = { value = ctx.charge },
							labelCacheKey = "charge:" .. tostring(ctx.charge),
							height = 18,
							fillStyle = { background = palette.teal },
						}),
					}),
					panel("locale state", { width = 320, height = 280 }, {
						metric("locale", ctx.locale, palette.teal),
						metric("version", tostring(ui.i18n.version()), palette.gold),
						ui.text("Parameterized translations refresh unless a cache key pins the value.", {
							wrap = true,
							width = "100%",
							style = { color = palette.muted },
						}),
					}),
				})
			)
		end,
	}),

	target({
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
	}),

	target({
		id = "responsive",
		title = "Responsive Helpers",
		docs = { "docs/responsive.md" },
		alt = "Animated GIF showing Glyph responsive breakpoints, columns, and virtual viewport mapping.",
		setup = function(ctx)
			ctx.simWidth = 680
		end,
		update = function(ctx)
			ctx.simWidth = math.floor(620 + wave(ctx, 1.8) * 320)
		end,
		component = function(ctx)
			local plan = ui.columns(ctx.simWidth, { min = 210, maxCount = 3, gap = 10 })
			local breakpoint = ctx.simWidth >= 860 and "lg" or ctx.simWidth >= 720 and "md" or "sm"
			local cards = {}
			local labels = { "systems", "party", "map" }
			local colors = { palette.teal, palette.gold, palette.coral }
			for index = 1, plan.count do
				cards[index] = ui.box({
					width = plan.width,
					height = 104,
					style = {
						background = cloneColor(colors[index], 0.2),
						borderColor = colors[index],
						borderWidth = 1,
						radius = 8,
					},
					draw = function(_, x, y, width, height, loveModule)
						local g = loveModule.graphics
						g.setColor(colors[index][1], colors[index][2], colors[index][3], 0.16)
						for stripe = 0, 4 do
							g.rectangle("fill", x + 16 + stripe * 18, y + height - 24, 10, 6, 3, 3)
						end
						g.setColor(1, 1, 1, 0.08)
						g.rectangle("line", x + 10, y + 10, width - 20, height - 20, 6, 6)
					end,
				}, {
					ui.text(labels[index], {
						position = "absolute",
						left = 18,
						top = 22,
						textStyle = "h2",
						style = { color = palette.text },
					}),
					ui.text("column " .. tostring(index), {
						position = "absolute",
						left = 18,
						top = 62,
						textStyle = "caption",
						style = { color = cloneColor(palette.text, 0.72) },
					}),
				})
			end

			return stage(
				ctx,
				"Responsive",
				"Breakpoints and viewport adapters keep game UI predictable.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("adaptive command deck", { flex = 1, height = 308 }, {
						ui.row({ width = "100%", gap = 12, align = "center" }, {
							metric("container", tostring(ctx.simWidth) .. "px", palette.teal),
							metric("breakpoint", breakpoint, palette.gold),
							metric("columns", tostring(plan.count), palette.coral),
						}),
						ui.box({
							width = "100%",
							height = 148,
							padding = 12,
							display = "column",
							style = {
								background = { 0.025, 0.034, 0.046, 1 },
								borderColor = cloneColor(palette.blue, 0.42),
								borderWidth = 1,
								radius = 8,
							},
						}, {
							ui.row({ gap = plan.gap, width = "100%" }, cards),
						}),
						ui.meter({
							value = ctx.simWidth - 600,
							min = 0,
							max = 360,
							height = 14,
							fillStyle = { background = palette.blue },
							trackStyle = { background = { 1, 1, 1, 0.08 } },
						}),
					}),
					panel("virtual viewport", { width = 318, height = 308 }, {
						ui.row({ gap = 10, align = "center" }, {
							pill("960x540", palette.blue),
							ui.text("screen", { style = { color = palette.muted } }),
						}),
						ui.box({
							width = 270,
							height = 164,
							style = {
								background = cloneColor(palette.blue, 0.15),
								borderColor = palette.blue,
								borderWidth = 1,
								radius = 8,
							},
							draw = function(_, x, y, width, height, loveModule)
								local g = loveModule.graphics
								g.setColor(1, 1, 1, 0.055)
								for gx = 24, width - 24, 28 do
									g.line(x + gx, y + 16, x + gx, y + height - 16)
								end
								for gy = 24, height - 24, 28 do
									g.line(x + 16, y + gy, x + width - 16, y + gy)
								end
								g.setColor(palette.teal[1], palette.teal[2], palette.teal[3], 0.18)
								g.rectangle("fill", x + 64, y + 50, 120, 54, 8, 8)
							end,
						}, {
							ui.box({
								position = "absolute",
								left = 44 + wave(ctx, 3.2) * 148,
								top = 58,
								width = 28,
								height = 28,
								style = {
									background = palette.teal,
									borderColor = { 1, 1, 1, 0.58 },
									borderWidth = 1,
									radius = 14,
								},
							}),
							ui.text(
								"virtual 320x180",
								{ position = "absolute", left = 18, bottom = 18, style = { color = palette.text } }
							),
						}),
						ui.text("Pointer math stays inside the virtual frame.", {
							wrap = true,
							width = "100%",
							style = { color = palette.muted },
						}),
					}),
				})
			)
		end,
	}),

	target({
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
			return stage(
				ctx,
				"Custom Draw",
				"Game-specific visuals stay in app draw functions.",
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
								local hullPoints = ui.polygonBox(hull.x, hull.y, hull.width, hull.height, { skew = 24 })
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
								drawCtx:printf("morph", morphBounds.x, morphBounds.y + 15, morphBounds.width, "center")
							end,
						}),
						ui.row({ width = "100%", gap = 8 }, {
							metric("path", tostring(math.floor(pathProgress * 100 + 0.5)) .. "%", palette.gold),
							metric("morph", tostring(math.floor(pathMorph * 100 + 0.5)) .. "%", palette.teal),
						}),
					}),
				})
			)
		end,
	}),

	target({
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
	}),

	target({
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
	}),

	target({
		id = "scenes-modals",
		title = "Scenes And Modals",
		docs = { "docs/scenes-and-modals.md" },
		alt = "Animated GIF showing Glyph scene layers, overlays, modal blocking, and backdrop behavior.",
		setup = function(ctx)
			ctx.modal = false
		end,
		actions = {
			{
				at = 0.75,
				run = function(ctx)
					ctx.modal = true
				end,
			},
			{
				at = 1.75,
				run = function(ctx)
					ctx.modal = false
				end,
			},
		},
		component = function(ctx)
			return stage(
				ctx,
				"Scenes And Modals",
				"Layered roots route input from top to bottom.",
				ui.stack({ width = "100%", height = 304 }, {
					ui.box({
						position = "absolute",
						left = 20,
						top = 18,
						width = 480,
						height = 226,
						style = {
							background = cloneColor(palette.blue, 0.2),
							borderColor = palette.blue,
							borderWidth = 2,
							radius = 8,
						},
					}, {
						ui.text(
							"main scene",
							{ position = "absolute", left = 18, top = 18, style = { color = palette.text } }
						),
						ui.meter({
							position = "absolute",
							left = 18,
							top = 68,
							width = 360,
							height = 16,
							value = 70,
							max = 100,
							fillStyle = { background = palette.teal },
						}),
					}),
					ui.box({
						position = "absolute",
						right = 36,
						top = 42,
						width = 260,
						height = 112,
						zIndex = 3,
						style = {
							background = cloneColor(palette.gold, 0.2),
							borderColor = palette.gold,
							borderWidth = 2,
							radius = 8,
						},
					}, {
						ui.text(
							"non-blocking overlay",
							{ position = "absolute", left = 16, top = 40, style = { color = palette.text } }
						),
					}),
					ctx.modal and ui.box({
						position = "absolute",
						inset = 0,
						zIndex = 10,
						style = { background = { 0, 0, 0, 0.42 }, radius = 8 },
					}, {
						ui.box({
							position = "absolute",
							left = 294,
							top = 76,
							width = 300,
							height = 142,
							style = {
								background = palette.panel2,
								borderColor = palette.coral,
								borderWidth = 2,
								radius = 8,
							},
						}, {
							ui.text(
								"modal layer",
								{ position = "absolute", left = 22, top = 28, style = { color = palette.text } }
							),
							ui.text(
								"blocking input",
								{ position = "absolute", left = 22, top = 66, style = { color = palette.muted } }
							),
						}),
					}) or nil,
				})
			)
		end,
	}),

	target({
		id = "transitions",
		title = "Transitions",
		docs = { "docs/transitions.md" },
		alt = "Animated GIF showing Glyph fade, slide, shader-style, and animated layer transitions.",
		update = function(ctx)
			ctx.progress = wave(ctx, 2.1)
		end,
		component = function(ctx)
			local p = ctx.progress or 0
			return stage(
				ctx,
				"Transitions",
				"Layers can fade, slide, animate, or delegate custom drawing.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("built-ins", { flex = 1, height = 284 }, {
						ui.stack({ width = "100%", height = 190 }, {
							ui.box({
								position = "absolute",
								left = 20,
								top = 22,
								width = 280,
								height = 128,
								style = {
									background = cloneColor(palette.blue, 0.22),
									borderColor = palette.blue,
									borderWidth = 1,
									radius = 8,
								},
							}),
							ui.box({
								position = "absolute",
								left = 72 + p * 190,
								top = 52,
								width = 240,
								height = 128,
								style = {
									background = cloneColor(palette.teal, 0.18 + p * 0.18),
									borderColor = palette.teal,
									borderWidth = 2,
									radius = 8,
								},
							}, {
								ui.text(
									"slide + fade",
									{ position = "absolute", left = 22, top = 52, style = { color = palette.text } }
								),
							}),
						}),
					}),
					panel("custom transition", { width = 320, height = 284 }, {
						ui.box({
							width = 250,
							height = 150,
							draw = function(_, x, y, width, height, loveModule)
								local g = loveModule.graphics
								g.setColor(0.03, 0.04, 0.055, 1)
								g.rectangle("fill", x, y, width, height, 8, 8)
								for i = 1, 9 do
									local alpha = math.max(0, 0.42 - math.abs(i / 9 - p) * 0.8)
									g.setColor(palette.coral[1], palette.coral[2], palette.coral[3], alpha)
									g.rectangle("fill", x + i * 22, y + 14, 14, height - 28, 7, 7)
								end
								g.setColor(1, 1, 1, 0.74)
								g.rectangle("line", x, y, width, height, 8, 8)
							end,
						}),
						ui.text("ctx.drawLayer() stays app-composable.", { style = { color = palette.muted } }),
					}),
				})
			)
		end,
	}),

	target({
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
	}),

	target({
		id = "menori",
		title = "Menori Adapter",
		docs = { "docs/menori.md" },
		width = 960,
		height = 540,
		fps = 18,
		duration = 4.2,
		exampleApp = "examples/menori",
		env = {
			GLYPH_MENORI_DOC_GIF = "1",
		},
		alt = "Animated GIF showing Glyph Menori scene transitions, loading overlay, HUD, and world-space billboard UI.",
	}),

	target({
		id = "performance",
		title = "Performance",
		docs = { "docs/performance.md" },
		alt = "Animated GIF showing Glyph memoized rows, static nodes, visible windows, and bounded work.",
		setup = function(ctx)
			ctx.offset = 1
		end,
		update = function(ctx)
			ctx.offset = 1 + math.floor(wave(ctx, 1.7) * 16)
		end,
		component = function(ctx)
			local rows = {}
			for i = 0, 7 do
				local index = ctx.offset + i
				rows[#rows + 1] = ui.row({
					height = 28,
					width = "100%",
					gap = 8,
					align = "center",
					style = {
						background = i % 2 == 0 and { 1, 1, 1, 0.035 } or { 1, 1, 1, 0.015 },
						radius = 4,
					},
				}, {
					ui.text("#" .. tostring(index), { width = 54, style = { color = palette.muted } }),
					ui.meter({
						value = (index * 13) % 100,
						max = 100,
						height = 10,
						flex = 1,
						fillStyle = { background = ({ palette.teal, palette.gold, palette.coral })[index % 3 + 1] },
					}),
					ui.text("static row", { width = 92, textStyle = "caption", style = { color = palette.text } }),
				})
			end

			return stage(
				ctx,
				"Performance",
				"Memo, static nodes, and visible windows keep work bounded.",
				ui.row({ gap = 14, width = "100%", align = "stretch" }, {
					panel("visible rows", { flex = 1, height = 310 }, rows),
					panel("work budget", { width = 318, height = 310 }, {
						metric("mounted rows", "8 / 10k", palette.teal),
						metric("memo hits", tostring(80 + math.floor(wave(ctx, 4.5) * 18)) .. "%", palette.gold),
						metric("layout pass", wave(ctx, 7) > 0.5 and "dirty" or "clean", palette.coral),
						ui.text("Large data demos should show bounded rendering, not full-list churn.", {
							wrap = true,
							width = "100%",
							style = { color = palette.muted },
						}),
					}),
				})
			)
		end,
	}),
}

function Manifest.targets()
	return targets
end

function Manifest.find(id)
	for _, item in ipairs(targets) do
		if item.id == id then
			return item
		end
	end
	return nil
end

return Manifest
