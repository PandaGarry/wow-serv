local addon, ns = ...

-- Build a {[itemId] = canonicalId} lookup from the huge nested ns.items table,
-- then free the original to reclaim memory.
--
-- Memory optimisation: we ONLY store NON-identity mappings (cases where the id
-- is an alias whose canonical is a different id).  Identity mappings (single-id
-- records, or the canonical id of a multi-id group, which would map to itself)
-- are omitted because every caller does `FindRecord(...) or itemId` -- a nil
-- result is interpreted as "this id is its own canonical".
--
-- This typically removes ~80% of entries (most items are listed as plain
-- numbers, not multi-variant groups), shrinking the lookup table from ~20k
-- entries to ~3-5k and saving roughly 500-800 KB of Lua heap on 32-bit WoW.
local lookup = {}
local canonicalsInDb = {}   -- all canonical item IDs that appear in the DB
do
    local type = type
    local function indexSlotData(slotData)
        for _, records in pairs(slotData) do
            for _, entry in ipairs(records) do
                if type(entry) == "table" then
                    local canonical = entry[1]
                    canonicalsInDb[canonical] = true
                    for i = 2, #entry do
                        local id = entry[i]
                        if id ~= canonical then
                            lookup[id] = canonical
                        end
                    end
                else
                    canonicalsInDb[entry] = true
                end
            end
        end
    end
    for slotName, slotData in pairs(ns.items) do
        if slotName == "Armor" then
            for _, armorSlotData in pairs(slotData) do
                indexSlotData(armorSlotData)
            end
        else
            indexSlotData(slotData)
        end
    end
    ns.items = nil
    collectgarbage("collect")
end

-- Returns the canonical item ID for the appearance group that contains
-- `whatItem`.  Returns nil if `whatItem` is its own canonical (or unknown);
-- callers MUST treat nil as "use whatItem as-is" via `FindRecord(...) or whatItem`.
function ns.FindRecord(whatSlot, whatItem)
    return lookup[whatItem]
end

-- Returns true when itemId appears anywhere in the appearances database
-- (either as a canonical entry or as an alias).  Used by border/tooltip code
-- to distinguish "in DB but not yet unlocked" from "not a transmoggable item."
function ns.IsInAppearancesDb(itemId)
    return canonicalsInDb[itemId] == true or lookup[itemId] ~= nil
end