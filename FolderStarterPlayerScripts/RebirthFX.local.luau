local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local RebirthEffect = BrainrotEvents:WaitForChild("RebirthEffect")
local MagicSound = ReplicatedStorage:FindFirstChild("Magic") 

-- === KONFIGURACJA EFEKTÓW ===
local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_SPEED = 1.0
local CAM = workspace.CurrentCamera

-- Screen Flash setup
local flashGui = Instance.new("ScreenGui")
flashGui.Name = "RebirthFlashGui"
flashGui.IgnoreGuiInset = true
flashGui.ResetOnSpawn = false
flashGui.Parent = playerGui

local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.fromScale(1, 1)
flashFrame.BackgroundColor3 = FLASH_COLOR
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.Parent = flashGui

-- Funkcja trzęsienia kamery
local function shakeCamera(duration, intensity)
	local startTime = tick()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			player.Character.Humanoid.CameraOffset = Vector3.new(0,0,0)
			return
		end
		
		-- Narastająca intensywność
		local currentIntensity = (elapsed / duration) * intensity
		local offsetX = (math.random() - 0.5) * currentIntensity
		local offsetY = (math.random() - 0.5) * currentIntensity
		local offsetZ = (math.random() - 0.5) * currentIntensity
		
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.CameraOffset = Vector3.new(offsetX, offsetY, offsetZ)
		end
	end)
end

-- Funkcja łagodnego blasku (bezpieczna i płynna)
local function playFlashSequence()
	-- Zamiast stroboskopu - jeden, bardzo miękki i półprzejrzysty "puls"
	local glowIntensity = 0.3 -- Nie wybielamy całkiem ekranu (bezpieczniejsze dla oczu)
	local fadeTime = 1.2 -- Dłuższy czas wygaszania (płynniej)
	
	flashFrame.BackgroundTransparency = 1
	
	-- Delikatny wjazd blasku
	local fadeIn = TweenService:Create(flashFrame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = glowIntensity})
	fadeIn:Play()
	
	-- Nagły (ale nie ostry) odskok FOV
	CAM.FieldOfView = CAM.FieldOfView + 15
	
	fadeIn.Completed:Wait()
	
	-- Bardzo powolne i płynne wygaszanie
	local fadeOut = TweenService:Create(flashFrame, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
	local fovReset = TweenService:Create(CAM, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {FieldOfView = CAM.FieldOfView - 15})
	
	fadeOut:Play()
	fovReset:Play()
end

-- Nasłuchiwanie na efekt Rebirth
RebirthEffect.OnClientEvent:Connect(function()
	local character = player.Character
	if not character then return end
	
	-- 1. Kamerowe show (Trzęsienie + Zoom)
	shakeCamera(1.5, 2)
	
	local oldFOV = CAM.FieldOfView
	local zoomTween = TweenService:Create(CAM, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {FieldOfView = oldFOV - 20})
	zoomTween:Play()
	
	-- 3. SZCZYT EFEKTU (Flashe) po 1.5s
	-- 2. Efekt blasku
	playFlashSequence()
	
	-- 3. Dźwięk Magic
	if MagicSound then
		MagicSound:Play()
	end
end)
