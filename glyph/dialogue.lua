local moduleName = ...
local prefix = moduleName and moduleName:match("^(.*)%.dialogue$") or "glyph"

local Components = require(prefix .. ".components")

local utf8 = require("utf8")

local Dialogue = {}
local Adapter = {}
Adapter.__index = Adapter

-- ---------------------------------------------------------------------------
-- Inline text effects
--
-- Mirrors the math in Love-Dialogue's TextEffects module but stays
-- self-contained so the core adapter never requires the app library's internal
-- modules. Each function accumulates into `tr` ({ dx, dy, color, shearX }).
-- ---------------------------------------------------------------------------

local effectTransforms = {
  color = function(effect, _, _, tr)
    local r, g, b = tostring(effect.content or ""):match("(%x%x)(%x%x)(%x%x)")
    if r then
      tr.color = { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, 1 }
    end
  end,
  wave = function(effect, index, time, tr)
    local intensity = tonumber(effect.content) or 1
    tr.dy = tr.dy + math.sin(time * 5 + index * 0.3) * intensity * 3
  end,
  shake = function(effect, index, time, tr)
    local intensity = tonumber(effect.content) or 1
    local a = time * 32 + index * 1.7
    tr.dx = tr.dx + math.cos(a * 1.3) * intensity * 2
    tr.dy = tr.dy + math.sin(a * 1.7) * intensity * 2
  end,
  jiggle = function(effect, index, time, tr)
    local intensity = tonumber(effect.content) or 1
    tr.dx = tr.dx + math.sin(time * 40 + index) * intensity * 1.5
    tr.dy = tr.dy + math.cos(time * 37 + index * 1.3) * intensity * 1.5
  end,
  italic = function(effect, _, _, tr)
    tr.shearX = (effect.content == "left") and 0.5 or -0.5
  end,
}

local function transformFor(effects, index, time)
  local tr = { dx = 0, dy = 0, color = nil, shearX = 0 }
  if not effects then
    return tr
  end
  for _, effect in ipairs(effects) do
    if index >= (effect.startIndex or 1) and index <= (effect.endIndex or 0) then
      local fn = effectTransforms[effect.type]
      if fn then
        fn(effect, index, time, tr)
      end
    end
  end
  return tr
end

local function utf8Chars(text)
  local chars = {}
  for _, code in utf8.codes(text or "") do
    chars[#chars + 1] = utf8.char(code)
  end
  return chars
end

local function withAlpha(color, opacity)
  return { color[1], color[2], color[3], (color[4] or 1) * (opacity or 1) }
end

-- Word-wrapped, per-glyph effect text. `chars` index is 1-based over the clean
-- (effect-stripped) text, matching Love-Dialogue's effect start/end indices.
local function drawEffectText(love, text, effects, x, y, limit, baseColor, time, opacity)
  local graphics = love.graphics
  local font = graphics.getFont()
  if not font then
    return
  end
  local lineHeight = font:getHeight() * 1.35
  local chars = utf8Chars(text)
  local count = #chars
  local cx, cy = 0, 0
  local i = 1

  graphics.push("all")
  while i <= count do
    local j = i
    local wordWidth = 0
    while j <= count and chars[j] ~= " " do
      wordWidth = wordWidth + font:getWidth(chars[j])
      j = j + 1
    end
    if cx > 0 and cx + wordWidth > limit then
      cx = 0
      cy = cy + lineHeight
    end
    for k = i, j - 1 do
      local tr = transformFor(effects, k, time)
      graphics.setColor(withAlpha(tr.color or baseColor, opacity))
      graphics.print(chars[k], x + cx + tr.dx, y + cy + tr.dy, 0, 1, 1, 0, 0, tr.shearX or 0, 0)
      cx = cx + font:getWidth(chars[k])
    end
    if j <= count and chars[j] == " " then
      cx = cx + font:getWidth(" ")
      i = j + 1
    else
      i = j
    end
  end
  graphics.pop()
end

local function drawCaret(love, x, y, width, height, color, opacity, time)
  if math.floor(time * 2) % 2 ~= 0 then
    return
  end
  local graphics = love.graphics
  graphics.push("all")
  graphics.setColor(withAlpha(color, opacity))
  local size = 6
  local px, py = x + width - size * 2, y + height - size * 2
  graphics.polygon("fill", px, py, px + size * 2, py, px + size, py + size)
  graphics.pop()
end

-- Draws a character portrait (a love Image + optional quad) scaled to `size`,
-- mirrored when flipH and rotated around its center. Mirrors Love-Dialogue's
-- LoveCharacter:drawPortrait, plus optional rotation.
local function drawPortraitImage(love, portrait, x, y, size, opacity, rotation)
  if not portrait or not portrait.texture then
    return
  end
  local graphics = love.graphics
  local sx, sy = size, size
  if portrait.width and portrait.width > 0 then
    sx = size / portrait.width
  end
  if portrait.height and portrait.height > 0 then
    sy = size / portrait.height
  end
  local ox = 0
  if portrait.flipH then
    sx = -sx
    ox = portrait.width or 0
  end
  graphics.push("all")
  graphics.setColor(1, 1, 1, (portrait.alpha or 1) * (opacity or 1))
  if rotation and rotation ~= 0 then
    local cx, cy = x + size / 2, y + size / 2
    graphics.translate(cx, cy)
    graphics.rotate(rotation)
    graphics.translate(-cx, -cy)
  end
  if portrait.quad then
    graphics.draw(portrait.texture, portrait.quad, x, y, 0, sx, sy, ox, 0)
  else
    graphics.draw(portrait.texture, x, y, 0, sx, sy, ox, 0)
  end
  graphics.pop()
end

-- Ease-out-back: overshoots slightly past 1.0 then settles, giving a "pop".
local function easeOutBack(p)
  local c1 = 1.70158
  local c3 = c1 + 1
  return 1 + c3 * (p - 1) ^ 3 + c1 * (p - 1) ^ 2
end

local function mergeInto(base, extra)
  if extra then
    for key, value in pairs(extra) do
      base[key] = value
    end
  end
  return base
end

-- ---------------------------------------------------------------------------
-- Adapter
-- ---------------------------------------------------------------------------

-- Builds the normalized model from a Love-Dialogue instance's `.state`. Used as
-- the injected renderModel() (see augment) and as a direct fallback.
local function buildModel(instance)
  local s = instance and instance.state
  if not s then
    return nil
  end
  local config = instance.config or {}
  local char = s.characters and s.characters[s.currentCharacter]
  local choices = {}
  for i, c in ipairs(s.activeChoices or {}) do
    choices[i] = { text = c.parsedText or c.text, target = c.target, effects = c.effects }
  end

  -- Current portrait (texture + quad) for the active character/expression.
  local portrait = nil
  if config.portraitEnabled ~= false and char and char.expressions then
    local expr = char.expressions[s.currentExpression] or char.expressions.Default
    if expr and expr.texture then
      portrait = {
        texture = expr.texture,
        quad = expr.quad,
        width = expr.w,
        height = expr.h,
        size = config.portraitSize or 100,
        flipH = config.portraitFlipH or false,
        -- character transform: honored by the renderer so app/library tweens
        -- (scale/position/rotation) animate the portrait.
        scale = char.scale or 1,
        rotation = char.rotation or 0,
        offsetX = char.x or 0,
        offsetY = char.y or 0,
        alpha = char.alpha,
      }
    end
  end

  return {
    active = s.isActive,
    status = s.status,
    opacity = s.boxOpacity,
    speaker = { name = s.currentCharacter, color = char and char.nameColor },
    expression = s.currentExpression,
    text = { full = s.fullText, shown = s.displayedText, waiting = s.waitingForInput },
    effects = s.effects,
    portrait = portrait,
    choiceMode = s.choiceMode,
    selectedChoice = s.selectedChoice,
    choices = choices,
  }
end

-- Adds the renderer-agnostic methods to a Love-Dialogue instance at runtime, so
-- the vendored library stays unmodified. Each is only added when missing, so an
-- upstream copy that already provides them keeps its own implementation.
local function augment(instance)
  if not instance or instance.__glyphDialogue then
    return instance
  end
  instance.__glyphDialogue = true

  if type(instance.renderModel) ~= "function" then
    instance.renderModel = function(self)
      return buildModel(self)
    end
  end
  if type(instance.selectChoice) ~= "function" then
    instance.selectChoice = function(self, index)
      local s = self.state
      if not s or not s.choiceMode then
        return s and s.selectedChoice
      end
      local count = #(s.activeChoices or {})
      index = math.max(1, math.min(count, index or 1))
      s.selectedChoice = index
      return index
    end
  end
  if type(instance.isFinished) ~= "function" then
    instance.isFinished = function(self)
      return not (self.state and self.state.isActive)
    end
  end
  -- Renderless-aware draw: when config.renderless is set, the library's own draw
  -- becomes a no-op so an external renderer can own drawing. Wrapping the
  -- instance leaves the shared class method untouched.
  if type(instance.draw) == "function" and not instance.__glyphDrawWrapped then
    instance.__glyphDrawWrapped = true
    local originalDraw = instance.draw
    instance.draw = function(self, ...)
      if self.config and self.config.renderless then
        return
      end
      return originalDraw(self, ...)
    end
  end

  return instance
end

function Adapter:wrap(instance)
  self.instance = augment(instance)
  if instance and self.onSignal then
    instance.onSignal = self.onSignal
  end
  return self
end

function Adapter:play(scriptPath, config)
  assert(self.library, "ui.dialogue.new requires opts.library to use :play()")
  local instance = self.library.play(scriptPath, config)
  -- Set on the built config (the library does not copy unknown config keys) so
  -- the augmented draw suppresses the library's own drawing.
  if instance and instance.config then
    instance.config.renderless = true
  end
  return self:wrap(instance)
end

function Adapter:setOnSignal(fn)
  self.onSignal = fn
  if self.instance then
    self.instance.onSignal = fn
  end
  return self
end

function Adapter:update(dt)
  self.elapsed = self.elapsed + (dt or 0)
  if self.instance then
    self.instance:update(dt)
  end
  self:trackPortrait()
end

-- Detect when the visible portrait (speaker or expression) changes so the pop
-- animation can restart from that moment.
function Adapter:trackPortrait()
  local model = self:model()
  local key = nil
  if model and model.portrait then
    key = (model.speaker and model.speaker.name or "") .. "|" .. tostring(model.expression)
  end
  if key ~= self.portraitKey then
    self.portraitKey = key
    self.portraitChangeAt = key and self.elapsed or nil
  end
end

-- Scale multiplier for the portrait "pop" since the last change. Returns 1 when
-- disabled (opts.portraitPop == false) or once the animation completes. Pass
-- `portraitPop = { duration = ..., from = ... }` to tune it.
function Adapter:portraitPopScale()
  local pop = self.opts.portraitPop
  if pop == false or not self.portraitChangeAt then
    return 1
  end
  local duration = (type(pop) == "table" and pop.duration) or 0.22
  local from = (type(pop) == "table" and pop.from) or 0.8
  local t = self.elapsed - self.portraitChangeAt
  if t >= duration then
    return 1
  end
  return from + (1 - from) * easeOutBack(t / duration)
end

function Adapter:keypressed(key)
  if self.instance then
    self.instance:keypressed(key)
  end
end

function Adapter:select(index)
  if not self.instance then
    return
  end
  local fn = self.instance.selectChoice
  if type(fn) == "function" then
    fn(self.instance, index)
  elseif self.instance.state then
    self.instance.state.selectedChoice = index
  end
end

function Adapter:advance()
  if self.instance then
    self.instance:advance()
  end
end

function Adapter:isActive()
  local model = self:model()
  return model ~= nil and model.active == true
end

function Adapter:isFinished()
  if not self.instance then
    return true
  end
  local fn = self.instance.isFinished
  if type(fn) == "function" then
    return fn(self.instance)
  end
  return not (self.instance.state and self.instance.state.isActive)
end

-- Normalized view of the current line. Wrapped instances always have a
-- renderModel() (injected by augment); otherwise builds it directly from
-- `.state`, so the adapter also works against an unmodified upstream copy.
function Adapter:model()
  local instance = self.instance
  if not instance then
    return nil
  end
  if type(instance.renderModel) == "function" then
    return instance:renderModel()
  end
  return buildModel(instance)
end

-- Returns a Glyph node tree rendering the current dialogue, or nil when there is
-- no active line. Layout/position/style are overridable through `props`.
function Adapter:component(props)
  props = props or {}
  local model = self:model()
  if not model or not model.active then
    return nil
  end

  local opacity = model.opacity or 1
  local theme = self.ui and self.ui.theme or {}
  local textColor = props.textColor or theme.textColor or { 1, 1, 1, 1 }
  local accent = props.accent or theme.accent or { 1, 0.86, 0.4, 1 }
  local font = props.font or self.opts.font

  local boxStyle = mergeInto({
    background = { 0, 0, 0, 0.86 },
    borderColor = { 1, 1, 1, 0.9 },
    borderWidth = 2,
    radius = 8,
  }, props.style)
  boxStyle.opacity = opacity

  local content = {}

  if model.speaker and model.speaker.name and model.speaker.name ~= "" then
    content[#content + 1] = Components.text(model.speaker.name, {
      textStyle = "h2",
      style = { color = model.speaker.color or textColor, opacity = opacity },
    })
  end

  content[#content + 1] = Components.box({
    width = "100%",
    flex = 1,
    interactive = false,
    accessibilityLabel = model.text and model.text.full or nil,
    draw = function(_, x, y, width, height, love)
      if font and love.graphics.setFont then
        love.graphics.setFont(font)
      end
      drawEffectText(love, model.text and model.text.shown or "", model.effects, x, y, width, textColor, self.elapsed, opacity)
      if model.text and model.text.waiting and not model.choiceMode then
        drawCaret(love, x, y, width, height, textColor, opacity, self.elapsed)
      end
    end,
  })

  if model.choiceMode and model.choices then
    local choiceNodes = {}
    for i, choice in ipairs(model.choices) do
      local selected = i == model.selectedChoice
      choiceNodes[#choiceNodes + 1] = Components.button({
        label = choice.text,
        width = "100%",
        focusable = false,
        style = {
          background = selected and { 1, 1, 1, 0.16 } or { 1, 1, 1, 0.04 },
          color = selected and accent or textColor,
          borderColor = selected and accent or { 1, 1, 1, 0.12 },
          borderWidth = 1,
          radius = 6,
          opacity = opacity,
        },
        onClick = function()
          self:select(i)
          self:advance()
        end,
      })
    end
    content[#content + 1] = Components.column({ width = "100%", gap = 4 }, choiceNodes)
  end

  -- Lay the portrait (if any) beside the text; otherwise the content fills.
  local inner
  if model.portrait then
    local pSize = model.portrait.size or 100
    inner = Components.row({ width = "100%", height = "100%", gap = props.gap or 14 }, {
      Components.box({
        width = pSize,
        height = "100%",
        interactive = false,
        accessibilityHidden = true,
        draw = function(_, x, y, _, height, love)
          local p = model.portrait
          -- Honor the character transform (scale) and the built-in pop, scaling
          -- around the portrait's bottom-center so it grows from the floor.
          local scaled = pSize * (p.scale or 1) * self:portraitPopScale()
          local dx = x + (pSize - scaled) / 2 + (p.offsetX or 0)
          local dy = y + height - scaled + (p.offsetY or 0)
          drawPortraitImage(love, p, dx, dy, scaled, opacity, p.rotation)
        end,
      }),
      Components.column({ flex = 1, height = "100%", gap = props.gap or 8 }, content),
    })
  else
    inner = Components.column({ width = "100%", height = "100%", gap = props.gap or 8 }, content)
  end

  local layout = {
    position = "absolute",
    left = props.margin or 24,
    right = props.margin or 24,
    bottom = props.margin or 24,
    height = props.height or 200,
    padding = props.padding or 18,
    style = boxStyle,
  }
  mergeInto(layout, props.layout)
  return Components.column(layout, { inner })
end

---@param rootUi glyph
---@param opts? table
function Dialogue.new(rootUi, opts)
  opts = opts or {}
  local adapter = setmetatable({
    ui = rootUi,
    opts = opts,
    library = opts.library,
    instance = nil,
    onSignal = opts.onSignal,
    elapsed = 0,
    portraitKey = nil,
    portraitChangeAt = nil,
  }, Adapter)
  if opts.instance then
    adapter:wrap(opts.instance)
  end
  return adapter
end

return Dialogue
