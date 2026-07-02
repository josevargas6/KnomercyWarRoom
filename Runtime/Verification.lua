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
    return {
        ok = #issues == 0,
        status = #issues == 0 and "PASS" or "WARN",
        issues = issues,
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
    local reporter = snapshot.reporter or {}
    local reporterCoverage = reporter.coverage or {}
    local now = KWR.Util:Now()
    local assignmentAudit = KWR.Assignments:Audit(snapshot, state.assignments)
    local audit = self:Audit(state)
    local teamSpecs, teamUnits, enemySpecs, enemyUnits, enemyLocal = 0, 0, 0, 0, 0
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
        if enemy.localEngaged then enemyLocal = enemyLocal + 1 end
    end
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
        scoreAge = age(score.observedAt, now),
        objectiveSource = objectives.source,
        objectiveWidget = objectives.widgetID,
        objectiveAge = age(objectives.observedAt, now),
        objectiveSummary = objectiveSummary(objectives),
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
        executionAssessment = strategy.executionAssessment,
        responsePackage = snapshot.responsePackage,
        simulations = strategy.simulations,
        switchIf = strategy.switchIf,
        stop = strategy.stop,
        objectiveDecision = strategy.objectiveDecision,
        weightedFocus = strategy.weightedFocus,
        roster = #(snapshot.roster or {}),
        enemies = #(snapshot.enemies or {}),
        teamSpecs = teamSpecs,
        teamUnits = teamUnits,
        enemySpecs = enemySpecs,
        enemyUnits = enemyUnits,
        enemyLocal = enemyLocal,
        assignments = #(state.assignments or {}),
        assignmentAudit = assignmentAudit,
        assignmentDetails = assignmentSummary(state.assignments),
        commandLine1 = command.line1,
        commandLine2 = command.line2,
        commandLine3 = command.line3,
        commandSource = command.source,
        commandConfidence = command.confidence,
        commandAge = age(command.createdAt, now),
        commandTTL = command.expiresAt and math.max(0, command.expiresAt - now) or nil,
        reporterActive = reporter.active == true,
        reporterRisk = reporter.risk or 0,
        reporterHotspot = reporter.hotspot and reporter.hotspot.label,
        reporterFriendly = reporterCoverage.friendly or 0,
        reporterEnemy = reporterCoverage.enemy or 0,
        reporterFriendlyLocated = reporterCoverage.friendlyLocated or 0,
        reporterEnemyLocated = reporterCoverage.enemyLocated or 0,
        reporterAge = age(reporter.updatedAt, now),
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
        bootMs = KWR.bootDiagnostics and KWR.bootDiagnostics.initializeMs or 0,
        errors = diagnostics.errors or 0,
        audit = audit,
    }
end

function Verification:Update(state)
    local snapshot = state and state.snapshot
    if not snapshot or not snapshot.context or not snapshot.context.inPvP
        or snapshot.context.preview then return end
    local entry = self:BuildEntry(state)
    local signature = KWR.Util:Signature({
        entry.mapKey,
        entry.team,
        entry.friendlyScore,
        entry.enemyScore,
        entry.objectiveSummary,
        entry.prediction,
        entry.planID,
    })
    if signature == self.lastSignature then return end
    self.lastSignature = signature
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
        "Bracket rules: " .. value(entry.bracket),
        "Assigned team: " .. value(entry.team) .. " / " .. value(entry.teamSide)
            .. " / score faction " .. tostring(entry.scoreFaction or "unknown"),
        "Team evidence: " .. value(entry.teamSource) .. " / votes " .. tostring(entry.teamVotes or 0),
        "Raw widget score: " .. tostring(entry.rawLeft or "unknown")
            .. " left / " .. tostring(entry.rawRight or "unknown") .. " right",
        "Friendly score: " .. tostring(entry.friendlyScore or 0)
            .. " - " .. tostring(entry.enemyScore or 0)
            .. " / " .. tostring(entry.maxScore or 0),
        "Score source: " .. value(entry.scoreSource)
            .. " / widget " .. tostring(entry.scoreWidget or "unknown")
            .. " / age " .. (entry.scoreAge and string.format("%.2f sec", entry.scoreAge) or "unknown"),
        "Objectives: " .. value(entry.objectiveSummary),
        "Objective source: " .. value(entry.objectiveSource)
            .. " / age " .. (entry.objectiveAge and string.format("%.2f sec", entry.objectiveAge) or "unknown"),
        "Objective widget: " .. tostring(entry.objectiveWidget or "unknown"),
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
        "Command evidence: " .. value(entry.commandSource)
            .. " / " .. value(entry.commandConfidence, "NONE")
            .. " / age " .. (entry.commandAge and string.format("%.2f sec", entry.commandAge) or "unknown")
            .. " / TTL " .. (entry.commandTTL and string.format("%.2f sec", entry.commandTTL) or "unknown"),
        string.format("Coverage: roster %d / enemies %d / assignments %d",
            entry.roster or 0, entry.enemies or 0, entry.assignments or 0),
        string.format("Live binding: team specs %d/%d, units %d/%d; enemy specs %d/%d, units %d/%d, local engaged %d",
            entry.teamSpecs or 0, entry.roster or 0,
            entry.teamUnits or 0, entry.roster or 0,
            entry.enemySpecs or 0, entry.enemies or 0,
            entry.enemyUnits or 0, entry.enemies or 0,
            entry.enemyLocal or 0),
        "Assignment audit: " .. (entry.assignmentAudit and entry.assignmentAudit.ok and "PASS" or "WARN"),
        string.format("Assignment integrity: station %d / moving %d / unknown %d / abandoned %d / impossible %d",
            entry.assignmentIntegrity and entry.assignmentIntegrity.onStation or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.moving or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.unverified or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.abandoned or 0,
            entry.assignmentIntegrity and entry.assignmentIntegrity.impossible or 0),
        string.format("Reporter: %s / risk %d / hotspot %s / coverage %d friendly (%d located), %d enemy (%d located) / age %s",
            entry.reporterActive and "ACTIVE" or "INACTIVE",
            entry.reporterRisk or 0,
            value(entry.reporterHotspot, "none"),
            entry.reporterFriendly or 0,
            entry.reporterFriendlyLocated or 0,
            entry.reporterEnemy or 0,
            entry.reporterEnemyLocated or 0,
            entry.reporterAge and string.format("%.2f sec", entry.reporterAge) or "unknown"),
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
        "Runtime errors: " .. tostring(entry.errors or 0),
    }
    for _, assignment in ipairs(entry.assignmentDetails or {}) do
        lines[#lines + 1] = "ASSIGN: " .. assignment
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
    KWR.Store:Subscribe(self, self.Update)
end

function Verification:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("Verification", Verification)
