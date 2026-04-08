local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HudTileStyle = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("HudTileStyle"))

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local ClaimDailyRewardRF = BrainrotEvents:WaitForChild("ClaimDailyReward")

-- Inicjalizacja GĹ‚Ăłwnego Ekranu
local oldGui = PlayerGui:FindFirstChild("DailyRewardsUI")
if oldGui then oldGui:Destroy() end

local oldToggle = PlayerGui:FindFirstChild("DailyRewardsToggleUI")
if oldToggle then oldToggle:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DailyRewardsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Przycisk Kalendarza na ekranie (Prawy dolny sektor)
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
if rsCalIcon then dailyIcon.Image = rsCalIcon:IsA("Decal") and rsCalIcon.Texture or rsCalIcon.Image end
dailyIcon.Parent = ToggleBtn

local btnLabel = Instance.new("TextLabel")
btnLabel.Text = "DAILY"
btnLabel.Parent = ToggleBtn

HudTileStyle.apply(ToggleBtn, dailyIcon, btnLabel, {
	side = "right",
	slotIndex = 3,
	zIndex = 50,
})

-- Ciemne tĹ‚o caĹ‚ego ekranu (Blur logic)
local DarkBg = Instance.new("Frame")
DarkBg.Size = UDim2.new(1,0,1,0)
DarkBg.BackgroundColor3 = Color3.new(0,0,0)
DarkBg.BackgroundTransparency = 0.5
DarkBg.Visible = false
DarkBg.Parent = ScreenGui

-- Panel GĹ‚Ăłwny Kalendarza
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 900, 0, 675)
MainFrame.Position = UDim2.new(0.5, -450, 0.5, -337)
MainFrame.BackgroundTransparency = 1 -- Przezroczyste tĹ‚o, bo uĹĽywamy ImageLabel pod spodem
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)

-- TĹ‚o GreenStuds dla MainFrame
local MainBg = Instance.new("ImageLabel")
MainBg.Name = "MainBg"
MainBg.Size = UDim2.fromScale(1, 1)
MainBg.BackgroundTransparency = 1
MainBg.ZIndex = 0
local gs = ReplicatedStorage:FindFirstChild("GreenStuds")
if gs then MainBg.Image = gs:IsA("Decal") and gs.Texture or gs.Image end
MainBg.ImageColor3 = Color3.fromRGB(130, 220, 130) -- Jasnozielony
MainBg.ScaleType = Enum.ScaleType.Tile
MainBg.TileSize = UDim2.fromOffset(128, 128)
MainBg.Parent = MainFrame
Instance.new("UICorner", MainBg).CornerRadius = UDim.new(0, 20)

-- Przycisk x
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = 24
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local TitleFrame = Instance.new("TextLabel")
TitleFrame.Size = UDim2.new(1, 0, 0, 50)
TitleFrame.Position = UDim2.new(0, 0, 0, 15)
TitleFrame.BackgroundTransparency = 1
TitleFrame.Font = Enum.Font.LuckiestGuy
TitleFrame.Text = "7-DAY LOGIN REWARDS"
TitleFrame.TextColor3 = Color3.fromRGB(255, 200, 50)
TitleFrame.TextSize = 65
TitleFrame.Parent = MainFrame

-- Siatka na Dni
local GridContainer = Instance.new("Frame")
GridContainer.Size = UDim2.new(1, -60, 0, 420)
GridContainer.Position = UDim2.new(0, 30, 0, 110)
GridContainer.BackgroundTransparency = 1
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
ClaimBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
ClaimBtn.Font = Enum.Font.LuckiestGuy
ClaimBtn.Text = "CLAIM REWARD!"
ClaimBtn.TextColor3 = Color3.new(1,1,1)
ClaimBtn.TextSize = 40
ClaimBtn.Parent = MainFrame
Instance.new("UICorner", ClaimBtn).CornerRadius = UDim.new(0, 12)

local function getRewardDescription(reward)
	if reward.Type == "Coin" then
		return tostring(reward.Value) .. " Coins"
	elseif reward.Type == "Speed" then
		return "Speed x2 (30m)"
	elseif reward.Type == "Jump" then
		return "Jump x2 (30m)"
	elseif reward.Type == "PurpleTrail" then
		return "Purple Aura"
	end

	return "Mystery Reward"
end

-- TÄ™tniÄ…ca animacja
local pulseTween = TweenService:Create(ClaimBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.new(0.65, 0, 0, 90), Position = UDim2.new(0.175, 0, 1, -112.5)})
pulseTween:Play()

local function updateUI()
	for _, child in ipairs(GridContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local streak = LocalPlayer:GetAttribute("LoginStreak") or 1
	local lastClaim = LocalPlayer:GetAttribute("LastClaimedDate") or ""
	local todayStr = os.date("%Y%m%d")
	
	local claimedToday = (lastClaim == todayStr)
	
	-- Poprawka: jeĹ›li odebrano dzieĹ„ 7 dzisiaj, streak = 1, ale chcemy by na ekranie zaznaczyĹ‚o ĹĽe odebrano!
	local displayStreak = streak
	if claimedToday and streak == 1 then
		displayStreak = 8
	end
	
	for i = 1, 7 do
		local reward = GameConfig.DailyRewards[i]
		
		local tile = Instance.new("Frame")
		tile.BackgroundTransparency = 1 -- Przezroczyste tĹ‚o dla kafelka
		tile.Parent = GridContainer
		Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 8)
		
		-- TĹ‚o GreenStuds dla kafelka
		local TileBg = Instance.new("ImageLabel")
		TileBg.Name = "TileBg"
		TileBg.Size = UDim2.fromScale(1, 1)
		TileBg.BackgroundTransparency = 0
		TileBg.BackgroundColor3 = Color3.fromRGB(40, 70, 40) -- Fallback
		TileBg.ZIndex = 0
		if gs then TileBg.Image = gs:IsA("Decal") and gs.Texture or gs.Image end
		TileBg.ImageColor3 = Color3.fromRGB(60, 100, 60) -- Ciemniejsza zieleĹ„
		TileBg.ScaleType = Enum.ScaleType.Tile
		TileBg.TileSize = UDim2.fromOffset(64, 64)
		TileBg.Parent = tile
		Instance.new("UICorner", TileBg).CornerRadius = UDim.new(0, 8)
		
		-- TytuĹ‚ (Day 1)
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 50)
		title.BackgroundTransparency = 1
		title.Text = "DAY " .. i
		title.TextColor3 = Color3.new(1,1,1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 30
		title.ZIndex = 2
		title.Parent = tile
		
		-- Nagroda
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 45)
		desc.Position = UDim2.new(0, 0, 1, -55)
		desc.BackgroundTransparency = 1
		local strDesc = getRewardDescription(reward)
		desc.Text = strDesc
		desc.TextColor3 = Color3.fromRGB(200, 200, 200)
		desc.Font = Enum.Font.GothamBold
		desc.TextSize = 22
		desc.ZIndex = 2
		desc.Parent = tile
		
		-- Ikona Ĺ›rodkowa
		local iconFrame = Instance.new("ImageLabel")
		iconFrame.Size = UDim2.new(0, 65, 0, 65)
		iconFrame.Position = UDim2.new(0.5, -32.5, 0.5, -12)
		iconFrame.BackgroundTransparency = 1
		iconFrame.ZIndex = 3 -- WyĹĽej niĹĽ tĹ‚o ikony
		iconFrame.Parent = tile
		
		local rsIcon = ReplicatedStorage:FindFirstChild(reward.Icon)
		if rsIcon and rsIcon:IsA("Decal") then
			iconFrame.Image = rsIcon.Texture
		elseif rsIcon and rsIcon:IsA("ImageLabel") then
			iconFrame.Image = rsIcon.Image
		elseif reward.Type == "PurpleTrail" then
			iconFrame.Image = "rbxassetid://13193264908"
		else
			iconFrame.Image = "rbxassetid://13193264908" -- fallback
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
			auraGlow.Image = "rbxassetid://12030614838"
			auraGlow.ImageColor3 = Color3.fromRGB(98, 28, 176)
			auraGlow.ImageTransparency = 0.28
			auraGlow.ZIndex = 2
			auraGlow.Parent = tile
		end
		
		-- LOGIKA STANĂ“W
		local isClaimed = (i < displayStreak)
		local isToday = (i == displayStreak and not claimedToday)
		local isLocked = (i > displayStreak)
		
		if isClaimed then
			TileBg.ImageColor3 = Color3.fromRGB(100, 110, 100) -- Bardziej szary/zgaszony zielony
			TileBg.BackgroundTransparency = 0.3
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
			claimedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			claimedLabel.Font = Enum.Font.LuckiestGuy
			claimedLabel.TextSize = 25
			claimedLabel.ZIndex = 4
			claimedLabel.Rotation = -15
			claimedLabel.Parent = tile
		elseif isToday then
			TileBg.ImageColor3 = Color3.fromRGB(100, 255, 100) -- Bardzo kolorowy/jasny zielony
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 4
			stroke.Color = Color3.fromRGB(255, 215, 0)
			stroke.Parent = tile
		else
			-- PrzyszĹ‚e dni (zamiast Locked)
			TileBg.ImageColor3 = Color3.fromRGB(60, 100, 60) -- Standardowy zielony
		end

		-- WYMUSZENIE KOLORU I WIDOCZNOĹšCI DLA SPEED/JUMP
		if reward.Type == "Speed" or reward.Type == "Jump" then
			-- Przesuwamy wyĹĽej ĹĽeby nie zasĹ‚aniaĹ‚ opisu
			iconFrame.Size = UDim2.new(0, 85, 0, 85)
			iconFrame.Position = UDim2.new(0.5, -42.5, 0.5, -50)
			
			-- Skoro ikony sÄ… czarne, dodajemy pod nie jaskrawÄ… czerwonÄ… tarczÄ™ (koĹ‚o)
			local glow = Instance.new("Frame")
			glow.Name = "IconGlow"
			glow.Size = UDim2.new(0, 85, 0, 85)
			glow.Position = iconFrame.Position
			glow.BackgroundColor3 = Color3.fromRGB(220, 0, 0) -- JASKRAWA CZERWIEĹ
			glow.ZIndex = 2
			glow.Parent = tile
			Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0) -- Robimy idealne koĹ‚o
			
			-- SylwetkÄ™ ludzika wymuszamy na czarno ĹĽeby biĹ‚a po oczach na czerwonym tle
			iconFrame.ImageColor3 = Color3.new(0, 0, 0)
			iconFrame.ImageTransparency = isClaimed and 0.5 or 0
			if isClaimed then glow.BackgroundTransparency = 0.5 end
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
		ClaimBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		ClaimBtn.Active = true
		pulseTween:Play()
	end
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["DailyRewards"] = function()
	if MainFrame and MainFrame.Visible then
		MainFrame.Visible = false
		DarkBg.Visible = false
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end

ToggleBtn.MouseButton1Click:Connect(function()
	local targetVisible = not MainFrame.Visible
	if targetVisible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "DailyRewards" then closeFunc() end
		end
	end
	
	MainFrame.Visible = targetVisible
	DarkBg.Visible = MainFrame.Visible
	if MainFrame.Visible then
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 15}):Play()
		updateUI()
		MainFrame.Position = UDim2.new(0.5, -450, 1.5, -337)
		TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -450, 0.5, -337)}):Play()
	else
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	DarkBg.Visible = false
	TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
end)

local isClaiming = false
ClaimBtn.MouseButton1Click:Connect(function()
	if isClaiming or not ClaimBtn.Active then return end
	isClaiming = true
	local success, resultStreak, resultReward = ClaimDailyRewardRF:InvokeServer()
	
	if success then
		-- Konfetti (dĹşwiÄ™k lokalny)
		local soundTemplate = ReplicatedStorage:WaitForChild("Claimed")
		if soundTemplate then
			local sound = soundTemplate:Clone()
			sound.Volume = 2
			sound.Parent = workspace
			sound:Play()
			game.Debris:AddItem(sound, 3)
		end
		
		updateUI()
	end
	isClaiming = false
end)

-- Update in background logic
LocalPlayer:GetAttributeChangedSignal("LoginStreak"):Connect(function()
	if MainFrame.Visible then updateUI() end
end)
