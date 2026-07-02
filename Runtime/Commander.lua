local _, KWR = ...

local Commander = {
    history = {},
    lastSignature = nil,
}
KWR.Commander = Commander

local function addPriorityTarget(action, definition, prediction)
    if not definition or not definition.priorities or not definition.priorities[1] then
        return action
    end
    if prediction.status == "WIN" then return action end
    if prediction.kind == "NODE" or prediction.kind == "HYBRID" then
        return action .. " Priority: " .. definition.priorities[1] .. "."
    end
    return action
end

local function nodeRecoveryCall(assignments, mapKey)
    local assaultLocation, assaultNames, assaultCount
    local defenders = {}
    for _, assignment in ipairs(assignments or {}) do
        local role = assignment.role or ""
        if role:find("Defender", 1, true) or role == "Tower Sitter" then
            defenders[#defenders + 1] = KWR.Maps:AbbreviateLocation(
                mapKey, assignment.location) .. " " .. assignment.shortName
        elseif role == "Strike Team" or role == "Main Fight"
            or role == "Tower Strike" or role == "Cap / Float" then
            assaultLocation = assaultLocation or assignment.location
            if assignment.location == assaultLocation then
                assaultCount = (assaultCount or 0) + 1
                if #(assaultNames or {}) < 3 then
                    assaultNames = assaultNames or {}
                    assaultNames[#assaultNames + 1] = assignment.shortName
                end
            end
        end
    end
    if not assaultLocation or not assaultNames or #assaultNames == 0 then return nil end
    local extra = math.max(0, (assaultCount or #assaultNames) - #assaultNames)
    local assault = table.concat(assaultNames, " + ") .. (extra > 0 and (" +" .. extra) or "")
    local hold = {}
    for index = 1, math.min(2, #defenders) do hold[#hold + 1] = defenders[index] end
    return "TAKE " .. KWR.Maps:AbbreviateLocation(mapKey, assaultLocation) .. ": " .. assault
        .. (#hold > 0 and (". HOLD " .. table.concat(hold, "; ")) or "")
end

function Commander:Compose(snapshot, prediction, assignments)
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local shortMap = definition and definition.short or (snapshot.context.inPvP and "BG" or "WORLD")
    local score = snapshot.score or {}
    local formation = snapshot.formation or {}
    local status = not snapshot.context.inPvP and "FORMING" or (prediction.status or "WAITING")
    local doctrine = KWR.Doctrine:Get(snapshot.context.mapKey)
    local doctrineRecommendation = KWR.Doctrine:Recommend(snapshot.context.mapKey, status, prediction.urgency)
    local strategy = snapshot.strategy or {}
    local action = not snapshot.context.inPvP and formation.action
        or strategy.action or prediction.action or doctrineRecommendation
    if snapshot.context.inPvP then action = addPriorityTarget(action, definition, prediction) end
    if snapshot.context.inPvP and (prediction.status == "LOSE" or strategy.state == "RECOVERY")
        and (snapshot.context.kind == "NODE" or snapshot.context.kind == "HYBRID") then
        action = nodeRecoveryCall(assignments, snapshot.context.mapKey) or action
    end
    if (prediction.urgency or 0) >= 90 and not strategy.action then
        action = prediction.emergency or doctrineRecommendation
    end
    local integrity = snapshot.assignmentIntegrity or {}
    local urgentReassignment = integrity.reassignments and integrity.reassignments[1]
    if snapshot.context.inPvP and urgentReassignment then
        local replacement = urgentReassignment.replacement or "nearest floater"
        action = "COVER " .. urgentReassignment.expected .. ": " .. replacement
            .. ". " .. action
    end
    action = KWR.Util:Text(action, "Play objective.", 82)

    local who = KWR.Assignments:SelectForCommand(assignments, prediction)
    if urgentReassignment and urgentReassignment.replacement then
        who = urgentReassignment.replacement
    end
    if not snapshot.context.inPvP and formation.recommendations and formation.recommendations[1] then
        local names = {}
        for index = 1, math.min(3, #formation.recommendations) do
            names[#names + 1] = formation.recommendations[index].label
        end
        who = "Recruit " .. table.concat(names, " / ")
    end
    local stabilized = false
    if snapshot.context.inPvP and not snapshot.reassessment and self.lastCommand
        and self.lastCommand.mapKey == snapshot.context.mapKey
        and self.lastCommand.status == status
        and (KWR.Util:Now() - (self.lastCommand.decisionAt or 0)) < 2.5
        and math.abs((prediction.urgency or 0) - (self.lastCommand.urgency or 0)) < 20 then
        action = self.lastCommand.action
        who = self.lastCommand.who
        stabilized = true
    end
    local when
    if not snapshot.context.inPvP then
        when = "BEFORE QUEUE"
    elseif prediction.captureDeadline then
        when = "BY " .. KWR.Util:Clock(prediction.captureDeadline)
    elseif status == "WIN" and prediction.timeToWin then
        when = "HOLD " .. KWR.Util:Clock(prediction.timeToWin)
    elseif (prediction.urgency or 0) >= 70 then
        when = "NOW"
    else
        when = "NEXT FIGHT"
    end

    local scoreText = not snapshot.context.inPvP and
        (tostring(formation.players or 0) .. "/" .. tostring(formation.targetSize or 10))
        or score.max and score.max > 0
        and (tostring(score.friendly or 0) .. "-" .. tostring(score.enemy or 0))
        or "NO SCORE"
    local modePrefix = snapshot.context.preview and "PREVIEW " or ""
    local line1 = KWR.Util:Text(modePrefix .. shortMap .. " " .. scoreText .. " " .. status, "KWR READY", 64)
    local line2 = KWR.Util:Text("NEXT: " .. action, "NEXT: PLAY OBJECTIVE", 132)
    local line3 = KWR.Util:Text("WHO: " .. who .. " | WHEN: " .. when, "WHO: TEAM | WHEN: NOW", 112)
    local movementReason = prediction.movementEvidence and prediction.movementEvidence ~= ""
        and (" FIELD: " .. prediction.movementEvidence) or ""
    local reason = KWR.Util:Text(
        (not snapshot.context.inPvP and (formation.reason or "Build the command unit.")
            or (prediction.condition or "Waiting for battlefield truth."))
            .. (strategy.reason and (" PLAN: " .. strategy.reason) or "")
            .. movementReason
            .. (strategy.objectiveDecision and strategy.objectiveDecision.success
                and (" SUCCESS: " .. strategy.objectiveDecision.success) or "")
            .. (strategy.objectiveDecision and strategy.objectiveDecision.abort
                and (" ABORT: " .. strategy.objectiveDecision.abort) or "")
            .. " STOP: " .. (strategy.stop or doctrine.stop or "Avoid low-value fights."),
        "Waiting for battlefield truth.",
        220
    )
    local signature = KWR.Util:Signature({ status, action, who })
    local combat = snapshot.combat or {}
    local killTarget = combat.killTarget
    local command = {
        mapKey = snapshot.context.mapKey,
        status = status,
        urgency = prediction.urgency or 0,
        line1 = line1,
        line2 = line2,
        line3 = line3,
        action = action,
        who = who,
        when = when,
        reason = reason,
        doctrine = doctrineRecommendation,
        confidence = strategy.confidence or prediction.confidence or "NONE",
        source = prediction.source or "none",
        reporterRisk = prediction.reporterRisk or 0,
        hotspot = prediction.hotspot,
        killTarget = killTarget and killTarget.shortName or nil,
        killTargetKey = killTarget and killTarget.key or nil,
        killReason = combat.killReason,
        planID = strategy.planID,
        ourComposition = strategy.ourTier and strategy.ourTier.qualified
            and (strategy.ourTier.tier .. " " .. strategy.ourTier.name)
            or (strategy.ourComposition and strategy.ourComposition.name or nil),
        enemyComposition = strategy.enemyTier and strategy.enemyTier.qualified
            and (strategy.enemyTier.tier .. " " .. strategy.enemyTier.name)
            or (strategy.enemyComposition and strategy.enemyComposition.name or nil),
        switchIf = strategy.switchIf,
        avoid = strategy.counter and strategy.counter.avoid or strategy.stop,
        counterplay = strategy.counter and strategy.counter.emphasis or nil,
        assignmentHints = strategy.assignmentHints,
        objectiveDecision = KWR.Util:Copy(strategy.objectiveDecision),
        weightedFocus = KWR.Util:Copy(strategy.weightedFocus),
        capabilityReadiness = strategy.capabilityReadiness,
        capabilityMatchup = strategy.capabilityMatchup,
        confidenceScore = strategy.confidenceBudget and strategy.confidenceBudget.score,
        evidence = strategy.confidenceBudget
            and KWR.Util:Copy(strategy.confidenceBudget.evidence) or {},
        risk = strategy.risk,
        expectedOutcome = strategy.expectedOutcome,
        projectedWinProbability = strategy.projectedWinProbability,
        recommendationMode = strategy.recommendationMode,
        simulations = KWR.Util:Copy(strategy.simulations),
        opportunity = KWR.Util:Copy(strategy.opportunity),
        assignmentIntegrity = KWR.Util:Copy(integrity),
        formation = not snapshot.context.inPvP and KWR.Util:Copy(formation) or nil,
        signature = signature,
        createdAt = KWR.Util:Now(),
        expiresAt = KWR.Util:Now() + (snapshot.context.inPvP and 3 or 30),
        stabilized = stabilized,
        reassessment = snapshot.reassessment and KWR.Util:Copy(snapshot.reassessment) or nil,
        decisionAt = stabilized and self.lastCommand.decisionAt or KWR.Util:Now(),
    }

    if signature ~= self.lastSignature then
        self.history[#self.history + 1] = {
            at = command.createdAt,
            mapKey = command.mapKey,
            status = status,
            action = action,
            reason = reason,
        }
        while #self.history > 30 do table.remove(self.history, 1) end
        self.lastSignature = signature
    end
    self.lastCommand = {
        mapKey = snapshot.context.mapKey,
        status = status,
        urgency = command.urgency,
        action = command.action,
        who = command.who,
        decisionAt = command.decisionAt,
    }
    return command
end

function Commander:GetHistory()
    return self.history
end

KWR:RegisterModule("Commander", Commander)
