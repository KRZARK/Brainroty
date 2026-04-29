local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local BrainrotCollectedEvent = BrainrotEvents:WaitForChild("BrainrotCollected")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

-- === TWORZENIE UI DLA ANIMACJI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PurchaseAnimUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999 
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.fromScale(1, 1)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BackgroundTransparency = 1
blackFrame.BorderSizePixel = 0
blackFrame.Parent = screenGui

local boxImage = Instance.new("ImageLabel")
boxImage.Name = "MagicBox"
boxImage.Size = UDim2.fromOffset(0, 0)
boxImage.Position = UDim2.fromScale(0.5, 0.45)
boxImage.AnchorPoint = Vector2.new(0.5, 0.5)
boxImage.BackgroundTransparency = 1
boxImage.Image = "rbxassetid://86015085773572" 
boxImage.Parent = screenGui

-- === LOGIKA ANIMACJI ===
local isPlaying = false

local function getAnimationMetrics()
	local layoutMetrics = HudTileStyle.getLayoutMetrics()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

	if layoutMetrics.IsLandscapeMobile then
		local baseSize = math.clamp(math.floor(math.min(viewport.X * 0.52, viewport.Y * 0.9)), 300, 360)
		local shakeRange = math.max(14, math.floor(baseSize * 0.045))
		return {
			boxSize = baseSize,
			shakeRange = shakeRange,
			yScale = 0.5,
		}
	elseif layoutMetrics.IsMobile then
		local baseSize = math.clamp(math.floor(math.min(viewport.X * 0.72, viewport.Y * 0.82)), 320, 460)
		local shakeRange = math.max(16, math.floor(baseSize * 0.05))
		return {
			boxSize = baseSize,
			shakeRange = shakeRange,
			yScale = 0.47,
		}
	end

	return {
		boxSize = 700,
		shakeRange = 30,
		yScale = 0.45,
	}
end

local function playOpeningSequence()
	if isPlaying then return end
	isPlaying = true
	local animationMetrics = getAnimationMetrics()
	-- 1. Krótkie opóźnienie na start
	task.wait(0.5)

	-- 2. Przygotowanie
	boxImage.Size = UDim2.fromOffset(0, 0)
	boxImage.Rotation = 0
	boxImage.Position = UDim2.fromScale(0.5, animationMetrics.yScale)

	-- 3. Pojawienie się tła i wskok skrzynki (Rozmiar 700)
	TweenService:Create(blackFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()
	local popIn = TweenService:Create(boxImage, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(animationMetrics.boxSize, animationMetrics.boxSize)})
	popIn:Play()
	popIn.Completed:Wait()

	-- 4. Trzęsienie
	local startTime = tick()
	local duration = 1.5 -- Czas trzęsienia

	while tick() - startTime < duration do
		boxImage.Rotation = math.random(-10, 10)
		boxImage.Size = UDim2.fromOffset(
			animationMetrics.boxSize + math.random(-animationMetrics.shakeRange, animationMetrics.shakeRange),
			animationMetrics.boxSize + math.random(-animationMetrics.shakeRange, animationMetrics.shakeRange)
		)
		task.wait(0.05)
	end

	-- USUNIĘTO task.wait(1) - Skrzynka znika od razu po trzęsieniu!

	-- 5. Wybuch / Zniknięcie
	local explosion = TweenService:Create(boxImage, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0)})
	local fadeOut = TweenService:Create(blackFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1})

	explosion:Play()
	fadeOut:Play()
	explosion.Completed:Wait()
	isPlaying = false
end

-- === OBSŁUGA SYGNAŁU ===
BrainrotCollectedEvent.OnClientEvent:Connect(function(name)
	if name == "PLAY_ANIM" then
		playOpeningSequence()
	end
end)
