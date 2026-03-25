local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")
local TrollSpectateTarget = BrainrotEvents:WaitForChild("TrollSpectateTarget")

local TROLL_PRODUCTS = {
    [100000001] = "Bomb",
    [100000002] = "Lava",
    [100000003] = "Tornado",
    [100000004] = "Fart"
}

-- Store each player's spectate target
local PlayerTargets = {}

TrollSpectateTarget.OnServerEvent:Connect(function(player, target)
    if target and target:IsA("Player") then
        PlayerTargets[player.UserId] = target
    end
end)

local function getTargetCharacter(player)
    local target = PlayerTargets[player.UserId]
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") then
        return target.Character, target.Character.HumanoidRootPart, target.Character.Humanoid
    end
    return nil, nil, nil
end

local function executeTroll(player, trollType)
    local targetChar, hrp, humanoid = getTargetCharacter(player)

    if not targetChar then
        warn("No valid target found for troll: " .. trollType)
        return false
    end

    if trollType == "Bomb" then
        local explosion = Instance.new("Explosion")
        explosion.Position = hrp.Position
        explosion.BlastRadius = 10
        explosion.BlastPressure = 500000
        explosion.DestroyJointRadiusPercent = 0
        explosion.Parent = game.Workspace

        -- Kill player without affecting stats (they just respawn)
        humanoid.Health = 0

    elseif trollType == "Lava" then
        local lavaPart = Instance.new("Part")
        lavaPart.Name = "RisingLava"
        lavaPart.Size = Vector3.new(100, 10, 100)
        lavaPart.Position = Vector3.new(hrp.Position.X, -10, hrp.Position.Z)
        lavaPart.Anchored = true
        lavaPart.CanCollide = false
        lavaPart.Material = Enum.Material.Neon
        lavaPart.Color = Color3.fromRGB(255, 85, 0)
        lavaPart.Parent = game.Workspace

        local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Linear)
        local goal = {Position = Vector3.new(lavaPart.Position.X, 50, lavaPart.Position.Z)}
        local tween = TweenService:Create(lavaPart, tweenInfo, goal)
        tween:Play()

        local connection
        connection = lavaPart.Touched:Connect(function(hit)
            local char = hit.Parent
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.Health = 0
                end
            end
        end)

        tween.Completed:Connect(function()
            connection:Disconnect()
            lavaPart:Destroy()
        end)

    elseif trollType == "Tornado" then
        -- Particle effect for whirlwind
        local attachment = Instance.new("Attachment")
        attachment.Parent = hrp

        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://6820579930" -- Example wind texture
        emitter.Rate = 50
        emitter.Speed = NumberRange.new(5, 10)
        emitter.Lifetime = NumberRange.new(2, 3)
        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 15)})
        emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)})
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = NumberRange.new(200, 300)
        emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
        emitter.Parent = attachment

        Debris:AddItem(attachment, 5)

        -- Toss nearby players
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local otherHrp = p.Character.HumanoidRootPart
                local dist = (otherHrp.Position - hrp.Position).Magnitude
                if dist < 20 then
                    local randomDir = Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)).Unit
                    otherHrp:ApplyImpulse(randomDir * 1000)
                end
            end
        end

    elseif trollType == "Fart" then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://888514106" -- Common fart sound
        sound.Volume = 2
        sound.RollOffMaxDistance = 100
        sound.Parent = hrp
        sound:Play()
        Debris:AddItem(sound, 3)

        local attachment = Instance.new("Attachment")
        attachment.Parent = hrp

        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://13214144415" -- Brainrot particle / generic dust
        emitter.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100)) -- Green
        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 5)})
        emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
        emitter.Lifetime = NumberRange.new(2, 4)
        emitter.Rate = 30
        emitter.Speed = NumberRange.new(2, 5)
        emitter.EmissionDirection = Enum.EmissionDirection.Back
        emitter.Parent = attachment

        task.delay(1, function()
            emitter.Enabled = false
        end)
        Debris:AddItem(attachment, 4)
    end

    return true
end

-- Intercept logic to modularly handle MarketplaceService.ProcessReceipt
-- since ServerCaseLogic.legacy.luau already has it
local originalProcessReceipt = MarketplaceService.ProcessReceipt

MarketplaceService.ProcessReceipt = function(receiptInfo)
    local trollType = TROLL_PRODUCTS[receiptInfo.ProductId]
    if trollType then
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if player then
            local success = executeTroll(player, trollType)
            if success then
                return Enum.ProductPurchaseDecision.PurchaseGranted
            else
                -- If no target or failed, don't grant purchase
                return Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- If it's not a troll product, call the original
    if originalProcessReceipt then
        return originalProcessReceipt(receiptInfo)
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end
-- Clean up memory when player leaves
Players.PlayerRemoving:Connect(function(player)
    PlayerTargets[player.UserId] = nil
end)
