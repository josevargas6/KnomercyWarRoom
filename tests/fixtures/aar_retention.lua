return function(KWR)
    local aar = KWR.AAR
    local savedActive, savedCompleted, savedCheckpoint = aar.active, aar.lastCompleted, aar.lastCheckpointAt
    local savedJournal = KWR.Util:Copy(KWR.db.journal)
    local savedOpponentModels = KWR.Util:Copy(KWR.db.opponentModels)
    local savedMode, savedChannel = KWR.db.profile.developmentMode, KWR.BuildInfo.channel
    local savedTime, savedEpoch = GetTime, time
    local clock = 200
    GetTime = function() return clock end
    time = function() return clock end
    KWR.BuildInfo.channel = "local"
    KWR.db.profile.developmentMode = false
    local state = { assignments = {}, prediction = {}, diagnostics = { lastDurationMs = 1 },
        command = { signature = "first", action = "Hold Farm",
            simulations = { { id = "HOLD", probability = 70 }, { id = "ROTATE", probability = 30 } } },
        snapshot = {
            context = { inPvP = true, mapKey = "ARATHI", phase = "ACTIVE", team = { side = 1 } },
            score = { friendly = 100, enemy = 90, max = 1500, source = "ui_widget" },
            objectives = { rows = {}, events = {} },
            roster = { { guid = "Player-AAR", name = "Player", classFile = "PRIEST", spec = "Holy" } },
            enemies = {}, reporter = {}, combat = {},
        } }
    aar.active = nil
    aar:Record(state)
    local team = aar.active
    assert(team.captureMode == "TEAM" and team.performance == nil
        and team.commands[1].simulations == nil, "Default AAR retained development payloads")
    assert(#KWR.db.journal.interrupted.commands == 1,
        "Initial checkpoint did not include the first recorded call")
    KWR.db.profile.developmentMode = true
    for index = 1, 150 do
        clock = clock + 1
        state.command.signature = "call-" .. index
        state.snapshot.roster[1].location = "Location " .. index
        state.snapshot.objectives.events = { { kind = "CAPTURE", text = "event " .. index, at = clock } }
        state.snapshot.lastMessage = "message " .. index
        aar:Record(state)
        assert(#team.commands <= 10 and #team.events <= 12
            and #team.objectiveTimeline <= 24
            and #team.playerEvidence["Player-AAR"].locations <= 4,
            "Active team AAR exceeded write bounds before checkpointing")
    end
    assert(team.captureMode == "TEAM" and team.performance == nil,
        "Changing opt-in reclassified the active match")
    assert(team.commands[1].at == 200 and team.commands[#team.commands].at == clock,
        "Command retention lost the opening or latest call")
    local seen = 0
    for _ in pairs(team.seenObjectiveEvents) do seen = seen + 1 end
    assert(seen <= 128 and #team.seenObjectiveOrder <= 128,
        "Objective dedup working index grew without bound")
    local before = #team.objectiveTimeline
    aar:CaptureObjectives(team, state.snapshot)
    assert(#team.objectiveTimeline == before, "Repeated objective event was duplicated")
    aar:PersistActive(true)
    assert(type(team.objectiveStates) == "table" and type(team.seenObjectiveEvents) == "table",
        "Checkpoint stripped active working indexes")
    local checkpoint = KWR.db.journal.interrupted
    assert(checkpoint ~= team and checkpoint.captureMode == "TEAM"
        and checkpoint.commands ~= team.commands, "Checkpoint aliased active data")
    local export = aar:Export(team)
    assert(export:find("Capture Mode: TEAM", 1, true)
        and export:find("detailed development telemetry was not retained", 1, true),
        "Team export fabricated zero-valued development measurements")
    state.snapshot.context.matchComplete = true
    state.snapshot.score.friendly = 1500
    aar:Finish(state)
    assert(aar.active == nil and KWR.db.journal.interrupted == nil
        and aar.lastCompleted.commands[#aar.lastCompleted.commands].at == clock,
        "Final AAR was lost or its interruption checkpoint survived")
    local historyCount = #KWR.db.journal.history
    aar:Finish(state)
    assert(#KWR.db.journal.history == historyCount, "Repeated finalization duplicated the match")
    state.snapshot.context.matchComplete = false
    clock = clock + 1
    aar:Start(state)
    aar:Record(state)
    assert(aar.active.captureMode == "DEVELOPMENT" and aar.active.performance.samples > 0
        and aar.active.performance.maxRefreshMs == 1
        and #aar.active.commands[1].simulations == 2,
        "Explicit development opt-in did not retain diagnostics")
    local legacy = { captureMode = "PLAYER", commands = {}, events = {}, performance = {} }
    aar:CompactEntry(legacy)
    assert(legacy.captureMode == "TEAM" and legacy.performance == nil, "PLAYER mode did not normalize")
    local historical = { performance = { samples = 7 }, commands = {} }
    aar:CompactEntry(historical)
    assert(historical.captureMode == "LEGACY_DEVELOPMENT" and historical.performance.samples == 7,
        "Unlabeled historical diagnostics were erased")
    local future = { captureModeVersion = 2, captureMode = "FUTURE", commands = "future" }
    assert(aar:CompactEntry(future) == future and future.commands == "future",
        "Future capture format was overwritten")
    aar.active, aar.lastCompleted, aar.lastCheckpointAt = savedActive, savedCompleted, savedCheckpoint
    KWR.db.journal = savedJournal
    KWR.db.opponentModels = savedOpponentModels
    KWR.db.profile.developmentMode, KWR.BuildInfo.channel = savedMode, savedChannel
    GetTime, time = savedTime, savedEpoch
end
