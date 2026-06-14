local ui = require("glyph")

-- Faithful port of the upstream Love-Dialogue demo (demo/main.lua):
--   https://github.com/Miisan-png/Love-Dialogue/tree/main/demo
--
-- Love-Dialogue parses the .ld scripts, runs the conversation, and draws the
-- dialogue box, portraits, and choice indicator itself. Glyph only hosts the
-- example: it owns the window/runner and composites the demo's own drawing
-- (a vertical gradient, the dialogue box, and a one-line controls hint) through
-- non-interactive custom-draw nodes. There is intentionally no extra Glyph UI.
--
-- The vendored library lives under vendor/ and the demo assets/scripts under
-- demo/ (a snapshot of the upstream demo folder, minus the unused TTF font).

local okDialogue, LoveDialogue = pcall(require, "LoveDialogue")
local dialogueLoadError = nil
if not okDialogue then
	dialogueLoadError = LoveDialogue
	LoveDialogue = nil
end

local ResourceManager = okDialogue and require("LoveDialogue.ResourceManager") or nil
local PluginManager = okDialogue and require("LoveDialogue.PluginManager") or nil
local DebugPlugin = okDialogue and require("LoveDialogue.plugins.DebugPlugin") or nil

local myDialogue = nil
local adapter = nil -- ui.dialogue adapter wrapping the current instance
local renderMode = "glyph" -- "library" (Love-Dialogue draws) | "glyph" (ui.dialogue draws)
local savedState = nil
local config = nil
local nextScriptPath = nil
local hintFont = nil
local bodyFont = nil
local fancy = false -- "j" toggles a custom box frame + a framed circular bust
local bgColor = { 0.1, 0.1, 0.2, 1 }

local CONTROLS = "Space/Enter (Next)  |  F (Skip)  |  S (Save)  |  L (Load)  |  Esc (Quit)"

local function onSignal(name, args)
	if name == "ChangeBG" then
		local r, g, b = tostring(args):match("(%S+)%s+(%S+)%s+(%S+)")
		if r and g and b then
			bgColor = { tonumber(r), tonumber(g), tonumber(b), 1 }
		end
	elseif name == "LoadScript" then
		nextScriptPath = args
	elseif name == "QuitGame" then
		if love.event then
			love.event.quit()
		end
	elseif name == "PlaySound" then
		local source = love.audio.newSource(args, "static")
		source:play()
	end
end

local function startDialogue(path)
	myDialogue = LoveDialogue.play(path, config)
	myDialogue.onSignal = onSignal
	-- adapter:wrap augments the instance (renderModel/selectChoice/isFinished)
	-- without touching the vendored library.
	if adapter then
		adapter:wrap(myDialogue)
	end
end

-- Switch which renderer draws the dialogue. The same Love-Dialogue instance is
-- shared; only drawing changes (drawDialogue / the adapter component gate on it).
local function toggleRenderer()
	renderMode = (renderMode == "library") and "glyph" or "library"
end

local function toggleFancy()
	fancy = not fancy
end

-- A custom box frame (component({ frame = ... })): a filled panel with a glowing
-- double outline, drawn with the ctx instead of the default 1px border.
local function fancyBoxFrame(ctx, x, y, width, height, love, opacity)
	opacity = opacity or 1
	ctx:color({ 0.03, 0.05, 0.1, 0.92 * opacity })
	ctx:rect("fill", x, y, width, height, 14)
	if love.graphics.setLineWidth then
		love.graphics.setLineWidth(2)
	end
	ctx:color({ 0.45, 0.7, 1, 0.85 * opacity })
	ctx:rect("line", x, y, width, height, 14)
	ctx:color({ 0.45, 0.7, 1, 0.32 * opacity })
	ctx:rect("line", x + 6, y + 6, width - 12, height - 12, 10)
end

-- A ring drawn on top of the circular bust (the stencil masks the image to a
-- circle; this outlines it). Used as a box draw callback.
local function fancyRing(_, x, y, width, height, love, _, ctx)
	if love.graphics.setLineWidth then
		love.graphics.setLineWidth(3)
	end
	ctx:color({ 0.5, 0.78, 1, 0.9 })
	local padding = 0
	ctx:shape("line", { kind = "circle", segments = 48 }, { x = x, y = y + padding, width = width, height = height })
end

-- Vertical gradient background, matching the upstream demo's love.draw.
local function drawBackground(_, x, y, width, height, love)
	love.graphics.push("all")
	for i = 0, height do
		local shade = (i / height) * 0.1
		love.graphics.setColor(bgColor[1] + shade, bgColor[2] + shade, bgColor[3] + shade, 1)
		love.graphics.line(x, y + i, x + width, y + i)
	end
	love.graphics.pop()
end

-- The dialogue box / portraits / indicator, drawn by Love-Dialogue itself.
-- Wrapped in push/pop so its color/font/transform state never leaks into Glyph.
local function drawDialogue(_, _, _, _, _, love)
	if renderMode ~= "library" then
		return
	end
	if not (myDialogue and myDialogue.state.isActive) then
		return
	end
	love.graphics.push("all")
	myDialogue:draw()
	love.graphics.pop()
end

local function drawControls(_, x, y, width, height, love)
	love.graphics.push("all")
	if hintFont then
		love.graphics.setFont(hintFont)
	end
	love.graphics.setColor(1, 1, 1, 0.6)
	local hint = CONTROLS .. "  |  G (Renderer: " .. renderMode .. ")"
	if renderMode == "glyph" then
		hint = hint .. "  |  J (Frame: " .. (fancy and "on" or "off") .. ")"
	end
	love.graphics.print(hint, x + 20, y + height - 30)
	love.graphics.pop()
end

local function Demo()
	local children = {
		ui.box({
			position = "absolute",
			inset = 0,
			interactive = false,
			accessibilityHidden = true,
			draw = drawBackground,
		}),
		ui.box({
			position = "absolute",
			inset = 0,
			interactive = false,
			accessibilityHidden = true,
			zIndex = 10,
			draw = drawDialogue,
		}),
	}
	-- In glyph mode, ui.dialogue renders the box from the shared instance's state.
	if renderMode == "glyph" and adapter then
		if fancy then
			-- Flow composition: a bottom-anchored column with a fixed-size, framed
			-- circular bust ON TOP of the (flow) box. As the box grows it pushes the
			-- column up, lifting the bust — the bust itself never resizes.
			local box = adapter:component({ frame = fancyBoxFrame, portrait = false, flow = true })
			if box then
				local SIZE = 150
				local bust = adapter:portrait({
					size = SIZE,
					width = "100%",
					height = "100%",
					side = "right", -- mirrors the bust to face the text
					stencil = { kind = "circle" }, -- mask the image to a circle
				})
				local cell = {}
				if bust then
					cell[#cell + 1] = bust
				end
				cell[#cell + 1] = ui.box({
					position = "absolute",
					inset = 0,
					interactive = false,
					accessibilityHidden = true,
					draw = fancyRing,
				})
				children[#children + 1] = ui.column({
					position = "absolute",
					left = 30,
					right = 30,
					bottom = 30,
					gap = 16, -- space between the bust and the box (the bust's "margin bottom")
					zIndex = 12,
				}, {
					ui.row({ width = "100%", justify = "end" }, { ui.stack({ width = SIZE, height = SIZE }, cell) }),
					box,
				})
			end
		else
			-- Same full-width box, but the portrait + speaker name render on the
			-- right for Wiisan and on the left for everyone else. Only the content
			-- side changes (model.speaker.name drives it); the box stays put.
			local model = adapter:model()
			local side = (model and model.speaker and model.speaker.name == "Wiisan") and "right" or "left"
			local box = adapter:component({ margin = 30, portrait = side, align = side, layout = { zIndex = 12 } })
			if box then
				children[#children + 1] = box
			end
		end
		-- Full-screen [fade: ...] transitions (the library draws these itself in
		-- library mode); below the controls hint, matching the library demo.
		local fade = adapter:overlay({ zIndex = 19 })
		if fade then
			children[#children + 1] = fade
		end
	end
	children[#children + 1] = ui.box({
		position = "absolute",
		inset = 0,
		interactive = false,
		accessibilityHidden = true,
		zIndex = 20,
		draw = drawControls,
	})
	return ui.stack({ width = "100%", height = "100%" }, children)
end

local function MissingDialogue()
	return ui.column({
		width = "100%",
		height = "100%",
		padding = 30,
		gap = 12,
		justify = "center",
		style = { background = { 0.1, 0.1, 0.2, 1 } },
	}, {
		ui.text("Love-Dialogue demo", { textStyle = "h1", style = { color = { 1, 1, 1, 1 } } }),
		ui.text(
			"The vendored Love-Dialogue copy under examples/dialogue/vendor could not be loaded.",
			{ wrap = true, width = 640, style = { color = { 0.8, 0.8, 0.85, 1 } } }
		),
		ui.text(tostring(dialogueLoadError or ""), {
			wrap = true,
			width = 640,
			textStyle = "caption",
			style = { color = { 1, 0.5, 0.5, 1 } },
		}),
	})
end

return {
	id = "dialogue",
	label = "Dialogue",
	window = {
		width = 1024,
		height = 768,
		resizable = true,
		title = "LoveDialogue Engine Demo",
	},
	setup = function()
		if not LoveDialogue then
			return
		end
		love.graphics.setDefaultFilter("nearest", "nearest")
		hintFont = love.graphics.newFont(14)
		bodyFont = love.graphics.newFont(20)
		adapter = ui.dialogue.new({
			library = LoveDialogue,
			font = bodyFont,
			height = 130, -- base text-area height
			choiceHeight = 30, -- each choice grows the box by ~this much
			maxHeight = 300, -- never taller than this
			portraitAlign = "bottom", -- "bottom" | "top" | "center",
			portraitSize = 150,
		})

		PluginManager:register(DebugPlugin)

		config = {
			boxHeight = 220,
			boxWidth = 1200,
			centerBox = true,
			portraitEnabled = true,
			boxColor = { 0, 0, 0, 1 },
			borderColor = { 1, 1, 1, 1 },
			borderWidth = 4,
			textColor = { 1, 1, 1, 1 },
			nameColor = { 1, 1, 1, 1 },
			typingSpeed = 0.04,
			padding = 20,
			autoLayoutEnabled = true,
			skipKey = "f",
			character_type = 0,
			portraitSize = 140,
			portraitFlipH = true,
			textSpeeds = { slow = 0.08, normal = 0.04, fast = 0.02 },
			initialSpeedSetting = "normal",
			autoAdvance = false,
			autoAdvanceDelay = 2.0,
			useNinePatch = false,
			ninePatchPath = "demo/assets/ui/9patch.png",
			ninePatchScale = 1.5,
			edgeWidth = 12,
			edgeHeight = 12,
			indicatorPath = "demo/assets/ui/indicator.png",
			plugins = { "Debug" },
			pluginData = { Debug = { enabled = false } },
		}

		startDialogue("demo/launcher.ld")
	end,
	update = function(dt)
		if not myDialogue then
			return
		end
		if nextScriptPath then
			myDialogue:destroy()
			startDialogue(nextScriptPath)
			nextScriptPath = nil
			return
		end
		adapter:update(dt)
	end,
	component = function()
		if not LoveDialogue then
			return MissingDialogue()
		end
		return Demo()
	end,
	keypressed = function(key)
		if not myDialogue then
			return
		end
		if key == "escape" then
			if love.event then
				love.event.quit()
			end
			return
		elseif key == "s" then
			savedState = myDialogue:saveState()
			print("Game Saved!", savedState.line)
		elseif key == "l" then
			if savedState then
				print("Loading Save...", savedState.line)
				myDialogue:loadState(savedState)
			end
		elseif key == "g" then
			toggleRenderer()
			return
		elseif key == "j" then
			toggleFancy()
			return
		end
		adapter:keypressed(key)
	end,
}
