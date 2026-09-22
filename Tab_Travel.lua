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
	{ "1-6   Североземье",        ".tele NorthshireValley" },
	{ "10-15 Сторожевой холм",    ".tele SentinelHill" },
	{ "20-25 Тёмный лес",         ".tele Darkshire" },
	{ "40-45 Терамор",            ".tele TheramoreIsle" },
	{ "58-63 Оплот Чести",        ".tele HonorHold" },
	{ "70-72 Крепость Отваги",    ".tele ValianceKeep" },
}

local GRIND_H = {
	{ "1-6   Долина Испытаний",   ".tele ValleyOfTrials" },
	{ "10-15 Перекрёсток",        ".tele TheCrossroads" },
	{ "25-30 Мельница Таррен",    ".tele TarrenMill" },
	{ "40-45 Деревня Колючего Ограждения", ".tele BrackenwallVillage" },
	{ "58-63 Траллмар",           ".tele Thrallmar" },
	{ "70-72 Крепость Песни Войны", ".tele WarsongHold" },
}

local openDungeons = AT.BuildMenu("AdminToolsRUDungeonMenu", DUNGEONS)
local openRaids    = AT.BuildMenu("AdminToolsRURaidMenu",    RAIDS)
local openGrindA   = AT.BuildMenu("AdminToolsRUGRindAMenu",  GRIND_A)
local openGrindH   = AT.BuildMenu("AdminToolsRUGRindHMenu",  GRIND_H)

local defs = {
	{ "Подземелья (все, по уровням)  \226\150\188", openDungeons },
	{ "Рейды (все, по уровням)  \226\150\188",        openRaids },
	{ "Места кача — Альянс  \226\150\188",            openGrindA },
	{ "Места кача — Орда  \226\150\188",              openGrindH },
}
for i, d in ipairs(defs) do
	local b = AT.MakeButton(p, d[1], 300, d[2], nil, "Открыть список")
	b:SetPoint("TOPLEFT", p, "TOPLEFT", 8, -12 - (i - 1) * 30)
end