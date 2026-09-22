--=========================================================================
-- Tab_Group.lua - вкладка «Группа»
--=========================================================================

local p = AT.RegisterTab("Группа")

local y = AT.FlowButtons(p, {
	{ "Призвать группу", ".groupsummon", AT.BTN_W, 2, "Призвать всех членов группы" },
	{ "Вернуть цель", ".recall", AT.BTN_W, 2, "Вернуть цель в предыдущую точку" },
	{ "Убить цель", ".die", AT.BTN_W, 2, "Убить выделенную цель" },
	{ "Воскресить цель", ".revive", AT.BTN_W, 2, "Воскресить выделенную цель" },
	{ "Заморозить", ".freeze", AT.BTN_W, 2, "Заморозить цель" },
	{ "Разморозить", ".unfreeze", AT.BTN_W, 2, "Разморозить цель" },
}, -4)

y = AT.FormRow(p, y - 4, "Явиться к:",    function(t) return ".appear " .. t end)
y = AT.FormRow(p, y,     "Призвать:",      function(t) return ".summon " .. t end)
y = AT.FormRow(p, y,     "Инфо игрока:",   function(t) return ".pinfo " .. t end)
y = AT.FormRow(p, y,     "Кикнуть:",       function(t) return ".kick " .. t end)