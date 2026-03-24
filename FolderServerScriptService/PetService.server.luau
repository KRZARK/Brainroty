local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local folder = ReplicatedStorage:FindFirstChild("BrainrotEvents") or Instance.new("Folder", ReplicatedStorage)
folder.Name = "BrainrotEvents"

local TogglePetEvent = folder:FindFirstChild("TogglePetEvent") or Instance.new("RemoteFunction")
TogglePetEvent.Name = "TogglePetEvent"
TogglePetEvent.Parent = folder

local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage")

local PetRequirements = {
	["Common"] = 1, ["Rare"] = 1, ["Epic"] = 2, ["Legendary"] = 2,
	["Mythic"] = 3, ["Brainrot God"] = 3, ["Secret"] = 4, ["OG"] = 5
}

local PET_OFFSET = CFrame.new(0, -1.5, 6.5) -- niżej (przy ziemi) i dalej za plecami
local function removePet(player)
	local pet = workspace:FindFirstChild(player.Name .. "_ActivePet")
	if pet then pet:Destroy() end

	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local weld = hrp:FindFirstChild("PetWeld")
			if weld then weld:Destroy() end
		end
	end
end

local function attachPet(player, character, petName)
	local template = BrainrotStorage:FindFirstChild(petName)
	if not template then return end

	local petModel = template:Clone()
	petModel.Name = player.Name .. "_ActivePet"

	local hrp = character:WaitForChild("HumanoidRootPart")

	-- 1. Ustal PrimaryPart
	local petRoot = petModel.PrimaryPart
	if not petRoot then
		petRoot = petModel:FindFirstChildWhichIsA("BasePart", true)
		if not petRoot then return end
		petModel.PrimaryPart = petRoot
	end

	-- 2. Czyszczenie modelu (usuwamy to, co mogłoby walczyć z fizyką)
	for _, inst in ipairs(petModel:GetDescendants()) do
		if inst:IsA("Humanoid") or inst:IsA("Animator") or inst:IsA("AnimationController") or inst:IsA("Script") or inst:IsA("LocalScript") then
			inst:Destroy()
		end
		if inst:IsA("JointInstance") or inst:IsA("WeldConstraint") then
			inst:Destroy()
		end
	end

	-- 3. Spawanie modelu WEWNĄTRZ (wszystkie części do petRoot)
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") and part ~= petRoot then
			local wc = Instance.new("WeldConstraint")
			wc.Part0 = petRoot
			wc.Part1 = part
			wc.Parent = petRoot
		end
	end

	-- 4. Złote Równanie Skalowania (wymiar w studach)
	local _, size = petModel:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	local targetSize = 4.5
	
	if maxDim > 0 then
		local currentScale = petModel:GetScale()
		local finalScale = (targetSize / maxDim) * currentScale
		petModel:ScaleTo(finalScale)
	else
		petModel:ScaleTo(0.9)
	end

	-- 5. Fizyka - usuwamy Anchored, żeby Weld zadziałał!
	-- Ustawiamy Massless=true i CanCollide=false, żeby pet nie przeszkadzał graczowi
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	petModel:SetAttribute("PetName", petName)
	
	-- 6. Dodanie do workspace i GŁÓWNY WELD do gracza
	-- Ta wersja jest 100% płynna, bo korzysta z silnika fizyki (Weld)
	petModel:PivotTo(hrp.CFrame * PET_OFFSET)
	petModel.Parent = workspace

	local mainWeld = Instance.new("Weld")
	mainWeld.Name = "PetWeld"
	mainWeld.Part0 = hrp
	mainWeld.Part1 = petRoot
	mainWeld.C0 = PET_OFFSET
	mainWeld.Parent = hrp

	warn("PetService: ✅ Aktywowano Weld dla: " .. petName)
end

TogglePetEvent.OnServerInvoke = function(player, petName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")

	if not rebirths or rebirths.Value < 1 then
		return false, "Requires Rebirth 1+", nil
	end

	local collection = player:FindFirstChild("BrainrotCollection")
	if not collection or not collection:FindFirstChild(petName) then
		return false, "You don't own this Brainrot!", nil
	end

	local template = BrainrotStorage:FindFirstChild(petName)
	if not template then return false, "Model not found", nil end

	local rarity = template:GetAttribute("Rarity") or "Common"
	local reqLevel = PetRequirements[rarity] or 1

	if rebirths.Value < reqLevel then
		return false, "Requires Rebirth " .. reqLevel, reqLevel
	end

	local character = player.Character
	if not character then return false, "Character not found", nil end

	local existingPet = workspace:FindFirstChild(player.Name .. "_ActivePet")
	if existingPet and existingPet:GetAttribute("PetName") == petName then
		removePet(player)
		return true, "UNEQUIPPED", nil
	end

	removePet(player)
	attachPet(player, character, petName)
	return true, "EQUIPPED", nil
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		removePet(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removePet(player)
end)

print("PetService Server Script Loaded Successfully!")
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		removePet(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removePet(player)
end)

print("PetService Server Script Loaded Successfully!")
