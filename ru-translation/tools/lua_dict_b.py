# WorldChat, AppearanceBuddy (сообщения сервера), npcTalk (подписи мирового чата)
D = {}
D["WorldChat.lua"] = {"World": "Мир"}

D["AppearanceBuddy.lua"] = {
    "|cff6ff98f[AppearanceBuddy]|r New appearance unlocked: %s": "|cff6ff98f[AppearanceBuddy]|r Открыт новый облик: %s",
    "|cff6ff98f[AppearanceBuddy]|r [provision test] New appearance unlocked: %s": "|cff6ff98f[AppearanceBuddy]|r [тест] Открыт новый облик: %s",
    "|cffffcc00[AppearanceBuddy]|r This appearance will unlock after the item's trade/refund window ends.":
        "|cffffcc00[AppearanceBuddy]|r Облик откроется после окончания срока обмена/возврата предмета.",
    "Set links are locked for %d more minute%s.": "Ссылки на комплекты заблокированы ещё на %d мин.",
    "Target is not online or could not be found.": "Цель не в сети или не найдена.",
    "Target another player to copy their appearance.": "Выберите другого игрока, чтобы скопировать его облик.",
    "You have not unlocked that appearance.": "Этот облик у вас не открыт.",
    "Your class cannot equip that item type.": "Ваш класс не может использовать этот тип предметов.",
    "Equip an item in that slot before applying an appearance.": "Сначала наденьте предмет в эту ячейку.",
    "Equip an item in this slot before applying an appearance.": "Сначала наденьте предмет в эту ячейку.",
    "Equip an off-hand item or shield before applying an off-hand appearance.": "Сначала наденьте предмет для левой руки или щит.",
    "A 2-handed weapon appearance cannot be applied while an off-hand item is equipped, and cannot be transmogged onto a 1-handed weapon.":
        "Облик двуручного оружия нельзя применить, пока в левой руке есть предмет, и нельзя наложить на одноручное оружие.",
    "|cffffd200[Transmog]|r Charged |cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r for set application.":
        "|cffffd200[Трансмогрификация]|r Списано |cffffd700%dз|r |cffc7c7cf%dс|r |cffeda55f%dм|r за применение комплекта.",
    "Invalid weapon slot.": "Неверная ячейка оружия.",
    "Could not resolve equipment slot.": "Не удалось определить ячейку экипировки.",
    "No weapon equipped in that slot.": "В этой ячейке нет оружия.",
    "Illusion enchants cannot be applied to shields.": "Иллюзии чар нельзя наложить на щит.",
    "Not enough gold. Applying an illusion costs |cffffd700%dg|r |cffc7c7cf%ds|r.":
        "Недостаточно золота. Иллюзия стоит |cffffd700%dз|r |cffc7c7cf%dс|r.",
    "Failed to apply visual: ": "Не удалось применить эффект: ",
    "|cffffcc00[Transmog]|r Commands (GM only):": "|cffffcc00[Трансмогрификация]|r Команды (только для ГМ):",
    "  .transmog free  — disable gold cost (current: |cff00ff00": "  .transmog free  — бесплатно (сейчас: |cff00ff00",
    "  .transmog cost  — enable gold cost": "  .transmog cost  — включить плату золотом",
    "Invalid illusion apply request.": "Неверный запрос иллюзии.",
    "|cff00ff00[Transmog]|r Weapon illusion overrides wiped. Open the transmog tab to verify the preview.":
        "|cff00ff00[Трансмогрификация]|r Иллюзии оружия сброшены. Откройте вкладку трансмогрификации, чтобы проверить.",
    "|cffff5555[Transmog]|r This command requires GM privileges.": "|cffff5555[Трансмогрификация]|r Команда доступна только ГМ.",
    "|cffffcc00[Transmog]|r Mode is already ": "|cffffcc00[Трансмогрификация]|r Режим уже ",
    "Gold cost ENABLED.": "Плата золотом ВКЛЮЧЕНА.",
    "Gold cost DISABLED — transmogs are free.": "Плата золотом ОТКЛЮЧЕНА — трансмогрификация бесплатна.",
    "|cffff5555[AppearanceBuddy]|r learn all: item_template appears empty.": "|cffff5555[AppearanceBuddy]|r learn all: таблица item_template пуста.",
    "|cffffcc00[AppearanceBuddy]|r learn all: %d / %d entries scanned (%d unlocked, %d skipped)...":
        "|cffffcc00[AppearanceBuddy]|r learn all: проверено %d / %d (открыто %d, пропущено %d)...",
    "|cff00ff00[AppearanceBuddy]|r learn all complete: scanned %d, unlocked %d, %d duplicate displays, %d bad/broken.":
        "|cff00ff00[AppearanceBuddy]|r learn all готово: проверено %d, открыто %d, дубликатов %d, битых %d.",
    "|cffff5555[AppearanceBuddy]|r learn all: CreateLuaEvent unavailable; aborting.": "|cffff5555[AppearanceBuddy]|r learn all: CreateLuaEvent недоступен, отмена.",
    "|cffffcc00[AppearanceBuddy]|r Commands (GM only):": "|cffffcc00[AppearanceBuddy]|r Команды (только для ГМ):",
    "  .ab learn all  — unlock every transmoggable appearance for your account.": "  .ab learn all  — открыть все облики для вашей учётной записи.",
    "  .ab provisions test on|off  — simulate fresh-player loot unlock messages.": "  .ab provisions test on|off  — тест сообщений об открытии обликов.",
    "|cffffcc00[AppearanceBuddy]|r Usage: .ab provisions test on|off": "|cffffcc00[AppearanceBuddy]|r Использование: .ab provisions test on|off",
    "|cff00ff00[AppearanceBuddy]|r Provision test mode ON. Looted appearances will be treated as new for this session.":
        "|cff00ff00[AppearanceBuddy]|r Тестовый режим ВКЛ. Добытые облики будут считаться новыми до конца сеанса.",
    "|cff00ff00[AppearanceBuddy]|r Provision test mode OFF.": "|cff00ff00[AppearanceBuddy]|r Тестовый режим ВЫКЛ.",
    "|cffffcc00[AppearanceBuddy]|r Usage: .ab learn all": "|cffffcc00[AppearanceBuddy]|r Использование: .ab learn all",
    "Requires GM mode (use .gm on).": "Нужен режим ГМ (введите .gm on).",
    "Invalid set ID.": "Неверный ID комплекта.",
    "No learnable items found for set ": "Не найдено предметов для комплекта ",
    "|cffffcc00[AppearanceBuddy]|r learn set: unlocked %d item(s) from \\\"%s\\\" for account %d.":
        "|cffffcc00[AppearanceBuddy]|r learn set: открыто предметов: %d из «%s» для учётной записи %d.",
    "|cffffcc00[AppearanceBuddy]|r learn all: scanning item_template...": "|cffffcc00[AppearanceBuddy]|r learn all: сканирование item_template...",
    "|cffff5555[AppearanceBuddy]|r learn all failed: ": "|cffff5555[AppearanceBuddy]|r learn all — ошибка: ",
    "You've leveled up and can now use ": "Вы получили уровень и теперь можете использовать ещё ",
    "|cffffffff more appearances!|r": "|cffffffff обликов!|r",
    "%s (%d pieces)": "%s (%d предм.)",
}

D["ActiveChat/npcTalk.lua"] = {
    "|cFFFFC0C0[World] |r|cff%s|Hplayer:%s|h[%s]|h|r: |cFFFFC0C0%s|r": "|cFFFFC0C0[Мир] |r|cff%s|Hplayer:%s|h[%s]|h|r: |cFFFFC0C0%s|r",
    "|cFF40FF40[Guild] |Hplayer:%s|h[%s]|h: %s|r": "|cFF40FF40[Гильдия] |Hplayer:%s|h[%s]|h: %s|r",
}
