local function OnEnterWorld(event, player)
    local isHorde = player:IsHorde()
    local playerName = player:GetName()
	
	local Class = { -- Class colors :) Prettier and easier than the elseif crap :) THESE ARE HEX COLORS!
    [1] = "C79C6E", -- Warrior
    [2] = "F58CBA", -- Paladin
    [3] = "ABD473", -- Hunter
    [4] = "FFF569", -- Rogue
    [5] = "FFFFFF", -- Priest
    [6] = "C41F3B", -- Death Knight
    [7] = "0070DE", -- Shaman
    [8] = "69CCF0", -- Mage
    [9] = "9482C9", -- Warlock
    [11] = "FF7d0A" -- Druid
};

    if(player:IsGM()) then
        local t = table.concat({"|cff", Class[player:GetClass()], "|Hplayer:|h [" .. playerName .. "]|h|r - |cffDF01D7[Владелец]|h|r вошёл в игру."});
		SendWorldMessage(t);
    elseif(isHorde == true) then
        local t = table.concat({"|cff", Class[player:GetClass()], "|Hplayer:|h [" .. playerName .. "]|h|r - |cff610B0B[Орда]|h|r вошёл в игру."});
		SendWorldMessage(t);
    elseif(isHorde == false) then
        local t = table.concat({"|cff", Class[player:GetClass()], "|Hplayer:|h [" .. playerName .. "]|h|r - |cff0101DF[Альянс]|h|r вошёл в игру."});
		SendWorldMessage(t);
    end
end

local function OnExitWorld(event, player)
    local isHorde = player:IsHorde()
    local playerName = player:GetName()

    if(player:IsGM()) then
        SendWorldMessage("[" .. playerName .. " - ГМ] вышел из игры." )
    elseif(isHorde == true) then
        SendWorldMessage("[" .. playerName .. " - Орда] вышел из игры." )
    elseif(isHorde == false) then
        SendWorldMessage("[" .. playerName .. " - Альянс] вышел из игры." )
    end
end
    
RegisterPlayerEvent(3, OnEnterWorld)
RegisterPlayerEvent(4, OnExitWorld)