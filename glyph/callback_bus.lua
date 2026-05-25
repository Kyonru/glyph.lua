local CallbackBus = {}
CallbackBus.__index = CallbackBus

local function normalizedPriority(priority)
  if priority == nil then
    return 0
  end

  return priority
end

local function sortRegistrations(registrations)
  table.sort(registrations, function(a, b)
    local aPriority = normalizedPriority(a.priority)
    local bPriority = normalizedPriority(b.priority)

    if aPriority == bPriority then
      return a.order < b.order
    end

    return aPriority < bPriority
  end)
end

function CallbackBus.new(callbackNames)
  local self = setmetatable({
    registrations = {},
    allowedCallbacks = {},
    nextOrder = 0,
  }, CallbackBus)

  for _, name in ipairs(callbackNames or {}) do
    self.allowedCallbacks[name] = true
    self.registrations[name] = {}
  end

  return self
end

function CallbackBus:isSupported(name)
  return self.allowedCallbacks[name] == true
end

function CallbackBus:assertSupported(name)
  if not self:isSupported(name) then
    error("[GlyphCallbackBus] Unsupported callback: " .. tostring(name), 3)
  end
end

function CallbackBus:register(name, fn, opts)
  self:assertSupported(name)

  if type(fn) ~= "function" then
    error("[GlyphCallbackBus] Callback handler must be a function", 2)
  end

  if opts ~= nil and type(opts) ~= "table" then
    error("[GlyphCallbackBus] Callback options must be a table", 2)
  end

  local priority = opts and opts.priority or nil
  if priority ~= nil and type(priority) ~= "number" then
    error("[GlyphCallbackBus] Callback priority must be a number", 2)
  end

  self.nextOrder = self.nextOrder + 1

  local entry = {
    fn = fn,
    order = self.nextOrder,
    priority = priority,
    active = true,
  }

  local registrations = self.registrations[name]
  registrations[#registrations + 1] = entry
  sortRegistrations(registrations)

  return function()
    if not entry.active then
      return false
    end

    entry.active = false

    for index, candidate in ipairs(registrations) do
      if candidate == entry then
        table.remove(registrations, index)
        return true
      end
    end

    return false
  end
end

function CallbackBus:dispatch(name, ...)
  self:assertSupported(name)

  local registrations = self.registrations[name]
  local snapshot = {}

  for index = 1, #registrations do
    snapshot[index] = registrations[index]
  end

  for _, entry in ipairs(snapshot) do
    if entry.active then
      entry.fn(...)
    end
  end
end

function CallbackBus:dispatchUntil(name, predicate, ...)
  self:assertSupported(name)

  local registrations = self.registrations[name]
  local snapshot = {}

  for index = 1, #registrations do
    snapshot[index] = registrations[index]
  end

  for _, entry in ipairs(snapshot) do
    if entry.active then
      local result = entry.fn(...)
      if predicate(result) then
        return result
      end
    end
  end

  return nil
end

return CallbackBus
