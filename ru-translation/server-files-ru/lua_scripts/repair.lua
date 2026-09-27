local ENABLED = false -- Set this to false to disable the script or true to enable.
local cmd = "repairall"

local function OnCommand(event, player, command)
    if not ENABLED then
        return
    end
    if command == cmd then
        if not player:IsInCombat() then
            player:DurabilityRepairAll( false )
            player:SendBroadcastMessage("Ваши предметы отремонтированы.")
        end
        return false
    end
end
RegisterPlayerEvent(42, OnCommand)