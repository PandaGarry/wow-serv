--===========================================================================
-- Admin Tools RU — Tab_Custom.lua
-- Вкладка «Свои»: свои кнопки с любыми командами.
-- ЛКМ — выполнить, ПКМ — меню (изменить / переместить / удалить).
-- Кнопки хранятся в SavedVariables (AdminToolsDB.custom).
--===========================================================================

local p = AT.RegisterTab("Свои")

local COLS     = 2
local COL_W    = 238
local ROW_H    = 26
local LIST_TOP = -166

local customPool = {}
local editIndex  = nil
local menuData   = {}
local openMenu   = AT.BuildMenu("AdminToolsRUCustomMenu", menuData)

local labelEdit, cmdEdit, addBtn, cancelBtn, statusLabel

--===========================================================================
-- Хелперы
--===========================================================================
local function GetList()
	if not AdminToolsDB then return {} end
	if type(AdminToolsDB.custom) ~= "table" then AdminToolsDB.custom = {} end
	return AdminToolsDB.custom
end

local function StartEdit(idx)
	local list = GetList()
	local item = list[idx]
	if not item then return end
	editIndex = idx
	labelEdit:SetText(item.label or "")
	cmdEdit:SetText(item.cmd or "")
	addBtn:SetText("Сохранить")
	cancelBtn:Show()
	statusLabel:SetText("Редактирую кнопку номер " .. idx .. " — измени поля и нажми «Сохранить».")
end

local function StopEdit()
	editIndex = nil
	labelEdit:SetText("")
	cmdEdit:SetText("")
	addBtn:SetText("Добавить кнопку")
	cancelBtn:Hide()
	statusLabel:SetText("")
	labelEdit:ClearFocus()
	cmdEdit:ClearFocus()
end

local function MoveCustom(idx, delta)
	local list = GetList()
	local target = idx + delta
	if not list[idx] or not list[target] then return end
	list[idx], list[target] = list[target], list[idx]
	if editIndex == idx then editIndex = target
	elseif editIndex == target then editIndex = idx end
	if AT.refreshCustom then AT.refreshCustom() end
end

local function DeleteCustom(idx)
	local list = GetList()
	local item = list[idx]
	if not item then return end
	-- StaticPopup_Show возвращает диалог — кладём в него индекс для OnAccept
	local dialog = StaticPopup_Show(AT.POPUP_DELCUSTOM, item.label or "?")
	if dialog then dialog.data = idx end
	if editIndex == idx then StopEdit() end
end

--===========================================================================
-- Отрисовка списка кнопок
--===========================================================================
local function RefreshCustom()
	local list = GetList()

	for i = #list + 1, #customPool do
		customPool[i]:Hide()
	end

	for i, item in ipairs(list) do
		local b = customPool[i]
		if not b then
			b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
			b:SetSize(COL_W, 22)
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

			b:SetScript("OnClick", function(self, mouse)
				local list2 = GetList()
				local it = list2[self._idx]
				if not it then return end

				if mouse == "RightButton" then
					for k = #menuData, 1, -1 do menuData[k] = nil end
					menuData[1] = { "Изменить",          function() StartEdit(self._idx) end }
					menuData[2] = { "Вверх",             function() MoveCustom(self._idx, -1) end }
					menuData[3] = { "Вниз",              function() MoveCustom(self._idx, 1) end }
					menuData[4] = { "|cffff5555Удалить|r", function() DeleteCustom(self._idx) end }
					openMenu(self)
				else
					AT.RunCmd(it.cmd)
				end
			end)

			b:SetScript("OnEnter", function(self)
				local list2 = GetList()
				local it = list2[self._idx]
				if not it then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(it.label or "?", 1, 1, 1)
				GameTooltip:AddLine("Команда: |cff33ff99" .. (it.cmd or "") .. "|r", 0.7, 0.7, 0.7)
				GameTooltip:AddLine("ЛКМ — выполнить, ПКМ — меню действий", 0.5, 0.5, 0.5)
				GameTooltip:Show()
			end)
			b:SetScript("OnLeave", function() GameTooltip:Hide() end)

			customPool[i] = b
		end

		b._idx = i
		b:SetText(item.label or "?")
		b:ClearAllPoints()
		local col = (i - 1) % COLS
		local row = AT.floor((i - 1) / COLS)
		b:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + col * (COL_W + 6), LIST_TOP - row * ROW_H)
		b:Show()
	end

	local rows = AT.ceil(#list / COLS)
	AT.NoteY(p, LIST_TOP - (rows + 1) * ROW_H)
	AT.FitPage(p)
end

AT.refreshCustom = RefreshCustom

--===========================================================================
-- Интерфейс
--===========================================================================
local head = AT.MakeLabel(p, "ЛКМ — выполнить.  ПКМ — изменить, переместить или удалить.",
	"GameFontNormal")
head:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -2)

local l1 = AT.MakeLabel(p, "Название:")
l1:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -32)
labelEdit = AT.MakeEdit(p, 200)
labelEdit:SetPoint("TOPLEFT", p, "TOPLEFT", 90, -28)

local l2 = AT.MakeLabel(p, "Команда:")
l2:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -58)
cmdEdit = AT.MakeEdit(p, 340)
cmdEdit:SetPoint("TOPLEFT", p, "TOPLEFT", 90, -54)

addBtn = AT.MakeButton(p, "Добавить кнопку", 140, function()
	local lab = AT.trim(labelEdit:GetText())
	local cmd = AT.trim(cmdEdit:GetText())

	if lab == "" or cmd == "" then
		AT.PrintErr("Заполни и «Название», и «Команда».")
		return
	end

	local list = GetList()
	if editIndex then
		list[editIndex] = { label = lab, cmd = cmd }
		AT.Print("Кнопка обновлена.")
	else
		table.insert(list, { label = lab, cmd = cmd })
		AT.Print("Кнопка добавлена: |cffffd100" .. lab .. "|r")
	end

	StopEdit()
	if AT.refreshCustom then AT.refreshCustom() end
end, nil, "Добавить новую кнопку в список")
addBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 90, -82)

cancelBtn = AT.MakeButton(p, "Отмена", 80, function() StopEdit() end, nil, "Отменить редактирование")
cancelBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 236, -82)
cancelBtn:Hide()

statusLabel = AT.MakeLabel(p, "", "GameFontDisableSmall")
statusLabel:SetJustifyH("LEFT")
statusLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -110)

local note = AT.MakeLabel(p,
	"Пример: название «Даларан», команда «.tele dalaran».\n"
	.. "Если команда не работает — сервер её отклонил (проверь свой уровень доступа).\n"
	.. "Точку в начале команды можно не ставить — аддон добавит её сам.",
	"GameFontDisableSmall")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -128)

local listHead = AT.MakeSection(p, "Мои кнопки", -140)
AT.NoteY(p, listHead)
