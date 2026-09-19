return function(KWR)
    local savedTimer, savedTime, savedGUID = C_Timer, GetTime, UnitGUID
    local now, timers = 100000, {}
    GetTime = function() return now end
    C_Timer = { After = function(delay, callback)
        timers[#timers + 1] = { at = now + delay, callback = callback }
    end }
    local namespace = setmetatable({ RegisterModule = function() end }, { __index = KWR })
    local function load(path)
        assert(loadfile(ResolveAddonPath(path)))("KnomercyWarRoom", namespace)
    end
    load("Runtime/MatchRuntime.lua")
    local runtime, passes, during = namespace.MatchRuntime, 0, false
    runtime.UpdateLifecycle = function() end
    runtime.Refresh = function()
        passes = passes + 1
        if during then
            during = false
            runtime:Queue("PVP_MATCH_ACTIVE", 0.05)
        end
    end
    runtime:Queue("burst", 0.2)
    for _ = 1, 1000 do runtime:Queue("burst", 0.2) end
    assert(#timers == 1, "Burst allocated more than one refresh timer")
    now = timers[1].at
    timers[1].callback()
    assert(passes == 1 and #timers == 1 and not runtime.pending,
        "Events consumed by capture caused redundant followup work")
    runtime:Queue("during-capture", 0.2)
    during = true
    now = timers[2].at
    timers[2].callback()
    assert(#timers == 3 and runtime.pendingReason == "PVP_MATCH_ACTIVE",
        "Followup replaced a critical event arriving during capture")
    now = timers[3].at
    timers[3].callback()
    assert(passes == 3 and not runtime.pending, "In-capture newest truth was lost")

    load("Data/Capabilities.lua")
    local cap = namespace.Capabilities
    for index = 1, 1000 do assert(cap:Resolve("unknown" .. index, "missing", "hero" .. index) == nil) end
    local stats = cap:CacheStats()
    assert(stats.entries == 1 and stats.misses == 1 and stats.hits == 999,
        "Unknown capability keys are unbounded or repeatedly miss")
    local original = cap:Resolve("DEATHKNIGHT", "Frost")
    assert(original, "Known capability missing")
    local copied = cap:Get("DEATHKNIGHT", "Frost")
    copied.ratings.mobility = -99
    assert(original.ratings.mobility ~= -99, "Mutable capability API leaked into shared cache")
    for index = 1, 1000 do cap:Resolve("DEATHKNIGHT", "Frost", "unreviewed" .. index) end
    assert(cap:CacheStats().entries == 2, "Unreviewed heroes created redundant resolved copies")

    local function legacyText(value)
        return value:gsub("|T.-|t", ""):gsub("|A.-|a", "")
            :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            :gsub("[\r\n;]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    end
    for _, value in ipairs({ "Frost", "Lumber Mill", "  a  b  ", "x\ty\nz\v ",
        "|cffffffffName|r", "|Ticon:16|t label", "|Aatlas|a\r; words", "\195\169clair-Realm" }) do
        assert(KWR.Util:Text(value) == legacyText(value), "Text fast path changed sanitization")
    end

    load("Runtime/Sensors.lua")
    namespace.Sensors:OnInitialize()
    local sensor = namespace.Sensors
    sensor.specCache = { other = { id = 99 }, player = { id = 1 } }
    sensor.specCache.shortAlias = sensor.specCache.player
    UnitGUID = function() return "player" end
    sensor:InvalidateSpecialization("player")
    assert(sensor.specCache.player == nil and sensor.specCache.shortAlias == nil
        and sensor.specCache.other.id == 99,
        "Specialization invalidation erased unrelated evidence")
    sensor.ResolveSpecialization = function() return 251, "Frost", "DAMAGER" end
    load("Runtime/RosterInspector.lua")
    local inspector, queued = namespace.RosterInspector, 0
    runtime.Queue = function() queued = queued + 1 end
    inspector.pendingGUID, inspector.pendingUnit = "player", "player"
    inspector:InspectReady("player")
    assert(queued == 1 and sensor.specCache.other.id == 99, "Accepted inspection lost peer cache or failed to refresh")
    inspector.pendingGUID, inspector.pendingUnit = "player", "player"
    inspector:InspectReady("player")
    assert(queued == 1, "Identical inspection rebuilt strategy")
    inspector.pendingGUID, inspector.pendingUnit = "recycled", "player"
    inspector:InspectReady("recycled")
    assert(sensor.specCache.recycled == nil and queued == 1, "Recycled token inherited another player's spec")
    local attempts = 0
    sensor.ResolveSpecialization = function() attempts = attempts + 1 end
    local record = { id = 251, name = "Frost", observedAt = now - 10 }
    for tick = 0, 49 do
        record = sensor:RefreshSpecialization("player", record, now + tick / 10, true)
    end
    assert(attempts == 1 and record.observedAt == now - 10 and record.name == "Frost",
        "Failed spec reads spun or renewed old observation timestamps")
    sensor:RefreshSpecialization("player", record, now + 5, true)
    assert(attempts == 2, "Failed spec read did not resume at its retry deadline")

    load("Runtime/Commander.lua")
    local commander = namespace.Commander
    local state = { snapshot = { context = { inPvP = true } }, assignments = {} }
    namespace.Store = { Get = function() return state end }
    local snapshot = { capturedAt = now, roster = {}, enemies = {},
        context = { inPvP = true, mapKey = "ARATHI", kind = "NODE", sessionKey = "clock-test" },
        score = { friendly = 100, enemy = 200, max = 1500 },
        objectives = { rows = { { label = "Blacksmith", owner = "ENEMY", state = "CONTROLLED" } } },
        strategy = { planID = "CLOCK_TEST", target = "Blacksmith", action = "REINFORCE Blacksmith",
            objectiveDecision = { target = "Blacksmith" } },
        responsePackage = { target = "Blacksmith", moverText = "Mover", moverActors = {
            { name = "Mover", guid = "Mover", role = "Strike Team", location = "Blacksmith" } },
            actorAssignments = { { name = "Mover", guid = "Mover", role = "Strike Team", location = "Blacksmith" } } },
    }
    local prediction = { status = "LOSE", urgency = 40, captureDeadline = 30 }
    local command = commander:Compose(snapshot, prediction, {})
    assert(command.activePlay.expectedResolutionAt == now + 30
        and command.activePlay.hardDeadlineAt > now + 30,
        "Relative deadline was interpreted as client uptime")
    assert(commander:TimingText(command) == "BY 0:30", "Issued countdown is not relative to issue time")
    now = now + 11
    assert(commander:TimingText(command) == "BY 0:19", "Retained countdown froze its text")
    local cardState = { snapshot = KWR.Util:Copy(snapshot), command = command,
        assignments = { { name = "Mover", guid = "Mover", role = "Strike Team", location = "Lumber Mill" } } }
    cardState.snapshot.responsePackage = { target = "Lumber Mill",
        actorAssignments = cardState.assignments, moverText = "CandidateOnly" }
    local card = KWR.CommandView:CommanderCard(cardState)
    assert(card.duties[1].location == "Blacksmith" and card.now.timing == "BY 0:19"
        and not card.speech:find("Lumber Mill", 1, true),
        "Retained speech mixed candidate jobs with the issued plan")
    now = now + 19
    assert(commander:TimingText(command) == "REASSESS", "Expired deadline remained an actionable BY 0:00")

    local assignments = { { name = "Mover", guid = "Mover", role = "Strike Team", location = "Lumber Mill" } }
    snapshot.strategy.executionAssessment = { confidence = "HIGH",
        actionOpportunity = { action = "REINFORCE", target = "Blacksmith", score = 100 } }
    local response = KWR.Assignments:ResponsePackage(snapshot, assignments)
    assert(response.qualified == false and response.assignmentConflict,
        "Execution proposal issued a different destination than named assignments")
    assignments[1].location = "Blacksmith"
    assert(KWR.Assignments:ResponsePackage(snapshot, assignments).qualified,
        "Coherent reinforcement plan was incorrectly suppressed")

    load("Runtime/CombatIntel.lua")
    local intel = namespace.CombatIntel
    local live = intel:GetRecord("Live", "Live", true)
    live.lastObservedAt = now - 700
    local stale = intel:GetRecord("Old", "Old", true)
    stale.lastObservedAt = now - 700
    intel:Prune({ enemies = { { guid = "Live", name = "Live" } } })
    assert(intel.byGUID.Live == live and intel.byName.live == live
        and intel.byGUID.Old == nil and intel.byName.old == nil,
        "Memory pruning dropped current truth or retained stale aliases")
    C_Timer, GetTime, UnitGUID = savedTimer, savedTime, savedGUID
    print("KWR_RUNTIME_OWNERSHIP_PASS burst=1001 captures=1 clock=long-uptime cache=bounded")
end
