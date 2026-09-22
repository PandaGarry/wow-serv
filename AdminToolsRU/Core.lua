--===========================================================================
-- Admin Tools RU — Core.lua
-- Ядро аддона: скин, шрифты, виджеты, реестр вкладок, прокрутка, избранное.
--
-- ВАЖНО: этот файл создаёт главное окно (AT.frame) ДО того, как вкладки
-- зарегистрируются. Поэтому Core.lua обязан идти первым в .toc.
--===========================================================================

AT = AT or {}

AT.ADDON_NAME = "AdminToolsRU"
AT.VERSION    = "5.1.1"
AT.PREFIX     = "|cff2fd6ff[AT-RU]|r "

local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
AT.floor, AT.ceil = floor, ceil

--===========================================================================
-- Утилиты
--===========================================================================

function AT.trim(s)
	if type(s) ~= "string" then return "" end
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function AT.Print(msg)
	if not DEFAULT_CHAT_FRAME then return end
	DEFAULT_CHAT_FRAME:AddMessage(AT.PREFIX .. tostring(msg))
end

function AT.PrintErr(msg)
	if not DEFAULT_CHAT_FRAME then return end
	DEFAULT_CHAT_FRAME:AddMessage(AT.PREFIX .. "|cffff5555" .. tostring(msg) .. "|r")
end

--===========================================================================
-- Уровни доступа
--===========================================================================
AT.SEC_NAMES = {
	[0] = "Игрок",
	[1] = "Модератор",
	[2] = "Гейммастер",
	[3] = "Администратор",
}

AT.SEC_RGB = {
	[0] = { 0.66, 0.66, 0.66 },
	[1] = { 0.30, 1.00, 0.40 },
	[2] = { 1.00, 0.90, 0.25 },
	[3] = { 1.00, 0.35, 0.35 },
}

AT.SEC_HEX = {
	[0] = "|cffa0a0a0",
	[1] = "|cff33ff66",
	[2] = "|cffffe640",
	[3] = "|cffff5555",
}

function AT.SecName(sec)
	local name = AT.SEC_NAMES[sec or 0] or "?"
	return (AT.SEC_HEX[sec or 0] or "") .. name .. "|r"
end

function AT.GetMySec()
	if AdminToolsDB and AdminToolsDB.mySec then return AdminToolsDB.mySec end
	return 3
end

function AT.IsLocked(sec)
	if not sec then return false end
	if not (AdminToolsDB and AdminToolsDB.restrictBySec) then return false end
	return AT.GetMySec() < sec
end

--===========================================================================
-- Скин: текстуры, цвета, шрифты
-- Файлы skin/*.tga лежат в папке аддона (см. tools/gen_textures.py).
--===========================================================================
AT.SKIN_PATH = "Interface\\AddOns\\" .. AT.ADDON_NAME .. "\\skin\\"

AT.SKIN = {
	btnNormal = AT.SKIN_PATH .. "btn-normal",
	btnHover  = AT.SKIN_PATH .. "btn-hover",
	btnPushed = AT.SKIN_PATH .. "btn-pushed",
	panel     = AT.SKIN_PATH .. "panel",
	glow      = AT.SKIN_PATH .. "glow",
	line      = AT.SKIN_PATH .. "line",
}

AT.THEME = {
	bg      = { 0.045, 0.055, 0.075, 0.97 },
	border  = { 0.16, 0.18, 0.24, 1.00 },
	accent  = { 0.18, 0.84, 1.00, 1.00 },   -- голубой акцент (стиль FenUI/Anima)
	accent2 = { 0.55, 0.40, 1.00, 1.00 },   -- фиолетовый (для градиентов)
	text    = { 0.90, 0.92, 0.96, 1.00 },
	textDim = { 0.55, 0.58, 0.66, 1.00 },
	danger  = { 1.00, 0.35, 0.35, 1.00 },
}

AT.WIN_W, AT.WIN_H = 880, 620
AT.BTN_W, AT.BTN_H, AT.PAD = 142, 22, 6
AT.TAB_W, AT.TAB_H, AT.TAB_STEP = 132, 24, 26
AT.FLOW_COLS = 4
AT.TELE_COLS = 3
AT.PAGE_PAD_L, AT.PAGE_PAD_R = 160, 16
AT.PAGE_TOP, AT.PAGE_BOTTOM = -118, 60

-----------------------------------------------------------------------------
-- Шрифты.
-- Не задаём пути к .ttf вручную: берём тот шрифт, который уже стоит у
-- виджета (клиент подставляет локализованный, с кириллицей). Меняем только
-- размер и обводку — так русский текст гарантированно отображается и на
-- ruRU, и на enUS клиенте.
-----------------------------------------------------------------------------
AT.fontRegistry = {}
AT.FontSizeDelta = 0

function AT.RegisterFont(fs)
	if not fs then return end
	local file, size, flags = fs:GetFont()
	if not file then return end
	AT.fontRegistry[fs] = { file = file, size = size, flags = flags }
	if AT.FontSizeDelta ~= 0 then
		fs:SetFont(file, size + AT.FontSizeDelta, flags)
	end
end

function AT.SetFontSizeDelta(delta)
	delta = tonumber(delta) or 0
	if delta < -2 then delta = -2 end
	if delta > 4 then delta = 4 end
	AT.FontSizeDelta = delta
	if AdminToolsDB then AdminToolsDB.fontSize = delta end

	for fs, info in pairs(AT.fontRegistry) do
		local size = info.size + delta
		if size < 6 then size = 6 end
		fs:SetFont(info.file, size, info.flags)
	end
end

function AT.GetFontSizeDelta()
	if AdminToolsDB and AdminToolsDB.fontSize then return AdminToolsDB.fontSize end
	return 0
end

--===========================================================================
-- Главное окно
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

-- мягкое свечение сверху (стиль FenUI: акцент в шапке)
local glow = frame:CreateTexture(nil, "BACKGROUND")
glow:SetTexture(AT.SKIN.glow)
glow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
glow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
glow:SetHeight(150)
glow:SetVertexColor(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.13)

-- вертикальная колонка вкладок: подложка
local tabBg = frame:CreateTexture(nil, "BACKGROUND")
tabBg:SetTexture(AT.SKIN.panel)
tabBg:SetVertexColor(0.05, 0.06, 0.09, 0.55)
tabBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -84)
tabBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 56)
tabBg:SetWidth(AT.TAB_W + 14)

AT.pages = {}
AT.scrolls = {}
AT.tabButtons = {}
AT.TABS = {}
AT.pageBottom = {}
AT.scrollOfPage = {}
AT.allButtons = {}       -- все кнопки-команды (для подсветки блокировки)
AT.favoriteButtons = {}

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
	-- счётчик в нижней панели обновляем по событию, а не каждый кадр
	if AT.UpdateHistoryLabel then AT.UpdateHistoryLabel() end
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
	if AT.EchoEnabled() and DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(AT.PREFIX .. "|cff666666>|r |cff2fd6ff" .. cmd .. "|r")
	end
end

--===========================================================================
-- Избранное: Shift+ЛКМ по любой кнопке-команде добавляет её в шапку
--===========================================================================
AT.FAVORITES_MAX = 12

function AT.GetFavorites()
	AdminToolsDB = AdminToolsDB or {}
	if type(AdminToolsDB.favorites) ~= "table" then AdminToolsDB.favorites = {} end
	return AdminToolsDB.favorites
end

function AT.IsFavorite(cmd)
	for _, f in ipairs(AT.GetFavorites()) do
		if f.cmd == cmd then return true end
	end
	return false
end

function AT.ToggleFavorite(label, cmd)
	if type(cmd) ~= "string" or cmd == "" then return end
	local list = AT.GetFavorites()

	for i, f in ipairs(list) do
		if f.cmd == cmd then
			table.remove(list, i)
			AT.Print("Убрано из избранного: " .. label)
			AT.RefreshFavorites()
			return
		end
	end

	if #list >= AT.FAVORITES_MAX then
		AT.PrintErr("Избранное заполнено (" .. AT.FAVORITES_MAX .. "). Убери что-нибудь.")
		return
	end

	table.insert(list, { label = label, cmd = cmd })
	AT.Print("В избранном: |cff2fd6ff" .. label .. "|r")
	AT.RefreshFavorites()
end

function AT.RefreshFavorites()
	local row = AT.favoritesRow
	if not row then return end
	-- куда вешать кнопки: Main.lua задаёт AT.favoritesAnchor (область справа от подписи)
	local anchor = AT.favoritesAnchor or row

	for _, b in ipairs(AT.favoriteButtons) do b:Hide() end

	local list = AT.GetFavorites()
	if #list == 0 then
		if row.hint then row.hint:Show() end
		return
	end
	if row.hint then row.hint:Hide() end

	for i, fav in ipairs(list) do
		local b = AT.favoriteButtons[i]
		if not b then
			b = CreateFrame("Button", nil, anchor)
			b:SetSize(104, 18)
			b:SetScript("OnClick", function(self, mouse)
				local f = AT.GetFavorites()[self.__index]
				if not f then return end
				if mouse == "RightButton" or IsShiftKeyDown() then
					AT.ToggleFavorite(f.label, f.cmd)
				else
					AT.RunCmd(f.cmd)
				end
			end)
			b:SetScript("OnEnter", function(self)
				local f = AT.GetFavorites()[self.__index]
				if not f then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(f.label, 1, 1, 1)
				GameTooltip:AddLine("Команда: |cff2fd6ff" .. f.cmd .. "|r", 0.7, 0.7, 0.7)
				GameTooltip:AddLine("ЛКМ — выполнить, Shift+ЛКМ — убрать", 0.5, 0.5, 0.5)
				GameTooltip:Show()
			end)
			b:SetScript("OnLeave", function() GameTooltip:Hide() end)
			AT.favoriteButtons[i] = b
		end

		b.__index = i
		local text = fav.label or fav.cmd
		if #text > 15 then text = text:sub(1, 14) .. "…" end
		b:SetText(text)

		local col = (i - 1) % 7
		local rowIdx = floor((i - 1) / 7)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", anchor, "TOPLEFT", (col) * 110, -rowIdx * 20)
		b:Show()
	end
end

--===========================================================================
-- Подтверждения
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

function AT.ConfirmCmd(cmd, text)
	local dialog = StaticPopup_Show(AT.POPUP_CONFIRM, text or cmd)
	if dialog then dialog.data = cmd end
	return dialog
end

--===========================================================================
-- Виджеты
--===========================================================================

-- Применить к кнопке наше оформление (текстуры + шрифт).
local function SkinButton(btn)
	btn:SetNormalTexture(AT.SKIN.btnNormal)
	btn:SetPushedTexture(AT.SKIN.btnPushed)

	local hl = btn:GetHighlightTexture()
	if hl then
		hl:SetTexture(AT.SKIN.btnHover)
		hl:SetBlendMode("ADD")
	end

	local fs = btn:GetFontString()
	if fs then
		AT.RegisterFont(fs)
		fs:SetJustifyH("CENTER")
	end
end
AT.SkinButton = SkinButton

-- Пересчитать цвета текста кнопок с учётом уровня доступа
function AT.RefreshLocks()
	for _, item in ipairs(AT.allButtons) do
		local btn, sec = item[1], item[2]
		local fs = btn.GetFontString and btn:GetFontString()
		if fs then
			if AT.IsLocked(sec) then
				fs:SetTextColor(0.42, 0.44, 0.48)
			else
				local rgb = AT.SEC_RGB[sec or 0] or AT.SEC_RGB[0]
				fs:SetTextColor(rgb[1], rgb[2], rgb[3])
			end
		end
	end
end

function AT.MakeButton(parent, text, w, action, sec, tooltip)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w or AT.BTN_W, AT.BTN_H)
	b:SetText(text)
	SkinButton(b)

	b.sec = sec
	if sec then
		local rgb = AT.SEC_RGB[sec] or AT.SEC_RGB[0]
		local fs = b:GetFontString()
		if fs then fs:SetTextColor(rgb[1], rgb[2], rgb[3]) end
	end

	-- запоминаем для общей перекраски при смене уровня доступа
	if sec then
		table.insert(AT.allButtons, { b, sec })
		if not text or text == "" then
			-- кнопки без подписи (например, счётчики) не учитываем
			table.remove(AT.allButtons)
		end
	end

	-- ПКМ по кнопке-команде копирует команду в поле ввода (не выполняя её)
	if type(action) == "string" then
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	end

	b:SetScript("OnClick", function(self, mouse)
		if mouse == "RightButton" and type(action) == "string" then
			if AT.SetCommandBox then
				AT.SetCommandBox(action)
				AT.Print("Команда в поле ввода: |cff2fd6ff" .. action .. "|r")
			end
			return
		end

		if AT.IsLocked(sec) then
			AT.PrintErr("Недоступно: нужен уровень «" .. (AT.SEC_NAMES[sec] or "?") .. "».")
			return
		end

		-- Shift+ЛКМ — добавить/убрать из избранного
		if type(action) == "string" and IsShiftKeyDown() then
			AT.ToggleFavorite(text, action)
			return
		end

		if type(action) == "function" then
			action(self)
		else
			AT.RunCmd(action)
		end
	end)

	if tooltip or sec or type(action) == "string" then
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(tooltip or text or "?", 1, 1, 1)

			if sec then
				local lockNote = AT.IsLocked(sec) and "  |cffff5555(заблокировано)|r" or ""
				GameTooltip:AddLine("Уровень: " .. AT.SecName(sec) .. lockNote, 0.6, 0.8, 1)
			end

			if type(action) == "string" then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Команда: |cff2fd6ff" .. action .. "|r", 0.7, 0.7, 0.7)
				local fav = AT.IsFavorite(action) and "|cffffd100в избранном|r" or "Shift+ЛКМ — в избранное"
				GameTooltip:AddLine("ПКМ — в поле ввода · " .. fav, 0.5, 0.5, 0.5)
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
	AT.RegisterFont(fs)
	return fs
end

-- Декоративная линия-разделитель (текстура skin/line.tga)
function AT.MakeLine(parent, y, left, right)
	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetTexture(AT.SKIN.line)
	line:SetVertexColor(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.45)
	line:SetHeight(8)
	line:SetPoint("TOPLEFT", parent, "TOPLEFT", left or 6, y + 3)
	line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", right or -8, y + 3)
	return line
end

function AT.NoteY(page, y)
	if type(y) ~= "number" then return end
	local cur = AT.pageBottom[page]
	if not cur or y < cur then AT.pageBottom[page] = y end
end

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
	local scroll = AT.scrollOfPage[page]
	if scroll and scroll:GetHeight() and height < scroll:GetHeight() then
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
	line:SetTexture(AT.SKIN.line)
	line:SetVertexColor(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.40)
	line:SetHeight(8)
	line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -1, -1)
	line:SetPoint("RIGHT", page, "RIGHT", -10, 0)

	AT.NoteY(page, y - 20)
	return y - 20
end

-- Сетка кнопок. defs = { {текст, действие, ширина, уровень, подсказка}, ... }
function AT.FlowButtons(page, defs, startY, cols)
	if type(defs) ~= "table" or #defs == 0 then return startY end
	cols = cols or AT.FLOW_COLS

	local pageW = page:GetWidth() or 660
	if pageW <= 0 then pageW = 660 end

	-- ширина может быть не задана или задана не числом — не падаем
	local function widthOf(d)
		if type(d[3]) == "number" and d[3] > 0 then return d[3] end
		return AT.BTN_W
	end

	local cellW = AT.BTN_W
	for _, d in ipairs(defs) do
		if widthOf(d) > cellW then cellW = widthOf(d) end
	end
	local fit = floor((pageW - 4 + AT.PAD) / (cellW + AT.PAD))
	if fit < 1 then fit = 1 end
	if cols > fit then cols = fit end

	for i, d in ipairs(defs) do
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)
		-- d[2] может быть подсказкой, если передан «плоский» список {название, команда, tip}
		local sec = type(d[4]) == "number" and d[4] or nil
		local tip = d[5]
		if tip == nil and type(d[3]) == "string" then tip = d[3] end
		local b = AT.MakeButton(page, d[1], widthOf(d), d[2], sec, tip)
		b:SetPoint("TOPLEFT", page, "TOPLEFT",
			4 + col * (cellW + AT.PAD),
			startY - row * (AT.BTN_H + AT.PAD))
	end

	local rows = ceil(#defs / cols)
	local newY = startY - rows * (AT.BTN_H + AT.PAD) - AT.PAD
	AT.NoteY(page, newY)
	return newY
end

function AT.FormRow(page, y, labelText, builder, width)
	local lbl = AT.MakeLabel(page, labelText)
	lbl:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y - 5)

	local edit = AT.MakeEdit(page, width or 240)
	edit:SetPoint("TOPLEFT", page, "TOPLEFT", 190, y)

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

function AT.FormRow2(page, y, labelText, builder)
	local lbl = AT.MakeLabel(page, labelText)
	lbl:SetPoint("TOPLEFT", page, "TOPLEFT", 6, y - 5)

	local e1 = AT.MakeEdit(page, 140)
	e1:SetPoint("TOPLEFT", page, "TOPLEFT", 190, y)
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
-- Фильтр: мгновенный поиск кнопок на странице
--===========================================================================
function AT.AttachFilter(page, hint)
	local name = "AdminToolsRUFilter" .. (page:GetName() or "")
	local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	box:SetSize(220, 20)
	box:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, AT.PAGE_TOP + 20)
	box:SetAutoFocus(false)
	box:SetText(hint or "поиск…")
	box:SetTextColor(0.55, 0.58, 0.66)
	box.__empty = true
	box.__page = page

	local function apply(self)
		local q = AT.trim(self:GetText():lower())
		local empty = (self.__empty or q == "")
		if self.__empty then q = "" end

		for _, child in ipairs(page:GetChildren()) do
			if child.__kind == "Button" and child.GetText then
				local t = (child:GetText() or ""):lower()
				if empty or t:find(q, 1, true) then
					child:Show()
				else
					child:Hide()
				end
			end
		end
		AT.FitPage(page)
	end

	box:SetScript("OnTextChanged", function(self, userInput)
		if self.__empty and userInput then
			self.__empty = false
			self:SetTextColor(0.90, 0.92, 0.96)
		end
		apply(self)
	end)

	box:SetScript("OnEditFocusGained", function(self)
		if self.__empty then self:SetText("") self.__empty = false self:SetTextColor(0.9, 0.92, 0.96) end
	end)

	box:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self.__empty = true
		self:SetTextColor(0.55, 0.58, 0.66)
		self:ClearFocus()
		apply(self)
	end)

	AT.filters = AT.filters or {}
	table.insert(AT.filters, box)
	return box
end

-- Показать только фильтр нужной вкладки
function AT.ShowFiltersFor(page)
	for _, box in ipairs(AT.filters or {}) do
		if box.__page == page then box:Show() else box:Hide() end
	end
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
--===========================================================================
function AT.RegisterTab(name)
	table.insert(AT.TABS, name)
	local index = #AT.TABS

	-- кнопка вкладки (вертикальная колонка слева)
	local b = CreateFrame("Button", "AdminToolsRUTab" .. index, frame)
	b:SetSize(AT.TAB_W, AT.TAB_H)

	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(b)
	bg:SetTexture(AT.SKIN.btnNormal)
	b.__bg = bg

	local marker = b:CreateTexture(nil, "OVERLAY")
	marker:SetTexture(AT.SKIN.line)
	marker:SetVertexColor(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 1)
	marker:SetHeight(8)
	marker:SetWidth(4)
	marker:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
	marker:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
	marker:Hide()
	b.__marker = marker

	local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("LEFT", b, "LEFT", 12, 0)
	label:SetText(name)
	label:SetJustifyH("LEFT")
	AT.RegisterFont(label)
	b.__label = label

	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(b)
	hl:SetTexture(AT.SKIN.btnHover)
	hl:SetBlendMode("ADD")

	b:SetScript("OnClick", function() AT.ShowPage(name) end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(name, 1, 1, 1)
		GameTooltip:AddLine("Показать вкладку", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	AT.tabButtons[name] = b

	-- страница (видимая область справа от колонки вкладок)
	local page = CreateFrame("Frame", "AdminToolsRUPage" .. index, frame)
	page:SetPoint("TOPLEFT", frame, "TOPLEFT", AT.PAGE_PAD_L, AT.PAGE_TOP)
	page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -AT.PAGE_PAD_R, AT.PAGE_BOTTOM)

	-- заголовок активной вкладки
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", AT.PAGE_PAD_L, AT.PAGE_TOP + 26)
	title:SetText(name)
	AT.RegisterFont(title)
	page.__title = title

	local scroll = CreateFrame("ScrollFrame", "AdminToolsRUScroll" .. index, page, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 0)
	scroll:EnableMouseWheel(true)
	scroll.maxScroll = 0

	local child = CreateFrame("Frame", "AdminToolsRUContent" .. index, scroll)
	child:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
	child:SetSize(scroll:GetWidth() or 660, 480)
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

		-- лёгкий скин полосы прокрутки
		local sbName = scrollBar:GetName()
		local thumb = sbName and _G[sbName .. "ThumbTexture"]
		if thumb then
			thumb:SetTexture(AT.SKIN.panel)
			thumb:SetVertexColor(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.55)
			thumb:SetWidth(6)
		end
		if sbName then
			local up = _G[sbName .. "ScrollUpButton"]
			local down = _G[sbName .. "ScrollDownButton"]
			if up then up:Hide() end
			if down then down:Hide() end
		end
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

-- Подсветка активной вкладки
function AT.SetTabActive(name, active)
	local b = AT.tabButtons[name]
	if not b then return end

	if active then
		b.__bg:SetTexture(AT.SKIN.btnHover)
		b.__bg:SetVertexColor(AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3], 0.55)
		b.__label:SetTextColor(1, 1, 1)
		b.__marker:Show()
	else
		b.__bg:SetTexture(AT.SKIN.btnNormal)
		b.__bg:SetVertexColor(1, 1, 1, 1)
		b.__label:SetTextColor(AT.THEME.textDim[1], AT.THEME.textDim[2], AT.THEME.textDim[3])
		b.__marker:Hide()
	end
end

function AT.ShowPage(name)
	if not name then return end
	if not AT.IsTabVisible(name) then return end
	AT.currentTab = name

	for n, p in pairs(AT.pages) do
		local holder = AT.scrolls[n] and AT.scrolls[n]:GetParent()
		if holder then
			if n == name then
				holder:Show()
				if p.__title then p.__title:Show() end
				AT.ShowFiltersFor(p)
			else
				holder:Hide()
				if p.__title then p.__title:Hide() end
			end
		end
	end

	for n in pairs(AT.tabButtons) do
		AT.SetTabActive(n, n == name)
	end

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
	["Модули"]      = true,
	["Мир"]         = true,
	["Себя"]        = true,
	["Персонаж"]    = true,
	["Группа"]      = true,
	["Сервер"]      = true,
	["Настройки"]   = true,
	["Свои"]        = true,
}

function AT.IsTabVisible(name)
	local fallback = AT.DEFAULT_TAB_VISIBILITY[name] ~= false
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
				b:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -90 - offset * AT.TAB_STEP)
				b:Show()
				offset = offset + 1
			else
				b:Hide()
			end
		end
	end
end

--===========================================================================
-- Масштаб
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
