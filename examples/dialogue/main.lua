package.path = "?.lua;?/init.lua;vendor/?.lua;vendor/?/init.lua;examples/?.lua;examples/dialogue/?.lua;examples/dialogue/vendor/?.lua;examples/dialogue/vendor/?/init.lua;dev/vendor/?.lua;../dev/vendor/?.lua;../../dev/vendor/?.lua;../?.lua;../?/init.lua;../../?.lua;../../?/init.lua;"
	.. package.path

local Runner = require("runner")
local example = require("example")

Runner.run(example)
