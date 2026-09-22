--===========================================================================
-- Admin Tools RU — Tab_Server.lua
-- Вкладка «Сервер»: информация, анонсы, остановка/перезапуск, сохранение.
--===========================================================================

local p = AT.RegisterTab("Сервер")

local y = AT.MakeSection(p, "Информация", -2)

y = AT.FlowButtons(p, {
	{ "Инфо сервера",  ".server info",  AT.BTN_W, 1, "Показать информацию о сервере" },
	{ "GPS",           ".gps",          AT.BTN_W, 1, "Показать координаты и карту" },
	{ "Мой аккаунт",   ".account",      AT.BTN_W, 1, "Показать информацию об аккаунте" },
	{ "Кто онлайн",    ".gm ingame",    AT.BTN_W, 1, "Показать ГМов в игре" },
	{ "Аптайм",        ".server info",  AT.BTN_W, 1, "Время работы сервера (в .server info)" },
	{ "Кто в мире",    ".who",          AT.BTN_W, 1, "Показать игроков онлайн" },
}, y)

y = AT.MakeSection(p, "Обслуживание", y - 8)

y = AT.FlowButtons(p, {
	{ "Сохранить всё", ".saveall", AT.BTN_W, 2, "Сохранить всех персонажей в БД" },
	{ "Очистить кэш",  ".reload",  AT.BTN_W, 2, "Перезагрузить таблицы ядра (.reload)" },
	{ "Отмена выкл.",  ".server shutdown cancel", AT.BTN_W, 2, "Отменить выключение сервера" },
	{ "Отмена рестарта", ".server restart cancel", AT.BTN_W, 2, "Отменить перезапуск сервера" },
}, y)

y = AT.MakeSection(p, "Опасное (с подтверждением)", y - 8)

y = AT.FlowButtons(p, {
	{ "Рестарт 60с", function()
		AT.ConfirmCmd(".server restart 60", "Перезапустить сервер через 60 секунд?")
	end, AT.BTN_W, 3, "Перезапуск через 60 секунд" },
	{ "Рестарт 5м", function()
		AT.ConfirmCmd(".server restart 300", "Перезапустить сервер через 5 минут?")
	end, AT.BTN_W, 3, "Перезапуск через 5 минут" },
	{ "Выкл 60с", function()
		AT.ConfirmCmd(".server shutdown 60", "Выключить сервер через 60 секунд?")
	end, AT.BTN_W, 3, "Выключение через 60 секунд" },
	{ "Выкл 5м", function()
		AT.ConfirmCmd(".server shutdown 300", "Выключить сервер через 5 минут?")
	end, AT.BTN_W, 3, "Выключение через 5 минут" },
}, y)

y = AT.MakeSection(p, "Сообщения игрокам", y - 8)

y = AT.FormRow(p, y, "Анонс (всем):", function(t) return ".announce " .. t end)
y = AT.FormRow(p, y, "MOTD:", function(t) return ".server set motd " .. t end)
AT.FormRow(p, y, "Выключить (сек):", function(t) return ".server shutdown " .. t end)
