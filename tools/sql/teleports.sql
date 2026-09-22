--===========================================================================
-- tools/sql/teleports.sql
-- Помощник для вкладки «Телепорт» и «Путешествие».
--
-- Команда .tele <имя> ищет совпадение по колонке `name` таблицы `game_tele`
-- (в разных сборках AzerothCore/TrinityCore встречаются разные названия,
-- поэтому список в Data.lua стоит сверить со своей базой).
--
-- База: world (у TrinityCore/AzerothCore — acore_world / world)
--===========================================================================

-- 1. Все сохранённые точки телепорта с координатами
SELECT id, name, position_x, position_y, position_z, orientation, map
FROM game_tele
ORDER BY name;

-- 2. Проверить конкретные точки из Data.lua (подземелья и рейды)
SELECT id, name, map FROM game_tele
WHERE name LIKE '%Ragefire%'   OR name LIKE '%Deadmines%'
   OR name LIKE '%Scarlet%'    OR name LIKE '%Blackrock%'
   OR name LIKE '%Scholomance%'OR name LIKE '%Stratholme%'
   OR name LIKE '%Utgarde%'    OR name LIKE '%Nexus%'
   OR name LIKE '%Gundrak%'    OR name LIKE '%Forge%'
   OR name LIKE '%PitOfSaron%' OR name LIKE '%HallsofReflection%'
   OR name LIKE '%Ulduar%'     OR name LIKE '%Karazhan%'
   OR name LIKE '%BlackTemple%'OR name LIKE '%Sunwell%'
   OR name LIKE '%MoltenCore%' OR name LIKE '%Naxxramas%'
   OR name LIKE '%TrialOfTheCrusader%'
ORDER BY name;

-- 3. Города
SELECT id, name, map FROM game_tele
WHERE name IN ('Stormwind','Ironforge','Darnassus','TheExodar',
               'Orgrimmar','Undercity','ThunderBluff','Silvermoon',
               'Shattrath','Dalaran','BootyBay','Gadgetzan')
ORDER BY name;

-- 4. Зоны прокачки
SELECT id, name, map FROM game_tele
WHERE name LIKE '%Northshire%' OR name LIKE '%SentinelHill%'
   OR name LIKE '%Darkshire%'  OR name LIKE '%Theramore%'
   OR name LIKE '%HonorHold%'  OR name LIKE '%Valiance%'
   OR name LIKE '%ValleyOfTrials%' OR name LIKE '%Crossroads%'
   OR name LIKE '%TarrenMill%' OR name LIKE '%Brackenwall%'
   OR name LIKE '%Thrallmar%'  OR name LIKE '%WarsongHold%'
ORDER BY name;

--===========================================================================
-- Что делать с результатом:
--   * если имя совпадает с Data.lua — ничего менять не нужно;
--   * если отличается — поправь строку в AdminToolsRU/Data.lua;
--   * если нужного имени нет — используй координаты:
--         .go xyz <x> <y> <z> <map>
--     (так уже сделано для Наксрамаса, ЦЛК и Логова Крыла Тьмы).
--
-- Полезно: узнать id точки и телепортироваться по нему —
--         .tele #<id>
--===========================================================================
