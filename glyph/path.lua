local Path = {}

local DEFAULT_SAMPLES = 96

local parseCache = {}
local flattenCache = {}

local COMMANDS = {
  M = 2,
  L = 2,
  H = 1,
  V = 1,
  C = 6,
  S = 4,
  Q = 4,
  T = 2,
  A = 7,
  Z = 0,
}

local function copyCommands(commands)
  local copy = {}
  for index, command in ipairs(commands or {}) do
    local nextCommand = {}
    for childIndex, value in ipairs(command) do
      nextCommand[childIndex] = value
    end
    copy[index] = nextCommand
  end
  return copy
end

local function copyPoints(points)
  local copy = {}
  for index, value in ipairs(points or {}) do
    copy[index] = value
  end
  return copy
end

local function clamp(value, minValue, maxValue)
  value = tonumber(value) or 0
  if value < minValue then
    return minValue
  elseif value > maxValue then
    return maxValue
  end
  return value
end

local function isDigit(char)
  return char ~= nil and char:match("%d") ~= nil
end

local function isCommand(char)
  return char ~= nil and char:match("[AaCcHhLlMmQqSsTtVvZz]") ~= nil
end

local function parseNumber(source, index)
  local startIndex = index
  local length = #source

  local char = source:sub(index, index)
  if char == "+" or char == "-" then
    index = index + 1
  end

  local hasDigits = false
  while index <= length and isDigit(source:sub(index, index)) do
    hasDigits = true
    index = index + 1
  end

  if source:sub(index, index) == "." then
    index = index + 1
    while index <= length and isDigit(source:sub(index, index)) do
      hasDigits = true
      index = index + 1
    end
  end

  if not hasDigits then
    error("invalid SVG path number at byte " .. tostring(startIndex), 3)
  end

  local exponent = source:sub(index, index)
  if exponent == "e" or exponent == "E" then
    local exponentIndex = index
    index = index + 1
    local sign = source:sub(index, index)
    if sign == "+" or sign == "-" then
      index = index + 1
    end

    local exponentDigits = false
    while index <= length and isDigit(source:sub(index, index)) do
      exponentDigits = true
      index = index + 1
    end

    if not exponentDigits then
      error("invalid SVG path exponent at byte " .. tostring(exponentIndex), 3)
    end
  end

  local value = tonumber(source:sub(startIndex, index - 1))
  if value == nil then
    error("invalid SVG path number at byte " .. tostring(startIndex), 3)
  end

  return value, index
end

local function tokenize(source)
  local tokens = {}
  local index = 1
  local length = #source

  while index <= length do
    local char = source:sub(index, index)
    if char == "," or char:match("%s") then
      index = index + 1
    elseif isCommand(char) then
      tokens[#tokens + 1] = char
      index = index + 1
    elseif char == "+" or char == "-" or char == "." or isDigit(char) then
      local value
      value, index = parseNumber(source, index)
      tokens[#tokens + 1] = value
    else
      error("invalid SVG path token '" .. char .. "' at byte " .. tostring(index), 2)
    end
  end

  return tokens
end

local function requireNumbers(tokens, index, count, command)
  local values = {}
  for offset = 1, count do
    local value = tokens[index]
    if type(value) ~= "number" then
      error("SVG path command " .. command .. " expected " .. tostring(count) .. " number(s)", 3)
    end
    values[offset] = value
    index = index + 1
  end
  return values, index
end

local function parseTokens(tokens)
  local commands = {}
  local index = 1
  local currentCommand = nil
  local x, y = 0, 0
  local subpathX, subpathY = 0, 0
  local previousKind, cubicX, cubicY, quadraticX, quadraticY

  local function add(command)
    commands[#commands + 1] = command
  end

  while index <= #tokens do
    local token = tokens[index]
    if type(token) == "string" then
      currentCommand = token
      index = index + 1
    elseif currentCommand == nil then
      error("SVG path data must begin with a command", 2)
    end

    local command = currentCommand
    local upper = command:upper()
    local relative = command ~= upper

    if COMMANDS[upper] == nil then
      error("unsupported SVG path command " .. tostring(command), 2)
    end

    if upper == "Z" then
      add({ "Z" })
      x, y = subpathX, subpathY
      previousKind, cubicX, cubicY, quadraticX, quadraticY = "Z", nil, nil, nil, nil
      currentCommand = nil
    elseif index > #tokens or type(tokens[index]) == "string" then
      error("SVG path command " .. command .. " expected " .. tostring(COMMANDS[upper]) .. " number(s)", 2)
    elseif upper == "M" then
      local first = true
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 2, command)
        local nextX = values[1]
        local nextY = values[2]
        if relative then
          nextX = x + nextX
          nextY = y + nextY
        end
        if first then
          add({ "M", nextX, nextY })
          subpathX, subpathY = nextX, nextY
          previousKind = "M"
          first = false
        else
          add({ "L", nextX, nextY })
          previousKind = "L"
        end
        cubicX, cubicY, quadraticX, quadraticY = nil, nil, nil, nil
        x, y = nextX, nextY
      end
      currentCommand = relative and "l" or "L"
    elseif upper == "L" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 2, command)
        local nextX = relative and x + values[1] or values[1]
        local nextY = relative and y + values[2] or values[2]
        add({ "L", nextX, nextY })
        previousKind, cubicX, cubicY, quadraticX, quadraticY = "L", nil, nil, nil, nil
        x, y = nextX, nextY
      end
    elseif upper == "H" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 1, command)
        local nextX = relative and x + values[1] or values[1]
        add({ "L", nextX, y })
        previousKind, cubicX, cubicY, quadraticX, quadraticY = "L", nil, nil, nil, nil
        x = nextX
      end
    elseif upper == "V" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 1, command)
        local nextY = relative and y + values[1] or values[1]
        add({ "L", x, nextY })
        previousKind, cubicX, cubicY, quadraticX, quadraticY = "L", nil, nil, nil, nil
        y = nextY
      end
    elseif upper == "C" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 6, command)
        local x1 = relative and x + values[1] or values[1]
        local y1 = relative and y + values[2] or values[2]
        local x2 = relative and x + values[3] or values[3]
        local y2 = relative and y + values[4] or values[4]
        local nextX = relative and x + values[5] or values[5]
        local nextY = relative and y + values[6] or values[6]
        add({ "C", x1, y1, x2, y2, nextX, nextY })
        previousKind, cubicX, cubicY = "C", x2, y2
        quadraticX, quadraticY = nil, nil
        x, y = nextX, nextY
      end
    elseif upper == "S" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 4, command)
        local x1 = previousKind == "C" and 2 * x - cubicX or x
        local y1 = previousKind == "C" and 2 * y - cubicY or y
        local x2 = relative and x + values[1] or values[1]
        local y2 = relative and y + values[2] or values[2]
        local nextX = relative and x + values[3] or values[3]
        local nextY = relative and y + values[4] or values[4]
        add({ "C", x1, y1, x2, y2, nextX, nextY })
        previousKind, cubicX, cubicY = "C", x2, y2
        quadraticX, quadraticY = nil, nil
        x, y = nextX, nextY
      end
    elseif upper == "Q" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 4, command)
        local x1 = relative and x + values[1] or values[1]
        local y1 = relative and y + values[2] or values[2]
        local nextX = relative and x + values[3] or values[3]
        local nextY = relative and y + values[4] or values[4]
        add({ "Q", x1, y1, nextX, nextY })
        previousKind, quadraticX, quadraticY = "Q", x1, y1
        cubicX, cubicY = nil, nil
        x, y = nextX, nextY
      end
    elseif upper == "T" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 2, command)
        local x1 = previousKind == "Q" and 2 * x - quadraticX or x
        local y1 = previousKind == "Q" and 2 * y - quadraticY or y
        local nextX = relative and x + values[1] or values[1]
        local nextY = relative and y + values[2] or values[2]
        add({ "Q", x1, y1, nextX, nextY })
        previousKind, quadraticX, quadraticY = "Q", x1, y1
        cubicX, cubicY = nil, nil
        x, y = nextX, nextY
      end
    elseif upper == "A" then
      while index <= #tokens and type(tokens[index]) ~= "string" do
        local values
        values, index = requireNumbers(tokens, index, 7, command)
        if (values[4] ~= 0 and values[4] ~= 1) or (values[5] ~= 0 and values[5] ~= 1) then
          error("SVG path command " .. command .. " flags must be 0 or 1", 2)
        end
        local nextX = relative and x + values[6] or values[6]
        local nextY = relative and y + values[7] or values[7]
        add({ "A", math.abs(values[1]), math.abs(values[2]), values[3], values[4], values[5], nextX, nextY })
        previousKind, cubicX, cubicY, quadraticX, quadraticY = "A", nil, nil, nil, nil
        x, y = nextX, nextY
      end
    end
  end

  return commands
end

local function normalizeLuaPath(path)
  local commands = {}
  local x, y = 0, 0
  local subpathX, subpathY = 0, 0
  local previousKind, cubicX, cubicY, quadraticX, quadraticY

  for _, command in ipairs(path or {}) do
    if type(command) ~= "table" or type(command[1]) ~= "string" then
      error("path command must be an array beginning with a command string", 3)
    end

    local raw = command[1]
    local upper = raw:upper()
    local relative = raw ~= upper
    if COMMANDS[upper] == nil then
      error("unsupported path command " .. tostring(raw), 3)
    end

    if upper == "Z" then
      commands[#commands + 1] = { "Z" }
      x, y = subpathX, subpathY
      previousKind, cubicX, cubicY, quadraticX, quadraticY = "Z", nil, nil, nil, nil
    elseif upper == "M" or upper == "L" then
      local nextX = tonumber(command[2])
      local nextY = tonumber(command[3])
      if nextX == nil or nextY == nil then
        error("path command " .. upper .. " requires x and y", 3)
      end
      if relative then
        nextX = x + nextX
        nextY = y + nextY
      end
      commands[#commands + 1] = { upper == "M" and "M" or "L", nextX, nextY }
      if upper == "M" then
        subpathX, subpathY = nextX, nextY
      end
      previousKind = upper == "M" and "M" or "L"
      cubicX, cubicY, quadraticX, quadraticY = nil, nil, nil, nil
      x, y = nextX, nextY
    elseif upper == "H" then
      local nextX = tonumber(command[2])
      if nextX == nil then
        error("path command H requires x", 3)
      end
      if relative then
        nextX = x + nextX
      end
      commands[#commands + 1] = { "L", nextX, y }
      previousKind, cubicX, cubicY, quadraticX, quadraticY = "L", nil, nil, nil, nil
      x = nextX
    elseif upper == "V" then
      local nextY = tonumber(command[2])
      if nextY == nil then
        error("path command V requires y", 3)
      end
      if relative then
        nextY = y + nextY
      end
      commands[#commands + 1] = { "L", x, nextY }
      previousKind, cubicX, cubicY, quadraticX, quadraticY = "L", nil, nil, nil, nil
      y = nextY
    elseif upper == "C" then
      local x1, y1, x2, y2, nextX, nextY = tonumber(command[2]), tonumber(command[3]), tonumber(command[4]), tonumber(command[5]), tonumber(command[6]), tonumber(command[7])
      if not x1 or not y1 or not x2 or not y2 or not nextX or not nextY then
        error("path command C requires six numbers", 3)
      end
      if relative then
        x1, y1, x2, y2, nextX, nextY = x + x1, y + y1, x + x2, y + y2, x + nextX, y + nextY
      end
      commands[#commands + 1] = { "C", x1, y1, x2, y2, nextX, nextY }
      previousKind, cubicX, cubicY = "C", x2, y2
      quadraticX, quadraticY = nil, nil
      x, y = nextX, nextY
    elseif upper == "S" then
      local x2, y2, nextX, nextY = tonumber(command[2]), tonumber(command[3]), tonumber(command[4]), tonumber(command[5])
      if not x2 or not y2 or not nextX or not nextY then
        error("path command S requires four numbers", 3)
      end
      if relative then
        x2, y2, nextX, nextY = x + x2, y + y2, x + nextX, y + nextY
      end
      local x1 = previousKind == "C" and 2 * x - cubicX or x
      local y1 = previousKind == "C" and 2 * y - cubicY or y
      commands[#commands + 1] = { "C", x1, y1, x2, y2, nextX, nextY }
      previousKind, cubicX, cubicY = "C", x2, y2
      quadraticX, quadraticY = nil, nil
      x, y = nextX, nextY
    elseif upper == "Q" then
      local x1, y1, nextX, nextY = tonumber(command[2]), tonumber(command[3]), tonumber(command[4]), tonumber(command[5])
      if not x1 or not y1 or not nextX or not nextY then
        error("path command Q requires four numbers", 3)
      end
      if relative then
        x1, y1, nextX, nextY = x + x1, y + y1, x + nextX, y + nextY
      end
      commands[#commands + 1] = { "Q", x1, y1, nextX, nextY }
      previousKind, quadraticX, quadraticY = "Q", x1, y1
      cubicX, cubicY = nil, nil
      x, y = nextX, nextY
    elseif upper == "T" then
      local nextX, nextY = tonumber(command[2]), tonumber(command[3])
      if not nextX or not nextY then
        error("path command T requires two numbers", 3)
      end
      if relative then nextX, nextY = x + nextX, y + nextY end
      local x1 = previousKind == "Q" and 2 * x - quadraticX or x
      local y1 = previousKind == "Q" and 2 * y - quadraticY or y
      commands[#commands + 1] = { "Q", x1, y1, nextX, nextY }
      previousKind, quadraticX, quadraticY = "Q", x1, y1
      cubicX, cubicY = nil, nil
      x, y = nextX, nextY
    elseif upper == "A" then
      local rx, ry, rotation = tonumber(command[2]), tonumber(command[3]), tonumber(command[4])
      local largeArc, sweep = tonumber(command[5]), tonumber(command[6])
      local nextX, nextY = tonumber(command[7]), tonumber(command[8])
      if not rx or not ry or not rotation or largeArc == nil or sweep == nil or not nextX or not nextY then
        error("path command A requires seven numbers", 3)
      end
      if (largeArc ~= 0 and largeArc ~= 1) or (sweep ~= 0 and sweep ~= 1) then
        error("path command A flags must be 0 or 1", 3)
      end
      if relative then nextX, nextY = x + nextX, y + nextY end
      commands[#commands + 1] = { "A", math.abs(rx), math.abs(ry), rotation, largeArc, sweep, nextX, nextY }
      previousKind, cubicX, cubicY, quadraticX, quadraticY = "A", nil, nil, nil, nil
      x, y = nextX, nextY
    end
  end

  return commands
end

function Path.parse(d)
  if type(d) ~= "string" then
    error("ui.path.parse expects an SVG path data string", 2)
  end

  local cached = parseCache[d]
  if cached then
    return copyCommands(cached)
  end

  local commands = parseTokens(tokenize(d))
  parseCache[d] = copyCommands(commands)
  return commands
end

function Path.normalize(path)
  if type(path) == "string" then
    return Path.parse(path)
  elseif type(path) == "table" then
    return normalizeLuaPath(path)
  end

  error("path must be SVG path data or a Lua command array", 2)
end

local function include(bounds, x, y)
  if x == nil or y == nil then
    return
  end

  if bounds.minX == nil then
    bounds.minX, bounds.maxX = x, x
    bounds.minY, bounds.maxY = y, y
    return
  end

  bounds.minX = math.min(bounds.minX, x)
  bounds.maxX = math.max(bounds.maxX, x)
  bounds.minY = math.min(bounds.minY, y)
  bounds.maxY = math.max(bounds.maxY, y)
end

local function boundsFromFlat(points)
  local raw = {}
  for index = 1, #points, 2 do
    include(raw, points[index], points[index + 1])
  end
  if raw.minX == nil then
    return { x = 0, y = 0, width = 0, height = 0 }
  end
  return {
    x = raw.minX,
    y = raw.minY,
    width = raw.maxX - raw.minX,
    height = raw.maxY - raw.minY,
  }
end

local function normalizedViewBox(viewBox)
  if viewBox == nil then
    return nil
  end

  local x, y, width, height
  if type(viewBox) == "string" then
    local values = {}
    for value in viewBox:gmatch("[-+]?%d*%.?%d+[eE]?[-+]?%d*") do
      values[#values + 1] = tonumber(value)
    end
    x, y, width, height = values[1], values[2], values[3], values[4]
  elseif type(viewBox) == "table" then
    x = tonumber(viewBox.x ~= nil and viewBox.x or viewBox[1])
    y = tonumber(viewBox.y ~= nil and viewBox.y or viewBox[2])
    width = tonumber(viewBox.width ~= nil and viewBox.width or viewBox[3])
    height = tonumber(viewBox.height ~= nil and viewBox.height or viewBox[4])
  end

  if x == nil or y == nil or width == nil or height == nil or width <= 0 or height <= 0 then
    error("path viewBox must contain x, y, width, and height with positive dimensions", 3)
  end

  return { x = x, y = y, width = width, height = height }
end

local function vectorAngle(ux, uy, vx, vy)
  local ul = math.sqrt(ux * ux + uy * uy)
  local vl = math.sqrt(vx * vx + vy * vy)
  if ul == 0 or vl == 0 then return 0 end
  local angle = math.acos(clamp((ux * vx + uy * vy) / (ul * vl), -1, 1))
  return ux * vy - uy * vx < 0 and -angle or angle
end

-- SVG endpoint-to-center conversion from the path implementation notes.
local function arcParameters(x1, y1, command)
  local rx, ry = math.abs(command[2]), math.abs(command[3])
  local x2, y2 = command[7], command[8]
  if rx == 0 or ry == 0 or (x1 == x2 and y1 == y2) then return nil end

  local phi = math.rad(command[4] % 360)
  local cosPhi, sinPhi = math.cos(phi), math.sin(phi)
  local dx, dy = (x1 - x2) * 0.5, (y1 - y2) * 0.5
  local px = cosPhi * dx + sinPhi * dy
  local py = -sinPhi * dx + cosPhi * dy
  local radii = px * px / (rx * rx) + py * py / (ry * ry)
  if radii > 1 then
    local scale = math.sqrt(radii)
    rx, ry = rx * scale, ry * scale
  end

  local numerator = math.max(0,
    rx * rx * ry * ry - rx * rx * py * py - ry * ry * px * px)
  local denominator = rx * rx * py * py + ry * ry * px * px
  local coefficient = denominator == 0 and 0 or math.sqrt(numerator / denominator)
  if (command[5] ~= 0) == (command[6] ~= 0) then coefficient = -coefficient end
  local cxPrime = coefficient * (rx * py / ry)
  local cyPrime = coefficient * (-ry * px / rx)
  local cx = cosPhi * cxPrime - sinPhi * cyPrime + (x1 + x2) * 0.5
  local cy = sinPhi * cxPrime + cosPhi * cyPrime + (y1 + y2) * 0.5
  local ux, uy = (px - cxPrime) / rx, (py - cyPrime) / ry
  local vx, vy = (-px - cxPrime) / rx, (-py - cyPrime) / ry
  local startAngle = vectorAngle(1, 0, ux, uy)
  local sweepAngle = vectorAngle(ux, uy, vx, vy)
  if command[6] == 0 and sweepAngle > 0 then
    sweepAngle = sweepAngle - math.pi * 2
  elseif command[6] ~= 0 and sweepAngle < 0 then
    sweepAngle = sweepAngle + math.pi * 2
  end
  return { cx = cx, cy = cy, rx = rx, ry = ry, phi = phi,
    startAngle = startAngle, sweepAngle = sweepAngle }
end

local function arcPoint(arc, angle)
  local cosPhi, sinPhi = math.cos(arc.phi), math.sin(arc.phi)
  local x, y = arc.rx * math.cos(angle), arc.ry * math.sin(angle)
  return arc.cx + cosPhi * x - sinPhi * y,
    arc.cy + sinPhi * x + cosPhi * y
end

function Path.bounds(path)
  local commands = Path.normalize(path)
  local raw = {}
  local x, y = 0, 0
  local subpathX, subpathY = 0, 0

  for _, command in ipairs(commands) do
    local kind = command[1]
    if kind == "M" or kind == "L" then
      include(raw, command[2], command[3])
      x, y = command[2], command[3]
      if kind == "M" then subpathX, subpathY = x, y end
    elseif kind == "C" then
      include(raw, command[2], command[3])
      include(raw, command[4], command[5])
      include(raw, command[6], command[7])
      x, y = command[6], command[7]
    elseif kind == "Q" then
      include(raw, command[2], command[3])
      include(raw, command[4], command[5])
      x, y = command[4], command[5]
    elseif kind == "A" then
      local arc = arcParameters(x, y, command)
      if arc then
        local steps = math.max(4, math.ceil(32 * math.abs(arc.sweepAngle) / (math.pi * 2)))
        for step = 0, steps do
          local px, py = arcPoint(arc, arc.startAngle + arc.sweepAngle * step / steps)
          include(raw, px, py)
        end
      else
        include(raw, command[7], command[8])
      end
      x, y = command[7], command[8]
    elseif kind == "Z" then
      x, y = subpathX, subpathY
    end
  end

  if raw.minX == nil then
    return { x = 0, y = 0, width = 0, height = 0 }
  end

  return {
    x = raw.minX,
    y = raw.minY,
    width = raw.maxX - raw.minX,
    height = raw.maxY - raw.minY,
  }
end

local function addPoint(points, x, y)
  local count = #points
  if count >= 2 and points[count - 1] == x and points[count] == y then
    return
  end
  points[count + 1] = x
  points[count + 2] = y
end

local function flattenCommands(commands, samples)
  local points = {}
  local x, y = 0, 0
  local subpathX, subpathY = 0, 0
  local steps = math.max(1, math.floor(tonumber(samples) or DEFAULT_SAMPLES))

  for _, command in ipairs(commands) do
    local kind = command[1]
    if kind == "M" then
      x, y = command[2], command[3]
      subpathX, subpathY = x, y
      addPoint(points, x, y)
    elseif kind == "L" then
      x, y = command[2], command[3]
      addPoint(points, x, y)
    elseif kind == "C" then
      local sx, sy = x, y
      for step = 1, steps do
        local t = step / steps
        local mt = 1 - t
        local nextX = mt * mt * mt * sx + 3 * mt * mt * t * command[2] + 3 * mt * t * t * command[4] + t * t * t * command[6]
        local nextY = mt * mt * mt * sy + 3 * mt * mt * t * command[3] + 3 * mt * t * t * command[5] + t * t * t * command[7]
        addPoint(points, nextX, nextY)
      end
      x, y = command[6], command[7]
    elseif kind == "Q" then
      local sx, sy = x, y
      for step = 1, steps do
        local t = step / steps
        local mt = 1 - t
        local nextX = mt * mt * sx + 2 * mt * t * command[2] + t * t * command[4]
        local nextY = mt * mt * sy + 2 * mt * t * command[3] + t * t * command[5]
        addPoint(points, nextX, nextY)
      end
      x, y = command[4], command[5]
    elseif kind == "A" then
      local arc = arcParameters(x, y, command)
      if arc then
        local arcSteps = math.max(1,
          math.ceil(steps * math.abs(arc.sweepAngle) / (math.pi * 2)))
        for step = 1, arcSteps do
          local nextX, nextY = arcPoint(arc,
            arc.startAngle + arc.sweepAngle * step / arcSteps)
          addPoint(points, nextX, nextY)
        end
      else
        addPoint(points, command[7], command[8])
      end
      x, y = command[7], command[8]
    elseif kind == "Z" then
      x, y = subpathX, subpathY
      addPoint(points, x, y)
    end
  end

  return points
end

function Path.flatten(path, opts)
  opts = opts or {}
  local samples = math.max(1, math.floor(tonumber(opts.samples) or DEFAULT_SAMPLES))

  if type(path) == "string" then
    local key = path .. "|" .. tostring(samples)
    local cached = flattenCache[key]
    if cached then
      return copyPoints(cached)
    end
    local points = flattenCommands(Path.parse(path), samples)
    flattenCache[key] = copyPoints(points)
    return points
  end

  return flattenCommands(Path.normalize(path), samples)
end

local function polylineLength(points)
  local total = 0
  for index = 3, #points, 2 do
    local dx = points[index] - points[index - 2]
    local dy = points[index + 1] - points[index - 1]
    total = total + math.sqrt(dx * dx + dy * dy)
  end
  return total
end

function Path.length(path, opts)
  if type(path) == "table" and type(path[1]) == "number" then
    return polylineLength(path)
  end
  return polylineLength(Path.flatten(path, opts))
end

local function pointAtDistance(points, distance)
  if #points < 2 then
    return 0, 0
  end

  if distance <= 0 then
    return points[1], points[2]
  end

  local traveled = 0
  for index = 3, #points, 2 do
    local x1, y1 = points[index - 2], points[index - 1]
    local x2, y2 = points[index], points[index + 1]
    local dx, dy = x2 - x1, y2 - y1
    local segmentLength = math.sqrt(dx * dx + dy * dy)
    if traveled + segmentLength >= distance then
      local t = segmentLength > 0 and ((distance - traveled) / segmentLength) or 0
      return x1 + dx * t, y1 + dy * t
    end
    traveled = traveled + segmentLength
  end

  return points[#points - 1], points[#points]
end

function Path.reveal(points, progress)
  progress = clamp(progress == nil and 1 or progress, 0, 1)
  if progress >= 1 then
    return copyPoints(points)
  end
  if #points < 2 then
    return {}
  end

  local target = polylineLength(points) * progress
  local result = { points[1], points[2] }
  if target <= 0 then
    return result
  end

  local traveled = 0
  for index = 3, #points, 2 do
    local x1, y1 = points[index - 2], points[index - 1]
    local x2, y2 = points[index], points[index + 1]
    local dx, dy = x2 - x1, y2 - y1
    local segmentLength = math.sqrt(dx * dx + dy * dy)

    if traveled + segmentLength < target then
      addPoint(result, x2, y2)
      traveled = traveled + segmentLength
    else
      local t = segmentLength > 0 and ((target - traveled) / segmentLength) or 0
      addPoint(result, x1 + dx * t, y1 + dy * t)
      break
    end
  end

  return result
end

function Path.resample(points, count)
  count = math.max(2, math.floor(tonumber(count) or DEFAULT_SAMPLES))
  if #points < 2 then
    return {}
  end

  local total = polylineLength(points)
  local result = {}
  if total <= 0 then
    for _ = 1, count do
      result[#result + 1] = points[1]
      result[#result + 1] = points[2]
    end
    return result
  end

  for index = 0, count - 1 do
    local x, y = pointAtDistance(points, total * (index / (count - 1)))
    result[#result + 1] = x
    result[#result + 1] = y
  end
  return result
end

function Path.morphCompatible(fromPath, toPath, t)
  local fromCommands = Path.normalize(fromPath)
  local toCommands = Path.normalize(toPath)
  t = clamp(t or 0, 0, 1)

  if #fromCommands ~= #toCommands then
    error("compatible path morph requires the same command count", 2)
  end

  local result = {}
  for index, fromCommand in ipairs(fromCommands) do
    local toCommand = toCommands[index]
    if fromCommand[1] ~= toCommand[1] or #fromCommand ~= #toCommand then
      error("compatible path morph requires matching command sequences", 2)
    end

    local command = { fromCommand[1] }
    for valueIndex = 2, #fromCommand do
      command[valueIndex] = fromCommand[valueIndex] + (toCommand[valueIndex] - fromCommand[valueIndex]) * t
    end
    result[index] = command
  end

  return result
end

function Path.morphResample(fromPath, toPath, t, opts)
  opts = opts or {}
  local count = math.max(2, math.floor(tonumber(opts.samples) or DEFAULT_SAMPLES))
  local fromPoints = Path.resample(Path.flatten(fromPath, opts), count)
  local toPoints = Path.resample(Path.flatten(toPath, opts), count)
  t = clamp(t or 0, 0, 1)

  local result = {}
  for index = 1, math.min(#fromPoints, #toPoints), 2 do
    result[#result + 1] = fromPoints[index] + (toPoints[index] - fromPoints[index]) * t
    result[#result + 1] = fromPoints[index + 1] + (toPoints[index + 1] - fromPoints[index + 1]) * t
  end
  return result
end

local function axisOffset(align, remaining)
  if align == "start" or align == "left" or align == "top" then
    return 0
  elseif align == "end" or align == "right" or align == "bottom" then
    return remaining
  end
  return remaining / 2
end

function Path.transform(points, sourceBounds, bounds, opts)
  opts = opts or {}
  bounds = bounds or sourceBounds or { x = 0, y = 0, width = 0, height = 0 }
  sourceBounds = sourceBounds or boundsFromFlat(points)

  local naturalWidth = sourceBounds.width
  local naturalHeight = sourceBounds.height
  local safeWidth = naturalWidth ~= 0 and naturalWidth or 1
  local safeHeight = naturalHeight ~= 0 and naturalHeight or 1
  local fit = opts.fit or "contain"
  local scaleX, scaleY = 1, 1
  local drawWidth, drawHeight = naturalWidth, naturalHeight

  if fit == "stretch" then
    scaleX = bounds.width / safeWidth
    scaleY = bounds.height / safeHeight
    drawWidth = bounds.width
    drawHeight = bounds.height
  elseif fit == "none" then
    scaleX, scaleY = 1, 1
  else
    local scale = math.min(bounds.width / safeWidth, bounds.height / safeHeight)
    scaleX, scaleY = scale, scale
    drawWidth = naturalWidth * scale
    drawHeight = naturalHeight * scale
  end

  local offsetX = axisOffset(opts.align or "center", bounds.width - drawWidth)
  local offsetY = axisOffset(opts.valign or "center", bounds.height - drawHeight)
  local result = {}

  for index = 1, #points, 2 do
    result[#result + 1] = bounds.x + offsetX + (points[index] - sourceBounds.x) * scaleX
    result[#result + 1] = bounds.y + offsetY + (points[index + 1] - sourceBounds.y) * scaleY
  end

  return result
end

local function splitCommands(commands)
  local subpaths = {}
  local current = nil

  for _, command in ipairs(commands) do
    if command[1] == "M" then
      current = { command }
      subpaths[#subpaths + 1] = current
    elseif current then
      current[#current + 1] = command
    end
  end

  return subpaths
end

local function commandVertices(commands)
  local points = {}
  local startX, startY
  for _, command in ipairs(commands) do
    local kind = command[1]
    local x, y
    if kind == "M" or kind == "L" then
      x, y = command[2], command[3]
      if kind == "M" then
        startX, startY = x, y
      end
    elseif kind == "C" then
      x, y = command[6], command[7]
    elseif kind == "Q" then
      x, y = command[4], command[5]
    elseif kind == "A" then
      x, y = command[7], command[8]
    elseif kind == "Z" then
      x, y = startX, startY
    end
    if x ~= nil and y ~= nil then
      addPoint(points, x, y)
    end
  end
  return points
end

---Return independently drawable contours while preserving SVG moveto boundaries.
---@param path string|table
---@param bounds table
---@param opts? table
---@return table[]
function Path.contours(path, bounds, opts)
  opts = opts or {}
  local morphTo = opts.morphTo
  local morph = clamp(opts.morph or 0, 0, 1)
  if morphTo ~= nil and morph > 0 then
    local points = Path.points(path, bounds, opts)
    return { {
      points = points,
      vertices = #points >= 4 and { points[1], points[2], points[#points - 1], points[#points] } or copyPoints(points),
      closed = #points >= 4 and points[1] == points[#points - 1] and points[2] == points[#points],
    } }
  end

  local commands = Path.normalize(path)
  local sourceBounds = normalizedViewBox(opts.viewBox) or Path.bounds(commands)
  local contours = {}
  for _, subpath in ipairs(splitCommands(commands)) do
    local flat = Path.flatten(subpath, { samples = opts.samples })
    if #flat >= 2 then
      contours[#contours + 1] = {
        points = Path.transform(flat, sourceBounds, bounds, opts),
        vertices = Path.transform(commandVertices(subpath), sourceBounds, bounds, opts),
        closed = subpath[#subpath] and subpath[#subpath][1] == "Z" or false,
      }
    end
  end
  return contours
end

---Return the uniform stroke scale introduced by fitting a viewBox into bounds.
---@param viewBox table|string
---@param bounds table
---@param opts? table
---@return number
function Path.strokeScale(viewBox, bounds, opts)
  opts = opts or {}
  local source = normalizedViewBox(viewBox)
  local scaleX = bounds.width / source.width
  local scaleY = bounds.height / source.height
  if (opts.fit or "contain") == "none" then
    return 1
  elseif opts.fit == "stretch" then
    return math.min(math.abs(scaleX), math.abs(scaleY))
  end
  return math.min(math.abs(scaleX), math.abs(scaleY))
end

function Path.points(path, bounds, opts)
  opts = opts or {}
  local morphTo = opts.morphTo
  local morph = clamp(opts.morph or 0, 0, 1)
  local samples = opts.samples or DEFAULT_SAMPLES

  local points
  local sourceBounds
  if morphTo ~= nil and morph > 0 and opts.morphMode == "resample" then
    points = Path.morphResample(path, morphTo, morph, { samples = samples })
    sourceBounds = normalizedViewBox(opts.viewBox) or boundsFromFlat(points)
  else
    local commands = path
    if morphTo ~= nil and morph > 0 then
      commands = Path.morphCompatible(path, morphTo, morph)
    end
    points = Path.flatten(commands, { samples = samples })
    sourceBounds = normalizedViewBox(opts.viewBox) or Path.bounds(commands)
  end

  return Path.transform(points, sourceBounds, bounds, opts)
end

return Path
