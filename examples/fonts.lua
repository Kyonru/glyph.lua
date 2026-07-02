local ExampleFonts = {}

local acme = "dev/assets/fonts/Acme/Acme-Regular.ttf"
local dotGothic16 = "dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf"
local googleSans = "dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf"
local inconsolata = "dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf"
local notoSansArabic = "dev/assets/fonts/Noto_Sans_Arabic/NotoSansArabic-Regular.ttf"
local notoSansArmenian = "dev/assets/fonts/Noto_Sans_Armenian/NotoSansArmenian-Regular.ttf"
local notoSansGeorgian = "dev/assets/fonts/Noto_Sans_Georgian/NotoSansGeorgian-Regular.ttf"
local notoSansHebrew = "dev/assets/fonts/Noto_Sans_Hebrew/NotoSansHebrew-Regular.ttf"
local notoSansMahajani = "dev/assets/fonts/Noto_Sans_Mahajani/NotoSansMahajani-Regular.ttf"
local notoSerifKr = "dev/assets/fonts/Noto_Serif_KR/NotoSerifKR-Regular.ttf"
local sekuya = "dev/assets/fonts/Sekuya/Sekuya-Regular.ttf"

local fontFiles = {
	body = inconsolata,
	title = sekuya,
	subheader = sekuya,
	description = acme,
	japanese = dotGothic16,
	arabic = notoSansArabic,
	armenian = notoSansArmenian,
	georgian = notoSansGeorgian,
	hebrew = notoSansHebrew,
	mahajani = notoSansMahajani,
	thai = googleSans,
	korean = notoSerifKr,
	amharic = googleSans,
}

local fallbackFontIds = {
	"japanese",
	"arabic",
	"armenian",
	"georgian",
	"hebrew",
	"mahajani",
	"thai",
	"korean",
	"amharic",
}

local cache = {}
local helperSource = debug and debug.getinfo and debug.getinfo(1, "S").source or nil
local helperDir = helperSource and helperSource:match("^@(.+)/[^/]+$") or nil
local repoRoot = helperDir and helperDir:match("^(.*)/examples$") or nil

local function copy(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end

local function mergeInto(target, source)
	if type(source) ~= "table" then
		return target
	end

	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" and value[1] == nil then
			mergeInto(target[key], value)
		else
			target[key] = copy(value)
		end
	end
	return target
end

local function capTypographySize(style, maxFontSize, maxLineHeight)
	if type(style.fontSize) ~= "number" or style.fontSize > maxFontSize then
		style.fontSize = maxFontSize
	end
	if type(style.lineHeight) ~= "number" or style.lineHeight > maxLineHeight then
		style.lineHeight = maxLineHeight
	end
	return style
end

local function addCandidate(candidates, seen, path)
	if not path or path == "" or seen[path] then
		return
	end
	seen[path] = true
	candidates[#candidates + 1] = path
end

local function addRootCandidates(candidates, seen, root, path)
	if not root or root == "" then
		return
	end
	addCandidate(candidates, seen, root .. "/" .. path)
	addCandidate(candidates, seen, root .. "/../" .. path)
	addCandidate(candidates, seen, root .. "/../../" .. path)
end

local function readFile(path, loveModule)
	local candidates = {}
	local seen = {}
	addCandidate(candidates, seen, path)
	addCandidate(candidates, seen, "../" .. path)
	addCandidate(candidates, seen, "../../" .. path)
	addRootCandidates(candidates, seen, repoRoot, path)

	local filesystem = loveModule and loveModule.filesystem
	if filesystem then
		local getters = {
			filesystem.getWorkingDirectory,
			filesystem.getSource,
			filesystem.getSourceBaseDirectory,
		}
		for _, getter in ipairs(getters) do
			if type(getter) == "function" then
				local ok, root = pcall(getter)
				if ok then
					addRootCandidates(candidates, seen, root, path)
				end
			end
		end
	end

	for _, candidate in ipairs(candidates) do
		local file = io.open(candidate, "rb")
		if file then
			local data = file:read("*a")
			file:close()
			return data
		end
	end

	return nil
end

local function loadFont(graphics, loveModule, id, size)
	if not graphics or type(graphics.newFont) ~= "function" then
		return nil
	end

	local path = fontFiles[id]
	local key = tostring(path or id) .. ":" .. tostring(size)
	if cache[key] ~= nil then
		return cache[key] or nil
	end

	local font = nil
	local loadedDevFont = false
	local data = path and readFile(path, loveModule)
	if data and loveModule and loveModule.filesystem and loveModule.filesystem.newFileData then
		local ok, fileData = pcall(loveModule.filesystem.newFileData, data, path)
		if ok and fileData then
			ok, font = pcall(graphics.newFont, fileData, size)
			loadedDevFont = ok and font ~= nil
		end
	end

	if not font then
		local ok
		ok, font = pcall(graphics.newFont, size)
		if not ok then
			font = nil
		end
	end

	if font and font.setFilter then
		font:setFilter("nearest", "nearest")
	end

	if not font then
		return nil
	end

	if loadedDevFont then
		cache[key] = font
	end
	return font
end

function ExampleFonts.load(loveModule, sizes)
	loveModule = loveModule or _G.love
	local graphics = loveModule and loveModule.graphics
	sizes = sizes or {}

	local fonts = {
		body = loadFont(graphics, loveModule, "body", sizes.body or 14),
		title = loadFont(graphics, loveModule, "title", sizes.title or 22),
		subheader = loadFont(graphics, loveModule, "subheader", sizes.subheader or 16),
		description = loadFont(graphics, loveModule, "description", sizes.description or sizes.body or 14),
		japanese = loadFont(graphics, loveModule, "japanese", sizes.japanese or sizes.body or 14),
	}
	for _, id in ipairs(fallbackFontIds) do
		if not fonts[id] then
			fonts[id] = loadFont(graphics, loveModule, id, sizes[id] or sizes.body or 14)
		end
	end
	return fonts
end

function ExampleFonts.theme(base, opts)
	base = copy(base or {})
	opts = opts or {}
	local colors = opts.colors or {}
	local fonts = ExampleFonts.load(opts.love or _G.love, opts.sizes)
	local typography = base.typography or {}
	typography.text = mergeInto(copy(typography.text or {}), { font = "body" })
	typography.paragraph = mergeInto(copy(typography.paragraph or {}), { font = "body" })
	typography.caption = mergeInto(copy(typography.caption or {}), { font = "body" })
	typography.input = mergeInto(copy(typography.input or {}), { font = "body" })
	typography.button = mergeInto(copy(typography.button or {}), { font = "body" })
	typography.h1 = capTypographySize(mergeInto(copy(typography.h1 or {}), { font = "title", color = colors.title }), 22, 34)
	typography.h2 = capTypographySize(mergeInto(copy(typography.h2 or {}), { font = "subheader", color = colors.subheader }), 18, 24)
	typography.h3 = capTypographySize(mergeInto(copy(typography.h3 or {}), { font = "subheader", color = colors.subheader }), 16, 22)
	typography.description = mergeInto(copy(typography.description or {}), { font = "description" })
	for _, id in ipairs(fallbackFontIds) do
		typography[id] = mergeInto({ font = id }, typography[id])
	end

	local themeFonts = {
		body = fonts.body,
		heading = fonts.subheader,
		display = fonts.title,
		title = fonts.title,
		subheader = fonts.subheader,
		description = fonts.description,
	}
	for _, id in ipairs(fallbackFontIds) do
		themeFonts[id] = fonts[id]
	end
	base.fonts = mergeInto(copy(base.fonts or {}), themeFonts)
	base.fontFallbacks = base.fontFallbacks or copy(fallbackFontIds)

	base.typography = typography

	return base
end

function ExampleFonts.apply(ui, base, opts)
	ui.setTheme(ExampleFonts.theme(base, opts))
end

function ExampleFonts.install(ui, opts)
	if not ui or ui._glyphExampleFontsInstalled then
		return
	end

	local rawSetTheme = ui.setTheme
	ui._glyphExampleFontsInstalled = true
	ui._glyphExampleFontsSetTheme = rawSetTheme
	ui.setTheme = function(nextTheme)
		return rawSetTheme(ExampleFonts.theme(nextTheme or {}, opts))
	end
	ui.setTheme({})
end

return ExampleFonts
