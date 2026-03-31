local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotUtils = {}

-- Chowanie zmiennej do lazy-loadingu, jeśli BrainrotStorage tworzy się później
local cachedStorage = nil
local function getStorage()
	if not cachedStorage then
		cachedStorage = ReplicatedStorage:WaitForChild("BrainrotStorage", 10)
	end
	return cachedStorage
end

--[[
	Funkcja sprawdzająca, czy dany gracz ma 100% zebranych modeli o podanej rzadkości.
	Przydatne m.in. do Odblokowywania stref, Ochrony przed Trollami.
]]
function BrainrotUtils.hasCompletedRarity(player, rarityName)
	if not player then return false end
	
	local storage = getStorage()
	if not storage then 
		warn("[BrainrotUtils] Nie znaleziono ReplicatedStorage.BrainrotStorage!")
		return false 
	end
	
	local collectionFolder = player:FindFirstChild("BrainrotCollection")
	if not collectionFolder then 
		return false 
	end

	local totalRequired = 0
	local totalCollected = 0

	for _, item in ipairs(storage:GetChildren()) do
		local itemRarity = item:GetAttribute("Rarity")
		
		if itemRarity == rarityName then
			totalRequired = totalRequired + 1
			
			-- Sprawdzamy czy w folderze gracza istnieje znacznik BoolValue z tą samą nazwą
			if collectionFolder:FindFirstChild(item.Name) then
				totalCollected = totalCollected + 1
			end
		end
	end

	-- Jeśli w ogóle nie ma takich obiektów w grze (albo błąd literówki), zwracamy fałsz dla bezpieczeństwa
	if totalRequired == 0 then
		return false
	end

	-- Zwraca true jeśli gracz posiada WSZYSTKIE wymagane elementy
	return totalCollected >= totalRequired
end

return BrainrotUtils
