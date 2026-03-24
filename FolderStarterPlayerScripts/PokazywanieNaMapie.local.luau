local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Potrzebne do wolnej animacji

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- === POPRAWKA: ODŚWIEŻANIE POSTACI PO RESPAWN / REBIRTH ===
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	rootPart = newChar:WaitForChild("HumanoidRootPart")
	
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
local RarityOrder = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God", "Secret", "OG"}
local RarityPrices = {
	["Common"] = 50, ["Rare"] = 150, ["Epic"] = 400, ["Legendary"] = 800,
	["Mythic"] = 1500, ["Brainrot God"] = 5000, ["Secret"] = 10000, ["OG"] = 99999
}

local activeHighlight = nil
local activeBeamRoot = nil
local lastCoinsValue = 0 -- Do śledzenia przyrostu
local currentTarget, currentRarity = nil, nil -- CACHE DLA OPTYMALIZACJI
local isStatusOverridden = false -- Zapobiega nadpisywaniu tekstu przez RunService

-- GUI SETUP
-- SIŁOWE ODCIĘCIE: Czyścimy ewentualny stary HUD przed stworzeniem nowego
local oldHud = player:WaitForChild("PlayerGui"):FindFirstChild("HUD_Standalone_UI")
if oldHud then oldHud:Destroy() end

local hudGui = Instance.new("ScreenGui")
hudGui.Name = "HUD_Standalone_UI"
hudGui.IgnoreGuiInset = true -- Kluczowe dla pozycji Y na samej górze
hudGui.DisplayOrder = 5 -- Najniższa warstwa (HUD)
hudGui.ResetOnSpawn = false
hudGui.Parent = player:WaitForChild("PlayerGui")

local helperFrame = Instance.new("Frame")
helperFrame.Name = "HelperFrame"
helperFrame.Size = UDim2.fromScale(0.13, 0.13) 
helperFrame.Position = UDim2.new(1, -15, 0, 25)
helperFrame.AnchorPoint = Vector2.new(1, 0)
helperFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
helperFrame.BackgroundTransparency = 0.5 -- FALLBACK: Półprzezroczysty czarny
helperFrame.ZIndex = 1
helperFrame.Parent = hudGui

-- NOWE TŁO Z ASSETEM (ID 11520144123)
local bgImage = Instance.new("ImageLabel")
bgImage.Name = "Background"
bgImage.Image = "rbxassetid://11520144123"
bgImage.ImageTransparency = 0
bgImage.BackgroundTransparency = 1
bgImage.Size = UDim2.fromScale(1, 1)
bgImage.ScaleType = Enum.ScaleType.Stretch
bgImage.ZIndex = 0
bgImage.Visible = true
bgImage.Parent = helperFrame

Instance.new("UICorner", helperFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", helperFrame)
stroke.Color = Color3.new(1,1,1)
stroke.Thickness = 2

local coinsDisplay = Instance.new("TextLabel")
coinsDisplay.Name = "CoinsDisplay"
coinsDisplay.Size = UDim2.new(1, -10, 0.35, 0)
coinsDisplay.Position = UDim2.new(0, 5, 0, 5)
coinsDisplay.BackgroundTransparency = 1
coinsDisplay.Font = Enum.Font.FredokaOne -- Nowoczesny font
coinsDisplay.TextScaled = true
coinsDisplay.TextColor3 = Color3.fromRGB(255, 215, 0) -- Złoty kolor
coinsDisplay.TextStrokeTransparency = 0 -- Czytelna obwódka
coinsDisplay.TextStrokeColor3 = Color3.new(0, 0, 0)
coinsDisplay.Text = "💰 COINS: 0"
coinsDisplay.ZIndex = 10 -- NA WIERZCHU
coinsDisplay.Parent = helperFrame
local coinsConstraint = Instance.new("UITextSizeConstraint")
coinsConstraint.MaxTextSize = 28 -- Przewrócone do balansu
coinsConstraint.Parent = coinsDisplay

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0.38, 0) -- Powiększony do 38% wysokości dla "STUCK?"
statusLabel.Position = UDim2.new(0.5, 0, 0.45, 0) -- Nieco wyżej
statusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.FredokaOne
statusLabel.TextScaled = true
statusLabel.TextColor3 = Color3.new(1, 1, 1) -- BIAŁY
statusLabel.TextStrokeTransparency = 0
statusLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
statusLabel.Text = "READY?"
statusLabel.ZIndex = 10
statusLabel.Parent = helperFrame
local statusConstraint = Instance.new("UITextSizeConstraint")
statusConstraint.MaxTextSize = 40 -- 2 razy większy dla "STUCK?"
statusConstraint.Parent = statusLabel

local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
buyBtn.Position = UDim2.fromScale(0.5, 0.78) -- Podniesiony, żeby był zapas na dole
buyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
buyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
buyBtn.Font = Enum.Font.FredokaOne
buyBtn.TextScaled = true
buyBtn.TextColor3 = Color3.new(1, 1, 1)
buyBtn.TextStrokeTransparency = 0
buyBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
buyBtn.TextXAlignment = Enum.TextXAlignment.Center
buyBtn.TextYAlignment = Enum.TextYAlignment.Center
buyBtn.Visible = false
buyBtn.ZIndex = 11 -- NA SAMYM WIERZCHU
buyBtn.Parent = helperFrame
Instance.new("UICorner", buyBtn)
local btnConstraint = Instance.new("UITextSizeConstraint")
btnConstraint.MaxTextSize = 22 -- Przewrócone do balansu
btnConstraint.Parent = buyBtn

-- Animacyjna korutyna dla efektu "STUCK?" co 30 sekund
task.spawn(function()
	local originalBgColor = buyBtn.BackgroundColor3
	while true do
		task.wait(30)
		
		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
		
		local tweenBtn = TweenService:Create(buyBtn, tweenInfo, {
			Size = UDim2.new(0.9 * 1.25, 0, 0.35 * 1.25, 0)
		})
		local tweenLabel = TweenService:Create(statusLabel, tweenInfo, {
			Size = UDim2.new(1 * 1.25, -10, 0.25 * 1.25, 0)
		})
		tweenBtn:Play()
		tweenLabel:Play()

		local startTime = tick()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local t = tick()
			if t - startTime > 3 then
				connection:Disconnect()
				statusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
				buyBtn.BackgroundColor3 = originalBgColor
			else
				local rainbow = Color3.fromHSV(t % 1, 1, 1)
				statusLabel.TextColor3 = rainbow
				buyBtn.BackgroundColor3 = rainbow
			end
		end)
	end
end)

-- === FUNKCJA ANIMACJI PLUSIKA (POPRAWIONA) ===
local function showCoinPopup(amount)
	local popup = Instance.new("TextLabel")
	popup.Name = "CoinPopup"
	popup.Size = UDim2.new(0, 80, 0, 25)

	-- Startuje po LEWEJ stronie kafelka (by nic nie zasłaniać - precyzyjne!)
	popup.Position = UDim2.fromScale(-0.35, 0.45) 
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.FredokaOne
	popup.TextSize = 24

	-- KOLOR IDENTYCZNY JAK LICZNIK
	popup.TextColor3 = Color3.fromRGB(255, 215, 0) -- Złoty
	-- TEKST Z PLUSIKIEM I WORKIEM
	popup.Text = "+" .. amount .. " 💰"
	popup.Parent = helperFrame -- DODAWANIE DO NOWEJ RAMKI MONET

	-- DODAJEMY OBRYS (żeby był widoczny na każdym tle)
	local popupStroke = Instance.new("UIStroke")
	popupStroke.Thickness = 2
	popupStroke.Color = Color3.new(0,0,0) -- Czarny obrys
	popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	popupStroke.Parent = popup

	-- === WOLNA ANIMACJA (3 SEKUNDY) ===
	local targetPos = UDim2.new(-0.35, 0, -0.6, 0) -- Leci prosto w górę z nowej pozycji
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
local function createWayfinder(target)
	if activeBeamRoot then activeBeamRoot:Destroy() end
	local attPlayer = Instance.new("Attachment", rootPart)
	attPlayer.Name = "FinderAttachment"
	attPlayer.Position = Vector3.new(0, 1, 0) 

	local targetPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	if not targetPart then return end

	local attTarget = Instance.new("Attachment", targetPart)
	attTarget.Name = "TargetAttachment"
	attTarget.WorldPosition = target:GetPivot().Position 

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
	if not _G.CollectedBrainrotsTable then return nil, nil end
	for _, rarityName in ipairs(RarityOrder) do
		local missing = {}
		for _, model in ipairs(brainrotyFolder:GetChildren()) do
			if model:IsA("Model") and not _G.CollectedBrainrotsTable[model.Name] then
				local mRarity = model:GetAttribute("Rarity") or "Common"
				if mRarity == rarityName then table.insert(missing, model) end
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

buyBtn.MouseButton1Click:Connect(function()
	local target, rarity = currentTarget, currentRarity
	if not target or not buyHintEvent then return end
	local success = buyHintEvent:InvokeServer(rarity)
	if success then
		local high = Instance.new("Highlight")
		high.Name = "ActiveFinder"
		high.Adornee = target
		high.FillColor = Color3.fromRGB(255, 255, 0)
		high.OutlineColor = Color3.new(1, 1, 1)
		high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		high.Parent = target
		activeHighlight = high
		createWayfinder(target)
	else
		isStatusOverridden = true
		statusLabel.Text = "NEED MORE COINS!"
		buyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		task.wait(3)
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
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
		if not activeHighlight.Adornee or (_G.CollectedBrainrotsTable and _G.CollectedBrainrotsTable[activeHighlight.Adornee.Name]) then
			activeHighlight:Destroy()
			activeHighlight = nil
			if activeBeamRoot then activeBeamRoot:Destroy(); activeBeamRoot = nil end
		end
	end

	if not activeHighlight then
		local target, rarity = currentTarget, currentRarity
		if target then
			buyBtn.Visible = true
			buyBtn.Text = "REVEAL " .. rarity:upper() .. " (" .. (RarityPrices[rarity] or 100) .. ")"
			if not isStatusOverridden then
				statusLabel.Text = "STUCK?"
				-- STYL DLA STUCK (Biały, Duży, Wyżej)
				statusLabel.TextColor3 = Color3.new(1, 1, 1)
				statusLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
				statusConstraint.MaxTextSize = 40
			end
		else
			if not isStatusOverridden then
				statusLabel.Text = "AREA CLEAR!"
				-- STYL STANDARDOWY (Biały, 2x WIĘKSZY, Niżej o 10px)
				statusLabel.TextColor3 = Color3.new(1, 1, 1)
				statusLabel.Position = UDim2.new(0.5, 0, 0.45, 10)
				statusConstraint.MaxTextSize = 44 -- Zwiększony 2 razy z 22
			end
			buyBtn.Visible = false
		end
	else
		buyBtn.Visible = false
		if not isStatusOverridden then
			statusLabel.Text = "FOLLOW THE LIGHT!"
			-- STYL DLA FOLLOW (Biały, 2x WIĘKSZY, Niżej o 10px)
			statusLabel.TextColor3 = Color3.new(1, 1, 1)
			statusLabel.Position = UDim2.new(0.5, 0, 0.45, 10)
			statusConstraint.MaxTextSize = 44 -- Zwiększony 2 razy z 22
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