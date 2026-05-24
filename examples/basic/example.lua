local ui = require("glyph")

local filter = ""
local activeTab = 1
local logs = {
  { message = "Renderer attached" },
  { message = "Frame graph rebuilt" },
  { message = "Inspector focused" },
  { message = "Timeline marker added" },
}

local function App()
  local count, setCount = ui.useState(0)

  local filtered = {}
  for _, log in ipairs(logs) do
    if filter == "" or log.message:lower():find(filter:lower(), 1, true) then
      filtered[#filtered + 1] = ui.text(log.message)
    end
  end

  return ui.panel({ title = "Feather Debugger", width = 360, padding = 12, gap = 10, borderColor = ui.theme.borderColor }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.button({
        label = "Increment",
        onClick = function()
          setCount(count + 1)
        end,
      }),
      ui.text("Count: " .. count),
    }),

    ui.tabs({
      active = activeTab,
      onChange = function(index)
        activeTab = index
      end,
    }, {
      {
        label = "Logs",
        content = ui.column({ gap = 8 }, {
          ui.input({
            placeholder = "Filter logs...",
            value = filter,
            onChange = function(nextValue)
              filter = nextValue
            end,
          }),
          ui.scrollView({ width = 320, height = 120, gap = 4, borderColor = ui.theme.borderColor, padding = 8 }, filtered),
        }),
      },
      {
        label = "Custom",
        content = ui.box({
          width = 320,
          height = 80,
          draw = function(_, x, y, width, height, love)
            love.graphics.setColor(0.24, 0.54, 0.95, 1)
            love.graphics.rectangle("fill", x, y, width, height, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Custom drawn widget", x + 12, y + 28)
          end,
        }),
      },
    }),
  })
end

return {
  id = "basic",
  label = "Basic",
  component = function()
    return App()
  end,
}
