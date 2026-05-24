.PHONY: docs test basic dashboard hud-menu modal performance scene settings styles

EXAMPLES := basic dashboard hud-menu modal performance scene settings styles

docs:
	zensical serve

test:
	busted

$(EXAMPLES):
	love examples/$@
