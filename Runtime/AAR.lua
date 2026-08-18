local _, KWR = ...

local AAR = {
    active = nil,
    lastCompleted = nil,
    maxHistory = 8,
    maxCommands = 18,
    maxEvents = 32,
    maxObjectiveTimeline = 48,
    maxDecisionReviews = 12,
    maxPlayerLocations = 8,
    maxPlayerNotes = 6,
    maxReviewQueue = 10,
}
KWR.AAR = AAR

local function epoch()
    return type(time) == "function" and time() or math.floor(KWR.Util:Now())
end

local function clean(value, fallback, limit)
    return KWR.Util:Text(value, fallback or "Unknown", limit or 160)
end

local function entityKey(entity, prefix)
    local guid = clean(entity and entity.guid, "", 80)
    if guid ~= "" then return guid end
    local name = clean(entity and entity.name, "", 64):lower()
    return (prefix or "entity") .. ":" .. (name ~= "" and name or "unknown")
end

local function displayEntity(entity)
    return {
        guid = clean(entity.guid, "", 80),
        name = clean(entity.name or entity.shortName, "Unknown", 64),
        shortName = clean(entity.shortName or entity.name, "Unknown", 40),
        class = clean(entity.class or entity.classFile, "Unknown", 32),
        classFile = clean(entity.classFile, "UNKNOWN", 24),
        spec = clean(entity.spec, "Unknown", 32),
        role = clean(entity.role or entity.groupRole, "Unknown", 16),
        specSource = clean(entity.specSource or entity.evidence, "unknown", 24),
    }
end

local function canonicalEntityName(entity)
    return KWR.Util:CanonicalName(
        entity and (entity.name or entity.shortName) or "")
end

local function claimEntityRecord(collection, entity, prefix, factory)
    local preferredKey = entityKey(entity, prefix)
    local record = collection[preferredKey]
    if record then return record, preferredKey end

    local canonicalName = canonicalEntityName(entity)
    if canonicalName ~= "" then
        for existingKey, existing in pairs(collection) do
            if canonicalEntityName(existing) == canonicalName then
                local hasGUID = clean(entity and entity.guid, "", 80) ~= ""
                if hasGUID and existingKey ~= preferredKey then
                    collection[existingKey] = nil
                    collection[preferredKey] = existing
                    return existing, preferredKey
                end
                return existing, existingKey
            end
        end
    end

    record = factory(entity)
    collection[preferredKey] = record
    return record, preferredKey
end

local function mergeEntity(record, entity)
    local current = displayEntity(entity)
    local source = current.specSource:lower()
    local authority = source == "inspect" and 400
        or source == "scoreboard" and 350
        or source == "live" and 300
        or source == "observed" and 250
        or source == "historical" and 100
        or 0
    record.fieldAuthority = type(record.fieldAuthority) == "table"
        and record.fieldAuthority or {}
    for _, field in ipairs({
        "guid", "name", "shortName", "class", "classFile", "spec", "role", "specSource",
    }) do
        local value = current[field]
        local unknown = record[field] == nil or record[field] == ""
            or record[field] == "Unknown" or record[field] == "UNKNOWN"
            or record[field] == "unknown"
        if value ~= nil and value ~= "" and value ~= "Unknown"
            and value ~= "UNKNOWN" and value ~= "unknown" then
            local currentAuthority = record.fieldAuthority[field] or 0
            local evidenceField = field == "spec" or field == "role"
                or field == "specSource"
            if unknown or not evidenceField or authority >= currentAuthority then
                record[field] = value
                if evidenceField then record.fieldAuthority[field] = authority end
            end
        end
    end
    -- A verified specialization is the role authority unless a stronger
    -- explicit role was provided by the same/higher-quality source.
    local resolvedRole = KWR.CombatSpells:Role(record.spec, "NONE")
    if resolvedRole ~= "NONE" and authority >= (record.fieldAuthority.role or 0) then
        record.role = resolvedRole
        record.fieldAuthority.role = authority
    end
    return record
end

local function assignmentByKey(assignments)
    local result = {}
    for _, assignment in ipairs(assignments or {}) do
        result[entityKey(assignment, "friendly")] = assignment
        local name = clean(assignment.name or assignment.shortName, "", 64):lower()
        if name ~= "" then result["name:" .. name] = assignment end
    end
    return result
end

local function trimList(list, maximum)
    if type(list) ~= "table" then return {} end
    maximum = KWR.Util:Number(maximum, 0) or 0
    if maximum <= 0 then
        return {}
    end
    local count = #list
    if count <= maximum then
        return list
    end
    local startIndex = count - maximum + 1
    local trimmed = {}
    for index = startIndex, count do
        trimmed[#trimmed + 1] = list[index]
    end
    return trimmed
end

local function appendBounded(list, value, maximum)
    list[#list + 1] = value
    return trimList(list, maximum)
end

local function compactPlayerEvidence(evidence, maxLocations, maxNotes)
    evidence = type(evidence) == "table" and evidence or {}
    evidence.locations = trimList(evidence.locations or {}, maxLocations or 8)
    evidence.notes = trimList(evidence.notes or {}, maxNotes or 6)
    return evidence
end

local function compactThreats(threats)
    local result = {}
    for key, threat in pairs(threats or {}) do
        result[key] = {
            guid = clean(threat.guid, "", 80),
            name = clean(threat.name, "Unknown", 64),
            class = clean(threat.class, "Unknown", 32),
            spec = clean(threat.spec, "Unknown", 32),
            role = clean(threat.role, "Unknown", 16),
            sightings = KWR.Util:Number(threat.sightings, 0) or 0,
            flags = KWR.Util:Copy(threat.flags or {}),
            lastSeenLocation = clean(threat.lastSeenLocation, "Unknown", 48),
            lastSeenAt = KWR.Util:Number(threat.lastSeenAt, nil),
            lastSeenAge = KWR.Util:Number(threat.lastSeenAge, nil),
        }
    end
    return result
end

local function copyEntry(entry)
    return KWR.Util:Copy(entry)
end

local function commandReviewRecord(state)
    return KWR.CommandReview:BuildRecord(
        state and state.command,
        state and state.snapshot,
        state and state.assignments,
        state and state.prediction)
end

local function activePlayOutcomeText(outcome)
    outcome = type(outcome) == "table" and outcome or {}
    local status = clean(outcome.status, "LIVE", 24)
    local phase = clean(outcome.phase, "UNKNOWN", 24)
    local bucket = clean(outcome.bucket, "PRE_ARRIVAL", 24)
    local reason = clean(outcome.reason, "No outcome reason recorded.", 120)
    return string.format("%s | %s | %s | %s", status, phase, bucket, reason)
end

local function relativeClock(entry, at)
    local elapsed = math.max(0, (at or entry.startedAt or 0)
        - (entry.startedAt or at or 0))
    return KWR.Util:Clock(elapsed)
end

local function formatEpoch(value)
    value = KWR.Util:Number(value, nil)
    if value == nil then return "Unknown" end
    if type(date) == "function" then
        local ok, formatted = pcall(date, "%Y-%m-%d %H:%M:%S", value)
        if ok and type(formatted) == "string" then return formatted end
    end
    return tostring(value)
end

local function joinClean(values, separator)
    local result = {}
    for _, value in ipairs(values or {}) do
        result[#result + 1] = clean(value, "Unknown", 180)
    end
    return table.concat(result, separator or "; ")
end

local function average(list)
    local total, count = 0, 0
    for _, value in ipairs(list or {}) do
        value = KWR.Util:Number(value, nil)
        if value ~= nil then
            total = total + value
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return total / count
end

local function pickHighestKey(counts)
    local winner
    local winnerCount
    for key, count in pairs(counts or {}) do
        local value = KWR.Util:Number(count, 0) or 0
        if not winnerCount or value > winnerCount
            or (value == winnerCount and tostring(key) < tostring(winner)) then
            winner = tostring(key)
            winnerCount = value
        end
    end
    return winner
end

local function classifyDecisionReview(command, result)
    command = type(command) == "table" and command or {}
    local score = KWR.Util:Number(command.decisionScore
        or command.projectedWinProbability, nil)
    local confidenceScore = KWR.Util:Number(command.confidenceScore, nil)
    local activeOutcome = command.activePlayOutcome or {}
    local execution = command.executionAssessment or {}
    local organization = execution.organization or {}
    local trustMode = clean(command.trustMode, "UNKNOWN", 24)
    local enemyResponse = command.enemyResponsePlan or {}
    local commandResult = clean(result, "UNKNOWN", 24)

    local decisionQuality = "PLAYABLE"
    if commandResult == "VICTORY" then
        decisionQuality = (score or 0) >= 65 and "STRONG" or "PLAYABLE"
    elseif commandResult == "DEFEAT" then
        if trustMode == "CONSERVATIVE" or trustMode == "VERIFY" then
            decisionQuality = "THIN_READ"
        elseif (score or 0) >= 70 or (confidenceScore or 0) >= 70 then
            decisionQuality = "GOOD_CALL_LOST"
        elseif (score or 0) < 45 then
            decisionQuality = "BAD_CALL"
        else
            decisionQuality = "PLAYABLE"
        end
    end

    local executionQuality = "CLEAN"
    if organization.state == "DISORDERED" or organization.state == "SCATTERED" then
        executionQuality = "BROKEN"
    elseif activeOutcome.bucket == "PRE_ARRIVAL"
        or activeOutcome.bucket == "LATE_ARRIVAL" then
        executionQuality = "LATE"
    elseif activeOutcome.status == "FAILED" then
        executionQuality = "BROKEN"
    end

    local truthQuality = "STABLE"
    if trustMode == "CONSERVATIVE" or trustMode == "VERIFY" then
        truthQuality = "THIN"
    elseif trustMode == "LOCKED" then
        truthQuality = "STABLE"
    elseif trustMode ~= "UNKNOWN" then
        truthQuality = "PARTIAL"
    end

    local enemyReadQuality = "READY"
    if clean(enemyResponse.attributionHint, "UNKNOWN", 24) == "ENEMY_COUNTER_WINDOW"
        or clean(enemyResponse.responsePressure, "UNKNOWN", 24) == "HIGH" then
        enemyReadQuality = "OUTPLAYED"
    elseif clean(enemyResponse.confidence, "LOW", 16) == "LOW" then
        enemyReadQuality = "UNCLEAR"
    end

    local failureMode = "NONE"
    if commandResult == "DEFEAT" then
        if decisionQuality == "BAD_CALL" then
            failureMode = "CALL"
        elseif truthQuality == "THIN" then
            failureMode = "READ"
        elseif executionQuality == "LATE" or executionQuality == "BROKEN" then
            failureMode = "EXECUTION"
        elseif enemyReadQuality == "OUTPLAYED" then
            failureMode = "COUNTER"
        else
            failureMode = "CONTESTED"
        end
    end

    local recommendedLesson = "Stay on the reviewed line while battlefield truth remains intact."
    if failureMode == "READ" then
        recommendedLesson = "Keep the call reversible until objective and movement truth improve."
    elseif failureMode == "EXECUTION" then
        recommendedLesson = "The branch was playable, but the team must arrive together and hold the timing."
    elseif failureMode == "COUNTER" then
        recommendedLesson = clean(enemyResponse.safestReply,
            "Respect the enemy counter window and answer it before re-committing.", 140)
    elseif failureMode == "CALL" then
        recommendedLesson = "Protect the score floor first and refuse low-value side pressure."
    end

    local outcomeDriver = clean(command.outcomeDriver, "", 48)
    if outcomeDriver == "" then
        outcomeDriver = clean(enemyResponse.attributionHint, "UNKNOWN", 48)
    end

    return {
        decisionQuality = decisionQuality,
        executionQuality = executionQuality,
        truthQuality = truthQuality,
        enemyReadQuality = enemyReadQuality,
        failureMode = failureMode,
        outcomeDriver = outcomeDriver,
        recommendedLesson = recommendedLesson,
    }
end

local function sortedValues(records)
    local result = {}
    for _, record in pairs(records or {}) do result[#result + 1] = record end
    table.sort(result, function(a, b)
        return clean(a.name or a.shortName, "Unknown", 64)
            < clean(b.name or b.shortName, "Unknown", 64)
    end)
    return result
end

function AAR:Start(state)
    local snapshot = state.snapshot
    self.active = {
        id = tostring(epoch()) .. ":" .. tostring(snapshot.context.mapKey),
        addonVersion = KWR.version,
        schemaVersion = KWR.schemaVersion,
        mapKey = snapshot.context.mapKey,
        mapName = snapshot.context.mapName,
        team = KWR.Util:Copy(snapshot.context.team),
        startedAt = epoch(),
        scoreStart = KWR.Util:Copy(snapshot.score),
        scoreEnd = nil,
        commands = {},
        events = {},
        feedback = {
            sessionType = KWR.Util:Text(
                KWR.db and KWR.db.profile and KWR.db.profile.fieldReviewContext,
                "Diagnostic", 24),
        },
        planUsage = {},
        decisionReviews = {},
        friendlyTeam = {},
        enemyTeam = {},
        playerEvidence = {},
        objectiveTimeline = {},
        objectiveStates = {},
        seenObjectiveEvents = {},
        enemyThreats = {},
        ratingChange = nil,
        lastSignature = nil,
        matchComplete = false,
        performance = {
            samples = 0,
            maxRefreshMs = 0,
            maxP95Ms = 0,
            refreshSamples = {},
            maxMemoryKB = 0,
            firstMemoryKB = nil,
            lastMemoryKB = nil,
            maxTransitionMs = 0,
            errors = 0,
            errorBaseline = KWR.MatchRuntime and KWR.MatchRuntime.diagnostics
                and (KWR.MatchRuntime.diagnostics.errors or 0) or 0,
        },
        safetyBaseline = KWR.SafetyMonitor and KWR.SafetyMonitor:Snapshot() or {},
        safety = { blocked = 0, forbidden = 0, total = 0 },
    }
    self:PersistActive()
end

function AAR:CaptureRuntimeEvidence(active, state)
    local diagnostics = type(state.diagnostics) == "table" and state.diagnostics or {}
    local performance = active.performance or {}
    performance.samples = (performance.samples or 0) + 1
    local duration = KWR.Util:Number(diagnostics.lastDurationMs, nil)
    if duration and duration >= 0 then
        performance.maxRefreshMs = math.max(performance.maxRefreshMs or 0, duration)
        local samples = performance.refreshSamples or {}
        samples[#samples + 1] = duration
        if #samples > 120 then table.remove(samples, 1) end
        performance.refreshSamples = samples
    end
    local memory = KWR.Util:Number(diagnostics.memoryKB, nil)
    if memory and memory > 0 then
        performance.maxMemoryKB = math.max(performance.maxMemoryKB or 0, memory)
        if performance.firstMemoryKB == nil then
            performance.firstMemoryKB = memory
        end
        performance.lastMemoryKB = memory
    end
    performance.maxTransitionMs = math.max(
        performance.maxTransitionMs or 0,
        diagnostics.lastTransitionDurationMs or 0)
    performance.errors = math.max(performance.errors or 0,
        math.max(0, (diagnostics.errors or 0) - (performance.errorBaseline or 0)))
    active.performance = performance
end

function AAR:FinalizeRuntimeEvidence(active)
    local performance = active.performance or {}
    local samples = performance.refreshSamples or {}
    if #samples > 0 then
        table.sort(samples)
        local index = math.max(1, math.ceil(#samples * 0.95))
        performance.maxP95Ms = samples[index] or 0
    end
    performance.refreshSamples = nil
    active.performance = performance
    local baseline = active.safetyBaseline or {}
    local current = KWR.SafetyMonitor and KWR.SafetyMonitor:Snapshot() or {}
    active.safety = {
        blocked = math.max(0, (current.blocked or 0) - (baseline.blocked or 0)),
        forbidden = math.max(0, (current.forbidden or 0) - (baseline.forbidden or 0)),
    }
    active.safety.total = active.safety.blocked + active.safety.forbidden
    active.safetyBaseline = nil
end

function AAR:CaptureTeams(active, snapshot)
    for _, player in ipairs(snapshot.roster or {}) do
        local stored = claimEntityRecord(
            active.friendlyTeam, player, "friendly", displayEntity)
        mergeEntity(stored, player)
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local stored = claimEntityRecord(
            active.enemyTeam, enemy, "enemy", displayEntity)
        mergeEntity(stored, enemy)
    end
end

function AAR:CaptureScoreboard(active, snapshot)
    local assigned = snapshot.context and snapshot.context.team or {}
    local friendlyFaction = KWR.Util:Number(assigned.scoreFaction, nil)
    if friendlyFaction == nil then return end
    local playerName
    for _, player in ipairs(snapshot.roster or {}) do
        if player.unit == "player" then
            playerName = clean(player.name, "", 64):lower()
            break
        end
    end
    for _, row in ipairs(KWR.TeamResolver and KWR.TeamResolver.rows or {}) do
        local rowFaction = KWR.Util:Number(row.faction, nil)
        if rowFaction ~= nil then
            local friendly = rowFaction == friendlyFaction
            local collection = friendly and active.friendlyTeam or active.enemyTeam
            local stored = claimEntityRecord(collection, row,
                friendly and "friendly" or "enemy", displayEntity)
            mergeEntity(stored, row)
            for _, field in ipairs({
                "killingBlows", "honorableKills", "deaths", "damageDone",
                "healingDone", "rating", "ratingChange",
            }) do
                local value = KWR.Util:Number(row[field], nil)
                if value ~= nil then stored[field] = value end
            end
            if playerName and clean(row.name, "", 64):lower() == playerName
                and row.ratingChange ~= nil then
                active.ratingChange = KWR.Util:Number(row.ratingChange, nil)
            end
        end
    end
end

function AAR:CapturePlayerEvidence(active, state)
    local now = epoch()
    local assignments = assignmentByKey(state.assignments)
    local integrity = state.snapshot.assignmentIntegrity or {}
    local integrityByGUID = {}
    local integrityByName = {}
    for _, row in ipairs(integrity.rows or {}) do
        if row.guid then integrityByGUID[row.guid] = row end
        local name = clean(row.name, "", 64):lower()
        if name ~= "" then integrityByName[name] = row end
    end
    for _, player in ipairs(state.snapshot.roster or {}) do
        local evidence, key = claimEntityRecord(
            active.playerEvidence, player, "friendly", function(entity)
                return {
                    guid = clean(entity.guid, "", 80),
                    name = clean(entity.name or entity.shortName, "Unknown", 64),
                    locations = {},
                    notes = {},
                    deathsObserved = 0,
                }
            end)
        local assignment = assignments[key]
            or assignments["name:" .. clean(player.name, "", 64):lower()]
        if assignment then
            local role = clean(assignment.role, "Unknown", 40)
            local location = clean(assignment.location, "Unknown", 48)
            local signature = role .. "|" .. location
            if evidence.assignmentSignature ~= signature then
                evidence.assignedAt = now
                evidence.assignmentSignature = signature
            end
            evidence.assignedRole = role
            evidence.assignedLocation = location
            evidence.lastAssignedAt = now
        end
        local location = clean(player.location, "Unknown", 48)
        if location ~= "Unknown" and location ~= "Position restricted"
            and location ~= evidence.lastLocation then
                appendBounded(evidence.locations, {
                    at = now,
                    location = location,
                    source = clean(player.locationSource, "Observed", 32),
            }, self.maxPlayerLocations)
            evidence.lastLocation = location
        end
        local dead = KWR.Util:Boolean(player.dead, false)
        if dead and not evidence.wasDead then
            evidence.deathsObserved = evidence.deathsObserved + 1
        end
        evidence.wasDead = dead
        local integrityRow = (player.guid and integrityByGUID[player.guid])
            or integrityByName[clean(player.shortName or player.name, "", 64):lower()]
        if integrityRow and (integrityRow.status == "ABANDONED"
            or integrityRow.status == "UNAVAILABLE_DEAD"
            or integrityRow.status == "UNAVAILABLE_DISCONNECTED"
            or integrityRow.status == "ON_STATION") then
            local note = integrityRow.status .. " | assigned "
                .. clean(integrityRow.expected, "Unknown", 48) .. " | observed "
                .. clean(integrityRow.actual, "Unknown", 48)
            if note ~= evidence.lastIntegrityNote then
                appendBounded(evidence.notes, { at = now, text = note }, self.maxPlayerNotes)
                evidence.lastIntegrityNote = note
            end
        end
        active.playerEvidence[key] = evidence
    end
end

function AAR:CaptureObjectives(active, snapshot)
    local now = epoch()
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local label = clean(row.label, "Unknown Objective", 64)
        local owner = clean(row.owner, "UNKNOWN", 16)
        local state = clean(row.state, "UNKNOWN", 20)
        local previous = active.objectiveStates[label]
        if previous and (previous.owner ~= owner or previous.state ~= state) then
            appendBounded(active.objectiveTimeline, {
                at = now,
                kind = "STATE",
                objective = label,
                text = label .. ": " .. previous.owner .. "/" .. previous.state
                    .. " -> " .. owner .. "/" .. state,
                source = clean(row.source, snapshot.objectives.source or "unknown", 24),
            }, self.maxObjectiveTimeline)
        end
        active.objectiveStates[label] = { owner = owner, state = state }
    end
    for _, event in ipairs(snapshot.objectives and snapshot.objectives.events or {}) do
        local signature = clean(event.kind, "EVENT", 24) .. "|"
            .. clean(event.text, "", 160) .. "|"
            .. tostring(KWR.Util:Number(event.at, 0) or 0)
        if not active.seenObjectiveEvents[signature] then
            active.seenObjectiveEvents[signature] = true
            appendBounded(active.objectiveTimeline, {
                at = now,
                kind = clean(event.kind, "EVENT", 24),
                objective = clean(event.objective, "Unknown", 64),
                player = clean(event.player, "Unknown", 64),
                text = clean(event.text, "Objective event observed.", 160),
                source = "BG_SYSTEM",
            }, self.maxObjectiveTimeline)
        end
    end
end

function AAR:CaptureThreats(active, snapshot)
    local now = epoch()
    local killTarget = snapshot.combat and snapshot.combat.killTarget or nil
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local threat, key = claimEntityRecord(active.enemyThreats, enemy, "enemy", function(entity)
            return {
            guid = clean(entity.guid, "", 80),
            name = clean(entity.name or entity.shortName, "Unknown", 64),
            class = clean(entity.class or entity.classFile, "Unknown", 32),
            spec = clean(entity.spec, "Unknown", 32),
            role = clean(entity.role, "Unknown", 16),
            sightings = 0,
            flags = {},
            visible = false,
        }
        end)
        mergeEntity(threat, enemy)
        -- A sighting is a visibility episode, not a Store-refresh count.
        if enemy.visible == true and threat.visible ~= true then
            threat.sightings = threat.sightings + 1
        end
        threat.visible = enemy.visible == true
        threat.lastSeenLocation = clean(enemy.location, threat.lastSeenLocation or "Unknown", 48)
        threat.lastSeenAt = KWR.Util:Number(enemy.lastSeenAt, threat.lastSeenAt)
        threat.lastSeenAge = KWR.Util:Number(enemy.lastSeenAge, enemy.age or threat.lastSeenAge)
        if threat.role == "HEALER" then threat.flags.healer = true end
        if threat.classFile == "ROGUE" or threat.spec == "Feral" then
            threat.flags.stealth = true
        end
        if enemy.carrier then threat.flags.carrier = true end
        if canonicalEntityName(enemy) ~= "" and canonicalEntityName(enemy)
            == canonicalEntityName(killTarget) then
            threat.flags.highPressure = true
        end
        if enemy.localEngaged then threat.flags.highPressure = true end
        active.enemyThreats[key] = threat
    end
end

function AAR:Record(state)
    if not self.active then self:Start(state) end
    local active = self.active
    local snapshot = state.snapshot or {}
    local score = snapshot.score or {}
    local objectives = snapshot.objectives or {}
    local now = epoch()
    -- The AAR is a semantic review ledger, not a second copy of every Store
    -- tick. Sampling unchanged state inflated work, memory, and sightings.
    local recordSignature = KWR.Util:Signature({
        state.command and state.command.signature or "",
        score.friendly or 0,
        score.enemy or 0,
        snapshot.context and snapshot.context.matchComplete and "DONE" or "LIVE",
        #(objectives.events or {}),
        #(snapshot.roster or {}),
        #(snapshot.enemies or {}),
    })
    if active.lastRecordSignature == recordSignature
        and (now - (active.lastRecordAt or 0)) < 5 then
        return
    end
    active.lastRecordSignature = recordSignature
    active.lastRecordAt = now
    active.scoreEnd = KWR.Util:Copy(state.snapshot.score)
    active.team = KWR.Util:Copy(state.snapshot.context.team or active.team)
    active.matchComplete = active.matchComplete
        or state.snapshot.context.matchComplete == true
    active.truthQualified = state.snapshot.score.source == "ui_widget"
        and state.snapshot.context.team
        and state.snapshot.context.team.side ~= nil
    self:CaptureRuntimeEvidence(active, state)
    local reporter = state.snapshot.reporter or {}
    local combat = state.snapshot.combat or {}
    active.lastFeatures = {
        at = epoch(),
        phase = state.snapshot.context.phase,
        friendlyScore = state.snapshot.score.friendly,
        enemyScore = state.snapshot.score.enemy,
        friendlyObjectives = state.snapshot.objectives.friendly,
        enemyObjectives = state.snapshot.objectives.enemy,
        reporterRisk = reporter.risk,
        hotspot = reporter.hotspot and reporter.hotspot.label or nil,
        killTarget = combat.killTarget and combat.killTarget.shortName or nil,
        priorityCast = combat.priorityCast and combat.priorityCast.name or nil,
        commandSignature = state.command and state.command.signature or nil,
    }
    self:CaptureTeams(active, state.snapshot)
    self:CaptureScoreboard(active, state.snapshot)
    self:CapturePlayerEvidence(active, state)
    self:CaptureObjectives(active, state.snapshot)
    self:CaptureThreats(active, state.snapshot)
    local planID = state.snapshot.strategy and state.snapshot.strategy.planID
    if planID then
        active.planUsage[planID] = (active.planUsage[planID] or 0) + 1
    end
    local signature = state.command and state.command.signature
    if signature and signature ~= active.lastSignature then
        local review = commandReviewRecord(state)
        local previousCommand = active.commands[#active.commands]
        if previousCommand and previousCommand.outcome == "Unknown" then
            local target = clean(previousCommand.objectiveTarget, "Unknown", 64)
            for _, objective in ipairs(state.snapshot.objectives
                and state.snapshot.objectives.rows or {}) do
                if clean(objective.label, "", 64) == target then
                    previousCommand.outcome = "Observed when next command issued: "
                        .. target .. " "
                        .. clean(objective.owner, "UNKNOWN", 16) .. "/"
                        .. clean(objective.state, "UNKNOWN", 20)
                    break
                end
            end
            if previousCommand.activePlayOutcome
                and previousCommand.activePlayOutcome.status
                and previousCommand.activePlayOutcome.status ~= "LIVE" then
                previousCommand.outcome = activePlayOutcomeText(
                    previousCommand.activePlayOutcome)
            end
        end
        active.commands[#active.commands + 1] = {
            at = epoch(),
            status = review.status,
            action = review.action,
            who = review.who,
            reason = review.reason,
            confidence = review.confidence,
            confidenceScore = review.confidenceScore,
            risk = review.risk,
            expectedOutcome = review.expectedOutcome,
            projectedWinProbability = review.projectedWinProbability,
            decisionScore = review.decisionScore,
            projection = review.projection,
            recommendationMode = review.recommendationMode,
            evidence = review.evidence,
            simulations = review.simulations,
            executionAssessment = review.executionAssessment,
            enemyResponsePlan = review.enemyResponsePlan,
            responsePackage = review.responsePackage,
            mapState = {
                phase = clean(state.snapshot.context.phase, "UNKNOWN", 20),
                friendlyScore = KWR.Util:Number(state.snapshot.score.friendly, nil),
                enemyScore = KWR.Util:Number(state.snapshot.score.enemy, nil),
                friendlyObjectives = KWR.Util:Number(state.snapshot.objectives.friendly, nil),
                enemyObjectives = KWR.Util:Number(state.snapshot.objectives.enemy, nil),
            },
            objectiveTarget = review.objectiveTarget,
            assigned = review.assigned,
            manualOverrides = review.manualOverrides,
            abortCondition = review.abortCondition,
            activePlay = KWR.Util:Copy(state.activePlay
                or (state.command and state.command.activePlay) or {}),
            activePlayDecision = KWR.Util:Copy(
                state.command and state.command.activePlayDecision or {}),
            activePlayTrend = KWR.Util:Copy(
                state.command and state.command.activePlayTrend or {}),
            activePlayOutcome = KWR.Util:Copy(
                state.command and state.command.activePlayOutcome or {}),
            activePlayTransition = KWR.Util:Copy(
                state.command and state.command.activePlayTransition or {}),
            trustMode = clean(state.snapshot.strategy and state.snapshot.strategy.trust
                and state.snapshot.strategy.trust.mode, "UNKNOWN", 24),
            outcomeDriver = clean(state.snapshot.strategy and state.snapshot.strategy.scenarioCalibration
                and state.snapshot.strategy.scenarioCalibration.topOutcomeDriver,
                clean(state.snapshot.strategy and state.snapshot.strategy.enemyResponseID, "", 48), 48),
            outcome = "Unknown",
        }
        active.commands = trimList(active.commands, self.maxCommands)
        active.lastSignature = signature
    end
    local message = KWR.Util:Text(state.snapshot.lastMessage, "", 160)
    if message ~= "" and message ~= active.lastMessage then
        active.events[#active.events + 1] = { at = epoch(), text = message }
        active.events = trimList(active.events, self.maxEvents)
        active.lastMessage = message
    end
    local reporterEvents = state.snapshot.reporter and state.snapshot.reporter.events or {}
    local reporterEvent = reporterEvents[#reporterEvents]
    if reporterEvent and reporterEvent.id ~= active.lastReporterEventID then
        active.events[#active.events + 1] = {
            at = epoch(),
            text = "Reporter: " .. KWR.Util:Text(reporterEvent.text, "Movement update", 140),
        }
        active.events = trimList(active.events, self.maxEvents)
        active.lastReporterEventID = reporterEvent.id
    end
end

function AAR:DetermineResult(entry)
    local score = entry.scoreEnd or {}
    if entry.matchComplete and (score.max or 0) > 0 then
        if (score.friendly or 0) > (score.enemy or 0) then return "VICTORY" end
        if (score.friendly or 0) < (score.enemy or 0) then return "DEFEAT" end
        return "DRAW"
    end
    if (score.max or 0) > 0 then
        if (score.friendly or 0) >= score.max then return "VICTORY" end
        if (score.enemy or 0) >= score.max then return "DEFEAT" end
        if (score.friendly or 0) > (score.enemy or 0) then return "AHEAD" end
        if (score.friendly or 0) < (score.enemy or 0) then return "BEHIND" end
    end
    return "UNKNOWN"
end

function AAR:BuildDecisionReviews(commands, result)
    local reviews = {}
    local startIndex = math.max(1, #(commands or {}) - (self.maxDecisionReviews - 1))
    for index = startIndex, #(commands or {}) do
        local command = commands[index]
        local alternative = command.simulations and command.simulations[2]
        reviews[#reviews + 1] = {
            at = command.at,
            recommendation = command.action,
            recommendationMode = command.recommendationMode,
            expectedOutcome = command.expectedOutcome,
            projectedWinProbability = command.projectedWinProbability,
            decisionScore = command.decisionScore
                or command.projectedWinProbability,
            confidence = command.confidence,
            risk = command.risk,
            actualResult = result,
            outcomeAligned = (result == "VICTORY" and
                (command.decisionScore
                    or command.projectedWinProbability or 0) >= 50)
                or (result == "DEFEAT" and
                    (command.decisionScore
                        or command.projectedWinProbability or 100) < 50),
            competingOption = alternative and alternative.id,
            competingProbability = alternative and alternative.probability,
            evidenceReview = "DEVELOPER_REVIEW_REQUIRED",
        }
        local classification = classifyDecisionReview(command, result)
        for key, value in pairs(classification) do
            reviews[#reviews][key] = value
        end
    end
    return reviews
end

function AAR:BuildReviewQueue(entry)
    local queue, performance, stability = {}, entry.performance or {}, entry.commandStability or {}
    local function add(kind, detail, priority)
        queue[#queue + 1] = { kind = kind, detail = clean(detail, "Review required.", 160), priority = priority }
    end
    if (performance.errors or 0) > 0 then
        add("RUNTIME_ERROR", "Runtime errors recorded: " .. tostring(performance.errors), "HIGH")
    end
    if (performance.maxP95Ms or 0) >= 2 or (performance.maxRefreshMs or 0) >= 10 then
        add("PERFORMANCE", string.format("Refresh p95 %.2f ms / max %.2f ms", performance.maxP95Ms or 0, performance.maxRefreshMs or 0), "HIGH")
    end
    if (stability.reversals or 0) > 0 or (stability.invalidationsAfterCommitment or 0) > 0 then
        add("COMMAND_STABILITY", "Reversals " .. tostring(stability.reversals or 0) .. "; late invalidations " .. tostring(stability.invalidationsAfterCommitment or 0), "MEDIUM")
    end
    for _, review in ipairs(entry.decisionReviews or {}) do
        if review.outcomeAligned == false then
            add("OUTCOME_MISMATCH", "Plan " .. clean(review.recommendation, "Unknown", 72) .. " contradicted match outcome.", "MEDIUM")
        end
    end
    return trimList(queue, self.maxReviewQueue)
end

function AAR:BuildCommandStabilitySummary()
    local metrics = KWR.Commander and KWR.Commander.GetStabilityMetrics
        and KWR.Commander:GetStabilityMetrics() or {}
    local overrides = KWR.Commander and KWR.Commander.GetOverrideLog
        and KWR.Commander:GetOverrideLog() or {}
    local suppressions = KWR.Commander and KWR.Commander.GetSuppressionLog
        and KWR.Commander:GetSuppressionLog() or {}
    local latestOverride = overrides[#overrides]
    local latestSuppression = suppressions[#suppressions]
    return {
        evaluations = KWR.Util:Number(metrics.evaluations, 0) or 0,
        issued = KWR.Util:Number(metrics.issued, 0) or 0,
        replacements = KWR.Util:Number(metrics.replacements, 0) or 0,
        stabilized = KWR.Util:Number(metrics.stabilized, 0) or 0,
        reversals = KWR.Util:Number(metrics.reversals, 0) or 0,
        preMoveInvalidations = KWR.Util:Number(metrics.preMovementInvalidations, 0) or 0,
        preMoveInvalidationRate = KWR.Util:Number(metrics.preMovementInvalidationRate, 0) or 0,
        emergencyBypasses = KWR.Util:Number(metrics.emergencyBypasses, 0) or 0,
        reassessmentBypasses = KWR.Util:Number(metrics.reassessmentBypasses, 0) or 0,
        responseBypasses = KWR.Util:Number(metrics.responseBypasses, 0) or 0,
        candidateBypasses = KWR.Util:Number(metrics.candidateBypasses, 0) or 0,
        overrides = KWR.Util:Number(metrics.overrides, 0) or 0,
        overridesBeforeArrival = KWR.Util:Number(metrics.overridesBeforeArrival, 0) or 0,
        overridesAfterCommitment = KWR.Util:Number(metrics.overridesAfterCommitment, 0) or 0,
        invalidations = KWR.Util:Number(metrics.invalidations, 0) or 0,
        invalidationsBeforeArrival = KWR.Util:Number(metrics.invalidationsBeforeArrival, 0) or 0,
        invalidationsAfterCommitment = KWR.Util:Number(metrics.invalidationsAfterCommitment, 0) or 0,
        successfulPlays = KWR.Util:Number(metrics.successfulPlays, 0) or 0,
        successRate = KWR.Util:Number(metrics.successRate, 0) or 0,
        averageSwitchAdvantage = KWR.Util:Number(metrics.averageSwitchAdvantage, 0) or 0,
        activePlayRetains = KWR.Util:Number(metrics.activePlayRetains, 0) or 0,
        retainedRecords = #(KWR.Commander:GetHistory() or {}),
        suppressedAlternatives = KWR.Util:Number(metrics.suppressedAlternatives, 0) or 0,
        suppressedByPersistence = KWR.Util:Number(metrics.suppressedByPersistence, 0) or 0,
        suppressedBySuperiority = KWR.Util:Number(metrics.suppressedBySuperiority, 0) or 0,
        averageLifetime = KWR.Util:Number(metrics.averageLifetime, 0) or 0,
        medianLifetime = KWR.Util:Number(metrics.medianLifetime, 0) or 0,
        shortestLifetime = KWR.Util:Number(metrics.shortestLifetime, 0) or 0,
        longestLifetime = KWR.Util:Number(metrics.longestLifetime, 0) or 0,
        reversalRate = KWR.Util:Number(metrics.reversalRate, 0) or 0,
        commandHealth = clean(metrics.commandHealth, "UNKNOWN", 16),
        commandHealthReason = clean(metrics.commandHealthReason, "No stability budget reason.", 120),
        certificationStatus = clean(metrics.certificationStatus, "INSUFFICIENT_SAMPLE", 32),
        certificationReason = clean(metrics.certificationReason, "Collect more command samples.", 120),
        latestOverride = latestOverride and {
            at = KWR.Util:Number(latestOverride.at, nil),
            currentObjective = clean(latestOverride.currentObjective, "Unknown", 48),
            candidateObjective = clean(latestOverride.candidateObjective, "Unknown", 48),
            phase = clean(latestOverride.phase, "Unknown", 24),
            phaseBucket = clean(latestOverride.phaseBucket, "Unknown", 24),
            invalidation = clean(latestOverride.invalidation, "", 48),
            invalidationFamily = clean(latestOverride.invalidationFamily, "NONE", 24),
            replacementReason = clean(latestOverride.replacementReason, "", 64),
            gateClass = clean(latestOverride.gateClass, "STEADY", 24),
            lostCommitmentTime = KWR.Util:Number(latestOverride.lostCommitmentTime, nil),
            observedDuration = KWR.Util:Number(latestOverride.observedDuration, nil),
            requiredDuration = KWR.Util:Number(latestOverride.requiredDuration, nil),
        } or nil,
        latestSuppression = latestSuppression and {
            at = KWR.Util:Number(latestSuppression.at, nil),
            currentObjective = clean(latestSuppression.currentObjective, "Unknown", 48),
            candidateObjective = clean(latestSuppression.candidateObjective, "Unknown", 48),
            phase = clean(latestSuppression.phase, "Unknown", 24),
            phaseBucket = clean(latestSuppression.phaseBucket, "Unknown", 24),
            invalidation = clean(latestSuppression.invalidation, "", 48),
            invalidationFamily = clean(latestSuppression.invalidationFamily, "NONE", 24),
            replacementReason = clean(latestSuppression.replacementReason, "", 64),
            gateClass = clean(latestSuppression.gateClass, "STEADY", 24),
            lostCommitmentTime = KWR.Util:Number(latestSuppression.lostCommitmentTime, nil),
            observedDuration = KWR.Util:Number(latestSuppression.observedDuration, nil),
            requiredDuration = KWR.Util:Number(latestSuppression.requiredDuration, nil),
        } or nil,
    }
end

function AAR:CompactEntry(entry)
    if type(entry) ~= "table" then return nil end
    entry.commands = trimList(entry.commands or {}, self.maxCommands)
    entry.events = trimList(entry.events or {}, self.maxEvents)
    entry.objectiveTimeline = trimList(
        entry.objectiveTimeline or {}, self.maxObjectiveTimeline)
    entry.decisionReviews = trimList(
        entry.decisionReviews or {}, self.maxDecisionReviews)
    entry.reviewQueue = trimList(entry.reviewQueue or {}, self.maxReviewQueue)
    entry.playerEvidence = type(entry.playerEvidence) == "table"
        and entry.playerEvidence or {}
    for key, evidence in pairs(entry.playerEvidence) do
        entry.playerEvidence[key] = compactPlayerEvidence(
            evidence, self.maxPlayerLocations, self.maxPlayerNotes)
    end
    entry.enemyThreats = compactThreats(entry.enemyThreats)
    entry.feedback = type(entry.feedback) == "table" and entry.feedback or {}
    entry.planUsage = type(entry.planUsage) == "table" and entry.planUsage or {}
    entry.friendlyTeam = type(entry.friendlyTeam) == "table" and entry.friendlyTeam or {}
    entry.enemyTeam = type(entry.enemyTeam) == "table" and entry.enemyTeam or {}
    return entry
end

function AAR:TrimHistory()
    local history = self:GetHistory()
    history = trimList(history, self.maxHistory)
    local compacted = {}
    for index = 1, #history do
        local entry = self:CompactEntry(history[index])
        if entry then
            compacted[#compacted + 1] = entry
        end
    end
    KWR.db.journal.history = compacted
    if self.lastCompleted then
        self.lastCompleted = self:CompactEntry(self.lastCompleted)
    end
    if KWR.db and KWR.db.journal then
        KWR.db.journal.interrupted = self:CompactEntry(KWR.db.journal.interrupted)
    end
end

function AAR:PersistActive()
    if not KWR.db or not KWR.db.journal then
        return
    end
    if not self.active then
        KWR.db.journal.interrupted = nil
        return
    end
    local checkpoint = self:CompactEntry(copyEntry(self.active))
    if checkpoint then
        checkpoint.result = "INTERRUPTED"
        checkpoint.partial = true
        checkpoint.interruptionReason = clean(
            checkpoint.interruptionReason,
            "Interrupted before battleground completion.",
            160)
        KWR.db.journal.interrupted = checkpoint
    end
end

function AAR:CommitInterrupted(reason)
    if not self.active then
        return false
    end
    self:Record({
        snapshot = {
            score = self.active.scoreEnd or self.active.scoreStart or {},
            context = {
                matchComplete = false,
                team = self.active.team or {},
            },
            objectives = { rows = {}, events = {} },
            roster = {},
            enemies = {},
            reporter = {},
            combat = {},
        },
        assignments = {},
        command = self.active.commands[#(self.active.commands or {})],
        prediction = nil,
    })
    local entry = self.active
    entry.endedAt = epoch()
    entry.duration = math.max(0, entry.endedAt - (entry.startedAt or entry.endedAt))
    entry.result = "INTERRUPTED"
    entry.partial = true
    entry.interruptionReason = clean(reason,
        "Reload, relog, or disable occurred before battleground completion.", 160)
    entry.finalCommand = entry.commands[#entry.commands]
    if entry.finalCommand then
        entry.finalCommand.outcome = "Interrupted: " .. entry.interruptionReason
    end
    entry.decisionReviews = self:BuildDecisionReviews(entry.commands, entry.result)
    entry.commandStability = self:BuildCommandStabilitySummary()
    self:FinalizeRuntimeEvidence(entry)
    entry.reviewQueue = self:BuildReviewQueue(entry)
    KWR.db.journal.history[#KWR.db.journal.history + 1] = entry
    KWR.db.journal.history = trimList(KWR.db.journal.history, self.maxHistory)
    self.lastCompleted = entry
    self.active = nil
    self:PersistActive()
    self:TrimHistory()
    return true
end

function AAR:Finish(state)
    if not self.active then return end
    self:Record(state)
    local entry = self.active
    entry.endedAt = epoch()
    entry.duration = math.max(0, entry.endedAt - (entry.startedAt or entry.endedAt))
    entry.result = self:DetermineResult(entry)
    entry.finalCommand = entry.commands[#entry.commands]
    if entry.finalCommand then
        if entry.finalCommand.activePlayOutcome
            and entry.finalCommand.activePlayOutcome.status
            and entry.finalCommand.activePlayOutcome.status ~= "LIVE" then
            entry.finalCommand.outcome = activePlayOutcomeText(
                entry.finalCommand.activePlayOutcome)
        else
            entry.finalCommand.outcome = "Match ended: " .. entry.result
        end
    end
    local primaryPlanID, primaryCount
    for planID, count in pairs(entry.planUsage or {}) do
        if not primaryCount or count > primaryCount then
            primaryPlanID, primaryCount = planID, count
        end
    end
    entry.primaryPlanID = primaryPlanID
    entry.decisionReviews = self:BuildDecisionReviews(entry.commands, entry.result)
    entry.commandStability = self:BuildCommandStabilitySummary()
    self:FinalizeRuntimeEvidence(entry)
    entry.reviewQueue = self:BuildReviewQueue(entry)
    entry.outcomeAttribution = entry.decisionReviews[#entry.decisionReviews]
        and KWR.Util:Copy(entry.decisionReviews[#entry.decisionReviews]) or nil
    if KWR.OpponentModels and KWR.OpponentModels.RecordMatch then
        KWR.OpponentModels:RecordMatch(entry)
    end
    KWR.db.journal.history[#KWR.db.journal.history + 1] = entry
    KWR.db.journal.history = trimList(KWR.db.journal.history, self.maxHistory)
    self:TrimHistory()
    self.lastCompleted = entry
    self.active = nil
    self:PersistActive()
    KWR:Print("AAR evidence ready: use /kwr aar copy.", true)
    if KWR.db.profile.aar.autoOpen and KWR.AARWindow and C_Timer and C_Timer.After then
        C_Timer.After(1.0, function() KWR.AARWindow:Show(entry.id) end)
    end
end

function AAR:Update(state, previous)
    if not KWR.db.profile.aar.enabled then
        self:CommitInterrupted("AAR capture was disabled before battleground completion.")
        return
    end
    local live = state.snapshot.context.inPvP and not state.snapshot.context.preview
    local wasLive = previous and previous.snapshot.context.inPvP and not previous.snapshot.context.preview
    if live then
        if state.snapshot.context.matchComplete == true then
            self:Finish(state)
        else
            self:Record(state)
            self:PersistActive()
        end
    elseif wasLive then
        self:Finish(previous)
    end
end

function AAR:GetLatest()
    local history = self:GetHistory()
    return history[#history] or self.lastCompleted
end

local function unknown(value)
    if value == nil or value == "" then return "Unknown" end
    return tostring(value)
end

local function sessionType(value)
    value = clean(value, "", 24)
    if value == "Commander" or value == "Spectator" or value == "Diagnostic" then
        return value
    end
    return ""
end

local function sessionInterpretation(value)
    if value == "Spectator" then
        return "Interpretation: observer evidence only; outcome is not a clean command-follow verdict."
    end
    if value == "Diagnostic" then
        return "Interpretation: diagnostic run; use for system evidence, not team-follow compliance."
    end
    if value == "Commander" then
        return "Interpretation: live command session; evaluate both call quality and team follow-through."
    end
    return "Interpretation: session context was not explicitly tagged."
end

function AAR:Export(entry)
    entry = entry or self:GetLatest()
    if not entry then return nil, "No completed KWR match evidence is available." end
    local lines = {
        "========== KWR MATCH EXPORT ==========",
        "Version: " .. clean(entry.addonVersion or KWR.version, "Unknown", 32),
        "Map: " .. clean(entry.mapName or entry.mapKey, "Unknown", 80),
        "Result: " .. clean(entry.result, "Unknown", 20),
        "Final Score: " .. (entry.scoreEnd
            and (unknown(entry.scoreEnd.friendly) .. " - " .. unknown(entry.scoreEnd.enemy))
            or "Unknown"),
        "Duration: " .. (entry.duration and KWR.Util:Clock(entry.duration) or "Unknown"),
        "Start: " .. formatEpoch(entry.startedAt),
        "End: " .. formatEpoch(entry.endedAt),
        "Rating Change: " .. unknown(entry.ratingChange),
        "Team Faction: " .. clean(entry.team and entry.team.faction, "Unknown", 16),
        "Review Context: " .. unknown(entry.feedback and sessionType(entry.feedback.sessionType) or ""),
        sessionInterpretation(sessionType(entry.feedback and entry.feedback.sessionType)),
        string.format("Runtime: samples %d | refresh max %.3f ms | p95 max %.3f ms | memory %.1f -> %.1f KB / max %.1f KB | transition max %.3f ms | errors %d",
            entry.performance and entry.performance.samples or 0,
            entry.performance and entry.performance.maxRefreshMs or 0,
            entry.performance and entry.performance.maxP95Ms or 0,
            entry.performance and entry.performance.firstMemoryKB or 0,
            entry.performance and entry.performance.lastMemoryKB or 0,
            entry.performance and entry.performance.maxMemoryKB or 0,
            entry.performance and entry.performance.maxTransitionMs or 0,
            entry.performance and entry.performance.errors or 0),
        string.format("Safety: blocked %d | forbidden %d | total %d",
            entry.safety and entry.safety.blocked or 0,
            entry.safety and entry.safety.forbidden or 0,
            entry.safety and entry.safety.total or 0),
        "",
        "Friendly Team:",
    }
    local friendly = sortedValues(entry.friendlyTeam)
    if #friendly == 0 then lines[#lines + 1] = "- Unknown" end
    for _, player in ipairs(friendly) do
        lines[#lines + 1] = string.format("- %s | %s | %s | %s | source %s",
            clean(player.name, "Unknown", 64), clean(player.class, "Unknown", 32),
            clean(player.spec, "Unknown", 32), clean(player.role, "Unknown", 16),
            clean(player.specSource, "unknown", 24))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Enemy Team:"
    local enemies = sortedValues(entry.enemyTeam)
    if #enemies == 0 then lines[#lines + 1] = "- Unknown" end
    for _, enemy in ipairs(enemies) do
        lines[#lines + 1] = string.format("- %s | %s | %s | %s | source %s",
            clean(enemy.name, "Unknown", 64), clean(enemy.class, "Unknown", 32),
            clean(enemy.spec, "Unknown", 32), clean(enemy.role, "Unknown", 16),
            clean(enemy.specSource, "unknown", 24))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "KWR Command Timeline:"
    if #(entry.commands or {}) == 0 then lines[#lines + 1] = "- No commands recorded." end
    for _, command in ipairs(entry.commands or {}) do
        local mapState = command.mapState or {}
        lines[#lines + 1] = string.format(
            "- +%s | state %s %s-%s objectives %s-%s | target %s | action %s | assigned %s | confidence %s (%s) | risk %s",
            relativeClock(entry, command.at), clean(mapState.phase, "Unknown", 20),
            unknown(mapState.friendlyScore), unknown(mapState.enemyScore),
            unknown(mapState.friendlyObjectives), unknown(mapState.enemyObjectives),
            clean(command.objectiveTarget, "Unknown", 64),
            clean(command.action, "Unknown", 160), clean(command.assigned or command.who, "Unknown", 120),
            clean(command.confidence, "Unknown", 16), unknown(command.confidenceScore),
            clean(command.risk, "Unknown", 16))
        lines[#lines + 1] = "  Evidence: "
            .. (#(command.evidence or {}) > 0
                and joinClean(command.evidence, "; ") or "Unknown")
        lines[#lines + 1] = "  Abort/Pivot: "
            .. clean(command.abortCondition, "Unknown", 180)
        local execution = command.executionAssessment or {}
        local commitment = execution.commitment or {}
        local collapse = execution.collapse or {}
        local organization = execution.organization or {}
        local nextAction = execution.actionOpportunity or {}
        lines[#lines + 1] = string.format(
            "  Execution: %s (%s) | commitment %s @ %s | collapse %s | organization %s/%s",
            clean(nextAction.action, "Unknown", 32),
            unknown(nextAction.score),
            clean(commitment.state, "Unknown", 32),
            clean(commitment.objective, "Unknown", 48),
            clean(collapse.state, "Unknown", 24),
            clean(organization.state, "Unknown", 24),
            unknown(organization.entropy))
        local activePlay = command.activePlay or {}
        local activeDecision = command.activePlayDecision or {}
        local activeOutcome = command.activePlayOutcome or {}
        local activeTransition = command.activePlayTransition or {}
        local replacementScore = activeDecision.replacementScore or {}
        lines[#lines + 1] = string.format(
            "  Active play: %s | %s | phase %s | milestone %s | commit %.1fs travel %.1fs interaction %.1fs",
            clean(activePlay.family, "WORLD", 24),
            clean(activePlay.objective, "current lane", 48),
            clean(activePlay.phase, "UNKNOWN", 24),
            clean(activePlay.milestone, "NONE", 32),
            KWR.Util:Number(activePlay.commitmentSeconds, 0) or 0,
            KWR.Util:Number(activePlay.travelSeconds, 0) or 0,
            KWR.Util:Number(activePlay.interactionSeconds, 0) or 0)
        lines[#lines + 1] = string.format(
            "  Persistence gate: observed %.1fs | required %.1fs | retained %s | replace %s",
            KWR.Util:Number(replacementScore.observedDuration, 0) or 0,
            KWR.Util:Number(replacementScore.requiredDuration, 0) or 0,
            activeDecision.retained and "YES" or "NO",
            activeDecision.replacementAllowed and "YES" or "NO")
        lines[#lines + 1] = string.format(
            "  Gate class: %s | invalidation family %s",
            clean(activeDecision.gateClass, "STEADY", 24),
            clean(activeDecision.invalidationFamily, "NONE", 24))
        lines[#lines + 1] = string.format(
            "  Transition: %s | %s -> %s | rule %s | age %.1fs",
            clean(activeTransition.trigger, "STEADY", 24),
            clean(activeTransition.fromPhase, "NONE", 24),
            clean(activeTransition.toPhase, "UNKNOWN", 24),
            clean(activeTransition.rule, "none", 48),
            KWR.Util:Number(activeTransition.age, 0) or 0)
        lines[#lines + 1] = "  Play outcome: " .. activePlayOutcomeText(activeOutcome)
        local response = command.responsePackage or {}
        lines[#lines + 1] = string.format(
            "  Response: %s | move %s | stay %s | qualified %s",
            clean(response.action, "Hold current plan", 120),
            clean(response.moverText, "Team", 100),
            clean(response.stayerText, "Assigned defenders", 100),
            response.qualified and "YES" or "NO")
        if #(command.manualOverrides or {}) > 0 then
            lines[#lines + 1] = "  Commander overrides: "
                .. joinClean(command.manualOverrides, " ; ")
        end
        lines[#lines + 1] = "  Outcome: " .. clean(command.outcome, "Unknown", 80)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Command Stability:"
    local stability = entry.commandStability or {}
    lines[#lines + 1] = string.format(
        "- Evaluations %s | issued %s | replacements %s | stabilized %s | reversals %s | retained records %s | suppressed %s",
        unknown(stability.evaluations), unknown(stability.issued), unknown(stability.replacements),
        unknown(stability.stabilized), unknown(stability.reversals),
        unknown(stability.retainedRecords), unknown(stability.suppressedAlternatives))
    lines[#lines + 1] = string.format("- Stability budget: %s | %s",
        clean(stability.commandHealth, "UNKNOWN", 16),
        clean(stability.commandHealthReason, "No stability budget reason.", 120))
    lines[#lines + 1] = string.format("- Field certification: %s | %s",
        clean(stability.certificationStatus, "INSUFFICIENT_SAMPLE", 32),
        clean(stability.certificationReason, "Collect more command samples.", 120))
    lines[#lines + 1] = string.format(
        "- ActivePlay switches %s | invalidations %s | pre-move invalidations %s | avg lifetime %s | median %s",
        unknown(stability.overrides), unknown(stability.invalidations),
        unknown(stability.preMoveInvalidations),
        stability.averageLifetime and KWR.Util:Clock(stability.averageLifetime) or "Unknown",
        stability.medianLifetime and KWR.Util:Clock(stability.medianLifetime) or "Unknown")
    lines[#lines + 1] = string.format(
        "- Churn detail: suppress persistence %s | suppress superiority %s | ActivePlay switches pre-arrival %s / committed %s | invalidations pre-arrival %s / committed %s",
        unknown(stability.suppressedByPersistence),
        unknown(stability.suppressedBySuperiority),
        unknown(stability.overridesBeforeArrival),
        unknown(stability.overridesAfterCommitment),
        unknown(stability.invalidationsBeforeArrival),
        unknown(stability.invalidationsAfterCommitment))
    lines[#lines + 1] = string.format(
        "- Bypass detail: response %s | reassessment %s | emergency %s | candidate %s",
        unknown(stability.responseBypasses),
        unknown(stability.reassessmentBypasses),
        unknown(stability.emergencyBypasses),
        unknown(stability.candidateBypasses))
    lines[#lines + 1] = string.format(
        "- Result quality: successes %s | success rate %.1f%% | average switch advantage %.1f",
        unknown(stability.successfulPlays),
        (KWR.Util:Number(stability.successRate, 0) or 0) * 100,
        KWR.Util:Number(stability.averageSwitchAdvantage, 0) or 0)
    local attribution = entry.outcomeAttribution or {}
    lines[#lines + 1] = string.format(
        "- Outcome attribution: call %s | execution %s | truth %s | enemy %s | failure %s",
        clean(attribution.decisionQuality, "UNKNOWN", 24),
        clean(attribution.executionQuality, "UNKNOWN", 24),
        clean(attribution.truthQuality, "UNKNOWN", 24),
        clean(attribution.enemyReadQuality, "UNKNOWN", 24),
        clean(attribution.failureMode, "NONE", 24))
    lines[#lines + 1] = string.format(
        "- Recommended lesson: %s",
        clean(attribution.recommendedLesson, "Review the decisive swing.", 180))
    local latestCommand = entry.commands and entry.commands[#entry.commands] or nil
    local latestActivePlay = latestCommand and latestCommand.activePlay or {}
    local latestDecision = latestCommand and latestCommand.activePlayDecision or {}
    local latestReplacementScore = latestDecision.replacementScore or {}
    lines[#lines + 1] = string.format(
        "- Latest active play: %s | %s | phase %s | commit %.1fs | travel %.1fs | interaction %.1fs",
        clean(latestActivePlay.family, "WORLD", 24),
        clean(latestActivePlay.objective, "current lane", 48),
        clean(latestActivePlay.phase, "UNKNOWN", 24),
        KWR.Util:Number(latestActivePlay.commitmentSeconds, 0) or 0,
        KWR.Util:Number(latestActivePlay.travelSeconds, 0) or 0,
        KWR.Util:Number(latestActivePlay.interactionSeconds, 0) or 0)
    lines[#lines + 1] = string.format(
        "- Latest persistence gate: observed %.1fs | required %.1fs | retained %s | replace %s",
        KWR.Util:Number(latestReplacementScore.observedDuration, 0) or 0,
        KWR.Util:Number(latestReplacementScore.requiredDuration, 0) or 0,
        latestDecision.retained and "YES" or "NO",
        latestDecision.replacementAllowed and "YES" or "NO")
    local latestOverride = stability.latestOverride
    if latestOverride then
        lines[#lines + 1] = string.format(
            "- Latest override: %s -> %s | phase %s (%s) | invalidation %s [%s] | gate %s | reason %s | lost commitment %s | observed %.1fs / required %.1fs",
            clean(latestOverride.currentObjective, "Unknown", 48),
            clean(latestOverride.candidateObjective, "Unknown", 48),
            clean(latestOverride.phase, "Unknown", 24),
            clean(latestOverride.phaseBucket, "unknown", 24),
            clean(latestOverride.invalidation, "none", 48),
            clean(latestOverride.invalidationFamily, "NONE", 24),
            clean(latestOverride.gateClass, "STEADY", 24),
            clean(latestOverride.replacementReason, "Unknown", 64),
            latestOverride.lostCommitmentTime
                and KWR.Util:Clock(latestOverride.lostCommitmentTime) or "Unknown",
            KWR.Util:Number(latestOverride.observedDuration, 0) or 0,
            KWR.Util:Number(latestOverride.requiredDuration, 0) or 0)
    end
    local latestSuppression = stability.latestSuppression
    if latestSuppression then
        lines[#lines + 1] = string.format(
            "- Latest suppression: %s -> %s | phase %s (%s) | invalidation %s [%s] | gate %s | reason %s | observed %.1fs / required %.1fs",
            clean(latestSuppression.currentObjective, "Unknown", 48),
            clean(latestSuppression.candidateObjective, "Unknown", 48),
            clean(latestSuppression.phase, "Unknown", 24),
            clean(latestSuppression.phaseBucket, "unknown", 24),
            clean(latestSuppression.invalidation, "none", 48),
            clean(latestSuppression.invalidationFamily, "NONE", 24),
            clean(latestSuppression.gateClass, "STEADY", 24),
            clean(latestSuppression.replacementReason, "Unknown", 64),
            KWR.Util:Number(latestSuppression.observedDuration, 0) or 0,
            KWR.Util:Number(latestSuppression.requiredDuration, 0) or 0)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Objective Timeline:"
    if #(entry.objectiveTimeline or {}) == 0 then
        lines[#lines + 1] = "- No qualified objective transitions recorded."
    end
    for _, event in ipairs(entry.objectiveTimeline or {}) do
        lines[#lines + 1] = string.format("- +%s | %s | %s | source %s",
            relativeClock(entry, event.at), clean(event.kind, "EVENT", 24),
            clean(event.text, "Unknown", 180), clean(event.source, "unknown", 24))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Player Evidence:"
    local players = sortedValues(entry.playerEvidence)
    if #players == 0 then lines[#lines + 1] = "- Unknown" end
    for _, player in ipairs(players) do
        local teamRow = entry.friendlyTeam and entry.friendlyTeam[
            player.guid ~= "" and player.guid or ("friendly:" .. player.name:lower())] or {}
        local assignedSeconds = player.assignedAt and player.lastAssignedAt
            and math.max(0, player.lastAssignedAt - player.assignedAt) or nil
        lines[#lines + 1] = string.format(
            "- %s | assignment %s @ %s | assigned time %s | last seen %s | deaths %s | KB %s | damage %s | healing %s",
            clean(player.name, "Unknown", 64), clean(player.assignedRole, "Unknown", 40),
            clean(player.assignedLocation, "Unknown", 48),
            assignedSeconds and KWR.Util:Clock(assignedSeconds) or "Unknown",
            clean(player.lastLocation, "Unknown", 48),
            unknown(teamRow.deaths or player.deathsObserved),
            unknown(teamRow.killingBlows), unknown(teamRow.damageDone),
            unknown(teamRow.healingDone))
        for _, note in ipairs(player.notes or {}) do
            lines[#lines + 1] = "  Evidence note +" .. relativeClock(entry, note.at)
                .. ": " .. clean(note.text, "Unknown", 180)
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Enemy Threats:"
    local threats = sortedValues(entry.enemyThreats)
    if #threats == 0 then lines[#lines + 1] = "- Unknown" end
    for _, threat in ipairs(threats) do
        local flags = {}
        if threat.flags and threat.flags.stealth then flags[#flags + 1] = "stealth-capable" end
        if threat.flags and threat.flags.healer then flags[#flags + 1] = "healer" end
        if threat.flags and threat.flags.carrier then flags[#flags + 1] = "carrier observed" end
        if threat.flags and threat.flags.highPressure then flags[#flags + 1] = "local pressure observed" end
        lines[#lines + 1] = string.format(
            "- %s | %s %s | last seen %s | age %s | sightings %s | %s",
            clean(threat.name, "Unknown", 64), clean(threat.spec, "Unknown", 32),
            clean(threat.class, "Unknown", 32),
            clean(threat.lastSeenLocation, "Unknown", 48),
            threat.lastSeenAge and (tostring(math.floor(threat.lastSeenAge)) .. "s") or "Unknown",
            unknown(threat.sightings),
            #flags > 0 and table.concat(flags, ", ") or "no qualified threat flag")
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Known Limitations:"
    lines[#lines + 1] = "- Unknown values were not inferred."
    lines[#lines + 1] = "- Positions, score statistics, rating, auras, and outcomes appear only when safely exposed."
    lines[#lines + 1] = "- Assignment notes describe observed evidence, not player intent."
    lines[#lines + 1] = "- Enemy plans are not inferred by this export."
    lines[#lines + 1] = "- KWR recommendations are separated from observed execution and match outcome."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "========== END EXPORT =========="
    return table.concat(lines, "\n")
end

function AAR:ClearCompleted()
    if self.active then
        return false, "A live match is being recorded; completed AAR history was not cleared."
    end
    if KWR.db and KWR.db.journal then
        KWR.db.journal.history = {}
        KWR.db.journal.interrupted = nil
    end
    self.lastCompleted = nil
    return true
end

function AAR:GetHistory()
    return KWR.db and KWR.db.journal and KWR.db.journal.history or {}
end

function AAR:GetByID(id)
    if self.active and self.active.id == id then
        return self.active
    end
    for _, entry in ipairs(self:GetHistory()) do
        if entry.id == id then return entry end
    end
    if self.lastCompleted and self.lastCompleted.id == id then
        return self.lastCompleted
    end
end

function AAR:SaveFeedback(id, feedback)
    local entry = self:GetByID(id)
    if not entry then return false end
    entry.feedback = {
        sessionType = sessionType(feedback.sessionType),
        wonBy = KWR.Util:Text(feedback.wonBy, "", 40),
        strength = KWR.Util:Text(feedback.strength, "", 40),
        heldBack = KWR.Util:Text(feedback.heldBack, "", 40),
        gameChanger = KWR.Util:Text(feedback.gameChanger, "", 48),
        notes = KWR.Util:Text(feedback.notes, "", 500),
    }
    if KWR.Learning then KWR.Learning:RecordReviewed(entry) end
    return true
end

function AAR:GetInsights()
    local history = self:GetHistory()
    local wins, losses, reviewed = 0, 0, 0
    local maps = {}
    local commander, spectator, diagnostic = 0, 0, 0
    for _, entry in ipairs(history) do
        if entry.result == "VICTORY" then wins = wins + 1 end
        if entry.result == "DEFEAT" then losses = losses + 1 end
        if entry.feedback and next(entry.feedback) then reviewed = reviewed + 1 end
        local mode = sessionType(entry.feedback and entry.feedback.sessionType)
        if mode == "Commander" then commander = commander + 1 end
        if mode == "Spectator" then spectator = spectator + 1 end
        if mode == "Diagnostic" then diagnostic = diagnostic + 1 end
        maps[entry.mapKey] = (maps[entry.mapKey] or 0) + 1
    end
    local topMap, topCount = "None", 0
    for map, count in pairs(maps) do
        if count > topCount then topMap, topCount = map, count end
    end
    local decided = wins + losses
    return {
        matches = #history,
        wins = wins,
        losses = losses,
        reviewed = reviewed,
        winRate = decided > 0 and math.floor((wins / decided) * 100 + 0.5) or 0,
        topMap = topMap,
        topMapCount = topCount,
        commander = commander,
        spectator = spectator,
        diagnostic = diagnostic,
    }
end

function AAR:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "AAR")
    end
    self:TrimHistory()
    if KWR.db and KWR.db.journal and KWR.db.journal.interrupted then
        self.lastCompleted = self:CompactEntry(KWR.db.journal.interrupted)
    end
    if KWR.Store and KWR.Store.Subscribe then
        KWR.Store:Subscribe(self, self.Update)
    end
end

function AAR:OnDisable()
    self:CommitInterrupted("Reload, relog, or addon disable interrupted the live match journal.")
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
end

KWR:RegisterModule("AAR", AAR)
