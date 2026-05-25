.PHONY: docs test animations basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles

EXAMPLES := animations basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
