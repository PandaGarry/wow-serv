--===========================================================================
-- Admin Tools RU — Tab_Group.lua
-- Вкладка «Группа»: призыв, воскрешение, кик, работа с целью.
--===========================================================================

local p = AT.RegisterTab("Группа")

local y = AT.MakeSection(p, "Действия с целью", -2)

y = AT.FlowButtons(p, {
	{ "Убить цель",      ".die",        AT.BTN_W, 3, "Убить выделенную цель" },
	{ "Воскресить цель", ".revive",     AT.BTN_W, 2, "Воскресить выделенную цель" },
	{ "Заморозить",      ".freeze",     AT.BTN_W, 2, "Заморозить цель" },
	{ "Разморозить",     ".unfreeze",   AT.BTN_W, 2, "Разморозить цель" },
	{ "Вернуть цель",    ".recall",     AT.BTN_W, 1, "Вернуть цель в предыдущую точку" },
	{ "Призвать группу", ".groupsummon", AT.BTN_W, 2, "Призвать всех членов группы" },
	{ "Выйти из боя",    ".combatstop", AT.BTN_W, 2, "Прервать бой у цели" },
	{ "Снять ауры",      ".unaura all", AT.BTN_W, 2, "Снять все ауры с цели" },
}, y)

y = AT.MakeSection(p, "Игроки", y - 8)

y = AT.FormRow(p, y, "Явиться к игроку:", function(t) return ".appear " .. t end)
y = AT.FormRow(p, y, "Призвать игрока:", function(t) return ".summon " .. t end)
y = AT.FormRow(p, y, "Инфо об игроке:", function(t) return ".pinfo " .. t end)
y = AT.FormRow(p, y, "Кикнуть игрока:", function(t) return ".kick " .. t end)
y = AT.FormRow(p, y, "Отправить сообщение:", function(t) return ".send message " .. t end)

local note = AT.MakeLabel(p,
	"ЛКМ по игроку в чате с зажатым Shift подставляет его имя в поле ввода.",
	"GameFontDisableSmall")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 4, y - 4)
AT.NoteY(p, y - 30)
