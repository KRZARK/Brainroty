local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")

local UpdateQuestProgress = BrainrotEvents:FindFirstChild("UpdateQuestProgress") or Instance.new("RemoteEvent")
UpdateQuestProgress.Name = "UpdateQuestProgress"
UpdateQuestProgress.Parent = BrainrotEvents

local ServerUpdateQuestProgress = BrainrotEvents:FindFirstChild("ServerUpdateQuestProgress") or Instance.new("BindableEvent")
ServerUpdateQuestProgress.Name = "ServerUpdateQuestProgress"
ServerUpdateQuestProgress.Parent = BrainrotEvents

local ClaimQuestReward = BrainrotEvents:FindFirstChild("ClaimQuestReward") or Instance.new("RemoteEvent")
ClaimQuestReward.Name = "ClaimQuestReward"
ClaimQuestReward.Parent = BrainrotEvents

local function addQuestProgress(player, questID, amount)
	if type(amount) ~= "number" or amount <= 0 or amount > 5000 then return end
	
	local questsFolder = player:FindFirstChild("DailyQuestsFolder")
	if not questsFolder then return end
	
	local questVal = questsFolder:FindFirstChild(questID)
	if questVal and not questVal:GetAttribute("Claimed") then
		local req = 99999
		for _, q in ipairs(GameConfig.QuestSystem.Pool) do
			if q.ID == questID then req = q.Req break end
		end
		
		if questVal.Value < req then
			questVal.Value = math.min(questVal.Value + amount, req)
		end
	end
end

-- Zabezpieczone dodawanie postępu z klienta
UpdateQuestProgress.OnServerEvent:Connect(function(player, questID, amount)
	addQuestProgress(player, questID, amount)
end)

-- Wewnętrzne dodawanie postępu przez serwer
ServerUpdateQuestProgress.Event:Connect(function(player, questID, amount)
	addQuestProgress(player, questID, amount)
end)

-- Odbieranie nagrody
ClaimQuestReward.OnServerEvent:Connect(function(player, questID)
	local questsFolder = player:FindFirstChild("DailyQuestsFolder")
	local stats = player:FindFirstChild("leaderstats")
	if not questsFolder or not stats then return end
	
	local questVal = questsFolder:FindFirstChild(questID)
	if questVal and not questVal:GetAttribute("Claimed") then
		
		local req, reward = 99999, 0
		for _, q in ipairs(GameConfig.QuestSystem.Pool) do
			if q.ID == questID then 
				req = q.Req 
				reward = q.Reward 
				break 
			end
		end
		
		if questVal.Value >= req then
			questVal:SetAttribute("Claimed", true)
			stats.Coins.Value += reward
		end
	end
end)
