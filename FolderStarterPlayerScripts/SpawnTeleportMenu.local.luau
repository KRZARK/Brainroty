local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpawnTeleportUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Poszukiwanie grafiki domku w ReplicatedStorage
local HomeImage = ReplicatedStorage:FindFirstChild("Domek")

local TeleportBtn = Instance.new("ImageButton")
TeleportBtn.Name = "TeleportBtn"
TeleportBtn.Size = UDim2.fromOffset(60, 60)
-- Domek w lewym dolnym rogu (odsunięty o 45 dla lepszej widoczności)
TeleportBtn.Position = UDim2.new(0, 45, 1, -100) 
TeleportBtn.BackgroundTransparency = 1
-- Jeśli Domek istnieje pobiera go, inaczej daje domyślną Robloxową ikonę domu
TeleportBtn.Image = HomeImage and (HomeImage:IsA("Decal") and HomeImage.Texture or HomeImage.Image) or "rbxassetid://6031280882"
TeleportBtn.Parent = ScreenGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(2, 0, 0, 20)
label.Position = UDim2.new(-0.5, 0, 1, 2)
label.BackgroundTransparency = 1
label.Text = "SPAWN TELEPORT"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.LuckiestGuy
label.TextSize = 16
label.TextStrokeTransparency = 0
label.Parent = TeleportBtn

-- Ramka weryfikacji po kliknięciu "Are you sure?"
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Name = "ConfirmFrame"
ConfirmFrame.Size = UDim2.new(0, 320, 0, 140)
ConfirmFrame.Position = UDim2.new(0.5, -160, 0.5, -70)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ConfirmFrame.Visible = false
ConfirmFrame.Parent = ScreenGui
Instance.new("UICorner", ConfirmFrame).CornerRadius = UDim.new(0, 12)

local question = Instance.new("TextLabel")
question.Size = UDim2.new(1, 0, 0.4, 0)
question.Position = UDim2.new(0, 0, 0, 15)
question.BackgroundTransparency = 1
question.Text = "Are you sure you want to teleport to Spawn?"
question.TextColor3 = Color3.fromRGB(240, 240, 240)
question.Font = Enum.Font.GothamBold
question.TextSize = 16
question.TextWrapped = true
question.Parent = ConfirmFrame

local function createButton(name, text, color, posX)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.4, 0, 0, 45)
	btn.Position = UDim2.new(posX, 0, 0.55, 0)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.Parent = ConfirmFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local YesBtn = createButton("YesBtn", "YES", Color3.fromRGB(60, 200, 60), 0.08)
local CancelBtn = createButton("CancelBtn", "NO", Color3.fromRGB(200, 60, 60), 0.52)

TeleportBtn.MouseButton1Click:Connect(function()
	ConfirmFrame.Visible = true
	local t = TweenService:Create(ConfirmFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 330, 0, 145)})
	t:Play()
	t.Completed:Connect(function()
		TweenService:Create(ConfirmFrame, TweenInfo.new(0.1), {Size = UDim2.new(0, 320, 0, 140)}):Play()
	end)
end)

CancelBtn.MouseButton1Click:Connect(function()
	ConfirmFrame.Visible = false
end)

YesBtn.MouseButton1Click:Connect(function()
	ConfirmFrame.Visible = false
	
	-- Znajdź blok SpawnLocation w Workspace
	local spawnLoc = nil
	for _, child in ipairs(Workspace:GetDescendants()) do
		if child:IsA("SpawnLocation") then
			spawnLoc = child
			break
		end
	end
	
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		-- Jeśli mamy Spawn w grze
		if spawnLoc then
			char:PivotTo(spawnLoc.CFrame + Vector3.new(0, 6, 0))
		else
			-- Fallback, powrót na bezpieczną pozycję np środek (jeśli nie ma klocka spawnu)
			char:PivotTo(CFrame.new(0, 20, 0))
		end
	end
end)
