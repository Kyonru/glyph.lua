local ui = require("glyph")

local activeNav = "Overview"
local chartRange = "1w"
local selectedView = "Overview"
local search = ""
local dashboardMetrics = {
	fps = 0,
	frame = 0,
	layoutCount = 0,
	mountedRows = 0,
	renderMs = 0,
	totalRows = 0,
}
local renderStartedAt = 0
local diagnosticsInstalled = false
local memoContext = {}
local TABLE_SCROLL_KEY = "dashboard-table-scroll"
local CHART_BUCKETS = 12
local chartRanges = {
	{ id = "1d", label = "1 day", hours = 24 },
	{ id = "1w", label = "1 week", hours = 24 * 7 },
	{ id = "1m", label = "1 month", hours = 24 * 30 },
	{ id = "1y", label = "1 year", hours = 24 * 365 },
}
local chartAnimation = {
	key = nil,
	from = {},
	to = {},
	startedAt = 0,
	duration = 0.34,
}

local rows = {
	{
		title = "Relay handoff",
		section = "Signal",
		status = "Routing",
		target = 18,
		limit = 5,
		reviewer = "Mara Voss",
	},
	{
		title = "Drone camera scrub",
		section = "Review",
		status = "Done",
		target = 29,
		limit = 24,
		reviewer = "Mara Voss",
	},
	{
		title = "North gate ping",
		section = "Watch",
		status = "Done",
		target = 10,
		limit = 13,
		reviewer = "Ilya Chen",
	},
	{
		title = "Beacon drift fix",
		section = "Repair",
		status = "Done",
		target = 27,
		limit = 23,
		reviewer = "Ilya Chen",
	},
	{
		title = "Cargo route audit",
		section = "Ops",
		status = "Routing",
		target = 2,
		limit = 16,
		reviewer = "Noa Faye",
	},
	{
		title = "Coolant variance",
		section = "Safety",
		status = "Routing",
		target = 20,
		limit = 8,
		reviewer = "Noa Faye",
	},
	{
		title = "Patrol overlap",
		section = "Schedule",
		status = "Routing",
		target = 19,
		limit = 21,
		reviewer = "Assign operator",
	},
	{
		title = "Outpost packet replay",
		section = "Forensics",
		status = "Done",
		target = 25,
		limit = 26,
		reviewer = "Assign operator",
	},
	{
		title = "Beacon array checksum",
		section = "Signal",
		status = "Done",
		target = 7,
		limit = 23,
		reviewer = "Assign operator",
	},
	{
		title = "Fuel lane conflict",
		section = "Ops",
		status = "Done",
		target = 30,
		limit = 28,
		reviewer = "Assign operator",
	},
}

local baseRows = rows
rows = {}
local ageBases = { 1, 8, 18, 54, 132, 310, 760, 2200 }
for cycle = 1, 8 do
	for baseIndex, row in ipairs(baseRows) do
		local ageStep = cycle <= 3 and 1.2 or cycle <= 5 and 8 or cycle <= 7 and 36 or 240
		local ageHours = ageBases[cycle] + (baseIndex - 1) * ageStep
		rows[#rows + 1] = {
			title = row.title .. " " .. cycle,
			section = row.section,
			status = (cycle + row.target) % 3 == 0 and "Routing" or row.status,
			target = row.target + cycle,
			limit = row.limit + (cycle % 4),
			ageHours = ageHours,
			packets = math.max(4, row.target + row.limit + cycle * 3),
			reviewer = cycle % 3 == 0 and "Assign reviewer" or row.reviewer,
		}
	end
end

local function timerNow()
	if love and love.timer and love.timer.getTime then
		return love.timer.getTime()
	end
	return os.clock()
end

local function currentFps()
	if love and love.timer and love.timer.getFPS then
		return love.timer.getFPS()
	end
	return 0
end

local colors = {
	bg = { 0.075, 0.085, 0.105, 1 },
	sidebar = { 0.095, 0.108, 0.132, 1 },
	surface = { 0.12, 0.138, 0.165, 1 },
	surface2 = { 0.15, 0.17, 0.2, 1 },
	surface3 = { 0.18, 0.205, 0.24, 1 },
	border = { 0.25, 0.29, 0.34, 1 },
	borderSoft = { 0.19, 0.22, 0.27, 1 },
	text = { 0.86, 0.9, 0.94, 1 },
	muted = { 0.58, 0.65, 0.72, 1 },
	accent = { 0.35, 0.72, 0.95, 1 },
	accentSoft = { 0.13, 0.23, 0.3, 1 },
	good = { 0.36, 0.8, 0.55, 1 },
	warn = { 0.94, 0.68, 0.28, 1 },
	bad = { 0.92, 0.42, 0.44, 1 },
}

local exampleTheme = {
	backgroundColor = colors.bg,
	surfaceColor = colors.surface,
	surfaceHoverColor = colors.surface2,
	surfacePressedColor = { 0.09, 0.105, 0.13, 1 },
	borderColor = colors.border,
	textColor = colors.text,
	mutedTextColor = colors.muted,
	accentColor = colors.accent,
	accentTextColor = { 0.05, 0.07, 0.09, 1 },
	components = {
		button = {
			radius = 5,
			variants = {
				nav = {
					background = { 0, 0, 0, 0 },
					borderColor = { 0, 0, 0, 0 },
					color = colors.muted,
					hover = { background = colors.surface2, color = colors.text },
					pressed = { background = { 0.11, 0.14, 0.17, 1 } },
					active = {
						background = colors.accentSoft,
						borderColor = { colors.accent[1], colors.accent[2], colors.accent[3], 0.45 },
						color = { 0.88, 0.96, 1, 1 },
					},
				},
				subtle = {
					background = colors.surface2,
					borderColor = colors.border,
					color = colors.text,
					hover = { background = colors.surface3 },
				},
			},
		},
	},
}

local cardStyle = ui.style({
	background = colors.surface,
	borderColor = colors.borderSoft,
	borderWidth = 1,
	radius = 6,
})

local muted = ui.style({ color = ui.theme.mutedTextColor })

local function metrics()
	local viewport = ui.viewport()
	local width = viewport.width
	local height = viewport.height
	local compact = ui.below("md")
	local sidebarWidth = compact and 0 or ui.clamp(width * 0.22, 172, 210)
	local availableContentWidth = math.max(340, width - sidebarWidth)
	local innerWidth = math.max(312, availableContentWidth - 28)
	local cardGap = 10
	local cardColumns = ui.columns(innerWidth, {
		min = compact and 150 or 160,
		maxCount = compact and 2 or 4,
		gap = cardGap,
	})
	local cardsPerRow = cardColumns.count
	local cardWidth = cardColumns.width
	local tableGap = compact and 6 or 10
	local tableGutter = 18
	local tableWidth = innerWidth
	local tableInner = tableWidth - 20 - tableGutter - tableGap * 6
	local tableHeight = math.max(180, height - (compact and 468 or 430))
	local tableHeaderHeight = 42
	local tableRowHeight = 42

	return {
		width = width,
		height = height,
		compact = compact,
		sidebarWidth = sidebarWidth,
		innerWidth = innerWidth,
		cardGap = cardGap,
		cardsPerRow = cardsPerRow,
		cardWidth = cardWidth,
		tableGap = tableGap,
		tableGutter = tableGutter,
		tableWidth = tableWidth,
		tableHeight = tableHeight,
		tableHeaderHeight = tableHeaderHeight,
		tableRowHeight = tableRowHeight,
		dragWidth = compact and 0 or 22,
		titleWidth = math.floor(tableInner * (compact and 0.42 or 0.3)),
		sectionWidth = compact and 0 or math.floor(tableInner * 0.18),
		statusWidth = 74,
		targetWidth = compact and 0 or 52,
		limitWidth = compact and 0 or 50,
		reviewerWidth = math.max(88, math.floor(tableInner * (compact and 0.26 or 0.19))),
	}
end

local function filteredRows()
	local rangeHours = chartRanges[#chartRanges].hours
	for _, range in ipairs(chartRanges) do
		if range.id == chartRange then
			rangeHours = range.hours
			break
		end
	end

	local result = {}
	local needle = search:lower()
	for _, row in ipairs(rows) do
		local inRange = (row.ageHours or 0) <= rangeHours
		local matchesSearch = search == ""
		if not matchesSearch then
			matchesSearch = row.title:lower():find(needle, 1, true)
				or row.section:lower():find(needle, 1, true)
				or row.status:lower():find(needle, 1, true)
		end
		if inRange and matchesSearch then
			result[#result + 1] = row
		end
	end
	return result
end

local function currentRange()
	for _, range in ipairs(chartRanges) do
		if range.id == chartRange then
			return range
		end
	end
	return chartRanges[#chartRanges]
end

local function chartSeries(sourceRows)
	local range = currentRange()
	local buckets = {}
	for index = 1, CHART_BUCKETS do
		buckets[index] = 0
	end

	local total = 0
	for _, row in ipairs(sourceRows) do
		local age = math.max(0, row.ageHours or 0)
		local normalized = 1 - math.min(1, age / range.hours)
		local bucket = math.max(1, math.min(CHART_BUCKETS, math.floor(normalized * CHART_BUCKETS) + 1))
		local value = row.packets or (row.target or 0) + (row.limit or 0)
		buckets[bucket] = buckets[bucket] + value
		total = total + value
	end

	return {
		key = chartRange .. ":" .. search .. ":" .. tostring(#sourceRows) .. ":" .. tostring(total),
		label = range.label,
		total = total,
		values = buckets,
	}
end

local function interpolateSeries(from, to, amount)
	local result = {}
	for index = 1, CHART_BUCKETS do
		local a = from[index] or 0
		local b = to[index] or 0
		result[index] = a + (b - a) * amount
	end
	return result
end

local function animatedChartValues(series)
	local now = timerNow()
	if chartAnimation.key ~= series.key then
		local previous = chartAnimation.key and animatedChartValues({
			key = chartAnimation.key,
			values = chartAnimation.to,
		}) or series.values
		chartAnimation.key = series.key
		chartAnimation.from = previous
		chartAnimation.to = series.values
		chartAnimation.startedAt = now
	end

	local progress = math.min(1, math.max(0, (now - chartAnimation.startedAt) / chartAnimation.duration))
	local eased = 1 - (1 - progress) * (1 - progress) * (1 - progress)
	return interpolateSeries(chartAnimation.from, chartAnimation.to, eased)
end

local function navButton(label, width)
	local function selectNav()
		activeNav = label
	end

	return ui.button({
		label = label,
		variant = "nav",
		active = activeNav == label,
		width = width,
		feedback = {
			press = "dashboard.nav.press",
			release = "dashboard.nav.release",
			activate = "dashboard.nav.activate",
		},
		onMousePressed = selectNav,
		onClick = selectNav,
	})
end

local function diagnosticBadge(label, value, tint, width)
	return ui.box({
		width = width or 118,
		height = 44,
		padding = { x = 10, y = 7 },
		display = "column",
		gap = 3,
		style = {
			background = { 0.08, 0.115, 0.14, 1 },
			borderColor = { tint[1], tint[2], tint[3], 0.42 },
			borderWidth = 1,
			radius = 5,
		},
	}, {
		ui.text(label, { style = muted }),
		ui.text(value, {
			style = {
				color = { tint[1], tint[2], tint[3], 1 },
			},
		}),
	})
end

local function diagnosticsStrip(m)
	local width = m.compact and 92 or 116

	return ui.row({ width = "100%", gap = 8, wrap = true }, {
		diagnosticBadge("fps", string.format("%1d", dashboardMetrics.fps), colors.accent, width),
		diagnosticBadge("render", string.format("%.2f ms", dashboardMetrics.renderMs), colors.good, width),
		diagnosticBadge("layouts", tostring(dashboardMetrics.layoutCount), colors.warn, width),
		diagnosticBadge("rows", tostring(dashboardMetrics.totalRows), colors.muted, width),
		diagnosticBadge("mounted", tostring(dashboardMetrics.mountedRows), colors.muted, width),
	})
end

local function metricCard(title, value, delta, caption, positive, width)
	return ui.box({
		width = width,
		height = 116,
		padding = 12,
		display = "column",
		gap = 7,
		style = cardStyle,
	}, {
		ui.text(title, { style = muted }),
		ui.text(value, {
			style = {
				color = ui.theme.textColor,
			},
		}),
		ui.row({ gap = 8, align = "center" }, {
			ui.text(delta, {
				style = {
					color = positive and colors.good or colors.bad,
				},
			}),
			ui.text(positive and "Trending up" or "Needs attention", { style = muted }),
		}),
		ui.text(caption, { width = math.max(80, width - 24), wrap = true, style = muted }),
	})
end

local function chartPanel(m)
	local sourceRows = filteredRows()
	local series = chartSeries(sourceRows)
	local bars = animatedChartValues(series)
	local headerCopyWidth = math.max(180, m.innerWidth - 420)
	local rangeButtons = {}
	for _, range in ipairs(chartRanges) do
		local rangeId = range.id
		local rangeLabel = range.label
		rangeButtons[#rangeButtons + 1] = ui.button({
			label = rangeLabel,
			variant = chartRange == rangeId and "primary" or "subtle",
			feedback = {
				press = "dashboard.button.press",
				release = "dashboard.button.release",
				activate = "dashboard.button.activate",
			},
			onClick = function()
				chartRange = rangeId
				ui.scrollTo(TABLE_SCROLL_KEY, 0)
			end,
		})
	end

	return ui.box({
		width = "100%",
		height = 224,
		padding = 14,
		display = "column",
		gap = 10,
		style = cardStyle,
	}, {
		ui.row({ width = "100%", gap = 12, align = "center" }, {
			ui.column({ width = headerCopyWidth, gap = 2 }, {
				ui.text("Queue Volume"),
				ui.text(string.format("%s window, %d packets in %d rows", series.label, series.total, #sourceRows), {
					width = "100%",
					wrap = true,
					style = muted,
				}),
			}),
			ui.box({ grow = 1, height = 1, interactive = false }),
			ui.row({ gap = 8, wrap = true, justify = "end" }, rangeButtons),
		}),
		ui.box({
			width = "100%",
			height = 154,
			draw = function(_, x, y, width, height, love, style)
				love.graphics.setColor(colors.bg)
				love.graphics.rectangle("fill", x, y, width, height, 6, 6)
				love.graphics.setColor(0.24, 0.28, 0.33, 0.78)
				for index = 1, 4 do
					local gy = y + index * height / 5
					love.graphics.line(x + 12, gy, x + width - 12, gy)
				end

				local maxValue = 1
				for _, value in ipairs(bars) do
					maxValue = math.max(maxValue, value)
				end
				local barWidth = (width - 48) / #bars
				for index, value in ipairs(bars) do
					local barHeight = (value / maxValue) * (height - 32)
					local bx = x + 20 + (index - 1) * barWidth
					local by = y + height - 16 - barHeight
					love.graphics.setColor(
						colors.accent[1],
						colors.accent[2],
						colors.accent[3],
						0.58 + index / #bars * 0.28
					)
					love.graphics.rectangle("fill", bx, by, barWidth - 8, barHeight, 3, 3)
				end
			end,
		}),
	})
end

local function statusPill(status)
	local done = status == "Done"
	return ui.box({
		width = 74,
		height = 24,
		style = {
			background = done and { 0.12, 0.22, 0.16, 1 } or { 0.24, 0.19, 0.1, 1 },
			borderColor = done and { colors.good[1], colors.good[2], colors.good[3], 0.55 }
				or { colors.warn[1], colors.warn[2], colors.warn[3], 0.55 },
			borderWidth = 1,
			radius = 4,
		},
		draw = function(_, x, y, width, height, love)
			love.graphics.setColor(done and 0.12 or 0.24, done and 0.22 or 0.19, done and 0.16 or 0.1, 1)
			love.graphics.rectangle("fill", x, y, width, height, 4, 4)
			love.graphics.setColor(
				done and colors.good[1] or colors.warn[1],
				done and colors.good[2] or colors.warn[2],
				done and colors.good[3] or colors.warn[3],
				0.55
			)
			love.graphics.rectangle("line", x, y, width, height, 4, 4)
			love.graphics.setColor(
				done and colors.good[1] or colors.warn[1],
				done and colors.good[2] or colors.warn[2],
				done and colors.good[3] or colors.warn[3],
				1
			)
			love.graphics.print(status, x + 8, y + 5)
		end,
	})
end

local function tableRow(row, index, m)
	local children = {}
	if not m.compact then
		children[#children + 1] = ui.text("::", { width = m.dragWidth, style = muted })
	end

	children[#children + 1] = ui.text(row.title, { width = m.titleWidth, wrap = true })
	if not m.compact then
		children[#children + 1] = ui.text(row.section, { width = m.sectionWidth, wrap = true, style = muted })
	end
	children[#children + 1] = statusPill(row.status)
	if not m.compact then
		children[#children + 1] = ui.text(tostring(row.target), { width = m.targetWidth })
		children[#children + 1] = ui.text(tostring(row.limit), { width = m.limitWidth })
	end
	children[#children + 1] = ui.text(row.reviewer, { flex = 1, wrap = true, style = muted })

	return ui.row({
		width = m.tableWidth,
		height = m.tableRowHeight,
		gap = m.tableGap,
		align = "center",
		padding = { left = 10, right = 10 + m.tableGutter, y = 6 },
		style = {
			background = index % 2 == 0 and { 0.13, 0.15, 0.18, 1 } or { 0.115, 0.132, 0.16, 1 },
			borderColor = colors.borderSoft,
			borderWidth = 1,
		},
	}, children)
end

local function dataTable(m)
	local header = {}
	if not m.compact then
		header[#header + 1] = ui.text("", { width = m.dragWidth })
	end
	header[#header + 1] = ui.text("Packet", { width = m.titleWidth, style = muted })
	if not m.compact then
		header[#header + 1] = ui.text("Lane", { width = m.sectionWidth, style = muted })
	end
	header[#header + 1] = ui.text("Status", { width = m.statusWidth, style = muted })
	if not m.compact then
		header[#header + 1] = ui.text("ETA", { width = m.targetWidth, style = muted })
		header[#header + 1] = ui.text("SLA", { width = m.limitWidth, style = muted })
	end
	header[#header + 1] = ui.text("Operator", { flex = 1, style = muted })

	local sourceRows = filteredRows()

	return ui.box({
		width = m.tableWidth,
		height = m.tableHeight,
		padding = 0,
		display = "column",
		style = cardStyle,
	}, {
		ui.row({
			width = m.tableWidth,
			height = m.tableHeaderHeight,
			gap = m.tableGap,
			padding = { left = 10, right = 10 + m.tableGutter, y = 8 },
			style = {
				background = colors.surface2,
				borderColor = colors.border,
				borderWidth = 1,
			},
		}, header),

		ui.virtualList({
			key = TABLE_SCROLL_KEY,
			width = m.tableWidth,
			height = math.max(1, m.tableHeight - m.tableHeaderHeight),
			itemCount = #sourceRows,
			itemHeight = m.tableRowHeight,
			overscan = 3,
			itemKey = function(index)
				return sourceRows[index] and sourceRows[index].title or index
			end,
			renderItem = function(index)
				return tableRow(sourceRows[index], index, m)
			end,
			onRangeChange = function(_, _, info)
				dashboardMetrics.totalRows = info.itemCount
				dashboardMetrics.mountedRows = info.mounted
			end,
			gap = 0,
			scrollbar = {
				width = 7,
				padding = 4,
				radius = 4,
				trackColor = { 0.09, 0.105, 0.13, 1 },
				thumbColor = { colors.accent[1], colors.accent[2], colors.accent[3], 0.72 },
				minThumbSize = 32,
			},
		}),
	})
end

local function memoizedSidebar()
	local m = memoContext.metrics

	return ui.column({
		width = m.sidebarWidth,
		height = m.height,
		gap = 8,
		padding = 14,
		style = {
			background = colors.sidebar,
			borderColor = colors.borderSoft,
			borderWidth = 1,
		},
	}, {
		ui.static(ui.text("Northstar Ops", { style = { color = ui.theme.textColor } })),
		ui.static(ui.text("Dispatch Flow", { style = muted })),
		navButton("Overview", m.sidebarWidth - 28),
		navButton("Intake", m.sidebarWidth - 28),
		navButton("SLA", m.sidebarWidth - 28),
		navButton("Queues", m.sidebarWidth - 28),
		navButton("Operators", m.sidebarWidth - 28),
		ui.box({ height = math.max(24, m.height - 440) }),
		ui.static(ui.text("Kyonru", { style = muted })),
	})
end

local function memoizedMetricRows()
	local m = memoContext.metrics
	local cards = {
		metricCard("Routed Today", "1,250", "+12.5%", "Packets cleared before handoff", true, m.cardWidth),
		metricCard("SLA Breaches", "12", "-20%", "Escalations need attention", false, m.cardWidth),
		metricCard("Open Signals", "45", "+12.5%", "Queues inside active targets", true, m.cardWidth),
		metricCard("Drift Rate", "4.5%", "+4.5%", "Beacon variance within range", true, m.cardWidth),
	}
	local cardRows = {}
	for index = 1, #cards, m.cardsPerRow do
		local rowChildren = {}
		for offset = 0, m.cardsPerRow - 1 do
			if cards[index + offset] then
				rowChildren[#rowChildren + 1] = cards[index + offset]
			end
		end
		cardRows[#cardRows + 1] = ui.row({ gap = m.cardGap }, rowChildren)
	end

	return ui.column({ width = "100%", gap = 10 }, cardRows)
end

local function memoizedDataTable()
	return dataTable(memoContext.metrics)
end

local function App()
	local m = metrics()
	memoContext.metrics = m
	local tableScrollRow = math.floor(ui.getScrollOffset(TABLE_SCROLL_KEY) / m.tableRowHeight)

	local shellChildren = {}
	if not m.compact then
		shellChildren[#shellChildren + 1] = ui.memo(memoizedSidebar, {
			activeNav,
			m.sidebarWidth,
			m.height,
		})
	end

	local headerChildren = {
		ui.text("Dispatch Queue", { flex = 1 }),
		ui.input({
			width = m.compact and 150 or 184,
			value = search,
			placeholder = "Filter packets...",
			onChange = function(value)
				search = value
				ui.scrollTo(TABLE_SCROLL_KEY, 0)
			end,
		}),
	}
	if not m.compact then
		headerChildren[#headerChildren + 1] = ui.button({
			label = selectedView,
			variant = "subtle",
			feedback = {
				press = "dashboard.button.press",
				release = "dashboard.button.release",
				activate = "dashboard.button.activate",
			},
			onClick = function()
				selectedView = selectedView == "Overview" and "Columns" or "Overview"
			end,
		})
	end

	local contentChildren = {
		ui.row({ gap = 8, align = "center" }, headerChildren),
		diagnosticsStrip(m),
		ui.memo(memoizedMetricRows, {
			m.cardWidth,
			m.cardsPerRow,
			m.cardGap,
		}),
		chartPanel(m),
		ui.memo(memoizedDataTable, {
			search,
			chartRange,
			activeNav,
			m.compact,
			m.innerWidth,
			m.tableGap,
			m.tableGutter,
			m.tableWidth,
			m.tableHeight,
			m.tableHeaderHeight,
			m.tableRowHeight,
			tableScrollRow,
			m.dragWidth,
			m.titleWidth,
			m.sectionWidth,
			m.statusWidth,
			m.targetWidth,
			m.limitWidth,
			m.reviewerWidth,
		}),
	}

	shellChildren[#shellChildren + 1] = ui.column({
		gap = 12,
		padding = 14,
		flex = 1,
		minWidth = 340,
		style = {
			background = ui.theme.backgroundColor,
		},
	}, contentChildren)

	return ui.row({
		gap = 0,
		width = m.width,
		height = m.height,
		style = {
			background = ui.theme.backgroundColor,
		},
	}, shellChildren)
end

local function setup()
	ui.setTheme(exampleTheme)
	if not diagnosticsInstalled then
		ui.on("beforeRender", function()
			renderStartedAt = timerNow()
			dashboardMetrics.layoutCount = 0
		end)
		ui.on("layout", function()
			dashboardMetrics.layoutCount = dashboardMetrics.layoutCount + 1
		end)
		ui.on("afterRender", function()
			dashboardMetrics.renderMs = (timerNow() - renderStartedAt) * 1000
		end)
		diagnosticsInstalled = true
	end
	ui.feedback.define("dashboard.nav.press", {
		{ kind = "animate", to = { scaleX = 1.045, scaleY = 0.91, x = 4, y = 1, rotation = -0.012 }, duration = 0.045, ease = "quadout" },
	})
	ui.feedback.define("dashboard.nav.release", {
		{ kind = "animate", to = { scaleX = 0.985, scaleY = 1.06, x = -1, y = -1, rotation = 0.008 }, duration = 0.07, ease = "quadout" },
		{ kind = "animate", to = { scale = 1, scaleX = 1, scaleY = 1, x = 0, y = 0, rotation = 0 }, duration = 0.18, ease = "backout" },
	})
	ui.feedback.define("dashboard.nav.activate", {
		{ kind = "animate", to = { scaleX = 1.055, scaleY = 0.98, y = -1 }, duration = 0.045, ease = "quadout" },
		{ kind = "animate", to = { scale = 1, scaleX = 1, scaleY = 1, y = 0, rotation = 0 }, duration = 0.16, ease = "backout" },
	})
	ui.feedback.define("dashboard.button.press", {
		{ kind = "animate", to = { scaleX = 1.04, scaleY = 0.9, y = 2, rotation = 0.01 }, duration = 0.045, ease = "quadout" },
	})
	ui.feedback.define("dashboard.button.release", {
		{ kind = "animate", to = { scaleX = 0.975, scaleY = 1.07, y = -2, rotation = -0.006 }, duration = 0.075, ease = "quadout" },
		{ kind = "animate", to = { scale = 1, scaleX = 1, scaleY = 1, y = 0, rotation = 0 }, duration = 0.18, ease = "backout" },
	})
	ui.feedback.define("dashboard.button.activate", {
		{ kind = "animate", to = { scaleX = 1.075, scaleY = 0.985, y = -1 }, duration = 0.05, ease = "quadout" },
		{ kind = "animate", to = { scale = 1, scaleX = 1, scaleY = 1, y = 0, rotation = 0 }, duration = 0.18, ease = "backout" },
	})
end

local function update(dt)
	dashboardMetrics.frame = dashboardMetrics.frame + 1
	dashboardMetrics.fps = currentFps()
	if dashboardMetrics.fps <= 0 and dt and dt > 0 then
		dashboardMetrics.fps = math.floor(1 / dt + 0.5)
	end
	if chartAnimation.key and timerNow() - chartAnimation.startedAt < chartAnimation.duration then
		ui.runtime:markDirty()
	end
end

return {
	id = "dashboard",
	label = "Dashboard",
	description = "A dispatch ops board with sidebar filters, metrics, charts, and a scrollable queue built from Glyph primitives.",
	setup = setup,
	update = update,
	window = {
		width = 928,
		height = 720,
		resizable = true,
		minWidth = 420,
		minHeight = 520,
		breakpoints = {
			md = 760,
		},
	},
	component = function()
		return App()
	end,
}
