local _, KWR = ...

local EncounterHistory = {
    maxPlayers = 240,
    maxAgeSeconds = 90 * 24 * 60 * 60,
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

local function nameKey(value)
    return KWR.Util:Text(value, "", 80):lower()
end

local function playerKey(entity)
    entity = type(entity) == "table" and entity or {}
    local guid = KWR.Util:Text(entity.guid, "", 96)
    if guid ~= "" then return "guid:" .. guid end
    local name = nameKey(entity.name or entity.shortName)
    return name ~= "" and "name:" .. name or ""
end

local function legacyNameKey(entity)
    return nameKey(type(entity) == "table" and (entity.name or entity.shortName) or entity)
end

local function knownSpec(spec)
    spec = KWR.Util:Text(spec, "", 32)
    return spec ~= "" and spec:lower() ~= "unknown"
end

local function validRecord(record)
    return type(record) == "table"
        and KWR.Util:Text(record.name, "", 80) ~= ""
        and knownSpec(record.spec)
        and KWR.Util:Number(record.lastSeenAt or record.observedAt, nil) ~= nil
end

local function recordKey(record, fallback)
    return KWR.Util:Text(record and record.identityKey, fallback or "", 128)
end

function EncounterHistory:OnInitialize()
    if KWR.MemoryBudget then KWR.MemoryBudget:Bind(self, "EncounterHistory") end
    KWR.db.encounters = type(KWR.db.encounters) == "table" and KWR.db.encounters or {}
    KWR.db.encounters.players = type(KWR.db.encounters.players) == "table"
        and KWR.db.encounters.players or {}
    KWR.db.encounters.quarantine = type(KWR.db.encounters.quarantine) == "table"
        and KWR.db.encounters.quarantine or {}
    self:Prune(stamp())
end

function EncounterHistory:Prune(now)
    local encounters = KWR.db and KWR.db.encounters or {}
    local players = type(encounters.players) == "table" and encounters.players or {}
    encounters.players = players
    encounters.quarantine = type(encounters.quarantine) == "table" and encounters.quarantine or {}
    now = KWR.Util:Number(now, stamp()) or stamp()
    local rows = {}
    for storedKey, record in pairs(players) do
        local lastSeen = KWR.Util:Number(record and (record.lastSeenAt or record.observedAt), nil)
        if type(storedKey) ~= "string" or not validRecord(record) then
            encounters.quarantine[storedKey] = record
            players[storedKey] = nil
        elseif lastSeen and now >= lastSeen and now - lastSeen > self.maxAgeSeconds then
            players[storedKey] = nil
        else
            rows[#rows + 1] = { key = storedKey, at = lastSeen or 0 }
        end
    end
    table.sort(rows, function(a, b)
        if a.at ~= b.at then return a.at > b.at end
        return a.key < b.key
    end)
    for index = self.maxPlayers + 1, #rows do players[rows[index].key] = nil end
    self.lastPruneAt = now
    self.pruneRequired = false
end

function EncounterHistory:Find(entity)
    local players = KWR.db.encounters.players
    local identity = playerKey(entity)
    if identity ~= "" and players[identity] then return players[identity], identity end
    -- Source releases before this migration keyed records by display name.
    local legacy = legacyNameKey(entity)
    if legacy ~= "" and players[legacy] then return players[legacy], legacy end
    return nil, identity
end

function EncounterHistory:Observe(entity, team, mapKey, currentSeason, now)
    if type(entity) ~= "table" or not knownSpec(entity.spec) then return end
    local identity = playerKey(entity)
    if identity == "" then return end
    now = KWR.Util:Number(now, stamp()) or stamp()
    local previous, storedKey = self:Find(entity)
    previous = previous or {}
    local firstThisSession = self.sessionSeen[identity] ~= true
    self.sessionSeen[identity] = true
    local role = KWR.CombatSpells:Role(entity.spec, entity.role or previous.role)
    local nextRecord = {
        identityKey = identity,
        name = KWR.Util:Text(entity.name, previous.name, 80),
        shortName = KWR.Util:Text(entity.shortName, previous.shortName, 40),
        class = KWR.Util:Text(entity.class, previous.class, 32),
        classFile = KWR.Util:Upper(entity.classFile, previous.classFile or "UNKNOWN", 24),
        spec = KWR.Util:Text(entity.spec, previous.spec, 32),
        role = role,
        team = KWR.Util:Upper(team, previous.team or "UNKNOWN", 12),
        mapKey = KWR.Util:Upper(mapKey, previous.mapKey or "UNKNOWN", 24),
        season = currentSeason or previous.season,
        firstSeenAt = KWR.Util:Number(previous.firstSeenAt or previous.observedAt, now) or now,
        lastSeenAt = now,
        observedAt = now,
        encounters = math.min((KWR.Util:Number(previous.encounters, 0) or 0)
            + (firstThisSession and 1 or 0), 9999),
    }
    -- If the semantic record did not change, update the existing table in place.
    -- That avoids one allocation per refresh while keeping its eviction time fresh.
    local same = previous.identityKey == nextRecord.identityKey
        and previous.name == nextRecord.name and previous.shortName == nextRecord.shortName
        and previous.class == nextRecord.class and previous.classFile == nextRecord.classFile
        and previous.spec == nextRecord.spec and previous.role == nextRecord.role
        and previous.team == nextRecord.team and previous.mapKey == nextRecord.mapKey
        and previous.season == nextRecord.season and previous.encounters == nextRecord.encounters
    if same then
        previous.lastSeenAt, previous.observedAt = now, now
        return previous
    end
    if storedKey and storedKey ~= identity then
        KWR.db.encounters.players[storedKey] = nil
    end
    KWR.db.encounters.players[identity] = nextRecord
    if not storedKey or storedKey ~= identity or not previous.identityKey then
        self.pruneRequired = true
    end
    return nextRecord
end

function EncounterHistory:Apply(entity, currentSeason)
    if type(entity) ~= "table" or knownSpec(entity.spec) then
        if type(entity) == "table" and knownSpec(entity.spec) then
            entity.evidence = entity.specSource == "historical" and "HISTORICAL" or "LIVE"
        end
        return entity
    end
    local record = self:Find(entity)
    if not validRecord(record) then return entity end
    local entityClass = KWR.Util:Upper(entity.classFile, "", 24)
    if entityClass ~= "" and entityClass ~= "UNKNOWN" and record.classFile ~= entityClass then
        return entity
    end
    if currentSeason and record.season and currentSeason ~= record.season then return entity end
    entity.spec = record.spec
    entity.specSource = "historical"
    entity.evidence = "HISTORICAL"
    entity.evidenceAt = record.lastSeenAt or record.observedAt
    entity.evidenceConfidence = currentSeason and record.season == currentSeason and "LIKELY" or "LOW"
    if KWR.Util:Text(entity.role, "NONE", 12) == "NONE" then entity.role = record.role end
    return entity
end

function EncounterHistory:Enrich(snapshot)
    local sessionKey = KWR.Util:BattlefieldSessionKey(snapshot.context)
    if self.sessionKey ~= sessionKey then
        self.sessionKey = sessionKey
        self.sessionSeen = {}
        self.pruneRequired = true
    end
    local currentSeason, now = season(), stamp()
    for _, player in ipairs(snapshot.roster or {}) do self:Apply(player, currentSeason) end
    for _, enemy in ipairs(snapshot.enemies or {}) do self:Apply(enemy, currentSeason) end
    for _, player in ipairs(snapshot.roster or {}) do
        if player.specSource ~= "historical" then
            self:Observe(player, "FRIENDLY", snapshot.context.mapKey, currentSeason, now)
        end
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if enemy.specSource ~= "historical" then
            self:Observe(enemy, "ENEMY", snapshot.context.mapKey, currentSeason, now)
        end
    end
    -- Spec enrichment is per refresh; sorting the whole persistent history is
    -- not. New identities enforce capacity immediately, aging is checked once
    -- per five seconds (and immediately if the wall clock moves backwards).
    if self.pruneRequired or not self.lastPruneAt or now < self.lastPruneAt
        or now - self.lastPruneAt >= 5 then
        self:Prune(now)
    end
    return snapshot
end

function EncounterHistory:Lookup(entity)
    local record = self:Find(entity)
    return KWR.Util:Copy(record)
end

function EncounterHistory:Count()
    local count = 0
    for _ in pairs(KWR.db.encounters.players) do count = count + 1 end
    return count
end

KWR:RegisterModule("EncounterHistory", EncounterHistory)
