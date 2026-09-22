--=========================================================================
-- Tab_Character.lua - вкладка «Персонаж»
--=========================================================================

local p = AT.RegisterTab("Персонаж")

local y = AT.MakeSection(p, "Уровень и таланты", -2)
y = AT.FlowButtons(p, {
	{ "Уровень +1", ".levelup 1", AT.BTN_W, 2, "Повысить уровень на 1" },
	{ "Уровень +5", ".levelup 5", AT.BTN_W, 2, "Повысить уровень на 5" },
	{ "Уровень +10", ".levelup 10", AT.BTN_W, 2, "Повысить уровень на 10" },
	{ "Уровень -1", ".levelup -1", AT.BTN_W, 2, "Понизить уровень на 1" },
	{ "Сброс талантов", ".reset talents", AT.BTN_W, 2, "Сбросить все таланты" },
	{ "Сброс заклинаний", ".reset spells", AT.BTN_W, 2, "Сбросить все заклинания" },
}, y)

y = AT.MakeSection(p, "Изучение", y - 8)
y = AT.FlowButtons(p, {
	{ "Изучить класс", ".learn all_myclass", AT.BTN_W, 2, "Изучить все заклинания класса" },
	{ "Изучить все", ".learn all_myspells", AT.BTN_W, 2, "Изучить все заклинания" },
	{ "Изучить таланты", ".learn all_mytalents", AT.BTN_W, 2, "Изучить все таланты" },
	{ "Изучить рецепты", ".learn all_recipes", AT.BTN_W, 2, "Изучить все рецепты" },
	{ "Изучить языки", ".learn all_lang", AT.BTN_W, 2, "Изучить все языки" },
	{ "Изучить ГМ", ".learn all_gm", AT.BTN_W, 3, "Изучить все GM-заклинания" },
	{ "Починить", ".repairitems", AT.BTN_W, 1, "Починить все предметы" },
	{ "+100з", ".modify money 1000000", AT.BTN_W, 2, "Дать 100 золота" },
	{ "+1000з", ".modify money 10000000", AT.BTN_W, 2, "Дать 1000 золота" },
}, y)

y = AT.MakeSection(p, "Предметы", y - 8)
local bag1 = AT.MakeButton(p, "Сумка x1", AT.BTN_W, ".additem " .. AT.MAX_BAG_ID .. " 1", 1, "Дать сумку на 22 слота")
bag1:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)
local bag4 = AT.MakeButton(p, "Сумки x4", AT.BTN_W, ".additem " .. AT.MAX_BAG_ID .. " 4", 1, "Дать 4 сумки на 22 слота")
bag4:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + (AT.BTN_W + AT.PAD), y)
y = y - (AT.BTN_H + AT.PAD) - 2

y = AT.FormRow2(p, y, "Добавить предмет (ID, кол-во):", function(a, b)
	if b == "" then b = "1" end
	return ".additem " .. a .. " " .. b
end)
y = AT.FormRow(p, y, "Добавить набор:",    function(t) return ".additemset " .. t end)
y = AT.FormRow(p, y, "Установить уровень:", function(t) return ".character level " .. t end)
y = AT.FormRow(p, y, "Дать денег (медь):",  function(t) return ".modify money " .. t end)