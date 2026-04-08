local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollSpectateTarget = BrainrotEvents:WaitForChild("TrollSpectateTarget")

-- Tablica produktów zostaje tutaj jako podgląd, ale zarządzana jest z ServerCaseLogic
local GameConfig = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("GameConfig"))
local BrainrotUtils = require(ReplicatedStorage:WaitForChild("FolderReplicatedStorage"):WaitForChild("BrainrotUtils"))

local TrollAnnouncement = BrainrotEvents:FindFirstChild("TrollAnnouncement") or Instance.new("RemoteEvent")
TrollAnnouncement.Name = "TrollAnnouncement"
TrollAnnouncement.Parent = BrainrotEvents

local TrollActionTriggered = BrainrotEvents:FindFirstChild("TrollActionTriggered") or Instance.new("RemoteEvent")
TrollActionTriggered.Name = "TrollActionTriggered"
TrollActionTriggered.Parent = BrainrotEvents

-- Tabele chronionych graczy (UserId -> Timestamp do kiedy ma ochronę)
local ProtectionsFart = {}
local ProtectionsMajor = {}

local PlayerTargets = {}

TrollSpectateTarget.OnServerEvent:Connect(function(player, target)
	if target and target:IsA("Player") then
		PlayerTargets[player.UserId] = target
	end
end)

local function getTargetCharacter(player)
	local target = PlayerTargets[player.UserId]
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") then
		return target.Character, target.Character.HumanoidRootPart, target.Character.Humanoid, target
	end
	return nil, nil, nil, target
end

local function hasVIPProtectionEnabled(target)
	return target and target:GetAttribute("HasVIP") == true and target:GetAttribute("VIPProtectionEnabled") == true
end

-- RemoteFunction do sprawdzania ważności (Pojawia się zanim klient kupi)
local CheckValidityRF = BrainrotEvents:FindFirstChild("CheckTrollValidity")
if not CheckValidityRF then
	CheckValidityRF = Instance.new("RemoteFunction")
	CheckValidityRF.Name = "CheckTrollValidity"
	CheckValidityRF.Parent = BrainrotEvents
end

CheckValidityRF.OnServerInvoke = function(player, target, trollType)
	if not target then return false, "No target selected!" end
	-- 1. Sprawdź immunitet OG
	if BrainrotUtils.hasCompletedRarity(target, "Secret") then
		return false, "This player is IMMUNE (OG Searcher)!"
	end

	if hasVIPProtectionEnabled(target) then
		return false, "This player has VIP Protection enabled!"
	end
	
	-- 2. Sprawdź oddzielny cooldown
	if trollType == "Fart" then
		if ProtectionsFart[target.UserId] and os.time() < ProtectionsFart[target.UserId] then
			local timeLeft = ProtectionsFart[target.UserId] - os.time()
			return false, string.format("Fart protection: %02d:%02d", math.floor(timeLeft / 60), timeLeft % 60)
		end
		
		local freeTrolls = player:GetAttribute("FreeFartTrolls") or 0
		if freeTrolls > 0 then
			player:SetAttribute("FreeFartTrolls", freeTrolls - 1)
			
			task.spawn(function()
				-- Lokalna wywoływanie executeTroll bez ProcessReceipt:
				-- Przenosimy wywołanie na wyższy poziom (ponieważ CheckTrollValidity działa przed kupnem)
				local TargetPlayerObj = PlayerTargets[player.UserId]
				if TargetPlayerObj then
					executeTroll(player, "Fart")
				end
			end)
			
			return false, "FREE_TROLL_USED"
		end
	else
		-- Inne trolle (Bomb, Lava, Tornado)
		if ProtectionsMajor[target.UserId] and os.time() < ProtectionsMajor[target.UserId] then
			local timeLeft = ProtectionsMajor[target.UserId] - os.time()
			return false, string.format("Major protection: %02d:%02d", math.floor(timeLeft / 60), timeLeft % 60)
		end
	end
	
	-- 3. Sprawdź czy postać żyje
	if not target.Character or not target.Character:FindFirstChild("Humanoid") or target.Character.Humanoid.Health <= 0 then
		return false, "Target is currently dead/respawning!"
	end
	return true, ""
end

local function executeTrollCore(player, trollType, targetChar, hrp, humanoid)

	if trollType == "Bomb" then
		-- Brak opadającej bomby, od razu celujemy w gracza
		local explosionPos = hrp.Position
		
		-- Błyskawiczna fizyczna siła i niszczenie stawów postaci!
		local explosion = Instance.new("Explosion")
		explosion.Position = explosionPos
		explosion.BlastRadius = 25
		explosion.BlastPressure = 1500000 -- Ekstremalnie silne wystempowanie (rozsadza gracza)
		explosion.DestroyJointRadiusPercent = 1 -- Gwarancja absolutnego rozerwania członków!
		explosion.Parent = game.Workspace
		
		-- Epicka, rozrastająca się trójwymiarowa KULA OGNIA!
		local fireball = Instance.new("Part")
		fireball.Name = "MassiveFireball"
		fireball.Shape = Enum.PartType.Ball
		fireball.Size = Vector3.new(2, 2, 2)
		fireball.Position = explosionPos
		fireball.Material = Enum.Material.Neon
		fireball.Color = Color3.fromRGB(255, 100, 20)
		fireball.Anchored = true
		fireball.CanCollide = false
		fireball.Parent = workspace
		
		-- Płynny wybuch kuli ognia (do 40 studów)
		local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
		TweenService:Create(fireball, tweenInfo, {Size = Vector3.new(45, 45, 45), Transparency = 1}):Play()
		Debris:AddItem(fireball, 1)
		
		-- Dźwięk z ReplicatedStorage o nazwie Bomb
		local bombSoundTpl = ReplicatedStorage:FindFirstChild("Bomb")
		local explosionSound
		if bombSoundTpl and bombSoundTpl:IsA("Sound") then
			explosionSound = bombSoundTpl:Clone()
		else
			explosionSound = Instance.new("Sound")
			explosionSound.SoundId = "rbxassetid://4602283437" -- Zapachowy potężny wybuch
		end
		explosionSound.Volume = 5
		explosionSound.Parent = fireball -- gra z miejsca wybuchu
		explosionSound:Play()

		-- Morderstwo
		if humanoid and humanoid.Parent then
			humanoid.Health = 0
		end
		
		-- Gwarancja odrodzenia nawet jeśli silnik Robloxa się zgubi po dezintegracji stawów
		local victimPlayer = Players:GetPlayerFromCharacter(targetChar)
		if victimPlayer then
			task.delay(4.5, function()
				if victimPlayer and victimPlayer.Character == targetChar or (victimPlayer.Character and victimPlayer.Character:FindFirstChild("Humanoid") and victimPlayer.Character.Humanoid.Health <= 0) then
					victimPlayer:LoadCharacter()
				end
			end)
		end

	elseif trollType == "Lava" then
		-- 1. Dźwięk z ReplicatedStorage
		local lavaSoundTpl = ReplicatedStorage:FindFirstChild("Lava")
		local lavaSound
		if lavaSoundTpl and lavaSoundTpl:IsA("Sound") then
			lavaSound = lavaSoundTpl:Clone()
		else
			lavaSound = Instance.new("Sound")
			lavaSound.SoundId = "rbxassetid://100634120850168"
		end
		lavaSound.Volume = 3
		lavaSound.Parent = hrp
		lavaSound:Play()
		Debris:AddItem(lavaSound, 6)

		-- 2. Płaska kałuża lawy pod nogami
		local lavaPuddle = Instance.new("Part")
		lavaPuddle.Name = "DeathLava"
		lavaPuddle.Size = Vector3.new(80, 6, 80) -- Przepotężna lawa, 2x większa
		lavaPuddle.Position = hrp.Position - Vector3.new(0, 3, 0)
		lavaPuddle.Shape = Enum.PartType.Block
		lavaPuddle.Anchored = true
		lavaPuddle.CanCollide = false
		lavaPuddle.Material = Enum.Material.Neon
		lavaPuddle.Color = Color3.fromRGB(255, 50, 0)
		lavaPuddle.Transparency = 0.2
		lavaPuddle.Parent = workspace
		
		-- 3. Ogień na postaci
		local fire = Instance.new("Fire")
		fire.Size = 8
		fire.Heat = 15
		fire.Parent = hrp

		-- 4. Sygnał o pieczeniu do ofiary
		local victimPlayer = Players:GetPlayerFromCharacter(targetChar)
		if victimPlayer then
			TrollActionTriggered:FireClient(victimPlayer, "Lava")
		end

		-- 5. Skakanie i śmierć parzy
		task.spawn(function()
			local startTime = tick()
			
			-- Zmuszanie do skakania co 0.5s przez 5 sekund
			while tick() - startTime < 5 do
				if humanoid and humanoid.Parent and humanoid.Health > 0 then
					humanoid.Jump = true
				end
				task.wait(0.5)
			end
			
			-- Śmierć na miejscu i sprzątanie
			if humanoid and humanoid.Parent then
				humanoid.Health = 0
			end
			if fire then fire:Destroy() end
			if lavaPuddle then lavaPuddle:Destroy() end
		end)

	elseif trollType == "Tornado" then
		-- 1. DŹWIĘK TORNADA
		local windSound = Instance.new("Sound")
		windSound.SoundId = "rbxassetid://82469823958180" -- Wind/Tornado sound
		windSound.Volume = 2
		windSound.Parent = hrp
		windSound:Play()
		Debris:AddItem(windSound, 8)

		-- 2. WIZUALNY MODEL TORNADA Z REPLICATED STORAGE
		local tornadoTemplate = ReplicatedStorage:FindFirstChild("Tornado")
		local tornadoInstance = nil
		
		if tornadoTemplate then
			tornadoInstance = tornadoTemplate:Clone()
			if tornadoInstance:IsA("Model") then
				tornadoInstance:PivotTo(hrp.CFrame - Vector3.new(0, 10, 0))
			elseif tornadoInstance:IsA("BasePart") then
				tornadoInstance.CFrame = hrp.CFrame - Vector3.new(0, 10, 0)
				tornadoInstance.Anchored = true
				tornadoInstance.CanCollide = false
			end
			tornadoInstance.Parent = workspace
			Debris:AddItem(tornadoInstance, 8)

			-- Animacja obrotu modelu
			task.spawn(function()
				local startTime = tick()
				while tick() - startTime < 8 do
					if tornadoInstance and tornadoInstance.Parent then
						if tornadoInstance:IsA("Model") then
							tornadoInstance:PivotTo(tornadoInstance:GetPivot() * CFrame.Angles(0, 0.8, 0))
						else
							tornadoInstance.CFrame = tornadoInstance.CFrame * CFrame.Angles(0, 0.8, 0)
						end
						-- Podążaj za graczem
						if hrp and hrp.Parent then
							local targetPos = hrp.Position - Vector3.new(0, 10, 0)
							if tornadoInstance:IsA("Model") then
								tornadoInstance:PivotTo(CFrame.new(tornadoInstance:GetPivot().Position:Lerp(targetPos, 0.1)) * (tornadoInstance:GetPivot().Rotation))
							else
								tornadoInstance.Position = tornadoInstance.Position:Lerp(targetPos, 0.1)
							end
						end
					end
					task.wait()
				end
				if tornadoInstance then tornadoInstance:Destroy() end
			end)
		end

		-- 3. FIZYKA: PRZYMUSOWY WYRZUT I WIROWANIE
		local function superToss(targetCharacter)
			local tHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
			local tHum = targetCharacter:FindFirstChild("Humanoid")
			if not tHrp or not tHum then return end

			tHum.PlatformStand = true -- Gwarantuje wyłączenie oporu podłogi
			tHum.Sit = true
			task.wait(0.1)
			
			-- Zdefiniujmy środek rotacji (będzie wysoko w górze nad miejscem wybuchu)
			local basePos = hrp.Position + Vector3.new(0, 18, 0)
			
			-- TWORZYMY W 100% DETERMINISTYCZNY PIVOT MIEJSCOWY (Naprawia bugi przyciągania z AlignPosition)
			local pivot = Instance.new("Part")
			pivot.Name = "TornadoPivot"
			pivot.Anchored = true
			pivot.CanCollide = false
			pivot.Transparency = 1
			pivot.Size = Vector3.new(1, 1, 1)
			pivot.CFrame = CFrame.new(basePos)
			pivot.Parent = workspace
			
			-- Tworzymy ramię, do którego spawamy gracza (odległość 14 studów)
			local arm = Instance.new("Part")
			arm.Name = "TornadoArm"
			arm.Anchored = false
			arm.CanCollide = false
			arm.Massless = true
			arm.Transparency = 1
			arm.Size = Vector3.new(1, 1, 1)
			arm.CFrame = CFrame.new(basePos) * CFrame.new(14, 0, 0)
			arm.Parent = workspace
			
			local weldCenter = Instance.new("WeldConstraint")
			weldCenter.Part0 = pivot
			weldCenter.Part1 = arm
			weldCenter.Parent = pivot
			
			-- Teleportujemy gracza do ramienia i "betonujemy" do niego!
			tHrp.CFrame = arm.CFrame
			
			local weldPlayer = Instance.new("WeldConstraint")
			weldPlayer.Part0 = arm
			weldPlayer.Part1 = tHrp
			weldPlayer.Parent = arm
			
			-- Zmuszamy gracza żeby fizycznie latał w owalu i rzucał się wokół środka używając CFrame
			local RunService = game:GetService("RunService")
			local connection
			local angle = 0
			
			connection = RunService.Stepped:Connect(function()
				if pivot and pivot.Parent then
					angle = angle + 0.15 -- Szybkość zapętlania
					
					-- Obracamy samym środkiem. Gracz złączony przez spaw do ramienia poleci za nim!
					-- Y position lekko buja (fale sinusoidalne)
					local bobbingOffset = Vector3.new(0, math.sin(angle * 2.5) * 4, 0)
					pivot.CFrame = CFrame.new(basePos + bobbingOffset) * CFrame.Angles(angle, angle * 1.5, angle * 0.5)
				else
					if connection then connection:Disconnect() end
				end
			end)
			
			-- Czyścimy po 8 sekundach i robimy odrzut!
			task.delay(8, function()
				if connection then connection:Disconnect() end
				
				-- 1. Sprzątanie (Niszczy też spawy)
				if pivot then pivot:Destroy() end
				if arm then arm:Destroy() end
				
				if tHrp then
					for _, b in ipairs(tHrp:GetChildren()) do
						if b:IsA("BodyMover") or b:IsA("AngularVelocity") or b:IsA("LinearVelocity") or b:IsA("VectorForce") or b:IsA("AlignPosition") or b:IsA("AlignOrientation") then
							b:Destroy()
						end
					end
				end
				
				-- 2. Efektowny odrzut na bok (Fling) z potężnego CFrame'a do pędu
				if tHrp then
					local randomAngle = math.rad(math.random(0, 360))
					local flingDir = Vector3.new(math.cos(randomAngle), 0.8, math.sin(randomAngle)).Unit
					tHrp.AssemblyLinearVelocity = flingDir * 250 -- Bardzo silny wystrzał
					
					-- Śmieszny dźwięk odbicia/wyrzucenia
					local punchSound = Instance.new("Sound")
					punchSound.SoundId = "rbxassetid://131144268" -- Klasyczne PUNCH
					punchSound.Volume = 3
					punchSound.Parent = tHrp
					punchSound:Play()
					Debris:AddItem(punchSound, 2)
				end
				
				-- 3. ŚMIERĆ OFIARY (Ostateczne naprawienie)
				if tHum then 
					-- Celowo NIE wyłączamy `PlatformStand = false`, ani nie wymuszamy chodzenia, 
					-- dzięki temu prędkość (AssemblyLinearVelocity) nie zostanie wyzerowana 
					-- i gracz widowiskowo wyleci jako "szmaciana lalka".
					
					-- Zabijamy gracza po ułamku sekundy krótkiego, widowiskowego lotu!
					task.delay(0.35, function()
						if tHum and tHum.Parent then
							tHum.Health = 0
						end
					end)
				end
			end)
		end

		superToss(targetChar)

		-- Pobliskie osoby
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			if char and char ~= targetChar and char:FindFirstChild("HumanoidRootPart") then
				local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
				if dist < 20 then
					superToss(char)
				end
			end
		end

	elseif trollType == "Fart" then
		-- 1. Dźwięk
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://130771368352078"
		sound.Volume = 3
		sound.RollOffMaxDistance = 100
		sound.Parent = hrp
		sound:Play()
		Debris:AddItem(sound, 4)

		-- 2. Fizyczna chmura gazu (widoczna dla wszystkich)
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(0, -1, 1.5) -- Lekko z tyłu i w dół od pasa
		attachment.Parent = hrp

		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds" -- Wbudowana, niezawodna tekstura
		smoke.Color = ColorSequence.new(Color3.fromRGB(60, 120, 40)) -- Toksyczna zieleń
		smoke.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 10) -- Mocno się rozrasta
		})
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.1, 0.3), -- Szybko gęstnieje
			NumberSequenceKeypoint.new(1, 1) -- Powoli się rozwiewa
		})
		smoke.Lifetime = NumberRange.new(3, 5)
		smoke.Speed = NumberRange.new(1, 3)
		smoke.SpreadAngle = Vector2.new(60, 60)
		smoke.Acceleration = Vector3.new(0, 2, 0) -- Powoli unosi się do góry
		smoke.Rate = 0 -- Wyłączamy ciągłe emitowanie...
		smoke.Parent = attachment
		
		smoke:Emit(40) -- ...i robimy jeden wielki, gwałtowny wybuch 40 cząsteczek!
		Debris:AddItem(attachment, 6)
		
		-- 3. Sygnał do klienta ofiary (żeby zatruć jej ekran)
		local victimPlayer = Players:GetPlayerFromCharacter(targetChar)
		if victimPlayer then
			TrollActionTriggered:FireClient(victimPlayer, "Fart")
		end
	end

	return true
end

local function executeTroll(player, trollType)
	local targetChar, hrp, humanoid, targetPlayer = getTargetCharacter(player)

	if not targetChar or not targetPlayer then
		warn("Troll purchased but target is dead or invalid. Consuming receipt to prevent lockup.")
		return true -- MUSI BYĆ TRUE, inaczej Receipt zacina cały sklep!!! Gracze kupujący u zmarłych tracą na własne ryzyko.
	end
	
	local targetName = targetPlayer.Name
	
	-- OCHRONA: Jeśli cel zebrał wszystkie Secret Brainroty
	if BrainrotUtils.hasCompletedRarity(targetPlayer, "Secret") then
		warn("Target " .. targetName .. " is IMMUNE to trolls. Consuming receipt.")
		return true -- Zapobiega blokadzie kolejki
	end

	if hasVIPProtectionEnabled(targetPlayer) then
		warn("Target " .. targetName .. " has VIP protection enabled. Consuming receipt.")
		return true
	end
	
	-- Ustawiamy OCHRONĘ po tym udanym trollu na konkretny slot (Fart uniezależniony od reszty)
	if trollType == "Fart" then
		ProtectionsFart[targetPlayer.UserId] = os.time() + 60
	else
		ProtectionsMajor[targetPlayer.UserId] = os.time() + 600
	end
	
	-- Ogłoszenie trolla wszystkim na serwerze!
	TrollAnnouncement:FireAllClients(player.Name, targetName, trollType)
	
	-- Opóźnienie 5 sekund przed faktycznym atakiem
	task.spawn(function()
		task.wait(5)
		if targetChar and targetChar.Parent and hrp and hrp.Parent and humanoid then
			executeTrollCore(player, trollType, targetChar, hrp, humanoid)
		end
	end)

	-- Zwracamy true od razu, by kasa (ProcessReceipt) zaliczyła zakup i usunęła blokadę kolejki
	return true
end

-- Udostępniamy funkcję Trollowania dla głównego skryptu zakupów (BindableEvent)
local TrollExecuteEvent = BrainrotEvents:FindFirstChild("TrollExecuteLogic")
if not TrollExecuteEvent then
	TrollExecuteEvent = Instance.new("BindableFunction")
	TrollExecuteEvent.Name = "TrollExecuteLogic"
	TrollExecuteEvent.Parent = BrainrotEvents
end

TrollExecuteEvent.OnInvoke = function(player, trollType)
	return executeTroll(player, trollType)
end

-- Clean up memory when player leaves
Players.PlayerRemoving:Connect(function(player)
	PlayerTargets[player.UserId] = nil
end)
