local ui = require("glyph")

local scale = 1
local locale = "en"
local callSign = "Vega"

local translations = {
	en = {
		briefing = "[font=heading]Signal found[/font][newline]Route [color=#7cffae]Vega[/color] through the relay and keep comms clean.",
		status = "Locale: English",
	},
	es = {
		briefing = "[font=heading]Senal encontrada[/font][newline]Guia a [color=#7cffae]Vega[/color] por el rele y manten limpia la comunicacion.",
		status = "Idioma: Espanol",
	},
}

local function setup()
	local loveModule = _G.love
	local graphics = loveModule and loveModule.graphics
	local fonts = {}

	if graphics and graphics.newFont then
		fonts.body = graphics.newFont(14)
		fonts.heading = graphics.newFont(24)
		fonts.mono = graphics.newFont(13)
	end

	local ok, sysl = pcall(require, "sysl_text")
	if ok then
		ui.richTextBackend.configure({
			sysl = sysl,
			defaults = {
				font = fonts.body,
				color = { 0.9, 0.96, 1, 1 },
				adjust_line_height = 2,
				print_speed = 0.001,
			},
			configure = function(Text)
				if Text.configure and Text.configure.font_table then
					Text.configure.font_table(fonts)
				end
			end,
		})
	end

	ui.i18n.configure({
		locale = locale,
		translate = function(key)
			return translations[locale] and translations[locale][key]
		end,
		setLocale = function(nextLocale)
			locale = nextLocale
		end,
		getLocale = function()
			return locale
		end,
	})

	ui.setTheme({
		textScale = scale,
		fonts = fonts,
		backgroundColor = { 0.035, 0.045, 0.07, 1 },
		surfaceColor = { 0.075, 0.09, 0.13, 0.96 },
		borderColor = { 0.25, 0.34, 0.48, 1 },
		textColor = { 0.9, 0.96, 1, 1 },
		mutedTextColor = { 0.55, 0.66, 0.78, 1 },
		accentColor = { 0.25, 0.72, 1, 1 },
		components = {
			button = {
				radius = 8,
				variants = {
					primary = {
						background = { 0.16, 0.52, 0.82, 1 },
					},
				},
			},
			panel = {
				radius = 10,
			},
		},
		typography = {
			text = { font = "body", fontSize = 14, lineHeight = 20 },
			h1 = { font = "heading", fontSize = 31, lineHeight = 38, color = { 1, 1, 1, 1 } },
			h2 = { font = "heading", fontSize = 22, lineHeight = 29, color = { 0.8, 0.9, 1, 1 } },
			paragraph = { font = "body", fontSize = 14, lineHeight = 22 },
			caption = { font = "body", fontSize = 11, lineHeight = 16, color = { 0.55, 0.66, 0.78, 1 } },
			code = { font = "mono", fontSize = 13, lineHeight = 19, color = { 0.75, 1, 0.82, 1 } },
			button = { font = "body", fontSize = 14, lineHeight = 20 },
			input = { font = "body", fontSize = 14, lineHeight = 20 },
		},
	})
end

local function applyScale(nextScale)
	scale = math.max(0.8, math.min(1.4, nextScale))
	ui.setTheme({ textScale = scale })
end

local function localeButton(id, label)
	return ui.button({
		label = label,
		active = locale == id,
		variant = locale == id and "primary" or nil,
		onClick = function()
			ui.i18n.setLocale(id)
		end,
	})
end

local function scaleControls()
	return ui.row({ gap = 8, width = "100%", align = "center" }, {
		ui.caption("Scale"),
		ui.button({
			label = "-",
			width = 36,
			onClick = function()
				applyScale(scale - 0.05)
			end,
		}),
		ui.text(string.format("%.0f%%", scale * 100), {
			width = 58,
			textAlign = "center",
			textStyle = "code",
		}),
		ui.button({
			label = "+",
			width = 36,
			onClick = function()
				applyScale(scale + 0.05)
			end,
		}),
		ui.box({ grow = 1, height = 1, interactive = false }),
		localeButton("en", "EN"),
		localeButton("es", "ES"),
	})
end

local function styleSamples()
	return ui.panel({ title = "Text Styles", titleTextStyle = "h2", gap = 10, padding = 16, flex = 1 }, {
		ui.h1("Command Typography"),
		ui.h2("Mission Deck"),
		ui.p(
			"Typography presets keep headings, body copy, labels, and captions consistent while still using normal Glyph text nodes.",
			{
				wrap = true,
				width = "100%",
			}
		),
		ui.caption("Caption text uses the same layout path, so it wraps and scales with the theme."),
		ui.text("mono/status/log_0442", { textStyle = "code" }),
	})
end

local function richSamples()
	return ui.panel({ title = "Rich Tags", titleTextStyle = "h2", gap = 12, padding = 16, flex = 1 }, {
		ui.richText("[font=heading]ALERT[/font] [color=#ffcf5a]incoming[/color]", {
			width = "100%",
			height = 52,
			wrap = true,
			textVerticalAlign = "center",
		}),
		ui.richText(
			"[font=mono]tags[/font] are [color=#73e5ff]inline[/color], [font=heading]measured[/font], and [font=mono]opt-in[/font].",
			{
				textStyle = "paragraph",
				wrap = true,
				width = "100%",
			}
		),
		ui.richTextKey("briefing", {
			textStyle = "paragraph",
			wrap = true,
			width = "100%",
		}),
		ui.caption(ui.t("status")),
	})
end

local function componentSamples()
	return ui.panel({ title = "Components", titleTextStyle = "h2", gap = 10, padding = 16, width = "100%" }, {
		ui.p("Buttons, inputs, panel titles, and meter labels resolve through typography too.", {
			wrap = true,
			width = "100%",
		}),
		ui.row({ gap = 8, width = "100%", align = "center" }, {
			ui.button({ label = "Primary", variant = "primary" }),
			ui.button({ label = "Normal" }),
			ui.input({
				value = callSign,
				placeholder = "Call sign",
				flex = 1,
				onChange = function(value)
					callSign = value
				end,
			}),
		}),
		ui.meter({
			value = #callSign,
			max = 12,
			width = "100%",
			height = 18,
			label = "call sign length",
			fillStyle = { background = { 0.25, 0.72, 1, 1 } },
			trackStyle = { background = { 1, 1, 1, 0.08 } },
		}),
	})
end

local function App()
	local viewport = ui.viewport()
	local compact = viewport.width < 760
	local sampleContent = compact
			and ui.column({ gap = 12, width = "100%" }, {
				styleSamples(),
				richSamples(),
			})
		or ui.row({ gap = 12, width = "100%", align = "stretch" }, {
			styleSamples(),
			richSamples(),
		})

	return ui.stack({ width = "100%", height = "100%" }, {
		ui.box({
			position = "absolute",
			inset = 0,
			interactive = false,
			style = { background = ui.theme.backgroundColor },
		}),
		ui.scrollView({ width = "100%", height = "100%", padding = compact and 14 or 24 }, {
			ui.column({ gap = 14, width = "100%" }, {
				ui.row({ gap = 12, width = "100%", align = "center" }, {
					ui.h1("Typography Lab", { flex = 1 }),
					ui.caption("fonts / scale / tags"),
				}),
				scaleControls(),
				sampleContent,
				componentSamples(),
			}),
		}),
	})
end

return {
	id = "typography",
	label = "Typography",
	setup = setup,
	window = {
		width = 900,
		height = 640,
		resizable = true,
		title = "glyph - typography",
	},
	component = function()
		return App()
	end,
}
