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
	"HasPurpleTrail",
	"LatestUnlockedTrail",
	"LatestUnlockedSpeedSetting",
	"LatestUnlockedJumpSetting",
	"SpeedSettingEnabled",
	"JumpSettingEnabled",
	"SpeedBoostEnds",
	"JumpBoostEnds",
	"SelectedTrail",
}

local playerConnections = {}
local statMaintenanceTokens = {}
local timedRefreshTokens = {}
local playerTouchedTrail = {}
local playerTouchedSpeed = {}
local playerTouchedJump = {}
local playerTouchedVIPProtection = {}
local playerTrailUnlockState = {}
local playerSpeedUnlockState = {}
local playerJumpUnlockState = {}

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

local function isTrailAvailable(player, trailName)
	if trailName == "OFF" then
		return true
	end

	if trailName == "PURPLE" then
		return player:GetAttribute("HasPurpleTrail") == true
	end

	if trailName == "VIP" then
		return player:GetAttribute("HasVIP") == true
	end

	local rebirthLevel = trailName and tonumber(string.match(trailName, "^REBIRTH (%d+)$"))
	if rebirthLevel then
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
		local rebirthCount = rebirths and rebirths.Value or 0
		return rebirthCount >= rebirthLevel and rebirthLevel >= 1 and rebirthLevel <= 4
	end

	return false
end

local function getFallbackTrailForPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0

	if rebirthCount >= 1 then
		return "REBIRTH " .. math.min(rebirthCount, 4)
	end

	if player:GetAttribute("HasPurpleTrail") == true then
		return "PURPLE"
	end

	if player:GetAttribute("HasVIP") == true then
		return "VIP"
	end

	return "OFF"
end

local function getPreferredTrailForPlayer(player)
	local latestUnlockedTrail = player:GetAttribute("LatestUnlockedTrail")
	if type(latestUnlockedTrail) == "string" and latestUnlockedTrail ~= "" and isTrailAvailable(player, latestUnlockedTrail) then
		return latestUnlockedTrail
	end

	return getFallbackTrailForPlayer(player)
end

local function syncUnlockedTrailState(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0
	local hasVIP = player:GetAttribute("HasVIP") == true
	local hasPurpleTrail = player:GetAttribute("HasPurpleTrail") == true

	local state = playerTrailUnlockState[player]
	if not state then
		playerTrailUnlockState[player] = {
			rebirthCount = rebirthCount,
			hasVIP = hasVIP,
			hasPurpleTrail = hasPurpleTrail,
		}
		return
	end

	local newestUnlockedTrail
	if rebirthCount > state.rebirthCount then
		newestUnlockedTrail = "REBIRTH " .. math.min(rebirthCount, 4)
	end

	if hasPurpleTrail and not state.hasPurpleTrail then
		newestUnlockedTrail = "PURPLE"
	end

	if hasVIP and not state.hasVIP then
		newestUnlockedTrail = "VIP"
	end

	state.rebirthCount = rebirthCount
	state.hasVIP = hasVIP
	state.hasPurpleTrail = hasPurpleTrail

	if newestUnlockedTrail and isTrailAvailable(player, newestUnlockedTrail) then
		player:SetAttribute("LatestUnlockedTrail", newestUnlockedTrail)
		player:SetAttribute("SelectedTrail", newestUnlockedTrail)
	end
end

local function isSpeedSettingAvailable(player, settingName)
	if settingName == "OFF" or settingName == "DEFAULT" then
		return true
	end

	if settingName == "VIP" then
		return player:GetAttribute("HasVIP") == true
	end

	if settingName == "GAMEPASS" then
		return player:GetAttribute("HasSpeedBoost") == true
	end

	local rebirthLevel = settingName and tonumber(string.match(settingName, "^REBIRTH (%d+)$"))
	if rebirthLevel then
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
		local rebirthCount = rebirths and rebirths.Value or 0
		return rebirthCount >= rebirthLevel and rebirthLevel >= 1 and rebirthLevel <= 3
	end

	return false
end

local function getFallbackSpeedSettingForPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0

	if player:GetAttribute("HasVIP") == true then
		return "VIP"
	end

	if player:GetAttribute("HasSpeedBoost") == true then
		return "GAMEPASS"
	end

	if rebirthCount >= 1 then
		return "REBIRTH " .. math.min(rebirthCount, 3)
	end

	return "OFF"
end

local function getPreferredSpeedSettingForPlayer(player)
	local latestUnlockedSpeedSetting = player:GetAttribute("LatestUnlockedSpeedSetting")
	if type(latestUnlockedSpeedSetting) == "string" and latestUnlockedSpeedSetting ~= "" and isSpeedSettingAvailable(player, latestUnlockedSpeedSetting) then
		return latestUnlockedSpeedSetting
	end

	return getFallbackSpeedSettingForPlayer(player)
end

local function syncUnlockedSpeedState(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0
	local hasVIP = player:GetAttribute("HasVIP") == true
	local hasSpeedBoost = player:GetAttribute("HasSpeedBoost") == true

	local state = playerSpeedUnlockState[player]
	if not state then
		playerSpeedUnlockState[player] = {
			rebirthCount = rebirthCount,
			hasVIP = hasVIP,
			hasSpeedBoost = hasSpeedBoost,
		}

		if player:GetAttribute("LatestUnlockedSpeedSetting") == nil or player:GetAttribute("LatestUnlockedSpeedSetting") == "" then
			player:SetAttribute("LatestUnlockedSpeedSetting", getFallbackSpeedSettingForPlayer(player))
		end
		return
	end

	local newestUnlockedSpeed
	if rebirthCount > state.rebirthCount then
		newestUnlockedSpeed = "REBIRTH " .. math.min(rebirthCount, 3)
	end

	if hasSpeedBoost and not state.hasSpeedBoost then
		newestUnlockedSpeed = "GAMEPASS"
	end

	if hasVIP and not state.hasVIP then
		newestUnlockedSpeed = "VIP"
	end

	state.rebirthCount = rebirthCount
	state.hasVIP = hasVIP
	state.hasSpeedBoost = hasSpeedBoost

	if newestUnlockedSpeed and isSpeedSettingAvailable(player, newestUnlockedSpeed) then
		player:SetAttribute("LatestUnlockedSpeedSetting", newestUnlockedSpeed)
		player:SetAttribute("SpeedSettingEnabled", newestUnlockedSpeed)
	end
end

local function isJumpSettingAvailable(player, settingName)
	if settingName == "OFF" or settingName == "DEFAULT" then
		return true
	end

	if settingName == "VIP" then
		return player:GetAttribute("HasVIP") == true
	end

	if settingName == "GAMEPASS" then
		return player:GetAttribute("HasJumpBoost") == true
	end

	local rebirthLevel = settingName and tonumber(string.match(settingName, "^REBIRTH (%d+)$"))
	if rebirthLevel then
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
		local rebirthCount = rebirths and rebirths.Value or 0
		return rebirthCount >= rebirthLevel and rebirthLevel >= 1 and rebirthLevel <= 3
	end

	return false
end

local function getFallbackJumpSettingForPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0

	if player:GetAttribute("HasVIP") == true then
		return "VIP"
	end

	if player:GetAttribute("HasJumpBoost") == true then
		return "GAMEPASS"
	end

	if rebirthCount >= 1 then
		return "REBIRTH " .. math.min(rebirthCount, 3)
	end

	return "OFF"
end

local function getPreferredJumpSettingForPlayer(player)
	local latestUnlockedJumpSetting = player:GetAttribute("LatestUnlockedJumpSetting")
	if type(latestUnlockedJumpSetting) == "string" and latestUnlockedJumpSetting ~= "" and isJumpSettingAvailable(player, latestUnlockedJumpSetting) then
		return latestUnlockedJumpSetting
	end

	return getFallbackJumpSettingForPlayer(player)
end

local function syncUnlockedJumpState(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthCount = rebirths and rebirths.Value or 0
	local hasVIP = player:GetAttribute("HasVIP") == true
	local hasJumpBoost = player:GetAttribute("HasJumpBoost") == true

	local state = playerJumpUnlockState[player]
	if not state then
		playerJumpUnlockState[player] = {
			rebirthCount = rebirthCount,
			hasVIP = hasVIP,
			hasJumpBoost = hasJumpBoost,
		}

		if player:GetAttribute("LatestUnlockedJumpSetting") == nil or player:GetAttribute("LatestUnlockedJumpSetting") == "" then
			player:SetAttribute("LatestUnlockedJumpSetting", getFallbackJumpSettingForPlayer(player))
		end
		return
	end

	local newestUnlockedJump
	if rebirthCount > state.rebirthCount then
		newestUnlockedJump = "REBIRTH " .. math.min(rebirthCount, 3)
	end

	if hasJumpBoost and not state.hasJumpBoost then
		newestUnlockedJump = "GAMEPASS"
	end

	if hasVIP and not state.hasVIP then
		newestUnlockedJump = "VIP"
	end

	state.rebirthCount = rebirthCount
	state.hasVIP = hasVIP
	state.hasJumpBoost = hasJumpBoost

	if newestUnlockedJump and isJumpSettingAvailable(player, newestUnlockedJump) then
		player:SetAttribute("LatestUnlockedJumpSetting", newestUnlockedJump)
		player:SetAttribute("JumpSettingEnabled", newestUnlockedJump)
	end
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
	if speedEnabled == true or speedEnabled == "DEFAULT" then
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
	if jumpEnabled == true or jumpEnabled == "DEFAULT" then
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
	local hasPurpleTrail = player:GetAttribute("HasPurpleTrail") == true

	if selectedTrail == "DEFAULT" then
		selectedTrail = getPreferredTrailForPlayer(player)
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
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(64, 255, 170)),
				ColorSequenceKeypoint.new(0.22, Color3.fromRGB(0, 132, 62)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(212, 255, 239)),
				ColorSequenceKeypoint.new(0.78, Color3.fromRGB(0, 74, 28)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 230, 118))
			})
		elseif rebirthLevel == 2 then
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 222, 88)),
				ColorSequenceKeypoint.new(0.2, Color3.fromRGB(198, 110, 0)),
				ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 250, 202)),
				ColorSequenceKeypoint.new(0.76, Color3.fromRGB(156, 70, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 187, 24))
			})
		elseif rebirthLevel == 3 then
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 88, 120)),
				ColorSequenceKeypoint.new(0.24, Color3.fromRGB(132, 0, 20)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 34, 74)),
				ColorSequenceKeypoint.new(0.78, Color3.fromRGB(84, 0, 10)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 0, 56))
			})
		else
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 62, 174)),
				ColorSequenceKeypoint.new(0.18, Color3.fromRGB(255, 174, 18)),
				ColorSequenceKeypoint.new(0.36, Color3.fromRGB(68, 255, 90)),
				ColorSequenceKeypoint.new(0.54, Color3.fromRGB(34, 231, 255)),
				ColorSequenceKeypoint.new(0.72, Color3.fromRGB(70, 96, 255)),
				ColorSequenceKeypoint.new(0.88, Color3.fromRGB(196, 72, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 82, 196))
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
		trail.LightInfluence = 0
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.16, Color3.fromRGB(22, 22, 22)),
			ColorSequenceKeypoint.new(0.34, Color3.fromRGB(240, 240, 240)),
			ColorSequenceKeypoint.new(0.52, Color3.fromRGB(8, 8, 8)),
			ColorSequenceKeypoint.new(0.74, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 28))
		})
		trail.Parent = hrp
	elseif selectedTrail == "PURPLE" and hasPurpleTrail then
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
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(98, 28, 176)),
			ColorSequenceKeypoint.new(0.22, Color3.fromRGB(62, 0, 118)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(145, 70, 220)),
			ColorSequenceKeypoint.new(0.78, Color3.fromRGB(48, 0, 96)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(118, 42, 188))
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

	if player:GetAttribute("SpeedSettingEnabled") == "MAX" then
		player:SetAttribute("SpeedSettingEnabled", "DEFAULT")
	end

	if player:GetAttribute("JumpSettingEnabled") == "MAX" then
		player:SetAttribute("JumpSettingEnabled", "DEFAULT")
	end

	if not playerTouchedSpeed[player] then
		local currentSpeed = player:GetAttribute("SpeedSettingEnabled")
		local preferredSpeed = getPreferredSpeedSettingForPlayer(player)
		if currentSpeed == nil or currentSpeed == true or currentSpeed == "DEFAULT" or (currentSpeed == "OFF" and preferredSpeed ~= "OFF") then
			player:SetAttribute("SpeedSettingEnabled", preferredSpeed)
		end
	end

	if not playerTouchedJump[player] then
		local currentJump = player:GetAttribute("JumpSettingEnabled")
		local preferredJump = getPreferredJumpSettingForPlayer(player)
		if currentJump == nil or currentJump == true or currentJump == "DEFAULT" or (currentJump == "OFF" and preferredJump ~= "OFF") then
			player:SetAttribute("JumpSettingEnabled", preferredJump)
		end
	end

	if player:GetAttribute("HasVIP") ~= true and player:GetAttribute("VIPProtectionEnabled") == true then
		player:SetAttribute("VIPProtectionEnabled", false)
	end

	if player:GetAttribute("HasVIP") == true and not playerTouchedVIPProtection[player] and player:GetAttribute("VIPProtectionEnabled") ~= true then
		player:SetAttribute("VIPProtectionEnabled", true)
	end

	if not playerTouchedTrail[player] then
		local currentTrail = player:GetAttribute("SelectedTrail")
		local preferredTrail = getPreferredTrailForPlayer(player)
		if currentTrail == nil or currentTrail == "DEFAULT" or (currentTrail == "OFF" and preferredTrail ~= "OFF") then
			player:SetAttribute("SelectedTrail", preferredTrail)
		end
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
	playerTouchedTrail[player] = nil
	playerTouchedSpeed[player] = nil
	playerTouchedJump[player] = nil
	playerTouchedVIPProtection[player] = nil
	playerTrailUnlockState[player] = nil
	playerSpeedUnlockState[player] = nil
	playerJumpUnlockState[player] = nil
end

local function bindRebirthListener(player, connections, leaderstats)
	local attached = false

	local function attachToRebirthValue(rebirths)
		if attached or not rebirths then
			return
		end

		attached = true
		table.insert(connections, rebirths:GetPropertyChangedSignal("Value"):Connect(function()
			syncUnlockedTrailState(player)
			syncUnlockedSpeedState(player)
			syncUnlockedJumpState(player)
			normalizePlayerSettings(player)
			applyCurrentCharacterStats(player)
		end))
		syncUnlockedTrailState(player)
		syncUnlockedSpeedState(player)
		syncUnlockedJumpState(player)
		task.defer(normalizePlayerSettings, player)
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
	playerTouchedTrail[player] = false
	playerTouchedSpeed[player] = false
	playerTouchedJump[player] = false
	playerTouchedVIPProtection[player] = false
	syncUnlockedTrailState(player)
	syncUnlockedSpeedState(player)
	syncUnlockedJumpState(player)

	local connections = playerConnections[player]
	for _, attributeName in ipairs(watchedAttributes) do
		table.insert(connections, player:GetAttributeChangedSignal(attributeName):Connect(function()
			syncUnlockedTrailState(player)
			syncUnlockedSpeedState(player)
			syncUnlockedJumpState(player)
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
		if value == "MAX" then
			value = "DEFAULT"
		end
		playerTouchedSpeed[player] = true
		player:SetAttribute("SpeedSettingEnabled", value)
		applyCurrentCharacterStats(player)
		return true, value, ""
	elseif settingName == "Jump" then
		if type(value) ~= "boolean" and type(value) ~= "string" then return false, nil, "INVALID_TYPE" end
		if value == "MAX" then
			value = "DEFAULT"
		end
		playerTouchedJump[player] = true
		player:SetAttribute("JumpSettingEnabled", value)
		applyCurrentCharacterStats(player)
		return true, value, ""
	elseif settingName == "VIPProtection" then
		if type(value) ~= "boolean" then return false, nil, "INVALID_TYPE" end
		playerTouchedVIPProtection[player] = true
		if not canUseVIPProtection(player) then
			player:SetAttribute("VIPProtectionEnabled", false)
			return false, false, "LOCKED"
		end

		player:SetAttribute("VIPProtectionEnabled", value)
		return true, value, ""
	elseif settingName == "SelectedTrail" then
		if type(value) ~= "string" then return false, nil, "INVALID_TYPE" end
		playerTouchedTrail[player] = true
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
