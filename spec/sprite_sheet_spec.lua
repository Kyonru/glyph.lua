package.path = "./?.lua;./?/init.lua;" .. package.path

local ui = require("glyph")

local function installLove()
  local quads = {}
  _G.love = {
    graphics = {
      newQuad = function(x, y, width, height, imageWidth, imageHeight)
        local quad = {
          x = x,
          y = y,
          width = width,
          height = height,
          imageWidth = imageWidth,
          imageHeight = imageHeight,
        }
        function quad:getViewport()
          return self.x, self.y, self.width, self.height
        end
        quads[#quads + 1] = quad
        return quad
      end,
    },
  }
  return quads
end

local function image(width, height)
  return {
    getWidth = function()
      return width
    end,
    getHeight = function()
      return height
    end,
  }
end

describe("sprite sheet helper", function()
  local previousLove

  before_each(function()
    previousLove = _G.love
    ui.spriteSheetBackend.clear()
    installLove()
  end)

  after_each(function()
    ui.spriteSheetBackend.clear()
    _G.love = previousLove
  end)

  it("creates cached quads by row-major index", function()
    local sheet = ui.spriteSheet(image(64, 72), {
      frameWidth = 16,
      frameHeight = 24,
    })

    local indexed = sheet:quad(6)
    local addressed = sheet:quadAt(2, 2)

    assert.are.equal(indexed, addressed)
    assert.are.equal(4, sheet.columns)
    assert.are.equal(3, sheet.rows)
    assert.are.same({ 16, 24, 16, 24 }, { indexed:getViewport() })
  end)

  it("maps quadAt through left, top, and border offsets", function()
    local sheet = ui.spriteSheet(image(70, 55), {
      frameWidth = 16,
      frameHeight = 24,
      left = 2,
      top = 3,
      border = 1,
    })

    local quad = sheet:quadAt(3, 2)

    assert.are.same({ 37, 29, 16, 24 }, { quad:getViewport() })
  end)

  it("uses source dimensions or explicit image dimensions", function()
    local natural = ui.spriteSheet(image(64, 48), {
      frameWidth = 16,
      frameHeight = 24,
    })
    local explicit = ui.spriteSheet({}, {
      frameWidth = 8,
      frameHeight = 12,
      imageWidth = 40,
      imageHeight = 36,
    })

    assert.are.equal(64, natural.imageWidth)
    assert.are.equal(48, natural.imageHeight)
    assert.are.equal(5, explicit.columns)
    assert.are.equal(3, explicit.rows)
  end)

  it("rejects invalid frame sizes and out-of-range frames", function()
    assert.has_error(function()
      ui.spriteSheet(image(64, 48), {
        frameWidth = 0,
        frameHeight = 24,
      })
    end)

    assert.has_error(function()
      ui.spriteSheet(image(8, 8), {
        frameWidth = 16,
        frameHeight = 24,
      })
    end)

    local sheet = ui.spriteSheet(image(32, 24), {
      frameWidth = 16,
      frameHeight = 24,
    })
    local ok, err = pcall(function()
      sheet:quadAt(3, 1)
    end)

    assert.is_false(ok)
    assert.is_true(tostring(err):find("sprite frame out of range", 1, true) ~= nil)
  end)

  it("delegates anim8 frame ranges through a configured backend", function()
    local gridArgs
    local frameArgs
    local anim8 = {
      newGrid = function(...)
        gridArgs = { ... }
        return function(...)
          frameArgs = { ... }
          return { "frame-a", "frame-b" }
        end
      end,
      newAnimation = function(frames, durations, onLoop)
        return {
          frames = frames,
          durations = durations,
          onLoop = onLoop,
          position = 2,
        }
      end,
    }

    ui.spriteSheetBackend.configure({ anim8 = anim8 })
    local sheet = ui.spriteSheet(image(64, 48), {
      frameWidth = 16,
      frameHeight = 24,
      left = 1,
      top = 2,
      border = 3,
    })

    local frames = sheet:frames("1-2", 1)
    local animation = sheet:animation({ "1-2", 1 }, 0.12, "loop")

    assert.are.same({ 16, 24, 64, 48, 1, 2, 3 }, gridArgs)
    assert.are.same({ "1-2", 1 }, frameArgs)
    assert.are.same({ "frame-a", "frame-b" }, frames)
    assert.are.equal(0.12, animation.durations)
    assert.are.equal("loop", animation.onLoop)
    assert.are.equal("frame-b", sheet:currentQuad(animation))
  end)

  it("uses per-sheet anim8 before the configured backend", function()
    local used = nil
    local function makeAnim8(name)
      return {
        newGrid = function()
          used = name
          return function()
            return {}
          end
        end,
        newAnimation = function(frames)
          return { frames = frames, position = 1 }
        end,
      }
    end

    ui.spriteSheetBackend.configure({ anim8 = makeAnim8("configured") })
    local sheet = ui.spriteSheet(image(16, 24), {
      frameWidth = 16,
      frameHeight = 24,
      anim8 = makeAnim8("sheet"),
    })

    sheet:frames(1, 1)

    assert.are.equal("sheet", used)
  end)

  it("errors clearly when animation helpers are used without anim8", function()
    local sheet = ui.spriteSheet(image(16, 24), {
      frameWidth = 16,
      frameHeight = 24,
    })
    local ok, err = pcall(function()
      sheet:frames(1, 1)
    end)

    assert.is_false(ok)
    assert.is_true(tostring(err):find("anim8 is required", 1, true) ~= nil)
  end)
end)
