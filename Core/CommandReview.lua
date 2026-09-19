local _, KWR = ...

local CommandReview = {}
KWR.CommandReview = CommandReview

local function clean(value, fallback, limit)
    return KWR.Util:Text(value, fallback or "Unknown", limit or 160)
end

local function publicNumber(value)
    if KWR.Util:IsSecret(value) or type(value) ~= "number" then return nil end
    if value ~= value or value < 0 or value == math.huge then return nil end
    return value
end

local function publicID(value)
    if KWR.Util:IsSecret(value) or type(value) ~= "string" then return nil end
    if value == "" or #value > 512 then return nil end
    return value
end

local function matchesCommand(command, record)
    if type(command) ~= "table" or type(record) ~= "table" then return false end
    local id = publicID(command.commandId)
    local revision = publicNumber(command.commandRevision)
    return id ~= nil and revision ~= nil and revision >= 1
        and revision <= 9007199254740991 and revision == math.floor(revision)
        and publicID(record.commandId) == id
        and publicNumber(record.commandRevision) == revision
        and KWR.Util:Number(record.schemaVersion, nil) == 1
        and KWR.Util:Text(record.clock, "", 24) == "UNIX_SECONDS"
end

function CommandReview:DeliveryEligible(command)
    local delivery = type(command) == "table" and command.delivery
    if not matchesCommand(command, delivery) then return false end
    if KWR.Util:Text(delivery.context, "", 24) ~= "Commander"
        or KWR.Util:Text(delivery.state, "", 24) ~= "LEADER_ATTESTED"
        or KWR.Util:Text(delivery.source, "", 40) ~= "EXPLICIT_LEADER_CONFIRMATION" then
        return false
    end
    -- Persisted review records use wall time; a later client process must not
    -- compare their timestamps against its new session's uptime.
    local now = publicNumber(KWR.Util:Call(time))
    local generatedAt = publicNumber(delivery.generatedAt)
    local deliveredAt = publicNumber(delivery.deliveredAt)
    return now ~= nil and generatedAt ~= nil and deliveredAt ~= nil
        and generatedAt <= deliveredAt and deliveredAt <= now
end

function CommandReview:ExecutionEligible(command)
    if not self:DeliveryEligible(command) then return false end
    local observed = command.executionObservation
    if not matchesCommand(command, observed)
        or KWR.Util:Text(observed.source, "", 24) ~= "PUBLIC_FACTS" then
        return false
    end
    local session = publicID(command.sessionKey)
    if not session or publicID(observed.sessionKey) ~= session then return false end
    local at = publicNumber(observed.observedAt)
    local now = publicNumber(KWR.Util:Call(time))
    if not at or not now or at < command.delivery.deliveredAt or at > now then
        return false
    end
    local ids = observed.evidenceIds
    if type(ids) ~= "table" or #ids == 0 or #ids > 4 then return false end
    for _, id in ipairs(ids) do
        if not publicID(id) then return false end
    end
    local outcome = KWR.Util:Text(observed.outcome, "", 16)
    return outcome == "OBSERVED" or outcome == "SUCCESS" or outcome == "FAILURE"
end

function CommandReview:OutcomeObserved(command)
    return self:ExecutionEligible(command)
        and KWR.Util:Text(command.executionObservation.outcome, "", 16) ~= "OBSERVED"
end

CommandReview.maxCallouts = 6
CommandReview.maxFollowthroughEvents = 8

local function validCallout(callout)
    if type(callout) ~= "table" or callout.schemaVersion ~= 1
        or callout.clock ~= "UNIX_SECONDS" or not publicID(callout.calloutId)
        or not publicID(callout.candidateId) or not publicID(callout.matchId)
        or not publicID(callout.commandId) or not publicID(callout.sessionKey) then return false end
    for _, field in ipairs({ "commandRevision", "calloutRevision" }) do
        local value = publicNumber(callout[field])
        if not value or value < 1 or value > 9007199254740991 or value ~= math.floor(value) then return false end
    end
    local now, generated = publicNumber(KWR.Util:Call(time)), publicNumber(callout.generatedAt)
    if not now or not generated or generated > now then return false end
    if KWR.Util:IsSecret(callout.speech) or type(callout.speech) ~= "string"
        or #callout.speech == 0 or #callout.speech > 16384 then return false end
    return true
end

function CommandReview:FollowthroughEligible(callout, event)
    if not validCallout(callout) or callout.context ~= "Commander"
        or type(event) ~= "table" or event.schemaVersion ~= 1
        or event.clock ~= "UNIX_SECONDS" or event.source ~= "LEADER_ATTESTATION"
        or event.context ~= "Commander" or not publicID(event.eventId) then return false end
    for _, field in ipairs({ "candidateId", "matchId", "commandId", "commandRevision", "calloutId", "calloutRevision" }) do
        if KWR.Util:IsSecret(event[field]) or event[field] ~= callout[field] then return false end
    end
    if event.state ~= "FOLLOWED" and event.state ~= "NOT_FOLLOWED" and event.state ~= "UNMARKED" then return false end
    local at, now = publicNumber(event.recordedAt), publicNumber(KWR.Util:Call(time))
    return at ~= nil and now ~= nil and at >= callout.generatedAt and at <= now
end

function CommandReview:EffectiveFollowthrough(callout)
    if not validCallout(callout) then return "UNMARKED" end
    local events = callout.events
    if type(events) ~= "table" or #events > self.maxFollowthroughEvents then return "UNMARKED" end
    local event = events[#events]
    return self:FollowthroughEligible(callout, event) and event.state or "UNMARKED"
end

function CommandReview:AppendFollowthrough(callout, mark)
    if not validCallout(callout) or callout.context ~= "Commander" then
        return false, "Feedback needs an original Commander-context call."
    end
    if mark ~= "FOLLOWED" and mark ~= "NOT_FOLLOWED" and mark ~= "UNMARKED" then
        return false, "Unknown follow-through mark."
    end
    if type(callout.events) ~= "table" or #callout.events > self.maxFollowthroughEvents then
        return false, "Feedback history is not compatible."
    end
    if self:EffectiveFollowthrough(callout) == mark then return false, "Already marked " .. mark end
    local last = callout.events[#callout.events]
    local at = publicNumber(KWR.Util:Call(time))
    if not at or (last and (not self:FollowthroughEligible(callout, last) or at < last.recordedAt)) then
        return false, "Feedback clock or previous event is invalid."
    end
    local serial = publicNumber(callout.eventSerial)
    if not serial or serial >= 9007199254740990 or serial ~= math.floor(serial) then
        return false, "Feedback event sequence is invalid."
    end
    local event = { schemaVersion = 1, clock = "UNIX_SECONDS", context = "Commander",
        source = "LEADER_ATTESTATION", state = mark, recordedAt = at,
        previousState = self:EffectiveFollowthrough(callout),
        eventId = callout.calloutId .. ":event:" .. tostring(serial + 1),
        supersedesEventId = last and last.eventId or nil }
    for _, field in ipairs({ "candidateId", "matchId", "commandId", "commandRevision", "calloutId", "calloutRevision" }) do
        event[field] = callout[field]
    end
    if not self:FollowthroughEligible(callout, event) then return false, "Feedback reference is invalid." end
    callout.eventSerial = serial + 1
    callout.events[#callout.events + 1] = event
    while #callout.events > self.maxFollowthroughEvents do
        callout.evictedEvents = (callout.evictedEvents or 0) + 1
        table.remove(callout.events, 1)
    end
    return true, mark == "UNMARKED" and "Mark undone; audit history retained."
        or (mark == "FOLLOWED" and "Marked followed - outcome remains separate." or "Marked not followed."), event
end

function CommandReview:HasNotFollowed(command)
    if type(command) ~= "table" then return false end
    if command.evictedNotFollowed == true then return true end
    local callouts = command.callouts
    if type(callouts) ~= "table" then return false end
    if #callouts > self.maxCallouts then return true end
    for _, callout in ipairs(callouts) do
        if self:EffectiveFollowthrough(callout) == "NOT_FOLLOWED" then return true end
    end
    return false
end

function CommandReview:NormalizeCallouts(command)
    if type(command) ~= "table" or type(command.callouts) ~= "table" then return false end
    if command.calloutSchemaVersion and command.calloutSchemaVersion ~= 1 then
        -- A future owner must retain and interpret its own data.
        return false
    end
    local retained = {}
    for _, callout in ipairs(command.callouts) do
        if validCallout(callout) then
            local events, evictedNotFollowed = {}, false
            for _, event in ipairs(type(callout.events) == "table" and callout.events or {}) do
                if self:FollowthroughEligible(callout, event) then
                    events[#events + 1] = event
                end
            end
            while #events > self.maxFollowthroughEvents do
                local evicted = table.remove(events, 1)
                if evicted.state == "NOT_FOLLOWED" then evictedNotFollowed = true end
            end
            callout.events = events
            callout.eventSerial = math.max(KWR.Util:Number(callout.eventSerial, 0) or 0, #events)
            if evictedNotFollowed then command.evictedNotFollowed = true end
            retained[#retained + 1] = callout
        end
    end
    while #retained > self.maxCallouts do
        local evicted = table.remove(retained, 1)
        if self:EffectiveFollowthrough(evicted) == "NOT_FOLLOWED" then
            command.evictedNotFollowed = true
        end
        command.evictedCallouts = (command.evictedCallouts or 0) + 1
    end
    command.callouts = retained
    command.calloutSchemaVersion = #retained > 0 and 1 or command.calloutSchemaVersion
    return true
end

function CommandReview:FollowthroughSummary(command)
    local lines = {}
    for index, callout in ipairs(command and command.callouts or {}) do
        if index > self.maxCallouts then break end
        if validCallout(callout) then
            lines[#lines + 1] = "Call " .. tostring(callout.calloutRevision) .. ": "
                .. self:EffectiveFollowthrough(callout) .. " (manual adherence; not outcome)"
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or "UNMARKED (no manual follow-through report)"
end

function CommandReview:CompactTextList(values, maximum, limit)
    local result = {}
    for index = 1, math.min(maximum or 0, #(values or {})) do
        result[#result + 1] = clean(values[index], "Unknown", limit or 120)
    end
    return result
end

function CommandReview:CompactEvidence(values, maximum, limit)
    local result = {}
    for index = 1, math.min(maximum or 0, #(values or {})) do
        local value = values[index]
        if type(value) == "table" then
            value = value.text or value.reason or value.label or value.summary
                or value.id or value.source
        end
        value = KWR.Util:Text(value, "", limit or 120)
        if value ~= "" and value ~= "Unknown" and value ~= "unknown" then
            result[#result + 1] = value
        end
    end
    return result
end

function CommandReview:DerivedEvidence(command, snapshot, maximum, limit)
    local evidence = self:CompactEvidence(command.evidence, maximum, limit)
    if #evidence > 0 then return evidence end
    local score = type(snapshot.score) == "table" and snapshot.score or {}
    local objectives = type(snapshot.objectives) == "table" and snapshot.objectives or {}
    local context = type(snapshot.context) == "table" and snapshot.context or {}
    local function add(value)
        if #evidence >= (maximum or 0) then return end
        value = KWR.Util:Text(value, "", limit or 120)
        if value ~= "" then evidence[#evidence + 1] = value end
    end
    local scoreSource = KWR.Util:Text(score.source, "", 32)
    if scoreSource ~= "" and scoreSource ~= "unknown" then
        add("score:" .. scoreSource)
    end
    local objectiveSource = KWR.Util:Text(objectives.source, "", 32)
    if objectiveSource ~= "" and objectiveSource ~= "unknown" then
        add("objectives:" .. objectiveSource)
    end
    local teamSource = KWR.Util:Text(context.team and context.team.source, "", 32)
    if teamSource ~= "" and teamSource ~= "unknown" then
        add("team:" .. teamSource)
    end
    local decision = type(command.activePlayDecision) == "table"
        and command.activePlayDecision or {}
    if decision.invalidation then
        add("play:" .. KWR.Util:Text(decision.invalidation, "unknown", 48))
    elseif decision.terminalOutcomeHeld == true then
        add("play:terminal-outcome-hold")
    end
    return evidence
end

function CommandReview:CompactSimulations(rows)
    local result = {}
    for index = 1, math.min(2, #(rows or {})) do
        local row = rows[index] or {}
        result[#result + 1] = {
            id = clean(row.id, "UNKNOWN", 32),
            utility = KWR.Util:Number(
                row.decisionScore or row.utility or row.probability or row.score, 0) or 0,
            projection = clean(row.projection, "UNKNOWN", 24),
            target = clean(row.target, "Unknown", 48),
            outcome = clean(row.outcome, "Unknown", 64),
            risk = clean(row.risk, "Unknown", 24),
        }
    end
    return result
end

function CommandReview:CompactExecutionAssessment(execution)
    execution = type(execution) == "table" and execution or {}
    local actionOpportunity = execution.actionOpportunity or {}
    local commitment = execution.commitment or {}
    local collapse = execution.collapse or {}
    local organization = execution.organization or {}
    return {
        actionOpportunity = {
            action = clean(actionOpportunity.action, "UNKNOWN", 32),
            score = KWR.Util:Number(actionOpportunity.score, 0) or 0,
        },
        commitment = {
            state = clean(commitment.state, "UNKNOWN", 24),
            objective = clean(commitment.objective, "Unknown", 48),
        },
        collapse = {
            state = clean(collapse.state, "UNKNOWN", 24),
        },
        organization = {
            state = clean(organization.state, "UNKNOWN", 24),
            entropy = KWR.Util:Number(organization.entropy, 0) or 0,
        },
    }
end

function CommandReview:CompactEnemyResponsePlan(plan)
    plan = type(plan) == "table" and plan or {}
    return {
        responseID = clean(plan.responseID, "UNKNOWN", 32),
        enemyPattern = clean(plan.enemyPattern, "Unknown", 120),
        safestReply = clean(plan.safestReply, "Hold the safer line.", 120),
        confidence = clean(plan.confidence, "LOW", 16),
        danger = KWR.Util:Number(plan.danger, 0) or 0,
        scoreFloorRisk = clean(plan.scoreFloorRisk, "UNKNOWN", 24),
        punishWindow = clean(plan.punishWindow, "UNKNOWN", 24),
        responsePressure = clean(plan.responsePressure, "UNKNOWN", 24),
        attributionHint = clean(plan.attributionHint, "UNKNOWN", 32),
        consequenceAdjustment = KWR.Util:Number(plan.consequenceAdjustment, 0) or 0,
    }
end

function CommandReview:CompactResponsePackage(response)
    response = type(response) == "table" and response or {}
    return {
        actionID = clean(response.actionID, "", 32),
        target = clean(response.target, "", 64),
        shortTarget = clean(response.shortTarget, "", 32),
        action = clean(response.action, "HOLD CURRENT PLAN", 120),
        moverText = clean(response.moverText, "Team", 100),
        stayerText = clean(response.stayerText, "Assigned defenders", 100),
        qualified = response.qualified == true,
        recovery = {
            criticalGap = clean(response.recovery and response.recovery.criticalGap, "", 48),
            releaseTarget = clean(response.recovery and response.recovery.releaseTarget, "", 48),
            urgent = response.recovery and response.recovery.urgent == true or false,
        },
    }
end

function CommandReview:CompactManualOverrides(snapshot, assignments)
    local rows = KWR.AssignmentOverrides and KWR.AssignmentOverrides:DescribeActive(
        snapshot, assignments) or {}
    return self:CompactTextList(rows, 4, 96)
end

function CommandReview:BuildRecord(command, snapshot, assignments, prediction)
    command = type(command) == "table" and command or {}
    snapshot = type(snapshot) == "table" and snapshot or {}
    local strategy = type(snapshot.strategy) == "table" and snapshot.strategy or {}
    local response = command.responsePackage or snapshot.responsePackage
    local objectiveDecision = type(command.objectiveDecision) == "table"
        and command.objectiveDecision or (type(strategy.objectiveDecision) == "table"
        and strategy.objectiveDecision or {})
    local confidenceBudget = type(strategy.confidenceBudget) == "table"
        and strategy.confidenceBudget or {}
    local evidence = self:CompactEvidence(
        command.evidence or confidenceBudget.evidence, 4, 120)
    if #evidence == 0 then
        evidence = self:DerivedEvidence(command, snapshot, 4, 120)
    end
    return {
        commandId = publicID(command.commandId),
        sessionKey = publicID(command.sessionKey),
        planID = publicID(command.planID),
        learningContext = type(command.learningContext) == "table"
            and KWR.Util:Copy(command.learningContext) or nil,
        commandRevision = publicNumber(command.commandRevision),
        generatedAt = publicNumber(command.generatedAt),
        delivery = self:DeliveryEligible(command) and KWR.Util:Copy(command.delivery) or nil,
        executionObservation = self:ExecutionEligible(command)
            and KWR.Util:Copy(command.executionObservation) or nil,
        status = command.status,
        action = command.action,
        who = command.who,
        reason = command.reason,
        confidence = command.confidence,
        confidenceScore = command.confidenceScore or confidenceBudget.score,
        risk = command.risk or strategy.risk,
        expectedOutcome = command.expectedOutcome or strategy.expectedOutcome,
        projectedWinProbability = command.projectedWinProbability
            or strategy.projectedWinProbability,
        decisionScore = command.decisionScore or strategy.decisionScore,
        projection = command.projection or strategy.projection,
        recommendationMode = command.recommendationMode or strategy.recommendationMode
            or (prediction and prediction.status) or nil,
        evidence = evidence,
        simulations = self:CompactSimulations(command.simulations or strategy.simulations),
        executionAssessment = self:CompactExecutionAssessment(
            command.executionAssessment or strategy.executionAssessment),
        enemyResponsePlan = self:CompactEnemyResponsePlan(
            command.enemyResponsePlan or strategy.enemyResponsePlan),
        responsePackage = self:CompactResponsePackage(response),
        objectiveTarget = clean(
            command.objectiveTarget or objectiveDecision.target, "Unknown", 64),
        assigned = clean(command.assigned or command.who, "Unknown", 120),
        manualOverrides = self:CompactManualOverrides(snapshot, assignments),
        abortCondition = clean(
            command.abortCondition or objectiveDecision.abort or command.switchIf,
            "Unknown", 160),
    }
end
