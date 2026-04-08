local GameConfig = {}

-- Ceny i Wymagania (Rzadkości)
GameConfig.Rarities = {
	["Common"] = { Price = 50, PetReqRebirth = 1, Color = Color3.fromRGB(163, 162, 165), Order = 1 },
	["Rare"] = { Price = 150, PetReqRebirth = 1, Color = Color3.fromRGB(64, 255, 71), Order = 2 },
	["Epic"] = { Price = 400, PetReqRebirth = 2, Color = Color3.fromRGB(180, 71, 255), Order = 3 },
	["Legendary"] = { Price = 800, PetReqRebirth = 2, Color = Color3.fromRGB(255, 145, 0), Order = 4 },
	["Mythic"] = { Price = 1500, PetReqRebirth = 3, Color = Color3.fromRGB(255, 33, 33), Order = 5 },
	["Brainrot God"] = { Price = 5000, PetReqRebirth = 3, Color = Color3.fromRGB(0, 255, 255), Order = 6 },
	["Secret"] = { Price = 10000, PetReqRebirth = 4, Color = Color3.fromRGB(150, 150, 150), Order = 7 },
	["OG"] = { Price = 99999, PetReqRebirth = 5, Color = Color3.fromRGB(0, 255, 255), Order = 8 }
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
GameConfig.MaxCollectDistance = 15
GameConfig.CoinRainTriggerAmount = 1000
GameConfig.CoinRainDuration = 115

GameConfig.TotalBrainrots = 143

GameConfig.QuestSystem = {
	DailyCount = 3, -- Ile zadań gracz dostaje dziennie
	Pool = {
		{ID = "CollectBrainrots", Desc = "Znajdz %d Brainrotow", Req = 30, Reward = 250},
		{ID = "CollectCoins", Desc = "Zbierz %d fizycznych monet", Req = 15, Reward = 300},
		{ID = "PlayTime", Desc = "Graj przez %d minut", Req = 20, Reward = 200},
		{ID = "Jump", Desc = "Podskocz %d razy", Req = 250, Reward = 150},
		{ID = "Walk", Desc = "Przebiegnij %d studow", Req = 3000, Reward = 150},
		{ID = "UseReveal", Desc = "Uzyj podpowiedzi %d razy", Req = 2, Reward = 200},
		{ID = "Fall", Desc = "Spadnij lacznie %d studow", Req = 500, Reward = 200},
		{ID = "Swim", Desc = "Plyn lacznie przez %d sekund", Req = 120, Reward = 150},
		{ID = "Socialize", Desc = "Badz blisko innych graczy przez %d sekund", Req = 180, Reward = 200}
	}
}
GameConfig.PlaytimeRewards = {
	{ TimeMinutes = 5, Reward = 100 },
	{ TimeMinutes = 15, Reward = 250 },
	{ TimeMinutes = 30, Reward = 500 },
	{ TimeMinutes = 60, Reward = 1000 },
	{ TimeMinutes = 90, Reward = 2000 }
}

GameConfig.DailyRewards = {
	[1] = { Type = "Coin", Value = 50, Icon = "Coin2D" },
	[2] = { Type = "Coin", Value = 250, Icon = "Coin2D" },
	[3] = { Type = "Speed", Value = 2, Icon = "speed" }, -- Speed Boost x2 (30 min)
	[4] = { Type = "Coin", Value = 500, Icon = "Coin2D" },
	[5] = { Type = "Jump", Value = 2, Icon = "Jump" }, -- Jump Boost x2 (30 min)
	[6] = { Type = "Coin", Value = 1000, Icon = "Coin2D" },
	[7] = { Type = "Coin", Value = 2000, Icon = "Coin2D" }
}

-- PREMIUM SHOP CONFIGURATION
GameConfig.GamePasses = {
	VIPBundle = 1780076745, -- ULTIMATE VIP BUNDLE
	SpeedBoost = 1778738985,
	JumpBoost = 1779440817
}

GameConfig.CoinPacks = {
	Pack100 = { ID = 3568785592, Amount = 100, Price = 19 },
	Pack250 = { ID = 3568785721, Amount = 250, Price = 45 },
	Pack500 = { ID = 3568785904, Amount = 500, Price = 79 },
	Pack1000 = { ID = 3568786016, Amount = 1000, Price = 149 }
}

-- STARTER PACK
GameConfig.StarterPack = {
	ProductID = 3571796279,
	Price = 99,
	CoinsReward = 1000,
	FreeFartTrolls = 3,
	CrateReward = "Secret"
}

return GameConfig
