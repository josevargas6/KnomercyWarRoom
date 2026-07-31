local _, KWR = ...

local RosterInspector = {
    pendingGUID = nil,
    pendingUnit = nil,
    lastRequestAt = -999,
    forceRosterKeys = {},
}
KWR.RosterInspector = RosterInspector

local function canRequest(unit)
    if not unit or unit == "player" then return false end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
    if type(CanInspect) ~= "function" or type(NotifyInspect) ~= "function" then return false end
    return KWR.Util:Boolean(KWR.Util:Call(CanInspect, unit, false), false)
end

local function rememberKey(collection, key)
    key = KWR.Util:Text(key, "", 80)
    if key ~= "" then collection[key:lower()] = true end
end

local function playerNeedsForcedInspect(owner, player)
    if type(player) ~= "table" then return false end
    local keys = owner.forceRosterKeys or {}
    local guid = KWR.Util:Text(player.guid, "", 80):lower()
    local name = KWR.Util:Text(player.name, "", 64):lower()
    return (guid ~= "" and keys[guid] == true)
        or (name ~= "" and keys[name] == true)
end

local function clearForcedInspect(owner, guid, name)
    if not owner.forceRosterKeys then return end
    rememberKey(owner.forceRosterKeys, guid)
    rememberKey(owner.forceRosterKeys, name)
    if guid and guid ~= "" then owner.forceRosterKeys[guid:lower()] = nil end
    if name and name ~= "" then owner.forceRosterKeys[name:lower()] = nil end
end

function RosterInspector:BeginFullRescan(roster)
    self.forceRosterKeys = {}
    local queued = 0
    for _, player in ipairs(roster or {}) do
        if type(player) == "table" and player.unit and player.unit ~= "player" then
            rememberKey(self.forceRosterKeys, player.guid)
            rememberKey(self.forceRosterKeys, player.name)
            queued = queued + 1
        end
    end
    if self.pendingGUID then
        self.pendingGUID, self.pendingUnit, self.pendingAt = nil, nil, nil
        if type(ClearInspectPlayer) == "function" then KWR.Util:Call(ClearInspectPlayer) end
    end
    self.lastRequestAt = -999
    return queued
end

function RosterInspector:RequestNext(roster)
    if self.pendingGUID and (KWR.Util:Now() - (self.pendingAt or 0)) > 5 then
        self.pendingGUID, self.pendingUnit, self.pendingAt = nil, nil, nil
        if type(ClearInspectPlayer) == "function" then KWR.Util:Call(ClearInspectPlayer) end
    end
    if self.pendingGUID or (KWR.Util:Now() - self.lastRequestAt) < 1.5 then return end
    for _, player in ipairs(roster or {}) do
        local forced = playerNeedsForcedInspect(self, player)
        if (forced or not player.spec or player.spec == "" or player.specSource == "historical")
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
        clearForcedInspect(self, guid, name)
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