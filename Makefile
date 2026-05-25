.PHONY: docs test animations basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles themes

EXAMPLES := animations basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles themes

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
