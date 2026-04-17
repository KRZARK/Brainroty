local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HudTileStyle = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("HudTileStyle"))

local oldGui = PlayerGui:FindFirstChild("SpawnTeleportUI")
if oldGui then oldGui:Destroy() end

local oldToggle = PlayerGui:FindFirstChild("SpawnToggleUI")
if oldToggle then oldToggle:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpawnTeleportUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Poszukiwanie grafiki domku w ReplicatedStorage
local HomeImage = ReplicatedStorage:FindFirstChild("Domek")

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "SpawnToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = PlayerGui

local TeleportBtn = Instance.new("ImageButton")
TeleportBtn.Name = "TeleportBtn"
TeleportBtn.Position = HudTileStyle.getSlot("left", 4)
TeleportBtn.ZIndex = 50
TeleportBtn.Parent = ToggleGui

local teleportIcon = Instance.new("ImageLabel")
teleportIcon.Name = "TeleportIcon"
teleportIcon.Image = HomeImage and (HomeImage:IsA("Decal") and HomeImage.Texture or HomeImage.Image) or "rbxassetid://6031280882"
teleportIcon.Parent = TeleportBtn

local label = Instance.new("TextLabel")
label.Text = "SPAWN"
label.Parent = TeleportBtn

HudTileStyle.apply(TeleportBtn, teleportIcon, label, {
	side = "left",
	slotIndex = 4,
	zIndex = 50,
})

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

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["SpawnTeleport"] = function()
	if ConfirmFrame and ConfirmFrame.Visible then
		ConfirmFrame.Visible = false
		TweenService:Create(TeleportBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	end
end

TeleportBtn.MouseButton1Click:Connect(function()
	if not ConfirmFrame.Visible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "SpawnTeleport" then closeFunc() end
		end
	end
	TweenService:Create(TeleportBtn, TweenInfo.new(0.2), {Rotation = -15}):Play()
	ConfirmFrame.Visible = true
	local t = TweenService:Create(ConfirmFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 330, 0, 145)})
	t:Play()
	t.Completed:Connect(function()
		TweenService:Create(ConfirmFrame, TweenInfo.new(0.1), {Size = UDim2.new(0, 320, 0, 140)}):Play()
	end)
end)

local function closeConfirmFrame()
	ConfirmFrame.Visible = false
	TweenService:Create(TeleportBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
end

CancelBtn.MouseButton1Click:Connect(closeConfirmFrame)

YesBtn.MouseButton1Click:Connect(function()
	closeConfirmFrame()
	
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
