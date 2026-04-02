local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BrainrotStorage = ReplicatedStorage:WaitForChild("BrainrotStorage")

-- === 1. LOGIKA KOLEKCJI ===
local function getMissingItems(rarityName)
	local missing = {}
	local target = string.upper(rarityName)
	local collected = _G.CollectedBrainrotsTable or {}
	for _, item in ipairs(BrainrotStorage:GetChildren()) do
		if item:IsA("Model") then
			local itemRarity = string.upper(item:GetAttribute("Rarity") or "Common")
			if itemRarity == target and not collected[item.Name] then
				table.insert(missing, item)
			end
		end
	end
	return missing
end

local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

local CaseData = {}
for name, data in pairs(GameConfig.Rarities) do
	table.insert(CaseData, {
		Name = string.upper(name),
		ID = GameConfig.CaseProducts[name],
		Color = data.Color,
		Order = data.Order
	})
end
table.sort(CaseData, function(a, b) return a.Order < b.Order end)

-- === 2. TWORZENIE BAZY UI ===
-- Czyścimy ewentualny stary HUD przed stworzeniem nowego (np. po Rebirth)
local oldShop = playerGui:FindFirstChild("CaseShopUI")
if oldShop then 
	oldShop:Destroy() 
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CaseShopUI"
screenGui.DisplayOrder = 15 -- NA SAMYM WIERZCHU (NAD INDEKSEM)
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local glowEffect = Instance.new("ImageLabel", screenGui)
glowEffect.Name = "Glow"
glowEffect.Visible = false

local mainBtn = Instance.new("TextButton", screenGui)
mainBtn.Name = "MainShopButton"
mainBtn.Position = HudTileStyle.getSlot("left", 2)
mainBtn.Text = ""
mainBtn.ZIndex = 61

local btnImg = Instance.new("ImageLabel", mainBtn)
btnImg.Name = "ShopIcon"
btnImg.Image = HudTileStyle.getImage(ReplicatedStorage, "Shop", "rbxassetid://86015085773572")

local btnText = Instance.new("TextLabel", mainBtn)
btnText.Text = "SHOP"

HudTileStyle.apply(mainBtn, btnImg, btnText, {
	side = "left",
	slotIndex = 2,
	zIndex = 61,
})

local shopContainer = Instance.new("Frame", screenGui)
shopContainer.Size = UDim2.fromScale(0.8, 0.8)
shopContainer.Position = UDim2.fromScale(0.5, 0.5)
shopContainer.AnchorPoint = Vector2.new(0.5, 0.5)
shopContainer.BackgroundColor3 = Color3.fromRGB(180, 140, 255) -- Jasnofioletowy
shopContainer.Visible = false
shopContainer.ZIndex = 100
Instance.new("UICorner", shopContainer).CornerRadius = UDim.new(0, 20)
Instance.new("UIStroke", shopContainer).Thickness = 4

-- TŁO GreenStuds dla shopContainer
local shopBg = Instance.new("ImageLabel", shopContainer)
shopBg.Name = "ShopBg"
shopBg.Size = UDim2.fromScale(1, 1)
shopBg.BackgroundTransparency = 1
shopBg.ZIndex = 100 -- To samo co shopContainer, ale elementy wewnątrz będą miały wyższy ZIndex
local gs = ReplicatedStorage:FindFirstChild("GreenStuds")
if gs then shopBg.Image = gs:IsA("Decal") and gs.Texture or gs.Image end
shopBg.ImageTransparency = 0.8 -- Subtelny wzorek
shopBg.ScaleType = Enum.ScaleType.Tile
shopBg.TileSize = UDim2.fromOffset(128, 128)
Instance.new("UICorner", shopBg).CornerRadius = UDim.new(0, 20)

local closeButton = Instance.new("TextButton", screenGui)
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(80, 80)
closeButton.Position = UDim2.new(0.5 + (0.8/2), 0, 0.5 - (0.8/2), 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 45
closeButton.Visible = false
closeButton.ZIndex = 110
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(1, 0) 

-- 2.1 ZAKŁADKI (TABS) - Zastępują stary tytuł
local TabBrainrot = Instance.new("TextButton", shopContainer)
TabBrainrot.Name = "TabBrainrot"
TabBrainrot.Size = UDim2.new(0.5, -10, 0, 80)
TabBrainrot.Position = UDim2.new(0, 5, 0, 15)
TabBrainrot.BackgroundTransparency = 1
TabBrainrot.Text = "BRAINROT SHOP"
TabBrainrot.Font = Enum.Font.LuckiestGuy
TabBrainrot.TextSize = 55 -- Nieco mniejsze niż 70, żeby dwa się zmieściły ładnie
TabBrainrot.ZIndex = 110
TabBrainrot.TextColor3 = Color3.fromRGB(255, 0, 255) -- Magenta (Aktywny)
TabBrainrot.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabBrainrot.BackgroundTransparency = 0
Instance.new("UICorner", TabBrainrot).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", TabBrainrot).Thickness = 4

local TabBoosts = Instance.new("TextButton", shopContainer)
TabBoosts.Name = "TabBoosts"
TabBoosts.Size = UDim2.new(0.5, -10, 0, 80)
TabBoosts.Position = UDim2.new(0.5, 5, 0, 15)
TabBoosts.BackgroundTransparency = 1
TabBoosts.Text = "BOOST SHOP"
TabBoosts.Font = Enum.Font.LuckiestGuy
TabBoosts.TextSize = 55
TabBoosts.ZIndex = 110
TabBoosts.TextColor3 = Color3.fromRGB(150, 150, 150) -- Szary (Nieaktywny)
TabBoosts.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TabBoosts.BackgroundTransparency = 0.4
Instance.new("UICorner", TabBoosts).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", TabBoosts).Thickness = 4

-- 2.2 STRONY (PAGES)
local BrainrotPage = Instance.new("Frame", shopContainer)
BrainrotPage.Name = "BrainrotPage"
BrainrotPage.Size = UDim2.new(1, 0, 1, -100)
BrainrotPage.Position = UDim2.new(0, 0, 0, 100)
BrainrotPage.BackgroundTransparency = 1
BrainrotPage.Visible = true
BrainrotPage.ZIndex = 101

local BoostPage = Instance.new("Frame", shopContainer)
BoostPage.Name = "BoostPage"
BoostPage.Size = UDim2.new(1, 0, 1, -100)
BoostPage.Position = UDim2.new(0, 0, 0, 100)
BoostPage.BackgroundTransparency = 1
BoostPage.Visible = false
BoostPage.ZIndex = 101

-- === 2.3 LOGIKA PREMIUM SHOP (BoostPage) ===
local floatingElements = {}

-- Funkcja pomocnicza do hoverów
local function addHover(btn, originalSize)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, originalSize.Y.Scale * 1.05, originalSize.Y.Offset)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = originalSize
		}):Play()
	end)
end

-- Lewa Sekcja: Ulepszenia
local UpgradesFrame = Instance.new("Frame", BoostPage)
UpgradesFrame.Size = UDim2.new(0.48, 0, 0.9, 0)
UpgradesFrame.Position = UDim2.new(0.01, 0, 0.05, 0)
UpgradesFrame.BackgroundTransparency = 1
UpgradesFrame.ZIndex = 102

local UpgradesTitle = Instance.new("TextLabel", UpgradesFrame)
UpgradesTitle.Size = UDim2.new(1, 0, 0.1, 0)
UpgradesTitle.Position = UDim2.new(0, 0, 0, 0)
UpgradesTitle.Text = "UPGRADES"
UpgradesTitle.Font = Enum.Font.LuckiestGuy
UpgradesTitle.TextSize = 40
UpgradesTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
UpgradesTitle.BackgroundTransparency = 1
UpgradesTitle.ZIndex = 102
Instance.new("UIStroke", UpgradesTitle).Thickness = 3

local upgradesGradient = Instance.new("UIGradient", UpgradesTitle)
upgradesGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 0)), 
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 180, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 180, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0)) 
})


-- Przycisk VIP
local VIPBtn = Instance.new("TextButton", UpgradesFrame)
local vipOrigSize = UDim2.new(0.9, 0, 0.45, 0)
VIPBtn.Size = vipOrigSize
VIPBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
VIPBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
VIPBtn.Text = "ULTIMATE VIP BUNDLE\n[x2 Coins, +Speed, +Jump, VIP Tag]"
VIPBtn.Font = Enum.Font.LuckiestGuy
VIPBtn.TextSize = 25
VIPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VIPBtn.TextWrapped = true
VIPBtn.TextXAlignment = Enum.TextXAlignment.Center
VIPBtn.TextYAlignment = Enum.TextYAlignment.Center
VIPBtn.ZIndex = 102
Instance.new("UICorner", VIPBtn).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", VIPBtn).Thickness = 3
addHover(VIPBtn, vipOrigSize)

local vipGrad = Instance.new("UIGradient", VIPBtn)
vipGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0))
})
vipGrad.Rotation = 45

-- TŁO GreenStuds dla VIPBtn
local vipBg = Instance.new("ImageLabel", VIPBtn)
vipBg.Name = "VipBg"
vipBg.Size = UDim2.fromScale(1, 1)
vipBg.BackgroundTransparency = 1
vipBg.ZIndex = 102
if gs then vipBg.Image = (gs:IsA("Decal") and gs.Texture or gs.Image) end
vipBg.ImageColor3 = Color3.fromRGB(200, 150, 0)
vipBg.ImageTransparency = 0.6
vipBg.ScaleType = Enum.ScaleType.Tile
vipBg.TileSize = UDim2.fromOffset(128, 128)
Instance.new("UICorner", vipBg).CornerRadius = UDim.new(0, 15)


-- Przyciski mniejsze (Speed)
local SpeedBtn = Instance.new("TextButton", UpgradesFrame)
local speedOrigSize = UDim2.new(0.42, 0, 0.3, 0)
SpeedBtn.Size = speedOrigSize
SpeedBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpeedBtn.Text = "" 
SpeedBtn.Font = Enum.Font.LuckiestGuy
SpeedBtn.TextSize = 30
SpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBtn.ZIndex = 102
Instance.new("UICorner", SpeedBtn).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", SpeedBtn).Thickness = 2
addHover(SpeedBtn, speedOrigSize)

local speedGrad = Instance.new("UIGradient", SpeedBtn)
speedGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
})
speedGrad.Rotation = 90

local speedLabel = Instance.new("TextLabel", SpeedBtn)
speedLabel.Size = UDim2.fromScale(1, 1)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "\n\n2x SPEED"
speedLabel.Font = Enum.Font.LuckiestGuy
speedLabel.TextSize = 30
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.ZIndex = 110 
Instance.new("UIStroke", speedLabel).Thickness = 2

-- TŁO GreenStuds dla SpeedBtn
local speedBg = Instance.new("ImageLabel", SpeedBtn)
speedBg.Name = "SpeedBg"
speedBg.Size = UDim2.fromScale(1, 1)
speedBg.BackgroundTransparency = 1
speedBg.ZIndex = 102
if gs then speedBg.Image = (gs:IsA("Decal") and gs.Texture or gs.Image) end
speedBg.ImageColor3 = Color3.fromRGB(0, 150, 255)
speedBg.ImageTransparency = 0.7
speedBg.ScaleType = Enum.ScaleType.Tile
speedBg.TileSize = UDim2.fromOffset(128, 128)
Instance.new("UICorner", speedBg).CornerRadius = UDim.new(0, 15)

-- Miękki blask (Glow) pod ikonką Speed
local speedGlow = Instance.new("ImageLabel", SpeedBtn)
speedGlow.Name = "SpeedGlow"
speedGlow.Size = UDim2.fromOffset(120, 120)
speedGlow.Position = UDim2.new(0.5, 0, 0.35, 0)
speedGlow.AnchorPoint = Vector2.new(0.5, 0.5)
speedGlow.BackgroundTransparency = 1
speedGlow.Image = "rbxassetid://12030614838" 
speedGlow.ImageColor3 = Color3.fromRGB(0, 255, 255) 
speedGlow.ZIndex = 103

local speedIcon = Instance.new("ImageLabel", SpeedBtn)
speedIcon.Name = "FloatingIcon"
speedIcon.Size = UDim2.fromOffset(90, 90)
speedIcon.Position = UDim2.new(0.5, 0, 0.35, 0)
speedIcon.AnchorPoint = Vector2.new(0.5, 0.5)
speedIcon.BackgroundTransparency = 1
speedIcon.ImageColor3 = Color3.new(0, 0, 0) 
speedIcon.ZIndex = 104
local speedAsset = ReplicatedStorage:FindFirstChild("speed")
if speedAsset then speedIcon.Image = (speedAsset:IsA("Decal") and speedAsset.Texture or speedAsset.Image) end
table.insert(floatingElements, {obj = speedIcon, isCoin = false})


-- Przycisk Jump
local JumpBtn = Instance.new("TextButton", UpgradesFrame)
local jumpOrigSize = UDim2.new(0.42, 0, 0.3, 0)
JumpBtn.Size = jumpOrigSize
JumpBtn.Position = UDim2.new(0.53, 0, 0.65, 0)
JumpBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
JumpBtn.Text = "" 
JumpBtn.Font = Enum.Font.LuckiestGuy
JumpBtn.TextSize = 30
JumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpBtn.ZIndex = 102
Instance.new("UICorner", JumpBtn).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", JumpBtn).Thickness = 2
addHover(JumpBtn, jumpOrigSize)

local jumpGrad = Instance.new("UIGradient", JumpBtn)
jumpGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 50))
})
jumpGrad.Rotation = 90

local jumpLabel = Instance.new("TextLabel", JumpBtn)
jumpLabel.Size = UDim2.fromScale(1, 1)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "\n\n2x JUMP"
jumpLabel.Font = Enum.Font.LuckiestGuy
jumpLabel.TextSize = 30
jumpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpLabel.ZIndex = 110 
Instance.new("UIStroke", jumpLabel).Thickness = 2

-- TŁO GreenStuds dla JumpBtn
local jumpBg = Instance.new("ImageLabel", JumpBtn)
jumpBg.Name = "JumpBg"
jumpBg.Size = UDim2.fromScale(1, 1)
jumpBg.BackgroundTransparency = 1
jumpBg.ZIndex = 102
if gs then jumpBg.Image = (gs:IsA("Decal") and gs.Texture or gs.Image) end
jumpBg.ImageColor3 = Color3.fromRGB(0, 200, 50)
jumpBg.ImageTransparency = 0.7
jumpBg.ScaleType = Enum.ScaleType.Tile
jumpBg.TileSize = UDim2.fromOffset(128, 128)
Instance.new("UICorner", jumpBg).CornerRadius = UDim.new(0, 15)

-- Miękki blask (Glow) pod ikonką Jump
local jumpGlow = Instance.new("ImageLabel", JumpBtn)
jumpGlow.Name = "JumpGlow"
jumpGlow.Size = UDim2.fromOffset(120, 120)
jumpGlow.Position = UDim2.new(0.5, 0, 0.35, 0)
jumpGlow.AnchorPoint = Vector2.new(0.5, 0.5)
jumpGlow.BackgroundTransparency = 1
jumpGlow.Image = "rbxassetid://12030614838" 
jumpGlow.ImageColor3 = Color3.fromRGB(100, 255, 100) 
jumpGlow.ZIndex = 103

local jumpIcon = Instance.new("ImageLabel", JumpBtn)
jumpIcon.Name = "FloatingIcon"
jumpIcon.Size = UDim2.fromOffset(90, 90)
jumpIcon.Position = UDim2.new(0.5, 0, 0.35, 0)
jumpIcon.AnchorPoint = Vector2.new(0.5, 0.5)
jumpIcon.BackgroundTransparency = 1
jumpIcon.ImageColor3 = Color3.new(0, 0, 0) 
jumpIcon.ZIndex = 104
local jumpAsset = ReplicatedStorage:FindFirstChild("Jump")
if jumpAsset then jumpIcon.Image = (jumpAsset:IsA("Decal") and jumpAsset.Texture or jumpAsset.Image) end
table.insert(floatingElements, {obj = jumpIcon, isCoin = false})


VIPBtn.MouseButton1Click:Connect(function() MarketplaceService:PromptGamePassPurchase(player, GameConfig.GamePasses.VIPBundle) end)
SpeedBtn.MouseButton1Click:Connect(function() MarketplaceService:PromptGamePassPurchase(player, GameConfig.GamePasses.SpeedBoost) end)
JumpBtn.MouseButton1Click:Connect(function() MarketplaceService:PromptGamePassPurchase(player, GameConfig.GamePasses.JumpBoost) end)

-- Prawa Sekcja: Monety
local CoinsFrame = Instance.new("Frame", BoostPage)
CoinsFrame.Size = UDim2.new(0.48, 0, 0.9, 0)
CoinsFrame.Position = UDim2.new(0.51, 0, 0.05, 0)
CoinsFrame.BackgroundTransparency = 1
CoinsFrame.ZIndex = 102

local CoinsTitle = Instance.new("TextLabel", CoinsFrame)
CoinsTitle.Size = UDim2.new(1, 0, 0.1, 0)
CoinsTitle.Position = UDim2.new(0, 0, 0, 0)
CoinsTitle.Text = "BUY COINS"
CoinsTitle.Font = Enum.Font.LuckiestGuy
CoinsTitle.TextSize = 40
CoinsTitle.TextColor3 = Color3.fromRGB(255, 255, 0)
CoinsTitle.BackgroundTransparency = 1
CoinsTitle.ZIndex = 102
Instance.new("UIStroke", CoinsTitle).Thickness = 3

local coinsGradient = Instance.new("UIGradient", CoinsTitle)
coinsGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 0)), 
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 230, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 230, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 0)) 
})

local CoinsGrid = Instance.new("Frame", CoinsFrame)
CoinsGrid.Size = UDim2.new(0.9, 0, 0.85, 0)
CoinsGrid.Position = UDim2.new(0.05, 0, 0.15, 0)
CoinsGrid.BackgroundTransparency = 1
CoinsGrid.ZIndex = 102
local cLayout = Instance.new("UIGridLayout", CoinsGrid)
cLayout.CellSize = UDim2.new(0.45, 0, 0.45, 0)
cLayout.CellPadding = UDim2.new(0.05, 0, 0.05, 0)

local packsOrder = {"Pack100", "Pack250", "Pack500", "Pack1000"}
local scales = {0.3, 0.45, 0.6, 0.8}

for i, packKey in ipairs(packsOrder) do
	local packData = GameConfig.CoinPacks[packKey]
	
	-- Niewidzialna ramka komórki dla siatki UIGridLayout (pozwala na hover na dzieciach bez psucia siatki)
	local cellFrame = Instance.new("Frame", CoinsGrid)
	cellFrame.BackgroundTransparency = 1
	
	local btn = Instance.new("TextButton", cellFrame)
	btn.Size = UDim2.fromScale(1, 1)
	btn.Position = UDim2.fromScale(0.5, 0.5)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
	btn.Text = ""
	btn.ZIndex = 102
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 15)
	Instance.new("UIStroke", btn).Thickness = 3
	addHover(btn, UDim2.fromScale(1, 1))
	
	local packGrad = Instance.new("UIGradient", btn)
	packGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50))
	})
	packGrad.Rotation = 45
	
	-- TŁO GreenStuds dla kafelka monety
	local coinTileBg = Instance.new("ImageLabel", btn)
	coinTileBg.Name = "CoinTileBg"
	coinTileBg.Size = UDim2.fromScale(1, 1)
	coinTileBg.BackgroundTransparency = 1
	coinTileBg.ZIndex = 102
	if gs then coinTileBg.Image = (gs:IsA("Decal") and gs.Texture or gs.Image) end
	coinTileBg.ImageColor3 = Color3.fromRGB(255, 200, 0)
	coinTileBg.ImageTransparency = 0.7
	coinTileBg.ScaleType = Enum.ScaleType.Tile
	coinTileBg.TileSize = UDim2.fromOffset(128, 128)
	Instance.new("UICorner", coinTileBg).CornerRadius = UDim.new(0, 15)

	local icon = Instance.new("ImageLabel", btn)
	icon.Name = "FloatingCoin"
	local s = scales[i] or 0.5
	icon.Size = UDim2.fromScale(s, s)
	
	local yPos = 0.4
	local yOffset = 20
	icon.Position = UDim2.new(0.5, 0, yPos, yOffset)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.ZIndex = 103
	local coinAsset = ReplicatedStorage:FindFirstChild("Coin2D")
	if coinAsset then
		icon.Image = (coinAsset:IsA("Decal") and coinAsset.Texture or coinAsset.Image)
	else
		icon.Image = "rbxassetid://1350436906" 
	end
	table.insert(floatingElements, {obj = icon, isCoin = true})
	
	local amountLabel = Instance.new("TextLabel", btn)
	amountLabel.Size = UDim2.new(1, 0, 0.3, 0)
	amountLabel.Position = UDim2.new(0, 0, 0.6, 0)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = packData.Amount .. " COINS"
	amountLabel.Font = Enum.Font.LuckiestGuy
	amountLabel.TextSize = 25
	amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	amountLabel.ZIndex = 103
	Instance.new("UIStroke", amountLabel).Thickness = 2
	
	local priceLabel = Instance.new("TextLabel", btn)
	priceLabel.Size = UDim2.new(1, 0, 0.2, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.85, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = packData.Price .. " R$"
	priceLabel.Font = Enum.Font.SourceSansBold
	priceLabel.TextSize = 20
	priceLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	priceLabel.ZIndex = 103
	
	-- BEST VALUE Wstążka
	if packKey == "Pack1000" then
		local ribbon = Instance.new("TextLabel", btn)
		ribbon.Size = UDim2.new(0.8, 0, 0.25, 0)
		ribbon.Position = UDim2.new(0.8, 0, 0, 0)
		ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
		ribbon.Rotation = 15 
		ribbon.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		ribbon.Text = "BEST\nVALUE!"
		ribbon.Font = Enum.Font.LuckiestGuy
		ribbon.TextSize = 18
		ribbon.TextColor3 = Color3.fromRGB(255, 255, 255)
		ribbon.ZIndex = 105
		Instance.new("UICorner", ribbon).CornerRadius = UDim.new(0.2, 0)
		Instance.new("UIStroke", ribbon).Thickness = 2
	end

	btn.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, packData.ID)
	end)
end


local subTitle = Instance.new("TextLabel", BrainrotPage)
subTitle.Size = UDim2.new(0.9, 0, 0, 140) 
subTitle.Position = UDim2.new(0.5, 0, 0, -10) -- Podciągnięte lekko w górę wewnątrz strony
subTitle.AnchorPoint = Vector2.new(0.5, 0)
subTitle.BackgroundTransparency = 1
subTitle.Text = "MAXIMUM BRAINROTS AHEAD! SKIP THE SEARCH AND ROLL FOR THE ONES YOU'RE MISSING!"
subTitle.Font = Enum.Font.LuckiestGuy
subTitle.TextSize = 50
subTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subTitle.TextWrapped = true
subTitle.ZIndex = 106
Instance.new("UIStroke", subTitle).Thickness = 4

local subTitleGradient = Instance.new("UIGradient", subTitle)
subTitleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 0)), 
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 180, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 180, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0)) 
})

task.spawn(function()
	local offset = -1
	while true do
		offset = offset + 0.02
		if offset > 1 then offset = -1 end
		subTitleGradient.Offset = Vector2.new(offset, 0)
		if upgradesGradient then upgradesGradient.Offset = Vector2.new(offset, 0) end
		if coinsGradient then coinsGradient.Offset = Vector2.new(offset, 0) end
		task.wait(0.01)
	end
end)

local gridFrame = Instance.new("Frame", BrainrotPage)
gridFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
gridFrame.Position = UDim2.new(0.05, 0, 0.28, 0) -- Przesunięte w górę relatywnie do strony
gridFrame.BackgroundTransparency = 1
gridFrame.ZIndex = 101
local gridLayout = Instance.new("UIGridLayout", gridFrame)
gridLayout.CellSize = UDim2.new(0.23, 0, 0.45, 0)
gridLayout.CellPadding = UDim2.new(0.02, 0, 0.05, 0)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- === 3. GENEROWANIE KAFELKÓW ===
local rainbowLabels = {}
local secretLabels = {}
local scrollingContainers = {}
-- Usuwamy shopSpinningModels


local function refreshShop()
	for _, child in ipairs(gridFrame:GetChildren()) do if not child:IsA("UIGridLayout") then child:Destroy() end end
	rainbowLabels = {}
	secretLabels = {}
	scrollingContainers = {}



	for _, data in ipairs(CaseData) do
		local missing = getMissingItems(data.Name)
		local caseBtn = Instance.new("TextButton", gridFrame)
		caseBtn.BackgroundColor3 = Color3.fromRGB(120, 110, 150) -- Szary fioletowy
		caseBtn.Text = ""
		caseBtn.ZIndex = 102
		Instance.new("UICorner", caseBtn).CornerRadius = UDim.new(0, 15)
		
		-- TŁO GreenStuds dla kafelka
		local tileBg = Instance.new("ImageLabel", caseBtn)
		tileBg.Name = "TileBg"
		tileBg.Size = UDim2.fromScale(1, 1)
		tileBg.BackgroundTransparency = 1
		tileBg.ZIndex = 102
		if gs then tileBg.Image = gs:IsA("Decal") and gs.Texture or gs.Image end
		tileBg.ImageTransparency = 0.7 -- Widoczny wzorek
		tileBg.ScaleType = Enum.ScaleType.Tile
		tileBg.TileSize = UDim2.fromOffset(64, 64)
		Instance.new("UICorner", tileBg).CornerRadius = UDim.new(0, 15)

		local uiStroke = Instance.new("UIStroke", caseBtn)
		uiStroke.Thickness = 3
		uiStroke.Color = data.Color

		local nameLabel = Instance.new("TextLabel", caseBtn)
		nameLabel.Size = UDim2.new(1, 0, 0.22, 0) 
		nameLabel.Position = UDim2.fromScale(0, 0) -- Podciągnięte na samą górę
		nameLabel.Text = (#missing == 0 and "ALL COLLECTED!") or (data.Name .. "\nCHEST")
		if #missing == 0 then caseBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20) end
		nameLabel.TextColor3 = data.Color
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 32 -- Subtelniejsza czcionka
		nameLabel.TextScaled = true
		nameLabel.BackgroundTransparency = 1
		nameLabel.ZIndex = 104

		if data.Name == "BRAINROT GOD" then table.insert(rainbowLabels, {Label = nameLabel, Stroke = uiStroke}) end
		if data.Name == "SECRET" then table.insert(secretLabels, {Label = nameLabel, Stroke = uiStroke}) end

		-- DOPRACOWANY OBSZAR WYŚWIETLANIA (Podniesiony, by nie zasłaniać R$)
		local clipFrame = Instance.new("Frame", caseBtn)
		clipFrame.Size = UDim2.new(0.95, 0, 0.60, 0) -- Skrócone z 0.68
		clipFrame.Position = UDim2.new(0.025, 0, 0.22, 0) -- Zaraz pod nazwą
		clipFrame.BackgroundTransparency = 1
		clipFrame.ClipsDescendants = true
		clipFrame.ZIndex = 105

		local scrollingContent = Instance.new("Frame", clipFrame)
		scrollingContent.Size = UDim2.new(0, 0, 1, 0)
		scrollingContent.BackgroundTransparency = 1
		scrollingContent.ZIndex = 105
		local layout = Instance.new("UIListLayout", scrollingContent)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 15)
		if data.Name == "OG" then layout.HorizontalAlignment = Enum.HorizontalAlignment.Center end

		if #missing > 0 then
			local itemWidth = 100 -- Zwiększone z 85 dla większej swobody
			local prob = (math.floor((100/#missing)*10)/10)
			local loops = (data.Name == "OG") and 1 or 3

			for j = 1, loops do
				for _, modelObj in ipairs(missing) do
					local itemFrame = Instance.new("Frame", scrollingContent)
					itemFrame.Size = UDim2.new(0, itemWidth, 1, 0)
					itemFrame.BackgroundTransparency = 1

					local vpSize = (data.Name == "OG") and 3.1 or 1.7 -- Ostateczna skala OG (+20%)
					local vpPos = (1 - vpSize) / 2 - 0.05 -- Podniesione wyżej wewnątrz ramki
					
					
					local vp = Instance.new("ViewportFrame", itemFrame)
					vp.Size = UDim2.fromScale(vpSize, vpSize)
					vp.Position = UDim2.fromScale(vpPos, vpPos)
					vp.BackgroundTransparency = 1
					vp.ZIndex = 106
					
					-- LEPSZE OŚWIETLENIE
					vp.Ambient = Color3.fromRGB(150, 150, 150)
					vp.LightColor = Color3.fromRGB(255, 255, 255)
					vp.LightDirection = Vector3.new(-1, -1, -0.5)

					-- TŁO (GLOW) DLA MODELU
					local modelGlow = Instance.new("ImageLabel", itemFrame)
					modelGlow.Name = "ModelGlow"
					modelGlow.Size = UDim2.fromScale(0.8, 0.8)
					modelGlow.Position = UDim2.fromScale(0.5, 0.5)
					modelGlow.AnchorPoint = Vector2.new(0.5, 0.5)
					modelGlow.BackgroundTransparency = 1
					modelGlow.Image = "rbxassetid://12030614838"
					modelGlow.ImageColor3 = data.Color
					modelGlow.ImageTransparency = 0.6
					modelGlow.ZIndex = 105

					local cl = modelObj:Clone()
					cl.Parent = vp
					local cf, size = cl:GetBoundingBox()
					local offset = cf:Inverse()
					for _, p in ipairs(cl:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = offset * p.CFrame end end

					local cam = Instance.new("Camera", vp)
					vp.CurrentCamera = cam
					-- ODDALENIE OBIEKTYWU (z 0.9 na 1.8 dla mniejszych zniekształceń perspektywy)
					local dist = math.max(size.X, size.Y, size.Z) * 1.8 
					-- Statyczna, ładna pozycja kamery (IDEALNIE Z PRZODU, NA WYSOKOŚCI ŚRODKA)
					cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, -dist), Vector3.new(0, 0, 0))



					local pl = Instance.new("TextLabel", itemFrame)
					pl.Size = UDim2.new(1, 0, 0.25, 0)
					pl.Position = UDim2.fromScale(0, 0.78)
					pl.Text = prob.."%"
					pl.TextColor3 = Color3.new(1,1,1)
					pl.TextScaled = true
					pl.BackgroundTransparency = 1
					pl.ZIndex = 107
					Instance.new("UIStroke", pl).Thickness = 2 -- Mocniejszy obrys
				end
			end
			if data.Name ~= "OG" then
				table.insert(scrollingContainers, {Frame = scrollingContent, Width = (#missing * itemWidth) + (#missing * 15)})
			else
				scrollingContent.Size = UDim2.fromScale(1, 1)
			end
		end

		local priceLabel = Instance.new("TextLabel", caseBtn)
		priceLabel.Size = UDim2.new(1, 0, 0, 40)
		priceLabel.Position = UDim2.new(0, 0, 1, -40)
		priceLabel.Text = "..."
		priceLabel.TextColor3 = Color3.new(1, 1, 1)
		priceLabel.Font = Enum.Font.SourceSansBold
		priceLabel.TextSize = 28
		priceLabel.BackgroundTransparency = 1
		priceLabel.ZIndex = 104

		task.spawn(function()
			local success, info = pcall(function() return MarketplaceService:GetProductInfo(data.ID, Enum.InfoType.Product) end)
			if success and info then priceLabel.Text = info.PriceInRobux .. " R$" end
		end)

		caseBtn.MouseButton1Click:Connect(function()
			local currentMissing = getMissingItems(data.Name)
			if #currentMissing == 0 then return end
			shopContainer.Visible = false
			closeButton.Visible = false
			local hudGui = playerGui:FindFirstChild("HUD_Standalone_UI")
			if hudGui then hudGui.Enabled = true end
			MarketplaceService:PromptProductPurchase(player, data.ID)
		end)
	end
end

-- === 4. ANIMACJE ===
RunService.RenderStepped:Connect(function()
	local t = tick()
	local rainbow = Color3.fromHSV(t % 3 / 3, 1, 1)
	local activeTab = BrainrotPage.Visible and TabBrainrot or TabBoosts
	activeTab.TextColor3 = rainbow
	btnText.TextColor3 = HudTileStyle.BaseLabelColor

	for _, data in pairs(scrollingContainers) do
		local offset = (t * 50) % data.Width
		data.Frame.Position = UDim2.new(0, -offset, 0, 0)
	end

	for _, item in pairs(rainbowLabels) do
		item.Label.TextColor3 = rainbow
		item.Stroke.Color = rainbow
	end
	local shine = (math.sin(t * 5) + 1) / 2
	local silver = Color3.new(0.5 + shine*0.5, 0.5 + shine*0.5, 0.5 + shine*0.5)
	for _, item in pairs(secretLabels) do
		item.Label.TextColor3 = silver
		item.Stroke.Color = silver
	end
	
	-- Pływające Ikonki w Boost Shop
	local floatOffset = math.sin(t * 3) * 5
	for _, data in ipairs(floatingElements) do
		if not data.isCoin then
			data.obj.Position = UDim2.new(0.5, 0, 0.35, floatOffset)
		else
			data.obj.Position = UDim2.new(0.5, 0, 0.4, 20 + floatOffset)
		end
	end
end)



local function toggleShop()
	local isVisible = not shopContainer.Visible
	if isVisible then refreshShop() end
	shopContainer.Visible = isVisible
	closeButton.Visible = isVisible
	
	local hudGui = playerGui:FindFirstChild("HUD_Standalone_UI")
	if hudGui then hudGui.Enabled = not isVisible end
end

mainBtn.MouseButton1Click:Connect(toggleShop)
closeButton.MouseButton1Click:Connect(toggleShop)

-- 5. LOGIKA PRZEŁĄCZANIA ZAKŁADEK
local function showBrainrot()
	BrainrotPage.Visible = true
	BoostPage.Visible = false
	TabBrainrot.TextColor3 = Color3.fromRGB(255, 0, 255)
	TabBrainrot.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	TabBrainrot.BackgroundTransparency = 0
	
	TabBoosts.TextColor3 = Color3.fromRGB(150, 150, 150)
	TabBoosts.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	TabBoosts.BackgroundTransparency = 0.4
end

local function showBoosts()
	BrainrotPage.Visible = false
	BoostPage.Visible = true
	TabBoosts.TextColor3 = Color3.fromRGB(255, 0, 255)
	TabBoosts.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	TabBoosts.BackgroundTransparency = 0
	
	TabBrainrot.TextColor3 = Color3.fromRGB(150, 150, 150)
	TabBrainrot.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	TabBrainrot.BackgroundTransparency = 0.4
end

TabBrainrot.MouseButton1Click:Connect(showBrainrot)
TabBoosts.MouseButton1Click:Connect(showBoosts)

-- === 6. TEXTCHATSERVICE [VIP] TAG LOGIC ===
local TextChatService = game:GetService("TextChatService")

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	TextChatService.OnIncomingMessage = function(message)
		local props = Instance.new("TextChatMessageProperties")
		
		if message.TextSource then
			local p = Players:GetPlayerByUserId(message.TextSource.UserId)
			if p and p:GetAttribute("HasVIP") then
				props.PrefixText = "<font color='#FFD700'><b>[VIP]</b></font> " .. (message.PrefixText or "")
			end
		end
		
		return props
	end
end