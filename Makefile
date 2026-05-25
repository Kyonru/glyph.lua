.PHONY: docs test basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles

EXAMPLES := basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
