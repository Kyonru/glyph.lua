local Filter = {}

local function mode(value)
  if value == "nearest" or value == "linear" then
    return value
  end
  return nil
end

local function matches(current, resolved)
  if not current or not resolved then
    return false
  end
  if current.min ~= resolved.min or (current.mag or current.min) ~= (resolved.mag or resolved.min) then
    return false
  end
  return resolved.anisotropy == nil or current.anisotropy == resolved.anisotropy
end

function Filter.resolve(spec, fallback)
  if spec == nil then
    spec = fallback
  end
  if spec == nil or spec == false then
    return nil
  end

  if type(spec) == "string" then
    local value = mode(spec)
    if value then
      return { min = value, mag = value }
    end
    return nil
  end

  if type(spec) ~= "table" then
    return nil
  end

  local base = mode(spec.filter or spec.mode or spec.type)
  local min = mode(spec.min or spec.minFilter or base)
  local mag = mode(spec.mag or spec.magFilter or base or min)
  if not min and mag then
    min = mag
  end
  if not min then
    return nil
  end

  return {
    min = min,
    mag = mag or min,
    anisotropy = tonumber(spec.anisotropy),
  }
end

function Filter.fromFields(source, fallback)
  if type(source) ~= "table" then
    return Filter.resolve(nil, fallback)
  end

  local spec = source.filter
  if spec == nil and (source.min ~= nil or source.mag ~= nil or source.minFilter ~= nil or source.magFilter ~= nil or source.anisotropy ~= nil) then
    spec = source
  end
  return Filter.resolve(spec, fallback)
end

function Filter.key(spec)
  local resolved = Filter.resolve(spec)
  if not resolved then
    return ""
  end
  return table.concat({
    resolved.min or "",
    resolved.mag or "",
    tostring(resolved.anisotropy or ""),
  }, "|")
end

function Filter.capture(target)
  if not target or type(target.getFilter) ~= "function" then
    return nil
  end

  local ok, min, mag, anisotropy = pcall(target.getFilter, target)
  if not ok then
    return nil
  end
  return { min = min, mag = mag, anisotropy = anisotropy }
end

function Filter.apply(target, spec, fallback)
  local resolved = Filter.resolve(spec, fallback)
  if not resolved or not target or type(target.setFilter) ~= "function" then
    return false
  end
  local current = Filter.capture(target)
  if matches(current, resolved) then
    return true, false
  end

  local ok = pcall(target.setFilter, target, resolved.min, resolved.mag or resolved.min, resolved.anisotropy)
  return ok, ok
end

function Filter.applyTemporary(target, spec, fallback)
  local resolved = Filter.resolve(spec, fallback)
  if not resolved or not target or type(target.setFilter) ~= "function" then
    return nil
  end

  local previous = Filter.capture(target)
  if matches(previous, resolved) then
    return nil
  end
  local ok = pcall(target.setFilter, target, resolved.min, resolved.mag or resolved.min, resolved.anisotropy)
  if ok then
    return previous or false
  end
  return nil
end

function Filter.restore(target, previous)
  if not previous or not target or type(target.setFilter) ~= "function" then
    return false
  end

  local ok = pcall(target.setFilter, target, previous.min, previous.mag or previous.min, previous.anisotropy)
  return ok
end

function Filter.with(target, spec, fn, fallback)
  local resolved = Filter.resolve(spec, fallback)
  if not resolved then
    return fn()
  end

  local previous = Filter.applyTemporary(target, resolved)
  local ok, a, b, c, d = pcall(fn)
  if previous then
    Filter.restore(target, previous)
  end
  if not ok then
    error(a, 0)
  end
  return a, b, c, d
end

return Filter
