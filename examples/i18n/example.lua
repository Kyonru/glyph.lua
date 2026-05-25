local ui = require("glyph")

local locale = "en"
local selectedTab = 1
local selectedCommand = "scan"
local messageCount = 3
local filter = ""
local renderCount = 0
local renderTick = 0
local liveBuilds = 0
local memoBuilds = 0
local translationCalls = 0

local translations = {
	en = {
		["app.title"] = "STRIKE CONSOLE",
		["app.subtitle"] = "Localized game UI powered by app-owned translation data.",
		["locale.en"] = "EN",
		["locale.pseudo"] = "PSEUDO",
		["input.filter"] = "Filter command log...",
		["status.title"] = "Mission Status",
		["status.ready"] = "Ready for launch",
		["status.zone"] = "Zone %{zone}",
		["status.alert"] = "Threat index %{value}%",
		["stats.power"] = "Reactor %{value}%",
		["stats.shield"] = "Shield %{value}%",
		["stats.sync"] = "Sync %{value}%",
		["commands.title"] = "Command Deck",
		["commands.scan"] = "Scan",
		["commands.launch"] = "Launch",
		["commands.guard"] = "Guard",
		["commands.recall"] = "Recall",
		["commands.cancel"] = "Cancel",
		["command.selected"] = "Queued command: %{command}",
		["tabs.overview"] = "Overview",
		["tabs.messages"] = "Messages",
		["messages.one"] = "1 squad message",
		["messages.other"] = "%{count} squad messages",
		["memo.title"] = "Memoized feed",
		["memo.description"] = "Stable until locale or message count changes.",
		["live.title"] = "Live feed",
		["live.description"] = "Rebuilds on every unrelated render.",
		["compare.title"] = "Translation Cost",
		["compare.rerender"] = "Ping UI",
		["compare.reset"] = "Reset",
		["compare.renders"] = "App renders: %{count}",
		["compare.renders_label"] = "App renders",
		["compare.tick"] = "Ping %{count}",
		["compare.tick_label"] = "Ping",
		["compare.live_builds"] = "Live builds: %{count}",
		["compare.live_builds_label"] = "Live builds",
		["compare.memo_builds"] = "Memo builds: %{count}",
		["compare.memo_builds_label"] = "Memo builds",
		["compare.saved_builds_label"] = "Saved rebuilds",
		["compare.translation_calls"] = "Translator calls: %{count}",
		["compare.translation_calls_label"] = "Translator calls",
	},
	pseudo = {
		["app.title"] = "[loc] STRIKE CONSOLE",
		["app.subtitle"] = "[loc] Localized game UI, app-owned translation data.",
		["locale.en"] = "EN",
		["locale.pseudo"] = "PSEUDO",
		["input.filter"] = "[loc] Filter command log...",
		["status.title"] = "[loc] Mission Status",
		["status.ready"] = "[loc] Ready for launch",
		["status.zone"] = "[loc] Zone %{zone}",
		["status.alert"] = "[loc] Threat index %{value}%",
		["stats.power"] = "[loc] Reactor %{value}%",
		["stats.shield"] = "[loc] Shield %{value}%",
		["stats.sync"] = "[loc] Sync %{value}%",
		["commands.title"] = "[loc] Command Deck",
		["commands.scan"] = "[loc] Scan",
		["commands.launch"] = "[loc] Launch",
		["commands.guard"] = "[loc] Guard",
		["commands.recall"] = "[loc] Recall",
		["commands.cancel"] = "[loc] Cancel",
		["command.selected"] = "[loc] Queued command: %{command}",
		["tabs.overview"] = "[loc] Overview",
		["tabs.messages"] = "[loc] Messages",
		["messages.one"] = "[loc] 1 squad message",
		["messages.other"] = "[loc] %{count} squad messages",
		["memo.title"] = "[loc] Memoized feed",
		["memo.description"] = "[loc] Stable until locale or message count changes.",
		["live.title"] = "[loc] Live feed",
		["live.description"] = "[loc] Rebuilds on every unrelated render.",
		["compare.title"] = "[loc] Translation Cost",
		["compare.rerender"] = "[loc] Ping UI",
		["compare.reset"] = "[loc] Reset",
		["compare.renders"] = "[loc] App renders: %{count}",
		["compare.renders_label"] = "[loc] App renders",
		["compare.tick"] = "[loc] Ping %{count}",
		["compare.tick_label"] = "[loc] Ping",
		["compare.live_builds"] = "[loc] Live builds: %{count}",
		["compare.live_builds_label"] = "[loc] Live builds",
		["compare.memo_builds"] = "[loc] Memo builds: %{count}",
		["compare.memo_builds_label"] = "[loc] Memo builds",
		["compare.saved_builds_label"] = "[loc] Saved rebuilds",
		["compare.translation_calls"] = "[loc] Translator calls: %{count}",
		["compare.translation_calls_label"] = "[loc] Translator calls",
	},
}

local theme = {
	backgroundColor = { 0.025, 0.035, 0.055, 1 },
	surfaceColor = { 0.055, 0.075, 0.11, 1 },
	surfaceHoverColor = { 0.08, 0.12, 0.16, 1 },
	surfacePressedColor = { 0.02, 0.04, 0.07, 1 },
	textColor = { 0.92, 0.98, 1, 1 },
	mutedTextColor = { 0.52, 0.68, 0.76, 1 },
	borderColor = { 0.12, 0.42, 0.54, 1 },
	accentColor = { 0.1, 0.84, 1, 1 },
	components = {
		button = {
			background = { 0.05, 0.11, 0.16, 1 },
			borderColor = { 0.1, 0.84, 1, 0.36 },
			borderWidth = 1,
			hover = { background = { 0.08, 0.18, 0.24, 1 }, borderColor = { 0.1, 0.84, 1, 0.8 } },
			pressed = { background = { 0.02, 0.07, 0.11, 1 } },
			focused = { borderColor = { 1, 0.86, 0.22, 1 }, borderWidth = 2 },
			active = { background = { 0.1, 0.84, 1, 0.22 }, borderColor = { 0.1, 0.84, 1, 1 } },
			variants = {
				danger = {
					background = { 0.32, 0.06, 0.08, 1 },
					borderColor = { 1, 0.2, 0.28, 0.75 },
					hover = { background = { 0.45, 0.08, 0.12, 1 } },
				},
			},
		},
		panel = {
			background = { 0.045, 0.06, 0.09, 0.92 },
			borderColor = { 0.1, 0.84, 1, 0.3 },
			borderWidth = 1,
		},
		input = {
			background = { 0.02, 0.035, 0.055, 1 },
			borderColor = { 0.1, 0.84, 1, 0.28 },
			focused = { borderColor = { 1, 0.86, 0.22, 1 }, borderWidth = 2 },
		},
	},
}

local function interpolate(value, params)
	if type(value) ~= "string" or type(params) ~= "table" then
		return value
	end

	return (value:gsub("%%{([%w_]+)}", function(name)
		local replacement = params[name]
		if replacement == nil then
			return "%{" .. name .. "}"
		end
		return tostring(replacement)
	end))
end

local function translate(key, params, opts)
	translationCalls = translationCalls + 1
	local tableForLocale = translations[locale] or translations.en
	local pluralKey = key
	if params and params.count then
		pluralKey = key .. (params.count == 1 and ".one" or ".other")
	end

	local value = tableForLocale[pluralKey] or translations.en[pluralKey]
	if value == nil and opts and opts.fallback then
		return opts.fallback
	end

	return interpolate(value, params)
end

local function setup()
	ui.setTheme(theme)
	ui.i18n.configure({
		translate = translate,
		setLocale = function(nextLocale)
			locale = nextLocale
		end,
		getLocale = function()
			return locale
		end,
	})
end

local function teardown()
	ui.i18n.configure({})
	locale = "en"
	selectedTab = 1
	selectedCommand = "scan"
	messageCount = 3
	filter = ""
	renderCount = 0
	renderTick = 0
	liveBuilds = 0
	memoBuilds = 0
	translationCalls = 0
end

local function metric(key, value, color)
	return ui.column({ gap = 4, flex = 1 }, {
		ui.meter({
			value = value,
			min = 0,
			max = 100,
			height = 14,
			width = "100%",
			shape = { kind = "skew", skew = 8 },
			fillStyle = { background = color },
			trackStyle = { background = { 0, 0, 0, 0.35 } },
			labelKey = key,
			labelParams = { value = value },
			labelCacheKey = key .. ":" .. tostring(value),
		}),
	})
end

local function memoizedRows()
	memoBuilds = memoBuilds + 1
	return ui.column({ gap = 6 }, {
		ui.textKey("memo.description", {
			wrap = true,
			style = { color = ui.theme.mutedTextColor },
		}),
		ui.textKey("messages", {
			textParams = { count = messageCount },
			textCacheKey = "messages:" .. tostring(messageCount),
		}),
		ui.textKey("missing.example", { textFallback = "Fallback text for a missing key" }),
	})
end

local function liveRows()
	liveBuilds = liveBuilds + 1
	return ui.column({ gap = 6 }, {
		ui.textKey("live.description", {
			wrap = true,
			style = { color = ui.theme.mutedTextColor },
		}),
		ui.textKey("messages", {
			textParams = { count = messageCount },
		}),
		ui.textKey("missing.example", { textFallback = "Fallback text for a missing key" }),
	})
end

local function localeButton(id, key)
	return ui.button({
		labelKey = key,
		width = 96,
		active = locale == id,
		onClick = function()
			ui.i18n.setLocale(id)
		end,
	})
end

local function commandButton(command)
	return ui.button({
		labelKey = "commands." .. command,
		width = "100%",
		active = selectedCommand == command,
		variant = command == "cancel" and "danger" or nil,
		onClick = function()
			selectedCommand = command
		end,
	})
end

local function commandDeck()
	return ui.panel({ titleKey = "commands.title", gap = 8, width = "100%" }, {
		commandButton("scan"),
		commandButton("launch"),
		commandButton("guard"),
		commandButton("recall"),
		commandButton("cancel"),
	})
end

local function statusPanel(compact)
	local commandLabel = ui.t("commands." .. selectedCommand)
	local statusChildren = {
		ui.tabs({ active = selectedTab, onChange = function(index) selectedTab = index end }, {
			{ labelKey = "tabs.overview", content = nil },
			{ labelKey = "tabs.messages", content = nil },
		}),
	}
	local tabContent = selectedTab == 1
		and ui.column({ gap = 10 }, {
			ui.textKey("status.ready"),
			ui.textKey("status.zone", {
				textParams = { zone = "A-17" },
				textCacheKey = "zone:a17",
				style = { color = ui.theme.mutedTextColor },
			}),
			compact and ui.column({ gap = 8 }, {
				metric("stats.power", 76, { 0.1, 0.84, 1, 1 }),
				metric("stats.shield", 58, { 0.38, 0.95, 0.5, 1 }),
				metric("stats.sync", 91, { 1, 0.86, 0.22, 1 }),
			}) or ui.row({ gap = 10 }, {
				metric("stats.power", 76, { 0.1, 0.84, 1, 1 }),
				metric("stats.shield", 58, { 0.38, 0.95, 0.5, 1 }),
				metric("stats.sync", 91, { 1, 0.86, 0.22, 1 }),
			}),
			ui.textKey("command.selected", {
				textParams = { command = commandLabel },
				textCacheKey = "command:" .. selectedCommand .. ":" .. tostring(ui.i18n.version()),
				style = { color = { 1, 0.86, 0.22, 1 } },
			}),
		})
		or ui.column({ gap = 10 }, {
			ui.textKey("messages", {
				textParams = { count = messageCount },
				textCacheKey = "messages-tab:" .. tostring(messageCount),
			}),
			ui.row({ gap = 8 }, {
				ui.button({ label = "-", width = 40, onClick = function() messageCount = math.max(0, messageCount - 1) end }),
				ui.button({ label = "+", width = 40, onClick = function() messageCount = messageCount + 1 end }),
			}),
		})

	statusChildren[1] = ui.tabs({ active = selectedTab, onChange = function(index) selectedTab = index end }, {
		{ labelKey = "tabs.overview", content = tabContent },
		{ labelKey = "tabs.messages", content = tabContent },
	})
	if not compact then
		statusChildren[#statusChildren + 1] = ui.textKey("status.alert", {
			textParams = { value = 34 },
			textCacheKey = "alert:34",
			style = { color = ui.theme.mutedTextColor },
		})
	end

	return ui.panel({ titleKey = "status.title", gap = 12, width = "100%" }, statusChildren)
end

local function comparisonPanel(compact)
	local comparisonLiveRows = liveRows()
	local comparisonMemoRows = ui.memo(memoizedRows, { ui.i18n.version(), messageCount })
	local savedBuilds = math.max(0, liveBuilds - memoBuilds)
	local function counterCard(labelKey, value, accent)
		return ui.box({
			display = "column",
			gap = 2,
			padding = 8,
			flex = 1,
			style = {
				background = { 0.02, 0.04, 0.065, 1 },
				borderColor = accent,
				borderWidth = 1,
			},
		}, {
			ui.textKey(labelKey, {
				style = { color = ui.theme.mutedTextColor },
			}),
			ui.text(tostring(value), {
				style = { fontSize = 22, color = accent },
			}),
		})
	end
	local renderCounters = {
		counterCard("compare.renders_label", renderCount, { 0.1, 0.84, 1, 1 }),
		counterCard("compare.tick_label", renderTick, { 1, 0.86, 0.22, 1 }),
		counterCard("compare.translation_calls_label", translationCalls, { 0.38, 0.95, 0.5, 1 }),
	}
	local buildCounters = {
		counterCard("compare.live_builds_label", liveBuilds, { 1, 0.36, 0.28, 1 }),
		counterCard("compare.memo_builds_label", memoBuilds, { 0.38, 0.95, 0.5, 1 }),
		counterCard("compare.saved_builds_label", savedBuilds, { 1, 0.86, 0.22, 1 }),
	}
	local feeds = {
		ui.panel({ titleKey = "live.title", flex = 1, gap = 8 }, {
			ui.textKey("compare.live_builds", {
				textParams = { count = liveBuilds },
			}),
			comparisonLiveRows,
		}),
		ui.panel({ titleKey = "memo.title", flex = 1, gap = 8 }, {
			ui.textKey("compare.memo_builds", {
				textParams = { count = memoBuilds },
				textCacheKey = "memo-builds:" .. tostring(memoBuilds),
			}),
			comparisonMemoRows,
		}),
	}

	return ui.panel({ titleKey = "compare.title", gap = 10, width = "100%" }, {
		ui.row({ gap = 8 }, {
			ui.button({
				labelKey = "compare.rerender",
				width = compact and 126 or 132,
				onClick = function()
					renderTick = renderTick + 1
				end,
			}),
			ui.button({
				labelKey = "compare.reset",
				width = compact and 82 or 92,
				onClick = function()
					renderCount = 0
					renderTick = 0
					liveBuilds = 0
					memoBuilds = 0
					translationCalls = 0
				end,
			}),
		}),
		compact and ui.column({ gap = 8 }, renderCounters) or ui.row({ gap = 8, align = "stretch" }, renderCounters),
		compact and ui.column({ gap = 8 }, buildCounters) or ui.row({ gap = 8, align = "stretch" }, buildCounters),
		compact and ui.column({ gap = 10 }, feeds) or ui.row({ gap = 12, align = "stretch" }, feeds),
	})
end

local function App()
	renderCount = renderCount + 1
	local viewport = ui.viewport()
	local compact = ui.below("md")
	local medium = ui.below("lg")
	local padding = compact and 12 or 18
	local contentWidth = math.max(320, viewport.width - padding * 2)
	local commandWidth = compact and contentWidth or 190
	local mainWidth = compact and contentWidth or math.max(360, contentWidth - commandWidth - 16)

	local header = ui.row({ gap = 10, align = "center" }, {
		ui.column({ gap = 3, flex = 1 }, {
			ui.textKey("app.title", { style = { fontSize = compact and 18 or 22, color = { 1, 1, 1, 1 } } }),
			ui.textKey("app.subtitle", {
				wrap = true,
				style = { color = ui.theme.mutedTextColor },
			}),
		}),
		localeButton("en", "locale.en"),
		localeButton("pseudo", "locale.pseudo"),
	})

	local controls = ui.row({ gap = 10, align = "center" }, {
		ui.input({
			value = filter,
			onChange = function(nextValue)
				filter = nextValue
			end,
			placeholderKey = "input.filter",
			flex = 1,
		}),
		ui.text("v" .. tostring(ui.i18n.version()), {
			style = { color = ui.theme.mutedTextColor },
		}),
	})

	local mainPanels = ui.column({ gap = 12, width = mainWidth }, {
		statusPanel(compact),
		comparisonPanel(compact or medium),
	})

	local body = compact and ui.column({ gap = 12, width = "100%" }, {
		commandDeck(),
		mainPanels,
	}) or ui.row({ gap = 16, align = "start" }, {
		ui.column({ gap = 12, width = commandWidth }, {
			commandDeck(),
		}),
		mainPanels,
	})

	return ui.scrollView({ width = "100%", height = "100%" }, {
		ui.column({
			width = viewport.width,
			minHeight = viewport.height,
			padding = padding,
			gap = 12,
			style = { background = ui.theme.backgroundColor },
		}, {
			header,
			controls,
			body,
		}),
	})
end

return {
	id = "i18n",
	label = "I18n",
	setup = setup,
	teardown = teardown,
	window = {
		width = 880,
		height = 600,
		minWidth = 420,
		minHeight = 440,
		title = "I18n - glyph.lua",
		resizable = true,
		breakpoints = { md = 720, lg = 980 },
	},
	component = function()
		return App()
	end,
}
