local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollAnnouncement = BrainrotEvents:WaitForChild("TrollAnnouncement")
local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

local gui = Instance.new("ScreenGui")
gui.Name = "TrollCountdownUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100 -- Zawsze na wierzchu, nawet nad questami i rebirthami
gui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(1, 0, 0.5, 0)
container.Position = UDim2.new(0, 0, 0, 70) -- Pod paskiem roboxów
container.BackgroundTransparency = 1
container.Parent = gui

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = container
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 10)

-- Dźwięk pikania (Tylko dla kupującego i ofiary)
local beepSound = Instance.new("Sound")
beepSound.SoundId = "rbxassetid://12221967" -- Krótkie popularne piknięcie/click
beepSound.Volume = 1
beepSound.Parent = gui

local goSound = Instance.new("Sound")
goSound.SoundId = "rbxassetid://4590662766" -- Impact / GO sound
goSound.Volume = 2
goSound.Parent = gui

local function applyGuiLayer(metrics)
	gui.DisplayOrder = metrics.displayOrder or 100
	container.Position = UDim2.new(0, 0, 0, metrics.containerTop or 70)
end

local function getCountdownMetrics()
	local layoutMetrics = HudTileStyle.getLayoutMetrics()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

	if layoutMetrics.IsLandscapeMobile then
		return {
			frameSize = UDim2.fromOffset(math.clamp(math.floor(viewport.X * 0.82), 380, 520), math.clamp(math.floor(viewport.Y * 0.11), 40, 44)),
			cornerRadius = UDim.new(0, 10),
			strokeThickness = 1.8,
			textSize = 17,
			textScaled = true,
			minTextSize = 11,
			maxTextSize = 17,
			countdownTextSize = 26,
			goTextSize = 28,
			padding = UDim.new(0, 8),
			backgroundTransparency = 0.16,
			containerTop = -14,
			displayOrder = 760,
		}
	elseif layoutMetrics.IsMobile then
		return {
			frameSize = UDim2.fromOffset(math.clamp(math.floor(viewport.X * 0.9), 460, 680), math.clamp(math.floor(viewport.Y * 0.1), 48, 54)),
			cornerRadius = UDim.new(0, 10),
			strokeThickness = 2,
			textSize = 22,
			textScaled = true,
			minTextSize = 12,
			maxTextSize = 22,
			countdownTextSize = 32,
			goTextSize = 36,
			padding = UDim.new(0, 10),
			backgroundTransparency = 0.18,
			containerTop = 60,
			displayOrder = 760,
		}
	end

	return {
		frameSize = UDim2.new(0, 600, 0, 50),
		cornerRadius = UDim.new(0, 8),
		strokeThickness = 2,
		textSize = 24,
		textScaled = false,
		minTextSize = 14,
		maxTextSize = 24,
		countdownTextSize = 36,
		goTextSize = 40,
		padding = UDim.new(0, 10),
		backgroundTransparency = 0.2,
		containerTop = 70,
		displayOrder = 100,
	}
end

local colorMap = {
	Bomb = Color3.fromRGB(200, 0, 0),
	Lava = Color3.fromRGB(255, 100, 0),
	Tornado = Color3.fromRGB(150, 150, 255),
	Fart = Color3.fromRGB(100, 255, 100)
}

TrollAnnouncement.OnClientEvent:Connect(function(buyerName, targetName, trollType)
	-- Sprawdzamy czy LocalPlayer jest zaangażowany w tego konkretnego trolla
	local isParticipant = (player.Name == buyerName or player.Name == targetName)
	local countdownMetrics = getCountdownMetrics()
	listLayout.Padding = countdownMetrics.padding
	applyGuiLayer(countdownMetrics)
	
	local frame = Instance.new("Frame")
	frame.Name = "CountdownFrame"
	frame.Size = countdownMetrics.frameSize
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = countdownMetrics.backgroundTransparency
	frame.ClipsDescendants = true
	frame.ZIndex = 10
	frame.Parent = container
	
	Instance.new("UICorner", frame).CornerRadius = countdownMetrics.cornerRadius
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = colorMap[trollType] or Color3.fromRGB(255, 255, 0)
	stroke.Thickness = countdownMetrics.strokeThickness
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextSize = countdownMetrics.textSize
	textLabel.TextScaled = countdownMetrics.textScaled
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.RichText = true
	textLabel.ZIndex = 11
	textLabel.Parent = frame
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MinTextSize = countdownMetrics.minTextSize
	textConstraint.MaxTextSize = countdownMetrics.maxTextSize
	textConstraint.Parent = textLabel
	
	-- Składanie tekstu i kolorowanie typu trollingu
	local trollColorHex = string.format("#%02X%02X%02X", stroke.Color.R * 255, stroke.Color.G * 255, stroke.Color.B * 255)
	local prefix = string.format("<b>%s</b> attacks <b>%s</b> (<font color='%s'>%s</font>):  ", buyerName, targetName, trollColorHex, string.upper(trollType))
	
	task.spawn(function()
		-- 1. Animacja wlotu nowej belki na listę
		frame.Size = UDim2.fromOffset(0, countdownMetrics.frameSize.Y.Offset)
		frame.BackgroundTransparency = 1
		textLabel.TextTransparency = 1
		
		TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = countdownMetrics.frameSize, BackgroundTransparency = countdownMetrics.backgroundTransparency}):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
		
		-- 2. Odliczanie z pulsem
		for i = 5, 1, -1 do
			if isParticipant then
				beepSound:Play()
			end
			
			textLabel.Text = prefix .. "<font size='" .. countdownMetrics.countdownTextSize .. "' color='#FF0000'><b>" .. i .. "</b></font>"
			
			-- Bicie serca (Puls obwódki)
			local tw = TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Thickness = countdownMetrics.strokeThickness + 2.5})
			tw:Play()
			
			task.wait(1)
		end
		
		-- 3. Akcja! (GO!)
		if isParticipant then
			goSound:Play()
		end
		
		textLabel.Text = prefix .. "<font size='" .. countdownMetrics.goTextSize .. "' color='#00FF00'>!! GO !!</font>"
		TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = stroke.Color, BackgroundTransparency = 0.5}):Play()
		
		-- Chwila ekspozycji
		task.wait(1.5)
		
		-- 4. Animacja znikania
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, countdownMetrics.frameSize.Y.Offset), BackgroundTransparency = 1}):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
		
		task.wait(0.3)
		frame:Destroy()
	end)
end)
