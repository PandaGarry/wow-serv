--[[
    Battle Pass — русская локализация (ruRU)

    Файл подключается первым в BattlePass.toc. Если клиент не ruRU,
    клиент использует английские строки-ключи из BattlePass.lua —
    ничего дополнительно править не нужно.

    Ключ — английский текст, значение — русский.
    Форматтеры (%d, %s) сохранять обязательно.
]]

if GetLocale() == "ruRU" then
    BattlePassLocale = {
        -- Заголовки интерфейса
        ["Battle Pass"]               = "Боевой пропуск",
        ["Progression"]               = "Прогресс",
        ["Sync"]                      = "Обновить",
        ["Claim All"]                 = "Забрать всё",
        ["Info"]                      = "Инфо",
        ["MAX LEVEL"]                 = "МАКСИМУМ",

        -- Состояния награды
        ["Locked"]                    = "Закрыто",
        ["Claim!"]                    = "Забрать!",
        ["Claimed"]                   = "Получено",
        ["Owned"]                     = "Уже есть",

        -- Подсказка (тултип)
        ["Level %d"]                  = "Уровень %d",
        ["Unknown"]                   = "Неизвестно",
        ["Item"]                      = "Предмет",
        ["Gold"]                      = "Золото",
        ["Title"]                     = "Титул",
        ["Spell"]                     = "Заклинание",
        ["Currency"]                  = "Валюта",
        ["Reward"]                    = "Награда",
        ["Locked - Reach level %d"]   = "Закрыто — достигните %d уровня",
        ["Click to claim!"]           = "Нажмите, чтобы забрать!",
        ["Already claimed"]           = "Уже получено",
        ["You already own this reward"] = "У вас уже есть эта награда",

        -- Сообщения в чат
        ["[Battle Pass]"]             = "[Боевой пропуск]",
        ["[Battle Pass Error]"]       = "[Ошибка боевого пропуска]",
        ["Level %d already claimed."] = "Уровень %d уже получен.",
        ["You already own this reward!"] = "У вас уже есть эта награда!",
        ["Reach level %d to claim this reward."] = "Достигните %d уровня, чтобы забрать эту награду.",
        ["Reward claimed!"]           = "Награда получена!",
        ["Failed to claim reward."]   = "Не удалось забрать награду.",
        ["Unknown error"]             = "Неизвестная ошибка",
        ["Level %d reached!"]         = "Достигнут %d уровень!",

        -- Опыт
        ["XP"]                        = "опыта",

        -- Команда /bp info
        ["Season 1"]                  = "Сезон 1",
        ["Level:"]                    = "Уровень:",
        ["XP:"]                       = "Опыт:",
        ["Total XP:"]                 = "Всего опыта:",
        ["Claimed Rewards:"]          = "Получено наград:",

        -- Служебные (видны только при ошибках)
        ["ERROR: BattlePassScrollContent not found"] = "ОШИБКА: не найдена область прокрутки BattlePassScrollContent",
        ["ERROR: Failed to create item %d"]          = "ОШИБКА: не удалось создать ячейку %d",
    }
end
