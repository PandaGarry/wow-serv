--===========================================================================
-- Admin Tools RU — Tab_Travel.lua
-- Вкладка «Путешествие»: выпадающие меню с подземельями, рейдами и местами кача.
-- Данные берутся из Data.lua (AT.DATA.dungeons / raids / grindAlliance / grindHorde).
--===========================================================================

local p = AT.RegisterTab("Путешествие")

-- Меню строятся один раз при загрузке аддона.
-- Формат данных: { { "Заголовок", { { "Пункт", "команда" }, ... } }, ... }
local openDungeons = AT.BuildMenu("AdminToolsRUDungeonMenu", AT.DATA.dungeons)
local openRaids    = AT.BuildMenu("AdminToolsRURaidMenu",    AT.DATA.raids)
-- Плоский список: сразу { { "Пункт", "команда" }, ... }
local openGrindA   = AT.BuildMenu("AdminToolsRUGrindAMenu",  AT.DATA.grindAlliance)
local openGrindH   = AT.BuildMenu("AdminToolsRUGrindHMenu",  AT.DATA.grindHorde)

local y = -4

local head = AT.MakeLabel(p, "Выбери категорию — откроется список точек.", "GameFontNormal")
head:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - 26

y = AT.FlowButtons(p, {
	{ "Подземелья (по дополнениям)", function(btn) openDungeons(btn) end, 300, 1,
		"Подземелья, сгруппированные по дополнениям" },
	{ "Рейды (по дополнениям)", function(btn) openRaids(btn) end, 300, 1,
		"Рейды, сгруппированные по дополнениям" },
	{ "Места кача — Альянс", function(btn) openGrindA(btn) end, 300, 1,
		"Зоны прокачки для Альянса" },
	{ "Места кача — Орда", function(btn) openGrindH(btn) end, 300, 1,
		"Зоны прокачки для Орды" },
}, y)

local note = AT.MakeLabel(p,
	"Подсказка: если команда из списка не сработала — сервер не нашёл такое имя\n"
	.. "телепорта. Проверь колонку name в таблице game_tele (см. tools/sql/teleports.sql)\n"
	.. "и поправь название в Data.lua. Для сложных точек используется .go xyz.",
	"GameFontDisableSmall")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 12)
AT.NoteY(p, y - 62)
