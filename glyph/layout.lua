local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local GridMath = require(prefix .. ".grid_math")
local Path = require(prefix .. ".path")
local RichTextBackend = require(prefix .. ".rich_text_backend")
local Typography = require(prefix .. ".typography")

local Layout = {}

local function spacing(value)
  if type(value) == "number" then
    return {
      top = value,
      right = value,
      bottom = value,
      left = value,
    }
  end

  value = value or {}
  return {
    top = value.top or value.y or 0,
    right = value.right or value.x or 0,
    bottom = value.bottom or value.y or 0,
    left = value.left or value.x or 0,
  }
end

local ZERO_SPACING = { top = 0, right = 0, bottom = 0, left = 0 }

-- Margin around a flow child. Returns numeric edges (non-numbers, e.g. percent
-- strings, collapse to 0 — margin is pixel-only) and a shared zero table when
-- absent, so the common no-margin path allocates nothing.
local function marginOf(props)
  if not props or props.margin == nil then
    return ZERO_SPACING
  end

  local m = spacing(props.margin)
  return {
    top = type(m.top) == "number" and m.top or 0,
    right = type(m.right) == "number" and m.right or 0,
    bottom = type(m.bottom) == "number" and m.bottom or 0,
    left = type(m.left) == "number" and m.left or 0,
  }
end

local function clamp(value, minValue, maxValue)
  if minValue ~= nil and value < minValue then
    value = minValue
  end

  if maxValue ~= nil and value > maxValue then
    value = maxValue
  end

  return value
end

local function percentValue(value, available)
  if type(value) ~= "string" then
    return nil
  end

  local number = value:match("^(%-?%d+%.?%d*)%%$")
  if not number or available == nil then
    return nil
  end

  return available * (tonumber(number) / 100)
end

local function resolveSize(value, available)
  if type(value) == "number" then
    return value
  end

  return percentValue(value, available)
end

local function numericSize(value)
  if type(value) == "number" then
    return value
  end

  return nil
end

local function richTextUsesBackendMetrics(node, props)
  return node
    and node.type == "text"
    and Typography.isRich(props)
    and node.richText ~= nil
    and node.richText.fallback ~= true
end

local function imageNaturalSize(props)
  props = props or {}

  local source = props.source
  if not source or type(source.getWidth) ~= "function" or type(source.getHeight) ~= "function" then
    return 0, 0
  end

  local quad = props.quad
  if quad and type(quad.getViewport) == "function" then
    local ok, _, _, width, height = pcall(quad.getViewport, quad)
    if ok and type(width) == "number" and type(height) == "number" then
      return width, height
    end
  end

  local okWidth, width = pcall(source.getWidth, source)
  local okHeight, height = pcall(source.getHeight, source)
  if okWidth and okHeight and type(width) == "number" and type(height) == "number" then
    return width, height
  end

  return 0, 0
end

local function isAbsolute(node)
  return node and node.props and node.props.position == "absolute"
end

local function resolveOffset(value, available)
  if type(value) == "number" then
    return value
  end

  return percentValue(value, available)
end

local function intrinsic(node, axis)
  if axis == "row" then
    return node.layout.width
  end

  return node.layout.height
end

local function setMain(node, axis, value)
  if axis == "row" then
    node.layout.width = value
  else
    node.layout.height = value
  end
end

local function setCross(node, axis, value)
  if axis == "row" then
    node.layout.height = value
  else
    node.layout.width = value
  end
end

local function cross(node, axis)
  if axis == "row" then
    return node.layout.height
  end

  return node.layout.width
end

local function mainProp(axis)
  if axis == "row" then
    return "width"
  end

  return "height"
end

local function crossProp(axis)
  if axis == "row" then
    return "height"
  end

  return "width"
end

local function flexGrow(props)
  if not props then
    return 0
  end

  if type(props.flex) == "number" then
    return props.flex
  end

  if props.flex == true then
    return 1
  end

  return props.grow or 0
end

local function flexShrink(props)
  if not props then
    return 1
  end

  if type(props.shrink) == "number" then
    return props.shrink
  end

  if props.flex ~= nil then
    return 1
  end

  return 1
end

local function flexBasis(node, direction)
  local props = node.props or {}
  if props.basis ~= nil then
    return props.basis
  end

  if props.flexBasis ~= nil then
    return props.flexBasis
  end

  local main = mainProp(direction)
  if props.flex ~= nil and props[main] == nil then
    return 0
  end

  return intrinsic(node, direction)
end

local function assignMainConstraint(child, direction, value)
  child.layout = child.layout or {}

  if direction == "row" then
    child.layout.assignedWidth = value
  else
    child.layout.assignedHeight = value
  end
end

local function assignedWidthFor(node, direction, mainValue, crossValue)
  if direction == "row" then
    return mainValue
  end

  return crossValue
end

local function assignedHeightFor(node, direction, mainValue, crossValue)
  if direction == "row" then
    return crossValue
  end

  return mainValue
end

local function charWidth(context, props, theme)
  if context.measureText then
    local width = context.measureText("M", props, theme)
    return width > 0 and width or 7
  end

  return 7
end

local function measureText(context, text, props, theme, nodeType)
  if context.measureText then
    return context.measureText(text, props, theme, nodeType)
  end

  return Typography.measurePlain(text, props, theme, nil, nil, nodeType)
end

local function utf8Chars(value)
  local chars = {}
  local text = tostring(value or "")
  local index = 1
  local length = #text

  while index <= length do
    local byte = text:byte(index)
    local charLength = 1
    if byte and byte >= 0xF0 then
      charLength = 4
    elseif byte and byte >= 0xE0 then
      charLength = 3
    elseif byte and byte >= 0xC0 then
      charLength = 2
    end

    if index + charLength - 1 > length then
      charLength = 1
    end

    chars[#chars + 1] = text:sub(index, index + charLength - 1)
    index = index + charLength
  end

  return chars
end

local function wrapText(text, maxWidth, context, props, theme)
  local measuredLineHeight = nil
  if context.measureText then
    local _, height = context.measureText("M", props, theme)
    measuredLineHeight = height
  end
  local lineHeight = props.lineHeight or measuredLineHeight or theme.lineHeight
  local widthLimit = math.max(1, maxWidth or 1)
  local lines = {}

  local function textWidth(value)
    if context.measureText then
      local width = context.measureText(value, props, theme)
      return width
    end

    return #value * charWidth(context, props, theme)
  end

  local function pushHardWrapped(value)
    if value == "" then
      lines[#lines + 1] = ""
      return
    end

    local current = ""
    for _, char in ipairs(utf8Chars(value)) do
      local nextValue = current .. char
      if current ~= "" and textWidth(nextValue) > widthLimit then
        lines[#lines + 1] = current
        current = char
      else
        current = nextValue
      end
    end

    if current ~= "" then
      lines[#lines + 1] = current
    end
  end

  local paragraphs = {}
  local source = tostring(text)
  local startIndex = 1
  while true do
    local newline = source:find("\n", startIndex, true)
    if not newline then
      paragraphs[#paragraphs + 1] = source:sub(startIndex)
      break
    end

    paragraphs[#paragraphs + 1] = source:sub(startIndex, newline - 1)
    startIndex = newline + 1
  end

  for _, paragraph in ipairs(paragraphs) do
    if paragraph == "" then
      lines[#lines + 1] = ""
    else
      local current = ""
      for word in paragraph:gmatch("%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if textWidth(candidate) <= widthLimit then
          current = candidate
        else
          if current ~= "" then
            lines[#lines + 1] = current
          end

          if textWidth(word) > widthLimit then
            pushHardWrapped(word)
            current = ""
          else
            current = word
          end
        end
      end

      if current ~= "" then
        lines[#lines + 1] = current
      end
    end
  end

  if #lines == 0 then
    lines[1] = ""
  end

  return lines, widthLimit, #lines * lineHeight
end

function Layout.measureNode(node, context)
  local props = node.props or {}
  local theme = context.theme
  local measure = props.measure or node.measure

  if type(measure) == "function" then
    local width, height = measure(node, context)
    return width or 0, height or 0
  end

  if node.type == "text" then
    local text = tostring(node.value or "")
    if props.wrap or props.width or node.layout.assignedWidth then
      local widthLimit = props.wrapWidth or resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or node.layout.assignedWidth or (props.wrap and node.layout.availableWidth) or props.maxWidth
      if widthLimit then
        if Typography.isRich(props) then
          local rich = RichTextBackend.prepare(node, text, widthLimit, props, theme.version)
          node.richText = rich
          node.wrappedText = {
            lines = type(rich.lines) == "table" and rich.lines or { text },
            width = rich.width,
            height = rich.height,
          }
          return rich.width, rich.height
        end
        local lines, wrappedWidth, wrappedHeight = wrapText(text, widthLimit, context, props, theme)
        node.wrappedText = {
          lines = lines,
          width = wrappedWidth,
          height = wrappedHeight,
        }
        return wrappedWidth, wrappedHeight
      end
    end

    if Typography.isRich(props) then
      local rich = RichTextBackend.prepare(node, text, nil, props, theme.version)
      node.richText = rich
      return rich.width, rich.height
    end

    return measureText(context, text, props, theme, node.type)
  end

  if node.type == "input" then
    return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or 160, resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or 28
  end

  if node.type == "button" then
    local label = tostring(props.label or "")
    local textWidth, textHeight
    textWidth, textHeight = measureText(context, label, props, theme, node.type)

    local pad = spacing(props.padding or { x = 10, y = 5 })
    return textWidth + pad.left + pad.right, textHeight + pad.top + pad.bottom
  end

  if node.type == "meter" then
    local kind = props.kind or "linear"
    local defaultWidth = kind == "linear" and 120 or 72
    local defaultHeight = kind == "linear" and 16 or 72
    return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or defaultWidth,
      resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or defaultHeight
  end

  if node.type == "image" then
    local naturalWidth, naturalHeight = imageNaturalSize(props)
    return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or naturalWidth,
      resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or naturalHeight
  end

  if node.type == "path" then
    local source = props.path or props.d
    local naturalWidth, naturalHeight = 0, 0
    if source ~= nil then
      local ok, bounds = pcall(Path.bounds, source)
      if ok and bounds then
        naturalWidth = bounds.width or 0
        naturalHeight = bounds.height or 0
      end
    end
    return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or naturalWidth,
      resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or naturalHeight
  end

  return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or 0, resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or 0
end

function Layout.compute(root, context)
  context = context or {}

  local visit

  local function absoluteEdges(props, contentWidth, contentHeight)
    local inset = props.inset ~= nil and spacing(props.inset) or {}
    return {
      left = resolveOffset(props.left ~= nil and props.left or inset.left, contentWidth),
      right = resolveOffset(props.right ~= nil and props.right or inset.right, contentWidth),
      top = resolveOffset(props.top ~= nil and props.top or inset.top, contentHeight),
      bottom = resolveOffset(props.bottom ~= nil and props.bottom or inset.bottom, contentHeight),
    }
  end

  local function placeAbsoluteChild(child, parent, pad, context)
    local props = child.props or {}
    local contentWidth = (parent.layout and parent.layout.contentWidth) or 0
    local contentHeight = (parent.layout and parent.layout.contentHeight) or 0
    local edges = absoluteEdges(props, contentWidth, contentHeight)
    local resolvedWidth = resolveSize(props.width, contentWidth)
    local resolvedHeight = resolveSize(props.height, contentHeight)

    if resolvedWidth == nil and edges.left ~= nil and edges.right ~= nil then
      resolvedWidth = math.max(0, contentWidth - edges.left - edges.right)
    end
    if resolvedHeight == nil and edges.top ~= nil and edges.bottom ~= nil then
      resolvedHeight = math.max(0, contentHeight - edges.top - edges.bottom)
    end

    child.layout = child.layout or {}
    child.layout.assignedWidth = resolvedWidth
    child.layout.assignedHeight = resolvedHeight
    child.dirty = child.dirty or {}
    child.dirty.layout = true
    visit(child, resolvedWidth or contentWidth, resolvedHeight or contentHeight)

    local x = resolveOffset(props.x, contentWidth)
    local y = resolveOffset(props.y, contentHeight)

    if edges.left ~= nil then
      x = edges.left
    elseif x == nil and edges.right ~= nil then
      x = contentWidth - edges.right - (child.layout.width or 0)
    end

    if edges.top ~= nil then
      y = edges.top
    elseif y == nil and edges.bottom ~= nil then
      y = contentHeight - edges.bottom - (child.layout.height or 0)
    end

    child.layout.x = pad.left + (x or 0)
    child.layout.y = pad.top + (y or 0)
  end

  local function placeAbsoluteChildren(node, pad)
    for _, child in ipairs(node.children or {}) do
      if isAbsolute(child) then
        placeAbsoluteChild(child, node, pad, context)
      end
    end
  end

  local function visitStack(node, availableWidth, availableHeight, props, children, pad)
    local resolvedWidth = resolveSize(props.width, availableWidth)
    local resolvedHeight = resolveSize(props.height, availableHeight)
    local measuredWidth, measuredHeight = nil, nil
    if node.type == "meter" then
      measuredWidth, measuredHeight = Layout.measureNode(node, context)
    end
    local width = node.layout.assignedWidth or resolvedWidth or numericSize(props.width) or measuredWidth
    local height = node.layout.assignedHeight or resolvedHeight or numericSize(props.height) or measuredHeight
    local innerWidth = width and math.max(0, width - pad.left - pad.right) or availableWidth
    local innerHeight = height and math.max(0, height - pad.top - pad.bottom) or availableHeight
    local maxWidth = 0
    local maxHeight = 0

    for _, child in ipairs(children) do
      child.layout = child.layout or {}
      child.layout.assignedWidth = nil
      child.layout.assignedHeight = nil

      if not isAbsolute(child) then
        if flexGrow(child.props) > 0 then
          child.layout.assignedWidth = innerWidth
          child.layout.assignedHeight = innerHeight
        end

        visit(child, innerWidth, innerHeight)
        child.layout.x = pad.left
        child.layout.y = pad.top
        maxWidth = math.max(maxWidth, child.layout.width or 0)
        maxHeight = math.max(maxHeight, child.layout.height or 0)
      end
    end

    node.layout.width = clamp(width or (maxWidth + pad.left + pad.right), props.minWidth, props.maxWidth)
    node.layout.height = clamp(height or (maxHeight + pad.top + pad.bottom), props.minHeight, props.maxHeight)
    node.layout.contentWidth = math.max(0, node.layout.width - pad.left - pad.right)
    node.layout.contentHeight = math.max(0, node.layout.height - pad.top - pad.bottom)

    for _, child in ipairs(children) do
      if not isAbsolute(child) and flexGrow(child.props) > 0 then
        child.layout.assignedWidth = node.layout.contentWidth
        child.layout.assignedHeight = node.layout.contentHeight
        child.dirty.layout = true
        visit(child, node.layout.contentWidth, node.layout.contentHeight)
        child.layout.x = pad.left
        child.layout.y = pad.top
      end
    end

    placeAbsoluteChildren(node, pad)
    node.dirty.layout = false
    return node.layout.width, node.layout.height
  end

  local function visitGrid(node, availableWidth, availableHeight, props, children, pad)
    local assignedWidth = node.layout.assignedWidth
    local assignedHeight = node.layout.assignedHeight
    local flowCount = 0
    for _, child in ipairs(children) do
      if not isAbsolute(child) then
        flowCount = flowCount + 1
      end
    end

    local plan = GridMath.resolve(props, availableWidth, availableHeight, assignedWidth, assignedHeight, flowCount)
    local gap = plan.gap
    local columns = plan.columns
    local cellWidth = plan.cellWidth
    local cellHeight = plan.cellHeight

    for _, child in ipairs(children) do
      child.layout = child.layout or {}
      child.layout.assignedWidth = nil
      child.layout.assignedHeight = nil

      if not isAbsolute(child) then
        child.layout.assignedWidth = cellWidth
        child.layout.assignedHeight = cellHeight
        child.dirty = child.dirty or {}
        child.dirty.layout = true
        visit(child, cellWidth, cellHeight)
      end
    end

    node.layout.width = plan.width
    node.layout.height = plan.height
    node.layout.contentWidth = plan.contentWidth
    node.layout.contentHeight = plan.contentHeight

    if node.type == "scrollView" then
      node.layout.scrollContentWidth = plan.gridWidth
      node.layout.scrollContentHeight = plan.gridHeight
    end

    flowCount = 0
    for _, child in ipairs(children) do
      if not isAbsolute(child) then
        local column = flowCount % columns
        local row = math.floor(flowCount / columns)
        child.layout.x = pad.left + plan.offsetX + column * (cellWidth + gap)
        child.layout.y = pad.top + plan.offsetY + row * (cellHeight + gap)
        flowCount = flowCount + 1
      end
    end

    placeAbsoluteChildren(node, pad)
    node.dirty.layout = false
    return node.layout.width, node.layout.height
  end

  visit = function(node, availableWidth, availableHeight)
    node.layout = node.layout or {}
    node.dirty = node.dirty or {}
    node.layout.availableWidth = availableWidth
    node.layout.availableHeight = availableHeight

    if (node.static or node.memoized) and node.dirty.layout == false and (node.layout.width or 0) > 0 and (node.layout.height or 0) > 0 then
      return node.layout.width, node.layout.height
    end

    local props = node.props or {}
    local children = node.children or {}
    local pad = spacing(props.padding)
    local gap = props.gap or 0
    local direction = props.display or node.display

    if direction == "stack" then
      return visitStack(node, availableWidth, availableHeight, props, children, pad)
    end

    if direction == "grid" then
      return visitGrid(node, availableWidth, availableHeight, props, children, pad)
    end

    if direction ~= "row" and direction ~= "column" then
      local measuredWidth, measuredHeight = Layout.measureNode(node, context)
      local resolvedWidth = resolveSize(props.width, availableWidth)
      local resolvedHeight = resolveSize(props.height, availableHeight)
      local preferredWidth = node.layout.assignedWidth or resolvedWidth or numericSize(props.width) or measuredWidth
      if richTextUsesBackendMetrics(node, props) then
        preferredWidth = node.layout.assignedWidth or measuredWidth
      end
      node.layout.width = clamp(preferredWidth, props.minWidth, props.maxWidth)
      node.layout.height = clamp(node.layout.assignedHeight or resolvedHeight or numericSize(props.height) or measuredHeight, props.minHeight, props.maxHeight)
      node.layout.contentWidth = math.max(0, node.layout.width - pad.left - pad.right)
      node.layout.contentHeight = math.max(0, node.layout.height - pad.top - pad.bottom)
      placeAbsoluteChildren(node, pad)
      node.dirty.layout = false
      return node.layout.width, node.layout.height
    end

    local main = mainProp(direction)
    local crossAxis = crossProp(direction)
    local resolvedWidth = resolveSize(props.width, availableWidth)
    local resolvedHeight = resolveSize(props.height, availableHeight)
    local mainSize
    local crossSize
    if direction == "row" then
      mainSize = resolvedWidth or node.layout.assignedWidth
      crossSize = resolvedHeight or node.layout.assignedHeight
    else
      mainSize = resolvedHeight or node.layout.assignedHeight
      crossSize = resolvedWidth or node.layout.assignedWidth
    end
    local innerMainLimit = mainSize and math.max(0, mainSize - (direction == "row" and pad.left + pad.right or pad.top + pad.bottom)) or nil
    local innerCrossLimit = crossSize and math.max(0, crossSize - (direction == "row" and pad.top + pad.bottom or pad.left + pad.right)) or nil
    local totalMain = 0
    local maxCross = 0
    local growTotal = 0
    local shrinkTotal = 0

    local flowIndex = 0
    for _, child in ipairs(children) do
      child.layout = child.layout or {}
      child.layout.assignedWidth = nil
      child.layout.assignedHeight = nil

      if not isAbsolute(child) then
        local m = marginOf(child.props)
        local mMain = (direction == "row") and (m.left + m.right) or (m.top + m.bottom)
        local mCross = (direction == "row") and (m.top + m.bottom) or (m.left + m.right)
        local availMain = innerMainLimit and math.max(0, innerMainLimit - mMain) or innerMainLimit
        local availCross = innerCrossLimit and math.max(0, innerCrossLimit - mCross) or innerCrossLimit
        local childAvailableWidth = (direction == "row") and availMain or availCross
        local childAvailableHeight = (direction == "row") and availCross or availMain

        visit(child, childAvailableWidth, childAvailableHeight)
        local basis = flexBasis(child, direction)
        totalMain = totalMain + basis + mMain
        maxCross = math.max(maxCross, cross(child, direction) + mCross)
        growTotal = growTotal + flexGrow(child.props)
        shrinkTotal = shrinkTotal + flexShrink(child.props) * basis

        flowIndex = flowIndex + 1
        if flowIndex > 1 then
          totalMain = totalMain + gap
        end
      end
    end

    local innerMain = innerMainLimit or totalMain
    local extra = math.max(0, innerMain - totalMain)
    if extra > 0 and growTotal > 0 then
      for _, child in ipairs(children) do
        if not isAbsolute(child) then
          local grow = flexGrow(child.props)
          if grow > 0 then
            local assigned = flexBasis(child, direction) + extra * (grow / growTotal)
            setMain(child, direction, assigned)
            assignMainConstraint(child, direction, assigned)
            child.dirty.layout = true
            local m = marginOf(child.props)
            local mCross = (direction == "row") and (m.top + m.bottom) or (m.left + m.right)
            local availCross = innerCrossLimit and math.max(0, innerCrossLimit - mCross) or innerCrossLimit
            visit(child, assignedWidthFor(child, direction, assigned, availCross), assignedHeightFor(child, direction, assigned, availCross))
          end
        end
      end
    elseif node.type ~= "scrollView" and innerMainLimit and totalMain > innerMainLimit and shrinkTotal > 0 then
      local overflow = totalMain - innerMainLimit
      for _, child in ipairs(children) do
        if not isAbsolute(child) then
          local shrink = flexShrink(child.props)
          local basis = flexBasis(child, direction)
          if shrink > 0 and basis > 0 then
            local assigned = math.max(0, basis - overflow * ((shrink * basis) / shrinkTotal))
            setMain(child, direction, assigned)
            assignMainConstraint(child, direction, assigned)
            child.dirty.layout = true
            local m = marginOf(child.props)
            local mCross = (direction == "row") and (m.top + m.bottom) or (m.left + m.right)
            local availCross = innerCrossLimit and math.max(0, innerCrossLimit - mCross) or innerCrossLimit
            visit(child, assignedWidthFor(child, direction, assigned, availCross), assignedHeightFor(child, direction, assigned, availCross))
          end
        end
      end
    end

    totalMain = 0
    maxCross = 0
    flowIndex = 0
    for _, child in ipairs(children) do
      if not isAbsolute(child) then
        local m = marginOf(child.props)
        totalMain = totalMain + intrinsic(child, direction)
          + ((direction == "row") and (m.left + m.right) or (m.top + m.bottom))
        maxCross = math.max(maxCross, cross(child, direction)
          + ((direction == "row") and (m.top + m.bottom) or (m.left + m.right)))
        flowIndex = flowIndex + 1
        if flowIndex > 1 then
          totalMain = totalMain + gap
        end
      end
    end

    local innerCross = innerCrossLimit or maxCross
    if node.type == "scrollView" then
      node.layout.scrollContentWidth = direction == "row" and totalMain or maxCross
      node.layout.scrollContentHeight = direction == "row" and maxCross or totalMain
    end

    local align = props.align or "start"
    local justify = props.justify or "start"
    local remainingMain = math.max(0, innerMain - totalMain)
    local offsetMain = 0
    if justify == "center" then
      offsetMain = remainingMain / 2
    elseif justify == "end" then
      offsetMain = remainingMain
    end
    local cursor = (direction == "row" and pad.left or pad.top) + offsetMain

    for _, child in ipairs(children) do
      if not isAbsolute(child) then
        local m = marginOf(child.props)
        local mainStart = (direction == "row") and m.left or m.top
        local mainEnd = (direction == "row") and m.right or m.bottom
        local crossStart = (direction == "row") and m.top or m.left
        local crossEnd = (direction == "row") and m.bottom or m.right
        local crossMargin = crossStart + crossEnd
        local childCross = cross(child, direction)
        local offsetCross = 0

        if align == "center" then
          offsetCross = (innerCross - childCross - crossMargin) / 2
        elseif align == "end" then
          offsetCross = innerCross - childCross - crossMargin
        elseif align == "stretch" then
          childCross = math.max(0, innerCross - crossMargin)
          setCross(child, direction, childCross)
        end

        cursor = cursor + mainStart
        if direction == "row" then
          child.layout.x = cursor
          child.layout.y = pad.top + crossStart + offsetCross
        else
          child.layout.x = pad.left + crossStart + offsetCross
          child.layout.y = cursor
        end

        cursor = cursor + intrinsic(child, direction) + mainEnd + gap
      end
    end

    if direction == "row" then
      node.layout.width = clamp(node.layout.assignedWidth or resolvedWidth or (totalMain + pad.left + pad.right), props.minWidth, props.maxWidth)
      node.layout.height = clamp(node.layout.assignedHeight or resolvedHeight or (innerCross + pad.top + pad.bottom), props.minHeight, props.maxHeight)
    else
      node.layout.width = clamp(node.layout.assignedWidth or resolvedWidth or (innerCross + pad.left + pad.right), props.minWidth, props.maxWidth)
      node.layout.height = clamp(node.layout.assignedHeight or resolvedHeight or (totalMain + pad.top + pad.bottom), props.minHeight, props.maxHeight)
    end

    node.layout.contentWidth = math.max(0, node.layout.width - pad.left - pad.right)
    node.layout.contentHeight = math.max(0, node.layout.height - pad.top - pad.bottom)
    placeAbsoluteChildren(node, pad)
    node.dirty.layout = false
    return node.layout.width, node.layout.height
  end

  visit(root, context.availableWidth, context.availableHeight)
  root.layout.x = root.layout.x or 0
  root.layout.y = root.layout.y or 0
  return root
end

return Layout
