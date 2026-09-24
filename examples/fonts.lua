local ExampleFonts = {}

local dotGothic16 = "dev/assets/fonts/DotGothic16/DotGothic16-Regular.ttf"
local googleSans = "dev/assets/fonts/Google_Sans/GoogleSans-Regular.ttf"
local inconsolata = "dev/assets/fonts/Inconsolata/Inconsolata-Regular.ttf"
local notoSansArabic = "dev/assets/fonts/Noto_Sans_Arabic/NotoSansArabic-Regular.ttf"
local notoSansArmenian = "dev/assets/fonts/Noto_Sans_Armenian/NotoSansArmenian-Regular.ttf"
local notoSansGeorgian = "dev/assets/fonts/Noto_Sans_Georgian/NotoSansGeorgian-Regular.ttf"
local notoSansHebrew = "dev/assets/fonts/Noto_Sans_Hebrew/NotoSansHebrew-Regular.ttf"
local notoSansMahajani = "dev/assets/fonts/Noto_Sans_Mahajani/NotoSansMahajani-Regular.ttf"
local notoSerifKr = "dev/assets/fonts/Noto_Serif_KR/NotoSerifKR-Regular.ttf"

local fontFiles = {
	body = googleSans,
	title = googleSans,
	subheader = googleSans,
	description = googleSans,
	mono = inconsolata,
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
local sourceCache = {}
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

local function filterFor(id)
	local smooth = id == "body" or id == "title" or id == "subheader" or id == "description" or id == "mono"
	return smooth and "linear" or "nearest"
end

local function loadFontSource(loveModule, id)
	local path = fontFiles[id]
	if not path then
		return nil
	end
	if sourceCache[path] then
		return sourceCache[path]
	end

	local data = readFile(path, loveModule)
	local filesystem = loveModule and loveModule.filesystem
	if data and filesystem and type(filesystem.newFileData) == "function" then
		local ok, source = pcall(filesystem.newFileData, data, path)
		if ok and source then
			sourceCache[path] = source
			return source
		end
	end

	return nil
end

local function loadFont(graphics, loveModule, id, size)
	if not graphics or type(graphics.newFont) ~= "function" then
		return nil
	end

	local path = fontFiles[id]
	local filter = filterFor(id)
	local key = tostring(path or id) .. ":" .. tostring(size) .. ":" .. filter
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
		font:setFilter(filter, filter)
	end

	if not font then
		return nil
	end

	if loadedDevFont then
		cache[key] = font
	end
	return font
end

function ExampleFonts.font(loveModule, id, size)
	loveModule = loveModule or _G.love
	local graphics = loveModule and loveModule.graphics
	return loadFont(graphics, loveModule, id, size or 14)
end

function ExampleFonts.specs(loveModule)
	loveModule = loveModule or _G.love
	local specs = {}
	for role, id in pairs({
		body = "body",
		title = "title",
		subheader = "subheader",
		description = "description",
		mono = "mono",
		monoDisplay = "mono",
		japanese = "japanese",
		arabic = "arabic",
		armenian = "armenian",
		georgian = "georgian",
		hebrew = "hebrew",
		mahajani = "mahajani",
		thai = "thai",
		korean = "korean",
		amharic = "amharic",
	}) do
		local source = loadFontSource(loveModule, id)
		specs[role] = {
			source = source,
			filter = filterFor(id),
		}
	end
	return specs
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
		mono = loadFont(graphics, loveModule, "mono", sizes.mono or 13),
		monoDisplay = loadFont(graphics, loveModule, "mono", sizes.monoDisplay or 32),
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
	local fonts = ExampleFonts.specs(opts.love or _G.love)
	local typography = base.typography or {}
	typography.text = mergeInto({ font = "body" }, copy(typography.text or {}))
	typography.paragraph = mergeInto({ font = "body" }, copy(typography.paragraph or {}))
	typography.caption = mergeInto({ font = "body" }, copy(typography.caption or {}))
	typography.input = mergeInto({ font = "body" }, copy(typography.input or {}))
	typography.button = mergeInto({ font = "body" }, copy(typography.button or {}))
	typography.code = mergeInto({ font = "mono" }, copy(typography.code or {}))
	typography.h1 = mergeInto({ font = "title", fontSize = 22, lineHeight = 34, color = colors.title }, copy(typography.h1 or {}))
	typography.h2 = mergeInto({ font = "subheader", fontSize = 18, lineHeight = 24, color = colors.subheader }, copy(typography.h2 or {}))
	typography.h3 = mergeInto({ font = "subheader", fontSize = 16, lineHeight = 22, color = colors.subheader }, copy(typography.h3 or {}))
	typography.description = mergeInto({ font = "description" }, copy(typography.description or {}))
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
		mono = fonts.mono,
		monoDisplay = fonts.monoDisplay,
	}
	for _, id in ipairs(fallbackFontIds) do
		themeFonts[id] = fonts[id]
	end
	base.fonts = mergeInto(themeFonts, copy(base.fonts or {}))
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
