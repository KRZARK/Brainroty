local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MAX_COLLECT_DISTANCE = 15

local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local BrainrotCollectedEvent = BrainrotEvents:WaitForChild("BrainrotCollected")
local BrainrotyFolder = Workspace:WaitForChild("Brainroty")

-- DODAJEMY FOLDER NA MONETY OD RAZU, ABY KLIENT NIE CZEKAŁ W NIESKOŃCZONOŚĆ
local PhysicalCoinsFolder = Workspace:FindFirstChild("PhysicalCoins")
if not PhysicalCoinsFolder then
	PhysicalCoinsFolder = Instance.new("Folder", Workspace)
	PhysicalCoinsFolder.Name = "PhysicalCoins"
end

 
 -- NOWE: System Coin Rain (Krok 1)
 local CoinRainTrigger = BrainrotEvents:FindFirstChild("CoinRainTrigger") or Instance.new("RemoteEvent", BrainrotEvents)
 CoinRainTrigger.Name = "CoinRainTrigger"
 
 local CoinCollected = BrainrotEvents:FindFirstChild("CoinCollected") or Instance.new("RemoteEvent", BrainrotEvents)
 CoinCollected.Name = "CoinCollected"
 
 local PoolUpdated = BrainrotEvents:FindFirstChild("PoolUpdated") or Instance.new("RemoteEvent", BrainrotEvents)
 PoolUpdated.Name = "PoolUpdated"
 
 local RebirthEvent = BrainrotEvents:FindFirstChild("RebirthEvent") or Instance.new("RemoteEvent", BrainrotEvents)
 RebirthEvent.Name = "RebirthEvent"
 
 local RebirthEffect = BrainrotEvents:FindFirstChild("RebirthEffect") or Instance.new("RemoteEvent", BrainrotEvents)
 RebirthEffect.Name = "RebirthEffect"
 
 local RebirthPositions = {} -- [UserId] = CFrame
 
 local GlobalRobuxPool = 0
 local Sponsors = {}
 local isEventActive = false -- Blokada na nakładanie się eventów
 local EVENT_DURATION = 115 
 
 -- === KONFIGURACJA MONET NA MAPIE ===
 local PHYSICAL_COIN_MESH = "rbxassetid://4937522724"
 local SPAWN_RANGE = 600 -- Zasięg 2x większy (600 studs)
 local COIN_REWARD = 1 -- Zmiana z 10 na 1
 
 local function spawnPhysicalCoins(count)
 	local folder = PhysicalCoinsFolder
 	folder:ClearAllChildren()
 	
 	-- NOWE: Priorytet dla modelu w ReplicatedStorage
 	local coinTemplate = ReplicatedStorage:FindFirstChild("EventCoin")
 	
 	if not coinTemplate then
 		-- Fallback: Próba pobrania z neta
 		local success, model = pcall(function()
 			return InsertService:LoadAsset(4937522724)
 		end)
 		
 		if success and model then
 			coinTemplate = model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChildWhichIsA("MeshPart") or model:FindFirstChildWhichIsA("Model")
 			if coinTemplate then 
 				coinTemplate = coinTemplate:Clone()
 				if coinTemplate:IsA("Model") then
 					coinTemplate:SetPrimaryPartCFrame(CFrame.new(0,0,0))
 				end
 			end
 			model:Destroy()
 		end
 	end
 	
 	print("!!! SPAWNING " .. count .. " PHYSICAL COINS !!! (Source: " .. (coinTemplate and coinTemplate.Name or "FALLBACK") .. ")")
 	
 	for i = 1, count do
 		local coin
 		if coinTemplate then
 			coin = coinTemplate:Clone()
 			if coin:IsA("Model") then
 				local root = coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart")
 				if not root then coin = Instance.new("Part") -- Fallback dla pustego modelu
 				else coin = root end
 			end
 		else
 			-- CAŁKOWITY FALLBACK: Złota kulka
 			coin = Instance.new("Part")
 			coin.Shape = Enum.PartType.Ball
 			coin.Material = Enum.Material.Neon
 			coin.Color = Color3.fromRGB(255, 215, 0)
 		end
 		
 		coin.Name = "CollectibleCoin"
 		coin.Size = Vector3.new(3, 3, 3)
 		coin.Position = Vector3.new(
 			math.random(-SPAWN_RANGE, SPAWN_RANGE),
 			100,
 			math.random(-SPAWN_RANGE, SPAWN_RANGE)
 		)
 		coin.CanCollide = false
 		coin.Anchored = true
 		coin.Parent = folder
 		
 		-- Raycast na ziemię
 		local ray = Ray.new(coin.Position, Vector3.new(0, -200, 0))
 		local hit, pos = Workspace:FindPartOnRay(ray, coin)
 		if hit then
 			coin.Position = pos + Vector3.new(0, 2, 0)
 		end
 
 
		local debounce = false
		coin.Touched:Connect(function(hit)
			if debounce then return end
			local char = hit.Parent
			local p = game.Players:GetPlayerFromCharacter(char)
			if p then
				debounce = true
				local stats = p:FindFirstChild("leaderstats")
				if stats and stats:FindFirstChild("Coins") then
					stats.Coins.Value += 1 -- Dodaje monetę bezpiecznie na serwerze
				end
				coin:Destroy()
			end
		end)
 	end
 	
 	-- Usuwamy niezebrane monety po 2 minutach
 	task.delay(120, function()
 		if folder then folder:ClearAllChildren() end
 	end)
 end

-- Twoje ID produktów (Rarity)
local CaseSettings = {
	[3558948736] = "Common", 
	[3558948814] = "Rare", 
	[3558949097] = "Epic",
	[3558949533] = "Legendary", 
	[3558950075] = "Mythic", 
	[3558950464] = "Brainrot God",
	[3558950670] = "Secret", 
	[3558951376] = "OG"
}

-- Funkcja pomocnicza do tworzenia/pobierania folderu kolekcji
local function getCollection(player)
	local collection = player:FindFirstChild("BrainrotCollection")
	if not collection then
		collection = Instance.new("Folder")
		collection.Name = "BrainrotCollection"
		collection.Parent = player
	end
	return collection
end

-- Funkcja szukająca tego, czego gracz JESZCZE NIE MA
local function getMissingItems(player, targetRarity)
	local collection = getCollection(player)
	local missing = {}
	local targetRarityUpper = string.upper(targetRarity)

	for _, model in pairs(BrainrotStorage:GetChildren()) do
		local modelRarity = string.upper(model:GetAttribute("Rarity") or "Common")

		if modelRarity == targetRarityUpper then
			if not collection:FindFirstChild(model.Name) then
				table.insert(missing, model)
			end
		end
	end
	return missing
end

-- 1. OBSŁUGA ZAKUPÓW W SKLEPIE
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local requestedRarity = CaseSettings[receiptInfo.ProductId]
	if not requestedRarity then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local missingItems = getMissingItems(player, requestedRarity)

	if #missingItems == 0 then
		warn("Gracz " .. player.Name .. " ma już wszystko z kategorii " .. requestedRarity)
		return Enum.ProductPurchaseDecision.PurchaseGranted 
	end

	-- === DODAWANIE DO GLOBALNEJ PULI ROBUX ===
	local success, pInfo = pcall(function()
		return MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product)
	end)
	
	if success and pInfo then
		local robuxPrice = pInfo.PriceInRobux or 0
		GlobalRobuxPool += robuxPrice
		Sponsors[player.Name] = true
		print("Aktualna pula Robux: " .. GlobalRobuxPool .. " (Ostatni zakup: " .. player.Name .. " za " .. robuxPrice .. " R$)")

		if GlobalRobuxPool >= 1000 and not isEventActive then
			isEventActive = true
			local sponsorNames = {}
			for name, _ in pairs(Sponsors) do table.insert(sponsorNames, name) end
			local sponsorList = table.concat(sponsorNames, ", ")
			
			print("!!! TRIGERING COIN RAIN !!! Sponsorzy: " .. sponsorList)
			CoinRainTrigger:FireAllClients(sponsorList)
			
			-- NOWE: Spawn fizycznych monet na mapie (DOCELOWO 400)
			spawnPhysicalCoins(400)
			
			-- Reset puli i sponsorów (Pieniądze "zużyte" na ten event)
			GlobalRobuxPool = 0
			Sponsors = {}
			
			-- Synchronizacja (Reset)
			PoolUpdated:FireAllClients(0)
			
			-- Odblokowanie po czasie trwania
			task.delay(EVENT_DURATION, function()
				isEventActive = false
				-- Jeśli w międzyczasie nazbierało się kolejne 1000 R$ (bo np. ktoś kupił droższy item), 
				-- to pool zostanie obsłużony przy kolejnym zakupie.
			end)
		else
			-- Postęp w puli
			PoolUpdated:FireAllClients(GlobalRobuxPool)
		end
	end

	local wonModel = missingItems[math.random(1, #missingItems)]
	local collection = getCollection(player)

	-- Zapis nagrody (marker)
	if not collection:FindFirstChild(wonModel.Name) then
		local marker = Instance.new("BoolValue")
		marker.Name = wonModel.Name
		marker.Parent = collection
	end

	-- Efekt otwierania skrzyni
	BrainrotCollectedEvent:FireClient(player, "PLAY_ANIM")
	task.wait(1.5) 

	-- Wysłanie info o modelu
	BrainrotCollectedEvent:FireClient(player, wonModel.Name)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- 2. OBSŁUGA ZBIERANIA Z MAPY (Szybki zapis na serwerze)
BrainrotCollectedEvent.OnServerEvent:Connect(function(player, brainrotName)
	-- Sprawdzamy, czy to na pewno nazwa modelu, a nie sygnał animacji
	if type(brainrotName) ~= "string" or brainrotName == "PLAY_ANIM" then return end

	local collection = getCollection(player)
	if collection:FindFirstChild(brainrotName) then return end

	-- Sanity Check dystansu
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local brainrotModel = BrainrotyFolder:FindFirstChild(brainrotName)

	if not humanoidRootPart or not brainrotModel then
		warn("[Sanity Check] Nieprawidłowe żądanie od gracza " .. player.Name .. " dla: " .. tostring(brainrotName))
		return
	end

	local targetPosition = nil
	local primaryPart = brainrotModel.PrimaryPart or brainrotModel:FindFirstChild("Hitbox") or brainrotModel:FindFirstChild("RootPart") or brainrotModel:FindFirstChildWhichIsA("BasePart")
	
	if primaryPart then
		targetPosition = primaryPart.Position
	else
		local cf, _ = brainrotModel:GetBoundingBox()
		targetPosition = cf.Position
	end

	if targetPosition then
		local distance = (humanoidRootPart.Position - targetPosition).Magnitude
		if distance > MAX_COLLECT_DISTANCE then
			warn("[Anti-Cheat] Gracz " .. player.Name .. " odrzucony. Odległość " .. math.floor(distance) .. " jest większa niż max " .. MAX_COLLECT_DISTANCE)
			return
		end
	end

	-- Pozytywna weryfikacja dystansu - zapisujemy
	local marker = Instance.new("BoolValue")
	marker.Name = brainrotName
	marker.Parent = collection
	
	local safeAttributeName = string.gsub(brainrotName, " ", "_")
	safeAttributeName = string.gsub(safeAttributeName, "[^%w_]", "")
	player:SetAttribute("Collected_" .. safeAttributeName, true)
	-- print("Serwer zapisał zebranie z mapy: " .. brainrotName)
end)

-- Synchronizacja Robuxów przy wejściu gracza
game.Players.PlayerAdded:Connect(function(player)
	PoolUpdated:FireClient(player, GlobalRobuxPool)
end)

-- OBSŁUGA REBIRTH (Logika Kasowania i Fizyka)
RebirthEvent.OnServerEvent:Connect(function(player)
	local collection = player:FindFirstChild("BrainrotCollection")
	
	-- Sprawdza, czy liczba elementów w folderze BrainrotCollection gracza wynosi 143.
	if collection and #collection:GetChildren() >= 143 then
		
		-- Zapisujemy pozycję gracza
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			RebirthPositions[player.UserId] = player.Character.HumanoidRootPart.CFrame
		end
		
		-- Wysyłanie efektu do klienta
		RebirthEffect:FireClient(player)
		
		-- Dłuższe opóźnienie na animację (1.5 sekundy na trzęsienie i zoom)
		task.delay(1.5, function()
			-- Ustawia wartość Coins gracza twardo na 0.
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local coins = stats:FindFirstChild("Coins")
				if coins then coins.Value = 0 end
				
				local rebirths = stats:FindFirstChild("Rebirths")
				if rebirths then rebirths.Value = rebirths.Value + 1 end
			end

			-- Reset kolekcji
			if collection then collection:ClearAllChildren() end
			
			-- Reset atrybutów
			for attrName, _ in pairs(player:GetAttributes()) do
				if string.match(attrName, "^Collected_") then
					player:SetAttribute(attrName, nil)
				end
			end
			
			-- Odświeżenie postaci (bez zabijania)
			player:LoadCharacter()
		end)
	end
end)

-- Fizyka (Nakładanie buffów do ruchu przy respawnie)
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local hrp = character:WaitForChild("HumanoidRootPart")
		
		-- Teleportacja powrotna jeśli to był Rebirth
		if RebirthPositions[player.UserId] then
			hrp.CFrame = RebirthPositions[player.UserId]
			RebirthPositions[player.UserId] = nil
		end
		
		-- Pobieranie Rebirths
		local stats = player:WaitForChild("leaderstats")
		local rebirths = stats:WaitForChild("Rebirths")
		
		-- Obliczanie zredukowanych buffów (Zredukowane o połowę)
		local multiplier = 1
		if rebirths.Value == 1 then
			multiplier = 1.25 -- Było 1.5
		elseif rebirths.Value == 2 then
			multiplier = 1.5 -- Było 2.0
		elseif rebirths.Value >= 3 then
			multiplier = 2 -- Było 3.0
		end
		
		-- Modifikacja statystyk
		humanoid.WalkSpeed = math.floor(16 * multiplier)
		humanoid.JumpPower = math.floor(50 * multiplier)
		humanoid.UseJumpPower = true 
		
		-- Napis PRESTIŻ nad głową (jeśli gracz ma powyżej 0 Rebirths)
		if rebirths.Value > 0 then
			local head = character:WaitForChild("Head", 5)
			if head then
				local gui = Instance.new("BillboardGui")
				gui.Name = "PrestigeGui"
				gui.Size = UDim2.fromScale(3.5, 0.8) -- Mniejszy rozmiar
				gui.StudsOffset = Vector3.new(0, 2.8, 0)
				gui.Adornee = head
				gui.AlwaysOnTop = true
				
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.fromScale(1, 1)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = "PRESTIŻ " .. rebirths.Value
				textLabel.TextColor3 = Color3.new(1, 1, 1) -- Bazowy biały pod gradient
				textLabel.Font = Enum.Font.FredokaOne
				textLabel.TextScaled = true
				textLabel.Parent = gui
				
				local gradient = Instance.new("UIGradient")
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 0)), -- Złoto
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Błysk
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0)) -- Ciemne Złoto
				})
				gradient.Rotation = 90
				gradient.Parent = textLabel
				
				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.new(0, 0, 0)
				stroke.Thickness = 2.5
				stroke.Parent = textLabel
				
				-- Małe gwiazdki po bokach dla luksusu
				textLabel.Text = "✨ " .. textLabel.Text .. " ✨"
				
				gui.Parent = head
				
				-- === KROK 2: AURA DLA GRACZY Z ODRODZENIEM ===
				if rebirths.Value >= 1 then
					local aura = Instance.new("Highlight")
					aura.Name = "RebirthAura"
					aura.Adornee = character
					aura.Adornee = character
					aura.FillTransparency = 0.9 -- Jeszcze subtelniejszy (praktycznie niewidoczny środek)
					aura.OutlineTransparency = 0.8 -- Bardzo miękki obrys
					aura.Parent = character
					
					local particles = Instance.new("ParticleEmitter")
					particles.Name = "RebirthParticles"
					particles.Texture = "rbxassetid://13214144415"
					particles.EmissionDirection = Enum.EmissionDirection.Top
					particles.Rate = 20
					particles.Lifetime = NumberRange.new(1, 1.5)
					particles.Speed = NumberRange.new(3, 5)
					
					local rb = rebirths.Value
					if rb == 1 then
						-- Kolory ustawia Klient (RenderStepped), tu dajemy tylko cząsteczki
						particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
					elseif rb == 2 then
						-- Kolory ustawia Klient (RenderStepped)
						particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
					elseif rb == 3 then
						particles.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
							ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 80, 80)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
						})
					else
						particles.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
							ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 255, 0)),
							ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 0)),
							ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
						})
					end
					
					particles.Parent = hrp
				end
			end
		end
	end)
end)

-- OBSŁUGA ZBIERANIA MONET Z DESZCZU (+1 Moneta)