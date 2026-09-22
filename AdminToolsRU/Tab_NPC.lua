--===========================================================================
-- Admin Tools RU — Tab_NPC.lua
-- Вкладка «NPC»: быстрый спавн NPC (торговцы, банкиры, трансмог и т.д.),
-- а также удаление и перемещение выделенного NPC.
-- Список NPC правится в Data.lua (AT.DATA.npcGroups).
--===========================================================================

local p = AT.RegisterTab("NPC")

local y = -2

-- Готовые наборы из Data.lua
for _, group in ipairs(AT.DATA.npcGroups) do
	y = AT.MakeSection(p, group.header, y)

	local defs = {}
	for _, npc in ipairs(group.list) do
		defs[#defs + 1] = {
			npc[1],
			".npc add " .. npc[2],
			AT.BTN_W,
			1,
			npc[3] .. "\n|cff888888entry " .. npc[2] .. "|r",
		}
	end
	y = AT.FlowButtons(p, defs, y)
	y = y - 10
end

-- Ручной спавн и поиск
y = AT.MakeSection(p, "Заспавнить вручную", y)

y = AT.FormRow(p, y, "ID существа (entry):", function(t) return ".npc add " .. t end)
y = AT.FormRow(p, y, "Найти NPC:", function(t) return ".lookup creature " .. t end)

-- Удаление и перемещение
y = AT.MakeSection(p, "Удаление и перемещение", y - 4)

local delBtn = AT.MakeButton(p, "Удалить выбранного NPC", 220, ".npc delete", 3,
	"Удалить NPC, на которого наведён курсор")
delBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)

local moveBtn = AT.MakeButton(p, "Переместить к себе", 200, ".npc move", 3,
	"Переместить выделенного NPC к вам")
moveBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + 226, y)

y = y - (AT.BTN_H + AT.PAD)

local infoBtn = AT.MakeButton(p, "Инфо о NPC", AT.BTN_W, ".npc info", 2,
	"Показать сведения о выделенном NPC")
infoBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)

local resetBtn = AT.MakeButton(p, "Сбросить всех", AT.BTN_W, ".npc reset", 3,
	"Сбросить всех ближайших NPC (осторожно!)")
resetBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + (AT.BTN_W + AT.PAD), y)

y = y - (AT.BTN_H + AT.PAD) - 4

local note = AT.MakeLabel(p,
	"Выдели NPC курсором мыши и нажми «Удалить» или «Переместить».\n"
	.. "ID существ можно узнать через .lookup creature или в таблице creature_template.",
	"GameFontDisableSmall")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)

AT.NoteY(p, y - 34)

-- Мгновенный фильтр по кнопкам вкладки (поиск по подписи)
AT.AttachFilter(p, "фильтр NPC…")
