local addon, ns = ...

-- ============================================================
-- PREVIEWLIST.LUA — SECTION MAP
-- ============================================================
--  Quick reference for where to find things in this file.
--
--  TUNING (most common edits)
--  ┌─────────────────────────────────────────────────────────────────────┐
--  │ Dynamic mode knobs          ~L77   MINI PREVIEW CONFIGURATION       │
--  │   Zoom sync strength              DYNAMIC_MINI_ZOOM_SYNC_FACTOR     │
--  │   Mini zoom-in/out clamps         DYNAMIC_MINI_X_MIN/MAX            │
--  │   Main-preview influence clamp    DYNAMIC_MAIN_X_MIN/MAX            │
--  │                                                                     │
--  │ Per-slot offsets (all races) ~L133  MINI PREVIEW CONFIGURATION      │
--  │   Zoom/pan/vert by slot           SLOT_OFFSETS { x, y, z }          │
--  │                                                                     │
--  │ Per-race/sex offsets         ~L155  MINI PREVIEW CONFIGURATION      │
--  │   Per-race, per-slot, static/dyn  RACE_SLOT_OFFSETS                 │
--  │   { slot → { static/dynamic → { x, y, z } } }                      │
--  └─────────────────────────────────────────────────────────────────────┘
--
--  SECTION INDEX
--  ~L  4   UPVALUE ALIASES            — localized globals / math functions
--  ~L 18   OFF-HAND SUBCLASS HELPERS  — subType→framing key mapping
--  ~L 46   MINI PREVIEW POSITION ACCESSORS
--                                     — getMiniPreviewY/Z/MaxZoom helpers
--  ~L 77   MINI PREVIEW CONFIG — DYNAMIC MODE KNOBS
--                                     — zoom sync factor + min/max clamps
--  ~L133   MINI PREVIEW CONFIG — SLOT OFFSETS (ALL RACES)
--                                     — per-slot zoom/pan/vert {x,y,z} applied to all races
--  ~L155   MINI PREVIEW CONFIG — PER-RACE / PER-SEX OFFSETS
--                                     — per-race/sex/slot {static/dynamic → {x,y,z}}
--  ~L524   DYNAMIC MODE CAMERA HELPERS
--                                     — getMainPreviewZoomOffset, getDynamicMiniFacing
--  ~L563   BACKGROUND TEXTURE SYSTEM  — per-race bg textures on mini cards
--  ~L614   CELL APPEARANCE CONSTANTS  — border colors, selection ring settings
--  ~L634   OFF-HAND TRYON SEQUENCER   — blocker item + scheduleOffhandSequence
--  ~L718   DRESSING ROOM CALLBACKS & RECYCLER
--                                     — model creation, pooling, click/select logic
--  ~L925   PREVIEWLIST METHODS        — public API (Show, Hide, SetSlot, …)
--  ~L1031  RENDER                     — renderPreviewItem, applyMiniPreviewPosition
--  ~L1155  QUERY CALLBACK             — item-data-ready → trigger render
--  ~L1225  UPDATE                     — OnUpdate handler (dynamic mirror loop)
--  ~L1346  CONSTRUCTOR                — ns.CreatePreviewList entry point
-- ============================================================

-- ============================================================
-- UPVALUE ALIASES
-- ============================================================
local pairs = pairs
local ipairs = ipairs
local type = type
local unpack = unpack
local math_floor = math.floor
local math_min = math.min
local math_max = math.max

local _, _playerRaceFile = UnitRace("player")
local _playerSex         = UnitSex("player")

-- ============================================================
-- OFF-HAND SUBCLASS HELPERS
-- ============================================================
-- Map GetItemInfo's (subType, equipLoc) → DressMe per-OH-subclass framing key.
-- DressMe's PreviewSetupDB has dedicated entries under "Off-hand" for each
-- weapon shape so the model rotates / re-zooms to read as off-hand even
-- though the engine still attaches the weapon to the MH bone.
local function getOffhandSubclassKey(itemId)
    if not itemId then return nil end
    local _, _, _, _, _, _, subType, _, equipLoc = GetItemInfo(itemId)
    if equipLoc == "INVTYPE_SHIELD"   then return "Shield" end
    if equipLoc == "INVTYPE_HOLDABLE" then return "Held in Off-hand" end
    if not subType then return nil end
    if subType:find("Sword")  then return "Sword"  end
    if subType:find("Axe")    then return "Axe"    end
    if subType:find("Mace")   then return "Mace"   end
    if subType:find("Dagger") then return "Dagger" end
    if subType:find("Fist")   then return "Fist"   end
    return nil
end

local function getOffhandPreviewSetup(itemId)
    local key = getOffhandSubclassKey(itemId)
    if not key then return nil end
    local version = ns.GetPreviewSetupVersion and ns.GetPreviewSetupVersion() or "classic"
    return ns.GetPreviewSetup and ns.GetPreviewSetup(version, _playerRaceFile, _playerSex, "Off-hand", key) or nil
end

-- ============================================================
-- MINI PREVIEW POSITION ACCESSORS
-- ============================================================
-- Keep mini previews using the calibrated race/sex horizontal framing from
-- PreviewSetupDB. Forcing this value to zero causes some models, especially
-- human female head previews, to sit left of center and clip against the card.
local function getMiniPreviewY(y)
    return tonumber(y) or 0
end

local function getMiniPreviewMaxZoom()
    local value = tonumber(ns.miniPreviewMaxZoom) or 1.0
    if value < 0.30 then value = 0.30 end
    if value > 3.00 then value = 3.00 end
    return value
end

local function getMiniPreviewPositionAdjust()
    local value = tonumber(ns.miniPreviewPositionAdjust) or 0.0
    if value < -0.50 then value = -0.50 end
    if value > 0.50 then value = 0.50 end
    return value
end

local function getMiniPreviewVerticalAdjust()
    local value = tonumber(ns.miniPreviewVerticalAdjust) or 0.0
    if value < -0.50 then value = -0.50 end
    if value > 0.50 then value = 0.50 end
    return value
end

-- ============================================================
-- MINI PREVIEW CONFIGURATION — DYNAMIC MODE
-- ============================================================
-- DYNAMIC_MINI_ZOOM_SYNC_FACTOR
--   How strongly the mini cards mirror the main preview's zoom
--   in dynamic mode. 1.0 = mirror exactly, 0.0 = ignore main zoom.
local DYNAMIC_MINI_ZOOM_SYNC_FACTOR = 0.55

-- Dynamic mode zoom clamps for mini cells (x axis = model position, matches main preview).
--   Higher x = more zoomed IN  (model closer to camera, larger/more detail).
--   Lower x  = more zoomed OUT (model further from camera, shows more of body).
--
--   DYNAMIC_MINI_X_MAX   : ceiling for mini cell zoom-in — lower this to prevent
--                          the minis following the main preview too far into the head.
--                          Default 12.00 (permissive). Try 0.75 to match the main clamp.
--   DYNAMIC_MINI_X_MIN   : floor for mini cell zoom-out (how far back the model pulls).
--                          Default -10.00 (very permissive zoom-out).
--   DYNAMIC_MAIN_X_MIN/MAX: clamps the raw main-preview x value before it feeds into
--                          the sync calculation — limits how much the main
--                          preview's zoom can influence the mini cards at all.
local DYNAMIC_MINI_X_MIN  = -10.00
local DYNAMIC_MINI_X_MAX  = 12.00
local DYNAMIC_MAIN_X_MIN  = -2.00
local DYNAMIC_MAIN_X_MAX  =  3.00

-- ============================================================
-- MINI PREVIEW CONFIGURATION — SLOT OFFSETS (ALL RACES)
-- ============================================================
-- Applied to ALL races in both static and dynamic mode.
-- Added on top of PreviewSetupDB base values.
--   x = zoom    (positive = more zoomed in,  negative = more zoomed out)
--   y = pan     (positive = shift right,      negative = shift left)
--   z = vertical (positive = shift up,        negative = shift down)
local SLOT_OFFSETS = {
    ["Head"]         = { x =  0.65, y = 0, z = 0 },  -- zoom in to fill cell
    ["Shoulder"]     = { x = -0.75, y = 0, z = 0 },  -- zoom out for full pauldrons
    -- ["Back"]      = { x = 0, y = 0, z = 0 },
    -- ["Chest"]     = { x = 0, y = 0, z = 0 },
    -- ["Shirt"]     = { x = 0, y = 0, z = 0 },
    -- ["Tabard"]    = { x = 0, y = 0, z = 0 },
    -- ["Wrist"]     = { x = 0, y = 0, z = 0 },
    -- ["Hands"]     = { x = 0, y = 0, z = 0 },
    -- ["Waist"]     = { x = 0, y = 0, z = 0 },
    -- ["Legs"]      = { x = 0, y = 0, z = 0 },
    -- ["Feet"]      = { x = 0, y = 0, z = 0 },
    -- ["Main Hand"] = { x = 0, y = 0, z = 0 },
    -- ["Off-hand"]  = { x = 0, y = 0, z = 0 },
    -- ["Ranged"]    = { x = 0, y = 0, z = 0 },
}

-- ============================================================
-- MINI PREVIEW CONFIGURATION — PER-RACE / PER-SEX OFFSETS
-- ============================================================
-- Additive on top of PreviewSetupDB + SLOT_OFFSETS above.
-- Each slot entry:  { static = { x, y, z }, dynamic = { x, y, z } }
--   Omit "static" or "dynamic" to leave that mode unaffected.
--   Omit or zero any axis component to leave it unaffected.
--   x = zoom    (positive = more zoomed in,  negative = more zoomed out)
--   y = pan     (positive = shift right,      negative = shift left)
--   z = vertical (positive = shift up,        negative = shift down)
-- Sex-specific override: add a [2] (male) or [3] (female) sub-table inside
--   the race.  Entries in race[sex][slot] take priority over race[slot].
local RACE_SLOT_OFFSETS = {
    -- ---- Alliance ----
    ["Dwarf"] = {
        ["Head"] = {
            static  = { x = 0, y = 0, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        -- ["Shoulder"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Back"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Chest"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Shirt"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Tabard"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Wrist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Hands"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Waist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Legs"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Feet"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Main Hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Off-hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Ranged"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
    },
    ["Draenei"] = {
        ["Head"] = {
            static  = { x = 0, y = 0, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        -- ["Shoulder"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Back"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Chest"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Shirt"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Tabard"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Wrist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Hands"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Waist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Legs"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Feet"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Main Hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Off-hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Ranged"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
    },
    ["Gnome"] = {
        ["Head"] = {
            static  = { x = -0.61, y = 0, z = -0.18 },
            dynamic = { x = -1, y = 0, z = -0.15 },
        },
        ["Shoulder"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Back"] = {
            static  = { x = -0.55, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Chest"] = {
            static  = { x = -0.4, y = 0, z = 0.06 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Shirt"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Tabard"] = {
            static  = { x = -0.25, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Wrist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Hands"] = {
            static  = { x = -0.4, y = -0.12, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Waist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Legs"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Feet"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Main Hand"] = {
            static  = { x = -0.7, y = -0.18, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Off-hand"] = {
            static  = { x = -0.10, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Ranged"] = {
            static  = { x = -0.4, y = -0.06, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
    },
    ["Human"] = {
        ["Head"] = {
            static  = { x = -0.15, y = 0.05, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        ["Shoulder"] = {
            static  = { x = 0.30, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Back"] = {
            static  = { x = -0.72, y = 0, z = 0.20 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Chest"] = {
            static  = { x = -1, y = 0, z = 0.30 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Shirt"] = {
            static  = { x = -0.25, y = 0, z = -0.10 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Tabard"] = {
            static  = { x = -0.45, y = 0, z = 0.10 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Wrist"] = {
            static  = { x = 0, y = -0.10, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Hands"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Waist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Legs"] = {
            static  = { x = -0.25, y = 0, z = 0.10 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Feet"] = {
            static  = { x = 0.10, y = 0, z = 0.05 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Main Hand"] = {
            static  = { x = -0.70, y = -0.45, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Off-hand"] = {
            static  = { x = -0.60, y = 0.20, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Ranged"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
    },
    ["NightElf"] = {
        ["Head"]     = {
            static  = { x = 0, y =  0, z = -0.45 },
            dynamic = { x = 0, y =  0, z = -0.45 },
        },
        ["Shoulder"] = {
            static  = { x = 0, y = -0.04, z =  0.0 },
            dynamic = { x = 0, y = -0.04, z =  0.0 },
        },
        ["Back"] = {
            static  = { x = -0.90, y = 0, z = 0.25 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Chest"] = {
            static  = { x = -1, y = 0, z = 0.30 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Shirt"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Tabard"] = {
            static  = { x = -0.45, y = 0, z = 0.10 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Wrist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Hands"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Waist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Legs"] = {
            static  = { x = -0.45, y = 0, z = 0.15 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Feet"] = {
            static  = { x = -0.15, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Main Hand"] = {
            static  = { x = -1.08, y = -0.130, z = 0.033 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Off-hand"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Ranged"] = {
            static  = { x = -1.15, y = 0.02, z = 0.113 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
    },
    -- ---- Horde ----
    ["BloodElf"] = {
        ["Head"] = {
            static  = { x = 0, y = 0, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        -- ["Shoulder"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Back"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Chest"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Shirt"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Tabard"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Wrist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Hands"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Waist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Legs"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Feet"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Main Hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Off-hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Ranged"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
    },
    ["Orc"] = {
        ["Head"]     = {
            static  = { x = -0.25, y =  0.15, z = -0.35 },
            dynamic = { x = -0.45, y =  0.00, z = -0.35 },
        },
        ["Shoulder"] = {
            static  = { x = -0.15, y = 0, z = 0 },
            dynamic = { x = -0.35, y = -0.05, z = 0 },
        },
        ["Back"] = {
            static  = { x = -0.95, y = 0, z = 0.20 },
            dynamic = { x = -0.95, y = 0, z = 0.20 },
        },
        ["Chest"] = {
            static  = { x = -1.0, y = 0, z = 0.15 },
            dynamic = { x = -1.30, y = 0, z = 0.15 },
        },
        ["Shirt"] = {
            static  = { x = -0.25, y = 0, z = -0.10 },
            dynamic = { x = -0.25, y = 0, z = 0 },
        },
        ["Tabard"] = {
            static  = { x = -0.50, y = 0, z = 0 },
            dynamic = { x = -0.50, y = 0, z = 0 },
        },
        ["Wrist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = -0.25, y = 0, z = 0 },
        },
        ["Hands"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = -0.35, y = 0.05, z = 0 },
        },
        ["Waist"] = {
            static  = { x = 0, y = 0, z = 0 },
            dynamic = { x = -0.15, y = 0, z = 0 },
        },
        ["Legs"] = {
            static  = { x = -0.50, y = 0, z = 0.10 },
            dynamic = { x = -0.55, y = 0, z = 0 },
        },
        ["Feet"] = {
            static  = { x = -0.15, y = 0, z = -0.03 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Main Hand"] = {
            static  = { x = -0.55, y = -0.15, z = 0 },
            dynamic = { x = 0, y = 0, z = 0 },
        },
        ["Off-hand"] = {
            static  = { x = -0.65, y = 0, z = 0 },
            dynamic = { x = -0.65, y = 0, z = 0 },
        },
        ["Ranged"] = {
            static  = { x = -0.75, y = 0, z = 0 },
            dynamic = { x = -0.75, y = 0, z = 0 },
        },
    },
    ["Scourge"] = {
        ["Head"] = {
            static  = { x = 0, y = 0, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        -- ["Shoulder"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Back"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Chest"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Shirt"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Tabard"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Wrist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Hands"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Waist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Legs"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Feet"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Main Hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Off-hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Ranged"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
    },
    ["Tauren"] = {
        ["Head"] = {
            static  = { x = 0, y = 0, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        -- ["Shoulder"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Back"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Chest"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Shirt"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Tabard"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Wrist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Hands"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Waist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Legs"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Feet"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Main Hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Off-hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Ranged"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
    },
    ["Troll"] = {
        ["Head"] = {
            static  = { x = 0, y = 0, z = -0.35 },
            dynamic = { x = 0, y = 0, z = -0.35 },
        },
        -- ["Shoulder"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Back"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Chest"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Shirt"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Tabard"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Wrist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Hands"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Waist"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Legs"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Feet"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Main Hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Off-hand"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
        -- ["Ranged"] = {
        --     static  = { x = 0, y = 0, z = 0 },
        --     dynamic = { x = 0, y = 0, z = 0 },
        -- },
    },
}

-- ============================================================
-- CALIBRATION SYSTEM  (temporary — remove after tuning)
-- ============================================================
ns.calibrationMode      = false
local _calibDR          = nil     -- DR currently being dragged
local _calibDragging    = false
local _calibBtn         = nil
local _calibCX, _calibCY           = 0, 0
local _calibBX, _calibBY, _calibBZ = 0, 0, 0
local _calibHUD         = nil     -- set by CreatePreviewList
local CALIB_SENS        = 0.008   -- model units per screen pixel (coarse)
local CALIB_SENS_FINE   = 0.002   -- model units per screen pixel (Shift held)
local CALIB_SCROLL_STEP = 0.05    -- model units per scroll tick

-- ============================================================
-- DYNAMIC MODE CAMERA HELPERS
-- ============================================================
local function getMainPreviewZoomOffset()
    if ns.miniPreviewMode ~= "dynamic" then return 0 end
    local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
    if not mainDR then return 0 end
    local x = mainDR:GetPosition()
    x = tonumber(x) or 0
    if x < DYNAMIC_MAIN_X_MIN then x = DYNAMIC_MAIN_X_MIN end
    if x > DYNAMIC_MAIN_X_MAX then x = DYNAMIC_MAIN_X_MAX end
    return x * DYNAMIC_MINI_ZOOM_SYNC_FACTOR
end

local function getDynamicMiniFacing(baseFacing)
    baseFacing = tonumber(baseFacing) or 0
    if ns.miniPreviewMode ~= "dynamic" then
        return baseFacing
    end
    -- Dynamic mode mirrors the main preview's facing exactly.
    local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
    local mainFacing = mainDR and tonumber(mainDR:GetFacing()) or 0
    return mainFacing
end

local function applyMiniPreviewPosition(dr, baseX, baseY, baseZ)
    if not dr then return end
    baseX = tonumber(baseX) or 0
    baseY = tonumber(baseY) or 0
    baseZ = tonumber(baseZ) or 0
    dr._abMiniBaseX = baseX
    dr._abMiniBaseY = baseY
    dr._abMiniBaseZ = baseZ
    local x = baseX + getMainPreviewZoomOffset()
    if x < DYNAMIC_MINI_X_MIN then x = DYNAMIC_MINI_X_MIN end
    if x > DYNAMIC_MINI_X_MAX then x = DYNAMIC_MINI_X_MAX end
    dr:SetPosition(x, baseY, baseZ)
end

-- ============================================================
-- PUBLIC MINI PREVIEW ACCESSORS
-- ============================================================
-- Exported so other panels (e.g. the illusion preview grid) can render their
-- own mini cells using the same per-race / per-sex / per-mode framing the
-- main slot grid uses.  Without these the illusion previews would ignore
-- the user's race tunings and the static/dynamic mode toggle.
function ns.GetMiniPreviewSlotOffset(slotName)
    if not slotName then return 0, 0, 0 end
    local so = SLOT_OFFSETS[slotName]
    local sx = so and so.x or 0
    local sy = so and so.y or 0
    local sz = so and so.z or 0
    local raceData = RACE_SLOT_OFFSETS[_playerRaceFile]
    local sexData  = raceData and raceData[_playerSex]
    local slotData = (sexData and sexData[slotName]) or (raceData and raceData[slotName])
    local isDynamic = ns.miniPreviewMode == "dynamic"
    local modeOff   = slotData and (isDynamic and slotData.dynamic or slotData.static)
    local rx = modeOff and modeOff.x or 0
    local ry = modeOff and modeOff.y or 0
    local rz = modeOff and modeOff.z or 0
    return sx + rx, sy + ry, sz + rz
end

function ns.ApplyMiniPreviewPosition(dr, x, y, z)
    applyMiniPreviewPosition(dr, x, y, z)
end

function ns.GetDynamicMiniFacing(baseFacing)
    return getDynamicMiniFacing(baseFacing)
end

-- ============================================================
-- BACKGROUND TEXTURE SYSTEM
-- ============================================================
-- Tracks every mini dressing-room that has been created so we can re-apply
-- the background texture when the setting changes at runtime.
local allMiniDRs = {}
local currentBgKey = nil  -- last value passed to ns.applyGridBackground

local BG_PATH = "Interface\\AddOns\\AppearanceBuddy\\images\\"

local function addBackgroundTexture(dr)
    local t = dr:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:Hide()
    dr.bgTex = t
end

local function applyBgToOneDR(dr, textureName)
    local t = dr.bgTex
    if not t then return end
    if textureName then
        t:SetTexture(BG_PATH .. textureName)
        t:Show()
        if dr.SetBackdropColor then
            dr:SetBackdropColor(0, 0, 0, 0)
        end
    else
        t:Hide()
        if dr.SetBackdropColor then
            dr:SetBackdropColor(0.25, 0.25, 0.25, 1)
        end
    end
end

-- Called by AppearanceBuddy.lua whenever the setting changes.
-- textureName is a race key ("human", "nightelf", …) or nil/false to hide all.
function ns.applyGridBackground(textureName)
    currentBgKey = textureName
    for _, dr in ipairs(allMiniDRs) do
        applyBgToOneDR(dr, textureName)
    end
end

-- Register any DressingRoom-like frame into the background system.
-- Exposed so Transmog.lua can add the sets preview model without duplicating logic.
function ns.RegisterMiniDR(dr)
    addBackgroundTexture(dr)
    allMiniDRs[#allMiniDRs + 1] = dr
    applyBgToOneDR(dr, currentBgKey)
end

-- ============================================================
-- CELL APPEARANCE CONSTANTS
-- ============================================================
local itemBackdrop = { -- small "DressingRoom"s
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	tile = true, tileSize = 8,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local itemBackdropColor = {0.25, 0.25, 0.25, 1}
local itemBackdropBorderColor = {0.6, 0.52, 0.28, 1}
local selectedItemBackdropBorderColor = {1, 1, 0}

-- Expose the border color table so AppearanceBuddy.lua can mutate it.
-- Mutating itemBackdropBorderColor in-place means all existing unpack()
-- call sites automatically use the new color without any changes.
ns.miniCellBorderColor = itemBackdropBorderColor

function ns.applyMiniCellBorderColor(r, g, b)
    itemBackdropBorderColor[1] = r
    itemBackdropBorderColor[2] = g
    itemBackdropBorderColor[3] = b
    for _, dr in ipairs(allMiniDRs) do
        if not dr._isSelected then
            dr:SetBackdropBorderColor(r, g, b, 1)
        end
    end
end
local itemBorderBackdrop = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local previewHighlightTexture = "Interface\\Buttons\\ButtonHilight-Square"
local PREFETCH_PAGE_RADIUS = 2
local OFFHAND_PREVIEW_CANDIDATE_DELAY_TICKS = 4

-- ============================================================
-- OFF-HAND TRYon SEQUENCER
-- ============================================================
local function makePreviewItemLink(itemId, name)
    return "|Hitem:" .. itemId .. ":0:0:0:0:0:0:0:0:0|h[" .. name .. "]|h"
end

-- Item 25 "Worn Shortsword" — INVTYPE_WEAPONMAINHAND, universally cached.
-- Pre-occupies MH so OH candidates (INVTYPE_WEAPON) route into OH instead of
-- being grabbed by the empty MH slot.  (Custom invisible blockers 144036 /
-- 134546 don't exist on this server's DB and silently no-op.)
local OFFHAND_PREVIEW_MAINHAND_BLOCKER_LINKS = {
    25,
}

local delayedTryOns = {}
local delayedTryOnFrame = CreateFrame("Frame")
delayedTryOnFrame:Hide()
delayedTryOnFrame:SetScript("OnUpdate", function(self)
    local hasPending = false
    for dr, data in pairs(delayedTryOns) do
        if data.ticks > 0 then
            data.ticks = data.ticks - 1
            hasPending = true
        else
            -- Fire next step in the sequence.
            local step = data.steps and data.steps[data.stepIdx]
            if step and dr.itemId == data.itemId and dr:IsShown() then
                if step.kind == "item" then
                    dr:TryOn(step.id)
                elseif step.kind == "blockers" then
                    for _, blocker in ipairs(step.list) do
                        dr:TryOn(blocker)
                    end
                end
            end
            data.stepIdx = (data.stepIdx or 1) + 1
            local nextStep = data.steps and data.steps[data.stepIdx]
            if nextStep then
                data.ticks = nextStep.delay or OFFHAND_PREVIEW_CANDIDATE_DELAY_TICKS
                hasPending = true
            else
                delayedTryOns[dr] = nil
            end
        end
    end
    if not hasPending then
        self:Hide()
    end
end)

local function scheduleTryOnNextFrame(dr, itemId)
    delayedTryOns[dr] = {
        itemId = itemId,
        ticks = OFFHAND_PREVIEW_CANDIDATE_DELAY_TICKS,
        stepIdx = 1,
        steps = { { kind = "item", id = itemId } },
    }
    delayedTryOnFrame:Show()
end

-- Schedule a multi-step sequence that ensures an OH candidate ends up in
-- the off-hand slot:
--   t+delay : TryOn(candidate)         -> may land in MH if MH slot is empty
--             or if blocker hadn't loaded yet
--   t+2*delay: TryOn(blocker) again    -> blocker claims MH and shoves any
--             candidate that ended up there into OH (model's left hand)
local function scheduleOffhandSequence(dr, itemId, blockers)
    delayedTryOns[dr] = {
        itemId = itemId,
        ticks = OFFHAND_PREVIEW_CANDIDATE_DELAY_TICKS,
        stepIdx = 1,
        steps = {
            { kind = "item", id = itemId },
            { kind = "blockers", list = blockers, delay = OFFHAND_PREVIEW_CANDIDATE_DELAY_TICKS },
        },
    }
    delayedTryOnFrame:Show()
end

local function getOffhandPreviewBlockerItem()
    return OFFHAND_PREVIEW_MAINHAND_BLOCKER_LINKS
end

-- ============================================================
-- DRESSING ROOM CALLBACKS & RECYCLER
-- ============================================================
local function getIndexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then return i end
    end
    return nil
end

--[[
    Methods:
        GetPage
        SetPage
        GetPageCount
        SetItems(itemIds) // takes a list of integers
        SetupModel(self, width, height, x, y, z, facing, sequence)
        Update
        TryOn(item)

        Call `Update` method manually after all Set- methods. TryOn 
        items several times in the same frame can give sometimes 
        unexpected result.
]]

local function DressingRoom_OnUpdateModel(self)
    local seq = self:GetParent():GetParent().dressingRoomSetup.sequence
    self:SetSequence(seq)
    self:GetParent()._abMiniSeq = seq
end


local function button_OnClick(self, button)
    local mainFrame = self:GetParent():GetParent()
    local onItemClick = mainFrame.onItemClick
    mainFrame.selectedItemId = self:GetParent().itemId
    mainFrame.selectedItemIndex = self:GetParent().itemIndex
    if mainFrame.selectedItemId ~= nil then
        for _, dr in ipairs(mainFrame.dressingRooms) do
            if dr.itemId == mainFrame.selectedItemId then
                dr._isSelected = true
                if dr._selectionRing then
                    dr._selectionRing:Show()
                end
            else
                dr._isSelected = false
                dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
                if dr._selectionRing then
                    dr._selectionRing:Hide()
                end
                if dr._glowFrame then
                    dr._glowFrame:SetFrameStrata("MEDIUM")
                    dr._glowFrame:Hide()
                end
            end
        end
    end
    if onItemClick ~= nil then
        onItemClick(self, button)
    end
    if button == "LeftButton" then
        PlaySound("gsTitleOptionOK")
    end
end


local function button_OnEnter(self, ...)
    local onEnter = self:GetParent():GetParent().onEnter
    if onEnter ~= nil then
        onEnter(self, ...)
    end
end


local function button_OnLeave(self, ...)
    local onLeave = self:GetParent():GetParent().onLeave
    if onLeave ~= nil then
        onLeave(self, ...)
    end
end

local queryItemHandler  -- forward declaration; assigned below after recycler

-- ============================================================
-- CALIBRATION OVERLAY  (temporary)
-- ============================================================
local function calibOverlay_OnUpdate(self, elapsed)
    -- Keep EnableMouse in sync with calibration mode every frame.
    -- This handles DRs that were recycled / created after the toggle, which
    -- would otherwise sit permanently at EnableMouse(false).
    local want = ns.calibrationMode == true
    if self._calibMouseEnabled ~= want then
        self:EnableMouse(want)
        self:EnableMouseWheel(want)
        self._calibMouseEnabled = want
    end

    if not ns.calibrationMode then
        if _calibDragging and _calibDR == self._dr then
            _calibDragging = false
        end
        return
    end

    -- Fallback drag-start: if OnMouseDown was missed (can happen when the
    -- overlay's EnableMouse was just fixed above), detect the held button
    -- directly.  Only start if this overlay is the active one (_calibDR set
    -- by OnEnter), so we don't accidentally drag a DR the cursor isn't over.
    if not _calibDragging and _calibDR == self._dr then
        local btn = nil
        if     IsMouseButtonDown("LeftButton")  then btn = "LeftButton"
        elseif IsMouseButtonDown("RightButton") then btn = "RightButton"
        end
        if btn then
            _calibDragging = true
            _calibBtn      = btn
            _calibCX, _calibCY = GetCursorPosition()
            _calibBX = self._dr._abMiniBaseX or 0
            _calibBY = self._dr._abMiniBaseY or 0
            _calibBZ = self._dr._abMiniBaseZ or 0
        end
    end

    if not _calibDragging then return end
    -- Auto-clear if the button was released outside the overlay.
    if not IsMouseButtonDown(_calibBtn) then
        _calibDragging = false
        return
    end
    if _calibDR ~= self._dr then return end
    local cx, cy  = GetCursorPosition()
    local scale   = UIParent:GetEffectiveScale()
    local dx      = (cx - _calibCX) / scale
    local dy      = (cy - _calibCY) / scale
    local sens    = IsShiftKeyDown() and CALIB_SENS_FINE or CALIB_SENS
    local newX, newY, newZ
    if _calibBtn == "RightButton" then
        -- Right-drag: Y axis (depth / tilt)
        newX = _calibBX
        newY = _calibBY + dx * CALIB_SENS_FINE
        newZ = _calibBZ
    else
        -- Left-drag: X (horizontal) and Z (vertical)
        newX = _calibBX + dx * sens
        newY = _calibBY
        newZ = _calibBZ + dy * sens
    end
    applyMiniPreviewPosition(self._dr, newX, newY, newZ)
    if _calibHUD then _calibHUD:Refresh() end
end

local function setupCalibrationOverlay(dr)
    local overlay = CreateFrame("Frame", nil, dr)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(dr:GetFrameLevel() + 20)
    overlay:EnableMouse(false)
    overlay:EnableMouseWheel(false)
    overlay._dr = dr

    overlay:SetScript("OnMouseDown", function(self, btn)
        if not ns.calibrationMode then return end
        _calibDR       = dr
        _calibDragging = true
        _calibBtn      = btn
        _calibCX, _calibCY = GetCursorPosition()
        _calibBX = dr._abMiniBaseX or 0
        _calibBY = dr._abMiniBaseY or 0
        _calibBZ = dr._abMiniBaseZ or 0
    end)

    overlay:SetScript("OnMouseUp", function(self)
        _calibDragging = false
    end)

    overlay:SetScript("OnUpdate", calibOverlay_OnUpdate)

    overlay:SetScript("OnMouseWheel", function(self, delta)
        if not ns.calibrationMode then return end
        _calibDR = dr
        applyMiniPreviewPosition(dr,
            (dr._abMiniBaseX or 0) + delta * CALIB_SCROLL_STEP,
            dr._abMiniBaseY or 0,
            dr._abMiniBaseZ or 0)
        if _calibHUD then _calibHUD:Refresh() end
    end)

    -- Show HUD immediately on hover so pre-existing values are visible
    -- before any drag happens.
    overlay:SetScript("OnEnter", function(self)
        if not ns.calibrationMode then return end
        _calibDR = dr
        if _calibHUD then _calibHUD:Refresh() end
    end)

    dr.calibOverlay = overlay
end

local recycler = {
    ["recycled"] = {},
    ["counter"] = 0,

    ["get"] = function(self, parent, number)
        local result = {}
        while #result < number do
            if self.recycled[parent] == nil then self.recycled[parent] = {} end
            local recycled = self.recycled[parent]
            if #recycled > 0 then
                table.insert(result, table.remove(recycled))
            else
                self.counter = self.counter + 1
                local dr = ns.CreateDressingRoom("$parentDressingRoom"..self.counter, parent)
                dr:SetBackdrop(itemBackdrop)
                dr:SetBackdropColor(unpack(itemBackdropColor))
                -- Border: 4 OVERLAY textures created on dr.model (the DressUpModel child).
                -- Child frames of DressUpModel at OVERLAY sublayer render above the 3D
                -- scene.  Sibling frames do not — WoW composites the DressUpModel 3D
                -- scene above all UI siblings regardless of frame level.
                -- Being children of dr.model they auto-hide/show with dr.  No separate
                -- borderFrame, no Show/Hide hooks, no strata management needed.
                local _T = 2
                -- Border: textures on a child Frame of dr.model (NOT directly on dr.model).
                -- WoW resets vertex colors of textures placed directly on a DressUpModel
                -- whenever it re-renders geometry (TryOn, Undress, Reset, SetUnit).
                -- Textures on a child Frame of the DressUpModel are unaffected, matching
                -- how DressingRoom.lua's dbgFrame/dbgInfo pattern works.
                local _T = 2
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
                _eTop:SetHeight(_T)
                _eBottom:SetTexture(_r, _g, _b, _a)
                _eBottom:SetPoint("BOTTOMLEFT",  borderHolder, "BOTTOMLEFT",  0, 0)
                _eBottom:SetPoint("BOTTOMRIGHT", borderHolder, "BOTTOMRIGHT", 0, 0)
                _eBottom:SetHeight(_T)
                _eLeft:SetTexture(_r, _g, _b, _a)
                _eLeft:SetPoint("TOPLEFT",    borderHolder, "TOPLEFT",    0, 0)
                _eLeft:SetPoint("BOTTOMLEFT", borderHolder, "BOTTOMLEFT", 0, 0)
                _eLeft:SetWidth(_T)
                _eRight:SetTexture(_r, _g, _b, _a)
                _eRight:SetPoint("TOPRIGHT",    borderHolder, "TOPRIGHT",    0, 0)
                _eRight:SetPoint("BOTTOMRIGHT", borderHolder, "BOTTOMRIGHT", 0, 0)
                _eRight:SetWidth(_T)
                dr._borderEdges = {_eTop, _eBottom, _eLeft, _eRight}
                -- SetBackdropBorderColor is the existing call-site API; forward to edges.
                function dr:SetBackdropBorderColor(r, g, b, a)
                    a = a or 1
                    for _, e in ipairs(self._borderEdges) do e:SetTexture(r, g, b, a) end
                end
                dr._reapplyBorderColor = nil  -- no longer needed; child frame is stable
                -- Pulse the border gold when selected; restore gold when deselected.
                dr._isSelected = false
                local pulseT = 0
                dr:HookScript("OnUpdate", function(self, elapsed)
                    if not self._isSelected then return end
                    pulseT = pulseT + elapsed
                    local v = math.abs(math.sin(pulseT * 3))
                    self:SetBackdropBorderColor(1, 0.85 * v + 0.15, 0, 1)
                end)
                -- Reapply gold on every Show: child texture vertex colors can reset
                -- to white {1,1,1,1} when a hidden frame becomes visible.
                dr:HookScript("OnShow", function(self)
                    if not self._isSelected then
                        self:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
                    end
                end)
                dr._selectionRing = nil  -- no separate ring; border edges used for selection
                dr:EnableDragRotation(false)
                dr:EnableMouseWheel(false)
                addBackgroundTexture(dr)
                allMiniDRs[#allMiniDRs + 1] = dr
                applyBgToOneDR(dr, currentBgKey)
                dr.queriedLabel = dr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                dr.queriedLabel:SetJustifyH("LEFT")
                dr.queriedLabel:SetHeight(18)
                dr.queriedLabel:SetPoint("CENTER", dr, "CENTER", 0, 0)
                dr.queriedLabel:SetText(ABL("Queried..."))
                dr.queriedLabel:Hide()
                dr.queryFailedLabel = dr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                dr.queryFailedLabel:SetJustifyH("LEFT")
                dr.queryFailedLabel:SetHeight(18)
                dr.queryFailedLabel:SetPoint("CENTER", dr, "CENTER", 0, 0)
                dr.queryFailedLabel:SetText(ABL("Query failed"))
                dr.queryFailedLabel:Hide()
                local btn = CreateFrame("Button", "$parent".."Button", dr)
                btn:SetAllPoints()
                btn:SetHighlightTexture(previewHighlightTexture)
                btn:EnableMouse(true)
                btn:RegisterForClicks("LeftButtonUp")
                btn:SetScript("OnEnter", button_OnEnter)
                btn:SetScript("OnLeave", button_OnLeave)
                btn:SetScript("OnClick", button_OnClick)
                dr.queryHandler = {["dressingRoom"] = dr, ["__call"] = queryItemHandler}
                setmetatable(dr.queryHandler, dr.queryHandler)
                dr.button = btn
                setupCalibrationOverlay(dr)
                table.insert(result, 1, dr)
            end
        end
        return result
    end,

    ["recycle"] = function(self, parent, dr)
        if self.recycled[parent] == nil then self.recycled[parent] = {} end
        local recycled = self.recycled[parent]
        for i, v in pairs(recycled) do
            assert(dr ~= v, "Double recycling.")
        end
        dr:ClearModel()
        dr:Hide()
        dr._needsReset = true
        table.insert(recycled, dr)
    end,
}


-- ============================================================
-- PREVIEWLIST METHODS
-- ============================================================
local function PreviewList_SetItems(self, itemIds)
    table.wipe(self.itemIds)
    for i=1, #itemIds do
        table.insert(self.itemIds, itemIds[i])
    end
    self.selectedItemId = nil
    self.selectedItemIndex = nil
    --if self.dressingRoomSetup ~= nil then
    --    self:Update()
    --end
end


local function PreviewList_SetupModel(self, width, height, x, y, z, facing, sequence)
    assert(#self.itemIds > 0, "`SetItems` first.")
    local setup = self.dressingRoomSetup
    if not setup then
        setup = {}
        self.dressingRoomSetup = setup
    end
    setup.width = width
    setup.height = height
    setup.x = x
    setup.y = y
    setup.z = z
    setup.facing = facing
    setup.sequence = sequence
    -- Keep the zoom baseline stable across page rebuilds.  The main dressing
    -- room's default transmog view is x=0; using the current main x here would
    -- make every page swap treat the player's zoom as the new default and
    -- snap mini previews back to the unzoomed framing.
    self._mainPreviewBaseX = 0
    local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
    self._mainPreviewBaseFacing = mainDR and mainDR:GetFacing() or 0
    local listW = self:GetWidth()
    local listH = self:GetHeight()
    local countW = (listW > 0 and listH > 0) and math.floor(listW / width)  or 0
    local countH = (listW > 0 and listH > 0) and math.floor(listH / height) or 0
    local perPage = countW * countH
    -- Only write layout geometry when we have valid frame dimensions.
    -- If GetWidth/Height return 0 (frame not yet laid out), keep the last
    -- good values so Update() doesn't corrupt positioning with NaN offsets.
    if perPage > 0 then
        setup.countW = countW
        setup.countH = countH
        setup.gapW = (listW - countW * width)  / 2
        setup.gapH = (listH - countH * height) / 2
    end
    if perPage > 0 then
        if #self.dressingRooms < perPage then
            local list = recycler:get(self, perPage - #self.dressingRooms)
            while #list > 0 do
                local dr = table.remove(list)
                dr:SetWidth(width)
                dr:SetHeight(height)
                table.insert(self.dressingRooms, dr)
            end
        elseif #self.dressingRooms > perPage then
            while #self.dressingRooms > perPage do
                local dr = table.remove(self.dressingRooms)
                dr:OnUpdateModel(nil)
                recycler:recycle(self, dr)
            end
        end
        -- Size DRs only; Update() will set positions with proper centering.
        for _, dr in ipairs(self.dressingRooms) do
            dr:SetSize(width, height)
            dr.itemId = nil
            dr.itemIndex = nil
            dr.isQuerying = false
            delayedTryOns[dr] = nil
            dr.queryRetryCount = 0
            dr._isSelected = false
            dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
            if dr._selectionRing then dr._selectionRing:Hide() end
            if dr._glowFrame then
                dr._glowFrame:SetFrameStrata("MEDIUM")
                dr._glowFrame:Hide()
            end
        end
    end
end


local function PreviewList_SetPage(self, page)
    assert(type(page) == "number", "`page` must be a positive number.")
    self.currentPage = page
end


local function PreviewList_GetPage(self)
    return self.currentPage
end


local function PreviewList_GetPageCount(self)
    if #self.itemIds == 0 or #self.dressingRooms == 0 then
        return 0
    end
    return math.ceil(#self.itemIds/#self.dressingRooms)
end


-- ============================================================
-- RENDER
-- ============================================================
local function renderPreviewItem(dr, itemId, offhandBlockerItem)
    dr:Show()
    -- Reapply border color: child texture vertex colors can reset to white on Show.
    if not dr._isSelected then
        dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
    end
    dr.queriedLabel:Hide()
    dr.queryFailedLabel:Hide()
    -- dr:Reset() re-fires SetUnit("player") which kicks off a multi-stage
    -- async load of the player's real gear.  On certain models that load
    -- never fully settles — the engine keeps re-attaching player gear over
    -- our preview, producing visible twitching.  Only Reset on the very
    -- first render of a (re)acquired DR; subsequent renders just Undress
    -- and re-dress, keeping the model in a stable steady state.
    if dr._needsReset ~= false then
        dr:Reset()
        dr._needsReset = false
    end
    local list = dr:GetParent()
    local hiddenSlots = list.hiddenSlots or {}
    dr:Undress()
    local setup = list.dressingRoomSetup
    dr._abMiniBaseFacing = setup.facing or 0
    local so          = SLOT_OFFSETS[list.currentSlot]
    local slotXOffset = so and so.x or 0
    local slotYOffset = so and so.y or 0
    local slotZOffset = so and so.z or 0
    local isDynamic   = ns.miniPreviewMode == "dynamic"
    local raceData    = RACE_SLOT_OFFSETS[_playerRaceFile]
    local sexData     = raceData and raceData[_playerSex]
    local slotKey     = list.currentSlot
    local slotData    = (sexData and sexData[slotKey]) or (raceData and raceData[slotKey])
    local modeOff     = slotData and (isDynamic and slotData.dynamic or slotData.static)
    local raceXOffset = modeOff and modeOff.x or 0
    local raceYOffset = modeOff and modeOff.y or 0
    local raceZOffset = modeOff and modeOff.z or 0
    -- Store the no-race-offset base so calibration HUD/Copy can compute the
    -- correct race delta regardless of which slot key was used.
    dr._abCalibBaseX    = setup.x + slotXOffset
    dr._abCalibBaseY    = getMiniPreviewY(setup.y) + slotYOffset
    dr._abCalibBaseZ    = setup.z + slotZOffset
    dr._abCalibSlotKey  = slotKey
    applyMiniPreviewPosition(dr,
        dr._abCalibBaseX + raceXOffset,
        dr._abCalibBaseY + raceYOffset,
        dr._abCalibBaseZ + raceZOffset)
    dr:SetFacing(getDynamicMiniFacing(dr._abMiniBaseFacing))

    -- Off-hand preview: pin the candidate directly to the off-hand slot.
    -- This matches the main preview path and avoids the dummy-mainhand
    -- blocker leaking into list cells as a generic sword model.
    if list.currentSlot == "Off-hand" then
        local ohKey = getOffhandSubclassKey(itemId)
        local isOHWeapon = ohKey ~= nil and ohKey ~= "Shield" and ohKey ~= "Held in Off-hand"

        -- For actual weapons in the off-hand slot, mirror the Main Hand
        -- static/dynamic framing exactly: use the Main Hand slot setup from
        -- PreviewSetupDB and a plain TryOn so the weapon lands in the
        -- main-hand attachment point (right hand), matching Main Hand cells.
        -- Shields and Held-in-Off-hand items keep their own dedicated framing.
        -- Weapons and shields use "Main Hand" for the PreviewSetupDB lookup
        -- so they share MH base framing. "Held in Off-hand" uses its own
        -- "Off-hand" DB entry so facing/sequence are correct — otherwise
        -- perItem is nil and the model spazzes on a bad default animation.
        -- RACE_SLOT_OFFSETS["Off-hand"] is reserved for "Held in Off-hand"
        -- only; weapons (and shields for race offsets) use "Main Hand" offsets.
        -- DB lookup: both Shield and Held in Off-hand have entries under
        -- ["Off-hand"] in PreviewSetupDB; weapons use ["Main Hand"].
        local perItemDbSlot = (ohKey == "Held in Off-hand" or ohKey == "Shield") and "Off-hand" or "Main Hand"
        local perItem
        if ohKey then
            local version = ns.GetPreviewSetupVersion and ns.GetPreviewSetupVersion() or "classic"
            perItem = ns.GetPreviewSetup and ns.GetPreviewSetup(version, _playerRaceFile, _playerSex, perItemDbSlot, ohKey) or nil
        end
        if perItem then
            local staticZoomFactor = ns.miniPreviewMode == "dynamic" and 1 or 0.86
            local perItemX = tonumber(perItem.x)
            local perItemY = tonumber(perItem.y)
            local perItemZ = tonumber(perItem.z)
            dr._abMiniBaseFacing = tonumber(perItem.facing) or setup.facing or 0
            -- Race offset key: shields and Held-in-Off-hand both use "Off-hand".
            -- OH weapons (which mirror MH framing) use "Main Hand".
            local ohSlotKey  = (ohKey == "Held in Off-hand" or ohKey == "Shield") and "Off-hand" or "Main Hand"
            local ohSlotData = (sexData and sexData[ohSlotKey]) or (raceData and raceData[ohSlotKey])
            local ohModeOff  = ohSlotData and (isDynamic and ohSlotData.dynamic or ohSlotData.static)
            local ohRaceX    = ohModeOff and ohModeOff.x or 0
            local ohRaceY    = ohModeOff and ohModeOff.y or 0
            local ohRaceZ    = ohModeOff and ohModeOff.z or 0
            local ohSlotOff  = SLOT_OFFSETS[ohSlotKey]
            local ohSlotX    = ohSlotOff and ohSlotOff.x or 0
            local ohSlotY    = ohSlotOff and ohSlotOff.y or 0
            local ohSlotZ    = ohSlotOff and ohSlotOff.z or 0
            -- Store the no-race-offset base for calibration HUD/Copy.
            dr._abCalibBaseX   = perItemX and (perItemX * staticZoomFactor * getMiniPreviewMaxZoom()) + ohSlotX or setup.x
            dr._abCalibBaseY   = perItemY and (perItemY + getMiniPreviewPositionAdjust()) + ohSlotY or setup.y
            dr._abCalibBaseZ   = perItemZ and (perItemZ + getMiniPreviewVerticalAdjust()) + ohSlotZ or setup.z
            dr._abCalibSlotKey = ohSlotKey
            applyMiniPreviewPosition(
                dr,
                dr._abCalibBaseX + ohRaceX,
                dr._abCalibBaseY + ohRaceY,
                dr._abCalibBaseZ + ohRaceZ)
            dr:SetFacing(getDynamicMiniFacing(dr._abMiniBaseFacing))
        end

        if isOHWeapon then
            -- Weapon: mirror Main Hand — plain TryOn routes the item into the
            -- right-hand slot on an undressed model, matching MH framing.
            -- No SECONDARYHANDSLOT, no blocker sequence needed.
            scheduleTryOnNextFrame(dr, itemId)
        elseif ns.miniPreviewMode == "dynamic" then
            dr:TryOn(itemId, "SECONDARYHANDSLOT")
        else
            -- WotLK's DressUpModel does not reliably honour the explicit
            -- secondary-hand slot in static mini cards.  Use the blocker
            -- sequence: candidate first, then a cached MH blocker to force the
            -- candidate into the off-hand attachment point.
            -- Shields and held-in-off-hand items route to OH naturally — skip
            -- the blocker so a stray sword model doesn't appear in the MH.
            if ohKey == "Shield" or ohKey == "Held in Off-hand" then
                scheduleTryOnNextFrame(dr, itemId)
            else
                scheduleOffhandSequence(dr, itemId, getOffhandPreviewBlockerItem())
            end
        end

        if dr._itemModel then dr._itemModel:Hide() end
        dr.button:Show()
        dr:OnUpdateModel(function(self)
            local seq = (perItem and tonumber(perItem.sequence))
                or (self:GetParent() and self:GetParent().dressingRoomSetup
                    and self:GetParent().dressingRoomSetup.sequence)
                or 0
            self:SetSequence(seq)
            self:GetParent()._abMiniSeq = seq
            if not dr._isSelected then
                dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
            end
        end)
        if list and list.onVisibleItem then
            list:onVisibleItem(dr)
        end
        return
    end

    if not ns.itemOnlyView then
        local outfitItems = list.tryOnItems
        if outfitItems then
            for _, outfitId in ipairs(outfitItems) do
                dr:TryOn(outfitId)
            end
        end
    end

    if list.currentSlot == "Main Hand" and not hiddenSlots["Off-hand"]
        and ns.showOffhandInMainhandPreview then
        local ohItem = GetInventoryItemID and GetInventoryItemID("player", 17)
        if ohItem then
            local ohEquipLoc = select(9, GetItemInfo(ohItem)) or ""
            if ohEquipLoc == "INVTYPE_WEAPON"
                or ohEquipLoc == "INVTYPE_WEAPONOFFHAND"
                or ohEquipLoc == "INVTYPE_SHIELD"
                or ohEquipLoc == "INVTYPE_HOLDABLE"
            then
                dr:TryOn(ohItem)
            end
        end
    end

    dr:TryOn(itemId)
    if dr._itemModel then dr._itemModel:Hide() end
    dr.button:Show()
    dr:OnUpdateModel(function(self)
        DressingRoom_OnUpdateModel(self)
        if not dr._isSelected then
            dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
        end
    end)
    if list and list.onVisibleItem then
        list:onVisibleItem(dr)
    end
end


-- ============================================================
-- QUERY CALLBACK
-- ============================================================
queryItemHandler = function(functable, itemId, success)
    local dr = functable.dressingRoom
    if dr.itemId == itemId then
        dr.isQuerying = false
        if success then
            -- Clear item from failure blacklist if it loaded on a retry.
            if ns.queryFailedItemIds then
                ns.queryFailedItemIds[itemId] = nil
            end
            local list = dr:GetParent()
            if list.currentSlot == "Off-hand" then
                renderPreviewItem(dr, itemId)
                return
            end
            renderPreviewItem(dr, itemId)
            return
        else
            -- Item failed to load.  Only retry if at least one sibling on
            -- this page already rendered (meaning items ARE loadable but this
            -- one was slow due to cache saturation from fast scrolling).
            -- If nothing on the page has rendered, this is likely a ghost
            -- page full of unloadable custom items — fail fast.
            local retries = dr.queryRetryCount or 0
            local anySiblingLoaded = false
            if retries < 1 then
                local list = dr:GetParent()
                if list then
                    for _, sibling in ipairs(list.dressingRooms) do
                        if sibling ~= dr and sibling.itemId and not sibling.isQuerying and sibling:IsShown() then
                            anySiblingLoaded = true
                            break
                        end
                    end
                end
            end
            if retries < 1 and anySiblingLoaded then
                dr.queryRetryCount = retries + 1
                -- Keep isQuerying true; defer the re-queue to the next frame
                -- so the expired handler is fully removed before ns.QueryItem
                -- re-adds it.  Calling ns.QueryItem directly here would find
                -- the same handler still in queries[], reset its timer, then
                -- have tremove immediately discard it — no SetHyperlink sent.
                if ns.QueryItemRetry then
                    ns.QueryItemRetry(itemId, dr.queryHandler)
                else
                    ns.QueryItem(itemId, dr.queryHandler)
                end
            else
                -- No sibling loaded (ghost page) or already retried.
                -- Only blacklist if the item genuinely does not exist in the
                -- client DBC.  GetItemIcon reads the MPQ directly and returns
                -- nil only when the item has no DBC entry at all.
                -- A QueryItem timeout just means the server was slow; adding
                -- those items to AppearanceBuddyBlacklist (SavedVariables)
                -- would grow the excludeList sent to the server on every
                -- request, causing it to compute lower totalPages permanently
                -- across sessions — the "slowly shrinking page count" bug.
                local existsInDBC = GetItemIcon and GetItemIcon(itemId) ~= nil
                if not existsInDBC then
                    -- Item is absent from client DBC — safe to blacklist.
                    if not ns.queryFailedItemIds then
                        _G["AppearanceBuddyBlacklist"] = _G["AppearanceBuddyBlacklist"] or {}
                        ns.queryFailedItemIds = _G["AppearanceBuddyBlacklist"]
                        ns.queryFailedCount = ns.queryFailedCount or 0
                    end
                    if (ns.queryFailedCount or 0) < (ns.C and ns.C.BLACKLIST_MAX_ENTRIES or 2000) then
                        ns.queryFailedItemIds[itemId] = true
                        ns.queryFailedCount = (ns.queryFailedCount or 0) + 1
                    end
                end
                -- In both cases hide the cell for this render cycle.
                -- Non-blacklisted items will be re-requested correctly on the
                -- next page visit once the server has had more time to respond.
                dr.isQuerying = false
                dr.queriedLabel:Hide()
                dr.queryFailedLabel:Hide()
                dr.button:Hide()
                dr:ClearModel()
                dr:Hide()
                dr.itemId = nil
                local list = dr:GetParent()
                if list and list.onVisibleItem then
                    list:onVisibleItem(dr)
                end
            end
        end
    end
end

-- ============================================================
-- UPDATE
-- ============================================================
local function PreviewList_Update(self)
    assert(self.dressingRoomSetup ~= nil, "`SetupModel` first.")
    assert(#self.itemIds > 0, "`SetItems` first.")
    local perPage = #self.dressingRooms
    local setup = self.dressingRoomSetup
    local countW = setup.countW or 1
    local gapW   = setup.gapW or 0
    local gapH   = setup.gapH or 0

    -- Count how many items are visible on this page (may be < perPage on last page).
    local itemsThisPage = 0
    local visibleItems = 0
    for i = 1, perPage do
        local itemIndex = (self.currentPage - 1) * perPage + i
        if self.itemIds[itemIndex] ~= nil then
            itemsThisPage = i
        end
    end
    for i = 1, perPage do
        local dr = self.dressingRooms[i]
        local itemIndex = (self.currentPage - 1) * perPage + i
        local itemId = self.itemIds[itemIndex]

        -- Position this DR.
        local col = (i - 1) % countW
        local row = math_floor((i - 1) / countW)
        local xOffset = gapW + col * setup.width
        local yOffset = gapH + row * setup.height
        dr:ClearAllPoints()
        dr:SetPoint("TOPLEFT", self, "TOPLEFT", xOffset, -yOffset)

        if itemId == nil then
            dr.itemId = nil
            dr.itemIndex = nil
            dr.isQuerying = false
            delayedTryOns[dr] = nil
            dr.button:Hide()
            dr.queriedLabel:Hide()
            dr.queryFailedLabel:Hide()
            dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
            dr:OnUpdateModel(nil)
            dr:ClearModel()
            dr:Hide()
        else
            dr.itemId = itemId
            dr.itemIndex = itemIndex
            dr.isQuerying = true
            delayedTryOns[dr] = nil
            dr.queryRetryCount = 0
            dr.button:Hide()
            dr.queriedLabel:Hide()
            dr.queryFailedLabel:Hide()
            dr:OnUpdateModel(nil)
            dr._needsReset = true
            dr:ClearModel()
            -- Show the cell immediately with its backdrop/background as a
            -- placeholder while the model loads asynchronously.  The 3D model
            -- area is transparent when no model is loaded, so only the
            -- background texture (or grey fill) is visible.  This eliminates
            -- the blank-grid flash while waiting for GetItemInfo to resolve.
            -- The button is still hidden, so clicks are ignored until
            -- renderPreviewItem shows the loaded model.
            dr:Show()
            local handler = dr.queryHandler
            ns.QueryItem(itemId, handler)
            -- Count as visible immediately: the placeholder cell is shown.
            visibleItems = visibleItems + 1
            if dr.itemId == self.selectedItemId then
                dr._isSelected = true
                dr:SetBackdropBorderColor(unpack(selectedItemBackdropBorderColor))
            else
                dr._isSelected = false
                dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
            end
        end
    end
    if self.onLoadingStateChanged then
        self:onLoadingStateChanged(visibleItems, itemsThisPage)
    end
    -- Pre-fetch surrounding pages into WoW's item cache so fast paging lands on
    -- already-warmed items more often instead of showing loading placeholders.
    for pageOffset = 1, PREFETCH_PAGE_RADIUS do
        local nextStart = (self.currentPage + pageOffset - 1) * perPage + 1
        for j = nextStart, math_min(nextStart + perPage - 1, #self.itemIds) do
            ns.QueryItem(self.itemIds[j])
        end

        local prevPage = self.currentPage - pageOffset
        if prevPage >= 1 then
            local prevStart = (prevPage - 1) * perPage + 1
            for j = prevStart, math_min(prevStart + perPage - 1, #self.itemIds) do
                ns.QueryItem(self.itemIds[j])
            end
        end
    end
end


local function PreviewList_SelectByItemId(self, itemId)
    local index = getIndexOf(self.itemIds, itemId)
    if index ~= nil then
        self.selectedItemId = itemId
        self.selectedItemIndex = index
        for _, dr in ipairs(self.dressingRooms) do
            if dr.itemId == itemId then
                dr._isSelected = true
                dr:SetBackdropBorderColor(unpack(selectedItemBackdropBorderColor))
            else
                dr._isSelected = false
                dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
            end
        end
    end
end


local function PreviewList_TryOn(self, item)
    self.tryOnItem = item
    if item ~= nil then
        for i, dr in ipairs(self.dressingRooms) do
            if dr:IsVisible() and not dr.isQuerying then
                dr:TryOn(item)
            end
        end
    end
end


-- ============================================================
-- CONSTRUCTOR
-- ============================================================
function ns.CreatePreviewList(parent)
    local frameName = nil
    if parent and parent.GetName then
        local parentName = parent:GetName()
        if parentName and parentName ~= "" then
            frameName = parentName.."PreviewList"
        end
    end

    local frame = CreateFrame("Frame", frameName, parent)

    frame.itemIds = {}
    frame.dressingRooms = {}
    frame.currentPage = 1
    frame.dressingRoomSetup = nil
    --[[
    frame.dressingRoomSetup = {
        ["width"] = 0,
        ["height"] = 0,
        ["x"] = 0.0,
        ["y"] = 0.0,
        ["z"] = 0.0,
        ["facing"] = 0.0,
        ["sequence"] = 0,
    }]]
    frame.onEnter = nil
    frame.onLeave = nil
    frame.onItemClick = nil
    frame.onBackgroundClick = nil
    frame.onVisibleItem = nil
    frame.onLoadingStateChanged = nil

    frame.selectedItemId = nil
    frame.selectedItemIndex = nil

    frame.SetItems = PreviewList_SetItems
    frame.Update = PreviewList_Update
    frame.SetupModel = PreviewList_SetupModel
    frame.GetPage = PreviewList_GetPage
    frame.SetPage = PreviewList_SetPage
    frame.GetPageCount = PreviewList_GetPageCount
    frame.SelectByItemId = PreviewList_SelectByItemId
    frame.TryOn = PreviewList_TryOn

    function frame:Deselect()
        self.selectedItemId = nil
        self.selectedItemIndex = nil
        for _, dr in ipairs(self.dressingRooms) do
            dr._isSelected = false
            dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
            if dr._selectionRing then dr._selectionRing:Hide() end
        end
        if self.onBackgroundClick then
            self.onBackgroundClick(self)
        end
    end

    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Clear selection highlight only. Do NOT call onBackgroundClick here —
            -- that would revert the main preview to the restore state, which is
            -- unwanted when the user accidentally clicks empty space.
            self.selectedItemId = nil
            self.selectedItemIndex = nil
            for _, dr in ipairs(self.dressingRooms) do
                dr._isSelected = false
                dr:SetBackdropBorderColor(unpack(itemBackdropBorderColor))
                if dr._selectionRing then dr._selectionRing:Hide() end
            end
        elseif button == "MiddleButton" then
            -- In dynamic mode, middle-clicking any mini model resets the main
            -- dressing room zoom back to home (0), exactly like middle-clicking
            -- the main dressing room itself.  The OnUpdate sync then propagates
            -- the animated zoom back to all mini cells automatically.
            if ns.miniPreviewMode == "dynamic" then
                local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
                if mainDR and mainDR.SmoothZoomReset then
                    mainDR:SmoothZoomReset()
                end
            end
        end
    end)

    frame:SetScript("OnShow", function(self)
        if self.dressingRoomSetup ~= nil then
            self:Update()
        end
    end)

    -- In dynamic mode: mirror the main dressing room's rotation, zoom, and
    -- vertical pan each frame. In static mode: mini cells use their fixed
    -- slot-specific PreviewSetupDB framing and this handler returns immediately.
    frame:SetScript("OnUpdate", function(self)
        if ns.miniPreviewMode ~= "dynamic" then return end
        local mainDR = ns.mainFrame and ns.mainFrame.dressingRoom
        if not mainDR then return end
        local setup = self.dressingRoomSetup or {}
        local drs = self.dressingRooms
        for i = 1, #drs do
            local dr = drs[i]
            if dr:IsShown() then
                local baseFacing = dr._abMiniBaseFacing ~= nil and dr._abMiniBaseFacing or (setup.facing or 0)
                local baseX = dr._abMiniBaseX ~= nil and dr._abMiniBaseX or (setup.x or 0)
                local baseY = dr._abMiniBaseY ~= nil and dr._abMiniBaseY or getMiniPreviewY(setup.y)
                local baseZ = dr._abMiniBaseZ ~= nil and dr._abMiniBaseZ or (setup.z or 0)
                dr:SetFacing(getDynamicMiniFacing(baseFacing))
                local x = baseX + getMainPreviewZoomOffset()
                if x < DYNAMIC_MINI_X_MIN then x = DYNAMIC_MINI_X_MIN end
                if x > DYNAMIC_MINI_X_MAX then x = DYNAMIC_MINI_X_MAX end
                dr:SetPosition(x, baseY, baseZ)
            end
        end
    end)

    -- ---- Calibration UI (temporary — remove after tuning) ----
    do
        local calibBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        calibBtn:SetSize(110, 20)
        -- Anchor is set by the caller (Transmog.lua) after CreatePreviewList returns.
        calibBtn:SetText(ABL("Calibrate: OFF"))
        frame.calibBtn = calibBtn

        local hud = CreateFrame("Frame", nil, frame)
        hud:SetPoint("TOPLEFT",  calibBtn, "BOTTOMLEFT",  0, -2)
        hud:SetPoint("TOPRIGHT", frame,    "BOTTOMRIGHT", 0, -26)
        hud:SetHeight(22)
        hud:Hide()
        _calibHUD = hud

        local hudText = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hudText:SetPoint("LEFT", hud, "LEFT", 4, 0)
        hudText:SetPoint("RIGHT", hud, "RIGHT", 0, 0)
        hudText:SetJustifyH("LEFT")

        -- Copy button: always visible next to calibBtn (not inside hud).
        local copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        copyBtn:SetSize(58, 20)
        copyBtn:SetText(ABL("Copy"))
        copyBtn:Hide()
        frame.calibCopyBtn = copyBtn

        -- Popup dialog for copy-paste (Ctrl+A / Ctrl+C friendly)
        local calibCopyDialog = CreateFrame("Frame", nil, UIParent)
        calibCopyDialog:SetSize(440, 90)
        calibCopyDialog:SetPoint("CENTER", UIParent, "CENTER")
        calibCopyDialog:SetFrameStrata("DIALOG")
        calibCopyDialog:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        calibCopyDialog:SetMovable(true)
        calibCopyDialog:EnableMouse(true)
        calibCopyDialog:RegisterForDrag("LeftButton")
        calibCopyDialog:SetScript("OnDragStart", calibCopyDialog.StartMoving)
        calibCopyDialog:SetScript("OnDragStop",  calibCopyDialog.StopMovingOrSizing)
        calibCopyDialog:Hide()
        do
            local title = calibCopyDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOP", calibCopyDialog, "TOP", 0, -14)
            title:SetText(ABL("Calibration Value"))
        end
        local calibEditBox = CreateFrame("EditBox", nil, calibCopyDialog, "InputBoxTemplate")
        calibEditBox:SetSize(400, 24)
        calibEditBox:SetPoint("CENTER", calibCopyDialog, "CENTER", 0, -8)
        calibEditBox:SetAutoFocus(false)
        calibEditBox:SetScript("OnEscapePressed", function(self) calibCopyDialog:Hide() end)
        calibEditBox:SetScript("OnShow", function(self)
            self:SetFocus()
            self:HighlightText()
        end)
        calibCopyDialog:SetScript("OnShow", function(self)
            calibEditBox:SetFocus()
            calibEditBox:HighlightText()
        end)

        -- copyBtn is created above (parented to frame); wire its OnClick here.
        copyBtn:SetPoint("LEFT", calibBtn, "RIGHT", 4, 0)
        copyBtn:SetScript("OnClick", function()
            if not _calibDR then return end
            local rx  = (_calibDR._abMiniBaseX or 0) - (_calibDR._abCalibBaseX or 0)
            local ry  = (_calibDR._abMiniBaseY or 0) - (_calibDR._abCalibBaseY or 0)
            local rz  = (_calibDR._abMiniBaseZ or 0) - (_calibDR._abCalibBaseZ or 0)
            local mode     = ns.miniPreviewMode == "dynamic" and "dynamic" or "static"
            local slotKey  = _calibDR._abCalibSlotKey or "?"
            local txt = string.format(
                '        -- ["%s"]["%s"]\n        %s  = { x = %.3f, y = %.3f, z = %.3f },',
                _playerRaceFile, slotKey, mode, rx, ry, rz)
            calibEditBox:SetText(txt)
            calibCopyDialog:Show()
            calibEditBox:SetFocus()
            calibEditBox:HighlightText()
        end)

        function hud:Refresh()
            if not _calibDR then self:Hide(); return end
            local rx  = (_calibDR._abMiniBaseX or 0) - (_calibDR._abCalibBaseX or 0)
            local ry  = (_calibDR._abMiniBaseY or 0) - (_calibDR._abCalibBaseY or 0)
            local rz  = (_calibDR._abMiniBaseZ or 0) - (_calibDR._abCalibBaseZ or 0)
            local seq = _calibDR._abMiniSeq
            local mode = ns.miniPreviewMode == "dynamic" and "dynamic" or "static"
            local seqStr  = seq and ("seq="..seq) or mode
            local slotKey = _calibDR._abCalibSlotKey or ((_calibDR:GetParent() and _calibDR:GetParent().currentSlot) or "?")
            hudText:SetText(string.format(
                "[%s][\"%s\"].%s  %s  x=%.3f  y=%.3f  z=%.3f",
                _playerRaceFile, slotKey, mode, seqStr, rx, ry, rz))
            self:Show()
        end

        calibBtn:SetScript("OnClick", function()
            ns.calibrationMode = not ns.calibrationMode
            if ns.calibrationMode then
                calibBtn:SetText("|cff00FF00Calibrate: ON|r")
                copyBtn:Show()
                for _, dr in ipairs(frame.dressingRooms) do
                    if dr.calibOverlay then
                        dr.calibOverlay:EnableMouse(true)
                        dr.calibOverlay:EnableMouseWheel(true)
                    end
                end
            else
                calibBtn:SetText(ABL("Calibrate: OFF"))
                copyBtn:Hide()
                _calibDR       = nil
                _calibDragging = false
                hud:Hide()
                for _, dr in ipairs(frame.dressingRooms) do
                    if dr.calibOverlay then
                        dr.calibOverlay:EnableMouse(false)
                        dr.calibOverlay:EnableMouseWheel(false)
                    end
                end
            end
        end)
    end

    return frame
end
