local _, KWR = ...

local Runtime = {
    active = false,
    pending = false,
    pendingDueAt = nil,
    pendingReason = nil,
    queueRevision = 0,
    timerToken = 0,
    requiredSettleAt = nil,
    transitionToken = 0,
    ticker = nil,
    lastMessage = "",
    diagnostics = {
        refreshes = 0,
        lastReason = "startup",
        lastDurationMs = 0,
        averageDurationMs = 0,
        p95DurationMs = 0,
        durationSampleCount = 0,
        maxDurationMs = 0,
        memoryKB = 0,
        events = 0,
        coalesced = 0,
        queueFollowups = 0,
        queuePreemptions = 0,
        settleRefreshes = 0,
        errors = 0,
        transitionRefreshes = 0,
        lastTransitionDurationMs = 0,
    },
    durationSamples = {},
    maxDurationSamples = 120,
}
KWR.MatchRuntime = Runtime

local MIN_REFRESH_INTERVAL = 0.40
local MAX_CHAINED_FOLLOWUPS = 1
local ROSTER_PRESENTATION_TIMEOUT = 8

local function firstLine(value)
    local text = tostring(value or "unknown runtime refresh error")
    return text:match("([^\r\n]+)") or text
end

local function runtimeErrorHandler(err)
    local message = tostring(err or "unknown runtime refresh error")
    local stack
    if type(debugstack) == "function" then
        local ok, value = pcall(debugstack, 3, 8, 8)
        if ok and type(value) == "string" and value ~= "" then
            stack = value
        end
    elseif debug and type(debug.traceback) == "function" then
        local ok, value = pcall(debug.traceback, message, 3)
        if ok and type(value) == "string" and value ~= "" then
            stack = value
        end
    end
    local formatted = stack and (message .. "\n" .. stack) or message
    if type(geterrorhandler) == "function" then
        local ok, handler = pcall(geterrorhandler)
        if ok and type(handler) == "function" then
            pcall(handler, formatted)
        end
    end
    return formatted
end

local function previewAvailable()
    return KWR.Preview and type(KWR.Preview.Build) == "function"
end

local function clearQueueState(runtime)
    runtime.pending = false
    runtime.pendingDueAt = nil
    runtime.pendingReason = nil
    runtime.pendingRevision = nil
    runtime.pendingSettle = nil
end

local function recordStage(runtime, name, started)
    if not started or started <= 0 or type(debugprofilestop) ~= "function" then return end
    runtime.diagnostics.stageMs = runtime.diagnostics.stageMs or {}
    runtime.diagnostics.stageMs[name] = math.max(0, debugprofilestop() - started)
end

local PERSISTENT_EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEAVING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "GROUP_ROSTER_UPDATE",
    "UNIT_NAME_UPDATE",
    "PLAYER_ROLES_ASSIGNED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "UPDATE_BATTLEFIELD_STATUS",
}

local ACTIVE_EVENTS = {
    "PVP_MATCH_ACTIVE",
    "PVP_MATCH_COMPLETE",
    "UPDATE_BATTLEFIELD_SCORE",
    "UPDATE_ACTIVE_BATTLEFIELD",
    "BATTLEGROUND_POINTS_UPDATE",
    "UPDATE_UI_WIDGET",
    "AREA_POIS_UPDATED",
    "VIGNETTES_UPDATED",
    "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED",
    "UPDATE_MOUSEOVER_UNIT",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_FOCUS_CHANGED",
    "PLAYER_SOFT_ENEMY_CHANGED",
    "UNIT_TARGET",
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_AURA",
    "ARENA_OPPONENT_UPDATE",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_SUCCEEDED",
    "CHAT_MSG_BG_SYSTEM_ALLIANCE",
    "CHAT_MSG_BG_SYSTEM_HORDE",
    "CHAT_MSG_BG_SYSTEM_NEUTRAL",
    "PLAYER_DEAD",
    "PLAYER_ALIVE",
    "PLAYER_UNGHOST",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
}

local function isPvP()
    local inside, instanceType = KWR.Util:Call(IsInInstance)
    return KWR.Util:Boolean(inside, false)
        and KWR.Util:Text(instanceType, "none", 16) == "pvp"
end

local function isFriendlyObjectiveCarrier(unit)
    if not unit or type(UnitIsFriend) ~= "function"
        or not KWR.Util:Boolean(KWR.Util:Call(UnitIsFriend, "player", unit), false) then
        return false
    end
    local state = KWR.Store and KWR.Store:Get()
    local carriers = state and state.snapshot and state.snapshot.objectives
        and state.snapshot.objectives.carriers or {}
    local unitName = KWR.Util:ShortName(KWR.Util:UnitName(unit)):lower()
    for _, carrier in ipairs(carriers) do
        if carrier.owner == "FRIENDLY"
            and KWR.Util:ShortName(carrier.player):lower() == unitName then
            return true
        end
    end
    return false
end

local function stableIdentityCount(rows)
    if type(rows) ~= "table" or #rows == 0 then return 0, false end
    local seen, count = {}, 0
    for _, row in ipairs(rows) do
        local key = KWR.Util:CanonicalPlayerKey(
            row and (row.name or row.shortName), row and row.guid)
        if not key or seen[key] then return count, false end
        seen[key] = true
        count = count + 1
    end
    return count, count == #rows
end

function Runtime:ResetTransientTruth()
    self.lastFriendlyHealthSyncAt = nil
    self.postMatchTruth = nil
    self.rosterPresentation = nil
    if KWR.Sensors then
        KWR.Sensors.scoreSession = nil
    end
    if KWR.TeamResolver and KWR.TeamResolver.Reset then
        KWR.TeamResolver:Reset()
    end
    if KWR.Reporter and KWR.Reporter.Reset then
        KWR.Reporter:Reset(nil)
    end
    if KWR.EnemyIntel and KWR.EnemyIntel.Reset then
        KWR.EnemyIntel:Reset(nil)
    end
    if KWR.ObjectiveIntel and KWR.ObjectiveIntel.Reset then
        KWR.ObjectiveIntel:Reset(nil)
    end
    if KWR.CombatIntel and KWR.CombatIntel.Reset then
        KWR.CombatIntel:Reset()
    end
    if KWR.Commander and KWR.Commander.ResetSession then
        KWR.Commander:ResetSession()
    end
    if KWR.SentinelIngress then KWR.SentinelIngress:Reset() end
    if KWR.EncounterHistory then
        KWR.EncounterHistory.sessionKey = nil
        KWR.EncounterHistory.sessionSeen = {}
    end
    if KWR.OpponentModels and KWR.OpponentModels.ResetSession then
        KWR.OpponentModels:ResetSession(nil)
    end
    if KWR.Assignments and KWR.Assignments.integrity then
        KWR.Assignments.integrity = { sessionKey = nil, records = {} }
    end
end

function Runtime:AnnotateRosterPresentation(snapshot)
    local context = snapshot and snapshot.context or {}
    if context.inPvP ~= true or context.preview == true then
        self.rosterPresentation = nil
        context.rosterPresentation = { ready = true, reason = "not_pvp" }
        return
    end

    local now = KWR.Util:Now()
    local sessionKey = KWR.Util:Text(context.sessionKey, "", 96)
    local presentation = self.rosterPresentation
    if not presentation or presentation.sessionKey ~= sessionKey then
        presentation = {
            sessionKey = sessionKey,
            startedAt = now,
        }
        self.rosterPresentation = presentation
    end

    local roster = snapshot.roster or {}
    local hydration = type(context.rosterHydration) == "table"
        and context.rosterHydration or {}
    local expected = math.max(#roster,
        KWR.Util:Number(hydration.expected, #roster) or #roster)
    local stable = #roster > 0
    for _, player in ipairs(roster) do
        if player.unitStable ~= true then
            stable = false
            break
        end
    end
    local complete = expected > 0 and #roster >= expected and stable
    local timedOut = now - (presentation.startedAt or now)
        >= ROSTER_PRESENTATION_TIMEOUT
    local ready = complete or timedOut
    context.rosterPresentation = {
        ready = ready,
        reason = complete and "complete" or (timedOut and "timeout" or "hydrating"),
        expected = expected,
        observed = #roster,
        stable = stable,
        startedAt = presentation.startedAt,
    }
end

function Runtime:RememberQualifiedTruth(snapshot)
    if not snapshot or not snapshot.context or not snapshot.context.inPvP
        or snapshot.context.preview then
        return
    end
    local sessionKey = KWR.Util:Text(snapshot.context.sessionKey,
        KWR.Util:BattlefieldSessionKey(snapshot.context), 96)
    if not self.postMatchTruth
        or self.postMatchTruth.sessionKey ~= sessionKey then
        self.postMatchTruth = { sessionKey = sessionKey }
    end
    local cached = self.postMatchTruth
    local team = snapshot.context.team or {}
    local sourceRank = {
        scoreboard_self = 4,
        scoreboard_roster = 3,
        native_lock = 2,
        native_fallback = 1,
    }
    local teamSource = KWR.Util:Text(team.source, "unresolved", 24)
    local currentRank = sourceRank[teamSource] or 0
    local cachedRank = cached.team and (sourceRank[
        KWR.Util:Text(cached.team.source, "unresolved", 24)] or 0) or 0
    if team.side ~= nil
        and KWR.Util:Text(team.faction, "Unknown", 16) ~= "Unknown"
        and currentRank >= cachedRank then
        cached.team = KWR.Util:Copy(team)
    end
    if snapshot.score and snapshot.score.source == "ui_widget" then
        cached.score = KWR.Util:Copy(snapshot.score)
    end
    if snapshot.objectives and snapshot.objectives.source == "ui_widget" then
        cached.objectives = KWR.Util:Copy(snapshot.objectives)
    end
    if snapshot.context.isBlitz == true then
        cached.isBlitz = true
        cached.blitzSource = KWR.Util:Text(
            snapshot.context.blitzSource, "confirmed", 32)
    end
    local rosterCount, rosterStable = stableIdentityCount(snapshot.roster)
    if rosterStable and rosterCount > 1
        and rosterCount >= (cached.rosterCount or 0) then
        cached.roster = KWR.Util:Copy(snapshot.roster)
        cached.rosterCount = rosterCount
    end
    local enemyCount, enemiesStable = stableIdentityCount(snapshot.enemies)
    if enemiesStable and enemyCount > 1
        and enemyCount >= (cached.enemyCount or 0) then
        cached.enemies = KWR.Util:Copy(snapshot.enemies)
        cached.enemyCount = enemyCount
    end
end

function Runtime:ApplyMatchCompleteFallback(snapshot)
    if not snapshot or not snapshot.context or not snapshot.context.inPvP then
        return snapshot
    end
    self:RememberQualifiedTruth(snapshot)
    if self.matchComplete ~= true then
        return snapshot
    end
    snapshot.context.matchComplete = true
    snapshot.context.phase = "COMPLETE"
    local sessionKey = KWR.Util:Text(snapshot.context.sessionKey,
        KWR.Util:BattlefieldSessionKey(snapshot.context), 96)
    local cached = self.postMatchTruth
    if not cached or cached.sessionKey ~= sessionKey then
        return snapshot
    end
    local team = snapshot.context.team or {}
    if cached.team and (team.side == nil
        or team.source == "scoreboard_pending"
        or team.source == "native_fallback"
        or team.source == "native_lock") then
        snapshot.context.team = KWR.Util:Copy(cached.team)
        snapshot.context.team.postMatchFrozen = true
    end
    if cached.score and snapshot.score
        and snapshot.score.source ~= "ui_widget" then
        snapshot.score = KWR.Util:Copy(cached.score)
        snapshot.score.postMatchFrozen = true
    end
    if cached.objectives and snapshot.objectives
        and snapshot.objectives.source ~= "ui_widget" then
        snapshot.objectives = KWR.Util:Copy(cached.objectives)
        snapshot.objectives.postMatchFrozen = true
    end
    if cached.isBlitz then
        snapshot.context.isBlitz = true
        snapshot.context.blitzSource = cached.blitzSource or "confirmed"
    end
    local rosterCount = stableIdentityCount(snapshot.roster)
    if cached.roster and rosterCount < (cached.rosterCount or 0) then
        snapshot.roster = KWR.Util:Copy(cached.roster)
        snapshot.context.rosterPostMatchFrozen = true
    end
    local enemyCount = stableIdentityCount(snapshot.enemies)
    if cached.enemies and enemyCount < (cached.enemyCount or 0) then
        snapshot.enemies = KWR.Util:Copy(cached.enemies)
        snapshot.context.enemiesPostMatchFrozen = true
    end
    return snapshot
end

function Runtime:Start()
    if self.active then return end
    self.matchComplete = false
    self.active = true
    if C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(1, function()
            if Runtime.active then Runtime:Queue("active-pulse", 0.02) end
        end)
    end
end

function Runtime:Stop()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.active = false
end

function Runtime:UpdateLifecycle()
    if isPvP() then self:Start() else self:Stop() end
end

function Runtime:ScheduleTransitionSweep(reason, rosterOnly)
    self.transitionToken = (self.transitionToken or 0) + 1
    local token = self.transitionToken
    local delays = rosterOnly and { 0.20, 0.80, 2.00, 5.00 }
        or { 0.15, 0.65, 1.50, 3.00, 6.00, 10.00 }
    for _, delay in ipairs(delays) do
        local settleDelay = delay
        local function settle()
            if token ~= Runtime.transitionToken then return end
            Runtime:Queue((reason or "transition") .. "-settle", 0.02)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(settleDelay, settle)
        else
            settle()
        end
    end
end

function Runtime:ScheduleFinalSweep(reason)
    self.finalSweepToken = (self.finalSweepToken or 0) + 1
    local token = self.finalSweepToken
    local delays = { 0.35, 1.00, 2.25 }
    for index, delay in ipairs(delays) do
        local function settle()
            if token ~= Runtime.finalSweepToken then return end
            Runtime:Queue((reason or "match-complete") .. "-" .. tostring(index), 0.02)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(delay, settle)
        else
            settle()
        end
    end
end

function Runtime:Refresh(reason)
    local started = type(debugprofilestop) == "function" and debugprofilestop() or 0
    local ok, message = xpcall(function()
        local snapshot
        -- The test driver models debugprofilestop as a single start/stop pair
        -- per refresh.  Retail gets the finer live-stage signal; deterministic
        -- offline timing remains a faithful end-to-end measurement.
        local profileStages = rawget(_G, "KWR_TEST_ENV") ~= true
        local stageStarted = profileStages and started or 0
        if KWR.db.profile.preview and not isPvP() and previewAvailable() then
            snapshot = KWR.Preview:Build()
        else
            if KWR.db.profile.preview and not previewAvailable() then
                KWR.db.profile.preview = false
            end
            snapshot = KWR.Sensors:Capture(self.lastMessage)
        end
        recordStage(self, "Sensors", stageStarted)
        stageStarted = profileStages and debugprofilestop() or 0
        snapshot.context.matchComplete = self.matchComplete == true
        snapshot = self:ApplyMatchCompleteFallback(snapshot)
        self:AnnotateRosterPresentation(snapshot)
        if KWR.SentinelMerge then
            snapshot = KWR.SentinelMerge:Apply(snapshot)
        end
        snapshot = KWR.EncounterHistory:Enrich(snapshot)
        if KWR.KnowledgeManifest and KWR.KnowledgeManifest.Status then
            snapshot.knowledgeStatus = KWR.KnowledgeManifest:Status(snapshot)
        end
        recordStage(self, "Truth", stageStarted)
        stageStarted = profileStages and debugprofilestop() or 0
        KWR.RosterInspector:RequestNext(snapshot.roster)
        snapshot = KWR.ObjectiveIntel:Apply(snapshot)
        snapshot.formation = KWR.FormationAdvisor:Evaluate(snapshot)
        snapshot.combat = KWR.CombatIntel:Analyze(snapshot)
        snapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(snapshot)
        snapshot.reporter = KWR.Reporter:Observe(snapshot)
        if KWR.OpponentModels and KWR.OpponentModels.Observe then
            snapshot.opponentModels = KWR.OpponentModels:Observe(snapshot)
        end
        snapshot.truth = KWR.Verification:Contract(snapshot)
        recordStage(self, "Battlefield", stageStarted)
        stageStarted = profileStages and debugprofilestop() or 0
        local prediction = KWR.Predictor:Evaluate(snapshot)
        snapshot.strategy = KWR.Strategist:Evaluate(snapshot, prediction)
        recordStage(self, "Strategy", stageStarted)
        stageStarted = profileStages and debugprofilestop() or 0
        local assignments = KWR.Assignments:Build(snapshot, prediction)
        snapshot.assignmentIntegrity = KWR.Assignments:Integrity(snapshot, assignments)
        snapshot.strategy.executionAssessment =
            KWR.Strategist:AssessExecution(snapshot, prediction, assignments)
        snapshot.responsePackage =
            KWR.Assignments:ResponsePackage(snapshot, assignments)
        recordStage(self, "Assignments", stageStarted)
        stageStarted = profileStages and debugprofilestop() or 0
        if self.reassessRequested then
            local previous = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
            local changes = KWR.Assignments:Diff(
                previous and previous.assignments, assignments)
            snapshot.reassessment = {
                at = KWR.Util:Now(),
                changes = changes,
                summary = KWR.Assignments:SummarizeChanges(
                    changes, snapshot.context.mapKey),
                reason = "Manual battlefield reassessment",
            }
            self.lastReassessment = KWR.Util:Copy(snapshot.reassessment)
            self.reassessRequested = false
        elseif self.lastReassessment
            and (KWR.Util:Now() - (self.lastReassessment.at or 0)) <= 10 then
            snapshot.reassessment = KWR.Util:Copy(self.lastReassessment)
        end
        local command = KWR.Commander:Compose(snapshot, prediction, assignments)
        snapshot.executionCommand = KWR.ExecutionCommandBuilder:Build(
            snapshot, prediction, assignments, command)
        snapshot.commandEmphasis = KWR.CommandEmphasis:Build(
            snapshot, prediction, assignments, command)
        recordStage(self, "Command", stageStarted)
        self.diagnostics.refreshes = self.diagnostics.refreshes + 1
        self.diagnostics.lastReason = reason or "refresh"
        if started > 0 and type(debugprofilestop) == "function" then
            local duration = math.max(0, debugprofilestop() - started)
            self.diagnostics.lastDurationMs = duration
            self.diagnostics.maxDurationMs = math.max(self.diagnostics.maxDurationMs or 0, duration)
            self.durationSamples[#self.durationSamples + 1] = duration
            if reason == "PLAYER_ENTERING_WORLD" or reason == "ZONE_CHANGED_NEW_AREA"
                or reason == "login" then
                self.diagnostics.transitionRefreshes = (self.diagnostics.transitionRefreshes or 0) + 1
                self.diagnostics.lastTransitionDurationMs = duration
            end
            while #self.durationSamples > (self.maxDurationSamples or 120) do
                table.remove(self.durationSamples, 1)
            end
            self.diagnostics.durationSampleCount = #self.durationSamples
            if self.diagnostics.refreshes % 10 == 0 then
                local ordered, total = {}, 0
                for index, sample in ipairs(self.durationSamples) do
                    ordered[index] = sample
                    total = total + sample
                end
                table.sort(ordered)
                self.diagnostics.averageDurationMs = #ordered > 0 and total / #ordered or 0
                local p95 = math.max(1, math.ceil(#ordered * 0.95))
                self.diagnostics.p95DurationMs = ordered[p95] or 0
                local memoryMB = KWR.MemoryBudget and KWR.MemoryBudget.MeasureMB
                    and KWR.MemoryBudget:MeasureMB() or nil
                self.diagnostics.memoryKB = KWR.Util:Number(memoryMB, nil)
                    and (memoryMB * 1024) or 0
            end
        end
        self.lastRefreshAt = KWR.Util:Now()
        if KWR.Store and KWR.Store.Publish then
            local published = KWR.Store:Publish(
                snapshot, prediction, assignments, command, KWR.Util:Copy(self.diagnostics))
            if KWR.CommandAudio then KWR.CommandAudio:Observe(published) end
            if KWR.CommanderComm then KWR.CommanderComm:Relay(published) end
        end
    end, runtimeErrorHandler)
    if not ok then
        self.diagnostics.errors = self.diagnostics.errors + 1
        self.diagnostics.lastError = tostring(message or "unknown runtime refresh error")
        self.diagnostics.lastErrorAt = KWR.Util and KWR.Util.Now and KWR.Util:Now() or 0
        self.diagnostics.lastErrorReason = reason or "refresh"
        KWR:Print("Runtime refresh failed: " .. firstLine(message), true)
    end
    return ok
end

function Runtime:EffectiveDelay(delay)
    local elapsed = KWR.Util:Now() - (self.lastRefreshAt or 0)
    return math.max(delay or 0.10, math.max(0, MIN_REFRESH_INTERVAL - elapsed))
end

function Runtime:Schedule(reason, delay, revision)
    self.pending = true
    self.pendingReason = reason or "queued"
    self.pendingRevision = revision or self.queueRevision or 0
    self.pendingSettle = self.pendingReason == "settle-refresh"
    delay = self:EffectiveDelay(delay)
    self.pendingDueAt = KWR.Util:Now() + delay
    self.timerToken = (self.timerToken or 0) + 1
    local token = self.timerToken
    local function run()
        if token ~= Runtime.timerToken then return end
        local dueAt = Runtime.pendingDueAt or KWR.Util:Now()
        local completedReason = Runtime.pendingReason or reason or "queued"
        local completedRevision = Runtime.pendingRevision or revision or 0
        local completedSettle = Runtime.pendingSettle == true
        clearQueueState(Runtime)
        Runtime:UpdateLifecycle()
        Runtime:Refresh(completedReason)
        local now = KWR.Util:Now()
        local timerMatured = now + 0.001 >= dueAt
        local latestRevision = Runtime.queueRevision or 0
        local hasNewRevision = latestRevision > completedRevision
        local settleStillPending = Runtime.requiredSettleAt
            and now + 0.001 < Runtime.requiredSettleAt
        local canChainFollowup = completedSettle ~= true
            and (Runtime.followupChainCount or 0) < MAX_CHAINED_FOLLOWUPS
        if timerMatured and hasNewRevision and canChainFollowup then
            Runtime.diagnostics.queueFollowups =
                (Runtime.diagnostics.queueFollowups or 0) + 1
            Runtime.followupChainCount = (Runtime.followupChainCount or 0) + 1
            Runtime:Schedule("coalesced-followup", 0.02,
                latestRevision)
        elseif timerMatured and settleStillPending then
            Runtime.followupChainCount = 0
            if not Runtime.pending then
                Runtime:Schedule("settle-refresh",
                    Runtime.requiredSettleAt - now,
                    latestRevision)
            end
        else
            Runtime.followupChainCount = 0
        end
        if Runtime.requiredSettleAt and now + 0.001 >= Runtime.requiredSettleAt then
            Runtime.requiredSettleAt = nil
            Runtime.diagnostics.settleRefreshes =
                (Runtime.diagnostics.settleRefreshes or 0) + 1
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, run)
    else
        run()
    end
end

function Runtime:Queue(reason, delay, settleDelay)
    self.queueRevision = (self.queueRevision or 0) + 1
    local revision = self.queueRevision
    local now = KWR.Util:Now()
    if settleDelay and settleDelay > 0 then
        self.requiredSettleAt = math.max(
            self.requiredSettleAt or 0, now + settleDelay)
    end
    if self.pending then
        self.diagnostics.coalesced = (self.diagnostics.coalesced or 0) + 1
        local requestedDueAt = now + self:EffectiveDelay(delay)
        if self.pendingDueAt and requestedDueAt + 0.001 < self.pendingDueAt then
            self.diagnostics.queuePreemptions =
                (self.diagnostics.queuePreemptions or 0) + 1
            self.timerToken = (self.timerToken or 0) + 1
            clearQueueState(self)
            self:Schedule(reason, delay, revision)
        end
        return
    end
    self:Schedule(reason, delay, revision)
end

function Runtime:ForceRefresh(reason)
    self.timerToken = (self.timerToken or 0) + 1
    clearQueueState(self)
    self.followupChainCount = 0
    self.queueRevision = (self.queueRevision or 0) + 1
    self:UpdateLifecycle()
    local ok = self:Refresh(reason or "manual")
    local now = KWR.Util:Now()
    if self.requiredSettleAt then
        if now + 0.001 < self.requiredSettleAt then
            self:Schedule("settle-refresh",
                self.requiredSettleAt - now, self.queueRevision)
        else
            self.requiredSettleAt = nil
        end
    end
    return ok
end

function Runtime:Reassess()
    self.reassessRequested = true
    local ok = self:ForceRefresh("manual-reassess")
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    if ok and state and state.command then
        KWR:Print("Reassessed: " .. KWR.Util:Text(state.command.action,
            "Current plan confirmed.", 120), true)
    else
        KWR:Print("Reassessment failed. Open /kwr verify and capture the warning.", true)
    end
    return ok
end

function Runtime:RescanRoster()
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    local roster = state and state.snapshot and state.snapshot.roster or nil
    local queued = 0
    if KWR.RosterInspector and type(KWR.RosterInspector.BeginFullRescan) == "function" then
        queued = KWR.RosterInspector:BeginFullRescan(roster)
    end
    local ok = self:ForceRefresh("manual-roster-rescan")
    self:ScheduleTransitionSweep("manual-roster-rescan", true)
    if ok then
        if queued > 0 then
            KWR:Print("Roster rescan started for " .. tostring(queued)
                .. " teammates. KWR will rebuild comp as fresh specs verify.", true)
        else
            KWR:Print("Roster rescan complete. No inspectable teammates needed a forced recheck.", true)
        end
    else
        KWR:Print("Roster rescan failed. Open /kwr verify and capture the warning.", true)
    end
    return ok
end

function Runtime:HandleEvent(event, ...)
    self.diagnostics.events = (self.diagnostics.events or 0) + 1
    if event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_LEAVING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UPDATE_BATTLEFIELD_STATUS" then
        local inPvP = isPvP()
        if not inPvP then
            self:ResetTransientTruth()
            self.matchComplete = false
            self.reassessRequested = false
            self.lastReassessment = nil
            self.lastMessage = ""
            self.finalSweepToken = (self.finalSweepToken or 0) + 1
            self:UpdateLifecycle()
            self:Refresh(event .. "-world")
        end
        self:Queue(event, 0.05)
        self:ScheduleTransitionSweep(event, false)
        return
    end
    if event == "GROUP_ROSTER_UPDATE" then
        self:Queue(event, 0.05)
        self:ScheduleTransitionSweep(event, true)
        return
    end
    if event == "UNIT_NAME_UPDATE" or event == "PLAYER_ROLES_ASSIGNED"
        or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:Queue(event, 0.05)
        return
    end
    -- Active events are registered once during addon initialization. Midnight
    -- can forbid changing protected event subscriptions during the PvP
    -- lifecycle, so inactive events are ignored instead of unregistered.
    if not self.active then return end
    if event == "PLAYER_REGEN_ENABLED" and KWR.MainWindow then
        KWR.MainWindow:FlushCombatVisibility()
    end
    if event:find("CHAT_MSG_BG_SYSTEM", 1, true) then
        self.lastMessage = KWR.Util:Text((...), "", 160)
        if KWR.ObjectiveIntel then
            local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
            local mapKey = state and state.snapshot and state.snapshot.context
                and state.snapshot.context.mapKey
            KWR.ObjectiveIntel:ObserveMessage(self.lastMessage, mapKey)
        end
    end
    if event == "UPDATE_UI_WIDGET" and KWR.Sensors then
        if KWR.Sensors:ObserveWidget((...)) ~= true then
            self.diagnostics.ignoredWidgetEvents =
                (self.diagnostics.ignoredWidgetEvents or 0) + 1
            return
        end
    end
    if (event == "UNIT_SPELLCAST_START"
        or event == "UNIT_SPELLCAST_CHANNEL_START") and KWR.CombatIntel then
        local unit, _, spellID = ...
        KWR.CombatIntel:ObserveUnitCast(unit, spellID, true, event)
    elseif (event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP") and KWR.CombatIntel then
        local unit, _, spellID = ...
        KWR.CombatIntel:ObserveUnitCast(unit, spellID, false, event)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and KWR.CombatIntel then
        local unit, _, spellID = ...
        KWR.CombatIntel:ObserveUnitSpell(unit, spellID)
    end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA") then
        local unit = ...
        if unit and type(UnitIsFriend) == "function"
            and KWR.Util:Boolean(KWR.Util:Call(UnitIsFriend, "player", unit), false)
            and not isFriendlyObjectiveCarrier(unit) then
            -- Friendly bars update directly in CombatRoster. A full strategy
            -- rebuild is only needed when the friendly unit carries an
            -- objective whose health or stacks can alter the call.
            if KWR.CombatRoster then
                KWR.CombatRoster:UpdateHealthForUnit(unit)
            end
            if KWR.MainWindow then
                KWR.MainWindow:UpdateHealthForUnit(unit)
            end
            self.diagnostics.lightweightEvents =
                (self.diagnostics.lightweightEvents or 0) + 1
            return
        end
    end
    if event == "NAME_PLATE_UNIT_ADDED" and KWR.EnemyIntel then
        local unit = ...
        KWR.EnemyIntel:ObserveToken(unit, "Nameplate")
        KWR.EnemyIntel:ObserveToken(unit and (unit .. "target"), "Nameplate Target")
    elseif event == "NAME_PLATE_UNIT_REMOVED" and KWR.EnemyIntel then
        local unit = ...
        KWR.EnemyIntel:ForgetToken(unit)
        KWR.EnemyIntel:ForgetToken(unit and (unit .. "target"))
    elseif event == "UNIT_TARGET" and KWR.EnemyIntel then
        local unit = ...
        if unit and (unit:find("^raid%d+$") or unit:find("^party%d+$")
            or unit:find("^raidpet%d+$") or unit:find("^partypet%d+$")) then
            KWR.EnemyIntel:ObserveToken(unit .. "target", "Team Engagement")
        end
    elseif event == "ARENA_OPPONENT_UPDATE" and KWR.EnemyIntel then
        local unit = ...
        KWR.EnemyIntel:ObserveToken(unit, "Objective Unit")
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
        or event == "UNIT_AURA") and KWR.EnemyIntel then
        local unit = ...
        if unit then
            KWR.EnemyIntel:ObserveToken(unit, "Unit Event")
            -- Health and aura traffic is exceptionally high in a real RBG.
            -- It can refine the local enemy record, but it cannot establish
            -- objective ownership, score truth, or a safe strategic pivot.
            -- Target/carrier observations remain available to CombatIntel on
            -- the regular pulse and combat/nameplate events instead of making
            -- each aura stack a complete strategy recomputation.
            self.diagnostics.lightweightEvents =
                (self.diagnostics.lightweightEvents or 0) + 1
            return
        end
    end
    if event == "PVP_MATCH_COMPLETE" then
        self.matchComplete = true
        if KWR.Sensors and KWR.Sensors.RequestScoreboard then
            KWR.Sensors:RequestScoreboard(true)
        elseif type(RequestBattlefieldScoreData) == "function" then
            KWR.Util:Call(RequestBattlefieldScoreData)
        end
        self:Refresh(event)
        self:ScheduleFinalSweep("PVP_MATCH_COMPLETE")
        return
    end
    local fast = event == "UPDATE_UI_WIDGET"
        or event == "UPDATE_BATTLEFIELD_SCORE"
        or event == "PVP_MATCH_ACTIVE"
    local settle = event == "UPDATE_BATTLEFIELD_SCORE" and 0.45
        or (event == "PVP_MATCH_ACTIVE" and 0.75)
        or nil
    self:Queue(event, fast and 0.05 or 0.12, settle)
end

function Runtime:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "RuntimeDiagnostics")
    end
    self.frame = CreateFrame("Frame", "KWR_MatchRuntimeFrame")
    for _, event in ipairs(PERSISTENT_EVENTS) do
        self.frame:RegisterEvent(event)
    end
    for _, event in ipairs(ACTIVE_EVENTS) do
        self.frame:RegisterEvent(event)
    end
    self.frame:SetScript("OnEvent", function(_, event, ...)
        Runtime:HandleEvent(event, ...)
    end)
end

function Runtime:OnEnable()
    self:UpdateLifecycle()
    self:Queue("login", 0.10, 1.0)
end

function Runtime:OnDisable()
    self:Stop()
end

KWR:RegisterModule("MatchRuntime", Runtime)
