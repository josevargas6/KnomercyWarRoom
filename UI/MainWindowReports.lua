local _, KWR = ...

local MainWindowReports = {}
KWR.MainWindowReports = MainWindowReports

local function roundedNumber(value)
    local number = tonumber(value)
    if not number then return 0 end
    return math.floor(number + 0.5)
end

local function topCounterText(counts, limit)
    local entries = {}
    for name, count in pairs(type(counts) == "table" and counts or {}) do
        entries[#entries + 1] = { name = name, count = tonumber(count) or 0 }
    end
    table.sort(entries, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)
    local result = {}
    for index = 1, math.min(limit or 5, #entries) do
        result[#result + 1] = entries[index].name .. " " .. tostring(entries[index].count)
    end
    return #result > 0 and table.concat(result, ", ") or "none"
end

function MainWindowReports:BuildExplainPayload(state, helpers)
    helpers = helpers or {}
    local command = state.command
    local strategy = state.snapshot.strategy or {}
    local formation = state.snapshot.formation or {}
    if not state.snapshot.context.inPvP then
        local recruits, positioning = {}, {}
        local currentComp = formation.currentComp
            or (formation.tierMatch and formation.tierMatch.qualified
                and formation.tierMatch or nil)
        local targetComp = formation.buildTarget
        for _, recruit in ipairs(formation.recommendations or {}) do
            recruits[#recruits + 1] = recruit.label .. " ["
                .. tostring(recruit.acquisition or "OPEN SLOT") .. "] - " .. recruit.reason
        end
        for index, text in ipairs(formation.positioning or {}) do
            positioning[#positioning + 1] = tostring(index) .. ". " .. text
        end
        return "KWR Setup Plan", table.concat({
            "COMMAND UNIT SETUP",
            tostring(formation.players or 0) .. " / " .. tostring(formation.targetSize or 10) .. " players",
            "NEED: " .. tostring(formation.needText or "Roster complete"),
            "CURRENT: " .. tostring(currentComp
                and (tostring(currentComp.tier or "") .. " " .. tostring(currentComp.name or ""))
                or (formation.archetype and formation.archetype.name or "Balanced Team Fight")),
            "TARGET: " .. tostring(targetComp
                and (tostring(targetComp.tier or "") .. " " .. tostring(targetComp.name or ""))
                or "Work the current shell"),
            "MATCH: " .. tostring(formation.tierMatch and formation.tierMatch.confidence or "GENERIC"),
            "HOW IT WINS: " .. tostring(currentComp and (currentComp.win or currentComp.description)
                or (formation.archetype and formation.archetype.description
                    or "Flexible objective play.")),
            "ROLE PACKAGE: " .. tostring(currentComp and currentComp.assignments
                or "Use capability-weighted setup roles."),
            "",
            "BEST RECRUITS:",
            #recruits > 0 and table.concat(recruits, "\n") or "Roster complete.",
            "",
            "POSITIONING KEYS:",
            table.concat(positioning, "\n"),
        }, "\n")
    end

    local alternatives = {}
    for _, alternative in ipairs(strategy.alternatives or {}) do
        alternatives[#alternatives + 1] = (alternative.feasible and "READY  " or "BLOCKED  ")
            .. alternative.id .. " - " .. alternative.action
    end
    local learning = KWR.Learning:Summary()
    local decision = strategy.objectiveDecision or {}
    local counter = strategy.counter or {}
    local confidenceEvidence = {}
    for _, item in ipairs(strategy.confidenceBudget and strategy.confidenceBudget.evidence or {}) do
        confidenceEvidence[#confidenceEvidence + 1] =
            (item.available and "YES " or "NO  ") .. item.name
            .. " [" .. tostring(roundedNumber(item.points or 0)) .. "]"
            .. (item.detail and (" - " .. tostring(item.detail)) or "")
    end
    local simulations = {}
    for _, candidate in ipairs(strategy.simulations or {}) do
        simulations[#simulations + 1] = string.format(
            "%s score %d [%s] @ %s - %s RISK: %s",
            candidate.id, roundedNumber(candidate.decisionScore or candidate.probability or 0),
            candidate.projection or "UNKNOWN",
            candidate.target or "unverified",
            candidate.outcome or "Unknown",
            candidate.risk or "Unknown")
    end
    local reporter = state.snapshot.reporter or {}
    local etaLines = {}
    for index = 1, math.min(3, #(reporter.etas or {})) do
        local eta = reporter.etas[index]
        etaLines[#etaLines + 1] = string.format(
            "%s F:%s E:%s edge:%s [%s]",
            eta.label,
            eta.friendlyETA and (tostring(eta.friendlyETA) .. "s") or "?",
            eta.enemyETA and (tostring(eta.enemyETA) .. "s") or "?",
            eta.advantage and (tostring(eta.advantage) .. "s") or "?",
            eta.confidence or "LOW")
    end
    local opportunity = strategy.opportunity or {}
    local intent = reporter.enemyIntent or {}
    local momentum = reporter.momentum or {}
    local resources = state.snapshot.combat and state.snapshot.combat.resourceEconomy or {}
    local integrity = state.snapshot.assignmentIntegrity or {}
    local execution = strategy.executionAssessment or {}
    local executionAction = execution.actionOpportunity or {}
    local commitment = execution.commitment or {}
    local pressureForecast = execution.pressureForecast or {}
    local reinforcement = execution.reinforcement or {}
    local rotationEconomy = execution.rotationEconomy or {}
    local collapse = execution.collapse or {}
    local recovery = execution.recovery or {}
    local organization = execution.organization or {}
    local response = state.snapshot.responsePackage or {}
    local truth = state.snapshot.truth or {}
    local truthSummary = truth.summary or {}
    local responseContract = strategy.responseContract or {}
    local objectiveRules = strategy.objectiveRules or {}
    local strategyTrust = strategy.trust or {}
    local knowledge = state.snapshot.knowledgeStatus or {}
    local horizons = execution.horizons or {}
    local overrides = KWR.AssignmentOverrides and KWR.AssignmentOverrides:DescribeActive(
        state.snapshot, state.assignments) or {}
    local integrityLines = {}
    for _, row in ipairs(integrity.reassignments or {}) do
        integrityLines[#integrityLines + 1] = row.name .. " " .. row.status
            .. " @ " .. row.actual .. " -> " .. row.expected
            .. " | replace: " .. tostring(row.replacement or "nearest floater")
    end
    local coverageLines = {}
    for _, row in ipairs(integrity.coverageLedger or {}) do
        coverageLines[#coverageLines + 1] = string.format(
            "%s %s | %d/%d | backup %s | enemy-known %d",
            row.location or "Unknown", row.state or "UNKNOWN",
            roundedNumber(row.assigned or 0), roundedNumber(row.required or 0),
            row.backup or "none", roundedNumber(row.enemyKnown or 0))
    end
    local line1, line2, line3 = KWR.CommandView:SummaryLines(state)
    local ourComposition = strategy.ourTier and strategy.ourTier.qualified
        and (strategy.ourTier.tier .. " " .. strategy.ourTier.name)
        or (strategy.ourComposition and strategy.ourComposition.name or "Unknown")
    local enemyComposition = strategy.enemyTier and strategy.enemyTier.qualified
        and (strategy.enemyTier.tier .. " " .. strategy.enemyTier.name)
        or (strategy.enemyComposition and strategy.enemyComposition.name or "Unknown")

    return "KWR Command Review", table.concat({
        line1,
        line2,
        line3,
        "",
        "BOTTOM LINE:",
        "ACTION: " .. tostring(response.action or command.action or "Hold current plan."),
        "WHO: " .. tostring(response.moverText or command.who or "Team"),
        "HOLD: " .. tostring(response.stayerText or "Assigned defenders"),
        "TRIGGER: " .. tostring(decision.success or command.switchIf or command.when or "NOW"),
        "RESET: " .. tostring(decision.abort or "Reassess when the scoring path changes."),
        "",
        "WHY THIS CALL:",
        "PLAN: " .. tostring(command.planID or "No reviewed plan"),
        "OUR COMPOSITION: " .. tostring(ourComposition),
        "ENEMY COMPOSITION: " .. tostring(enemyComposition),
        "REASON: " .. tostring(command.reason),
        string.format("DECISION: %s | score %s/100 [%s; heuristic] | confidence %s/100 %s | risk %s",
            tostring(strategy.recommendationMode or "HOLD"),
            tostring(strategy.decisionScore or 0),
            tostring(strategy.projection or "UNKNOWN"),
            tostring(strategy.confidenceBudget and strategy.confidenceBudget.score or 0),
            tostring(strategy.confidence or "NONE"),
            tostring(strategy.risk or "HIGH")),
        "EXPECTED: " .. tostring(strategy.expectedOutcome or "Unknown"),
        "ENEMY ANSWER: " .. tostring(counter.emphasis or "No composition counter available."),
        "MAIN FOCUS: " .. tostring(
            helpers.weightedFocusText and helpers.weightedFocusText(strategy)
                or strategy.weightedFocus and strategy.weightedFocus.summary
                or strategy.state
                or "Objective play"),
        "SAFER BRANCH: " .. tostring(command.branchChoice or strategy.comparisonChoice or "Hold the reviewed line."),
        "SAFE COUNTER: " .. tostring(command.safeCounter or strategy.safeCounterAction or "Protect the score path first."),
        "SUCCESS WHEN: " .. tostring(decision.success or "The objective changes as called."),
        "ABORT WHEN: " .. tostring(decision.abort or "The scoring path or commitment changes."),
        "RESPONSE CHAIN: " .. tostring(counter.sequence
            and table.concat(counter.sequence, " -> ") or "No reviewed sequence available."),
        "SWITCH IF: " .. tostring(command.switchIf or "Authoritative state changes."),
        "DO NOT: " .. tostring(counter.avoid or strategy.stop or "Take low-value fights."),
        string.format("DATA: %d%% usable | verified %d | stale %d | aggressive commit %s",
            roundedNumber(truthSummary.coverage or 0), roundedNumber(truthSummary.verified or 0),
            roundedNumber(truthSummary.stale or 0),
            truth.aggressiveCommitAllowed and "ALLOWED" or "GATED"),
        string.format("OBJECTIVE RULES: %s | minimum control %s | legal %s | blocked %s",
            tostring(objectiveRules.family or state.snapshot.context.kind or "WORLD"),
            tostring(strategy.minimumControlToWin or "?"),
            #(strategy.legalActions or {}) > 0 and table.concat(strategy.legalActions, ", ") or "none",
            #(strategy.impossibleActions or {}) > 0 and table.concat(strategy.impossibleActions, ", ") or "none"),
        "NEXT TRIGGER: " .. tostring(responseContract.trigger or "Unverified"),
        "LIKELY ENEMY ANSWER: " .. tostring(responseContract.likelyCounter or "Unknown"),
        "OUR RESPONSE: " .. tostring(responseContract.counterResponse or "Verify then reassess."),
        string.format("READINESS: %s | patch aligned %s | enemy certainty %d%% | historical %d",
            tostring(knowledge.label or "NONE"),
            knowledge.patchAligned and "YES" or "NO",
            roundedNumber((knowledge.enemyCoverage or 0) * 100),
            roundedNumber(knowledge.enemyHistorical or 0)),
        string.format("CALL READ: %s / %s / %s",
            tostring(strategyTrust.label or "NONE"),
            tostring(strategyTrust.mode or "VERIFY"),
            tostring(strategyTrust.reason or "Unknown")),
        "",
        "WHY THIS READ:",
        #confidenceEvidence > 0 and table.concat(confidenceEvidence, "\n") or "No qualified evidence.",
        "",
        "CANDIDATE SIMULATION:",
        #simulations > 0 and table.concat(simulations, "\n") or "Unavailable.",
        "",
        "TIMING / ENEMY PLAN:",
        #etaLines > 0 and table.concat(etaLines, "\n") or "No legal coordinate ETA.",
        "Enemy intent: " .. tostring(intent.target or "Unknown")
            .. " | " .. tostring(intent.confidence or "NONE")
            .. " | ETA " .. tostring(intent.eta or "?") .. "s",
        "Pressure trend: " .. tostring(momentum.state or "UNKNOWN")
            .. " " .. tostring(momentum.value or 0)
            .. " | " .. tostring(momentum.confidence or "LOW"),
        "",
        "OPPORTUNITY WINDOW: " .. (opportunity.open and "OPEN" or "CLOSED")
            .. " | " .. tostring(opportunity.duration or 0) .. "s | "
            .. tostring(opportunity.confidence or "LOW"),
        #(opportunity.evidence or {}) > 0 and table.concat(opportunity.evidence, ", ")
            or "No verified temporary advantage.",
        string.format("RESOURCE ECONOMY: edge %d | %s | enemy trinkets %d, defensives used %d, active %d",
            roundedNumber(resources.advantage or 0), resources.confidence or "NONE",
            roundedNumber(resources.enemy and resources.enemy.trinketsUsed or 0),
            roundedNumber(resources.enemy and resources.enemy.defensivesUsed or 0),
            roundedNumber(resources.enemy and resources.enemy.activeDefensives or 0)),
        "",
        "HOW THE FIGHT SETS UP:",
        string.format("Best action: %s @ %s | score %d | confidence %s/%d",
            tostring(executionAction.action or "UNKNOWN"),
            tostring(executionAction.target or commitment.objective or "Unknown"),
            roundedNumber(executionAction.score or 0),
            tostring(execution.confidence or "NONE"),
            roundedNumber(execution.confidenceScore or 0)),
        "Reason: " .. tostring(executionAction.reason or "No qualified execution veto."),
        string.format("Commitment: %s @ %s | excess %d",
            tostring(commitment.state or "UNKNOWN"),
            tostring(commitment.objective or "Unknown"),
            roundedNumber(commitment.excess or 0)),
        string.format("Pressure: %s @ %s | score %d | enemy ETA %s",
            tostring(pressureForecast.state or "UNKNOWN"),
            tostring(pressureForecast.target or "Unknown"),
            roundedNumber(pressureForecast.score or 0),
            pressureForecast.eta and (tostring(pressureForecast.eta) .. "s") or "Unknown"),
        string.format("Reinforcement: %s | friendly %s | enemy %s | edge %s",
            tostring(reinforcement.side or "UNKNOWN"),
            reinforcement.friendlyETA and (tostring(reinforcement.friendlyETA) .. "s") or "Unknown",
            reinforcement.enemyETA and (tostring(reinforcement.enemyETA) .. "s") or "Unknown",
            reinforcement.advantage and (tostring(reinforcement.advantage) .. "s") or "Unknown"),
        string.format("Rotation: %s | value %d | leaving cost %s",
            tostring(rotationEconomy.state or "UNKNOWN"),
            roundedNumber(rotationEconomy.value or 0),
            tostring(rotationEconomy.leavingCost or "Unknown")),
        string.format("Collapse: %s %d | response %s | Recovery: %s %d",
            tostring(collapse.state or "UNKNOWN"), roundedNumber(collapse.score or 0),
            tostring(collapse.response or "HOLD_PLAN"),
            recovery.open and "OPEN" or "CLOSED", roundedNumber(recovery.score or 0)),
        string.format("Organization: %s | entropy %d",
            tostring(organization.state or "UNKNOWN"),
            roundedNumber(organization.entropy or 0)),
        string.format("Response package: %s | qualified %s",
            tostring(response.action or "HOLD CURRENT PLAN"),
            response.qualified and "YES" or "NO"),
        string.format("Horizons: 5s %s | 15s %s @ %s | 30s %s",
            horizons.immediate and horizons.immediate.state or "UNKNOWN",
            horizons.engagement and horizons.engagement.state or "UNKNOWN",
            horizons.engagement and horizons.engagement.target or "Unknown",
            horizons.strategic and horizons.strategic.state or "UNKNOWN"),
        "ACTION PACKAGE: " .. tostring(response.action or "HOLD CURRENT PLAN"),
        "WHO PACKAGE: " .. tostring(response.moverText or "Team"),
        "HOLD PACKAGE: " .. tostring(response.stayerText or "Assigned defenders"),
        "",
        "ASSIGNMENT INTEGRITY:",
        string.format("on station %d | moving %d | unknown %d | abandoned %d | impossible %d",
            roundedNumber(integrity.onStation or 0), roundedNumber(integrity.moving or 0),
            roundedNumber(integrity.unverified or 0), roundedNumber(integrity.abandoned or 0),
            roundedNumber(integrity.impossible or 0)),
        "",
        "COMMANDER OVERRIDES:",
        #overrides > 0 and table.concat(overrides, "\n") or "No active commander assignment locks.",
        "",
        #integrityLines > 0 and table.concat(integrityLines, "\n") or "No reassignment required.",
        #coverageLines > 0 and table.concat(coverageLines, "\n") or "No verified objective coverage ledger.",
        "",
        "ALTERNATIVE REVIEW:",
        #(strategy.alternativeReview or {}) > 0 and (function()
            local rows = {}
            for _, row in ipairs(strategy.alternativeReview or {}) do
                rows[#rows + 1] = string.format("%s @ %s | %d | %s",
                    tostring(row.id or "UNKNOWN"),
                    tostring(row.target or "unknown"),
                    roundedNumber(row.score or 0),
                    tostring(row.reason or "weaker option"))
            end
            return table.concat(rows, "\n")
        end)() or "No alternative comparison available.",
        "",
        "ALTERNATIVES:",
        #alternatives > 0 and table.concat(alternatives, "\n") or "None",
        "",
        "LEARNING: " .. tostring(learning.samples) .. " reviewed samples across "
            .. tostring(learning.plans) .. " plans.",
    }, "\n")
end

function MainWindowReports:BuildAlternativesPayload(state)
    local command = state.command or {}
    local strategy = state.snapshot and state.snapshot.strategy or {}
    local simulationsById = {}
    for _, candidate in ipairs(strategy.simulations or {}) do
        if candidate.id then
            simulationsById[candidate.id] = candidate
        end
    end

    local lines = {
        "CURRENT CALL:",
        "ACTION: " .. tostring(command.action or strategy.action or "Hold current plan."),
        "WHO: " .. tostring(command.who or "Team"),
        "WHERE: " .. tostring(command.target or strategy.target or "Current objective"),
        "WIN IF: " .. tostring(command.switchIf or "Authoritative state stays on our side."),
        "RISK: " .. tostring(strategy.risk or "Unknown"),
        "",
        "OTHER REVIEWED PATHS:",
    }

    local added = 0
    for _, row in ipairs(strategy.alternativeReview or {}) do
        local simulation = simulationsById[row.id] or {}
        added = added + 1
        lines[#lines + 1] = string.format(
            "%d) %s @ %s",
            added,
            tostring(row.id or "UNKNOWN"),
            tostring(simulation.target or row.target or "Unverified objective"))
        lines[#lines + 1] = "   CALL: " .. tostring(simulation.action or "Reposition and verify.")
        lines[#lines + 1] = string.format(
            "   READ: %d | %s | %s",
            roundedNumber(simulation.decisionScore or row.score or 0),
            tostring(simulation.projection or "UNKNOWN"),
            simulation.legal == false and "BLOCKED" or "READY")
        lines[#lines + 1] = "   WHY NOT FIRST: " .. tostring(row.reason or "Weaker reviewed edge.")
        lines[#lines + 1] = "   WIN IF: " .. tostring(simulation.outcome or "Objective converts cleanly.")
        lines[#lines + 1] = "   RISK: " .. tostring(simulation.risk or "Unknown")
        lines[#lines + 1] = ""
    end

    if added == 0 then
        lines[#lines + 1] = "No alternate path beats the current line yet."
        lines[#lines + 1] = "Recheck after a new sighting, score swing, or coverage break."
    else
        lines[#lines + 1] = "Commander use:"
        lines[#lines + 1] = "Choose one alternate only when the live fight is stalled or the trigger breaks."
    end

    return "KWR Alternate Plans", table.concat(lines, "\n")
end

function MainWindowReports:BuildPerformancePayload(state)
    local diagnostics = state.diagnostics or {}
    local boot = KWR.bootDiagnostics or {}
    local capabilityCache = KWR.Capabilities:CacheStats()
    local decisionCache = KWR.Strategist:CacheStats()
    local command = state.command or {}
    local activePlay = state.activePlay or command.activePlay or {}
    local activeDecision = command.activePlayDecision or {}
    local activeTransition = command.activePlayTransition or {}
    local stability = KWR.Commander:GetStabilityMetrics()
    local overrides = KWR.Commander:GetOverrideLog()
    local suppressions = KWR.Commander.GetSuppressionLog and KWR.Commander:GetSuppressionLog() or {}
    local latestOverride = overrides[#overrides]
    local latestSuppression = suppressions[#suppressions]
    local sampleCount = diagnostics.durationSampleCount or 0
    local p95Text = sampleCount >= 10
        and string.format("P95: %.3f ms", diagnostics.p95DurationMs or 0)
        or string.format("P95: pending (%d/10 samples before first calculation)", sampleCount)
    local tacticalSampleCount = diagnostics.tacticalDurationSampleCount or 0
    local tacticalP95Text = tacticalSampleCount >= 10
        and string.format("Tactical P95: %.3f ms", diagnostics.p95TacticalDurationMs or 0)
        or string.format("Tactical P95: pending (%d/10)", tacticalSampleCount)
    local moduleTimes = {}
    for name, duration in pairs(boot.moduleMs or {}) do
        moduleTimes[#moduleTimes + 1] = { name = name, duration = duration }
    end
    table.sort(moduleTimes, function(a, b) return a.duration > b.duration end)
    local slowModules = {}
    for index = 1, math.min(5, #moduleTimes) do
        slowModules[#slowModules + 1] = string.format("%s %.3f ms",
            moduleTimes[index].name, moduleTimes[index].duration)
    end
    local stageTimes = {}
    for name, duration in pairs(diagnostics.stageMs or {}) do
        stageTimes[#stageTimes + 1] = { name = name, duration = duration }
    end
    table.sort(stageTimes, function(a, b) return a.duration > b.duration end)
    local slowStages = {}
    for index = 1, math.min(4, #stageTimes) do
        slowStages[#slowStages + 1] = string.format("%s %.3f ms",
            stageTimes[index].name, stageTimes[index].duration)
    end
    return "KWR Performance", table.concat({
        "KWR PERFORMANCE TELEMETRY",
        string.format("Boot module initialization: %.3f ms", boot.initializeMs or 0),
        "Slowest initialization: " .. (#slowModules > 0 and table.concat(slowModules, ", ") or "unavailable"),
        string.format("Last world transition refresh: %.3f ms", diagnostics.lastTransitionDurationMs or 0),
        "Transition refreshes: " .. tostring(diagnostics.transitionRefreshes or 0),
        "Lightweight health/aura events: " .. tostring(diagnostics.lightweightEvents or 0),
        "",
        "Strategic refreshes: " .. tostring(diagnostics.strategicRefreshes
            or diagnostics.refreshes or 0),
        "Tactical refreshes: " .. tostring(diagnostics.tacticalRefreshes or 0),
        "Events: " .. tostring(diagnostics.events or 0),
        "Coalesced events: " .. tostring(diagnostics.coalesced or 0),
        "Newest-truth followups: " .. tostring(diagnostics.queueFollowups or 0),
        "Earlier refresh preemptions: " .. tostring(diagnostics.queuePreemptions or 0),
        "Load/widget settle refreshes: " .. tostring(diagnostics.settleRefreshes or 0),
        string.format("Strategic last: %.3f ms", diagnostics.lastDurationMs or 0),
        string.format("Strategic average: %.3f ms", diagnostics.averageDurationMs or 0),
        "Duration samples: strategic " .. tostring(sampleCount)
            .. " / 120, tactical " .. tostring(tacticalSampleCount) .. " / 120",
        "Strategic duration samples: " .. tostring(sampleCount) .. " / 120",
        "Strategic " .. p95Text,
        string.format("Strategic maximum: %.3f ms", diagnostics.maxDurationMs or 0),
        string.format("Tactical last: %.3f ms", diagnostics.lastTacticalDurationMs or 0),
        string.format("Tactical average: %.3f ms", diagnostics.averageTacticalDurationMs or 0),
        "Tactical duration samples: " .. tostring(tacticalSampleCount) .. " / 120",
        tacticalP95Text,
        string.format("Tactical maximum: %.3f ms", diagnostics.maxTacticalDurationMs or 0),
        string.format("Tactical queue: coalesced %d / absorbed %d / escalated %d",
            diagnostics.tacticalCoalesced or 0,
            diagnostics.tacticalAbsorbed or 0,
            diagnostics.tacticalEscalations or 0),
        "Top events: " .. topCounterText(diagnostics.eventReasons, 6),
        "Strategic queue reasons: " .. topCounterText(
            diagnostics.strategicQueueReasons, 6),
        "Strategic execution reasons: " .. topCounterText(
            diagnostics.strategicRefreshReasons, 6),
        "Tactical queue reasons: " .. topCounterText(
            diagnostics.tacticalQueueReasons, 6),
        "Tactical execution reasons: " .. topCounterText(
            diagnostics.tacticalRefreshReasons, 6),
        "Latest slow stages: " .. (#slowStages > 0 and table.concat(slowStages, ", ") or "unavailable"),
        string.format("KWR addon memory: %.1f KB (same GetAddOnMemoryUsage sample)", diagnostics.memoryKB or 0),
        string.format("Performance watchdog: mode %s | sampled events %d | widget drops %d | points drops %d",
            tostring(KWR.MemoryBudget and KWR.MemoryBudget.degradationMode or "FULL"),
            #(diagnostics.eventTrace or {}), diagnostics.widgetEventsCoalesced or 0,
            diagnostics.pointsEventsCoalesced or 0),
        string.format("Capability cache: %d hits / %d misses / %d entries",
            capabilityCache.hits or 0, capabilityCache.misses or 0,
            capabilityCache.entries or 0),
        string.format("Decision cache: %d hits / %d misses",
            decisionCache.hits or 0, decisionCache.misses or 0),
        string.format("Execution cache: %d hits / %d misses",
            decisionCache.executionHits or 0, decisionCache.executionMisses or 0),
        string.format("HUD renders skipped: %d / updated: %d",
            KWR.HUD.renderSkips or 0, KWR.HUD.renderUpdates or 0),
        string.format("Roster row renders skipped: %d / updated: %d",
            KWR.CombatRoster.renderSkips or 0, KWR.CombatRoster.renderUpdates or 0),
        string.format("Expanded roster rows skipped: %d / updated: %d",
            KWR.MainWindow.expandedRosterSkips or 0,
            KWR.MainWindow.expandedRosterUpdates or 0),
        "Runtime errors: " .. tostring(diagnostics.errors or 0),
        string.format("Command acknowledgements: %d | last %.1fs ago",
            KWR.CommandAudio and KWR.CommandAudio.acknowledgements or 0,
            KWR.CommandAudio and KWR.CommandAudio.lastAcknowledgedAt
                and math.max(0, KWR.Util:Now() - KWR.CommandAudio.lastAcknowledgedAt) or 0),
        "",
        "COMMAND STABILITY:",
        string.format("Issued %d | replacements %d | stabilized %d | suppressed %d | reversals %d",
            stability.issued or 0, stability.replacements or 0, stability.stabilized or 0,
            stability.suppressed or 0, stability.reversals or 0),
        string.format("Budget %s | %s | reversal %.1f%% | pre-move %.1f%%",
            tostring(stability.commandHealth or "UNKNOWN"),
            tostring(stability.commandHealthReason or "No stability budget reason."),
            tonumber(stability.reversalRate or 0) * 100,
            tonumber(stability.preMovementInvalidationRate or 0) * 100),
        string.format("Field certification %s | %s",
            tostring(stability.certificationStatus or "INSUFFICIENT_SAMPLE"),
            tostring(stability.certificationReason or "Collect more command samples.")),
        string.format("Pre-move invalidations %d | overrides %d | retained %d | suppressed alternatives %d",
            stability.preMovementInvalidations or 0, stability.overrides or 0,
            stability.activePlayRetains or 0, stability.suppressedAlternatives or 0),
        string.format("Suppression persistence %d | superiority %d | overrides pre-arrival %d / committed %d",
            stability.suppressedByPersistence or 0,
            stability.suppressedBySuperiority or 0,
            stability.overridesBeforeArrival or 0,
            stability.overridesAfterCommitment or 0),
        string.format("Invalidations pre-arrival %d / committed %d",
            stability.invalidationsBeforeArrival or 0,
            stability.invalidationsAfterCommitment or 0),
        string.format("Successes %d | success %.1f%% | average switch advantage %.1f",
            stability.successfulPlays or 0,
            tonumber(stability.successRate or 0) * 100,
            tonumber(stability.averageSwitchAdvantage or 0) or 0),
        string.format("Bypass response %d | reassessment %d | emergency %d",
            stability.responseBypasses or 0, stability.reassessmentBypasses or 0,
            stability.emergencyBypasses or 0),
        string.format("Average lifetime %.2fs | median %.2fs | shortest %.2fs | longest %.2fs",
            stability.averageLifetime or 0, stability.medianLifetime or 0,
            stability.shortestLifetime or 0, stability.longestLifetime or 0),
        "",
        "ACTIVE PLAY:",
        string.format("%s | %s | %s | phase %s | milestone %s",
            tostring(activePlay.family or state.snapshot and state.snapshot.context and state.snapshot.context.kind or "WORLD"),
            tostring(activePlay.action or command.action or "HOLD"),
            tostring(activePlay.objective or command.where or "current lane"),
            tostring(activePlay.phase or "NONE"),
            tostring(activePlay.milestone or "NONE")),
        string.format("Movers %d | stayers %d | confidence %d | retained %s",
            #(activePlay.movers or {}), #(activePlay.stayers or {}),
            roundedNumber(activePlay.confidence or 0),
            activeDecision.retained and "YES" or "NO"),
        string.format("Timing commit %.1fs | travel %.1fs | interaction %.1fs",
            tonumber(activePlay.commitmentSeconds or 0) or 0,
            tonumber(activePlay.travelSeconds or 0) or 0,
            tonumber(activePlay.interactionSeconds or 0) or 0),
        string.format("Persistence observed %.1fs | required %.1fs | trend %.1fs / %d wins",
            activeDecision.replacementScore and tonumber(activeDecision.replacementScore.observedDuration or 0) or 0,
            activeDecision.replacementScore and tonumber(activeDecision.replacementScore.requiredDuration or 0) or 0,
            tonumber(command.activePlayTrend and command.activePlayTrend.duration or 0) or 0,
            tonumber(command.activePlayTrend and command.activePlayTrend.consecutiveWins or 0) or 0),
        string.format("Replacement %s | invalidation %s | reason %s",
            activeDecision.replacementAllowed and "ALLOWED" or "HELD",
            tostring(activeDecision.invalidation or "none"),
            tostring(activeDecision.replacementReason or activeDecision.phaseReason or "steady state")),
        string.format("Gate %s | family %s",
            tostring(activeDecision.gateClass or "STEADY"),
            tostring(activeDecision.invalidationFamily or "NONE")),
        string.format("Transition %s | %s -> %s | rule %s",
            tostring(activeTransition.trigger or "STEADY"),
            tostring(activeTransition.fromPhase or "NONE"),
            tostring(activeTransition.toPhase or "UNKNOWN"),
            tostring(activeTransition.rule or "none")),
        latestOverride and string.format("Latest override: %s -> %s @ %s/%s (lost %.1fs, obs %.1fs, req %.1fs)",
            tostring(latestOverride.currentObjective or "unknown"),
            tostring(latestOverride.candidateObjective or "unknown"),
            tostring(latestOverride.phase or "UNKNOWN"),
            tostring(latestOverride.phaseBucket or "UNKNOWN"),
            tonumber(latestOverride.lostCommitmentTime or 0) or 0,
            tonumber(latestOverride.observedDuration or 0) or 0,
            tonumber(latestOverride.requiredDuration or 0) or 0)
            or "Latest override: none",
        latestSuppression and string.format("Latest suppression: %s -> %s @ %s/%s (%s, obs %.1fs, req %.1fs)",
            tostring(latestSuppression.currentObjective or "unknown"),
            tostring(latestSuppression.candidateObjective or "unknown"),
            tostring(latestSuppression.phase or "UNKNOWN"),
            tostring(latestSuppression.phaseBucket or "UNKNOWN"),
            tostring(latestSuppression.replacementReason or "steady state"),
            tonumber(latestSuppression.observedDuration or 0) or 0,
            tonumber(latestSuppression.requiredDuration or 0) or 0)
            or "Latest suppression: none",
        "",
        "RETENTION:",
        KWR.MemoryBudget and KWR.MemoryBudget:Report() or "Retention report unavailable.",
        "",
        "Testing target: P95 < 2 ms, routine max < 4 ms, stable memory.",
    }, "\n")
end
