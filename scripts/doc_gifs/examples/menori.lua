return function(env)
	return env.target({
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
	})
end
