--===========================================================================
-- Admin Tools RU — Main.lua
-- Заголовок окна, нижняя панель команд, кнопка на миникарте,
-- слэш-команды и обработка событий.
-- Загружается ПОСЛЕДНИМ (см. .toc): только здесь все вкладки уже созданы.
--===========================================================================

-- Заголовок для окна назначения клавиш (используется в Bindings.xml)
ADMINTOOLSRU_BINDING_HEADER = "Admin Tools RU"

local frame = AT.frame

--===========================================================================
-- Заголовок и кнопка закрытия
--===========================================================================
local title = AT.MakeLabel(frame, "Admin Tools RU v" .. AT.VERSION, "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -14)

local subtitle = AT.MakeLabel(frame, "GM-панель · AzerothCore 3.3.5", "GameFontDisableSmall")
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -6, -6)

-- Разделитель под вкладками
local sep = frame:CreateTexture(nil, "ARTWORK")
sep:SetTexture(AT.THEME.border[1], AT.THEME.border[2], AT.THEME.border[3], 0.6)
sep:SetHeight(1)
sep:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -70)
sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -70)

--===========================================================================
-- Нижняя панель: быстрый ввод команды + история
--===========================================================================
local cmdLabel = AT.MakeLabel(frame, "Команда:")
cmdLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)

local cmdBox = CreateFrame("EditBox", "AdminToolsRUCmdBox", frame, "InputBoxTemplate")
cmdBox:SetSize(380, 20)
cmdBox:SetPoint("LEFT", cmdLabel, "RIGHT", 10, 0)
cmdBox:SetAutoFocus(false)
cmdBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local histIndex = 0

local function RunFromBox()
	AT.RunCmd(cmdBox:GetText())
	cmdBox:SetText("")
	histIndex = 0
end

local function NavigateHistory(step)
	if #AT.history == 0 then return end
	histIndex = histIndex + step
	if histIndex < 1 then histIndex = 1 end
	if histIndex > #AT.history then
		histIndex = #AT.history + 1
		cmdBox:SetText("")
		return
	end
	cmdBox:SetText(AT.history[histIndex] or "")
end

cmdBox:SetScript("OnEnterPressed", function(self)
	RunFromBox()
	self:ClearFocus()
end)

-- Стрелки вверх/вниз для истории: OnArrowPressed поддержан не всеми сборками
-- клиента, поэтому оборачиваем в pcall и дублируем кнопками ▲/▼.
pcall(function()
	cmdBox:SetScript("OnArrowPressed", function(self, key)
		if key == "UP" then NavigateHistory(1)
		elseif key == "DOWN" then NavigateHistory(-1) end
	end)
end)

local runBtn = AT.MakeButton(frame, "Выполнить", 90, RunFromBox, nil, "Выполнить команду из поля ввода")
runBtn:SetPoint("LEFT", cmdBox, "RIGHT", 8, 0)

local upBtn = AT.MakeButton(frame, "▲", 26, function() NavigateHistory(1) end, nil,
	"Предыдущая команда")
upBtn:SetPoint("LEFT", runBtn, "RIGHT", 8, 0)

local downBtn = AT.MakeButton(frame, "▼", 26, function() NavigateHistory(-1) end, nil,
	"Следующая команда")
downBtn:SetPoint("LEFT", upBtn, "RIGHT", 4, 0)

-- Счётчик истории (обновляем текст только при изменении длины)
local histLabel = AT.MakeLabel(frame, "", "GameFontDisableSmall")
histLabel:SetPoint("LEFT", downBtn, "RIGHT", 8, 0)
local histShown = -1
histLabel:SetScript("OnUpdate", function(self)
	local count = #AT.history
	if count ~= histShown then
		histShown = count
		self:SetText(count > 0 and ("история: " .. count) or "")
	end
end)

--===========================================================================
-- Кнопка на миникарте
--===========================================================================
local mmBtn = CreateFrame("Button", "AdminToolsRUMMBtn", Minimap)
mmBtn:SetSize(28, 28)
mmBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 4, 4)
mmBtn:SetFrameStrata("MEDIUM")
mmBtn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
mmBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmBtn:RegisterForDrag("LeftButton")
mmBtn:SetMovable(true)
mmBtn:SetClampedToScreen(true)

local mmIcon = mmBtn:CreateTexture(nil, "BACKGROUND")
mmIcon:SetSize(20, 20)
mmIcon:SetPoint("CENTER")
mmIcon:SetTexture("Interface\\Icons\\INV_Misc_Wrench_01")
mmBtn.icon = mmIcon

local mmBorder = mmBtn:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(54, 54)
mmBorder:SetPoint("TOPLEFT", -2, 2)
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

mmBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

mmBtn:SetScript("OnClick", function(self, button)
	if button == "RightButton" then
		AT.frame:Show()
		AT.ShowPage("Телепорт")
	else
		AT.Toggle()
	end
end)

mmBtn:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Admin Tools RU v" .. AT.VERSION, 1, 1, 1)
	GameTooltip:AddLine("ЛКМ — открыть/закрыть панель", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("ПКМ — вкладка «Телепорт»", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Перетащи — переместить кнопку", 0.6, 0.6, 0.6)
	GameTooltip:Show()
end)
mmBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

mmBtn:SetScript("OnDragStart", function(self) self:StartMoving() end)
mmBtn:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	if AdminToolsDB then AdminToolsDB.minimapPos = { point, relPoint, x, y } end
end)

function AT.RestoreMinimapPos()
	if not mmBtn then return end
	if AdminToolsDB and AdminToolsDB.minimapPos then
		local p = AdminToolsDB.minimapPos
		if p[1] and p[2] then
			mmBtn:ClearAllPoints()
			mmBtn:SetPoint(p[1], Minimap, p[2], p[3] or 0, p[4] or 0)
		end
	end
end

--===========================================================================
-- Слэш-команды
--===========================================================================
local function PrintHelp()
	AT.Print("|cffffd100Admin Tools RU v" .. AT.VERSION .. "|r — панель GM-команд")
	AT.Print("|cff33ff99/admin|r — открыть/закрыть панель")
	AT.Print("|cff33ff99/admin <команда>|r — выполнить команду, напр. |cffaaaaaa/admin tele stormwind|r")
	AT.Print("|cff33ff99/adt|r — то же, что /admin")
	AT.Print("|cff33ff99/ath|r — эта справка")
	AT.Print("|cff33ff99/atecho|r — вкл/выкл эхо выполненных команд")
	AT.Print("|cff33ff99/atreset|r — сбросить все настройки аддона")
	AT.Print("Кнопка на миникарте: ЛКМ — панель, ПКМ — телепорт.")
end

SLASH_ADMINTOOLSRU1 = "/admin"
SLASH_ADMINTOOLSRU2 = "/adt"
SlashCmdList["ADMINTOOLSRU"] = function(msg)
	msg = AT.trim(msg or "")
	if msg ~= "" then
		AT.RunCmd(msg)
		return
	end
	AT.Toggle()
end

SLASH_ADMINTOOLSRUHELP1 = "/ath"
SLASH_ADMINTOOLSRUHELP2 = "/adminhelp"
SlashCmdList["ADMINTOOLSRUHELP"] = function() PrintHelp() end

SLASH_ADMINTOOLSRUECHO1 = "/atecho"
SlashCmdList["ADMINTOOLSRUECHO"] = function()
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.echo = not AT.EchoEnabled()
	AT.Print("Эхо команд: " .. (AT.EchoEnabled() and "|cff33ff99включено|r" or "|cffff5555выключено|r"))
end

SLASH_ADMINTOOLSRURESET1 = "/atreset"
SlashCmdList["ADMINTOOLSRURESET"] = function()
	AdminToolsDB = nil
	ReloadUI()
end

--===========================================================================
-- Инициализация
--===========================================================================
local DEFAULTS = {
	echo = true,
	restrictBySec = false,
	mySec = 3,
	scale = 1.0,
	tabVisibility = {},
	custom = {},
	history = {},
}

local function InitDB()
	if type(AdminToolsDB) ~= "table" then AdminToolsDB = {} end
	for k, v in pairs(DEFAULTS) do
		if AdminToolsDB[k] == nil then
			if type(v) == "table" then
				local copy = {}
				for kk, vv in pairs(v) do copy[kk] = vv end
				AdminToolsDB[k] = copy
			else
				AdminToolsDB[k] = v
			end
		end
	end
	AT.history = AdminToolsDB.history or {}
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= AT.ADDON_NAME then return end

		InitDB()

		-- позиция окна
		if AdminToolsDB.pos then
			local p = AdminToolsDB.pos
			if p[1] and p[2] then
				frame:ClearAllPoints()
				frame:SetPoint(p[1], UIParent, p[2], p[3] or 0, p[4] or 0)
			end
		end

		AT.SetScale(AdminToolsDB.scale)
		AT.RestoreMinimapPos()

		-- кнопка на миникарте могла быть скрыта в настройках
		if AdminToolsDB.minimapHidden and mmBtn then
			mmBtn:Hide()
		end

		-- перечитать сохранённые настройки в элементы вкладок
		if AT.refreshCustom then AT.refreshCustom() end
		if AT.RefreshSettings then AT.RefreshSettings() end

		self:UnregisterEvent("ADDON_LOADED")
		return
	end

	if event == "PLAYER_LOGIN" then
		AT.ApplyTabVisibility()

		-- высота прокрутки каждой вкладки (в этот момент координаты уже верны)
		for _, name in ipairs(AT.TABS) do
			if AT.pages[name] then AT.FitPage(AT.pages[name]) end
		end

		local startTab = AdminToolsDB.tab
		if not startTab or not AT.IsTabVisible(startTab) then
			for _, n in ipairs(AT.TABS) do
				if AT.IsTabVisible(n) then startTab = n break end
			end
		end
		AT.ShowPage(startTab or "Телепорт")

		AT.Print("v" .. AT.VERSION .. " загружен. |cffaaaaaa/admin|r — панель, |cffaaaaaa/ath|r — справка.")
		self:UnregisterEvent("PLAYER_LOGIN")
	end
end)
