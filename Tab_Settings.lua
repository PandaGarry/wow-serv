--=========================================================================
-- Tab_Settings.lua - вкладка «Настройки»
-- Управление видимостью других вкладок
--=========================================================================

local p = AT.RegisterTab("Настройки")

local head = AT.MakeLabel(p, "Видимость вкладок", "GameFontNormal")
head:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -4)

local desc = AT.MakeLabel(p, "Сними галочку, чтобы скрыть ненужную вкладку.\n"
	.. "Настройки сохраняются автоматически.", "GameFontNormalSmall")
desc:SetJustifyH("LEFT")
desc:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -26)

local checkboxes = {}
local ALL_TABS = {
	"Телепорт", "Путешествие", "Боты", "NPC", "Себя",
	"Персонаж", "Группа", "Сервер", "Настройки", "Свои"
}

local y = -70
for _, tabName in ipairs(ALL_TABS) do
	if tabName ~= "Настройки" then  -- саму себя скрывать нельзя
		local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
		cb:SetSize(24, 24)
		cb:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y)
		cb.Text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		cb.Text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
		cb.Text:SetText("Показывать вкладку «" .. tabName .. "»")
		cb:SetChecked(AT.IsTabVisible(tabName))
		cb:SetScript("OnClick", function(self)
			AT.SetTabVisible(tabName, self:GetChecked() and true or false)
			AT.ApplyTabVisibility()
		end)
		table.insert(checkboxes, cb)
		y = y - 28
	end
end

-- Кнопка сброса
local resetBtn = AT.MakeButton(p, "Показать все вкладки", 200, function()
	for _, cb in ipairs(checkboxes) do
		cb:SetChecked(true)
	end
	for _, tabName in ipairs(ALL_TABS) do
		AT.SetTabVisible(tabName, true)
	end
	AT.ApplyTabVisibility()
end, 1, "Включить все вкладки")
resetBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y - 20)

local note = AT.MakeLabel(p, "Если что-то пошло не так — используй /atreset\n"
	.. "для сброса всех настроек аддона.", "GameFontNormalSmall")
note:SetJustifyH("LEFT")
note:SetPoint("TOPLEFT", p, "TOPLEFT", 6, y - 60)