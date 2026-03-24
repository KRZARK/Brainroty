local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tworzymy folder na eventy, jeśli nie istnieje
local folder = ReplicatedStorage:FindFirstChild("BrainrotEvents") or Instance.new("Folder", ReplicatedStorage)
folder.Name = "BrainrotEvents"

local buyHintEvent = Instance.new("RemoteFunction") -- Używamy Function, żeby dać znać graczowi czy zakup się udał
buyHintEvent.Name = "BuyHintEvent"
buyHintEvent.Parent = folder

-- KONFIGURACJA CEN (Serwer musi je znać, żeby nikt go nie oszukał)
local RarityPrices = {
	["Common"] = 50, ["Rare"] = 150, ["Epic"] = 400, ["Legendary"] = 800,
	["Mythic"] = 1500, ["Brainrot God"] = 5000, ["Secret"] = 10000, ["OG"] = 99999
}

-- FUNKCJA: Dodawanie waluty do Leaderstats
Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0 -- Tu możesz w przyszłości podpiąć DataStore
	coins.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	-- NAGRODA ZA CZAS: 10 monet co 60 sekund
	task.spawn(function()
		while player and player.Parent do
			task.wait(60)
			
			local multiplier = 1
			if rebirths.Value == 1 then
				multiplier = 1.25
			elseif rebirths.Value == 2 then
				multiplier = 1.5
			elseif rebirths.Value >= 3 then
				multiplier = 2
			end
			
			local amountToAdd = math.floor(10 * multiplier)
			coins.Value = coins.Value + amountToAdd
		end
	end)
end)

-- OBSŁUGA ZAKUPU
buyHintEvent.OnServerInvoke = function(player, rarityName)
	local coins = player.leaderstats.Coins
	local price = RarityPrices[rarityName] or 999999

	if coins.Value >= price then
		coins.Value = coins.Value - price
		return true -- Zakup udany
	end

	return false -- Brak kasy
end