--===========================================================================
-- Admin Tools RU — Core.lua
-- Ядро аддона: тема, виджеты, запуск GM-команд, реестр вкладок, прокрутка.
--
-- ВАЖНО: этот файл создаёт главное окно (AT.frame) ДО того, как вкладки
-- зарегистрируются. Поэтому Core.lua обязан идти первым в .toc.
--===========================================================================

AT = AT or {}

AT.ADDON_NAME = "AdminToolsRU"
AT.VERSION    = "5.0.0"
AT.PREFIX     = "|cff33ff99[AT-RU]|r "

local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
AT.floor, AT.ceil = floor, ceil

--===========================================================================
-- Утилиты
--===========================================================================

-- Свой trim: не зависим от глобального strtrim (его нет в обычном Lua,
-- а в игре он есть — но так модуль тестируется вне игры).
function AT.trim(s)
	if type(s) ~= "string" then return "" end
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Сообщение в чат (всегда).
function AT.Print(msg)
	if not DEFAULT_CHAT_FRAME then return end
	DEFAULT_CHAT_FRAME:AddMessage(AT.PREFIX .. tostring(msg))
end

-- Сообщение об ошибке.
function AT.PrintErr(msg)
	if not DEFAULT_CHAT_FRAME then return end
	DEFAULT_CHAT_FRAME:AddMessage(AT.PREFIX .. "|cffff5555" .. tostring(msg) .. "|r")
end

--===========================================================================
-- Уровни доступа (GM security level)
--===========================================================================
AT.SEC_NAMES = {
	[0] = "Игрок",
	[1] = "Модератор",
	[2] = "Гейммастер",
	[3] = "Администратор",
}

AT.SEC_COLORS = {
	[0] = "|cff9d9d9d",
	[1] = "|cff33ff33",
	[2] = "|cffffff33",
	[3] = "|cffff3333",
}

function AT.SecName(sec)
	local name = AT.SEC_NAMES[sec or 0] or "?"
	return (AT.SEC_COLORS[sec or 0] or "") .. name .. "|r"
end

-- Мой уровень доступа (настраивается во вкладке «Настройки»).
function AT.GetMySec()
	if AdminToolsDB and AdminToolsDB.mySec then return AdminToolsDB.mySec end
	return 3
end

-- Заблокирована ли кнопка для текущего уровня доступа.
function AT.IsLocked(sec)
	if not sec then return false end
	if not (AdminToolsDB and AdminToolsDB.restrictBySec) then return false end
	return AT.GetMySec() < sec
end

--===========================================================================
-- Тема
--===========================================================================
AT.THEME = {
	bg      = { 0.06, 0.07, 0.10, 0.96 },
	border  = { 0.25, 0.25, 0.30, 1.00 },
	accent  = { 0.40, 0.70, 1.00, 1.00 },
	text    = { 0.92, 0.92, 0.96, 1.00 },
	textDim = { 0.60, 0.60, 0.65, 1.00 },
}

AT.WIN_W, AT.WIN_H = 660, 600
AT.BTN_W, AT.BTN_H, AT.PAD = 142, 22, 6
AT.FLOW_COLS = 4          -- колонок в AT.FlowButtons
AT.TELE_COLS = 3          -- колонок в AT.TeleSection
AT.PAGE_TOP, AT.PAGE_BOTTOM = -72, 48
AT.PAGE_PAD = 16

--===========================================================================
-- Главное окно (создаётся здесь — вкладки подключаются к нему сразу)
--===========================================================================
local frame = CreateFrame("Frame", "AdminToolsRUFrame", UIParent)
AT.frame = frame
frame:SetSize(AT.WIN_W, AT.WIN_H)
frame:SetPoint("CENTER")
frame:SetBackdrop({
	bgFile   = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile     = false,
	edgeSize = 1,
	insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})
frame:SetBackdropColor(AT.THEME.bg[1], AT.THEME.bg[2], AT.THEME.bg[3], AT.THEME.bg[4])
frame:SetBackdropBorderColor(AT.THEME.border[1], AT.THEME.border[2], AT.THEME.border[3], AT.THEME.border[4])
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	if AdminToolsDB then AdminToolsDB.pos = { point, relPoint, x, y } end
end)
frame:Hide()
tinsert(UISpecialFrames, "AdminToolsRUFrame")

AT.pages = {}         -- [имя вкладки] = прокручиваемый контейнер (scroll child)
AT.scrolls = {}       -- [имя вкладки] = сам ScrollFrame
AT.tabButtons = {}    -- [имя вкладки] = кнопка вкладки
AT.TABS = {}          -- порядок вкладок
AT.pageBottom = {}    -- [page] = самая нижняя занятая Y (отрицательная)

--===========================================================================
-- Запуск команд
--===========================================================================

AT.HISTORY_MAX = 30
AT.history = {}

function AT.PushHistory(cmd)
	if type(cmd) ~= "string" or cmd == "" then return end
	for i = #AT.history, 1, -1 do
		if AT.history[i] == cmd then table.remove(AT.history, i) end
	end
	table.insert(AT.history, 1, cmd)
	while #AT.history > AT.HISTORY_MAX do table.remove(AT.history) end
	if AdminToolsDB then AdminToolsDB.history = AT.history end
end

function AT.EchoEnabled()
	if not AdminToolsDB then return true end
	return AdminToolsDB.echo ~= false
end

-- Отправить GM-команду. Принимает "tele x" или ".tele x".
function AT.RunCmd(cmd)
	if type(cmd) ~= "string" then return end
	cmd = AT.trim(cmd)
	if cmd == "" then return end
	if cmd:sub(1, 1) ~= "." and cmd:sub(1, 1) ~= "#" then
		cmd = "." .. cmd
	end
	if #cmd > 255 then cmd = cmd:sub(1, 255) end
	SendChatMessage(cmd, "SAY")
	AT.PushHistory(cmd)
	if AT.EchoEnabled() then
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(AT.PREFIX .. "|cff888888>|r |cff33ff99" .. cmd .. "|r")
		end
	end
end

--===========================================================================
-- Подтверждения (StaticPopup)
--===========================================================================
AT.POPUP_CONFIRM   = "ADMINTOOLS_CONFIRM"
AT.POPUP_ENEMYCITY = "ADMINTOOLS_ENEMYCITY"
AT.POPUP_DELCUSTOM = "ADMINTOOLS_DELCUSTOM"

StaticPopupDialogs[AT.POPUP_CONFIRM] = {
	text = "Выполнить команду?\n\n|cffffd100%s|r",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data) AT.RunCmd(data) end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs[AT.POPUP_ENEMYCITY] = {
	text = "Это |cffff2020%s|r — столица вражеской фракции.\n"
		.. "Стража атакует вас по прибытии.\n\nВсё равно телепортироваться?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data) AT.RunCmd(data) end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs[AT.POPUP_DELCUSTOM] = {
	text = "Удалить кнопку «|cffffd100%s|r»?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		if type(data) == "number" and AdminToolsDB and AdminToolsDB.custom then
			table.remove(AdminToolsDB.custom, data)
			if AdminToolsDB.refreshCustom then AdminToolsDB.refreshCustom() end
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- Диалог подтверждения. cmd — команда, text — своя формулировка (необязательно).
function AT.ConfirmCmd(cmd, text)
	local dialog = StaticPopup_Show(AT.POPUP_CONFIRM, text or cmd)
	if dialog then dialog.data = cmd end
	return dialog
end

--===========================================================================
-- Виджеты
--===========================================================================
function AT.MakeButton(parent, text, w, action, sec, tooltip)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w or AT.BTN_W, AT.BTN_H)

	if sec and AT.SEC_COLORS[sec] then
		b:SetText(AT.SEC_COLORS[sec] .. text .. "|r")
	else
		b:SetText(text)
	end

	b:SetScript("OnClick", function(self)
		if AT.IsLocked(sec) then
			AT.PrintErr("Недостаточно прав: нужно «" .. (AT.SEC_NAMES[sec] or "?") .. "».")
			return
		end
		if type(action) == "function" then
			action(self)
		else
			AT.RunCmd(action)
		end
	end)

	if tooltip then
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(tooltip, 1, 1, 1)
			if sec then
				GameTooltip:AddLine("Уровень доступа: " .. AT.SecName(sec), 0.6, 0.8, 1)
			end
			if type(action) == "string" then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Команда: |cff33ff99" .. action .. "|r", 0.7, 0.7, 0.7)
			end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end

	return b
end

function AT.MakeEdit(parent, w)
	local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	e:SetSize(w or 170, 20)
	e:SetAutoFocus(false)
	e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	return e
end

function AT.MakeLabel(parent, text, template)
	local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormalSmall")
	fs:SetText(text)
	return fs
end

-- Учёт нижней границы контента страницы (для авто-высоты прокрутки).
function AT.NoteY(page, y)
	if type(y) ~= "number" then return end
	local cur = AT.pageBottom[page]
	if not cur or y < cur then AT.pageBottom[page] = y end
end

-- Пересчитать высоту страницы: по учтённым Y + по фактическому низу виджетов.
function AT.FitPage(page)
	local lowest = AT.pageBottom[page]

	local top = page.GetTop and page:GetTop()
	if top then
		for _, child in ipairs({ page:GetChildren() }) do
			if child.GetBottom and child:IsShown() then
				local bottom = child:GetBottom()
				if bottom and bottom < top then
					local y = bottom - top
					if not lowest or y < lowest then lowest = y end
				end
			end
		end
	end

	local height = -(lowest or 0) + 24
	local scroll = AT.scrollOfPage and AT.scrollOfPage[page]
	if scroll and scroll.GetHeight and scroll:GetHeight() and height < scroll:GetHeight() then
		height = scroll:GetHeight()
	end
	if height < 1 then height = 1 end
	page:SetHeight(height)
	return height
end

function AT.MakeSection(page, title, y)
	local header = AT.MakeLabel(page, title, "GameFontNormal")
	header:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y)

	local line = page:CreateTexture(nil, "ARTWORK")
	line:SetTexture(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.35)
	line:SetHeight(1)
	line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
	line:SetPoint("RIGHT", page, "RIGHT", -10, 0)

	AT.NoteY(page, y - 20)
	return y - 20
end

-- Сетка кнопок. defs = { {текст, действие, ширина, уровень доступа, подсказка}, ... }
-- Возвращает Y для следующего блока.
function AT.FlowButtons(page, defs, startY, cols)
	if type(defs) ~= "table" or #defs == 0 then return startY end
	cols = cols or AT.FLOW_COLS

	local pageW = page:GetWidth() or 598
	if pageW <= 0 then pageW = 598 end

	local cellW = AT.BTN_W
	for _, d in ipairs(defs) do
		if (d[3] or AT.BTN_W) > cellW then cellW = d[3] or AT.BTN_W end
	end
	-- не даём колонкам вылезти за пределы страницы
	local fit = floor((pageW - 4 + AT.PAD) / (cellW + AT.PAD))
	if fit < 1 then fit = 1 end
	if cols > fit then cols = fit end

	for i, d in ipairs(defs) do
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)
		local b = AT.MakeButton(page, d[1], d[3] or AT.BTN_W, d[2], d[4], d[5])
		b:SetPoint("TOPLEFT", page, "TOPLEFT",
			4 + col * (cellW + AT.PAD),
			startY - row * (AT.BTN_H + AT.PAD))
	end

	local rows = ceil(#defs / cols)
	local newY = startY - rows * (AT.BTN_H + AT.PAD) - AT.PAD
	AT.NoteY(page, newY)
	return newY
end

-- Строка формы: подпись + поле + кнопка «OK». builder(text) -> команда.
function AT.FormRow(page, y, labelText, builder, width)
	local lbl = AT.MakeLabel(page, labelText)
	lbl:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y - 5)

	local edit = AT.MakeEdit(page, width or 240)
	edit:SetPoint("TOPLEFT", page, "TOPLEFT", 150, y)

	local function fire()
		local text = AT.trim(edit:GetText())
		if text ~= "" then AT.RunCmd(builder(text)) end
	end

	local go = AT.MakeButton(page, "OK", 40, fire)
	go:SetPoint("LEFT", edit, "RIGHT", 6, 0)

	edit:SetScript("OnEnterPressed", function(self)
		fire()
		self:ClearFocus()
	end)

	AT.NoteY(page, y - 26)
	return y - 26, edit
end

-- Строка формы с двумя полями. builder(a, b) -> команда.
function AT.FormRow2(page, y, labelText, builder)
	local lbl = AT.MakeLabel(page, labelText)
	lbl:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y - 5)

	local e1 = AT.MakeEdit(page, 140)
	e1:SetPoint("TOPLEFT", page, "TOPLEFT", 150, y)
	local e2 = AT.MakeEdit(page, 70)
	e2:SetPoint("LEFT", e1, "RIGHT", 6, 0)

	local function fire()
		local a = AT.trim(e1:GetText())
		local b = AT.trim(e2:GetText())
		if a ~= "" then AT.RunCmd(builder(a, b)) end
	end

	local go = AT.MakeButton(page, "OK", 40, fire)
	go:SetPoint("LEFT", e2, "RIGHT", 6, 0)

	e1:SetScript("OnEnterPressed", function() fire() end)
	e2:SetScript("OnEnterPressed", function(self)
		fire()
		self:ClearFocus()
	end)

	AT.NoteY(page, y - 26)
	return y - 26
end

--===========================================================================
-- Телепорт-кнопки и секции
--===========================================================================
function AT.MakeTeleButton(parent, label, teleName, cityFaction)
	return AT.MakeButton(parent, label, AT.BTN_W, function()
		local cmd = ".tele " .. teleName
		local playerFaction = UnitFactionGroup("player")
		if cityFaction and cityFaction ~= "Neutral" and playerFaction and cityFaction ~= playerFaction then
			local dialog = StaticPopup_Show(AT.POPUP_ENEMYCITY, cityFaction)
			if dialog then dialog.data = cmd end
		else
			AT.RunCmd(cmd)
		end
	end, nil, "Телепорт в " .. label .. "\n|cff888888.tele " .. teleName .. "|r")
end

-- list = { {подпись, имя телепорта, фракция}, ... }
function AT.TeleSection(page, y, header, list)
	local h = AT.MakeLabel(page, header, "GameFontNormal")
	h:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y)
	y = y - 16

	local cols = AT.TELE_COLS
	for i, e in ipairs(list) do
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)
		local b = AT.MakeTeleButton(page, e[1], e[2], e[3])
		b:SetPoint("TOPLEFT", page, "TOPLEFT",
			4 + col * (AT.BTN_W + AT.PAD),
			y - row * (AT.BTN_H + AT.PAD))
	end

	local newY = y - ceil(#list / cols) * (AT.BTN_H + AT.PAD) - AT.PAD - 2
	AT.NoteY(page, newY)
	return newY
end

--===========================================================================
-- Регистрация вкладок
-- Каждая вкладка получает прокручиваемую страницу и рисует в неё.
--===========================================================================
AT.scrollOfPage = {}

function AT.RegisterTab(name)
	table.insert(AT.TABS, name)
	local index = #AT.TABS

	-- Кнопка вкладки
	local b = CreateFrame("Button", "AdminToolsRUTab" .. index, frame, "UIPanelButtonTemplate")
	b:SetSize(62, 22)
	b:SetText(name)
	b:SetScript("OnClick", function() AT.ShowPage(name) end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Вкладка «" .. name .. "»", 1, 1, 1)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	AT.tabButtons[name] = b

	-- Страница (видимая область)
	local page = CreateFrame("Frame", "AdminToolsRUPage" .. index, frame)
	page:SetPoint("TOPLEFT", frame, "TOPLEFT", AT.PAGE_PAD, AT.PAGE_TOP)
	page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -AT.PAGE_PAD, AT.PAGE_BOTTOM)

	-- Прокрутка
	local scroll = CreateFrame("ScrollFrame", "AdminToolsRUScroll" .. index, page, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 0)
	scroll:EnableMouseWheel(true)
	scroll.maxScroll = 0

	local child = CreateFrame("Frame", "AdminToolsRUContent" .. index, scroll)
	child:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
	child:SetSize(scroll:GetWidth() or 598, 480)
	scroll:SetScrollChild(child)

	local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
	local syncing = false

	if scrollBar then
		scrollBar:SetMinMaxValues(0, 0)
		scrollBar:SetValue(0)
		scrollBar:SetScript("OnValueChanged", function(self, value)
			if syncing then return end
			syncing = true
			scroll:SetVerticalScroll(value or 0)
			syncing = false
		end)
	end

	scroll:SetScript("OnVerticalScroll", function(self, offset)
		if syncing then return end
		syncing = true
		if scrollBar and scrollBar:GetValue() ~= offset then scrollBar:SetValue(offset) end
		syncing = false
	end)

	scroll:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
		yrange = yrange or 0
		self.maxScroll = yrange
		if scrollBar then
			scrollBar:SetMinMaxValues(0, yrange)
			if yrange > 0 then
				if not scrollBar:IsShown() then scrollBar:Show() end
			else
				if scrollBar:IsShown() then scrollBar:Hide() end
			end
		end
	end)

	scroll:SetScript("OnSizeChanged", function(self, w)
		if w and w > 0 then child:SetWidth(w) end
	end)

	scroll:SetScript("OnMouseWheel", function(self, delta)
		local value = self:GetVerticalScroll() - delta * 40
		if value < 0 then value = 0 end
		if value > (self.maxScroll or 0) then value = self.maxScroll or 0 end
		self:SetVerticalScroll(value)
		if scrollBar then scrollBar:SetValue(value) end
	end)

	AT.pages[name] = child
	AT.scrolls[name] = scroll
	AT.scrollOfPage[child] = scroll
	AT.pageBottom[child] = 0

	page:Hide()
	return child
end

function AT.ShowPage(name)
	if not name then return end
	if not AT.IsTabVisible(name) then return end
	AT.currentTab = name

	for n, p in pairs(AT.pages) do
		local holder = AT.scrolls[n] and AT.scrolls[n]:GetParent()
		if holder then
			if n == name then holder:Show() else holder:Hide() end
		end
	end

	for n, b in pairs(AT.tabButtons) do
		if n == name then b:LockHighlight() else b:UnlockHighlight() end
	end

	-- только сейчас, когда страница уже видима, считаем высоту контента
	if AT.pages[name] then AT.FitPage(AT.pages[name]) end

	if AdminToolsDB then AdminToolsDB.tab = name end
end

function AT.Toggle()
	if not AT.frame then return end
	if AT.frame:IsShown() then
		AT.frame:Hide()
	else
		AT.frame:Show()
		if AT.currentTab then AT.ShowPage(AT.currentTab) end
	end
end

--===========================================================================
-- Выпадающие меню
-- Данные: { { "Заголовок", { {"Пункт", "команда"}, ... } }, ... }
-- Возвращает функцию open(anchor) — открыть меню.
--===========================================================================
function AT.BuildMenu(globalName, dataTable)
	local menu = CreateFrame("Frame", globalName, UIParent, "UIDropDownMenuTemplate")

	local function init(self, level)
		local data = (level == 1) and dataTable or UIDROPDOWNMENU_MENU_VALUE
		if type(data) ~= "table" then return end

		for _, entry in ipairs(data) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = entry[1]
			info.notCheckable = true

			local value = entry[2]
			local valueType = type(value)

			if valueType == "table" then
				info.hasArrow = true
				info.value = value
			elseif valueType == "function" then
				info.func = function()
					CloseDropDownMenus()
					value()
				end
			else
				info.func = function()
					CloseDropDownMenus()
					AT.RunCmd(value)
				end
			end

			UIDropDownMenu_AddButton(info, level)
		end
	end

	UIDropDownMenu_Initialize(menu, init, "MENU")

	return function(anchor)
		ToggleDropDownMenu(1, nil, menu, anchor or "cursor", 0, 0)
	end
end

--===========================================================================
-- Видимость вкладок
--===========================================================================
AT.DEFAULT_TAB_VISIBILITY = {
	["Телепорт"]    = true,
	["Путешествие"] = true,
	["Боты"]        = true,
	["NPC"]         = true,
	["Себя"]        = true,
	["Персонаж"]    = true,
	["Группа"]      = true,
	["Сервер"]      = true,
	["Настройки"]   = true,
	["Свои"]        = true,
}

function AT.IsTabVisible(name)
	local fallback = AT.DEFAULT_TAB_VISIBILITY[name] ~= false
	-- «Настройки» не скрываем никогда, иначе не вернуть остальные вкладки
	if name == "Настройки" then return true end
	if not AdminToolsDB or type(AdminToolsDB.tabVisibility) ~= "table" then return fallback end
	local v = AdminToolsDB.tabVisibility[name]
	if v == nil then return fallback end
	return v and true or false
end

function AT.SetTabVisible(name, visible)
	if name == "Настройки" then visible = true end
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.tabVisibility = AdminToolsDB.tabVisibility or {}
	AdminToolsDB.tabVisibility[name] = visible and true or false

	local b = AT.tabButtons[name]
	if b then
		if visible then b:Show() else b:Hide() end
	end

	-- если текущая вкладка стала скрытой — переключаемся на первую доступную
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
	local offset = 0
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b then
			if AT.IsTabVisible(name) then
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 + offset * 66, -42)
				b:Show()
				offset = offset + 1
			else
				b:Hide()
			end
		end
	end
end

--===========================================================================
-- Масштаб окна
--===========================================================================
function AT.SetScale(scale)
	scale = tonumber(scale) or 1
	if scale < 0.6 then scale = 0.6 end
	if scale > 1.6 then scale = 1.6 end
	scale = floor(scale * 100) / 100
	if AdminToolsDB then AdminToolsDB.scale = scale end
	if AT.frame then AT.frame:SetScale(scale) end
end

function AT.GetScale()
	if AdminToolsDB and AdminToolsDB.scale then return AdminToolsDB.scale end
	return 1
end
