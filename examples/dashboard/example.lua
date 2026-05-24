local ui = require("glyph")

local activeNav = "Dashboard"
local chartRange = "3m"
local selectedView = "Overview"
local search = ""

local rows = {
	{
		title = "Cover page",
		section = "Cover page",
		status = "In Process",
		target = 18,
		limit = 5,
		reviewer = "Eddie Lake",
	},
	{
		title = "Table of contents",
		section = "Table of contents",
		status = "Done",
		target = 29,
		limit = 24,
		reviewer = "Eddie Lake",
	},
	{
		title = "Executive summary",
		section = "Narrative",
		status = "Done",
		target = 10,
		limit = 13,
		reviewer = "Eddie Lake",
	},
	{
		title = "Technical approach",
		section = "Narrative",
		status = "Done",
		target = 27,
		limit = 23,
		reviewer = "Jamik Tashpulatov",
	},
	{
		title = "Design",
		section = "Narrative",
		status = "In Process",
		target = 2,
		limit = 16,
		reviewer = "Jamik Tashpulatov",
	},
	{
		title = "Capabilities",
		section = "Narrative",
		status = "In Process",
		target = 20,
		limit = 8,
		reviewer = "Jamik Tashpulatov",
	},
	{
		title = "Integration with existing systems",
		section = "Narrative",
		status = "In Process",
		target = 19,
		limit = 21,
		reviewer = "Assign reviewer",
	},
	{
		title = "Innovation and Advantages",
		section = "Narrative",
		status = "Done",
		target = 25,
		limit = 26,
		reviewer = "Assign reviewer",
	},
	{
		title = "Overview of EMR's Innovative Solutions",
		section = "Technical content",
		status = "Done",
		target = 7,
		limit = 23,
		reviewer = "Assign reviewer",
	},
	{
		title = "Advanced Algorithms and Machine Learning",
		section = "Narrative",
		status = "Done",
		target = 30,
		limit = 28,
		reviewer = "Assign reviewer",
	},
}

local baseRows = rows
rows = {}
for cycle = 1, 8 do
	for _, row in ipairs(baseRows) do
		rows[#rows + 1] = {
			title = row.title .. " " .. cycle,
			section = row.section,
			status = (cycle + row.target) % 3 == 0 and "In Process" or row.status,
			target = row.target + cycle,
			limit = row.limit + (cycle % 4),
			reviewer = cycle % 3 == 0 and "Assign reviewer" or row.reviewer,
		}
	end
end

local visitors = { 220, 310, 280, 420, 390, 520, 480, 610, 590, 710, 690, 760 }

local exampleTheme = {
	backgroundColor = { 0.965, 0.965, 0.955, 1 },
	surfaceColor = { 1, 1, 1, 1 },
	surfaceHoverColor = { 0.925, 0.94, 0.955, 1 },
	surfacePressedColor = { 0.88, 0.9, 0.925, 1 },
	borderColor = { 0.82, 0.84, 0.86, 1 },
	textColor = { 0.08, 0.09, 0.105, 1 },
	mutedTextColor = { 0.45, 0.48, 0.52, 1 },
	accentColor = { 0.1, 0.12, 0.14, 1 },
	accentTextColor = { 1, 1, 1, 1 },
	components = {
		button = {
			radius = 5,
			variants = {
				nav = {
					background = { 0, 0, 0, 0 },
					borderColor = { 0, 0, 0, 0 },
					color = { 0.3, 0.34, 0.38, 1 },
					hover = { background = { 0.92, 0.93, 0.94, 1 } },
					active = {
						background = { 0.08, 0.09, 0.105, 1 },
						color = { 1, 1, 1, 1 },
					},
				},
				subtle = {
					background = { 0.945, 0.95, 0.955, 1 },
					borderColor = { 0.82, 0.84, 0.86, 1 },
					color = { 0.12, 0.14, 0.16, 1 },
					hover = { background = { 0.9, 0.915, 0.93, 1 } },
				},
			},
		},
	},
}

local cardStyle = ui.style({
	background = { 1, 1, 1, 1 },
	borderColor = ui.theme.borderColor,
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
	local tableInner = innerWidth - 20 - tableGap * 6
	local tableHeight = math.max(180, height - (compact and 468 or 430))

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
		tableHeight = tableHeight,
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
	if search == "" then
		return rows
	end

	local result = {}
	local needle = search:lower()
	for _, row in ipairs(rows) do
		if
			row.title:lower():find(needle, 1, true)
			or row.section:lower():find(needle, 1, true)
			or row.status:lower():find(needle, 1, true)
		then
			result[#result + 1] = row
		end
	end
	return result
end

local function navButton(label, width)
	return ui.button({
		label = label,
		variant = "nav",
		active = activeNav == label,
		width = width,
		onClick = function()
			activeNav = label
		end,
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
					color = positive and { 0.08, 0.45, 0.24, 1 } or { 0.72, 0.16, 0.18, 1 },
				},
			}),
			ui.text(positive and "Trending up" or "Needs attention", { style = muted }),
		}),
		ui.text(caption, { width = math.max(80, width - 24), wrap = true, style = muted }),
	})
end

local function chartPanel(m)
	return ui.box({
		width = "100%",
		height = 224,
		padding = 14,
		display = "column",
		gap = 10,
		style = cardStyle,
	}, {
		ui.row({ gap = 8, align = "center" }, {
			ui.column({ gap = 2, grow = 1 }, {
				ui.text("Total Visitors"),
				ui.text("Last " .. (chartRange == "3m" and "3 months" or "6 months"), { style = muted }),
			}),
			ui.button({
				label = "3 months",
				variant = chartRange == "3m" and "primary" or "subtle",
				onClick = function()
					chartRange = "3m"
				end,
			}),
			ui.button({
				label = "6 months",
				variant = chartRange == "6m" and "primary" or "subtle",
				onClick = function()
					chartRange = "6m"
				end,
			}),
		}),
		ui.box({
			width = "100%",
			height = 154,
			draw = function(_, x, y, width, height, love, style)
				love.graphics.setColor(0.965, 0.97, 0.975, 1)
				love.graphics.rectangle("fill", x, y, width, height, 6, 6)
				love.graphics.setColor(0.84, 0.86, 0.88, 1)
				for index = 1, 4 do
					local gy = y + index * height / 5
					love.graphics.line(x + 12, gy, x + width - 12, gy)
				end

				local maxValue = 800
				local barWidth = (width - 48) / #visitors
				for index, value in ipairs(visitors) do
					local barHeight = (value / maxValue) * (height - 32)
					local bx = x + 20 + (index - 1) * barWidth
					local by = y + height - 16 - barHeight
					love.graphics.setColor(0.12, 0.14, 0.16, 0.9)
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
			background = done and { 0.9, 0.97, 0.92, 1 } or { 1, 0.95, 0.82, 1 },
			borderColor = done and { 0.62, 0.82, 0.66, 1 } or { 0.9, 0.72, 0.3, 1 },
			borderWidth = 1,
			radius = 4,
		},
		draw = function(_, x, y, width, height, love)
			love.graphics.setColor(done and 0.9 or 1, done and 0.97 or 0.95, done and 0.92 or 0.82, 1)
			love.graphics.rectangle("fill", x, y, width, height, 4, 4)
			love.graphics.setColor(done and 0.62 or 0.9, done and 0.82 or 0.72, done and 0.66 or 0.3, 1)
			love.graphics.rectangle("line", x, y, width, height, 4, 4)
			love.graphics.setColor(done and 0.08 or 0.36, done and 0.36 or 0.25, done and 0.16 or 0.04, 1)
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
		width = "100%",
		gap = m.tableGap,
		align = "center",
		padding = { x = 10, y = 6 },
		style = {
			background = index % 2 == 0 and { 0.985, 0.987, 0.99, 1 } or { 1, 1, 1, 1 },
			borderColor = { 0.9, 0.91, 0.92, 1 },
			borderWidth = 1,
		},
	}, children)
end

local function dataTable(m)
	local header = {}
	if not m.compact then
		header[#header + 1] = ui.text("", { width = m.dragWidth })
	end
	header[#header + 1] = ui.text("Header", { width = m.titleWidth, style = muted })
	if not m.compact then
		header[#header + 1] = ui.text("Section Type", { width = m.sectionWidth, style = muted })
	end
	header[#header + 1] = ui.text("Status", { width = m.statusWidth, style = muted })
	if not m.compact then
		header[#header + 1] = ui.text("Target", { width = m.targetWidth, style = muted })
		header[#header + 1] = ui.text("Limit", { width = m.limitWidth, style = muted })
	end
	header[#header + 1] = ui.text("Reviewer", { flex = 1, style = muted })

	local bodyRows = {}
	for index, row in ipairs(filteredRows()) do
		bodyRows[#bodyRows + 1] = tableRow(row, index, m)
	end

	return ui.box({
		width = "100%",
		height = m.tableHeight,
		padding = 0,
		display = "column",
		style = cardStyle,
	}, {
		ui.row({
			width = "100%",
			gap = m.tableGap,
			padding = { x = 10, y = 8 },
			style = {
				background = { 0.955, 0.96, 0.965, 1 },
				borderColor = { 0.86, 0.88, 0.9, 1 },
				borderWidth = 1,
			},
		}, header),

		ui.scrollView({
			width = "100%",
			flex = 1,
			display = "column",
			gap = 0,
			scrollbar = {
				width = 7,
				padding = 4,
				radius = 4,
				trackColor = { 0.92, 0.93, 0.94, 1 },
				thumbColor = { 0.42, 0.46, 0.5, 0.9 },
				minThumbSize = 32,
			},
		}, bodyRows),
	})
end

local function App()
	local m = metrics()
	local cards = {
		metricCard("Total Revenue", "$1,250.00", "+12.5%", "Visitors for the last 6 months", true, m.cardWidth),
		metricCard("New Customers", "1,234", "-20%", "Acquisition needs attention", false, m.cardWidth),
		metricCard("Active Accounts", "45,678", "+12.5%", "Engagement exceed targets", true, m.cardWidth),
		metricCard("Growth Rate", "4.5%", "+4.5%", "Meets growth projections", true, m.cardWidth),
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

	local shellChildren = {}
	if not m.compact then
		shellChildren[#shellChildren + 1] = ui.column({
			width = m.sidebarWidth,
			height = m.height,
			gap = 8,
			padding = 14,
			style = {
				background = { 0.985, 0.987, 0.99, 1 },
				borderColor = ui.theme.borderColor,
				borderWidth = 1,
			},
		}, {
			ui.text("Acme Inc.", { style = { color = ui.theme.textColor } }),
			ui.text("Documents", { style = muted }),
			navButton("Dashboard", m.sidebarWidth - 28),
			navButton("Lifecycle", m.sidebarWidth - 28),
			navButton("Analytics", m.sidebarWidth - 28),
			navButton("Projects", m.sidebarWidth - 28),
			navButton("Team", m.sidebarWidth - 28),
			ui.box({ height = math.max(24, m.height - 440) }),
			ui.text("Kyonru", { style = muted }),
		})
	end

	local headerChildren = {
		ui.text("Documents", { flex = 1 }),
		ui.input({
			width = m.compact and 150 or 184,
			value = search,
			placeholder = "Filter documents...",
			onChange = function(value)
				search = value
			end,
		}),
	}
	if not m.compact then
		headerChildren[#headerChildren + 1] = ui.button({
			label = selectedView,
			variant = "subtle",
			onClick = function()
				selectedView = selectedView == "Overview" and "Columns" or "Overview"
			end,
		})
	end

	local contentChildren = {
		ui.row({ gap = 8, align = "center" }, headerChildren),
	}
	for _, row in ipairs(cardRows) do
		contentChildren[#contentChildren + 1] = row
	end
	contentChildren[#contentChildren + 1] = chartPanel(m)
	contentChildren[#contentChildren + 1] = dataTable(m)

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
end

return {
	id = "dashboard",
	label = "Dashboard",
	setup = setup,
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
