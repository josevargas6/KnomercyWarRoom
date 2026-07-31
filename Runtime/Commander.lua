local _, KWR = ...

local Commander = {
    history = {},
    lastSignature = nil,
    maxHistory = 16,
    metrics = nil,
    candidateTrends = nil,
    overrideLog = {},
    maxOverrideLog = 20,
    suppressionLog = {},
    maxSuppressionLog = 20,
}
KWR.Commander = Commander

local function median(values)
    if type(values) ~= "table" or #values == 0 then return 0 end
    local copy = KWR.Util:Copy(values)
    table.sort(copy)
    local middle = math.floor(#copy / 2) + 1
    if (#copy % 2) == 1 then return copy[middle] end
    return (copy[middle - 1] + copy[middle]) / 2
end

local function classifyBypass(snapshot, response, prediction, stabilized)
    if stabilized then return "STABILIZED" end
    if snapshot.reassessment then return "REASSESSMENT" end
    if response and response.qualified then return "RESPONSE_PACKAGE" end
    if (prediction.urgency or 0) >= 90 then return "EMERGENCY_URGENCY" end
    return "CANDIDATE_CHANGE"
end

local function stabilitySummary(metrics)
    metrics = metrics or {}
    local lifetimes = metrics.lifetimes or {}
    local reversals = metrics.reversals or 0
    local evaluations = metrics.evaluations or 0
    local issued = metrics.issued or 0
    local replacements = metrics.replacements or 0
    local preMovementInvalidations = metrics.preMovementInvalidations or 0
    local successfulPlays = metrics.successfulPlays or 0
    local switchAdvantages = metrics.switchAdvantages or {}
    local reversalRate = issued > 0 and (reversals / issued) or 0
    local medianLifetime = median(lifetimes.samples or {})
    local averageSwitchAdvantage = switchAdvantages.count and switchAdvantages.count > 0
        and ((switchAdvantages.total or 0) / switchAdvantages.count) or 0
    local commandHealth = "UNKNOWN"
    local commandHealthReason = "No replacement sample yet."
    local certificationStatus = "INSUFFICIENT_SAMPLE"
    local certificationReason = "Collect at least three command replacements or one full match AAR."
    if replacements > 0 then
        local preMoveRate = preMovementInvalidations / replacements
        if reversalRate > 0.05 then
            commandHealth = "REVIEW"
            commandHealthReason = "Objective reversals exceed the 5% churn budget."
        elseif preMoveRate > 0.10 then
            commandHealth = "REVIEW"
            commandHealthReason = "Commands are being replaced before movement too often."
        elseif medianLifetime > 0 and medianLifetime < 20 then
            commandHealth = "WATCH"
            commandHealthReason = "Median command lifetime is below the 20s objective-command target."
        else
            commandHealth = "PASS"
            commandHealthReason = "Command churn is inside offline stability budget."
        end
    elseif issued > 0 then
        commandHealth = "PASS"
        commandHealthReason = "No command replacements recorded."
    end
    if issued >= 8 or replacements >= 3 or successfulPlays >= 1 then
        if commandHealth == "PASS" then
            certificationStatus = "READY"
            certificationReason = "Current match has enough command-stability evidence for review."
        elseif commandHealth == "WATCH" then
            certificationStatus = "REVIEW_REQUIRED"
            certificationReason = "Evidence sample is large enough, but stability is below target."
        elseif commandHealth == "REVIEW" then
            certificationStatus = "FAIL_REVIEW"
            certificationReason = "Evidence sample is large enough and churn exceeds budget."
        end
    end
    return {
        evaluations = evaluations,
        issued = issued,
        replacements = replacements,
        stabilized = metrics.stabilized or 0,
        suppressed = metrics.suppressed or 0,
        reversals = reversals,
        shortestLifetime = lifetimes.shortest or 0,
        longestLifetime = lifetimes.longest or 0,
        averageLifetime = lifetimes.count and lifetimes.count > 0
            and ((lifetimes.total or 0) / lifetimes.count) or 0,
        medianLifetime = medianLifetime,
        preMovementInvalidations = preMovementInvalidations,
        emergencyBypasses = metrics.emergencyBypasses or 0,
        reassessmentBypasses = metrics.reassessmentBypasses or 0,
        responseBypasses = metrics.responseBypasses or 0,
        candidateBypasses = metrics.candidateBypasses or 0,
        activePlayRetains = metrics.activePlayRetains or 0,
        suppressedAlternatives = metrics.suppressedAlternatives or 0,
        suppressedByPersistence = metrics.suppressedByPersistence or 0,
        suppressedBySuperiority = metrics.suppressedBySuperiority or 0,
        overrides = metrics.overrides or 0,
        overridesBeforeArrival = metrics.overridesBeforeArrival or 0,
        overridesAfterCommitment = metrics.overridesAfterCommitment or 0,
        invalidations = metrics.invalidations or 0,
        invalidationsBeforeArrival = metrics.invalidationsBeforeArrival or 0,
        invalidationsAfterCommitment = metrics.invalidationsAfterCommitment or 0,
        successfulPlays = successfulPlays,
        successRate = replacements > 0 and (successfulPlays / replacements) or 0,
        averageSwitchAdvantage = averageSwitchAdvantage,
        reversalRate = reversalRate,
        preMovementInvalidationRate = replacements > 0
            and (preMovementInvalidations / replacements) or 0,
        commandHealth = commandHealth,
        commandHealthReason = commandHealthReason,
        certificationStatus = certificationStatus,
        certificationReason = certificationReason,
    }
end

local function phaseBucket(phase)
    phase = KWR.Util:Text(phase, "UNKNOWN", 24)
    if phase == "MOVING" then
        return "MOVING"
    end
    if phase == "COMMITTED" or phase == "RESOLVING" then
        return "COMMITTED"
    end
    return "PRE_ARRIVAL"
end

local function trendSummary(trend)
    return {
        signature = trend and trend.signature or nil,
        firstPreferredAt = trend and trend.firstPreferredAt or 0,
        lastPreferredAt = trend and trend.lastPreferredAt or 0,
        consecutiveWins = trend and trend.consecutiveWins or 0,
        averageAdvantage = trend and trend.averageAdvantage or 0,
        minimumAdvantage = trend and trend.minimumAdvantage or 0,
        duration = trend and math.max(0, (trend.lastPreferredAt or 0)
            - (trend.firstPreferredAt or 0)) or 0,
    }
end

local function splitNames(text)
    local names = {}
    for token in string.gmatch(tostring(text or ""), "([^,;]+)") do
        local clean = KWR.Util:Text(token, "", 48):gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" and clean ~= "Team" and clean ~= "Assigned defenders" then
            names[#names + 1] = clean
        end
    end
    return names
end

local function currentObjectiveOwner(snapshot, objective)
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        if row.label == objective then
            return row.owner, row.state
        end
    end
    return nil, nil
end

local function currentObjectiveRow(snapshot, objective)
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        if row.label == objective then
            return row
        end
    end
    return nil
end

local function objectiveSummary(snapshot)
    local summary = {
        friendly = 0,
        enemy = 0,
        assaultedFriendly = 0,
        assaultedEnemy = 0,
        contested = 0,
    }
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local owner = KWR.Util:Text(row.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(row.state, "UNKNOWN", 20)
        if owner == "FRIENDLY" then
            summary.friendly = summary.friendly + 1
            if state == "INCOMING" then
                summary.assaultedFriendly = summary.assaultedFriendly + 1
            end
        elseif owner == "ENEMY" then
            summary.enemy = summary.enemy + 1
            if state == "INCOMING" then
                summary.assaultedEnemy = summary.assaultedEnemy + 1
            end
        end
        if state == "INCOMING" or state == "CONTESTED" then
            summary.contested = summary.contested + 1
        end
    end
    return summary
end

local function flagStateSummary(snapshot)
    local objectives = snapshot.objectives or {}
    local rows = objectives.rows or {}
    local summary = {
        friendlyFlagActive = KWR.Util:Number(objectives.friendlyFlagActive, 0) or 0,
        enemyFlagActive = KWR.Util:Number(objectives.enemyFlagActive, 0) or 0,
        publicFlags = #(objectives.flags or {}),
        homeAvailable = false,
        enemyRoomAvailable = false,
        centerFlagActive = false,
    }
    for _, row in ipairs(rows) do
        if row.kind == "FLAG" then
            if row.label == "Flag" and row.state == "CARRIED" then
                summary.centerFlagActive = true
            elseif row.label == "Home" and row.state == "AVAILABLE" then
                summary.homeAvailable = true
            elseif row.label == "Enemy Flag Room" and row.state == "AVAILABLE" then
                summary.enemyRoomAvailable = true
            end
        end
    end
    return summary
end

local function classifyFlagPlay(play)
    if not play then return "FIELD" end
    local objective = KWR.Util:Text(play.objective, "", 48)
    local action = KWR.Util:Text(play.action, "", 160):upper()
    if objective == "Our FC" or action:find("ESCORT", 1, true)
        or action:find("PROTECT", 1, true) or action:find("PEEL", 1, true) then
        return "ESCORT"
    end
    if objective == "Enemy FC" or action:find("RETURN", 1, true)
        or action:find("KILL", 1, true) or action:find("INTERCEPT", 1, true) then
        return "RETURN"
    end
    if objective == "Home" or objective == "Enemy Flag Room"
        or action:find("RESET", 1, true) or action:find("SCORE", 1, true) then
        return "RESET"
    end
    return "FIELD"
end

local function orbStateSummary(snapshot)
    local carriers = snapshot.objectives and snapshot.objectives.carriers or {}
    local summary = {
        friendlyCarriers = 0,
        enemyCarriers = 0,
        lowFriendlyCarrier = false,
        lowEnemyCarrier = false,
        totalStacks = 0,
    }
    for _, carrier in ipairs(carriers) do
        local owner = KWR.Util:Text(carrier.owner, "UNKNOWN", 16)
        local health = KWR.Util:Number(carrier.healthPercent, nil)
        local stacks = KWR.Util:Number(carrier.stacks, 0) or 0
        summary.totalStacks = summary.totalStacks + stacks
        if owner == "FRIENDLY" then
            summary.friendlyCarriers = summary.friendlyCarriers + 1
            if health and health <= 35 then summary.lowFriendlyCarrier = true end
        elseif owner == "ENEMY" then
            summary.enemyCarriers = summary.enemyCarriers + 1
            if health and health <= 35 then summary.lowEnemyCarrier = true end
        end
    end
    return summary
end

local function classifyOrbPlay(play)
    if not play then return "FIELD" end
    local objective = KWR.Util:Text(play.objective, "", 48)
    local objectiveUpper = objective:upper()
    local action = KWR.Util:Text(play.action, "", 160):upper()
    if objectiveUpper:find("ORB", 1, true) or action:find("PICKUP", 1, true) then
        return "PICKUP"
    end
    if objective == "Enemy Carrier" or action:find("HUNT", 1, true)
        or action:find("KILL", 1, true) or action:find("FOCUS", 1, true) then
        return "HUNT"
    end
    if objective == "Center" and (action:find("CONTROL", 1, true)
        or action:find("HOLD", 1, true) or action:find("ROTATE", 1, true)) then
        return "CENTER"
    end
    if action:find("CARRIER", 1, true) or action:find("PEEL", 1, true)
        or action:find("HANDOFF", 1, true) then
        return "CARRY"
    end
    return "FIELD"
end

local function cartStateSummary(snapshot)
    local objectives = snapshot.objectives or {}
    local summary = {
        vehicles = #(objectives.vehicles or {}),
        activeRows = 0,
        friendlyControlled = 0,
        enemyControlled = 0,
        crystalSeen = false,
    }
    for _, row in ipairs(objectives.rows or {}) do
        local state = KWR.Util:Text(row.state, "UNKNOWN", 20)
        local owner = KWR.Util:Text(row.owner, "UNKNOWN", 16)
        local label = KWR.Util:Text(row.label, "", 48)
        if state == "ACTIVE" then
            summary.activeRows = summary.activeRows + 1
        end
        if owner == "FRIENDLY" and state == "CONTROLLED" then
            summary.friendlyControlled = summary.friendlyControlled + 1
        elseif owner == "ENEMY" and state == "CONTROLLED" then
            summary.enemyControlled = summary.enemyControlled + 1
        end
        if label == "Crystal" then
            summary.crystalSeen = true
        end
    end
    return summary
end

local function classifyCartPlay(play)
    if not play then return "FIELD" end
    local objective = KWR.Util:Text(play.objective, "", 48)
    local action = KWR.Util:Text(play.action, "", 160):upper()
    if objective == "Our Cart" or objective == "Primary Cart"
        or action:find("ESCORT", 1, true) or action:find("ADVANCE", 1, true) then
        return "ESCORT"
    end
    if objective == "Enemy Cart" or action:find("DELAY", 1, true)
        or action:find("INTERCEPT", 1, true) or action:find("STOP", 1, true) then
        return "DELAY"
    end
    if objective == "Crystal" or action:find("CRYSTAL", 1, true) then
        return "CRYSTAL"
    end
    if objective == "Active Cart" or objective == "Lava" or objective == "Water"
        or objective == "Top" or action:find("CART", 1, true) then
        return "LANE"
    end
    return "FIELD"
end

local function resourceStateSummary(snapshot)
    local objectives = snapshot.objectives or {}
    local summary = {
        activeNodes = 0,
        friendlyControlled = 0,
        enemyControlled = 0,
        availableNodes = 0,
        nextSpawnSeen = false,
    }
    for _, row in ipairs(objectives.rows or {}) do
        local label = KWR.Util:Text(row.label, "", 48)
        local owner = KWR.Util:Text(row.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(row.state, "UNKNOWN", 20)
        if label == "Next Spawn" then
            summary.nextSpawnSeen = state ~= "MAP"
        end
        if label ~= "Next Spawn" and state == "ACTIVE" then
            summary.activeNodes = summary.activeNodes + 1
        elseif state == "AVAILABLE" then
            summary.availableNodes = summary.availableNodes + 1
        end
        if owner == "FRIENDLY" and state == "CONTROLLED" then
            summary.friendlyControlled = summary.friendlyControlled + 1
        elseif owner == "ENEMY" and state == "CONTROLLED" then
            summary.enemyControlled = summary.enemyControlled + 1
        end
    end
    return summary
end

local function classifyResourcePlay(play)
    if not play then return "FIELD" end
    local objective = KWR.Util:Text(play.objective, "", 48)
    local action = KWR.Util:Text(play.action, "", 160):upper()
    if objective == "Next Spawn" or action:find("SPAWN", 1, true) then
        return "SPAWN"
    end
    if objective == "Active Node" or action:find("CAPTURE", 1, true)
        or action:find("HOLD NODE", 1, true) then
        return "ACTIVE"
    end
    return "FIELD"
end

local function playMilestone(play, snapshot)
    if not play or not play.id then return "NONE" end
    local family = KWR.Util:Text(play.family, "WORLD", 16)
    if family == "NODE" or family == "HYBRID" then
        local owner, state = currentObjectiveOwner(snapshot, play.objective)
        if owner == "FRIENDLY" and state == "CONTROLLED" then return "OBJECTIVE_SECURED" end
        if state == "INCOMING" or state == "CONTESTED" then return "OBJECTIVE_CONTESTED" end
        if play.objective and play.objective ~= "" then return "ROTATING_TO_OBJECTIVE" end
    elseif family == "FLAG" then
        local summary = flagStateSummary(snapshot)
        local playType = classifyFlagPlay(play)
        if playType == "ESCORT" then
            if summary.friendlyFlagActive > 0 and summary.enemyFlagActive > 0 then
                return "FC_STANDOFF"
            elseif summary.friendlyFlagActive > 0 then
                return "SCORE_WINDOW"
            end
        elseif playType == "RETURN" then
            if summary.enemyFlagActive > 0 then return "RETURN_WINDOW" end
            return "RETURN_RESOLVED"
        elseif playType == "RESET" then
            if summary.homeAvailable and summary.enemyRoomAvailable then
                return "FLAGS_RESET"
            end
        end
    elseif family == "ORB" then
        local summary = orbStateSummary(snapshot)
        local playType = classifyOrbPlay(play)
        if playType == "CENTER" and (summary.friendlyCarriers + summary.enemyCarriers) > 0 then
            return "CENTER_CONTEST"
        elseif playType == "CARRY" and summary.friendlyCarriers > 0 then
            return "FRIENDLY_ORB_LIVE"
        elseif playType == "HUNT" and summary.enemyCarriers > 0 then
            return "ENEMY_ORB_LIVE"
        elseif playType == "PICKUP" and (summary.friendlyCarriers + summary.enemyCarriers) > 0 then
            return "ORB_PICKUP_LIVE"
        end
    elseif family == "CART" then
        local summary = cartStateSummary(snapshot)
        local playType = classifyCartPlay(play)
        if playType == "ESCORT" and (summary.friendlyControlled > 0 or summary.activeRows > 0) then
            return "FRIENDLY_CART_LIVE"
        elseif playType == "DELAY" and (summary.enemyControlled > 0 or summary.activeRows > 0) then
            return "ENEMY_CART_LIVE"
        elseif playType == "CRYSTAL" and summary.crystalSeen then
            return "CRYSTAL_LIVE"
        elseif playType == "LANE" and (summary.activeRows > 0 or summary.vehicles > 0) then
            return "LANE_CONTEST"
        end
    elseif family == "RESOURCE" then
        local summary = resourceStateSummary(snapshot)
        local playType = classifyResourcePlay(play)
        if playType == "ACTIVE" and summary.activeNodes > 0 then
            return "ACTIVE_NODE_LIVE"
        elseif playType == "SPAWN" and summary.nextSpawnSeen then
            return "NEXT_SPAWN_LIVE"
        end
    end
    return "NONE"
end

local function phaseFromMilestone(play, milestone)
    if milestone == "OBJECTIVE_SECURED" then return "COMMITTED" end
    if milestone == "OBJECTIVE_CONTESTED" then return "RESOLVING" end
    if milestone == "FC_STANDOFF" or milestone == "RETURN_WINDOW"
        or milestone == "CENTER_CONTEST" or milestone == "ENEMY_ORB_LIVE"
        or milestone == "FRIENDLY_CART_LIVE" or milestone == "ENEMY_CART_LIVE"
        or milestone == "ACTIVE_NODE_LIVE" then
        return "COMMITTED"
    end
    if milestone == "SCORE_WINDOW" or milestone == "FRIENDLY_ORB_LIVE"
        or milestone == "CRYSTAL_LIVE" or milestone == "NEXT_SPAWN_LIVE"
        or milestone == "LANE_CONTEST" or milestone == "ORB_PICKUP_LIVE" then
        return "MOVING"
    end
    return nil
end

local function milestoneReason(play, milestone)
    local objective = KWR.Util:Text(play and play.objective, "objective", 48)
    local reasons = {
        OBJECTIVE_SECURED = objective .. " remains secured.",
        OBJECTIVE_CONTESTED = objective .. " remains contested.",
        ROTATING_TO_OBJECTIVE = "Rotation toward " .. objective .. " is still live.",
        FC_STANDOFF = "Both flags remain out; hold escort discipline.",
        SCORE_WINDOW = "The friendly flag route remains live.",
        RETURN_WINDOW = "The enemy carrier remains active.",
        RETURN_RESOLVED = "The return state resolved.",
        FLAGS_RESET = "Both flags reset to base.",
        CENTER_CONTEST = "The center orb fight remains live.",
        FRIENDLY_ORB_LIVE = "A friendly orb carrier is still active.",
        ENEMY_ORB_LIVE = "An enemy orb carrier is still active.",
        ORB_PICKUP_LIVE = "Orb pickup is stil…13896 tokens truncated… or "")
            .. (safeCounter and (" COUNTER: " .. safeCounter) or "")
            .. movementReason
            .. (strategy.objectiveDecision and strategy.objectiveDecision.success
                and (" SUCCESS: " .. strategy.objectiveDecision.success) or "")
            .. (strategy.objectiveDecision and strategy.objectiveDecision.abort
                and (" ABORT: " .. strategy.objectiveDecision.abort) or "")
            .. (response.qualified and (" STAY: " .. response.stayerText) or "")
            .. (response.recovery and response.recovery.summary
                and (" RECOVERY: " .. response.recovery.summary) or "")
            .. (trust.reason and (" CHECK: " .. trust.reason) or "")
            .. (knowledge.compositionAuthorized == false
                and (" KNOWLEDGE: " .. KWR.Util:Text(knowledge.reason, "", 120)) or "")
            .. (snapshot.reassessment and snapshot.reassessment.summary
                and (" CHANGES: " .. snapshot.reassessment.summary) or "")
            .. " STOP: " .. (strategy.stop or doctrine.stop or "Avoid low-value fights."),
        "Waiting for live battleground data.",
        220
    )
    if finalStatus then
        local finalScoreTable = type(snapshot.score) == "table" and snapshot.score or {}
        local finalScore = tostring(finalScoreTable.friendly or 0)
            .. "-" .. tostring(finalScoreTable.enemy or 0)
        reason = finalStatus .. " | FINAL SCORE " .. finalScore
    end
    local signature = KWR.Util:Signature({ status, action, who })
    local compactResponse = KWR.CommandReview:CompactResponsePackage(response)
    local compactObjectiveDecision = strategy.objectiveDecision and {
        target = KWR.Util:Text(strategy.objectiveDecision.target, "Unknown", 64),
        success = KWR.Util:Text(strategy.objectiveDecision.success, "Unknown", 160),
        abort = KWR.Util:Text(strategy.objectiveDecision.abort, "Unknown", 160),
    } or nil
    local bypass = classifyBypass(snapshot, response, prediction, stabilized)
    local now = KWR.Util:Now()
    local previousCommand = self.lastCommand
    local command = {
        mapKey = mapKey,
        status = status,
        urgency = prediction.urgency or 0,
        action = action,
        who = who,
        when = when,
        reason = reason,
        confidence = strategy.confidence or prediction.confidence or "NONE",
        planID = strategy.planID,
        branchChoice = branchChoice,
        safeCounter = safeCounter,
        doctrineComparisonID = strategy.doctrineComparisonID,
        enemyResponseGuidanceID = strategy.enemyResponseGuidanceID,
        switchIf = strategy.switchIf,
        objectiveDecision = compactObjectiveDecision,
        responsePackage = compactResponse,
        verificationReason = snapshot.context.inPvP and trust.reason and trust.mode ~= "COMMIT"
            and KWR.Util:Text(trust.reason, "", 110) or nil,
        knowledgeReason = snapshot.context.inPvP and knowledge.compositionAuthorized == false
            and KWR.Util:Text(knowledge.reason, "", 110) or nil,
        signature = signature,
        createdAt = now,
        expiresAt = now + (snapshot.context.inPvP and 3 or 30),
        stabilized = stabilized,
        reassessment = snapshot.reassessment and { active = true } or nil,
        decisionAt = stabilized and self.lastCommand.decisionAt or now,
        candidateAction = candidateAction,
        candidateWho = candidateWho,
        bypass = bypass,
        stability = {
            retentionWindow = snapshot.context.inPvP and 2.5 or 0,
            ttlSeconds = snapshot.context.inPvP and 3 or 30,
            urgencyDelta = previousCommand
                and math.abs((prediction.urgency or 0) - (previousCommand.urgency or 0))
                or 0,
            retained = stabilized == true,
            responseBypass = response.qualified == true,
            reassessmentBypass = snapshot.reassessment ~= nil,
            emergencyBypass = (prediction.urgency or 0) >= 90 and not stabilized,
        },
    }
    local candidatePlay = buildActivePlay(
        snapshot, prediction, strategy, response, command, previousPlay, now)
    self.candidateTrends = self.candidateTrends or {}
    local trend = self.candidateTrends[candidatePlay.id]
    if trend then
        local wins = (trend.consecutiveWins or 0) + 1
        local priorAverage = trend.averageAdvantage or 0
        local currentAdvantage = (candidatePlay.remainingValue or 0)
            - currentRemainingValue(previousPlay, now)
        trend.lastPreferredAt = now
        trend.consecutiveWins = wins
        trend.averageAdvantage = ((priorAverage * (wins - 1)) + currentAdvantage) / wins
        trend.minimumAdvantage = trend.minimumAdvantage
            and math.min(trend.minimumAdvantage, currentAdvantage) or currentAdvantage
    else
        trend = {
            signature = candidatePlay.id,
            firstPreferredAt = now,
            lastPreferredAt = now,
            consecutiveWins = 1,
            averageAdvantage = (candidatePlay.remainingValue or 0)
                - currentRemainingValue(previousPlay, now),
            minimumAdvantage = (candidatePlay.remainingValue or 0)
                - currentRemainingValue(previousPlay, now),
        }
        self.candidateTrends[candidatePlay.id] = trend
    end
    for signature, other in pairs(self.candidateTrends) do
        if signature ~= candidatePlay.id and (now - (other.lastPreferredAt or 0)) > 20 then
            self.candidateTrends[signature] = nil
        end
    end

    local updatedPreviousPlay = previousPlay and KWR.Util:Copy(previousPlay) or nil
    local previousPlayForTransition = updatedPreviousPlay and KWR.Util:Copy(updatedPreviousPlay) or nil
    if updatedPreviousPlay and updatedPreviousPlay.id then
        updatedPreviousPlay.phase = currentPlayPhase(updatedPreviousPlay, snapshot, now)
    end
    local invalidation = invalidationReason(updatedPreviousPlay, snapshot, now)
    local canReplace, replacementReason, replacementScore = replacementAllowed(
        snapshot, updatedPreviousPlay, candidatePlay, trend, prediction, command)
    if invalidation then
        canReplace = true
        replacementReason = "INVALIDATED:" .. invalidation
    end
    local retainedActivePlay = updatedPreviousPlay and updatedPreviousPlay.id
        and invalidation == nil
        and canReplace ~= true
        and (updatedPreviousPlay.minimumCommitUntil or 0) > now
    local activePlay = candidatePlay
    if retainedActivePlay then
        activePlay = updatedPreviousPlay
        command.action = previousState.command and previousState.command.action or command.action
        command.who = previousState.command and previousState.command.who or command.who
        command.when = previousState.command and previousState.command.when or command.when
        command.reason = previousState.command and previousState.command.reason or command.reason
        command.signature = previousState.command and previousState.command.signature or command.signature
        command.bypass = "ACTIVE_PLAY_HOLD"
        command.stabilized = true
        command.decisionAt = previousState.command and previousState.command.decisionAt or command.decisionAt
    else
        activePlay.phase = currentPlayPhase(activePlay, snapshot, now)
    end
    command.activePlay = activePlay
    command.activePlayCandidate = candidatePlay
    command.activePlayTrend = trendSummary(trend)
    local lostCommitmentTime = updatedPreviousPlay and updatedPreviousPlay.minimumCommitUntil
        and math.max(0, (updatedPreviousPlay.minimumCommitUntil or 0) - now) or 0
    command.activePlayDecision = {
        retained = retainedActivePlay == true,
        invalidation = invalidation,
        invalidationFamily = invalidationFamily(invalidation, updatedPreviousPlay or activePlay),
        replacementAllowed = canReplace == true,
        replacementReason = replacementReason,
        gateClass = decisionGateClass(
            invalidation,
            replacementReason,
            retainedActivePlay == true,
            canReplace == true),
        replacementScore = replacementScore,
        lostCommitmentTime = lostCommitmentTime,
        phaseReason = playStateReason(activePlay, snapshot, activePlay.phase, invalidation),
    }
    command.activePlayOutcome = activePlayOutcome(
        activePlay,
        invalidation,
        retainedActivePlay == true,
        canReplace == true)
    command.activePlayTransition = activePlayTransition(
        previousPlayForTransition,
        activePlay,
        invalidation,
        retainedActivePlay == true,
        canReplace == true,
        replacementReason,
        now)
    command.stability.activePlayRetained = retainedActivePlay == true
    command.stability.activePlayDecision = command.activePlayDecision

    self.metrics = self.metrics or {
        issued = 0,
        replacements = 0,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        emergencyBypasses = 0,
        reassessmentBypasses = 0,
        responseBypasses = 0,
        candidateBypasses = 0,
        activePlayRetains = 0,
        suppressedAlternatives = 0,
        suppressedByPersistence = 0,
        suppressedBySuperiority = 0,
        overrides = 0,
        overridesBeforeArrival = 0,
        overridesAfterCommitment = 0,
        invalidations = 0,
        invalidationsBeforeArrival = 0,
        invalidationsAfterCommitment = 0,
        successfulPlays = 0,
        switchAdvantages = {
            total = 0,
            count = 0,
        },
        lifetimes = {
            total = 0,
            count = 0,
            shortest = nil,
            longest = 0,
            samples = {},
        },
        recentSignatures = {},
        evaluations = 0,
    }
    local metrics = self.metrics
    metrics.evaluations = (metrics.evaluations or 0) + 1
    if stabilized then
        metrics.stabilized = metrics.stabilized + 1
        metrics.suppressed = metrics.suppressed + 1
    end
    if retainedActivePlay then
        metrics.activePlayRetains = (metrics.activePlayRetains or 0) + 1
        metrics.suppressedAlternatives = (metrics.suppressedAlternatives or 0) + 1
        if replacementReason == "INSUFFICIENT_PERSISTENCE" then
            metrics.suppressedByPersistence =
                (metrics.suppressedByPersistence or 0) + 1
        elseif replacementReason == "NOT_MATERIALLY_SUPERIOR" then
            metrics.suppressedBySuperiority =
                (metrics.suppressedBySuperiority or 0) + 1
        end
        if updatedPreviousPlay and updatedPreviousPlay.id
            and candidatePlay and candidatePlay.id
            and updatedPreviousPlay.id ~= candidatePlay.id then
            local retainedPhase = phaseBucket(updatedPreviousPlay.phase)
            local record = {
                at = now,
                mapKey = mapKey,
                currentPlay = updatedPreviousPlay.id,
                candidatePlay = candidatePlay.id,
                currentObjective = updatedPreviousPlay.objective,
                candidateObjective = candidatePlay.objective,
                phase = updatedPreviousPlay.phase,
                phaseBucket = retainedPhase,
                invalidation = invalidation,
                invalidationFamily = invalidationFamily(invalidation, updatedPreviousPlay),
                replacementReason = replacementReason,
                gateClass = decisionGateClass(
                    invalidation,
                    replacementReason,
                    retainedActivePlay == true,
                    canReplace == true),
                lostCommitmentTime = lostCommitmentTime,
                confidence = command.confidence,
                requiredDuration = replacementScore and replacementScore.requiredDuration or 0,
                observedDuration = replacementScore and replacementScore.observedDuration or 0,
                evidence = overrideEvidence(snapshot, prediction, command, invalidation, replacementReason),
            }
            self.suppressionLog = self.suppressionLog or {}
            self.suppressionLog[#self.suppressionLog + 1] = record
            while #self.suppressionLog > self.maxSuppressionLog do
                table.remove(self.suppressionLog, 1)
            end
            command.suppressionRecord = record
        end
    end
    if invalidation then
        metrics.invalidations = (metrics.invalidations or 0) + 1
        if invalidation == "PLAY_SUCCEEDED" then
            metrics.successfulPlays = (metrics.successfulPlays or 0) + 1
        end
        local invalidationPhase = phaseBucket(updatedPreviousPlay and updatedPreviousPlay.phase)
        if invalidationPhase == "COMMITTED" then
            metrics.invalidationsAfterCommitment =
                (metrics.invalidationsAfterCommitment or 0) + 1
        else
            metrics.invalidationsBeforeArrival =
                (metrics.invalidationsBeforeArrival or 0) + 1
        end
    end
    if bypass == "EMERGENCY_URGENCY" then
        metrics.emergencyBypasses = metrics.emergencyBypasses + 1
    elseif bypass == "REASSESSMENT" then
        metrics.reassessmentBypasses = metrics.reassessmentBypasses + 1
    elseif bypass == "RESPONSE_PACKAGE" then
        metrics.responseBypasses = metrics.responseBypasses + 1
    elseif bypass == "CANDIDATE_CHANGE" then
        metrics.candidateBypasses = metrics.candidateBypasses + 1
    end
    if canReplace == true and updatedPreviousPlay and updatedPreviousPlay.id
        and updatedPreviousPlay.id ~= candidatePlay.id then
        metrics.overrides = (metrics.overrides or 0) + 1
        if replacementScore then
            local switchAdvantages = metrics.switchAdvantages or { total = 0, count = 0 }
            local advantage = (replacementScore.adjustedAlternative or 0)
                - (replacementScore.currentValue or 0)
            switchAdvantages.total = (switchAdvantages.total or 0) + advantage
            switchAdvantages.count = (switchAdvantages.count or 0) + 1
            metrics.switchAdvantages = switchAdvantages
        end
        local replacementPhase = phaseBucket(updatedPreviousPlay.phase)
        if replacementPhase == "COMMITTED" then
            metrics.overridesAfterCommitment =
                (metrics.overridesAfterCommitment or 0) + 1
        else
            metrics.overridesBeforeArrival =
                (metrics.overridesBeforeArrival or 0) + 1
        end
        local record = {
            at = now,
            mapKey = mapKey,
            currentPlay = updatedPreviousPlay.id,
            candidatePlay = candidatePlay.id,
            currentObjective = updatedPreviousPlay.objective,
            candidateObjective = candidatePlay.objective,
            phase = updatedPreviousPlay.phase,
            phaseBucket = replacementPhase,
            invalidation = invalidation,
            invalidationFamily = invalidationFamily(invalidation, updatedPreviousPlay),
            replacementReason = replacementReason,
            gateClass = decisionGateClass(
                invalidation,
                replacementReason,
                retainedActivePlay == true,
                canReplace == true),
            lostCommitmentTime = lostCommitmentTime,
            confidence = command.confidence,
            requiredDuration = replacementScore and replacementScore.requiredDuration or 0,
            observedDuration = replacementScore and replacementScore.observedDuration or 0,
            evidence = overrideEvidence(snapshot, prediction, command, invalidation, replacementReason),
        }
        self.overrideLog = self.overrideLog or {}
        self.overrideLog[#self.overrideLog + 1] = record
        while #self.overrideLog > self.maxOverrideLog do
            table.remove(self.overrideLog, 1)
        end
        command.overrideRecord = record
    end

    local publishedSignature = command.signature
    if publishedSignature ~= self.lastSignature then
        metrics.issued = metrics.issued + 1
        local replaced = previousCommand and previousCommand.signature
            and previousCommand.signature ~= publishedSignature
        local lifetime = previousCommand and previousCommand.createdAt
            and math.max(0, now - previousCommand.createdAt) or nil
        if replaced then
            metrics.replacements = metrics.replacements + 1
            if lifetime ~= nil then
                local lifetimes = metrics.lifetimes
                lifetimes.total = (lifetimes.total or 0) + lifetime
                lifetimes.count = (lifetimes.count or 0) + 1
                lifetimes.shortest = lifetimes.shortest
                    and math.min(lifetimes.shortest, lifetime) or lifetime
                lifetimes.longest = math.max(lifetimes.longest or 0, lifetime)
                lifetimes.samples[#lifetimes.samples + 1] = lifetime
                while #lifetimes.samples > 32 do table.remove(lifetimes.samples, 1) end
                if previousCommand.decisionAt == previousCommand.createdAt
                    and lifetime < 3 then
                    metrics.preMovementInvalidations =
                        (metrics.preMovementInvalidations or 0) + 1
                end
            end
            local recent = metrics.recentSignatures or {}
            local prior = recent[#recent]
            local twoBack = recent[#recent - 1]
            if prior and twoBack
                and twoBack.signature == publishedSignature
                and prior.signature ~= publishedSignature
                and lifetime ~= nil
                and lifetime <= 10 then
                metrics.reversals = metrics.reversals + 1
            end
        end
        self.history[#self.history + 1] = {
            at = command.createdAt,
            mapKey = command.mapKey,
            status = status,
            action = action,
            reason = reason,
            who = who,
            signature = publishedSignature,
            bypass = bypass,
            stabilized = stabilized,
            lifetime = lifetime,
            activePlayOutcome = KWR.Util:Copy(command.activePlayOutcome),
            activePlayTransition = KWR.Util:Copy(command.activePlayTransition),
            activePlayDecision = KWR.Util:Copy(command.activePlayDecision),
        }
        while #self.history > self.maxHistory do table.remove(self.history, 1) end
        self.lastSignature = publishedSignature
        local recent = metrics.recentSignatures
        recent[#recent + 1] = {
            at = now,
            signature = publishedSignature,
        }
        while #recent > 6 do table.remove(recent, 1) end
    end
    self.lastCommand = {
        mapKey = snapshot.context.mapKey,
        status = status,
        urgency = command.urgency,
        action = command.action,
        who = command.who,
        signature = publishedSignature,
        createdAt = command.createdAt,
        decisionAt = command.decisionAt,
        stabilizationSignature = stabilizationSignature,
    }
    self.lastActivePlay = KWR.Util:Copy(activePlay)
    command.stabilitySummary = stabilitySummary(metrics)
    return command
end

function Commander:GetHistory()
    return self.history
end

function Commander:GetStabilityMetrics()
    return stabilitySummary(self.metrics)
end

function Commander:GetOverrideLog()
    return self.overrideLog or {}
end

function Commander:GetSuppressionLog()
    return self.suppressionLog or {}
end

function Commander:ResetSession()
    self.lastCommand = nil
    self.lastSignature = nil
    self.lastActivePlay = nil
    self.metrics = nil
    self.candidateTrends = nil
    self.overrideLog = {}
    self.suppressionLog = {}
    self.history = {}
end

function Commander:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "CommanderHistory")
    end
    self:ResetSession()
end

KWR:RegisterModule("Commander", Commander)