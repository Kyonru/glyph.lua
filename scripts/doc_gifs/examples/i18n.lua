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
	})
end
