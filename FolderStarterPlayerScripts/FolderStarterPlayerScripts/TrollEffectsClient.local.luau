local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollActionTriggered = BrainrotEvents:WaitForChild("TrollActionTriggered")

TrollActionTriggered.OnClientEvent:Connect(function(actionType)
	if actionType == "Fart" then
		-- 1. Toksyczny kolor ekranu
		local cc = Instance.new("ColorCorrectionEffect")
		cc.TintColor = Color3.fromRGB(150, 180, 100) -- Zgniły odcień
		cc.Brightness = -0.1
		cc.Parent = Lighting
		
		-- 2. Rozmazanie oczu (Gaz)
		local blur = Instance.new("BlurEffect")
		blur.Size = 20
		blur.Parent = Lighting
		
		-- 3. Trzęsienie kamery (krztuszenie się)
		local shakeTime = 1.5
		local start = tick()
		local shakeConn
		shakeConn = RunService.RenderStepped:Connect(function()
			if tick() - start > shakeTime then
				shakeConn:Disconnect()
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
				end
				return
			end
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				local offset = Vector3.new(math.random(-10, 10)/20, math.random(-10, 10)/20, math.random(-10, 10)/20)
				player.Character.Humanoid.CameraOffset = offset
			end
		end)
		
		-- 4. Płynne powracanie do normy (wietrzenie gazu przez 4 sekundy)
		TweenService:Create(cc, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TintColor = Color3.new(1,1,1), Brightness = 0}):Play()
		TweenService:Create(blur, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0}):Play()
		
		task.delay(4.5, function()
			cc:Destroy()
			blur:Destroy()
		end)
		
	elseif actionType == "Lava" then
		-- 1. Zmiana oświetlenia na agresywną czerwień
		local cc = Instance.new("ColorCorrectionEffect")
		cc.TintColor = Color3.fromRGB(255, 80, 80) -- Agresywna czerwień
		cc.Brightness = 0.1
		cc.Parent = Lighting
		
		-- 2. Efekt fali gorąca wokół gracza (animowany blur)
		local blur = Instance.new("BlurEffect")
		blur.Size = 5
		blur.Parent = Lighting
		
		local lavaActive = true
		local animConn
		local timePassed = 0
		
		animConn = RunService.RenderStepped:Connect(function(dt)
			timePassed = timePassed + dt
			if not lavaActive then
				animConn:Disconnect()
				return
			end
			-- Gładka pulsacja blura (od ok 5 do 10)
			blur.Size = 7.5 + math.sin(timePassed * 8) * 2.5
		end)
		
		-- Znika na 100% dokładnie w momencie śmierci gracza
		local deathConn
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			deathConn = player.Character.Humanoid.Died:Connect(function()
				lavaActive = false
				cc:Destroy()
				blur:Destroy()
				if deathConn then deathConn:Disconnect() end
			end)
		end
		
		-- Opcja awaryjna
		task.delay(6, function()
			if lavaActive then
				lavaActive = false
				cc:Destroy()
				blur:Destroy()
				if deathConn then deathConn:Disconnect() end
			end
		end)
	end
end)
