local _, KWR = ...

local AAR = {
    active = nil,
    lastCompleted = nil,
    maxHistory = 30,
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

local function assignmentByKey(assignments)
    local result = {}
    for _, assignment in ipairs(assignments or {}) do
        result[entityKey(assignment, "friendly")] = assignment
        local name = clean(assignment.name or assignment.shortName, "", 64):lower()
        if name ~= "" then result["name:" .. name] = assignment end
    end
    return result
end

local function appendBounded(list, value, maximum)
    list[#list + 1] = value
    while #list > maximum do table.remove(list, 1) end
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
end

function AAR:CaptureTeams(active, snapshot)
    for _, player in ipairs(snapshot.roster or {}) do
        local key = entityKey(player, "friendly")
        active.friendlyTeam[key] = active.friendlyTeam[key]
            or displayEntity(player)
        local stored = active.friendlyTeam[key]
        if stored.spec == "Unknown" and clean(player.spec, "Unknown", 32) ~= "Unknown" then
            stored.spec = clean(player.spec, "Unknown", 32)
            stored.specSource = clean(player.specSource, "observed", 24)
        end
        if stored.role == "Unknown" and player.role then
            stored.role = clean(player.role, "Unknown", 16)
        end
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local key = entityKey(enemy, "enemy")
        active.enemyTeam[key] = active.enemyTeam[key] or displayEntity(enemy)
        local stored = active.enemyTeam[key]
        if stored.spec == "Unknown" and clean(enemy.spec, "Unknown", 32) ~= "Unknown" then
            stored.spec = clean(enemy.spec, "Unknown", 32)
            stored.specSource = clean(enemy.specSource or enemy.evidence, "observed", 24)
        end
        if stored.role == "Unknown" and enemy.role then
            stored.role = clean(enemy.role, "Unknown", 16)
        end
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
            local key = entityKey(row, friendly and "friendly" or "enemy")
            local collection = friendly and active.friendlyTeam or active.enemyTeam
            collection[key] = collection[key] or displayEntity(row)
            local stored = collection[key]
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
        local key = entityKey(player, "friendly")
        local evidence = active.playerEvidence[key] or {
            guid = clean(player.guid, "", 80),
            name = clean(player.name or player.shortName, "Unknown", 64),
            locations = {},
            notes = {},
            deathsObserved = 0,
        }
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
            }, 20)
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
                appendBounded(evidence.notes, { at = now, text = note }, 12)
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
            }, 120)
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
            }, 120)
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
            sightings = 0,
            flags = {},
        }
        if enemy.visible == true then threat.sightings = threat.sightings + 1 end
        threat.lastSeenLocation = clean(enemy.location, threat.lastSeenLocation or "Unknown", 48)
        threat.lastSeenAt = KWR.Util:Number(enemy.lastSeenAt, threat.lastSeenAt)
        threat.lastSeenAge = KWR.Util:Number(enemy.lastSeenAge, enemy.age or threat.lastSeenAge)
        if enemy.role == "HEALER" then threat.flags.healer = true end
        if enemy.classFile == "ROGUE" or enemy.spec == "Feral" then
            threat.flags.stealth = true
        end
        if enemy.carrier then threat.flags.carrier = true end
        if key == killKey or enemy.localEngaged then threat.flags.highPressure = true end
        active.enemyThreats[key] = threat
    end
end

function AAR:Record(state)
    if not self.active then self:Start(state) end
    local active = self.active
    active.scoreEnd = KWR.Util:Copy(state.snapshot.score)
    active.team = KWR.Util:Copy(state.snapshot.context.team or active.team)
    active.matchComplete = active.matchComplete
        or state.snapshot.context.matchComplete == true
    active.truthQualified = state.snapshot.score.source == "ui_widget"
        and state.snapshot.context.team
        and state.snapshot.context.team.side ~= nil
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
        end
        active.commands[#active.commands + 1] = {
            at = epoch(),
            status = state.command.status,
            action = state.command.action,
            who = state.command.who,
            reason = state.command.reason,
            confidence = state.command.confidence,
            confidenceScore = state.command.confidenceScore,
            risk = state.command.risk,
            expectedOutcome = state.command.expectedOutcome,
            projectedWinProbability = state.command.projectedWinProbability,
            recommendationMode = state.command.recommendationMode,
            evidence = KWR.Util:Copy(state.command.evidence),
            simulations = KWR.Util:Copy(state.command.simulations),
            executionAssessment = KWR.Util:Copy(
                state.command.executionAssessment),
            responsePackage = KWR.Util:Copy(
                state.command.responsePackage),
            mapState = {
                phase = clean(state.snapshot.context.phase, "UNKNOWN", 20),
                friendlyScore = KWR.Util:Number(state.snapshot.score.friendly, nil),
                enemyScore = KWR.Util:Number(state.snapshot.score.enemy, nil),
                friendlyObjectives = KWR.Util:Number(state.snapshot.objectives.friendly, nil),
                enemyObjectives = KWR.Util:Number(state.snapshot.objectives.enemy, nil),
            },
            objectiveTarget = state.command.objectiveDecision
                and clean(state.command.objectiveDecision.target, "Unknown", 64) or "Unknown",
            assigned = clean(state.command.who, "Unknown", 120),
            abortCondition = state.command.objectiveDecision
                and clean(state.command.objectiveDecision.abort, "Unknown", 160)
                or clean(state.command.switchIf, "Unknown", 160),
            outcome = "Unknown",
        }
        while #active.commands > 40 do table.remove(active.commands, 1) end
        active.lastSignature = signature
    end
    local message = KWR.Util:Text(state.snapshot.lastMessage, "", 160)
    if message ~= "" and message ~= active.lastMessage then
        active.events[#active.events + 1] = { at = epoch(), text = message }
        while #active.events > 80 do table.remove(active.events, 1) end
        active.lastMessage = message
    end
    local reporterEvents = state.snapshot.reporter and state.snapshot.reporter.events or {}
    local reporterEvent = reporterEvents[#reporterEvents]
    if reporterEvent and reporterEvent.id ~= active.lastReporterEventID then
        active.events[#active.events + 1] = {
            at = epoch(),
            text = "Reporter: " .. KWR.Util:Text(reporterEvent.text, "Movement update", 140),
        }
        while #active.events > 80 do table.remove(active.events, 1) end
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
    local startIndex = math.max(1, #(commands or {}) - 19)
    for index = startIndex, #(commands or {}) do
        local command = commands[index]
        local alternative = command.simulations and command.simulations[2]
        reviews[#reviews + 1] = {
            at = command.at,
            recommendation = command.action,
            recommendationMode = command.recommendationMode,
            expectedOutcome = command.expectedOutcome,
            projectedWinProbability = command.projectedWinProbability,
            confidence = command.confidence,
            risk = command.risk,
            actualResult = result,
            outcomeAligned = (result == "VICTORY" and
                (command.projectedWinProbability or 0) >= 50)
                or (result == "DEFEAT" and
                    (command.projectedWinProbability or 100) < 50),
            competingOption = alternative and alternative.id,
            competingProbability = alternative and alternative.probability,
            evidenceReview = "DEVELOPER_REVIEW_REQUIRED",
        }
    end
    return reviews
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
        entry.finalCommand.outcome = "Match ended: " .. entry.result
    end
    local primaryPlanID, primaryCount
    for planID, count in pairs(entry.planUsage or {}) do
        if not primaryCount or count > primaryCount then
            primaryPlanID, primaryCount = planID, count
        end
    end
    entry.primaryPlanID = primaryPlanID
    entry.decisionReviews = self:BuildDecisionReviews(entry.commands, entry.result)
    KWR.db.journal.history[#KWR.db.journal.history + 1] = entry
    while #KWR.db.journal.history > self.maxHistory do
        table.remove(KWR.db.journal.history, 1)
    end
    self.lastCompleted = entry
    self.active = nil
    KWR:Print("AAR evidence ready: use /kwr aar copy.", true)
    if KWR.db.profile.aar.autoOpen and KWR.AARWindow and C_Timer and C_Timer.After then
        C_Timer.After(1.0, function() KWR.AARWindow:Show(entry.id) end)
    end
end

function AAR:Update(state, previous)
    if not KWR.db.profile.aar.enabled then
        self.active = nil
        return
    end
    local live = state.snapshot.context.inPvP and not state.snapshot.context.preview
    local wasLive = previous and previous.snapshot.context.inPvP and not previous.snapshot.context.preview
    if live then
        self:Record(state)
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

function AAR:Export(entry)
    entry = entry or self:GetLatest()
    if not entry then return nil, "No completed KWR match evidence is available." end
    local lines = {
        "========== KWR MATCH EXPORT ==========",
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
        local response = command.responsePackage or {}
        lines[#lines + 1] = string.format(
            "  Response: %s | move %s | stay %s | qualified %s",
            clean(response.action, "Hold current plan", 120),
            clean(response.moverText, "Team", 100),
            clean(response.stayerText, "Assigned defenders", 100),
            response.qualified and "YES" or "NO")
        lines[#lines + 1] = "  Outcome: " .. clean(command.outcome, "Unknown", 80)
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
    if KWR.db and KWR.db.journal then KWR.db.journal.history = {} end
    self.lastCompleted = nil
    return true
end

function AAR:GetHistory()
    return KWR.db and KWR.db.journal and KWR.db.journal.history or {}
end

function AAR:GetByID(id)
    for _, entry in ipairs(self:GetHistory()) do
        if entry.id == id then return entry end
    end
end

function AAR:SaveFeedback(id, feedback)
    local entry = self:GetByID(id)
    if not entry then return false end
    entry.feedback = {
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
    for _, entry in ipairs(history) do
        if entry.result == "VICTORY" then wins = wins + 1 end
        if entry.result == "DEFEAT" then losses = losses + 1 end
        if entry.feedback and next(entry.feedback) then reviewed = reviewed + 1 end
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
    }
end

function AAR:OnInitialize()
    KWR.Store:Subscribe(self, self.Update)
end

function AAR:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("AAR", AAR)
