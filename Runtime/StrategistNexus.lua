local _, KWR = ...

local StrategistNexus = {}
KWR.StrategistNexus = StrategistNexus

local function scoreState(prediction, phase)
    local status = KWR.Util:Upper(prediction and prediction.status, "WAITING", 16)
    local urgency = KWR.Util:Number(prediction and prediction.urgency, 0) or 0
    if urgency >= 88 then
        return "EMERGENCY"
    end
    if status == "WIN" then return "FAVORABLE" end
    if status == "LOSE" then return "UNFAVORABLE" end
    if status == "TIE" or status == "CONTEST" then return "TIED" end
    return "SAFE_DEFAULT"
end

local function evidenceState(snapshot, result)
    local truth = snapshot.truth or {}
    local knowledge = snapshot.knowledgeStatus or {}
    local budget = result.confidenceBudget or {}
    if truth.coreFresh == true and knowledge.compositionAuthorized ~= false then
        return "LIVE_KNOWN"
    end
    if truth.coreFresh == true then return "OBSERVED" end
    if (budget.score or 0) >= 55 then return "DERIVED" end
    if knowledge.compositionAuthorized == false then return "META_ONLY" end
    return "UNKNOWN"
end

local function averageRating(summary, category)
    local known = math.max(0, KWR.Util:Number(summary and summary.knownSpecs, 0) or 0)
    if known == 0 then return nil end
    return (KWR.Util:Number(summary.ratings and summary.ratings[category], 0) or 0) / known
end

local function capabilityAdjustment(ours, enemy, focus)
    local enemyCoverage = KWR.Util:Clamp(enemy and enemy.coverage or 0, 0, 1)
    local ourCoverage = KWR.Util:Clamp(ours and ours.coverage or 0, 0, 1)
    local coverage = math.min(ourCoverage, enemyCoverage)
    if coverage <= 0 then return 0, "enemy capability coverage unavailable" end
    local weighted, weights = 0, 0
    for category, weight in pairs(focus or {}) do
        local ourRating = averageRating(ours, category)
        local enemyRating = averageRating(enemy, category)
        if ourRating and enemyRating then
            weighted = weighted + (ourRating - enemyRating) * weight
            weights = weights + weight
        end
    end
    if weights <= 0 then return 0, "candidate capability profile unavailable" end
    local raw = (weighted / weights) * 3 * coverage
    local adjustment = math.floor(KWR.Util:Clamp(raw, -8, 8) + (raw >= 0 and 0.5 or -0.5))
    return adjustment, string.format("capability edge %.2f at %d%% coverage",
        weighted / weights, math.floor(coverage * 100 + 0.5))
end

local function fallbackCandidate(candidates, primaryID)
    for _, candidate in ipairs(candidates or {}) do
        if candidate.id ~= primaryID and candidate.legal ~= false
            and candidate.reversible == true then
            return candidate
        end
    end
    for _, candidate in ipairs(candidates or {}) do
        if candidate.id ~= primaryID and candidate.legal ~= false then
            return candidate
        end
    end
end

local function alternativeReview(candidates)
    local rows = {}
    local primary = candidates and candidates[1]
    for index = 2, math.min(3, #(candidates or {})) do
        local candidate = candidates[index]
        rows[#rows + 1] = {
            id = candidate.id,
            target = candidate.target,
            score = candidate.decisionScore or candidate.probability or 0,
            legal = candidate.legal ~= false,
            reason = candidate.legal == false and (candidate.ruleReason or "objective rule gate")
                or ((candidate.decisionScore or 0) + 6 < (primary and primary.decisionScore or 0)
                    and "lower Nexus decision score" or "weaker bounded edge"),
        }
    end
    return rows
end

function StrategistNexus:Rank(snapshot, prediction, result)
    if type(result) ~= "table" or type(result.simulations) ~= "table"
        or not KWR.StrategistNexusPolicy or not KWR.StrategistNexusCorpus
        or not KWR.StrategistNexusKnowledge then
        return result
    end
    local phase = result.phase or result.state or "PRESSURE"
    local state = scoreState(prediction, phase)
    local enemyArchetype = result.enemyComposition and result.enemyComposition.id or "BALANCED"
    local compWatch, compWatchSource = KWR.StrategistNexusPolicy:CompWatch(
        result.enemyTier, enemyArchetype)
    local liveEvidence = evidenceState(snapshot, result)
    local budgetScore = result.confidenceBudget and result.confidenceBudget.score or 0
    local mapKey = snapshot.context and snapshot.context.mapKey
    local knowledgeCoverage = KWR.StrategistNexusKnowledge:Coverage(mapKey, phase)

    for _, candidate in ipairs(result.simulations) do
        local responseID = candidate.enemyResponsePlan
            and candidate.enemyResponsePlan.responseID or "ROTATION_MIRROR"
        local counterResponse = KWR.StrategistNexusPolicy:ResponseCategory(responseID)
        local family = KWR.StrategistNexusPolicy:Family(phase, candidate.id)
        local simulationCoverage = KWR.StrategistNexusCorpus:Coverage(
            mapKey,
            phase,
            {
                family = family,
                compWatch = compWatch,
                scoreState = state,
                counterResponse = counterResponse,
                evidenceState = liveEvidence,
            })
        local capability, capabilityReason = capabilityAdjustment(
            result.ourSummary, result.enemySummary,
            KWR.StrategistNexusPolicy:Focus(candidate.id))
        local archetype = KWR.StrategistNexusPolicy:ArchetypeAdjustment(
            enemyArchetype, candidate.id)
        local score = KWR.StrategistNexusPolicy:ScoreAdjustment(state, candidate.id)
        local discipline = 0
        if budgetScore < 55 then
            discipline = candidate.reversible == true and 2 or -4
        end
        -- The generated corpus proves this branch was exercised. It does not
        -- contain empirical outcomes, so it may only penalize missing coverage.
        local coverageGuard = simulationCoverage.available and 0 or -3
        local total = KWR.Util:Clamp(
            capability + archetype + score + discipline + coverageGuard, -16, 16)
        local original = candidate.decisionScore or candidate.probability or 0
        if candidate.legal ~= false then
            candidate.decisionScore = math.floor(KWR.Util:Clamp(original + total, 5, 95) + 0.5)
            candidate.probability = candidate.decisionScore
            candidate.projection = candidate.decisionScore >= 70 and "FAVORABLE"
                or (candidate.decisionScore >= 50 and "VIABLE" or "WEAK")
        end
        candidate.nexus = {
            schemaVersion = 1,
            originalScore = original,
            adjustment = candidate.legal ~= false and total or 0,
            capabilityAdjustment = capability,
            capabilityReason = capabilityReason,
            archetypeAdjustment = archetype,
            scoreStateAdjustment = score,
            disciplineAdjustment = discipline,
            coverageGuardAdjustment = coverageGuard,
            family = family,
            scoreState = state,
            counterResponse = counterResponse,
            compWatch = compWatch,
            compWatchSource = compWatchSource,
            evidenceState = liveEvidence,
            simulationCoverage = KWR.Util:Copy(simulationCoverage),
            knowledgeCoverage = KWR.Util:Copy(knowledgeCoverage),
            theoryActivated = simulationCoverage.available == true
                and knowledgeCoverage.available == true,
            activation = "IMMEDIATE_THEORY_FIRST",
            authority = "THEORY_POLICY_WITH_REVIEWED_KNOWLEDGE",
        }
    end

    table.sort(result.simulations, function(a, b)
        if (a.legal ~= false) ~= (b.legal ~= false) then return a.legal ~= false end
        if (a.decisionScore or 0) ~= (b.decisionScore or 0) then
            return (a.decisionScore or 0) > (b.decisionScore or 0)
        end
        return a.id < b.id
    end)

    local selected = result.simulations[1]
    if selected then
        result.selectedAction = KWR.Util:Copy(selected)
        -- The winning Nexus candidate is executable strategy, not envelope-only metadata.
        result.action = selected.id .. ": " .. KWR.Util:Text(selected.outcome,
            "Execute the selected objective action.", 180)
        result.target = selected.target or result.target
        result.reason = KWR.Util:Text(selected.outcome, result.reason, 220)
        result.switchIf = KWR.Util:Text(selected.abort, result.switchIf, 180)
        result.stop = KWR.Util:Text(selected.abort, result.stop, 180)
        result.expectedOutcome = selected.outcome
        result.recommendationMode = selected.id
        result.projectedWinProbability = selected.probability
        result.decisionScore = selected.decisionScore
        result.projection = selected.projection
        result.enemyResponsePlan = KWR.Util:Copy(selected.enemyResponsePlan)
        result.enemyResponseID = selected.enemyResponsePlan
            and selected.enemyResponsePlan.responseID or nil
        result.enemyResponseSummary = selected.enemyResponsePlan
            and selected.enemyResponsePlan.summary or nil
        result.consequenceScore = selected.enemyResponsePlan
            and selected.enemyResponsePlan.consequenceAdjustment or 0
    end
    result.alternativeReview = alternativeReview(result.simulations)
    result.nexusFallbackCandidate = KWR.Util:Copy(fallbackCandidate(
        result.simulations, selected and selected.id))
    result.nexusContext = {
        schemaVersion = 1,
        phase = phase,
        scoreState = state,
        enemyArchetype = enemyArchetype,
        compWatch = compWatch,
        compWatchSource = compWatchSource,
        evidenceState = liveEvidence,
        productionStatus = KWR.StrategistNexusKnowledge:Status(),
        productionPatch = KWR.StrategistNexusKnowledge:Patch(),
        contract = KWR.StrategistNexusKnowledge:Shared(),
        knowledgeCoverage = KWR.Util:Copy(knowledgeCoverage),
        liveEvidence = KWR.StrategistNexusKnowledge:LiveEvidence(),
        simulationStatus = KWR.StrategistNexusCorpus:Status(),
        simulationActivation = KWR.StrategistNexusCorpus:Activation(),
        simulationCases = KWR.StrategistNexusCorpus:Count(),
        simulationPatch = KWR.StrategistNexusCorpus:Patch(),
    }
    return result
end

local function candidateAction(candidate, defaultTarget)
    candidate = type(candidate) == "table" and candidate or {}
    local action = KWR.Util:Text(candidate.action, "", 180)
    if action ~= "" then return action end
    local id = KWR.Util:Text(candidate.id, "HOLD", 40)
    local outcome = KWR.Util:Text(candidate.outcome, "", 180)
    if outcome ~= "" then return id .. ": " .. outcome end
    local target = KWR.Util:Text(candidate.target or defaultTarget,
        "the mapped objective", 96)
    return "Execute " .. id .. " at " .. target .. " if the primary aborts."
end

function StrategistNexus:Envelope(snapshot, prediction, result)
    if type(result) ~= "table" then return nil end
    local selected = result.selectedAction or {}
    local fallback = result.nexusFallbackCandidate or {}
    local response = selected.enemyResponsePlan or result.enemyResponsePlan or {}
    local contract = result.responseContract or {}
    local context = result.nexusContext or {}
    local knowledge = context.knowledgeCoverage or {}
    local live = context.liveEvidence or {}
    local nexusContract = context.contract or {}
    return {
        schemaVersion = 1,
        primary = {
            id = result.recommendationMode or selected.id or "VERIFY",
            action = result.action,
            target = result.target or selected.target,
            score = result.decisionScore,
            outcome = result.expectedOutcome or selected.outcome,
            basis = result.projectionBasis or "IMMEDIATE_THEORY_FIRST",
        },
        fallback = {
            id = fallback.id or "HOLD",
            target = fallback.target,
            action = candidateAction(fallback, result.target or selected.target),
            score = fallback.decisionScore,
        },
        enemyResponse = {
            id = response.responseID or "ROTATION_MIRROR",
            pattern = response.enemyPattern or contract.likelyCounter,
            trigger = response.trigger,
            safestReply = response.safestReply or contract.counterResponse,
        },
        success = selected.success or contract.success,
        abort = result.stop or selected.abort or contract.abort,
        mustStay = KWR.Util:Copy(contract.playersWhoStay or {}),
        requiredEvidence = KWR.Util:Copy(contract.requiredEvidence or {}),
        confidence = result.trust and result.trust.label or result.confidence or "NONE",
        commitAuthorized = result.trust and result.trust.commitAuthorized == true,
        executionGate = KWR.Util:Copy(result.executionGate or {}),
        provenance = {
            sourceStatus = context.productionStatus or "UNAVAILABLE",
            authority = nexusContract.authority,
            developerGate = nexusContract.developerGate,
            activation = nexusContract.activation or "IMMEDIATE_THEORY_FIRST",
            liveEvidenceRole = nexusContract.liveEvidenceRole,
            simulationStatus = context.simulationStatus or "UNAVAILABLE",
            simulationActivation = context.simulationActivation,
            simulationAuthority = nexusContract.simulationAuthority
                or "THEORY_BRANCH_ACTIVATION_NON_EMPIRICAL",
            totalSimulationCases = context.simulationCases or 0,
            marginalCases = selected.nexus and selected.nexus.simulationCoverage
                and selected.nexus.simulationCoverage.marginalCases or 0,
            reviewedLabels = knowledge.reviewedLabels or 0,
            reviewedCases = knowledge.reviewedCases or 0,
            adversarialCases = knowledge.adversarialCases or 0,
            doctrineComparisons = knowledge.doctrineComparisons or 0,
            doctrineResponses = knowledge.doctrineResponses or 0,
            capturedLiveMatches = live.capturedMatches or 0,
            reviewedLiveMatches = live.reviewedMatches or 0,
            reviewedLearningSamples = live.reviewedLearningSamples or 0,
            learnedPlans = live.learnedPlans or 0,
            livePromotion = live.promotion or "PLAYER_REVIEW_REQUIRED",
            patch = context.productionPatch,
            simulationPatch = context.simulationPatch,
            mapKey = snapshot.context and snapshot.context.mapKey,
            phase = context.phase,
            scoreState = context.scoreState,
            compWatch = context.compWatch,
            evidenceState = context.evidenceState,
        },
    }
end

KWR:RegisterModule("StrategistNexus", StrategistNexus)
