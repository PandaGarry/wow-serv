--=========================================================================
-- Tab_Teleport.lua - вкладка «Телепорт»
--=========================================================================

local p = AT.RegisterTab("Телепорт")

local y = -2
y = AT.TeleSection(p, y, "Альянс", {
	{ "Штормград", "stormwind",   "Alliance" },
	{ "Стальгорн", "ironforge",   "Alliance" },
	{ "Дарнас",    "darnassus",   "Alliance" },
	{ "Экзодар",   "theexodar",   "Alliance" },
})
y = AT.TeleSection(p, y, "Орда", {
	{ "Оргриммар",     "orgrimmar",    "Horde" },
	{ "Подгород",      "undercity",    "Horde" },
	{ "Громовой Утёс", "thunderbluff", "Horde" },
	{ "Луносвет",      "silvermoon",   "Horde" },
})
y = AT.TeleSection(p, y, "Нейтральные", {
	{ "Шаттрат",         "shattrath", "Neutral" },
	{ "Даларан",         "dalaran",   "Neutral" },
	{ "Пиратская Бухта", "bootybay",  "Neutral" },
	{ "Прибамбасск",     "gadgetzan", "Neutral" },
})

y = AT.MakeSection(p, "Произвольный телепорт", y - 4)
y = AT.FormRow(p, y, "Телепорт (имя точки):", function(t) return ".tele " .. t end)
y = AT.FormRow(p, y, "Поиск телепорта:",      function(t) return ".lookup tele " .. t end)
y = AT.FormRow(p, y, "Сохранить точку:",      function(t) return ".tele add " .. t end)

y = AT.MakeSection(p, "Прочее", y - 6)
y = AT.FlowButtons(p, {
	{ "Вернуться назад", ".recall", nil, 1, "Вернуться в предыдущую точку" },
	{ "Сбросить инсты",  ".instance unbind all", nil, 2, "Сбросить все привязки к подземельям" },
	{ "Мои координаты",  ".gps", nil, 1, "Показать текущие координаты" },
}, y)

AT.FinishPage(p, y)
