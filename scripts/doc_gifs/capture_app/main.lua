local repoRoot = love.filesystem and love.filesystem.getWorkingDirectory and love.filesystem.getWorkingDirectory() or "."

package.path = table.concat({
  repoRoot .. "/?.lua",
  repoRoot .. "/?/init.lua",
  repoRoot .. "/scripts/?.lua",
  repoRoot .. "/scripts/?/init.lua",
  repoRoot .. "/scripts/?/?.lua",
  "../../../?.lua",
  "../../../?/init.lua",
  "../../../scripts/?.lua",
  "../../../scripts/?/init.lua",
  "../../../scripts/?/?.lua",
  "?.lua",
  "?/init.lua",
}, ";") .. ";" .. package.path

local ui = require("glyph")
local Manifest = require("doc_gifs.manifest")

local opts = {
  target = nil,
  frameDir = nil,
  width = 960,
  height = 540,
  fps = 18,
}

local target = nil
local ctx = nil
local frame = 0
local totalFrames = 1
local pendingCapture = false
local firedActions = {}

local function parseArgs(argv)
  local index = 1
  while index <= #argv do
    local value = argv[index]
    if value == "--target" then
      opts.target = argv[index + 1]
      index = index + 1
    elseif value == "--frames" then
      opts.frameDir = argv[index + 1]
      index = index + 1
    elseif value == "--width" then
      opts.width = tonumber(argv[index + 1]) or opts.width
      index = index + 1
    elseif value == "--height" then
      opts.height = tonumber(argv[index + 1]) or opts.height
      index = index + 1
    elseif value == "--fps" then
      opts.fps = tonumber(argv[index + 1]) or opts.fps
      index = index + 1
    end
    index = index + 1
  end
end

local function framePath(index)
  return string.format("%s/%04d.png", opts.frameDir, index)
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

local function runActions(time)
  for index, action in ipairs(target.actions or {}) do
    if not firedActions[index] and time >= (action.at or 0) then
      firedActions[index] = true
      if type(action.run) == "function" then
        action.run(ctx)
      end
    end
  end
end

function love.load(argv)
  parseArgs(argv or arg or {})

  if not opts.target or opts.target == "" then
    error("missing --target")
  end
  if not opts.frameDir or opts.frameDir == "" then
    error("missing --frames")
  end

  target = assert(Manifest.find(opts.target), "unknown target: " .. tostring(opts.target))
  opts.fps = target.fps or opts.fps
  opts.width = target.width or opts.width
  opts.height = target.height or opts.height
  totalFrames = math.max(1, math.floor((target.duration or 2.6) * opts.fps + 0.5))

  love.window.setMode(opts.width, opts.height, {
    resizable = false,
    vsync = 0,
    highdpi = false,
  })

  ui.setLove(love)
  ui.configureWindow({
    width = opts.width,
    height = opts.height,
    resizable = false,
    title = "glyph doc GIF: " .. target.id,
    breakpoints = { sm = 560, md = 760, lg = 960 },
  })
  ui.resize(opts.width, opts.height)
  ui.setTheme({
    backgroundColor = { 0.035, 0.043, 0.058, 1 },
    surfaceColor = { 0.075, 0.092, 0.118, 0.96 },
    surfaceHoverColor = { 0.12, 0.15, 0.19, 1 },
    surfacePressedColor = { 0.05, 0.065, 0.085, 1 },
    borderColor = { 1, 1, 1, 0.16 },
    textColor = { 0.93, 0.96, 0.98, 1 },
    mutedTextColor = { 0.58, 0.66, 0.73, 1 },
    accentColor = { 0.1, 0.78, 0.68, 1 },
  })

  ctx = {
    width = opts.width,
    height = opts.height,
    fps = opts.fps,
    duration = target.duration or 2.6,
    time = 0,
    love = love,
    events = {},
    images = {},
  }

  if type(target.setup) == "function" then
    target.setup(ctx)
  end
end

function love.update()
  if not target or frame >= totalFrames then
    return
  end

  local fixedDt = 1 / opts.fps
  ctx.time = frame * fixedDt
  runActions(ctx.time)

  if type(target.update) == "function" then
    target.update(ctx, ctx.time, fixedDt)
  end

  ui.update(fixedDt)
end

function love.draw()
  if not target or not ctx then
    return
  end
  if frame >= totalFrames then
    quit(0)
    return
  end

  if type(target.beforeDraw) == "function" then
    target.beforeDraw(ctx)
  else
    love.graphics.clear(0.035, 0.043, 0.058, 1)
  end

  if target.usesScene then
    ui.render()
  else
    ui.render(function()
      return target.component(ctx)
    end)
  end

  if pendingCapture then
    return
  end

  pendingCapture = true
  local nextFrame = frame + 1
  love.graphics.captureScreenshot(function(imageData)
    writeImageData(imageData, framePath(nextFrame))
    frame = nextFrame
    pendingCapture = false
    if frame >= totalFrames then
      quit(0)
    end
  end)
end
