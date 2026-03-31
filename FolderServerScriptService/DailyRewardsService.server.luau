local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")

local ClaimDailyRewardRF = Instance.new("RemoteFunction")
ClaimDailyRewardRF.Name = "ClaimDailyReward"
ClaimDailyRewardRF.Parent = BrainrotEvents

ClaimDailyRewardRF.OnServerInvoke = function(player)
	local lastClaim = player:GetAttribute("LastClaimedDate") or ""
	local todayStr = os.date("%Y%m%d")
	
	if lastClaim == todayStr then
		return false, "Odebrano już nagrodę na dziś!"
	end
	
	local streak = player:GetAttribute("LoginStreak") or 1
	if streak > 7 then streak = 1 end
	
	local reward = GameConfig.DailyRewards[streak]
	if not reward then return false, "Wystąpił błąd w konfiguracji." end
	
	-- Przyznajemy Nagrodę
	if reward.Type == "Coin" then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Coins") then
			leaderstats.Coins.Value += reward.Value
		end
	elseif reward.Type == "Speed" then
		player:SetAttribute("SpeedBoostEnds", os.time() + 1800) -- 30 min z zabezpieczeniem przed śmiercią
	elseif reward.Type == "Jump" then
		player:SetAttribute("JumpBoostEnds", os.time() + 1800) -- 30 min z zabezpieczeniem przed śmiercią
	end
	
	-- Zapisujemy postęp
	player:SetAttribute("LastClaimedDate", todayStr)
	
	local nextStreak = streak + 1
	if nextStreak > 7 then nextStreak = 1 end
	player:SetAttribute("LoginStreak", nextStreak)
	
	return true, streak, reward
end

-- Petla nakładająca boosty nawet po śmierci (co 1 sekunde sprawdza atrybuty czasowe gracza)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid", 10)
		if not humanoid then return end
		
		task.spawn(function()
			while char and char.Parent and humanoid.Health > 0 do
				local speedEnd = player:GetAttribute("SpeedBoostEnds") or 0
				local jumpEnd = player:GetAttribute("JumpBoostEnds") or 0
				
				local speedMult = (os.time() < speedEnd) and 2 or 1
				local jumpMult = (os.time() < jumpEnd) and 2 or 1
				
				-- Wymuszamy domyślne statystyki x Mult(2)
				humanoid.WalkSpeed = 32 * speedMult 
				humanoid.UseJumpPower = true
				humanoid.JumpPower = 100 * jumpMult
				
				task.wait(1)
			end
		end)
	end)
end)
