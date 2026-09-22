--===========================================================================
-- Admin Tools RU — Tab_Character.lua
-- Вкладка «Персонаж»: уровни, таланты, изучение, деньги, предметы,
-- раса/фракция/имя (важно для Custom Races в сборке).
--===========================================================================

local p = AT.RegisterTab("Персонаж")

--===========================================================================
-- Уровень и таланты
--===========================================================================
local y = AT.MakeSection(p, "Уровень и таланты", -2)

y = AT.FlowButtons(p, {
	{ "Уровень +1",       ".levelup 1",        AT.BTN_W, 2, "Повысить уровень на 1" },
	{ "Уровень +5",       ".levelup 5",        AT.BTN_W, 2, "Повысить уровень на 5" },
	{ "Уровень +10",      ".levelup 10",       AT.BTN_W, 2, "Повысить уровень на 10" },
	{ "Уровень -1",       ".levelup -1",       AT.BTN_W, 2, "Понизить уровень на 1" },
	{ "Сброс талантов",   ".reset talents",    AT.BTN_W, 2, "Сбросить все таланты" },
	{ "Сброс заклинаний", ".reset spells",     AT.BTN_W, 2, "Сбросить все заклинания" },
	{ "Сброс питомца",    ".reset pet talents", AT.BTN_W, 2, "Сбросить таланты питомца" },
	{ "Открыть таланты",  ".cheat talent on",  AT.BTN_W, 3, "Разрешить любое число талантов" },
}, y)

--===========================================================================
-- Раса, фракция, имя (Custom Races)
--===========================================================================
y = AT.MakeSection(p, "Раса, фракция, имя (Custom Races)", y - 6)

y = AT.FlowButtons(p, {
	{ "Сменить расу", function()
		AT.ConfirmCmd(".character changerace " .. (AT.lastCharName or ""),
			"Сменить расу? Персонаж будет перезагружен.")
	end, AT.BTN_W, 3, "Сменить расу (Worgen/Goblin и др. из сборки)" },
	{ "Сменить фракцию", function()
		AT.ConfirmCmd(".character changefaction " .. (AT.lastCharName or ""),
			"Сменить фракцию? Персонаж будет перезагружен.")
	end, AT.BTN_W, 3, "Сменить фракцию" },
	{ "Переименовать", function()
		AT.ConfirmCmd(".character rename " .. (AT.lastCharName or ""), "Разрешить смену имени?")
	end, AT.BTN_W, 3, "Разрешить смену имени при следующем входе" },
	{ "Внешность", function()
		AT.ConfirmCmd(".character customize " .. (AT.lastCharName or ""), "Разрешить смену внешности?")
	end, AT.BTN_W, 3, "Разрешить смену внешности при следующем входе" },
	{ "Скип старта ДК", ".npc add 25462", AT.BTN_W, 1, "NPC для пропуска стартовой зоны ДК" },
}, y)

local nameNote = AT.MakeLabel(p,
	"Если поле «персонаж» пусто — команда применится к тебе самому.\n" ..
	"Для Custom Races: race id идёт из твоей сборки (Worgen/Goblin), поэтому\n" ..
	"удобнее сначала сделать .character changerace, затем сменить внешность.",
	"GameFontDisableSmall")
nameNote:SetJustifyH("LEFT")
nameNote:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 4)
y = y - 52

y = AT.FormRow(p, y, "Персонаж (ник, для GM):", function(t)
	AT.lastCharName = t
	return ".character level " .. t
end)

y = AT.FormRow(p, y, "Своя раса (номер):", function(t) return ".character changerace " .. t end)
y = AT.FormRow(p, y, "Своя фракция (alliance/horde):", function(t) return ".character changefaction " .. t end)
y = AT.FormRow(p, y, "Звания (title id):", function(t) return ".character titles " .. t end)

--===========================================================================
-- Изучение
--===========================================================================
y = AT.MakeSection(p, "Изучение и навыки", y - 6)

y = AT.FlowButtons(p, {
	{ "Изучить класс",   ".learn all_myclass",   AT.BTN_W, 2, "Все заклинания класса" },
	{ "Изучить все",     ".learn all_myspells",  AT.BTN_W, 2, "Все заклинания" },
	{ "Изучить таланты", ".learn all_mytalents", AT.BTN_W, 2, "Все таланты" },
	{ "Изучить рецепты", ".learn all_recipes",   AT.BTN_W, 2, "Все рецепты профессий" },
	{ "Изучить языки",   ".learn all_lang",      AT.BTN_W, 2, "Все языки" },
	{ "Изучить ГМ",      ".learn all_gm",        AT.BTN_W, 3, "Все GM-заклинания" },
	{ "Макс. навыки",    ".maxskill",            AT.BTN_W, 1, "Максимальные навыки" },
	{ "Починить",        ".repairitems",         AT.BTN_W, 1, "Починить всю экипировку" },
}, y)

y = AT.FormRow(p, y - 4, "Изучить заклинание (id):", function(t) return ".learn " .. t end)
y = AT.FormRow(p, y, "Забыть заклинание (id):", function(t) return ".unlearn " .. t end)
y = AT.FormRow(p, y, "Навык (skill level max):", function(t) return ".setskill " .. t end)
y = AT.FormRow(p, y, "Опыт (rate):", function(t) return ".modify xp " .. t end)

--===========================================================================
-- Деньги
--===========================================================================
y = AT.MakeSection(p, "Деньги", y - 6)

y = AT.FlowButtons(p, {
	{ "+100з",   ".modify money 1000000",    AT.BTN_W, 2, "Дать 100 золота" },
	{ "+1000з",  ".modify money 10000000",   AT.BTN_W, 2, "Дать 1000 золота" },
	{ "+10000з", ".modify money 100000000",  AT.BTN_W, 2, "Дать 10000 золота" },
	{ "Честь +1000",  ".modify honor 1000",  AT.BTN_W, 3, "Дать очки чести" },
	{ "Арена +1000",  ".modify arena 1000",  AT.BTN_W, 3, "Дать очки арены" },
}, y)

--===========================================================================
-- Предметы
--===========================================================================
y = AT.MakeSection(p, "Предметы", y - 6)

local bag1 = AT.MakeButton(p, "Сумка x1", AT.BTN_W,
	".additem " .. AT.DATA.bagItemId .. " 1", 1, "Дать сумку на 22 слота")
bag1:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)

local bag4 = AT.MakeButton(p, "Сумки x4", AT.BTN_W,
	".additem " .. AT.DATA.bagItemId .. " 4", 1, "Дать 4 сумки на 22 слота")
bag4:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + (AT.BTN_W + AT.PAD), y)

local setIdBtn = AT.MakeButton(p, "ID сумки", AT.BTN_W, function()
	AT.Print("ID предмета сумки: |cffffd100" .. AT.DATA.bagItemId .. "|r")
	AT.Print("Сменить можно в AdminToolsRU/Data.lua, поле AT.DATA.bagItemId")
end, 1, "Показать, какой предмет выдаётся как «сумка»")
setIdBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + 2 * (AT.BTN_W + AT.PAD), y)

y = y - (AT.BTN_H + AT.PAD) - 6

y = AT.FormRow2(p, y, "Добавить предмет (ID, кол-во):", function(a, b)
	if b == "" then b = "1" end
	return ".additem " .. a .. " " .. b
end)
y = AT.FormRow(p, y, "Добавить набор (ID):", function(t) return ".additemset " .. t end)
y = AT.FormRow(p, y, "Найти предмет:", function(t) return ".lookup item " .. t end)
y = AT.FormRow(p, y, "Отправить предмет (ник itemid:кол):", function(t)
	return ".send items " .. t
end)
AT.FormRow2(p, y, "Отправить почтой (ник, деньги):", function(who, money)
	return ".send money " .. who .. " " .. money
end)
