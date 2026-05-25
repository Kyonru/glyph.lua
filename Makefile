.PHONY: docs test accessibility animations audio-cues basic dashboard hud-menu hud-primitives i18n juice modal navigate performance scene settings styles themes viewport

EXAMPLES := accessibility animations audio-cues basic dashboard hud-menu hud-primitives i18n juice modal navigate performance scene settings styles themes viewport

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
