-- Enable for skid event DK for Custom RACES
local ENABLED = false -- Set this to false to disable the script or true to enable.(Enable for Custom Race-Disable Module skip_dk_module.conf)

local function deathgateoncreate(event, player)
    if not ENABLED then
        return
    end
    if player:GetClass() == 6 then
		player:LearnSpell(50977)
        player:LearnSpell(53428)
		player:LearnSpell(48778)

        
        local itemId = 38707  
        local amount = 1  

        
        player:AddItem(itemId, amount)
        print("Death Knight Skip script is active. Use your Deathgate to escape the deathknight starting zone.")
    end
end

RegisterPlayerEvent(30, deathgateoncreate)  
