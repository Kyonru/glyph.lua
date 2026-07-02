package.path = "./?.lua;./?/init.lua;examples/?.lua;" .. package.path

local ExampleFonts = require("examples.fonts")

local function fakeLove(opts)
	opts = opts or {}
	local love = {}
	love.filesystem = opts.filesystem ~= false and {
		newFileData = function(data, path)
			return { data = data, path = path }
		end,
		getWorkingDirectory = function()
			return opts.workingDirectory or "."
		end,
		getSource = function()
			return opts.source or "."
		end,
		getSourceBaseDirectory = function()
			return opts.sourceBaseDirectory or "."
		end,
	} or nil
	love.graphics = {
		newFont = function(source, size)
			if type(source) == "table" then
				return {
					source = source.path,
					size = size,
					dataLength = #(source.data or ""),
					setFilter = function(self, min, mag)
						self.min = min
						self.mag = mag
					end,
				}
			end

			return {
				source = "default",
				size = size or source,
				setFilter = function(self, min, mag)
					self.min = min
					self.mag = mag
				end,
			}
		end,
	}
	return love
end

describe("example fonts", function()
	it("loads the configured font for each example role", function()
		local fonts = ExampleFonts.load(fakeLove(), { body = 13, title = 31, subheader = 23, description = 17, japanese = 37 })

		assert.are.equal("dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf", fonts.body.source)
		assert.are.equal("dev/assets/fonts/Sekuya/Sekuya-Regular.ttf", fonts.title.source)
		assert.are.equal("dev/assets/fonts/Sekuya/Sekuya-Regular.ttf", fonts.subheader.source)
		assert.are.equal("dev/assets/fonts/Acme/Acme-Regular.ttf", fonts.description.source)
		assert.are.equal("dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf", fonts.japanese.source)
		assert.is_true(fonts.japanese.dataLength > 1000)
		assert.are.equal("nearest", fonts.japanese.min)
		assert.are.equal("nearest", fonts.japanese.mag)
	end)

	it("maps example typography to role-specific fonts", function()
		local theme = ExampleFonts.theme({
			typography = {
				caption = { fontSize = 11, lineHeight = 16 },
			},
		}, { love = fakeLove() })

		assert.are.equal("body", theme.typography.text.font)
		assert.are.equal("body", theme.typography.caption.font)
		assert.are.equal("title", theme.typography.h1.font)
		assert.are.equal("subheader", theme.typography.h2.font)
		assert.are.equal("description", theme.typography.description.font)
		assert.are.equal("dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf", theme.fonts.body.source)
		assert.are.equal("dev/assets/fonts/Sekuya/Sekuya-Regular.ttf", theme.fonts.title.source)
		assert.are.equal("dev/assets/fonts/Acme/Acme-Regular.ttf", theme.fonts.description.source)
		assert.are.equal("dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf", theme.fonts.japanese.source)
	end)

	it("does not cache a default fallback as the dev font", function()
		local missing = ExampleFonts.load(fakeLove({ filesystem = false }), { japanese = 41 })
		local loaded = ExampleFonts.load(fakeLove(), { japanese = 41 })

		assert.are.equal("default", missing.japanese.source)
		assert.are.equal("dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf", loaded.japanese.source)
	end)
end)
