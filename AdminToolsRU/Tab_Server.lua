--=========================================================================
-- Tab_Server.lua - вкладка «Сервер»
--=========================================================================

local p = AT.RegisterTab("Сервер")

local y = AT.MakeSection(p, "Информация", -2)
y = AT.FlowButtons(p, {
	{ "Инфо сервера",  ".server info", nil, 1, "Показать информацию о сервере" },
	{ "GPS",           ".gps",         nil, 1, "Показать координаты" },
	{ "Мой аккаунт",   ".account",     nil, 1, "Показать информацию об аккаунте" },
	{ "ГМы онлайн",    ".gm ingame",   nil, 1, "Показать ГМов онлайн" },
	{ "Сохранить всё", ".saveall",     nil, 2, "Сохранить всех персонажей" },
}, y)

y = AT.MakeSection(p, "Выключение и рестарт", y - 6)
y = AT.FlowButtons(p, {
	{ "Выкл. 60 с",    function() AT.ConfirmCmd(".server shutdown 60",  "Выключить сервер через 60 секунд?") end,    nil, 3, "Выключить сервер через 60 секунд" },
	{ "Выкл. 5 мин",   function() AT.ConfirmCmd(".server shutdown 300", "Выключить сервер через 5 минут?") end,      nil, 3, "Выключить сервер через 5 минут" },
	{ "Рестарт 60 с",  function() AT.ConfirmCmd(".server restart 60",   "Перезапустить сервер через 60 секунд?") end, nil, 3, "Перезапустить сервер через 60 секунд" },
	{ "Отменить выкл.", ".server shutdown cancel", nil, 3, "Отменить запланированное выключение/рестарт" },
}, y)

y = AT.MakeSection(p, "Сообщения", y - 6)
y = AT.FormRow(p, y, "Анонс всем игрокам:", function(t) return ".announce " .. t end, 340)
y = AT.FormRow(p, y, "Установить MOTD:",    function(t) return ".server set motd " .. t end, 340)
y = AT.FormRow(p, y, "Выключить через (сек):", function(t) return ".server shutdown " .. t end, 100)

AT.FinishPage(p, y)
