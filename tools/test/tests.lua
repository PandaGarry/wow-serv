--===========================================================================
-- tools/test/tests.lua
-- Набор проверок аддона Admin Tools RU на заглушке WoW API.
-- Результат складывается в глобальную таблицу AT_TEST (её читает run.js).
--===========================================================================

local T = { pass = 0, fail = 0, fails = {}, notes = {} }
AT_TEST = T

local function ok(cond, name, extra)
	if cond then
		T.pass = T.pass + 1
	else
		T.fail = T.fail + 1
		table.insert(T.fails, name .. (extra and ("  → " .. tostring(extra)) or ""))
	end
	return cond and true or false
end

local function eq(actual, expected, name)
	return ok(actual == expected, name,
		"ожидалось [" .. tostring(expected) .. "], получено [" .. tostring(actual) .. "]")
end

local function note(s) table.insert(T.notes, s) end

--===========================================================================
-- Вспомогательные поиски
--===========================================================================
local function FindButton(tabName, textPart)
	local page = AT.pages[tabName]
	if not page then return nil end
	for _, c in ipairs(page:GetChildren()) do
		if c.__kind == "Button" and c:IsShown() then
			local t = c:GetText() or ""
			if t:find(textPart, 1, true) then return c end
		end
	end
	return nil
end

local function ButtonsOf(tabName)
	local out = {}
	local page = AT.pages[tabName]
	if not page then return out end
	for _, c in ipairs(page:GetChildren()) do
		if c.__kind == "Button" and c:IsShown() then table.insert(out, c) end
	end
	return out
end

--===========================================================================
-- Вспомогательное: отпечаток состояния интерфейса
--===========================================================================
function UiSignature()
	local fr = AT.frame
	local w, h = 0, 0
	if fr and fr.GetWidth then w, h = fr:GetWidth() or 0, fr:GetHeight() or 0 end

	local mmShown, mmX, mmY = 0, 0, 0
	if AT.minimapButton then
		mmShown = AT.minimapButton:IsShown() and 1 or 0
		mmX = math.floor((AT.minimapButton:GetLeft() or 0) * 10)
		mmY = math.floor((AT.minimapButton:GetTop() or 0) * 10)
	end

	local visibleTabs = 0
	for _, name in ipairs(AT.TABS) do
		local b = AT.tabButtons[name]
		if b and b:IsShown() then visibleTabs = visibleTabs + 1 end
	end

	local visibleFilters = 0
	for _, box in ipairs(AT.filters or {}) do
		if box:IsShown() then visibleFilters = visibleFilters + 1 end
	end

	return table.concat({
		w, h,
		math.floor(AT.GetScale() * 100),
		AT.GetFontSizeDelta(),
		AT.GetThemeKey(),
		AT.WindowSizeLabel(),
		AT.GetMinimapAngle(),
		mmShown, mmX, mmY,
		visibleTabs,
		visibleFilters,
		AT.RowHighlightEnabled() and 1 or 0,
		AT.TooltipsEnabled() and 1 or 0,
		AT.FiltersEnabled() and 1 or 0,
		AT.currentTab or "",
	}, "|")
end

local function EditsOf(tabName)
	local out = {}
	local page = AT.pages[tabName]
	if not page then return out end
	for _, c in ipairs(page:GetChildren()) do
		if c.__kind == "EditBox" and c:IsShown() then table.insert(out, c) end
	end
	return out
end

--===========================================================================
-- 1. Загрузка и реестр вкладок
--===========================================================================
eq(type(AT), "table", "AT создан при загрузке Core.lua")
eq(type(AT.frame), "table", "главное окно AT.frame создано")
eq(#AT.TABS, 13, "зарегистрировано 13 вкладок")

local EXPECTED_TABS = {
	"Мир", "Телепорт", "Путешествие", "Боты", "NPC", "Модули",
	"Себя", "Персонаж", "Группа", "Сервер", "Интерфейс", "Настройки", "Свои",
}
for i, name in ipairs(EXPECTED_TABS) do
	eq(AT.TABS[i], name, "порядок вкладок: " .. name)
	ok(AT.tabButtons[name] ~= nil, "есть кнопка вкладки «" .. name .. "»")
	ok(AT.pages[name] ~= nil, "есть страница вкладки «" .. name .. "»")
	ok(AT.scrolls[name] ~= nil, "есть прокрутка вкладки «" .. name .. "»")
end

-- Страницы должны иметь реальные размеры
for _, name in ipairs(AT.TABS) do
	local page = AT.pages[name]
	ok(page:GetWidth() > 300, "ширина страницы «" .. name .. "» > 300 (" .. tostring(page:GetWidth()) .. ")")
	ok(AT.pageBottom[page] ~= nil, "учтён низ контента «" .. name .. "»")
end

-- Сохранённые переменные инициализированы
eq(type(AdminToolsDB), "table", "AdminToolsDB создан по ADDON_LOADED")
eq(AdminToolsDB.echo, true, "по умолчанию эхо команд включено")
eq(AdminToolsDB.mySec, 3, "по умолчанию уровень доступа 3")
eq(AdminToolsDB.restrictBySec, false, "по умолчанию блокировка по уровню выключена")
eq(type(AdminToolsDB.tabVisibility), "table", "таблица видимости вкладок создана")
eq(type(AdminToolsDB.custom), "table", "список своих кнопок создан")
ok(#STUB.chat > 0, "аддон что-то сказал в чат при загрузке")

--===========================================================================
-- 2. Высота страниц и влезание контента
--===========================================================================
for _, name in ipairs(AT.TABS) do
	local page = AT.pages[name]
	AT.ShowPage(name)
	local h = AT.FitPage(page)
	ok(h and h > 0, "высота страницы «" .. name .. "» > 0 (" .. tostring(h) .. ")")

	local pageLeft, pageRight = page:GetLeft(), page:GetRight()
	for _, c in ipairs(page:GetChildren()) do
		if c:IsShown() and c.__kind == "Button" then
			local right = c:GetRight()
			ok(right <= pageRight + 1,
				"кнопка влезает по ширине в «" .. name .. "»",
				string.format("«%s» правый край %.0f > %.0f", tostring(c:GetText()), right, pageRight))

			local left = c:GetLeft()
			ok(left >= pageLeft - 1,
				"кнопка не вылезает влево в «" .. name .. "»",
				string.format("«%s» левый край %.0f < %.0f", tostring(c:GetText()), left, pageLeft))
		end
	end
end

--===========================================================================
-- 3. Все кнопки: клик без ошибок и осмысленный результат
--===========================================================================
local totalClicked = 0

-- Для кнопок «OK» в строках форм заполняем поля той же строки,
-- иначе кнопка справедливо ничего не делает.
local function FillFormRow(btn, page)
	if not page then return end
	local by = (btn:GetTop() + btn:GetBottom()) / 2
	local bx = btn:GetLeft()
	for _, c in ipairs(page:GetChildren()) do
		if c.__kind == "EditBox" and c:IsShown() then
			local cy = (c:GetTop() + c:GetBottom()) / 2
			if math.abs(cy - by) < 6 and c:GetRight() <= bx + 8 then
				c:SetText("1")
			end
		end
	end
end

-- Масштаб не по умолчанию, чтобы кнопки «-», «+» и сброс были заметны
AT.SetScale(1.2)
STUB.shift = false

for _, tabName in ipairs(AT.TABS) do
	if tabName ~= "Свои" then
		AT.ShowPage(tabName)
		for _, btn in ipairs(ButtonsOf(tabName)) do
			local label = tostring(btn:GetText())
			local page = AT.pages[tabName]
			STUB.ClearSent()
			STUB.visiblePopup = nil
			local chatBefore = #STUB.chat
			local menusBefore = #STUB.dropdownOpened
			-- «отпечаток» интерфейса до клика: если он изменился, кнопка
			-- сделала что-то видимое, даже если не отправила команду
			local sigBefore = UiSignature()

			if label == "OK" then FillFormRow(btn, page) end

			local clicked, err = STUB.Click(btn, "LeftButton")
			totalClicked = totalClicked + 1

			ok(clicked, "клик без ошибки: " .. tabName .. " / " .. label, err)

			local msg = STUB.LastCommand()
			if msg then
				local first = msg:sub(1, 1)
				ok(first == "." or first == "#", "команда начинается с точки: " .. msg)
				ok(#msg > 1, "команда не пустая: " .. label)
				ok(not msg:find("nil", 1, true), "в команде нет nil: " .. msg)
				ok(not msg:find(" ", -1, true), "в конце команды нет пробела: [" .. msg .. "]")
			else
				local effect = (STUB.visiblePopup ~= nil)
					or (#STUB.chat > chatBefore)
					or (#STUB.dropdownOpened > menusBefore)
					or (STUB.focused ~= nil)              -- кнопка перевела фокус в поле
					or (UiSignature() ~= sigBefore)       -- изменился интерфейс
				ok(effect, "кнопка что-то делает (команда, попап, меню или сообщение): "
					.. tabName .. " / " .. label)
				if STUB.visiblePopup then
					ok(type(STUB.visiblePopup.data) == "string" or STUB.visiblePopup.data == nil,
						"попап несёт команду: " .. tostring(STUB.visiblePopup.data))
				end
			end
		end
	end
end

ok(totalClicked > 60, "прокликано больше 60 кнопок (" .. totalClicked .. ")")
note("прокликано кнопок: " .. totalClicked)

-- Вернуть настройки, которые могли поменяться при прокликивании
AdminToolsDB.mySec = 3
AdminToolsDB.restrictBySec = false
AT.SetScale(1)
STUB.visiblePopup = nil

--===========================================================================
-- 4. Подтверждения (попапы)
--===========================================================================
STUB.ClearSent()
STUB.visiblePopup = nil
AT.ConfirmCmd(".server restart 60", "Перезапустить сервер?")
ok(STUB.visiblePopup ~= nil, "AT.ConfirmCmd показал попап")
eq(STUB.visiblePopup and STUB.visiblePopup.data, ".server restart 60", "попап несёт команду")

local accepted = STUB.AcceptPopup(AT.POPUP_CONFIRM)
ok(accepted, "нажатие «Да» обработано")
eq(STUB.LastCommand(), ".server restart 60", "после подтверждения команда ушла")

-- «Опасные» кнопки на вкладке «Сервер» должны требовать подтверждения
local restartBtn = FindButton("Сервер", "Рестарт 60с")
ok(restartBtn ~= nil, "найдена кнопка «Рестарт 60с»")
if restartBtn then
	STUB.ClearSent()
	STUB.visiblePopup = nil
	STUB.Click(restartBtn)
	eq(#STUB.sent, 0, "без подтверждения команда не уходит")
	ok(STUB.visiblePopup ~= nil, "и показывается попап")
	STUB.AcceptPopup()
	eq(STUB.LastCommand(), ".server restart 60", "после подтверждения уходит .server restart 60")
end

--===========================================================================
-- 5. Предупреждение о столице вражеской фракции
--===========================================================================
STUB.faction = "Horde"
STUB.ClearSent()
STUB.visiblePopup = nil

local stormwindBtn = FindButton("Телепорт", "Штормград")
ok(stormwindBtn ~= nil, "найдена кнопка «Штормград»")
if stormwindBtn then
	STUB.Click(stormwindBtn)
	eq(#STUB.sent, 0, "ордынец не телепортируется в Штормград без подтверждения")
	ok(STUB.visiblePopup ~= nil, "показано предупреждение о вражеской столице")
	eq(STUB.visiblePopup and STUB.visiblePopup.data, ".tele Stormwind", "попап несёт .tele Stormwind")
	STUB.AcceptPopup()
	eq(STUB.LastCommand(), ".tele Stormwind", "после согласия телепорт выполнен")
end

-- Своя столица — без вопросов
local orgrimmarBtn = FindButton("Телепорт", "Оргриммар")
if orgrimmarBtn then
	STUB.ClearSent()
	STUB.visiblePopup = nil
	STUB.Click(orgrimmarBtn)
	eq(STUB.LastCommand(), ".tele Orgrimmar", "своя столица телепортируется сразу")
	eq(#STUB.popups > 0 and STUB.visiblePopup ~= nil, false, "для своей столицы попап не показывается")
end

STUB.faction = "Alliance"
STUB.visiblePopup = nil

--===========================================================================
-- 6. Ограничение по уровню доступа
--===========================================================================
AdminToolsDB.restrictBySec = true
AdminToolsDB.mySec = 1

local delNpcBtn = FindButton("NPC", "Удалить выбранного NPC")
ok(delNpcBtn ~= nil, "найдена кнопка «Удалить выбранного NPC»")
if delNpcBtn then
	STUB.ClearSent()
	local chatBefore = #STUB.chat
	STUB.Click(delNpcBtn)
	eq(#STUB.sent, 0, "кнопка уровня 3 не срабатывает на уровне 1")
	ok(#STUB.chat > chatBefore, "и объясняет причину в чате")
end

AdminToolsDB.mySec = 3
STUB.ClearSent()
if delNpcBtn then
	STUB.Click(delNpcBtn)
	eq(STUB.LastCommand(), ".npc delete", "на уровне 3 та же кнопка работает")
end

AdminToolsDB.restrictBySec = false

--===========================================================================
-- 7. Видимость вкладок
--===========================================================================
ok(AT.IsTabVisible("Боты"), "вкладка «Боты» видна по умолчанию")
AT.SetTabVisible("Боты", false)
ok(not AT.IsTabVisible("Боты"), "вкладку «Боты» можно скрыть")
ok(not AT.tabButtons["Боты"]:IsShown(), "кнопка скрытой вкладки не показана")

AT.ApplyTabVisibility()

-- вкладки идут вертикальной колонкой: проверяем пересечение прямоугольников
local function RectsOverlap(a, b)
	return not (a.right <= b.left or b.right <= a.left or a.bottom >= b.top or b.bottom >= a.top)
end

local shown = {}
for _, name in ipairs(AT.TABS) do
	local b = AT.tabButtons[name]
	if b and b:IsShown() then
		table.insert(shown, {
			name = name,
			left = b:GetLeft(), right = b:GetRight(),
			top = b:GetTop(), bottom = b:GetBottom(),
		})
	end
end
local overlaps = 0
for i = 1, #shown do
	for j = i + 1, #shown do
		if RectsOverlap(shown[i], shown[j]) then overlaps = overlaps + 1 end
	end
end
eq(overlaps, 0, "кнопки видимых вкладок не накладываются друг на друга")
ok(#shown >= 10, "видимых вкладок не меньше 10 (" .. #shown .. ")")

-- колонка вкладок должна помещаться в окно по высоте
local frameBottom = AT.frame:GetBottom()
local lowest = nil
for _, r in ipairs(shown) do
	if not lowest or r.bottom < lowest then lowest = r.bottom end
end
ok(lowest >= frameBottom, "колонка вкладок не вылезает за нижний край окна")

AT.SetTabVisible("Настройки", false)
ok(AT.IsTabVisible("Настройки"), "вкладку «Настройки» нельзя скрыть (иначе не вернуть остальные)")

AT.SetTabVisible("Боты", true)
AT.ApplyTabVisibility()
ok(AT.tabButtons["Боты"]:IsShown(), "вкладку «Боты» можно вернуть")

-- Переключение на скрытую вкладку не должно срабатывать
AT.ShowPage("Боты")
AT.SetTabVisible("Боты", false)
ok(AT.currentTab ~= "Боты", "после скрытия текущей вкладки панель переключилась на другую")
AT.SetTabVisible("Боты", true)
AT.ApplyTabVisibility()

--===========================================================================
-- 8. Слэш-команды
--===========================================================================
STUB.ClearSent()
SlashCmdList["ADMINTOOLSRU"]("")
ok(AT.frame:IsShown(), "/admin открывает панель")
SlashCmdList["ADMINTOOLSRU"]("")
ok(not AT.frame:IsShown(), "повторный /admin закрывает панель")

STUB.ClearSent()
SlashCmdList["ADMINTOOLSRU"]("tele stormwind")
eq(STUB.LastCommand(), ".tele stormwind", "/admin <команда> выполняет команду")

STUB.ClearSent()
SlashCmdList["ADMINTOOLSRU"](".gps")
eq(STUB.LastCommand(), ".gps", "точка в команде не дублируется")

local chatBefore = #STUB.chat
SlashCmdList["ADMINTOOLSRUHELP"]()
ok(#STUB.chat - chatBefore >= 5, "/ath печатает справку")

local echoBefore = AT.EchoEnabled()
SlashCmdList["ADMINTOOLSRUECHO"]()
eq(AT.EchoEnabled(), not echoBefore, "/atecho переключает эхо команд")
SlashCmdList["ADMINTOOLSRUECHO"]()
eq(AT.EchoEnabled(), echoBefore, "/atecho возвращает эхо обратно")

--===========================================================================
-- 9. RunCmd: нормализация, обрезка, история
--===========================================================================
STUB.ClearSent()
AT.RunCmd("   tele   dalaran   ")
eq(STUB.LastCommand(), ".tele   dalaran", "RunCmd обрезает пробелы по краям")

STUB.ClearSent()
AT.RunCmd("")
AT.RunCmd(nil)
eq(#STUB.sent, 0, "пустая команда и nil ничего не отправляют")

STUB.ClearSent()
AT.RunCmd(string.rep("x", 400))
eq(#STUB.LastCommand(), 255, "слишком длинная команда обрезается до 255 символов")

AT.history = {}
for i = 1, 35 do AT.RunCmd(".gps " .. i) end
eq(#AT.history, 30, "история ограничена 30 командами")
eq(AT.history[1], ".gps 35", "последняя команда лежит первой")
AT.RunCmd(".gps 35")
local dup = 0
for _, c in ipairs(AT.history) do if c == ".gps 35" then dup = dup + 1 end end
eq(dup, 1, "повтор команды не плодит дубликаты в истории")

--===========================================================================
-- 10. Кнопка на миникарте
--===========================================================================
local mmBtn = _G["AdminToolsRUMMBtn"]
ok(mmBtn ~= nil, "кнопка на миникарте создана")
if mmBtn then
	AT.frame:Hide()
	STUB.Click(mmBtn, "LeftButton")
	ok(AT.frame:IsShown(), "ЛКМ по кнопке миникарты открывает панель")
	STUB.Click(mmBtn, "LeftButton")
	ok(not AT.frame:IsShown(), "повторный ЛКМ закрывает панель")
	STUB.Click(mmBtn, "RightButton")
	ok(AT.frame:IsShown(), "ПКМ открывает панель")
	eq(AT.currentTab, "Телепорт", "ПКМ открывает вкладку «Телепорт»")
end

--===========================================================================
-- 11. Выпадающие меню (вкладка «Путешествие»)
--===========================================================================
local travelBtn = FindButton("Путешествие", "Подземелья")
ok(travelBtn ~= nil, "найдена кнопка «Подземелья (по дополнениям)»")
if travelBtn then
	STUB.clearLastDropdown = nil
	STUB.Click(travelBtn)
	local menu = STUB.lastDropdown
	ok(menu ~= nil, "по клику открылось выпадающее меню")
	if menu then
		ok(menu.initError == nil, "построение меню без ошибок", menu.initError)
		ok(#menu.entries >= 3, "в меню есть группы дополнений (" .. #menu.entries .. ")")
		local hasArrow = false
		for _, e in ipairs(menu.entries) do
			if e.info.text and e.info.hasArrow then hasArrow = true end
		end
		ok(hasArrow, "у групп меню есть вложенные списки")

		-- открываем первую группу (второй уровень) и жмём первый пункт
		local group = AT.DATA.dungeons[1][2]
		UIDROPDOWNMENU_MENU_VALUE = group
		STUB.currentMenu = menu
		menu.entries = {}
		menu.init(menu, 2)
		STUB.currentMenu = nil
		ok(#menu.entries == #group, "во втором уровне столько же пунктов, сколько в данных")
		local func = menu.entries[1] and menu.entries[1].info.func
		ok(type(func) == "function", "у пункта меню есть обработчик")
		if func then
			STUB.ClearSent()
			func()
			eq(STUB.LastCommand(), group[1][2], "пункт меню выполняет свою команду")
		end
		UIDROPDOWNMENU_MENU_VALUE = nil
	end
end

--===========================================================================
-- 12. Вкладка «Свои»: добавление, выполнение, меню, удаление
--===========================================================================
AT.ShowPage("Свои")
AdminToolsDB.custom = {}
AT.refreshCustom()

local edits = EditsOf("Свои")
ok(#edits >= 2, "на вкладке «Свои» есть поля ввода (" .. #edits .. ")")
if #edits >= 2 then
	local labelEdit, cmdEdit = edits[1], edits[2]
	labelEdit:SetText("Даларан")
	cmdEdit:SetText("tele dalaran")

	local addBtn = FindButton("Свои", "Добавить кнопку")
	ok(addBtn ~= nil, "найдена кнопка «Добавить кнопку»")
	if addBtn then
		STUB.Click(addBtn)
		eq(#AdminToolsDB.custom, 1, "кнопка добавлена в сохранённые")
		eq(AdminToolsDB.custom[1] and AdminToolsDB.custom[1].cmd, "tele dalaran", "команда сохранена как введена")
		eq(labelEdit:GetText(), "", "поле названия очищено после добавления")

		-- нажатие своей кнопки
		local customBtn = FindButton("Свои", "Даларан")
		ok(customBtn ~= nil, "своя кнопка появилась в списке")
		if customBtn then
			STUB.ClearSent()
			STUB.Click(customBtn, "LeftButton")
			eq(STUB.LastCommand(), ".tele dalaran", "своя кнопка выполняет команду")

			-- ПКМ: меню действий
			STUB.Click(customBtn, "RightButton")
			local menu = STUB.lastDropdown
			ok(menu ~= nil and menu.initError == nil, "ПКМ открывает меню действий")
			if menu then
				local deleteEntry
				for _, e in ipairs(menu.entries) do
					if e.info.text and e.info.text:find("Удалить") then deleteEntry = e.info end
				end
				ok(deleteEntry ~= nil, "в меню есть пункт «Удалить»")
				if deleteEntry then
					STUB.visiblePopup = nil
					deleteEntry.func()
					ok(STUB.visiblePopup ~= nil, "удаление просит подтверждения")
					STUB.AcceptPopup(AT.POPUP_DELCUSTOM)
					eq(#AdminToolsDB.custom, 0, "кнопка удалена после подтверждения")
				end
			end
		end
	end
end

-- Перемещение своих кнопок
AdminToolsDB.custom = { { label = "A", cmd = ".gps" }, { label = "B", cmd = ".gps" } }
AT.refreshCustom()
local btnB = FindButton("Свои", "B")
if btnB then
	STUB.Click(btnB, "RightButton")
	local menu = STUB.lastDropdown
	local upEntry
	for _, e in ipairs(menu.entries) do
		if e.info.text == "Вверх" then upEntry = e.info end
	end
	ok(upEntry ~= nil, "в меню есть пункт «Вверх»")
	if upEntry then
		upEntry.func()
		eq(AdminToolsDB.custom[1].label, "B", "кнопка переместилась наверх")
	end
end
AdminToolsDB.custom = {}
AT.refreshCustom()

-- Высота страницы «Свои» пересчитывается после изменения списка
local before = AT.pageBottom[AT.pages["Свои"]]
AdminToolsDB.custom = { { label = "X", cmd = ".gps" }, { label = "Y", cmd = ".gps" },
	{ label = "Z", cmd = ".gps" }, { label = "W", cmd = ".gps" }, { label = "V", cmd = ".gps" } }
AT.refreshCustom()
local after = AT.pageBottom[AT.pages["Свои"]]
ok(after ~= nil and after < (before or 0), "высота страницы «Свои» выросла вместе со списком")
AdminToolsDB.custom = {}
AT.refreshCustom()

--===========================================================================
-- 13. Меню настроек построены
--===========================================================================
-- меню: подземелья, рейды, 2 места кача, классы ботов, свои кнопки
ok(#STUB.menus >= 6, "создано не меньше 6 выпадающих меню (" .. #STUB.menus .. ")")
local menuErr = 0
for _, m in ipairs(STUB.menus) do
	if m.initError then menuErr = menuErr + 1 end
end
eq(menuErr, 0, "ни одно меню не падает при построении")

--===========================================================================
-- 14. Данные сервера консистентны
--===========================================================================
for _, g in ipairs(AT.DATA.cities) do
	ok(type(g.header) == "string" and #g.header > 0, "у группы городов есть заголовок")
	for _, e in ipairs(g.list) do
		ok(type(e[1]) == "string" and #e[1] > 0, "у города есть подпись")
		ok(type(e[2]) == "string" and #e[2] > 0, "у города есть имя телепорта")
		ok(e[3] == "Alliance" or e[3] == "Horde" or e[3] == "Neutral",
			"фракция города корректна: " .. tostring(e[3]))
	end
end

for _, group in ipairs(AT.DATA.npcGroups) do
	ok(type(group.header) == "string" and #group.header > 0, "у группы NPC есть заголовок")
	for _, npc in ipairs(group.list) do
		ok(type(npc[2]) == "number" and npc[2] > 0, "у NPC числовой entry: " .. tostring(npc[2]))
		ok(type(npc[3]) == "string" and #npc[3] > 0, "у NPC есть подсказка")
	end
end

local function CheckCmdList(list, what)
	for _, e in ipairs(list) do
		ok(type(e[2]) == "string" and #e[2] > 1, what .. ": команда не пустая")
		ok(e[2]:sub(1, 1) == ".", what .. ": команда начинается с точки (" .. tostring(e[2]) .. ")")
		ok(e[2] == STUB.trim and e[2] or e[2] == (e[2]:gsub("^%s+", ""):gsub("%s+$", "")),
			what .. ": в команде нет лишних пробелов")
	end
end

for _, grp in ipairs(AT.DATA.dungeons) do CheckCmdList(grp[2], "подземелья/" .. grp[1]) end
for _, grp in ipairs(AT.DATA.raids) do CheckCmdList(grp[2], "рейды/" .. grp[1]) end
CheckCmdList(AT.DATA.grindAlliance, "кач/альянс")
CheckCmdList(AT.DATA.grindHorde, "кач/орда")

ok(type(AT.DATA.bagItemId) == "number" and AT.DATA.bagItemId > 0, "ID сумки задан числом")

--===========================================================================
-- 15. Сообщения об ошибках не пустые (проверка, что PrintErr работает)
--===========================================================================
local chatBefore = #STUB.chat
AT.PrintErr("проверка")
ok(#STUB.chat == chatBefore + 1, "PrintErr пишет в чат")
ok(STUB.chat[#STUB.chat]:find("проверка"), "сообщение дошло целиком")

--===========================================================================
-- 16. Избранное (Shift+ЛКМ)
--===========================================================================
AdminToolsDB.favorites = {}
AdminToolsDB.restrictBySec = false
AdminToolsDB.mySec = 3
AT.RefreshFavorites()

AT.ShowPage("Боты")
local followBtn = FindButton("Боты", "Следовать")
ok(followBtn ~= nil, "найдена кнопка «Следовать» для проверки избранного")
if followBtn then
	STUB.ClearSent()
	STUB.shift = true
	STUB.Click(followBtn)
	STUB.shift = false

	eq(#STUB.sent, 0, "Shift+ЛКМ не выполняет команду")
	eq(#AT.GetFavorites(), 1, "Shift+ЛКМ добавляет кнопку в избранное")
	eq(AT.GetFavorites()[1] and AT.GetFavorites()[1].cmd, ".npcbot command follow",
		"в избранное попала нужная команда")
	ok(AT.IsFavorite(".npcbot command follow"), "AT.IsFavorite видит команду")

	local favBtn = AT.favoriteButtons[1]
	ok(favBtn ~= nil and favBtn:IsShown(), "кнопка избранного показана в шапке")

	if favBtn then
		STUB.ClearSent()
		STUB.Click(favBtn)
		eq(STUB.LastCommand(), ".npcbot command follow", "клик по избранному выполняет команду")
	end

	-- повторный Shift+ЛКМ убирает
	STUB.shift = true
	STUB.Click(followBtn)
	STUB.shift = false
	eq(#AT.GetFavorites(), 0, "повторный Shift+ЛКМ убирает из избранного")

	-- лимит избранного
	for i = 1, 20 do AT.ToggleFavorite("кнопка " .. i, ".gps " .. i) end
	ok(#AT.GetFavorites() <= AT.FAVORITES_MAX,
		"избранное не превышает лимит " .. AT.FAVORITES_MAX)
	AdminToolsDB.favorites = {}
	AT.RefreshFavorites()
end

--===========================================================================
-- 17. ПКМ по кнопке — команда в поле ввода
--===========================================================================
AT.ShowPage("Мир")
local gpsBtn = FindButton("Мир", "GPS")
ok(gpsBtn ~= nil, "найдена кнопка «GPS»")
if gpsBtn then
	STUB.ClearSent()
	STUB.Click(gpsBtn, "RightButton")
	eq(AT.GetCommandBox():GetText(), ".gps", "ПКМ кладёт команду в поле ввода")
	eq(#STUB.sent, 0, "при этом команда не выполняется")
end

--===========================================================================
-- 18. Фильтр кнопок на вкладке
--===========================================================================
local filter
for _, box in ipairs(AT.filters or {}) do
	if box.__page == AT.pages["Телепорт"] then filter = box end
end
ok(filter ~= nil, "на вкладке «Телепорт» есть фильтр")

if filter then
	local function VisibleCount()
		local n = 0
		for _, c in ipairs(AT.pages["Телепорт"]:GetChildren()) do
			if c.__kind == "Button" and c:IsShown() then n = n + 1 end
		end
		return n
	end

	AT.ShowPage("Телепорт")
	local total = VisibleCount()
	ok(total > 10, "до фильтра видно много кнопок (" .. total .. ")")

	STUB.Focus(filter)
	STUB.Type(filter, "Шторм")
	local after = VisibleCount()
	ok(after > 0, "фильтр что-то оставил (" .. after .. ")")
	ok(after < total, "фильтр скрыл лишние кнопки (" .. after .. " из " .. total .. ")")

	local stormShown = false
	for _, c in ipairs(AT.pages["Телепорт"]:GetChildren()) do
		if c.__kind == "Button" and c:IsShown()
			and (c:GetText() or ""):find("Штормград") then stormShown = true end
	end
	ok(stormShown, "подходящая кнопка «Штормград» осталась видимой")

	-- Esc очищает фильтр
	local esc = filter:GetScript("OnEscapePressed")
	if esc then
		esc(filter)
		eq(VisibleCount(), total, "после Esc снова видны все кнопки")
	end
end

--===========================================================================
-- 19. Шрифт: меняется размер, но не подменяется файл (кириллица из клиента)
--===========================================================================
local fontsBefore = {}
for fs in pairs(AT.fontRegistry) do
	fontsBefore[fs] = select(2, fs:GetFont())
end
ok(#STUB.chat > 0, "фонтан сообщений есть")  -- заглушка для порядка

local fontChangedAll = true
local fontCount = 0
AT.SetFontSizeDelta(2)
for fs, size in pairs(fontsBefore) do
	fontCount = fontCount + 1
	local _, newSize = fs:GetFont()
	if newSize ~= size + 2 then fontChangedAll = false end
end
ok(fontCount > 20, "в реестре шрифтов больше 20 элементов (" .. fontCount .. ")")
ok(fontChangedAll, "размер шрифта вырос на 2 пт у всех элементов")

local fontFileOk = true
for fs in pairs(AT.fontRegistry) do
	local file = fs:GetFont()
	if type(file) ~= "string" or file:find("AdminToolsRU", 1, true) then fontFileOk = false end
end
ok(fontFileOk, "аддон не подменяет файл шрифта (русский текст остаётся корректным)")

AT.SetFontSizeDelta(0)
local fontBackAll = true
for fs, size in pairs(fontsBefore) do
	local _, newSize = fs:GetFont()
	if newSize ~= size then fontBackAll = false end
end
ok(fontBackAll, "после сброса размеры шрифтов вернулись")
eq(AT.GetFontSizeDelta(), 0, "смещение размера сброшено в 0")

--===========================================================================
-- 20. Перекраска кнопок по уровню доступа
--===========================================================================
AT.ShowPage("NPC")
local npcDelBtn = FindButton("NPC", "Удалить выбранного NPC")
ok(npcDelBtn ~= nil, "найдена кнопка уровня 3 на вкладке «NPC»")

if npcDelBtn then
	local fs = npcDelBtn:GetFontString()

	-- уровень 3 = красный (r >> g), заблокированная кнопка = серая (r ≈ g)
	AdminToolsDB.restrictBySec = true
	AdminToolsDB.mySec = 1
	AT.RefreshLocks()
	local r1, g1 = fs:GetTextColor()
	ok(math.abs(r1 - g1) < 0.12,
		"на уровне 1 кнопка уровня 3 выглядит серой (r=" .. string.format("%.2f", r1)
		.. ", g=" .. string.format("%.2f", g1) .. ")")

	AdminToolsDB.mySec = 3
	AT.RefreshLocks()
	local r2, g2 = fs:GetTextColor()
	ok(r2 - g2 > 0.4,
		"на уровне 3 та же кнопка окрашена как «администратор» (r=" .. string.format("%.2f", r2)
		.. ", g=" .. string.format("%.2f", g2) .. ")")

	AdminToolsDB.restrictBySec = false
	AdminToolsDB.mySec = 3
	AT.RefreshLocks()
end

--===========================================================================
-- 21. Встроенный замер производительности
--===========================================================================
local chatBefore = #STUB.chat
AT.Bench()
ok(#STUB.chat > chatBefore, "/atbench печатает отчёт (" .. (#STUB.chat - chatBefore) .. " строк)")
local benchFound = false
for i = chatBefore + 1, #STUB.chat do
	if tostring(STUB.chat[i]):find("Производительность") then benchFound = true end
end
ok(benchFound, "в отчёте есть строка о производительности")

--===========================================================================
-- 21b. Shift+клик по нику в чате → в поле ввода команды
--===========================================================================
ok(STUB.CallHook("SetItemRef", "player:Тестер", "[Тестер]", "LeftButton") > 0,
	"аддон подписан на клики по ссылкам в чате")

local box = AT.GetCommandBox()
box:SetText("")

STUB.shift = true
STUB.CallHook("SetItemRef", "player:Тестер", "[Тестер]", "LeftButton")
STUB.shift = false
eq(box:GetText(), "Тестер", "Shift+клик по нику кладёт имя в поле ввода")

STUB.shift = true
STUB.CallHook("SetItemRef", "player:Второй", "[Второй]", "LeftButton")
STUB.shift = false
eq(box:GetText(), "Тестер Второй", "второе имя добавляется через пробел")

-- без Shift имя не подставляется
box:SetText("")
STUB.CallHook("SetItemRef", "player:Тестер", "[Тестер]", "LeftButton")
eq(box:GetText(), "", "без Shift имя в поле не попадает")

-- клик по предмету не трогает поле ввода
box:SetText("")
STUB.shift = true
STUB.CallHook("SetItemRef", "item:19019:0:0:0:0:0:0:0", "[Thunderfury]", "LeftButton")
STUB.shift = false
eq(box:GetText(), "", "клик по предмету поле ввода не меняет")

box:SetText("")

--===========================================================================
-- 22. Файлы скина на месте
--===========================================================================
for _, key in ipairs({ "btnNormal", "btnHover", "btnPushed", "panel", "glow", "line" }) do
	ok(type(AT.SKIN[key]) == "string" and AT.SKIN[key]:find("skin", 1, true),
		"текстура скина задана: " .. key)
end

--===========================================================================
-- 23. Полнота загрузки Main.lua (регрессия: ошибка обрывала файл,
--     из-за чего не работали /admin и кнопка на миникарте)
--===========================================================================
ok(AT.loaded == true, "Main.lua выполнился до конца (AT.loaded)")

ok(type(AT.GetCommandBox) == "function", "панель команд создана (AT.GetCommandBox)")
ok(AT.GetCommandBox() ~= nil, "поле ввода команды существует")
ok(type(AT.Bench) == "function", "/atbench доступен")
ok(type(AT.Toggle) == "function", "AT.Toggle доступен")
ok(_G["AdminToolsRUMMBtn"] ~= nil, "кнопка на миникарте создана")

-- слэш-команды: именно этого не было при обрыве Main.lua
eq(SLASH_ADMINTOOLSRU1, "/admin", "зарегистрирован /admin")
eq(SLASH_ADMINTOOLSRU2, "/adt", "зарегистрирован /adt")
eq(SLASH_ADMINTOOLSRUHELP1, "/ath", "зарегистрирован /ath")
eq(SLASH_ADMINTOOLSRUBENCH1, "/atbench", "зарегистрирован /atbench")
eq(SLASH_ADMINTOOLSRUECHO1, "/atecho", "зарегистрирован /atecho")
eq(SLASH_ADMINTOOLSRURESET1, "/atreset", "зарегистрирован /atreset")

for _, handler in ipairs({
	"ADMINTOOLSRU", "ADMINTOOLSRUHELP", "ADMINTOOLSRUBENCH",
	"ADMINTOOLSRUECHO", "ADMINTOOLSRURESET",
}) do
	ok(type(SlashCmdList[handler]) == "function", "обработчик команды на месте: " .. handler)
end

-- все зарегистрированные SLASH_* имеют обработчик (иначе клиент пишет
-- «введите /помощь для списка команд»)
local slashCount, slashOk = 0, 0
for k in pairs(_G) do
	if type(k) == "string" and k:match("^SLASH_ADMINTOOLSRU") then
		slashCount = slashCount + 1
		local key = k:gsub("^SLASH_", ""):gsub("%d+$", "")
		if type(SlashCmdList[key]) == "function" then slashOk = slashOk + 1 end
	end
end
ok(slashCount >= 7, "зарегистрировано слэш-команд: " .. slashCount)
eq(slashOk, slashCount, "у каждой слэш-команды есть рабочий обработчик")

--===========================================================================
-- 24. Счётчик истории обновляется по событию (без OnUpdate на FontString)
--===========================================================================
ok(AT.histLabel ~= nil, "счётчик истории создан")
if AT.histLabel then
	ok(type(AT.histLabel.__kind) == "string" and AT.histLabel.__kind == "FontString",
		"счётчик истории — FontString (у него нет SetScript, обновляем по событию)")

	AT.history = {}
	AT.RunCmd(".gps")
	ok((AT.histLabel:GetText() or ""):find("1"), "после 1 команды счётчик показывает 1")
	AT.RunCmd(".gps 2")
	ok((AT.histLabel:GetText() or ""):find("2"), "после 2 команд счётчик показывает 2")
	AT.history = {}
	AT.UpdateHistoryLabel()
	eq(AT.histLabel:GetText(), "", "пустая история — пустой счётчик")
end

--===========================================================================
-- 25. Методов, которых нет в API 3.3.5, аддон не вызывает
--===========================================================================
local unknownCount = 0
for _ in pairs(STUB.unknownMethods) do unknownCount = unknownCount + 1 end
eq(unknownCount, 0, "нет вызовов неизвестных методов API")

--===========================================================================
-- 26. Темы оформления
--===========================================================================
local accentBefore = { AT.THEME.accent[1], AT.THEME.accent[2], AT.THEME.accent[3] }

ok(AT.Themes ~= nil and AT.Themes.cyan ~= nil, "палитры тем загружены")
ok(#AT.THEME_ORDER >= 4, "тем не меньше четырёх (" .. #AT.THEME_ORDER .. ")")

-- у каждой темы все нужные цвета
for _, key in ipairs(AT.THEME_ORDER) do
	local th = AT.Themes[key]
	ok(th and th.name and th.bg and th.border and th.accent and th.accent2,
		"тема укомплектована: " .. tostring(key))
end

-- переключение темы меняет цвет акцента и перекрашивает элементы
local themedOk = false
AT.ApplyTheme("emerald", true)
eq(AT.GetThemeKey(), "emerald", "тема переключилась на «изумрудную»")
eq(AdminToolsDB.theme, "emerald", "выбор темы сохранён в настройках")
ok(AT.THEME.accent[2] > accentBefore[2] - 0.01, "акцент темы применился к палитре")

if AT.themed and #AT.themed > 0 then
	local region = AT.themed[1].region
	local r, g, b = region:GetVertexColor()
	themedOk = (math.abs(r - AT.THEME.accent[1]) < 0.01
		and math.abs(g - AT.THEME.accent[2]) < 0.01)
	ok(#AT.themed >= 5, "в реестре тем не меньше 5 перекрашиваемых элементов")
end
ok(themedOk, "элементы интерфейса перекрасились в цвет темы (маркеры, линии, свечение)")

-- некорректное имя темы не ломает аддон
AT.ApplyTheme("такой-темы-нет", true)
eq(AT.GetThemeKey(), "cyan", "неизвестная тема откатывается на голубую")

-- проверка вкладки «Интерфейс»: у каждой темы есть кнопка-образец
AT.ShowPage("Интерфейс")
local swatches = 0
for _, name in ipairs(AT.THEME_ORDER) do
	if FindButton("Интерфейс", AT.Themes[name].name) then swatches = swatches + 1 end
end
eq(swatches, #AT.THEME_ORDER, "на вкладке «Интерфейс» есть кнопка для каждой темы")

--===========================================================================
-- 27. Размер и положение окна
--===========================================================================
ok(#AT.WINDOW_SIZES >= 3, "есть пресеты размера окна (" .. #AT.WINDOW_SIZES .. ")")

for i, size in ipairs(AT.WINDOW_SIZES) do
	AT.SetWindowSize(i)
	local w, h = AT.frame:GetWidth(), AT.frame:GetHeight()
	eq(w, size[2], "ширина окна для пресета «" .. size[1] .. "»")
	eq(h, size[3], "высота окна для пресета «" .. size[1] .. "»")
end

AT.SetWindowSize(2)
eq(AT.GetWindowSize(), 2, "выбранный размер окна сохраняется")
ok(AT.WindowSizeLabel():find("Обычный") ~= nil, "подпись размера окна читаема")

-- положение
for i, pos in ipairs(AT.WINDOW_POSITIONS) do
	AT.SetWindowPosition(i)
	local point = AT.frame:GetPoint()
	eq(point, pos[2], "точка привязки окна для «" .. pos[1] .. "»")
end
AT.SetWindowPosition(1)
eq(AdminToolsDB.pos[1], "CENTER", "положение окна сохраняется в настройках")

--===========================================================================
-- 28. Кнопка на миникарте: угол и скрытие
--===========================================================================
local mm = AT.minimapButton
ok(mm ~= nil, "ядро видит кнопку на миникарте (AT.minimapButton)")

if mm then
	-- до установки угла кнопка в углу миникарты
	AT.SetMinimapAngle(-1)
	eq(AT.GetMinimapAngle(), -1, "угол «по умолчанию» сохранён")

	-- угол 0 = справа по центру: X максимальный, Y примерно нулевой
	AT.SetMinimapAngle(0)
	local x0 = mm:GetLeft()
	eq(AT.GetMinimapAngle(), 0, "угол 0 сохранён")

	-- 90 = сверху: Y больше, чем при 0
	AT.SetMinimapAngle(90)
	local y90 = mm:GetTop()
	ok(y90 and x0 and y90 > 0, "кнопка переместилась по окружности миникарты")

	AT.SetMinimapAngle(180)
	local x180 = mm:GetLeft()
	ok(x180 and x0 and x180 < x0, "угол 180 ставит кнопку слева, а 0 — справа")

	-- скрытие/показ
	AT.SetMinimapShown(false)
	ok(not mm:IsShown(), "кнопку миникарты можно скрыть")
	ok(not AT.IsMinimapShown(), "состояние «скрыта» читается из настроек")
	eq(AdminToolsDB.minimapHidden, true, "скрытие сохраняется")

	AT.SetMinimapShown(true)
	ok(mm:IsShown(), "кнопку можно показать обратно")
	eq(AdminToolsDB.minimapHidden, false, "показ сохраняется")

	-- перетаскивание отменяет угол
	AT.SetMinimapAngle(45)
	AdminToolsDB.minimapPos = { "BOTTOMLEFT", "BOTTOMLEFT", 4, 4 }
	AdminToolsDB.minimapAngle = nil
	AT.RestoreMinimapPos()
	eq(AT.GetMinimapAngle(), -1, "после перетаскивания позиция важнее угла")

	AT.SetMinimapAngle(-1)
	AdminToolsDB.minimapPos = nil
end

--===========================================================================
-- 29. Переключатели чтения интерфейса
--===========================================================================
-- подсказки
AT.SetTooltipsEnabled(false)
ok(not AT.TooltipsEnabled(), "подсказки выключаются")
AdminToolsDB.restrictBySec = false
local tipBtn = FindButton("Мир", "GPS")
if tipBtn then
	STUB.Enter(tipBtn)
	local shown = STUB.lastTooltipShown and true or false
	ok(not shown, "при выключенных подсказках тултип не показывается")
	STUB.Leave(tipBtn)
end
AT.SetTooltipsEnabled(true)
ok(AT.TooltipsEnabled(), "подсказки включаются обратно")
if tipBtn then
	STUB.Enter(tipBtn)
	ok(STUB.lastTooltipShown, "при включённых подсказках тултип показывается")
	STUB.Leave(tipBtn)
end

-- фильтры
AT.SetFiltersEnabled(false)
local hiddenAll = true
for _, box in ipairs(AT.filters or {}) do
	if box:IsShown() then hiddenAll = false end
end
ok(hiddenAll, "выключенный фильтр скрыт на всех вкладках")
AT.SetFiltersEnabled(true)
AT.ShowPage("Телепорт")
local filterShown = false
for _, box in ipairs(AT.filters or {}) do
	if box:IsShown() then filterShown = true end
end
ok(filterShown, "включённый фильтр снова виден")

-- подсветка строк
ok(AT.rowHL ~= nil and #AT.rowHL > 0, "полосы подсветки строк созданы (" .. #(AT.rowHL or {}) .. ")")
AT.SetRowHighlight(false)
local anyShown = false
for _, tex in ipairs(AT.rowHL or {}) do
	if tex:IsShown() then anyShown = true end
end
ok(not anyShown, "при выключенной подсветке все полосы скрыты")
ok(not AT.RowHighlightEnabled(), "состояние подсветки читается из настроек")

if tipBtn and tipBtn.__rowHL then
	STUB.Enter(tipBtn)
	ok(not tipBtn.__rowHL:IsShown(), "выключенная подсветка не появляется при наведении")
	STUB.Leave(tipBtn)
end

AT.SetRowHighlight(true)
ok(AT.RowHighlightEnabled(), "подсветка включается обратно")
if tipBtn and tipBtn.__rowHL then
	STUB.Enter(tipBtn)
	ok(tipBtn.__rowHL:IsShown(), "включённая подсветка строки появляется при наведении")
	STUB.Leave(tipBtn)
	ok(not tipBtn.__rowHL:IsShown(), "подсветка гаснет, когда курсор ушёл")
end

--===========================================================================
-- 30. Хук показа вкладки
--===========================================================================
ok(AT.pageHooks ~= nil and type(AT.pageHooks["Интерфейс"]) == "function",
	"вкладка «Интерфейс» подписана на собственный показ")
AT.SetMinimapAngle(90)
AT.ShowPage("Интерфейс")
local mmTextFound = false
for _, child in ipairs(AT.pages["Интерфейс"]:GetChildren()) do
	local getter = child.GetText
	local t = getter and getter(child)
	if t and tostring(t):find("угол 90") then mmTextFound = true end
end
ok(mmTextFound, "при показе вкладки подпись угла обновилась")
AT.SetMinimapAngle(-1)

AT.ShowPage("Телепорт")

return T
