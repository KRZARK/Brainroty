local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService") -- Potrzebne do animacji

-- 1. USTAWIENIA KOLORÓW
local RarityColors = {
	["Common"] = Color3.fromRGB(163, 162, 165),
	["Rare"] = Color3.fromRGB(64, 255, 71),
	["Epic"] = Color3.fromRGB(180, 71, 255),
	["Legendary"] = Color3.fromRGB(255, 145, 0),
	["Mythic"] = Color3.fromRGB(255, 33, 33),
	["Brainrot God"] = Color3.fromRGB(0, 255, 255),
	["Secret"] = Color3.fromRGB(150, 150, 150),
	["OG"] = Color3.fromRGB(0, 255, 255),
}

local RarityOrder = {
	["Common"] = 1,
	["Rare"] = 2,
	["Epic"] = 3,
	["Legendary"] = 4,
	["Mythic"] = 5,
	["Brainrot God"] = 6,
	["Secret"] = 7,
	["OG"] = 8,
}

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- === POPRAWKA: ODŚWIEŻENIE ZMIENNYCH PO RESPAWNIE / REBIRTH ===
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	rootPart = newChar:WaitForChild("HumanoidRootPart")
end)

local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))
local BrainrotCollectedEvent = BrainrotEvents:WaitForChild("BrainrotCollected")
local TogglePetEvent = BrainrotEvents:WaitForChild("TogglePetEvent")
local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage") 
local BrainrotyFolder = Workspace:WaitForChild("Brainroty") 

local CollectSound = SoundService:WaitForChild("CollectSound")
CollectSound.SoundId = "rbxassetid://3150375869"

local collectedBrainrots = {}
_G.CollectedBrainrotsTable = collectedBrainrots -- Udostępniamy tabelę dla sklepu
local spinningModels = {} 

-- UI Setup
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Name = "BrainrotIndexUI"
screenGui.DisplayOrder = 10
screenGui.IgnoreGuiInset = true -- Pozwala na precyzyjne sterowanie szczytem ekranu
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- === NOWA SEKACJA: GŁÓWNY PASEK POSTĘPU NA SAMEJ GÓRZE ===
local topProgressContainer = Instance.new("Frame")
topProgressContainer.Name = "TopProgressContainer"
topProgressContainer.Size = UDim2.new(0.4, 0, 0, 45)
topProgressContainer.Position = UDim2.new(0.5, 0, 0, 65) -- Przesunięty niżej (był na 35)
topProgressContainer.AnchorPoint = Vector2.new(0.5, 0)
topProgressContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topProgressContainer.BorderSizePixel = 0
topProgressContainer.Parent = screenGui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0.5, 0)
topCorner.Parent = topProgressContainer

local topStroke = Instance.new("UIStroke")
topStroke.Thickness = 3
topStroke.Color = Color3.fromRGB(255, 255, 255)
topStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
topStroke.Parent = topProgressContainer

local topProgressFill = Instance.new("Frame")
topProgressFill.Name = "Fill"
topProgressFill.Size = UDim2.fromScale(0, 1)
topProgressFill.BackgroundColor3 = Color3.fromRGB(255, 40, 100)
topProgressFill.BorderSizePixel = 0
topProgressFill.ClipsDescendants = true
topProgressFill.Parent = topProgressContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.5, 0)
fillCorner.Parent = topProgressFill

local stripes = Instance.new("ImageLabel")
stripes.Name = "Stripes"
stripes.Size = UDim2.new(2, 0, 1, 0)
stripes.Position = UDim2.new(0, 0, 0, 0)
stripes.BackgroundTransparency = 1
stripes.Image = "rbxassetid://13008436034"
stripes.ImageTransparency = 0.7
stripes.TileSize = UDim2.new(0, 60, 1, 0)
stripes.ScaleType = Enum.ScaleType.Tile
stripes.Parent = topProgressFill

local topProgressLabel = Instance.new("TextLabel")
topProgressLabel.Size = UDim2.fromScale(1, 1)
topProgressLabel.BackgroundTransparency = 1
topProgressLabel.Text = "BRAINROT PROGRESS: 0 / 0"
topProgressLabel.TextColor3 = Color3.new(1, 1, 1)
topProgressLabel.Font = Enum.Font.SourceSansBold
topProgressLabel.TextSize = 26
topProgressLabel.ZIndex = 5
topProgressLabel.Parent = topProgressContainer

-- SŁONIK NA KOŃCU (Powiększony z tłem)
local elephantFrame = Instance.new("Frame")
elephantFrame.Name = "ElephantAnchor"
elephantFrame.Size = UDim2.fromOffset(110, 110)
elephantFrame.Position = UDim2.new(1, 0, 0.5, 0)
elephantFrame.AnchorPoint = Vector2.new(0.5, 0.5)
elephantFrame.BackgroundTransparency = 1
elephantFrame.Parent = topProgressContainer

local elephantBg = Instance.new("Frame")
elephantBg.Name = "Background"
elephantBg.Size = UDim2.fromScale(0.9, 0.9)
elephantBg.Position = UDim2.fromScale(0.5, 0.5)
elephantBg.AnchorPoint = Vector2.new(0.5, 0.5)
elephantBg.BackgroundColor3 = Color3.fromRGB(92, 99, 102)
elephantBg.BorderSizePixel = 0
elephantBg.ZIndex = 1
elephantBg.Parent = elephantFrame

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = elephantBg

local bgStroke = Instance.new("UIStroke")
bgStroke.Thickness = 4 -- Zwiększyłem na 4, żeby czarna linia była lepiej widoczna
bgStroke.Color = Color3.fromRGB(0, 0, 0) -- CZARNY KOLOR
bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Upewnia się, że obrys idzie po krawędzi koła
bgStroke.Parent = elephantBg

local function setupElephant()
	local elephantModel = BrainrotStorage:FindFirstChild("Strawberry Elephant") or BrainrotStorage:FindFirstChildWhichIsA("Model")
	if elephantModel then
		local viewport = Instance.new("ViewportFrame")
		viewport.Size = UDim2.fromScale(1.4, 1.4) 
		viewport.Position = UDim2.fromScale(0.5, 0.4) 
		viewport.AnchorPoint = Vector2.new(0.5, 0.5)
		viewport.BackgroundTransparency = 1
		viewport.ZIndex = 52
		viewport.Parent = elephantFrame

		local clone = elephantModel:Clone()
		clone.Parent = viewport

		local cam = Instance.new("Camera")
		viewport.CurrentCamera = cam
		cam.Parent = viewport

		local cf, size = clone:GetBoundingBox()
		cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(size.X * 0.45, size.Y * 0.1, size.Z * 1.1), cf.Position)
	end
end
setupElephant()

-- === SEKACJA: UI POWIADOMIENIA ===
local notifyFrame = Instance.new("Frame")
notifyFrame.Name = "NotifyFrame"
notifyFrame.Size = UDim2.new(1, 0, 1, 0)
notifyFrame.Position = UDim2.new(0, 0, 0, 0)
notifyFrame.BackgroundTransparency = 1
notifyFrame.ZIndex = 150 -- <--- TO DODAJ/ZMIEŃ
notifyFrame.Parent = screenGui

local notifyLine1 = Instance.new("TextLabel")
local notifyLine2 = Instance.new("TextLabel")
local notifyLine2Shadow = Instance.new("TextLabel")
local notifyLine3 = Instance.new("TextLabel")

local function setupNotifyLabel(lbl, size, pos, fontSize, isTitle)
	lbl.Size = UDim2.new(1, 0, 0, size)
	lbl.Position = UDim2.new(0, 0, 0, pos)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextSize = fontSize
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.5
	lbl.TextStrokeColor3 = Color3.new(0,0,0)
	lbl.ZIndex = 155
	lbl.TextTransparency = 1
	lbl.Parent = notifyFrame

	if isTitle then
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 140, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 100))
		})
		gradient.Parent = lbl
	end
end

setupNotifyLabel(notifyLine1, 40, 110, 40, true) -- Przesunięty z 60 na 110, żeby nie nachodził na pasek progresu
setupNotifyLabel(notifyLine2Shadow, 80, 164, 85, false)
setupNotifyLabel(notifyLine2, 80, 160, 85, false)
setupNotifyLabel(notifyLine3, 75, 225, 65, false)

notifyLine2Shadow.TextColor3 = Color3.new(0, 0, 0)
notifyLine2Shadow.TextStrokeTransparency = 1
notifyLine2Shadow.ZIndex = notifyLine2.ZIndex - 1

local notifyViewport = Instance.new("ViewportFrame")
notifyViewport.Name = "NotifyViewport"
notifyViewport.Size = UDim2.new(0, 750, 0, 750)
notifyViewport.Position = UDim2.new(0.5, 0, 0.45, 100) -- Przesunięte w dół o 50px
notifyViewport.AnchorPoint = Vector2.new(0.5, 0.5)
notifyViewport.ZIndex = 160
notifyViewport.BackgroundTransparency = 1
notifyViewport.ImageTransparency = 1 
notifyViewport.Parent = notifyFrame

local notificationQueue = {}
local isShowingNow = false
local activeNotifyRarity = ""


local function createViewport(model, parent, isCollected)
	local viewport = parent:IsA("ViewportFrame") and parent or Instance.new("ViewportFrame")
	viewport.ZIndex = 52 -- Zawsze o 1 wyżej niż ramka-rodzic
	if not parent:IsA("ViewportFrame") then
		viewport.Size = UDim2.new(1, 0, 0.7, 0)
		viewport.BackgroundTransparency = 1
		viewport.Parent = parent
	end

	viewport:ClearAllChildren()
	local clone = model:Clone()
	clone.Parent = viewport

	local camera = Instance.new("Camera")
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	local cf, size = clone:GetBoundingBox()
	local maxSide = math.max(size.X, size.Y, size.Z)

	local isNotify = (parent == notifyViewport)
	local zoomFactor = isNotify and 1.2 or 0.8 
	local distance = maxSide * zoomFactor

	if isNotify then
		camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, distance), cf.Position)
	else
		camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(distance, distance/2, distance), cf.Position)
	end

	if not isCollected then
		for _, item in clone:GetDescendants() do
			if item:IsA("BasePart") then
				item.Color = Color3.new(0, 0, 0)
				item.Material = Enum.Material.SmoothPlastic
				if item:IsA("MeshPart") then item.TextureID = "" end
			elseif item:IsA("SpecialMesh") then
				item.TextureId = ""
				item.VertexColor = Vector3.new(0, 0, 0)
			elseif item:IsA("Decal") or item:IsA("Texture") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("SurfaceAppearance") then
				item:Destroy()
			elseif item:IsA("ParticleEmitter") or item:IsA("Light") or item:IsA("Beam") or item:IsA("Trail") then
				item:Destroy()
			end
		end
	else
		spinningModels[viewport] = {Clone = clone, Center = cf.Position, Dist = distance, IsNotify = isNotify}
	end
	return viewport
end

local function showCollectionEffect(name, rarity)
	isShowingNow = true
	activeNotifyRarity = rarity

	local modelTemplate = BrainrotStorage:FindFirstChild(name)
	if modelTemplate then
		createViewport(modelTemplate, notifyViewport, true)
	end

	notifyLine1.Text = "YOU FOUND"
	notifyLine2.Text = string.upper(name)
	notifyLine2Shadow.Text = string.upper(name)
	notifyLine3.Text = string.upper(rarity)

	if rarity ~= "Brainrot God" and rarity ~= "Secret" then
		notifyLine3.TextColor3 = RarityColors[rarity] or Color3.new(1, 1, 1)
	end

	for i = 1, 0, -0.1 do
		notifyLine1.TextTransparency = i
		notifyLine1.TextStrokeTransparency = i
		notifyLine2.TextTransparency = i
		notifyLine2.TextStrokeTransparency = i
		notifyLine2Shadow.TextTransparency = (i + 0.5 > 1) and 1 or (i + 0.5) 
		notifyLine3.TextTransparency = i
		notifyLine3.TextStrokeTransparency = i
		notifyViewport.ImageTransparency = i
		task.wait(0.05)
	end

	task.wait(3)

	for i = 0, 1, 0.1 do
		notifyLine1.TextTransparency = i
		notifyLine1.TextStrokeTransparency = i
		notifyLine2.TextTransparency = i
		notifyLine2.TextStrokeTransparency = i
		notifyLine2Shadow.TextTransparency = i
		notifyLine3.TextTransparency = i
		notifyLine3.TextStrokeTransparency = i
		notifyViewport.ImageTransparency = i
		task.wait(0.05)
	end

	spinningModels[notifyViewport] = nil 
	notifyViewport:ClearAllChildren()
	activeNotifyRarity = ""
	isShowingNow = false 
end

task.spawn(function()
	while true do
		if #notificationQueue > 0 and not isShowingNow then
			local nextNotify = table.remove(notificationQueue, 1)
			showCollectionEffect(nextNotify.name, nextNotify.rarity)
		end
		task.wait(0.1)
	end
end)

local function makeNonCollidable(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function discoverBrainrots()
	local brainrots = {}
	if BrainrotyFolder then
		for _, model in BrainrotyFolder:GetChildren() do
			if model:IsA("Model") then
				table.insert(brainrots, model)
				makeNonCollidable(model)
			end
		end
	end
	return brainrots
end

local brainrots = discoverBrainrots()

-- PRZYCISK OTWIERANIA
-- === NOWA SEKACJA: GŁÓWNY PRZYCISK INDEX (PRAWA STRONA) ===

local indexGlow = Instance.new("ImageLabel")
indexGlow.Name = "IndexGlow"
indexGlow.Visible = false
indexGlow.Parent = screenGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Position = HudTileStyle.getSlot("right", 1)
openButton.Text = ""
openButton.ZIndex = 11
openButton.Parent = screenGui

local indexImg = Instance.new("ImageLabel")
indexImg.Name = "IndexIcon"
indexImg.Image = HudTileStyle.getImage(ReplicatedStorage, "Index", "rbxassetid://72256385")
indexImg.Parent = openButton

local indexText = Instance.new("TextLabel")
indexText.Text = "INDEX"
indexText.Parent = openButton

HudTileStyle.apply(openButton, indexImg, indexText, {
	side = "right",
	slotIndex = 1,
	zIndex = 11,
})

-- RAMKA INDEKSU
local indexFrame = Instance.new("ScrollingFrame")
indexFrame.Name = "IndexFrame"
indexFrame.Size = UDim2.fromScale(0.85, 0.85)
indexFrame.Position = UDim2.fromScale(0.5, 0.5)
indexFrame.AnchorPoint = Vector2.new(0.5, 0.5)
indexFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
indexFrame.BorderSizePixel = 0
indexFrame.ScrollBarThickness = 8
indexFrame.Visible = false
indexFrame.Parent = screenGui
indexFrame.ZIndex = 50
indexFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

-- PASEK POSTĘPU (W INDEKSIE)
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.BackgroundTransparency = 1 -- Całkowicie przezroczysty
progressContainer.Visible = false -- I tak go nie chcemy widzieć
progressContainer.Size = UDim2.new(0.85, 0, 0, 60)
progressContainer.Position = UDim2.new(0.5, 0, 0.5 + (0.85/2), 15)
progressContainer.AnchorPoint = Vector2.new(0.5, 0)
progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
progressContainer.Visible = false
progressContainer.Parent = screenGui

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 8)
progressCorner.Parent = progressContainer

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.fromScale(0, 1)
progressBar.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressContainer
progressBar.Transparency = 1

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 8)
barCorner.Parent = progressBar

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "ProgressLabel"
progressLabel.Size = UDim2.fromScale(1, 1)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "COLLECTED: 0 / 0"
progressLabel.TextColor3 = Color3.new(1, 1, 1)
progressLabel.Font = Enum.Font.SourceSansBold
progressLabel.TextSize = 0
progressLabel.TextStrokeTransparency = 0
progressLabel.ZIndex = 2
progressLabel.Parent = progressContainer


-- GŁÓWNY TYTUŁ NA DOLE
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.85, 0, 0, 80) 
titleLabel.Position = UDim2.new(0.5, 0, 0.935, 0) -- Pozycja na dole
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BRAINROT INDEX"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.LuckiestGuy -- Gruba czcionka
titleLabel.TextSize = 80 
titleLabel.Visible = false
titleLabel.ZIndex = 55
titleLabel.Parent = screenGui
Instance.new("UIStroke", titleLabel).Thickness = 4

-- PRZYCISK X
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(80, 80)
closeButton.Position = UDim2.new(0.5 + (0.85/2), 0, 0.5 - (0.85/2), 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 45
closeButton.Visible = false
closeButton.ZIndex = 55
closeButton.Parent = screenGui

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local layout = Instance.new("UIGridLayout")
layout.CellPadding = UDim2.fromOffset(15, 15)
layout.CellSize = UDim2.fromOffset(260, 380)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.Name
layout.Parent = indexFrame

local function updateProgressBar()
	local total = 0
	local collected = 0

	-- 1. Liczenie postępu
	for _, item in BrainrotStorage:GetChildren() do
		if item:IsA("Model") then
			total = total + 1
			if collectedBrainrots[item.Name] then
				collected = collected + 1
			end
		end
	end

	-- 2. UKRYWANIE MODELI NA MAPIE (Standardowa logika)
	if BrainrotyFolder then
		for _, modelNaMapie in ipairs(BrainrotyFolder:GetChildren()) do
			if modelNaMapie:IsA("Model") and collectedBrainrots[modelNaMapie.Name] then
				for _, part in ipairs(modelNaMapie:GetDescendants()) do
					if part:IsA("BasePart") then
						if part.Transparency < 1 then
							part.Transparency = 0.8
						end
						part.CanCollide = false
					end
				end
			end
		end
	end

	-- 3. Aktualizacja pasków i tekstów
	local percentage = (total > 0) and (collected / total) or 0

	topProgressLabel.Text = "BRAINROT PROGRESS: " .. collected .. " / " .. total
	topProgressFill:TweenSize(UDim2.fromScale(percentage, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)

	progressLabel.Text = "COLLECTED: " .. collected .. " / " .. total
	progressBar:TweenSize(UDim2.fromScale(percentage, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
end

local function isRarityFinished(rarityName)
	local totalInRarity = 0
	local collectedInRarity = 0

	-- Zamieniamy na duże litery, żeby uniknąć błędów w pisowni
	local targetRarity = string.upper(rarityName)

	for _, item in ipairs(BrainrotStorage:GetChildren()) do
		if item:IsA("Model") then
			local itemRarity = item:GetAttribute("Rarity") or "Common"

			if string.upper(itemRarity) == targetRarity then
				totalInRarity = totalInRarity + 1
				if collectedBrainrots[item.Name] then
					collectedInRarity = collectedInRarity + 1
				end
			end
		end
	end

	-- Jeśli kategoria jest pusta w Storage, nie blokujemy
	if totalInRarity == 0 then return false end

	-- Zwraca true, jeśli mamy komplet
	return collectedInRarity >= totalInRarity
end

local function refreshIndex()
	-- Zamiast czyścić całą tabelę, usuwamy z niej tylko te modele, które NIE są powiadomieniami
	for viewport, data in pairs(spinningModels) do
		if not data.IsNotify then
			spinningModels[viewport] = nil
		end
	end
	for _, child in indexFrame:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, wzorzec in BrainrotStorage:GetChildren() do
		if not wzorzec:IsA("Model") then continue end

		local rarity = wzorzec:GetAttribute("Rarity") or "Common"
		local order = RarityOrder[rarity] or 9 

		local itemFrame = Instance.new("Frame")
		itemFrame.Name = order .. "_" .. wzorzec.Name
		itemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		itemFrame.BorderSizePixel = 4
		itemFrame.BorderMode = Enum.BorderMode.Inset
		itemFrame.BorderColor3 = RarityColors[rarity] or Color3.new(1, 1, 1)
		itemFrame.ZIndex = 51 -- O 1 wyżej niż główna ramka
		itemFrame.Parent = indexFrame

		local isCollected = collectedBrainrots[wzorzec.Name]
		createViewport(wzorzec, itemFrame, isCollected)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -10, 0, 40)
		nameLabel.Position = UDim2.new(0, 5, 0, 320)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = isCollected and wzorzec.Name or "???"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 28
		nameLabel.ZIndex = 52
		nameLabel.TextScaled = true
		nameLabel.Parent = itemFrame

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Name = "RarityLabel"
		rarityLabel.Size = UDim2.new(1, -10, 0, 25)
		rarityLabel.Position = UDim2.new(0, 5, 0, 300)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = string.upper(rarity)
		rarityLabel.TextColor3 = RarityColors[rarity] or Color3.new(1, 1, 1)
		rarityLabel.Font = Enum.Font.SourceSansBold
		rarityLabel.ZIndex = 52
		rarityLabel.TextSize = 24
		rarityLabel.Parent = itemFrame
		
		-- === SYSTEM PETÓW (Przycisk Equip) ===
		if isCollected then
			local function getActivePetName()
				if not character then return nil end
				local pet = workspace:FindFirstChild(player.Name .. "_ActivePet")
				return pet and pet:GetAttribute("PetName")
			end
			
			local isEquipped = (getActivePetName() == wzorzec.Name)
			
			local equipBtn = Instance.new("TextButton")
			equipBtn.Name = "EquipButton"
			equipBtn.Size = UDim2.new(1, -10, 0, 40) -- Taki sam rozmiar jak NameLabel
			equipBtn.Position = UDim2.new(0, 5, 0, 320) -- Pozycja NameLabel
			equipBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(0, 100, 200)
			equipBtn.Text = isEquipped and "UNEQUIP PET" or "EQUIP PET"
			equipBtn.TextColor3 = Color3.new(1, 1, 1)
			equipBtn.Font = Enum.Font.FredokaOne
			equipBtn.TextSize = 18
			equipBtn.ZIndex = 55
			equipBtn.Visible = false -- Domyślnie ukryty do momentu najechania
			equipBtn.Parent = itemFrame
			
			Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 6)
			
			-- Zablokowanie przycisku jeśli gracz ma Rebirth 1
			local leaderstats = player:FindFirstChild("leaderstats")
			local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
			local userRebirths = (rebirths and rebirths.Value) or 0
			
			if userRebirths < 1 then
				equipBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				equipBtn.Text = "REQUIRES REBIRTH"
				equipBtn.AutoButtonColor = false
			else
				equipBtn.MouseButton1Click:Connect(function()
					if not TogglePetEvent then return end
					equipBtn.Text = "..."
					
					local success, response, reqLvl = TogglePetEvent:InvokeServer(wzorzec.Name)
					
					if success then
						equipBtn.Text = response
						task.wait(0.2)
						refreshIndex()
					else
						-- Błąd (Teraz czyta PRAWIDŁOWY powód z serwera!)
						equipBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
						equipBtn.Text = string.upper(response) -- Używamy prawdziwego powodu
						task.wait(2)
						equipBtn.BackgroundColor3 = (getActivePetName() == wzorzec.Name) and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(0, 100, 200)
						equipBtn.Text = (getActivePetName() == wzorzec.Name) and "UNEQUIP PET" or "EQUIP PET"
					end
				end)
			end
			
			-- Obsługa najechania myszką (Hover)
			itemFrame.MouseEnter:Connect(function()
				nameLabel.Visible = false
				equipBtn.Visible = true
			end)
			
			itemFrame.MouseLeave:Connect(function()
				equipBtn.Visible = false
				nameLabel.Visible = true
			end)
		end
	end
	updateProgressBar()
end

local function toggleUI(visible)
	indexFrame.Visible = visible
	titleLabel.Visible = visible
	closeButton.Visible = visible
	progressContainer.Visible = visible
	
	-- Ukrywamy HUD (monety), by nie zaśmiecał ekranu przy Indeksie
	local hudGui = playerGui:FindFirstChild("HUD_Standalone_UI")
	if hudGui then hudGui.Enabled = not visible end
	
	if visible then refreshIndex() end
end

local function collectBrainrot(model)
	if collectedBrainrots[model.Name] then return end
	_G.LastCollectTick = tick()
	collectedBrainrots[model.Name] = true
	

	if CollectSound then
		CollectSound:Play()
	end

	local rarity = model:GetAttribute("Rarity") or "Common"
	table.insert(notificationQueue, {name = model.Name, rarity = rarity})

	BrainrotCollectedEvent:FireServer(model.Name)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Transparency < 1 then
				part.Transparency = 0.9
			end
		end
	end
	updateProgressBar()
end

local function checkTouches()
	local currentCharacter = player.Character
	if not currentCharacter then return end
	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	for _, model in ipairs(brainrots) do
		if model and model.Parent and not collectedBrainrots[model.Name] then
			local targetPosition = nil
			local priorityPart = model:FindFirstChild("Hitbox") or model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart")

			if priorityPart then
				targetPosition = priorityPart.Position
			else
				local cf, size = model:GetBoundingBox()
				targetPosition = cf.Position
			end

			if targetPosition and (targetPosition - rootPart.Position).Magnitude < 6 then
				collectBrainrot(model)
			end
		end
	end
end

openButton.MouseButton1Click:Connect(function()
	toggleUI(not indexFrame.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
	toggleUI(false)
end)

RunService.RenderStepped:Connect(function()
	-- Wklej to wewnątrz RunService.RenderStepped:Connect(function()

	local t = tick()
	local rainbow = Color3.fromHSV(t % 3 / 3, 1, 1)

	indexText.TextColor3 = HudTileStyle.BaseLabelColor
	titleLabel.TextColor3 = rainbow
	stripes.Position = UDim2.new(0, -(t * 60) % 60, 0, 0)

	if activeNotifyRarity == "Brainrot God" then
		notifyLine3.TextColor3 = Color3.fromHSV(t % 3 / 3, 1, 1)
	elseif activeNotifyRarity == "Secret" then
		local shine = (math.sin(t * 5) + 1) / 2
		notifyLine3.TextColor3 = Color3.new(shine, shine, shine)
	end

	for viewport, data in pairs(spinningModels) do
		if viewport and viewport.Parent then
			local angle = t * 1.5 
			local x = math.cos(angle) * data.Dist
			local z = math.sin(angle) * data.Dist
			local yOffset = data.IsNotify and 0 or data.Dist/2
			viewport.CurrentCamera.CFrame = CFrame.lookAt(data.Center + Vector3.new(x, yOffset, z), data.Center)
		end
	end

	if indexFrame.Visible then
		for _, frame in pairs(indexFrame:GetChildren()) do
			if frame:IsA("Frame") then
				if string.sub(frame.Name, 1, 2) == "6_" then
					local rainbow = Color3.fromHSV(t % 3 / 3, 1, 1)
					frame.BorderColor3 = rainbow
					if frame:FindFirstChild("RarityLabel") then frame.RarityLabel.TextColor3 = rainbow end
				elseif string.sub(frame.Name, 1, 2) == "7_" then
					local shine = (math.sin(t * 3) + 1) / 2 
					local silver = Color3.new(shine, shine, shine)
					frame.BorderColor3 = silver
					if frame:FindFirstChild("RarityLabel") then frame.RarityLabel.TextColor3 = silver end
				end
			end
		end
	end

	-- === KROK 3: ANIMACJA SREBRA I TĘCZY NA KLIENCIE ===
	local rainbow = Color3.fromHSV((t % 3) / 3, 1, 1)
	local silverPulse = (math.sin(t * 3) + 1) / 2
	local silverColor = Color3.new(silverPulse, silverPulse, silverPulse)
	
	for _, p in ipairs(game.Players:GetPlayers()) do
		if p.Character then
			local aura = p.Character:FindFirstChild("RebirthAura")
			local stats = p:FindFirstChild("leaderstats")
			if aura and stats and stats:FindFirstChild("Rebirths") then
				local rb = stats.Rebirths.Value
				if rb == 1 then
					-- Poziom 1: Stały Zielony
					aura.FillColor = Color3.fromRGB(0, 255, 0)
					aura.OutlineColor = Color3.fromRGB(0, 255, 0)
				elseif rb == 2 then
					-- Poziom 2: Stały Złoty
					aura.FillColor = Color3.fromRGB(255, 215, 0)
					aura.OutlineColor = Color3.fromRGB(255, 215, 0)
				elseif rb == 3 then
					aura.FillColor = silverColor
					aura.OutlineColor = silverColor
				elseif rb >= 4 then
					aura.FillColor = rainbow
					aura.OutlineColor = rainbow
				end
			end
		end
	end
	-- === KROK 4: PŁYNNE PODĄŻANIE PETÓW (ZOPTYMALIZOWANE) ===
	local activePetsFolder = Workspace:FindFirstChild("ActivePets")
	if activePetsFolder then
		for _, pet in ipairs(activePetsFolder:GetChildren()) do
			local ownerId = pet:GetAttribute("OwnerUserId")
			if ownerId then
				local owner = Players:GetPlayerByUserId(ownerId)
				if owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = owner.Character.HumanoidRootPart
					local targetCF = hrp.CFrame * CFrame.new(2.5, -1.8, 7.0)
					
					-- Lerp na kliencie
					pet:PivotTo(pet:GetPivot():Lerp(targetCF, 0.15))
				end
			end
		end
	end
end)

-- === DODANE NASŁUCHIWANIE NA RESET (REBIRTH) ===
local RebirthEffect = BrainrotEvents:WaitForChild("RebirthEffect")
RebirthEffect.OnClientEvent:Connect(function()
	print("!!! CLIENT: REBIRTH - FORCING BAR RESET !!!")
	
	-- NIE CZYŚCIMY TABELI TUTAJ! Pozwalamy ChildRemoved (linijka 793) 
	-- zrobić to model po modelu, żeby przywrócić ich widoczność na mapie.
	
	if updateProgressBar then
		updateProgressBar()
	end
end)

task.spawn(function()
	local collection = player:WaitForChild("BrainrotCollection")
	collection.ChildRemoved:Connect(function(child)
		if collectedBrainrots[child.Name] then
			collectedBrainrots[child.Name] = nil
			-- Reset modelu na mapie do stanu z BrainrotStorage (BEZPIECZNA METODA)
			if BrainrotyFolder and BrainrotStorage then
				local storageModel = BrainrotStorage:FindFirstChild(child.Name)
				local mapModel = BrainrotyFolder:FindFirstChild(child.Name)
				
				if storageModel and mapModel then
					for _, storagePart in ipairs(storageModel:GetDescendants()) do
						if storagePart:IsA("BasePart") then
							local mapPath = mapModel:GetDescendants()
							for _, mapPart in ipairs(mapPath) do
								if mapPart.Name == storagePart.Name and mapPart:IsA("BasePart") then
									mapPart.Transparency = storagePart.Transparency
								end
							end
						end
					end
				end
			end
			-- Opóźniona aktualizacja, by suwak na górze gładko spadł na 0
			task.delay(0.1, function()
				updateProgressBar()
			end)
		end
	end)
end)

-- === SYNCHRONIZACJA STARTOWA (Bezpieczna) ===
task.spawn(function()
	local collection = player:WaitForChild("BrainrotCollection", 10)
	if collection then
		for _, child in ipairs(collection:GetChildren()) do
			collectedBrainrots[child.Name] = true
		end
		updateProgressBar()
	end
end)

task.spawn(function()
	while true do
		checkTouches()
		task.wait(0.2)
	end
end)

-- ========================================================
-- OBSŁUGA SYGNAŁU Z SERWERA (TERAZ ZE SKRZYNIĄ)
-- ========================================================
BrainrotCollectedEvent.OnClientEvent:Connect(function(name)

	if name == "PLAY_ANIM" then
		return -- Ignorujemy to całkowicie! PurchaseAnimationScript się tym zajmie.
	end

	if collectedBrainrots[name] then return end

	local modelTemplate = BrainrotStorage:FindFirstChild(name)
	local rarity = "Common" -- Domyślna wartość, żeby się nie wywaliło

	if modelTemplate then
		rarity = modelTemplate:GetAttribute("Rarity") or "Common"
		collectedBrainrots[name] = true
	else
		-- Jeśli nie ma modelu w Storage, nadal chcemy pokazać napis, żeby nie było błędu
		-- Model nie znaleziony w Storage
	end

	-- ZABEZPIECZENIE: Jeśli z jakiegoś powodu rarity to nil, dajemy tekst
	local safeName = tostring(name) or "UNKNOWN"
	local safeRarity = tostring(rarity) or "COMMON"

	task.delay(1.2, function()
		if CollectSound then CollectSound:Play() end
		-- Dodajemy do kolejki powiadomień
		table.insert(notificationQueue, {name = safeName, rarity = safeRarity})

		updateProgressBar()
		if indexFrame.Visible then refreshIndex() end
	end)
end)

-- === EVENT ROBUX PROGRESS BAR ===
local robuxContainer = Instance.new("Frame")
robuxContainer.Name = "RobuxProgressContainer"
robuxContainer.Size = UDim2.new(0.3, 0, 0, 30) -- Mniejszy niż główny
robuxContainer.Position = UDim2.new(0.5, 0, 0, 20) -- Nad głównym paskiem (był na 90)
robuxContainer.AnchorPoint = Vector2.new(0.5, 0)
robuxContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
robuxContainer.BorderSizePixel = 0
robuxContainer.Parent = screenGui

Instance.new("UICorner", robuxContainer).CornerRadius = UDim.new(0.5, 0)
local robuxStroke = Instance.new("UIStroke", robuxContainer)
robuxStroke.Thickness = 2
robuxStroke.Color = Color3.fromRGB(255, 215, 0) -- Złoty obrys

local robuxFill = Instance.new("Frame", robuxContainer)
robuxFill.Size = UDim2.fromScale(0, 1)
robuxFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
Instance.new("UICorner", robuxFill).CornerRadius = UDim.new(0.5, 0)

local robuxLabel = Instance.new("TextLabel", robuxContainer)
robuxLabel.Size = UDim2.fromScale(1, 1)
robuxLabel.BackgroundTransparency = 1
robuxLabel.Text = "COIN RAIN PROGRESS: 0 / 1000 R$"
robuxLabel.TextColor3 = Color3.new(1, 1, 1)
robuxLabel.Font = Enum.Font.SourceSansBold
robuxLabel.TextSize = 20
robuxLabel.ZIndex = 5

local PoolUpdated = BrainrotEvents:WaitForChild("PoolUpdated")

PoolUpdated.OnClientEvent:Connect(function(currentPool, queuedCount)
    local maxPool = GameConfig.CoinRainTriggerAmount or 1000 
    local percentage = math.clamp(currentPool / maxPool, 0, 1)
    
    -- ZAWSZE AKTUALIZUJEMY (Zgodnie z życzeniem: "ma się pasek aktualizować ciągle")
    robuxLabel.Text = "COIN RAIN PROGRESS: " .. currentPool .. " / " .. maxPool .. " R$"
    TweenService:Create(robuxFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(percentage, 1)}):Play()
end)
