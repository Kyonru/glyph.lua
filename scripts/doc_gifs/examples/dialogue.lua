return function(env)
	return env.target({
		id = "dialogue",
		title = "Dialogue Adapter",
		docs = { "docs/dialogue.md" },
		width = 960,
		height = 540,
		fps = 18,
		duration = 6.0,
		exampleApp = "examples/dialogue",
		env = {
			GLYPH_DIALOGUE_DOC_GIF = "1",
		},
		alt = "Animated GIF showing the Glyph dialogue adapter: typewriter text with inline color, wave, shake, and jiggle effects, character portraits, and a choice menu.",
	})
end
