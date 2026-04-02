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
		return camera.ViewportSize
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
	return UserInputService.TouchEnabled and viewport.X <= 1024
end

function HudTileStyle.getLayoutMetrics()
	local viewport = getViewportSize()
	local isMobile = HudTileStyle.isMobileLayout()
	local rows = 5

	local topSafe = isMobile and math.max(74, math.floor(viewport.Y * 0.19 + 0.5)) or math.max(164, math.floor(viewport.Y * 0.18 + 0.5))
	local bottomSafe = isMobile and math.max(44, math.floor(viewport.Y * 0.12 + 0.5)) or math.max(64, math.floor(viewport.Y * 0.08 + 0.5))
	local leftMargin = isMobile and math.max(12, math.floor(viewport.X * 0.02 + 0.5)) or 26
	local rightMargin = isMobile and math.max(12, math.floor(viewport.X * 0.02 + 0.5)) or 32
	local widthCap = isMobile and (viewport.X * 0.10) or (viewport.X * 0.082)
	local heightCap = (viewport.Y - topSafe - bottomSafe) / (rows + 0.12 * (rows - 1))
	local buttonPx = math.floor(math.clamp(math.min(widthCap, heightCap), isMobile and 34 or 70, isMobile and 52 or 104) + 0.5)
	local gapPx = isMobile and math.max(5, math.floor(buttonPx * 0.10 + 0.5)) or math.max(8, math.floor(buttonPx * 0.10 + 0.5))
	local totalHeight = (buttonPx * rows) + (gapPx * (rows - 1))
	local spareSpace = math.max(0, viewport.Y - topSafe - bottomSafe - totalHeight)
	local startY = topSafe + math.floor(spareSpace * 0.08 + 0.5) + (buttonPx / 2)

	return {
		Viewport = viewport,
		IsMobile = isMobile,
		ButtonPx = buttonPx,
		GapPx = gapPx,
		LeftX = leftMargin + (buttonPx / 2),
		RightX = viewport.X - rightMargin - (buttonPx / 2),
		StartY = startY,
	}
end

function HudTileStyle.getButtonSize()
	local metrics = HudTileStyle.getLayoutMetrics()
	return UDim2.fromOffset(metrics.ButtonPx, metrics.ButtonPx)
end

function HudTileStyle.getSlot(side, index)
	local metrics = HudTileStyle.getLayoutMetrics()
	local x = side == "right" and metrics.RightX or metrics.LeftX
	local y = metrics.StartY + ((index - 1) * (metrics.ButtonPx + metrics.GapPx))
	return UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
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
	button.Size = HudTileStyle.getButtonSize()

	local buttonPosition
	if config.side and config.slotIndex then
		buttonPosition = HudTileStyle.getSlot(config.side, config.slotIndex)
	elseif config.position then
		buttonPosition = config.position
	end

	if buttonPosition then
		local insetCompensation = config.applyInsetCompensation == false and Vector2.zero or getInsetCompensation(button)
		button.Position = offsetUDim2(buttonPosition, insetCompensation.X, insetCompensation.Y)
	end

	if config.onLayout then
		config.onLayout(HudTileStyle.getLayoutMetrics(), button)
	end
end

local function bindTileInteractions(button, icon, stroke, iconBasePosition, iconBaseSize, config)
	if button:GetAttribute("HudInteractionsBound") then
		return
	end
	button:SetAttribute("HudInteractionsBound", true)

	local enableHover = config.enableHover ~= false
	local enableClickSound = config.enableClickSound ~= false
	local baseTransparency = config.backgroundTransparency or HudTileStyle.BaseBackgroundTransparency
	local hoverTransparency = math.max(0.08, baseTransparency - 0.08)
	local iconHoverPosition = offsetUDim2(iconBasePosition, 0, -4)
	local iconHoverSize = scaleUDim2(iconBaseSize, 1.08)
	local hoverStrokeThickness = (config.strokeThickness or 3) + 0.5

	if enableHover then
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = hoverTransparency,
			}):Play()
			if icon then
				TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = iconHoverPosition,
					Size = iconHoverSize,
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
					Position = iconBasePosition,
					Size = iconBaseSize,
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
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyButtonLayout(button, config)
		end)
	end

	bindCamera(Workspace.CurrentCamera)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera(Workspace.CurrentCamera)
		applyButtonLayout(button, config)
	end)
end

function HudTileStyle.apply(button, icon, label, config)
	config = config or {}
	local zIndex = config.zIndex or button.ZIndex or 50
	local iconBasePosition = config.iconPosition or UDim2.new(0.5, 0, 0.35, 0)
	local iconBaseSize = config.iconSize or UDim2.fromScale(0.78, 0.78)

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

	local corner = ensureChild(button, "UICorner", "HudCorner")
	corner.CornerRadius = config.cornerRadius or UDim.new(0, 20)

	local stroke = ensureChild(button, "UIStroke", "HudStroke")
	stroke.Thickness = config.strokeThickness or 3
	stroke.Color = config.strokeColor or HudTileStyle.BaseStrokeColor
	stroke.Transparency = config.strokeTransparency or 0.03
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradient = ensureChild(button, "UIGradient", "HudGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, config.topColor or HudTileStyle.BaseTopColor),
		ColorSequenceKeypoint.new(1, config.bottomColor or HudTileStyle.BaseBottomColor),
	})
	gradient.Rotation = config.gradientRotation or 90

	if icon then
		icon.BackgroundTransparency = 1
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = iconBasePosition
		icon.Size = iconBaseSize
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = zIndex + 1
		icon.Parent = button
	end

	local labelStroke
	if label then
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = config.labelPosition or UDim2.new(0.5, 0, 0.89, 0)
		label.Size = config.labelSize or UDim2.new(1, -8, 0, 24)
		label.TextColor3 = config.labelColor or HudTileStyle.BaseLabelColor
		label.Font = config.font or Enum.Font.LuckiestGuy
		label.TextScaled = config.textScaled ~= false
		label.TextWrapped = false
		label.TextSize = config.textSize or 22
		label.ZIndex = zIndex + 2
		label.Parent = button

		labelStroke = ensureChild(label, "UIStroke", "HudLabelStroke")
		labelStroke.Thickness = config.labelStrokeThickness or 2
		labelStroke.Color = config.labelStrokeColor or Color3.fromRGB(0, 0, 0)
		labelStroke.Transparency = 0
	end

	if config.enableHover ~= false or config.enableClickSound ~= false then
		bindTileInteractions(button, icon, stroke, iconBasePosition, iconBaseSize, config)
	end

	return {
		Stroke = stroke,
		Gradient = gradient,
		LabelStroke = labelStroke,
	}
end

return HudTileStyle
