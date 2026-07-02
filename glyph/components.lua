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
  -- `rich = true` is shorthand for `format = "sysl"`; an explicit format wins.
  if props.rich == true and props.format == nil then
    props.format = "sysl"
  end
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

---@param value string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.richText(value, props)
  props = normalizeProps(props)
  props.format = props.format or "sysl"
  return Components.text(value, props)
end

---@param key string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.richTextKey(key, props)
  props = normalizeProps(props)
  props.textKey = key
  props.format = props.format or "sysl"
  return Components.text(key, props)
end

---@param value string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.h1(value, props)
  props = normalizeProps(props)
  props.textStyle = props.textStyle or "h1"
  return Components.text(value, props)
end

---@param value string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.h2(value, props)
  props = normalizeProps(props)
  props.textStyle = props.textStyle or "h2"
  return Components.text(value, props)
end

---@param value string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.p(value, props)
  props = normalizeProps(props)
  props.textStyle = props.textStyle or "paragraph"
  return Components.text(value, props)
end

---@param value string
---@param props? GlyphTextProps
---@return GlyphNode
function Components.caption(value, props)
  props = normalizeProps(props)
  props.textStyle = props.textStyle or "caption"
  return Components.text(value, props)
end

---@param props? GlyphImageProps
---@return GlyphNode
function Components.image(props)
  return createNode("image", props, nil)
end

---@param props? GlyphPathProps
---@return GlyphNode
function Components.path(props)
  return createNode("path", props, nil)
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

---@param props? GlyphGridProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.grid(props, children)
  props = normalizeProps(props)
  props.display = "grid"
  return createNode("grid", props, children)
end

---@param props? GlyphPortalProps
---@param children? GlyphNode[]|GlyphNode
---@return GlyphNode
function Components.portal(props, children)
  props = normalizeProps(props)
  props.position = props.position or "absolute"
  props.zScope = props.zScope or "root"
  props.display = props.display or "stack"
  return createNode("portal", props, children)
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

---@param props? GlyphScrollViewProps
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
      width = tab.width or props.tabWidth,
      height = tab.height or props.tabHeight,
      padding = tab.padding or props.tabPadding,
      onClick = function()
        if props.onChange then
          props.onChange(index, tab)
        end
      end,
      backgroundColor = index == active and props.activeColor or nil,
      active = index == active,
      role = tab.role or "tab",
      accessibilityLabel = tab.accessibilityLabel,
      accessibilityLabelKey = tab.accessibilityLabelKey,
      accessibilityLabelParams = tab.accessibilityLabelParams,
      accessibilityLabelFallback = tab.accessibilityLabelFallback,
      accessibilityLabelCacheKey = tab.accessibilityLabelCacheKey,
      accessibilityDescription = tab.accessibilityDescription,
      accessibilityDescriptionKey = tab.accessibilityDescriptionKey,
      accessibilityDescriptionParams = tab.accessibilityDescriptionParams,
      accessibilityDescriptionFallback = tab.accessibilityDescriptionFallback,
      accessibilityDescriptionCacheKey = tab.accessibilityDescriptionCacheKey,
      accessibilityHidden = tab.accessibilityHidden,
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
  local title = props.title or props.titleKey
  local resolvedTitle = title and I18n.resolveTitle(props) or nil

  if title then
    panelChildren[#panelChildren + 1] = Components.text(resolvedTitle, {
      color = props.titleColor,
      textStyle = props.titleTextStyle or "h2",
    })
  end

  for _, child in ipairs(normalizeChildren(children)) do
    panelChildren[#panelChildren + 1] = child
  end

  return createNode("panel", {
    display = "column",
    gap = props.gap or 8,
    padding = props.padding or 10,
    margin = props.margin,
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
    justify = props.justify,
    navGroup = props.navGroup,
    navScope = props.navScope,
    navTrap = props.navTrap,
    onNavigateExit = props.onNavigateExit,
    role = props.role,
    accessibilityLabel = props.accessibilityLabel,
    accessibilityLabelKey = props.accessibilityLabelKey,
    accessibilityLabelParams = props.accessibilityLabelParams,
    accessibilityLabelFallback = props.accessibilityLabelFallback,
    accessibilityLabelCacheKey = props.accessibilityLabelCacheKey,
    accessibilityDescription = props.accessibilityDescription,
    accessibilityDescriptionKey = props.accessibilityDescriptionKey,
    accessibilityDescriptionParams = props.accessibilityDescriptionParams,
    accessibilityDescriptionFallback = props.accessibilityDescriptionFallback,
    accessibilityDescriptionCacheKey = props.accessibilityDescriptionCacheKey,
    accessibilityValue = props.accessibilityValue,
    accessibilityValueText = props.accessibilityValueText,
    accessibilityValueTextKey = props.accessibilityValueTextKey,
    accessibilityValueTextParams = props.accessibilityValueTextParams,
    accessibilityValueTextFallback = props.accessibilityValueTextFallback,
    accessibilityValueTextCacheKey = props.accessibilityValueTextCacheKey,
    accessibilityHidden = props.accessibilityHidden,
    accessibilityLive = props.accessibilityLive,
    title = resolvedTitle,
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
