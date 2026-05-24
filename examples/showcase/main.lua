package.path = "?.lua;?/init.lua;examples/?/example.lua;examples/?.lua;../../?.lua;../../?/init.lua;../?/example.lua;" .. package.path

local ui = require("glyph")

local examples = {
	{ id = "basic", label = "Basic", module = "basic" },
	{ id = "dashboard", label = "Dashboard", module = "dashboard" },
	{ id = "hud-menu", label = "HUD Menu", module = "hud-menu" },
	{ id = "modal", label = "Modal", module = "modal" },
	{ id = "performance", label = "Performance", module = "performance" },
	{ id = "scene", label = "Scene", module = "scene" },
	{ id = "settings", label = "Settings", module = "settings" },
	{ id = "styles", label = "Styles", module = "styles" },
}

local active = nil
local activeId = nil

local function clone(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		if key ~= "version" then
			copy[key] = clone(item)
		end
	end
	return copy
end

local baseTheme = clone(ui.theme)

local function restoreTable(target, source)
	for key in pairs(target) do
		if key ~= "version" and source[key] == nil then
			target[key] = nil
		end
	end

	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = target[key] or {}
			restoreTable(target[key], value)
		else
			target[key] = value
		end
	end
end

local function restoreBaseTheme()
	restoreTable(ui.theme, baseTheme)
	ui.theme.version = (ui.theme.version or 0) + 1
	ui.runtime.styleCache = {}
	ui.runtime:markDirty()
end

local function findExample(id)
	for _, item in ipairs(examples) do
		if item.id == id then
			return item
		end
	end
	return examples[1]
end

local function call(example, name, ...)
	local fn = example and example[name]
	if type(fn) == "function" then
		return fn(...)
	end
	return nil
end

local function nav()
	local buttons = {}
	for _, item in ipairs(examples) do
		buttons[#buttons + 1] = ui.button({
			label = item.label,
			width = 138,
			active = activeId == item.id,
			onClick = function()
				if activeId ~= item.id then
					switchExample(item.id)
				end
			end,
			style = {
				background = activeId == item.id and { 0.18, 0.38, 0.72, 0.92 } or { 0.03, 0.04, 0.055, 0.9 },
				color = { 0.94, 0.96, 1, 1 },
				borderColor = activeId == item.id and { 0.52, 0.74, 1, 1 } or { 1, 1, 1, 0.16 },
				borderWidth = 1,
				radius = 6,
				hover = { background = { 0.14, 0.2, 0.29, 0.94 } },
			},
		})
	end

	return ui.column({
		position = "absolute",
		top = 12,
		left = 12,
		width = 166,
		padding = 10,
		gap = 7,
		zIndex = 100,
		style = {
			background = { 0.02, 0.025, 0.032, 0.88 },
			borderColor = { 1, 1, 1, 0.16 },
			borderWidth = 1,
			radius = 8,
		},
	}, {
		ui.text("Showcase", { style = { color = { 1, 1, 1, 1 } } }),
		ui.text("real examples", { style = { color = { 0.68, 0.74, 0.82, 1 } } }),
		ui.column({ gap = 6 }, buttons),
	})
end

local function App()
	local child = nil
	if active and active.component then
		child = active.component("showcase")
	end

	return ui.stack({
		width = "100%",
		height = "100%",
	}, {
		child or ui.box({ width = "100%", height = "100%" }),
		nav(),
	})
end

function switchExample(id)
	if active then
		call(active, "teardown", "showcase")
	end

	ui.modal.closeAll()
	restoreBaseTheme()

	local item = findExample(id)
	package.loaded[item.module] = nil
	active = require(item.module)
	activeId = item.id

	call(active, "setup", "showcase")
	ui.scene.set("showcase:" .. item.id, App, {
		transition = ui.transitions.fade({ duration = 0.12 }),
	})
end

function love.wheelmoved(dx, dy)
	call(active, "wheelmoved", dx, dy, "showcase")
end

function love.keypressed(key)
	call(active, "keypressed", key, "showcase")
end

function love.load()
	ui.load({
		window = {
			width = 1040,
			height = 700,
			resizable = true,
			minWidth = 720,
			minHeight = 520,
			breakpoints = { md = 820 },
			title = "glyph - real examples showcase",
		},
	})
	switchExample("basic")
end

function love.update(dt)
	call(active, "update", dt, "showcase")
	ui.update(dt)
end

function love.draw()
	if active then
		call(active, "beforeDraw", "showcase")
	else
		love.graphics.clear(0.04, 0.05, 0.06, 1)
	end
	ui.render()
end
