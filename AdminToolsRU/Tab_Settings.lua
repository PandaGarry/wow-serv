--=========================================================================
-- Tab_Settings.lua - вкладка «Настройки»
--=========================================================================

local p = AT.RegisterTab("Настройки")

local function MakeCheck(x, y, text, onClick)
	local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	cb:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
	local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
	fs:SetJustifyH("LEFT")
	fs:SetWidth(AT.CONTENT_W / 2 - 40)
	fs:SetText(text)
	cb:SetScript("OnClick", onClick)
	return cb
end

---------------------------------------------------------------------------
-- Видимость вкладок (две колонки)
---------------------------------------------------------------------------
local y = AT.MakeSection(p, "Видимость вкладок", -2)
local checks = {}
local names = {}
for _, n in ipairs(AT.TABS) do
	if n ~= "Настройки" then tinsert(names, n) end
end
-- «Свои» регистрируется после этого файла — добавим её вручную
tinsert(names, "Свои")

local half = AT.ceil(#names / 2)
for i, tabName in ipairs(names) do
	local col = (i <= half) and 0 or 1
	local row = (i <= half) and (i - 1) or (i - half - 1)
	checks[tabName] = MakeCheck(6 + col * (AT.CONTENT_W / 2), y - row * 26, tabName, function(self)
		AT.SetTabVisible(tabName, self:GetChecked() and true or false)
		AT.ApplyTabVisibility()
	end)
end
y = y - half * 26 - 4

local resetBtn = AT.MakeButton(p, "Показать все вкладки", 180, function()
	for _, n in ipairs(names) do AT.SetTabVisible(n, true) end
	AT.ApplyTabVisibility()
	p:GetScript("OnShow")(p)
end, nil, "Включить все вкладки")
resetBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - AT.BTN_H - 12

---------------------------------------------------------------------------
-- Интерфейс
---------------------------------------------------------------------------
y = AT.MakeSection(p, "Интерфейс", y)

local echo = MakeCheck(6, y, "Дублировать выполненные команды в чат", function(self)
	AdminToolsDB.echo = self:GetChecked() and true or false
end)
y = y - 32

local scaleLabel = AT.MakeLabel(p, "Масштаб окна:", "GameFontNormalSmall")
scaleLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y - 4)

local slider = CreateFrame("Slider", "AdminToolsRUScaleSlider", p, "OptionsSliderTemplate")
slider:SetWidth(220)
slider:SetPoint("TOPLEFT", p, "TOPLEFT", 130, y - 2)
slider:SetMinMaxValues(0.6, 1.4)
slider:SetValueStep(0.05)
AdminToolsRUScaleSliderLow:SetText("60%")
AdminToolsRUScaleSliderHigh:SetText("140%")
local function UpdateSliderText(v)
	AdminToolsRUScaleSliderText:SetText(AT.floor(v * 100 + 0.5) .. "%")
end
slider:SetScript("OnValueChanged", function(self, v)
	v = AT.floor(v * 20 + 0.5) / 20
	UpdateSliderText(v)
	if self._init then return end
	AdminToolsDB.scale = v
end)
-- Масштаб применяем по отпусканию мыши, иначе окно «уезжает» из-под курсора
slider:SetScript("OnMouseUp", function() AT.ApplyScale() end)
y = y - 44

local resetPos = AT.MakeButton(p, "Сбросить позицию окна", 180, function()
	AdminToolsDB.pos = nil
	AdminToolsDB.scale = 1
	AT.frame:ClearAllPoints()
	AT.frame:SetPoint("CENTER")
	AT.ApplyScale()
	p:GetScript("OnShow")(p)
end, nil, "Вернуть окно в центр экрана и масштаб 100%")
resetPos:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y)
y = y - AT.BTN_H - 12

y = AT.MakeNote(p, "Настройки сохраняются автоматически. Если что-то пошло не так — "
	.. "команда /atreset сбрасывает все настройки аддона (с перезагрузкой интерфейса).", y)

-- Актуализация состояния при каждом открытии (SavedVariables грузятся позже файла)
p:SetScript("OnShow", function()
	for n, cb in pairs(checks) do cb:SetChecked(AT.IsTabVisible(n)) end
	echo:SetChecked(not AdminToolsDB or AdminToolsDB.echo ~= false)
	local s = (AdminToolsDB and AdminToolsDB.scale) or 1
	slider._init = true
	slider:SetValue(s)
	UpdateSliderText(s)
	slider._init = nil
end)

AT.FinishPage(p, y)
