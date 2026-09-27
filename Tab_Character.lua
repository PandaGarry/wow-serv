--=========================================================================
-- Tab_Character.lua - вкладка «Персонаж»
--=========================================================================

local p = AT.RegisterTab("Персонаж")

local y = AT.MakeSection(p, "Уровень и таланты", -2)
y = AT.FlowButtons(p, {
	{ "Уровень +1",       ".levelup 1",     nil, 2, "Повысить уровень на 1" },
	{ "Уровень +5",       ".levelup 5",     nil, 2, "Повысить уровень на 5" },
	{ "Уровень +10",      ".levelup 10",    nil, 2, "Повысить уровень на 10" },
	{ "Уровень -1",       ".levelup -1",    nil, 2, "Понизить уровень на 1" },
	{ "Сброс талантов",   ".reset talents", nil, 2, "Сбросить все таланты" },
	{ "Сброс заклинаний", ".reset spells",  nil, 2, "Сбросить все заклинания" },
}, y)

y = AT.MakeSection(p, "Изучение", y - 6)
y = AT.FlowButtons(p, {
	{ "Изучить класс",   ".learn all_myclass",   nil, 2, "Изучить все заклинания класса" },
	{ "Изучить все",     ".learn all_myspells",  nil, 2, "Изучить все заклинания" },
	{ "Изучить таланты", ".learn all_mytalents", nil, 2, "Изучить все таланты" },
	{ "Изучить рецепты", ".learn all_recipes",   nil, 2, "Изучить все рецепты" },
	{ "Изучить языки",   ".learn all_lang",      nil, 2, "Изучить все языки" },
	{ "Изучить ГМ",      ".learn all_gm",        nil, 3, "Изучить все GM-заклинания" },
}, y)

y = AT.MakeSection(p, "Предметы и золото", y - 6)
y = AT.FlowButtons(p, {
	{ "Сумка x1", ".additem " .. AT.MAX_BAG_ID .. " 1", nil, 1, "Дать сумку на 22 слота" },
	{ "Сумки x4", ".additem " .. AT.MAX_BAG_ID .. " 4", nil, 1, "Дать 4 сумки на 22 слота" },
	{ "Починить", ".repairitems",           nil, 1, "Починить все предметы" },
	{ "+100 з",   ".modify money 1000000",  nil, 2, "Дать 100 золота" },
	{ "+1000 з",  ".modify money 10000000", nil, 2, "Дать 1000 золота" },
}, y)

y = AT.FormRow2(p, y - 2, "Предмет (ID / кол-во):", function(a, b)
	if b == "" then b = "1" end
	return ".additem " .. a .. " " .. b
end)
y = AT.FormRow(p, y, "Добавить набор (ID):", function(t) return ".additemset " .. t end, 160)
y = AT.FormRow(p, y, "Установить уровень:",  function(t) return ".character level " .. t end, 100)
y = AT.FormRow(p, y, "Дать денег (медь):",   function(t) return ".modify money " .. t end, 160)

AT.FinishPage(p, y)
