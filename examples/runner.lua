local ui = require("glyph")
local ExampleFonts = require("fonts")

local Runner = {}

local DESCRIPTIONS = {
	accessibility = "Semantic labels, live-region announcements, focus events, and an adapter log for screen-reader style integrations.",
	animations = "Visual-only enter, exit, movement, resize, and meter animation powered by Glyph's Flux adapter.",
	["audio-cues"] = "Button and interaction audio metadata emitted as app-owned cue events.",
	basic = "Core Glyph primitives, layout, state, tabs, and custom draw in a compact starter screen.",
	dashboard = "A dense debugger/admin surface with scanning layouts, charts, filters, and operational panels.",
	dialogue = "A Love-Dialogue bridge that can render the running conversation through Glyph primitives.",
	["hud-menu"] = "A game-shaped HUD menu with custom drawing, animated selection, and controller-friendly structure.",
	["hud-primitives"] = "Meters, images, shapes, clipping, stencil masks, and dynamic HUD panels.",
	i18n = "Backend-agnostic translation, locale switching, cache keys, and semantic text resolution.",
	inventory = "Grid helpers, drag/drop lifecycles, keyboard carry state, sprite sheets, and tooltip-style details.",
	juice = "Triggerable feedback sequences for animation, audio metadata, particles, and app-owned game feel.",
	menori = "Optional Menori scene integration with screen-space HUD and interactive world-space billboard UI.",
	modal = "Scene-backed modals with input blocking, stacked dialogs, and custom transition styling.",
	navigate = "Spatial navigation, nav groups, trapped scopes, and keyboard/gamepad activation flows.",
	["path-feedback"] = "Vector path reveal, morphing, pulse rings, and app-owned feedback targets.",
	performance = "Large-list rendering patterns with memo/static helpers and bounded per-frame work.",
	scene = "Scene stacks, overlays, pause layers, transitions, and input routing between layers.",
	styles = "Theme variants, state styles, shader hooks, and visual styling precedence.",
	themes = "Theme tokens, density presets, variants, and stateful component styling across a complex UI.",
	typography = "Font registries, typography presets, text scaling, rich tags, and multilingual fallback behavior.",
	viewport = "Fixed virtual viewport adapters, input conversion, scaling modes, and scroll behavior.",
}

local function call(example, name, ...)
	local fn = example and example[name]
	if type(fn) == "function" then
		return fn(...)
	end
	return nil
end

local function exampleDescription(example)
	if example.description ~= nil then
		return example.description
	end
	return DESCRIPTIONS[example.id]
end

local function exampleTitle(example)
	return example.title or example.label or example.id or "Example"
end

local function wrapComponent(example, mode)
	if not example or type(example.component) ~= "function" then
		return nil
	end

	local content = example.component(mode)
	if example.chrome == false or example.usesScene then
		return content
	end

	local headerChildren = {
		ui.h1(exampleTitle(example)),
	}
	local description = exampleDescription(example)
	if description and description ~= "" then
		headerChildren[#headerChildren + 1] = ui.p(description, {
			textStyle = "description",
			width = "100%",
			wrap = true,
			style = { color = ui.theme.mutedTextColor },
		})
	end

	return ui.column({ width = "100%", height = "100%", padding = 24, gap = 16 }, {
		ui.column({ width = "100%", gap = 6 }, headerChildren),
		ui.stack({ width = "100%", grow = 1 }, {
			content,
		}),
	})
end

local function captureOptions(example)
	local frameDir = os.getenv("GLYPH_DOC_GIF_FRAMES")
	if not frameDir or frameDir == "" then
		return nil
	end

	local window = example.window or {}
	return {
		frameDir = frameDir,
		total = math.max(1, tonumber(os.getenv("GLYPH_DOC_GIF_TOTAL")) or 1),
		fps = math.max(1, tonumber(os.getenv("GLYPH_DOC_GIF_FPS")) or 18),
		width = tonumber(os.getenv("GLYPH_DOC_GIF_WIDTH")) or window.width or 960,
		height = tonumber(os.getenv("GLYPH_DOC_GIF_HEIGHT")) or window.height or 540,
		frame = 0,
		pending = false,
	}
end

local function captureWindow(window, capture)
	if not capture then
		return window
	end

	local opts = {}
	for key, value in pairs(window or {}) do
		opts[key] = value
	end
	opts.width = capture.width
	opts.height = capture.height
	opts.resizable = false
	opts.minWidth = nil
	opts.minHeight = nil
	opts.highdpi = false
	opts.vsync = 0
	return opts
end

local function captureFramePath(capture, index)
	return string.format("%s/%04d.png", capture.frameDir, index)
end

local function writeImageData(imageData, path)
	local fileData = imageData:encode("png")
	local file = assert(io.open(path, "wb"))
	file:write(fileData:getString())
	file:close()
end

local function quit(status)
	if love.event and love.event.quit then
		love.event.quit(status or 0)
	end
end

function Runner.run(example)
	local capture = nil

	local function updateExample(dt)
		call(example, "update", dt, "standalone")
		ui.update(dt)
	end

	local function drawExample()
		call(example, "beforeDraw", "standalone")
		if example.usesScene then
			ui.render()
		else
			ui.render(function()
				return wrapComponent(example, "standalone")
			end)
		end
	end

	function love.wheelmoved(dx, dy)
		call(example, "wheelmoved", dx, dy, "standalone")
	end

	function love.keypressed(key)
		call(example, "keypressed", key, "standalone")
	end

	function love.keyreleased(key)
		call(example, "keyreleased", key, "standalone")
	end

	function love.gamepadpressed(joystick, button)
		call(example, "gamepadpressed", joystick, button, "standalone")
	end

	function love.gamepadreleased(joystick, button)
		call(example, "gamepadreleased", joystick, button, "standalone")
	end

	function love.load()
		capture = captureOptions(example)
		ui.load({
			window = captureWindow(example.window, capture),
			install = example.install,
		})
		ExampleFonts.install(ui)
		if capture then
			ui.resize(capture.width, capture.height)
		end
		call(example, "setup", "standalone")
	end

	function love.update(dt)
		if capture then
			return
		end
		updateExample(dt)
	end

	function love.draw()
		if not capture then
			drawExample()
			return
		end

		if capture.frame >= capture.total then
			quit(0)
			return
		end
		if capture.pending then
			return
		end

		updateExample(1 / capture.fps)
		drawExample()

		capture.pending = true
		local nextFrame = capture.frame + 1
		love.graphics.captureScreenshot(function(imageData)
			writeImageData(imageData, captureFramePath(capture, nextFrame))
			capture.frame = nextFrame
			capture.pending = false
			if capture.frame >= capture.total then
				quit(0)
			end
		end)
	end
end

return Runner
