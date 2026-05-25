local Navigate = {}

local VALID_DIRECTIONS = {
  up = true,
  down = true,
  left = true,
  right = true,
}

---@param node GlyphNode
---@param reverse? boolean
---@return GlyphNode[]
local function orderedChildren(node, reverse)
  local source = node.children or {}
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
      if reverse then
        return a.index > b.index
      end
      return a.index < b.index
    end

    if reverse then
      return a.zIndex > b.zIndex
    end
    return a.zIndex < b.zIndex
  end)

  local result = {}
  for index, entry in ipairs(ordered) do
    result[index] = entry.node
  end
  return result
end

---@param node GlyphNode
---@param parentX number
---@param parentY number
---@param fn fun(node: GlyphNode, x: number, y: number, group: any, scope: GlyphNode|GlyphLayer|nil)
---@param group any
---@param scope GlyphNode|GlyphLayer|nil
local function absoluteWalk(node, parentX, parentY, fn, group, scope)
  if not node then
    return
  end

  local layout = node.layout or {}
  local props = node.props or {}
  local x = parentX + (layout.x or 0)
  local y = parentY + (layout.y or 0)
  local nextGroup = group
  local nextScope = scope

  if props.navGroup ~= nil then
    nextGroup = props.navGroup
  end

  if props.navScope == true then
    nextScope = node
  end

  fn(node, x, y, nextGroup, nextScope)

  for _, child in ipairs(orderedChildren(node)) do
    absoluteWalk(child, x, y, fn, nextGroup, nextScope)
  end
end

---@param node GlyphNode
---@return boolean
local function isFocusable(node)
  local props = node.props or {}
  if props.interactive == false or props.disabled == true or props.focusable == false then
    return false
  end

  return node.type == "button" or node.type == "input" or props.focusable == true
end

---@param node GlyphNode
---@param x number
---@param y number
---@param group any
---@param scope GlyphNode|GlyphLayer|nil
---@return GlyphNavCandidate
local function candidateFor(node, x, y, group, scope)
  local layout = node.layout or {}
  local width = layout.width or 0
  local height = layout.height or 0

  return {
    node = node,
    x = x,
    y = y,
    w = width,
    h = height,
    width = width,
    height = height,
    cx = x + width / 2,
    cy = y + height / 2,
    group = group,
    scope = scope,
    scopeNode = scope,
  }
end

---@param root GlyphNode
---@param offsetX number
---@param offsetY number
---@param candidates GlyphNavCandidate[]
---@param scope GlyphNode|GlyphLayer|nil
local function collectRoot(root, offsetX, offsetY, candidates, scope)
  absoluteWalk(root, offsetX or 0, offsetY or 0, function(node, x, y, group, scope)
    if isFocusable(node) then
      candidates[#candidates + 1] = candidateFor(node, x, y, group, scope)
    end
  end, nil, scope)
end

---@param runtime table
---@return GlyphNavCandidate[]
function Navigate.collect(runtime)
  local candidates = {}
  local scene = runtime.scene

  if scene and #scene.layers > 0 then
    for index = #scene.layers, 1, -1 do
      local layer = scene.layers[index]
      if layer.state ~= "exiting" then
        if layer.input ~= false and layer.root then
          local layerScope = layer.navScope == true and layer or nil
          collectRoot(layer.root, layer.offsetX or 0, layer.offsetY or 0, candidates, layerScope)
        end

        if layer.blocking then
          break
        end
      elseif layer.blocking then
        break
      end
    end

    return candidates
  end

  if runtime.root then
    collectRoot(runtime.root, 0, 0, candidates)
  end

  return candidates
end

---@param candidates GlyphNavCandidate[]
---@return GlyphNavCandidate|nil
local function topLeft(candidates)
  table.sort(candidates, function(a, b)
    if a.y == b.y then
      return a.x < b.x
    end
    return a.y < b.y
  end)
  return candidates[1]
end

---@param candidates GlyphNavCandidate[]
---@param node GlyphNode|nil
---@return GlyphNavCandidate|nil
local function candidateForNode(candidates, node)
  for _, candidate in ipairs(candidates) do
    if candidate.node == node or (node and node.path ~= nil and candidate.node.path == node.path) then
      return candidate
    end
  end
  return nil
end

---@param a1 number
---@param a2 number
---@param b1 number
---@param b2 number
---@return number
local function rangeGap(a1, a2, b1, b2)
  if a2 < b1 then
    return b1 - a2
  elseif b2 < a1 then
    return a1 - b2
  end
  return 0
end

---@param direction GlyphNavDirection
---@param origin GlyphNavCandidate
---@param candidate GlyphNavCandidate
---@return number|nil, boolean|nil
local function directionalDistance(direction, origin, candidate)
  local dx = candidate.cx - origin.cx
  local dy = candidate.cy - origin.cy

  if direction == "right" then
    if dx <= 0 then return nil end
    return math.max(0, candidate.x - (origin.x + origin.w)), true
  elseif direction == "left" then
    if dx >= 0 then return nil end
    return math.max(0, origin.x - (candidate.x + candidate.w)), true
  elseif direction == "down" then
    if dy <= 0 then return nil end
    return math.max(0, candidate.y - (origin.y + origin.h)), false
  elseif direction == "up" then
    if dy >= 0 then return nil end
    return math.max(0, origin.y - (candidate.y + candidate.h)), false
  end

  return nil
end

---@param direction GlyphNavDirection
---@param origin GlyphNavCandidate
---@param candidate GlyphNavCandidate
---@return number|nil
local function scoreCandidate(direction, origin, candidate)
  local primaryGap, horizontal = directionalDistance(direction, origin, candidate)
  if primaryGap == nil then
    return nil
  end

  local secondaryGap
  local centerPrimary
  local centerSecondary

  if horizontal then
    secondaryGap = rangeGap(origin.y, origin.y + origin.h, candidate.y, candidate.y + candidate.h)
    centerPrimary = math.abs(candidate.cx - origin.cx)
    centerSecondary = math.abs(candidate.cy - origin.cy)
  else
    secondaryGap = rangeGap(origin.x, origin.x + origin.w, candidate.x, candidate.x + candidate.w)
    centerPrimary = math.abs(candidate.cy - origin.cy)
    centerSecondary = math.abs(candidate.cx - origin.cx)
  end

  -- Avoid lateral moves into mostly vertical targets and vice versa. Vertical
  -- movement gets a row fallback below, but horizontal movement should stop
  -- cleanly at row ends instead of jumping into the next row.
  if secondaryGap > 0 and centerSecondary > centerPrimary then
    return nil
  end

  local beamPenalty = secondaryGap == 0 and 0 or 100000
  return beamPenalty + primaryGap * 10 + secondaryGap + centerPrimary * 0.01 + centerSecondary * 0.001
end

---@param direction GlyphNavDirection
---@param origin GlyphNavCandidate
---@param candidates GlyphNavCandidate[]
---@return GlyphNavCandidate|nil
local function rowFallback(direction, origin, candidates)
  if direction ~= "up" and direction ~= "down" then return nil end

  local pool = {}
  for _, c in ipairs(candidates) do
    if c.node ~= origin.node then
      local primaryGap = directionalDistance(direction, origin, c)
      if primaryGap ~= nil then
        pool[#pool + 1] = c
      end
    end
  end
  if #pool == 0 then return nil end

  local minDy = math.huge
  for _, c in ipairs(pool) do
    local d = math.abs(c.cy - origin.cy)
    if d < minDy then minDy = d end
  end

  local threshold = minDy + math.max(minDy * 0.5, 8)
  local row = {}
  for _, c in ipairs(pool) do
    if math.abs(c.cy - origin.cy) <= threshold then
      row[#row + 1] = c
    end
  end

  table.sort(row, function(a, b) return a.cx < b.cx end)
  return direction == "down" and row[1] or row[#row]
end

---@param direction GlyphNavDirection
---@param origin GlyphNavCandidate
---@param candidates GlyphNavCandidate[]
---@return GlyphNavCandidate|nil
local function bestFrom(direction, origin, candidates)
  local best = nil
  local bestScore = nil

  for _, candidate in ipairs(candidates) do
    if candidate.node ~= origin.node then
      local score = scoreCandidate(direction, origin, candidate)
      if score and (bestScore == nil or score < bestScore) then
        best = candidate
        bestScore = score
      end
    end
  end

  if not best then
    best = rowFallback(direction, origin, candidates)
  end

  return best
end

---@param candidates GlyphNavCandidate[]
---@param scope GlyphNode|GlyphLayer|nil
---@return GlyphNavCandidate[]
local function filterScope(candidates, scope)
  if scope == nil then
    return candidates
  end

  local scoped = {}
  for _, candidate in ipairs(candidates) do
    if candidate.scope == scope then
      scoped[#scoped + 1] = candidate
    end
  end
  return scoped
end

---@param candidates GlyphNavCandidate[]
---@param group any
---@return GlyphNavCandidate[]
local function filterGroup(candidates, group)
  if group == nil then
    return candidates
  end

  local scoped = {}
  for _, candidate in ipairs(candidates) do
    if candidate.group == group then
      scoped[#scoped + 1] = candidate
    end
  end
  return scoped
end

---@param scope GlyphNode|GlyphLayer|nil
---@return table
local function navScopeProps(scope)
  if not scope then
    return {}
  end

  if scope.type ~= nil then
    return scope.props or {}
  end

  return scope
end

---@param direction GlyphNavDirection
---@param currentNode GlyphNode|nil
---@param candidates GlyphNavCandidate[]
---@return GlyphNavCandidate|nil, GlyphNavCandidate|nil
function Navigate.best(direction, currentNode, candidates)
  if not VALID_DIRECTIONS[direction] or #candidates == 0 then
    return nil
  end

  local current = candidateForNode(candidates, currentNode)
  if not current then
    return topLeft(candidates)
  end

  if current.group ~= nil then
    local scopedBest = bestFrom(direction, current, filterGroup(candidates, current.group))
    if scopedBest then
      return scopedBest
    end
  end

  if current.scope ~= nil then
    local scopedBest = bestFrom(direction, current, filterScope(candidates, current.scope))
    if scopedBest then
      return scopedBest
    end

    local scopeProps = navScopeProps(current.scope)
    if scopeProps.navTrap == true or type(scopeProps.onNavigateExit) == "function" then
      return nil, current
    end
  end

  return bestFrom(direction, current, candidates)
end

---@param direction GlyphNavDirection
---@param blocked GlyphNavCandidate|nil
---@param candidates GlyphNavCandidate[]
---@return GlyphNavCandidate|nil
local function exitScope(direction, blocked, candidates)
  if not blocked or not blocked.scope then
    return nil
  end

  local scope = blocked.scope
  local props = navScopeProps(scope)
  if type(props.onNavigateExit) ~= "function" then
    return nil
  end

  local target = props.onNavigateExit(direction, blocked.node, scope, candidates)
  if target == false or target == nil then
    return nil
  end

  return candidateForNode(candidates, target) or { node = target }
end

---@param runtime table
---@param direction GlyphNavDirection
---@return GlyphNode|nil
function Navigate.move(runtime, direction)
  if not VALID_DIRECTIONS[direction] then
    error("[glyph.navigate] Invalid direction: " .. tostring(direction), 2)
  end

  local candidates = Navigate.collect(runtime)
  local best, blocked = Navigate.best(direction, runtime.focusNode, candidates)
  if not best then
    best = exitScope(direction, blocked, candidates)
  end

  if not best then
    return nil
  end

  local current = candidateForNode(candidates, runtime.focusNode)
  local context = {
    direction = direction,
    origin = current and current.node or runtime.focusNode,
    originCandidate = current,
    candidate = best.node,
    target = best.node,
    targetCandidate = best,
    candidates = candidates,
    scope = current and current.scope or nil,
  }

  local override = nil
  if runtime.bus and runtime.bus.dispatchUntil then
    override = runtime.bus:dispatchUntil("navigate", function(result)
      return result ~= nil
    end, direction, best.node, candidates, context)
  end

  if override == false then
    return nil
  elseif override ~= nil then
    best = candidateForNode(candidates, override) or { node = override }
  end

  if best and best.node then
    runtime:setFocus(best.node)
    return best.node
  end

  return nil
end

return Navigate
