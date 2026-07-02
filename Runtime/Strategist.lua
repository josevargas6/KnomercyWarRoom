local _, KWR = ...

local Strategist = {
    cache = nil,
    cacheHits = 0,
    cacheMisses = 0,
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
    add(objectives.friendly)
    add(objectives.enemy)
    add(objectives.friendlyIncoming)
    add(objectives.enemyIncoming)
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
    local combat = snapshot.combat or {}
    local resources = combat.resourceEconomy or {}
    add("score", 15, snapshot.score and snapshot.score.source == "ui_widget",
        snapshot.score and snapshot.score.source)
    add("objectives", 15,
        snapshot.objectives and snapshot.objectives.source == "ui_widget",
        snapshot.objectives and snapshot.objectives.source)
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
    local momentum = reporter.momentum and reporter.momentum.value or 0
    local resources = snapshot.combat and snapshot.combat.resourceEconomy or {}
    local resourceAdvantage = resources.advantage or 0
    local ratings, enemyRatings = ourSummary.ratings or {}, enemySummary.ratings or {}
    local etaEdge = 0
    for _, eta in ipairs(reporter.etas or {}) do
        if eta.advantage then etaEdge = math.max(etaEdge, eta.advantage) end
    end
    local candidates = {
        {
            id = "HOLD",
            probability = 48 + (prediction.status == "WIN" and 20 or -5)
                + ((ratings.nodeDefense or 1) - 2) * 4
                + (budget.score < 50 and 10 or 0),
            outcome = "Preserve the current scoring requirement.",
            risk = "May surrender initiative if the enemy has a free weak-side objective.",
        },
        {
            id = "ROTATE",
            probability = 45 + ((ratings.mobility or 1) - 2) * 5
                + KWR.Util:Clamp(etaEdge, -12, 12)
                + (reporter.enemyIntent and reporter.enemyIntent.target and 6 or 0),
            outcome = "Arrive before the enemy commitment and stabilize the next objective.",
            risk = "A late or unverified rotation can expose the objective being left.",
        },
        {
            id = "TRADE",
            probability = 40 + ((ratings.splitPush or 1) - 2) * 6
                + (prediction.status == "LOSE" and 12 or 0)
                - (budget.score < 50 and 10 or 0),
            outcome = "Exchange the least valuable exposed objective for a better scoring lane.",
            risk = "The trade fails if defenders leave before the capture is secured.",
        },
        {
            id = "TEAMFIGHT",
            probability = 44 + ((ratings.teamfight or 1)
                - (enemyRatings.teamfight or 1)) * 7
                + opportunity.score * 0.18 + momentum * 0.08
                + resourceAdvantage * 0.10,
            outcome = "Convert the temporary combat advantage into objective control.",
            risk = "The fight has no value if it occurs away from the scoring requirement.",
        },
        {
            id = "SPLIT",
            probability = 41 + ((ratings.splitPush or 1)
                - (enemyRatings.mobility or 1)) * 6
                + (reporter.enemyIntent and reporter.enemyIntent.groupSize or 0) * 2
                - (budget.score < 55 and 8 or 0),
            outcome = "Force the enemy composition to defend separate scoring threats.",
            risk = "Split pressure becomes two losing fights without confirmed timing.",
        },
    }
    for _, candidate in ipairs(candidates) do
        candidate.probability = math.floor(KWR.Util:Clamp(
            candidate.probability, 5, 95) + 0.5)
    end
    table.sort(candidates, function(a, b)
        if a.probability ~= b.probability then return a.probability > b.probability end
        return a.id < b.id
    end)
    return candidates
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
    local counter = KWR.Counters:Get(enemyComposition.id)
    if enemyTier and enemyTier.qualified then
        counter = {
            emphasis = enemyTier.counter,
            avoid = "Do not let " .. enemyTier.name .. " execute: " .. enemyTier.win,
            source = enemyTier.source,
            confidence = enemyTier.confidence,
        }
    end
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
    if prediction.status == "WAITING" and currentState ~= "OPENING" then
        result.reason = "Authoritative battlefield truth is incomplete; no live plan is selected."
        result.confidence = "NONE"
        return result
    end

    for _, battlePlan in ipairs(KWR.BattlePlans:Get(snapshot.context.mapKey)) do
        local feasible, missing = requirementFit(ourSummary, battlePlan.requires)
        local score = 0
        local focus = planFocus(snapshot.context.kind, battlePlan.state, currentState)
        local readiness, matchup = capabilityFit(ourSummary, enemySummary, focus)
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
    result.opportunity = opportunity
    result.simulations = simulations
    result.expectedOutcome = simulations[1] and simulations[1].outcome
    result.recommendationMode = simulations[1] and simulations[1].id
    result.projectedWinProbability = simulations[1] and simulations[1].probability
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
        result.action = scenario.action
        result.objectiveDecision = KWR.Util:Copy(scenario.objectiveDecision)
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
    if budget.score < 40 and currentState ~= "OPENING" then
        result.action = "Protect the current scoring requirement, verify enemy movement, then reassess."
        result.reason = "Evidence coverage is too low for an aggressive commitment."
        result.stop = "Do not commit a split or long rotation from unverified information."
        result.recommendationMode = "HOLD"
        result.expectedOutcome = "Preserve score while rebuilding battlefield confidence."
    elseif opportunity.open and budget.score >= 55
        and result.recommendationMode == "TEAMFIGHT" then
        result.reason = result.reason .. " WINDOW: "
            .. table.concat(opportunity.evidence, ", ") .. "."
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
    }
end

KWR:RegisterModule("Strategist", Strategist)
