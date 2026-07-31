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
    for _, field in ipairs({
        "guid", "name", "shortName", "class", "classFile", "spec", "role", "specSource",
    }) do
        local value = current[field]
        local unknown = record[field] == nil or record[field] == ""
            or record[field] == "Unknown" or record[field] == "UNKNOWN"
            or record[field] == "unknown"
        if value ~= nil and value ~= "" and value ~= "Unknown"
            and value ~= "UNKNOWN" and value ~= "unknown" and unknown then
            record[field] = value
        end
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
        mapKey = snapshot.context.mapKey,
        mapName = snapshot.context.mapName,
        team = KWR.Util:Copy(snapshot.context.team),
        startedAt = epoch(),
        scoreStart = KWR.Util:Copy(snapshot.score),
        scoreEnd = nil,
        commands = {},
        events = {},
        feedback = {},
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
    }
    self:PersistActive()
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
            or integrityRow.status == "IMPOSSIBLE"
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
    local killKey = snapshot.combat and snapshot.combat.killTarget
        and entityKey(snapshot.combat.killTarget, "enemy") or nil
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local key = entityKey(enemy, "enemy")
        local threat = active.enemyThreats[key] or {
            guid = clean(enemy.guid, "", 80),
            name = clean(enemy.name or enemy.shortName, "Unknown", 64),
            class = clean(enemy.class or enemy.classFile, "Unknown", 32),
            spec = clean(enemy.spec, "Unknown", 32),
            role = clean(enemy.role, "Unknown", 16),
            sightings…5627 tokens truncated…======",
        "Version: " .. clean(KWR.version, "Unknown", 32),
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
        "- Issued %s | replacements %s | stabilized %s | reversals %s | retained %s | suppressed %s",
        unknown(stability.issued), unknown(stability.replacements),
        unknown(stability.stabilized), unknown(stability.reversals),
        unknown(stability.activePlayRetains), unknown(stability.suppressedAlternatives))
    lines[#lines + 1] = string.format("- Stability budget: %s | %s",
        clean(stability.commandHealth, "UNKNOWN", 16),
        clean(stability.commandHealthReason, "No stability budget reason.", 120))
    lines[#lines + 1] = string.format("- Field certification: %s | %s",
        clean(stability.certificationStatus, "INSUFFICIENT_SAMPLE", 32),
        clean(stability.certificationReason, "Collect more command samples.", 120))
    lines[#lines + 1] = string.format(
        "- Overrides %s | invalidations %s | pre-move invalidations %s | avg lifetime %s | median %s",
        unknown(stability.overrides), unknown(stability.invalidations),
        unknown(stability.preMoveInvalidations),
        stability.averageLifetime and KWR.Util:Clock(stability.averageLifetime) or "Unknown",
        stability.medianLifetime and KWR.Util:Clock(stability.medianLifetime) or "Unknown")
    lines[#lines + 1] = string.format(
        "- Churn detail: suppress persistence %s | suppress superiority %s | overrides pre-arrival %s / committed %s | invalidations pre-arrival %s / committed %s",
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