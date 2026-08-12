local _, Sentinel = ...

local Panels = {}
Sentinel.Panels = Panels

local function profile(kind)
    local db = Sentinel.db.profile.panels
    db[kind] = type(db[kind]) == "table" and db[kind] or {}
    return db[kind]
end

local function trim(value)
    value = value ~= nil and tostring(value) or ""
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    value = value:gsub("%s+", " ")
    return value
end

local function short(value, fallback, limit)
    value = trim(value)
    if value == "" then
        value = fallback or ""
    end
    limit = limit or 28
    if #value > limit then
        return value:sub(1, limit - 3):gsub("%s+%S*$", "") .. "..."
    end
    return value
end

local function canShow(frame, setting)
    local settings = profile(setting)
    return settings.enabled == true
end

local function applyAnchor(frame, setting)
    local settings = profile(setting)
    frame:ClearAllPoints()
    frame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.x, settings.y)
end

local function saveAnchor(frame, setting)
    local settings = profile(setting)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    settings.point = point
    settings.relativePoint = relativePoint
    settings.x = x
    settings.y = y
end

local function createShell(name, title, width, height, setting)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    Sentinel.Theme:Style(frame, "background", "borderHi")
    applyAnchor(frame, setting)

    frame.headerBand = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.headerBand:SetPoint("TOPLEFT", 8, -6)
    frame.headerBand:SetPoint("TOPRIGHT", -8, -6)
    frame.headerBand:SetHeight(24)
    Sentinel.Theme:Style(frame.headerBand, "raised", "border")

    frame.brand = frame.headerBand:CreateTexture(nil, "ARTWORK")
    frame.brand:SetPoint("LEFT", 6, 0)
    frame.brand:SetSize(12, 12)
    frame.brand:SetTexture("Interface\\Icons\\Ability_Rogue_TricksOftheTrade")

    frame.title = Sentinel.Theme:Title(frame.headerBand, 10, "LEFT")
    frame.title:SetPoint("LEFT", frame.brand, "RIGHT", 6, 0)
    frame.title:SetText(title)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        if Sentinel.db.profile.panels.locked == true then return end
        Sentinel.db.profile.panels.layoutManaged = false
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        saveAnchor(selfFrame, setting)
    end)
    return frame
end

local function makeKeyValue(parent, label, y)
    local key = Sentinel.Theme:Font(parent, 8, "gold", "LEFT", "OUTLINE")
    key:SetPoint("TOPLEFT", 10, y)
    key:SetWidth(78)
    key:SetText(label)

    local value = Sentinel.Theme:Font(parent, 10, "strong", "LEFT", "OUTLINE")
    value:SetPoint("TOPLEFT", 82, y + 1)
    value:SetPoint("TOPRIGHT", -10, y + 1)
    value:SetHeight(14)
    return value
end

function Panels:CreateStatus()
    if self.statusFrame then return self.statusFrame end
    local frame = createShell("KWRSentinel_StatusPanel", "SENTINEL STATUS", 320, 168, "status")
    frame.assignment = makeKeyValue(frame, "ASSIGN", -40)
    frame.stage = makeKeyValue(frame, "STAGE", -62)
    frame.trinket = makeKeyValue(frame, "TRINKET", -84)
    frame.kick = makeKeyValue(frame, "KICK", -106)
    frame.cc = makeKeyValue(frame, "CC", -128)
    frame.rez = makeKeyValue(frame, "RESPAWN", -150)
    self.statusFrame = frame
    return frame
end

function Panels:UpdateStatus(view)
    local frame = self:CreateStatus()
    if Sentinel:OverlaySuppressed() or canShow(frame, "status") ~= true then
        frame:Hide()
        return
    end
    local assignment = view and view.assignment or {}
    local status = view and view.playerStatus or {}
    frame.assignment:SetText(short((assignment.shortRole or assignment.role or "UNASSIGNED")
        .. " " .. (assignment.location or ""), "UNASSIGNED", 30))
    frame.stage:SetText(short(status.stage ~= "" and status.stage or status.movement, "STAY", 24))
    frame.trinket:SetText(short(status.trinket, "UNKNOWN", 26))
    frame.kick:SetText(short(status.kick, "UNKNOWN", 26))
    frame.cc:SetText(short(status.cc, "UNKNOWN", 26))
    frame.rez:SetText(short(status.rez, "ALIVE", 20))
    frame:Show()
end

function Panels:Update(view)
    if not Sentinel.db or not Sentinel.db.profile then
        return
    end
    view = view or (Sentinel.Bridge and Sentinel.Bridge:BuildView()) or {}
    local remote = Sentinel.Relay and Sentinel.Relay:View()
    if remote then
        for key, value in pairs(remote) do view[key] = value end
    end
    self:UpdateStatus(view)
end

function Panels:ResetPositions()
    local defaults = Sentinel.defaults
        and Sentinel.defaults.profile
        and Sentinel.defaults.profile.panels
    if not defaults then return end
    local source = defaults.status
    local target = Sentinel.db.profile.panels.status
    Sentinel.db.profile.panels.layoutManaged = true
    target.point = source.point
    target.relativePoint = source.relativePoint
    target.x = source.x
    target.y = source.y
    if self.statusFrame then applyAnchor(self.statusFrame, "status") end
    self:Update()
end

function Panels:OnInitialize()
    self:CreateStatus():Hide()
end

function Panels:OnEnable()
    self:Update()
end

Sentinel:RegisterModule("Panels", Panels)
