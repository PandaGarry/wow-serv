--=========================================================================
-- Main.lua - оформление окна, нижняя панель, кнопка на миникарте,
-- слэш-команды и инициализация
--=========================================================================

local f = AT.frame
local T = AT.THEME

f:SetBackdrop({
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile = false,
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
f:SetBackdropColor(T.bg[1], T.bg[2], T.bg[3], T.bg[4])
f:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], T.border[4])
f:SetFrameStrata("HIGH")
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
tinsert(UISpecialFrames, "AdminToolsRUFrame")

-- Заголовок
local titleBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
titleBg:SetTexture(1, 1, 1, 0.04)
titleBg:SetPoint("TOPLEFT", 1, -1)
titleBg:SetPoint("TOPRIGHT", -1, -1)
titleBg:SetHeight(32)

local title = AT.MakeLabel(f, "Admin Tools RU |cff66b3ffv" .. AT.VERSION .. "|r", "GameFontHighlightLarge")
title:SetPoint("TOPLEFT", 14, -9)

local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)

-- Линия под вкладками (позицию выставляет AT.ApplyTabVisibility)
AT.tabLine = f:CreateTexture(nil, "ARTWORK")
AT.tabLine:SetTexture(T.border[1], T.border[2], T.border[3], 1)
AT.tabLine:SetHeight(1)

---------------------------------------------------------------------------
-- Нижняя панель команд
---------------------------------------------------------------------------
local bottomLine = f:CreateTexture(nil, "ARTWORK")
bottomLine:SetTexture(T.border[1], T.border[2], T.border[3], 1)
bottomLine:SetHeight(1)
bottomLine:SetPoint("BOTTOMLEFT", 8, AT.BOTTOM_H)
bottomLine:SetPoint("BOTTOMRIGHT", -8, AT.BOTTOM_H)

local cmdLabel = AT.MakeLabel(f, "Команда:", "GameFontNormal")
cmdLabel:SetPoint("BOTTOMLEFT", 16, 18)

local cmdBox = AT.MakeEdit(f)
local runBtn
local function runTyped()
	AT.RunCmd(cmdBox:GetText()); cmdBox:SetText(""); cmdBox:ClearFocus()
end
runBtn = AT.MakeButton(f, "Выполнить", 110, runTyped, nil, "Выполнить команду из поля ввода")
runBtn:SetPoint("BOTTOMRIGHT", -16, 13)
cmdBox:SetHeight(20)
cmdBox:SetPoint("LEFT", cmdLabel, "RIGHT", 14, 0)
cmdBox:SetPoint("RIGHT", runBtn, "LEFT", -10, 0)
cmdBox:SetScript("OnEnterPressed", runTyped)

---------------------------------------------------------------------------
-- Кнопка на миникарте
---------------------------------------------------------------------------
local minimapBtn = CreateFrame("Button", "AdminToolsRUMMBtn", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetMovable(true)
minimapBtn:SetClampedToScreen(true)

local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("TOPLEFT", 7, -5)
icon:SetTexture("Interface\\Icons\\INV_Misc_Wrench_01")
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local border = minimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

minimapBtn:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		if f:IsShown() then f:Hide() else f:Show() end
	else
		f:Show()
		AT.ShowPage("Телепорт")
	end
end)
minimapBtn:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Admin Tools RU", 1, 1, 1)
	GameTooltip:AddLine("ЛКМ — открыть/закрыть панель", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("ПКМ — вкладка «Телепорт»", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Перетащите, чтобы переместить", 0.6, 0.6, 0.6)
	GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
minimapBtn:SetScript("OnDragStart", function(self) self:StartMoving() end)
minimapBtn:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	if AdminToolsDB then AdminToolsDB.minimapPos = { point, relPoint, x, y } end
end)

local function RestoreMinimapPos()
	local p = AdminToolsDB and AdminToolsDB.minimapPos
	if p then
		minimapBtn:ClearAllPoints()
		minimapBtn:SetPoint(p[1], Minimap, p[2], p[3], p[4])
	end
end

---------------------------------------------------------------------------
-- Масштаб окна
---------------------------------------------------------------------------
function AT.ApplyScale()
	local s = (AdminToolsDB and AdminToolsDB.scale) or 1
	f:SetScale(s)
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
AT.ApplyTabVisibility()   -- первичная раскладка (до загрузки настроек)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" then
		if name ~= "AdminToolsRU" then return end
		AdminToolsDB = AdminToolsDB or {}
		AdminToolsDB.custom = AdminToolsDB.custom or {}
		AdminToolsDB.refreshCustom = nil   -- мусор от старых версий
		if AdminToolsDB.pos then
			f:ClearAllPoints()
			f:SetPoint(AdminToolsDB.pos[1], UIParent, AdminToolsDB.pos[2], AdminToolsDB.pos[3], AdminToolsDB.pos[4])
		end
		AT.ApplyScale()
		if AT.RefreshCustom then AT.RefreshCustom() end
		RestoreMinimapPos()
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		AT.ApplyTabVisibility()
		local startTab = AdminToolsDB and AdminToolsDB.tab
		if not startTab or not AT.pages[startTab] or not AT.IsTabVisible(startTab) then
			startTab = nil
			for _, n in ipairs(AT.TABS) do
				if AT.IsTabVisible(n) then startTab = n; break end
			end
		end
		AT.ShowPage(startTab or "Телепорт")
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Admin Tools RU v" .. AT.VERSION .. "|r загружен. /admin или кнопка у миникарты.")
		self:UnregisterEvent("PLAYER_LOGIN")
	end
end)
