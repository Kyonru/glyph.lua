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

-- Pixel height of `text` wrapped to `limit`, using the same word wrap as
-- drawEffectText, so the box can be sized to fit long lines.
local function wrappedTextHeight(font, text, limit)
  if not font or not limit or limit <= 0 then
    return 0
  end
  local lineHeight = font:getHeight() * 1.35
  local chars = utf8Chars(text)
  local count = #chars
  if count == 0 then
    return lineHeight
  end
  local cx, lines = 0, 1
  local i = 1
  while i <= count do
    local j = i
    local wordWidth = 0
    while j <= count and chars[j] ~= " " do
      wordWidth = wordWidth + font:getWidth(chars[j])
      j = j + 1
    end
    if cx > 0 and cx + wordWidth > limit then
      cx = 0
      lines = lines + 1
    end
    for k = i, j - 1 do
      cx = cx + font:getWidth(chars[k])
    end
    if j <= count and chars[j] == " " then
      cx = cx + font:getWidth(" ")
      i = j + 1
    else
      i = j
    end
  end
  return lines * lineHeight
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
-- mirrored when `flip` and rotated around its center. Mirrors Love-Dialogue's
-- LoveCharacter:drawPortrait, plus optional rotation. `flip` defaults to the
-- portrait's own flipH when nil.
local function drawPortraitImage(love, portrait, x, y, size, opacity, rotation, flip)
  if not portrait or not portrait.texture then
    return
  end
  if flip == nil then
    flip = portrait.flipH
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
  if flip then
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

-- Vertical placement of a `scaled`-tall portrait inside a `boxHeight` slot.
local function portraitYFor(align, y, boxHeight, scaled, offsetY)
  offsetY = offsetY or 0
  if align == "top" then
    return y + offsetY
  elseif align == "center" then
    return y + (boxHeight - scaled) / 2 + offsetY
  end
  return y + boxHeight - scaled + offsetY -- "bottom" (default)
end

-- Resolves the effective horizontal flip. `flip` may be true/false (force),
-- or nil/"auto" (use the portrait's own flipH, inverted when on the right so
-- the character faces the text).
local function resolveFlip(flip, side, base)
  base = base and true or false
  if flip == true then
    return true
  elseif flip == false then
    return false
  end
  if side == "right" then
    return not base
  end
  return base
end

-- Draws a frame at (x, y, w, h). `frame` may be a draw function
-- (ctx, x, y, w, h, love, opacity), a nine-slice table ({ image = img, ... }),
-- or a style table ({ background, borderColor, borderWidth, radius }).
local function drawFrame(ctx, love, frame, x, y, width, height, opacity)
  if not frame then
    return
  end
  opacity = opacity or 1
  if type(frame) == "function" then
    frame(ctx, x, y, width, height, love, opacity)
  elseif frame.image then
    ctx:nineSlice(frame.image, { x = x, y = y, width = width, height = height }, frame.opts or frame)
  else
    if frame.background then
      ctx:color(withAlpha(frame.background, opacity))
      ctx:rect("fill", x, y, width, height, frame.radius)
    end
    if frame.borderColor and (frame.borderWidth or 0) > 0 then
      if love.graphics.setLineWidth then
        love.graphics.setLineWidth(frame.borderWidth)
      end
      ctx:color(withAlpha(frame.borderColor, opacity))
      ctx:rect("line", x, y, width, height, frame.radius)
    end
  end
end

-- Ease-out-back: overshoots slightly past 1.0 then settles, giving a "pop".
local function easeOutBack(p)
  local c1 = 1.70158
  local c3 = c1 + 1
  return 1 + c3 * (p - 1) ^ 3 + c1 * (p - 1) ^ 2
end

-- Frame-rate independent exponential approach toward `target`.
local function approach(current, target, dt, speed)
  local k = 1 - math.exp(-(speed or 12) * (dt or 0))
  return current + (target - current) * k
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

  -- Full-screen fade transition ([fade: ...]). The library updates its alpha in
  -- :update; only the draw lives in :draw, which the adapter replaces.
  local transition = nil
  if s.transition and (s.transition.alpha or 0) > 0 then
    transition = { color = s.transition.color or { 0, 0, 0 }, alpha = s.transition.alpha }
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
    transition = transition,
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
  self:updateHeight(dt)
end

-- Caches the wrapped pixel height of the current line's text so the box can
-- grow to fit long lines. Called from the body draw with the real width/font.
function Adapter:measureBody(font, text, width)
  text = text or ""
  if self._bodyText == text and self._bodyWidth == width and self._bodyFont == font then
    return
  end
  self._bodyText = text
  self._bodyWidth = width
  self._bodyFont = font
  self.bodyTextHeight = wrappedTextHeight(font, text, width)
end

-- Animates the box height: a base height that grows to fit long wrapped text and
-- the choice buttons, and an `open` factor (0..1) that expands the box in when
-- the dialogue appears and collapses it while it fades out.
function Adapter:updateHeight(dt)
  local model = self:model()
  local base = self.opts.height or 160
  -- Grow the base so long, wrapped lines are not clipped (chrome = padding +
  -- speaker name + gaps). Measured by the body draw a frame earlier.
  if self.bodyTextHeight and self.bodyTextHeight > 0 then
    local chrome = 2 * (self.opts.padding or 18) + 44
    base = math.max(base, self.bodyTextHeight + chrome)
  end
  local target = base
  if model and model.choiceMode and model.choices and #model.choices > 0 then
    -- Each choice adds one button row (height + 4px gap) to the base.
    local unit = (self.opts.choiceHeight or 34) + 4
    target = base + #model.choices * unit
  end
  if self.opts.maxHeight then
    target = math.min(target, self.opts.maxHeight)
  end
  local openTarget = (model and model.active and model.status ~= "fading_out") and 1 or 0
  self.boxHeight = approach(self.boxHeight or target, target, dt, 14)
  self.open = approach(self.open or 0, openTarget, dt, 12)
end

-- Current animated box height (content height × open factor), or the fixed
-- height when animateHeight is disabled.
function Adapter:resolvedHeight(props)
  local base = self.opts.height or 160
  if self.opts.animateHeight == false then
    return (props and props.height) or base
  end
  return (self.boxHeight or base) * (self.open or 1)
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

-- Builds a portrait box node (or nil), shared by the inline portrait and the
-- standalone Adapter:portrait. `o` controls size/width/height/side/align/fit/
-- flip/frame/stencil/layout.
local function buildPortraitNode(self, model, o)
  o = o or {}
  local p = model and model.portrait
  if not p then
    return nil
  end
  local pSize = o.size or self.opts.portraitSize or p.size or 100
  local flip = resolveFlip(o.flip, o.side, p.flipH)
  local align = o.align or self.opts.portraitAlign
  local fit = o.fit
  if fit == nil then
    fit = self.opts.portraitFit
  end
  local frame = o.frame
  local stencil = o.stencil
  local opacity = model.opacity or 1

  local boxProps = {
    width = o.width or pSize,
    height = o.height or "100%",
    interactive = false,
    accessibilityHidden = true,
    draw = function(_, x, y, width, height, love, _, ctx)
      if frame then
        drawFrame(ctx, love, frame, x, y, width, height, opacity)
      end
      local function drawImage()
        local scaled = pSize * (p.scale or 1) * self:portraitPopScale()
        if fit then
          scaled = math.min(scaled, height)
        end
        local dx = x + (width - scaled) / 2 + (p.offsetX or 0)
        local dy = portraitYFor(align, y, height, scaled, p.offsetY)
        drawPortraitImage(love, p, dx, dy, scaled, opacity, p.rotation, flip)
      end
      if stencil then
        ctx:stencil(stencil, drawImage, o.stencilOpts)
      else
        drawImage()
      end
    end,
  }
  if o.layout then
    mergeInto(boxProps, o.layout)
  end
  return Components.box(boxProps)
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
      local mfont = font
      if mfont and love.graphics.setFont then
        love.graphics.setFont(mfont)
      end
      mfont = mfont or (love.graphics.getFont and love.graphics.getFont())
      -- Measure the full line at the real width so the box can size to fit it.
      self:measureBody(mfont, model.text and model.text.full or "", width)
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
        height = self.opts.choiceHeight or 34,
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

  -- Place the portrait (left/right) beside the text, or drop it when
  -- props.portrait == false; otherwise the content fills the box.
  local side = props.portrait
  if side == nil then
    side = self.opts.portraitSide or "left"
  end
  local inner
  if side ~= false and model.portrait then
    local portrait = buildPortraitNode(self, model, {
      side = side,
      frame = self.opts.portraitFrame,
      stencil = self.opts.portraitStencil,
    })
    local contentColumn = Components.column({ flex = 1, height = "100%", gap = props.gap or 8 }, content)
    local rowChildren = (side == "right") and { contentColumn, portrait } or { portrait, contentColumn }
    inner = Components.row({ width = "100%", height = "100%", gap = props.gap or 14 }, rowChildren)
  else
    inner = Components.column({ width = "100%", height = "100%", gap = props.gap or 8 }, content)
  end

  -- A custom box frame (props.frame / opts.frame) is drawn behind the content
  -- and replaces the default border; otherwise the default styled border shows.
  local frame = props.frame or self.opts.frame
  local boxStyle = mergeInto({}, props.style)
  local boxDraw = nil
  if frame then
    boxDraw = function(_, x, y, width, height, love, _, ctx)
      drawFrame(ctx, love, frame, x, y, width, height, opacity)
    end
  else
    boxStyle = mergeInto({
      background = { 0, 0, 0, 0.86 },
      borderColor = { 1, 1, 1, 0.9 },
      borderWidth = 2,
      radius = 8,
    }, props.style)
  end
  boxStyle.opacity = opacity

  local layout = {
    height = self:resolvedHeight(props),
    padding = props.padding or 18,
    display = "column",
    style = boxStyle,
    draw = boxDraw,
  }
  if props.flow then
    -- A flow node (not absolutely positioned), so it can be composed in a
    -- column/row — e.g. with a fixed-size portrait above that the growing box
    -- pushes up.
    layout.width = props.width or "100%"
  else
    layout.position = "absolute"
    layout.left = props.margin or 24
    layout.right = props.margin or 24
    layout.bottom = props.margin or 24
  end
  mergeInto(layout, props.layout)
  return Components.box(layout, { inner })
end

-- Full-screen fade overlay for the library's [fade: ...] transitions, or nil
-- when no fade is active. Place it on top of your scene (it covers the whole
-- screen). `props.zIndex` sets its stacking order.
function Adapter:overlay(props)
  props = props or {}
  local model = self:model()
  local t = model and model.transition
  if not t or not t.alpha or t.alpha <= 0 then
    return nil
  end
  local color = t.color or { 0, 0, 0 }
  local alpha = t.alpha
  return Components.box({
    position = "absolute",
    inset = 0,
    interactive = false,
    accessibilityHidden = true,
    zIndex = props.zIndex,
    draw = function(_, x, y, width, height, love)
      love.graphics.push("all")
      love.graphics.setColor(color[1], color[2], color[3], alpha)
      love.graphics.rectangle("fill", x, y, width, height)
      love.graphics.pop()
    end,
  })
end

-- Standalone portrait node (or nil) you can position anywhere — e.g. a bust on
-- top of the box, in its own frame. Pair with component({ portrait = false }).
-- props: size, width, height, side, align, fit, flip, frame, stencil, layout.
function Adapter:portrait(props)
  props = props or {}
  local model = self:model()
  -- Require an active dialogue: once it ends, Love-Dialogue releases its
  -- textures (LoveDialogue:destroy), so the portrait must not be drawn.
  if not model or not model.active or not model.portrait then
    return nil
  end
  return buildPortraitNode(self, model, {
    size = props.size,
    width = props.width,
    height = props.height,
    side = props.side,
    align = props.align,
    fit = props.fit,
    flip = props.flip,
    frame = props.frame,
    stencil = props.stencil,
    stencilOpts = props.stencilOpts,
    layout = props.layout,
  })
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
    boxHeight = nil,
    open = nil,
  }, Adapter)
  if opts.instance then
    adapter:wrap(opts.instance)
  end
  return adapter
end

return Dialogue
