local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local claimEvent = BrainrotEvents:WaitForChild("ClaimPlaytimeReward")
local getTimeEvent = BrainrotEvents:WaitForChild("GetPlaytimeData")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HudTileStyle = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("HudTileStyle"))
local greenStudsImage = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")

local function playClaimRewardSound()
	local soundTemplate = ReplicatedStorage:FindFirstChild("Claimed")
	if soundTemplate and soundTemplate:IsA("Sound") then
		local sound = soundTemplate:Clone()
		sound.Volume = 2
		sound.Parent = workspace
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 3)
	end
end

-- Inicjalizacja Danych z Serwera
local sessionStartTime = os.time()
local claimedRewards = {}
local rewardRows = {}

local function resetPlaytimeCycleClient(newStartTime)
	sessionStartTime = tonumber(newStartTime) or os.time()
	claimedRewards = {}

	for _, rowObj in ipairs(rewardRows) do
		rowObj.Button.Text = "LOCKED"
		rowObj.Button.BackgroundColor3 = Color3.fromRGB(90, 96, 104)
	end
end

-- Pobranie prawdziwego czasu z serwera po załadowaniu
task.spawn(function()
	local st, claimed = getTimeEvent:InvokeServer()
	if st and claimed then
		sessionStartTime = st
		claimedRewards = claimed
	end
end)

-- Zmiana rozmiaru i struktura UI
local oldGui = playerGui:FindFirstChild("PlaytimeRewardsUI")
if oldGui then oldGui:Destroy() end

local oldToggle = playerGui:FindFirstChild("PlaytimeRewardsToggleUI")
if oldToggle then oldToggle:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlaytimeRewardsUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
backdrop.BackgroundTransparency = 1
backdrop.Visible = false
backdrop.ZIndex = 99
backdrop.Parent = screenGui

-- Pobranie zasobów wizualnych
local Coin2D = ReplicatedStorage:WaitForChild("Coin2D")
local Wykrzyknik = ReplicatedStorage:WaitForChild("Wykrzyknik")

-- === 1. PRZYCISK Z LEWEJ STRONY ===
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "PlaytimeRewardsToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = playerGui

local giftBtn = Instance.new("ImageButton")
giftBtn.Name = "GiftButton"
giftBtn.Position = HudTileStyle.getSlot("right", 2)
giftBtn.ZIndex = 50
giftBtn.Parent = ToggleGui

local giftIcon = Instance.new("ImageLabel")
giftIcon.Name = "GiftIcon"
giftIcon.Image = Coin2D:IsA("Decal") and Coin2D.Texture or Coin2D.Image
giftIcon.Parent = giftBtn

local giftTitle = Instance.new("TextLabel")
giftTitle.Text = "PLAYTIME"
giftTitle.Parent = giftBtn

HudTileStyle.apply(giftBtn, giftIcon, giftTitle, {
	side = "right",
	slotIndex = 2,
	zIndex = 50,
})

-- Wykrzyknik
local giftNotif = Instance.new("ImageLabel")
giftNotif.Size = UDim2.fromOffset(36, 36)
giftNotif.Position = UDim2.new(1, -6, 0, 6)
giftNotif.BackgroundTransparency = 1
giftNotif.Image = Wykrzyknik:IsA("Decal") and Wykrzyknik.Texture or Wykrzyknik.Image
giftNotif.Visible = false
giftNotif.AnchorPoint = Vector2.new(1, 0)
giftNotif.ZIndex = 55
giftNotif.Parent = giftBtn

-- Licznik czasu pod ikonką
local giftTimerLbl = Instance.new("TextLabel")
giftTimerLbl.Size = UDim2.new(0.76, 0, 0, 20)
giftTimerLbl.AnchorPoint = Vector2.new(0.5, 0.5)
giftTimerLbl.Position = UDim2.new(0.5, 0, 0.63, 0)
giftTimerLbl.BackgroundColor3 = Color3.fromRGB(20, 24, 29)
giftTimerLbl.BackgroundTransparency = 0.15
giftTimerLbl.Text = ""
giftTimerLbl.TextColor3 = Color3.new(1, 1, 1)
giftTimerLbl.Font = Enum.Font.FredokaOne
giftTimerLbl.TextSize = 14
giftTimerLbl.ZIndex = 53
giftTimerLbl.Parent = giftBtn
Instance.new("UICorner", giftTimerLbl).CornerRadius = UDim.new(0, 5)
local giftTimerStroke = Instance.new("UIStroke", giftTimerLbl)
giftTimerStroke.Thickness = 1
giftTimerStroke.Color = Color3.new(0, 0, 0)

-- Licznik monet NA DOLE obrazka
local giftAmountLbl = Instance.new("TextLabel")
giftAmountLbl.Size = UDim2.new(1, -14, 0, 18)
giftAmountLbl.AnchorPoint = Vector2.new(0.5, 0.5)
giftAmountLbl.Position = UDim2.new(0.5, 0, 0.16, 0)
giftAmountLbl.BackgroundTransparency = 1
giftAmountLbl.Text = ""
giftAmountLbl.TextColor3 = Color3.fromRGB(255, 230, 0)
giftAmountLbl.Font = Enum.Font.LuckiestGuy
giftAmountLbl.TextSize = 16
giftAmountLbl.ZIndex = 54
giftAmountLbl.Parent = giftBtn
local amtStroke = Instance.new("UIStroke", giftAmountLbl)
amtStroke.Thickness = 2
amtStroke.Color = Color3.new(0, 0, 0)

local function updateGiftButtonLayout()
	local metrics = HudTileStyle.getLayoutMetrics()
	if metrics.IsLandscapeMobile then
		giftTitle.Text = "PLAYTIME"
		giftNotif.Size = UDim2.fromOffset(24, 24)
		giftNotif.Position = UDim2.new(1, -1, 0, 1)
		giftTimerLbl.Size = UDim2.new(0.92, 0, 0, 14)
		giftTimerLbl.Position = UDim2.new(0.5, 0, 0.57, 0)
		giftTimerLbl.TextSize = 11
		giftAmountLbl.Visible = false
	elseif metrics.IsMobile then
		giftTitle.Text = "PLAYTIME"
		giftNotif.Size = UDim2.fromOffset(22, 22)
		giftNotif.Position = UDim2.new(1, -1, 0, 1)
		giftTimerLbl.Size = UDim2.new(0.9, 0, 0, 12)
		giftTimerLbl.Position = UDim2.new(0.5, 0, 0.57, 0)
		giftTimerLbl.TextSize = 10
		giftAmountLbl.Visible = false
	else
		giftTitle.Text = "PLAYTIME"
		giftNotif.Size = UDim2.fromOffset(36, 36)
		giftNotif.Position = UDim2.new(1, -6, 0, 6)
		giftTimerLbl.Size = UDim2.new(0.76, 0, 0, 20)
		giftTimerLbl.Position = UDim2.new(0.5, 0, 0.63, 0)
		giftTimerLbl.TextSize = 14
		giftAmountLbl.Visible = true
	end
end

updateGiftButtonLayout()

local function bindGiftLayoutCamera(camera)
	if not camera then
		return
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateGiftButtonLayout)
end

bindGiftLayoutCamera(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindGiftLayoutCamera(Workspace.CurrentCamera)
	updateGiftButtonLayout()
end)

-- === 2. GŁÓWNY PANEL NAGRÓD ===
local mainPanel = Instance.new("Frame")
mainPanel.Name = "RewardsPanel"
mainPanel.Size = UDim2.fromOffset(620, 700)
mainPanel.Position = UDim2.new(0.5, 0, 0.52, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = Color3.fromRGB(24, 31, 56)
mainPanel.Visible = false
mainPanel.ZIndex = 100
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 26)
local panelStroke = Instance.new("UIStroke", mainPanel)
panelStroke.Thickness = 3
panelStroke.Color = Color3.fromRGB(221, 236, 225)
panelStroke.Transparency = 0.06

local panelGradient = Instance.new("UIGradient", mainPanel)
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 55, 93)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 28, 48)),
})
panelGradient.Rotation = 90

HudTileStyle.bindResponsivePanelScale(mainPanel, {
	baseSize = UDim2.fromOffset(620, 700),
	landscapeWidthRatio = 0.9,
	landscapeHeightRatio = 0.92,
	portraitWidthRatio = 0.94,
	portraitHeightRatio = 0.84,
	landscapeMinScale = 0.35,
	portraitMinScale = 0.48,
})

local panelPattern = Instance.new("ImageLabel", mainPanel)
panelPattern.Name = "GreenStudsPattern"
panelPattern.Size = UDim2.fromScale(1, 1)
panelPattern.BackgroundTransparency = 1
panelPattern.Image = greenStudsImage
panelPattern.ImageColor3 = Color3.fromRGB(113, 144, 214)
panelPattern.ImageTransparency = 0.76
panelPattern.ScaleType = Enum.ScaleType.Tile
panelPattern.TileSize = UDim2.fromOffset(128, 128)
panelPattern.ZIndex = 100
Instance.new("UICorner", panelPattern).CornerRadius = UDim.new(0, 26)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, -28, 0, 64)
header.Position = UDim2.new(0, 14, 0, 14)
header.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
header.BackgroundTransparency = 0.12
header.BorderSizePixel = 0
header.ZIndex = 101
header.Parent = mainPanel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local headerPattern = Instance.new("ImageLabel", header)
headerPattern.Size = UDim2.fromScale(1, 1)
headerPattern.BackgroundTransparency = 1
headerPattern.Image = greenStudsImage
headerPattern.ImageColor3 = Color3.fromRGB(94, 122, 196)
headerPattern.ImageTransparency = 0.82
headerPattern.ScaleType = Enum.ScaleType.Tile
headerPattern.TileSize = UDim2.fromOffset(112, 112)
headerPattern.ZIndex = 101
Instance.new("UICorner", headerPattern).CornerRadius = UDim.new(0, 20)

local accent = Instance.new("Frame", header)
accent.Name = "Accent"
accent.Size = UDim2.new(0, 12, 1, -18)
accent.Position = UDim2.new(0, 10, 0, 9)
accent.BackgroundColor3 = Color3.fromRGB(78, 136, 255)
accent.BorderSizePixel = 0
accent.ZIndex = 102
Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

-- Przycisk zamykania panelu
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(44, 44)
closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(196, 66, 66)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 104
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 14)
local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Thickness = 2
closeStroke.Color = Color3.fromRGB(255, 247, 244)
closeStroke.Transparency = 0.08

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 38, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PLAYTIME REWARDS"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.LuckiestGuy
title.TextSize = 38
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 103
title.Parent = header
local titleStroke = Instance.new("UIStroke", title)
titleStroke.Thickness = 2
titleStroke.Color = Color3.new(0, 0, 0)

-- Baner Społecznościowy
local socialBonusPercent = tonumber(GameConfig.InviteFriendCoinBonusPercent) or 20
local socialBtn = Instance.new("TextButton")
socialBtn.Size = UDim2.new(1, -28, 0, 88)
socialBtn.Position = UDim2.new(0, 14, 0, 92)
socialBtn.AnchorPoint = Vector2.new(0, 0)
socialBtn.BackgroundColor3 = Color3.fromRGB(22, 30, 52)
socialBtn.Text = ""
socialBtn.TextColor3 = Color3.new(1, 1, 1)
socialBtn.Font = Enum.Font.GothamBold
socialBtn.TextSize = 34
socialBtn.ZIndex = 102
socialBtn.Parent = mainPanel
Instance.new("UICorner", socialBtn).CornerRadius = UDim.new(0, 20)
local socialStroke = Instance.new("UIStroke", socialBtn)
socialStroke.Thickness = 2
socialStroke.Color = Color3.fromRGB(116, 174, 255)
socialStroke.Transparency = 0.08

local socialTitle = Instance.new("TextLabel")
socialTitle.Name = "SocialTitle"
socialTitle.Size = UDim2.new(1, -28, 1, -20)
socialTitle.Position = UDim2.new(0, 14, 0, 7)
socialTitle.BackgroundTransparency = 1
socialTitle.Text = "INVITE FRIENDS AND GET +" .. socialBonusPercent .. "% COINS"
socialTitle.TextColor3 = Color3.new(1, 1, 1)
socialTitle.Font = Enum.Font.GothamBold
socialTitle.TextSize = 24
socialTitle.TextScaled = true
socialTitle.TextWrapped = true
socialTitle.TextXAlignment = Enum.TextXAlignment.Left
socialTitle.TextYAlignment = Enum.TextYAlignment.Center
socialTitle.ZIndex = 103
socialTitle.Parent = socialBtn

local socialTitleConstraint = Instance.new("UITextSizeConstraint")
socialTitleConstraint.MinTextSize = 14
socialTitleConstraint.MaxTextSize = 24
socialTitleConstraint.Parent = socialTitle

local socialTitleStroke = Instance.new("UIStroke")
socialTitleStroke.Thickness = 1.8
socialTitleStroke.Color = Color3.new(0, 0, 0)
socialTitleStroke.Transparency = 0.18
socialTitleStroke.Parent = socialTitle

local socialActiveLabel = Instance.new("TextLabel")
socialActiveLabel.Name = "ActiveBonusLabel"
socialActiveLabel.AnchorPoint = Vector2.new(1, 1)
socialActiveLabel.Position = UDim2.new(1, -14, 1, -8)
socialActiveLabel.Size = UDim2.new(0.58, 0, 0, 18)
socialActiveLabel.BackgroundTransparency = 1
socialActiveLabel.Text = "ACTIVE +" .. socialBonusPercent .. "% COINS FRIEND BONUS"
socialActiveLabel.TextColor3 = Color3.fromRGB(104, 255, 136)
socialActiveLabel.Font = Enum.Font.GothamBold
socialActiveLabel.TextSize = 13
socialActiveLabel.TextScaled = true
socialActiveLabel.TextWrapped = false
socialActiveLabel.TextXAlignment = Enum.TextXAlignment.Right
socialActiveLabel.TextYAlignment = Enum.TextYAlignment.Bottom
socialActiveLabel.Visible = false
socialActiveLabel.ZIndex = 104
socialActiveLabel.Parent = socialBtn

local socialActiveConstraint = Instance.new("UITextSizeConstraint")
socialActiveConstraint.MinTextSize = 10
socialActiveConstraint.MaxTextSize = 13
socialActiveConstraint.Parent = socialActiveLabel

local socialActiveStroke = Instance.new("UIStroke")
socialActiveStroke.Thickness = 1.6
socialActiveStroke.Color = Color3.new(0, 0, 0)
socialActiveStroke.Transparency = 0.2
socialActiveStroke.Parent = socialActiveLabel

local socialPattern = Instance.new("ImageLabel", socialBtn)
socialPattern.Size = UDim2.new(0, 56, 1, 0)
socialPattern.BackgroundTransparency = 1
socialPattern.Image = greenStudsImage
socialPattern.ImageColor3 = Color3.fromRGB(90, 122, 198)
socialPattern.ImageTransparency = 0.8
socialPattern.ScaleType = Enum.ScaleType.Tile
socialPattern.TileSize = UDim2.fromOffset(96, 96)
socialPattern.ZIndex = 101
Instance.new("UICorner", socialPattern).CornerRadius = UDim.new(0, 20)

-- Lista nagród
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -28, 1, -198)
listFrame.Position = UDim2.new(0, 14, 0, 188)
listFrame.AnchorPoint = Vector2.new(0, 0)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 8
listFrame.ScrollBarImageColor3 = Color3.fromRGB(170, 196, 255)
listFrame.ZIndex = 101
listFrame.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = listFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 12)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function updateSocialBannerLayout()
	local metrics = HudTileStyle.getLayoutMetrics()
	local isLandscapeMobile = metrics.IsLandscapeMobile
	local isMobile = metrics.IsMobile
	local bannerHeight

	if isLandscapeMobile then
		bannerHeight = 124
		socialTitle.Text = "INVITE FRIENDS\nAND GET +" .. socialBonusPercent .. "% COINS"
		socialTitle.Size = UDim2.new(1, -24, 0, 60)
		socialTitle.Position = UDim2.new(0, 12, 0, 6)
		socialTitle.TextXAlignment = Enum.TextXAlignment.Left
		socialTitleConstraint.MinTextSize = 10
		socialTitleConstraint.MaxTextSize = 16

		socialActiveLabel.AnchorPoint = Vector2.new(0, 1)
		socialActiveLabel.Position = UDim2.new(0, 12, 1, -8)
		socialActiveLabel.Size = UDim2.new(1, -24, 0, 34)
		socialActiveLabel.Text = "ACTIVE +" .. socialBonusPercent .. "% COINS\nFRIEND BONUS"
		socialActiveLabel.TextWrapped = true
		socialActiveLabel.TextXAlignment = Enum.TextXAlignment.Left
		socialActiveConstraint.MinTextSize = 8
		socialActiveConstraint.MaxTextSize = 10

		socialPattern.Size = UDim2.new(0, 48, 1, 0)
	elseif isMobile then
		bannerHeight = 164
		socialTitle.Text = "INVITE FRIENDS\nAND GET +" .. socialBonusPercent .. "% COINS"
		socialTitle.Size = UDim2.new(1, -26, 0, 84)
		socialTitle.Position = UDim2.new(0, 12, 0, 8)
		socialTitle.TextXAlignment = Enum.TextXAlignment.Left
		socialTitleConstraint.MinTextSize = 10
		socialTitleConstraint.MaxTextSize = 15

		socialActiveLabel.AnchorPoint = Vector2.new(0, 1)
		socialActiveLabel.Position = UDim2.new(0, 12, 1, -10)
		socialActiveLabel.Size = UDim2.new(1, -24, 0, 42)
		socialActiveLabel.Text = "ACTIVE +" .. socialBonusPercent .. "% COINS\nFRIEND BONUS"
		socialActiveLabel.TextWrapped = true
		socialActiveLabel.TextXAlignment = Enum.TextXAlignment.Left
		socialActiveConstraint.MinTextSize = 8
		socialActiveConstraint.MaxTextSize = 10

		socialPattern.Size = UDim2.new(0, 44, 1, 0)
	else
		bannerHeight = 88
		socialTitle.Text = "INVITE FRIENDS AND GET +" .. socialBonusPercent .. "% COINS"
		socialTitle.Size = UDim2.new(1, -28, 1, -20)
		socialTitle.Position = UDim2.new(0, 14, 0, 7)
		socialTitle.TextXAlignment = Enum.TextXAlignment.Left
		socialTitleConstraint.MinTextSize = 14
		socialTitleConstraint.MaxTextSize = 24

		socialActiveLabel.AnchorPoint = Vector2.new(1, 1)
		socialActiveLabel.Position = UDim2.new(1, -14, 1, -8)
		socialActiveLabel.Size = UDim2.new(0.58, 0, 0, 18)
		socialActiveLabel.Text = "ACTIVE +" .. socialBonusPercent .. "% COINS FRIEND BONUS"
		socialActiveLabel.TextWrapped = false
		socialActiveLabel.TextXAlignment = Enum.TextXAlignment.Right
		socialActiveConstraint.MinTextSize = 10
		socialActiveConstraint.MaxTextSize = 13

		socialPattern.Size = UDim2.new(0, 56, 1, 0)
	end

	socialBtn.Size = UDim2.new(1, -28, 0, bannerHeight)
	local listTop = socialBtn.Position.Y.Offset + bannerHeight + 8
	listFrame.Position = UDim2.new(0, 14, 0, listTop)
	listFrame.Size = UDim2.new(1, -28, 1, -(listTop + 10))
end

updateSocialBannerLayout()

local function bindSocialLayoutCamera(camera)
	if not camera then
		return
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSocialBannerLayout)
end

bindSocialLayoutCamera(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindSocialLayoutCamera(Workspace.CurrentCamera)
	updateSocialBannerLayout()
end)

-- === 3. BUDOWANIE ELEMENTÓW LISTY ===
local playtimeMetrics = HudTileStyle.getLayoutMetrics()
local compactLandscapeRows = playtimeMetrics.IsLandscapeMobile
local mobileRows = playtimeMetrics.IsMobile

local function getPlaytimeClaimPopupMetrics()
	local metrics = HudTileStyle.getLayoutMetrics()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

	if metrics.IsLandscapeMobile then
		return {
			size = UDim2.fromOffset(math.clamp(math.floor(viewport.X * 0.22), 124, 156), math.clamp(math.floor(viewport.Y * 0.085), 30, 36)),
			textSize = 20,
			strokeThickness = 2,
			rise = 32,
		}
	elseif metrics.IsMobile then
		return {
			size = UDim2.fromOffset(math.clamp(math.floor(viewport.X * 0.28), 144, 176), math.clamp(math.floor(viewport.Y * 0.068), 34, 40)),
			textSize = 24,
			strokeThickness = 2.4,
			rise = 38,
		}
	end

	return {
		size = UDim2.fromOffset(200, 50),
		textSize = 35,
		strokeThickness = 3,
		rise = 50,
	}
end

for index, rewardData in ipairs(GameConfig.PlaytimeRewards) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, compactLandscapeRows and 92 or (mobileRows and 88 or 84))
	row.BackgroundColor3 = Color3.fromRGB(22, 28, 48)
	row.BackgroundTransparency = 0.06
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.ZIndex = 102
	row.Parent = listFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 20)
	local rowStroke = Instance.new("UIStroke", row)
	rowStroke.Thickness = 2
	rowStroke.Color = Color3.fromRGB(95, 104, 114)
	rowStroke.Transparency = 0.1

	local rowPattern = Instance.new("ImageLabel", row)
	rowPattern.Size = UDim2.new(0, 56, 1, 0)
	rowPattern.BackgroundTransparency = 1
	rowPattern.Image = greenStudsImage
	rowPattern.ImageColor3 = Color3.fromRGB(90, 122, 198)
	rowPattern.ImageTransparency = 0.8
	rowPattern.ScaleType = Enum.ScaleType.Tile
	rowPattern.TileSize = UDim2.fromOffset(96, 96)
	rowPattern.ZIndex = 102
	Instance.new("UICorner", rowPattern).CornerRadius = UDim.new(0, 20)
	
	local timeLbl = Instance.new("TextLabel")
	timeLbl.Size = UDim2.new(0, 110, 1, 0)
	timeLbl.Position = UDim2.fromOffset(20, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Text = rewardData.TimeMinutes .. " MIN"
	timeLbl.TextColor3 = Color3.fromRGB(202, 224, 205)
	timeLbl.Font = Enum.Font.GothamBold
	timeLbl.TextSize = compactLandscapeRows and 27 or (mobileRows and 24 or 22)
	timeLbl.TextXAlignment = Enum.TextXAlignment.Left
	timeLbl.ZIndex = 103
	timeLbl.Parent = row
	
	local coinLbl = Instance.new("TextLabel")
	coinLbl.Size = UDim2.new(0, 160, 1, 0)
	coinLbl.Position = UDim2.fromOffset(138, 0)
	coinLbl.BackgroundTransparency = 1
	coinLbl.Text = "💰 " .. rewardData.Reward
	coinLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinLbl.Font = Enum.Font.FredokaOne
	coinLbl.TextSize = compactLandscapeRows and 29 or (mobileRows and 26 or 24)
	coinLbl.TextXAlignment = Enum.TextXAlignment.Left
	coinLbl.ZIndex = 103
	coinLbl.Parent = row
	
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0, compactLandscapeRows and 154 or 144, 0, compactLandscapeRows and 52 or 48)
	actionBtn.Position = UDim2.new(1, -18, 0.5, 0)
	actionBtn.AnchorPoint = Vector2.new(1, 0.5)
	actionBtn.BackgroundColor3 = Color3.fromRGB(90, 96, 104)
	actionBtn.Text = "LOCKED"
	actionBtn.TextColor3 = Color3.new(1, 1, 1)
	actionBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
	actionBtn.TextStrokeTransparency = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.TextSize = compactLandscapeRows and 23 or (mobileRows and 21 or 19)
	actionBtn.AutoButtonColor = false
	actionBtn.ZIndex = 105
	actionBtn.Parent = row
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 16)
	local actionStroke = Instance.new("UIStroke", actionBtn)
	actionStroke.Thickness = 2
	actionStroke.Color = Color3.new(0, 0, 0)
	actionStroke.Transparency = 0.12
	
	table.insert(rewardRows, {
		Frame = row,
		Button = actionBtn,
		CoinLabel = coinLbl,
		Data = rewardData,
		Index = index
	})
	
	-- Obsługa kliknięcia (Odbiór Nagrody)
	actionBtn.MouseButton1Click:Connect(function()
		if actionBtn.Text == "CLAIM" then
			actionBtn.Text = "..."
			local success, result, shouldRestart, nextCycleStartTime = claimEvent:InvokeServer(index)
			if success then
				playClaimRewardSound()
				
				if shouldRestart then
					-- Jeżeli odebrano wszystkie nagrody, serwer restartuje cały cykl od nowa.
					resetPlaytimeCycleClient(nextCycleStartTime)
				else
					claimedRewards[tostring(index)] = true -- Czasem stringuje się przy jsonie
					claimedRewards[index] = true
					actionBtn.BackgroundColor3 = Color3.fromRGB(62, 70, 79)
					actionBtn.Text = "CLAIMED"
				end
				
				-- Pokazanie popupu
				local pop = Instance.new("TextLabel")
				local popupMetrics = getPlaytimeClaimPopupMetrics()
				pop.Size = popupMetrics.size
				pop.AnchorPoint = Vector2.new(0.5, 1)
				pop.Position = UDim2.fromOffset(actionBtn.AbsolutePosition.X + (actionBtn.AbsoluteSize.X * 0.5), actionBtn.AbsolutePosition.Y - 4)
				pop.BackgroundTransparency = 1
				pop.ZIndex = 200
				pop.Font = Enum.Font.LuckiestGuy
				pop.TextSize = popupMetrics.textSize
				pop.TextColor3 = Color3.new(0, 1, 0)
				pop.Text = "+ " .. result .. " COINS"
				pop.Parent = screenGui
				
				local popStroke = Instance.new("UIStroke", pop)
				popStroke.Thickness = popupMetrics.strokeThickness
				
				-- Ruch do góry
				local tw = TweenService:Create(pop, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = pop.Position - UDim2.fromOffset(0, popupMetrics.rise), TextTransparency = 1})
				local strokeTw = TweenService:Create(popStroke, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.2), {Transparency = 1})
				tw:Play()
				strokeTw:Play()
				task.delay(1.5, function() pop:Destroy() end)
			else
				actionBtn.Text = "CLAIM"
				warn("Failed to claim:", result)
			end
		end
	end)
end

listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

-- === 4. LOGIKA I PĘTLA ODŚWIEŻANIA ===
local function formatTime(seconds)
	if seconds <= 0 then return "00:00" end
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

-- AKTUALIZACJA WARTOŚCI MONET W UI (Mnożnik VIP/Rebirth + FriendBonus)
local isFriendBonusActive = false

local function updateRewardValues()
	local multi = player:GetAttribute("CoinEarningsMultiplier") or player:GetAttribute("CoinMultiplier") or 1
	
	for _, r in ipairs(rewardRows) do
		local fRew = math.floor(r.Data.Reward * multi)
		r.CoinLabel.Text = "💰 " .. fRew
	end
end

player:GetAttributeChangedSignal("CoinMultiplier"):Connect(updateRewardValues)
player:GetAttributeChangedSignal("CoinEarningsMultiplier"):Connect(updateRewardValues)
updateRewardValues() -- Inicjalne ustawienie

-- Aktualizacja baneru zapraszania znajomych
local function updateSocialBanner()
	isFriendBonusActive = player:GetAttribute("InviteFriendBonusActive") == true
	local activeBonusCount = tonumber(player:GetAttribute("InviteFriendBonusCount")) or 0
	socialActiveLabel.Visible = isFriendBonusActive and activeBonusCount > 0
	if socialActiveLabel.Visible then
		socialBtn.BackgroundColor3 = Color3.fromRGB(20, 46, 36)
		socialStroke.Color = Color3.fromRGB(104, 255, 136)
	else
		socialBtn.BackgroundColor3 = Color3.fromRGB(22, 30, 52)
		socialStroke.Color = Color3.fromRGB(72, 160, 224)
	end
end

-- Sprawdzanie znajomych co 10 sekund (nie w pętli render, żeby nie zabić rate-limitu!)
player:GetAttributeChangedSignal("InviteFriendBonusActive"):Connect(updateSocialBanner)
player:GetAttributeChangedSignal("InviteFriendBonusCount"):Connect(updateSocialBanner)
updateSocialBanner()

socialBtn.MouseButton1Click:Connect(function()
	local success, err = pcall(function()
		SocialService:PromptGameInvite(player)
	end)
	if not success then
		warn("SocialService error:", err)
	end
end)

local panelOpen = false

local function updatePanelVisibility(open)
	panelOpen = open
	backdrop.Visible = open
	mainPanel.Visible = open

	if open then
		backdrop.BackgroundTransparency = 1
		mainPanel.Position = UDim2.new(0.5, 0, 0.54, 0)
		mainPanel.Size = UDim2.fromOffset(560, 650)
		TweenService:Create(backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.38,
		}):Play()
		TweenService:Create(mainPanel, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(620, 700),
		}):Play()
	else
		local panelTween = TweenService:Create(mainPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.54, 0),
			Size = UDim2.fromOffset(560, 650),
		})
		panelTween:Play()
		TweenService:Create(backdrop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		panelTween.Completed:Connect(function()
			if not panelOpen then
				backdrop.Visible = false
				mainPanel.Visible = false
			end
		end)
	end
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["PlaytimeRewards"] = function()
	if panelOpen then
		updatePanelVisibility(false)
		TweenService:Create(giftBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end

giftBtn.MouseButton1Click:Connect(function()
	local targetVisible = not panelOpen
	if targetVisible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "PlaytimeRewards" then closeFunc() end
		end
	end
	
	updatePanelVisibility(targetVisible)
	if targetVisible then
		TweenService:Create(giftBtn, TweenInfo.new(0.2), {Rotation = 15}):Play()
	else
		TweenService:Create(giftBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	updatePanelVisibility(false)
	TweenService:Create(giftBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
end)

-- Pętla RenderStepped do odświeżania odliczania i pulsującej ikonki powiadomień
RunService.RenderStepped:Connect(function(dt)
	local elapsed = os.time() - sessionStartTime
	local anyReadyToClaim = false
	local lowestTimeLeft = math.huge
	local nextRewardAmount = 0
	
	for _, rowObj in ipairs(rewardRows) do
		local reqSecs = rowObj.Data.TimeMinutes * 60
		local btn = rowObj.Button
		
		-- Jeśli już odebrane (indeks może być przekazany przez serwer w różnej formie)
		if claimedRewards[rowObj.Index] or claimedRewards[tostring(rowObj.Index)] then
			if btn.Text ~= "CLAIMED" then
				btn.BackgroundColor3 = Color3.fromRGB(62, 70, 79)
				btn.Text = "CLAIMED"
			end
		else
			-- Jeśli jeszcze nieodebrane
			if elapsed >= reqSecs then
				anyReadyToClaim = true
				if btn.Text ~= "CLAIM" and btn.Text ~= "..." then
					btn.BackgroundColor3 = Color3.fromRGB(56, 182, 92)
					btn.Text = "CLAIM"
				end
			else
				local left = reqSecs - elapsed
				btn.Text = formatTime(left)
				if left < lowestTimeLeft then
					lowestTimeLeft = left
					
					local multi = player:GetAttribute("CoinEarningsMultiplier") or player:GetAttribute("CoinMultiplier") or 1
					nextRewardAmount = math.floor(rowObj.Data.Reward * multi)
				end
			end
		end
	end
	
	-- Efekt pulsowania wykrzyknika i ikonki
	if anyReadyToClaim then
		giftNotif.Visible = true
		local scale = 1 + math.sin(tick() * 8) * 0.2
		giftNotif.Size = UDim2.fromOffset(35 * scale, 35 * scale)
		if not mainPanel.Visible then
			giftBtn.Rotation = math.sin(tick() * 4) * 3
		end
		
		giftTimerLbl.Text = "CLAIM!"
		giftTimerLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
		giftAmountLbl.Text = ""
	else
		giftNotif.Visible = false
		if not mainPanel.Visible then
			giftBtn.Rotation = 0
		end
		
		if lowestTimeLeft ~= math.huge then
			giftTimerLbl.Text = formatTime(lowestTimeLeft)
			giftAmountLbl.Text = "+" .. nextRewardAmount
			giftTimerLbl.TextColor3 = Color3.new(1, 1, 1)
		else
			giftTimerLbl.Text = "MAXED"
			giftAmountLbl.Text = ""
			giftTimerLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
		end
	end
end)

-- Na start sprawdzamy baner
updateSocialBanner()

print("PlaytimeRewardsGui Loaded")
