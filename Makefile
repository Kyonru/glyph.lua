.PHONY: docs docs-gifs docs-tour doc-tour test examples-tour tour accessibility animations audio-cues basic dashboard dialogue hud-menu i18n inventory juice menori modal navigate path-feedback performance scene styles themes typography viewport

EXAMPLES := accessibility animations audio-cues basic dashboard dialogue hud-menu i18n inventory juice menori modal navigate path-feedback performance scene styles themes typography viewport
TOUR_EXAMPLES := accessibility animations audio-cues basic dashboard dialogue hud-menu i18n inventory juice menori modal navigate path-feedback performance scene themes typography viewport
LOVE_BIN ?= $(shell command -v love 2>/dev/null || if [ -x /Applications/love.app/Contents/MacOS/love ]; then echo /Applications/love.app/Contents/MacOS/love; else echo love; fi)

docs:
	zensical serve

docs-gifs:
	lua scripts/generate_doc_gifs.lua

docs-tour:
	lua scripts/doc_gifs/tour.lua

doc-tour: docs-tour

test:
	busted

examples-tour:
	@for example in $(TOUR_EXAMPLES); do \
		echo "==> $$example (press Esc in the Love window for next)"; \
		GLYPH_EXAMPLE_NEXT_ON_ESCAPE=1 "$(LOVE_BIN)" examples/$$example || exit $$?; \
	done

tour: examples-tour

$(EXAMPLES):
	"$(LOVE_BIN)" examples/$@
