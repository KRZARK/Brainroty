local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HudTileStyle = {}

HudTileStyle.ButtonSize = UDim2.fromOffset(100, 100)
HudTileStyle.HoverSize = UDim2.fromOffset(100, 100)
HudTileStyle.BaseBackgroundColor = Color3.fromRGB(33, 37, 44)
HudTileStyle.BaseTopColor = Color3.fromRGB(55, 61, 72)
HudTileStyle.BaseBottomColor = Color3.fromRGB(22, 26, 32)
HudTileStyle.BaseStrokeColor = Color3.fromRGB(245, 241, 231)
HudTileStyle.BaseLabelColor = Color3.fromRGB(255, 255, 255)
HudTileStyle.BaseBackgroundTransparency = 0.24

local sharedClickSound
local managedButtons = setmetatable({}, { __mode = "k" })
local layoutRefreshQueued = false
local refreshManagedLayout

local function cleanupManagedButtons()
	for button in pairs(managedButtons) do
		if button.Parent == nil then
			managedButtons[button] = nil
		end
	end
end

local function scheduleLayoutRefresh()
	if layoutRefreshQueued then
		return
	end

	layoutRefreshQueued = true
	task.defer(function()
		layoutRefreshQueued = false
		if refreshManagedLayout then
			refreshManagedLayout()
		end
	end)
end

local function ensureChild(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function scaleUDim2(value, multiplier)
	return UDim2.new(
		value.X.Scale * multiplier,
		math.floor(value.X.Offset * multiplier + 0.5),
		value.Y.Scale * multiplier,
		math.floor(value.Y.Offset * multiplier + 0.5)
	)
end

local function offsetUDim2(value, xOffset, yOffset)
	return UDim2.new(
		value.X.Scale,
		value.X.Offset + xOffset,
		value.Y.Scale,
		value.Y.Offset + yOffset
	)
end

local function getViewportSize()
	local camera = Workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		if viewport.X >= 100 and viewport.Y >= 100 then
			return viewport
		end
	end
	return Vector2.new(1280, 720)
end

local function getOwningScreenGui(instance)
	local current = instance
	while current do
		if current:IsA("ScreenGui") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function getInsetCompensation(instance)
	local screenGui = getOwningScreenGui(instance)
	if screenGui and screenGui.IgnoreGuiInset then
		local topLeftInset = GuiService:GetGuiInset()
		return topLeftInset
	end
	return Vector2.zero
end

function HudTileStyle.isMobileLayout()
	local viewport = getViewportSize()
	return UserInputService.TouchEnabled or viewport.X <= 500 or viewport.Y <= 500
end

function HudTileStyle.getLayoutMetrics()
	local viewport = getViewportSize()
	local isMobile = HudTileStyle.isMobileLayout()
	local isLandscapeMobile = isMobile and viewport.X > viewport.Y
	local rows = 3

	local topSafe
	local bottomSafe
	local leftMargin
	local rightMargin
	local widthCap
	if isLandscapeMobile then
		topSafe = math.max(54, math.floor(viewport.Y * 0.145 + 0.5))
		bottomSafe = math.max(102, math.floor(viewport.Y * 0.27 + 0.5))
		leftMargin = math.max(16, math.floor(viewport.X * 0.026 + 0.5))
		rightMargin = math.max(16, math.floor(viewport.X * 0.026 + 0.5))
		widthCap = viewport.X * 0.082
	elseif isMobile then
		topSafe = math.max(126, math.floor(viewport.Y * 0.20 + 0.5))
		bottomSafe = math.max(126, math.floor(viewport.Y * 0.24 + 0.5))
		leftMargin = math.max(10, math.floor(viewport.X * 0.018 + 0.5))
		rightMargin = math.max(10, math.floor(viewport.X * 0.018 + 0.5))
		widthCap = viewport.X * 0.11
	else
		topSafe = math.max(182, math.floor(viewport.Y * 0.20 + 0.5))
		bottomSafe = math.max(74, math.floor(viewport.Y * 0.08 + 0.5))
		leftMargin = 22
		rightMargin = 28
		widthCap = viewport.X * 0.070
	end
	local heightCap = (viewport.Y - topSafe - bottomSafe) / (rows + 0.14 * (rows - 1))
	local buttonPx = math.floor(math.clamp(math.min(widthCap, heightCap), isMobile and 34 or 56, isMobile and 52 or 88) + 0.5)
	local gapPx = isLandscapeMobile and math.max(5, math.floor(buttonPx * 0.10 + 0.5)) or (isMobile and math.max(6, math.floor(buttonPx * 0.12 + 0.5)) or math.max(8, math.floor(buttonPx * 0.14 + 0.5)))
	local columnGapPx = isLandscapeMobile and math.max(5, math.floor(buttonPx * 0.08 + 0.5)) or (isMobile and math.max(6, math.floor(buttonPx * 0.10 + 0.5)) or math.max(10, math.floor(buttonPx * 0.16 + 0.5)))
	local totalHeight = (buttonPx * rows) + (gapPx * (rows - 1))
	local availableHeight = math.max(viewport.Y - topSafe - bottomSafe, totalHeight)
	local startBias = isLandscapeMobile and 0 or (isMobile and 0.06 or 0.06)
	local mobileLiftPx = isLandscapeMobile and math.floor(buttonPx * 0.48 + 0.5) or (isMobile and math.floor(buttonPx * 0.42 + 0.5) or 0)
	local startY = topSafe + math.floor(math.max(availableHeight - totalHeight, 0) * startBias + 0.5) + (buttonPx / 2) - mobileLiftPx
	local row1Y = startY
	local row2Y = row1Y + buttonPx + gapPx
	local row3Y = row2Y + buttonPx + gapPx
	local pair1Y = math.floor(((row1Y + row2Y) * 0.5) + 0.5)
	local pair2Y = math.floor(((row2Y + row3Y) * 0.5) + 0.5)
	local leftOuterX = leftMargin + (buttonPx / 2)
	local leftInnerX = leftOuterX + buttonPx + columnGapPx
	local rightOuterX = viewport.X - rightMargin - (buttonPx / 2)
	local rightInnerX = rightOuterX - buttonPx - columnGapPx

	local contentLeft = leftInnerX + (buttonPx * 0.5) + math.max(8, gapPx)
	local contentRight = rightInnerX - (buttonPx * 0.5) - math.max(8, gapPx)
	local contentTop = topSafe
	local contentBottom = viewport.Y - bottomSafe

	return {
		Viewport = viewport,
		IsMobile = isMobile,
		IsLandscapeMobile = isLandscapeMobile,
		TopSafe = topSafe,
		BottomSafe = bottomSafe,
		LeftMargin = leftMargin,
		RightMargin = rightMargin,
		ButtonPx = buttonPx,
		GapPx = gapPx,
		ColumnGapPx = columnGapPx,
		LeftX = leftOuterX,
		RightX = rightOuterX,
		LeftOuterX = leftOuterX,
		LeftInnerX = leftInnerX,
		RightInnerX = rightInnerX,
		RightOuterX = rightOuterX,
		ContentLeft = contentLeft,
		ContentRight = contentRight,
		ContentTop = contentTop,
		ContentBottom = contentBottom,
		ContentWidth = math.max(contentRight - contentLeft, buttonPx * 2),
		ContentHeight = math.max(contentBottom - contentTop, buttonPx * 2),
		StartY = row1Y,
		RowCenters = { row1Y, row2Y, row3Y },
		InnerPairCenters = { pair1Y, pair2Y },
	}
end

local function getManagedSlotCenters(side, count, metrics)
	local innerX = side == "right" and metrics.RightInnerX or metrics.LeftInnerX
	local outerX = side == "right" and metrics.RightOuterX or metrics.LeftOuterX
	local rows = metrics.RowCenters
	local pairs = metrics.InnerPairCenters

	if count <= 0 then
		return {}
	elseif count == 1 then
		return {
			Vector2.new(innerX, rows[2]),
		}
	elseif count == 2 then
		return {
			Vector2.new(innerX, pairs[1]),
			Vector2.new(outerX, pairs[1]),
		}
	elseif count == 3 then
		return {
			Vector2.new(innerX, pairs[1]),
			Vector2.new(outerX, rows[1]),
			Vector2.new(outerX, rows[2]),
		}
	elseif count == 4 then
		return {
			Vector2.new(innerX, pairs[1]),
			Vector2.new(outerX, rows[1]),
			Vector2.new(outerX, rows[2]),
			Vector2.new(innerX, pairs[2]),
		}
	elseif count == 5 then
		return {
			Vector2.new(innerX, pairs[1]),
			Vector2.new(outerX, rows[1]),
			Vector2.new(outerX, rows[2]),
			Vector2.new(innerX, pairs[2]),
			Vector2.new(outerX, rows[3]),
		}
	end

	return {
		Vector2.new(innerX, rows[1]),
		Vector2.new(outerX, rows[1]),
		Vector2.new(innerX, rows[2]),
		Vector2.new(outerX, rows[2]),
		Vector2.new(innerX, rows[3]),
		Vector2.new(outerX, rows[3]),
	}
end

function HudTileStyle.getButtonSize()
	local metrics = HudTileStyle.getLayoutMetrics()
	local size = UDim2.fromOffset(metrics.ButtonPx, metrics.ButtonPx)
	HudTileStyle.ButtonSize = size
	HudTileStyle.HoverSize = size
	return size
end

function HudTileStyle.getSlot(side, index)
	local metrics = HudTileStyle.getLayoutMetrics()
	local nominalCount = side == "left" and 6 or 5
	local positions = getManagedSlotCenters(side, nominalCount, metrics)
	local resolvedIndex = math.clamp(tonumber(index) or 1, 1, #positions)
	local position = positions[resolvedIndex] or positions[#positions]
	return UDim2.fromOffset(math.floor(position.X + 0.5), math.floor(position.Y + 0.5))
end

function HudTileStyle.getImageFromObject(object, fallback)
	if not object then
		return fallback or ""
	end
	if object:IsA("Decal") then
		return object.Texture
	end
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then
		return object.Image
	end
	if object:IsA("StringValue") then
		return object.Value
	end
	return fallback or ""
end

function HudTileStyle.getResponsivePanelScale(baseWidth, baseHeight, options)
	options = options or {}
	local metrics = HudTileStyle.getLayoutMetrics()
	local viewport = metrics.Viewport
	local isMobile = options.forceMobile == true or metrics.IsMobile
	local isLandscapeMobile = isMobile and metrics.IsLandscapeMobile

	if not isMobile then
		return options.desktopScale or 1, viewport, false, false
	end

	local widthRatio
	local heightRatio
	local contentWidthRatio
	local contentHeightRatio
	if isLandscapeMobile then
		widthRatio = options.landscapeWidthRatio or options.mobileWidthRatio or 0.92
		heightRatio = options.landscapeHeightRatio or options.mobileHeightRatio or 0.84
		contentWidthRatio = options.landscapeContentWidthRatio or options.mobileContentWidthRatio or 0.98
		contentHeightRatio = options.landscapeContentHeightRatio or options.mobileContentHeightRatio or 0.82
	else
		widthRatio = options.portraitWidthRatio or options.mobileWidthRatio or 0.9
		heightRatio = options.portraitHeightRatio or options.mobileHeightRatio or 0.82
		contentWidthRatio = options.portraitContentWidthRatio or options.mobileContentWidthRatio or 0.98
		contentHeightRatio = options.portraitContentHeightRatio or options.mobileContentHeightRatio or 0.88
	end

	local maxWidth = math.max(1, viewport.X * widthRatio)
	local maxHeight = math.max(1, viewport.Y * heightRatio)
	if options.useHudSafeBounds ~= false then
		maxWidth = math.min(maxWidth, math.max(1, metrics.ContentWidth * contentWidthRatio))
		maxHeight = math.min(maxHeight, math.max(1, metrics.ContentHeight * contentHeightRatio))
	end
	local maxScale
	local minScale
	if isLandscapeMobile then
		maxScale = options.landscapeMaxScale or options.mobileMaxScale or options.maxScale or 1
		minScale = options.landscapeMinScale or options.mobileMinScale or options.minScale or 0.45
	else
		maxScale = options.portraitMaxScale or options.mobileMaxScale or options.maxScale or 1
		minScale = options.portraitMinScale or options.mobileMinScale or options.minScale or 0.45
	end
	local scale = math.min(maxWidth / math.max(baseWidth, 1), maxHeight / math.max(baseHeight, 1), maxScale)
	scale = math.clamp(scale, minScale, maxScale)
	return scale, viewport, true, isLandscapeMobile
end

function HudTileStyle.bindResponsivePanelScale(panel, options)
	options = options or {}
	local baseSize = options.baseSize or panel.Size
	local baseWidth = options.baseWidth or baseSize.X.Offset
	local baseHeight = options.baseHeight or baseSize.Y.Offset
	local uiScale = options.uiScale or ensureChild(panel, "UIScale", options.scaleName or "HudResponsivePanelScale")

	panel.Size = baseSize

	local function apply()
		local scale, viewport, isMobile, isLandscapeMobile = HudTileStyle.getResponsivePanelScale(baseWidth, baseHeight, options)
		if options.transformScale then
			scale = options.transformScale(scale, viewport, isMobile, isLandscapeMobile)
		end
		uiScale.Scale = scale
		if options.onLayout then
			options.onLayout({
				Scale = scale,
				Viewport = viewport,
				IsMobile = isMobile,
				IsLandscapeMobile = isLandscapeMobile,
				BaseWidth = baseWidth,
				BaseHeight = baseHeight,
				Panel = panel,
				UIScale = uiScale,
			})
		end
		return scale, viewport, isMobile, isLandscapeMobile
	end

	if not panel:GetAttribute("HudResponsivePanelBound") then
		panel:SetAttribute("HudResponsivePanelBound", true)
		local function bindCamera(camera)
			if not camera then
				return
			end
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
		end

		bindCamera(Workspace.CurrentCamera)
		panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
		Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			bindCamera(Workspace.CurrentCamera)
			apply()
			task.defer(apply)
		end)
	end

	apply()
	task.defer(apply)
	task.delay(0.2, apply)
	task.delay(1, apply)
	return {
		Apply = apply,
		UIScale = uiScale,
		BaseWidth = baseWidth,
		BaseHeight = baseHeight,
	}
end

function HudTileStyle.getImage(repStorage, objectName, fallback)
	local object = repStorage:FindFirstChild(objectName)
	return HudTileStyle.getImageFromObject(object, fallback)
end

function HudTileStyle.playClick()
	local clickTemplate = ReplicatedStorage:FindFirstChild("Click")
	if not clickTemplate or not clickTemplate:IsA("Sound") then
		return
	end

	if not sharedClickSound or sharedClickSound.Parent == nil then
		sharedClickSound = clickTemplate:Clone()
		sharedClickSound.Name = "HudTileClick"
		sharedClickSound.Parent = SoundService
	end

	sharedClickSound.TimePosition = 0
	SoundService:PlayLocalSound(sharedClickSound)
end

local function applyButtonLayout(button, config)
	local metrics = HudTileStyle.getLayoutMetrics()
	local size = UDim2.fromOffset(metrics.ButtonPx, metrics.ButtonPx)
	HudTileStyle.ButtonSize = size
	HudTileStyle.HoverSize = size
	button.Size = size

	local usesManagedLayout = config.side ~= nil and config.slotIndex ~= nil
	if usesManagedLayout then
		managedButtons[button] = config
		if not button:GetAttribute("HudManagedLayoutBound") then
			button:SetAttribute("HudManagedLayoutBound", true)
			button.AncestryChanged:Connect(function()
				if button.Parent == nil then
					managedButtons[button] = nil
				end
				scheduleLayoutRefresh()
			end)
			button:GetPropertyChangedSignal("Visible"):Connect(scheduleLayoutRefresh)
		end
		
		scheduleLayoutRefresh()
		return
	end

	local buttonPosition = config.position
	if buttonPosition then
		local insetCompensation = config.applyInsetCompensation == false and Vector2.zero or getInsetCompensation(button)
		button.Position = offsetUDim2(buttonPosition, insetCompensation.X, insetCompensation.Y)
	end

	if config.onLayout then
		config.onLayout(metrics, button)
	end
end

refreshManagedLayout = function()
	cleanupManagedButtons()
	local metrics = HudTileStyle.getLayoutMetrics()
	local size = UDim2.fromOffset(metrics.ButtonPx, metrics.ButtonPx)
	HudTileStyle.ButtonSize = size
	HudTileStyle.HoverSize = size

	for _, side in ipairs({ "left", "right" }) do
		local entries = {}
		for button, config in pairs(managedButtons) do
			if button.Parent ~= nil and config.side == side then
				table.insert(entries, {
					Button = button,
					Config = config,
				})
			end
		end

		table.sort(entries, function(a, b)
			local aPriority = tonumber(a.Config.slotIndex) or 0
			local bPriority = tonumber(b.Config.slotIndex) or 0
			if aPriority == bPriority then
				return a.Button.Name < b.Button.Name
			end
			return aPriority < bPriority
		end)

		local positions = getManagedSlotCenters(side, #entries, metrics)
		for index, entry in ipairs(entries) do
			local position = positions[math.min(index, #positions)]
			local insetCompensation = entry.Config.applyInsetCompensation == false and Vector2.zero or getInsetCompensation(entry.Button)
			entry.Button.Size = size
			entry.Button.Position = UDim2.fromOffset(
				math.floor(position.X + insetCompensation.X + 0.5),
				math.floor(position.Y + insetCompensation.Y + 0.5)
			)
			if entry.Config.onLayout then
				entry.Config.onLayout(metrics, entry.Button)
			end
		end
	end
end

local function bindTileInteractions(button, icon, stroke, iconState, config)
	if button:GetAttribute("HudInteractionsBound") then
		return
	end
	button:SetAttribute("HudInteractionsBound", true)

	local enableHover = config.enableHover ~= false
	local enableClickSound = config.enableClickSound ~= false
	local baseTransparency = config.backgroundTransparency or HudTileStyle.BaseBackgroundTransparency
	local hoverTransparency = math.max(0.08, baseTransparency - 0.08)
	local hoverStrokeThickness = (config.strokeThickness or 3) + 0.5

	local function refreshResponsiveState()
		if iconState and iconState.Refresh then
			iconState.Refresh()
		else
			applyButtonLayout(button, config)
		end
	end

	if enableHover then
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = hoverTransparency,
			}):Play()
			if icon then
				TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = offsetUDim2(iconState.BasePosition, 0, -4),
					Size = scaleUDim2(iconState.BaseSize, 1.08),
				}):Play()
			end
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Thickness = hoverStrokeThickness,
				}):Play()
			end
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = baseTransparency,
			}):Play()
			if icon then
				TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = iconState.BasePosition,
					Size = iconState.BaseSize,
				}):Play()
			end
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Thickness = config.strokeThickness or 3,
				}):Play()
			end
		end)
	end

	if enableClickSound then
		button.Activated:Connect(HudTileStyle.playClick)
	end

	local function bindCamera(camera)
		if not camera then
			return
		end
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshResponsiveState)
	end

	bindCamera(Workspace.CurrentCamera)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera(Workspace.CurrentCamera)
		refreshResponsiveState()
	end)
end

function HudTileStyle.apply(button, icon, label, config)
	config = config or {}
	local zIndex = config.zIndex or button.ZIndex or 50
	local iconState = {
		BasePosition = UDim2.new(0.5, 0, 0.35, 0),
		BaseSize = UDim2.fromScale(0.78, 0.78),
	}

	local corner = ensureChild(button, "UICorner", "HudCorner")
	local stroke = ensureChild(button, "UIStroke", "HudStroke")
	local gradient = ensureChild(button, "UIGradient", "HudGradient")
	local labelStroke

	local function applyResponsiveStyle()
		local metrics = HudTileStyle.getLayoutMetrics()
		local isMobile = metrics.IsMobile
		local isLandscapeMobile = metrics.IsLandscapeMobile

		iconState.BasePosition = config.iconPosition or (
			isLandscapeMobile and UDim2.new(0.5, 0, 0.29, 0)
			or (isMobile and UDim2.new(0.5, 0, 0.30, 0) or UDim2.new(0.5, 0, 0.35, 0))
		)
		iconState.BaseSize = config.iconSize or (
			isLandscapeMobile and UDim2.fromScale(0.50, 0.50)
			or (isMobile and UDim2.fromScale(0.54, 0.54) or UDim2.fromScale(0.78, 0.78))
		)

		applyButtonLayout(button, config)
		button.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
		button.BackgroundColor3 = config.backgroundColor3 or HudTileStyle.BaseBackgroundColor
		button.BackgroundTransparency = config.backgroundTransparency or HudTileStyle.BaseBackgroundTransparency
		button.BorderSizePixel = 0
		button.ZIndex = zIndex
		button.ClipsDescendants = false
		if button:IsA("GuiButton") then
			button.AutoButtonColor = false
		end
		if button:IsA("ImageButton") then
			button.Image = ""
		end

		corner.CornerRadius = config.cornerRadius or (isLandscapeMobile and UDim.new(0, 12) or (isMobile and UDim.new(0, 14) or UDim.new(0, 20)))

		stroke.Thickness = config.strokeThickness or (isLandscapeMobile and 1.8 or (isMobile and 2 or 3))
		stroke.Color = config.strokeColor or HudTileStyle.BaseStrokeColor
		stroke.Transparency = config.strokeTransparency or 0.03
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, config.topColor or HudTileStyle.BaseTopColor),
			ColorSequenceKeypoint.new(1, config.bottomColor or HudTileStyle.BaseBottomColor),
		})
		gradient.Rotation = config.gradientRotation or 90

		if icon then
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = iconState.BasePosition
			icon.Size = iconState.BaseSize
			icon.ScaleType = Enum.ScaleType.Fit
			icon.ZIndex = zIndex + 1
			icon.Parent = button
		end

		if label then
			label.BackgroundTransparency = 1
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = config.labelPosition or (isLandscapeMobile and UDim2.new(0.5, 0, 0.78, 0) or (isMobile and UDim2.new(0.5, 0, 0.8, 0) or UDim2.new(0.5, 0, 0.89, 0)))
			label.Size = config.labelSize or (isLandscapeMobile and UDim2.new(1.08, 0, 0.28, 0) or (isMobile and UDim2.new(1.0, 0, 0.32, 0) or UDim2.new(1, -8, 0, 24)))
			label.TextColor3 = config.labelColor or HudTileStyle.BaseLabelColor
			label.Font = config.font or Enum.Font.LuckiestGuy
			label.TextScaled = config.textScaled ~= false
			label.TextWrapped = config.textWrapped ~= nil and config.textWrapped or isMobile
			label.TextXAlignment = config.textXAlignment or Enum.TextXAlignment.Center
			label.TextYAlignment = config.textYAlignment or Enum.TextYAlignment.Center
			label.TextSize = config.textSize or (isLandscapeMobile and 11 or (isMobile and 16 or 22))
			label.ZIndex = zIndex + 2
			label.Parent = button

			labelStroke = ensureChild(label, "UIStroke", "HudLabelStroke")
			labelStroke.Thickness = config.labelStrokeThickness or (isLandscapeMobile and 0.85 or (isMobile and 1 or 2))
			labelStroke.Color = config.labelStrokeColor or Color3.fromRGB(0, 0, 0)
			labelStroke.Transparency = 0

			local textConstraint = ensureChild(label, "UITextSizeConstraint", "HudLabelTextConstraint")
			if isLandscapeMobile then
				textConstraint.MinTextSize = config.minTextSize or 7
				textConstraint.MaxTextSize = config.maxTextSize or math.max(9, math.floor(metrics.ButtonPx * 0.20 + 0.5))
			elseif isMobile then
				textConstraint.MinTextSize = config.minTextSize or 7
				textConstraint.MaxTextSize = config.maxTextSize or math.max(10, math.floor(metrics.ButtonPx * 0.23 + 0.5))
			else
				textConstraint.MinTextSize = config.minTextSize or 12
				textConstraint.MaxTextSize = config.maxTextSize or (config.textSize or 22)
			end
		end
	end

	iconState.Refresh = applyResponsiveStyle
	applyResponsiveStyle()

	if config.enableHover ~= false or config.enableClickSound ~= false then
		bindTileInteractions(button, icon, stroke, iconState, config)
	end

	return {
		Stroke = stroke,
		Gradient = gradient,
		LabelStroke = labelStroke,
	}
end

return HudTileStyle
