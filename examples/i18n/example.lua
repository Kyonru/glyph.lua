local ui = require("glyph")

local locale = "en"
local selectedTab = 1
local messageCount = 3
local filter = ""

local translations = {
	en = {
		["app.title"] = "Localization",
		["app.subtitle"] = "Glyph resolves keys; your app owns the translator.",
		["locale.en"] = "English",
		["locale.pseudo"] = "Pseudo",
		["stats.title"] = "Mission Status",
		["stats.ready"] = "Ready for launch",
		["stats.power"] = "Power %{value}%",
		["actions.launch"] = "Launch",
		["actions.cancel"] = "Cancel",
		["input.filter"] = "Filter commands...",
		["tabs.overview"] = "Overview",
		["tabs.messages"] = "Messages",
		["messages.one"] = "1 new message",
		["messages.other"] = "%{count} new messages",
		["memo.title"] = "Memoized translated rows",
	},
	pseudo = {
		["app.title"] = "[loc] Localization",
		["app.subtitle"] = "[loc] Glyph resolves keys; translator stays yours.",
		["locale.en"] = "English",
		["locale.pseudo"] = "Pseudo",
		["stats.title"] = "[loc] Mission Status",
		["stats.ready"] = "[loc] Ready for launch",
		["stats.power"] = "[loc] Power %{value}%",
		["actions.launch"] = "[loc] Launch",
		["actions.cancel"] = "[loc] Cancel",
		["input.filter"] = "[loc] Filter commands...",
		["tabs.overview"] = "[loc] Overview",
		["tabs.messages"] = "[loc] Messages",
		["messages.one"] = "[loc] 1 new message",
		["messages.other"] = "[loc] %{count} new messages",
		["memo.title"] = "[loc] Memoized translated rows",
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
	messageCount = 3
	filter = ""
end

local function memoizedRows()
	return ui.column({ gap = 6 }, {
		ui.textKey("memo.title", { style = { color = ui.theme.mutedTextColor } }),
		ui.textKey("messages", {
			textParams = { count = messageCount },
			textCacheKey = "messages:" .. tostring(messageCount),
		}),
		ui.textKey("missing.example", { textFallback = "Fallback text for a missing key" }),
	})
end

local function localeButton(id, key)
	return ui.button({
		labelKey = key,
		width = 112,
		active = locale == id,
		onClick = function()
			ui.i18n.setLocale(id)
		end,
	})
end

local function App()
	local tabContent = selectedTab == 1
		and ui.column({ gap = 10 }, {
			ui.textKey("stats.ready"),
			ui.meter({
				value = 76,
				min = 0,
				max = 100,
				width = 260,
				height = 16,
				labelKey = "stats.power",
				labelParams = { value = 76 },
				labelCacheKey = "power:76",
			}),
			ui.row({ gap = 8 }, {
				ui.button({ labelKey = "actions.launch", width = 120, variant = "primary", onClick = function() end }),
				ui.button({ labelKey = "actions.cancel", width = 120, variant = "ghost", onClick = function() end }),
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

	return ui.column({ padding = 24, gap = 14, width = "100%", height = "100%" }, {
		ui.row({ gap = 12, align = "center" }, {
			ui.column({ gap = 4, flex = 1 }, {
				ui.textKey("app.title", { style = { fontSize = 22 } }),
				ui.textKey("app.subtitle", {
					wrap = true,
					style = { color = ui.theme.mutedTextColor },
				}),
			}),
			localeButton("en", "locale.en"),
			localeButton("pseudo", "locale.pseudo"),
		}),

		ui.input({
			value = filter,
			onChange = function(nextValue)
				filter = nextValue
			end,
			placeholderKey = "input.filter",
			width = 320,
		}),

		ui.row({ gap = 14, align = "stretch", flex = 1 }, {
			ui.panel({ titleKey = "stats.title", width = 330, gap = 12 }, {
				ui.tabs({ active = selectedTab, onChange = function(index) selectedTab = index end }, {
					{ labelKey = "tabs.overview", content = tabContent },
					{ labelKey = "tabs.messages", content = tabContent },
				}),
			}),
			ui.panel({ title = "Cache", flex = 1 }, {
				ui.memo(memoizedRows, { ui.i18n.version(), messageCount }),
			}),
		}),
	})
end

return {
	id = "i18n",
	label = "I18n",
	setup = setup,
	teardown = teardown,
	window = {
		width = 820,
		height = 520,
		title = "I18n - glyph.lua",
		resizable = true,
	},
	component = function()
		return App()
	end,
}
