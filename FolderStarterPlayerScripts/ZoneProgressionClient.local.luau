local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local BrainrotUtils = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("BrainrotUtils"))

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))

-- GUI dla błędu portalu
local playerGui = player:WaitForChild("PlayerGui")
local warningGui = Instance.new("ScreenGui")
warningGui.Name = "OGPortalWarning"
warningGui.DisplayOrder = 100
warningGui.ResetOnSpawn = false -- KLUCZOWE: GUI nie usuwa się po śmierci!
warningGui.Parent = playerGui

local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.fromScale(0.8, 0.2)
warningLabel.Position = UDim2.fromScale(0.5, 0.3)
warningLabel.AnchorPoint = Vector2.new(0.5, 0.5)
warningLabel.BackgroundTransparency = 1
warningLabel.Text = "YOU MUST COLLECT ALL SECRET BRAINROTS TO SEARCH FOR OG!"
warningLabel.TextColor3 = Color3.fromRGB(255, 30, 30)
warningLabel.Font = Enum.Font.FredokaOne
warningLabel.TextScaled = true
warningLabel.Visible = false
warningLabel.ZIndex = 100
warningLabel.Parent = warningGui

local warningStroke = Instance.new("UIStroke")
warningStroke.Thickness = 4
warningStroke.Color = Color3.new(0, 0, 0)
warningStroke.Parent = warningLabel

local uiConstraint = Instance.new("UITextSizeConstraint")
uiConstraint.MaxTextSize = 60
uiConstraint.MinTextSize = 20
uiConstraint.Parent = warningLabel

local debounce = false
local doorUnlockStates = {}
local doorUnlockQueue = {}
local isDoorUnlockShowing = false
local portalUnlockState = nil
local greenStudsTexture = ""

local greenStudsDecal = ReplicatedStorage:FindFirstChild("GreenStuds")
if greenStudsDecal and greenStudsDecal:IsA("Decal") then
	greenStudsTexture = greenStudsDecal.Texture
end

local doorAnnouncementGui = Instance.new("ScreenGui")
doorAnnouncementGui.Name = "ZoneUnlockAnnouncements"
doorAnnouncementGui.DisplayOrder = 90
doorAnnouncementGui.IgnoreGuiInset = true
doorAnnouncementGui.ResetOnSpawn = false
doorAnnouncementGui.Parent = playerGui

local doorAnnouncementCard = Instance.new("Frame")
doorAnnouncementCard.Name = "DoorUnlockCard"
doorAnnouncementCard.AnchorPoint = Vector2.new(0.5, 0.5)
doorAnnouncementCard.Position = UDim2.fromScale(0.5, 0.08)
doorAnnouncementCard.Size = UDim2.new(0.72, 0, 0, 140)
doorAnnouncementCard.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
doorAnnouncementCard.BackgroundTransparency = 1
doorAnnouncementCard.BorderSizePixel = 0
doorAnnouncementCard.ClipsDescendants = true
doorAnnouncementCard.Visible = false
doorAnnouncementCard.Parent = doorAnnouncementGui

local doorCardConstraint = Instance.new("UISizeConstraint")
doorCardConstraint.MaxSize = Vector2.new(820, 140)
doorCardConstraint.MinSize = Vector2.new(480, 126)
doorCardConstraint.Parent = doorAnnouncementCard

local doorCardCorner = Instance.new("UICorner")
doorCardCorner.CornerRadius = UDim.new(0, 24)
doorCardCorner.Parent = doorAnnouncementCard

local doorTextureBackground = Instance.new("ImageLabel")
doorTextureBackground.Name = "TextureBackground"
doorTextureBackground.Size = UDim2.fromScale(1, 1)
doorTextureBackground.BackgroundTransparency = 1
doorTextureBackground.Image = greenStudsTexture
doorTextureBackground.ImageColor3 = Color3.fromRGB(95, 255, 165)
doorTextureBackground.ImageTransparency = 0.82
doorTextureBackground.ScaleType = Enum.ScaleType.Tile
doorTextureBackground.TileSize = UDim2.fromOffset(72, 72)
doorTextureBackground.Parent = doorAnnouncementCard

local doorTextureGradient = Instance.new("UIGradient")
doorTextureGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 94, 56)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(92, 255, 164)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 68, 50)),
})
doorTextureGradient.Rotation = 18
doorTextureGradient.Parent = doorTextureBackground

local doorCardStroke = Instance.new("UIStroke")
doorCardStroke.Thickness = 2.5
doorCardStroke.Color = Color3.fromRGB(150, 255, 190)
doorCardStroke.Transparency = 1
doorCardStroke.Parent = doorAnnouncementCard

local doorCardGradient = Instance.new("UIGradient")
doorCardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 22, 18)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(20, 52, 37)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 24, 20)),
})
doorCardGradient.Rotation = 12
doorCardGradient.Parent = doorAnnouncementCard

local doorAccentLine = Instance.new("Frame")
doorAccentLine.Name = "AccentLine"
doorAccentLine.AnchorPoint = Vector2.new(0.5, 0)
doorAccentLine.Position = UDim2.fromScale(0.5, 0)
doorAccentLine.Size = UDim2.new(1, -36, 0, 6)
doorAccentLine.BackgroundColor3 = Color3.fromRGB(92, 255, 148)
doorAccentLine.BackgroundTransparency = 1
doorAccentLine.BorderSizePixel = 0
doorAccentLine.Parent = doorAnnouncementCard

local doorAccentCorner = Instance.new("UICorner")
doorAccentCorner.CornerRadius = UDim.new(1, 0)
doorAccentCorner.Parent = doorAccentLine

local doorBadge = Instance.new("TextLabel")
doorBadge.Name = "Badge"
doorBadge.AnchorPoint = Vector2.new(0, 0.5)
doorBadge.Position = UDim2.new(0, 28, 0, 38)
doorBadge.Size = UDim2.new(1, -56, 0, 30)
doorBadge.BackgroundTransparency = 1
doorBadge.Font = Enum.Font.GothamBlack
doorBadge.Text = "NEW AREA UNLOCKED"
doorBadge.TextColor3 = Color3.fromRGB(173, 255, 205)
doorBadge.TextSize = 26
doorBadge.TextStrokeColor3 = Color3.fromRGB(10, 28, 18)
doorBadge.TextStrokeTransparency = 0.3
doorBadge.TextTransparency = 1
doorBadge.TextXAlignment = Enum.TextXAlignment.Left
doorBadge.ZIndex = 2
doorBadge.Parent = doorAnnouncementCard

local doorTitle = Instance.new("TextLabel")
doorTitle.Name = "Title"
doorTitle.AnchorPoint = Vector2.new(0, 0.5)
doorTitle.Position = UDim2.new(0, 28, 0, 88)
doorTitle.Size = UDim2.new(1, -56, 0, 54)
doorTitle.BackgroundTransparency = 1
doorTitle.Font = Enum.Font.FredokaOne
doorTitle.Text = "DOORS TO AREA 1 ARE NOW OPEN!"
doorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
doorTitle.TextSize = 31
doorTitle.TextTransparency = 1
doorTitle.TextWrapped = true
doorTitle.TextXAlignment = Enum.TextXAlignment.Left
doorTitle.ZIndex = 2
doorTitle.Parent = doorAnnouncementCard

local doorSubText = Instance.new("TextLabel")
doorSubText.Name = "SubText"
doorSubText.AnchorPoint = Vector2.new(0, 0.5)
doorSubText.Position = UDim2.new(0, 28, 1, -24)
doorSubText.Size = UDim2.new(1, -56, 0, 22)
doorSubText.BackgroundTransparency = 1
doorSubText.Font = Enum.Font.GothamBold
doorSubText.Text = "Completed category: RARE"
doorSubText.TextColor3 = Color3.fromRGB(191, 225, 255)
doorSubText.TextSize = 16
doorSubText.TextTransparency = 1
doorSubText.TextXAlignment = Enum.TextXAlignment.Left
doorSubText.ZIndex = 2
doorSubText.Visible = false
doorSubText.Parent = doorAnnouncementCard

local doorUnlockSoundTemplate = ReplicatedStorage:WaitForChild("Drzwi", 10)
local doorUnlockSound = nil
if doorUnlockSoundTemplate and doorUnlockSoundTemplate:IsA("Sound") then
	doorUnlockSound = doorUnlockSoundTemplate:Clone()
	doorUnlockSound.Name = "DoorUnlockAnnouncementSound"
	doorUnlockSound.Parent = SoundService
end

local function prettifyAreaName(value)
	local text = tostring(value or "")
	text = text:gsub("_", " ")
	text = text:gsub("([a-z])([A-Z])", "%1 %2")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function getDoorGroupRoot(door, doorsFolder)
	local current = door
	while current and current.Parent and current.Parent ~= doorsFolder do
		current = current.Parent
	end
	return current or door
end

local function getRequiredRarityForDoor(door, doorsFolder)
	local current = door
	while current and current ~= doorsFolder do
		local requiredRarity = current:GetAttribute("RequiresRarity")
		if requiredRarity then
			return requiredRarity
		end
		current = current.Parent
	end
	return nil
end

local function getAreaAnnouncementLabel(groupName)
	local areaNumber, rawAreaName = string.match(groupName or "", "^(%d+)%s*[%._%-]%s*(.+)$")
	if not areaNumber then
		areaNumber, rawAreaName = string.match(groupName or "", "^(%d+)%s*(.+)$")
	end

	local cleanAreaName = prettifyAreaName(rawAreaName or groupName or "New Area")
	if areaNumber then
		if cleanAreaName ~= "" and string.lower(cleanAreaName) ~= ("area " .. areaNumber) then
			return string.format("Area %s (%s)", areaNumber, cleanAreaName)
		end
		return string.format("Area %s", areaNumber)
	end

	return cleanAreaName ~= "" and cleanAreaName or "New Area"
end

local function getDoorAreaNumber(groupName)
	local areaNumber = string.match(groupName or "", "^(%d+)")
	return tonumber(areaNumber)
end

local function getDoorRequirements(groupName, fallbackRequiredRarity)
	local areaNumber = getDoorAreaNumber(groupName)
	if areaNumber == 1 then
		return {"Common", "Rare"}
	end

	if areaNumber == 2 then
		return {"Epic", "Legendary"}
	end

	if fallbackRequiredRarity then
		return {fallbackRequiredRarity}
	end

	return {}
end

local function hasCompletedAllRarities(playerToCheck, rarities)
	if type(rarities) ~= "table" or #rarities == 0 then
		return false
	end

	for _, rarityName in ipairs(rarities) do
		if not BrainrotUtils.hasCompletedRarity(playerToCheck, rarityName) then
			return false
		end
	end

	return true
end

local function playDoorUnlockSound()
	if not doorUnlockSound then
		return
	end

	doorUnlockSound:Stop()
	doorUnlockSound.TimePosition = 0
	doorUnlockSound:Play()
end

local function showNextDoorUnlockAnnouncement()
	if isDoorUnlockShowing or #doorUnlockQueue == 0 then
		return
	end

	local nextAnnouncement = table.remove(doorUnlockQueue, 1)
	isDoorUnlockShowing = true
	doorAnnouncementCard.Visible = true
	doorAnnouncementCard.Position = UDim2.fromScale(0.5, 0.08)
	doorAnnouncementCard.BackgroundTransparency = 1
	doorCardStroke.Transparency = 1
	doorAccentLine.BackgroundTransparency = 1
	doorBadge.TextTransparency = 1
	doorTitle.TextTransparency = 1
	doorSubText.TextTransparency = 1

	doorBadge.Visible = not nextAnnouncement.hideBadge
	if nextAnnouncement.hideBadge then
		doorTitle.Position = UDim2.new(0, 28, 0.5, 0)
		doorTitle.Size = UDim2.new(1, -56, 0, 72)
		doorTitle.TextSize = 34
		doorTitle.TextXAlignment = Enum.TextXAlignment.Center
	else
		doorTitle.Position = UDim2.new(0, 28, 0, 88)
		doorTitle.Size = UDim2.new(1, -56, 0, 54)
		doorTitle.TextSize = 31
		doorTitle.TextXAlignment = Enum.TextXAlignment.Left
	end

	doorBadge.Text = tostring(nextAnnouncement.badgeText or "NEW AREA UNLOCKED")
	doorTitle.Text = tostring(nextAnnouncement.titleText or string.format("DOORS TO %s ARE NOW OPEN!", string.upper(nextAnnouncement.areaLabel or "NEW AREA")))
	doorSubText.Text = tostring(nextAnnouncement.subText or "")
	doorSubText.Visible = false

	playDoorUnlockSound()

	TweenService:Create(doorAnnouncementCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.12),
		BackgroundTransparency = 0.06,
	}):Play()
	TweenService:Create(doorCardStroke, TweenInfo.new(0.3), {Transparency = 0.12}):Play()
	TweenService:Create(doorAccentLine, TweenInfo.new(0.3), {BackgroundTransparency = 0.08}):Play()
	TweenService:Create(doorBadge, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
	TweenService:Create(doorTitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	TweenService:Create(doorSubText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	task.spawn(function()
		task.wait(10)

		TweenService:Create(doorAnnouncementCard, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, 0.08),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(doorCardStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
		TweenService:Create(doorAccentLine, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
		TweenService:Create(doorBadge, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		TweenService:Create(doorTitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		TweenService:Create(doorSubText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()

		task.wait(0.35)
		doorAnnouncementCard.Visible = false
		isDoorUnlockShowing = false
		showNextDoorUnlockAnnouncement()
	end)
end

local function queueDoorUnlockAnnouncement(groupId, groupName, requiredRarity)
	for _, queued in ipairs(doorUnlockQueue) do
		if queued.groupId == groupId then
			return
		end
	end

	table.insert(doorUnlockQueue, {
		groupId = groupId,
		areaLabel = getAreaAnnouncementLabel(groupName),
		requiredRarity = tostring(requiredRarity or "Unknown"),
	})
	showNextDoorUnlockAnnouncement()
end

local function queuePortalUnlockAnnouncement()
	local portalAnnouncementId = "OG_PORTAL"
	for _, queued in ipairs(doorUnlockQueue) do
		if queued.groupId == portalAnnouncementId then
			return
		end
	end

	table.insert(doorUnlockQueue, {
		groupId = portalAnnouncementId,
		hideBadge = true,
		titleText = "THE PORTAL TO THE OG BRAINROT IS NOW OPEN. FIND IT.",
	})
	showNextDoorUnlockAnnouncement()
end

local function setDoorOpenState(door, isOpen)
	if isOpen then
		if door.CanCollide ~= false then
			door.CanCollide = false
			door.Transparency = 0.6
			door.Material = Enum.Material.ForceField
			door.BrickColor = BrickColor.new("Lime green")
		end
	else
		if door.CanCollide ~= true then
			door.CanCollide = true
			door.Transparency = 0
			door.Material = Enum.Material.Neon
			door.BrickColor = BrickColor.new("Really red")
		end
	end
end

-- Manage zone doors and announce newly unlocked areas
task.spawn(function()
	-- Czekamy na wczytanie kolekcji gracza oraz wzorców, by uniknąć fałszywych powiadomień po wejściu do gry
	player:WaitForChild("BrainrotCollection", 30)
	local storage = ReplicatedStorage:WaitForChild("BrainrotStorage", 10)
	if storage then
		while #storage:GetChildren() == 0 do
			task.wait(0.5)
		end
	end

	while true do
		local doorsFolder = Workspace:FindFirstChild("ZoneDoors")
		if doorsFolder then
			local doorGroups = {}
			for _, door in ipairs(doorsFolder:GetDescendants()) do
				if door:IsA("BasePart") then
					local groupRoot = getDoorGroupRoot(door, doorsFolder)
					local groupId = groupRoot:GetFullName()
					local groupData = doorGroups[groupId]
					if not groupData then
						groupData = {
							root = groupRoot,
							name = groupRoot.Name,
							requiredRarity = getRequiredRarityForDoor(door, doorsFolder),
							requirements = getDoorRequirements(groupRoot.Name, getRequiredRarityForDoor(door, doorsFolder)),
							parts = {},
						}
						doorGroups[groupId] = groupData
					end
					table.insert(groupData.parts, door)
				end
			end

			for groupId, groupData in pairs(doorGroups) do
				if #groupData.requirements > 0 then
					local hasCompleted = hasCompletedAllRarities(player, groupData.requirements)
					local previousState = doorUnlockStates[groupId]

					for _, door in ipairs(groupData.parts) do
						setDoorOpenState(door, hasCompleted)
					end

					if previousState == nil then
						doorUnlockStates[groupId] = hasCompleted
					elseif previousState == false and hasCompleted == true then
						doorUnlockStates[groupId] = true
						queueDoorUnlockAnnouncement(groupId, groupData.name, groupData.requiredRarity)
					elseif previousState == true and hasCompleted == false then
						doorUnlockStates[groupId] = false
					end
				end
			end
		end

		local hasSecret = BrainrotUtils.hasCompletedRarity(player, "Secret")
		
		if portalUnlockState == nil then
			portalUnlockState = hasSecret
		elseif portalUnlockState == false and hasSecret == true then
			portalUnlockState = true
			queuePortalUnlockAnnouncement()
		elseif portalUnlockState == true and hasSecret == false then
			portalUnlockState = false
		end

		task.wait(1)
	end
end)

-- Nasłuchiwanie portalu OG
task.spawn(function()
	local portal = Workspace:WaitForChild("OGPortal", 20)
	if not portal then
		warn("[ZoneProgression] OGPortal not loaded within 20s!")
		return
	end
	
	-- Funkcja podłączana do eventu touched
	local function onTouched(hit)
		if debounce then return end
		
		local character = player.Character
		if character and hit:IsDescendantOf(character) then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				debounce = true
				
				-- ROZWIĄZANIE PROBLEMU KROK 4: Weryfikacja serwerowa względem TotalBrainrots
				local requestTeleport = ReplicatedStorage:WaitForChild("BrainrotEvents"):WaitForChild("RequestOGTeleport")
				local success = requestTeleport:InvokeServer()
				
				if success then
					if type(_G.ClearOgPortalHint) == "function" then
						_G.ClearOgPortalHint()
					end
					task.wait(1) -- Czas na TP (serwer to wykonuje)
				else
					warningLabel.Text = "YOU MUST COLLECT ALL SECRET BRAINROTS TO SEARCH FOR OG!"
					warningLabel.Visible = true
					task.delay(3, function()
						warningLabel.Visible = false
					end)
					
					-- Dajemy mu 3 sekundy kary po odbiciu się zanim znowu wyskoczy gui
					task.wait(3)
				end
				
				debounce = false
			end
		end
	end

	-- Podpięcie do elementu głównego jeśli jest BasePart
	if portal:IsA("BasePart") then
		portal.Touched:Connect(onTouched)
	end

	-- Podpięcie do wszystkich aktualnych części w środku
	for _, part in ipairs(portal:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end

	-- ROZWIĄZANIE PROBLEMU STREAMINGU: podpięcie do części, które załadują się w przyszłości
	portal.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.Touched:Connect(onTouched)
		end
	end)
end)

print("ZoneProgressionClient loaded.")
