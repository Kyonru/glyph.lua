.PHONY: docs test animations basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles themes viewport

EXAMPLES := animations basic dashboard hud-menu hud-primitives modal navigate performance scene settings styles themes viewport

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
