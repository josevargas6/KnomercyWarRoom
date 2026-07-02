local _, KWR = ...

local Runtime = {
    active = false,
    pending = false,
    ticker = nil,
    lastMessage = "",
    diagnostics = {
        refreshes = 0,
        lastReason = "startup",
        lastDurationMs = 0,
        averageDurationMs = 0,
        p95DurationMs = 0,
        maxDurationMs = 0,
        memoryKB = 0,
        events = 0,
        coalesced = 0,
        errors = 0,
        transitionRefreshes = 0,
        lastTransitionDurationMs = 0,
    },
    durationSamples = {},
}
KWR.MatchRuntime = Runtime

local MIN_REFRESH_INTERVAL = 0.25
local MAX_DURATION_SAMPLES = 120

local PERSISTENT_EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "GROUP_ROSTER_UPDATE",
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

function Runtime:Start()
    if self.active then return end
    self.matchComplete = false
    self.active = true
    if C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(1, function()
            if Runtime.active then Runtime:Refresh("active-pulse") end
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

function Runtime:Refresh(reason)
    local started = type(debugprofilestop) == "function" and debugprofilestop() or 0
    local ok, message = xpcall(function()
        local snapshot
        if KWR.db.profile.preview and not isPvP() then
            snapshot = KWR.Preview:Build()
        else
            snapshot = KWR.Sensors:Capture(self.lastMessage)
        end
        snapshot.context.matchComplete = self.matchComplete == true
        snapshot = KWR.EncounterHistory:Enrich(snapshot)
        KWR.RosterInspector:RequestNext(snapshot.roster)
        snapshot = KWR.ObjectiveIntel:Apply(snapshot)
        snapshot.formation = KWR.FormationAdvisor:Evaluate(snapshot)
        snapshot.combat = KWR.CombatIntel:Analyze(snapshot)
        snapshot.reporter = KWR.Reporter:Observe(snapshot)
        local prediction = KWR.Predictor:Evaluate(snapshot)
        snapshot.strategy = KWR.Strategist:Evaluate(snapshot, prediction)
        local assignments = KWR.Assignments:Build(snapshot, prediction)
        snapshot.assignmentIntegrity = KWR.Assignments:Integrity(snapshot, assignments)
        snapshot.strategy.executionAssessment =
            KWR.Strategist:AssessExecution(snapshot, prediction, assignments)
        snapshot.responsePackage =
            KWR.Assignments:ResponsePackage(snapshot, assignments)
        if self.reassessRequested then
            local previous = KWR.Store:Get()
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
            while #self.durationSamples > MAX_DURATION_SAMPLES do table.remove(self.durationSamples, 1) end
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
                if type(collectgarbage) == "function" then
                    local memory = KWR.Util:Call(collectgarbage, "count")
                    self.diagnostics.memoryKB = KWR.Util:Number(memory, self.diagnostics.memoryKB) or 0
                end
            end
        end
        self.lastRefreshAt = KWR.Util:Now()
        KWR.Store:Publish(snapshot, prediction, assignments, command, KWR.Util:Copy(self.diagnostics))
    end, geterrorhandler())
    if not ok then
        self.diagnostics.errors = self.diagnostics.errors + 1
        KWR:Print("Runtime refresh failed: " .. tostring(message), true)
    end
    return ok
end

function Runtime:Queue(reason, delay)
    if self.pending then
        self.diagnostics.coalesced = (self.diagnostics.coalesced or 0) + 1
        return
    end
    self.pending = true
    local elapsed = KWR.Util:Now() - (self.lastRefreshAt or 0)
    delay = math.max(delay or 0.10, math.max(0, MIN_REFRESH_INTERVAL - elapsed))
    local function run()
        Runtime.pending = false
        Runtime:UpdateLifecycle()
        Runtime:Refresh(reason or "queued")
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, run)
    else
        run()
    end
end

function Runtime:ForceRefresh(reason)
    self.pending = false
    self:UpdateLifecycle()
    return self:Refresh(reason or "manual")
end

function Runtime:Reassess()
    self.reassessRequested = true
    local ok = self:ForceRefresh("manual-reassess")
    local state = KWR.Store:Get()
    if ok and state and state.command then
        KWR:Print("Reassessed: " .. KWR.Util:Text(state.command.action,
            "Current plan confirmed.", 120), true)
    else
        KWR:Print("Reassessment failed. Open /kwr verify and capture the warning.", true)
    end
    return ok
end

function Runtime:HandleEvent(event, ...)
    self.diagnostics.events = (self.diagnostics.events or 0) + 1
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Queue(event, 1.0)
        return
    end
    if event == "GROUP_ROSTER_UPDATE" then
        self:Queue(event, 0.15)
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
            local state = KWR.Store:Get()
            local mapKey = state and state.snapshot and state.snapshot.context
                and state.snapshot.context.mapKey
            KWR.ObjectiveIntel:ObserveMessage(self.lastMessage, mapKey)
        end
    end
    if event == "UPDATE_UI_WIDGET" and KWR.Sensors then
        KWR.Sensors:ObserveWidget((...))
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
        if unit then KWR.EnemyIntel:ObserveToken(unit, "Unit Event") end
    end
    if event == "PVP_MATCH_COMPLETE" then
        self.matchComplete = true
        self:Refresh(event)
        self:Queue("PVP_MATCH_COMPLETE_FINAL", 0.35)
        return
    end
    self:Queue(event, event == "UPDATE_UI_WIDGET" and 0.05 or 0.12)
end

function Runtime:OnInitialize()
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
    self:Queue("login", 1.0)
end

function Runtime:OnDisable()
    self:Stop()
end

KWR:RegisterModule("MatchRuntime", Runtime)
