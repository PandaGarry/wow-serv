local ENABLED = false -- Set this to false to disable the script or true to enable.
local command = "bank"

function OnEvents(event, player, message, type, language)
    if not ENABLED then
        return
    end
    if (message == command) then
		
       player:SendBroadcastMessage("|cff00cc00Bienvenido a tu Banco|cff00ffff ["..player:GetName().."]|r")
	   player:SendShowBank(player)
	   return false;
    end
end

RegisterPlayerEvent(42, OnEvents)