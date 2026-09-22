--===========================================================================
-- Admin Tools RU — Main.lua
-- Шапка окна, строка «Избранное», нижняя панель команд, кнопка на миникарте,
-- слэш-команды и обработка событий.
-- Загружается ПОСЛЕДНИМ (см. .toc): только здесь все вкладки уже созданы.
--===========================================================================

ADMINTOOLSRU_BINDING_HEADER = "Admin Tools RU"

local frame = AT.frame

-- профайлер: в игре есть debugprofilestop(), в тестах — GetTime()
local profiler = debugprofilestop or function()
	return (GetTime and GetTime() or 0) * 1000
end

--===========================================================================
-- Шапка
--===========================================================================
local title = AT.MakeLabel(frame, "Admin Tools RU", "GameFontHighlightLarge")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -12)

local version = AT.MakeLabel(frame, "v" .. AT.VERSION, "GameFontDisableSmall")
version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 2)

local subtitle = AT.MakeLabel(frame, "AzerothCore - NPCBots + Extras - Custom Races", "GameFontDisableSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
close:SetScale(0.9)

--===========================================================================
-- Строка избранного (Shift+ЛКМ по любой кнопке-команде)
--===========================================================================
local favRow = CreateFrame("Frame", nil, frame)
favRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
favRow:SetSize(AT.WIN_W - 60, 42)
AT.favoritesRow = favRow

local favTitle = AT.MakeLabel(favRow, "Избранное:", "GameFontNormalSmall")
favTitle:SetPoint("TOPLEFT", favRow, "TOPLEFT", 0, -2)

local favArea = CreateFrame("Frame", nil, favRow)
favArea:SetPoint("TOPLEFT", favRow, "TOPLEFT", 88, 0)
favArea:SetSize(AT.WIN_W - 140, 42)
favRow.hint = AT.MakeLabel(favArea, "пусто — наведи на кнопку и нажми Shift+ЛКМ, чтобы добавить",
	"GameFontDisableSmall")
favRow.hint:SetPoint("TOPLEFT", favArea, "TOPLEFT", 0, -2)

-- кнопки избранного создаются в AT.RefreshFavorites() внутри этой области
AT.favoritesAnchor = favArea

--===========================================================================
-- Разделители и заголовок раздела
--===========================================================================
AT.MakeLine(frame, -82, 14, -14)

--===========================================================================
-- Нижняя панель: быстрый ввод команды + история
--===========================================================================
-- линия над панелью команд (PAGE_BOTTOM отсчитывается от низа окна)
AT.MakeLine(frame, -(AT.WIN_H - AT.PAGE_BOTTOM) + 2, 14, -14)

local cmdLabel = AT.MakeLabel(frame, "Команда:", "GameFontNormalSmall")
cmdLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)

local cmdBox = CreateFrame("EditBox", "AdminToolsRUCmdBox", frame, "InputBoxTemplate")
cmdBox:SetSize(430, 20)
cmdBox:SetPoint("LEFT", cmdLabel, "RIGHT", 10, 0)
cmdBox:SetAutoFocus(false)
cmdBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

function AT.SetCommandBox(text)
	if not cmdBox then return end
	cmdBox:SetText(text or "")
	cmdBox:SetFocus()
	cmdBox:HighlightText()
end

function AT.GetCommandBox()
	return cmdBox
end

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

pcall(function()
	cmdBox:SetScript("OnArrowPressed", function(self, key)
		if key == "UP" then NavigateHistory(1)
		elseif key == "DOWN" then NavigateHistory(-1) end
	end)
end)

local runBtn = AT.MakeButton(frame, "Выполнить", 90, RunFromBox, nil, "Выполнить команду из поля ввода")
runBtn:SetPoint("LEFT", cmdBox, "RIGHT", 8, 0)

-- Символы ▲/▼ есть не во всех шрифтах 3.3.5, поэтому подписи текстом
local upBtn = AT.MakeButton(frame, "Вверх", 58, function() NavigateHistory(1) end, nil, "Предыдущая команда")
upBtn:SetPoint("LEFT", runBtn, "RIGHT", 8, 0)

local downBtn = AT.MakeButton(frame, "Вниз", 58, function() NavigateHistory(-1) end, nil, "Следующая команда")
downBtn:SetPoint("LEFT", upBtn, "RIGHT", 4, 0)

-- Счётчик истории.
-- ВАЖНО: MakeLabel возвращает FontString, а у FontString в WoW нет SetScript
-- (скрипты есть только у фреймов). Поэтому счётчик обновляется по событию —
-- при изменении истории вызывается AT.UpdateHistoryLabel() из Core.PushHistory.
local histLabel = AT.MakeLabel(frame, "", "GameFontDisableSmall")
histLabel:SetPoint("LEFT", downBtn, "RIGHT", 8, 0)
AT.histLabel = histLabel

function AT.UpdateHistoryLabel()
	if not AT.histLabel then return end
	local count = #AT.history
	AT.histLabel:SetText(count > 0 and ("история: " .. count) or "")
end

--===========================================================================
-- Shift+ЛКМ по нику игрока в чате → имя попадает в поле ввода команды
-- (удобно для .kick, .summon, .ban — не надо набирать ник руками)
--===========================================================================
local function OnChatLinkClick(link, text, button)
	if not IsShiftKeyDown() then return end
	if type(link) ~= "string" or not link:find("player:", 1, true) then return end

	local name = text and text:match("%[(.-)%]")
	if not name or name == "" then return end

	local box = AT.GetCommandBox and AT.GetCommandBox()
	if not box then return end

	local current = AT.trim(box:GetText() or "")
	box:SetText(current == "" and name or (current .. " " .. name))
	box:SetFocus()
	box:HighlightText()
	AT.Print("Имя в поле ввода: |cff2fd6ff" .. name .. "|r")
end

if SetItemRef and hooksecurefunc then
	hooksecurefunc("SetItemRef", OnChatLinkClick)
end

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

-- кнопка нужна ядру для установки угла и скрытия (вкладка «Интерфейс»)
AT.minimapButton = mmBtn

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
	if AdminToolsDB then
		AdminToolsDB.minimapPos = { point, relPoint, x, y }
		AdminToolsDB.minimapAngle = nil   -- ручная позиция важнее угла
	end
end)

function AT.RestoreMinimapPos()
	if not mmBtn then return end

	-- 1) угол на окружности (вкладка «Интерфейс»)
	local angle = AT.GetMinimapAngle()
	if angle and angle >= 0 then
		AT.SetMinimapAngle(angle)
		return
	end

	-- 2) позиция, куда игрок сам перетащил кнопку
	if AdminToolsDB and AdminToolsDB.minimapPos then
		local pos = AdminToolsDB.minimapPos
		if pos[1] and pos[2] then
			mmBtn:ClearAllPoints()
			mmBtn:SetPoint(pos[1], Minimap, pos[2], pos[3] or 0, pos[4] or 0)
		end
	end
end

--===========================================================================
-- Диагностика производительности (встроенная, без внешних аддонов)
--===========================================================================
function AT.Bench()
	local lines = {}

	local t0 = profiler()
	local switches = 0
	for _, name in ipairs(AT.TABS) do
		AT.ShowPage(name)
		switches = switches + 1
	end
	local switchMs = profiler() - t0

	t0 = profiler()
	local buttons = 0
	local fonts = 0
	for _, name in ipairs(AT.TABS) do
		local page = AT.pages[name]
		if page then
			AT.FitPage(page)
			for _, child in ipairs(page:GetChildren()) do
				if child.__kind == "Button" then buttons = buttons + 1 end
			end
		end
	end
	local layoutMs = profiler() - t0

	for fs in pairs(AT.fontRegistry) do fonts = fonts + 1 end

	AT.Print("|cffffd100Производительность панели|r")
	AT.Print(("Переключение %d вкладок: |cff2fd6ff%.2f мс|r (%.2f мс на вкладку)")
		:format(switches, switchMs, switchMs / math.max(1, switches)))
	AT.Print(("Пересчёт высоты %d вкладок: |cff2fd6ff%.2f мс|r"):format(#AT.TABS, layoutMs))
	AT.Print(("Кнопок на всех вкладках: |cff2fd6ff%d|r, шрифтов в реестре: |cff2fd6ff%d|r")
		:format(buttons, fonts))
	AT.Print("Память клиента: " .. (GetAddOnMemoryUsage
		and ("|cff2fd6ff" .. ("%.0f"):format(GetAddOnMemoryUsage(AT.ADDON_NAME)) .. " КБ|r")
		or "недоступно"))

	if AT.currentTab then AT.ShowPage(AT.currentTab) end
end

--===========================================================================
-- Слэш-команды
--===========================================================================
local function PrintHelp()
	AT.Print("|cffffd100Admin Tools RU v" .. AT.VERSION .. "|r — GM-панель для AzerothCore 3.3.5")
	AT.Print("|cff2fd6ff/admin|r — открыть/закрыть панель")
	AT.Print("|cff2fd6ff/admin <команда>|r — выполнить команду, напр. |cffaaaaaa/admin tele stormwind|r")
	AT.Print("|cff2fd6ff/adt|r — то же, что /admin")
	AT.Print("|cff2fd6ff/ath|r — эта справка, |cff2fd6ff/atbench|r — замер скорости панели")
	AT.Print("|cff2fd6ff/atecho|r — вкл/выкл эхо команд, |cff2fd6ff/atreset|r — сбросить настройки")
	AT.Print("В панели: |cffaaaaaaShift+ЛКМ|r по кнопке — в избранное, |cffaaaaaaПКМ|r — команда в поле ввода.")
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

SLASH_ADMINTOOLSRUBENCH1 = "/atbench"
SlashCmdList["ADMINTOOLSRUBENCH"] = function() AT.Bench() end

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
	theme = "cyan",
	windowSize = 2,
	tooltips = true,
	rowHighlight = true,
	filters = true,
	echo = true,
	restrictBySec = false,
	mySec = 3,
	scale = 1.0,
	fontSize = 0,
	tabVisibility = {},
	custom = {},
	favorites = {},
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

		if AdminToolsDB.pos then
			local p = AdminToolsDB.pos
			if p[1] and p[2] then
				frame:ClearAllPoints()
				frame:SetPoint(p[1], UIParent, p[2], p[3] or 0, p[4] or 0)
			end
		end

		AT.SetScale(AdminToolsDB.scale)
		AT.ApplyTheme(AT.GetThemeKey(), true)
		AT.SetWindowSize(AT.GetWindowSize())
		AT.SetFontSizeDelta(AdminToolsDB.fontSize or 0)
		AT.RestoreMinimapPos()

		if not AT.IsMinimapShown() and mmBtn then mmBtn:Hide() end

		if AT.refreshCustom then AT.refreshCustom() end
		if AT.RefreshSettings then AT.RefreshSettings() end
		if AT.RefreshInterfaceSettings then AT.RefreshInterfaceSettings() end
		AT.RefreshFavorites()
		AT.RefreshLocks()

		self:UnregisterEvent("ADDON_LOADED")
		return
	end

	if event == "PLAYER_LOGIN" then
		AT.ApplyTabVisibility()

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
		AT.RefreshFavorites()

		AT.Print("v" .. AT.VERSION .. " готов. |cffaaaaaa/admin|r — панель, |cffaaaaaa/ath|r — справка.")
		self:UnregisterEvent("PLAYER_LOGIN")
	end
end)

-- Флаг для автотестов: Main.lua выполнился до конца (значит, слэш-команды,
-- кнопка миникарты и панель команд созданы).
AT.loaded = true
