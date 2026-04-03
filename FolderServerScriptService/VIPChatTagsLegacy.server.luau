local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Obsługa starego ChatService (Legacy Chat)
if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
	task.spawn(function()
		local ChatServiceRunner = ServerScriptService:WaitForChild("ChatServiceRunner", 10)
		if ChatServiceRunner then
			local success, ChatService = pcall(function()
				return require(ChatServiceRunner:WaitForChild("ChatService"))
			end)
			
			if success and ChatService then
				ChatService.SpeakerAdded:Connect(function(speakerName)
					local speaker = ChatService:GetSpeaker(speakerName)
					local player = speaker:GetPlayer()
					
					if player then
						-- Ustawiamy na starcie, jeśli ma VIP
						if player:GetAttribute("HasVIP") then
							speaker:SetExtraData("Tags", {{TagText = "VIP", TagColor = Color3.fromRGB(255, 215, 0)}})
						end
						
						-- Jeśli dokupi VIP w trakcie gry
						player:GetAttributeChangedSignal("HasVIP"):Connect(function()
							if player:GetAttribute("HasVIP") then
								speaker:SetExtraData("Tags", {{TagText = "VIP", TagColor = Color3.fromRGB(255, 215, 0)}})
							end
						end)
					end
				end)
			end
		end
	end)
end