local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollSpectateTarget = BrainrotEvents:WaitForChild("TrollSpectateTarget")

-- Troll Product IDs (Replace with actual ones if known, using placeholder IDs for now)
local TROLL_PRODUCTS = {
    Bomb = 100000001,
    Lava = 100000002,
    Tornado = 100000003,
    Fart = 100000004
}

-- Create UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrollMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Position = UDim2.new(1, -220, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Troll Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

-- Spectate functionality
local spectateIndex = 0
local spectateTarget = nil

local SpectateButton = Instance.new("TextButton")
SpectateButton.Name = "SpectateButton"
SpectateButton.Size = UDim2.new(1, -20, 0, 40)
SpectateButton.Position = UDim2.new(0, 10, 0, 50)
SpectateButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SpectateButton.Text = "Spectate: None"
SpectateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpectateButton.Font = Enum.Font.Gotham
SpectateButton.TextSize = 16
SpectateButton.Parent = MainFrame

local UICornerSpectate = Instance.new("UICorner")
UICornerSpectate.CornerRadius = UDim.new(0, 6)
UICornerSpectate.Parent = SpectateButton

SpectateButton.MouseButton1Click:Connect(function()
    local players = Players:GetPlayers()
    -- filter out local player if we want, but letting them spectate themselves is fine
    -- Actually let's keep all players

    spectateIndex = spectateIndex + 1
    if spectateIndex > #players then
        spectateIndex = 1
    end

    local target = players[spectateIndex]

    if target and target.Character and target.Character:FindFirstChild("Humanoid") then
        Workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
        SpectateButton.Text = "Spectating: " .. target.Name
        spectateTarget = target
        -- Send target to server for future troll actions
        TrollSpectateTarget:FireServer(target)
    else
        Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        SpectateButton.Text = "Spectate: None"
        spectateTarget = nil
    end
end)

local function createTrollButton(name, yPos, productId)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(1, -20, 0, 40)
    Button.Position = UDim2.new(0, 10, 0, yPos)
    Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Button.Text = name .. " Troll"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 16
    Button.Parent = MainFrame

    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(0, 6)
    UICornerBtn.Parent = Button

    Button.MouseButton1Click:Connect(function()
        if spectateTarget then
            MarketplaceService:PromptProductPurchase(LocalPlayer, productId)
        else
            SpectateButton.Text = "Select Target First!"
            task.delay(1.5, function()
                if spectateTarget then
                    SpectateButton.Text = "Spectating: " .. spectateTarget.Name
                else
                    SpectateButton.Text = "Spectate: None"
                end
            end)
        end
    end)
end

createTrollButton("Bomb", 100, TROLL_PRODUCTS.Bomb)
createTrollButton("Lava", 150, TROLL_PRODUCTS.Lava)
createTrollButton("Tornado", 200, TROLL_PRODUCTS.Tornado)
createTrollButton("Fart", 250, TROLL_PRODUCTS.Fart)

-- Clean up camera when character dies/respawns
LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    if not spectateTarget then
        Workspace.CurrentCamera.CameraSubject = humanoid
    end
end)
