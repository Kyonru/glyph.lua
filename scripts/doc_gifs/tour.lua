package.path = "./?.lua;./?/init.lua;scripts/?.lua;scripts/?/init.lua;" .. package.path

local Manifest = require("doc_gifs.manifest")

local function shellQuote(value)
	value = tostring(value)
	return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function fileExists(path)
	local file = io.open(path, "rb")
	if file then
		file:close()
		return true
	end
	return false
end

local function commandPath(name)
	local handle = io.popen("command -v " .. shellQuote(name) .. " 2>/dev/null")
	if not handle then
		return nil
	end
	local result = handle:read("*l")
	handle:close()
	if result and result ~= "" then
		return result
	end
	return nil
end

local function findLove()
	local env = os.getenv("LOVE_BIN")
	if env and env ~= "" then
		return env
	end

	local path = commandPath("love")
	if path then
		return path
	end

	local macPath = "/Applications/love.app/Contents/MacOS/love"
	if fileExists(macPath) then
		return macPath
	end

	error("could not find Love2D. Set LOVE_BIN=/path/to/love.", 2)
end

local function envPrefix(target)
	local parts = {}
	for key, value in pairs(target.env or {}) do
		parts[#parts + 1] = key .. "=" .. shellQuote(value)
	end
	return table.concat(parts, " ")
end

local function run(command)
	local ok, reason, code = os.execute(command)
	if ok == true or ok == 0 then
		return
	end
	error("command failed (" .. tostring(reason or code or ok) .. "): " .. command, 2)
end

local loveBin = findLove()

for _, target in ipairs(Manifest.targets()) do
	print(("==> %s (press Esc in the Love window for next)"):format(target.id))

	if target.exampleApp then
		local prefix = envPrefix(target)
		if prefix ~= "" then
			prefix = prefix .. " "
		end
		run(prefix .. "GLYPH_EXAMPLE_NEXT_ON_ESCAPE=1 " .. shellQuote(loveBin) .. " " .. shellQuote(target.exampleApp))
	else
		run(table.concat({
			shellQuote(loveBin),
			shellQuote("scripts/doc_gifs/capture_app"),
			"--target",
			shellQuote(target.id),
		}, " "))
	end
end
