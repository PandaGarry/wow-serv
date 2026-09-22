--=========================================================================
-- Tab_Bots.lua - вкладка «Боты» (NPCBots) с расширенными командами
--=========================================================================

local p = AT.RegisterTab("Боты")

-- Секция «Управление»
local y = AT.MakeSection(p, "Управление", -2)
y = AT.FlowButtons(p, {
	{ "Следовать", ".npcbot command follow", AT.BTN_W, 1, "Боты следуют за вами" },
	{ "Стоять",    ".npcbot command stay", AT.BTN_W, 1, "Боты стоят на месте" },
	{ "Воскресить", ".npcbot revive", AT.BTN_W, 1, "Воскресить выделенного бота (или всех, если цель — вы)" },
	{ "Телепорт к себе", ".npcbot recall teleport", AT.BTN_W, 1, "Принудительно телепортировать ботов к вам" },
	{ "Дистанция 10", ".npcbot distance 10", AT.BTN_W, 1, "Ближняя дистанция следования" },
	{ "Дистанция 30", ".npcbot distance 30", AT.BTN_W, 1, "Средняя дистанция следования" },
}, y)

-- Секция «Поиск и спавн»
y = AT.MakeSection(p, "Поиск и спавн", y - 8)
y = AT.FormRow(p, y - 4, "Найти ботов (класс):", function(t) return ".npcbot lookup " .. t end)
y = AT.FormRow(p, y,     "Спавн бота (ID):",     function(t) return ".npcbot spawn " .. t end)

-- Секция «Список»
y = AT.MakeSection(p, "Список", y - 8)
AT.FlowButtons(p, {
	{ "Список ботов", ".npcbot list spawned", AT.BTN_W, 1, "Список всех заспавненных ботов" },
	{ "Уволить бота", ".npcbot remove", AT.BTN_W, 3, "Уволить выделенного бота" },
	{ "Освободить бота", ".npcbot free", AT.BTN_W, 3, "Освободить бота от владельца" },
}, y)

-- Секция «Продвинутое (GM/Админ)» — НОВОЕ
y = AT.MakeSection(p, "Продвинутое (GM/Админ)", y - 30)
y = AT.FlowButtons(p, {
	{ "Присвоить бота", ".npcbot add", AT.BTN_W, 3, "Присвоить выделенного бота себе (бесплатно)" },
	{ "Удалить бота", ".npcbot delete", AT.BTN_W, 3, "Удалить выделенного бота из мира и БД" },
	{ "Список свободных", ".npcbot list spawned free", AT.BTN_W, 3, "Показать ботов без владельца" },
}, y)
y = AT.FormRow(p, y - 4, "Переместить бота (ID):", function(t) return ".npcbot move " .. t end)

-- Подсказка
local note = AT.MakeLabel(p, "Классы: 1-Воин, 2-Паладин, 3-Охотник, 4-Разбойник, 5-Жрец,\n"
	.. "6-Рыцарь смерти, 7-Шаман, 8-Маг, 9-Чернокнижник, 11-Друид.")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 20)