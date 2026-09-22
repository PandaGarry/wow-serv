--=========================================================================
-- Main.lua - окно, кнопка на миникарте, инициализация
--=========================================================================

local f = CreateFrame("Frame", "AdminToolsRUFrame", UIParent)
AT.frame = f
f:SetSize(640, 620)
f:SetPoint("CENTER")
f:SetBackdrop({
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile = false,
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
f:SetBackdropColor(AT.THEME.bg[1], AT.THEME.bg[2], AT.THEME.bg[3], AT.THEME.bg[4])
f:SetBackdropBorderColor(AT.THEME.border[1], AT.THEME.border[2], AT.THEME.border[3], AT.THEME.border[4])
f:SetToplevel(true)
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local p, _, rp, x, y = self:GetPoint()
	if AdminToolsDB then AdminToolsDB.pos = { p, rp, x, y } end
end)
f:SetScript("OnMouseDown", function(self) self:Raise() end)
f:Hide()
tinsert(UISpecialFrames, "AdminToolsRUFrame")

local title = AT.MakeLabel(f, "Admin Tools RU v4.2", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -14)

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -6, -6)

-- Нижняя панель команд
local cmdLabel = AT.MakeLabel(f, "Команда:")
cmdLabel:SetPoint("BOTTOMLEFT", 20, 20)
local cmdBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
cmdBox:SetSize(380, 20)
cmdBox:SetPoint("LEFT", cmdLabel, "RIGHT", 10, 0)
cmdBox:SetAutoFocus(false)
cmdBox:SetFrameStrata("HIGH")
cmdBox:SetScript("OnEscapePressed", cmdBox.ClearFocus)
cmdBox:SetScript("OnEnterPressed", function(self)
	AT.RunCmd(self:GetText()); self:SetText(""); self:ClearFocus()
end)
local runBtn = AT.MakeButton(f, "Выполнить", 80, function()
	AT.RunCmd(cmdBox:GetText()); cmdBox:SetText("")
end, nil, "Выполнить команду из поля ввода")
runBtn:SetPoint("LEFT", cmdBox, "RIGHT", 8, 0)
runBtn:SetFrameStrata("HIGH")

-- Позиционирование вкладок
for i, name in ipairs(AT.TABS) do
	local b = AT.tabButtons[name]
	b:SetPoint("TOPLEFT", f, "TOPLEFT", 8 + (i - 1) * 66, -42)
end

---------------------------------------------------------------------------
-- Кнопка на миникарте
---------------------------------------------------------------------------
local minimapBtn = CreateFrame("Button", "AdminToolsRUMMBtn", Minimap)
minimapBtn:SetSize(28, 28)
-- Ставим снизу слева, чтобы не пересекаться с AtlasLoot и XRet
minimapBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 4, 4)
minimapBtn:SetFrameStrata("HIGH")  -- выше иконок других аддонов
minimapBtn:SetFrameLevel(Minimap:GetFrameLevel() + 10)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetMovable(true)
minimapBtn:SetClampedToScreen(true)

local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", 0, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_Wrench_01")
minimapBtn.icon = icon

local border = minimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

minimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if f:IsShown() then f:Hide() else f:Show() end
    elseif button == "RightButton" then
        if not f:IsShown() then f:Show() end
        AT.ShowPage("Телепорт")
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Admin Tools RU", 1, 1, 1)
    GameTooltip:AddLine("ЛКМ — открыть/закрыть панель", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("ПКМ — вкладка «Телепорт»", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Перетащи — переместить кнопку", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Перетаскивание
minimapBtn:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AdminToolsDB then
        AdminToolsDB.minimapPos = { point, relPoint, x, y }
    end
end)

-- Восстановление позиции
local function RestoreMinimapPos()
    if AdminToolsDB and AdminToolsDB.minimapPos then
        local p = AdminToolsDB.minimapPos
        minimapBtn:ClearAllPoints()
        minimapBtn:SetPoint(p[1], Minimap, p[2], p[3], p[4])
    end
end
---------------------------------------------------------------------------
-- Слэш-команды
---------------------------------------------------------------------------
SLASH_ADMINTOOLSRU1 = "/admin"
SLASH_ADMINTOOLSRU2 = "/adt"
SlashCmdList["ADMINTOOLSRU"] = function(msg)
	msg = strtrim(msg or "")
	if msg ~= "" then AT.RunCmd(msg); return end
	if f:IsShown() then f:Hide() else f:Show() end
end

SLASH_ADMINTOOLSRURESET1 = "/atreset"
SlashCmdList["ADMINTOOLSRURESET"] = function()
	AdminToolsDB = nil
	ReloadUI()
end

---------------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name ~= "AdminToolsRU" then return end

	if event == "ADDON_LOADED" then
		AdminToolsDB = AdminToolsDB or {}
		AdminToolsDB.custom = AdminToolsDB.custom or {}
		if AdminToolsDB.pos then
			f:ClearAllPoints()
			f:SetPoint(AdminToolsDB.pos[1], UIParent, AdminToolsDB.pos[2], AdminToolsDB.pos[3], AdminToolsDB.pos[4])
		end
		if AdminToolsDB.refreshCustom then AdminToolsDB.refreshCustom() end
		RestoreMinimapPos()
		return
	end

	if event == "PLAYER_LOGIN" then
		AT.ApplyTabVisibility()
		-- Найти первую видимую вкладку
		local startTab = AdminToolsDB and AdminToolsDB.tab
		if not startTab or not AT.IsTabVisible(startTab) then
			for _, n in ipairs(AT.TABS) do
				if AT.IsTabVisible(n) then startTab = n; break end
			end
		end
		AT.ShowPage(startTab or "Телепорт")
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Admin Tools RU v4.2|r загружен. Кнопка — у миникарты.")
		self:UnregisterEvent("PLAYER_LOGIN")
	end
end)