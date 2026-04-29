local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService") -- Potrzebne do animacji
local AvatarEditorService = game:GetService("AvatarEditorService")
local GuiService = game:GetService("GuiService")

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
local OgBrainrotDiscoveryAnnouncement = BrainrotEvents:WaitForChild("OgBrainrotDiscoveryAnnouncement")
local TogglePetEvent = BrainrotEvents:WaitForChild("TogglePetEvent")
local MarkExperienceFavoritedEvent = BrainrotEvents:WaitForChild("MarkExperienceFavorited")
local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage") 
local BrainrotyFolder = Workspace:WaitForChild("Brainroty") 
local GreenStudsTexture = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")
local CLIENT_COLLECT_DISTANCE = GameConfig.ClientCollectDistance or 6
local currentBrainrotCollected = 0
local currentBrainrotTotal = GameConfig.TotalBrainrots or 0
local currentCoinRainPool = 0
local currentCoinRainMax = GameConfig.CoinRainTriggerAmount or 1000
local useCompactTopStatusText = false
local showMobileCoinRainSuffix = true
local useWrappedMobileCoinRainText = false

local function formatBrainrotProgressText(collected, total)
	local prefix = useCompactTopStatusText and "BRAINROT: " or "BRAINROT PROGRESS: "
	return prefix .. tostring(collected) .. " / " .. tostring(total)
end

local function formatCoinRainProgressText(currentPool, maxPool)
	if useWrappedMobileCoinRainText then
		return "COIN RAIN\nPROGRESS: " .. tostring(currentPool) .. "/" .. tostring(maxPool) .. " " .. utf8.char(0xE002)
	end

	local prefix = useCompactTopStatusText and "COIN RAIN: " or "COIN RAIN PROGRESS: "
	local suffix = showMobileCoinRainSuffix and (" " .. utf8.char(0xE002)) or ""
	return prefix .. tostring(currentPool) .. " / " .. tostring(maxPool) .. suffix
end

local CollectSound = SoundService:WaitForChild("CollectSound")
CollectSound.SoundId = "rbxassetid://3150375869"

local collectedBrainrots = {}
_G.CollectedBrainrotsTable = collectedBrainrots -- Udostępniamy tabelę dla sklepu
local spinningModels = {} 

-- UI Setup
-- UI Setup
local playerGui = player:WaitForChild("PlayerGui")

-- === CZYSZCZENIE STARYCH INSTANCJI ===
local oldGui = playerGui:FindFirstChild("BrainrotIndexUI")
if oldGui then oldGui:Destroy() end

local oldToggle = playerGui:FindFirstChild("BrainrotIndexToggleUI")
if oldToggle then oldToggle:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Name = "BrainrotIndexUI"
screenGui.DisplayOrder = 540
screenGui.IgnoreGuiInset = true -- Pozwala na precyzyjne sterowanie szczytem ekranu
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "BrainrotIndexToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = playerGui

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
topProgressLabel.Text = formatBrainrotProgressText(0, currentBrainrotTotal)
topProgressLabel.TextColor3 = Color3.new(1, 1, 1)
topProgressLabel.Font = Enum.Font.SourceSansBold
topProgressLabel.TextSize = 26
topProgressLabel.TextScaled = true
topProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
topProgressLabel.ZIndex = 5
topProgressLabel.Parent = topProgressContainer

local topProgressTextConstraint = Instance.new("UITextSizeConstraint")
topProgressTextConstraint.MinTextSize = 9
topProgressTextConstraint.MaxTextSize = 22
topProgressTextConstraint.Parent = topProgressLabel

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

local notifyLine1Constraint = Instance.new("UITextSizeConstraint")
notifyLine1Constraint.MinTextSize = 14
notifyLine1Constraint.MaxTextSize = 40
notifyLine1Constraint.Parent = notifyLine1

local notifyLine2Constraint = Instance.new("UITextSizeConstraint")
notifyLine2Constraint.MinTextSize = 18
notifyLine2Constraint.MaxTextSize = 85
notifyLine2Constraint.Parent = notifyLine2

local notifyLine2ShadowConstraint = Instance.new("UITextSizeConstraint")
notifyLine2ShadowConstraint.MinTextSize = 18
notifyLine2ShadowConstraint.MaxTextSize = 85
notifyLine2ShadowConstraint.Parent = notifyLine2Shadow

local notifyLine3Constraint = Instance.new("UITextSizeConstraint")
notifyLine3Constraint.MinTextSize = 16
notifyLine3Constraint.MaxTextSize = 65
notifyLine3Constraint.Parent = notifyLine3

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

local function applyCollectionNotifyLayout()
	local metrics = HudTileStyle.getLayoutMetrics()
	local viewport = metrics.Viewport or Vector2.new(1280, 720)
	local isMobile = metrics.IsMobile
	local isLandscapeMobile = metrics.IsLandscapeMobile

	if isLandscapeMobile then
		local centerX = math.floor(viewport.X * 0.5 + 0.5)
		local baseY = math.floor(metrics.TopSafe + 8 + 0.5)
		local titleWidth = math.clamp(math.floor(viewport.X * 0.62 + 0.5), 210, 340)
		local nameWidth = math.clamp(math.floor(viewport.X * 0.86 + 0.5), 300, 520)
		local rarityWidth = math.clamp(math.floor(viewport.X * 0.54 + 0.5), 180, 300)
		local viewportSize = math.clamp(math.floor(viewport.Y * 0.58 + 0.5), 180, 220)

		notifyLine1.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine1.Position = UDim2.fromOffset(centerX, baseY)
		notifyLine1.Size = UDim2.fromOffset(titleWidth, 24)
		notifyLine1.TextScaled = true
		notifyLine1.TextWrapped = false
		notifyLine1.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine1.TextSize = 24
		notifyLine1Constraint.MinTextSize = 12
		notifyLine1Constraint.MaxTextSize = 24

		notifyLine2Shadow.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine2Shadow.Position = UDim2.fromOffset(centerX, baseY + 31)
		notifyLine2Shadow.Size = UDim2.fromOffset(nameWidth, 56)
		notifyLine2Shadow.TextScaled = true
		notifyLine2Shadow.TextWrapped = true
		notifyLine2Shadow.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine2Shadow.TextYAlignment = Enum.TextYAlignment.Center
		notifyLine2Shadow.TextSize = 42
		notifyLine2ShadowConstraint.MinTextSize = 18
		notifyLine2ShadowConstraint.MaxTextSize = 42

		notifyLine2.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine2.Position = UDim2.fromOffset(centerX, baseY + 28)
		notifyLine2.Size = UDim2.fromOffset(nameWidth, 56)
		notifyLine2.TextScaled = true
		notifyLine2.TextWrapped = true
		notifyLine2.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine2.TextYAlignment = Enum.TextYAlignment.Center
		notifyLine2.TextSize = 42
		notifyLine2Constraint.MinTextSize = 18
		notifyLine2Constraint.MaxTextSize = 42

		notifyLine3.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine3.Position = UDim2.fromOffset(centerX, baseY + 90)
		notifyLine3.Size = UDim2.fromOffset(rarityWidth, 28)
		notifyLine3.TextScaled = true
		notifyLine3.TextWrapped = false
		notifyLine3.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine3.TextSize = 28
		notifyLine3Constraint.MinTextSize = 14
		notifyLine3Constraint.MaxTextSize = 28

		notifyViewport.Size = UDim2.fromOffset(viewportSize, viewportSize)
		notifyViewport.Position = UDim2.fromOffset(centerX, math.floor(viewport.Y * 0.67 + 0.5))
	elseif isMobile then
		local centerX = math.floor(viewport.X * 0.5 + 0.5)
		local baseY = math.floor(metrics.TopSafe + 16 + 0.5)
		local titleWidth = math.clamp(math.floor(viewport.X * 0.76 + 0.5), 220, 380)
		local nameWidth = math.clamp(math.floor(viewport.X * 0.90 + 0.5), 280, 500)
		local rarityWidth = math.clamp(math.floor(viewport.X * 0.64 + 0.5), 180, 320)
		local viewportSize = math.clamp(math.floor(viewport.X * 0.70 + 0.5), 200, 280)

		notifyLine1.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine1.Position = UDim2.fromOffset(centerX, baseY)
		notifyLine1.Size = UDim2.fromOffset(titleWidth, 30)
		notifyLine1.TextScaled = true
		notifyLine1.TextWrapped = false
		notifyLine1.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine1.TextSize = 30
		notifyLine1Constraint.MinTextSize = 14
		notifyLine1Constraint.MaxTextSize = 30

		notifyLine2Shadow.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine2Shadow.Position = UDim2.fromOffset(centerX, baseY + 39)
		notifyLine2Shadow.Size = UDim2.fromOffset(nameWidth, 72)
		notifyLine2Shadow.TextScaled = true
		notifyLine2Shadow.TextWrapped = true
		notifyLine2Shadow.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine2Shadow.TextYAlignment = Enum.TextYAlignment.Center
		notifyLine2Shadow.TextSize = 48
		notifyLine2ShadowConstraint.MinTextSize = 20
		notifyLine2ShadowConstraint.MaxTextSize = 48

		notifyLine2.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine2.Position = UDim2.fromOffset(centerX, baseY + 34)
		notifyLine2.Size = UDim2.fromOffset(nameWidth, 72)
		notifyLine2.TextScaled = true
		notifyLine2.TextWrapped = true
		notifyLine2.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine2.TextYAlignment = Enum.TextYAlignment.Center
		notifyLine2.TextSize = 48
		notifyLine2Constraint.MinTextSize = 20
		notifyLine2Constraint.MaxTextSize = 48

		notifyLine3.AnchorPoint = Vector2.new(0.5, 0)
		notifyLine3.Position = UDim2.fromOffset(centerX, baseY + 114)
		notifyLine3.Size = UDim2.fromOffset(rarityWidth, 34)
		notifyLine3.TextScaled = true
		notifyLine3.TextWrapped = false
		notifyLine3.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine3.TextSize = 32
		notifyLine3Constraint.MinTextSize = 16
		notifyLine3Constraint.MaxTextSize = 32

		notifyViewport.Size = UDim2.fromOffset(viewportSize, viewportSize)
		notifyViewport.Position = UDim2.fromOffset(centerX, math.floor(viewport.Y * 0.7 + 0.5))
	else
		notifyLine1.AnchorPoint = Vector2.new(0, 0)
		notifyLine1.Position = UDim2.new(0, 0, 0, 110)
		notifyLine1.Size = UDim2.new(1, 0, 0, 40)
		notifyLine1.TextScaled = false
		notifyLine1.TextWrapped = false
		notifyLine1.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine1.TextSize = 40
		notifyLine1Constraint.MinTextSize = 14
		notifyLine1Constraint.MaxTextSize = 40

		notifyLine2Shadow.AnchorPoint = Vector2.new(0, 0)
		notifyLine2Shadow.Position = UDim2.new(0, 0, 0, 164)
		notifyLine2Shadow.Size = UDim2.new(1, 0, 0, 80)
		notifyLine2Shadow.TextScaled = false
		notifyLine2Shadow.TextWrapped = false
		notifyLine2Shadow.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine2Shadow.TextYAlignment = Enum.TextYAlignment.Center
		notifyLine2Shadow.TextSize = 85
		notifyLine2ShadowConstraint.MinTextSize = 18
		notifyLine2ShadowConstraint.MaxTextSize = 85

		notifyLine2.AnchorPoint = Vector2.new(0, 0)
		notifyLine2.Position = UDim2.new(0, 0, 0, 160)
		notifyLine2.Size = UDim2.new(1, 0, 0, 80)
		notifyLine2.TextScaled = false
		notifyLine2.TextWrapped = false
		notifyLine2.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine2.TextYAlignment = Enum.TextYAlignment.Center
		notifyLine2.TextSize = 85
		notifyLine2Constraint.MinTextSize = 18
		notifyLine2Constraint.MaxTextSize = 85

		notifyLine3.AnchorPoint = Vector2.new(0, 0)
		notifyLine3.Position = UDim2.new(0, 0, 0, 225)
		notifyLine3.Size = UDim2.new(1, 0, 0, 75)
		notifyLine3.TextScaled = false
		notifyLine3.TextWrapped = false
		notifyLine3.TextXAlignment = Enum.TextXAlignment.Center
		notifyLine3.TextSize = 65
		notifyLine3Constraint.MinTextSize = 16
		notifyLine3Constraint.MaxTextSize = 65

		notifyViewport.Size = UDim2.new(0, 750, 0, 750)
		notifyViewport.Position = UDim2.new(0.5, 0, 0.45, 100)
	end
end

local function getCollectionNotifyViewportOptions()
	local metrics = HudTileStyle.getLayoutMetrics()
	if metrics.IsLandscapeMobile then
		return {distanceMultiplier = 1.18}
	elseif metrics.IsMobile then
		return {distanceMultiplier = 1.12}
	end
	return nil
end

local function bindCollectionNotifyLayout()
	local function bindCamera(camera)
		if not camera then
			return
		end
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyCollectionNotifyLayout)
	end

	bindCamera(Workspace.CurrentCamera)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera(Workspace.CurrentCamera)
		task.defer(applyCollectionNotifyLayout)
	end)
end

applyCollectionNotifyLayout()
bindCollectionNotifyLayout()

local globalAnnouncementOverlay = Instance.new("Frame")
globalAnnouncementOverlay.Name = "GlobalAnnouncementOverlay"
globalAnnouncementOverlay.Size = UDim2.fromScale(1, 1)
globalAnnouncementOverlay.BackgroundColor3 = Color3.fromRGB(6, 10, 18)
globalAnnouncementOverlay.BackgroundTransparency = 1
globalAnnouncementOverlay.Visible = false
globalAnnouncementOverlay.ZIndex = 260
globalAnnouncementOverlay.Parent = screenGui

local overlayGlow = Instance.new("ImageLabel")
overlayGlow.Name = "OverlayGlow"
overlayGlow.AnchorPoint = Vector2.new(0.5, 0.5)
overlayGlow.Position = UDim2.fromScale(0.5, 0.12)
overlayGlow.Size = UDim2.fromOffset(1200, 420)
overlayGlow.BackgroundTransparency = 1
overlayGlow.Image = "rbxassetid://4996891970"
overlayGlow.ImageColor3 = Color3.fromRGB(0, 255, 221)
overlayGlow.ImageTransparency = 1
overlayGlow.ZIndex = 261
overlayGlow.Parent = globalAnnouncementOverlay

local topBeam = Instance.new("Frame")
topBeam.Name = "TopBeam"
topBeam.AnchorPoint = Vector2.new(0.5, 0)
topBeam.Position = UDim2.fromScale(0.5, 0.03)
topBeam.Size = UDim2.new(0.76, 0, 0, 6)
topBeam.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
topBeam.BackgroundTransparency = 1
topBeam.BorderSizePixel = 0
topBeam.ZIndex = 262
topBeam.Parent = globalAnnouncementOverlay
Instance.new("UICorner", topBeam).CornerRadius = UDim.new(1, 0)

local bottomBeam = Instance.new("Frame")
bottomBeam.Name = "BottomBeam"
bottomBeam.AnchorPoint = Vector2.new(0.5, 1)
bottomBeam.Position = UDim2.fromScale(0.5, 0.25)
bottomBeam.Size = UDim2.new(0.76, 0, 0, 6)
bottomBeam.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bottomBeam.BackgroundTransparency = 1
bottomBeam.BorderSizePixel = 0
bottomBeam.ZIndex = 262
bottomBeam.Parent = globalAnnouncementOverlay
Instance.new("UICorner", bottomBeam).CornerRadius = UDim.new(1, 0)

local globalAnnouncementCard = Instance.new("Frame")
globalAnnouncementCard.Name = "GlobalAnnouncementCard"
globalAnnouncementCard.AnchorPoint = Vector2.new(0.5, 0.5)
globalAnnouncementCard.Position = UDim2.fromScale(0.5, 0.14)
globalAnnouncementCard.Size = UDim2.fromOffset(980, 220)
globalAnnouncementCard.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
globalAnnouncementCard.BackgroundTransparency = 1
globalAnnouncementCard.BorderSizePixel = 0
globalAnnouncementCard.Visible = false
globalAnnouncementCard.ZIndex = 265
globalAnnouncementCard.Parent = globalAnnouncementOverlay
Instance.new("UICorner", globalAnnouncementCard).CornerRadius = UDim.new(0, 28)

local globalCardStroke = Instance.new("UIStroke")
globalCardStroke.Thickness = 3
globalCardStroke.Transparency = 1
globalCardStroke.Color = Color3.fromRGB(0, 255, 221)
globalCardStroke.Parent = globalAnnouncementCard

local globalCardGradient = Instance.new("UIGradient")
globalCardGradient.Rotation = 18
globalCardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 16, 35)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(18, 27, 52)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 12, 24))
})
globalCardGradient.Parent = globalAnnouncementCard

local globalShine = Instance.new("Frame")
globalShine.Name = "Shine"
globalShine.AnchorPoint = Vector2.new(0.5, 0.5)
globalShine.Position = UDim2.fromScale(-0.2, 0.5)
globalShine.Size = UDim2.fromScale(0.18, 1.4)
globalShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
globalShine.BackgroundTransparency = 1
globalShine.Rotation = 18
globalShine.BorderSizePixel = 0
globalShine.ZIndex = 266
globalShine.Parent = globalAnnouncementCard

local globalShineGradient = Instance.new("UIGradient")
globalShineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.68),
	NumberSequenceKeypoint.new(1, 1)
})
globalShineGradient.Parent = globalShine

local globalAnnouncementViewportHolder = Instance.new("Frame")
globalAnnouncementViewportHolder.Name = "ViewportHolder"
globalAnnouncementViewportHolder.AnchorPoint = Vector2.new(0.5, 0.5)
globalAnnouncementViewportHolder.Position = UDim2.fromScale(0.12, 0.5)
globalAnnouncementViewportHolder.Size = UDim2.fromOffset(120, 120)
globalAnnouncementViewportHolder.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
globalAnnouncementViewportHolder.BackgroundTransparency = 0.15
globalAnnouncementViewportHolder.BorderSizePixel = 0
globalAnnouncementViewportHolder.ZIndex = 267
globalAnnouncementViewportHolder.Parent = globalAnnouncementCard
Instance.new("UICorner", globalAnnouncementViewportHolder).CornerRadius = UDim.new(1, 0)

local globalViewportStroke = Instance.new("UIStroke")
globalViewportStroke.Thickness = 4
globalViewportStroke.Transparency = 0.08
globalViewportStroke.Color = Color3.fromRGB(255, 214, 79)
globalViewportStroke.Parent = globalAnnouncementViewportHolder

local globalAnnouncementViewport = Instance.new("ViewportFrame")
globalAnnouncementViewport.Name = "GlobalAnnouncementViewport"
globalAnnouncementViewport.Size = UDim2.fromScale(1, 1)
globalAnnouncementViewport.BackgroundTransparency = 1
globalAnnouncementViewport.ImageTransparency = 1
globalAnnouncementViewport.ZIndex = 268
globalAnnouncementViewport.Parent = globalAnnouncementViewportHolder

local globalBadge = Instance.new("TextLabel")
globalBadge.Name = "Badge"
globalBadge.AnchorPoint = Vector2.new(0, 0)
globalBadge.Position = UDim2.fromScale(0.23, 0.12)
globalBadge.Size = UDim2.fromOffset(220, 34)
globalBadge.BackgroundColor3 = Color3.fromRGB(255, 214, 79)
globalBadge.BackgroundTransparency = 1
globalBadge.BorderSizePixel = 0
globalBadge.Font = Enum.Font.FredokaOne
globalBadge.Text = "GLOBAL DISCOVERY"
globalBadge.TextColor3 = Color3.fromRGB(12, 20, 33)
globalBadge.TextSize = 18
globalBadge.TextTransparency = 1
globalBadge.ZIndex = 268
globalBadge.Parent = globalAnnouncementCard
Instance.new("UICorner", globalBadge).CornerRadius = UDim.new(1, 0)

local globalTitle = Instance.new("TextLabel")
globalTitle.Name = "Title"
globalTitle.AnchorPoint = Vector2.new(0, 0)
globalTitle.Position = UDim2.fromScale(0.23, 0.3)
globalTitle.Size = UDim2.fromOffset(650, 60)
globalTitle.BackgroundTransparency = 1
globalTitle.Font = Enum.Font.FredokaOne
globalTitle.Text = "PLAYER JUST FOUND OG STRAWBERRY ELEPHANT"
globalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
globalTitle.TextSize = 34
globalTitle.TextXAlignment = Enum.TextXAlignment.Left
globalTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
globalTitle.TextStrokeTransparency = 0.3
globalTitle.TextTransparency = 1
globalTitle.ZIndex = 268
globalTitle.Parent = globalAnnouncementCard

local globalRarity = Instance.new("TextLabel")
globalRarity.Name = "Rarity"
globalRarity.AnchorPoint = Vector2.new(0, 0)
globalRarity.Position = UDim2.fromScale(0.23, 0.58)
globalRarity.Size = UDim2.fromOffset(360, 32)
globalRarity.BackgroundTransparency = 1
globalRarity.Font = Enum.Font.FredokaOne
globalRarity.Text = "OG BRAINROT FOUND"
globalRarity.TextColor3 = Color3.fromRGB(0, 255, 221)
globalRarity.TextSize = 20
globalRarity.TextXAlignment = Enum.TextXAlignment.Left
globalRarity.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
globalRarity.TextStrokeTransparency = 0.45
globalRarity.TextTransparency = 1
globalRarity.ZIndex = 268
globalRarity.Parent = globalAnnouncementCard

local globalFinder = Instance.new("TextLabel")
globalFinder.Name = "Finder"
globalFinder.AnchorPoint = Vector2.new(0, 0)
globalFinder.Position = UDim2.fromScale(0.23, 0.3)
globalFinder.Size = UDim2.fromOffset(660, 60)
globalFinder.BackgroundTransparency = 1
globalFinder.Font = Enum.Font.SourceSansBold
globalFinder.Text = "PLAYER JUST FOUND OG STRAWBERRY ELEPHANT"
globalFinder.TextColor3 = Color3.fromRGB(255, 244, 186)
globalFinder.TextSize = 34
globalFinder.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
globalFinder.TextStrokeTransparency = 0.5
globalFinder.TextTransparency = 1
globalFinder.ZIndex = 268
globalFinder.Parent = globalAnnouncementCard
globalFinder.TextXAlignment = Enum.TextXAlignment.Left

local globalSubText = Instance.new("TextLabel")
globalSubText.Name = "SubText"
globalSubText.AnchorPoint = Vector2.new(0, 0)
globalSubText.Position = UDim2.fromScale(0.23, 0.72)
globalSubText.Size = UDim2.fromOffset(520, 40)
globalSubText.BackgroundTransparency = 1
globalSubText.Font = Enum.Font.GothamMedium
globalSubText.Text = "You can still find it too!"
globalSubText.TextWrapped = true
globalSubText.TextColor3 = Color3.fromRGB(225, 236, 255)
globalSubText.TextSize = 20
globalSubText.TextTransparency = 1
globalSubText.ZIndex = 268
globalSubText.Parent = globalAnnouncementCard
globalSubText.TextXAlignment = Enum.TextXAlignment.Left

local notificationQueue = {}
local isShowingNow = false
local activeNotifyRarity = ""
local hasFavoritedExperience = player:GetAttribute("HasFavoritedExperience") == true
local hasPromptedFavorite = hasFavoritedExperience
local isCheckingFavoriteStatus = false
local globalAnnouncementQueue = {}
local isGlobalAnnouncementShowing = false
local isRebirthing = false
local isRebirthReadyQueued = false
local isRebirthReadyShowing = false
local hasShownRebirthReadyAnnouncement = false
local rebirthReadyRequestId = 0
local REBIRTH_READY_TARGET = "Strawberry Elephant"
local REBIRTH_READY_RARITY = "OG"
local REBIRTH_READY_DELAY = 4.5
local REBIRTH_READY_DURATION = 10
local rebirthReadyIconImage = "rbxassetid://72256385"

local rebirthReadyOverlay = Instance.new("Frame")
rebirthReadyOverlay.Name = "RebirthReadyOverlay"
rebirthReadyOverlay.Size = UDim2.fromScale(1, 1)
rebirthReadyOverlay.BackgroundColor3 = Color3.fromRGB(18, 11, 2)
rebirthReadyOverlay.BackgroundTransparency = 1
rebirthReadyOverlay.Visible = false
rebirthReadyOverlay.ZIndex = 270
rebirthReadyOverlay.Parent = screenGui

local rebirthOverlayGlow = Instance.new("ImageLabel")
rebirthOverlayGlow.Name = "OverlayGlow"
rebirthOverlayGlow.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthOverlayGlow.Position = UDim2.fromScale(0.5, 0.33)
rebirthOverlayGlow.Size = UDim2.fromOffset(1220, 440)
rebirthOverlayGlow.BackgroundTransparency = 1
rebirthOverlayGlow.Image = "rbxassetid://4996891970"
rebirthOverlayGlow.ImageColor3 = Color3.fromRGB(255, 211, 74)
rebirthOverlayGlow.ImageTransparency = 1
rebirthOverlayGlow.ZIndex = 271
rebirthOverlayGlow.Parent = rebirthReadyOverlay

local rebirthTopBeam = Instance.new("Frame")
rebirthTopBeam.Name = "TopBeam"
rebirthTopBeam.AnchorPoint = Vector2.new(0.5, 0)
rebirthTopBeam.Position = UDim2.fromScale(0.5, 0.17)
rebirthTopBeam.Size = UDim2.new(0.76, 0, 0, 6)
rebirthTopBeam.BackgroundColor3 = Color3.fromRGB(255, 228, 148)
rebirthTopBeam.BackgroundTransparency = 1
rebirthTopBeam.BorderSizePixel = 0
rebirthTopBeam.ZIndex = 272
rebirthTopBeam.Parent = rebirthReadyOverlay
Instance.new("UICorner", rebirthTopBeam).CornerRadius = UDim.new(1, 0)

local rebirthBottomBeam = Instance.new("Frame")
rebirthBottomBeam.Name = "BottomBeam"
rebirthBottomBeam.AnchorPoint = Vector2.new(0.5, 1)
rebirthBottomBeam.Position = UDim2.fromScale(0.5, 0.49)
rebirthBottomBeam.Size = UDim2.new(0.76, 0, 0, 6)
rebirthBottomBeam.BackgroundColor3 = Color3.fromRGB(255, 228, 148)
rebirthBottomBeam.BackgroundTransparency = 1
rebirthBottomBeam.BorderSizePixel = 0
rebirthBottomBeam.ZIndex = 272
rebirthBottomBeam.Parent = rebirthReadyOverlay
Instance.new("UICorner", rebirthBottomBeam).CornerRadius = UDim.new(1, 0)

local rebirthReadyCard = Instance.new("Frame")
rebirthReadyCard.Name = "RebirthReadyCard"
rebirthReadyCard.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthReadyCard.Position = UDim2.fromScale(0.5, 0.33)
rebirthReadyCard.Size = UDim2.fromOffset(980, 220)
rebirthReadyCard.BackgroundColor3 = Color3.fromRGB(27, 18, 4)
rebirthReadyCard.BackgroundTransparency = 1
rebirthReadyCard.BorderSizePixel = 0
rebirthReadyCard.Visible = false
rebirthReadyCard.ZIndex = 275
rebirthReadyCard.Parent = rebirthReadyOverlay
Instance.new("UICorner", rebirthReadyCard).CornerRadius = UDim.new(0, 28)

local rebirthCardStroke = Instance.new("UIStroke")
rebirthCardStroke.Thickness = 3
rebirthCardStroke.Transparency = 1
rebirthCardStroke.Color = Color3.fromRGB(255, 214, 79)
rebirthCardStroke.Parent = rebirthReadyCard

local rebirthCardGradient = Instance.new("UIGradient")
rebirthCardGradient.Rotation = 18
rebirthCardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 18, 4)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(68, 43, 8)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(23, 14, 3))
})
rebirthCardGradient.Parent = rebirthReadyCard

local rebirthShine = Instance.new("Frame")
rebirthShine.Name = "Shine"
rebirthShine.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthShine.Position = UDim2.fromScale(-0.2, 0.5)
rebirthShine.Size = UDim2.fromScale(0.18, 1.4)
rebirthShine.BackgroundColor3 = Color3.fromRGB(255, 246, 214)
rebirthShine.BackgroundTransparency = 1
rebirthShine.Rotation = 18
rebirthShine.BorderSizePixel = 0
rebirthShine.ZIndex = 276
rebirthShine.Parent = rebirthReadyCard

local rebirthShineGradient = Instance.new("UIGradient")
rebirthShineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.68),
	NumberSequenceKeypoint.new(1, 1)
})
rebirthShineGradient.Parent = rebirthShine

local rebirthViewportHolder = Instance.new("Frame")
rebirthViewportHolder.Name = "ViewportHolder"
rebirthViewportHolder.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthViewportHolder.Position = UDim2.fromScale(0.12, 0.5)
rebirthViewportHolder.Size = UDim2.fromOffset(120, 120)
rebirthViewportHolder.BackgroundColor3 = Color3.fromRGB(34, 23, 4)
rebirthViewportHolder.BackgroundTransparency = 0.15
rebirthViewportHolder.BorderSizePixel = 0
rebirthViewportHolder.ZIndex = 277
rebirthViewportHolder.Parent = rebirthReadyCard
Instance.new("UICorner", rebirthViewportHolder).CornerRadius = UDim.new(1, 0)

local rebirthViewportStroke = Instance.new("UIStroke")
rebirthViewportStroke.Thickness = 4
rebirthViewportStroke.Transparency = 0.08
rebirthViewportStroke.Color = Color3.fromRGB(255, 222, 120)
rebirthViewportStroke.Parent = rebirthViewportHolder

local rebirthViewportGlow = Instance.new("ImageLabel")
rebirthViewportGlow.Name = "ViewportGlow"
rebirthViewportGlow.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthViewportGlow.Position = UDim2.fromScale(0.5, 0.5)
rebirthViewportGlow.Size = UDim2.fromScale(1.65, 1.65)
rebirthViewportGlow.BackgroundTransparency = 1
rebirthViewportGlow.Image = "rbxassetid://4996891970"
rebirthViewportGlow.ImageColor3 = Color3.fromRGB(255, 214, 79)
rebirthViewportGlow.ImageTransparency = 1
rebirthViewportGlow.ZIndex = 278
rebirthViewportGlow.Parent = rebirthViewportHolder

local rebirthViewportHalo = Instance.new("Frame")
rebirthViewportHalo.Name = "ViewportHalo"
rebirthViewportHalo.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthViewportHalo.Position = UDim2.fromScale(0.5, 0.5)
rebirthViewportHalo.Size = UDim2.fromScale(0.74, 0.74)
rebirthViewportHalo.BackgroundColor3 = Color3.fromRGB(255, 202, 73)
rebirthViewportHalo.BackgroundTransparency = 1
rebirthViewportHalo.BorderSizePixel = 0
rebirthViewportHalo.ZIndex = 279
rebirthViewportHalo.Parent = rebirthViewportHolder
Instance.new("UICorner", rebirthViewportHalo).CornerRadius = UDim.new(1, 0)

local rebirthAnnouncementIcon = Instance.new("ImageLabel")
rebirthAnnouncementIcon.Name = "RebirthIcon"
rebirthAnnouncementIcon.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthAnnouncementIcon.Position = UDim2.fromScale(0.5, 0.5)
rebirthAnnouncementIcon.Size = UDim2.fromScale(0.58, 0.58)
rebirthAnnouncementIcon.BackgroundTransparency = 1
rebirthAnnouncementIcon.Image = rebirthReadyIconImage
rebirthAnnouncementIcon.ImageColor3 = Color3.fromRGB(255, 251, 239)
rebirthAnnouncementIcon.ImageTransparency = 1
rebirthAnnouncementIcon.Rotation = -8
rebirthAnnouncementIcon.ZIndex = 280
rebirthAnnouncementIcon.Parent = rebirthViewportHolder

local rebirthBadge = Instance.new("TextLabel")
rebirthBadge.Name = "Badge"
rebirthBadge.AnchorPoint = Vector2.new(0, 0)
rebirthBadge.Position = UDim2.fromScale(0.23, 0.12)
rebirthBadge.Size = UDim2.fromOffset(250, 34)
rebirthBadge.BackgroundColor3 = Color3.fromRGB(255, 214, 79)
rebirthBadge.BackgroundTransparency = 1
rebirthBadge.BorderSizePixel = 0
rebirthBadge.Font = Enum.Font.FredokaOne
rebirthBadge.Text = "INDEX COMPLETE!"
rebirthBadge.TextColor3 = Color3.fromRGB(53, 31, 0)
rebirthBadge.TextSize = 18
rebirthBadge.TextTransparency = 1
rebirthBadge.ZIndex = 278
rebirthBadge.Parent = rebirthReadyCard
Instance.new("UICorner", rebirthBadge).CornerRadius = UDim.new(1, 0)

local rebirthTitle = Instance.new("TextLabel")
rebirthTitle.Name = "Title"
rebirthTitle.AnchorPoint = Vector2.new(0, 0)
rebirthTitle.Position = UDim2.fromScale(0.23, 0.27)
rebirthTitle.Size = UDim2.fromOffset(650, 72)
rebirthTitle.BackgroundTransparency = 1
rebirthTitle.Font = Enum.Font.FredokaOne
rebirthTitle.Text = "CONGRATULATIONS! YOU COLLECTED EVERY BRAINROT!"
rebirthTitle.TextWrapped = true
rebirthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthTitle.TextSize = 29
rebirthTitle.TextXAlignment = Enum.TextXAlignment.Left
rebirthTitle.TextYAlignment = Enum.TextYAlignment.Top
rebirthTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rebirthTitle.TextStrokeTransparency = 0.28
rebirthTitle.TextTransparency = 1
rebirthTitle.ZIndex = 278
rebirthTitle.Parent = rebirthReadyCard

local rebirthReadyRarity = Instance.new("TextLabel")
rebirthReadyRarity.Name = "Rarity"
rebirthReadyRarity.AnchorPoint = Vector2.new(0, 0)
rebirthReadyRarity.Position = UDim2.fromScale(0.23, 0.62)
rebirthReadyRarity.Size = UDim2.fromOffset(360, 30)
rebirthReadyRarity.BackgroundTransparency = 1
rebirthReadyRarity.Font = Enum.Font.FredokaOne
rebirthReadyRarity.Text = "REBIRTH READY"
rebirthReadyRarity.TextColor3 = Color3.fromRGB(255, 214, 79)
rebirthReadyRarity.TextSize = 20
rebirthReadyRarity.TextXAlignment = Enum.TextXAlignment.Left
rebirthReadyRarity.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rebirthReadyRarity.TextStrokeTransparency = 0.42
rebirthReadyRarity.TextTransparency = 1
rebirthReadyRarity.ZIndex = 278
rebirthReadyRarity.Parent = rebirthReadyCard

local rebirthSubText = Instance.new("TextLabel")
rebirthSubText.Name = "SubText"
rebirthSubText.AnchorPoint = Vector2.new(0, 0)
rebirthSubText.Position = UDim2.fromScale(0.23, 0.75)
rebirthSubText.Size = UDim2.fromOffset(590, 42)
rebirthSubText.BackgroundTransparency = 1
rebirthSubText.Font = Enum.Font.GothamMedium
rebirthSubText.Text = "YOU ARE NOW READY TO REBIRTH! UNLOCK EXCLUSIVE PETS, TRAILS & BOOSTS!"
rebirthSubText.TextWrapped = true
rebirthSubText.TextColor3 = Color3.fromRGB(255, 242, 208)
rebirthSubText.TextSize = 19
rebirthSubText.TextTransparency = 1
rebirthSubText.ZIndex = 278
rebirthSubText.Parent = rebirthReadyCard
rebirthSubText.TextXAlignment = Enum.TextXAlignment.Left

local function getGlobalAnnouncementLayout()
	local metrics = HudTileStyle.getLayoutMetrics()
	local viewport = metrics.Viewport or Vector2.new(1280, 720)
	local layout = {
		glowPosition = UDim2.fromScale(0.5, 0.12),
		glowSize = UDim2.fromOffset(1200, 420),
		topBeamPosition = UDim2.fromScale(0.5, 0.03),
		bottomBeamPosition = UDim2.fromScale(0.5, 0.25),
		beamSize = UDim2.new(0.76, 0, 0, 6),
		cardStartSize = UDim2.fromOffset(900, 190),
		cardStartPosition = UDim2.fromScale(0.5, 0.12),
		cardShownSize = UDim2.fromOffset(980, 220),
		cardShownPosition = UDim2.fromScale(0.5, 0.14),
		cardExitSize = UDim2.fromOffset(930, 200),
		cardExitPosition = UDim2.fromScale(0.5, 0.11),
		viewportPosition = UDim2.fromScale(0.12, 0.5),
		viewportStartSize = UDim2.fromOffset(110, 110),
		viewportShownSize = UDim2.fromOffset(120, 120),
		badgePosition = UDim2.fromScale(0.23, 0.12),
		badgeSize = UDim2.fromOffset(220, 34),
		badgeTextSize = 18,
		titlePosition = UDim2.fromScale(0.23, 0.3),
		titleSize = UDim2.fromOffset(660, 60),
		titleTextSize = 34,
		titleWrapped = false,
		titleYAlignment = Enum.TextYAlignment.Center,
		rarityPosition = UDim2.fromScale(0.23, 0.58),
		raritySize = UDim2.fromOffset(360, 32),
		rarityTextSize = 20,
		subTextPosition = UDim2.fromScale(0.23, 0.72),
		subTextSize = UDim2.fromOffset(520, 40),
		subTextTextSize = 20,
		subTextWrapped = true,
		subTextYAlignment = Enum.TextYAlignment.Center,
	}

	if metrics.IsLandscapeMobile then
		local cardWidth = math.clamp(math.floor(metrics.ContentWidth * 0.95 + 0.5), 332, 388)
		local cardHeight = math.clamp(math.floor(viewport.Y * 0.40 + 0.5), 140, 160)
		local cardTop = math.max(18, metrics.TopSafe - math.floor(cardHeight * 0.08 + 0.5))
		local cardCenterX = math.floor((metrics.ContentLeft + metrics.ContentRight) * 0.5 + 0.5)
		local cardCenterY = math.floor(cardTop + cardHeight * 0.5 + 0.5)
		local beamWidth = math.clamp((cardWidth + 80) / viewport.X, 0.54, 0.76)
		local beamCenterX = math.floor(viewport.X * 0.5 + 0.5)
		local beamTopY = math.max(10, cardTop - 16)
		local beamBottomY = math.min(viewport.Y - 12, cardTop + cardHeight + 16)
		local viewportShown = math.clamp(math.floor(cardHeight * 0.56 + 0.5), 80, 90)
		local viewportStart = math.max(72, viewportShown - 8)
		local viewportCenterX = math.floor(cardWidth * 0.15 + 0.5)
		local viewportCenterY = math.floor(cardHeight * 0.5 + 0.5)
		local textLeft = viewportCenterX + math.floor(viewportShown * 0.5 + 18 + 0.5)
		local textWidth = math.max(150, cardWidth - textLeft - 18)

		layout.glowPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.glowSize = UDim2.fromOffset(cardWidth + 180, cardHeight + 150)
		layout.topBeamPosition = UDim2.fromOffset(beamCenterX, beamTopY)
		layout.bottomBeamPosition = UDim2.fromOffset(beamCenterX, beamBottomY)
		layout.beamSize = UDim2.new(beamWidth, 0, 0, 5)
		layout.cardStartSize = UDim2.fromOffset(cardWidth - 26, cardHeight - 12)
		layout.cardStartPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 8)
		layout.cardShownSize = UDim2.fromOffset(cardWidth, cardHeight)
		layout.cardShownPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.cardExitSize = UDim2.fromOffset(cardWidth - 12, cardHeight - 8)
		layout.cardExitPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 6)
		layout.viewportPosition = UDim2.fromOffset(viewportCenterX, viewportCenterY)
		layout.viewportStartSize = UDim2.fromOffset(viewportStart, viewportStart)
		layout.viewportShownSize = UDim2.fromOffset(viewportShown, viewportShown)
		layout.badgePosition = UDim2.fromOffset(textLeft, 14)
		layout.badgeSize = UDim2.fromOffset(math.min(textWidth, 168), 26)
		layout.badgeTextSize = 14
		layout.titlePosition = UDim2.fromOffset(textLeft, 40)
		layout.titleSize = UDim2.fromOffset(textWidth, 52)
		layout.titleTextSize = 21
		layout.titleWrapped = true
		layout.rarityPosition = UDim2.fromOffset(textLeft, 94)
		layout.raritySize = UDim2.fromOffset(math.min(textWidth, 210), 22)
		layout.rarityTextSize = 16
		layout.subTextPosition = UDim2.fromOffset(textLeft, 114)
		layout.subTextSize = UDim2.fromOffset(textWidth, 24)
		layout.subTextTextSize = 14
	elseif metrics.IsMobile then
		local cardWidth = math.clamp(math.floor(viewport.X * 0.9 + 0.5), 330, 460)
		local cardHeight = math.clamp(math.floor(viewport.Y * 0.22 + 0.5), 176, 210)
		local cardTop = math.max(30, metrics.TopSafe + 16)
		local cardCenterX = math.floor(viewport.X * 0.5 + 0.5)
		local cardCenterY = math.floor(cardTop + cardHeight * 0.5 + 0.5)
		local beamWidth = math.clamp((cardWidth + 110) / viewport.X, 0.6, 0.9)
		local viewportShown = math.clamp(math.floor(cardHeight * 0.54 + 0.5), 88, 110)
		local viewportStart = math.max(80, viewportShown - 10)
		local viewportCenterX = math.floor(cardWidth * 0.16 + 0.5)
		local viewportCenterY = math.floor(cardHeight * 0.5 + 0.5)
		local textLeft = viewportCenterX + math.floor(viewportShown * 0.5 + 22 + 0.5)
		local textWidth = math.max(170, cardWidth - textLeft - 24)

		layout.glowPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.glowSize = UDim2.fromOffset(cardWidth + 240, cardHeight + 180)
		layout.topBeamPosition = UDim2.fromOffset(cardCenterX, math.max(12, cardTop - 18))
		layout.bottomBeamPosition = UDim2.fromOffset(cardCenterX, math.min(viewport.Y - 16, cardTop + cardHeight + 18))
		layout.beamSize = UDim2.new(beamWidth, 0, 0, 6)
		layout.cardStartSize = UDim2.fromOffset(cardWidth - 32, cardHeight - 14)
		layout.cardStartPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 10)
		layout.cardShownSize = UDim2.fromOffset(cardWidth, cardHeight)
		layout.cardShownPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.cardExitSize = UDim2.fromOffset(cardWidth - 14, cardHeight - 8)
		layout.cardExitPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 8)
		layout.viewportPosition = UDim2.fromOffset(viewportCenterX, viewportCenterY)
		layout.viewportStartSize = UDim2.fromOffset(viewportStart, viewportStart)
		layout.viewportShownSize = UDim2.fromOffset(viewportShown, viewportShown)
		layout.badgePosition = UDim2.fromOffset(textLeft, 18)
		layout.badgeSize = UDim2.fromOffset(math.min(textWidth, 194), 30)
		layout.badgeTextSize = 16
		layout.titlePosition = UDim2.fromOffset(textLeft, 52)
		layout.titleSize = UDim2.fromOffset(textWidth, 66)
		layout.titleTextSize = 24
		layout.titleWrapped = true
		layout.rarityPosition = UDim2.fromOffset(textLeft, 120)
		layout.raritySize = UDim2.fromOffset(math.min(textWidth, 240), 26)
		layout.rarityTextSize = 18
		layout.subTextPosition = UDim2.fromOffset(textLeft, 148)
		layout.subTextSize = UDim2.fromOffset(textWidth, 30)
		layout.subTextTextSize = 15
	end

	return layout
end

local function applyGlobalAnnouncementLayout(layout)
	overlayGlow.Position = layout.glowPosition
	overlayGlow.Size = layout.glowSize
	topBeam.Position = layout.topBeamPosition
	topBeam.Size = layout.beamSize
	bottomBeam.Position = layout.bottomBeamPosition
	bottomBeam.Size = layout.beamSize
	globalAnnouncementCard.Position = layout.cardShownPosition
	globalAnnouncementCard.Size = layout.cardShownSize
	globalAnnouncementViewportHolder.Position = layout.viewportPosition
	globalAnnouncementViewportHolder.Size = layout.viewportShownSize
	globalBadge.Position = layout.badgePosition
	globalBadge.Size = layout.badgeSize
	globalBadge.TextSize = layout.badgeTextSize
	globalTitle.Position = layout.titlePosition
	globalTitle.Size = layout.titleSize
	globalTitle.TextSize = layout.titleTextSize
	globalTitle.TextWrapped = layout.titleWrapped
	globalTitle.TextYAlignment = layout.titleYAlignment
	globalFinder.Position = layout.titlePosition
	globalFinder.Size = layout.titleSize
	globalFinder.TextSize = layout.titleTextSize
	globalFinder.TextWrapped = layout.titleWrapped
	globalFinder.TextYAlignment = layout.titleYAlignment
	globalRarity.Position = layout.rarityPosition
	globalRarity.Size = layout.raritySize
	globalRarity.TextSize = layout.rarityTextSize
	globalSubText.Position = layout.subTextPosition
	globalSubText.Size = layout.subTextSize
	globalSubText.TextSize = layout.subTextTextSize
	globalSubText.TextWrapped = layout.subTextWrapped
	globalSubText.TextYAlignment = layout.subTextYAlignment
end

local function getRebirthReadyLayout()
	local metrics = HudTileStyle.getLayoutMetrics()
	local viewport = metrics.Viewport or Vector2.new(1280, 720)
	local layout = {
		glowPosition = UDim2.fromScale(0.5, 0.33),
		glowSize = UDim2.fromOffset(1220, 440),
		topBeamPosition = UDim2.fromScale(0.5, 0.17),
		bottomBeamPosition = UDim2.fromScale(0.5, 0.49),
		beamSize = UDim2.new(0.76, 0, 0, 6),
		cardStartSize = UDim2.fromOffset(900, 190),
		cardStartPosition = UDim2.fromScale(0.5, 0.31),
		cardShownSize = UDim2.fromOffset(980, 220),
		cardShownPosition = UDim2.fromScale(0.5, 0.33),
		cardExitSize = UDim2.fromOffset(930, 200),
		cardExitPosition = UDim2.fromScale(0.5, 0.3),
		viewportPosition = UDim2.fromScale(0.12, 0.5),
		viewportStartSize = UDim2.fromOffset(110, 110),
		viewportShownSize = UDim2.fromOffset(120, 120),
		iconStartSize = UDim2.fromScale(0.5, 0.5),
		iconShownSize = UDim2.fromScale(0.58, 0.58),
		badgePosition = UDim2.fromScale(0.23, 0.12),
		badgeSize = UDim2.fromOffset(250, 34),
		badgeTextSize = 18,
		titlePosition = UDim2.fromScale(0.23, 0.27),
		titleSize = UDim2.fromOffset(650, 72),
		titleTextSize = 29,
		titleWrapped = true,
		titleYAlignment = Enum.TextYAlignment.Top,
		rarityPosition = UDim2.fromScale(0.23, 0.62),
		raritySize = UDim2.fromOffset(360, 30),
		rarityTextSize = 20,
		subTextPosition = UDim2.fromScale(0.23, 0.75),
		subTextSize = UDim2.fromOffset(590, 42),
		subTextTextSize = 19,
		subTextWrapped = true,
		subTextYAlignment = Enum.TextYAlignment.Center,
		shineStartPosition = UDim2.fromScale(-0.2, 0.5),
		shineEndPosition = UDim2.fromScale(1.15, 0.5),
	}

	if metrics.IsLandscapeMobile then
		local cardWidth = math.clamp(math.floor(metrics.ContentWidth * 0.99 + 0.5), 344, 394)
		local cardHeight = math.clamp(math.floor(viewport.Y * 0.43 + 0.5), 160, 176)
		local cardTop = math.max(48, metrics.TopSafe + math.floor(viewport.Y * 0.10 + 0.5))
		local cardCenterX = math.floor((metrics.ContentLeft + metrics.ContentRight) * 0.5 + 0.5)
		local cardCenterY = math.floor(cardTop + cardHeight * 0.5 + 0.5)
		local beamWidth = math.clamp((cardWidth + 90) / viewport.X, 0.56, 0.78)
		local beamCenterX = math.floor(viewport.X * 0.5 + 0.5)
		local viewportShown = math.clamp(math.floor(cardHeight * 0.55 + 0.5), 84, 92)
		local viewportStart = math.max(74, viewportShown - 8)
		local viewportCenterX = math.floor(cardWidth * 0.145 + 0.5)
		local viewportCenterY = math.floor(cardHeight * 0.5 + 0.5)
		local textLeft = viewportCenterX + math.floor(viewportShown * 0.5 + 16 + 0.5)
		local textWidth = math.max(164, cardWidth - textLeft - 14)

		layout.glowPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.glowSize = UDim2.fromOffset(cardWidth + 190, cardHeight + 160)
		layout.topBeamPosition = UDim2.fromOffset(beamCenterX, math.max(16, cardTop - 18))
		layout.bottomBeamPosition = UDim2.fromOffset(beamCenterX, math.min(viewport.Y - 14, cardTop + cardHeight + 18))
		layout.beamSize = UDim2.new(beamWidth, 0, 0, 5)
		layout.cardStartSize = UDim2.fromOffset(cardWidth - 28, cardHeight - 12)
		layout.cardStartPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 9)
		layout.cardShownSize = UDim2.fromOffset(cardWidth, cardHeight)
		layout.cardShownPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.cardExitSize = UDim2.fromOffset(cardWidth - 12, cardHeight - 8)
		layout.cardExitPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 7)
		layout.viewportPosition = UDim2.fromOffset(viewportCenterX, viewportCenterY)
		layout.viewportStartSize = UDim2.fromOffset(viewportStart, viewportStart)
		layout.viewportShownSize = UDim2.fromOffset(viewportShown, viewportShown)
		layout.badgePosition = UDim2.fromOffset(textLeft, 14)
		layout.badgeSize = UDim2.fromOffset(math.min(textWidth, 168), 26)
		layout.badgeTextSize = 14
		layout.titlePosition = UDim2.fromOffset(textLeft, 38)
		layout.titleSize = UDim2.fromOffset(textWidth, 58)
		layout.titleTextSize = 19
		layout.titleYAlignment = Enum.TextYAlignment.Center
		layout.rarityPosition = UDim2.fromOffset(textLeft, 99)
		layout.raritySize = UDim2.fromOffset(math.min(textWidth, 210), 22)
		layout.rarityTextSize = 16
		layout.subTextPosition = UDim2.fromOffset(textLeft, 118)
		layout.subTextSize = UDim2.fromOffset(textWidth, 36)
		layout.subTextTextSize = 12
		layout.subTextYAlignment = Enum.TextYAlignment.Top
	elseif metrics.IsMobile then
		local cardWidth = math.clamp(math.floor(viewport.X * 0.9 + 0.5), 336, 470)
		local cardHeight = math.clamp(math.floor(viewport.Y * 0.24 + 0.5), 190, 232)
		local cardTop = math.max(44, metrics.TopSafe + 72)
		local cardCenterX = math.floor(viewport.X * 0.5 + 0.5)
		local cardCenterY = math.floor(cardTop + cardHeight * 0.5 + 0.5)
		local beamWidth = math.clamp((cardWidth + 120) / viewport.X, 0.62, 0.92)
		local viewportShown = math.clamp(math.floor(cardHeight * 0.56 + 0.5), 92, 112)
		local viewportStart = math.max(84, viewportShown - 10)
		local viewportCenterX = math.floor(cardWidth * 0.16 + 0.5)
		local viewportCenterY = math.floor(cardHeight * 0.5 + 0.5)
		local textLeft = viewportCenterX + math.floor(viewportShown * 0.5 + 22 + 0.5)
		local textWidth = math.max(172, cardWidth - textLeft - 24)

		layout.glowPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.glowSize = UDim2.fromOffset(cardWidth + 250, cardHeight + 190)
		layout.topBeamPosition = UDim2.fromOffset(cardCenterX, math.max(18, cardTop - 20))
		layout.bottomBeamPosition = UDim2.fromOffset(cardCenterX, math.min(viewport.Y - 18, cardTop + cardHeight + 20))
		layout.beamSize = UDim2.new(beamWidth, 0, 0, 6)
		layout.cardStartSize = UDim2.fromOffset(cardWidth - 34, cardHeight - 14)
		layout.cardStartPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 10)
		layout.cardShownSize = UDim2.fromOffset(cardWidth, cardHeight)
		layout.cardShownPosition = UDim2.fromOffset(cardCenterX, cardCenterY)
		layout.cardExitSize = UDim2.fromOffset(cardWidth - 16, cardHeight - 8)
		layout.cardExitPosition = UDim2.fromOffset(cardCenterX, cardCenterY - 8)
		layout.viewportPosition = UDim2.fromOffset(viewportCenterX, viewportCenterY)
		layout.viewportStartSize = UDim2.fromOffset(viewportStart, viewportStart)
		layout.viewportShownSize = UDim2.fromOffset(viewportShown, viewportShown)
		layout.badgePosition = UDim2.fromOffset(textLeft, 18)
		layout.badgeSize = UDim2.fromOffset(math.min(textWidth, 190), 30)
		layout.badgeTextSize = 16
		layout.titlePosition = UDim2.fromOffset(textLeft, 50)
		layout.titleSize = UDim2.fromOffset(textWidth, 74)
		layout.titleTextSize = 22
		layout.titleYAlignment = Enum.TextYAlignment.Top
		layout.rarityPosition = UDim2.fromOffset(textLeft, 128)
		layout.raritySize = UDim2.fromOffset(math.min(textWidth, 240), 26)
		layout.rarityTextSize = 18
		layout.subTextPosition = UDim2.fromOffset(textLeft, 156)
		layout.subTextSize = UDim2.fromOffset(textWidth, 34)
		layout.subTextTextSize = 15
	end

	return layout
end

local function applyRebirthReadyLayout(layout)
	rebirthOverlayGlow.Position = layout.glowPosition
	rebirthOverlayGlow.Size = layout.glowSize
	rebirthTopBeam.Position = layout.topBeamPosition
	rebirthTopBeam.Size = layout.beamSize
	rebirthBottomBeam.Position = layout.bottomBeamPosition
	rebirthBottomBeam.Size = layout.beamSize
	rebirthReadyCard.Position = layout.cardShownPosition
	rebirthReadyCard.Size = layout.cardShownSize
	rebirthViewportHolder.Position = layout.viewportPosition
	rebirthViewportHolder.Size = layout.viewportShownSize
	rebirthAnnouncementIcon.Size = layout.iconShownSize
	rebirthBadge.Position = layout.badgePosition
	rebirthBadge.Size = layout.badgeSize
	rebirthBadge.TextSize = layout.badgeTextSize
	rebirthTitle.Position = layout.titlePosition
	rebirthTitle.Size = layout.titleSize
	rebirthTitle.TextSize = layout.titleTextSize
	rebirthTitle.TextWrapped = layout.titleWrapped
	rebirthTitle.TextYAlignment = layout.titleYAlignment
	rebirthReadyRarity.Position = layout.rarityPosition
	rebirthReadyRarity.Size = layout.raritySize
	rebirthReadyRarity.TextSize = layout.rarityTextSize
	rebirthSubText.Position = layout.subTextPosition
	rebirthSubText.Size = layout.subTextSize
	rebirthSubText.TextSize = layout.subTextTextSize
	rebirthSubText.TextWrapped = layout.subTextWrapped
	rebirthSubText.TextYAlignment = layout.subTextYAlignment
end

applyGlobalAnnouncementLayout(getGlobalAnnouncementLayout())
applyRebirthReadyLayout(getRebirthReadyLayout())

task.spawn(function()
	local rebirthIconAsset = ReplicatedStorage:WaitForChild("RebirthIcon", 5)
	if rebirthIconAsset then
		if rebirthIconAsset:IsA("Decal") then
			rebirthReadyIconImage = rebirthIconAsset.Texture
		elseif rebirthIconAsset:IsA("ImageLabel") or rebirthIconAsset:IsA("ImageButton") then
			rebirthReadyIconImage = rebirthIconAsset.Image
		elseif rebirthIconAsset:IsA("StringValue") then
			rebirthReadyIconImage = rebirthIconAsset.Value
		end
	end

	rebirthAnnouncementIcon.Image = rebirthReadyIconImage
end)

local function getAnnouncementDisplayName(brainrotName, rarity)
	if (rarity or "") == "OG" and brainrotName == "Strawberry Elephant" then
		return "OG Brainrot Strawberry Elephant"
	end

	return brainrotName or "Strawberry Elephant"
end


local function createViewport(model, parent, isCollected, options)
	options = options or {}
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
	camera.FieldOfView = 30
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	local cf, size = clone:GetBoundingBox()
	local isNotify = (parent == notifyViewport)
	local isGlobalAnnouncement = (parent == globalAnnouncementViewport)
	if isGlobalAnnouncement then
		camera.CFrame = CFrame.lookAt(
			cf.Position + Vector3.new(size.X * 0.42, size.Y * 0.12, size.Z * 1.22),
			cf.Position
		)
	else
		local absSize = viewport.AbsoluteSize
		local aspect = (absSize.X > 0 and absSize.Y > 0) and (absSize.X / absSize.Y) or (isNotify and 1 or 1.55)
		local verticalHalfFov = math.rad(camera.FieldOfView * 0.5)
		local horizontalHalfFov = math.atan(math.tan(verticalHalfFov) * aspect)
		local fitHalfFov = math.min(verticalHalfFov, horizontalHalfFov)
		local radius = math.max(size.Magnitude * 0.5, 0.1)
		local distance = (radius / math.sin(fitHalfFov)) * (options.distanceMultiplier or 1.08)
		local lookDirection = options.lookDirection or (isNotify and Vector3.new(0, 0, 1) or Vector3.new(1, 0.48, 1).Unit)
		local cameraPosition = cf.Position + (lookDirection * distance)
		camera.CFrame = CFrame.lookAt(cameraPosition, cf.Position)
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
		local spinDistance = (camera.CFrame.Position - cf.Position).Magnitude
		spinningModels[viewport] = {Clone = clone, Center = cf.Position, Dist = spinDistance, IsNotify = (isNotify or isGlobalAnnouncement)}
	end
	return viewport
end

local function isRebirthReadyTarget(brainrotName, rarity)
	return tostring(brainrotName or "") == REBIRTH_READY_TARGET and tostring(rarity or "") == REBIRTH_READY_RARITY
end

local function hideRebirthReadyEffectImmediately()
	local layout = getRebirthReadyLayout()
	applyRebirthReadyLayout(layout)

	rebirthReadyOverlay.BackgroundTransparency = 1
	rebirthOverlayGlow.ImageTransparency = 1
	rebirthTopBeam.BackgroundTransparency = 1
	rebirthBottomBeam.BackgroundTransparency = 1
	rebirthReadyCard.BackgroundTransparency = 1
	rebirthCardStroke.Transparency = 1
	rebirthCardStroke.Thickness = 3
	rebirthBadge.BackgroundTransparency = 1
	rebirthBadge.TextTransparency = 1
	rebirthTitle.TextTransparency = 1
	rebirthReadyRarity.TextTransparency = 1
	rebirthSubText.TextTransparency = 1
	rebirthViewportGlow.ImageTransparency = 1
	rebirthViewportHalo.BackgroundTransparency = 1
	rebirthAnnouncementIcon.ImageTransparency = 1
	rebirthReadyCard.Size = layout.cardStartSize
	rebirthReadyCard.Position = layout.cardStartPosition
	rebirthViewportHolder.Size = layout.viewportStartSize
	rebirthAnnouncementIcon.Size = layout.iconStartSize
	rebirthShine.Position = layout.shineStartPosition
	rebirthShine.BackgroundTransparency = 1
	rebirthReadyCard.Visible = false
	rebirthReadyOverlay.Visible = false
end

local function resetRebirthReadyAnnouncementState()
	rebirthReadyRequestId += 1
	isRebirthReadyQueued = false
	isRebirthReadyShowing = false
	hasShownRebirthReadyAnnouncement = false
	hideRebirthReadyEffectImmediately()
end

local function showRebirthReadyEffect(requestId)
	if rebirthReadyRequestId ~= requestId or isRebirthReadyShowing then
		return
	end

	local layout = getRebirthReadyLayout()
	applyRebirthReadyLayout(layout)

	isRebirthReadyShowing = true
	rebirthReadyOverlay.Visible = true
	rebirthReadyCard.Visible = true
	rebirthAnnouncementIcon.Image = rebirthReadyIconImage

	rebirthReadyOverlay.BackgroundTransparency = 1
	rebirthOverlayGlow.ImageTransparency = 1
	rebirthTopBeam.BackgroundTransparency = 1
	rebirthBottomBeam.BackgroundTransparency = 1
	rebirthReadyCard.BackgroundTransparency = 1
	rebirthCardStroke.Transparency = 1
	rebirthCardStroke.Thickness = 3
	rebirthBadge.BackgroundTransparency = 1
	rebirthBadge.TextTransparency = 1
	rebirthTitle.TextTransparency = 1
	rebirthReadyRarity.TextTransparency = 1
	rebirthSubText.TextTransparency = 1
	rebirthViewportGlow.ImageTransparency = 1
	rebirthViewportHalo.BackgroundTransparency = 1
	rebirthAnnouncementIcon.ImageTransparency = 1
	rebirthReadyCard.Size = layout.cardStartSize
	rebirthReadyCard.Position = layout.cardStartPosition
	rebirthViewportHolder.Size = layout.viewportStartSize
	rebirthAnnouncementIcon.Size = layout.iconStartSize
	rebirthShine.Position = layout.shineStartPosition
	rebirthShine.BackgroundTransparency = 1

	TweenService:Create(rebirthReadyOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.28}):Play()
	TweenService:Create(rebirthOverlayGlow, TweenInfo.new(0.35), {ImageTransparency = 0.44}):Play()
	TweenService:Create(rebirthTopBeam, TweenInfo.new(0.35), {BackgroundTransparency = 0.08}):Play()
	TweenService:Create(rebirthBottomBeam, TweenInfo.new(0.35), {BackgroundTransparency = 0.08}):Play()
	TweenService:Create(rebirthReadyCard, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.08,
		Size = layout.cardShownSize,
		Position = layout.cardShownPosition,
	}):Play()
	TweenService:Create(rebirthCardStroke, TweenInfo.new(0.35), {Transparency = 0.04}):Play()
	TweenService:Create(rebirthBadge, TweenInfo.new(0.35), {BackgroundTransparency = 0.02, TextTransparency = 0}):Play()
	TweenService:Create(rebirthTitle, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(rebirthReadyRarity, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(rebirthSubText, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(rebirthViewportHolder, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = layout.viewportShownSize
	}):Play()
	TweenService:Create(rebirthViewportGlow, TweenInfo.new(0.35), {ImageTransparency = 0.32}):Play()
	TweenService:Create(rebirthViewportHalo, TweenInfo.new(0.35), {BackgroundTransparency = 0.32}):Play()
	TweenService:Create(rebirthAnnouncementIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		ImageTransparency = 0,
		Size = layout.iconShownSize
	}):Play()
	TweenService:Create(rebirthShine, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = layout.shineEndPosition,
		BackgroundTransparency = 0.45,
	}):Play()

	local pulseTween = TweenService:Create(rebirthCardStroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {
		Thickness = 7
	})
	pulseTween:Play()

	task.delay(REBIRTH_READY_DURATION, function()
		if rebirthReadyRequestId ~= requestId or not isRebirthReadyShowing then
			return
		end

		TweenService:Create(rebirthReadyOverlay, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
		TweenService:Create(rebirthOverlayGlow, TweenInfo.new(0.35), {ImageTransparency = 1}):Play()
		TweenService:Create(rebirthTopBeam, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
		TweenService:Create(rebirthBottomBeam, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
		TweenService:Create(rebirthReadyCard, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			Size = layout.cardExitSize,
			Position = layout.cardExitPosition,
		}):Play()
		TweenService:Create(rebirthCardStroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
		TweenService:Create(rebirthBadge, TweenInfo.new(0.25), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(rebirthTitle, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		TweenService:Create(rebirthReadyRarity, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		TweenService:Create(rebirthSubText, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
		TweenService:Create(rebirthViewportGlow, TweenInfo.new(0.25), {ImageTransparency = 1}):Play()
		TweenService:Create(rebirthViewportHalo, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
		TweenService:Create(rebirthAnnouncementIcon, TweenInfo.new(0.25), {ImageTransparency = 1}):Play()

		task.delay(0.4, function()
			if rebirthReadyRequestId ~= requestId then
				return
			end

			hideRebirthReadyEffectImmediately()
			isRebirthReadyShowing = false
		end)
	end)
end

local function scheduleRebirthReadyAnnouncement(brainrotName, rarity)
	if not isRebirthReadyTarget(brainrotName, rarity) then
		return
	end

	if isRebirthReadyQueued or hasShownRebirthReadyAnnouncement or isRebirthing then
		return
	end

	isRebirthReadyQueued = true
	rebirthReadyRequestId += 1
	local requestId = rebirthReadyRequestId

	task.delay(REBIRTH_READY_DELAY, function()
		if rebirthReadyRequestId ~= requestId then
			return
		end

		isRebirthReadyQueued = false

		if isRebirthing or player.Parent ~= Players then
			return
		end

		hasShownRebirthReadyAnnouncement = true
		showRebirthReadyEffect(requestId)
	end)
end

hideRebirthReadyEffectImmediately()

local function promptFavorite()
	pcall(function()
		AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end

local function markExperienceFavorited()
	if hasFavoritedExperience then
		return
	end

	hasFavoritedExperience = true
	MarkExperienceFavoritedEvent:FireServer()
end

local function hasExistingFavorite()
	if hasFavoritedExperience or isCheckingFavoriteStatus then
		return hasFavoritedExperience
	end

	isCheckingFavoriteStatus = true
	local success, isFavorited = pcall(function()
		return AvatarEditorService:GetFavoriteAsync(game.PlaceId, Enum.AvatarItemType.Asset)
	end)
	isCheckingFavoriteStatus = false

	if success and isFavorited then
		markExperienceFavorited()
		return true
	end

	return false
end

AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result)
	if result == Enum.AvatarPromptResult.Success then
		markExperienceFavorited()
	end
end)

local function showCollectionEffect(name, rarity)
	isShowingNow = true
	activeNotifyRarity = rarity

	if rarity ~= "Common" and rarity ~= "Rare" and not hasPromptedFavorite then
		hasPromptedFavorite = true
		task.spawn(function()
			if hasExistingFavorite() then
				return
			end

			task.delay(5, function()
				if player and player.Parent and not hasFavoritedExperience then
					promptFavorite()
				end
			end)
		end)
	end

	local modelTemplate = BrainrotStorage:FindFirstChild(name)
	if modelTemplate then
		applyCollectionNotifyLayout()
		createViewport(modelTemplate, notifyViewport, true, getCollectionNotifyViewportOptions())
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

local function showGlobalDiscoveryEffect(finderName, brainrotName, rarity)
	local layout = getGlobalAnnouncementLayout()
	applyGlobalAnnouncementLayout(layout)

	isGlobalAnnouncementShowing = true
	globalAnnouncementOverlay.Visible = true
	globalAnnouncementCard.Visible = true

	local announcementName = "OG STRAWBERRY ELEPHANT"
	globalBadge.Text = "GLOBAL DISCOVERY"
	globalRarity.Text = "OG BRAINROT FOUND"
	globalFinder.Text = string.upper(tostring(finderName or "Someone") .. " JUST FOUND " .. announcementName)
	globalSubText.Text = "You can still find it too!"

	globalAnnouncementOverlay.BackgroundTransparency = 1
	overlayGlow.ImageTransparency = 1
	topBeam.BackgroundTransparency = 1
	bottomBeam.BackgroundTransparency = 1
	globalAnnouncementCard.BackgroundTransparency = 1
	globalCardStroke.Transparency = 1
	globalCardStroke.Thickness = 3
	globalBadge.BackgroundTransparency = 1
	globalBadge.TextTransparency = 1
	globalTitle.TextTransparency = 1
	globalRarity.TextTransparency = 1
	globalFinder.TextTransparency = 1
	globalSubText.TextTransparency = 1
	globalAnnouncementViewport.ImageTransparency = 1
	globalAnnouncementCard.Size = layout.cardStartSize
	globalAnnouncementCard.Position = layout.cardStartPosition
	globalAnnouncementViewportHolder.Size = layout.viewportStartSize
	globalShine.Position = layout.shineStartPosition or UDim2.fromScale(-0.2, 0.5)
	globalShine.BackgroundTransparency = 1

	local modelTemplate = BrainrotStorage:FindFirstChild(brainrotName or "")
	if modelTemplate then
		createViewport(modelTemplate, globalAnnouncementViewport, true)
	end

	TweenService:Create(globalAnnouncementOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.22}):Play()
	TweenService:Create(overlayGlow, TweenInfo.new(0.35), {ImageTransparency = 0.5}):Play()
	TweenService:Create(topBeam, TweenInfo.new(0.35), {BackgroundTransparency = 0.12}):Play()
	TweenService:Create(bottomBeam, TweenInfo.new(0.35), {BackgroundTransparency = 0.12}):Play()
	TweenService:Create(globalAnnouncementCard, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.12,
		Size = layout.cardShownSize,
		Position = layout.cardShownPosition,
	}):Play()
	TweenService:Create(globalCardStroke, TweenInfo.new(0.35), {Transparency = 0.05}):Play()
	TweenService:Create(globalBadge, TweenInfo.new(0.35), {BackgroundTransparency = 0.02, TextTransparency = 0}):Play()
	TweenService:Create(globalRarity, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(globalFinder, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(globalSubText, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(globalAnnouncementViewport, TweenInfo.new(0.35), {ImageTransparency = 0}):Play()
	TweenService:Create(globalAnnouncementViewportHolder, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = layout.viewportShownSize
	}):Play()
	TweenService:Create(globalShine, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = layout.shineEndPosition or UDim2.fromScale(1.15, 0.5),
		BackgroundTransparency = 0.55,
	}):Play()

	local pulseTween = TweenService:Create(globalCardStroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {
		Thickness = 7
	})
	pulseTween:Play()

	task.wait(10)

	TweenService:Create(globalAnnouncementOverlay, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	TweenService:Create(overlayGlow, TweenInfo.new(0.35), {ImageTransparency = 1}):Play()
	TweenService:Create(topBeam, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	TweenService:Create(bottomBeam, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	TweenService:Create(globalAnnouncementCard, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
		Size = layout.cardExitSize,
		Position = layout.cardExitPosition,
	}):Play()
	TweenService:Create(globalCardStroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
	TweenService:Create(globalBadge, TweenInfo.new(0.25), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
	TweenService:Create(globalRarity, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	TweenService:Create(globalFinder, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	TweenService:Create(globalSubText, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	TweenService:Create(globalAnnouncementViewport, TweenInfo.new(0.25), {ImageTransparency = 1}):Play()

	task.wait(0.4)

	spinningModels[globalAnnouncementViewport] = nil
	globalAnnouncementViewport:ClearAllChildren()
	globalAnnouncementCard.Visible = false
	globalAnnouncementOverlay.Visible = false
	isGlobalAnnouncementShowing = false
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

task.spawn(function()
	while true do
		if #globalAnnouncementQueue > 0 and not isGlobalAnnouncementShowing then
			local nextAnnouncement = table.remove(globalAnnouncementQueue, 1)
			showGlobalDiscoveryEffect(nextAnnouncement.finderName, nextAnnouncement.brainrotName, nextAnnouncement.rarity)
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
indexGlow.Parent = ToggleGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Position = HudTileStyle.getSlot("left", 1)
openButton.Text = ""
openButton.ZIndex = 11
openButton.Parent = ToggleGui

local indexImg = Instance.new("ImageLabel")
indexImg.Name = "IndexIcon"
indexImg.Image = HudTileStyle.getImage(ReplicatedStorage, "Index", "rbxassetid://72256385")
indexImg.Parent = openButton

local indexText = Instance.new("TextLabel")
indexText.Text = "INDEX"
indexText.Parent = openButton

HudTileStyle.apply(openButton, indexImg, indexText, {
	side = "left",
	slotIndex = 1,
	zIndex = 11,
})

-- RAMKA INDEKSU
local indexBackdrop = Instance.new("Frame")
indexBackdrop.Name = "IndexBackdrop"
indexBackdrop.Size = UDim2.fromScale(1, 1)
indexBackdrop.BackgroundColor3 = Color3.fromRGB(7, 9, 13)
indexBackdrop.BackgroundTransparency = 0.32
indexBackdrop.BorderSizePixel = 0
indexBackdrop.Visible = false
indexBackdrop.Active = true
indexBackdrop.ZIndex = 49
indexBackdrop.Parent = screenGui

local indexModal = Instance.new("Frame")
indexModal.Name = "IndexModal"
indexModal.AnchorPoint = Vector2.new(0.5, 0.5)
indexModal.Position = UDim2.fromScale(0.5, 0.5)
indexModal.BackgroundColor3 = HudTileStyle.BaseBackgroundColor
indexModal.BorderSizePixel = 0
indexModal.ClipsDescendants = true
indexModal.ZIndex = 50
indexModal.Parent = indexBackdrop

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 28)
modalCorner.Parent = indexModal

local indexModalScale = Instance.new("UIScale")
indexModalScale.Name = "IndexModalScale"
indexModalScale.Scale = 1
indexModalScale.Parent = indexModal

local modalStroke = Instance.new("UIStroke")
modalStroke.Thickness = 3
modalStroke.Color = HudTileStyle.BaseStrokeColor
modalStroke.Transparency = 0.04
modalStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
modalStroke.Parent = indexModal

local modalGradient = Instance.new("UIGradient")
modalGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, HudTileStyle.BaseTopColor),
	ColorSequenceKeypoint.new(1, HudTileStyle.BaseBottomColor),
})
modalGradient.Rotation = 90
modalGradient.Parent = indexModal

local modalBg = Instance.new("ImageLabel")
modalBg.Name = "ModalBg"
modalBg.Size = UDim2.fromScale(1, 1)
modalBg.BackgroundTransparency = 1
modalBg.Image = GreenStudsTexture
modalBg.ImageColor3 = Color3.fromRGB(126, 184, 132)
modalBg.ImageTransparency = 0.74
modalBg.ScaleType = Enum.ScaleType.Tile
modalBg.TileSize = UDim2.fromOffset(128, 128)
modalBg.ZIndex = 50
modalBg.Parent = indexModal
local modalBgCorner = Instance.new("UICorner")
modalBgCorner.CornerRadius = UDim.new(0, 28)
modalBgCorner.Parent = modalBg

local modalHeader = Instance.new("Frame")
modalHeader.Name = "Header"
modalHeader.BackgroundTransparency = 1
modalHeader.ZIndex = 51
modalHeader.Parent = indexModal

local headerDivider = Instance.new("Frame")
headerDivider.Name = "Divider"
headerDivider.AnchorPoint = Vector2.new(0.5, 1)
headerDivider.Position = UDim2.new(0.5, 0, 1, 0)
headerDivider.Size = UDim2.new(1, -36, 0, 2)
headerDivider.BackgroundColor3 = HudTileStyle.BaseStrokeColor
headerDivider.BackgroundTransparency = 0.72
headerDivider.BorderSizePixel = 0
headerDivider.ZIndex = 52
headerDivider.Parent = modalHeader

-- GŁÓWNY TYTUŁ W HEADERZE
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BRAINROT INDEX"
titleLabel.TextColor3 = HudTileStyle.BaseLabelColor
titleLabel.Font = Enum.Font.LuckiestGuy
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 53
titleLabel.Parent = modalHeader
local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 2
titleStroke.Color = Color3.new(0, 0, 0)
titleStroke.Parent = titleLabel

local helperLabel = Instance.new("TextLabel")
helperLabel.Name = "HelperLabel"
helperLabel.BackgroundTransparency = 1
helperLabel.Text = "COLLECTION ALBUM"
helperLabel.TextColor3 = Color3.fromRGB(214, 222, 235)
helperLabel.TextTransparency = 0.16
helperLabel.Font = Enum.Font.FredokaOne
helperLabel.TextXAlignment = Enum.TextXAlignment.Left
helperLabel.ZIndex = 52
helperLabel.Parent = modalHeader

-- PRZYCISK X
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(156, 52, 64)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.FredokaOne
closeButton.AutoButtonColor = false
closeButton.ZIndex = 54
closeButton.Parent = modalHeader
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 14)
closeCorner.Parent = closeButton
local closeStroke = Instance.new("UIStroke")
closeStroke.Thickness = 2
closeStroke.Color = HudTileStyle.BaseStrokeColor
closeStroke.Transparency = 0.12
closeStroke.Parent = closeButton
closeButton.Activated:Connect(HudTileStyle.playClick)

-- PASEK POSTĘPU (W INDEKSIE)
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.BackgroundColor3 = Color3.fromRGB(18, 21, 27)
progressContainer.BorderSizePixel = 0
progressContainer.ZIndex = 52
progressContainer.Parent = modalHeader

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 16)
progressCorner.Parent = progressContainer

local progressStroke = Instance.new("UIStroke")
progressStroke.Thickness = 2
progressStroke.Color = HudTileStyle.BaseStrokeColor
progressStroke.Transparency = 0.18
progressStroke.Parent = progressContainer

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.fromScale(0, 1)
progressBar.BackgroundColor3 = Color3.fromRGB(255, 78, 126)
progressBar.BorderSizePixel = 0
progressBar.ClipsDescendants = true
progressBar.Parent = progressContainer

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 16)
barCorner.Parent = progressBar

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "ProgressLabel"
progressLabel.Size = UDim2.fromScale(1, 1)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "COLLECTED: 0 / " .. currentBrainrotTotal
progressLabel.TextColor3 = Color3.new(1, 1, 1)
progressLabel.Font = Enum.Font.FredokaOne
progressLabel.TextStrokeTransparency = 1
progressLabel.ZIndex = 53
progressLabel.Parent = progressContainer

local indexFrame = Instance.new("ScrollingFrame")
indexFrame.Name = "IndexFrame"
indexFrame.BackgroundTransparency = 1
indexFrame.BorderSizePixel = 0
indexFrame.ScrollBarThickness = 18
indexFrame.ScrollBarImageColor3 = HudTileStyle.BaseStrokeColor
indexFrame.ScrollBarImageTransparency = 0.06
indexFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexFrame.CanvasSize = UDim2.fromOffset(0, 0)
indexFrame.ZIndex = 51
indexFrame.Parent = indexModal

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 4)
gridPadding.PaddingBottom = UDim.new(0, 4)
gridPadding.Parent = indexFrame

local layout = Instance.new("UIGridLayout")
layout.CellPadding = UDim2.fromOffset(14, 14)
layout.CellSize = UDim2.fromOffset(172, 200)
layout.FillDirectionMaxCells = 4
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.Name
layout.Parent = indexFrame

local function applyIndexModalLayout()
	local metrics = HudTileStyle.getLayoutMetrics()
	local viewport = metrics.Viewport or Vector2.new(1280, 720)
	local isMobile = metrics.IsMobile
	local isLandscapeMobile = metrics.IsLandscapeMobile
	local modalWidthPx
	local modalHeightPx
	local headerHeight
	local sidePadding
	local bodyGap
	local columns
	local cellPadding
	local cellWidth
	local cellHeight
	local modalScale = 1
	local titleY
	local titleHeight
	local titleTextSize
	local helperY
	local helperHeight
	local helperTextSize
	local closeY
	local closeSize
	local closeTextSize
	local progressY
	local progressHeight
	local progressTextSize

	if isLandscapeMobile then
		modalWidthPx = 1040
		modalHeightPx = 650
		headerHeight = 132
		sidePadding = 20
		bodyGap = 12
		cellPadding = 16
		columns = 4
		cellWidth = math.floor((modalWidthPx - (sidePadding * 2) - (cellPadding * (columns - 1))) / columns)
		cellWidth = math.clamp(cellWidth, 214, 292)
		cellHeight = math.floor(cellWidth * 1.15 + 0.5)
		modalScale = math.clamp(math.min((viewport.X * 0.93) / modalWidthPx, (viewport.Y * 0.88) / modalHeightPx), 0.48, 0.82)
		titleY = 16
		titleHeight = 38
		titleTextSize = 38
		helperY = 54
		helperHeight = 20
		helperTextSize = 15
		closeY = 16
		closeSize = 46
		closeTextSize = 26
		progressY = 84
		progressHeight = 30
		progressTextSize = 15
	elseif isMobile then
		modalWidthPx = 1020
		modalHeightPx = 760
		headerHeight = 132
		sidePadding = 20
		bodyGap = 12
		cellPadding = 16
		local frameWidth = modalWidthPx - (sidePadding * 2)
		columns = frameWidth >= 680 and 3 or 2
		cellWidth = math.floor((frameWidth - (cellPadding * (columns - 1))) / columns)
		cellWidth = math.clamp(cellWidth, 180, 260)
		cellHeight = math.floor(cellWidth * 1.14 + 0.5)
		modalScale = math.clamp(math.min((viewport.X * 0.94) / modalWidthPx, (viewport.Y * 0.86) / modalHeightPx), 0.5, 0.84)
		titleY = 16
		titleHeight = 38
		titleTextSize = 38
		helperY = 52
		helperHeight = 20
		helperTextSize = 15
		closeY = 16
		closeSize = 46
		closeTextSize = 26
		progressY = 82
		progressHeight = 32
		progressTextSize = 15
	else
		local modalWidthScale = 0.72
		local modalHeightScale = 0.82
		modalWidthPx = math.floor(viewport.X * modalWidthScale + 0.5)
		modalHeightPx = math.floor(viewport.Y * modalHeightScale + 0.5)
		headerHeight = 140
		sidePadding = 22
		bodyGap = 14
		cellPadding = 18
		local frameWidth = modalWidthPx - (sidePadding * 2)
		columns = frameWidth >= 920 and 4 or (frameWidth >= 700 and 3 or 2)
		cellWidth = math.floor((frameWidth - (cellPadding * (columns - 1))) / columns)
		cellWidth = math.clamp(cellWidth, 210, 300)
		cellHeight = math.floor(cellWidth * 1.16 + 0.5)
		titleY = 18
		titleHeight = 42
		titleTextSize = 42
		helperY = 60
		helperHeight = 22
		helperTextSize = 17
		closeY = 18
		closeSize = 48
		closeTextSize = 28
		progressY = 90
		progressHeight = 34
		progressTextSize = 16
	end

	indexModalScale.Scale = modalScale
	indexModal.Position = UDim2.fromOffset(math.floor(viewport.X * 0.5 + 0.5), math.floor(viewport.Y * (isLandscapeMobile and 0.5 or 0.5) + 0.5))
	indexModal.Size = UDim2.fromOffset(modalWidthPx, modalHeightPx)
	modalCorner.CornerRadius = UDim.new(0, isMobile and 26 or 28)
	modalBgCorner.CornerRadius = modalCorner.CornerRadius
	modalStroke.Thickness = isLandscapeMobile and 2 or 3
	modalHeader.Size = UDim2.new(1, 0, 0, headerHeight)
	indexFrame.Position = UDim2.new(0, sidePadding, 0, headerHeight + bodyGap)
	indexFrame.Size = UDim2.new(1, -(sidePadding * 2), 1, -(headerHeight + bodyGap + sidePadding))
	indexFrame.ScrollBarThickness = isLandscapeMobile and 10 or (isMobile and 12 or 18)
	layout.FillDirectionMaxCells = columns
	layout.CellPadding = UDim2.fromOffset(cellPadding, cellPadding)
	layout.CellSize = UDim2.fromOffset(cellWidth, cellHeight)

	titleLabel.Position = UDim2.fromOffset(sidePadding, titleY)
	titleLabel.Size = UDim2.new(1, -(sidePadding * 2) - 72, 0, titleHeight)
	titleLabel.TextSize = titleTextSize
	titleLabel.TextXAlignment = isLandscapeMobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left

	helperLabel.Position = UDim2.fromOffset(sidePadding, helperY)
	helperLabel.Size = UDim2.new(1, -(sidePadding * 2) - 72, 0, helperHeight)
	helperLabel.TextSize = helperTextSize
	helperLabel.TextXAlignment = isLandscapeMobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left

	closeButton.Position = UDim2.new(1, -sidePadding, 0, closeY)
	closeButton.Size = UDim2.fromOffset(closeSize, closeSize)
	closeButton.TextSize = closeTextSize

	progressContainer.Position = UDim2.new(0, sidePadding, 0, progressY)
	progressContainer.Size = UDim2.new(1, -(sidePadding * 2), 0, progressHeight)
	progressLabel.TextSize = progressTextSize
end

applyIndexModalLayout()

local function bindIndexLayoutCamera(camera)
	if not camera then
		return
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyIndexModalLayout)
end

bindIndexLayoutCamera(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindIndexLayoutCamera(Workspace.CurrentCamera)
	applyIndexModalLayout()
end)

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
							part.Transparency = 0.9
						end
						part.CanCollide = false
					end
				end
			end
		end
	end

	-- 3. Aktualizacja pasków i tekstów
	local percentage = (total > 0) and (collected / total) or 0
	local remaining = math.max(total - collected, 0)

	currentBrainrotCollected = collected
	currentBrainrotTotal = total
	topProgressLabel.Text = formatBrainrotProgressText(collected, total)
	topProgressFill:TweenSize(UDim2.fromScale(percentage, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)

	helperLabel.Text = (remaining == 0 and total > 0) and "ALBUM COMPLETE" or (remaining .. " LEFT TO FIND")
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

local function getActivePetName()
	local activePetsFolder = Workspace:FindFirstChild("ActivePets")
	if not activePetsFolder then
		return nil
	end

	local pet = activePetsFolder:FindFirstChild(player.Name .. "_ActivePet")
	return pet and pet:GetAttribute("PetName")
end

local function getCardAccentColor(rarity, timeValue)
	local t = timeValue or tick()
	if rarity == "Brainrot God" then
		return Color3.fromHSV((t % 3) / 3, 1, 1)
	elseif rarity == "Secret" then
		local shine = (math.sin(t * 3) + 1) / 2
		return Color3.new(shine, shine, shine)
	end

	return (RarityColors[rarity] or HudTileStyle.BaseStrokeColor):Lerp(HudTileStyle.BaseStrokeColor, 0.35)
end

local function getCardTileColor(rarity, timeValue)
	local accent = getCardAccentColor(rarity, timeValue)
	local neutral = Color3.fromRGB(126, 132, 138)
	local shadow = Color3.fromRGB(46, 52, 60)
	return accent:Lerp(neutral, 0.68):Lerp(shadow, 0.18)
end

local function refreshIndex(preserveScrollPosition)
	local savedCanvasPosition = preserveScrollPosition and indexFrame.CanvasPosition or Vector2.zero
	local indexMetrics = HudTileStyle.getLayoutMetrics()
	local compactLandscapeCards = indexMetrics.IsLandscapeMobile
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

		local isCollected = collectedBrainrots[wzorzec.Name]
		local accentColor = getCardAccentColor(rarity)
		local tileColor = getCardTileColor(rarity)
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
		local userRebirths = (rebirths and rebirths.Value) or 0
		local reqLevel = GameConfig.GetPetRequirementForRarity(rarity)
		local canEquipPet = userRebirths >= reqLevel
		local isEquipped = isCollected and (getActivePetName() == wzorzec.Name)

		local itemFrame = Instance.new("Frame")
		itemFrame.Name = string.format("%02d_%s", order, wzorzec.Name)
		itemFrame:SetAttribute("RarityKey", rarity)
		itemFrame:SetAttribute("IsCollected", isCollected)
		itemFrame.BackgroundColor3 = tileColor:Lerp(Color3.fromRGB(24, 27, 32), isCollected and 0.55 or 0.48)
		itemFrame.BackgroundTransparency = isCollected and 0.04 or 0.08
		itemFrame.BorderSizePixel = 0
		itemFrame.ClipsDescendants = true
		itemFrame.ZIndex = 51
		itemFrame.Parent = indexFrame
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, compactLandscapeCards and 16 or 18)
		itemCorner.Parent = itemFrame
		local itemStroke = Instance.new("UIStroke")
		itemStroke.Name = "ItemStroke"
		itemStroke.Thickness = compactLandscapeCards and 1.6 or 2
		itemStroke.Color = accentColor
		itemStroke.Transparency = isCollected and 0.08 or 0.18
		itemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		itemStroke.Parent = itemFrame
		local itemBg = Instance.new("ImageLabel")
		itemBg.Name = "TileBg"
		itemBg.Size = UDim2.fromScale(1, 1)
		itemBg.BackgroundTransparency = 1
		itemBg.Image = GreenStudsTexture
		itemBg.ImageColor3 = tileColor
		itemBg.ImageTransparency = isCollected and 0.78 or 0.84
		itemBg.ScaleType = Enum.ScaleType.Tile
		itemBg.TileSize = UDim2.fromOffset(compactLandscapeCards and 80 or 92, compactLandscapeCards and 80 or 92)
		itemBg.ZIndex = 51
		itemBg.Parent = itemFrame
		local itemBgCorner = Instance.new("UICorner")
		itemBgCorner.CornerRadius = UDim.new(0, compactLandscapeCards and 16 or 18)
		itemBgCorner.Parent = itemBg
		local itemGradient = Instance.new("UIGradient")
		itemGradient.Name = "ItemGradient"
		itemGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, tileColor:Lerp(Color3.fromRGB(78, 84, 92), 0.55)),
			ColorSequenceKeypoint.new(1, tileColor:Lerp(Color3.fromRGB(18, 22, 28), 0.72)),
		})
		itemGradient.Rotation = 90
		itemGradient.Parent = itemFrame

		local previewHolder = Instance.new("Frame")
		previewHolder.Name = "PreviewHolder"
		previewHolder.Size = UDim2.new(1, compactLandscapeCards and -8 or -18, compactLandscapeCards and 0.48 or 0.52, 0)
		previewHolder.Position = UDim2.new(0.5, 0, 0, compactLandscapeCards and 6 or 12)
		previewHolder.AnchorPoint = Vector2.new(0.5, 0)
		previewHolder.BackgroundColor3 = Color3.fromRGB(88, 96, 92)
		previewHolder.BorderSizePixel = 0
		previewHolder.ZIndex = 53
		previewHolder.Parent = itemFrame
		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, compactLandscapeCards and 12 or 14)
		previewCorner.Parent = previewHolder
		local previewBg = Instance.new("ImageLabel")
		previewBg.Name = "PreviewBg"
		previewBg.Size = UDim2.fromScale(1, 1)
		previewBg.BackgroundTransparency = 1
		previewBg.Image = GreenStudsTexture
		previewBg.ImageColor3 = Color3.fromRGB(122, 146, 126)
		previewBg.ImageTransparency = 0.92
		previewBg.ScaleType = Enum.ScaleType.Tile
		previewBg.TileSize = UDim2.fromOffset(compactLandscapeCards and 78 or 96, compactLandscapeCards and 78 or 96)
		previewBg.ZIndex = 53
		previewBg.Parent = previewHolder
		local previewBgCorner = Instance.new("UICorner")
		previewBgCorner.CornerRadius = UDim.new(0, compactLandscapeCards and 12 or 14)
		previewBgCorner.Parent = previewBg
		local previewStroke = Instance.new("UIStroke")
		previewStroke.Name = "PreviewStroke"
		previewStroke.Thickness = compactLandscapeCards and 1.2 or 1.5
		previewStroke.Color = accentColor
		previewStroke.Transparency = 0.3
		previewStroke.Parent = previewHolder

		local previewViewport = createViewport(wzorzec, previewHolder, isCollected, compactLandscapeCards and {
			distanceMultiplier = 0.64,
		} or nil)
		previewViewport.Name = "PreviewViewport"
		previewViewport.Size = UDim2.new(1, compactLandscapeCards and 0 or -2, 1, compactLandscapeCards and 0 or -2)
		previewViewport.Position = UDim2.new(0.5, 0, 0.5, 0)
		previewViewport.AnchorPoint = Vector2.new(0.5, 0.5)
		previewViewport.ZIndex = 54

		local infoContainer = Instance.new("Frame")
		infoContainer.Name = "InfoContainer"
		infoContainer.Size = UDim2.new(1, compactLandscapeCards and -18 or -20, 0, compactLandscapeCards and 126 or 94)
		infoContainer.Position = UDim2.new(0.5, 0, 1, -12)
		infoContainer.AnchorPoint = Vector2.new(0.5, 1)
		infoContainer.BackgroundTransparency = 1
		infoContainer.ZIndex = 55
		infoContainer.Parent = itemFrame

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Name = "RarityLabel"
		rarityLabel.Position = UDim2.new(0, 0, 0, compactLandscapeCards and 2 or 0)
		rarityLabel.Size = UDim2.new(1, 0, 0, compactLandscapeCards and 20 or 18)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = string.upper(rarity)
		rarityLabel.TextColor3 = accentColor
		rarityLabel.Font = Enum.Font.FredokaOne
		rarityLabel.TextScaled = true
		rarityLabel.ZIndex = 56
		rarityLabel.Parent = infoContainer
		local rarityConstraint = Instance.new("UITextSizeConstraint")
		rarityConstraint.MinTextSize = compactLandscapeCards and 9 or 14
		rarityConstraint.MaxTextSize = compactLandscapeCards and 14 or 20
		rarityConstraint.Parent = rarityLabel

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Position = UDim2.new(0, 0, 0, compactLandscapeCards and 24 or 20)
		nameLabel.Size = UDim2.new(1, -2, 0, compactLandscapeCards and 52 or 40)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = isCollected and wzorzec.Name or "???"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.LuckiestGuy
		nameLabel.TextScaled = true
		nameLabel.TextWrapped = true
		nameLabel.TextYAlignment = compactLandscapeCards and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
		nameLabel.ZIndex = 56
		nameLabel.Parent = infoContainer
		local nameConstraint = Instance.new("UITextSizeConstraint")
		nameConstraint.MinTextSize = compactLandscapeCards and 9 or 18
		nameConstraint.MaxTextSize = compactLandscapeCards and 15 or 28
		nameConstraint.Parent = nameLabel
		local nameStroke = Instance.new("UIStroke")
		nameStroke.Thickness = compactLandscapeCards and 2 or 2.5
		nameStroke.Color = Color3.new(0, 0, 0)
		nameStroke.Parent = nameLabel

		if isCollected then
			local lockedEquipText = reqLevel <= 0 and "EQUIP" or ("REBIRTH " .. reqLevel .. " REQUIRED")
			local equipBtn = Instance.new("TextButton")
			equipBtn.Name = "EquipButton"
			equipBtn.Size = UDim2.new(1, 0, 0, compactLandscapeCards and 24 or 34)
			equipBtn.Position = UDim2.new(0.5, 0, 1, 0)
			equipBtn.AnchorPoint = Vector2.new(0.5, 1)
			equipBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(53, 156, 96) or (canEquipPet and Color3.fromRGB(57, 117, 194) or Color3.fromRGB(96, 101, 111))
			equipBtn.Text = isEquipped and "EQUIPPED" or (canEquipPet and "EQUIP" or lockedEquipText)
			equipBtn.TextColor3 = Color3.new(1, 1, 1)
			equipBtn.Font = Enum.Font.LuckiestGuy
			equipBtn.TextScaled = true
			equipBtn.TextWrapped = true
			equipBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
			equipBtn.TextStrokeTransparency = 0.15
			equipBtn.AutoButtonColor = false
			equipBtn.ZIndex = 57
			equipBtn.Parent = infoContainer
			local equipConstraint = Instance.new("UITextSizeConstraint")
			equipConstraint.MinTextSize = compactLandscapeCards and 10 or 13
			equipConstraint.MaxTextSize = compactLandscapeCards and 15 or 22
			equipConstraint.Parent = equipBtn
			local equipCorner = Instance.new("UICorner")
			equipCorner.CornerRadius = UDim.new(0, compactLandscapeCards and 8 or 10)
			equipCorner.Parent = equipBtn
			local equipStroke = Instance.new("UIStroke")
			equipStroke.Name = "StatusStroke"
			equipStroke.Thickness = compactLandscapeCards and 1.5 or 2
			equipStroke.Color = Color3.new(0, 0, 0)
			equipStroke.Transparency = 0.02
			equipStroke.Parent = equipBtn
			
			if canEquipPet then
				equipBtn.MouseButton1Click:Connect(function()
					if not TogglePetEvent then
						return
					end
					
					equipBtn.Text = "..."
					local success, response = TogglePetEvent:InvokeServer(wzorzec.Name)
					
					if success then
						equipBtn.Text = string.upper(response)
						task.wait(0.2)
						refreshIndex(true)
					else
						equipBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
						equipBtn.Text = string.upper(response)
						task.wait(2)
						refreshIndex(true)
					end
				end)
			end
		else
			local missingLabel = Instance.new("TextLabel")
			missingLabel.Name = "MissingLabel"
			missingLabel.Size = UDim2.new(1, 0, 0, compactLandscapeCards and 24 or 30)
			missingLabel.Position = UDim2.new(0.5, 0, 1, 0)
			missingLabel.AnchorPoint = Vector2.new(0.5, 1)
			missingLabel.BackgroundColor3 = Color3.fromRGB(18, 21, 27)
			missingLabel.BackgroundTransparency = 0.06
			missingLabel.Text = "MISSING"
			missingLabel.TextColor3 = accentColor
			missingLabel.Font = Enum.Font.LuckiestGuy
			missingLabel.TextScaled = true
			missingLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
			missingLabel.TextStrokeTransparency = 0.12
			missingLabel.ZIndex = 57
			missingLabel.Parent = infoContainer
			local missingConstraint = Instance.new("UITextSizeConstraint")
			missingConstraint.MinTextSize = compactLandscapeCards and 10 or 16
			missingConstraint.MaxTextSize = compactLandscapeCards and 15 or 24
			missingConstraint.Parent = missingLabel
			local missingCorner = Instance.new("UICorner")
			missingCorner.CornerRadius = UDim.new(0, compactLandscapeCards and 8 or 10)
			missingCorner.Parent = missingLabel
			local missingStroke = Instance.new("UIStroke")
			missingStroke.Name = "StatusStroke"
			missingStroke.Thickness = compactLandscapeCards and 1.5 or 2
			missingStroke.Color = Color3.new(0, 0, 0)
			missingStroke.Transparency = 0.02
			missingStroke.Parent = missingLabel
		end
	end
	updateProgressBar()
	if preserveScrollPosition then
		task.defer(function()
			RunService.Heartbeat:Wait()
			local maxCanvasY = math.max(indexFrame.AbsoluteCanvasSize.Y - indexFrame.AbsoluteWindowSize.Y, 0)
			indexFrame.CanvasPosition = Vector2.new(savedCanvasPosition.X, math.clamp(savedCanvasPosition.Y, 0, maxCanvasY))
		end)
	end
end

local function toggleUI(visible)
	if visible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "BrainrotCollector" then closeFunc() end
		end
	end
	
	indexBackdrop.Visible = visible
	
	if visible then
		TweenService:Create(openButton, TweenInfo.new(0.2), {Rotation = 15}):Play()
	else
		TweenService:Create(openButton, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
	
	-- Ukrywamy HUD (monety), by nie zaśmiecał ekranu przy Indeksie
	local hudGui = playerGui:FindFirstChild("HUD_Standalone_UI")
	if hudGui then
		hudGui.Enabled = not visible
	end
	
	if visible then
		applyIndexModalLayout()
		updateProgressBar()
		refreshIndex(false)
		indexFrame.CanvasPosition = Vector2.zero
	end
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["BrainrotCollector"] = function()
	if indexBackdrop and indexBackdrop.Visible then
		toggleUI(false)
	end
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
	scheduleRebirthReadyAnnouncement(model.Name, rarity)

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

			if targetPosition and (targetPosition - rootPart.Position).Magnitude < CLIENT_COLLECT_DISTANCE then
				collectBrainrot(model)
			end
		end
	end
end

openButton.MouseButton1Click:Connect(function()
	toggleUI(not indexBackdrop.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
	toggleUI(false)
end)

RunService.RenderStepped:Connect(function()
	-- Wklej to wewnątrz RunService.RenderStepped:Connect(function()

	local t = tick()
	local rainbow = Color3.fromHSV(t % 3 / 3, 1, 1)

	indexText.TextColor3 = HudTileStyle.BaseLabelColor
	titleLabel.TextColor3 = HudTileStyle.BaseLabelColor
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

	if indexBackdrop.Visible then
		for _, frame in pairs(indexFrame:GetChildren()) do
			if frame:IsA("Frame") then
				local rarityKey = frame:GetAttribute("RarityKey")
				if rarityKey == "Brainrot God" or rarityKey == "Secret" then
					local accentColor = getCardAccentColor(rarityKey, t)
					local itemStroke = frame:FindFirstChild("ItemStroke")
					if itemStroke then
						itemStroke.Color = accentColor
					end
					local previewHolder = frame:FindFirstChild("PreviewHolder")
					local previewStroke = previewHolder and previewHolder:FindFirstChild("PreviewStroke")
					if previewStroke then
						previewStroke.Color = accentColor
					end
					local infoContainer = frame:FindFirstChild("InfoContainer")
					if infoContainer then
						local rarityLabel = infoContainer:FindFirstChild("RarityLabel")
						if rarityLabel then
							rarityLabel.TextColor3 = accentColor
						end
						local missingLabel = infoContainer:FindFirstChild("MissingLabel")
						if missingLabel then
							missingLabel.TextColor3 = accentColor
							missingLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
							missingLabel.TextStrokeTransparency = 0
							local statusStroke = missingLabel:FindFirstChild("StatusStroke")
							if statusStroke then
								statusStroke.Color = Color3.new(0, 0, 0)
								statusStroke.Transparency = 0
							end
						end
					end
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
	isRebirthing = true
	resetRebirthReadyAnnouncementState()
	
	-- Szybkie czyszczenie kolekcji i mapy w jednym kroku (Zabezpieczenie przed ściną)
	table.clear(collectedBrainrots)
	
	if BrainrotyFolder and BrainrotStorage then
		for _, mapModel in ipairs(BrainrotyFolder:GetChildren()) do
			local storageModel = BrainrotStorage:FindFirstChild(mapModel.Name)
			if storageModel then
				for _, storagePart in ipairs(storageModel:GetDescendants()) do
					if storagePart:IsA("BasePart") then
						local mapPart = mapModel:FindFirstChild(storagePart.Name, true)
						if mapPart and mapPart:IsA("BasePart") then
							mapPart.Transparency = storagePart.Transparency
						end
					end
				end
			end
		end
	end
	
	if updateProgressBar then
		updateProgressBar()
	end
	
	if indexBackdrop.Visible then
		refreshIndex(false)
	end
	
	task.delay(2, function()
		isRebirthing = false
	end)
end)

task.spawn(function()
	local collection = player:WaitForChild("BrainrotCollection")
	collection.ChildRemoved:Connect(function(child)
		if isRebirthing then return end -- Blokada podczas Rebirth!
		
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
				if indexBackdrop.Visible then
					refreshIndex(false)
				end
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
		
		-- Czekamy by większość mapy się załadowała
		task.wait(1)
		updateProgressBar()
		
		-- Obsługa dosłanego strumieniowania mapy (StreamingEnabled)
		if BrainrotyFolder then
			BrainrotyFolder.ChildAdded:Connect(function(modelNaMapie)
				if modelNaMapie:IsA("Model") and collectedBrainrots[modelNaMapie.Name] then
					-- Czekamy na wczytanie partów modelu
					task.wait(0.2)
					for _, part in ipairs(modelNaMapie:GetDescendants()) do
						if part:IsA("BasePart") then
							if part.Transparency < 1 then
								part.Transparency = 0.9
							end
							part.CanCollide = false
						end
					end
				end
			end)
		end
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
		if safeName == REBIRTH_READY_TARGET and not collectedBrainrots[safeName] then
			return
		end

		if CollectSound then CollectSound:Play() end
		-- Dodajemy do kolejki powiadomień
		table.insert(notificationQueue, {name = safeName, rarity = safeRarity})
		scheduleRebirthReadyAnnouncement(safeName, safeRarity)

		updateProgressBar()
		if indexFrame.Visible then refreshIndex(true) end
	end)
end)

OgBrainrotDiscoveryAnnouncement.OnClientEvent:Connect(function(finderName, brainrotName, rarity)
	table.insert(globalAnnouncementQueue, {
		finderName = tostring(finderName or "Someone"),
		brainrotName = tostring(brainrotName or "Strawberry Elephant"),
		rarity = tostring(rarity or "OG"),
	})
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
robuxLabel.Text = formatCoinRainProgressText(0, currentCoinRainMax)
robuxLabel.TextColor3 = Color3.new(1, 1, 1)
robuxLabel.Font = Enum.Font.SourceSansBold
robuxLabel.TextSize = 20
robuxLabel.TextScaled = true
robuxLabel.TextWrapped = false
robuxLabel.TextYAlignment = Enum.TextYAlignment.Center
robuxLabel.ZIndex = 5

local robuxTextConstraint = Instance.new("UITextSizeConstraint")
robuxTextConstraint.MinTextSize = 10
robuxTextConstraint.MaxTextSize = 20
robuxTextConstraint.Parent = robuxLabel

local topStatusLayoutConnection

local function applyTopStatusLayout()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local insetTopLeft, _ = GuiService:GetGuiInset()
	local hudMetrics = HudTileStyle.getLayoutMetrics()
	local isMobile = hudMetrics.IsMobile
	local isLandscapeMobile = hudMetrics.IsLandscapeMobile

	local sidePadding
	local gapBetweenBars
	local coinsHudWidth
	local coinsHudRightPadding
	local gapToCoinsHud
	local desiredBrainrotWidth
	local desiredCoinWidth
	local brainrotHeight
	local coinHeight
	local rowTop
	local compactLayout

	if isLandscapeMobile then
		sidePadding = math.clamp(viewport.X * 0.012, 6, 12)
		gapBetweenBars = math.clamp(viewport.X * 0.006, 6, 10)
		coinsHudWidth = math.clamp(viewport.X * 0.19, 122, 138)
		coinsHudRightPadding = math.clamp(viewport.X * 0.010, 7, 12)
		gapToCoinsHud = math.clamp(viewport.X * 0.012, 10, 14)
		desiredBrainrotWidth = math.clamp(viewport.X * 0.32, 190, 206)
		desiredCoinWidth = math.clamp(viewport.X * 0.185, 108, 122)
		brainrotHeight = 28
		coinHeight = 30
		rowTop = math.max(math.floor(insetTopLeft.Y * 0.10 + 0.5), 10)
		compactLayout = true
	elseif isMobile then
		sidePadding = math.clamp(viewport.X * 0.016, 10, 18)
		gapBetweenBars = math.clamp(viewport.X * 0.0075, 7, 12)
		coinsHudWidth = math.clamp(viewport.X * 0.34, 150, 188)
		coinsHudRightPadding = math.clamp(viewport.X * 0.015, 10, 16)
		gapToCoinsHud = math.clamp(viewport.X * 0.010, 8, 14)
		desiredBrainrotWidth = math.clamp(viewport.X * 0.56, 236, 340)
		desiredCoinWidth = math.clamp(viewport.X * 0.27, 124, 176)
		brainrotHeight = 38
		coinHeight = 36
		rowTop = math.max(math.floor(insetTopLeft.Y * 0.16 + 0.5), 20)
		compactLayout = true
	else
		sidePadding = math.clamp(viewport.X * 0.02, 12, 24)
		gapBetweenBars = math.clamp(viewport.X * 0.0085, 8, 18)
		coinsHudWidth = 210
		coinsHudRightPadding = 20
		gapToCoinsHud = math.clamp(viewport.X * 0.015, 26, 36)
		desiredBrainrotWidth = math.clamp(viewport.X * 0.285, 300, 540)
		desiredCoinWidth = math.clamp(viewport.X * 0.145, 170, 280)
		compactLayout = viewport.X < 1180
		brainrotHeight = compactLayout and 40 or 46
		coinHeight = compactLayout and 34 or 36
		rowTop = math.max(math.floor(insetTopLeft.Y * 0.18 + 0.5), compactLayout and 24 or 28)
	end

	local availableWidth = math.max(viewport.X - sidePadding - (coinsHudWidth + coinsHudRightPadding + gapToCoinsHud), 250)
	local totalDesiredWidth = desiredBrainrotWidth + desiredCoinWidth + gapBetweenBars
	local layoutScale = totalDesiredWidth > availableWidth and (availableWidth / totalDesiredWidth) or 1
	local brainrotWidth = math.floor(desiredBrainrotWidth * layoutScale + 0.5)
	local coinWidth = math.floor(desiredCoinWidth * layoutScale + 0.5)
	local appliedGap = math.max(isLandscapeMobile and 6 or 8, math.floor(gapBetweenBars * layoutScale + 0.5))
	if not isMobile then
		compactLayout = compactLayout or coinWidth < 210 or brainrotWidth < 340
		brainrotHeight = compactLayout and 40 or 46
		coinHeight = compactLayout and 34 or 36
		rowTop = math.max(math.floor(insetTopLeft.Y * 0.18 + 0.5), compactLayout and 24 or 28)
	end
	local coinLeft = math.floor(viewport.X - coinsHudWidth - coinsHudRightPadding - gapToCoinsHud - coinWidth + 0.5)
	local elephantSize = math.clamp(
		math.floor(brainrotWidth * (isLandscapeMobile and 0.17 or (compactLayout and 0.30 or 0.24)) + 0.5),
		isLandscapeMobile and 30 or (compactLayout and 50 or 72),
		isLandscapeMobile and 38 or (compactLayout and 72 or 88)
	)
	local elephantInset = math.floor(elephantSize * (isLandscapeMobile and 0.18 or 0.42) + 0.5)
	local brainrotCenteredLeft = math.floor(((viewport.X - brainrotWidth) * 0.5) + 0.5)
	local brainrotVisualOverhang = isLandscapeMobile and math.floor(elephantSize * 0.22 + 0.5) or 0
	local leftHudClearance = isLandscapeMobile and math.clamp(math.floor(viewport.X * 0.235 + 0.5), 148, 160) or sidePadding
	local brainrotLeft = brainrotCenteredLeft
	if isLandscapeMobile then
		local maxBrainrotLeft = coinLeft - appliedGap - brainrotWidth - brainrotVisualOverhang
		brainrotLeft = math.max(leftHudClearance, math.min(brainrotCenteredLeft, maxBrainrotLeft))
	else
		brainrotLeft = math.max(sidePadding, brainrotCenteredLeft)
	end

	useCompactTopStatusText = compactLayout and not isMobile
	useWrappedMobileCoinRainText = isMobile
	showMobileCoinRainSuffix = not isMobile
	topProgressContainer.AnchorPoint = Vector2.new(0, 0)
	topProgressContainer.Position = UDim2.fromOffset(brainrotLeft, rowTop)
	topProgressContainer.Size = UDim2.fromOffset(brainrotWidth, brainrotHeight)

	robuxContainer.AnchorPoint = Vector2.new(0, 0)
	robuxContainer.Position = UDim2.fromOffset(coinLeft, rowTop)
	robuxContainer.Size = UDim2.fromOffset(coinWidth, coinHeight)
	robuxLabel.TextWrapped = isMobile

	topStroke.Thickness = isLandscapeMobile and 1.8 or (compactLayout and 2 or 3)
	robuxStroke.Thickness = isLandscapeMobile and 1.4 or 2
	stripes.TileSize = UDim2.new(0, isLandscapeMobile and 26 or (compactLayout and 42 or 60), 1, 0)

	topProgressLabel.Position = UDim2.fromOffset(isLandscapeMobile and 6 or (compactLayout and 10 or 14), 0)
	topProgressLabel.Size = UDim2.new(1, -(elephantSize + (isLandscapeMobile and 6 or (compactLayout and 12 or 20))), 1, 0)
	topProgressTextConstraint.MinTextSize = isLandscapeMobile and 7 or (isMobile and 9 or 10)
	topProgressTextConstraint.MaxTextSize = isLandscapeMobile and 11 or (isMobile and 13 or (compactLayout and 18 or 22))

	elephantFrame.Size = UDim2.fromOffset(elephantSize, elephantSize)
	elephantFrame.Position = UDim2.new(1, -elephantInset, 0.5, 0)
	elephantBg.Size = UDim2.fromScale(isLandscapeMobile and 0.80 or 0.88, isLandscapeMobile and 0.80 or 0.88)
	bgStroke.Thickness = isLandscapeMobile and 2 or (compactLayout and 3 or 4)

	robuxTextConstraint.MinTextSize = isLandscapeMobile and 6 or (isMobile and 8 or 10)
	robuxTextConstraint.MaxTextSize = isLandscapeMobile and 9 or (isMobile and 11 or (compactLayout and 15 or 18))
	topProgressLabel.Text = formatBrainrotProgressText(currentBrainrotCollected, currentBrainrotTotal)
	robuxLabel.Text = formatCoinRainProgressText(currentCoinRainPool, currentCoinRainMax)
end

local function bindTopStatusLayoutCamera(camera)
	if topStatusLayoutConnection then
		topStatusLayoutConnection:Disconnect()
		topStatusLayoutConnection = nil
	end

	if not camera then
		return
	end

	topStatusLayoutConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyTopStatusLayout)
end

applyTopStatusLayout()
bindTopStatusLayoutCamera(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindTopStatusLayoutCamera(Workspace.CurrentCamera)
	applyTopStatusLayout()
end)

local PoolUpdated = BrainrotEvents:WaitForChild("PoolUpdated")

PoolUpdated.OnClientEvent:Connect(function(currentPool, queuedCount)
	local maxPool = GameConfig.CoinRainTriggerAmount or 1000 
	local percentage = math.clamp(currentPool / maxPool, 0, 1)
    
    -- ZAWSZE AKTUALIZUJEMY (Zgodnie z życzeniem: "ma się pasek aktualizować ciągle")
	currentCoinRainPool = currentPool
	currentCoinRainMax = maxPool
	robuxLabel.Text = formatCoinRainProgressText(currentPool, maxPool)
	TweenService:Create(robuxFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(percentage, 1)}):Play()
end)
