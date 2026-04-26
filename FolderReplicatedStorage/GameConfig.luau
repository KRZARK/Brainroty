local GameConfig = {}

-- Ceny i Wymagania (Rzadkości)
GameConfig.Rarities = {
	["Common"] = { Price = 25, PetReqRebirth = 0, Color = Color3.fromRGB(163, 162, 165), Order = 1 },
	["Rare"] = { Price = 50, PetReqRebirth = 1, Color = Color3.fromRGB(64, 255, 71), Order = 2 },
	["Epic"] = { Price = 150, PetReqRebirth = 2, Color = Color3.fromRGB(180, 71, 255), Order = 3 },
	["Legendary"] = { Price = 300, PetReqRebirth = 2, Color = Color3.fromRGB(255, 145, 0), Order = 4 },
	["Mythic"] = { Price = 600, PetReqRebirth = 3, Color = Color3.fromRGB(255, 33, 33), Order = 5 },
	["Brainrot God"] = { Price = 1200, PetReqRebirth = 3, Color = Color3.fromRGB(0, 255, 255), Order = 6 },
	["Secret"] = { Price = 2500, PetReqRebirth = 4, Color = Color3.fromRGB(150, 150, 150), Order = 7 },
	["OG"] = { Price = 10000, PetReqRebirth = 5, Color = Color3.fromRGB(0, 255, 255), Order = 8 }
}

-- Produkty: Skrzynki (POPRAWIONE ID z oryginalnych skryptów)
GameConfig.CaseProducts = {
	["Common"] = 3558948736,
	["Rare"] = 3558948814,
	["Epic"] = 3558949097,
	["Legendary"] = 3558949533, -- Poprawione z 3558949533
	["Mythic"] = 3558950075, -- Poprawione z 3558950075
	["Brainrot God"] = 3558950464, -- Poprawione z 3558950464
	["Secret"] = 3558950670, -- Poprawione z 3558950670
	["OG"] = 3558951376 -- Poprawione z 3558951376
}

-- Produkty: Trolle
GameConfig.TrollProducts = {
	Bomb = 3562965666,
	Lava = 3562965753,
	Tornado = 3562965850,
	Fart = 3562965942
}

-- Globalne Ustawienia
GameConfig.ClientCollectDistance = 6
GameConfig.MaxCollectDistance = 10
GameConfig.CollectRequestRateWindow = 0.35
GameConfig.MaxCollectRequestsPerWindow = 4
GameConfig.CoinRainTriggerAmount = 1000
GameConfig.CoinRainDuration = 115
GameConfig.CoinRainCoinReward = 5

GameConfig.TotalBrainrots = 143

GameConfig.QuestSystem = {
	DailyCount = 3, -- Ile zadań gracz dostaje dziennie
	SelectionVersion = 3,
	Pool = {
		{ID = "CollectBrainrots", Desc = "Znajdz %d Brainrotow", Req = 30, Reward = 1000, Category = "Active"},
		{ID = "PlayTime", Desc = "Graj przez %d minut", Req = 40, Reward = 1000, Category = "Passive"},
		{ID = "Jump", Desc = "Podskocz %d razy", Req = 500, Reward = 1000, Category = "Active"},
		{ID = "Climb", Desc = "Wespnij sie lub wskocz lacznie na %d studow", Req = 2000, Reward = 1000, Category = "Active"},
		{ID = "Walk", Desc = "Przebiegnij %d studow", Req = 6000, Reward = 1000, Category = "Passive"},
		{ID = "UseReveal", Desc = "Uzyj podpowiedzi %d razy", Req = 2, Reward = 1000, Category = "Situational"},
		{ID = "Fall", Desc = "Spadnij lacznie %d studow", Req = 1000, Reward = 1000, Category = "Passive"},
		{ID = "Swim", Desc = "Plyn lacznie przez %d sekund", Req = 120, Reward = 1000, Category = "Situational"},
		{ID = "Socialize", Desc = "Badz blisko innych graczy przez %d sekund", Req = 180, Reward = 1000, Category = "Situational"}
	}
}
GameConfig.PlaytimeRewards = {
	{ TimeMinutes = 5, Reward = 250 },
	{ TimeMinutes = 15, Reward = 500 },
	{ TimeMinutes = 30, Reward = 1000 },
	{ TimeMinutes = 60, Reward = 2250 },
	{ TimeMinutes = 90, Reward = 4000 }
}
GameConfig.PlaytimeReconnectHeartbeatSeconds = 10
GameConfig.PlaytimeReconnectGraceSeconds = 60

GameConfig.DailyRewards = {
	[1] = { Type = "Coin", Value = 1000, Icon = "Coin2D" },
	[2] = { Type = "Coin", Value = 2000, Icon = "Coin2D" },
	[3] = { Type = "Speed", Value = 2, Icon = "speed" }, -- Speed Boost x2 (30 min)
	[4] = { Type = "Coin", Value = 3500, Icon = "Coin2D" },
	[5] = { Type = "Jump", Value = 2, Icon = "Jump" }, -- Jump Boost x2 (30 min)
	[6] = { Type = "Coin", Value = 6000, Icon = "Coin2D" },
	[7] = { Type = "PurpleTrail", Value = 1, Icon = "Aura" }
}

-- PREMIUM SHOP CONFIGURATION
GameConfig.GamePasses = {
	VIPBundle = 1780076745, -- ULTIMATE VIP BUNDLE
	SpeedBoost = 1778738985,
	JumpBoost = 1779440817
}

GameConfig.CoinPacks = {
	Pack100 = { ID = 3568785592, Amount = 1000, Price = 19 },
	Pack250 = { ID = 3568785721, Amount = 2500, Price = 45 },
	Pack500 = { ID = 3568785904, Amount = 10000, Price = 79 },
	Pack1000 = { ID = 3568786016, Amount = 25000, Price = 149 }
}

-- STARTER PACK
GameConfig.StarterPack = {
	ProductID = 3571796279,
	Price = 99,
	CoinsReward = 1000,
	FreeFartTrolls = 3,
	CrateReward = "Secret"
}

function GameConfig.GetPetRequirementForRarity(rarityName)
	local rarityConfig = rarityName and GameConfig.Rarities[rarityName]
	if rarityConfig and rarityConfig.PetReqRebirth ~= nil then
		return rarityConfig.PetReqRebirth
	end

	return 0
end

function GameConfig.GetPetUnlocksForRebirthLevel(rebirthLevel)
	local unlocks = {}
	local targetLevel = tonumber(rebirthLevel) or 0

	for rarityName, rarityConfig in pairs(GameConfig.Rarities) do
		if GameConfig.GetPetRequirementForRarity(rarityName) == targetLevel then
			table.insert(unlocks, {
				Name = rarityName,
				Order = rarityConfig.Order or math.huge,
			})
		end
	end

	table.sort(unlocks, function(a, b)
		return a.Order < b.Order
	end)

	local names = {}
	for _, unlockData in ipairs(unlocks) do
		table.insert(names, unlockData.Name)
	end

	return names
end

function GameConfig.GetPetUnlocksLabelForRebirthLevel(rebirthLevel)
	local unlocks = GameConfig.GetPetUnlocksForRebirthLevel(rebirthLevel)
	return #unlocks > 0 and table.concat(unlocks, ", ") or "Brak"
end

return GameConfig
