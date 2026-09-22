--===========================================================================
-- Admin Tools RU — Tab_Interface.lua
-- Вкладка «Интерфейс»: темы оформления, размер и положение окна,
-- кнопка на миникарте, чтение интерфейса.
--
-- Всё применяется мгновенно: тема — перекраска текстур, размер и положение —
-- якоря, поэтому перезагрузка интерфейса не нужна.
--===========================================================================

local p = AT.RegisterTab("Интерфейс")

--===========================================================================
-- Темы оформления
--===========================================================================
local y = AT.MakeSection(p, "Тема оформления", -2)

local themeSwatches = {}

local function MakeSwatch(themeKey, index)
	local theme = AT.Themes[themeKey]
	local b = AT.MakeButton(p, theme.name, 130, function()
		AT.ApplyTheme(themeKey)
		AT.RefreshThemeSwatches()
	end, nil, "Тема «" .. theme.name .. "»: меняются фон, рамка и акцентный цвет")

	b:SetPoint("TOPLEFT", p, "TOPLEFT", 6 + (index - 1) * 136, y)

	-- цветной образец темы прямо на кнопке
	local sw = b:CreateTexture(nil, "ARTWORK")
	sw:SetTexture(AT.SKIN.panel)
	sw:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.85)
	sw:SetSize(10, 10)
	sw:SetPoint("TOPLEFT", b, "TOPLEFT", 6, -6)
	b.__swatch = sw

	themeSwatches[themeKey] = b
	return b
end

for i, key in ipairs(AT.THEME_ORDER) do
	MakeSwatch(key, i)
end

local themeCount = #AT.THEME_ORDER
y = y - 26

local themeLabel = AT.MakeLabel(p, "", "GameFontDisableSmall")
themeLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

function AT.RefreshThemeSwatches()
	if not themeLabel then return end
	local theme = AT.Themes[AT.GetThemeKey()] or AT.Themes.cyan
	themeLabel:SetText("Сейчас: " .. theme.name
		.. ". Тема сохраняется и меняет вид всей панели.")

	for key, b in pairs(themeSwatches) do
		local active = (key == AT.GetThemeKey())
		local fs = b:GetFontString()
		if fs then
			if active then
				fs:SetTextColor(1, 1, 1)
			else
				fs:SetTextColor(AT.THEME.textDim[1], AT.THEME.textDim[2], AT.THEME.textDim[3])
			end
		end
	end
end

y = y - 20

--===========================================================================
-- Размер окна
--===========================================================================
y = AT.MakeSection(p, "Размер окна", y - 4)

local sizeLabel = AT.MakeLabel(p, "", "GameFontNormalSmall")
sizeLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 300, y - 5)

for i, size in ipairs(AT.WINDOW_SIZES) do
	local b = AT.MakeButton(p, size[1], 140, function()
		AT.SetWindowSize(i)
		AT.RefreshInterfaceSettings()
	end, nil, "Размер окна: " .. size[2] .. "x" .. size[3])
	b:SetPoint("TOPLEFT", p, "TOPLEFT", 6 + (i - 1) * 146, y)
end

y = y - 26

--===========================================================================
-- Положение окна
--===========================================================================
y = AT.MakeSection(p, "Положение окна", y - 4)

for i, pos in ipairs(AT.WINDOW_POSITIONS) do
	local b = AT.MakeButton(p, pos[1], 140, function()
		AT.SetWindowPosition(i)
		AT.Print("Окно перемещено: " .. pos[1] .. ". Можно перетаскивать мышью за шапку.")
	end, nil, "Переместить окно: " .. pos[1])
	b:SetPoint("TOPLEFT", p, "TOPLEFT", 6 + (i - 1) * 146, y)
end

y = y - 26

local posNote = AT.MakeLabel(p,
	"Позиция сохраняется, когда перетаскиваешь окно за шапку мышью.",
	"GameFontDisableSmall")
posNote:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - 24

--===========================================================================
-- Кнопка на миникарте
--===========================================================================
y = AT.MakeSection(p, "Кнопка на миникарте", y - 4)

local showMM = AT.MakeButton(p, "", 200, function(self)
	AT.SetMinimapShown(not AT.IsMinimapShown())
	AT.RefreshInterfaceSettings()
end, nil, "Показать или скрыть кнопку панели на миникарте")
showMM:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local mmLabel = AT.MakeLabel(p, "", "GameFontNormalSmall")
mmLabel:SetPoint("LEFT", showMM, "RIGHT", 12, 0)

y = y - 26

local mmHint = AT.MakeLabel(p, "Угол на окружности миникарты:", "GameFontNormalSmall")
mmHint:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

y = y - 18

local angleDefs = {}
for _, deg in ipairs({ 180, 135, 90, 45, 0, 315, 270, 225 }) do
	angleDefs[#angleDefs + 1] = { tostring(deg), function()
		AT.SetMinimapAngle(deg)
		AT.RefreshInterfaceSettings()
	end, 56, nil, "Поставить кнопку под углом " .. deg .. " градусов" }
end
angleDefs[#angleDefs + 1] = { "По умолчанию", function()
	AT.SetMinimapAngle(-1)
	AT.RefreshInterfaceSettings()
end, 130, nil, "Вернуть кнопку в левый нижний угол миникарты" }

y = AT.FlowButtons(p, angleDefs, y)

--===========================================================================
-- Чтение интерфейса
--===========================================================================
y = AT.MakeSection(p, "Чтение интерфейса", y - 4)

AT.MakeCheckbox(p, "Подсветка строк при наведении", function()
	return AT.RowHighlightEnabled()
end, function(v)
	AT.SetRowHighlight(v)
	if v then
		AT.Print("Подсветка строк включена — применится после перезагрузки интерфейса "
			.. "(/reload), потому что полосы создаются вместе со строками.")
	else
		AT.Print("Подсветка строк выключена.")
	end
end, y, "Полупрозрачная полоса под строкой кнопок и полей")

y = y - 26

AT.MakeCheckbox(p, "Всплывающие подсказки", function()
	return AT.TooltipsEnabled()
end, function(v)
	AT.SetTooltipsEnabled(v)
	AT.Print(v and "Подсказки включены." or "Подсказки выключены.")
end, y, "Описания кнопок и уровней доступа")

y = y - 26

AT.MakeCheckbox(p, "Поля фильтра на вкладках", function()
	return AT.FiltersEnabled()
end, function(v)
	AT.SetFiltersEnabled(v)
	AT.Print(v and "Фильтр показывается на больших вкладках." or "Фильтр скрыт.")
end, y, "Строка «поиск…» над списком кнопок")

y = y - 26

AT.MakeCheckbox(p, "Кнопка панели на миникарте", function()
	return AT.IsMinimapShown()
end, function(v)
	AT.SetMinimapShown(v)
end, y, "Дублирует переключатель выше — для удобства")

y = y - 30

--===========================================================================
-- Акцентный цвет
--===========================================================================
y = AT.MakeSection(p, "Акцентный цвет", y - 4)

local accentSwatches = {}

for i, entry in ipairs(AT.ACCENTS) do
	local col = (i - 1) % 4
	local row = AT.floor((i - 1) / 4)
	local b = AT.MakeButton(p, entry.name, 140, function()
		AT.SetAccent(entry.key)
		AT.RefreshInterfaceSettings()
	end, nil, "Акцент «" .. entry.name .. "»: цвет заголовков, линий, активной вкладки")

	b:SetPoint("TOPLEFT", p, "TOPLEFT", 6 + col * 146, y - row * 26)

	if entry.color then
		local sw = b:CreateTexture(nil, "ARTWORK")
		sw:SetTexture(AT.SKIN.panel)
		sw:SetVertexColor(entry.color[1], entry.color[2], entry.color[3], 0.9)
		sw:SetSize(10, 10)
		sw:SetPoint("TOPLEFT", b, "TOPLEFT", 6, -6)
		b.__swatch = sw
	end
	accentSwatches[entry.key] = b
end

y = y - 2 * 26 - 4

--===========================================================================
-- Стиль кнопок
--===========================================================================
y = AT.MakeSection(p, "Стиль кнопок", y - 4)

local styleFlat = AT.MakeButton(p, "Плоский", 140, function()
	AT.SetButtonStyle("flat")
	AT.RefreshInterfaceSettings()
end, nil, "Как сейчас: прямоугольные кнопки с градиентом")

styleFlat:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local styleRound = AT.MakeButton(p, "Скруглённый", 140, function()
	AT.SetButtonStyle("rounded")
	AT.RefreshInterfaceSettings()
end, nil, "Скруглённые углы: торцевые текстуры в натуральную высоту")

styleRound:SetPoint("TOPLEFT", p, "TOPLEFT", 152, y)

y = y - 26

--===========================================================================
-- Звук
--===========================================================================
y = AT.MakeSection(p, "Звук", y - 4)

AT.MakeCheckbox(p, "Звук при выполнении команды", function()
	return AT.SoundEnabled()
end, function(v)
	AT.SetSoundEnabled(v)
	AT.Print(v and "Звук включён." or "Звук выключен.")
end, y, "Короткий сигнал клиента при отправке команды (по умолчанию выключен)")

y = y - 26

--===========================================================================
-- Горячие клавиши
--===========================================================================
y = AT.MakeSection(p, "Горячие клавиши", y - 4)

local hotkeyRows = {}

for i, hk in ipairs(AT.HOTKEY_ACTIONS) do
	local rowY = y - (i - 1) * 26

	local name = AT.MakeLabel(p, hk[1], "GameFontNormalSmall")
	name:SetPoint("TOPLEFT", p, "TOPLEFT", 6, rowY - 5)

	local keyText = AT.MakeLabel(p, "не назначена", "GameFontDisableSmall")
	keyText:SetPoint("TOPLEFT", p, "TOPLEFT", 170, rowY - 5)

	local assign = AT.MakeButton(p, "Назначить", 100, function()
		AT.captureLabel = statusLabel
		AT.StartCapture(hk[2], statusLabel)
	end, nil, "Нажми, затем нажми нужную клавишу (Esc — отмена)")
	assign:SetPoint("TOPLEFT", p, "TOPLEFT", 300, rowY)

	local clear = AT.MakeButton(p, "Сброс", 70, function()
		AT.ClearHotkey(hk[2])
		AT.RefreshInterfaceSettings()
	end, nil, "Снять назначенную клавишу")
	clear:SetPoint("TOPLEFT", p, "TOPLEFT", 406, rowY)

	hotkeyRows[#hotkeyRows + 1] = { action = hk[2], label = keyText }
end

y = y - #AT.HOTKEY_ACTIONS * 26 - 4

local statusLabel = AT.MakeLabel(p, "Нажми «Назначить», затем нужную клавишу.",
	"GameFontDisableSmall")
statusLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
AT.captureLabel = statusLabel

y = y - 22

--===========================================================================
-- Экспорт и импорт настроек
--===========================================================================
y = AT.MakeSection(p, "Экспорт и импорт настроек", y - 4)

local expNote = AT.MakeLabel(p,
	"Скопируй строку в буфер (Ctrl+C) и вставь на другом персонаже (Ctrl+V),",
	"GameFontDisableSmall")
expNote:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local expNote2 = AT.MakeLabel(p,
	"затем нажми «Импорт из поля». Переносятся тема, акценты, избранное и свои кнопки.",
	"GameFontDisableSmall")
expNote2:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 14)

y = y - 34

local exportBox = AT.MakeMultiEdit(p, 520, 64)
exportBox:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local exportStatus = AT.MakeLabel(p, "", "GameFontDisableSmall")
exportStatus:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 74)

local expBtn = AT.MakeButton(p, "Экспорт в поле", 150, function()
	local text = AT.BuildExportString()
	exportBox:SetText(text)
	exportBox:SetFocus()
	exportBox:HighlightText()
	exportStatus:SetText("Строка настроек готова — нажми Ctrl+C, чтобы скопировать.")
	AT.Print("Настройки выгружены в поле. Ctrl+C — скопировать.")
end, nil, "Собрать текущие настройки в строку")
expBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 96)

local impBtn = AT.MakeButton(p, "Импорт из поля", 150, function()
	local applied, msg = AT.ImportString(exportBox:GetText())
	exportStatus:SetText(msg)
	if applied > 0 then
		AT.Print("Настройки применены: " .. applied .. " строк.")
	else
		AT.PrintErr(msg)
	end
end, nil, "Применить настройки из строки в поле")
impBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 162, y - 96)

local clrBtn = AT.MakeButton(p, "Очистить поле", 130, function()
	exportBox:SetText("")
	exportStatus:SetText("")
end, nil, "Убрать текст из поля")
clrBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 318, y - 96)

y = y - 96 - 26

--===========================================================================
-- Диагностика
--===========================================================================
y = AT.MakeSection(p, "Диагностика", y - 4)

y = AT.FlowButtons(p, {
	{ "Замер (/atbench)",  function() AT.Bench() end, 180, nil, "Измерить скорость переключения вкладок и подсчитать элементы" },
	{ "Сбросить позиции",  function()
		AdminToolsDB.pos = nil
		AdminToolsDB.minimapPos = nil
		AdminToolsDB.minimapAngle = -1
		AT.SetWindowPosition(1)
		AT.SetMinimapAngle(-1)
		AT.Print("Позиции окна и кнопки миникарты сброшены.")
	end, 190, nil, "Вернуть окно в центр, а кнопку — в левый нижний угол" },
}, y)

local benchNote = AT.MakeLabel(p,
	"Замер показывает стоимость переключения вкладок и пересчёта высоты — если",
	"GameFontDisableSmall")
benchNote:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)

local benchNote2 = AT.MakeLabel(p,
	"панель начнёт тормозить, эти цифры покажут, где именно.",
	"GameFontDisableSmall")
benchNote2:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 14)

--===========================================================================
-- Обновление состояния при открытии вкладки
--===========================================================================
function AT.RefreshInterfaceSettings()
	if not p then return end

	if sizeLabel then sizeLabel:SetText(AT.WindowSizeLabel()) end

	local theme = AT.Themes[AT.GetThemeKey()] or AT.Themes.cyan
	if themeLabel then
		themeLabel:SetText("Сейчас: " .. theme.name .. ". Тема сохраняется и меняет вид всей панели.")
	end

	if showMM then
		showMM:SetText(AT.IsMinimapShown() and "Скрыть кнопку миникарты" or "Показать кнопку миникарты")
	end
	if mmLabel then
		local angle = AT.GetMinimapAngle()
		mmLabel:SetText(angle < 0 and "по умолчанию (левый низ)"
			or ("угол " .. angle .. " градусов"))
	end

	-- акценты: подсветить выбранный
	local accentKey = (AdminToolsDB and AdminToolsDB.accent) or "theme"
	for key, b in pairs(accentSwatches) do
		local fs = b:GetFontString()
		if fs then
			if key == accentKey then
				fs:SetTextColor(1, 1, 1)
			else
				fs:SetTextColor(AT.THEME.textDim[1], AT.THEME.textDim[2],
					AT.THEME.textDim[3])
			end
		end
	end

	-- стиль кнопок
	local rounded = (AT.ButtonStyle() == "rounded")
	local flatFs = styleFlat and styleFlat:GetFontString()
	local roundFs = styleRound and styleRound:GetFontString()
	if flatFs then
		flatFs:SetTextColor(rounded and AT.THEME.textDim[1] or 1,
			rounded and AT.THEME.textDim[2] or 1,
			rounded and AT.THEME.textDim[3] or 1)
	end
	if roundFs then
		roundFs:SetTextColor(rounded and 1 or AT.THEME.textDim[1],
			rounded and 1 or AT.THEME.textDim[2],
			rounded and 1 or AT.THEME.textDim[3])
	end

	-- горячие клавиши
	for _, row in ipairs(hotkeyRows) do
		if row.label then row.label:SetText(AT.HotkeyText(row.action)) end
	end

	AT.RefreshThemeSwatches()
end

AT.RegisterPageHook("Интерфейс", function()
	AT.RefreshInterfaceSettings()
end)
