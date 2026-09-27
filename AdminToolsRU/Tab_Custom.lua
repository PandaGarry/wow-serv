--=========================================================================
-- Tab_Custom.lua - вкладка «Свои» (пользовательские кнопки)
--=========================================================================

local p = AT.RegisterTab("Свои")

local y = AT.MakeSection(p, "Новая кнопка", -2)

local eLabel
local lbl1 = AT.MakeLabel(p, "Название:")
lbl1:SetJustifyH("LEFT"); lbl1:SetWidth(90); lbl1:SetHeight(20)
lbl1:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
eLabel = AT.MakeEdit(p, 200)
eLabel:SetMaxLetters(40)
eLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 102, y)
y = y - AT.ROW_H

local lbl2 = AT.MakeLabel(p, "Команда:")
lbl2:SetJustifyH("LEFT"); lbl2:SetWidth(90); lbl2:SetHeight(20)
lbl2:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
local eCmd = AT.MakeEdit(p, 400)
eCmd:SetPoint("TOPLEFT", p, "TOPLEFT", 102, y)
y = y - AT.ROW_H

local RefreshCustom
local function AddCustom()
	local lab = strtrim(eLabel:GetText() or "")
	local cmd = strtrim(eCmd:GetText() or "")
	if lab == "" or cmd == "" then return end
	AdminToolsDB.custom = AdminToolsDB.custom or {}
	tinsert(AdminToolsDB.custom, { label = lab, cmd = cmd })
	eLabel:SetText(""); eCmd:SetText(""); eLabel:ClearFocus(); eCmd:ClearFocus()
	RefreshCustom()
end
eLabel:SetScript("OnTabPressed", function() eCmd:SetFocus() end)
eCmd:SetScript("OnTabPressed", function() eLabel:SetFocus() end)
eLabel:SetScript("OnEnterPressed", function() eCmd:SetFocus() end)
eCmd:SetScript("OnEnterPressed", AddCustom)

local add = AT.MakeButton(p, "Добавить кнопку", 160, AddCustom, nil, "Добавить новую кнопку в список")
add:SetPoint("TOPLEFT", p, "TOPLEFT", 96, y)
y = y - AT.BTN_H - 8

y = AT.MakeNote(p, "Пример: «Даларан» / «.tele dalaran». ЛКМ по кнопке — выполнить, ПКМ — удалить. "
	.. "Если команда не срабатывает — сервер отклонил её (проверьте уровень доступа).", y)

y = AT.MakeSection(p, "Мои кнопки", y - 4)
local LIST_Y = y

local emptyNote = AT.MakeLabel(p, "Пока пусто — добавьте первую кнопку выше.", "GameFontDisableSmall")
emptyNote:SetPoint("TOPLEFT", p, "TOPLEFT", 6, LIST_Y)

local customPool = {}

RefreshCustom = function()
	for _, b in ipairs(customPool) do b:Hide() end
	local list = (AdminToolsDB and AdminToolsDB.custom) or {}
	local cols = 3
	local w = AT.floor((AT.CONTENT_W - 8 - AT.PAD * (cols - 1)) / cols)
	for i, item in ipairs(list) do
		local b = customPool[i]
		if not b then
			b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
			b:SetSize(w, AT.BTN_H)
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			b:SetScript("OnClick", function(self, mouse)
				local it = AdminToolsDB.custom[self._idx]
				if not it then return end
				if mouse == "RightButton" then
					local d = StaticPopup_Show("ADMINTOOLS_DELCUSTOM", it.label)
					if d then d.data = self._idx end
				else
					AT.RunCmd(it.cmd)
				end
			end)
			b:SetScript("OnEnter", function(self)
				local it = AdminToolsDB.custom[self._idx]
				if not it then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(it.label, 1, 1, 1)
				GameTooltip:AddLine("Команда: |cff33ff99" .. it.cmd .. "|r", 0.7, 0.7, 0.7)
				GameTooltip:AddLine("ЛКМ — выполнить, ПКМ — удалить", 0.5, 0.5, 0.5)
				GameTooltip:Show()
			end)
			b:SetScript("OnLeave", function() GameTooltip:Hide() end)
			customPool[i] = b
		end
		b._idx = i
		AT.SetButtonText(b, item.label)
		local col = (i - 1) % cols
		local row = AT.floor((i - 1) / cols)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + col * (w + AT.PAD), LIST_Y - row * (AT.BTN_H + AT.PAD))
		b:Show()
	end
	if #list == 0 then emptyNote:Show() else emptyNote:Hide() end
	local rows = math.max(1, AT.ceil(#list / cols))
	AT.FinishPage(p, LIST_Y - rows * (AT.BTN_H + AT.PAD))
end
AT.RefreshCustom = RefreshCustom

StaticPopupDialogs["ADMINTOOLS_DELCUSTOM"] = {
	text = "Удалить кнопку «%s»?",
	button1 = YES, button2 = NO,
	OnAccept = function(self, data)
		if AdminToolsDB and AdminToolsDB.custom and data then
			tremove(AdminToolsDB.custom, data)
			RefreshCustom()
		end
	end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

RefreshCustom()
