local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local premiumPurchaseCelebrationEvent = BrainrotEvents:WaitForChild("PremiumPurchaseCelebration")

local oldGui = playerGui:FindFirstChild("PremiumPurchaseNotificationGui")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PremiumPurchaseNotificationGui"
screenGui.DisplayOrder = 980
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

local function createLabel(parent, props)
	local label = Instance.new(props.className or "TextLabel")
	label.Name = props.name or "Label"
	label.BackgroundTransparency = props.backgroundTransparency or 1
	label.Size = props.size or UDim2.fromScale(1, 1)
	label.Position = props.position or UDim2.fromScale(0, 0)
	label.AnchorPoint = props.anchorPoint or Vector2.zero
	label.ZIndex = props.zIndex or 1
	label.Parent = parent

	if label:IsA("TextLabel") or label:IsA("TextButton") then
		label.Text = props.text or ""
		label.TextColor3 = props.textColor3 or Color3.new(1, 1, 1)
		label.TextTransparency = props.textTransparency or 0
		label.TextScaled = props.textScaled or false
		label.TextSize = props.textSize or 20
		label.TextWrapped = props.textWrapped or false
		label.Font = props.font or Enum.Font.FredokaOne
		label.TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left
		label.TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center
	end

	return label
end

local function createStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function addPattern(parent, color, transparency, tileSize, zIndex, cornerRadius)
	local pattern = Instance.new("ImageLabel")
	pattern.Name = "Pattern"
	pattern.Size = UDim2.fromScale(1, 1)
	pattern.BackgroundTransparency = 1
	pattern.Image = greenStudsImage
	pattern.ImageColor3 = color
	pattern.ImageTransparency = transparency
	pattern.ScaleType = Enum.ScaleType.Tile
	pattern.TileSize = tileSize or UDim2.fromOffset(120, 120)
	pattern.ZIndex = zIndex or parent.ZIndex
	pattern.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = cornerRadius or UDim.new(0, 20)
	corner.Parent = pattern

	return pattern
end

local function createCard(parent, size, position, backgroundColor, gradientColors, strokeColor, cornerRadius, zIndex)
	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = backgroundColor
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = cornerRadius or UDim.new(0, 20)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = strokeColor
	stroke.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(gradientColors)
	gradient.Rotation = 120
	gradient.Parent = frame

	return frame
end

local function getIconImage(name, fallback)
	return HudTileStyle.getImage(ReplicatedStorage, name, fallback or "")
end

local function createIcon(parent, props)
	local icon = Instance.new("ImageLabel")
	icon.Name = props.name or "Icon"
	icon.Size = props.size
	icon.Position = props.position
	icon.AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = props.image or ""
	icon.ImageColor3 = props.imageColor3 or Color3.new(1, 1, 1)
	icon.ImageTransparency = props.imageTransparency or 0
	icon.Rotation = props.rotation or 0
	icon.ZIndex = props.zIndex or 1
	icon.Parent = parent
	return icon
end

local notificationQueue = {}
local isShowingNotification = false
local NOTIFICATION_DISPLAY_SECONDS = 7

local PURCHASE_CONFIG = {
	VIP = {
		style = "vip",
		title = "ULTIMATE VIP BUNDLE",
		subtitle = "VIP UNLOCKED",
		badge = "PURCHASE COMPLETE",
		perks = "x2 Coins, +Speed, +Jump, VIP Tag,\nSilver Trail, Troll Shield",
		footer = "All VIP perks are now active.",
	},
	SpeedBoost = {
		style = "toast",
		title = "2X SPEED UNLOCKED",
		subtitle = "Your movement boost is ready to use.",
		iconName = "speed",
		accent = Color3.fromRGB(123, 226, 255),
		base = Color3.fromRGB(32, 65, 97),
		pattern = Color3.fromRGB(138, 230, 255),
	},
	JumpBoost = {
		style = "toast",
		title = "2X JUMP UNLOCKED",
		subtitle = "Your jump boost is ready to use.",
		iconName = "Jump",
		accent = Color3.fromRGB(152, 255, 168),
		base = Color3.fromRGB(31, 87, 50),
		pattern = Color3.fromRGB(183, 255, 193),
	},
}

local function playToastNotification(config)
	local mobile = isMobileLayout()
	local width = mobile and 300 or 360
	local height = mobile and 92 or 104
	local topInset = mobile and 84 or 104

	local holder = Instance.new("Frame")
	holder.Name = "ToastHolder"
	holder.Size = UDim2.fromOffset(width, height)
	holder.Position = UDim2.new(1, width + 40, 0, topInset)
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 1000
	holder.Parent = screenGui

	local card = createCard(
		holder,
		UDim2.fromScale(1, 1),
		UDim2.fromScale(0.5, 0.5),
		config.base,
		{
			ColorSequenceKeypoint.new(0, config.base:Lerp(Color3.fromRGB(14, 18, 23), 0.22)),
			ColorSequenceKeypoint.new(1, config.base:Lerp(config.accent, 0.18)),
		},
		config.accent:Lerp(Color3.new(1, 1, 1), 0.25),
		UDim.new(0, 24),
		1001
	)

	addPattern(card, config.pattern, 0.84, UDim2.fromOffset(96, 96), 1001, UDim.new(0, 24))

	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.Size = UDim2.new(0.86, 0, 1.3, 0)
	glow.Position = UDim2.fromScale(0.16, -0.12)
	glow.BackgroundTransparency = 0.28
	glow.BackgroundColor3 = config.accent
	glow.BorderSizePixel = 0
	glow.ZIndex = 1000
	glow.Parent = card
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glow

	local iconBadge = Instance.new("Frame")
	iconBadge.Name = "IconBadge"
	iconBadge.Size = mobile and UDim2.fromOffset(62, 62) or UDim2.fromOffset(70, 70)
	iconBadge.Position = UDim2.new(0, 18, 0.5, 0)
	iconBadge.AnchorPoint = Vector2.new(0, 0.5)
	iconBadge.BackgroundColor3 = config.accent
	iconBadge.BorderSizePixel = 0
	iconBadge.ZIndex = 1003
	iconBadge.Parent = card
	local iconBadgeCorner = Instance.new("UICorner")
	iconBadgeCorner.CornerRadius = UDim.new(1, 0)
	iconBadgeCorner.Parent = iconBadge
	createStroke(iconBadge, Color3.fromRGB(8, 12, 18), 2.5, 0.2)

	createIcon(iconBadge, {
		name = "BoostIcon",
		size = mobile and UDim2.fromOffset(34, 34) or UDim2.fromOffset(40, 40),
		position = UDim2.fromScale(0.5, 0.5),
		image = getIconImage(config.iconName),
		imageColor3 = Color3.new(1, 1, 1),
		zIndex = 1004,
	})

	local purchasedLabel = createLabel(card, {
		name = "PurchasedLabel",
		size = UDim2.fromOffset(width - 120, 18),
		position = UDim2.fromOffset(102, 14),
		text = "PURCHASED",
		font = Enum.Font.FredokaOne,
		textSize = mobile and 14 or 15,
		textColor3 = config.accent:Lerp(Color3.new(1, 1, 1), 0.2),
		zIndex = 1004,
	})
	local purchasedGradient = Instance.new("UIGradient")
	purchasedGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, config.accent),
		ColorSequenceKeypoint.new(1, config.accent:Lerp(Color3.new(1, 1, 1), 0.3)),
	})
	purchasedGradient.Parent = purchasedLabel

	createLabel(card, {
		name = "Title",
		size = UDim2.new(1, -126, 0, mobile and 28 or 32),
		position = UDim2.fromOffset(102, 30),
		text = config.title,
		font = Enum.Font.LuckiestGuy,
		textSize = mobile and 24 or 28,
		textColor3 = Color3.new(1, 1, 1),
		zIndex = 1004,
	})

	createLabel(card, {
		name = "Subtitle",
		size = UDim2.new(1, -126, 0, mobile and 28 or 32),
		position = UDim2.fromOffset(102, mobile and 58 or 64),
		text = config.subtitle,
		font = Enum.Font.FredokaOne,
		textSize = mobile and 14 or 16,
		textWrapped = true,
		textColor3 = Color3.fromRGB(231, 240, 247),
		zIndex = 1004,
	})

	local tweenIn = TweenService:Create(holder, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -24, 0, topInset),
	})
	tweenIn:Play()
	tweenIn.Completed:Wait()

	task.wait(NOTIFICATION_DISPLAY_SECONDS)

	local tweenOut = TweenService:Create(holder, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, width + 50, 0, topInset),
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()
	holder:Destroy()
end

local function playVipNotification(config)
	local mobile = isMobileLayout()

	local overlay = Instance.new("Frame")
	overlay.Name = "VipOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(7, 10, 15)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1100
	overlay.Parent = screenGui

	local cardSize = mobile and UDim2.new(0.88, 0, 0, 280) or UDim2.new(0, 620, 0, 340)
	local card = createCard(
		overlay,
		cardSize,
		UDim2.new(0.5, 0, 0.46, 0),
		Color3.fromRGB(43, 61, 63),
		{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 39, 53)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(43, 61, 63)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(73, 101, 78)),
		},
		Color3.fromRGB(255, 217, 117),
		UDim.new(0, 26),
		1101
	)

	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 0.84
	cardScale.Parent = card

	addPattern(card, Color3.fromRGB(196, 235, 214), 0.84, UDim2.fromOffset(124, 124), 1101, UDim.new(0, 26))

	local goldGlow = Instance.new("Frame")
	goldGlow.Name = "GoldGlow"
	goldGlow.Size = UDim2.new(1, -24, 0, mobile and 80 or 96)
	goldGlow.Position = UDim2.new(0.5, 0, 0, 12)
	goldGlow.AnchorPoint = Vector2.new(0.5, 0)
	goldGlow.BackgroundColor3 = Color3.fromRGB(255, 187, 64)
	goldGlow.BackgroundTransparency = 0.26
	goldGlow.BorderSizePixel = 0
	goldGlow.ZIndex = 1102
	goldGlow.Parent = card
	local goldGlowCorner = Instance.new("UICorner")
	goldGlowCorner.CornerRadius = UDim.new(0, 22)
	goldGlowCorner.Parent = goldGlow
	local goldGlowGradient = Instance.new("UIGradient")
	goldGlowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 209, 108)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 210)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 178, 70)),
	})
	goldGlowGradient.Rotation = 8
	goldGlowGradient.Parent = goldGlow

	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(mobile and 166 or 196, 34)
	badge.Position = UDim2.new(0.5, 0, 0, 18)
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.BackgroundColor3 = Color3.fromRGB(255, 213, 92)
	badge.BorderSizePixel = 0
	badge.ZIndex = 1104
	badge.Parent = card
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = badge
	createStroke(badge, Color3.fromRGB(103, 66, 18), 2.2, 0.05)
	createLabel(badge, {
		name = "BadgeText",
		size = UDim2.fromScale(1, 1),
		text = config.badge,
		font = Enum.Font.FredokaOne,
		textSize = mobile and 14 or 15,
		textColor3 = Color3.fromRGB(74, 44, 8),
		textXAlignment = Enum.TextXAlignment.Center,
		zIndex = 1105,
	})

	local vipBackdropAssets = {
		{ name = "Coin2D", position = UDim2.new(0.12, 0, 0.24, 0), size = mobile and UDim2.fromOffset(72, 72) or UDim2.fromOffset(96, 96), rotation = -18, color = Color3.fromRGB(255, 226, 104), transparency = 0.6 },
		{ name = "Crown", position = UDim2.new(0.88, 0, 0.22, 0), size = mobile and UDim2.fromOffset(84, 84) or UDim2.fromOffset(112, 112), rotation = 16, color = Color3.fromRGB(255, 247, 221), transparency = 0.62 },
		{ name = "speed", position = UDim2.new(0.14, 0, 0.72, 0), size = mobile and UDim2.fromOffset(70, 70) or UDim2.fromOffset(90, 90), rotation = -12, color = Color3.fromRGB(145, 236, 255), transparency = 0.64 },
		{ name = "Jump", position = UDim2.new(0.86, 0, 0.72, 0), size = mobile and UDim2.fromOffset(70, 70) or UDim2.fromOffset(90, 90), rotation = 12, color = Color3.fromRGB(181, 255, 198), transparency = 0.64 },
	}

	for _, iconConfig in ipairs(vipBackdropAssets) do
		createIcon(card, {
			name = iconConfig.name .. "Backdrop",
			size = iconConfig.size,
			position = iconConfig.position,
			image = getIconImage(iconConfig.name),
			imageColor3 = iconConfig.color,
			imageTransparency = iconConfig.transparency,
			rotation = iconConfig.rotation,
			zIndex = 1103,
		})
	end

	local title = createLabel(card, {
		name = "VipTitle",
		size = UDim2.new(0.82, 0, 0, mobile and 50 or 64),
		position = UDim2.new(0.5, 0, 0, mobile and 62 or 68),
		anchorPoint = Vector2.new(0.5, 0),
		text = config.title,
		font = Enum.Font.LuckiestGuy,
		textScaled = true,
		textColor3 = Color3.new(1, 1, 1),
		textXAlignment = Enum.TextXAlignment.Center,
		zIndex = 1106,
	})
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = mobile and 24 or 28
	titleConstraint.MaxTextSize = mobile and 34 or 42
	titleConstraint.Parent = title
	createStroke(title, Color3.fromRGB(86, 47, 0), 3, 0)
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 234, 153)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 210, 108)),
	})
	titleGradient.Rotation = 12
	titleGradient.Parent = title

	createLabel(card, {
		name = "VipSubtitle",
		size = UDim2.new(0.78, 0, 0, 26),
		position = UDim2.new(0.5, 0, 0, mobile and 116 or 130),
		anchorPoint = Vector2.new(0.5, 0),
		text = config.subtitle,
		font = Enum.Font.FredokaOne,
		textSize = mobile and 18 or 20,
		textColor3 = Color3.fromRGB(255, 249, 228),
		textXAlignment = Enum.TextXAlignment.Center,
		zIndex = 1106,
	})

	local perks = createLabel(card, {
		name = "VipPerks",
		size = UDim2.new(0.78, 0, 0, mobile and 72 or 88),
		position = UDim2.new(0.5, 0, 0, mobile and 150 or 174),
		anchorPoint = Vector2.new(0.5, 0),
		text = config.perks,
		font = Enum.Font.FredokaOne,
		textSize = mobile and 16 or 20,
		textWrapped = true,
		textColor3 = Color3.fromRGB(255, 249, 228),
		textXAlignment = Enum.TextXAlignment.Center,
		textYAlignment = Enum.TextYAlignment.Center,
		zIndex = 1106,
	})
	createStroke(perks, Color3.fromRGB(82, 49, 8), 2, 0.12)

	local footerPill = Instance.new("Frame")
	footerPill.Name = "FooterPill"
	footerPill.Size = UDim2.new(0.68, 0, 0, mobile and 34 or 38)
	footerPill.Position = UDim2.new(0.5, 0, 1, mobile and -24 or -28)
	footerPill.AnchorPoint = Vector2.new(0.5, 1)
	footerPill.BackgroundColor3 = Color3.fromRGB(252, 226, 149)
	footerPill.BorderSizePixel = 0
	footerPill.ZIndex = 1106
	footerPill.Parent = card
	local footerPillCorner = Instance.new("UICorner")
	footerPillCorner.CornerRadius = UDim.new(1, 0)
	footerPillCorner.Parent = footerPill
	createStroke(footerPill, Color3.fromRGB(109, 69, 15), 2, 0.1)
	createLabel(footerPill, {
		name = "FooterText",
		size = UDim2.fromScale(1, 1),
		text = config.footer,
		font = Enum.Font.FredokaOne,
		textSize = mobile and 13 or 15,
		textColor3 = Color3.fromRGB(83, 52, 7),
		textXAlignment = Enum.TextXAlignment.Center,
		zIndex = 1107,
	})

	local tweenOverlayIn = TweenService:Create(overlay, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.36,
	})
	local tweenCardIn = TweenService:Create(cardScale, TweenInfo.new(0.44, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	})
	tweenOverlayIn:Play()
	tweenCardIn:Play()
	tweenCardIn.Completed:Wait()

	task.wait(NOTIFICATION_DISPLAY_SECONDS)

	local tweenOverlayOut = TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})
	local tweenCardOut = TweenService:Create(cardScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.9,
	})
	tweenOverlayOut:Play()
	tweenCardOut:Play()
	tweenCardOut.Completed:Wait()
	overlay:Destroy()
end

local function processQueue()
	if isShowingNotification then
		return
	end

	isShowingNotification = true

	while #notificationQueue > 0 do
		local notificationType = table.remove(notificationQueue, 1)
		local config = PURCHASE_CONFIG[notificationType]

		if config then
			if config.style == "vip" then
				playVipNotification(config)
			else
				playToastNotification(config)
			end
		end

		task.wait(0.08)
	end

	isShowingNotification = false
end

premiumPurchaseCelebrationEvent.OnClientEvent:Connect(function(notificationType)
	if type(notificationType) ~= "string" or PURCHASE_CONFIG[notificationType] == nil then
		return
	end

	table.insert(notificationQueue, notificationType)
	processQueue()
end)
