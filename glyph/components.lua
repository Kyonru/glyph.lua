local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local CallbackBus = require(prefix .. ".callback_bus")
local I18n = require(prefix .. ".i18n")

local Components = {}

local function normalizeProps(props)
  if props == nil then
    return {}
  end

  return props
end

local function normalizeChildren(children)
  if children == nil then
    return {}
  end

  if children.type then
    return { children }
  end

  return children
end

local function createNode(kind, props, children)
  local node = {
    type = kind,
    props = normalizeProps(props),
    children = normalizeChildren(children),
    layout = { x = 0, y = 0, width = 0, height = 0 },
    dirty = {
      layout = true,
      style = true,
      text = true,
      bounds = true,
    },
    bus = nil,
  }

  for _, child in ipairs(node.children) do
    child.parent = node
  end

  if node.props.callbacks then
    node.bus = CallbackBus.new(node.props.callbacks)
  end

  return node
end

---@param value string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.text(value, props)
  props = normalizeProps(props)
  local node = createNode("text", props, nil)
  node.value = I18n.resolveText(value, props)
  return node
end

---@param key string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.textKey(key, props)
  props = normalizeProps(props)
  props.textKey = key
  return Components.text(key, props)
end

---@param props? GlyphProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.box(props, children)
  return createNode("box", props, children)
end

---@param props? GlyphProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.stack(props, children)
  props = normalizeProps(props)
  props.display = "stack"
  return createNode("stack", props, children)
end

---@param props? GlyphProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.row(props, children)
  props = normalizeProps(props)
  props.display = "row"
  return createNode("row", props, children)
end

---@param props? GlyphProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.column(props, children)
  props = normalizeProps(props)
  props.display = "column"
  return createNode("column", props, children)
end

---@param props? GlyphButtonProps
---@return GlyphNode
function Components.button(props)
  props = normalizeProps(props)
  props.focusable = props.focusable ~= false
  props.label = I18n.resolveLabel(props)
  return createNode("button", props, nil)
end

---@param props? GlyphInputProps
---@return GlyphNode
function Components.input(props)
  props = normalizeProps(props)
  props.focusable = props.focusable ~= false
  props.placeholder = I18n.resolvePlaceholder(props)
  return createNode("input", props, nil)
end

---@param props? GlyphMeterProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.meter(props, children)
  props = normalizeProps(props)
  props.value = props.value or 0
  props.min = props.min or 0
  props.max = props.max or 1
  props.kind = props.kind or "linear"
  props.direction = props.direction or "right"
  props.display = props.display or "stack"
  props.label = I18n.resolveLabel(props)
  return createNode("meter", props, children)
end

---@param props? GlyphProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.scrollView(props, children)
  props = normalizeProps(props)
  props.display = props.display or "column"
  return createNode("scrollView", props, children)
end

---@param props? GlyphTabsProps
---@param tabs? GlyphTab[]
---@return GlyphNode
function Components.tabs(props, tabs)
  props = normalizeProps(props)
  local active = props.active or 1
  local children = {}

  for index, tab in ipairs(tabs or {}) do
    children[#children + 1] = Components.button({
      label = I18n.resolveLabel(tab) or tostring(index),
      onClick = function()
        if props.onChange then
          props.onChange(index, tab)
        end
      end,
      backgroundColor = index == active and props.activeColor or nil,
      active = index == active,
      variant = props.tabVariant,
      style = props.tabStyle,
      styleType = "tab",
    })
  end

  local tabRow = Components.row({ gap = props.gap or 4, height = props.tabHeight }, children)
  local content = tabs and tabs[active] and tabs[active].content or nil

  return Components.column(props, {
    tabRow,
    content or Components.box({ height = 0, width = 0 }),
  })
end

---@param props? GlyphPanelProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.panel(props, children)
  props = normalizeProps(props)
  local panelChildren = {}

  if props.title then
    panelChildren[#panelChildren + 1] = Components.text(I18n.resolveTitle(props), {
      color = props.titleColor,
    })
  elseif props.titleKey then
    panelChildren[#panelChildren + 1] = Components.text(I18n.resolveTitle(props), {
      color = props.titleColor,
    })
  end

  for _, child in ipairs(normalizeChildren(children)) do
    panelChildren[#panelChildren + 1] = child
  end

  return createNode("panel", {
    display = "column",
    gap = props.gap or 8,
    padding = props.padding or 10,
    width = props.width,
    height = props.height,
    grow = props.grow,
    flex = props.flex,
    shrink = props.shrink,
    minWidth = props.minWidth,
    minHeight = props.minHeight,
    maxWidth = props.maxWidth,
    maxHeight = props.maxHeight,
    position = props.position,
    x = props.x,
    y = props.y,
    top = props.top,
    right = props.right,
    bottom = props.bottom,
    left = props.left,
    inset = props.inset,
    zIndex = props.zIndex,
    align = props.align,
    navGroup = props.navGroup,
    navScope = props.navScope,
    navTrap = props.navTrap,
    onNavigateExit = props.onNavigateExit,
    clip = props.clip,
    stencil = props.stencil,
    shape = props.shape,
    draw = props.draw,
    backgroundColor = props.backgroundColor,
    borderColor = props.borderColor,
    radius = props.radius,
    style = props.style,
    variant = props.variant,
    styleType = props.styleType,
  }, panelChildren)
end

---@param node GlyphNode
---@return GlyphNode
function Components.static(node)
  node.static = true
  node.dirty = node.dirty or {}
  node.dirty.layout = true
  node.dirty.style = false
  node.dirty.text = false
  node.dirty.bounds = false
  return node
end

return Components
