local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))
local greenStudsImage = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")

local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local ClaimDailyRewardRF = BrainrotEvents:WaitForChild("ClaimDailyReward")
local OpenDailyRewardsPanelEvent = BrainrotEvents:WaitForChild("OpenDailyRewardsPanel")

local oldGui = PlayerGui:FindFirstChild("DailyRewardsUI")
if oldGui then
	oldGui:Destroy()
end

local oldToggle = PlayerGui:FindFirstChild("DailyRewardsToggleUI")
if oldToggle then
	oldToggle:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DailyRewardsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "DailyRewardsToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = PlayerGui

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleDailyMenu"
ToggleBtn.Position = HudTileStyle.getSlot("right", 3)
ToggleBtn.ZIndex = 50
ToggleBtn.Parent = ToggleGui

local dailyIcon = Instance.new("ImageLabel")
dailyIcon.Name = "DailyIcon"
dailyIcon.Image = "rbxassetid://15222045142"
local rsCalIcon = ReplicatedStorage:FindFirstChild("Kalendarz")
if rsCalIcon then
	if rsCalIcon:IsA("Decal") then
		dailyIcon.Image = rsCalIcon.Texture
	elseif rsCalIcon:IsA("ImageLabel") or rsCalIcon:IsA("ImageButton") then
		dailyIcon.Image = rsCalIcon.Image
	end
end
dailyIcon.Parent = ToggleBtn

local btnLabel = Instance.new("TextLabel")
btnLabel.Text = "DAILY"
btnLabel.Parent = ToggleBtn

HudTileStyle.apply(ToggleBtn, dailyIcon, btnLabel, {
	side = "right",
	slotIndex = 3,
	zIndex = 50,
})

local DarkBg = Instance.new("Frame")
DarkBg.Name = "Backdrop"
DarkBg.Size = UDim2.fromScale(1, 1)
DarkBg.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
DarkBg.BackgroundTransparency = 1
DarkBg.Visible = false
DarkBg.ZIndex = 0
DarkBg.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 900, 0, 675)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 31, 56)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)

HudTileStyle.bindResponsivePanelScale(MainFrame, {
	baseSize = UDim2.fromOffset(900, 675),
	landscapeWidthRatio = 0.96,
	landscapeHeightRatio = 0.92,
	portraitWidthRatio = 0.94,
	portraitHeightRatio = 0.84,
	mobileMinScale = 0.48,
})

local panelStroke = Instance.new("UIStroke", MainFrame)
panelStroke.Thickness = 3
panelStroke.Color = Color3.new(0, 0, 0)
panelStroke.Transparency = 0.06

local panelGradient = Instance.new("UIGradient", MainFrame)
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 55, 93)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 28, 48)),
})
panelGradient.Rotation = 90

local MainBg = Instance.new("ImageLabel")
MainBg.Name = "GreenStudsPattern"
MainBg.Size = UDim2.fromScale(1, 1)
MainBg.BackgroundTransparency = 1
MainBg.Image = greenStudsImage
MainBg.ImageColor3 = Color3.fromRGB(113, 144, 214)
MainBg.ImageTransparency = 0.76
MainBg.ScaleType = Enum.ScaleType.Tile
MainBg.TileSize = UDim2.fromOffset(128, 128)
MainBg.ZIndex = 1
MainBg.Parent = MainFrame
Instance.new("UICorner", MainBg).CornerRadius = UDim.new(0, 20)

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Name = "Header"
HeaderFrame.Size = UDim2.new(1, -32, 0, 72)
HeaderFrame.Position = UDim2.new(0, 16, 0, 16)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
HeaderFrame.BackgroundTransparency = 0.12
HeaderFrame.BorderSizePixel = 0
HeaderFrame.ZIndex = 2
HeaderFrame.Parent = MainFrame
Instance.new("UICorner", HeaderFrame).CornerRadius = UDim.new(0, 20)

local HeaderPattern = Instance.new("ImageLabel")
HeaderPattern.Size = UDim2.fromScale(1, 1)
HeaderPattern.BackgroundTransparency = 1
HeaderPattern.Image = greenStudsImage
HeaderPattern.ImageColor3 = Color3.fromRGB(94, 122, 196)
HeaderPattern.ImageTransparency = 0.82
HeaderPattern.ScaleType = Enum.ScaleType.Tile
HeaderPattern.TileSize = UDim2.fromOffset(112, 112)
HeaderPattern.ZIndex = 2
HeaderPattern.Parent = HeaderFrame
Instance.new("UICorner", HeaderPattern).CornerRadius = UDim.new(0, 20)

local HeaderAccent = Instance.new("Frame")
HeaderAccent.Name = "Accent"
HeaderAccent.Size = UDim2.new(0, 12, 1, -18)
HeaderAccent.Position = UDim2.new(0, 10, 0, 9)
HeaderAccent.BackgroundColor3 = Color3.fromRGB(78, 136, 255)
HeaderAccent.BorderSizePixel = 0
HeaderAccent.ZIndex = 3
HeaderAccent.Parent = HeaderFrame
Instance.new("UICorner", HeaderAccent).CornerRadius = UDim.new(1, 0)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(44, 44)
CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(196, 66, 66)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 22
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 4
CloseBtn.Parent = HeaderFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 14)

local closeStroke = Instance.new("UIStroke", CloseBtn)
closeStroke.Thickness = 2
closeStroke.Color = Color3.new(0, 0, 0)
closeStroke.Transparency = 0.08

local TitleFrame = Instance.new("TextLabel")
TitleFrame.Size = UDim2.new(1, -120, 1, 0)
TitleFrame.Position = UDim2.new(0, 40, 0, 0)
TitleFrame.BackgroundTransparency = 1
TitleFrame.Font = Enum.Font.LuckiestGuy
TitleFrame.Text = "7-DAY LOGIN REWARDS"
TitleFrame.TextColor3 = Color3.new(1, 1, 1)
TitleFrame.TextSize = 44
TitleFrame.TextXAlignment = Enum.TextXAlignment.Left
TitleFrame.ZIndex = 4
TitleFrame.Parent = HeaderFrame

local titleStroke = Instance.new("UIStroke", TitleFrame)
titleStroke.Thickness = 2
titleStroke.Color = Color3.new(0, 0, 0)

local GridContainer = Instance.new("Frame")
GridContainer.Size = UDim2.new(1, -60, 0, 420)
GridContainer.Position = UDim2.new(0, 30, 0, 116)
GridContainer.BackgroundTransparency = 1
GridContainer.ZIndex = 2
GridContainer.Parent = MainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 180, 0, 190)
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.Parent = GridContainer

local ClaimBtn = Instance.new("TextButton")
ClaimBtn.Size = UDim2.new(0.6, 0, 0, 85)
ClaimBtn.Position = UDim2.new(0.2, 0, 1, -110)
ClaimBtn.BackgroundColor3 = Color3.fromRGB(70, 112, 208)
ClaimBtn.BorderSizePixel = 0
ClaimBtn.Font = Enum.Font.LuckiestGuy
ClaimBtn.Text = "CLAIM REWARD!"
ClaimBtn.TextColor3 = Color3.new(1, 1, 1)
ClaimBtn.TextSize = 40
ClaimBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
ClaimBtn.TextStrokeTransparency = 0
ClaimBtn.AutoButtonColor = false
ClaimBtn.ZIndex = 3
ClaimBtn.Parent = MainFrame
Instance.new("UICorner", ClaimBtn).CornerRadius = UDim.new(0, 18)

local claimBtnStroke = Instance.new("UIStroke", ClaimBtn)
claimBtnStroke.Thickness = 2
claimBtnStroke.Color = Color3.new(0, 0, 0)
claimBtnStroke.Transparency = 0.08

local function getRewardDescription(reward)
	if reward.Type == "Coin" then
		local multiplier = LocalPlayer:GetAttribute("CoinMultiplier") or 1
		return tostring(math.floor(reward.Value * multiplier)) .. " Coins"
	elseif reward.Type == "Speed" then
		return "Speed x2 (30m)"
	elseif reward.Type == "Jump" then
		return "Jump x2 (30m)"
	elseif reward.Type == "PurpleTrail" then
		return "Purple Trail"
	end

	return "Mystery Reward"
end

local pulseTween = TweenService:Create(
	ClaimBtn,
	TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{Size = UDim2.new(0.65, 0, 0, 90), Position = UDim2.new(0.175, 0, 1, -112.5)}
)
pulseTween:Play()

local function updateUI()
	for _, child in ipairs(GridContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local streak = LocalPlayer:GetAttribute("LoginStreak") or 1
	local lastClaim = LocalPlayer:GetAttribute("LastClaimedDate") or ""
	local todayStr = os.date("%Y%m%d")
	local claimedToday = lastClaim == todayStr

	local displayStreak = streak
	if claimedToday and streak == 1 then
		displayStreak = 8
	end

	for i = 1, 7 do
		local reward = GameConfig.DailyRewards[i]
		if not reward then
			continue
		end

		local tile = Instance.new("Frame")
		tile.BackgroundColor3 = Color3.fromRGB(22, 28, 48)
		tile.BackgroundTransparency = 0.04
		tile.BorderSizePixel = 0
		tile.Parent = GridContainer
		Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 8)

		local tileGradient = Instance.new("UIGradient", tile)
		tileGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 47, 78)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 26, 44)),
		})
		tileGradient.Rotation = 90

		local tileStroke = Instance.new("UIStroke", tile)
		tileStroke.Thickness = 2
		tileStroke.Color = Color3.new(0, 0, 0)
		tileStroke.Transparency = 0.08

		local TileBg = Instance.new("ImageLabel")
		TileBg.Name = "TileBg"
		TileBg.Size = UDim2.fromScale(1, 1)
		TileBg.BackgroundTransparency = 1
		TileBg.Image = greenStudsImage
		TileBg.ImageColor3 = Color3.fromRGB(90, 122, 198)
		TileBg.ImageTransparency = 0.82
		TileBg.ScaleType = Enum.ScaleType.Tile
		TileBg.TileSize = UDim2.fromOffset(72, 72)
		TileBg.ZIndex = 1
		TileBg.Parent = tile
		Instance.new("UICorner", TileBg).CornerRadius = UDim.new(0, 8)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 50)
		title.BackgroundTransparency = 1
		title.Text = "DAY " .. i
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 30
		title.ZIndex = 2
		title.Parent = tile

		local dayStroke = Instance.new("UIStroke", title)
		dayStroke.Thickness = 2
		dayStroke.Color = Color3.new(0, 0, 0)

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 45)
		desc.Position = UDim2.new(0, 0, 1, -55)
		desc.BackgroundTransparency = 1
		desc.Text = getRewardDescription(reward)
		desc.TextColor3 = Color3.fromRGB(220, 232, 255)
		desc.Font = Enum.Font.GothamBold
		desc.TextSize = 22
		desc.ZIndex = 2
		desc.Parent = tile

		local descStroke = Instance.new("UIStroke", desc)
		descStroke.Thickness = 1.5
		descStroke.Color = Color3.new(0, 0, 0)

		local iconFrame = Instance.new("ImageLabel")
		iconFrame.Size = UDim2.new(0, 65, 0, 65)
		iconFrame.Position = UDim2.new(0.5, -32.5, 0.5, -12)
		iconFrame.BackgroundTransparency = 1
		iconFrame.ZIndex = 3
		iconFrame.Parent = tile

		local rsIcon = ReplicatedStorage:FindFirstChild(reward.Icon)
		if rsIcon and rsIcon:IsA("Decal") then
			iconFrame.Image = rsIcon.Texture
		elseif rsIcon and (rsIcon:IsA("ImageLabel") or rsIcon:IsA("ImageButton")) then
			iconFrame.Image = rsIcon.Image
		else
			iconFrame.Image = "rbxassetid://13193264908"
		end

		if reward.Type == "PurpleTrail" then
			iconFrame.ImageColor3 = Color3.fromRGB(128, 48, 205)
			iconFrame.ImageTransparency = 0
			iconFrame.Size = UDim2.new(0, 72, 0, 72)
			iconFrame.Position = UDim2.new(0.5, -36, 0.5, -16)

			local auraGlow = Instance.new("ImageLabel")
			auraGlow.Name = "AuraGlow"
			auraGlow.Size = UDim2.fromOffset(96, 96)
			auraGlow.Position = UDim2.new(0.5, 0, 0.5, -12)
			auraGlow.AnchorPoint = Vector2.new(0.5, 0.5)
			auraGlow.BackgroundTransparency = 1
			auraGlow.Image = iconFrame.Image
			auraGlow.ImageColor3 = Color3.fromRGB(98, 28, 176)
			auraGlow.ImageTransparency = 0.28
			auraGlow.ZIndex = 2
			auraGlow.Parent = tile
		end

		local isClaimed = i < displayStreak
		local isToday = i == displayStreak and not claimedToday

		if isClaimed then
			tile.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
			TileBg.ImageColor3 = Color3.fromRGB(104, 116, 150)
			TileBg.ImageTransparency = 0.86
			iconFrame.ImageTransparency = 0.5

			local checkMark = Instance.new("ImageLabel")
			checkMark.Size = UDim2.fromScale(0.6, 0.6)
			checkMark.Position = UDim2.fromScale(0.2, 0.2)
			checkMark.BackgroundTransparency = 1
			checkMark.Image = "rbxassetid://13508110820"
			checkMark.ImageColor3 = Color3.new(0, 1, 0)
			checkMark.ZIndex = 3
			checkMark.Parent = iconFrame

			local claimedLabel = Instance.new("TextLabel")
			claimedLabel.Size = UDim2.new(1, 0, 0, 30)
			claimedLabel.Position = UDim2.new(0, 0, 0.5, -15)
			claimedLabel.BackgroundTransparency = 1
			claimedLabel.Text = "CLAIMED"
			claimedLabel.TextColor3 = Color3.fromRGB(220, 232, 255)
			claimedLabel.Font = Enum.Font.LuckiestGuy
			claimedLabel.TextSize = 25
			claimedLabel.ZIndex = 4
			claimedLabel.Rotation = -15
			claimedLabel.Parent = tile

			local claimedStroke = Instance.new("UIStroke", claimedLabel)
			claimedStroke.Thickness = 2
			claimedStroke.Color = Color3.new(0, 0, 0)
		elseif isToday then
			tile.BackgroundColor3 = Color3.fromRGB(28, 55, 72)
			TileBg.ImageColor3 = Color3.fromRGB(88, 188, 255)
			TileBg.ImageTransparency = 0.74
			tileStroke.Thickness = 3
			tileStroke.Color = Color3.fromRGB(103, 226, 255)
		end

		if reward.Type == "Speed" or reward.Type == "Jump" then
			iconFrame.Size = UDim2.new(0, 85, 0, 85)
			iconFrame.Position = UDim2.new(0.5, -42.5, 0.5, -50)

			local glow = Instance.new("Frame")
			glow.Name = "IconGlow"
			glow.Size = UDim2.new(0, 85, 0, 85)
			glow.Position = iconFrame.Position
			glow.BackgroundColor3 = Color3.fromRGB(109, 154, 255)
			glow.ZIndex = 2
			glow.Parent = tile
			Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)

			iconFrame.ImageColor3 = Color3.new(0, 0, 0)
			iconFrame.ImageTransparency = isClaimed and 0.5 or 0
			if isClaimed then
				glow.BackgroundTransparency = 0.5
			end
		end
	end

	if claimedToday then
		ClaimBtn.Text = "COME BACK TOMORROW!"
		ClaimBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		ClaimBtn.Active = false
		pulseTween:Pause()
		ClaimBtn.Size = UDim2.new(0.6, 0, 0, 85)
		ClaimBtn.Position = UDim2.new(0.2, 0, 1, -110)
	else
		ClaimBtn.Text = "CLAIM REWARD!"
		ClaimBtn.BackgroundColor3 = Color3.fromRGB(70, 112, 208)
		ClaimBtn.Active = true
		pulseTween:Play()
	end
end

local function closePanel()
	if not MainFrame.Visible then
		return
	end

	local panelTween = TweenService:Create(
		MainFrame,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 0.54, 0)}
	)
	panelTween:Play()
	TweenService:Create(
		DarkBg,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	):Play()

	panelTween.Completed:Connect(function()
		if not MainFrame.Visible then
			DarkBg.Visible = false
		end
	end)

	MainFrame.Visible = false
	TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
end

local function openPanel()
	DarkBg.Visible = true
	DarkBg.BackgroundTransparency = 1
	MainFrame.Visible = true
	updateUI()
	MainFrame.Position = UDim2.new(0.5, 0, 0.54, 0)

	TweenService:Create(
		DarkBg,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.38}
	):Play()
	TweenService:Create(
		MainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	):Play()
	TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 15}):Play()
end

local function showDailyRewardsPanel()
	for name, closeFunc in pairs(_G.UiMenus) do
		if name ~= "DailyRewards" then
			closeFunc()
		end
	end
	openPanel()
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["DailyRewards"] = function()
	closePanel()
end

ToggleBtn.MouseButton1Click:Connect(function()
	local targetVisible = not MainFrame.Visible
	if targetVisible then
		showDailyRewardsPanel()
	else
		closePanel()
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	closePanel()
end)

local isClaiming = false
ClaimBtn.MouseButton1Click:Connect(function()
	if isClaiming or not ClaimBtn.Active then
		return
	end

	isClaiming = true
	local success = ClaimDailyRewardRF:InvokeServer()
	if success then
		local soundTemplate = ReplicatedStorage:WaitForChild("Claimed")
		if soundTemplate then
			local sound = soundTemplate:Clone()
			sound.Volume = 2
			sound.Parent = workspace
			sound:Play()
			Debris:AddItem(sound, 3)
		end

		updateUI()
	end
	isClaiming = false
end)

LocalPlayer:GetAttributeChangedSignal("LoginStreak"):Connect(function()
	if MainFrame.Visible then
		updateUI()
	end
end)

LocalPlayer:GetAttributeChangedSignal("CoinMultiplier"):Connect(function()
	if MainFrame.Visible then
		updateUI()
	end
end)

OpenDailyRewardsPanelEvent.OnClientEvent:Connect(function()
	local todayStr = os.date("%Y%m%d")
	if (LocalPlayer:GetAttribute("LastClaimedDate") or "") == todayStr then
		return
	end

	if MainFrame.Visible then
		return
	end

	showDailyRewardsPanel()
end)
