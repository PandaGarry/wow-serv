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

y = AT.FormRow(p, y - 2, "Телепорт:",      function(t) return ".tele " .. t end)
y = AT.FormRow(p, y,     "Поиск телепорта:", function(t) return ".lookup tele " .. t end)
y = AT.FormRow(p, y,     "Сохранить точку:", function(t) return ".tele add " .. t end)

AT.FlowButtons(p, {
	{ "Вернуться назад", ".recall", AT.BTN_W, 1, "Вернуться в предыдущую точку" },
	{ "Сбросить инсты",  ".instance unbind all", AT.BTN_W, 2, "Сбросить все привязки к подземельям" },
}, y - 4)