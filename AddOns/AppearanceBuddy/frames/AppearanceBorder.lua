local addon, ns = ...

local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local type = type
local next = next
local unpack = unpack
local math_max = math.max
local math_abs = math.abs
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemID = GetContainerItemID
local GetInventorySlotInfo = GetInventorySlotInfo
local GetInventoryItemLink = GetInventoryItemLink
local _G = _G

local BORDER_TEXTURE           = "Interface\\AddOns\\AppearanceBuddy\\images\\Transmog_Border.tga"
local BORDER_ALPHA             = 0.85

-- ── Transmog-applied border toggle ───────────────────────────────────────────
-- Set to false to hide the gold border on slots that have a transmog applied.
local SHOW_TRANSMOG_APPLIED_BORDER = true
-- ─────────────────────────────────────────────────────────────────────────────

local TRANSMOG_APPLIED_ALPHA   = 0.90
local TRANSMOG_APPLIED_R       = 1.00  -- gold tint for "transmog applied"
local TRANSMOG_APPLIED_G       = 0.80
local TRANSMOG_APPLIED_B       = 0.10
local FADE_DURATION  = 0.25  -- seconds
local BORDER_INSET_H = -8    -- px outward from button edge (horizontal)
local BORDER_INSET_V = -7    -- px outward from button edge (vertical)
local BORDER_OFFSET_Y = 0   -- shift the whole border down (negative = down)

local borderTex        = setmetatable({}, { __mode = "k" })
local transmogBorderTex = setmetatable({}, { __mode = "k" })

local function getBorder(btn)
    if not borderTex[btn] then
        local t = btn:CreateTexture(nil, "OVERLAY")
        t:SetTexture(BORDER_TEXTURE)
        t:SetPoint("TOPLEFT",     btn, "TOPLEFT",      BORDER_INSET_H, -BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -BORDER_INSET_H,  BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetAlpha(0)
        borderTex[btn] = t
    end
    return borderTex[btn]
end

local function getTransmogBorder(btn)
    if not transmogBorderTex[btn] then
        local t = btn:CreateTexture(nil, "OVERLAY")
        t:SetTexture(BORDER_TEXTURE)
        t:SetVertexColor(TRANSMOG_APPLIED_R, TRANSMOG_APPLIED_G, TRANSMOG_APPLIED_B)
        t:SetPoint("TOPLEFT",     btn, "TOPLEFT",      BORDER_INSET_H, -BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -BORDER_INSET_H,  BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetAlpha(0)
        transmogBorderTex[btn] = t
    end
    return transmogBorderTex[btn]
end

-- Called by Transmog.lua to show/hide the gold transmog-applied border on any button.
-- Defined after fadingBorders so the closure captures the upvalue correctly.

-- One shared frame drives all fade animations (Texture objects lack SetScript).
local fadingBorders = {}
local animActive    = false
local animFrame     = CreateFrame("Frame")
-- Reused scratch list to avoid a per-frame table allocation while borders are fading.
local _fadingDone   = {}

local function startAnim()
    if animActive then return end
    animActive = true
    animFrame:SetScript("OnUpdate", function(self, dt)
        local n = 0
        for t, entry in pairs(fadingBorders) do
            entry.elapsed = entry.elapsed + dt
            local a = entry.startAlpha * math_max(1 - entry.elapsed / FADE_DURATION, 0)
            t:SetAlpha(a)
            if entry.elapsed >= FADE_DURATION then
                t:SetAlpha(0)
                n = n + 1
                _fadingDone[n] = t
            end
        end
        for i = 1, n do fadingBorders[_fadingDone[i]] = nil; _fadingDone[i] = nil end
        if not next(fadingBorders) then
            animActive = false
            self:SetScript("OnUpdate", nil)
        end
    end)
end

local function showBorder(t)
    fadingBorders[t] = nil
    t:SetAlpha(BORDER_ALPHA)
end

local function fadeBorder(t)
    local startAlpha = t:GetAlpha()
    if startAlpha <= 0 then return end
    fadingBorders[t] = { startAlpha = startAlpha, elapsed = 0 }
    startAnim()
end

local function hideBorder(t)
    fadingBorders[t] = nil
    t:SetAlpha(0)
end

-- Called by Transmog.lua to show/hide the gold transmog-applied border on any button.
function ns.SetTransmogAppliedBorder(btn, show)
    if not btn then return end
    local t = getTransmogBorder(btn)
    if show and SHOW_TRANSMOG_APPLIED_BORDER then
        fadingBorders[t] = nil
        t:SetAlpha(TRANSMOG_APPLIED_ALPHA)
    else
        fadingBorders[t] = nil
        t:SetAlpha(0)
    end
end

-- Returns true when itemId is in the appearances DB but not yet in ns.unlockedItemIds.
-- Uses the canonical group ID so item variants of the same appearance share one entry.

-- Cache of item IDs the player currently owns (equipped + bags), rebuilt on demand.
local ownedItemCache = {}
local ownedItemCacheDirty = true

local function RebuildOwnedItemCache()
    ownedItemCacheDirty = false
    wipe(ownedItemCache)
    -- Equipped slots 1–19
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then ownedItemCache[id] = true end
    end
    -- Bags 0–4
    for bag = 0, 4 do
        for bslot = 1, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, bslot)
            if id and id > 0 then ownedItemCache[id] = true end
        end
    end
end

-- Mark cache dirty whenever the player's inventory changes.
local _ownedCacheFrame = CreateFrame("Frame")
_ownedCacheFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
_ownedCacheFrame:RegisterEvent("BAG_UPDATE")
_ownedCacheFrame:SetScript("OnEvent", function() ownedItemCacheDirty = true end)

local function playerOwnsItem(itemId)
    if ownedItemCacheDirty then RebuildOwnedItemCache() end
    return ownedItemCache[itemId] == true
end

local function isUncollected(itemId)
    if not itemId or itemId == 0 then return false end
    -- Guard: suppress until the server has sent the initial AllUnlockedItemIds
    -- response.  Before that arrives ns.unlockedItemIds is empty, and any item
    -- in the client DB would look "uncollected" — a guaranteed false positive.
    if not ns.unlockedItemIdsReady then return false end
    -- Guard: only flag items that are actually in our appearances database.
    if not (ns.IsInAppearancesDb and ns.IsInAppearancesDb(itemId)) then return false end
    local canonical = (ns.FindRecord and ns.FindRecord(nil, itemId)) or itemId
    -- Check both the canonical alias AND the raw item ID.
    if ns.unlockedItemIds[canonical] or ns.unlockedItemIds[itemId] then return false end
    -- Suppress false positive: if the player currently has this item equipped
    -- or in their bags, their appearance is physically available — don't flag it.
    if playerOwnsItem(itemId) then return false end
    return true
end

-- newlyUnlockedSet: optional {[canonicalId]=true}; those buttons fade out instead of snap-hide.
local function refreshButton(btn, itemId, newlyUnlockedSet)
    local t = getBorder(btn)
    if ns.showUncollectedBorder ~= false and isUncollected(itemId) then
        showBorder(t)
    elseif newlyUnlockedSet and itemId and newlyUnlockedSet[itemId] then
        fadeBorder(t)
    else
        hideBorder(t)
    end
end

-- Pre-built button name lookup to avoid string concat inside the tight bag loop.
local bagButtonNames = {}
for bag = 0, 4 do
    bagButtonNames[bag] = {}
    for slot = 1, 36 do -- max bag slot count
        bagButtonNames[bag][slot] = "ContainerFrame" .. (bag + 1) .. "Item" .. slot
    end
end

local function forEachBagButton(newlyUnlockedSet)
    for bag = 0, 4 do
        local size = GetContainerNumSlots(bag)
        local names = bagButtonNames[bag]
        for slot = 1, size do
            local btn = _G[names[slot]]
            if btn then
                local itemId = GetContainerItemID(bag, slot)
                refreshButton(btn, itemId, newlyUnlockedSet)
            end
        end
    end
end

local CHAR_SLOTS = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
    "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot",
    "RangedSlot",
}

-- Maps WoW character frame slot names to the Transmog module's slot names.
local CHAR_TO_TRANSMOG_SLOT = {
    HeadSlot          = "Head",
    ShoulderSlot      = "Shoulder",
    BackSlot          = "Back",
    ChestSlot         = "Chest",
    ShirtSlot         = "Shirt",
    TabardSlot        = "Tabard",
    WristSlot         = "Wrist",
    HandsSlot         = "Hands",
    WaistSlot         = "Waist",
    LegsSlot          = "Legs",
    FeetSlot          = "Feet",
    MainHandSlot      = "Main Hand",
    SecondaryHandSlot = "Off-hand",
    RangedSlot        = "Ranged",
}

local function forEachEquipButton(newlyUnlockedSet)
    if not CharacterFrame or not CharacterFrame:IsShown() then return end
    for _, slotName in ipairs(CHAR_SLOTS) do
        local btn = _G["Character" .. slotName]
        if btn then
            local slotId = GetInventorySlotInfo(slotName)
            local link   = slotId and GetInventoryItemLink("player", slotId)
            local itemId = link and tonumber(link:match("item:(%d+)")) or nil
            refreshButton(btn, itemId, newlyUnlockedSet)

            -- Transmog-applied border
            local tb = getTransmogBorder(btn)
            local transmogSlot = CHAR_TO_TRANSMOG_SLOT[slotName]
            if transmogSlot and ns.IsTransmogged and ns.IsTransmogged(transmogSlot) then
                tb:SetAlpha(BORDER_ALPHA)
            else
                tb:SetAlpha(0)
            end
        end
    end
end

-- Allow Transmog.lua to trigger a character-frame border refresh after slot syncs.
ns.RefreshEquipBorders = forEachEquipButton

local NUM_AH_ROWS = 8

-- Map each AH tab to its scroll-frame name so we can compute FauxScrollFrame offsets.
local AH_TABS = {
    { listType = "list",   btnPrefix = "BrowseButton",   scrollFrame = "BrowseScrollFrame"   },
    { listType = "owner",  btnPrefix = "AuctionsButton", scrollFrame = "AuctionsScrollFrame"  },
    { listType = "bidder", btnPrefix = "BidButton",      scrollFrame = "BidScrollFrame"       },
}

-- AH-specific border cache, keyed by the icon frame itself.
local ahBorderTex = setmetatable({}, { __mode = "k" })

-- Locate the item-icon Button inside a BrowseButton/AuctionsButton/BidButton row.
local function findAHIcon(rowBtn)
    local name = rowBtn:GetName()
    if name then
        local sub = _G[name .. "Item"] or _G[name .. "ItemButton"]
        if sub then return sub end
    end
    local children = { rowBtn:GetChildren() }
    for _, child in ipairs(children) do
        local w, h = child:GetWidth(), child:GetHeight()
        if w and h and w > 10 and h > 10 and math_abs(w - h) < 6 then
            return child
        end
    end
    return nil
end

-- Create the border texture on the icon frame directly so it's on top and fits perfectly.
local function getAHBorder(iconBtn)
    if not ahBorderTex[iconBtn] then
        local t = iconBtn:CreateTexture(nil, "OVERLAY")
        t:SetTexture(BORDER_TEXTURE)
        t:SetPoint("TOPLEFT",     iconBtn, "TOPLEFT",      BORDER_INSET_H, -BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetPoint("BOTTOMRIGHT", iconBtn, "BOTTOMRIGHT", -BORDER_INSET_H,  BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetAlpha(0)
        ahBorderTex[iconBtn] = t
    end
    return ahBorderTex[iconBtn]
end

-- Cache icon lookup per row button so findAHIcon only runs once per button.
local rowIconCache = setmetatable({}, { __mode = "k" })

local function refreshAHTab(listType, btnPrefix, scrollFrameName, numRows, newlyUnlockedSet)
    local offset = 0
    local sf = _G[scrollFrameName]
    if sf and FauxScrollFrame_GetOffset then
        offset = FauxScrollFrame_GetOffset(sf) or 0
    end

    local numBatch = GetNumAuctionItems and GetNumAuctionItems(listType) or 0

    for i = 1, numRows do
        local rowBtn = _G[btnPrefix .. i]
        if rowBtn then
            -- Cache the icon lookup so we only search children once.
            if rowIconCache[rowBtn] == nil then
                rowIconCache[rowBtn] = findAHIcon(rowBtn) or false
            end
            local iconBtn = rowIconCache[rowBtn]
            if iconBtn then
                local t = getAHBorder(iconBtn)
                local itemId
                local auctionIndex = offset + i
                if auctionIndex >= 1 and auctionIndex <= numBatch and rowBtn:IsShown() then
                    local link = GetAuctionItemLink(listType, auctionIndex)
                    itemId = link and tonumber(link:match("item:(%d+)")) or nil
                end
                if isUncollected(itemId) then
                    showBorder(t)
                elseif newlyUnlockedSet and itemId and newlyUnlockedSet[itemId] then
                    fadeBorder(t)
                else
                    hideBorder(t)
                end
            end
        end
    end
end

local function forEachAuctionButton(newlyUnlockedSet)
    if not AuctionFrame or not AuctionFrame:IsShown() then return end
    for _, tab in ipairs(AH_TABS) do
        refreshAHTab(tab.listType, tab.btnPrefix, tab.scrollFrame, NUM_AH_ROWS, newlyUnlockedSet)
    end
end

local forEachMerchantButton  -- forward declaration; defined after forEachLootButton
local forEachBagnonButton    -- forward declaration; defined after Bagnon hook setup
local forEachLootButton      -- forward declaration; defined below

local function refreshAllBorders(newlyUnlockedSet)
    forEachBagButton(newlyUnlockedSet)
    forEachBagnonButton(newlyUnlockedSet)
    forEachEquipButton(newlyUnlockedSet)
    forEachAuctionButton(newlyUnlockedSet)
    forEachMerchantButton(newlyUnlockedSet)
    forEachLootButton(newlyUnlockedSet)
end

local currentTooltipItemId
local getTrackedLootButtonIndex
local refreshTrackedLootTooltip

-- Called by Transmog.lua when appearances are unlocked or the registry is wiped.
-- newIds={} means ClearAll — refresh everything immediately.
ns.OnAppearancesUnlocked = function(newIds)
    if #newIds == 0 then
        refreshAllBorders(nil)
        return
    end
    local set = {}
    for _, id in ipairs(newIds) do set[id] = true end
    refreshAllBorders(set)

    -- If the tooltip is showing an item that was just collected, dismiss it so
    -- the stale "not yet collected" line disappears.
    if currentTooltipItemId and GameTooltip:IsShown() then
        local canonical = ns.FindRecord and ns.FindRecord(nil, currentTooltipItemId)
        if canonical and set[canonical] then
            if getTrackedLootButtonIndex and getTrackedLootButtonIndex() then
                refreshTrackedLootTooltip(nil)
            else
                GameTooltip:Hide()
            end
        end
    end
end

ns.RefreshAllBorders = function()
    refreshAllBorders(nil)
end

-- Track which item the GameTooltip is currently displaying so we can dismiss
-- the "not yet collected" tooltip when that appearance is unlocked.
currentTooltipItemId = nil

getTrackedLootButtonIndex = function()
    if not GameTooltip or not GameTooltip.IsShown or not GameTooltip:IsShown() then
        return nil
    end

    local owner = GameTooltip.GetOwner and GameTooltip:GetOwner() or nil
    if not owner then
        return nil
    end

    local lootIndex = owner.GetID and tonumber(owner:GetID()) or nil
    if lootIndex and lootIndex > 0 then
        return lootIndex
    end

    local ownerName = owner.GetName and owner:GetName() or nil
    if type(ownerName) == "string" then
        lootIndex = tonumber(ownerName:match("^LootButton(%d+)$"))
        if lootIndex and lootIndex > 0 then
            return lootIndex
        end
    end

    return nil
end

refreshTrackedLootTooltip = function(changedLootIndex)
    local lootIndex = getTrackedLootButtonIndex()
    if not lootIndex or (changedLootIndex and lootIndex ~= changedLootIndex) then
        return
    end

    currentTooltipItemId = nil

    local link = GetLootSlotLink(lootIndex)
    if link then
        GameTooltip:SetLootItem(lootIndex)
    else
        GameTooltip:Hide()
    end
end

local function addTooltipLine(itemId)
    currentTooltipItemId = itemId
    if ns.showUncollectedTooltip ~= false then
        if isUncollected(itemId) then
            GameTooltip:AddLine(ABL("Item appearance not yet collected!"), 1, 0.65, 0, true)
            GameTooltip:Show()
        end
    end
end

GameTooltip:HookScript("OnHide", function() currentTooltipItemId = nil end)

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
    addTooltipLine(GetContainerItemID(bag, slot))
end)

hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
    local link = GetInventoryItemLink(unit, slot)
    if link then addTooltipLine(tonumber(link:match("item:(%d+)"))) end
end)

hooksecurefunc(GameTooltip, "SetLootItem", function(self, lootIndex)
    local link = GetLootSlotLink(lootIndex)
    if link then addTooltipLine(tonumber(link:match("item:(%d+)"))) end
end)

if type(GameTooltip.SetMerchantItem) == "function" then
    hooksecurefunc(GameTooltip, "SetMerchantItem", function(self, index)
        local link = GetMerchantItemLink and GetMerchantItemLink(index) or nil
        if link then addTooltipLine(tonumber(link:match("item:(%d+)"))) end
    end)
end

if MerchantFrame then
    MerchantFrame:HookScript("OnShow", function() forEachMerchantButton(nil) end)
    MerchantFrame:HookScript("OnHide", function() forEachMerchantButton(nil) end)
end

local ahTickFrame = CreateFrame("Frame")
ahTickFrame:Hide()
ahTickFrame:SetScript("OnUpdate", function(self)
    forEachAuctionButton(nil)
end)

local ahSetupDone = false
local function setupAH()
    if ahSetupDone then return end
    ahSetupDone = true
    if AuctionFrame then
        AuctionFrame:HookScript("OnShow", function()
            ahTickFrame:Show()
        end)
        AuctionFrame:HookScript("OnHide", function()
            ahTickFrame:Hide()
            forEachAuctionButton(nil)  -- clear any borders immediately on close
        end)
        if AuctionFrame:IsShown() then
            ahTickFrame:Show()
        end
    end
    if type(GameTooltip.SetAuctionItem) == "function" then
        hooksecurefunc(GameTooltip, "SetAuctionItem", function(self, listType, index)
            local link = GetAuctionItemLink(listType, index)
            if link then addTooltipLine(tonumber(link:match("item:(%d+)"))) end
        end)
    end
end

-- LootButton<N> is a wide row frame (~243×30 px).  Creating our border on the
-- whole row stretches the square border texture into a useless slab.  We look
-- for the small icon child frame inside the button and create the border there.
local lootIconCache  = setmetatable({}, { __mode = "k" })
local lootBorderTex  = setmetatable({}, { __mode = "k" })

local function getLootIconFrame(btn)
    if lootIconCache[btn] ~= nil then return lootIconCache[btn] end
    local name = btn:GetName()
    -- Try common template child-frame suffixes used by Blizzard
    local icon = name and (
        _G[name .. "ItemButton"] or
        _G[name .. "Slot"]       or
        _G[name .. "Item"])
    if icon and icon.CreateTexture then
        lootIconCache[btn] = icon
        return icon
    end
    -- Walk immediate child frames and pick the first roughly-square one
    local children = { btn:GetChildren() }
    for _, child in ipairs(children) do
        local w, h = child:GetWidth(), child:GetHeight()
        if w and h and w > 8 and h > 8 and math_abs(w - h) < 4 then
            lootIconCache[btn] = child
            return child
        end
    end
    -- Nothing found — create a 30×30 overlay frame at the icon position.
    -- WoW 3.3.5 LootButtonTemplate places the icon 3 px from the left edge.
    local overlay = CreateFrame("Frame", nil, btn)
    overlay:SetSize(30, 30)
    overlay:SetPoint("LEFT", btn, "LEFT", 3, 0)
    lootIconCache[btn] = overlay
    return overlay
end

local function getLootBorder(iconFrame)
    if not lootBorderTex[iconFrame] then
        local t = iconFrame:CreateTexture(nil, "OVERLAY")
        t:SetTexture(BORDER_TEXTURE)
        t:SetPoint("TOPLEFT",     iconFrame, "TOPLEFT",      BORDER_INSET_H, -BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -BORDER_INSET_H,  BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetAlpha(0)
        lootBorderTex[iconFrame] = t
    end
    return lootBorderTex[iconFrame]
end

forEachLootButton = function(newlyUnlockedSet)
    if not LootFrame or not LootFrame:IsShown() then return end
    for i = 1, LOOTFRAME_NUMBUTTONS or 4 do
        local btn = _G["LootButton" .. i]
        if btn then
            local iconFrame = getLootIconFrame(btn)
            local t = getLootBorder(iconFrame)
            if btn:IsShown() then
                local link   = GetLootSlotLink(i)
                local itemId = link and tonumber(link:match("item:(%d+)")) or nil
                if ns.showUncollectedBorder ~= false and isUncollected(itemId) then
                    showBorder(t)
                elseif newlyUnlockedSet and itemId and newlyUnlockedSet[itemId] then
                    fadeBorder(t)
                else
                    hideBorder(t)
                end
            else
                hideBorder(t)
            end
        end
    end
end

-- ── Bagnon compatibility ────────────────────────────────────────────────────
-- When Bagnon's "all frames enabled + no pass-through" condition is not met,
-- it creates BagnonItemSlot<N> buttons instead of reusing ContainerFrame ones.
-- forEachBagButton never finds those, so we hook Bagnon.ItemSlot.Update to
-- refresh our border after every slot update Bagnon performs.
local bagnonButtons  = setmetatable({}, { __mode = "k" })
local bagnonHookDone = false

forEachBagnonButton = function(newlyUnlockedSet)
    for btn in pairs(bagnonButtons) do
        if btn:IsVisible() and not (btn.IsCached and btn:IsCached()) then
            local bag  = btn:GetParent() and btn:GetParent():GetID()
            local slot = btn:GetID()
            if bag ~= nil and slot and slot > 0 then
                local itemId = GetContainerItemID(bag, slot)
                refreshButton(btn, itemId, newlyUnlockedSet)
            end
        end
    end
end

local function setupBagnonHook()
    if bagnonHookDone then return end
    if not (Bagnon and Bagnon.ItemSlot and Bagnon.ItemSlot.Update) then return end
    bagnonHookDone = true
    hooksecurefunc(Bagnon.ItemSlot, "Update", function(self)
        if self.IsCached and self:IsCached() then return end
        bagnonButtons[self] = true
        local bag  = self:GetParent() and self:GetParent():GetID()
        local slot = self:GetID()
        if bag ~= nil and slot and slot > 0 then
            local itemId = GetContainerItemID(bag, slot)
            refreshButton(self, itemId, nil)
        end
    end)
end

-- ── Merchant/Vendor frame: uncollected appearance borders ────────────────────

local MERCHANT_ITEMS_PER_PAGE = 10  -- WoW 3.3.5 shows up to 10 rows at a time

local merchantBorderTex = setmetatable({}, { __mode = "k" })

local function getMerchantBorder(iconBtn)
    if not merchantBorderTex[iconBtn] then
        local t = iconBtn:CreateTexture(nil, "OVERLAY")
        t:SetTexture(BORDER_TEXTURE)
        t:SetPoint("TOPLEFT",     iconBtn, "TOPLEFT",      BORDER_INSET_H, -BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetPoint("BOTTOMRIGHT", iconBtn, "BOTTOMRIGHT", -BORDER_INSET_H,  BORDER_INSET_V + BORDER_OFFSET_Y)
        t:SetAlpha(0)
        merchantBorderTex[iconBtn] = t
    end
    return merchantBorderTex[iconBtn]
end

forEachMerchantButton = function(newlyUnlockedSet)
    if not MerchantFrame or not MerchantFrame:IsShown() then return end
    local offset = 0
    if MerchantListScrollFrame and FauxScrollFrame_GetOffset then
        offset = FauxScrollFrame_GetOffset(MerchantListScrollFrame) or 0
    end
    local total = GetMerchantNumItems and GetMerchantNumItems() or 0
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local iconBtn = _G["MerchantItem" .. i .. "ItemButton"]
        if iconBtn then
            local itemIndex = offset + i
            local link = itemIndex <= total and GetMerchantItemLink and GetMerchantItemLink(itemIndex) or nil
            local itemId = link and tonumber(link:match("item:(%d+)")) or nil
            local t = getMerchantBorder(iconBtn)
            if ns.showUncollectedBorder ~= false and isUncollected(itemId) then
                showBorder(t)
            elseif newlyUnlockedSet and itemId and newlyUnlockedSet[itemId] then
                fadeBorder(t)
            else
                hideBorder(t)
            end
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("LOOT_SLOT_CLEARED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("MERCHANT_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit ~= "player" then return end
    end
    if event == "AUCTION_HOUSE_SHOW" then
        setupAH()
        forEachAuctionButton(nil)
        return
    end
    if event == "AUCTION_ITEM_LIST_UPDATE" then
        forEachAuctionButton(nil)
        return
    end
    if event == "LOOT_OPENED" then
        forEachLootButton(nil)
        return
    end
    if event == "LOOT_CLOSED" then
        forEachLootButton(nil)
        if getTrackedLootButtonIndex() then
            GameTooltip:Hide()
        end
        return
    end
    if event == "LOOT_SLOT_CLEARED" then
        local lootIndex = tonumber(...)
        forEachLootButton(nil)
        refreshTrackedLootTooltip(lootIndex)
        return
    end
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Bagnon" then setupBagnonHook() end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        setupBagnonHook()   -- catch cases where Bagnon loaded before this addon
        refreshAllBorders(nil)
        return
    end
    if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        forEachMerchantButton(nil)
        return
    end
    if event == "MERCHANT_CLOSED" then
        forEachMerchantButton(nil)
        return
    end
    refreshAllBorders(nil)
end)

if CharacterFrame then
    CharacterFrame:HookScript("OnShow", function() forEachEquipButton(nil) end)
end

-- ── Inspect frame: uncollected borders + self-inspect transmog borders ────────

local INSPECT_TO_TRANSMOG_SLOT = {
    InspectHeadSlot          = "Head",
    InspectShoulderSlot      = "Shoulder",
    InspectBackSlot          = "Back",
    InspectChestSlot         = "Chest",
    InspectShirtSlot         = "Shirt",
    InspectTabardSlot        = "Tabard",
    InspectWristSlot         = "Wrist",
    InspectHandsSlot         = "Hands",
    InspectWaistSlot         = "Waist",
    InspectLegsSlot          = "Legs",
    InspectFeetSlot          = "Feet",
    InspectMainHandSlot      = "Main Hand",
    InspectSecondaryHandSlot = "Off-hand",
    InspectRangedSlot        = "Ranged",
}

local INSPECT_SLOT_NAMES = {
    "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot", "InspectBackSlot",
    "InspectChestSlot", "InspectShirtSlot", "InspectTabardSlot", "InspectWristSlot",
    "InspectHandsSlot", "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot",
    "InspectFinger0Slot", "InspectFinger1Slot", "InspectTrinket0Slot", "InspectTrinket1Slot",
    "InspectMainHandSlot", "InspectSecondaryHandSlot", "InspectRangedSlot",
}

local function forEachInspectButton(newlyUnlockedSet)
    if not InspectFrame or not InspectFrame:IsShown() then return end
    local inspectedUnit = InspectFrame.unit or "target"
    local isSelf = UnitIsUnit and UnitIsUnit(inspectedUnit, "player") or false
    for _, slotName in ipairs(INSPECT_SLOT_NAMES) do
        local btn = _G[slotName]
        if btn then
            local baseSlot = slotName:gsub("^Inspect", "")
            local slotId = GetInventorySlotInfo(baseSlot)
            local itemId = slotId and GetInventoryItemID(inspectedUnit, slotId) or nil
            refreshButton(btn, itemId, newlyUnlockedSet)

            -- Show transmog-applied gold border only when inspecting yourself.
            local tb = getTransmogBorder(btn)
            local transmogSlot = INSPECT_TO_TRANSMOG_SLOT[slotName]
            if isSelf and transmogSlot and ns.IsTransmogged and ns.IsTransmogged(transmogSlot) then
                tb:SetAlpha(TRANSMOG_APPLIED_ALPHA)
            else
                tb:SetAlpha(0)
            end
        end
    end
end

ns.RefreshInspectBorders = forEachInspectButton

-- InspectFrame lives in the LoD addon Blizzard_InspectUI, which loads the
-- first time a player is inspected — NOT at our addon's init.  Hook it as
-- soon as the inspect UI appears so the borders attach the very first time.
local function hookInspectFrame()
    if not InspectFrame or InspectFrame.__abHooked then return end
    InspectFrame.__abHooked = true
    InspectFrame:HookScript("OnShow", function() forEachInspectButton(nil) end)
    -- Also refresh if the user switches targets while the frame stays open.
    if InspectPaperDollFrame then
        InspectPaperDollFrame:HookScript("OnShow", function() forEachInspectButton(nil) end)
    end
    -- If the frame is already shown when we hook (race on first inspect), paint now.
    if InspectFrame:IsShown() then
        forEachInspectButton(nil)
    end
end

hookInspectFrame()  -- handles the case where Blizzard_InspectUI was loaded before us

local inspectEventFrame = CreateFrame("Frame")
inspectEventFrame:RegisterEvent("INSPECT_READY")
inspectEventFrame:RegisterEvent("ADDON_LOADED")
inspectEventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            hookInspectFrame()
        end
        return
    end
    -- INSPECT_READY: inspect data just arrived, repaint borders with fresh items.
    forEachInspectButton(nil)
end)
