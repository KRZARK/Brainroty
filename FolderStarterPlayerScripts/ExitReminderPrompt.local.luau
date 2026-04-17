local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

local oldGui = playerGui:FindFirstChild("ExitReminderPromptGui")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExitReminderPromptGui"
screenGui.DisplayOrder = 975
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local greenStudsImage = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")

local function getViewportSize()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local function isMobileLayout()
	return getViewportSize().X <= 900
end

local function getIconImage(name, fallback)
	return HudTileStyle.getImage(ReplicatedStorage, name, fallback or "")
end

local holder = Instance.new("Frame")
holder.Name = "ExitReminderHolder"
holder.BackgroundTransparency = 1
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Visible = false
holder.Parent = screenGui

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0)
card.BackgroundColor3 = Color3.fromRGB(43, 61, 63)
card.BorderSizePixel = 0
card.Parent = holder

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 26)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Thickness = 3
cardStroke.Color = Color3.fromRGB(255, 219, 126)
cardStroke.Parent = card

local cardGradient = Instance.new("UIGradient")
cardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 39, 53)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(43, 61, 63)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(73, 101, 78)),
})
cardGradient.Rotation = 124
cardGradient.Parent = card

local pattern = Instance.new("ImageLabel")
pattern.Name = "Pattern"
pattern.Size = UDim2.fromScale(1, 1)
pattern.BackgroundTransparency = 1
pattern.Image = greenStudsImage
pattern.ImageColor3 = Color3.fromRGB(196, 235, 214)
pattern.ImageTransparency = 0.86
pattern.ScaleType = Enum.ScaleType.Tile
pattern.TileSize = UDim2.fromOffset(124, 124)
pattern.Parent = card

local patternCorner = Instance.new("UICorner")
patternCorner.CornerRadius = UDim.new(0, 26)
patternCorner.Parent = pattern

local topGlow = Instance.new("Frame")
topGlow.Name = "TopGlow"
topGlow.AnchorPoint = Vector2.new(0.5, 0)
topGlow.BackgroundColor3 = Color3.fromRGB(255, 184, 72)
topGlow.BackgroundTransparency = 0.16
topGlow.BorderSizePixel = 0
topGlow.Parent = card

local topGlowCorner = Instance.new("UICorner")
topGlowCorner.CornerRadius = UDim.new(0, 24)
topGlowCorner.Parent = topGlow

local topGlowGradient = Instance.new("UIGradient")
topGlowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 201, 96)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 210)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 174, 62)),
})
topGlowGradient.Rotation = 8
topGlowGradient.Parent = topGlow

local leftIcon = Instance.new("ImageLabel")
leftIcon.Name = "LeftIcon"
leftIcon.AnchorPoint = Vector2.new(0.5, 0.5)
leftIcon.BackgroundTransparency = 1
leftIcon.Image = getIconImage("Crown")
leftIcon.ImageColor3 = Color3.fromRGB(255, 239, 205)
leftIcon.ImageTransparency = 0.18
leftIcon.Rotation = -12
leftIcon.ZIndex = 3
leftIcon.Parent = card

local rightIcon = Instance.new("ImageLabel")
rightIcon.Name = "RightIcon"
rightIcon.AnchorPoint = Vector2.new(0.5, 0.5)
rightIcon.BackgroundTransparency = 1
rightIcon.Image = getIconImage("Coin2D")
rightIcon.ImageColor3 = Color3.fromRGB(255, 216, 96)
rightIcon.ImageTransparency = 0.2
rightIcon.Rotation = 14
rightIcon.ZIndex = 3
rightIcon.Parent = card

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.LuckiestGuy
title.Text = "HEY SIGMA!"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Center
title.ZIndex = 7
title.Parent = card

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 26
titleConstraint.MaxTextSize = 44
titleConstraint.Parent = title

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 3
titleStroke.Color = Color3.fromRGB(86, 47, 0)
titleStroke.Parent = title

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 234, 153)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 210, 108)),
})
titleGradient.Rotation = 10
titleGradient.Parent = title

local body = Instance.new("TextLabel")
body.Name = "Body"
body.AnchorPoint = Vector2.new(0.5, 0)
body.BackgroundTransparency = 1
body.Font = Enum.Font.FredokaOne
body.Text = "Don't forget to like the game\nand come back later\nto find more brainrots!"
body.TextColor3 = Color3.fromRGB(255, 249, 228)
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Center
body.TextYAlignment = Enum.TextYAlignment.Top
body.ZIndex = 7
body.Parent = card

local bodyStroke = Instance.new("UIStroke")
bodyStroke.Thickness = 2
bodyStroke.Color = Color3.fromRGB(82, 49, 8)
bodyStroke.Transparency = 0.12
bodyStroke.Parent = body

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.BackgroundColor3 = Color3.fromRGB(252, 226, 149)
footer.BorderSizePixel = 0
footer.ZIndex = 7
footer.Parent = card

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(1, 0)
footerCorner.Parent = footer

local footerStroke = Instance.new("UIStroke")
footerStroke.Thickness = 2
footerStroke.Color = Color3.fromRGB(109, 69, 15)
footerStroke.Transparency = 0.1
footerStroke.Parent = footer

local footerLabel = Instance.new("TextLabel")
footerLabel.Name = "FooterLabel"
footerLabel.Size = UDim2.fromScale(1, 1)
footerLabel.BackgroundTransparency = 1
footerLabel.Font = Enum.Font.FredokaOne
footerLabel.Text = "Thanks for playing."
footerLabel.TextColor3 = Color3.fromRGB(84, 52, 9)
footerLabel.TextXAlignment = Enum.TextXAlignment.Center
footerLabel.ZIndex = 8
footerLabel.Parent = footer

local cardScale = Instance.new("UIScale")
cardScale.Scale = 0.94
cardScale.Parent = card

local activeTween
local isVisible = false
local openToken = 0

local function getVisiblePosition(width)
	if isMobileLayout() then
		return UDim2.new(0.5, 0, 0, 26)
	end

	return UDim2.new(1, -26, 0, 124)
end

local function getHiddenPosition(width, height)
	if isMobileLayout() then
		return UDim2.new(0.5, 0, 0, -height - 24)
	end

	return UDim2.new(1, width + 36, 0, 124)
end

local function applyLayout()
	local mobile = isMobileLayout()
	local viewport = getViewportSize()
	local holderWidth = mobile and math.floor(viewport.X * 0.94 + 0.5) or 520
	local holderHeight = mobile and 320 or 336
	local visiblePosition = getVisiblePosition(holderWidth)
	local hiddenPosition = getHiddenPosition(holderWidth, holderHeight)

	holder.Size = UDim2.fromOffset(holderWidth, holderHeight)
	holder.AnchorPoint = mobile and Vector2.new(0.5, 0) or Vector2.new(1, 0)
	holder.Position = isVisible and visiblePosition or hiddenPosition

	card.Size = UDim2.fromOffset(holderWidth, holderHeight)
	card.Position = UDim2.fromOffset(holderWidth / 2, 0)

	topGlow.Size = UDim2.new(1, -20, 0, mobile and 94 or 106)
	topGlow.Position = UDim2.new(0.5, 0, 0, 10)

	leftIcon.Size = mobile and UDim2.fromOffset(74, 74) or UDim2.fromOffset(82, 82)
	leftIcon.Position = UDim2.new(0.11, 0, mobile and 0.78 or 0.8, 0)

	rightIcon.Size = mobile and UDim2.fromOffset(74, 74) or UDim2.fromOffset(80, 80)
	rightIcon.Position = UDim2.new(0.89, 0, mobile and 0.24 or 0.22, 0)

	title.Size = UDim2.new(0.88, 0, 0, mobile and 54 or 62)
	title.Position = UDim2.new(0.5, 0, 0, mobile and 57 or 63)

	body.Size = UDim2.new(0.84, 0, 0, mobile and 126 or 132)
	body.Position = UDim2.new(0.5, 0, 0, mobile and 118 or 126)
	body.TextSize = mobile and 30 or 34

	footer.Size = UDim2.new(0.72, 0, 0, mobile and 52 or 58)
	footer.Position = UDim2.new(0.5, 0, 1, mobile and -18 or -20)
	footerLabel.TextSize = mobile and 24 or 28
end

applyLayout()

local function stopTween()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
end

local function showReminder()
	if isVisible then
		return
	end

	isVisible = true
	applyLayout()
	holder.Visible = true
	cardScale.Scale = 0.94
	stopTween()

	local visiblePosition = getVisiblePosition(holder.AbsoluteSize.X)
	local tweenPosition = TweenService:Create(holder, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = visiblePosition,
	})
	local tweenScale = TweenService:Create(cardScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	})
	activeTween = tweenPosition
	tweenPosition:Play()
	tweenScale:Play()
	tweenPosition.Completed:Connect(function()
		if activeTween == tweenPosition then
			activeTween = nil
		end
	end)
end

local function hideReminder()
	if not isVisible then
		return
	end

	isVisible = false
	stopTween()

	local hiddenPosition = getHiddenPosition(holder.AbsoluteSize.X, holder.AbsoluteSize.Y)
	local tweenPosition = TweenService:Create(holder, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = hiddenPosition,
	})
	local tweenScale = TweenService:Create(cardScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.96,
	})
	activeTween = tweenPosition
	tweenPosition:Play()
	tweenScale:Play()
	tweenPosition.Completed:Connect(function()
		if activeTween == tweenPosition then
			activeTween = nil
		end
		if not isVisible then
			holder.Visible = false
		end
	end)
end

GuiService.MenuOpened:Connect(function()
	openToken += 1
	local token = openToken

	task.delay(0.18, function()
		if token ~= openToken then
			return
		end

		if GuiService.MenuIsOpen then
			showReminder()
		end
	end)
end)

GuiService.MenuClosed:Connect(function()
	openToken += 1
	hideReminder()
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	applyLayout()
end)
