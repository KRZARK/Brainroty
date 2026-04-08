local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("[QuestSystem] Initializing QuestGuiScript...")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local ClaimQuestReward = BrainrotEvents:WaitForChild("ClaimQuestReward")

print("[QuestSystem] Events found. Creating GUI...")

-- 1. Tworzenie GUI
local oldGui = playerGui:FindFirstChild("QuestUI")
if oldGui then oldGui:Destroy() end

local oldToggle = playerGui:FindFirstChild("QuestToggleUI")
if oldToggle then oldToggle:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 -- Ta sama warstwa co reszta bocznych kafelków
screenGui.Parent = playerGui

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "QuestToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = playerGui

local questBtn = Instance.new("ImageButton")
questBtn.Name = "OpenQuests"
questBtn.Position = HudTileStyle.getSlot("left", 1)
questBtn.ZIndex = 100
questBtn.Parent = ToggleGui

local btnIcon = Instance.new("ImageLabel")
btnIcon.Name = "QuestIcon"
btnIcon.Parent = questBtn

-- Ładowanie ikony dynamicznie (zastępuje brzydką skrzynkę/emoji)
task.spawn(function()
	local questIconObj = ReplicatedStorage:WaitForChild("QuestIcon", 5)
	if questIconObj then
		if questIconObj:IsA("Decal") then
			btnIcon.Image = questIconObj.Texture
		elseif questIconObj:IsA("ImageLabel") or questIconObj:IsA("ImageButton") then
			btnIcon.Image = questIconObj.Image
		elseif questIconObj:IsA("StringValue") then
			btnIcon.Image = questIconObj.Value
		else
			btnIcon.Image = "rbxassetid://15266855513" -- Fallback
		end
	else
		btnIcon.Image = "rbxassetid://15266855513" -- Fallback globalny (Zwój)
	end
end)

local btnText = Instance.new("TextLabel")
btnText.Text = "QUESTS"
btnText.Parent = questBtn

HudTileStyle.apply(questBtn, btnIcon, btnText, {
	side = "left",
	slotIndex = 1,
	zIndex = 100,
})

-- GŁÓWNY PANEL ZADAŃ
local questPanel = Instance.new("Frame")
questPanel.Size = UDim2.fromOffset(400, 500)
questPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
questPanel.AnchorPoint = Vector2.new(0.5, 0.5)
questPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
questPanel.Visible = false
questPanel.ZIndex = 50
questPanel.Parent = screenGui
Instance.new("UICorner", questPanel).CornerRadius = UDim.new(0, 15)
local panelStroke = Instance.new("UIStroke", questPanel)
panelStroke.Thickness = 4
panelStroke.Color = Color3.fromRGB(255, 215, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundTransparency = 1
title.Text = "DAILY QUESTS"
title.Font = Enum.Font.LuckiestGuy
title.TextSize = 45
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.ZIndex = 51
title.Parent = questPanel
Instance.new("UIStroke", title).Thickness = 3

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.new(1, -10, 0, 10)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 25
closeBtn.ZIndex = 52
closeBtn.Parent = questPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5, 0)

-- KONTENER NA ZADANIA
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -80)
listFrame.Position = UDim2.new(0, 10, 0, 70)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 6
listFrame.ZIndex = 51
listFrame.Parent = questPanel
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 10)

-- IKONKA POWIADOMIENIA (Wykrzyknik)
local notifyBadge = Instance.new("ImageLabel")
notifyBadge.Name = "NotifyBadge"
notifyBadge.Size = UDim2.fromOffset(38, 38)
notifyBadge.Position = UDim2.new(1, -6, 0, 6)
notifyBadge.AnchorPoint = Vector2.new(1, 0)
notifyBadge.BackgroundTransparency = 1
notifyBadge.Visible = false
notifyBadge.ZIndex = 110
notifyBadge.Parent = questBtn

task.spawn(function()
	local exclamObj = ReplicatedStorage:WaitForChild("Wykrzyknik", 5)
	if exclamObj then
		if exclamObj:IsA("Decal") then notifyBadge.Image = exclamObj.Texture
		elseif exclamObj:IsA("ImageLabel") or exclamObj:IsA("ImageButton") then notifyBadge.Image = exclamObj.Image
		elseif exclamObj:IsA("StringValue") then notifyBadge.Image = exclamObj.Value
		else notifyBadge.Image = "rbxassetid://15266855513" -- Fallback
		end
	else
		notifyBadge.Image = "rbxassetid://15266855513" -- Fallback
	end
end)

-- LOGIKA UI
local function getQuestConfig(id)
	for _, q in ipairs(GameConfig.QuestSystem.Pool) do
		if q.ID == id then return q end
	end
	return nil
end

local function checkForClaimable()
	local questsFolder = player:FindFirstChild("DailyQuestsFolder")
	if not questsFolder then return false end
	for _, qVal in ipairs(questsFolder:GetChildren()) do
		local config = getQuestConfig(qVal.Name)
		if config and qVal.Value >= config.Req and not qVal:GetAttribute("Claimed") then
			return true
		end
	end
	return false
end

local function updateNotifyBadge()
	if questPanel.Visible then
		notifyBadge.Visible = false
	else
		notifyBadge.Visible = checkForClaimable()
	end
end

-- Nasłuchiwanie na zmiany w zadaniach
task.spawn(function()
	local questsFolder = player:WaitForChild("DailyQuestsFolder", 10)
	if questsFolder then
		for _, qVal in ipairs(questsFolder:GetChildren()) do
			qVal.Changed:Connect(updateNotifyBadge)
			qVal:GetAttributeChangedSignal("Claimed"):Connect(updateNotifyBadge)
		end
		updateNotifyBadge()
	end
end)

local questConnections = {} -- Tabela na aktywne połączenia (zapobiega błędom 'Can only tween')

local function refreshQuests()
	-- 1. Czyścimy stare połączenia, żeby nie wywalało błędu przy tweenowaniu nieistniejących pasków
	for _, conn in ipairs(questConnections) do
		conn:Disconnect()
	end
	table.clear(questConnections)

	-- 2. Usuwamy stare ramki
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local questsFolder = player:WaitForChild("DailyQuestsFolder", 5)
	if not questsFolder then return end
	
	for _, qVal in ipairs(questsFolder:GetChildren()) do
		local config = getQuestConfig(qVal.Name)
		if not config then continue end
		
		local qFrame = Instance.new("Frame")
		qFrame.Size = UDim2.new(1, -10, 0, 100)
		qFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		qFrame.ZIndex = 52
		qFrame.Parent = listFrame
		Instance.new("UICorner", qFrame).CornerRadius = UDim.new(0, 8)
		
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -10, 0, 30)
		desc.Position = UDim2.new(0, 10, 0, 5)
		desc.BackgroundTransparency = 1
		desc.Text = string.format(config.Desc, config.Req)
		desc.TextColor3 = Color3.new(1, 1, 1)
		desc.Font = Enum.Font.FredokaOne
		desc.TextSize = 18
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 53
		desc.Parent = qFrame
		
		local rewardLbl = Instance.new("TextLabel")
		rewardLbl.Size = UDim2.new(0, 100, 0, 30)
		rewardLbl.Position = UDim2.new(1, -10, 0, 5)
		rewardLbl.AnchorPoint = Vector2.new(1, 0)
		rewardLbl.BackgroundTransparency = 1
		rewardLbl.Text = "+" .. config.Reward .. " 💰"
		rewardLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
		rewardLbl.Font = Enum.Font.FredokaOne
		rewardLbl.TextSize = 20
		rewardLbl.TextXAlignment = Enum.TextXAlignment.Right
		rewardLbl.ZIndex = 53
		rewardLbl.Parent = qFrame
		
		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(0.65, 0, 0, 25)
		barBg.Position = UDim2.new(0, 10, 0, 65)
		barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		barBg.ZIndex = 53
		barBg.Parent = qFrame
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(0.5, 0)
		
		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.fromScale(math.clamp(qVal.Value / config.Req, 0, 1), 1)
		barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		barFill.ZIndex = 54
		barFill.Parent = barBg
		Instance.new("UICorner", barFill).CornerRadius = UDim.new(0.5, 0)
		
		local progressTxt = Instance.new("TextLabel")
		progressTxt.Size = UDim2.fromScale(1, 1)
		progressTxt.BackgroundTransparency = 1
		progressTxt.Text = math.floor(qVal.Value) .. " / " .. config.Req
		progressTxt.TextColor3 = Color3.new(1, 1, 1)
		progressTxt.Font = Enum.Font.SourceSansBold
		progressTxt.TextSize = 16
		progressTxt.ZIndex = 55
		progressTxt.Parent = barBg
		
		local claimBtn = Instance.new("TextButton")
		claimBtn.Size = UDim2.new(0.25, 0, 0, 40)
		claimBtn.Position = UDim2.new(1, -10, 0, 50)
		claimBtn.AnchorPoint = Vector2.new(1, 0)
		claimBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		claimBtn.Text = "CLAIM"
		claimBtn.TextColor3 = Color3.new(1, 1, 1)
		claimBtn.Font = Enum.Font.FredokaOne
		claimBtn.TextSize = 18
		claimBtn.ZIndex = 53
		claimBtn.Parent = qFrame
		Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)
		
		-- Aktualizacja paska w czasie rzeczywistym
		local conn = qVal.Changed:Connect(function(newVal)
			progressTxt.Text = math.floor(newVal) .. " / " .. config.Req
			barFill:TweenSize(UDim2.fromScale(math.clamp(newVal / config.Req, 0, 1), 1), "Out", "Quad", 0.3, true)
			
			if newVal >= config.Req and not qVal:GetAttribute("Claimed") then
				claimBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
			end
		end)
		table.insert(questConnections, conn)
		
		-- Ustalenie stanu przycisku
		local isClaimed = qVal:GetAttribute("Claimed")
		if isClaimed then
			claimBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			claimBtn.Text = "DONE"
			barFill.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
		elseif qVal.Value >= config.Req then
			claimBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		end
		
		claimBtn.MouseButton1Click:Connect(function()
			if qVal.Value >= config.Req and not qVal:GetAttribute("Claimed") then
				ClaimQuestReward:FireServer(qVal.Name)
				claimBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				claimBtn.Text = "DONE"
				barFill.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
				qVal:SetAttribute("Claimed", true)
			end
		end)
	end
end



-- Obsługa otwierania/zamykania z zabezpieczeniem
local function toggleMenu()
	print("[QuestSystem] Clicked Open Button!")
	local targetVisible = not questPanel.Visible
	if targetVisible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "QuestGui" then closeFunc() end
		end
	end
	questPanel.Visible = targetVisible
	
	if targetVisible then
		TweenService:Create(questBtn, TweenInfo.new(0.2), {Rotation = -15}):Play()
		notifyBadge.Visible = false -- Chowanie powiadomienia przy otwarciu
		task.spawn(function()
			local success, err = pcall(function()
				refreshQuests()
			end)
			if not success then
				warn("[QuestSystem] Błąd podczas renderowania zadań: " .. tostring(err))
			end
		end)
	else
		TweenService:Create(questBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
		updateNotifyBadge()
	end
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["QuestGui"] = function()
	if questPanel and questPanel.Visible then
		toggleMenu()
	end
end

questBtn.Activated:Connect(toggleMenu)
closeBtn.Activated:Connect(toggleMenu)

-- Animacje przycisku i powiadomienia
game:GetService("RunService").RenderStepped:Connect(function()
	local t = tick()
	btnIcon.Position = UDim2.new(0.5, 0, 0.38, 0)
	btnText.TextColor3 = HudTileStyle.BaseLabelColor
	
	-- Animacja pulsującego wykrzyknika
	if notifyBadge.Visible then
		local s = 1 + math.sin(t * 10) * 0.15
		notifyBadge.Size = UDim2.fromOffset(38 * s, 38 * s)
	end
end)
