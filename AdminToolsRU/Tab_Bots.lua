--=========================================================================
-- Tab_Bots.lua - вкладка «Боты» (NPCBots)
--=========================================================================

local p = AT.RegisterTab("Боты")

local y = AT.MakeSection(p, "Управление", -2)
y = AT.FlowButtons(p, {
	{ "Следовать",       ".npcbot command follow",  nil, 1, "Боты следуют за вами" },
	{ "Стоять",          ".npcbot command stay",    nil, 1, "Боты стоят на месте" },
	{ "Воскресить",      ".npcbot revive",          nil, 1, "Воскресить выделенного бота (или всех, если цель — вы)" },
	{ "Телепорт к себе", ".npcbot recall teleport", nil, 1, "Принудительно телепортировать ботов к вам" },
	{ "Дистанция 10",    ".npcbot distance 10",     nil, 1, "Ближняя дистанция следования" },
	{ "Дистанция 30",    ".npcbot distance 30",     nil, 1, "Средняя дистанция следования" },
}, y)

y = AT.MakeSection(p, "Список", y - 6)
y = AT.FlowButtons(p, {
	{ "Список ботов",     ".npcbot list spawned",      nil, 1, "Список всех заспавненных ботов" },
	{ "Список свободных", ".npcbot list spawned free", nil, 3, "Показать ботов без владельца" },
	{ "Уволить бота",     ".npcbot remove",            nil, 3, "Уволить выделенного бота" },
	{ "Освободить бота",  ".npcbot free",              nil, 3, "Освободить бота от владельца" },
}, y)

y = AT.MakeSection(p, "Продвинутое (GM / Админ)", y - 6)
y = AT.FlowButtons(p, {
	{ "Присвоить бота", ".npcbot add",    nil, 3, "Присвоить выделенного бота себе (бесплатно)" },
	{ "Удалить бота",   ".npcbot delete", nil, 3, "Удалить выделенного бота из мира и БД" },
}, y)

y = AT.MakeSection(p, "Поиск и спавн", y - 6)
y = AT.FormRow(p, y, "Найти ботов (номер класса):", function(t) return ".npcbot lookup " .. t end)
y = AT.FormRow(p, y, "Спавн бота (ID):",            function(t) return ".npcbot spawn " .. t end)
y = AT.FormRow(p, y, "Переместить бота (ID):",      function(t) return ".npcbot move " .. t end)

y = AT.MakeNote(p, "Классы: 1 — Воин, 2 — Паладин, 3 — Охотник, 4 — Разбойник, 5 — Жрец, "
	.. "6 — Рыцарь смерти, 7 — Шаман, 8 — Маг, 9 — Чернокнижник, 11 — Друид.", y - 4)

AT.FinishPage(p, y)
