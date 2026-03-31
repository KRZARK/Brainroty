local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")

-- Utworzenie RemoteFunction do odbierania nagród
local claimEvent = BrainrotEvents:FindFirstChild("ClaimPlaytimeReward")
if not claimEvent then
	claimEvent = Instance.new("RemoteFunction")
	claimEvent.Name = "ClaimPlaytimeReward"
	claimEvent.Parent = BrainrotEvents
end

-- Utworzenie RemoteFunction do pobierania czasu startu i stanu
local getTimeEvent = BrainrotEvents:FindFirstChild("GetPlaytimeData")
if not getTimeEvent then
	getTimeEvent = Instance.new("RemoteFunction")
	getTimeEvent.Name = "GetPlaytimeData"
	getTimeEvent.Parent = BrainrotEvents
end

-- Słowniki danych sesyjnych
local SessionStartTimes = {}
local ClaimedRewards = {}

Players.PlayerAdded:Connect(function(player)
	SessionStartTimes[player.UserId] = os.time()
	ClaimedRewards[player.UserId] = {}
end)

Players.PlayerRemoving:Connect(function(player)
	SessionStartTimes[player.UserId] = nil
	ClaimedRewards[player.UserId] = nil
end)

-- Inicjalizacja dla graczy już obecnych podczas ładowania skryptu (np. w Studio)
for _, player in ipairs(Players:GetPlayers()) do
	if not SessionStartTimes[player.UserId] then
		SessionStartTimes[player.UserId] = os.time()
		ClaimedRewards[player.UserId] = {}
	end
end

-- Dodatkowa funkcja do klienta, aby zsynchronizować StartTime i State
getTimeEvent.OnServerInvoke = function(player)
	local startTime = SessionStartTimes[player.UserId] or os.time()
	local claimed = ClaimedRewards[player.UserId] or {}
	return startTime, claimed
end

claimEvent.OnServerInvoke = function(player, rewardIndex)
	local startTime = SessionStartTimes[player.UserId]
	local claimed = ClaimedRewards[player.UserId]
	
	if not startTime or not claimed then
		return false, "Błąd sesji."
	end
	
	local rewardData = GameConfig.PlaytimeRewards[rewardIndex]
	if not rewardData then
		return false, "Niepoprawny indeks nagrody."
	end
	
	if claimed[rewardIndex] then
		return false, "Ta nagroda została już odebrana."
	end
	
	local elapsedSeconds = os.time() - startTime
	local requiredSeconds = rewardData.TimeMinutes * 60
	
	if elapsedSeconds < requiredSeconds then
		return false, "Nie upłynęło wystarczająco dużo czasu."
	end
	
	-- Obliczanie nagrody
	local baseReward = rewardData.Reward
	
	-- 1. Mnożnik za Rebirth
	local multiplier = 1
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirthsVal = leaderstats and leaderstats:FindFirstChild("Rebirths")
	if rebirthsVal then
		local rb = rebirthsVal.Value
		if rb == 1 then multiplier = 1.25
		elseif rb == 2 then multiplier = 1.5
		elseif rb >= 3 then multiplier = 2.0
		end
	end
	
	-- 2. Bonus za Znajomego (+20%)
	local hasFriendBonus = false
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.UserId ~= player.UserId then
			local success, isFriend = pcall(function()
				return player:IsFriendsWith(otherPlayer.UserId)
			end)
			if success and isFriend then
				hasFriendBonus = true
				break
			end
		end
	end
	
	if hasFriendBonus then
		multiplier = multiplier * 1.2
	end
	
	local finalReward = math.floor(baseReward * multiplier)
	
	-- Przyznanie nagrody
	local coinsVal = leaderstats and leaderstats:FindFirstChild("Coins")
	if coinsVal then
		coinsVal.Value = coinsVal.Value + finalReward
		claimed[rewardIndex] = true -- Oznacz jako odebrane
		
		-- Odtworzenie dźwięku systemowego (Kaching) - opcjonalnie zrobimy to po stronie klienta
		return true, finalReward, hasFriendBonus
	else
		return false, "Brak statystyki Coins."
	end
end

print("PlaytimeRewardService Server Script Loaded Successfully!")
