local ui = require("glyph")

local Runner = {}

local function call(example, name, ...)
	local fn = example and example[name]
	if type(fn) == "function" then
		return fn(...)
	end
	return nil
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
				return example.component("standalone")
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
