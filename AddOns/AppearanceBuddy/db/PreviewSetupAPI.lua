local addon, ns = ...

-- Extract only the current player's race+sex data for every version, then
-- free the full table (10 races × 2 sexes × 2 versions → just 2 entries).
local _, playerRace = UnitRace("player")
local playerSex     = UnitSex("player")

local playerData = {}
for version, versionData in pairs(ns.previewSetup) do
    local raceData = versionData[playerRace]
    if raceData and raceData[playerSex] then
        playerData[version] = raceData[playerSex]
    end
end
ns.previewSetup = nil
collectgarbage("collect")

local function startswith(str, a, b, c)
    local s = str:sub(1, 2)
    return s == a or s == b or s == c
end

function ns.GetPreviewSetup(version, raceFileName, sex, slot, subclass)
    local vData = playerData[version]
    if not vData then return nil end
    if vData[slot] == nil then
        return vData["Armor"] and vData["Armor"][slot]
    end
    if startswith(subclass, "1H", "MH", "OH") then
        subclass = subclass:sub(4)
    end
    return vData[slot][subclass]
end