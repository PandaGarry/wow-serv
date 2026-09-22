--===========================================================================
-- Admin Tools RU — Tab_Settings.lua
-- Вкладка «Настройки»: видимость вкладок, эхо команд, уровень доступа,
-- масштаб окна, сброс позиций.
--
-- Внимание: вкладка строится ДО загрузки сохранённых переменных, поэтому
-- все значения подставляются в AT.RefreshSettings(), которую ядро вызывает
-- после ADDON_LOADED.
--===========================================================================

local p = AT.RegisterTab("Настройки")

local tabCheckboxes = {}   -- галочки видимости вкладок
local behaviorChecks = {}  -- галочки поведения
local secBtn, scaleLabel, fontLabel

--===========================================================================
-- Хелперы
--===========================================================================
local function MakeCheck(key, label, getter, setter, y)
	local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	cb:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y)
	cb.Text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	cb.Text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
	cb.Text:SetText(label)
	cb.__getter = getter
	cb:SetScript("OnClick", function(self)
		setter(self:GetChecked() and true or false)
		-- после смены настройки перечитываем состояние всех элементов
		if AT.RefreshSettings then AT.RefreshSettings() end
	end)
	if key then behaviorChecks[key] = cb end
	AT.NoteY(p, y - 28)
	return cb, y - 28
end

function AT.RefreshSettings()
	if not p then return end
	local db = AdminToolsDB or {}

	if secBtn then
		secBtn:SetText("Мой уровень доступа: " .. AT.SecName(db.mySec or 3) .. " |cff888888(нажми, чтобы сменить)|r")
	end

	for key, cb in pairs(behaviorChecks) do
		if cb.__getter then cb:SetChecked(cb.__getter() and true or false) end
	end

	for _, cb in ipairs(tabCheckboxes) do
		cb:SetChecked(AT.IsTabVisible(cb.tabName))
	end

	-- %.0f, а не %d: масштаб — дробное число, %d с ним падает в Lua 5.3+
	if scaleLabel then scaleLabel:SetText(string.format("%.0f%%", AT.GetScale() * 100)) end
	if fontLabel then
		local d = AT.GetFontSizeDelta()
		fontLabel:SetText((d > 0 and "+" or "") .. d .. " пт")
	end

	-- перекрасить кнопки-команды: доступные — цветом уровня, закрытые — серым
	AT.RefreshLocks()
	AT.RefreshFavorites()
end

--===========================================================================
-- Уровень доступа
--===========================================================================
local y = AT.MakeSection(p, "Уровень доступа", -2)

local secLegend = AT.MakeLabel(p,
	"1 — " .. AT.SecName(1) .. "   2 — " .. AT.SecName(2) .. "   3 — " .. AT.SecName(3),
	"GameFontDisableSmall")
secLegend:SetJustifyH("LEFT")
secLegend:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - 20

secBtn = AT.MakeButton(p, "Мой уровень доступа: —", 340, function(self)
	local nextSec = AT.GetMySec() + 1
	if nextSec > 3 then nextSec = 1 end
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.mySec = nextSec
	AT.RefreshSettings()
	AT.Print("Уровень доступа в панели: " .. AT.SecName(nextSec))
end, nil, "Твой уровень GM. Влияет только на подсветку и блокировку кнопок в панели.")
secBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - 30

local _, newY = MakeCheck("restrict",
	"Блокировать кнопки выше моего уровня доступа",
	function() return AdminToolsDB and AdminToolsDB.restrictBySec end,
	function(v)
		AdminToolsDB = AdminToolsDB or {}
		AdminToolsDB.restrictBySec = v and true or false
		AT.Print("Блокировка по уровню доступа: " .. (v and "|cff33ff99включена|r" or "|cffff5555выключена|r"))
	end, y)
y = newY

--===========================================================================
-- Поведение
--===========================================================================
y = AT.MakeSection(p, "Поведение", y - 6)

_, y = MakeCheck("echo",
	"Показывать выполненные команды в чате",
	function() return AT.EchoEnabled() end,
	function(v)
		AdminToolsDB = AdminToolsDB or {}
		AdminToolsDB.echo = v and true or false
	end, y)

_, y = MakeCheck("minimap",
	"Показывать кнопку на миникарте",
	function()
		return not (AdminToolsDB and AdminToolsDB.minimapHidden)
	end,
	function(v)
		AdminToolsDB = AdminToolsDB or {}
		AT.SetMinimapShown(v)
		local btn = _G["AdminToolsRUMMBtn"]
		if btn then
			if v then btn:Show() else btn:Hide() end
		end
	end, y)

--===========================================================================
-- Масштаб окна
--===========================================================================
y = AT.MakeSection(p, "Масштаб окна", y - 6)

scaleLabel = AT.MakeLabel(p, "100%", "GameFontNormalSmall")
scaleLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 132, y - 5)

local minusBtn = AT.MakeButton(p, "-", 34, function()
	AT.SetScale(AT.GetScale() - 0.05)
	AT.RefreshSettings()
end, nil, "Уменьшить интерфейс панели")
minusBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local plusBtn = AT.MakeButton(p, "+", 34, function()
	AT.SetScale(AT.GetScale() + 0.05)
	AT.RefreshSettings()
end, nil, "Увеличить интерфейс панели")
plusBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 46, y)

local resetScaleBtn = AT.MakeButton(p, "Сбросить масштаб", 150, function()
	AT.SetScale(1)
	AT.RefreshSettings()
end, nil, "Вернуть масштаб 100%")
resetScaleBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 200, y)
y = y - 30

--===========================================================================
-- Шрифт (размер текста; сам шрифт берётся из клиента — кириллица гарантирована)
--===========================================================================
y = AT.MakeSection(p, "Шрифт панели", y - 4)

fontLabel = AT.MakeLabel(p, "0 пт", "GameFontNormalSmall")
fontLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 132, y - 5)

local fontMinus = AT.MakeButton(p, "Мельче", 80, function()
	AT.SetFontSizeDelta(AT.GetFontSizeDelta() - 1)
	AT.RefreshSettings()
	AT.Print("Размер текста: " .. AT.GetFontSizeDelta() .. " пт")
end, nil, "Уменьшить текст панели на 1 пункт")
fontMinus:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local fontPlus = AT.MakeButton(p, "Крупнее", 80, function()
	AT.SetFontSizeDelta(AT.GetFontSizeDelta() + 1)
	AT.RefreshSettings()
	AT.Print("Размер текста: " .. AT.GetFontSizeDelta() .. " пт")
end, nil, "Увеличить текст панели на 1 пункт")
fontPlus:SetPoint("TOPLEFT", p, "TOPLEFT", 92, y)

local fontReset = AT.MakeButton(p, "Сбросить шрифт", 130, function()
	AT.SetFontSizeDelta(0)
	AT.RefreshSettings()
	AT.Print("Размер текста сброшен (0 пт).")
end, nil, "Вернуть исходный размер текста")
fontReset:SetPoint("TOPLEFT", p, "TOPLEFT", 178, y)
y = y - 28

local fontNote = AT.MakeLabel(p,
	"Шрифт не подменяется — берётся тот, что уже использует клиент, поэтому русский\n" ..
	"текст корректен и на ruRU, и на enUS. Настраивается только размер.",
	"GameFontDisableSmall")
fontNote:SetJustifyH("LEFT")
fontNote:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - 36

--===========================================================================
-- Видимость вкладок
--===========================================================================
y = AT.MakeSection(p, "Видимость вкладок", y - 6)

local desc = AT.MakeLabel(p,
	"Сними галочку, чтобы скрыть ненужную вкладку. Настройки сохраняются автоматически.",
	"GameFontDisableSmall")
desc:SetJustifyH("LEFT")
desc:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 2)
y = y - 22

for _, tabName in ipairs(AT.TABS) do
	if tabName ~= "Настройки" then
		local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
		cb:SetSize(24, 24)
		cb:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y)
		cb.Text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		cb.Text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
		cb.Text:SetText("Вкладка «" .. tabName .. "»")
		cb.tabName = tabName
		cb:SetScript("OnClick", function(self)
			AT.SetTabVisible(self.tabName, self:GetChecked() and true or false)
			AT.ApplyTabVisibility()
		end)
		table.insert(tabCheckboxes, cb)
		y = y - 26
	end
end
AT.NoteY(p, y)

local showAllBtn = AT.MakeButton(p, "Показать все вкладки", 200, function()
	for _, tabName in ipairs(AT.TABS) do
		AT.SetTabVisible(tabName, true)
	end
	AT.ApplyTabVisibility()
	AT.RefreshSettings()
	AT.Print("Все вкладки включены.")
end, 1, "Включить все вкладки обратно")
showAllBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y - 10)
y = y - 42

--===========================================================================
-- Позиции и сброс
--===========================================================================
y = AT.MakeSection(p, "Позиции и сброс", y - 6)

local posBtn = AT.MakeButton(p, "Сбросить позицию окна", 190, function()
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.pos = nil
	AT.frame:ClearAllPoints()
	AT.frame:SetPoint("CENTER")
	AT.Print("Позиция окна сброшена.")
end, nil, "Вернуть окно в центр экрана")
posBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local mmResetBtn = AT.MakeButton(p, "Позиция кнопки миникарты", 220, function()
	AdminToolsDB = AdminToolsDB or {}
	AdminToolsDB.minimapPos = nil
	AT.RestoreMinimapPos()
	AT.Print("Позиция кнопки на миникарте сброшена.")
end, nil, "Вернуть кнопку к левому нижнему углу миникарты")
mmResetBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6 + 196, y)
y = y - 32

local favResetBtn = AT.MakeButton(p, "Очистить избранное", 190, function()
	AT.GetFavorites()
	wipe(AdminToolsDB.favorites)
	AT.RefreshFavorites()
	AT.Print("Избранное очищено.")
end, nil, "Убрать все кнопки из строки «Избранное» в шапке")
favResetBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6 + 196 + 228, y)

local note = AT.MakeLabel(p,
	"Полный сброс всех настроек — команда |cff33ff99/atreset|r (перезагрузит интерфейс).",
	"GameFontDisableSmall")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

AT.NoteY(p, y - 30)
