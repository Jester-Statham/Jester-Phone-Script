-- Widgets.lua — Jester Phone v2.6 — Темы и Виджеты (FIXED)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Widgets = {}

-- ==================== ТЕМЫ ====================
Widgets.Themes = {
	{ Name = "Хакерский", Background = Color3.fromRGB(8, 12, 10), Surface = Color3.fromRGB(18, 25, 22), Text = Color3.fromRGB(0, 255, 100), Accent = Color3.fromRGB(0, 255, 70), Accent2 = Color3.fromRGB(100, 255, 200) },
	{ Name = "Полночь",   Background = Color3.fromRGB(12, 12, 18), Surface = Color3.fromRGB(24, 24, 36), Text = Color3.fromRGB(230, 230, 240), Accent = Color3.fromRGB(120, 80, 255), Accent2 = Color3.fromRGB(255, 60, 120) },
	{ Name = "Мороз",     Background = Color3.fromRGB(10, 18, 28), Surface = Color3.fromRGB(20, 34, 50), Text = Color3.fromRGB(235, 248, 255), Accent = Color3.fromRGB(80, 180, 255), Accent2 = Color3.fromRGB(255, 100, 180) },
	{ Name = "Киберпанк", Background = Color3.fromRGB(16, 8, 24),  Surface = Color3.fromRGB(32, 14, 48), Text = Color3.fromRGB(255, 240, 255), Accent = Color3.fromRGB(255, 0, 128), Accent2 = Color3.fromRGB(0, 255, 255) },
	{ Name = "Алый",      Background = Color3.fromRGB(28, 10, 12), Surface = Color3.fromRGB(48, 16, 20), Text = Color3.fromRGB(255, 235, 235), Accent = Color3.fromRGB(255, 40, 60), Accent2 = Color3.fromRGB(0, 220, 255) },
	{ Name = "Лес",       Background = Color3.fromRGB(10, 24, 14), Surface = Color3.fromRGB(18, 40, 24), Text = Color3.fromRGB(230, 250, 235), Accent = Color3.fromRGB(60, 220, 100), Accent2 = Color3.fromRGB(255, 160, 40) },
	{ Name = "Океан",     Background = Color3.fromRGB(8, 20, 36),  Surface = Color3.fromRGB(16, 36, 64), Text = Color3.fromRGB(220, 240, 255), Accent = Color3.fromRGB(0, 180, 255), Accent2 = Color3.fromRGB(255, 200, 0) },
	{ Name = "Монохром",  Background = Color3.fromRGB(16, 16, 16), Surface = Color3.fromRGB(32, 32, 32), Text = Color3.fromRGB(245, 245, 245), Accent = Color3.fromRGB(200, 200, 200), Accent2 = Color3.fromRGB(140, 140, 140) },
}

-- ==================== ХЕЛПЕРЫ ====================
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function safeCleanup(list)
	for _, fn in ipairs(list or {}) do pcall(fn) end
end

-- ==================== ВИДЖЕТЫ ====================
Widgets.List = {

	-- 1. Пустой (по умолчанию)
	{ Name = "None", Desc = "Без виджета", Build = function() return function() end end },

	-- 2. Starfield
	{ Name = "Starfield", Desc = "Звёздное небо", Build = function(layer, theme)
		local cleanup = {}
		for i = 1, 35 do
			local star = new("Frame", {
				Size = UDim2.fromOffset(math.random(1,3), math.random(1,3)),
				Position = UDim2.new(math.random(), 0, math.random(), 0),
				BackgroundColor3 = math.random() > 0.7 and theme.Accent or theme.Text,
				ZIndex = 2,
			}, layer)
			local speed = math.random(8, 25)
			local tw = TweenService:Create(star, TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0)})
			tw:Play()
			table.insert(cleanup, function() tw:Cancel(); star:Destroy() end)
		end
		return function() safeCleanup(cleanup) end
	end},

	-- 3. Floating Orbs (замена Wave Pulse — плавающие круги)
	{ Name = "Floating Orbs", Desc = "Плавающие сферы", Build = function(layer, theme)
		local cleanup = {}
		local orbs = {}
		local active = true

		for i = 1, 6 do
			local size = math.random(18, 42)
			local orb = new("Frame", {
				Size = UDim2.fromOffset(size, size),
				Position = UDim2.new(math.random() * 0.8 + 0.1, 0, math.random() * 0.8 + 0.1, 0),
				BackgroundColor3 = i % 2 == 0 and theme.Accent or theme.Accent2,
				BackgroundTransparency = 0.65,
				ZIndex = 2,
			}, layer)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, orb)

			local stroke = new("UIStroke", {
				Color = i % 2 == 0 and theme.Accent2 or theme.Accent,
				Thickness = 1.5,
				Transparency = 0.4,
			}, orb)

			local glow = new("Frame", {
				Size = UDim2.fromScale(1.4, 1.4),
				Position = UDim2.fromScale(-0.2, -0.2),
				BackgroundColor3 = orb.BackgroundColor3,
				BackgroundTransparency = 0.9,
				ZIndex = 1,
			}, orb)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)

			local baseX = orb.Position.X.Scale
			local baseY = orb.Position.Y.Scale
			local speedX = (math.random() - 0.5) * 0.15
			local speedY = (math.random() - 0.5) * 0.12
			local phase = math.random() * math.pi * 2

			table.insert(orbs, {
				orb = orb,
				glow = glow,
				stroke = stroke,
				baseX = baseX,
				baseY = baseY,
				speedX = speedX,
				speedY = speedY,
				phase = phase,
				size = size,
			})
		end

		local conn = RunService.Heartbeat:Connect(function(dt)
			if not active then return end
			for _, o in ipairs(orbs) do
				if o.orb and o.orb.Parent then
					o.phase = o.phase + dt * 0.8
					local offsetX = math.sin(o.phase * 0.7) * 0.08 + o.speedX * dt * 10
					local offsetY = math.cos(o.phase * 0.9) * 0.06 + o.speedY * dt * 10
					o.orb.Position = UDim2.new(
						math.clamp(o.baseX + offsetX, 0.05, 0.95 - o.size / 300),
						0,
						math.clamp(o.baseY + offsetY, 0.05, 0.95 - o.size / 300),
						0
					)
					local pulse = 0.5 + math.sin(o.phase * 1.5) * 0.2
					o.orb.BackgroundTransparency = 0.65 + pulse * 0.15
					o.stroke.Transparency = 0.3 + pulse * 0.3
					o.glow.Size = UDim2.fromScale(1.4 + pulse * 0.3, 1.4 + pulse * 0.3)
					o.glow.Position = UDim2.fromScale(-0.2 - pulse * 0.15, -0.2 - pulse * 0.15)
				end
			end
		end)
		table.insert(cleanup, function() active = false; conn:Disconnect() end)

		for _, o in ipairs(orbs) do
			table.insert(cleanup, function()
				if o.orb then pcall(function() o.orb:Destroy() end) end
			end)
		end

		return function() safeCleanup(cleanup) end
	end},

	-- 4. CIRCUIT
	{ Name = "CIRCUIT", Desc = "Неон", Build = function(layer, theme)
		local cleanup = {}
		for i = 1, 4 do
			local line = new("Frame", {
				Size = UDim2.new(0.92, 0, 0, 3),
				Position = UDim2.new(0.04, 0, 0.18 + i * 0.17, 0),
				BackgroundColor3 = theme.Surface,
				ZIndex = 2,
			}, layer)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, line)
			local light = new("Frame", {
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = theme.Accent2,
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ZIndex = 3,
			}, line)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, light)
			local tw = TweenService:Create(light, TweenInfo.new(1.6 + i * 0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
				Position = UDim2.new(1, -16, 0.5, 0)
			})
			tw:Play()
			table.insert(cleanup, function() tw:Cancel(); line:Destroy() end)
		end
		return function() safeCleanup(cleanup) end
	end},

	-- 5. ENERGY PULSE
	{ Name = "PULSE", Desc = "Пульс", Build = function(layer, theme)
		local cleanup = {}
		for i = 1, 4 do
			local ring = new("Frame", {
				Size = UDim2.fromOffset(55 + i * 42, 55 + i * 42),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ZIndex = 2,
			}, layer)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
			local stroke = new("UIStroke", { Color = theme.Accent, Thickness = 2.5, Transparency = 0.85 }, ring)
			local tw = TweenService:Create(stroke, TweenInfo.new(1.3 + i * 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.15 })
			tw:Play()
			table.insert(cleanup, function() tw:Cancel(); ring:Destroy() end)
		end
		return function() safeCleanup(cleanup) end
	end},

	-- 6. ORBIT-CORE
	{ Name = "ORBIT", Desc = "Планеты", Build = function(layer, theme)
		local cleanup = {}
		local core = new("Frame", {
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Accent2,
			ZIndex = 3,
			BorderSizePixel = 0,
		}, layer)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, core)
		new("UIStroke", { Color = theme.Accent, Thickness = 1.5, Transparency = 0.4 }, core)
		table.insert(cleanup, function() core:Destroy() end)

		for i = 1, 3 do
			local orbit = new("Frame", {
				Size = UDim2.fromOffset(75 + i * 32, 75 + i * 32),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ZIndex = 2,
			}, layer)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, orbit)
			local stroke = new("UIStroke", { Color = theme.Accent, Thickness = 1.5, Transparency = 0.6 }, orbit)
			local dot = new("Frame", { Name = "Dot", Size = UDim2.fromOffset(5,5), BackgroundColor3 = theme.Accent2, ZIndex = 4 }, orbit)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

			local angle = i * 1.1
			local conn = RunService.Heartbeat:Connect(function(dt)
				if dot and dot.Parent then
					angle += dt * (0.7 + i * 0.35)
					local px = math.cos(angle) * (38 + i * 16)
					local py = math.sin(angle) * (32 + i * 13) * 0.65
					dot.Position = UDim2.new(0.5, px, 0.5, py)
				end
			end)
			table.insert(cleanup, function() conn:Disconnect(); orbit:Destroy() end)
		end
		return function() safeCleanup(cleanup) end
	end},
}

-- Инициализация
function Widgets.Init(phone)
	if phone.WidgetLayer then phone.WidgetLayer:ClearAllChildren() end
end

function Widgets.ApplyWidget(phone, index)
	if not phone.WidgetLayer then return end
	-- Очищаем предыдущий виджет
	if phone._widgetCleanup then
		pcall(phone._widgetCleanup)
		phone._widgetCleanup = nil
	end
	phone.WidgetLayer:ClearAllChildren()
	local widget = Widgets.List[index] or Widgets.List[1]
	if widget and widget.Build then
		local cleanup = widget.Build(phone.WidgetLayer, phone.Theme)
		phone._widgetCleanup = cleanup
	end
end

return Widgets
