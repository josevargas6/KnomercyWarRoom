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

local function qualifiedResponseRequiresReplacement(response)
    if not response or response.qualified ~= true then return false end
    -- A normal response package refines movers/stayers under the current
    -- strategy. It is not a reason to discard an active play every refresh.
    -- Only an explicit emergency or a confirmed critical coverage gap may
    -- cross the commitment gate without ordinary superiority/persistence.
    return response.emergency == true
        or (response.recovery and KWR.Util:Text(response.recovery.criticalGap, "", 48) ~= "")
end

local function classifyBypass(snapshot, response, prediction, stabilized)
    if stabilized then return "STABILIZED" end
    if snapshot.reassessment then return "REASSESSMENT" end
    if qualifiedResponseRequiresReplacement(response) then return "RESPONSE_PACKAGE" end
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
        ORB_PICKUP_LIVE = "Orb pickup is still unresolved.",
        FRIENDLY_CART_LIVE = "The friendly cart lane remains live.",
        ENEMY_CART_LIVE = "The enemy cart lane remains live.",
        CRYSTAL_LIVE = "The crystal objective remains live.",
        LANE_CONTEST = "The cart lane remains contested.",
        ACTIVE_NODE_LIVE = "The active resource node remains live.",
        NEXT_SPAWN_LIVE = "The next spawn is still relevant.",
    }
    return reasons[milestone] or "Play remains live."
end

local function invalidationReasonText(code)
    local reasons = {
        MATCH_COMPLETE = "The battleground ended.",
        MAP_FAMILY_CHANGED = "The active battleground family changed.",
        HELD_NODE_LOST = "The held node was lost.",
        FAST_TICK_NODE_UNSTABLE = "The node became unstable on a fast score clock.",
        NODE_RESOLUTION_MISSED = "The node did not resolve before the play expired.",
        FRIENDLY_FLAG_STATE_CHANGED = "The friendly flag state changed.",
        ENEMY_FLAG_STATE_CHANGED = "The enemy flag state changed.",
        FLAGS_RESET = "The flags reset.",
        FLAG_CAPTURED = "A flag capture resolved the play.",
        FRIENDLY_ORB_STATE_CHANGED = "Friendly orb possession changed.",
        ENEMY_ORB_STATE_CHANGED = "Enemy orb possession changed.",
        ORBS_RESET = "Orb control reset.",
        FRIENDLY_CART_STATE_CHANGED = "The friendly cart lane changed state.",
        ENEMY_CART_STATE_CHANGED = "The enemy cart lane changed state.",
        CRYSTAL_STATE_CHANGED = "The crystal state changed.",
        ACTIVE_NODE_STATE_CHANGED = "The active node changed state.",
        NEXT_SPAWN_STATE_CHANGED = "The next-spawn state changed.",
        HARD_DEADLINE_PASSED = "The play deadline passed before resolution.",
        PLAY_SUCCEEDED = "The battlefield result already resolved in our favor.",
        PLAY_EXPIRED = "The play expired before resolution.",
    }
    return reasons[code] or "The play state changed."
end

local function actionHasVerb(play, verbs)
    local action = KWR.Util:Text(play and play.action, "", 200):upper()
    for _, verb in ipairs(verbs or {}) do
        if action:find(verb, 1, true) then
            return true
        end
    end
    return false
end

local function isResolutionPlay(play)
    if not play or not play.id then return false end
    local family = KWR.Util:Text(play.family, "WORLD", 16)
    if family == "NODE" or family == "HYBRID" then
        return actionHasVerb(play, {
            "TAKE", "CAPTURE", "SECURE", "ASSAULT", "RECAP",
        })
    elseif family == "FLAG" then
        local playType = classifyFlagPlay(play)
        return playType == "RETURN" or playType == "RESET"
    elseif family == "ORB" then
        local playType = classifyOrbPlay(play)
        return playType == "HUNT" or playType == "PICKUP"
    elseif family == "CART" then
        local playType = classifyCartPlay(play)
        return playType == "DELAY" or playType == "CRYSTAL"
    elseif family == "RESOURCE" then
        local playType = classifyResourcePlay(play)
        return playType == "ACTIVE" or playType == "SPAWN"
    end
    return false
end

local function playSucceeded(play, snapshot)
    if not play or not play.id then return false end
    local family = KWR.Util:Text(play.family, "WORLD", 16)
    if family == "NODE" or family == "HYBRID" then
        local owner, state = currentObjectiveOwner(snapshot, play.objective)
        if owner ~= "FRIENDLY" or state ~= "CONTROLLED" then return false end
        return actionHasVerb(play, {
            "TAKE", "CAPTURE", "SECURE", "ASSAULT", "RECAP", "CONTROL",
        })
            and not actionHasVerb(play, { "HOLD", "DEFEND", "STABILIZE", "PEEL" })
    elseif family == "FLAG" then
        local summary = flagStateSummary(snapshot)
        local playType = classifyFlagPlay(play)
        if playType == "RETURN" then
            return summary.enemyFlagActive <= 0 and summary.homeAvailable == true
        elseif playType == "RESET" then
            return summary.homeAvailable == true and summary.enemyRoomAvailable == true
        elseif playType == "ESCORT" then
            return (snapshot.score and snapshot.score.lastCapture) == "FRIENDLY"
                or (summary.friendlyFlagActive <= 0 and summary.enemyFlagActive <= 0
                    and summary.homeAvailable == true)
        end
    elseif family == "ORB" then
        local summary = orbStateSummary(snapshot)
        local playType = classifyOrbPlay(play)
        if playType == "HUNT" then
            return summary.enemyCarriers <= 0
        elseif playType == "PICKUP" then
            return summary.friendlyCarriers > 0
        end
    elseif family == "CART" then
        local summary = cartStateSummary(snapshot)
        local playType = classifyCartPlay(play)
        local owner, state = currentObjectiveOwner(snapshot, play.objective)
        if playType == "ESCORT" then
            return owner == "FRIENDLY" and state == "CONTROLLED" and summary.activeRows <= 0
        elseif playType == "DELAY" then
            return summary.enemyControlled <= 0 and summary.activeRows <= 0
        elseif playType == "LANE" then
            return owner == "FRIENDLY" and state == "CONTROLLED" and summary.activeRows <= 0
        end
    elseif family == "RESOURCE" then
        local summary = resourceStateSummary(snapshot)
        local playType = classifyResourcePlay(play)
        local owner, state = currentObjectiveOwner(snapshot, play.objective)
        local objectiveRow = currentObjectiveRow(snapshot, play.objective)
        if playType == "ACTIVE" then
            return owner == "FRIENDLY" and state == "CONTROLLED"
        elseif playType == "SPAWN" then
            if objectiveRow then
                return owner == "FRIENDLY" and state == "CONTROLLED"
            end
            return summary.nextSpawnSeen ~= true and summary.availableNodes > 0
        end
    end
    return false
end

local function playStateReason(play, snapshot, phase, invalidation)
    if invalidation then return invalidationReasonText(invalidation) end
    if phase == "FAILED" then
        return "The play deadline passed before the required battlefield result."
    end
    if phase == "SUCCEEDED" then
        return "The required battlefield result has been achieved."
    end
    return milestoneReason(play, play and play.milestone or "NONE")
end

local function activePlayOutcome(play, invalidation, retained, replacementAllowed)
    if not play or not play.id then
        return {
            status = "NONE",
            phase = "EXPIRED",
            bucket = "PRE_ARRIVAL",
            reason = "No active play existed.",
            invalidation = invalidation,
            retained = retained == true,
            replacementAllowed = replacementAllowed == true,
        }
    end
    local status = "LIVE"
    if retained == true then
        status = "HELD"
    elseif invalidation == "PLAY_SUCCEEDED" or play.phase == "SUCCEEDED" then
        status = "SUCCEEDED"
    elseif invalidation ~= nil or play.phase == "FAILED" or play.phase == "EXPIRED" then
        status = "FAILED"
    elseif replacementAllowed == true then
        status = "REPLACED"
    end
    return {
        status = status,
        phase = play.phase or "UNKNOWN",
        bucket = phaseBucket(play.phase),
        reason = playStateReason(play, nil, play.phase, invalidation),
        invalidation = invalidation,
        retained = retained == true,
        replacementAllowed = replacementAllowed == true,
        objective = play.objective,
        family = play.family,
        milestone = play.milestone,
    }
end

local function activePlayTransition(previousPlay, activePlay, invalidation,
    retained, replacementAllowed, replacementReason, now)
    local fromPhase = previousPlay and previousPlay.phase or "NONE"
    local toPhase = activePlay and activePlay.phase or "EXPIRED"
    local trigger = "STEADY"
    if invalidation == "PLAY_SUCCEEDED" or toPhase == "SUCCEEDED" then
        trigger = "SUCCESS"
    elseif invalidation == "HARD_DEADLINE_PASSED"
        or invalidation == "PLAY_EXPIRED" or toPhase == "FAILED"
        or toPhase == "EXPIRED" then
        trigger = "FAILURE"
    elseif invalidation ~= nil then
        trigger = "INVALIDATION"
    elseif retained == true then
        trigger = "HELD"
    elseif replacementAllowed == true and previousPlay and activePlay
        and previousPlay.id and activePlay.id and previousPlay.id ~= activePlay.id then
        trigger = "REPLACED"
    elseif fromPhase ~= toPhase then
        trigger = "PHASE_ADVANCED"
    end
    local rule = invalidation or replacementReason
        or (activePlay and activePlay.milestone) or trigger
    return {
        trigger = trigger,
        fromPhase = fromPhase,
        toPhase = toPhase,
        rule = rule,
        reason = invalidation and invalidationReasonText(invalidation)
            or playStateReason(activePlay, nil, toPhase, nil),
        at = now,
        age = activePlay and activePlay.issuedAt
            and math.max(0, now - activePlay.issuedAt) or 0,
        objective = activePlay and activePlay.objective,
        family = activePlay and activePlay.family,
        retained = retained == true,
        replacementAllowed = replacementAllowed == true,
    }
end

local function travelPenalty(definition, currentObjective, nextObjective)
    if not definition or not definition.key or not currentObjective or not nextObjective
        or currentObjective == nextObjective then
        return 0, nil
    end
    local estimate = KWR.Maps:TravelEstimate(definition.key, currentObjective, nextObjective, {
        mounted = true,
    })
    if not estimate then return 0, nil end
    local penalty = 0
    if estimate.band == "LONG" then
        penalty = 8
    elseif estimate.band == "ROTATION" then
        penalty = 5
    elseif estimate.band == "NEAR" then
        penalty = 2
    end
    return penalty, estimate
end

local function currentPlayPhase(play, snapshot, now)
    if not play or not play.id then return "EXPIRED" end
    if snapshot.context and snapshot.context.matchComplete then
        return "EXPIRED"
    end
    local milestone = playMilestone(play, snapshot)
    play.milestone = milestone
    if playSucceeded(play, snapshot) then
        return "SUCCEEDED"
    end
    if isResolutionPlay(play)
        and play.hardDeadlineAt and play.hardDeadlineAt > 0 and now >= play.hardDeadlineAt then
        return "FAILED"
    end
    local milestonePhase = phaseFromMilestone(play, milestone)
    if milestonePhase == "SUCCEEDED" or milestonePhase == "RESOLVING"
        or milestonePhase == "COMMITTED" then
        return milestonePhase
    end
    if play.expectedResolutionAt and play.expectedResolutionAt > 0 and now >= play.expectedResolutionAt then
        return "RESOLVING"
    end
    if play.expectedArrivalAt and play.expectedArrivalAt > 0 and now >= play.expectedArrivalAt then
        return "COMMITTED"
    end
    if play.reviewAt and play.reviewAt > 0 and now >= play.reviewAt then
        return "MOVING"
    end
    if milestonePhase then return milestonePhase end
    return "ISSUED"
end

local function executionTiming(snapshot, previousPlay, family, objective, action, movers)
    local context = snapshot.context or {}
    local mapKey = context.mapKey
    local definition = mapKey and KWR.Maps:Get(mapKey) or nil
    local moverCount = #(movers or {})
    local responseDelay = context.inPvP and 4 or 2
    local groupDelay = math.max(3, math.min(8, moverCount + 2))
    local interaction = 0
    local travel = 0

    if previousPlay and previousPlay.objective and objective
        and previousPlay.objective ~= objective and mapKey then
        local estimate = KWR.Maps:TravelEstimate(mapKey, previousPlay.objective, objective, {
            mounted = true,
        })
        if estimate and estimate.seconds then
            travel = math.max(2, math.min(12, math.floor((estimate.seconds * 0.5) + 0.5)))
        end
    end

    if family == "NODE" or family == "HYBRID" then
        local capture = definition and (definition.captureSeconds or definition.blitzCaptureSeconds) or 30
        interaction = math.max(8, math.min(18, math.floor((capture * 0.25) + 0.5)))
        if actionHasVerb({ action = action }, { "HOLD", "DEFEND", "STABILIZE", "PEEL" }) then
            interaction = math.max(6, interaction - 4)
        end
    elseif family == "FLAG" then
        local playType = classifyFlagPlay({ objective = objective, action = action })
        if playType == "ESCORT" then
            interaction = 10
        elseif playType == "RETURN" then
            interaction = 8
        elseif playType == "RESET" then
            interaction = 7
        else
            interaction = 6
        end
    elseif family == "ORB" then
        local playType = classifyOrbPlay({ objective = objective, action = action })
        if playType == "CENTER" or playType == "CARRY" then
            interaction = 8
        else
            interaction = 6
        end
    elseif family == "CART" then
        local playType = classifyCartPlay({ objective = objective, action = action })
        if playType == "ESCORT" or playType == "DELAY" then
            interaction = 9
        elseif playType == "CRYSTAL" then
            interaction = 6
        else
            interaction = 7
        end
    elseif family == "RESOURCE" then
        local playType = classifyResourcePlay({ objective = objective, action = action })
        interaction = playType == "SPAWN" and 6 or 8
    else
        interaction = 5
    end

    return {
        responseDelay = responseDelay,
        groupDelay = groupDelay,
        travel = travel,
        interaction = interaction,
        commitment = responseDelay + groupDelay + travel + interaction,
    }
end

local function buildActivePlay(snapshot, prediction, strategy, response, command, previousPlay, now)
    local family = snapshot.context and snapshot.context.kind or "WORLD"
    local objective = (response and response.target) or strategy.target
        or (strategy.objectiveDecision and strategy.objectiveDecision.target) or nil
    local movers = splitNames(response and response.moverText or command.who)
    local stayers = splitNames(response and response.stayerText or "")
    local baseCommit = snapshot.context and snapshot.context.inPvP and 12 or 6
    if family == "NODE" or family == "HYBRID" then
        baseCommit = 18
    elseif family == "FLAG" then
        baseCommit = 14
    elseif family == "ORB" then
        baseCommit = 10
    elseif family == "CART" or family == "RESOURCE" then
        baseCommit = 12
    end
    if family == "FLAG" then
        local flagType = classifyFlagPlay({
            objective = objective,
            action = command.action,
        })
        if flagType == "ESCORT" then
            baseCommit = 18
        elseif flagType == "RETURN" then
            baseCommit = 16
        elseif flagType == "RESET" then
            baseCommit = 12
        end
    elseif family == "ORB" then
        local orbType = classifyOrbPlay({
            objective = objective,
            action = command.action,
        })
        if orbType == "CARRY" or orbType == "CENTER" then
            baseCommit = 12
        elseif orbType == "HUNT" then
            baseCommit = 8
        elseif orbType == "PICKUP" then
            baseCommit = 10
        end
    elseif family == "CART" then
        local cartType = classifyCartPlay({
            objective = objective,
            action = command.action,
        })
        if cartType == "ESCORT" then
            baseCommit = 14
        elseif cartType == "DELAY" then
            baseCommit = 12
        elseif cartType == "CRYSTAL" then
            baseCommit = 10
        elseif cartType == "LANE" then
            baseCommit = 12
        end
    elseif family == "RESOURCE" then
        local resourceType = classifyResourcePlay({
            objective = objective,
            action = command.action,
        })
        if resourceType == "SPAWN" then
            baseCommit = 10
        elseif resourceType == "ACTIVE" then
            baseCommit = 12
        end
    end
    local timing = executionTiming(snapshot, previousPlay, family, objective, command.action, movers)
    baseCommit = math.max(baseCommit, timing.commitment)
    if response and response.qualified then baseCommit = baseCommit + 4 end
    if (prediction.urgency or 0) >= 85 then baseCommit = math.max(6, baseCommit - 3) end
    local responseDelay = timing.responseDelay
    local groupDelay = timing.groupDelay
    local arrival = now + responseDelay + groupDelay
    local resolution = prediction.captureDeadline
        or ((prediction.timeToWin and family ~= "WORLD") and (now + prediction.timeToWin) or nil)
        or (arrival + baseCommit)
    local hardDeadline = resolution and (resolution + math.max(4, math.floor(baseCommit * 0.25))) or nil
    local actionCode = KWR.Util:Text(
        response and response.actionID,
        KWR.Util:Text(command.action, "PLAY", 48):match("^[^%s:.]+") or "PLAY",
        48)
    local id = KWR.Util:Signature({
        family,
        command.planID or strategy.planID or command.action,
        objective or "none",
        actionCode,
    })
    local play = {
        id = id,
        family = family,
        action = command.action,
        actionCode = actionCode,
        objective = objective,
        movers = movers,
        stayers = stayers,
        issuedAt = previousPlay and previousPlay.id == id and previousPlay.issuedAt or now,
        minimumCommitUntil = previousPlay and previousPlay.id == id
            and previousPlay.minimumCommitUntil or (now + baseCommit),
        reviewAt = previousPlay and previousPlay.id == id
            and previousPlay.reviewAt or (now + responseDelay),
        expectedArrivalAt = previousPlay and previousPlay.id == id
            and previousPlay.expectedArrivalAt or arrival,
        expectedResolutionAt = previousPlay and previousPlay.id == id
            and previousPlay.expectedResolutionAt or resolution,
        hardDeadlineAt = previousPlay and previousPlay.id == id
            and previousPlay.hardDeadlineAt or hardDeadline,
        phase = "ISSUED",
        scoreAtIssue = previousPlay and previousPlay.id == id
            and previousPlay.scoreAtIssue
            or ((prediction.urgency or 0) < 100 and (100 - (prediction.urgency or 0)) or 0),
        remainingValue = math.max(0, 100 - (prediction.urgency or 0)),
        successRules = {
            strategy.objectiveDecision and strategy.objectiveDecision.success
                or "Objective becomes favorable.",
        },
        abortRules = {
            strategy.objectiveDecision and strategy.objectiveDecision.abort
                or strategy.switchIf or "Scoring path or manpower changes.",
        },
        invalidationRules = {
            "Match completes.",
            "Required objective state becomes impossible or irrelevant.",
            "Current map or battleground family changes.",
        },
        sourceEvidence = {
            strategy.planID or "none",
            prediction.status or "WAITING",
            response and response.actionID or "HOLD_PLAN",
            command.bypass or "CANDIDATE_CHANGE",
        },
        confidence = tonumber(strategy.decisionScore or 0)
            or tonumber(prediction.urgency or 0) or 0,
        milestone = "NONE",
        commitmentSeconds = baseCommit,
        travelSeconds = timing.travel,
        interactionSeconds = timing.interaction,
    }
    if family == "FLAG" then
        local flags = flagStateSummary(snapshot)
        local score = snapshot.score or {}
        play.flagBaseline = {
            friendlyFlagActive = flags.friendlyFlagActive or 0,
            enemyFlagActive = flags.enemyFlagActive or 0,
            homeAvailable = flags.homeAvailable == true,
            enemyRoomAvailable = flags.enemyRoomAvailable == true,
            score = KWR.Util:Signature({ score.friendly or 0, score.enemy or 0 }),
        }
    end
    play.phase = currentPlayPhase(play, snapshot, now)
    return play
end

local function requiredPersistenceSeconds(currentPlay, nextPlay)
    if not nextPlay or not nextPlay.id then return 0 end
    if not currentPlay or not currentPlay.id then return 3 end
    local required = 0
    if currentPlay.objective == nextPlay.objective then
        required = 4
    elseif currentPlay.family == nextPlay.family
        and (currentPlay.family == "NODE" or currentPlay.family == "HYBRID") then
        required = 8
    elseif currentPlay.family == nextPlay.family then
        required = 6
    else
        required = 10
    end
    if currentPlay.phase == "COMMITTED" or currentPlay.phase == "RESOLVING" then
        required = required + 2
    end
    if (nextPlay.travelSeconds or 0) > 0 then
        required = required + math.min(4, math.max(1, math.floor((nextPlay.travelSeconds or 0) / 3)))
    end
    if (nextPlay.commitmentSeconds or 0) > 18 then
        required = required + math.min(4,
            math.max(1, math.floor(((nextPlay.commitmentSeconds or 0) - 18) / 4) + 1))
    end
    return required
end

local function switchMargin(currentPlay, nextPlay)
    if not currentPlay or not currentPlay.id then return 0 end
    if currentPlay.objective == nextPlay.objective then return 8 end
    if currentPlay.family ~= nextPlay.family then return 25 end
    if currentPlay.phase == "COMMITTED" or currentPlay.phase == "RESOLVING" then
        return 20
    end
    return 18
end

local function nodeFamilyPolicy(definition, snapshot, currentPlay, nextPlay)
    definition = definition or {}
    local mapKey = definition.key
    local maxObjectives = definition.maxObjectives or 3
    local tickSeconds = definition.tickSeconds or 2
    local captureSeconds = snapshot.context and snapshot.context.isBlitz
        and (definition.blitzCaptureSeconds or definition.captureSeconds or 60)
        or (definition.captureSeconds or 60)
    local summary = objectiveSummary(snapshot)
    local objectiveDelta = maxObjectives >= 5 and 4 or 0
    local fastTickDelta = tickSeconds <= 1 and 5 or 0
    local outerRotationDelta = 0
    local defensePenalty = 0
    local structurePenalty = 0
    local centerAnchorPenalty = 0
    local routeEstimate = nil
    if currentPlay and currentPlay.objective and nextPlay and nextPlay.objective
        and currentPlay.objective ~= nextPlay.objective then
        outerRotationDelta, routeEstimate = travelPenalty(
            definition, currentPlay.objective, nextPlay.objective)
        local owner = currentObjectiveOwner(snapshot, currentPlay.objective)
        if owner == "FRIENDLY" then
            defensePenalty = maxObjectives <= 3 and 8 or 5
        end
    end
    if mapKey == "GILNEAS" then
        if summary.friendly >= 2 then
            structurePenalty = structurePenalty + 8
        end
        if currentPlay and currentPlay.objective == "Waterworks"
            and nextPlay and nextPlay.objective ~= "Waterworks" then
            centerAnchorPenalty = centerAnchorPenalty + 6
        end
    elseif mapKey == "ARATHI" then
        local outer = {
            ["Lumber Mill"] = true,
            Mine = true,
            Farm = true,
            Stables = true,
        }
        if currentPlay and nextPlay and outer[currentPlay.objective]
            and outer[nextPlay.objective] then
            structurePenalty = structurePenalty + 5
        end
        if currentPlay and currentPlay.objective == "Blacksmith"
            and nextPlay and nextPlay.objective ~= "Blacksmith" then
            centerAnchorPenalty = centerAnchorPenalty + 4
        end
    elseif mapKey == "DEEPWIND" then
        local outer = {
            Quarry = true,
            Farm = true,
        }
        if currentPlay and nextPlay and outer[currentPlay.objective]
            and outer[nextPlay.objective] then
            structurePenalty = structurePenalty + 4
        end
        if currentPlay and currentPlay.objective == "Market"
            and nextPlay and nextPlay.objective ~= "Market" then
            centerAnchorPenalty = centerAnchorPenalty + 4
        end
    elseif mapKey == "EOTS" then
        if currentPlay and currentPlay.objective == "Flag" then
            structurePenalty = structurePenalty + 3
        end
        if nextPlay and nextPlay.objective == "Flag"
            and currentPlay and currentPlay.objective ~= "Flag"
            and summary.friendly >= 2 then
            structurePenalty = structurePenalty + 6
        end
    end
    return {
        persistenceBonus = math.max(0, math.floor(captureSeconds / 15)),
        switchMarginBonus = objectiveDelta + fastTickDelta + defensePenalty
            + structurePenalty + centerAnchorPenalty,
        travelPenalty = outerRotationDelta,
        defensePenalty = defensePenalty,
        structurePenalty = structurePenalty,
        centerAnchorPenalty = centerAnchorPenalty,
        captureSeconds = captureSeconds,
        tickSeconds = tickSeconds,
        routeEstimate = routeEstimate,
        heldFriendlyObjectives = summary.friendly,
        contestedObjectives = summary.contested,
    }
end

local function flagFamilyPolicy(definition, snapshot, currentPlay, nextPlay)
    definition = definition or {}
    local summary = flagStateSummary(snapshot)
    local stackSeconds = definition.stackSeconds or 30
    local mapKey = snapshot.context and snapshot.context.mapKey or ""
    local currentType = classifyFlagPlay(currentPlay)
    local nextType = classifyFlagPlay(nextPlay)
    local structurePenalty = 0
    local carryPenalty = 0
    local resetPenalty = 0
    local routePenalty = 0
    if currentType == "ESCORT" and nextType ~= "ESCORT" and summary.friendlyFlagActive > 0 then
        carryPenalty = carryPenalty + 10
    end
    if currentType == "RETURN" and nextType ~= "RETURN" and summary.enemyFlagActive > 0 then
        carryPenalty = carryPenalty + 8
    end
    if currentType == "RESET" and nextType ~= "RESET"
        and (summary.homeAvailable ~= true or summary.enemyRoomAvailable ~= true) then
        resetPenalty = resetPenalty + 6
    end
    if summary.friendlyFlagActive > 0 and summary.enemyFlagActive > 0 then
        structurePenalty = structurePenalty + 6
    elseif summary.friendlyFlagActive > 0 or summary.enemyFlagActive > 0 then
        structurePenalty = structurePenalty + 4
    end
    if mapKey == "TWINPEAKS" then
        if (currentType == "ESCORT" or currentType == "RETURN") and nextType == "FIELD" then
            routePenalty = routePenalty + 4
        end
        if currentType == "RESET" and nextType ~= "RESET" then
            routePenalty = routePenalty + 3
        end
    end
    return {
        persistenceBonus = math.max(0, math.floor(stackSeconds / 10)),
        switchMarginBonus = structurePenalty + carryPenalty + resetPenalty + routePenalty,
        carryPenalty = carryPenalty,
        resetPenalty = resetPenalty,
        structurePenalty = structurePenalty,
        routePenalty = routePenalty,
        stackSeconds = stackSeconds,
        flagSummary = summary,
    }
end

local function orbFamilyPolicy(snapshot, currentPlay, nextPlay)
    local summary = orbStateSummary(snapshot)
    local currentType = classifyOrbPlay(currentPlay)
    local nextType = classifyOrbPlay(nextPlay)
    local carryPenalty = 0
    local centerPenalty = 0
    local huntPenalty = 0
    if currentType == "CARRY" and nextType ~= "CARRY" and summary.friendlyCarriers > 0 then
        carryPenalty = carryPenalty + 8
    end
    if currentType == "CENTER" and nextType ~= "CENTER"
        and (summary.friendlyCarriers + summary.enemyCarriers) >= 2 then
        centerPenalty = centerPenalty + 6
    end
    if currentType == "HUNT" and nextType ~= "HUNT" and summary.enemyCarriers > 0 then
        huntPenalty = huntPenalty + 5
    end
    return {
        switchMarginBonus = carryPenalty + centerPenalty + huntPenalty,
        carryPenalty = carryPenalty,
        centerPenalty = centerPenalty,
        huntPenalty = huntPenalty,
        summary = summary,
    }
end

local function cartFamilyPolicy(snapshot, currentPlay, nextPlay)
    local summary = cartStateSummary(snapshot)
    local mapKey = snapshot.context and snapshot.context.mapKey or ""
    local currentType = classifyCartPlay(currentPlay)
    local nextType = classifyCartPlay(nextPlay)
    local escortPenalty = 0
    local delayPenalty = 0
    local crystalPenalty = 0
    local lanePenalty = 0
    local crystalOpportunityPenalty = 0
    if currentType == "ESCORT" and nextType ~= "ESCORT"
        and (summary.friendlyControlled > 0 or summary.activeRows > 0) then
        escortPenalty = escortPenalty + 8
    end
    if currentType == "DELAY" and nextType ~= "DELAY"
        and (summary.enemyControlled > 0 or summary.activeRows > 0) then
        delayPenalty = delayPenalty + 7
    end
    if currentType == "CRYSTAL" and nextType ~= "CRYSTAL" and summary.crystalSeen then
        crystalPenalty = crystalPenalty + 5
    end
    if currentType == "LANE" and nextType ~= "LANE" and summary.vehicles > 0 then
        lanePenalty = lanePenalty + 5
    end
    if mapKey == "DEEPHAUL" and nextType == "CRYSTAL"
        and (currentType == "ESCORT" or currentType == "DELAY" or currentType == "LANE")
        and (summary.friendlyControlled > 0 or summary.enemyControlled > 0 or summary.activeRows > 0) then
        crystalOpportunityPenalty = crystalOpportunityPenalty + 6
    end
    if mapKey == "DEEPHAUL" and currentType == "CRYSTAL" and nextType ~= "CRYSTAL"
        and summary.crystalSeen then
        crystalOpportunityPenalty = crystalOpportunityPenalty + 4
    end
    return {
        switchMarginBonus = escortPenalty + delayPenalty + crystalPenalty
            + lanePenalty + crystalOpportunityPenalty,
        escortPenalty = escortPenalty,
        delayPenalty = delayPenalty,
        crystalPenalty = crystalPenalty,
        lanePenalty = lanePenalty,
        crystalOpportunityPenalty = crystalOpportunityPenalty,
        summary = summary,
    }
end

local function resourceFamilyPolicy(snapshot, currentPlay, nextPlay)
    local summary = resourceStateSummary(snapshot)
    local mapKey = snapshot.context and snapshot.context.mapKey or ""
    local currentType = classifyResourcePlay(currentPlay)
    local nextType = classifyResourcePlay(nextPlay)
    local activePenalty = 0
    local spawnPenalty = 0
    local spawnOpportunityPenalty = 0
    if currentType == "ACTIVE" and nextType ~= "ACTIVE"
        and (summary.activeNodes > 0 or summary.friendlyControlled > 0) then
        activePenalty = activePenalty + 7
    end
    if currentType == "SPAWN" and nextType ~= "SPAWN" and summary.nextSpawnSeen then
        spawnPenalty = spawnPenalty + 6
    end
    if mapKey == "SEETHING" and currentType == "ACTIVE" and nextType == "SPAWN"
        and summary.activeNodes > 0 then
        spawnOpportunityPenalty = spawnOpportunityPenalty + 5
    end
    if mapKey == "SEETHING" and currentType == "SPAWN" and nextType == "ACTIVE"
        and summary.nextSpawnSeen then
        spawnOpportunityPenalty = spawnOpportunityPenalty + 4
    end
    return {
        switchMarginBonus = activePenalty + spawnPenalty + spawnOpportunityPenalty,
        activePenalty = activePenalty,
        spawnPenalty = spawnPenalty,
        spawnOpportunityPenalty = spawnOpportunityPenalty,
        summary = summary,
    }
end

local function nodeInvalidationReason(definition, play, snapshot, now)
    if not play or not play.objective then return nil end
    local owner, state = currentObjectiveOwner(snapshot, play.objective)
    if owner and owner ~= "FRIENDLY"
        and (play.phase == "COMMITTED" or play.phase == "RESOLVING") then
        return "HELD_NODE_LOST"
    end
    if state == "INCOMING" and (play.phase == "MOVING" or play.phase == "COMMITTED") then
        local tickSeconds = definition and definition.tickSeconds or 2
        if tickSeconds <= 1 then
            return "FAST_TICK_NODE_UNSTABLE"
        end
    end
    if play.expectedResolutionAt and now >= play.expectedResolutionAt
        and owner ~= "FRIENDLY" then
        return "NODE_RESOLUTION_MISSED"
    end
    return nil
end

local function flagInvalidationReason(definition, play, snapshot)
    if not play then return nil end
    local summary = flagStateSummary(snapshot)
    local baseline = play.flagBaseline or {}
    local playType = classifyFlagPlay(play)
    if playType == "ESCORT" and (baseline.friendlyFlagActive or 0) > 0
        and summary.friendlyFlagActive <= 0 then
        return "FRIENDLY_FLAG_STATE_CHANGED"
    end
    if playType == "RETURN" and (baseline.enemyFlagActive or 0) > 0
        and summary.enemyFlagActive <= 0 then
        return "ENEMY_FLAG_STATE_CHANGED"
    end
    if playType == "RESET"
        and ((baseline.friendlyFlagActive or 0) > 0
            or (baseline.enemyFlagActive or 0) > 0
            or baseline.homeAvailable ~= true
            or baseline.enemyRoomAvailable ~= true)
        and summary.friendlyFlagActive <= 0
        and summary.enemyFlagActive <= 0
        and summary.homeAvailable == true
        and summary.enemyRoomAvailable == true then
        return "FLAGS_RESET"
    end
    local score = snapshot.score or {}
    local scoreRevision = KWR.Util:Signature({ score.friendly or 0, score.enemy or 0 })
    if baseline.score and baseline.score ~= scoreRevision then
        return "FLAG_CAPTURED"
    end
    return nil
end

local function orbInvalidationReason(play, snapshot)
    if not play then return nil end
    local summary = orbStateSummary(snapshot)
    local playType = classifyOrbPlay(play)
    local objective = KWR.Util:Text(play.objective, "", 48)
    local objectiveRow = objective ~= "" and currentObjectiveRow(snapshot, objective) or nil
    if playType == "CARRY" and summary.friendlyCarriers <= 0 then
        return "FRIENDLY_ORB_STATE_CHANGED"
    end
    if playType == "HUNT" and summary.enemyCarriers <= 0 then
        return "ENEMY_ORB_STATE_CHANGED"
    end
    if playType == "CENTER"
        and summary.friendlyCarriers <= 0
        and summary.enemyCarriers > 0 then
        return "FRIENDLY_ORB_STATE_CHANGED"
    end
    if playType == "CENTER"
        and summary.friendlyCarriers <= 0
        and summary.enemyCarriers <= 0 then
        return "ORBS_RESET"
    end
    if playType == "PICKUP" and objectiveRow then
        local owner = KWR.Util:Text(objectiveRow.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(objectiveRow.state, "UNKNOWN", 20)
        if owner ~= "UNKNOWN" or (state ~= "AVAILABLE" and state ~= "ACTIVE") then
            return "FRIENDLY_ORB_STATE_CHANGED"
        end
    end
    return nil
end

local function cartInvalidationReason(play, snapshot)
    if not play then return nil end
    local summary = cartStateSummary(snapshot)
    local playType = classifyCartPlay(play)
    local objective = KWR.Util:Text(play.objective, "", 48)
    local objectiveRow = objective ~= "" and currentObjectiveRow(snapshot, objective) or nil
    if playType == "ESCORT" and objectiveRow then
        local owner = KWR.Util:Text(objectiveRow.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(objectiveRow.state, "UNKNOWN", 20)
        if owner ~= "FRIENDLY" and state ~= "ACTIVE" then
            return "FRIENDLY_CART_STATE_CHANGED"
        end
    end
    if playType == "DELAY" and objectiveRow then
        local owner = KWR.Util:Text(objectiveRow.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(objectiveRow.state, "UNKNOWN", 20)
        if owner ~= "ENEMY" and state ~= "ACTIVE" then
            return "ENEMY_CART_STATE_CHANGED"
        end
    end
    if objective ~= "" and objective ~= "Enemy Cart" and objective ~= "Crystal" then
        local owner, state = currentObjectiveOwner(snapshot, objective)
        if owner ~= "FRIENDLY" and state ~= "ACTIVE" and summary.vehicles <= 0 then
            return "FRIENDLY_CART_STATE_CHANGED"
        end
    end
    if playType == "ESCORT"
        and summary.friendlyControlled <= 0
        and summary.activeRows <= 0 then
        return "FRIENDLY_CART_STATE_CHANGED"
    end
    if playType == "DELAY"
        and summary.enemyControlled <= 0
        and summary.activeRows <= 0 then
        return "ENEMY_CART_STATE_CHANGED"
    end
    if playType == "CRYSTAL" and summary.crystalSeen ~= true then
        return "CRYSTAL_STATE_CHANGED"
    end
    return nil
end

local function resourceInvalidationReason(play, snapshot)
    if not play then return nil end
    local summary = resourceStateSummary(snapshot)
    local playType = classifyResourcePlay(play)
    local objective = KWR.Util:Text(play.objective, "", 48)
    local objectiveRow = objective ~= "" and currentObjectiveRow(snapshot, objective) or nil
    if playType == "ACTIVE" and objectiveRow then
        local owner = KWR.Util:Text(objectiveRow.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(objectiveRow.state, "UNKNOWN", 20)
        if owner ~= "FRIENDLY" and state ~= "ACTIVE" and state ~= "CONTROLLED" then
            return "ACTIVE_NODE_STATE_CHANGED"
        end
    end
    if playType == "SPAWN" and objectiveRow then
        local owner = KWR.Util:Text(objectiveRow.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(objectiveRow.state, "UNKNOWN", 20)
        if owner ~= "UNKNOWN" or (state ~= "ACTIVE" and state ~= "AVAILABLE") then
            return "NEXT_SPAWN_STATE_CHANGED"
        end
    end
    if playType == "ACTIVE"
        and summary.activeNodes <= 0
        and summary.friendlyControlled <= 0 then
        return "ACTIVE_NODE_STATE_CHANGED"
    end
    if playType == "SPAWN" and summary.nextSpawnSeen ~= true then
        return "NEXT_SPAWN_STATE_CHANGED"
    end
    return nil
end

local function switchCost(snapshot, currentPlay, nextPlay, trend, now)
    if not currentPlay or not currentPlay.id then
        return {
            total = 0,
            components = {},
        }
    end
    local definition = snapshot.context and snapshot.context.mapKey
        and KWR.Maps:Get(snapshot.context.mapKey) or nil
    local components = {}
    local function add(label, value)
        if value and value > 0 then
            components[#components + 1] = { label = label, value = value }
        end
    end
    local movers = #(currentPlay.movers or {})
    add("response", 4)
    add("group", math.min(8, math.max(2, movers * 2)))
    add("travel", currentPlay.phase == "MOVING" and 6 or 0)
    add("commitment", (currentPlay.phase == "COMMITTED" or currentPlay.phase == "RESOLVING") and 10 or 0)
    add("objective_progress", currentPlay.expectedResolutionAt and now
        and currentPlay.expectedResolutionAt > now and 4 or 0)
    add("contradiction", currentPlay.objective ~= nextPlay.objective and 3 or 0)
    if currentPlay.family == "NODE" or currentPlay.family == "HYBRID" then
        local policy = nodeFamilyPolicy(definition, snapshot, currentPlay, nextPlay)
        add("node_travel", policy.travelPenalty)
        add("node_defense", policy.defensePenalty)
        add("node_structure", policy.structurePenalty)
        add("node_anchor", policy.centerAnchorPenalty)
    elseif currentPlay.family == "FLAG" then
        local policy = flagFamilyPolicy(definition, snapshot, currentPlay, nextPlay)
        add("flag_structure", policy.structurePenalty)
        add("flag_carry", policy.carryPenalty)
        add("flag_reset", policy.resetPenalty)
        add("flag_route", policy.routePenalty)
    elseif currentPlay.family == "ORB" then
        local policy = orbFamilyPolicy(snapshot, currentPlay, nextPlay)
        add("orb_carry", policy.carryPenalty)
        add("orb_center", policy.centerPenalty)
        add("orb_hunt", policy.huntPenalty)
    elseif currentPlay.family == "CART" then
        local policy = cartFamilyPolicy(snapshot, currentPlay, nextPlay)
        add("cart_escort", policy.escortPenalty)
        add("cart_delay", policy.delayPenalty)
        add("cart_crystal", policy.crystalPenalty)
        add("cart_lane", policy.lanePenalty)
        add("cart_crystal_opportunity", policy.crystalOpportunityPenalty)
    elseif currentPlay.family == "RESOURCE" then
        local policy = resourceFamilyPolicy(snapshot, currentPlay, nextPlay)
        add("resource_active", policy.activePenalty)
        add("resource_spawn", policy.spawnPenalty)
        add("resource_spawn_opportunity", policy.spawnOpportunityPenalty)
    end
    local total = 0
    for _, component in ipairs(components) do
        total = total + (component.value or 0)
    end
    return {
        total = total,
        components = components,
        trend = trendSummary(trend),
    }
end

local function explicitSwitchMargin(snapshot, currentPlay, nextPlay)
    local margin = switchMargin(currentPlay, nextPlay)
    if currentPlay and (currentPlay.family == "NODE" or currentPlay.family == "HYBRID") then
        local definition = snapshot.context and snapshot.context.mapKey
            and KWR.Maps:Get(snapshot.context.mapKey) or nil
        margin = margin + (nodeFamilyPolicy(definition, snapshot, currentPlay, nextPlay).switchMarginBonus or 0)
    elseif currentPlay and currentPlay.family == "FLAG" then
        local definition = snapshot.context and snapshot.context.mapKey
            and KWR.Maps:Get(snapshot.context.mapKey) or nil
        margin = margin + (flagFamilyPolicy(definition, snapshot, currentPlay, nextPlay).switchMarginBonus or 0)
    elseif currentPlay and currentPlay.family == "ORB" then
        margin = margin + (orbFamilyPolicy(snapshot, currentPlay, nextPlay).switchMarginBonus or 0)
    elseif currentPlay and currentPlay.family == "CART" then
        margin = margin + (cartFamilyPolicy(snapshot, currentPlay, nextPlay).switchMarginBonus or 0)
    elseif currentPlay and currentPlay.family == "RESOURCE" then
        margin = margin + (resourceFamilyPolicy(snapshot, currentPlay, nextPlay).switchMarginBonus or 0)
    end
    return margin
end

local function currentRemainingValue(play, now)
    if not play or not play.id then return 0 end
    local remaining = play.remainingValue or 0
    local elapsed = math.max(0, (now or 0) - (play.issuedAt or 0))
    remaining = math.max(0, remaining - elapsed * 1.5)
    if play.phase == "MOVING" then remaining = remaining + 4 end
    if play.phase == "COMMITTED" then remaining = remaining + 8 end
    if play.phase == "RESOLVING" then remaining = remaining + 10 end
    if play.phase == "SUCCEEDED" then remaining = 0 end
    if play.phase == "FAILED" or play.phase == "EXPIRED" then remaining = 0 end
    return remaining
end

local function invalidationReason(play, snapshot, now)
    if not play or not play.id then return "NO_ACTIVE_PLAY" end
    if snapshot.context and snapshot.context.matchComplete then
        return "MATCH_COMPLETE"
    end
    if play.family ~= (snapshot.context and snapshot.context.kind or "WORLD") then
        return "MAP_FAMILY_CHANGED"
    end
    if play.phase == "SUCCEEDED" then
        return "PLAY_SUCCEEDED"
    end
    if play.phase == "FAILED" or play.phase == "EXPIRED" then
        return "PLAY_EXPIRED"
    end
    local definition = snapshot.context and snapshot.context.mapKey
        and KWR.Maps:Get(snapshot.context.mapKey) or nil
    if play.family == "NODE" or play.family == "HYBRID" then
        local nodeReason = nodeInvalidationReason(definition, play, snapshot, now)
        if nodeReason then return nodeReason end
    elseif play.family == "FLAG" then
        local flagReason = flagInvalidationReason(definition, play, snapshot)
        if flagReason then return flagReason end
    elseif play.family == "ORB" then
        local orbReason = orbInvalidationReason(play, snapshot)
        if orbReason then return orbReason end
    elseif play.family == "CART" then
        local cartReason = cartInvalidationReason(play, snapshot)
        if cartReason then return cartReason end
    elseif play.family == "RESOURCE" then
        local resourceReason = resourceInvalidationReason(play, snapshot)
        if resourceReason then return resourceReason end
    end
    if isResolutionPlay(play)
        and play.hardDeadlineAt and play.hardDeadlineAt > 0 and now >= play.hardDeadlineAt then
        return "HARD_DEADLINE_PASSED"
    end
    return nil
end

local function invalidationFamily(code, play)
    if not code then return "NONE" end
    if code == "MATCH_COMPLETE" or code == "MAP_FAMILY_CHANGED"
        or code == "PLAY_SUCCEEDED" or code == "PLAY_EXPIRED"
        or code == "HARD_DEADLINE_PASSED" then
        return "SHARED"
    end
    local family = KWR.Util:Text(play and play.family, "WORLD", 16)
    if family == "HYBRID" then
        return "NODE"
    end
    return family
end

local function decisionGateClass(invalidation, replacementReason, retained, replacementAllowed)
    if invalidation then
        return "INVALIDATION"
    end
    if retained == true and replacementReason == "INSUFFICIENT_PERSISTENCE" then
        return "PERSISTENCE_HOLD"
    end
    if retained == true and replacementReason == "NOT_MATERIALLY_SUPERIOR" then
        return "SUPERIORITY_HOLD"
    end
    if replacementAllowed == true then
        return "REPLACEMENT"
    end
    if retained == true then
        return "ACTIVE_HOLD"
    end
    return "STEADY"
end

local function overrideEvidence(snapshot, prediction, command, invalidation, replacementReason)
    local evidence = {}
    if invalidation then evidence[#evidence + 1] = "invalidation:" .. invalidation end
    if replacementReason then evidence[#evidence + 1] = "replacement:" .. replacementReason end
    if command and command.reassessment then evidence[#evidence + 1] = "manual_reassessment" end
    if command and command.responsePackage and command.responsePackage.qualified then
        evidence[#evidence + 1] = "qualified_response_package"
    end
    if (prediction and prediction.urgency or 0) >= 95 then
        evidence[#evidence + 1] = "emergency_urgency"
    end
    if snapshot and snapshot.strategy and snapshot.strategy.trust
        and snapshot.strategy.trust.reason then
        evidence[#evidence + 1] = KWR.Util:Text(snapshot.strategy.trust.reason, "", 80)
    end
    return evidence
end

local function replacementAllowed(snapshot, currentPlay, nextPlay, trend, prediction, command)
    if not nextPlay or not nextPlay.id then
        return false, "NO_CANDIDATE"
    end
    if not currentPlay or not currentPlay.id then
        return true, "NO_ACTIVE_PLAY"
    end
    if currentPlay.id == nextPlay.id then
        return true, "SAME_PLAY"
    end
    if command.reassessment then
        return true, "REASSESSMENT"
    end
    if qualifiedResponseRequiresReplacement(command.responsePackage) then
        return true, "RESPONSE_PACKAGE"
    end
    if (prediction.urgency or 0) >= 95 then
        return true, "EMERGENCY_URGENCY"
    end
    local currentValue = currentRemainingValue(currentPlay, nextPlay.issuedAt or 0)
    local margin = explicitSwitchMargin(snapshot, currentPlay, nextPlay)
    local cost = switchCost(snapshot, currentPlay, nextPlay, trend, nextPlay.issuedAt or 0)
    local adjustedAlternative = math.max(0,
        (nextPlay.remainingValue or 0) - (cost.total or 0))
    local scorePayload = {
        currentValue = currentValue,
        adjustedAlternative = adjustedAlternative,
        margin = margin,
        switchCost = cost,
    }
    local requiredDuration = requiredPersistenceSeconds(currentPlay, nextPlay)
    local duration = trend and math.max(0, (trend.lastPreferredAt or 0)
        - (trend.firstPreferredAt or 0)) or 0
    scorePayload.requiredDuration = requiredDuration
    scorePayload.observedDuration = duration
    if duration < requiredDuration then
        return false, "INSUFFICIENT_PERSISTENCE", scorePayload
    end
    if adjustedAlternative < (currentValue + margin) then
        return false, "NOT_MATERIALLY_SUPERIOR", scorePayload
    end
    return true, "SUPERIORITY_MET", scorePayload
end

local function finalMatchStatus(snapshot)
    if not (snapshot and snapshot.context and snapshot.context.matchComplete) then
        return nil
    end
    local score = snapshot.score or {}
    local friendly = KWR.Util:Number(score.friendly, nil)
    local enemy = KWR.Util:Number(score.enemy, nil)
    if friendly == nil or enemy == nil then return "COMPLETE" end
    if friendly > enemy then return "VICTORY" end
    if friendly < enemy then return "DEFEAT" end
    return "DRAW"
end

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
    local assaultLocation, assaultNames
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
                assaultNames = assaultNames or {}
                assaultNames[#assaultNames + 1] = assignment.shortName
            end
        end
    end
    if not assaultLocation or not assaultNames or #assaultNames == 0 then return nil end
    local assault = table.concat(assaultNames, ", ")
    local hold = {}
    for index = 1, #defenders do hold[#hold + 1] = defenders[index] end
    return "TAKE " .. KWR.Maps:AbbreviateLocation(mapKey, assaultLocation) .. ": " .. assault
        .. (#hold > 0 and (". HOLD " .. table.concat(hold, "; ")) or "")
end

function Commander:Compose(snapshot, prediction, assignments)
    snapshot = type(snapshot) == "table" and snapshot or {}
    snapshot.context = type(snapshot.context) == "table" and snapshot.context or {}
    prediction = type(prediction) == "table" and prediction or {}
    assignments = type(assignments) == "table" and assignments or {}

    local mapKey = snapshot.context.mapKey
    local previousState = KWR.Store and KWR.Store:Get() or {}
    local previousPlay = previousState and previousState.activePlay or self.lastActivePlay
    local score = type(snapshot.score) == "table" and snapshot.score or {}
    local definition = mapKey and KWR.Maps:Get(mapKey) or nil
    local formation = snapshot.formation or {}
    local status = not snapshot.context.inPvP and "FORMING" or (prediction.status or "WAITING")
    local finalStatus = finalMatchStatus(snapshot)
    if finalStatus then status = finalStatus end
    local doctrine = KWR.Doctrine:Get(mapKey)
    local doctrineRecommendation = KWR.Doctrine:Recommend(mapKey, status, prediction.urgency)
    local strategy = snapshot.strategy or {}
    local response = snapshot.responsePackage or {}
    local trust = strategy.trust or {}
    local knowledge = snapshot.knowledgeStatus or strategy.knowledge or {}
    local action = not snapshot.context.inPvP and formation.action
        or strategy.action or prediction.action or doctrineRecommendation
    if snapshot.context.inPvP then action = addPriorityTarget(action, definition, prediction) end
    if snapshot.context.inPvP and (prediction.status == "LOSE" or strategy.state == "RECOVERY")
        and (snapshot.context.kind == "NODE" or snapshot.context.kind == "HYBRID") then
        action = nodeRecoveryCall(assignments, mapKey) or action
    end
    if (prediction.urgency or 0) >= 90 and not strategy.action then
        action = prediction.emergency or doctrineRecommendation
        if snapshot.context.inPvP then
            action = addPriorityTarget(action, definition, prediction)
        end
    end
    if snapshot.context.inPvP and response.qualified then
        action = response.action
        action = addPriorityTarget(action, definition, prediction)
    end
    if finalStatus then
        action = finalStatus == "VICTORY" and "Match won. Battlefield objective succeeded."
            or (finalStatus == "DEFEAT" and "Match lost. Capture the AAR and review the failed swing.")
            or "Match complete. Capture the AAR and review the final state."
    end
    local integrity = snapshot.assignmentIntegrity or {}
    local urgentReassignment = integrity.reassignments and integrity.reassignments[1]
    local recovery = response.recovery or {}
    if not finalStatus and snapshot.context.inPvP and urgentReassignment then
        local replacement = urgentReassignment.replacement or "nearest floater"
        action = "COVER " .. urgentReassignment.expected .. ": " .. replacement
            .. ". " .. action
    end
    if not finalStatus and snapshot.context.inPvP and recovery.criticalGap and recovery.releaseTarget then
        action = "SEND RELIEF TO " .. KWR.Maps:AbbreviateLocation(mapKey, recovery.criticalGap)
            .. "; PEEL EXCESS FROM "
            .. KWR.Maps:AbbreviateLocation(mapKey, recovery.releaseTarget)
            .. ". " .. action
    end
    action = KWR.Util:Text(action, "Play objective.", 180)

    local who = KWR.Assignments:SelectForCommand(assignments, prediction)
    if not finalStatus and snapshot.context.inPvP and response.qualified then
        who = response.moverText or who
    end
    if not finalStatus and urgentReassignment and urgentReassignment.replacement then
        who = urgentReassignment.replacement
    end
    if not snapshot.context.inPvP then
        if formation.recommendations and formation.recommendations[1] then
            local names = {}
            for index = 1, math.min(3, #formation.recommendations) do
                names[#names + 1] = formation.recommendations[index].label
            end
            who = "Recruit " .. table.concat(names, " / ")
        else
            who = "Full team"
        end
    end
    if not finalStatus and snapshot.reassessment then
        local changed = {}
        for index = 1, #(snapshot.reassessment.changes or {}) do
            changed[#changed + 1] =
                snapshot.reassessment.changes[index].name
        end
        if #changed > 0 then who = table.concat(changed, ", ") end
    end
    if finalStatus then who = "Review / AAR" end
    action = KWR.Util:Text(action, "Play objective.", 220)
    local stabilizationSignature = KWR.Util:Signature({
        mapKey,
        status,
        action,
        who,
        response.qualified and "RESPONSE" or "STANDARD",
        snapshot.reassessment and "REASSESS" or "STEADY",
    })
    local stabilized = false
    local candidateAction = action
    local candidateWho = who
    if snapshot.context.inPvP and not snapshot.reassessment
        and self.lastCommand
        and self.lastCommand.mapKey == mapKey
        and self.lastCommand.status == status
        and (KWR.Util:Now() - (self.lastCommand.decisionAt or 0)) < 2.5
        and math.abs((prediction.urgency or 0) - (self.lastCommand.urgency or 0)) < 20
        and self.lastCommand.stabilizationSignature == stabilizationSignature then
        action = self.lastCommand.action
        who = self.lastCommand.who
        stabilized = true
    end
    local when
    if not snapshot.context.inPvP then
        when = "BEFORE QUEUE"
    elseif finalStatus then
        when = "MATCH END"
    elseif prediction.captureDeadline then
        when = "BY " .. KWR.Util:Clock(prediction.captureDeadline)
    elseif status == "WIN" and prediction.timeToWin then
        when = "HOLD " .. KWR.Util:Clock(prediction.timeToWin)
    elseif (prediction.urgency or 0) >= 70 then
        when = "NOW"
    else
        when = "NEXT FIGHT"
    end

    local movementReason = prediction.movementEvidence and prediction.movementEvidence ~= ""
        and (" FIELD: " .. prediction.movementEvidence) or ""
    local branchChoice = strategy.comparisonChoice
        and KWR.Util:Text(strategy.comparisonChoice, "", 84) or nil
    local safeCounter = strategy.safeCounterAction
        and KWR.Util:Text(strategy.safeCounterAction, "", 96) or nil
    local reason = KWR.Util:Text(
        (not snapshot.context.inPvP and (formation.reason or "Build the command unit.")
            or (prediction.condition or "Waiting for live battleground data."))
            .. (strategy.reason and (" PLAN: " .. strategy.reason) or "")
            .. (branchChoice and (" BRANCH: " .. branchChoice) or "")
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
        urgency = finalStatus and 0 or (prediction.urgency or 0),
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
            responseBypass = qualifiedResponseRequiresReplacement(response),
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
    local publishedCreatedAt = previousCommand
        and previousCommand.signature == publishedSignature
        and previousCommand.createdAt or command.createdAt
    command.createdAt = publishedCreatedAt
    self.lastCommand = {
        mapKey = snapshot.context.mapKey,
        status = status,
        urgency = command.urgency,
        action = command.action,
        who = command.who,
        signature = publishedSignature,
        createdAt = publishedCreatedAt,
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
