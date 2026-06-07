local moduleName = ...

if not moduleName or moduleName == "" then
  return require("feel.init")
end

return require(moduleName .. ".init")
