local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local RebirthEvent = BrainrotEvents:WaitForChild("RebirthEvent")
local function safeWait(parent, name)
    local obj = parent:WaitForChild(name, 5) -- Czekaj 5 sekund
    if not obj then
        warn("!! PROBLEM: Brak obiektu '" .. name .. "' w " .. parent.Name .. " !!")
    end
    return obj
end

local GreenStuds = safeWait(ReplicatedStorage, "GreenStuds")
local Paws = safeWait(ReplicatedStorage, "Paws")
local SpeedAsset = safeWait(ReplicatedStorage, "speed")
local CoinAsset = safeWait(ReplicatedStorage, "Coin2D")
local AuraAsset = safeWait(ReplicatedStorage, "Aura")
local WarningAsset = safeWait(ReplicatedStorage, "warning")

-- Kolekcje dla animacji (muszą być na górze)
local rbSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), ColorSequenceKeypoint.new(0.2, Color3.new(1,1,0)),
    ColorSequenceKeypoint.new(0.4, Color3.new(0,1,0)), ColorSequenceKeypoint.new(0.6, Color3.new(0,1,1)),
    ColorSequenceKeypoint.new(0.8, Color3.new(0,0,1)), ColorSequenceKeypoint.new(1, Color3.new(1,0,1))
})
local rainbows = {}
local animatedIcons = {}

-- === 1. TWORZENIE GUI ===
local screenGui = playerGui:FindFirstChild("RebirthPromptGui")
if screenGui then screenGui:Destroy() end

screenGui = Instance.new("ScreenGui")
screenGui.Name = "RebirthPromptGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.Enabled = false
screenGui.Parent = playerGui

-- GŁÓWNA RAMKA (bladozielone tło z subtelną teksturą studs)
local mainFrame = Instance.new("ImageLabel")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(780, 500)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(140, 190, 255) -- Bardziej soczysty niebieski
mainFrame.Image = GreenStuds:IsA("Decal") and GreenStuds.Texture or GreenStuds.Image
mainFrame.ImageTransparency = 0.75
mainFrame.ImageColor3 = Color3.fromRGB(100, 180, 255) -- Mocny błękitny tint
mainFrame.ScaleType = Enum.ScaleType.Tile
mainFrame.TileSize = UDim2.fromOffset(100, 100)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)

local uiScale = Instance.new("UIScale", mainFrame)
uiScale.Scale = 1.2

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 6
mainStroke.Color = Color3.new(1, 1, 1)

local rainbowGradient = Instance.new("UIGradient", mainStroke)
rainbowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
})

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 65)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "ODRODZENIE"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.FredokaOne
title.TextSize = 38
title.Parent = mainFrame
local titleStroke = Instance.new("UIStroke", title)
titleStroke.Thickness = 3
titleStroke.Color = Color3.new(0, 0, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(45, 45)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 28
closeBtn.ZIndex = 10
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Thickness = 2
closeStroke.Color = Color3.fromRGB(100, 0, 0)

-- === PANELE KOLUMN ===
local leftPanel = Instance.new("ImageLabel")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.42, 0, 0.62, 0)
leftPanel.Position = UDim2.new(0.04, 0, 0.18, 0)
leftPanel.BackgroundTransparency = 0.4
leftPanel.BackgroundColor3 = Color3.fromRGB(0, 60, 160) -- Mocny Ciemny Niebieski
leftPanel.Image = GreenStuds:IsA("Decal") and GreenStuds.Texture or GreenStuds.Image
leftPanel.ImageTransparency = 0.6
leftPanel.ImageColor3 = Color3.fromRGB(50, 120, 255)
leftPanel.ScaleType = Enum.ScaleType.Tile
leftPanel.TileSize = UDim2.fromOffset(100, 100)
leftPanel.Parent = mainFrame
Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 12)
local leftStroke = Instance.new("UIStroke", leftPanel)
leftStroke.Thickness = 2
leftStroke.Color = Color3.fromRGB(180, 180, 180) -- Jaśniejsza obwódka dla lepszego kontrastu

local rightPanel = Instance.new("ImageLabel")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.42, 0, 0.62, 0)
rightPanel.Position = UDim2.new(0.54, 0, 0.18, 0)
rightPanel.BackgroundTransparency = 0.4
rightPanel.BackgroundColor3 = Color3.fromRGB(0, 60, 160) -- Mocny Ciemny Niebieski
rightPanel.Image = GreenStuds:IsA("Decal") and GreenStuds.Texture or GreenStuds.Image
rightPanel.ImageTransparency = 0.6
rightPanel.ImageColor3 = Color3.fromRGB(50, 120, 255)
rightPanel.ScaleType = Enum.ScaleType.Tile
rightPanel.TileSize = UDim2.fromOffset(100, 100)
rightPanel.Parent = mainFrame
Instance.new("UICorner", rightPanel).CornerRadius = UDim.new(0, 12)
local rightStroke = Instance.new("UIStroke", rightPanel)
rightStroke.Thickness = 2
rightStroke.Color = Color3.fromRGB(180, 180, 180) -- Jaśniejsza obwódka

-- NAGŁÓWKI
local leftHeader = Instance.new("TextLabel")
leftHeader.Name = "LeftHeader"
leftHeader.Size = UDim2.new(0.42, 0, 0, 35)
leftHeader.Position = UDim2.new(0.04, 0, 0.14, 0)
leftHeader.BackgroundTransparency = 1
leftHeader.Text = "OBECNIE (PRESTIŻ 0)"
leftHeader.TextColor3 = Color3.fromRGB(0, 255, 255)
leftHeader.Font = Enum.Font.FredokaOne
leftHeader.TextSize = 32
leftHeader.Parent = mainFrame
local lhStroke = Instance.new("UIStroke", leftHeader)
lhStroke.Thickness = 2
lhStroke.Color = Color3.new(0, 0, 0)

local rightHeader = Instance.new("TextLabel")
rightHeader.Name = "RightHeader"
rightHeader.Size = UDim2.new(0.42, 0, 0, 35)
rightHeader.Position = UDim2.new(0.54, 0, 0.14, 0)
rightHeader.BackgroundTransparency = 1
rightHeader.Text = "PO ODRODZENIU (PRESTIŻ 1)"
rightHeader.TextColor3 = Color3.fromRGB(255, 0, 255)
rightHeader.Font = Enum.Font.FredokaOne
rightHeader.TextSize = 32
rightHeader.Parent = mainFrame
local rhStroke = Instance.new("UIStroke", rightHeader)
rhStroke.Thickness = 2
rhStroke.Color = Color3.new(0, 0, 0)

-- STRZAŁKA
local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.new(0.08, 0, 0, 60)
arrow.Position = UDim2.new(0.46, 0, 0.42, 0)
arrow.BackgroundTransparency = 1
arrow.Text = "➡"
arrow.TextColor3 = Color3.fromRGB(0, 100, 0)
arrow.Font = Enum.Font.FredokaOne
arrow.TextSize = 65
arrow.Parent = mainFrame
local arrowStroke = Instance.new("UIStroke", arrow)
arrowStroke.Thickness = 2
arrowStroke.Color = Color3.new(1, 1, 1)

-- RZĘDY STATYSTYK
local function createStatRow(parent, iconAsset, iconColor, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(0.92, 0, 0, 68)
    row.Position = UDim2.new(0.04, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local ico = Instance.new("ImageLabel")
    ico.Size = UDim2.fromOffset(64, 64)
    ico.Position = UDim2.new(0, 0, 0.5, 0)
    ico.AnchorPoint = Vector2.new(0, 0.5)
    ico.BackgroundTransparency = 1
    ico.Image = iconAsset
    ico.ImageColor3 = iconColor
    ico.ImageTransparency = 0 -- Gwarantujemy pełną nasycenie koloru
    ico.Parent = row

    local lblCont = Instance.new("Frame")
    lblCont.Size = UDim2.new(1, -80, 1, 0)
    lblCont.Position = UDim2.new(0, 75, 0, 0)
    lblCont.BackgroundTransparency = 1
    lblCont.Parent = row
    local list = Instance.new("UIListLayout", lblCont)
    list.FillDirection = Enum.FillDirection.Vertical
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Padding = UDim.new(0, 2)

    local function createL(parent, isValue)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 0)
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.BackgroundTransparency = 1
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Font = Enum.Font.FredokaOne
        l.TextSize = 22
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 5
        l.Parent = parent
        local s = Instance.new("UIStroke", l)
        s.Thickness = 1.5; s.Color = Color3.new(0, 0, 0)
        return l
    end

    local nameLbl = createL(lblCont)
    local valLbl = createL(lblCont, true)

    table.insert(animatedIcons, ico)
    return nameLbl, valLbl, ico
end

local ICON_SPEED = SpeedAsset:IsA("Decal") and SpeedAsset.Texture or SpeedAsset.Image
local ICON_COIN  = CoinAsset:IsA("Decal") and CoinAsset.Texture or CoinAsset.Image
local ICON_PET   = Paws:IsA("Decal") and Paws.Texture or Paws.Image
local ICON_AURA  = AuraAsset:IsA("Decal") and AuraAsset.Texture or AuraAsset.Image

local spdLN, spdLV, spdLI = createStatRow(leftPanel, ICON_SPEED, Color3.fromRGB(0, 255, 255), 10)
local coinLN, coinLV, coinLI = createStatRow(leftPanel, ICON_COIN, Color3.fromRGB(0, 255, 255), 75)
local petLN, petLV, petLI = createStatRow(leftPanel, ICON_PET, Color3.fromRGB(0, 255, 255), 140)
local auraLN, auraLV, auraLI = createStatRow(leftPanel, ICON_AURA, Color3.fromRGB(100, 100, 100), 205)

local spdRN, spdRV, spdRI = createStatRow(rightPanel, ICON_SPEED, Color3.fromRGB(255, 200, 0), 10)
local coinRN, coinRV, coinRI = createStatRow(rightPanel, ICON_COIN, Color3.fromRGB(255, 200, 0), 75)
local petRN, petRV, petRI = createStatRow(rightPanel, ICON_PET, Color3.fromRGB(255, 200, 0), 140)
local auraRN, auraRV, auraRI = createStatRow(rightPanel, ICON_AURA, Color3.fromRGB(0, 200, 0), 205)

local warnBar = Instance.new("Frame")
warnBar.Size = UDim2.new(0.92, 0, 0, 35)
warnBar.Position = UDim2.new(0.5, 0, 0.77, 0)
warnBar.AnchorPoint = Vector2.new(0.5, 0)
warnBar.BackgroundColor3 = Color3.fromRGB(220, 180, 0)
warnBar.Parent = mainFrame
Instance.new("UICorner", warnBar).CornerRadius = UDim.new(0, 8)

local warnText = Instance.new("TextLabel")
warnText.Size = UDim2.fromScale(1, 1)
warnText.BackgroundTransparency = 1
warnText.Text = "TWOJE MONETY I KOLEKCJA ZOSTANĄ ZRESETOWANE!"
warnText.TextColor3 = Color3.fromRGB(60, 0, 0)
warnText.Font = Enum.Font.FredokaOne
warnText.TextSize = 22
warnText.TextWrapped = true
warnText.Parent = warnBar
local warnStroke = Instance.new("UIStroke", warnText)
warnStroke.Thickness = 0

-- ANIMOWANE IKONY OSTRZEGAWCZE ( warning )
local function createWarnIcon(side)
    local ico = Instance.new("ImageLabel")
    ico.Size = UDim2.fromOffset(30, 30)
    ico.Position = UDim2.new(side == "left" and 0 or 1, side == "left" and 5 or -5, 0.5, 0)
    ico.AnchorPoint = Vector2.new(side == "left" and 0 or 1, 0.5)
    ico.BackgroundTransparency = 1
    ico.Image = WarningAsset:IsA("Decal") and WarningAsset.Texture or WarningAsset.Image
    ico.ZIndex = 5
    ico.Parent = warnBar
    return ico
end
local warnIconL = createWarnIcon("left")
local warnIconR = createWarnIcon("right")

local confirmBtn = Instance.new("TextButton")
confirmBtn.Name = "ConfirmButton"
confirmBtn.Size = UDim2.new(0.45, 0, 0, 70)
confirmBtn.Position = UDim2.new(0.5, 0, 0.9, 0)
confirmBtn.AnchorPoint = Vector2.new(0.5, 0)
confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 0)
confirmBtn.Text = "POTWIERDZAM\nREBIRTH"
confirmBtn.TextColor3 = Color3.new(1, 1, 1)
confirmBtn.Font = Enum.Font.FredokaOne
confirmBtn.TextSize = 28
confirmBtn.Parent = mainFrame
Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 15)
confirmBtn.TextStrokeTransparency = 0
confirmBtn.TextStrokeColor3 = Color3.new(0, 0, 0) -- Czarna obwódka napisu
local btnStroke = Instance.new("UIStroke", confirmBtn)
btnStroke.Thickness = 3
btnStroke.Color = Color3.new(0, 0, 0)

-- === 2. LOGIKA ===
local function getRebirthStats(level)
    local stats = {
        Speed = "x1.0",
        Coins = "x1.0",
        Pets = GameConfig.GetPetUnlocksLabelForRebirthLevel(level),
        Aura = "Brak",
    }

    if level == 1 then
        stats.Speed = "x1.25"
        stats.Coins = "x1.25"
        stats.Aura = "Zielona"
    elseif level == 2 then
        stats.Speed = "x1.5"
        stats.Coins = "x1.5"
        stats.Aura = "Złota"
    elseif level >= 3 then
        stats.Speed = "x2.0"
        stats.Coins = "x2.0"
        stats.Aura = "Czerwona"
    end

    if level == 4 then
        stats.Aura = "Tęczowa"
    end

    if level >= 5 then
        stats.Pets = GameConfig.GetPetUnlocksLabelForRebirthLevel(5)
        stats.Aura = "Tęczowa MAX"
    end

    return stats
end

local function getAuraColorRGB(auraName)
    if auraName == "Brak" then return Color3.fromRGB(40, 40, 40) end -- Ciemnoszary, prawie czarny
    if auraName == "Zielona" then return Color3.fromRGB(0, 255, 0) end
    if auraName == "Złota" then return Color3.fromRGB(255, 215, 0) end
    if auraName == "Czerwona" then return Color3.fromRGB(255, 0, 0) end
    if string.find(auraName, "Tęczowa") then return Color3.fromRGB(255, 0, 255) end
    return Color3.fromRGB(255, 255, 255)
end

local function colorToRGBString(color)
    return string.format("rgb(%d,%d,%d)", color.R*255, color.G*255, color.B*255)
end

local function applyVisualStyle(obj, enabled, color)
    local g = obj:FindFirstChild("RainbowGrad")
    if enabled then
        if obj:IsA("TextLabel") then obj.TextColor3 = Color3.new(1,1,1) else obj.ImageColor3 = Color3.new(1,1,1) end
        if not g then
            g = Instance.new("UIGradient")
            g.Name = "RainbowGrad"; g.Color = rbSequence; g.Parent = obj
            table.insert(rainbows, g)
        end
    else
        if g then
            g:Destroy()
            for i, v in ipairs(rainbows) do if v == g then table.remove(rainbows, i); break end end
        end
        if obj:IsA("TextLabel") then obj.TextColor3 = color else obj.ImageColor3 = color end
    end
end

local canRebirth = false
local function updateDisplay()
    local leaderstats = player:FindFirstChild("leaderstats")
    local currentLevel = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
    local collection = player:FindFirstChild("BrainrotCollection")
    local count = collection and #collection:GetChildren() or 0
    local TARGET = GameConfig.TotalBrainrots

    local cur = getRebirthStats(currentLevel)
    local nxt = getRebirthStats(currentLevel + 1)
    local curAuraColor = getAuraColorRGB(cur.Aura)
    local nxtAuraColor = getAuraColorRGB(nxt.Aura)
    local curColorStr = colorToRGBString(curAuraColor)
    local nxtColorStr = colorToRGBString(nxtAuraColor)

    leftHeader.Text = "OBECNIE (PRESTIŻ " .. currentLevel .. ")"
    applyVisualStyle(leftHeader, currentLevel >= 4, curAuraColor)
    
    rightHeader.Text = "PO ODRODZENIU (PRESTIŻ " .. (currentLevel + 1) .. ")"
    applyVisualStyle(rightHeader, (currentLevel + 1) >= 4, nxtAuraColor)

    -- Funkcja pomocnicza do ustawiania statystyk z białym napisem i kolorową ikoną/wartością
    local function setStat(nameLbl, valLbl, ico, txt, val, color, isRb)
        nameLbl.Text = txt .. ":"
        nameLbl.TextColor3 = Color3.new(1, 1, 1)
        
        valLbl.Text = val
        applyVisualStyle(valLbl, isRb, color)
        applyVisualStyle(ico, isRb, color)
    end

    setStat(spdLN, spdLV, spdLI, "SZYBKOŚĆ", cur.Speed, curAuraColor, currentLevel >= 4)
    setStat(coinLN, coinLV, coinLI, "MNOŻNIK MONET", cur.Coins, curAuraColor, currentLevel >= 4)
    setStat(petLN, petLV, petLI, "BRAINROT PETS", cur.Pets, curAuraColor, currentLevel >= 4)
    setStat(auraLN, auraLV, auraLI, "TRAIL", cur.Aura, curAuraColor, currentLevel >= 4)

    local spdVal = nxt.Speed .. (nxt.Speed == cur.Speed and " (MAX)" or "")
    local coinVal = nxt.Coins .. (nxt.Coins == cur.Coins and " (MAX)" or "")
    local petVal = nxt.Pets .. (nxt.Pets == cur.Pets and " (MAX)" or "")
    local auraVal = nxt.Aura .. (nxt.Aura == cur.Aura and " (MAX)" or "")

    setStat(spdRN, spdRV, spdRI, "SZYBKOŚĆ", spdVal, nxtAuraColor, (currentLevel + 1) >= 4)
    setStat(coinRN, coinRV, coinRI, "MNOŻNIK MONET", coinVal, nxtAuraColor, (currentLevel + 1) >= 4)
    setStat(petRN, petRV, petRI, "BRAINROT PETS", petVal, nxtAuraColor, (currentLevel + 1) >= 4)
    setStat(auraRN, auraRV, auraRI, "TRAIL", auraVal, nxtAuraColor, (currentLevel + 1) >= 4)

    if count >= TARGET then
        canRebirth = true
        confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 0)
        confirmBtn.Text = "POTWIERDZAM\nREBIRTH"
        btnStroke.Color = Color3.fromRGB(0, 80, 0)
        
        local g = confirmBtn:FindFirstChild("MetallicGrad")
        if g then g:Destroy() end
    else
        canRebirth = false
        confirmBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Nieco ciemniejsza czerwień pod metalik
        confirmBtn.Text = "Brainroty: " .. count .. " / " .. TARGET .. "\n(Brakuje " .. (TARGET - count) .. ")"
        btnStroke.Color = Color3.new(0, 0, 0)
        
        -- Efekt metaliczny na napisie
        if not confirmBtn:FindFirstChild("MetallicGrad") then
            local g = Instance.new("UIGradient")
            g.Name = "MetallicGrad"
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
            })
            g.Rotation = 90
            g.Parent = confirmBtn
        end
    end
end

closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

local debounce = false
confirmBtn.MouseButton1Click:Connect(function()
    if debounce then return end
    if not canRebirth then
        debounce = true
        local op = confirmBtn.Position
        for i = 1, 6 do
            confirmBtn.Position = op + UDim2.fromOffset((i%2 == 0 and 5 or -5), 0)
            task.wait(0.05)
        end
        confirmBtn.Position = op
        debounce = false
        return
    end
    debounce = true
    RebirthEvent:FireServer()
    screenGui.Enabled = false
    task.wait(2)
    debounce = false
end)

_G.OpenRebirthPrompt = function()
    updateDisplay()
    screenGui.Enabled = true
end

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function()
    local t = tick()
    
    -- SPOKOJNIEJSZA ANIMACJA OBWÓDKI (Bardzo powolny obrót)
    rainbowGradient.Rotation = (t * 40) % 360
    
    -- Animacja strzałki
    arrow.Position = UDim2.new(0.46, math.sin(t * 6) * 8, 0.42, 0)

    -- PŁYNNA ANIMACJA TEKSTÓW TĘCZOWYCH (Przesunięcie zamiast szalonego obrotu)
    for _, g in ipairs(rainbows) do
        -- Przesuwamy offset w poziomie, co daje efekt "płynących" kolorów
        local flow = math.sin(t * 2) * 0.3
        g.Offset = Vector2.new(flow, 0)
        -- Delikatny obrót dla dynamiki, ale znacznie wolniej
        g.Rotation = math.sin(t * 0.5) * 15
    end

    -- Animacja ikon statystyk (delikatny obrót i pulsowanie)
    for i, ico in ipairs(animatedIcons) do
        local phase = i * 0.5 -- Różne ikony ruszają się w innym tempie/fazie
        ico.Rotation = math.sin(tick() * 2 + phase) * 6
        local s = 1 + math.sin(tick() * 3 + phase) * 0.06
        ico.Size = UDim2.fromOffset(64 * s, 64 * s)
    end

    -- Animacja ostrzeżeń (pulsowanie i obrót)
    local ws = 1 + math.sin(tick() * 10) * 0.15
    warnIconL.Size = UDim2.fromOffset(30 * ws, 30 * ws)
    warnIconR.Size = UDim2.fromOffset(30 * ws, 30 * ws)
    warnIconL.Rotation = math.sin(tick() * 8) * 10
    warnIconR.Rotation = math.sin(tick() * 8) * -10
end)

print("RebirthPromptScript Fixed and Loaded")
