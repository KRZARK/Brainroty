local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotEvents = ReplicatedStorage:FindFirstChild("BrainrotEvents")
if not BrainrotEvents then
	BrainrotEvents = Instance.new("Folder")
	BrainrotEvents.Name = "BrainrotEvents"
	BrainrotEvents.Parent = ReplicatedStorage
end

local UpdateGameplaySettingRF = BrainrotEvents:FindFirstChild("UpdateGameplaySetting")
if not UpdateGameplaySettingRF then
	UpdateGameplaySettingRF = Instance.new("RemoteFunction")
	UpdateGameplaySettingRF.Name = "UpdateGameplaySetting"
	UpdateGameplaySettingRF.Parent = BrainrotEvents
end

local DEFAULT_PLAYER_SETTINGS = {
	SpeedSettingEnabled = true,
	JumpSettingEnabled = true,
	VIPProtectionEnabled = false,
}

local watchedAttributes = {
	"HasVIP",
	"HasSpeedBoost",
	"HasJumpBoost",
	"SpeedSettingEnabled",
	"JumpSettingEnabled",
	"SpeedBoostEnds",
	"JumpBoostEnds",
}

local playerConnections = {}
local statMaintenanceTokens = {}
local timedRefreshTokens = {}

local function getRebirthMultiplier(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0

	if rebirthCount == 1 then
		return 1.25
	elseif rebirthCount == 2 then
		return 1.5
	elseif rebirthCount >= 3 then
		return 2
	end

	return 1
end

local function computeMovementStats(player)
	local hasVIP = player:GetAttribute("HasVIP") == true
	local speedEnabled = player:GetAttribute("SpeedSettingEnabled")
	local jumpEnabled = player:GetAttribute("JumpSettingEnabled")
	local ownsSpeedBoost = hasVIP or player:GetAttribute("HasSpeedBoost") == true
	local ownsJumpBoost = hasVIP or player:GetAttribute("HasJumpBoost") == true
	local speedBoostEnds = player:GetAttribute("SpeedBoostEnds") or 0
	local jumpBoostEnds = player:GetAttribute("JumpBoostEnds") or 0
	local speedMultiplier = os.time() < speedBoostEnds and 2 or 1
	local jumpMultiplier = os.time() < jumpBoostEnds and 2 or 1
	local rebirthMultiplier = getRebirthMultiplier(player)

	if speedEnabled == nil then
		speedEnabled = true
	end

	if jumpEnabled == nil then
		jumpEnabled = true
	end

	local walkSpeed = 16
	if speedEnabled then
		local baseSpeed = ownsSpeedBoost and 32 or 16
		walkSpeed = math.floor(baseSpeed * speedMultiplier * rebirthMultiplier)
	end

	local jumpPower = 50
	if jumpEnabled then
		local baseJump = ownsJumpBoost and 100 or 50
		jumpPower = math.floor(baseJump * jumpMultiplier * rebirthMultiplier)
	end

	return walkSpeed, jumpPower
end

local function applyCurrentCharacterStats(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local walkSpeed, jumpPower = computeMovementStats(player)
	humanoid.WalkSpeed = walkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = jumpPower
end

local function scheduleTimedRefresh(player)
	timedRefreshTokens[player] = (timedRefreshTokens[player] or 0) + 1
	local token = timedRefreshTokens[player]

	task.spawn(function()
		while player.Parent and timedRefreshTokens[player] == token do
			local now = os.time()
			local nextExpiry = math.huge
			local speedBoostEnds = player:GetAttribute("SpeedBoostEnds") or 0
			local jumpBoostEnds = player:GetAttribute("JumpBoostEnds") or 0

			if speedBoostEnds > now then
				nextExpiry = math.min(nextExpiry, speedBoostEnds)
			end

			if jumpBoostEnds > now then
				nextExpiry = math.min(nextExpiry, jumpBoostEnds)
			end

			if nextExpiry == math.huge then
				return
			end

			task.wait(math.max(0.05, nextExpiry - now + 0.05))

			if not player.Parent or timedRefreshTokens[player] ~= token then
				return
			end

			applyCurrentCharacterStats(player)
		end
	end)
end

local function normalizePlayerSettings(player)
	for attributeName, defaultValue in pairs(DEFAULT_PLAYER_SETTINGS) do
		if player:GetAttribute(attributeName) == nil then
			player:SetAttribute(attributeName, defaultValue)
		end
	end

	if player:GetAttribute("HasVIP") ~= true and player:GetAttribute("VIPProtectionEnabled") == true then
		player:SetAttribute("VIPProtectionEnabled", false)
	end
end

local function disconnectPlayer(player)
	local connections = playerConnections[player]
	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	playerConnections[player] = nil
	statMaintenanceTokens[player] = nil
	timedRefreshTokens[player] = nil
end

local function bindRebirthListener(player, connections, leaderstats)
	local attached = false

	local function attachToRebirthValue(rebirths)
		if attached or not rebirths then
			return
		end

		attached = true
		table.insert(connections, rebirths:GetPropertyChangedSignal("Value"):Connect(function()
			applyCurrentCharacterStats(player)
		end))
		task.defer(applyCurrentCharacterStats, player)
	end

	local existingRebirths = leaderstats:FindFirstChild("Rebirths")
	if existingRebirths then
		attachToRebirthValue(existingRebirths)
		return
	end

	table.insert(connections, leaderstats.ChildAdded:Connect(function(child)
		if child.Name == "Rebirths" then
			attachToRebirthValue(child)
		end
	end))
end

local function bindPlayer(player)
	if playerConnections[player] then
		return
	end

	normalizePlayerSettings(player)
	playerConnections[player] = {}

	local connections = playerConnections[player]
	for _, attributeName in ipairs(watchedAttributes) do
		table.insert(connections, player:GetAttributeChangedSignal(attributeName):Connect(function()
			normalizePlayerSettings(player)
			applyCurrentCharacterStats(player)
			scheduleTimedRefresh(player)
		end))
	end

	table.insert(connections, player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			task.defer(applyCurrentCharacterStats, player)
		end
	end))

	local existingLeaderstats = player:FindFirstChild("leaderstats")
	if existingLeaderstats then
		bindRebirthListener(player, connections, existingLeaderstats)
	end

	table.insert(connections, player.ChildAdded:Connect(function(child)
		if child:IsA("Folder") and child.Name == "leaderstats" then
			bindRebirthListener(player, connections, child)
			task.defer(applyCurrentCharacterStats, player)
		end
	end))

	scheduleTimedRefresh(player)
	task.defer(applyCurrentCharacterStats, player)

	statMaintenanceTokens[player] = (statMaintenanceTokens[player] or 0) + 1
	local maintenanceToken = statMaintenanceTokens[player]
	task.spawn(function()
		while player.Parent and statMaintenanceTokens[player] == maintenanceToken do
			applyCurrentCharacterStats(player)
			task.wait(0.75)
		end
	end)
end

local function canUseVIPProtection(player)
	return player:GetAttribute("HasVIP") == true
end

UpdateGameplaySettingRF.OnServerInvoke = function(player, settingName, enabled)
	if type(settingName) ~= "string" or type(enabled) ~= "boolean" then
		return false, nil, "INVALID_REQUEST"
	end

	if settingName == "Speed" then
		player:SetAttribute("SpeedSettingEnabled", enabled)
		applyCurrentCharacterStats(player)
		return true, enabled, ""
	elseif settingName == "Jump" then
		player:SetAttribute("JumpSettingEnabled", enabled)
		applyCurrentCharacterStats(player)
		return true, enabled, ""
	elseif settingName == "VIPProtection" then
		if not canUseVIPProtection(player) then
			player:SetAttribute("VIPProtectionEnabled", false)
			return false, false, "LOCKED"
		end

		player:SetAttribute("VIPProtectionEnabled", enabled)
		return true, enabled, ""
	end

	return false, nil, "UNKNOWN_SETTING"
end

for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(disconnectPlayer)

print("SettingsService Server Script Loaded Successfully!")
