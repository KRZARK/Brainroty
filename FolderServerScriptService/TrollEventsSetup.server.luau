-- BrainrotEvents RemoteEvents Setup for Troll System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotEvents = ReplicatedStorage:WaitForChild("BrainrotEvents")

local RemoteEventNames = {
    "TrollSpectateTarget", -- Client sends target player to Server when they want to spectate them / confirm target
    "TrollActionTriggered", -- Client tells Server which troll they want to execute (after purchase, or for setup)
    "TrollAnnouncement", -- Wysłanie informacji o kupnie trolla do wszystkich graczy ze szczegółami odliczania
}

for _, name in ipairs(RemoteEventNames) do
    if not BrainrotEvents:FindFirstChild(name) then
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = BrainrotEvents
    end
end
