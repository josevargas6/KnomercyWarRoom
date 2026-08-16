local _, KWR = ...

local EnemyResponsePlanner = {}
KWR.EnemyResponsePlanner = EnemyResponsePlanner

local function text(value, fallback, limit)
    return KWR.Util:Text(value, fallback or "", limit or 120)
end

local function upper(value, fallback, limit)
    return KWR.Util:Upper(value, fallback or "", limit or 32)
end

local function number(value, fallback)
    return KWR.Util:Number(value, fallback)
end

local function phase(snapshot)
    return upper(snapshot and snapshot.context and snapshot.context.phase, "UNKNOWN", 24)
end

local function objectivePressure(snapshot)
    local reporter = snapshot.reporter or {}
    local hotspot = reporter.hotspot or {}
    local risk = number(reporter.risk, 0) or 0
    return {
        hotspot = upper(hotspot.label or hotspot.key, "FIELD", 24),
        owner = upper(hotspot.owner, "UNKNOWN", 16),
        risk = risk,
        enemyIntent = upper(reporter.enemyIntent and reporter.enemyIntent.target, "", 24),
    }
end

local function baselineResponse(candidate, target)
    target = text(target, "the scoring objective", 48)
    if candidate.id == "HOLD" then
        return {
            id = "HOLD_SECOND_LANE_PRESSURE",
            enemyPattern = "Enemy tests a second lane while the team holds " .. target .. ".",
            danger = 11,
            trigger = "the reserve stays static after enemy movement leaves the held lane",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "WINDOW",
            responsePressure = "MEDIUM",
            attributionHint = "PRESSURE_SPLIT",
        }
    end
    if candidate.id == "ROTATE" then
        return {
            id = "ROTATION_MIRROR",
            enemyPattern = "Enemy mirrors the route to " .. target .. " and tests the arrival edge.",
            danger = 12,
            trigger = "enemy movement matches the rotation before local parity improves",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "FAST",
            responsePressure = "MEDIUM",
            attributionHint = "ENEMY_COUNTER_WINDOW",
        }
    end
    if candidate.id == "TRADE" then
        return {
            id = "COUNTER_TRADE_RACE",
            enemyPattern = "Enemy races the opposite score event while the team commits to " .. target .. ".",
            danger = 14,
            trigger = "the enemy conversion resolves before the called trade",
            scoreFloorRisk = "HIGH",
            punishWindow = "FAST",
            responsePressure = "MEDIUM",
            attributionHint = "WINDOW_CONVERSION",
        }
    end
    if candidate.id == "TEAMFIGHT" then
        return {
            id = "TEAMFIGHT_REINFORCE",
            enemyPattern = "Enemy reinforces " .. target .. " and peels the first kill window.",
            danger = 13,
            trigger = "enemy support connects before crowd control converts objective value",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "FAST",
            responsePressure = "HIGH",
            attributionHint = "CONTESTED_LINE",
        }
    end
    return {
        id = "SPLIT_COLLAPSE_PUNISH",
        enemyPattern = "Enemy identifies and collapses the weaker pressure lane near " .. target .. ".",
        danger = 16,
        trigger = "the split loses healer, defender, or arrival-time connection",
        scoreFloorRisk = "MEDIUM",
        punishWindow = "FAST",
        responsePressure = "HIGH",
        attributionHint = "EXECUTION_BREAK",
    }
end

local function classifyEnemyResponse(snapshot, prediction, candidate, context)
    local pressure = objectivePressure(snapshot)
    local flags = context.doctrineFlags or {}
    local target = candidate.target or "objective"
    local mapKind = snapshot.context and snapshot.context.kind or "NODE"
    local currentStatus = upper(context.currentStatus, "TIE", 16)
    local budget = context.budget or {}
    local targetUpper = upper(target, "OBJECTIVE", 32)

    if candidate.id == "TEAMFIGHT" and pressure.owner == "UNKNOWN" then
        return {
            id = "DECORATIVE_FIGHT_TRAP",
            enemyPattern = "Enemy wants a full fight away from real score value.",
            danger = 20,
            trigger = "fight loses direct score value",
            scoreFloorRisk = "HIGH",
            punishWindow = "IMMEDIATE",
            responsePressure = "HIGH",
            attributionHint = "LOW_TRUTH_STATE",
        }
    end
    if currentStatus == "WIN" and candidate.id ~= "HOLD"
        and (flags.enemyOvercommit or pressure.risk >= 70) then
        return {
            id = "SCORE_FLOOR_BREAK",
            enemyPattern = "Enemy wants your push to break the line that is already winning.",
            danger = 22,
            trigger = "the current score floor is left before the next swing resolves",
            scoreFloorRisk = "HIGH",
            punishWindow = "IMMEDIATE",
            responsePressure = "HIGH",
            attributionHint = "SCORE_FLOOR_BREAK",
        }
    end
    if candidate.id == "SPLIT" and flags.friendlyWaveSplit then
        return {
            id = "SPLIT_COLLAPSE_PUNISH",
            enemyPattern = "Enemy collapses the weaker half of a split call first.",
            danger = 18,
            trigger = "friendly support lines disconnect",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "FAST",
            responsePressure = "HIGH",
            attributionHint = "EXECUTION_BREAK",
        }
    end
    if candidate.id == "ROTATE"
        and (pressure.enemyIntent == targetUpper or pressure.hotspot == targetUpper) then
        return {
            id = "LATE_ROTATION_PUNISH",
            enemyPattern = "Enemy commits first and punishes the late arrival route.",
            danger = 16,
            trigger = "enemy reaches the target first",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "FAST",
            responsePressure = "HIGH",
            attributionHint = "ENEMY_COUNTER_WINDOW",
        }
    end
    if candidate.id == "TRADE" and flags.enemyOvercommit then
        return {
            id = "COUNTER_TRADE_RACE",
            enemyPattern = "Enemy races the opposite score event and dares a low-value trade.",
            danger = 14,
            trigger = "protected score floor is weaker than the traded lane",
            scoreFloorRisk = "HIGH",
            punishWindow = "FAST",
            responsePressure = "MEDIUM",
            attributionHint = "WINDOW_CONVERSION",
        }
    end
    if mapKind == "FLAG" and (candidate.id == "TEAMFIGHT" or candidate.id == "TRADE") then
        return {
            id = "CARRIER_ROUTE_SWAP",
            enemyPattern = "Enemy changes carrier route and buys time with escort reset.",
            danger = 18,
            trigger = "carrier peel or route denial breaks first",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "FAST",
            responsePressure = "HIGH",
            attributionHint = "ENEMY_COUNTER_WINDOW",
        }
    end
    if mapKind == "FLAG" and candidate.id == "ROTATE" then
        return {
            id = "FLAG_OVERCHASE_PUNISH",
            enemyPattern = "Enemy wins time while the return route over-chases the wrong side.",
            danger = 17,
            trigger = "the escort route loses sight of the score event",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "FAST",
            responsePressure = "MEDIUM",
            attributionHint = "ROUTE_MISREAD",
        }
    end
    if (mapKind == "RESOURCE" or mapKind == "CART")
        and candidate.id ~= "HOLD" and phase(snapshot) ~= "OPENING" then
        return {
            id = "SPAWN_VALUE_RACE",
            enemyPattern = "Enemy spends your movement on the wrong lane while the next value window opens elsewhere.",
            danger = 15,
            trigger = "next active objective resolves before your route cashes in",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "WINDOW",
            responsePressure = "MEDIUM",
            attributionHint = "WINDOW_CONVERSION",
        }
    end
    if candidate.id == "HOLD" and (pressure.risk or 0) >= 70 then
        return {
            id = "MULTI_POINT_PRESSURE",
            enemyPattern = "Enemy threatens a second score lane while the hold remains static.",
            danger = 12,
            trigger = "reserve never leaves the current shell",
            scoreFloorRisk = "MEDIUM",
            punishWindow = "WINDOW",
            responsePressure = "MEDIUM",
            attributionHint = "PRESSURE_SPLIT",
        }
    end
    if budget.score and budget.score < 50 and candidate.reversible ~= true then
        return {
            id = "TRUTH_BAIT_OVERCOMMIT",
            enemyPattern = "Enemy benefits if the team commits hard from thin live truth.",
            danger = 19,
            trigger = "the push locks before score and movement truth settle",
            scoreFloorRisk = "HIGH",
            punishWindow = "IMMEDIATE",
            responsePressure = "HIGH",
            attributionHint = "LOW_TRUTH_STATE",
        }
    end
    return baselineResponse(candidate, target)
end

local function chooseSafestReply(enemyResponse, context)
    local contract = context.responseContract or {}
    local expert = context.expertReview or {}
    local doctrineResponse = context.doctrineResponse or {}
    local fallback = contract.safeFallbackAction
        or expert.consensusFallbackAction
        or "CALL:HOLD"
    local preferred = doctrineResponse.safestCounter
        or expert.safestCounter
        or fallback

    if enemyResponse.id == "DECORATIVE_FIGHT_TRAP" then
        return "Leave the decorative fight and protect the scoring objective."
    end
    if enemyResponse.id == "SPLIT_COLLAPSE_PUNISH" then
        return "Reconnect support lines and collapse the safer half first."
    end
    if enemyResponse.id == "LATE_ROTATION_PUNISH" then
        return "Abort the late route and replant the current score floor."
    end
    if enemyResponse.id == "COUNTER_TRADE_RACE" then
        return "Take only the trade that still protects the score floor."
    end
    if enemyResponse.id == "CARRIER_ROUTE_SWAP" then
        return "Protect route denial and peel before re-committing the return."
    end
    if enemyResponse.id == "SCORE_FLOOR_BREAK" then
        return "Re-plant the score floor before chasing extra value."
    end
    if enemyResponse.id == "TRUTH_BAIT_OVERCOMMIT" then
        return "Wait for one more clean read before the hard send."
    end
    if enemyResponse.id == "FLAG_OVERCHASE_PUNISH" then
        return "Keep the return line tight and deny the free route swap."
    end
    if enemyResponse.id == "SPAWN_VALUE_RACE" then
        return "Protect the live objective and move only when the next value window is ours."
    end
    if enemyResponse.id == "HOLD_SECOND_LANE_PRESSURE" then
        return "Keep minimum control at the held lane and pivot the reserve toward confirmed pressure."
    end
    if enemyResponse.id == "ROTATION_MIRROR" then
        return "Take the route only with the arrival edge; otherwise replant the vacated score floor."
    end
    if enemyResponse.id == "TEAMFIGHT_REINFORCE" then
        return "Control the incoming support wave, preserve healer connection, and convert the first clean window."
    end
    return preferred
end

local function consequenceAdjustment(prediction, candidate, context, enemyResponse)
    local flags = context.doctrineFlags or {}
    local opportunity = context.opportunity or {}
    local contract = context.responseContract or {}
    local expert = context.expertReview or {}
    local calibration = context.scenarioCalibration or {}
    local adversarial = context.adversarialCalibration or {}
    local budget = context.budget or {}
    local delta = 0
    local reasons = {}

    if candidate.id == "HOLD" and prediction.status == "WIN" then
        delta = delta + 8
        reasons[#reasons + 1] = "hold preserves the current winning path"
    end
    if enemyResponse.id == "SCORE_FLOOR_BREAK" then
        delta = delta - 16
        reasons[#reasons + 1] = "the move breaks a winning score floor"
    end
    if enemyResponse.id == "TRUTH_BAIT_OVERCOMMIT" then
        delta = delta - 14
        reasons[#reasons + 1] = "thin truth does not justify a hard send"
    end
    if candidate.id == "TEAMFIGHT" and enemyResponse.id == "DECORATIVE_FIGHT_TRAP" then
        delta = delta - 16
        reasons[#reasons + 1] = "fight can be decorative instead of scoring"
    end
    if candidate.id == "SPLIT" and flags.friendlyWaveSplit then
        delta = delta - 14
        reasons[#reasons + 1] = "split pressure is punishable through disconnected support"
    end
    if candidate.id == "ROTATE" and enemyResponse.id == "LATE_ROTATION_PUNISH" then
        delta = delta - 12
        reasons[#reasons + 1] = "rotation loses value if enemy arrives first"
    end
    if candidate.id == "TRADE" and enemyResponse.id == "COUNTER_TRADE_RACE" then
        if flags.projectedLoss then
            delta = delta + 6
            reasons[#reasons + 1] = "desperation trade is more playable from a losing state"
        else
            delta = delta - 10
            reasons[#reasons + 1] = "trade risks the score floor from a stable state"
        end
    end
    if candidate.id == "TEAMFIGHT" and opportunity.open then
        delta = delta + 8
        reasons[#reasons + 1] = "live opportunity keeps the fight actionable"
    end
    if budget.score and budget.score < 55 and candidate.reversible ~= true then
        delta = delta - 8
        reasons[#reasons + 1] = "hard commit is downgraded by weak evidence"
    end
    if candidate.reversible == true and budget.score and budget.score < 55 then
        delta = delta + 4
        reasons[#reasons + 1] = "reversible movement stays playable under weaker truth"
    end
    if (expert.reviewConfidence == "HIGH"
        and expert.consensusPrimaryAction == ("PLAN:" .. candidate.id)) then
        delta = delta + 6
        reasons[#reasons + 1] = "expert review supports the candidate shape"
    end
    if expert.topLossClassification == "EXECUTION_ERROR"
        and enemyResponse.responsePressure == "HIGH"
        and candidate.id == "SPLIT" then
        delta = delta - 6
        reasons[#reasons + 1] = "reviewed history says this branch breaks when execution pressure spikes"
    end
    if calibration.reviewedCases and calibration.reviewedCases >= 5
        and calibration.winRate and calibration.winRate >= 70
        and expert.consensusPrimaryAction == ("PLAN:" .. candidate.id) then
        delta = delta + 4
        reasons[#reasons + 1] = "reviewed map history supports repeating the line"
    end
    if adversarial.truthRisk == "HIGH" and budget.score and budget.score < 60
        and candidate.reversible ~= true then
        delta = delta - 6
        reasons[#reasons + 1] = "adversarial review says weak truth should not force commitment"
    end
    if contract.forbiddenCommit == "CALL:FULL_COMMIT"
        and candidate.id == "TEAMFIGHT"
        and budget.score and budget.score < 55 then
        delta = delta - 8
        reasons[#reasons + 1] = "adversarial discipline forbids a blind full commit"
    end

    return delta, reasons
end

function EnemyResponsePlanner:Evaluate(snapshot, prediction, candidate, context)
    context = type(context) == "table" and context or {}
    candidate = type(candidate) == "table" and candidate or {}

    local enemyResponse = classifyEnemyResponse(snapshot, prediction, candidate, context)
    local safestReply = chooseSafestReply(enemyResponse, context)
    local delta, reasons = consequenceAdjustment(prediction, candidate, context, enemyResponse)

    local confidence = math.abs(delta) >= 12 and "HIGH"
        or (math.abs(delta) >= 6 and "MEDIUM" or "LOW")

    return {
        responseID = enemyResponse.id,
        enemyPattern = enemyResponse.enemyPattern,
        trigger = enemyResponse.trigger,
        danger = enemyResponse.danger,
        safestReply = safestReply,
        scoreFloorRisk = enemyResponse.scoreFloorRisk,
        punishWindow = enemyResponse.punishWindow,
        responsePressure = enemyResponse.responsePressure,
        attributionHint = enemyResponse.attributionHint,
        consequenceAdjustment = delta,
        confidence = confidence,
        reasons = reasons,
        summary = string.format("%s | reply: %s | adjust: %d",
            enemyResponse.enemyPattern,
            safestReply,
            delta),
    }
end

KWR:RegisterModule("EnemyResponsePlanner", EnemyResponsePlanner)
