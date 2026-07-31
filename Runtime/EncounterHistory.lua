local _, KWR = ...

local EncounterHistory = {
    maxPlayers = 240,
    sessionSeen = {},
}
KWR.EncounterHistory = EncounterHistory

local function stamp()
    if type(time) == "function" then
        return KWR.Util:Number(KWR.Util:Call(time), 0) or 0
    end
    return KWR.Util:Now()
end

local function season()
    if C_PvP and type(C_PvP.GetActiveSeason) == "function" then
        return KWR.Util:Number(KWR.Util:Call(C_PvP.GetActiveSeason), nil)
    end
end

local function key(name)
    return KWR.Util:Text(name, "", 80):lower()
end

local function knownSpec(spec)
    spec = KWR.Util:Text(spec, "", 32)
    return spec ~= "" and spec:lower() ~= "unknown"
end

function EncounterHistory:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "EncounterHistory")
    end
    KWR.db.encounters = type(KWR.db.encounters) == "table" and KWR.db.encounters or {}
    KWR.db.encounters.players = type(KWR.db.encounters.players) == "table"
        and KWR.db.encounters.players or {}
end

function EncounterHistory:Prune()
    local players, count = KWR.db.encounters.players, 0
    for _ in pairs(players) do count = count + 1 end
    while count > self.maxPlayers do
        local oldestKey, oldestAt
        for playerKey, record in pairs(players) do
            local observedAt = KWR.Util:Number(record.observedAt, 0) or 0
            if oldestAt == nil or observedAt < oldestAt then
                oldestKey, oldestAt = playerKey, observedAt
            end
        end
        if not oldestKey then break end
        players[oldestKey] = nil
        count = count - 1
    end
end

function EncounterHistory:Observe(entity, team, mapKey)
    if type(entity) ~= "table" or not knownSpec(entity.spec) then return end
    local playerKey = key(entity.name)
    if playerKey == "" then return end
    local previous = KWR.db.encounters.players[playerKey] or {}
    local currentSeason = season()
    local firstThisSession = self.sessionSeen[playerKey] ~= true
    self.sessionSeen[playerKey] = true
    KWR.db.encounters.players[playerKey] = {
        name = KWR.Util:Text(entity.name, previous.name, 80),
        shortName = KWR.Util:Text(entity.shortName, previous.shortName, 40),
        class = KWR.Util:Text(entity.class, previous.class, 32),
        classFile = KWR.Util:Upper(entity.classFile, previous.classFile or "UNKNOWN", 24),
        spec = KWR.Util:Text(entity.spec, previous.spec, 32),
        role = KWR.CombatSpells:Role(entity.spec, entity.role or previous.role),
        team = KWR.Util:Upper(team, previous.team or "UNKNOWN", 12),
        mapKey = KWR.Util:Upper(mapKey, previous.mapKey or "UNKNOWN", 24),
        season = currentSeason or previous.season,
        observedAt = stamp(),
        encounters = math.min((KWR.Util:Number(previous.encounters, 0) or 0)
            + (firstThisSession and 1 or 0), 9999),
    }
end

function EncounterHistory:Apply(entity)
    if type(entity) ~= "table" or knownSpec(entity.spec) then
        if type(entity) == "table" and knownSpec(entity.spec) then
            entity.evidence = entity.specSource == "historical" and "HISTORICAL" or "LIVE"
        end
        return entity
    end
    local record = KWR.db.encounters.players[key(entity.name)]
    if not record then return entity end
    local entityClass = KWR.Util:Upper(entity.classFile, "", 24)
    if entityClass ~= "" and entityClass ~= "UNKNOWN"
        and record.classFile ~= entityClass then return entity end
    local currentSeason = season()
    if currentSeason and record.season and currentSeason ~= record.season then return entity end
    entity.spec = record.spec
    entity.specID = entity.specID
    entity.specSource = "historical"
    entity.evidence = "HISTORICAL"
    entity.evidenceAt = record.observedAt
    entity.evidenceConfidence = currentSeason and record.season == currentSeason and "LIKELY" or "LOW"
    if KWR.Util:Text(entity.role, "NONE", 12) == "NONE" then entity.role = record.role end
    return entity
end

function EncounterHistory:Enrich(snapshot)
    local sessionKey = KWR.Util:BattlefieldSessionKey(snapshot.context)
    if self.sessionKey ~= sessionKey then
        self.sessionKey = sessionKey
        self.sessionSeen = {}
    end
    for _, player in ipairs(snapshot.roster or {}) do self:Apply(player) end
    for _, enemy in ipairs(snapshot.enemies or {}) do self:Apply(enemy) end
    for _, player in ipairs(snapshot.roster or {}) do
        if player.specSource ~= "historical" then
            self:Observe(player, "FRIENDLY", snapshot.context.mapKey)
        end
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if enemy.specSource ~= "historical" then
            self:Observe(enemy, "ENEMY", snapshot.context.mapKey)
        end
    end
    self:Prune()
    return snapshot
end

function EncounterHistory:Lookup(name)
    return KWR.Util:Copy(KWR.db.encounters.players[key(name)])
end

function EncounterHistory:Count()
    local count = 0
    for _ in pairs(KWR.db.encounters.players) do count = count + 1 end
    return count
end

KWR:RegisterModule("EncounterHistory", EncounterHistory)