local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local CoinGrantHelper = require(script.Parent:WaitForChild("CoinGrantHelper"))
local requestImmediateDataSaveEvent = BrainrotEvents:WaitForChild("RequestImmediateDataSave")
local playtimeHeartbeatInterval = GameConfig.PlaytimeReconnectHeartbeatSeconds or 10
local playtimeReconnectGraceSeconds = GameConfig.PlaytimeReconnectGraceSeconds or 60
local isStudio = RunService:IsStudio()

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

local playtimeResumeStore = nil
do
	local success, result = pcall(function()
		return MemoryStoreService:GetHashMap("PlaytimeReconnectResume_V2")
	end)

	if success then
		playtimeResumeStore = result
	else
		warn("[PlaytimeRewardService] MemoryStore niedostepny, playtime reconnect resume bedzie pominiety: " .. tostring(result))
	end
end

-- Słowniki danych sesyjnych
local SessionStartTimes = {}
local ClaimedRewards = {}
local heartbeatLoopActiveByUserId = {}
local sessionInitializationInProgressByUserId = {}
local sessionInitializedByUserId = {}

local function clearClaimedRewards(claimed)
	if type(claimed) ~= "table" then
		return {}
	end

	for rewardIndex = 1, #GameConfig.PlaytimeRewards do
		claimed[rewardIndex] = nil
	end

	return claimed
end

local function hasClaimedAllRewards(claimed)
	if type(claimed) ~= "table" then
		return false
	end

	for rewardIndex = 1, #GameConfig.PlaytimeRewards do
		if not claimed[rewardIndex] then
			return false
		end
	end

	return #GameConfig.PlaytimeRewards > 0
end

local function serializeClaimedRewards(claimed)
	local claimedIndices = {}

	for rewardIndex = 1, #GameConfig.PlaytimeRewards do
		if claimed[rewardIndex] then
			table.insert(claimedIndices, rewardIndex)
		end
	end

	return claimedIndices
end

local function deserializeClaimedRewards(claimedIndices)
	local claimed = {}

	if type(claimedIndices) ~= "table" then
		return claimed
	end

	for _, rewardIndex in ipairs(claimedIndices) do
		local numericIndex = tonumber(rewardIndex)
		if numericIndex then
			claimed[numericIndex] = true
		end
	end

	return claimed
end

local function saveReconnectSnapshot(player)
	if not playtimeResumeStore then
		return false
	end

	local startTime = SessionStartTimes[player.UserId]
	local claimed = ClaimedRewards[player.UserId]
	if not startTime or not claimed then
		return false
	end

	local success, err = pcall(function()
		playtimeResumeStore:SetAsync(tostring(player.UserId), {
			startTime = startTime,
			claimedRewards = serializeClaimedRewards(claimed),
			savedAt = os.time(),
		}, playtimeReconnectGraceSeconds)
	end)

	if not success then
		warn("[PlaytimeRewardService] Nie udalo sie zapisac snapshotu reconnect dla " .. player.Name .. ": " .. tostring(err) .. (isStudio and " | Sprawdz: published place + Enable Studio Access to API Services." or ""))
	elseif isStudio then
		print("[PlaytimeRewardService][Studio] Saved reconnect snapshot for " .. player.Name .. " startTime=" .. tostring(startTime))
	end

	return success
end

local function loadReconnectSnapshot(player)
	if not playtimeResumeStore then
		return nil
	end

	local success, snapshot = pcall(function()
		return playtimeResumeStore:GetAsync(tostring(player.UserId))
	end)

	if not success then
		warn("[PlaytimeRewardService] Nie udalo sie odczytac snapshotu reconnect dla " .. player.Name .. ": " .. tostring(snapshot) .. (isStudio and " | Sprawdz: published place + Enable Studio Access to API Services." or ""))
		return nil
	end

	if type(snapshot) ~= "table" or type(snapshot.startTime) ~= "number" then
		if isStudio then
			print("[PlaytimeRewardService][Studio] No reconnect snapshot found for " .. player.Name)
		end
		return nil
	end

	pcall(function()
		playtimeResumeStore:RemoveAsync(tostring(player.UserId))
	end)

	if isStudio then
		print("[PlaytimeRewardService][Studio] Loaded reconnect snapshot for " .. player.Name .. " startTime=" .. tostring(snapshot.startTime))
	end

	return snapshot
end

local function initializePlayerSession(player)
	local snapshot = loadReconnectSnapshot(player)

	if snapshot then
		SessionStartTimes[player.UserId] = snapshot.startTime
		ClaimedRewards[player.UserId] = deserializeClaimedRewards(snapshot.claimedRewards)
	else
		SessionStartTimes[player.UserId] = os.time()
		ClaimedRewards[player.UserId] = {}
	end

	if hasClaimedAllRewards(ClaimedRewards[player.UserId]) then
		SessionStartTimes[player.UserId] = os.time()
		ClaimedRewards[player.UserId] = clearClaimedRewards(ClaimedRewards[player.UserId])
	end

	saveReconnectSnapshot(player)
end

local function resetRewardCycle(player)
	local userId = player.UserId
	local claimed = ClaimedRewards[userId] or {}

	ClaimedRewards[userId] = clearClaimedRewards(claimed)
	SessionStartTimes[userId] = os.time()
	saveReconnectSnapshot(player)

	return SessionStartTimes[userId]
end

local function ensurePlayerSessionInitialized(player)
	if sessionInitializedByUserId[player.UserId] then
		return
	end

	while sessionInitializationInProgressByUserId[player.UserId] do
		task.wait()
		if sessionInitializedByUserId[player.UserId] then
			return
		end
	end

	sessionInitializationInProgressByUserId[player.UserId] = true
	initializePlayerSession(player)
	sessionInitializationInProgressByUserId[player.UserId] = nil
	sessionInitializedByUserId[player.UserId] = true
end

local function startHeartbeatLoop(player)
	if heartbeatLoopActiveByUserId[player.UserId] then
		return
	end

	heartbeatLoopActiveByUserId[player.UserId] = true
	task.spawn(function()
		while heartbeatLoopActiveByUserId[player.UserId] and player.Parent == Players do
			task.wait(playtimeHeartbeatInterval)
			if not heartbeatLoopActiveByUserId[player.UserId] or player.Parent ~= Players then
				break
			end
			saveReconnectSnapshot(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	ensurePlayerSessionInitialized(player)
	startHeartbeatLoop(player)
end)

Players.PlayerRemoving:Connect(function(player)
	heartbeatLoopActiveByUserId[player.UserId] = nil
	sessionInitializationInProgressByUserId[player.UserId] = nil
	sessionInitializedByUserId[player.UserId] = nil
	saveReconnectSnapshot(player)
	SessionStartTimes[player.UserId] = nil
	ClaimedRewards[player.UserId] = nil
end)

-- Inicjalizacja dla graczy już obecnych podczas ładowania skryptu (np. w Studio)
for _, player in ipairs(Players:GetPlayers()) do
	if not SessionStartTimes[player.UserId] then
		ensurePlayerSessionInitialized(player)
		startHeartbeatLoop(player)
	end
end

-- Dodatkowa funkcja do klienta, aby zsynchronizować StartTime i State
getTimeEvent.OnServerInvoke = function(player)
	ensurePlayerSessionInitialized(player)
	if hasClaimedAllRewards(ClaimedRewards[player.UserId]) then
		resetRewardCycle(player)
	end
	local startTime = SessionStartTimes[player.UserId] or os.time()
	local claimed = ClaimedRewards[player.UserId] or {}
	return startTime, claimed
end

claimEvent.OnServerInvoke = function(player, rewardIndex)
	ensurePlayerSessionInitialized(player)
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
	
	-- 1. Mnożnik za Rebirth i inne (Pobierany z atrybutu)
	local multiplier = player:GetAttribute("CoinEarningsMultiplier") or player:GetAttribute("CoinMultiplier") or 1
	
	-- 2. Bonus za Znajomego (+20%)
	-- CoinMultiplier already includes VIP and Rebirth bonuses.

	local finalReward = math.floor(baseReward * multiplier)
	
	-- Przyznanie nagrody
	local grantSucceeded, grantedCoins = CoinGrantHelper.grantCoins(player, finalReward, "PlaytimeReward:" .. tostring(rewardIndex))
	if grantSucceeded then
		claimed[rewardIndex] = true -- Oznacz jako odebrane
		local restart = hasClaimedAllRewards(claimed)
		local nextCycleStartTime = nil

		if restart then
			nextCycleStartTime = resetRewardCycle(player)
		else
			saveReconnectSnapshot(player)
		end

		requestImmediateDataSaveEvent:Fire(player)
		
		-- Odtworzenie dźwięku systemowego (Kaching) - opcjonalnie zrobimy to po stronie klienta
		return true, grantedCoins, restart, nextCycleStartTime
	else
		return false, "Brak statystyki Coins."
	end
end

print("PlaytimeRewardService Server Script Loaded Successfully!")
