local addon, ns = ...

local mainFrameTitle     = "|ccff6ff98AppearanceBuddy|r |cffffffff3.9|r |cff7eb3ffPreview Build|r"
local mainFrameTitleAlt  = "|cffffd700AppearanceBuddy|r |cffffce6a3.9|r |cffffb347Preview Build|r"

local _, raceFileName = UnitRace("player")
local _, classFileName = UnitClass("player")

local previewSetupVersion = "classic"

local armorSlots = {"Head", "Shoulder", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet"}
local backSlot = "Back"
local miscellaneousSlots = {"Tabard", "Shirt"}
local mainHandSlot = "Main Hand"
local offHandSlot = "Off-hand"
local rangedSlot = "Ranged"

local addonMessagePrefix = "AppearanceBuddy"
-- Used in look saving/sending. Changing will break compatibility.
local slotOrder = { "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist", "Legs", "Feet", "Main Hand", "Off-hand", "Ranged",}

local slotTextures = {
    ["Head"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-head",
    ["Shoulder"] =  "Interface\\Paperdoll\\ui-paperdoll-slot-shoulder",
    ["Back"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-chest",
    ["Chest"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-chest",
    ["Shirt"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-shirt",
    ["Tabard"] =    "Interface\\Paperdoll\\ui-paperdoll-slot-tabard",
    ["Wrist"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-wrists",
    ["Hands"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-hands",
    ["Waist"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-waist",
    ["Legs"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-legs",
    ["Feet"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-feet",
    ["Main Hand"] = "Interface\\Paperdoll\\ui-paperdoll-slot-mainhand",
    ["Off-hand"] =  "Interface\\Paperdoll\\ui-paperdoll-slot-secondaryhand",
    ["Ranged"] =    "Interface\\Paperdoll\\ui-paperdoll-slot-ranged",
}

local slotSubclasses = {--[[
    ["slot1"] = {subclass1, subclass2, ...},
    ["slot2"] = {subclass1, subclass2, ...},
    ...]]
}

do
    -- ── Class-specific armor filter options ───────────────────────────────────
    -- Mirrors CLASS_MAX_ARMOR_SUBCLASS on the server (1=Cloth, 2=Leather,
    -- 3=Mail, 4=Plate).  Only armor types up to the class's proficiency are
    -- shown; types above it are invisible so the dropdown never returns empty.
    local CLASS_MAX_ARMOR = {
        MAGE=1, PRIEST=1, WARLOCK=1,
        DRUID=2, ROGUE=2,
        HUNTER=3, SHAMAN=3,
        WARRIOR=4, PALADIN=4, DEATHKNIGHT=4,
    }
    local ARMOR_SEQUENCE = {"Cloth", "Leather", "Mail", "Plate"}
    local maxArmorRank = CLASS_MAX_ARMOR[classFileName] or 4
    local allowedArmorSubclasses = {}
    for i = 1, maxArmorRank do
        allowedArmorSubclasses[i] = ARMOR_SEQUENCE[i]
    end
    for _, slot in ipairs(armorSlots) do slotSubclasses[slot] = allowedArmorSubclasses end

    for _, slot in ipairs(miscellaneousSlots) do slotSubclasses[slot] = {"Miscellaneous"} end
    slotSubclasses[backSlot] = {"Cloth", }

    -- ── Class-specific weapon filter options ─────────────────────────────────
    -- Mirrors CLASS_ALLOWED_WEAPON_SUBCLASSES on the server so the dropdown
    -- only shows weapon types the player's class can actually equip.
    local classNameToId = {
        WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
        DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9, DRUID = 11,
    }
    local classWeaponAllowed = {
        [1]  = {[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true},
        [2]  = {[0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true},
        [3]  = {[0]=true,[1]=true,[2]=true,[3]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true},
        [4]  = {[0]=true,[2]=true,[3]=true,[4]=true,[7]=true,[13]=true,[15]=true,[16]=true,[18]=true},
        [5]  = {[4]=true,[10]=true,[15]=true,[19]=true},
        [6]  = {[0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true},
        [7]  = {[0]=true,[1]=true,[4]=true,[5]=true,[10]=true,[13]=true,[15]=true},
        [8]  = {[7]=true,[10]=true,[15]=true,[19]=true},
        [9]  = {[7]=true,[10]=true,[15]=true,[19]=true},
        [11] = {[4]=true,[5]=true,[6]=true,[10]=true,[13]=true,[15]=true},
    }
    local classShieldAllowed = { [1]=true, [2]=true, [7]=true }

    -- Subclass → option name + which slot(s) it can appear in.
    local subclassSlots = {
        [0]  = { name="Axe",        main=true, off=true  },
        [1]  = { name="Axe (2H)",   main=true            },
        [2]  = { name="Bow",                   ranged=true },
        [3]  = { name="Gun",                   ranged=true },
        [4]  = { name="Mace",       main=true, off=true  },
        [5]  = { name="Mace (2H)",  main=true            },
        [6]  = { name="Polearm",    main=true            },
        [7]  = { name="Sword",      main=true, off=true  },
        [8]  = { name="Sword (2H)", main=true            },
        [10] = { name="Staff",      main=true            },
        [13] = { name="Fist",       main=true, off=true  },
        [15] = { name="Dagger",     main=true, off=true  },
        [16] = { name="Thrown",                ranged=true },
        [18] = { name="Crossbow",              ranged=true },
        [19] = { name="Wand",                  ranged=true },
    }
    -- Preferred display order for each slot.
    local mainOrder   = {"Axe","Mace","Sword","Dagger","Fist","Axe (2H)","Mace (2H)","Sword (2H)","Polearm","Staff"}
    local offOrder    = {"Axe","Mace","Sword","Dagger","Fist","Shield","Held in Off-hand"}
    local rangedOrder = {"Bow","Crossbow","Gun","Wand","Thrown"}

    local classId = classNameToId[classFileName] or 0
    local allowed = classWeaponAllowed[classId] or {}

    local inMain, inOff, inRanged = {}, {}, {}
    for sub, info in pairs(subclassSlots) do
        if allowed[sub] then
            if info.main   then inMain[info.name]   = true end
            if info.off    then inOff[info.name]     = true end
            if info.ranged then inRanged[info.name]  = true end
        end
    end
    if classShieldAllowed[classId] then inOff["Shield"] = true end
    inOff["Held in Off-hand"] = true  -- every class can have a held-in-off-hand

    local mainOptions, offOptions, rangedOptions = {}, {}, {}
    for _, n in ipairs(mainOrder)   do if inMain[n]   then mainOptions[#mainOptions+1]     = n end end
    for _, n in ipairs(offOrder)    do if inOff[n]    then offOptions[#offOptions+1]       = n end end
    for _, n in ipairs(rangedOrder) do if inRanged[n] then rangedOptions[#rangedOptions+1] = n end end

    slotSubclasses[mainHandSlot] = mainOptions
    slotSubclasses[offHandSlot]  = offOptions
    slotSubclasses[rangedSlot]   = rangedOptions

    -- Snapshot the class-specific (blizzlike) subclasses before overriding them
    -- for unrestricted servers.  ns.applyBlizzlikeSlotFilters() switches between
    -- these two sets when the server reports its blizzlike status.
    local blizzlikeSubclasses = {}
    for slotName, subs in pairs(slotSubclasses) do
        blizzlikeSubclasses[slotName] = subs
    end

    -- Default to unrestricted (all armor types, all weapon types) so non-blizzlike
    -- servers can show cross-class appearances.  Blizzlike servers receive
    -- T.Blizzlike_Transmog=true in TransmogCostInfo and switch to the restricted set.
    local unrestrictedArmorAll = {"Cloth", "Leather", "Mail", "Plate"}
    for _, slot in ipairs(armorSlots) do slotSubclasses[slot] = unrestrictedArmorAll end
    slotSubclasses[mainHandSlot] = mainOrder
    slotSubclasses[offHandSlot]  = offOrder
    slotSubclasses[rangedSlot]   = rangedOrder

    local unrestrictedSubclasses = {}
    for slotName, subs in pairs(slotSubclasses) do
        unrestrictedSubclasses[slotName] = subs
    end

    -- Switches the filter-dropdown options to either blizzlike (class-appropriate)
    -- or unrestricted (all armor/weapon types) depending on the server setting.
    -- Mutates slotSubclasses in-place so SLOT_SUBCLASSES in Transmog.lua
    -- (which holds the same table reference) reflects the change immediately.
    function ns.applyBlizzlikeSlotFilters(enabled)
        local source = enabled and blizzlikeSubclasses or unrestrictedSubclasses
        for slotName, subs in pairs(source) do
            slotSubclasses[slotName] = subs
        end
    end
end

local defaultSlot = "Head"

local defaultSettings = {
    dressingRoomBackgroundColor = {0.6, 0.6, 0.6, 1},
    dressingRoomBackgroundTexture = {
        [GetRealmName()] = {
            [GetUnitName("player")] = classFileName == "DEATHKNIGHT" and classFileName or raceFileName,
        },
    },
    gridBackground = true,
    miniCellBorderColor = {0.6, 0.52, 0.28},
    previewSetup = "classic", -- possible values are "classic" and "modern",
    miniPreviewMode = "static", -- possible values are "static" and "dynamic",
    miniPreviewMaxZoom = 1.0,
    miniPreviewPositionAdjust = 0.0,
    miniPreviewVerticalAdjust = 0.0,
    showAppearanceBuddyButton = true,
    showShortcutsInTooltip = true,
    ignoreUIScaling = false,
    windowLocked = false,
    removeTransmogAppearanceEnabled = true,
    showDisplayIdInTooltip = true,
    showItemIdInTooltip = true,
    itemOnlyView = false,
    sameTypeFilter = true,
    showUncollectedBorder = true,
    showUncollectedTooltip = true,
    showTransmogCost = true,
    enableSetChatLinks = true,
    hideNoLevelItems = false,
    hideCustomSets = false,
    hideJunkSets = true,
    showOffhandInMainhandPreview = false,
    appearanceButtonSize = 30,
    showGithubButton = true,
    muteUISounds = false,
    alternativeWindowAppearance = false,
}

local function GetSettings()
    local function copyTable(tableFrom)
        local result = {}
        for k, v in pairs(tableFrom) do
            if type(v) == "table" then
                result[k] = copyTable(v)
            else
                result[k] = v
            end
        end
        return result
    end

    -- Migrate from old DressMe variable name
    if _G["AppearanceBuddySettings"] == nil and type(_G["DressMeSettings"]) == "table" then
        _G["AppearanceBuddySettings"] = copyTable(_G["DressMeSettings"])
        _G["DressMeSettings"] = nil
    end

    if _G["AppearanceBuddySettings"] == nil then
        _G["AppearanceBuddySettings"] = copyTable(defaultSettings)
    else
        for k, v in pairs(defaultSettings) do
            if _G["AppearanceBuddySettings"][k] == nil then
                _G["AppearanceBuddySettings"][k] = type(v) == "table" and copyTable(v) or v
            end
        end
        if _G["AppearanceBuddySettings"].dressingRoomBackgroundTexture[GetRealmName()] == nil then
            _G["AppearanceBuddySettings"].dressingRoomBackgroundTexture[GetRealmName()] = {}
        end
        if _G["AppearanceBuddySettings"].dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] == nil then
            _G["AppearanceBuddySettings"].dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] = defaultSettings.dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]
        end
    end

    return _G["AppearanceBuddySettings"]
end


local function getManagedScrollFrameParts(scrollFrame)
    if not scrollFrame then
        return nil, nil, nil
    end

    local scrollBar = scrollFrame.ScrollBar
    if not scrollBar and scrollFrame.GetName then
        local frameName = scrollFrame:GetName()
        if frameName and frameName ~= "" then
            scrollBar = _G[frameName.."ScrollBar"]
        end
    end
    if not scrollBar then
        return nil, nil, nil
    end

    local scrollUpButton = scrollBar.ScrollUpButton or _G[scrollBar:GetName().."ScrollUpButton"]
    local scrollDownButton = scrollBar.ScrollDownButton or _G[scrollBar:GetName().."ScrollDownButton"]
    return scrollBar, scrollUpButton, scrollDownButton
end

local function RefreshManagedScrollFrame(scrollFrame, forcedVisibility)
    local scrollBar, scrollUpButton, scrollDownButton = getManagedScrollFrameParts(scrollFrame)
    if not scrollBar then
        return
    end

    local shouldShow
    if forcedVisibility ~= nil then
        shouldShow = forcedVisibility and true or false
    else
        shouldShow = false
        if scrollFrame:IsVisible() then
            local scrollChild = scrollFrame:GetScrollChild()
            local childHeight = scrollChild and tonumber(scrollChild:GetHeight()) or 0
            local frameHeight = tonumber(scrollFrame:GetHeight()) or 0
            shouldShow = childHeight > frameHeight + 1
        end
    end

    if shouldShow then scrollBar:Show() else scrollBar:Hide() end
    if scrollUpButton then
        if shouldShow then scrollUpButton:Show() else scrollUpButton:Hide() end
    end
    if scrollDownButton then
        if shouldShow then scrollDownButton:Show() else scrollDownButton:Hide() end
    end

    if not shouldShow and scrollFrame.SetVerticalScroll then
        scrollFrame:SetVerticalScroll(0)
    end
end

local function IsWindowLocked()
    return GetSettings().windowLocked and true or false
end


local dressingRoomBorderBackdrop = { -- For a frame above DressingRoom
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\AddOns\\AppearanceBuddy\\images\\mirror-border",
	tile = false, tileSize = 16, edgeSize = 32,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}


local mainFrame = CreateFrame("Frame", addon, UIParent)
mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
mainFrame:SetToplevel(true)
mainFrame:SetFrameLevel(100)
local function RaiseAppearanceBuddyDropdownLayers()
    for i = 1, 2 do
        local dropdown = _G["DropDownList" .. i]
        if dropdown then
            dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
            dropdown:SetFrameLevel(220 + i)
            if dropdown.SetToplevel then dropdown:SetToplevel(true) end
            if dropdown:IsShown() and dropdown.Raise then dropdown:Raise() end
        end
    end
end

if type(hooksecurefunc) == "function" and type(ToggleDropDownMenu) == "function" then
    hooksecurefunc("ToggleDropDownMenu", function()
        RaiseAppearanceBuddyDropdownLayers()
    end)
end

-- "Hurry up! You must hack the main frame!"
-- <hackerman noises>
table.insert(UISpecialFrames, mainFrame:GetName())
do 
    mainFrame:SetWidth(1045)
    mainFrame:SetHeight(505)
    mainFrame:SetPoint("CENTER")
    mainFrame:Hide()
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not IsWindowLocked() then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetScript("OnMouseDown", function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(100)
        self:Raise()
        RaiseAppearanceBuddyDropdownLayers()
    end)
    -- Central sound helper — respects the muteUISounds setting.
    ns.PlayUISound = function(soundId)
        if not GetSettings().muteUISounds then
            PlaySound(soundId)
        end
    end

    mainFrame:SetScript("OnShow", function()
        mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        mainFrame:SetFrameLevel(100)
        mainFrame:Raise()
        RaiseAppearanceBuddyDropdownLayers()
        ns.PlayUISound("igCharacterInfoOpen")
        if _G["TempEnchant1"] then _G["TempEnchant1"]:Hide() end
        if _G["TempEnchant2"] then _G["TempEnchant2"]:Hide() end
    end)
    mainFrame:SetScript("OnHide", function()
        ns.PlayUISound("igCharacterInfoClose")
        if _G["TempEnchant1"] then _G["TempEnchant1"]:Show() end
        if _G["TempEnchant2"] then _G["TempEnchant2"]:Show() end
        if mainFrame.selectedSlot then mainFrame.selectedSlot:UnlockHighlight() end
    end)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -9)
    title:SetText(mainFrameTitle)
    mainFrame.titleText = title  -- exposed so applyAlternativeWindowAppearance can recolor it

    local logo = mainFrame:CreateTexture(nil, "OVERLAY")
    logo:SetTexture("Interface\\AddOns\\AppearanceBuddy\\images\\logo")
    logo:SetSize(45, 45)
    logo:SetPoint("TOPLEFT", 10, -26)

    -- Invisible clickable button over the logo: click to open the GitHub
    -- project page in a copyable popup (WoW cannot launch a browser directly).
    local logoButton = CreateFrame("Button", nil, mainFrame)
    logoButton:SetAllPoints(logo)
    logoButton:SetFrameLevel(mainFrame:GetFrameLevel() + 10)
    local GITHUB_URL = "https://github.com/Doodihealz/AppearanceBuddy-Transmog-System"
    if not StaticPopupDialogs["APPEARANCEBUDDY_GITHUB_URL"] then
        StaticPopupDialogs["APPEARANCEBUDDY_GITHUB_URL"] = {
            -- Padded text expands the dialog naturally so the editbox below
            -- (sized to fit the URL) doesn't overflow the popup borders.
            text = "AppearanceBuddy on GitHub\n(Ctrl+C to copy)",
            button1 = OKAY,
            hasEditBox = true,
            editBoxWidth = 260,
            OnShow = function(self)
                self.editBox:SetWidth(260)
                self.editBox:SetText(GITHUB_URL)
                self.editBox:SetCursorPosition(0)
                self.editBox:HighlightText()
                self.editBox:SetFocus()
            end,
            OnAccept = function() end,
            EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
            EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    logoButton:SetScript("OnClick", function()
        StaticPopup_Show("APPEARANCEBUDDY_GITHUB_URL")
    end)
    logoButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("AppearanceBuddy")
        GameTooltip:AddLine(ABL("Click to view the GitHub page"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    logoButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mainFrame.logoButton = logoButton

    local titleBg = mainFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")
	titleBg:SetPoint("TOPLEFT", 10, -7)
    titleBg:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -28, -24)

	local menuBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    menuBg:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
    menuBg:SetTexCoord(0, 1, 0, 0.8125) 
	menuBg:SetPoint("TOPLEFT", 10, -26)
    menuBg:SetPoint("RIGHT", -6, 0)
    menuBg:SetHeight(48)
    menuBg:SetVertexColor(0.5, 0.5, 0.5)

    local frameBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    frameBg:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
    frameBg:SetTexCoord(0, 0.5, 0, 0.8125) 
    frameBg:SetPoint("TOPLEFT", menuBg, "BOTTOMLEFT")
    frameBg:SetPoint("TOPRIGHT", menuBg, "BOTTOMRIGHT")
    frameBg:SetPoint("BOTTOM", 0, 5)
    frameBg:SetVertexColor(0.25, 0.25, 0.25)
	
	local topLeft = mainFrame:CreateTexture(nil, "BORDER")
    topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    topLeft:SetTexCoord(0.5, 0.625, 0, 1)
	topLeft:SetWidth(64)
	topLeft:SetHeight(64)
	topLeft:SetPoint("TOPLEFT")
	
	local topRight = mainFrame:CreateTexture(nil, "BORDER")
    topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    topRight:SetTexCoord(0.625, 0.75, 0, 1)
	topRight:SetWidth(64)
	topRight:SetHeight(64)
    topRight:SetPoint("TOPRIGHT")
	
	local top = mainFrame:CreateTexture(nil, "BORDER")
    top:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    top:SetTexCoord(0.25, 0.37, 0, 1)
	top:SetPoint("TOPLEFT", topLeft, "TOPRIGHT")
    top:SetPoint("TOPRIGHT", topRight, "TOPLEFT")

    local menuSeparatorLeft = mainFrame:CreateTexture(nil, "BORDER")
    menuSeparatorLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    menuSeparatorLeft:SetTexCoord(0.5, 0.5546875, 0.25, 0.53125)
	menuSeparatorLeft:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT")
    menuSeparatorLeft:SetWidth(28)
    menuSeparatorLeft:SetHeight(18)

    local menuSeparatorRight = mainFrame:CreateTexture(nil, "BORDER")
    menuSeparatorRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    menuSeparatorRight:SetTexCoord(0.7109375, 0.75, 0.25, 0.53125)
	menuSeparatorRight:SetPoint("TOPRIGHT", topRight, "BOTTOMRIGHT")
    menuSeparatorRight:SetWidth(20)
    menuSeparatorRight:SetHeight(18)

    local menuSeparatorCenter = mainFrame:CreateTexture(nil, "BORDER")
    menuSeparatorCenter:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    menuSeparatorCenter:SetTexCoord(0.564453125, 0.671875, 0.25, 0.53125)
    menuSeparatorCenter:SetPoint("TOPLEFT", menuSeparatorLeft, "TOPRIGHT")
    menuSeparatorCenter:SetPoint("BOTTOMRIGHT", menuSeparatorRight, "BOTTOMLEFT")

    local botLeft = mainFrame:CreateTexture(nil, "BORDER")
    botLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    botLeft:SetTexCoord(0.75, 0.875, 0, 1)
	botLeft:SetPoint("BOTTOMLEFT")
    botLeft:SetWidth(64)
    botLeft:SetHeight(64)

    local left = mainFrame:CreateTexture(nil, "BORDER")
    left:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    left:SetTexCoord(0, 0.125, 0, 1)
    left:SetPoint("TOPLEFT", menuSeparatorLeft, "BOTTOMLEFT")
    left:SetPoint("BOTTOMRIGHT", botLeft, "TOPRIGHT")

    local botRight = mainFrame:CreateTexture(nil, "BORDER")
    botRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    botRight:SetTexCoord(0.875, 1, 0, 1)
	botRight:SetPoint("BOTTOMRIGHT")
    botRight:SetWidth(64)
    botRight:SetHeight(64)

    local right = mainFrame:CreateTexture(nil, "BORDER")
    right:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    right:SetTexCoord(0.125, 0.25, 0, 1)
    right:SetPoint("TOPRIGHT", menuSeparatorRight, "BOTTOMRIGHT", 4, 0)
    right:SetPoint("BOTTOMLEFT", botRight, "TOPLEFT", 4, 0)

    local bot = mainFrame:CreateTexture(nil, "BORDER")
    bot:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    bot:SetTexCoord(0.38, 0.45, 0, 1)
    bot:SetPoint("BOTTOMLEFT", botLeft, "BOTTOMRIGHT")
    bot:SetPoint("TOPRIGHT", botRight, "TOPLEFT")

    -- separatorV (vertical centre divider) intentionally omitted –
    -- the Settings tab uses the full width.
    
    mainFrame.stats = CreateFrame("Frame", nil, mainFrame)
    mainFrame.stats:SetFrameLevel(1)
    local stats = mainFrame.stats
    stats:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	    tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 }
    })
    stats:SetBackdropColor(0.12, 0.12, 0.12)
    stats:SetBackdropBorderColor(0.25, 0.25, 0.25)
    stats:SetPoint("BOTTOMLEFT", 410, 8)
    stats:SetPoint("BOTTOMRIGHT", -6, 8)
    stats:SetHeight(24)

    mainFrame.buttons = {}

    local function UpdateWindowLockState()
        local locked = IsWindowLocked()
        mainFrame:SetMovable(not locked)
        if locked then
            mainFrame:StopMovingOrSizing()
        end
    end

	local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
    close:SetScript("OnClick", function(self)
        self:GetParent():Hide()
    end)

    -- Gold X close-button skin, applied only when alt mode is on.
    -- Capture vanilla state up front so we can restore it cleanly.
    do
        local BTN_TEX = "Interface\\AddOns\\AppearanceBuddy\\images\\Button.tga"
        local origW, origH = close:GetSize()
        local origNormal   = close:GetNormalTexture()   and close:GetNormalTexture():GetTexture()
        local origPushed   = close:GetPushedTexture()   and close:GetPushedTexture():GetTexture()
        local origDisabled = close:GetDisabledTexture() and close:GetDisabledTexture():GetTexture()
        local origHighlight= close:GetHighlightTexture()and close:GetHighlightTexture():GetTexture()

        local label = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER", close, "CENTER", 0, 0)
        label:SetText("X")
        label:SetTextColor(1, 1, 1, 1)
        label:Hide()

        local function applyGold()
            close:SetSize(20, 20)
            close:SetNormalTexture(BTN_TEX)
            close:SetPushedTexture(BTN_TEX)
            close:SetDisabledTexture(BTN_TEX)
            close:SetHighlightTexture("")
            local n = close:GetNormalTexture();   if n then n:SetAllPoints(close) end
            local p = close:GetPushedTexture();   if p then p:SetAllPoints(close); p:SetVertexColor(0.75, 0.70, 0.55, 1) end
            local d = close:GetDisabledTexture(); if d then d:SetAllPoints(close); d:SetDesaturated(true); d:SetVertexColor(0.55, 0.55, 0.55, 1) end
            label:Show()
        end

        local function restoreVanilla()
            close:SetSize(origW, origH)
            close:SetNormalTexture(origNormal)
            close:SetPushedTexture(origPushed)
            close:SetDisabledTexture(origDisabled)
            close:SetHighlightTexture(origHighlight or "Interface\\Buttons\\UI-Common-MouseHilight")
            label:Hide()
        end

        close.abApplyGold     = applyGold
        close.abRestoreVanilla= restoreVanilla
    end

    mainFrame.buttons.close = close
    mainFrame.UpdateWindowLockState = UpdateWindowLockState
    UpdateWindowLockState()
end


mainFrame.dressingRoom = ns.CreateDressingRoom(nil, mainFrame)

do
    local dr = mainFrame.dressingRoom
    dr:SetPoint("TOPLEFT", 10, -74)
    dr:SetSize(400, 400)

    local border = CreateFrame("Frame", nil, dr)
    border:SetAllPoints()
    border:SetBackdrop(dressingRoomBorderBackdrop)
    border:SetBackdropColor(0, 0, 0, 0)
    mainFrame.dressingRoomBorder = border

    -- Alternative-appearance border overlay: hidden by default, toggled on
    -- when the alternativeWindowAppearance setting is enabled.
    local altBorder = border:CreateTexture(nil, "OVERLAY")
    altBorder:SetTexture("Interface\\AddOns\\AppearanceBuddy\\images\\LeftPreviewBorder.tga")
    -- Hug the outer edge of the race background. Each side independent so
    -- you can fit the gold flush without overlapping the action buttons.
    local BORDER_PAD_X      = 17
    local BORDER_PAD_TOP    = 31
    local BORDER_PAD_BOTTOM = 28
    altBorder:SetPoint("TOPLEFT",     border, "TOPLEFT",     -BORDER_PAD_X,  BORDER_PAD_TOP)
    altBorder:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT",  BORDER_PAD_X, -BORDER_PAD_BOTTOM)
    altBorder:Hide()
    mainFrame.dressingRoomAltBorder = altBorder
    -- Register so applyAlternativeWindowAppearance toggles all known borders.
    ns.altBorders = ns.altBorders or {}
    table.insert(ns.altBorders, altBorder)

    dr.backgroundTextures = {}
    for s in ("human,nightelf,dwarf,gnome,draenei,orc,scourge,tauren,troll,bloodelf,deathknight"):gmatch("%w+") do
        dr.backgroundTextures[s] = dr:CreateTexture(nil, "BACKGROUND")
        dr.backgroundTextures[s]:SetTexture("Interface\\AddOns\\AppearanceBuddy\\images\\"..s)
        dr.backgroundTextures[s]:SetAllPoints()
        dr.backgroundTextures[s]:Hide()
    end
    dr.backgroundTextures["color"] = dr:CreateTexture(nil, "BACKGROUND")
    dr.backgroundTextures["color"]:SetAllPoints()
    dr.backgroundTextures["color"]:SetTexture(1, 1, 1)
    dr.backgroundTextures["color"]:Hide()

    local tip = dr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tip:SetPoint("BOTTOM", dr, "TOP", 0, 12)
    tip:SetJustifyH("CENTER")
    tip:SetJustifyV("BOTTOM")
    tip:SetText(ABL("\124cff00ff00Left Mouse:\124r rotate \124 \124cff00ff00Right Mouse:\124r pan\124n\124cff00ff00Wheel\124r or \124cff00ff00Alt + Right Mouse:\124r zoom"))

    -- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
    local defaultLight = {1, 0, 0, 1, 0, 1, 0.7, 0.7, 0.7, 1, 0.8, 0.8, 0.64}
    local shadowformLight = {1, 0, 0, 1, 0, 1, 0.16, 0, 0.23, 0}
    local shadowformAlpha = 0.75

    dr.shadowformEnabled = false

    dr.EnableShadowform = function(self)
        self:SetLight(unpack(shadowformLight))
        self:SetModelAlpha(shadowformAlpha)
        self.shadowformEnabled = true
    end

    dr.DisableShadowform = function(self)
        self:SetLight(unpack(defaultLight))
        self:SetModelAlpha(1)
        self.shadowformEnabled = false
    end
end

-- Button skin: swap UIPanelButtonTemplate2 textures with gold Button.tga
-- only while alt mode is on. Vanilla red textures restore when alt is off.
do
    local BTN_TEX = "Interface\\AddOns\\AppearanceBuddy\\images\\Button.tga"
    local skinnedButtons = {}

    local function getTexFile(tex)
        return tex and tex.GetTexture and tex:GetTexture() or nil
    end

    function ns.SkinButton(btn)
        if not btn or btn._abSkinApplied then return end
        btn._abSkinApplied = true

        -- Capture vanilla template texture regions and their alpha so we can
        -- restore them when alt mode is turned off.
        local regionAlphas = {}
        for _, region in ipairs({btn:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then
                regionAlphas[region] = region:GetAlpha()
            end
        end

        btn._abOrig = {
            normal     = getTexFile(btn:GetNormalTexture()),
            pushed     = getTexFile(btn:GetPushedTexture()),
            disabled   = getTexFile(btn:GetDisabledTexture()),
            highlight  = getTexFile(btn:GetHighlightTexture()),
            regions    = regionAlphas,
        }

        table.insert(skinnedButtons, btn)
    end

    local function applyGold(btn)
        -- Hide vanilla template texture regions
        for region in pairs(btn._abOrig.regions) do
            region:SetAlpha(0)
        end
        btn:SetNormalTexture(BTN_TEX)
        local n = btn:GetNormalTexture(); if n then n:SetAllPoints(btn) end
        btn:SetPushedTexture(BTN_TEX)
        local p = btn:GetPushedTexture(); if p then p:SetAllPoints(btn); p:SetVertexColor(0.75, 0.70, 0.55, 1) end
        btn:SetHighlightTexture("")
        btn:SetDisabledTexture(BTN_TEX)
        local d = btn:GetDisabledTexture(); if d then d:SetAllPoints(btn); d:SetDesaturated(true); d:SetVertexColor(0.55, 0.55, 0.55, 1) end
        local fs = btn:GetFontString()
        if fs then fs:SetDrawLayer("OVERLAY", 1); fs:SetTextColor(1, 1, 1, 1) end
    end

    local function restoreVanilla(btn)
        for region, alpha in pairs(btn._abOrig.regions) do
            region:SetAlpha(alpha)
        end
        btn:SetNormalTexture(btn._abOrig.normal)
        btn:SetPushedTexture(btn._abOrig.pushed)
        btn:SetDisabledTexture(btn._abOrig.disabled)
        btn:SetHighlightTexture(btn._abOrig.highlight or "Interface\\Buttons\\UI-Common-MouseHilight")
        local fs = btn:GetFontString()
        if fs then fs:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1) end
    end

    function ns.SetButtonSkinEnabled(on)
        for _, btn in ipairs(skinnedButtons) do
            if on then applyGold(btn) else restoreVanilla(btn) end
        end
    end
end

mainFrame.buttons.send = CreateFrame("Button", "$parentButtonSend", mainFrame, "UIPanelButtonTemplate2")

do
    StaticPopupDialogs["APPEARANCE_BUDDY_SEND_DIALOG"] = {
        text = "|cffffd700Enter player name:",
        button1 = "Send",
        button2 = CLOSE,
        timeout = 0,
        whileDead = true,
        hasEditBox = true,
        preferredIndex = 3,
        OnAccept = function(self)
            local playerName = self.editBox:GetText()
            if playerName ~= "" then
                local slots = mainFrame.slots
                local parts = {}
                local itemsCount = 0
                for i = 1, #slotOrder do
                    local slot = slots[slotOrder[i]]
                    if slot and slot.itemId ~= nil then
                        parts[i] = tostring(slot.itemId)
                        itemsCount = itemsCount + 1
                    else
                        parts[i] = ""
                    end
                end
                if itemsCount > 0 then
                    SendAddonMessage(addonMessagePrefix, table.concat(parts, ":"), "WHISPER", playerName)
                else
                    SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: nothing to send.")
                end
            end
        end,
        OnShow = function(self)
            self.editBox:SetText("")
        end,}
    local btn = mainFrame.buttons.send
    btn:SetPoint("TOPRIGHT", mainFrame.dressingRoom, "BOTTOMRIGHT")
    btn:SetPoint("BOTTOM", mainFrame.stats, "BOTTOM", 0, 1)
    btn:SetWidth(mainFrame.dressingRoom:GetWidth()/4)
    btn:SetText(ABL("Send"))
    btn:SetScript("OnClick", function()
        StaticPopup_Show("APPEARANCE_BUDDY_SEND_DIALOG")
        ns.PlayUISound("gsTitleOptionOK")
    end)
end

mainFrame.buttons.reset = CreateFrame("Button", "$parentButtonReset", mainFrame, "UIPanelButtonTemplate2")

do
    local btn = mainFrame.buttons.reset
    btn:SetPoint("TOPRIGHT", mainFrame.buttons.send, "TOPLEFT")
    btn:SetWidth(mainFrame.buttons.send:GetWidth())
    btn:SetText(ABL("Reset"))
    btn:SetScript("OnClick", function()
        mainFrame.dressingRoom:Reset()
        ns.PlayUISound("gsTitleOptionOK")
    end)
end

mainFrame.buttons.undress = CreateFrame("Button", "$parentButtonUndress", mainFrame, "UIPanelButtonTemplate2")

do
    local btn = mainFrame.buttons.undress
    btn:SetPoint("TOPRIGHT", mainFrame.buttons.reset, "TOPLEFT")
    btn:SetPoint("BOTTOMRIGHT", mainFrame.buttons.reset, "BOTTOMLEFT")
    btn:SetWidth(mainFrame.buttons.reset:GetWidth())
    btn:SetText(ABL("Undress"))
    btn:SetScript("OnClick", function()
        mainFrame.dressingRoom:Undress()
        ns.PlayUISound("gsTitleOptionOK")
    end)
end

mainFrame.buttons.useTarget = CreateFrame("Button", "$parentButtonUseTarget", mainFrame, "UIPanelButtonTemplate2")

do
    local btn = mainFrame.buttons.useTarget
    btn:SetPoint("TOPRIGHT", mainFrame.buttons.undress, "TOPLEFT")
    btn:SetWidth(mainFrame.buttons.undress:GetWidth())
    btn:SetText(ABL("Use Target"))
    btn:SetScript("OnClick", function()
        mainFrame.dressingRoom:SetUnit("target")
        ns.PlayUISound("gsTitleOptionOK")
    end)
    -- Skin all 4 dressing-room action buttons
    for _, key in ipairs({"send", "reset", "undress", "useTarget"}) do
        ns.SkinButton(mainFrame.buttons[key])
    end
    btn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(ABL("Use target player's model."))
        GameTooltip:AddLine(ABL("The target must be in range of inspection."), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

---------------- TABS ----------------

local TAB_NAMES = {ABL("Transmog"), ABL("Settings")}

mainFrame.tabs = {}

do
    local tabs = {}

    local function tab_OnClick(self)
        local selectedTab = PanelTemplates_GetSelectedTab(self:GetParent())
        local tab = tabs[selectedTab]
        if tab ~= nil then
            tab:Hide()
        end
        PanelTemplates_SetTab(self:GetParent(), self:GetID())
        tabs[self:GetID()]:Show()
        ns.PlayUISound("gsTitleOptionOK")
    end

    for i = 1, #TAB_NAMES do
        mainFrame.buttons["tab"..i] = CreateFrame("Button", "$parentTab"..i, mainFrame, "OptionsFrameTabButtonTemplate")
        local btn = mainFrame.buttons["tab"..i]
        btn:SetText(TAB_NAMES[i])
        btn:SetID(i)
        if i == 1 then
            btn:SetPoint("BOTTOMLEFT", btn:GetParent(), "TOPLEFT", 410, -70)
        else
            btn:SetPoint("LEFT", _G[mainFrame:GetName().."Tab"..(i - 1)], "RIGHT")
        end
        btn:SetScript("OnClick", tab_OnClick)

        local frame = CreateFrame("Frame", "$parentTab"..i.."Content", mainFrame)
        frame:SetPoint("TOPLEFT", 410, -73)
        frame:SetPoint("BOTTOMRIGHT", -8, 4)
        frame:Hide()
        table.insert(tabs, frame)
    end
    
    PanelTemplates_SetNumTabs(mainFrame, #TAB_NAMES)
    tab_OnClick(_G[mainFrame:GetName().."Tab1"])

    mainFrame.tabs.transmog = tabs[1]
    mainFrame.tabs.settings = tabs[2]

    -- The settings tab spans the full window width (no dressing-room panel on the left).
    mainFrame.tabs.settings:ClearAllPoints()
    mainFrame.tabs.settings:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     8,  -73)
    mainFrame.tabs.settings:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -8,  4)
end

---------------- SLOTS ----------------

mainFrame.slots = {}
mainFrame.selectedSlot = nil

local function slot_OnShiftLeftClick(self)
    if self.itemId ~= nil then
        local _, link = GetItemInfo(self.itemId)
        if link ~= nil then
            SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: "..link.." ("..self.itemId..")")
        else
            SELECTED_CHAT_FRAME:AddMessage("|ccff6ff98<AppearanceBuddy>|r: It seems this item cannot be used for transmogrification.")
        end
    end
end

local function getIndex(array, value)
    for i = 1, #array do
        if array[i] == value then
            return i    
        end
    end
    return nil
end

local function slot_OnControlLeftClick(self)
    if self.itemId ~= nil then
        ns.ShowWowheadURLDialog(self.itemId)
    end
end


local function slot_OnLeftClick(self)
    local selectedSlot = mainFrame.selectedSlot
    if selectedSlot ~= nil then
        selectedSlot:UnlockHighlight()
    end
    mainFrame.selectedSlot = self
    -- ReTryOn weapon so the model displays the weapon of the clicked (selected) slot.
    -- Direct equality avoids allocating a fresh 3-element table on every slot click.
    if self.itemId ~= nil and (self.slotName == mainHandSlot or self.slotName == offHandSlot or self.slotName == rangedSlot) then
        mainFrame.dressingRoom:TryOn(self.itemId)
    end
    self:LockHighlight()
end

local function slot_OnRightClick(self)
    self:RemoveItem()
end

local function slot_OnClick(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            slot_OnShiftLeftClick(self)
        elseif IsControlKeyDown() then
            slot_OnControlLeftClick(self)
        else
            slot_OnLeftClick(self)
        end
        PlaySound("gsTitleOptionOK")
    elseif button == "RightButton" then
        slot_OnRightClick(self)
    end
end

local function slot_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.itemId == nil then
        GameTooltip:AddLine(self.slotName)
    else
        local _, link = GetItemInfo(self.itemId)
        if link then
            GameTooltip:SetHyperlink(link)
        else
            GameTooltip:AddLine(self.slotName)
            GameTooltip:AddLine(ABL("Loading..."), 0.7, 0.7, 0.7)
        end
        if GetSettings().showShortcutsInTooltip then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00Shift + Left Click:|r create a hyperlink for the item.")
            GameTooltip:AddLine("|cff00ff00Right Click:|r undress the slot.")
            GameTooltip:AddLine("|cff00ff00Ctrl + Left Click:|r create a Wowhead URL for the item.")
        end
    end
    GameTooltip:Show()
end

local function slot_OnLeave(self)
    GameTooltip:Hide()
end

local slotNameRemap = {
    [mainHandSlot] = "MainHand",
    [offHandSlot]  = "SecondaryHand",
    [rangedSlot]   = "Ranged",
    [backSlot]     = "Back",
}

local function slot_Reset(self)
    local characterSlotName = slotNameRemap[self.slotName] or self.slotName
    local slotId = GetInventorySlotInfo(characterSlotName.."Slot")
    local itemId = GetInventoryItemID("player", slotId)
    local name = GetItemInfo(itemId ~= nil and itemId or 0)
    if name ~= nil then
        self:SetItem(itemId)
    else
        self:RemoveItem()
    end
end

local function slot_RemoveItem(self)
    if self.itemId ~= nil then
        self.itemId = nil
        self.textures.empty:Show()
        self.textures.item:Hide()
        self:GetScript("OnEnter")(self)
        --[[ We cannot undress a specific slot
        of a DressUpModel in WotLK. Instead,
        we're undressing the whole model and
        dressing it up again without the slot. ]]
        -- We cannot undress a specific slot of a DressUpModel in WotLK.
        -- Instead, undress the whole model and re-dress without this slot.
        --
        -- IMPORTANT: iterate via the canonical `slotOrder` (ipairs), NOT
        -- pairs(mainFrame.slots).  See note above tryOnFromSlots about the
        -- DressUpModel weapon-routing quirk: pairs() returns slots in
        -- arbitrary order and routinely caused only one of two equipped 1H
        -- weapons to render after Undress + TryOn.
        mainFrame.dressingRoom:Undress()
        for _, slotName in ipairs(slotOrder) do
            local slot = mainFrame.slots[slotName]
            if slot and slot.itemId ~= nil then
                mainFrame.dressingRoom:TryOn(slot.itemId)
            end
        end
    end
end

-- Set of slot names that map to weapon bones in the model.  Used to detect
-- when a slot's TryOn must be re-applied in canonical MH → OH → Ranged
-- order to work around the WoW DressUpModel weapon-routing quirk (see notes
-- above tryOnFromSlots).
local WEAPON_SLOT_NAMES = {
    [mainHandSlot] = true,
    [offHandSlot]  = true,
    [rangedSlot]   = true,
}
-- Canonical TryOn order for the three weapon slots.  MH MUST be applied
-- before OH so that an INVTYPE_WEAPON OH item routes to the off-hand bone
-- (engine: "MH empty → INVTYPE_WEAPON goes to MH; MH occupied → INVTYPE_WEAPON
-- goes to OH").  Without a fixed order the second weapon to load from the
-- item cache silently evicted the first — producing the "only 1 weapon shows"
-- bug at login.
local WEAPON_SLOT_ORDER = { mainHandSlot, offHandSlot, rangedSlot }

-- Re-applies all three weapon slots' items in canonical order.  Cheap (3
-- TryOn calls); safe to call from any per-slot callback that just resolved
-- a weapon item, because the LAST call deterministically lands the model in
-- a state where every loaded weapon is on the correct bone.
local function reapplyWeaponSlotsInOrder()
    for _, name in ipairs(WEAPON_SLOT_ORDER) do
        local s = mainFrame.slots and mainFrame.slots[name]
        if s and s.itemId ~= nil then
            mainFrame.dressingRoom:TryOn(s.itemId)
        end
    end
end

local slot_SetItem_pendingRefresh = false

local function slot_SetItem(self, itemId)
    self.itemId = itemId
    ns.QueryItem(itemId, function(queriedItemId, success)
        if queriedItemId == self.itemId and success then
            local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(queriedItemId)
            self.textures.empty:Hide()
            self.textures.item:SetTexture(texture)
            self.textures.item:Show()
            -- Always TryOn so the character is dressed in real gear.
            -- If the transmog tab is active and already synced, also schedule
            -- a single debounced updatePreviewModel call on the next frame so
            -- that now-cached items allow TryOn(effectiveId) to actually show
            -- the transmog appearance on top of real gear.
            --
            -- For weapon slots, re-apply ALL three weapon slots in canonical
            -- MH → OH → Ranged order instead of just TryOn-ing this one item.
            -- DressUpModel:TryOn(INVTYPE_WEAPON) routes the item to the MH
            -- bone when MH is empty and to the OH bone when MH is occupied.
            -- QueryItem callbacks fire in item-cache load order (effectively
            -- random), so a naive per-slot TryOn would race — the second
            -- weapon to load could land in MH and evict the first, leaving
            -- only one weapon visible.  Re-applying all three weapons each
            -- time a weapon callback resolves makes the final state
            -- deterministic regardless of cache-load order.
            if WEAPON_SLOT_NAMES[self.slotName] then
                reapplyWeaponSlotsInOrder()
            else
                mainFrame.dressingRoom:TryOn(queriedItemId)
            end
            local transmogTabActive = mainFrame.tabs
                and mainFrame.tabs.transmog
                and mainFrame.tabs.transmog:IsShown()
            if transmogTabActive and ns.IsTransmogSynced and ns.IsTransmogSynced() then
                if not slot_SetItem_pendingRefresh then
                    slot_SetItem_pendingRefresh = true
                    local f = CreateFrame("Frame")
                    f:SetScript("OnUpdate", function(self)
                        self:SetScript("OnUpdate", nil)
                        slot_SetItem_pendingRefresh = false
                        if ns.RefreshTransmogPreview then
                            ns.RefreshTransmogPreview()
                        end
                    end)
                end
            end
        end
    end)
end

--------- Slot building

do
    for slotName, texturePath in pairs(slotTextures) do
        local slot = CreateFrame("Button", "$parentSlot"..slotName, mainFrame, "ItemButtonTemplate")
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        slot:SetFrameLevel(mainFrame.dressingRoom:GetFrameLevel() + 1)
        slot:SetScript("OnClick", slot_OnClick)
        slot:SetScript("OnEnter", slot_OnEnter)
        slot:SetScript("OnLeave", slot_OnLeave)
        slot:GetHighlightTexture():SetAllPoints()  -- cover full icon (template default is 36x36 on 37x37 button)
        slot.slotName = slotName
        mainFrame.slots[slotName] = slot
        slot.textures = {}
        slot.textures.empty = slot:CreateTexture(nil, "BACKGROUND")
        slot.textures.empty:SetTexture(texturePath)
        slot.textures.empty:SetAllPoints()
        slot.textures.item = slot:CreateTexture(nil, "BACKGROUND")
        slot.textures.item:SetAllPoints()
        slot.textures.item:Hide()
        slot.Reset = slot_Reset
        slot.SetItem = slot_SetItem
        slot.RemoveItem = slot_RemoveItem
    end

    local slots = mainFrame.slots
    slots["Head"]:SetPoint("TOPLEFT", mainFrame.dressingRoom, "TOPLEFT", 16, -16)
    slots["Shoulder"]:SetPoint("TOP", slots["Head"], "BOTTOM", 0, -4)
    slots["Back"]:SetPoint("TOP", slots["Shoulder"], "BOTTOM", 0, -4)
    slots["Chest"]:SetPoint("TOP", slots["Back"], "BOTTOM", 0, -4)
    slots["Shirt"]:SetPoint("TOP", slots["Chest"], "BOTTOM", 0, -36)
    slots["Tabard"]:SetPoint("TOP", slots["Shirt"], "BOTTOM", 0, -4)
    slots["Wrist"]:SetPoint("TOP", slots["Tabard"], "BOTTOM", 0, -36)
    slots["Hands"]:SetPoint("TOPRIGHT", mainFrame.dressingRoom, "TOPRIGHT", -16, -16)
    slots["Waist"]:SetPoint("TOP", slots["Hands"], "BOTTOM", 0, -4)
    slots["Legs"]:SetPoint("TOP", slots["Waist"], "BOTTOM", 0, -4)
    slots["Feet"]:SetPoint("TOP", slots["Legs"], "BOTTOM", 0, -4)
    slots["Off-hand"]:SetPoint("BOTTOM", mainFrame.dressingRoom, "BOTTOM", 0, 16)
    slots["Main Hand"]:SetPoint("RIGHT", slots["Off-hand"], "LEFT", -4, 0)
    slots["Ranged"]:SetPoint("LEFT", slots["Off-hand"], "RIGHT", 4, 0)
end

------- Tricks and hooks with slots and provided appearances. -------


local function btnReset_Hook()
    mainFrame.dressingRoom:Undress()
    -- Iterate via slotOrder (ipairs) so weapon slots are reset in canonical
    -- MH -> OH -> Ranged order.  See note above tryOnFromSlots: each slot:Reset
    -- triggers an async TryOn via the item-cache callback, and pairs() order
    -- previously caused the OH 1H weapon's TryOn to land before the MH's,
    -- making one of the two weapons disappear from the model.
    for _, slotName in ipairs(slotOrder) do
        local slot = mainFrame.slots[slotName]
        if slot then
            if slot.slotName == rangedSlot and ("DRUIDSHAMANPALADINDEATHKNIGHT"):find(classFileName) then
                slot:RemoveItem()
            else
                slot:Reset()
            end
        end
    end
    if mainFrame.dressingRoom.shadowformEnabled then
        mainFrame.dressingRoom:EnableShadowform()
    end
end

local function btnUndress_Hook()
    for _, slot in pairs(mainFrame.slots) do
        slot.itemId = nil
        slot.textures.empty:Show()
        slot.textures.item:Hide()
    end
end

-- Re-dresses a DressUpModel from the saved slot items.
--
-- WoW 3.3.5 DressUpModel:TryOn() weapon-routing quirk:
--   * INVTYPE_WEAPONMAINHAND  → always main-hand bone.
--   * INVTYPE_WEAPONOFFHAND / INVTYPE_HOLDABLE / INVTYPE_SHIELD → always OH.
--   * INVTYPE_WEAPON (1H, dual-wieldable) → MH bone if MH is empty,
--     OH bone if MH is already occupied.
--   * INVTYPE_RANGED / INVTYPE_RANGEDRIGHT / INVTYPE_THROWN → ranged bone.
--
-- Consequence: if the OH 1H weapon is TryOn-ed BEFORE the MH 1H weapon,
-- the OH item lands in the MH bone first; the subsequent MH TryOn (also
-- INVTYPE_WEAPON) then sees MH occupied and routes the MH item to OH.
-- The two weapons end up swapped — visually surviving — but if anything
-- causes only the SECOND TryOn to land (e.g. the first item is not in the
-- client item cache yet, or the model is mid-Reset), only one weapon
-- renders.  pairs() iteration order is undefined in Lua, so the bug was
-- intermittent and reproduced reliably when the OH item finished caching
-- after the MH item at login.
--
-- Fix: iterate via `slotOrder` (ipairs) so weapons are always applied as
-- Main Hand → Off-hand → Ranged.  This makes the final model state
-- deterministic and prevents the "only 1 weapon shows when loading into
-- AppearanceBuddy" regression.
local function tryOnFromSlots(dressUpModel)
    for _, slotName in ipairs(slotOrder) do
        local slot = mainFrame.slots[slotName]
        if slot and slot.itemId ~= nil then
            dressUpModel:TryOn(slot.itemId)
        end
    end
end

local function refreshDressingRoomFromSlots(unitToken)
    if unitToken ~= nil then
        mainFrame.dressingRoom:SetUnit(unitToken)
    end

    mainFrame.dressingRoom:Undress()
    tryOnFromSlots(mainFrame.dressingRoom)

    if mainFrame.dressingRoom.shadowformEnabled then
        mainFrame.dressingRoom:EnableShadowform()
    end
end

-- Re-TryOn selected appearances since the model resets each time it's shown.
-- Showing/hiding a DressUpModel also breaks the model's positioning.
local function dressingRoom_OnShow(self)
    self:Reset()
    -- Do NOT call Undress() here. Reset() already calls SetUnit("player") which
    -- displays the character with all real equipped gear. Undress() after Reset()
    -- strips that away, leaving the model naked if tryOnFromSlots finds no cached
    -- item IDs (common on first login before items are in the item cache).
    -- tryOnFromSlots() then layers any manually-set slot items on top of the
    -- Reset() base; if slots are empty, real gear from Reset() stays visible.
    tryOnFromSlots(self)
    if self.shadowformEnabled then
        self:EnableShadowform()
    end
end

-- Re-TryOn slot items when the displayed model changes.
mainFrame.buttons.useTarget:HookScript("OnClick", function(_)
    if mainFrame.dressingRoom.shadowformEnabled then
        mainFrame.dressingRoom:EnableShadowform()
    end
    mainFrame.dressingRoom:Undress()
    tryOnFromSlots(mainFrame.dressingRoom)
end)

-- Initialize dressingRoom hooks and slot state on the first time the window opens.
--
-- Previously this was deferred to mainFrame.slots[defaultSlot]:SetScript("OnShow"),
-- but that fires at the WRONG time: the Transmog tab's OnShow hides normal slots
-- (via SetAppearanceBuddyPreviewControlsVisible) before the Head slot's OnShow can
-- fire, so initialization was deferred until the user clicked Settings for the first
-- time (when normal slots become visible again) -- resetting the dressingRoom to real
-- gear and wiping the transmog preview.
--
-- By hooking mainFrame:OnShow instead, init runs when the window first opens, before
-- any children fire their OnShow. The dressingRoom_OnShow hook is in place by the
-- time the dressingRoom fires its own OnShow naturally (as a child of mainFrame), and
-- the Transmog tab's updatePreviewModel then re-applies transmog on top.
do
    local initialized = false
    mainFrame:HookScript("OnShow", function()
        if initialized then return end
        initialized = true
        mainFrame.buttons.reset:HookScript("OnClick", btnReset_Hook)
        mainFrame.dressingRoom:HookScript("OnShow", dressingRoom_OnShow)
        -- dressingRoom_OnShow fires naturally when dressingRoom becomes visible
        -- as a child of mainFrame (no explicit call needed here).
        btnReset_Hook()
        mainFrame.buttons.undress:HookScript("OnClick", btnUndress_Hook)
        mainFrame.slots[defaultSlot]:Click("LeftButton")
    end)
end

---------------- CHARACTER MENU BUTTON ----------------

local btnAppearanceBuddy = CreateFrame("Button", "$parent"..addon.."AppearanceBuddyButton", CharacterModelFrame)
do
    local size = GetSettings().appearanceButtonSize or 40
    btnAppearanceBuddy:SetSize(size, size)
    btnAppearanceBuddy:SetPoint("BOTTOMRIGHT", -2, 24)
    btnAppearanceBuddy:EnableMouse(true)
    btnAppearanceBuddy:RegisterForClicks("LeftButtonUp")

    -- Logo texture fills the button; scales with the button automatically.
    local tex = btnAppearanceBuddy:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\AddOns\\AppearanceBuddy\\images\\logo")
    btnAppearanceBuddy._logoTex = tex

    -- Highlight overlay so the button has hover feedback.
    local hi = btnAppearanceBuddy:CreateTexture(nil, "HIGHLIGHT")
    hi:SetAllPoints()
    hi:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hi:SetBlendMode("ADD")

    btnAppearanceBuddy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("AppearanceBuddy", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    btnAppearanceBuddy:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
btnAppearanceBuddy:SetScript("OnClick", function(self)
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show() 
    end
end)

---------------- SETTINGS TAB ----------------


do  --------- Settings tab UI + backend
    local settingsTab = mainFrame.tabs.settings

    -- -----------------------------------------------------------------------
    -- Backend helpers (used by applySettings and by widget callbacks)
    -- -----------------------------------------------------------------------

    local function applyPreviewSetup(mode)
        GetSettings().previewSetup = mode
        previewSetupVersion = mode
        if mainFrame.selectedSlot ~= nil then
            mainFrame.selectedSlot:Click("LeftButton")
        end
    end

    local function refreshMiniPreviewModels()
        if ns.mainFrame and ns.mainFrame.tabs and ns.mainFrame.tabs.transmog then
            local transmogTab = ns.mainFrame.tabs.transmog
            local list = transmogTab.list
            if list and list.dressingRoomSetup and list.itemIds and #list.itemIds > 0 then
                list:Update()
            end
            local illusionFrame = transmogTab.illusionFrame
            if illusionFrame and illusionFrame:IsShown() then
                if illusionFrame.updateWeaponIcon then illusionFrame.updateWeaponIcon() end
                if illusionFrame.populate then illusionFrame.populate() end
            end
        end
    end

    local function applyMiniPreviewMode(mode)
        mode = mode == "dynamic" and "dynamic" or "static"
        GetSettings().miniPreviewMode = mode
        ns.miniPreviewMode = mode
        refreshMiniPreviewModels()
    end

    local miniMaxZoomSlider, miniMaxZoomValue

    -- Programmatic slider sync must not behave like user input. On the 3.3.5
    -- client, SetValue can fire OnValueChanged; without this, opening the
    -- settings panel can accidentally apply slider callbacks.
    local function SetSliderValueSilently(sliderFrame, value, valueText, valueTextFunc)
        if not sliderFrame then return end
        sliderFrame._abSuppressOnValueChanged = true
        sliderFrame:SetValue(value)
        sliderFrame._abSuppressOnValueChanged = nil
        if valueText and valueTextFunc then
            valueText:SetText(valueTextFunc(value))
        end
    end

    local function clampMiniMaxZoomPercent(value)
        value = math.floor((tonumber(value) or 100) + 0.5)
        if value < 30 then value = 30 end
        if value > 300 then value = 300 end
        return value
    end

    local function getMiniMaxZoomPercent(settings)
        settings = settings or GetSettings()

        -- Migration path for users who installed an intermediate build with the
        -- tangled miniPreviewZoomAdjust / zoom-limit fields. Use the old actual
        -- mini zoom once, then keep the new setting fully independent.
        if settings.miniPreviewMaxZoom == nil and settings.miniPreviewZoomAdjust ~= nil then
            return clampMiniMaxZoomPercent((tonumber(settings.miniPreviewZoomAdjust) or 1.0) * 100)
        end

        return clampMiniMaxZoomPercent((tonumber(settings.miniPreviewMaxZoom) or 1.0) * 100)
    end

    local function applyMiniPreviewMaxZoom(value)
        value = clampMiniMaxZoomPercent(value) / 100
        GetSettings().miniPreviewMaxZoom = value
        ns.miniPreviewMaxZoom = value
        refreshMiniPreviewModels()
    end

    local function applyMiniPreviewPositionAdjust(value)
        value = tonumber(value) or 0.0
        if value < -0.50 then value = -0.50 end
        if value > 0.50 then value = 0.50 end
        GetSettings().miniPreviewPositionAdjust = value
        ns.miniPreviewPositionAdjust = value
        refreshMiniPreviewModels()
    end

    local function applyMiniPreviewVerticalAdjust(value)
        value = tonumber(value) or 0.0
        if value < -0.50 then value = -0.50 end
        if value > 0.50 then value = 0.50 end
        GetSettings().miniPreviewVerticalAdjust = value
        ns.miniPreviewVerticalAdjust = value
        refreshMiniPreviewModels()
    end

    local function applyCharacterBackground(background, r, g, b)
        local textures = mainFrame.dressingRoom.backgroundTextures
        GetSettings().dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] = background
        for _, tex in pairs(textures) do tex:Hide() end
        if textures[background] then textures[background]:Show() end
        if r and textures.color then textures.color:SetTexture(r, g, b) end
        if ns.applyGridBackground and GetSettings().gridBackground then
            ns.applyGridBackground(background ~= "color" and background or nil)
        end
    end

    settingsTab.SetPreviewSetup        = function(self, mode) applyPreviewSetup(mode) end
    settingsTab.SetCharacterBackground = function(self, background, r, g, b) applyCharacterBackground(background, r, g, b) end

    -- -----------------------------------------------------------------------
    -- Alternative Window Appearance — overlay elements created once at load.
    -- applyAlternativeWindowAppearance(on) is called from the checkbox and
    -- from applySettings() on ADDON_LOADED.
    -- -----------------------------------------------------------------------
    local ALT_IMG = "Interface\\AddOns\\AppearanceBuddy\\images\\"

    -- Custom background: ARTWORK layer renders above the default BACKGROUND
    -- textures (frameBg, menuBg, titleBg) but below BORDER chrome.
    local altBg = mainFrame:CreateTexture(nil, "ARTWORK")
    altBg:SetTexture(ALT_IMG .. "Background.tga")
    altBg:SetVertexColor(1, 1, 1, 1)
    -- Adjust these offsets to reposition/scale the background image.
    -- TOPLEFT  (left, top):   negative = move left/up,  positive = move right/down
    -- BOTTOMRIGHT (right, bottom): positive = extend right/up, negative = shrink
    local BG_LEFT   = -18  -- extend left beyond frame edge
    local BG_RIGHT  =  22  -- extend right beyond frame edge
    local BG_TOP    =  16  -- extend up beyond frame edge
    local BG_BOTTOM = -20  -- extend down beyond frame edge
    altBg:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     BG_LEFT,   BG_TOP)
    altBg:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", BG_RIGHT,  BG_BOTTOM)
    altBg:Hide()

    -- Horizontal gold dividers above the chrome (OVERLAY layer).
    local altDivTop = mainFrame:CreateTexture(nil, "OVERLAY")
    altDivTop:SetTexture(ALT_IMG .. "Divider.tga")
    altDivTop:SetVertexColor(1, 1, 1, 1)
    altDivTop:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  10, -68)
    altDivTop:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -6, -68)
    altDivTop:SetHeight(8)
    altDivTop:Hide()

    local altDivBot = mainFrame:CreateTexture(nil, "OVERLAY")
    altDivBot:SetTexture(ALT_IMG .. "Divider.tga")
    altDivBot:SetVertexColor(1, 1, 1, 1)
    altDivBot:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  10, 10)
    altDivBot:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -6, 10)
    altDivBot:SetHeight(8)
    altDivBot:Hide()

    -- Button overlay list – populated lazily on first call to
    -- applyAlternativeWindowAppearance so that Transmog.lua buttons exist.
    local altButtonOverlays = nil

    local function buildButtonOverlays()
        altButtonOverlays = {}
    end

    local function applyAlternativeWindowAppearance(on)
        if not altButtonOverlays then buildButtonOverlays() end
        if on then
            altBg:Show(); altDivTop:Show(); altDivBot:Show()
            if mainFrame.dressingRoomBorder then
                mainFrame.dressingRoomBorder:SetBackdropBorderColor(0, 0, 0, 0)
            end
        else
            altBg:Hide(); altDivTop:Hide(); altDivBot:Hide()
            if mainFrame.dressingRoomBorder then
                mainFrame.dressingRoomBorder:SetBackdropBorderColor(1, 1, 1, 1)
            end
        end
        -- Show/hide all registered alt borders (main DR + Sets preview, etc.)
        if ns.altBorders then
            for _, tex in ipairs(ns.altBorders) do
                if on then tex:Show() else tex:Hide() end
            end
        end
        -- Lift slot buttons above the alt border overlay so they remain
        -- clickable and visually on top of the gold frame art.
        if mainFrame.slots then
            local drLvl = mainFrame.dressingRoom:GetFrameLevel()
            local target = on and (drLvl + 5) or (drLvl + 1)
            for _, slot in pairs(mainFrame.slots) do
                slot:SetFrameLevel(target)
            end
        end
        if ns.SetButtonSkinEnabled then ns.SetButtonSkinEnabled(on) end
        -- Title: gold palette in alt mode, normal palette otherwise.
        if mainFrame.titleText then
            mainFrame.titleText:SetText(on and mainFrameTitleAlt or mainFrameTitle)
        end
        -- Close button: gold X in alt mode, vanilla red X otherwise.
        local closeBtn = mainFrame.buttons and mainFrame.buttons.close
        if closeBtn then
            if on and closeBtn.abApplyGold then closeBtn.abApplyGold()
            elseif closeBtn.abRestoreVanilla then closeBtn.abRestoreVanilla() end
        end
    end

    -- -----------------------------------------------------------------------
    -- Layout helpers
    -- -----------------------------------------------------------------------
    local PAD_X      = 24
    local COL_W      = 370   -- each column width (two columns side by side)
    local ROW_H      = 26
    local SECTION_H  = 14    -- header label height
    local SECTION_GAP = 10   -- gap before a new section header
    local CB_SIZE    = 24

    -- Tracks next Y offset per column (1 = left, 2 = right)
    local colY = { -16, -16 }
    local colX = { PAD_X, PAD_X + COL_W }

    local function addSectionHeader(col, text)
        colY[col] = colY[col] - SECTION_GAP
        local lbl = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetText("|cffffd700" .. text .. "|r")
        lbl:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", colX[col], colY[col])
        lbl:SetWidth(COL_W - PAD_X)
        lbl:SetJustifyH("LEFT")
        -- underline via thin texture
        local line = settingsTab:CreateTexture(nil, "BACKGROUND")
        line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        line:SetVertexColor(0.4, 0.4, 0.4, 0.8)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -1)
        line:SetWidth(COL_W - PAD_X * 2)
        colY[col] = colY[col] - SECTION_H - 4
    end

    -- Creates a checkbox row and returns the checkbox widget.
    -- tooltipTitle/tooltipBody may be nil to skip tooltip.
    local _cbIdx = 0
    local function addCheckbox(col, labelText, tooltipTitle, tooltipBody, onClick)
        _cbIdx = _cbIdx + 1
        local cbName = "AppearanceBuddySettingsCB" .. _cbIdx
        local cb = CreateFrame("CheckButton", cbName, settingsTab, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", colX[col], colY[col])
        cb:SetScript("OnClick", function(self)
            onClick(self:GetChecked() ~= nil)
        end)
        if tooltipTitle then
            cb:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(tooltipTitle)
                if tooltipBody then GameTooltip:AddLine(tooltipBody, 1, 1, 1, 1, true) end
                GameTooltip:Show()
            end)
            cb:HookScript("OnLeave", function() GameTooltip:Hide() end)
        end
        local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetText(labelText)
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        colY[col] = colY[col] - ROW_H
        return cb
    end

    -- -----------------------------------------------------------------------
    -- LEFT COLUMN — Display & UI
    -- -----------------------------------------------------------------------
    addSectionHeader(1, "Display & UI")

    local cbShowButton = addCheckbox(1,
        'Show "Appearance" button',
        'Show "Appearance" button',
        'Show or hide the "Appearance" button in the character window. The addon is still accessible via /appearancebuddy.',
        function(on)
            GetSettings().showAppearanceBuddyButton = on
            if on then btnAppearanceBuddy:Show() else btnAppearanceBuddy:Hide() end
        end)
    settingsTab.showAppearanceBuddyButtonCheckBox = cbShowButton

    local cbGithubButton = addCheckbox(1,
        "Allow clickable GitHub UI button",
        "Allow clickable GitHub UI button",
        "Enable or disable the clickable GitHub link on the logo in the top-left of the window.",
        function(on)
            GetSettings().showGithubButton = on
            if mainFrame.logoButton then
                if on then
                    mainFrame.logoButton:Show()
                else
                    mainFrame.logoButton:Hide()
                    GameTooltip:Hide()
                end
            end
        end)

    local cbMuteSounds = addCheckbox(1,
        "Mute UI sounds",
        "Mute UI sounds",
        "Silence the open/close and button click sounds played by AppearanceBuddy.",
        function(on)
            GetSettings().muteUISounds = on
        end)

    local cbShortcuts = addCheckbox(1,
        "Show shortcuts in tooltips",
        nil, nil,
        function(on)
            GetSettings().showShortcutsInTooltip = on
        end)
    settingsTab.showShortcutsInTooltipCheckBox = cbShortcuts

    local cbDisplayId = addCheckbox(1,
        "Show Item Display Id in tooltip",
        nil, nil,
        function(on)
            GetSettings().showDisplayIdInTooltip = on
        end)
    settingsTab.showDisplayIdInTooltipCheckBox = cbDisplayId

    local cbItemId = addCheckbox(1,
        "Show Item Id in tooltip",
        "Show Item Id in tooltip",
        "Show the server item ID for the appearance beneath the display ID in the item tooltip.",
        function(on)
            GetSettings().showItemIdInTooltip = on
        end)
    settingsTab.showItemIdInTooltipCheckBox = cbItemId

    local cbTransmogCost = addCheckbox(1,
        "Show transmog cost",
        "Show transmog cost",
        "Display the gold cost for applying transmog changes in the status bar.",
        function(on)
            GetSettings().showTransmogCost = on
        end)
    settingsTab.showTransmogCostCheckBox = cbTransmogCost

    local cbSetChatLinks = addCheckbox(1,
        "Enable set chat links",
        "Enable set chat links",
        "When enabled, the 'Link Set' button posts a clickable [Set Name] hyperlink in chat. Other AppearanceBuddy users can click it to import and preview the set in one step. When disabled, 'Link Set' falls back to the raw share code and incoming set links on your client are ignored.",
        function(on)
            GetSettings().enableSetChatLinks = on
        end)
    settingsTab.enableSetChatLinksCheckBox = cbSetChatLinks

    local cbIgnoreScaling = addCheckbox(1,
        "Ignore UI scaling",
        "Ignore UI scaling",
        "The game's 3D rendering can break correct display of previews with low UI scaling values. Enable this to bypass UI scaling.",
        function(on)
            GetSettings().ignoreUIScaling = on
            if on then
                mainFrame:SetParent(nil)
                mainFrame:SetScale(0.9)
            else
                mainFrame:SetParent(UIParent)
                mainFrame:SetScale(1)
            end
            if mainFrame:IsVisible() then mainFrame:Hide(); mainFrame:Show() end
        end)
    settingsTab.ignoreUIScalingCheckBox = cbIgnoreScaling

    local cbWindowLocked = addCheckbox(1,
        "Lock window position",
        "Lock window",
        "Prevent AppearanceBuddy from being moved.",
        function(on)
            GetSettings().windowLocked = on
            if mainFrame.UpdateWindowLockState then mainFrame.UpdateWindowLockState() end
        end)
    settingsTab.windowLockedCheckBox = cbWindowLocked

    local cbAltAppearance = addCheckbox(1,
        "Alternative Window Appearance",
        "Alternative Window Appearance",
        "Replace the window background, dividers, and action buttons with custom themed artwork. Off by default.",
        function(on)
            GetSettings().alternativeWindowAppearance = on
            applyAlternativeWindowAppearance(on)
        end)

    -- Appearance button size slider
    colY[1] = colY[1] - SECTION_GAP
    local sliderLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sliderLabel:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", colX[1], colY[1])
    sliderLabel:SetText(ABL("Appearance button size:  |cff808080(default: 30 px)|r"))

    local slider = CreateFrame("Slider", "AppearanceBuddyButtonSizeSlider", settingsTab, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", sliderLabel, "BOTTOMLEFT", 0, -8)
    slider:SetWidth(180)
    slider:SetMinMaxValues(20, 80)
    slider:SetValueStep(1)
    local sliderLow  = _G[slider:GetName().."Low"]
    local sliderHigh = _G[slider:GetName().."High"]
    if sliderLow  then sliderLow:SetText("20") end
    if sliderHigh then sliderHigh:SetText("80") end

    local sliderVal = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sliderVal:SetPoint("TOP", slider, "BOTTOM", 0, -2)

    local btnSliderReset = CreateFrame("Button", "AppearanceBuddyButtonSizeSliderReset", settingsTab, "UIPanelButtonTemplate2")
    btnSliderReset:SetSize(60, 20)
    btnSliderReset:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    btnSliderReset:SetText(ABL("Reset"))
    btnSliderReset:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(ABL("Reset to default (30 px)"))
        GameTooltip:Show()
    end)
    btnSliderReset:HookScript("OnLeave", function() GameTooltip:Hide() end)
    btnSliderReset:SetScript("OnClick", function()
        slider:SetValue(30)
    end)

    slider:SetScript("OnValueChanged", function(self, value)
        local sz = math.floor(value + 0.5)
        GetSettings().appearanceButtonSize = sz
        btnAppearanceBuddy:SetSize(sz, sz)
        sliderVal:SetText(sz .. " px")
    end)

    colY[1] = colY[1] - 68   -- account for label + slider + value label + reset btn

    -- -----------------------------------------------------------------------
    -- RIGHT COLUMN — Item Grid & Preview
    -- -----------------------------------------------------------------------
    addSectionHeader(2, "Item Grid & Preview")

    local cbGridBg = addCheckbox(2,
        "Item grid background",
        "Item grid background",
        "Show the race background image inside each item preview cell instead of a plain grey box.",
        function(on)
            GetSettings().gridBackground = on
            if ns.applyGridBackground then
                if on then
                    local bg = GetSettings().dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]:lower()
                    ns.applyGridBackground(bg ~= "color" and bg or nil)
                else
                    ns.applyGridBackground(nil)
                end
            end
        end)
    settingsTab.gridBackgroundCheckBox = cbGridBg

    -- Color swatch to pick the plain-background color used when no race texture is active.
    local cellColorLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cellColorLabel:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", colX[2] + CB_SIZE + 4, colY[2] - 5)
    cellColorLabel:SetText(ABL("Grid border color:"))

    local cellColorSwatch = CreateFrame("Button", "AppearanceBuddyCellColorSwatch", settingsTab)
    cellColorSwatch:SetSize(18, 18)
    cellColorSwatch:SetPoint("LEFT", cellColorLabel, "RIGHT", 8, 0)
    cellColorSwatch:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    cellColorSwatch:SetBackdropColor(0, 0, 0, 0)
    cellColorSwatch:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    -- Use ARTWORK so it renders above the backdrop bgFile layer.
    local cellColorSwatchTex = cellColorSwatch:CreateTexture(nil, "ARTWORK")
    cellColorSwatchTex:SetPoint("TOPLEFT", cellColorSwatch, "TOPLEFT", 2, -2)
    cellColorSwatchTex:SetPoint("BOTTOMRIGHT", cellColorSwatch, "BOTTOMRIGHT", -2, 2)

    local function updateCellColorSwatch()
        local c = GetSettings().miniCellBorderColor or {}
        local r = c[1] or 0.6
        local g = c[2] or 0.52
        local b = c[3] or 0.28
        cellColorSwatchTex:SetTexture(r, g, b)
    end
    updateCellColorSwatch()  -- initialize on creation

    cellColorSwatch:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(ABL("Grid border color"))
        GameTooltip:AddLine(ABL("Click to choose the color of the border lines surrounding each mini preview cell."), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cellColorSwatch:HookScript("OnLeave", function() GameTooltip:Hide() end)

    cellColorSwatch:SetScript("OnClick", function()
        local c = GetSettings().miniCellBorderColor or {}
        local r, g, b = c[1] or 0.6, c[2] or 0.52, c[3] or 0.28
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.previousValues = {r, g, b}
        ColorPickerFrame.func = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            GetSettings().miniCellBorderColor = {nr, ng, nb}
            if ns.applyMiniCellBorderColor then ns.applyMiniCellBorderColor(nr, ng, nb) end
            updateCellColorSwatch()
        end
        ColorPickerFrame.cancelFunc = function(prev)
            local pr = prev and prev[1] or 0.6
            local pg = prev and prev[2] or 0.52
            local pb = prev and prev[3] or 0.28
            GetSettings().miniCellBorderColor = {pr, pg, pb}
            if ns.applyMiniCellBorderColor then ns.applyMiniCellBorderColor(pr, pg, pb) end
            updateCellColorSwatch()
        end
        ShowUIPanel(ColorPickerFrame)
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(400)
        ColorPickerFrame:Raise()
    end)

    local cellColorResetBtn = CreateFrame("Button", "AppearanceBuddyCellColorResetBtn", settingsTab, "UIPanelButtonTemplate2")
    cellColorResetBtn:SetSize(60, 20)
    cellColorResetBtn:SetPoint("LEFT", cellColorSwatch, "RIGHT", 8, 0)
    cellColorResetBtn:SetText(ABL("Reset"))
    cellColorResetBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(ABL("Reset grid border color to default gold"))
        GameTooltip:Show()
    end)
    cellColorResetBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    cellColorResetBtn:SetScript("OnClick", function()
        local dr, dg, db = 0.6, 0.52, 0.28
        GetSettings().miniCellBorderColor = {dr, dg, db}
        if ns.applyMiniCellBorderColor then ns.applyMiniCellBorderColor(dr, dg, db) end
        updateCellColorSwatch()
    end)

    colY[2] = colY[2] - ROW_H

    local cbItemOnly = addCheckbox(2,
        "Bare character view (mini models)",
        "Bare character view",
        "Show the previewed item on a bare, undressed character in the mini views, hiding all other equipped gear.",
        function(on)
            GetSettings().itemOnlyView = on
            ns.itemOnlyView = on
            if ns.mainFrame and ns.mainFrame.tabs and ns.mainFrame.tabs.transmog then
                local list = ns.mainFrame.tabs.transmog.list
                if list and list.dressingRoomSetup and #list.itemIds > 0 then list:Update() end
            end
        end)
    settingsTab.itemOnlyViewCheckBox = cbItemOnly

    local cbShowOffhand = addCheckbox(2,
        "Show equipped off-hand in main hand previews",
        "Show equipped off-hand in main hand previews",
        "When browsing main hand items, also show your equipped off-hand (shield, weapon, etc.) in each mini preview card. Off by default so shields don't clutter the main hand preview.",
        function(on)
            GetSettings().showOffhandInMainhandPreview = on
            ns.showOffhandInMainhandPreview = on
            if ns.mainFrame and ns.mainFrame.tabs and ns.mainFrame.tabs.transmog then
                local list = ns.mainFrame.tabs.transmog.list
                if list and list.dressingRoomSetup and #list.itemIds > 0 then list:Update() end
            end
        end)
    settingsTab.showOffhandInMainhandPreviewCheckBox = cbShowOffhand

    local cbSameType = addCheckbox(2,
        "Smart Filter",
        "Smart Filter",
        "When changing a slot, start with the equipped item's type selected in the Filter menu. You can still change the filter manually.",
        function(on)
            GetSettings().sameTypeFilter = on
            if ns.ApplySameTypeFilterForCurrentSlot then
                ns.ApplySameTypeFilterForCurrentSlot(true)
            end
        end)
    settingsTab.sameTypeFilterCheckBox = cbSameType

    local cbHidePlaceholder = addCheckbox(2,
        "Hide placeholder items",
        "Hide placeholder items",
        "Hide appearances for items with no required level and item level 0 or 1. These are typically debug, placeholder, or removed items.",
        function(on)
            GetSettings().hideNoLevelItems = on
            ns.hideNoLevelItems = on
            if ns.requestCurrentSlotItems then ns.requestCurrentSlotItems(true) end
        end)
    settingsTab.hideNoLevelItemsCheckBox = cbHidePlaceholder

    addSectionHeader(2, "Uncollected Appearances")

    local cbUncollectedBorder = addCheckbox(2,
        "Show uncollected appearance border",
        "Uncollected appearance border",
        "Show a colored border around items whose appearance you have not yet collected.",
        function(on)
            GetSettings().showUncollectedBorder = on
            ns.showUncollectedBorder = on
            if ns.RefreshAllBorders then ns.RefreshAllBorders() end
        end)
    settingsTab.showUncollectedBorderCheckBox = cbUncollectedBorder

    local cbUncollectedTooltip = addCheckbox(2,
        "Show uncollected tooltip text",
        "Uncollected appearance tooltip",
        'Show "Item appearance not yet collected!" text in tooltips for items whose appearance you haven\'t unlocked.',
        function(on)
            GetSettings().showUncollectedTooltip = on
            ns.showUncollectedTooltip = on
        end)
    settingsTab.showUncollectedTooltipCheckBox = cbUncollectedTooltip

    local cbHideCustomSets = addCheckbox(2,
        "Hide custom item sets",
        "Hide custom item sets",
        "Show only original item sets present in the base game (up to WotLK).  Hides synthesised sets generated from custom / downported items that have no item_template.itemset entry.",
        function(on)
            GetSettings().hideCustomSets = on
            if ns.RebuildSetLists then ns.RebuildSetLists() end
        end)

    local cbHideJunkSets = addCheckbox(2,
        "Hide junk / template sets",
        "Hide junk / template sets",
        "Hide catalog sets whose names contain developer keywords such as 'Art Template', 'Test', 'QA', or 'Deprecated'. These are internal placeholder sets not intended for players.",
        function(on)
            GetSettings().hideJunkSets = on
            if ns.RebuildSetLists then ns.RebuildSetLists() end
        end)
    settingsTab.hideJunkSetsCheckBox = cbHideJunkSets

    addSectionHeader(2, "Model Setup")

    -- Preview setup dropdown (classic vs modern)
    local previewLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", colX[2], colY[2] - 4)
    previewLabel:SetText(ABL("Character models:"))

    local previewMenu = CreateFrame("Frame", "AppearanceBuddyPreviewSetupMenu", settingsTab, "UIDropDownMenuTemplate")
    previewMenu:SetPoint("LEFT", previewLabel, "RIGHT", -14, 0)
    previewMenu:SetFrameStrata("FULLSCREEN_DIALOG")
    previewMenu:SetFrameLevel(205)
    UIDropDownMenu_SetWidth(previewMenu, 90)
    if _G["AppearanceBuddyPreviewSetupMenuButton"] then
        _G["AppearanceBuddyPreviewSetupMenuButton"]:HookScript("OnClick", RaiseAppearanceBuddyDropdownLayers)
    end

    local function previewMenu_OnClick(self, mode)
        applyPreviewSetup(mode)
        UIDropDownMenu_SetText(previewMenu, mode == "modern" and ABL("Modern") or ABL("Classic"))
    end
    UIDropDownMenu_Initialize(previewMenu, function()
        local cur = GetSettings().previewSetup
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.checked, info.arg1, info.func = "Classic", cur == "classic", "classic", previewMenu_OnClick
        UIDropDownMenu_AddButton(info)
        info.text, info.checked, info.arg1, info.func = "Modern",  cur == "modern",  "modern",  previewMenu_OnClick
        UIDropDownMenu_AddButton(info)
    end)

    colY[2] = colY[2] - 34

    local miniPreviewLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    miniPreviewLabel:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", colX[2], colY[2] - 4)
    miniPreviewLabel:SetText(ABL("Mini previews:"))

    local miniPreviewMenu = CreateFrame("Frame", "AppearanceBuddyMiniPreviewModeMenu", settingsTab, "UIDropDownMenuTemplate")
    miniPreviewMenu:SetPoint("LEFT", miniPreviewLabel, "RIGHT", -14, 0)
    miniPreviewMenu:SetFrameStrata("FULLSCREEN_DIALOG")
    miniPreviewMenu:SetFrameLevel(205)
    UIDropDownMenu_SetWidth(miniPreviewMenu, 90)
    if _G["AppearanceBuddyMiniPreviewModeMenuButton"] then
        _G["AppearanceBuddyMiniPreviewModeMenuButton"]:HookScript("OnClick", RaiseAppearanceBuddyDropdownLayers)
    end

    local function miniPreviewMenu_OnClick(self, mode)
        applyMiniPreviewMode(mode)
        UIDropDownMenu_SetText(miniPreviewMenu, mode == "dynamic" and ABL("Dynamic") or ABL("Static"))
    end
    UIDropDownMenu_Initialize(miniPreviewMenu, function()
        local cur = GetSettings().miniPreviewMode == "dynamic" and "dynamic" or "static"
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.checked, info.arg1, info.func = "Static", cur == "static", "static", miniPreviewMenu_OnClick
        UIDropDownMenu_AddButton(info)
        info.text, info.checked, info.arg1, info.func = "Dynamic", cur == "dynamic", "dynamic", miniPreviewMenu_OnClick
        UIDropDownMenu_AddButton(info)
    end)

    colY[2] = colY[2] - 34

    -- Mini preview sliders live in the freed right-side area instead of being
    -- pushed below the settings page.  They affect every mini model uniformly.
    local miniAdjustX = colX[2] + 330
    local miniAdjustY = -48
    local miniAdjustW = 300

    local miniAdjustHeader = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    miniAdjustHeader:SetText("|cffffd700Mini Model Adjustments|r")
    miniAdjustHeader:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", miniAdjustX, miniAdjustY)
    miniAdjustHeader:SetWidth(miniAdjustW)
    miniAdjustHeader:SetJustifyH("LEFT")
    local miniAdjustLine = settingsTab:CreateTexture(nil, "BACKGROUND")
    miniAdjustLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    miniAdjustLine:SetVertexColor(0.4, 0.4, 0.4, 0.8)
    miniAdjustLine:SetHeight(1)
    miniAdjustLine:SetPoint("TOPLEFT", miniAdjustHeader, "BOTTOMLEFT", 0, -1)
    miniAdjustLine:SetWidth(miniAdjustW - 24)

    local function createMiniSlider(name, labelText, yOffset, lowText, highText, minValue, maxValue, resetValue, tooltipText, onApply, valueTextFunc)
        local label = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", miniAdjustX, miniAdjustY - yOffset)
        label:SetText(labelText)

        local sliderFrame = CreateFrame("Slider", name, settingsTab, "OptionsSliderTemplate")
        sliderFrame:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
        sliderFrame:SetWidth(180)
        sliderFrame:SetMinMaxValues(minValue, maxValue)
        sliderFrame:SetValueStep(1)

        local low  = _G[sliderFrame:GetName().."Low"]
        local high = _G[sliderFrame:GetName().."High"]
        if low  then low:SetText(lowText) end
        if high then high:SetText(highText) end

        local resetButton = CreateFrame("Button", name.."Reset", settingsTab, "UIPanelButtonTemplate2")
        resetButton:SetSize(60, 20)
        resetButton:SetPoint("LEFT", sliderFrame, "RIGHT", 10, 0)
        resetButton:SetText(ABL("Reset"))
        resetButton:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetText(tooltipText)
            GameTooltip:Show()
        end)
        resetButton:HookScript("OnLeave", function() GameTooltip:Hide() end)
        resetButton:SetScript("OnClick", function()
            sliderFrame:SetValue(resetValue)
        end)

        local valueText = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valueText:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)

        sliderFrame:SetScript("OnValueChanged", function(self, value)
            local rounded = math.floor((tonumber(value) or resetValue) + 0.5)
            if self._abSuppressOnValueChanged then
                valueText:SetText(valueTextFunc(rounded))
                return
            end
            onApply(rounded)
            valueText:SetText(valueTextFunc(rounded))
        end)

        return sliderFrame, valueText
    end

    local miniVerticalSlider, miniVerticalValue = createMiniSlider(
        "AppearanceBuddyMiniPreviewVerticalSlider",
        "Mini model up/down:  |cff808080(default: 0)|r",
        30,
        "Down", "Up", -50, 50, 0,
        "Reset mini model vertical position to center",
        function(value) applyMiniPreviewVerticalAdjust(value / 100) end,
        function(value) return (value > 0 and "+" or "") .. value end)

    local miniPositionSlider, miniPositionValue = createMiniSlider(
        "AppearanceBuddyMiniPreviewPositionSlider",
        "Mini model left/right:  |cff808080(default: 0)|r",
        78,
        "Left", "Right", -50, 50, 0,
        "Reset mini model horizontal position to center",
        function(value) applyMiniPreviewPositionAdjust(value / 100) end,
        function(value) return (value > 0 and "+" or "") .. value end)

    miniMaxZoomSlider, miniMaxZoomValue = createMiniSlider(
        "AppearanceBuddyMiniPreviewMaxZoomSlider",
        "Mini maximum zoom:  |cff808080(default: 100%)|r",
        126,
        "30%", "300%", 30, 300, 100,
        "Reset mini model maximum zoom to 100%",
        function(value) applyMiniPreviewMaxZoom(value) end,
        function(value) return value .. "%" end)

    -- -----------------------------------------------------------------------
    -- RIGHT COLUMN (mini area) — Debug  (same x-axis as Mini Model Adjustments)
    -- -----------------------------------------------------------------------
    local debugHdr = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    debugHdr:SetText("|cffffd700Debug|r")
    debugHdr:SetPoint("TOPLEFT", miniMaxZoomSlider, "BOTTOMLEFT", 0, -28)
    debugHdr:SetWidth(miniAdjustW)
    debugHdr:SetJustifyH("LEFT")
    local debugLine = settingsTab:CreateTexture(nil, "BACKGROUND")
    debugLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    debugLine:SetVertexColor(0.4, 0.4, 0.4, 0.8)
    debugLine:SetHeight(1)
    debugLine:SetPoint("TOPLEFT", debugHdr, "BOTTOMLEFT", 0, -1)
    debugLine:SetWidth(miniAdjustW - 24)

    local cbCalibration = CreateFrame("CheckButton", "AppearanceBuddySettingsCBCalib", settingsTab, "ChatConfigCheckButtonTemplate")
    cbCalibration:SetPoint("TOPLEFT", debugHdr, "BOTTOMLEFT", 0, -8)
    cbCalibration:SetScript("OnClick", function(self)
        local on = self:GetChecked() ~= nil
        GetSettings().calibrationEnabled = on
        local tt = mainFrame.tabs and mainFrame.tabs.transmog
        local cb  = tt and tt.list and tt.list.calibBtn
        local ccb = tt and tt.list and tt.list.calibCopyBtn
        if cb  then if on then cb:Show() else cb:Hide(); cb:SetText(ABL("Calibrate: OFF")) end end
        if ccb then if not on then ccb:Hide() end end
        if not on and ns.calibrationMode then
            ns.calibrationMode = false
            if cb then cb:SetText(ABL("Calibrate: OFF")) end
            if ccb then ccb:Hide() end
        end
    end)
    cbCalibration:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(ABL("Enable calibration mode"))
        GameTooltip:AddLine(ABL("Shows Calibrate / Copy buttons on the Transmog tab for tuning per-race mini preview offsets. Off by default."), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbCalibration:HookScript("OnLeave", function() GameTooltip:Hide() end)
    local calibLbl = cbCalibration:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    calibLbl:SetText(ABL("Enable calibration"))
    calibLbl:SetPoint("LEFT", cbCalibration, "RIGHT", 4, 0)

    -- -----------------------------------------------------------------------
    -- applySettings: called once on ADDON_LOADED to sync all widgets
    -- -----------------------------------------------------------------------
    local function applySettings(settings)
        local autoBackground = classFileName == "DEATHKNIGHT" and "deathknight" or raceFileName:lower()
        applyCharacterBackground(autoBackground, unpack(settings.dressingRoomBackgroundColor))
        if ns.applyGridBackground then
            ns.applyGridBackground(settings.gridBackground and autoBackground or nil)
        end
        applyPreviewSetup(settings.previewSetup)
        UIDropDownMenu_SetText(previewMenu, settings.previewSetup == "modern" and ABL("Modern") or ABL("Classic"))

        if settings.showAppearanceBuddyButton then btnAppearanceBuddy:Show() else btnAppearanceBuddy:Hide() end
        if mainFrame.logoButton then
            if settings.showGithubButton ~= false then mainFrame.logoButton:Show() else mainFrame.logoButton:Hide() end
        end
        if settings.ignoreUIScaling then
            mainFrame:SetParent(nil); mainFrame:SetScale(0.9)
        else
            mainFrame:SetParent(UIParent); mainFrame:SetScale(1)
        end
        if mainFrame.UpdateWindowLockState then mainFrame.UpdateWindowLockState() end

        applyMiniPreviewMode(settings.miniPreviewMode)
        ns.itemOnlyView                     = settings.itemOnlyView == true
        ns.showOffhandInMainhandPreview      = settings.showOffhandInMainhandPreview == true
        ns.showUncollectedBorder             = settings.showUncollectedBorder ~= false
        if ns.RefreshAllBorders then ns.RefreshAllBorders() end
        ns.showUncollectedTooltip = settings.showUncollectedTooltip ~= false
        ns.hideNoLevelItems       = settings.hideNoLevelItems == true
        ns.miniPreviewMaxZoom = getMiniMaxZoomPercent(settings) / 100
        settings.miniPreviewMaxZoom = ns.miniPreviewMaxZoom
        ns.miniPreviewPositionAdjust = tonumber(settings.miniPreviewPositionAdjust) or 0.0
        if ns.miniPreviewPositionAdjust < -0.50 then ns.miniPreviewPositionAdjust = -0.50 end
        if ns.miniPreviewPositionAdjust > 0.50 then ns.miniPreviewPositionAdjust = 0.50 end
        ns.miniPreviewVerticalAdjust = tonumber(settings.miniPreviewVerticalAdjust) or 0.0
        if ns.miniPreviewVerticalAdjust < -0.50 then ns.miniPreviewVerticalAdjust = -0.50 end
        if ns.miniPreviewVerticalAdjust > 0.50 then ns.miniPreviewVerticalAdjust = 0.50 end

        local sz = settings.appearanceButtonSize or 40
        btnAppearanceBuddy:SetSize(sz, sz)

        -- Sync checkboxes
        cbShowButton:SetChecked(settings.showAppearanceBuddyButton)
        cbGithubButton:SetChecked(settings.showGithubButton ~= false)
        cbMuteSounds:SetChecked(settings.muteUISounds == true)
        cbShortcuts:SetChecked(settings.showShortcutsInTooltip)
        cbDisplayId:SetChecked(settings.showDisplayIdInTooltip ~= false)
        cbItemId:SetChecked(settings.showItemIdInTooltip ~= false)
        cbTransmogCost:SetChecked(settings.showTransmogCost ~= false)
        cbSetChatLinks:SetChecked(settings.enableSetChatLinks ~= false)
        cbIgnoreScaling:SetChecked(settings.ignoreUIScaling)
        cbWindowLocked:SetChecked(settings.windowLocked)
        cbAltAppearance:SetChecked(settings.alternativeWindowAppearance == true)
        applyAlternativeWindowAppearance(settings.alternativeWindowAppearance == true)
        -- Calibration buttons: only visible when Debug > Enable calibration is on.
        do
            local tt = mainFrame.tabs and mainFrame.tabs.transmog
            local cb  = tt and tt.list and tt.list.calibBtn
            local ccb = tt and tt.list and tt.list.calibCopyBtn
            local on  = settings.calibrationEnabled == true
            if cb  then if on then cb:Show()  else cb:Hide()  end end
            if ccb then ccb:Hide() end  -- Copy is shown only while Calibrate is ON
        end
        cbGridBg:SetChecked(settings.gridBackground)
        cbItemOnly:SetChecked(settings.itemOnlyView == true)
        cbShowOffhand:SetChecked(settings.showOffhandInMainhandPreview == true)
        cbSameType:SetChecked(settings.sameTypeFilter ~= false)
        cbHidePlaceholder:SetChecked(settings.hideNoLevelItems == true)
        cbUncollectedBorder:SetChecked(settings.showUncollectedBorder ~= false)
        cbUncollectedTooltip:SetChecked(settings.showUncollectedTooltip ~= false)
        cbHideCustomSets:SetChecked(settings.hideCustomSets == true)
        cbHideJunkSets:SetChecked(settings.hideJunkSets ~= false)
        slider:SetValue(sz)
        sliderVal:SetText(sz .. " px")
        local miniMaxZoom = getMiniMaxZoomPercent(settings)
        SetSliderValueSilently(miniMaxZoomSlider, miniMaxZoom, miniMaxZoomValue, function(value) return value .. "%" end)
        local miniPos = math.floor(((tonumber(settings.miniPreviewPositionAdjust) or 0.0) * 100) + 0.5)
        if miniPos < -50 then miniPos = -50 end
        if miniPos > 50 then miniPos = 50 end
        SetSliderValueSilently(miniPositionSlider, miniPos, miniPositionValue, function(value) return (value > 0 and "+" or "") .. value end)
        local miniVertical = math.floor(((tonumber(settings.miniPreviewVerticalAdjust) or 0.0) * 100) + 0.5)
        if miniVertical < -50 then miniVertical = -50 end
        if miniVertical > 50 then miniVertical = 50 end
        SetSliderValueSilently(miniVerticalSlider, miniVertical, miniVerticalValue, function(value) return (value > 0 and "+" or "") .. value end)
        UIDropDownMenu_SetText(miniPreviewMenu, settings.miniPreviewMode == "dynamic" and ABL("Dynamic") or ABL("Static"))
        -- Sync mini cell border color to ns and update swatch
        local cc = settings.miniCellBorderColor or {}
        local cr, cg, cb2 = cc[1] or 0.6, cc[2] or 0.52, cc[3] or 0.28
        if ns.applyMiniCellBorderColor then ns.applyMiniCellBorderColor(cr, cg, cb2) end
        updateCellColorSwatch()
    end

    -- Keep widgets in sync when the settings tab is shown.
    settingsTab:SetScript("OnShow", function()
        local s = GetSettings()
        cbShowButton:SetChecked(s.showAppearanceBuddyButton)
        cbGithubButton:SetChecked(s.showGithubButton ~= false)
        cbMuteSounds:SetChecked(s.muteUISounds == true)
        cbShortcuts:SetChecked(s.showShortcutsInTooltip)
        cbDisplayId:SetChecked(s.showDisplayIdInTooltip ~= false)
        cbItemId:SetChecked(s.showItemIdInTooltip ~= false)
        cbTransmogCost:SetChecked(s.showTransmogCost ~= false)
        cbSetChatLinks:SetChecked(s.enableSetChatLinks ~= false)
        cbIgnoreScaling:SetChecked(s.ignoreUIScaling)
        cbWindowLocked:SetChecked(s.windowLocked)
        cbAltAppearance:SetChecked(s.alternativeWindowAppearance == true)
        cbGridBg:SetChecked(s.gridBackground)
        cbItemOnly:SetChecked(s.itemOnlyView == true)
        cbShowOffhand:SetChecked(s.showOffhandInMainhandPreview == true)
        cbSameType:SetChecked(s.sameTypeFilter ~= false)
        cbHidePlaceholder:SetChecked(s.hideNoLevelItems == true)
        cbUncollectedBorder:SetChecked(s.showUncollectedBorder ~= false)
        cbUncollectedTooltip:SetChecked(s.showUncollectedTooltip ~= false)
        cbHideCustomSets:SetChecked(s.hideCustomSets == true)
        cbHideJunkSets:SetChecked(s.hideJunkSets ~= false)
        cbCalibration:SetChecked(s.calibrationEnabled == true)
        cbCalibration:SetChecked(s.calibrationEnabled == true)
        local sz = s.appearanceButtonSize or 40
        slider:SetValue(sz)
        sliderVal:SetText(sz .. " px")
        local miniMaxZoom = getMiniMaxZoomPercent(s)
        SetSliderValueSilently(miniMaxZoomSlider, miniMaxZoom, miniMaxZoomValue, function(value) return value .. "%" end)
        local miniPos = math.floor(((tonumber(s.miniPreviewPositionAdjust) or 0.0) * 100) + 0.5)
        if miniPos < -50 then miniPos = -50 end
        if miniPos > 50 then miniPos = 50 end
        SetSliderValueSilently(miniPositionSlider, miniPos, miniPositionValue, function(value) return (value > 0 and "+" or "") .. value end)
        local miniVertical = math.floor(((tonumber(s.miniPreviewVerticalAdjust) or 0.0) * 100) + 0.5)
        if miniVertical < -50 then miniVertical = -50 end
        if miniVertical > 50 then miniVertical = 50 end
        SetSliderValueSilently(miniVerticalSlider, miniVertical, miniVerticalValue, function(value) return (value > 0 and "+" or "") .. value end)
        UIDropDownMenu_SetText(previewMenu, s.previewSetup == "modern" and ABL("Modern") or ABL("Classic"))
        UIDropDownMenu_SetText(miniPreviewMenu, s.miniPreviewMode == "dynamic" and ABL("Dynamic") or ABL("Static"))
        local scc = s.miniCellBorderColor or {}
        local scr, scg, scb = scc[1] or 0.6, scc[2] or 0.52, scc[3] or 0.28
        if ns.applyMiniCellBorderColor then ns.applyMiniCellBorderColor(scr, scg, scb) end
        updateCellColorSwatch()

        -- Hide the dressing room and slot buttons so 3D model enchant effects
        -- (weapon glows, particle FX) don't bleed through the settings panel.
        mainFrame.dressingRoom:Hide()
        if ns.SetAppearanceBuddyPreviewControlsVisible then
            ns.SetAppearanceBuddyPreviewControlsVisible(false)
        end
        -- Also hide the action buttons that sit on mainFrame (not on transmogTab).
        if mainFrame.buttons.send    then mainFrame.buttons.send:Hide()    end
        if mainFrame.buttons.reset   then mainFrame.buttons.reset:Hide()   end
        if mainFrame.buttons.undress then mainFrame.buttons.undress:Hide() end
        if mainFrame.buttons.useTarget then mainFrame.buttons.useTarget:Hide() end
        -- Share controls were reparented to mainFrame so they don't auto-hide
        -- with transmogTab; explicitly hide them while Settings is visible.
        local tt = mainFrame.tabs and mainFrame.tabs.transmog
        if tt then
            if tt.buttonShareCopy then tt.buttonShareCopy:Hide() end
            if tt.buttonShareLink then tt.buttonShareLink:Hide() end
            if tt.shareEditBox    then tt.shareEditBox:Hide()    end
        end
    end)

    settingsTab:HookScript("OnHide", function()
        -- Restore the dressing room and action buttons when leaving the settings tab.
        -- transmogTab:OnShow will re-hide the slot buttons when the transmog tab opens.
        mainFrame.dressingRoom:Show()
        if mainFrame.buttons.send    then mainFrame.buttons.send:Show()    end
        if mainFrame.buttons.reset   then mainFrame.buttons.reset:Show()   end
        if mainFrame.buttons.undress then mainFrame.buttons.undress:Show() end
        if mainFrame.buttons.useTarget then mainFrame.buttons.useTarget:Show() end
    end)

    -- -----------------------------------------------------------------------
    -- ADDON_LOADED: bootstrap saved variables
    -- -----------------------------------------------------------------------
    settingsTab:RegisterEvent("ADDON_LOADED")
    settingsTab:SetScript("OnEvent", function(self, event, addonName)
        if addonName == addon then
            if event == "ADDON_LOADED" then
                applySettings(GetSettings())
                if type(_G["AppearanceBuddyBlacklist"]) == "table" then
                    ns.queryFailedItemIds = _G["AppearanceBuddyBlacklist"]
                else
                    _G["AppearanceBuddyBlacklist"] = {}
                    ns.queryFailedItemIds = _G["AppearanceBuddyBlacklist"]
                end
                local blCount = 0
                for _ in pairs(ns.queryFailedItemIds) do blCount = blCount + 1 end
                ns.queryFailedCount = blCount
                -- The persistent page-cap mechanism caused stuck low page
                -- counts when users scrolled rapidly through pages whose
                -- items briefly looked empty post-filter.  The server
                -- already excludes blacklisted items via excludeList, so
                -- its totalPages is authoritative.  Wipe any stale cap and
                -- disable the persistent store entirely.
                _G["AppearanceBuddyPageCaps"] = nil
                ns.slotPageCaps = nil
            end
        end
    end)
end

---------------- CHAT COMMANDS ----------------

ns.mainFrame = mainFrame
ns.slotSubclasses = slotSubclasses
ns.GetSettings = GetSettings
ns.RefreshManagedScrollFrame = RefreshManagedScrollFrame
ns.GetPreviewSetupVersion = function()
    return previewSetupVersion
end
ns.RefreshDressingRoomFromSlots = refreshDressingRoomFromSlots
ns.SetAppearanceBuddyPreviewControlsVisible = function(visible)
    for _, slot in pairs(mainFrame.slots) do
        if visible then
            slot:Show()
        else
            slot:Hide()
        end
    end

    for _, name in ipairs({"send", "reset", "undress", "useTarget"}) do
        local button = mainFrame.buttons[name]
        if button then
            if visible then
                button:Show()
            else
                button:Hide()
            end
        end
    end
end

-- Hide transmog-side controls when the Settings tab is active.
do
    local function showTransmogSide()
        -- Do NOT call SetAppearanceBuddyPreviewControlsVisible here.
        -- transmogTab:OnShow already fires before this hook and manages slot/button
        -- visibility correctly via updateActionButtons(). Calling it again here
        -- would override that and show buttons that should stay hidden.
        if mainFrame.dressingRoom then
            mainFrame.dressingRoom:SetAlpha(1)
        end
        if mainFrame.stats then mainFrame.stats:Show() end
        local tt = mainFrame.tabs.transmog
        if tt then
            if tt.buttonMHIllusion then tt.buttonMHIllusion:Show() end
            if tt.buttonOHIllusion then tt.buttonOHIllusion:Show() end
        end
    end
    local function hideTransmogSide()
        ns.SetAppearanceBuddyPreviewControlsVisible(false)
        if mainFrame.dressingRoom then
            mainFrame.dressingRoom:SetAlpha(0)
        end
        if mainFrame.stats then mainFrame.stats:Hide() end
        local tt = mainFrame.tabs.transmog
        if tt then
            if tt.buttonMHIllusion then tt.buttonMHIllusion:Hide() end
            if tt.buttonOHIllusion then tt.buttonOHIllusion:Hide() end
        end
    end

    local frameName = mainFrame:GetName()
    local tabBtn1 = _G[frameName .. "Tab1"]
    local tabBtn2 = _G[frameName .. "Tab2"]
    if tabBtn1 then
        tabBtn1:HookScript("OnClick", showTransmogSide)
    end
    if tabBtn2 then
        tabBtn2:HookScript("OnClick", hideTransmogSide)
    end
end

SLASH_APPEARANCEBUDDY1 = "/appearancebuddy"
SLASH_APPEARANCEBUDDY2 = "/ab"

-- Scan results popup (created once, reused)
local function getScanPopup()
    if _G["AppearanceBuddyScanPopup"] then
        return _G["AppearanceBuddyScanPopup"]
    end
    local p = CreateFrame("Frame", "AppearanceBuddyScanPopup", UIParent)
    p:SetSize(540, 360)
    p:SetPoint("CENTER")
    p:SetMovable(true)
    p:EnableMouse(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    p:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    p:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    p:SetBackdropBorderColor(0.55, 0.55, 0.55)

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -9)
    title:SetText("|cff00ff00AppearanceBuddy Frame Scan|r  (Ctrl+A then Ctrl+C to copy)")

    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() p:Hide() end)

    local sf = CreateFrame("ScrollFrame", "AppearanceBuddyScanScroll", p, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 8, -26)
    sf:SetPoint("BOTTOMRIGHT", -26, 8)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:EnableMouse(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetWidth(490)
    eb:SetScript("OnEscapePressed", function() p:Hide() end)
    sf:SetScrollChild(eb)
    p.editBox = eb

    return p
end

-- Register with the WoW Interface Options panel (Interface > AddOns list)
do
    local panel = CreateFrame("Frame")
    panel.name = "AppearanceBuddy"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AppearanceBuddy")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText(ABL("Transmog addon for WotLK 3.3.5  |cff808080/ab|r"))

    -- Scroll frame so all checkboxes fit without overflowing the panel.
    local scrollFrame = CreateFrame("ScrollFrame", "AppearanceBuddyOptionsScroll", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     subtitle, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel,    "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(390)    -- fixed width; scroll bar is 16px, panel content ~430px
    content:SetHeight(600)   -- large enough for all items; scroll frame clips to panel height
    scrollFrame:SetScrollChild(content)

    -- WotLK bug: UIPanelScrollFrameTemplate's OnScrollRangeChanged checks
    -- "value == max" to decide whether to follow the thumb. When the range
    -- is first established from 0→N, both value and max are 0 so it
    -- "follows" to the new max, landing at the bottom.  Force top on the
    -- first range change so the list always starts at the top.
    local scrollRangeInitialized = false
    scrollFrame:HookScript("OnScrollRangeChanged", function(self, _, yRange)
        if not scrollRangeInitialized and (yRange or 0) > 0 then
            scrollRangeInitialized = true
            self:SetVerticalScroll(0)
            local sb = _G[self:GetName() .. "ScrollBar"]
            if sb then sb:SetValue(0) end
        end
    end)

    -- Resize content width to match the scroll frame once it has been laid out.
    scrollFrame:HookScript("OnShow", function(self)
        local w = self:GetWidth()
        if w and w > 10 then content:SetWidth(w) end
    end)

    local checkboxes = {}
    local lastAnchor = content   -- chain from the top of the content frame

    local _optCbIdx = 0
    local function makeCheckbox(key, label, tooltipTitle, tooltipBody, onClick)
        _optCbIdx = _optCbIdx + 1
        local cb = CreateFrame("CheckButton", "AppearanceBuddyOptionsCB" .. _optCbIdx, content, "ChatConfigCheckButtonTemplate")
        if lastAnchor == content then
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
        else
            cb:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, 0)
        end
        cb:SetScript("OnClick", function(self)
            onClick(self:GetChecked() ~= nil)
        end)
        if tooltipTitle then
            cb:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(tooltipTitle)
                if tooltipBody then GameTooltip:AddLine(tooltipBody, 1, 1, 1, 1, true) end
                GameTooltip:Show()
            end)
            cb:HookScript("OnLeave", function() GameTooltip:Hide() end)
        end
        local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetText(label)
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 2)
        checkboxes[key] = cb
        lastAnchor = cb
        return cb
    end

    local function syncSettingsTab(cbName, value)
        local st = mainFrame.tabs.settings
        if st and st[cbName] then
            -- Use the raw method to avoid firing the settingsTab OnClick again.
            local raw = st[cbName]._origSetChecked or getmetatable(st[cbName]) and getmetatable(st[cbName]).__index and getmetatable(st[cbName]).__index.SetChecked
            if raw then raw(st[cbName], value) else st[cbName]:SetChecked(value) end
        end
    end

    makeCheckbox("showAppearanceBuddyButton", 'Show "Appearance" button',
        'Show "Appearance" button',
        'Show or hide the "Appearance" button in the character window.',
        function(on)
            GetSettings().showAppearanceBuddyButton = on
            syncSettingsTab("showAppearanceBuddyButtonCheckBox", on)
            if on then btnAppearanceBuddy:Show() else btnAppearanceBuddy:Hide() end
        end)

    makeCheckbox("showShortcutsInTooltip", "Show shortcuts in tooltip", nil, nil,
        function(on)
            GetSettings().showShortcutsInTooltip = on
            syncSettingsTab("showShortcutsInTooltipCheckBox", on)
        end)

    makeCheckbox("ignoreUIScaling", "Ignore UI scaling",
        "Ignore UI scaling",
        "The game's 3D rendering can break correct display of previews with low UI scaling values. Enable this to bypass UI scaling.",
        function(on)
            GetSettings().ignoreUIScaling = on
            syncSettingsTab("ignoreUIScalingCheckBox", on)
            if on then
                mainFrame:SetParent(nil)
                mainFrame:SetScale(0.9)
            else
                mainFrame:SetParent(UIParent)
                mainFrame:SetScale(1)
            end
            if mainFrame:IsVisible() then mainFrame:Hide(); mainFrame:Show() end
        end)

    makeCheckbox("windowLocked", "Lock window",
        "Lock window",
        "Prevent AppearanceBuddy from being moved.",
        function(on)
            GetSettings().windowLocked = on
            syncSettingsTab("windowLockedCheckBox", on)
            if mainFrame.UpdateWindowLockState then mainFrame.UpdateWindowLockState() end
        end)

    makeCheckbox("gridBackground", "Item grid background",
        "Item grid background",
        "Show the race background image inside each item preview cell instead of a plain grey box.",
        function(on)
            GetSettings().gridBackground = on
            syncSettingsTab("gridBackgroundCheckBox", on)
            if ns.applyGridBackground then
                if on then
                    local bg = GetSettings().dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]:lower()
                    ns.applyGridBackground(bg ~= "color" and bg or nil)
                else
                    ns.applyGridBackground(nil)
                end
            end
        end)

    makeCheckbox("showDisplayIdInTooltip", "Show Item Display Id in tooltip", nil, nil,
        function(on)
            GetSettings().showDisplayIdInTooltip = on
            syncSettingsTab("showDisplayIdInTooltipCheckBox", on)
        end)

    makeCheckbox("showItemIdInTooltip", "Show Item Id in tooltip",
        "Show Item Id in tooltip",
        "Show the server item ID for the appearance beneath the display ID in the item tooltip.",
        function(on)
            GetSettings().showItemIdInTooltip = on
            syncSettingsTab("showItemIdInTooltipCheckBox", on)
        end)

    makeCheckbox("itemOnlyView", "Bare character view (mini models)",
        "Bare character view",
        "Show the previewed item on a bare, undressed character in the mini views, hiding all other equipped gear.",
        function(on)
            GetSettings().itemOnlyView = on
            ns.itemOnlyView = on
            syncSettingsTab("itemOnlyViewCheckBox", on)
            if ns.mainFrame and ns.mainFrame.tabs and ns.mainFrame.tabs.transmog then
                local list = ns.mainFrame.tabs.transmog.list
                if list and list.dressingRoomSetup and #list.itemIds > 0 then
                    list:Update()
                end
            end
        end)

    makeCheckbox("showOffhandInMainhandPreview", "Show equipped off-hand in main hand previews",
        "Show equipped off-hand in main hand previews",
        "When browsing main hand items, also show your equipped off-hand (shield, weapon, etc.) in each mini preview card. Off by default so shields don't clutter the main hand preview.",
        function(on)
            GetSettings().showOffhandInMainhandPreview = on
            ns.showOffhandInMainhandPreview = on
            syncSettingsTab("showOffhandInMainhandPreviewCheckBox", on)
            if ns.mainFrame and ns.mainFrame.tabs and ns.mainFrame.tabs.transmog then
                local list = ns.mainFrame.tabs.transmog.list
                if list and list.dressingRoomSetup and #list.itemIds > 0 then
                    list:Update()
                end
            end
        end)

    makeCheckbox("sameTypeFilter", "Smart Filter",
        "Smart Filter",
        "When changing a slot, start with the equipped item's type selected in the Filter menu. You can still change the filter manually.",
        function(on)
            GetSettings().sameTypeFilter = on
            syncSettingsTab("sameTypeFilterCheckBox", on)
            if ns.ApplySameTypeFilterForCurrentSlot then
                ns.ApplySameTypeFilterForCurrentSlot(true)
            end
        end)

    makeCheckbox("showUncollectedBorder", "Show uncollected appearance border",
        "Uncollected appearance border",
        "Show a colored border around items whose appearance you have not yet collected (bags, character sheet, auction house, loot).",
        function(on)
            GetSettings().showUncollectedBorder = on
            ns.showUncollectedBorder = on
            syncSettingsTab("showUncollectedBorderCheckBox", on)
            if ns.RefreshAllBorders then ns.RefreshAllBorders() end
        end)

    makeCheckbox("showUncollectedTooltip", "Show uncollected tooltip text",
        "Uncollected appearance tooltip",
        'Show "Item appearance not yet collected!" text in tooltips for items whose appearance you have not unlocked.',
        function(on)
            GetSettings().showUncollectedTooltip = on
            ns.showUncollectedTooltip = on
            syncSettingsTab("showUncollectedTooltipCheckBox", on)
        end)

    makeCheckbox("showTransmogCost", "Show transmog cost",
        "Show transmog cost",
        "Display the gold cost for applying transmog changes in the status bar.",
        function(on)
            GetSettings().showTransmogCost = on
            syncSettingsTab("showTransmogCostCheckBox", on)
        end)

    makeCheckbox("enableSetChatLinks", "Enable set chat links",
        "Enable set chat links",
        "When enabled, the 'Link Set' button posts a clickable [Set Name] hyperlink in chat. Other AppearanceBuddy users can click it to import and preview the set in one step. When disabled, 'Link Set' falls back to the raw share code and incoming set links on your client are ignored.",
        function(on)
            GetSettings().enableSetChatLinks = on
            syncSettingsTab("enableSetChatLinksCheckBox", on)
        end)

    -- Slider: Appearance button size
    do
        local sliderLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        sliderLabel:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 2, -16)
        sliderLabel:SetText(ABL("Appearance button size"))

        local slider = CreateFrame("Slider", "AppearanceBuddyButtonSizeSlider", content, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", sliderLabel, "BOTTOMLEFT", 0, -8)
        slider:SetWidth(200)
        slider:SetMinMaxValues(20, 80)
        slider:SetValueStep(1)
        local sliderLow  = _G[slider:GetName().."Low"]
        local sliderHigh = _G[slider:GetName().."High"]
        if sliderLow  then sliderLow:SetText("20") end
        if sliderHigh then sliderHigh:SetText("80") end

        local valLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        valLabel:SetPoint("TOP", slider, "BOTTOM", 0, -2)

        local function applySize(size)
            size = math.floor(size + 0.5)
            GetSettings().appearanceButtonSize = size
            btnAppearanceBuddy:SetSize(size, size)
            valLabel:SetText(size.." px")
            slider:SetValue(size)
        end

        slider:SetScript("OnValueChanged", function(self, value)
            applySize(value)
        end)

        -- Sync when panel opens.
        local origOnShow = panel:GetScript("OnShow")
        panel:HookScript("OnShow", function()
            local sz = GetSettings().appearanceButtonSize or 40
            slider:SetValue(sz)
            valLabel:SetText(sz.." px")
        end)

        applySize(GetSettings().appearanceButtonSize or 40)
        -- Anchor the next item below the slider's Low/High/value label row.
        -- Use slider:BOTTOMLEFT (offset -2 to undo sliderLabel's +2 indent, and
        -- -22 to clear the Low/High/valLabel text that sits below the thumb).
        local afterSlider = CreateFrame("Frame", nil, content)
        afterSlider:SetSize(1, 1)
        afterSlider:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -2, -22)
        lastAnchor = afterSlider
    end

    makeCheckbox("hideNoLevelItems", "Hide placeholder items",
        "Hide placeholder items",
        "Hide appearances for items with no required level and item level 0 or 1. These are typically debug, placeholder, or removed items.",
        function(on)
            GetSettings().hideNoLevelItems = on
            ns.hideNoLevelItems = on
            syncSettingsTab("hideNoLevelItemsCheckBox", on)
            if ns.requestCurrentSlotItems then ns.requestCurrentSlotItems(true) end
        end)

    makeCheckbox("hideJunkSets", "Hide junk / template sets",
        "Hide junk / template sets",
        "Hide catalog sets whose names contain developer keywords such as 'Art Template', 'Test', 'QA', or 'Deprecated'. These are internal placeholder sets not intended for players.",
        function(on)
            GetSettings().hideJunkSets = on
            syncSettingsTab("hideJunkSetsCheckBox", on)
            if ns.RebuildSetLists then ns.RebuildSetLists() end
        end)

    -- Refresh checkbox states whenever the panel is opened.
    panel:SetScript("OnShow", function()
        scrollFrame:SetVerticalScroll(0)
        local sb = _G["AppearanceBuddyOptionsScrollScrollBar"]
        if sb then sb:SetValue(0) end
        local s = GetSettings()
        checkboxes.showAppearanceBuddyButton:SetChecked(s.showAppearanceBuddyButton)
        checkboxes.showShortcutsInTooltip:SetChecked(s.showShortcutsInTooltip)
        checkboxes.ignoreUIScaling:SetChecked(s.ignoreUIScaling)
        checkboxes.windowLocked:SetChecked(s.windowLocked)
        checkboxes.gridBackground:SetChecked(s.gridBackground)
        checkboxes.showDisplayIdInTooltip:SetChecked(s.showDisplayIdInTooltip ~= false)
        checkboxes.showItemIdInTooltip:SetChecked(s.showItemIdInTooltip ~= false)
        checkboxes.itemOnlyView:SetChecked(s.itemOnlyView == true)
        checkboxes.showOffhandInMainhandPreview:SetChecked(s.showOffhandInMainhandPreview == true)
        checkboxes.sameTypeFilter:SetChecked(s.sameTypeFilter ~= false)
        checkboxes.showUncollectedBorder:SetChecked(s.showUncollectedBorder ~= false)
        checkboxes.showUncollectedTooltip:SetChecked(s.showUncollectedTooltip ~= false)
        checkboxes.showTransmogCost:SetChecked(s.showTransmogCost ~= false)
        checkboxes.enableSetChatLinks:SetChecked(s.enableSetChatLinks ~= false)
        checkboxes.hideNoLevelItems:SetChecked(s.hideNoLevelItems == true)
        checkboxes.hideJunkSets:SetChecked(s.hideJunkSets ~= false)
    end)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

SlashCmdList["APPEARANCEBUDDY"] = function(msg)
    if msg == "" then
        if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
    elseif msg == "debug" then
        if mainFrame.dressingRoom:IsDebugInfoShown() then mainFrame.dressingRoom:HideDebugInfo() else mainFrame.dressingRoom:ShowDebugInfo() end
    elseif msg == "scan" then
        local mfLeft, mfBottom, mfWidth, mfHeight = mainFrame:GetLeft(), mainFrame:GetBottom(), mainFrame:GetWidth(), mainFrame:GetHeight()
        if not mfLeft then
            print("|cffff4444AppearanceBuddy scan:|r Open the window first.")
            return
        end
        local mfRight  = mfLeft   + mfWidth
        local mfTop    = mfBottom + mfHeight
        -- Search zone: mainFrame area expanded by 600px on all sides
        local expand = 600
        local zL, zR = mfLeft - expand, mfRight  + expand
        local zB, zT = mfBottom - expand, mfTop + expand

        local lines = {}
        lines[#lines+1] = string.format("mainFrame: (%.0f,%.0f)-(%.0f,%.0f)  size %.0fx%.0f",
            mfLeft, mfBottom, mfRight, mfTop, mfWidth, mfHeight)
        lines[#lines+1] = "Visible frames within 300px of window:"
        lines[#lines+1] = ""

        local count = 0
        local frame = EnumerateFrames()
        while frame do
            if frame:IsVisible() and frame ~= mainFrame then
                local fl, fb, fw, fh = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
                if fl and fb and fw and fh and fw > 0 and fh > 0 then
                    local fr = fl + fw
                    local ft = fb + fh
                    -- Include only frames that overlap the search zone
                    if fr > zL and fl < zR and ft > zB and fb < zT then
                        local name = frame:GetName() or "(no name)"
                        local otype = frame:GetObjectType()
                        local outsideTag = ""
                        if fr <= mfLeft or fl >= mfRight or ft <= mfBottom or fb >= mfTop then
                            outsideTag = " *** OUTSIDE ***"
                        end
                        lines[#lines+1] = string.format("[%s] %s  (%.0f,%.0f)-(%.0f,%.0f)%s",
                            otype, name, fl, fb, fr, ft, outsideTag)
                        count = count + 1
                    end
                end
            end
            frame = EnumerateFrames(frame)
        end

        if count == 0 then
            lines[#lines+1] = "(none found)"
        end

        local popup = getScanPopup()
        local text = table.concat(lines, "\n")
        popup.editBox:SetText(text)
        popup.editBox:SetCursorPosition(0)
        popup:Show()
        popup:Raise()
        print("|cff00ff00AppearanceBuddy:|r Scan complete — " .. count .. " frame(s). See popup window.")
    end
end
