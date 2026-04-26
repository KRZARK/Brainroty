local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HudTileStyle = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("HudTileStyle"))
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local SpawnSystemRequest = BrainrotEvents:WaitForChild("SpawnSystemRequest")

local oldGui = PlayerGui:FindFirstChild("SpawnTeleportUI")
if oldGui then oldGui:Destroy() end

local oldToggle = PlayerGui:FindFirstChild("SpawnToggleUI")
if oldToggle then oldToggle:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpawnTeleportUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local HomeImage = ReplicatedStorage:FindFirstChild("Domek")

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "SpawnToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = PlayerGui

local TeleportBtn = Instance.new("ImageButton")
TeleportBtn.Name = "TeleportBtn"
TeleportBtn.Position = HudTileStyle.getSlot("left", 6)
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
	slotIndex = 6,
	zIndex = 50,
})

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Name = "ConfirmFrame"
ConfirmFrame.Size = UDim2.new(0, 320, 0, 140)
ConfirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ConfirmFrame.Visible = false
ConfirmFrame.Parent = ScreenGui
Instance.new("UICorner", ConfirmFrame).CornerRadius = UDim.new(0, 12)

HudTileStyle.bindResponsivePanelScale(ConfirmFrame, {
	baseSize = UDim2.fromOffset(320, 140),
	landscapeWidthRatio = 0.7,
	landscapeHeightRatio = 0.42,
	portraitWidthRatio = 0.9,
	portraitHeightRatio = 0.3,
	mobileMinScale = 0.72,
})

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
	btn.TextColor3 = Color3.new(1, 1, 1)
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
		TweenService:Create(TeleportBtn, TweenInfo.new(0.2), { Rotation = 0 }):Play()
	end
end

TeleportBtn.MouseButton1Click:Connect(function()
	if not ConfirmFrame.Visible then
		for name, closeFunc in pairs(_G.UiMenus) do
			if name ~= "SpawnTeleport" then closeFunc() end
		end
	end

	TweenService:Create(TeleportBtn, TweenInfo.new(0.2), { Rotation = -15 }):Play()
	ConfirmFrame.Visible = true

	local openTween = TweenService:Create(
		ConfirmFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 330, 0, 145) }
	)
	openTween:Play()
	openTween.Completed:Connect(function()
		TweenService:Create(ConfirmFrame, TweenInfo.new(0.1), { Size = UDim2.new(0, 320, 0, 140) }):Play()
	end)
end)

local function closeConfirmFrame()
	ConfirmFrame.Visible = false
	TweenService:Create(TeleportBtn, TweenInfo.new(0.2), { Rotation = 0 }):Play()
end

CancelBtn.MouseButton1Click:Connect(closeConfirmFrame)

YesBtn.MouseButton1Click:Connect(function()
	closeConfirmFrame()
	SpawnSystemRequest:FireServer("ReturnToMainSpawn")
end)
