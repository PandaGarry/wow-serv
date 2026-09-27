--=========================================================================
-- Tab_Group.lua - вкладка «Группа»
--=========================================================================

local p = AT.RegisterTab("Группа")

local y = AT.MakeSection(p, "Действия с целью", -2)
y = AT.FlowButtons(p, {
	{ "Призвать группу", ".groupsummon", nil, 2, "Призвать всех членов группы" },
	{ "Вернуть цель",    ".recall",      nil, 2, "Вернуть цель в предыдущую точку" },
	{ "Убить цель",      ".die",         nil, 2, "Убить выделенную цель" },
	{ "Воскресить цель", ".revive",      nil, 2, "Воскресить выделенную цель" },
	{ "Заморозить",      ".freeze",      nil, 2, "Заморозить цель" },
	{ "Разморозить",     ".unfreeze",    nil, 2, "Разморозить цель" },
}, y)

y = AT.MakeSection(p, "По имени игрока", y - 6)
y = AT.FormRow(p, y, "Явиться к игроку:", function(t) return ".appear " .. t end)
y = AT.FormRow(p, y, "Призвать игрока:",  function(t) return ".summon " .. t end)
y = AT.FormRow(p, y, "Инфо об игроке:",   function(t) return ".pinfo " .. t end)
y = AT.FormRow(p, y, "Кикнуть игрока:",   function(t) return ".kick " .. t end)

AT.FinishPage(p, y)
