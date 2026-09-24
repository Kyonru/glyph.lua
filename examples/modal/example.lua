local ui = require("glyph")

local BG = ui.theme.backgroundColor
local SURFACE = ui.theme.surfaceColor
local BORDER = ui.theme.borderColor
local ACCENT = ui.theme.accentColor
local TEXT = ui.theme.textColor
local MUTED = ui.theme.mutedTextColor
local DANGER = { 0.95, 0.32, 0.32, 1 }
local SUCCESS = { 0.32, 0.88, 0.56, 1 }
local W, H = 800, 520

local checkerShader
local bgTime = 0
local particles = {}

local Blob = {}
Blob.__index = Blob

function Blob.new(opts)
	opts = opts or {}
	local self = setmetatable({
		x = 0,
		y = 0,
		radius = 0,
		segments = opts.segments or 24,
		wobble = opts.wobble or 28,
		speed = opts.speed or 1.2,
		time = 0,
	}, Blob)
	self.phases = {}
	for index = 1, self.segments do
		self.phases[index] = index * 1.618033988749895
	end
	return self
end

function Blob:update(dt)
	self.time = self.time + dt * self.speed
end

function Blob:draw(graphics)
	local points = {}
	for index = 1, self.segments do
		local angle = (index - 1) / self.segments * math.pi * 2
		local radius = self.radius + math.sin(self.time + self.phases[index]) * self.wobble
		points[#points + 1] = self.x + math.cos(angle) * radius
		points[#points + 1] = self.y + math.sin(angle) * radius
	end
	graphics.polygon("fill", points)
end

local function initParticles(count)
	particles = {}
	for index = 1, count do
		particles[index] = {
			x = math.random(),
			y = math.random(),
			speed = 0.025 + math.random() * 0.09,
			radius = 1.5 + math.random() * 3.5,
			phase = math.random() * math.pi * 2,
			tint = math.random(),
		}
	end
end

local function drawAnimatedBackground(_, x, y, width, height, love, _, ctx)
	local graphics = love.graphics

	ctx:color(BG)
	graphics.rectangle("fill", x, y, width, height)

	for index, p in ipairs(particles) do
		local drift = bgTime * p.speed
		local px = x + ((p.x + drift) % 1) * width
		local py = y + ((p.y + math.sin(bgTime * 0.2 + p.phase) * 0.04) % 1) * height
		local alpha = 0.05 + (math.sin(bgTime * 2.2 + p.phase) + 1) * 0.035
		local color = p.tint > 0.72 and ACCENT or MUTED

		ctx:color({ color[1], color[2], color[3], alpha })
		graphics.circle("fill", px, py, p.radius)

		if index % 5 == 0 then
			ctx:color({ color[1], color[2], color[3], alpha * 0.22 })
			graphics.circle("fill", px, py, p.radius * 5.5)
		end
	end

	local orbitX = x + width * 0.5 + math.cos(bgTime * 0.65) * width * 0.31
	local orbitY = y + height * 0.58 + math.sin(bgTime * 1.05) * height * 0.22
	local pulse = (math.sin(bgTime * 4.2) + 1) / 2

	ctx:color({ ACCENT[1], ACCENT[2], ACCENT[3], 0.08 })
	graphics.circle("fill", orbitX, orbitY, 72 + pulse * 24)
	ctx:color({ ACCENT[1], ACCENT[2], ACCENT[3], 0.58 })
	graphics.circle("line", orbitX, orbitY, 40 + pulse * 10)
	ctx:color(ACCENT)
	graphics.circle("fill", orbitX, orbitY, 11)

	ctx:color({ BORDER[1], BORDER[2], BORDER[3], 0.22 })
	for index = 0, 8 do
		local lx = x + index * width / 8 + math.sin(bgTime + index) * 16
		ctx:line(lx, y, lx - 110, y + height)
	end
end

local function blobTransition(opts)
	opts = opts or {}
	local blob = Blob.new(opts)

	return ui.transitions.custom({
		duration = opts.duration or 0.55,
		exitDuration = opts.exitDuration or opts.duration or 0.42,
		draw = function(ctx)
			local graphics = ctx.love.graphics
			local p = ctx.phase == "exit" and (1 - ctx.progress) or ctx.progress
			local maxRadius = math.sqrt(ctx.bounds.width * ctx.bounds.width + ctx.bounds.height * ctx.bounds.height) / 2
				+ blob.wobble

			blob.x = ctx.bounds.x + ctx.bounds.width / 2
			blob.y = ctx.bounds.y + ctx.bounds.height / 2
			blob.radius = maxRadius * p
			blob:update(ctx.runtime.lastDt or 0)

			graphics.stencil(function()
				blob:draw(graphics)
			end, "replace", 1)
			graphics.setStencilTest("equal", 1)
			ctx.drawLayer()
			graphics.setStencilTest()
		end,
	})
end

local function shaderTransition()
	return ui.transitions.custom({
		duration = 0.34,
		exitDuration = 0.26,
		draw = function(ctx)
			local graphics = ctx.love.graphics
			local p = ctx.phase == "exit" and (1 - ctx.progress) or ctx.progress
			if checkerShader then
				checkerShader:send("amount", p)
				checkerShader:send("time", ui.time())
				graphics.setShader(checkerShader)
			end
			graphics.setColor(1, 1, 1, p)
			ctx.drawLayer()
		end,
	})
end

local function statusLabel(label, color)
	return ui.row({ gap = 8, align = "center" }, {
		ui.box({
			width = 7,
			height = 7,
			interactive = false,
			accessibilityHidden = true,
			style = { background = color, radius = 0 },
		}),
		ui.text(label, { textStyle = "code", style = { color = MUTED } }),
	})
end

local function closeButton(label, id)
	return ui.button({
		label = label,
		width = "100%",
		height = 36,
		variant = "primary",
		onClick = function()
			ui.modal.close(id)
		end,
	})
end

local function card(height, children)
	return ui.column({
		width = W,
		height = height or H,
		gap = 20,
		padding = { top = 36, left = 44, right = 44, bottom = 34 },
		style = {
			background = SURFACE,
			borderColor = BORDER,
			borderWidth = 1,
			radius = ui.theme.radius,
		},
	}, children)
end

local function ModalBody(tag, tagColor, title, description, buttonLabel, id)
	return card(H, {
		ui.column({ gap = 12 }, {
			ui.row({ width = "100%", align = "center", gap = 16 }, {
				ui.text(title, { textStyle = "h1", style = { color = TEXT } }),
				ui.box({ grow = 1, height = 1, interactive = false }),
				statusLabel(tag, tagColor),
			}),
			ui.text(description, {
				textStyle = "paragraph",
				wrap = true,
				width = W - 88,
				style = { color = MUTED },
			}),
		}),
		ui.box({ flex = 1 }),
		closeButton(buttonLabel, id),
	})
end

local function FadeModal()
	return ModalBody(
		"TRANSITION / FADE",
		ACCENT,
		"Smooth fade in and out",
		"A quiet default for confirmations, alerts, and debugger panels.",
		"Got it",
		"fade"
	)
end

local function SlideModal()
	return ModalBody(
		"TRANSITION / SLIDE",
		SUCCESS,
		"Slides in from below",
		"Good for sheets and pushed interface layers that should feel spatial.",
		"Dismiss",
		"slide"
	)
end

local function ScaleModal()
	return ModalBody(
		"TRANSITION / SCALE",
		{ 1.0, 0.72, 0.28, 1 },
		"Pops open from the center",
		"Useful for contextual menus, command palettes, and spotlight dialogs.",
		"Close",
		"scale"
	)
end

local function BlobModal()
	return ModalBody(
		"CUSTOM / STENCIL",
		{ 0.92, 0.38, 0.72, 1 },
		"Organic blob reveal",
		"This transition is implemented entirely in the example with love.graphics.stencil.",
		"Neat, close it",
		"blob"
	)
end

local function ShaderModal()
	return ModalBody(
		"CUSTOM / SHADER",
		{ 0.55, 0.86, 1.0, 1 },
		"Shader-backed transition",
		"Custom transitions can set shaders, canvases, stencils, transforms, or colors and then draw the layer.",
		"Done",
		"shader"
	)
end

local function ConfirmModal()
	return card(340, {
		ui.column({ gap = 12 }, {
			ui.row({ width = "100%", align = "center", gap = 16 }, {
				ui.text("Delete this item?", { textStyle = "h1", style = { color = TEXT } }),
				ui.box({ grow = 1, height = 1, interactive = false }),
				statusLabel("ACTION / CONFIRM", DANGER),
			}),
			ui.text("This action cannot be undone. Backdrop dismissal is disabled for this modal.", {
				textStyle = "paragraph",
				wrap = true,
				width = W - 88,
				style = { color = MUTED },
			}),
		}),
		ui.box({ flex = 1 }),
		ui.row({ width = "100%", gap = 10 }, {
			ui.button({
				label = "Delete",
				flex = 1,
				onClick = function()
					ui.modal.close("confirm")
				end,
				style = {
					background = DANGER,
					borderColor = { 1, 0.45, 0.45, 0.5 },
					borderWidth = 1,
					radius = ui.theme.radius,
					color = { 1, 1, 1, 1 },
					hover = { background = { 1.0, 0.42, 0.42, 1 } },
				},
			}),
			ui.button({
				label = "Cancel",
				flex = 1,
				onClick = function()
					ui.modal.close("confirm")
				end,
			}),
		}),
	})
end

local function CounterModal()
	local count, setCount = ui.useState(0)

	return card(360, {
		ui.column({ gap = 12 }, {
			ui.row({ width = "100%", align = "center", gap = 16 }, {
				ui.text("Layer-local hook state", { textStyle = "h1", style = { color = TEXT } }),
				ui.box({ grow = 1, height = 1, interactive = false }),
				statusLabel("STATE / ISOLATED", ACCENT),
			}),
			ui.text(
				"Each scene or modal layer owns its own hook scope. This counter does not affect the main tree or other modals.",
				{
					textStyle = "paragraph",
					wrap = true,
					width = W - 88,
					style = { color = MUTED },
				}
			),
		}),
		ui.box({ flex = 1 }),
		ui.row({ width = "100%", align = "center", gap = 20 }, {
			ui.button({
				label = "-",
				width = 44,
				onClick = function()
					setCount(count - 1)
				end,
			}),
			ui.text(tostring(count), { textStyle = "code", style = { color = ACCENT } }),
			ui.button({
				label = "+",
				width = 44,
				onClick = function()
					setCount(count + 1)
				end,
			}),
		}),
		closeButton("Done", "counter"),
	})
end

local function launchBtn(label, onClick)
	return ui.button({
		label = label,
		width = "100%",
		height = 36,
		onClick = onClick,
	})
end

local function commandGroup(label, children)
	return ui.column({ gap = 6, width = "100%" }, {
		ui.text(label, { textStyle = "code", style = { color = MUTED } }),
		ui.column({ gap = 6, width = "100%" }, children),
	})
end

local function App()
	return ui.row({ width = "100%", height = "100%", style = { background = BG } }, {
		ui.column({
			width = 236,
			height = "100%",
			padding = 18,
			gap = 16,
			style = { background = SURFACE },
		}, {
			ui.column({ gap = 5, width = "100%" }, {
				ui.text("Modal routes", { textStyle = "h2", style = { color = TEXT } }),
				ui.text("Open a layer over the live probe field.", {
					textStyle = "caption",
					wrap = true,
					width = "100%",
					style = { color = MUTED },
				}),
			}),
			commandGroup("BUILT-IN", {
				launchBtn("Fade", function()
					ui.modal.open("fade", FadeModal, {
						transition = ui.transitions.fade({ duration = 0.28 }),
						width = W,
						height = H,
						dismissOnBackdrop = true,
					})
				end),
				launchBtn("Slide", function()
					ui.modal.open("slide", SlideModal, {
						transition = ui.transitions.slide({ direction = "bottom", duration = 0.32 }),
						width = W,
						height = H,
						dismissOnBackdrop = true,
					})
				end),
				launchBtn("Scale", function()
					ui.modal.open("scale", ScaleModal, {
						transition = ui.transitions.scale({ duration = 0.26 }),
						width = W,
						height = H,
						dismissOnBackdrop = true,
					})
				end),
			}),
			commandGroup("CUSTOM DRAW", {
				launchBtn("Blob", function()
					ui.modal.open(
						"blob",
						BlobModal,
						{ transition = blobTransition(), width = W, height = H, dismissOnBackdrop = true }
					)
				end),
				launchBtn("Shader", function()
					ui.modal.open(
						"shader",
						ShaderModal,
						{ transition = shaderTransition(), width = W, height = H, dismissOnBackdrop = true }
					)
				end),
			}),
			commandGroup("PATTERNS", {
				launchBtn("Confirm", function()
					ui.modal.open(
						"confirm",
						ConfirmModal,
						{ transition = ui.transitions.scale({ duration = 0.22 }), width = W, height = 340 }
					)
				end),
				launchBtn("Counter", function()
					ui.modal.open(
						"counter",
						CounterModal,
						{ transition = "fade", duration = 0.22, width = W, height = 360, dismissOnBackdrop = true }
					)
				end),
			}),
		}),
		ui.box({ width = 1, height = "100%", interactive = false, style = { background = BORDER } }),
		ui.stack({ grow = 1, height = "100%" }, {
			ui.box({
				position = "absolute",
				inset = 0,
				interactive = false,
				draw = drawAnimatedBackground,
			}),
			ui.column({
				position = "absolute",
				top = 24,
				left = 28,
				right = 28,
				gap = 8,
			}, {
				ui.text("Live layer field", { textStyle = "h1", style = { color = TEXT } }),
				ui.text("Motion remains visible beneath each blocking modal so clipping, backdrop coverage, and transition timing are easy to inspect.", {
					textStyle = "paragraph",
					wrap = true,
					width = 470,
					style = { color = MUTED },
				}),
			}),
			ui.row({
				position = "absolute",
				left = 28,
				bottom = 22,
				align = "center",
			}, {
				statusLabel("BACKGROUND ACTIVE", ACCENT),
			}),
			ui.text("ESC CLOSES THE TOP LAYER", {
				position = "absolute",
				right = 28,
				bottom = 22,
				textStyle = "code",
				style = { color = MUTED },
			}),
		}),
	})
end

local function setup()
	math.randomseed(os.time())
	initParticles(56)

	if love.graphics and love.graphics.newShader then
		checkerShader = love.graphics.newShader([[
    extern number amount;
    extern number time;
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
      number bars = step(0.5, fract((px.x + px.y + time * 80.0) / 18.0));
      vec3 tint = mix(vec3(0.74, 0.45, 0.08), vec3(0.93, 0.91, 0.86), bars);
      vec4 base = Texel(tex, uv) * color;
      base.rgb = mix(base.rgb, base.rgb * tint * 1.25, 1.0 - amount);
      return base;
    }
  ]])
	end
end

local function update(dt)
	bgTime = bgTime + dt
end

local function beforeDraw()
	love.graphics.clear(BG[1], BG[2], BG[3], 1)
end

return {
	id = "modal",
	label = "Modal",
	description = "Open modals over a live probe field: fade, slide, scale, shader, confirm, and stateful counter patterns.",
	window = {
		width = 960,
		height = 580,
		resizable = true,
		title = "glyph - scene-backed modal demo",
	},
	setup = setup,
	update = update,
	beforeDraw = beforeDraw,
	teardown = function()
		ui.modal.closeAll()
	end,
	component = function()
		return App()
	end,
}
