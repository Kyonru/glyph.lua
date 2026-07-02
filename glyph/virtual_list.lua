local VirtualList = {}

local reservedProps = {
  itemCount = true,
  itemHeight = true,
  itemKey = true,
  onRangeChange = true,
  overscan = true,
  renderItem = true,
  scrollOffset = true,
  visibleCount = true,
}

local function copyScrollProps(props)
  local result = {}
  for key, value in pairs(props or {}) do
    if not reservedProps[key] then
      result[key] = value
    end
  end
  return result
end

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

local function scrollOffsetFor(runtime, props)
  if type(props.scrollOffset) == "number" then
    return math.max(0, props.scrollOffset)
  end

  local key = props.key
  if key == nil or not runtime then
    return 0
  end
  if type(runtime.getScrollOffset) == "function" then
    return math.max(0, runtime:getScrollOffset(key))
  end

  local offsets = runtime.scrollOffsets
  if not offsets then
    return 0
  end
  local needle = "k:" .. tostring(key)
  for path, offset in pairs(offsets) do
    if tostring(path):find(needle, 1, true) then
      return math.max(0, offset or 0)
    end
  end
  return 0
end

local function itemKey(props, index)
  if type(props.itemKey) == "function" then
    local value = props.itemKey(index)
    if value ~= nil then
      return value
    end
  elseif type(props.itemKey) == "table" then
    local value = props.itemKey[index]
    if value ~= nil then
      return value
    end
  end
  return index
end

---@param runtime table
---@param Components table
---@param props GlyphVirtualListProps
---@return GlyphNode
function VirtualList.build(runtime, Components, props)
  props = props or {}
  local itemCount = math.max(0, math.floor(tonumber(props.itemCount) or 0))
  local itemHeight = tonumber(props.itemHeight)
  local renderItem = props.renderItem

  if not itemHeight or itemHeight <= 0 or type(renderItem) ~= "function" then
    return Components.scrollView(copyScrollProps(props), {})
  end

  local explicitVisibleCount = tonumber(props.visibleCount)
  local viewportHeight = tonumber(props.height) or (explicitVisibleCount and explicitVisibleCount * itemHeight) or itemHeight
  local overscan = math.max(0, math.floor(tonumber(props.overscan) or 2))
  local maxScroll = math.max(0, itemCount * itemHeight - viewportHeight)
  local offset = clamp(scrollOffsetFor(runtime, props), 0, maxScroll)
  local first = itemCount > 0 and math.floor(offset / itemHeight) + 1 or 1
  first = clamp(first - overscan, 1, math.max(1, itemCount))
  local visibleCount = math.ceil(viewportHeight / itemHeight)
  local last = itemCount > 0 and math.min(itemCount, first + math.max(0, visibleCount - 1) + overscan * 2) or 0
  local children = {}

  local topSpacer = (first - 1) * itemHeight
  if topSpacer > 0 then
    children[#children + 1] = Components.box({
      width = props.width or "100%",
      height = topSpacer,
      interactive = false,
    })
  end

  for index = first, last do
    local node = renderItem(index)
    if node then
      node.props = node.props or {}
      if node.props.key == nil then
        node.props.key = itemKey(props, index)
      end
      if node.props.height == nil then
        node.props.height = itemHeight
      end
      children[#children + 1] = node
    end
  end

  local bottomSpacer = math.max(0, (itemCount - last) * itemHeight)
  if bottomSpacer > 0 then
    children[#children + 1] = Components.box({
      width = props.width or "100%",
      height = bottomSpacer,
      interactive = false,
    })
  end

  if type(props.onRangeChange) == "function" then
    props.onRangeChange(first, last, {
      itemCount = itemCount,
      itemHeight = itemHeight,
      mounted = math.max(0, last - first + 1),
      overscan = overscan,
      scrollOffset = offset,
    })
  end

  local scrollProps = copyScrollProps(props)
  scrollProps.display = scrollProps.display or "column"
  return Components.scrollView(scrollProps, children)
end

return VirtualList
