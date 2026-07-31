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
        or (truth.coreFresh == false and "Cor…8272 tokens truncated…emyCarrier.stacks or 0
            if enemyStacks < 3 then
                result.action = "Stabilize our flag carrier, regroup offense, and deny trickle deaths."
                result.reason = "Both flags are held; coordinated offense becomes more actionable as carrier pressure rises."
                result.switchIf = "Push the grouped return when enemy carrier stacks or exposed defenses create a real kill window."
                result.stop = "Do not trickle into a healthy, fully supported low-stack carrier."
            else
                result.action = "Push one grouped return team onto the stacked enemy flag carrier while preserving our carrier peel."
                result.reason = "Enemy carrier pressure is now actionable; synchronize healer control and burst."
                result.stop = "Do not send isolated players ahead of the return group."
            end
        end
    elseif snapshot.context.kind == "ORB" then
        local endangered
        for _, carrier in ipairs(carriers) do
            if carrier.owner == "FRIENDLY" and carrier.healthPercent
                and carrier.healthPercent <= 35 then endangered = carrier break end
        end
        if endangered then
            result.action = "Prepare a replacement at " .. endangered.objective
                .. " and peel the current carrier toward supported scoring space."
            result.reason = "A low-health orb carrier needs an intentional handoff or immediate peel, not an unplanned loss."
        end
    end
    local truth = snapshot.truth or {}
    result.trust = trustModel(snapshot, prediction, budget, simulations, result.selectedAction)
    if (budget.score < 40 or truth.coreFresh == false)
        and currentState ~= "OPENING" then
        result.action = "Protect the current scoring requirement, verify enemy movement, then reassess."
        result.reason = truth.conservativeReason
            or "Evidence coverage is too low for an aggressive commitment."
        result.stop = "Do not commit a split or long rotation from unverified information."
        result.recommendationMode = "HOLD"
        result.expectedOutcome = "Preserve score while rebuilding battlefield confidence."
        result.projectedWinProbability = nil
        result.decisionScore = simulations[1]
            and simulations[1].decisionScore or nil
    elseif snapshot.knowledgeStatus
        and snapshot.knowledgeStatus.compositionAuthorized == false
        and currentState ~= "OPENING" then
        result.action = "Play the map, protect coverage, and avoid composition-dependent commits until specs are verified."
        result.reason = snapshot.knowledgeStatus.reason
        result.stop = "Do not force comp-specific swaps or split calls from historical or incomplete spec truth."
        result.recommendationMode = "VERIFY"
        result.expectedOutcome = "Stabilize around map fundamentals while composition certainty improves."
    elseif result.trust and result.trust.commitAuthorized == false
        and currentState ~= "OPENING" then
        result.action = "Verify enemy movement, protect the score floor, and probe with reversible movement only."
        result.reason = result.trust.reason
        result.stop = "Do not split or hard-commit from thin movement confidence."
        result.recommendationMode = "VERIFY"
        result.expectedOutcome = "Reduce uncertainty before the next decisive commit."
    elseif opportunity.open and budget.score >= 55
        and result.recommendationMode == "TEAMFIGHT" then
        result.reason = result.reason .. " WINDOW: "
            .. table.concat(opportunity.evidence, ", ") .. "."
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
        advantage = eta and eta.advantage or nil,
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