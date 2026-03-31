local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService") -- Potrzebne do pętli podążania

local folder = ReplicatedStorage:FindFirstChild("BrainrotEvents") or Instance.new("Folder", ReplicatedStorage)
folder.Name = "BrainrotEvents"

local TogglePetEvent = folder:FindFirstChild("TogglePetEvent") or Instance.new("RemoteFunction")
TogglePetEvent.Name = "TogglePetEvent"
TogglePetEvent.Parent = folder

local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))

local ActivePetsFolder = workspace:FindFirstChild("ActivePets") or Instance.new("Folder")
ActivePetsFolder.Name = "ActivePets"
ActivePetsFolder.Parent = workspace

local PET_OFFSET = CFrame.new(2.5, -1.8, 7.0) -- Dalej, niżej i lekko w bok

local function removePet(player)
	local pet = ActivePetsFolder:FindFirstChild(player.Name .. "_ActivePet")
	if pet then pet:Destroy() end
end

local function attachPet(player, character, petName)
	local template = BrainrotStorage:FindFirstChild(petName)
	if not template then return end

	local petModel = template:Clone()
	petModel.Name = player.Name .. "_ActivePet"
	petModel:SetAttribute("OwnerUserId", player.UserId) -- Klucz dla klienta

	local hrp = character:WaitForChild("HumanoidRootPart")

	-- 1. Czyszczenie modelu ze zbędnych skryptów
	for _, inst in ipairs(petModel:GetDescendants()) do
		if inst:IsA("Humanoid") or inst:IsA("Animator") or inst:IsA("AnimationController") or inst:IsA("Script") or inst:IsA("LocalScript") then
			inst:Destroy()
		end
	end

	-- 2. Całkowite zamrożenie fizyki (Anchored = true)
	-- Fizykę przesunięcia przejmie klient przez RenderStepped
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.Massless = true
		end
	end

	-- 3. Złote Równanie Skalowania (Tomeryczne - bazujące na objętości)
	local _, size = petModel:GetBoundingBox()
	-- Używamy pierwiastka sześciennego z objętości, co najlepiej "uśrednia" wielkość
	-- różnych brył (długich patyków vs grubych kostek).
	local volume = size.X * size.Y * size.Z
	local sideLength = math.pow(volume, 1/3)
	local targetSize = 5.5 -- Docelowa "masa" wizualna

	if sideLength > 0.1 then
		local currentScale = petModel:GetScale()
		local finalScale = (targetSize / sideLength) * currentScale
		petModel:ScaleTo(finalScale)
	else
		petModel:ScaleTo(1.2)
	end

	petModel:SetAttribute("PetName", petName)

	-- Ustawiamy Peta początkowo za graczem i oddajemy mu kontrolę (wizualną)
	petModel:PivotTo(hrp.CFrame * PET_OFFSET)
	petModel.Parent = ActivePetsFolder

	warn("PetService: ✅ Aktywowano Peta (Tryb Klient) dla: " .. player.Name)
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
	local reqLevel = GameConfig.Rarities[rarity] and GameConfig.Rarities[rarity].PetReqRebirth or 1

	if rebirths.Value < reqLevel then
		return false, "Requires Rebirth " .. reqLevel, reqLevel
	end

	local character = player.Character
	if not character then return false, "Character not found", nil end

	local existingPet = ActivePetsFolder:FindFirstChild(player.Name .. "_ActivePet")
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