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
    tacticalPending = false,
    tacticalTimerToken = 0,
    lastTacticalEscalationAt = 0,
    lastEnemyCaptureAt = 0,
    lastWidgetQueueAt = 0,
    lastPointsQueueAt = 0,
    lastBattlefieldStatusQueueAt = 0,
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
        tacticalRefreshes = 0,
        tacticalCoalesced = 0,
        tacticalPreemptions = 0,
        tacticalAbsorbed = 0,
        eventReasons = {},
        strategicQueueReasons = {},
        strategicRefreshReasons = {},
        tacticalQueueReasons = {},
        tacticalRefreshReasons = {},
    },
    durationSamples = {},
    tacticalDurationSamples = {},
    maxDurationSamples = 120,
    maxTacticalDurationSamples = 120,
}
KWR.MatchRuntime = Runtime

local MIN_REFRESH_INTERVAL = 0.75
local CRITICAL_REFRESH_INTERVAL = 0.15
local TACTICAL_REFRESH_INTERVAL = 0.50
local STRATEGIC_HEARTBEAT_INTERVAL = 15
local PUBLIC_FRESHNESS_INTERVAL = 4
local QUIET_TACTICAL_REFRESH_INTERVAL = 0.75
local EMERGENCY_TACTICAL_REFRESH_INTERVAL = 0.05
local MAX_CHAINED_FOLLOWUPS = 1
-- A tactical truth change is useful, but repeatedly rebuilding the entire
-- strategic pipeline during a large team fight is not.  Keep score/flag
-- events immediate; let tactical escalation settle long enough to publish
-- the newest local truth in one strategic pass.
local STRATEGIC_ESCALATION_DWELL = 1.50
local ENEMY_CAPTURE_INTERVAL = 1.00
local ROSTER_PRESENTATION_TIMEOUT = 8
-- UPDATE_BATTLEFIELD_STATUS is a high-frequency status pulse, not a world
-- transition. Preserve its newest truth with one trailing refresh instead of
-- repeatedly scheduling a transition-hydration sweep.
local BATTLEFIELD_STATUS_REFRESH_INTERVAL = 1.00

local CRITICAL_REFRESH_REASONS = {
    UPDATE_UI_WIDGET = true,
    BATTLEGROUND_POINTS_UPDATE = true,
    UPDATE_BATTLEFIELD_SCORE = true,
    PVP_MATCH_ACTIVE = true,
    PVP_MATCH_COMPLETE = true,
    CHAT_MSG_BG_SYSTEM_ALLIANCE = true,
    CHAT_MSG_BG_SYSTEM_HORDE = true,
    CHAT_MSG_BG_SYSTEM_NEUTRAL = true,
}

local PUBLIC_REFRESH_REASONS = {
    UPDATE_UI_WIDGET = "BOTH",
    BATTLEGROUND_POINTS_UPDATE = "SCORE",
    UPDATE_BATTLEFIELD_STATUS = "STATUS",
    ["public-freshness"] = "STATUS",
}

local TACTICAL_EVENTS = {
    NAME_PLATE_UNIT_ADDED = true,
    NAME_PLATE_UNIT_REMOVED = true,
    UPDATE_MOUSEOVER_UNIT = true,
    PLAYER_TARGET_CHANGED = true,
    PLAYER_FOCUS_CHANGED = true,
    PLAYER_SOFT_ENEMY_CHANGED = true,
    UNIT_TARGET = true,
    ARENA_OPPONENT_UPDATE = true,
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_STOP = true,
    UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
    UNIT_SPELLCAST_SUCCEEDED = true,
    PLAYER_REGEN_ENABLED = true,
    PLAYER_REGEN_DISABLED = true,
}

local EMERGENCY_TACTICAL_EVENTS = {
    PLAYER_TARGET_CHANGED = true,
    PLAYER_FOCUS_CHANGED = true,
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
}

local LOW_PRIORITY_TACTICAL_EVENTS = {
    UPDATE_MOUSEOVER_UNIT = true,
    NAME_PLATE_UNIT_ADDED = true,
    NAME_PLATE_UNIT_REMOVED = true,
}

local function firstLine(value)
    local text = tostring(value or "unknown runtime refresh error")
    return text:match("([^\r\n]+)") or text
end

local function incrementCounter(container, key)
    if type(container) ~= "table" then return end
    key = KWR.Util:Text(key, "unknown", 64)
    container[key] = (container[key] or 0) + 1
end

local function appendEventTrace(runtime, event)
    if event == "UNIT_AURA" or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        return
    end
    local trace = runtime.diagnostics.eventTrace or {}
    trace[#trace + 1] = {
        event = KWR.Util:Text(event, "unknown", 64),
        at = KWR.Util:Now(),
    }
    while #trace > 32 do table.remove(trace, 1) end
    runtime.diagnostics.eventTrace = trace
end

local function tacticalStrategicSignature(snapshot)
    local parts = {
        snapshot and snapshot.context and snapshot.context.sessionKey or "none",
    }
    local enemies = {}
    for _, enemy in ipairs(snapshot and snapshot.enemies or {}) do
        enemies[#enemies + 1] = table.concat({
            KWR.Util:Text(enemy.key or enemy.guid or enemy.name, "unknown", 96),
            enemy.dead == true and "dead" or "alive",
            enemy.carrier == true and "carrier" or "none",
        }, ":")
    end
    table.sort(enemies)
    for _, value in ipairs(enemies) do parts[#parts + 1] = value end
    -- Visibility, local range, engagement, location and casts are tactical
    -- presentation truth. They intentionally do not rebuild objectives,
    -- strategy and assignments: the tactical publication below updates the
    -- local-fight surface. Carrier and death state can materially change the
    -- battlefield plan, so they retain a bounded escalation path.
    return KWR.Util:Signature(parts)
end

local function tacticalInputSignature(snapshot, combatRevision)
    local parts = { combatRevision or 0 }
    for _, enemy in ipairs(snapshot and snapshot.enemies or {}) do
        parts[#parts + 1] = table.concat({
            KWR.Util:Text(enemy.key or enemy.guid or enemy.name, "?", 96),
            tostring(enemy.healthPercent or "?"),
            tostring(enemy.dead == true),
            tostring(enemy.visible == true),
            tostring(enemy.carrier == true),
            tostring(enemy.location or enemy.objective or "?"),
            tostring(enemy.engaged == true),
            tostring(enemy.unit or "?"),
        }, ":")
    end
    return KWR.Util:Signature(parts)
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
    return KWR.BuildInfo and KWR.BuildInfo:HasPreview()
end

local PREVIEW_RECOMPUTE_REASONS = {
    ["preview-toggle"] = true,
    ["preview-all"] = true,
    ["preview-roster"] = true,
    ["options-preview"] = true,
    ["manual"] = true,
    ["manual-reassess"] = true,
}

local function canReusePreview(runtime, reason)
    if PREVIEW_RECOMPUTE_REASONS[reason] then return false end
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    local context = state and state.snapshot and state.snapshot.context or nil
    return context and context.preview == true
end

local function allowsScoreboardReuse(reason)
    reason = tostring(reason or "")
    -- Objective/status pulses do not themselves invalidate scoreboard rows.
    -- UPDATE_BATTLEFIELD_SCORE and roster/spec changes mark the cache dirty;
    -- Sensors also imposes a 1.5-second age limit. Avoid rereading the full
    -- scoreboard on each unrelated pulse during a live team fight.
    return reason == "AREA_POIS_UPDATED"
        or reason == "UPDATE_BATTLEFIELD_STATUS"
        or reason == "BATTLEGROUND_POINTS_UPDATE"
        or reason == "UPDATE_UI_WIDGET"
        or reason == "coalesced-followup" or reason == "settle-refresh"
        or reason == "INSPECT_READY" or reason == "inspect-ready"
        or reason:find("%-settle$") ~= nil
end

local function tacticalCaptureRequired(reason)
    -- A cast needs an immediate tactical update, but it does not require a
    -- fresh full enemy-roster capture. Target/focus/nameplate transitions do;
    -- those are the events that can change the observed local target itself.
    return reason == "PLAYER_TARGET_CHANGED"
        or reason == "PLAYER_FOCUS_CHANGED"
        or reason == "ARENA_OPPONENT_UPDATE"
        or reason == "NAME_PLATE_UNIT_ADDED"
        or reason == "NAME_PLATE_UNIT_REMOVED"
end

local function clearQueueState(runtime)
    runtime.pending = false
    runtime.pendingDueAt = nil
    runtime.pendingReason = nil
    runtime.pendingRevision = nil
    runtime.pendingSettle = nil
end

local function clearTacticalQueueState(runtime)
    runtime.tacticalPending = false
    runtime.tacticalPendingReason = nil
    runtime.tacticalPendingDueAt = nil
end

local function recordStage(runtime, name, started)
    if not started or started <= 0 or type(debugprofilestop) ~= "function" then return end
    runtime.diagnostics.stageMs = runtime.diagnostics.stageMs or {}
    runtime.diagnostics.stageMs[name] = math.max(0, debugprofilestop() - started)
end

local function tacticalSnapshot(currentSnapshot)
    local snapshot = {}
    for key, value in pairs(currentSnapshot or {}) do
        snapshot[key] = value
    end
    return snapshot
end

local function copyTacticalEnemies(enemies)
    local result = {}
    for index, enemy in ipairs(enemies or {}) do
        local copy = {}
        for key, value in pairs(enemy) do copy[key] = value end
        if type(enemy.combat) == "table" then
            copy.combat = {}
            for key, value in pairs(enemy.combat) do copy.combat[key] = value end
        end
        result[index] = copy
    end
    return result
end

local function timingMetrics(samples)
    local ordered, total = {}, 0
    for index, sample in ipairs(samples or {}) do
        ordered[index] = sample
        total = total + sample
    end
    table.sort(ordered)
    local count = #ordered
    local function percentile(fraction)
        return count > 0 and ordered[math.max(1, math.ceil(count * fraction))] or 0
    end
    return {
        average = count > 0 and total / count or 0,
        p50 = percentile(0.50),
        p95 = percentile(0.95),
        p99 = percentile(0.99),
        max = count > 0 and ordered[count] or 0,
    }
end

local function recordTacticalDuration(runtime, duration)
    local diagnostics = runtime.diagnostics
    diagnostics.lastTacticalDurationMs = duration
    diagnostics.maxTacticalDurationMs = math.max(
        diagnostics.maxTacticalDurationMs or 0, duration)
    runtime.tacticalDurationSamples[#runtime.tacticalDurationSamples + 1] = duration
    while #runtime.tacticalDurationSamples
        > (runtime.maxTacticalDurationSamples or 120) do
        table.remove(runtime.tacticalDurationSamples, 1)
    end
    diagnostics.tacticalDurationSampleCount = #runtime.tacticalDurationSamples
    if diagnostics.tacticalRefreshes % 10 == 0 then
        local metrics = timingMetrics(runtime.tacticalDurationSamples)
        diagnostics.averageTacticalDurationMs = metrics.average
        diagnostics.p50TacticalDurationMs = metrics.p50
        diagnostics.p95TacticalDurationMs = metrics.p95
        diagnostics.p99TacticalDurationMs = metrics.p99
        diagnostics.maxTacticalDurationMs = metrics.max
    end
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
    if KWR.CountdownState then KWR.CountdownState:Cancel("RUNTIME_RESET") end
    self.lastFriendlyHealthSyncAt = nil
    self.postMatchTruth = nil
    self.rosterPresentation = nil
    self.lastTacticalInputs = nil
    self.lastTacticalComputedAt = nil
    self.lastEnemyTokenRevision = nil
    self.latestQueuedReason = nil
    if KWR.Sensors then
        KWR.Sensors.scoreSession = nil
        KWR.Sensors.widgetFingerprints = {}
        KWR.Sensors.widgetLastObservedAt = {}
        KWR.Sensors:InvalidateScoreboard()
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

local function preservePublicRows(objectives)
    for _, row in ipairs(objectives and objectives.rows or {}) do
        if not row.publicFields then
            row.publicFields = {
                label = row.label, owner = row.owner, state = row.state,
                kind = row.kind, source = row.source, x = row.x, y = row.y,
                carrier = row.carrier,
            }
        end
    end
end

local function rosterInputSignature(snapshot)
    local parts = {}
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        parts[#parts + 1] = table.concat({
            tostring(player.guid or player.name or "?"),
            tostring(player.spec or player.specID or "?"),
            tostring(player.classFile or "?"),
            tostring(player.role or player.groupRole or "?"),
            tostring(player.dead == true),
            tostring(player.carrier == true),
        }, ":")
    end
    return KWR.Util:Signature(parts)
end

local function objectiveInputSignature(snapshot)
    local objectives = snapshot and snapshot.objectives or {}
    local parts = {
        objectives.source or "?", objectives.widgetID or "?",
        objectives.friendly or 0, objectives.enemy or 0,
        objectives.friendlyIncoming or 0, objectives.enemyIncoming or 0,
    }
    for _, row in ipairs(objectives.rows or {}) do
        local public = row.publicFields or row
        parts[#parts + 1] = table.concat({
            tostring(public.label or "?"), tostring(public.state or "?"),
            tostring(public.owner or "?"), tostring(public.source or "?"),
            tostring(public.x or "?"), tostring(public.y or "?"),
            tostring(row.iconState or "?"),
        }, ":")
    end
    return KWR.Util:Signature(parts)
end

local function strategicInputSignature(snapshot)
    local context = snapshot and snapshot.context or {}
    local score = snapshot and snapshot.score or {}
    local parts = {
        context.sessionKey or "?", context.phase or "?",
        context.team and context.team.side or "?",
        context.isBlitz == true and "BLITZ" or "STANDARD",
        context.matchComplete == true and "COMPLETE" or "ACTIVE",
        tostring(score.friendly or "?"), tostring(score.enemy or "?"),
        tostring(score.max or "?"), tostring(score.source or "?"),
        rosterInputSignature(snapshot), objectiveInputSignature(snapshot),
        tacticalStrategicSignature(snapshot),
        snapshot and snapshot.lastMessage or "",
    }
    return table.concat(parts, "\031")
end

local function assignmentPlanSignature(snapshot)
    local strategy = snapshot and snapshot.strategy or {}
    local decision = strategy.objectiveDecision or {}
    local enemyShape = strategy.enemyComposition or {}
    return KWR.Util:Signature({
        snapshot and snapshot.context and snapshot.context.mapKey or "?",
        strategy.state or "?", strategy.target or "?",
        decision.target or "?", enemyShape.id or "BALANCED",
    })
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
    if snapshot.context.isBrawl == true then
        cached.isBrawl = true
        cached.brawlSource = KWR.Util:Text(
            snapshot.context.brawlSource, "confirmed", 32)
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
    if cached.isBrawl then
        snapshot.context.isBrawl = true
        snapshot.context.brawlSource = cached.brawlSource or "confirmed"
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

function Runtime:RefreshTactical(reason)
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    local currentSnapshot = state and state.snapshot or nil
    if not currentSnapshot or not currentSnapshot.context
        or currentSnapshot.context.inPvP ~= true
        or currentSnapshot.context.preview == true
        or currentSnapshot.context.matchComplete == true then
        return true
    end

    local started = type(debugprofilestop) == "function" and debugprofilestop() or 0
    local ok, message = xpcall(function()
        -- Tactical work only replaces enemy/combat presentation fields. A
        -- top-level copy keeps the published strategic snapshot immutable
        -- while avoiding a full deep copy for every target/cast event.
        local snapshot = tacticalSnapshot(currentSnapshot)
        local stageStarted = started
        local now = KWR.Util:Now()
        local tokenRevision = KWR.EnemyIntel
            and KWR.EnemyIntel.tokenRevision or 0
        local repeatedNameplate = (reason == "NAME_PLATE_UNIT_ADDED"
            or reason == "NAME_PLATE_UNIT_REMOVED")
            and tokenRevision == self.lastEnemyTokenRevision
        local reuseEnemyTruth = (not tacticalCaptureRequired(reason)
            or repeatedNameplate)
            and (now - (self.lastEnemyCaptureAt or 0)) < ENEMY_CAPTURE_INTERVAL
            and type(currentSnapshot.enemies) == "table"
        if reuseEnemyTruth then
            snapshot.enemies = copyTacticalEnemies(currentSnapshot.enemies)
            self.diagnostics.tacticalEnemyReuse =
                (self.diagnostics.tacticalEnemyReuse or 0) + 1
        elseif KWR.EnemyIntel and KWR.EnemyIntel.Capture then
            local observed = KWR.EnemyIntel:Capture(
                snapshot.context,
                snapshot.roster,
                snapshot.context.team,
                nil)
            local scoreFaction = snapshot.context.team
                and snapshot.context.team.scoreFaction or nil
            snapshot.enemies = KWR.EnemyIntel:FilterPublishedTruth(
                snapshot.roster, observed, scoreFaction)
            self.lastEnemyCaptureAt = now
            self.lastEnemyTokenRevision = KWR.EnemyIntel.tokenRevision
        else
            snapshot.enemies = copyTacticalEnemies(currentSnapshot.enemies)
        end
        recordStage(self, "TacticalEnemy", stageStarted)
        local inputSignature = tacticalInputSignature(snapshot,
            KWR.CombatIntel and KWR.CombatIntel.observed)
        if inputSignature == self.lastTacticalInputs
            and now - (self.lastTacticalComputedAt or 0) < 0.75 then
            self.diagnostics.tacticalStageReuses =
                (self.diagnostics.tacticalStageReuses or 0) + 1
            self.diagnostics.tacticalRefreshes =
                (self.diagnostics.tacticalRefreshes or 0) + 1
            self.diagnostics.lastTacticalReason = reason or "tactical"
            incrementCounter(self.diagnostics.tacticalRefreshReasons,
                reason or "tactical")
            self.lastTacticalRefreshAt = now
            if started > 0 and type(debugprofilestop) == "function" then
                recordTacticalDuration(self,
                    math.max(0, debugprofilestop() - started))
            end
            return
        end
        stageStarted = type(debugprofilestop) == "function" and debugprofilestop() or 0
        if KWR.CombatIntel and KWR.CombatIntel.Analyze then
            snapshot.combat = KWR.CombatIntel:Analyze(snapshot)
        end
        if KWR.TeamfightCommandPlanner and KWR.TeamfightCommandPlanner.Plan then
            snapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(snapshot)
        end
        if KWR.ExecutionCommandBuilder and KWR.ExecutionCommandBuilder.Build then
            snapshot.executionCommand = KWR.ExecutionCommandBuilder:Build(
                snapshot, state.prediction, state.assignments, state.command)
        end
        if KWR.CommandEmphasis and KWR.CommandEmphasis.Build then
            snapshot.commandEmphasis = KWR.CommandEmphasis:Build(
                snapshot, state.prediction, state.assignments, state.command)
        end
        recordStage(self, "TacticalCombat", stageStarted)
        self.lastTacticalInputs = inputSignature
        self.lastTacticalComputedAt = now

        local strategicSignature = tacticalStrategicSignature(snapshot)
        local strategicTruthChanged = self.lastTacticalStrategicSignature ~= nil
            and self.lastTacticalStrategicSignature ~= strategicSignature
        self.lastTacticalStrategicSignature = strategicSignature
        self.diagnostics.tacticalRefreshes =
            (self.diagnostics.tacticalRefreshes or 0) + 1
        self.diagnostics.lastTacticalReason = reason or "tactical"
        incrementCounter(self.diagnostics.tacticalRefreshReasons,
            reason or "tactical")
        self.lastTacticalRefreshAt = KWR.Util:Now()
        KWR.Store:PublishPatch(
            snapshot,
            { "enemies", "combat", "teamfight", "executionCommand",
                "commandEmphasis" },
            state.prediction,
            state.assignments,
            state.command,
            self.diagnostics, function()
                if started > 0 and type(debugprofilestop) == "function" then
                    recordTacticalDuration(self, math.max(0, debugprofilestop() - started))
                end
                return self.diagnostics
            end)
        if strategicTruthChanged
            and ((self.diagnostics.events or 0) < 500
                or KWR.Util:Now() - (self.lastTacticalEscalationAt or 0)
                    >= STRATEGIC_ESCALATION_DWELL) then
            self.diagnostics.tacticalEscalations =
                (self.diagnostics.tacticalEscalations or 0) + 1
            self.lastTacticalEscalationAt = KWR.Util:Now()
            self:Queue("tactical-truth-change", 0.40)
        end
    end, runtimeErrorHandler)
    if not ok then
        self.diagnostics.errors = (self.diagnostics.errors or 0) + 1
        self.diagnostics.lastError = tostring(message or "unknown tactical refresh error")
        self.diagnostics.lastErrorAt = KWR.Util:Now()
        self.diagnostics.lastErrorReason = reason or "tactical"
        KWR:Print("Tactical refresh failed: " .. firstLine(message), true)
    end
    return ok
end

function Runtime:AdaptiveTacticalDelay(reason)
    if EMERGENCY_TACTICAL_EVENTS[reason] then
        return EMERGENCY_TACTICAL_REFRESH_INTERVAL
    end
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    local snapshot = state and state.snapshot or {}
    local combat = snapshot.combat or {}
    local activeFight = combat.priorityCast or combat.localTarget
    local objectives = snapshot.objectives or {}
    local contested = false
    for _, objective in pairs(objectives.rows or {}) do
        if type(objective) == "table" and objective.pendingState == "INCOMING" then
            contested = true
            break
        end
    end
    local p95 = KWR.Util:Number(self.diagnostics.p95TacticalDurationMs, 0) or 0
    local tacticalInterval = p95 >= 12 and 1.25
        or (p95 >= 6 and 0.85) or TACTICAL_REFRESH_INTERVAL
    if activeFight or contested then return tacticalInterval end
    if LOW_PRIORITY_TACTICAL_EVENTS[reason] then
        return math.max(QUIET_TACTICAL_REFRESH_INTERVAL, tacticalInterval)
    end
    return TACTICAL_REFRESH_INTERVAL
end

function Runtime:ScheduleTactical(reason, delay)
    self.tacticalPending = true
    self.tacticalPendingReason = reason or "tactical"
    delay = math.max(delay or 0.05, self:AdaptiveTacticalDelay(reason))
    self.tacticalPendingDueAt = KWR.Util:Now() + delay
    self.tacticalTimerToken = (self.tacticalTimerToken or 0) + 1
    local token = self.tacticalTimerToken
    local function run()
        if token ~= Runtime.tacticalTimerToken then return end
        local completedReason = Runtime.tacticalPendingReason or reason or "tactical"
        clearTacticalQueueState(Runtime)
        if Runtime.pending
            and not PUBLIC_REFRESH_REASONS[Runtime.pendingReason] then
            Runtime.diagnostics.tacticalAbsorbed =
                (Runtime.diagnostics.tacticalAbsorbed or 0) + 1
            return
        end
        Runtime:RefreshTactical(completedReason)
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, run)
    else
        run()
    end
end

function Runtime:QueueTactical(reason, delay)
    incrementCounter(self.diagnostics.tacticalQueueReasons,
        reason or "tactical")
    if self.pending then
        self.diagnostics.tacticalAbsorbed =
            (self.diagnostics.tacticalAbsorbed or 0) + 1
        return
    end
    if self.tacticalPending then
        self.diagnostics.tacticalCoalesced =
            (self.diagnostics.tacticalCoalesced or 0) + 1
        local requestedDelay = math.max(delay or 0.05,
            self:AdaptiveTacticalDelay(reason))
        local requestedDueAt = KWR.Util:Now() + requestedDelay
        if self.tacticalPendingDueAt
            and requestedDueAt + 0.001 < self.tacticalPendingDueAt then
            self.diagnostics.tacticalPreemptions =
                (self.diagnostics.tacticalPreemptions or 0) + 1
            self.tacticalTimerToken = (self.tacticalTimerToken or 0) + 1
            clearTacticalQueueState(self)
            self:ScheduleTactical(reason, requestedDelay)
        end
        return
    end
    self:ScheduleTactical(reason, delay)
end

function Runtime:Start()
    if self.active then return end
    self.matchComplete = false
    self.active = true
    if C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(1, function()
            if not Runtime.active then return end
            local now = KWR.Util:Now()
            if KWR.CountdownState and KWR.CountdownState.active
                and not Runtime.pending and not Runtime.tacticalPending then
                Runtime:RefreshTactical("countdown-tick")
            end
            if now - (Runtime.lastStrategicRefreshAt or 0)
                >= STRATEGIC_HEARTBEAT_INTERVAL and not Runtime.pending then
                Runtime:Queue("truth-heartbeat", 0.02)
            elseif not Runtime.pending and not Runtime.matchComplete then
                local state = KWR.Store and KWR.Store:Get()
                local snapshot = state and state.snapshot or {}
                if snapshot.context and snapshot.context.matchComplete then return end
                local score = snapshot.score or {}
                local objectives = snapshot.objectives or {}
                local scoreDue = score.source == "ui_widget"
                    and now - (score.observedAt or 0) >= PUBLIC_FRESHNESS_INTERVAL
                local objectiveDue = objectives.source == "ui_widget"
                    and now - (objectives.observedAt or 0) >= PUBLIC_FRESHNESS_INTERVAL
                if scoreDue or objectiveDue then
                    Runtime:Queue("public-freshness", 0.02)
                end
            end
        end)
    end
end

function Runtime:Stop()
    if KWR.CountdownState then KWR.CountdownState:Cancel("RUNTIME_STOP") end
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.tacticalTimerToken = (self.tacticalTimerToken or 0) + 1
    clearTacticalQueueState(self)
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

local function publishStrategic(runtime, reason, started, profileStages,
    snapshot, prediction, assignments, command, fields)
    runtime.diagnostics.refreshes = runtime.diagnostics.refreshes + 1
    runtime.diagnostics.strategicRefreshes =
        (runtime.diagnostics.strategicRefreshes or 0) + 1
    runtime.diagnostics.lastReason = reason or "refresh"
    incrementCounter(runtime.diagnostics.strategicRefreshReasons,
        reason or "refresh")
    local publicationStarted = profileStages and debugprofilestop() or 0
    local function finalizeDiagnostics()
        recordStage(runtime, "Publish", publicationStarted)
        if started > 0 and type(debugprofilestop) == "function" then
            local duration = math.max(0, debugprofilestop() - started)
            runtime.diagnostics.lastDurationMs = duration
            runtime.diagnostics.maxDurationMs = math.max(
                runtime.diagnostics.maxDurationMs or 0, duration)
            runtime.durationSamples[#runtime.durationSamples + 1] = duration
            if reason == "PLAYER_ENTERING_WORLD" or reason == "ZONE_CHANGED_NEW_AREA"
                or reason == "login" then
                runtime.diagnostics.transitionRefreshes =
                    (runtime.diagnostics.transitionRefreshes or 0) + 1
                runtime.diagnostics.lastTransitionDurationMs = duration
            end
            while #runtime.durationSamples > (runtime.maxDurationSamples or 120) do
                table.remove(runtime.durationSamples, 1)
            end
            runtime.diagnostics.durationSampleCount = #runtime.durationSamples
            if runtime.diagnostics.refreshes % 10 == 0 then
                local metrics = timingMetrics(runtime.durationSamples)
                runtime.diagnostics.averageDurationMs = metrics.average
                runtime.diagnostics.p50DurationMs = metrics.p50
                runtime.diagnostics.p95DurationMs = metrics.p95
                runtime.diagnostics.p99DurationMs = metrics.p99
                runtime.diagnostics.maxDurationMs = metrics.max
                local memoryMB = KWR.MemoryBudget and KWR.MemoryBudget.Sample
                    and KWR.MemoryBudget:Sample(nil, false) or nil
                runtime.diagnostics.memoryKB = KWR.Util:Number(memoryMB, nil)
                    and (memoryMB * 1024) or 0
                runtime.diagnostics.memorySampleAt = KWR.MemoryBudget
                    and KWR.MemoryBudget.lastMeasuredAt
            end
        end
        return runtime.diagnostics
    end
    runtime.lastRefreshAt = KWR.Util:Now()
    if fields == nil then
        -- Cheap public publications cannot defer the authoritative roster,
        -- enemy, and phase sweep indefinitely during a status-event storm.
        runtime.lastStrategicRefreshAt = runtime.lastRefreshAt
    end
    if not KWR.Store then
        finalizeDiagnostics()
        return
    end
    local published, changed
    if fields then
        published, changed = KWR.Store:PublishPatch(
            snapshot, fields, prediction, assignments, command,
            runtime.diagnostics, finalizeDiagnostics)
    else
        published = KWR.Store:Publish(
            snapshot, prediction, assignments, command,
            runtime.diagnostics, finalizeDiagnostics)
        changed = true
    end
    if changed then
        runtime.lastTacticalStrategicSignature = tacticalStrategicSignature(
            published.snapshot)
        if KWR.CommandAudio then KWR.CommandAudio:Observe(published) end
        if KWR.CommanderComm then KWR.CommanderComm:Relay(published) end
    end
end

function Runtime:RefreshPublic(reason, previous, started, profileStages)
    local previousSnapshot = previous and previous.snapshot
    if not previousSnapshot or not previousSnapshot.context
        or previousSnapshot.context.inPvP ~= true
        or previousSnapshot.context.preview == true
        or previousSnapshot.context.matchComplete == true
        or self.matchComplete == true
        or not KWR.Sensors.CapturePublic then
        return false
    end
    local kind = PUBLIC_REFRESH_REASONS[reason]
    if not kind then return false end
    local stageStarted = profileStages and started or 0
    local snapshot, changedKind = KWR.Sensors:CapturePublic(
        previousSnapshot, kind, self.lastMessage)
    if not snapshot then return false end
    recordStage(self, "Sensors", stageStarted)
    self.diagnostics.publicCaptures = (self.diagnostics.publicCaptures or 0) + 1
    if changedKind == "UNCHANGED" then
        self.diagnostics.unchangedPublicSkips =
            (self.diagnostics.unchangedPublicSkips or 0) + 1
        local now = KWR.Util:Now()
        local fields = {}
        if snapshot.score ~= previousSnapshot.score
            and snapshot.score.observedAt
            and snapshot.score.observedAt > (previousSnapshot.score.observedAt or 0)
            and now - (previousSnapshot.score.observedAt or 0)
                >= PUBLIC_FRESHNESS_INTERVAL - 1 then
            fields[#fields + 1] = "score"
        end
        if snapshot.objectives ~= previousSnapshot.objectives
            and snapshot.objectives.observedAt
            and snapshot.objectives.observedAt > (previousSnapshot.objectives.observedAt or 0)
            and now - (previousSnapshot.objectives.observedAt or 0)
                >= PUBLIC_FRESHNESS_INTERVAL - 1 then
            fields[#fields + 1] = "objectives"
        end
        local truthChanged = false
        if #fields > 0 then
            snapshot.truth = KWR.Verification:Contract(snapshot)
            fields[#fields + 1] = "truth"
            self.diagnostics.publicFreshnessPatches =
                (self.diagnostics.publicFreshnessPatches or 0) + 1
            local priorTruth = previousSnapshot.truth or {}
            truthChanged = snapshot.truth.coreFresh ~= priorTruth.coreFresh
                or snapshot.truth.aggressiveCommitAllowed
                    ~= priorTruth.aggressiveCommitAllowed
                or snapshot.truth.mode ~= priorTruth.mode
        end
        if not truthChanged then
            publishStrategic(self, reason, started, profileStages, snapshot,
                previous.prediction, previous.assignments, previous.command, fields)
            return true
        end
        self.diagnostics.freshnessPlanRecomputes =
            (self.diagnostics.freshnessPlanRecomputes or 0) + 1
        changedKind = "SCORE"
    end
    local objectiveChanged = changedKind == "OBJECTIVE"
    stageStarted = profileStages and debugprofilestop() or 0
    if objectiveChanged then
        -- ObjectiveIntel and CombatIntel decorate carrier and enemy rows.
        -- Never let them mutate the previously published Store branches.
        snapshot.roster = KWR.Util:Copy(previousSnapshot.roster)
        snapshot.enemies = copyTacticalEnemies(previousSnapshot.enemies)
        snapshot = KWR.ObjectiveIntel:Apply(snapshot)
        snapshot.combat = KWR.CombatIntel:Analyze(snapshot)
        snapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(snapshot)
        snapshot.reporter = KWR.Reporter:Observe(snapshot)
        self.diagnostics.objectiveStageRecomputes =
            (self.diagnostics.objectiveStageRecomputes or 0) + 1
    else
        self.diagnostics.battlefieldStageReuses =
            (self.diagnostics.battlefieldStageReuses or 0) + 1
    end
    snapshot.truth = KWR.Verification:Contract(snapshot)
    recordStage(self, "Battlefield", stageStarted)
    stageStarted = profileStages and debugprofilestop() or 0
    local prediction = KWR.Predictor:Evaluate(snapshot)
    snapshot.strategy = KWR.Strategist:Evaluate(snapshot, prediction)
    snapshot.carrierTargetEvidence =
        KWR.ObjectiveIntel:NormalizeStrategyTarget(snapshot)
    recordStage(self, "Strategy", stageStarted)
    stageStarted = profileStages and debugprofilestop() or 0
    local reuseAssignments = not objectiveChanged
        and previous.assignments ~= nil
        and assignmentPlanSignature(snapshot)
            == assignmentPlanSignature(previousSnapshot)
    local assignments
    if reuseAssignments then
        assignments = previous.assignments
        snapshot.assignmentIntegrity = previousSnapshot.assignmentIntegrity
        self.diagnostics.assignmentStageReuses =
            (self.diagnostics.assignmentStageReuses or 0) + 1
    else
        assignments = KWR.Assignments:Build(snapshot, prediction)
        snapshot.assignmentIntegrity = KWR.Assignments:Integrity(snapshot, assignments)
    end
    snapshot.strategy.executionAssessment =
        KWR.Strategist:AssessExecution(snapshot, prediction, assignments)
    snapshot.responsePackage = KWR.Assignments:ResponsePackage(snapshot, assignments)
    recordStage(self, "Assignments", stageStarted)
    stageStarted = profileStages and debugprofilestop() or 0
    local command = KWR.Commander:Compose(snapshot, prediction, assignments)
    command = KWR.Commander:ObservePublicExecution(snapshot, command)
    if command.activePlayDecision and command.activePlayDecision.retained then
        assignments = previous.assignments or assignments
        snapshot.responsePackage = previousSnapshot.responsePackage
            or snapshot.responsePackage
        snapshot.assignmentIntegrity = KWR.Assignments:Integrity(snapshot, assignments)
    end
    snapshot.executionCommand = KWR.ExecutionCommandBuilder:Build(
        snapshot, prediction, assignments, command)
    snapshot.commandEmphasis = KWR.CommandEmphasis:Build(
        snapshot, prediction, assignments, command)
    recordStage(self, "Command", stageStarted)
    local fields = { "score", "truth", "strategy", "carrierTargetEvidence",
        "assignmentIntegrity", "responsePackage", "executionCommand",
        "commandEmphasis", "capturedAt", "lastMessage" }
    if snapshot.objectives ~= previousSnapshot.objectives then
        fields[#fields + 1] = "objectives"
    end
    if objectiveChanged then
        fields[#fields + 1] = "roster"
        fields[#fields + 1] = "enemies"
        fields[#fields + 1] = "combat"
        fields[#fields + 1] = "teamfight"
        fields[#fields + 1] = "reporter"
    end
    publishStrategic(self, reason, started, profileStages, snapshot,
        prediction, assignments, command, fields)
    return true
end

function Runtime:Refresh(reason)
    local usingPreview = KWR.db.profile.preview and not isPvP()
        and previewAvailable()
    if usingPreview and canReusePreview(self, reason) then
        -- The preview fixture is static. Re-running its full Reporter ->
        -- Strategist -> Assignments path for unrelated world events only
        -- obscures real field-performance telemetry and makes the design
        -- surface feel sluggish. Explicit preview actions still recompute.
        self.diagnostics.previewRefreshSkips =
            (self.diagnostics.previewRefreshSkips or 0) + 1
        self.lastRefreshAt = KWR.Util:Now()
        return true
    end
    local started = type(debugprofilestop) == "function" and debugprofilestop() or 0
    local ok, message = xpcall(function()
        local profileStages = rawget(_G, "KWR_TEST_ENV") ~= true
        local previous = KWR.Store and KWR.Store:Get() or nil
        if not usingPreview and self:RefreshPublic(reason, previous,
            started, profileStages) then
            return
        end
        local snapshot
        -- The test driver models debugprofilestop as a single start/stop pair
        -- per refresh.  Retail gets the finer live-stage signal; deterministic
        -- offline timing remains a faithful end-to-end measurement.
        local stageStarted = profileStages and started or 0
        if usingPreview then
            snapshot = KWR.Preview:Build()
        else
            if KWR.db.profile.preview and not previewAvailable() then
                KWR.db.profile.preview = false
            end
            snapshot = KWR.Sensors:Capture(self.lastMessage,
                allowsScoreboardReuse(reason))
        end
        preservePublicRows(snapshot.objectives)
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
        local unchangedInspection = reason == "inspect-ready"
            or reason == "INSPECT_READY"
            or reason == "UPDATE_BATTLEFIELD_SCORE"
            or reason == "GROUP_ROSTER_UPDATE"
            or reason == "UNIT_NAME_UPDATE"
            or reason == "PLAYER_ROLES_ASSIGNED"
            or reason == "PLAYER_SPECIALIZATION_CHANGED"
        if unchangedInspection and previous and previous.snapshot
            and not self.reassessRequested
            and strategicInputSignature(snapshot)
                == strategicInputSignature(previous.snapshot) then
            self.diagnostics.unchangedInspectionSkips =
                (self.diagnostics.unchangedInspectionSkips or 0) + 1
            publishStrategic(self, reason, started, profileStages,
                previous.snapshot, previous.prediction, previous.assignments,
                previous.command, {})
            return
        end
        stageStarted = profileStages and debugprofilestop() or 0
        local prediction
        local assignments
        local command
        if snapshot.context.inPvP ~= true and snapshot.context.preview ~= true then
            -- Outside PvP only the formation surface is actionable. Do not
            -- rebuild combat, reporter, opponent, verification, strategy, or
            -- response systems from non-battleground data.
            self.reassessRequested = false
            self.lastReassessment = nil
            if KWR.Commander and KWR.Commander.ClearActivePlay then
                KWR.Commander:ClearActivePlay()
            end
            snapshot.formation = KWR.FormationAdvisor:Evaluate(snapshot)
            snapshot.combat = {}
            snapshot.teamfight = { displayEligible = false }
            snapshot.reporter = {
                active = false,
                status = "INACTIVE",
                friendly = {},
                enemy = {},
                pressure = {},
                events = {},
                risk = 0,
                summary = "Reporter standing by. Enter a battleground to build movement knowledge.",
                coverage = { friendly = 0, enemy = 0 },
            }
            snapshot.truth = {
                coreFresh = false,
                aggressiveCommitAllowed = false,
                mode = "VERIFY_FIRST",
            }
            prediction = KWR.Predictor:Evaluate(snapshot)
            snapshot.strategy = {
                state = "WORLD",
                action = prediction.action,
                confidence = "NONE",
                reason = "Strategy engine is standing by outside a battleground.",
                objectiveDecision = {},
                executionAssessment = {},
            }
            assignments = KWR.Assignments:Build(snapshot)
            snapshot.assignmentIntegrity = {
                onStation = #assignments,
                moving = 0,
                unverified = 0,
                abandoned = 0,
                impossible = 0,
                coverageLedger = {},
                reassignments = {},
            }
            snapshot.responsePackage = {
                active = false,
                qualified = false,
                actionID = "HOLD_PLAN",
                action = "HOLD CURRENT PLAN",
                target = "VERIFY",
                shortTarget = "VERIFY",
                movers = {},
                stayers = {},
                moverText = "Team",
                stayerText = "Assigned defenders",
                confidence = "NONE",
                score = 0,
                recovery = {},
            }
            command = KWR.Commander:Compose(snapshot, prediction, assignments)
        else
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
            prediction = KWR.Predictor:Evaluate(snapshot)
            snapshot.strategy = KWR.Strategist:Evaluate(snapshot, prediction)
            snapshot.carrierTargetEvidence =
                KWR.ObjectiveIntel:NormalizeStrategyTarget(snapshot)
            recordStage(self, "Strategy", stageStarted)
            stageStarted = profileStages and debugprofilestop() or 0
            assignments = KWR.Assignments:Build(snapshot, prediction)
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
            command = KWR.Commander:Compose(snapshot, prediction, assignments)
            command = KWR.Commander:ObservePublicExecution(snapshot, command)
            if command.activePlayDecision and command.activePlayDecision.retained then
                local previous = KWR.Store:Get()
                -- Retention is a plan transaction, not just an old headline.
                -- Do not publish unissued candidate jobs under a retained call.
                assignments = previous.assignments or assignments
                snapshot.responsePackage = previous.snapshot and previous.snapshot.responsePackage
                    or snapshot.responsePackage
                snapshot.assignmentIntegrity = KWR.Assignments:Integrity(snapshot, assignments)
            end
            snapshot.executionCommand = KWR.ExecutionCommandBuilder:Build(
                snapshot, prediction, assignments, command)
            snapshot.commandEmphasis = KWR.CommandEmphasis:Build(
                snapshot, prediction, assignments, command)
        end
        recordStage(self, "Command", stageStarted)
        publishStrategic(self, reason, started, profileStages, snapshot,
            prediction, assignments, command)
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

function Runtime:EffectiveDelay(delay, reason)
    local elapsed = KWR.Util:Now() - (self.lastRefreshAt or 0)
    local interval = CRITICAL_REFRESH_REASONS[reason] == true
        and CRITICAL_REFRESH_INTERVAL or MIN_REFRESH_INTERVAL
    -- Adaptive backpressure applies only to non-critical refreshes.  The
    -- current score, objective messages, and match-end truth remain prompt.
    if CRITICAL_REFRESH_REASONS[reason] ~= true then
        local p95 = KWR.Util:Number(self.diagnostics.p95DurationMs, 0) or 0
        if p95 >= 16 then
            interval = math.max(interval, 2.00)
        elseif p95 >= 8 then
            interval = math.max(interval, 1.25)
        end
    end
    return math.max(delay or 0.10, math.max(0, interval - elapsed))
end

function Runtime:Schedule(reason, delay, revision)
    self.pending = true
    self.pendingReason = reason or "queued"
    self.pendingRevision = revision or self.queueRevision or 0
    self.pendingSettle = self.pendingReason == "settle-refresh"
    delay = self:EffectiveDelay(delay, reason)
    self.pendingDueAt = KWR.Util:Now() + delay
    self.timerToken = (self.timerToken or 0) + 1
    local token = self.timerToken
    local function run()
        if token ~= Runtime.timerToken then return end
        local dueAt = Runtime.pendingDueAt or KWR.Util:Now()
        local completedReason = Runtime.pendingReason or reason or "queued"
        -- Capture reads the current APIs, so all events received BEFORE it
        -- starts are consumed by this pass, not by a redundant second pass.
        local completedRevision = Runtime.queueRevision or revision or 0
        local completedSettle = Runtime.pendingSettle == true
        Runtime.latestQueuedReason = nil
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
        if timerMatured and hasNewRevision and canChainFollowup and not Runtime.pending then
            Runtime.diagnostics.queueFollowups =
                (Runtime.diagnostics.queueFollowups or 0) + 1
            Runtime.followupChainCount = (Runtime.followupChainCount or 0) + 1
            Runtime:Schedule(Runtime.latestQueuedReason or "coalesced-followup", 0.02,
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
    incrementCounter(self.diagnostics.strategicQueueReasons,
        reason or "queued")
    local publicReason = PUBLIC_REFRESH_REASONS[reason] ~= nil
    if not self.latestQueuedReason then
        self.latestQueuedReason = reason
    elseif PUBLIC_REFRESH_REASONS[self.latestQueuedReason] then
        self.latestQueuedReason = publicReason and "UPDATE_UI_WIDGET" or reason
    end
    if self.tacticalPending and not publicReason then
        self.tacticalTimerToken = (self.tacticalTimerToken or 0) + 1
        clearTacticalQueueState(self)
        self.diagnostics.tacticalAbsorbed =
            (self.diagnostics.tacticalAbsorbed or 0) + 1
    end
    self.queueRevision = (self.queueRevision or 0) + 1
    local revision = self.queueRevision
    local now = KWR.Util:Now()
    if settleDelay and settleDelay > 0 then
        self.requiredSettleAt = math.max(
            self.requiredSettleAt or 0, now + settleDelay)
    end
    if self.pending then
        self.diagnostics.coalesced = (self.diagnostics.coalesced or 0) + 1
        -- A public pulse must never hide a roster or lifecycle invalidation
        -- merely because it was the first event in the queue.
        if PUBLIC_REFRESH_REASONS[self.pendingReason] then
            if publicReason then
                self.pendingReason = "UPDATE_UI_WIDGET"
            else
                self.pendingReason = reason
            end
        end
        local requestedDueAt = now + self:EffectiveDelay(delay, reason)
        if self.pendingDueAt and requestedDueAt + 0.001 < self.pendingDueAt then
            self.diagnostics.queuePreemptions =
                (self.diagnostics.queuePreemptions or 0) + 1
            local queuedReason = self.pendingReason or reason
            self.timerToken = (self.timerToken or 0) + 1
            clearQueueState(self)
            self:Schedule(queuedReason, delay, revision)
        end
        return
    end
    self:Schedule(reason, delay, revision)
end

function Runtime:ForceRefresh(reason)
    self.timerToken = (self.timerToken or 0) + 1
    clearQueueState(self)
    self.latestQueuedReason = nil
    if self.tacticalPending then
        self.tacticalTimerToken = (self.tacticalTimerToken or 0) + 1
        clearTacticalQueueState(self)
        self.diagnostics.tacticalAbsorbed =
            (self.diagnostics.tacticalAbsorbed or 0) + 1
    end
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
    local current = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    if current and current.snapshot and current.snapshot.context
        and current.snapshot.context.preview == true then
        KWR:Print("Preview roster is synthetic; no Retail inspection was requested.", true)
        return true
    end
    local ok = self:ForceRefresh("manual-roster-rescan")
    local state = KWR.Store and KWR.Store.Get and KWR.Store:Get() or nil
    local roster = state and state.snapshot and state.snapshot.roster or nil
    local queued = 0
    if ok and KWR.RosterInspector
        and type(KWR.RosterInspector.BeginFullRescan) == "function" then
        queued = KWR.RosterInspector:BeginFullRescan(roster)
        KWR.RosterInspector:RequestNext(roster)
    end
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

function Runtime:QueueBattlefieldStatus()
    local now = KWR.Util:Now()
    local elapsed = now - (self.lastBattlefieldStatusQueueAt or 0)
    if elapsed < BATTLEFIELD_STATUS_REFRESH_INTERVAL then
        self.diagnostics.battlefieldStatusCoalesced =
            (self.diagnostics.battlefieldStatusCoalesced or 0) + 1
        self:Queue("UPDATE_BATTLEFIELD_STATUS",
            BATTLEFIELD_STATUS_REFRESH_INTERVAL - elapsed)
        return
    end
    self.lastBattlefieldStatusQueueAt = now
    self:Queue("UPDATE_BATTLEFIELD_STATUS", 0.12)
end

function Runtime:HandleEvent(event, ...)
    self.diagnostics.events = (self.diagnostics.events or 0) + 1
    incrementCounter(self.diagnostics.eventReasons, event or "unknown")
    appendEventTrace(self, event)
    if event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_LEAVING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
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
    if event == "UPDATE_BATTLEFIELD_STATUS" then
        self:UpdateLifecycle()
        self:QueueBattlefieldStatus()
        return
    end
    if event == "GROUP_ROSTER_UPDATE" then
        if KWR.Sensors then KWR.Sensors:InvalidateScoreboard() end
        self:Queue(event, 0.05)
        self:ScheduleTransitionSweep(event, true)
        return
    end
    if event == "UNIT_NAME_UPDATE" or event == "PLAYER_ROLES_ASSIGNED"
        or event == "PLAYER_SPECIALIZATION_CHANGED" then
        if event == "PLAYER_SPECIALIZATION_CHANGED" and KWR.Sensors then
            KWR.Sensors:InvalidateSpecialization((...))
        end
        if KWR.Sensors then KWR.Sensors:InvalidateScoreboard() end
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
        local relevant, widgetKind = KWR.Sensors:ObserveWidget((...))
        if relevant ~= true then
            self.diagnostics.ignoredWidgetEvents =
                (self.diagnostics.ignoredWidgetEvents or 0) + 1
            if widgetKind == "UNCHANGED" then
                self.diagnostics.unchangedWidgetPulses =
                    (self.diagnostics.unchangedWidgetPulses or 0) + 1
            else
                self.diagnostics.cosmeticWidgetPulses =
                    (self.diagnostics.cosmeticWidgetPulses or 0) + 1
            end
            return
        end
        local now = KWR.Util:Now()
        local elapsed = now - (self.lastWidgetQueueAt or 0)
        if elapsed < 0.25 then
            self.diagnostics.widgetEventsCoalesced =
                (self.diagnostics.widgetEventsCoalesced or 0) + 1
            -- ObserveWidget has already accepted and fingerprinted this final
            -- state. Queue a trailing refresh so it cannot be stranded after
            -- an earlier refresh consumed the leading edge of the burst.
            self:Queue("UPDATE_UI_WIDGET", 0.25 - elapsed)
            return
        end
        self.lastWidgetQueueAt = now
    end
    if event == "BATTLEGROUND_POINTS_UPDATE" then
        local now = KWR.Util:Now()
        local elapsed = now - (self.lastPointsQueueAt or 0)
        if elapsed < 0.50 then
            self.diagnostics.pointsEventsCoalesced =
                (self.diagnostics.pointsEventsCoalesced or 0) + 1
            -- The latest score is already available to the next capture. Keep
            -- one trailing refresh so a burst's final points update cannot be
            -- stranded behind the leading-edge rate limit.
            self:Queue("BATTLEGROUND_POINTS_UPDATE", 0.50 - elapsed)
            return
        end
        self.lastPointsQueueAt = now
    end
    if event == "UPDATE_BATTLEFIELD_SCORE" or event == "PVP_MATCH_ACTIVE"
        or event == "PVP_MATCH_COMPLETE" then
        if KWR.Sensors then KWR.Sensors:InvalidateScoreboard() end
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
            if event ~= "UNIT_AURA" and KWR.CombatRoster then
                KWR.CombatRoster:UpdateHealthForUnit(unit)
            end
            if event ~= "UNIT_AURA" and KWR.MainWindow then
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
    if TACTICAL_EVENTS[event] then
        self:QueueTactical(event, 0.05)
        return
    end
    if event == "PVP_MATCH_COMPLETE" then
        if KWR.CountdownState then KWR.CountdownState:Cancel("MATCH_COMPLETE") end
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
