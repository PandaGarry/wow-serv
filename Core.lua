--=========================================================================
-- Core.lua - ядро Admin Tools RU
-- Общие функции, тема, виджеты и система раскладки
--=========================================================================

local floor, ceil = math.floor, math.ceil

-- Глобальная таблица аддона
AT = AT or {}
AT.pages = {}        -- name -> ScrollFrame
AT.contents = {}     -- name -> контент-фрейм страницы
AT.tabButtons = {}
AT.TABS = {}
AT.floor, AT.ceil = floor, ceil
AT.MAX_BAG_ID = 41600
AT.VERSION = "4.3"

---------------------------------------------------------------------------
-- Размеры и раскладка (все отступы считаются от этих констант)
---------------------------------------------------------------------------
AT.WIN_W, AT.WIN_H = 720, 600    -- размер главного окна
AT.SIDE      = 14                -- боковой отступ страницы
AT.SCROLL_W  = 20                -- место под полосу прокрутки
AT.CONTENT_W = AT.WIN_W - AT.SIDE * 2 - AT.SCROLL_W - 6   -- = 666
AT.COLS      = 4                 -- кнопок в ряд
AT.PAD       = 6                 -- промежуток между кнопками
AT.BTN_H     = 22
AT.BTN_W     = floor((AT.CONTENT_W - 8 - AT.PAD * (AT.COLS - 1)) / AT.COLS)  -- = 160
AT.ROW_H     = 28                -- высота строки формы
AT.LABEL_W   = 200               -- ширина колонки подписей в формах
AT.EDIT_W    = 250               -- ширина поля ввода по умолчанию
AT.TAB_Y     = -40               -- верх первого ряда вкладок
AT.TAB_ROW_H = 24
AT.BOTTOM_H  = 46                -- высота нижней панели команд

-- Уровни доступа
AT.SL_COLORS = {
	[1] = "|cff33ff33",
	[2] = "|cffffff33",
	[3] = "|cffff5555",
}

-- Тёмная тема
AT.THEME = {
	bg      = { 0.08, 0.09, 0.12, 0.95 },
	border  = { 0.25, 0.25, 0.30, 1 },
	accent  = { 0.40, 0.70, 1.0, 1 },
	text    = { 0.90, 0.90, 0.95, 1 },
	textDim = { 0.60, 0.60, 0.65, 1 },
}

---------------------------------------------------------------------------
-- Выполнение команды
---------------------------------------------------------------------------
function AT.RunCmd(cmd)
	if type(cmd) ~= "string" then return end
	cmd = strtrim(cmd)
	if cmd == "" then return end
	if cmd:sub(1, 1) ~= "." then cmd = "." .. cmd end
	if #cmd > 255 then cmd = cmd:sub(1, 255) end
	SendChatMessage(cmd, "SAY")
	if not AdminToolsDB or AdminToolsDB.echo ~= false then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[AT-RU]|r " .. cmd)
	end
end

function AT.ConfirmCmd(cmd, text)
	local d = StaticPopup_Show("ADMINTOOLS_CONFIRM", text or cmd)
	if d then d.data = cmd end
end

StaticPopupDialogs["ADMINTOOLS_CONFIRM"] = {
	text = "Выполнить команду?\n\n|cffffd100%s|r",
	button1 = YES, button2 = NO,
	OnAccept = function(self, data) AT.RunCmd(data) end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["ADMINTOOLS_ENEMYCITY"] = {
	text = "Это |cffff2020%s|r — столица вражеской фракции.\nСтража атакует вас по прибытии.\n\nВсё равно телепортироваться?",
	button1 = YES, button2 = NO,
	OnAccept = function(self, data) AT.RunCmd(data) end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Виджеты
---------------------------------------------------------------------------

-- Вписать текст кнопки: сначала уменьшаем шрифт, затем обрезаем «...»
local function FitButtonText(b, w)
	local fs = b:GetFontString()
	if not fs then return end
	fs:ClearAllPoints()
	fs:SetPoint("LEFT", b, "LEFT", 5, 1)
	fs:SetPoint("RIGHT", b, "RIGHT", -5, 1)
	fs:SetHeight(AT.BTN_H - 6)
	fs:SetJustifyH("CENTER")
	if fs:GetStringWidth() > (w - 10) then
		b:SetNormalFontObject(GameFontNormalSmall)
		b:SetHighlightFontObject(GameFontHighlightSmall)
		b:SetDisabledFontObject(GameFontDisableSmall)
	end
end
AT.FitButtonText = FitButtonText

function AT.SetButtonText(b, text, sl)
	if sl and AT.SL_COLORS[sl] then
		b:SetText(AT.SL_COLORS[sl] .. text .. "|r")
	else
		b:SetText(text)
	end
	FitButtonText(b, b:GetWidth())
end

function AT.MakeButton(parent, text, w, action, sl, tooltip)
	w = w or AT.BTN_W
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w, AT.BTN_H)
	AT.SetButtonText(b, text, sl)
	b:SetScript("OnClick", function()
		if type(action) == "function" then action() else AT.RunCmd(action) end
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text, 1, 1, 1)                     -- полное название
		if tooltip and tooltip ~= text then
			GameTooltip:AddLine(tooltip, 0.85, 0.85, 0.85, true)
		end
		if sl and AT.SL_COLORS[sl] then
			local slName = (sl == 1 and "Модератор") or (sl == 2 and "Гейммастер") or "Администратор"
			GameTooltip:AddLine("Уровень доступа: " .. slName, 0.5, 0.8, 1)
		end
		if type(action) == "string" then
			GameTooltip:AddLine("Команда: |cff33ff99" .. action .. "|r", 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return b
end

-- Поле ввода. У InputBoxTemplate левая рамка рисуется на ~5px левее
-- самого фрейма, поэтому при позиционировании добавляем +6 по X.
function AT.MakeEdit(parent, w)
	local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	e:SetSize(w or AT.EDIT_W, 20)
	e:SetAutoFocus(false)
	e:SetFontObject(ChatFontNormal)
	e:SetTextInsets(0, 4, 0, 0)
	e:SetMaxLetters(250)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	return e
end

function AT.MakeLabel(parent, text, template)
	local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormalSmall")
	fs:SetText(text)
	return fs
end

-- Многострочная подсказка на всю ширину страницы. Возвращает новый y.
function AT.MakeNote(parent, text, y)
	local fs = AT.MakeLabel(parent, text, "GameFontHighlightSmall")
	fs:SetTextColor(AT.THEME.textDim[1], AT.THEME.textDim[2], AT.THEME.textDim[3])
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	fs:SetWidth(AT.CONTENT_W - 12)
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
	local h = fs:GetStringHeight()
	if not h or h < 12 then h = 12 end
	return y - h - 8, fs
end

-- Заголовок секции с линией. Возвращает y для содержимого.
function AT.MakeSection(parent, title, y)
	local header = AT.MakeLabel(parent, title, "GameFontNormal")
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetTexture(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.4)
	line:SetHeight(1)
	line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
	line:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
	return y - 24
end

-- Сетка кнопок. defs: { текст, действие, ширина, SL, подсказка }
function AT.FlowButtons(page, defs, startY, cols, w)
	cols = cols or AT.COLS
	w = w or AT.floor((AT.CONTENT_W - 8 - AT.PAD * (cols - 1)) / cols)
	for i, d in ipairs(defs) do
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)
		local b = AT.MakeButton(page, d[1], w, d[2], d[4], d[5])
		b:SetPoint("TOPLEFT", page, "TOPLEFT", 4 + col * (w + AT.PAD), startY - row * (AT.BTN_H + AT.PAD))
	end
	return startY - ceil(#defs / cols) * (AT.BTN_H + AT.PAD) - 4
end

-- Подпись строки формы фиксированной ширины (длинный текст обрезается «...»)
local function FormLabel(page, y, text)
	local lbl = AT.MakeLabel(page, text, "GameFontNormalSmall")
	lbl:SetJustifyH("LEFT")
	lbl:SetWidth(AT.LABEL_W - 10)
	lbl:SetHeight(20)
	lbl:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y)
	return lbl
end

-- Метка + поле + «ОК». Возвращает новый y и поле ввода.
function AT.FormRow(page, y, labelText, builder, width)
	FormLabel(page, y, labelText)
	local e = AT.MakeEdit(page, width or AT.EDIT_W)
	e:SetPoint("TOPLEFT", page, "TOPLEFT", AT.LABEL_W + 6, y)
	local function fire()
		local t = strtrim(e:GetText() or "")
		if t ~= "" then AT.RunCmd(builder(t)) end
	end
	local go = AT.MakeButton(page, "ОК", 60, fire)
	go:SetPoint("LEFT", e, "RIGHT", 8, 0)
	e:SetScript("OnEnterPressed", function(self) fire(); self:ClearFocus() end)
	return y - AT.ROW_H, e
end

-- Метка + два поля + «ОК»
function AT.FormRow2(page, y, labelText, builder, w1, w2)
	FormLabel(page, y, labelText)
	local e1 = AT.MakeEdit(page, w1 or 160)
	e1:SetPoint("TOPLEFT", page, "TOPLEFT", AT.LABEL_W + 6, y)
	local e2 = AT.MakeEdit(page, w2 or 76)
	e2:SetPoint("LEFT", e1, "RIGHT", 14, 0)
	local function fire()
		local a = strtrim(e1:GetText() or "")
		local b = strtrim(e2:GetText() or "")
		if a ~= "" then AT.RunCmd(builder(a, b)) end
	end
	local go = AT.MakeButton(page, "ОК", 60, fire)
	go:SetPoint("LEFT", e2, "RIGHT", 8, 0)
	e1:SetScript("OnTabPressed", function() e2:SetFocus() end)
	e2:SetScript("OnTabPressed", function() e1:SetFocus() end)
	e1:SetScript("OnEnterPressed", function(self) fire(); self:ClearFocus() end)
	e2:SetScript("OnEnterPressed", function(self) fire(); self:ClearFocus() end)
	return y - AT.ROW_H, e1, e2
end

function AT.MakeTeleButton(parent, label, teleName, cityFaction, w)
	return AT.MakeButton(parent, label, w or AT.BTN_W, function()
		local pf = UnitFactionGroup("player")
		if cityFaction and cityFaction ~= "Neutral" and pf and cityFaction ~= pf then
			local d = StaticPopup_Show("ADMINTOOLS_ENEMYCITY", label)
			if d then d.data = ".tele " .. teleName end
		else
			AT.RunCmd(".tele " .. teleName)
		end
	end, nil, "Телепорт: .tele " .. teleName)
end

function AT.TeleSection(page, y, header, list)
	y = AT.MakeSection(page, header, y)
	local cols = AT.COLS
	for i, e in ipairs(list) do
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)
		local b = AT.MakeTeleButton(page, e[1], e[2], e[3])
		b:SetPoint("TOPLEFT", page, "TOPLEFT", 4 + col * (AT.BTN_W + AT.PAD), y - row * (AT.BTN_H + AT.PAD))
	end
	return y - ceil(#list / cols) * (AT.BTN_H + AT.PAD) - 6
end

---------------------------------------------------------------------------
-- Регистрация вкладки. Каждая страница — ScrollFrame с контентом,
-- поэтому длинные вкладки прокручиваются колесом и не налезают на
-- нижнюю панель.
---------------------------------------------------------------------------
local pageCount = 0

function AT.RegisterTab(name)
	table.insert(AT.TABS, name)
	pageCount = pageCount + 1

	local b = CreateFrame("Button", nil, AT.frame, "UIPanelButtonTemplate")
	b:SetText(name)
	b:SetHeight(AT.TAB_ROW_H - 2)
	b:SetScript("OnClick", function() AT.ShowPage(name) end)
	AT.tabButtons[name] = b

	local sf = CreateFrame("ScrollFrame", "AdminToolsRUPage" .. pageCount, AT.frame, "UIPanelScrollFrameTemplate")
	sf.scrollBarHideable = true
	sf:Hide()

	local content = CreateFrame("Frame", nil, sf)
	content:SetSize(AT.CONTENT_W, 10)
	sf:SetScrollChild(content)

	AT.pages[name] = sf
	AT.contents[name] = content
	return content
end

-- Вызывается вкладкой в конце построения: задаёт высоту прокручиваемой области
function AT.FinishPage(content, y)
	content:SetHeight(math.max(10, -y + 8))
	local sf = content:GetParent()
	if sf and sf.UpdateScrollChildRect then sf:UpdateScrollChildRect() end
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
	local menu = CreateFrame("Frame", globalName, AT.frame, "UIDropDownMenuTemplate")
	local function init(_, level)
		if not level then return end
		local data = (level == 1) and dataTable or UIDROPDOWNMENU_MENU_VALUE
		if type(data) ~= "table" then return end
		for _, entry in ipairs(data) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = entry[1]
			info.notCheckable = true
			if type(entry[2]) == "table" then
				info.hasArrow = true
				info.value = entry[2]
			else
				local cmd = entry[2]
				info.func = function() AT.RunCmd(cmd); CloseDropDownMenus() end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_Initialize(menu, init, "MENU")
	return function(anchor)
		ToggleDropDownMenu(1, nil, menu, anchor or "cursor", 0, 0)
	end
end

---------------------------------------------------------------------------
-- Настройки видимости вкладок
---------------------------------------------------------------------------
function AT.IsTabVisible(name)
	if name == "Настройки" then return true end
	local tv = AdminToolsDB and AdminToolsDB.tabVisibility
	if not tv or tv[name] == nil then return true end
	return tv[name]
end

function AT.SetTabVisible(name, visible)
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.tabVisibility = AdminToolsDB.tabVisibility or {}
	AdminToolsDB.tabVisibility[name] = visible
	if not visible and AT.currentTab == name then
		for _, n in ipairs(AT.TABS) do
			if n ~= name and AT.IsTabVisible(n) then AT.ShowPage(n); break end
		end
	end
end

-- Раскладывает видимые вкладки в несколько рядов (перенос по ширине окна)
-- и подгоняет область страниц под получившееся число рядов.
-- Ширина кнопки вкладки по тексту
local function SizeTab(b, small)
	if small then
		b:SetNormalFontObject(GameFontNormalSmall)
		b:SetHighlightFontObject(GameFontHighlightSmall)
	else
		b:SetNormalFontObject(GameFontNormal)
		b:SetHighlightFontObject(GameFontHighlight)
	end
	local tw = b:GetFontString():GetStringWidth() or 40
	b:SetWidth(math.max(small and 48 or 56, ceil(tw) + (small and 14 or 18)))
end

function AT.ApplyTabVisibility()
	local maxW = AT.WIN_W - 16
	-- Если в один ряд не помещается — уменьшаем шрифт вкладок
	local total = 0
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b and AT.IsTabVisible(name) then SizeTab(b, false); total = total + b:GetWidth() + 2 end
	end
	local small = total > maxW
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b then SizeTab(b, small) end
	end
	local x, row = 0, 0
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b then
			if AT.IsTabVisible(name) then
				local w = b:GetWidth()
				if x > 0 and x + w > maxW then x = 0; row = row + 1 end
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", AT.frame, "TOPLEFT", 8 + x, AT.TAB_Y - row * AT.TAB_ROW_H)
				b:Show()
				x = x + w + 2
			else
				b:Hide()
			end
		end
	end
	local top = AT.TAB_Y - (row + 1) * AT.TAB_ROW_H - 8
	for _, sf in pairs(AT.pages) do
		sf:ClearAllPoints()
		sf:SetPoint("TOPLEFT", AT.frame, "TOPLEFT", AT.SIDE, top)
		sf:SetPoint("BOTTOMRIGHT", AT.frame, "BOTTOMRIGHT", -(AT.SIDE + AT.SCROLL_W + 6), AT.BOTTOM_H + 4)
	end
	if AT.tabLine then
		AT.tabLine:ClearAllPoints()
		AT.tabLine:SetPoint("TOPLEFT", AT.frame, "TOPLEFT", 8, top + 4)
		AT.tabLine:SetPoint("TOPRIGHT", AT.frame, "TOPRIGHT", -8, top + 4)
	end
end

---------------------------------------------------------------------------
-- Главное окно создаётся здесь, до загрузки вкладок (Tab_*.lua),
-- чтобы у страниц и кнопок вкладок был корректный родитель.
---------------------------------------------------------------------------
AT.frame = CreateFrame("Frame", "AdminToolsRUFrame", UIParent)
AT.frame:SetSize(AT.WIN_W, AT.WIN_H)
AT.frame:SetPoint("CENTER")
AT.frame:Hide()
