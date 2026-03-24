local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local CaseData = {
	{Name = "COMMON", ID = 3558948736, Color = Color3.fromRGB(163, 162, 165)},
	{Name = "RARE", ID = 3558948814, Color = Color3.fromRGB(64, 255, 71)},
	{Name = "EPIC", ID = 3558949097, Color = Color3.fromRGB(180, 71, 255)},
	{Name = "LEGENDARY", ID = 3558949533, Color = Color3.fromRGB(255, 145, 0)},
	{Name = "MYTHIC", ID = 3558950075, Color = Color3.fromRGB(255, 33, 33)},
	{Name = "BRAINROT GOD", ID = 3558950464, Color = Color3.fromRGB(0, 255, 255)},
	{Name = "SECRET", ID = 3558950670, Color = Color3.fromRGB(150, 150, 150)},
	{Name = "OG", ID = 3558951376, Color = Color3.fromRGB(0, 255, 255)},
}

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
glowEffect.BackgroundTransparency = 1
glowEffect.Image = "rbxassetid://12030614838"
glowEffect.ImageColor3 = Color3.fromRGB(40, 180, 40)
glowEffect.Size = UDim2.fromOffset(250, 250)
glowEffect.Position = UDim2.new(0, 110, 0.5, 0) 
glowEffect.AnchorPoint = Vector2.new(0.5, 0.5)
glowEffect.ZIndex = 60

local mainBtn = Instance.new("TextButton", screenGui)
mainBtn.Name = "MainShopButton"
mainBtn.Size = UDim2.fromOffset(210, 210)
mainBtn.Position = UDim2.new(0, 110, 0.5, 0) 
mainBtn.AnchorPoint = Vector2.new(0.5, 0.5)
mainBtn.BackgroundTransparency = 1
mainBtn.Text = ""
mainBtn.ZIndex = 61

local btnImg = Instance.new("ImageLabel", mainBtn)
btnImg.Size = UDim2.fromScale(0.8, 0.8)
btnImg.Position = UDim2.fromScale(0.5, 0.45)
btnImg.AnchorPoint = Vector2.new(0.5, 0.5)
btnImg.BackgroundTransparency = 1
btnImg.Image = "rbxassetid://86015085773572"
btnImg.ZIndex = 62

local btnText = Instance.new("TextLabel", mainBtn)
btnText.Size = UDim2.new(1, 0, 0, 40)
btnText.Position = UDim2.new(0, 0, 0.8, 0)
btnText.BackgroundTransparency = 1
btnText.Text = "GET BRAINROT"
btnText.Font = Enum.Font.LuckiestGuy
btnText.TextSize = 25
btnText.ZIndex = 63
Instance.new("UIStroke", btnText).Thickness = 2

local shopContainer = Instance.new("Frame", screenGui)
shopContainer.Size = UDim2.fromScale(0.8, 0.8)
shopContainer.Position = UDim2.fromScale(0.5, 0.5)
shopContainer.AnchorPoint = Vector2.new(0.5, 0.5)
shopContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
shopContainer.Visible = false
shopContainer.ZIndex = 100
Instance.new("UICorner", shopContainer).CornerRadius = UDim.new(0, 20)
Instance.new("UIStroke", shopContainer).Thickness = 4

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

local title = Instance.new("TextLabel", shopContainer)
title.Size = UDim2.new(1, 0, 0, 80)
title.Position = UDim2.new(0, 0, 0, 15)
title.BackgroundTransparency = 1
title.Text = "BRAINROT SHOP"
title.Font = Enum.Font.LuckiestGuy
title.TextSize = 70
title.ZIndex = 105
title.TextColor3 = Color3.new(1, 1, 1)

local subTitle = Instance.new("TextLabel", shopContainer)
subTitle.Size = UDim2.new(0.9, 0, 0, 140) 
subTitle.Position = UDim2.new(0.5, 0, 0, 90) 
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
		task.wait(0.01)
	end
end)

local gridFrame = Instance.new("Frame", shopContainer)
gridFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
gridFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
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
		caseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		caseBtn.Text = ""
		caseBtn.ZIndex = 102
		Instance.new("UICorner", caseBtn).CornerRadius = UDim.new(0, 15)
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
	local pulse = (math.sin(t * 4) + 1) / 2
	glowEffect.Size = UDim2.fromOffset(230 + (pulse * 60), 230 + (pulse * 60))
	mainBtn.Size = UDim2.fromOffset(210 + (pulse * 15), 210 + (pulse * 15))
	title.TextColor3 = rainbow
	btnText.TextColor3 = rainbow

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