local SpriteSheet = {}

local backend = {
  anim8 = nil,
}

local unpack = table.unpack or _G.unpack

local Sheet = {}
Sheet.__index = Sheet

local function assertPositiveInteger(value, name)
  if type(value) ~= "number" then
    error(name .. " must be a number", 3)
  end
  if value < 1 or value ~= math.floor(value) then
    error(name .. " must be a positive integer", 3)
  end
end

local function imageDimension(image, method, explicit, name)
  if explicit ~= nil then
    assertPositiveInteger(explicit, name)
    return explicit
  end

  if image and type(image[method]) == "function" then
    local ok, value = pcall(image[method], image)
    if ok and type(value) == "number" then
      assertPositiveInteger(value, name)
      return value
    end
  end

  error(name .. " is required when the source image cannot report its size", 3)
end

local function graphics()
  local loveModule = _G.love
  return loveModule and loveModule.graphics or nil
end

local function newQuad(x, y, width, height, imageWidth, imageHeight)
  local g = graphics()
  if not g or type(g.newQuad) ~= "function" then
    error("love.graphics.newQuad is required to create sprite sheet quads", 3)
  end
  return g.newQuad(x, y, width, height, imageWidth, imageHeight)
end

local function resolveAnim8(opts)
  return (opts and opts.anim8) or backend.anim8
end

local function frameCount(size, offset, frameSize, border)
  return math.floor(math.max(0, size - offset) / (frameSize + border))
end

---@param opts? GlyphSpriteSheetBackendConfig
---@return nil
function SpriteSheet.configure(opts)
  backend.anim8 = opts and opts.anim8 or nil
end

---@return nil
function SpriteSheet.clear()
  backend.anim8 = nil
end

---@param image any
---@param opts GlyphSpriteSheetProps
---@return GlyphSpriteSheet
function SpriteSheet.new(image, opts)
  opts = opts or {}
  assertPositiveInteger(opts.frameWidth, "frameWidth")
  assertPositiveInteger(opts.frameHeight, "frameHeight")

  local imageWidth = imageDimension(image, "getWidth", opts.imageWidth, "imageWidth")
  local imageHeight = imageDimension(image, "getHeight", opts.imageHeight, "imageHeight")
  local left = opts.left or 0
  local top = opts.top or 0
  local border = opts.border or 0
  if type(left) ~= "number" or left < 0 then
    error("left must be a non-negative number", 2)
  end
  if type(top) ~= "number" or top < 0 then
    error("top must be a non-negative number", 2)
  end
  if type(border) ~= "number" or border < 0 then
    error("border must be a non-negative number", 2)
  end

  local sheet = {
    image = image,
    frameWidth = opts.frameWidth,
    frameHeight = opts.frameHeight,
    imageWidth = imageWidth,
    imageHeight = imageHeight,
    left = left,
    top = top,
    border = border,
    columns = frameCount(imageWidth, left, opts.frameWidth, border),
    rows = frameCount(imageHeight, top, opts.frameHeight, border),
    anim8 = resolveAnim8(opts),
    _quads = {},
    _grid = nil,
  }

  if sheet.columns < 1 or sheet.rows < 1 then
    error("sprite sheet image is too small for the configured frame size", 2)
  end

  return setmetatable(sheet, Sheet)
end

---@param column number
---@param row number
---@return any
function Sheet:quadAt(column, row)
  assertPositiveInteger(column, "column")
  assertPositiveInteger(row, "row")
  if column > self.columns or row > self.rows then
    error(("sprite frame out of range: column=%d row=%d"):format(column, row), 2)
  end

  local key = column .. ":" .. row
  if not self._quads[key] then
    self._quads[key] = newQuad(
      self.left + (column - 1) * self.frameWidth + column * self.border,
      self.top + (row - 1) * self.frameHeight + row * self.border,
      self.frameWidth,
      self.frameHeight,
      self.imageWidth,
      self.imageHeight
    )
  end
  return self._quads[key]
end

---@param index number
---@return any
function Sheet:quad(index)
  assertPositiveInteger(index, "index")
  local column = ((index - 1) % self.columns) + 1
  local row = math.floor((index - 1) / self.columns) + 1
  return self:quadAt(column, row)
end

local function requireAnim8(sheet)
  local anim8 = sheet.anim8
  if not anim8 then
    error("anim8 is required for sprite sheet frame ranges and animations", 3)
  end
  if type(anim8.newGrid) ~= "function" or type(anim8.newAnimation) ~= "function" then
    error("anim8 must provide newGrid and newAnimation", 3)
  end
  return anim8
end

function Sheet:grid()
  if not self._grid then
    local anim8 = requireAnim8(self)
    self._grid = anim8.newGrid(
      self.frameWidth,
      self.frameHeight,
      self.imageWidth,
      self.imageHeight,
      self.left,
      self.top,
      self.border
    )
  end
  return self._grid
end

---@return any[]
function Sheet:frames(...)
  local grid = self:grid()
  return grid(...)
end

---@param frameArgs any[]
---@param durations number|table
---@param onLoop? function
---@return any
function Sheet:animation(frameArgs, durations, onLoop)
  local anim8 = requireAnim8(self)
  if type(frameArgs) ~= "table" then
    error("frameArgs must be a table of anim8 grid arguments", 2)
  end
  return anim8.newAnimation(self:frames(unpack(frameArgs)), durations, onLoop)
end

---@param animation any
---@return any
function Sheet:currentQuad(animation)
  if type(animation) ~= "table" then
    error("animation must be an anim8 animation", 2)
  end
  if type(animation.getFrameInfo) == "function" then
    local frame = animation:getFrameInfo(0, 0)
    if frame then
      return frame
    end
  end
  if animation.frames and animation.position then
    return animation.frames[animation.position]
  end
  error("animation does not expose a current frame", 2)
end

return SpriteSheet
