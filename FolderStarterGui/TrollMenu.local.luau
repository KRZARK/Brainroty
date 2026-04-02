local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollSpectateTarget = BrainrotEvents:WaitForChild("TrollSpectateTarget")

local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotUtils = require(FolderReplicatedStorage:WaitForChild("BrainrotUtils"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

-- Create UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrollMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Toggle Button
local DevilEmoji = ReplicatedStorage:WaitForChild("DevilEmoji", 5)
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleTrollMenu"
ToggleBtn.Position = HudTileStyle.getSlot("right", 4)
ToggleBtn.ZIndex = 50
ToggleBtn.Parent = ScreenGui

local trollIcon = Instance.new("ImageLabel")
trollIcon.Name = "TrollIcon"
trollIcon.Image = DevilEmoji and (DevilEmoji:IsA("Decal") and DevilEmoji.Texture or DevilEmoji.Image) or "rbxassetid://164479326"
trollIcon.Parent = ToggleBtn

local btnLabel = Instance.new("TextLabel")
btnLabel.Text = "TROLL"
btnLabel.Parent = ToggleBtn

HudTileStyle.apply(ToggleBtn, trollIcon, btnLabel, {
	side = "right",
	slotIndex = 4,
	zIndex = 50,
})

-- Panel Główny
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 600)

-- Prawy dolny róg (otwarte) i zjazd poza prawą dolną krawędź (zamknięte)
local openPos = UDim2.new(1, -420, 1, -620)
local closedPos = UDim2.new(1, 20, 1, -620)

MainFrame.Position = closedPos
MainFrame.Visible = false
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 15)
UICornerMain.Parent = MainFrame

-- Tytuł Menu
local TitleFrame = Instance.new("TextLabel")
TitleFrame.Name = "TitleFrame"
TitleFrame.Size = UDim2.new(1, -60, 0, 50)
TitleFrame.Position = UDim2.new(0, 20, 0, 10)
TitleFrame.BackgroundTransparency = 1
TitleFrame.Font = Enum.Font.LuckiestGuy
TitleFrame.Text = "TROLL MENU"
TitleFrame.TextColor3 = Color3.fromRGB(200, 40, 40)
TitleFrame.TextSize = 45
TitleFrame.Parent = MainFrame

-- Przycisk Zamknięcia X
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0, 15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 24
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Kontener do podglądania (Ze strzałkami)
local SpectateContainer = Instance.new("Frame")
SpectateContainer.Name = "SpectateContainer"
SpectateContainer.Size = UDim2.new(1, -40, 0, 70)
SpectateContainer.Position = UDim2.new(0, 20, 0, 80)
SpectateContainer.BackgroundTransparency = 1
SpectateContainer.Parent = MainFrame

local PrevBtn = Instance.new("TextButton")
PrevBtn.Name = "PrevBtn"
PrevBtn.Size = UDim2.new(0, 60, 1, 0)
PrevBtn.Position = UDim2.new(0, 0, 0, 0)
PrevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PrevBtn.Text = "<"
PrevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.TextSize = 35
PrevBtn.Parent = SpectateContainer
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0, 8)

local NextBtn = Instance.new("TextButton")
NextBtn.Name = "NextBtn"
NextBtn.Size = UDim2.new(0, 60, 1, 0)
NextBtn.Position = UDim2.new(1, -60, 0, 0)
NextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NextBtn.Text = ">"
NextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NextBtn.Font = Enum.Font.GothamBold
NextBtn.TextSize = 35
NextBtn.Parent = SpectateContainer
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0, 8)

local SpectateLabel = Instance.new("TextLabel")
SpectateLabel.Name = "SpectateLabel"
SpectateLabel.Size = UDim2.new(1, -140, 1, 0)
SpectateLabel.Position = UDim2.new(0, 70, 0, 0)
SpectateLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpectateLabel.Text = "Spectate: None"
SpectateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpectateLabel.Font = Enum.Font.Gotham
SpectateLabel.TextSize = 20
SpectateLabel.TextWrapped = true
SpectateLabel.Parent = SpectateContainer
Instance.new("UICorner", SpectateLabel).CornerRadius = UDim.new(0, 8)

local spectateIndex = 0
local spectateTarget = nil

local function stopSpectating()
    Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    SpectateLabel.Text = "Spectate: None"
    spectateTarget = nil
    
    -- Zabezpieczające odblokowanie przycisków trolli
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child.Active = true
            child.AutoButtonColor = true
            child.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            child.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function updateSpectateTarget(dir)
    local players = Players:GetPlayers()
    local others = {}
    for _, p in ipairs(players) do
        -- [TUTAJ ZMIENIĆ PRZED WYDANIEM GRY]
        -- Aby wyłączyć podglądanie samego siebie, usuń komentarze z poniższych dwóch linii:
        -- if p ~= LocalPlayer then
            table.insert(others, p)
        -- end
    end
    
    if #others == 0 then
        SpectateLabel.Text = "No one else to spectate"
        stopSpectating()
        return
    end

    spectateIndex = spectateIndex + dir
    if spectateIndex > #others then spectateIndex = 1 end
    if spectateIndex < 1 then spectateIndex = #others end

    local target = others[spectateIndex]

    if target and target.Character and target.Character:FindFirstChild("Humanoid") then
        Workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
        
        local isImmune = BrainrotUtils.hasCompletedRarity(target, "Secret")
        if isImmune then
            SpectateLabel.Text = "Spectating: " .. target.Name .. "\n(OG SEARCHER - IMMUNE)"
            -- Zablokuj przyciski (trolle to dzieci MainFrame)
            for _, child in ipairs(MainFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Active = false
                    child.AutoButtonColor = false
                    child.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    child.TextColor3 = Color3.fromRGB(100, 100, 100)
                end
            end
        else
            SpectateLabel.Text = "Spectating: " .. target.Name
            -- Odblokuj przyciski
            for _, child in ipairs(MainFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Active = true
                    child.AutoButtonColor = true
                    child.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                    child.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
        
        spectateTarget = target
        TrollSpectateTarget:FireServer(target)
    else
        stopSpectating()
    end
end

PrevBtn.MouseButton1Click:Connect(function() updateSpectateTarget(-1) end)
NextBtn.MouseButton1Click:Connect(function() updateSpectateTarget(1) end)

-- Logika animacji i auto-włączania podglądania
local menuOpen = false

local function toggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        MainFrame.Visible = true
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(MainFrame, tweenInfo, {Position = openPos}):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 15}):Play()
        
        -- Auto-start spektowania przy otwarciu (wymuś +1)
        if not spectateTarget then
            updateSpectateTarget(1)
        end
    else
        -- Zatrzymujemy spektowanie przy ukryciu menu
        stopSpectating()
        
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(MainFrame, tweenInfo, {Position = closedPos})
        tween:Play()
        tween.Completed:Connect(function()
            if not menuOpen then
                MainFrame.Visible = false
            end
        end)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
    end
end

ToggleBtn.MouseButton1Click:Connect(toggleMenu)
CloseBtn.MouseButton1Click:Connect(toggleMenu)

local function createTrollButton(name, yPos, productId)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(1, -60, 0, 70)
    Button.Position = UDim2.new(0, 30, 0, yPos)
    Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Button.Text = name .. " Troll"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 25
    Button.Parent = MainFrame

    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(0, 10)
    UICornerBtn.Parent = Button

    Button.MouseButton1Click:Connect(function()
        if spectateTarget then
            -- Pre-flight check before prompting purchase! (Wysyłamy też nazwę trolla!)
            local CheckValidityRF = BrainrotEvents:FindFirstChild("CheckTrollValidity")
            if CheckValidityRF then
                local isValid, errMessage = CheckValidityRF:InvokeServer(spectateTarget, name)
                if not isValid then
                    SpectateLabel.Text = "BLOCKED: " .. errMessage
                    task.delay(2, function()
                        if spectateTarget then
                            local isImmune = BrainrotUtils.hasCompletedRarity(spectateTarget, "Secret")
                            SpectateLabel.Text = "Spectating: " .. spectateTarget.Name .. (isImmune and "\n(OG SEARCHER - IMMUNE)" or "")
                        else
                            SpectateLabel.Text = "Spectate: None"
                        end
                    end)
                    return
                end
            end
            
            MarketplaceService:PromptProductPurchase(LocalPlayer, productId)
        else
            SpectateLabel.Text = "Select Target First!"
            task.delay(1.5, function()
                if spectateTarget then
                    local isImmune = BrainrotUtils.hasCompletedRarity(spectateTarget, "Secret")
                    SpectateLabel.Text = "Spectating: " .. spectateTarget.Name .. (isImmune and "\n(OG SEARCHER - IMMUNE)" or "")
                else
                    SpectateLabel.Text = "Spectate: None"
                end
            end)
        end
    end)
end

local yOffset = 180
for name, id in pairs(GameConfig.TrollProducts) do
    createTrollButton(name, yOffset, id)
    yOffset = yOffset + 90
end

-- Clean up camera when character dies/respawns
LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    if not spectateTarget then
        Workspace.CurrentCamera.CameraSubject = humanoid
    end
end)
