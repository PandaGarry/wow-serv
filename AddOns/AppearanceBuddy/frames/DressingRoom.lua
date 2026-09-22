
local addon, ns = ...

local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local math_exp = math.exp
local math_rad = math.rad

local defaultWidth = 350
local defaultHeight = 430

-- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
local defaultLight = {1, 0, 0, 1, 0, 1, 0.7, 0.7, 0.7, 1, 0.8, 0.8, 0.64}

local xStep = 0.2 -- per pixel
local zStep = 0.003 -- per pixel
local facingStep = math_rad(0.75) -- per pixel

local sex = {male = 2, female = 3}
sex[sex.male] = "male"
sex[sex.female] = "female"
local male, female = 2, 3

-- ============================================================
-- MAIN DRESSING ROOM CONFIGURATION
-- ============================================================
-- Per-race zoom limits for the main dressing room preview.
--   x axis: positive = zoomed IN  (model moves toward camera, closer/larger).
--            negative = zoomed OUT (model moves away from camera, smaller).
--   Default position is x = 0 (full-body view). Wheel/Alt+RMB drag changes x.
--
--   modelX.max  = how far the player can zoom IN.
--     Reducing these values prevents zooming through the character's head.
--     0.75 is a safe value for all races that allows close-up detail views
--     without clipping. Raise a value if you want more zoom for that race.
--
--   modelX.min  = how far the player can zoom OUT (negative = pull back).
--     -2.0 allows a generous zoom-out range. Make less negative to restrict.
--
-- Z axis limits (modelZ) control vertical pan range.
-- ============================================================
local modelX = { -- male = 2, female = 3
    min = {
        -- The Alliance
        Dwarf =     {male = -2.0, female = -2.0},
        Draenei =   {male = -2.0, female = -2.0},
        Gnome =     {male = -2.0, female = -2.0},
        Human =     {male = -2.0, female = -2.0},
        NightElf =  {male = -2.0, female = -2.0},
        -- The Horde
        BloodElf =  {male = -2.0, female = -2.0},
        Orc =       {male = -2.0, female = -2.0},
        Scourge =   {male = -2.0, female = -2.0},
        Tauren =    {male = -2.0, female = -2.0},
        Troll =     {male = -2.0, female = -2.0},
    },
    max = {
        -- The Alliance  (reduce to zoom in less; raise to allow more)
        Dwarf =     {male = 0.75, female = 0.75},
        Draenei =   {male = 0.75, female = 0.75},
        Gnome =     {male = 0.75, female = 0.75},
        Human =     {male = 0.75, female = 0.75},
        NightElf =  {male = 0.75, female = 0.75},
        -- The Horde
        BloodElf =  {male = 0.75, female = 0.75},
        Orc =       {male = 0.75, female = 0.75},
        Scourge =   {male = 0.75, female = 0.75},
        Tauren =    {male = 0.75, female = 0.75},
        Troll =     {male = 0.75, female = 0.75},
    },
}

local modelZ = {
    min = {
        -- The Alliance
        Dwarf =     {male = -0.80, female = -0.60},
        Draenei =   {male = -1.15, female = -0.97},
        Gnome =     {male = -0.30, female = -0.32},
        Human =     {male = -1.05, female = -1.76},
        NightElf =  {male = -1.05, female = -0.87},
        -- The Horde
        BloodElf =  {male = -1.00, female = -0.75},
        Orc =       {male = -0.75, female = -0.75},
        Scourge =   {male = -0.80, female = -0.67},
        Tauren =    {male = -0.80, female = -0.50},
        Troll =     {male = -0.75, female = -0.75},
    },
    max = {
        -- The Alliance
        Dwarf =     {male = 0.52, female = 0.75},
        Draenei =   {male = 1.15, female = 0.92},
        Gnome =     {male = 0.48, female = 0.47},
        Human =     {male = 0.78, female = 0.77},
        NightElf =  {male = 0.96, female = 0.96},
        -- The Horde
        BloodElf =  {male = 0.75, female = 0.80},
        Orc =       {male = 0.95, female = 0.9},
        Scourge =   {male = 0.75, female = 0.85},
        Tauren =    {male = 0.90, female = 1.35},
        Troll =     {male = 1.25, female = 1.25},
    },
}


function ns.CreateDressingRoom(name, parent)
    local frame = CreateFrame("Frame", name, parent)
    frame:EnableMouseWheel(true)
    frame:SetSize(defaultWidth, defaultHeight)
    frame:SetMinResize(defaultWidth, defaultHeight)
    frame:SetMaxResize(defaultWidth, defaultHeight)

    local unit = "player"
    local _, unitRaceFileName = UnitRace(unit)
    local unitSex = UnitSex(unit)

    local model = CreateFrame("DressUpModel", nil, frame)
    model:SetAllPoints()
    model:SetUnit("player")

    local dragDummy = CreateFrame("Frame", nil, frame)
    dragDummy:SetPoint("TOPLEFT", 24, -24)
    dragDummy:SetPoint("BOTTOMRIGHT", -24, 24)
    dragDummy:EnableMouse(true)
    dragDummy:SetMovable(true)

    local spinVelocity = 0  -- radians/second; used for momentum after a left-button drag
    local SPIN_FRICTION = 4.0  -- decay rate: higher = stops sooner
    local SPIN_STOP_THRESHOLD = 0.05  -- rad/s below which we kill the coast loop

    -- Shared cursor upvalues — avoids allocating a new closure on every mouse-down.
    local cursorX, cursorY = 0, 0

    local function onUpdateLeftDrag(self, elapsed)
        local newX, newY = GetCursorPosition()
        if not newX or not newY then return end
        local deltaX = newX - cursorX
        model:SetFacing((model:GetFacing() or 0) + deltaX * facingStep)
        -- Track instantaneous velocity (rad/s) with smoothing so stutter
        -- frames don't pollute the release speed.
        local dt = math_max(elapsed, 0.001)
        local instant = (deltaX * facingStep) / dt
        spinVelocity = spinVelocity * 0.4 + instant * 0.6
        cursorX, cursorY = newX, newY
    end

    local function onUpdateAltRightDrag(self, elapsed)
        local newX, newY = GetCursorPosition()
        frame:GetScript("OnMouseWheel")(frame, (newY - cursorY) * 0.05)
        cursorX, cursorY = newX, newY
    end

    local function onUpdateRightDrag(self, elapsed)
        local newX, newY = GetCursorPosition()
        if not newX or not newY then return end
        local deltaY = newY - cursorY
        local x, y, z = model:GetPosition()
        local zOffset = zStep * deltaY
        z = z + zOffset
        local raceZ = modelZ.max[unitRaceFileName]
        local maxZ = raceZ and raceZ[sex[unitSex]] or 1.0
        raceZ = modelZ.min[unitRaceFileName]
        local minZ = raceZ and raceZ[sex[unitSex]] or -1.0
        z = z > maxZ and maxZ or z
        z = z < minZ and minZ or z
        model:SetPosition(x, y, z)
        cursorX, cursorY = newX, newY
    end

    local function onUpdateSpinCoast(self, elapsed)
        if math_abs(spinVelocity) <= SPIN_STOP_THRESHOLD then
            spinVelocity = 0
            self:SetScript("OnUpdate", nil)
            return
        end
        model:SetFacing(model:GetFacing() + spinVelocity * elapsed)
        spinVelocity = spinVelocity * math_exp(-SPIN_FRICTION * elapsed)
    end

    dragDummy:SetScript("OnMouseDown", function(self, button)
        self:StartMoving()
        spinVelocity = 0  -- cancel any existing momentum when a new drag begins
        cursorX, cursorY = GetCursorPosition()
        if button == "LeftButton" then
            self:SetScript("OnUpdate", onUpdateLeftDrag)
        elseif button == "RightButton" and IsAltKeyDown() then
            self:SetScript("OnUpdate", onUpdateAltRightDrag)
        elseif button == "RightButton" then
            self:SetScript("OnUpdate", onUpdateRightDrag)
        elseif button == "MiddleButton" then
            -- Reset rotation, vertical pan, and zoom back to defaults.
            spinVelocity = 0
            self:SetScript("OnUpdate", nil)
            model:SetFacing(0)
            local x, y, z = model:GetPosition()
            model:SetPosition(x, 0, 0)  -- keep x (zoom) for smooth reset
            frame:SmoothZoomReset()
        end
    end)

    dragDummy:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -24)
        self:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 24)

        if math_abs(spinVelocity) > SPIN_STOP_THRESHOLD then
            -- Coast to a stop: apply velocity each frame and decay it
            -- exponentially so behaviour is framerate-independent.
            self:SetScript("OnUpdate", onUpdateSpinCoast)
        else
            spinVelocity = 0
            self:SetScript("OnUpdate", nil)
        end

    end)

    dragDummy:SetScript("OnHide", dragDummy:GetScript("OnMouseUp"))

    -- ---- Smooth zoom (driven by the +/-/Reset overlay buttons) ----
    local zoomVelocity = 0      -- model-x units/second
    local zoomTarget   = nil    -- non-nil: spring x towards this value
    local ZOOM_KICK     = 1.5   -- velocity impulse per button click
    local ZOOM_FRICTION = 4.0   -- exponential decay (matches spin coast)
    local ZOOM_STOP     = 0.5 -- stop threshold

    local zoomFrame = CreateFrame("Frame")
    zoomFrame:Hide()
    zoomFrame:SetScript("OnUpdate", function(self, elapsed)
        local dt = math_max(elapsed, 0.001)
        local x, y, z = model:GetPosition()
        local xMin = (modelX.min[unitRaceFileName] and modelX.min[unitRaceFileName][sex[unitSex]]) or 0
        local xMax = (modelX.max[unitRaceFileName] and modelX.max[unitRaceFileName][sex[unitSex]]) or 8.0

        if zoomTarget ~= nil then
            local diff = zoomTarget - x
            if math_abs(diff) < 0.002 then
                model:SetPosition(zoomTarget, y, z)
                zoomTarget = nil
                self:Hide()
                return
            end
            local newX = x + diff * (1 - math_exp(-8 * dt))
            newX = math_max(xMin, math_min(xMax, newX))
            model:SetPosition(newX, y, z)
            return
        end

        if math_abs(zoomVelocity) <= ZOOM_STOP then
            zoomVelocity = 0
            self:Hide()
            return
        end

        x = x + zoomVelocity * dt
        x = math_max(xMin, math_min(xMax, x))
        model:SetPosition(x, y, z)
        zoomVelocity = zoomVelocity * math_exp(-ZOOM_FRICTION * dt)
        if (zoomVelocity > 0 and x >= xMax) or (zoomVelocity < 0 and x <= xMin) then
            zoomVelocity = 0
            self:Hide()
        end
    end)

    -- direction: +1 = zoom in, -1 = zoom out
    function frame:SmoothZoom(direction)
        zoomTarget = nil
        zoomVelocity = zoomVelocity + direction * ZOOM_KICK
        zoomFrame:Show()
    end

    -- Animate back to the default (x = 0) position.
    function frame:SmoothZoomReset()
        zoomTarget = 0
        zoomVelocity = 0
        zoomFrame:Show()
    end

    local dbgFrame = CreateFrame("Frame", nil, model)
    dbgFrame:Hide()
    dbgFrame:EnableMouse(false)
    dbgFrame:EnableMouseWheel(false)
    dbgFrame:SetAllPoints()

    local dbgInfo = dbgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dbgInfo:SetAllPoints()
    dbgInfo:SetJustifyH("LEFT")
    dbgInfo:SetJustifyV("TOP")

    function frame:ShowDebugInfo()
        dbgFrame:Show()
        dbgFrame:SetScript("OnUpdate", function(self, elapsed)
            local facing = model:GetFacing()
            local x, y, z = model:GetPosition()
            dbgInfo:SetFormattedText(ABL("Facing = %f\nX = %f\nZ = %f"), facing, x, z)
        end)
    end

    function frame:HideDebugInfo() dbgFrame:Hide() end
    function frame:IsDebugInfoShown() return dbgFrame:IsShown() end

    function frame:Reset()
        local x, y, z = model:GetPosition()
        local facing = model:GetFacing() or 0
        model:SetPosition(0, 0, 0)
        model:SetFacing(0)
        model:ClearModel()
        model:SetUnit("player")

        unit = "player"
        _, unitRaceFileName = UnitRace(unit)
        unitSex = UnitSex(unit)

        local sexKey = sex[unitSex] or "male"
        local rMinX = modelX.min[unitRaceFileName]
        local rMaxX = modelX.max[unitRaceFileName]
        local rMinZ = modelZ.min[unitRaceFileName]
        local rMaxZ = modelZ.max[unitRaceFileName]
        local minX = rMinX and rMinX[sexKey] or -1.0
        local maxX = rMaxX and rMaxX[sexKey] or 2.0
        local minZ = rMinZ and rMinZ[sexKey] or -1.0
        local maxZ = rMaxZ and rMaxZ[sexKey] or 1.0

        x = x < minX and minX or x > maxX and maxX or x
        z = z < minZ and minZ or z > maxZ and maxZ or z

        model:SetPosition(x, y, z)
        model:SetFacing(facing)
        model:SetLight(unpack(defaultLight))
    end

    function frame:SetUnit(newUnit)
        if UnitIsPlayer(newUnit) and CheckInteractDistance(newUnit, 1) then
            local x, y, z = model:GetPosition()
            local facing = model:GetFacing() or 0
            model:SetPosition(0, 0, 0)
            model:SetFacing(0)
            model:ClearModel()
            model:SetUnit(newUnit)
            unit = newUnit
            _, unitRaceFileName = UnitRace(unit)
            unitSex = UnitSex(unit)
            local sexKey = sex[unitSex] or "male"
            local rMinX = modelX.min[unitRaceFileName]
            local rMaxX = modelX.max[unitRaceFileName]
            local rMinZ = modelZ.min[unitRaceFileName]
            local rMaxZ = modelZ.max[unitRaceFileName]
            local minX = rMinX and rMinX[sexKey] or -1.0
            local maxX = rMaxX and rMaxX[sexKey] or 2.0
            local minZ = rMinZ and rMinZ[sexKey] or -1.0
            local maxZ = rMaxZ and rMaxZ[sexKey] or 1.0

            x = x < minX and minX or x > maxX and maxX or x
            z = z < minZ and minZ or z > maxZ and maxZ or z

            model:SetPosition(x, y, z)
            model:SetFacing(facing)
        end
    end

    function frame:GetUnitToken()
        return unit
    end

    function frame:ClearModel(...) model:ClearModel(...) end
    function frame:TryOn(...) model:TryOn(...) end
    function frame:Undress() model:Undress() end
    function frame:GetPosition(...) return model:GetPosition(...) end
    function frame:SetPosition(...) model:SetPosition(...) end
    function frame:GetFacing(...) return model:GetFacing(...) end
    function frame:SetFacing(...) model:SetFacing(...) end
    function frame:SetAnimation(animId) model:SetSequence(animId) end
    function frame:SetSequence(...) model:SetSequence(...) end

    function frame:SetModelScale(...) model:SetModelScale(...) end
    function frame:GetModelScale(...) return model:GetModelScale(...) end
    function frame:SetLight(...) model:SetLight(...) end
    function frame:GetLight(...) return model:GetLight(...) end
    function frame:SetModelAlpha(...) model:SetAlpha(...) end
    function frame:GetModelAlpha(...) return model:GetAlpha(...) end
    function frame:OnUpdateModel(...) model:SetScript("OnUpdateModel", ...) end
    function frame:EnableDragRotation(enable) 
        if enable then dragDummy:Show() else dragDummy:Hide() end
    end

    local originSetBackdrop = frame.SetBackdrop
    function frame:SetBackdrop(backdrop)
        originSetBackdrop(frame, backdrop)
        model:ClearAllPoints()
        model:SetPoint("TOPLEFT", backdrop.insets.left * 2, -backdrop.insets.top * 2)
        model:SetPoint("BOTTOMRIGHT", -backdrop.insets.right * 2, backdrop.insets.bottom * 2)
    end

    frame:SetScript("OnMouseWheel", function(self, delta)
        self:SmoothZoom(delta)
    end)

    for _, child in pairs({frame:GetChildren()}) do
        child:SetFrameLevel(frame:GetFrameLevel())
    end

    -- Expose the DressUpModel so callers can create OVERLAY-sublayer child frames
    -- above the 3D scene (child frames of model at OVERLAY render above model content;
    -- sibling frames do not — WoW composites the 3D scene above all siblings).
    frame.model = model

    return frame
end
