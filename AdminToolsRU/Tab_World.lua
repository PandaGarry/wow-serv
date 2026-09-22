--===========================================================================
-- Admin Tools RU — Tab_World.lua
-- Вкладка «Мир»: объекты, перемещение по миру, спавн и правка NPC.
-- Здесь собраны команды, которых не было в старой версии аддона.
--===========================================================================

local p = AT.RegisterTab("Мир")

--===========================================================================
-- Перемещение
--===========================================================================
local y = AT.MakeSection(p, "Перемещение", -2)

y = AT.FlowButtons(p, {
	{ "GPS",           ".gps",      AT.BTN_W, 1, "Координаты и карта текущей позиции" },
	{ "Расстояние",    ".distance", AT.BTN_W, 1, "Дистанция до цели" },
	{ "Вернуться",     ".recall",   AT.BTN_W, 1, "Вернуться в предыдущую точку" },
	{ "Список зон",    ".lookup area", AT.BTN_W, 1, "Найти зону по названию" },
}, y)

y = AT.FormRow(p, y - 4, "К существу (ID/имя):", function(t) return ".go creature " .. t end)
y = AT.FormRow(p, y, "К объекту (GUID):", function(t) return ".go object " .. t end)
y = AT.FormRow(p, y, "В точку X Y Z [карта]:", function(t) return ".go xyz " .. t end)
y = AT.FormRow(p, y, "В зону (zonexy):", function(t) return ".go zonexy " .. t end)
y = AT.FormRow(p, y, "Телепорт по имени:", function(t) return ".tele " .. t end)

--===========================================================================
-- Объекты (gameobjects)
--===========================================================================
y = AT.MakeSection(p, "Объекты (gameobject)", y - 6)

y = AT.FlowButtons(p, {
	{ "Инфо об объекте", ".gobject info",   AT.BTN_W, 1, "Сведения о выделенном объекте" },
	{ "Переместить к себе", ".gobject move", AT.BTN_W, 2, "Перетащить объект в свою точку" },
	{ "Повернуть",      ".gobject turn",   AT.BTN_W, 2, "Повернуть выделенный объект" },
	{ "Ближайшие",      ".gobject near",   AT.BTN_W, 1, "Список объектов рядом" },
	{ "Цель",           ".gobject target", AT.BTN_W, 1, "Выделить объект как цель" },
	{ "Удалить объект", function()
		AT.ConfirmCmd(".gobject delete", "Удалить выделенный объект?")
	end, AT.BTN_W, 3, "Удалить выделенный объект (с подтверждением)" },
	{ "Найти объект", function()
		local e = _G["AdminToolsRUWorldSearch"]
		if e then e:SetFocus() end
	end, AT.BTN_W, 1, "Поле поиска объекта — ниже" },
}, y)

y = AT.FormRow(p, y - 4, "Создать объект (entry):", function(t) return ".gobject add " .. t end)
y = AT.FormRow2(p, y, "Объект + таймер (entry, сек):", function(entry, sec)
	return ".gobject add " .. entry .. " spawntime " .. sec
end)
y = AT.FormRow(p, y, "Поиск объекта (часть имени):", function(t) return ".lookup gameobject " .. t end)

--===========================================================================
-- Спавн и правка NPC
--===========================================================================
y = AT.MakeSection(p, "Спавн и правка NPC", y - 6)

y = AT.FlowButtons(p, {
	{ "Инфо о NPC",     ".npc info",    AT.BTN_W, 1, "Сведения о выделенном NPC" },
	{ "Удалить",        ".npc delete",  AT.BTN_W, 3, "Удалить выделенного NPC" },
	{ "Переместить",    ".npc move",    AT.BTN_W, 3, "Переместить NPC к себе" },
	{ "Повернуть",      ".npc turn",    AT.BTN_W, 2, "Повернуть NPC" },
	{ "Сбросить",       ".npc reset",   AT.BTN_W, 3, "Сбросить ближайших NPC" },
}, y)

y = AT.FormRow(p, y - 4, "Спавн NPC (entry):", function(t) return ".npc add " .. t end)
y = AT.FormRow(p, y, "Найти существо:", function(t) return ".lookup creature " .. t end)
y = AT.FormRow(p, y, "Найти предмет:", function(t) return ".lookup item " .. t end)
y = AT.FormRow(p, y, "Найти заклинание:", function(t) return ".lookup spell " .. t end)
y = AT.FormRow(p, y, "Найти квест:", function(t) return ".lookup quest " .. t end)

--===========================================================================
-- Поиск по gameobject — отдельное поле с фокусом
--===========================================================================
local searchLabel = AT.MakeLabel(p, "Поиск объекта по имени:", "GameFontNormalSmall")
searchLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 5)

local searchEdit = AT.MakeEdit(p, 240)
searchEdit:SetPoint("TOPLEFT", p, "TOPLEFT", 150, y)
_G["AdminToolsRUWorldSearch"] = searchEdit

local function DoSearch()
	local q = AT.trim(searchEdit:GetText())
	if q ~= "" then AT.RunCmd(".lookup gameobject " .. q) end
end

local searchBtn = AT.MakeButton(p, "OK", 40, DoSearch)
searchBtn:SetPoint("LEFT", searchEdit, "RIGHT", 6, 0)

local searchClear = AT.MakeButton(p, "Сброс", 60, function()
	searchEdit:SetText("")
	searchEdit:ClearFocus()
	AT.Print("Поле поиска очищено.")
end)
searchClear:SetPoint("LEFT", searchBtn, "RIGHT", 6, 0)

-- поиск по Enter и доступ из кнопки «Найти объект» выше
searchEdit:SetScript("OnEnterPressed", function(self)
	DoSearch()
	self:ClearFocus()
end)

local hint = AT.MakeLabel(p,
	"Подсказка: для перемещения по карте удобнее .go xyz X Y Z MAP — карту смотри\n" ..
	"через .gps и AtlasLoot. GUID объекта виден в .gobject near / .gobject info.",
	"GameFontDisableSmall")
hint:SetJustifyH("LEFT")
hint:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 30)

AT.NoteY(p, y - 70)
