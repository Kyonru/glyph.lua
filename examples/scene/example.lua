local ui = require("glyph")

local BG = { 0.06, 0.07, 0.09, 1 }
local SURFACE = { 0.12, 0.13, 0.16, 1 }
local TEXT = { 0.92, 0.94, 0.96, 1 }
local MUTED = { 0.56, 0.60, 0.66, 1 }
local ACCENT = { 0.36, 0.72, 1.0, 1 }
local sceneTime = 0
local activeMode = "standalone"
local showcaseScene = "home"

local function layerId(id)
	if activeMode == "showcase" then
		return "scene-demo:" .. id
	end
	return id
end

local function screen(title, subtitle, accent, navTarget)
	return ui.column({
		width = "100%",
		height = "100%",
		padding = 28,
		gap = 16,
		style = { background = BG },
	}, {
		ui.row({ width = "100%", align = "center" }, {
			ui.column({ flex = 1, gap = 4 }, {
				ui.text(title, { style = { color = TEXT } }),
				ui.text(subtitle, { style = { color = MUTED } }),
			}),
			ui.button({
				label = "Debug Overlay",
				onClick = function()
					ui.scene.push(layerId("debug"), DebugOverlay, {
						kind = "overlay",
						input = false,
						blocking = false,
						transition = "fade",
						duration = 0.12,
					})
				end,
			}),
		}),

		ui.box({
			flex = 1,
			width = "100%",
			display = "column",
			padding = 24,
			gap = 10,
			style = {
				background = { accent[1], accent[2], accent[3], 0.08 },
				borderColor = { accent[1], accent[2], accent[3], 0.28 },
				borderWidth = 1,
				radius = 10,
			},
			draw = function(_, x, y, width, height, love, _, ctx)
				ctx:color({ accent[1], accent[2], accent[3], 0.12 })
				for index = 0, 10 do
					local lx = x + index * width / 10
					ctx:line(lx, y, lx + 80, y + height)
				end

				local trackY = y + height * 0.64
				local trackLeft = x + 42
				local trackRight = x + width - 42
				local span = math.max(1, trackRight - trackLeft)
				local t = (math.sin(sceneTime * 1.6) + 1) / 2
				local px = trackLeft + span * t
				local pulse = (math.sin(sceneTime * 5.4) + 1) / 2

				ctx:color({ accent[1], accent[2], accent[3], 0.22 })
				ctx:line(trackLeft, trackY, trackRight, trackY)
				ctx:color({ accent[1], accent[2], accent[3], 0.16 + pulse * 0.12 })
				love.graphics.circle("fill", px, trackY, 34 + pulse * 10)
				ctx:color({ 0.94, 0.97, 1.0, 1 })
				love.graphics.circle("fill", px, trackY, 10)
				ctx:color({ 0.08, 0.10, 0.14, 1 })
				love.graphics.circle("fill", px + 3, trackY - 3, 3)
			end,
		}, {
			ui.text("This is a native Glyph scene layer.", { style = { color = TEXT } }),
			ui.text("Scenes, overlays, and modals share the same stack and transition pipeline.", {
				wrap = true,
				width = 520,
				style = { color = MUTED },
			}),
			ui.text("The moving probe pauses with the modal, but keeps running under the debug overlay.", {
				wrap = true,
				width = 520,
				style = { color = MUTED },
			}),
		}),

		ui.row({ gap = 10 }, {
			ui.button({
				label = "Go To Inventory",
				onClick = function()
					local targetName = navTarget or "home"
					local targetScene = targetName == "home" and HomeScene or InventoryScene

					if activeMode == "showcase" then
						showcaseScene = targetName
					else
						ui.scene.set(targetName, targetScene, {
							transition = ui.transitions.slide({ direction = "up", duration = 0.24 }),
						})
					end
				end,
			}),
			ui.button({
				label = "Pause Menu",
				onClick = function()
					ui.scene.push(layerId("pause"), PauseMenu, {
						kind = "modal",
						width = 420,
						height = 260,
						dismissOnBackdrop = true,
						transition = ui.transitions.scale({ duration = 0.18 }),
					})
				end,
			}),
		}),
	})
end

function HomeScene()
	return screen("Home Scene", "Main scene replacement with ui.scene.set.", ACCENT, "inventory")
end

function InventoryScene()
	return screen("Inventory Scene", "This screen replaced the previous root scene.", { 0.68, 0.50, 1.0, 1 }, "home")
end

function PauseMenu()
	return ui.column({
		width = 420,
		height = 260,
		padding = 24,
		gap = 14,
		style = {
			background = SURFACE,
			borderColor = { ACCENT[1], ACCENT[2], ACCENT[3], 0.35 },
			borderWidth = 1,
			radius = 12,
		},
	}, {
		ui.text("Paused", { style = { color = TEXT } }),
		ui.text("This modal is just a scene layer with backdrop and blocking input.", {
			wrap = true,
			width = 360,
			style = { color = MUTED },
		}),
		ui.box({ flex = 1 }),
		ui.button({
			label = "Resume",
			width = "100%",
			onClick = function()
				ui.scene.close(layerId("pause"))
			end,
		}),
	})
end

function DebugOverlay()
	return ui.box({
		width = 220,
		height = 70,
		style = {
			background = { 0, 0, 0, 0.46 },
			borderColor = { 1, 1, 1, 0.12 },
			borderWidth = 1,
			radius = 8,
		},
	}, {
		ui.column({ padding = 10, gap = 4 }, {
			ui.text("Debug Overlay", { style = { color = TEXT } }),
			ui.text("Non-blocking layer", { style = { color = MUTED } }),
		}),
	})
end

local function setup(mode)
	activeMode = mode or "standalone"
	showcaseScene = "home"

	if activeMode == "standalone" then
		ui.scene.set("home", HomeScene, { transition = "none" })
	end
end

local function update(dt)
	if not ui.scene.isOpen(layerId("pause")) then
		sceneTime = sceneTime + dt
	end
end

local function beforeDraw()
	love.graphics.clear(BG[1], BG[2], BG[3], BG[4])
end

local function component()
	if showcaseScene == "inventory" then
		return InventoryScene()
	end
	return HomeScene()
end

return {
	id = "scene",
	label = "Scene",
	window = {
		width = 900,
		height = 580,
		resizable = true,
		title = "glyph - scene layers",
	},
	usesScene = true,
	setup = setup,
	update = update,
	beforeDraw = beforeDraw,
	teardown = function()
		ui.scene.close(layerId("debug"))
		ui.scene.close(layerId("pause"))
	end,
	component = component,
}
