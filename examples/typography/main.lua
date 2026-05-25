package.path = "?.lua;?/init.lua;examples/?.lua;examples/typography/?.lua;../?.lua;../?/init.lua;../../?.lua;../../?/init.lua;" .. package.path

local Runner = require("runner")
local example = require("example")

Runner.run(example)
