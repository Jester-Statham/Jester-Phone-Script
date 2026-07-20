-- core.lua — Jester Phone v2.3 — Ядро (исправленная сетка иконок 3×3)

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local Core = {}
Core.__index = Core
Core.Version = "2.3"

local SOUND_IDS = {
	tap_base = "rbxassetid://133196982070163",
	power_on = "rbxassetid://130114397986399",
	power_off = "rbxassetid://139019913635357",
	notif_basic = "rbxassetid://131390520971848",
	notif_steam = "rbxassetid://139308638407157",
	active_basic = "rbxassetid://136583780243085",
	active_cod = "rbxassetid://109745540878065",
	ping = "rbxassetid://122293143209564",
	deact_turbine = "rbxassetid://123479605313650",
	deact_basic = "rbxassetid://75306766920351",
	widget_switch = "rbxassetid://122293143209564",
}

Core.SoundNames = {
	Tap = {
		{ Name = "Base Tap", Key = "tap_base" },
		{ Name = "Ping", Key = "ping" },
		{ Name = "Basic Active", Key = "active_basic" },
		{ Name = "COD Active", Key = "active_cod" },
	},
	Notify = {
		{ Name = "Basic", Key = "notif_basic" },
		{ Name = "Steam", Key = "notif_steam" },
	},
	AppOpen = {
		{ Name = "Basic Active", Key = "active_basic" },
		{ Name = "COD Active", Key = "active_cod" },
	},
}

Core.Models = {
	{ Name = "Jester Mini",   Size = UDim2.fromOffset(215, 385), Radius = 24, Notch = UDim2.fromOffset(64, 16) },
	{ Name = "Jester One",    Size = UDim2.fromOffset(250, 445), Radius = 30, Notch = UDim2.fromOffset(78, 18) },
	{ Name = "Jester Pro",    Size = UDim2.fromOffset(268, 485), Radius = 36, Notch = UDim2.fromOffset(96, 20) },
	{ Name = "Jester Ultra",  Size = UDim2.fromOffset(290, 525), Radius = 42, Notch = UDim2.fromOffset(120, 24) },
}

function Core.new()
	local self = setmetatable({}, Core)
	self.Sound = {
		Enabled = true,
		Volume = 0.6,
		Tap = "tap_base",
		Notify = "notif_basic",
		AppOpen = "active_basic",
	}
	self.Apps = {}
	self._icons = {}
	self._tags = {}
	self._notchDown = false
	self._swipeStart = nil
	self._connections = {}
	self._sounds = {}
	self._wpCleanup = nil
	self._widgetCleanup = nil

	local saved = nil
	pcall(function() saved = getgenv().JesterPhoneData end)
	self.ModelIndex = saved and saved.ModelIndex or 2
	self.ThemeIndex = saved and saved.ThemeIndex or 1
	self.WidgetIndex = saved and saved.WidgetIndex or 1

	return self
end

-- ═══════════════════════════════════════════════════════
--  РЕГИСТРАЦИЯ ПРИЛОЖЕНИЙ
-- ═══════════════════════════════════════════════════════
function Core:RegisterApp(app)
	if type(app) ~= "table" then
		warn("[jester phone] RegisterApp: ожидалась таблица, получено " .. type(app))
		return
	end
	if not app.Name then
		warn("[jester phone] RegisterApp: у приложения нет поля Name")
		return
	end
	if not app.Icon then
		app.Icon = "📦"
	end
	if not app.Open then
		warn("[jester phone] RegisterApp: у приложения '" .. tostring(app.Name) .. "' нет метода Open")
		return
	end

	table.insert(self.Apps, app)

	-- Если телефон уже создан — добавляем иконку сразу
	if self.Grid then
		self:_AddIcon(app)
	end
end

function Core:LoadApps(folder)
	if not folder then return end
	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local ok, app = pcall(require, module)
			if ok and type(app) == "table" and app.Name and app.Open then
				self:RegisterApp(app)
			else
				warn("[jester phone] Не удалось загрузить приложение: " .. module.Name)
			end
		end
	end
end

function Core:_Connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(self._connections, conn)
	return conn
end

function Core:_CleanupConnections()
	for _, conn in ipairs(self._connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(self._connections)
end

function Core:Play(key, force)
	if not (self.Sound.Enabled or force) then return end
	local id = SOUND_IDS[key]
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = self.Sound.Volume
	s.Parent = SoundService
	s.Loaded:Wait()
	s:Play()
	
	local soundRef = { sound = s, destroyed = false }
	table.insert(self._sounds, soundRef)
	
	task.delay(s.TimeLength + 0.5, function()
		if not soundRef.destroyed then
			soundRef.destroyed = true
			pcall(function() s:Destroy() end)
		end
	end)
end

function Core:PlayTap()
	self:Play(self.Sound.Tap)
end

function Core:Tag(obj, kind)
	table.insert(self._tags, { obj = obj, kind = kind })
	if self.Theme then
		self:_ApplyTag({ obj = obj, kind = kind }, self.Theme)
	end
end

function Core:_ApplyTag(e, theme)
	pcall(function()
		local k, o = e.kind, e.obj
		local sub = theme.Text:Lerp(theme.Background, 0.4)
		if k == "bg" then o.BackgroundColor3 = theme.Background
		elseif k == "surface" then o.BackgroundColor3 = theme.Surface
		elseif k == "text" then o.TextColor3 = theme.Text
		elseif k == "subtext" then o.TextColor3 = sub
		elseif k == "accent" then o.BackgroundColor3 = theme.Accent
		elseif k == "accent2" then o.BackgroundColor3 = theme.Accent2
		elseif k == "accentText" then o.TextColor3 = theme.Accent
		elseif k == "textBg" then o.BackgroundColor3 = theme.Text
		elseif k == "stroke" then o.Color = theme.Accent
		elseif k == "stroke2" then o.Color = theme.Accent2
		end
	end)
end

function Core:SetTheme(i)
	self.ThemeIndex = i
	self.Theme = self.WidgetsModule.Themes[i] or self.WidgetsModule.Themes[1]
	local t = self.Theme
	for _, e in ipairs(self._tags) do
		self:_ApplyTag(e, t)
	end
	if self.WidgetLayer then
		self.WidgetsModule.ApplyWidget(self, self.WidgetIndex)
	end
	pcall(function()
		local data = getgenv().JesterPhoneData or {}
		data.ThemeIndex = i
		getgenv().JesterPhoneData = data
	end)
end

function Core:SetWidget(i)
	self.WidgetIndex = i
	if self.WidgetsModule then
		self.WidgetsModule.ApplyWidget(self, i)
	end
end

function Core:SetModel(i, instant)
	self.ModelIndex = i
	local m = self.Models[i]
	if not self.Phone then return end
	if instant then
		self.Phone.Size = m.Size
	else
		TweenService:Create(self.Phone, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = m.Size }):Play()
	end
	self.PhoneCorner.CornerRadius = UDim.new(0, m.Radius)
	self.ScreenCorner.CornerRadius = UDim.new(0, math.max(m.Radius - 6, 8))
	self.Notch.Size = m.Notch
	pcall(function()
		local data = getgenv().JesterPhoneData or {}
		data.ModelIndex = i
		getgenv().JesterPhoneData = data
	end)
end

-- ═══════════════════════════════════════════════════════
--  ИКОНКИ ПРИЛОЖЕНИЙ — сетка 3×3
-- ═══════════════════════════════════════════════════════
function Core:_AddIcon(app)
	local ICON_SIZE = 48
	local ICON_HOVER = 52
	local NAME_HEIGHT = 14
	local HOLDER_HEIGHT = ICON_SIZE + NAME_HEIGHT + 2

	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(ICON_SIZE, HOLDER_HEIGHT),
		ZIndex = 5,
	}, self.Grid)
	holder.LayoutOrder = #self._icons + 1

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
		Text = app.Icon or "📦",
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 5,
	}, holder)
	self:Tag(btn, "surface")
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, btn)

	local gloss = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.85,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, btn)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, gloss)

	local name = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, ICON_SIZE + 2),
		Size = UDim2.new(1, 8, 0, NAME_HEIGHT),
		BackgroundTransparency = 1,
		Text = app.Name or "App",
		Font = Enum.Font.Gotham,
		TextSize = 9,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		ZIndex = 5,
	}, holder)
	self:Tag(name, "subtext")

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			Size = UDim2.fromOffset(ICON_HOVER, ICON_HOVER)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
		}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		self:PlayTap()
		self:OpenApp(app)
	end)

	table.insert(self._icons, holder)
end

function Core:OpenApp(app)
	if self.CurrentApp then self:CloseApp() end
	self.CurrentApp = app

	TweenService:Create(self.Home, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0, -20, 0, 44),
		BackgroundTransparency = 1,
	}):Play()
	self.Home.Visible = false
	self.Home.Position = UDim2.new(0, 0, 0, 44)

	for _, c in ipairs(self.WindowContent:GetChildren()) do c:Destroy() end
	self.WindowTitle.Text = app.Name or ""
	self.Window.Visible = true
	self.Window.Position = UDim2.new(0, 20, 0, 40)
	TweenService:Create(self.Window, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 40),
	}):Play()

	self:Play(self.Sound.AppOpen)
	local ok, err = pcall(function() app:Open(self, self.WindowContent) end)
	if not ok then warn("[jester phone] ошибка в приложении: " .. tostring(err)) end
end

function Core:CloseApp()
	local app = self.CurrentApp
	self.CurrentApp = nil
	if app and app.Close then pcall(function() app:Close(self) end) end

	TweenService:Create(self.Window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0, 20, 0, 40),
	}):Play()

	task.delay(0.2, function()
		for _, c in ipairs(self.WindowContent:GetChildren()) do c:Destroy() end
		self.Window.Visible = false
		self.Window.Position = UDim2.new(0, 0, 0, 40)
		self.Home.Visible = true
		TweenService:Create(self.Home, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 44),
		}):Play()
	end)
end

function Core:Notify(opts)
	opts = opts or {}
	if not self.NotifyLayer then return end
	if self._toast and self._toast.Parent then self._toast:Destroy() end
	self:Play(self.Sound.Notify)

	local height = opts.OnConfirm and 96 or 62
	local toast = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -height - 20),
		Size = UDim2.new(1, -18, 0, height),
		BorderSizePixel = 0,
		ZIndex = 10,
	}, self.NotifyLayer)
	self:Tag(toast, "surface")
	new("UICorner", { CornerRadius = UDim.new(0, 16) }, toast)
	local st = new("UIStroke", { Thickness = 1, Transparency = 0.4 }, toast)
	self:Tag(st, "stroke")

	local glass = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.9,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 10,
	}, toast)
	new("UICorner", { CornerRadius = UDim.new(0, 16) }, glass)

	local title = new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 10),
		Size = UDim2.new(1, -70, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Title or "Уведомление",
		ZIndex = 10,
	}, toast)
	self:Tag(title, "text")

	local timerLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.fromOffset(40, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		ZIndex = 10,
	}, toast)
	self:Tag(timerLabel, "subtext")

	local body = new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 28),
		Size = UDim2.new(1, -28, 0, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = opts.Text or "",
		ZIndex = 10,
	}, toast)
	self:Tag(body, "subtext")

	local function dismiss()
		if not toast.Parent then return end
		TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -height - 20)
		}):Play()
		task.delay(0.3, function() pcall(function() toast:Destroy() end) end)
		if self._toast == toast then self._toast = nil end
	end

	if opts.OnConfirm then
		local yes = new("TextButton", {
			Position = UDim2.new(0, 14, 1, -36),
			Size = UDim2.new(0.5, -20, 0, 28),
			Text = opts.ConfirmText or "Да",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, toast)
		self:Tag(yes, "accent")
		new("UICorner", { CornerRadius = UDim.new(0, 10) }, yes)

		local no = new("TextButton", {
			Position = UDim2.new(0.5, 6, 1, -36),
			Size = UDim2.new(0.5, -20, 0, 28),
			Text = opts.CancelText or "Нет",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, toast)
		self:Tag(no, "bg")
		self:Tag(no, "text")
		new("UICorner", { CornerRadius = UDim.new(0, 10) }, no)
		local nst = new("UIStroke", { Thickness = 1, Transparency = 0.4 }, no)
		self:Tag(nst, "stroke")

		yes.MouseButton1Click:Connect(function()
			self:PlayTap()
			pcall(opts.OnConfirm)
			dismiss()
		end)
		no.MouseButton1Click:Connect(function()
			self:PlayTap()
			if opts.OnCancel then pcall(opts.OnCancel) end
			dismiss()
		end)
	end

	self._toast = toast
	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 42)
	}):Play()

	task.spawn(function()
		local left = opts.Timeout or (opts.OnConfirm and 6 or 3)
		while left > 0 and toast.Parent do
			if opts.OnConfirm then timerLabel.Text = left .. "с" end
			task.wait(1)
			left -= 1
		end
		if toast.Parent then dismiss() end
	end)
end

function Core:RequestRemove()
	self:Notify({
		Title = "Выключить телефон?",
		Text = "Интерфейс будет удалён. Настройки сохранены.",
		Timeout = 6,
		ConfirmText = "Выкл",
		CancelText = "Отмена",
		OnConfirm = function() self:Shutdown() end,
		OnCancel = function() self:Play("deact_basic") end,
	})
end

function Core:Shutdown()
	self:Play("power_off", true)
	local phone, gui = self.Phone, self.Gui
	TweenService:Create(phone, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0)
	}):Play()
	
	self:_CleanupConnections()
	for _, soundRef in ipairs(self._sounds) do
		if not soundRef.destroyed then
			soundRef.destroyed = true
			pcall(function() soundRef.sound:Destroy() end)
		end
	end
	table.clear(self._sounds)
	
	if self._wpCleanup then
		pcall(self._wpCleanup)
		self._wpCleanup = nil
	end
	if self._widgetCleanup then
		pcall(self._widgetCleanup)
		self._widgetCleanup = nil
	end
	
	task.delay(0.6, function() pcall(function() gui:Destroy() end) end)
end

function Core:ToggleNotchDown()
	if not self.Phone then return end
	self._notchDown = not self._notchDown
	local target = self._notchDown and UDim2.new(0, 16, 1, 250) or UDim2.new(0, 16, 1, -16)
	TweenService:Create(self.Phone, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = target
	}):Play()
end

function Core:GetNames(list)
	local t = {}
	for _, v in ipairs(list) do table.insert(t, v.Name) end
	return t
end

function Core:GetSoundIndex(group)
	for i, o in ipairs(self.SoundNames[group]) do
		if o.Key == self.Sound[group] then return i end
	end
	return 1
end

function Core:Start()
	local parent
	pcall(function() parent = gethui() end)
	if not parent then pcall(function() parent = game:GetService("CoreGui") end) end
	if not parent then parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	local old = parent:FindFirstChild("JesterPhone")
	if old then old:Destroy() end

	if not self.WidgetsModule then
		warn("[jester phone] WidgetsModule не подключён! Загрузите widgets.lua перед Start()")
	end

	local model = self.Models[self.ModelIndex]

	local gui = new("ScreenGui", {
		Name = "JesterPhone",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, parent)
	self.Gui = gui

	-- ═══════════════════════════════════════════════════════
	--  КОРПУС ТЕЛЕФОНА
	-- ═══════════════════════════════════════════════════════
	local phone = new("Frame", {
		Name = "Phone",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(12, 12, 15),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)
	self.Phone = phone
	self.PhoneCorner = new("UICorner", { CornerRadius = UDim.new(0, model.Radius) }, phone)
	new("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 2, Transparency = 0.25 }, phone)

	local shadow = new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 40, 1, 40),
		BackgroundTransparency = 1,
		Image = "rbxassetid://13160452193",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.55,
		ZIndex = 0,
	}, phone)

	-- ═══════════════════════════════════════════════════════
	--  ЭКРАН
	-- ═══════════════════════════════════════════════════════
	local screen = new("Frame", {
		Name = "Screen",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -10, 1, -10),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, phone)
	self:Tag(screen, "bg")
	self.ScreenCorner = new("UICorner", { CornerRadius = UDim.new(0, math.max(model.Radius - 6, 8)) }, screen)

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 1: ВИДЖЕТЫ
	-- ═══════════════════════════════════════════════════════
	local widgetLayer = new("Frame", {
		Name = "WidgetLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
	}, screen)
	new("UICorner", { CornerRadius = self.ScreenCorner.CornerRadius }, widgetLayer)
	self.WidgetLayer = widgetLayer

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 2: ОКНО ПРИЛОЖЕНИЯ
	-- ═══════════════════════════════════════════════════════
	local win = new("Frame", {
		Name = "AppWindow",
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 1, -78),
		BackgroundTransparency = 1,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 2,
	}, screen)

	local winTitle = new("TextLabel", {
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		ZIndex = 2,
	}, win)
	self:Tag(winTitle, "text")

	local winContent = new("Frame", {
		Position = UDim2.new(0, 8, 0, 26),
		Size = UDim2.new(1, -16, 1, -32),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
	}, win)

	self.Window = win
	self.WindowTitle = winTitle
	self.WindowContent = winContent

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 3: УВЕДОМЛЕНИЯ
	-- ═══════════════════════════════════════════════════════
	local nl = new("Frame", {
		Name = "NotifyLayer",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 3,
	}, screen)
	self.NotifyLayer = nl

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 4: ГЛАВНЫЙ ЭКРАН
	-- ═══════════════════════════════════════════════════════
	local home = new("Frame", {
		Name = "Home",
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -84),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 4,
	}, screen)
	self.Home = home

	local clock = new("TextLabel", {
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 38,
		Text = "--:--",
		ZIndex = 4,
	}, home)
	self:Tag(clock, "text")

	local dateLabel = new("TextLabel", {
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = "",
		ZIndex = 4,
	}, home)
	self:Tag(dateLabel, "subtext")

	-- ═══════════════════════════════════════════════════════
	--  СЕТКА ИКОНОК 3×3
	-- ═══════════════════════════════════════════════════════
	local grid = new("Frame", {
		Name = "Grid",
		Position = UDim2.new(0, 10, 0, 66),
		Size = UDim2.new(1, -20, 1, -72),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, home)

	local gridLayout = new("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellSize = UDim2.fromOffset(58, 64),
		CellPadding = UDim2.new(0, 6, 0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		FillDirectionMaxCells = 3,
	}, grid)

	self.Grid = grid

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 5: СТАТУС-БАР
	-- ═══════════════════════════════════════════════════════
	local status = new("Frame", {
		Position = UDim2.new(0, 11, 0, 10),
		Size = UDim2.new(1, -22, 0, 20),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, screen)

	local devLabel = new("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "jester v" .. self.Version,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, status)
	self:Tag(devLabel, "accentText")

	local timeLabel = new("TextLabel", {
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "--:--",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 5,
	}, status)
	self:Tag(timeLabel, "text")

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 6: НИЖНЯЯ ПАНЕЛЬ
	-- ═══════════════════════════════════════════════════════
	local homeBar = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, screen)

	local bumperBtn = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(160, 30),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 6,
	}, homeBar)

	local bumper = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(110, 6),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.25,
		ZIndex = 6,
	}, bumperBtn)
	self:Tag(bumper, "textBg")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bumper)

	local bumperTween = nil
	local bumperConn = bumperBtn.MouseButton1Click:Connect(function()
		self:PlayTap()
		if self.CurrentApp then
			self:CloseApp()
		else
			if bumperTween then
				pcall(function() bumperTween:Cancel() end)
			end
			
			local t1 = TweenService:Create(bumper, TweenInfo.new(0.08), { Size = UDim2.fromOffset(90, 6) })
			bumperTween = t1
			t1:Play()
			
			t1.Completed:Connect(function()
				if not bumper or not bumper.Parent then return end
				local t2 = TweenService:Create(bumper, TweenInfo.new(0.12), { Size = UDim2.fromOffset(110, 6) })
				bumperTween = t2
				t2:Play()
			end)
		end
	end)
	table.insert(self._connections, bumperConn)

	-- ═══════════════════════════════════════════════════════
	--  СЛОЙ 7: ЧЁЛКА
	-- ═══════════════════════════════════════════════════════
	local notch = new("TextButton", {
		Name = "Notch",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = model.Notch,
		BackgroundColor3 = Color3.fromRGB(8, 8, 10),
		BorderSizePixel = 0,
		ZIndex = 7,
		Text = "",
		AutoButtonColor = false,
	}, screen)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, notch)
	self.Notch = notch

	notch.MouseButton1Click:Connect(function()
		self:PlayTap()
		self:ToggleNotchDown()
	end)

	-- ═══════════════════════════════════════════════════════
	--  КНОПКА УДАЛЕНИЯ
	-- ═══════════════════════════════════════════════════════
	local rm = new("TextButton", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, -8, 1, 8),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		BackgroundTransparency = 0.35,
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		ZIndex = 40,
	}, phone)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, rm)
	rm.MouseButton1Click:Connect(function()
		self:PlayTap()
		self:RequestRemove()
	end)

	-- ═══════════════════════════════════════════════════════
	--  ИКОНКИ ПРИЛОЖЕНИЙ
	-- ═══════════════════════════════════════════════════════
	for _, app in ipairs(self.Apps) do self:_AddIcon(app) end

	-- ═══════════════════════════════════════════════════════
	--  ЧАСЫ И ДАТА
	-- ═══════════════════════════════════════════════════════
	local MONTHS = { "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря" }
	local DAYS = { "воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота" }
	local clockTask
	clockTask = task.spawn(function()
		while gui.Parent do
			local now = os.date("*t")
			local hm = string.format("%02d:%02d", now.hour, now.min)
			timeLabel.Text = hm
			clock.Text = hm
			dateLabel.Text = DAYS[now.wday] .. ", " .. now.day .. " " .. MONTHS[now.month]
			task.wait(1)
		end
	end)
	table.insert(self._connections, { Disconnect = function() pcall(function() task.cancel(clockTask) end) end })

	-- ═══════════════════════════════════════════════════════
	--  ИНИЦИАЛИЗАЦИЯ ТЕМЫ И ВИДЖЕТОВ
	-- ═══════════════════════════════════════════════════════
	if self.WidgetsModule then
		self.WidgetsModule.Init(self)
	else
		self.Theme = { Background = Color3.fromRGB(15,17,26), Surface = Color3.fromRGB(27,30,46), Text = Color3.fromRGB(232,235,245), Accent = Color3.fromRGB(94,106,255), Accent2 = Color3.fromRGB(150,120,255) }
	end

	-- ═══════════════════════════════════════════════════════
	--  ПОЯВЛЕНИЕ ТЕЛЕФОНА
	-- ═══════════════════════════════════════════════════════
	TweenService:Create(phone, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = model.Size
	}):Play()
	task.delay(0.15, function() self:Play("power_on", true) end)
end

return Core
