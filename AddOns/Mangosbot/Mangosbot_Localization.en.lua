--[[
	MangosBot — английские названия привязок клавиш (enUS).
	Раньше этот файл перезаписывал названия на любом клиенте;
	теперь действует только для английского — см. ru-файл.
]]

if GetLocale() ~= "enUS" then return end

BINDING_HEADER_MANGOSBOT = "Mangosbot";
BINDING_NAME_ROSTER = "Show/Hide Bot Roster";
BINDING_NAME_DEBUG = "Show Debug Info";
BINDING_NAME_FOLLOW = "Bot Movement: Follow Master";
BINDING_NAME_STAY = "Bot Movement: Stay";
BINDING_NAME_PASSIVE = "Bot Movement: Passive";
BINDING_NAME_FLEE = "Bot Movement: Flee";
BINDING_NAME_LOOT = "Bot Actions: Loot";
BINDING_NAME_ATTACK = "Bot Actions: Attack";
BINDING_NAME_PULL = "Bot Actions: Pull";
BINDING_NAME_BOOST = "Bot Actions: Toggle Boost";
