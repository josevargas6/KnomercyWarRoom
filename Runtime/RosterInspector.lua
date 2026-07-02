local _, KWR = ...

local RosterInspector = {
    pendingGUID = nil,
    pendingUnit = nil,
    lastRequestAt = -999,
}
KWR.RosterInspector = RosterInspector

local function canRequest(unit)
    if not unit or unit == "player" then return false end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
    if type(CanInspect) ~= "function" or type(NotifyInspect) ~= "function" then return false end
    return KWR.Util:Boolean(KWR.Util:Call(CanInspect, unit, false), false)
end

function RosterInspector:RequestNext(roster)
    if self.pendingGUID and (KWR.Util:Now() - (self.pendingAt or 0)) > 5 then
        self.pendingGUID, self.pendingUnit, self.pendingAt = nil, nil, nil
        if type(ClearInspectPlayer) == "function" then KWR.Util:Call(ClearInspectPlayer) end
    end
    if self.pendingGUID or (KWR.Util:Now() - self.lastRequestAt) < 1.5 then return end
    for _, player in ipairs(roster or {}) do
        if (not player.spec or player.spec == "" or player.specSource == "historical")
            and canRequest(player.unit) then
            self.pendingGUID = player.guid
            self.pendingUnit = player.unit
            self.pendingAt = KWR.Util:Now()
            self.lastRequestAt = KWR.Util:Now()
            KWR.Util:Call(NotifyInspect, player.unit)
            return
        end
    end
end

function RosterInspector:InspectReady(guid)
    guid = KWR.Util:Text(guid, "", 80)
    if guid == "" or guid ~= self.pendingGUID then return end
    local unit = self.pendingUnit
    local specID, specName, specRole = KWR.Sensors:ResolveSpecialization(unit)
    if specName and specName ~= "" then
        local record = { id = specID, name = specName, role = specRole, observedAt = KWR.Util:Now() }
        KWR.Sensors.specCache[guid] = record
        local name = KWR.Util:UnitName(unit)
        if name then KWR.Sensors.specCache[name:lower()] = record end
    end
    self.pendingGUID, self.pendingUnit, self.pendingAt = nil, nil, nil
    if type(ClearInspectPlayer) == "function" then KWR.Util:Call(ClearInspectPlayer) end
    if KWR.MatchRuntime then KWR.MatchRuntime:Queue("inspect-ready", 0.05) end
end

function RosterInspector:OnInitialize()
    if EventRegistry and type(EventRegistry.RegisterFrameEventAndCallback) == "function" then
        EventRegistry:RegisterFrameEventAndCallback("INSPECT_READY", function(_, guid)
            RosterInspector:InspectReady(guid)
        end, self)
    end
end

KWR:RegisterModule("RosterInspector", RosterInspector)
