--===========================================================================
-- Admin Tools RU — Tab_Bots.lua
-- Вкладка «Боты»: полный набор команд модуля NPCBots (trickerer/NPCBots).
--
-- Команды сверены с официальным мануалом NPCBots:
--   .npcbot command <follow|follow only|standstill|stopfully|walk|nogossip|unbind>
--   .npcbot distance <N> | distance attack <N>
--   .npcbot info | revive | hide | vehicle eject | go <entry> | move <id>
--   .npcbot spawn <id> | delete [id <id>|free] | free | add | remove
--   .npcbot set spec <1-30> | set faction <a|h|m|f> | set owner <ник>
--   .npcbot order cast <бот> <спелл> [цель]
--   .npcbot lookup <класс> | reloadconfig
-- Можно сокращать: .npcb
--===========================================================================

local p = AT.RegisterTab("Боты")

--===========================================================================
-- Управление отрядом
--===========================================================================
local y = AT.MakeSection(p, "Отряд: движение и поведение", -2)

y = AT.FlowButtons(p, {
	{ "Следовать",     ".npcbot command follow",       AT.BTN_W, 1, "Боты идут за тобой" },
	{ "Только следовать", ".npcbot command follow only", AT.BTN_W, 1, "Идут за тобой, но не атакуют и не кастуют" },
	{ "Стоять",        ".npcbot command standstill",   AT.BTN_W, 1, "Держат позицию, но реагируют на бой" },
	{ "Полный стоп",   ".npcbot command stopfully",    AT.BTN_W, 1, "Прервать всё: не двигаются и не реагируют" },
	{ "Шаг",           ".npcbot command walk",         AT.BTN_W, 1, "Переключить шаг/бег ботов" },
	{ "Без сплетен",   ".npcbot command nogossip",     AT.BTN_W, 1, "Запретить/разрешить окно общения бота" },
	{ "Воскресить",    ".npcbot revive",               AT.BTN_W, 1, "Воскресить выделенного бота или всех своих" },
	{ "Спрятать",      ".npcbot hide",                 AT.BTN_W, 1, "Временно убрать ботов из мира (не в бою)" },
}, y)

y = AT.MakeSection(p, "Дистанция следования", y - 6)
y = AT.FlowButtons(p, {
	{ "10 ярдов",  ".npcbot distance 10",        AT.BTN_W, 1, "Близко" },
	{ "30 ярдов",  ".npcbot distance 30",        AT.BTN_W, 1, "Средне" },
	{ "50 ярдов",  ".npcbot distance 50",        AT.BTN_W, 1, "Далеко" },
	{ "75 ярдов",  ".npcbot distance 75",        AT.BTN_W, 1, "Максимум" },
	{ "Атака: близко", ".npcbot distance attack 20", AT.BTN_W, 1, "Держать дистанцию атаки 20" },
	{ "Атака: далеко", ".npcbot distance attack 50", AT.BTN_W, 1, "Держать дистанцию атаки 50" },
}, y)

y = AT.MakeSection(p, "Информация и транспорт", y - 6)
y = AT.FlowButtons(p, {
	{ "Инфо о ботах",   ".npcbot info",         AT.BTN_W, 1, "Показать сведения о твоих ботах" },
	{ "Выйти из машин", ".npcbot vehicle eject", AT.BTN_W, 1, "Выкинуть ботов из транспорта" },
	{ "Список ботов",   ".npcbot list spawned", AT.BTN_W, 1, "Все заспавненные боты" },
	{ "Список свободных", ".npcbot list spawned free", AT.BTN_W, 1, "Боты без владельца" },
}, y)

--===========================================================================
-- Найм и работа с ботом
--===========================================================================
y = AT.MakeSection(p, "Найм, поиск, спавн", y - 6)

local openClassMenu
do
	local items = {}
	for _, c in ipairs(AT.DATA.botClasses) do
		items[#items + 1] = { c[1] .. " (класс " .. c[2] .. ")", ".npcbot lookup " .. c[2] }
	end
	openClassMenu = AT.BuildMenu("AdminToolsRUBotClassMenu", items)
end

local classBtn = AT.MakeButton(p, "Найти ботов по классу (меню)", 220,
	function(btn) openClassMenu(btn) end, 1,
	"Список ботов выбранного класса с их ID")
classBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)

y = AT.FormRow(p, y - 4, "Найти по классу (номер):", function(t) return ".npcbot lookup " .. t end)
y = AT.FormRow(p, y, "Заспавнить бота (ID):", function(t) return ".npcbot spawn " .. t end)
y = AT.FormRow(p, y, "Переместить бота (ID):", function(t) return ".npcbot move " .. t end)
y = AT.FormRow(p, y, "Телепорт к боту (ID):", function(t) return ".npcbot go " .. t end)

--===========================================================================
-- Настройка выделенного бота (GM)
--===========================================================================
y = AT.MakeSection(p, "Настройка выделенного бота (GM)", y - 6)

y = AT.FlowButtons(p, {
	{ "Присвоить себе", ".npcbot add",    AT.BTN_W, 3, "Взять выделенного бота бесплатно" },
	{ "Уволить",        ".npcbot remove", AT.BTN_W, 3, "Уволить бота" },
	{ "Освободить",     ".npcbot free",   AT.BTN_W, 3, "Забрать бота у владельца" },
}, y)

-- фракция бота
local factionDefs = {}
for _, f in ipairs(AT.DATA.botFactions) do
	factionDefs[#factionDefs + 1] = {
		f[1], ".npcbot set faction " .. f[2], AT.BTN_W, 3,
		"Сделать выделенного бота: " .. f[1],
	}
end
local factionLabel = AT.MakeLabel(p, "Фракция выделенного бота:")
factionLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 4)
y = AT.FlowButtons(p, factionDefs, y - 20)

y = AT.FormRow(p, y, "Спека бота (1-30):", function(t) return ".npcbot set spec " .. t end)
y = AT.FormRow(p, y, "Сменить владельца (ник):", function(t) return ".npcbot set owner " .. t end)
y = AT.FormRow(p, y, "Приказ: каст (бот):", function(t) return ".npcbot order cast " .. t end)

local orderNote = AT.MakeLabel(p,
	"Приказ на каст вводится в формате: имя_бота спелл [цель], например\n"
	.. "«javad lesser_healing_wave me» или «javad purge mytarget».",
	"GameFontDisableSmall")
orderNote:SetJustifyH("LEFT")
orderNote:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 4)
y = y - 34

--===========================================================================
-- Опасные операции
--===========================================================================
y = AT.MakeSection(p, "Опасные операции (с подтверждением)", y - 6)

y = AT.FlowButtons(p, {
	{ "Удалить бота", function()
		AT.ConfirmCmd(".npcbot delete", "Удалить выделенного бота из мира и БД?\nЭкипировка вернётся владельцу.")
	end, AT.BTN_W, 3, "Удалить выделенного бота (сначала лучше .npcbot remove)" },
	{ "Удалить по ID", function()
		AT.ConfirmCmd(".npcbot delete id " .. (AT.lastIdInput or ""), "Удалить бота по ID?")
	end, AT.BTN_W, 3, "Удалить бота по ID (укажи в поле ниже)" },
	{ "Удалить всех свободных", function()
		AT.ConfirmCmd(".npcbot delete free", "Удалить ВСЕХ ботов без владельца?")
	end, AT.BTN_W, 3, "Массовое удаление ботов без владельца" },
}, y)

y = AT.FormRow(p, y, "ID бота для удаления:", function(t)
	AT.lastIdInput = t
	return ".npcbot delete id " .. t
end)

--===========================================================================
-- Сервер (GM)
--===========================================================================
y = AT.MakeSection(p, "Обслуживание модуля (GM)", y - 6)

y = AT.FlowButtons(p, {
	{ "Перечитать конфиг", ".npcbot reloadconfig", AT.BTN_W, 3, "Перезагрузить настройки NPCBots из конфига" },
	{ "Пути странников",   ".npcbot wp spawnall",  AT.BTN_W, 3, "Разработка: точки блуждания ботов" },
}, y)

-- Героические классы — только если собраны в сервере
local heroLabel = AT.MakeLabel(p, "Героические классы (если собраны в сервере):", "GameFontNormal")
heroLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 6)
y = y - 24

local heroDefs = {}
for _, c in ipairs(AT.DATA.botHeroClasses) do
	heroDefs[#heroDefs + 1] = { c[1], ".npcbot lookup " .. c[2], AT.BTN_W, 3, "Поиск ботов класса " .. c[1] }
end
y = AT.FlowButtons(p, heroDefs, y)

local tip = AT.MakeLabel(p, AT.DATA.botTips, "GameFontDisableSmall")
tip:SetJustifyH("LEFT")
tip:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 4)
AT.NoteY(p, y - 68)
