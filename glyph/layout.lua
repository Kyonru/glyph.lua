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
    for index = 1, #value do
      local nextValue = current .. value:sub(index, index)
      if current ~= "" and textWidth(nextValue) > widthLimit then
        lines[#lines + 1] = current
        current = value:sub(index, index)
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
        local lines, wrappedWidth, wrappedHeight = wrapText(text, widthLimit, context, props, theme)
        node.wrappedText = {
          lines = lines,
          width = wrappedWidth,
          height = wrappedHeight,
        }
        return wrappedWidth, wrappedHeight
      end
    end

    if context.measureText then
      return context.measureText(text, props, theme)
    end

    return #text * 7, theme.lineHeight
  end

  if node.type == "input" then
    return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or 160, resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or 28
  end

  if node.type == "button" then
    local label = tostring(props.label or "")
    local textWidth, textHeight
    if context.measureText then
      textWidth, textHeight = context.measureText(label, props, theme)
    else
      textWidth, textHeight = #label * 7, theme.lineHeight
    end

    local pad = spacing(props.padding or { x = 10, y = 5 })
    return textWidth + pad.left + pad.right, textHeight + pad.top + pad.bottom
  end

  return resolveSize(props.width, node.layout.availableWidth) or numericSize(props.width) or 0, resolveSize(props.height, node.layout.availableHeight) or numericSize(props.height) or 0
end

function Layout.compute(root, context)
  context = context or {}

  local function visit(node, availableWidth, availableHeight)
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

    if direction ~= "row" and direction ~= "column" then
      local measuredWidth, measuredHeight = Layout.measureNode(node, context)
      local resolvedWidth = resolveSize(props.width, availableWidth)
      local resolvedHeight = resolveSize(props.height, availableHeight)
      node.layout.width = clamp(node.layout.assignedWidth or resolvedWidth or numericSize(props.width) or measuredWidth, props.minWidth, props.maxWidth)
      node.layout.height = clamp(node.layout.assignedHeight or resolvedHeight or numericSize(props.height) or measuredHeight, props.minHeight, props.maxHeight)
      node.layout.contentWidth = math.max(0, node.layout.width - pad.left - pad.right)
      node.layout.contentHeight = math.max(0, node.layout.height - pad.top - pad.bottom)
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

    for index, child in ipairs(children) do
      child.layout = child.layout or {}
      child.layout.assignedWidth = nil
      child.layout.assignedHeight = nil

      local childAvailableWidth = innerCrossLimit
      local childAvailableHeight = innerMainLimit
      if direction == "row" then
        childAvailableWidth = innerMainLimit
        childAvailableHeight = innerCrossLimit
      end

      visit(child, childAvailableWidth, childAvailableHeight)
      local basis = flexBasis(child, direction)
      totalMain = totalMain + basis
      maxCross = math.max(maxCross, cross(child, direction))
      growTotal = growTotal + flexGrow(child.props)
      shrinkTotal = shrinkTotal + flexShrink(child.props) * basis

      if index > 1 then
        totalMain = totalMain + gap
      end
    end

    local innerMain = innerMainLimit or totalMain
    local extra = math.max(0, innerMain - totalMain)
    if extra > 0 and growTotal > 0 then
      for _, child in ipairs(children) do
        local grow = flexGrow(child.props)
        if grow > 0 then
          local assigned = flexBasis(child, direction) + extra * (grow / growTotal)
          setMain(child, direction, assigned)
          assignMainConstraint(child, direction, assigned)
          child.dirty.layout = true
          visit(child, assignedWidthFor(child, direction, assigned, innerCrossLimit), assignedHeightFor(child, direction, assigned, innerCrossLimit))
        end
      end
    elseif node.type ~= "scrollView" and innerMainLimit and totalMain > innerMainLimit and shrinkTotal > 0 then
      local overflow = totalMain - innerMainLimit
      for _, child in ipairs(children) do
        local shrink = flexShrink(child.props)
        local basis = flexBasis(child, direction)
        if shrink > 0 and basis > 0 then
          local assigned = math.max(0, basis - overflow * ((shrink * basis) / shrinkTotal))
          setMain(child, direction, assigned)
          assignMainConstraint(child, direction, assigned)
          child.dirty.layout = true
          visit(child, assignedWidthFor(child, direction, assigned, innerCrossLimit), assignedHeightFor(child, direction, assigned, innerCrossLimit))
        end
      end
    end

    totalMain = 0
    maxCross = 0
    for index, child in ipairs(children) do
      totalMain = totalMain + intrinsic(child, direction)
      maxCross = math.max(maxCross, cross(child, direction))
      if index > 1 then
        totalMain = totalMain + gap
      end
    end

    local innerCross = innerCrossLimit or maxCross
    if node.type == "scrollView" then
      node.layout.scrollContentWidth = direction == "row" and totalMain or maxCross
      node.layout.scrollContentHeight = direction == "row" and maxCross or totalMain
    end

    local align = props.align or "start"
    local cursor = direction == "row" and pad.left or pad.top

    for _, child in ipairs(children) do
      local childCross = cross(child, direction)
      local offsetCross = 0

      if align == "center" then
        offsetCross = (innerCross - childCross) / 2
      elseif align == "end" then
        offsetCross = innerCross - childCross
      elseif align == "stretch" then
        childCross = innerCross
        setCross(child, direction, innerCross)
      end

      if direction == "row" then
        child.layout.x = cursor
        child.layout.y = pad.top + offsetCross
      else
        child.layout.x = pad.left + offsetCross
        child.layout.y = cursor
      end

      cursor = cursor + intrinsic(child, direction) + gap
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
    node.dirty.layout = false
    return node.layout.width, node.layout.height
  end

  visit(root)
  root.layout.x = root.layout.x or 0
  root.layout.y = root.layout.y or 0
  return root
end

return Layout
