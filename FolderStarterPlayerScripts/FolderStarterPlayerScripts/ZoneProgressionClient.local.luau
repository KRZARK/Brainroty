local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local BrainrotUtils = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("BrainrotUtils"))

-- GUI dla błędu portalu
local playerGui = player:WaitForChild("PlayerGui")
local warningGui = Instance.new("ScreenGui")
warningGui.Name = "OGPortalWarning"
warningGui.DisplayOrder = 100
warningGui.ResetOnSpawn = false -- KLUCZOWE: GUI nie usuwa się po śmierci!
warningGui.Parent = playerGui

local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.fromScale(0.8, 0.2)
warningLabel.Position = UDim2.fromScale(0.5, 0.3)
warningLabel.AnchorPoint = Vector2.new(0.5, 0.5)
warningLabel.BackgroundTransparency = 1
warningLabel.Text = "YOU MUST COLLECT ALL SECRET BRAINROTS TO SEARCH FOR OG!"
warningLabel.TextColor3 = Color3.fromRGB(255, 30, 30)
warningLabel.Font = Enum.Font.FredokaOne
warningLabel.TextScaled = true
warningLabel.Visible = false
warningLabel.ZIndex = 100
warningLabel.Parent = warningGui

local warningStroke = Instance.new("UIStroke")
warningStroke.Thickness = 4
warningStroke.Color = Color3.new(0, 0, 0)
warningStroke.Parent = warningLabel

local uiConstraint = Instance.new("UITextSizeConstraint")
uiConstraint.MaxTextSize = 60
uiConstraint.MinTextSize = 20
uiConstraint.Parent = warningLabel

local debounce = false

-- Pętla zarządzająca barierami (ZoneDoors)
task.spawn(function()
	while true do
		local doorsFolder = Workspace:FindFirstChild("ZoneDoors")
		if doorsFolder then
			-- Używamy GetDescendants, żeby działało to ze zgrupowanymi modelami
			for _, door in ipairs(doorsFolder:GetDescendants()) do
				if door:IsA("BasePart") then
					-- Sprawdzamy atrybut na samej części, a jeśli go nie ma to na jej rodzicu (Modelu)
					local requiredRarity = door:GetAttribute("RequiresRarity")
					if not requiredRarity and door.Parent then
						requiredRarity = door.Parent:GetAttribute("RequiresRarity")
					end
					
					if requiredRarity then
						local hasCompleted = BrainrotUtils.hasCompletedRarity(player, requiredRarity)
						
						if hasCompleted then
							-- Otwarty dostęp
							if door.CanCollide ~= false then
								door.CanCollide = false
								door.Transparency = 0.6
								door.Material = Enum.Material.ForceField
								door.BrickColor = BrickColor.new("Lime green")
							end
						else
							-- Brak dostępu
							if door.CanCollide ~= true then
								door.CanCollide = true
								door.Transparency = 0
								door.Material = Enum.Material.Neon
								door.BrickColor = BrickColor.new("Really red")
							end
						end
					end
				end
			end
		end
		
		task.wait(1)
	end
end)

-- Nasłuchiwanie portalu OG
task.spawn(function()
	local portal = Workspace:WaitForChild("OGPortal", 20)
	if not portal then
		warn("[ZoneProgression] OGPortal not loaded within 20s!")
		return
	end
	
	-- Funkcja podłączana do eventu touched
	local function onTouched(hit)
		if debounce then return end
		
		local character = player.Character
		if character and hit:IsDescendantOf(character) then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				debounce = true
				
				local hasSecret = BrainrotUtils.hasCompletedRarity(player, "Secret")
				
				if hasSecret then
					local ogSpawn = Workspace:FindFirstChild("OGSpawn")
					-- OGSpawn też może być modelem
					local spawnCFrame = ogSpawn and (ogSpawn:IsA("Model") and ogSpawn:GetPivot() or ogSpawn.CFrame) or nil
					
					if spawnCFrame then
						hrp.CFrame = spawnCFrame + Vector3.new(0, 3, 0)
					else
						warn("OGSpawn not found in Workspace!")
					end
					task.wait(1) -- Czas na TP
				else
					warningLabel.Visible = true
					task.delay(3, function()
						warningLabel.Visible = false
					end)
					
					-- Dajemy mu 3 sekundy kary po odbiciu się zanim znowu wyskoczy gui
					task.wait(3)
				end
				
				debounce = false
			end
		end
	end

	-- Podpięcie do elementu głównego jeśli jest BasePart
	if portal:IsA("BasePart") then
		portal.Touched:Connect(onTouched)
	end

	-- Podpięcie do wszystkich aktualnych części w środku
	for _, part in ipairs(portal:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end

	-- ROZWIĄZANIE PROBLEMU STREAMINGU: podpięcie do części, które załadują się w przyszłości
	portal.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.Touched:Connect(onTouched)
		end
	end)
end)

print("ZoneProgressionClient loaded.")
