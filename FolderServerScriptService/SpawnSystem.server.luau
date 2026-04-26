local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")

local SpawnSystemRequest = BrainrotEvents:FindFirstChild("SpawnSystemRequest") or Instance.new("RemoteEvent")
SpawnSystemRequest.Name = "SpawnSystemRequest"
SpawnSystemRequest.Parent = BrainrotEvents

local SpawnSystemServerEvent = BrainrotEvents:FindFirstChild("SpawnSystemServerEvent") or Instance.new("BindableEvent")
SpawnSystemServerEvent.Name = "SpawnSystemServerEvent"
SpawnSystemServerEvent.Parent = BrainrotEvents

local SPAWN_MODE_MAIN = "Main"
local SPAWN_MODE_OG = "OG"
local MAIN_SPAWN_POSITION = Vector3.new(0, 4, 0)
local TELEPORT_OFFSET = Vector3.new(0, 4, 0)

local playerSpawnModes = {}
local pendingOgReturnTokens = {}
local pendingRespawnOverrides = {}

local function ensureMainSpawn()
	local existingMainSpawn = Workspace:FindFirstChild("MainSpawn")
	if existingMainSpawn then
		return existingMainSpawn
	end

	local mainSpawn = Instance.new("Part")
	mainSpawn.Name = "MainSpawn"
	mainSpawn.Size = Vector3.new(24, 1, 24)
	mainSpawn.Position = MAIN_SPAWN_POSITION
	mainSpawn.Anchored = true
	mainSpawn.CanCollide = true
	mainSpawn.Material = Enum.Material.Concrete
	mainSpawn.Color = Color3.fromRGB(70, 170, 255)
	mainSpawn.TopSurface = Enum.SurfaceType.Smooth
	mainSpawn.BottomSurface = Enum.SurfaceType.Smooth
	mainSpawn.Parent = Workspace

	return mainSpawn
end

local function getPivotFromInstance(target)
	if not target then
		return nil
	end

	if target:IsA("Model") then
		return target:GetPivot()
	end

	if target:IsA("BasePart") then
		return target.CFrame
	end

	local basePart = target:FindFirstChildWhichIsA("BasePart", true)
	return basePart and basePart.CFrame or nil
end

local function getSpawnTargetForMode(mode)
	if mode == SPAWN_MODE_OG then
		local ogSpawn = Workspace:FindFirstChild("OGSpawn")
		if ogSpawn then
			return ogSpawn
		end
	end

	return ensureMainSpawn()
end

local function setPlayerSpawnMode(player, mode)
	if not player then
		return
	end

	playerSpawnModes[player.UserId] = mode or SPAWN_MODE_MAIN
end

local function teleportPlayerToTarget(player, target)
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local targetPivot = getPivotFromInstance(target)

	if not character or not humanoidRootPart or not targetPivot then
		return false
	end

	character:PivotTo(targetPivot + TELEPORT_OFFSET)
	return true
end

local function teleportPlayerToCFrame(player, targetCFrame)
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not character or not humanoidRootPart or typeof(targetCFrame) ~= "CFrame" then
		return false
	end

	humanoidRootPart.CFrame = targetCFrame
	return true
end

local function teleportPlayerToCurrentSpawn(player)
	local spawnMode = playerSpawnModes[player.UserId] or SPAWN_MODE_MAIN
	local spawnTarget = getSpawnTargetForMode(spawnMode)
	return teleportPlayerToTarget(player, spawnTarget)
end

local function cancelPendingOgReturn(player)
	if not player then
		return
	end

	pendingOgReturnTokens[player.UserId] = nil
end

local function queueOgReturnToMainSpawn(player)
	if not player then
		return
	end

	local token = tostring(os.clock()) .. "_" .. tostring(player.UserId)
	pendingOgReturnTokens[player.UserId] = token

	task.delay(10, function()
		if player.Parent ~= Players then
			return
		end

		if pendingOgReturnTokens[player.UserId] ~= token then
			return
		end

		pendingOgReturnTokens[player.UserId] = nil
		teleportPlayerToTarget(player, ensureMainSpawn())
	end)
end

local function handleCharacterAdded(player, character)
	task.spawn(function()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoidRootPart then
			return
		end

		task.wait()

		local overrideCFrame = pendingRespawnOverrides[player.UserId]
		if overrideCFrame then
			pendingRespawnOverrides[player.UserId] = nil
			teleportPlayerToCFrame(player, overrideCFrame)
			return
		end

		teleportPlayerToCurrentSpawn(player)
	end)
end

local function registerPlayer(player)
	setPlayerSpawnMode(player, SPAWN_MODE_MAIN)

	player.CharacterAdded:Connect(function(character)
		handleCharacterAdded(player, character)
	end)

	if player.Character then
		handleCharacterAdded(player, player.Character)
	end
end

local function handleServerAction(action, player, options)
	if not player then
		return
	end

	options = options or {}

	if action == "EnterOG" then
		cancelPendingOgReturn(player)
		setPlayerSpawnMode(player, SPAWN_MODE_OG)
		teleportPlayerToTarget(player, getSpawnTargetForMode(SPAWN_MODE_OG))
		return
	end

	if action == "ReturnToMainSpawn" then
		cancelPendingOgReturn(player)
		setPlayerSpawnMode(player, SPAWN_MODE_MAIN)
		if options.teleportNow then
			teleportPlayerToTarget(player, ensureMainSpawn())
		end
		return
	end

	if action == "HandleOGCollected" then
		setPlayerSpawnMode(player, SPAWN_MODE_MAIN)
		queueOgReturnToMainSpawn(player)
		return
	end

	if action == "SetRespawnOverride" then
		local overrideCFrame = options.cframe
		if typeof(overrideCFrame) == "CFrame" then
			pendingRespawnOverrides[player.UserId] = overrideCFrame
		end
	end
end

SpawnSystemRequest.OnServerEvent:Connect(function(player, action)
	if action == "ReturnToMainSpawn" then
		handleServerAction("ReturnToMainSpawn", player, { teleportNow = true })
	end
end)

SpawnSystemServerEvent.Event:Connect(function(action, player, options)
	handleServerAction(action, player, options)
end)

ensureMainSpawn()

for _, player in ipairs(Players:GetPlayers()) do
	registerPlayer(player)
end

Players.PlayerAdded:Connect(registerPlayer)

Players.PlayerRemoving:Connect(function(player)
	playerSpawnModes[player.UserId] = nil
	pendingOgReturnTokens[player.UserId] = nil
	pendingRespawnOverrides[player.UserId] = nil
end)
