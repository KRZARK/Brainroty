local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService") -- Potrzebne do animacji
local AvatarEditorService = game:GetService("AvatarEditorService")

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
local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage") 
local BrainrotyFolder = Workspace:WaitForChild("Brainroty") 
local GreenStudsTexture = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")

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
screenGui.DisplayOrder = 10
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
local hasPromptedFavorite = false
local globalAnnouncementQueue = {}
local isGlobalAnnouncementShowing = false

local function getAnnouncementDisplayName(brainrotName, rarity)
	if (rarity or "") == "OG" and brainrotName == "Strawberry Elephant" then
		return "OG Brainrot Strawberry Elephant"
	end

	return brainrotName or "Strawberry Elephant"
end


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
		local distance = (radius / math.sin(fitHalfFov)) * 1.08
		local lookDirection = isNotify and Vector3.new(0, 0, 1) or Vector3.new(1, 0.48, 1).Unit
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

local function promptFavorite()
	pcall(function()
		AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end

local function showCollectionEffect(name, rarity)
	isShowingNow = true
	activeNotifyRarity = rarity

	if rarity ~= "Common" and rarity ~= "Rare" and not hasPromptedFavorite then
		hasPromptedFavorite = true
		task.delay(5, function()
			if player and player.Parent then
				promptFavorite()
			end
		end)
	end

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

local function showGlobalDiscoveryEffect(finderName, brainrotName, rarity)
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
	globalAnnouncementCard.Size = UDim2.fromOffset(900, 190)
	globalAnnouncementCard.Position = UDim2.fromScale(0.5, 0.12)
	globalAnnouncementViewportHolder.Size = UDim2.fromOffset(110, 110)
	globalShine.Position = UDim2.fromScale(-0.2, 0.5)
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
		Size = UDim2.fromOffset(980, 220),
		Position = UDim2.fromScale(0.5, 0.14),
	}):Play()
	TweenService:Create(globalCardStroke, TweenInfo.new(0.35), {Transparency = 0.05}):Play()
	TweenService:Create(globalBadge, TweenInfo.new(0.35), {BackgroundTransparency = 0.02, TextTransparency = 0}):Play()
	TweenService:Create(globalRarity, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(globalFinder, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(globalSubText, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	TweenService:Create(globalAnnouncementViewport, TweenInfo.new(0.35), {ImageTransparency = 0}):Play()
	TweenService:Create(globalAnnouncementViewportHolder, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(120, 120)
	}):Play()
	TweenService:Create(globalShine, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(1.15, 0.5),
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
		Size = UDim2.fromOffset(930, 200),
		Position = UDim2.fromScale(0.5, 0.11),
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
openButton.Position = HudTileStyle.getSlot("right", 1)
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
	side = "right",
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
progressLabel.Text = "COLLECTED: 0 / 0"
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
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local isMobile = HudTileStyle.isMobileLayout()
	local modalWidthScale = isMobile and 0.92 or 0.72
	local modalHeightScale = isMobile and 0.80 or 0.82
	local headerHeight = isMobile and 124 or 140
	local sidePadding = isMobile and 16 or 22
	local bodyGap = isMobile and 10 or 14
	local modalWidthPx = math.floor(viewport.X * modalWidthScale + 0.5)
	local frameWidth = modalWidthPx - (sidePadding * 2)
	local columns = isMobile and 2 or (frameWidth >= 780 and 3 or 2)
	local cellPadding = isMobile and 10 or 18
	local cellWidth = math.floor((frameWidth - (cellPadding * (columns - 1))) / columns)
	cellWidth = math.clamp(cellWidth, isMobile and 146 or 210, isMobile and 188 or 300)
	local cellHeight = math.floor(cellWidth * (isMobile and 1.24 or 1.16) + 0.5)

	indexModal.Size = UDim2.fromScale(modalWidthScale, modalHeightScale)
	modalHeader.Size = UDim2.new(1, 0, 0, headerHeight)
	indexFrame.Position = UDim2.new(0, sidePadding, 0, headerHeight + bodyGap)
	indexFrame.Size = UDim2.new(1, -(sidePadding * 2), 1, -(headerHeight + bodyGap + sidePadding))
	layout.FillDirectionMaxCells = columns
	layout.CellPadding = UDim2.fromOffset(cellPadding, cellPadding)
	layout.CellSize = UDim2.fromOffset(cellWidth, cellHeight)

	titleLabel.Position = UDim2.fromOffset(sidePadding, isMobile and 14 or 18)
	titleLabel.Size = UDim2.new(1, -(sidePadding * 2) - (isMobile and 58 or 72), 0, isMobile and 34 or 42)
	titleLabel.TextSize = isMobile and 30 or 42

	helperLabel.Position = UDim2.fromOffset(sidePadding, isMobile and 46 or 60)
	helperLabel.Size = UDim2.new(1, -(sidePadding * 2) - (isMobile and 58 or 72), 0, isMobile and 18 or 22)
	helperLabel.TextSize = isMobile and 13 or 17

	closeButton.Position = UDim2.new(1, -sidePadding, 0, isMobile and 14 or 18)
	closeButton.Size = UDim2.fromOffset(isMobile and 42 or 48, isMobile and 42 or 48)
	closeButton.TextSize = isMobile and 24 or 28

	progressContainer.Position = UDim2.new(0, sidePadding, 0, isMobile and 76 or 90)
	progressContainer.Size = UDim2.new(1, -(sidePadding * 2), 0, isMobile and 28 or 34)
	progressLabel.TextSize = isMobile and 13 or 16
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
	local remaining = math.max(total - collected, 0)

	topProgressLabel.Text = "BRAINROT PROGRESS: " .. collected .. " / " .. total
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
		itemCorner.CornerRadius = UDim.new(0, 18)
		itemCorner.Parent = itemFrame
		local itemStroke = Instance.new("UIStroke")
		itemStroke.Name = "ItemStroke"
		itemStroke.Thickness = 2
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
		itemBg.TileSize = UDim2.fromOffset(92, 92)
		itemBg.ZIndex = 51
		itemBg.Parent = itemFrame
		local itemBgCorner = Instance.new("UICorner")
		itemBgCorner.CornerRadius = UDim.new(0, 18)
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
		previewHolder.Size = UDim2.new(1, -18, 0.52, 0)
		previewHolder.Position = UDim2.new(0.5, 0, 0, 12)
		previewHolder.AnchorPoint = Vector2.new(0.5, 0)
		previewHolder.BackgroundColor3 = Color3.fromRGB(88, 96, 92)
		previewHolder.BorderSizePixel = 0
		previewHolder.ZIndex = 53
		previewHolder.Parent = itemFrame
		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 14)
		previewCorner.Parent = previewHolder
		local previewBg = Instance.new("ImageLabel")
		previewBg.Name = "PreviewBg"
		previewBg.Size = UDim2.fromScale(1, 1)
		previewBg.BackgroundTransparency = 1
		previewBg.Image = GreenStudsTexture
		previewBg.ImageColor3 = Color3.fromRGB(122, 146, 126)
		previewBg.ImageTransparency = 0.92
		previewBg.ScaleType = Enum.ScaleType.Tile
		previewBg.TileSize = UDim2.fromOffset(96, 96)
		previewBg.ZIndex = 53
		previewBg.Parent = previewHolder
		local previewBgCorner = Instance.new("UICorner")
		previewBgCorner.CornerRadius = UDim.new(0, 14)
		previewBgCorner.Parent = previewBg
		local previewStroke = Instance.new("UIStroke")
		previewStroke.Name = "PreviewStroke"
		previewStroke.Thickness = 1.5
		previewStroke.Color = accentColor
		previewStroke.Transparency = 0.3
		previewStroke.Parent = previewHolder

		local previewViewport = createViewport(wzorzec, previewHolder, isCollected)
		previewViewport.Name = "PreviewViewport"
		previewViewport.Size = UDim2.new(1, -2, 1, -2)
		previewViewport.Position = UDim2.new(0.5, 0, 0.5, 0)
		previewViewport.AnchorPoint = Vector2.new(0.5, 0.5)
		previewViewport.ZIndex = 54

		local infoContainer = Instance.new("Frame")
		infoContainer.Name = "InfoContainer"
		infoContainer.Size = UDim2.new(1, -20, 0, 94)
		infoContainer.Position = UDim2.new(0.5, 0, 1, -12)
		infoContainer.AnchorPoint = Vector2.new(0.5, 1)
		infoContainer.BackgroundTransparency = 1
		infoContainer.ZIndex = 55
		infoContainer.Parent = itemFrame

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Name = "RarityLabel"
		rarityLabel.Position = UDim2.new(0, 0, 0, 0)
		rarityLabel.Size = UDim2.new(1, 0, 0, 18)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = string.upper(rarity)
		rarityLabel.TextColor3 = accentColor
		rarityLabel.Font = Enum.Font.FredokaOne
		rarityLabel.TextScaled = true
		rarityLabel.ZIndex = 56
		rarityLabel.Parent = infoContainer
		local rarityConstraint = Instance.new("UITextSizeConstraint")
		rarityConstraint.MinTextSize = 14
		rarityConstraint.MaxTextSize = 20
		rarityConstraint.Parent = rarityLabel

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Position = UDim2.new(0, 0, 0, 20)
		nameLabel.Size = UDim2.new(1, 0, 0, 40)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = isCollected and wzorzec.Name or "???"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.LuckiestGuy
		nameLabel.TextScaled = true
		nameLabel.TextWrapped = true
		nameLabel.TextYAlignment = Enum.TextYAlignment.Center
		nameLabel.ZIndex = 56
		nameLabel.Parent = infoContainer
		local nameConstraint = Instance.new("UITextSizeConstraint")
		nameConstraint.MinTextSize = 18
		nameConstraint.MaxTextSize = 28
		nameConstraint.Parent = nameLabel
		local nameStroke = Instance.new("UIStroke")
		nameStroke.Thickness = 2.5
		nameStroke.Color = Color3.new(0, 0, 0)
		nameStroke.Parent = nameLabel

		if isCollected then
			local lockedEquipText = reqLevel <= 0 and "EQUIP" or ("REBIRTH " .. reqLevel .. " REQUIRED")
			local equipBtn = Instance.new("TextButton")
			equipBtn.Name = "EquipButton"
			equipBtn.Size = UDim2.new(1, 0, 0, 34)
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
			equipConstraint.MinTextSize = 13
			equipConstraint.MaxTextSize = 22
			equipConstraint.Parent = equipBtn
			local equipCorner = Instance.new("UICorner")
			equipCorner.CornerRadius = UDim.new(0, 10)
			equipCorner.Parent = equipBtn
			local equipStroke = Instance.new("UIStroke")
			equipStroke.Name = "StatusStroke"
			equipStroke.Thickness = 2
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
			missingLabel.Size = UDim2.new(1, 0, 0, 30)
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
			missingConstraint.MinTextSize = 16
			missingConstraint.MaxTextSize = 24
			missingConstraint.Parent = missingLabel
			local missingCorner = Instance.new("UICorner")
			missingCorner.CornerRadius = UDim.new(0, 10)
			missingCorner.Parent = missingLabel
			local missingStroke = Instance.new("UIStroke")
			missingStroke.Name = "StatusStroke"
			missingStroke.Thickness = 2
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
								part.Transparency = 0.8
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
		if CollectSound then CollectSound:Play() end
		-- Dodajemy do kolejki powiadomień
		table.insert(notificationQueue, {name = safeName, rarity = safeRarity})

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
robuxLabel.Text = "COIN RAIN PROGRESS: 0 / 1000 " .. utf8.char(0xE002)
robuxLabel.TextColor3 = Color3.new(1, 1, 1)
robuxLabel.Font = Enum.Font.SourceSansBold
robuxLabel.TextSize = 20
robuxLabel.ZIndex = 5

local PoolUpdated = BrainrotEvents:WaitForChild("PoolUpdated")

PoolUpdated.OnClientEvent:Connect(function(currentPool, queuedCount)
    local maxPool = GameConfig.CoinRainTriggerAmount or 1000 
    local percentage = math.clamp(currentPool / maxPool, 0, 1)
    
    -- ZAWSZE AKTUALIZUJEMY (Zgodnie z życzeniem: "ma się pasek aktualizować ciągle")
    robuxLabel.Text = "COIN RAIN PROGRESS: " .. currentPool .. " / " .. maxPool .. " " .. utf8.char(0xE002)
    TweenService:Create(robuxFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(percentage, 1)}):Play()
end)
