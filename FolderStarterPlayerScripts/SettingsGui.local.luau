local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

local UpdateGameplaySettingRF = BrainrotEvents:WaitForChild("UpdateGameplaySetting", 10)
local settingsIconImage = HudTileStyle.getImage(ReplicatedStorage, "Settings", "rbxassetid://6031280882")
local greenStudsImage = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")

local localSettings = {
	Music = true,
	SFX = true,
	Performance = false,
}

local function getAvailableTrails()
	local trails = {"OFF"}
	if LocalPlayer:GetAttribute("HasPurpleTrail") then
		table.insert(trails, "PURPLE")
	end
	if LocalPlayer:GetAttribute("HasVIP") then
		table.insert(trails, "VIP")
	end
	
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
	
	for i = 1, math.min(rebirths, 4) do
		table.insert(trails, "REBIRTH " .. i)
	end
	
	return trails
end

local function getAvailableSpeeds()
	local options = {"OFF"}
	if LocalPlayer:GetAttribute("HasVIP") then
		table.insert(options, "VIP")
	end
	if LocalPlayer:GetAttribute("HasSpeedBoost") then
		table.insert(options, "GAMEPASS")
	end
	
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
	
	for i = 1, math.min(rebirths, 3) do
		table.insert(options, "REBIRTH " .. i)
	end
	
	return options
end

local function getAvailableJumps()
	local options = {"OFF"}
	if LocalPlayer:GetAttribute("HasVIP") then
		table.insert(options, "VIP")
	end
	if LocalPlayer:GetAttribute("HasJumpBoost") then
		table.insert(options, "GAMEPASS")
	end
	
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
	
	for i = 1, math.min(rebirths, 3) do
		table.insert(options, "REBIRTH " .. i)
	end
	
	return options
end

local settingDefinitions = {
	{
		id = "Music",
		title = "MUSIC",
		kind = "local",
		default = true,
	},
	{
		id = "SFX",
		title = "SOUNDS / SFX",
		kind = "local",
		default = true,
	},
	{
		id = "Speed",
		title = "SPEED",
		kind = "cycle",
		remoteKey = "Speed",
		attributeName = "SpeedSettingEnabled",
		default = "DEFAULT",
		getOptions = getAvailableSpeeds,
	},
	{
		id = "Jump",
		title = "JUMP",
		kind = "cycle",
		remoteKey = "Jump",
		attributeName = "JumpSettingEnabled",
		default = "DEFAULT",
		getOptions = getAvailableJumps,
	},
	{
		id = "TrailColor",
		title = "TRAIL COLOR",
		kind = "cycle",
		remoteKey = "SelectedTrail",
		attributeName = "SelectedTrail",
		default = "DEFAULT",
		getOptions = getAvailableTrails,
	},
	{
		id = "VIPProtection",
		title = "VIP PROTECTION",
		kind = "server",
		remoteKey = "VIPProtection",
		attributeName = "VIPProtectionEnabled",
		default = false,
		isUnlocked = function()
			return LocalPlayer:GetAttribute("HasVIP") == true
		end,
	},
	{
		id = "Performance",
		title = "PERFORMANCE",
		kind = "local",
		default = false,
	},
}

local rowLookup = {}
local pendingServerToggles = {}
local trackedSounds = {}
local performanceOverrides = {}
local performanceScanConnection
local performanceScanToken = 0
local settingsLayoutConnection

local function getSettingsLayoutMetrics()
	local metrics = HudTileStyle.getLayoutMetrics()
	if metrics.IsLandscapeMobile then
		return {
			rowHeight = 82,
			rowGap = 14,
			titleTextSize = 23,
			titleOffset = 180,
			toggleWidth = 116,
			toggleHeight = 50,
			boolStatusTextSize = 20,
			cycleStatusTextSize = 16,
		}
	elseif metrics.IsMobile then
		return {
			rowHeight = 78,
			rowGap = 13,
			titleTextSize = 22,
			titleOffset = 176,
			toggleWidth = 112,
			toggleHeight = 48,
			boolStatusTextSize = 19,
			cycleStatusTextSize = 15,
		}
	end

	return {
		rowHeight = 72,
		rowGap = 12,
		titleTextSize = 20,
		titleOffset = 170,
		toggleWidth = 108,
		toggleHeight = 46,
		boolStatusTextSize = 18,
		cycleStatusTextSize = 14,
	}
end

local oldGui = PlayerGui:FindFirstChild("SettingsUI")
if oldGui then oldGui:Destroy() end

local oldToggle = PlayerGui:FindFirstChild("SettingsToggleUI")
if oldToggle then oldToggle:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SettingsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 30
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "SettingsToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.Parent = PlayerGui

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleSettings"
ToggleBtn.Position = HudTileStyle.getSlot("right", 5)
ToggleBtn.ZIndex = 50
ToggleBtn.Parent = ToggleGui

local toggleIcon = Instance.new("ImageLabel")
toggleIcon.Name = "SettingsIcon"
toggleIcon.Image = settingsIconImage
toggleIcon.Parent = ToggleBtn

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Text = "SETTINGS"
toggleLabel.Parent = ToggleBtn

HudTileStyle.apply(ToggleBtn, toggleIcon, toggleLabel, {
	side = "right",
	slotIndex = 5,
	zIndex = 50,
})

local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.fromScale(1, 1)
Backdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
Backdrop.BackgroundTransparency = 0.38
Backdrop.Visible = false
Backdrop.ZIndex = 89
Backdrop.Parent = ScreenGui

local Panel = Instance.new("Frame")
Panel.Name = "SettingsPanel"
Panel.Size = UDim2.fromOffset(560, 560)
Panel.Position = UDim2.new(0.5, 0, 0.52, 0)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(18, 22, 29)
Panel.BorderSizePixel = 0
Panel.Visible = false
Panel.ZIndex = 90
Panel.Parent = ScreenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 26)
panelCorner.Parent = Panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 3
panelStroke.Color = Color3.fromRGB(221, 236, 225)
panelStroke.Transparency = 0.06
panelStroke.Parent = Panel

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 39, 48)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 19, 24)),
})
panelGradient.Rotation = 90
panelGradient.Parent = Panel

HudTileStyle.bindResponsivePanelScale(Panel, {
	baseSize = UDim2.fromOffset(560, 560),
	landscapeWidthRatio = 0.84,
	landscapeHeightRatio = 0.9,
	portraitWidthRatio = 0.92,
	portraitHeightRatio = 0.84,
	landscapeMinScale = 0.4,
	portraitMinScale = 0.54,
})

local panelPattern = Instance.new("ImageLabel")
panelPattern.Name = "GreenStudsPattern"
panelPattern.Size = UDim2.fromScale(1, 1)
panelPattern.BackgroundTransparency = 1
panelPattern.Image = greenStudsImage
panelPattern.ImageColor3 = Color3.fromRGB(101, 166, 113)
panelPattern.ImageTransparency = 0.85
panelPattern.ScaleType = Enum.ScaleType.Tile
panelPattern.TileSize = UDim2.fromOffset(128, 128)
panelPattern.ZIndex = 90
panelPattern.Parent = Panel

local patternCorner = Instance.new("UICorner")
patternCorner.CornerRadius = UDim.new(0, 26)
patternCorner.Parent = panelPattern

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, -28, 0, 64)
Header.Position = UDim2.new(0, 14, 0, 14)
Header.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
Header.BackgroundTransparency = 0.12
Header.BorderSizePixel = 0
Header.ZIndex = 91
Header.Parent = Panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = Header

local headerPattern = Instance.new("ImageLabel")
headerPattern.Size = UDim2.fromScale(1, 1)
headerPattern.BackgroundTransparency = 1
headerPattern.Image = greenStudsImage
headerPattern.ImageColor3 = Color3.fromRGB(88, 150, 102)
headerPattern.ImageTransparency = 0.9
headerPattern.ScaleType = Enum.ScaleType.Tile
headerPattern.TileSize = UDim2.fromOffset(112, 112)
headerPattern.ZIndex = 91
headerPattern.Parent = Header

local headerPatternCorner = Instance.new("UICorner")
headerPatternCorner.CornerRadius = UDim.new(0, 20)
headerPatternCorner.Parent = headerPattern

local Accent = Instance.new("Frame")
Accent.Name = "Accent"
Accent.Size = UDim2.new(0, 12, 1, -18)
Accent.Position = UDim2.new(0, 10, 0, 9)
Accent.BackgroundColor3 = Color3.fromRGB(66, 200, 106)
Accent.BorderSizePixel = 0
Accent.ZIndex = 92
Accent.Parent = Header

local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(1, 0)
accentCorner.Parent = Accent

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 38, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SETTINGS"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.LuckiestGuy
Title.TextSize = 38
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 93
Title.Parent = Header

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 2
titleStroke.Color = Color3.new(0, 0, 0)
titleStroke.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.fromOffset(44, 44)
CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(196, 66, 66)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 94
CloseBtn.Parent = Header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 14)
closeCorner.Parent = CloseBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Thickness = 2
closeStroke.Color = Color3.fromRGB(255, 247, 244)
closeStroke.Transparency = 0.08
closeStroke.Parent = CloseBtn

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -28, 1, -106)
Content.Position = UDim2.new(0, 14, 0, 92)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 8
Content.ScrollBarImageColor3 = Color3.fromRGB(202, 224, 205)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.fromOffset(0, 0)
Content.ZIndex = 91
Content.Parent = Panel

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 12)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local function isLikelyMusic(sound)
	local name = string.lower(sound.Name)
	if name:find("music") or name:find("bgm") or name:find("theme") or name:find("song") then
		return true
	end

	if sound:GetAttribute("IsMusic") == true then
		return true
	end

	return sound.Parent == SoundService and sound.Looped
end

local function disconnectTrackedSound(sound)
	local tracked = trackedSounds[sound]
	if not tracked then
		return
	end

	for _, connection in ipairs(tracked.connections) do
		connection:Disconnect()
	end

	trackedSounds[sound] = nil
end

local function applySoundState(sound)
	local tracked = trackedSounds[sound]
	if not tracked then
		return
	end

	local shouldMute = (isLikelyMusic(sound) and not localSettings.Music) or ((not isLikelyMusic(sound)) and not localSettings.SFX)
	local targetVolume = shouldMute and 0 or tracked.baseVolume

	if math.abs(sound.Volume - targetVolume) < 0.001 then
		return
	end

	sound.Volume = targetVolume
end

local function trackSound(sound)
	if trackedSounds[sound] then
		return
	end

	local tracked = {
		baseVolume = sound.Volume,
		connections = {},
	}

	trackedSounds[sound] = tracked
	table.insert(tracked.connections, sound:GetPropertyChangedSignal("Volume"):Connect(function()
		local shouldMute = (isLikelyMusic(sound) and not localSettings.Music) or ((not isLikelyMusic(sound)) and not localSettings.SFX)
		if not shouldMute then
			tracked.baseVolume = sound.Volume
		end
		applySoundState(sound)
	end))
	table.insert(tracked.connections, sound:GetPropertyChangedSignal("Looped"):Connect(function()
		applySoundState(sound)
	end))
	table.insert(tracked.connections, sound.AncestryChanged:Connect(function(_, parent)
		if not parent then
			disconnectTrackedSound(sound)
		else
			applySoundState(sound)
		end
	end))

	applySoundState(sound)
end

local function applyAudioSettings()
	for sound in pairs(trackedSounds) do
		applySoundState(sound)
	end
end

local function isOtherPlayerCharacterInstance(instance)
	local characterModel = instance:FindFirstAncestorOfClass("Model")
	if not characterModel then
		return false
	end

	local owner = Players:GetPlayerFromCharacter(characterModel)
	return owner ~= nil and owner ~= LocalPlayer
end

local function isOtherPlayerPetInstance(instance)
	local petModel = instance:FindFirstAncestorOfClass("Model")
	local activePetsFolder = Workspace:FindFirstChild("ActivePets")
	if not petModel or not activePetsFolder or petModel.Parent ~= activePetsFolder then
		return false
	end

	local ownerUserId = petModel:GetAttribute("OwnerUserId")
	return ownerUserId ~= nil and ownerUserId ~= LocalPlayer.UserId
end

local function getPerformanceCategory(instance)
	if instance:IsA("Trail") and (instance.Name == "RebirthTrail" or instance.Name == "VIPSoloTrail") and isOtherPlayerCharacterInstance(instance) then
		return "trail"
	end

	if instance:IsA("BillboardGui") and instance.Name == "PrestigeGui" and isOtherPlayerCharacterInstance(instance) then
		return "billboard"
	end

	if isOtherPlayerPetInstance(instance) then
		return "pet"
	end

	return nil
end

local function hidePerformanceInstance(instance)
	if performanceOverrides[instance] then
		return
	end

	local category = getPerformanceCategory(instance)
	if not category then
		return
	end

	if category == "trail" or category == "billboard" then
		performanceOverrides[instance] = {
			kind = "Enabled",
			value = instance.Enabled,
		}
		instance.Enabled = false
		return
	end

	if category == "pet" then
		if instance:IsA("BasePart") then
			performanceOverrides[instance] = {
				kind = "LocalTransparencyModifier",
				value = instance.LocalTransparencyModifier,
			}
			instance.LocalTransparencyModifier = 1
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			performanceOverrides[instance] = {
				kind = "Transparency",
				value = instance.Transparency,
			}
			instance.Transparency = 1
		elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("Highlight") then
			performanceOverrides[instance] = {
				kind = "Enabled",
				value = instance.Enabled,
			}
			instance.Enabled = false
		end
	end
end

local function restorePerformanceOverrides()
	for instance, state in pairs(performanceOverrides) do
		if instance and instance.Parent then
			if state.kind == "Enabled" then
				instance.Enabled = state.value
			elseif state.kind == "Transparency" then
				instance.Transparency = state.value
			elseif state.kind == "LocalTransparencyModifier" then
				instance.LocalTransparencyModifier = state.value
			end
		end
		performanceOverrides[instance] = nil
	end
end

local function refreshPerformanceScan()
	for _, instance in ipairs(Workspace:GetDescendants()) do
		hidePerformanceInstance(instance)
	end
end

local function setPerformanceModeEnabled(enabled)
	localSettings.Performance = enabled
	performanceScanToken += 1

	if performanceScanConnection then
		performanceScanConnection:Disconnect()
		performanceScanConnection = nil
	end

	if enabled then
		refreshPerformanceScan()
		performanceScanConnection = Workspace.DescendantAdded:Connect(function(instance)
			hidePerformanceInstance(instance)
		end)

		local token = performanceScanToken
		task.spawn(function()
			while localSettings.Performance and performanceScanToken == token do
				refreshPerformanceScan()
				task.wait(2)
			end
		end)
	else
		restorePerformanceOverrides()
	end
end

local function getCurrentSettingValue(definition)
	if definition.kind == "local" then
		local current = localSettings[definition.id]
		if current == nil then
			return definition.default
		end
		return current
	end

	local attributeValue = LocalPlayer:GetAttribute(definition.attributeName)
	if attributeValue == nil then
		return definition.default
	end

	return attributeValue
end

local function isUnlocked(definition)
	if not definition.isUnlocked then
		return true
	end

	return definition.isUnlocked()
end

local function applyLocalSetting(definition)
	if definition.id == "Music" or definition.id == "SFX" then
		applyAudioSettings()
	elseif definition.id == "Performance" then
		setPerformanceModeEnabled(localSettings.Performance)
	end
end

local function updateRowVisual(definition)
	local row = rowLookup[definition.id]
	if not row then
		return
	end

	local layout = getSettingsLayoutMetrics()
	local currentValue = getCurrentSettingValue(definition)
	local unlocked = isUnlocked(definition)
	local isPending = pendingServerToggles[definition.id] == true

	row.StatusLabel.TextScaled = false
	row.StatusLabel.TextSize = layout.boolStatusTextSize

	if isPending then
		row.StatusLabel.Text = "..."
		row.Toggle.BackgroundColor3 = Color3.fromRGB(86, 99, 112)
		row.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.Toggle.Active = false
		row.Toggle.AutoButtonColor = false
		row.Stroke.Color = Color3.fromRGB(137, 154, 171)
		return
	end

	if not unlocked then
		row.StatusLabel.Text = "LOCKED"
		row.Toggle.BackgroundColor3 = Color3.fromRGB(90, 96, 104)
		row.StatusLabel.TextColor3 = Color3.fromRGB(213, 216, 220)
		row.Toggle.Active = true
		row.Toggle.AutoButtonColor = false
		row.Stroke.Color = Color3.fromRGB(95, 104, 114)
		return
	end

	if definition.kind == "cycle" then
		if currentValue == "DEFAULT" or currentValue == true then
			local options = definition.getOptions()
			currentValue = options[#options] or "OFF"
		elseif currentValue == false then
			currentValue = "OFF"
		end
		row.StatusLabel.Text = tostring(currentValue)
		row.StatusLabel.TextScaled = (string.len(tostring(currentValue)) > 8)
		row.StatusLabel.TextSize = layout.cycleStatusTextSize
		
		if currentValue == "OFF" then
			row.Toggle.BackgroundColor3 = Color3.fromRGB(188, 68, 68)
			row.Stroke.Color = Color3.fromRGB(214, 108, 108)
		else
			row.Toggle.BackgroundColor3 = Color3.fromRGB(48, 126, 186)
			row.Stroke.Color = Color3.fromRGB(72, 160, 224)
		end
		
		row.StatusLabel.TextColor3 = Color3.new(1, 1, 1)
		row.Toggle.Active = true
		row.Toggle.AutoButtonColor = false
		return
	end

	row.StatusLabel.TextScaled = false
	row.StatusLabel.TextSize = layout.boolStatusTextSize
	row.StatusLabel.Text = currentValue and "ON" or "OFF"
	row.Toggle.BackgroundColor3 = currentValue and Color3.fromRGB(56, 182, 92) or Color3.fromRGB(188, 68, 68)
	row.StatusLabel.TextColor3 = Color3.new(1, 1, 1)
	row.Toggle.Active = true
	row.Toggle.AutoButtonColor = false
	row.Stroke.Color = currentValue and Color3.fromRGB(86, 210, 123) or Color3.fromRGB(214, 108, 108)
end

local function updateAllRows()
	for _, definition in ipairs(settingDefinitions) do
		updateRowVisual(definition)
	end
end

local function toggleDefinition(definition)
	if definition.kind == "local" then
		localSettings[definition.id] = not getCurrentSettingValue(definition)
		applyLocalSetting(definition)
		updateRowVisual(definition)
		return
	end

	if not isUnlocked(definition) then
		updateRowVisual(definition)
		return
	end

	if not UpdateGameplaySettingRF then
		return
	end

	if pendingServerToggles[definition.id] then
		return
	end

	pendingServerToggles[definition.id] = true
	updateRowVisual(definition)

	local targetValue
	if definition.kind == "cycle" then
		local options = definition.getOptions()
		local currentValue = getCurrentSettingValue(definition)
		
		if currentValue == "DEFAULT" or currentValue == true then
			currentValue = options[#options] or "OFF"
		elseif currentValue == false then
			currentValue = "OFF"
		end
		
		local currentIndex = table.find(options, currentValue) or 1
		local nextIndex = (currentIndex % #options) + 1
		targetValue = options[nextIndex]
	else
		targetValue = not getCurrentSettingValue(definition)
	end

	pcall(function()
		return UpdateGameplaySettingRF:InvokeServer(definition.remoteKey, targetValue)
	end)

	pendingServerToggles[definition.id] = nil
	updateAllRows()
end

local function createSettingRow(order, definition)
	local Row = Instance.new("Frame")
	Row.Name = definition.id .. "Row"
	Row.Size = UDim2.new(1, -4, 0, 72)
	Row.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
	Row.BackgroundTransparency = 0.06
	Row.BorderSizePixel = 0
	Row.LayoutOrder = order
	Row.ZIndex = 92
	Row.Parent = Content

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 20)
	rowCorner.Parent = Row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 2
	rowStroke.Color = Color3.fromRGB(95, 104, 114)
	rowStroke.Transparency = 0.1
	rowStroke.Parent = Row

	local rowPattern = Instance.new("ImageLabel")
	rowPattern.Size = UDim2.new(0, 56, 1, 0)
	rowPattern.BackgroundTransparency = 1
	rowPattern.Image = greenStudsImage
	rowPattern.ImageColor3 = Color3.fromRGB(84, 146, 98)
	rowPattern.ImageTransparency = 0.84
	rowPattern.ScaleType = Enum.ScaleType.Tile
	rowPattern.TileSize = UDim2.fromOffset(96, 96)
	rowPattern.ZIndex = 92
	rowPattern.Parent = Row

	local rowPatternCorner = Instance.new("UICorner")
	rowPatternCorner.CornerRadius = UDim.new(0, 20)
	rowPatternCorner.Parent = rowPattern

	local rowTitle = Instance.new("TextLabel")
	rowTitle.Name = "RowTitle"
	rowTitle.Size = UDim2.new(1, -170, 1, 0)
	rowTitle.Position = UDim2.new(0, 20, 0, 0)
	rowTitle.BackgroundTransparency = 1
	rowTitle.Text = definition.title
	rowTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	rowTitle.Font = Enum.Font.GothamBold
	rowTitle.TextSize = 20
	rowTitle.TextXAlignment = Enum.TextXAlignment.Left
	rowTitle.TextYAlignment = Enum.TextYAlignment.Center
	rowTitle.ZIndex = 93
	rowTitle.Parent = Row

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "Toggle"
	toggleButton.Size = UDim2.fromOffset(108, 46)
	toggleButton.Position = UDim2.new(1, -18, 0.5, 0)
	toggleButton.AnchorPoint = Vector2.new(1, 0.5)
	toggleButton.BackgroundColor3 = Color3.fromRGB(56, 182, 92)
	toggleButton.Text = "" -- Usuwamy bezpośredni tekst
	toggleButton.AutoButtonColor = false
	toggleButton.ZIndex = 94
	toggleButton.Parent = Row

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.fromScale(1, 1)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "ON"
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 18
	statusLabel.ZIndex = 95
	statusLabel.Parent = toggleButton

	local textOutline = Instance.new("UIStroke")
	textOutline.Thickness = 2.5
	textOutline.Color = Color3.new(0, 0, 0)
	textOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textOutline.Parent = statusLabel

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 16)
	toggleCorner.Parent = toggleButton

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Thickness = 2
	toggleStroke.Color = Color3.fromRGB(255, 246, 243)
	toggleStroke.Transparency = 0.12
	toggleStroke.Parent = toggleButton

	toggleButton.Activated:Connect(function()
		toggleDefinition(definition)
	end)

	rowLookup[definition.id] = {
		Row = Row,
		Stroke = rowStroke,
		TitleLabel = rowTitle,
		Toggle = toggleButton,
		StatusLabel = statusLabel,
	}
end

local function applySettingsLayout()
	local layout = getSettingsLayoutMetrics()
	ContentLayout.Padding = UDim.new(0, layout.rowGap)

	for _, row in pairs(rowLookup) do
		row.Row.Size = UDim2.new(1, -4, 0, layout.rowHeight)
		row.TitleLabel.Size = UDim2.new(1, -layout.titleOffset, 1, 0)
		row.TitleLabel.TextSize = layout.titleTextSize
		row.Toggle.Size = UDim2.fromOffset(layout.toggleWidth, layout.toggleHeight)
	end

	updateAllRows()
end

local function bindSettingsCamera(camera)
	if settingsLayoutConnection then
		settingsLayoutConnection:Disconnect()
		settingsLayoutConnection = nil
	end

	if camera then
		settingsLayoutConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applySettingsLayout)
	end
end

for index, definition in ipairs(settingDefinitions) do
	if localSettings[definition.id] == nil and definition.kind == "local" then
		localSettings[definition.id] = definition.default
	end
	createSettingRow(index, definition)
end

bindSettingsCamera(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindSettingsCamera(Workspace.CurrentCamera)
	task.defer(applySettingsLayout)
end)
applySettingsLayout()
task.defer(applySettingsLayout)

for _, instance in ipairs(game:GetDescendants()) do
	if instance:IsA("Sound") then
		trackSound(instance)
	end
end

game.DescendantAdded:Connect(function(instance)
	if instance:IsA("Sound") then
		trackSound(instance)
	end
end)

applyAudioSettings()
setPerformanceModeEnabled(localSettings.Performance)

local panelOpen = false

local function updatePanelVisibility(open)
	panelOpen = open
	Backdrop.Visible = open
	Panel.Visible = open

	if open then
		Backdrop.BackgroundTransparency = 1
		Panel.Position = UDim2.new(0.5, 0, 0.54, 0)
		TweenService:Create(Backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.38,
		}):Play()
		TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	else
		local panelTween = TweenService:Create(Panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.54, 0),
		})
		panelTween:Play()
		TweenService:Create(Backdrop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		panelTween.Completed:Connect(function()
			if not panelOpen then
				Backdrop.Visible = false
				Panel.Visible = false
			end
		end)
	end
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["SettingsGui"] = function()
	if panelOpen then
		updatePanelVisibility(false)
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end

ToggleBtn.Activated:Connect(function()
	if not panelOpen then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "SettingsGui" then closeFunc() end
		end
	end
	updateAllRows()
	updatePanelVisibility(not panelOpen)
	if panelOpen then
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 15}):Play()
	else
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end)

CloseBtn.Activated:Connect(function()
	updatePanelVisibility(false)
	TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
end)

local watchedAttributes = {
	"HasVIP",
	"HasSpeedBoost",
	"HasJumpBoost",
	"HasPurpleTrail",
	"SpeedSettingEnabled",
	"JumpSettingEnabled",
	"VIPProtectionEnabled",
	"SelectedTrail",
}

for _, attributeName in ipairs(watchedAttributes) do
	LocalPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
		updateAllRows()
	end)
end

-- Update when Rebirths change to recalculate available trails
local function connectLeaderstats(leaderstats)
	local rebirths = leaderstats:WaitForChild("Rebirths", 5)
	if rebirths then
		rebirths:GetPropertyChangedSignal("Value"):Connect(function()
			updateAllRows()
		end)
	end
end

local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
if leaderstats then
	connectLeaderstats(leaderstats)
else
	LocalPlayer.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			connectLeaderstats(child)
		end
	end)
end

updateAllRows()
