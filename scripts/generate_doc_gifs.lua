package.path = "./?.lua;./?/init.lua;scripts/?.lua;scripts/?/init.lua;" .. package.path

local Manifest = require("doc_gifs.manifest")
local Markdown = require("doc_gifs.markdown")

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

local function readFile(path)
  local file = assert(io.open(path, "rb"))
  local content = file:read("*a")
  file:close()
  return content
end

local function writeFile(path, content)
  local file = assert(io.open(path, "wb"))
  file:write(content)
  file:close()
end

local function filesMatch(left, right)
  if not fileExists(left) or not fileExists(right) then
    return false
  end

  return readFile(left) == readFile(right)
end

local function replaceFile(source, destination)
  local ok, err = os.rename(source, destination)
  if ok then
    return
  end

  if fileExists(destination) then
    os.remove(destination)
    ok, err = os.rename(source, destination)
    if ok then
      return
    end
  end

  error("could not replace " .. destination .. " with " .. source .. " (" .. tostring(err) .. ")", 2)
end

local function run(command)
  print(command)
  local ok, reason, code = os.execute(command)
  if ok == true or ok == 0 then
    return true
  end

  error("command failed (" .. tostring(reason or code or ok) .. "): " .. command, 2)
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

local function findFfmpeg()
  local env = os.getenv("FFMPEG_BIN")
  if env and env ~= "" then
    return env
  end

  local path = commandPath("ffmpeg")
  if path then
    return path
  end

  error("could not find ffmpeg. Set FFMPEG_BIN=/path/to/ffmpeg.", 2)
end

local function mkdir(path)
  run("mkdir -p " .. shellQuote(path))
end

local function parseArgs(argv)
  local opts = {
    feature = os.getenv("FEATURE"),
    width = tonumber(os.getenv("WIDTH")) or 960,
    height = tonumber(os.getenv("HEIGHT")) or 540,
    fps = tonumber(os.getenv("FPS")) or 18,
    tmpRoot = os.getenv("DOC_GIF_TMP") or "/tmp/glyph-doc-gifs",
    outputDir = os.getenv("DOC_GIF_OUTPUT") or "docs/assets/feature-gifs",
    keepFrames = os.getenv("KEEP_FRAMES") == "1",
  }

  local index = 1
  while index <= #argv do
    local argValue = argv[index]
    if argValue == "--feature" then
      opts.feature = argv[index + 1]
      index = index + 1
    elseif argValue == "--width" then
      opts.width = tonumber(argv[index + 1]) or opts.width
      index = index + 1
    elseif argValue == "--height" then
      opts.height = tonumber(argv[index + 1]) or opts.height
      index = index + 1
    elseif argValue == "--fps" then
      opts.fps = tonumber(argv[index + 1]) or opts.fps
      index = index + 1
    elseif argValue == "--tmp" then
      opts.tmpRoot = argv[index + 1] or opts.tmpRoot
      index = index + 1
    elseif argValue == "--output" then
      opts.outputDir = argv[index + 1] or opts.outputDir
      index = index + 1
    elseif argValue == "--keep-frames" then
      opts.keepFrames = true
    end
    index = index + 1
  end

  return opts
end

local function framePath(frameDir, index)
  return string.format("%s/%04d.png", frameDir, index)
end

local function cleanFrames(frameDir, count)
  os.remove(frameDir .. "/palette.png")
  for index = 1, count do
    os.remove(framePath(frameDir, index))
  end
end

local function cleanupFrames(frameDir, count)
  cleanFrames(frameDir, count)
  os.remove(frameDir)
end

local function updateFeatureDocs(target)
  for _, docPath in ipairs(target.docs) do
    local content = readFile(docPath)
    local updated = Markdown.updateFeatureDoc(content, target, docPath)
    if updated ~= content then
      writeFile(docPath, updated)
      print("updated " .. docPath)
    end
  end
end

local function updateGallery(targets)
  local docPath = "docs/examples.md"
  local content = readFile(docPath)
  local updated = Markdown.updateGalleryDoc(content, targets, docPath)
  if updated ~= content then
    writeFile(docPath, updated)
    print("updated " .. docPath)
  end
end

local function docGifEnv(target, frameDir, totalFrames, width, height, fps)
  local values = {
    GLYPH_DOC_GIF_TARGET = target.id,
    GLYPH_DOC_GIF_FRAMES = frameDir,
    GLYPH_DOC_GIF_TOTAL = tostring(totalFrames),
    GLYPH_DOC_GIF_WIDTH = tostring(width),
    GLYPH_DOC_GIF_HEIGHT = tostring(height),
    GLYPH_DOC_GIF_FPS = tostring(fps),
  }
  local defaultKeys = {
    "GLYPH_DOC_GIF_TARGET",
    "GLYPH_DOC_GIF_FRAMES",
    "GLYPH_DOC_GIF_TOTAL",
    "GLYPH_DOC_GIF_WIDTH",
    "GLYPH_DOC_GIF_HEIGHT",
    "GLYPH_DOC_GIF_FPS",
  }
  local keys = {}

  for _, key in ipairs(defaultKeys) do
    keys[#keys + 1] = key
  end

  for key, value in pairs(target.env or {}) do
    values[key] = tostring(value)
    local isDefault = false
    for _, defaultKey in ipairs(defaultKeys) do
      if key == defaultKey then
        isDefault = true
        break
      end
    end
    if not isDefault then
      keys[#keys + 1] = key
    end
  end

  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = key .. "=" .. shellQuote(values[key])
  end
  return table.concat(parts, " ")
end

local function loveCaptureCommand(target, frameDir, totalFrames, width, height, fps, tools)
  if target.exampleApp then
    return table.concat({
      docGifEnv(target, frameDir, totalFrames, width, height, fps),
      shellQuote(tools.love),
      shellQuote(target.exampleApp),
    }, " ")
  end

  return table.concat({
    shellQuote(tools.love),
    shellQuote("scripts/doc_gifs/capture_app"),
    "--target",
    shellQuote(target.id),
    "--frames",
    shellQuote(frameDir),
    "--width",
    tostring(width),
    "--height",
    tostring(height),
    "--fps",
    tostring(fps),
  }, " ")
end

local function captureTarget(target, opts, tools)
  local fps = target.fps or opts.fps
  local width = target.width or opts.width
  local height = target.height or opts.height
  local totalFrames = math.max(1, math.floor((target.duration or 2.6) * fps + 0.5))
  local frameDir = opts.tmpRoot .. "/" .. target.id
  local outputPath = opts.outputDir .. "/" .. target.id .. ".gif"
  local tempOutputPath = opts.outputDir .. "/." .. target.id .. ".tmp.gif"
  local palettePath = frameDir .. "/palette.png"
  local patternPath = frameDir .. "/%04d.png"

  mkdir(frameDir)
  cleanFrames(frameDir, math.max(totalFrames + 12, 720))
  os.remove(tempOutputPath)

  run(loveCaptureCommand(target, frameDir, totalFrames, width, height, fps, tools))

  if not fileExists(framePath(frameDir, 1)) or not fileExists(framePath(frameDir, totalFrames)) then
    error("capture did not produce expected frames for " .. target.id, 2)
  end

  mkdir(opts.outputDir)
  run(table.concat({
    shellQuote(tools.ffmpeg),
    "-y -v error -bitexact -framerate",
    tostring(fps),
    "-start_number 1 -i",
    shellQuote(patternPath),
    "-vf palettegen=stats_mode=diff",
    "-map_metadata -1",
    shellQuote(palettePath),
  }, " "))

  run(table.concat({
    shellQuote(tools.ffmpeg),
    "-y -v error -bitexact -framerate",
    tostring(fps),
    "-start_number 1 -i",
    shellQuote(patternPath),
    "-i",
    shellQuote(palettePath),
    "-filter_complex",
    shellQuote("[0:v][1:v]paletteuse=dither=bayer:bayer_scale=2"),
    "-loop 0",
    "-map_metadata -1",
    "-f gif",
    shellQuote(tempOutputPath),
  }, " "))

  if not fileExists(tempOutputPath) then
    error("ffmpeg did not produce " .. tempOutputPath, 2)
  end

  local changed = not filesMatch(tempOutputPath, outputPath)
  if changed then
    replaceFile(tempOutputPath, outputPath)
    print("generated " .. outputPath)
  else
    os.remove(tempOutputPath)
    print("unchanged " .. outputPath)
  end

  if not opts.keepFrames then
    cleanupFrames(frameDir, math.max(totalFrames + 12, 720))
  end
end

local function selectedTargets(opts, targets)
  if not opts.feature or opts.feature == "" then
    return targets
  end

  local target = Manifest.find(opts.feature)
  if not target then
    error("unknown doc GIF feature: " .. tostring(opts.feature), 2)
  end

  return { target }
end

local function main(argv)
  local opts = parseArgs(argv or {})
  local targets = Manifest.targets()
  Markdown.validateTargets(targets)

  local tools = {
    love = findLove(),
    ffmpeg = findFfmpeg(),
  }

  mkdir(opts.tmpRoot)
  mkdir(opts.outputDir)

  local requested = selectedTargets(opts, targets)
  for _, target in ipairs(requested) do
    captureTarget(target, opts, tools)
    updateFeatureDocs(target)
  end

  updateGallery(targets)
end

main(arg or {})
