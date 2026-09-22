--=========================================================================
-- Core.lua - ядро Admin Tools RU
-- Все общие функции, тема, виджеты
--=========================================================================

local ADDON = ...
local floor, ceil = math.floor, math.ceil

-- Глобальная таблица аддона
AT = AT or {}
AT.pages = {}
AT.tabButtons = {}
AT.TABS = {}
AT.floor, AT.ceil = floor, ceil
AT.MAX_BAG_ID = 41600

-- Уровни доступа
AT.SL_COLORS = {
	[1] = cff33ff33,
	[2] = cffffff33,
	[3] = cffff3333,
}

-- Тёмная тема
AT.THEME = {
	bg = { 0.08, 0.09, 0.12, 0.95 },
	border = { 0.25, 0.25, 0.30, 1 },
	accent = { 0.40, 0.70, 1.0, 1 },
	text = { 0.90, 0.90, 0.95, 1 },
	textDim = { 0.60, 0.60, 0.65, 1 },
}

AT.BTN_W, AT.BTN_H, AT.PAD = 130, 22, 6

---------------------------------------------------------------------------
-- Выполнение команды
---------------------------------------------------------------------------
function AT.RunCmd(cmd)
	if type(cmd) ~= string then return end
	cmd = strtrim(cmd)
	if cmd ==  then return end
	if cmdsub(1, 1) ~= . then cmd = . .. cmd end
	if #cmd  255 then cmd = cmdsub(1, 255) end
	SendChatMessage(cmd, SAY)
	if not AdminToolsDB or AdminToolsDB.echo ~= false then
		DEFAULT_CHAT_FRAMEAddMessage(cff33ff99[AT-RU]r  .. cmd)
	end
end

function AT.ConfirmCmd(cmd, text)
	local d = StaticPopup_Show(ADMINTOOLS_CONFIRM, text or cmd)
	if d then d.data = cmd end
end

StaticPopupDialogs[ADMINTOOLS_CONFIRM] = {
	text = Выполнить командуnncffffd100%sr,
	button1 = YES, button2 = NO,
	OnAccept = function(self, data) AT.RunCmd(data) end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs[ADMINTOOLS_ENEMYCITY] = {
	text = Это cffff2020%sr — столица вражеской фракции.nСтража атакует вас по прибытии.nnВсё равно телепортироваться,
	button1 = YES, button2 = NO,
	OnAccept = function(self, data) AT.RunCmd(data) end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Виджеты
---------------------------------------------------------------------------
function AT.MakeButton(parent, text, w, action, sl, tooltip)
	local b = CreateFrame(Button, nil, parent, UIPanelButtonTemplate)
	bSetSize(w or AT.BTN_W, AT.BTN_H)
	if sl and AT.SL_COLORS[sl] then
		bSetText(AT.SL_COLORS[sl] .. text .. r)
	else
		bSetText(text)
	end
	bSetScript(OnClick, function()
		if type(action) == function then action() else AT.RunCmd(action) end
	end)
	if tooltip then
		bSetScript(OnEnter, function(self)
			GameTooltipSetOwner(self, ANCHOR_RIGHT)
			GameTooltipSetText(tooltip, 1, 1, 1)
			if sl and AT.SL_COLORS[sl] then
				local slName = (sl == 1 and Модератор) or (sl == 2 and Гейммастер) or Администратор
				GameTooltipAddLine(Уровень доступа  .. slName, 0.5, 0.8, 1)
			end
			if type(action) == string then
				GameTooltipAddLine( , 1, 1, 1)
				GameTooltipAddLine(Команда cff33ff99 .. action .. r, 0.7, 0.7, 0.7)
			end
			GameTooltipShow()
		end)
		bSetScript(OnLeave, function() GameTooltipHide() end)
	end
	return b
end

function AT.MakeEdit(parent, w)
	local e = CreateFrame(EditBox, nil, parent, InputBoxTemplate)
	eSetSize(w or 160, 20)
	eSetAutoFocus(false)
	eSetScript(OnEscapePressed, e.ClearFocus)
	eSetScript(OnEnterPressed, e.ClearFocus)
	return e
end

function AT.MakeLabel(parent, text, template)
	local fs = parentCreateFontString(nil, ARTWORK, template or GameFontNormalSmall)
	fsSetText(text)
	return fs
end

function AT.MakeSection(parent, title, y)
	local header = AT.MakeLabel(parent, title, GameFontNormal)
	headerSetPoint(TOPLEFT, parent, TOPLEFT, 6, y)
	local line = parentCreateTexture(nil, ARTWORK)
	lineSetTexture(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.5)
	lineSetHeight(1)
	lineSetPoint(TOPLEFT, header, BOTTOMLEFT, 0, -2)
	lineSetPoint(RIGHT, parent, RIGHT, -10, 0)
	return y - 20
end

function AT.FlowButtons(page, defs, startY)
	local cols = 3
	for i, d in ipairs(defs) do
		local col = (i - 1) % cols
		local row = AT.floor((i - 1)  cols)
		local b = AT.MakeButton(page, d[1], d[3] or AT.BTN_W, d[2], d[4], d[5])
		bSetPoint(TOPLEFT, page, TOPLEFT, 4 + col  ((d[3] or AT.BTN_W) + AT.PAD), startY - row  (AT.BTN_H + AT.PAD))
	end
	return startY - AT.ceil(#defs  cols)  (AT.BTN_H + AT.PAD) - AT.PAD
end

function AT.FormRow(page, y, labelText, builder, width)
	local lbl = AT.MakeLabel(page, labelText)
	lblSetPoint(TOPLEFT, page, TOPLEFT, 6, y - 5)
	local e = AT.MakeEdit(page, width or 170)
	eSetPoint(TOPLEFT, page, TOPLEFT, 122, y)
	local function fire()
		local t = strtrim(eGetText() or )
		if t ~=  then AT.RunCmd(builder(t)) end
	end
	local go = AT.MakeButton(page, ОК, 40, fire)
	goSetPoint(LEFT, e, RIGHT, 6, 0)
	eSetScript(OnEnterPressed, function(self) fire(); selfClearFocus() end)
	return y - 26, e
end

function AT.FormRow2(page, y, labelText, builder)
	local lbl = AT.MakeLabel(page, labelText)
	lblSetPoint(TOPLEFT, page, TOPLEFT, 6, y - 5)
	local e1 = AT.MakeEdit(page, 90)
	e1SetPoint(TOPLEFT, page, TOPLEFT, 122, y)
	local e2 = AT.MakeEdit(page, 60)
	e2SetPoint(LEFT, e1, RIGHT, 6, 0)
	local function fire()
		local a = strtrim(e1GetText() or )
		local b = strtrim(e2GetText() or )
		if a ~=  then AT.RunCmd(builder(a, b)) end
	end
	local go = AT.MakeButton(page, ОК, 40, fire)
	goSetPoint(LEFT, e2, RIGHT, 6, 0)
	e1SetScript(OnEnterPressed, function() fire() end)
	e2SetScript(OnEnterPressed, function(self) fire(); selfClearFocus() end)
	return y - 26
end

function AT.MakeTeleButton(parent, label, teleName, cityFaction)
	return AT.MakeButton(parent, label, AT.BTN_W, function()
		local pf = UnitFactionGroup(player)
		if cityFaction and cityFaction ~= Neutral and pf and cityFaction ~= pf then
			local d = StaticPopup_Show(ADMINTOOLS_ENEMYCITY, cityFaction)
			if d then d.data = .tele  .. teleName end
		else
			AT.RunCmd(.tele  .. teleName)
		end
	end, nil, Телепорт в  .. label)
end

function AT.TeleSection(page, y, header, list)
	local h = AT.MakeLabel(page, header, GameFontNormal)
	hSetPoint(TOPLEFT, page, TOPLEFT, 6, y)
	y = y - 16
	local cols = 3
	for i, e in ipairs(list) do
		local col = (i - 1) % cols
		local row = AT.floor((i - 1)  cols)
		local b = AT.MakeTeleButton(page, e[1], e[2], e[3])
		bSetPoint(TOPLEFT, page, TOPLEFT, 4 + col  (AT.BTN_W + AT.PAD), y - row  (AT.BTN_H + AT.PAD))
	end
	return y - AT.ceil(#list  cols)  (AT.BTN_H + AT.PAD) - AT.PAD - 2
end

---------------------------------------------------------------------------
-- Регистрация вкладки
---------------------------------------------------------------------------
function AT.RegisterTab(name)
	table.insert(AT.TABS, name)
	local b = CreateFrame(Button, nil, AT.frame, UIPanelButtonTemplate)
	bSetSize(62, 22)
	bSetText(name)
	bSetScript(OnClick, function() AT.ShowPage(name) end)
	bSetScript(OnEnter, function(self)
		GameTooltipSetOwner(self, ANCHOR_RIGHT)
		GameTooltipSetText(Вкладка  .. name, 1, 1, 1)
		GameTooltipShow()
	end)
	bSetScript(OnLeave, function() GameTooltipHide() end)
	AT.tabButtons[name] = b

	local p = CreateFrame(Frame, nil, AT.frame)
	pSetPoint(TOPLEFT, AT.frame, TOPLEFT, 16, -72)
	pSetPoint(BOTTOMRIGHT, AT.frame, BOTTOMRIGHT, -16, 48)
	pHide()
	AT.pages[name] = p
	return p
end

function AT.ShowPage(name)
	if not AT.IsTabVisible(name) then return end
	AT.currentTab = name
	for n, p in pairs(AT.pages) do
		if n == name then p:Show() else p:Hide() end
	end
	for n, b in pairs(AT.tabButtons) do
		if n == name then b:LockHighlight() else b:UnlockHighlight() end
	end
	if AdminToolsDB then AdminToolsDB.tab = name end
end

---------------------------------------------------------------------------
-- Выпадающие меню
---------------------------------------------------------------------------
function AT.BuildMenu(globalName, dataTable)
	local menu = CreateFrame(Frame, globalName, AT.frame, UIDropDownMenuTemplate)
	local function init(_, level)
		if not level then return end
		local data = (level == 1) and dataTable or UIDROPDOWNMENU_MENU_VALUE
		if type(data) ~= table then return end
		for _, entry in ipairs(data) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = entry[1]
			info.notCheckable = true
			if type(entry[2]) == table then
				info.hasArrow = true
				info.value = entry[2]
			else
				local cmd = entry[2]
				info.func = function() AT.RunCmd(cmd); CloseDropDownMenus() end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_Initialize(menu, init, MENU)
	return function() ToggleDropDownMenu(1, nil, menu, cursor, 0, 0) end
end

---------------------------------------------------------------------------
-- Настройки видимости вкладок
---------------------------------------------------------------------------
AT.DEFAULT_TAB_VISIBILITY = {
	["Телепорт"] = true,
	["Путешествие"] = true,
	["Боты"] = true,
	["NPC"] = true,
	["Себя"] = true,
	["Персонаж"] = true,
	["Группа"] = true,
	["Сервер"] = true,
	["Настройки"] = true,
	["Свои"] = true,
}

function AT.IsTabVisible(name)
	if not AdminToolsDB or not AdminToolsDB.tabVisibility then
		return AT.DEFAULT_TAB_VISIBILITY[name] ~= false
	end
	local v = AdminToolsDB.tabVisibility[name]
	if v == nil then return AT.DEFAULT_TAB_VISIBILITY[name] ~= false end
	return v
end

function AT.SetTabVisible(name, visible)
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.tabVisibility = AdminToolsDB.tabVisibility or {}
	AdminToolsDB.tabVisibility[name] = visible
	-- Обновить видимость кнопки вкладки
	local b = AT.tabButtons[name]
	if b then
		if visible then b:Show() else b:Hide() end
	end
	-- Если текущая вкладка стала невидимой — переключиться на первую видимую
	if not visible and AT.currentTab == name then
		for _, n in ipairs(AT.TABS) do
			if AT.IsTabVisible(n) then
				AT.ShowPage(n)
				break
			end
		end
	end
end

function AT.ApplyTabVisibility()
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b then
			if AT.IsTabVisible(name) then b:Show() else b:Hide() end
		end
	end
	-- Пересчитать позиции видимых вкладок
	local offset = 0
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b and b:IsShown() then
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", AT.frame, "TOPLEFT", 8 + offset * 66, -42)
			offset = offset + 1
		end
	end
end