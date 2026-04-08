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
local oldGui = PlayerGui:FindFirstChild("TrollMenu")
if oldGui then oldGui:Destroy() end

local oldToggle = PlayerGui:FindFirstChild("TrollToggleGui")
if oldToggle then oldToggle:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrollMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 105
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Toggle Button
local DevilEmoji = ReplicatedStorage:WaitForChild("DevilEmoji", 5)
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "TrollToggleGui"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = PlayerGui

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleTrollMenu"
ToggleBtn.Position = HudTileStyle.getSlot("right", 4)
ToggleBtn.ZIndex = 50
ToggleBtn.Parent = ToggleGui

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
MainFrame.Size = UDim2.new(0, 280, 0, 420)
MainFrame.ZIndex = 100

-- Prawy dolny róg (otwarte) i zjazd poza prawą dolną krawędź (zamknięte)
local openPos = UDim2.new(1, -420, 1, -440)
local closedPos = UDim2.new(1, 40, 1, -440)

MainFrame.Position = closedPos
MainFrame.Visible = false
MainFrame.BackgroundColor3 = Color3.new(1, 1, 1) -- BIAŁE do Gradientu
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 60, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 20, 140))
})
mainGradient.Rotation = 90
mainGradient.Parent = MainFrame

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 15)
UICornerMain.Parent = MainFrame

-- Tło GreenStuds z ReplicatedStorage
local patternBg = Instance.new("ImageLabel")
patternBg.Name = "PatternBg"
patternBg.Size = UDim2.fromScale(1, 1)
patternBg.BackgroundTransparency = 1
patternBg.Image = HudTileStyle.getImage(ReplicatedStorage, "GreenStuds", "")
patternBg.ImageColor3 = Color3.fromRGB(200, 130, 255)
patternBg.ImageTransparency = 0.8
patternBg.ScaleType = Enum.ScaleType.Tile
patternBg.TileSize = UDim2.fromOffset(128, 128)
patternBg.ZIndex = 100
patternBg.Parent = MainFrame
local patternCorner = Instance.new("UICorner")
patternCorner.CornerRadius = UDim.new(0, 15)
patternCorner.Parent = patternBg

-- Tytuł Menu
local TitleFrame = Instance.new("TextLabel")
TitleFrame.Name = "TitleFrame"
TitleFrame.Size = UDim2.new(1, -40, 0, 40)
TitleFrame.Position = UDim2.new(0, 20, 0, 10)
TitleFrame.BackgroundTransparency = 1
TitleFrame.Font = Enum.Font.LuckiestGuy
TitleFrame.Text = "TROLL MENU"
TitleFrame.TextColor3 = Color3.fromRGB(255, 30, 30) -- Bardziej intensywny czerwony
TitleFrame.TextSize = 34
TitleFrame.ZIndex = 101
TitleFrame.Parent = MainFrame

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Thickness = 2
TitleStroke.Color = Color3.new(0, 0, 0)
TitleStroke.Parent = TitleFrame

-- Przycisk Zamknięcia X
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
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
SpectateContainer.Size = UDim2.new(1, -40, 0, 50)
SpectateContainer.Position = UDim2.new(0, 20, 0, 60)
SpectateContainer.BackgroundTransparency = 1
SpectateContainer.Parent = MainFrame

local PrevBtn = Instance.new("TextButton")
PrevBtn.Name = "PrevBtn"
PrevBtn.Size = UDim2.new(0, 45, 1, 0)
PrevBtn.Position = UDim2.new(0, 0, 0, 0)
PrevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PrevBtn.Text = "<"
PrevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.TextSize = 28
PrevBtn.Parent = SpectateContainer
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0, 6)

local NextBtn = Instance.new("TextButton")
NextBtn.Name = "NextBtn"
NextBtn.Size = UDim2.new(0, 45, 1, 0)
NextBtn.Position = UDim2.new(1, -45, 0, 0)
NextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NextBtn.Text = ">"
NextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NextBtn.Font = Enum.Font.GothamBold
NextBtn.TextSize = 28
NextBtn.Parent = SpectateContainer
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0, 6)

local SpectateLabel = Instance.new("TextLabel")
SpectateLabel.Name = "SpectateLabel"
SpectateLabel.Size = UDim2.new(1, -100, 1, 0)
SpectateLabel.Position = UDim2.new(0, 50, 0, 0)
SpectateLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpectateLabel.Text = "Spectate: None"
SpectateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpectateLabel.Font = Enum.Font.GothamBold -- Bardziej czytelna czcionka
SpectateLabel.TextSize = 20 -- Zwiększony rozmiar tekstu z 14
SpectateLabel.TextScaled = true -- Dodane skalowanie żeby dobrze wypełniało przestrzeń
SpectateLabel.TextWrapped = true
SpectateLabel.Parent = SpectateContainer
Instance.new("UICorner", SpectateLabel).CornerRadius = UDim.new(0, 6)
local SpectateStroke = Instance.new("UIStroke")
SpectateStroke.Thickness = 1.5
SpectateStroke.Color = Color3.new(0, 0, 0)
SpectateStroke.Parent = SpectateLabel

local spectateIndex = 0
local spectateTarget = nil
local trollButtons = {}
local targetAttributeConnections = {}

local function disconnectTargetAttributeConnections()
    for _, connection in ipairs(targetAttributeConnections) do
        connection:Disconnect()
    end

    table.clear(targetAttributeConnections)
end

local function isTargetVipProtected(target)
    return target and target:GetAttribute("HasVIP") == true and target:GetAttribute("VIPProtectionEnabled") == true
end

local function setTrollButtonsLocked(locked)
    for _, button in ipairs(trollButtons) do
        button.Interactable = not locked
        button.AutoButtonColor = not locked
        button.BackgroundColor3 = locked and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(70, 70, 70)
        button.TextColor3 = locked and Color3.fromRGB(110, 110, 110) or Color3.fromRGB(255, 255, 255)
    end
end

local function getTargetStatusText(target)
    if not target then
        return "Spectate: None", false
    end

    local statusBits = {}
    local locked = false

    if target ~= LocalPlayer then
        if BrainrotUtils.hasCompletedRarity(target, "Secret") then
            table.insert(statusBits, "OG SEARCHER - IMMUNE")
            locked = true
        end

        if isTargetVipProtected(target) then
            table.insert(statusBits, "VIP PROTECTION ENABLED")
            locked = true
        end
    end

    local text = "Spectating: " .. target.Name
    if #statusBits > 0 then
        text = text .. "\n(" .. table.concat(statusBits, " | ") .. ")"
    end

    return text, locked
end

local function refreshSpectateDisplay()
    local text, locked = getTargetStatusText(spectateTarget)
    SpectateLabel.Text = text
    setTrollButtonsLocked(locked)
end

local function watchTargetAttributes(target)
    disconnectTargetAttributeConnections()

    if not target then
        return
    end

    table.insert(targetAttributeConnections, target:GetAttributeChangedSignal("VIPProtectionEnabled"):Connect(refreshSpectateDisplay))
    table.insert(targetAttributeConnections, target:GetAttributeChangedSignal("HasVIP"):Connect(refreshSpectateDisplay))
end

local function stopSpectating()
    Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    SpectateLabel.Text = "Spectate: None"
    spectateTarget = nil
    disconnectTargetAttributeConnections()
    refreshSpectateDisplay()
    -- Fall through and restore any remaining legacy button states.
    
    -- Zabezpieczające odblokowanie przycisków trolli
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child:GetAttribute("IsTrollActionButton") then
            child.Interactable = true
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
        spectateTarget = target
        watchTargetAttributes(target)
        refreshSpectateDisplay()
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
        for name, closeFunc in pairs(_G.UiMenus) do
            if name ~= "TrollMenu" then closeFunc() end
        end
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

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["TrollMenu"] = function()
    if menuOpen then
        toggleMenu()
    end
end

ToggleBtn.MouseButton1Click:Connect(toggleMenu)
CloseBtn.MouseButton1Click:Connect(toggleMenu)

local function createTrollButton(name, yPos, productId)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(1, -40, 0, 50)
    Button.Position = UDim2.new(0, 20, 0, yPos)
    Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Button.Text = "" -- Usunięto tekst na rzecz własnego labla wyżej w hierarchii Z
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 20
    Button.ZIndex = 101
    Button.ClipsDescendants = true
    Button.Parent = MainFrame

    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(0, 10)
    UICornerBtn.Parent = Button

    -- Cieniowanie przycisku bazowe
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 2
    btnStroke.Color = Color3.fromRGB(200, 200, 200)
    btnStroke.Transparency = 0.2
    btnStroke.Parent = Button

    local customText = Instance.new("TextLabel")
    customText.Name = "ButtonText"
    customText.Size = UDim2.fromScale(1, 1)
    customText.BackgroundTransparency = 1
    customText.Text = name .. " Troll"
    customText.TextColor3 = Color3.fromRGB(255, 255, 255)
    customText.Font = Enum.Font.GothamBold
    customText.TextSize = 20
    customText.ZIndex = 105
    customText.Parent = Button

    -- Obrys do tekstu dla czytelności na teksturach
    local textStroke = Instance.new("UIStroke")
    textStroke.Thickness = 1.5
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Parent = customText

    if name == "Fart" then
        Button.BackgroundColor3 = Color3.fromRGB(90, 140, 70)
        local fartImg = HudTileStyle.getImage(ReplicatedStorage, "Fart", "")
        
        -- Zamiana małych ikonek na powielone tło (Tile) tak jak w Tornado Troll
        local bgImg = Instance.new("ImageLabel")
        bgImg.Size = UDim2.fromScale(1, 1)
        bgImg.BackgroundTransparency = 1
        bgImg.Image = fartImg
        bgImg.ScaleType = Enum.ScaleType.Tile
        bgImg.TileSize = UDim2.new(0, 70, 1, 0) -- Szerokość 70px (poszerzone boki w stosunku do wysokości), Wysokość = 100%
        bgImg.ImageTransparency = 0.5 -- Lekko przezroczyste/wyblakłe
        bgImg.ZIndex = 102
        bgImg.Parent = Button

    elseif name == "Bomb" then
        Button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        local bombImg = HudTileStyle.getImage(ReplicatedStorage, "BombIcon", "")

        -- Zamiana na powielone tło (Tile) tak jak przy innych trollach
        local bgImg = Instance.new("ImageLabel")
        bgImg.Size = UDim2.fromScale(1, 1)
        bgImg.BackgroundTransparency = 1
        bgImg.Image = bombImg
        bgImg.ScaleType = Enum.ScaleType.Tile
        bgImg.TileSize = UDim2.new(0, 50, 1, 0) -- Kwadratowe wymiary żeby bomba nie była zniekształcona 50x50
        bgImg.ImageTransparency = 0.5 -- Lekko przezroczyste/wyblakłe tło
        bgImg.ZIndex = 102
        bgImg.Parent = Button

    elseif name == "Tornado" then
        local bgImg = Instance.new("ImageLabel")
        bgImg.Size = UDim2.fromScale(1, 1)
        bgImg.BackgroundTransparency = 1
        bgImg.Image = HudTileStyle.getImage(ReplicatedStorage, "TornadoIcon", "")
        bgImg.ScaleType = Enum.ScaleType.Tile
        bgImg.TileSize = UDim2.new(0, 50, 1, 0) -- Szerokość 50px, Wysokość = 100% ramki (50px wysokości przycisku), to sprawia że w pionie jest dokładnie 1 ikona
        bgImg.ImageTransparency = 0.5 -- Lekko przezroczyste
        bgImg.ImageColor3 = Color3.fromRGB(150, 150, 150) -- "Lekko poszarzały" efekt, przyciemniający oryginalne kolory
        bgImg.ZIndex = 102
        bgImg.Parent = Button
        Button.BackgroundColor3 = Color3.fromRGB(80, 100, 110) -- Tło pod przezroczystością też poszarzone

    elseif name == "Lava" then
        local bgImg = Instance.new("ImageLabel")
        bgImg.Size = UDim2.fromScale(1, 1)
        bgImg.BackgroundTransparency = 1
        
        -- Zmieniono według instrukcji na wyszukanie na sztywno "LavaIcon" skoro zostało to tak zapisane
        local lavaAsset = ReplicatedStorage:FindFirstChild("LavaIcon")
        if lavaAsset then
            bgImg.Image = HudTileStyle.getImageFromObject(lavaAsset, "")
        else
            -- Dodatkowy fallback na wypadek gdyby nazwa różniła się wielkością liter (lavaicon, itp) lub nie było to w głównym ReplicatedStorage
            bgImg.Image = HudTileStyle.getImage(ReplicatedStorage, "LavaIcon", "")
        end
        
        bgImg.ScaleType = Enum.ScaleType.Tile
        bgImg.TileSize = UDim2.new(0, 50, 1, 0) -- Tak jak Tornado
        bgImg.ImageTransparency = 0.2
        bgImg.ZIndex = 102
        bgImg.Parent = Button
        Button.BackgroundColor3 = Color3.fromRGB(180, 60, 20)
    end

    Button:SetAttribute("IsTrollActionButton", true)
    table.insert(trollButtons, Button)

    Button.MouseButton1Click:Connect(function()
        if spectateTarget then
            -- Pre-flight check before prompting purchase! (Wysyłamy też nazwę trolla!)
            local CheckValidityRF = BrainrotEvents:FindFirstChild("CheckTrollValidity")
            if CheckValidityRF then
                local isValid, errMessage = CheckValidityRF:InvokeServer(spectateTarget, name)
                if not isValid then
                    if errMessage == "FREE_TROLL_USED" then
                        SpectateLabel.Text = "FREE FART TROLL USED!"
                        task.delay(2, function()
                            refreshSpectateDisplay()
                        end)
                        return
                    end

                    SpectateLabel.Text = "BLOCKED: " .. errMessage
                    task.delay(2, function()
                        refreshSpectateDisplay()
                    end)
                    return
                end
            end
            
            MarketplaceService:PromptProductPurchase(LocalPlayer, productId)
        else
            SpectateLabel.Text = "Select Target First!"
            task.delay(1.5, function()
                refreshSpectateDisplay()
            end)
        end
    end)
end

local yOffset = 130
for name, id in pairs(GameConfig.TrollProducts) do
    createTrollButton(name, yOffset, id)
    yOffset = yOffset + 65
end

refreshSpectateDisplay()

-- Clean up camera when character dies/respawns
LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    if not spectateTarget then
        Workspace.CurrentCamera.CameraSubject = humanoid
    end
end)
