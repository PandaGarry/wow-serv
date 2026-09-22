--===========================================================================
-- Admin Tools RU — Tab_Bots.lua
-- Вкладка «Боты» (модуль NPCBots): управление, поиск, спавн.
--► Команды соответствуют модулю npcbot для AzerothCore/TrinityCore.
--  Если модуля нет — команды просто не будут найдены сервером.
--===========================================================================

local p = AT.RegisterTab("Боты")

local y = AT.MakeSection(p, "Управление отрядом", -2)

y = AT.FlowButtons(p, {
	{ "Следовать",       ".npcbot command follow",  AT.BTN_W, 1, "Боты следуют за вами" },
	{ "Стоять",          ".npcbot command stay",    AT.BTN_W, 1, "Боты стоят на месте" },
	{ "Воскресить",      ".npcbot revive",          AT.BTN_W, 1, "Воскресить выделенного бота (или всех, если цель — вы)" },
	{ "Телепорт к себе", ".npcbot recall teleport", AT.BTN_W, 1, "Принудительно телепортировать ботов к вам" },
	{ "Дистанция 10",    ".npcbot distance 10",     AT.BTN_W, 1, "Ближняя дистанция следования" },
	{ "Дистанция 30",    ".npcbot distance 30",     AT.BTN_W, 1, "Средняя дистанция следования" },
	{ "Дистанция 50",    ".npcbot distance 50",     AT.BTN_W, 1, "Дальняя дистанция следования" },
	{ "Список ботов",    ".npcbot list spawned",    AT.BTN_W, 1, "Список всех заспавненных ботов" },
}, y)

y = AT.MakeSection(p, "Поиск и спавн", y - 8)

y = AT.FormRow(p, y, "Найти ботов (класс):", function(t) return ".npcbot lookup " .. t end)
y = AT.FormRow(p, y, "Спавн бота (ID):", function(t) return ".npcbot spawn " .. t end)
y = AT.FormRow(p, y, "Переместить бота (ID):", function(t) return ".npcbot move " .. t end)

y = AT.MakeSection(p, "Продвинутое (GM/Админ)", y - 8)

y = AT.FlowButtons(p, {
	{ "Присвоить бота", function()
		AT.ConfirmCmd(".npcbot add", "Присвоить выделенного бота себе?")
	end, AT.BTN_W, 3, "Присвоить выделенного бота себе (бесплатно)" },
	{ "Удалить бота", function()
		AT.ConfirmCmd(".npcbot delete", "Удалить выделенного бота из мира и БД?")
	end, AT.BTN_W, 3, "Удалить выделенного бота из мира и БД" },
	{ "Список свободных", ".npcbot list spawned free", AT.BTN_W, 3, "Показать ботов без владельца" },
	{ "Уволить бота",     ".npcbot remove", AT.BTN_W, 3, "Уволить выделенного бота" },
	{ "Освободить бота",  ".npcbot free",   AT.BTN_W, 3, "Освободить бота от владельца" },
}, y)

-- Справочная информация по классам
local classLabel = AT.MakeLabel(p, AT.DATA.npcbotClasses, "GameFontDisableSmall")
classLabel:SetJustifyH("LEFT")
classLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 6)

local specLabel = AT.MakeLabel(p, AT.DATA.npcbotSpeccs, "GameFontDisableSmall")
specLabel:SetJustifyH("LEFT")
specLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 66)

AT.NoteY(p, y - 130)
