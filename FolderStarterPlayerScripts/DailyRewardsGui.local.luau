local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local ClaimDailyRewardRF = BrainrotEvents:WaitForChild("ClaimDailyReward")

-- Inicjalizacja Głównego Ekranu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DailyRewardsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Przycisk Kalendarza na ekranie (Prawy dolny sektor)
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleDailyMenu"
ToggleBtn.Size = UDim2.fromOffset(65, 65)
ToggleBtn.Position = UDim2.new(1, -15, 0.75, 0) -- Przesunięte w dół aby nie zasłaniać
ToggleBtn.AnchorPoint = Vector2.new(1, 0.5)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Image = "rbxassetid://15222045142" -- Ikonka szarego kalendarza (zastępcza)
local rsCalIcon = ReplicatedStorage:FindFirstChild("Kalendarz")
if rsCalIcon then ToggleBtn.Image = rsCalIcon:IsA("Decal") and rsCalIcon.Texture or rsCalIcon.Image end
ToggleBtn.Parent = ScreenGui

local btnLabel = Instance.new("TextLabel")
btnLabel.Size = UDim2.new(1.5, 0, 0, 20)
btnLabel.Position = UDim2.new(-0.25, 0, 1, 0)
btnLabel.BackgroundTransparency = 1
btnLabel.Text = "DAILY REWARDS"
btnLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
btnLabel.Font = Enum.Font.LuckiestGuy
btnLabel.TextSize = 14
btnLabel.TextStrokeTransparency = 0
btnLabel.Parent = ToggleBtn

-- Ciemne tło całego ekranu (Blur logic)
local DarkBg = Instance.new("Frame")
DarkBg.Size = UDim2.new(1,0,1,0)
DarkBg.BackgroundColor3 = Color3.new(0,0,0)
DarkBg.BackgroundTransparency = 0.5
DarkBg.Visible = false
DarkBg.Parent = ScreenGui

-- Panel Główny Kalendarza
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 900, 0, 675)
MainFrame.Position = UDim2.new(0.5, -450, 0.5, -337)
MainFrame.BackgroundTransparency = 1 -- Przezroczyste tło, bo używamy ImageLabel pod spodem
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)

-- Tło GreenStuds dla MainFrame
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

-- Tętniąca animacja
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
	
	-- Poprawka: jeśli odebrano dzień 7 dzisiaj, streak = 1, ale chcemy by na ekranie zaznaczyło że odebrano!
	local displayStreak = streak
	if claimedToday and streak == 1 then
		displayStreak = 8
	end
	
	for i = 1, 7 do
		local reward = GameConfig.DailyRewards[i]
		
		local tile = Instance.new("Frame")
		tile.BackgroundTransparency = 1 -- Przezroczyste tło dla kafelka
		tile.Parent = GridContainer
		Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 8)
		
		-- Tło GreenStuds dla kafelka
		local TileBg = Instance.new("ImageLabel")
		TileBg.Name = "TileBg"
		TileBg.Size = UDim2.fromScale(1, 1)
		TileBg.BackgroundTransparency = 0
		TileBg.BackgroundColor3 = Color3.fromRGB(40, 70, 40) -- Fallback
		TileBg.ZIndex = 0
		if gs then TileBg.Image = gs:IsA("Decal") and gs.Texture or gs.Image end
		TileBg.ImageColor3 = Color3.fromRGB(60, 100, 60) -- Ciemniejsza zieleń
		TileBg.ScaleType = Enum.ScaleType.Tile
		TileBg.TileSize = UDim2.fromOffset(64, 64)
		TileBg.Parent = tile
		Instance.new("UICorner", TileBg).CornerRadius = UDim.new(0, 8)
		
		-- Tytuł (Day 1)
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
		local strDesc = reward.Type == "Coin" and tostring(reward.Value).." Coins" or ((reward.Type == "Speed" and "Speed x2 (30m)") or "Jump x2 (30m)")
		desc.Text = strDesc
		desc.TextColor3 = Color3.fromRGB(200, 200, 200)
		desc.Font = Enum.Font.GothamBold
		desc.TextSize = 22
		desc.ZIndex = 2
		desc.Parent = tile
		
		-- Ikona środkowa
		local iconFrame = Instance.new("ImageLabel")
		iconFrame.Size = UDim2.new(0, 65, 0, 65)
		iconFrame.Position = UDim2.new(0.5, -32.5, 0.5, -12)
		iconFrame.BackgroundTransparency = 1
		iconFrame.ZIndex = 3 -- Wyżej niż tło ikony
		iconFrame.Parent = tile
		
		local rsIcon = ReplicatedStorage:FindFirstChild(reward.Icon)
		if rsIcon and rsIcon:IsA("Decal") then
			iconFrame.Image = rsIcon.Texture
		elseif rsIcon and rsIcon:IsA("ImageLabel") then
			iconFrame.Image = rsIcon.Image
		else
			iconFrame.Image = "rbxassetid://13193264908" -- fallback
		end
		
		-- LOGIKA STANÓW
		local isClaimed = (i < displayStreak) or (i == displayStreak and claimedToday)
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
			-- Przyszłe dni (zamiast Locked)
			TileBg.ImageColor3 = Color3.fromRGB(60, 100, 60) -- Standardowy zielony
		end

		-- WYMUSZENIE KOLORU I WIDOCZNOŚCI DLA SPEED/JUMP
		if reward.Type == "Speed" or reward.Type == "Jump" then
			-- Przesuwamy wyżej żeby nie zasłaniał opisu
			iconFrame.Size = UDim2.new(0, 85, 0, 85)
			iconFrame.Position = UDim2.new(0.5, -42.5, 0.5, -50)
			
			-- Skoro ikony są czarne, dodajemy pod nie jaskrawą czerwoną tarczę (koło)
			local glow = Instance.new("Frame")
			glow.Name = "IconGlow"
			glow.Size = UDim2.new(0, 85, 0, 85)
			glow.Position = iconFrame.Position
			glow.BackgroundColor3 = Color3.fromRGB(220, 0, 0) -- JASKRAWA CZERWIEŃ
			glow.ZIndex = 2
			glow.Parent = tile
			Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0) -- Robimy idealne koło
			
			-- Sylwetkę ludzika wymuszamy na czarno żeby biła po oczach na czerwonym tle
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

ToggleBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
	DarkBg.Visible = MainFrame.Visible
	if MainFrame.Visible then
		updateUI()
		MainFrame.Position = UDim2.new(0.5, -450, 1.5, -337)
		TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -450, 0.5, -337)}):Play()
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	DarkBg.Visible = false
end)

local isClaiming = false
ClaimBtn.MouseButton1Click:Connect(function()
	if isClaiming or not ClaimBtn.Active then return end
	isClaiming = true
	local success, resultStreak, resultReward = ClaimDailyRewardRF:InvokeServer()
	
	if success then
		-- Konfetti (dźwięk lokalny)
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://13214811565" -- Tada / Success chime
		sound.Volume = 2
		sound.Parent = Workspace
		sound:Play()
		game.Debris:AddItem(sound, 3)
		
		updateUI()
	end
	isClaiming = false
end)

-- Update in background logic
LocalPlayer:GetAttributeChangedSignal("LoginStreak"):Connect(function()
	if MainFrame.Visible then updateUI() end
end)
