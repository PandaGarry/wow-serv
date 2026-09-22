--=========================================================================
-- Tab_Server.lua - вкладка «Сервер»
--=========================================================================

local p = AT.RegisterTab("Сервер")

local y = AT.FlowButtons(p, {
	{ "Инфо сервера", ".server info", AT.BTN_W, 1, "Показать информацию о сервере" },
	{ "GPS", ".gps", AT.BTN_W, 1, "Показать координаты" },
	{ "Сохранить всё", ".saveall", AT.BTN_W, 2, "Сохранить всех персонажей" },
	{ "Мой аккаунт", ".account", AT.BTN_W, 1, "Показать информацию об аккаунте" },
	{ "Кто онлайн", ".gm ingame", AT.BTN_W, 1, "Показать ГМов онлайн" },
	{ "Отмена выключения", ".server shutdown cancel", AT.BTN_W, 3, "Отменить выключение сервера" },
	{ "Выкл 60с", function() AT.ConfirmCmd(".server shutdown 60", "Выключить сервер через 60 секунд?") end, AT.BTN_W, 3, "Выключить сервер" },
	{ "Рестарт 60с", function() AT.ConfirmCmd(".server restart 60", "Перезапустить сервер через 60 секунд?") end, AT.BTN_W, 3, "Перезапустить сервер" },
	{ "Выкл 5м", function() AT.ConfirmCmd(".server shutdown 300", "Выключить сервер через 5 минут?") end, AT.BTN_W, 3, "Выключить сервер через 5 минут" },
}, -4)

y = AT.FormRow(p, y - 4, "Анонс:",          function(t) return ".announce " .. t end)
y = AT.FormRow(p, y,     "Установить MOTD:", function(t) return ".server set motd " .. t end)
y = AT.FormRow(p, y,     "Выключить (сек):", function(t) return ".server shutdown " .. t end)