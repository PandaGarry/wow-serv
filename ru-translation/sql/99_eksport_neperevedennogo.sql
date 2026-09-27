-- =====================================================================
-- 99_eksport_neperevedennogo.sql — ТОЛЬКО ЧТЕНИЕ.
-- Выгружает английские тексты, у которых НЕТ русского перевода.
-- Запускайте ПОСЛЕ применения 01_*.sql. Каждый результат сохраните
-- в CSV (HeidiSQL: правый клик по результату -> «Экспорт строк» -> CSV, UTF-8)
-- и загрузите в репозиторий в папку ru-translation/export/.
-- =====================================================================

-- A) Фразы и меню ботов без перевода  -> export/bots_npc_text.csv
SELECT t.ID, t.text0_0
FROM npc_text t
LEFT JOIN npc_text_locale l ON l.ID = t.ID AND l.locale = 'ruRU'
WHERE t.ID BETWEEN 70000 AND 71000 AND l.ID IS NULL
ORDER BY t.ID;

-- B) Имена/подписи ботов и кастомных NPC без перевода -> export/creatures.csv
--    (entry >= 70000 — боты и NPC модулей; стандартные NPC уже есть в базе AzerothCore)
SELECT c.entry, c.name, c.subname
FROM creature_template c
LEFT JOIN creature_template_locale l ON l.entry = c.entry AND l.locale = 'ruRU'
WHERE c.entry >= 70000 AND l.entry IS NULL
ORDER BY c.entry;

-- C) Пункты меню NPC без перевода -> export/gossip.csv
SELECT o.MenuID, o.OptionID, o.OptionText, o.BoxText
FROM gossip_menu_option o
LEFT JOIN gossip_menu_option_locale l
       ON l.MenuID = o.MenuID AND l.OptionID = o.OptionID AND l.locale = 'ruRU'
WHERE l.MenuID IS NULL AND o.OptionText <> ''
ORDER BY o.MenuID, o.OptionID;

-- D) Сообщения сервера без перевода -> export/acore_string.csv
SELECT entry, content_default
FROM acore_string
WHERE locale_ruRU IS NULL OR locale_ruRU = ''
ORDER BY entry;
