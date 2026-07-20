-- settings.lua — Jester Phone v3.3 — Упрощённые настройки
local App = { Name = "Настройки", Icon = "⚙️" }

local TweenService = game:GetService("TweenService")

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

function App:Open(phone, content)
	-- Очистка
	for _, child in ipairs(content:GetChildren()) do
		pcall(function() child:Destroy() end)
	end

	local cleanupList = {}
	local function track(obj)
		if type(obj) == "table" and obj.Disconnect then
			table.insert(cleanupList, function() pcall(function() obj:Disconnect() end) end)
		elseif type(obj) == "function" then
			table.insert(cleanupList, obj)
		elseif typeof(obj) == "Instance" then
			table.insert(cleanupList, function() pcall(function() obj:Destroy() end) end)
		elseif typeof(obj) == "RBXScriptConnection" then
			table.insert(cleanupList, function() pcall(function() obj:Disconnect() end) end)
		elseif typeof(obj) == "Tween" then
			table.insert(cleanupList, function() pcall(function() obj:Cancel() end) end)
		end
		return obj
	end

	local scroll = track(new("ScrollingFrame", {
		Name = "SettingsScroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 6,
		ClipsDescendants = true,
	}, content))

	local listLayout = track(new("UIListLayout", {
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll))

	track(new("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 20),
	}, scroll))

	track(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if scroll and scroll.Parent then
			scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
		end
	end))

	local order = 0

	local function header(text)
		order += 1
		local l = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = order,
			ZIndex = 6,
		}, scroll)
		phone:Tag(l, "accentText")
		return l
	end

	-- ═══════════════════════════════════════════════════════
	--  СЕТКА ТЕМ — 8 штук, каждая с двумя цветами
	-- ═══════════════════════════════════════════════════════
	local function themeGrid()
		order += 1
		local themes = phone.WidgetsModule and phone.WidgetsModule.Themes or {}
		if #themes == 0 then return end

		local cols = 4
		local size = 40
		local pad = 8
		local count = math.min(#themes, 10)
		local rows = math.ceil(count / cols)
		local gridHeight = rows * size + (rows - 1) * pad + 4

		local gridContainer = track(new("Frame", {
			Size = UDim2.new(1, 0, 0, gridHeight),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 6,
		}, scroll))

		for i = 1, count do
			local theme = themes[i]
			local row = math.floor((i - 1) / cols)
			local col = (i - 1) % cols

			local btn = track(new("TextButton", {
				Position = UDim2.new(0, col * (size + pad), 0, row * (size + pad)),
				Size = UDim2.fromOffset(size, size),
				Text = "",
				BorderSizePixel = 0,
				AutoButtonColor = false,
				BackgroundColor3 = theme.Accent,
				ZIndex = 6,
			}, gridContainer))
			track(new("UICorner", { CornerRadius = UDim.new(0, 10) }, btn))

			-- Второй цвет — полоска снизу
			local accent2Strip = new("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 10),
				BackgroundColor3 = theme.Accent2,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, btn)
			track(new("UICorner", { 
				CornerRadius = UDim.new(0, 10) 
			}, accent2Strip))

			-- Обводка для выбранной темы
			local stroke = new("UIStroke", {
				Thickness = (i == phone.ThemeIndex) and 2.5 or 0,
				Color = Color3.new(1, 1, 1),
				Transparency = 0.2,
			}, btn)

			track(btn.MouseButton1Click:Connect(function()
				if not btn or not btn.Parent then return end
				phone:PlayTap()
				phone:SetTheme(i)

				for _, child in ipairs(gridContainer:GetChildren()) do
					if child:IsA("TextButton") then
						local st = child:FindFirstChildOfClass("UIStroke")
						if st then
							st.Thickness = 0
						end
					end
				end
				stroke.Thickness = 2.5
			end))
		end
	end

	-- ═══════════════════════════════════════════════════════
	--  ВИДЖЕТЫ — 6 лучших, сетка 2×3 (2 в ширину, 3 в высоту)
	-- ═══════════════════════════════════════════════════════
	local function widgetGrid()
		order += 1
		local allWidgets = phone.WidgetsModule and phone.WidgetsModule.List or {}
		if #allWidgets == 0 then return end

		-- Только 6 лучших виджетов
		local bestWidgets = {}
		local widgetIndices = {}
		for i, w in ipairs(allWidgets) do
			if #bestWidgets < 6 then
				table.insert(bestWidgets, w)
				table.insert(widgetIndices, i)
			end
		end

		local cols = 2        -- 2 в ширину
		local rows = 3        -- 3 в высоту
		local cardWidth = 100 -- шире, т.к. 2 колонки
		local cardHeight = 52 -- ниже, т.к. 3 ряда
		local pad = 8
		local gridHeight = rows * cardHeight + (rows - 1) * pad + 4

		local gridContainer = track(new("Frame", {
			Size = UDim2.new(1, 0, 0, gridHeight),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 6,
		}, scroll))

		for idx, widget in ipairs(bestWidgets) do
			local i = widgetIndices[idx]
			local row = math.floor((idx - 1) / cols)
			local col = (idx - 1) % cols

			local card = track(new("TextButton", {
				Position = UDim2.new(0, col * (cardWidth + pad), 0, row * (cardHeight + pad)),
				Size = UDim2.fromOffset(cardWidth, cardHeight),
				Text = "",
				BorderSizePixel = 0,
				AutoButtonColor = false,
				ZIndex = 6,
			}, gridContainer))
			phone:Tag(card, "surface")
			track(new("UICorner", { CornerRadius = UDim.new(0, 10) }, card))

			-- Обводка для выбранного
			local stroke = new("UIStroke", {
				Thickness = (i == phone.WidgetIndex) and 2 or 0,
				Color = phone.Theme and phone.Theme.Accent or Color3.fromRGB(94, 106, 255),
				Transparency = 0.4,
			}, card)

			-- Иконка слева
			local iconLabel = new("TextLabel", {
				Size = UDim2.fromOffset(28, 28),
				Position = UDim2.new(0, 8, 0.5, -14),
				BackgroundTransparency = 1,
				Text = widget.Icon or "◆",
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 6,
			}, card)
			phone:Tag(iconLabel, "accentText")

			-- Название справа от иконки
			local nameLabel = new("TextLabel", {
				Size = UDim2.new(1, -44, 0, 16),
				Position = UDim2.new(0, 40, 0, 6),
				BackgroundTransparency = 1,
				Text = widget.Name,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 6,
			}, card)
			phone:Tag(nameLabel, "text")

			-- Описание под названием
			local descLabel = new("TextLabel", {
				Size = UDim2.new(1, -44, 0, 14),
				Position = UDim2.new(0, 40, 0, 24),
				BackgroundTransparency = 1,
				Text = widget.Desc or "",
				Font = Enum.Font.Gotham,
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 6,
			}, card)
			phone:Tag(descLabel, "subtext")

			track(card.MouseButton1Click:Connect(function()
				if not card or not card.Parent then return end
				phone:PlayTap()
				phone:SetWidget(i)
				phone:Play("widget_switch")

				for _, child in ipairs(gridContainer:GetChildren()) do
					if child:IsA("TextButton") then
						local st = child:FindFirstChildOfClass("UIStroke")
						if st then
							st.Thickness = 0
						end
					end
				end
				stroke.Thickness = 2
				stroke.Color = phone.Theme and phone.Theme.Accent or Color3.fromRGB(94, 106, 255)
			end))
		end
	end

	-- ═══════════════════════════════════════════════════════
	--  TOGGLE — звуки интерфейса
	-- ═══════════════════════════════════════════════════════
	local function soundToggle()
		order += 1
		local container = track(new("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 6,
		}, scroll))

		local label = new("TextLabel", {
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			Text = "Звуки интерфейса",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, container)
		phone:Tag(label, "text")

		local trackFrame = track(new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.fromOffset(44, 22),
			BackgroundColor3 = phone.Sound.Enabled and phone.Theme.Accent or phone.Theme.Surface,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, container))
		track(new("UICorner", { CornerRadius = UDim.new(1, 0) }, trackFrame))

		local knob = track(new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = phone.Sound.Enabled and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, trackFrame))
		track(new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob))

		local btn = track(new("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 6,
		}, container))

		local state = phone.Sound.Enabled
		local debounce = false

		track(btn.MouseButton1Click:Connect(function()
			if not btn or not btn.Parent then return end
			if debounce then return end
			debounce = true
			phone:PlayTap()

			state = not state
			phone.Sound.Enabled = state

			TweenService:Create(trackFrame, TweenInfo.new(0.2), {
				BackgroundColor3 = state and phone.Theme.Accent or phone.Theme.Surface
			}):Play()
			TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
				Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
			}):Play()

			task.delay(0.3, function() debounce = false end)
		end))
	end

	-- ═══════════════════════════════════════════════════════
	--  СБОРКА
	-- ═══════════════════════════════════════════════════════

	header("ТЕМА")
	themeGrid()

	header("ВИДЖЕТ")
	widgetGrid()

	header("ЗВУК")
	soundToggle()

	order += 1
	local footer = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = "jester dev • phone ui v" .. (phone.Version or "3.3"),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = order,
		ZIndex = 6,
	}, scroll)
	phone:Tag(footer, "subtext")

	function App:Close(phone)
		for i = #cleanupList, 1, -1 do
			pcall(cleanupList[i])
			cleanupList[i] = nil
		end
		table.clear(cleanupList)
	end
end

return App
