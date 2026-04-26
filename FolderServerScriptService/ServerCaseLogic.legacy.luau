local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))

local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local BrainrotCollectedEvent = BrainrotEvents:WaitForChild("BrainrotCollected")
local OgBrainrotDiscoveryAnnouncement = BrainrotEvents:FindFirstChild("OgBrainrotDiscoveryAnnouncement") or Instance.new("RemoteEvent", BrainrotEvents)
OgBrainrotDiscoveryAnnouncement.Name = "OgBrainrotDiscoveryAnnouncement"
local BrainrotyFolder = Workspace:WaitForChild("Brainroty")

local SPECIAL_ANNOUNCEMENT_BRAINROT = "Strawberry Elephant"

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

local RequestOGTeleport = BrainrotEvents:FindFirstChild("RequestOGTeleport") or Instance.new("RemoteFunction", BrainrotEvents)
RequestOGTeleport.Name = "RequestOGTeleport"
local SpawnSystemServerEvent = BrainrotEvents:FindFirstChild("SpawnSystemServerEvent") or Instance.new("BindableEvent", BrainrotEvents)
SpawnSystemServerEvent.Name = "SpawnSystemServerEvent"
local collectRequestRateByUserId = {} -- [UserId] = { windowStart = number, requestCount = number }

local GlobalRobuxPool = 0
local Sponsors = {} -- Zachowujemy dla kompatybilności paska (opcjonalnie)
local isEventActive = false -- STARY FLAG (Zostawiam dla kompatybilności paska, ale użyjemy IsRainActive do kolejki)

local function addRobuxSpent(player, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount > 0 then
		player:SetAttribute("RobuxSpent", (player:GetAttribute("RobuxSpent") or 0) + amount)
	end
end

local function announceRareDiscovery(player, brainrotName, rarity)
	if brainrotName ~= SPECIAL_ANNOUNCEMENT_BRAINROT then
		return
	end

	OgBrainrotDiscoveryAnnouncement:FireAllClients(player.Name, brainrotName, rarity or "OG")
end

local function isCollectRequestRateLimited(player)
	local now = time()
	local rateWindow = GameConfig.CollectRequestRateWindow or 1.0
	local maxRequestsPerWindow = GameConfig.MaxCollectRequestsPerWindow or 100 -- Ogromny limit, by gracze z lagiem nie gubili brainrotów
	local currentState = collectRequestRateByUserId[player.UserId]

	if not currentState or (now - currentState.windowStart) > rateWindow then
		collectRequestRateByUserId[player.UserId] = {
			windowStart = now,
			requestCount = 1
		}
		return false
	end

	currentState.requestCount += 1
	return currentState.requestCount > maxRequestsPerWindow
end

-- NOWE: Kolejkowanie
local QueuedRains = 0
local IsRainActive = false
local CurrentSponsors = {} -- Tabela nicków dla obecnej puli
local SponsorQueue = {} -- Kolejka tabel sponsorów


-- === KONFIGURACJA MONET NA MAPIE ===
local PHYSICAL_COIN_MESH = "rbxassetid://4937522724"
local DEFAULT_SPAWN_RANGE = 600
local COIN_REWARD = GameConfig.CoinRainCoinReward or 5
local COIN_SPAWN_BOUNDS_PADDING = 10
local COIN_SPAWN_VERTICAL_PADDING = 140
local COIN_SPAWN_ATTEMPTS = 8
local coinRainRandom = Random.new()

local function getBoundsFromInstance(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		local halfSize = instance.Size * 0.5
		return {
			minX = instance.Position.X - halfSize.X,
			maxX = instance.Position.X + halfSize.X,
			minZ = instance.Position.Z - halfSize.Z,
			maxZ = instance.Position.Z + halfSize.Z,
			minY = instance.Position.Y - halfSize.Y,
			maxY = instance.Position.Y + halfSize.Y,
		}
	end

	if instance:IsA("Model") then
		local cf, size = instance:GetBoundingBox()
		local halfSize = size * 0.5
		return {
			minX = cf.Position.X - halfSize.X,
			maxX = cf.Position.X + halfSize.X,
			minZ = cf.Position.Z - halfSize.Z,
			maxZ = cf.Position.Z + halfSize.Z,
			minY = cf.Position.Y - halfSize.Y,
			maxY = cf.Position.Y + halfSize.Y,
		}
	end

	return nil
end

local function findCoinRainBoundsOverride()
	local override = Workspace:FindFirstChild("CoinRainBounds")
	if not override then
		return nil
	end

	return getBoundsFromInstance(override)
end

local function isCharacterPart(part)
	local ancestorModel = part:FindFirstAncestorOfClass("Model")
	if not ancestorModel then
		return false
	end

	return Players:GetPlayerFromCharacter(ancestorModel) ~= nil
end

local function shouldUsePartForCoinRainBounds(part)
	if not part:IsA("BasePart") then
		return false
	end

	if part:IsDescendantOf(PhysicalCoinsFolder) then
		return false
	end

	if isCharacterPart(part) then
		return false
	end

	local activePetsFolder = Workspace:FindFirstChild("ActivePets")
	if activePetsFolder and part:IsDescendantOf(activePetsFolder) then
		return false
	end

	if part.Transparency >= 1 then
		return false
	end

	if not part.Anchored then
		return false
	end

	if not part.CanCollide then
		return false
	end

	if part.Size.X <= 0 or part.Size.Z <= 0 then
		return false
	end

	return true
end

local function computeCoinRainSpawnBounds()
	local overrideBounds = findCoinRainBoundsOverride()
	if overrideBounds then
		overrideBounds.minX -= COIN_SPAWN_BOUNDS_PADDING
		overrideBounds.maxX += COIN_SPAWN_BOUNDS_PADDING
		overrideBounds.minZ -= COIN_SPAWN_BOUNDS_PADDING
		overrideBounds.maxZ += COIN_SPAWN_BOUNDS_PADDING
		overrideBounds.rayOriginY = overrideBounds.maxY + COIN_SPAWN_VERTICAL_PADDING
		overrideBounds.rayLength = math.max((overrideBounds.maxY - overrideBounds.minY) + (COIN_SPAWN_VERTICAL_PADDING * 2), 500)
		return overrideBounds
	end

	local bounds = nil

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if shouldUsePartForCoinRainBounds(descendant) then
			local halfSize = descendant.Size * 0.5
			local minX = descendant.Position.X - halfSize.X
			local maxX = descendant.Position.X + halfSize.X
			local minZ = descendant.Position.Z - halfSize.Z
			local maxZ = descendant.Position.Z + halfSize.Z
			local minY = descendant.Position.Y - halfSize.Y
			local maxY = descendant.Position.Y + halfSize.Y

			if not bounds then
				bounds = {
					minX = minX,
					maxX = maxX,
					minZ = minZ,
					maxZ = maxZ,
					minY = minY,
					maxY = maxY,
				}
			else
				bounds.minX = math.min(bounds.minX, minX)
				bounds.maxX = math.max(bounds.maxX, maxX)
				bounds.minZ = math.min(bounds.minZ, minZ)
				bounds.maxZ = math.max(bounds.maxZ, maxZ)
				bounds.minY = math.min(bounds.minY, minY)
				bounds.maxY = math.max(bounds.maxY, maxY)
			end
		end
	end

	if not bounds then
		return {
			minX = -DEFAULT_SPAWN_RANGE,
			maxX = DEFAULT_SPAWN_RANGE,
			minZ = -DEFAULT_SPAWN_RANGE,
			maxZ = DEFAULT_SPAWN_RANGE,
			minY = 0,
			maxY = 150,
			rayOriginY = 250,
			rayLength = 500,
		}
	end

	bounds.minX -= COIN_SPAWN_BOUNDS_PADDING
	bounds.maxX += COIN_SPAWN_BOUNDS_PADDING
	bounds.minZ -= COIN_SPAWN_BOUNDS_PADDING
	bounds.maxZ += COIN_SPAWN_BOUNDS_PADDING
	bounds.rayOriginY = bounds.maxY + COIN_SPAWN_VERTICAL_PADDING
	bounds.rayLength = math.max((bounds.maxY - bounds.minY) + (COIN_SPAWN_VERTICAL_PADDING * 2), 500)

	return bounds
end

local function buildCoinRainRaycastParams()
	local exclusions = {PhysicalCoinsFolder, BrainrotyFolder}
	local activePetsFolder = Workspace:FindFirstChild("ActivePets")
	if activePetsFolder then
		table.insert(exclusions, activePetsFolder)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(exclusions, player.Character)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclusions
	params.IgnoreWater = false

	return params
end

local function getFallbackCoinSpawnPosition()
	return Vector3.new(
		coinRainRandom:NextNumber(-DEFAULT_SPAWN_RANGE, DEFAULT_SPAWN_RANGE),
		100,
		coinRainRandom:NextNumber(-DEFAULT_SPAWN_RANGE, DEFAULT_SPAWN_RANGE)
	)
end

local function findCoinSpawnPosition(bounds, raycastParams)
	if not bounds then
		return getFallbackCoinSpawnPosition()
	end

	for _ = 1, COIN_SPAWN_ATTEMPTS do
		local origin = Vector3.new(
			coinRainRandom:NextNumber(bounds.minX, bounds.maxX),
			bounds.rayOriginY,
			coinRainRandom:NextNumber(bounds.minZ, bounds.maxZ)
		)
		local result = Workspace:Raycast(origin, Vector3.new(0, -bounds.rayLength, 0), raycastParams)
		if result and result.Instance and result.Normal.Y >= 0.45 then
			return result.Position + Vector3.new(0, 2, 0)
		end
	end

	return getFallbackCoinSpawnPosition()
end

local function spawnPhysicalCoins(count)
	local folder = PhysicalCoinsFolder
	folder:ClearAllChildren()
	local spawnBounds = computeCoinRainSpawnBounds()
	local raycastParams = buildCoinRainRaycastParams()

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
		coin.Size = Vector3.new(3, 3, 0.5)
		coin.Position = findCoinSpawnPosition(spawnBounds, raycastParams)
		coin.CanCollide = false
		coin.Anchored = true
		coin.Parent = folder

		local debounce = false
		coin.Touched:Connect(function(hit)
			if debounce then return end
			local char = hit.Parent
			local p = Players:GetPlayerFromCharacter(char)
			if p then
				debounce = true
				local stats = p:FindFirstChild("leaderstats")
				if stats and stats:FindFirstChild("Coins") then
					local amountToAdd = math.ceil(COIN_REWARD * (p:GetAttribute("CoinMultiplier") or 1))
					stats.Coins.Value += amountToAdd
					
				end
				coin:Destroy()
			end
		end)
	end

	-- Usuwamy niezebrane monety po 2 minutach (Fallback)
	task.delay(120, function()
		if folder then folder:ClearAllChildren() end
	end)
end

-- NOWE: Funkcja zarządzająca kolejką
local function checkRainQueue()
	if IsRainActive then return end
	
	if QueuedRains > 0 then
		IsRainActive = true
		task.spawn(function()
			while QueuedRains > 0 do
				QueuedRains -= 1
				PoolUpdated:FireAllClients(GlobalRobuxPool, QueuedRains) -- Synchronizacja kolejki
				
				local activeSponsors = table.remove(SponsorQueue, 1) or {"ANONYMOUS"}
				
				print("!!! STARTING QUEUED COIN RAIN !!! Remaining: " .. QueuedRains)
				CoinRainTrigger:FireAllClients(activeSponsors)
				spawnPhysicalCoins(400)
				
				task.wait(GameConfig.CoinRainDuration)
				
				-- Sprzątanie monet
				if PhysicalCoinsFolder then
					PhysicalCoinsFolder:ClearAllChildren()
				end
				
				-- Bufor między deszczami
				task.wait(5)
			end
			IsRainActive = false
		end)
	end
end

-- NOWE: Zunifikowana funkcja zarządzająca globalną pulą Robux
local function addToGlobalRobuxPool(player, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then return end
	
	addRobuxSpent(player, amount)
	GlobalRobuxPool += amount
	
	-- DODAWANIE SPONSORA (Bez duplikacji)
	if not table.find(CurrentSponsors, player.Name) then
		table.insert(CurrentSponsors, player.Name)
	end
	
	Sponsors[player.Name] = true -- Dla starszych systemów
	print("[COINRAIN] " .. player.Name .. " wydał " .. amount .. " " .. utf8.char(0xE002) .. ". Nowa pula: " .. GlobalRobuxPool)

	if GlobalRobuxPool >= GameConfig.CoinRainTriggerAmount then
		while GlobalRobuxPool >= GameConfig.CoinRainTriggerAmount do
			GlobalRobuxPool -= GameConfig.CoinRainTriggerAmount
			QueuedRains += 1
			table.insert(SponsorQueue, table.clone(CurrentSponsors))
		end
		
		CurrentSponsors = {} -- Reset dla następnej puli
		Sponsors = {} -- Reset starych sponsorów
		PoolUpdated:FireAllClients(GlobalRobuxPool, QueuedRains)
		checkRainQueue()
	else
		PoolUpdated:FireAllClients(GlobalRobuxPool, QueuedRains)
	end
end

-- NOWE: Komunikacja między skryptami dla wspólnej puli
local AddRobuxToPoolEvent = BrainrotEvents:FindFirstChild("AddRobuxToPool") or Instance.new("BindableEvent", BrainrotEvents)
AddRobuxToPoolEvent.Name = "AddRobuxToPool"
AddRobuxToPoolEvent.Event:Connect(addToGlobalRobuxPool)



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

-- 1. OBSŁUGA ZAKUPÓW W SKLEPIE (Centralna Kasa Fiskalna)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	-- Wspólna logika pobierania ceny
	local function getProductPrice(productId)
		local ok, pInfo = pcall(function()
			return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
		end)
		if ok and pInfo then
			return pInfo.PriceInRobux or 0
		end
		warn("[COINRAIN ERROR] Nie udało się pobrać ceny produktu: " .. tostring(productId))
		return 0
	end

	-- SPRAWDZENIE A: CZY TO JEST TROLL?
	local trollType = nil
	for name, id in pairs(GameConfig.TrollProducts) do
		if id == receiptInfo.ProductId then
			trollType = name
			break
		end
	end

	if trollType then
		local TrollExecuteEvent = BrainrotEvents:FindFirstChild("TrollExecuteLogic")
		if TrollExecuteEvent then
			local success = TrollExecuteEvent:Invoke(player, trollType)
			if success then
				local price = getProductPrice(receiptInfo.ProductId)
				addToGlobalRobuxPool(player, price)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("Nie udalo sie wykonac Trolla (Brak celu lub blad)")
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- SPRAWDZENIE C: CZY TO JEST PACZKA MONET?
	for packName, packData in pairs(GameConfig.CoinPacks) do
		if packData.ID == receiptInfo.ProductId then
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Coins") then
				stats.Coins.Value += packData.Amount
				
				local price = getProductPrice(receiptInfo.ProductId)
				addToGlobalRobuxPool(player, price)
				
				print(player.Name .. " kupił paczkę " .. packName .. " otrzymując " .. packData.Amount .. " monet!")
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
	end

	-- SPRAWDZENIE B: CZY TO JEST SKRZYNKA BRAINROT?
	local requestedRarity = nil
	for rarity, id in pairs(GameConfig.CaseProducts) do
		if id == receiptInfo.ProductId then
			requestedRarity = rarity
			break
		end
	end

	if not requestedRarity then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local missingItems = getMissingItems(player, requestedRarity)

	if #missingItems == 0 then
		warn("Gracz " .. player.Name .. " ma już wszystko z kategorii " .. requestedRarity)
		return Enum.ProductPurchaseDecision.PurchaseGranted 
	end

	-- Dodanie do puli
	local price = getProductPrice(receiptInfo.ProductId)
	addToGlobalRobuxPool(player, price)

	local wonModel = missingItems[math.random(1, #missingItems)]
	local collection = getCollection(player)

	-- Zapis nagrody (marker i atrybut)
	if not collection:FindFirstChild(wonModel.Name) then
		local marker = Instance.new("BoolValue")
		marker.Name = wonModel.Name
		marker.Parent = collection
		
		local safeAttributeName = string.gsub(wonModel.Name, " ", "_")
		safeAttributeName = string.gsub(safeAttributeName, "[^%w_]", "")
		player:SetAttribute("Collected_" .. safeAttributeName, true)
		
		-- NOWE: Konsumpcja wskazówki (usunięcie z DataStore/folderu)
		local hints = player:FindFirstChild("BoughtHints")
		local rarity = wonModel:GetAttribute("Rarity") or "Common"
		if hints and hints:FindFirstChild(rarity) then
			hints[rarity]:Destroy()
		end

		announceRareDiscovery(player, wonModel.Name, rarity)
	end

	-- Efekt otwierania skrzyni
	BrainrotCollectedEvent:FireClient(player, "PLAY_ANIM")
	task.wait(1.5) 

	-- Wysłanie info o modelu
	BrainrotCollectedEvent:FireClient(player, wonModel.Name)
	
	local ServerUpdateQuestProgress = BrainrotEvents:FindFirstChild("ServerUpdateQuestProgress")
	if ServerUpdateQuestProgress then
		ServerUpdateQuestProgress:Fire(player, "CollectBrainrots", 1)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local OpenSpecificCaseEvent = BrainrotEvents:FindFirstChild("OpenSpecificCase") or Instance.new("BindableEvent", BrainrotEvents)
OpenSpecificCaseEvent.Name = "OpenSpecificCase"
OpenSpecificCaseEvent.Event:Connect(function(player, requestedRarity)
	local missingItems = getMissingItems(player, requestedRarity)

	if #missingItems == 0 then
		warn("Gracz " .. player.Name .. " ma już wszystko z kategorii " .. requestedRarity .. " (StarterPack)")
		return 
	end

	local wonModel = missingItems[math.random(1, #missingItems)]
	local collection = getCollection(player)

	if not collection:FindFirstChild(wonModel.Name) then
		local marker = Instance.new("BoolValue")
		marker.Name = wonModel.Name
		marker.Parent = collection
		
		local safeAttributeName = string.gsub(wonModel.Name, " ", "_")
		safeAttributeName = string.gsub(safeAttributeName, "[^%w_]", "")
		player:SetAttribute("Collected_" .. safeAttributeName, true)
		
		local hints = player:FindFirstChild("BoughtHints")
		local rarity = wonModel:GetAttribute("Rarity") or "Common"
		if hints and hints:FindFirstChild(rarity) then
			hints[rarity]:Destroy()
		end

		announceRareDiscovery(player, wonModel.Name, rarity)
	end

	BrainrotCollectedEvent:FireClient(player, "PLAY_ANIM")
	task.wait(1.5) 
	BrainrotCollectedEvent:FireClient(player, wonModel.Name)
	
	local ServerUpdateQuestProgress = BrainrotEvents:FindFirstChild("ServerUpdateQuestProgress")
	if ServerUpdateQuestProgress then
		ServerUpdateQuestProgress:Fire(player, "CollectBrainrots", 1)
	end

end)

game.Players.PlayerRemoving:Connect(function(player)
	collectRequestRateByUserId[player.UserId] = nil
end)

-- 2. OBSŁUGA ZBIERANIA Z MAPY (Szybki zapis na serwerze)
BrainrotCollectedEvent.OnServerEvent:Connect(function(player, brainrotName)
	-- Sprawdzamy, czy to na pewno nazwa modelu, a nie sygnał animacji
	if type(brainrotName) ~= "string" or brainrotName == "PLAY_ANIM" then return end
	if isCollectRequestRateLimited(player) then
		warn("[Anti-Cheat] Gracz " .. player.Name .. " wysyla zbyt wiele requestow collect.")
		return
	end

	local collection = getCollection(player)
	if collection:FindFirstChild(brainrotName) then return end

	-- Sanity Check dystansu
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local brainrotModel = BrainrotyFolder:FindFirstChild(brainrotName)
	
	-- Pobieramy wzorzec ze storage, aby znać rzadkość
	local modelTemplate = BrainrotStorage:FindFirstChild(brainrotName)

	if not humanoid or humanoid.Health <= 0 or not humanoidRootPart or not brainrotModel or not modelTemplate then
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

	if not targetPosition then
		warn("[Sanity Check] Nie udalo sie ustalic pozycji collecta dla: " .. tostring(brainrotName))
		return
	end

	if targetPosition then
		local distance = (humanoidRootPart.Position - targetPosition).Magnitude
		local maxDist = GameConfig.MaxCollectDistance or 60
		if maxDist < 60 then maxDist = 60 end -- Bezpieczny bufor dla szybko biegających graczy (np. ze Speed Boostem)
		
		if distance > maxDist then
			warn("[Anti-Cheat] Gracz " .. player.Name .. " odrzucony. Odległość " .. math.floor(distance) .. " jest większa niż max " .. maxDist)
			return
		end
	end

	-- Pozytywna weryfikacja dystansu - zapisujemy
	local marker = Instance.new("BoolValue")
	marker.Name = brainrotName
	marker.Parent = collection

	-- NOWE: Konsumpcja wskazówki przy zebraniu z mapy
	local hints = player:FindFirstChild("BoughtHints")
	local rarity = modelTemplate and (modelTemplate:GetAttribute("Rarity") or "Common") or "Common"
	if hints and hints:FindFirstChild(rarity) then
		hints[rarity]:Destroy()
	end

	announceRareDiscovery(player, brainrotName, rarity)

	local safeAttributeName = string.gsub(brainrotName, " ", "_")
	safeAttributeName = string.gsub(safeAttributeName, "[^%w_]", "")
	player:SetAttribute("Collected_" .. safeAttributeName, true)
	
	local ServerUpdateQuestProgress = BrainrotEvents:FindFirstChild("ServerUpdateQuestProgress")
	if ServerUpdateQuestProgress then
		ServerUpdateQuestProgress:Fire(player, "CollectBrainrots", 1)
	end

	if rarity == "OG" then
		SpawnSystemServerEvent:Fire("HandleOGCollected", player)
	end
end)

-- Synchronizacja Robuxów przy wejściu gracza
game.Players.PlayerAdded:Connect(function(player)
	PoolUpdated:FireClient(player, GlobalRobuxPool, QueuedRains)
end)

-- OBSŁUGA PORTALU OG (Walidacja Serwerowa - KROK 4)
RequestOGTeleport.OnServerInvoke = function(player)
	local BrainrotUtils = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("BrainrotUtils"))
	
	-- Twarde sprawdzanie ilości (Zmienione: teleport wymaga tylko skompletowania rzadkości "Secret")
	if BrainrotUtils.hasCompletedRarity(player, "Secret") then
		SpawnSystemServerEvent:Fire("EnterOG", player)
		return true
	end
	
	return false
end

-- OBSŁUGA REBIRTH (Logika Kasowania i Fizyka)
RebirthEvent.OnServerEvent:Connect(function(player)
	local collection = player:FindFirstChild("BrainrotCollection")

	-- Sprawdza, czy liczba elementów w folderze BrainrotCollection gracza wynosi GameConfig.TotalBrainrots.
	if collection and #collection:GetChildren() >= GameConfig.TotalBrainrots then
		local rebirthReturnCFrame = nil

		-- Zapisujemy pozycję gracza
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			rebirthReturnCFrame = player.Character.HumanoidRootPart.CFrame
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
			if rebirthReturnCFrame then
				SpawnSystemServerEvent:Fire("SetRespawnOverride", player, { cframe = rebirthReturnCFrame })
			end
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

		-- Pobieranie Rebirths
		local stats = player:WaitForChild("leaderstats")
		local rebirths = stats:WaitForChild("Rebirths")

		-- Obliczanie zredukowanych buffów (Zredukowane o połowę)
		local function updateStatsAndVIP()
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				-- Usunięto nadpisywanie statystyk (teraz w całości obsługuje to SettingsService.server.luau)
				humanoid.UseJumpPower = true 
			end

			-- Napis VIP nad głową
			if player:GetAttribute("HasVIP") then
				local head = character:FindFirstChild("Head")
				if head and not head:FindFirstChild("VIPGui") then
					local vipGui = Instance.new("BillboardGui")
					vipGui.Name = "VIPGui"
					vipGui.Size = UDim2.fromScale(3.5, 0.8)
					
					-- Jeśli ma też prestiż, dajemy wyżej
					if rebirths.Value > 0 then
						vipGui.StudsOffset = Vector3.new(0, 4.0, 0)
					else
						vipGui.StudsOffset = Vector3.new(0, 2.8, 0)
					end
					
					vipGui.Adornee = head
					vipGui.AlwaysOnTop = true

					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.fromScale(1, 1)
					textLabel.BackgroundTransparency = 1
					textLabel.Text = "VIP"
					textLabel.TextColor3 = Color3.new(1, 1, 1)
					textLabel.Font = Enum.Font.FredokaOne
					textLabel.TextScaled = true
					textLabel.Parent = vipGui

					local gradient = Instance.new("UIGradient")
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)), -- Złoto
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 200)), -- Jasne złoto/Błysk
						ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 0)) -- Ciemne Złoto
					})
					gradient.Rotation = 90
					gradient.Parent = textLabel

					local stroke = Instance.new("UIStroke")
					stroke.Color = Color3.new(0, 0, 0)
					stroke.Thickness = 2.5
					stroke.Parent = textLabel

					vipGui.Parent = head
				end
			end
		end

		-- Wywołujemy od razu na wypadek gdy atrybut już jest
		updateStatsAndVIP()
		
		-- Podpinamy dynamiczne nasłuchiwanie
		player:GetAttributeChangedSignal("HasVIP"):Connect(updateStatsAndVIP)
		player:GetAttributeChangedSignal("HasSpeedBoost"):Connect(updateStatsAndVIP)
		player:GetAttributeChangedSignal("HasJumpBoost"):Connect(updateStatsAndVIP)

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

				-- Usunięto gwiazdki zgodnie z życzeniem

				gui.Parent = head
			end
		end

		-- === KROK 2: SZEROKA POŚWIATA (STYL COIN RAIN - TYLKO TRAIL) ===
		-- (Przeniesione do SettingsService.server.luau by umożliwić wybór traila)
		--[[
				if rebirths.Value >= 1 then
					-- Tworzymy szerokie mocowanie po bokach gracza (Oś X) - rozstaw 2.25 studs
					local att0 = Instance.new("Attachment")
					att0.Name = "TrailAtt0"
					att0.Position = Vector3.new(1.125, 0, 0) -- Prawa strona
					att0.Parent = hrp

					local att1 = Instance.new("Attachment")
					att1.Name = "TrailAtt1"
					att1.Position = Vector3.new(-1.125, 0, 0) -- Lewa strona
					att1.Parent = hrp

					local trail = Instance.new("Trail")
					trail.Name = "RebirthTrail"
					trail.Attachment0 = att0
					trail.Attachment1 = att1
					trail.Lifetime = 0.8 -- Długi ogon (jak w Coin Rain)
					trail.FaceCamera = true -- Zawsze zwrócony przodem do kamery

					-- Gładkie znikanie na końcu ogona
					trail.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1)
					})

					-- Zwężanie się (jak w Coin Rain)
					trail.WidthScale = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0)
					})

					trail.LightEmission = 1
					trail.LightInfluence = 0

					-- TWOJE ORYGINALNE KOLORY REBIRTH
					local rb = rebirths.Value
					if rb == 1 then
						trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
					elseif rb == 2 then
						trail.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
					elseif rb == 3 then
						trail.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Neonowy Czerwony
							ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 0, 0)), -- Ciemna Czerwień (agresywny gradient)
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
				end
		]]
	end)
end)
