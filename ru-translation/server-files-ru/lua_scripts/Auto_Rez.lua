local ENABLED = false -- Set this to false to disable the script or true for enabled
local SPELL_ID = 51916

function OnKilledByCreature(event, killer, killed)
    if not ENABLED then
        return
    end
    killed:CastSpell(killed, SPELL_ID, true)
end

RegisterPlayerEvent(8, OnKilledByCreature)