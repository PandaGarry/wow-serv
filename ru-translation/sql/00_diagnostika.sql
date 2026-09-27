-- =====================================================================
-- 00_diagnostika.sql — ТОЛЬКО ЧТЕНИЕ, ничего не меняет в базе.
-- Показывает, сколько русского перевода есть в базе acore_world.
-- Выполнять в базе acore_world (HeidiSQL: выбрать базу слева -> вкладка «Запрос» -> F9).
-- =====================================================================

-- 1) Общая картина: сколько записей всего и сколько переведено на ruRU
SELECT 'creature_template (NPC)' AS `таблица`,
       (SELECT COUNT(*) FROM creature_template) AS `всего`,
       (SELECT COUNT(*) FROM creature_template_locale WHERE locale='ruRU') AS `ruRU`
UNION ALL SELECT 'item_template (предметы)',
       (SELECT COUNT(*) FROM item_template),
       (SELECT COUNT(*) FROM item_template_locale WHERE locale='ruRU')
UNION ALL SELECT 'quest_template (квесты)',
       (SELECT COUNT(*) FROM quest_template),
       (SELECT COUNT(*) FROM quest_template_locale WHERE locale='ruRU')
UNION ALL SELECT 'gameobject_template (объекты)',
       (SELECT COUNT(*) FROM gameobject_template),
       (SELECT COUNT(*) FROM gameobject_template_locale WHERE locale='ruRU')
UNION ALL SELECT 'gossip_menu_option (пункты диалогов)',
       (SELECT COUNT(*) FROM gossip_menu_option),
       (SELECT COUNT(*) FROM gossip_menu_option_locale WHERE locale='ruRU')
UNION ALL SELECT 'npc_text (тексты диалогов)',
       (SELECT COUNT(*) FROM npc_text),
       (SELECT COUNT(*) FROM npc_text_locale WHERE locale='ruRU')
UNION ALL SELECT 'broadcast_text (фразы)',
       (SELECT COUNT(*) FROM broadcast_text),
       (SELECT COUNT(*) FROM broadcast_text_locale WHERE locale='ruRU')
UNION ALL SELECT 'acore_string (сообщения сервера)',
       (SELECT COUNT(*) FROM acore_string),
       (SELECT COUNT(*) FROM acore_string WHERE locale_ruRU IS NOT NULL AND locale_ruRU <> '')
UNION ALL SELECT 'БОТЫ: npc_text 70000-71000',
       (SELECT COUNT(*) FROM npc_text WHERE ID BETWEEN 70000 AND 71000),
       (SELECT COUNT(*) FROM npc_text_locale WHERE locale='ruRU' AND ID BETWEEN 70000 AND 71000);
