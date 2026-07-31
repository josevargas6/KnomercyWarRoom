local _, KWR = ...

local Predictor = {}
KWR.Predictor = Predictor

local INF = 999999
local LIVE_EVIDENCE_MAX_AGE = 5

local function n(value, fallback)
    return KWR.Util:Number(value, fallback) or fallback
end

local function timeToWin(maxScore, score, pointsPerTick, tickSeconds)
    maxScore = n(maxScore, 0)
    score = n(score, 0)
    pointsPerTick = n(pointsPerTick, 0)
    tickSeconds = n(tickSeconds, 1)
    if score >= maxScore and maxScore > 0 then return 0 end
    if pointsPerTick <= 0 then return INF end
    return math.ceil(math.max(maxScore - score, 0) / pointsPerTick) * tickSeconds
end

local function pointsFor(definition, objectives, isBlitz)
    local count = math.max(0, math.min(definition.maxObjectives or 0, n(objectives, 0)))
    local rates = isBlitz and definition.blitzPointsPerTick or definition.pointsPerTick
    return n(rates and rates[count], 0)
end

local function minimumObjectivesToBeat(definition, friendlyScore, enemyScore, enemyObjectives, isBlitz)
    local enemyTime = timeToWin(
        definition.maxScore,
        enemyScore,
        pointsFor(definition, enemyObjectives, isBlitz),
        definition.tickSeconds
    )
    for count = 1, definition.maxObjectives do
        local friendlyTime = timeToWin(
            definition.maxScore,
            friendlyScore,
            pointsFor(definition, count, isBlitz),
            definition.tickSeconds
        )
        if friendlyTime < enemyTime then
            return count, friendlyTime, enemyTime
        end
    end
    return definition.maxObjectives,
        timeToWin(definition.maxScore, friendlyScore,
            pointsFor(definition, definition.maxObjectives, isBlitz), definition.tickSeconds),
        enemyTime
end

local function isFresh(evidence)
    if type(evidence) ~= "table" or evidence.observedAt == nil then
        return true
    end
    local age = KWR.Util:Now() - n(evidence.observedAt, 0)
    return age >= 0 and age <= LIVE_EVIDENCE_MAX_AGE
end

local function confidence(snapshot)
    if snapshot.context.preview then return "PREVIEW" end
    local score = snapshot.score.source == "ui_widget" and isFresh(snapshot.score)
    local objectives = snapshot.objectives.source == "ui_widget" and isFresh(snapshot.objectives)
    if score and objectives then return "HIGH" end
    if score or objectives then return "MEDIUM" end
    return "LOW"
end

local function hasScore(snapshot)
    return (snapshot.score.source == "ui_widget" and isFresh(snapshot.score))
        or (snapshot.context.preview and snapshot.score.source == "preview")
end

local function hasObjectives(snapshot)
    return (snapshot.objectives.source == "ui_widget" and isFresh(snapshot.objectives))
        or (snapshot.context.preview and snapshot.objectives.source == "preview")
end

local function waiting(snapshot, message)
    return {
        status = snapshot.context.inPvP and "WAITING" or "WORLD",
        urgency = 0,
        condition = message or "Waiting for battleground data.",
        action = snapshot.context.inPvP and "Hold assignments until battlefield data arrives." or "Queue or join your team.",
        emergency = "Play the objective.",
        confidence = "NONE",
        source = "none",
        mapKey = snapshot.context.mapKey,
        kind = snapshot.context.kind,
    }
end

local function nodePrediction(snapshot, definition)
    if not hasScore(snapshot) or not hasObjectives(snapshot) then
        return waiting(snapshot, "Waiting for score and objective widgets.")
    end
    local score, objectives = snapshot.score, snapshot.objectives
    local isBlitz = snapshot.context.isBlitz == true
    local friendlyBases = n(objectives.friendly, 0)
    local enemyBases = n(objectives.enemy, 0)
    local friendlyIncoming = n(objectives.friendlyIncoming, 0)
    local enemyIncoming = n(objectives.enemyIncoming, 0)
    local friendlyTime = timeToWin(definition.maxScore, score.friendly,
        pointsFor(definition, friendlyBases, isBlitz), definition.tickSeconds)
    local enemyTime = timeToWin(definition.maxScore, score.enemy,
        pointsFor(definition, enemyBases, isBlitz), definition.tickSeconds)
    local minimum, projectedFriendly, projectedEnemy = minimumObjectivesToBeat(
        definition, score.friendly, score.enemy, enemyBases, isBlitz
    )
    local recoverable = projectedFriendly < projectedEnemy
    local status = friendlyTime < enemyTime and "WIN" or (enemyTime < friendlyTime and "LOSE" or "TIE")
    local projectedFriendlyBases = math.min(definition.maxObjectives, friendlyBases + friendlyIncoming)
    local projectedEnemyBases = math.min(definition.maxObjectives, enemyBases + enemyIncoming)
    local incomingFriendlyTime = timeToWin(definition.maxScore, score.friendly,
        pointsFor(definition, projectedFriendlyBases, isBlitz), definition.tickSeconds)
    local incomingEnemyTime = timeToWin(definition.maxScore, score.enemy,
        pointsFor(definition, projectedEnemyBases, isBlitz), definition.tickSeconds)
    local incomingStatus = incomingFriendlyTime < incomingEnemyTime and "WIN"
        or (incomingEnemyTime < incomingFriendlyTime and "LOSE" or "TIE")
    local urgency = status == "LOSE" and (score.enemyNeeded <= 250 and 95 or 78)
        or (status == "WIN" and (score.enemyNeeded <= 250 and 72 or 35) or 58)
    local needed = math.max(minimum - friendlyBases, 0)
    local captureSeconds = isBlitz and definition.blitzCaptureSeconds or definition.captureSeconds
    local captureDeadline = enemyTime < INF and math.max(0, enemyTime - (captureSeconds or 0)) or nil
    local condition
    local action

    if status == "WIN" then
        condition = "Hold " .. tostring(friendlyBases) .. " for " .. KWR.Util:Clock(friendlyTime) .. "."
        action = "Defend current control and stop the next enemy swing."
    elseif status == "LOSE" then
        if recoverable then
            condition = "Need " .. tostring(minimum) .. " objectives"
                .. (needed > 0 and (" (+" .. tostring(needed) .. ")") or "")
                .. (captureDeadline and (" within " .. KWR.Util:Clock(captureDeadline)) or "") .. "."
            action = needed > 0 and "Regroup and take one more objective now." or "Stop the incoming enemy capture."
        else
            condition = "No current objective count beats the enemy scoring clock."
            action = "Stop enemy scoring immediately, then create a full objective swing."
            urgency = 100
        end
    else
        condition = "Current scoring paths are tied."
        action = "Win the next objective cleanly and keep defenders planted."
    end
    if enemyIncoming > 0 and incomingStatus == "LOSE" and status ~= "LOSE" then
        action = "Stop the enemy incoming capture; it flips the projected clock to a loss."
        urgency = math.max(urgency, 92)
    elseif friendlyIncoming > 0 and incomingStatus == "WIN" and status ~= "WIN" then
        action = "Protect the friendly incoming capture; it creates the projected win."
        urgency = math.max(urgency, 82)
    end

    return {
        status = status,
        urgency = urgency,
        condition = condition,
        action = action,
        emergency = status == "LOSE" and "Interrupt enemy scoring immediately." or "Protect the current win path.",
        confidence = confidence(snapshot),
        source = "score+objectives",
        mapKey = definition.key,
        kind = definition.kind,
        timeToWin = math.min(friendlyTime, enemyTime) < INF and math.min(friendlyTime, enemyTime) or nil,
        friendlyTime = friendlyTime,
        enemyTime = enemyTime,
        friendlyObjectives = friendlyBases,
        enemyObjectives = enemyBases,
        friendlyIncoming = friendlyIncoming,
        enemyIncoming = enemyIncoming,
        incomingStatus = incomingStatus,
        incomingFriendlyTime = incomingFriendlyTime,
        incomingEnemyTime = incomingEnemyTime,
        neededObjectives = needed,
        minimumObjectives = minimum,
        captureDeadline = captureDeadline,
        projectedFriendlyTime = projectedFriendly,
        projectedEnemyTime = projectedEnemy,
        recoverable = recoverable,
        isBlitz = isBlitz,
    }
end

local function flagPrediction(snapshot, definition)
    if not hasScore(snapshot) then
        return waiting(snapshot, "Waiting for flag and score widgets.")
    end
    local score, objectives = snapshot.score, snapshot.objectives
    local status = score.friendly > score.enemy and "WIN" or (score.enemy > score.friendly and "LOSE" or "TIE")
    local tiedByLastCapture = score.friendly == score.enemy and score.friendly > 0
    if tiedByLastCapture and score.lastCapture == "FRIENDLY" then
        status = "WIN"
    elseif tiedByLastCapture and score.lastCapture == "ENEMY" then
        status = "LOSE"
    end
    local friendlyCarrying = n(objectives.friendlyActive, 0) > 0
    local enemyCarrying = n(objectives.enemyActive, 0) > 0
    local urgency = status == "LOSE" and 90 or ((friendlyCarrying or enemyCarrying) and 72 or 48)
    local condition
    local action
    if status == "WIN" then
        condition = "Protect the lead and secure a clean flag return."
        if friendlyCarrying and enemyCarrying then
            action = "Protect our carrier and collapse on EFC with a coordinated return team."
        elseif enemyCarrying then
            action = "Collapse on EFC while keeping enough defense to prevent the equalizer."
        elseif friendlyCarrying then
            action = "Escort our carrier and preserve the return window."
        else
            action = "Keep defense home and push only with numbers."
        end
    elseif status == "LOSE" then
        condition = "The next return-and-cap window must convert."
        action = "Group on EFC, control healers, then escort the cap."
    else
        condition = tiedByLastCapture and "Scores are tied; last-capture tiebreak is not yet observed."
            or "The first clean cap or final-cap tiebreak decides the path."
        action = "Keep peel on our carrier and coordinate one EFC collapse."
    end
    if tiedByLastCapture and status == "WIN" then
        condition = "Scores are tied; friendly team owns the observed last-capture tiebreak."
        action = enemyCarrying and "Protect the tiebreak: return our flag and deny the cap."
            or "Protect the tiebreak and avoid an unnecessary carrier trade."
    elseif tiedByLastCapture and status == "LOSE" then
        condition = "Scores are tied; enemy team owns the observed last-capture tiebreak."
        action = "The next return-and-cap must convert; a timeout is a loss."
    end
    return {
        status = status, urgency = urgency, condition = condition, action = action,
        emergency = "Kill EFC now; random mid kills do not change the win path.",
        confidence = confidence(snapshot), source = "score+flag_widget",
        mapKey = definition.key, kind = definition.kind,
        friendlyCarrying = friendlyCarrying, enemyCarrying = enemyCarrying,
        lastCapture = score.lastCapture,
        tiedByLastCapture = tiedByLastCapture,
    }
end

local function hybridPrediction(snapshot, definition)
    local prediction = nodePrediction(snapshot, definition)
    if prediction.status == "WAITING" then return prediction end
    local objectives = snapshot.objectives or {}
    local towers = n(objectives.friendly, 0)
    local enemyTowers = n(objectives.enemy, 0)
    local friendlyCarrying = n(objectives.friendlyFlagActive, 0) > 0
    local enemyCarrying = n(objectives.enemyFlagActive, 0) > 0
    local flagValues = snapshot.context.isBlitz and definition.blitzFlagValue or definition.flagValue
    local flagValue = n(flagValues and flagValues[towers], 0)
    prediction.friendlyCarrying = friendlyCarrying
    prediction.enemyCarrying = enemyCarrying
    prediction.flagValue = flagValue
    prediction.source = "score+towers+flag"
    prediction.condition = string.format(
        "Tower control %d-%d; flag value %d.", towers, enemyTowers, flagValue)
    if towers < enemyTowers then
        prediction.action = "Recover tower control before investing in a low-value flag."
        prediction.urgency = math.max(prediction.urgency or 0, 82)
    elseif friendlyCarrying and flagValue > 0 then
        prediction.action = "Protect the flag carrier and deliver only while tower value holds."
    elseif enemyCarrying then
        prediction.action = "Stop the enemy flag while preserving tower control."
    else
        prediction.action = "Stabilize towers, then secure the flag at useful value."
    end
    prediction.emergency = "Create a tower swing now; a flag without tower value cannot recover the clock."
    return prediction
end

local function orbPrediction(snapshot, definition)
    if not hasScore(snapshot) then
        return waiting(snapshot, "Waiting for orb and score widgets.")
    end
    local score, objectives = snapshot.score, snapshot.objectives
    local hasOrbState = hasObjectives(snapshot) == true
    local friendly = n(objectives.friendlyActive, 0)
    local enemy = n(objectives.enemyActive, 0)
    local status = score.friendly > score.enemy and "WIN" or (score.enemy > score.friendly and "LOSE" or "TIE")
    local urgency = hasOrbState and enemy > friendly and 86
        or (score.enemyNeeded <= 250 and 92 or (status == "LOSE" and 74 or 55))
    local action = hasOrbState and enemy > friendly
        and "Kill the highest-value enemy carrier and recover an orb."
        or (hasOrbState and friendly > enemy
            and "Protect carriers near center and prepare replacement pickups."
            or "Control center, identify visible carriers, and secure the next loose orb.")
    return {
        status = status, urgency = urgency,
        condition = hasOrbState
            and ("Orb control: " .. tostring(friendly) .. " friendly to " .. tostring(enemy) .. " enemy.")
            or "Orb ownership telemetry unavailable; using authoritative score only.",
        action = action, emergency = "Kill an enemy carrier and deny center scoring now.",
        confidence = confidence(snapshot), source = hasOrbState and "score+orb_widget" or "score_only",
        mapKey = definition.key, kind = definition.kind,
        friendlyObjectives = friendly, enemyObjectives = enemy,
        objectiveTelemetry = hasOrbState,
    }
end

local function cartPrediction(snapshot, definition)
    if not hasScore(snapshot) then
        return waiting(snapshot, "Waiting for cart and score data.")
    end
    local score, objectives = snapshot.score, snapshot.objectives
    local hasCartState = hasObjectives(snapshot) == true
    local friendly = n(objectives.friendlyActive, 0)
    local enemy = n(objectives.enemyActive, 0)
    local status = score.friendly > score.enemy and "WIN" or (score.enemy > score.friendly and "LOSE" or "TIE")
    local urgency = hasCartState and enemy > friendly and 86
        or (score.enemyNeeded <= 250 and 94 or (status == "LOSE" and 76 or 60))
    local action
    if definition.key == "DEEPHAUL" then
        action = hasCartState and enemy > friendly
            and "Turn the enemy cart while keeping our escort covered."
            or (hasCartState and friendly > enemy
                and "Stay with our cart and keep a separate delay group on theirs."
                or "Confirm both carts, escort ours, and contest Crystal only with both covered.")
    else
        action = hasCartState and enemy > friendly
            and "Delay the enemy scoring route and take the shortest recoverable cart."
            or (hasCartState and friendly > enemy
                and "Escort the scoring cart and rotate before the next spawn."
                or "Confirm active cart ownership, fight on cart, and assign one delay group.")
    end
    return {
        status = status, urgency = urgency,
        condition = hasCartState
            and ("Cart control: " .. tostring(friendly) .. " friendly to " .. tostring(enemy) .. " enemy.")
            or "Cart ownership telemetry unavailable; using authoritative score only.",
        action = action, emergency = "Stop the enemy turn-in immediately; leave dead carts.",
        confidence = confidence(snapshot), source = hasCartState and "score+cart_state" or "score_only",
        mapKey = definition.key, kind = definition.kind,
        friendlyObjectives = friendly, enemyObjectives = enemy,
        objectiveTelemetry = hasCartState,
    }
end

local function resourcePrediction(snapshot, definition)
    if not hasScore(snapshot) then
        return waiting(snapshot, "Waiting for resource score data.")
    end
    local score = snapshot.score
    local status = score.friendly > score.enemy and "WIN" or (score.enemy > score.friendly and "LOSE" or "TIE")
    local urgency = status == "LOSE" and (score.enemyNeeded <= 250 and 94 or 78) or 52
    return {
        status = status, urgency = urgency,
        condition = status == "LOSE" and "Resource deficit: the next clean spawn must convert."
            or "Resource pace: arrive before the next active spawn.",
        action = status == "LOSE" and "Group for the next node and deny a free channel."
            or "Rotate early, protect the channel, and leave exhausted nodes.",
        emergency = "Reach the next spawn now; road fights cannot recover the score.",
        confidence = confidence(snapshot), source = "score",
        mapKey = definition.key, kind = definition.kind,
    }
end

local function applyReporterEvidence(prediction, snapshot)
    local reporter = snapshot.reporter
    if type(reporter) ~= "table" then return prediction end
    prediction.reporterRisk = n(reporter.risk, 0)
    prediction.movementEvidence = KWR.Util:Text(reporter.summary, "", 160)
    prediction.hotspot = reporter.hotspot and KWR.Util:Text(reporter.hotspot.label, "", 48) or nil
    if prediction.reporterRisk >= 70 and reporter.callHint then
        prediction.urgency = math.max(n(prediction.urgency, 0), prediction.reporterRisk)
        prediction.action = KWR.Util:Text(prediction.action .. " " .. reporter.callHint, prediction.action, 180)
        prediction.source = KWR.Util:Text(prediction.source .. "+reporter", prediction.source, 48)
    end
    return prediction
end

function Predictor:Evaluate(snapshot)
    local prediction
    if not snapshot.context.inPvP then
        prediction = waiting(snapshot, "Enter a battleground to begin live command.")
        return applyReporterEvidence(prediction, snapshot)
    end
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    if not definition then
        prediction = waiting(snapshot, "This battleground does not have a verified predictor yet.")
        return applyReporterEvidence(prediction, snapshot)
    end
    if definition.kind == "NODE" then
        prediction = nodePrediction(snapshot, definition)
    elseif definition.kind == "HYBRID" then
        prediction = hybridPrediction(snapshot, definition)
    elseif definition.kind == "FLAG" then
        prediction = flagPrediction(snapshot, definition)
    elseif definition.kind == "ORB" then
        prediction = orbPrediction(snapshot, definition)
    elseif definition.kind == "CART" then
        prediction = cartPrediction(snapshot, definition)
    elseif definition.kind == "RESOURCE" then
        prediction = resourcePrediction(snapshot, definition)
    else
        prediction = waiting(snapshot)
    end
    return applyReporterEvidence(prediction, snapshot)
end

function Predictor:TimeToWin(maxScore, score, pointsPerTick, tickSeconds)
    return timeToWin(maxScore, score, pointsPerTick, tickSeconds)
end

KWR:RegisterModule("Predictor", Predictor)