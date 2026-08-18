local _, KWR = ...

local CommandReview = {}
KWR.CommandReview = CommandReview

local function clean(value, fallback, limit)
    return KWR.Util:Text(value, fallback or "Unknown", limit or 160)
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

function CommandReview:CompactSimulations(rows)
    local result = {}
    for index = 1, math.min(2, #(rows or {})) do
        local row = rows[index] or {}
        result[#result + 1] = {
            id = clean(row.id, "UNKNOWN", 32),
            probability = KWR.Util:Number(
                row.probability or row.decisionScore or row.score, 0) or 0,
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
    return {
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
        evidence = self:CompactEvidence(command.evidence or confidenceBudget.evidence, 4, 120),
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
