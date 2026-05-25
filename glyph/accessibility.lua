local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local I18n = require(prefix .. ".i18n")

local Accessibility = {}

local defaultConfig = {
  enabled = true,
  announceOnFocus = true,
  announceOnActivate = true,
}

local config = {}

local function resetConfig()
  config = {}
  for key, value in pairs(defaultConfig) do
    config[key] = value
  end
end

resetConfig()

local function orderedChildren(node)
  local source = node and node.children or {}
  if #source <= 1 then
    return source
  end

  local ordered = {}
  for index, child in ipairs(source) do
    ordered[index] = {
      index = index,
      node = child,
      zIndex = (child.props and child.props.zIndex) or 0,
    }
  end

  table.sort(ordered, function(a, b)
    if a.zIndex == b.zIndex then
      return a.index < b.index
    end
    return a.zIndex < b.zIndex
  end)

  local result = {}
  for index, entry in ipairs(ordered) do
    result[index] = entry.node
  end
  return result
end

local function defaultRole(node)
  if not node then
    return nil
  end

  local props = node.props or {}
  if node.type == "button" and props.styleType == "tab" then
    return "tab"
  elseif node.type == "button" then
    return "button"
  elseif node.type == "input" then
    return "input"
  elseif node.type == "meter" then
    return "meter"
  elseif node.type == "text" then
    return "text"
  elseif node.type == "panel" then
    return "panel"
  end

  return nil
end

local function resolveKey(props, prefixName, fallback)
  local key = props[prefixName .. "Key"]
  if key == nil then
    return fallback
  end

  return I18n.t(key, props[prefixName .. "Params"], {
    fallback = props[prefixName .. "Fallback"],
    cacheKey = props[prefixName .. "CacheKey"],
  })
end

local function textValue(node)
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

local function defaultLabel(node)
  local props = node and node.props or {}
  if node and node.type == "input" then
    return props.placeholder or textValue(node)
  end
  return textValue(node)
end

local function defaultValueText(node)
  if not node then
    return nil
  end

  local props = node.props or {}
  if node.type == "input" then
    return props.value ~= nil and tostring(props.value) or nil
  end
  if node.type == "meter" then
    if type(props.label) == "function" then
      return tostring(props.label(props.value or 0, props.min or 0, props.max or 1))
    end
    if props.label ~= nil then
      return tostring(props.label)
    end
    return tostring(props.value or 0)
  end
  if props.accessibilityValue ~= nil then
    return tostring(props.accessibilityValue)
  end
  return nil
end

function Accessibility.configure(opts)
  resetConfig()
  opts = opts or {}
  for key, value in pairs(opts) do
    config[key] = value
  end
end

function Accessibility.isEnabled()
  return config.enabled ~= false
end

function Accessibility.describe(node)
  if not node or not node.props then
    return nil
  end

  local props = node.props or {}
  if props.accessibilityHidden == true then
    return nil
  end

  local role = props.role or defaultRole(node)
  if role == "none" then
    return nil
  end

  local label = resolveKey(props, "accessibilityLabel", props.accessibilityLabel or defaultLabel(node))
  local description = resolveKey(props, "accessibilityDescription", props.accessibilityDescription)
  local valueText = resolveKey(props, "accessibilityValueText", props.accessibilityValueText or defaultValueText(node))
  local live = props.accessibilityLive
  if live == nil then
    live = "off"
  end

  if role == nil and label == nil and description == nil and valueText == nil and live == "off" and props.focusable ~= true then
    return nil
  end

  return {
    node = node,
    path = node.path,
    type = node.type,
    role = role,
    label = label,
    description = description,
    value = props.accessibilityValue,
    valueText = valueText,
    live = live,
    disabled = props.disabled == true,
    focusable = props.focusable == true or node.type == "button" or node.type == "input",
    hidden = false,
  }
end

local function appendSnapshot(result, node)
  if node and node.props and node.props.accessibilityHidden == true then
    return
  end

  local description = Accessibility.describe(node)
  if description then
    result[#result + 1] = description
  end

  for _, child in ipairs(orderedChildren(node)) do
    appendSnapshot(result, child)
  end
end

function Accessibility.snapshot(target)
  local result = {}
  if not target then
    return result
  end

  if target.root or target.scene then
    if target.root then
      appendSnapshot(result, target.root)
    end
    if target.scene and target.scene.layers then
      for _, layer in ipairs(target.scene.layers) do
        if layer.root and layer.state ~= "exiting" then
          appendSnapshot(result, layer.root)
        end
      end
    end
  else
    appendSnapshot(result, target)
  end

  return result
end

local function messageFor(kind, description, fallback)
  if fallback then
    return fallback
  end

  if not description then
    return nil
  end

  local parts = {}
  if description.label then
    parts[#parts + 1] = description.label
  end
  if description.role and description.role ~= "text" then
    parts[#parts + 1] = description.role
  end
  if description.valueText and description.valueText ~= description.label then
    parts[#parts + 1] = description.valueText
  end
  if description.description then
    parts[#parts + 1] = description.description
  end

  if #parts == 0 then
    return kind
  end
  return table.concat(parts, ", ")
end

function Accessibility.announce(runtime, message, opts)
  if not Accessibility.isEnabled() or not runtime then
    return nil
  end

  opts = opts or {}
  local description = opts.node and Accessibility.describe(opts.node) or nil
  if opts.node and not description then
    return nil
  end
  local resolvedMessage = message or messageFor(opts.kind or "announce", description)
  if resolvedMessage == nil then
    return nil
  end

  local event = {
    kind = opts.kind or "announce",
    message = resolvedMessage,
    node = opts.node,
    path = description and description.path or opts.path,
    role = description and description.role or opts.role,
    label = description and description.label or opts.label,
    description = description and description.description or opts.description,
    valueText = description and description.valueText or opts.valueText,
    live = opts.live or (description and description.live),
  }

  runtime:dispatch("accessibility", event)
  return event
end

function Accessibility.emit(runtime, kind, node, opts)
  if not Accessibility.isEnabled() then
    return nil
  end
  if kind == "focus" and config.announceOnFocus == false then
    return nil
  end
  if kind == "activate" and config.announceOnActivate == false then
    return nil
  end

  opts = opts or {}
  opts.kind = kind
  opts.node = node
  return Accessibility.announce(runtime, opts.message, opts)
end

function Accessibility.focused(runtime)
  if not runtime then
    return nil
  end
  return Accessibility.describe(runtime.focusNode)
end

function Accessibility.scanLive(runtime, root)
  if not Accessibility.isEnabled() or not runtime or not root then
    return
  end

  runtime.accessibilityLiveValues = runtime.accessibilityLiveValues or {}

  local function visit(node)
    if node and node.props and node.props.accessibilityHidden == true then
      return
    end

    local description = Accessibility.describe(node)
    if description and description.live and description.live ~= "off" and description.path then
      local value = description.valueText or description.label or description.description or ""
      local previous = runtime.accessibilityLiveValues[description.path]
      if previous ~= nil and previous ~= value then
        Accessibility.announce(runtime, value, {
          kind = "live",
          node = node,
          live = description.live,
        })
      end
      runtime.accessibilityLiveValues[description.path] = value
    end

    for _, child in ipairs(orderedChildren(node)) do
      visit(child)
    end
  end

  visit(root)
end

return Accessibility
