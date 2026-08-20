local _, KWR = ...

local Strategist = {
    cache = nil,
    cacheHits = 0,
    cacheMisses = 0,
    executionCache = nil,
    executionCacheHits = 0,
    executionCacheMisses = 0,
}
KWR.Strategist = Strategist

local STATE_FOCUS = {
    OPENING = { mobility = 1.0, objectiveUtility = 0.9, splitPush = 0.8 },
    STABILIZE = { survivability = 1.0, nodeDefense = 0.9, peel = 0.8 },
    CONTEST = { teamfight = 1.0, pressure = 0.9, ccPotential = 0.8 },
    RECOVERY = { recovery = 1.0, burst = 0.9, killConfirm = 0.9 },
    WIN = { nodeDefense = 1.0, survivability = 0.9, manaEndurance = 0.8 },
    LOSE = { burst = 1.0, killConfirm = 0.9, splitPush = 0.8 },
    TIE = { teamfight = 1.0, objectiveUtility = 0.9, pressure = 0.8 },
    ANY = { teamfight = 1.0, objectiveUtility = 0.9, mobility = 0.8 },
}

local KIND_FOCUS = {
    NODE = { nodeDefense = 1.0, splitPush = 0.9, mobility = 0.8 },
    HYBRID = { nodeDefense = 1.0, objectiveUtility = 0.9, mobility = 0.8 },
    FLAG = { flagCarry = 1.0, peel = 0.9, killConfirm = 0.8 },
    ORB = { survivability = 1.0, recovery = 0.9, objectiveUtility = 0.8 },
    CART = { teamfight = 1.0, mobility = 0.9, objectiveUtility = 0.8 },
    RESOURCE = { mobility = 1.0, splitPush = 0.9, ccPotential = 0.8 },
}

local function planFocus(kind, planState, currentState)
    local focus = {}
    local function merge(source)
        for category, weight in pairs(source or {}) do
            focus[category] = math.max(focus[category] or 0, weight)
        end
    end
    merge(KIND_FOCUS[kind])
    merge(STATE_FOCUS[planState == "ANY" and currentState or planState])
    return focus
end

local function capabilityFit(ours, enemy, focus)
    local weighted, weightTotal, matchup = 0, 0, 0
    for category, weight in pairs(focus or {}) do
        local ourRating = ours.ratings and ours.ratings[category] or 0
        local enemyRating = enemy.ratings and enemy.ratings[category] or 0
        weighted = weighted + (math.max(0, ourRating - 1) / 4) * weight
        matchup = matchup + ((ourRating - enemyRating) / 4) * weight
        weightTotal = weightTotal + weight
    end
    if weightTotal == 0 then return 0, 0 end
    return (weighted / weightTotal) * 12, (matchup / weightTotal) * 6
end

function Strategist:FocusCategories()
    local result = {}
    for _, source in pairs({ STATE_FOCUS, KIND_FOCUS }) do
        for _, profile in pairs(source) do
            for category in pairs(profile) do result[category] = true end
        end
    end
    return result
end

local function requirementFit(summary, requirements)
    local missing = {}
    for tag, required in pairs(requirements or {}) do
        local available = summary.tags[tag] or 0
        if available < required then
            missing[#missing + 1] = tag .. " " .. tostring(available) .. "/" .. tostring(required)
        end
    end
    return #missing == 0, missing
end

local function stateFit(planState, status)
    if status == "RECOVERY" then return planState == "LOSE" or planState == "ANY" end
    if status == "STABILIZE" then return planState == "WIN" or planState == "ANY" end
    if status == "CONTEST" then return planState == "TIE" or planState == "ANY" end
    return planState == "ANY" or planState == status
end

local function hasOptions(set)
    return type(set) == "table" and next(set) ~= nil
end

local function doctrineFlags(snapshot, prediction, currentState)
    local reporter = snapshot.reporter or {}
    local coverage = reporter.coverage or {}
    local hotspot = reporter.hotspot or {}
    local integrity = snapshot.assignmentIntegrity or {}
    local resources = snapshot.combat and snapshot.combat.resourceEconomy or {}
    local unresolvedCoverage = false
    for _, row in ipairs(integrity.coverageLedger or {}) do
        if row.state == "UNCOVERED" then
            unresolvedCoverage = true
            break
        end
    end
    local objectiveContestable = #(snapshot.objectives and snapshot.objectives.timers or {}) > 0
        or #(snapshot.objectives and snapshot.objectives.carriers or {}) > 0
        or (hotspot.risk or 0) >= 35
        or ((hotspot.friendly or 0) > 0 and (hotspot.enemy or 0) > 0)
    local enemyOvercommit = (reporter.enemyIntent and (reporter.enemyIntent.groupSize or 0) >= 6)
        or (#(reporter.pressure or {}) >= 2
            and (reporter.pressure[1].enemy or 0) > 0
            and (reporter.pressure[2].enemy or 0) > 0)
    local anchorsStable = unresolvedCoverage ~= true
        and (integrity.uncovered or 0) == 0
        and (integrity.abandoned or 0) == 0
    local waveAdvantage = (resources.advantage or 0) >= 0
        or ((coverage.friendlyLocated or 0) >= (coverage.enemyLocated or 0))
    local urgency = prediction.urgency or 0
    return {
        phase = currentState,
        objectiveContestable = objectiveContestable == true,
        arrivalAfterResolution = currentState == "RECOVERY"
            and objectiveContestable ~= true and urgency >= 70,
        waveAdvantage = waveAdvantage == true,
        anchorsStable = anchorsStable == true,
        enemyOvercommit = enemyOvercommit == true,
        enemyReserveCommitted = enemyOvercommit == true,
        projectedWin = prediction.status == "WIN",
        projectedLoss = prediction.status == "LOSE",
        delayWins = prediction.status == "WIN" and urgency >= 75,
        oneScoringEventRequired = urgency >= 85,
        enemyInteractionWouldWin = prediction.status == "WIN"
            and urgency >= 80 and (hotspot.enemy or 0) > (hotspot.friendly or 0),
        onlyDefenderWouldMove = unresolvedCoverage == true,
        friendlyWaveSplit = (integrity.moving or 0) >= 2
            and (integrity.onStation or 0) < (integrity.moving or 0),
    }
end

local function doctrineSelection(snapshot, prediction, currentState, result)
    local flags = doctrineFlags(snapshot, prediction, currentState)
    local compThreat = KWR.CompThreats and KWR.CompThreats:Select(
        result.enemyComposition, result.enemyTier, snapshot.context.kind) or nil
    local defenseModel = KWR.EnemyDefenseModels and KWR.EnemyDefenseModels:Select(
        snapshot, result.enemyComposition, currentState) or nil
    local branch, branchClass
    if currentState == "OPENING" and KWR.OpenerDoctrine then
        branch = KWR.OpenerDoctrine:Select(snapshot.context.mapKey, {
            ourComposition = result.ourComposition,
            enemyComposition = result.enemyComposition,
            ourTier = result.ourTier,
            enemyTier = result.enemyTier,
            compThreat = compThreat,
            enemyDefenseModel = defenseModel,
        })
        branchClass = "OPENER"
    elseif currentState == "RECOVERY" and KWR.RecoveryDoctrine then
        branch = KWR.RecoveryDoctrine:Select(snapshot.context.mapKey, flags)
        branchClass = "RECOVERY"
    elseif (prediction.urgency or 0) >= 75 and KWR.EndgameDoctrine then
        branch = KWR.EndgameDoctrine:Select(snapshot.context.mapKey, flags)
        branchClass = "ENDGAME"
    end
    return compThreat, defenseModel, branch, branchClass, flags
end

local function applyDoctrineBranch(result, branch, branchClass)
    if not branch then return end
    result.doctrineClass = branchClass
    result.doctrineBranch = KWR.Util:Copy(branch)
    result.doctrineBranchID = branch.id
    if branchClass == "OPENER" then
        result.action = branch.action or result.action
        result.reason = "Opener doctrine: " .. KWR.Util:Text(branch.when, "", 140)
            .. ". " .. KWR.Util:Text(result.reason, "", 140)
        result.switchIf = branch.followup or result.switchIf
        result.stop = branch.antiThrow or result.stop
    elseif branchClass == "RECOVERY" then
        result.action = branch.action or result.action
        result.reason = "Recovery doctrine: " .. KWR.Util:Text(branch.when, "", 140)
            .. ". " .. KWR.Util:Text(result.reason, "", 140)
        result.switchIf = branch.abortOrSwitch or result.switchIf
        result.stop = branch.assignmentContinuity or result.stop
        result.objectiveDecision = result.objectiveDecision or {}
        result.objectiveDecision.abort = result.objectiveDecision.abort or branch.abortOrSwitch
    elseif branchClass == "ENDGAME" then
        result.action = branch.action or result.action
        result.reason = "Endgame doctrine: " .. KWR.Util:Text(branch.condition, "", 140)
            .. ". " .. KWR.Util:Text(result.reason, "", 140)
        result.switchIf = branch.fallback or result.switchIf
        result.stop = branch.antiThrow or result.stop
    end
end

local function applyDoctrineComparisonGuidance(result, comparison)
    if not comparison then return end
    result.doctrineComparison = KWR.Util:Copy(comparison)
    result.doctrineComparisonID = comparison.id
    result.comparisonChoice = comparison.optionA
    result.reason = KWR.Util:Text(result.reason, "", 220)
    if result.reason ~= "" then
        result.reason = result.reason .. " "
    end
    result.reason = result.reason .. string.format(
        "COMPARE: %s over %s when %s.",
        comparison.optionA or "option A",
        comparison.optionB or "option B",
        comparison.preferWhen or "the safer path is confirmed")
    if not result.switchIf or result.switchIf == "" then
        result.switchIf = comparison.preferWhen
    end
    if comparison.avoidWhen and comparison.avoidWhen ~= "" then
        result.stop = KWR.Util:Text(result.stop, "", 220)
        if result.stop ~= "" then
            result.stop = result.stop .. " "
        end
        result.stop = result.stop .. comparison.avoidWhen
    end
end

local function applyDoctrineResponseGuidance(result, response)
    if not response then return end
    result.enemyResponseGuidance = KWR.Util:Copy(response)
    result.enemyResponseGuidanceID = response.id
    result.safeCounterAction = response.safestCounter
    result.reason = KWR.Util:Text(result.reason, "", 220)
    if result.reason ~= "" then
        result.reason = result.reason .. " "
    end
    result.reason = result.reason .. string.format(
        "COUNTER: %s because %s.",
        response.safestCounter or "hold the safer line",
        response.because or "it preserves the score path")
    if (result.switchIf == nil or result.switchIf == "") and response.holdIf then
        result.switchIf = response.holdIf
    end
    if response.abortIf and response.abortIf ~= "" then
        result.stop = KWR.Util:Text(result.stop, "", 220)
        if result.stop ~= "" then
            result.stop = result.stop .. " "
        end
        result.stop = result.stop .. response.abortIf
    end
end

local function strategicState(snapshot, prediction)
    local score = snapshot.score or {}
    local friendly = tonumber(score.friendly) or 0
    local enemy = tonumber(score.enemy) or 0
    local elapsed = tonumber(snapshot.context and snapshot.context.elapsed) or 0
    if friendly == 0 and enemy == 0 and elapsed < 90 then
        return "OPENING"
    end
    if prediction.status == "LOSE" and (prediction.urgency or 0) >= 60 then
        return "RECOVERY"
    end
    if prediction.status == "WIN" then return "STABILIZE" end
    if prediction.status == "TIE" then return "CONTEST" end
    if prediction.status == "WAITING" then return "PRESSURE" end
    return prediction.status
end

local function mapSignal(mapKey)
    for _, signal in ipairs(KWR.SourceRegistry:Signals("REVIEWED_PRINCIPLE")) do
        for _, signalMap in ipairs(signal.maps or {}) do
            if signalMap == mapKey then return signal end
        end
    end
end

local function quickRosterSignature(roster)
    local parts = {}
    for _, player in ipairs(roster or {}) do
        parts[#parts + 1] = table.concat({
            player.guid or player.name or "?",
            player.spec or "?",
            player.role or "?",
            player.dead and "D" or "A",
            player.location or "?",
        }, ":")
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function decisionSignature(snapshot, prediction)
    local reporter = snapshot.reporter or {}
    local intent = reporter.enemyIntent or {}
    local momentum = reporter.momentum or {}
    local resources = snapshot.combat and snapshot.combat.resourceEconomy or {}
    local objectives = snapshot.objectives or {}
    local parts = {}
    local function add(value) parts[#parts + 1] = tostring(value or "") end
    add(snapshot.context.mapKey)
    add(prediction.status)
    add(math.floor((prediction.urgency or 0) / 5))
    add(snapshot.score and snapshot.score.friendly)
    add(snapshot.score and snapshot.score.enemy)
    add(objectives.source)
    add(objectives.friendly)
    add(objectives.enemy)
    add(objectives.friendlyIncoming)
    add(objectives.enemyIncoming)
    for _, row in ipairs(objectives.rows or {}) do
        local resolution = row.resolution or {}
        local ownerResolution = resolution.owner or {}
        local stateResolution = resolution.state or {}
        add(table.concat({
            row.label or "?",
            row.owner or "?",
            row.state or "?",
            ownerResolution.selectedSource or "?",
            stateResolution.selectedSource or "?",
            ownerResolution.conflict and "owner-conflict" or "owner-clean",
            stateResolution.conflict and "state-conflict" or "state-clean",
        }, ":"))
    end
    add(reporter.hotspot and reporter.hotspot.label)
    add(math.floor((reporter.risk or 0) / 5))
    add(intent.target)
    add(intent.groupSize)
    add(math.floor((momentum.value or 0) / 5))
    add(resources.advantage)
    add(reporter.matchMemory and reporter.matchMemory.revision)
    add(quickRosterSignature(snapshot.roster))
    add(quickRosterSignature(snapshot.enemies))
    return table.concat(parts, "\031")
end

local function objectiveEvidenceSummary(snapshot)
    local objectives = snapshot.objectives or {}
    local rows = objectives.rows or {}
    local conflicts, unresolved, nativeSemantics = 0, 0, 0
    for _, row in ipairs(rows) do
        local resolution = row.resolution or {}
        local stateResolution = resolution.state or {}
        local ownerResolution = resolution.owner or {}
        if stateResolution.conflict or ownerResolution.conflict then
            conflicts = conflicts + 1
        end
        if row.native and row.native.semantic and row.native.semantic ~= "UNOBSERVED" then
            nativeSemantics = nativeSemantics + 1
        end
        if row.state == "UNKNOWN" or row.owner == "UNKNOWN"
            or stateResolution.selectedSource == nil
            or ownerResolution.selectedSource == nil then
            unresolved = unresolved + 1
        end
    end
    return {
        source = objectives.source or "unknown",
        total = #rows,
        conflicts = conflicts,
        unresolved = unresolved,
        nativeSemantics = nativeSemantics,
        authoritative = objectives.source == "ui_widget" and conflicts == 0
            and unresolved == 0,
    }
end

local function confidenceBudget(snapshot, prediction, ourSummary, enemySummary)
    local evidence, score = {}, 0
    local function add(name, points, available, detail)
        evidence[#evidence + 1] = {
            name = name,
            points = available and points or 0,
            available = available == true,
            detail = detail,
        }
        if available then score = score + points end
    end
    local reporter = snapshot.reporter or {}
    local coverage = reporter.coverage or {}
    local reporterTrust = reporter.trust or {}
    local knowledge = snapshot.knowledgeStatus or {}
    local opponentModels = snapshot.opponentModels and snapshot.opponentModels.summary or {}
    local combat = snapshot.combat or {}
    local resources = combat.resourceEconomy or {}
    local objectiveEvidence = objectiveEvidenceSummary(snapshot)
    add("score", 15, snapshot.score and snapshot.score.source == "ui_widget",
        snapshot.score and snapshot.score.source)
    add("objectives", 15,
        snapshot.objectives and snapshot.objectives.source == "ui_widget",
        snapshot.objectives and snapshot.objectives.source)
    add("objective resolution", 8, objectiveEvidence.authoritative,
        string.format("%s / %d conflicts / %d unresolved",
            objectiveEvidence.source, objectiveEvidence.conflicts,
            objectiveEvidence.unresolved))
    add("friendly roster", 12, #(snapshot.roster or {}) >= 8,
        tostring(#(snapshot.roster or {})) .. " known")
    add("friendly capabilities", 10, (ourSummary.coverage or 0) >= 0.8,
        string.format("%d%%", math.floor((ourSummary.coverage or 0) * 100)))
    add("enemy roster", 8, #(snapshot.enemies or {}) >= 8,
        tostring(#(snapshot.enemies or {})) .. " known")
    add("enemy capabilities", 8, (enemySummary.coverage or 0) >= 0.6,
        string.format("%d%%", math.floor((enemySummary.coverage or 0) * 100)))
    add("location / ETA", 10, (coverage.friendlyLocated or 0)
        + (coverage.enemyLocated or 0) >= 3,
        tostring(coverage.friendlyLocated or 0) .. "F/"
            .. tostring(coverage.enemyLocated or 0) .. "E located")
    add("resource economy", 8, (resources.coverage or 0) >= 1,
        tostring(resources.coverage or 0) .. " enemy observations")
    add("momentum", 7, reporter.momentum and reporter.momentum.confidence ~= "NONE",
        reporter.momentum and reporter.momentum.state)
    add("enemy intent", 7, reporter.enemyIntent
        and reporter.enemyIntent.confidence ~= "NONE",
        reporter.enemyIntent and reporter.enemyIntent.target)
    add("reporter trust", 8, (reporterTrust.label == "HIGH"
        or reporterTrust.label == "MEDIUM"),
        reporterTrust.reason)
    add("knowledge freshness", 10, (knowledge.label == "HIGH"
        or knowledge.label == "MEDIUM"),
        knowledge.reason)
    add("opponent tendencies", 6, (opponentModels.label == "HIGH"
        or opponentModels.label == "MEDIUM"),
        opponentModels.reason)
    if objectiveEvidence.conflicts > 0 then
        score = score - math.min(18, objectiveEvidence.conflicts * 6)
    end
    if objectiveEvidence.source ~= "ui_widget" and objectiveEvidence.total > 0 then
        score = score - 8
    end
    if objectiveEvidence.unresolved > 0 then
        score = score - math.min(10, objectiveEvidence.unresolved * 3)
    end
    score = KWR.Util:Clamp(score, 0, 100)
    local risk = score < 40 and "HIGH"
        or ((prediction.urgency or 0) >= 85 and score < 70 and "HIGH"
        or (score < 70 and "MEDIUM" or "LOW"))
    return {
        score = score,
        label = score >= 80 and "HIGH" or (score >= 55 and "MEDIUM"
            or (score >= 30 and "LOW" or "NONE")),
        risk = risk,
        evidence = evidence,
    }
end

local function trustModel(snapshot, prediction, budget, simulations, selected)
    local truth = snapshot.truth or {}
    local reporterTrust = snapshot.reporter and snapshot.reporter.trust or {}
    local knowledge = snapshot.knowledgeStatus or {}
    local objectiveEvidence = objectiveEvidenceSummary(snapshot)
    local best = selected or simulations and simulations[1] or nil
    local second = simulations and simulations[2] or nil
    local separation = best and second
        and math.max(0, (best.decisionScore or 0) - (second.decisionScore or 0))
        or 100
    local score = KWR.Util:Clamp(
        (budget and budget.score or 0) * 0.6
            + (reporterTrust.score or 0) * 0.4
            + math.min(12, separation),
        0, 100)
    if objectiveEvidence.conflicts > 0 then
        score = math.max(0, score - math.min(16, objectiveEvidence.conflicts * 5))
    end
    if objectiveEvidence.authoritative ~= true then
        score = math.max(0, score - 6)
    end
    local label = score >= 80 and "HIGH"
        or (score >= 55 and "MEDIUM" or (score >= 30 and "LOW" or "NONE"))
    local mode = label == "HIGH" and "COMMIT"
        or (label == "MEDIUM" and "PROBE" or "VERIFY")
    local reason = (objectiveEvidence.conflicts > 0
            and "Objective truth has conflicting public signals.")
        or (truth.coreFresh == false and "Core truth is incomplete.")
        or (objectiveEvidence.authoritative ~= true
            and "Objective state is not fully authoritative yet.")
        or (knowledge.compositionAuthorized == false
            and "Composition certainty is too low for an advanced commit.")
        or (reporterTrust.pace == "VERIFY_FIRST" and "Enemy movement confidence is still thin.")
        or (separation <= 6 and "Top strategic options are still close.")
        or "Strategy has enough separation to commit."
    return {
        score = score,
        label = label,
        mode = mode,
        separation = separation,
        reason = reason,
        commitAuthorized = truth.coreFresh ~= false
            and objectiveEvidence.conflicts == 0
            and objectiveEvidence.authoritative == true
            and knowledge.compositionAuthorized ~= false
            and reporterTrust.pace ~= "VERIFY_FIRST"
            and label ~= "NONE" and label ~= "LOW",
        objectiveEvidence = objectiveEvidence,
    }
end

local function compareAlternatives(candidates)
    local results = {}
    local top = candidates and candidates[1]
    for index = 2, math.min(3, #(candidates or {})) do
        local candidate = candidates[index]
        local reason
        if candidate.legal == false then
            reason = candidate.ruleReason or "objective rule gate"
        elseif (candidate.decisionScore or 0) + 8 < (top and top.decisionScore or 0) then
            reason = "lower decision score"
        elseif candidate.opportunityCost and top
            and candidate.opportunityCost > (top.opportunityCost or 0) then
            reason = "higher opportunity cost"
        elseif candidate.reversible == false and top and top.reversible == true then
            reason = "less reversible"
        else
            reason = "weaker evidence edge"
        end
        results[#results + 1] = {
            id = candidate.id,
            target = candidate.target,
            score = candidate.decisionScore or candidate.probability or 0,
            reason = reason,
            legal = candidate.legal ~= false,
        }
    end
    return results
end

local function opportunityWindow(snapshot)
    local combat = snapshot.combat or {}
    local resources = combat.resourceEconomy or {}
    local enemy = resources.enemy or {}
    local reporter = snapshot.reporter or {}
    local score, duration, evidence = 0, 0, {}
    if (enemy.deadHealers or 0) > 0 then
        score = score + 38
        duration = math.max(duration, 18)
        evidence[#evidence + 1] = "enemy healer dead"
    end
    if (enemy.trinketsUsed or 0) >= 2 then
        score = score + 22
        duration = math.max(duration, 12)
        evidence[#evidence + 1] = tostring(enemy.trinketsUsed) .. " trinkets used"
    end
    if (enemy.defensivesUsed or 0) >= 2 then
        score = score + 18
        duration = math.max(duration, 10)
        evidence[#evidence + 1] = tostring(enemy.defensivesUsed) .. " defensives used"
    end
    if (enemy.isolatedCarriers or 0) > 0 then
        score = score + 30
        duration = math.max(duration, 8)
        evidence[#evidence + 1] = "carrier locally actionable"
    end
    local pressure = reporter.pressure or {}
    if #pressure >= 2 and pressure[1].enemy > 0 and pressure[2].enemy > 0 then
        score = score + 14
        duration = math.max(duration, 10)
        evidence[#evidence + 1] = "enemy team split"
    end
    for _, row in ipairs(pressure) do
        if row.owner == "ENEMY" and row.enemy == 0 and row.friendly > 0 then
            score = score + 24
            duration = math.max(duration, 10)
            evidence[#evidence + 1] = row.label .. " temporarily undefended"
            break
        end
    end
    score = KWR.Util:Clamp(score, 0, 100)
    return {
        open = score >= 30,
        score = score,
        duration = duration,
        expiresAt = score >= 30 and (KWR.Util:Now() + duration) or nil,
        confidence = score >= 65 and "HIGH" or (score >= 30 and "MEDIUM" or "LOW"),
        evidence = evidence,
    }
end

local function candidateSimulation(snapshot, prediction, ourSummary, enemySummary,
    budget, opportunity)
    local reporter = snapshot.reporter or {}
    local intent = reporter.enemyIntent or {}
    local reporterTrust = reporter.trust or {}
    local momentum = reporter.momentum and reporter.momentum.value or 0
    local resources = snapshot.combat and snapshot.combat.resourceEconomy or {}
    local resourceAdvantage = resources.advantage or 0
    local objectiveRules = KWR.ObjectiveRules
        and KWR.ObjectiveRules:Resolve(snapshot) or nil
    local ratings, enemyRatings = ourSummary.ratings or {}, enemySummary.ratings or {}
    local truth = snapshot.truth or {}
    local definition = KWR.Maps:Get(snapshot.context and snapshot.context.mapKey)
    local profile = KWR.Maps:OperationalProfile(
        snapshot.context and snapshot.context.mapKey)
    local faction = snapshot.context and snapshot.context.team
        and snapshot.context.team.faction
    local homeTarget = definition and definition.home and faction
        and definition.home[faction]
    local theoryTarget = homeTarget
        or (definition and definition.priorities and definition.priorities[1])
        or (definition and definition.title)
        or "the current scoring objective"
    local friendly, enemy, available = {}, {}, {}
    for _, objective in ipairs(snapshot.objectives
        and snapshot.objectives.rows or {}) do
        if objective.owner == "FRIENDLY" then
            friendly[#friendly + 1] = objective.label
        elseif objective.owner == "ENEMY" then
            enemy[#enemy + 1] = objective.label
        else
            available[#available + 1] = objective.label
        end
    end
    local function priorityTarget(candidates)
        local present = {}
        for _, target in ipairs(candidates or {}) do present[target] = true end
        for _, target in ipairs(definition and definition.priorities or {}) do
            if present[target] then return target end
        end
        return candidates and candidates[1]
    end
    local assaultTarget = priorityTarget(enemy)
        or priorityTarget(available)
        or (definition and definition.priorities
            and definition.priorities[1])
    local threatenedTarget = reporter.hotspot
        and reporter.hotspot.owner == "FRIENDLY"
        and reporter.hotspot.label or friendly[1] or theoryTarget
    local function etaFor(target)
        for _, eta in ipairs(reporter.etas or {}) do
            if eta.label == target then return eta end
        end
    end
    local assaultETA = etaFor(assaultTarget)
    local reinforceETA = etaFor(threatenedTarget)
    local etaEdge = assaultETA and assaultETA.advantage or 0
    local uncertaintyPenalty = truth.aggressiveCommitAllowed == false
        and 14 or (budget.score < 55 and 8 or 0)
    local intentCommitment = KWR.Util:Number(intent.commitmentScore, 0) or 0
    local intentOvercommit = intent.target ~= nil and intentCommitment >= 55
    local hiddenRisk = KWR.Util:Number(reporterTrust.hiddenRisk, 0) or 0
    local objectiveUrgency = KWR.Util:Clamp(
        prediction.urgency or 0, 0, 100)
    local holdValue = prediction.status == "WIN" and 24
        or (#friendly >= (profile.stableMinimum or 1) and 8 or -12)
    local threatenedRisk = reporter.hotspot
        and reporter.hotspot.owner == "FRIENDLY"
        and reporter.hotspot.risk or 0
    local candidates = {
        {
            id = "HOLD",
            target = #friendly > 0 and table.concat(friendly, " + ")
                or theoryTarget,
            probability = 48 + holdValue
                + ((ratings.nodeDefense or 1) - 2) * 4
                + (budget.score < 50 and 10 or 0)
                + math.min(10, hiddenRisk * 0.08)
                - math.max(0, threatenedRisk - 70) * 0.18,
            outcome = "Preserve the current scoring requirement.",
            risk = "May surrender initiative if the enemy has a free weak-side objective.",
            opportunityCost = 8,
            reversible = true,
            success = "Required objectives remain controlled through the next scoring window.",
            abort = "Coverage breaks or the current score path stops winning.",
            evidence = {
                tostring(#friendly) .. " friendly objectives",
                tostring(threatenedRisk) .. " highest friendly risk",
            },
        },
        {
            id = "ROTATE",
            target = threatenedTarget or assaultTarget,
            probability = 43 + ((ratings.mobility or 1) - 2) * 5
                + KWR.Util:Clamp(reinforceETA
                    and reinforceETA.advantage or etaEdge, -12, 12)
                + (intent.target == threatenedTarget and 10 or 0)
                + (intent.target == threatenedTarget
                    and math.min(10, intentCommitment * 0.12) or 0)
                + threatenedRisk * 0.12
                - (truth.coreFresh == false and 8 or 0),
            outcome = "Arrive before the enemy commitment and stabilize the next objective.",
            risk = "A late or unverified rotation can expose the objective being left.",
            opportunityCost = 20,
            reversible = true,
            success = "Reinforcements restore minimum coverage before objective loss.",
            abort = "Enemy arrives first or the departure exposes another scoring objective.",
            evidence = {
                tostring(reinforceETA and reinforceETA.advantage
                    or "unknown") .. "s arrival edge",
                tostring(threatenedRisk) .. " pressure risk",
            },
        },
        {
            id = "TRADE",
            target = assaultTarget,
            probability = 40 + ((ratings.splitPush or 1) - 2) * 6
                + (prediction.status == "LOSE" and 14 or 0)
                + (intent.target == threatenedTarget and intentOvercommit and 12 or 0)
                + objectiveUrgency * 0.08
                - uncertaintyPenalty,
            outcome = "Exchange the least valuable exposed objective for a better scoring lane.",
            risk = "The trade fails if defenders leave before the capture is secured.",
            opportunityCost = 30,
            reversible = false,
            success = assaultTarget and ("Secure " .. assaultTarget
                .. " before the threatened objective is lost.")
                or "Complete the objective trade.",
            abort = "The assault is reinforced or the protected score floor becomes uncovered.",
            evidence = {
                tostring(assaultTarget or "no target") .. " trade target",
                tostring(objectiveUrgency) .. " urgency",
            },
        },
        {
            id = "TEAMFIGHT",
            target = reporter.hotspot and reporter.hotspot.label
                or assaultTarget,
            probability = 44 + ((ratings.teamfight or 1)
                - (enemyRatings.teamfight or 1)) * 7
                + opportunity.score * 0.18 + momentum * 0.08
                + resourceAdvantage * 0.10
                + math.min(8, intentCommitment * 0.06)
                - hiddenRisk * 0.12
                - (reporter.hotspot and reporter.hotspot.owner == "UNKNOWN"
                    and 8 or 0),
            outcome = "Convert the temporary combat advantage into objective control.",
            risk = "The fight has no value if it occurs away from the scoring requirement.",
            opportunityCost = 24,
            reversible = false,
            success = "The fight creates immediate objective control or carrier progress.",
            abort = "The opportunity window closes or the fight loses objective value.",
            evidence = {
                tostring(opportunity.score) .. " opportunity",
                tostring(momentum) .. " momentum",
                tostring(resourceAdvantage) .. " resource edge",
            },
        },
        {
            id = "SPLIT",
            target = assaultTarget,
            probability = 41 + ((ratings.splitPush or 1)
                - (enemyRatings.mobility or 1)) * 6
                + (intent.groupSize or 0) * 2
                + (intent.target == threatenedTarget and intentOvercommit and 14 or 0)
                + (reporter.hotspot
                    and (reporter.hotspot.enemy or 0) >= 5 and 12 or 0)
                - hiddenRisk * 0.10
                - uncertaintyPenalty,
            outcome = "Force the enemy composition to defend separate scoring threats.",
            risk = "Split pressure becomes two losing fights without confirmed timing.",
            opportunityCost = 35,
            reversible = false,
            success = "Enemy releases enough players to weaken its primary win condition.",
            abort = "Both groups lose local parity or healer coverage disconnects.",
            evidence = {
                tostring(reporter.enemyIntent
                    and reporter.enemyIntent.groupSize or 0)
                    .. " enemies in predicted commitment",
                tostring(budget.score) .. " evidence score",
            },
        },
    }
    for _, candidate in ipairs(candidates) do
        if candidate.target == nil then
            candidate.probability = candidate.probability - 18
            candidate.evidence[#candidate.evidence + 1] =
                "no verified objective target"
        end
        if objectiveRules then
            local legal, reason = KWR.ObjectiveRules:IsActionLegal(
                snapshot, candidate.id, objectiveRules)
            candidate.legal = legal == true
            candidate.ruleReason = reason
            if not candidate.legal then
                candidate.probability = candidate.probability - 26
                candidate.evidence[#candidate.evidence + 1] =
                    "objective rule gate: " .. tostring(reason)
            end
        else
            candidate.legal = true
        end
        if not candidate.reversible
            and truth.aggressiveCommitAllowed == false then
            candidate.probability = candidate.probability - 12
            candidate.evidence[#candidate.evidence + 1] =
                "aggressive commitment gated by truth coverage"
        end
        candidate.probability = candidate.probability
            - candidate.opportunityCost * 0.08
        candidate.probability = math.floor(KWR.Util:Clamp(
            candidate.probability, 5, 95) + 0.5)
        candidate.decisionScore = candidate.probability
        candidate.projection = candidate.probability >= 70 and "FAVORABLE"
            or (candidate.probability >= 50 and "VIABLE" or "WEAK")
        candidate.heuristic = true
    end
    table.sort(candidates, function(a, b)
        if a.probability ~= b.probability then return a.probability > b.probability end
        return a.id < b.id
    end)
    return candidates
end

local function applyEnemyResponsePlanning(snapshot, prediction, result)
    if not KWR.EnemyResponsePlanner or not result.simulations then
        return
    end
    local context = {
        doctrineFlags = result.doctrineFlags,
        responseContract = result.responseContract,
        expertReview = result.scenarioExpertReview,
        scenarioCalibration = result.scenarioCalibration,
        adversarialCalibration = result.scenarioAdversarialCalibration,
        doctrineResponse = result.enemyResponseGuidance,
        opportunity = result.opportunity,
        budget = result.confidenceBudget,
        currentStatus = prediction and prediction.status,
    }
    for _, candidate in ipairs(result.simulations) do
        local responsePlan = KWR.EnemyResponsePlanner:Evaluate(
            snapshot, prediction, candidate, context)
        candidate.enemyResponsePlan = responsePlan
        candidate.decisionScore = math.floor(KWR.Util:Clamp(
            (candidate.decisionScore or candidate.probability or 0)
                + (responsePlan.consequenceAdjustment or 0),
            5,
            95) + 0.5)
        candidate.probability = candidate.decisionScore
        candidate.projection = candidate.decisionScore >= 70 and "FAVORABLE"
            or (candidate.decisionScore >= 50 and "VIABLE" or "WEAK")
        candidate.evidence[#candidate.evidence + 1] =
            "response " .. tostring(responsePlan.responseID)
                .. " adjust " .. tostring(responsePlan.consequenceAdjustment or 0)
    end
    table.sort(result.simulations, function(a, b)
        if a.decisionScore ~= b.decisionScore then
            return a.decisionScore > b.decisionScore
        end
        return a.id < b.id
    end)
    result.selectedAction = result.simulations[1]
        and KWR.Util:Copy(result.simulations[1]) or nil
    result.expectedOutcome = result.simulations[1] and result.simulations[1].outcome
    result.recommendationMode = result.simulations[1] and result.simulations[1].id
    result.projectedWinProbability = result.simulations[1] and result.simulations[1].probability
    result.decisionScore = result.simulations[1] and result.simulations[1].decisionScore
    result.projection = result.simulations[1] and result.simulations[1].projection
    result.alternativeReview = compareAlternatives(result.simulations)
    if result.selectedAction and result.selectedAction.enemyResponsePlan then
        result.enemyResponsePlan = KWR.Util:Copy(result.selectedAction.enemyResponsePlan)
        result.enemyResponseID = result.enemyResponsePlan.responseID
        result.enemyResponseSummary = result.enemyResponsePlan.summary
        result.consequenceScore = result.enemyResponsePlan.consequenceAdjustment or 0
    end
end

local function carrierTarget(carrier, fallback)
    return KWR.Util:Text(carrier and (carrier.player or carrier.name or carrier.objective),
        fallback or "the objective carrier", 64)
end

-- Carrier and emergency-objective truth outrank a generic Nexus candidate.
-- Keep every command-facing field in one synchronized record so Commander,
-- the envelope, and active-play stability track the exact same call.
local function applyObjectiveOverride(result, override)
    if type(result) ~= "table" or type(override) ~= "table" then return end
    local previous = KWR.Util:Copy(result.selectedAction or {})
    local selected = KWR.Util:Copy(previous)
    selected.id = KWR.Util:Text(override.id, "OBJECTIVE_OVERRIDE", 48)
    selected.target = KWR.Util:Text(override.target or result.target,
        "the live objective", 64)
    selected.outcome = KWR.Util:Text(override.outcome or override.reason,
        "Live objective truth requires this action.", 180)
    selected.success = KWR.Util:Text(override.success, selected.success or "Objective stabilizes.", 160)
    selected.abort = KWR.Util:Text(override.abort, selected.abort or "Carrier or objective state changes.", 160)
    selected.override = "LIVE_OBJECTIVE_TRUTH"
    result.selectedAction = selected
    result.action = KWR.Util:Text(override.action, result.action, 220)
    result.reason = KWR.Util:Text(override.reason, result.reason, 220)
    result.switchIf = KWR.Util:Text(override.switchIf, result.switchIf, 180)
    result.stop = KWR.Util:Text(override.abort, result.stop, 180)
    result.target = selected.target
    result.expectedOutcome = selected.outcome
    result.recommendationMode = selected.id
    result.enemyResponsePlan = nil
    result.enemyResponseID = nil
    result.enemyResponseSummary = nil
    result.consequenceScore = 0
    if previous.id and previous.id ~= selected.id then
        result.nexusFallbackCandidate = previous
    end
    result.objectiveDecision = type(result.objectiveDecision) == "table"
        and KWR.Util:Copy(result.objectiveDecision) or {}
    result.objectiveDecision.target = selected.target
    result.objectiveDecision.success = selected.success
    result.objectiveDecision.abort = selected.abort
end

function Strategist:Evaluate(snapshot, prediction)
    local signature = decisionSignature(snapshot, prediction)
    local now = KWR.Util:Now()
    if self.cache and self.cache.signature == signature
        and now - self.cache.at <= 1.5 then
        self.cacheHits = self.cacheHits + 1
        return KWR.Util:Copy(self.cache.result)
    end
    self.cacheMisses = self.cacheMisses + 1
    local ourSummary = snapshot.formation and snapshot.formation.summary
        or KWR.Capabilities:Summarize(snapshot.roster)
    local enemySummary = KWR.Capabilities:Summarize(snapshot.enemies)
    local ourComposition = KWR.Compositions:Detect(ourSummary)
    local enemyComposition = KWR.Compositions:Detect(enemySummary)
    local ourTier = KWR.Compositions:MatchTier(snapshot.roster, snapshot.context.mapKey)
    local enemyTier = KWR.Compositions:MatchTier(snapshot.enemies, snapshot.context.mapKey)
    local counter = KWR.Counters:Get(
        enemyComposition.id,
        enemyTier and enemyTier.qualified and enemyTier or nil)
    local result = {
        ourSummary = ourSummary,
        enemySummary = enemySummary,
        ourComposition = ourComposition,
        enemyComposition = enemyComposition,
        ourTier = KWR.Util:Copy(ourTier),
        enemyTier = KWR.Util:Copy(enemyTier),
        counter = KWR.Util:Copy(counter),
        candidates = {},
        confidence = "NONE",
    }
    if not snapshot.context.inPvP then
        result.reason = "Strategy engine is standing by outside a battleground."
        return result
    end
    local currentState = strategicState(snapshot, prediction)
    result.state = currentState
    for _, battlePlan in ipairs(KWR.BattlePlans:Get(snapshot.context.mapKey)) do
        local feasible, missing = requirementFit(ourSummary, battlePlan.requires)
        local score = 0
        local focus = planFocus(snapshot.context.kind, battlePlan.state, currentState)
        local readiness, matchup = capabilityFit(ourSummary, enemySummary, focus)
        local ourTierID = ourTier and ourTier.qualified and ourTier.id or nil
        local enemyTierID = enemyTier and enemyTier.qualified and enemyTier.id or nil
        local preferredState = currentState == "RECOVERY" and "LOSE"
            or (currentState == "STABILIZE" and "WIN")
            or (currentState == "CONTEST" and "TIE")
            or currentState
        if stateFit(battlePlan.state, currentState) then
            score = score + (battlePlan.state == preferredState and 35 or 14)
        else
            score = score - 24
        end
        if battlePlan.archetypes[ourComposition.id] then score = score + 22 end
        if ourTier and ourTier.qualified and ourTier.mapFit then score = score + 10 end
        if hasOptions(battlePlan.enemyArchetypes) then
            if battlePlan.enemyArchetypes[enemyComposition.id] then
                score = score + 18
            else
                score = score - 6
            end
        end
        if hasOptions(battlePlan.ourTiers) and ourTierID then
            if battlePlan.ourTiers[ourTierID] then
                score = score + 20
            else
                score = score - 8
            end
        end
        if hasOptions(battlePlan.enemyTiers) and enemyTierID then
            if battlePlan.enemyTiers[enemyTierID] then
                score = score + 18
            else
                score = score - 6
            end
        end
        if battlePlan.pugFriendly then
            if ourTierID == "PUG_FRIENDLY" then
                score = score + 18
            elseif not ourTier or not ourTier.qualified then
                score = score + 12
            end
        elseif ourTierID == "PUG_FRIENDLY" then
            score = score - 5
        end
        score = score + (battlePlan.priority or 0)
        score = score + math.min(12, (ourSummary.coverage or 0) * 12)
        score = score + math.min(10, (prediction.urgency or 0) / 10)
        score = score + readiness + matchup
        if not feasible then score = score - 35 end
        if KWR.Learning and KWR.Learning.Adjustment then
            score = score + KWR.Learning:Adjustment(snapshot.context.mapKey, battlePlan.id)
        end
        result.candidates[#result.candidates + 1] = {
            plan = battlePlan,
            score = score,
            feasible = feasible,
            missing = missing,
            focus = focus,
            readiness = readiness,
            matchup = matchup,
        }
    end
    table.sort(result.candidates, function(a, b)
        if a.feasible ~= b.feasible then return a.feasible == true end
        if a.score ~= b.score then return a.score > b.score end
        return a.plan.id < b.plan.id
    end)

    local selected
    for _, candidate in ipairs(result.candidates) do
        if candidate.feasible then selected = candidate break end
    end
    selected = selected or result.candidates[1]
    if not selected then
        result.reason = "No reviewed plan exists for this map."
        return result
    end
    local budget = confidenceBudget(snapshot, prediction, ourSummary, enemySummary)
    local opportunity = opportunityWindow(snapshot)
    local simulations = candidateSimulation(
        snapshot, prediction, ourSummary, enemySummary, budget, opportunity)
    local signal = mapSignal(snapshot.context.mapKey)
    result.planID = selected.plan.id
    result.action = selected.plan.action
    result.reason = selected.plan.why
    result.switchIf = selected.plan.switchIf
    result.stop = selected.plan.stop
    result.assignmentHints = KWR.Util:Copy(selected.plan.assignments)
    result.planTags = KWR.Util:Copy(selected.plan.tags)
    result.planPriority = selected.plan.priority or 0
    result.planNote = selected.plan.note
    result.pugFriendly = selected.plan.pugFriendly == true
    result.score = selected.score
    result.feasible = selected.feasible
    result.missing = selected.missing
    result.weightedFocus = KWR.Util:Copy(selected.focus)
    result.capabilityReadiness = selected.readiness
    result.capabilityMatchup = selected.matchup
    result.principle = signal and signal.principle or nil
    result.confidenceBudget = budget
    result.confidence = budget.label
    result.risk = budget.risk
    result.objectiveRules = KWR.ObjectiveRules
        and KWR.ObjectiveRules:Resolve(snapshot) or nil
    result.minimumControlToWin = result.objectiveRules
        and result.objectiveRules.minimumControlToWin or nil
    result.legalActions = result.objectiveRules
        and KWR.Util:Copy(result.objectiveRules.legalActionList) or {}
    result.impossibleActions = result.objectiveRules
        and KWR.Util:Copy(result.objectiveRules.impossibleActionList) or {}
    result.opportunity = opportunity
    result.simulations = simulations
    result.knowledge = KWR.Util:Copy(snapshot.knowledgeStatus)
    result.selectedAction = simulations[1]
        and KWR.Util:Copy(simulations[1]) or nil
    result.expectedOutcome = simulations[1] and simulations[1].outcome
    result.recommendationMode = simulations[1] and simulations[1].id
    result.projectedWinProbability = simulations[1] and simulations[1].probability
    result.decisionScore = simulations[1] and simulations[1].decisionScore
    result.projection = simulations[1] and simulations[1].projection
    result.alternativeReview = compareAlternatives(simulations)
    result.alternatives = {}
    for _, candidate in ipairs(result.candidates) do
        if candidate.plan.id ~= result.planID and #result.alternatives < 2 then
            result.alternatives[#result.alternatives + 1] = {
                id = candidate.plan.id,
                action = candidate.plan.action,
                score = candidate.score,
                feasible = candidate.feasible,
            }
        end
    end
    local scenario = KWR.ScenarioLibrary:Select(snapshot, prediction, result)
    if scenario then
        result.scenarioID = scenario.id
        result.phase = scenario.phase
        result.pressureState = scenario.pressure
        result.fightShape = scenario.shape
        result.scenarioAction = scenario.action
        result.objectiveDecision = KWR.Util:Copy(scenario.objectiveDecision)
        result.responseContract = KWR.Util:Copy(scenario.responseContract)
        if not result.action or result.action == "" then
            result.action = scenario.action
        end
    end
    -- The live strategy only consumes decision fields, not the complete
    -- reviewed corpus row.  Keep the corpus immutable and avoid cloning its
    -- evidence graph on every battlefield refresh.
    local scenarioCalibration = KWR.ScenarioCalibration
        and KWR.ScenarioCalibration:GetSummary(result.scenarioID) or nil
    if not scenarioCalibration and KWR.ScenarioCalibration then
        scenarioCalibration = KWR.ScenarioCalibration:GetSummaryByMapAndPhase(
            snapshot.context and snapshot.context.mapKey,
            result.phase)
    end
    if scenarioCalibration then
        result.scenarioCalibration = scenarioCalibration
        result.reviewedCases = scenarioCalibration.reviewedCases
        result.reviewedWinRate = scenarioCalibration.winRate
        result.reviewConfidence = scenarioCalibration.reviewConfidence
        result.reviewDisciplineRule = scenarioCalibration.disciplineRule
        if result.responseContract then
            result.responseContract.reviewedCases = scenarioCalibration.reviewedCases
            result.responseContract.reviewedWinRate = scenarioCalibration.winRate
            result.responseContract.reviewConfidence = scenarioCalibration.reviewConfidence
            result.responseContract.disciplineRule = scenarioCalibration.disciplineRule
            result.responseContract.topFailure = scenarioCalibration.topFailure
        end
        if scenarioCalibration.topFailure and scenarioCalibration.topFailure ~= "NONE" then
            result.stop = KWR.Util:Text(result.stop, "", 220)
            if result.stop ~= "" then
                result.stop = result.stop .. " "
            end
            result.stop = result.stop .. scenarioCalibration.disciplineRule
        end
        result.reason = KWR.Util:Text(result.reason, "", 220)
        if result.reason ~= "" then
            result.reason = result.reason .. " "
        end
        result.reason = result.reason .. string.format(
            "REVIEWED: %d cases, %d%% wins, common break = %s.",
            scenarioCalibration.reviewedCases or 0,
            scenarioCalibration.winRate or 0,
            scenarioCalibration.topFailure or "NONE")
    end
    local adversarialCalibration = KWR.ScenarioAdversarialCalibration
        and KWR.ScenarioAdversarialCalibration:GetSummary(result.scenarioID) or nil
    if not adversarialCalibration and KWR.ScenarioAdversarialCalibration then
        adversarialCalibration = KWR.ScenarioAdversarialCalibration:GetSummaryByMapAndPhase(
            snapshot.context and snapshot.context.mapKey,
            result.phase)
    end
    if adversarialCalibration then
        result.scenarioAdversarialCalibration = adversarialCalibration
        result.adversarialCases = adversarialCalibration.adversarialCases
        result.adversarialDisciplineRule = adversarialCalibration.disciplineRule
        if result.responseContract then
            result.responseContract.adversarialCases = adversarialCalibration.adversarialCases
            result.responseContract.truthRisk = adversarialCalibration.truthRisk
            result.responseContract.safePrimaryAction = adversarialCalibration.safePrimaryAction
            result.responseContract.safeFallbackAction = adversarialCalibration.safeFallbackAction
            result.responseContract.forbiddenCommit = adversarialCalibration.forbiddenCommit
            result.responseContract.mustStay = KWR.Util:Copy(adversarialCalibration.mustStay)
            result.responseContract.escalateWhen = adversarialCalibration.escalateWhen
            result.responseContract.adversarialDisciplineRule = adversarialCalibration.disciplineRule
        end
    end
    local scenarioExpertReview = KWR.ScenarioExpertCorpus
        and KWR.ScenarioExpertCorpus:GetSummary(result.scenarioID) or nil
    if not scenarioExpertReview and KWR.ScenarioExpertCorpus then
        scenarioExpertReview = KWR.ScenarioExpertCorpus:GetSummaryByMapAndPhase(
            snapshot.context and snapshot.context.mapKey,
            result.phase)
    end
    if scenarioExpertReview then
        result.scenarioExpertReview = scenarioExpertReview
        result.expertReviewedLabels = scenarioExpertReview.reviewedLabels
        result.expertReviewConfidence = scenarioExpertReview.reviewConfidence
        result.expertAgreementRate = scenarioExpertReview.agreementRate
        result.expertPreferredAction = scenarioExpertReview.consensusPrimaryAction
        result.expertPreferredFallback = scenarioExpertReview.consensusFallbackAction
        result.expertSafestCounter = scenarioExpertReview.safestCounter
        result.expertExpectedEnemyCounter = scenarioExpertReview.expectedEnemyCounter
        if result.responseContract then
            result.responseContract.expertReviewedLabels = scenarioExpertReview.reviewedLabels
            result.responseContract.expertReviewConfidence = scenarioExpertReview.reviewConfidence
            result.responseContract.expertAgreementRate = scenarioExpertReview.agreementRate
            result.responseContract.expertPreferredAction = scenarioExpertReview.consensusPrimaryAction
            result.responseContract.expertPreferredFallback = scenarioExpertReview.consensusFallbackAction
            result.responseContract.expertSafestCounter = scenarioExpertReview.safestCounter
            result.responseContract.expertExpectedEnemyCounter = scenarioExpertReview.expectedEnemyCounter
            result.responseContract.expertMustStay = KWR.Util:Copy(scenarioExpertReview.mustStay)
            result.responseContract.expertRequiredCapabilities =
                KWR.Util:Copy(scenarioExpertReview.requiredCapabilities)
        end
    end
    local compThreat, defenseModel, doctrineBranch, doctrineClass, flags =
        doctrineSelection(snapshot, prediction, currentState, result)
    result.compThreat = KWR.Util:Copy(compThreat)
    result.enemyDefenseModel = KWR.Util:Copy(defenseModel)
    result.doctrineFlags = KWR.Util:Copy(flags)
    applyDoctrineBranch(result, doctrineBranch, doctrineClass)
    local doctrineComparison = KWR.DoctrineComparisons
        and KWR.DoctrineComparisons:SelectComparison(snapshot.context.mapKey, {
            currentState = currentState,
            prediction = prediction,
            flags = flags,
            kind = snapshot.context.kind,
        }) or nil
    local doctrineResponse = KWR.DoctrineComparisons
        and KWR.DoctrineComparisons:SelectResponse(snapshot.context.mapKey, {
            currentState = currentState,
            prediction = prediction,
            flags = flags,
            kind = snapshot.context.kind,
            compThreat = compThreat,
            defenseModel = defenseModel,
        }) or nil
    applyDoctrineComparisonGuidance(result, doctrineComparison)
    applyDoctrineResponseGuidance(result, doctrineResponse)
    applyEnemyResponsePlanning(snapshot, prediction, result)
    if KWR.StrategistNexus then
        KWR.StrategistNexus:Rank(snapshot, prediction, result)
    end
    local carriers = snapshot.objectives and snapshot.objectives.carriers or {}
    if snapshot.context.kind == "FLAG" then
        local friendlyCarrier, enemyCarrier
        for _, carrier in ipairs(carriers) do
            if carrier.owner == "FRIENDLY" then friendlyCarrier = carrier
            elseif carrier.owner == "ENEMY" then enemyCarrier = carrier end
        end
        if friendlyCarrier and enemyCarrier then
            local enemyStacks = enemyCarrier.stacks or 0
            if enemyStacks < 3 then
                applyObjectiveOverride(result, {
                    id = "STABILIZE_FRIENDLY_CARRIER",
                    target = carrierTarget(friendlyCarrier, "our flag carrier"),
                    action = "Stabilize our flag carrier, regroup offense, and deny trickle deaths.",
                    reason = "Both flags are held; coordinated offense becomes more actionable as carrier pressure rises.",
                    switchIf = "Push the grouped return when enemy carrier stacks or exposed defenses create a real kill window.",
                    success = "Our carrier is stabilized and the return group is assembled.",
                    abort = "Do not trickle into a healthy, fully supported low-stack carrier.",
                })
            else
                applyObjectiveOverride(result, {
                    id = "RETURN_ENEMY_CARRIER",
                    target = carrierTarget(enemyCarrier, "the enemy flag carrier"),
                    action = "Push one grouped return team onto the stacked enemy flag carrier while preserving our carrier peel.",
                    reason = "Enemy carrier pressure is now actionable; synchronize healer control and burst.",
                    success = "The enemy carrier is returned or their escort is broken.",
                    abort = "Do not send isolated players ahead of the return group.",
                })
            end
        end
    elseif snapshot.context.kind == "ORB" then
        local endangered
        for _, carrier in ipairs(carriers) do
            if carrier.owner == "FRIENDLY" and carrier.healthPercent
                and carrier.healthPercent <= 35 then endangered = carrier break end
        end
        if endangered then
            applyObjectiveOverride(result, {
                id = "RELIEVE_FRIENDLY_ORB_CARRIER",
                target = carrierTarget(endangered, endangered.objective or "the orb carrier"),
                action = "Prepare a replacement at " .. KWR.Util:Text(endangered.objective,
                    "the scoring point", 64)
                    .. " and peel the current carrier toward supported scoring space.",
                reason = "A low-health orb carrier needs an intentional handoff or immediate peel, not an unplanned loss.",
                success = "The carrier reaches support or the replacement secures the handoff.",
                abort = "Do not abandon the current carrier before relief arrives.",
            })
        end
    end
    local truth = snapshot.truth or {}
    result.trust = trustModel(snapshot, prediction, budget, simulations, result.selectedAction)
    result.theoryActive = true
    result.projectionBasis = "IMMEDIATE_THEORY_FIRST"
    local gateReason
    local requiredEvidence = {}
    if budget.score < 40 or truth.coreFresh == false then
        gateReason = truth.conservativeReason
            or "Evidence coverage is too low for an aggressive commitment."
        requiredEvidence = {
            "authoritative objective state",
            "fresh score state",
            "enemy movement confirmation",
        }
    elseif snapshot.knowledgeStatus
        and snapshot.knowledgeStatus.compositionAuthorized == false then
        gateReason = snapshot.knowledgeStatus.reason
        requiredEvidence = {
            "verified enemy specializations",
            "enemy capability coverage",
            "composition counter confirmation",
        }
    elseif result.trust and result.trust.commitAuthorized == false then
        gateReason = result.trust.reason
        requiredEvidence = {
            "objective conflict resolution",
            "enemy movement confirmation",
            "local arrival-time advantage",
        }
    elseif opportunity.open and budget.score >= 55
        and result.recommendationMode == "TEAMFIGHT" then
        result.reason = result.reason .. " WINDOW: "
            .. table.concat(opportunity.evidence, ", ") .. "."
    end
    result.executionGate = {
        -- This remains diagnostic metadata. The player always receives the
        -- best current call; weak truth changes its commitment style, not
        -- whether KWR provides a plan.
        status = gateReason and "VERIFY_BEFORE_COMMIT" or "COMMIT_ALLOWED",
        reason = gateReason or "Live truth supports the selected plan.",
        requiredEvidence = KWR.Util:Copy(requiredEvidence),
        theoreticalPrimary = result.recommendationMode,
        target = result.selectedAction and result.selectedAction.target,
    }
    if gateReason then
        result.reason = KWR.Util:Text(result.reason, "", 220)
        if result.reason ~= "" then result.reason = result.reason .. " " end
        result.reason = result.reason .. "ADAPTIVE PLAN: " .. gateReason
        result.stop = KWR.Util:Text(result.stop, "", 220)
        if result.stop ~= "" then result.stop = result.stop .. " " end
        result.stop = result.stop
            .. "Keep objective coverage intact and convert only on the first confirmed opening."
    end
    if adversarialCalibration and (
        (result.trust and result.trust.commitAuthorized == false)
        or result.recommendationMode == "VERIFY"
        or result.recommendationMode == "HOLD") then
        result.reason = KWR.Util:Text(result.reason, "", 220)
        if result.reason ~= "" then
            result.reason = result.reason .. " "
        end
        result.reason = result.reason .. string.format(
            "ADVERSARIAL: safe=%s / fallback=%s / forbid=%s.",
            adversarialCalibration.safePrimaryAction or "CHECK",
            adversarialCalibration.safeFallbackAction or "HOLD",
            adversarialCalibration.forbiddenCommit or "FULL_COMMIT")
        result.stop = KWR.Util:Text(result.stop, "", 220)
        if result.stop ~= "" then
            result.stop = result.stop .. " "
        end
        result.stop = result.stop .. adversarialCalibration.disciplineRule
        if (result.switchIf == nil or result.switchIf == "") and adversarialCalibration.escalateWhen then
            result.switchIf = adversarialCalibration.escalateWhen
        end
    end
    if KWR.StrategistNexus then
        result.nexus = KWR.StrategistNexus:Envelope(snapshot, prediction, result)
    end
    self.cache = {
        signature = signature,
        at = now,
        result = KWR.Util:Copy(result),
    }
    return result
end

function Strategist:CacheStats()
    return {
        hits = self.cacheHits or 0,
        misses = self.cacheMisses or 0,
        active = self.cache ~= nil,
        executionHits = self.executionCacheHits or 0,
        executionMisses = self.executionCacheMisses or 0,
        executionActive = self.executionCache ~= nil,
    }
end

local function executionLabel(score)
    if score >= 75 then return "HIGH" end
    if score >= 50 then return "MEDIUM" end
    if score >= 25 then return "LOW" end
    return "NONE"
end

local function findETA(reporter, target)
    if not target then return nil end
    for _, row in ipairs(reporter.etas or {}) do
        if row.label == target then return row end
    end
end

function Strategist:AssessExecution(snapshot, prediction, assignments)
    if not snapshot.context or not snapshot.context.inPvP then
        return {
            active = false,
            confidence = "NONE",
            actionOpportunity = { action = "NONE", score = 0 },
        }
    end

    local integrity = snapshot.assignmentIntegrity or {}
    local signatureParts = {
        decisionSignature(snapshot, prediction),
        integrity.onStation or 0,
        integrity.moving or 0,
        integrity.unverified or 0,
        integrity.abandoned or 0,
        integrity.impossible or 0,
    }
    for _, assignment in ipairs(assignments or {}) do
        signatureParts[#signatureParts + 1] = table.concat({
            assignment.guid or assignment.name or "?",
            assignment.role or "?",
            assignment.location or "?",
        }, ":")
    end
    local executionSignature = table.concat(signatureParts, "\030")
    local executionNow = KWR.Util:Now()
    if self.executionCache
        and self.executionCache.signature == executionSignature
        and executionNow - self.executionCache.at <= 1.0 then
        self.executionCacheHits = self.executionCacheHits + 1
        return KWR.Util:Copy(self.executionCache.result)
    end
    self.executionCacheMisses = self.executionCacheMisses + 1

    local reporter = snapshot.reporter or {}
    local momentum = reporter.momentum or {}
    local intent = reporter.enemyIntent or {}
    local resources = snapshot.combat and snapshot.combat.resourceEconomy or {}
    local resourceEnemy = resources.enemy or {}
    local evidenceCount = 0
    if #(reporter.pressure or {}) > 0 then evidenceCount = evidenceCount + 1 end
    if #(reporter.etas or {}) > 0 then evidenceCount = evidenceCount + 1 end
    if intent.target then evidenceCount = evidenceCount + 1 end
    if momentum.confidence and momentum.confidence ~= "NONE" then
        evidenceCount = evidenceCount + 1
    end
    if #(integrity.rows or {}) > 0 then evidenceCount = evidenceCount + 1 end
    if (resources.coverage or 0) > 0 then evidenceCount = evidenceCount + 1 end
    local confidenceScore = KWR.Util:Clamp(
        (snapshot.strategy and snapshot.strategy.confidenceBudget
            and snapshot.strategy.confidenceBudget.score or 0) * 0.65
            + evidenceCount * 6,
        0, 100)
    if snapshot.truth and snapshot.truth.coreFresh == false then
        confidenceScore = math.min(confidenceScore, 38)
    end

    local commitment = {
        state = "UNKNOWN",
        score = 0,
        objective = nil,
        excess = 0,
        evidence = {},
    }
    for _, row in ipairs(reporter.pressure or {}) do
        local state, score, excess
        if row.owner == "FRIENDLY" and row.enemy >= 2 and row.friendly <= 1 then
            state = "UNDERDEFENDED"
            score = 78 + math.min(18, (row.enemy - row.friendly) * 6)
        elseif row.owner == "FRIENDLY" and row.friendly >= 5 and row.enemy <= 1 then
            state = "FRIENDLY_OVERCOMMITTED"
            excess = math.max(1, row.friendly - math.max(2, row.enemy + 1))
            score = 62 + math.min(25, excess * 6)
        elseif row.owner == "ENEMY" and row.enemy >= 5 and row.friendly <= 2 then
            state = "ENEMY_OVERCOMMITTED"
            excess = math.max(1, row.enemy - math.max(2, row.friendly + 1))
            score = 68 + math.min(25, excess * 5)
        elseif row.enemy > 0 and row.friendly >= 3 then
            state = "CAP_BLOCKED"
            score = 45 + math.min(20, row.enemy * 5)
        end
        if state and score > commitment.score then
            commitment.state = state
            commitment.score = KWR.Util:Clamp(score, 0, 100)
            commitment.objective = row.label
            commitment.excess = excess or 0
            commitment.evidence = {
                tostring(row.friendly) .. " friendly observed",
                tostring(row.enemy) .. " enemy observed",
                "owner " .. tostring(row.owner),
            }
        end
    end
    for _, coverage in ipairs(integrity.coverageLedger or {}) do
        if coverage.state == "UNCOVERED" and commitment.score < 88 then
            commitment.state = "UNDERDEFENDED"
            commitment.score = 88
            commitment.objective = coverage.location
            commitment.excess = 0
            commitment.evidence = {
                tostring(coverage.assigned or 0) .. " assigned",
                tostring(coverage.required or 1) .. " required",
                tostring(coverage.enemyKnown or 0) .. " enemy known",
            }
        elseif coverage.state == "OVERCOMMITTED"
            and commitment.score < 72 then
            commitment.state = "FRIENDLY_OVERCOMMITTED"
            commitment.score = 72
            commitment.objective = coverage.location
            commitment.excess = math.max(1,
                (coverage.assigned or 0) - (coverage.required or 1))
            commitment.evidence = {
                tostring(coverage.assigned or 0) .. " assigned",
                tostring(coverage.required or 1) .. " required",
            }
        end
    end

    local forecastTarget = intent.target
        or (reporter.hotspot and reporter.hotspot.label)
    local eta = findETA(reporter, forecastTarget)
    local reinforcement = {
        target = forecastTarget,
        friendlyETA = eta and eta.friendlyETA or nil,
        enemyETA = eta and eta.enemyETA or nil,
        advantage = eta and eta.advantageQualified == true and eta.advantage or nil,
        estimatedAdvantage = eta and eta.estimatedAdvantage or nil,
        advantageQualified = eta and eta.advantageQualified == true or false,
        friendlySource = eta and eta.friendlySource or nil,
        enemySource = eta and eta.enemySource or nil,
        confidence = eta and eta.confidence or "NONE",
        side = "UNKNOWN",
    }
    if reinforcement.advantage then
        reinforcement.side = reinforcement.advantage >= 3 and "FRIENDLY"
            or (reinforcement.advantage <= -3 and "ENEMY" or "EVEN")
    end

    local pressureScore = 0
    local pressureEvidence = {}
    if reporter.hotspot and reporter.hotspot.risk then
        pressureScore = pressureScore + reporter.hotspot.risk * 0.55
        pressureEvidence[#pressureEvidence + 1] =
            tostring(reporter.hotspot.risk) .. " hotspot risk"
    end
    if intent.target then
        pressureScore = pressureScore + (intent.confidenceScore or 0) * 0.35
        pressureEvidence[#pressureEvidence + 1] =
            tostring(intent.confidence or "LOW") .. " enemy intent"
    end
    if reinforcement.side == "ENEMY" then
        pressureScore = pressureScore + 15
        pressureEvidence[#pressureEvidence + 1] = "enemy reinforcements first"
    end
    pressureScore = KWR.Util:Clamp(pressureScore, 0, 100)
    local pressureForecast = {
        target = forecastTarget,
        score = pressureScore,
        state = not forecastTarget and "UNKNOWN"
            or (pressureScore >= 65 and "RISING"
            or (pressureScore >= 40 and "WATCH" or "STABLE")),
        eta = reinforcement.enemyETA,
        confidence = executionLabel(math.min(confidenceScore, pressureScore)),
        evidence = pressureEvidence,
    }

    local rotationEconomy = {
        target = forecastTarget,
        state = "UNKNOWN",
        value = 0,
        arrivalEdge = reinforcement.advantage,
        leavingCost = commitment.state == "UNDERDEFENDED" and "HIGH"
            or (commitment.state == "FRIENDLY_OVERCOMMITTED" and "LOW" or "MEDIUM"),
        evidence = {},
    }
    if reinforcement.advantage then
        rotationEconomy.value = KWR.Util:Clamp(
            50 + reinforcement.advantage * 3
                + (commitment.state == "FRIENDLY_OVERCOMMITTED" and 18 or 0)
                - (commitment.state == "UNDERDEFENDED" and 30 or 0),
            0, 100)
        rotationEconomy.state = rotationEconomy.value >= 65 and "WORTH_IT"
            or (rotationEconomy.value <= 35 and "NOT_WORTH_IT" or "MARGINAL")
        rotationEconomy.evidence = {
            "arrival edge " .. tostring(reinforcement.advantage) .. "s",
            "leaving cost " .. rotationEconomy.leavingCost,
        }
    end

    local friendlyDead = momentum.friendlyDead or 0
    local enemyDead = momentum.enemyDead or 0
    local collapseScore = math.max(0, -(momentum.value or 0)) * 0.55
        + math.max(0, friendlyDead - enemyDead) * 14
        + ((momentum.friendlyHealers or 0) == 0 and friendlyDead > 0 and 18 or 0)
        + (reporter.hotspot and math.max(0, reporter.hotspot.delta or 0) * 8 or 0)
        + math.max(0, -(resources.advantage or 0)) * 0.25
    collapseScore = KWR.Util:Clamp(collapseScore, 0, 100)
    local collapse = {
        score = collapseScore,
        state = collapseScore >= 70 and "CRITICAL"
            or (collapseScore >= 45 and "AT_RISK" or "STABLE"),
        response = collapseScore >= 70
            and ((prediction.urgency or 0) >= 85 and "STALL_OR_TRADE"
                or "DISENGAGE_RESET")
            or (collapseScore >= 45 and "PREPARE_EXIT" or "HOLD_PLAN"),
        confidence = executionLabel(math.min(confidenceScore, collapseScore + 20)),
        evidence = {
            tostring(friendlyDead) .. " friendly dead",
            tostring(enemyDead) .. " enemy dead",
            tostring(momentum.value or 0) .. " momentum",
        },
    }

    local recoveryScore = math.max(0, momentum.value or 0) * 0.45
        + enemyDead * 14 - friendlyDead * 8
        + (commitment.state == "FRIENDLY_OVERCOMMITTED" and 12 or 0)
        + ((resourceEnemy.deadHealers or 0) > 0 and 15 or 0)
    recoveryScore = KWR.Util:Clamp(recoveryScore, 0, 100)
    local recovery = {
        open = recoveryScore >= 45 and collapse.state == "STABLE",
        score = recoveryScore,
        response = recoveryScore >= 45 and "RESET_REASSIGN" or "CONTINUE",
        confidence = executionLabel(math.min(confidenceScore, recoveryScore + 20)),
    }

    local assignmentCount = #(assignments or {})
    local organizationScore = (integrity.abandoned or 0) * 24
        + (integrity.impossible or 0) * 14
        + (integrity.moving or 0) * 4
        + math.min(20, (integrity.unverified or 0) * 2)
        + (commitment.state == "FRIENDLY_OVERCOMMITTED" and 12 or 0)
        + (commitment.state == "UNDERDEFENDED" and 18 or 0)
        + (integrity.uncovered or 0) * 16
        + (integrity.overcommitted or 0) * 8
    if assignmentCount == 0 then organizationScore = 0 end
    organizationScore = KWR.Util:Clamp(organizationScore, 0, 100)
    local organization = {
        entropy = organizationScore,
        state = assignmentCount == 0 and "UNKNOWN"
            or (organizationScore >= 70 and "CRITICAL"
            or (organizationScore >= 45 and "DISRUPTED"
            or (organizationScore >= 20 and "STRAINED" or "ORDERED"))),
        abandoned = integrity.abandoned or 0,
        impossible = integrity.impossible or 0,
        moving = integrity.moving or 0,
        unverified = integrity.unverified or 0,
        uncovered = integrity.uncovered or 0,
        overcommitted = integrity.overcommitted or 0,
        confidence = assignmentCount > 0 and executionLabel(confidenceScore) or "NONE",
    }

    local actions = {
        { action = "HOLD_PLAN", score = 45, reason = "No stronger execution veto." },
    }
    if collapse.state == "CRITICAL" then
        actions[#actions + 1] = {
            action = collapse.response, score = 95,
            reason = "Fight collapse risk is critical.",
        }
    end
    if commitment.state == "UNDERDEFENDED" then
        actions[#actions + 1] = {
            action = "REINFORCE", score = 90,
            target = commitment.objective,
            reason = "A friendly objective is underdefended.",
        }
    elseif commitment.state == "ENEMY_OVERCOMMITTED" then
        actions[#actions + 1] = {
            action = "CONTAIN_TRADE", score = 86,
            target = commitment.objective,
            reason = "Enemy commitment exposes another objective.",
        }
    elseif commitment.state == "FRIENDLY_OVERCOMMITTED" then
        actions[#actions + 1] = {
            action = "REALLOCATE", score = 80,
            target = commitment.objective,
            reason = "Friendly manpower exceeds observed need.",
        }
    end
    if pressureForecast.state == "RISING" then
        actions[#actions + 1] = {
            action = "PREPARE_PRESSURE", score = 78,
            target = pressureForecast.target,
            reason = "Pressure forecast is rising.",
        }
    end
    if rotationEconomy.state == "WORTH_IT" then
        actions[#actions + 1] = {
            action = "ROTATE", score = 74,
            target = rotationEconomy.target,
            reason = "Arrival advantage exceeds leaving cost.",
        }
    end
    if recovery.open then
        actions[#actions + 1] = {
            action = "RESET_REASSIGN", score = 68,
            reason = "A bounded recovery window is open.",
        }
    end
    table.sort(actions, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.action < b.action
    end)

    local result = {
        active = true,
        confidenceScore = math.floor(confidenceScore + 0.5),
        confidence = executionLabel(confidenceScore),
        commitment = commitment,
        pressureForecast = pressureForecast,
        reinforcement = reinforcement,
        rotationEconomy = rotationEconomy,
        collapse = collapse,
        recovery = recovery,
        organization = organization,
        actionOpportunity = actions[1],
        alternatives = actions,
        horizons = {
            immediate = {
                seconds = 5,
                state = collapse.state == "CRITICAL"
                    and collapse.response
                    or actions[1].action,
                target = actions[1].target,
            },
            engagement = {
                seconds = 15,
                state = pressureForecast.state,
                target = pressureForecast.target,
                reinforcement = reinforcement.side,
            },
            strategic = {
                seconds = 30,
                state = prediction.status or "WAITING",
                target = snapshot.strategy
                    and snapshot.strategy.objectiveDecision
                    and snapshot.strategy.objectiveDecision.target,
            },
        },
    }
    self.executionCache = {
        signature = executionSignature,
        at = executionNow,
        result = KWR.Util:Copy(result),
    }
    return result
end

KWR:RegisterModule("Strategist", Strategist)
