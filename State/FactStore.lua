local _, KWR = ...

local FactStore = {}
KWR.FactStore = FactStore

local function add(facts, fact)
    local ok = not KWR.ComplianceGate or KWR.ComplianceGate:AllowFact(fact)
    if ok then facts[#facts + 1] = fact end
end

local OBSERVATION_FIELDS = { "observedAt", "lastSeenAt", "capturedAt" }

local function observationTime(row)
    for _, field in ipairs(OBSERVATION_FIELDS) do
        local value = KWR.Util:Number(row and row[field], nil)
        if value and value == value and value >= 0 and value < math.huge then return value end
    end
    return nil
end

local function confidenceFor(row, observedAt, now)
    if not observedAt or observedAt > now then return "UNKNOWN" end
    local confidence = KWR.Util:Text(row and row.confidence, "INFERRED", 16)
    if confidence == "CONFIRMED" or confidence == "INFERRED" then return confidence end
    return "UNKNOWN"
end

local function objectiveKey(row)
    return KWR.Util:Text(row and (row.objectiveID or row.id or row.nodeID
        or row.guid or row.name or row.label), "unknown", 96)
end

local function actorKey(row)
    return KWR.Util:CanonicalPlayerKey(row and row.name, row and row.guid)
end

local function matchGeneration(snapshot)
    local context = snapshot and snapshot.context or {}
    return KWR.Util:Text(context.sessionKey or context.matchGeneration, "unknown", 160)
end

local function factID(generation, kind, subject, suffix)
    -- Evidence IDs are stable within one match generation, but a same-map
    -- rematch must never be able to inherit a prior match's supporting fact.
    return kind .. ":" .. generation .. ":" .. subject .. (suffix or "")
end

function FactStore:FromSnapshot(snapshot)
    local facts = {}
    local now = KWR.Util:Now()
    local generation = matchGeneration(snapshot)
    add(facts, KWR.SafeBattlegroundAdapter and KWR.SafeBattlegroundAdapter:ContextFact(snapshot)
        or { type = "BATTLEGROUND_CONTEXT", source = "internal" })
    for _, enemy in ipairs(snapshot and snapshot.enemies or {}) do
        local observedAt = observationTime(enemy)
        local subject = actorKey(enemy)
        add(facts, {
            id = subject and factID(generation, "enemy", subject, ":identity") or nil,
            type = "ENEMY",
            source = KWR.ComplianceGate and KWR.ComplianceGate:NormalizeSource(
                KWR.Util:Text(enemy.source, enemy.visible and "nameplate" or "scoreboard", 32))
                or KWR.Util:Text(enemy.source, enemy.visible and "nameplate" or "scoreboard", 32),
            subject = subject or "unknown",
            enemy = enemy,
            confidence = confidenceFor(enemy, observedAt, now),
            observedAt = observedAt,
            matchGeneration = generation,
        })
    end
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        local observedAt = observationTime(player)
        local subject = actorKey(player)
        add(facts, {
            id = subject and factID(generation, "friendly", subject, ":identity") or nil,
            type = "FRIENDLY",
            source = "scoreboard",
            subject = subject or "unknown",
            player = player,
            confidence = confidenceFor(player, observedAt, now),
            observedAt = observedAt,
            matchGeneration = generation,
        })
    end
    local objectives = snapshot and snapshot.objectives or {}
    local objectiveRows = objectives.rows or objectives
    for _, objective in ipairs(type(objectiveRows) == "table" and objectiveRows or {}) do
        local observedAt = observationTime(objective) or observationTime(objectives)
        local subject = objectiveKey(objective)
        add(facts, {
            id = factID(generation, "objective", subject),
            type = "OBJECTIVE",
            source = KWR.Util:Text(objective.source or objectives.source, "unknown", 32),
            subject = subject,
            objective = objective,
            confidence = confidenceFor(objective, observedAt, now),
            observedAt = observedAt,
            expiresAt = KWR.Util:Number(objective.expiresAt, nil),
            matchGeneration = generation,
        })
    end
    return {
        facts = facts,
        generatedAt = now,
        matchGeneration = generation,
        ruleset = KWR.ComplianceGate and KWR.ComplianceGate:Ruleset() or {},
    }
end

KWR:RegisterModule("FactStore", FactStore)
