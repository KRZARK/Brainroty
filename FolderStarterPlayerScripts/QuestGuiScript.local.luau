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

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
backdrop.BackgroundTransparency = 1
backdrop.Visible = false
backdrop.ZIndex = 49
backdrop.Parent = screenGui

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "QuestToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = playerGui

local questBtn = Instance.new("ImageButton")
questBtn.Name = "OpenQuests"
questBtn.Position = HudTileStyle.getSlot("left", 3)
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
	slotIndex = 3,
	zIndex = 100,
})

-- GŁÓWNY PANEL ZADAŃ
local questPanel = Instance.new("Frame")
questPanel.Size = UDim2.fromOffset(520, 560)
questPanel.Position = UDim2.new(0.5, 0, 0.52, 0)
questPanel.AnchorPoint = Vector2.new(0.5, 0.5)
questPanel.BackgroundColor3 = Color3.fromRGB(24, 31, 56)
questPanel.Visible = false
questPanel.ZIndex = 50
questPanel.Parent = screenGui
Instance.new("UICorner", questPanel).CornerRadius = UDim.new(0, 26)
local panelStroke = Instance.new("UIStroke", questPanel)
panelStroke.Thickness = 3
panelStroke.Color = Color3.new(0, 0, 0)
panelStroke.Transparency = 0.06

HudTileStyle.bindResponsivePanelScale(questPanel, {
	baseSize = UDim2.fromOffset(520, 560),
	landscapeWidthRatio = 0.84,
	landscapeHeightRatio = 0.88,
	portraitWidthRatio = 0.92,
	portraitHeightRatio = 0.84,
	mobileMinScale = 0.54,
})

local panelGradient = Instance.new("UIGradient", questPanel)
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 55, 93)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 28, 48)),
})
panelGradient.Rotation = 90

local panelPattern = Instance.new("ImageLabel", questPanel)
panelPattern.Name = "GreenStudsPattern"
panelPattern.Size = UDim2.fromScale(1, 1)
panelPattern.BackgroundTransparency = 1
panelPattern.Image = greenStudsImage
panelPattern.ImageColor3 = Color3.fromRGB(113, 144, 214)
panelPattern.ImageTransparency = 0.76
panelPattern.ScaleType = Enum.ScaleType.Tile
panelPattern.TileSize = UDim2.fromOffset(128, 128)
panelPattern.ZIndex = 50
Instance.new("UICorner", panelPattern).CornerRadius = UDim.new(0, 26)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, -28, 0, 64)
header.Position = UDim2.new(0, 14, 0, 14)
header.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
header.BackgroundTransparency = 0.12
header.BorderSizePixel = 0
header.ZIndex = 51
header.Parent = questPanel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local headerPattern = Instance.new("ImageLabel", header)
headerPattern.Size = UDim2.fromScale(1, 1)
headerPattern.BackgroundTransparency = 1
headerPattern.Image = greenStudsImage
headerPattern.ImageColor3 = Color3.fromRGB(94, 122, 196)
headerPattern.ImageTransparency = 0.82
headerPattern.ScaleType = Enum.ScaleType.Tile
headerPattern.TileSize = UDim2.fromOffset(112, 112)
headerPattern.ZIndex = 51
Instance.new("UICorner", headerPattern).CornerRadius = UDim.new(0, 20)

local accent = Instance.new("Frame", header)
accent.Name = "Accent"
accent.Size = UDim2.new(0, 12, 1, -18)
accent.Position = UDim2.new(0, 10, 0, 9)
accent.BackgroundColor3 = Color3.fromRGB(78, 136, 255)
accent.BorderSizePixel = 0
accent.ZIndex = 52
Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 38, 0, 0)
title.BackgroundTransparency = 1
title.Text = "DAILY QUESTS"
title.Font = Enum.Font.LuckiestGuy
title.TextSize = 38
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 53
title.Parent = header
local titleStroke = Instance.new("UIStroke", title)
titleStroke.Thickness = 2
titleStroke.Color = Color3.new(0, 0, 0)

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
closeBtn.ZIndex = 54
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 14)
local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Thickness = 2
closeStroke.Color = Color3.new(0, 0, 0)
closeStroke.Transparency = 0.08

-- KONTENER NA ZADANIA
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -28, 1, -106)
listFrame.Position = UDim2.new(0, 14, 0, 92)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 8
listFrame.ScrollBarImageColor3 = Color3.fromRGB(170, 196, 255)
listFrame.ZIndex = 51
listFrame.Parent = questPanel
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 12)

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
local panelOpen = false

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
	if panelOpen then
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

local function updatePanelVisibility(open)
	panelOpen = open
	backdrop.Visible = open
	questPanel.Visible = open

	if open then
		backdrop.BackgroundTransparency = 1
		questPanel.Position = UDim2.new(0.5, 0, 0.54, 0)
		TweenService:Create(backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.38,
		}):Play()
		TweenService:Create(questPanel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	else
		local panelTween = TweenService:Create(questPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.54, 0),
		})
		panelTween:Play()
		TweenService:Create(backdrop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		panelTween.Completed:Connect(function()
			if not panelOpen then
				backdrop.Visible = false
				questPanel.Visible = false
			end
		end)
	end
end

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
		qFrame.Size = UDim2.new(1, -4, 0, 108)
		qFrame.BackgroundColor3 = Color3.fromRGB(22, 28, 48)
		qFrame.BackgroundTransparency = 0.06
		qFrame.BorderSizePixel = 0
		qFrame.ZIndex = 52
		qFrame.Parent = listFrame
		Instance.new("UICorner", qFrame).CornerRadius = UDim.new(0, 20)
		local qStroke = Instance.new("UIStroke", qFrame)
		qStroke.Thickness = 2
		qStroke.Color = Color3.new(0, 0, 0)
		qStroke.Transparency = 0.1

		local rowPattern = Instance.new("ImageLabel")
		rowPattern.Size = UDim2.new(0, 56, 1, 0)
		rowPattern.BackgroundTransparency = 1
		rowPattern.Image = greenStudsImage
		rowPattern.ImageColor3 = Color3.fromRGB(90, 122, 198)
		rowPattern.ImageTransparency = 0.8
		rowPattern.ScaleType = Enum.ScaleType.Tile
		rowPattern.TileSize = UDim2.fromOffset(96, 96)
		rowPattern.ZIndex = 52
		rowPattern.Parent = qFrame
		Instance.new("UICorner", rowPattern).CornerRadius = UDim.new(0, 20)
		
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -178, 0, 38)
		desc.Position = UDim2.new(0, 20, 0, 12)
		desc.BackgroundTransparency = 1
		desc.Text = string.format(config.Desc, config.Req)
		desc.TextColor3 = Color3.new(1, 1, 1)
		desc.Font = Enum.Font.GothamBold
		desc.TextSize = 18
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 53
		desc.Parent = qFrame
		
		local rewardLbl = Instance.new("TextLabel")
		rewardLbl.Size = UDim2.new(0, 132, 0, 30)
		rewardLbl.Position = UDim2.new(1, -18, 0, 12)
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
		barBg.Size = UDim2.new(1, -178, 0, 30)
		barBg.Position = UDim2.new(0, 20, 0, 64)
		barBg.BackgroundColor3 = Color3.fromRGB(16, 21, 38)
		barBg.ZIndex = 53
		barBg.Parent = qFrame
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 14)
		local barStroke = Instance.new("UIStroke", barBg)
		barStroke.Thickness = 1.5
		barStroke.Color = Color3.new(0, 0, 0)
		barStroke.Transparency = 0.08
		
		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.fromScale(math.clamp(qVal.Value / config.Req, 0, 1), 1)
		barFill.BackgroundColor3 = Color3.fromRGB(56, 182, 92)
		barFill.ZIndex = 54
		barFill.Parent = barBg
		Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 14)
		
		local progressTxt = Instance.new("TextLabel")
		progressTxt.Size = UDim2.fromScale(1, 1)
		progressTxt.BackgroundTransparency = 1
		progressTxt.Text = math.floor(qVal.Value) .. " / " .. config.Req
		progressTxt.TextColor3 = Color3.new(1, 1, 1)
		progressTxt.Font = Enum.Font.GothamBold
		progressTxt.TextSize = 15
		progressTxt.ZIndex = 55
		progressTxt.Parent = barBg
		local progressStroke = Instance.new("UIStroke", progressTxt)
		progressStroke.Thickness = 2
		progressStroke.Color = Color3.new(0, 0, 0)
		
		local claimBtn = Instance.new("TextButton")
		claimBtn.Size = UDim2.new(0, 128, 0, 46)
		claimBtn.Position = UDim2.new(1, -18, 0, 54)
		claimBtn.AnchorPoint = Vector2.new(1, 0)
		claimBtn.BackgroundColor3 = Color3.fromRGB(90, 96, 104)
		claimBtn.Text = "CLAIM"
		claimBtn.TextColor3 = Color3.new(1, 1, 1)
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.TextSize = 18
		claimBtn.AutoButtonColor = false
		claimBtn.ZIndex = 54
		claimBtn.Parent = qFrame
		Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 16)
		local claimStroke = Instance.new("UIStroke", claimBtn)
		claimStroke.Thickness = 2
		claimStroke.Color = Color3.new(0, 0, 0)
		claimStroke.Transparency = 0.12
		
		-- Aktualizacja paska w czasie rzeczywistym
		local conn = qVal.Changed:Connect(function(newVal)
			progressTxt.Text = math.floor(newVal) .. " / " .. config.Req
			barFill:TweenSize(UDim2.fromScale(math.clamp(newVal / config.Req, 0, 1), 1), "Out", "Quad", 0.3, true)
			
			if newVal >= config.Req and not qVal:GetAttribute("Claimed") then
				claimBtn.BackgroundColor3 = Color3.fromRGB(56, 182, 92)
			end
		end)
		table.insert(questConnections, conn)
		
		-- Ustalenie stanu przycisku
		local isClaimed = qVal:GetAttribute("Claimed")
		if isClaimed then
			claimBtn.BackgroundColor3 = Color3.fromRGB(62, 70, 79)
			claimBtn.Text = "DONE"
			barFill.BackgroundColor3 = Color3.fromRGB(48, 126, 186)
		elseif qVal.Value >= config.Req then
			claimBtn.BackgroundColor3 = Color3.fromRGB(56, 182, 92)
		end
		
		claimBtn.MouseButton1Click:Connect(function()
			if qVal.Value >= config.Req and not qVal:GetAttribute("Claimed") then
				ClaimQuestReward:FireServer(qVal.Name)
				playClaimRewardSound()
				claimBtn.BackgroundColor3 = Color3.fromRGB(62, 70, 79)
				claimBtn.Text = "DONE"
				barFill.BackgroundColor3 = Color3.fromRGB(48, 126, 186)
				qVal:SetAttribute("Claimed", true)
			end
		end)
	end
end



-- Obsługa otwierania/zamykania z zabezpieczeniem
local function toggleMenu()
	print("[QuestSystem] Clicked Open Button!")
	local targetVisible = not panelOpen
	if targetVisible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "QuestGui" then closeFunc() end
		end
	end
	updatePanelVisibility(targetVisible)
	
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
	if panelOpen then
		updatePanelVisibility(false)
		TweenService:Create(questBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
		updateNotifyBadge()
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
