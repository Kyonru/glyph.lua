local ui = require("glyph")

local Runner = {}

local function call(example, name, ...)
	local fn = example and example[name]
	if type(fn) == "function" then
		return fn(...)
	end
	return nil
end

function Runner.run(example)
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
		ui.load({
			window = example.window,
		})
		call(example, "setup", "standalone")
	end

	function love.update(dt)
		call(example, "update", dt, "standalone")
		ui.update(dt)
	end

	function love.draw()
		call(example, "beforeDraw", "standalone")
		if example.usesScene then
			ui.render()
		else
			ui.render(function()
				return example.component("standalone")
			end)
		end
	end
end

return Runner
