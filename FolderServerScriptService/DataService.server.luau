local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local openDailyRewardsPanelEvent = BrainrotEvents:FindFirstChild("OpenDailyRewardsPanel") or Instance.new("RemoteEvent")
openDailyRewardsPanelEvent.Name = "OpenDailyRewardsPanel"
openDailyRewardsPanelEvent.Parent = BrainrotEvents

-- 1. Inicjalizacja DataStore
local BrainrotData = DataStoreService:GetDataStore("BrainrotData_V1")
local QUEST_AUTOSAVE_INTERVAL = 60
local lastQuestAutosaveVersionByUserId = {}

-- Ustawienia domyślne dla nowych graczy
local DEFAULT_DATA = {
	Coins = 0,
	Rebirths = 0,
	Collection = {},
	BoughtHints = {}, -- NOWE: Zapisane podpowiedzi
	QuestDate = "", -- Data ostatniego losowania zadań
	DailyQuests = {}, -- Aktualne zadania i postęp
	LoginStreak = 1,
	LastClaimedDate = "",
	LastDailyRewardPromptDate = "",
	HasBoughtStarterPack = false,
	FreeFartTrolls = 0,
	StarterPackExpiry = 0,
	HasPurpleTrail = false,
	LatestUnlockedTrail = "",
	LatestUnlockedSpeedSetting = "",
	LatestUnlockedJumpSetting = "",
	SpeedBoostEnds = 0,
	JumpBoostEnds = 0,
}

-- Funkcja pomocnicza do bezpiecznego zapisu
local function saveData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local collection = player:FindFirstChild("BrainrotCollection")
	local boughtHints = player:FindFirstChild("BoughtHints") -- NOWE
	
	if not leaderstats or not collection or not boughtHints then
		return false
	end
	
	local dataToSave = {
		Coins = leaderstats.Coins.Value,
		Rebirths = leaderstats.Rebirths.Value,
		Collection = {},
		BoughtHints = {}, -- NOWE
		QuestDate = player:GetAttribute("QuestDate") or "",
		DailyQuests = {},
		LoginStreak = player:GetAttribute("LoginStreak") or 1,
		LastClaimedDate = player:GetAttribute("LastClaimedDate") or "",
		LastDailyRewardPromptDate = player:GetAttribute("LastDailyRewardPromptDate") or "",
		HasBoughtStarterPack = player:GetAttribute("HasBoughtStarterPack") or false,
		FreeFartTrolls = player:GetAttribute("FreeFartTrolls") or 0,
		StarterPackExpiry = player:GetAttribute("StarterPackExpiry") or 0,
		HasPurpleTrail = player:GetAttribute("HasPurpleTrail") or false,
		LatestUnlockedTrail = player:GetAttribute("LatestUnlockedTrail") or "",
		LatestUnlockedSpeedSetting = player:GetAttribute("LatestUnlockedSpeedSetting") or "",
		LatestUnlockedJumpSetting = player:GetAttribute("LatestUnlockedJumpSetting") or "",
		SpeedBoostEnds = player:GetAttribute("SpeedBoostEnds") or 0,
		JumpBoostEnds = player:GetAttribute("JumpBoostEnds") or 0,
	}
	
	local questsFolder = player:FindFirstChild("DailyQuestsFolder")
	if questsFolder then
		for _, q in ipairs(questsFolder:GetChildren()) do
			table.insert(dataToSave.DailyQuests, {ID = q.Name, Progress = q.Value, Claimed = q:GetAttribute("Claimed") or false})
		end
	end
	
	for _, item in ipairs(collection:GetChildren()) do
		table.insert(dataToSave.Collection, item.Name)
	end

	for _, hint in ipairs(boughtHints:GetChildren()) do
		table.insert(dataToSave.BoughtHints, hint.Name)
	end
	
	local success, err = pcall(function()
		BrainrotData:SetAsync(tostring(player.UserId), dataToSave)
	end)
	
	if success then
		print("Successfully saved data for " .. player.Name)
		return true
	else
		warn("Failed to save data for " .. player.Name .. ": " .. err)
		return false
	end
end

-- Aktualizacja Mnożnika Monet
local function updateCoinMultiplier(player)
	local multi = 1
	if player:GetAttribute("HasVIP") then
		multi = multi * 2
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rb = rebirths and rebirths.Value or 0
	
	if rb == 1 then multi = multi * 1.25
	elseif rb == 2 then multi = multi * 1.5
	elseif rb >= 3 then multi = multi * 2.0
	end
	
	player:SetAttribute("CoinMultiplier", multi)
end

-- 2. Funkcja PlayerAdded (Ładowanie Danych)
Players.PlayerAdded:Connect(function(player)
	local userId = tostring(player.UserId)
	local loadedData
	
	local success, result = pcall(function()
		return BrainrotData:GetAsync(userId)
	end)
	
	if success and result then
		loadedData = result
	else
		loadedData = DEFAULT_DATA
		if not success then
			warn("Error loading data for " .. player.Name .. ": " .. tostring(result))
		end
	end
	
	-- Tworzenie folderu leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = loadedData.Coins or 0
	coins.Parent = leaderstats
	
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = loadedData.Rebirths or 0
	rebirths.Parent = leaderstats
	
	leaderstats.Parent = player
	
	-- Nasłuchiwanie zmian w Rebirths
	rebirths:GetPropertyChangedSignal("Value"):Connect(function()
		updateCoinMultiplier(player)
	end)
	player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		updateCoinMultiplier(player)
	end)
	
	-- Tworzenie folderu BrainrotCollection
	local collectionFolder = Instance.new("Folder")
	collectionFolder.Name = "BrainrotCollection"
	
	if loadedData.Collection then
		for _, itemName in ipairs(loadedData.Collection) do
			local marker = Instance.new("BoolValue")
			marker.Name = itemName
			marker.Parent = collectionFolder
		end
	end
	collectionFolder.Parent = player

	-- LOGIKA DAILY REWARDS (Login Streak)
	local streak = loadedData.LoginStreak or 1
	local lastClaim = loadedData.LastClaimedDate or ""
	
	local todayStr = os.date("%Y%m%d")
	local yesterdayT = os.date("*t", os.time() - 86400)
	local yesterdayStr = string.format("%04d%02d%02d", yesterdayT.year, yesterdayT.month, yesterdayT.day)
	
	if lastClaim == todayStr or lastClaim == yesterdayStr then
		-- Utrzymujemy passę (albo odebrał wyżej dzisiaj, albo kwalifikuje się od wczoraj)
	else
		-- Reset, ponieważ pominął dzień (lub jest to jego pierwszy raz)
		streak = 1
	end
	
	player:SetAttribute("LoginStreak", streak)
	player:SetAttribute("LastClaimedDate", lastClaim)
	local lastDailyRewardPromptDate = loadedData.LastDailyRewardPromptDate or ""
	local shouldScheduleDailyRewardPrompt = lastDailyRewardPromptDate ~= todayStr and lastClaim ~= todayStr
	if lastDailyRewardPromptDate ~= todayStr then
		player:SetAttribute("LastDailyRewardPromptDate", todayStr)
	else
		player:SetAttribute("LastDailyRewardPromptDate", lastDailyRewardPromptDate)
	end
	if shouldScheduleDailyRewardPrompt then
		task.delay(180, function()
			if player.Parent ~= Players then
				return
			end
			if (player:GetAttribute("LastClaimedDate") or "") == todayStr then
				return
			end
			openDailyRewardsPanelEvent:FireClient(player)
		end)
	end
	
	player:SetAttribute("HasBoughtStarterPack", loadedData.HasBoughtStarterPack or false)
	player:SetAttribute("FreeFartTrolls", loadedData.FreeFartTrolls or 0)
	player:SetAttribute("HasPurpleTrail", loadedData.HasPurpleTrail or false)
	player:SetAttribute("LatestUnlockedTrail", loadedData.LatestUnlockedTrail or "")
	player:SetAttribute("LatestUnlockedSpeedSetting", loadedData.LatestUnlockedSpeedSetting or "")
	player:SetAttribute("LatestUnlockedJumpSetting", loadedData.LatestUnlockedJumpSetting or "")
	player:SetAttribute("SpeedBoostEnds", loadedData.SpeedBoostEnds or 0)
	player:SetAttribute("JumpBoostEnds", loadedData.JumpBoostEnds or 0)
	player:SetAttribute("QuestAutosaveVersion", 0)
	lastQuestAutosaveVersionByUserId[player.UserId] = 0
	
	-- Inicjowanie wygasania Starter Packa dla nowych i starych graczy bez tej wartości
	local expiry = loadedData.StarterPackExpiry or 0
	if expiry == 0 then
		expiry = os.time() + (24 * 60 * 60) -- 24 godziny od pierwszego dołączenia
	end
	player:SetAttribute("StarterPackExpiry", expiry)

	-- Tworzenie folderu BoughtHints (NOWE)
	local hintsFolder = Instance.new("Folder")
	hintsFolder.Name = "BoughtHints"

	if loadedData.BoughtHints then
		for _, rarityName in ipairs(loadedData.BoughtHints) do
			local marker = Instance.new("BoolValue")
			marker.Name = rarityName
			marker.Parent = hintsFolder
		end
	end
	hintsFolder.Parent = player
	
	-- LOGIKA DAILY QUESTS
	local today = os.date("%Y%m%d") -- Zwraca np. "20260329"
	local questsFolder = Instance.new("Folder")
	questsFolder.Name = "DailyQuestsFolder"
	
	player:SetAttribute("QuestDate", loadedData.QuestDate or "")
	
	-- Sprawdzamy czy to nowy dzień dla gracza
	if player:GetAttribute("QuestDate") ~= today then
		player:SetAttribute("QuestDate", today)
		-- Losowanie nowych zadań
		local availableQuests = table.clone(GameConfig.QuestSystem.Pool)
		for i = 1, GameConfig.QuestSystem.DailyCount do
			if #availableQuests == 0 then break end
			local randIndex = math.random(1, #availableQuests)
			local chosen = table.remove(availableQuests, randIndex)
			
			local qVal = Instance.new("IntValue")
			qVal.Name = chosen.ID
			qVal.Value = 0
			qVal.Parent = questsFolder
			qVal:SetAttribute("Claimed", false)
		end
		player:SetAttribute("QuestAutosaveVersion", 1)
	else
		-- Ładowanie zapisanych zadań
		if loadedData.DailyQuests then
			for _, qData in ipairs(loadedData.DailyQuests) do
				local qVal = Instance.new("IntValue")
				qVal.Name = qData.ID
				qVal.Value = qData.Progress or 0
				qVal:SetAttribute("Claimed", qData.Claimed or false)
				qVal.Parent = questsFolder
			end
		end
	end
	questsFolder.Parent = player
	
	-- LOGIKA PREMIUM SHOP (Game Passy)
	task.spawn(function()
		local hasVIP = false
		local hasSpeed = false
		local hasJump = false
		
		local s1, o1 = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GamePasses.VIPBundle) end)
		if (s1 and o1) or player.UserId == game.CreatorId then hasVIP = true end
		
		local s2, o2 = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GamePasses.SpeedBoost) end)
		if s2 and o2 then hasSpeed = true end
		
		local s3, o3 = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GamePasses.JumpBoost) end)
		if s3 and o3 then hasJump = true end
		
		if hasVIP then
			player:SetAttribute("HasVIP", true)
		end
		
		if hasSpeed then player:SetAttribute("HasSpeedBoost", true) end
		if hasJump then player:SetAttribute("HasJumpBoost", true) end
		
		updateCoinMultiplier(player)
	end)
	
	-- Nakładanie wizualnych efektów VIP na postać (przeniesione do SettingsService)
	--[[ 
	player.CharacterAdded:Connect(function(character)
		-- Dajemy chwilę na załadowanie atrybutów, jeśli to pierwsze dołączenie
		task.wait(1)
		
		if player:GetAttribute("HasVIP") then
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				local att0 = Instance.new("Attachment")
				att0.Name = "VIPTrailAtt0"
				att0.Position = Vector3.new(1.125, 0.5, 0)
				att0.Parent = hrp

				local att1 = Instance.new("Attachment")
				att1.Name = "VIPTrailAtt1"
				att1.Position = Vector3.new(-1.125, 0.5, 0)
				att1.Parent = hrp

				local trail = Instance.new("Trail")
				trail.Name = "VIPSoloTrail"
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
					ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)), -- Srebrny
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Biały
					ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150)) -- Szary
				})
				
				trail.Parent = hrp
			end
		end
	end)
	]]
	
end)

task.spawn(function()
	while true do
		task.wait(QUEST_AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local currentVersion = player:GetAttribute("QuestAutosaveVersion") or 0
			local lastSavedVersion = lastQuestAutosaveVersionByUserId[player.UserId] or 0
			if currentVersion > lastSavedVersion then
				local saveTargetVersion = currentVersion
				local saveSucceeded = saveData(player)
				if saveSucceeded then
					local latestVersion = player:GetAttribute("QuestAutosaveVersion") or 0
					if latestVersion == saveTargetVersion then
						lastQuestAutosaveVersionByUserId[player.UserId] = saveTargetVersion
					end
				end
			end
		end
	end
end)

-- 3. Funkcja PlayerRemoving (Zapisywanie Danych)
Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	lastQuestAutosaveVersionByUserId[player.UserId] = nil
end)

-- 4. Zabezpieczenie BindToClose (Zamykanie serwera)
game:BindToClose(function()
	-- Jeśli jesteśmy w Studio, nie czekaj (opcjonalne, ale przyspiesza testy)
	if RunService:IsStudio() then task.wait(1) end
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			saveData(player)
		end)
	end
	
	-- Daj serwerowi chwilę na zakończenie asynchronicznych pcalli
	task.wait(2)
end)

-- 5. Obsługa BuyHintEvent (Przeniesione z CoinService)
local buyHintEvent = BrainrotEvents:FindFirstChild("BuyHintEvent") or Instance.new("RemoteFunction", BrainrotEvents)
buyHintEvent.Name = "BuyHintEvent"
local premiumPurchaseCelebrationEvent = BrainrotEvents:FindFirstChild("PremiumPurchaseCelebration") or Instance.new("RemoteEvent", BrainrotEvents)
premiumPurchaseCelebrationEvent.Name = "PremiumPurchaseCelebration"

buyHintEvent.OnServerInvoke = function(player, rarityName)
	local coins = player.leaderstats.Coins
	local hintsFolder = player:FindFirstChild("BoughtHints")
	
	-- Jeśli już ma tę podpowiedź, nie musi kupować (zabezpieczenie)
	if hintsFolder and hintsFolder:FindFirstChild(rarityName) then
		return true 
	end

	local rarityData = GameConfig.Rarities[rarityName]
	local price = rarityData and rarityData.Price or 999999

	if coins.Value >= price then
		coins.Value = coins.Value - price
		
		-- Zapisujemy podpowiedź w folderze
		if hintsFolder then
			local marker = Instance.new("BoolValue")
			marker.Name = rarityName
			marker.Parent = hintsFolder
		end
		
		local ServerUpdateQuestProgress = BrainrotEvents:FindFirstChild("ServerUpdateQuestProgress")
		if ServerUpdateQuestProgress then
			ServerUpdateQuestProgress:Fire(player, "UseReveal", 1)
		end
		
		return true -- Zakup udany
	end

	return false -- Brak kasy
end

-- 6. Obsługa Game Passów kupionych w trakcie gry
local function addGamePassSpend(player, gamePassId)
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(gamePassId, Enum.InfoType.GamePass)
	end)

	if success and info and info.PriceInRobux then
		local AddRobuxToPoolEvent = BrainrotEvents:FindFirstChild("AddRobuxToPool")
		if AddRobuxToPoolEvent and AddRobuxToPoolEvent:IsA("BindableEvent") then
			AddRobuxToPoolEvent:Fire(player, info.PriceInRobux)
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		addGamePassSpend(player, gamePassId)
		local notificationType
		if gamePassId == GameConfig.GamePasses.VIPBundle then
			player:SetAttribute("HasVIP", true)
			player:SetAttribute("LatestUnlockedTrail", "VIP")
			player:SetAttribute("SelectedTrail", "VIP")
			notificationType = "VIP"
		elseif gamePassId == GameConfig.GamePasses.SpeedBoost then
			player:SetAttribute("HasSpeedBoost", true)
			notificationType = "SpeedBoost"
			-- Uzupełnienie statystyk bez resetu
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.WalkSpeed = 32
			end
		elseif gamePassId == GameConfig.GamePasses.JumpBoost then
			player:SetAttribute("HasJumpBoost", true)
			notificationType = "JumpBoost"
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.JumpPower = 100
			end
		end

		if notificationType then
			premiumPurchaseCelebrationEvent:FireClient(player, notificationType)
		end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if wasPurchased and productId == GameConfig.StarterPack.ProductID then
		local player = Players:GetPlayerByUserId(userId)
		if player and player:GetAttribute("HasBoughtStarterPack") ~= true then
			-- a) Zmień atrybut HasBoughtStarterPack na true
			player:SetAttribute("HasBoughtStarterPack", true)
			
			-- b) Dodaj graczowi 1000 monet
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Coins") then
				stats.Coins.Value += GameConfig.StarterPack.CoinsReward
			end
			
			-- c) Zwiększ atrybut FreeFartTrolls
			local currentFreeTrolls = player:GetAttribute("FreeFartTrolls") or 0
			player:SetAttribute("FreeFartTrolls", currentFreeTrolls + GameConfig.StarterPack.FreeFartTrolls)
			
			-- d) Otwórz skrzynkę "Secret"
			local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
			local OpenCaseEvent = BrainrotEvents:FindFirstChild("OpenSpecificCase")
			if OpenCaseEvent then
				OpenCaseEvent:Fire(player, GameConfig.StarterPack.CrateReward)
			end
			
			-- e) Zapisz dane
			saveData(player)
			print("[StarterPack] Przyznano nagrody dla gracza " .. player.Name)
		end
	end
end)

print("DataService Server Script Loaded Successfully!")
