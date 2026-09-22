--===========================================================================
-- Admin Tools RU — Tab_Teleport.lua
-- Вкладка «Телепорт»: столицы, свободный телепорт, поиск, сохранение точек.
-- Список городов правится в Data.lua (AT.DATA.cities).
--===========================================================================

local p = AT.RegisterTab("Телепорт")

local y = -2

-- Города (Альянс / Орда / Нейтральные) с предупреждением о вражеской столице
for _, group in ipairs(AT.DATA.cities) do
	y = AT.TeleSection(p, y, group.header, group.list)
	y = y - 6
end

-- Свободные формы
y = AT.FormRow(p, y, "Телепорт (имя или #id):", function(t) return ".tele " .. t end)
y = AT.FormRow(p, y, "Найти телепорт:", function(t) return ".lookup tele " .. t end)
y = AT.FormRow(p, y, "Сохранить точку:", function(t) return ".tele add " .. t end)

-- Служебные кнопки
AT.FlowButtons(p, {
	{ "Вернуться назад", ".recall", AT.BTN_W, 1, "Вернуться в предыдущую точку" },
	{ "Сбросить инсты", ".instance unbind all", AT.BTN_W, 2, "Сбросить все привязки к подземельям" },
	{ "Список точек", ".tele", AT.BTN_W, 1, "Показать список сохранённых точек (если поддерживается ядром)" },
}, y - 4)

-- Мгновенный фильтр по кнопкам вкладки (поиск по подписи)
AT.AttachFilter(p, "фильтр городов…")
