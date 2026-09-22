--[[
	MangosBot — слой локализации.

	MBL("English") возвращает русский текст из Mangosbot_Localization.ru.lua,
	а если перевода нет — исходную строку. Идентификаторы команд
	(например "follow_master") не переводятся: они уходят на сервер как есть.
]]

MangosbotLocale = MangosbotLocale or {}

function MBL(key)
    local value = MangosbotLocale[key]
    if value then
        return value
    end
    return key
end
