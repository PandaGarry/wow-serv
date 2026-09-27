--=========================================================================
-- Tab_Travel.lua - вкладка «Путешествие»
--=========================================================================

local p = AT.RegisterTab("Путешествие")

local DUNGEONS = {
	{ "Классика", {
		{ "Огненная Пропасть (13-18)",     ".tele RagefireChasm" },
		{ "Мёртвые Копи (15-25)",           ".tele TheDeadmines" },
		{ "Монастырь Алого Ордена (28-45)", ".tele ScarletMonastery" },
		{ "Глубины Черной Горы (52-60)",    ".tele BlackrockDepths" },
		{ "Некроситет (58-60)",             ".tele Scholomance" },
	} },
	{ "Пылающий Легион", {
		{ "Бастионы Адского Пламени (60-62)", ".tele HellfireRamparts" },
		{ "Старый Хилсбрад (66-68)",          ".tele OldHillsbradFoothills" },
		{ "Разрушенные залы (70)",            ".tele TheShatteredHalls" },
		{ "Терраса Магистров (70)",           ".tele MagistersTerrace" },
	} },
	{ "Гнев Короля-лича", {
		{ "Крепость Утгард (70-72)",          ".tele UtgardeKeep" },
		{ "Нексус (71-73)",                   ".tele TheNexus" },
		{ "Гундрак (76-78)",                  ".tele Gundrak" },
		{ "Вершина Утгард (78-80)",           ".tele UtgardePinnacle" },
	} },
}

local RAIDS = {
	{ "Классика", {
		{ "Огненные Недра (60)",       ".tele MoltenCore" },
		{ "Логово Крыла Тьмы (60)",    ".go xyz -7396.4 -1070.18 589.39 469" },
		{ "Храм Ан'Киража (AQ40)",     ".tele AQ40" },
	} },
	{ "Пылающий Легион", {
		{ "Каражан (70)",              ".tele Karazhan" },
		{ "Чёрный Храм (70)",          ".tele BlackTemple" },
		{ "Плато Солнечного Колодца (70)", ".tele SunwellPlateau" },
	} },
	{ "Гнев Короля-лича", {
		{ "Наксрамас (80)",            ".go xyz 3668.72 -1262.46 243.62 571" },
		{ "Ульдуар (80)",              ".tele Ulduar" },
		{ "Цитадель Ледяной Короны (80)", ".go xyz 5873.82 2110.98 636.01 571" },
	} },
}

local GRIND_A = {
	{ "1-6: Североземье",        ".tele NorthshireValley" },
	{ "10-15: Сторожевой холм",  ".tele SentinelHill" },
	{ "20-25: Тёмный лес",       ".tele Darkshire" },
	{ "40-45: Терамор",          ".tele TheramoreIsle" },
	{ "58-63: Оплот Чести",      ".tele HonorHold" },
	{ "70-72: Крепость Отваги",  ".tele ValianceKeep" },
}

local GRIND_H = {
	{ "1-6: Долина Испытаний",   ".tele ValleyOfTrials" },
	{ "10-15: Перекрёсток",      ".tele TheCrossroads" },
	{ "25-30: Мельница Таррен",  ".tele TarrenMill" },
	{ "40-45: Деревня Колючего Ограждения", ".tele BrackenwallVillage" },
	{ "58-63: Траллмар",         ".tele Thrallmar" },
	{ "70-72: Крепость Песни Войны", ".tele WarsongHold" },
}

local openDungeons = AT.BuildMenu("AdminToolsRUDungeonMenu", DUNGEONS)
local openRaids    = AT.BuildMenu("AdminToolsRURaidMenu",    RAIDS)
local openGrindA   = AT.BuildMenu("AdminToolsRUGrindAMenu",  GRIND_A)
local openGrindH   = AT.BuildMenu("AdminToolsRUGrindHMenu",  GRIND_H)

local W = AT.floor((AT.CONTENT_W - 8 - AT.PAD) / 2)

local function MenuRow(y, left, right)
	for col, d in ipairs({ left, right }) do
		local b
		local open = d[2]
		b = AT.MakeButton(p, d[1], W, function() open(b) end, nil, d[3])
		b:SetPoint("TOPLEFT", p, "TOPLEFT", 4 + (col - 1) * (W + AT.PAD), y)
	end
	return y - AT.BTN_H - AT.PAD - 4
end

local y = AT.MakeSection(p, "Подземелья и рейды", -2)
y = MenuRow(y,
	{ "Подземелья  »", openDungeons, "Все подземелья по дополнениям и уровням" },
	{ "Рейды  »",      openRaids,    "Все рейды по дополнениям" })

y = AT.MakeSection(p, "Места прокачки", y - 4)
y = MenuRow(y,
	{ "Альянс  »", openGrindA, "Точки прокачки для Альянса" },
	{ "Орда  »",   openGrindH, "Точки прокачки для Орды" })

y = AT.MakeNote(p, "Нажмите кнопку — под ней откроется список. Наведите на раздел, чтобы увидеть точки телепорта.", y - 6)

AT.FinishPage(p, y)
