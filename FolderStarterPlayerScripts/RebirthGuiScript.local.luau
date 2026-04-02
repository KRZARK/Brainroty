local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local FolderReplicatedStorage = ReplicatedStorage:WaitForChild("FolderReplicatedStorage")
local GameConfig = require(FolderReplicatedStorage:WaitForChild("GameConfig"))
local HudTileStyle = require(FolderReplicatedStorage:WaitForChild("HudTileStyle"))

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
rebirthBtn.Position = HudTileStyle.getSlot("left", 3)
rebirthBtn.ZIndex = 50
rebirthBtn.Parent = screenGui

local icon = Instance.new("ImageLabel")
icon.Name = "RebirthIconImage"
icon.Parent = rebirthBtn

local lb = Instance.new("TextLabel")
lb.Text = "REBIRTH"
lb.Parent = rebirthBtn

local rebirthStyle = HudTileStyle.apply(rebirthBtn, icon, lb, {
	side = "left",
	slotIndex = 3,
	zIndex = 50,
})
local stroke = rebirthStyle.Stroke

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


-- LOGIKA SPRAWDZANIA POSTĘPU Z UŻYCIEM EVENTÓW (Zamiast niepraktycznej pętli While)
local TARGET_COUNT = GameConfig.TotalBrainrots
local isReady = false

local function updateButtonDisplay(collection)
	local count = #collection:GetChildren()
	if count >= TARGET_COUNT then
		isReady = true
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(120, 36, 36)
		rebirthBtn.BackgroundTransparency = 0.04
		stroke.Color = Color3.fromRGB(255, 215, 0)
		icon.ImageColor3 = Color3.new(1, 1, 1)
	else
		isReady = false
		rebirthBtn.BackgroundColor3 = HudTileStyle.BaseBackgroundColor
		rebirthBtn.BackgroundTransparency = 0.12
		stroke.Color = HudTileStyle.BaseStrokeColor
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		icon.Rotation = 0
		icon.Position = UDim2.new(0.5, 0, 0.38, 0)
		stroke.Thickness = 3
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
		icon.Position = UDim2.new(0.5, 0, 0.38, 0) + UDim2.fromScale(shakeX, shakeY)
		icon.Rotation = (math.random() - 0.5) * 5
	end
end)
