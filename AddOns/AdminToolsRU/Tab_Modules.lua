--===========================================================================
-- Admin Tools RU — Tab_Modules.lua
-- Вкладка «Модули»: команды и NPC-услуги ТВОЕЙ сборки
-- (RageZone repack: AzerothCore + NPCBots + Eluna + Extras + Custom Races).
--
-- Все команды — из описания сборки: .hirebot, .npcarena, .npcemblem,
-- .npcreset, .npcbeast, .npcfreepro, .npcvweapon, .npcallmount, .npcbuff,
-- .npcenchant, .npclottery, .npcguild, .npctalent, .npcracial, .npcbank,
-- .bank, .buff, .repairall, .resetid, .ga, .chat
--► Команды .npc* создают/удаляют NPC услуги (нужны GM-права).
--===========================================================================

local p = AT.RegisterTab("Модули")

--===========================================================================
-- NPC-услуги: спавн рядом с собой
--===========================================================================
local y = AT.MakeSection(p, "NPC-услуги сборки (спавн у себя)", -2)

local npcDefs = {}
for _, npc in ipairs(AT.DATA.repackNpcSpawns) do
	local cmd = npc[4]
	local tip = npc[3]
	if npc[2] and npc[2] > 0 then
		tip = tip .. "\n|cff888888entry " .. npc[2] .. "|r"
	end
	npcDefs[#npcDefs + 1] = { npc[1], cmd, AT.BTN_W, 1, tip }
end
y = AT.FlowButtons(p, npcDefs, y)

local spawnHint = AT.MakeLabel(p,
	"Спавн происходит в твоей точке. Удалить NPC — вкладка «NPC» (.npc delete) или\n" ..
	"наведи курсор на NPC и нажми «Удалить выбранного NPC».",
	"GameFontDisableSmall")
spawnHint:SetJustifyH("LEFT")
spawnHint:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 4)
y = y - 36

--===========================================================================
-- Утилиты (модули Extras)
--===========================================================================
y = AT.MakeSection(p, "Утилиты игрока (Extras)", y - 4)

local utilDefs = {}
for _, u in ipairs(AT.DATA.repackUtilities) do
	utilDefs[#utilDefs + 1] = { u[1], u[2], AT.BTN_W, 1, u[3] }
end
y = AT.FlowButtons(p, utilDefs, y)

y = AT.FormRow(p, y - 4, "Объявить в чат:", function(t) return ".chat " .. t end)
y = AT.FormRow(p, y, "Спавн NPC по entry:", function(t) return ".npc add " .. t end)

--===========================================================================
-- Настройки сборки
--===========================================================================
y = AT.MakeSection(p, "Где это включается", y - 4)

local cfg = AT.MakeLabel(p, AT.DATA.repackConfig, "GameFontDisableSmall")
cfg:SetJustifyH("LEFT")
cfg:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 4)
y = y - 92

local cfgNote = AT.MakeLabel(p,
	"Если команда отвечает «неизвестная команда» — соответствующий модуль\n" ..
	"выключен в worldserver.conf сборки. Файл: <сервер>/etc/worldserver.conf,\n" ..
	"после правки — перезапуск или .reload config.",
	"GameFontDisableSmall")
cfgNote:SetJustifyH("LEFT")
cfgNote:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y)
AT.NoteY(p, y - 62)
