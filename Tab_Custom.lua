--=========================================================================
-- Tab_Custom.lua - вкладка «Свои» (пользовательские кнопки)
--=========================================================================

local p = AT.RegisterTab("Свои")

local customPool = {}

local function RefreshCustom()
	for _, b in ipairs(customPool) do b:Hide() end
	local list = (AdminToolsDB and AdminToolsDB.custom) or {}
	for i, item in ipairs(list) do
		local b = customPool[i]
		if not b then
			b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
			b:SetSize(230, 22)
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			customPool[i] = b
		end
		b._idx = i
		b:SetText(item.label)
		b:SetScript("OnClick", function(self, mouse)
			if mouse == "RightButton" then
				local d = StaticPopup_Show("ADMINTOOLS_DELCUSTOM")
				if d then d.data = self._idx end
			else
				AT.RunCmd(item.cmd)
			end
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(item.label, 1, 1, 1)
			GameTooltip:AddLine("Команда: |cff33ff99" .. item.cmd .. "|r", 0.7, 0.7, 0.7)
			GameTooltip:AddLine("ЛКМ — выполнить, ПКМ — удалить", 0.5, 0.5, 0.5)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		local col = (i - 1) % 2
		local row = AT.floor((i - 1) / 2)
		b:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + col * 238, -140 - row * 26)
		b:Show()
	end
end
AdminToolsDB = AdminToolsDB or {}
AdminToolsDB.refreshCustom = RefreshCustom

local head = AT.MakeLabel(p, "ЛКМ — выполнить.  ПКМ — удалить.")
head:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -2)

local l1 = AT.MakeLabel(p, "Название:")
l1:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -30)
local eLabel = AT.MakeEdit(p, 160)
eLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 90, -26)

local l2 = AT.MakeLabel(p, "Команда:")
l2:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -56)
local eCmd = AT.MakeEdit(p, 320)
eCmd:SetPoint("TOPLEFT", p, "TOPLEFT", 90, -52)

local add = AT.MakeButton(p, "Добавить кнопку", 130, function()
	local lab = strtrim(eLabel:GetText() or "")
	local cmd = strtrim(eCmd:GetText() or "")
	if lab == "" or cmd == "" then return end
	AdminToolsDB.custom = AdminToolsDB.custom or {}
	tinsert(AdminToolsDB.custom, { label = lab, cmd = cmd })
	eLabel:SetText(""); eCmd:SetText(""); eLabel:ClearFocus(); eCmd:ClearFocus()
	RefreshCustom()
end, nil, "Добавить новую кнопку в список")
add:SetPoint("TOPLEFT", p, "TOPLEFT", 90, -80)

local note = AT.MakeLabel(p, "Пример: «Даларан» / «.tele dalaran».\n"
	.. "Если команда не работает — сервер отклонил её (проверь SL).")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -112)