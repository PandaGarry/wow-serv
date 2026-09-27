local AIO = AIO or require("AIO")
local TransmogHandlers
do
    local ok, handlers = pcall(AIO.AddHandlers, "Transmog", {})
    TransmogHandlers = (ok and handlers) or {}
end

local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local type = type
local next = next
local tinsert = table.insert
local tconcat = table.concat
local tsort = table.sort
local math_floor = math.floor
local math_ceil = math.ceil
local math_max = math.max
local math_min = math.min
local string_format = string.format
local string_lower = string.lower
local string_byte = string.byte

-- Per-session memory: track which player GUIDs have already had their
-- retroactive quest-reward scan completed.  Avoids even a DB round-trip
-- on re-logins within the same worldserver session.

-- Shared namespace for read-only lookup tables and class-restriction maps.
-- Consolidating these into one local frees up Lua 5.1 main-chunk register slots
-- (the main chunk is limited to 200 active locals; each individual table used
-- to occupy its own slot).  Hot-path access through T.* is still O(1) and
-- adds no measurable overhead.
local T = {}

T.QUEST_SCAN_DONE_CACHE = {}

-- Manual bitwise AND for non-negative integers up to 2^31-1.
-- Eluna's Lua 5.1 build does NOT expose the `bit` library, so we cannot use
-- bit.band.  Class masks for player classes only need 11 bits (classes 1-11),
-- so this is fast enough for the few call sites that AND restriction masks.
local function MaskAnd(a, b)
    -- Coerce signed -1 ("all classes") to 2^31-1 so the AND yields the other
    -- operand unchanged.  This matches the WoW DB convention where -1 means
    -- "no restriction" and any positive mask should win.
    if a < 0 then a = 2147483647 end
    if b < 0 then b = 2147483647 end
    local r = 0
    local bit_pos = 1
    while a > 0 and b > 0 do
        local ab, bb = a % 2, b % 2
        if ab == 1 and bb == 1 then r = r + bit_pos end
        a, b = (a - ab) / 2, (b - bb) / 2
        bit_pos = bit_pos * 2
    end
    return r
end

local SLOTS = 10
local CALC = 281

-- PLAYER_VISIBLE_ITEM_1_ENCHANTMENT field base (matches ALE script).
-- Formula: base + (equipSlot * 2)  → the uint16 that drives the enchant glow.
-- Declared as a real global (no `local`) so it remains accessible without
-- consuming one of the 200 main-chunk local register slots Lua 5.1 allows.
PLAYER_VISIBLE_ITEM_1_ENCHANTMENT = 284

-- Forward declaration: GetItemTemplateInfo is defined later but referenced
-- by the cost functions below.  Without this, the closure captures the
-- (non-existent) global instead of the local, silently crashing cost checks.
local GetItemTemplateInfo

-- ── Configuration ────────────────────────────────────────────────────────────
-- Blizzlike restrictions: when true, players may only apply appearances for
-- items their class can actually equip (armor type, weapon type, level, and
-- class-specific gear).  Set false for unrestricted cross-class transmogging.
T.Blizzlike_Transmog = true

-- Gold cost: when true, applying a transmog costs gold scaled by player level,
-- item rarity, and item required level.  Set false for free transmogging.
T.transmog_cost = true
T.TRANSMOG_COST_PER_SLOT = 50000     -- Base cost in copper per slot at max level (50000 = 5 gold)
T.TRANSMOG_COST_MAX_LEVEL = 80       -- Level at which full cost is charged

-- When true the "Reset All Transmog" button is shown in the client settings tab.
-- Set false to hide it server-wide (e.g., on servers that don't want players
-- to wipe their own collection).
T.allow_reset_all_transmog = true

-- Appearance collection policy.
-- Default is intentionally conservative: learn from equipped items and quest
-- rewards.  Direct loot/bag learning is legacy behavior because it creates
-- trade/refund edge cases that are hard to explain to players.
T.LEARN_APPEARANCES_ON_EQUIP = true
T.LEARN_APPEARANCES_FROM_BAGS = false
T.PROVISION_TEST_PLAYERS = {}
T.ITEM_QUALITY_LINK_COLORS = {
    [0] = "ff9d9d9d",
    [1] = "ffffffff",
    [2] = "ff1eff00",
    [3] = "ff0070dd",
    [4] = "ffa335ee",
    [5] = "ffff8000",
    [6] = "ffe6cc80",
    [7] = "ffe6cc80",
}
-- ─────────────────────────────────────────────────────────────────────────────

T.TRANSMOG_SCRIPT_PATH = "lua_scripts/transmog.lua"
T.TRANSMOG_SCRIPT_REVISION = "appearancebuddy-diagnostics-2026-04-13"

-- Rarity cost multipliers (quality 3 = Rare is the 1.0 baseline).
T.TRANSMOG_RARITY_MULTIPLIER = {
    [0] = 0.25,   -- Poor (grey)
    [1] = 0.25,   -- Common (white)
    [2] = 0.5,    -- Uncommon (green)
    [3] = 1.0,    -- Rare (blue)  — baseline
    [4] = 3.0,    -- Epic (purple)
    [5] = 30.0,   -- Legendary (orange)
}

-- Maximum armor subclass a class is proficient with (item class 4, subclasses 1-4).
-- Subclass: 1=Cloth, 2=Leather, 3=Mail, 4=Plate.  Subclass 0 (Misc) is always allowed.
T.CLASS_MAX_ARMOR_SUBCLASS = {
    [1]  = 4,  -- Warrior      -> Plate
    [2]  = 4,  -- Paladin      -> Plate
    [3]  = 3,  -- Hunter       -> Mail
    [4]  = 2,  -- Rogue        -> Leather
    [5]  = 1,  -- Priest       -> Cloth
    [6]  = 4,  -- Death Knight -> Plate
    [7]  = 3,  -- Shaman       -> Mail
    [8]  = 1,  -- Mage         -> Cloth
    [9]  = 1,  -- Warlock      -> Cloth
    [11] = 2,  -- Druid        -> Leather
}

-- Weapon subclasses each class is proficient with (item class 2).
-- Subclass IDs: 0=Axe1H, 1=Axe2H, 2=Bow, 3=Gun, 4=Mace1H, 5=Mace2H,
--               6=Polearm, 7=Sword1H, 8=Sword2H, 10=Staff, 13=Fist,
--               15=Dagger, 16=Thrown, 18=Crossbow, 19=Wand.
T.CLASS_ALLOWED_WEAPON_SUBCLASSES = {
    [1]  = {[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true},  -- Warrior:     1H/2H Axe, Bow, Gun, 1H/2H Mace, Polearm, 1H/2H Sword, Staff, Fist, Dagger, Thrown, Crossbow
    [2]  = {[0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true},                                                                      -- Paladin:     1H/2H Axe, 1H/2H Mace, Polearm, 1H/2H Sword
    [3]  = {[0]=true,[1]=true,[2]=true,[3]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true},                    -- Hunter:      1H/2H Axe, Bow, Gun, Polearm, 1H/2H Sword, Staff, Fist, Dagger, Thrown, Crossbow
    [4]  = {[0]=true,[2]=true,[3]=true,[4]=true,[7]=true,[13]=true,[15]=true,[16]=true,[18]=true},                                                -- Rogue:       1H Axe, Bow, Gun, 1H Mace, 1H Sword, Fist, Dagger, Thrown, Crossbow
    [5]  = {[4]=true,[10]=true,[15]=true,[19]=true},                                                                                              -- Priest:      1H Mace, Staff, Dagger, Wand
    [6]  = {[0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true},                                                                      -- Death Knight: 1H/2H Axe, 1H/2H Mace, Polearm, 1H/2H Sword
    [7]  = {[0]=true,[1]=true,[4]=true,[5]=true,[10]=true,[13]=true,[15]=true},                                                                   -- Shaman:      1H/2H Axe, 1H/2H Mace, Staff, Fist, Dagger
    [8]  = {[7]=true,[10]=true,[15]=true,[19]=true},                                                                                              -- Mage:        1H Sword, Staff, Dagger, Wand
    [9]  = {[7]=true,[10]=true,[15]=true,[19]=true},                                                                                              -- Warlock:     1H Sword, Staff, Dagger, Wand
    [11] = {[4]=true,[5]=true,[6]=true,[10]=true,[13]=true,[15]=true},                                                                            -- Druid:       1H/2H Mace, Polearm, Staff, Fist, Dagger
}

-- Classes that can equip shields (item class 4, subclass 6).
T.CLASS_SHIELD_ALLOWED = { [1]=true, [2]=true, [7]=true }  -- Warrior, Paladin, Shaman

-- Titan's Grip (spell 46917): allows Warriors to dual-wield 2H weapons.
-- Without this talent learned, a 2H weapon appearance cannot be applied to the off-hand slot.
T.TITANS_GRIP_SPELL_ID = 46917
T.SLOT_OFFHAND = 315   -- PLAYER_VISIBLE_ITEM field for the off-hand slot
T.SLOT_MAINHAND = 313   -- PLAYER_VISIBLE_ITEM field for the main-hand slot
-- Real equipment-slot indices used with GetItemByPos(player, 255, n).
T.EQUIP_SLOT_MAINHAND = 15
T.EQUIP_SLOT_OFFHAND = 16

-- Returns the inventoryType of the item actually equipped in a given
-- equipment slot, or nil if the slot is empty or unreadable.
local function GetEquippedInventoryType(player, equipSlot)
    local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
    if not ok or not item then return nil end
    local ok2, tpl = pcall(item.GetItemTemplate, item)
    if not ok2 or not tpl then return nil end
    local ok3, invType = pcall(tpl.GetInventoryType, tpl)
    return ok3 and invType or nil
end

local function HasEquippedOffhandItem(player)
    return GetEquippedInventoryType(player, T.EQUIP_SLOT_OFFHAND) ~= nil
end

local function OffhandSlotMissingEquipment(player, slot)
    return slot == T.SLOT_OFFHAND and not HasEquippedOffhandItem(player)
end

-- Returns the level-scaled cost per slot for a player.
-- Scales linearly from 10% at level 1 to 100% at max level.
-- Hardened: returns 0 on any unexpected input rather than nil/negative.
local function GetTransmogCostForPlayer(player)
    if not T.transmog_cost or T.TRANSMOG_COST_PER_SLOT <= 0 then return 0 end
    if not player then return 0 end
    local ok, level = pcall(player.GetLevel, player)
    if not ok or type(level) ~= "number" or level < 1 then level = 1 end
    local maxLvl = T.TRANSMOG_COST_MAX_LEVEL
    if type(maxLvl) ~= "number" or maxLvl < 2 then maxLvl = 80 end
    local scale = 0.10 + 0.90 * (math_max(0, level - 1) / (maxLvl - 1))
    if scale > 1 then scale = 1 end
    if scale < 0 then scale = 0 end
    local cost = math.floor(T.TRANSMOG_COST_PER_SLOT * scale)
    if cost < 0 then cost = 0 end
    return cost
end

-- Returns the cost to transmog a specific item, factoring player level, item rarity, and item required level.
-- Hardened: never returns nil or a negative number; clamps inputs.
local function GetTransmogCostForItem(player, itemId)
    local baseCost = GetTransmogCostForPlayer(player)
    if baseCost <= 0 then return 0 end
    if not itemId or itemId <= 0 then return 0 end
    local quality = 3
    local reqLevel = 0
    local tpl = GetItemTemplateInfo(itemId)
    if tpl then
        local q = tonumber(tpl.quality)
        if q and q >= 0 and q <= 5 then quality = q end
        local rl = tonumber(tpl.requiredLevel)
        if rl and rl > 0 then reqLevel = rl end
    end
    local rarityMult = T.TRANSMOG_RARITY_MULTIPLIER[quality] or 1.0
    local maxLvl = T.TRANSMOG_COST_MAX_LEVEL
    if type(maxLvl) ~= "number" or maxLvl < 2 then maxLvl = 80 end
    local itemLevelScale = 0.20 + 0.80 * (reqLevel / maxLvl)
    if itemLevelScale > 1 then itemLevelScale = 1 end
    if itemLevelScale < 0 then itemLevelScale = 0 end
    local cost = math.floor(baseCost * rarityMult * itemLevelScale)
    if cost < 0 then cost = 0 end
    return cost
end

T.VISIBLE_SLOTS = {
    283, 287, 289, 291, 293, 295, 297, 299, 301, 311, 313, 315, 317, 319
}

T.VISIBLE_SLOT_SET = {}
for _, slot in ipairs(T.VISIBLE_SLOTS) do
    T.VISIBLE_SLOT_SET[slot] = true
end

T.UNUSABLE_INVENTORY_TYPES = {[2]=true, [11]=true, [12]=true, [18]=true, [24]=true, [27]=true, [28]=true}

T.INVENTORY_TYPE_MAP = {
    [283] = "= 1", [287] = "= 3", [289] = "= 4", [291] = "IN (5,20)", [293] = "= 6",
    [295] = "= 7", [297] = "= 8", [299] = "= 9", [301] = "= 10", [311] = "= 16",
    [313] = "IN (13,17,21)", [315] = "IN (13,17,22,23,14)", [317] = "IN (15,25,26)", [319] = "= 19"
}

T.SLOT_INVENTORY_TYPES = {
    [283] = {[1] = true},
    [287] = {[3] = true},
    [289] = {[4] = true},
    [291] = {[5] = true, [20] = true},
    [293] = {[6] = true},
    [295] = {[7] = true},
    [297] = {[8] = true},
    [299] = {[9] = true},
    [301] = {[10] = true},
    [311] = {[16] = true},
    [313] = {[13] = true, [17] = true, [21] = true},
    [315] = {[13] = true, [14] = true, [17] = true, [22] = true, [23] = true},
    [317] = {[15] = true, [25] = true, [26] = true},
    [319] = {[19] = true},
}

T.APPEARANCE_SET_SLOTS = {
    { name = "Head", slot = 283 },
    { name = "Shoulder", slot = 287 },
    { name = "Back", slot = 311 },
    { name = "Chest", slot = 291 },
    { name = "Shirt", slot = 289 },
    { name = "Tabard", slot = 319 },
    { name = "Wrist", slot = 299 },
    { name = "Hands", slot = 301 },
    { name = "Waist", slot = 293 },
    { name = "Legs", slot = 295 },
    { name = "Feet", slot = 297 },
    { name = "Main Hand", slot = 313 },
    { name = "Off-hand", slot = 315 },
    { name = "Ranged", slot = 317 },
}

T.INVENTORY_TYPE_TO_SLOT_INDEX = {
    [1] = 1,
    [3] = 2,
    [16] = 3,
    [5] = 4,
    [20] = 4,
    [4] = 5,
    [19] = 6,
    [9] = 7,
    [10] = 8,
    [6] = 9,
    [7] = 10,
    [8] = 11,
    [13] = 12,
    [17] = 12,
    [21] = 12,
    [14] = 13,
    [22] = 13,
    [23] = 13,
    [15] = 14,
    [25] = 14,
    [26] = 14,
}

local function NormalizePage(page)
    page = math_floor(tonumber(page) or 1)
    return page < 1 and 1 or page
end

local function NormalizePageSize(pageSize)
    pageSize = math_floor(tonumber(pageSize) or SLOTS)
    return math_max(1, math_min(50, pageSize))
end

local function EscapeString(str)
    if not str then return "" end
    return str:gsub("'", "''"):gsub("\\", "\\\\")
end

local function NormalizeVisibleSlot(slot)
    slot = tonumber(slot)
    if not slot then return nil end
    slot = math_floor(slot)
    return T.VISIBLE_SLOT_SET[slot] and slot or nil
end

-- ---------------------------------------------------------------------------
-- Bootstrap: create the required tables if they do not already exist.
-- account_transmog lives in the auth DB; character_transmog in the chars DB.
-- ---------------------------------------------------------------------------
do
    AuthDBQuery([[
        CREATE TABLE IF NOT EXISTS `account_transmog` (
            `account_id`       INT UNSIGNED    NOT NULL,
            `unlocked_item_id` INT UNSIGNED    NOT NULL,
            `display_id`       INT UNSIGNED    NOT NULL DEFAULT 0,
            `inventory_type`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
            `item_name`        VARCHAR(255)    NOT NULL DEFAULT '',
            PRIMARY KEY (`account_id`, `unlocked_item_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    CharDBQuery([[
        CREATE TABLE IF NOT EXISTS `character_transmog` (
            `player_guid` INT UNSIGNED NOT NULL,
            `slot`        INT UNSIGNED NOT NULL,
            `item`        INT UNSIGNED     NULL DEFAULT NULL,
            `real_item`   INT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`player_guid`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    CharDBQuery([[
        CREATE TABLE IF NOT EXISTS `character_illusion` (
            `player_guid` INT UNSIGNED NOT NULL,
            `slot_id`     INT UNSIGNED NOT NULL,
            `enchant_id`  INT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`player_guid`, `slot_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    CharDBQuery([[
        CREATE TABLE IF NOT EXISTS `transmog_settings` (
            `key`   VARCHAR(64)  NOT NULL,
            `value` VARCHAR(255) NOT NULL DEFAULT '',
            PRIMARY KEY (`key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Load persisted cost toggle
    local row = CharDBQuery("SELECT `value` FROM transmog_settings WHERE `key` = 'cost_enabled' LIMIT 1")
    if row then
        local v = row:GetString(0)
        T.transmog_cost = (v == "1")
    end
end
-- ---------------------------------------------------------------------------

T.ITEM_TEMPLATE_CACHE = {}
T.ITEM_SET_TEMPLATE_CACHE = {}
-- Per-(itemset,ilvl) tier template cache.  Key = itemsetId*10000+ilvl (integer).
-- Holds one template per distinct item-level tier within an itemset so that e.g.
-- Frost Witch's ilvl-251, Sanctified ilvl-264, and Sanctified-Heroic ilvl-277
-- each get their own catalog entry with the correct display IDs.
T.ITEM_SET_TIER_CACHE = {}
-- Per-itemset list of "primary" ItemLevels: ilvls that have totalCount equal
-- to the maximum slot coverage across all ilvls in the set.  Only itemsets
-- with 2+ primary tiers are split into per-tier catalog entries (e.g. Frost
-- Witch's 251/264/277).  Single-tier sets stay as one entry.  Populated by
-- BulkEnsureItemSetTemplates so no extra DB query is needed.
T.ITEM_SET_PRIMARY_TIERS_CACHE = {}
-- Per-itemset list of all distinct ItemLevels in the DB.  Used to seed empty
-- tier groups in the catalog so every visual variant of an itemset shows even
-- when the player has only unlocked items from one of the tiers.
T.ITEM_SET_TIER_LEVELS_CACHE = {}
T.VIRTUAL_SET_TEMPLATE_CACHE = {}
T.ACCOUNT_APPEARANCE_CACHE = {}
T.ACCOUNT_ITEM_SET_CATALOG_CACHE = {}
T.ACCOUNT_ITEM_SET_CATALOG_TRANSPORT_CACHE = {}
-- Keyed by "accountGUID:classId" — caches the blizzlike-filtered packed catalog
-- per character class so the per-item WorldDB lookups happen only once.
T.ACCOUNT_ITEM_SET_BLIZZLIKE_CACHE = {}

-- Class id -> bitmask used by item_template.AllowableClass.
-- Mask is 2^(classId-1).
T.CLASS_ID_TO_MASK = {
    [1]=1,    [2]=2,    [3]=4,    [4]=8,    [5]=16,
    [6]=32,   [7]=64,   [8]=128,  [9]=256,  [11]=1024,
}

-- Race id -> faction: "Alliance" or "Horde".
-- Used at send-time to check FlagsExtra faction-only flags.
T.RACE_ID_TO_FACTION = {
    -- Alliance
    [1]  = "Alliance",  -- Human
    [3]  = "Alliance",  -- Dwarf
    [4]  = "Alliance",  -- NightElf
    [7]  = "Alliance",  -- Gnome
    [11] = "Alliance",  -- Draenei
    -- Horde
    [2]  = "Horde",     -- Orc
    [5]  = "Horde",     -- Undead
    [6]  = "Horde",     -- Tauren
    [8]  = "Horde",     -- Troll
    [10] = "Horde",     -- BloodElf
}

-- Class id -> highest wearable armor subclass (1=Cloth..4=Plate).
T.CLASS_ID_TO_MAX_ARMOR_SUBCLASS = {
    [5]=1,  -- Priest   : Cloth
    [8]=1,  -- Mage     : Cloth
    [9]=1,  -- Warlock  : Cloth
    [4]=2,  -- Rogue    : Leather
    [11]=2, -- Druid    : Leather
    [3]=3,  -- Hunter   : Mail
    [7]=3,  -- Shaman   : Mail
    [1]=4,  -- Warrior  : Plate
    [2]=4,  -- Paladin  : Plate
    [6]=4,  -- DK       : Plate
}

-- Class id -> bitmask of allowed weapon subclasses (item_template.class=2).
-- Bit position = subclass id.  Subclasses (3.3.5):
--   0=Axe1H 1=Axe2H 2=Bow 3=Gun 4=Mace1H 5=Mace2H 6=Polearm
--   7=Sword1H 8=Sword2H 10=Staff 13=Fist 15=Dagger 16=Thrown
--   18=Crossbow 19=Wand
-- Sets containing a weapon subclass not present in the player's mask are
-- hidden from the catalog under blizzlike.
T.CLASS_ID_TO_WEAPON_MASK = {
    [1]  = 374239,  -- Warrior : all except Wand
    [2]  = 1523,    -- Paladin : Axe1H/2H, Mace1H/2H, Polearm, Sword1H/2H, Staff
    [3]  = 370127,  -- Hunter  : all except Mace1H/2H, Wand
    [4]  = 368796,  -- Rogue   : Bow, Crossbow, Mace1H, Sword1H, Dagger, Fist, Gun, Thrown
    [5]  = 558096,  -- Priest  : Mace1H, Staff, Dagger, Wand
    [6]  = 499,     -- DK      : Axe1H/2H, Mace1H/2H, Polearm, Sword1H/2H
    [7]  = 42035,   -- Shaman  : Axe1H/2H, Mace1H/2H, Staff, Fist, Dagger
    [8]  = 558208,  -- Mage    : Sword1H, Staff, Dagger, Wand
    [9]  = 558208,  -- Warlock : Sword1H, Staff, Dagger, Wand
    [11] = 42096,   -- Druid   : Mace1H/2H, Polearm, Staff, Fist, Dagger
}

-- Per-account fully-packed catalog cache for the rebuilt GetUnlockedItemSets
-- handler.  Invalidated whenever an unlock/revoke mutates account_transmog.
T.UNLOCKED_ITEM_SETS_CACHE = {}

-- Per-itemset cache of canonical full item lists from item_template.
-- Set definitions never change at runtime, so this is populated once per
-- itemset and reused across every account/player query.
T.ITEMSET_FULL_CACHE = {}

local function InvalidateAccountCaches(accountGUID)
    accountGUID = tonumber(accountGUID)
    if not accountGUID then
        return
    end

    T.ACCOUNT_APPEARANCE_CACHE[accountGUID] = nil
    T.ACCOUNT_ITEM_SET_CATALOG_CACHE[accountGUID] = nil
    T.ACCOUNT_ITEM_SET_CATALOG_TRANSPORT_CACHE[accountGUID] = nil
    T.UNLOCKED_ITEM_SETS_CACHE[accountGUID] = nil
    -- Invalidate all per-class cached catalogs for this account.
    local prefix = tostring(accountGUID) .. ":"
    for k in pairs(T.ACCOUNT_ITEM_SET_BLIZZLIKE_CACHE) do
        if k:sub(1, #prefix) == prefix then
            T.ACCOUNT_ITEM_SET_BLIZZLIKE_CACHE[k] = nil
        end
    end
end

local function CreateAccountAppearanceCache(accountGUID)
    local cache = {
        accountId = tonumber(accountGUID) or 0,
        all = {},
        bySlot = {},
        bySlotIndex = {},
        bySlotDisplay = {},
        dedupedBySlot = {},       -- one record per unique displayId per slot (for pagination)
        dedupedBySlotIndex = {},  -- itemId → position in dedupedBySlot[slot]
        unlockedItemIdsCsv = nil,
    }

    for _, slot in ipairs(T.VISIBLE_SLOTS) do
        cache.bySlot[slot] = {}
        cache.bySlotIndex[slot] = {}
        cache.bySlotDisplay[slot] = {}
        cache.dedupedBySlot[slot] = {}
        cache.dedupedBySlotIndex[slot] = {}
    end

    return cache
end

local function AddAccountAppearanceRecord(cache, record)
    tinsert(cache.all, record)

    for slot, allowedInventoryTypes in pairs(T.SLOT_INVENTORY_TYPES) do
        if allowedInventoryTypes[record.inventoryType] then
            local slotRecords = cache.bySlot[slot]
            tinsert(slotRecords, record)
            cache.bySlotIndex[slot][record.itemId] = #slotRecords

            if record.displayId > 0 then
                local displayBucket = cache.bySlotDisplay[slot][record.displayId]
                if not displayBucket then
                    displayBucket = {
                        firstItemId = record.itemId,
                        items = {},
                    }
                    cache.bySlotDisplay[slot][record.displayId] = displayBucket
                elseif record.itemId < displayBucket.firstItemId then
                    displayBucket.firstItemId = record.itemId
                end

                displayBucket.items[record.itemId] = true
            end
        end
    end
end

local function GetAccountAppearanceCache(accountGUID)
    accountGUID = tonumber(accountGUID)
    if not accountGUID then
        return CreateAccountAppearanceCache(0)
    end

    local cached = T.ACCOUNT_APPEARANCE_CACHE[accountGUID]
    if cached then
        return cached
    end

    local cache = CreateAccountAppearanceCache(accountGUID)
    local unlockedItems = AuthDBQuery(string_format(
        "SELECT unlocked_item_id, display_id, inventory_type, item_name FROM account_transmog WHERE account_id = %d ORDER BY unlocked_item_id",
        accountGUID
    ))

    if unlockedItems then
        repeat
            local itemId = tonumber(unlockedItems:GetUInt32(0)) or 0
            local displayId = tonumber(unlockedItems:GetUInt32(1)) or 0
            local inventoryType = tonumber(unlockedItems:GetUInt32(2)) or 0
            local itemName = unlockedItems:GetString(3) or ""

            if itemId > 0 and inventoryType > 0 then
                AddAccountAppearanceRecord(cache, {
                    itemId = itemId,
                    displayId = displayId,
                    displayIdStr = displayId > 0 and tostring(displayId) or nil,
                    inventoryType = inventoryType,
                    itemName = itemName,
                    lowerName = string_lower(itemName),
                })
            end
        until not unlockedItems:NextRow()
    end

    T.ACCOUNT_APPEARANCE_CACHE[accountGUID] = cache

    -- Build deduplicated slot lists in a single pass.
    -- bySlot[slot] is ordered by itemId ascending (ORDER BY unlocked_item_id),
    -- so the first time a displayId appears it is already the canonical item.
    for _, slot in ipairs(T.VISIBLE_SLOTS) do
        local seenDisplayIds = {}
        local deduped      = cache.dedupedBySlot[slot]
        local dedupedIndex = cache.dedupedBySlotIndex[slot]
        for _, record in ipairs(cache.bySlot[slot]) do
            if record.displayId > 0 and not seenDisplayIds[record.displayId] then
                seenDisplayIds[record.displayId] = true
                deduped[#deduped + 1] = record
                dedupedIndex[record.itemId] = #deduped
            end
        end
    end

    local parts, count, seen = {}, 0, {}
    -- Use cache.all (every row from account_transmog) rather than dedupedBySlot
    -- (which only keeps one item per display_id per slot).  If the player has two
    -- items that share the same appearance, dedupedBySlot would only send the
    -- lower-ID one, causing the client to show "not yet collected" when hovering
    -- the higher-ID variant whose canonical ID differs in the client's item DB.
    for _, rec in ipairs(cache.all or {}) do
        local iid = tonumber(rec.itemId)
        if iid and iid > 0 and not seen[iid] then
            seen[iid] = true
            count = count + 1
            parts[count] = iid
        end
    end
    cache.unlockedItemIdsCsv = tconcat(parts, ",")

    return cache
end

local function IsArmorSetSlotIndex(slotIndex)
    return slotIndex and slotIndex >= 1 and slotIndex <= 11
end

local function GetVirtualSetBaseName(itemName)
    itemName = tostring(itemName or ""):gsub("%s+$", "")
    if itemName == "" then return nil end
    local baseName = itemName:gsub("%s+[^%s]+$", "")
    return (baseName ~= "" and baseName ~= itemName) and baseName or nil
end

local function GetVirtualSetId(baseName)
    local hash = 0
    for index = 1, #baseName do
        hash = (hash * 33 + string_byte(baseName, index)) % 2147483647
    end

    if hash == 0 then
        hash = 1
    end

    return -hash
end

local function GetStoredRealItemId(playerGUID, slot)
    local r = CharDBQuery(string_format("SELECT real_item FROM character_transmog WHERE player_guid = %d AND slot = %d", playerGUID, slot))
    return r and (tonumber(r:GetUInt32(0)) or 0) or 0
end

-- Fetch real_item for every slot in one query instead of one query per slot.
local function GetAllStoredRealItemIds(playerGUID)
    local result = {}
    local rows = CharDBQuery(string_format(
        "SELECT slot, real_item FROM character_transmog WHERE player_guid = %d",
        playerGUID
    ))
    if rows then
        repeat
            local slot = tonumber(rows:GetUInt32(0))
            if slot then
                result[slot] = tonumber(rows:GetUInt32(1)) or 0
            end
        until not rows:NextRow()
    end
    return result
end

-- Fetch the current transmog appearance item for every slot (the `item` column).
-- Returns slot -> itemId map; slots with no override or a NULL item are absent.
local function GetAllStoredItemIds(playerGUID)
    local result = {}
    local rows = CharDBQuery(string_format(
        "SELECT slot, item FROM character_transmog WHERE player_guid = %d AND item IS NOT NULL",
        playerGUID
    ))
    if rows then
        repeat
            local slot = tonumber(rows:GetUInt32(0))
            if slot then
                result[slot] = tonumber(rows:GetUInt32(1)) or 0
            end
        until not rows:NextRow()
    end
    return result
end

local function UpsertTransmogSlot(playerGUID, slot, item, realItemId)
    local itemValue = item == nil and "NULL" or tostring(tonumber(item) or 0)
    realItemId = tonumber(realItemId) or 0

    CharDBQuery(string_format(
        "INSERT INTO character_transmog (`player_guid`, `slot`, `item`, `real_item`) VALUES (%d, %d, %s, %d) ON DUPLICATE KEY UPDATE item = VALUES(item), real_item = VALUES(real_item)",
        playerGUID, slot, itemValue, realItemId
    ))
end

-- Upsert multiple slots in a single INSERT ... ON DUPLICATE KEY UPDATE.
local function BatchUpsertTransmogSlots(playerGUID, updates)
    if not updates or #updates == 0 then return end
    local values = {}
    for _, u in ipairs(updates) do
        local slot, item, realItemId = u[1], u[2], tonumber(u[3]) or 0
        local itemValue = item == nil and "NULL" or tostring(tonumber(item) or 0)
        values[#values + 1] = string_format("(%d, %d, %s, %d)", playerGUID, slot, itemValue, realItemId)
    end
    CharDBQuery(
        "INSERT INTO character_transmog (`player_guid`, `slot`, `item`, `real_item`) VALUES "
        .. tconcat(values, ", ")
        .. " ON DUPLICATE KEY UPDATE item = VALUES(item), real_item = VALUES(real_item)"
    )
end

GetItemTemplateInfo = function(itemId)
    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 then return nil end
    local cached = T.ITEM_TEMPLATE_CACHE[itemId]
    if cached then return cached end
    local query = WorldDBQuery(string_format("SELECT itemset, InventoryType, name, displayid, class, subclass, Quality, RequiredLevel, AllowableClass, FlagsExtra, AllowableRace, ItemLevel FROM item_template WHERE entry = %u LIMIT 1", itemId))
    if not query then return nil end
    cached = {
        itemset         = tonumber(query:GetUInt32(0)) or 0,
        inventoryType   = tonumber(query:GetUInt32(1)) or 0,
        name            = query:GetString(2) or "",
        displayId       = tonumber(query:GetUInt32(3)) or 0,
        class           = tonumber(query:GetUInt32(4)) or 0,
        subclass        = tonumber(query:GetUInt32(5)) or 0,
        quality         = tonumber(query:GetUInt32(6)) or 0,
        requiredLevel   = tonumber(query:GetUInt32(7)) or 0,
        allowableClass  = tonumber(query:GetInt32(8)),   -- signed: -1 = all classes
        flagsExtra      = tonumber(query:GetUInt32(9)) or 0,
        allowableRace   = tonumber(query:GetInt32(10)),  -- signed: -1 = all races
        itemLevel       = tonumber(query:GetUInt32(11)) or 0,
    }
    T.ITEM_TEMPLATE_CACHE[itemId] = cached
    return cached
end

-- Bulk-warm T.ITEM_TEMPLATE_CACHE; one IN() instead of one query per record.
-- Chunks into batches of 500 to avoid exceeding max_allowed_packet.
T.BULK_CHUNK_SIZE = 500

local function BulkEnsureItemTemplates(allRecords)
    local missing = {}
    for _, record in ipairs(allRecords) do
        local itemId = tonumber(record.itemId)
        if itemId and itemId > 0 and T.ITEM_TEMPLATE_CACHE[itemId] == nil then
            missing[#missing + 1] = itemId
            T.ITEM_TEMPLATE_CACHE[itemId] = false  -- in-flight sentinel
        end
    end
    if #missing == 0 then return end

    local chunk = {}
    for chunkStart = 1, #missing, T.BULK_CHUNK_SIZE do
        local chunkEnd = math_min(chunkStart + T.BULK_CHUNK_SIZE - 1, #missing)
        local chunkLen = 0
        for i = chunkStart, chunkEnd do
            chunkLen = chunkLen + 1
            chunk[chunkLen] = missing[i]
        end
        -- Trim any leftovers from a previous (larger) iteration.
        for i = chunkLen + 1, #chunk do chunk[i] = nil end
        local query = WorldDBQuery(string_format(
            "SELECT entry, itemset, InventoryType, name, displayid, class, subclass, Quality, RequiredLevel, AllowableClass, FlagsExtra, AllowableRace, ItemLevel FROM item_template WHERE entry IN (%s)",
            tconcat(chunk, ",")
        ))
        if query then
            repeat
                local entry = tonumber(query:GetUInt32(0)) or 0
                if entry > 0 then
                    T.ITEM_TEMPLATE_CACHE[entry] = {
                        itemset         = tonumber(query:GetUInt32(1)) or 0,
                        inventoryType   = tonumber(query:GetUInt32(2)) or 0,
                        name            = query:GetString(3) or "",
                        displayId       = tonumber(query:GetUInt32(4)) or 0,
                        class           = tonumber(query:GetUInt32(5)) or 0,
                        subclass        = tonumber(query:GetUInt32(6)) or 0,
                        quality         = tonumber(query:GetUInt32(7)) or 0,
                        requiredLevel   = tonumber(query:GetUInt32(8)) or 0,
                        allowableClass  = tonumber(query:GetInt32(9)),   -- signed: -1 = all classes
                        flagsExtra      = tonumber(query:GetUInt32(10)) or 0,
                        allowableRace   = tonumber(query:GetInt32(11)),  -- signed: -1 = all races
                        itemLevel       = tonumber(query:GetUInt32(12)) or 0,
                    }
                end
            until not query:NextRow()
        end
    end
    -- Clear sentinels for items the DB returned no row for (truly unknown entries).
    for _, itemId in ipairs(missing) do
        if T.ITEM_TEMPLATE_CACHE[itemId] == false then
            T.ITEM_TEMPLATE_CACHE[itemId] = nil
        end
    end
end

local function DeriveItemSetName(names)
    local prefixWords
    for _, itemName in ipairs(names) do
        local words = {}
        for word in tostring(itemName or ""):gmatch("%S+") do words[#words+1] = word end
        if not prefixWords then
            prefixWords = words
        else
            local nextPrefix = {}
            for i = 1, math_min(#prefixWords, #words) do
                if prefixWords[i] ~= words[i] then break end
                nextPrefix[#nextPrefix+1] = prefixWords[i]
            end
            prefixWords = nextPrefix
        end
        if not prefixWords or #prefixWords == 0 then break end
    end
    if prefixWords and #prefixWords > 0 then
        local name = tconcat(prefixWords, " "):gsub("[%s%-:]+$", "")
        if name ~= "" then return name end
    end
    return names[1] or "Unnamed Set"
end

local function GetVirtualSetTemplate(baseName)
    baseName = tostring(baseName or ""):gsub("%s+$", "")
    if baseName == "" then
        return nil
    end

    local cached = T.VIRTUAL_SET_TEMPLATE_CACHE[baseName]
    if cached then
        return cached
    end

    local safeBaseName = EscapeString(baseName):gsub("%%", "\\%%"):gsub("_", "\\_")
    local query = WorldDBQuery(string_format(
        "SELECT entry, name, InventoryType, displayid FROM item_template WHERE InventoryType IN (1,3,4,5,6,7,8,9,10,16,19,20) AND name LIKE '%s %%' ORDER BY entry",
        safeBaseName
    ))
    if not query then
        return nil
    end

    local fullItems = {}
    local fullItemDisplay = {}
    local itemNames = {}
    local totalCount = 0

    repeat
        local entry = tonumber(query:GetUInt32(0)) or 0
        local name = query:GetString(1) or ""
        local inventoryType = tonumber(query:GetUInt32(2)) or 0
        local displayId = tonumber(query:GetUInt32(3)) or 0
        local slotIndex = T.INVENTORY_TYPE_TO_SLOT_INDEX[inventoryType]

        if slotIndex and IsArmorSetSlotIndex(slotIndex) and GetVirtualSetBaseName(name) == baseName then
            if not fullItems[slotIndex] or fullItems[slotIndex] == 0 then
                fullItems[slotIndex] = entry
                fullItemDisplay[slotIndex] = displayId
                totalCount = totalCount + 1
                tinsert(itemNames, name)
            end
        end
    until not query:NextRow()

    if totalCount == 0 then
        return nil
    end

    for index = 1, #T.APPEARANCE_SET_SLOTS do
        fullItems[index] = tonumber(fullItems[index]) or 0
        fullItemDisplay[index] = tonumber(fullItemDisplay[index]) or 0
    end

    cached = {
        id = GetVirtualSetId(baseName),
        name = DeriveItemSetName(itemNames),
        fullItems = fullItems,
        fullItemDisplay = fullItemDisplay,
        totalCount = totalCount,
    }

    T.VIRTUAL_SET_TEMPLATE_CACHE[baseName] = cached
    return cached
end

local function GetItemSetTemplate(itemsetId)
    itemsetId = tonumber(itemsetId)
    if not itemsetId or itemsetId <= 0 then
        return nil
    end

    local cached = T.ITEM_SET_TEMPLATE_CACHE[itemsetId]
    if cached then
        return cached
    end

    local query = WorldDBQuery(string_format(
        "SELECT entry, name, InventoryType, AllowableClass, displayid FROM item_template WHERE itemset = %u ORDER BY entry",
        itemsetId
    ))
    if not query then
        return nil
    end

    local fullItems = {}
    local fullItemDisplay = {}
    local itemNames = {}
    local itemNameBySlot = {}  -- track first item name per slot for variant labelling
    local totalCount = 0
    local classMask = -1  -- -1 = all classes; AND down to the set's restriction

    repeat
        local entry = tonumber(query:GetUInt32(0)) or 0
        local name = query:GetString(1) or ""
        local inventoryType = tonumber(query:GetUInt32(2)) or 0
        local allowableClass = query:GetInt32(3)
        local displayId = tonumber(query:GetUInt32(4)) or 0
        local slotIndex = T.INVENTORY_TYPE_TO_SLOT_INDEX[inventoryType]

        if slotIndex and (not fullItems[slotIndex] or fullItems[slotIndex] == 0) then
            fullItems[slotIndex]       = entry
            fullItemDisplay[slotIndex] = displayId
            totalCount = totalCount + 1
            tinsert(itemNames, name)
            itemNameBySlot[slotIndex] = name  -- first item wins per slot
        end
        -- AND class masks: only classes allowed by every item remain set.
        if allowableClass and allowableClass ~= -1 and allowableClass ~= 0 then
            if classMask == -1 then
                classMask = allowableClass
            else
                classMask = MaskAnd(classMask, allowableClass)
            end
        end
    until not query:NextRow()

    if totalCount == 0 then
        return nil
    end

    for index = 1, #T.APPEARANCE_SET_SLOTS do
        fullItems[index]       = tonumber(fullItems[index]) or 0
        fullItemDisplay[index] = tonumber(fullItemDisplay[index]) or 0
    end

    cached = {
        id = itemsetId,
        name = DeriveItemSetName(itemNames),
        fullItems = fullItems,
        fullItemDisplay = fullItemDisplay,
        totalCount = totalCount,
        allowableClass = classMask,
        variantLabel = (function()
            -- Derive a short label that distinguishes this set from others sharing
            -- the same common-prefix name (e.g. "Tunic" for Frost Witch's 892,
            -- "Hauberk" for 893, "Chestguard" for 894).  Prefer the chest piece
            -- (slotIndex 4 = InventoryType 5); fall back to head (slotIndex 1).
            local base = DeriveItemSetName(itemNames)
            local src  = itemNameBySlot[4] or itemNameBySlot[1] or itemNames[1] or ""
            if base == "" or #src <= #base then return "" end
            return (src:sub(#base + 2):gsub("^%s+", ""):gsub("%s+$", ""))
        end)(),
    }

    T.ITEM_SET_TEMPLATE_CACHE[itemsetId] = cached
    return cached
end

-- Return a per-ilvl-tier template for a given itemset + item level.
-- Used so that e.g. Frost Witch's ilvl-251 / Sanctified ilvl-264 / ilvl-277 each
-- produce a distinct catalog entry with the correct display IDs for that tier.
-- Cache key is the synthetic integer itemsetId*10000+ilvl to avoid string overhead.
local function GetItemSetTierTemplate(itemsetId, ilvl)
    itemsetId = tonumber(itemsetId)
    ilvl      = tonumber(ilvl)
    if not itemsetId or itemsetId <= 0 or not ilvl or ilvl <= 0 then return nil end

    local cacheKey = itemsetId * 10000 + ilvl
    local cached = T.ITEM_SET_TIER_CACHE[cacheKey]
    if cached ~= nil then return cached or nil end  -- false = negative-cache sentinel

    local query = WorldDBQuery(string_format(
        "SELECT entry, name, InventoryType, AllowableClass, displayid FROM item_template WHERE itemset = %u AND ItemLevel = %u ORDER BY entry",
        itemsetId, ilvl
    ))
    if not query then
        T.ITEM_SET_TIER_CACHE[cacheKey] = false
        return nil
    end

    local fullItems       = {}
    local fullItemDisplay = {}   -- parallel: display ID per slot for visual comparison
    local itemNames       = {}
    local itemNameBySlot  = {}
    local totalCount      = 0
    local classMask       = -1

    repeat
        local entry          = tonumber(query:GetUInt32(0)) or 0
        local name           = query:GetString(1) or ""
        local inventoryType  = tonumber(query:GetUInt32(2)) or 0
        local allowableClass = query:GetInt32(3)
        local displayId      = tonumber(query:GetUInt32(4)) or 0
        local slotIndex      = T.INVENTORY_TYPE_TO_SLOT_INDEX[inventoryType]

        if slotIndex and (not fullItems[slotIndex] or fullItems[slotIndex] == 0) then
            fullItems[slotIndex]       = entry
            fullItemDisplay[slotIndex] = displayId
            totalCount                 = totalCount + 1
            tinsert(itemNames, name)
            itemNameBySlot[slotIndex]  = name
        end
        if allowableClass and allowableClass ~= -1 and allowableClass ~= 0 then
            if classMask == -1 then classMask = allowableClass
            else classMask = MaskAnd(classMask, allowableClass) end
        end
    until not query:NextRow()

    if totalCount == 0 then
        T.ITEM_SET_TIER_CACHE[cacheKey] = false
        return nil
    end

    for i = 1, #T.APPEARANCE_SET_SLOTS do
        fullItems[i]       = tonumber(fullItems[i]) or 0
        fullItemDisplay[i] = tonumber(fullItemDisplay[i]) or 0
    end

    local baseName = DeriveItemSetName(itemNames)
    local src      = itemNameBySlot[4] or itemNameBySlot[1] or itemNames[1] or ""
    local vLabel   = (baseName ~= "" and #src > #baseName)
                     and src:sub(#baseName + 2):gsub("^%s+", ""):gsub("%s+$", "")
                     or  ""

    cached = {
        id             = cacheKey,
        ilvl           = ilvl,
        name           = baseName,
        fullItems      = fullItems,
        fullItemDisplay = fullItemDisplay,
        totalCount     = totalCount,
        allowableClass = classMask,
        variantLabel   = vLabel,
    }
    T.ITEM_SET_TIER_CACHE[cacheKey] = cached
    return cached
end

-- Return the sorted list of distinct ItemLevels that exist for an itemset.
-- Lazily queries the DB the first time and caches the result so subsequent
-- catalog builds for other accounts reuse the same list.
local function GetItemSetTierLevels(itemsetId)
    itemsetId = tonumber(itemsetId)
    if not itemsetId or itemsetId <= 0 then return nil end
    local cached = T.ITEM_SET_TIER_LEVELS_CACHE[itemsetId]
    if cached ~= nil then return cached or nil end

    local query = WorldDBQuery(string_format(
        "SELECT DISTINCT ItemLevel FROM item_template WHERE itemset = %u AND ItemLevel > 0 ORDER BY ItemLevel",
        itemsetId
    ))
    if not query then
        T.ITEM_SET_TIER_LEVELS_CACHE[itemsetId] = false
        return nil
    end
    local levels = {}
    repeat
        local lvl = tonumber(query:GetUInt32(0)) or 0
        if lvl > 0 then levels[#levels + 1] = lvl end
    until not query:NextRow()
    if #levels == 0 then
        T.ITEM_SET_TIER_LEVELS_CACHE[itemsetId] = false
        return nil
    end
    T.ITEM_SET_TIER_LEVELS_CACHE[itemsetId] = levels
    return levels
end

-- Bulk-warm T.ITEM_SET_TEMPLATE_CACHE; one IN() instead of one query per set.
local function BulkEnsureItemSetTemplates(allRecords)
    local missing = {}
    local seen = {}
    for _, record in ipairs(allRecords) do
        local tpl = T.ITEM_TEMPLATE_CACHE[tonumber(record.itemId) or 0]
        if tpl then
            local itemsetId = tonumber(tpl.itemset) or 0
            if itemsetId > 0 and not seen[itemsetId] and T.ITEM_SET_TEMPLATE_CACHE[itemsetId] == nil then
                missing[#missing + 1] = itemsetId
                seen[itemsetId] = true
            end
        end
    end
    if #missing == 0 then return end

    -- Include ItemLevel and displayid so we can build per-tier templates in the
    -- same pass that populates the legacy non-tiered cache.
    local query = WorldDBQuery(string_format(
        "SELECT entry, name, InventoryType, itemset, AllowableClass, ItemLevel, displayid FROM item_template WHERE itemset IN (%s) ORDER BY entry",
        tconcat(missing, ",")
    ))

    local partials     = {}   -- non-tiered: partials[itemsetId]
    local tierPartials = {}   -- per-tier:   tierPartials[itemsetId*10000+ilvl]
    if query then
        repeat
            local entry          = tonumber(query:GetUInt32(0)) or 0
            local name           = query:GetString(1) or ""
            local invType        = tonumber(query:GetUInt32(2)) or 0
            local itemsetId      = tonumber(query:GetUInt32(3)) or 0
            local allowableClass = query:GetInt32(4)
            local ilvl           = tonumber(query:GetUInt32(5)) or 0
            local displayId      = tonumber(query:GetUInt32(6)) or 0
            local slotIdx        = T.INVENTORY_TYPE_TO_SLOT_INDEX[invType]
            if itemsetId > 0 and slotIdx then
                -- Non-tiered partial (lowest-entry item per slot, ignoring ilvl)
                local p = partials[itemsetId]
                if not p then
                    partials[itemsetId] = { fullItems = {}, fullItemDisplay = {}, itemNames = {}, itemNameBySlot = {}, totalCount = 0, classMask = -1 }
                    p = partials[itemsetId]
                end
                if not p.fullItems[slotIdx] or p.fullItems[slotIdx] == 0 then
                    p.fullItems[slotIdx]       = entry
                    p.fullItemDisplay[slotIdx] = displayId
                    p.totalCount = p.totalCount + 1
                    p.itemNames[#p.itemNames + 1] = name
                    p.itemNameBySlot[slotIdx] = name
                end

                -- Per-tier partial
                if ilvl > 0 then
                    local tierKey = itemsetId * 10000 + ilvl
                    if T.ITEM_SET_TIER_CACHE[tierKey] == nil then
                        local tp = tierPartials[tierKey]
                        if not tp then
                            tierPartials[tierKey] = { itemsetId=itemsetId, ilvl=ilvl, fullItems={}, fullItemDisplay={}, itemNames={}, itemNameBySlot={}, totalCount=0, classMask=-1 }
                            tp = tierPartials[tierKey]
                        end
                        if not tp.fullItems[slotIdx] or tp.fullItems[slotIdx] == 0 then
                            tp.fullItems[slotIdx]       = entry
                            tp.fullItemDisplay[slotIdx] = displayId
                            tp.totalCount               = tp.totalCount + 1
                            tp.itemNames[#tp.itemNames + 1] = name
                            tp.itemNameBySlot[slotIdx]  = name
                        end
                        if allowableClass and allowableClass ~= -1 and allowableClass ~= 0 then
                            if tp.classMask == -1 then tp.classMask = allowableClass
                            else tp.classMask = MaskAnd(tp.classMask, allowableClass) end
                        end
                    end
                end

                if allowableClass and allowableClass ~= -1 and allowableClass ~= 0 then
                    if p.classMask == -1 then
                        p.classMask = allowableClass
                    else
                        p.classMask = MaskAnd(p.classMask, allowableClass)
                    end
                end
            end
        until not query:NextRow()
    end

    -- Commit non-tiered templates
    for _, id in ipairs(missing) do
        local p = partials[id]
        if p and p.totalCount > 0 then
            for i = 1, #T.APPEARANCE_SET_SLOTS do
                p.fullItems[i]       = tonumber(p.fullItems[i]) or 0
                p.fullItemDisplay[i] = tonumber(p.fullItemDisplay[i]) or 0
            end
            local baseName = DeriveItemSetName(p.itemNames)
            local src = p.itemNameBySlot[4] or p.itemNameBySlot[1] or p.itemNames[1] or ""
            local vLabel = ""
            if baseName ~= "" and #src > #baseName then
                vLabel = (src:sub(#baseName + 2):gsub("^%s+", ""):gsub("%s+$", ""))
            end
            T.ITEM_SET_TEMPLATE_CACHE[id] = { id=id, name=baseName, fullItems=p.fullItems, fullItemDisplay=p.fullItemDisplay, totalCount=p.totalCount, allowableClass=p.classMask, variantLabel=vLabel }
        end
    end

    -- Commit per-tier templates
    for tierKey, tp in pairs(tierPartials) do
        if tp.totalCount > 0 then
            for i = 1, #T.APPEARANCE_SET_SLOTS do
                tp.fullItems[i]       = tonumber(tp.fullItems[i]) or 0
                tp.fullItemDisplay[i] = tonumber(tp.fullItemDisplay[i]) or 0
            end
            local baseName = DeriveItemSetName(tp.itemNames)
            local src = tp.itemNameBySlot[4] or tp.itemNameBySlot[1] or tp.itemNames[1] or ""
            local vLabel = (baseName ~= "" and #src > #baseName)
                           and src:sub(#baseName + 2):gsub("^%s+", ""):gsub("%s+$", "")
                           or  ""
            T.ITEM_SET_TIER_CACHE[tierKey] = {
                id             = tierKey,
                ilvl           = tp.ilvl,
                name           = baseName,
                fullItems      = tp.fullItems,
                fullItemDisplay = tp.fullItemDisplay,
                totalCount     = tp.totalCount,
                allowableClass = tp.classMask,
                variantLabel   = vLabel,
            }
        end
    end

    -- Compute primary tiers per touched itemset: sorted list of ilvls whose
    -- totalCount equals the maximum across the set.  Used by the catalog to
    -- decide which sets warrant per-tier splitting.
    do
        local maxBy = {}  -- itemsetId -> max totalCount
        for _, tp in pairs(tierPartials) do
            local sid = tp.itemsetId
            if (maxBy[sid] or 0) < tp.totalCount then maxBy[sid] = tp.totalCount end
        end
        local listBy = {}  -- itemsetId -> { ilvl, ... }
        for _, tp in pairs(tierPartials) do
            local sid = tp.itemsetId
            if tp.totalCount == maxBy[sid] then
                local L = listBy[sid] or {}
                L[#L + 1] = tp.ilvl
                listBy[sid] = L
            end
        end
        for _, sid in ipairs(missing) do
            local L = listBy[sid]
            if L then tsort(L); T.ITEM_SET_PRIMARY_TIERS_CACHE[sid] = L
            else           T.ITEM_SET_PRIMARY_TIERS_CACHE[sid] = false end
        end
    end
end

local function GetUnlockedAppearanceItemId(accountGUID, slot, itemId)
    itemId = tonumber(itemId)
    slot = NormalizeVisibleSlot(slot)
    if not itemId or itemId <= 0 or not slot then return nil end
    local tpl = T.INVENTORY_TYPE_MAP[slot] and GetItemTemplateInfo(itemId)
    if not tpl then return nil end
    local displayId = tonumber(tpl.displayId)
    if not displayId or displayId <= 0 then return nil end
    local bucket = GetAccountAppearanceCache(accountGUID).bySlotDisplay[slot][displayId]
    if not bucket then return nil end
    return bucket.items[itemId] and itemId or tonumber(bucket.firstItemId) or nil
end

local function BuildAccountItemSetCatalog(accountGUID)
    accountGUID = tonumber(accountGUID)
    if not accountGUID then
        return {}
    end

    local cachedCatalog = T.ACCOUNT_ITEM_SET_CATALOG_CACHE[accountGUID]
    if cachedCatalog then
        return cachedCatalog
    end

    local appearanceCache = GetAccountAppearanceCache(accountGUID)

    BulkEnsureItemTemplates(appearanceCache.all)
    BulkEnsureItemSetTemplates(appearanceCache.all)

    local grouped = {}

    for _, record in ipairs(appearanceCache.all) do
        local itemId = tonumber(record.itemId) or 0
        local itemTemplate = GetItemTemplateInfo(itemId)
        if itemTemplate then
            local slotIndex = T.INVENTORY_TYPE_TO_SLOT_INDEX[itemTemplate.inventoryType]
            local groupKey = nil
            local groupId = nil
            local groupName = nil
            local setTemplate = nil
            local isVirtual = false
            local hasExactTotal = false

            if itemTemplate.itemset and itemTemplate.itemset > 0 then
                -- Only split into per-ilvl tiers when the itemset actually has
                -- multiple primary visual tiers (Frost Witch's 251/264/277).
                -- Single-tier sets stay as a single catalog entry to avoid
                -- spurious fragmentation (e.g. one-piece "tiers" when an item's
                -- ilvl differs from the rest of its set).
                local sid     = itemTemplate.itemset
                local ilvl    = itemTemplate.itemLevel or 0
                local primary = T.ITEM_SET_PRIMARY_TIERS_CACHE[sid]
                local useTier = primary and #primary > 1 and ilvl > 0
                local tierIlvl
                if useTier then
                    -- Map item's ilvl to nearest primary tier (for items with
                    -- ilvls slightly off from the canonical tier values).
                    local best, bestD = primary[1], math.abs(primary[1] - ilvl)
                    for i = 2, #primary do
                        local d = math.abs(primary[i] - ilvl)
                        if d < bestD or (d == bestD and primary[i] > best) then
                            best, bestD = primary[i], d
                        end
                    end
                    tierIlvl = best
                end
                local tierTpl = useTier and slotIndex and GetItemSetTierTemplate(sid, tierIlvl) or nil
                setTemplate = tierTpl or (slotIndex and GetItemSetTemplate(sid) or nil)
                if slotIndex and setTemplate then
                    if tierTpl then
                        groupKey = "itemset:"..sid..":"..tierIlvl
                        groupId  = tierTpl.id   -- synthetic int = itemsetId*10000+ilvl
                    else
                        groupKey = "itemset:"..sid
                        groupId  = sid
                    end
                    groupName    = setTemplate.name
                    hasExactTotal = true
                end
            elseif IsArmorSetSlotIndex(slotIndex) then
                local baseName = GetVirtualSetBaseName(record.itemName or itemTemplate.name)
                if baseName then
                    setTemplate = GetVirtualSetTemplate(baseName)
                    groupKey = "virtual:"..baseName
                    groupId = GetVirtualSetId(baseName)
                    groupName = setTemplate and setTemplate.name or baseName
                    isVirtual = true
                    hasExactTotal = setTemplate ~= nil
                end
            end

            if groupKey then
                local group = grouped[groupKey]
                if not group then
                    group = {
                        id            = groupId,
                        ilvl          = setTemplate and setTemplate.ilvl or 0,
                        variantLabel  = setTemplate and setTemplate.variantLabel or "",
                        name          = groupName,
                        displayName   = groupName,
                        fullItems     = {},
                        fullItemDisplay = {},
                        unlockedItems = {},
                        unlockedCount = 0,
                        totalCount    = setTemplate and (tonumber(setTemplate.totalCount) or 0) or 0,
                        isVirtual     = isVirtual,
                        hasExactTotal = hasExactTotal,
                        allowableClass = (setTemplate and setTemplate.allowableClass) or -1,
                    }

                    for index = 1, #T.APPEARANCE_SET_SLOTS do
                        group.fullItems[index]       = setTemplate and (tonumber(setTemplate.fullItems[index]) or 0) or 0
                        group.fullItemDisplay[index] = setTemplate and setTemplate.fullItemDisplay and (tonumber(setTemplate.fullItemDisplay[index]) or 0) or 0
                        group.unlockedItems[index]   = 0
                    end

                    grouped[groupKey] = group
                end

                if group.unlockedItems[slotIndex] == 0 then
                    group.unlockedItems[slotIndex] = itemId
                    group.unlockedCount = group.unlockedCount + 1

                    if group.fullItems[slotIndex] == 0 then
                        group.fullItems[slotIndex] = itemId
                        if group.isVirtual then
                            group.totalCount = group.totalCount + 1
                        end
                    end
                end
            end
        end
    end

    -- Seed empty tier groups: for every multi-tier itemset the player has
    -- touched, walk its primary tiers and create empty (0-unlock) groups for
    -- tiers the player hasn't farmed yet.  Limited to true multi-tier sets
    -- (T.ITEM_SET_PRIMARY_TIERS_CACHE[sid] has 2+ entries) to avoid spurious
    -- one-piece "tier" entries on single-tier sets.
    do
        local seenItemsets = {}
        for _, g in pairs(grouped) do
            if not g.isVirtual and g.id and g.id > 10000 then
                local itemsetId = math.floor(g.id / 10000)
                seenItemsets[itemsetId] = true
            end
        end
        for itemsetId in pairs(seenItemsets) do
            local primary = T.ITEM_SET_PRIMARY_TIERS_CACHE[itemsetId]
            if primary and #primary > 1 then
                for _, lvl in ipairs(primary) do
                    local key = "itemset:"..itemsetId..":"..lvl
                    if not grouped[key] then
                        local tt = GetItemSetTierTemplate(itemsetId, lvl)
                        if tt then
                            local g = {
                                id              = tt.id,
                                ilvl            = tt.ilvl or lvl,
                                variantLabel    = tt.variantLabel or "",
                                name            = tt.name,
                                displayName     = tt.name,
                                fullItems       = {},
                                fullItemDisplay = {},
                                unlockedItems   = {},
                                unlockedCount   = 0,
                                totalCount      = tonumber(tt.totalCount) or 0,
                                isVirtual       = false,
                                hasExactTotal   = true,
                                allowableClass  = tt.allowableClass or -1,
                                seededTier      = true,
                            }
                            for i = 1, #T.APPEARANCE_SET_SLOTS do
                                g.fullItems[i]       = tonumber(tt.fullItems[i])       or 0
                                g.fullItemDisplay[i] = tonumber(tt.fullItemDisplay[i]) or 0
                                g.unlockedItems[i]   = 0
                            end
                            grouped[key] = g
                        end
                    end
                end
            end
        end
    end

    local result = {}
    for _, group in pairs(grouped) do
        if group.totalCount > 0 then
            result[#result+1] = group
        end
    end

    -- Merge groups sharing the same display name.
    -- Three cases are handled:
    --   1) addsNewSlots=true  → complement merge (groups cover different slots)
    --   2) addsNewSlots=false, visually identical (majority of shared slots have
    --      matching display IDs) → merge unlocked-item counts but keep existing
    --      fullItems/display unchanged.  This collapses spec variants that look
    --      identical (e.g. Frost Witch's 892/893/894 at ilvl-264 all share the
    --      same display IDs, so they produce one catalog entry).
    --   3) addsNewSlots=false, visually different → keep as a separate entry.
    --      This preserves distinct color tiers (ilvl-251 vs 264 vs 277).
    local byName = {}
    local mergedResult = {}
    for _, group in ipairs(result) do
        local key = tostring(group.name or ""):lower()
        local existing = byName[key]
        if not existing then
            byName[key] = group
            mergedResult[#mergedResult+1] = group
        else
            -- Check if the new group adds any slots missing from existing.
            local addsNewSlots = false
            for slotIndex = 1, #T.APPEARANCE_SET_SLOTS do
                if (existing.fullItems[slotIndex] or 0) == 0 and (group.fullItems[slotIndex] or 0) ~= 0 then
                    addsNewSlots = true
                    break
                end
            end

            if addsNewSlots then
                -- Case 1: complement merge — union fullItems, unlockedItems, counts.
                for slotIndex = 1, #T.APPEARANCE_SET_SLOTS do
                    if (existing.fullItems[slotIndex] or 0) == 0 and (group.fullItems[slotIndex] or 0) ~= 0 then
                        existing.fullItems[slotIndex]       = group.fullItems[slotIndex]
                        existing.fullItemDisplay[slotIndex] = group.fullItemDisplay[slotIndex] or 0
                    end
                    if (existing.unlockedItems[slotIndex] or 0) == 0 and (group.unlockedItems[slotIndex] or 0) ~= 0 then
                        existing.unlockedItems[slotIndex] = group.unlockedItems[slotIndex]
                    end
                end
                local mergedUnlocked = 0
                for slotIndex = 1, #T.APPEARANCE_SET_SLOTS do
                    if (existing.unlockedItems[slotIndex] or 0) ~= 0 then
                        mergedUnlocked = mergedUnlocked + 1
                    end
                end
                existing.unlockedCount = mergedUnlocked
                existing.totalCount = math_max(existing.totalCount, group.totalCount)
            else
                -- Case 2 or 3: same slots.  Compare display IDs strictly:
                -- ALL shared slots must have identical display IDs to merge.
                -- Any mismatch → different color tier → keep separate.
                local compareCount = 0
                local mismatch     = false
                for slotIndex = 1, #T.APPEARANCE_SET_SLOTS do
                    local dispA = existing.fullItemDisplay[slotIndex] or 0
                    local dispB = group.fullItemDisplay[slotIndex]    or 0
                    if dispA ~= 0 and dispB ~= 0 then
                        compareCount = compareCount + 1
                        if dispA ~= dispB then mismatch = true; break end
                    end
                end
                local isSameVisual = compareCount > 0 and not mismatch

                if isSameVisual then
                    -- Case 2: same visual (spec variants within one ilvl tier).
                    -- Merge only the unlocked-item counts; keep existing fullItems.
                    for slotIndex = 1, #T.APPEARANCE_SET_SLOTS do
                        if (existing.unlockedItems[slotIndex] or 0) == 0 and (group.unlockedItems[slotIndex] or 0) ~= 0 then
                            existing.unlockedItems[slotIndex] = group.unlockedItems[slotIndex]
                        end
                    end
                    local mergedUnlocked = 0
                    for slotIndex = 1, #T.APPEARANCE_SET_SLOTS do
                        if (existing.unlockedItems[slotIndex] or 0) ~= 0 then
                            mergedUnlocked = mergedUnlocked + 1
                        end
                    end
                    existing.unlockedCount = mergedUnlocked
                    existing.totalCount    = math_max(existing.totalCount, group.totalCount)
                else
                    -- Case 3: different visual (distinct color tier).  Keep separate
                    -- under a unique key so further same-named groups don't falsely
                    -- match the existing entry.
                    local uniqueKey = key .. "\0" .. tostring(group.id)
                    byName[uniqueKey] = group
                    mergedResult[#mergedResult+1] = group
                end
            end
        end
    end

    -- Disambiguate entries that share the same base name.
    -- Prefer variantLabel (item-name suffix) when it uniquely identifies the group
    -- among all same-named groups; fall back to ilvl number when it doesn't.
    local nameCountMap  = {}
    local nameVariantCt = {}   -- name → { variantLabel → count }
    for _, group in ipairs(mergedResult) do
        local n  = tostring(group.name or "")
        local vl = group.variantLabel or ""
        nameCountMap[n]         = (nameCountMap[n] or 0) + 1
        nameVariantCt[n]        = nameVariantCt[n] or {}
        nameVariantCt[n][vl]    = (nameVariantCt[n][vl] or 0) + 1
    end
    for _, group in ipairs(mergedResult) do
        local n = tostring(group.name or "")
        if (nameCountMap[n] or 0) > 1 and not group.isVirtual then
            local vl         = group.variantLabel or ""
            local vlIsUnique = vl ~= "" and nameVariantCt[n] and (nameVariantCt[n][vl] or 0) <= 1
            if vlIsUnique then
                group.name = n .. " (" .. vl .. ")"
            elseif (group.ilvl or 0) > 0 then
                -- Fallback: ilvl number distinguishes tiers with identical piece names
                -- (e.g. "Sanctified Frost Witch's" at 264 vs 277).
                group.name = n .. " (" .. tostring(group.ilvl) .. ")"
            elseif vl ~= "" then
                group.name = n .. " (" .. vl .. ")"
            end
        end
    end

    -- Display-signature merge (third pass): collapse groups that are visually
    -- identical into a single entry regardless of name.  This combines e.g.
    -- "Gladiator's Linked", "Gladiator's Mail", and "Gladiator's Ringmail"
    -- (shaman S1 PvP sets share the same recolor across specs) or seasonal
    -- equivalents that share appearances across many PvP sets.
    --
    -- Match rule: two groups are the SAME visual when every slot that has a
    -- non-zero display ID in BOTH groups has the same display ID (no
    -- mismatches on the overlap) and the overlap is non-empty.  Slots present
    -- in only one group are allowed — they extend the canonical group's
    -- coverage (complement merge).  Any mismatch on an overlapping slot means
    -- a different color tier and the groups stay separate.
    --
    -- O(n*k) where k = number of already-seen canonical groups.  n is small
    -- per account (usually <200), so this is fine.
    local sigResult = {}
    for _, group in ipairs(mergedResult) do
        local hasDisplay = false
        for i = 1, #T.APPEARANCE_SET_SLOTS do
            if (group.fullItemDisplay[i] or 0) ~= 0 then hasDisplay = true; break end
        end
        local mergedInto = nil
        if hasDisplay then
            for idx, existing in ipairs(sigResult) do
                local existingHasDisplay = false
                for si = 1, #T.APPEARANCE_SET_SLOTS do
                    if (existing.fullItemDisplay[si] or 0) ~= 0 then existingHasDisplay = true; break end
                end
                if existingHasDisplay then
                    local overlap, mismatch = 0, false
                    for si = 1, #T.APPEARANCE_SET_SLOTS do
                        local a = existing.fullItemDisplay[si] or 0
                        local b = group.fullItemDisplay[si]    or 0
                        if a ~= 0 and b ~= 0 then
                            overlap = overlap + 1
                            if a ~= b then mismatch = true; break end
                        end
                    end
                    if overlap > 0 and not mismatch then
                        -- Prefer non-virtual canonical; if both same kind, lower id wins.
                        local swap = false
                        if existing.isVirtual and not group.isVirtual then
                            swap = true
                        elseif existing.isVirtual == group.isVirtual
                           and (tonumber(group.id) or 0) < (tonumber(existing.id) or 0) then
                            swap = true
                        end
                        if swap then
                            sigResult[idx] = group
                            group, existing = existing, group
                        end
                        -- Complement merge: fill any slots existing lacks.
                        for si = 1, #T.APPEARANCE_SET_SLOTS do
                            if (existing.fullItems[si] or 0) == 0 and (group.fullItems[si] or 0) ~= 0 then
                                existing.fullItems[si]       = group.fullItems[si]
                                existing.fullItemDisplay[si] = group.fullItemDisplay[si] or 0
                            end
                            if (existing.unlockedItems[si] or 0) == 0 and (group.unlockedItems[si] or 0) ~= 0 then
                                existing.unlockedItems[si] = group.unlockedItems[si]
                            end
                        end
                        local uc = 0
                        for si = 1, #T.APPEARANCE_SET_SLOTS do
                            if (existing.unlockedItems[si] or 0) ~= 0 then uc = uc + 1 end
                        end
                        existing.unlockedCount = uc
                        existing.totalCount    = math_max(existing.totalCount, group.totalCount)
                        -- If we absorbed a real itemset into what was a virtual
                        -- canonical (or vice versa), the winning side's flags
                        -- stay — but mark hasExactTotal if either side had it.
                        if group.hasExactTotal then existing.hasExactTotal = true end
                        -- Shorten display name to common word prefix.
                        local common = DeriveItemSetName({existing.name, group.name})
                        if common ~= "" and common ~= "Unnamed Set" then
                            existing.name = common
                        end
                        mergedInto = existing
                        break
                    end
                end
            end
        end
        if not mergedInto then
            sigResult[#sigResult+1] = group
        end
    end
    mergedResult = sigResult

    -- Word-prefix merge (fourth pass): collapse groups whose .name is a strict
    -- word-prefix of another group's name.  Handles PvP recolor sets where
    -- different armor-type variants share the same visual (shaman S1
    -- "Gladiator's Linked" + "Gladiator's Mail" sig-merged to "Gladiator's";
    -- "Gladiator's Ringmail" survives because its displayIDs may differ
    -- slightly in the DB).  User intent: one catalog entry per tier name.
    --
    -- Tier-disambiguated names are immune: "Frost Witch's (251)" is not a
    -- word-prefix of "Frost Witch's (264)".  Seasonal tiers also safe:
    -- "Gladiator's" is not a word-prefix of "Merciless Gladiator's".  Virtual
    -- groups stay separate.
    local function wordCount(s)
        local n = 0
        for _ in tostring(s or ""):gmatch("%S+") do n = n + 1 end
        return n
    end
    local function isWordPrefix(short, long)
        if short == "" or long == "" or short == long then return false end
        if short:sub(-1) == ")" or long:sub(1, #short + 1) ~= short .. " " then return false end
        return true
    end
    -- Sort canonical candidates (short names) first so they absorb longer ones.
    -- Include virtual groups: a real itemset named "Gladiator's" should absorb
    -- a virtual "Gladiator's Ringmail" group (items with itemset=0 grouped by
    -- name prefix) that shares the tier's visual family.
    local prefixPool = {}
    for _, g in ipairs(mergedResult) do
        prefixPool[#prefixPool + 1] = g
    end
    tsort(prefixPool, function(a, b)
        local wa, wb = wordCount(a.name), wordCount(b.name)
        if wa ~= wb then return wa < wb end
        -- Prefer real itemsets as canonical when word-count tied.
        if a.isVirtual ~= b.isVirtual then return not a.isVirtual end
        return tostring(a.name) < tostring(b.name)
    end)
    local absorbed = {}
    for i = 1, #prefixPool do
        local longer = prefixPool[i]
        if not absorbed[longer] then
            for j = 1, i - 1 do
                local shorter = prefixPool[j]
                if not absorbed[shorter] and isWordPrefix(shorter.name, longer.name) then
                    -- Merge longer into shorter.
                    for si = 1, #T.APPEARANCE_SET_SLOTS do
                        if (shorter.fullItems[si] or 0) == 0 and (longer.fullItems[si] or 0) ~= 0 then
                            shorter.fullItems[si]       = longer.fullItems[si]
                            shorter.fullItemDisplay[si] = longer.fullItemDisplay[si] or 0
                        end
                        if (shorter.unlockedItems[si] or 0) == 0 and (longer.unlockedItems[si] or 0) ~= 0 then
                            shorter.unlockedItems[si] = longer.unlockedItems[si]
                        end
                    end
                    local uc = 0
                    for si = 1, #T.APPEARANCE_SET_SLOTS do
                        if (shorter.unlockedItems[si] or 0) ~= 0 then uc = uc + 1 end
                    end
                    shorter.unlockedCount = uc
                    shorter.totalCount    = math_max(shorter.totalCount, longer.totalCount)
                    if longer.hasExactTotal then shorter.hasExactTotal = true end
                    -- If either side is a real itemset, the merged entry must
                    -- present as non-virtual so it uses the (X/Y) display
                    -- format and skips the virtual-only minUnlocks=3 filter.
                    if not longer.isVirtual then
                        shorter.isVirtual = false
                        if (tonumber(shorter.id) or 0) == 0 or shorter.isVirtual == nil then
                            shorter.id = longer.id
                        end
                        if (longer.allowableClass or -1) ~= -1 then
                            shorter.allowableClass = longer.allowableClass
                        end
                    end
                    absorbed[longer] = true
                    break
                end
            end
        end
    end
    if next(absorbed) then
        local kept = {}
        for _, g in ipairs(mergedResult) do
            if not absorbed[g] then kept[#kept + 1] = g end
        end
        mergedResult = kept
    end

    -- Spec-variant merge (fifth pass): collapse groups that share the same
    -- name AND the same ilvl into a single entry, even when their visuals
    -- differ.  Real bug case: druid T7.10 raid "Heroes' Dreamwalker" exists
    -- as three distinct itemsets (Resto / Feral / Balance) — same tier name,
    -- same ilvl, different recolors per spec.  Without this pass the catalog
    -- shows the same name three times (e.g. 5/5, 4/5, 1/5).  Color-tier
    -- variants with DIFFERENT ilvls (Frost Witch's 251 vs 264 vs 277) are
    -- preserved as separate entries because the (name, ilvl) keys differ.
    --
    -- Canonical selection: prefer the group with the highest unlockedCount so
    -- the preview model shows the most-complete visual.  Ties broken by lowest
    -- id for stability.  Slot union semantics: a slot is "unlocked" if ANY of
    -- the merged groups had an unlock for that slot, so unlockedCount becomes
    -- the count of distinct unlocked slot indices across all variants.
    do
        local buckets = {}  -- key = name .. "\0" .. ilvl  → array of groups
        for _, g in ipairs(mergedResult) do
            if not g.isVirtual then
                local key = tostring(g.name or "") .. "\0" .. tostring(g.ilvl or 0)
                local b = buckets[key]
                if not b then b = {}; buckets[key] = b end
                b[#b + 1] = g
            end
        end
        local absorbedSV = {}
        for _, bucket in pairs(buckets) do
            if #bucket > 1 then
                tsort(bucket, function(a, b)
                    if (a.unlockedCount or 0) ~= (b.unlockedCount or 0) then
                        return (a.unlockedCount or 0) > (b.unlockedCount or 0)
                    end
                    return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
                end)
                local canonical = bucket[1]
                for i = 2, #bucket do
                    local other = bucket[i]
                    for si = 1, #T.APPEARANCE_SET_SLOTS do
                        -- Only union the unlocked slot indices.  Do NOT touch
                        -- canonical.fullItems / fullItemDisplay so the preview
                        -- model keeps showing one consistent visual variant
                        -- (the one with the most unlocks).
                        if (canonical.unlockedItems[si] or 0) == 0 and (other.unlockedItems[si] or 0) ~= 0 then
                            canonical.unlockedItems[si] = other.unlockedItems[si]
                        end
                    end
                    canonical.totalCount = math_max(canonical.totalCount, other.totalCount)
                    if other.hasExactTotal then canonical.hasExactTotal = true end
                    absorbedSV[other] = true
                end
                local uc = 0
                for si = 1, #T.APPEARANCE_SET_SLOTS do
                    if (canonical.unlockedItems[si] or 0) ~= 0 then uc = uc + 1 end
                end
                canonical.unlockedCount = uc
            end
        end
        if next(absorbedSV) then
            local kept = {}
            for _, g in ipairs(mergedResult) do
                if not absorbedSV[g] then kept[#kept + 1] = g end
            end
            mergedResult = kept
        end
    end

    -- Apply minimum-unlock threshold and build display names on the merged set.
    -- seededTier groups (auto-added empty tier variants) are always shown so the
    -- player can see every visual variant of an itemset they have any unlocks in.
    local finalResult = {}
    for _, group in ipairs(mergedResult) do
        local minUnlocks = group.isVirtual and 3 or 1
        if group.seededTier or group.unlockedCount >= minUnlocks then
            group.displayName = (group.isVirtual and not group.hasExactTotal)
                and string_format("%s (%d предм.)", group.name, group.unlockedCount)
                or  string_format("%s (%d/%d)", group.name, group.unlockedCount, group.totalCount)
            finalResult[#finalResult+1] = group
        end
    end

    tsort(finalResult, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)

    T.ACCOUNT_ITEM_SET_CATALOG_CACHE[accountGUID] = finalResult
    return finalResult
end

local function PackItemIdList(itemIds)
    -- Compact comma-separated representation.  AIO encodes one string with ~6×
    -- less overhead than a 14-element table of numbers (most slots are 0).
    -- The client's deserializePackedItemIdList already accepts both formats.
    local n = #T.APPEARANCE_SET_SLOTS
    local parts = {}
    local lastNonZero = 0
    for index = 1, n do
        local v = tonumber(itemIds and itemIds[index]) or 0
        parts[index] = v
        if v ~= 0 then lastNonZero = index end
    end
    -- Trim trailing zeros to shrink payload further; client pads back to slot
    -- count automatically.
    if lastNonZero == 0 then
        return ""
    end
    local out = {}
    for i = 1, lastNonZero do
        out[i] = tostring(parts[i])
    end
    return tconcat(out, ",")
end

local function BuildAccountItemSetCatalogTransport(accountGUID)
    accountGUID = tonumber(accountGUID)
    if not accountGUID then
        return {}
    end

    local cachedCatalog = T.ACCOUNT_ITEM_SET_CATALOG_TRANSPORT_CACHE[accountGUID]
    if cachedCatalog then
        return cachedCatalog
    end

    local packedCatalog = {}
    for _, setData in ipairs(BuildAccountItemSetCatalog(accountGUID)) do
        packedCatalog[#packedCatalog + 1] = {
            tonumber(setData.id) or 0,
            tostring(setData.name or ""),
            tonumber(setData.unlockedCount) or 0,
            tonumber(setData.totalCount) or 0,
            setData.hasExactTotal == false and 0 or 1,
            PackItemIdList(setData.fullItems),
            PackItemIdList(setData.unlockedItems),
            tonumber(setData.allowableClass) or -1,
        }
    end

    T.ACCOUNT_ITEM_SET_CATALOG_TRANSPORT_CACHE[accountGUID] = packedCatalog
    return packedCatalog
end

local function CalculateSlot(slot)
    if slot == 0 then slot = 1 elseif slot >= 2 then slot = slot + 1 end
    return CALC + (slot * 2)
end

T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT = {
    [283] = 0,
    [287] = 2,
    [289] = 3,
    [291] = 4,
    [293] = 5,
    [295] = 6,
    [297] = 7,
    [299] = 8,
    [301] = 9,
    [311] = 14,
    [313] = 15,
    [315] = 16,
    [317] = 17,
    [319] = 18,
}

T.EQUIPMENT_SLOT_TO_VISIBLE_SLOT = {
    [0] = 283,
    [2] = 287,
    [3] = 289,
    [4] = 291,
    [5] = 293,
    [6] = 295,
    [7] = 297,
    [8] = 299,
    [9] = 301,
    [14] = 311,
    [15] = 313,
    [16] = 315,
    [17] = 317,
    [18] = 319,
}

T.PLAYER_EVENT_ON_AFTER_SET_VISIBLE_ITEM_SLOT = 74

local function WriteVisibleItemField(player, slot, value)
    if not player then
        return false
    end

    slot = NormalizeVisibleSlot(slot)
    if not slot then
        return false
    end

    value = tonumber(value) or 0

    -- Always use SetUInt32Value to ensure the update-field is marked dirty and
    -- the change reaches the client.  UpdateUInt32Value (if it exists) is called
    -- afterwards as a belt-and-suspenders forced refresh, but never as the sole
    -- mechanism — on some builds it completes without error yet does not
    -- actually propagate the visual change.
    player:SetUInt32Value(slot, value)

    if type(player.UpdateUInt32Value) == "function" then
        pcall(player.UpdateUInt32Value, player, slot, value)
    end

    return true
end

-- Sets the PERM-enchant visual (low uint16) of PLAYER_VISIBLE_ITEM_X_ENCHANTMENT.
-- Preserves the high uint16 (temp enchant / random-property).  This must use
-- SetUInt16Value(field, 0, enchantId): the Eluna weapon-visual reference script
-- writes this exact half-field, and some cores do not propagate the visual when
-- the packed uint32 is written directly.
local function SetEnchantVisual(player, fieldIndex, enchantId)
    enchantId = math.min(tonumber(enchantId) or 0, 65535)
    if type(player.SetUInt16Value) == "function" then
        player:SetUInt16Value(fieldIndex, 0, enchantId)
    else
        local raw     = player:GetUInt32Value(fieldIndex)
        local upper   = raw - (raw % 65536)      -- preserve high uint16
        local newVal  = upper + enchantId
        player:SetUInt32Value(fieldIndex, newVal)
        if type(player.UpdateUInt32Value) == "function" then
            pcall(player.UpdateUInt32Value, player, fieldIndex, newVal)
        end
    end
end

-- Force-clear BOTH halves of the enchant-visual field.  Use for explicit
-- "Hide" (enchant_id = 0) where the user wants the weapon glow to fully
-- disappear, including any upper-16 temp-imbue visuals (Windfury /
-- Flametongue / Rockbiter / Reforger temp-slot enchants / Poisons /
-- sharpening stones / oils).  SetEnchantVisual intentionally preserves the
-- upper 16 so Revert/Clear paths don't nuke the player's active imbue glow,
-- but for Hide we want the opposite — wipe everything.
local function HideEnchantVisual(player, fieldIndex)
    if type(player.SetUInt16Value) == "function" then
        player:SetUInt16Value(fieldIndex, 0, 0)
        player:SetUInt16Value(fieldIndex, 1, 0)
    else
        player:SetUInt32Value(fieldIndex, 0)
        if type(player.UpdateUInt32Value) == "function" then
            pcall(player.UpdateUInt32Value, player, fieldIndex, 0)
        end
    end
end

local function SetVisibleItemValue(player, slot, value)
    if not player then
        return
    end

    slot = NormalizeVisibleSlot(slot)
    if not slot then
        return
    end

    local equipmentSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slot]
    if equipmentSlot ~= nil and type(player.SetVisibleItemSlot) == "function" and type(player.GetItemByPos) == "function" then
        local ok, equippedItem = pcall(player.GetItemByPos, player, 255, equipmentSlot)
        if ok then
            pcall(player.SetVisibleItemSlot, player, equipmentSlot, equippedItem)
        end
    end

    WriteVisibleItemField(player, slot, value)
end

local function Transmog_OnAfterSetVisibleItemSlot(event, player, equipmentSlot, item)
    if not player then
        return
    end

    local equipmentSlotNum = tonumber(equipmentSlot)
    local visibleSlot = T.EQUIPMENT_SLOT_TO_VISIBLE_SLOT[equipmentSlotNum]
    if not visibleSlot then
        return
    end

    -- Slot was emptied (item is nil): clear the visual and do not restore the
    -- stored transmog appearance onto an empty slot.  The DB row is preserved
    -- so the transmog restores automatically the next time the player equips
    -- an item in this slot (via the transmog load / equip path).
    if not item then
        WriteVisibleItemField(player, visibleSlot, 0)
        if visibleSlot == T.SLOT_MAINHAND or visibleSlot == T.SLOT_OFFHAND then
            local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipmentSlotNum * 2)
            HideEnchantVisual(player, fieldIndex)
        end
        return
    end

    local playerGUID = player:GetGUIDLow()

    local transmog = CharDBQuery(string_format(
        "SELECT item FROM character_transmog WHERE player_guid = %d AND slot = %d AND item IS NOT NULL LIMIT 1",
        playerGUID, visibleSlot
    ))
    if transmog then
        local transmogItem = tonumber(transmog:GetUInt32(0)) or 0
        WriteVisibleItemField(player, visibleSlot, transmogItem)
    end

    -- For weapon slots, re-apply the stored enchant visual (including enchant_id = 0
    -- which means "hidden").  This runs AFTER the core has already written the natural
    -- enchant from the item into the visible field, so our value always wins.
    if visibleSlot == T.SLOT_MAINHAND or visibleSlot == T.SLOT_OFFHAND then
        local illRow = CharDBQuery(string_format(
            "SELECT enchant_id FROM character_illusion WHERE player_guid = %d AND slot_id = %d LIMIT 1",
            playerGUID, visibleSlot
        ))
        if illRow then
            local enchantId = tonumber(illRow:GetUInt32(0))
            if enchantId ~= nil then
                local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipmentSlotNum * 2)
                if enchantId == 0 then
                    HideEnchantVisual(player, fieldIndex)
                else
                    SetEnchantVisual(player, fieldIndex, enchantId)
                end
            end
        end
    end
end

local function InitializePlayerTransmog(playerGUID)
    local values = {}
    for _, slot in ipairs(T.VISIBLE_SLOTS) do
        tinsert(values, string_format("(%d, %d, NULL, 0)", playerGUID, slot))
    end
    CharDBQuery("INSERT IGNORE INTO character_transmog (player_guid, slot, item, real_item) VALUES " .. tconcat(values, ", "))
end

local BuildAppearanceBuddyItemLink
local BuildAppearanceBuddyItemLinkFromTemplate

local function GetCompatibleInventoryTypeCsv(inventoryType)
    inventoryType = tonumber(inventoryType)
    if not inventoryType or inventoryType <= 0 then
        return nil
    end
    local compatibleTypes, seenTypes = {}, {}
    for _, allowedInventoryTypes in pairs(T.SLOT_INVENTORY_TYPES or {}) do
        if allowedInventoryTypes[inventoryType] then
            for invType in pairs(allowedInventoryTypes) do
                if not seenTypes[invType] then
                    seenTypes[invType] = true
                    compatibleTypes[#compatibleTypes + 1] = invType
                end
            end
        end
    end
    if #compatibleTypes == 0 then
        compatibleTypes[1] = inventoryType
    end
    table.sort(compatibleTypes)
    return tconcat(compatibleTypes, ",")
end

local function AccountHasAppearance(accountGUID, displayId, inventoryType)
    accountGUID = tonumber(accountGUID)
    displayId = tonumber(displayId)
    local compatibleTypesCsv = GetCompatibleInventoryTypeCsv(inventoryType)
    if not accountGUID or not displayId or displayId <= 0 or not compatibleTypesCsv then
        return false
    end
    return AuthDBQuery(string_format(
        "SELECT 1 FROM account_transmog WHERE account_id = %d AND display_id = %d AND inventory_type IN (%s) LIMIT 1",
        accountGUID, displayId, compatibleTypesCsv
    )) ~= nil
end

-- Returns the player-locale name for an item, falling back to defaultName.
-- Queries locales_item in the world DB using the player's client locale index.
--local function GetLocalizedItemName(player, itemId, defaultName)
--    if not player or not itemId then return defaultName end
--    local localeIdx = player.GetDbLocaleIndex and player:GetDbLocaleIndex() or 0
--    if type(localeIdx) ~= "number" or localeIdx <= 0 then return defaultName end
--    local col = "name_loc" .. math_floor(localeIdx)
--    local ok, result = pcall(WorldDBQuery, string_format(
--        "SELECT `%s` FROM locales_item WHERE entry = %d LIMIT 1", col, tonumber(itemId) or 0))
--    if ok and result then
--        local localName = result:GetString(0)
--        if localName and localName ~= "" then return localName end
--    end
--    return defaultName
--end

local function AddTransmogToAccount(player, itemTemplate)
    local displayId = itemTemplate:GetDisplayId()
    if not displayId or displayId <= 0 then return end
    local accountGUID = player:GetAccountId()
    local itemId = itemTemplate:GetItemId()
    local inventoryType = itemTemplate:GetInventoryType()
    local alreadyUnlocked = AccountHasAppearance(accountGUID, displayId, inventoryType)
    if alreadyUnlocked then
        return
    end
    local defaultName = itemTemplate:GetName()
    AuthDBQuery(string_format(
        "INSERT IGNORE INTO account_transmog (account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES (%d, %d, %d, %d, '%s')",
        accountGUID, itemId, displayId, inventoryType, EscapeString(defaultName)
    ))
    InvalidateAccountCaches(accountGUID)
    if player.SendBroadcastMessage then
        local quality = 1
        if itemTemplate.GetQuality then
            local okQ, q = pcall(itemTemplate.GetQuality, itemTemplate)
            if okQ and q ~= nil then quality = tonumber(q) or quality end
        end
        --local localName = GetLocalizedItemName(player, itemId, defaultName)
        player:SendBroadcastMessage(string_format(
            "|cff6ff98f[AppearanceBuddy]|r Открыт новый облик: %s",
            BuildAppearanceBuddyItemLink(itemId, localName, quality)))
    end
    -- Immediately push the updated unlock list to the client so the bag/tooltip
    -- border and "not yet collected" message reflect the new state without
    -- requiring a relog.  InvalidateAccountCaches above ensures the next
    -- GetAccountAppearanceCache call rebuilds from DB and includes this item.
    TransmogHandlers.GetAllUnlockedItemIds(player)
end

local function IsTransmoggableItem(class, inventoryType)
    return (class == 2 or class == 4) and not T.UNUSABLE_INVENTORY_TYPES[inventoryType]
end

BuildAppearanceBuddyItemLink = function(itemId, itemName, quality)
    itemId = tonumber(itemId) or 0
    if itemId <= 0 then return tostring(itemName or "Unknown Item") end
    local color = T.ITEM_QUALITY_LINK_COLORS[tonumber(quality) or 1] or T.ITEM_QUALITY_LINK_COLORS[1]
    local name = tostring(itemName or ("Item #" .. itemId))
    return string_format("|c%s|HABappearance:%d|h[%s]|h|r", color, itemId, name)
end

BuildAppearanceBuddyItemLinkFromTemplate = function(itemTemplate)
    if not itemTemplate then return "Unknown Item" end
    local itemId = itemTemplate:GetItemId()
    local name = itemTemplate:GetName()
    local quality = 1
    if itemTemplate.GetQuality then
        local ok, q = pcall(itemTemplate.GetQuality, itemTemplate)
        if ok and q ~= nil then quality = tonumber(q) or quality end
    end
    return BuildAppearanceBuddyItemLink(itemId, name, quality)
end

-- Returns true when the player is permitted to use the given item's appearance.
-- All checks are skipped when T.Blizzlike_Transmog = false (unrestricted mode).
-- When enabled, enforces:
--   1. AllowableClass bitmask (class-specific gear such as Lawbringer / Judgement).
--   2. Armor type proficiency (Cloth/Leather/Mail/Plate).
--   3. Weapon type proficiency.
--   4. Item required level (player must be high enough level to equip it).
--   5. Titan's Grip: 2H weapon in off-hand only for Warriors with the talent.
--   6. Slot must have an item equipped (Blizzlike: can't transmog an empty slot).
-- Slots excluded from rule 6: Shirt (289) and Tabard (319) are cosmetic-only
-- slots that may be pre-set without an item equipped.
local SLOT_REQUIRES_EQUIPPED_ITEM = {
    [283] = true, -- Head
    [287] = true, -- Shoulder
    [291] = true, -- Chest
    [293] = true, -- Waist
    [295] = true, -- Legs
    [297] = true, -- Feet
    [299] = true, -- Wrist
    [301] = true, -- Hands
    [311] = true, -- Back
    [313] = true, -- Main Hand
    [315] = true, -- Off-hand (also covered by OffhandSlotMissingEquipment)
    [317] = true, -- Ranged
}

-- Returns true when Blizzlike mode is on, the slot requires an equipped item,
-- and the player has nothing in that slot.
local function SlotMissingEquippedItem(player, slot)
    if not T.Blizzlike_Transmog then return false end
    if not SLOT_REQUIRES_EQUIPPED_ITEM[slot] then return false end
    local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slot]
    if equipSlot == nil then return false end
    if not player or not player.GetItemByPos then return false end
    local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
    return not (ok and item ~= nil)
end

local function PlayerCanTransmogItem(player, tpl, slot)
    if not T.Blizzlike_Transmog then return true end
    if SlotMissingEquippedItem(player, slot) then
        return false
    end
    if OffhandSlotMissingEquipment(player, slot) then
        return false
    end
    if not tpl then return true end

    local classId = player:GetClass() or 0

    -- AllowableClass: stored as signed int in MySQL; -1 / very large unsigned = all classes.
    -- Valid bitmasks are at most 2047 (all 10 playable classes combined).
    local allowableClass = tpl.allowableClass
    if allowableClass and allowableClass > 0 and allowableClass <= 2047 and classId > 0 then
        -- Bit for classId: class 1 -> bit 0 (value 1), class 2 -> bit 1 (value 2), etc.
        local classBit = 1
        for _ = 1, classId - 1 do classBit = classBit * 2 end
        if math_floor(allowableClass / classBit) % 2 ~= 1 then
            return false  -- item is class-restricted and this class is not in the mask
        end
    end

    -- Armor type proficiency (item class 4, subclass 1-4; subclass 0 = Misc, always allowed).
    if tpl.class == 4 and tpl.subclass >= 1 and tpl.subclass <= 4 then
        local maxArmor = T.CLASS_MAX_ARMOR_SUBCLASS[classId]
        if maxArmor and tpl.subclass > maxArmor then
            return false
        end
    end

    -- Shield proficiency (item class 4, subclass 6): only Warriors, Paladins, and Shamans.
    if tpl.class == 4 and tpl.subclass == 6 then
        if not T.CLASS_SHIELD_ALLOWED[classId] then
            return false
        end
    end

    -- Weapon type proficiency (item class 2).
    if tpl.class == 2 then
        local allowedWeapons = T.CLASS_ALLOWED_WEAPON_SUBCLASSES[classId]
        if allowedWeapons and not allowedWeapons[tpl.subclass] then
            return false
        end
    end

    -- Level requirement: cannot apply the appearance of an item the player cannot yet equip.
    if tpl.requiredLevel and tpl.requiredLevel > 0 and player:GetLevel() < tpl.requiredLevel then
        return false
    end

    -- AllowableRace restriction (signed int; -1 / very large unsigned = all races allowed).
    -- Valid race bitmasks for WotLK fit in ≤ 2047 (races 1-11, bit per race).
    local allowableRace = tpl.allowableRace
    if allowableRace and allowableRace > 0 and allowableRace <= 2047 then
        local raceId = player:GetRace() or 0
        if raceId > 0 then
            local raceBit = 1
            for _ = 1, raceId - 1 do raceBit = raceBit * 2 end
            if math_floor(allowableRace / raceBit) % 2 ~= 1 then
                return false  -- race-restricted item; player's race not in the mask
            end
        end
    end

    -- FlagsExtra faction check: bit 6 (0x40) = Horde-only, bit 7 (0x80) = Alliance-only.
    -- These flags gate certain NPC-reward and faction-specific appearances.
    if tpl.flagsExtra and tpl.flagsExtra > 0 then
        local hordeOnly    = (math_floor(tpl.flagsExtra / 64)  % 2) == 1
        local allianceOnly = (math_floor(tpl.flagsExtra / 128) % 2) == 1
        if hordeOnly or allianceOnly then
            local raceId = player:GetRace() or 0
            local playerFaction = T.RACE_ID_TO_FACTION[raceId]
            if hordeOnly    and playerFaction ~= "Horde"    then return false end
            if allianceOnly and playerFaction ~= "Alliance" then return false end
        end
    end

    -- Titan's Grip: a 2H weapon appearance in the off-hand slot requires the Warrior talent.
    if slot == T.SLOT_OFFHAND and tpl.inventoryType == 17 then
        if player:GetClass() ~= 1 or not player:HasSpell(T.TITANS_GRIP_SPELL_ID) then
            return false
        end
    end

    -- 2H weapon in the main-hand slot: only valid when the off-hand slot is
    -- empty, OR the player is a Warrior with Titan's Grip and the off-hand item
    -- is also a 2H weapon (true dual-2H stance).  A 2H appearance is never
    -- valid alongside a shield, an off-hand item, or a 1H weapon in off-hand.
    if slot == T.SLOT_MAINHAND and tpl.inventoryType == 17 then
        local offInvType = GetEquippedInventoryType(player, T.EQUIP_SLOT_OFFHAND)
        if offInvType ~= nil then  -- something is equipped in off-hand
            local isTGDual2H = (player:GetClass() == 1)
                and player:HasSpell(T.TITANS_GRIP_SPELL_ID)
                and (offInvType == 17)
            if not isTGDual2H then
                return false
            end
        end
    end

    return true
end

local function SafeGetItemByPos(player, bag, slot)
    if not player or not player.GetItemByPos then return nil end
    local ok, item = pcall(player.GetItemByPos, player, bag, slot)
    return ok and item or nil
end

local function GetBagSlotCount(player, bag)
    if not player then return 0 end
    if bag == 0 then
        if player.GetBagSize then
            local ok, size = pcall(player.GetBagSize, player, bag)
            if ok and size and size > 0 then return size end
        end
        return 16
    end
    local bagItem = SafeGetItemByPos(player, 255, bag)
    if not bagItem or not bagItem.GetBagSize then return 0 end
    local ok, size = pcall(bagItem.GetBagSize, bagItem)
    return (ok and size and size > 0) and size or 0
end

local function QueueTransmogToAccount(player, itemTemplate, values, seenItemIds, seenAppearances)
    if not player or not itemTemplate or type(values) ~= "table" then return false end
    local accountGUID = player:GetAccountId()
    local itemId = itemTemplate:GetItemId()
    local displayId = itemTemplate:GetDisplayId()
    local inventoryType = itemTemplate:GetInventoryType()
    if not displayId or displayId <= 0 then return false end
    if seenItemIds and seenItemIds[itemId] then return false end
    local appearanceKey = tostring(displayId) .. ":" .. tostring(GetCompatibleInventoryTypeCsv(inventoryType) or inventoryType)
    if seenAppearances and seenAppearances[appearanceKey] then return false end
    if AccountHasAppearance(accountGUID, displayId, inventoryType) then return false end
    values[#values+1] = string_format("(%d, %d, %d, %d, '%s')",
        accountGUID, itemId, displayId, inventoryType, EscapeString(itemTemplate:GetName()))
    if seenItemIds then seenItemIds[itemId] = true end
    if seenAppearances then seenAppearances[appearanceKey] = true end
    return true
end

-- Probe once at startup whether the vendor-refund and group-loot trade tables
-- exist in this schema.  AzerothCore treats a missing-table MySQL error as
-- fatal and aborts the worldserver, so we NEVER query a table that may not
-- exist.  information_schema.tables is always present and never crashes.
T.HAS_ITEM_REFUNDS_TABLE = CharDBQuery(
    "SELECT 1 FROM information_schema.tables"
    .. " WHERE table_schema = DATABASE() AND table_name = 'item_refunds' LIMIT 1"
) ~= nil

T.HAS_ITEM_SOULBOUND_TRADE_TABLE = CharDBQuery(
    "SELECT 1 FROM information_schema.tables"
    .. " WHERE table_schema = DATABASE() AND table_name = 'item_soulbound_trade_data' LIMIT 1"
) ~= nil

-- Returns true if the item is still inside a vendor-refund or group-loot trade window.
-- We must not unlock appearances during these windows to prevent buy->unlock->refund
-- or pass-around-the-group abuse.
local function IsItemInTradeableWindow(item)
    if not item or not item.GetGUIDLow then return false end
    local ok, guidLow = pcall(item.GetGUIDLow, item)
    if not ok or not guidLow or guidLow == 0 then return false end
    -- Vendor refund window: row present for the full 2-hour refundable period.
    if T.HAS_ITEM_REFUNDS_TABLE then
        local refundRow = CharDBQuery(string_format(
            "SELECT 1 FROM item_refunds WHERE item_guid = %d LIMIT 1", guidLow))
        if refundRow then return true end
    end
    -- Group-loot soulbound trade window: row present while item can still be traded.
    if T.HAS_ITEM_SOULBOUND_TRADE_TABLE then
        local tradeRow = CharDBQuery(string_format(
            "SELECT 1 FROM item_soulbound_trade_data WHERE itemGuid = %d LIMIT 1", guidLow))
        if tradeRow then return true end
    end
    return false
end

local function TryUnlockAppearanceFromItem(player, item, values, seenItemIds, seenAppearances)
    if not player or not item or not item.GetItemTemplate then return false end
    local okT, tpl = pcall(item.GetItemTemplate, item)
    if not okT or not tpl then return false end
    local okC, class = pcall(tpl.GetClass, tpl)
    local okI, invType = pcall(tpl.GetInventoryType, tpl)
    if not okC or not okI or not IsTransmoggableItem(class, invType) then return false end
    -- Block unlock while the item is still vendor-refundable or group-loot tradeable.
    -- Appearances are granted once these windows expire (caught by the next login scan).
    if IsItemInTradeableWindow(item) then return false end
    if values then return QueueTransmogToAccount(player, tpl, values, seenItemIds, seenAppearances) end
    AddTransmogToAccount(player, tpl)
    return true
end

local function IsProvisionTestEnabled(player)
    if not player or not player.GetGUIDLow then return false end
    return T.PROVISION_TEST_PLAYERS[player:GetGUIDLow()] == true
end

local function SendProvisionTestUnlock(player, itemId, itemName, quality)
    if player.SendBroadcastMessage then
        player:SendBroadcastMessage(string_format(
            "|cff6ff98f[AppearanceBuddy]|r [тест] Открыт новый облик: %s",
            BuildAppearanceBuddyItemLink(itemId, itemName, quality)))
    end
    TransmogHandlers.GetAllUnlockedItemIds(player)
end

-- Loot never grants appearances in the production system.  This hook exists
-- only for the GM provision-test command so admins can simulate a fresh
-- player's loot message without editing account_transmog.
local function TryUnlockAppearanceFromLoot(player, item)
    if not IsProvisionTestEnabled(player) then return end
    if not player or not item or not item.GetItemTemplate then return end
    local okT, tpl = pcall(item.GetItemTemplate, item)
    if not okT or not tpl then return end
    local okC, class = pcall(tpl.GetClass, tpl)
    local okI, invType = pcall(tpl.GetInventoryType, tpl)
    if not okC or not okI or not IsTransmoggableItem(class, invType) then return end
    local itemId = tpl:GetItemId()
    if not itemId or itemId <= 0 then return end
    local okQ, quality = pcall(tpl.GetQuality, tpl)
    SendProvisionTestUnlock(player, itemId, tpl:GetName(), okQ and quality or nil)
end

-- ---------------------------------------------------------------------------
-- Inventory scan (login/quest completion) — not the direct-loot path
-- ---------------------------------------------------------------------------

local function ScanPlayerInventoryForTransmogUnlocks(player)
    if not player then return end
    local accountGUID = player:GetAccountId()
    local values, seen, seenItemIds, seenAppearances = {}, {}, {}, {}
    local function visitItem(item)
        if not item then return end
        local guidLow = item.GetGUIDLow and item:GetGUIDLow() or nil
        if guidLow then
            if seen[guidLow] then return end
            seen[guidLow] = true
        end
        TryUnlockAppearanceFromItem(player, item, values, seenItemIds, seenAppearances)
    end

    for slot = 0, 18 do
        visitItem(SafeGetItemByPos(player, 255, slot))
    end

    if not T.LEARN_APPEARANCES_FROM_BAGS then
        if #values > 0 then
            AuthDBQuery(
                "INSERT IGNORE INTO account_transmog (account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES "
                .. tconcat(values, ", ")
            )
            InvalidateAccountCaches(accountGUID)
        end
        return
    end

    local backpackSlots = GetBagSlotCount(player, 0)
    for slot = 23, 22 + backpackSlots do
        visitItem(SafeGetItemByPos(player, 255, slot))
    end

    for bagSlot = 19, 22 do
        local bagItem = SafeGetItemByPos(player, 255, bagSlot)
        if bagItem then
            visitItem(bagItem)

            local bagSize = GetBagSlotCount(player, bagSlot)
            for slot = 0, bagSize - 1 do
                visitItem(SafeGetItemByPos(player, bagSlot, slot))
            end
        end
    end

    if #values > 0 then
        AuthDBQuery(
            "INSERT IGNORE INTO account_transmog (account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES "
            .. tconcat(values, ", ")
        )
        InvalidateAccountCaches(accountGUID)
    end
end

function Transmog_OnCharacterCreate(event, player)
    InitializePlayerTransmog(player:GetGUIDLow())
end

function Transmog_OnCharacterDelete(event, guid)
    guid = tonumber(guid) or 0
    if guid <= 0 then return end
    T.PROVISION_TEST_PLAYERS[guid] = nil
    CharDBQuery(string_format("DELETE FROM character_transmog   WHERE player_guid = %d", guid))
    CharDBQuery(string_format("DELETE FROM character_illusion   WHERE player_guid = %d", guid))
end

function Transmog_OnLootItem(event, player, item, count)
    if event ~= 51 and event ~= 52 and event ~= 53 and event ~= 56 then return end
    if not player or not item then return end
    if player.IsBot and player:IsBot() then return end
    TryUnlockAppearanceFromLoot(player, item)
end

function Transmog_OnEquipItem(event, player, item, bag, slot)
    if not T.LEARN_APPEARANCES_ON_EQUIP then return end
    if not player or not item then return end
    if player.IsBot and player:IsBot() then return end
    local itemTemplate = item:GetItemTemplate()
    if not itemTemplate then return end
    local playerGUID   = player:GetGUIDLow()
    local class        = item:GetClass()
    local inventoryType = itemTemplate:GetInventoryType()

    if not IsTransmoggableItem(class, inventoryType) then return end
    if IsItemInTradeableWindow(item) then
        if player.SendBroadcastMessage then
            player:SendBroadcastMessage("|cffffcc00[AppearanceBuddy]|r Облик откроется после окончания срока обмена/возврата предмета.")
        end
        return
    end

    AddTransmogToAccount(player, itemTemplate)

    local constSlot = CalculateSlot(slot)
    local itemId    = itemTemplate:GetItemId()

    CharDBQuery(string_format(
        "INSERT INTO character_transmog (`player_guid`, `slot`, `real_item`) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE real_item = VALUES(real_item)",
        playerGUID, constSlot, itemId
    ))

    local transmog = CharDBQuery(string_format(
        "SELECT item FROM character_transmog WHERE player_guid = %d AND slot = %d AND item IS NOT NULL",
        playerGUID, constSlot
    ))
    if not transmog then return end

    local transmogItem = tonumber(transmog:GetUInt32(0)) or 0
    -- Always apply the override: item > 0 = transmog, item == 0 = hidden.
    SetVisibleItemValue(player, constSlot, transmogItem)

    -- Re-apply any stored weapon illusion for this slot.
    if constSlot == T.SLOT_MAINHAND or constSlot == T.SLOT_OFFHAND then
        local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[constSlot]
        if equipSlot then
            -- Include enchant_id = 0 rows so equipping a weapon with "hide enchant" stored
            -- correctly zeroes out the visual field instead of showing the natural glow.
            local illRow = CharDBQuery(string_format(
                "SELECT enchant_id FROM character_illusion WHERE player_guid = %d AND slot_id = %d LIMIT 1",
                playerGUID, constSlot
            ))
            if illRow then
                local enchantId = tonumber(illRow:GetUInt32(0))
                if enchantId ~= nil then
                    local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)
                    SetEnchantVisual(player, fieldIndex, enchantId)
                end
            end
        end
    end
end

function TransmogHandlers.OnUnequipItem(player)
    local playerGUID = player:GetGUIDLow()

    local transmogs = CharDBQuery(string_format(
        "SELECT slot, item, real_item FROM character_transmog WHERE player_guid = %d AND item IS NOT NULL",
        playerGUID
    ))
    if not transmogs then return end

    repeat
        local slot = tonumber(transmogs:GetUInt32(0))
        -- Slot is empty: ensure the visible field stays at 0.  Do NOT push the
        -- stored transmog appearance back — an empty slot must show nothing.
        -- The DB row is kept intact so the transmog restores on re-equip.
        if slot and player:GetUInt32Value(slot) == 0 then
            WriteVisibleItemField(player, slot, 0)
        end
    until not transmogs:NextRow()
end

local ApplyStoredIllusions  -- forward declaration; defined near ApplyWeaponIllusion below

function Transmog_Load(player)
    local playerGUID = player:GetGUIDLow()

    -- Only fetch rows that have a transmog override (item IS NOT NULL).
    -- Also fetch real_item so we can restore it if the appearance is now restricted.
    local transmogs = CharDBQuery(string_format(
        "SELECT slot, item, real_item FROM character_transmog WHERE player_guid = %d AND item IS NOT NULL",
        playerGUID
    ))
    if transmogs then
        repeat
            local slot     = tonumber(transmogs:GetUInt32(0))
            local item     = tonumber(transmogs:GetUInt32(1)) or 0   -- 0 = hidden
            local realItem = tonumber(transmogs:GetUInt32(2)) or 0
            if slot then
                -- Before applying any visual, verify the equipment slot is actually
                -- occupied.  A stale DB row (e.g. the player unequipped the item in a
                -- previous session) must not paint the stored appearance onto an empty
                -- slot — that causes the character model to show the transmog item even
                -- though nothing is equipped there.  The DB row is preserved so the
                -- transmog restores automatically the next time the player equips.
                local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slot]
                local slotOccupied = false
                if equipSlot then
                    local ok, itm = pcall(function()
                        if player.GetEquippedItemBySlot then
                            return player:GetEquippedItemBySlot(equipSlot)
                        end
                        if player.GetItemByPos then
                            return player:GetItemByPos(255, equipSlot)
                        end
                    end)
                    slotOccupied = ok and itm ~= nil
                end

                if not slotOccupied then
                    -- Slot is empty: clear any stale visual field value.
                    WriteVisibleItemField(player, slot, 0)
                else
                    -- Retroactive blizzlike enforcement: strip appearances the player can no longer use.
                    local stripped = false
                    if item > 0 then
                        local tpl = GetItemTemplateInfo(item)
                        if not PlayerCanTransmogItem(player, tpl, slot) then
                            UpsertTransmogSlot(playerGUID, slot, nil, realItem)
                            SetVisibleItemValue(player, slot, realItem)
                            stripped = true
                        end
                    end
                    if not stripped then
                        SetVisibleItemValue(player, slot, item)
                    end
                end
            end
        until not transmogs:NextRow()
    end

    AIO.Handle(player, "Transmog", "LoadTransmogsAfterSave")

    -- NOTE: we used to auto-purge enchant_id = 0 rows for weapons with no
    -- perm enchant under the assumption that "Hide" on an unenchanted weapon
    -- was nonsensical.  That was wrong: Hide also suppresses the UPPER 16
    -- bits (Windfury / Flametongue / Rockbiter / Reforger temp-slot enchants
    -- / poisons / sharpening stones / oils).  Killing the row on every login
    -- silently defeated the user's explicit intent.  The row is now always
    -- respected and HideEnchantVisual zeroes both halves of the field.

    -- Re-apply weapon illusions after transmogs are loaded.
    ApplyStoredIllusions(player)

    -- NOTE: do NOT push SetStoredIllusions here from the live visible-enchant
    -- field.  That field's lower 16 bits hold the perm-enchant visual; the
    -- upper 16 bits hold temp-slot enchants (Reforger slot-1, Windfury,
    -- Flametongue, Poisons, etc.).  When the player has no perm enchant but
    -- DOES have a temp-slot enchant, the lower 16 are 0 — and pushing
    -- {slotId, 0} makes the client treat the slot as "explicitly hidden" and
    -- strip the natural glow in the preview.
    --
    -- The authoritative illusion sync happens in SetTransmogItemIds (and is
    -- triggered when the transmog tab opens or any state change occurs); that
    -- path correctly omits entries when no character_illusion DB row exists,
    -- so the client renders the natural state from SetUnit("player") and the
    -- temp-slot enchant glow is preserved.
end

local ScanCompletedQuestsForTransmogUnlocks

function TransmogHandlers.LoadPlayer(player)
    -- Playerbot characters have no real client session; skip all DB scanning
    -- and AIO calls so that mass bot initialisation (e.g. rndbot init) does
    -- not flood the world thread with thousands of synchronous DB queries.
    if player.IsBot and player:IsBot() then return end

    InitializePlayerTransmog(player:GetGUIDLow())

    ScanPlayerInventoryForTransmogUnlocks(player)
    Transmog_Load(player)
    TransmogHandlers.GetAllUnlockedItemIds(player)
    player:SetUInt32Value(147, 1)
    AIO.Handle(player, "Transmog", "TransmogCostInfo", T.transmog_cost, T.TRANSMOG_COST_PER_SLOT, T.TRANSMOG_RARITY_MULTIPLIER, T.Blizzlike_Transmog, player:IsGM(), T.allow_reset_all_transmog)

    local playerGUID = player:GetGUIDLow()
    local function runQuestBackfill()
        local p = player
        if GetPlayerByGUID then
            p = GetPlayerByGUID(playerGUID)
        end
        if not p then return end
        local added = ScanCompletedQuestsForTransmogUnlocks(p)
        if added and added > 0 then
            TransmogHandlers.GetAllUnlockedItemIds(p)
        end
    end

    if CreateLuaEvent then
        CreateLuaEvent(runQuestBackfill, 750, 1)
    else
        runQuestBackfill()
    end
end

function TransmogHandlers.GetTransmogCostInfo(player)
    AIO.Handle(player, "Transmog", "TransmogCostInfo", T.transmog_cost, T.TRANSMOG_COST_PER_SLOT, T.TRANSMOG_RARITY_MULTIPLIER, T.Blizzlike_Transmog, player:GetGMRank(), T.allow_reset_all_transmog)
end

-- ---------------------------------------------------------------------------
-- Set-share chat link broadcaster.
--
-- The client cannot embed a custom |HABset:..|h link directly in chat:
-- AzerothCore's hyperlink validator rejects it and the message is dropped
-- with "sent a message with an invalid link" in the server log.
--
-- Instead, the client's "Link Set" button sends the share code to this
-- handler, which fans the payload out to the appropriate audience over AIO.
-- Each recipient with the addon then prints the clickable link locally; the
-- server never has to parse or validate the |H link itself.
--
-- Inputs are length-capped and rate-limited per sender to prevent spam.
-- ---------------------------------------------------------------------------
local SET_LINK_BURST_LIMIT = 5
local SET_LINK_LOCKOUT_SECONDS = 10 * 60
local _setLinkState = {}     -- [playerGUIDLow] = { sent = count, lockedUntil = timestamp }

local function _setLinkNow()
    local now = os.time and tonumber(os.time()) or nil
    if now and now > 0 then
        return now
    end

    now = os.clock and tonumber(os.clock()) or nil
    if now and now >= 0 then
        return now
    end

    return nil
end

local function _setLinkBuildAudience(sender, chatType, target)
    local out = {}
    local senderGUID = sender:GetGUIDLow()
    local function add(p)
        if not p then return end
        if p:GetGUIDLow() == senderGUID then return end
        out[#out + 1] = p
    end

    if chatType == "SAY" then
        local nearby = sender.GetPlayersInRange and sender:GetPlayersInRange(25, 0, false) or nil
        if nearby then for _, p in ipairs(nearby) do add(p) end end
    elseif chatType == "YELL" then
        local nearby = sender.GetPlayersInRange and sender:GetPlayersInRange(300, 0, false) or nil
        if nearby then for _, p in ipairs(nearby) do add(p) end end
    elseif chatType == "PARTY" or chatType == "RAID"
        or chatType == "INSTANCE_CHAT" or chatType == "BATTLEGROUND" then
        local g = sender:GetGroup()
        if g then
            local mem = g.GetMembers and g:GetMembers() or nil
            if mem then for _, p in ipairs(mem) do add(p) end end
        end
    elseif chatType == "GUILD" or chatType == "OFFICER" then
        local guild = sender:GetGuild()
        if guild then
            local gid = guild.GetId and guild:GetId() or nil
            if gid then
                local all = GetPlayersInWorld and GetPlayersInWorld() or {}
                for _, p in ipairs(all) do
                    local pg = p.GetGuild and p:GetGuild() or nil
                    if pg and pg.GetId and pg:GetId() == gid then add(p) end
                end
            end
        end
    elseif chatType == "WHISPER" and target and target ~= "" then
        local p = GetPlayerByName and GetPlayerByName(target) or nil
        if p then add(p) end
    end

    return out
end

function TransmogHandlers.BroadcastSetLink(player, chatType, target, code, setName)
    if not player then return end
    chatType = type(chatType) == "string" and chatType:upper() or "SAY"
    target   = type(target)   == "string" and target  or ""
    code     = type(code)     == "string" and code    or ""
    setName  = type(setName)  == "string" and setName or "Set"

    -- Strict validation: code is a normal AB1 share string and the printable
    -- name is short. This stops spam-vector abuse via oversized payloads.
    if #code  > 1024 then return end
    if #setName > 64 then return end
    if code:sub(1, 4) ~= "AB1~" then return end

    local supported = {
        SAY = true, YELL = true, PARTY = true, RAID = true,
        INSTANCE_CHAT = true, BATTLEGROUND = true,
        GUILD = true, OFFICER = true, WHISPER = true,
    }
    if not supported[chatType] then return end

    -- Allow short bursts, then lock set-link broadcasts for a while.
    local now = _setLinkNow()
    local guidLow = player:GetGUIDLow()
    local state = _setLinkState[guidLow]
    if not state then
        state = { sent = 0, lockedUntil = 0 }
        _setLinkState[guidLow] = state
    end

    if now then
        local lockedUntil = tonumber(state.lockedUntil) or 0
        if lockedUntil > now then
            local remaining = math.ceil((lockedUntil - now) / 60)
            AIO.Handle(player, "Transmog", "ReceiveSetLinkError",
                string.format("Ссылки на комплекты заблокированы ещё на %d мин.",
                    remaining, remaining == 1 and "" or "s"))
            return
        elseif lockedUntil > 0 then
            state.sent = 0
            state.lockedUntil = 0
        end
    end

    local audience = _setLinkBuildAudience(player, chatType, target)
    local senderName = player:GetName() or "Unknown"

    -- Echo back to sender so they see exactly what recipients see.
    AIO.Handle(player, "Transmog", "ReceiveSetLink",
        senderName, chatType, code, setName, target, true)

    for _, p in ipairs(audience) do
        AIO.Handle(p, "Transmog", "ReceiveSetLink",
            senderName, chatType, code, setName, target, false)
    end

    state.sent = (tonumber(state.sent) or 0) + 1
    if now and state.sent >= SET_LINK_BURST_LIMIT then
        state.sent = 0
        state.lockedUntil = now + SET_LINK_LOCKOUT_SECONDS
    end
end

function TransmogHandlers.CopyTargetAppearanceSet(player, targetName)
    if not player then return end
    targetName = type(targetName) == "string" and targetName or ""
    if targetName == "" then
        AIO.Handle(player, "Transmog", "TargetAppearanceSetError", "No target selected.")
        return
    end

    local target = GetPlayerByName and GetPlayerByName(targetName) or nil
    if not target then
        AIO.Handle(player, "Transmog", "TargetAppearanceSetError", "Цель не в сети или не найдена.")
        return
    end
    if target:GetGUIDLow() == player:GetGUIDLow() then
        AIO.Handle(player, "Transmog", "TargetAppearanceSetError", "Выберите другого игрока, чтобы скопировать его облик.")
        return
    end

    local targetGUID = target:GetGUIDLow()
    local equippedBySlot = {}
    local function resolveEquippedId(equipSlot)
        local item
        local ok = pcall(function()
            if target.GetEquippedItemBySlot then
                item = target:GetEquippedItemBySlot(equipSlot)
            end
            if not item and target.GetItemByPos then
                item = target:GetItemByPos(255, equipSlot)
            end
        end)
        if not ok or not item then return 0 end

        local id
        pcall(function()
            if item.GetEntry then
                id = item:GetEntry()
            end
            if (not id or id == 0) and item.GetItemTemplate then
                local tpl = item:GetItemTemplate()
                if tpl and tpl.GetItemId then
                    id = tpl:GetItemId()
                end
            end
        end)
        return tonumber(id) or 0
    end

    for _, info in ipairs(T.APPEARANCE_SET_SLOTS) do
        local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[info.slot]
        equippedBySlot[info.slot] = equipSlot and resolveEquippedId(equipSlot) or 0
    end

    local storedBySlot = {}
    local transmogs = CharDBQuery(string_format(
        "SELECT slot, item FROM character_transmog WHERE player_guid = %d",
        targetGUID
    ))
    if transmogs then
        repeat
            local slot = NormalizeVisibleSlot(transmogs:GetUInt32(0))
            if slot then
                local rawItem = transmogs:GetString(1)
                if rawItem == nil or rawItem == "" or rawItem == "NULL" then
                    storedBySlot[slot] = nil
                else
                    storedBySlot[slot] = tonumber(rawItem) or 0
                end
            end
        until not transmogs:NextRow()
    end

    local items = {}
    for index, info in ipairs(T.APPEARANCE_SET_SLOTS) do
        local stored = storedBySlot[info.slot]
        if stored ~= nil then
            items[index] = stored
        else
            items[index] = equippedBySlot[info.slot] or 0
        end
    end

    local enchants = {0, 0}
    local illusions = CharDBQuery(string_format(
        "SELECT slot_id, enchant_id FROM character_illusion WHERE player_guid = %d AND slot_id IN (%d, %d)",
        targetGUID, T.SLOT_MAINHAND, T.SLOT_OFFHAND
    ))
    if illusions then
        repeat
            local slot = tonumber(illusions:GetUInt32(0))
            local enchantId = tonumber(illusions:GetUInt32(1)) or 0
            if slot == T.SLOT_MAINHAND then
                enchants[1] = enchantId
            elseif slot == T.SLOT_OFFHAND then
                enchants[2] = enchantId
            end
        until not illusions:NextRow()
    end

    local name = target:GetName() or targetName
    local classId = target:GetClass() or 0
    AIO.Handle(player, "Transmog", "ReceiveTargetAppearanceSet",
        name, items, enchants, classId)
end

-- Allows the client settings UI to toggle free transmogs at runtime.
-- Only takes effect for the current session; the default is set by
-- T.transmog_cost at the top of this file.
-- Restricted to GM rank 3+ to prevent players from making transmog free for everyone.
function TransmogHandlers.SetFreeTransmogs(player, free)
    if not player or player:GetGMRank() < 3 then return end
    T.transmog_cost = not free
    -- Broadcast the updated cost info back to all online players so their
    -- UI reflects the change immediately.
    local players = GetPlayersInWorld and GetPlayersInWorld() or {}
    for _, p in ipairs(players) do
        AIO.Handle(p, "Transmog", "TransmogCostInfo", T.transmog_cost, T.TRANSMOG_COST_PER_SLOT, T.TRANSMOG_RARITY_MULTIPLIER, T.Blizzlike_Transmog, p:GetGMRank(), T.allow_reset_all_transmog)
    end
end

function TransmogHandlers.GetDiagnostics(player)
    AIO.Handle(player, "Transmog", "Diagnostics", {
        scriptPath = T.TRANSMOG_SCRIPT_PATH,
        scriptRevision = T.TRANSMOG_SCRIPT_REVISION,
        hasSetTransmogItemIds = type(TransmogHandlers.SetTransmogItemIds) == "function",
        hasSetCurrentSlotItemPage = type(TransmogHandlers.SetCurrentSlotItemPage) == "function",
        hasSetCurrentSlotItemIds = type(TransmogHandlers.SetCurrentSlotItemIds) == "function",
        hasSetSearchCurrentSlotItemIds = type(TransmogHandlers.SetSearchCurrentSlotItemIds) == "function",
        hasApplyWeaponIllusion = type(TransmogHandlers.ApplyWeaponIllusion) == "function",
        hasApplyWeaponIllusionV2 = type(TransmogHandlers.ApplyWeaponIllusionV2) == "function",
        hasUnlockedItemSets = type(TransmogHandlers.GetUnlockedItemSets) == "function",
        hasGetAllUnlockedItemIds = type(TransmogHandlers.GetAllUnlockedItemIds) == "function",
        hasScanInventoryUnlocks = type(TransmogHandlers.ScanInventoryUnlocks) == "function",
    })
end

function TransmogHandlers.ScanInventoryUnlocks(player)
    ScanPlayerInventoryForTransmogUnlocks(player)
    -- Push the (possibly updated) unlocked list so the client can refresh
    -- bag borders and tooltips immediately instead of waiting for the 3-min poll.
    TransmogHandlers.GetAllUnlockedItemIds(player)
end

function TransmogHandlers.EquipTransmogItem(player, item, slot)
    local playerGUID = player:GetGUIDLow()
    local accountGUID = player:GetAccountId()
    slot = NormalizeVisibleSlot(slot)
    if not slot then return end
    item = item ~= nil and (tonumber(item) or 0) or nil

    -- Resolve the requested item to the player's actually-unlocked canonical
    -- item id BEFORE doing any blizzlike or cost work.  Without this:
    --   * a malicious client could apply any in-game appearance (the only
    --     ownership gate later is the upsert, which doesn't validate);
    --   * the cost charged could differ from what the client UI shows because
    --     the displayed itemId may be a non-canonical alias of an unlocked
    --     piece (rarity / required level can differ between aliases).
    -- Hide (item == 0) and Restore (item == nil) bypass this since they are
    -- always free and don't require ownership.
    local resolvedItemId = item
    if item and item > 0 then
        local unlocked = GetUnlockedAppearanceItemId(accountGUID, slot, item)
        if not unlocked then
            AIO.Handle(player, "Transmog", "TransmogError",
                "Этот облик у вас не открыт.")
            TransmogHandlers.SetTransmogItemIds(player)
            return
        end
        resolvedItemId = unlocked
    end

    -- Blizzlike equip restriction: reject appearances the player's class cannot use.
    if resolvedItemId and resolvedItemId > 0 then
        local tpl = GetItemTemplateInfo(resolvedItemId)
        if not PlayerCanTransmogItem(player, tpl, slot) then
            -- Give a specific message when the block is caused by a 2H appearance
            -- conflicting with an equipped off-hand item.
            local errMsg = "Ваш класс не может использовать этот тип предметов."
            if SlotMissingEquippedItem(player, slot) then
                errMsg = "Сначала наденьте предмет в эту ячейку."
            elseif OffhandSlotMissingEquipment(player, slot) then
                errMsg = "Сначала наденьте предмет для левой руки или щит."
            elseif tpl and tpl.class == 2 and tpl.inventoryType == 17 and slot == T.SLOT_MAINHAND then
                local offInvType = GetEquippedInventoryType(player, T.EQUIP_SLOT_OFFHAND)
                if offInvType ~= nil then
                    errMsg = "Облик двуручного оружия нельзя применить, пока в левой руке есть предмет, и нельзя наложить на одноручное оружие."
                end
            end
            AIO.Handle(player, "Transmog", "TransmogError", errMsg)
            -- Push the real server state so the client rolls back its optimistic update.
            TransmogHandlers.SetTransmogItemIds(player)
            return
        end
    end

    -- Charge gold when applying a transmog appearance (item > 0).
    --
    -- Skip charging when the slot is ALREADY transmogged to the same canonical
    -- appearance.  Without this guard, repeated Apply clicks (or AIO retries)
    -- would charge the player every time for zero visual change — a known
    -- exploit pattern and a UX wallet drain.  ApplyAppearanceSet already does
    -- this via GetAllStoredItemIds; mirror it here so single-slot Apply is
    -- consistent with Apply All.
    if T.transmog_cost and resolvedItemId and resolvedItemId > 0 then
        local currentItemId = GetAllStoredItemIds(playerGUID)[slot]
        if currentItemId ~= resolvedItemId then
            local costForItem = GetTransmogCostForItem(player, resolvedItemId)
            if costForItem > 0 then
                local currentMoney = player:GetCoinage()
                if currentMoney < costForItem then
                    AIO.Handle(player, "Transmog", "TransmogCostError", costForItem)
                    -- Resync client to actual server state so the model rolls back.
                    TransmogHandlers.SetTransmogItemIds(player)
                    return
                end
                player:ModifyMoney(-costForItem)
            end
        end
    end

    local oldItemId = GetStoredRealItemId(playerGUID, slot)
    UpsertTransmogSlot(playerGUID, slot, resolvedItemId, oldItemId)
    SetVisibleItemValue(player, slot, resolvedItemId == nil and oldItemId or resolvedItemId)
end

function TransmogHandlers.ApplyAppearanceSet(player, itemIds)
    if type(itemIds) ~= "table" then
        AIO.Handle(player, "Transmog", "AppearanceSetResult", 0, 0, "", 0)
        return
    end

    local playerGUID = player:GetGUIDLow()
    local accountGUID = player:GetAccountId()

    -- Pre-calculate chargeable slots (items being applied, not hidden/restored).
    -- Skip any slot whose appearance is already set to the target item so that
    -- the server charge matches exactly what the client cost display shows.
    -- Also skip slots that would be rejected by blizzlike equip restrictions.
    if T.transmog_cost then
        local currentItemIds = GetAllStoredItemIds(playerGUID)
        local totalCost = 0
        for index, info in ipairs(T.APPEARANCE_SET_SLOTS) do
            local requestedItemId = tonumber(itemIds[index]) or -1
            if requestedItemId > 0 then
                -- Use unlockedItemId for both the restriction check and the cost
                -- calculation so pre-calc and application phase are fully consistent.
                local unlockedItemId = GetUnlockedAppearanceItemId(accountGUID, info.slot, requestedItemId)
                -- Compare against the resolved canonical item, not the alias the
                -- client sent: an alias whose canonical is already applied must
                -- not be charged (otherwise repeated Apply on the same set
                -- would silently bill the player every click).
                if unlockedItemId
                    and currentItemIds[info.slot] ~= unlockedItemId
                    and PlayerCanTransmogItem(player, GetItemTemplateInfo(unlockedItemId), info.slot) then
                    totalCost = totalCost + GetTransmogCostForItem(player, unlockedItemId)
                end
            end
        end
        if totalCost > 0 then
            local currentMoney = player:GetCoinage()
            if currentMoney < totalCost then
                AIO.Handle(player, "Transmog", "TransmogCostError", totalCost)
                -- Resync the client to the real server state (while applyingAppearanceSet
                -- is still true on the client) so the left model rolls back correctly.
                TransmogHandlers.SetTransmogItemIds(player)
                AIO.Handle(player, "Transmog", "AppearanceSetResult", 0, 0, "", 0)
                return
            end
            player:ModifyMoney(-totalCost)
            -- Per-coin colouring matches the client formatCoin so the chat
            -- broadcast reads at a glance (yellow gold / silver / copper).
            player:SendBroadcastMessage(string_format(
                "|cffffd200[Трансмогрификация]|r Списано |cffffd700%dз|r |cffc7c7cf%dс|r |cffeda55f%dм|r за применение комплекта.",
                math_floor(totalCost / 10000),
                math_floor((totalCost % 10000) / 100),
                totalCost % 100))
        end
    end

    local appliedCount = 0
    local hiddenCount = 0
    local restoredCount = 0
    local missingSlots = {}
    local batchUpdates = {}

    local realItemIds = GetAllStoredRealItemIds(playerGUID)

    for index, info in ipairs(T.APPEARANCE_SET_SLOTS) do
        local requestedItemId = tonumber(itemIds[index]) or -1
        local realItemId = realItemIds[info.slot] or 0

        if requestedItemId < 0 then
            batchUpdates[#batchUpdates + 1] = {info.slot, nil, realItemId}
            SetVisibleItemValue(player, info.slot, realItemId)
            restoredCount = restoredCount + 1
        elseif requestedItemId == 0 then
            batchUpdates[#batchUpdates + 1] = {info.slot, 0, realItemId}
            SetVisibleItemValue(player, info.slot, 0)
            hiddenCount = hiddenCount + 1
        else
            local unlockedItemId = GetUnlockedAppearanceItemId(accountGUID, info.slot, requestedItemId)
            if unlockedItemId then
                if not PlayerCanTransmogItem(player, GetItemTemplateInfo(unlockedItemId), info.slot) then
                    tinsert(missingSlots, info.name)
                else
                    batchUpdates[#batchUpdates + 1] = {info.slot, unlockedItemId, realItemId}
                    SetVisibleItemValue(player, info.slot, unlockedItemId)
                    appliedCount = appliedCount + 1
                end
            else
                tinsert(missingSlots, info.name)
            end
        end
    end

    BatchUpsertTransmogSlots(playerGUID, batchUpdates)
    TransmogHandlers.SetTransmogItemIds(player)
    AIO.Handle(player, "Transmog", "AppearanceSetResult", appliedCount, hiddenCount, tconcat(missingSlots, ", "), restoredCount)
end

-- ---------------------------------------------------------------------------
-- GetUnlockedItemSets (rebuilt 2026-04-22)
--
-- Self-contained catalog builder.  Bypasses the legacy shared appearance
-- cache pipeline entirely so the client never gets trapped in a permanent
-- "Fetching..." state when a sub-step errors silently.
--
-- Caches:
--   * T.UNLOCKED_ITEM_SETS_CACHE[accountId]  full packed result; invalidated by
--                                            InvalidateAccountCaches() whenever
--                                            account_transmog mutates.
--   * T.ITEMSET_FULL_CACHE[itemsetId]        canonical fullItems / totalCount /
--                                            classMask / derived name.  Set
--                                            definitions are static so this is
--                                            populated once per itemset and
--                                            reused across all accounts.
--   * T.ITEM_TEMPLATE_CACHE[itemId]          shared with the rest of the script;
--                                            we hit this first to avoid extra
--                                            DB round-trips for unlocked items.
--
-- The handler ALWAYS responds (pcall-wrapped, sends `{}` on error) so the
-- client never times out.
-- ---------------------------------------------------------------------------
local function BuildUnlockedItemSetsTransport(accountGUID)
    local result = {}
    if accountGUID <= 0 then return result end

    -- Step 1: unlocked items for this account.  account_transmog has a unique
    -- key on (account_id, unlocked_item_id) so dedup is unnecessary here.
    local q = AuthDBQuery(string_format(
        "SELECT unlocked_item_id FROM account_transmog WHERE account_id = %d",
        accountGUID))
    if not q then return result end

    local unlockedIds = {}
    repeat
        local iid = tonumber(q:GetUInt32(0)) or 0
        if iid > 0 then unlockedIds[#unlockedIds + 1] = iid end
    until not q:NextRow()

    if #unlockedIds == 0 then return result end

    -- Step 2: resolve item_template for each unlocked item.  Hit the shared
    -- cache first; only query the DB for entries we have not seen yet.
    local CHUNK = 500
    local missing = {}
    for _, iid in ipairs(unlockedIds) do
        local cached = T.ITEM_TEMPLATE_CACHE[iid]
        if cached == nil then
            missing[#missing + 1] = iid
        end
    end
    if #missing > 0 then
        for s = 1, #missing, CHUNK do
            local e = math_min(s + CHUNK - 1, #missing)
            local list = {}
            for i = s, e do list[#list + 1] = missing[i] end
            local rows = WorldDBQuery(string_format(
                "SELECT entry, itemset, InventoryType, name, displayid, class, subclass, Quality, RequiredLevel, AllowableClass, ItemLevel FROM item_template WHERE entry IN (%s)",
                tconcat(list, ",")))
            if rows then
                repeat
                    local entry = tonumber(rows:GetUInt32(0)) or 0
                    if entry > 0 then
                        T.ITEM_TEMPLATE_CACHE[entry] = {
                            itemset       = tonumber(rows:GetUInt32(1)) or 0,
                            inventoryType = tonumber(rows:GetUInt32(2)) or 0,
                            name          = rows:GetString(3) or "",
                            displayId     = tonumber(rows:GetUInt32(4)) or 0,
                            class         = tonumber(rows:GetUInt32(5)) or 0,
                            subclass      = tonumber(rows:GetUInt32(6)) or 0,
                            quality       = tonumber(rows:GetUInt32(7)) or 0,
                            requiredLevel = tonumber(rows:GetUInt32(8)) or 0,
                            allowableClass= tonumber(rows:GetInt32(9)),
                            itemLevel     = tonumber(rows:GetUInt32(10)) or 0,
                        }
                    end
                until not rows:NextRow()
            end
        end
        -- Mark any still-missing entries as false so we never re-query them.
        for _, iid in ipairs(missing) do
            if T.ITEM_TEMPLATE_CACHE[iid] == nil then
                T.ITEM_TEMPLATE_CACHE[iid] = false
            end
        end
    end

    -- Step 3: index unlocked items by itemset (and remember each item's ilvl
    -- so we can attribute it to the correct visual tier later).
    local touchedSets = {}  -- itemsetId -> true
    local unlockedBySet = {} -- itemsetId -> array of {iid, slotIdx, ilvl}
    for _, iid in ipairs(unlockedIds) do
        local tpl = T.ITEM_TEMPLATE_CACHE[iid]
        if tpl and tpl.itemset and tpl.itemset > 0 then
            local slotIdx = T.INVENTORY_TYPE_TO_SLOT_INDEX[tpl.inventoryType]
            if slotIdx then
                local sid = tpl.itemset
                touchedSets[sid] = true
                local lst = unlockedBySet[sid]
                if not lst then lst = {}; unlockedBySet[sid] = lst end
                lst[#lst + 1] = { iid = iid, slotIdx = slotIdx, ilvl = tonumber(tpl.itemLevel) or 0 }
            end
        end
    end

    -- Step 3.5: synthesize "virtual" itemsets for unlocked items whose
    -- item_template has itemset = 0 (typical of custom / downported / patched-
    -- in armor like "Corrupted Gladiator's Leather X").  Items are grouped by
    -- name-prefix (drop last word) and given a synthetic negative itemset id
    -- via GetVirtualSetId so they coexist with real (positive) itemset ids
    -- without collision.
    --
    -- IMPORTANT: build the virtual set ENTIRELY from in-memory unlocked items
    -- (already cached in T.ITEM_TEMPLATE_CACHE).  Do NOT scan item_template
    -- with LIKE for canonical totals — that approach blows the AIO 1e8
    -- instruction budget on accounts with many custom items.  totalCount is
    -- approximated as the number of distinct armor slots covered by the
    -- unlocked items (so the catalog reports e.g. "8/8" once you've unlocked
    -- a complete look).
    local function packFullStrLocal(fullItems)
        local n = #T.APPEARANCE_SET_SLOTS
        local parts, last = {}, 0
        for idx = 1, n do
            local f = fullItems[idx] or 0
            parts[idx] = tostring(f)
            if f ~= 0 then last = idx end
        end
        return last > 0 and tconcat(parts, ",", 1, last) or ""
    end

    -- Bucket unlocked-with-itemset=0 items by baseName.
    local virtualBuckets = {}  -- baseName -> { vid, items = {{iid,slotIdx,ilvl,name,disp}, ...} }
    for _, iid in ipairs(unlockedIds) do
        local tpl = T.ITEM_TEMPLATE_CACHE[iid]
        if tpl and (not tpl.itemset or tpl.itemset == 0) then
            local slotIdx = T.INVENTORY_TYPE_TO_SLOT_INDEX[tpl.inventoryType]
            if slotIdx and IsArmorSetSlotIndex(slotIdx) then
                local baseName = GetVirtualSetBaseName(tpl.name)
                if baseName then
                    local bucket = virtualBuckets[baseName]
                    if not bucket then
                        bucket = { vid = GetVirtualSetId(baseName), items = {} }
                        virtualBuckets[baseName] = bucket
                    end
                    bucket.items[#bucket.items + 1] = {
                        iid = iid, slotIdx = slotIdx,
                        ilvl = tonumber(tpl.itemLevel) or 0,
                        name = tpl.name, disp = tpl.displayId or 0,
                    }
                end
            end
        end
    end

    -- Materialise virtual itemsets directly from the bucketed unlocks.
    -- Allow even single-piece virtual sets so that a player who has unlocked
    -- e.g. only the helm of "Demonic Gladiator's Felskin" can still find the
    -- set via search and preview the full look.  When at least one piece is
    -- unlocked we additionally consult GetVirtualSetTemplate(baseName) — a
    -- single LIKE-by-baseName query per distinct baseName, cached in
    -- T.VIRTUAL_SET_TEMPLATE_CACHE — to recover the canonical piece count and
    -- per-slot fullItems/displayIds.  Falls back to the in-memory bucket if
    -- the LIKE query returns nothing (e.g. server config disabled it).
    for baseName, bucket in pairs(virtualBuckets) do
        local vid = bucket.vid
        if T.ITEMSET_FULL_CACHE[vid] == nil then
            -- Try to recover the full canonical set from item_template via baseName.
            local canon = GetVirtualSetTemplate(baseName)

            local fullItems, fullDisplay, names = {}, {}, {}
            local total = 0

            if canon and canon.totalCount and canon.totalCount > 0 then
                -- Use canonical full-piece list as the baseline so totalCount
                -- reflects the real set size (e.g. 8/8 reported correctly).
                for idx = 1, #T.APPEARANCE_SET_SLOTS do
                    fullItems[idx]   = tonumber(canon.fullItems[idx]) or 0
                    fullDisplay[idx] = tonumber(canon.fullItemDisplay and canon.fullItemDisplay[idx]) or 0
                    if fullItems[idx] ~= 0 then total = total + 1 end
                end
                names[1] = canon.name or baseName
            else
                -- Fallback: derive everything from the unlocked bucket.
                for _, u in ipairs(bucket.items) do
                    if not fullItems[u.slotIdx] then
                        fullItems[u.slotIdx]   = u.iid
                        fullDisplay[u.slotIdx] = u.disp
                        names[#names + 1]      = u.name
                        total = total + 1
                    end
                end
            end

            if total >= 1 then
                T.ITEMSET_FULL_CACHE[vid] = {
                    tiered        = false,
                    fullItems     = fullItems,
                    fullDisplay   = fullDisplay,
                    totalCount    = total,
                    classMask     = -1,
                    factionFlag   = 0,
                    armorSubclass = 0,
                    hasShield     = false,
                    weaponMask    = 0,
                    name          = (canon and canon.name) or DeriveItemSetName(names) or baseName,
                    fullStr       = packFullStrLocal(fullItems),
                }
            else
                T.ITEMSET_FULL_CACHE[vid] = false
            end
        end
        if T.ITEMSET_FULL_CACHE[vid] then
            touchedSets[vid] = true
            local lst = unlockedBySet[vid] or {}
            for _, u in ipairs(bucket.items) do
                lst[#lst + 1] = { iid = u.iid, slotIdx = u.slotIdx, ilvl = u.ilvl }
            end
            unlockedBySet[vid] = lst
        end
    end

    -- Step 4: bulk-fetch canonical full item lists for all touched sets.
    -- Cached at the itemset level so repeated builds reuse the data.
    local missingSets = {}
    for sid in pairs(touchedSets) do
        if T.ITEMSET_FULL_CACHE[sid] == nil then
            missingSets[#missingSets + 1] = sid
        end
    end
    if #missingSets > 0 then
        for s = 1, #missingSets, CHUNK do
            local e = math_min(s + CHUNK - 1, #missingSets)
            local list = {}
            for i = s, e do list[#list + 1] = missingSets[i] end
            local rows = WorldDBQuery(string_format(
                "SELECT entry, itemset, InventoryType, name, AllowableClass, class, subclass, FlagsExtra, ItemLevel, displayid FROM item_template WHERE itemset IN (%s) ORDER BY entry",
                tconcat(list, ",")))
            -- Build per-(set, ilvl) partials in one pass, plus a per-set
            -- aggregated record for the legacy single-entry path.
            local tierPartials = {}  -- sid -> ilvl -> partial
            local setPartials  = {}  -- sid -> partial (aggregate, all ilvls)
            for _, sid in ipairs(list) do
                tierPartials[sid] = {}
                setPartials[sid]  = { fullItems = {}, fullDisplay = {}, totalCount = 0, names = {}, classMask = -1, armorSubclass = 0, weaponSubs = {}, factionFlag = 0, hasShield = false }
            end
            if rows then
                repeat
                    local entry   = tonumber(rows:GetUInt32(0)) or 0
                    local sid     = tonumber(rows:GetUInt32(1)) or 0
                    local invType = tonumber(rows:GetUInt32(2)) or 0
                    local name    = rows:GetString(3) or ""
                    local ac      = tonumber(rows:GetInt32(4)) or -1
                    local iclass  = tonumber(rows:GetUInt32(5)) or 0
                    local isub    = tonumber(rows:GetUInt32(6)) or 0
                    local flagsEx = tonumber(rows:GetUInt32(7)) or 0
                    local ilvl    = tonumber(rows:GetUInt32(8)) or 0
                    local dispId  = tonumber(rows:GetUInt32(9)) or 0
                    local slotIdx = T.INVENTORY_TYPE_TO_SLOT_INDEX[invType]
                    local sp      = setPartials[sid]
                    if sp and slotIdx and entry > 0 then
                        -- Aggregate (per-set) partial: lowest-entry-per-slot wins.
                        if not sp.fullItems[slotIdx] then
                            sp.fullItems[slotIdx]   = entry
                            sp.fullDisplay[slotIdx] = dispId
                            sp.totalCount = sp.totalCount + 1
                            sp.names[#sp.names + 1] = name
                        end
                        if ac ~= -1 and ac ~= 0 then
                            if sp.classMask == -1 then sp.classMask = ac
                            else sp.classMask = MaskAnd(sp.classMask, ac) end
                        end
                        local fbit = flagsEx % 4
                        if fbit == 1 or fbit == 3 then sp.factionFlag = 1
                        elseif fbit == 2 and sp.factionFlag ~= 1 then sp.factionFlag = 2 end
                        if iclass == 4 and isub >= 1 and isub <= 4 and isub > sp.armorSubclass then
                            sp.armorSubclass = isub
                        end
                        if iclass == 4 and isub == 6 then sp.hasShield = true end
                        if iclass == 2 and isub >= 0 and isub <= 20 then sp.weaponSubs[isub] = true end

                        -- Tier (per-ilvl) partial.
                        if ilvl > 0 then
                            local tp = tierPartials[sid][ilvl]
                            if not tp then
                                tp = { fullItems = {}, fullDisplay = {}, totalCount = 0, names = {} }
                                tierPartials[sid][ilvl] = tp
                            end
                            if not tp.fullItems[slotIdx] then
                                tp.fullItems[slotIdx]   = entry
                                tp.fullDisplay[slotIdx] = dispId
                                tp.totalCount = tp.totalCount + 1
                                tp.names[#tp.names + 1] = name
                            end
                        end
                    end
                until not rows:NextRow()
            end

            local nSlots = #T.APPEARANCE_SET_SLOTS

            local function packPartial(p)
                local fullParts = {}
                local lastFull  = 0
                for idx = 1, nSlots do
                    local f = p.fullItems[idx] or 0
                    fullParts[idx] = tostring(f)
                    if f ~= 0 then lastFull = idx end
                end
                return lastFull > 0 and tconcat(fullParts, ",", 1, lastFull) or ""
            end

            local function packWeaponMask(p)
                local m, bv = 0, 1
                for sub = 0, 20 do
                    if p.weaponSubs and p.weaponSubs[sub] then m = m + bv end
                    bv = bv * 2
                end
                return m
            end

            -- Decide per-set tier strategy and finalise cache entries.
            for _, sid in ipairs(list) do
                local sp = setPartials[sid]
                if not sp or sp.totalCount == 0 then
                    T.ITEMSET_FULL_CACHE[sid] = false
                else
                    local maxCount = sp.totalCount
                    local primary  = {}  -- list of ilvls where totalCount == maxCount
                    for ilvl, tp in pairs(tierPartials[sid]) do
                        if tp.totalCount == maxCount then primary[#primary + 1] = ilvl end
                    end
                    tsort(primary)

                    local baseName = DeriveItemSetName(sp.names)
                    if not baseName or baseName == "" then baseName = "Set "..tostring(sid) end

                    if #primary <= 1 then
                        -- Single visual tier: legacy single entry per itemset.
                        T.ITEMSET_FULL_CACHE[sid] = {
                            tiered        = false,
                            fullItems     = sp.fullItems,
                            fullDisplay   = sp.fullDisplay,
                            totalCount    = sp.totalCount,
                            classMask     = sp.classMask,
                            factionFlag   = sp.factionFlag,
                            armorSubclass = sp.armorSubclass,
                            hasShield     = sp.hasShield,
                            weaponMask    = packWeaponMask(sp),
                            name          = baseName,
                            fullStr       = packPartial(sp),
                        }
                    else
                        -- Multiple visual tiers: emit one entry per primary tier.
                        local tiers = {}
                        for _, ilvl in ipairs(primary) do
                            local tp = tierPartials[sid][ilvl]
                            local tierName = DeriveItemSetName(tp.names)
                            if not tierName or tierName == "" then tierName = baseName end
                            tiers[ilvl] = {
                                fullItems     = tp.fullItems,
                                fullDisplay   = tp.fullDisplay,
                                totalCount    = tp.totalCount,
                                classMask     = sp.classMask,        -- inherit from set
                                factionFlag   = sp.factionFlag,
                                armorSubclass = sp.armorSubclass,
                                hasShield     = sp.hasShield,
                                weaponMask    = packWeaponMask(sp),
                                name          = tierName,
                                ilvl          = ilvl,
                                fullStr       = packPartial(tp),
                            }
                        end
                        -- Disambiguate same-named tiers by appending ilvl.
                        local nameCt = {}
                        for _, t in pairs(tiers) do nameCt[t.name] = (nameCt[t.name] or 0) + 1 end
                        for _, t in pairs(tiers) do
                            if nameCt[t.name] > 1 then
                                t.name = t.name .. " (" .. tostring(t.ilvl) .. ")"
                            end
                        end
                        T.ITEMSET_FULL_CACHE[sid] = {
                            tiered      = true,
                            primary     = primary,   -- sorted ilvl list
                            tiers       = tiers,     -- ilvl -> tier record
                            baseName    = baseName,
                        }
                    end
                end
            end
        end
    end

    -- Step 5: build entry records (one per itemset, or one per primary tier),
    -- then merge entries that share a display signature so visually-identical
    -- sets across different itemsets (e.g. Gladiator's Linked / Mail / Ringmail)
    -- collapse into a single catalog row.
    local nSlots = #T.APPEARANCE_SET_SLOTS

    local function nearestPrimaryTier(primary, ilvl)
        -- primary is sorted ascending.  Pick the entry with smallest |delta|;
        -- on ties prefer the higher tier (matches "upgraded" item intuition).
        local best, bestDelta = primary[1], math.abs(primary[1] - ilvl)
        for i = 2, #primary do
            local d = math.abs(primary[i] - ilvl)
            if d < bestDelta or (d == bestDelta and primary[i] > best) then
                best, bestDelta = primary[i], d
            end
        end
        return best
    end

    -- Collect raw entries first (still per source set/tier) so we can merge.
    local entries = {}
    for sid in pairs(touchedSets) do
        local si = T.ITEMSET_FULL_CACHE[sid]
        if si then
            if si.tiered then
                local perTier = {}
                for _, ilvl in ipairs(si.primary) do
                    perTier[ilvl] = { unlockedItems = {}, count = 0 }
                end
                for _, u in ipairs(unlockedBySet[sid] or {}) do
                    local target = nearestPrimaryTier(si.primary, u.ilvl)
                    local pt = perTier[target]
                    if pt and not pt.unlockedItems[u.slotIdx] then
                        pt.unlockedItems[u.slotIdx] = u.iid
                        pt.count = pt.count + 1
                    end
                end
                for _, ilvl in ipairs(si.primary) do
                    local t  = si.tiers[ilvl]
                    local pt = perTier[ilvl]
                    entries[#entries + 1] = {
                        id            = sid * 10000 + ilvl,
                        name          = t.name,
                        totalCount    = t.totalCount,
                        fullItems     = t.fullItems,
                        fullDisplay   = t.fullDisplay,
                        unlockedItems = pt.unlockedItems,
                        classMask     = t.classMask,
                        armorSubclass = t.armorSubclass,
                        weaponMask    = t.weaponMask,
                        factionFlag   = t.factionFlag,
                        hasShield     = t.hasShield,
                    }
                end
            else
                local unlockedItems = {}
                local count = 0
                for _, u in ipairs(unlockedBySet[sid] or {}) do
                    if not unlockedItems[u.slotIdx] then
                        unlockedItems[u.slotIdx] = u.iid
                        count = count + 1
                    end
                end
                entries[#entries + 1] = {
                    id            = sid,
                    name          = si.name,
                    totalCount    = si.totalCount,
                    fullItems     = si.fullItems,
                    fullDisplay   = si.fullDisplay,
                    unlockedItems = unlockedItems,
                    classMask     = si.classMask,
                    armorSubclass = si.armorSubclass,
                    weaponMask    = si.weaponMask,
                    factionFlag   = si.factionFlag,
                    hasShield     = si.hasShield,
                }
            end
        end
    end

    -- Display-signature merge: collapse entries with identical visual displays
    -- into a single canonical entry.  O(n) hash-based: build a signature string
    -- from all non-zero (slot:displayId) pairs and use it as a map key.
    -- Visually-identical sets (e.g. Gladiator's Linked/Mail/Ringmail variants
    -- that share every display ID) collapse; partially-overlapping sets are
    -- kept separate to avoid incorrectly merging distinct armour types.
    local merged = {}
    local sigToIdx = {}  -- display sig string → index in merged
    for _, e in ipairs(entries) do
        local parts = {}
        for i = 1, nSlots do
            local d = (e.fullDisplay and e.fullDisplay[i]) or 0
            if d ~= 0 then parts[#parts + 1] = i .. ":" .. d end
        end
        local sig = tconcat(parts, "|")
        local existingIdx = sig ~= "" and sigToIdx[sig]
        if existingIdx then
            local can = merged[existingIdx]
            -- Prefer lower id as canonical.
            if e.id < can.id then
                merged[existingIdx] = e
                e, can = can, e
            end
            -- Shorten name to common word prefix of both.
            local common = DeriveItemSetName({can.name, e.name})
            if common and common ~= "" and common ~= "Unnamed Set" then
                can.name = common
            end
            -- Complement unlocked slots from the absorbed entry.
            for i = 1, nSlots do
                if (can.unlockedItems[i] or 0) == 0 and (e.unlockedItems[i] or 0) ~= 0 then
                    can.unlockedItems[i] = e.unlockedItems[i]
                end
            end
        else
            merged[#merged + 1] = e
            if sig ~= "" then sigToIdx[sig] = #merged end
        end
    end

    -- Pack final transport rows.
    for _, e in ipairs(merged) do
        local count = 0
        local unlockedParts, lastUnlocked = {}, 0
        for i = 1, nSlots do
            local u = e.unlockedItems[i] or 0
            unlockedParts[i] = tostring(u)
            if u ~= 0 then count = count + 1; lastUnlocked = i end
        end
        local unlockedStr = lastUnlocked > 0 and tconcat(unlockedParts, ",", 1, lastUnlocked) or ""
        local fullParts, lastFull = {}, 0
        for i = 1, nSlots do
            local f = e.fullItems[i] or 0
            fullParts[i] = tostring(f)
            if f ~= 0 then lastFull = i end
        end
        local fullStr = lastFull > 0 and tconcat(fullParts, ",", 1, lastFull) or ""
        result[#result + 1] = {
            e.id,
            e.name,
            count,
            e.totalCount,
            1,
            fullStr,
            unlockedStr,
            e.classMask,
            e.armorSubclass,
            e.weaponMask,
            e.factionFlag,
            e.hasShield and 1 or 0,
        }
    end

    -- Stable sort by name so the UI is deterministic.
    tsort(result, function(a, b) return tostring(a[2]) < tostring(b[2]) end)
    return result
end

function TransmogHandlers.GetUnlockedItemSets(player, requestToken)
    local accountGUID = player and player:GetAccountId() or 0
    requestToken = tonumber(requestToken) or 0
    if accountGUID <= 0 then
        AIO.Handle(player, "Transmog", "InitItemSets", {}, requestToken)
        return
    end

    local ok, err = pcall(function()
    -- Build (or hit cache for) the full unfiltered packed catalog.
    local cached = T.UNLOCKED_ITEM_SETS_CACHE[accountGUID]
    if not cached then
        local ok, packed = pcall(BuildUnlockedItemSetsTransport, accountGUID)
        if not ok then
            print("[Transmog] GetUnlockedItemSets ERROR: "..tostring(packed))
            packed = {}
        end
        T.UNLOCKED_ITEM_SETS_CACHE[accountGUID] = packed
        cached = packed
    end

    -- Apply blizzlike per-class filter at send time.  We do NOT cache the
    -- filtered list because two characters on the same account may have
    -- different classes/races, and the filter is cheap (a few bit-ANDs per set).
    -- The full catalog is the cached, expensive part.
    local out = cached
    if T.Blizzlike_Transmog and player then
        local classId    = player:GetClass() or 0
        local raceId     = player:GetRace()  or 0
        local classMask  = T.CLASS_ID_TO_MASK[classId] or 0
        local faction    = T.RACE_ID_TO_FACTION[raceId]  -- nil if unknown
        local maxArmor   = T.CLASS_ID_TO_MAX_ARMOR_SUBCLASS[classId] or 4
        local weaponMask = T.CLASS_ID_TO_WEAPON_MASK[classId] or 0
        if classMask > 0 then
            out = {}
            local factionBlocked = 0
            for i = 1, #cached do
                local s = cached[i]
                local ac         = tonumber(s[8])  or -1
                local sub        = tonumber(s[9])  or 0
                local wmask      = tonumber(s[10]) or 0
                local factionFlg = tonumber(s[11]) or 0
                local hasShield  = tonumber(s[12]) or 0
                local classOk   = (ac == -1 or ac == 0) or (MaskAnd(ac, classMask) ~= 0)
                local armorOk   = (sub == 0)   or (sub <= maxArmor)
                local weaponOk  = (wmask == 0) or (MaskAnd(wmask, weaponMask) == wmask)
                local shieldOk  = (hasShield == 0) or (T.CLASS_SHIELD_ALLOWED[classId] == true)
                -- factionFlag: 1=Horde-only, 2=Alliance-only, 0=unrestricted
                -- If faction is nil (unknown race) allow all faction flags
                local factionOk = (faction == nil) or (factionFlg == 0)
                    or (factionFlg == 1 and faction == "Horde")
                    or (factionFlg == 2 and faction == "Alliance")
                if not factionOk then factionBlocked = factionBlocked + 1 end
                if classOk and armorOk and weaponOk and shieldOk and factionOk then
                    out[#out + 1] = s
                end
            end
        end
    end

    AIO.Handle(player, "Transmog", "InitItemSets", out, requestToken)
    end)
    if not ok then
        print("[Transmog] GetUnlockedItemSets send ERROR: "..tostring(err))
        AIO.Handle(player, "Transmog", "InitItemSets", {}, requestToken, tostring(err))
    end
end

function TransmogHandlers.ApplyUnlockedItemSet(player, itemsetId)
    itemsetId = tonumber(itemsetId)
    if not itemsetId or itemsetId == 0 then
        TransmogHandlers.SetTransmogItemIds(player)
        AIO.Handle(player, "Transmog", "UnlockedItemSetResult", "Item set", 0, 0, "")
        return
    end

    local accountGUID = player:GetAccountId()

    -- Use the same catalog source that GetUnlockedItemSets sends to the client
    -- (BuildUnlockedItemSetsTransport).  The old BuildAccountItemSetCatalog path
    -- used a different grouping/merging strategy and could produce IDs that did
    -- not match the packed catalog the client received, causing the set lookup
    -- to silently fail and return appliedCount=0.
    local selectedSet = nil
    local function parseItemCSV(str)
        if type(str) ~= "string" or str == "" then return {} end
        local t, i = {}, 1
        for tok in (str .. ","):gmatch("([^,]*),") do
            t[i] = tonumber(tok) or 0
            i = i + 1
        end
        return t
    end

    local catalog = BuildUnlockedItemSetsTransport(accountGUID)
    for _, s in ipairs(catalog) do
        if tonumber(s[1]) == itemsetId then
            selectedSet = {
                name          = tostring(s[2] or "Set"),
                unlockedItems = parseItemCSV(s[7] or ""),  -- unlockedStr
                fullItems     = parseItemCSV(s[6] or ""),  -- fullStr
            }
            break
        end
    end

    if not selectedSet then
        TransmogHandlers.SetTransmogItemIds(player)
        AIO.Handle(player, "Transmog", "UnlockedItemSetResult", "Item set", 0, 0, "")
        return
    end

    local playerGUID = player:GetGUIDLow()

    -- Pre-calculate chargeable slots for the unlocked item set.
    -- Skip any slot whose appearance is already set to the target item so that
    -- the server charge matches exactly what the client cost display shows.
    -- Also skip slots that would be rejected by blizzlike equip restrictions.
    if T.transmog_cost then
        local currentItemIds = GetAllStoredItemIds(playerGUID)
        local totalCost = 0
        for index, info in ipairs(T.APPEARANCE_SET_SLOTS) do
            local unlockedItemId = tonumber(selectedSet.unlockedItems[index]) or 0
            if unlockedItemId > 0 and currentItemIds[info.slot] ~= unlockedItemId then
                if PlayerCanTransmogItem(player, GetItemTemplateInfo(unlockedItemId), info.slot) then
                    totalCost = totalCost + GetTransmogCostForItem(player, unlockedItemId)
                end
            end
        end
        if totalCost > 0 then
            local currentMoney = player:GetCoinage()
            if currentMoney < totalCost then
                AIO.Handle(player, "Transmog", "TransmogCostError", totalCost)
                -- Resync the client to the real server state so the left model rolls back.
                TransmogHandlers.SetTransmogItemIds(player)
                AIO.Handle(player, "Transmog", "UnlockedItemSetResult", selectedSet.name, 0, 0, "")
                return
            end
            player:ModifyMoney(-totalCost)
        end
    end

    local appliedCount = 0
    local missingSlots = {}
    local batchUpdates = {}

    local realItemIds = GetAllStoredRealItemIds(playerGUID)

    for index, info in ipairs(T.APPEARANCE_SET_SLOTS) do
        local unlockedItemId = tonumber(selectedSet.unlockedItems[index]) or 0
        local previewItemId  = tonumber(selectedSet.fullItems[index]) or 0
        local realItemId     = realItemIds[info.slot] or 0

        if unlockedItemId > 0 then
            if not PlayerCanTransmogItem(player, GetItemTemplateInfo(unlockedItemId), info.slot) then
                tinsert(missingSlots, info.name)
            else
                batchUpdates[#batchUpdates + 1] = {info.slot, unlockedItemId, realItemId}
                SetVisibleItemValue(player, info.slot, unlockedItemId)
                appliedCount = appliedCount + 1
            end
        elseif previewItemId > 0 then
            -- Set has a full item for this slot but the player hasn't unlocked
            -- it yet.  Report it as missing; leave the existing transmog alone.
            tinsert(missingSlots, info.name)
        end
        -- Slots with no item in the set at all (previewItemId == 0 and
        -- unlockedItemId == 0) are left unchanged.  Apply Unlocked only touches
        -- slots that belong to this set, so unrelated transmogs are preserved.
    end

    BatchUpsertTransmogSlots(playerGUID, batchUpdates)
    TransmogHandlers.SetTransmogItemIds(player)
    AIO.Handle(player, "Transmog", "UnlockedItemSetResult", selectedSet.name, appliedCount, 0, tconcat(missingSlots, ", "))
end

function TransmogHandlers.UnequipTransmogItem(player, slot)
    local playerGUID = player:GetGUIDLow()
    slot = NormalizeVisibleSlot(slot)
    if not slot then
        return
    end

    local oldItemId = GetStoredRealItemId(playerGUID, slot)
    UpsertTransmogSlot(playerGUID, slot, 0, oldItemId)
    SetVisibleItemValue(player, slot, 0)
end

-- ── Hidden-illusion enforcement cache ─────────────────────────────────────────────────
-- Tracks players who have enchant_id = 0 ("hide") stored for a weapon slot.
-- The periodic enforcer uses this to suppress any glow written to the field
-- by imbues, real enchants, or any other external source that bypasses the
-- OnAfterSetVisibleItemSlot hook.
-- Structure: guid_low (number) → { [slotId] = true }
T.HIDDEN_ENCHANT_PLAYERS = {}

local function UpdateHiddenEnchantCache(playerGUID, slotId, enchantId)
    if enchantId == 0 then
        if not T.HIDDEN_ENCHANT_PLAYERS[playerGUID] then
            T.HIDDEN_ENCHANT_PLAYERS[playerGUID] = {}
        end
        T.HIDDEN_ENCHANT_PLAYERS[playerGUID][slotId] = true
    else
        local slots = T.HIDDEN_ENCHANT_PLAYERS[playerGUID]
        if slots then
            slots[slotId] = nil
            if not next(slots) then
                T.HIDDEN_ENCHANT_PLAYERS[playerGUID] = nil
            end
        end
    end
end
-- ─────────────────────────────────────────────────────────────────────────

-- Re-applies all stored weapon illusions for a player.  Also AUTHORITATIVELY
-- rebuilds T.HIDDEN_ENCHANT_PLAYERS[guid] from the DB so any stale cache
-- entries (e.g. left over after `.transmog wipeillusions`, direct SQL edits,
-- or an Eluna reload mid-session) are dropped.  Without this rebuild, the
-- periodic enforcer can keep zeroing the enchant field for a slot whose DB
-- row no longer exists — producing exactly the "stuck hidden" state the
-- user just hit.
ApplyStoredIllusions = function(player)
    local playerGUID = player:GetGUIDLow()

    -- Authoritative cache rebuild: drop everything for this GUID first.
    T.HIDDEN_ENCHANT_PLAYERS[playerGUID] = nil

    -- Include enchant_id = 0 rows so "hide enchant" is also re-applied on login.
    local rows = CharDBQuery(string_format(
        "SELECT slot_id, enchant_id FROM character_illusion WHERE player_guid = %d",
        playerGUID
    ))
    if not rows then return end
    repeat
        local slotId    = tonumber(rows:GetUInt32(0))
        local enchantId = tonumber(rows:GetUInt32(1))
        local equipSlot = slotId and T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
        if equipSlot and enchantId ~= nil then
            local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
            if ok and item then
                -- Safety: never apply an illusion to a shield. If a stale DB
                -- row somehow targets a shield, purge it and skip.
                local isShield = false
                if slotId == T.SLOT_OFFHAND then
                    local okT, tpl = pcall(item.GetItemTemplate, item)
                    if okT and tpl then
                        local okC, iclass  = pcall(tpl.GetClass,    tpl)
                        local okS, isubcls = pcall(tpl.GetSubClass, tpl)
                        if okC and okS and iclass == 4 and isubcls == 6 then
                            isShield = true
                        end
                    end
                end
                if isShield then
                    CharDBQuery(string_format(
                        "DELETE FROM character_illusion WHERE player_guid = %d AND slot_id = %d",
                        playerGUID, slotId
                    ))
                else
                    local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)
                    if enchantId == 0 then
                        HideEnchantVisual(player, fieldIndex)
                    else
                        SetEnchantVisual(player, fieldIndex, enchantId)
                    end
                end
            end
        end
        -- Keep the enforcement cache in sync with whatever is stored in the DB.
        if slotId then UpdateHiddenEnchantCache(playerGUID, slotId, enchantId or 1) end
    until not rows:NextRow()
end

local function ReapplyWeaponIllusionVisual(player, slotId, enchantId)
    if not player then return false end
    local equipSlot = slotId and T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
    if not equipSlot then return false end

    local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
    if not ok or not item then return false end

    local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)
    if enchantId == 0 then
        HideEnchantVisual(player, fieldIndex)
    else
        SetEnchantVisual(player, fieldIndex, enchantId)
    end
    return true
end

local function ScheduleWeaponIllusionReapply(playerGUID, slotId, enchantId)
    if not CreateLuaEvent then return end

    local delays = { 100, 350, 1000 }
    for _, delay in ipairs(delays) do
        CreateLuaEvent(function()
            local player = nil
            if GetPlayerByGUID then
                player = GetPlayerByGUID(playerGUID)
            end
            if not player then return end

            local row = CharDBQuery(string_format(
                "SELECT enchant_id FROM character_illusion WHERE player_guid = %d AND slot_id = %d LIMIT 1",
                playerGUID, slotId
            ))
            if not row then return end

            local storedEnchant = tonumber(row:GetUInt32(0))
            if storedEnchant == enchantId then
                ReapplyWeaponIllusionVisual(player, slotId, storedEnchant)
            end
        end, delay, 1)
    end
end

-- Applies or removes a weapon enchant *visual* (illusion) on the player's equipped
-- weapon in the requested slot.  Uses SetEnchantVisual (SetUInt32Value +
-- enchantment field — this is purely cosmetic and does NOT apply real enchant stats.
-- slotId is a PLAYER_VISIBLE_ITEM slot (313 = Main Hand, 315 = Off-hand).
-- enchantId = 0 removes the current visual.
function TransmogHandlers.ApplyWeaponIllusion(player, slotId, enchantId)
    slotId    = tonumber(slotId)   or 0
    enchantId = tonumber(enchantId) or 0

    -- Only Main Hand (313) and Off-hand (315) are supported.
    if slotId ~= T.SLOT_MAINHAND and slotId ~= T.SLOT_OFFHAND then
        AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId, "Неверная ячейка оружия.")
        return
    end

    local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
    if not equipSlot then
        AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId, "Не удалось определить ячейку экипировки.")
        return
    end

    -- Confirm the player has something equipped there.
    local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
    if not ok or not item then
        AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId, "В этой ячейке нет оружия.")
        return
    end

    -- Shields cannot have enchant illusions. If the off-hand item is a shield
    -- (item class 4, subclass 6), reject immediately and purge any previously
    -- persisted illusion for that slot so it cannot linger in the DB.
    if slotId == T.SLOT_OFFHAND then
        local okT, tpl = pcall(item.GetItemTemplate, item)
        if okT and tpl then
            local okC, iclass   = pcall(tpl.GetClass,    tpl)
            local okS, isubcls  = pcall(tpl.GetSubClass, tpl)
            if okC and okS and iclass == 4 and isubcls == 6 then
                -- Purge any stale DB row so the shield stays clean.
                CharDBQuery(string_format(
                    "DELETE FROM character_illusion WHERE player_guid = %d AND slot_id = %d",
                    player:GetGUIDLow(), slotId
                ))
                UpdateHiddenEnchantCache(player:GetGUIDLow(), slotId, 1)
                AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId,
                    "Иллюзии чар нельзя наложить на щит.")
                return
            end
        end
    end

    -- Blizzlike illusion cost: 25% of player level in gold.  enchantId == 0
    -- ("No Enchant" / hide) is always free.  Skip charging if the slot already
    -- has the requested illusion (repeated Apply clicks must not double-charge).
    if enchantId > 0 and T.transmog_cost then
        local existingRow = CharDBQuery(string_format(
            "SELECT enchant_id FROM character_illusion WHERE player_guid = %d AND slot_id = %d LIMIT 1",
            player:GetGUIDLow(), slotId))
        local currentEnchant = existingRow and (tonumber(existingRow:GetUInt32(0)) or -1) or -1
        if currentEnchant ~= enchantId then
            local cost = math_floor(player:GetLevel() * 2500)  -- copper: 0.25 * level * 10 000
            if cost > 0 then
                if player:GetCoinage() < cost then
                    AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId,
                        string_format("Недостаточно золота. Иллюзия стоит |cffffd700%dз|r |cffc7c7cf%dс|r.",
                            math_floor(cost / 10000),
                            math_floor((cost % 10000) / 100)))
                    return
                end
                player:ModifyMoney(-cost)
            end
        end
    end

    local playerGUID = player:GetGUIDLow()

    -- Persist before kicking the visible-slot refresh so the
    -- OnAfterSetVisibleItemSlot hook can see the new intent if the core fires it
    -- synchronously during SetVisibleItemSlot.
    CharDBQuery(string_format(
        "INSERT INTO character_illusion (player_guid, slot_id, enchant_id) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE enchant_id = VALUES(enchant_id)",
        playerGUID, slotId, enchantId
    ))

    -- Force a visible-item refresh FIRST so every observing client (self
    -- included) re-reads the visible-item fields for this slot.  This also
    -- resets the enchant field to the item's natural perm enchant — which is
    -- why we then call SetEnchantVisual AFTERWARDS, so our illusion value
    -- ends up as the final write and actually takes effect on the live
    -- character model.  Without this order, the engine may broadcast the
    -- pre-illusion state to other players before our write propagates.
    if type(player.SetVisibleItemSlot) == "function" then
        pcall(player.SetVisibleItemSlot, player, equipSlot, item)
    end

    local applyOk, applyErr = pcall(function()
        ReapplyWeaponIllusionVisual(player, slotId, enchantId)
    end)
    if not applyOk then
        AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId, "Не удалось применить эффект: " .. tostring(applyErr))
        return
    end

    -- Update the enforcement cache so the periodic suppressor immediately
    -- starts (or stops) policing this slot.
    UpdateHiddenEnchantCache(playerGUID, slotId, enchantId)

    -- Some cores rebuild PLAYER_VISIBLE_ITEM fields shortly after
    -- SetVisibleItemSlot and can overwrite the immediate write above with the
    -- equipped weapon's natural enchant.  Re-apply on short delayed ticks, but
    -- only if the DB still contains the same intent.
    ScheduleWeaponIllusionReapply(playerGUID, slotId, enchantId)

    -- Push a fresh authoritative state sync so the client immediately sees the
    -- confirmed enchant value and the preview stays in sync.  SetTransmogItemIds
    -- now reads from character_illusion (not the live field) so the round-trip
    -- is guaranteed to reflect exactly what we just persisted.
    TransmogHandlers.SetTransmogItemIds(player)
    AIO.Handle(player, "Transmog", "WeaponIllusionApplied", slotId, enchantId)
end

function TransmogHandlers.ApplyWeaponIllusionV2(player, slotId, enchantId)
    return TransmogHandlers.ApplyWeaponIllusion(player, slotId, enchantId)
end

if AIO and AIO.RegisterEvent then
    pcall(AIO.RegisterEvent, "ABIllusionApplyV3", function(player, slotId, enchantId)
        if TransmogHandlers and type(TransmogHandlers.ApplyWeaponIllusion) == "function" then
            TransmogHandlers.ApplyWeaponIllusion(player, slotId, enchantId)
        end
    end)
    pcall(AIO.RegisterEvent, "ABIllusionApplyV2", function(player, slotId, enchantId)
        if TransmogHandlers and type(TransmogHandlers.ApplyWeaponIllusion) == "function" then
            TransmogHandlers.ApplyWeaponIllusion(player, slotId, enchantId)
        end
    end)
end

-- Removes any weapon-illusion override on the requested slot, restoring the
-- weapon's natural visual.  Used by the client's Revert All button so that
-- temporary imbues (Windfury, Flametongue, etc., stored in the upper 16 bits
-- of the enchant field) and permanent enchants (lower 16 bits read from the
-- item's enchantment slot 0) are both preserved.  Just rewriting the lower
-- 16 bits to 0 would kill a Windfury glow if there was no perm enchant; just
-- DELETE-ing the DB row would leave a stale override in the live field if a
-- previous SetEnchantVisual had clobbered it.  We do both, plus rewrite the
-- field with the item's real perm enchant so the natural state is bulletproof.
function TransmogHandlers.ClearWeaponIllusion(player, slotId)
    slotId = tonumber(slotId) or 0
    if slotId ~= T.SLOT_MAINHAND and slotId ~= T.SLOT_OFFHAND then
        AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId, "Неверная ячейка оружия.")
        return
    end

    local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
    if not equipSlot then
        AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId, "Не удалось определить ячейку экипировки.")
        return
    end

    local playerGUID = player:GetGUIDLow()

    -- 1. Drop the persisted override.
    CharDBQuery(string_format(
        "DELETE FROM character_illusion WHERE player_guid = %d AND slot_id = %d",
        playerGUID, slotId
    ))

    -- 2. Remove from the periodic enforcer cache.
    UpdateHiddenEnchantCache(playerGUID, slotId, 1)  -- 1 ≠ 0 → removes from cache

    -- 3. Restore the natural perm enchant on the live field via SetEnchantVisual,
    --    which writes ONLY the lower 16 bits (perm enchant) and PRESERVES the
    --    upper 16 bits (temp-imbue visual: Windfury / Flametongue / Rockbiter /
    --    Poisons / sharpening stones / oils).  Earlier this path wrote the full
    --    32-bit value to clear "stale" temp-imbue bits, but that also wiped the
    --    user's currently-active imbue every time they hit Revert All — leaving
    --    them with no weapon glow until the imbue aura's next periodic refresh
    --    re-wrote the upper 16 bits (10+ seconds, sometimes never).
    --
    --    Permanent enchants and illusions live in the LOWER 16 bits, temp imbues
    --    in the UPPER 16 — they never overlap.  Restoring just the lower 16 to
    --    the item's real perm enchant is correct and complete.
    local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
    if ok and item then
        local permEnchant = 0
        local okE, raw = pcall(item.GetEnchantmentId, item, 0)  -- 0 = PERM_ENCHANTMENT_SLOT
        if okE and raw then permEnchant = tonumber(raw) or 0 end
        local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)

        -- Force a visible-item refresh FIRST so every observing client (self
        -- included) re-reads the visible-item fields for this slot.  Without
        -- this kick, the SetEnchantVisual write below is staged on the
        -- server but the previously-broadcast "hidden" state lingers on the
        -- client — the dressing-room model (SetUnit("player")) keeps
        -- rendering the suppressed glow even after Revert All.  Same pattern
        -- ApplyWeaponIllusion uses to make illusions visible immediately.
        if type(player.SetVisibleItemSlot) == "function" then
            pcall(player.SetVisibleItemSlot, player, equipSlot, item)
        end

        pcall(SetEnchantVisual, player, fieldIndex, permEnchant)
    end

    -- 4. Confirm to the client (this also re-pushes SetStoredIllusions, which
    --    will now report the natural enchant since the DB row is gone).
    TransmogHandlers.SetTransmogItemIds(player)
end

function TransmogHandlers.displayTransmog(player, spellid)
    AIO.Handle(player, "Transmog", "TransmogFrame")
    return false
end

-- All enchant visual IDs available as weapon illusions.
-- Source: same pool used by mod-ale's random-enchant-visual script.
T.AVAILABLE_ILLUSION_IDS = {
    3789, 3854, 3273, 3225, 3870, 1899, 2674, 2675, 2671, 2672,
    3365, 2673, 2343,  425, 3855, 1894, 1103, 1898, 3345, 1743,
    3093, 1900, 3846, 1606,  283,    1, 3265,    2,    3, 3266,
    1903,   13,   26,    7,  803, 1896, 2666,   25,
}

-- Sends the list of available illusion enchant IDs to the requesting player.
-- Currently grants full access to every player.  Swap the table population
-- logic here when per-player unlock tracking is added.
function TransmogHandlers.GetAvailableIllusions(player)
    AIO.Handle(player, "Transmog", "ReceiveAvailableIllusions", T.AVAILABLE_ILLUSION_IDS)
end

function TransmogHandlers.SetTransmogItemIds(player)
    local playerGUID = player:GetGUIDLow()

    -- Build an authoritative map of equipped item IDs per visible slot.
    -- This is the only reliable source on 3.3.5: the client's GetInventoryItemID
    -- returns wrong values for the off-hand slot when a 2H weapon is equipped
    -- (auto-mirrors MH into OH), which causes the dressing room preview to
    -- show the off-hand weapon in the main hand and leave the off-hand empty.
    --
    -- Resolution chain (each item independently tried):
    --   1. Player:GetEquippedItemBySlot(equipSlot)  -- canonical for slots 0-18
    --   2. Player:GetItemByPos(255, equipSlot)      -- fallback
    -- Then read the entry id with one of (in order):
    --   a. Item:GetEntry()         -- inherited from Object, always present
    --   b. Item:GetItemTemplate():GetItemId()  -- fallback
    --
    -- Any failure is logged once via print so we never go silent.
    local equippedBySlot = {}
    local function resolveEquippedId(equipSlot)
        local item
        local ok, err = pcall(function()
            if player.GetEquippedItemBySlot then
                item = player:GetEquippedItemBySlot(equipSlot)
            end
            if not item and player.GetItemByPos then
                item = player:GetItemByPos(255, equipSlot)
            end
        end)
        if not ok then
            if T.DEBUG_EQUIPPED then
            print(string_format(
                "[AppearanceBuddy] equip-slot %d lookup failed: %s",
                equipSlot, tostring(err)))
            end
            return 0
        end
        if not item then return 0 end

        -- Try GetEntry first (Object-level method, always available in ALE).
        local id
        local okE, errE = pcall(function()
            if item.GetEntry then
                id = item:GetEntry()
            end
            if (not id or id == 0) and item.GetItemTemplate then
                local tpl = item:GetItemTemplate()
                if tpl and tpl.GetItemId then
                    id = tpl:GetItemId()
                end
            end
        end)
        if not okE then
            if T.DEBUG_EQUIPPED then
            print(string_format(
                "[AppearanceBuddy] equip-slot %d entry lookup failed: %s",
                equipSlot, tostring(errE)))
            end
            return 0
        end
        return tonumber(id) or 0
    end

    for _, info in ipairs(T.APPEARANCE_SET_SLOTS) do
        local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[info.slot]
        if equipSlot then
            equippedBySlot[info.slot] = resolveEquippedId(equipSlot)
        end
    end

    -- Optional verbose diagnostic.  Enable by setting `T.DEBUG_EQUIPPED = true`
    -- (e.g. from a GM command) when chasing preview glitches.  Prints the
    -- weapon-slot resolution result so we can verify the server saw both hands.
    if T.DEBUG_EQUIPPED then
        print(string_format(
            "[AppearanceBuddy] %s equipped MH=%d OH=%d Ranged=%d",
            tostring(player.GetName and player:GetName() or playerGUID),
            equippedBySlot[313] or 0,
            equippedBySlot[315] or 0,
            equippedBySlot[317] or 0))
    end

    local batch = {}
    local slotsSent = {}

    local transmogs = CharDBQuery(string_format(
        "SELECT slot, item, real_item FROM character_transmog WHERE player_guid = %d",
        playerGUID
    ))
    if transmogs then
        repeat
            local slot = NormalizeVisibleSlot(transmogs:GetUInt32(0))
            if slot then
                -- Column 1 (item): NULL in SQL → GetUInt32 returns 0, but we need
                -- nil for "no transmog" vs 0 for "hidden".  IsNull is not
                -- universally available, so test via GetString which returns "".
                local rawItem = transmogs:GetString(1)
                local item
                if rawItem == nil or rawItem == "" or rawItem == "NULL" then
                    item = nil          -- no transmog override
                else
                    item = tonumber(rawItem) or 0   -- 0 = hidden, >0 = transmog
                end
                batch[#batch + 1] = {
                    slot,
                    item,
                    tonumber(transmogs:GetUInt32(2)) or 0,
                    equippedBySlot[slot] or 0,
                }
                slotsSent[slot] = true
            end
        until not transmogs:NextRow()
    end

    -- Always send all 14 visible slots so the client can call normalizeServerState
    -- for every slot.  For slots with no character_transmog row, the 4th element
    -- (server-resolved equipped item ID) lets the client show what the player
    -- actually has equipped without ever consulting GetInventoryItemID.
    for _, info in ipairs(T.APPEARANCE_SET_SLOTS) do
        if not slotsSent[info.slot] then
            batch[#batch + 1] = {info.slot, nil, 0, equippedBySlot[info.slot] or 0}
        end
    end

    if #batch > 0 then
        AIO.Handle(player, "Transmog", "SetTransmogItemIdsBatch", batch)
    end

    -- Re-push authoritative weapon-enchant visibility from the character_illusion
    -- DB table, NOT the live visible field.  The live field can be overwritten at
    -- any time by Shaman imbues, Eluna reloads, or any other external write — if
    -- we read it here we would send the natural enchant back to the client and
    -- undo a stored "hide".  The DB row is the source of truth for the player's
    -- INTENT.  We also re-apply SetEnchantVisual whenever the live field disagrees
    -- with the stored intent so the field self-heals without waiting for the
    -- 3-second periodic enforcer, and we repopulate HIDDEN_ENCHANT_PLAYERS in case
    -- it was wiped by an Eluna reload.
    do
        -- Load stored illusion intents for both weapon slots in one query.
        local dbIllusions = {}
        local illRows = CharDBQuery(string_format(
            "SELECT slot_id, enchant_id FROM character_illusion WHERE player_guid = %d AND slot_id IN (%d, %d)",
            playerGUID, T.SLOT_MAINHAND, T.SLOT_OFFHAND
        ))
        if illRows then
            repeat
                local sid = tonumber(illRows:GetUInt32(0))
                local eid = tonumber(illRows:GetUInt32(1))
                if sid then dbIllusions[sid] = eid end
            until not illRows:NextRow()
        end

        local illusionData = {}
        for _, slotId in ipairs({ T.SLOT_MAINHAND, T.SLOT_OFFHAND }) do
            local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
            if equipSlot then
                local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
                local storedEnchant = dbIllusions[slotId]
                if ok and item and storedEnchant ~= nil then
                    -- DB has an explicit intent.  If the live field disagrees,
                    -- re-apply immediately so the character visual is correct
                    -- before the next enforcer tick.
                    local fieldIndex  = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)
                    local valOk, raw  = pcall(player.GetUInt32Value, player, fieldIndex)
                    local liveRaw     = (valOk and tonumber(raw)) or 0
                    local liveLower   = liveRaw % 65536
                    if storedEnchant == 0 then
                        -- Hide intent: live field must be fully zero (both halves).
                        if liveRaw ~= 0 then
                            pcall(HideEnchantVisual, player, fieldIndex)
                        end
                    elseif liveLower ~= storedEnchant then
                        pcall(SetEnchantVisual, player, fieldIndex, storedEnchant)
                    end
                    -- Repopulate enforcement cache (may have been wiped by reload).
                    UpdateHiddenEnchantCache(playerGUID, slotId, storedEnchant)
                    illusionData[#illusionData + 1] = { slotId, storedEnchant }
                else
                    -- ANTI-STALE: no DB row OR no item → send -1 sentinel so the
                    -- client AUTHORITATIVELY clears any stale illusionApplied
                    -- value for this slot.  Without this, an earlier hide(0) (or
                    -- any other prior override) would persist on the client even
                    -- though the DB intent is gone, and the next preview update
                    -- would treat enchantDirty as true and strip the weapon's
                    -- natural glow — including temp imbues in upper 16 bits like
                    -- Windfury, Flametongue, Reforger temp-slot enchants, poisons.
                    illusionData[#illusionData + 1] = { slotId, -1 }
                    -- Also ensure the enforcer cache is clean for this slot so
                    -- the periodic suppressor cannot keep zeroing the field.
                    UpdateHiddenEnchantCache(playerGUID, slotId, 1)
                end
            end
        end
        if #illusionData > 0 then
            AIO.Handle(player, "Transmog", "SetStoredIllusions", illusionData)
        end
    end
end

local function BuildPagedItemIds(records, page, pageSize)
    local result = {}
    local displayIds = {}
    local total = #records
    local resolvedPage = NormalizePage(page)

    if total <= 0 then
        return result, false, displayIds, 1, 1
    end

    local maxPage = math_max(1, math_ceil(total / pageSize))
    if resolvedPage > maxPage then
        resolvedPage = maxPage
    end

    local pageOffset = (resolvedPage > 1) and (pageSize * (resolvedPage - 1)) or 0
    local lastIndex = math_min(total, pageOffset + pageSize)
    for index = pageOffset + 1, lastIndex do
        result[#result + 1] = tonumber(records[index].itemId) or 0
        displayIds[#displayIds + 1] = tonumber(records[index].displayId) or 0
    end

    return result, total > lastIndex, displayIds, resolvedPage, maxPage
end

local function SearchAppearanceRecords(records, search)
    local normalizedSearch = string_lower(tostring(search or ""))
    local matches = {}

    if normalizedSearch == "" then
        return matches
    end

    for _, record in ipairs(records) do
        if (record.lowerName and record.lowerName:find(normalizedSearch, 1, true))
            or (record.displayIdStr and record.displayIdStr:find(normalizedSearch, 1, true)) then
            matches[#matches + 1] = record
        end
    end

    return matches
end

T.FILTER_RULES = {
    ["Cloth"] =               { class = 4, subclass = 1 },
    ["Leather"] =             { class = 4, subclass = 2 },
    ["Mail"] =                { class = 4, subclass = 3 },
    ["Plate"] =               { class = 4, subclass = 4 },
    ["Miscellaneous"] =       { class = 4, subclass = 0 },
    ["Axe"] =                 { class = 2, subclass = 0 },
    ["Axe (2H)"] =            { class = 2, subclass = 1 },
    ["Bow"] =                 { class = 2, subclass = 2 },
    ["Gun"] =                 { class = 2, subclass = 3 },
    ["Mace"] =                { class = 2, subclass = 4 },
    ["Mace (2H)"] =           { class = 2, subclass = 5 },
    ["Polearm"] =             { class = 2, subclass = 6 },
    ["Sword"] =               { class = 2, subclass = 7 },
    ["Sword (2H)"] =          { class = 2, subclass = 8 },
    ["Staff"] =               { class = 2, subclass = 10 },
    ["Fist"] =                { class = 2, subclass = 13 },
    ["Dagger"] =              { class = 2, subclass = 15 },
    ["Thrown"] =              { class = 2, subclass = 16 },
    ["Crossbow"] =            { class = 2, subclass = 18 },
    ["Wand"] =                { class = 2, subclass = 19 },
    ["Shield"] =              { class = 4, subclass = 6 },
    ["Held in Off-hand"] =    { inventoryType = 23 },
}

local function BuildRarityFilterSet(rarityFilterToken)
    if rarityFilterToken == nil then
        return nil
    end

    if type(rarityFilterToken) == "table" then
        local parsed = {}
        for _, raw in ipairs(rarityFilterToken) do
            local quality = tonumber(raw)
            if quality and quality >= 0 then
                parsed[quality] = true
            end
        end
        return parsed
    end

    rarityFilterToken = tostring(rarityFilterToken)
    if rarityFilterToken == "" then
        return nil
    end
    if rarityFilterToken == "none" then
        return {}
    end

    local parsed = {}
    for token in rarityFilterToken:gmatch("[^,]+") do
        local quality = tonumber(token)
        if quality and quality >= 0 then
            parsed[quality] = true
        end
    end
    return parsed
end

-- Filter appearance records to only include items the player's class can equip.
-- Runs server-side so the catalog never shows weapons/armor the class cannot use.
-- `slot` is the VISIBLE_SLOT number (e.g. 315) used for the Titan's Grip check.
-- Only active when T.Blizzlike_Transmog is true; otherwise returns records unchanged.
local function FilterRecordsByClassProficiency(records, player, slot)
    if not T.Blizzlike_Transmog then return records end
    local classId    = player:GetClass() or 0
    local raceId     = player:GetRace() or 0
    local playerLevel = player:GetLevel() or 1
    local maxArmor = T.CLASS_MAX_ARMOR_SUBCLASS[classId]
    local allowedWeapons = T.CLASS_ALLOWED_WEAPON_SUBCLASSES[classId]
    local isOffhand  = (slot == T.SLOT_OFFHAND)
    local hasTG = classId == 1 and player:HasSpell(T.TITANS_GRIP_SPELL_ID)
    local faction    = T.RACE_ID_TO_FACTION[raceId]  -- nil = unknown race, allow all

    -- classMask: classId 0 (unknown) maps to bit 0 which is harmless (no real class uses 0).
    local classMask = classId > 0 and 2 ^ (classId - 1) or 0

    local filtered = {}
    for _, record in ipairs(records) do
        local tpl = GetItemTemplateInfo(record.itemId)
        if tpl then
            local ok = true
            -- FlagsExtra bits: 0x01=Horde-only, 0x02=Alliance-only.
            if faction then
                local fbit = (tpl.flagsExtra or 0) % 4
                if fbit == 1 or fbit == 3 then
                    if faction ~= "Horde"    then ok = false end
                elseif fbit == 2 then
                    if faction ~= "Alliance" then ok = false end
                end
            end
            -- AllowableClass: -1 means all classes; otherwise it's a bitmask.
            -- Skip items whose bitmask doesn't include the player's class.
            local ac = tpl.allowableClass
            if ok and ac and ac ~= -1 and math_floor(ac / classMask) % 2 == 0 then
                ok = false
            end
            -- Skip items the player is too low level to equip.
            if ok and tpl.requiredLevel and tpl.requiredLevel > playerLevel then
                ok = false
            end
            -- For items with no explicit required level, estimate one from item level
            -- (roughly 0.4 * ilvl) so that e.g. ilvl 105 gear doesn't appear for a
            -- level 5 player. Skip this for max-level (80) players so that items
            -- with requiredLevel=0 and high ilvl (raid gear, custom items) are not
            -- incorrectly hidden at the level cap.
            if ok and playerLevel < 80 and (not tpl.requiredLevel or tpl.requiredLevel == 0) and tpl.itemLevel and tpl.itemLevel > 0 then
                local estimatedLevel = math_max(1, math_floor(tpl.itemLevel * 0.4))
                if estimatedLevel > playerLevel then
                    ok = false
                end
            end
            if ok and tpl.class == 4 then
                if tpl.subclass >= 1 and tpl.subclass <= 4 then
                    if maxArmor and tpl.subclass > maxArmor then ok = false end
                elseif tpl.subclass == 6 then
                    if not T.CLASS_SHIELD_ALLOWED[classId] then ok = false end
                end
            elseif tpl.class == 2 then
                if not allowedWeapons or not allowedWeapons[tpl.subclass] then
                    ok = false
                elseif isOffhand and tpl.inventoryType == 17 then
                    -- 2H in off-hand only for Warriors with Titan's Grip.
                    if not hasTG then ok = false end
                end
                -- Note: 2H in main-hand while off-hand is occupied is NOT filtered
                -- here — those appearances remain visible so the player can see them.
                -- The apply-time check in PlayerCanTransmogItem rejects the equip
                -- and shows "You must hide your off-hand..." instead.
            end
            if ok then filtered[#filtered + 1] = record end
        else
            filtered[#filtered + 1] = record
        end
    end
    return filtered
end

local function FilterAppearanceRecords(records, subclassFilter, rarityFilter)
    -- Fast path: no filters at all.
    if (not subclassFilter or subclassFilter == "") and rarityFilter == nil then
        return records
    end

    -- Empty rarity filter (user unchecked everything) means "show nothing".
    if rarityFilter and not next(rarityFilter) then
        return {}
    end

    -- A subclass filter is supplied but unknown to us.  Previously we returned
    -- the unfiltered list, which silently bypassed the rarity filter too.  Now
    -- we still honour the rarity filter even if the subclass rule is unknown.
    local hasSubclass = subclassFilter and subclassFilter ~= ""
    local rule = hasSubclass and T.FILTER_RULES[tostring(subclassFilter)] or nil
    local subclassRuleUnknown = hasSubclass and not rule

    local filtered = {}
    for _, record in ipairs(records or {}) do
        local itemTemplate = GetItemTemplateInfo(record.itemId)
        if itemTemplate then
            local matches = true
            if rule then
                if rule.class ~= nil and tonumber(itemTemplate.class) ~= tonumber(rule.class) then
                    matches = false
                end
                if matches and rule.subclass ~= nil and tonumber(itemTemplate.subclass) ~= tonumber(rule.subclass) then
                    matches = false
                end
                if matches and rule.inventoryType ~= nil and tonumber(itemTemplate.inventoryType) ~= tonumber(rule.inventoryType) then
                    matches = false
                end
            end
            -- ALWAYS enforce the rarity filter when one is provided, even if
            -- the subclass rule is unknown / missing.  This is the hardening
            -- fix: a malformed subclass token must not allow Poor/Common items
            -- through when the user explicitly asked for "Artifact only".
            if matches and rarityFilter and not rarityFilter[tonumber(itemTemplate.quality) or 0] then
                matches = false
            end
            if matches then
                filtered[#filtered + 1] = record
            end
        end
    end

    return filtered
end

-- Defensive helper: re-apply the rarity filter at the very end of any slot
-- pipeline, after all other transforms.  Cheap O(n) safety net so a future
-- change to FilterAppearanceRecords / proficiency filter can never let an
-- item of the wrong quality leak into the client list.
local function EnforceRarityFilter(records, rarityFilter)
    if not rarityFilter then return records end
    if not next(rarityFilter) then return {} end
    local filtered = {}
    for _, rec in ipairs(records or {}) do
        local tpl = GetItemTemplateInfo(rec.itemId)
        if tpl and rarityFilter[tonumber(tpl.quality) or 0] then
            filtered[#filtered + 1] = rec
        end
    end
    return filtered
end

function TransmogHandlers.SetCurrentSlotItemPage(player, slot, itemId, pageSize, requestToken, subclassFilter, rarityFilterToken)
    slot = NormalizeVisibleSlot(slot)
    itemId = tonumber(itemId) or 0
    pageSize = NormalizePageSize(pageSize)

    if not slot or itemId <= 0 then
        AIO.Handle(player, "Transmog", "SetCurrentSlotItemPageClient", slot or 0, 1, requestToken)
        return
    end

    local accountGUID = player:GetAccountId()
    local resolvedItemId = T.INVENTORY_TYPE_MAP[slot] and GetUnlockedAppearanceItemId(accountGUID, slot, itemId) or nil
    if not resolvedItemId or resolvedItemId <= 0 then
        AIO.Handle(player, "Transmog", "SetCurrentSlotItemPageClient", slot, 1, requestToken)
        return
    end

    local cache = GetAccountAppearanceCache(accountGUID)
    local records = FilterRecordsByClassProficiency(
        FilterAppearanceRecords(cache.dedupedBySlot[slot] or {}, subclassFilter, BuildRarityFilterSet(rarityFilterToken)),
        player, slot)
    local itemIndex = nil
    for index, record in ipairs(records) do
        if tonumber(record.itemId) == resolvedItemId then
            itemIndex = index
            break
        end
    end
    local page = itemIndex and (math_floor((itemIndex - 1) / pageSize) + 1) or 1
    AIO.Handle(player, "Transmog", "SetCurrentSlotItemPageClient", slot, page, requestToken)
end

local function resolveSlotItemArgs(slot, page, pageSize, requestToken, subclassFilter, rarityFilterToken, clientExcludeIds, hideNoLevel)
    slot = NormalizeVisibleSlot(slot)
    page = NormalizePage(page)
    if requestToken == nil then
        requestToken = pageSize
        pageSize = SLOTS
    end
    pageSize = NormalizePageSize(pageSize)
    if not T.INVENTORY_TYPE_MAP[slot] then return end
    if subclassFilter ~= nil then
        subclassFilter = tostring(subclassFilter)
        if subclassFilter == "" then
            subclassFilter = nil
        end
    end
    if type(rarityFilterToken) == "table" and clientExcludeIds == nil then
        clientExcludeIds = rarityFilterToken
        rarityFilterToken = nil
    end
    local rarityFilter = BuildRarityFilterSet(rarityFilterToken)
    -- Build a fast lookup of item IDs the client has marked as unloadable.
    -- Cap at 2000 entries to match the client-side BLACKLIST_MAX_ENTRIES constant
    -- and prevent a malicious client from sending an unbounded list.
    local excludeSet = nil
    if type(clientExcludeIds) == "table" and #clientExcludeIds > 0 then
        excludeSet = {}
        local limit = math_min(#clientExcludeIds, 2000)
        for i = 1, limit do
            local id = tonumber(clientExcludeIds[i])
            if id and id > 0 then
                excludeSet[id] = true
            end
        end
    end
    hideNoLevel = hideNoLevel == true or hideNoLevel == 1
    return slot, page, pageSize, requestToken, subclassFilter, rarityFilter, excludeSet, hideNoLevel
end

-- Subclass IDs for weapons that require inventoryType 17 (two-handed).
T.WEAPON_2H_SUBCLASSES = { [1]=true, [5]=true, [6]=true, [8]=true, [10]=true }

-- Returns true when a common off-hand conflict exists for this slot.
-- hasTG (Titan's Grip) exempts Warriors from all 2H restrictions.
local function OffhandConflictsMainhand(player, slot)
    if not T.Blizzlike_Transmog then return false end
    if slot ~= T.SLOT_MAINHAND then return false end
    local classId = player:GetClass()
    if classId == 1 and player:HasSpell(T.TITANS_GRIP_SPELL_ID) then return false end
    return GetEquippedInventoryType(player, T.EQUIP_SLOT_OFFHAND) ~= nil
end

-- Returns a warning string when the current equipment makes a slot impossible
-- to apply. For main-hand "All" filters, 2H records are silently excluded from
-- results instead of blocking the whole list.
local function GetSlotEquipWarning(player, slot, subclassFilter)
    if not T.Blizzlike_Transmog then return nil end
    if SlotMissingEquippedItem(player, slot) and slot ~= T.SLOT_OFFHAND then
        return "Сначала наденьте предмет в эту ячейку."
    end
    if OffhandSlotMissingEquipment(player, slot) then
        return "Сначала наденьте предмет для левой руки или щит."
    end
    if not OffhandConflictsMainhand(player, slot) then return nil end
    if not subclassFilter or subclassFilter == "" then return nil end
    local rule = T.FILTER_RULES[tostring(subclassFilter)]
    if rule and rule.class == 2 and T.WEAPON_2H_SUBCLASSES[rule.subclass] then
        return "Облик двуручного оружия нельзя применить, пока в левой руке есть предмет, и нельзя наложить на одноручное оружие."
    end
    return nil
end

-- Removes records whose item has inventoryType 17 (two-handed weapon).
-- Used when browsing the main-hand slot with an off-hand equipped and no
-- subclass filter active, so 2H appearances are silently excluded.
local function Exclude2HWeaponRecords(records)
    local filtered = {}
    for _, rec in ipairs(records) do
        local tpl = GetItemTemplateInfo(rec.itemId)
        if tpl and tonumber(tpl.inventoryType) ~= 17 then
            filtered[#filtered + 1] = rec
        end
    end
    return filtered
end

function TransmogHandlers.SetCurrentSlotItemIds(player, slot, page, pageSize, requestToken, subclassFilter, rarityFilterToken, clientExcludeIds, hideNoLevel)
    local rSlot, rPage, rPageSize, rToken, rSubclass, rRarity, excludeSet, rHideNoLevel = resolveSlotItemArgs(slot, page, pageSize, requestToken, subclassFilter, rarityFilterToken, clientExcludeIds, hideNoLevel)
    if not rSlot then return end
    local cache = GetAccountAppearanceCache(player:GetAccountId())
    local records = FilterRecordsByClassProficiency(
        FilterAppearanceRecords(cache.dedupedBySlot[rSlot] or {}, rSubclass, rRarity),
        player, rSlot)
    if rHideNoLevel then
        local filtered = {}
        for _, rec in ipairs(records) do
            local tpl = GetItemTemplateInfo(rec.itemId)
            if not tpl or (tpl.requiredLevel ~= 0 or tpl.itemLevel > 1) then
                filtered[#filtered + 1] = rec
            end
        end
        records = filtered
    end
    if excludeSet then
        local filtered = {}
        for _, rec in ipairs(records) do
            if not excludeSet[tonumber(rec.itemId) or 0] then
                filtered[#filtered + 1] = rec
            end
        end
        records = filtered
    end
    if T.Blizzlike_Transmog and OffhandSlotMissingEquipment(player, rSlot) then
        records = {}
    end
    -- Blizzlike: hide browse list for slots where the player has nothing equipped.
    if SlotMissingEquippedItem(player, rSlot) then
        records = {}
    end
    -- When "All" is shown on main-hand with an off-hand equipped, silently strip
    -- 2H items so the list stays useful rather than being blocked entirely.
    if (not rSubclass or rSubclass == "") and OffhandConflictsMainhand(player, rSlot) then
        records = Exclude2HWeaponRecords(records)
    end
    -- Hardening: re-enforce the rarity filter as a final safety net so a bug
    -- in any earlier stage can never leak items of the wrong quality.
    records = EnforceRarityFilter(records, rRarity)
    local ids, hasMore, displayIds, resolvedPage, maxPage = BuildPagedItemIds(records, rPage, rPageSize)
    AIO.Handle(player, "Transmog", "InitTab", ids, resolvedPage, hasMore, rSlot, rToken, displayIds, maxPage, GetSlotEquipWarning(player, rSlot, rSubclass))
end

-- Sends all unlocked appearance IDs to the client for border/tooltip display.
-- Reads from the in-memory cache; no DB query.
function TransmogHandlers.GetAllUnlockedItemIds(player)
    local cache = GetAccountAppearanceCache(player:GetAccountId())
    -- Packed once when the account appearance cache is built.  Reusing the
    -- payload avoids rebuilding a large string on login/open/refresh paths.
    AIO.Handle(player, "Transmog", "AllUnlockedItemIds", cache.unlockedItemIdsCsv or "")
end

-- Pre-scan endpoint: returns the COMPLETE filtered itemId list for a slot
-- so the client can DBC-check every id once and seed its blacklist BEFORE
-- the first paged request.  This keeps totalPages accurate from the start
-- (no more "Page 7 / 11" then converging to 10 after fast scrolling).
-- Compact CSV transport; no paging, no displayIds, no exclude (client merges
-- this with its existing blacklist locally).
function TransmogHandlers.GetAllItemIdsForSlot(player, slot, subclassFilter, rarityFilterToken, hideNoLevel, requestToken)
    slot = NormalizeVisibleSlot(slot)
    if not slot then return end
    local rarityFilter = BuildRarityFilterSet(rarityFilterToken)
    local cache = GetAccountAppearanceCache(player:GetAccountId())
    local records = FilterRecordsByClassProficiency(
        FilterAppearanceRecords(cache.dedupedBySlot[slot] or {}, subclassFilter, rarityFilter),
        player, slot)
    if hideNoLevel then
        local filtered = {}
        for _, rec in ipairs(records) do
            local tpl = GetItemTemplateInfo(rec.itemId)
            if not tpl or (tpl.requiredLevel ~= 0 or tpl.itemLevel > 1) then
                filtered[#filtered + 1] = rec
            end
        end
        records = filtered
    end
    if T.Blizzlike_Transmog and OffhandSlotMissingEquipment(player, slot) then
        records = {}
    end
    if SlotMissingEquippedItem(player, slot) then
        records = {}
    end
    if (not subclassFilter or subclassFilter == "") and OffhandConflictsMainhand(player, slot) then
        records = Exclude2HWeaponRecords(records)
    end
    -- Hardening: belt-and-suspenders rarity enforcement.
    records = EnforceRarityFilter(records, rarityFilter)
    local parts = {}
    for i = 1, #records do
        local iid = tonumber(records[i].itemId)
        if iid and iid > 0 then parts[#parts + 1] = iid end
    end
    AIO.Handle(player, "Transmog", "AllItemIdsForSlot", slot, tconcat(parts, ","), tonumber(requestToken) or 0)
end

function TransmogHandlers.SetSearchCurrentSlotItemIds(player, slot, page, search, pageSize, requestToken, subclassFilter, rarityFilterToken, clientExcludeIds, hideNoLevel)
    if not search or search == '' then return end
    search = tostring(search):sub(1, 128)  -- cap search string length
    local rSlot, rPage, rPageSize, rToken, rSubclass, rRarity, excludeSet, rHideNoLevel = resolveSlotItemArgs(slot, page, pageSize, requestToken, subclassFilter, rarityFilterToken, clientExcludeIds, hideNoLevel)
    if not rSlot then return end
    local cache = GetAccountAppearanceCache(player:GetAccountId())
    local matches = SearchAppearanceRecords(
        FilterRecordsByClassProficiency(
            FilterAppearanceRecords(cache.dedupedBySlot[rSlot] or {}, rSubclass, rRarity),
            player, rSlot),
        search)
    if rHideNoLevel then
        local filtered = {}
        for _, rec in ipairs(matches) do
            local tpl = GetItemTemplateInfo(rec.itemId)
            if not tpl or (tpl.requiredLevel ~= 0 or tpl.itemLevel > 1) then
                filtered[#filtered + 1] = rec
            end
        end
        matches = filtered
    end
    if excludeSet then
        local filtered = {}
        for _, rec in ipairs(matches) do
            if not excludeSet[tonumber(rec.itemId) or 0] then
                filtered[#filtered + 1] = rec
            end
        end
        matches = filtered
    end
    if T.Blizzlike_Transmog and OffhandSlotMissingEquipment(player, rSlot) then
        matches = {}
    end
    if (not rSubclass or rSubclass == "") and OffhandConflictsMainhand(player, rSlot) then
        matches = Exclude2HWeaponRecords(matches)
    end
    -- Hardening: belt-and-suspenders rarity enforcement.
    matches = EnforceRarityFilter(matches, rRarity)
    local ids, hasMore, displayIds, resolvedPage, maxPage = BuildPagedItemIds(matches, rPage, rPageSize)
    AIO.Handle(player, "Transmog", "InitTab", ids, resolvedPage, hasMore, rSlot, rToken, displayIds, maxPage, GetSlotEquipWarning(player, rSlot, rSubclass))
end

function TransmogHandlers.SetEquipmentTransmogInfo(player, slot, currentTooltipSlot)
    slot = NormalizeVisibleSlot(slot)
    if not slot then return end

    local transmog = CharDBQuery(string_format(
        "SELECT 1 FROM character_transmog WHERE player_guid = %d AND slot = %d AND item IS NOT NULL AND item != 0 LIMIT 1",
        player:GetGUIDLow(), slot
    ))

    if transmog then
        AIO.Handle(player, "Transmog", "SetEquipmentTransmogInfoClient", currentTooltipSlot)
    end
end

-- ---------------------------------------------------------------------------
-- ClearAllAccountTransmog
-- Wipes every unlocked appearance and every applied transmog for every
-- character on the requesting player's account.
-- Safety: the account ID is derived server-side from the authenticated player
-- object; no client-supplied identifier is trusted.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- RemoveUnlockedAppearance
-- Removes a single item from this account's unlocked appearance collection.
-- Safety: account ID is derived server-side; itemId is validated to belong to
-- the requesting account before deletion — no other account can be affected.
-- ---------------------------------------------------------------------------
function TransmogHandlers.RemoveUnlockedAppearance(player, itemId)
    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 or math_floor(itemId) ~= itemId then
        AIO.Handle(player, "Transmog", "RemoveUnlockedAppearanceComplete", false, 0)
        return
    end
    itemId = math_floor(itemId)

    local accountGUID = player:GetAccountId()

    -- Verify ownership: the item must exist in THIS account's appearances.
    -- This check prevents a malformed client call from deleting a different
    -- account's data even if somehow account IDs were spoofed.
    local check = AuthDBQuery(string_format(
        "SELECT 1 FROM account_transmog WHERE account_id = %d AND unlocked_item_id = %d LIMIT 1",
        accountGUID, itemId
    ))
    if not check then
        AIO.Handle(player, "Transmog", "RemoveUnlockedAppearanceComplete", false, itemId)
        return
    end

    AuthDBQuery(string_format(
        "DELETE FROM account_transmog WHERE account_id = %d AND unlocked_item_id = %d",
        accountGUID, itemId
    ))

    InvalidateAccountCaches(accountGUID)

    AIO.Handle(player, "Transmog", "RemoveUnlockedAppearanceComplete", true, itemId)
end
-- ---------------------------------------------------------------------------

function TransmogHandlers.ClearAllAccountTransmog(player)
    local accountGUID = player:GetAccountId()
    local playerGUID  = player:GetGUIDLow()

    -- Step 1: restore the online player's visual appearance from the stored
    -- real_item values before we delete anything, so their model immediately
    -- shows their actual equipped gear rather than the transmog overlay.
    local activeTx = CharDBQuery(string_format(
        "SELECT slot, real_item FROM character_transmog WHERE player_guid = %d AND item IS NOT NULL",
        playerGUID
    ))
    if activeTx then
        repeat
            local slot     = tonumber(activeTx:GetUInt32(0))
            local realItem = tonumber(activeTx:GetUInt32(1)) or 0
            if slot then
                SetVisibleItemValue(player, slot, realItem)
            end
        until not activeTx:NextRow()
    end

    -- Step 2: collect every character GUID that belongs to this account so we
    -- can wipe their character_transmog rows in one query.
    local charGuids = { playerGUID }
    local otherChars = CharDBQuery(string_format(
        "SELECT guid FROM characters WHERE account = %d AND guid != %d",
        accountGUID, playerGUID
    ))
    if otherChars then
        repeat
            local guid = tonumber(otherChars:GetUInt32(0))
            if guid then
                charGuids[#charGuids + 1] = guid
            end
        until not otherChars:NextRow()
    end

    -- Step 3: delete all per-character transmog slot data for the account.
    CharDBQuery(string_format(
        "DELETE FROM character_transmog WHERE player_guid IN (%s)",
        tconcat(charGuids, ",")
    ))

    -- Step 4: re-initialise rows for the online player so the system treats
    -- every slot as "no transmog" (item = NULL) from this point forward.
    InitializePlayerTransmog(playerGUID)

    -- Step 5: wipe every unlocked appearance for this account.
    AuthDBQuery(string_format(
        "DELETE FROM account_transmog WHERE account_id = %d",
        accountGUID
    ))

    -- Step 6: purge all server-side in-memory caches for this account.
    InvalidateAccountCaches(accountGUID)

    -- Step 7: tell the client the wipe is complete so it can re-sync.
    AIO.Handle(player, "Transmog", "ClearAllAccountTransmogComplete")
end

-- ---------------------------------------------------------------------------
-- Quest-reward appearance unlock
-- When a player completes a quest that offers item rewards (choose-one or
-- guaranteed), unlock the transmog appearance for ALL reward items — not
-- just the one the player picked.  This means you never miss an appearance
-- from an exclusive-choice quest.
-- ---------------------------------------------------------------------------
local function UnlockQuestRewardAppearances(player, questId)
    local q = WorldDBQuery(string_format(
        "SELECT RewardChoiceItemID1, RewardChoiceItemID2, RewardChoiceItemID3, "
        .. "RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6, "
        .. "RewardItem1, RewardItem2, RewardItem3, RewardItem4 "
        .. "FROM quest_template WHERE ID = %d LIMIT 1",
        questId
    ))
    if not q then return end

    local accountGUID = player:GetAccountId()
    local values, seenItemIds = {}, {}

    for col = 0, 9 do
        local itemId = tonumber(q:GetUInt32(col)) or 0
        if itemId > 0 and not seenItemIds[itemId] then
            local info = GetItemTemplateInfo(itemId)
            if info and info.displayId > 0 and IsTransmoggableItem(info.class, info.inventoryType) then
                seenItemIds[itemId] = true
                values[#values + 1] = string_format("(%d, %d, %d, %d, '%s')",
                    accountGUID, itemId, info.displayId, info.inventoryType,
                    EscapeString(info.name))
            end
        end
    end

    if #values > 0 then
        AuthDBQuery(
            "INSERT IGNORE INTO account_transmog "
            .. "(account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES "
            .. tconcat(values, ", ")
        )
        InvalidateAccountCaches(accountGUID)
    end
end

function Transmog_OnCompleteQuest(event, player, quest)
    if not player or not quest then return end
    if player.IsBot and player:IsBot() then return end
    local questId = quest:GetId()
    if not questId or questId <= 0 then return end
    UnlockQuestRewardAppearances(player, questId)
end

-- Retroactive scan: unlock appearances for every quest the player has already
-- completed. Runs once at login so existing characters get credit for past
-- quest rewards.
ScanCompletedQuestsForTransmogUnlocks = function(player)
    local playerGUID = player:GetGUIDLow()

    local function markDone()
        CharDBQuery(string_format(
            "INSERT IGNORE INTO transmog_settings (`key`, `value`) VALUES ('quest_scan_%d', '1')",
            playerGUID
        ))
        T.QUEST_SCAN_DONE_CACHE[playerGUID] = true
    end

    -- Guard 1: in-memory cache — zero DB cost on re-login within the same session.
    if T.QUEST_SCAN_DONE_CACHE[playerGUID] then return 0 end

    -- Guard 2: persistent marker — skip if this character's scan completed in a
    -- previous session.  The key is small so transmog_settings never accumulates
    -- more than one row per character.
    local marker = CharDBQuery(string_format(
        "SELECT 1 FROM transmog_settings WHERE `key` = 'quest_scan_%d' LIMIT 1",
        playerGUID
    ))
    if marker then
        T.QUEST_SCAN_DONE_CACHE[playerGUID] = true
        return 0
    end

    local rows = CharDBQuery(string_format(
        "SELECT quest FROM character_queststatus_rewarded WHERE guid = %d",
        playerGUID
    ))
    if not rows then
        markDone()
        return 0
    end

    local questIds = {}
    repeat
        local qid = tonumber(rows:GetUInt32(0))
        if qid and qid > 0 then questIds[#questIds + 1] = qid end
    until not rows:NextRow()
    if #questIds == 0 then
        markDone()
        return 0
    end

    local accountGUID = player:GetAccountId()
    local values, seenItemIds = {}, {}

    -- Process quests in chunks to avoid oversized IN clauses.
    local chunk = {}
    for chunkStart = 1, #questIds, T.BULK_CHUNK_SIZE do
        local chunkEnd = math_min(chunkStart + T.BULK_CHUNK_SIZE - 1, #questIds)
        local chunkLen = 0
        for i = chunkStart, chunkEnd do
            chunkLen = chunkLen + 1
            chunk[chunkLen] = questIds[i]
        end
        for i = chunkLen + 1, #chunk do chunk[i] = nil end

        local q = WorldDBQuery(string_format(
            "SELECT ID, RewardChoiceItemID1, RewardChoiceItemID2, RewardChoiceItemID3, "
            .. "RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6, "
            .. "RewardItem1, RewardItem2, RewardItem3, RewardItem4 "
            .. "FROM quest_template WHERE ID IN (%s)",
            tconcat(chunk, ",")
        ))
        if q then
            -- First pass: collect all reward item IDs so we can bulk-warm the cache
            -- and avoid N+1 GetItemTemplateInfo queries inside the second pass.
            local questRewards = {}
            local warmIds = {}
            repeat
                local row = {}
                for col = 1, 10 do
                    local itemId = tonumber(q:GetUInt32(col)) or 0
                    row[col] = itemId
                    if itemId > 0 then
                        warmIds[#warmIds + 1] = { itemId = itemId }
                    end
                end
                questRewards[#questRewards + 1] = row
            until not q:NextRow()

            if #warmIds > 0 then
                BulkEnsureItemTemplates(warmIds)
            end

            -- Second pass: process from collected data (no extra DB query).
            for _, row in ipairs(questRewards) do
                for col = 1, 10 do
                    local itemId = row[col]
                    if itemId > 0 and not seenItemIds[itemId] then
                        local info = GetItemTemplateInfo(itemId)
                        if info and info.displayId > 0 and IsTransmoggableItem(info.class, info.inventoryType) then
                            seenItemIds[itemId] = true
                            values[#values + 1] = string_format("(%d, %d, %d, %d, '%s')",
                                accountGUID, itemId, info.displayId, info.inventoryType,
                                EscapeString(info.name))
                        end
                    end
                end
            end
        end
    end

    if #values > 0 then
        AuthDBQuery(
            "INSERT IGNORE INTO account_transmog "
            .. "(account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES "
            .. tconcat(values, ", ")
        )
        InvalidateAccountCaches(accountGUID)
    end

    -- Mark scan as permanently done for this character so future logins skip it.
    markDone()
    return #values
end
-- ---------------------------------------------------------------------------

RegisterPlayerEvent(1, Transmog_OnCharacterCreate)
RegisterPlayerEvent(2, Transmog_OnCharacterDelete)
RegisterPlayerEvent(51, Transmog_OnLootItem)
RegisterPlayerEvent(52, Transmog_OnLootItem)
RegisterPlayerEvent(53, Transmog_OnLootItem)
RegisterPlayerEvent(56, Transmog_OnLootItem)
RegisterPlayerEvent(29, Transmog_OnEquipItem)
RegisterPlayerEvent(54, Transmog_OnCompleteQuest)
pcall(RegisterPlayerEvent, T.PLAYER_EVENT_ON_AFTER_SET_VISIBLE_ITEM_SLOT, Transmog_OnAfterSetVisibleItemSlot)

-- Event 4 = PLAYER_EVENT_ON_LOGOUT.
pcall(RegisterPlayerEvent, 4, function(event, player)
    if not player then return end
    if player.IsBot and player:IsBot() then return end
    -- Remove from hidden-enchant enforcement cache so the periodic timer
    -- doesn't hold a stale reference after the player has logged out.
    T.HIDDEN_ENCHANT_PLAYERS[player:GetGUIDLow()] = nil
    T.PROVISION_TEST_PLAYERS[player:GetGUIDLow()] = nil
end)

-- ── Hidden-enchant periodic enforcer ──────────────────────────────────────
-- Belt-and-suspenders: every 3 seconds, for any player who has "No Enchant"
-- (enchant_id = 0) stored for a weapon slot, check whether an external source
-- (shaman imbue, real enchant, flask coating, etc.) wrote a non-zero visual
-- back into the field and, if so, immediately zero it out again.
-- This fires regardless of whether T.PLAYER_EVENT_ON_AFTER_SET_VISIBLE_ITEM_SLOT
-- was triggered by the enchant application, making suppression bulletproof.
if CreateLuaEvent and GetPlayersInWorld then
    CreateLuaEvent(function()
        if not next(T.HIDDEN_ENCHANT_PLAYERS) then return end
        local online = GetPlayersInWorld()
        if not online then return end
        for _, player in ipairs(online) do
            if player and player.IsInWorld and player:IsInWorld() then
                local guid  = player:GetGUIDLow()
                local slots = T.HIDDEN_ENCHANT_PLAYERS[guid]
                if slots then
                    for slotId in pairs(slots) do
                        -- SELF-HEAL: verify the DB row still exists with
                        -- enchant_id = 0.  If it doesn't, this cache entry is
                        -- stale (e.g. from a prior session, Eluna reload, or
                        -- direct SQL edit) — drop it instead of zeroing the
                        -- field, which would keep suppressing the natural
                        -- weapon glow and temp imbues (Windfury, Flametongue,
                        -- Reforger temp-slot enchants, poisons) forever.
                        local dbOk = false
                        local row = CharDBQuery(string_format(
                            "SELECT 1 FROM character_illusion WHERE player_guid = %d AND slot_id = %d AND enchant_id = 0 LIMIT 1",
                            guid, slotId))
                        if row then dbOk = true end

                        if not dbOk then
                            slots[slotId] = nil
                            if not next(slots) then
                                T.HIDDEN_ENCHANT_PLAYERS[guid] = nil
                            end
                        else
                            local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
                            if equipSlot then
                                local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
                                if ok and item then
                                    local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)
                                    -- Wipe BOTH halves so temp imbues (Windfury, Flametongue,
                                    -- Reforger temp-slot enchants, poisons, etc.) don't keep
                                    -- glowing and defeat the user's Hide intent.
                                    pcall(HideEnchantVisual, player, fieldIndex)
                                end
                            end
                        end
                    end
                end
            end
        end
    end, 3000, 0)  -- 3-second interval, repeat indefinitely
end
-- ──────────────────────────────────────────────────────────────────────────

-- Event 3 = PLAYER_EVENT_ON_LOGIN: fires during server-side login AFTER items
-- are equipped but BEFORE the player is visible to other clients.  This ensures
-- transmog overrides and hidden items are baked into the initial create packet
-- so other players (and the logging-in player) never see the un-transmogged look.
RegisterPlayerEvent(3, function(event, player)
    if not player then return end
    Transmog_Load(player)
end)

-- ---------------------------------------------------------------------------
-- .transmog free / .transmog cost  (GM-only)
-- Toggles T.transmog_cost at runtime and pushes the change to all
-- online players so their UI updates immediately.
-- ---------------------------------------------------------------------------
RegisterPlayerEvent(42, function(_, player, command)
    if not player or not command or command == "" then return end
    local head, tail = command:match("^%.?([%w_%.%-]+)%s*(.*)$")
    if not head then return end
    head = head:lower()
    if head ~= "transmog" then return end

    local sub = (tail or ""):lower():match("^(%S+)")
    if not sub or sub == "" then
        if player:IsGM() then
            local mode = T.transmog_cost and "cost" or "free"
            player:SendBroadcastMessage("|cffffcc00[Трансмогрификация]|r Команды (только для ГМ):")
            player:SendBroadcastMessage("  .transmog free  — бесплатно (сейчас: |cff00ff00" .. mode .. "|r)")
            player:SendBroadcastMessage("  .transmog cost  — включить плату золотом")
        end
        return false
    end
    if sub ~= "free" and sub ~= "cost" and sub ~= "wipeillusions" and sub ~= "illusion" then
        -- Unrecognised subcommand — don't consume
        return
    end

    -- .transmog illusion <slot_id> <enchant_id>
    -- Client fallback transport for weapon illusions.  This deliberately uses
    -- the same authoritative server apply path as AIO so cost, persistence,
    -- validation, and visual refresh behavior stay identical.
    if sub == "illusion" then
        local slotId, enchantId = (tail or ""):match("^%S+%s+([%d%-]+)%s+([%d%-]+)")
        slotId = tonumber(slotId)
        enchantId = tonumber(enchantId)
        if slotId and enchantId and TransmogHandlers and TransmogHandlers.ApplyWeaponIllusion then
            TransmogHandlers.ApplyWeaponIllusion(player, slotId, enchantId)
        else
            AIO.Handle(player, "Transmog", "WeaponIllusionError", slotId or 0, "Неверный запрос иллюзии.")
        end
        return false
    end

    -- .transmog wipeillusions  — manually purge ALL stored weapon-illusion
    -- intents for the calling player (both Main Hand and Off-hand).  Use this
    -- as an escape hatch when stale rows make the preview keep showing the
    -- weapon as hidden even after Revert All.  Self-service, no GM required.
    if sub == "wipeillusions" then
        local guid = player:GetGUIDLow()
        CharDBQuery(string_format(
            "DELETE FROM character_illusion WHERE player_guid = %d", guid))
        T.HIDDEN_ENCHANT_PLAYERS[guid] = nil
        -- Restore the natural lower-16 enchant on both weapon slots so the
        -- visible field matches the underlying item state immediately.
        for _, slotId in ipairs({ T.SLOT_MAINHAND, T.SLOT_OFFHAND }) do
            local equipSlot = T.VISIBLE_SLOT_TO_EQUIPMENT_SLOT[slotId]
            if equipSlot then
                local ok, item = pcall(player.GetItemByPos, player, 255, equipSlot)
                if ok and item then
                    local permEnchant = 0
                    local okE, raw = pcall(item.GetEnchantmentId, item, 0)
                    if okE and raw then permEnchant = tonumber(raw) or 0 end
                    local fieldIndex = PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (equipSlot * 2)
                    pcall(SetEnchantVisual, player, fieldIndex, permEnchant)
                end
            end
        end
        -- Push fresh authoritative state so the addon clears its cached
        -- illusionApplied/illusionEnchants for both slots immediately.
        if TransmogHandlers and TransmogHandlers.SetTransmogItemIds then
            TransmogHandlers.SetTransmogItemIds(player)
        end
        player:SendBroadcastMessage("|cff00ff00[Трансмогрификация]|r Иллюзии оружия сброшены. Откройте вкладку трансмогрификации, чтобы проверить.")
        return false
    end

    if not player:IsGM() then
        player:SendBroadcastMessage("|cffff5555[Трансмогрификация]|r Команда доступна только ГМ.")
        return false
    end

    local wantEnabled = (sub == "cost")
    if T.transmog_cost == wantEnabled then
        player:SendBroadcastMessage("|cffffcc00[Трансмогрификация]|r Режим уже " .. (wantEnabled and "cost" or "free") .. ".")
        return false
    end

    T.transmog_cost = wantEnabled

    -- Persist to DB so the toggle survives restarts.
    CharDBQuery(string_format(
        "INSERT INTO transmog_settings (`key`, `value`) VALUES ('cost_enabled', '%s') ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)",
        wantEnabled and "1" or "0"
    ))

    player:SendBroadcastMessage("|cff00ff00[Transmog]|r " .. (wantEnabled and "Плата золотом ВКЛЮЧЕНА." or "Плата золотом ОТКЛЮЧЕНА — трансмогрификация бесплатна."))

    -- Push updated cost info to every online player so the UI refreshes.
    if GetPlayersInWorld then
        local onlinePlayers = GetPlayersInWorld() or {}
        for _, p in ipairs(onlinePlayers) do
            AIO.Handle(p, "Transmog", "TransmogCostInfo", T.transmog_cost, T.TRANSMOG_COST_PER_SLOT, T.TRANSMOG_RARITY_MULTIPLIER, T.Blizzlike_Transmog, p:GetGMRank(), T.allow_reset_all_transmog)
        end
    end

    return false
end)

-- ---------------------------------------------------------------------------
-- .ab learn all  (GM-only)
-- Bulk-unlocks every transmoggable item in item_template for the calling
-- player's account.  Skips:
--   * non-armor / non-weapon (class != 2 and != 4)
--   * items with no displayid (invisible / placeholder rows)
--   * items with UNUSABLE inventory types (bag, ammo, etc.)
--   * items with quality 0 (Poor) — almost universally test/junk/broken
--   * items whose name matches a known test / placeholder / debug pattern
--     ("TEST", "OLD", "QA", "DEPRECATED", "MONSTER", "(NYI)", "PH ", etc.)
--   * items flagged ITEM_FLAGS_EXTRA_INTERNAL (FlagsExtra bit 0x4) — Blizzard's
--     own marker for hidden/internal items
-- Performance:
--   * Pages item_template by entry-id ranges (10000 per page) so we never
--     materialise more than ~10k rows in Lua at once.
--   * Defers each page through CreateLuaEvent (one tick gap) so the world
--     thread isn't blocked for the entire scan; players don't lag during it.
--   * Bulk INSERTs of 500 rows per query, INSERT IGNORE so existing unlocks
--     are preserved and one bad row never aborts the operation.
-- ---------------------------------------------------------------------------

-- Compiled once.  Names matching ANY of these (case-insensitive) are skipped.
T.LEARNALL_BAD_NAME_PATTERNS = T.LEARNALL_BAD_NAME_PATTERNS or {
    "test",  "qa%s",     "%(test%)",   "deprecated", "deprc",
    "%(old%)", "%(unused%)", "%(nyi%)",  "monster%s", "internal",
    "placeholder", "^ph%s",   "%(ph%)",  "debug",     "%[ph%]",
    "%[unused%]", "%(deprecated%)",     "_old",      "dnt",
    "do not use",  "donotuse",          "scrapped",  "removed",
}

local function IsBadAppearanceName(name)
    if not name or name == "" then return true end  -- nameless rows are usually broken
    local lower = name:lower()
    for _, pat in ipairs(T.LEARNALL_BAD_NAME_PATTERNS) do
        if lower:find(pat) then return true end
    end
    return false
end

local function AB_LearnAllAppearances(player)
    local accountGUID = player:GetAccountId()
    local playerGUID  = player:GetGUIDLow()

    local PAGE        = 10000   -- entry-id range per page
    local INSERT_CHUNK = 500    -- rows per bulk INSERT
    local startEntry  = 0
    local maxEntry    = nil

    -- Resolve highest entry once so we know when to stop.
    local maxQ = WorldDBQuery("SELECT MAX(entry) FROM item_template")
    if maxQ then maxEntry = tonumber(maxQ:GetUInt32(0)) end
    if not maxEntry or maxEntry <= 0 then
        player:SendBroadcastMessage("|cffff5555[AppearanceBuddy]|r learn all: таблица item_template пуста.")
        return
    end

    local totalScanned, totalKept, totalSkippedBad, totalSkippedDup = 0, 0, 0, 0
    local pendingValues = {}
    -- Dedup table: collapse multiple item_template rows that share the same
    -- (displayId, inventoryType) to a single unlock.  Many custom DBs have
    -- dozens of test/clone items pointing at the same model — without this
    -- the catalog gets flooded with visually-identical duplicates.
    local seenDisplay = {}

    local function flushInserts()
        if #pendingValues == 0 then return end
        AuthDBQuery(
            "INSERT IGNORE INTO account_transmog "
            .. "(account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES "
            .. tconcat(pendingValues, ", ")
        )
        for i = #pendingValues, 1, -1 do pendingValues[i] = nil end
    end

    local function findPlayer()
        -- Player may have logged out between pages.  Look them up fresh each
        -- tick so we don't crash dereferencing a stale userdata.
        if not GetPlayerByGUID then return nil end
        return GetPlayerByGUID(playerGUID)
    end

    local function processPage()
        local p = findPlayer()
        local lo, hi = startEntry, startEntry + PAGE - 1
        local q = WorldDBQuery(string_format(
            "SELECT entry, displayid, InventoryType, name, class, FlagsExtra "
            .. "FROM item_template WHERE entry BETWEEN %d AND %d "
            .. "AND displayid > 0 AND class IN (2, 4)",
            lo, hi))
        if q then
            repeat
                totalScanned = totalScanned + 1
                local entry   = tonumber(q:GetUInt32(0)) or 0
                local dispId  = tonumber(q:GetUInt32(1)) or 0
                local invType = tonumber(q:GetUInt32(2)) or 0
                local name    = q:GetString(3) or ""
                local iclass  = tonumber(q:GetUInt32(4)) or 0
                local flagsEx = tonumber(q:GetUInt32(5)) or 0
                local internalFlag = (flagsEx % 8) >= 4  -- bit 0x4
                local dupKey = dispId .. "|" .. invType
                if entry > 0 and dispId > 0
                    and not internalFlag
                    and IsTransmoggableItem(iclass, invType)
                    and not IsBadAppearanceName(name)
                    and not seenDisplay[dupKey]
                then
                    seenDisplay[dupKey] = true
                    totalKept = totalKept + 1
                    pendingValues[#pendingValues + 1] = string_format(
                        "(%d, %d, %d, %d, '%s')",
                        accountGUID, entry, dispId, invType, EscapeString(name))
                    if #pendingValues >= INSERT_CHUNK then flushInserts() end
                elseif seenDisplay[dupKey] and entry > 0 and dispId > 0 then
                    totalSkippedDup = totalSkippedDup + 1
                else
                    totalSkippedBad = totalSkippedBad + 1
                end
            until not q:NextRow()
        end

        startEntry = startEntry + PAGE

        if startEntry <= maxEntry then
            -- Periodic progress every ~50k entries.
            if p and (startEntry % (PAGE * 5)) == 0 then
                p:SendBroadcastMessage(string_format(
                    "|cffffcc00[AppearanceBuddy]|r learn all: проверено %d / %d (открыто %d, пропущено %d)...",
                    startEntry, maxEntry, totalKept, totalSkippedBad))
            end
            -- Defer the next page so the world thread can serve other work.
            CreateLuaEvent(processPage, 50, 1)
        else
            -- Final flush + report.
            flushInserts()
            InvalidateAccountCaches(accountGUID)
            if p then
                p:SendBroadcastMessage(string_format(
                    "|cff00ff00[AppearanceBuddy]|r learn all готово: проверено %d, открыто %d, дубликатов %d, битых %d.",
                    totalScanned, totalKept, totalSkippedDup, totalSkippedBad))
                if TransmogHandlers and TransmogHandlers.SetTransmogItemIds then
                    pcall(TransmogHandlers.SetTransmogItemIds, p)
                end
                -- Signal the client to refresh its catalog so new unlocks are
                -- immediately visible without a manual reload.
                AIO.Handle(p, "Transmog", "LearnAllDone")
            end
        end
    end

    if not CreateLuaEvent then
        player:SendBroadcastMessage("|cffff5555[AppearanceBuddy]|r learn all: CreateLuaEvent недоступен, отмена.")
        return
    end
    CreateLuaEvent(processPage, 1, 1)
end

RegisterPlayerEvent(42, function(_, player, command)
    if not player or not command or command == "" then return end
    local head, tail = command:match("^%.?([%w_%.%-]+)%s*(.*)$")
    if not head then return end
    head = head:lower()
    if head ~= "ab" then return end

    local sub, rest = (tail or ""):lower():match("^(%S+)%s*(.*)$")
    if not sub or sub == "" then
        if player:IsGM() then
            player:SendBroadcastMessage("|cffffcc00[AppearanceBuddy]|r Команды (только для ГМ):")
            player:SendBroadcastMessage("  .ab learn all  — открыть все облики для вашей учётной записи.")
            player:SendBroadcastMessage("  .ab provisions test on|off  — тест сообщений об открытии обликов.")
        end
        return false
    end

    if sub == "provisions" then
        if not player:IsGM() then return false end
        local arg1, arg2 = (rest or ""):match("^(%S+)%s*(%S*)")
        if arg1 ~= "test" or (arg2 ~= "on" and arg2 ~= "off") then
            player:SendBroadcastMessage("|cffffcc00[AppearanceBuddy]|r Использование: .ab provisions test on|off")
            return false
        end
        local guid = player:GetGUIDLow()
        if arg2 == "on" then
            T.PROVISION_TEST_PLAYERS[guid] = true
            player:SendBroadcastMessage("|cff00ff00[AppearanceBuddy]|r Тестовый режим ВКЛ. Добытые облики будут считаться новыми до конца сеанса.")
        else
            T.PROVISION_TEST_PLAYERS[guid] = nil
            player:SendBroadcastMessage("|cff00ff00[AppearanceBuddy]|r Тестовый режим ВЫКЛ.")
        end
        return false
    end

    if sub == "learn" then
        local arg = (rest or ""):match("^(%S+)")
        if arg ~= "all" then
            player:SendBroadcastMessage("|cffffcc00[AppearanceBuddy]|r Использование: .ab learn all")
            return false
        end
        if not player:IsGM() then return false end
        -- Send a confirmation dialog to the client.  The actual scan only
        -- starts when the player clicks "Yes" (LearnAllConfirmed handler).
        AIO.Handle(player, "Transmog", "LearnAllConfirm")
        return false
    end

    -- Unknown subcommand — don't consume.
    return
end)

-- ---------------------------------------------------------------------------
-- .ab learn set  (GM-only, per-set unlock)
-- Unlocks all fullItems from a specific catalog set for the calling player's
-- account.  Triggered by the client via Shift+Left-click on a catalog row.
-- ---------------------------------------------------------------------------

-- Fired by the client when the player Shift+Left-clicks a catalog set in
-- learn mode.  Unlocks every fullItem in that set for the account.
function TransmogHandlers.LearnCatalogSet(player, itemsetId)
    if not player then return end
    if not player:IsGM() then
        AIO.Handle(player, "Transmog", "LearnCatalogSetResult", false, "Нужен режим ГМ (введите .gm on).")
        return
    end

    itemsetId = tonumber(itemsetId)
    if not itemsetId or itemsetId == 0 then
        AIO.Handle(player, "Transmog", "LearnCatalogSetResult", false, "Неверный ID комплекта.")
        return
    end

    local accountGUID = player:GetAccountId()

    -- Pull fullItems directly from the item-set template first (most reliable
    -- since it contains ALL items, not just those already unlocked).
    local itemsToLearn = {}
    local setName      = "Set #" .. tostring(itemsetId)

    local tpl = nil
    if itemsetId > 10000 then
        -- Synthetic tier id: realSetId * 10000 + ilvl
        local realSid  = math.floor(itemsetId / 10000)
        local tierIlvl = itemsetId - realSid * 10000
        tpl = GetItemSetTierTemplate(realSid, tierIlvl)
    end
    tpl = tpl or GetItemSetTemplate(itemsetId)

    if tpl then
        setName = tostring(tpl.name or setName)
        if tpl.fullItems then
            for _, itemId in ipairs(tpl.fullItems) do
                local id = tonumber(itemId)
                if id and id > 0 then
                    tinsert(itemsToLearn, id)
                end
            end
        end
    end

    -- Fallback: scan the account catalog if template lookup found nothing
    -- (virtual sets / merged groups that have no raw itemset entry).
    if #itemsToLearn == 0 then
        for _, setData in ipairs(BuildAccountItemSetCatalog(accountGUID)) do
            if tonumber(setData.id) == itemsetId then
                setName = tostring(setData.name or setName)
                if setData.fullItems then
                    for _, itemId in ipairs(setData.fullItems) do
                        local id = tonumber(itemId)
                        if id and id > 0 then
                            tinsert(itemsToLearn, id)
                        end
                    end
                end
                break
            end
        end
    end

    if #itemsToLearn == 0 then
        AIO.Handle(player, "Transmog", "LearnCatalogSetResult", false,
            "Не найдено предметов для комплекта " .. tostring(itemsetId) .. ".")
        return
    end

    -- Bulk-unlock all items into account_transmog.
    local values = {}
    for _, itemId in ipairs(itemsToLearn) do
        local tpl = GetItemTemplateInfo(itemId)
        if tpl then
            local displayId      = tonumber(tpl.displayId)      or 0
            local inventoryType  = tonumber(tpl.inventoryType)  or 0
            local itemName       = EscapeString(tostring(tpl.name or ""))
            if displayId > 0 then
                tinsert(values, string_format(
                    "(%d, %d, %d, %d, '%s')",
                    accountGUID, itemId, displayId, inventoryType, itemName))
            end
        end
    end

    if #values > 0 then
        AuthDBQuery(
            "INSERT IGNORE INTO account_transmog "
            .. "(account_id, unlocked_item_id, display_id, inventory_type, item_name) VALUES "
            .. tconcat(values, ", "))
        InvalidateAccountCaches(accountGUID)
    end

    player:SendBroadcastMessage(string_format(
        "|cffffcc00[AppearanceBuddy]|r learn set: открыто предметов: %d из «%s» для учётной записи %d.",
        #values, setName, accountGUID))
    AIO.Handle(player, "Transmog", "LearnCatalogSetResult", true, setName, #values)
end

-- Fired by the client when the player clicks "Yes" on the learn-all
-- confirmation dialog.  Only proceeds if the calling player is a GM.
function TransmogHandlers.LearnAllConfirmed(player)
    if not player or not player:IsGM() then return end
    player:SendBroadcastMessage("|cffffcc00[AppearanceBuddy]|r learn all: сканирование item_template...")
    local ok, err = pcall(AB_LearnAllAppearances, player)
    if not ok then
        player:SendBroadcastMessage("|cffff5555[AppearanceBuddy]|r learn all — ошибка: " .. tostring(err))
    end
end
-- Fires 3 seconds after the level change so the message isn't buried under
-- the stat-gain spam.
-- Event 13 = PLAYER_EVENT_ON_LEVEL_CHANGE
-- ---------------------------------------------------------------------------
local function CountNewAppearancesAtLevel(player, oldLevel, newLevel)
    if not T.Blizzlike_Transmog then return 0 end
    local cache = GetAccountAppearanceCache(player:GetAccountId())
    if not cache or not cache.dedupedBySlot then return 0 end

    -- Collect all records that need a template lookup, then bulk-warm the
    -- item-template cache in one IN() query instead of one query per item.
    -- Without this, a player with thousands of unlocked appearances causes
    -- hundreds/thousands of synchronous WorldDBQuery calls here, freezing
    -- the world thread for the duration of the level-up event.
    local allRecords = {}
    for _, records in pairs(cache.dedupedBySlot) do
        for _, record in ipairs(records) do
            allRecords[#allRecords + 1] = record
        end
    end
    BulkEnsureItemTemplates(allRecords)

    local count = 0
    for _, records in pairs(cache.dedupedBySlot) do
        for _, record in ipairs(records) do
            local tpl = T.ITEM_TEMPLATE_CACHE[record.itemId]
            if tpl then
                local minLevel = tpl.requiredLevel or 0
                if minLevel == 0 and tpl.itemLevel and tpl.itemLevel > 0 then
                    minLevel = math_max(1, math_floor(tpl.itemLevel * 0.4))
                end
                if minLevel > oldLevel and minLevel <= newLevel then
                    count = count + 1
                end
            end
        end
    end
    return count
end

RegisterPlayerEvent(13, function(event, player, oldLevel)
    if not player then return end
    if not T.Blizzlike_Transmog then return end
    if player.IsBot and player:IsBot() then return end
    local newLevel   = player:GetLevel()
    local playerGUID = player:GetGUIDLow()
    -- Defer the entire count + message into a CreateLuaEvent so it runs
    -- off the level-change event handler's call stack.  The bulk DB work
    -- in CountNewAppearancesAtLevel (BulkEnsureItemTemplates) still blocks
    -- for one tick, but that tick is decoupled from the level-up packet
    -- path so the client doesn't perceive a freeze.
    -- The 3-second delay also lets stat-gain messages clear first.
    CreateLuaEvent(function()
        if not GetPlayerByGUID then return end
        local p = GetPlayerByGUID(playerGUID)
        if not p then return end
        local count = CountNewAppearancesAtLevel(p, oldLevel, newLevel)
        if count > 0 then
            p:SendBroadcastMessage(
                "|cffffffff" .. "Вы получили уровень и теперь можете использовать ещё " ..
                "|cff00ff00" .. count .. "|r" ..
                "|cffffffff обликов!|r"
            )
        end
    end, 3000, 1)
end)
