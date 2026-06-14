local moduleName = ...
local glyphPrefix = moduleName and moduleName:match("^(.*)%.feedback$") or "glyph"

-- Inert stand-in so feedback degrades to a no-op (instead of crashing the whole
-- library) if the vendored Feel backend is ever absent. Every entry returns the
-- safe default its caller expects.
local function stubFeel()
  return {
    target = function()
      return { values = {} }
    end,
    define = function() end,
    get = function() end,
    validate = function()
      return false
    end,
    active = function()
      return {}
    end,
    isPlaying = function()
      return false
    end,
    play = function() end,
    update = function()
      return false
    end,
    clear = function() end,
  }
end

local function loadFeel()
  local ok, feel = pcall(require, glyphPrefix .. ".vendor.feel")
  if ok and type(feel) == "table" then
    return feel
  end
  return stubFeel()
end

local Feel = loadFeel()

local Feedback = {}

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

local function stateFor(runtime, node)
  runtime.feedbackStates = runtime.feedbackStates or {}
  local id = feedbackId(node) or ("manual:" .. tostring({}))
  local target = runtime.feedbackStates[id]

  if not target then
    target = Feel.target({
      id = id,
      label = nodeLabel(node),
      node = node,
    })
    runtime.feedbackStates[id] = target
  end

  target.node = node
  target.label = nodeLabel(node)
  if node then
    node._glyphFeedbackId = id
    node._glyphFeedback = target.values
  end

  return target
end

local function enrichEvent(event, node)
  event.node = event.node or node
  event.type = event.type or (node and node.type or nil)
  event.path = event.path or (node and node.path or nil)
  event.variant = event.variant or (node and node.props and node.props.variant or nil)
  event.styleType = event.styleType or (node and node.props and node.props.styleType or nil)
  event.label = event.label or nodeLabel(node)
  return event
end

function Feedback.define(name, sequence)
  return Feel.define(name, sequence)
end

function Feedback.get(name)
  return Feel.get(name)
end

function Feedback.validate(sequence)
  return Feel.validate(sequence)
end

function Feedback.active()
  return Feel.active()
end

function Feedback.targetFor(runtime, node)
  if not runtime or not node or not runtime.feedbackStates then
    return nil
  end
  local id = feedbackId(node)
  return id and runtime.feedbackStates[id] or nil
end

function Feedback.isPlaying(runtime, node, key)
  if not runtime then
    return Feel.isPlaying(nil, key)
  end

  if node ~= nil then
    local target = Feedback.targetFor(runtime, node)
    return target ~= nil and Feel.isPlaying(target, key)
  end

  return Feel.isPlaying(nil, key)
end

function Feedback.play(runtime, nameOrSequence, node, opts)
  if not runtime or nameOrSequence == nil or nameOrSequence == false then
    return nil
  end
  if type(nameOrSequence) == "string" and not Feel.get(nameOrSequence) then
    return nil
  end

  opts = opts or {}
  local target = stateFor(runtime, node)
  local playOpts = {}
  for key, value in pairs(opts) do
    playOpts[key] = value
  end

  playOpts.trigger = opts.trigger or "manual"
  playOpts.markDirty = function()
    if runtime.markDirty then
      runtime:markDirty()
    end
    if opts.markDirty then
      opts.markDirty()
    end
  end
  playOpts.emit = function(event)
    runtime:dispatch("feedback", enrichEvent(event, node))
  end
  playOpts.audio = function(event)
    runtime:dispatch("audio", enrichEvent(event, node))
  end

  local ctx = Feel.play(nameOrSequence, target, playOpts)
  if not ctx then
    return nil
  end

  ctx.runtime = runtime
  ctx.node = node
  return ctx
end

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

function Feedback.prepare(runtime, root)
  if not runtime or not root or not runtime.feedbackStates then
    return
  end

  local function visit(node)
    local id = feedbackId(node)
    local target = id and runtime.feedbackStates[id] or nil
    if target then
      target.node = node
      target.label = nodeLabel(node)
      node._glyphFeedbackId = id
      node._glyphFeedback = target.values
    end
    for _, child in ipairs(node.children or {}) do
      visit(child)
    end
  end

  visit(root)
end

function Feedback.update(runtime, dt)
  local active = Feel.update(dt)
  if active and runtime and runtime.markDirty then
    runtime:markDirty()
  end
  return active
end

function Feedback.clear(runtime, node)
  if runtime and node then
    local target = Feedback.targetFor(runtime, node)
    if target then
      Feel.clear(target)
    end
    local id = feedbackId(node)
    if id and runtime.feedbackStates then
      runtime.feedbackStates[id] = nil
    end
    node._glyphFeedback = nil
    node._glyphFeedbackId = nil
    if runtime.markDirty then
      runtime:markDirty()
    end
    return
  end

  Feel.clear()
  if runtime then
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

Feedback.feel = Feel

return Feedback
