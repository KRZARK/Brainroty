local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local CoinRainTrigger = BrainrotEvents:WaitForChild("CoinRainTrigger")

-- === KONFIGURACJA ===
local COIN_ASSET = "rbxassetid://11520144151"
local SPECIAL_2D_ASSET = "rbxassetid://15993201893" -- NOWY ASSET 2D
local MUSIC_ASSET = "rbxassetid://140383003026220" -- NOWA MUZYKA
local RAIN_DURATION = 115 -- 1 minuta 55 sekund
local NOTIFY_DURATION = 115
local COLLECT_SOUND_ID = "rbxassetid://99636386529233" -- TWÓJ DŹWIĘK KOLEKCJI

local isEventActive = false -- NOWE: Flaga dla kamery

-- Tworzymy ScreenGui dla efektów
local rainGui = Instance.new("ScreenGui")
rainGui.Name = "CoinRainEffects"
rainGui.DisplayOrder = 100 -- Najwyższa warstwa
rainGui.IgnoreGuiInset = true
rainGui.Parent = playerGui

-- Funkcja tworząca spadającą monetę
local function createFallingCoin()
	local coin = Instance.new("ImageLabel")
	coin.Name = "RainCoin"
	coin.BackgroundTransparency = 1
	coin.Size = UDim2.fromScale(0.0375, 0.0375) -- O 25% mniejsze (0.05 * 0.75)
	-- Ograniczamy rozmiar monety (Constraint)
	local aspect = Instance.new("UIAspectRatioConstraint", coin)
	
	local startX = math.random()
	coin.Position = UDim2.new(startX, 0, -0.1, 0)
	coin.Image = COIN_ASSET
	coin.Rotation = math.random(0, 360)
	coin.Parent = rainGui

	local fallTime = math.random(15, 30) / 10 -- 1.5 - 3.0 sekundy
	local goal = {
		Position = UDim2.new(startX + (math.random(-10, 10)/100), 0, 1.1, 0),
		Rotation = coin.Rotation + math.random(180, 720)
	}

	local tweenInfo = TweenInfo.new(fallTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(coin, tweenInfo, goal)
	
	tween.Completed:Connect(function()
		coin:Destroy()
	end)
	tween:Play()
end

-- Funkcja tworząca spadający OBRAZEK 2D (Szybszy i pewniejszy niż 3D)
local function createFallingSpecial2D()
	local special = Instance.new("ImageLabel")
	special.Name = "SpecialRainItem"
	special.BackgroundTransparency = 1
	special.Size = UDim2.fromScale(0.06, 0.06) -- O 25% mniejsze (0.08 * 0.75)
	special.ZIndex = 99
	
	local startX = math.random()
	special.Position = UDim2.new(startX, 0, -0.1, 0)
	special.Image = SPECIAL_2D_ASSET
	special.Parent = rainGui

	local aspect = Instance.new("UIAspectRatioConstraint", special)

	local fallTime = math.random(15, 30) / 10
	local goal = {
		Position = UDim2.new(startX + (math.random(-15, 15)/100), 0, 1.2, 0),
		Rotation = math.random(-360, 360)
	}

	local tween = TweenService:Create(special, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), goal)
	tween.Completed:Connect(function() special:Destroy() end)
	tween:Play()
end

-- Obsługa zdarzenia
CoinRainTrigger.OnClientEvent:Connect(function(sponsors)
	print("!!! CLIENT: OTRZYMANO SYGNAŁ COIN RAIN !!!")
	
	-- 1. Powiadomienie o sponsorach (PRZYWRÓCONY STARY STYL - PRZENIESIONY NA DÓŁ)
	local sponsorContainer = Instance.new("Frame")
	sponsorContainer.Name = "SponsorContainer"
	sponsorContainer.Size = UDim2.new(0.6, 0, 0, 40)
	sponsorContainer.Position = UDim2.new(0.5, 0, 0.95, 0) -- Dół ekranu (95%)
	sponsorContainer.AnchorPoint = Vector2.new(0.5, 1)
	sponsorContainer.BackgroundColor3 = Color3.new(0, 0, 0)
	sponsorContainer.BackgroundTransparency = 0.4
	sponsorContainer.BorderSizePixel = 0
	sponsorContainer.ClipsDescendants = true
	sponsorContainer.Parent = rainGui
	
	local uiCorner = Instance.new("UICorner", sponsorContainer)
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	
	local sponsorText = Instance.new("TextLabel")
	sponsorText.Name = "SponsorList"
	sponsorText.Size = UDim2.new(2, 0, 1, 0)
	sponsorText.Position = UDim2.new(1.1, 0, 0, 0)
	sponsorText.BackgroundTransparency = 1
	sponsorText.Text = "💸 COIN RAIN SPONSORS: " .. sponsors .. " 💸"
	sponsorText.TextColor3 = Color3.fromRGB(255, 215, 0)
	sponsorText.Font = Enum.Font.FredokaOne
	sponsorText.TextSize = 24
	sponsorText.Parent = sponsorContainer

	local stroke = Instance.new("UIStroke", sponsorText)
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	
	-- Przewijanie napisu (Marquee)
	local tweenInfoScroll = TweenInfo.new(16, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	local scrollTween = TweenService:Create(sponsorText, tweenInfoScroll, {Position = UDim2.new(-1.5, 0, 0, 0)})
	scrollTween:Play()
	
	-- 2. Muzyka i DŹWIĘKI
	local sound = Instance.new("Sound")
	sound.SoundId = MUSIC_ASSET
	sound.Volume = 0.8
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()
	
	isEventActive = true -- START TAŃCA KAMERY
	
	-- Usuwamy efekty wizualne (GUI i muzykę) po czasie trwania
	task.delay(RAIN_DURATION, function()
		isEventActive = false -- KONIEC TAŃCA KAMERY
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
		end
		if sponsorContainer then sponsorContainer:Destroy() end
		if sound then sound:Stop(); sound:Destroy() end
	end)

	-- Funkcja nakładająca efekty na konkretną postać
	local currentTrail, currentAtt0, currentAtt1
	
	local function applyBuffsToCharacter(targetChar)
		local hum = targetChar:WaitForChild("Humanoid")
		local root = targetChar:WaitForChild("HumanoidRootPart")
		
		-- 1. Bonusy
		hum.WalkSpeed = 32
		hum.JumpPower = 100
		if hum.UseJumpPower == false then hum.JumpHeight = 14.4 end
		
		-- 2. Poświata (Zmniejszona o połowę względem poprzedniej - rozstaw 2.25 studs)
		currentAtt0 = Instance.new("Attachment", root)
		currentAtt0.Position = Vector3.new(1.125, 0, 0)
		currentAtt1 = Instance.new("Attachment", root)
		currentAtt1.Position = Vector3.new(-1.125, 0, 0)
		
		currentTrail = Instance.new("Trail")
		currentTrail.Name = "GoldenPath"
		currentTrail.Attachment0 = currentAtt0
		currentTrail.Attachment1 = currentAtt1
		currentTrail.FaceCamera = true
		currentTrail.Lifetime = 0.8
		currentTrail.WidthScale = NumberSequence.new(1, 0)
		currentTrail.LightEmission = 1
		currentTrail.LightInfluence = 0
		currentTrail.Enabled = true
		currentTrail.Parent = root
		
		-- Tęczowa pętla dla danego traila
		task.spawn(function()
			while currentTrail and currentTrail.Parent do
				local t = tick()
				local rainbow = Color3.fromHSV(t % 3 / 3, 1, 1)
				currentTrail.Color = ColorSequence.new(rainbow)
				task.wait(0.05)
			end
		end)
	end

	-- Pierwsze nałożenie
	local char = player.Character or player.CharacterAdded:Wait()
	applyBuffsToCharacter(char)
	
	-- Obsługa Rebirth (Respawn) w trakcie eventu
	local charAddedConn = player.CharacterAdded:Connect(function(newChar)
		if isEventActive then
			applyBuffsToCharacter(newChar)
		end
	end)
	
	-- Przywracamy statystyki po wydarzeniu
	task.delay(RAIN_DURATION, function()
		isEventActive = false -- Koniec flaki
		if charAddedConn then charAddedConn:Disconnect() end
		
		-- Przywrócenie balansu jest obsługiwane przez ServerCaseLogic (CharacterAdded)
		-- bo przy LoadCharacter parametry i tak się resetują do bazowych/rebirthowych.
		
		if currentTrail then 
			currentTrail.Enabled = false 
			task.wait(1) 
			if currentTrail then currentTrail:Destroy() end
			if currentAtt0 then currentAtt0:Destroy() end
			if currentAtt1 then currentAtt1:Destroy() end
		end
	end)

	-- 4. Deszcz monet i obrazów specjalnych (CAŁY CZAS TRWANIA, x2 WIĘCEJ)
	local startTime = tick()
	print("!!! CLIENT: STARTING PARTICLE RAIN !!!")
	
	task.spawn(function()
		while tick() - startTime < RAIN_DURATION do
			-- NOWE: Spawn fizycznych monet na mapie (ZWIĘKSZONO DO 400)
			createFallingCoin() -- Keep falling UI coins
			task.spawn(createFallingSpecial2D)
			
			task.wait(0.1) -- 2x częściej niż 0.2s
		end
		print("!!! CLIENT: RAIN ENDED !!!")
	end)
end)

-- NOWE: Płynne obracanie monet ORAZ bujanie kamery (Taniec)
RunService.RenderStepped:Connect(function(dt)
	-- 1. Obracanie monet
	local folder = Workspace:FindFirstChild("PhysicalCoins")
	if folder then
		for _, coin in ipairs(folder:GetChildren()) do
			if coin:IsA("BasePart") then
				coin.CFrame *= CFrame.Angles(0, dt * 5, 0)
			end
		end
	end
	
	-- 2. Bujanie kamery (Taniec do muzyki)
	if isEventActive and player.Character and player.Character:FindFirstChild("Humanoid") then
		local t = tick()
		local x = math.sin(t * 4) * 0.4 -- Lekkie kołysanie lewo-prawo
		local y = math.abs(math.sin(t * 8)) * 0.2 -- Lekkie podskakiwanie
		player.Character.Humanoid.CameraOffset = Vector3.new(x, y, 0)
	end
end)

-- Obsługa zbierania fizycznych monet (Prawidlowa doliczajaca +1)
local CoinCollected = BrainrotEvents:WaitForChild("CoinCollected")

local function onCoinTouched(coin)
	if coin.Name == "CollectibleCoin" and coin:IsA("BasePart") then
		local debounce = false
		coin.Touched:Connect(function(hit)
			if debounce then return end
			local char = hit.Parent
			local p = Players:GetPlayerFromCharacter(char)
			if p == player then
				debounce = true
				-- 1. Sygnał do serwera (ZAKOMENTOWANY - serwer sam to teraz robi)
				-- CoinCollected:FireServer()
				
				-- 2. Efekt lokalny (Dźwięk + Popup)
				local s = Instance.new("Sound")
				s.SoundId = COLLECT_SOUND_ID
				s.Volume = 1
				s.Parent = SoundService
				s:Play()
				game:GetService("Debris"):AddItem(s, 2)
				
				local popup = Instance.new("TextLabel")
				popup.Name = "RewardPopup"
				popup.Size = UDim2.new(0, 200, 0, 50)
				popup.Position = UDim2.fromScale(0.5, 0.5)
				popup.AnchorPoint = Vector2.new(0.5, 0.5)
				popup.BackgroundTransparency = 1
				popup.Text = "+1 💰"
				popup.TextColor3 = Color3.fromRGB(255, 230, 0)
				popup.Font = Enum.Font.FredokaOne
				popup.TextSize = 45
				popup.ZIndex = 200
				popup.Parent = rainGui
				
				local stroke = Instance.new("UIStroke", popup)
				stroke.Thickness = 3
				stroke.Color = Color3.new(0, 0, 0)
				
				popup:TweenPosition(UDim2.fromScale(0.5, 0.35), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.8, true)
				task.delay(0.8, function()
					if popup then popup:Destroy() end
				end)

				-- 3. Usunięcie monety
				coin:Destroy()
			end
		end)
	end
end

-- Nasłuchiwanie nowych monet na mapie
local physicalCoinsFolder = Workspace:WaitForChild("PhysicalCoins")
physicalCoinsFolder.ChildAdded:Connect(onCoinTouched)
for _, coin in ipairs(physicalCoinsFolder:GetChildren()) do
	onCoinTouched(coin)
end
