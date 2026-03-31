local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local RebirthEvent = BrainrotEvents:WaitForChild("RebirthEvent")

-- Tworzenie GUI z poziomu kodu (pewność i czystość w eksploratorze)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RebirthGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 
screenGui.Parent = playerGui

local rebirthBtn = Instance.new("ImageButton")
rebirthBtn.Name = "RebirthButton"
rebirthBtn.Size = UDim2.fromOffset(170, 170) -- 15% mniejszy (z 200)
rebirthBtn.Position = UDim2.new(0, 110, 0.5, 210) -- Dopasowane pod mniejszy rozmiar
rebirthBtn.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80) 
rebirthBtn.BackgroundTransparency = 0.2
rebirthBtn.Image = "" -- Czekamy na ikonę
rebirthBtn.ZIndex = 50
rebirthBtn.Parent = screenGui

-- Ikonka Rebirth
local icon = Instance.new("ImageLabel")
icon.Size = UDim2.fromScale(0.9, 0.9) -- Bardziej wypełnia kwadrat
icon.Position = UDim2.fromScale(0.5, 0.45) -- Nieco w górę, by zrobić miejsce na napis
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.BackgroundTransparency = 1
icon.ZIndex = 51
icon.Parent = rebirthBtn

-- Napis na dole REBIRTH
local lb = Instance.new("TextLabel")
lb.Size = UDim2.new(1, 0, 0, 40)
lb.Position = UDim2.fromScale(0, 0.8)
lb.BackgroundTransparency = 1
lb.Text = "REBIRTH"
lb.TextColor3 = Color3.new(1, 1, 1)
lb.Font = Enum.Font.FredokaOne
lb.TextSize = 25
lb.ZIndex = 52
lb.Parent = rebirthBtn
Instance.new("UIStroke", lb).Thickness = 2

task.spawn(function()
	local rebirthIcon = ReplicatedStorage:WaitForChild("RebirthIcon", 5)
	if rebirthIcon then
		if rebirthIcon:IsA("Decal") then
			icon.Image = rebirthIcon.Texture
		elseif rebirthIcon:IsA("ImageLabel") or rebirthIcon:IsA("ImageButton") then
			icon.Image = rebirthIcon.Image
		elseif rebirthIcon:IsA("StringValue") then
			icon.Image = rebirthIcon.Value
		else
			icon.Image = "rbxassetid://72256385" 
		end
	else
		icon.Image = "rbxassetid://72256385" -- Fallback globalny
	end
end)


Instance.new("UICorner", rebirthBtn).CornerRadius = UDim.new(0.2, 0)
local stroke = Instance.new("UIStroke", rebirthBtn)
stroke.Thickness = 4
stroke.Color = Color3.fromRGB(30, 30, 30)

local uiGradient = Instance.new("UIGradient", rebirthBtn)
uiGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7))
})
uiGradient.Rotation = 90

-- LOGIKA SPRAWDZANIA POSTĘPU Z UŻYCIEM EVENTÓW (Zamiast niepraktycznej pętli While)
local TARGET_COUNT = GameConfig.TotalBrainrots
local isReady = false

local function updateButtonDisplay(collection)
	local count = #collection:GetChildren()
	if count >= TARGET_COUNT then
		isReady = true
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		rebirthBtn.BackgroundTransparency = 0
		stroke.Color = Color3.fromRGB(255, 215, 0) -- Złoty obrys gdy gotowy
		icon.ImageColor3 = Color3.new(1, 1, 1)
	else
		isReady = false
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Jaśniejszy szary
		rebirthBtn.BackgroundTransparency = 0.2 -- Wyraźniejszy
		stroke.Color = Color3.fromRGB(70, 70, 70)
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Pełna biel ikony
		icon.Rotation = 0
		icon.Position = UDim2.fromScale(0.5, 0.45)
		stroke.Thickness = 4
	end
end

-- Inicjalizacja folderu kolekcji i podłączenie wydajnych listenerów
task.spawn(function()
	local collection = player:WaitForChild("BrainrotCollection")
	
	-- Pierwszy rzut oka
	updateButtonDisplay(collection)
	
	-- Nasłuchuj tylko wtedy gdy coś się zmieni (Bez obciążania serwera i klienta)
	collection.ChildAdded:Connect(function()
		updateButtonDisplay(collection)
	end)
	collection.ChildRemoved:Connect(function()
		updateButtonDisplay(collection)
	end)
end)

-- INTERAKCJE I ANIMACJE KLIKNIĘCIA
rebirthBtn.MouseEnter:Connect(function()
	if isReady then
		TweenService:Create(rebirthBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(215, 215)}):Play()
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	else
		TweenService:Create(rebirthBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(205, 205)}):Play()
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end)

rebirthBtn.MouseLeave:Connect(function()
	TweenService:Create(rebirthBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(170, 170)}):Play()
	if not isReady then
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	else
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	end
end)

local debounce = false
rebirthBtn.MouseButton1Click:Connect(function()
    if debounce then return end
	debounce = true
	
	-- ZAWSZE OTWIERAMY PROMPT (Służy teraz jako pasek postępu)
    if _G.OpenRebirthPrompt then
        _G.OpenRebirthPrompt()
    else
        -- Fallback jeśli skrypt promptu jeszcze się nie załadował
        local collection = player:FindFirstChild("BrainrotCollection")
        local count = collection and #collection:GetChildren() or 0
        if count >= TARGET_COUNT then
            RebirthEvent:FireServer()
        end
    end
	
	task.wait(0.5)
	debounce = false
end)

-- Pulsujący i ognisty efekt kiedy przycisk jest GOTOWY
RunService.RenderStepped:Connect(function()
	if isReady then
		local t = tick()
		local sine = (math.sin(t * 10) + 1) / 2 -- Szybszy puls
		stroke.Thickness = 4 + (sine * 6)
		
		-- Efekt ognia (zmiana koloru i drganie)
		icon.ImageColor3 = Color3.new(1, 0.4 + (sine * 0.4), 0) -- Pulsujący pomarańczowy/żółty
		
		-- Trzęsienie ikonką (shake)
		local shakeX = (math.random() - 0.5) * 0.04
		local shakeY = (math.random() - 0.5) * 0.04
		icon.Position = UDim2.fromScale(0.5 + shakeX, 0.45 + shakeY)
		icon.Rotation = (math.random() - 0.5) * 5
	end
end)
