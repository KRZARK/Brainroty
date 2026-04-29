local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

-- Sprawdzenie czy gracz już kupił starter pack
if LocalPlayer:GetAttribute("HasBoughtStarterPack") == true then
	return -- Wyjdź i nie twórz GUI
end

local oldGui = PlayerGui:FindFirstChild("StarterPackGui")
if oldGui then oldGui:Destroy() end

local oldToggle = PlayerGui:FindFirstChild("StarterPackToggleUI")
if oldToggle then oldToggle:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarterPackGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local StarterIcon = ReplicatedStorage:WaitForChild("Starterpack", 3)

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "StarterPackToggleUI"
ToggleGui.DisplayOrder = 200
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = PlayerGui

local openBtn = Instance.new("ImageButton")
openBtn.Name = "OpenStarterPackBtn"
openBtn.Parent = ToggleGui

local iconLabel = Instance.new("ImageLabel")
iconLabel.Name = "StarterIcon"
iconLabel.Image = StarterIcon and (StarterIcon:IsA("Decal") and StarterIcon.Texture or StarterIcon.Image) or "rbxassetid://10672027202"
iconLabel.Parent = openBtn

local textLabel = Instance.new("TextLabel")
textLabel.Text = "STARTERPACK"
textLabel.Parent = openBtn

HudTileStyle.apply(openBtn, iconLabel, textLabel, {
	side = "left",
	slotIndex = 2,
	zIndex = 50,
	minTextSize = 8,
	maxTextSize = 12,
})

local mobileTimerBadge = Instance.new("TextLabel")
mobileTimerBadge.Name = "MobileTimerBadge"
mobileTimerBadge.Size = UDim2.new(0.88, 0, 0, 12)
mobileTimerBadge.AnchorPoint = Vector2.new(0.5, 0.5)
mobileTimerBadge.Position = UDim2.new(0.5, 0, 0.57, 0)
mobileTimerBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 29)
mobileTimerBadge.BackgroundTransparency = 0.12
mobileTimerBadge.Text = ""
mobileTimerBadge.TextColor3 = Color3.new(1, 1, 1)
mobileTimerBadge.Font = Enum.Font.FredokaOne
mobileTimerBadge.TextSize = 9
mobileTimerBadge.Visible = false
mobileTimerBadge.ZIndex = 53
mobileTimerBadge.Parent = openBtn

local mobileTimerCorner = Instance.new("UICorner")
mobileTimerCorner.CornerRadius = UDim.new(0, 5)
mobileTimerCorner.Parent = mobileTimerBadge

local mobileTimerStroke = Instance.new("UIStroke")
mobileTimerStroke.Thickness = 1
mobileTimerStroke.Color = Color3.new(0, 0, 0)
mobileTimerStroke.Parent = mobileTimerBadge

-- Main Frame (Center)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 450)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Białe, żeby nie przyciemniało gradientu
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(200, 150, 255)
stroke.Thickness = 4
stroke.Parent = mainFrame

-- Gradient do tła
local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 180)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 200, 110))
})
mainGradient.Rotation = 90
mainGradient.Parent = mainFrame

local GreenStuds = ReplicatedStorage:WaitForChild("GreenStuds", 5)
if GreenStuds then
	local bgTexture = Instance.new("ImageLabel")
	bgTexture.Name = "BgTexture"
	bgTexture.Size = UDim2.new(1, 0, 1, 0)
	bgTexture.BackgroundTransparency = 1
	bgTexture.Image = GreenStuds:IsA("Decal") and GreenStuds.Texture or GreenStuds.Image
	bgTexture.ImageColor3 = Color3.fromRGB(250, 240, 180) -- Bladozłoty
	bgTexture.ImageTransparency = 0.8
	bgTexture.ScaleType = Enum.ScaleType.Tile
	bgTexture.TileSize = UDim2.new(0, 150, 0, 150)
	bgTexture.ZIndex = 0
	
	local uiCornerTex = Instance.new("UICorner")
	uiCornerTex.CornerRadius = UDim.new(0, 15)
	uiCornerTex.Parent = bgTexture
	
	bgTexture.Parent = mainFrame
end

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 25
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Tytuł
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Text = "STARTER PACK!"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Złoty kolor
titleLabel.TextSize = 50
titleLabel.TextStrokeColor3 = Color3.fromRGB(100, 50, 0)
titleLabel.TextStrokeTransparency = 0
titleLabel.Parent = mainFrame

-- Countdown Timer UI
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0, 30)
timerLabel.Position = UDim2.new(0, 0, 0, 55)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = "Ends in: 23:59:59"
timerLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
timerLabel.TextSize = 22
timerLabel.Parent = mainFrame

-- Kontener dla zawartości (Kafelki)
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -40, 0, 210)
contentContainer.Position = UDim2.new(0, 20, 0, 100)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local itemsList = Instance.new("UIListLayout")
itemsList.Padding = UDim.new(0, 10)
itemsList.FillDirection = Enum.FillDirection.Horizontal
itemsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
itemsList.SortOrder = Enum.SortOrder.LayoutOrder
itemsList.VerticalAlignment = Enum.VerticalAlignment.Center
itemsList.Parent = contentContainer

local function createFeatureTile(iconName, topText, bottomText, order, iconSize)
	local sizeVal = iconSize or 120
	local tile = Instance.new("Frame")
	tile.Size = UDim2.new(0, 140, 0, 210)
	tile.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
	tile.LayoutOrder = order
	tile.Parent = contentContainer
	
	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 12)
	tCorner.Parent = tile
	
	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(180, 140, 255)
	tStroke.Transparency = 0.2
	tStroke.Thickness = 2
	tStroke.Parent = tile
	
	local imgObj = ReplicatedStorage:WaitForChild(iconName, 3)
	
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, sizeVal, 0, sizeVal)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0, 65)
	icon.BackgroundTransparency = 1
	icon.Image = imgObj and (imgObj:IsA("Decal") and imgObj.Texture or imgObj.Image) or ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = tile
	
	local topLbl = Instance.new("TextLabel")
	topLbl.Size = UDim2.new(1, -10, 0, 25)
	topLbl.Position = UDim2.new(0, 5, 0, 140)
	topLbl.BackgroundTransparency = 1
	topLbl.Font = Enum.Font.FredokaOne
	topLbl.Text = topText
	topLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	topLbl.TextSize = 22
	topLbl.TextScaled = true
	topLbl.Parent = tile
	
	local botLbl = Instance.new("TextLabel")
	botLbl.Size = UDim2.new(1, -10, 0, 35)
	botLbl.Position = UDim2.new(0, 5, 0, 165)
	botLbl.BackgroundTransparency = 1
	botLbl.Font = Enum.Font.GothamBold
	botLbl.Text = bottomText
	botLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	botLbl.TextSize = 16
	botLbl.TextScaled = true
	botLbl.TextWrapped = true
	botLbl.Parent = tile
end

createFeatureTile("Coin2D", "1000", "Coins", 1, 90)
createFeatureTile("Fart", "3x", "Free Fart Troll", 2, 255)
createFeatureTile("Chest", "100%", "Secret Brainrot", 3, 255)

-- Purchase Button
local buyBtn = Instance.new("TextButton")
buyBtn.Name = "BuyButton"
buyBtn.Size = UDim2.new(0, 300, 0, 70)
buyBtn.Position = UDim2.new(0.5, -150, 1, -100)
buyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
buyBtn.Text = "" 
buyBtn.Parent = mainFrame

local buyLayout = Instance.new("UIListLayout")
buyLayout.FillDirection = Enum.FillDirection.Horizontal
buyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buyLayout.Padding = UDim.new(0, 5)
buyLayout.SortOrder = Enum.SortOrder.LayoutOrder
buyLayout.Parent = buyBtn

local buyBtnText = Instance.new("TextLabel")
buyBtnText.BackgroundTransparency = 1
buyBtnText.Font = Enum.Font.FredokaOne
buyBtnText.TextSize = 35
buyBtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
buyBtnText.TextStrokeColor3 = Color3.fromRGB(0, 100, 0)
buyBtnText.TextStrokeTransparency = 0
buyBtnText.AutomaticSize = Enum.AutomaticSize.XY
buyBtnText.LayoutOrder = 1
buyBtnText.Text = "LOADING..."
buyBtnText.Parent = buyBtn

local robuxIcon = Instance.new("ImageLabel")
robuxIcon.Size = UDim2.fromOffset(30, 30)
robuxIcon.BackgroundTransparency = 1
robuxIcon.Image = "rbxasset://textures/ui/common/robux_small.png"
robuxIcon.LayoutOrder = 2
robuxIcon.Visible = false
robuxIcon.Parent = buyBtn

task.spawn(function()
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(GameConfig.StarterPack.ProductID, Enum.InfoType.Product)
	end)
	if success and info and info.PriceInRobux then
		buyBtnText.Text = "BUY FOR " .. info.PriceInRobux
		robuxIcon.Visible = true
	else
		buyBtnText.Text = "BUY FOR " .. tonumber(GameConfig.StarterPack.Price)
		robuxIcon.Visible = true
	end
end)

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 15)
buyCorner.Parent = buyBtn

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 240, 120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 40))
})
btnGradient.Rotation = 90
btnGradient.Parent = buyBtn

-- Pulse element for buy button
local pulseTween
task.spawn(function()
	while task.wait(1.5) do
		if not buyBtn.Parent then break end
		local ts = TweenService:Create(buyBtn, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Size = UDim2.new(0, 320, 0, 75),
			Position = UDim2.new(0.5, -160, 1, -102)
		})
		ts:Play()
		pulseTween = ts
		break
	end
end)

buyBtn.MouseEnter:Connect(function()
	buyBtn.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
end)

buyBtn.MouseLeave:Connect(function()
	buyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
end)

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = mainFrame

local starterPackLayoutScale = 1
local starterPackAnimationScale = 1
local starterPackAnimationValue = Instance.new("NumberValue")
starterPackAnimationValue.Name = "StarterPackAnimationScale"
starterPackAnimationValue.Value = 1

local function applyStarterPackScale()
	uiScale.Scale = starterPackLayoutScale * starterPackAnimationScale
end

starterPackAnimationValue:GetPropertyChangedSignal("Value"):Connect(function()
	starterPackAnimationScale = starterPackAnimationValue.Value
	applyStarterPackScale()
end)

local function updateStarterPackLayout()
	local scale, _, _, isLandscapeMobile = HudTileStyle.getResponsivePanelScale(500, 450, {
		landscapeWidthRatio = 0.86,
		landscapeHeightRatio = 0.9,
		landscapeContentWidthRatio = 1.24,
		landscapeContentHeightRatio = 1.6,
		portraitWidthRatio = 0.94,
		portraitHeightRatio = 0.8,
		landscapeMinScale = 0.48,
		portraitMinScale = 0.62,
	})
	if isLandscapeMobile then
		scale *= 0.9
	end
	starterPackLayoutScale = scale
	applyStarterPackScale()
end

-- Main Logic
local hasAutoOpened = false

local function closeStarterPack()
	if not mainFrame.Visible then return end
	local tween = TweenService:Create(starterPackAnimationValue, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Value = 0 })
	tween:Play()
	TweenService:Create(openBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	tween.Completed:Wait()
	mainFrame.Visible = false
end

_G.UiMenus = _G.UiMenus or {}
_G.UiMenus["StarterPack"] = closeStarterPack

local function openStarterPack()
	for name, closeFunc in pairs(_G.UiMenus) do
		if name ~= "StarterPack" then closeFunc() end
	end
	
	TweenService:Create(openBtn, TweenInfo.new(0.2), {Rotation = -15}):Play()
	starterPackAnimationValue.Value = 0.5
	mainFrame.Visible = true
	TweenService:Create(starterPackAnimationValue, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Value = 1
	}):Play()
end

openBtn.MouseButton1Click:Connect(function()
	hasAutoOpened = true -- Jeśli gracz sam otworzy, możemy uznać że nie musimy go atakować popupem, choć można to pominąć.
	openStarterPack()
end)

-- Auto popup po 5 minutach
task.delay(300, function()
	if not hasAutoOpened and not mainFrame.Visible and LocalPlayer:GetAttribute("HasBoughtStarterPack") ~= true then
		hasAutoOpened = true
		openStarterPack()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	local tween = TweenService:Create(starterPackAnimationValue, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Value = 0
	})
	tween:Play()
	TweenService:Create(openBtn, TweenInfo.new(0.2), {Rotation = 0}):Play()
	tween.Completed:Wait()
	mainFrame.Visible = false
end)

-- Prompt Purchase
buyBtn.MouseButton1Click:Connect(function()
	MarketplaceService:PromptProductPurchase(LocalPlayer, GameConfig.StarterPack.ProductID)
end)

-- Ukrywanie GUI po zakupie przez zjawisko aktualizacji atrybutu
LocalPlayer:GetAttributeChangedSignal("HasBoughtStarterPack"):Connect(function()
	if LocalPlayer:GetAttribute("HasBoughtStarterPack") == true then
		screenGui:Destroy()
		ToggleGui:Destroy()
	end
end)

-- Odliczanie 24 godzin
task.spawn(function()
	while task.wait(1) do
		if not screenGui.Parent then break end
		
		local expiry = LocalPlayer:GetAttribute("StarterPackExpiry")
		if expiry then
			local timeLeft = expiry - os.time()
			if timeLeft <= 0 then
				screenGui:Destroy()
				ToggleGui:Destroy()
				break
			else
				local h = math.floor(timeLeft / 3600)
				local m = math.floor((timeLeft % 3600) / 60)
				local s = timeLeft % 60
				
				local timeString = string.format("%02d:%02d:%02d", h, m, s)
				timerLabel.Text = "Ends in: " .. timeString
				if HudTileStyle.getLayoutMetrics().IsMobile then
					textLabel.Text = "STARTERPACK"
					mobileTimerBadge.Text = timeString
					mobileTimerBadge.Visible = true
				else
					textLabel.Text = "STARTERPACK\n" .. timeString
					mobileTimerBadge.Visible = false
				end
			end
		end
	end
end)

-- Funkcjonalnosc w zaleznosci od skalowania MainFrame (Roblox GuiObject.Size używany jako Scale)
mainFrame.Size = UDim2.new(0, 500, 0, 450)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
updateStarterPackLayout()

local function bindStarterPackCamera(camera)
	if not camera then
		return
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateStarterPackLayout)
end

bindStarterPackCamera(Workspace.CurrentCamera)
mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateStarterPackLayout)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindStarterPackCamera(Workspace.CurrentCamera)
	updateStarterPackLayout()
	task.defer(updateStarterPackLayout)
end)
task.defer(updateStarterPackLayout)
task.delay(0.2, updateStarterPackLayout)
task.delay(1, updateStarterPackLayout)
