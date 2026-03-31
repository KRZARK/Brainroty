local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local UpdateQuestProgress = BrainrotEvents:WaitForChild("UpdateQuestProgress")

-- Zmienne śledzenia
local lastPos = rootPart.Position
local distanceWalked = 0
local jumpsDone = 0
local timePlayed = 0
local fallDistance = 0
local swimTime = 0
local socialTime = 0

-- Śledzenie Skoków
humanoid.Jumping:Connect(function(isActive)
	if isActive then jumpsDone += 1 end
end)

-- Główna pętla śledząca (obliczenia co klatkę)
local timeAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
	timeAccumulator += dt
	timePlayed += dt
	
	local state = humanoid:GetState()
	local currentPos = rootPart.Position
	
	-- 1. Bieganie/Chodzenie
	if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics then
		local dist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(lastPos.X, 0, lastPos.Z)).Magnitude
		distanceWalked += dist
	end
	
	-- 2. Spadanie
	if state == Enum.HumanoidStateType.Freefall then
		if lastPos.Y > currentPos.Y then
			fallDistance += (lastPos.Y - currentPos.Y)
		end
	end
	
	-- 3. Pływanie
	if state == Enum.HumanoidStateType.Swimming then
		swimTime += dt
	end
	
	-- 4. Przebywanie blisko innych (Socialize) - zasięg 15 studów
	local isNearSomeone = false
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local otherPos = otherPlayer.Character.HumanoidRootPart.Position
			if (otherPos - currentPos).Magnitude <= 15 then
				isNearSomeone = true
				break
			end
		end
	end
	if isNearSomeone then socialTime += dt end
	
	lastPos = currentPos
	
	-- Wysyłamy paczkę danych co 5 sekund na serwer
	if timeAccumulator >= 5 then
		timeAccumulator = 0
		
		if distanceWalked >= 5 then UpdateQuestProgress:FireServer("Walk", math.floor(distanceWalked)); distanceWalked = 0 end
		if jumpsDone > 0 then UpdateQuestProgress:FireServer("Jump", jumpsDone); jumpsDone = 0 end
		if fallDistance >= 5 then UpdateQuestProgress:FireServer("Fall", math.floor(fallDistance)); fallDistance = 0 end
		if math.floor(swimTime) > 0 then UpdateQuestProgress:FireServer("Swim", math.floor(swimTime)); swimTime -= math.floor(swimTime) end
		if math.floor(socialTime) > 0 then UpdateQuestProgress:FireServer("Socialize", math.floor(socialTime)); socialTime -= math.floor(socialTime) end
		
		if timePlayed >= 60 then
			UpdateQuestProgress:FireServer("PlayTime", math.floor(timePlayed / 60))
			timePlayed = timePlayed % 60
		end
	end
end)
