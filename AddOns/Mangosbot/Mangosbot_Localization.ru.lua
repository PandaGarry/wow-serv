--[[
	MangosBot — русские названия привязок клавиш (ruRU).
]]

if GetLocale() ~= "ruRU" then return end

BINDING_HEADER_MANGOSBOT = "MangosBot"
BINDING_NAME_ROSTER = "Показать/скрыть список ботов"
BINDING_NAME_DEBUG = "Показать отладочную информацию"
BINDING_NAME_FOLLOW = "Боты: следовать за хозяином"
BINDING_NAME_STAY = "Боты: стоять на месте"
BINDING_NAME_PASSIVE = "Боты: пассивный режим"
BINDING_NAME_FLEE = "Боты: бежать"
BINDING_NAME_LOOT = "Боты: собирать добычу"
BINDING_NAME_ATTACK = "Боты: атаковать"
BINDING_NAME_PULL = "Боты: подтянуть цель"
BINDING_NAME_BOOST = "Боты: вкл/выкл усиление"

-- Подписи в интерфейсе панели (тултипы и заголовки)
MangosbotLocale = {
    ["Click!"]           = "Нажмите!",
    ["Bot Control Panel"] = "Панель управления ботами",
    ["Debug Info"]       = "Отладка",
    ["Filter"]           = "Фильтр",
}
