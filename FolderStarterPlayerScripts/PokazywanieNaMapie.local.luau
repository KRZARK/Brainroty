local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Potrzebne do wolnej animacji

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local activeHighlight
local bindDeathCleanup
local createWayfinder

-- === POPRAWKA: ODŚWIEŻANIE POSTACI PO RESPAWN / REBIRTH ===
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	rootPart = newChar:WaitForChild("HumanoidRootPart")
	bindDeathCleanup(newChar)
	
	-- Jeśli użytkownik aktualnie czegoś SZUKAŁ, po respawnie odświeżamy mu ścieżkę!
	if activeHighlight and activeHighlight.Adornee then
		task.wait(0.1) -- Chwila na załadowanie HumanoidRootPart
		createWayfinder(activeHighlight.Adornee)
	end
end)

-- Czekamy na dane serwerowe
local brainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents", 10)
local buyHintEvent = brainrotEvents and brainrotEvents:WaitForChild("BuyHintEvent", 10)
local brainrotyFolder = workspace:WaitForChild("Brainroty", 10)

-- KONFIGURACJA
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

local greenStudsImage = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")
local kompasImage = HudTileStyle.getImage(ReplicatedStorage, "Kompas", "rbxassetid://3944676352")

activeHighlight = nil
local activeBeamRoot = nil
local activeTargetAttachment = nil
local lastCoinsValue = 0 -- Do śledzenia przyrostu
local currentTarget, currentRarity = nil, nil -- CACHE DLA OPTYMALIZACJI
local isStatusOverridden = false -- Zapobiega nadpisywaniu tekstu przez RunService
local isOgPortalHintActive = false
local deathCleanupConnection = nil

local function getCollectedFolder()
	return player:FindFirstChild("BrainrotCollection")
end

local function hasCollectedBrainrot(brainrotName)
	local collectedFolder = getCollectedFolder()
	return collectedFolder ~= nil and brainrotName ~= nil and collectedFolder:FindFirstChild(brainrotName) ~= nil
end

local function clearActiveHint()
	if activeHighlight then
		activeHighlight:Destroy()
		activeHighlight = nil
	end

	if activeBeamRoot then
		activeBeamRoot:Destroy()
		activeBeamRoot = nil
	end

	if activeTargetAttachment then
		activeTargetAttachment:Destroy()
		activeTargetAttachment = nil
	end

	isOgPortalHintActive = false
end

bindDeathCleanup = function(characterModel)
	if deathCleanupConnection then
		deathCleanupConnection:Disconnect()
		deathCleanupConnection = nil
	end

	local humanoid = characterModel and characterModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	deathCleanupConnection = humanoid.Died:Connect(function()
		if isOgPortalHintActive then
			clearActiveHint()
		end
	end)
end

bindDeathCleanup(character)

_G.ClearOgPortalHint = function()
	if isOgPortalHintActive then
		clearActiveHint()
	end
end

local function hasSavedHintForRarity(rarity)
	local hintsFolder = player:FindFirstChild("BoughtHints")
	return rarity ~= nil and hintsFolder ~= nil and hintsFolder:FindFirstChild(rarity) ~= nil
end

-- GUI SETUP
local oldBtnGui = player:WaitForChild("PlayerGui"):FindFirstChild("RevealButton_UI")
if oldBtnGui then oldBtnGui:Destroy() end

local oldPromptGui = player:WaitForChild("PlayerGui"):FindFirstChild("RevealPrompt_UI")
if oldPromptGui then oldPromptGui:Destroy() end

local revealBtnGui = Instance.new("ScreenGui")
revealBtnGui.Name = "RevealButton_UI"
revealBtnGui.IgnoreGuiInset = true
revealBtnGui.DisplayOrder = 200 -- Zawsze na wierzchu (jak ToggleGui w ustawieniach)
revealBtnGui.ResetOnSpawn = false
revealBtnGui.Parent = player:WaitForChild("PlayerGui")

local promptGui = Instance.new("ScreenGui")
promptGui.Name = "RevealPrompt_UI"
promptGui.IgnoreGuiInset = true
promptGui.DisplayOrder = 30 -- Backdrop pod przyciskami!
promptGui.ResetOnSpawn = false
promptGui.Parent = player:WaitForChild("PlayerGui")

-- ESTETYCZNA RAMKA NA MONETY
local coinsFrame = Instance.new("Frame")
coinsFrame.Name = "CoinsFrame"
coinsFrame.Size = UDim2.fromOffset(200, 45)
coinsFrame.Position = UDim2.new(1, -20, 0, 20) -- Prawy górny róg
coinsFrame.AnchorPoint = Vector2.new(1, 0)
coinsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
coinsFrame.BackgroundTransparency = 0.4
coinsFrame.ZIndex = 1
coinsFrame.Parent = revealBtnGui

local coinsCorner = Instance.new("UICorner")
coinsCorner.CornerRadius = UDim.new(0, 8)
coinsCorner.Parent = coinsFrame

local stroke = Instance.new("UIStroke", coinsFrame)
stroke.Color = Color3.new(1,1,1)
stroke.Thickness = 2

local coinsDisplay = Instance.new("TextLabel")
coinsDisplay.Name = "CoinsDisplay"
coinsDisplay.Size = UDim2.new(1, -10, 1, -10)
coinsDisplay.Position = UDim2.new(0, 5, 0, 5)
coinsDisplay.BackgroundTransparency = 1
coinsDisplay.Font = Enum.Font.FredokaOne -- Nowoczesny font
coinsDisplay.TextScaled = true
coinsDisplay.TextColor3 = Color3.fromRGB(255, 215, 0) -- Złoty kolor
coinsDisplay.TextStrokeTransparency = 0 -- Czytelna obwódka
coinsDisplay.TextStrokeColor3 = Color3.new(0, 0, 0)
coinsDisplay.Text = "💰 0"
coinsDisplay.ZIndex = 10 -- NA WIERZCHU
coinsDisplay.Parent = coinsFrame

local coinsTextConstraint = Instance.new("UITextSizeConstraint")
coinsTextConstraint.MinTextSize = 10
coinsTextConstraint.MaxTextSize = 28
coinsTextConstraint.Parent = coinsDisplay

local coinsLayoutConnection

local function applyCoinsFrameLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local metrics = HudTileStyle.getLayoutMetrics()

	if metrics.IsLandscapeMobile then
		local frameWidth = math.clamp(viewport.X * 0.20, 128, 144)
		local frameHeight = math.clamp(viewport.Y * 0.084, 28, 32)
		local rightPadding = math.clamp(viewport.X * 0.012, 8, 14)
		coinsFrame.Size = UDim2.fromOffset(frameWidth, frameHeight)
		coinsFrame.Position = UDim2.new(1, -rightPadding, 0, 10)
		coinsCorner.CornerRadius = UDim.new(0, 6)
		stroke.Thickness = 1.8
		coinsDisplay.Size = UDim2.new(1, -8, 1, -6)
		coinsDisplay.Position = UDim2.new(0, 4, 0, 3)
		coinsTextConstraint.MaxTextSize = 16
	elseif metrics.IsMobile then
		local frameWidth = math.clamp(viewport.X * 0.34, 150, 188)
		local frameHeight = math.clamp(viewport.Y * 0.055, 34, 40)
		local rightPadding = math.clamp(viewport.X * 0.015, 10, 16)
		coinsFrame.Size = UDim2.fromOffset(frameWidth, frameHeight)
		coinsFrame.Position = UDim2.new(1, -rightPadding, 0, 18)
		coinsCorner.CornerRadius = UDim.new(0, 8)
		stroke.Thickness = 2
		coinsDisplay.Size = UDim2.new(1, -10, 1, -8)
		coinsDisplay.Position = UDim2.new(0, 5, 0, 4)
		coinsTextConstraint.MaxTextSize = 22
	else
		coinsFrame.Size = UDim2.fromOffset(200, 45)
		coinsFrame.Position = UDim2.new(1, -20, 0, 20)
		coinsCorner.CornerRadius = UDim.new(0, 8)
		stroke.Thickness = 2
		coinsDisplay.Size = UDim2.new(1, -10, 1, -10)
		coinsDisplay.Position = UDim2.new(0, 5, 0, 5)
		coinsTextConstraint.MaxTextSize = 28
	end
end

local function bindCoinsLayoutCamera(camera)
	if coinsLayoutConnection then
		coinsLayoutConnection:Disconnect()
		coinsLayoutConnection = nil
	end

	if not camera then
		return
	end

	coinsLayoutConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyCoinsFrameLayout)
end

applyCoinsFrameLayout()
bindCoinsLayoutCamera(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindCoinsLayoutCamera(workspace.CurrentCamera)
	applyCoinsFrameLayout()
end)

local revealBtn = Instance.new("ImageButton")
revealBtn.Name = "RevealButton"
revealBtn.Position = HudTileStyle.getSlot("right", 1)
revealBtn.ZIndex = 50
revealBtn.Visible = true -- ZAWSZE WIDOCZNY
revealBtn.Parent = revealBtnGui

local revealIcon = Instance.new("ImageLabel")
revealIcon.Name = "RevealIcon"
revealIcon.Image = kompasImage -- Kompas z ReplicatedStorage
revealIcon.Parent = revealBtn

local revealLabel = Instance.new("TextLabel")
revealLabel.Text = "HINT"
revealLabel.Parent = revealBtn

HudTileStyle.apply(revealBtn, revealIcon, revealLabel, {
	side = "right",
	slotIndex = 1,
	zIndex = 50,
})

-- WAŻNE: Dodajemy wywołanie, żeby ikona zachowywała się prawidłowo gdy otwierane jest inne UI z _G.UiMenus
_G.UiMenus = _G.UiMenus or {}

local promptBackdrop = Instance.new("Frame")
promptBackdrop.Name = "PromptBackdrop"
promptBackdrop.Size = UDim2.fromScale(1, 1)
promptBackdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
promptBackdrop.BackgroundTransparency = 0.38
promptBackdrop.Visible = false
promptBackdrop.ZIndex = 89
promptBackdrop.Parent = promptGui

local promptFrame = Instance.new("Frame")
promptFrame.Name = "RevealPromptFrame"
promptFrame.Size = UDim2.fromOffset(400, 220)
promptFrame.Position = UDim2.fromScale(0.5, 0.5)
promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
promptFrame.BackgroundColor3 = Color3.new(1, 1, 1) -- MUSI BYĆ BIAŁE BY UIGRADIENT DZIAŁAŁ POPRAWNIE!
promptFrame.BorderSizePixel = 0
promptFrame.Visible = false
promptFrame.ZIndex = 90
promptFrame.Parent = promptGui

local promptCorner = Instance.new("UICorner")
promptCorner.CornerRadius = UDim.new(0, 26)
promptCorner.Parent = promptFrame

local promptStroke = Instance.new("UIStroke")
promptStroke.Color = Color3.fromRGB(221, 236, 225)
promptStroke.Thickness = 3
promptStroke.Transparency = 0.06
promptStroke.Parent = promptFrame

local promptGradient = Instance.new("UIGradient")
promptGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 90, 90)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30)),
})
promptGradient.Rotation = 90
promptGradient.Parent = promptFrame

HudTileStyle.bindResponsivePanelScale(promptFrame, {
	baseSize = UDim2.fromOffset(400, 220),
	landscapeWidthRatio = 0.76,
	landscapeHeightRatio = 0.58,
	portraitWidthRatio = 0.92,
	portraitHeightRatio = 0.34,
	mobileMinScale = 0.7,
})

local promptPattern = Instance.new("ImageLabel")
promptPattern.Name = "Pattern"
promptPattern.Size = UDim2.fromScale(1, 1)
promptPattern.BackgroundTransparency = 1
promptPattern.Image = greenStudsImage
promptPattern.ImageColor3 = Color3.fromRGB(240, 90, 90) -- Dopasowane do jasnoczerwonego gradientu
promptPattern.ImageTransparency = 0.85
promptPattern.ScaleType = Enum.ScaleType.Tile
promptPattern.TileSize = UDim2.fromOffset(128, 128)
promptPattern.ZIndex = 90
promptPattern.Parent = promptFrame

local patternCorner = Instance.new("UICorner")
patternCorner.CornerRadius = UDim.new(0, 26)
patternCorner.Parent = promptPattern

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
promptLabel.Position = UDim2.fromScale(0.5, 0.3)
promptLabel.AnchorPoint = Vector2.new(0.5, 0.5)
promptLabel.BackgroundTransparency = 1
promptLabel.TextScaled = true
promptLabel.Font = Enum.Font.FredokaOne
promptLabel.TextColor3 = Color3.new(1, 1, 1)
promptLabel.Text = "Czy chcesz kupić podpowiedź do Brainrota za 50 monet?"
promptLabel.ZIndex = 91
promptLabel.Text = "Czy chcesz kupic podpowiedz do Brainrota?"
promptLabel.Parent = promptFrame

local promptTextStroke = Instance.new("UIStroke", promptLabel)
promptTextStroke.Thickness = 2
promptTextStroke.Color = Color3.new(0, 0, 0)

local promptLabelConstraint = Instance.new("UITextSizeConstraint")
promptLabelConstraint.MaxTextSize = 24
promptLabelConstraint.Parent = promptLabel

local confirmBtn = Instance.new("TextButton")
confirmBtn.Size = UDim2.new(0.35, 0, 0.25, 0)
confirmBtn.Position = UDim2.fromScale(0.3, 0.75)
confirmBtn.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBtn.BackgroundColor3 = Color3.fromRGB(56, 182, 92)
confirmBtn.Font = Enum.Font.FredokaOne
confirmBtn.TextScaled = true
confirmBtn.TextColor3 = Color3.new(1, 1, 1)
confirmBtn.Text = "KUP"
confirmBtn.ZIndex = 91
confirmBtn.Parent = promptFrame
Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 16)
local confirmStroke = Instance.new("UIStroke", confirmBtn)
confirmStroke.Thickness = 2
confirmStroke.Color = Color3.new(0, 0, 0)
confirmStroke.Transparency = 0
confirmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local confirmTextStroke = Instance.new("UIStroke", confirmBtn)
confirmTextStroke.Thickness = 2
confirmTextStroke.Color = Color3.new(0, 0, 0)
confirmTextStroke.Transparency = 0
confirmTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
local confirmConstraint = Instance.new("UITextSizeConstraint")
confirmConstraint.MaxTextSize = 20
confirmConstraint.Parent = confirmBtn

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0.35, 0, 0.25, 0)
cancelBtn.Position = UDim2.fromScale(0.7, 0.75)
cancelBtn.AnchorPoint = Vector2.new(0.5, 0.5)
cancelBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
cancelBtn.Font = Enum.Font.FredokaOne
cancelBtn.TextScaled = true
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Text = "ANULUJ"
cancelBtn.ZIndex = 91
cancelBtn.Parent = promptFrame
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 16)
local cancelStroke = Instance.new("UIStroke", cancelBtn)
cancelStroke.Thickness = 2
cancelStroke.Color = Color3.new(0, 0, 0)
cancelStroke.Transparency = 0
cancelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local cancelTextStroke = Instance.new("UIStroke", cancelBtn)
cancelTextStroke.Thickness = 2
cancelTextStroke.Color = Color3.new(0, 0, 0)
cancelTextStroke.Transparency = 0
cancelTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
local cancelConstraint = Instance.new("UITextSizeConstraint")
cancelConstraint.MaxTextSize = 20
cancelConstraint.Parent = cancelBtn

-- Logika UI Menus i animacji
local panelOpen = false

local function updatePromptVisibility(open)
	panelOpen = open
	promptBackdrop.Visible = open
	promptFrame.Visible = open

	if open then
		promptBackdrop.BackgroundTransparency = 1
		promptFrame.Position = UDim2.new(0.5, 0, 0.54, 0)
		TweenService:Create(promptBackdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.38,
		}):Play()
		TweenService:Create(promptFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
		else
			local panelTween = TweenService:Create(promptFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.54, 0),
		})
		panelTween:Play()
		TweenService:Create(promptBackdrop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		panelTween.Completed:Connect(function()
			if not panelOpen then
				promptBackdrop.Visible = false
				promptFrame.Visible = false
			end
		end)
	end
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["RevealPromptGui"] = function()
	if panelOpen then
		updatePromptVisibility(false)
		TweenService:Create(revealBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end

-- Animacyjna korutyna dla efektu "STUCK?" co 30 sekund
task.spawn(function()
	while true do
		task.wait(30)
		if revealLabel.Text == "HINT" then
			local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
			local tweenIcon = TweenService:Create(revealIcon, tweenInfo, {
				Size = UDim2.fromScale(0.78 * 1.25, 0.78 * 1.25)
			})
			tweenIcon:Play()
		end
	end
end)

-- === FUNKCJA ANIMACJI PLUSIKA (POPRAWIONA) ===
local function showCoinPopup(amount)
	local popup = Instance.new("TextLabel")
	popup.Name = "CoinPopup"
	popup.Size = UDim2.new(0, 80, 0, 25)

	-- Startuje po LEWEJ stronie kafelka (by nic nie zasłaniać - precyzyjne!)
	popup.Position = UDim2.new(0, -50, 0.5, 0)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.FredokaOne
	popup.TextSize = 24

	-- KOLOR IDENTYCZNY JAK LICZNIK
	popup.TextColor3 = Color3.fromRGB(255, 215, 0) -- Złoty
	-- TEKST Z PLUSIKIEM I WORKIEM
	popup.Text = "+" .. amount .. " 💰"
	popup.Parent = coinsFrame -- DODAWANIE DO NOWEJ RAMKI MONET

	-- DODAJEMY OBRYS (żeby był widoczny na każdym tle)
	local popupStroke = Instance.new("UIStroke")
	popupStroke.Thickness = 2
	popupStroke.Color = Color3.new(0,0,0) -- Czarny obrys
	popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	popupStroke.Parent = popup

	-- === WOLNA ANIMACJA (3 SEKUNDY) ===
	local targetPos = UDim2.new(0, -50, -0.5, 0) -- Leci prosto w górę z nowej pozycji
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local tween = TweenService:Create(popup, tweenInfo, {
		Position = targetPos,
		TextTransparency = 1 -- Znikanie tekstu
	})

	-- Musimy też animować przezroczystość obrysu!
	local strokeTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1) -- Zaczyna znikać po 1s
	local strokeTween = TweenService:Create(popupStroke, strokeTweenInfo, {
		Transparency = 1
	})

	tween:Play()
	strokeTween:Play()
	tween.Completed:Connect(function() popup:Destroy() end)
end

-- === FUNKCJA TWORZENIA STRZAŁKI (BEAM) ===
createWayfinder = function(target)
	if activeBeamRoot then activeBeamRoot:Destroy() end
	if activeTargetAttachment then activeTargetAttachment:Destroy() end
	local attPlayer = Instance.new("Attachment", rootPart)
	attPlayer.Name = "FinderAttachment"
	attPlayer.Position = Vector3.new(0, 1, 0) 

	local targetPart = nil
	if target:IsA("BasePart") then
		targetPart = target
	elseif target:IsA("Model") then
		targetPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	else
		targetPart = target:FindFirstChildWhichIsA("BasePart", true)
	end

	if not targetPart then return end

	local attTarget = Instance.new("Attachment", targetPart)
	attTarget.Name = "TargetAttachment"
	if target:IsA("Model") then
		attTarget.WorldPosition = target:GetPivot().Position
	else
		attTarget.WorldPosition = targetPart.Position
	end
	activeTargetAttachment = attTarget

	local beam = Instance.new("Beam")
	beam.Name = "PathOfLight"
	beam.Attachment0 = attPlayer
	beam.Attachment1 = attTarget
	beam.FaceCamera = true
	beam.Width0 = 1.2; beam.Width1 = 1.2 -- Pogrubiony dla widoczności "Premium"
	beam.LightEmission = 1; beam.LightInfluence = 0
	beam.ZOffset = -1 
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- Biały start
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)), -- Złoty środek
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 127)) -- Jasnożółty koniec
	})
	beam.Texture = "rbxassetid://13214144415" -- Twoja tekstura strzałek (teraz jaśniejsza)
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureSpeed = 3
	beam.Transparency = NumberSequence.new(0.2, 0.5) -- Lekka pzezroczystość dla efektu "ducha"
	beam.Parent = attPlayer
	activeBeamRoot = attPlayer 
end

-- SZUKANIE NAJNIŻSZEJ RANGI
local function getLowestRarityMissing()
	local rarities = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God", "Secret", "OG"}
	for _, rarityName in ipairs(rarities) do
		local missing = {}
		for _, model in ipairs(brainrotyFolder:GetChildren()) do
			if model:IsA("Model") and not hasCollectedBrainrot(model.Name) then
				local mRarity = model:GetAttribute("Rarity") or "Common"
				if mRarity == rarityName then
					if rarityName == "OG" then
						local ogPortal = workspace:FindFirstChild("OGPortal")
						if ogPortal then
							return ogPortal, rarityName
						end
					else
						table.insert(missing, model)
					end
				end
			end
		end
		if #missing > 0 then
			local nearest = nil
			local minDist = math.huge
			for _, m in ipairs(missing) do
				local d = (m:GetPivot().Position - rootPart.Position).Magnitude
				if d < minDist then minDist = d; nearest = m end
			end
			return nearest, rarityName
		end
	end
	return nil, nil
end

revealBtn.Activated:Connect(function()
	if not panelOpen then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "RevealPromptGui" then closeFunc() end
		end
	end
	local target, rarity = currentTarget, currentRarity
	if not target then return end
	
	local price = GameConfig.Rarities[rarity] and GameConfig.Rarities[rarity].Price or 100
	
	if activeHighlight then
		promptLabel.Text = "Obecnie podążasz już śladem Brainrota (" .. rarity:upper() .. ")!"
		confirmBtn.Text = "SZUKAJ!"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Niebieski kolor
	elseif hasSavedHintForRarity(rarity) then
		promptLabel.Text = "Masz juz podpowiedz do Brainrota (" .. rarity:upper() .. "). Chcesz jej uzyc?"
		confirmBtn.Text = "SZUKAJ!"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	else
		promptLabel.Text = "Czy chcesz kupić podpowiedź do Brainrota ("..rarity:upper()..") za " .. price .. " monet?"
		confirmBtn.Text = "KUP"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(56, 182, 92) -- Zielony (oryginalny)
	end
	
	updatePromptVisibility(not panelOpen)
	if panelOpen then
		TweenService:Create(revealBtn, TweenInfo.new(0.2), {Rotation = 15}):Play()
	else
		TweenService:Create(revealBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end)

cancelBtn.Activated:Connect(function()
	updatePromptVisibility(false)
	TweenService:Create(revealBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
end)

confirmBtn.Activated:Connect(function()
	updatePromptVisibility(false)
	TweenService:Create(revealBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	
	if activeHighlight then return end -- Zabezpieczenie przed pobraniem środków
	
	local target, rarity = currentTarget, currentRarity
	if not target or not buyHintEvent then return end
	local success = hasSavedHintForRarity(rarity) or buyHintEvent:InvokeServer(rarity)
	if success then
		local high = Instance.new("Highlight")
		high.Name = "ActiveFinder"
		high.Adornee = target
		high.FillColor = Color3.fromRGB(255, 255, 0)
		high.OutlineColor = Color3.new(1, 1, 1)
		high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		high.Parent = target
		activeHighlight = high
		isOgPortalHintActive = (rarity == "OG")
		createWayfinder(target)
	else
		isStatusOverridden = true
		revealLabel.Text = "No Coins!"
		task.wait(3)
		revealLabel.Text = "HINT"
		isStatusOverridden = false
	end
end)

-- PĘTLA ODŚWIEŻAJĄCA
RunService.RenderStepped:Connect(function()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsObj = leaderstats:FindFirstChild("Coins")
		if coinsObj then
			local currentCoins = coinsObj.Value

			-- === WYKRYWANIE PRZYROSTU ===
			if currentCoins > lastCoinsValue and lastCoinsValue ~= 0 then
				showCoinPopup(currentCoins - lastCoinsValue)
			end

			lastCoinsValue = currentCoins
			coinsDisplay.Text = "💰 COINS: " .. currentCoins
		end
	end

	if activeHighlight then
		if not activeHighlight.Adornee or (not isOgPortalHintActive and hasCollectedBrainrot(activeHighlight.Adornee.Name)) then
			clearActiveHint()
		end
	end

	if not activeHighlight then
		local target, rarity = currentTarget, currentRarity
		
		-- Zapisana podpowiedz uruchamia sie teraz tylko po kliknieciu gracza
		
		
		if target then
			revealBtn.Visible = true
			if not isStatusOverridden then
				revealLabel.Text = "HINT"
			end
		else
			if not isStatusOverridden then
				revealLabel.Text = "CLEAR"
			end
			revealBtn.Visible = true
		end
	else
		revealBtn.Visible = true
		if not isStatusOverridden then
			revealLabel.Text = "FOLLOW"
		end
	end
end)

-- === OPTYMALIZACJA: WOLNA PĘTLA SZUKANIA (1 RAZ NA SEKUNDĘ) ===
task.spawn(function()
	while true do
		currentTarget, currentRarity = getLowestRarityMissing()
		task.wait(1)
	end
end)
