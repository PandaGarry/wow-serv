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

	AT.RefreshThemeSwatches()
end

AT.RegisterPageHook("Интерфейс", function()
	AT.RefreshInterfaceSettings()
end)
