local _, KWR = ...

local Verification = {
    ledger = {},
    maxEntries = 60,
    lastSignature = nil,
}
KWR.Verification = Verification

local function value(value, fallback)
    return KWR.Util:Text(value, fallback or "unknown", 180)
end

local function objectiveSummary(objectives)
    return string.format("%d friendly, %d enemy, %d friendly incoming, %d enemy incoming",
        objectives.friendly or 0,
        objectives.enemy or 0,
        objectives.friendlyIncoming or 0,
        objectives.enemyIncoming or 0)
end

local function objectiveEvidenceDetails(objectives)
    local details = {}
    for _, row in ipairs(objectives and objectives.rows or {}) do
        if #details >= 3 then break end
        local resolution = row.resolution or {}
        local stateResolution = resolution.state or {}
        local ownerResolution = resolution.owner or {}
        local conflicts = {}
        if stateResolution.conflict then conflicts[#conflicts + 1] = "state" end
        if ownerResolution.conflict then conflicts[#conflicts + 1] = "owner" end
        details[#details + 1] = string.format(
            "%s [%s] state %s via %s / owner %s via %s / %s",
            row.label or "Objective",
            row.native and row.native.semantic or "UNKNOWN",
            row.state or "UNKNOWN",
            stateResolution.selectedSource or row.selectedSource or row.source or "unknown",
            row.owner or "UNKNOWN",
            ownerResolution.selectedSource or row.selectedSource or row.source or "unknown",
            #conflicts > 0 and table.concat(conflicts, "+") or "clean"
        )
    end
    return details
end

local function objectiveConflictCount(objectives)
    local count = 0
    for _, row in ipairs(objectives and objectives.rows or {}) do
        local resolution = row.resolution or {}
        if (resolution.state and resolution.state.conflict)
            or (resolution.owner and resolution.owner.conflict) then
            count = count + 1
        end
    end
    return count
end

local function objectiveSummarySignature(objectives)
    local friendly, enemy, friendlyIncoming, enemyIncoming = 0, 0, 0, 0
    for _, row in ipairs(objectives and objectives.rows or {}) do
        local owner = KWR.Util:Text(row.owner, "UNKNOWN", 16)
        local state = KWR.Util:Text(row.state, "UNKNOWN", 20)
        if owner == "FRIENDLY" then
            friendly = friendly + 1
            if state == "INCOMING" then
                friendlyIncoming = friendlyIncoming + 1
            end
        elseif owner == "ENEMY" then
            enemy = enemy + 1
            if state == "INCOMING" then
                enemyIncoming = enemyIncoming + 1
            end
        end
    end
    return string.format("%d/%d/%d/%d", friendly, enemy, friendlyIncoming, enemyIncoming)
end

local function lightweightSignature(state)
    state = type(state) == "table" and state or {}
    local snapshot = type(state.snapshot) == "table" and state.snapshot or {}
    local context = type(snapshot.context) == "table" and snapshot.context or {}
    local score = type(snapshot.score) == "table" and snapshot.score or {}
    local strategy = type(snapshot.strategy) == "table" and snapshot.strategy or {}
    local objectives = type(snapshot.objectives) == "table" and snapshot.objectives or {}
    local command = type(state.command) == "table" and state.command or {}
    return KWR.Util:Signature({
        context.mapKey,
        context.instanceType,
        context.team,
        score.friendly,
        score.enemy,
        objectives.source,
        objectiveSummarySignature(objectives),
        strategy.planID,
        strategy.action,
        strategy.state,
        command.signature,
        command.action,
        command.activePlay and command.activePlay.id or nil,
    })
end

local function age(observedAt, now)
    observedAt = KWR.Util:Number(observedAt, nil)
    if not observedAt then return nil end
    return math.max(0, (now or KWR.Util:Now()) - observedAt)
end

local function assignmentSummary(assignments)
    local rows = {}
    for index, assignment in ipairs(assignments or {}) do
        if index > 10 then break end
        rows[#rows + 1] = string.format("%s = %s @ %s",
            value(assignment.shortName or assignment.name, "unknown"),
            value(assignment.role, "unknown"),
            value(assignment.location, "unknown"))
    end
    return rows
end

local function activeProblemSummary(problems)
    local rows = {}
    for index, problem in ipairs(problems or {}) do
        if index > 6 then break end
        local row = KWR.ProblemSignalRegistry and KWR.ProblemSignalRegistry:Describe(problem.type)
        rows[#rows + 1] = string.format("%s / %s / %s / evid %d",
            value(problem.type, "UNKNOWN"),
            value(problem.confidence, "UNKNOWN"),
            row and (row.enabled and "SUPPORTED" or "DISABLED") or "UNDECLARED",
            problem.evidenceIDs and #problem.evidenceIDs or 0)
    end
    return rows
end

function Verification:Contract(snapshot)
    snapshot = snapshot or {}
    local context = snapshot.context or {}
    local score = snapshot.score or {}
    local objectives = snapshot.objectives or {}
    local reporter = snapshot.reporter or {}
    local now = KWR.Util:Now()
    local facts = {
        match = KWR.Util:Evidence(
            context.inPvP and context.mapKey or nil,
            context.inPvP and "instance_context" or "none",
            context.capturedAt or snapshot.capturedAt,
            context.inPvP and 10 or 30,
            context.inPvP and "HIGH" or "NONE",
            context.inPvP and KWR.Maps:Get(context.mapKey) ~= nil),
        team = KWR.Util:Evidence(
            context.team and context.team.faction or nil,
            context.team and context.team.source or "scoreboard",
            context.capturedAt or snapshot.capturedAt,
            15,
            context.team and context.team.side and "HIGH" or "NONE",
            context.team and context.team.side ~= nil),
        score = KWR.Util:Evidence(
            score.source == "ui_widget" and {
                friendly = score.friendly,
                enemy = score.enemy,
                max = score.max,
            } or nil,
            score.source,
            score.observedAt,
            5,
            score.source == "ui_widget" and "HIGH" or "NONE",
            score.source == "ui_widget"),
        objectives = KWR.Util:Evidence(
            objectives.source == "ui_widget" and objectives.rows or nil,
            objectives.source,
            objectives.observedAt,
            5,
            objectives.source == "ui_widget" and "HIGH"
                or (#(objectives.rows or {}) > 0 and "LOW" or "NONE"),
            objectives.source == "ui_widget"),
        friendlyRoster = KWR.Util:Evidence(
            #(snapshot.roster or {}) > 0 and #(snapshot.roster or {}) or nil,
            "group_units",
            snapshot.capturedAt,
            8,
            #(snapshot.roster or {}) >= 8 and "HIGH" or "MEDIUM",
            #(snapshot.roster or {}) > 0),
        enemyRoster = KWR.Util:Evidence(
            #(snapshot.enemies or {}) > 0 and #(snapshot.enemies or {}) or nil,
            "pvp_scoreboard",
            snapshot.capturedAt,
            12,
            #(snapshot.enemies or {}) >= 8 and "MEDIUM" or "LOW",
            false),
        movement = KWR.Util:Evidence(
            reporter.coverage and {
                friendly = reporter.coverage.friendlyLocated or 0,
                enemy = reporter.coverage.enemyLocated or 0,
            } or nil,
            "reporter_tracks",
            reporter.updatedAt,
            8,
            reporter.coverage and
                ((reporter.coverage.friendlyLocated or 0)
                    + (reporter.coverage.enemyLocated or 0) >= 3)
                and "MEDIUM" or "LOW",
            false),
    }
    local summary = {
        verified = 0,
        observed = 0,
        stale = 0,
        unknown = 0,
        usable = 0,
        total = 0,
    }
    for _, fact in pairs(facts) do
        fact.age = fact.observedAt and math.max(0, now - fact.observedAt) or nil
        summary.total = summary.total + 1
        if fact.state == "VERIFIED" then summary.verified = summary.verified + 1
        elseif fact.state == "OBSERVED" then summary.observed = summary.observed + 1
        elseif fact.state == "STALE" then summary.stale = summary.stale + 1
        else summary.unknown = summary.unknown + 1 end
        if KWR.Util:EvidenceUsable(fact, "LOW") then
            summary.usable = summary.usable + 1
        end
    end
    local coreFresh = KWR.Util:EvidenceUsable(facts.match, "HIGH")
        and KWR.Util:EvidenceUsable(facts.team, "HIGH")
        and KWR.Util:EvidenceUsable(facts.score, "HIGH")
    local objectiveRequired = context.kind == "NODE"
        or context.kind == "HYBRID" or context.kind == "ORB"
        or context.kind == "CART" or context.kind == "RESOURCE"
    if objectiveRequired then
        coreFresh = coreFresh
            and KWR.Util:EvidenceUsable(facts.objectives, "MEDIUM")
    end
    summary.coverage = summary.total > 0
        and math.floor((summary.usable / summary.total) * 100 + 0.5) or 0
    return {
        generatedAt = now,
        facts = facts,
        summary = summary,
        coreFresh = coreFresh == true,
        aggressiveCommitAllowed = coreFresh == true
            and summary.coverage >= 65
            and summary.stale == 0,
        conservativeReason = coreFresh and nil
            or "Core match, faction, score, or objective evidence is incomplete.",
    }
end

function Verification:Audit(state)
    state = state or KWR.Store:Get()
    local issues = {}
    local snapshot = state.snapshot or {}
    local context = snapshot.context or {}
    local score = snapshot.score or {}
    local objectives = snapshot.objectives or {}
    local assignmentAudit = KWR.Assignments:Audit(snapshot, state.assignments)
    if context.inPvP then
        if not KWR.Maps:Get(context.mapKey) then
            issues[#issues + 1] = "Battleground definition unresolved"
        end
        if not context.team or not context.team.side then
            issues[#issues + 1] = "Assigned battlefield team unresolved"
        end
        if score.source ~= "ui_widget" then
            issues[#issues + 1] = "Authoritative score unavailable"
        end
        local definition = KWR.Maps:Get(context.mapKey)
        if definition and definition.objectiveWidget and objectives.source ~= "ui_widget" then
            issues[#issues + 1] = "Authoritative objective widget unavailable"
        end
        for _, issue in ipairs(assignmentAudit.issues or {}) do
            issues[#issues + 1] = issue
        end
        local now = KWR.Util:Now()
        if score.source == "ui_widget" and age(score.observedAt, now)
            and age(score.observedAt, now) > 5 then
            issues[#issues + 1] = "Score evidence is stale"
        end
        if objectives.source == "ui_widget" and age(objectives.observedAt, now)
            and age(objectives.observedAt, now) > 5 then
            issues[#issues + 1] = "Objective evidence is stale"
        end
        local objectiveConflicts = objectiveConflictCount(objectives)
        if objectiveConflicts > 0 then
            issues[#issues + 1] = string.format(
                "Objective source conflicts detected on %d row%s",
                objectiveConflicts,
                objectiveConflicts == 1 and "" or "s")
        end
        if state.prediction and state.prediction.mapKey
            and state.prediction.mapKey ~= context.mapKey then
            issues[#issues + 1] = "Prediction map does not match active map"
        end
        if state.command and state.command.mapKey
            and state.command.mapKey ~= context.mapKey then
            issues[#issues + 1] = "Command map does not match active map"
        end
    end
    if (state.diagnostics and state.diagnostics.errors or 0) > 0 then
        issues[#issues + 1] = "Runtime errors recorded"
    end
    local problemAudit = KWR.ProblemSignalRegistry and KWR.ProblemSignalRegistry:Audit(
        snapshot.teamfight and snapshot.teamfight.problems or {}) or nil
    for _, issue in ipairs(problemAudit and problemAudit.issues or {}) do
        issues[#issues + 1] = issue
    end
    return {
        ok = #issues == 0,
        status = #issues == 0 and "PASS" or "WARN",
        issues = issues,
        problemSignals = problemAudit,
    }
end

function Verification:BuildEntry(state)
    state = state or KWR.Store:Get()
    local snapshot = state.snapshot or {}
    local context = snapshot.context or {}
    local score = snapshot.score or {}
    local objectives = snapshot.objectives or {}
    local prediction = state.prediction or {}
    local strategy = snapshot.strategy or {}
    local diagnostics = state.diagnostics or {}
    local command = state.command or {}
    local activePlay = state.activePlay or {}
    local reporter = snapshot.reporter or {}
    local reporterCoverage = reporter.coverage or {}
    local commandLine1, commandLine2, commandLine3 = KWR.CommandView:SummaryLines(state)
    local now = KWR.Util:Now()
    local contract = self:Contract(snapshot)
    local assignmentAudit = KWR.Assignments:Audit(snapshot, state.assignments)
    local audit = self:Audit(state)
    local problemSignalSummary = KWR.ProblemSignalRegistry
        and KWR.ProblemSignalRegistry:Summary() or nil
    local problemSignalAudit = audit.problemSignals
    local overrideDetails = KWR.AssignmentOverrides
        and KWR.AssignmentOverrides:DescribeActive(snapshot, state.assignments)
        or {}
    local teamSpecs, teamUnits = 0, 0
    local enemySpecs, enemyUnits, enemyLocal = 0, 0, 0
    local enemyVisible, enemyLocalRange, enemyLastSeen = 0, 0, 0
    for _, player in ipairs(snapshot.roster or {}) do
        if player.spec and player.spec ~= "" and player.spec ~= "Unknown" then
            teamSpecs = teamSpecs + 1
        end
        if player.unit then teamUnits = teamUnits + 1 end
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if enemy.spec and enemy.spec ~= "" and enemy.spec ~= "Unknown" then
            enemySpecs = enemySpecs + 1
        end
        if enemy.unit then enemyUnits = enemyUnits + 1 end
        if enemy.visible then enemyVisible = enemyVisible + 1 end
        if enemy.localRange then enemyLocalRange = enemyLocalRange + 1 end
        if enemy.localEngaged then enemyLocal = enemyLocal + 1 end
        if enemy.locationState == "LAST SEEN" then enemyLastSeen = enemyLastSeen + 1 end
    end
    local localTarget = snapshot.combat and snapshot.combat.localTarget or {}
    local commandTarget = snapshot.combat and snapshot.combat.killTarget or {}
    local commandStability = KWR.Commander and KWR.Commander:GetStabilityMetrics() or {}
    local overrideLog = KWR.Commander and KWR.Commander:GetOverrideLog() or {}
    local suppressionLog = KWR.Commander and KWR.Commander.GetSuppressionLog
        and KWR.Commander:GetSuppressionLog() or {}
    local latestOverride = overrideLog[#overrideLog]
    local latestSuppression = suppressionLog[#suppressionLog]
    return {
        revision = state.revision or 0,
        capturedAt = state.capturedAt or KWR.Util:Now(),
        captureAge = age(state.capturedAt, now),
        mapKey = context.mapKey,
        mapName = context.mapName,
        mapID = context.mapID,
        instanceType = context.instanceType,
        phase = context.phase,
        bracket = context.isBlitz and "BLITZ" or "STANDARD",
        preview = context.preview == true,
        team = context.team and context.team.faction or "Unknown",
        teamSide = context.team and context.team.side or "unknown",
        scoreFaction = context.team and context.team.scoreFaction,
        teamSource = context.team and context.team.source or "unresolved",
        teamVotes = context.team and context.team.votes or 0,
        rawLeft = score.rawLeft,
        rawRight = score.rawRight,
        friendlyScore = score.friendly or 0,
        enemyScore = score.enemy or 0,
        maxScore = score.max or 0,
        scoreSource = score.source,
        scoreWidget = score.widgetID,
        scoreWidgetAuthority = score.widgetAuthority,
        scoreRegressionRejected = score.regressionRejected == true,
        scoreAge = age(score.observedAt, now),
        scoreChangedAge = age(score.changedAt, now),
        objectiveSource = objectives.source,
        objectiveWidget = objectives.widgetID,
        objectiveAge = age(objectives.observedAt, now),
        objectiveSummary = objectiveSummary(objectives),
        objectiveDetails = objectiveEvidenceDetails(objectives),
        objectiveConflicts = objectiveConflictCount(objectives),
        prediction = prediction.status,
        condition = prediction.condition,
        action = prediction.action,
        confidence = prediction.confidence,
        planID = strategy.planID,
        planReason = strategy.reason,
        decisionConfidenceScore = strategy.confidenceBudget
            and strategy.confidenceBudget.score,
        decisionRisk = strategy.risk,
        recommendationMode = strategy.recommendationMode,
        projectedWinProbability = strategy.projectedWinProbability,
        expectedOutcome = strategy.expectedOutcome,
        opportunity = strategy.opportunity,
        strategyTrust = strategy.trust,
        scenarioCalibration = strategy.scenarioCalibration,
        scenarioAdversarialCalibration = strategy.scenarioAdversarialCalibration,
        enemyResponsePlan = strategy.enemyResponsePlan,
        alternativeReview = strategy.alternativeReview,
        executionAssessment = strategy.executionAssessment,
        responsePackage = snapshot.responsePackage,
        knowledgeStatus = snapshot.knowledgeStatus,
        simulations = strategy.simulations,
        switchIf = strategy.switchIf,
        stop = strategy.stop,
        objectiveDecision = strategy.objectiveDecision,
        doctrineClass = strategy.doctrineClass,
        doctrineBranchID = strategy.doctrineBranchID,
        doctrineComparisonID = strategy.doctrineComparisonID,
        enemyResponseGuidanceID = strategy.enemyResponseGuidanceID,
        compThreat = strategy.compThreat,
        enemyDefenseModel = strategy.enemyDefenseModel,
        weightedFocus = strategy.weightedFocus,
        roster = #(snapshot.roster or {}),
        enemies = #(snapshot.enemies or {}),
        teamSpecs = teamSpecs,
        teamUnits = teamUnits,
        enemySpecs = enemySpecs,
        enemyUnits = enemyUnits,
        enemyLocal = enemyLocal,
        enemyVisible = enemyVisible,
        enemyLocalRange = enemyLocalRange,
        enemyLastSeen = enemyLastSeen,
        assignments = #(state.assignments or {}),
        assignmentAudit = assignmentAudit,
        assignmentDetails = assignmentSummary(state.assignments),
        overrideCount = #overrideDetails,
        overrideDetails = overrideDetails,
        problemSignalSummary = problemSignalSummary,
        problemSignalAudit = problemSignalAudit,
        activeProblemDetails = activeProblemSummary(snapshot.teamfight and snapshot.teamfight.problems),
        truthContract = contract,
        localTargetName = localTarget.shortName or localTarget.name,
        localTargetState = localTarget.locationState,
        localTargetReason = snapshot.combat
            and (snapshot.combat.localTargetReason or snapshot.combat.killReason),
        commandTargetName = commandTarget.shortName or commandTarget.name,
        commandTargetState = commandTarget.locationState,
        commandTargetReason = snapshot.combat and snapshot.combat.killReason,
        commandLine1 = commandLine1,
        commandLine2 = commandLine2,
        commandLine3 = commandLine3,
        commandSource = prediction.source,
        commandConfidence = command.confidence,
        commandAge = age(command.createdAt, now),
        commandTTL = command.expiresAt and math.max(0, command.expiresAt - now) or nil,
        commandBypass = command.bypass,
        commandStability = command.stability,
        commandStabilitySummary = commandStability,
        commandOverrideRecord = command.overrideRecord,
        commandSuppressionRecord = command.suppressionRecord,
        latestOverride = latestOverride,
        latestSuppression = latestSuppression,
        activePlay = activePlay,
        activePlayMilestone = activePlay.milestone or "NONE",
        activePlayCandidate = command.activePlayCandidate,
        activePlayTrend = command.activePlayTrend,
        activePlayDecision = command.activePlayDecision,
        activePlayOutcome = command.activePlayOutcome,
        activePlayTransition = command.activePlayTransition,
        activePlayPhaseReason = command.activePlayDecision and command.activePlayDecision.phaseReason,
        activePlayReviewIn = activePlay.reviewAt and math.max(0, activePlay.reviewAt - now) or 0,
        activePlayCommitIn = activePlay.minimumCommitUntil
            and math.max(0, activePlay.minimumCommitUntil - now) or 0,
        activePlayArrivalIn = activePlay.expectedArrivalAt
            and math.max(0, activePlay.expectedArrivalAt - now) or 0,
        activePlayResolutionIn = activePlay.expectedResolutionAt
            and math.max(0, activePlay.expectedResolutionAt - now) or nil,
        activePlayCommitmentSeconds = activePlay.commitmentSeconds or 0,
        activePlayTravelSeconds = activePlay.travelSeconds or 0,
        activePlayInteractionSeconds = activePlay.interactionSeconds or 0,
        activePlayObservedDuration = command.activePlayDecision
            and command.activePlayDecision.replacementScore
            and command.activePlayDecision.replacementScore.observedDuration or 0,
        activePlayRequiredDuration = command.activePlayDecision
            and command.activePlayDecision.replacementScore
            and command.activePlayDecision.replacementScore.requiredDuration or 0,
        reporterActive = reporter.active == true,
        reporterRisk = reporter.risk or 0,
        reporterHotspot = reporter.hotspot and reporter.hotspot.label,
        reporterFriendly = reporterCoverage.friendly or 0,
        reporterEnemy = reporterCoverage.enemy or 0,
        reporterFriendlyLocated = reporterCoverage.friendlyLocated or 0,
        reporterEnemyLocated = reporterCoverage.enemyLocated or 0,
        reporterAge = age(reporter.updatedAt, now),
        reporterTrust = reporter.trust,
        enemyIntent = reporter.enemyIntent,
        momentum = reporter.momentum,
        resourceEconomy = snapshot.combat and snapshot.combat.resourceEconomy,
        priorityCast = snapshot.combat and snapshot.combat.priorityCast,
        assignmentIntegrity = snapshot.assignmentIntegrity,
        refreshReason = diagnostics.lastReason,
        refreshMs = diagnostics.lastDurationMs or 0,
        p95Ms = diagnostics.p95DurationMs or 0,
        memoryKB = diagnostics.memoryKB or 0,
        transitionMs = diagnostics.lastTransitionDurationMs or 0,
        queueCoalesced = diagnostics.coalesced or 0,
        queueFollowups = diagnostics.queueFollowups or 0,
        queuePreemptions = diagnostics.queuePreemptions or 0,
        settleRefreshes = diagnostics.settleRefreshes or 0,
        bootMs = KWR.bootDiagnostics and KWR.bootDiagnostics.initializeMs or 0,
        errors = diagnostics.errors or 0,
        retention = KWR.MemoryBudget and KWR.MemoryBudget:Summary() or nil,
        audit = audit,
    }
end

function Verification:Update(state)
    local snapshot = state and state.snapshot
    if not snapshot or not snapshot.context or not snapshot.context.inPvP
        or snapshot.context.preview then return end
    local signature = lightweightSignature(state)
    if signature == self.lastSignature then return end
    self.lastSignature = signature
    local entry = self:BuildEntry(state)
    self.ledger[#self.ledger + 1] = entry
    while #self.ledger > self.maxEntries do table.remove(self.ledger, 1) end
end

function Verification:Format(entry)
    entry = entry or self:BuildEntry(KWR.Store:Get())
    local lines = {
        "KWR LIVE VERIFICATION",
        "Version: " .. value(KWR.version),
        "Audit: " .. value(entry.audit and entry.audit.status, "WARN"),
        "Map: " .. value(entry.mapName) .. " [" .. value(entry.mapKey) .. "]",
        "Map ID: " .. tostring(entry.mapID or "unknown")
            .. " / instance " .. value(entry.instanceType),
        "Phase: " .. value(entry.phase)
            .. " / capture age " .. string.format("%.2f sec", entry.captureAge or 0),
        string.format("Data coverage: core %s / coverage %d%% / aggressive commit %s / verified %d observed %d stale %d unknown %d",
            entry.truthContract and entry.truthContract.coreFresh and "FRESH" or "LIMITED",
            entry.truthContract and entry.truthContract.summary and entry.truthContract.summary.coverage or 0,
            entry.truthContract and entry.truthContract.aggressiveCommitAllowed and "YES" or "NO",
            entry.truthContract and entry.truthContract.summary and entry.truthContract.summary.verified or 0,
            entry.truthContract and entry.truthContract.summary and entry.truthContract.summary.observed or 0,
            entry.truthContract and entry.truthContract.summary and entry.truthContract.summary.stale or 0,
            entry.truthContract and entry.truthContract.summary and entry.truthContract.summary.unknown or 0),
        string.format("Problem signals: supported %d / disabled %d / partial %d / aliases %d / total %d",
            entry.problemSignalSummary and entry.problemSignalSummary.supported or 0,
            entry.problemSignalSummary and entry.problemSignalSummary.disabled or 0,
            entry.problemSignalSummary and entry.problemSignalSummary.partial or 0,
            entry.problemSignalSummary and entry.problemSignalSummary.legacyAliases or 0,
            entry.problemSignalSummary and entry.problemSignalSummary.total or 0),
        string.format("Problem coverage: full %d / active %d / unsupported %d / disabled %d / unknown %d / audit %s",
            entry.problemSignalSummary and entry.problemSignalSummary.fullCoverage or 0,
            entry.problemSignalAudit and entry.problemSignalAudit.active or 0,
            entry.problemSignalAudit and entry.problemSignalAudit.activeUnsupported or 0,
            entry.problemSignalAudit and entry.problemSignalAudit.activeDisabled or 0,
            entry.problemSignalAudit and entry.problemSignalAudit.activeUnknown or 0,
            entry.problemSignalAudit and entry.problemSignalAudit.auditOK and "PASS" or "WARN"),
        "Bracket rules: " .. value(entry.bracket),
        "Assigned team: " .. value(entry.team) .. " / " .. value(entry.teamSide)
            .. " / score faction " .. tostring(entry.scoreFaction or "unknown"),
        "Team data: " .. value(entry.teamSource) .. " / votes " .. tostring(entry.teamVotes or 0),
        "Raw widget score: " .. tostring(entry.rawLeft or "unknown")
            .. " left / " .. tostring(entry.rawRight or "unknown") .. " right",
        "Friendly score: " .. tostring(entry.friendlyScore or 0)
            .. " - " .. tostring(entry.enemyScore or 0)
            .. " / " .. tostring(entry.maxScore or 0),
        "Score source: " .. value(entry.scoreSource)
            .. " / widget " .. tostring(entry.scoreWidget or "unknown")
            .. " / " .. value(entry.scoreWidgetAuthority, "unverified")
            .. " / age " .. (entry.scoreAge and string.format("%.2f sec", entry.scoreAge) or "unknown"),
        "Score change age: "
            .. (entry.scoreChangedAge and string.format("%.2f sec",
                entry.scoreChangedAge) or "unknown")
            .. " / regression rejected "
            .. (entry.scoreRegressionRejected and "YES" or "NO"),
        "Objectives: " .. value(entry.objectiveSummary),
        "Objective source: " .. value(entry.objectiveSource)
            .. " / age " .. (entry.objectiveAge and string.format("%.2f sec", entry.objectiveAge) or "unknown"),
        "Objective widget: " .. tostring(entry.objectiveWidget or "unknown"),
        "Objective conflicts: " .. tostring(entry.objectiveConflicts or 0),
        "Prediction: " .. value(entry.prediction)
            .. " / confidence " .. value(entry.confidence, "NONE"),
        "Condition: " .. value(entry.condition),
        "Action: " .. value(entry.action),
        "Plan: " .. value(entry.planID, "none"),
        "Plan reason: " .. value(entry.planReason),
        string.format("Decision: %s / projected %d%% / confidence %d / risk %s",
            value(entry.recommendationMode, "HOLD"),
            entry.projectedWinProbability or 0,
            entry.decisionConfidenceScore or 0,
            value(entry.decisionRisk, "HIGH")),
        "Doctrine: " .. value(entry.doctrineClass, "NONE")
            .. " / " .. value(entry.doctrineBranchID, "none"),
        "Branch choice: " .. value(entry.branchChoice, "unknown")
            .. " / " .. value(entry.doctrineComparisonID, "none"),
        "Safe counter: " .. value(entry.safeCounter, "unknown")
            .. " / " .. value(entry.enemyResponseGuidanceID, "none"),
        "Enemy model: " .. value(entry.compThreat and entry.compThreat.id, "unknown")
            .. " / defense " .. value(
                entry.enemyDefenseModel and entry.enemyDefenseModel.id, "unknown"),
        "Expected outcome: " .. value(entry.expectedOutcome),
        "Switch if: " .. value(entry.switchIf),
        "Stop rule: " .. value(entry.stop),
        "Objective success: " .. value(entry.objectiveDecision
            and entry.objectiveDecision.success, "unknown"),
        "Objective abort: " .. value(entry.objectiveDecision
            and entry.objectiveDecision.abort, "unknown"),
        "Command: " .. value(entry.commandLine1),
        value(entry.commandLine2),
        value(entry.commandLine3),
        "Command data: " .. value(entry.commandSource)
            .. " / " .. value(entry.commandConfidence, "NONE")
            .. " / age " .. (entry.commandAge and string.format("%.2f sec", entry.commandAge) or "unknown")
            .. " / TTL " .. (entry.commandTTL and string.format("%.2f sec", entry.commandTTL) or "unknown")
            .. " / bypass " .. value(entry.commandBypass, "unknown"),
        string.format("Command stability: retain %.1fs / TTL %.1fs / retained %s / urgency delta %d / response bypass %s / reassessment bypass %s / emergency bypass %s",
            entry.commandStability and entry.commandStability.retentionWindow or 0,
            entry.commandStability and entry.commandStability.ttlSeconds or 0,
            entry.commandStability and entry.commandStability.retained and "YES" or "NO",
            entry.commandStability and entry.commandStability.urgencyDelta or 0,
            entry.commandStability and entry.commandStability.responseBypass and "YES" or "NO",
            entry.commandStability and entry.commandStability.reassessmentBypass and "YES" or "NO",
            entry.commandStability and entry.commandStability.emergencyBypass and "YES" or "NO"),
        string.format("Command churn: issued %d / replacements %d / stabilized %d / suppressed %d / reversals %d / pre-move invalidations %d",
            entry.commandStabilitySummary and entry.commandStabilitySummary.issued or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.replacements or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.stabilized or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.suppressed or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.reversals or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.preMovementInvalidations or 0),
        string.format("Command stability budget: %s / %s / reversal %.1f%% / pre-move %.1f%%",
            value(entry.commandStabilitySummary and entry.commandStabilitySummary.commandHealth, "UNKNOWN"),
            value(entry.commandStabilitySummary and entry.commandStabilitySummary.commandHealthReason, "No stability budget reason."),
            (entry.commandStabilitySummary and entry.commandStabilitySummary.reversalRate or 0) * 100,
            (entry.commandStabilitySummary and entry.commandStabilitySummary.preMovementInvalidationRate or 0) * 100),
        string.format("Command field certification: %s / %s",
            value(entry.commandStabilitySummary and entry.commandStabilitySummary.certificationStatus, "INSUFFICIENT_SAMPLE"),
            value(entry.commandStabilitySummary and entry.commandStabilitySummary.certificationReason, "Collect more command samples.")),
        string.format("Command churn detail: suppression persistence %d / superiority %d / overrides pre-arrival %d / overrides committed %d / invalidations pre-arrival %d / invalidations committed %d",
            entry.commandStabilitySummary and entry.commandStabilitySummary.suppressedByPersistence or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.suppressedBySuperiority or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.overridesBeforeArrival or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.overridesAfterCommitment or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.invalidationsBeforeArrival or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.invalidationsAfterCommitment or 0),
        string.format("Command result quality: successes %d / success %.1f%% / average switch advantage %.1f",
            entry.commandStabilitySummary and entry.commandStabilitySummary.successfulPlays or 0,
            (entry.commandStabilitySummary and entry.commandStabilitySummary.successRate or 0) * 100,
            entry.commandStabilitySummary and entry.commandStabilitySummary.averageSwitchAdvantage or 0),
        string.format("Command overrides: %d / invalidations %d",
            entry.commandStabilitySummary and entry.commandStabilitySummary.overrides or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.invalidations or 0),
        string.format("Command lifetime: median %.2fs / average %.2fs / shortest %.2fs / longest %.2fs",
            entry.commandStabilitySummary and entry.commandStabilitySummary.medianLifetime or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.averageLifetime or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.shortestLifetime or 0,
            entry.commandStabilitySummary and entry.commandStabilitySummary.longestLifetime or 0),
        string.format("Active play: %s / %s / %s / %s / movers %d / stayers %d / review %.2fs / commit %.2fs / arrival %.2fs / resolution %s",
            value(entry.activePlay and entry.activePlay.family, "WORLD"),
            value(entry.activePlay and entry.activePlay.phase, "EXPIRED"),
            value(entry.activePlay and entry.activePlay.objective, "none"),
            value(entry.activePlayMilestone, "NONE"),
            entry.activePlay and #(entry.activePlay.movers or {}) or 0,
            entry.activePlay and #(entry.activePlay.stayers or {}) or 0,
            entry.activePlayReviewIn or 0,
            entry.activePlayCommitIn or 0,
            entry.activePlayArrivalIn or 0,
            entry.activePlayResolutionIn ~= nil
                and string.format("%.2fs", entry.activePlayResolutionIn)
                or "unknown"),
        string.format("Active play timing: commit %.2fs / travel %.2fs / interaction %.2fs",
            entry.activePlayCommitmentSeconds or 0,
            entry.activePlayTravelSeconds or 0,
            entry.activePlayInteractionSeconds or 0),
        string.format("Active play decision: retained %s / invalidation %s / replace %s / reason %s / trend %.2fs %d wins avg %.1f",
            entry.activePlayDecision and entry.activePlayDecision.retained and "YES" or "NO",
            value(entry.activePlayDecision and entry.activePlayDecision.invalidation, "none"),
            entry.activePlayDecision and entry.activePlayDecision.replacementAllowed and "YES" or "NO",
            value(entry.activePlayDecision and entry.activePlayDecision.replacementReason, "unknown"),
            entry.activePlayTrend and entry.activePlayTrend.duration or 0,
            entry.activePlayTrend and entry.activePlayTrend.consecutiveWins or 0,
            entry.activePlayTrend and entry.activePlayTrend.averageAdvantage or 0),
        string.format("Active play gate: %s / family %s",
            value(entry.activePlayDecision and entry.activePlayDecision.gateClass, "STEADY"),
            value(entry.activePlayDecision and entry.activePlayDecision.invalidationFamily, "NONE")),
        string.format("Active play outcome: %s / %s / %s / %s",
            value(entry.activePlayOutcome and entry.activePlayOutcome.status, "LIVE"),
            value(entry.activePlayOutcome and entry.activePlayOutcome.phase, "UNKNOWN"),
            value(entry.activePlayOutcome and entry.activePlayOutcome.bucket, "PRE_ARRIVAL"),
            value(entry.activePlayOutcome and entry.activePlayOutcome.reason, "No outcome reason recorded.")),
        string.format("Active play transition: %s / %s -> %s / rule %s / age %.2fs",
            value(entry.activePlayTransition and entry.activePlayTransition.trigger, "STEADY"),
            value(entry.activePlayTransition and entry.activePlayTransition.fromPhase, "NONE"),
            value(entry.activePlayTransition and entry.activePlayTransition.toPhase, "UNKNOWN"),
            value(entry.activePlayTransition and entry.activePlayTransition.rule, "none"),
            entry.activePlayTransition and entry.activePlayTransition.age or 0),
        string.format("Persistence gate: observed %.2fs / required %.2fs",
            entry.activePlayObservedDuration or 0,
            entry.activePlayRequiredDuration or 0),
        "Active play state reason: " .. value(entry.activePlayPhaseReason, "unknown"),
        string.format("Active play override: lost %.2fs / latest %s -> %s / %s",
            entry.activePlayDecision and entry.activePlayDecision.lostCommitmentTime or 0,
            value(entry.latestOverride and entry.latestOverride.currentObjective, "none"),
            value(entry.latestOverride and entry.latestOverride.candidateObjective, "none"),
            value(entry.latestOverride and entry.latestOverride.replacementReason, "none")),
        string.format("Active play override gate: phase %s / bucket %s / observed %.2fs / required %.2fs",
            value(entry.latestOverride and entry.latestOverride.phase, "UNKNOWN"),
            value(entry.latestOverride and entry.latestOverride.phaseBucket, "UNKNOWN"),
            entry.latestOverride and entry.latestOverride.observedDuration or 0,
            entry.latestOverride and entry.latestOverride.requiredDuration or 0),
        string.format("Active play override class: %s / family %s",
            value(entry.latestOverride and entry.latestOverride.gateClass, "UNKNOWN"),
            value(entry.latestOverride and entry.latestOverride.invalidationFamily, "NONE")),
        string.format("Active play suppression: %s -> %s / %s / %s",
            value(entry.latestSuppression and entry.latestSuppression.currentObjective, "none"),
            value(entry.latestSuppression and entry.latestSuppression.candidateObjective, "none"),
            value(entry.latestSuppression and entry.latestSuppression.gateClass, "UNKNOWN"),
            value(entry.latestSuppression and entry.latestSuppression.replacementReason, "none")),
        string.format("Active play suppression gate: phase %s / bucket %s / observed %.2fs / required %.2fs",
            value(entry.latestSuppression and entry.latestSuppression.phase, "UNKNOWN"),
            value(entry.latestSuppression and entry.latestSuppression.phaseBucket, "UNKNOWN"),
            entry.latestSuppression and entry.latestSuppression.observedDuration or 0,
            entry.latestSuppression and entry.latestSuppression.requiredDuration or 0),
        string.format("Active play switch score: current %.1f / alternative %.1f / margin %.1f / cost %.1f",
            entry.activePlayDecision and entry.activePlayDecision.replacementScore
                and entry.activePlayDecision.replacementScore.currentValue or 0,
            entry.activePlayDecision and entry.activePlayDecision.replacementScore
                and entry.activePlayDecision.replacementScore.adjustedAlternative or 0,
            entry.activePlayDecision and entry.activePlayDecision.replacementScore
                and entry.activePlayDecision.replacementScore.margin or 0,
            entry.activePlayDecision and entry.activePlayDecision.replacementScore
                and entry.activePlayDecision.replacementScore.switchCost
                and entry.activePlayDecision.replacementScore.switchCost.total or 0),
        string.format("Coverage: roster %d / enemies %d / assignments %d",
            entry.roster or 0, entry.enemies or 0, entry.assignments or 0),
        string.format("Live binding: team specs %d/%d, units %d/%d; enemy specs %d/%d, units %d/%d, local engaged %d",
            entry.teamSpecs or 0, entry.roster or 0,
            entry.teamUnits or 0, entry.roster or 0,
            entry.enemySpecs or 0, entry.enemies or 0,
            entry.enemyUnits or 0, entry.enemies or 0,
            entry.enemyLocal or 0),
        string.format("Enemy visibility: %d visible / %d local / %d engaged / %d last seen",
            entry.enemyVisible or 0,
            entry.enemyLocalRange or 0,
            entry.enemyLocal or 0,
            entry.enemyLastSeen or 0),
        "Local target: " .. value(entry.localTargetName, "none")
            .. " / " .. value(entry.localTargetState, "UNKNOWN")
            .. " / " .. value(entry.localTargetReason,
                "No safely observed enemy in local fight range."),
        "Command target: " .. value(entry.commandTargetName, "none")
            .. " / " .. value(entry.commandTargetState, "UNKNOWN")
            .. " / " .. value(entry.commandTargetReason,
                "No commander target emphasis active."),
        "Assignment audit: " .. (entry.assignmentAudit and entry.assignmentAudit.ok and "PASS" or "WARN"),
        string.format("Assignment integrity: station %d / moving %d / unknown %d / abandoned %d / impossible %d",
            entry.assignmentIntegrity and entry.assignmentIntegrity.onStation or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.moving or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.unverified or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.abandoned or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.impossible or 0),
        string.format("ActivePlay switches: %d active", entry.overrideCount or 0),
        string.format("Reporter: %s / risk %d / hotspot %s / coverage %d friendly (%d located), %d enemy (%d located) / age %s",
            entry.reporterActive and "ACTIVE" or "INACTIVE",
            entry.reporterRisk or 0,
            value(entry.reporterHotspot, "none"),
            entry.reporterFriendly or 0,
            entry.reporterFriendlyLocated or 0,
            entry.reporterEnemy or 0,
            entry.reporterEnemyLocated or 0,
            entry.reporterAge and string.format("%.2f sec", entry.reporterAge) or "unknown"),
        string.format("Reporter confidence: %s / %s / %s",
            value(entry.reporterTrust and entry.reporterTrust.label, "NONE"),
            value(entry.reporterTrust and entry.reporterTrust.pace, "VERIFY_FIRST"),
            value(entry.reporterTrust and entry.reporterTrust.reason, "No reporter confidence rationale.")),
        string.format("Enemy intent: %s / %s / ETA %s",
            value(entry.enemyIntent and entry.enemyIntent.target, "unknown"),
            value(entry.enemyIntent and entry.enemyIntent.confidence, "NONE"),
            entry.enemyIntent and entry.enemyIntent.eta
                and (tostring(entry.enemyIntent.eta) .. "s") or "unknown"),
        string.format("Momentum: %s %d / resource edge %d (%s)",
            value(entry.momentum and entry.momentum.state, "UNKNOWN"),
            entry.momentum and entry.momentum.value or 0,
            entry.resourceEconomy and entry.resourceEconomy.advantage or 0,
            value(entry.resourceEconomy and entry.resourceEconomy.confidence, "NONE")),
        string.format("Priority cast: %s by %s / %s / response %s",
            value(entry.priorityCast and entry.priorityCast.name, "none"),
            value(entry.priorityCast and entry.priorityCast.source, "unknown"),
            value(entry.priorityCast and entry.priorityCast.priority, "NONE"),
            value(entry.priorityCast and entry.priorityCast.response, "UNKNOWN")),
        string.format("Opportunity: %s / score %d / duration %ds",
            entry.opportunity and entry.opportunity.open and "OPEN" or "CLOSED",
            entry.opportunity and entry.opportunity.score or 0,
            entry.opportunity and entry.opportunity.duration or 0),
        string.format("Knowledge: %s / patch aligned %s / enemy certainty %d%% / historical %d / %s",
            value(entry.knowledgeStatus and entry.knowledgeStatus.label, "NONE"),
            entry.knowledgeStatus and entry.knowledgeStatus.patchAligned and "YES" or "NO",
            math.floor(((entry.knowledgeStatus and entry.knowledgeStatus.enemyCoverage) or 0) * 100 + 0.5),
            entry.knowledgeStatus and entry.knowledgeStatus.enemyHistorical or 0,
            value(entry.knowledgeStatus and entry.knowledgeStatus.reason, "Unknown")),
        string.format("Strategy confidence: %s / %s / separation %s / %s",
            value(entry.strategyTrust and entry.strategyTrust.label, "NONE"),
            value(entry.strategyTrust and entry.strategyTrust.mode, "VERIFY"),
            tostring(entry.strategyTrust and entry.strategyTrust.separation or "unknown"),
            value(entry.strategyTrust and entry.strategyTrust.reason, "Unknown")),
        string.format("Execution: %s (%d) / commitment %s @ %s / pressure %s / rotation %s / collapse %s / organization %s %d",
            value(entry.executionAssessment
                and entry.executionAssessment.actionOpportunity
                and entry.executionAssessment.actionOpportunity.action, "UNKNOWN"),
            entry.executionAssessment
                and entry.executionAssessment.actionOpportunity
                and entry.executionAssessment.actionOpportunity.score or 0,
            value(entry.executionAssessment
                and entry.executionAssessment.commitment
                and entry.executionAssessment.commitment.state, "UNKNOWN"),
            value(entry.executionAssessment
                and entry.executionAssessment.commitment
                and entry.executionAssessment.commitment.objective, "unknown"),
            value(entry.executionAssessment
                and entry.executionAssessment.pressureForecast
                and entry.executionAssessment.pressureForecast.state, "UNKNOWN"),
            value(entry.executionAssessment
                and entry.executionAssessment.rotationEconomy
                and entry.executionAssessment.rotationEconomy.state, "UNKNOWN"),
            value(entry.executionAssessment
                and entry.executionAssessment.collapse
                and entry.executionAssessment.collapse.state, "UNKNOWN"),
            value(entry.executionAssessment
                and entry.executionAssessment.organization
                and entry.executionAssessment.organization.state, "UNKNOWN"),
            entry.executionAssessment
                and entry.executionAssessment.organization
                and entry.executionAssessment.organization.entropy or 0),
        string.format("Response package: %s / qualified %s / move %s / stay %s / confidence %s score %d",
            value(entry.responsePackage and entry.responsePackage.action,
                "HOLD CURRENT PLAN"),
            entry.responsePackage and entry.responsePackage.qualified
                and "YES" or "NO",
            value(entry.responsePackage and entry.responsePackage.moverText,
                "Team"),
            value(entry.responsePackage and entry.responsePackage.stayerText,
                "Assigned defenders"),
            value(entry.responsePackage and entry.responsePackage.confidence,
                "NONE"),
            entry.responsePackage and entry.responsePackage.score or 0),
        string.format("Performance: last %.3f ms / p95 %.3f ms / memory %.1f KB",
            entry.refreshMs or 0, entry.p95Ms or 0, entry.memoryKB or 0),
        string.format("Transitions: last %.3f ms / addon initialize %.3f ms",
            entry.transitionMs or 0, entry.bootMs or 0),
        string.format("Refresh queue: coalesced %d / followups %d / preemptions %d / settles %d",
            entry.queueCoalesced or 0,
            entry.queueFollowups or 0,
            entry.queuePreemptions or 0,
            entry.settleRefreshes or 0),
        "Runtime errors: " .. tostring(entry.errors or 0),
        string.format("Retention budget: %.1f MB target / %s current",
            entry.retention and entry.retention.softCapMB or 0,
            (entry.retention and entry.retention.currentMB)
                and string.format("%.2f MB", entry.retention.currentMB)
                or "unavailable"),
        string.format("Retention usage: AAR %d/%d | Enc %d/%d | Opp %d/%d | Match %d/%d | Notes %d/%d | Learn %d/%d | Verify %d/%d",
            entry.retention and entry.retention.history and entry.retention.history.count or 0,
            entry.retention and entry.retention.history and entry.retention.history.cap or 0,
            entry.retention and entry.retention.encounters and entry.retention.encounters.count or 0,
            entry.retention and entry.retention.encounters and entry.retention.encounters.cap or 0,
            entry.retention and entry.retention.opponentProfiles and entry.retention.opponentProfiles.count or 0,
            entry.retention and entry.retention.opponentProfiles and entry.retention.opponentProfiles.cap or 0,
            entry.retention and entry.retention.processedMatches and entry.retention.processedMatches.count or 0,
            entry.retention and entry.retention.processedMatches and entry.retention.processedMatches.cap or 0,
            entry.retention and entry.retention.enemyNotes and entry.retention.enemyNotes.count or 0,
            entry.retention and entry.retention.enemyNotes and entry.retention.enemyNotes.cap or 0,
            entry.retention and entry.retention.learningPlans and entry.retention.learningPlans.count or 0,
            entry.retention and entry.retention.learningPlans and entry.retention.learningPlans.cap or 0,
            entry.retention and entry.retention.verificationLedger and entry.retention.verificationLedger.count or 0,
            entry.retention and entry.retention.verificationLedger and entry.retention.verificationLedger.cap or 0),
    }
    for _, assignment in ipairs(entry.assignmentDetails or {}) do
        lines[#lines + 1] = "ASSIGN: " .. assignment
    end
    for _, problem in ipairs(entry.activeProblemDetails or {}) do
        lines[#lines + 1] = "PROBLEM: " .. problem
    end
    for _, detail in ipairs(entry.objectiveDetails or {}) do
        lines[#lines + 1] = "OBJ: " .. detail
    end
    for _, override in ipairs(entry.overrideDetails or {}) do
        lines[#lines + 1] = "OVERRIDE: " .. override
    end
    for _, alternative in ipairs(entry.alternativeReview or {}) do
        lines[#lines + 1] = "ALT: " .. value(alternative.id)
            .. " @ " .. value(alternative.target, "unknown")
            .. " / " .. tostring(alternative.score or 0)
            .. " / " .. value(alternative.reason, "weaker option")
    end
    for _, issue in ipairs(entry.audit and entry.audit.issues or {}) do
        lines[#lines + 1] = "WARN: " .. issue
    end
    return table.concat(lines, "\n")
end

function Verification:CurrentReport()
    return self:Format(self:BuildEntry(KWR.Store:Get()))
end

function Verification:LedgerReport()
    local lines = {
        "KWR MATCH EVIDENCE LEDGER",
        "Version: " .. value(KWR.version),
        "Transitions: " .. tostring(#self.ledger),
        "",
    }
    for index, entry in ipairs(self.ledger) do
        lines[#lines + 1] = string.format(
            "%02d  %s  %s  %d-%d  OBJ %s  %s  %s  %.3fms",
            index,
            value(entry.mapKey),
            value(entry.team),
            entry.friendlyScore or 0,
            entry.enemyScore or 0,
            value(entry.objectiveSummary),
            value(entry.prediction),
            value(entry.planID, "none"),
            entry.refreshMs or 0
        )
    end
    return table.concat(lines, "\n")
end

function Verification:FieldReport()
    local latest = KWR.AAR and KWR.AAR:GetHistory()
        and KWR.AAR:GetHistory()[#KWR.AAR:GetHistory()]
    local aar = KWR.AAR and KWR.AAR.active
        and ("ACTIVE " .. value(KWR.AAR.active.mapName))
        or (latest and string.format("%s | %s | %d-%d",
            value(latest.mapName),
            value(latest.result),
            latest.scoreEnd and latest.scoreEnd.friendly or 0,
            latest.scoreEnd and latest.scoreEnd.enemy or 0)
        or "NONE")
    return table.concat({
        "KWR FIELD DEFECT BUNDLE",
        "Generated locally; contains no automatic transmission.",
        "",
        self:CurrentReport(),
        "",
        "LATEST AAR: " .. aar,
        "",
        self:LedgerReport(),
    }, "\n")
end

function Verification:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "Verification")
    end
    if KWR.Store and KWR.Store.Subscribe then
        KWR.Store:Subscribe(self, self.Update)
    end
end

function Verification:OnDisable()
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
end

KWR:RegisterModule("Verification", Verification)
