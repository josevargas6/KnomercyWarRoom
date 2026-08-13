local _, KWR = ...

local SafetyMonitor = {
    blocked = 0,
    forbidden = 0,
    recent = {},
    maxRecent = 8,
}
KWR.SafetyMonitor = SafetyMonitor

local EVENTS = {
    ADDON_ACTION_BLOCKED = "blocked",
    ADDON_ACTION_FORBIDDEN = "forbidden",
}

function SafetyMonitor:Record(event, subject, action)
    local counter = EVENTS[event]
    if not counter then return end
    local addon = KWR.Util:Text(subject, "", 64)
    if addon ~= "KnomercyWarRoom" and addon ~= "KWRSentinel" then return end
    self[counter] = (self[counter] or 0) + 1
    self.recent[#self.recent + 1] = {
        at = KWR.Util:Now(),
        event = event,
        subject = addon,
        action = KWR.Util:Text(action, "unknown", 100),
    }
    while #self.recent > self.maxRecent do
        table.remove(self.recent, 1)
    end
end

function SafetyMonitor:Snapshot()
    return {
        blocked = self.blocked or 0,
        forbidden = self.forbidden or 0,
        total = (self.blocked or 0) + (self.forbidden or 0),
        recent = KWR.Util:Copy(self.recent or {}),
    }
end

function SafetyMonitor:OnInitialize()
    self.frame = self.frame or CreateFrame("Frame")
    for event in pairs(EVENTS) do
        self.frame:RegisterEvent(event)
    end
    self.frame:SetScript("OnEvent", function(_, event, ...)
        self:Record(event, ...)
    end)
end

function SafetyMonitor:OnDisable()
    if not self.frame then return end
    for event in pairs(EVENTS) do
        self.frame:UnregisterEvent(event)
    end
end

KWR:RegisterModule("SafetyMonitor", SafetyMonitor)
