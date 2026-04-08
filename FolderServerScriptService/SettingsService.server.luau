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
	SelectedTrail = "DEFAULT",
}

local watchedAttributes = {
	"HasVIP",
	"HasSpeedBoost",
	"HasJumpBoost",
	"SpeedSettingEnabled",
	"JumpSettingEnabled",
	"SpeedBoostEnds",
	"JumpBoostEnds",
	"SelectedTrail",
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
	if speedEnabled == true or speedEnabled == "MAX" or speedEnabled == "DEFAULT" then
		local baseSpeed = ownsSpeedBoost and 32 or 16
		walkSpeed = math.floor(baseSpeed * speedMultiplier * rebirthMultiplier)
	elseif speedEnabled == "VIP" or speedEnabled == "GAMEPASS" then
		walkSpeed = math.floor(32 * speedMultiplier)
	elseif type(speedEnabled) == "string" and string.find(speedEnabled, "REBIRTH") then
		local rNum = tonumber(string.match(speedEnabled, "%d+"))
		local rMult = 1
		if rNum == 1 then rMult = 1.25
		elseif rNum == 2 then rMult = 1.5
		elseif rNum and rNum >= 3 then rMult = 2 end
		walkSpeed = math.floor(16 * rMult * speedMultiplier)
	elseif speedEnabled == "OFF" or speedEnabled == false then
		walkSpeed = 16
	end

	local jumpPower = 50
	if jumpEnabled == true or jumpEnabled == "MAX" or jumpEnabled == "DEFAULT" then
		local baseJump = ownsJumpBoost and 100 or 50
		jumpPower = math.floor(baseJump * jumpMultiplier * rebirthMultiplier)
	elseif jumpEnabled == "VIP" or jumpEnabled == "GAMEPASS" then
		jumpPower = math.floor(100 * jumpMultiplier)
	elseif type(jumpEnabled) == "string" and string.find(jumpEnabled, "REBIRTH") then
		local rNum = tonumber(string.match(jumpEnabled, "%d+"))
		local rMult = 1
		if rNum == 1 then rMult = 1.25
		elseif rNum == 2 then rMult = 1.5
		elseif rNum and rNum >= 3 then rMult = 2 end
		jumpPower = math.floor(50 * rMult * jumpMultiplier)
	elseif jumpEnabled == "OFF" or jumpEnabled == false then
		jumpPower = 50
	end

	return walkSpeed, jumpPower
end

local function applyCurrentTrail(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local selectedTrail = player:GetAttribute("SelectedTrail") or "DEFAULT"
	
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
	local hasVIP = player:GetAttribute("HasVIP") == true

	if selectedTrail == "DEFAULT" then
		if rebirths >= 1 then
			selectedTrail = "REBIRTH " .. math.min(rebirths, 4)
		elseif hasVIP then
			selectedTrail = "VIP"
		else
			selectedTrail = "OFF"
		end
		player:SetAttribute("SelectedTrail", selectedTrail)
	end

	local currentTrailValue = hrp:FindFirstChild("SelectedTrailValue")
	if currentTrailValue and currentTrailValue.Value == selectedTrail then
		return -- Trail is already correctly applied
	end

	-- Clean up existing trails managed by settings
	for _, child in ipairs(hrp:GetChildren()) do
		if child:IsA("Trail") and (child.Name == "SelectedPlayerTrail") then
			child:Destroy()
		end
		if child:IsA("Attachment") and (child.Name == "TrailAtt0" or child.Name == "TrailAtt1" or child.Name == "VIPTrailAtt0" or child.Name == "VIPTrailAtt1") then
			child:Destroy()
		end
		if child:IsA("Trail") and (child.Name == "RebirthTrail" or child.Name == "VIPSoloTrail") then
			child:Destroy()
		end
		if child:IsA("StringValue") and child.Name == "SelectedTrailValue" then
			child:Destroy()
		end
	end

	local newTrailValue = Instance.new("StringValue")
	newTrailValue.Name = "SelectedTrailValue"
	newTrailValue.Value = selectedTrail
	newTrailValue.Parent = hrp

	if selectedTrail == "OFF" then return end

	local isRebirth = string.match(selectedTrail, "^REBIRTH (%d+)$")
	local rebirthLevel = isRebirth and tonumber(isRebirth) or 0

	if isRebirth and rebirths >= rebirthLevel and rebirthLevel >= 1 then
		local att0 = Instance.new("Attachment")
		att0.Name = "TrailAtt0"
		att0.Position = Vector3.new(1.125, 0, 0)
		att0.Parent = hrp

		local att1 = Instance.new("Attachment")
		att1.Name = "TrailAtt1"
		att1.Position = Vector3.new(-1.125, 0, 0)
		att1.Parent = hrp

		local trail = Instance.new("Trail")
		trail.Name = "SelectedPlayerTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.8
		trail.FaceCamera = true
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		trail.LightEmission = 1
		trail.LightInfluence = 0

		if rebirthLevel == 1 then
			trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
		elseif rebirthLevel == 2 then
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		elseif rebirthLevel == 3 then
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			})
		else
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
			})
		end
		trail.Parent = hrp

	elseif selectedTrail == "VIP" and hasVIP then
		local att0 = Instance.new("Attachment")
		att0.Name = "VIPTrailAtt0"
		att0.Position = Vector3.new(1.125, 0.5, 0)
		att0.Parent = hrp

		local att1 = Instance.new("Attachment")
		att1.Name = "VIPTrailAtt1"
		att1.Position = Vector3.new(-1.125, 0.5, 0)
		att1.Parent = hrp

		local trail = Instance.new("Trail")
		trail.Name = "SelectedPlayerTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.8
		trail.FaceCamera = true
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		trail.LightEmission = 1
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
		})
		trail.Parent = hrp
	else
		-- If they selected an invalid trail, fallback to OFF
		if selectedTrail ~= "DEFAULT" then
			player:SetAttribute("SelectedTrail", "OFF")
		end
	end
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
	
	applyCurrentTrail(player)
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

UpdateGameplaySettingRF.OnServerInvoke = function(player, settingName, value)
	if type(settingName) ~= "string" then
		return false, nil, "INVALID_REQUEST"
	end

	if settingName == "Speed" then
		if type(value) ~= "boolean" and type(value) ~= "string" then return false, nil, "INVALID_TYPE" end
		player:SetAttribute("SpeedSettingEnabled", value)
		applyCurrentCharacterStats(player)
		return true, value, ""
	elseif settingName == "Jump" then
		if type(value) ~= "boolean" and type(value) ~= "string" then return false, nil, "INVALID_TYPE" end
		player:SetAttribute("JumpSettingEnabled", value)
		applyCurrentCharacterStats(player)
		return true, value, ""
	elseif settingName == "VIPProtection" then
		if type(value) ~= "boolean" then return false, nil, "INVALID_TYPE" end
		if not canUseVIPProtection(player) then
			player:SetAttribute("VIPProtectionEnabled", false)
			return false, false, "LOCKED"
		end

		player:SetAttribute("VIPProtectionEnabled", value)
		return true, value, ""
	elseif settingName == "SelectedTrail" then
		if type(value) ~= "string" then return false, nil, "INVALID_TYPE" end
		player:SetAttribute("SelectedTrail", value)
		applyCurrentCharacterStats(player)
		return true, value, ""
	end

	return false, nil, "UNKNOWN_SETTING"
end

for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(disconnectPlayer)

print("SettingsService Server Script Loaded Successfully!")
