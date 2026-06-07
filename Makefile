.PHONY: docs docs-gifs test accessibility animations audio-cues basic dashboard hud-menu hud-primitives i18n inventory juice modal navigate performance scene settings styles themes typography viewport

EXAMPLES := accessibility animations audio-cues basic dashboard hud-menu hud-primitives i18n inventory juice modal navigate performance scene settings styles themes typography viewport

docs:
	zensical serve

docs-gifs:
	lua scripts/generate_doc_gifs.lua

test:
	busted

$(EXAMPLES):
	love examples/$@
