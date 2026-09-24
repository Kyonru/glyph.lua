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
		local fonts = ExampleFonts.load(fakeLove(), { body = 13, title = 31, subheader = 23, description = 17, mono = 15, monoDisplay = 33, japanese = 37, arabic = 19 })

		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", fonts.body.source)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", fonts.title.source)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", fonts.subheader.source)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", fonts.description.source)
		assert.are.equal("dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf", fonts.mono.source)
		assert.are.equal("dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf", fonts.monoDisplay.source)
		assert.are.equal("dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf", fonts.japanese.source)
		assert.are.equal("dev/assets/fonts/Noto_Sans_Arabic/NotoSansArabic-Regular.ttf", fonts.arabic.source)
		assert.are.equal("dev/assets/fonts/Noto_Sans_Armenian/NotoSansArmenian-Regular.ttf", fonts.armenian.source)
		assert.are.equal("dev/assets/fonts/Noto_Sans_Georgian/NotoSansGeorgian-Regular.ttf", fonts.georgian.source)
		assert.are.equal("dev/assets/fonts/Noto_Sans_Hebrew/NotoSansHebrew-Regular.ttf", fonts.hebrew.source)
		assert.are.equal("dev/assets/fonts/Noto_Sans_Mahajani/NotoSansMahajani-Regular.ttf", fonts.mahajani.source)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", fonts.thai.source)
		assert.are.equal("dev/assets/fonts/Noto_Serif_KR/NotoSerifKR-Regular.ttf", fonts.korean.source)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", fonts.amharic.source)
		assert.is_true(fonts.japanese.dataLength > 1000)
		assert.are.equal("nearest", fonts.japanese.min)
		assert.are.equal("nearest", fonts.japanese.mag)
		assert.are.equal("linear", fonts.body.min)
		assert.are.equal("linear", fonts.body.mag)
		assert.are.equal("linear", fonts.mono.min)
		assert.are.equal("linear", fonts.mono.mag)
		assert.are.equal(33, fonts.monoDisplay.size)
		assert.are.equal(19, fonts.arabic.size)
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
		assert.are.equal("mono", theme.typography.code.font)
		assert.are.equal("arabic", theme.typography.arabic.font)
		assert.are.equal("korean", theme.typography.korean.font)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", theme.fonts.body.source.path)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", theme.fonts.title.source.path)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", theme.fonts.description.source.path)
		assert.are.equal("dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf", theme.fonts.mono.source.path)
		assert.are.equal("dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf", theme.fonts.japanese.source.path)
		assert.are.equal("dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf", theme.fonts.amharic.source.path)
		assert.are.equal("linear", theme.fonts.body.filter)
		assert.are.equal("linear", theme.fonts.mono.filter)
		assert.is_nil(theme.fonts.body.size)
		assert.are.same({
			"japanese",
			"arabic",
			"armenian",
			"georgian",
			"hebrew",
			"mahajani",
			"thai",
			"korean",
			"amharic",
		}, theme.fontFallbacks)
	end)

	it("fills shared defaults without replacing a later bespoke theme", function()
		local applied = nil
		local sentinelBody = "bespoke-body"
		local fakeUi = {
			setTheme = function(theme)
				applied = theme
			end,
		}

		ExampleFonts.install(fakeUi, { love = fakeLove() })
		fakeUi.setTheme({
			fonts = { body = sentinelBody },
			typography = {
				text = { font = "bespoke" },
				h1 = { font = "bespoke", fontSize = 31, lineHeight = 40 },
			},
		})

		assert.are.same(sentinelBody, applied.fonts.body)
		assert.are.equal("bespoke", applied.typography.text.font)
		assert.are.equal("bespoke", applied.typography.h1.font)
		assert.are.equal(31, applied.typography.h1.fontSize)
		assert.are.equal(40, applied.typography.h1.lineHeight)
		assert.is_not_nil(applied.fonts.mono)
	end)

	it("does not cache a default fallback as the dev font", function()
		local missing = ExampleFonts.load(fakeLove({ filesystem = false }), { japanese = 41 })
		local loaded = ExampleFonts.load(fakeLove(), { japanese = 41 })

		assert.are.equal("default", missing.japanese.source)
		assert.are.equal("dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf", loaded.japanese.source)
	end)
end)
