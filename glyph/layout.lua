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
    if props.wrap or props.width then
      local widthLimit = props.wrapWidth or props.width or props.maxWidth
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
    return props.width or 160, props.height or 28
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

  return props.width or 0, props.height or 0
end

function Layout.compute(root, context)
  context = context or {}

  local function visit(node, availableWidth, availableHeight)
    node.layout = node.layout or {}
    node.dirty = node.dirty or {}

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
      node.layout.width = clamp(props.width or measuredWidth, props.minWidth, props.maxWidth)
      node.layout.height = clamp(props.height or measuredHeight, props.minHeight, props.maxHeight)
      node.layout.contentWidth = math.max(0, node.layout.width - pad.left - pad.right)
      node.layout.contentHeight = math.max(0, node.layout.height - pad.top - pad.bottom)
      node.dirty.layout = false
      return node.layout.width, node.layout.height
    end

    local main = mainProp(direction)
    local crossAxis = crossProp(direction)
    local innerMainLimit = props[main] and math.max(0, props[main] - (direction == "row" and pad.left + pad.right or pad.top + pad.bottom)) or nil
    local innerCrossLimit = props[crossAxis] and math.max(0, props[crossAxis] - (direction == "row" and pad.top + pad.bottom or pad.left + pad.right)) or nil
    local totalMain = 0
    local maxCross = 0
    local growTotal = 0

    for index, child in ipairs(children) do
      local childAvailableWidth = innerCrossLimit
      local childAvailableHeight = innerMainLimit
      if direction == "row" then
        childAvailableWidth = innerMainLimit
        childAvailableHeight = innerCrossLimit
      end

      visit(child, childAvailableWidth, childAvailableHeight)
      totalMain = totalMain + intrinsic(child, direction)
      maxCross = math.max(maxCross, cross(child, direction))
      growTotal = growTotal + (child.props and child.props.grow or 0)

      if index > 1 then
        totalMain = totalMain + gap
      end
    end

    local innerMain = innerMainLimit or totalMain
    local extra = math.max(0, innerMain - totalMain)
    if extra > 0 and growTotal > 0 then
      for _, child in ipairs(children) do
        local grow = child.props and child.props.grow or 0
        if grow > 0 then
          setMain(child, direction, intrinsic(child, direction) + extra * (grow / growTotal))
        end
      end
    end

    local innerCross = innerCrossLimit or maxCross
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
      node.layout.width = clamp(props.width or (totalMain + pad.left + pad.right), props.minWidth, props.maxWidth)
      node.layout.height = clamp(props.height or (innerCross + pad.top + pad.bottom), props.minHeight, props.maxHeight)
    else
      node.layout.width = clamp(props.width or (innerCross + pad.left + pad.right), props.minWidth, props.maxWidth)
      node.layout.height = clamp(props.height or (totalMain + pad.top + pad.bottom), props.minHeight, props.maxHeight)
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
