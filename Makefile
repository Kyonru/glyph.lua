.PHONY: docs test animations audio-cues basic dashboard hud-menu hud-primitives i18n modal navigate performance scene settings styles themes viewport

EXAMPLES := animations audio-cues basic dashboard hud-menu hud-primitives i18n modal navigate performance scene settings styles themes viewport

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
