--[[
    AppearanceBuddy — слой локализации.

    ABL(key) возвращает русский текст из locale\ruRU.lua, а если русского
    перевода нет — исходную английскую строку. Поэтому аддон работает
    на любом клиенте, а на русском весь интерфейс переведён.

    ВАЖНО: строки-идентификаторы переводить нельзя — их передают в API
    (имена якорей, шрифтов, подклассы предметов для серверных запросов).
    Переводим только то, что видит игрок.
]]

AppearanceBuddyLocale = AppearanceBuddyLocale or {}

function ABL(key)
    local value = AppearanceBuddyLocale[key]
    if value then
        return value
    end
    return key
end

-- Сокращения для частых сочетаний
function ABLF(key, ...)
    return string.format(ABL(key), ...)
end
