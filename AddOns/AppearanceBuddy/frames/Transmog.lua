local addon, ns = ...

local wipe = table.wipe
local tconcat = table.concat
local tsort = table.sort
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local string_format = string.format
local _scratch = { fid = {}, fdid = {}, exc = {}, hid = {}, outfit = {}, rarity = {} }

-- Gold / Silver / Copper cost formatter (stored on ns to avoid main-chunk locals).
-- Each digit group is wrapped in the matching Blizzard coin colour so the cost
-- reads at a glance (yellow gold / silver-grey silver / copper brown).
do
    local GOLD_ICON   = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"
    local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
    local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t"
    local GOLD_COLOR   = "|cffffd700"   -- Blizzard gold yellow
    local SILVER_COLOR = "|cffc7c7cf"   -- Blizzard silver grey
    local COPPER_COLOR = "|cffeda55f"   -- Blizzard copper brown
    local COLOR_END    = "|r"
    function ns.formatCoin(copper)
        copper = math_floor(math.abs(copper))
        local g = math_floor(copper / 10000)
        local s = math_floor((copper % 10000) / 100)
        local c = copper % 100
        local parts = {}
        if g > 0 then parts[#parts + 1] = GOLD_COLOR   .. g .. COLOR_END .. GOLD_ICON   end
        if s > 0 or g > 0 then parts[#parts + 1] = SILVER_COLOR .. s .. COLOR_END .. SILVER_ICON end
        parts[#parts + 1] = COPPER_COLOR .. c .. COLOR_END .. COPPER_ICON
        return tconcat(parts, " ")
    end
end

local mainFrame = ns.mainFrame
if not mainFrame or not mainFrame.tabs or not mainFrame.tabs.transmog then
    return
end

local AIO = _G.AIO
if not AIO and type(require) == "function" then
    local ok, lib = pcall(require, "AIO")
    if ok then
        AIO = lib
    end
end

local GetSettings = ns.GetSettings
local SLOT_SUBCLASSES = ns.slotSubclasses or {}
ns.ARMOR_SUBTYPE_ORDER = ns.ARMOR_SUBTYPE_ORDER or { Cloth = 1, Leather = 2, Mail = 3, Plate = 4 }
local transmogTab = mainFrame.tabs.transmog
local transmogTabName = transmogTab:GetName() or (addon.."TransmogTab")
local EXPECTED_SERVER_SCRIPT_PATH = "lua_scripts/transmog.lua"

local SLOT_DATA = {
    { name = "Head", slotId = 283, previewSubclass = nil },
    { name = "Shoulder", slotId = 287, previewSubclass = nil },
    { name = "Back", slotId = 311, previewSubclass = "Cloth" },
    { name = "Chest", slotId = 291, previewSubclass = nil },
    { name = "Shirt", slotId = 289, previewSubclass = "Miscellaneous" },
    { name = "Tabard", slotId = 319, previewSubclass = "Miscellaneous" },
    { name = "Wrist", slotId = 299, previewSubclass = nil },
    { name = "Hands", slotId = 301, previewSubclass = nil },
    { name = "Waist", slotId = 293, previewSubclass = nil },
    { name = "Legs", slotId = 295, previewSubclass = nil },
    { name = "Feet", slotId = 297, previewSubclass = nil },
    { name = "Main Hand", slotId = 313, previewSubclass = "Sword" },
    { name = "Off-hand", slotId = 315, previewSubclass = "Shield" },
    { name = "Ranged", slotId = 317, previewSubclass = "Bow" },
}

ns.SameTypeInventorySlotBySlotName = {
    ["Head"] = "HeadSlot",
    ["Shoulder"] = "ShoulderSlot",
    ["Back"] = "BackSlot",
    ["Chest"] = "ChestSlot",
    ["Shirt"] = "ShirtSlot",
    ["Tabard"] = "TabardSlot",
    ["Wrist"] = "WristSlot",
    ["Hands"] = "HandsSlot",
    ["Waist"] = "WaistSlot",
    ["Legs"] = "LegsSlot",
    ["Feet"] = "FeetSlot",
    ["Main Hand"] = "MainHandSlot",
    ["Off-hand"] = "SecondaryHandSlot",
    ["Ranged"] = "RangedSlot",
}

ns.SameTypeSubclassFilterAliases = {
    ["One-Handed Axes"] = "Axe",
    ["One-Handed Maces"] = "Mace",
    ["One-Handed Swords"] = "Sword",
    ["Two-Handed Axes"] = "Axe",
    ["Two-Handed Maces"] = "Mace",
    ["Two-Handed Swords"] = "Sword",
    ["Fist Weapons"] = "Fist",
    ["Axes"] = "Axe",
    ["Maces"] = "Mace",
    ["Swords"] = "Sword",
    ["Daggers"] = "Dagger",
    ["Shields"] = "Shield",
    ["Bows"] = "Bow",
    ["Guns"] = "Gun",
    ["Crossbows"] = "Crossbow",
    ["Staves"] = "Staff",
    ["Wands"] = "Wand",
    ["Held In Off-hand"] = "Held in Off-hand",
    ["Miscellaneous"] = "Miscellaneous",
}

-- Short labels for filter button display (to prevent text overflow)
local FILTER_SHORT_LABEL = {
    ["Held in Off-hand"] = "H Off-hand",
}

local RARITY_OPTIONS = {
    { quality = 0, label = ABL("Grey") },
    { quality = 1, label = ABL("Common") },
    { quality = 2, label = ABL("Uncommon") },
    { quality = 3, label = ABL("Rare") },
    { quality = 4, label = ABL("Epic") },
    { quality = 5, label = ABL("Legendary") },
    { quality = 6, label = ABL("Artifact") },
}

local DEFAULT_ARMOR_SUBCLASS = {
    ["MAGE"] = "Cloth",
    ["PRIEST"] = "Cloth",
    ["WARLOCK"] = "Cloth",
    ["DRUID"] = "Leather",
    ["ROGUE"] = "Leather",
    ["HUNTER"] = "Mail",
    ["SHAMAN"] = "Mail",
    ["PALADIN"] = "Plate",
    ["WARRIOR"] = "Plate",
    ["DEATHKNIGHT"] = "Plate",
}

local SLOT_ID_BY_NAME = {}
local SLOT_NAME_BY_ID = {}
local SLOT_PREVIEW_SUBCLASS = {}

for _, info in ipairs(SLOT_DATA) do
    SLOT_ID_BY_NAME[info.name] = info.slotId
    SLOT_NAME_BY_ID[info.slotId] = info.name
    SLOT_PREVIEW_SUBCLASS[info.name] = info.previewSubclass
end

local _, playerRaceFileName = UnitRace("player")
local playerSex = UnitSex("player")
local _, playerClassFileName = UnitClass("player")

local C = {}
C.ACTION_ROW_Y = 6
C.LIST_TOP_Y = -56
C.LIST_BOTTOM_Y = 30
C.SETS_FRAME_BOTTOM_Y = 10
C.SETS_SCROLL_STEP = 72
C.SETS_LIST_SCROLL_WIDTH = 332   -- total width of the visual background box
C.SETS_LIST_WIDTH        = 292   -- width of the inner list content (bg - 5 left - 25 right scrollbar zone - 10 text margin)
C.SETS_PREVIEW_LEFT_X    = 380   -- x where the preview panel starts
C.SETS_AUTO_REFRESH_INTERVAL = 120
C.SETS_DIRTY_REFRESH_DELAY = 2
C.CATALOG_AUTO_RETRY_DELAY = 8     -- seconds after timeout before auto-retrying
C.CATALOG_MAX_AUTO_RETRIES = 3     -- give up after this many auto-retries
C.CATALOG_REQUEST_TIMEOUT  = 30    -- seconds before a pending request is declared timed out
C.BROWSE_REQUEST_TIMEOUT   = 12    -- item-list / page request timeout (was 4; bumped to absorb
                                   -- AIO bus contention + cold AccountAppearanceCache build,
                                   -- which can take 5-8s on accounts with thousands of unlocks)
C.BROWSE_AUTO_RETRY_DELAY  = 0.75  -- reduced from 1.25
C.BROWSE_MAX_AUTO_RETRIES  = 3     -- increased from 2
C.DEFAULT_TRANSMOG_PAGE_SIZE = 10
C.PREVIEW_CARD_WIDTH = 120
C.PREVIEW_CARD_HEIGHT = 112
C.SET_SOURCE_SAVED = "saved"
C.SET_SOURCE_CATALOG = "catalog"
C.PREVIEW_ZOOM_FACTOR = 0.85
C.HEAD_PREVIEW_ZOOM_FACTOR = 0.65
C.HEAD_PREVIEW_Z_OFFSET = 0.10
C.FILTER_BTN_H = 16
C.FILTER_BTN_GAP = 2
C.FILTER_PAD = 4
C.FILTER_WIDTH = 150
C.SET_PREVIEW_DELAY = 0.05     -- reduced from 0.15; token system handles stale renders
C.SET_PREVIEW_QUERY_PASSES = 3
C.REBUILD_BATCH_SIZE = 200
C.ICON_QUERY_BATCH = 200
C.REBUILD_TIME_BUDGET = 0.016   -- seconds of work per coroutine slice (was 0.012)
C.SET_LIST_ICON_MAX_CANDIDATES = 4
C.SET_LIST_ICON_ASYNC_LIMIT = 80
C.BLACKLIST_MAX_ENTRIES = 2000
C.WEAPON_SLOT = {
    ["Main Hand"] = true,
    ["Off-hand"] = true,
    ["Ranged"] = true,
}
C.SET_LIST_ICON_SLOT_PRIORITY = {1, 2, 4, 8, 9, 10, 11, 7, 3, 5, 6, 12, 13, 14}
C.SET_PREVIEW_RETRY_SLOT_ORDER = {
    "Chest", "Legs", "Feet", "Waist", "Hands", "Wrist",
    "Back", "Shoulder", "Head", "Shirt", "Tabard",
    "Main Hand", "Off-hand", "Ranged",
}
C.INVENTORY_TOKEN_BY_SLOT_NAME = {
    ["Head"] = "Head",
    ["Shoulder"] = "Shoulder",
    ["Back"] = "Back",
    ["Chest"] = "Chest",
    ["Shirt"] = "Shirt",
    ["Tabard"] = "Tabard",
    ["Wrist"] = "Wrist",
    ["Hands"] = "Hands",
    ["Waist"] = "Waist",
    ["Legs"] = "Legs",
    ["Feet"] = "Feet",
    ["Main Hand"] = "MainHand",
    ["Off-hand"] = "SecondaryHand",
    ["Ranged"] = "Ranged",
}
C.PREVIEW_HORIZONTAL_FACTOR = 0.15
C.CATALOG_SLOT_LABELS = {
    ["Head"] = "Head",
    ["Shoulder"] = "Shoulders",
    ["Back"] = "Cloak",
    ["Chest"] = "Chest",
    ["Shirt"] = "Shirt",
    ["Tabard"] = "Tabard",
    ["Wrist"] = "Bracers",
    ["Hands"] = "Gloves",
    ["Waist"] = "Belt",
    ["Legs"] = "Legs",
    ["Feet"] = "Boots",
    ["Main Hand"] = "Main Hand",
    ["Off-hand"] = "Off-hand",
    ["Ranged"] = "Ranged",
}

local function trim(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function safeLink(itemId)
    local _, link = GetItemInfo(itemId)
    return link
end

-- Resolve the canonical appearance ID for deduplication.
-- Returns a positive canonical ID (shared for same appearance) or the item ID
-- itself when no canonical exists.  Integer keys avoid string allocations.
local FindRecord = ns.FindRecord  -- cached; never nil after ItemsAPI loads

local function getAppearanceCanonical(slotName, itemId)
    if FindRecord then
        return FindRecord(slotName, itemId) or itemId
    end
    return itemId
end


local function getDisplayedItemIdForAppearance(slotName, selectedItemId, displayedItemIds)
    local numericItemId = tonumber(selectedItemId)
    if not slotName or not numericItemId or numericItemId <= 0 then
        return nil
    end

    local selectedKey = getAppearanceCanonical(slotName, numericItemId)

    for index = 1, #(displayedItemIds or {}) do
        local displayedItemId = tonumber(displayedItemIds[index])
        if displayedItemId == numericItemId then
            return displayedItemId
        end
        if displayedItemId and getAppearanceCanonical(slotName, displayedItemId) == selectedKey then
            return displayedItemId
        end
    end

    return nil
end

local function getEquippedVisibleItemId(slotName)
    local inventoryToken = C.INVENTORY_TOKEN_BY_SLOT_NAME[slotName]
    if not inventoryToken then
        return nil
    end

    local inventorySlot = GetInventorySlotInfo(inventoryToken.."Slot")
    if not inventorySlot then
        return nil
    end

    local itemId = GetInventoryItemID("player", inventorySlot)
    return tonumber(itemId) or nil
end

-- Returns the inventory equip-location string for an item (e.g. "INVTYPE_WEAPON",
-- "INVTYPE_WEAPONMAINHAND", "INVTYPE_2HWEAPON", …) used to detect auto-mirror risk.
local function getItemEquipLoc(itemId)
    if not itemId or itemId <= 0 then return "" end
    return select(9, GetItemInfo(itemId)) or ""
end

local function getSavedTransmogSets()
    -- Migrate from old DressMe variable name.
    -- Also migrate if AppearanceBuddyTransmogSavedSets is an empty table but
    -- DressMeTransmogSavedSets has entries (handles the case where a previous
    -- session wrote an empty table before migration had a chance to run).
    local existing = _G.AppearanceBuddyTransmogSavedSets
    local legacy   = _G.DressMeTransmogSavedSets
    local needMigrate = type(existing) ~= "table"
        or (type(legacy) == "table" and #legacy > 0 and #existing == 0)
    if needMigrate then
        if type(legacy) == "table" and #legacy > 0 then
            _G.AppearanceBuddyTransmogSavedSets = legacy
            _G.DressMeTransmogSavedSets = nil
        elseif type(existing) ~= "table" then
            _G.AppearanceBuddyTransmogSavedSets = {}
        end
    end

    return _G.AppearanceBuddyTransmogSavedSets
end

-- Returns the hidden catalog sets table (id string → true).
-- Stored as a SavedVariable so hidden state persists across sessions.
local function getHiddenCatalogSets()
    if type(_G.AppearanceBuddyHiddenCatalogSets) ~= "table" then
        _G.AppearanceBuddyHiddenCatalogSets = {}
    end
    return _G.AppearanceBuddyHiddenCatalogSets
end

local function sortSavedTransmogSets()
    tsort(getSavedTransmogSets(), function(a, b)
        local nameA = tostring(a and a.name or "")
        local nameB = tostring(b and b.name or "")
        if nameA == nameB then
            return false
        end
        return nameA < nameB
    end)
end

local function normalizeServerState(itemId, realItemId, slotName, serverEquippedId)
    local item = tonumber(itemId)
    local real = tonumber(realItemId)
    local equipped = tonumber(serverEquippedId)

    -- Server-authoritative equipped item ALWAYS wins.  The server reads the
    -- player's actual inventory via GetItemByPos every time SetTransmogItemIds
    -- is fired, so `equipped` reflects exactly what the player has on right
    -- now.  WoW 3.3.5 client GetInventoryItemID is unreliable for the off-hand
    -- when a 2H is equipped (auto-mirrors MH into OH), and the DB `real_item`
    -- column can be stale (last weapon a transmog was applied over).  Trust
    -- the server unconditionally:
    --   equipped > 0  → that exact item is in the slot
    --   equipped == 0 → slot is empty; show nothing
    --   equipped == nil → message came from a legacy/older path; fall back
    if equipped ~= nil then
        if equipped > 0 then
            real = equipped
        else
            real = nil
        end
    elseif (not real or real <= 0) and slotName then
        real = getEquippedVisibleItemId(slotName)
    end

    if real == 0 then
        real = nil
    end

    local effectiveId
    if real == nil then
        -- Slot is empty: nothing to display regardless of any stored transmog.
        -- The transmog row is preserved in the DB so it restores on re-equip.
        effectiveId = nil
    elseif item == 0 then
        effectiveId = 0
    elseif item and item > 0 then
        effectiveId = item
    else
        effectiveId = real
    end

    return {
        itemId = item,
        realItemId = real,
        effectiveId = effectiveId,
    }
end

local state = {
    enabled = AIO and type(AIO.AddHandlers) == "function" and type(AIO.Handle) == "function",
    disabledReason = nil,
    applyingAppearanceSet = false,
    syncNextSetStateToPreview = false,
    applyingUnlockedItemSet = false,
    applyingUnlockedItemSetStartedAt = 0,
    synced = false,
    currentSlot = SLOT_DATA[1].name,
    currentPage = 1,
    pendingPage = nil,
    pageRequestInFlight = false,
    hasMorePages = false,
    totalPages = nil,
    requestToken = 0,
    pageCache = {},
    pageCacheOrder = {},
    pageCacheTokens = {},
    pageCacheRequestSerial = 0,
    -- Session-level set of item IDs that were removed this session.
    -- Used as a belt-and-suspenders guard to prevent removed items from
    -- re-appearing via stale page-cache hits or server-cache race conditions.
    removedItemIds = {},
    -- Per-session pre-scan flag: tracks slot+filter combos whose full id list
    -- has been DBC-checked.  When set, the next paged request can rely on the
    -- blacklist being authoritative so the server's totalPages is accurate.
    preScanned = {},
    preScanInFlight = nil,
    preScanToken = 0,
    search = "",
    subclassFilter = {},
    autoSubclassFilter = {},
    manualSubclassFilter = {},
    viewMode = "items",
    setSource = C.SET_SOURCE_SAVED,
    itemSetCatalog = {},
    itemSetCatalogLoaded = false,
    itemSetCatalogRequestPending = false,
    itemSetCatalogRequestStartedAt = 0,
    itemSetCatalogLastRefreshAt = 0,
    itemSetCatalogDirty = true,
    itemSetCatalogDirtyAt = 0,
    itemSetCatalogRetryAt = 0,       -- GetTime() when next auto-retry fires (0 = none pending)
    itemSetCatalogRetryCount = 0,    -- number of auto-retries attempted since last success
    itemSetCatalogRequestToken = 0,
    serverDiagnostics = nil,
    serverDiagnosticsRequestedAt = 0,
    serverDiagnosticsReceivedAt = 0,
    browseRequestStartedAt = 0,
    browseRequestLabel = nil,
    browseRequestRetryAt = 0,
    browseRequestRetryCount = 0,
    browseRequestPayload = nil,
    lastBridgeError = nil,
    lastBridgeErrorAt = 0,
    lastServerReplyAt = 0,
    lastServerReplySource = nil,
    selectedSavedSetName = nil,
    selectedCatalogSetId = nil,
    slotPages = {},
    slotPageAnchors = {},
    pageLookupToken = 0,
    pageLookupSlot = nil,
    pageLookupAnchor = nil,
    rarityFilter = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true },
    previousUnit = nil,
    previousView = nil,
    server = {},
    preview = {},
    slotButtons = {},
    illusionEnchants = {},  -- active visual illusion per slot name: { ["Main Hand"] = enchantId }
    illusionApplied  = {},  -- last enchant sent to server per slot: { ["Main Hand"] = enchantId }
    illusionStored   = {},  -- true when the server has a stored illusion override row for the slot
    transmogCostEnabled = true,
    transmogCostPerSlot = 50000,  -- base cost for Rare at max level; server overrides via TransmogCostInfo
    transmogRarityMult = { [0]=0.25, [1]=0.25, [2]=0.5, [3]=1.0, [4]=3.0, [5]=30.0 },  -- server overrides
    blizzlikeEnabled = false,     -- server overrides via TransmogCostInfo (4th arg)
    playerIsGM = false,           -- server overrides via TransmogCostInfo (5th arg)
    playerGMRank = 0,             -- account.gmlevel; >= 1 means GM account
    editingSetName = nil,  -- non-nil while editing a saved set in Items mode
}

local displayIdByItemId = {}  -- itemId -> displayId, populated per page by InitTab; module-internal only

for _, info in ipairs(SLOT_DATA) do
    state.server[info.name] = normalizeServerState(nil, nil)
    state.preview[info.name] = {
        mode = "restore",
        itemId = nil,
        effectiveId = nil,
    }
end

-- Returns true when slotName (e.g. "Hands") has a transmog appearance applied.
-- A transmog is considered active when the server has set a non-zero itemId for
-- the slot that differs from the real equipped item (or the slot has no real item).
function ns.IsTransmogged(transmogSlotName)
    local s = state.server[transmogSlotName]
    if not s or not s.itemId or s.itemId <= 0 then return false end
    -- itemId > 0 means an appearance is set. Show the border unless the
    -- appearance IS the equipped item (i.e. no actual transmog change).
    local real = s.realItemId
    return real == nil or real <= 0 or s.itemId ~= real
end

local function noteServerResponse(source)
    state.lastServerReplyAt = GetTime and GetTime() or 0
    state.lastServerReplySource = source
end

function ns.SafeAioHandle(handlerName, methodName, ...)
    if not state.enabled then
        return false
    end
    if not AIO or type(AIO.Handle) ~= "function" then
        state.enabled = false
        state.disabledReason = "AIO.Handle is unavailable"
        state.lastBridgeError = state.disabledReason
        state.lastBridgeErrorAt = GetTime and GetTime() or 0
        return false
    end

    local ok, err = pcall(AIO.Handle, handlerName, methodName, ...)
    if not ok then
        state.lastBridgeError = tostring(err or "unknown AIO dispatch error")
        state.lastBridgeErrorAt = GetTime and GetTime() or 0
        return false
    end
    return true
end

local function requestServerDiagnostics(force)
    if not state.enabled then
        return
    end

    local now = GetTime and GetTime() or 0
    if not force and state.serverDiagnosticsRequestedAt > 0
        and (now - state.serverDiagnosticsRequestedAt) < 2 then
        return
    end

    state.serverDiagnosticsRequestedAt = now
    ns.SafeAioHandle("Transmog", "GetDiagnostics")
end

local function beginBrowseRequest(label)
    state.browseRequestStartedAt = GetTime and GetTime() or 0
    state.browseRequestLabel = label
    state.browseRequestRetryAt = 0
    state.browseRequestRetryCount = 0
end

local function clearBrowseRequest()
    state.browseRequestStartedAt = 0
    state.browseRequestLabel = nil
    state.browseRequestRetryAt = 0
    state.browseRequestRetryCount = 0
    state.browseRequestPayload = nil
end

function ns.RememberBrowseRequest(methodName, ...)
    local payload = { methodName, n = select("#", ...) }
    for index = 1, payload.n do
        payload[index + 1] = select(index, ...)
    end
    state.browseRequestPayload = payload
end

function ns.ResendBrowseRequest()
    local payload = state.browseRequestPayload
    if type(payload) ~= "table" or not payload[1] then
        return false
    end
    state.browseRequestStartedAt = GetTime and GetTime() or 0
    state.browseRequestRetryAt = 0
    state.browseRequestLabel = payload[1]
    return ns.SafeAioHandle("Transmog", payload[1], unpack(payload, 2, (payload.n or 0) + 1))
end

local function appendDiagnosticLine(lines, label, value)
    lines[#lines + 1] = label..": "..value
end

local function formatElapsedSince(timestamp)
    local ts = tonumber(timestamp) or 0
    if ts <= 0 then
        return "none this session"
    end

    local now = GetTime and GetTime() or 0
    local elapsed = now - ts
    if elapsed < 0 then
        elapsed = 0
    end
    return string_format(ABL("%.1fs ago"), elapsed)
end

local function hasLoadedItemListData()
    local list = transmogTab and transmogTab.list
    local itemIds = list and list.itemIds
    return type(itemIds) == "table" and #itemIds > 0 and list.dressingRoomSetup and true or false
end

local function countSelectedRarities()
    local count = 0
    for _, option in ipairs(RARITY_OPTIONS) do
        if state.rarityFilter[option.quality] ~= false then
            count = count + 1
        end
    end
    return count
end

local function hasAnySelectedRarity()
    return countSelectedRarities() > 0
end

local function hasActiveRarityFilter()
    return countSelectedRarities() < #RARITY_OPTIONS
end

local function serializeRarityFilter()
    local values = _scratch.rarity
    wipe(values)
    for _, option in ipairs(RARITY_OPTIONS) do
        if state.rarityFilter[option.quality] ~= false then
            values[#values + 1] = tostring(option.quality)
        end
    end

    if #values == #RARITY_OPTIONS then
        return nil
    end
    if #values == 0 then
        return "none"
    end
    return tconcat(values, ",")
end

local function getAioBridgeStatusText()
    if not state.enabled then
        return "client unavailable"
    end
    if (tonumber(state.lastServerReplyAt) or 0) > 0 then
        return "server to client communication successful"
    end
    return "client bridge initialized"
end

local function addCommonDiagnosticLines(lines, info)
    appendDiagnosticLine(lines, "Expected Script", EXPECTED_SERVER_SCRIPT_PATH)
    appendDiagnosticLine(lines, "AIO Bridge", getAioBridgeStatusText())
    appendDiagnosticLine(lines, "Transmog Sync", state.synced and "received" or "not received")
    appendDiagnosticLine(lines, "Transmog Diagnostics", info and formatElapsedSince(state.serverDiagnosticsReceivedAt) or "no reply")

    if state.lastServerReplySource then
        appendDiagnosticLine(lines, "Last Transmog Reply", state.lastServerReplySource.." ("..formatElapsedSince(state.lastServerReplyAt)..")")
    else
        appendDiagnosticLine(lines, "Last Transmog Reply", "none this session")
    end

    if state.lastBridgeError then
        appendDiagnosticLine(lines, "Last Client Send Error", state.lastBridgeError.." ("..formatElapsedSince(state.lastBridgeErrorAt)..")")
    end

    if info and type(info.scriptPath) == "string" and info.scriptPath ~= "" then
        appendDiagnosticLine(lines, "Server Script", info.scriptPath)
    end
end

local function buildBrowseTimeoutDiagnostics(requestLabel, timeoutSeconds)
    local info = state.serverDiagnostics
    local pendingRequest = type(requestLabel) == "string" and requestLabel ~= "" and requestLabel or "Transmog request"
    local lines = {
        "Request Timed Out",
        "",
        string_format(ABL("%s did not respond after %.1f seconds."), pendingRequest, tonumber(timeoutSeconds) or 0),
        "",
    }
    addCommonDiagnosticLines(lines, info)

    if info and type(info) == "table" then
        local hasItemListHandler = info.hasSetCurrentSlotItemIds or info.hasSetSearchCurrentSlotItemIds
        local handlerStatus = "present"
        if pendingRequest == "SetCurrentSlotItemPage" then
            handlerStatus = info.hasSetCurrentSlotItemPage and "present" or "missing"
            appendDiagnosticLine(lines, "Handler", "page lookup ("..handlerStatus..")")
        elseif pendingRequest == "SetCurrentSlotItemIds" or pendingRequest == "SetSearchCurrentSlotItemIds" then
            handlerStatus = hasItemListHandler and "present" or "missing"
            appendDiagnosticLine(lines, "Handler", "item list ("..handlerStatus..")")
        else
            appendDiagnosticLine(lines, "Handler", "unknown request")
        end
        lines[#lines + 1] = ""
        if pendingRequest == "SetCurrentSlotItemPage" and not info.hasSetCurrentSlotItemPage then
            lines[#lines + 1] = "Diagnostics reached the server, but the required page-lookup handler is missing."
            lines[#lines + 1] = "That usually means an older transmog.lua is still loaded."
        elseif (pendingRequest == "SetCurrentSlotItemIds" or pendingRequest == "SetSearchCurrentSlotItemIds") and not hasItemListHandler then
            lines[#lines + 1] = "Diagnostics reached the server, but the required item-list handler is missing."
            lines[#lines + 1] = "That usually means an older transmog.lua is still loaded."
        else
            lines[#lines + 1] = "Diagnostics reached the server."
            lines[#lines + 1] = "This points to a runtime failure or stale handler state."
        end
    else
        lines[#lines + 1] = ""
        lines[#lines + 1] = "The Transmog handler did not answer diagnostics."
        lines[#lines + 1] = "AIO may still be available, but transmog.lua is likely missing, failed during load, or an older script is still active."
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Reload the server-side Lua engine after restoring "..EXPECTED_SERVER_SCRIPT_PATH.."."
    return tconcat(lines, "\n")
end

local function buildCatalogTimeoutDiagnostics(timeoutSeconds)
    local info = state.serverDiagnostics
    local lines = {
        "Request Timed Out",
        "",
        string_format(ABL("GetUnlockedItemSets did not respond after %.1f seconds."), tonumber(timeoutSeconds) or 0),
        "",
    }
    addCommonDiagnosticLines(lines, info)

    if info and type(info) == "table" then
        appendDiagnosticLine(lines, "Handler", "item sets ("..(info.hasUnlockedItemSets and "present" or "missing")..")")
        lines[#lines + 1] = ""
        if info.hasUnlockedItemSets then
            lines[#lines + 1] = "Diagnostics reached the server."
            lines[#lines + 1] = "This points to a runtime failure or stale handler state."
        else
            lines[#lines + 1] = "Diagnostics reached the server, but the required item-set handler is missing."
            lines[#lines + 1] = "That usually means an older transmog.lua is still loaded."
        end
    else
        lines[#lines + 1] = ""
        lines[#lines + 1] = "The Transmog handler did not answer diagnostics."
        lines[#lines + 1] = "AIO may still be available, but transmog.lua is likely missing, failed during load, or an older script is still active."
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Reload the server-side Lua engine after restoring "..EXPECTED_SERVER_SCRIPT_PATH.."."
    return tconcat(lines, "\n")
end

local function slotHasRestorableAppearance(slotName)
    local serverState = slotName and state.server[slotName]
    local realItemId = serverState and tonumber(serverState.realItemId) or nil
    return realItemId and realItemId > 0
end

local function copyServerToPreview(slotName)
    local serverState = state.server[slotName]
    local previewState = state.preview[slotName]

    previewState.itemId = nil

    if serverState.itemId == 0 then
        previewState.mode = "hidden"
        previewState.effectiveId = 0
    elseif serverState.itemId and serverState.itemId > 0 then
        if serverState.realItemId then
            -- Transmog is stored and something is actually equipped: show it.
            previewState.mode = "item"
            previewState.itemId = serverState.itemId
            previewState.effectiveId = serverState.itemId
        else
            -- Transmog is stored but the slot is empty: show nothing.
            -- The DB row is preserved; it will restore on re-equip.
            previewState.mode = "restore"
            previewState.effectiveId = nil
        end
    else
        previewState.mode = "restore"
        previewState.effectiveId = serverState.realItemId
    end
end

local function copyAllServerToPreview()
    for _, info in ipairs(SLOT_DATA) do
        copyServerToPreview(info.name)
    end
end

local function snapshotCurrentTransmogSet()
    local items = {}

    for index, info in ipairs(SLOT_DATA) do
        local previewState = state.preview[info.name]
        if previewState.mode == "hidden" then
            items[index] = 0
        elseif previewState.mode == "item" and previewState.itemId then
            items[index] = previewState.itemId
        else
            items[index] = slotHasRestorableAppearance(info.name) and -1 or 0
        end
    end

    return items
end

-- ---------------------------------------------------------------------------
-- Set share string encode / decode
--
-- Format: AB1~<name>~<item1>,<item2>,...,<item14>~<mhEnchant>,<ohEnchant>
--   Items: positive = item ID, 0 = hidden, empty token = restore / no-change.
--   Enchants: enchant ID for Main Hand and Off-hand (0 = none).
-- ---------------------------------------------------------------------------
local SHARE_PREFIX = "AB1"

local function encodeSetAsShareString(setData)
    if not setData or type(setData.items) ~= "table" then return nil end
    -- Strip the field separator from the name so it can't corrupt the format.
    local name = tostring(setData.name or ""):gsub("[~,]", "-")
    local parts = {}
    for i = 1, #SLOT_DATA do
        local v = tonumber(setData.items[i])
        -- empty token = restore / skip; 0 = hidden; positive = item ID.
        parts[i] = (v and v >= 0) and tostring(v) or ""
    end
    local enc = type(setData.enchants) == "table" and setData.enchants or {}
    local mhE = tonumber(enc["Main Hand"]) or 0
    local ohE = tonumber(enc["Off-hand"]) or 0
    return SHARE_PREFIX .. "~" .. name .. "~" .. table.concat(parts, ",") .. "~" .. mhE .. "," .. ohE
end

local function decodeShareStringToSet(str)
    if type(str) ~= "string" then return nil, "Not a string." end
    str = str:match("^%s*(.-)%s*$")  -- trim whitespace
    str = str:match("|HABset:([^|]+)|h") or str
    str = str:match("^ABset:(.+)$") or str
    local prefix, name, itemsStr, enchStr = str:match("^([^~]+)~([^~]*)~([^~]*)~?(.*)$")
    if prefix ~= SHARE_PREFIX then
        return nil, "Not a valid AppearanceBuddy share code."
    end
    if name == "" then return nil, "Share code has no set name." end
    local items = {}
    local i = 0
    for token in (itemsStr .. ","):gmatch("([^,]*),") do
        i = i + 1
        if i > #SLOT_DATA then break end
        local v = tonumber(token)
        items[i] = (v ~= nil) and v or -1
    end
    for j = i + 1, #SLOT_DATA do items[j] = -1 end
    local enchants = { ["Main Hand"] = 0, ["Off-hand"] = 0 }
    if enchStr and enchStr ~= "" then
        local mh, oh = enchStr:match("^(%d+),(%d+)$")
        enchants["Main Hand"] = tonumber(mh) or 0
        enchants["Off-hand"]  = tonumber(oh) or 0
    end
    return { name = name, items = items, enchants = enchants }
end

-- fn.importShareString is defined later (after fn, invalidateSavedSetIndex are
-- in scope). The editbox OnEnterPressed calls it via fn.importShareString.

-- ---------------------------------------------------------------------------
-- Chat-clickable set hyperlink.
--
-- We embed the AB1 share string as the data portion of a custom |H link
-- ("ABset:<share>"). Receivers running AppearanceBuddy intercept clicks via
-- a SetItemRef hook and import + select the set; receivers without the addon
-- just see the bracketed [Name] in light blue and clicks do nothing.
--
-- Stored on `ns` to avoid consuming a main-chunk local slot (Lua 5.1 caps
-- the main chunk at 200 locals).
-- ---------------------------------------------------------------------------
ns._setLinkPrefix = "ABset:"


local function getTransmogSetPreviewItem(index, itemIds)
    local requestedItemId = type(itemIds) == "table" and tonumber(itemIds[index]) or nil
    local slotName = SLOT_DATA[index] and SLOT_DATA[index].name or nil

    if requestedItemId and requestedItemId > 0 then
        return requestedItemId
    end

    if requestedItemId == 0 then
        return 0
    end

    if slotName and state.server[slotName] and state.server[slotName].realItemId then
        return state.server[slotName].realItemId
    end

    return 0
end

local function buildPreviewItemsFromTransmogSet(itemIds)
    local previewItems = {}

    for index = 1, #SLOT_DATA do
        previewItems[index] = getTransmogSetPreviewItem(index, itemIds)
    end

    return previewItems
end

local function ensureSetPreviewBackground(model)
    if not model or not model.backgroundTextures then
        return
    end

    for _, texture in pairs(model.backgroundTextures) do
        texture:Hide()
    end
end

local function updateSetPreviewBackground()
    local setsFrame = transmogTab and transmogTab.setsFrame
    local model = setsFrame and setsFrame.previewModel
    ensureSetPreviewBackground(model)
end

local function getSetListIconItemId(setData)
    if type(setData) ~= "table" then
        return nil
    end

    -- Memoize per setData: icon candidates never change for a given catalog row.
    if setData._iconCandCache ~= nil then
        return setData._iconCandCache or nil
    end

    local candidates = {}
    local seen = {}
    local cap = C.SET_LIST_ICON_MAX_CANDIDATES or 4
    local function add(id)
        id = tonumber(id) or 0
        if id > 0 and not seen[id] then
            seen[id] = true
            candidates[#candidates + 1] = id
        end
    end

    local ui = ns.getSetUnlockedItems(setData)
    local fi = ns.getSetFullItems(setData)
    local savedItems = type(setData.items) == "table" and setData.items or nil

    for _, slotIndex in ipairs(C.SET_LIST_ICON_SLOT_PRIORITY) do
        if #candidates >= cap then break end
        if ui then add(ui[slotIndex]) end
        if #candidates >= cap then break end
        if fi then add(fi[slotIndex]) end
        if #candidates >= cap then break end
        if savedItems then add(savedItems[slotIndex]) end
    end

    if #candidates == 0 then
        -- Do NOT cache false here.  Unlock/item data may not have arrived yet
        -- when the first rebuild runs; permanently caching "no candidates" would
        -- mean the icon is never re-attempted even after data arrives later.
        return nil
    end
    setData._iconCandCache = candidates
    return candidates
end

local function ensureSetListButtonLayout(button)
    if not button then
        return nil
    end

    if not button.iconTexture then
        button.iconTexture = button:CreateTexture(nil, "ARTWORK")
        button.iconTexture:SetSize(16, 16)
        button.iconTexture:SetPoint("LEFT", button, "LEFT", 4, 0)
        button.iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.iconTexture:Hide()

        button.iconBackdrop = button:CreateTexture(nil, "BACKGROUND")
        button.iconBackdrop:SetPoint("TOPLEFT", button.iconTexture, "TOPLEFT", -1, 1)
        button.iconBackdrop:SetPoint("BOTTOMRIGHT", button.iconTexture, "BOTTOMRIGHT", 1, -1)
        button.iconBackdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
        button.iconBackdrop:SetVertexColor(0.12, 0.12, 0.12, 0.85)
        button.iconBackdrop:Hide()
    end

    local label = button:GetFontString()
    if label then
        label:ClearAllPoints()
        if button.iconTexture:IsShown() then
            label:SetPoint("LEFT", button.iconTexture, "RIGHT", 4, 0)
        else
            label:SetPoint("LEFT", button, "LEFT", 6, 0)
        end
        label:SetPoint("RIGHT", button, "RIGHT", -2, 0)
        label:SetJustifyH("LEFT")
    end

    return label
end

-- Shared backoff timer for async icon retries.  Previously each retry created
-- its own Frame+OnUpdate, which produced hundreds of frames during a catalog
-- load.  A single OnUpdate driver fires queued callbacks at ~1s intervals.
local _iconRetryFrame = CreateFrame("Frame")
local _iconRetryQueue = {}  -- list of { dueAt = GetTime()+1, fn = function }
local tremove = table.remove
_iconRetryFrame:Hide()
_iconRetryFrame:SetScript("OnUpdate", function(self)
    local now = GetTime()
    local i = 1
    while i <= #_iconRetryQueue do
        local entry = _iconRetryQueue[i]
        if now >= entry.dueAt then
            tremove(_iconRetryQueue, i)
            local ok, err = pcall(entry.fn)
            if not ok then geterrorhandler()(err) end
        else
            i = i + 1
        end
    end
    if #_iconRetryQueue == 0 then self:Hide() end
end)
local function scheduleIconRetry(fn)
    _iconRetryQueue[#_iconRetryQueue + 1] = { dueAt = GetTime() + 0.5, fn = fn }  -- was 1s
    if not _iconRetryFrame:IsShown() then _iconRetryFrame:Show() end
end

local function setSetListButtonIcon(button, itemIdOrList, allowAsync)
    if not button then
        return
    end

    ensureSetListButtonLayout(button)

    -- Normalize input: single id or list of candidate ids.
    local candidates
    if type(itemIdOrList) == "table" then
        candidates = itemIdOrList
    else
        local single = tonumber(itemIdOrList) or 0
        candidates = (single > 0) and { single } or {}
    end

    -- Stamp this generation onto the button so async retries from a stale
    -- batch don't overwrite a newer icon.
    button.catalogIconGen      = (button.catalogIconGen or 0) + 1
    local myGen                = button.catalogIconGen
    button.catalogIconItemId   = candidates[1] or 0

    if #candidates == 0 then
        if button.iconTexture then button.iconTexture:Hide() end
        if button.iconBackdrop then button.iconBackdrop:Hide() end
        ensureSetListButtonLayout(button)
        return
    end

    -- Try each candidate in order: first one whose item info is already
    -- cached client-side wins. Otherwise async-resolve them in order.
    for i = 1, #candidates do
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(candidates[i])
        if texture then
            if button.iconBackdrop then button.iconBackdrop:Show() end
            if button.iconTexture then
                button.iconTexture:Show()
                button.iconTexture:SetTexture(texture)
            end
            ensureSetListButtonLayout(button)
            return
        end
    end

    -- Show backdrop + placeholder while async resolution runs.
    if allowAsync == false then
        if button.iconTexture then button.iconTexture:Hide() end
        if button.iconBackdrop then button.iconBackdrop:Hide() end
        ensureSetListButtonLayout(button)
        return
    end

    -- Show backdrop + placeholder while async resolution runs.
    if button.iconBackdrop then button.iconBackdrop:Show() end
    if button.iconTexture then
        button.iconTexture:Show()
        button.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    ensureSetListButtonLayout(button)

    -- Async: walk candidates with up to 4 attempts each, 1s backoff.
    local idx = 1
    local attempts = 0
    local function tryNext()
        if not button or button.catalogIconGen ~= myGen then return end
        if idx > #candidates then
            -- All candidates failed; hide the placeholder rather than leaving a `?`.
            if button.iconTexture then button.iconTexture:Hide() end
            if button.iconBackdrop then button.iconBackdrop:Hide() end
            ensureSetListButtonLayout(button)
            return
        end

        local id = candidates[idx]
        attempts = attempts + 1
        ns.QueryItem(id, function(queriedItemId)
            if not button or button.catalogIconGen ~= myGen then return end
            local _, _, _, _, _, _, _, _, _, queriedTexture = GetItemInfo(queriedItemId)
            if queriedTexture and button.iconTexture then
                button.iconTexture:SetTexture(queriedTexture)
                ensureSetListButtonLayout(button)
                return
            end
            if attempts < 4 then
                scheduleIconRetry(tryNext)
            else
                -- Move on to the next candidate.
                idx = idx + 1
                attempts = 0
                tryNext()
            end
        end)
    end
    tryNext()
end

local linkSavedSet  -- forward declaration; defined near buttonShareLink below

local function ensureSetListButtonTooltip(button)
    if not button or button.fullLabelTooltipHooked then
        return
    end

    -- Allow right-click in addition to the default left-click.
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Right-click on a catalog row hides that set until Reveal Hidden is clicked.
    -- Use onRightClick field instead of HookScript: SetScript (called by the
    -- recycler on every reuse) wipes HookScript hooks in WoW 3.3.5.
    -- setName check first so a saved row with stale itemSetId can't trigger this.
    button.onRightClick = function(self)
        if self.setName then return end
        if self.itemSetId then
            local hidden = getHiddenCatalogSets()
            hidden[tostring(self.itemSetId)] = true
            GameTooltip:Hide()
            ns.RebuildSetLists()
            ns.UpdateSetButtons()
        end
    end

    -- Shift+Left-click:
    --   Saved row (setName set):    link the set to chat.
    --   Catalog row (itemSetId set): GM-only "learn all" via Ctrl+Shift+click.
    -- NOTE: setName is checked FIRST because list buttons are recycled and
    -- a stale itemSetId from a prior catalog use could otherwise win.
    button.onShiftClick = function(self)
        if self.setName then
            -- Saved: link to chat
            GameTooltip:Hide()
            local savedSets = getSavedTransmogSets()
            for _, s in ipairs(savedSets) do
                if s.name == self.setName then
                    linkSavedSet(s)
                    break
                end
            end
        elseif self.itemSetId and IsControlKeyDown() and state.playerIsGM then
            -- Catalog GM: learn all items (GM-only; no chat output for non-GMs)
            GameTooltip:Hide()
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffffcc00[AppearanceBuddy]|r Requesting learn for set " .. tostring(self.itemSetId) .. "...")
            ns.SafeAioHandle("Transmog", "LearnCatalogSet", self.itemSetId)
        end
    end

    -- Ctrl+Left-click:
    --   Saved row: confirm then delete the saved set.
    button.onCtrlClick = function(self)
        if not self.setName then return end
        GameTooltip:Hide()
        state._pendingDeleteSetName = self.setName
        StaticPopup_Show("AB_REMOVE_SAVED_CONFIRM", self.setName)
    end

    button:HookScript("OnEnter", function(self)
        local fullText = self.fullLabelText
        if not fullText or fullText == "" then
            return
        end

        -- Hover pre-warm: kick item-info requests for every piece in this set
        -- so the client cache is populated before the user clicks.
        if ns.PrewarmSetData then
            if self.setName then
                local saved = _G.AppearanceBuddyTransmogSavedSets
                if type(saved) == "table" then
                    for i = 1, #saved do
                        if saved[i] and saved[i].name == self.setName then
                            ns.PrewarmSetData(saved[i])
                            break
                        end
                    end
                end
            elseif self.itemSetId and state._catalogSetIndex then
                local s = state._catalogSetIndex[self.itemSetId]
                if s then ns.PrewarmSetData(s) end
            end
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(fullText, 1, 0.82, 0)
        if self.itemSetId then
            -- For GM players: show richer set breakdown (unlocked/total + missing slots).
            if state.playerIsGM then
                -- Look up this set in the catalog index.
                local setData = state._catalogSetIndex and state._catalogSetIndex[self.itemSetId]
                if setData then
                    local unlocked = tonumber(setData.unlockedCount) or 0
                    local total    = tonumber(setData.totalCount)    or 0
                    if total > 0 then
                        if unlocked >= total then
                            GameTooltip:AddLine(string_format(ABL("Pieces: %d/%d"), unlocked, total), 0.4, 1, 0.4)
                        else
                            GameTooltip:AddLine(string_format(ABL("Pieces: %d/%d"), unlocked, total), 1, 0.82, 0)
                        end
                        -- List missing slots if any.
                        local missing = ns.getCatalogSetMissingSlots and ns.getCatalogSetMissingSlots(setData) or {}
                        if #missing > 0 then
                            GameTooltip:AddLine(ABL("Missing: ") .. table.concat(missing, ", "), 1, 0.5, 0.5, true)
                        end
                    end
                end
                GameTooltip:AddLine(ABL("Additional options available to GMs:"), 0.4, 1, 0.4)
                GameTooltip:AddLine(ABL("  Ctrl+Shift+click: learn all items in this set."), 0.4, 1, 0.4)
            end
            GameTooltip:AddLine(ABL("Right-click to hide from catalog."), 0.7, 0.7, 0.7)
        elseif self.setName then
            GameTooltip:AddLine(ABL("Shift+click to link this set in chat."), 0.7, 0.9, 1)
            GameTooltip:AddLine(ABL("Ctrl+click to delete this saved set."), 0.9, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button.fullLabelTooltipHooked = true
end

local function getCurrentSlotPageAnchor(slotName)
    local previewState = state.preview[slotName]
    local serverState = state.server[slotName]

    if previewState and previewState.mode == "item" and previewState.itemId and previewState.itemId > 0 then
        return previewState.itemId
    end

    if previewState and previewState.mode == "hidden" then
        return 0
    end

    if serverState and serverState.itemId and serverState.itemId > 0 then
        return serverState.itemId
    end

    if serverState and serverState.itemId == 0 then
        return 0
    end

    if previewState and previewState.effectiveId and previewState.effectiveId > 0 then
        return previewState.effectiveId
    end

    if serverState and serverState.realItemId and serverState.realItemId > 0 then
        return serverState.realItemId
    end

    return 0
end

local function rememberSlotPage(slotName, page, anchor)
    slotName = slotName or state.currentSlot
    if not slotName then
        return
    end

    page = tonumber(page) or 1
    if page < 1 then
        page = 1
    end

    if anchor == nil then
        -- Called from a manual page-browse response (no anchor supplied).
        -- Clear the stored anchor so that the NEXT slot-button click always
        -- triggers a fresh SetCurrentSlotItemPage server lookup and lands on
        -- the actual transmog page rather than the last manually-browsed page.
        anchor = 0
    end

    state.slotPages[slotName] = page
    state.slotPageAnchors[slotName] = tonumber(anchor) or 0
end

local function isSlotDirty(slotName)
    local serverState = state.server[slotName]
    local previewState = state.preview[slotName]

    if previewState.mode == "restore" then
        return serverState.itemId ~= nil
    elseif previewState.mode == "hidden" then
        return serverState.itemId ~= 0
    elseif previewState.mode == "item" then
        return serverState.itemId ~= previewState.itemId
    end

    return false
end

local function getDirtyCount()
    local total = 0
    for _, info in ipairs(SLOT_DATA) do
        if isSlotDirty(info.name) then
            total = total + 1
        end
    end
    -- Also count pending illusion changes (selected enchant differs from last
    -- applied to server) for Main Hand and Off-hand weapon slots.
    for _, slotName in ipairs({"Main Hand", "Off-hand"}) do
        local selected = state.illusionEnchants[slotName]
        local applied  = state.illusionApplied[slotName]
        if selected ~= nil and selected ~= applied then
            total = total + 1
        end
    end
    return total
end

local function hasAppliedTransmogs()
    for _, info in ipairs(SLOT_DATA) do
        if state.server[info.name].itemId ~= nil then
            return true
        end
    end

    -- Any stored weapon illusion counts as applied, including one that happens
    -- to match the weapon's natural enchant.  Natural equipped enchants seeded
    -- from item links do not count here.
    for _, slotName in ipairs({ "Main Hand", "Off-hand" }) do
        if state.illusionStored[slotName] then
            return true
        end
    end

    return false
end

local function getPreviewSetup(slotName)
    -- Prefer the user's active subclass filter (e.g. "Sword", "Axe",
    -- "Held in Off-hand") so weapons in the Off-hand catalog frame with
    -- the correct camera angle / facing instead of always using the
    -- Shield framing — which makes 1H weapons look "wrong-handed".
    local activeSub = state and state.subclassFilter and state.subclassFilter[slotName]
    local subclass  = activeSub or SLOT_PREVIEW_SUBCLASS[slotName] or DEFAULT_ARMOR_SUBCLASS[playerClassFileName]
    local version   = ns.GetPreviewSetupVersion and ns.GetPreviewSetupVersion() or "classic"
    local setup     = ns.GetPreviewSetup(version, playerRaceFileName, playerSex, slotName, subclass)
    -- Fallback: if no per-subclass entry exists for the requested combo,
    -- fall back to the slot's default subclass framing.
    if not setup and activeSub then
        local fb = SLOT_PREVIEW_SUBCLASS[slotName] or DEFAULT_ARMOR_SUBCLASS[playerClassFileName]
        setup = ns.GetPreviewSetup(version, playerRaceFileName, playerSex, slotName, fb)
    end
    return setup
end

-- The DB x/y/z/facing values are calibrated for portrait cards (~5:6 ratio).
-- Reduce x to zoom out from the default DB zoom.
local function getListPreviewSetup(slotName)
    local baseSetup = getPreviewSetup(slotName) or {}
    local zoomFactor = slotName == "Head" and C.HEAD_PREVIEW_ZOOM_FACTOR or C.PREVIEW_ZOOM_FACTOR

    -- Weapon slots use z=0 (vertically centered) to match the illusion panel.
    local z = C.WEAPON_SLOT[slotName] and 0 or (tonumber(baseSetup.z) or 0) * zoomFactor
    if slotName == "Head" then
        z = z + C.HEAD_PREVIEW_Z_OFFSET
    end

    return C.PREVIEW_CARD_WIDTH,
        C.PREVIEW_CARD_HEIGHT,
        (tonumber(baseSetup.x) or 0) * zoomFactor,
        (tonumber(baseSetup.y) or 0) * C.PREVIEW_HORIZONTAL_FACTOR,
        z,
        tonumber(baseSetup.facing) or 0,
        tonumber(baseSetup.sequence) or 3
end

local function getCurrentSlotPageSize(slotName)
    local width, height = getListPreviewSetup(slotName)
    width = tonumber(width) or 0
    height = tonumber(height) or 0

    if width <= 0 or height <= 0 then
        return C.DEFAULT_TRANSMOG_PAGE_SIZE
    end

    -- Prefer the column/row count already established by SetupModel so the
    -- server page size always matches what the grid actually displays.  This
    -- prevents the race where GetWidth() returns different values between the
    -- request call and the SetupModel call (e.g. right after list:Show()).
    local setup = transmogTab.list and transmogTab.list.dressingRoomSetup
    if setup
        and (setup.width  or 0) == width
        and (setup.height or 0) == height
        and (setup.countW or 0) > 0
        and (setup.countH or 0) > 0 then
        return math_max(1, setup.countW * setup.countH)
    end

    local listWidth  = tonumber(transmogTab.list and transmogTab.list:GetWidth())  or 0
    local listHeight = tonumber(transmogTab.list and transmogTab.list:GetHeight()) or 0
    if listWidth <= 0 or listHeight <= 0 then
        return C.DEFAULT_TRANSMOG_PAGE_SIZE
    end

    local columns = math_max(1, math_floor(listWidth  / width))
    local rows    = math_max(1, math_floor(listHeight / height))
    return math_max(1, columns * rows)
end

local function setPreviewToRestore(slotName)
    local serverState = state.server[slotName]
    local previewState = state.preview[slotName]

    previewState.mode = "restore"
    previewState.itemId = nil
    previewState.effectiveId = serverState.realItemId
end

local function setPreviewToHidden(slotName)
    local previewState = state.preview[slotName]

    previewState.mode = "hidden"
    previewState.itemId = nil
    previewState.effectiveId = 0
end

local function setPreviewToItem(slotName, itemId)
    local previewState = state.preview[slotName]
    local serverState = state.server[slotName]

    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 then
        return
    end

    if serverState.realItemId and itemId == serverState.realItemId then
        setPreviewToRestore(slotName)
        return
    end

    previewState.mode = "item"
    previewState.itemId = itemId
    previewState.effectiveId = itemId
end

local function refreshPreviewFromServer(slotName)
    copyServerToPreview(slotName)
    if state.currentSlot == slotName then
        local displayedItemId = getDisplayedItemIdForAppearance(slotName, state.preview[slotName].itemId, transmogTab.list.itemIds)
        transmogTab.list:SelectByItemId(displayedItemId or state.preview[slotName].itemId or -1)
    end
end

-- Suppresses the OnUpdateModel → re-apply scheduling while updatePreviewModel
-- (or the re-apply hook itself) is actively calling TryOn.  Without this guard,
-- TryOn fires OnUpdateModel which would schedule a re-apply for the next frame;
-- that re-apply then calls TryOn(INVTYPE_WEAPON) on an already-occupied MH and
-- the engine routes the weapon to OH, producing the doubled-weapon bug.
local updatePreviewInProgress = false

-- Fixed re-apply schedule (seconds after updatePreviewModel).  The model
-- reload from SetUnit/Reset is multi-stage and asynchronous: body first,
-- then attached items (weapons, shields, helms with attached visuals).
-- Late stages can OVERWRITE earlier TryOn calls, leaving MH/OH empty
-- because the player's real equipped gear lands after our preview TryOns.
-- We schedule several re-applies at increasing intervals so at least one
-- (and ideally the last) lands AFTER all async stages have settled.
local REAPPLY_SCHEDULE = {}
local reapplyDeadlines = {}
local reapplyNextIndex = 1

-- One-shot flag: when true, the next updatePreviewModel() call ignores its
-- per-slot diff optimisation and rebuilds the model from scratch (full Undress
-- + per-slot TryOn).  Set by commit paths because SetUnit("player") renders
-- whatever the server's visible-item field currently says, which reflects the
-- PREVIOUS transmog state until the server processes the just-sent AIO message.
-- Without a forced re-dress the diff path sees "effectiveId == dressedId" (both
-- already updated optimistically in serverState) and skips, leaving the model
-- showing the stale render.
local forcePreviewFullRedress = false
function ns.requestPreviewFullRedress()
    forcePreviewFullRedress = true
end

function ns.BuildWeaponPreviewLink(itemId, enchantId)
    if not itemId or itemId <= 0 then
        return nil
    end
    if enchantId and enchantId > 0 then
        return string.format("|Hitem:%d:%d:0:0:0:0:0:0:0:0|h[Weapon]|h", itemId, enchantId)
    end
    return string.format("|Hitem:%d:0:0:0:0:0:0:0:0:0|h[Weapon]|h", itemId)
end

function ns.TryOnHandWeaponPair(dressModel, mhItemId, mhEnchantId, ohItemId, ohEnchantId)
    local mhLink = ns.BuildWeaponPreviewLink(mhItemId, mhEnchantId)
    local ohLink = ns.BuildWeaponPreviewLink(ohItemId, ohEnchantId)
    if mhLink then
        dressModel:TryOn(mhLink, "MainHandSlot")
    end
    if ohLink then
        dressModel:TryOn(ohLink, "SecondaryHandSlot")
    end
end

function ns.TryOnSingleHandWeapon(dressModel, slotName, itemId, enchantId)
    local link = ns.BuildWeaponPreviewLink(itemId, enchantId)
    local slotToken = ns.SameTypeInventorySlotBySlotName[slotName]
    if link and slotToken then
        dressModel:TryOn(link, slotToken)
    end
end

local function updatePreviewModel()
    if not transmogTab:IsShown() and not mainFrame:IsShown() then
        return
    end

    local hasPreviewData = false
    for _, info in ipairs(SLOT_DATA) do
        if state.preview[info.name].effectiveId ~= nil then
            hasPreviewData = true
            break
        end
    end

    if not hasPreviewData and not state.synced then
        return
    end

    -- SetUnit fires OnUpdateModel synchronously.  With updatePreviewInProgress
    -- still false, that schedules the re-apply frame — which is exactly what
    -- we want: after this function finishes and the flag is cleared, if the
    -- model is reloaded asynchronously, the re-apply will re-dress it.
    mainFrame.dressingRoom:SetUnit("player")
    -- Strategy: SetUnit("player") (which Reset() also calls internally) renders
    -- the player exactly as the SERVER sees them — reading the visible-item
    -- field (including transmog overrides) AND the visible-enchant field
    -- (including temp imbues like Windfury / Flametongue stored in the upper
    -- 16 bits).  We deliberately do NOT call Dress() here: Dress() re-reads
    -- from the player's real inventory items, which carry only the permanent
    -- enchant from the item's enchantment-slot 0 — it STRIPS any temp imbue
    -- glow.  Surgical per-slot TryOn overrides below handle preview diffs and
    -- illusion changes; everything else stays on the SetUnit render so the
    -- live temp imbue survives.
    updatePreviewInProgress = true
    mainFrame.dressingRoom:Reset()

    local function getInvSlotId(slotName)
        local token = C.INVENTORY_TOKEN_BY_SLOT_NAME[slotName]
        return token and GetInventorySlotInfo(token .. "Slot") or nil
    end

    -- WotLK 3.3.5's DressUpModel has no per-slot UndressSlot API.  When the
    -- user wants any slot HIDDEN (effectiveId == 0) or REVERTED to nothing
    -- (server slot was hidden by transmog), we have to wipe the entire model
    -- with Undress() and re-dress every visible slot from scratch.  Without
    -- this branch, "Hide" silently does nothing because the per-slot diff
    -- path below only knows how to add (TryOn), not subtract.
    --
    -- Also forced after a commit (Apply / Apply All) because SetUnit("player")
    -- renders the SERVER's visible-item field, which still shows the previous
    -- transmog until the server processes the just-sent EquipTransmogItem AIO.
    -- Without a forced rebuild the diff path skips slots whose optimistically-
    -- updated serverState already matches preview, leaving the stale render.
    local needsFullRedress = forcePreviewFullRedress
    forcePreviewFullRedress = false
    if not needsFullRedress then
        for _, info in ipairs(SLOT_DATA) do
            local pState = state.preview[info.name]
            local eff    = pState.effectiveId
            if eff == 0 then
                -- explicit hide preview
                needsFullRedress = true
                break
            end
            -- Slot has no preview override but server has it hidden — Reset()'s
            -- SetUnit("player") render still shows the appearance correctly
            -- (transmog hide already on the server), so we don't need to redress
            -- for that case.  Only USER preview-side hides require the wipe.
        end
    end

    if needsFullRedress then
        mainFrame.dressingRoom:Undress()
        local pendingMainHandId, pendingMainHandEnchant = nil, nil
        local pendingOffHandId, pendingOffHandEnchant = nil, nil

        for _, info in ipairs(SLOT_DATA) do
            local slotName     = info.name
            local previewState = state.preview[slotName]
            local serverState  = state.server[slotName]
            local effectiveId  = previewState.effectiveId

            -- Resolve what to render in this slot:
            --   slot empty (realItemId nil) → render nothing, always
            --   preview hide (eff==0)        → render nothing
            --   preview item (eff>0)         → render eff
            --   no preview, server hide      → render nothing
            --   no preview, server transmog  → render server.itemId
            --   no preview, no server change → render server.realItemId
            --     (NOT GetInventoryItemID — unreliable for OH when 2H equipped)
            local renderId
            if not serverState.realItemId then
                -- Slot is empty: never render a transmog appearance onto nothing.
                renderId = nil
            elseif effectiveId == 0 then
                renderId = nil
            elseif effectiveId and effectiveId > 0 then
                renderId = effectiveId
            elseif serverState.itemId == 0 then
                renderId = nil
            elseif serverState.itemId and serverState.itemId > 0 then
                renderId = serverState.itemId
            else
                renderId = serverState.realItemId
            end

            if renderId and renderId > 0 then
                if C.WEAPON_SLOT[slotName] then
                    if slotName == "Main Hand" then
                        pendingMainHandId = renderId
                        pendingMainHandEnchant = state.illusionEnchants[slotName]
                    elseif slotName == "Off-hand" then
                        pendingOffHandId = renderId
                        pendingOffHandEnchant = state.illusionEnchants[slotName]
                    else
                        -- Skip Ranged unless explicitly browsing or transmogging it.
                        local skipRanged = (slotName == "Ranged")
                            and state.currentSlot ~= "Ranged"
                            and not (previewState and previewState.itemId)
                        if not skipRanged then
                            local enchantId = state.illusionEnchants[slotName]
                            local slotToken = (slotName == "Main Hand") and "MainHandSlot"
                                or (slotName == "Off-hand") and "SecondaryHandSlot"
                                or (slotName == "Ranged")   and "RangedSlot"
                                or nil
                            local function tryOnWeapon()
                                if enchantId and enchantId > 0 then
                                    mainFrame.dressingRoom:TryOn(string.format(
                                        "|Hitem:%d:%d:0:0:0:0:0:0:0:0|h[Weapon]|h",
                                        renderId, enchantId), slotToken)
                                elseif enchantId == 0 then
                                    mainFrame.dressingRoom:TryOn(string.format(
                                        "|Hitem:%d:0:0:0:0:0:0:0:0:0|h[Weapon]|h",
                                        renderId), slotToken)
                                else
                                    mainFrame.dressingRoom:TryOn(string.format(
                                        "|Hitem:%d:0:0:0:0:0:0:0:0:0|h[Weapon]|h",
                                        renderId), slotToken)
                                end
                            end

                            tryOnWeapon()
                        end
                    end
                else
                    mainFrame.dressingRoom:TryOn(renderId)
                end
            end
        end
        ns.TryOnHandWeaponPair(mainFrame.dressingRoom,
            pendingMainHandId, pendingMainHandEnchant,
            pendingOffHandId, pendingOffHandEnchant)
    else
    -- Override every slot whose preview.effectiveId differs from what the
    -- player actually has equipped.  Mode encodes the user's intent:
    --   hidden  → effectiveId == 0 → strip the slot (and never re-add)
    --   item    → transmog override → strip + TryOn override id
    --   restore → effectiveId == real equipped → leave Dress() result alone
    --             (unless a weapon-enchant illusion preview is pending)
    local handPairNeedsRefresh = false
    local pendingMainHandId, pendingMainHandEnchant = nil, nil
    local pendingOffHandId, pendingOffHandEnchant = nil, nil
    for _, info in ipairs(SLOT_DATA) do
        local slotName = info.name
        local previewState = state.preview[slotName]
        local serverState = state.server[slotName]
        local effectiveId = previewState.effectiveId
        local invSlotId = getInvSlotId(slotName)
        local equippedId = invSlotId and GetInventoryItemID("player", invSlotId) or nil

        -- What Dress() actually rendered into this slot.  The server writes the
        -- applied transmog item ID into PLAYER_VISIBLE_ITEM_X_ENTRYID, and Dress()
        -- reads from THAT field — NOT from the real inventory item.  So when a
        -- transmog is applied, Dress() shows the transmog appearance even though
        -- GetInventoryItemID still returns the real item.  We must compare against
        -- the dressed appearance, otherwise Revert All (which sets effectiveId to
        -- the real item) silently no-ops because effectiveId == equippedId, leaving
        -- the transmog visible.
        --   serverState.itemId > 0  → Dress shows transmog
        --   serverState.itemId == 0 → slot hidden by transmog (Dress shows nothing)
        --   serverState.itemId == nil → no transmog applied (Dress shows real item)
        local dressedId
        if serverState.itemId == 0 then
            dressedId = 0
        elseif serverState.itemId and serverState.itemId > 0 then
            dressedId = serverState.itemId
        else
            dressedId = equippedId or 0
        end

        if C.WEAPON_SLOT[slotName] then
            if slotName == "Main Hand" or slotName == "Off-hand" then
                local enchantId  = state.illusionEnchants[slotName]
                local appliedEnch = state.illusionApplied[slotName]
                local enchantDirty = enchantId ~= appliedEnch
                local idDirty = (effectiveId or 0) ~= dressedId
                if idDirty or enchantDirty or enchantId == 0 or effectiveId == 0 then
                    handPairNeedsRefresh = true
                end
                if slotName == "Main Hand" and effectiveId and effectiveId > 0 then
                    pendingMainHandId = effectiveId
                    pendingMainHandEnchant = enchantId
                elseif slotName == "Off-hand" and effectiveId and effectiveId > 0 then
                    pendingOffHandId = effectiveId
                    pendingOffHandEnchant = enchantId
                end
            else
                -- Skip Ranged unless explicitly browsing or transmogging it.
                local skipRanged = (slotName == "Ranged")
                    and state.currentSlot ~= "Ranged"
                    and not (previewState and previewState.itemId)
                if skipRanged then
                    if invSlotId and mainFrame.dressingRoom.UndressSlot then
                        mainFrame.dressingRoom:UndressSlot(invSlotId)
                    end
                else
                    local enchantId  = state.illusionEnchants[slotName]
                    local appliedEnch = state.illusionApplied[slotName]
                    local enchantDirty = enchantId ~= appliedEnch
                    local idDirty = (effectiveId or 0) ~= dressedId
                    -- enchantId == 0 means "explicitly hide".  The hide override must
                    -- fire even when enchantDirty is false (applied == 0 already), because
                    -- Dress() shows the weapon with its real enchant glow and we need
                    -- TryOn(item:0:...) to suppress it regardless of dirty state.
                    if idDirty or enchantDirty or enchantId == 0 then
                        if invSlotId and mainFrame.dressingRoom.UndressSlot then
                            mainFrame.dressingRoom:UndressSlot(invSlotId)
                        end
                        if effectiveId and effectiveId > 0 then
                            -- Force the engine to route to the correct hand slot
                            -- by passing the slot token.  Without this, on 3.3.5
                            -- TryOn(INVTYPE_WEAPON) often mirrors a 1H weapon
                            -- into BOTH hands when the model already has weapons
                            -- in both slots from the SetUnit("player") base render.
                            local slotToken = (slotName == "Main Hand") and "MainHandSlot"
                                or (slotName == "Off-hand") and "SecondaryHandSlot"
                                or (slotName == "Ranged")   and "RangedSlot"
                                or nil
                            if enchantId and enchantId > 0 then
                                mainFrame.dressingRoom:TryOn(string.format(
                                    "|Hitem:%d:%d:0:0:0:0:0:0:0:0|h[Weapon]|h",
                                    effectiveId, enchantId), slotToken)
                            elseif enchantId == 0 then
                                mainFrame.dressingRoom:TryOn(string.format(
                                    "|Hitem:%d:0:0:0:0:0:0:0:0:0|h[Weapon]|h",
                                    effectiveId), slotToken)
                            else
                                mainFrame.dressingRoom:TryOn(string.format(
                                    "|Hitem:%d:0:0:0:0:0:0:0:0:0|h[Weapon]|h",
                                    effectiveId), slotToken)
                            end
                        end
                    end
                end
            end
        else
            -- Non-weapon slots.
            if effectiveId == 0 then
                if invSlotId and mainFrame.dressingRoom.UndressSlot then
                    mainFrame.dressingRoom:UndressSlot(invSlotId)
                end
            elseif effectiveId and effectiveId ~= dressedId then
                if invSlotId and mainFrame.dressingRoom.UndressSlot then
                    mainFrame.dressingRoom:UndressSlot(invSlotId)
                end
                mainFrame.dressingRoom:TryOn(effectiveId)
            end
        end
    end
    if handPairNeedsRefresh then
        local mhInvSlot = getInvSlotId("Main Hand")
        local ohInvSlot = getInvSlotId("Off-hand")
        if mhInvSlot and mainFrame.dressingRoom.UndressSlot then
            mainFrame.dressingRoom:UndressSlot(mhInvSlot)
        end
        if ohInvSlot and mainFrame.dressingRoom.UndressSlot then
            mainFrame.dressingRoom:UndressSlot(ohInvSlot)
        end
        ns.TryOnHandWeaponPair(mainFrame.dressingRoom,
            pendingMainHandId, pendingMainHandEnchant,
            pendingOffHandId, pendingOffHandEnchant)
    end
    end
    updatePreviewInProgress = false
    -- Arm the fixed re-apply schedule.  Each entry becomes an absolute
    -- deadline (seconds, GetTime base) at which the re-apply frame fires.
    local now = GetTime()
    wipe(reapplyDeadlines)
    for i, dt in ipairs(REAPPLY_SCHEDULE) do
        reapplyDeadlines[i] = now + dt
    end
    reapplyNextIndex = 1
    if ns and ns.ScheduleReapply then ns.ScheduleReapply() end

    if mainFrame.dressingRoom.shadowformEnabled then
        mainFrame.dressingRoom:EnableShadowform()
    end
end

local function saveDressingRoomView()
    local x, y, z = mainFrame.dressingRoom:GetPosition()

    state.previousView = {
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        facing = tonumber(mainFrame.dressingRoom:GetFacing()) or 0,
    }
end

local function setTransmogDressingRoomView()
    mainFrame.dressingRoom:SetPosition(0, 0, 0)
    mainFrame.dressingRoom:SetFacing(0)
end

local function restoreDressingRoomView()
    local view = state.previousView
    if not view then
        return
    end

    mainFrame.dressingRoom:SetPosition(view.x or 0, view.y or 0, view.z or 0)
    mainFrame.dressingRoom:SetFacing(view.facing or 0)
end

local function showListMessage(text)
    transmogTab.messageText:SetText(text or "")
    transmogTab.messageText:Show()
    transmogTab.list:Hide()

    for _, dressingRoom in ipairs(transmogTab.list.dressingRooms) do
        dressingRoom:OnUpdateModel(nil)
        dressingRoom:ClearModel()
        dressingRoom:Hide()
    end
end

-- Returns rarity and item-level scaling for cost display.
-- Falls back to 1.0 (Rare baseline) if quality is unknown.
do
    local COST_MAX_LEVEL = 80

    -- Per-item cost cache. Keyed by itemId.  Stores the last computed cost
    -- ALONGSIDE a `complete` flag indicating whether GetItemInfo returned
    -- valid quality + required-level data at compute time.  Incomplete entries
    -- are recomputed on the next access; complete entries are returned as-is
    -- so the displayed cost never jitters.
    --
    -- Encoding: costCache[itemId] = number  → complete value
    --           costCache[itemId] = false   → QueryItem in flight (skip re-querying)
    --           costCache[itemId] = nil     → not yet computed
    -- Using a flat value instead of a {cost, complete} table saves one table
    -- allocation + two string-key hash nodes per cached item.
    --
    -- Invalidated when the player levels up (player level affects the formula).
    local costCache = {}
    local cachedPlayerLevel = UnitLevel("player") or 0

    local function invalidateCostCache()
        for k in pairs(costCache) do costCache[k] = nil end
    end

    -- Public: invalidates if player level changed since last call.
    function ns.maybeInvalidateCostCacheForLevel()
        local currentLevel = UnitLevel("player") or cachedPlayerLevel
        if currentLevel ~= cachedPlayerLevel then
            cachedPlayerLevel = currentLevel
            invalidateCostCache()
        end
    end

    function ns.getRarityMultiplier(itemId)
        if not itemId or itemId <= 0 then return 1.0 end
        local _, _, quality = GetItemInfo(itemId)
        if not quality then return nil end  -- unknown — caller must handle
        return state.transmogRarityMult[quality] or 1.0
    end

    -- Scale cost by the item's required level (lower-level items are cheaper).
    -- Returns nil when GetItemInfo data is not yet available so the caller can
    -- treat the cost as "pending" rather than displaying a wrong value.
    function ns.getItemLevelScale(itemId)
        if not itemId or itemId <= 0 then return 1.0 end
        local name, _, _, _, itemMinLevel = GetItemInfo(itemId)
        if not name then return nil end  -- item info not loaded yet
        local mlv = itemMinLevel or 0
        if mlv <= 0 then return 0.20 end
        local scale = 0.20 + 0.80 * (mlv / COST_MAX_LEVEL)
        if scale > 1 then scale = 1 end
        return scale
    end

    -- Client-side player level scaling matching the server formula.
    function ns.getLevelScale()
        local level = UnitLevel("player") or COST_MAX_LEVEL
        local scale = 0.10 + 0.90 * ((level - 1) / (COST_MAX_LEVEL - 1))
        if scale > 1 then scale = 1 end
        return scale
    end

    -- Returns the cost for an item, matching the server formula exactly:
    --   floor(floor(baseCost * levelScale) * rarityMult * itemLevelScale)
    -- Returns 0 (and queues a QueryItem) if item info is not yet loaded so the
    -- displayed cost stays stable instead of jumping when GetItemInfo arrives.
    function ns.getCostForItem(itemId)
        if not itemId or itemId <= 0 then return 0 end

        ns.maybeInvalidateCostCacheForLevel()

        local cached = costCache[itemId]
        -- Fast path: complete cached value (a number).
        if type(cached) == "number" then
            return cached
        end

        local baseCost = state.transmogCostPerSlot
        if not baseCost or baseCost <= 0 then return 0 end

        local rarityMult = ns.getRarityMultiplier(itemId)
        local itemLevelScale = ns.getItemLevelScale(itemId)

        if rarityMult == nil or itemLevelScale == nil then
            -- Item data not yet loaded — issue a single QueryItem (guarded by
            -- the false sentinel so we never stack duplicate requests).
            if cached ~= false and ns.QueryItem then
                costCache[itemId] = false  -- mark in-flight
                ns.QueryItem(itemId, function(queriedId)
                    if costCache[queriedId] == false then
                        costCache[queriedId] = nil  -- allow recompute on next access
                    end
                    if ns._refreshCostText then ns._refreshCostText() end
                end)
            end
            return 0
        end

        -- Match server's double-floor sequence so client display = actual charge.
        local levelScaledBase = math.floor(baseCost * ns.getLevelScale())
        local cost = math.floor(levelScaledBase * rarityMult * itemLevelScale)
        costCache[itemId] = cost
        return cost
    end

    -- Public: lets the catalog handler invalidate when transmog cost config
    -- changes (cost toggle, base cost, rarity table).
    ns.invalidateCostCache = invalidateCostCache
end

-- Returns the copper cost to apply a single weapon illusion (one slot).
-- Formula: 25% of player level in gold (e.g. 20g at level 80).
-- enchantId == 0 ("No Enchant" / hide) is always free — callers must check.
do
    function ns.getIllusionCost()
        if not state.transmogCostEnabled then return 0 end
        local level = UnitLevel("player") or 80
        return math_floor(level * 2500)  -- copper: 0.25 * level * 10 000
    end
end

-- Calculate total cost of all dirty slots (item mode with itemId > 0).
-- Stored on ns to avoid consuming a main-chunk local register.
do
    function ns.getChargeableDirtyCost()
        local total = 0
        for _, info in ipairs(SLOT_DATA) do
            if isSlotDirty(info.name) then
                local previewState = state.preview[info.name]
                if previewState.mode == "item" and previewState.itemId and previewState.itemId > 0 then
                    total = total + ns.getCostForItem(previewState.itemId)
                end
            end
        end
        return total
    end
end

local function updateCostText()
    if not transmogTab.costText then return end

    -- Re-anchors statusText so it never overlaps costText when both are
    -- pinned to the BOTTOMRIGHT corner (illusion mode and the per-item
    -- transmog cost).  When costText is hidden, statusText reclaims the
    -- full row width.  Without this, "Slot: ... Illusion | Pending changes"
    -- and "Cost per illusion: ..." rendered on top of each other in the
    -- bottom-right corner because statusText spans LEFT->BOTTOMRIGHT and
    -- costText anchors BOTTOMRIGHT only ~9px below it.
    local function anchorStatusBesideCost(visible)
        local st = transmogTab.statusText
        if not st then return end
        st:ClearAllPoints()
        st:SetPoint("LEFT", transmogTab.buttonRestore, "RIGHT", 10, 0)
        if visible then
            st:SetPoint("RIGHT", transmogTab.costText, "LEFT", -8, 0)
        else
            st:SetPoint("RIGHT", transmogTab, "BOTTOMRIGHT", -7, C.ACTION_ROW_Y + 11)
        end
    end

    -- Illusion mode: use the per-level formula, not the per-item formula.
    if state.viewMode == "illusion" and state.transmogCostEnabled then
        local cost = ns.getIllusionCost and ns.getIllusionCost() or 0
        if cost > 0 then
            transmogTab.costText:SetText(ABL("Cost per illusion: ") .. ns.formatCoin(cost))
            transmogTab.costText:ClearAllPoints()
            transmogTab.costText:SetPoint("RIGHT", transmogTab, "BOTTOMRIGHT", -7, C.ACTION_ROW_Y + 11)
            transmogTab.costText:Show()
            anchorStatusBesideCost(true)
            return
        end
        transmogTab.costText:SetText("")
        transmogTab.costText:Hide()
        anchorStatusBesideCost(false)
        return
    end

    if not (state.transmogCostEnabled and state.transmogCostPerSlot > 0
        and GetSettings and GetSettings().showTransmogCost ~= false) then
        transmogTab.costText:SetText("")
        transmogTab.costText:Hide()
        anchorStatusBesideCost(false)
        return
    end

    local totalCost = 0
    if state.viewMode == "sets" then
        -- Sum per-item costs from the selected set
        local setData
        if state.setSource == C.SET_SOURCE_SAVED then
            local name = state.selectedSavedSetName
            if name then
                for _, s in ipairs(getSavedTransmogSets()) do
                    if s.name == name then setData = s; break end
                end
            end
            if setData and type(setData.items) == "table" then
                for index = 1, #SLOT_DATA do
                    local v = tonumber(setData.items[index]) or -1
                    if v > 0 then
                        local serverItemId = state.server[SLOT_DATA[index].name].itemId
                        if serverItemId ~= v then
                            totalCost = totalCost + ns.getCostForItem(v)
                        end
                    end
                end
            end
        else
            local selId = tonumber(state.selectedCatalogSetId)
            if selId then
                for _, s in ipairs(state.itemSetCatalog) do
                    if tonumber(s.id) == selId then setData = s; break end
                end
            end
            if setData and setData._uir ~= nil then
                local ui = ns.getSetUnlockedItems(setData)
                for index = 1, #SLOT_DATA do
                    local v = ui and tonumber(ui[index]) or 0
                    if v > 0 then
                        local serverItemId = state.server[SLOT_DATA[index].name].itemId
                        if serverItemId ~= v then
                            totalCost = totalCost + ns.getCostForItem(v)
                        end
                    end
                end
            end
        end
    else
        totalCost = ns.getChargeableDirtyCost()
    end

    if totalCost > 0 then
        transmogTab.costText:SetText(ABL("Cost: ") .. ns.formatCoin(totalCost))
        transmogTab.costText:ClearAllPoints()
        if state.viewMode == "sets" then
            transmogTab.costText:SetPoint("RIGHT", transmogTab.setsFrame.buttonApplySelected, "LEFT", -8, 0)
            -- Sets-mode cost is anchored away from the bottom-right corner,
            -- so statusText keeps its full-width anchor.
            anchorStatusBesideCost(false)
        else
            transmogTab.costText:SetPoint("RIGHT", transmogTab, "BOTTOMRIGHT", -7, C.ACTION_ROW_Y + 11)
            anchorStatusBesideCost(true)
        end
        transmogTab.costText:Show()
    else
        transmogTab.costText:SetText("")
        transmogTab.costText:Hide()
        anchorStatusBesideCost(false)
    end
end

-- Expose so the cost cache (defined earlier in a do...end block) can refresh
-- the displayed cost when GetItemInfo data arrives via QueryItem callbacks.
ns._refreshCostText = updateCostText

local function updateStatusText()
    local slotName = state.currentSlot
    local dirtyCount = getDirtyCount()
    if not state.enabled then
        transmogTab.statusText:SetText(state.disabledReason or ABL("Transmog is unavailable."))
        return
    end

    local searchSuffix = state.search ~= "" and ("  |  Filter: "..state.search) or ""
    if state.editingSetName then
        transmogTab.statusText:SetText((ABL("Editing: |cffffd200%s|r%s")):format(state.editingSetName, searchSuffix))
    elseif state.viewMode == "illusion" then
        local illusionSlotName = SLOT_NAME_BY_ID[transmogTab.illusionFrame.activeSlotId] or slotName
        transmogTab.statusText:SetText((ABL("Slot: %s Illusion%s")):format(ABL(illusionSlotName), searchSuffix))
    else
        transmogTab.statusText:SetText((ABL("Slot: %s%s")):format(ABL(slotName), searchSuffix))
    end
    updateCostText()
end

local function setEnabled(btn, cond) if cond then btn:Enable() else btn:Disable() end end

local function hasCopyableTarget()
    return UnitExists and UnitExists("target")
        and not (UnitIsUnit and UnitIsUnit("target", "player"))
        and (not UnitIsPlayer or UnitIsPlayer("target"))
end

function ns.HideSetShareControls(clearText)
    if transmogTab.buttonShareCopy then
        transmogTab.buttonShareCopy:Hide()
        transmogTab.buttonShareCopy:SetAlpha(0)
        transmogTab.buttonShareCopy:Disable()
    end
    if transmogTab.buttonShareLink then
        transmogTab.buttonShareLink:Hide()
        transmogTab.buttonShareLink:SetAlpha(0)
        transmogTab.buttonShareLink:Disable()
    end
    if transmogTab.shareEditBox then
        transmogTab.shareEditBox:ClearFocus()
        if clearText then transmogTab.shareEditBox:SetText("") end
        transmogTab.shareEditBox:Hide()
        transmogTab.shareEditBox:SetAlpha(0)
    end
end

function ns.ShowSetShareControls()
    transmogTab.buttonShareCopy:SetAlpha(1)
    transmogTab.buttonShareLink:SetAlpha(1)
    transmogTab.shareEditBox:SetAlpha(1)
    transmogTab.buttonShareCopy:Show()
    transmogTab.buttonShareLink:Show()
    transmogTab.shareEditBox:Show()
end

ns.ClassColorById = ns.ClassColorById or {
    [1] = "ffc79c6e", -- Warrior
    [2] = "fff58cba", -- Paladin
    [3] = "ffabd473", -- Hunter
    [4] = "fffff569", -- Rogue
    [5] = "ffffffff", -- Priest
    [6] = "ffc41f3b", -- Death Knight
    [7] = "ff0070de", -- Shaman
    [8] = "ff69ccf0", -- Mage
    [9] = "ff9482c9", -- Warlock
    [11] = "ffff7d0a", -- Druid
}

function ns.ColorPlayerName(name, classId)
    local color = ns.ClassColorById[tonumber(classId) or 0] or "ffffffff"
    return "|c" .. color .. tostring(name or "Unknown") .. "|r"
end

local function updateActionButtons()
    if not transmogTab:IsShown() then return end
    local hasDirty = getDirtyCount() > 0
    local currentDirty = isSlotDirty(state.currentSlot)
    local hasApplied = hasAppliedTransmogs()

    if not state.enabled then
        for _, b in ipairs({transmogTab.buttonApply, transmogTab.buttonRestore, transmogTab.buttonHide,
                           transmogTab.buttonRevertAll, transmogTab.buttonApplyAll, transmogTab.buttonRevert,
                           transmogTab.buttonPrev, transmogTab.buttonNext}) do b:Disable() end
        return
    end

    if state.viewMode == "illusion" then
        local f = transmogTab.illusionFrame
        local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        local selectedEnchant = slotName and state.illusionEnchants[slotName]
        local appliedEnchant  = slotName and state.illusionApplied[slotName]
        local isDirty = selectedEnchant ~= appliedEnchant
        -- Apply is only meaningful when the selected illusion differs from the
        -- last server-confirmed illusion for this weapon slot.
        setEnabled(transmogTab.buttonApply, selectedEnchant ~= nil and isDirty)
        -- Hide is always available for the active weapon (free "No Enchant").
        setEnabled(transmogTab.buttonHide,    selectedEnchant ~= 0)
        -- Restore is available whenever the pending preview differs from the applied enchant.
        setEnabled(transmogTab.buttonRestore, isDirty)
        -- Apply All should be clickable whenever any illusion (or transmog) change is pending.
        setEnabled(transmogTab.buttonApplyAll, getDirtyCount() > 0)
        -- Revert All must also be refreshed in illusion mode so the player can
        -- click it after hiding / overriding a glow without first switching back
        -- to the items view.  hasAppliedTransmogs already reports illusion state.
        setEnabled(transmogTab.buttonRevertAll, hasApplied and not state.applyingAppearanceSet)
        -- Prev/Next are managed by showPage in illusion mode.
        return
    end

    local serverState = state.server[state.currentSlot]
    local previewState = state.preview[state.currentSlot]
    -- In blizzlike mode an empty slot cannot receive a new transmog or hide;
    -- the slot can still be Restored (removes any stale DB row).
    local slotEmpty = state.blizzlikeEnabled and not serverState.realItemId
    setEnabled(transmogTab.buttonApply,     currentDirty)
    setEnabled(transmogTab.buttonRestore,   serverState.itemId ~= nil or previewState.mode ~= "restore")
    setEnabled(transmogTab.buttonHide,      not slotEmpty and (previewState.mode ~= "hidden" or serverState.itemId ~= 0))
    setEnabled(transmogTab.buttonRevertAll, hasApplied and not state.applyingAppearanceSet)
    setEnabled(transmogTab.buttonApplyAll,  hasDirty)
    setEnabled(transmogTab.buttonRevert,    hasDirty)
    if state.viewMode ~= "illusion" then
        setEnabled(transmogTab.buttonPrev,      state.currentPage > 1)
        local onPage = state.pendingPage or state.currentPage
        local canGoNext
        local maxPage = state.totalPages
        if state.clientMaxPages then
            maxPage = maxPage and math_min(maxPage, state.clientMaxPages) or state.clientMaxPages
        end
        if maxPage then
            canGoNext = onPage < maxPage
        else
            canGoNext = state.hasMorePages and true or false
        end
        setEnabled(transmogTab.buttonNext,      canGoNext)
    end

    -- Editing set buttons: swap the full normal action row with Save Set / Cancel Edit
    if transmogTab.buttonSaveSet then
        if state.editingSetName then
            -- Show only the two set-editing buttons; hide everything else in the
            -- action row so nothing overlaps or floats at a broken anchor position.
            transmogTab.buttonSaveSet:Show()
            transmogTab.buttonCancelEdit:Show()
            transmogTab.buttonRevertAll:Hide()
            transmogTab.buttonApplyAll:Hide()
            transmogTab.buttonRevert:Hide()
            transmogTab.buttonApply:Hide()
            transmogTab.buttonHide:Hide()
            transmogTab.buttonRestore:Hide()
        else
            transmogTab.buttonSaveSet:Hide()
            transmogTab.buttonCancelEdit:Hide()
            -- Restore the per-slot action buttons if they were hidden by a prior
            -- edit session (only when still in items mode; mode changes handle the
            -- rest via setItemModeVisible).
            if state.viewMode == "items" then
                transmogTab.buttonRevert:Show()
                transmogTab.buttonApply:Show()
                transmogTab.buttonHide:Show()
                transmogTab.buttonRestore:Show()
            end
        end
    end
end

local fn = {}

local pendingSlotButtonRefreshes = {}
local slotButtonRefreshFrame = CreateFrame("Frame")
local function slotButtonRefreshFrame_OnUpdate(self)
    self:SetScript("OnUpdate", nil)

    local queuedRefreshes = pendingSlotButtonRefreshes
    pendingSlotButtonRefreshes = {}

    for slotName, itemId in pairs(queuedRefreshes) do
        local previewState = state.preview[slotName]
        if previewState and previewState.effectiveId == itemId then
            fn.refreshSlotButton(slotName)
        end
    end
end

local function queueSlotButtonRefresh(slotName, itemId)
    pendingSlotButtonRefreshes[slotName] = itemId
    if slotButtonRefreshFrame:GetScript("OnUpdate") == nil then
        slotButtonRefreshFrame:SetScript("OnUpdate", slotButtonRefreshFrame_OnUpdate)
    end
end

fn.refreshSlotButton = function(slotName)
    local button = state.slotButtons[slotName]
    if not button then
        return
    end

    local previewState = state.preview[slotName]
    local itemId = previewState.effectiveId
    local itemLink, texture
    if itemId and itemId > 0 then
        -- Capture only the link (pos 2); discard the rest.  GetItemIcon is a
        -- lighter call for the texture so we avoid unpacking 10 returns.
        itemLink = select(2, GetItemInfo(itemId))
        texture  = GetItemIcon(itemId)
    end
    local icon = itemId and itemId > 0 and texture or nil

    if itemId and itemId > 0 and not icon and not itemLink then
        ns.QueryItem(itemId, function(queriedItemId, success)
            if success and previewState.effectiveId == queriedItemId then
                queueSlotButtonRefresh(slotName, queriedItemId)
            end
        end)
    end

    if icon then
        SetItemButtonTexture(button, icon)
        button.defaultTexture:Hide()
        button.hiddenLabel:Hide()
    else
        SetItemButtonTexture(button, nil)
        button.defaultTexture:Show()
        if previewState.effectiveId == 0 then
            button.hiddenLabel:Show()
        else
            button.hiddenLabel:Hide()
        end
    end

    if isSlotDirty(slotName) then
        button.pendingGlow:Show()
    else
        button.pendingGlow:Hide()
    end

    -- Transmog-applied gold border on AppearanceBuddy slot buttons
    if ns.SetTransmogAppliedBorder then
        ns.SetTransmogAppliedBorder(button, ns.IsTransmogged and ns.IsTransmogged(slotName))
    end
end

local function refreshAllSlotButtons()
    for _, info in ipairs(SLOT_DATA) do
        fn.refreshSlotButton(info.name)
    end
end

-- Returns the list of filterable subclasses for a slot, or nil if the slot
-- has zero or only one subclass (nothing to filter).
local function getSlotFilterOptions(slotName)
    local subs = SLOT_SUBCLASSES[slotName]
    if not subs or #subs <= 1 then return nil end
    return subs
end

function ns.SameTypeFilterEnabled()
    local settings = GetSettings and GetSettings() or nil
    return not settings or settings.sameTypeFilter ~= false
end

function ns.FindSameTypeFilterOption(slotName, candidate)
    if not candidate or candidate == "" then return nil end
    local options = getSlotFilterOptions(slotName)
    if not options then return nil end
    for _, option in ipairs(options) do
        if option == candidate then
            return option
        end
    end
    local mapped = ns.SameTypeSubclassFilterAliases and ns.SameTypeSubclassFilterAliases[candidate]
    if mapped then
        for _, option in ipairs(options) do
            if option == mapped then
                return option
            end
        end
    end
    return nil
end

function ns.GetEquippedSameTypeFilter(slotName)
    local inventorySlotName = ns.SameTypeInventorySlotBySlotName and ns.SameTypeInventorySlotBySlotName[slotName]
    local inventorySlotId = inventorySlotName and GetInventorySlotInfo and GetInventorySlotInfo(inventorySlotName)
    if not inventorySlotId then return nil end

    local link = GetInventoryItemLink and GetInventoryItemLink("player", inventorySlotId)
    if not link then return nil end

    local _, _, _, _, _, _, subType, _, equipLoc = GetItemInfo(link)
    if equipLoc == "INVTYPE_SHIELD" then
        return ns.FindSameTypeFilterOption(slotName, "Shield")
    elseif equipLoc == "INVTYPE_HOLDABLE" then
        return ns.FindSameTypeFilterOption(slotName, "Held in Off-hand")
    elseif equipLoc == "INVTYPE_2HWEAPON" then
        local text = tostring(subType or "")
        if text:find("Axe") then
            return ns.FindSameTypeFilterOption(slotName, "Axe (2H)")
        elseif text:find("Mace") then
            return ns.FindSameTypeFilterOption(slotName, "Mace (2H)")
        elseif text:find("Sword") then
            return ns.FindSameTypeFilterOption(slotName, "Sword (2H)")
        end
    end

    return ns.FindSameTypeFilterOption(slotName, subType)
end

function ns.ApplySameTypeFilterForSlot(slotName, force)
    if not getSlotFilterOptions(slotName) then
        return false
    end

    if force then
        state.manualSubclassFilter[slotName] = nil
    end

    if not ns.SameTypeFilterEnabled() then
        if state.autoSubclassFilter[slotName] then
            state.autoSubclassFilter[slotName] = nil
            state.subclassFilter[slotName] = nil
            return true
        end
        return false
    end

    if not force and state.manualSubclassFilter[slotName] then
        return false
    end

    if not force and state.subclassFilter[slotName] ~= nil and not state.autoSubclassFilter[slotName] then
        return false
    end

    local sameType = ns.GetEquippedSameTypeFilter(slotName)
    if sameType then
        local changed = state.subclassFilter[slotName] ~= sameType or not state.autoSubclassFilter[slotName]
        state.subclassFilter[slotName] = sameType
        state.autoSubclassFilter[slotName] = true
        state.manualSubclassFilter[slotName] = nil
        return changed
    end

    if state.autoSubclassFilter[slotName] then
        state.autoSubclassFilter[slotName] = nil
        state.subclassFilter[slotName] = nil
        return true
    end
    return false
end

ns.ApplySameTypeFilterForCurrentSlot = function(force)
    local changed = ns.ApplySameTypeFilterForSlot(state.currentSlot, force)
    if fn.updateFilterUI then fn.updateFilterUI() end
    if changed and state.viewMode == "items" and transmogTab:IsShown() and fn.requestCurrentSlotItems then
        fn.requestCurrentSlotItems(true)
    end
end


local function selectSlot(slotName)
    if not SLOT_ID_BY_NAME[slotName] then
        return
    end

    state.currentSlot = slotName
    state.pendingPage = nil
    state.totalPages = nil
    state.hasMorePages = false
    state.probeToken = nil
    if trim(transmogTab.searchBox:GetText()) == "" then
        state.currentPage = tonumber(state.slotPages[slotName]) or 1
        if state.currentPage < 1 then
            state.currentPage = 1
        end
    end

    -- Purge any stale subclass filter that is no longer in the valid option
    -- list for this slot (e.g. a "Plate" filter on a slot for a Shaman).
    local currentFilter = state.subclassFilter[slotName]
    if currentFilter then
        local opts = getSlotFilterOptions(slotName)
        local valid = false
        if opts then
            for _, opt in ipairs(opts) do
                if opt == currentFilter then valid = true; break end
            end
        end
        if not valid then
            state.subclassFilter[slotName] = nil
            state.autoSubclassFilter[slotName] = nil
            state.manualSubclassFilter[slotName] = nil
        end
    end

    ns.ApplySameTypeFilterForSlot(slotName, false)

    for _, info in ipairs(SLOT_DATA) do
        local button = state.slotButtons[info.name]
        if button then
            if info.name == slotName then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end
    end

    fn.updatePageText()
    updateStatusText()
    updateActionButtons()
    if fn.updateFilterUI then fn.updateFilterUI() end
    if fn.filterPopup then fn.filterPopup:Hide() end
    -- Clear any slot-specific warning until the server replies for this slot.
    state.slotWarning = nil

    -- Blizzlike: immediately show the "equip first" message so the stale item
    -- list from the previous slot does not briefly appear before the request
    -- fires.  fn.requestCurrentSlotItems will also enforce this; showing it
    -- here avoids the one-frame flicker.
    if state.blizzlikeEnabled and not (state.server[slotName] and state.server[slotName].realItemId) then
        showListMessage("Equip an item in this slot to browse appearances.")
    end
end

fn.updatePageText = function()
    -- Prefer clientMaxPages (persisted cap from ghost page discovery) when
    -- available; otherwise fall back to the server's totalPages.
    local displayTotal = state.clientMaxPages or state.totalPages
    if displayTotal and displayTotal > 1 then
        transmogTab.pageText:SetText((ABL("Page %d / %d")):format(state.currentPage, displayTotal))
    else
        transmogTab.pageText:SetText((ABL("Page %d")):format(state.currentPage))
    end
end


local function invalidateItemSetCatalog()
    state.itemSetCatalogLoaded = false
    state.itemSetCatalogDirty = true
    state.itemSetCatalogDirtyAt = GetTime and GetTime() or 0
end

local function canHandlePageNavigation()
    return state.enabled
        and state.viewMode == "items"
        and transmogTab:IsShown()
        and not transmogTab.searchBox:HasFocus()
end

local function scheduleDebouncedPageRequest()
    -- Page clicks are user-directed and should supersede stale in-flight page
    -- requests.  Waiting for the old response made paging feel frozen under
    -- AIO/server contention, then suddenly catch up once the old response or
    -- timeout landed.
    if state.pageRequestInFlight then
        state.pageRequestInFlight = false
        clearBrowseRequest()
    end
    fn.requestCurrentSlotItems(false)
end

local function getNextRequestedPage()
    local currentPage = tonumber(state.currentPage) or 1
    local pendingPage = tonumber(state.pendingPage)
    if not pendingPage or pendingPage == currentPage then
        return currentPage
    end
    if pendingPage < currentPage then
        return math_max(1, pendingPage)
    end
    if state.totalPages then
        return pendingPage
    end
    return currentPage + 1
end

local function changePage(direction)
    if not canHandlePageNavigation() then
        return false
    end

    direction = tonumber(direction)
    if direction == nil or direction == 0 then
        return false
    end

    local targetPage = tonumber(state.pendingPage) or tonumber(state.currentPage) or 1
    if direction < 0 then
        if targetPage <= 1 then
            return false
        end
        state.pendingPage = targetPage - 1
    else
        -- When the server has told us the total page count, use it as the
        -- definitive upper bound; otherwise fall back to the hasMorePages flag.
        -- Also respect the client-side cap from previous ghost page detection.
        local maxPage = state.totalPages
        if state.clientMaxPages then
            maxPage = maxPage and math_min(maxPage, state.clientMaxPages) or state.clientMaxPages
        end
        if maxPage then
            if targetPage + 1 > maxPage then
                return false
            end
        elseif not state.hasMorePages then
            return false
        end
        state.pendingPage = targetPage + 1
    end

    PlaySound("gsTitleOptionOK")
    scheduleDebouncedPageRequest()
    return true
end

local function handlePageScroll(_, delta)
    if delta == nil or delta == 0 then
        return false
    end

    if state.viewMode == "sets" and transmogTab:IsShown() and transmogTab.setsFrame:IsShown() then
        local scrollFrame = transmogTab.setsFrame.listScroll
        local scrollChild = transmogTab.setsFrame.list
        if not scrollFrame or not scrollChild then
            return false
        end

        local maxScroll = math_max(0, (scrollChild:GetHeight() or 0) - (scrollFrame:GetHeight() or 0))
        if maxScroll <= 0 then
            scrollFrame:SetVerticalScroll(0)
            return false
        end

        local currentScroll = scrollFrame:GetVerticalScroll() or 0
        local nextScroll = currentScroll - (delta * C.SETS_SCROLL_STEP)
        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > maxScroll then
            nextScroll = maxScroll
        end

        if nextScroll == currentScroll then
            return false
        end

        scrollFrame:SetVerticalScroll(nextScroll)
        return true
    end

    if state.viewMode == "illusion" then
        local f = transmogTab.illusionFrame
        if delta > 0 then
            if f.currentPage > 1 then f._showPage(f.currentPage - 1) end
        else
            local pages = math.max(1, math.ceil(#f.illusionList / (f.perPage or 1)))
            if f.currentPage < pages then f._showPage(f.currentPage + 1) end
        end
        return true
    end

    if delta > 0 then
        return changePage(-1)
    end

    return changePage(1)
end

local function updateListSelection()
    local previewState = state.preview[state.currentSlot]
    if previewState.mode == "item" and previewState.itemId then
        local displayedItemId = getDisplayedItemIdForAppearance(state.currentSlot, previewState.itemId, transmogTab.list.itemIds)
        transmogTab.list:SelectByItemId(displayedItemId or previewState.itemId)
    else
        transmogTab.list.selectedItemId = nil
        transmogTab.list.selectedItemIndex = nil
        for _, dressingRoom in ipairs(transmogTab.list.dressingRooms) do
            dressingRoom._isSelected = false
            if dressingRoom._borderFrame then
                dressingRoom._borderFrame:SetFrameStrata("MEDIUM")
                if dressingRoom._borderFrameBaseLevel then
                    dressingRoom._borderFrame:SetFrameLevel(dressingRoom._borderFrameBaseLevel)
                end
            end
            if dressingRoom._selectionRing then dressingRoom._selectionRing:Hide() end
            dressingRoom:SetBackdropBorderColor(1, 1, 1)
        end
    end
end

local function updateCandidateList(itemIds)
    itemIds = itemIds or {}

    -- A slot warning (e.g. off-hand equipped while browsing main-hand 2H)
    -- takes priority: hide the list and show the informational message.
    if state.slotWarning then
        showListMessage(state.slotWarning)
        updateListSelection()
        updateStatusText()
        updateActionButtons()
        return
    end

    if #itemIds == 0 then
        local message
        if not hasAnySelectedRarity() then
            message = "No rarities selected."
        elseif state.search ~= "" then
            message = "No unlocked appearances match this search."
        elseif state.subclassFilter[state.currentSlot] ~= nil or hasActiveRarityFilter() then
            message = "No unlocked appearances match the current filters."
        else
            message = "No unlocked appearances for this slot yet."
        end
        showListMessage(message)
        updateListSelection()
        updateStatusText()
        updateActionButtons()
        return
    end

    local width, height, x, y, z, facing, sequence = getListPreviewSetup(state.currentSlot)

    transmogTab.messageText:Hide()
    transmogTab.list:Show()

    -- Detect whether the incoming item list is identical to what's already shown.
    -- When the pre-scan fires a re-request after blacklisting unrenderable items,
    -- the resulting page is often the same set of IDs.  Calling Update() in that
    -- case resets all DRs to the loading/outfit state (briefly showing the
    -- character's equipped weapon instead of the candidate item) before the
    -- delayed TryOn sequence re-fires — producing a visible sword flash.
    -- Skipping the re-render when IDs are unchanged eliminates that flicker.
    local currentIds = transmogTab.list.itemIds
    local sameIds = (#currentIds == #itemIds)
    if sameIds then
        for i = 1, #itemIds do
            if currentIds[i] ~= itemIds[i] then
                sameIds = false
                break
            end
        end
    end

    -- For hand-weapon slots, skip Undress() inside queryItemHandler so the
    -- player's real equipped off-hand stays on the model and WoW doesn't
    -- auto-mirror a 1H weapon into both hand attachment points.
    transmogTab.list.currentSlot = state.currentSlot
    transmogTab.list.skipUndress = (state.currentSlot == "Main Hand" or state.currentSlot == "Off-hand")

    -- Track which slots are applied-hidden on the server so mini DRs can
    -- suppress them even when skipUndress is active.
    wipe(_scratch.hid)
    for _, info in ipairs(SLOT_DATA) do
        if state.server[info.name] and state.server[info.name].itemId == 0 then
            _scratch.hid[info.name] = true
        end
    end
    transmogTab.list.hiddenSlots = _scratch.hid

    -- Mirror current transmog onto mini DRs so the preview item is seen
    -- in context with the character's full outfit.
    transmogTab.list.tryOnItems = ns.GetTransmogOutfitItems and ns.GetTransmogOutfitItems(state.currentSlot) or nil

    if not sameIds then
        transmogTab.list:SetItems(itemIds)
        transmogTab.list:SetupModel(width, height, x, y, z, facing, sequence)
        transmogTab.list:SetPage(1)
        transmogTab.list:Update()
    else
        -- Same IDs but the framing may have changed (e.g. user switched
        -- the subclass filter from Shield → Sword on the Off-hand slot).
        -- Re-apply SetupModel + Update so cells reposition without losing
        -- their already-loaded models.
        local setup = transmogTab.list.dressingRoomSetup
        if setup and (
            setup.x ~= x or setup.y ~= y or setup.z ~= z
            or setup.facing ~= facing or setup.sequence ~= sequence
        ) then
            transmogTab.list:SetupModel(width, height, x, y, z, facing, sequence)
            transmogTab.list:Update()
        end
    end
    updateListSelection()
    updateStatusText()
    updateActionButtons()
end

-- Builds a stable key that identifies the (slot,filter) combo whose full
-- itemId list has been pre-scanned this session.  Search-mode results are
-- not pre-scanned (different list every keystroke).
local function getPreScanKey(slotName)
    if state.search and state.search ~= "" then return nil end
    local subclass    = state.subclassFilter[slotName] or ""
    local rarityToken = serializeRarityFilter() or ""
    local hideNoLevel = ns.hideNoLevelItems and "1" or "0"
    return tostring(slotName) .. "|" .. subclass .. "|" .. rarityToken .. "|" .. hideNoLevel
end

function ns.GetItemPageCacheKey(slotName, page, pageSize, search, subclass, rarityToken, hideNoLevel)
    return table.concat({
        tostring(slotName or ""),
        tostring(tonumber(page) or 1),
        tostring(tonumber(pageSize) or 0),
        tostring(search or ""),
        tostring(subclass or ""),
        tostring(rarityToken or ""),
        hideNoLevel and "1" or "0",
        tostring(ns.queryFailedCount or 0),
    }, "\031")
end

function ns.CopyArray(src)
    local out = {}
    if type(src) == "table" then
        for i = 1, #src do
            out[i] = src[i]
        end
    end
    return out
end

function ns.StoreItemPageCache(key, payload)
    if not key or type(payload) ~= "table" then return end
    if not state.pageCache[key] then
        state.pageCacheOrder[#state.pageCacheOrder + 1] = key
        if #state.pageCacheOrder > 30 then
            local oldKey = table.remove(state.pageCacheOrder, 1)
            if oldKey then state.pageCache[oldKey] = nil end
        end
    end
    state.pageCache[key] = {
        itemIds = ns.CopyArray(payload.itemIds),
        displayIds = ns.CopyArray(payload.displayIds),
        page = tonumber(payload.page) or 1,
        hasMorePages = payload.hasMorePages and true or false,
        slotId = tonumber(payload.slotId) or 0,
        totalPages = tonumber(payload.totalPages) or 1,
        slotWarning = payload.slotWarning,
    }
end

function ns.PrefetchItemPage(slotName, page)
    page = tonumber(page) or 0
    if page < 1 or not state.enabled or state.search == nil then return end
    if state.totalPages and page > state.totalPages then return end
    local slotId = SLOT_ID_BY_NAME[slotName]
    if not slotId then return end

    local pageSize = getCurrentSlotPageSize(slotName)
    local subclass = state.subclassFilter[slotName]
    local rarityFilter = serializeRarityFilter()
    local hideNoLevel = ns.hideNoLevelItems and true or nil
    local key = ns.GetItemPageCacheKey(slotName, page, pageSize, state.search, subclass, rarityFilter, hideNoLevel)
    if state.pageCache[key] then return end

    state.pageCacheRequestSerial = (state.pageCacheRequestSerial or 0) + 1
    local token = 800000 + state.pageCacheRequestSerial
    state.pageCacheTokens[token] = key

    local excludeList = nil
    if ns.queryFailedItemIds then
        local exc = _scratch.exc
        wipe(exc)
        for id in pairs(ns.queryFailedItemIds) do
            exc[#exc + 1] = id
        end
        if #exc > 0 then excludeList = exc end
    end

    if state.search ~= "" then
        ns.SafeAioHandle("Transmog", "SetSearchCurrentSlotItemIds", slotId, page, state.search, pageSize, token, subclass, rarityFilter, excludeList, hideNoLevel)
    else
        ns.SafeAioHandle("Transmog", "SetCurrentSlotItemIds", slotId, page, pageSize, token, subclass, rarityFilter, excludeList, hideNoLevel)
    end
end

-- Fires the pre-scan: server returns the COMPLETE filtered itemId list for
-- the current slot+filter so the client can DBC-check every id after the
-- first visible page is already requested. Result handled by AllItemIdsForSlot.
local function requestPreScanForCurrentSlot()
    if not state.enabled then return false end
    local key = getPreScanKey(state.currentSlot)
    if not key then return false end
    if state.preScanned[key] then return false end
    if state.preScanInFlight == key then return true end  -- already fetching
    local slotId = SLOT_ID_BY_NAME[state.currentSlot]
    if not slotId then return false end
    state.preScanInFlight = key
    state.preScanToken    = (state.preScanToken or 0) + 1
    local subclass    = state.subclassFilter[state.currentSlot]
    local rarityToken = serializeRarityFilter()
    local hideNoLevel = ns.hideNoLevelItems and true or nil
    ns.SafeAioHandle("Transmog", "GetAllItemIdsForSlot", slotId, subclass, rarityToken, hideNoLevel, state.preScanToken)
    return true
end

fn.requestCurrentSlotItems = function(resetPage)
    if not state.enabled then
        return
    end

    -- Blizzlike restriction: if the slot has no item equipped, suppress the
    -- catalog entirely and show a "must equip first" message instead.  The
    -- server would return items, but the player cannot apply or hide anything
    -- on an empty slot, so showing a full list is misleading.
    if state.blizzlikeEnabled and not (state.server[state.currentSlot] and state.server[state.currentSlot].realItemId) then
        if resetPage then
            state.currentPage = 1
            state.pendingPage = nil
            state.totalPages = nil
            state.hasMorePages = false
            state.clientMaxPages = nil
        end
        fn.updatePageText()
        updateStatusText()
        updateActionButtons()
        showListMessage("Equip an item in this slot to browse appearances.")
        return
    end

    if resetPage then
        state.currentPage = 1
        state.pendingPage = nil
        state.pageRequestInFlight = false
        clearBrowseRequest()
        state.hasMorePages = false  -- only reset on slot change / full refresh
        state.totalPages = nil
        -- Persistent client-side page cap removed: the server is
        -- authoritative for totalPages and already excludes blacklisted
        -- items.  See AppearanceBuddy.lua ADDON_LOADED for the wipe.
        state.clientMaxPages = nil
    end

    state.search = trim(transmogTab.searchBox:GetText())
    state.clientMaxPages = nil
    state.requestToken = state.requestToken + 1
    requestServerDiagnostics(false)

    fn.updatePageText()
    updateStatusText()
    -- Only clear the list on the very first load for the slot.  While paging
    -- within an already-loaded slot, leave the previous items visible so the
    -- UI feels smooth rather than flashing to a blank "Loading" screen.
    if resetPage or not hasLoadedItemListData() then
        showListMessage("Loading appearances...")
    end
    updateActionButtons()

    if not hasAnySelectedRarity() then
        state.currentPage = 1
        state.pendingPage = nil
        state.pageLookupSlot = nil
        state.pageLookupAnchor = nil
        state.pageRequestInFlight = false
        clearBrowseRequest()
        state.hasMorePages = false
        state.totalPages = 1
        fn.updatePageText()
        showListMessage("No rarities selected.")
        updateStatusText()
        updateActionButtons()
        return
    end

    local slotId = SLOT_ID_BY_NAME[state.currentSlot]
    local pageSize = getCurrentSlotPageSize(state.currentSlot)
    local subclass = state.subclassFilter[state.currentSlot]
    local rarityFilter = serializeRarityFilter()
    local requestedPage = resetPage and (tonumber(state.currentPage) or 1) or getNextRequestedPage()
    if requestedPage < 1 then
        requestedPage = 1
    end
    local hideNoLevel = ns.hideNoLevelItems and true or nil
    local cacheKey = ns.GetItemPageCacheKey(
        state.currentSlot,
        requestedPage,
        pageSize,
        state.search,
        subclass,
        rarityFilter,
        hideNoLevel)
    local cachedPage = state.pageCache[cacheKey]
    if cachedPage then
        local cachedItemIds    = cachedPage.itemIds    or {}
        local cachedDisplayIds = cachedPage.displayIds or {}
        -- Filter out any items removed this session so a stale cache entry
        -- (from a prefetch that raced against the DELETE) never shows them.
        if state.removedItemIds and next(state.removedItemIds) then
            local filteredIds  = {}
            local filteredDids = {}
            for i, raw in ipairs(cachedItemIds) do
                local iid = tonumber(raw)
                if not iid or not state.removedItemIds[iid] then
                    filteredIds[#filteredIds + 1]  = raw
                    filteredDids[#filteredDids + 1] = cachedDisplayIds[i]
                end
            end
            cachedItemIds    = filteredIds
            cachedDisplayIds = filteredDids
        end
        wipe(displayIdByItemId)
        for i = 1, #cachedItemIds do
            local iid = tonumber(cachedItemIds[i])
            local did = tonumber(cachedDisplayIds[i])
            if iid and iid > 0 and did and did > 0 then
                displayIdByItemId[iid] = did
            end
        end
        state.currentPage = tonumber(cachedPage.page) or requestedPage
        state.hasMorePages = cachedPage.hasMorePages and true or false
        state.totalPages = tonumber(cachedPage.totalPages) or state.totalPages
        state.slotWarning = (cachedPage.slotWarning and cachedPage.slotWarning ~= "") and cachedPage.slotWarning or nil
        fn.updatePageText()
        updateCandidateList(cachedItemIds)
    end
    state.pageRequestInFlight = true
    beginBrowseRequest(state.search ~= "" and "SetSearchCurrentSlotItemIds" or "SetCurrentSlotItemIds")
    -- Send the client's blacklist of unrenderable item IDs so the server
    -- excludes them from the result set and page count.
    local excludeList = nil
    if ns.queryFailedItemIds then
        local exc = _scratch.exc
        wipe(exc)
        for id in pairs(ns.queryFailedItemIds) do
            exc[#exc + 1] = id
        end
        if #exc > 0 then excludeList = exc end
    end
    if state.search ~= "" then
        ns.RememberBrowseRequest("SetSearchCurrentSlotItemIds", slotId, requestedPage, state.search, pageSize, state.requestToken, subclass, rarityFilter, excludeList, hideNoLevel)
        ns.SafeAioHandle("Transmog", "SetSearchCurrentSlotItemIds", slotId, requestedPage, state.search, pageSize, state.requestToken, subclass, rarityFilter, excludeList, hideNoLevel)
    else
        ns.RememberBrowseRequest("SetCurrentSlotItemIds", slotId, requestedPage, pageSize, state.requestToken, subclass, rarityFilter, excludeList, hideNoLevel)
        ns.SafeAioHandle("Transmog", "SetCurrentSlotItemIds", slotId, requestedPage, pageSize, state.requestToken, subclass, rarityFilter, excludeList, hideNoLevel)
    end

    -- Fire the full per-slot pre-scan after the visible page request.  The
    -- pre-scan improves final page counts by seeding the DBC blacklist, but it
    -- should not sit in front of the first page load.
    requestPreScanForCurrentSlot()
end

fn.requestCurrentSlotItemPage = function(slotName, itemId)
    if not state.enabled then
        return
    end

    local slotId = SLOT_ID_BY_NAME[slotName]
    itemId = tonumber(itemId) or 0
    if not slotId or itemId <= 0 then
        state.currentPage = 1
        fn.updatePageText()
        fn.requestCurrentSlotItems(false)
        return
    end

    if not hasAnySelectedRarity() then
        fn.requestCurrentSlotItems(true)
        return
    end

    state.pageLookupToken = state.pageLookupToken + 1
    state.pageLookupSlot = slotName
    state.pageLookupAnchor = itemId
    state.currentPage = 1
    state.pendingPage = nil
    state.hasMorePages = false

    fn.updatePageText()
    showListMessage("Locating current appearance...")
    updateActionButtons()

    local subclass = state.subclassFilter[slotName]
    local rarityFilter = serializeRarityFilter()
    requestServerDiagnostics(false)
    beginBrowseRequest("SetCurrentSlotItemPage")
    ns.RememberBrowseRequest("SetCurrentSlotItemPage", slotId, itemId, getCurrentSlotPageSize(slotName), state.pageLookupToken, subclass, rarityFilter)
    ns.SafeAioHandle("Transmog", "SetCurrentSlotItemPage", slotId, itemId, getCurrentSlotPageSize(slotName), state.pageLookupToken, subclass, rarityFilter)
end

fn.loadCurrentSlotItems = function()
    if not state.enabled then
        return
    end

    state.pendingPage = nil
    local currentSearch = trim(transmogTab.searchBox:GetText())
    if currentSearch ~= "" then
        fn.requestCurrentSlotItems(true)
        return
    end

    local slotName = state.currentSlot
    local currentAnchor = getCurrentSlotPageAnchor(slotName)
    local rememberedPage = tonumber(state.slotPages[slotName])
    local rememberedAnchor = tonumber(state.slotPageAnchors[slotName]) or 0

    if rememberedPage and rememberedPage > 0 and rememberedAnchor == currentAnchor then
        state.currentPage = rememberedPage
        fn.updatePageText()
        fn.requestCurrentSlotItems(false)
        return
    end

    if currentAnchor and currentAnchor > 0 then
        fn.requestCurrentSlotItemPage(slotName, currentAnchor)
    else
        state.currentPage = rememberedPage and rememberedPage > 0 and rememberedPage or 1
        fn.updatePageText()
        fn.requestCurrentSlotItems(false)
    end
end

fn.requestItemSetCatalog = function()
    if not state.enabled then
        return
    end
    if state.itemSetCatalogRequestPending then
        local now = GetTime and GetTime() or 0
        if now <= 0 or state.itemSetCatalogRequestStartedAt <= 0
            or (now - state.itemSetCatalogRequestStartedAt) <= (C.CATALOG_REQUEST_TIMEOUT + 5) then
            return
        end
        state.itemSetCatalogRequestPending = false
        state.itemSetCatalogRequestStartedAt = 0
    end

    state.itemSetCatalogRequestToken = (state.itemSetCatalogRequestToken or 0) + 1
    state.itemSetCatalogRequestPending = true
    state.itemSetCatalogRequestStartedAt = GetTime and GetTime() or 0
    fn.updateSetButtons()
    requestServerDiagnostics(false)

    if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG
        and #state.itemSetCatalog == 0 then
        transmogTab.setsFrame.previewTitle:SetText(ABL("Loading Item Sets"))
        transmogTab.setsFrame.previewInfo:SetText(ABL("Fetching unlocked account item sets..."))
    end

    if not ns.SafeAioHandle("Transmog", "GetUnlockedItemSets", state.itemSetCatalogRequestToken) then
        state.itemSetCatalogRequestPending = false
        state.itemSetCatalogRequestStartedAt = 0
    end
end

local function shouldRefreshItemSetCatalog(force)
    if not state.enabled or state.itemSetCatalogRequestPending then
        return false
    end

    -- A retry is already scheduled; don't queue another unless the user forced it.
    if not force and state.itemSetCatalogRetryAt > 0 then
        return false
    end

    if not force then
        if not transmogTab:IsShown() or state.viewMode ~= "sets" or state.setSource ~= C.SET_SOURCE_CATALOG then
            return false
        end
    end

    local now = GetTime and GetTime() or 0
    if force then
        return true
    end

    if not state.itemSetCatalogLoaded or #state.itemSetCatalog == 0 then
        return true
    end

    if state.itemSetCatalogDirty then
        if now <= 0 then
            return true
        end

        return (now - (state.itemSetCatalogDirtyAt or 0)) >= C.SETS_DIRTY_REFRESH_DELAY
    end

    if now <= 0 then
        return false
    end

    return (now - (state.itemSetCatalogLastRefreshAt or 0)) >= C.SETS_AUTO_REFRESH_INTERVAL
end

local function refreshItemSetCatalogIfNeeded(force)
    if force then
        -- Manual / forced refresh resets the retry schedule so the user can
        -- always escape a stuck auto-retry countdown.
        state.itemSetCatalogRetryAt = 0
        state.itemSetCatalogRetryCount = 0
    end

    if not shouldRefreshItemSetCatalog(force) then
        return false
    end

    fn.requestItemSetCatalog()
    return true
end

local function requestServerState()
    if not state.enabled then
        return
    end

    ns.SafeAioHandle("Transmog", "SetTransmogItemIds")
end

local lastBagContentsSignature = nil
local bagSigBuffer = {}   -- reused every scan to avoid per-scan table allocation
local pendingBagScanDelay = 0
local pendingBagScanForce = false
local bagScanFrame = CreateFrame("Frame")

local function getContainerItemIdCompat(bagId, slotId)
    if type(GetContainerItemID) == "function" then
        local rawItemId = GetContainerItemID(bagId, slotId)
        local itemId = rawItemId and tonumber(rawItemId) or nil
        if itemId and itemId > 0 then
            return itemId
        end
    end

    local itemLink = type(GetContainerItemLink) == "function" and GetContainerItemLink(bagId, slotId) or nil
    if type(itemLink) ~= "string" then
        return nil
    end

    return tonumber(string.match(itemLink, "item:(%d+)"))
end

local function getBagContentsSignature()
    wipe(bagSigBuffer)
    local maxBagId = tonumber(NUM_BAG_SLOTS) or 4

    for bagId = 0, maxBagId do
        local slotCount = type(GetContainerNumSlots) == "function" and tonumber(GetContainerNumSlots(bagId)) or 0
        if slotCount and slotCount > 0 then
            for slotId = 1, slotCount do
                local itemId = getContainerItemIdCompat(bagId, slotId)
                if itemId and itemId > 0 then
                    bagSigBuffer[#bagSigBuffer + 1] = string_format("%d:%d:%d", bagId, slotId, itemId)
                end
            end
        end
    end

    return tconcat(bagSigBuffer, "|")
end

local function refreshAppearanceStateFromInventory(force)
    if not state.enabled then
        return false
    end

    local signature = getBagContentsSignature()
    if not force and signature == lastBagContentsSignature then
        return false
    end

    lastBagContentsSignature = signature
    invalidateItemSetCatalog()
    ns.SafeAioHandle("Transmog", "ScanInventoryUnlocks")
    requestServerState()

    if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG then
        refreshItemSetCatalogIfNeeded(false)
    end

    return true
end

local function bagScanFrame_OnUpdate(self, elapsed)
    pendingBagScanDelay = math_max(0, pendingBagScanDelay - (elapsed or 0))
    if pendingBagScanDelay > 0 then
        return
    end

    self:SetScript("OnUpdate", nil)
    local force = pendingBagScanForce
    pendingBagScanForce = false
    refreshAppearanceStateFromInventory(force)
end

local function scheduleBagAppearanceScan(force, delay)
    pendingBagScanForce = pendingBagScanForce or force or false

    local requestedDelay = tonumber(delay) or 0
    if bagScanFrame:GetScript("OnUpdate") == nil then
        pendingBagScanDelay = requestedDelay
        bagScanFrame:SetScript("OnUpdate", bagScanFrame_OnUpdate)
    else
        pendingBagScanDelay = math_min(pendingBagScanDelay, requestedDelay)
    end
end

local function normalizeAppearanceSet(itemIds)
    local normalized = {}

    for index = 1, #SLOT_DATA do
        local slotName = SLOT_DATA[index] and SLOT_DATA[index].name or nil
        local itemId = type(itemIds) == "table" and tonumber(itemIds[index]) or nil
        if itemId and itemId > 0 then
            normalized[index] = math_floor(itemId)
        elseif itemId == 0 then
            normalized[index] = 0
        else
            normalized[index] = slotHasRestorableAppearance(slotName) and -1 or 0
        end
    end

    return normalized
end

function ns.ApplySetIllusions(enchants)
    if type(enchants) ~= "table" then
        return
    end

    for _, slotName in ipairs({ "Main Hand", "Off-hand" }) do
        local slotId = SLOT_ID_BY_NAME[slotName]
        local enchantId = tonumber(enchants[slotName])
        if slotId and enchantId then
            enchantId = math_floor(enchantId)
            if enchantId > 0 then
                if AIO and AIO.Msg then
                    AIO.Msg():Add("ABIllusionApplyV3", slotId, enchantId):Send()
                end
                state.illusionEnchants[slotName] = enchantId
            else
                ns.ClearWeaponIllusionOverride(slotName, slotId)
            end
        end
    end
end

local function applyAppearanceSetAsTransmog(itemIds, enchants)
    if not state.enabled then
        if state.disabledReason then
            SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: "..state.disabledReason)
        end
        return false
    end
    if state.applyingAppearanceSet then
        return false
    end

    state.applyingAppearanceSet = true
    if transmogTab:IsShown() and state.viewMode == "sets" then
        fn.updateSetButtons()
    end

    -- Optimistically push the set items into preview immediately so the left-side
    -- character model updates without waiting for the server AIO round-trip.  The
    -- incoming SetTransmogItemIdsBatch will confirm (or correct) the final state;
    -- this just prevents the model from showing the stale pre-apply appearance while
    -- the network round-trip is in flight, which was the visible "revert" the player
    -- saw after clicking Apply Set following hand-transmog work.
    if type(itemIds) == "table" then
        for index, info in ipairs(SLOT_DATA) do
            local slotName = info.name
            local itemId = tonumber(itemIds[index])
            if itemId and itemId > 0 then
                setPreviewToItem(slotName, itemId)
            elseif itemId == 0 then
                setPreviewToHidden(slotName)
            else
                setPreviewToRestore(slotName)
            end
        end
        if ns.requestPreviewFullRedress then ns.requestPreviewFullRedress() end
        if transmogTab:IsShown() then
            refreshAllSlotButtons()
            updatePreviewModel()
            updateStatusText()
            updateActionButtons()
        end
    end

    ns.SafeAioHandle("Transmog", "ApplyAppearanceSet", normalizeAppearanceSet(itemIds))
    ns.ApplySetIllusions(enchants)
    return true
end

local function revertAllTransmogs()
    local restoreAll = {}
    for index, info in ipairs(SLOT_DATA) do
        restoreAll[index] = slotHasRestorableAppearance(info.name) and -1 or 0
    end

    return applyAppearanceSetAsTransmog(restoreAll)
end

local function applyUnlockedCatalogSet(itemSetId)
    itemSetId = tonumber(itemSetId)
    if not state.enabled or not itemSetId or itemSetId == 0 then
        return false
    end
    if state.applyingUnlockedItemSet then
        return false
    end

    state.applyingUnlockedItemSet = true
    state.applyingUnlockedItemSetStartedAt = GetTime and GetTime() or 0
    if transmogTab:IsShown() and state.viewMode == "sets" then
        fn.updateSetButtons()
    end
    ns.SafeAioHandle("Transmog", "ApplyUnlockedItemSet", itemSetId)
    return true
end

local function commitSlot(slotName)
    if not state.enabled then
        return
    end

    local slotId = SLOT_ID_BY_NAME[slotName]
    local serverState = state.server[slotName]
    local previewState = state.preview[slotName]

    -- In blizzlike mode, block applying or hiding an appearance on an empty slot.
    -- Restore (which removes any stale DB override) is still permitted.
    if state.blizzlikeEnabled and not serverState.realItemId then
        if previewState.mode == "hidden" or previewState.mode == "item" then
            return
        end
    end

    if previewState.mode == "restore" then
        -- Always send nil to mean "remove transmog override entirely".
        -- The old code sent 0 (= hide) when slotHasRestorableAppearance was
        -- false, which caused clicking Restore → Apply on a hidden slot to
        -- immediately re-hide it instead of clearing the transmog.
        ns.SafeAioHandle("Transmog", "EquipTransmogItem", nil, slotId)
        serverState.itemId = nil
        serverState.effectiveId = serverState.realItemId
    elseif previewState.mode == "hidden" then
        ns.SafeAioHandle("Transmog", "EquipTransmogItem", 0, slotId)
        serverState.itemId = 0
        serverState.effectiveId = 0
    elseif previewState.mode == "item" and previewState.itemId then
        ns.SafeAioHandle("Transmog", "EquipTransmogItem", previewState.itemId, slotId)
        serverState.itemId = previewState.itemId
        serverState.effectiveId = previewState.itemId
    end

    copyServerToPreview(slotName)
    fn.refreshSlotButton(slotName)
end

local function revertAllPreview()
    copyAllServerToPreview()
    refreshAllSlotButtons()
    updatePreviewModel()
    updateListSelection()
    updateStatusText()
    updateActionButtons()
end

local function onSlotButtonEnter(self)
    local slotName = self.slotName
    local serverState = state.server[slotName]
    local previewState = state.preview[slotName]

    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(slotName)

    if serverState.realItemId then
        GameTooltip:AddLine(ABL("Original: ")..(safeLink(serverState.realItemId) or ("item:"..serverState.realItemId)), 1, 1, 1)
    else
        GameTooltip:AddLine(ABL("Original: no item equipped"), 0.75, 0.75, 0.75)
    end

    if serverState.itemId == 0 then
        GameTooltip:AddLine(ABL("Applied: hidden"), 1, 0.3, 0.3)
    elseif serverState.itemId and serverState.itemId > 0 then
        GameTooltip:AddLine(ABL("Applied: ")..(safeLink(serverState.itemId) or ("item:"..serverState.itemId)), 0.3, 1, 0.3)
    else
        GameTooltip:AddLine(ABL("Applied: original appearance"), 0.3, 1, 0.3)
    end

    if isSlotDirty(slotName) then
        if previewState.mode == "hidden" then
            GameTooltip:AddLine(ABL("Preview: hidden"), 1, 0.82, 0)
        elseif previewState.mode == "restore" then
            GameTooltip:AddLine(ABL("Preview: restore original appearance"), 1, 0.82, 0)
        elseif previewState.itemId then
            GameTooltip:AddLine(ABL("Preview: ")..(safeLink(previewState.itemId) or ("item:"..previewState.itemId)), 1, 0.82, 0)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ABL("Click to browse unlocked appearances."))
    GameTooltip:Show()
end

local function onSlotButtonLeave()
    GameTooltip:Hide()
end

local function onSlotButtonClick(self)
    PlaySound("gsTitleOptionOK")
    -- selectSlot must run before fn.updateViewMode() so that the subclass
    -- filter (e.g. Shield default for Off-hand) is set before any
    -- loadCurrentSlotItems call fires inside updateViewMode.
    selectSlot(self.slotName)
    if state.viewMode == "illusion" then
        state.viewMode = "items"
        fn.updateViewMode()
    end
    fn.loadCurrentSlotItems()
end

-- Canonical appearance IDs known to be unlocked on this account.
-- Populated on login via AllUnlockedItemIds and incrementally via InitTab browsing.
-- AppearanceBorder.lua reads this; ns.OnAppearancesUnlocked is assigned by that module.
ns.unlockedItemIds = {}
-- Set to true once the server has sent at least one AllUnlockedItemIds response.
-- AppearanceBorder.lua gates isUncollected() on this flag so it never shows
-- false positives during the async AIO handshake window after login.
ns.unlockedItemIdsReady = false
ns.OnAppearancesUnlocked = nil

local function onListItemEnter(self)
    local itemId = self:GetParent().itemId
    if not itemId then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:ClearLines()
    local link = safeLink(itemId)
    if link then
        GameTooltip:SetHyperlink(link)
    else
        GameTooltip:AddLine(ABL("item:")..itemId)
    end

    if GetSettings and GetSettings().showShortcutsInTooltip then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left Click:|r preview this appearance.")
        GameTooltip:AddLine("|cff00ff00Shift + Left Click:|r create an item link.")
        GameTooltip:AddLine("|cff00ff00Ctrl + Left Click:|r create a Wowhead URL.")
        if GetSettings and GetSettings().removeTransmogAppearanceEnabled then
            GameTooltip:AddLine("|cffff4040Ctrl + Shift + Left Click:|r permanently remove this appearance from your account.")
        end
    end
    if GetSettings and GetSettings().showDisplayIdInTooltip then
        local did = displayIdByItemId[itemId]
        if did and did > 0 then
            GameTooltip:AddLine(ABL("Item Display Id: ")..did, 0.6, 0.6, 0.6)
        end
    end
    if GetSettings and GetSettings().showItemIdInTooltip ~= false then
        if itemId and itemId > 0 then
            GameTooltip:AddLine(ABL("Item Id: ")..itemId, 0.6, 0.6, 0.6)
        end
    end
    GameTooltip:Show()
end

local function onListItemLeave()
    GameTooltip:Hide()
end

local function onListItemClick(self)
    local itemId = self:GetParent().itemId
    if not itemId then
        return
    end

    -- Ctrl+Shift must be checked BEFORE the individual Shift and Ctrl guards
    -- below so the combo doesn't fall through into link or Wowhead URL mode.
    if IsShiftKeyDown() and IsControlKeyDown() then
        if state.enabled and GetSettings and GetSettings().removeTransmogAppearanceEnabled then
            -- Fire the server delete first so it can race in parallel with the
            -- local UI work below — every ms shaved off matters when spamming.
    ns.SafeAioHandle("Transmog", "RemoveUnlockedAppearance", itemId)

            -- Record this removal session-wide immediately so that InitTab
            -- responses and page-cache hits can never re-introduce this item,
            -- even if the server replies from a stale cache or a pre-scheduled
            -- prefetch response arrives after the DELETE was sent.
            state.removedItemIds[itemId] = true
            local _removedCanonical = FindRecord and FindRecord(itemId)
            if _removedCanonical and _removedCanonical ~= itemId then
                state.removedItemIds[_removedCanonical] = true
            end
            -- Wipe the page cache so navigating to adjacent pages (or back to
            -- the current page) never serves a stale cached list that still
            -- contains the removed item.
            wipe(state.pageCache)
            wipe(state.pageCacheOrder)

            -- ── Optimistic local removal ──────────────────────────────────────
            -- Without this, every click waited for a full server round trip
            -- (delete reply → requestCurrentSlotItems → fresh page query →
            -- per-item caches), making rapid removal feel unresponsive.  We
            -- mutate the in-memory list right away and only fall back to a
            -- server resync if the delete actually fails.
            local list = transmogTab.list
            if list and list.itemIds then
                local ids = list.itemIds
                local removedIndex = nil
                for i = 1, #ids do
                    if ids[i] == itemId then
                        removedIndex = i
                        break
                    end
                end
                if removedIndex then
                    table.remove(ids, removedIndex)

                    -- Drop from the unlock cache so other UI (sets, search,
                    -- catalog filtering) immediately treats it as not owned.
                    if ns.unlockedItemIds then
                        ns.unlockedItemIds[itemId] = nil
                        local canonical = FindRecord and FindRecord(itemId)
                        if canonical and canonical ~= itemId then
                            ns.unlockedItemIds[canonical] = nil
                        end
                    end

                    -- Clear selection if the removed item was selected.
                    if list.selectedItemId == itemId then
                        list.selectedItemId = nil
                        list.selectedItemIndex = nil
                    end

                    -- Reset preview if it was showing the removed appearance.
                    local prev = state.preview and state.preview[state.currentSlot]
                    if prev and prev.itemId == itemId then
                        setPreviewToRestore(state.currentSlot)
                        fn.refreshSlotButton(state.currentSlot)
                        ns.requestPreviewFullRedress()
                        updatePreviewModel()
                    end

                    -- Clamp current page if removal shrank the list past it.
                    if list.GetPageCount and list.SetPage then
                        local pageCount = list:GetPageCount()
                        if pageCount > 0 and list.currentPage and list.currentPage > pageCount then
                            list:SetPage(pageCount)
                        end
                    end

                    if list.Update and #ids > 0 then
                        list:Update()
                    elseif #ids == 0 then
                        -- Empty list: ask the server to recompute totalPages /
                        -- show the empty-state message.  Cheap, only happens
                        -- once when the slot is fully cleared.
                        fn.requestCurrentSlotItems(false)
                    end
                end
            end
        end
        return
    end

    if IsShiftKeyDown() then
        local link = safeLink(itemId)
        if link then
            SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: "..link.." ("..itemId..")")
        end
        return
    end

    if IsControlKeyDown() then
        ns.ShowWowheadURLDialog(itemId)
        return
    end

    PlaySound("gsTitleOptionOK")

    setPreviewToItem(state.currentSlot, itemId)
    fn.refreshSlotButton(state.currentSlot)
    updatePreviewModel()
    updateStatusText()
    updateActionButtons()
    onListItemEnter(self)
end

-- Transmog slot buttons live on the dressing room (same positions as main slots).
-- They are children of transmogTab so they auto-show/hide with the tab.
for index, info in ipairs(SLOT_DATA) do
    local safeSlotName = info.name:gsub("[%s%-]", "")
    local button = CreateFrame("Button", (transmogTab:GetName() or addon.."Transmog").."Slot"..safeSlotName, transmogTab, "ItemButtonTemplate")
    button:SetFrameLevel(mainFrame.dressingRoom:GetFrameLevel() + 1)
    button:RegisterForClicks("LeftButtonUp")
    button.slotName = info.name
    button:SetScript("OnClick", onSlotButtonClick)
    button:SetScript("OnEnter", onSlotButtonEnter)
    button:SetScript("OnLeave", onSlotButtonLeave)
    button:GetHighlightTexture():SetAllPoints()  -- cover full icon (template default is 36x36 on 37x37 button)

    button.defaultTexture = button:CreateTexture(nil, "BACKGROUND")
    button.defaultTexture:SetAllPoints()
    button.defaultTexture:SetTexture(mainFrame.slots[info.name].textures.empty:GetTexture())

    button.pendingGlow = button:CreateTexture(nil, "OVERLAY")
    button.pendingGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.pendingGlow:SetBlendMode("ADD")
    button.pendingGlow:SetPoint("CENTER", 0, 0)
    button.pendingGlow:SetWidth(64)
    button.pendingGlow:SetHeight(64)
    button.pendingGlow:SetVertexColor(1, 0.82, 0)
    button.pendingGlow:Hide()

    button.hiddenLabel = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.hiddenLabel:SetPoint("CENTER", 0, 0)
    button.hiddenLabel:SetText("X")
    button.hiddenLabel:SetTextColor(1, 0.25, 0.25)
    button.hiddenLabel:Hide()

    state.slotButtons[info.name] = button
end

-- Position transmog slot buttons on the dressing room, mirroring main slot layout.
do
    local dr = mainFrame.dressingRoom
    local sb = state.slotButtons
    sb["Head"]:SetPoint("TOPLEFT", dr, "TOPLEFT", 16, -16)
    sb["Shoulder"]:SetPoint("TOP", sb["Head"], "BOTTOM", 0, -4)
    sb["Back"]:SetPoint("TOP", sb["Shoulder"], "BOTTOM", 0, -4)
    sb["Chest"]:SetPoint("TOP", sb["Back"], "BOTTOM", 0, -4)
    sb["Shirt"]:SetPoint("TOP", sb["Chest"], "BOTTOM", 0, -36)
    sb["Tabard"]:SetPoint("TOP", sb["Shirt"], "BOTTOM", 0, -4)
    sb["Wrist"]:SetPoint("TOP", sb["Tabard"], "BOTTOM", 0, -36)
    sb["Hands"]:SetPoint("TOPRIGHT", dr, "TOPRIGHT", -16, -16)
    sb["Waist"]:SetPoint("TOP", sb["Hands"], "BOTTOM", 0, -4)
    sb["Legs"]:SetPoint("TOP", sb["Waist"], "BOTTOM", 0, -4)
    sb["Feet"]:SetPoint("TOP", sb["Legs"], "BOTTOM", 0, -4)
    sb["Off-hand"]:SetPoint("BOTTOM", dr, "BOTTOM", 0, 16)
    sb["Main Hand"]:SetPoint("RIGHT", sb["Off-hand"], "LEFT", -4, 0)
    sb["Ranged"]:SetPoint("LEFT", sb["Off-hand"], "RIGHT", 4, 0)
end

-- ---- Weapon Illusion Buttons ----
-- Two small buttons at the bottom-right of the dressing room.
-- Left = Main Hand illusion, Right = Off-hand illusion.
-- Each opens the illusion grid on the right side panel for that weapon slot.
do
    local dr = mainFrame.dressingRoom
    local BTN_SIZE = 34
    local BTN_PAD  = 8

    local BTN_OFFSET_X = -18  -- pull in from the right border edge
    local BTN_OFFSET_Y =  18.5  -- lift above the bottom border edge

    -- Resolve the Blizzard global strings to their numeric values at runtime.
    -- In WotLK 3.3.5 these are numeric constants exposed as globals.
    -- Fall back to the well-known values in case the globals differ by locale.
    local function buildOHInvTypeSet()
        local t = {}
        -- numeric InventoryType values for one-hand / off-hand / two-hand wieldable weapons
        for _, v in ipairs({ 13, 14, 17 }) do t[v] = true end
        return t
    end
    local OH_ILLUSION_INVTYPE_IDS = buildOHInvTypeSet()

    -- Returns nil if the off-hand slot has nothing or an item that can't hold an
    -- enchant illusion (shield, held-in-off-hand, totem, etc.).
    -- Returns the itemId if it's a weapon that supports illusions.
    local function getOHIllusionWeaponId()
        local invSlot = GetInventorySlotInfo("SecondaryHandSlot")
        local itemId  = invSlot and GetInventoryItemID("player", invSlot)
        if not itemId then return nil end
        local _, _, _, _, _, _, _, _, invType = GetItemInfo(itemId)
        if not invType then return nil end
        -- Map string inv-type to numeric for comparison
        local numericType = nil
        if     invType == "INVTYPE_WEAPON"        then numericType = 13
        elseif invType == "INVTYPE_WEAPONOFFHAND" then numericType = 14
        elseif invType == "INVTYPE_2HWEAPON"      then numericType = 17
        end
        if OH_ILLUSION_INVTYPE_IDS[numericType] then
            return itemId
        end
        return nil  -- shield / held-in-off-hand / etc.
    end

    local ILLUSION_NAMES_BRIEF = {
        -- Names match SpellItemEnchantment.dbc
        [3789] = "Berserking",         [3854] = "+81 Spell Power",
        [3273] = "Deathfrost",         [3225] = "Executioner",
        [3870] = "Blood Draining",     [1899] = "Unholy Weapon",
        [2674] = "Spellsurge",         [2675] = "Battlemaster",
        [2671] = "Sunfire",            [2672] = "Soulfrost",
        [3365] = "Rune of Swordshattering", [2673] = "Mongoose",
        [2343] = "+43 Spell Power",    [425]  = "Black Temple Dummy",
        [3855] = "+69 Spell Power",    [1894] = "Icy Weapon",
        [1103] = "+26 Agility",        [1898] = "Lifestealing",
        [3345] = "Earthliving",        [1743] = "MHTest02",
        [3093] = "Demonslaying",       [1900] = "Crusader",
        [3846] = "+40 Spell Power",    [1606] = "+50 Attack Power",
        [283]  = "Windfury",           [1]    = "Rockbiter",
        [3265] = "Blessed Weapon Coating", [2]    = "Frostbrand",
        [3]    = "Flametongue",        [3266] = "Righteous Weapon Coating",
        [1903] = "+9 Spirit",          [13]   = "Sharpened",
        [26]   = "Frost Oil",          [7]    = "Deadly Poison",
        [803]  = "Fiery Weapon",       [1896] = "+9 Weapon Damage",
        [2666] = "+30 Intellect",      [25]   = "Shadow Oil",
    }

    local function makeIllusionButton(name, label, slotId, icon, xAnchor, isOffHand)
        -- Parent to mainFrame (not transmogTab) so the buttons remain visible
        -- when switching to the Settings tab, providing visual continuity.
        local btn = CreateFrame("Button", transmogTabName.."WeaponIllusion"..name, mainFrame, "ItemButtonTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn:SetFrameLevel(dr:GetFrameLevel() + 2)
        btn:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", xAnchor, BTN_OFFSET_Y)
        btn:RegisterForClicks("LeftButtonUp")

        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true,
            tileSize = 8,
            edgeSize = 0,
            insets = { left = -2, right = 0, top = 0, bottom = -2 },
        })
        btn:SetBackdropColor(0, 0, 0, 1)
        SetItemButtonTexture(btn, icon)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(label .. ABL(" Illusion"), 1, 1, 1)

            -- Off-hand: check whether the equipped item supports illusions.
            if isOffHand and not getOHIllusionWeaponId() then
                GameTooltip:AddLine(
                    "Equip a one-handed weapon in your Off-hand that supports illusions to apply an illusion to it.",
                    0.6, 0.6, 0.6, true)
                GameTooltip:Show()
                return
            end

            local slotName  = SLOT_NAME_BY_ID[slotId]
            local enchantId = slotName and state.illusionEnchants[slotName]
            local applied
            if enchantId == 0 then
                applied = "No Enchant"
            elseif enchantId then
                applied = ILLUSION_NAMES_BRIEF[enchantId] or ("Enchant #"..enchantId)
            else
                applied = "None"
            end
            GameTooltip:AddLine(ABL("Applied: ") .. applied, 1, 0.82, 0)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(ABL("Click to browse unlocked illusions."), 0.6, 0.6, 0.6, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:ClearLines()
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function()
            -- Off-hand: silently ignore click if the item doesn't support illusions.
            if isOffHand and not getOHIllusionWeaponId() then return end
            PlaySound("gsTitleOptionOK")
            transmogTab.illusionFrame.activeSlotId = slotId
            state.viewMode = "illusion"
            fn.updateViewMode()
        end)

        return btn
    end

    -- Off-hand illusion: bottom-right corner of the dressing room.
    transmogTab.buttonOHIllusion = makeIllusionButton(
        "OffHand",
        "Off-hand",
        SLOT_ID_BY_NAME["Off-hand"],
        "Interface\\Icons\\inv_enchant_disenchant",
        BTN_OFFSET_X,
        true   -- isOffHand
    )

    -- Main Hand illusion: immediately to the left of the Off-hand button.
    transmogTab.buttonMHIllusion = makeIllusionButton(
        "MainHand",
        "Main Hand",
        SLOT_ID_BY_NAME["Main Hand"],
        "Interface\\Icons\\inv_enchant_disenchant",
        BTN_OFFSET_X - BTN_SIZE - BTN_PAD,
        false  -- isOffHand
    )
end

transmogTab.searchLabel = transmogTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
transmogTab.searchLabel:SetPoint("TOPLEFT", 8, -8)
transmogTab.searchLabel:SetText("")
transmogTab.searchLabel:Hide()

transmogTab.searchBox = CreateFrame("EditBox", (transmogTab:GetName() or addon.."Transmog").."SearchBox", transmogTab, "InputBoxTemplate")
transmogTab.searchBox:SetPoint("TOPLEFT", transmogTab, "TOPLEFT", 8, -8)
transmogTab.searchBox:SetWidth(252)
transmogTab.searchBox:SetHeight(20)
transmogTab.searchBox:SetAutoFocus(false)
transmogTab.searchBox:SetTextInsets(6, 6, 0, 0)
transmogTab.searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
transmogTab.searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    fn.requestCurrentSlotItems(true)
end)

transmogTab.searchPlaceholder = transmogTab.searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
transmogTab.searchPlaceholder:SetPoint("LEFT", 6, 0)
transmogTab.searchPlaceholder:SetText(ABL("Search Item name or Display id"))

transmogTab.searchBox:SetScript("OnTextChanged", function(self)
    if self:GetText() == "" then
        transmogTab.searchPlaceholder:Show()
    else
        transmogTab.searchPlaceholder:Hide()
    end
end)

transmogTab.buttonSearch = CreateFrame("Button", transmogTabName.."ButtonSearch", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonSearch:SetPoint("LEFT", transmogTab.searchBox, "RIGHT", 8, 0)
transmogTab.buttonSearch:SetSize(70, 20)
transmogTab.buttonSearch:SetText(ABL("Search"))
transmogTab.buttonSearch:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    fn.requestCurrentSlotItems(true)
end)

transmogTab.buttonClearSearch = CreateFrame("Button", transmogTabName.."ButtonClearSearch", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonClearSearch:SetPoint("LEFT", transmogTab.buttonSearch, "RIGHT", 4, 0)
transmogTab.buttonClearSearch:SetSize(70, 20)
transmogTab.buttonClearSearch:SetText(ABL("Clear"))
transmogTab.buttonClearSearch:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    transmogTab.searchBox:SetText("")
    fn.loadCurrentSlotItems()
end)

-- Filter button: shows the active subclass filter; only visible for slots that
-- have more than one subclass (armour material or weapon type).
-- Lives on the second row (same row as Prev/Next) to avoid overlapping the Sets/Items buttons.
transmogTab.filterButton = CreateFrame("Button", transmogTabName.."FilterButton", transmogTab, "UIPanelButtonTemplate2")
transmogTab.filterButton:SetPoint("TOPLEFT", transmogTab, "TOPLEFT", 6, -36)
transmogTab.filterButton:SetSize(110, 20)
transmogTab.filterButton:SetText(ABL("Filter: All"))
transmogTab.filterButton:Hide()

transmogTab.rarityFilterButton = CreateFrame("Button", transmogTabName.."RarityFilterButton", transmogTab, "UIPanelButtonTemplate2")
transmogTab.rarityFilterButton:SetPoint("LEFT", transmogTab.filterButton, "RIGHT", 8, 0)
transmogTab.rarityFilterButton:SetSize(116, 20)
transmogTab.rarityFilterButton:SetText(ABL("Rarity Filter"))
transmogTab.rarityFilterButton:Show()

-- Singleton popup frame that lists the filter options for the current slot.
fn.filterPopup = CreateFrame("Frame", transmogTabName.."FilterPopup", UIParent)
-- TOOLTIP strata sits above FULLSCREEN_DIALOG (mainFrame) so the popup stays
-- on top even after a click on the addon main frame triggers Raise().
fn.filterPopup:SetFrameStrata("TOOLTIP")
fn.filterPopup:SetFrameLevel(110)
fn.filterPopup:SetToplevel(true)
fn.filterPopup:SetClampedToScreen(true)
fn.filterPopup:SetBackdrop({
    bgFile    = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile  = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
fn.filterPopup:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
fn.filterPopup:SetBackdropBorderColor(0.4, 0.4, 0.4)
fn.filterPopup:Hide()
fn.filterPopup.optionButtons = {}
tinsert(UISpecialFrames, fn.filterPopup:GetName())

local function closeFilterPopup()
    fn.filterPopup:Hide()
end

fn.rarityFilterPopup = CreateFrame("Frame", transmogTabName.."RarityFilterPopup", UIParent)
fn.rarityFilterPopup:SetFrameStrata("TOOLTIP")
fn.rarityFilterPopup:SetFrameLevel(110)
fn.rarityFilterPopup:SetToplevel(true)
fn.rarityFilterPopup:SetClampedToScreen(true)
fn.rarityFilterPopup:SetBackdrop({
    bgFile    = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile  = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
fn.rarityFilterPopup:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
fn.rarityFilterPopup:SetBackdropBorderColor(0.4, 0.4, 0.4)
fn.rarityFilterPopup:Hide()
fn.rarityFilterPopup.optionButtons = {}
tinsert(UISpecialFrames, fn.rarityFilterPopup:GetName())

local function closeRarityFilterPopup()
    fn.rarityFilterPopup:Hide()
end

local function updateRarityFilterPopupButtons()
    for index, option in ipairs(RARITY_OPTIONS) do
        local btn = fn.rarityFilterPopup.optionButtons[index]
        if btn then
            local isSelected = state.rarityFilter[option.quality] ~= false
            btn.lbl:SetText((isSelected and "[x] " or "[ ] ")..option.label)
            if isSelected then
                btn.lbl:SetTextColor(1, 0.82, 0)
            else
                btn.lbl:SetTextColor(1, 1, 1)
            end
        end
    end
end

local function showRarityFilterPopup()
    closeFilterPopup()

    for index, option in ipairs(RARITY_OPTIONS) do
        local btn = fn.rarityFilterPopup.optionButtons[index]
        if not btn then
            btn = CreateFrame("Button", nil, fn.rarityFilterPopup)
            btn:SetHeight(C.FILTER_BTN_H)
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT",  btn, "LEFT",  4, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
            lbl:SetJustifyH("LEFT")
            btn.lbl = lbl
            fn.rarityFilterPopup.optionButtons[index] = btn
        end

        btn:ClearAllPoints()
        local yOff = -C.FILTER_PAD - (index - 1) * (C.FILTER_BTN_H + C.FILTER_BTN_GAP)
        btn:SetPoint("TOPLEFT",  fn.rarityFilterPopup, "TOPLEFT",  C.FILTER_PAD,  yOff)
        btn:SetPoint("TOPRIGHT", fn.rarityFilterPopup, "TOPRIGHT", -C.FILTER_PAD, yOff)
        btn:Show()

        local capturedQuality = option.quality
        btn:SetScript("OnClick", function()
            state.rarityFilter[capturedQuality] = state.rarityFilter[capturedQuality] == false
            updateRarityFilterPopupButtons()
            fn.updateRarityFilterUI()
            fn.requestCurrentSlotItems(true)
        end)
    end

    local totalH = #RARITY_OPTIONS * (C.FILTER_BTN_H + C.FILTER_BTN_GAP) - C.FILTER_BTN_GAP + C.FILTER_PAD * 2
    fn.rarityFilterPopup:SetSize(C.FILTER_WIDTH, totalH)
    fn.rarityFilterPopup:ClearAllPoints()
    fn.rarityFilterPopup:SetPoint("BOTTOMLEFT", transmogTab.rarityFilterButton, "TOPLEFT", 0, 2)
    updateRarityFilterPopupButtons()
    fn.rarityFilterPopup:Show()
    fn.rarityFilterPopup:Raise()
end

local function showFilterPopup()
    local options = getSlotFilterOptions(state.currentSlot)
    if not options then return end
    closeRarityFilterPopup()

    local allOptions = {"All"}
    for _, sub in ipairs(options) do
        allOptions[#allOptions + 1] = sub
    end

    -- Hide any extra buttons left from a previous (longer) slot
    for i = #allOptions + 1, #fn.filterPopup.optionButtons do
        fn.filterPopup.optionButtons[i]:Hide()
    end

    local currentFilter = state.subclassFilter[state.currentSlot]

    for i, optionText in ipairs(allOptions) do
        local btn = fn.filterPopup.optionButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, fn.filterPopup)
            btn:SetHeight(C.FILTER_BTN_H)
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT",  btn, "LEFT",  4, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
            lbl:SetJustifyH("LEFT")
            btn.lbl = lbl
            fn.filterPopup.optionButtons[i] = btn
        end

        btn:ClearAllPoints()
        local yOff = -C.FILTER_PAD - (i - 1) * (C.FILTER_BTN_H + C.FILTER_BTN_GAP)
        btn:SetPoint("TOPLEFT",  fn.filterPopup, "TOPLEFT",  C.FILTER_PAD,  yOff)
        btn:SetPoint("TOPRIGHT", fn.filterPopup, "TOPRIGHT", -C.FILTER_PAD, yOff)
        btn.lbl:SetText(ABL(optionText))  -- сервер ждёт английское значение, переводим только подпись
        btn:Show()

        local isAll = (optionText == "All")
        local isSelected = (isAll and currentFilter == nil) or (not isAll and currentFilter == optionText)
        if isSelected then
            btn.lbl:SetTextColor(1, 0.82, 0)
        else
            btn.lbl:SetTextColor(1, 1, 1)
        end

        local capturedOption = optionText
        local capturedIsAll  = isAll
        btn:SetScript("OnClick", function()
            state.subclassFilter[state.currentSlot] = capturedIsAll and nil or capturedOption
            state.autoSubclassFilter[state.currentSlot] = nil
            state.manualSubclassFilter[state.currentSlot] = true
            fn.updateFilterUI()
            fn.requestCurrentSlotItems(true)
            closeFilterPopup()
        end)
    end

    local totalH = #allOptions * (C.FILTER_BTN_H + C.FILTER_BTN_GAP) - C.FILTER_BTN_GAP + C.FILTER_PAD * 2
    fn.filterPopup:SetSize(C.FILTER_WIDTH, totalH)
    fn.filterPopup:ClearAllPoints()
    fn.filterPopup:SetPoint("BOTTOMLEFT", transmogTab.filterButton, "TOPLEFT", 0, 2)
    fn.filterPopup:Show()
    fn.filterPopup:Raise()
end

transmogTab.filterButton:SetScript("OnClick", function()
    if fn.filterPopup:IsShown() then
        closeFilterPopup()
    else
        showFilterPopup()
    end
end)

transmogTab.rarityFilterButton:SetScript("OnClick", function()
    if fn.rarityFilterPopup:IsShown() then
        closeRarityFilterPopup()
    else
        showRarityFilterPopup()
    end
end)

fn.updateFilterUI = function()
    -- Illusion mode has no subclass concept — keep the filter button hidden
    -- regardless of the current slot's options.
    if state.viewMode == "illusion" then
        transmogTab.filterButton:Hide()
        closeFilterPopup()
        return
    end
    local options = getSlotFilterOptions(state.currentSlot)
    if not options then
        transmogTab.filterButton:Hide()
        closeFilterPopup()
        return
    end
    local currentFilter = state.subclassFilter[state.currentSlot]
    local filterLabel = currentFilter and (FILTER_SHORT_LABEL[currentFilter] or currentFilter) or "All"
    transmogTab.filterButton:SetText(ABL("Filter: ") .. ABL(filterLabel))
    transmogTab.filterButton:Show()
end

fn.updateRarityFilterUI = function()
    -- Rarity filter doesn't apply to illusions; hide it in illusion mode.
    if state.viewMode == "illusion" then
        transmogTab.rarityFilterButton:Hide()
        closeRarityFilterPopup()
        return
    end
    transmogTab.rarityFilterButton:SetText(ABL("Rarity Filter"))
    transmogTab.rarityFilterButton:Show()
    if fn.rarityFilterPopup:IsShown() then
        updateRarityFilterPopupButtons()
    end
end

transmogTab.buttonNext = CreateFrame("Button", transmogTabName.."ButtonNext", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonNext:SetPoint("TOPRIGHT", transmogTab, "TOPRIGHT", -6, -36)
transmogTab.buttonNext:SetSize(64, 20)
transmogTab.buttonNext:SetText(ABL("Next"))
transmogTab.buttonNext:SetScript("OnClick", function()
    if state.viewMode == "illusion" then
        local f = transmogTab.illusionFrame
        local pages = math.max(1, math.ceil(#f.illusionList / (f.perPage or 1)))
        if f.currentPage < pages then f._showPage(f.currentPage + 1) end
        return
    end
    changePage(1)
end)

transmogTab.pageText = transmogTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
transmogTab.pageText:SetPoint("CENTER", transmogTab, "TOP", 0, -46)
transmogTab.pageText:SetText(ABL("Page 1"))

transmogTab.buttonPrev = CreateFrame("Button", transmogTabName.."ButtonPrev", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonPrev:SetPoint("RIGHT", transmogTab.buttonNext, "LEFT", -6, 0)
transmogTab.buttonPrev:SetSize(64, 20)
transmogTab.buttonPrev:SetText(ABL("Prev"))
transmogTab.buttonPrev:SetScript("OnClick", function()
    if state.viewMode == "illusion" then
        local f = transmogTab.illusionFrame
        if f.currentPage > 1 then
            f._showPage(f.currentPage - 1)
        end
        return
    end
    changePage(-1)
end)

transmogTab.list = ns.CreatePreviewList(transmogTab)
transmogTab.list:SetPoint("TOPLEFT", 8, C.LIST_TOP_Y)
transmogTab.list:SetPoint("BOTTOMRIGHT", -8, C.LIST_BOTTOM_Y)
transmogTab.list:Hide()
transmogTab.list.onEnter = onListItemEnter
transmogTab.list.onLeave = onListItemLeave
transmogTab.list.onItemClick = onListItemClick
transmogTab.list.onVisibleItem = function()
    if transmogTab.messageText:GetText() == "Loading appearances..." then
        transmogTab.messageText:Hide()
        transmogTab.list:Show()
    end
    -- Check if all items on the current page have finished querying but none
    -- rendered a model.  If so, the page contains only unrenderable items
    -- and we should back up to the previous page.
    local drs = transmogTab.list.dressingRooms
    local anyQuerying = false
    local anyVisible = false
    for _, dr in ipairs(drs) do
        if dr.itemId then
            if dr.isQuerying then
                anyQuerying = true
            else
                anyVisible = true
            end
        end
    end
    if not anyQuerying and not anyVisible and state.currentPage > 1 then
        -- Every item on this page was hidden (query-failed).  Back up one
        -- page; the cap is session-only.  The newly-blacklisted items will
        -- be sent in the next request's excludeList so the server
        -- recomputes totalPages correctly.
        state.currentPage = state.currentPage - 1
        state.totalPages = state.currentPage
        state.hasMorePages = false
        state.pendingPage = nil
        fn.updatePageText()
        fn.requestCurrentSlotItems(false)
    elseif not anyQuerying and not anyVisible and state.currentPage == 1 then
        -- Page 1 and everything failed: show the empty message instead.
        state.totalPages = 1
        state.hasMorePages = false
        fn.updatePageText()
        showListMessage("No unlocked appearances for this slot yet.")
    elseif not anyQuerying and anyVisible then
        -- Page done loading.
        fn.updatePageText()
    end
end
transmogTab.list.onLoadingStateChanged = function(self, visibleItems, itemsThisPage)
    if (tonumber(itemsThisPage) or 0) > 0 and (tonumber(visibleItems) or 0) <= 0 then
        transmogTab.messageText:SetText(ABL("Loading appearances..."))
        transmogTab.messageText:Show()
        transmogTab.list:Show()
    elseif (tonumber(visibleItems) or 0) > 0 and transmogTab.messageText:GetText() == "Loading appearances..." then
        transmogTab.messageText:Hide()
        transmogTab.list:Show()
    end
end
transmogTab.list.onBackgroundClick = function()
    setPreviewToRestore(state.currentSlot)
    fn.refreshSlotButton(state.currentSlot)
    updatePreviewModel()
    updateStatusText()
    updateActionButtons()
end

transmogTab.messageText = transmogTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
transmogTab.messageText:SetPoint("TOPLEFT", transmogTab.list, "TOPLEFT", 20, -24)
transmogTab.messageText:SetPoint("BOTTOMRIGHT", transmogTab.list, "BOTTOMRIGHT", -20, 24)
transmogTab.messageText:SetJustifyH("CENTER")
transmogTab.messageText:SetJustifyV("MIDDLE")
transmogTab.messageText:SetTextColor(1, 0.82, 0)
transmogTab.messageText:Hide()



transmogTab.statusText = transmogTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

-- Attaches a hover tooltip to the given button. `body` is the descriptive sentence
-- shown beneath the title in white. Pass nil for `body` to show only the title.
local function attachButtonTooltip(button, title, body)
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(title, 1, 0.82, 0)
        if body then GameTooltip:AddLine(body, 1, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function sendWeaponIllusionApply(slotId, enchantId, source)
    slotId = tonumber(slotId)
    enchantId = tonumber(enchantId)
    if not slotId or enchantId == nil then
        return false
    end

    local sent = false
    if AIO and AIO.Msg then
        AIO.Msg():Add("ABIllusionApplyV3", slotId, enchantId):Send()
        sent = true
    end

    return sent
end

transmogTab.buttonApply = CreateFrame("Button", transmogTabName.."ButtonApply", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonApply:SetPoint("BOTTOMLEFT", 0, C.ACTION_ROW_Y)
transmogTab.buttonApply:SetSize(90, 22)
transmogTab.buttonApply:SetText(ABL("Apply"))
transmogTab.buttonApply:SetScript("OnClick", function()
    if state.viewMode == "illusion" or (transmogTab.illusionFrame and transmogTab.illusionFrame:IsShown()) then
        local f = transmogTab.illusionFrame
        local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        local enchantId = slotName and state.illusionEnchants[slotName]
        if enchantId == nil then enchantId = f.selectedEnchantId end
        if enchantId ~= nil and f.activeSlotId then
            if slotName and enchantId == state.illusionApplied[slotName] then
                updateActionButtons()
                return
            end
            -- Client-side gold check for non-free illusions.
            if enchantId ~= 0 and state.transmogCostEnabled then
                local cost = ns.getIllusionCost and ns.getIllusionCost() or 0
                if cost > 0 and GetMoney() < cost then
                    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Not enough gold! You need " .. ns.formatCoin(cost) .. " to apply this illusion.")
                    return
                end
            end
            PlaySound("gsTitleOptionOK")
            sendWeaponIllusionApply(f.activeSlotId, enchantId, "button")
            -- Do not mark the illusion as applied optimistically.  The server
            -- charges gold and writes the live visible enchant; wait for its
            -- SetStoredIllusions sync before confirming applied state locally.
            updateActionButtons()
        else
            return
        end
        return
    end

    if not isSlotDirty(state.currentSlot) then
        return
    end

    -- Client-side gold check for single slot apply
    if state.transmogCostEnabled and state.transmogCostPerSlot > 0 then
        local previewState = state.preview[state.currentSlot]
        if previewState.mode == "item" and previewState.itemId and previewState.itemId > 0 then
            local itemCost = ns.getCostForItem(previewState.itemId)
            if itemCost > 0 and GetMoney() < itemCost then
                SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Not enough gold! You need " .. ns.formatCoin(itemCost) .. " to apply this transmog.")
                return
            end
        end
    end

    PlaySound("gsTitleOptionOK")
    commitSlot(state.currentSlot)
    if ns.requestPreviewFullRedress then ns.requestPreviewFullRedress() end
    -- Do NOT call requestServerState() here: the confirming SetTransmogItemIdsBatch
    -- would arrive in a later frame and call updatePreviewModel() → Reset() →
    -- SetUnit("player"), which renders the OLD appearance because SMSG_UPDATE_OBJECT
    -- (updating PLAYER_VISIBLE_ITEM_X_ENTRYID) races the AIO batch.  The diff path
    -- then skips TryOn (effectiveId == dressedId per optimistic state) leaving the
    -- preview stuck on the old item.  commitSlot's optimistic update is correct;
    -- the server sends its own batch on failure (TransmogError/TransmogCostError)
    -- for error recovery without needing a client-initiated sync here.
    updatePreviewModel()
    updateStatusText()
    updateActionButtons()
end)

transmogTab.buttonHide = CreateFrame("Button", transmogTabName.."ButtonHide", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonHide:SetPoint("LEFT", transmogTab.buttonApply, "RIGHT", 6, 0)
transmogTab.buttonHide:SetSize(90, 22)
transmogTab.buttonHide:SetText(ABL("Hide"))
transmogTab.buttonHide:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    -- In illusion view, Hide always clears the active weapon's enchant glow (free),
    -- regardless of which non-weapon slot is currently selected on the left.
    if state.viewMode == "illusion" then
        local f = transmogTab.illusionFrame
        local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        if slotName then
            state.illusionEnchants[slotName] = 0
            -- Clear cell selection highlight; "No Enchant" cell will be re-highlighted by tooltip hover only.
            for _, cell in ipairs(f.cells) do
                cell._isSelected = (cell.enchantId == 0)
                if not cell._isSelected then
                    cell:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)
                end
            end
            updatePreviewModel()
            updateActionButtons()
        end
        return
    end
    setPreviewToHidden(state.currentSlot)
    fn.refreshSlotButton(state.currentSlot)
    updatePreviewModel()
    updateListSelection()
    updateStatusText()
    updateActionButtons()
end)

function ns.ClearWeaponIllusionOverride(slotName, slotId)
    if not slotName or not slotId then
        return false
    end

            ns.SafeAioHandle("Transmog", "ClearWeaponIllusion", slotId)
    state.illusionEnchants[slotName] = nil
    state.illusionApplied[slotName] = nil
    state.illusionStored[slotName] = nil
    return true
end

transmogTab.buttonRestore = CreateFrame("Button", transmogTabName.."ButtonRestore", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonRestore:SetPoint("LEFT", transmogTab.buttonHide, "RIGHT", 6, 0)
transmogTab.buttonRestore:SetSize(90, 22)
transmogTab.buttonRestore:SetText(ABL("Restore"))
transmogTab.buttonRestore:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    -- In illusion view, Restore removes the stored illusion override entirely
    -- so the weapon returns to its natural enchant / no-glow state.
    if state.viewMode == "illusion" then
        local f = transmogTab.illusionFrame
        local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        if slotName then
            ns.ClearWeaponIllusionOverride(slotName, f.activeSlotId)
            for _, cell in ipairs(f.cells) do
                cell._isSelected = false
                cell:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)
            end
            updatePreviewModel()
            updateStatusText()
            updateActionButtons()
        end
        return
    end
    setPreviewToRestore(state.currentSlot)
    fn.refreshSlotButton(state.currentSlot)
    updatePreviewModel()
    updateListSelection()
    updateStatusText()
    updateActionButtons()
end)

-- Calibrate / Copy buttons are shown/hidden by the Debug setting in the
-- Settings tab. Reparent them here so they sit in the correct action row;
-- visibility is controlled by AppearanceBuddy.lua's applySettings.
do
    local cb = transmogTab.list.calibBtn
    if cb then
        cb:SetParent(transmogTab)
        cb:ClearAllPoints()
        cb:SetPoint("LEFT", transmogTab.buttonRestore, "RIGHT", 6, 0)
        cb:SetSize(100, 22)
        cb:Hide()  -- hidden by default; shown when calibrationEnabled == true
    end
    local ccb = transmogTab.list.calibCopyBtn
    if ccb and cb then
        ccb:SetParent(transmogTab)
        ccb:ClearAllPoints()
        ccb:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        ccb:SetSize(58, 22)
        ccb:Hide()  -- shown only while Calibrate: ON
    end
end

-- Status text anchored to Restore (calibrate button may be hidden).
local _statusAnchor = transmogTab.buttonRestore
transmogTab.statusText:SetPoint("LEFT", _statusAnchor, "RIGHT", 8, 0)
transmogTab.statusText:SetPoint("RIGHT", transmogTab, "BOTTOMRIGHT", -7, C.ACTION_ROW_Y + 11)
transmogTab.statusText:SetJustifyH("LEFT")

-- Estimated cost, bottom-right corner, right-aligned.
transmogTab.costText = transmogTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
transmogTab.costText:SetPoint("BOTTOMRIGHT", transmogTab, "BOTTOMRIGHT", -7, C.ACTION_ROW_Y + 2)
transmogTab.costText:SetJustifyH("RIGHT")
transmogTab.costText:Hide()

transmogTab.buttonRevert = CreateFrame("Button", transmogTabName.."ButtonRevert", mainFrame, "UIPanelButtonTemplate2")
transmogTab.buttonRevert:Hide()
transmogTab.buttonRevert:SetSize(140, 22)
transmogTab.buttonRevert:SetText(ABL("Revert Preview"))
transmogTab.buttonRevert:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    revertAllPreview()
end)

transmogTab.buttonRevertAll = CreateFrame("Button", transmogTabName.."ButtonRevertAll", mainFrame, "UIPanelButtonTemplate2")
transmogTab.buttonRevertAll:Hide()
transmogTab.buttonRevertAll:SetSize(130, 22)
transmogTab.buttonRevertAll:SetText(ABL("Revert All"))
transmogTab.buttonRevertAll:SetScript("OnClick", function()
    if not hasAppliedTransmogs() then
        return
    end

    PlaySound("gsTitleOptionOK")
    -- Stage all server-applied slots as "restore" in the preview without
    -- sending to the server.  The player must click Apply All to commit.
    for _, info in ipairs(SLOT_DATA) do
        if state.server[info.name].itemId ~= nil then
            setPreviewToRestore(info.name)
        end
    end
    -- Clear weapon-illusion overrides on the server so the natural visual
    -- (perm enchant + any temp imbue like Windfury / Flametongue) returns.
    -- We send this immediately rather than staging it, because temp imbues
    -- live in the upper 16 bits of the visible-enchant field and can't be
    -- represented via TryOn() in the dressing room — only the live character
    -- can show them.  Server confirmation will refresh illusionApplied via
    -- SetStoredIllusions and the preview/buttons will update accordingly.
    for _, slotName in ipairs({ "Main Hand", "Off-hand" }) do
        if state.illusionStored[slotName] then
            local slotId = SLOT_ID_BY_NAME[slotName]
            ns.ClearWeaponIllusionOverride(slotName, slotId)
        end
    end
    refreshAllSlotButtons()
    updatePreviewModel()
    updateStatusText()
    updateActionButtons()
end)

transmogTab.buttonApplyAll = CreateFrame("Button", transmogTabName.."ButtonApplyAll", mainFrame, "UIPanelButtonTemplate2")
transmogTab.buttonApplyAll:Hide()
transmogTab.buttonApplyAll:SetSize(130, 22)
transmogTab.buttonApplyAll:SetText(ABL("Apply All"))
transmogTab.buttonApplyAll:SetScript("OnClick", function()
    if getDirtyCount() == 0 then
        return
    end

    -- Client-side gold check for all pending slots (transmog items + illusions).
    if state.transmogCostEnabled then
        local totalCost = 0
        if state.transmogCostPerSlot > 0 then
            totalCost = totalCost + ns.getChargeableDirtyCost()
        end
        -- Add pending illusion costs; enchantId 0 ("hide") is always free.
        local illusionCostPerSlot = ns.getIllusionCost and ns.getIllusionCost() or 0
        if illusionCostPerSlot > 0 then
            for _, illusionSlotName in ipairs({"Main Hand", "Off-hand"}) do
                local sel = state.illusionEnchants[illusionSlotName]
                local app = state.illusionApplied[illusionSlotName]
                if sel ~= nil and sel ~= app and sel ~= 0 then
                    totalCost = totalCost + illusionCostPerSlot
                end
            end
        end
        if totalCost > 0 and GetMoney() < totalCost then
            SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Not enough gold! You need " .. ns.formatCoin(totalCost) .. " to apply all changes.")
            return
        end
    end

    PlaySound("gsTitleOptionOK")
    for _, info in ipairs(SLOT_DATA) do
        if isSlotDirty(info.name) then
            commitSlot(info.name)
        end
    end

    -- Also commit any pending weapon illusion changes.
    for _, slotName in ipairs({"Main Hand", "Off-hand"}) do
        local selected = state.illusionEnchants[slotName]
        local applied  = state.illusionApplied[slotName]
        if selected ~= nil and selected ~= applied then
            local slotId = SLOT_ID_BY_NAME[slotName]
            if slotId then
                sendWeaponIllusionApply(slotId, selected, "apply_all")
            end
        end
    end

    if ns.requestPreviewFullRedress then ns.requestPreviewFullRedress() end
    -- Do NOT call requestServerState() here — same race as single-slot Apply:
    -- the confirming batch resets the model to old appearance before
    -- SMSG_UPDATE_OBJECT updates the client's visible-item field.
    refreshAllSlotButtons()
    updatePreviewModel()
    updateStatusText()
    updateActionButtons()
end)

-- Position the 3 global transmog action buttons under the dressing room
-- (main Use Target/Undress/Reset/Send buttons are hidden while transmog tab is open).
do
    local dr = mainFrame.dressingRoom
    transmogTab.buttonRevertAll:SetPoint("TOPLEFT", dr, "BOTTOMLEFT", 0, 0)
    transmogTab.buttonRevert:SetPoint("LEFT", transmogTab.buttonRevertAll, "RIGHT", 0, 0)
    transmogTab.buttonApplyAll:SetPoint("TOPRIGHT", dr, "BOTTOMRIGHT", 0, 0)

    -- Re-anchor the right action group (Apply/Hide/Restore) so its baseline
    -- matches the left group exactly, instead of relying on absolute pixel maths.
    transmogTab.buttonApply:ClearAllPoints()
    transmogTab.buttonApply:SetPoint("BOTTOMLEFT", transmogTab.buttonApplyAll, "BOTTOMRIGHT", 1, 0)

    local actionLevel = math.max(
        transmogTab:GetFrameLevel() + 20,
        (transmogTab.illusionFrame and transmogTab.illusionFrame:GetFrameLevel() or 0) + 10
    )
    for _, btn in ipairs({
        transmogTab.buttonRevertAll,
        transmogTab.buttonRevert,
        transmogTab.buttonApplyAll,
        transmogTab.buttonApply,
        transmogTab.buttonHide,
        transmogTab.buttonRestore,
    }) do
        if btn then btn:SetFrameLevel(actionLevel) end
    end
end

-- Editing set buttons (shown in Items mode while editing a saved set)
transmogTab.buttonSaveSet = CreateFrame("Button", transmogTabName.."ButtonSaveSet", mainFrame, "UIPanelButtonTemplate2")
transmogTab.buttonSaveSet:Hide()
transmogTab.buttonSaveSet:SetSize(130, 22)
transmogTab.buttonSaveSet:SetText(ABL("Save Set"))
transmogTab.buttonSaveSet:SetScript("OnClick", function()
    if not state.editingSetName then return end
    PlaySound("gsTitleOptionOK")
    fn.confirmSaveEditedSet()
end)

transmogTab.buttonCancelEdit = CreateFrame("Button", transmogTabName.."ButtonCancelEdit", mainFrame, "UIPanelButtonTemplate2")
transmogTab.buttonCancelEdit:Hide()
transmogTab.buttonCancelEdit:SetSize(130, 22)
transmogTab.buttonCancelEdit:SetText(ABL("Cancel Edit"))
transmogTab.buttonCancelEdit:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    fn.cancelEditSavedSet()
end)

do
    local dr = mainFrame.dressingRoom
    transmogTab.buttonCancelEdit:SetPoint("TOPLEFT", dr, "BOTTOMLEFT", 0, 0)
    transmogTab.buttonSaveSet:SetPoint("TOPRIGHT", dr, "BOTTOMRIGHT", 0, 0)
end

transmogTab.buttonModeItems = CreateFrame("Button", transmogTabName.."ButtonModeItems", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonModeItems:SetPoint("RIGHT", transmogTab.buttonNext, "RIGHT", 0, 28)
transmogTab.buttonModeItems:SetSize(64, 20)
transmogTab.buttonModeItems:SetText(ABL("Items"))

transmogTab.buttonModeSets = CreateFrame("Button", transmogTabName.."ButtonModeSets", transmogTab, "UIPanelButtonTemplate2")
transmogTab.buttonModeSets:SetPoint("RIGHT", transmogTab.buttonModeItems, "LEFT", -6, 0)
transmogTab.buttonModeSets:SetSize(64, 20)
transmogTab.buttonModeSets:SetText(ABL("Sets"))

-- ── Share / Import controls (same row as Sets/Items mode buttons) ────────────
-- "Copy Set" puts the selected saved set's share code into the editbox (and
-- selects all text for easy Ctrl+C).  "Link Set" inserts the code into the
-- active chat editbox.  Pasting a valid code into the editbox and pressing
-- Enter imports it as a new saved set.
do
    local shareBtn = CreateFrame("Button", transmogTabName.."ButtonShareLink", transmogTab, "UIPanelButtonTemplate2")
    shareBtn:SetSize(78, 22)
    shareBtn:SetText(ABL("Link Set"))
    -- Anchored later (after setsFrame.buttonEditSaved exists) in the bottom action row.
    shareBtn:Hide()
    transmogTab.buttonShareLink = shareBtn

    local copyBtn = CreateFrame("Button", transmogTabName.."ButtonShareCopy", transmogTab, "UIPanelButtonTemplate2")
    copyBtn:SetSize(78, 22)
    copyBtn:SetText(ABL("Copy Set"))
    copyBtn:Hide()
    transmogTab.buttonShareCopy = copyBtn

    -- Edit box for pasting share codes. Sits in the bottom action row, to the
    -- right of the Edit / Copy Set / Link Set buttons.
    local eb = CreateFrame("EditBox", transmogTabName.."ShareEditBox", transmogTab, "InputBoxTemplate")
    eb:SetSize(180, 20)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(512)
    eb:SetFontObject("ChatFontNormal")
    eb:Hide()
    transmogTab.shareEditBox = eb

    -- Show placeholder text when the box is empty.
    local placeholder = eb:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetAllPoints()
    placeholder:SetJustifyH("LEFT")
    placeholder:SetText(ABL("Paste share code and press Enter…"))
    eb:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then placeholder:Show() else placeholder:Hide() end
    end)
    placeholder:Show()

    -- Press Enter: import if the box has content; otherwise ignore.
    eb:SetScript("OnEnterPressed", function(self)
        local code = self:GetText()
        if code ~= "" then
            local setData = decodeShareStringToSet(code)
            if fn.importShareString and fn.importShareString(code) then
                self:SetText("")
                self:ClearFocus()
                if setData and ns.PreviewLinkedSet then
                    ns.PreviewLinkedSet(setData)
                end
            end
        end
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
end

-- Illusion panel: overlays the item list area when viewMode == "illusion".
transmogTab.illusionFrame = CreateFrame("Frame", transmogTabName.."IllusionFrame", transmogTab)
transmogTab.illusionFrame:SetPoint("TOPLEFT", 8, C.LIST_TOP_Y)
transmogTab.illusionFrame:SetPoint("BOTTOMRIGHT", -8, C.LIST_BOTTOM_Y)
transmogTab.illusionFrame:Hide()

do
    local f = transmogTab.illusionFrame
    f.activeSlotId  = nil
    f.currentPage   = 1
    f.perPage       = 6        -- updated by showPage() once frame has real dimensions
    f.illusionList  = {}
    f.weaponItemId  = nil
    f._previewX     = 0
    f._previewY     = 0
    f._previewZ     = 0
    f._previewFacing = 0
    f._previewSeq   = 3

    -- All available illusion enchant IDs (same pool as mod-ale's random-visual script).
    -- Temporary: full access for every player.  Replace ns.unlockedIllusionIds seeding
    -- with per-player server data when per-player tracking is implemented.
    local ILLUSION_IDS = {
        3789, 3854, 3273, 3225, 3870, 1899, 2674, 2675, 2671, 2672,
        3365, 2673, 2343,  425, 3855, 1894, 1103, 1898, 3345, 1743,
        3093, 1900, 3846, 1606,  283,    1, 3265,    2,    3, 3266,
        1903,   13,   26,    7,  803, 1896, 2666,   25,
    }
    local ILLUSION_NAMES = {
        -- Names match SpellItemEnchantment.dbc (verified against build 3.4.3.53622)
        [3789] = "Berserking",         [3854] = "+81 Spell Power",
        [3273] = "Deathfrost",         [3225] = "Executioner",
        [3870] = "Blood Draining",     [1899] = "Unholy Weapon",
        [2674] = "Spellsurge",         [2675] = "Battlemaster",
        [2671] = "Sunfire",            [2672] = "Soulfrost",
        [3365] = "Rune of Swordshattering", [2673] = "Mongoose",
        [2343] = "+43 Spell Power",    [425]  = "Black Temple Dummy",
        [3855] = "+69 Spell Power",    [1894] = "Icy Weapon",
        [1103] = "+26 Agility",        [1898] = "Lifestealing",
        [3345] = "Earthliving",        [1743] = "MHTest02",
        [3093] = "Demonslaying",       [1900] = "Crusader",
        [3846] = "+40 Spell Power",    [1606] = "+50 Attack Power",
        [283]  = "Windfury",           [1]    = "Rockbiter",
        [3265] = "Blessed Weapon Coating", [2]    = "Frostbrand",
        [3]    = "Flametongue",        [3266] = "Righteous Weapon Coating",
        [1903] = "+9 Spirit",          [13]   = "Sharpened",
        [26]   = "Frost Oil",          [7]    = "Deadly Poison",
        [803]  = "Fiery Weapon",       [1896] = "+9 Weapon Damage",
        [2666] = "+30 Intellect",      [25]   = "Shadow Oil",
    }

    local CELL_W    = C.PREVIEW_CARD_WIDTH    -- 120
    local CELL_H    = C.PREVIEW_CARD_HEIGHT   -- 112
    local MAX_CELLS = 15  -- up to 3×5 to match the regular item grid; extras hidden when the grid is shorter

    local cellBackdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, tileSize = 8,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    }
    -- ── Header ───────────────────────────────────────────────────────────────
    -- ── Grid container (fills the full panel; page nav sits at the bottom) ───
    f.gridFrame = CreateFrame("Frame", transmogTabName.."IllusionGrid", f)
    f.gridFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     0,   0)
    f.gridFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0,   0)

    -- ── Mini DressingRoom cells (up to MAX_CELLS) ─────────────────────────────
    f.cells = {}
    for i = 1, MAX_CELLS do
        local dr = ns.CreateDressingRoom(transmogTabName.."IllusionCell"..i, f.gridFrame)
        dr:SetSize(CELL_W, CELL_H)
        dr:EnableDragRotation(false)
        dr:EnableMouseWheel(false)
        dr:SetBackdrop(cellBackdrop)
        dr:SetBackdropColor(0.25, 0.25, 0.25, 1)
        ns.RegisterMiniDR(dr)

        -- Border: 4 solid-color OVERLAY textures on a child Frame of dr.model.
        -- Identical technique to PreviewList.lua — textures parented to a child
        -- Frame of the DressUpModel are immune to vertex-color resets that
        -- occur on TryOn / Undress / Reset.
        do
            local _BT = 2
            local _r, _g, _b, _a = 0.6, 0.52, 0.28, 1.0
            local borderHolder = CreateFrame("Frame", nil, dr.model)
            borderHolder:SetAllPoints(dr.model)
            borderHolder:EnableMouse(false)
            borderHolder:EnableMouseWheel(false)
            local _eTop    = borderHolder:CreateTexture(nil, "OVERLAY")
            local _eBottom = borderHolder:CreateTexture(nil, "OVERLAY")
            local _eLeft   = borderHolder:CreateTexture(nil, "OVERLAY")
            local _eRight  = borderHolder:CreateTexture(nil, "OVERLAY")
            _eTop:SetTexture(_r, _g, _b, _a)
            _eTop:SetPoint("TOPLEFT",  borderHolder, "TOPLEFT",  0,  0)
            _eTop:SetPoint("TOPRIGHT", borderHolder, "TOPRIGHT", 0,  0)
            _eTop:SetHeight(_BT)
            _eBottom:SetTexture(_r, _g, _b, _a)
            _eBottom:SetPoint("BOTTOMLEFT",  borderHolder, "BOTTOMLEFT",  0, 0)
            _eBottom:SetPoint("BOTTOMRIGHT", borderHolder, "BOTTOMRIGHT", 0, 0)
            _eBottom:SetHeight(_BT)
            _eLeft:SetTexture(_r, _g, _b, _a)
            _eLeft:SetPoint("TOPLEFT",    borderHolder, "TOPLEFT",    0, 0)
            _eLeft:SetPoint("BOTTOMLEFT", borderHolder, "BOTTOMLEFT", 0, 0)
            _eLeft:SetWidth(_BT)
            _eRight:SetTexture(_r, _g, _b, _a)
            _eRight:SetPoint("TOPRIGHT",    borderHolder, "TOPRIGHT",    0, 0)
            _eRight:SetPoint("BOTTOMRIGHT", borderHolder, "BOTTOMRIGHT", 0, 0)
            _eRight:SetWidth(_BT)
            dr._borderEdges = {_eTop, _eBottom, _eLeft, _eRight}
            function dr:SetBackdropBorderColor(r, g, b, a)
                a = a or 1
                for _, e in ipairs(self._borderEdges) do e:SetTexture(r, g, b, a) end
            end
        end
        dr._isSelected = false

        local pulseT = 0
        dr:HookScript("OnUpdate", function(self, elapsed)
            if not self._isSelected then return end
            pulseT = pulseT + elapsed
            local v = math.abs(math.sin(pulseT * 3))
            self:SetBackdropBorderColor(1, 0.85 * v + 0.15, 0, 1)
        end)
        dr:HookScript("OnShow", function(self)
            if not self._isSelected then
                self:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)
            end
        end)

        -- Hover highlight overlay.
        local hi = dr:CreateTexture(nil, "HIGHLIGHT")
        hi:SetAllPoints()
        hi:SetTexture("Interface\\Buttons\\ButtonHilight-Square")

        -- Invisible click button on top of the model.
        local btn = CreateFrame("Button", nil, dr)
        btn:SetAllPoints()
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp")

        btn:SetScript("OnEnter", function(self)
            if dr.enchantId == nil then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:ClearLines()
            if dr.enchantId == 0 then
                GameTooltip:AddLine(ABL("No Enchant"), 1, 1, 1)
                GameTooltip:AddLine(ABL("Hides your weapon's enchantment glow."), 1, 1, 1, 1, true)
                GameTooltip:AddLine(ABL("Free of charge."), 0.2, 1, 0.2, 1)
            else
                GameTooltip:AddLine(ILLUSION_NAMES[dr.enchantId] or (ABL("Enchant #")..dr.enchantId), 1, 1, 1)
                GameTooltip:AddLine(ABL("Id: ")..dr.enchantId, 0.7, 0.7, 0.7)
                GameTooltip:AddLine(ABL("Click to preview. Hit Apply to equip."), 1, 1, 1, 1, true)
                if state.transmogCostEnabled then
                    local cost = ns.getIllusionCost and ns.getIllusionCost() or 0
                    if cost > 0 then
                        GameTooltip:AddLine(ABL("Cost: ") .. ns.formatCoin(cost), 1, 0.82, 0)
                    end
                end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        btn:SetScript("OnClick", function()
            if dr.enchantId == nil or not f.activeSlotId then return end  -- 0 is valid (No Enchant)
            PlaySound("gsTitleOptionOK")
            -- Update selection highlight on all cells.
            for _, cell in ipairs(f.cells) do
                cell._isSelected = (cell == dr)
                if not cell._isSelected then
                    cell:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)
                end
            end
            -- Store as pending preview only; Apply button sends it to the server.
            local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
            f.selectedEnchantId = dr.enchantId
            if slotName then state.illusionEnchants[slotName] = dr.enchantId end
            updatePreviewModel()
            updateActionButtons()
        end)

        dr.button    = btn
        dr.enchantId = nil
        dr:Hide()
        f.cells[i] = dr
    end

    -- ── Placeholder (shown when there's nothing to display) ───────────────────
    f.infoText = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    f.infoText:SetPoint("CENTER", f.gridFrame, "CENTER", 0, 0)
    f.infoText:SetJustifyH("CENTER")
    f.infoText:SetText("")
    f.infoText:Hide()

    -- Pagination is handled by the top-level transmogTab.buttonPrev/buttonNext/pageText.

    -- ── Cell loader ───────────────────────────────────────────────────────────
    -- Fills one DR cell with the player's weapon wearing the given enchant visual.
    local function loadCell(dr, enchantId)
        dr.enchantId   = enchantId
        dr._isSelected = false
        dr:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)

        if not f.weaponItemId then
            dr:Hide()
            return
        end

        dr:Show()
        dr:Reset()
        -- z=0 centers the model vertically to match weapon preview placement.
        -- Apply the same per-race / per-sex / mode-aware offset the main mini
        -- preview grid uses, so the illusion cells mirror the user's tuning
        -- and respect static/dynamic mode.
        local _slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        local _ox, _oy, _oz = 0, 0, 0
        if ns.GetMiniPreviewSlotOffset then
            _ox, _oy, _oz = ns.GetMiniPreviewSlotOffset(_slotName)
        end
        if ns.ApplyMiniPreviewPosition then
            ns.ApplyMiniPreviewPosition(dr, f._previewX + _ox, f._previewY + _oy, _oz)
        else
            dr:SetPosition(f._previewX + _ox, f._previewY + _oy, _oz)
        end
        dr:SetFacing(ns.GetDynamicMiniFacing and ns.GetDynamicMiniFacing(f._previewFacing) or f._previewFacing)

        -- Strip EVERYTHING the model came with after Reset (which leaves the
        -- player's real equipped gear).  The custom mini-DR only exposes a full
        -- Undress() — no per-slot UndressSlot — so we must wipe the slate clean
        -- and re-dress only what we want, otherwise the player's real OH/MH
        -- weapons leak through and the cell shows the same weapon in both hands
        -- (TryOn(INVTYPE_WEAPON) routes to MH; the existing OH from Reset stays
        -- visible → "two of the same dagger" bug).
        dr:Undress()

        -- Re-add the current transmog outfit as context (non-weapon slots ONLY).
        if not ns.itemOnlyView then
            local slotName    = SLOT_NAME_BY_ID[f.activeSlotId]
            local outfitItems = ns.GetTransmogOutfitItems and ns.GetTransmogOutfitItems(slotName)
            if outfitItems then
                for _, id in ipairs(outfitItems) do
                    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
                    local isWeapon = equipLoc and (
                           equipLoc == "INVTYPE_WEAPON"
                        or equipLoc == "INVTYPE_2HWEAPON"
                        or equipLoc == "INVTYPE_WEAPONMAINHAND"
                        or equipLoc == "INVTYPE_WEAPONOFFHAND"
                        or equipLoc == "INVTYPE_RANGED"
                        or equipLoc == "INVTYPE_RANGEDRIGHT"
                        or equipLoc == "INVTYPE_THROWN"
                        or equipLoc == "INVTYPE_SHIELD"
                        or equipLoc == "INVTYPE_HOLDABLE")
                    if not isWeapon then dr:TryOn(id) end
                end
            end
        end

        -- enchantId=0 means "No Enchant" — show the weapon without any glow.
        --
        -- Slot routing: DressUpModel:TryOn takes only one argument in 3.3.5;
        -- there is no slot-override parameter.  The engine always routes a
        -- generic INVTYPE_WEAPON to MainHand when that slot is empty.
        -- To show an OH weapon in the LEFT hand we first TryOn the sibling MH
        -- item (which occupies the right hand), then TryOn the OH weapon — the
        -- engine then has no choice but to route it to the off-hand.
        -- Conversely, for MH preview with an occupied OH we do nothing special
        -- because MH is always filled first.
        if f.activeSlotId == 315 and f.siblingItemId and f.siblingItemId > 0 then
            -- Occupy the right hand with the MH weapon first.
            dr:TryOn(f.siblingItemId)
        end

        if enchantId and enchantId > 0 then
            local link = string.format(
                "|Hitem:%d:%d:0:0:0:0:0:0:0:0|h[Weapon]|h",
                f.weaponItemId, enchantId
            )
            dr:TryOn(link)
        elseif enchantId == 0 then
            -- Explicitly hidden: force-suppress natural glow.
            dr:TryOn(string.format("|Hitem:%d:0:0:0:0:0:0:0:0:0|h[Weapon]|h", f.weaponItemId))
        else
            dr:TryOn(f.weaponItemId)
        end

        -- Set the standing-idle animation once the async model load completes.
        local seq = f._previewSeq
        dr:OnUpdateModel(function(self) self:SetSequence(seq) end)
    end

    -- ── Page renderer ──────────────────────────────────────────────────────────
    local function showPage(page)
        -- Compute grid geometry from the actual frame dimensions (may be 0 on
        -- first call if the frame hasn't been laid out yet; fall back to 3×2).
        local gridW   = f.gridFrame:GetWidth()
        local gridH   = f.gridFrame:GetHeight()
        local cols    = math.max(1, gridW > 0 and math.floor(gridW / CELL_W) or 3)
        local rows    = math.max(1, gridH > 0 and math.floor(gridH / CELL_H) or 2)
        local perPage = math.min(cols * rows, MAX_CELLS)
        local gapW    = gridW > 0 and ((gridW - cols * CELL_W) / 2) or 0
        local gapH    = gridH > 0 and ((gridH - rows * CELL_H) / 2) or 0

        f.perPage     = perPage
        f.currentPage = page

        local total  = #f.illusionList
        local pages  = math.max(1, math.ceil(total / perPage))
        local offset = (page - 1) * perPage

        for i, dr in ipairs(f.cells) do
            local enchantId = f.illusionList[offset + i]
            if enchantId and i <= perPage then
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                dr:ClearAllPoints()
                dr:SetPoint("TOPLEFT", f.gridFrame, "TOPLEFT",
                    gapW + col * CELL_W, -(gapH + row * CELL_H))
                loadCell(dr, enchantId)
            else
                dr.enchantId = nil
                dr:Hide()
            end
        end

        -- Re-sync selection highlight: mark the cell whose enchantId matches the
        -- current pending choice.  loadCell resets _isSelected = false, so without
        -- this a user navigating pages would lose the gold border on their selection.
        local _selSlot = SLOT_NAME_BY_ID[f.activeSlotId]
        local _pendingId = _selSlot and state.illusionEnchants[_selSlot]
        for _, dr in ipairs(f.cells) do
            if dr:IsShown() and dr.enchantId ~= nil then
                dr._isSelected = (dr.enchantId == _pendingId)
                if not dr._isSelected then
                    dr:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)
                end
            end
        end

        setEnabled(transmogTab.buttonPrev, page > 1)
        setEnabled(transmogTab.buttonNext, page < pages)
        transmogTab.pageText:SetText(pages > 1 and (ABL("Page ")..page.." / "..pages) or (ABL("Page ")..page))
    end

    -- Expose showPage so the top-level Prev/Next buttons can call it.
    f._showPage = showPage

    -- ── Facing + zoom sync with the main dressing room (mirrors PreviewList) ──
    f.gridFrame:SetScript("OnUpdate", function(self)
        local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
        if not mainDR then return end
        -- Re-derive per-race / per-mode offsets every frame so that toggling
        -- static <-> dynamic or changing race tunings while the grid is open
        -- updates the cells live.  Position + facing routing matches the main
        -- mini preview grid (ApplyMiniPreviewPosition handles dynamic zoom
        -- sync clamps; in static mode it just calls SetPosition).
        local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        local ox, oy, oz = 0, 0, 0
        if ns.GetMiniPreviewSlotOffset then
            ox, oy, oz = ns.GetMiniPreviewSlotOffset(slotName)
        end
        local facing = ns.GetDynamicMiniFacing and ns.GetDynamicMiniFacing(f._previewFacing) or f._previewFacing
        for _, dr in ipairs(f.cells) do
            if dr:IsShown() then
                dr:SetFacing(facing)
                if ns.ApplyMiniPreviewPosition then
                    ns.ApplyMiniPreviewPosition(dr, f._previewX + ox, f._previewY + oy, oz)
                else
                    dr:SetPosition(f._previewX + ox, f._previewY + oy, oz)
                end
            end
        end
    end)

    -- ── Public API ────────────────────────────────────────────────────────────

    -- Refreshes the weapon icon and caches weapon item ID + model preview setup
    -- for the currently active slot.  Must be called before populate().
    -- Caches the displayed weapon item ID and model-space preview setup for the
    -- active slot.  Must be called before populate().
    function f.updateWeaponIcon()
        local slotName = SLOT_NAME_BY_ID[f.activeSlotId]
        local invToken = slotName and C.INVENTORY_TOKEN_BY_SLOT_NAME[slotName]
        local invSlot  = invToken and GetInventorySlotInfo(invToken .. "Slot")

        -- Pick what the cell actually renders for this weapon.  Use the
        -- DISPLAYED appearance (transmog if any, else real) so the illusion
        -- preview matches what the player sees in-world.  Falling back to the
        -- real equipped item only when no transmog has been applied.
        local function displayedItemForSlot(name)
            if not name then return nil end
            local serverSt = state.server and state.server[name]
            if serverSt then
                if serverSt.itemId and serverSt.itemId > 0 then
                    return serverSt.itemId
                end
                if serverSt.realItemId and serverSt.realItemId > 0 then
                    return serverSt.realItemId
                end
            end
            local tok = C.INVENTORY_TOKEN_BY_SLOT_NAME[name]
            local s   = tok and GetInventorySlotInfo(tok .. "Slot")
            return s and GetInventoryItemID("player", s) or nil
        end

        f.weaponItemId = displayedItemForSlot(slotName)
            or (invSlot and GetInventoryItemID("player", invSlot) or nil)

        -- Sibling weapon (MH when previewing OH, OH when previewing MH).  Used
        -- by loadCell to occupy the sibling hand first so the previewed weapon
        -- routes into the correct hand (TryOn always sends INVTYPE_WEAPON to
        -- MH when empty).  Also resolves to the displayed appearance.
        local siblingSlotId  = (f.activeSlotId == 315) and 313 or (f.activeSlotId == 313) and 315 or nil
        local siblingName    = siblingSlotId and SLOT_NAME_BY_ID[siblingSlotId]
        f.siblingItemId      = displayedItemForSlot(siblingName)

        local effectiveSlot = slotName or "Main Hand"
        local _, _, bx, by, bz, bfacing, bseq = getListPreviewSetup(effectiveSlot)
        f._previewX      = bx      or 0
        f._previewY      = by      or 0
        f._previewZ      = bz      or 0
        f._previewFacing = bfacing or 0
        f._previewSeq    = bseq    or 3
    end

    -- Rebuilds the illusion list from ns.unlockedIllusionIds and renders page 1.
    function f.populate()
        local ids        = ns.unlockedIllusionIds
        local hasEntries = type(ids) == "table" and next(ids) ~= nil

        -- "No Enchant" (id=0) is always the first entry so the player can hide their
        -- weapon's enchantment glow for free, regardless of what illusions they own.
        f.illusionList = { 0 }
        if hasEntries then
            for id in pairs(ids) do
                f.illusionList[#f.illusionList + 1] = id
            end
            -- Sort with 0 kept first, then ascending by id.
            table.sort(f.illusionList, function(a, b)
                if a == 0 then return true end
                if b == 0 then return false end
                return a < b
            end)
        end

        -- Show the grid whenever a weapon is equipped; "No Enchant" is always available.
        if not f.weaponItemId then
            for _, dr in ipairs(f.cells) do
                dr.enchantId = nil
                dr:Hide()
            end
            f.infoText:SetText(ABL("No weapon equipped in this slot."))
            f.infoText:Show()
            setEnabled(transmogTab.buttonPrev, false)
            setEnabled(transmogTab.buttonNext, false)
            transmogTab.pageText:SetText("")
        else
            f.infoText:Hide()
            showPage(1)
        end
    end

    -- Seed ns.unlockedIllusionIds with every available illusion (temporary full access).
    ns.unlockedIllusionIds = {}
    for _, id in ipairs(ILLUSION_IDS) do
        ns.unlockedIllusionIds[id] = true
    end
end

transmogTab.setsFrame = CreateFrame("Frame", transmogTabName.."SetsFrame", transmogTab)
transmogTab.setsFrame:SetPoint("TOPLEFT", 8, -34)
transmogTab.setsFrame:SetPoint("BOTTOMRIGHT", -8, C.SETS_FRAME_BOTTOM_Y)
transmogTab.setsFrame:Hide()

do
    local setsFrame = transmogTab.setsFrame
    local previewBackdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

    -- Source-toggle buttons: same Y row as the Sets / Items buttons in the top-right.
    -- setsFrame top = transmogTab y -34; Sets/Items buttons = transmogTab y -8;
    -- so offset inside setsFrame = +26 to align vertically.
    setsFrame.buttonSourceSaved = CreateFrame("Button", transmogTabName.."ButtonSourceSaved", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonSourceSaved:SetPoint("TOPLEFT", setsFrame, "TOPLEFT", 6, 26)
    setsFrame.buttonSourceSaved:SetSize(84, 20)
    setsFrame.buttonSourceSaved:SetText(ABL("Saved"))

    setsFrame.buttonSourceCatalog = CreateFrame("Button", transmogTabName.."ButtonSourceCatalog", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonSourceCatalog:SetPoint("LEFT", setsFrame.buttonSourceSaved, "RIGHT", 6, 0)
    setsFrame.buttonSourceCatalog:SetSize(84, 20)
    setsFrame.buttonSourceCatalog:SetText(ABL("Catalog"))

    -- "Reveal Hidden" button: only shown in catalog mode when there are
    -- hidden sets. Anchored to the right of Refresh in the action row
    -- (positioned later, when buttonRefreshCatalog has been created).
    setsFrame.buttonRevealHidden = CreateFrame("Button", transmogTabName.."ButtonRevealHidden", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonRevealHidden:SetSize(106, 22)
    setsFrame.buttonRevealHidden:SetText(ABL("Reveal Hidden"))
    setsFrame.buttonRevealHidden:Hide()
    setsFrame.buttonRevealHidden:SetScript("OnClick", function()
        local hidden = getHiddenCatalogSets()
        for k in pairs(hidden) do hidden[k] = nil end
        fn.rebuildSetLists()
        fn.updateSetButtons()
    end)

    -- Set-name search: free-text filter for both Saved and Catalog rows.
    -- Sits in the row that Reveal Hidden used to occupy.
    setsFrame.searchBox = CreateFrame("EditBox", transmogTabName.."SetsSearchBox", setsFrame, "InputBoxTemplate")
    setsFrame.searchBox:SetPoint("LEFT", setsFrame.buttonSourceCatalog, "RIGHT", 12, 0)
    setsFrame.searchBox:SetSize(120, 20)
    setsFrame.searchBox:SetAutoFocus(false)
    setsFrame.searchBox:SetMaxLetters(64)
    setsFrame.searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    setsFrame.searchBox:SetScript("OnEnterPressed", function(self)
        state._setsSearchText = (self:GetText() or ""):lower()
        self:ClearFocus()
        fn.rebuildSetLists()
    end)

    setsFrame.buttonSearch = CreateFrame("Button", transmogTabName.."ButtonSetsSearch", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonSearch:SetPoint("LEFT", setsFrame.searchBox, "RIGHT", 8, 0)
    setsFrame.buttonSearch:SetSize(64, 20)
    setsFrame.buttonSearch:SetText(ABL("Search"))
    setsFrame.buttonSearch:SetScript("OnClick", function()
        state._setsSearchText = (setsFrame.searchBox:GetText() or ""):lower()
        setsFrame.searchBox:ClearFocus()
        fn.rebuildSetLists()
    end)

    setsFrame.buttonClearSearch = CreateFrame("Button", transmogTabName.."ButtonSetsClearSearch", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonClearSearch:SetPoint("LEFT", setsFrame.buttonSearch, "RIGHT", 4, 0)
    setsFrame.buttonClearSearch:SetSize(54, 20)
    setsFrame.buttonClearSearch:SetText(ABL("Clear"))
    setsFrame.buttonClearSearch:SetScript("OnClick", function()
        setsFrame.searchBox:SetText("")
        state._setsSearchText = ""
        setsFrame.searchBox:ClearFocus()
        fn.rebuildSetLists()
    end)

    -- Background box: full visual width, anchored to buttons above and setsFrame bottom.
    setsFrame.listScrollBg = CreateFrame("Frame", nil, setsFrame)
    setsFrame.listScrollBg:SetPoint("TOPLEFT",    setsFrame.buttonSourceSaved, "BOTTOMLEFT", -6, -6)
    setsFrame.listScrollBg:SetPoint("BOTTOMLEFT", setsFrame, "BOTTOMLEFT", 0, 20)
    setsFrame.listScrollBg:SetWidth(C.SETS_LIST_SCROLL_WIDTH)
    setsFrame.listScrollBg:SetBackdrop(previewBackdrop)
    setsFrame.listScrollBg:SetBackdropColor(0.06, 0.06, 0.06, 1)
    setsFrame.listScrollBg:SetBackdropBorderColor(0.25, 0.25, 0.25)

    -- The scroll frame is INSET from listScrollBg so list items never render on top
    -- of or outside the border.  Left/top/bottom inset = 5px (inside border); right
    -- side is narrower to leave room for the scrollbar which we anchor explicitly.
    setsFrame.listScroll = CreateFrame("ScrollFrame", transmogTabName.."SetsScroll", setsFrame, "UIPanelScrollFrameTemplate")
    setsFrame.listScroll:SetPoint("TOPLEFT",     setsFrame.listScrollBg, "TOPLEFT",     5, -5)
    setsFrame.listScroll:SetPoint("BOTTOMRIGHT", setsFrame.listScrollBg, "BOTTOMRIGHT", -25, 5)

    -- UIPanelScrollFrameTemplate anchors $parentScrollBar ~32px outside the frame's
    -- right edge.  Re-anchor it (and its up/down buttons) inside listScrollBg.
    local _sb = setsFrame.listScroll.ScrollBar
                or _G[transmogTabName.."SetsScrollScrollBar"]
    if _sb then
        local _sbName = _sb:GetName() or ""
        local _sbUp   = _sb.ScrollUpButton   or _G[_sbName.."ScrollUpButton"]
        local _sbDown = _sb.ScrollDownButton or _G[_sbName.."ScrollDownButton"]
        local btnH = (_sbUp and _sbUp:GetHeight()) or 16
        -- Park the up/down buttons flush inside the bg border, then stretch the
        -- slider track between them.
        if _sbUp then
            _sbUp:ClearAllPoints()
            _sbUp:SetPoint("TOPRIGHT", setsFrame.listScrollBg, "TOPRIGHT", -5, -5)
        end
        if _sbDown then
            _sbDown:ClearAllPoints()
            _sbDown:SetPoint("BOTTOMRIGHT", setsFrame.listScrollBg, "BOTTOMRIGHT", -5, 5)
        end
        _sb:ClearAllPoints()
        _sb:SetPoint("TOPRIGHT",    setsFrame.listScrollBg, "TOPRIGHT",    -5, -(5 + btnH))
        _sb:SetPoint("BOTTOMRIGHT", setsFrame.listScrollBg, "BOTTOMRIGHT", -5,  (5 + btnH))
    end

    setsFrame.list = ns.CreateListFrame(transmogTabName.."SetsList", nil, setsFrame.listScroll)
    setsFrame.list:SetPoint("TOPLEFT", 0, 0)
    setsFrame.list:SetWidth(C.SETS_LIST_WIDTH)
    setsFrame.listScroll:SetScrollChild(setsFrame.list)

    setsFrame.noResultsLabel = setsFrame.listScrollBg:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    setsFrame.noResultsLabel:SetPoint("CENTER", setsFrame.listScrollBg, "CENTER", 0, 0)
    setsFrame.noResultsLabel:SetText(ABL("No sets found."))
    setsFrame.noResultsLabel:Hide()
    setsFrame.listScroll:EnableMouseWheel(true)
    setsFrame.listScroll:SetScript("OnMouseWheel", function(self, delta)
        local rowH = 16
        local maxScroll = math_max(0, self:GetScrollChild():GetHeight() - self:GetHeight())
        local newScroll = math_floor((self:GetVerticalScroll() - delta * rowH * 3) / rowH + 0.5) * rowH
        newScroll = math_min(maxScroll, math_max(0, newScroll))
        self:SetVerticalScroll(newScroll)
        -- Pre-warm full item data for rows that are scrolling into view so
        -- clicking them renders the complete outfit instantly.
        if state.setSource == C.SET_SOURCE_CATALOG and ns.QueryItem and state._catalogSetIndex then
            local scrollH   = self:GetHeight() or 200
            local firstIdx  = math_floor(newScroll / rowH) + 1
            local lastIdx   = math_floor((newScroll + scrollH) / rowH) + 2  -- +2 for partial rows
            local lookAhead = lastIdx + 15  -- pre-warm one extra screen below
            local listFrame = setsFrame.list
            for i = firstIdx, math_min(listFrame:GetSize(), lookAhead) do
                local btn = listFrame:GetButton(i)
                if btn and btn.itemSetId then
                    local s = state._catalogSetIndex[btn.itemSetId]
                    if s then
                        local fi = ns.getSetFullItems and ns.getSetFullItems(s)
                        if fi then
                            for j = 1, #fi do
                                local id = tonumber(fi[j])
                                if id and id > 0 then ns.QueryItem(id, nil) end
                            end
                        end
                    end
                end
            end
        end
    end)
    if ns.RefreshManagedScrollFrame then
        ns.RefreshManagedScrollFrame(setsFrame.listScroll)
    end
    setsFrame:HookScript("OnShow", function(self)
        if ns.RefreshManagedScrollFrame then
            ns.RefreshManagedScrollFrame(self.listScroll)
        end
    end)
    setsFrame:HookScript("OnHide", function(self)
        if ns.RefreshManagedScrollFrame then
            ns.RefreshManagedScrollFrame(self.listScroll, false)
        end
    end)

    setsFrame.previewTitle = setsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    setsFrame.previewTitle:SetPoint("TOPLEFT", C.SETS_PREVIEW_LEFT_X, -4)
    setsFrame.previewTitle:SetPoint("TOPRIGHT", -8, -4)
    setsFrame.previewTitle:SetJustifyH("CENTER")
    setsFrame.previewTitle:SetText(ABL("Set Preview"))

    setsFrame.previewModel = ns.CreateDressingRoom(nil, setsFrame)
    setsFrame.previewModel:SetPoint("TOPLEFT", C.SETS_PREVIEW_LEFT_X, -24)
    setsFrame.previewModel:SetPoint("BOTTOMRIGHT", -8, 120)
    setsFrame.previewModel:SetBackdrop(previewBackdrop)
    setsFrame.previewModel:SetBackdropColor(0.08, 0.08, 0.08, 1)
    setsFrame.previewModel:SetBackdropBorderColor(0.25, 0.25, 0.25)
    if ns.RegisterMiniDR then ns.RegisterMiniDR(setsFrame.previewModel) end

    -- Alternative-appearance gold border (mirrors the main dressing room).
    -- Hidden by default; AppearanceBuddy.lua toggles all registered borders.
    do
        local altBorder = setsFrame.previewModel:CreateTexture(nil, "OVERLAY")
        altBorder:SetTexture("Interface\\AddOns\\AppearanceBuddy\\images\\LeftPreviewBorder.tga")
        local PAD_X, PAD_TOP, PAD_BOTTOM = 8, 20, 20
        -- Independent vertical nudges for the two edges.
        --   TOP_Y_OFFSET    : positive = top edge moves UP, negative = DOWN
        --   BOTTOM_Y_OFFSET : positive = bottom edge moves UP, negative = DOWN
        -- Use both equal to shift the whole border; use one to stretch/squash.
        local TOP_Y_OFFSET    = 0
        local BOTTOM_Y_OFFSET = 0
        altBorder:SetPoint("TOPLEFT",     setsFrame.previewModel, "TOPLEFT",     -PAD_X,  PAD_TOP    + TOP_Y_OFFSET)
        altBorder:SetPoint("BOTTOMRIGHT", setsFrame.previewModel, "BOTTOMRIGHT",  PAD_X, -PAD_BOTTOM + BOTTOM_Y_OFFSET)
        altBorder:Hide()
        ns.altBorders = ns.altBorders or {}
        table.insert(ns.altBorders, altBorder)
        setsFrame.previewModelAltBorder = altBorder
    end
    -- Info panel: framed box below the model for set description text.
    setsFrame.infoPanel = CreateFrame("Frame", nil, setsFrame)
    setsFrame.infoPanel:SetPoint("TOPLEFT", setsFrame.previewModel, "BOTTOMLEFT", 0, -4)
    setsFrame.infoPanel:SetPoint("BOTTOMRIGHT", -8, 28)
    setsFrame.infoPanel:SetBackdrop(previewBackdrop)
    setsFrame.infoPanel:SetBackdropColor(0.06, 0.06, 0.06, 1)
    setsFrame.infoPanel:SetBackdropBorderColor(0.25, 0.25, 0.25)
    setsFrame.previewInfo = setsFrame.infoPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    setsFrame.previewInfo:SetPoint("TOPLEFT", 9, -8)
    setsFrame.previewInfo:SetPoint("BOTTOMRIGHT", -9, 8)
    setsFrame.previewInfo:SetJustifyH("LEFT")
    setsFrame.previewInfo:SetJustifyV("TOP")

    setsFrame.previewModel:SetUnit("player")
    setsFrame.previewModel:Reset()
    -- Bidirectional facing sync between the sets preview and the main dressing room.
    -- If the preview's facing differs from what we last wrote (the user dragged it),
    -- push the new value to the main model so both rotate together.
    -- Otherwise follow the main model, so dragging the left model still works.
    local lastSyncedFacing = nil
    setsFrame.previewModel:SetScript("OnUpdate", function(self)
        local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
        if not mainDR then return end

        -- ── Facing sync (bidirectional) ───────────────────────────────────────
        local previewFacing = self:GetFacing()
        if lastSyncedFacing ~= nil and math.abs(previewFacing - lastSyncedFacing) > 0.001 then
            mainDR:SetFacing(previewFacing)
            lastSyncedFacing = previewFacing
        else
            local mainFacing = mainDR:GetFacing()
            self:SetFacing(mainFacing)
            lastSyncedFacing = mainFacing
        end

        -- ── Zoom sync (follow main model position) ────────────────────────────
        -- The main model starts at (0,0,0) when the transmog tab opens; mouse
        -- wheel moves its x axis.  Mirror that offset onto the preview model.
        local mx, my, mz = mainDR:GetPosition()
        local px, py, pz = self:GetPosition()
        mx = mx or 0; my = my or 0; mz = mz or 0
        px = px or 0; py = py or 0; pz = pz or 0
        if math.abs(px - mx) > 0.001 or math.abs(py - my) > 0.001 or math.abs(pz - mz) > 0.001 then
            self:SetPosition(mx, my, mz)
        end
    end)
    updateSetPreviewBackground()

    setsFrame.buttonCopyCurrent = CreateFrame("Button", transmogTabName.."ButtonCopyCurrentSet", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonCopyCurrent:SetPoint("BOTTOMLEFT", transmogTab, "BOTTOMLEFT", 0, C.ACTION_ROW_Y)
    setsFrame.buttonCopyCurrent:SetSize(116, 22)
    setsFrame.buttonCopyCurrent:SetText(ABL("Copy Current..."))

    setsFrame.buttonRemoveSaved = CreateFrame("Button", transmogTabName.."ButtonRemoveSavedSet", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonRemoveSaved:SetPoint("LEFT", setsFrame.buttonCopyCurrent, "RIGHT", 6, 0)
    setsFrame.buttonRemoveSaved:SetSize(78, 22)
    setsFrame.buttonRemoveSaved:SetText(ABL("Remove"))

    setsFrame.buttonEditSaved = CreateFrame("Button", transmogTabName.."ButtonEditSavedSet", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonEditSaved:SetPoint("LEFT", setsFrame.buttonRemoveSaved, "RIGHT", 6, 0)
    setsFrame.buttonEditSaved:SetSize(78, 22)
    setsFrame.buttonEditSaved:SetText(ABL("Edit"))

    -- Share controls live in the empty area below the left preview
    -- (dressing room), parented to mainFrame so they sit outside the
    -- transmog tab's bottom action row.
    -- Layout (left -> right): Copy Set | Link Set | [share editbox]
    local dr = mainFrame and mainFrame.dressingRoom
    local shareAnchor = dr or transmogTab
    transmogTab.buttonShareCopy:ClearAllPoints()
    if dr then
        transmogTab.buttonShareCopy:SetParent(mainFrame)
        transmogTab.buttonShareLink:SetParent(mainFrame)
        transmogTab.shareEditBox:SetParent(mainFrame)
        transmogTab.buttonShareCopy:SetPoint("TOPLEFT", dr, "BOTTOMLEFT", 0, 2)
    else
        transmogTab.buttonShareCopy:SetPoint("BOTTOMLEFT", transmogTab, "BOTTOMLEFT", 0, C.ACTION_ROW_Y + 28)
    end
    transmogTab.buttonShareLink:ClearAllPoints()
    transmogTab.buttonShareLink:SetPoint("LEFT", transmogTab.buttonShareCopy, "RIGHT", 4, 0)
    transmogTab.shareEditBox:ClearAllPoints()
    transmogTab.shareEditBox:SetPoint("LEFT", transmogTab.buttonShareLink, "RIGHT", 12, 0)
    if dr then
        transmogTab.shareEditBox:SetPoint("RIGHT", dr, "BOTTOMRIGHT", -6, 0)
    end

    setsFrame.buttonRefreshCatalog = CreateFrame("Button", transmogTabName.."ButtonRefreshCatalog", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonRefreshCatalog:SetPoint("BOTTOMLEFT", transmogTab, "BOTTOMLEFT", 0, C.ACTION_ROW_Y)
    setsFrame.buttonRefreshCatalog:SetSize(116, 22)
    setsFrame.buttonRefreshCatalog:SetText(ABL("Refresh"))

    -- Anchor Reveal Hidden directly to the right of Refresh in the action row.
    setsFrame.buttonRevealHidden:SetPoint("LEFT", setsFrame.buttonRefreshCatalog, "RIGHT", 6, 0)

    setsFrame.buttonApplySelected = CreateFrame("Button", transmogTabName.."ButtonApplySelectedSet", setsFrame, "UIPanelButtonTemplate2")
    setsFrame.buttonApplySelected:SetPoint("BOTTOMRIGHT", transmogTab, "BOTTOMRIGHT", 0, C.ACTION_ROW_Y)
    setsFrame.buttonApplySelected:SetSize(118, 22)
    setsFrame.buttonApplySelected:SetText(ABL("Apply Set"))

    attachButtonTooltip(setsFrame.buttonSourceSaved,      "Saved Sets",
        "Show outfits you have saved on this character.")
    attachButtonTooltip(setsFrame.buttonSourceCatalog,    "Set Catalog",
        "Show all known appearance sets the server has on file.")
    attachButtonTooltip(setsFrame.buttonCopyCurrent,      "Copy Current",
        "No target: copy your current preview into a new saved set you can name.\nWith a target: copy the target's visible gear into your preview, using only appearances you have unlocked. Nothing is applied until you click Apply.")
    attachButtonTooltip(setsFrame.buttonRemoveSaved,      "Remove",
        "Permanently delete the selected saved set from this character.")
    attachButtonTooltip(setsFrame.buttonEditSaved,        "Edit",
        "Open the selected saved set in Items mode. Click Save Set when done.")
    attachButtonTooltip(setsFrame.buttonRefreshCatalog,   "Refresh Catalog",
        "Re-fetch the catalog of available appearance sets from the server.")
    attachButtonTooltip(setsFrame.buttonRevealHidden,     "Reveal Hidden Sets",
        "Show all sets you have hidden by right-clicking in the Catalog. Clicking this unhides all of them.")
    attachButtonTooltip(setsFrame.buttonApplySelected,    "Apply Set",
        "Equip the selected set as a single transmog operation. Catalog sets unlock the items first.")
end

-- ── All buttons are now created; attach hover tooltips. ─────────────────────
attachButtonTooltip(transmogTab.buttonApply,          "Apply",
    "Send the previewed appearance for the selected slot (or weapon illusion) to the server.")
attachButtonTooltip(transmogTab.buttonHide,           "Hide",
    "Hide the equipped item's appearance for the selected slot. In illusion view, removes the weapon's enchantment glow for free.")
attachButtonTooltip(transmogTab.buttonRestore,        "Restore",
    "Discard the pending preview and revert to the appearance currently saved on the server.")
attachButtonTooltip(transmogTab.buttonRevertAll,      "Revert All",
    "Stage every applied transmog as a restore. Click Apply All to commit and clear all transmogs at once.")
attachButtonTooltip(transmogTab.buttonRevert,         "Revert Preview",
    "Undo every pending change in the preview without touching what is already applied on the server.")
attachButtonTooltip(transmogTab.buttonApplyAll,       "Apply All",
    "Send every pending preview change to the server in a single batch (gold cost is summed).")
attachButtonTooltip(transmogTab.buttonSaveSet,        "Save Set",
    "Save the current preview as the appearance set you are editing.")
attachButtonTooltip(transmogTab.buttonCancelEdit,     "Cancel Edit",
    "Stop editing the saved set and discard pending changes.")
attachButtonTooltip(transmogTab.buttonShareCopy,      "Copy Set",
    "Encode the selected saved set into a share code and place it in the text box (select all and Ctrl+C to copy).")
attachButtonTooltip(transmogTab.buttonShareLink,      "Link Set",
    "Insert a clickable [Set Name] hyperlink into the active chat edit box. Other AppearanceBuddy users can left-click it to import + preview the set, or right-click it to copy the raw share code into a popup for pasting into the import bar.")
attachButtonTooltip(transmogTab.shareEditBox,         "Share Code",
    "Paste a share code here and press Enter to import it as a new saved set.")
attachButtonTooltip(transmogTab.buttonModeItems,      "Items",
    "Browse and apply individual transmog appearances per slot.")
attachButtonTooltip(transmogTab.buttonModeSets,       "Sets",
    "Browse, save, and apply complete outfits made from your unlocked appearances.")
attachButtonTooltip(transmogTab.buttonSearch,         "Search",
    "Search every unlocked appearance for the slot by name.")
attachButtonTooltip(transmogTab.buttonClearSearch,    "Clear Search",
    "Clear the search box and return to the normal slot listing.")
attachButtonTooltip(transmogTab.setsFrame.buttonSearch, "Search Sets",
    "Filter saved sets and catalog sets by name.")
attachButtonTooltip(transmogTab.setsFrame.buttonClearSearch, "Clear Set Search",
    "Clear the set search box and show all saved or catalog sets.")
attachButtonTooltip(transmogTab.buttonPrev,           "Previous Page",
    "Show the previous page of appearances or illusions.")
attachButtonTooltip(transmogTab.buttonNext,           "Next Page",
    "Show the next page of appearances or illusions.")
attachButtonTooltip(transmogTab.filterButton,         "Subclass Filter",
    "Restrict the listing to a specific armor or weapon subclass.")
attachButtonTooltip(transmogTab.rarityFilterButton,   "Rarity Filter",
    "Choose which item rarities are shown in the listing.")

local itemModeWidgets = {
    transmogTab.searchBox,
    transmogTab.searchPlaceholder,
    transmogTab.buttonSearch,
    transmogTab.buttonClearSearch,
    transmogTab.pageText,
    transmogTab.buttonPrev,
    transmogTab.buttonNext,
    transmogTab.list,
    transmogTab.messageText,
    transmogTab.statusText,
    transmogTab.buttonApply,
    transmogTab.buttonHide,
    transmogTab.buttonRestore,
    transmogTab.buttonRevert,
    transmogTab.buttonRevertAll,
    transmogTab.buttonApplyAll,
    transmogTab.filterButton,
    transmogTab.rarityFilterButton,
}

for _, info in ipairs(SLOT_DATA) do
    table.insert(itemModeWidgets, state.slotButtons[info.name])
end

local function updateModeButtons()
    transmogTab.buttonModeItems:UnlockHighlight()
    transmogTab.buttonModeSets:UnlockHighlight()
    if transmogTab.buttonMHIllusion then transmogTab.buttonMHIllusion:UnlockHighlight() end
    if transmogTab.buttonOHIllusion then transmogTab.buttonOHIllusion:UnlockHighlight() end
    -- Hide illusion weapon buttons while in the Sets view.
    local inSets = state.viewMode == "sets"
    if transmogTab.buttonMHIllusion then
        if inSets then transmogTab.buttonMHIllusion:Hide() else transmogTab.buttonMHIllusion:Show() end
    end
    if transmogTab.buttonOHIllusion then
        if inSets then transmogTab.buttonOHIllusion:Hide() else transmogTab.buttonOHIllusion:Show() end
    end
    if state.viewMode == "items" then
        transmogTab.buttonModeItems:LockHighlight()
    elseif state.viewMode == "sets" then
        transmogTab.buttonModeSets:LockHighlight()
    elseif state.viewMode == "illusion" then
        transmogTab.buttonModeItems:LockHighlight()
        local f = transmogTab.illusionFrame
        if f and f.activeSlotId then
            if f.activeSlotId == SLOT_ID_BY_NAME["Main Hand"] and transmogTab.buttonMHIllusion then
                transmogTab.buttonMHIllusion:LockHighlight()
            elseif f.activeSlotId == SLOT_ID_BY_NAME["Off-hand"] and transmogTab.buttonOHIllusion then
                transmogTab.buttonOHIllusion:LockHighlight()
            end
        end
    end
end

local function setItemModeVisible(visible)
    for _, widget in ipairs(itemModeWidgets) do
        if widget and widget ~= transmogTab.list and widget ~= transmogTab.messageText then
            if visible then
                -- Never blindly Show() the placeholder; its visibility is
                -- governed by whether the search box is empty.
                if widget == transmogTab.searchPlaceholder then
                    if transmogTab.searchBox:GetText() == "" then
                        widget:Show()
                    end
                else
                    widget:Show()
                end
            else
                widget:Hide()
            end
        end
    end
    if visible then
        local showMsg = transmogTab.messageText:GetText() ~= "" and (#transmogTab.list.itemIds == 0 or not transmogTab.list.dressingRoomSetup)
        if showMsg then transmogTab.messageText:Show() transmogTab.list:Hide()
        else transmogTab.messageText:Hide() transmogTab.list:Show() end
    else
        closeFilterPopup()
        closeRarityFilterPopup()
        transmogTab.messageText:Hide()
        transmogTab.list:Hide()
    end
end


local function getSelectedSavedSet()
    local selectedName = state.selectedSavedSetName
    if not selectedName then
        return nil
    end

    -- Build a name→setData index on first use; invalidated when sets change.
    local sets = getSavedTransmogSets()
    if not state._savedSetIndex or state._savedSetIndexLen ~= #sets then
        state._savedSetIndex = {}
        state._savedSetIndexLen = #sets
        for _, setData in ipairs(sets) do
            state._savedSetIndex[setData.name] = setData
        end
    end
    return state._savedSetIndex[selectedName] or nil
end

local function invalidateSavedSetIndex()
    state._savedSetIndex = nil
    state._savedSetIndexLen = nil
end

-- Import a share string and save it as a saved set.  Defined here (after
-- invalidateSavedSetIndex and fn are both in scope) and assigned to fn so the
-- editbox OnEnterPressed handler (created earlier) can reach it via fn.
fn.importShareString = function(str)
    local setData, err = decodeShareStringToSet(str)
    if not setData then
        SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Import failed: " .. (err or "unknown"))
        return false
    end
    local savedSets = getSavedTransmogSets()
    local existing = nil
    for idx, s in ipairs(savedSets) do
        if s.name == setData.name then existing = idx; break end
    end
    local function doImport()
        if existing then
            savedSets[existing].items    = setData.items
            savedSets[existing].enchants = setData.enchants
        else
            table.insert(savedSets, setData)
        end
        invalidateSavedSetIndex()
        state.setSource = C.SET_SOURCE_SAVED
        state.selectedSavedSetName = setData.name
        fn.rebuildSetLists()
        fn.updateSetButtons()
        fn.updateSetPreview()
        SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Set \""
            .. setData.name .. "\" " .. (existing and "updated" or "imported") .. ".")
    end
    if existing then
        StaticPopupDialogs["AB_IMPORT_OVERWRITE"] = {
            text = "A set named \"|cffffd200" .. setData.name .. "|r\" already exists. Overwrite it?",
            button1 = "Overwrite", button2 = "Cancel",
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
            OnAccept = doImport,
        }
        StaticPopup_Show("AB_IMPORT_OVERWRITE")
    else
        doImport()
    end
    return true
end

local function getSelectedCatalogSet()
    local selectedId = tonumber(state.selectedCatalogSetId)
    if not selectedId then
        return nil
    end

    -- Build an id→setData index on first use; invalidated when catalog changes.
    local catalog = state.itemSetCatalog
    if not state._catalogSetIndex or state._catalogSetIndexLen ~= #catalog then
        state._catalogSetIndex = {}
        state._catalogSetIndexLen = #catalog
        for _, setData in ipairs(catalog) do
            local id = tonumber(setData.id)
            if id then
                state._catalogSetIndex[id] = setData
            end
        end
    end
    return state._catalogSetIndex[selectedId] or nil
end

local function invalidateCatalogSetIndex()
    state._catalogSetIndex = nil
    state._catalogSetIndexLen = nil
end

local function isCatalogSetComplete(setData)
    if type(setData) ~= "table" then
        return false
    end

    if setData.hasExactTotal == false then
        return false
    end

    local unlockedCount = tonumber(setData.unlockedCount) or 0
    local totalCount = tonumber(setData.totalCount) or 0
    return totalCount > 0 and unlockedCount >= totalCount
end

function ns.getCatalogSetDisplayName(setData)
    if setData._displayNameCache then return setData._displayNameCache end
    local name = tostring(setData.name or "Set")
    local s
    if setData.hasExactTotal then
        s = string_format("%s (%d/%d)", name, setData.unlockedCount or 0, setData.totalCount or 0)
    else
        s = string_format(ABL("%s (%d pieces)"), name, setData.unlockedCount or 0)
    end
    setData._displayNameCache = s
    return s
end

local function getCatalogSetRowLabel(setData)
    if type(setData) ~= "table" then
        return "Set"
    end
    if setData._rowLabelCache then return setData._rowLabelCache end

    local baseLabel = ns.getCatalogSetDisplayName(setData)
    local s = isCatalogSetComplete(setData) and ("|cff40ff40"..baseLabel.."|r") or baseLabel
    setData._rowLabelCache = s
    return s
end

function ns.DedupeCatalogRowsByVisibleLabel(rows)
    if type(rows) ~= "table" or #rows < 2 then
        return rows
    end

    local filtered = {}
    local seen = {}
    for _, setData in ipairs(rows) do
        local key = tostring(ns.getCatalogSetDisplayName(setData) or ""):lower()
        if key == "" then
            key = "id:" .. tostring(setData and setData.id or "")
        end
        if not seen[key] then
            seen[key] = true
            filtered[#filtered + 1] = setData
        end
    end
    return filtered
end

local function getCatalogSetMissingSlots(setData)
    if type(setData) ~= "table" then
        return {}
    end

    local missing = {}
    local fi = ns.getSetFullItems(setData)
    local ui = ns.getSetUnlockedItems(setData)
    for index, slotInfo in ipairs(SLOT_DATA) do
        local fullItemId = fi and tonumber(fi[index]) or 0
        local unlockedItemId = ui and tonumber(ui[index]) or 0

        if fullItemId > 0 and unlockedItemId <= 0 then
            missing[#missing + 1] = C.CATALOG_SLOT_LABELS[slotInfo.name] or slotInfo.name
        end
    end

    return missing
end
-- Exposed on ns so the tooltip closure inside ensureSetListButtonTooltip
-- (defined before this function) can call it via a late-bound table ref.
ns.getCatalogSetMissingSlots = getCatalogSetMissingSlots

local function renderSetPreviewModelItems(model, itemIds, token)
    if token and model.setPreviewToken ~= token then return end
    updateSetPreviewBackground()
    model:Reset()
    if token and model.setPreviewToken ~= token then return end
    model:Undress()

    local retryItems = {}
    for index = 1, #SLOT_DATA do
        if token and model.setPreviewToken ~= token then return end
        local itemId = type(itemIds) == "table" and tonumber(itemIds[index]) or nil
        if itemId and itemId > 0 then
            local info = SLOT_DATA[index]
            if C.WEAPON_SLOT[info.name] then
                -- Always build an explicit link (enchant=0 when none) so the
                -- DressUpModel never inherits an enchant visual from a prior slot.
                local link = ns.BuildWeaponPreviewLink(itemId, state.illusionEnchants[info.name])
                if link then model:TryOn(link) end
            else
                model:TryOn(itemId)
            end
            retryItems[info.name] = itemId
        end
    end

    for _, slotName in ipairs(C.SET_PREVIEW_RETRY_SLOT_ORDER) do
        if token and model.setPreviewToken ~= token then return end
        local itemId = retryItems[slotName]
        if itemId and itemId > 0 then
            if C.WEAPON_SLOT[slotName] then
                local link = ns.BuildWeaponPreviewLink(itemId, state.illusionEnchants[slotName])
                if link then model:TryOn(link) end
            else
                model:TryOn(itemId)
            end
        end
    end

    if model.shadowformEnabled then
        model:EnableShadowform()
    end
end

local function setPreviewModelItems(model, itemIds)
    model.setPreviewToken = (model.setPreviewToken or 0) + 1
    local token = model.setPreviewToken
    local normalizedItems = {}

    for index = 1, #SLOT_DATA do
        local itemId = type(itemIds) == "table" and tonumber(itemIds[index]) or 0
        normalizedItems[index] = itemId and itemId > 0 and itemId or 0
    end

    model:Reset()
    model:Undress()

    -- Returns a render-ready list: real id where GetItemInfo is cached, 0 otherwise.
    local function buildReadyItems()
        local ready = {}
        for i = 1, #SLOT_DATA do
            local id = normalizedItems[i]
            ready[i] = (id > 0 and select(2, GetItemInfo(id))) and id or 0
        end
        return ready
    end

    -- Kick queries for every uncached item.  When the last one resolves (or
    -- times out) do one final full render.  Token guards against stale
    -- callbacks from a previously-selected set.
    local pending = 0
    local function onItemResolved()
        if model.setPreviewToken ~= token then return end
        pending = pending - 1
        if pending <= 0 then
            renderSetPreviewModelItems(model, buildReadyItems(), token)
        end
    end

    for i = 1, #SLOT_DATA do
        local id = normalizedItems[i]
        if id > 0 and not select(2, GetItemInfo(id)) then
            pending = pending + 1
            ns.QueryItem(id, onItemResolved)
        end
    end

    -- Only render immediately when every item is already in the Lua cache.
    -- If anything is pending, the model stays undressed (Reset/Undress ran above)
    -- and onItemResolved fires a single complete render once all items resolve.
    -- This prevents the "helmet only, then rest trickles in" artifact caused by
    -- rendering a partial set from whatever happened to be cache-hot.
    if pending == 0 then
        renderSetPreviewModelItems(model, buildReadyItems(), token)
    end
end

-- Fire-and-forget pre-warm: kicks WoW's item-info request for every itemId so
-- the client cache is populated before the user actually previews the set.
-- No handler installed, no per-item allocation.
local function prewarmSetItemIds(itemIds)
    if type(itemIds) ~= "table" or not ns.QueryItem then return end
    for i = 1, #itemIds do
        local id = tonumber(itemIds[i])
        if id and id > 0 then
            ns.QueryItem(id, nil)
        end
    end
end

local function prewarmSetData(setData)
    if type(setData) ~= "table" then return end
    if setData.items then
        prewarmSetItemIds(setData.items)
    end
    if ns.getSetFullItems and (setData._fir or setData._fic) then
        prewarmSetItemIds(ns.getSetFullItems(setData))
    end
end
ns.PrewarmSetData = prewarmSetData

fn.updateSetButtons = function()
    local setsFrame = transmogTab.setsFrame
    local hasSelection = false
    local applyLocked = state.applyingAppearanceSet or state.applyingUnlockedItemSet or state.itemSetCatalogRequestPending

    if state.setSource == C.SET_SOURCE_SAVED then
        hasSelection = getSelectedSavedSet() ~= nil
        setsFrame.buttonSourceSaved:LockHighlight()
        setsFrame.buttonSourceCatalog:UnlockHighlight()
        setsFrame.buttonCopyCurrent:Show()
        setsFrame.buttonRefreshCatalog:Hide()
        setsFrame.buttonRevealHidden:Hide()
        setsFrame.buttonRemoveSaved:Show()
        setsFrame.buttonEditSaved:Show()
        setsFrame.buttonApplySelected:SetText(ABL("Apply Set"))
        setEnabled(setsFrame.buttonRemoveSaved, hasSelection)
        setEnabled(setsFrame.buttonEditSaved, hasSelection and state.synced)
        setEnabled(setsFrame.buttonCopyCurrent, state.synced)
        -- Share controls: visible in saved mode; Copy/Link enabled when a set is selected.
        -- Only show while the transmog tab is actually visible — they were
        -- reparented to mainFrame so they would otherwise leak onto the
        -- Settings tab when rebuildSetLists runs from a settings checkbox.
        if transmogTab:IsShown() then
            ns.ShowSetShareControls()
        end
        setEnabled(transmogTab.buttonShareCopy, hasSelection or hasCopyableTarget())
        setEnabled(transmogTab.buttonShareLink, hasSelection)
    else
        hasSelection = getSelectedCatalogSet() ~= nil
        setsFrame.buttonSourceSaved:UnlockHighlight()
        setsFrame.buttonSourceCatalog:LockHighlight()
        setsFrame.buttonCopyCurrent:Hide()
        setsFrame.buttonRemoveSaved:Hide()
        setsFrame.buttonEditSaved:Hide()
        setsFrame.buttonRefreshCatalog:Show()
        setEnabled(setsFrame.buttonRefreshCatalog, state.enabled and not state.itemSetCatalogRequestPending)
        setsFrame.buttonApplySelected:SetText(ABL("Apply Unlocked"))
        -- Share controls: hidden in catalog mode (sets can't be shared from catalog).
        ns.HideSetShareControls(false)
        -- Show "Reveal Hidden" only when at least one set is hidden.
        local hasHidden = next(getHiddenCatalogSets()) ~= nil
        if hasHidden then
            setsFrame.buttonRevealHidden:Show()
        else
            setsFrame.buttonRevealHidden:Hide()
        end
    end

    setEnabled(setsFrame.buttonApplySelected, state.enabled and hasSelection and not applyLocked)
end

fn.updateSetPreview = function()
    local setsFrame = transmogTab.setsFrame
    updateSetPreviewBackground()

    if state.setSource == C.SET_SOURCE_SAVED then
        local savedSet = getSelectedSavedSet()
        if not savedSet then
            setsFrame.previewTitle:SetText(ABL("Set Preview"))
            setsFrame.previewInfo:SetText(ABL("Select a saved transmog set or copy the current preview into a new named set."))
            setsFrame.previewModel.setPreviewToken = (setsFrame.previewModel.setPreviewToken or 0) + 1
            setsFrame.previewModel:Undress()
            updateCostText()
            return
        end

        local itemCount = 0
        local hiddenCount = 0
        local restoreCount = 0
        for index = 1, #SLOT_DATA do
            local value = tonumber(savedSet.items and savedSet.items[index]) or -1
            if value > 0 then
                itemCount = itemCount + 1
            elseif value == 0 then
                hiddenCount = hiddenCount + 1
            else
                restoreCount = restoreCount + 1
            end
        end

        setPreviewModelItems(setsFrame.previewModel, buildPreviewItemsFromTransmogSet(savedSet.items))
        setsFrame.previewTitle:SetText(savedSet.name)
        setsFrame.previewInfo:SetText((ABL("Saved transmog set\nCustom appearances: %d  |  Hidden: %d  |  Restore: %d")):format(itemCount, hiddenCount, restoreCount))
        updateCostText()
    else
        local catalogSet = getSelectedCatalogSet()
        if not catalogSet then
            setsFrame.previewTitle:SetText(ABL("Set Preview"))
            if state.itemSetCatalogRequestPending then
                setsFrame.previewInfo:SetText(ABL("Fetching unlocked item sets..."))
            elseif state.itemSetCatalogRetryAt > 0 then
                -- The catalogTimeoutFrame OnUpdate owns the countdown text; return
                -- without overwriting it so the live countdown stays visible.
                setsFrame.previewModel.setPreviewToken = (setsFrame.previewModel.setPreviewToken or 0) + 1
                setsFrame.previewModel:Undress()
                updateCostText()
                return
            elseif not state.itemSetCatalogLoaded or #state.itemSetCatalog == 0 then
                setsFrame.previewInfo:SetText(ABL("Automatic catalog scanning is disabled.\nClick Refresh to load unlocked item sets."))
            else
                local loadedCount = setsFrame.list:GetSize()
                local countText = loadedCount > 0
                    and (ABL("Loaded %d sets.\n\n")):format(loadedCount)
                    or  ""
                setsFrame.previewInfo:SetText(countText .. ABL("Select an unlocked item set to preview the full look. Applying it will use only the pieces your account has unlocked."))
            end
            setsFrame.previewModel.setPreviewToken = (setsFrame.previewModel.setPreviewToken or 0) + 1
            setsFrame.previewModel:Undress()
            updateCostText()
            return
        end

        setPreviewModelItems(setsFrame.previewModel, ns.getSetFullItems(catalogSet))
        setsFrame.previewTitle:SetText(catalogSet.name or ABL("Unlocked Item Set"))
        local infoLines = {
            (ABL("Unlocked pieces: %d/%d")):format(tonumber(catalogSet.unlockedCount) or 0, tonumber(catalogSet.totalCount) or 0)
        }
        local missingSlots = getCatalogSetMissingSlots(catalogSet)
        if #missingSlots > 0 then
            infoLines[#infoLines + 1] = "Missing: "..table.concat(missingSlots, ", ")
        end
        infoLines[#infoLines + 1] = "Preview hides non-set slots. Apply uses only unlocked appearances."
        setsFrame.previewInfo:SetText(table.concat(infoLines, "\n"))
    end
    updateCostText()
end

-- Debounce rapid set-list selection: wait C.SET_PREVIEW_DELAY seconds after the
-- last click before rendering.  Without this, fast clicking between sets can
-- leave in-flight TryOn() calls from the previous set painting stray items
-- onto the newly-reset model, mixing appearances across sets.
local _setPreviewElapsed = 0
local setPreviewDebounceFrame = CreateFrame("Frame")
setPreviewDebounceFrame:Hide()
setPreviewDebounceFrame:SetScript("OnUpdate", function(self, elapsed)
    _setPreviewElapsed = _setPreviewElapsed + elapsed
    if _setPreviewElapsed >= C.SET_PREVIEW_DELAY then
        self:Hide()
        _setPreviewElapsed = 0
        fn.updateSetPreview()
    end
end)

local function scheduleSetPreview()
    _setPreviewElapsed = 0
    setPreviewDebounceFrame:Show()
end

-- ---- Incremental set-list builder ----
-- Row insertion is spread across frames via a coroutine that yields every
-- C.REBUILD_BATCH_SIZE rows, keeping the UI responsive on large catalogs.
-- A per-request token lets the coroutine abort early when superseded.

-- ---- Class/armor filter for blizzlike saved-set filtering ----
-- All helpers are wrapped in do..end so they consume block-local slots
-- rather than main-chunk locals (Lua 5.1 hard limit: 200 per chunk).
do
    local ARMOR_SUBTYPE_ORDER = ns.ARMOR_SUBTYPE_ORDER

    -- WoW class bitmasks: 2^(classId-1), matching item_template.AllowableClass.
    -- classId comes from select(3, UnitClass("player")).
    local CLASS_ID_TO_MASK = {
        [1]=1, [2]=2, [3]=4, [4]=8, [5]=16, [6]=32,
        [7]=64, [8]=128, [9]=256, [11]=1024
    }
    local playerClassId   = select(3, UnitClass("player"))
    local playerClassMask = CLASS_ID_TO_MASK[playerClassId] or 0

    -- Returns false if `allowableClass` explicitly excludes the player's class.
    -- allowableClass = -1 (or 0) means "all classes" — always passes.
    local function classAllowed(allowableClass)
        if not allowableClass or allowableClass == -1 or allowableClass == 0 then
            return true
        end
        -- WoW stores AllowableClass as a signed int; bit.band handles negatives correctly.
        return bit.band(allowableClass, playerClassMask) ~= 0
    end
    ns.ClassAllowedForCurrentPlayer = classAllowed

    -- Returns a filtered copy of `sets` excluding sets whose armor items all exceed
    -- the player's armor proficiency.  Also excludes catalog sets flagged with a
    -- class restriction that excludes the current player via the server-supplied
    -- allowableClass bitmask.
    -- Only called when blizzlike restrictions are active (state.blizzlikeEnabled).
    fn.filterSavedSetsByPlayerClass = function(sets)
        local maxArmorName = DEFAULT_ARMOR_SUBCLASS[playerClassFileName]
        local maxOrder = ARMOR_SUBTYPE_ORDER[maxArmorName] or 4

        local filtered = {}
        for _, setData in ipairs(sets) do
            local items = setData.items
            local hasArmor = false
            local hasUsable = false
            if items then
                for idx = 1, #SLOT_DATA do
                    local itemId = tonumber(items[idx])
                    if itemId and itemId > 0 then
                        local _, _, _, _, _, _, subType = GetItemInfo(itemId)
                        local order = ARMOR_SUBTYPE_ORDER[subType]
                        if order then
                            hasArmor = true
                            if order <= maxOrder then
                                hasUsable = true
                            end
                        end
                    end
                end
            end
            local armorOk = maxOrder >= 4 or not hasArmor or hasUsable
            if armorOk then
                filtered[#filtered + 1] = setData
            end
        end
        return filtered
    end

    -- Catalog sets carry an `allowableClass` bitmask AND an `armorSubclass`
    -- (1=Cloth..4=Plate, 0=no armor) from the server, both sourced directly
    -- from item_template.  No client-side GetItemInfo needed (which is async
    -- and returns nil for uncached items, letting unwanted sets slip through).
    -- Server already filters by class + armor proficiency when blizzlike is on.
    -- This is a defensive second pass in case a stale catalog slips through.
    fn.filterCatalogSetsByPlayerClass = function(sets)
        local maxArmorName = DEFAULT_ARMOR_SUBCLASS[playerClassFileName]
        local maxOrder = ARMOR_SUBTYPE_ORDER[maxArmorName] or 4

        local filtered = {}
        for _, setData in ipairs(sets) do
            if classAllowed(setData.allowableClass) then
                local sub = tonumber(setData.armorSubclass) or 0
                if sub == 0 or sub <= maxOrder then
                    filtered[#filtered + 1] = setData
                end
            end
        end
        return filtered
    end
end

local rebuildSetListsToken = 0
local rebuildTickFrame = CreateFrame("Frame")
rebuildTickFrame:Hide()

fn.rebuildSetLists = function()
    local setsFrame = transmogTab.setsFrame
    local listFrame = setsFrame.list

    local reselectValue = state.setSource == C.SET_SOURCE_SAVED
        and state.selectedSavedSetName
        or  state.selectedCatalogSetId

    -- Capture scroll position BEFORE Clear() — Clear() shrinks the child frame
    -- to zero height, which causes WoW to clamp the scroll to 0 immediately,
    -- so reading it later (inside the coroutine) always returns 0.
    local savedScroll = setsFrame.listScroll:GetVerticalScroll() or 0

    -- Invalidate any in-progress rebuild by advancing the token.
    rebuildSetListsToken = rebuildSetListsToken + 1
    local myToken = rebuildSetListsToken

    listFrame:Clear()
    if setsFrame.noResultsLabel then setsFrame.noResultsLabel:Hide() end
    if state.setSource == C.SET_SOURCE_SAVED then
        state.selectedSavedSetName = nil
    else
        state.selectedCatalogSetId = nil
    end

    local rows
    if state.setSource == C.SET_SOURCE_SAVED then
        sortSavedTransmogSets()
        rows = getSavedTransmogSets()
        if state.blizzlikeEnabled then
            rows = fn.filterSavedSetsByPlayerClass(rows)
        end
    else
        -- Single-pass catalog filter.  Previously each filter (class, custom,
        -- min-pieces, junk, hidden) allocated its own filtered array and
        -- iterated rows separately — N table allocations and N*rows iterations
        -- on a multi-thousand-set catalog.  Combine all checks into one pass
        -- with at most one allocation.
        local source = state.itemSetCatalog or {}
        local hideCustom = (GetSettings and GetSettings().hideCustomSets) and true or false
        local hideJunk   = (GetSettings and GetSettings().hideJunkSets ~= false) and true or false
        local hidden     = getHiddenCatalogSets()
        local hasHidden  = next(hidden) ~= nil
        local blizz      = state.blizzlikeEnabled and true or false

        local maxArmorOrder = 4
        if blizz then
            local maxArmorName = DEFAULT_ARMOR_SUBCLASS[playerClassFileName]
            maxArmorOrder = (ns.ARMOR_SUBTYPE_ORDER and ns.ARMOR_SUBTYPE_ORDER[maxArmorName]) or 4
        end

        local function isJunkSetName(name)
            if not name then return false end
            -- Wrap with spaces so word-boundary checks are simple.
            local low = " " .. name:lower() .. " "
            if low:find("art template", 1, true) then return true end
            if low:find("[^%a]test[^%a]")          then return true end
            if low:find("[^%a]qa[^%a]")            then return true end
            if low:find("deprecated", 1, true)     then return true end
            return false
        end

        rows = {}
        for i = 1, #source do
            local setData = source[i]
            local id      = tonumber(setData.id) or 0
            local total   = tonumber(setData.totalCount) or 0
            local armorSub   = tonumber(setData.armorSubclass) or 0
            local weaponMask = tonumber(setData.weaponMask) or 0

            -- Custom (virtual / negative-id) sets.
            local keep = (not hideCustom) or (id > 0)

            -- Min-pieces floor: 2 for weapon-only sets, 4 for armor sets.
            if keep then
                local isWeaponSet = (armorSub == 0) and (weaponMask ~= 0)
                if not (total >= 2 and (isWeaponSet or total >= 4)) then
                    keep = false
                end
            end

            -- Junk / dev-template name keywords.
            if keep and hideJunk and isJunkSetName(setData.name) then
                keep = false
            end

            -- User-hidden via right-click.
            if keep and hasHidden and hidden[tostring(id)] then
                keep = false
            end

            -- Blizzlike class restriction.
            if keep and blizz then
                if ns.ClassAllowedForCurrentPlayer and not ns.ClassAllowedForCurrentPlayer(setData.allowableClass) then
                    keep = false
                elseif armorSub ~= 0 and armorSub > maxArmorOrder then
                    keep = false
                end
            end

            if keep then
                rows[#rows + 1] = setData
            end
        end
        rows = ns.DedupeCatalogRowsByVisibleLabel(rows)
    end

    -- Set-name search filter (applies to both Saved and Catalog).
    if state._setsSearchText and state._setsSearchText ~= "" then
        local needle = state._setsSearchText
        local filtered = {}
        for _, setData in ipairs(rows) do
            local name = tostring(setData.name or ""):lower()
            if name:find(needle, 1, true) then
                filtered[#filtered + 1] = setData
            end
        end
        rows = filtered
    end

    if #rows == 0 and state._setsSearchText and state._setsSearchText ~= "" then
        if setsFrame.noResultsLabel then
            setsFrame.noResultsLabel:SetText((ABL("No sets found matching \"%s\".")):format(state._setsSearchText))
            setsFrame.noResultsLabel:Show()
        end
        return
    end

    if setsFrame.noResultsLabel then setsFrame.noResultsLabel:Hide() end

    local isSaved = (state.setSource == C.SET_SOURCE_SAVED)

    -- Bulk pre-warm: kick item-info requests for the FIRST icon candidate of
    -- the first visible-ish chunk in one tight loop BEFORE the coroutine runs.  By the
    -- time the coroutine reaches each row, GetItemInfo is far more likely to
    -- be cache-hot, eliminating per-row async backoff for icon resolution.
    -- Capped because pre-warming thousands of items at once stalls the frame
    -- on huge catalogs without measurable benefit (the user only sees the
    -- first screenful immediately; subsequent rows warm as the coroutine
    -- iterates anyway).
    -- In addition, pre-warm ALL items for the first screenful of catalog rows
    -- (not just the icon candidate).  This means clicking any of the first
    -- ~40 visible sets is far more likely to be fully cache-hot, enabling an
    -- instant complete render with no partial-outfit artifact.
    if not isSaved and ns.QueryItem then
        local prewarmLimit = math_min(#rows, C.SET_LIST_ICON_ASYNC_LIMIT or 80)
        for i = 1, prewarmLimit do
            local cands = getSetListIconItemId(rows[i])
            if cands and cands[1] then
                ns.QueryItem(cands[1], nil)
            end
        end
        -- Full-item pre-warm for the first two visible pages.
        local fullPrewarmLimit = math_min(#rows, 40)
        for i = 1, fullPrewarmLimit do
            local setData = rows[i]
            if setData then
                local fi = ns.getSetFullItems and ns.getSetFullItems(setData)
                if fi then
                    for j = 1, #fi do
                        local id = tonumber(fi[j])
                        if id and id > 0 then ns.QueryItem(id, nil) end
                    end
                end
            end
        end
    end

    local co = coroutine.create(function()
        local iconBatch, iconBatchLen = {}, 0
        local function flushIcons()
            for j = 1, iconBatchLen, 3 do
                if rebuildSetListsToken == myToken then setSetListButtonIcon(iconBatch[j], iconBatch[j+1], iconBatch[j+2]) end
            end
            wipe(iconBatch)
            iconBatchLen = 0
        end

        for i = 1, #rows do
            if rebuildSetListsToken ~= myToken then return end

            local setData = rows[i]
            local label = isSaved
                and setData.name
                or  getCatalogSetRowLabel(setData)

            local buttonId = listFrame:AddItem(label)
            local button   = listFrame:GetButton(buttonId)

            if isSaved then
                button.setName       = setData.name
                button.fullLabelText = setData.name
                button.itemSetId     = nil  -- clear catalog field if reused
            else
                button.itemSetId     = tonumber(setData.id)
                button.fullLabelText = ns.getCatalogSetDisplayName(setData)
                button.setName       = nil  -- clear saved field if reused
            end
            ensureSetListButtonTooltip(button)

            iconBatch[iconBatchLen + 1] = button
            iconBatch[iconBatchLen + 2] = getSetListIconItemId(setData)
            iconBatch[iconBatchLen + 3] = true  -- always allow async; token guards stale callbacks
            iconBatchLen = iconBatchLen + 3

            if iconBatchLen >= C.ICON_QUERY_BATCH * 3 then flushIcons() end
        end

        for j = 1, iconBatchLen, 3 do
            if rebuildSetListsToken == myToken then setSetListButtonIcon(iconBatch[j], iconBatch[j+1], iconBatch[j+2]) end
        end

        if rebuildSetListsToken ~= myToken then return end

        setsFrame.listScroll:UpdateScrollChildRect()
        do
            local maxScroll = math_max(0, (listFrame:GetHeight() or 0) - (setsFrame.listScroll:GetHeight() or 0))
            local currentScroll = reselectValue ~= nil
                and math_min(math_max(savedScroll, 0), maxScroll)
                or  0
            setsFrame.listScroll:SetVerticalScroll(currentScroll)
            -- Sync the scrollbar thumb explicitly.  UpdateScrollChildRect fires
            -- OnScrollRangeChanged which calls SetMinMaxValues but only clamps
            -- SetValue when value > newMax.  When the list grows or is rebuilt
            -- the thumb stays stale.  Force-sync here so thumb always matches.
            local scrollBar = setsFrame.listScroll.ScrollBar
                or _G[(setsFrame.listScroll:GetName() or "") .. "ScrollBar"]
            if scrollBar then
                scrollBar:SetMinMaxValues(0, maxScroll)
                scrollBar:SetValue(currentScroll)
            end
        end
        if ns.RefreshManagedScrollFrame then
            ns.RefreshManagedScrollFrame(setsFrame.listScroll)
        end

        if reselectValue ~= nil then
            for index = 1, listFrame:GetSize() do
                local button = listFrame:GetButton(index)
                if isSaved then
                    if button and button.setName == reselectValue then
                        listFrame:Select(index)
                        break
                    end
                elseif button and tonumber(button.itemSetId) == tonumber(reselectValue) then
                    listFrame:Select(index)
                    break
                end
            end
        end

        fn.updateSetButtons()
        fn.updateSetPreview()
    end)

    rebuildTickFrame:SetScript("OnUpdate", function(self)
        if rebuildSetListsToken ~= myToken then
            self:Hide()
            self:SetScript("OnUpdate", nil)
            return
        end

        local ok, err = coroutine.resume(co)
        if not ok then
            geterrorhandler()(err)
            self:Hide()
            self:SetScript("OnUpdate", nil)
        elseif coroutine.status(co) == "dead" then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
    rebuildTickFrame:Show()
end

transmogTab.setsFrame.list.onSelect = function(self, id)
    local button = self:GetButton(id)
    if state.setSource == C.SET_SOURCE_SAVED then
        state.selectedSavedSetName = button and button.setName or nil
    else
        state.selectedCatalogSetId = button and tonumber(button.itemSetId) or nil
    end

    -- Pre-warm item info for the just-selected set immediately, so by the time
    -- the debounce fires and the preview model renders, the client cache is
    -- already populated and pieces appear without waiting for sequential
    -- tooltip:SetHyperlink round-trips.
    if ns.PrewarmSetData then
        if state.setSource == C.SET_SOURCE_SAVED then
            local s = getSelectedSavedSet()
            if s then ns.PrewarmSetData(s) end
        else
            local s = getSelectedCatalogSet()
            if s then ns.PrewarmSetData(s) end
        end
    end

    fn.updateSetButtons()
    -- Fire immediately; setPreviewModelItems bumps the token so any in-flight
    -- render from a prior selection aborts before applying TryOn calls.
    setPreviewDebounceFrame:Hide()
    _setPreviewElapsed = 0
    fn.updateSetPreview()
end

local function saveCurrentPreviewAsNamedSet(name)
    name = trim(name)
    if name == "" then
        return
    end

    local savedSets = getSavedTransmogSets()
    local snapshot = snapshotCurrentTransmogSet()
    local existing = nil

    for index, setData in ipairs(savedSets) do
        if setData.name == name then
            existing = index
            break
        end
    end

    if existing then
        savedSets[existing].items    = snapshot
        savedSets[existing].enchants = {
            ["Main Hand"] = state.illusionEnchants["Main Hand"] or state.illusionApplied["Main Hand"] or 0,
            ["Off-hand"]  = state.illusionEnchants["Off-hand"]  or state.illusionApplied["Off-hand"]  or 0,
        }
    else
        table.insert(savedSets, {
            name  = name,
            items = snapshot,
            enchants = {
                ["Main Hand"] = state.illusionEnchants["Main Hand"] or state.illusionApplied["Main Hand"] or 0,
                ["Off-hand"]  = state.illusionEnchants["Off-hand"]  or state.illusionApplied["Off-hand"]  or 0,
            },
        })
    end
    invalidateSavedSetIndex()

    state.setSource = C.SET_SOURCE_SAVED
    state.selectedSavedSetName = name
    fn.rebuildSetLists()
    fn.updateSetButtons()
    fn.updateSetPreview()
end

local function loadSetIntoPreviewForEdit(setData)
    if not setData or not setData.items then return end
    if type(setData.enchants) == "table" then
        state.illusionEnchants["Main Hand"] = tonumber(setData.enchants["Main Hand"]) or 0
        state.illusionEnchants["Off-hand"]  = tonumber(setData.enchants["Off-hand"]) or 0
    end
    for index, info in ipairs(SLOT_DATA) do
        local value = tonumber(setData.items[index]) or -1
        if value > 0 then
            setPreviewToItem(info.name, value)
        elseif value == 0 then
            setPreviewToHidden(info.name)
        else
            setPreviewToRestore(info.name)
        end
    end
    refreshAllSlotButtons()
    updatePreviewModel()
    updateStatusText()
    updateActionButtons()
end

function ns.PreviewLinkedSet(setData)
    if not setData or not setData.items then return end
    state.setSource = C.SET_SOURCE_SAVED
    state.selectedSavedSetName = setData.name
    if state.viewMode ~= "sets" then
        state.viewMode = "sets"
        if fn.updateViewMode then fn.updateViewMode() end
    end
    fn.rebuildSetLists()
    fn.updateSetButtons()
    fn.updateSetPreview()
    loadSetIntoPreviewForEdit(setData)
end

fn.beginEditSavedSet = function()
    local savedSet = getSelectedSavedSet()
    if not savedSet then return end
    state.editingSetName = savedSet.name
    loadSetIntoPreviewForEdit(savedSet)
    state.viewMode = "items"
    fn.updateViewMode()
end

fn.cancelEditSavedSet = function()
    state.editingSetName = nil
    revertAllPreview()
    refreshAllSlotButtons()
    updatePreviewModel()
    state.viewMode = "sets"
    state.setSource = C.SET_SOURCE_SAVED
    fn.updateViewMode()
end

fn.confirmSaveEditedSet = function()
    local name = state.editingSetName
    if not name then return end
    StaticPopupDialogs["APPEARANCE_BUDDY_EDIT_SET_CONFIRM"] = {
        text = "Save changes to set \"|cffffd200%s|r\"?",
        button1 = "Save",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function()
            saveCurrentPreviewAsNamedSet(state.editingSetName)
            state.editingSetName = nil
            revertAllPreview()
            state.viewMode = "sets"
            state.setSource = C.SET_SOURCE_SAVED
            fn.updateViewMode()
        end,
        OnCancel = function() end,
    }
    StaticPopup_Show("APPEARANCE_BUDDY_EDIT_SET_CONFIRM", name)
end

local function showSaveCurrentSetDialog()
    if not state.synced then
        SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: wait for transmog data to finish syncing before saving a transmog set.")
        return
    end

    StaticPopupDialogs["APPEARANCE_BUDDY_TRANSMOG_SET_SAVE_DIALOG"] = {
        text = "Enter transmog set name:",
        button1 = "Save",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        hasWideEditBox = true,
        maxLetters = 50,
        preferredIndex = 3,
        OnShow = function(self)
            self.button1:Disable()
            self.wideEditBox:SetText("")
            self.originalOnChange = self.wideEditBox:GetScript("OnTextChanged")
            self.wideEditBox:SetScript("OnTextChanged", function(editBox, ...)
                local text = trim(editBox:GetText())
                if text == "" then
                    self.button1:Disable()
                else
                    self.button1:Enable()
                end
                if self.originalOnChange then
                    self.originalOnChange(editBox, ...)
                end
            end)
        end,
        OnAccept = function(self)
            local enteredName = trim(self.wideEditBox:GetText())
            self.wideEditBox:SetScript("OnTextChanged", self.originalOnChange)
            self.originalOnChange = nil
            saveCurrentPreviewAsNamedSet(enteredName)
        end,
        OnCancel = function(self)
            self.wideEditBox:SetScript("OnTextChanged", self.originalOnChange)
            self.originalOnChange = nil
        end,
    }

    StaticPopup_Show("APPEARANCE_BUDDY_TRANSMOG_SET_SAVE_DIALOG")
end

local function removeSelectedSavedSet()
    local selectedName = state.selectedSavedSetName
    if not selectedName then
        return
    end

    local savedSets = getSavedTransmogSets()
    for index, setData in ipairs(savedSets) do
        if setData.name == selectedName then
            table.remove(savedSets, index)
            break
        end
    end
    invalidateSavedSetIndex()

    state.selectedSavedSetName = nil
    fn.rebuildSetLists()
end

fn.updateViewMode = function()
    if not transmogTab:IsShown() then return end
    local isItems = state.viewMode == "items"
    local isSets = state.viewMode == "sets"
    local isIllusion = state.viewMode == "illusion"

    updateModeButtons()
    -- Illusion mode keeps all item-mode widgets (slot buttons, etc.) visible.
    setItemModeVisible(isItems or isIllusion)

    if isIllusion then
        transmogTab.setsFrame:Hide()
        ns.HideSetShareControls(false)
        -- Replace the list area with the illusion frame.
        transmogTab.list:Hide()
        transmogTab.messageText:Hide()
        transmogTab.illusionFrame:Show()
        transmogTab.illusionFrame.updateWeaponIcon()
        transmogTab.illusionFrame.populate()
        -- Show Apply, Hide, and Restore to match the items tab layout.
        transmogTab.buttonApply:Show()
        transmogTab.buttonHide:Show()
        transmogTab.buttonRestore:Show()
        -- Subclass and rarity filters are item-only; hide them so they don't
        -- overlap the illusion grid header.
        transmogTab.filterButton:Hide()
        transmogTab.rarityFilterButton:Hide()
        closeFilterPopup()
        closeRarityFilterPopup()
        updateStatusText()
        updateActionButtons()
        return
    end

    transmogTab.illusionFrame:Hide()

    if isItems then
        transmogTab.setsFrame:Hide()
        ns.HideSetShareControls(false)
        if ns.RefreshManagedScrollFrame then
            ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll, false)
        end
        transmogTab.buttonApply:Show()
        transmogTab.buttonHide:Show()
        transmogTab.buttonRestore:Show()
        transmogTab.buttonRevert:Show()
        transmogTab.buttonRevertAll:Show()
        transmogTab.buttonApplyAll:Show()
        if not state.enabled then
            showListMessage(state.disabledReason or "Transmog is unavailable.")
        else
            fn.loadCurrentSlotItems()
        end
        updateStatusText()
        updateActionButtons()
    else
        if state.editingSetName then
            state.editingSetName = nil
            revertAllPreview()
        end
        transmogTab.buttonSaveSet:Hide()
        transmogTab.buttonCancelEdit:Hide()
        transmogTab.setsFrame:Show()
        if ns.RefreshManagedScrollFrame then
            ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll)
        end
        fn.rebuildSetLists()
        if state.setSource == C.SET_SOURCE_CATALOG and state.enabled then
            refreshItemSetCatalogIfNeeded(false)
        end
    end
end

local function setSetSource(source)
    if source ~= C.SET_SOURCE_SAVED and source ~= C.SET_SOURCE_CATALOG then
        return
    end

    state.setSource = source
    fn.rebuildSetLists()

    if source == C.SET_SOURCE_CATALOG and state.enabled then
        refreshItemSetCatalogIfNeeded(false)
    end
end

transmogTab.buttonModeItems:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    state.viewMode = "items"
    fn.updateViewMode()
end)

transmogTab.buttonModeSets:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    state.viewMode = "sets"
    fn.updateViewMode()
end)

function ns.PrintSetLinkMessage(senderName, chatType, code, setName, isEcho)
    if type(code) ~= "string" or code == "" then return end
    if type(setName) ~= "string" or setName == "" then setName = "Set" end
    if type(senderName) ~= "string" then senderName = "Unknown" end
    chatType = type(chatType) == "string" and chatType:upper() or "SAY"

    local linkPrefix = ns._setLinkPrefix or "ABset:"
    local nameSafe = setName:gsub("[%[%]|]", "")
    local link = "|cff7eb3ff|H" .. linkPrefix .. code .. "|h[" .. nameSafe .. "]|h|r"

    local prefix
    if chatType == "WHISPER" then
        prefix = string_format("|cffff80ff[%s whispers]|r ", senderName)
    elseif chatType == "GUILD" or chatType == "OFFICER" then
        prefix = string_format("|cff40ff40[%s]|r |cff7eb3ff<%s>|r: ",
            chatType == "OFFICER" and "Officer" or "Guild", senderName)
    elseif chatType == "PARTY" or chatType == "RAID"
        or chatType == "INSTANCE_CHAT" or chatType == "BATTLEGROUND" then
        local label = (chatType == "PARTY" and "Party")
            or (chatType == "RAID" and "Raid")
            or (chatType == "BATTLEGROUND" and "BG")
            or "Instance"
        prefix = string_format("|cffaaaaff[%s]|r |cff7eb3ff<%s>|r: ", label, senderName)
    else
        prefix = string_format("|cffffffff%s %s:|r ",
            senderName, chatType == "YELL" and "yells" or "says")
    end

    local chatFrame = DEFAULT_CHAT_FRAME or SELECTED_CHAT_FRAME or ChatFrame1
    if chatFrame and chatFrame.AddMessage then
        chatFrame:AddMessage(prefix .. link)
    end
end

-- "Copy Set": encode the selected saved set, put the code into the share
-- edit box and select all text so the user can Ctrl+C immediately.
transmogTab.buttonShareCopy:SetScript("OnClick", function()
    if hasCopyableTarget() then
        local targetName = UnitName and UnitName("target") or nil
        if targetName and targetName ~= "" and AIO and AIO.Handle then
            PlaySound("gsTitleOptionOK")
    ns.SafeAioHandle("Transmog", "CopyTargetAppearanceSet", targetName)
            return
        end
    end

    local savedSet = getSelectedSavedSet()
    if not savedSet then return end
    PlaySound("gsTitleOptionOK")
    local code = encodeSetAsShareString(savedSet)
    if not code then return end
    local eb = transmogTab.shareEditBox
    eb:SetText(code)
    eb:SetFocus()
    eb:HighlightText()
end)

-- "Link Set": broadcast a clickable [Set Name] chat link via the server.
--
-- The server's hyperlink validator rejects custom |H prefixes, so we cannot
-- just insert the link into a normal chat edit box. Instead we send the
-- share code + chat type to the server over AIO; the server fans it out to
-- the appropriate audience (say/yell/party/raid/guild/whisper) and each
-- recipient with the addon prints the clickable link locally.
--
-- When the per-client setting `enableSetChatLinks` is disabled we fall back
-- to the legacy behaviour: insert the raw AB1 share code into the active
-- chat edit box so the user can paste it manually.
-- ---------------------------------------------------------------------------
-- Shared helper: link a saved set to chat (used by the Link Set button and
-- Shift+Click on a row in the saved-sets list).
-- ---------------------------------------------------------------------------
linkSavedSet = function(savedSet)
    if not savedSet then return end
    PlaySound("gsTitleOptionOK")

    local s = GetSettings and GetSettings() or nil
    local useLink = not s or s.enableSetChatLinks ~= false

    -- Legacy fallback: paste raw share code into the chat editbox.
    if not useLink then
        local code = encodeSetAsShareString(savedSet)
        if not code then return end
        local chatBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        if chatBox and chatBox:IsShown() then
            chatBox:Insert(code)
            chatBox:SetFocus()
        else
            ChatEdit_ActivateChat(ChatFrame1EditBox)
            ChatFrame1EditBox:Insert(code)
        end
        return
    end

    local code = encodeSetAsShareString(savedSet)
    if not code then return end

    -- Derive chat type + target from the focused chat edit box. If nothing
    -- is focused, default to SAY (matches WoW's chat default).
    local chatType, target = "SAY", ""
    local chatBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if chatBox and chatBox:IsShown() then
        chatType = (chatBox.chatType or chatBox:GetAttribute("chatType") or "SAY"):upper()
        if chatType == "WHISPER" then
            target = chatBox.tellTarget or chatBox:GetAttribute("tellTarget") or ""
        end
        -- Close the chat box; we are not sending plain text.
        if ChatEdit_DeactivateChat then ChatEdit_DeactivateChat(chatBox) end
    end

    -- Channels (incl. trade/general) and unsupported types are not fanned out
    -- by the server; degrade to legacy paste behaviour so the user has a way
    -- to share manually.
    local supported = {
        SAY = true, YELL = true, PARTY = true, RAID = true,
        INSTANCE_CHAT = true, BATTLEGROUND = true,
        GUILD = true, OFFICER = true, WHISPER = true,
    }
    if not supported[chatType] then
        local cb = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        if cb and cb:IsShown() then
            cb:Insert(code); cb:SetFocus()
        else
            ChatEdit_ActivateChat(ChatFrame1EditBox)
            ChatFrame1EditBox:Insert(code)
        end
        SELECTED_CHAT_FRAME:AddMessage(
            "|ccff6ff98<AppearanceBuddy>|r: Channel chat doesn't support clickable set links - share code pasted instead.")
        return
    end

    if AIO and AIO.Handle then
        ns.PrintSetLinkMessage((UnitName and UnitName("player")) or "You",
            chatType, code, savedSet.name or "Set", true)
        transmogTab._localSetLinkEchoes = transmogTab._localSetLinkEchoes or {}
        transmogTab._localSetLinkEchoes[code] = GetTime and GetTime() or 0
        ns.SafeAioHandle("Transmog", "BroadcastSetLink", chatType, target, code, savedSet.name or "Set")
    else
        ns.PrintSetLinkMessage((UnitName and UnitName("player")) or "You",
            chatType, code, savedSet.name or "Set", true)
    end
end

transmogTab.buttonShareLink:SetScript("OnClick", function()
    linkSavedSet(getSelectedSavedSet())
end)

-- ---------------------------------------------------------------------------
-- Inbound chat-link click: hook the global SetItemRef so a click on an
-- |HABset:...|h[Name]|h link pulls the set into the player's saved sets,
-- opens AppearanceBuddy, switches to the Transmog > Sets view and selects
-- the imported set so the user only has to press Apply.
--
-- The per-client setting `enableSetChatLinks` gates this behaviour; when
-- disabled the click silently falls through to the default handler.
-- ---------------------------------------------------------------------------
do
    local PREFIX_LEN = #ns._setLinkPrefix
    local APPEARANCE_PREFIX = "ABappearance:"
    local APPEARANCE_PREFIX_LEN = #APPEARANCE_PREFIX

    local function getSlotNameForItem(itemId)
        local equipLoc = getItemEquipLoc(itemId)
        if equipLoc == "" and ns.QueryItem then
            return nil
        end
        if equipLoc == "INVTYPE_HEAD" then return "Head" end
        if equipLoc == "INVTYPE_SHOULDER" then return "Shoulder" end
        if equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE" then return "Chest" end
        if equipLoc == "INVTYPE_WAIST" then return "Waist" end
        if equipLoc == "INVTYPE_LEGS" then return "Legs" end
        if equipLoc == "INVTYPE_FEET" then return "Feet" end
        if equipLoc == "INVTYPE_WRIST" then return "Wrist" end
        if equipLoc == "INVTYPE_HAND" then return "Hands" end
        if equipLoc == "INVTYPE_CLOAK" then return "Back" end
        if equipLoc == "INVTYPE_TABARD" then return "Tabard" end
        if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_2HWEAPON" then return "Main Hand" end
        if equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then return "Off-hand" end
        if equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN" then return "Ranged" end
        return nil
    end

    local function openAppearanceLink(itemId)
        itemId = tonumber(itemId)
        if not itemId or itemId <= 0 then return end

        local function openResolved()
            local slotName = getSlotNameForItem(itemId) or state.currentSlot or "Head"
            if mainFrame and not mainFrame:IsShown() then mainFrame:Show() end
            local tab1 = mainFrame and _G[mainFrame:GetName() .. "Tab1"]
            if tab1 and tab1:GetScript("OnClick") then tab1:GetScript("OnClick")(tab1) end
            if state.viewMode ~= "items" then
                state.viewMode = "items"
                if fn.updateViewMode then fn.updateViewMode() end
            end
            selectSlot(slotName)
            -- Clear any active search so we browse the full slot list,
            -- then navigate to the page containing this specific item.
            if transmogTab.searchBox then
                transmogTab.searchBox:SetText("")
                transmogTab.searchBox:ClearFocus()
            end
            setPreviewToItem(slotName, itemId)
            fn.refreshSlotButton(slotName)
            updatePreviewModel()
            updateStatusText()
            -- Jump to the page that contains this item (SetCurrentSlotItemPage).
            if fn.requestCurrentSlotItemPage then
                fn.requestCurrentSlotItemPage(slotName, itemId)
            elseif fn.requestCurrentSlotItems then
                fn.requestCurrentSlotItems(false)
            end
        end

        if getSlotNameForItem(itemId) then
            openResolved()
        elseif ns.QueryItem then
            ns.QueryItem(itemId, function()
                openResolved()
            end)
        else
            openResolved()
        end
    end

    -- Right-click handler: show a tiny popup with the AB1 share code in a
    -- selected/highlighted editbox so the user can Ctrl+C and paste it into
    -- the "Paste share code" bar (or anywhere else). Built lazily.
    local function showCopyPopup(code)
        StaticPopupDialogs["AB_COPY_SHARE_CODE"] = StaticPopupDialogs["AB_COPY_SHARE_CODE"] or {
            text         = "AppearanceBuddy share code\n(Ctrl+C to copy)",
            button1      = OKAY or "Okay",
            hasEditBox   = true,
            editBoxWidth = 260,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnShow = function(self, data)
                local eb = self.editBox or _G[self:GetName() .. "EditBox"]
                if eb then
                    eb:SetText(data or "")
                    eb:HighlightText()
                    eb:SetFocus()
                end
            end,
            EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
            EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        }
        StaticPopup_Show("AB_COPY_SHARE_CODE", nil, nil, code)
    end

    -- Replace SetItemRef directly (not hooksecurefunc) so AB links are
    -- intercepted BEFORE Blizzard's code calls SetHyperlink on an unknown
    -- link type, which would produce an error.
    local _origSetItemRef = SetItemRef
    SetItemRef = function(link, text, button)
        if type(link) ~= "string" then
            return _origSetItemRef(link, text, button)
        end

        if link:sub(1, APPEARANCE_PREFIX_LEN) == APPEARANCE_PREFIX then
            openAppearanceLink(link:sub(APPEARANCE_PREFIX_LEN + 1))
            return
        end

        if link:sub(1, PREFIX_LEN) == ns._setLinkPrefix then
            local s = GetSettings and GetSettings() or nil
            if s and s.enableSetChatLinks == false then
                return _origSetItemRef(link, text, button)
            end
            local code = link:sub(PREFIX_LEN + 1)
            if code == "" then return end

            -- Right-click → copy popup; left-click → preview items on model.
            if button == "RightButton" then
                showCopyPopup(code)
                return
            end

            local setData = decodeShareStringToSet(code)
            if not setData then return end

            -- Open addon and switch to Items view so the player can see each
            -- slot previewed on their character and apply individually.
            if mainFrame and not mainFrame:IsShown() then mainFrame:Show() end
            local tab1 = mainFrame and _G[mainFrame:GetName() .. "Tab1"]
            if tab1 and tab1:GetScript("OnClick") then tab1:GetScript("OnClick")(tab1) end
            if state.viewMode ~= "items" then
                state.viewMode = "items"
                if fn.updateViewMode then fn.updateViewMode() end
            end

            loadSetIntoPreviewForEdit(setData)
            return
        end

        return _origSetItemRef(link, text, button)
    end
end

transmogTab.setsFrame.buttonSourceSaved:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    setSetSource(C.SET_SOURCE_SAVED)
end)

transmogTab.setsFrame.buttonSourceCatalog:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    setSetSource(C.SET_SOURCE_CATALOG)
end)

-- ---------------------------------------------------------------------------
-- Mirror the current target's visible gear into our PREVIEW (no apply, no
-- save).  Only slots whose item the player has unlocked (canonical match)
-- are mirrored; the rest are left alone.  Triggered by clicking Copy Set
-- while a valid target exists; without a target the button keeps its
-- original "save current outfit" behaviour.
-- ---------------------------------------------------------------------------
local function mirrorTargetIntoPreview()
    if not (UnitExists and UnitExists("target")) then return false end
    if UnitIsUnit and UnitIsUnit("target", "player") then return false end

    -- Best-effort inspect for players so visible-armor slots are filled.
    -- Non-visible slots (neck/ring/trinket) aren't transmog slots, so we
    -- don't depend on the inspect callback.
    if UnitIsPlayer and UnitIsPlayer("target")
       and CanInspect and CanInspect("target") and NotifyInspect then
        pcall(NotifyInspect, "target")
    end

    local mirrored, skipped = 0, 0
    for _, info in ipairs(SLOT_DATA) do
        local slotName = info.name
        local invToken = C.INVENTORY_TOKEN_BY_SLOT_NAME[slotName]
        local invSlot  = invToken and GetInventorySlotInfo(invToken .. "Slot") or nil
        local itemId   = invSlot and GetInventoryItemID("target", invSlot) or nil
        if itemId and itemId > 0 then
            local canonical = getAppearanceCanonical(slotName, itemId) or itemId
            local hasIt = ns.unlockedItemIds
                          and (ns.unlockedItemIds[canonical] or ns.unlockedItemIds[itemId])
            if hasIt then
                -- Prefer the canonical id so the displayed appearance matches
                -- whatever the player has actually unlocked under that key.
                setPreviewToItem(slotName, canonical)
                mirrored = mirrored + 1
            else
                skipped = skipped + 1
            end
        end
    end

    updatePreviewModel()

    local targetName = (UnitName and UnitName("target")) or "target"
    SELECTED_CHAT_FRAME:AddMessage(string_format(
        "|ccff6ff98<AppearanceBuddy>|r: Mirrored %s's outfit into preview - %d slot%s previewed, %d skipped (locked). Click Apply to commit.",
        targetName, mirrored, mirrored == 1 and "" or "s", skipped))
    return true
end

transmogTab.setsFrame.buttonCopyCurrent:SetScript("OnClick", function()
    PlaySound("gsTitleOptionOK")
    -- If a valid (non-self) target exists, mirror their look into preview.
    -- Otherwise keep the original behaviour: save the current outfit as a set.
    if mirrorTargetIntoPreview() then return end
    showSaveCurrentSetDialog()
end)

transmogTab.setsFrame.buttonRemoveSaved:SetScript("OnClick", function()
    if not state.selectedSavedSetName then
        return
    end

    PlaySound("gsTitleOptionOK")
    removeSelectedSavedSet()
end)

transmogTab.setsFrame.buttonEditSaved:SetScript("OnClick", function()
    if not state.selectedSavedSetName or not state.synced then
        return
    end

    PlaySound("gsTitleOptionOK")
    fn.beginEditSavedSet()
end)

transmogTab.setsFrame.buttonRefreshCatalog:SetScript("OnClick", function()
    if not state.enabled then
        return
    end

    PlaySound("gsTitleOptionOK")
    refreshItemSetCatalogIfNeeded(true)
end)

transmogTab.setsFrame.buttonApplySelected:SetScript("OnClick", function()
    if state.setSource == C.SET_SOURCE_SAVED then
        local savedSet = getSelectedSavedSet()
        if savedSet then
            -- Client-side gold pre-check for saved sets.
            -- Mirrors the server's pre-calc: only new slots (not already applied) cost gold.
            if state.transmogCostEnabled and state.transmogCostPerSlot > 0 then
                local totalCost = 0
                for index = 1, #SLOT_DATA do
                    local v = tonumber(savedSet.items and savedSet.items[index]) or -1
                    if v > 0 then
                        local serverItemId = state.server[SLOT_DATA[index].name].itemId
                        if serverItemId ~= v then
                            totalCost = totalCost + ns.getCostForItem(v)
                        end
                    end
                end
                if totalCost > 0 and GetMoney() < totalCost then
                    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Not enough gold! You need "
                        .. ns.formatCoin(totalCost) .. " to apply this set.")
                    return
                end
            end
            PlaySound("gsTitleOptionOK")
            applyAppearanceSetAsTransmog(savedSet.items, savedSet.enchants)
        end
    else
        local catalogSet = getSelectedCatalogSet()
        if catalogSet then
            PlaySound("gsTitleOptionOK")
            applyUnlockedCatalogSet(catalogSet.id)
            -- Optimistically preview the catalog set's known items on the left-side
            -- model so the player sees the change immediately, without waiting for
            -- the UnlockedItemSetResult + requestServerState round-trip.  The server
            -- may apply fewer slots (only unlocked pieces), but this is a better
            -- experience than the model staying on the stale pre-apply appearance.
            local fullItems = ns.getSetFullItems and ns.getSetFullItems(catalogSet)
            if type(fullItems) == "table" then
                for index, info in ipairs(SLOT_DATA) do
                    local itemId = tonumber(fullItems[index])
                    if itemId and itemId > 0 then
                        setPreviewToItem(info.name, itemId)
                    end
                end
                if ns.requestPreviewFullRedress then ns.requestPreviewFullRedress() end
                refreshAllSlotButtons()
                updatePreviewModel()
                updateStatusText()
                updateActionButtons()
            end
        end
    end
end)

local handlers = {}

-- displayIdByItemId declared above (before onListItemEnter)

-- Transmog cost handlers
handlers.TransmogCostInfo = function(player, enabled, costPerSlot, rarityMult, blizzlike, isGM, allowResetAll)
    noteServerResponse("TransmogCostInfo")
    state.transmogCostEnabled = enabled and true or false
    state.transmogCostPerSlot = tonumber(costPerSlot) or 0
    if type(rarityMult) == "table" then
        state.transmogRarityMult = rarityMult
    end
    state.blizzlikeEnabled = blizzlike and true or false

    -- Switch the filter dropdown options to match the server's blizzlike mode.
    -- In blizzlike mode, only armor/weapon types the character can equip are shown.
    -- In unrestricted mode, all types are shown so cross-class browsing works.
    if ns.applyBlizzlikeSlotFilters then
        ns.applyBlizzlikeSlotFilters(state.blizzlikeEnabled)
    end

    -- If a filter is currently active for the selected slot and that filter option
    -- no longer exists in the new (blizzlike-restricted) list, clear it so the
    -- player isn't stuck with a filter that returns zero results.
    if state.blizzlikeEnabled and state.currentSlot then
        local activeFilter = state.subclassFilter[state.currentSlot]
        if activeFilter then
            local stillValid = false
            local options = ns.slotSubclasses and ns.slotSubclasses[state.currentSlot]
            if options then
                for _, opt in ipairs(options) do
                    if opt == activeFilter then stillValid = true; break end
                end
            end
            if not stillValid then
                state.subclassFilter[state.currentSlot]    = nil
                state.autoSubclassFilter[state.currentSlot]   = nil
                state.manualSubclassFilter[state.currentSlot] = nil
            end
        end
    end
    -- Server now sends the account's GM rank (number) here.  Older builds sent
    -- a boolean (only true when .gm-toggle was on); accept both so a stale
    -- server doesn't break detection.  Treat any rank >= 1 as a GM account.
    local rank = tonumber(isGM)
    if rank ~= nil then
        state.playerGMRank = rank
        state.playerIsGM   = rank >= 1
    else
        state.playerGMRank = isGM and 1 or 0
        state.playerIsGM   = isGM and true or false
    end
    -- Cost config changed → flush per-item cost cache so display stays accurate.
    if ns.invalidateCostCache then ns.invalidateCostCache() end
    -- Show or hide the "Reset All Transmog" button based on server config.
    if ns.btnClearTransmog then
        if allowResetAll == false then ns.btnClearTransmog:Hide() else ns.btnClearTransmog:Show() end
    end
    if transmogTab:IsShown() then
        updateStatusText()
        updateActionButtons()
        if ns._refreshCostText then ns._refreshCostText() end
    end
end

handlers.TransmogCostError = function(player, requiredAmount)
    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Not enough gold! You need " .. ns.formatCoin(tonumber(requiredAmount) or 0) .. " to apply this transmog.")
end

handlers.TransmogError = function(player, message)
    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: " .. tostring(message or "Transmog not allowed."))
end

-- Server-fanned chat link delivery. Renders the |HABset:..|h hyperlink
-- locally in the receiving client so it bypasses the chat hyperlink validator.
handlers.ReceiveSetLink = function(_, senderName, chatType, code, setName, target, isEcho)
    if isEcho and type(code) == "string" then
        local localEchoes = transmogTab._localSetLinkEchoes
        local echoedAt = localEchoes and localEchoes[code]
        local now = GetTime and GetTime() or 0
        if echoedAt and (now == 0 or (now - echoedAt) < 5) then
            localEchoes[code] = nil
            return
        end
    end

    ns.PrintSetLinkMessage(senderName, chatType, code, setName, isEcho)
end

handlers.ReceiveSetLinkError = function(_, message)
    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: " .. tostring(message or "Set link rejected."))
end

handlers.ReceiveTargetAppearanceSet = function(_, targetName, items, enchants, classId)
    if type(items) ~= "table" then return end
    targetName = type(targetName) == "string" and targetName or "Target"
    local setData = {
        name = targetName,
        items = items,
        enchants = {
            ["Main Hand"] = type(enchants) == "table" and (tonumber(enchants[1]) or 0) or 0,
            ["Off-hand"] = type(enchants) == "table" and (tonumber(enchants[2]) or 0) or 0,
        },
    }
    if mainFrame and not mainFrame:IsShown() then mainFrame:Show() end
    local tab1 = mainFrame and _G[mainFrame:GetName() .. "Tab1"]
    if tab1 and tab1:GetScript("OnClick") then tab1:GetScript("OnClick")(tab1) end
    transmogTab.shareEditBox:SetText("")
    transmogTab.shareEditBox:ClearFocus()
    ns.HideSetShareControls(true)
    state.viewMode = "items"
    if fn.updateViewMode then fn.updateViewMode() end
    ns.HideSetShareControls(true)
    loadSetIntoPreviewForEdit(setData)
    ns.HideSetShareControls(true)
    if transmogTab.buttonModeItems then transmogTab.buttonModeItems:LockHighlight() end
    if transmogTab.buttonModeSets then transmogTab.buttonModeSets:UnlockHighlight() end
    if transmogTab.list and transmogTab.list.SelectByItemId then
        local cur = state.currentSlot and state.preview[state.currentSlot]
        transmogTab.list:SelectByItemId((cur and cur.itemId) or -1)
    end
    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Copied " .. ns.ColorPlayerName(targetName, classId) .. "'s appearance set.")
end

handlers.TargetAppearanceSetError = function(_, message)
    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: " .. tostring(message or "Could not copy target appearance."))
end

handlers.WeaponIllusionError = function(player, slotId, message)
    -- The server rejected the apply; roll back the optimistic illusionApplied update
    -- so the slot is marked dirty again and the user can retry after fixing the problem
    -- (e.g. equipping a weapon).
    local slotName = slotId and SLOT_NAME_BY_ID[tonumber(slotId)]
    if slotName then
        state.illusionApplied[slotName]  = nil  -- unknown — resync on next login
        state.illusionEnchants[slotName] = nil  -- revert preview to pre-attempt state
        state.illusionStored[slotName]   = nil
        if state.viewMode == "illusion" then
            local f = transmogTab.illusionFrame
            for _, cell in ipairs(f.cells) do
                cell._isSelected = false
                cell:SetBackdropBorderColor(0.6, 0.52, 0.28, 1)
            end
            updatePreviewModel()
            updateActionButtons()
        end
    end
    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Weapon illusion error \226\128\148 " .. tostring(message or "unknown error."))
end

handlers.WeaponIllusionApplied = function(player, slotId, enchantId)
    local slotName = slotId and SLOT_NAME_BY_ID[tonumber(slotId)]
    enchantId = tonumber(enchantId) or 0
    if slotName then
        state.illusionEnchants[slotName] = enchantId
        state.illusionApplied[slotName]  = enchantId
        state.illusionStored[slotName]   = true
    end
    updatePreviewModel()
    if slotName and ns.TryOnSingleHandWeapon then
        local itemId = state.preview[slotName] and state.preview[slotName].effectiveId
        if itemId and itemId > 0 then
            ns.TryOnSingleHandWeapon(mainFrame.dressingRoom, slotName, itemId, enchantId)
        end
    end
    if transmogTab:IsShown() then
        updateStatusText()
        updateActionButtons()
    end
end

-- Receives the list of available illusion enchant IDs from the server.
-- Replaces the temporary client-side seed so only server-granted illusions show.
handlers.ReceiveAvailableIllusions = function(player, illusionIds)
    if type(illusionIds) ~= "table" then return end
    ns.unlockedIllusionIds = {}
    for _, id in ipairs(illusionIds) do
        ns.unlockedIllusionIds[tonumber(id)] = true
    end
    if state.viewMode == "illusion" then
        transmogTab.illusionFrame.populate()
    end
end

-- Slot-level warning (e.g. off-hand blocks 2H main-hand appearances).
-- Stored and consumed by updateCandidateList so the warning replaces the list.
handlers.SlotWarning = function(player, message)
    state.slotWarning = (message and message ~= "") and message or nil
end

handlers.InitTab = function(player, itemIds, page, hasMorePages, slotId, requestToken, displayIds, totalPages, slotWarning)
    noteServerResponse("InitTab")
    local responseSlot = SLOT_NAME_BY_ID[tonumber(slotId)] or state.currentSlot
    local responseToken = tonumber(requestToken)
    local prefetchCacheKey = responseToken and state.pageCacheTokens[responseToken] or nil

    -- Pre-warm: fire WoW item data requests so GetItemInfo is cache-hot by
    -- the time Update() starts rendering dressing rooms.  For prefetch
    -- responses this runs well before the user navigates to the page;
    -- for the current-page response it fires in the same frame as Update().
    -- ns.QueryItem(id, nil) calls tooltip:SetHyperlink for uncached items,
    -- which actually requests the data — unlike GetItemInfo(id) which is
    -- a pure cache read and does nothing for uncached items.
    if type(itemIds) == "table" and ns.QueryItem then
        for _, raw in ipairs(itemIds) do
            local id = tonumber(raw)
            if id and id > 0 then ns.QueryItem(id, nil) end
        end
    end

    if prefetchCacheKey then
        state.pageCacheTokens[responseToken] = nil
        ns.StoreItemPageCache(prefetchCacheKey, {
            itemIds = itemIds,
            displayIds = displayIds,
            page = page,
            hasMorePages = hasMorePages,
            slotId = slotId,
            totalPages = totalPages,
            slotWarning = slotWarning,
        })
        return
    end

    -- Ghost-page probe: a background request for the last page to check if
    -- it contains only unrenderable items.  We never update the visible grid;
    -- just run DBC + blacklist checks and, if the page is empty after
    -- filtering, cap totalPages so the stale count is never displayed.
    if responseToken and state.probeToken and responseToken == state.probeToken then
        state.probeToken = nil
        if responseSlot ~= state.currentSlot then return end
        -- DBC check on the probed page.
        if type(itemIds) == "table" and GetItemIcon then
            if not ns.queryFailedItemIds then
                _G["AppearanceBuddyBlacklist"] = _G["AppearanceBuddyBlacklist"] or {}
                ns.queryFailedItemIds = _G["AppearanceBuddyBlacklist"]
                ns.queryFailedCount = ns.queryFailedCount or 0
            end
            for _, raw in ipairs(itemIds) do
                local iid = tonumber(raw) or 0
                if iid > 0 and not ns.queryFailedItemIds[iid] and GetItemIcon(iid) == nil then
                    if (ns.queryFailedCount or 0) < C.BLACKLIST_MAX_ENTRIES then
                        ns.queryFailedItemIds[iid] = true
                        ns.queryFailedCount = (ns.queryFailedCount or 0) + 1
                    end
                end
            end
        end
        -- Filter blacklisted items.
        local validCount = 0
        if type(itemIds) == "table" and ns.queryFailedItemIds then
            for _, raw in ipairs(itemIds) do
                local iid = tonumber(raw) or 0
                if iid > 0 and not ns.queryFailedItemIds[iid] then
                    validCount = validCount + 1
                end
            end
        elseif type(itemIds) == "table" then
            validCount = #itemIds
        end
        -- Probe used to permanently cap totalPages here.  That caused
        -- spurious "only N pages" bugs whenever a probe race-fired during
        -- a rapid scroll that already advanced past the probed page.
        -- The server already excludes blacklisted items via excludeList,
        -- so any cap we apply here is stale by the time it lands.
        return
    end

    if responseToken and responseToken ~= state.requestToken then
        return
    end

    if responseSlot ~= state.currentSlot then
        return
    end

    clearBrowseRequest()
    state.slotWarning = (slotWarning and slotWarning ~= "") and slotWarning or nil

    -- Cache display IDs sent alongside item IDs.
    wipe(displayIdByItemId)
    if type(displayIds) == "table" and type(itemIds) == "table" then
        for i = 1, #itemIds do
            local iid = tonumber(itemIds[i])
            local did = tonumber(displayIds[i])
            if iid and iid > 0 and did and did > 0 then
                displayIdByItemId[iid] = did
            end
        end
    end

    -- Belt-and-suspenders: strip any items removed this session before doing
    -- anything else with the list.  This catches server-cache races where the
    -- DELETE reply and the next SetCurrentSlotItemIds response overlap, and
    -- also guards against in-flight prefetch responses that were computed
    -- before the server's InvalidateAccountCaches() call landed.
    if state.removedItemIds and next(state.removedItemIds) and type(itemIds) == "table" then
        local out = {}
        local outDids = type(displayIds) == "table" and {} or nil
        for i, raw in ipairs(itemIds) do
            local iid = tonumber(raw)
            if not iid or not state.removedItemIds[iid] then
                out[#out + 1] = raw
                if outDids then outDids[#outDids + 1] = displayIds[i] end
            end
        end
        itemIds    = out
        displayIds = outDids or displayIds
        -- Re-sync the display-ID lookup to the filtered set.
        wipe(displayIdByItemId)
        if type(displayIds) == "table" then
            for i = 1, #itemIds do
                local iid = tonumber(itemIds[i])
                local did = tonumber(displayIds[i])
                if iid and iid > 0 and did and did > 0 then
                    displayIdByItemId[iid] = did
                end
            end
        end
    end

    -- Accumulate canonical appearance IDs into ns.unlockedItemIds.  InitTab is
    -- a browse/sync response, not an unlock event, so it must never trigger
    -- newly-unlocked fade/message behavior.
    if type(itemIds) == "table" then
        for _, raw in ipairs(itemIds) do
            local iid = tonumber(raw)
            if iid and iid > 0 then
                local canonical = (FindRecord and FindRecord(nil, iid)) or iid
                if not ns.unlockedItemIds[canonical] then
                    ns.unlockedItemIds[canonical] = true
                end
            end
        end
    end

    state.currentPage = tonumber(page) or 1
    state.pageRequestInFlight = false
    state.hasMorePages = hasMorePages and true or false
    -- totalPages hard-caps navigation and prevents ghost pages from stale hasMorePages.
    local totalPagesNum = tonumber(totalPages)
    if totalPagesNum and totalPagesNum >= 1 then
        state.totalPages = totalPagesNum
    end
    -- Server is authoritative for totalPages.  Do NOT shrink it from a
    -- client-side cap; that mechanism caused the "stuck at 6 pages"
    -- regression when fast-scrolling produced transient empty pages.
    state.clientMaxPages = nil

    -- Determine whether this response is for the user's *final* scroll destination
    -- or just an intermediate step while fast-scrolling through pages.
    -- When pendingPage is set and differs from currentPage the user is still
    -- stepping toward a higher (or lower) target; the current page is never
    -- actually *viewed* and must NOT corrupt the blacklist or the page-count caps.
    -- All three guards below (GetItemIcon check, filter-induced cap, empty-page
    -- cap) are gated on this flag so that rapid wheel-scrolling can never
    -- shrink totalPages/clientMaxPages by passing through intermediate pages.
    local onFinalPage = not tonumber(state.pendingPage)
        or tonumber(state.pendingPage) == state.currentPage

    -- Proactive DBC check: GetItemIcon reads the client's item DBC directly.
    -- If it returns nil the item does not exist in the 3.3.5 client files and
    -- will NEVER load, regardless of caching.  Instantly blacklist these items
    -- so they never occupy a grid slot or inflate the page count.
    -- Only run on the final destination page; running it on intermediate pages
    -- grows the excludeList, causing the server to compute a lower maxPage on
    -- the very next step and permanently shrinking the browsable range.
    if onFinalPage and type(itemIds) == "table" and GetItemIcon then
        if not ns.queryFailedItemIds then
            _G["AppearanceBuddyBlacklist"] = _G["AppearanceBuddyBlacklist"] or {}
            ns.queryFailedItemIds = _G["AppearanceBuddyBlacklist"]
            ns.queryFailedCount = ns.queryFailedCount or 0
        end
        for _, raw in ipairs(itemIds) do
            local iid = tonumber(raw) or 0
            if iid > 0 and not ns.queryFailedItemIds[iid] and GetItemIcon(iid) == nil then
                if (ns.queryFailedCount or 0) < C.BLACKLIST_MAX_ENTRIES then
                    ns.queryFailedItemIds[iid] = true
                    ns.queryFailedCount = (ns.queryFailedCount or 0) + 1
                end
            end
        end
    end

    -- Filter out items the client has previously failed to load so they do
    -- not occupy grid slots or inflate the page count.
    if type(itemIds) == "table" and ns.queryFailedItemIds then
        local fid, fdid = _scratch.fid, _scratch.fdid
        wipe(fid)
        wipe(fdid)
        local useDisplayTable = type(displayIds) == "table"
        local removedCount = 0
        for i, raw in ipairs(itemIds) do
            local iid = tonumber(raw) or 0
            if iid > 0 and not ns.queryFailedItemIds[iid] then
                fid[#fid + 1] = raw
                if useDisplayTable then
                    fdid[#fid] = displayIds[i]
                end
            else
                removedCount = removedCount + 1
            end
        end
        if removedCount > 0 then
            itemIds = fid
            displayIds = useDisplayTable and fdid or displayIds
            -- Re-cache display IDs for the filtered set.
            wipe(displayIdByItemId)
            if type(displayIds) == "table" then
                for i = 1, #itemIds do
                    local iid = tonumber(itemIds[i])
                    local did = tonumber(displayIds[i])
                    if iid and iid > 0 and did and did > 0 then
                        displayIdByItemId[iid] = did
                    end
                end
            end
            -- If the server says there are no more pages beyond this one and
            -- items were filtered, cap totalPages so the "Next" button is
            -- disabled and no ghost page appears.
            -- Only cap on the final destination page (not during fast-scroll).
            if onFinalPage and not state.hasMorePages and state.totalPages and state.currentPage <= state.totalPages then
                state.totalPages = state.currentPage
            end
        end
    end

    -- Only apply the empty-page cap when we are on the final destination page.
    -- On an intermediate fast-scroll step an empty page just means all items
    -- were previously blacklisted; we should keep advancing toward pendingPage.
    -- The cap is *session-only* now; the server is authoritative across
    -- sessions.  Next request will re-pass the updated excludeList and the
    -- server will recompute totalPages correctly.
    if onFinalPage and type(itemIds) == "table" and #itemIds == 0 and state.currentPage > 1 then
        state.currentPage = state.currentPage - 1
        state.hasMorePages = false
        state.totalPages = state.currentPage
        state.pendingPage = nil
        fn.updatePageText()
        fn.requestCurrentSlotItems(false)
        return
    end
    if tonumber(state.pendingPage) == state.currentPage then
        state.pendingPage = nil
    elseif tonumber(state.pendingPage) then
        local pendingPage = tonumber(state.pendingPage) or state.currentPage
        if pendingPage < state.currentPage then
            state.pendingPage = nil
        elseif pendingPage > state.currentPage and not state.hasMorePages then
            state.pendingPage = nil
        end
    end
    if trim(transmogTab.searchBox:GetText()) == "" then
        rememberSlotPage(responseSlot, state.currentPage)
    end

    fn.updatePageText()
    updateCandidateList(itemIds or {})
    local pageSize = getCurrentSlotPageSize(responseSlot)
    local rarityFilter = serializeRarityFilter()
    local hideNoLevel = ns.hideNoLevelItems and true or nil
    ns.StoreItemPageCache(ns.GetItemPageCacheKey(
        responseSlot,
        state.currentPage,
        pageSize,
        state.search,
        state.subclassFilter[responseSlot],
        rarityFilter,
        hideNoLevel
    ), {
        itemIds = itemIds,
        displayIds = displayIds,
        page = state.currentPage,
        hasMorePages = state.hasMorePages,
        slotId = slotId,
        totalPages = state.totalPages,
        slotWarning = state.slotWarning,
    })
    local pendingAfterResponse = tonumber(state.pendingPage)
    if not pendingAfterResponse then
        ns.PrefetchItemPage(responseSlot, state.currentPage + 1)
        ns.PrefetchItemPage(responseSlot, state.currentPage + 2)
        ns.PrefetchItemPage(responseSlot, state.currentPage - 1)
        ns.PrefetchItemPage(responseSlot, state.currentPage - 2)
    end
    if pendingAfterResponse and pendingAfterResponse ~= state.currentPage then
        fn.requestCurrentSlotItems(false)
    end

    -- Ghost-page probe: if the server reports more pages than our cap and
    -- we are near the end, silently request the last page to verify it
    -- actually contains renderable items.  This catches custom server items
    -- (e.g. 222221) that only appear on the final page and would otherwise
    -- not be detected until the user scrolls there.
    if state.totalPages and state.currentPage >= state.totalPages - 2
       and state.currentPage < state.totalPages
       and not pendingAfterResponse
       and not state.clientMaxPages and not state.probeToken then
        state.probeToken = state.requestToken + 90000
        local slotId = SLOT_ID_BY_NAME[state.currentSlot]
        local pageSize = getCurrentSlotPageSize(state.currentSlot)
        local subclass = state.subclassFilter[state.currentSlot]
        local rarityFilter = serializeRarityFilter()
        local excludeList = nil
        if ns.queryFailedItemIds then
            local exc = _scratch.exc
            wipe(exc)
            for id in pairs(ns.queryFailedItemIds) do
                exc[#exc + 1] = id
            end
            if #exc > 0 then excludeList = exc end
        end
        if (state.search or "") ~= "" then
        ns.SafeAioHandle("Transmog", "SetSearchCurrentSlotItemIds", slotId, state.totalPages, state.search, pageSize, state.probeToken, subclass, rarityFilter, excludeList)
        else
        ns.SafeAioHandle("Transmog", "SetCurrentSlotItemIds", slotId, state.totalPages, pageSize, state.probeToken, subclass, rarityFilter, excludeList)
        end
    end
end

-- Pre-scan response: server sent the COMPLETE filtered itemId list for the
-- given slot.  DBC-check every id and seed ns.queryFailedItemIds with any
-- that the client cannot render.  After scanning, mark the (slot,filter)
-- combo as scanned and re-issue the current paged request so the server
-- will compute totalPages with the now-complete excludeList.  Result: the
-- "Page 7 / 11" then-converges-to-10 flicker is gone — the count is right
-- on the very first paged response.
handlers.AllItemIdsForSlot = function(player, slotId, csvIds, responseToken)
    noteServerResponse("AllItemIdsForSlot")
    local responseSlot = SLOT_NAME_BY_ID[tonumber(slotId)]
    if not responseSlot then return end
    local key = getPreScanKey(responseSlot)
    -- Drop stale responses (slot/filter changed while in flight).
    if not key or state.preScanInFlight ~= key then
        if state.preScanInFlight == key then state.preScanInFlight = nil end
        return
    end
    state.preScanInFlight = nil

    if GetItemIcon and type(csvIds) == "string" and csvIds ~= "" then
        if not ns.queryFailedItemIds then
            _G["AppearanceBuddyBlacklist"] = _G["AppearanceBuddyBlacklist"] or {}
            ns.queryFailedItemIds = _G["AppearanceBuddyBlacklist"]
            ns.queryFailedCount = ns.queryFailedCount or 0
        end
        local added = 0
        for token in csvIds:gmatch("[^,]+") do
            local iid = tonumber(token) or 0
            if iid > 0 and not ns.queryFailedItemIds[iid] and GetItemIcon(iid) == nil then
                if (ns.queryFailedCount or 0) < C.BLACKLIST_MAX_ENTRIES then
                    ns.queryFailedItemIds[iid] = true
                    ns.queryFailedCount = (ns.queryFailedCount or 0) + 1
                    added = added + 1
                end
            end
        end
        state.preScanned[key] = true
        -- Re-issue the current paged request only if anything changed
        -- (otherwise the in-flight response is already accurate).
        if added > 0 and responseSlot == state.currentSlot then
            fn.requestCurrentSlotItems(false)
        end
    else
        state.preScanned[key] = true
    end
end

-- Bulk seed of ns.unlockedItemIds on login (and every 3 min refresh).
-- Accepts either a comma-separated string (preferred, compact transport) or a
-- numeric array (legacy format).
handlers.AllUnlockedItemIds = function(player, itemIds)
    noteServerResponse("AllUnlockedItemIds")
    -- Mark the lookup as authoritative so isUncollected() stops suppressing
    -- itself.  Set this BEFORE processing items so that even an empty response
    -- (account has no unlocked appearances) clears the false-positive window.
    ns.unlockedItemIdsReady = true
    local unlocked = ns.unlockedItemIds
    local changed = false

    local function consume(iidRaw)
        local iid = tonumber(iidRaw)
        if not (iid and iid > 0) then return end
        local canonical = (FindRecord and FindRecord(nil, iid)) or iid
        if not unlocked[canonical] then
            unlocked[canonical] = true
            changed = true
        end
    end

    if type(itemIds) == "string" then
        for value in itemIds:gmatch("[^,]+") do consume(value) end
    elseif type(itemIds) == "table" then
        for _, raw in ipairs(itemIds) do consume(raw) end
    elseif type(itemIds) == "number" then
        consume(itemIds)
    else
        return
    end

    -- This is a bulk cache seed from the server.  Refresh borders silently, but
    -- do not present these IDs as newly unlocked appearances on login.
    if changed and ns.OnAppearancesUnlocked then
        ns.OnAppearancesUnlocked({})
    end
end

handlers.SetCurrentSlotItemPageClient = function(player, slotId, page, requestToken)
    noteServerResponse("SetCurrentSlotItemPageClient")
    local responseSlot = SLOT_NAME_BY_ID[tonumber(slotId)] or state.currentSlot
    local responseToken = tonumber(requestToken)
    local currentSearch = trim(transmogTab.searchBox:GetText())

    if responseToken and responseToken ~= state.pageLookupToken then
        return
    end

    if responseSlot ~= state.currentSlot or currentSearch ~= "" then
        return
    end

    if state.pageLookupSlot ~= responseSlot then
        return
    end

    if (tonumber(state.pageLookupAnchor) or 0) ~= getCurrentSlotPageAnchor(responseSlot) then
        return
    end

    clearBrowseRequest()
    state.currentPage = tonumber(page) or 1
    if state.currentPage < 1 then
        state.currentPage = 1
    end

    rememberSlotPage(responseSlot, state.currentPage, state.pageLookupAnchor)
    state.pageLookupSlot = nil
    state.pageLookupAnchor = nil
    fn.requestCurrentSlotItems(false)
end

-- Shared logic: update server+preview state for a single slot and refresh its button.
-- Does NOT redraw the model; callers must call updatePreviewModel() themselves.
local function applySlotServerSync(slotId, itemId, realItemId, equippedItemId)
    local slotName = SLOT_NAME_BY_ID[tonumber(slotId)]
    if not slotName then return false end

    local previousServerState = state.server[slotName]
    local previewState = state.preview[slotName]
    local previewUntouched = previewState
        and previewState.mode == "restore"
        and previewState.itemId == nil
        and previewState.effectiveId == nil
    local isInitialSlotSync = previewUntouched
        and previousServerState
        and previousServerState.itemId == nil
        and previousServerState.realItemId == nil

    state.synced = true
    state.server[slotName] = normalizeServerState(itemId, realItemId, slotName, equippedItemId)

    if state.applyingAppearanceSet or state.syncNextSetStateToPreview or state.applyingUnlockedItemSet or isInitialSlotSync or not isSlotDirty(slotName) then
        copyServerToPreview(slotName)
    elseif state.preview[slotName].mode == "restore" then
        state.preview[slotName].effectiveId = state.server[slotName].realItemId
    elseif state.preview[slotName].mode == "item" and state.server[slotName].realItemId and state.preview[slotName].itemId == state.server[slotName].realItemId then
        setPreviewToRestore(slotName)
    end

    fn.refreshSlotButton(slotName)
    return slotName
end

-- Returns the permanent enchant ID embedded in the player's equipped weapon link for
-- the given slot name, or nil if the weapon has no enchant (or no weapon equipped).
local function getEquippedWeaponEnchantId(slotName)
    local invToken = C.INVENTORY_TOKEN_BY_SLOT_NAME[slotName]
    local slotId   = invToken and GetInventorySlotInfo(invToken .. "Slot")
    if not slotId then return nil end
    local link = GetInventoryItemLink("player", slotId)
    if not link then return nil end
    local id = tonumber(link:match("|Hitem:%d+:(%d+):"))
    return (id and id > 0) and id or nil
end

-- Seeds illusionEnchants and illusionApplied from the currently equipped weapon enchants.
-- Only fills slots that haven't been set this session, so a pending illusion preview is
-- not overwritten.  This makes the left-hand preview show the player's real weapon glow
-- on first load without requiring them to open the illusion panel first.
local function initIllusionFromEquipped()
    for _, slotName in ipairs({ "Main Hand", "Off-hand" }) do
        if state.illusionApplied[slotName] == nil then
            local enchantId = getEquippedWeaponEnchantId(slotName)
            if enchantId then
                state.illusionEnchants[slotName] = enchantId
                state.illusionApplied[slotName]  = enchantId
                state.illusionStored[slotName]   = nil
            end
        end
    end
end

-- Batched sync: all slots arrive in one message → one model redraw.
handlers.SetTransmogItemIdsBatch = function(player, batch)
    noteServerResponse("SetTransmogItemIdsBatch")
    if type(batch) ~= "table" then return end
    local touchedCurrentSlot = false
    for _, entry in ipairs(batch) do
        local slotName = applySlotServerSync(entry[1], entry[2], entry[3], entry[4])
        if slotName and slotName == state.currentSlot then
            touchedCurrentSlot = true
        end
        -- Debug: print raw weapon-slot payloads.  Toggle with /abdebug.
        if AppearanceBuddyDebug and (entry[1] == 313 or entry[1] == 315 or entry[1] == 317) then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cff00ff00[AB]|r RX slot=%s item=%s real=%s equipped=%s",
                tostring(entry[1]), tostring(entry[2]),
                tostring(entry[3]), tostring(entry[4])))
        end
    end
    state.syncNextSetStateToPreview = false
    initIllusionFromEquipped()
    updatePreviewModel()
    if ns.RefreshEquipBorders then ns.RefreshEquipBorders() end
    if transmogTab:IsShown() then
        updateStatusText()
        updateActionButtons()
        if touchedCurrentSlot then
            updateListSelection()
        end
        if state.viewMode == "sets" then
            fn.updateSetPreview()
        end
    end
end

-- Single-slot sync (kept for any direct per-slot server calls).
handlers.SetTransmogItemIdClient = function(player, slotId, itemId, realItemId, equippedItemId)
    local slotName = applySlotServerSync(slotId, itemId, realItemId, equippedItemId)
    if not slotName then return end
    initIllusionFromEquipped()
    updatePreviewModel()
    if ns.RefreshEquipBorders then ns.RefreshEquipBorders() end
    if transmogTab:IsShown() then
        updateStatusText()
        updateActionButtons()
        if slotName == state.currentSlot then
            updateListSelection()
        end
        if state.viewMode == "sets" then
            fn.updateSetPreview()
        end
    end
end

handlers.LoadTransmogsAfterSave = function()
    if state.synced then
        updatePreviewModel()
    end
end

-- Receives persisted weapon illusion data from the server (sent during Transmog_Load).
-- This seeds illusionEnchants and illusionApplied so that the main preview (left panel)
-- immediately shows the correct enchant glow without needing the illusion panel open.
-- Overrides any item-link reading done by initIllusionFromEquipped.
handlers.SetStoredIllusions = function(player, illusionData)
    if type(illusionData) ~= "table" then return end
    for _, entry in ipairs(illusionData) do
        local slotId    = entry[1]
        local enchantId = tonumber(entry[2])
        local slotName  = SLOT_NAME_BY_ID[slotId]
        if slotName and enchantId ~= nil then
            -- ANTI-STALE: -1 is the server's "no override" sentinel.  Clear
            -- both illusionEnchants and illusionApplied for this slot so any
            -- leftover hide(0) (or other prior override) from an earlier
            -- session does NOT persist and cause updatePreviewModel to think
            -- enchantDirty is true (which would strip the weapon's natural
            -- glow including temp imbues like Windfury / Flametongue / Reforger
            -- temp-slot enchants / poisons that live in the upper 16 bits).
            if enchantId == -1 then
                state.illusionEnchants[slotName] = nil
                state.illusionApplied[slotName]  = nil
                state.illusionStored[slotName]   = nil
            else
                -- Accept enchantId = 0: it means the player explicitly hid the enchant glow.
                -- Preserve any pending staged change the user has made locally
                -- (e.g. via Revert All or a cell click).  illusionEnchants is the
                -- preview/staging slot — only overwrite it when it agrees with the
                -- previously-applied value (no pending edit), or when it's nil.
                local prevApplied = state.illusionApplied[slotName]
                local pending     = state.illusionEnchants[slotName]
                if pending == nil or pending == prevApplied then
                    state.illusionEnchants[slotName] = enchantId
                end
                state.illusionApplied[slotName] = enchantId
                state.illusionStored[slotName]  = true
            end
        end
    end
    updatePreviewModel()
    if transmogTab:IsShown() then
        updateStatusText()
        updateActionButtons()
    end
end

local function deserializePackedItemIdList(packed)
    local slotCount = #SLOT_DATA

    -- If already a correctly-sized table, coerce values in place to avoid a new allocation
    if type(packed) == "table" then
        if #packed == slotCount then
            for index = 1, slotCount do
                packed[index] = tonumber(packed[index]) or 0
            end
            return packed
        end
        local itemIds = {}
        for index = 1, slotCount do
            itemIds[index] = tonumber(packed[index]) or 0
        end
        return itemIds
    end

    local itemIds = {}
    local index = 1
    for value in tostring(packed or ""):gmatch("[^,]+") do
        if index > slotCount then
            break
        end
        itemIds[index] = tonumber(value) or 0
        index = index + 1
    end

    for fillIndex = index, slotCount do
        itemIds[fillIndex] = 0
    end

    return itemIds
end

-- Lazy accessors for catalog set item arrays.
-- fullItems and unlockedItems are kept as raw CSV strings until first access,
-- avoiding one 14-int array allocation per set on catalog load (saves ~200 bytes
-- × N sets, typically 200-500 sets = 40-100 KB).
-- Defined on ns (not as locals) to stay within Lua 5.1's 200-local-per-function limit.
function ns.getSetFullItems(s)
    if not s._fic then s._fic = deserializePackedItemIdList(s._fir) end
    return s._fic
end
function ns.getSetUnlockedItems(s)
    if not s._uic then s._uic = deserializePackedItemIdList(s._uir) end
    return s._uic
end

local function normalizeCatalogSetData(rawSet)
    if type(rawSet) ~= "table" then
        return nil
    end

    if rawSet.fullItems or rawSet.unlockedItems or rawSet.displayName or rawSet.hasExactTotal ~= nil then
        return {
            id = tonumber(rawSet.id) or 0,
            name = tostring(rawSet.name or "Set"),
            unlockedCount = tonumber(rawSet.unlockedCount) or 0,
            totalCount = tonumber(rawSet.totalCount) or 0,
            hasExactTotal = rawSet.hasExactTotal ~= false,
            -- Store raw strings; lazy-parse via ns.getSetFullItems / ns.getSetUnlockedItems
            _fir = type(rawSet.fullItems) == "string" and rawSet.fullItems
                   or (type(rawSet.fullItems) == "table" and tconcat(rawSet.fullItems, ",") or ""),
            _uir = type(rawSet.unlockedItems) == "string" and rawSet.unlockedItems
                   or (type(rawSet.unlockedItems) == "table" and tconcat(rawSet.unlockedItems, ",") or ""),
        }
    end

    local name = tostring(rawSet[2] or "Set")
    local unlockedCount = tonumber(rawSet[3]) or 0
    local totalCount = tonumber(rawSet[4]) or 0
    local hasExactTotal = tonumber(rawSet[5]) ~= 0
    return {
        id = tonumber(rawSet[1]) or 0,
        name = name,
        unlockedCount = unlockedCount,
        totalCount = totalCount,
        hasExactTotal = hasExactTotal,
        -- Store raw strings for lazy parsing
        _fir = rawSet[6] or "",
        _uir = rawSet[7] or "",
        allowableClass = tonumber(rawSet[8]) or -1,
        armorSubclass  = tonumber(rawSet[9]) or 0,
        weaponMask    = tonumber(rawSet[10]) or 0,
        factionFlag   = tonumber(rawSet[11]) or 0,  -- 0=any, 1=Horde-only, 2=Alliance-only
        hasShield     = (tonumber(rawSet[12]) or 0) ~= 0,
    }
end

handlers.InitItemSets = function(player, itemSets, requestToken, errorMessage)
    noteServerResponse("InitItemSets")
    local responseToken = tonumber(requestToken)
    if responseToken and responseToken > 0 and responseToken ~= state.itemSetCatalogRequestToken then
        return
    end
    if errorMessage and errorMessage ~= "" then
        state.lastBridgeError = tostring(errorMessage)
        state.lastBridgeErrorAt = GetTime and GetTime() or 0
    end

    -- Drop the old catalog reference outright; Lua's incremental GC will
    -- reclaim the orphaned per-entry tables behind the scenes.  The previous
    -- implementation manually wiped every lazy-cache field on every old entry
    -- and then called collectgarbage("collect") — a full stop-the-world pass
    -- that spiked frametime by hundreds of ms on accounts with thousands of
    -- sets.  Letting GC run incrementally is dramatically faster end-to-end.
    state.itemSetCatalog = nil

    local normalizedCatalog = {}
    if type(itemSets) == "table" then
        local n = #itemSets
        for index = 1, n do
            local setData = normalizeCatalogSetData(itemSets[index])
            if setData then
                normalizedCatalog[#normalizedCatalog + 1] = setData
            end
            -- Release the raw packed entry as we go so the source table
            -- shrinks alongside our growing normalised one.
            itemSets[index] = nil
        end
    end

    state.itemSetCatalog = normalizedCatalog
    invalidateCatalogSetIndex()
    state.itemSetCatalogLoaded = true
    state.itemSetCatalogRequestPending = false
    state.itemSetCatalogRequestStartedAt = 0
    state.itemSetCatalogLastRefreshAt = GetTime and GetTime() or 0
    state.itemSetCatalogDirty = false
    state.itemSetCatalogDirtyAt = 0
    -- Successful response — cancel any pending auto-retry.
    state.itemSetCatalogRetryAt    = 0
    state.itemSetCatalogRetryCount = 0

    if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG then
        fn.rebuildSetLists()
    end
end

handlers.Diagnostics = function(player, info)
    noteServerResponse("Diagnostics")
    if type(info) ~= "table" then
        state.serverDiagnostics = nil
        state.serverDiagnosticsReceivedAt = 0
        return
    end

    state.serverDiagnostics = info
    state.serverDiagnosticsReceivedAt = GetTime and GetTime() or 0
end

do
    local catalogTimeoutFrame = CreateFrame("Frame")
    local _lastCountdownShown = -1   -- throttle redundant SetText calls to ~1/s

    catalogTimeoutFrame:SetScript("OnUpdate", function()
        local now = GetTime and GetTime() or 0

        -- ── Apply-unlocked safety timeout ─────────────────────────────────────
        -- If the server never responds to ApplyUnlockedItemSet (e.g. a Lua error
        -- on the server side), the button would stay grey forever.  After 15 s
        -- we silently clear the flag so the player can try again.
        if state.applyingUnlockedItemSet and state.applyingUnlockedItemSetStartedAt > 0
                and now > 0 and (now - state.applyingUnlockedItemSetStartedAt) > 15 then
            state.applyingUnlockedItemSet = false
            state.applyingUnlockedItemSetStartedAt = 0
            if transmogTab:IsShown() and state.viewMode == "sets" then
                fn.updateSetButtons()
            end
        end

        -- ── Auto-retry countdown ──────────────────────────────────────────────
        -- Runs while NOT pending (pending was cleared by the timeout branch below).
        if not state.itemSetCatalogRequestPending and state.itemSetCatalogRetryAt > 0 then
            if now > 0 and now >= state.itemSetCatalogRetryAt then
                -- Countdown expired — fire the retry.
                state.itemSetCatalogRetryAt = 0
                _lastCountdownShown = -1
                fn.requestItemSetCatalog()
            elseif state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG
                    and not getSelectedCatalogSet() then
                -- Update live countdown text once per second.
                local remaining = math_max(0, math.ceil(state.itemSetCatalogRetryAt - now))
                if remaining ~= _lastCountdownShown then
                    _lastCountdownShown = remaining
                    transmogTab.setsFrame.previewTitle:SetText(ABL("Request Timed Out"))
                    transmogTab.setsFrame.previewInfo:SetText(
                        (ABL("GetUnlockedItemSets did not respond.\nRetrying in %ds... (attempt %d/%d)\n\nClick Refresh to retry now.")):format(
                            remaining,
                            state.itemSetCatalogRetryCount,
                            C.CATALOG_MAX_AUTO_RETRIES))
                end
            end
            return
        end

        -- ── Request timeout detection ─────────────────────────────────────────
        if not state.itemSetCatalogRequestPending then
            return
        end

        if now <= 0 or (now - (state.itemSetCatalogRequestStartedAt or 0)) < C.CATALOG_REQUEST_TIMEOUT then
            return
        end

        local timeoutElapsed = now - (state.itemSetCatalogRequestStartedAt or 0)
        state.itemSetCatalogRequestPending = false
        state.itemSetCatalogRequestStartedAt = 0
        _lastCountdownShown = -1

        local inCatalogView = state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG

        if state.itemSetCatalogRetryCount < C.CATALOG_MAX_AUTO_RETRIES then
            -- Schedule an auto-retry.
            state.itemSetCatalogRetryCount = state.itemSetCatalogRetryCount + 1
            state.itemSetCatalogRetryAt    = now + C.CATALOG_AUTO_RETRY_DELAY

            if inCatalogView then
                transmogTab.setsFrame.previewTitle:SetText(ABL("Request Timed Out"))
                transmogTab.setsFrame.previewInfo:SetText(
                    (ABL("GetUnlockedItemSets did not respond after %.1fs.\nRetrying in %ds... (attempt %d/%d)\n\nClick Refresh to retry now.")):format(
                        timeoutElapsed,
                        C.CATALOG_AUTO_RETRY_DELAY,
                        state.itemSetCatalogRetryCount,
                        C.CATALOG_MAX_AUTO_RETRIES))
                transmogTab.setsFrame.previewModel:Undress()
                fn.updateSetButtons()
            end
        else
            -- All retries exhausted — show full diagnostics.
            state.itemSetCatalogRetryAt = 0

            if inCatalogView then
                transmogTab.setsFrame.previewTitle:SetText(ABL("Item Sets Unavailable"))
                transmogTab.setsFrame.previewInfo:SetText(buildCatalogTimeoutDiagnostics(timeoutElapsed))
                transmogTab.setsFrame.previewModel:Undress()
                fn.updateSetButtons()
            end
        end
    end)
end

do
    local browseTimeoutFrame = CreateFrame("Frame")
    browseTimeoutFrame:SetScript("OnUpdate", function()
        local waitingForBrowse = state.pageRequestInFlight or state.pageLookupSlot ~= nil
        if not waitingForBrowse then
            return
        end

        local now = GetTime and GetTime() or 0
        if state.browseRequestRetryAt and state.browseRequestRetryAt > 0 and now > 0 and now >= state.browseRequestRetryAt then
            if not ns.ResendBrowseRequest() then
                local failedLabel = state.browseRequestLabel
                state.pageRequestInFlight = false
                state.pendingPage = nil
                state.pageLookupSlot = nil
                state.pageLookupAnchor = nil
                clearBrowseRequest()
                if state.viewMode == "items" and transmogTab:IsShown() then
                    showListMessage(buildBrowseTimeoutDiagnostics(failedLabel, C.BROWSE_REQUEST_TIMEOUT or 12))
                    updateStatusText()
                    updateActionButtons()
                end
            end
            return
        end

        local startedAt = tonumber(state.browseRequestStartedAt) or 0
        if now <= 0 or startedAt <= 0 or (now - startedAt) < (C.BROWSE_REQUEST_TIMEOUT or 12) then
            return
        end

        local timeoutElapsed = now - startedAt
        local requestLabel = state.browseRequestLabel

        if state.browseRequestRetryCount < C.BROWSE_MAX_AUTO_RETRIES then
            state.browseRequestRetryCount = state.browseRequestRetryCount + 1
            state.browseRequestRetryAt = now + (C.BROWSE_AUTO_RETRY_DELAY or 1.25)
            state.browseRequestStartedAt = now
            if state.viewMode == "items" and transmogTab:IsShown() then
                showListMessage((ABL("Request timed out. Retrying %s... (%d/%d)")):format(
                    tostring(requestLabel or "request"),
                    state.browseRequestRetryCount,
                    C.BROWSE_MAX_AUTO_RETRIES))
                updateStatusText()
                updateActionButtons()
            end
            return
        end

        state.pageRequestInFlight = false
        state.pendingPage = nil
        state.pageLookupSlot = nil
        state.pageLookupAnchor = nil
        clearBrowseRequest()

        if state.viewMode == "items" and transmogTab:IsShown() then
            showListMessage(buildBrowseTimeoutDiagnostics(requestLabel, timeoutElapsed))
            updateStatusText()
            updateActionButtons()
        end
    end)
end

handlers.RemoveUnlockedAppearanceComplete = function(player, success, itemId)
    itemId = tonumber(itemId)

    -- De-dupe: if we recently received ANY reply for this itemId, suppress.
    -- Server can occasionally fire a paired success+fail (e.g. when a click
    -- triggers two delete attempts and the second finds the row already
    -- gone).  The user only cares about the first authoritative result.
    state._removeReplyAt = state._removeReplyAt or {}
    local now = GetTime and GetTime() or 0
    local last = itemId and state._removeReplyAt[itemId] or 0
    if itemId and now > 0 and last > 0 and (now - last) < 2 then
        state._removeReplyAt[itemId] = now
        return
    end
    if itemId and now > 0 then
        state._removeReplyAt[itemId] = now
    end

    if not success then
        SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Failed to remove appearance — item was not found in your unlocked appearances.")
        -- Undo the optimistic session-removal tracking so that the fresh page
        -- request below can re-show the item (the server still owns the row).
        if itemId and state.removedItemIds then
            state.removedItemIds[itemId] = nil
            local canonical = FindRecord and FindRecord(itemId)
            if canonical and canonical ~= itemId then
                state.removedItemIds[canonical] = nil
            end
        end
        -- Optimistic removal got it wrong (server still owns the row).  Pull a
        -- fresh page so the item reappears in the UI.
        fn.requestCurrentSlotItems(false)
        return
    end

    -- The click handler already optimistically removed the item from the
    -- visible list, the unlock cache, the preview, and clamped the page.  We
    -- intentionally do NOT call requestCurrentSlotItems here — that round trip
    -- is exactly what made rapid Ctrl+Shift+Click feel sluggish.

    -- Catalog and sets-view refreshes are coalesced via a single short-delay
    -- timer so spamming N removes triggers ONE rebuild instead of N.
    invalidateItemSetCatalog()
    state._removeRefreshPending = (state._removeRefreshPending or 0) + 1
    if not state._removeRefreshFrame then
        state._removeRefreshFrame = CreateFrame("Frame")
        state._removeRefreshFrame:Hide()
        state._removeRefreshFrame.elapsed = 0
        state._removeRefreshFrame:SetScript("OnUpdate", function(self, dt)
            self.elapsed = self.elapsed + dt
            if self.elapsed < 0.35 then return end
            self.elapsed = 0
            self:Hide()
            state._removeRefreshPending = 0
            if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG then
                refreshItemSetCatalogIfNeeded(true)
            end
        end)
    end
    state._removeRefreshFrame.elapsed = 0
    state._removeRefreshFrame:Show()

    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Unlocked appearance permanently removed from your account.")
end

handlers.AppearanceSetResult = function(player, appliedCount, hiddenCount, missingSlots, restoredCount)
    state.applyingAppearanceSet = false

    if transmogTab:IsShown() and state.viewMode == "sets" then
        fn.updateSetButtons()
    end

    appliedCount  = tonumber(appliedCount)  or 0
    hiddenCount   = tonumber(hiddenCount)   or 0
    restoredCount = tonumber(restoredCount) or 0
    local total = appliedCount + hiddenCount + restoredCount

    -- If the server applied nothing and there are missing slots, let the player know.
    if total == 0 and missingSlots and missingSlots ~= "" then
        SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: Set could not be applied. Missing appearances: " .. tostring(missingSlots))
    end

    -- If nothing at all was applied (server may have rejected due to gold/restrictions),
    -- request a fresh server state sync so the left model reflects reality.
    if total == 0 then
        requestServerState()
    else
        state.syncNextSetStateToPreview = true
        if ns.requestPreviewFullRedress then ns.requestPreviewFullRedress() end
        requestServerState()
    end
end

handlers.UnlockedItemSetResult = function(player, setName, appliedCount, hiddenCount, missingSlots)
    state.applyingUnlockedItemSet = false
    state.applyingUnlockedItemSetStartedAt = 0

    if transmogTab:IsShown() and state.viewMode == "sets" then
        fn.updateSetButtons()
    end

    appliedCount = tonumber(appliedCount) or 0
    if appliedCount > 0 then
        local label = tostring(setName or "Set")
        local msg = string_format("|cffffd200[AppearanceBuddy]|r Applied %d appearance%s from |cffffffff%s|r.",
            appliedCount, appliedCount == 1 and "" or "s", label)
        if missingSlots and missingSlots ~= "" then
            msg = msg .. " |cffff9900Missing: " .. tostring(missingSlots) .. ".|r"
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg)

        -- The server already sent SetTransmogItemIdsBatch from inside
        -- ApplyUnlockedItemSet (before this result message), so the preview
        -- state is already fully synced via that first batch's
        -- applyingUnlockedItemSet=true path.  Do NOT request a full redress
        -- here: that path calls Reset()+ClearModel() which wipes the
        -- DressUpModel to the environment background before the async
        -- SetUnit("player") reload completes, blanking both the left
        -- character preview and the right mini preview.
        -- A lightweight requestServerState() is kept purely as a safety net
        -- (e.g. if the first batch was dropped in an edge case) but without
        -- forcePreviewFullRedress so the second batch uses the safe diff path.
        requestServerState()
    end
end

-- ---------------------------------------------------------------------------
-- GM learn-set (Shift+click catalog row while in GM mode)
-- LearnCatalogSetResult — server reports success/failure of the learn.
-- ---------------------------------------------------------------------------
handlers.LearnCatalogSetResult = function(player, success, setNameOrErr, count)
    if success then
        local learned = tonumber(count) or 0
        local msg = string_format(
            "|cffffcc00[AppearanceBuddy]|r Learned %d appearance%s from |cffffffff%s|r.",
            learned, learned == 1 and "" or "s", tostring(setNameOrErr))
        DEFAULT_CHAT_FRAME:AddMessage(msg)
        -- Force a full catalog re-fetch so the row label updates to the new
        -- count (e.g. 6/8 → 8/8) and turns green when complete.
        -- Reset pending state first so the request is never throttled.
        state.itemSetCatalogRequestPending = false
        state.itemSetCatalogDirty = true
        state.itemSetCatalogLoaded = false
        invalidateCatalogSetIndex()
        -- Also refresh unlocked-item highlights (bag borders / tooltip locks).
        ns.SafeAioHandle("Transmog", "GetAllUnlockedItemIds")
        if transmogTab:IsShown() and state.viewMode == "sets" then
            fn.requestItemSetCatalog()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff5555[AppearanceBuddy]|r Learn set failed: " .. tostring(setNameOrErr))
    end
end

-- ---------------------------------------------------------------------------
-- Saved-set delete confirmation popup (triggered by Shift+click on a saved row).
-- ---------------------------------------------------------------------------
StaticPopupDialogs["AB_REMOVE_SAVED_CONFIRM"] = {
    text = "Delete saved set \"|cffffffff%s|r\"?\n\nThis cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function()
        local name = state._pendingDeleteSetName
        state._pendingDeleteSetName = nil
        if not name then return end
        local savedSets = getSavedTransmogSets()
        for index, setData in ipairs(savedSets) do
            if setData.name == name then
                table.remove(savedSets, index)
                break
            end
        end
        invalidateSavedSetIndex()
        if state.selectedSavedSetName == name then
            state.selectedSavedSetName = nil
        end
        fn.rebuildSetLists()
    end,
    OnCancel = function()
        state._pendingDeleteSetName = nil
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ---------------------------------------------------------------------------
-- Learn-all confirmation popup
-- Shown when the server asks the client to confirm before bulk-unlocking all
-- appearances.  The player must explicitly choose Yes to proceed.
-- ---------------------------------------------------------------------------
StaticPopupDialogs["AB_LEARN_ALL_CONFIRM"] = {
    text = "|cffff4444You are about to unlock ALL appearances on this server.|r\n\n"
        .. "This process will take a |cffffcc00few moments|r and may |cffff9900briefly impact server responsiveness|r depending on the size of the item database.\n\n"
        .. "|cffaaaaaa Note: This may include appearances with |cffff6666broken textures or missing models|r|cffaaaaaa. "
        .. "You may need to |cffffffff manually remove|r |cffaaaaaa unwanted entries from your collected appearances afterward.|r\n\n"
        .. "|cffaaaaaa This also unlocks items used exclusively by NPCs. These items |cffff9900bypass the Horde/Alliance faction filter|r|cffaaaaaa and will appear in the browser regardless of your character's faction.|r\n\n"
        .. "Would you like to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        ns.SafeAioHandle("Transmog", "LearnAllConfirmed")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Server requests confirmation before running learn-all.
handlers.LearnAllConfirm = function()
    if not state.playerIsGM then return end
    StaticPopup_Show("AB_LEARN_ALL_CONFIRM")
end

-- Server signals that learn-all has finished.  Refresh catalog + unlocked
-- item list so new appearances are immediately visible.
handlers.LearnAllDone = function()
    -- Force a full catalog re-fetch (clears server-side cache too via the
    -- dirty flag path).
    state.itemSetCatalogDirty = true
    state.itemSetCatalogLoaded = false
    if transmogTab:IsShown() and state.viewMode == "sets" then
        fn.requestItemSetCatalog()
    end
    -- Also refresh the unlocked-item highlights in the items view.
    ns.SafeAioHandle("Transmog", "GetAllUnlockedItemIds")
end

handlers.ClearAllAccountTransmogComplete = function()
    wipe(ns.unlockedItemIds)
    ns.unlockedItemIdsReady = false
    if ns.OnAppearancesUnlocked then ns.OnAppearancesUnlocked({}) end

    -- Reset all client-side transmog state.
    for _, info in ipairs(SLOT_DATA) do
        state.server[info.name] = normalizeServerState(nil, nil)
        state.preview[info.name] = {
            mode        = "restore",
            itemId      = nil,
            effectiveId = nil,
        }
    end
    state.synced = false
    for _, slotName in ipairs({ "Main Hand", "Off-hand" }) do
        state.illusionEnchants[slotName] = nil
        state.illusionApplied[slotName]  = nil
        state.illusionStored[slotName]   = nil
    end

    -- Flush item-set catalog.
    state.itemSetCatalog = {}
    invalidateCatalogSetIndex()
    state.itemSetCatalogLoaded = false
    invalidateItemSetCatalog()

    -- Re-sync transmog slot data from the server.
    ns.SafeAioHandle("Transmog", "SetTransmogItemIds")

    refreshAllSlotButtons()
    updatePreviewModel()
    if transmogTab:IsShown() then
        updateStatusText()
        updateActionButtons()
        if state.viewMode == "sets" then
            fn.rebuildSetLists()
        end
    end

    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: All account transmog appearances have been permanently cleared.")
end

-- Sent by the server when a player interacts with a transmogrifier NPC.
handlers.TransmogFrame = function()
    if ns.mainFrame and not ns.mainFrame:IsShown() then
        ns.mainFrame:Show()
    end
end

if state.enabled then
    local ok, err = pcall(function()
        AIO.AddHandlers("Transmog", handlers)
    end)

    if not ok then
        state.enabled = false
        state.disabledReason = "Transmog bridge unavailable. Disable the legacy transmog client if it is still loaded."
    end
else
    state.disabledReason = "AIO is not available, so AppearanceBuddy cannot reach the server transmog handlers."
end

-- ---------------------------------------------------------------------------
-- Settings tab: "Reset All Transmog" button (only when AIO is functional).
-- ---------------------------------------------------------------------------
if state.enabled then
    local settingsTab = mainFrame.tabs.settings

    local btnClearTransmog = CreateFrame("Button", "$parentClearTransmogButton", settingsTab, "UIPanelButtonTemplate2")
    ns.btnClearTransmog = btnClearTransmog  -- exposed so TransmogCostInfo can show/hide it
    -- Anchor in the settings tab footer row, matching the transmog tab's action row.
    btnClearTransmog:SetPoint("BOTTOMLEFT", settingsTab, "BOTTOMLEFT", 0, C.ACTION_ROW_Y)
    btnClearTransmog:SetSize(200, 22)
    btnClearTransmog:SetText(ABL("Reset All Transmog..."))
    btnClearTransmog:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffff2020Reset All Account Transmog|r")
        GameTooltip:AddLine(
            "Permanently deletes ALL unlocked transmog appearances from this account and removes all applied transmogrifications on every character. This cannot be undone.",
            1, 1, 1, 1, true
        )
        GameTooltip:Show()
    end)
    btnClearTransmog:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    StaticPopupDialogs["APPEARANCE_BUDDY_CLEAR_ALL_TRANSMOG"] = {
        text = "|cffff2020WARNING|r\n\nThis will |cffff2020permanently delete|r ALL unlocked transmog appearances from your account and remove all applied transmog from every character on this account.\n\nType |cffffd700Clear|r to confirm:\n\n\n",
        button1 = "Confirm",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        hasWideEditBox = true,
        preferredIndex = 3,
        OnShow = function(self)
            self.button1:Disable()
            self.wideEditBox:SetText("")
            self.wideEditBox:SetScript("OnTextChanged", function(editBox)
                -- Require the exact word "Clear" — case-sensitive — before the
                -- confirm button enables. This prevents accidental execution.
                if editBox:GetText() == "Clear" then
                    self.button1:Enable()
                else
                    self.button1:Disable()
                end
            end)
        end,
        OnAccept = function(self)
            -- Double-check the typed text server-side validation is on the
            -- server; this is a final client-side guard against UI races.
            if self.wideEditBox:GetText() ~= "Clear" then
                return
            end
            self.wideEditBox:SetScript("OnTextChanged", nil)
            ns.SafeAioHandle("Transmog", "ClearAllAccountTransmog")
        end,
        OnCancel = function(self)
            self.wideEditBox:SetScript("OnTextChanged", nil)
        end,
        OnHide = function(self)
            -- Always clean up the script reference, even on Escape-close.
            if self.wideEditBox then
                self.wideEditBox:SetScript("OnTextChanged", nil)
            end
        end,
    }

    btnClearTransmog:SetScript("OnClick", function()
        PlaySound("gsTitleOptionOK")
        StaticPopup_Show("APPEARANCE_BUDDY_CLEAR_ALL_TRANSMOG")
    end)
end

ns.ApplyAppearanceSetAsTransmog = applyAppearanceSetAsTransmog
ns.IsTransmogAvailable = function()
    return state.enabled
end

transmogTab:EnableMouseWheel(true)
transmogTab:SetScript("OnMouseWheel", handlePageScroll)
transmogTab.illusionFrame:EnableMouseWheel(true)
transmogTab.illusionFrame:SetScript("OnMouseWheel", handlePageScroll)
transmogTab.illusionFrame.gridFrame:EnableMouseWheel(true)
transmogTab.illusionFrame.gridFrame:SetScript("OnMouseWheel", handlePageScroll)
transmogTab.list:EnableMouseWheel(true)
transmogTab.list:SetScript("OnMouseWheel", handlePageScroll)
transmogTab.searchBox:EnableMouseWheel(true)
transmogTab.searchBox:SetScript("OnMouseWheel", handlePageScroll)
mainFrame:EnableMouseWheel(true)
mainFrame:SetScript("OnMouseWheel", handlePageScroll)

do
    local dressingRoom = mainFrame.dressingRoom
    local originalOnMouseWheel = dressingRoom:GetScript("OnMouseWheel")

    dressingRoom:SetScript("OnMouseWheel", function(self, delta)
        if originalOnMouseWheel then
            originalOnMouseWheel(self, delta)
        end
    end)
end

transmogTab:SetScript("OnShow", function()
    if ns.SetAppearanceBuddyPreviewControlsVisible then
        ns.SetAppearanceBuddyPreviewControlsVisible(false)
    end

    -- Force OnTextChanged to fire so the placeholder FontString always reflects
    -- the actual editbox content on re-open.  A plain visibility check is
    -- unreliable because WoW can restore editbox text after OnShow fires,
    -- meaning GetText() still returns "" at check time; then the late-arriving
    -- text appears under a still-visible placeholder.  Calling SetText with
    -- the current value triggers OnTextChanged synchronously regardless of
    -- whether the text changed, which correctly shows/hides the placeholder.
    transmogTab.searchBox:SetText(transmogTab.searchBox:GetText())

    -- ANTI-STUCK: clear in-memory illusion state on every tab open so a stale
    -- value from a prior session (or a lost AIO message, or a race) cannot
    -- linger and make the preview show hidden when the server no longer has
    -- an override.  The authoritative SetStoredIllusions that follows the
    -- SetTransmogItemIds request below repopulates any real overrides; slots
    -- with no DB row arrive as the -1 sentinel and stay cleared.
    for _, slotName in ipairs({ "Main Hand", "Off-hand" }) do
        state.illusionEnchants[slotName] = nil
        state.illusionApplied[slotName]  = nil
        state.illusionStored[slotName]   = nil
    end

    state.previousUnit = mainFrame.dressingRoom.GetUnitToken and mainFrame.dressingRoom:GetUnitToken() or "player"
    saveDressingRoomView()
    mainFrame.dressingRoom:SetUnit("player")
    setTransmogDressingRoomView()

    selectSlot(state.currentSlot)
    refreshAllSlotButtons()
    updateStatusText()
    updateActionButtons()

    if state.enabled then
        -- Always request a fresh authoritative sync on tab open.  The server
        -- response (SetTransmogItemIdsBatch + SetStoredIllusions) is the only
        -- source of truth that can un-stick a stale preview state.
        ns.SafeAioHandle("Transmog", "SetTransmogItemIds")
    end

    if state.enabled and state.synced and state.viewMode == "items" and transmogTab.list:IsShown() then
        transmogTab.list.currentSlot = state.currentSlot
        transmogTab.list.skipUndress = (state.currentSlot == "Main Hand" or state.currentSlot == "Off-hand")
        local hiddenSlots = {}
        for _, info in ipairs(SLOT_DATA) do
            if state.server[info.name] and state.server[info.name].itemId == 0 then
                hiddenSlots[info.name] = true
            end
        end
        transmogTab.list.hiddenSlots = hiddenSlots
        transmogTab.list.tryOnItems = ns.GetTransmogOutfitItems and ns.GetTransmogOutfitItems(state.currentSlot) or nil
        transmogTab.list:Update()
    end

    updatePreviewModel()
    fn.updateViewMode()
    refreshItemSetCatalogIfNeeded(false)
    if ns.RefreshManagedScrollFrame then
        if state.viewMode == "sets" then
            ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll)
        else
            ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll, false)
        end
    end
end)

transmogTab:SetScript("OnHide", function()
    if ns.SetAppearanceBuddyPreviewControlsVisible then
        ns.SetAppearanceBuddyPreviewControlsVisible(true)
    end

    closeFilterPopup()
    closeRarityFilterPopup()

    -- Hide the global transmog buttons (parented to mainFrame, not transmogTab)
    transmogTab.buttonRevertAll:Hide()
    transmogTab.buttonRevert:Hide()
    transmogTab.buttonApplyAll:Hide()

    -- Only restore real gear and camera when the window fully closes.
    -- When switching to another tab (mainFrame still visible), keep the
    -- transmog preview on the model so the appearance stays consistent.
    if not mainFrame:IsShown() then
        if ns.RefreshDressingRoomFromSlots then
            ns.RefreshDressingRoomFromSlots(state.previousUnit)
        end
        restoreDressingRoomView()
    end

    if ns.RefreshManagedScrollFrame then
        ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll, false)
    end
end)

-- When the window closes while the Settings tab is active, transmogTab:OnHide
-- already fired during the tab-switch (mainFrame was visible then, so it skipped
-- the restore). Hook mainFrame:OnHide to catch that missed restoration.
mainFrame:HookScript("OnHide", function()
    closeFilterPopup()
    closeRarityFilterPopup()
    if not transmogTab:IsShown() then
        if ns.RefreshDressingRoomFromSlots then
            ns.RefreshDressingRoomFromSlots(state.previousUnit)
        end
        restoreDressingRoomView()
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LEVEL_UP" then
        -- Level affects cost formula; flush cache so cost text refreshes.
        if ns.invalidateCostCache then ns.invalidateCostCache() end
        if ns._refreshCostText then ns._refreshCostText() end
        return
    end
    if not state.enabled then
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        lastBagContentsSignature = nil
        invalidateItemSetCatalog()
        requestServerDiagnostics(true)
        ns.SafeAioHandle("Transmog", "LoadPlayer")
        requestServerState()
        if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG then
            refreshItemSetCatalogIfNeeded(false)
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        invalidateItemSetCatalog()
        ns.SafeAioHandle("Transmog", "OnUnequipItem")
        requestServerState()
        if ns.ApplySameTypeFilterForCurrentSlot then
            ns.ApplySameTypeFilterForCurrentSlot(false)
        end
        if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_CATALOG then
            refreshItemSetCatalogIfNeeded(false)
        end
        scheduleBagAppearanceScan(false, 0.1)
    elseif event == "BAG_UPDATE" then
        invalidateItemSetCatalog()
        scheduleBagAppearanceScan(false, 0.2)
    elseif event == "PLAYER_TARGET_CHANGED" then
        if state.viewMode == "sets" and state.setSource == C.SET_SOURCE_SAVED then
            fn.updateSetButtons()
        end
    end
end)

-- Refresh unlocked IDs every 3 minutes so newly earned appearances propagate promptly.
-- The scan also lets equipped items unlock after a vendor refund or group-trade
-- window expires without requiring a relog.
do
    local elapsed = 0
    local unlockedRefreshFrame = CreateFrame("Frame")
    unlockedRefreshFrame:SetScript("OnUpdate", function(self, dt)
        if not state.enabled then elapsed = 0; return end
        elapsed = elapsed + dt
        if elapsed >= 180 then
            elapsed = 0
            ns.SafeAioHandle("Transmog", "ScanInventoryUnlocks")
        end
    end)
end

ns.IsTransmogSynced = function() return state.synced end
ns.RefreshTransmogPreview = function() updatePreviewModel() end
ns.RebuildSetLists = function() if fn.rebuildSetLists then fn.rebuildSetLists() end end
ns.UpdateSetButtons = function() if fn.updateSetButtons then fn.updateSetButtons() end end
-- Exposed for AppearanceBuddy.lua (settings callbacks trigger slot refresh).
ns.requestCurrentSlotItems = function(...) if fn.requestCurrentSlotItems then fn.requestCurrentSlotItems(...) end end
-- Returns effective transmog IDs for all slots (excluding excludeSlot) so mini DRs can mirror the outfit.
ns.GetTransmogOutfitItems = function(excludeSlot)
    if not state.synced then return nil end
    local outfit = _scratch.outfit
    wipe(outfit)

    -- When browsing a non-weapon slot, check whether both hand-weapon slots
    -- have items.  If only one does, WoW's DressUpModel auto-mirrors it into
    -- the empty hand — producing the "dual-wielding one mace" ghost.
    -- Prevent this by skipping hand weapons entirely when there's no pair.
    local isWeaponSlot = C.WEAPON_SLOT[excludeSlot]
    local mhId = state.preview["Main Hand"] and state.preview["Main Hand"].effectiveId
    local ohId = state.preview["Off-hand"] and state.preview["Off-hand"].effectiveId
    local hasMH = mhId and mhId > 0
    local hasOH = ohId and ohId > 0
    local skipHandWeapons = not isWeaponSlot and (hasMH ~= hasOH)

    for _, info in ipairs(SLOT_DATA) do
        if info.name ~= excludeSlot then
            if skipHandWeapons and (info.name == "Main Hand" or info.name == "Off-hand") then
                -- skip to avoid auto-mirror bug (non-weapon browsing, unpaired weapons)
            elseif isWeaponSlot and (info.name == "Main Hand" or info.name == "Off-hand") then
                -- For weapon-slot browsing, omit hand weapons from the outfit.
                -- queryItemHandler injects the real equipped companion weapon
                -- directly via GetInventoryItemID so that exactly ONE hand is
                -- occupied before TryOn(candidate).  If weapons were included
                -- here AND injected below, both hands would be filled before
                -- the candidate, causing INVTYPE_WEAPON to route back to MH.
            else
                local effectiveId = state.preview[info.name] and state.preview[info.name].effectiveId
                if effectiveId and effectiveId > 0 then
                    outfit[#outfit + 1] = effectiveId
                end
            end
        end
    end
    return #outfit > 0 and outfit or nil
end

do
    -- Fixed-schedule re-apply driver.  Triggered by updatePreviewModel(),
    -- runs the re-apply at each scheduled deadline (REAPPLY_SCHEDULE).
    -- Each pass fully Undresses and re-dresses the model so late-arriving
    -- async stages from SetUnit/Reset cannot leave MH/OH wrong.
    local reapplyFrame = CreateFrame("Frame")
    reapplyFrame:Hide()

    local function doReapply()
        if not state.synced or not transmogTab:IsShown() then return end
        local dr = mainFrame.dressingRoom
        updatePreviewInProgress = true

        -- Do NOT Undress here.  Undress in a re-apply races the async model
        -- reload from SetUnit/Reset and tends to leave MH/OH empty.  Mini
        -- previews work precisely because they don't undress the model
        -- before TryOn for hand weapons; we mirror that approach.
        --
        -- IMPORTANT: only TryOn non-weapon slots when there's an actual
        -- transmog override (preview differs from equipped).  Bare TryOn of
        -- the player's REAL armor item is a no-op visually but rebuilds the
        -- model geometry, which strips runtime weapon temp-imbue visuals
        -- (Windfury / Flametongue / Rockbiter).  SetUnit("player") already
        -- rendered the real armor — leave it alone unless we need to override.
        for _, info in ipairs(SLOT_DATA) do
            if not C.WEAPON_SLOT[info.name] then
                local itemId = state.preview[info.name] and state.preview[info.name].effectiveId
                if itemId and itemId > 0 then
                    local invToken   = C.INVENTORY_TOKEN_BY_SLOT_NAME[info.name]
                    local invSlot    = invToken and GetInventorySlotInfo(invToken .. "Slot")
                    local equippedId = invSlot and GetInventoryItemID("player", invSlot) or nil
                    if itemId ~= equippedId then
                        dr:TryOn(itemId)
                    end
                end
            end
        end

        local mhId = state.preview["Main Hand"] and state.preview["Main Hand"].effectiveId
        local ohId = state.preview["Off-hand"] and state.preview["Off-hand"].effectiveId
        local mhEnchant = state.illusionEnchants and state.illusionEnchants["Main Hand"]
        local ohEnchant = state.illusionEnchants and state.illusionEnchants["Off-hand"]
        ns.TryOnHandWeaponPair(dr,
            (mhId and mhId > 0) and mhId or nil, mhEnchant,
            (ohId and ohId > 0) and ohId or nil, ohEnchant)
        -- Ranged intentionally NOT reapplied: it was loaded once by
        -- updatePreviewModel; reapplying it just refreshes a visible gun
        -- without fixing MH/OH visibility.

        if dr.shadowformEnabled then dr:EnableShadowform() end
        updatePreviewInProgress = false
    end

    reapplyFrame:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local deadline = reapplyDeadlines[reapplyNextIndex]
        if not deadline then
            self:Hide()
            return
        end
        if now < deadline then return end
        reapplyNextIndex = reapplyNextIndex + 1
        doReapply()
        if not reapplyDeadlines[reapplyNextIndex] then
            self:Hide()
        end
    end)

    -- Exposed so updatePreviewModel() (which lives outside this do-block
    -- scope) can re-arm the schedule by showing the frame.
    ns.ScheduleReapply = function()
        reapplyFrame:Show()
    end
end

copyAllServerToPreview()
selectSlot(state.currentSlot)
refreshAllSlotButtons()
fn.updatePageText()
updateStatusText()
updateActionButtons()
sortSavedTransmogSets()
fn.rebuildSetLists()
updateModeButtons()
setItemModeVisible(state.viewMode == "items")
if state.viewMode == "items" then
    transmogTab.setsFrame:Hide()
    if ns.RefreshManagedScrollFrame then
        ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll, false)
    end
else
    transmogTab.setsFrame:Show()
    if ns.RefreshManagedScrollFrame then
        ns.RefreshManagedScrollFrame(transmogTab.setsFrame.listScroll)
    end
end

-- /abdebug — toggle verbose RX logging and dump current weapon-slot state.
-- Use when the dressing-room preview is missing a weapon: confirms whether
-- the server is actually sending an equipped item ID for MH/OH/Ranged.
SLASH_APPEARANCEBUDDYDEBUG1 = "/abdebug"
SlashCmdList["APPEARANCEBUDDYDEBUG"] = function(msg)
    AppearanceBuddyDebug = not AppearanceBuddyDebug
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cff00ff00[AB]|r debug logging %s",
        AppearanceBuddyDebug and "ON" or "OFF"))
    for _, slotName in ipairs({ "Main Hand", "Off-hand", "Ranged" }) do
        local s = state.server[slotName] or {}
        local p = state.preview[slotName] or {}
        local invToken = C.INVENTORY_TOKEN_BY_SLOT_NAME[slotName]
        local invSlot  = invToken and GetInventorySlotInfo(invToken.."Slot")
        local clientId = invSlot and GetInventoryItemID("player", invSlot)
        local link     = invSlot and GetInventoryItemLink("player", invSlot)
        local linkId   = link and tonumber(link:match("|Hitem:(%d+):"))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff00ff00[AB]|r %s server.item=%s server.real=%s preview.eff=%s clientGetID=%s linkID=%s",
            slotName,
            tostring(s.itemId), tostring(s.realItemId), tostring(p.effectiveId),
            tostring(clientId), tostring(linkId)))
    end
end

-- Apply custom button skin to all transmog tab buttons.
do
    if ns.SkinButton then
        local btns = {
            transmogTab.buttonSearch, transmogTab.buttonClearSearch,
            transmogTab.filterButton, transmogTab.rarityFilterButton,
            transmogTab.buttonNext, transmogTab.buttonPrev,
            transmogTab.buttonApply, transmogTab.buttonHide,
            transmogTab.buttonRestore, transmogTab.buttonRevert,
            transmogTab.buttonRevertAll, transmogTab.buttonApplyAll,
            transmogTab.buttonSaveSet, transmogTab.buttonCancelEdit,
            transmogTab.buttonModeItems, transmogTab.buttonModeSets,
            transmogTab.buttonShareLink, transmogTab.buttonShareCopy,
            -- Sets sub-frame buttons
            transmogTab.setsFrame and transmogTab.setsFrame.buttonSourceSaved,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonSourceCatalog,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonCopyCurrent,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonRemoveSaved,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonEditSaved,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonRefreshCatalog,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonRevealHidden,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonSearch,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonClearSearch,
            transmogTab.setsFrame and transmogTab.setsFrame.buttonApplySelected,
        }
        for _, btn in pairs(btns) do
            if btn then ns.SkinButton(btn) end
        end
    end
end
