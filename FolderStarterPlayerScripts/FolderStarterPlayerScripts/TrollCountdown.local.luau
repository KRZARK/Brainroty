local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollAnnouncement = BrainrotEvents:WaitForChild("TrollAnnouncement")

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

local colorMap = {
	Bomb = Color3.fromRGB(200, 0, 0),
	Lava = Color3.fromRGB(255, 100, 0),
	Tornado = Color3.fromRGB(150, 150, 255),
	Fart = Color3.fromRGB(100, 255, 100)
}

TrollAnnouncement.OnClientEvent:Connect(function(buyerName, targetName, trollType)
	-- Sprawdzamy czy LocalPlayer jest zaangażowany w tego konkretnego trolla
	local isParticipant = (player.Name == buyerName or player.Name == targetName)
	
	local frame = Instance.new("Frame")
	frame.Name = "CountdownFrame"
	frame.Size = UDim2.new(0, 600, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.2
	frame.ClipsDescendants = true
	frame.Parent = container
	
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = colorMap[trollType] or Color3.fromRGB(255, 255, 0)
	stroke.Thickness = 2
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextSize = 24
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.RichText = true
	textLabel.Parent = frame
	
	-- Składanie tekstu i kolorowanie typu trollingu
	local trollColorHex = string.format("#%02X%02X%02X", stroke.Color.R * 255, stroke.Color.G * 255, stroke.Color.B * 255)
	local prefix = string.format("<b>%s</b> atakuje <b>%s</b> (<font color='%s'>%s</font>):  ", buyerName, targetName, trollColorHex, string.upper(trollType))
	
	task.spawn(function()
		-- 1. Animacja wlotu nowej belki na listę
		frame.Size = UDim2.new(0, 0, 0, 50)
		frame.BackgroundTransparency = 1
		textLabel.TextTransparency = 1
		
		TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 50), BackgroundTransparency = 0.2}):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
		
		-- 2. Odliczanie z pulsem
		for i = 5, 1, -1 do
			if isParticipant then
				beepSound:Play()
			end
			
			textLabel.Text = prefix .. "<font size='36' color='#FF0000'><b>" .. i .. "</b></font>"
			
			-- Bicie serca (Puls obwódki)
			local tw = TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Thickness = 5})
			tw:Play()
			
			task.wait(1)
		end
		
		-- 3. Akcja! (GO!)
		if isParticipant then
			goSound:Play()
		end
		
		textLabel.Text = prefix .. "<font size='40' color='#00FF00'>!! GO !!</font>"
		TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = stroke.Color, BackgroundTransparency = 0.5}):Play()
		
		-- Chwila ekspozycji
		task.wait(1.5)
		
		-- 4. Animacja znikania
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 50), BackgroundTransparency = 1}):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
		
		task.wait(0.3)
		frame:Destroy()
	end)
end)
