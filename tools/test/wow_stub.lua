--===========================================================================
-- tools/test/wow_stub.lua
-- Заглушка API World of Warcraft 3.3.5 для запуска аддона вне игры.
--
-- Реализовано:
--   * виджеты (Frame/Button/EditBox/CheckButton/ScrollFrame/Slider/Texture/FontString)
--   * упрощённая геометрия: SetPoint/SetSize считаются честно (пиксели),
--     поэтому тесты видят реальные координаты и могут ловить наложения
--   * события, скрипты, сохранённые переменные, чат, попапы, меню, тултипы
--
-- Всё, что аддон вызовет, но что здесь не описано, вернёт no-op функцию
-- и попадёт в STUB.unknownMethods (тесты печатают отчёт по ним).
--===========================================================================

STUB = STUB or {}
STUB.sent = {}            -- вызовы SendChatMessage
STUB.chat = {}            -- сообщения в DEFAULT_CHAT_FRAME
STUB.popups = {}          -- созданные попапы
STUB.bindingCalls = {}    -- назначения клавиш (не используются)
STUB.unknownMethods = {}  -- неизвестные методы виджетов (счётчик)
STUB.unknownNames = {}    -- имена неизвестных методов (список)
STUB.frames = {}          -- все созданные виджеты (для рассылки событий)
STUB.reloads = 0
STUB.locale = "ruRU"
STUB.faction = "Alliance"
STUB.menus = {}
STUB.dropdownOpened = {}

--===========================================================================
-- Геометрия
--===========================================================================
local ROOT_RECTS = {
	UIParent = { left = 0, top = 768, right = 1024, bottom = 0 },
	Minimap  = { left = 736, top = 130, right = 876, bottom = -10 },
}

local function Rect(w)
	if not w then return nil end
	if w.__rect then return w.__rect end

	local relRect = w.__relRect
	if not relRect then
		if w.__parent then
			relRect = Rect(w.__parent)
		else
			relRect = ROOT_RECTS[w.__name or ""] or { left = 0, top = 768, right = 1024, bottom = 0 }
		end
	end
	if not relRect then relRect = { left = 0, top = 0, right = 0, bottom = 0 } end

	local w_, h_ = w.__w or 0, w.__h or 0

	local function Resolve(point, r)
		if point == "TOPLEFT"     then return r.left, r.top end
		if point == "TOP"         then return r.left + (r.right - r.left) / 2, r.top end
		if point == "TOPRIGHT"    then return r.right, r.top end
		if point == "LEFT"        then return r.left, r.top - (r.top - r.bottom) / 2 end
		if point == "CENTER"      then return r.left + (r.right - r.left) / 2, r.top - (r.top - r.bottom) / 2 end
		if point == "RIGHT"       then return r.right, r.top - (r.top - r.bottom) / 2 end
		if point == "BOTTOMLEFT"  then return r.left, r.bottom end
		if point == "BOTTOM"      then return r.left + (r.right - r.left) / 2, r.bottom end
		if point == "BOTTOMRIGHT" then return r.right, r.bottom end
		return r.left, r.top
	end

	local p1 = w.__points and w.__points[1]
	local p2 = w.__points and w.__points[2]

	-- Внимание: SetPoint(point, relTo, relPoint, x, y) означает
	-- «моя точка point встаёт в relPoint соседа relTo». Поэтому точку
	-- привязки надо брать из relPoint, а не из point.
	local left, top
	if p1 then
		local rx, ry = Resolve(p1.relPoint or p1.point, p1.relTo and Rect(p1.relTo) or relRect)
		local ax, ay = rx + (p1.x or 0), ry + (p1.y or 0)
		local anchor = p1.point
		if anchor == "TOPLEFT" then left, top = ax, ay
		elseif anchor == "TOP" then left, top = ax - w_ / 2, ay
		elseif anchor == "TOPRIGHT" then left, top = ax - w_, ay
		elseif anchor == "LEFT" then left, top = ax, ay + h_ / 2
		elseif anchor == "CENTER" then left, top = ax - w_ / 2, ay + h_ / 2
		elseif anchor == "RIGHT" then left, top = ax - w_, ay + h_ / 2
		elseif anchor == "BOTTOMLEFT" then left, top = ax, ay + h_
		elseif anchor == "BOTTOM" then left, top = ax - w_ / 2, ay + h_
		elseif anchor == "BOTTOMRIGHT" then left, top = ax - w_, ay + h_
		else left, top = ax, ay end
	else
		left, top = relRect.left, relRect.top
	end

	-- Две угловые точки задают размер (как в WoW)
	if p2 and p1 then
		local rx2, ry2 = Resolve(p2.relPoint or p2.point, p2.relTo and Rect(p2.relTo) or relRect)
		local bx, by = rx2 + (p2.x or 0), ry2 + (p2.y or 0)
		if p1.point == "TOPLEFT" and p2.point == "BOTTOMRIGHT" then
			w_ = bx - left
			h_ = top - by
		elseif p1.point == "BOTTOMLEFT" and p2.point == "TOPRIGHT" then
			w_ = bx - left
			h_ = by - top
			top = by
		elseif p1.point == "TOPLEFT" and p2.point == "RIGHT" then
			w_ = bx - left
		elseif p1.point == "TOPLEFT" and p2.point == "BOTTOM" then
			h_ = top - by
		end
	end

	w.__rect = { left = left, top = top, right = left + w_, bottom = top - h_ }
	return w.__rect
end
STUB.Rect = Rect

local function Invalidate(w)
	w.__rect = nil
end

--===========================================================================
-- Виджеты
--===========================================================================
local M = {}   -- таблица методов виджетов (заполняется ниже)

local widgetMeta = {
	__index = function(t, k)
		-- 1. реальные методы виджета
		local real = M[k]
		if real ~= nil then return real end
		-- 2. всё остальное: no-op + учёт в отчёте (чтобы тесты не падали
		--    на методах, которых нет в заглушке)
		if type(k) == "string" and k:match("^%u") then
			if not STUB.unknownMethods[k] then
				STUB.unknownMethods[k] = 0
				table.insert(STUB.unknownNames, k)
			end
			STUB.unknownMethods[k] = STUB.unknownMethods[k] + 1
			return function() end
		end
		return nil
	end,
}

local function NewWidget(kind, name, parent, template)
	local w = {
		__kind = kind,
		__name = name,
		__parent = parent,
		__children = {},
		__regions = {},
		__scripts = {},
		__points = {},
		__shown = true,
		__w = 0,
		__h = 0,
		__template = template,
		__text = "",
		__checked = false,
		__verticalScroll = 0,
		__value = 0,
	}
	setmetatable(w, widgetMeta)

	if parent and parent.__children then table.insert(parent.__children, w) end
	if name then _G[name] = w end
	table.insert(STUB.frames, w)

	-- UIPanelScrollFrameTemplate создаёт полосу прокрутки $parentScrollBar
	if template == "UIPanelScrollFrameTemplate" and name then
		local bar = NewWidget("Slider", name .. "ScrollBar", w, nil)
		w.__scrollBar = bar
	end

	return w
end
STUB.NewWidget = NewWidget

--===========================================================================
-- Методы виджетов
--===========================================================================

function M:GetName() return self.__name end
function M:GetParent() return self.__parent end
function M:GetObjectType() return self.__kind end

function M:SetSize(w, h)
	self.__w = w or 0
	self.__h = h or 0
	Invalidate(self)
end
function M:SetWidth(w) self:SetSize(w, self.__h) end
function M:SetHeight(h) self:SetSize(self.__w, h) end

function M:SetPoint(point, relTo, relPoint, x, y)
	-- поддерживаем все формы вызова, включая SetPoint(point, x, y)
	if type(relTo) == "number" or relTo == nil then
		y = relPoint
		x = relTo
		relTo, relPoint = nil, point
	end
	table.insert(self.__points, { point = point, relTo = relTo, relPoint = relPoint, x = x or 0, y = y or 0 })
	Invalidate(self)
end
function M:ClearAllPoints() self.__points = {} Invalidate(self) end
function M:GetNumPoints() return #self.__points end
function M:GetPoint(i)
	local p = self.__points[i or 1]
	if not p then return nil end
	return p.point, p.relTo, p.relPoint, p.x, p.y
end

function M:GetWidth()
	local r = Rect(self)
	return r and (r.right - r.left) or 0
end
function M:GetHeight()
	local r = Rect(self)
	return r and (r.top - r.bottom) or 0
end
function M:GetTop() return Rect(self).top end
function M:GetBottom() return Rect(self).bottom end
function M:GetLeft() return Rect(self).left end
function M:GetRight() return Rect(self).right end
function M:GetCenter()
	local r = Rect(self)
	return (r.left + r.right) / 2, (r.top + r.bottom) / 2
end

function M:SetScale(s) self.__scale = s STUB.lastScale = s end
function M:GetScale() return self.__scale or 1 end
function M:GetEffectiveScale() return self.__scale or 1 end

function M:Show() self.__shown = true end
function M:Hide() self.__shown = false end
function M:SetShown(v) self.__shown = v and true or false end
function M:IsShown() return self.__shown and true or false end
function M:IsVisible() return self.__shown and true or false end

function M:SetScript(name, fn) self.__scripts[name] = fn end
function M:GetScript(name) return self.__scripts[name] end
function M:HookScript(name, fn)
	local prev = self.__scripts[name]
	self.__scripts[name] = function(...)
		if prev then prev(...) end
		fn(...)
	end
end
function M:RegisterEvent(e) self.__events = self.__events or {} self.__events[e] = true end
function M:UnregisterEvent(e) if self.__events then self.__events[e] = nil end end
function M:UnregisterAllEvents() self.__events = {} end
function M:IsEventRegistered(e) return self.__events and self.__events[e] or false end

function M:SetText(t)
	self.__text = t
	-- как в игре: OnTextChanged с userInput=false
	local fn = self.__scripts and self.__scripts.OnTextChanged
	if fn and self.__kind == "EditBox" then fn(self, false) end
end
function M:GetText() return self.__text end

-- Шрифты: аддон берёт уже установленный шрифт и меняет только размер
function M:GetFont()
	return self.__fontFile or "Fonts\\FRIZQT__.TTF", self.__fontSize or 12, self.__fontFlags or ""
end
function M:SetFont(file, size, flags)
	self.__fontFile = file
	self.__fontSize = size
	self.__fontFlags = flags
	if STUB.fontError then return false end
	return true
end
function M:GetFontString()
	if not self.__fontString then
		self.__fontString = NewWidget("FontString", nil, self, "GameFontNormal")
	end
	return self.__fontString
end
function M:SetParent(parent)
	if self.__parent and self.__parent.__children then
		for i, c in ipairs(self.__parent.__children) do
			if c == self then table.remove(self.__parent.__children, i) break end
		end
	end
	self.__parent = parent
	if parent and parent.__children then table.insert(parent.__children, self) end
	self.__rect = nil
	return self
end
function M:SetJustifyH(j) self.__justifyH = j end
function M:SetJustifyV(j) self.__justifyV = j end
function M:SetAutoFocus(v) self.__autoFocus = v end
function M:SetFocus() STUB.focused = self end
function M:ClearFocus() if STUB.focused == self then STUB.focused = nil end end
function M:HasFocus() return STUB.focused == self end
function M:HighlightText() end
function M:SetMaxLetters(n) end
function M:SetNumeric(v) end
function M:SetTextInsets(a, b, c, d) end

function M:CreateFontString(name, layer, template)
	return NewWidget("FontString", name, self, template)
end
function M:CreateTexture(name, layer)
	return NewWidget("Texture", name, self, nil)
end
function M:CreateFont(name, template)
	return NewWidget("Font", name, self, template)
end
function M:GetChildren() return self.__children end
function M:GetRegions() return self.__regions end
function M:GetNumChildren() return #self.__children end

function M:SetTexture(a, b, c, d)
	if type(a) == "string" then self.__texture = a else self.__rgba = { a, b, c, d } end
end
function M:SetVertexColor(a, b, c, d) self.__rgba = { a, b, c, d } end
function M:SetAlpha(a) self.__alpha = a end
function M:SetBlendMode(m) end
function M:SetAllPoints(f) if f then self:SetPoint("TOPLEFT", f, "TOPLEFT") self:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT") end end

function M:SetChecked(v) self.__checked = v and true or false end
function M:GetChecked() return self.__checked end
function M:SetHighlightTexture(t)
	self.__highlight = t
	if not self.__highlightWidget then
		self.__highlightWidget = NewWidget("Texture", nil, self, nil)
	end
	return self.__highlightWidget
end
function M:GetHighlightTexture()
	if not self.__highlightWidget then
		self.__highlightWidget = NewWidget("Texture", nil, self, nil)
	end
	return self.__highlightWidget
end
function M:SetNormalTexture(t) self.__normalTexture = t end
function M:SetPushedTexture(t) self.__pushedTexture = t end
function M:SetDisabledTexture(t) self.__disabledTexture = t end
function M:GetNormalTexture() return self.__normalTexture end
function M:LockHighlight() self.__locked = true end
function M:UnlockHighlight() self.__locked = false end
function M:RegisterForClicks(...) self.__clicks = { ... } end
function M:RegisterForDrag(...) self.__drag = { ... } end
function M:SetMovable(v) self.__movable = v end
function M:SetClampedToScreen(v) self.__clamped = v end
function M:SetToplevel(v) self.__toplevel = v end
function M:EnableMouse(v) self.__mouse = v end
function M:EnableMouseWheel(v) self.__mouseWheel = v end
function M:SetFrameStrata(s) self.__strata = s end
function M:GetFrameStrata() return self.__strata end
function M:SetFrameLevel(l) self.__level = l end
function M:GetFrameLevel() return self.__level or 1 end
function M:Raise() end
function M:StartMoving() end
function M:StopMovingOrSizing() end
function M:SetBackdrop(t) self.__backdrop = t end
function M:SetBackdropColor(...) self.__backdropColor = { ... } end
function M:SetBackdropBorderColor(...) self.__backdropBorderColor = { ... } end
function M:SetID(id) self.__id = id end
function M:GetID() return self.__id end

-- ScrollFrame
function M:SetScrollChild(child) self.__scrollChild = child end
function M:GetScrollChild() return self.__scrollChild end
function M:GetVerticalScroll() return self.__verticalScroll or 0 end
function M:SetVerticalScroll(v) self.__verticalScroll = v STUB.lastScroll = v end
function M:GetHorizontalScroll() return 0 end
function M:SetHorizontalScroll(v) end
function M:UpdateScrollChildRect() end

-- Slider
function M:SetMinMaxValues(minv, maxv) self.__min, self.__max = minv, maxv end
function M:GetMinMaxValues() return self.__min or 0, self.__max or 0 end
function M:SetValue(v)
	local changed = self.__value ~= v
	self.__value = v
	if changed or true then
		local fn = self.__scripts and self.__scripts.OnValueChanged
		if fn then fn(self, v) end
	end
end
function M:GetValue() return self.__value or 0 end
function M:SetOrientation(o) end

-- Tooltip
function M:SetOwner(o, a) self.__owner = o self.__anchor = a end
function M:AddLine(...) table.insert(self.__lines or {}, { ... }) end
function M:AddDoubleLine(...) end
function M:ClearLines() self.__lines = {} end
function M:NumLines() return #(self.__lines or {}) end
function M:GetLine(i) return "line" end
function M:SetTextColor(r, g, b, a)
	self.__textColor = { r, g, b, a }
end
function M:GetTextColor()
	local c = self.__textColor or { 1, 1, 1, 1 }
	return c[1], c[2], c[3], c[4]
end

--===========================================================================
-- CreateFrame
--===========================================================================
UIParent = NewWidget("Frame", "UIParent", nil, nil)
UIParent:SetSize(1024, 768)

Minimap = NewWidget("Frame", "Minimap", nil, nil)
Minimap:SetSize(140, 140)
Minimap:SetFrameLevel(2)

function CreateFrame(kind, name, parent, template)
	return NewWidget(kind, name, parent, template)
end

--===========================================================================
-- Чат, события, команды
--===========================================================================
DEFAULT_CHAT_FRAME = NewWidget("ScrollingMessageFrame", "DEFAULT_CHAT_FRAME", UIParent, nil)
function DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b)
	table.insert(STUB.chat, tostring(msg))
end

function SendChatMessage(msg, channel)
	table.insert(STUB.sent, { msg = msg, channel = channel })
end

function UnitFactionGroup(unit) return STUB.faction end
function IsShiftKeyDown() return STUB.shift and true or false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function GetAddOnMemoryUsage(name) return STUB.memoryKB or 864 end

-- профайлер: как в игре, растёт с каждым вызовом
function debugprofilestop()
	STUB.clock = (STUB.clock or 0) + 0.5
	return STUB.clock
end
function UnitName(unit) return "TestPlayer" end
function ReloadUI() STUB.reloads = STUB.reloads + 1 end
function GetLocale() return STUB.locale end
function GetTime() return 0 end

UISpecialFrames = {}
SlashCmdList = {}

-- Клик по ссылке в чате (ники, предметы) и хуки
STUB.hooks = {}
function SetItemRef(link, text, button) end
function hooksecurefunc(nameOrFunc, fn)
	local key = type(nameOrFunc) == "string" and nameOrFunc or "func"
	STUB.hooks[key] = STUB.hooks[key] or {}
	table.insert(STUB.hooks[key], fn)
end

-- Вызвать хук как в игре: hooksecurefunc("SetItemRef", fn) → после SetItemRef
function STUB.CallHook(name, ...)
	local list = STUB.hooks[name]
	if not list then return 0 end
	for _, fn in ipairs(list) do pcall(fn, ...) end
	return #list
end

--===========================================================================
-- Попапы
--===========================================================================
StaticPopupDialogs = {}

function StaticPopup_Show(which, arg1, arg2)
	local info = StaticPopupDialogs[which]
	if not info then
		STUB.popupError = "нет диалога " .. tostring(which)
		return nil
	end
	local dialog = {
		which = which,
		info = info,
		text_arg1 = arg1,
		text_arg2 = arg2,
		data = nil,
	}
	dialog.GetText = function(self) return info.text end
	table.insert(STUB.popups, dialog)
	STUB.visiblePopup = dialog
	return dialog
end

function StaticPopup_FindVisible(which)
	if STUB.visiblePopup and STUB.visiblePopup.which == which then return STUB.visiblePopup end
	return nil
end

function StaticPopup_Hide(which)
	if STUB.visiblePopup and (not which or STUB.visiblePopup.which == which) then STUB.visiblePopup = nil end
end
StaticPopup_Visible = StaticPopup_Hide

-- Кнопка «Да» в тестах
function STUB.AcceptPopup(which)
	local dialog = STUB.visiblePopup
	if not dialog then return false end
	if which and dialog.which ~= which then return false end
	local info = dialog.info
	STUB.visiblePopup = nil
	if info and info.OnAccept then
		info.OnAccept(dialog, dialog.data)
		return true
	end
	return false
end

--===========================================================================
-- Выпадающие меню
--===========================================================================
UIDROPDOWNMENU_MENU_VALUE = nil
MENU = "MENU"

function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info, level)
	local menu = STUB.currentMenu
	if menu then
		menu.entries = menu.entries or {}
		table.insert(menu.entries, { info = info, level = level or 1 })
	end
end
function UIDropDownMenu_Initialize(menu, init, mode)
	menu.init = init
	menu.displayMode = mode
	table.insert(STUB.menus, menu)
	STUB.currentMenu = menu
	menu.entries = {}
	local ok, err = pcall(init, menu, 1)
	menu.initError = (not ok) and err or nil
	STUB.currentMenu = nil
end
function UIDropDownMenu_SetSelectedValue() end
function UIDropDownMenu_SetWidth() end
function ToggleDropDownMenu(level, value, menu, anchor, x, y)
	table.insert(STUB.dropdownOpened, menu)
	STUB.lastDropdown = menu
	STUB.lastDropdownAnchor = anchor
	-- как в игре: при открытии меню заново строится список пунктов
	if menu and menu.init then
		STUB.currentMenu = menu
		menu.entries = {}
		local ok, err = pcall(menu.init, menu, level or 1)
		menu.initError = (not ok) and err or nil
		STUB.currentMenu = nil
	end
end
function CloseDropDownMenus() STUB.dropdownClosed = true end

--===========================================================================
-- Тултип
--===========================================================================
GameTooltip = NewWidget("GameTooltip", "GameTooltip", UIParent, nil)

--===========================================================================
-- Мелкие глобальные функции и константы, как в игре
--===========================================================================
tinsert = table.insert
tremove = table.remove
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strtrim = function(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
strsplit = function(sep, str) return str end
format = string.format
yes, no = true, false

YES, NO, OK, CANCEL = "YES", "NO", "OK", "CANCEL"
MENU = "MENU"
ANCHOR_RIGHT, ANCHOR_LEFT, ANCHOR_CURSOR = "ANCHOR_RIGHT", "ANCHOR_LEFT", "ANCHOR_CURSOR"
ARTWORK, BACKGROUND, OVERLAY = "ARTWORK", "BACKGROUND", "OVERLAY"
TOPLEFT, TOP, TOPRIGHT = "TOPLEFT", "TOP", "TOPRIGHT"
LEFT, CENTER, RIGHT = "LEFT", "CENTER", "RIGHT"
BOTTOMLEFT, BOTTOM, BOTTOMRIGHT = "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"

GameFontNormal        = "GameFontNormal"
GameFontNormalSmall   = "GameFontNormalSmall"
GameFontHighlight     = "GameFontHighlight"
GameFontHighlightLarge = "GameFontHighlightLarge"
GameFontDisableSmall  = "GameFontDisableSmall"
GameFontDisable       = "GameFontDisable"
NumberFontNormal      = "NumberFontNormal"

UIPanelButtonTemplate      = "UIPanelButtonTemplate"
InputBoxTemplate           = "InputBoxTemplate"
UICheckButtonTemplate      = "UICheckButtonTemplate"
UIPanelScrollFrameTemplate = "UIPanelScrollFrameTemplate"
UIDropDownMenuTemplate     = "UIDropDownMenuTemplate"
UIPanelCloseButton         = "UIPanelCloseButton"

SAY, YELL, PARTY, RAID, GUILD, WHISPER = "SAY", "YELL", "PARTY", "RAID", "GUILD", "WHISPER"

--===========================================================================
-- Утилиты для тестов
--===========================================================================
function STUB.Click(widget, mouse)
	local fn = widget.__scripts and widget.__scripts.OnClick
	if not fn then return false, "нет OnClick" end
	local ok, err = pcall(fn, widget, mouse or "LeftButton")
	if not ok then
		STUB.lastError = err
		return false, err
	end
	return true
end

function STUB.Enter(widget)
	local fn = widget.__scripts and widget.__scripts.OnEnter
	if fn then pcall(fn, widget) end
end

function STUB.Leave(widget)
	local fn = widget.__scripts and widget.__scripts.OnLeave
	if fn then pcall(fn, widget) end
end

function STUB.FireEvent(frame, event, ...)
	local fn = frame.__scripts and frame.__scripts.OnEvent
	if not fn then return false, "нет OnEvent" end
	local ok, err = pcall(fn, frame, event, ...)
	if not ok then
		STUB.lastError = err
		return false, err
	end
	return true
end

-- Разослать событие всем, кто на него подписан (эмуляция событий клиента)
function STUB.FireAll(event, ...)
	local handled = 0
	for _, f in ipairs(STUB.frames) do
		if f.__events and f.__events[event] then
			local ok, err = STUB.FireEvent(f, event, ...)
			handled = handled + 1
			if not ok then
				STUB.eventError = { event = event, err = err }
			end
		end
	end
	return handled
end

function STUB.ClearSent() STUB.sent = {} end

-- Ввод текста пользователем (OnTextChanged с userInput=true)
function STUB.Type(widget, text)
	widget.__text = text
	local fn = widget.__scripts and widget.__scripts.OnTextChanged
	if fn then pcall(fn, widget, true) end
end

function STUB.Focus(widget)
	local fn = widget.__scripts and widget.__scripts.OnEditFocusGained
	if fn then pcall(fn, widget) end
	STUB.focused = widget
end
function STUB.LastCommand()
	local last = STUB.sent[#STUB.sent]
	return last and last.msg or nil
end

-- Найти первый виджет по типу с заданным текстом (для клика по вкладке)
function STUB.FindNamed(name) return _G[name] end
