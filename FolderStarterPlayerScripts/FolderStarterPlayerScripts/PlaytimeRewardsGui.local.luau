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

-- Inicjalizacja Danych z Serwera
local sessionStartTime = os.time()
local claimedRewards = {}

-- Pobranie prawdziwego czasu z serwera po załadowaniu
task.spawn(function()
	local st, claimed = getTimeEvent:InvokeServer()
	if st and claimed then
		sessionStartTime = st
		claimedRewards = claimed
	end
end)

-- Zmiana rozmiaru i struktura UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlaytimeRewardsUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Pobranie zasobów wizualnych
local Coin2D = ReplicatedStorage:WaitForChild("Coin2D")
local Wykrzyknik = ReplicatedStorage:WaitForChild("Wykrzyknik")

-- === 1. PRZYCISK Z LEWEJ STRONY ===
local giftBtn = Instance.new("ImageButton")
giftBtn.Name = "GiftButton"
giftBtn.Position = HudTileStyle.getSlot("right", 2)
giftBtn.ZIndex = 50
giftBtn.Parent = screenGui

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
Instance.new("UIStroke", giftTimerLbl).Thickness = 1

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
	if metrics.IsMobile then
		giftTitle.Text = "TIME"
		giftNotif.Size = UDim2.fromOffset(24, 24)
		giftNotif.Position = UDim2.new(1, -2, 0, 2)
		giftTimerLbl.Size = UDim2.new(0.82, 0, 0, 14)
		giftTimerLbl.Position = UDim2.new(0.5, 0, 0.58, 0)
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
mainPanel.Size = UDim2.fromOffset(500, 600)
mainPanel.Position = UDim2.fromScale(0.5, 0.5)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainPanel.Visible = false
mainPanel.ZIndex = 100
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 15)
local panelStroke = Instance.new("UIStroke", mainPanel)
panelStroke.Thickness = 4
panelStroke.Color = Color3.fromRGB(255, 215, 0)

-- Przycisk zamykania panelu
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(50, 50)
closeBtn.Position = UDim2.new(1, -10, 0, 10)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 30
closeBtn.ZIndex = 110
closeBtn.Parent = mainPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.fromOffset(0, 15)
title.BackgroundTransparency = 1
title.Text = "PLAYTIME REWARDS"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.LuckiestGuy
title.TextSize = 40
title.ZIndex = 101
title.Parent = mainPanel

-- Baner Społecznościowy
local socialBtn = Instance.new("TextButton")
socialBtn.Size = UDim2.new(0.9, 0, 0, 50)
socialBtn.Position = UDim2.new(0.5, 0, 0, 80)
socialBtn.AnchorPoint = Vector2.new(0.5, 0)
socialBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
socialBtn.Text = "👥 INVITE FRIEND (+20% COINS)"
socialBtn.TextColor3 = Color3.new(1, 1, 1)
socialBtn.Font = Enum.Font.FredokaOne
socialBtn.TextSize = 20
socialBtn.ZIndex = 102
socialBtn.Parent = mainPanel
Instance.new("UICorner", socialBtn).CornerRadius = UDim.new(0, 10)
local socialStroke = Instance.new("UIStroke", socialBtn)
socialStroke.Thickness = 3
socialStroke.Color = Color3.new(0, 0, 0)

-- Lista nagród
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(0.95, 0, 1, -150)
listFrame.Position = UDim2.new(0.5, 0, 0, 140)
listFrame.AnchorPoint = Vector2.new(0.5, 0)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 8
listFrame.ZIndex = 101
listFrame.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = listFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- === 3. BUDOWANIE ELEMENTÓW LISTY ===
local rewardRows = {}

for index, rewardData in ipairs(GameConfig.PlaytimeRewards) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 75)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.LayoutOrder = index
	row.ZIndex = 102
	row.Parent = listFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", row).Thickness = 2
	
	local timeLbl = Instance.new("TextLabel")
	timeLbl.Size = UDim2.new(0, 80, 1, 0)
	timeLbl.Position = UDim2.fromOffset(20, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Text = rewardData.TimeMinutes .. " MIN"
	timeLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
	timeLbl.Font = Enum.Font.FredokaOne
	timeLbl.TextSize = 25
	timeLbl.TextXAlignment = Enum.TextXAlignment.Left
	timeLbl.ZIndex = 103
	timeLbl.Parent = row
	
	local coinLbl = Instance.new("TextLabel")
	coinLbl.Size = UDim2.new(0, 120, 1, 0)
	coinLbl.Position = UDim2.fromOffset(120, 0)
	coinLbl.BackgroundTransparency = 1
	coinLbl.Text = "💰 " .. rewardData.Reward
	coinLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinLbl.Font = Enum.Font.FredokaOne
	coinLbl.TextSize = 25
	coinLbl.TextXAlignment = Enum.TextXAlignment.Left
	coinLbl.ZIndex = 103
	coinLbl.Parent = row
	
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0, 140, 0, 50)
	actionBtn.Position = UDim2.new(1, -15, 0.5, 0)
	actionBtn.AnchorPoint = Vector2.new(1, 0.5)
	actionBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	actionBtn.Text = "LOCKED"
	actionBtn.TextColor3 = Color3.new(1, 1, 1)
	actionBtn.Font = Enum.Font.FredokaOne
	actionBtn.TextSize = 22
	actionBtn.ZIndex = 105
	actionBtn.Parent = row
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)
	
	table.insert(rewardRows, {
		Frame = row,
		Button = actionBtn,
		Data = rewardData,
		Index = index
	})
	
	-- Obsługa kliknięcia (Odbiór Nagrody)
	actionBtn.MouseButton1Click:Connect(function()
		if actionBtn.Text == "CLAIM" then
			actionBtn.Text = "..."
			local success, result, hadSocBonus = claimEvent:InvokeServer(index)
			if success then
				claimedRewards[tostring(index)] = true -- Czasem stringuje się przy jsonie
				claimedRewards[index] = true
				actionBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				actionBtn.Text = "CLAIMED"
				
				-- Pokazanie popupu
				local pop = Instance.new("TextLabel")
				pop.Size = UDim2.fromOffset(200, 50)
				pop.Position = UDim2.fromOffset(actionBtn.AbsolutePosition.X, actionBtn.AbsolutePosition.Y)
				pop.BackgroundTransparency = 1
				pop.ZIndex = 200
				pop.Font = Enum.Font.LuckiestGuy
				pop.TextSize = 35
				pop.TextColor3 = Color3.new(0, 1, 0)
				pop.Text = "+ " .. result .. " 💰" .. (hadSocBonus and " (FRIEND BONUS!)" or "")
				pop.Parent = screenGui
				
				local popStroke = Instance.new("UIStroke", pop)
				popStroke.Thickness = 3
				
				-- Ruch do góry
				local tw = TweenService:Create(pop, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = pop.Position - UDim2.fromOffset(0, 50), TextTransparency = 1})
				tw:Play()
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

-- Aktualizacja baneru zapraszania znajomych
local isFriendBonusActive = false
local function updateSocialBanner()
	local foundFriend = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local success, isF = pcall(function() return player:IsFriendsWith(p.UserId) end)
			if success and isF then
				foundFriend = true
				break
			end
		end
	end
	
	if foundFriend then
		if not isFriendBonusActive then
			isFriendBonusActive = true
			socialBtn.BackgroundColor3 = Color3.fromRGB(220, 180, 0) -- Złoty kolor
			socialBtn.Text = "🤝 FRIEND BONUS ACTIVE! (+20%)"
			socialStroke.Color = Color3.new(1, 1, 1)
		end
	else
		if isFriendBonusActive then
			isFriendBonusActive = false
			socialBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200) -- Niebieski kolor
			socialBtn.Text = "👥 INVITE FRIEND (+20% COINS)"
			socialStroke.Color = Color3.new(0, 0, 0)
		end
	end
end

-- Sprawdzanie znajomych co 10 sekund (nie w pętli render, żeby nie zabić rate-limitu!)
task.spawn(function()
	while true do
		updateSocialBanner()
		task.wait(10)
	end
end)

socialBtn.MouseButton1Click:Connect(function()
	if not isFriendBonusActive then
		local success, err = pcall(function()
			SocialService:PromptGameInvite(player)
		end)
		if not success then
			warn("SocialService error:", err)
		end
	end
end)

giftBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = not mainPanel.Visible
	if mainPanel.Visible then
		mainPanel.Size = UDim2.fromOffset(450, 550)
		TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(500, 600)}):Play()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
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
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				btn.Text = "CLAIMED"
			end
		else
			-- Jeśli jeszcze nieodebrane
			if elapsed >= reqSecs then
				anyReadyToClaim = true
				if btn.Text ~= "CLAIM" and btn.Text ~= "..." then
					btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
					btn.Text = "CLAIM"
				end
			else
				local left = reqSecs - elapsed
				btn.Text = formatTime(left)
				if left < lowestTimeLeft then
					lowestTimeLeft = left
					nextRewardAmount = rowObj.Data.Reward
				end
			end
		end
	end
	
	-- Efekt pulsowania wykrzyknika i ikonki
	if anyReadyToClaim then
		giftNotif.Visible = true
		local scale = 1 + math.sin(tick() * 8) * 0.2
		giftNotif.Size = UDim2.fromOffset(35 * scale, 35 * scale)
		giftBtn.Rotation = math.sin(tick() * 4) * 3
		
		giftTimerLbl.Text = "CLAIM!"
		giftTimerLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
		giftAmountLbl.Text = ""
	else
		giftNotif.Visible = false
		giftBtn.Rotation = 0
		
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
