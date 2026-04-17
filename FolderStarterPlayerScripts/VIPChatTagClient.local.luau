local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Obsługa nowego TextChatService (Modern Chat)
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		
		if message.TextSource then
			local player = Players:GetPlayerByUserId(message.TextSource.UserId)
			if player and player:GetAttribute("HasVIP") then
				-- Dodanie tagu VIP ze złotym kolorem przed nickiem
				properties.PrefixText = "<font color='#FFD700'><b>[VIP]</b></font> " .. message.PrefixText
			end
		end
		
		return properties
	end
end