local prefix = (...):match("^(.*)%.[^%.]+$") or "glyph"
local Responsive = require(prefix .. ".responsive")

local GridMath = {}

---@param value? number|GlyphPadding
---@return GlyphPadding
function GridMath.spacing(value)
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

---@param value any
---@param available? number
---@return number|nil
function GridMath.percentValue(value, available)
  if type(value) ~= "string" then
    return nil
  end

  local number = value:match("^(%-?%d+%.?%d*)%%$")
  if not number or available == nil then
    return nil
  end

  return available * (tonumber(number) / 100)
end

---@param value any
---@param available? number
---@return number|nil
function GridMath.resolveSize(value, available)
  if type(value) == "number" then
    return value
  end

  return GridMath.percentValue(value, available)
end

---@param value any
---@return number|nil
function GridMath.numericSize(value)
  if type(value) == "number" then
    return value
  end

  return nil
end

---@param value number
---@param minValue? number
---@param maxValue? number
---@return number
function GridMath.clamp(value, minValue, maxValue)
  if minValue ~= nil and value < minValue then
    value = minValue
  end

  if maxValue ~= nil and value > maxValue then
    value = maxValue
  end

  return value
end

---@param props GlyphGridProps|table
---@param availableWidth? number
---@param availableHeight? number
---@param assignedWidth? number
---@param assignedHeight? number
---@param flowCount? number
---@return table
function GridMath.resolve(props, availableWidth, availableHeight, assignedWidth, assignedHeight, flowCount)
  props = props or {}
  local gap = props.gap or 0
  local pad = GridMath.spacing(props.padding)
  local resolvedWidth = GridMath.resolveSize(props.width, availableWidth)
  local resolvedHeight = GridMath.resolveSize(props.height, availableHeight)
  local candidateWidth = assignedWidth or resolvedWidth or (props.minCellWidth and availableWidth) or nil
  local columnContainerWidth = nil

  if candidateWidth then
    columnContainerWidth = math.max(0, GridMath.clamp(candidateWidth, props.minWidth, props.maxWidth) - pad.left - pad.right)
  elseif availableWidth then
    columnContainerWidth = math.max(0, availableWidth - pad.left - pad.right)
  end

  local columns = math.max(1, math.floor(props.columns or 1))
  local cellWidth = nil

  if props.minCellWidth then
    local maxColumns = props.maxColumns and math.max(1, math.floor(props.maxColumns)) or nil
    local plan = Responsive.columns(columnContainerWidth or props.minCellWidth or 0, {
      min = props.minCellWidth,
      maxCount = maxColumns,
      gap = gap,
    })
    columns = math.max(1, math.floor(plan.count or 1))
    cellWidth = math.max(0, plan.width or 0)
  else
    cellWidth = GridMath.resolveSize(props.cellWidth, columnContainerWidth) or GridMath.numericSize(props.cellWidth) or 0
  end

  local cellHeight = GridMath.resolveSize(props.cellHeight, availableHeight) or GridMath.numericSize(props.cellHeight) or cellWidth
  flowCount = math.max(0, math.floor(flowCount or 0))

  local rows = flowCount > 0 and math.ceil(flowCount / columns) or 0
  local gridWidth = columns * cellWidth + math.max(0, columns - 1) * gap
  local gridHeight = rows > 0 and (rows * cellHeight + (rows - 1) * gap) or 0
  local naturalWidth = gridWidth + pad.left + pad.right
  local naturalHeight = gridHeight + pad.top + pad.bottom
  local widthCandidate = resolvedWidth or naturalWidth
  local heightCandidate = resolvedHeight or naturalHeight

  if assignedWidth then
    widthCandidate = resolvedWidth or math.max(assignedWidth, naturalWidth)
  end

  if assignedHeight then
    heightCandidate = resolvedHeight or math.max(assignedHeight, naturalHeight)
  end

  local width = GridMath.clamp(widthCandidate, props.minWidth, props.maxWidth)
  local height = GridMath.clamp(heightCandidate, props.minHeight, props.maxHeight)
  local contentWidth = math.max(0, width - pad.left - pad.right)
  local contentHeight = math.max(0, height - pad.top - pad.bottom)
  local remainingX = math.max(0, contentWidth - gridWidth)
  local remainingY = math.max(0, contentHeight - gridHeight)
  local offsetX = 0
  local offsetY = 0
  local justify = props.justify or "start"
  local align = props.align or "start"

  if justify == "center" then
    offsetX = remainingX / 2
  elseif justify == "end" then
    offsetX = remainingX
  end

  if align == "center" then
    offsetY = remainingY / 2
  elseif align == "end" then
    offsetY = remainingY
  end

  return {
    gap = gap,
    padding = pad,
    columns = columns,
    rows = rows,
    cellWidth = cellWidth,
    cellHeight = cellHeight,
    gridWidth = gridWidth,
    gridHeight = gridHeight,
    width = width,
    height = height,
    contentWidth = contentWidth,
    contentHeight = contentHeight,
    offsetX = offsetX,
    offsetY = offsetY,
  }
end

---@param bounds GlyphBounds
---@param props GlyphGridPointProps|GlyphGridProps|table
---@param x number
---@param y number
---@return GlyphGridCell|nil
function GridMath.pointToCell(bounds, props, x, y)
  if type(bounds) ~= "table" or type(props) ~= "table" then
    return nil
  end

  local width = bounds.width or 0
  local height = bounds.height or 0
  if width <= 0 or height <= 0 then
    return nil
  end
  if x < (bounds.x or 0) or y < (bounds.y or 0) or x >= (bounds.x or 0) + width or y >= (bounds.y or 0) + height then
    return nil
  end

  local count = props.count and math.max(0, math.floor(props.count)) or nil
  local flowCount = count or 0
  local plan = GridMath.resolve(props, width, height, width, height, flowCount)
  if plan.columns <= 0 or plan.cellWidth <= 0 or plan.cellHeight <= 0 then
    return nil
  end

  local pad = plan.padding
  local offsetY = count and plan.offsetY or 0
  local contentX = x - (bounds.x or 0) - pad.left - plan.offsetX
  local contentY = y - (bounds.y or 0) - pad.top - offsetY

  if contentX < 0 or contentY < 0 then
    return nil
  end

  local strideX = plan.cellWidth + plan.gap
  local strideY = plan.cellHeight + plan.gap
  local column = math.floor(contentX / strideX) + 1
  local row = math.floor(contentY / strideY) + 1

  if column < 1 or column > plan.columns or row < 1 then
    return nil
  end

  local localX = contentX - (column - 1) * strideX
  local localY = contentY - (row - 1) * strideY
  if localX < 0 or localY < 0 or localX >= plan.cellWidth or localY >= plan.cellHeight then
    return nil
  end

  local index = (row - 1) * plan.columns + column
  if count and index > count then
    return nil
  end

  return {
    column = column,
    row = row,
    index = index,
    localX = localX,
    localY = localY,
  }
end

return GridMath
