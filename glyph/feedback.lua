local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local Animation = require(prefix .. ".animation")

local Feedback = {}

---@type table<string, GlyphFeedbackSequence>
local registry = {}

local FIELDS = {
  "opacity",
  "x",
  "y",
  "scale",
  "scaleX",
  "scaleY",
  "rotation",
}

---@param node GlyphNode|nil
---@return string|nil
local function feedbackId(node)
  if not node then
    return nil
  end

  local props = node.props or {}
  if props.key ~= nil then
    return "key:" .. tostring(props.key)
  end
  return node.path and ("path:" .. node.path) or nil
end

---@param values? GlyphAnimationValues|table
---@return boolean
local function isIdentity(values)
  values = values or {}
  return (values.opacity or 1) == 1
    and (values.x or 0) == 0
    and (values.y or 0) == 0
    and (values.scale or 1) == 1
    and (values.scaleX or 1) == 1
    and (values.scaleY or 1) == 1
    and (values.rotation or 0) == 0
end

---@param target table
---@param source? table
---@return nil
local function applyFields(target, source)
  for _, key in ipairs(FIELDS) do
    if source and source[key] ~= nil then
      target[key] = source[key]
    end
  end
end

---@param value any
---@return boolean
local function isArray(value)
  return type(value) == "table" and value[1] ~= nil
end

---@param step any
---@return GlyphFeedbackStep
local function normalizeStep(step)
  if type(step) == "function" then
    return {
      kind = "callback",
      callback = step,
    }
  end

  if type(step) ~= "table" then
    return {
      kind = "emit",
      event = tostring(step),
    }
  end

  if step.kind ~= nil then
    return step
  end

  if step.to or step.from or step.duration or step.ease then
    local copy = {}
    for key, value in pairs(step) do
      copy[key] = value
    end
    copy.kind = "animate"
    return copy
  end

  return step
end

---@param value any
---@return GlyphFeedbackSequence|nil
local function normalizeSequence(value)
  if value == nil or value == false then
    return nil
  end

  if type(value) == "string" then
    return registry[value]
  end

  if type(value) == "function" then
    return { normalizeStep(value) }
  end

  if type(value) ~= "table" then
    return { normalizeStep(value) }
  end

  if value.kind or value.to or value.from or value.duration or value.ease then
    return { normalizeStep(value) }
  end

  if isArray(value) then
    local sequence = {}
    for index, step in ipairs(value) do
      sequence[index] = normalizeStep(step)
    end
    return sequence
  end

  return { normalizeStep(value) }
end

---@param node GlyphNode|nil
---@return string|nil
local function nodeLabel(node)
  if not node then
    return nil
  end

  local props = node.props or {}
  if type(props.label) == "string" then
    return props.label
  end
  if type(props.title) == "string" then
    return props.title
  end
  if node.type == "text" and node.value ~= nil then
    return tostring(node.value)
  end
  if node.type == "input" then
    if props.value ~= nil and tostring(props.value) ~= "" then
      return tostring(props.value)
    end
    if props.placeholder ~= nil then
      return tostring(props.placeholder)
    end
  end
  return nil
end

---@param runtime table
---@param node GlyphNode|nil
---@return GlyphFeedbackState
local function stateFor(runtime, node)
  runtime.feedbackStates = runtime.feedbackStates or {}
  local id = feedbackId(node) or ("manual:" .. tostring({}))
  local state = runtime.feedbackStates[id]
  if not state then
    state = {
      id = id,
      subject = Animation.subject(),
      active = 0,
      tweens = {},
    }
    runtime.feedbackStates[id] = state
  end

  state.node = node
  if node then
    node._glyphFeedbackId = id
    node._glyphFeedback = state.subject
  end
  return state
end

---@param runtime table
---@param ctx GlyphFeedbackContext
---@param step GlyphFeedbackStep
---@param nextStep fun()
---@return nil
local function runStep(runtime, ctx, step, nextStep)
  local kind = step.kind or "emit"

  if kind == "animate" then
    local state = stateFor(runtime, ctx.node)
    if step.from then
      applyFields(state.subject, step.from)
    end

    state.active = (state.active or 0) + 1
    local tween
    tween = Animation.to(state.subject, step.duration or 0.16, step.to or {}, {
      ease = step.ease,
      delay = step.delay,
      onStart = step.onStart,
      onUpdate = function(subject)
        if step.onUpdate then
          step.onUpdate(subject, ctx)
        end
        runtime:markDirty()
      end,
      onComplete = function(subject)
        state.active = math.max(0, (state.active or 1) - 1)
        for index = #state.tweens, 1, -1 do
          if state.tweens[index] == tween then
            table.remove(state.tweens, index)
            break
          end
        end
        if step.onComplete then
          step.onComplete(subject, ctx)
        end
        if state.active == 0 and isIdentity(state.subject) then
          runtime.feedbackStates[state.id] = nil
        end
        runtime:markDirty()
        nextStep()
      end,
    })
    state.tweens[#state.tweens + 1] = tween
    runtime:markDirty()
    return
  end

  if kind == "audio" and step.cue then
    local node = ctx.node
    runtime:dispatch("audio", {
      cue = step.cue,
      kind = step.audioKind or "feedback",
      node = node,
      type = node and node.type or nil,
      path = node and node.path or nil,
      variant = node and node.props and node.props.variant or nil,
      styleType = node and node.props and node.props.styleType or nil,
      label = nodeLabel(node),
    })
  elseif kind == "emit" then
    local event = {
      kind = step.event or step.name or ctx.trigger or "feedback",
      name = step.name,
      trigger = ctx.trigger,
      node = ctx.node,
      path = ctx.node and ctx.node.path or nil,
      payload = step.payload,
      step = step,
    }
    for key, value in pairs(step) do
      if event[key] == nil and key ~= "kind" then
        event[key] = value
      end
    end
    runtime:dispatch("feedback", event)
  elseif kind == "callback" then
    local callback = step.callback or step.fn or step[1]
    if type(callback) == "function" then
      callback(ctx)
    end
  end

  nextStep()
end

---@param name string
---@param sequence GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)
---@return GlyphFeedbackSequence|nil
function Feedback.define(name, sequence)
  local normalized = normalizeSequence(sequence)
  registry[name] = normalized
  return normalized
end

---@param runtime table
---@param nameOrSequence any
---@param node? GlyphNode
---@param opts? GlyphFeedbackPlayOpts
---@return GlyphFeedbackContext|nil
function Feedback.play(runtime, nameOrSequence, node, opts)
  if not runtime or nameOrSequence == nil or nameOrSequence == false then
    return nil
  end

  local sequence = normalizeSequence(nameOrSequence)
  if not sequence then
    return nil
  end

  opts = opts or {}
  local ctx = {
    runtime = runtime,
    node = node,
    trigger = opts.trigger or "manual",
    source = nameOrSequence,
    opts = opts,
  }

  local index = 0
  local function nextStep()
    index = index + 1
    local step = sequence[index]
    if not step then
      return
    end
    runStep(runtime, ctx, step, nextStep)
  end

  nextStep()
  return ctx
end

---@param runtime table
---@param node GlyphNode|nil
---@param trigger "hover"|"focus"|"press"|"release"|"activate"|"error"|string
---@param opts? GlyphFeedbackPlayOpts
---@return GlyphFeedbackContext|nil
function Feedback.trigger(runtime, node, trigger, opts)
  if not node or not node.props or node.props.feedback == false then
    return nil
  end
  if node.props.disabled == true and (trigger == "press" or trigger == "release" or trigger == "activate") then
    return nil
  end

  local feedback = node.props.feedback
  local value = type(feedback) == "table" and feedback[trigger] or nil
  if value == nil or value == false then
    return nil
  end

  opts = opts or {}
  opts.trigger = trigger
  return Feedback.play(runtime, value, node, opts)
end

---@param runtime table
---@param root? GlyphNode
---@return nil
function Feedback.prepare(runtime, root)
  if not runtime or not root or not runtime.feedbackStates then
    return
  end

  local function visit(node)
    local id = feedbackId(node)
    local state = id and runtime.feedbackStates[id] or nil
    if state then
      state.node = node
      node._glyphFeedbackId = id
      node._glyphFeedback = state.subject
    end
    for _, child in ipairs(node.children or {}) do
      visit(child)
    end
  end

  visit(root)
end

---@param runtime? table
---@return nil
function Feedback.clear(runtime)
  registry = {}
  if runtime then
    for _, state in pairs(runtime.feedbackStates or {}) do
      for _, tween in ipairs(state.tweens or {}) do
        if tween.stop then
          tween:stop()
        end
      end
    end
    runtime.feedbackStates = {}

    local function clearNode(node)
      if not node then
        return
      end
      node._glyphFeedback = nil
      node._glyphFeedbackId = nil
      for _, child in ipairs(node.children or {}) do
        clearNode(child)
      end
    end

    clearNode(runtime.root)
    if runtime.scene then
      for _, layer in ipairs(runtime.scene.layers or {}) do
        clearNode(layer.root)
      end
    end
    if runtime.markDirty then
      runtime:markDirty()
    end
  end
end

---@param name string
---@return GlyphFeedbackSequence|nil
function Feedback.get(name)
  return registry[name]
end

return Feedback
