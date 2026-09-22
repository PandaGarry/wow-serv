local addon, ns = ...

local QUERY_TIME = 6  -- reduced from 10; resolve preview/icons to best-effort sooner

local pairs = pairs
local pcall = pcall
local tostring = tostring
local type = type
local next = next
local tinsert = table.insert
local tremove = table.remove
local twipe = table.wipe
local GetItemInfo = GetItemInfo
local geterrorhandler = geterrorhandler

local tooltip = CreateFrame("GameTooltip", nil, UIParent)
local dummy = CreateFrame("Frame", nil, UIParent)
dummy.queries = {} -- [itemId] = {functable1, functable2, fuctable3, ...}

local onRemove = {} -- reused every OnUpdate tick to avoid per-frame allocation
local retryQueue = {} -- deferred retry entries: {itemId, handler}

local function dummy_OnUpdate(self, elapsed)
    twipe(onRemove)
    for itemId, handlers in pairs(self.queries) do
        local _, itemLink = GetItemInfo(itemId)
        if itemLink ~= nil then
            for j = 1, #handlers do
                local ok, err = pcall(handlers[j][1], itemId, true)
                if not ok then
                    geterrorhandler()("QueryItem handler error for item " .. tostring(itemId) .. ": " .. tostring(err))
                end
            end
            twipe(handlers)
        else
            local i = #handlers
            while i >= 1 do
                local h = handlers[i]
                h[2] = h[2] - elapsed
                if h[2] <= 0 then
                    local ok, err = pcall(h[1], itemId, false)
                    if not ok then
                        geterrorhandler()("QueryItem handler error for item " .. tostring(itemId) .. ": " .. tostring(err))
                    end
                    tremove(handlers, i)
                end
                i = i - 1
            end
        end
        if #handlers == 0 then
            onRemove[#onRemove + 1] = itemId
        end
    end
    while #onRemove > 0 do
        self.queries[tremove(onRemove)] = nil
    end
    -- Process deferred retries after cleanup so queries[itemId] is nil and
    -- ns.QueryItem will resend SetHyperlink, firing a fresh server request.
    for i = #retryQueue, 1, -1 do
        local entry = tremove(retryQueue, i)
        ns.QueryItem(entry[1], entry[2])
    end
    if next(self.queries) == nil and #retryQueue == 0 then
        self:SetScript("OnUpdate", nil)
    end
end


function ns.QueryItem(itemId, handler)
    if type(itemId) ~= "number" then
        return
    end
    if handler ~= nil
        and type(handler) ~= "function"
        and not (type(handler) == "table" and getmetatable(handler) ~= nil and getmetatable(handler)["__call"] ~= nil)
    then
        return
    end
    local _, itemLink = GetItemInfo(itemId)
    if itemLink ~= nil then
        if handler ~= nil then
            local ok, err = pcall(handler, itemId, true)
            if not ok then
                geterrorhandler()("QueryItem handler error for item " .. tostring(itemId) .. ": " .. tostring(err))
            end
        end
        return
    end

    local queries = dummy.queries
    -- Pre-warm call (no handler): just kick WoW's item request if not already
    -- in-flight, then bail.  No Lua table allocation or OnUpdate polling needed.
    if handler == nil then
        if queries[itemId] == nil then
            tooltip:SetHyperlink("item:".. tostring(itemId) ..":0:0:0:0:0:0:0")
            tooltip:Hide()
        end
        return
    end

    if queries[itemId] == nil then
        tooltip:SetHyperlink("item:".. tostring(itemId) ..":0:0:0:0:0:0:0")
        tooltip:Hide()
        queries[itemId] = {}
    end
    for i = 1, #queries[itemId] do
        if queries[itemId][i][1] == handler then
            queries[itemId][i][2] = QUERY_TIME
            return
        end
    end
    tinsert(queries[itemId], {handler, QUERY_TIME})
    if dummy:GetScript("OnUpdate") == nil then
        dummy:SetScript("OnUpdate", dummy_OnUpdate)
    end
end

-- Deferred retry: enqueues a fresh QueryItem call to run AFTER the current
-- OnUpdate tick completes.  At that point the expired handler has been fully
-- removed and queries[itemId] is nil, so ns.QueryItem will resend the
-- SetHyperlink request and register a new timer — unlike calling ns.QueryItem
-- directly from inside a handler (which finds the old entry, resets its timer,
-- and then has it immediately discarded by tremove).
function ns.QueryItemRetry(itemId, handler)
    retryQueue[#retryQueue + 1] = {itemId, handler}
    if dummy:GetScript("OnUpdate") == nil then
        dummy:SetScript("OnUpdate", dummy_OnUpdate)
    end
end
