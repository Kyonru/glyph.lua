.PHONY: docs docs-gifs test examples-tour tour accessibility animations audio-cues basic dashboard dialogue hud-menu hud-primitives i18n inventory juice menori modal navigate path-feedback performance scene styles themes typography viewport

EXAMPLES := accessibility animations audio-cues basic dashboard dialogue hud-menu hud-primitives i18n inventory juice menori modal navigate path-feedback performance scene styles themes typography viewport
TOUR_EXAMPLES := accessibility animations audio-cues basic dashboard dialogue hud-menu hud-primitives i18n inventory juice menori modal navigate path-feedback performance scene themes typography viewport
LOVE_BIN ?= $(shell command -v love 2>/dev/null || if [ -x /Applications/love.app/Contents/MacOS/love ]; then echo /Applications/love.app/Contents/MacOS/love; else echo love; fi)

docs:
	zensical serve

docs-gifs:
	lua scripts/generate_doc_gifs.lua

test:
	busted

examples-tour:
	@for example in $(TOUR_EXAMPLES); do \
		echo "==> $$example (press Enter in the Love window for next)"; \
		GLYPH_EXAMPLE_NEXT_ON_ENTER=1 "$(LOVE_BIN)" examples/$$example || exit $$?; \
	done

tour: examples-tour

$(EXAMPLES):
	"$(LOVE_BIN)" examples/$@
