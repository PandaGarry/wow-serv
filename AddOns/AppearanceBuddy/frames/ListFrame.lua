local addon, ns = ...

local type = type
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove



local function button_OnClick(self, mouseButton)
    if mouseButton == "RightButton" then
        if self.onRightClick then self.onRightClick(self) end
        return
    end
    if IsShiftKeyDown() and self.onShiftClick then
        self.onShiftClick(self)
        return
    end
    if IsControlKeyDown() and self.onCtrlClick then
        self.onCtrlClick(self)
        return
    end
    self:GetParent():Select(self:GetID())
end


local recycler = {
    ["recycled"] = {},
    ["counter"] = 0,

    ["get"] = function(self, parent, number)
        number = number ~= nil and number or 1
        local result = {}
        while #result < number do
            if self.recycled[parent] == nil then self.recycled[parent] = {} end
            local recycled = self.recycled[parent]
            if #recycled > 0 then
                local btn = tremove(recycled)
                btn:Show()
                tinsert(result, btn)
            else
                self.counter = self.counter + 1
                local btn = CreateFrame("Button", "$parentListFrameButton"..self.counter, parent, "OptionsListButtonTemplate")
                btn:SetID(0)
                btn:Show()
                btn:SetScript("OnClick", button_OnClick)
                tinsert(result, 1, btn)
            end
        end
        return #result > 1 and result or result[1]
    end,

    ["recycle"] = function(self, parent, btn)
        if self.recycled[parent] == nil then self.recycled[parent] = {} end
        local recycled = self.recycled[parent]
        for i, v in ipairs(recycled) do
            assert(btn ~= v, "Double recycling.")
        end
        btn:Hide()
        tinsert(recycled, btn)
    end,
}


local function ListFrame_SetInsets(self, left, right, top, bottom)
    self.insets.left = left
    self.insets.right = right
    self.insets.top = top
    self.insets.bottom = bottom
    self:Update()
end


local function ListFrame_GetListHeight(self)
    -- O(1): cached running total maintained by AddItem/RemoveItem/Clear/Update.
    return self._totalHeight or 0
end

local function ListFrame_RecalcTotalHeight(self)
    local h = 0
    for i = 1, #self.buttons do
        h = h + (self.buttons[i]:GetHeight() or 0)
    end
    self._totalHeight = h
    return h
end


local function ListFrame_Select(self, id)
    if self.selected ~= nil then
        self.buttons[self.selected]:UnlockHighlight()
    end
    if type(id) == "number" then
        if not self.buttons[id] then return end  -- out-of-range guard
        self.buttons[id]:LockHighlight()
        self.selected = id
        if self.onSelect ~= nil then
            self.onSelect(self, id)
        end
    elseif type(id) == "string" then
        for i = 1, #self.buttons do
            if self.buttons[i]:GetText() == id then
                self.buttons[i]:LockHighlight()
                self.selected = i
                if self.onSelect ~= nil then
                    self.onSelect(self, i)
                end
                break
            end
        end
    end
end


local function ListFrame_Deselect(self)
    if self.selected ~= nil then
        self.buttons[self.selected]:UnlockHighlight()
        local selected = self.selected
        self.selected = nil
        return selected
    end
end


local function ListFrame_GetSelected(self)
    return self.selected
end


local function ListFrame_GetButton(self, nameOrId)
    if type(nameOrId) == "string" then
        for i = 1, #self.buttons do
            if self.buttons[i].name == nameOrId then
                return self.buttons[i]
            end
        end
    elseif type(nameOrId) == "number" then
        return self.buttons[nameOrId]
    end
end


local function ListFrame_RemoveItem(self, id)
    id = tonumber(id)
    if id and #self.buttons >= id and id > 0 then
        if self.selected ~= nil then
            if self.selected == id then
                self:Deselect()
            elseif self.selected > id then
                self.selected = self.selected - 1
            end
        end
        for i = id + 1, #self.buttons do
            self.buttons[i]:SetID(i - 1)
        end
        local btn = tremove(self.buttons, id)
        local bh = btn:GetHeight() or 0
        btn:ClearAllPoints()
        recycler:recycle(self, btn)
        self._totalHeight = math.max(0, (self._totalHeight or 0) - bh)
        self:Update()
    end
end


local function ListFrame_Clear(self)
    if self:GetSelected() ~= nil then
        self:Deselect()
    end
    while #self.buttons > 0 do
        local btn = tremove(self.buttons, #self.buttons)
        btn:ClearAllPoints()
        recycler:recycle(self, btn)
    end
    self._totalHeight = 0
    self:Update()
end


local function ListFrame_Update(self)
    ListFrame_RecalcTotalHeight(self)
    self:SetHeight((self._totalHeight or 0) + self.insets.top + self.insets.bottom)
    if #self.buttons > 0 then
        self.buttons[1]:SetPoint("TOPLEFT", self.insets.left, -self.insets.top)
        self.buttons[1]:SetPoint("TOPRIGHT", -self.insets.right, self.insets.bottom)
        for i=2, #self.buttons do
            self.buttons[i]:SetPoint("TOPLEFT", self.buttons[i - 1], "BOTTOMLEFT")
            self.buttons[i]:SetPoint("TOPRIGHT", self.buttons[i - 1], "BOTTOMRIGHT")
        end
    end
end


local function ListFrame_AddItem(self, itemName)
    assert(type(itemName) == "string", "Item name must be a 'string' value.")
    local btn = recycler:get(self)
    btn:SetText(itemName)
    btn:SetScript("OnClick", button_OnClick)
    btn.name = itemName
    tinsert(self.buttons, btn)
    local id = #self.buttons
    btn:SetID(id)

    -- Anchor only the new button rather than calling full Update() (which
    -- re-anchors every existing button, making bulk inserts O(n²)).
    btn:ClearAllPoints()
    if id == 1 then
        btn:SetPoint("TOPLEFT", self.insets.left, -self.insets.top)
        btn:SetPoint("TOPRIGHT", -self.insets.right, self.insets.bottom)
    else
        btn:SetPoint("TOPLEFT", self.buttons[id - 1], "BOTTOMLEFT")
        btn:SetPoint("TOPRIGHT", self.buttons[id - 1], "BOTTOMRIGHT")
    end
    -- O(1) height bookkeeping: previously called GetListHeight() which
    -- iterated every existing button, making bulk catalog inserts O(n^2).
    self._totalHeight = (self._totalHeight or 0) + (btn:GetHeight() or 0)
    self:SetHeight(self._totalHeight + self.insets.top + self.insets.bottom)
    return id
end


local function ListFrame_GetSize(self)
    return #self.buttons
end


function ns.CreateListFrame(name, list, parent)
    local frame = CreateFrame("Frame", name, parent)
    frame.insets = {left = 0, right = 0, top = 0, bottom = 0}
    frame.buttons = {}
    frame._totalHeight = 0
    frame.selected = nil
    frame.onSelect = nil

    frame.SetInsets = ListFrame_SetInsets
    frame.GetListHeight = ListFrame_GetListHeight
    frame.GetSelected = ListFrame_GetSelected
    frame.GetButton = ListFrame_GetButton
    frame.Select = ListFrame_Select
    frame.Deselect = ListFrame_Deselect
    frame.AddItem = ListFrame_AddItem
    frame.RemoveItem = ListFrame_RemoveItem
    frame.Clear = ListFrame_Clear
    frame.Update = ListFrame_Update
    frame.GetSize = ListFrame_GetSize

    if list ~= nil then
        for _, name in pairs(list) do
            ListFrame_AddItem(frame, name)
        end
    end

    return frame
end
