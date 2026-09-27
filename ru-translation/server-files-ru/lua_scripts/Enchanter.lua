-- Made by Foereaper
-- Fixed by rochet
-- edit by Clotic Updated with Ranged bows and added some other enchants

local npcid_enchanter = 60011 -- ID for npc

local T = {
    ["Menu"] = {
        {"Голова", 0},
        {"Плечи", 2},
        {"Грудь", 4},
        {"Ноги", 6},
        {"Ступни", 7},
        {"Запястья", 8},
        {"Кисти рук", 9},
        {"Спина (плащ)", 14},
        {"Оружие в правой руке", 15},
        {"Двуручное оружие", 151},
        {"Оружие в левой руке", 16},
        {"Щиты", 161},
        {"Оружие дальнего боя", 17}

    },
    [0] = {
        -- Headpiece
        {"Магический знак пылающих тайн", 3820, false},
        {"Магический знак блаженного исцеления", 3819, false},
        {"Магический знак стойкого защитника", 3818, false},
        {"Магический знак мучений", 3817, false},
        {"Магический знак свирепого гладиатора", 3842, false},
        {"Магический знак триумфа", 3795, false},
        {"Магический знак господства", 3797, false}
    },
    [2] = {
        -- Shoulders
        {"Надпись триумфа", 3793, false},
        {"Надпись господства", 3794, false},
        {"Большая надпись гладиатора", 3852, false},
        {"Большая надпись секиры", 3808, false},
        {"Большая надпись утеса", 3809, false},
        {"Большая надпись вершины", 3811, false},
        {"Большая надпись шторма", 3810, false},
        {"Мощь Плети", 2717, false},
        {"Сила Плети", 2721, false},
        {"Зандаларская печать мощи", 2606, false}
    },
    [4] = {
        -- Chest
        {"Грудь – мощные характеристики", 3832, false},
        {"Грудь – огромный запас здоровья", 3297, false},
        {"Грудь – большое восполнение маны", 2381, false},
        {"Грудь – исключительная устойчивость", 3245, false},
        {"Грудь – повышенная защита", 1953, false}
    },
    [6] = {
        -- Legs
        {"Земляные накладки для поножей", 3853, false},
        {"Накладки для поножей из морозной кожи", 3822, false},
        {"Накладки для поножей из ледяной чешуи", 3823, false},
        {"Блестящая чародейская нить", 3719, false},
        {"Сапфировая чародейская нить", 3721, false}
    },
    [7] = {
        -- Boots
        {"Большая сила атаки", 1597, false},
        {"Живучесть клыкарра", 3232, false},
        {"Превосходная ловкость", 983, false},
        {"Большой дух", 1147, false},
        {"Большая живучесть", 3244, false},
        {"Ледоход", 3826, false},
        {"Большая стойкость", 1075, false}
    },
    [8] = {
        -- Bracers
        {"Гнездо в наручах ", 3717, false},
        {"Высшая выносливость", 3850, false},
        {"Превосходная сила заклинаний", 2332, false},
        {"Большая сила атаки", 3845, false},
        {"Высший дух", 1147, false},
        {"Мастерство", 3231, false},
        {"Большие характеристики", 2661, false},
        {"Исключительный интеллект", 1119, false}

    },
    [9] = {
        -- Gloves
        {"Гнездо в перчатках", 3723, false},
        {"Повышение навыка верховой езды", 930, false},
        {"Большая сила разрушения", 3249, false},
        {"Оружейник", 3253, false},
        {"Сокрушитель", 1603, false},
        {"Ловкость", 3222, false},
        {"Точность", 3234, false},
        {"Мастерство", 3231, false},
        {"Исключительная сила заклинаний", 3246, false}

    },
    [14] = {
        -- Cloak
        {"Теневая броня", 3256, false},
        {"Мудрость", 3296, false},
        {"Нить титанов", 1951, false},
        {"Большая скорость", 3831, false},
        {"Могучая броня", 3294, false},
        {"Высшая ловкость", 1099, false},
        {"Проникающая способность заклинаний", 1262, false}
    },
    [15] = {
        -- Main Hand
        {"Рыцарь", 1900, false},
        {"Страж титанов", 3851, false},
        {"Меткость", 3788, false},
        {"Берсерк", 3789, false},
        {"Черная магия", 3790, false},
        {"Могучая сила заклинаний", 3834, false},
        {"Превосходная мощь", 3833, false},
        {"Ледокол", 3239, false},
        {"Оберег жизни", 3241, false},
        {"Кровопускание", 3870, false},
        {"Защита клинка", 3869, false},
        {"Исключительная ловкость", 1103, false},
        {"Исключительный дух", 3844, false},
        {"Палач", 3225, false},
        {"Мангуст", 2673, false},
        -- Two-Handed
        {"Резня", 3827, true},
        {"Бич Плети", 3247, true},
        {"Убийца великанов", 3251, true},
        {"Большая сила заклинаний", 3854, true}

    },
    [16] = {
        -- Offhand
        {"Страж титанов", 3851, false},
        {"Меткость", 3788, false},
        {"Берсерк", 3789, false},
        {"Черная магия", 3790, false},
        {"Могучая сила заклинаний", 3834, false},
        {"Превосходная мощь", 3833, false},
        {"Ледокол", 3239, false},
        {"Оберег жизни", 3241, false},
        {"Кровопускание", 3870, false},
        {"Защита клинка", 3869, false},
        {"Исключительная ловкость", 1103, false},
        {"Исключительный дух", 3844, false},
        {"Палач", 3225, false},
        {"Мангуст", 2673, false},
        -- Shields
        {"Защита", 1952, true},
        {"Большой интеллект", 1128, true},
        {"Блок щитом", 2655, true},
        {"Устойчивость", 3229, true},
        {"Высшая выносливость", 1071, true},
        {"Прочный щит", 2653, true},

    },
    [17] = {
		--Ranged
        {"Оптический прицел с алмазной огранкой", 3843, false},
        {"Солнечный прицел", 3607, false},
        {"Прицел «Сердцеискатель»", 3608, false}
        -- {"Khorium Scope", 2723, false}

    }
}
local pVar = {}

function Enchanter(event, player, unit)
    pVar[player:GetName()] = nil

    for _, v in ipairs(T["Menu"]) do
        player:GossipMenuAddItem(3, "" .. v[1] .. ".|R", 0, v[2])
    end
    player:GossipSendMenu(1, unit)
end

function EnchanterSelect(event, player, unit, sender, intid, code)
    if (intid < 500) then
        local ID = intid
        local f
        if (intid == 161 or intid == 151) then
            ID = math.floor(intid / 10)
            f = true
        end
        pVar[player:GetName()] = intid
        if (T[ID]) then
            for i, v in ipairs(T[ID]) do
                if ((not f and not v[3]) or (f and v[3])) then
                    player:GossipMenuAddItem(3, "" .. v[1] .. ".|R", 0, v[2])
                end
            end
        end
        player:GossipMenuAddItem(3, "[Назад]", 0, 500)
        player:GossipSendMenu(1, unit)
    elseif (intid == 500) then
        Enchanter(event, player, unit)
    elseif (intid >= 900) then
        local ID = pVar[player:GetName()]
        if (ID == 161 or ID == 151) then
            ID = math.floor(ID / 10)
        end
        for k, v in pairs(T[ID]) do
            if v[2] == intid then
                local item = player:GetEquippedItemBySlot(ID)
                if item then
                    if v[3] then
                        local WType = item:GetSubClass()
                        if pVar[player:GetName()] == 151 then
                            if (WType == 1 or WType == 5 or WType == 6 or WType == 8 or WType == 10) then
                                item:ClearEnchantment(0, 0)
                                item:SetEnchantment(intid, 0, 0)
                            else
                                player:SendAreaTriggerMessage("У вас не надето двуручное оружие!")
                            end
                        elseif pVar[player:GetName()] == 161 then
                            if (WType == 6) then
                                item:ClearEnchantment(0, 0)
                                item:SetEnchantment(intid, 0, 0)
                            else
                                player:SendAreaTriggerMessage("У вас не надет щит!")
                            end
                        elseif pVar[player:GetName()] == 17 then
                            if (WType == 2 or WType == 3 or Wtype == 18) then
                                item:ClearEnchantment(0, 0)
                                item:SetEnchantment(intid, 0, 0)
                            else
                                player:SendAreaTriggerMessage("У вас не надето оружие дальнего боя!")
                            end
                        end
                    else
                        item:ClearEnchantment(0, 0)
                        item:SetEnchantment(intid, 0, 0)
                        player:CastSpell(player, 36937)
                    end
                else
                    player:SendAreaTriggerMessage("В выбранной ячейке нет предмета для зачарования!")
                end
            end
        end
        EnchanterSelect(event, player, unit, sender, pVar[player:GetName()], nil)
    end
end

RegisterCreatureGossipEvent(npcid_enchanter, 1, Enchanter)
RegisterCreatureGossipEvent(npcid_enchanter, 2, EnchanterSelect)
