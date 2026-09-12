return function(KWR)
    local savedTime, savedLeader = GetTime, UnitIsGroupLeader
    local clock = 100
    GetTime = function() return clock end
    UnitIsGroupLeader = function() return true end
    local timer = KWR.CountdownState
    timer:Cancel("FIXTURE")
    local snapshot = {
        context = { inPvP = true, sessionKey = "fixture-match", mapKey = "ARATHI", kind = "NODE" },
        capturedAt = clock,
        objectives = { rows = {
            { id = "LM", label = "Lumber Mill", owner = "FRIENDLY", state = "CONTROLLED" },
            { id = "BS", label = "Blacksmith", owner = "ENEMY", state = "CONTROLLED" },
        } },
        roster = { { name = "Actor", guid = "Actor-1", role = "DAMAGER", spec = "Subtlety",
            classFile = "ROGUE", dead = false, connected = true } },
        enemies = { { name = "Target", guid = "Target-1", role = "DAMAGER", spec = "Arms",
            visible = true, localRange = true, dead = false, killable = true,
            healthPercent = 25, source = "nameplate", lastSeenAt = clock } },
    }
    local plan = KWR.TeamfightCommandPlanner:Plan(snapshot)
    assert(plan.killTarget and plan.displayEligible and plan.countdown.state == "UNTIMED", "Countdown fixture lacks eligible target")
    assert(timer:Text(plan.countdown) == "ON LEADER CALL" and timer:Build(5).state == "UNTIMED",
        "Legacy numeric Build or missing start invented a countdown")
    assert(timer:Start(snapshot, plan, 5))
    local cueID, deadline
    for _, step in ipairs({ {100, 5}, {101, 4}, {104, 1}, {105, 0} }) do
        clock = step[1]
        local current = KWR.TeamfightCommandPlanner:Plan(snapshot)
        local projected = current.countdown
        cueID, deadline = cueID or projected.id, deadline or projected.deadline
        assert(projected.seconds == step[2] and projected.deadline == 105 and projected.id == cueID,
            "Planner refresh restarted the explicit deadline")
        assert(KWR.CountdownFrame:Build(projected).seconds == step[2], "Countdown presenter diverged")
        local packetSnapshot = KWR.Util:Copy(snapshot)
        packetSnapshot.teamfight = current
        local packet = KWR.ExecutionCommandBuilder:Build(packetSnapshot, {}, {}, {})
        assert(packet.trigger == projected.text, "Execution packet timing diverged")
        packetSnapshot.executionCommand = packet
        local view = KWR.CommandView:FightNow({ snapshot = packetSnapshot })
        if view.current.source == "LOCAL_FIGHT" and view.current.what == "KILL" then
            assert(view.current.when == projected.text, "HUD command model timing diverged")
        end
        local card = KWR.TeamfightCommandCard:Build(current)
        assert(card.lines[#card.lines]:find(projected.text, 1, true), "Teamfight card timing diverged")
    end
    local oldGO = timer:Build(snapshot, plan)
    clock = 106
    assert(timer:Text(oldGO) == "ON LEADER CALL" and timer.active == nil, "Expired copy resurrected GO")
    clock = 100
    assert(timer:Start(snapshot, plan, 5))
    local before = timer:Build(snapshot, plan)
    local reversed = KWR.Util:Copy(snapshot)
    reversed.objectives.rows[1], reversed.objectives.rows[2] = reversed.objectives.rows[2], reversed.objectives.rows[1]
    assert(timer:Build(reversed, plan).id == before.id, "Objective order canceled timing")
    for _, mutate in ipairs({
        function(s) s.context.sessionKey = "next-match" end,
        function(s) s.context.matchComplete = true end,
        function(s) s.context.preview = true end,
        function(s) s.enemies = {} end,
        function(s) s.enemies[1].dead = true end,
        function(s) s.enemies[1].localRange = false end,
        function(s) s.objectives.rows[1].owner = "ENEMY" end,
        function(_, p) p.killTarget.targetGUID = "Target-2" end,
        function(_, p) p.assignments = { { actorGUID = "Actor-2", verb = "Subdue", targetGUID = "Healer" } } end,
        function(_, p) p.killTarget = nil end,
        function(_, p) p.displayEligible = false end,
    }) do
        assert(timer:Start(snapshot, plan, 5))
        local old = timer:Build(snapshot, plan)
        local changed, changedPlan = KWR.Util:Copy(snapshot), KWR.Util:Copy(plan)
        mutate(changed, changedPlan)
        assert(timer:Build(changed, changedPlan).state == "UNTIMED" and timer:Text(old) == "ON LEADER CALL",
            "Changed battlefield/plan truth preserved a stale cue")
    end
    for _, duration in ipairs({ 0, 11, 1.5, -1, math.huge, 0/0, "invalid" }) do
        assert(not timer:Start(snapshot, plan, duration), "Invalid countdown duration accepted")
    end
    assert(not timer:Start(snapshot, plan, nil))
    UnitIsGroupLeader = nil
    assert(not timer:Start(snapshot, plan, 5), "Missing leadership API authorized countdown")
    UnitIsGroupLeader = function() error("unavailable") end
    assert(not timer:Start(snapshot, plan, 5), "Throwing leadership API authorized countdown")
    UnitIsGroupLeader = function() return false end
    assert(not timer:Start(snapshot, plan, 5), "Nonleader authorized countdown")
    UnitIsGroupLeader = function() return true end
    local invalid = KWR.Util:Copy(snapshot)
    invalid.context.sessionKey = nil
    assert(not timer:Start(invalid, plan, 5), "Missing session identity authorized countdown")
    invalid.context.sessionKey, invalid.context.preview = "fixture-match", true
    assert(not timer:Start(invalid, plan, 5), "Preview authorized countdown")
    invalid.context.preview, invalid.context.matchComplete = false, true
    assert(not timer:Start(invalid, plan, 5), "Completed match authorized countdown")
    assert(timer:Start(snapshot, plan, 5))
    local old = timer:Build(snapshot, plan)
    clock = 99
    assert(timer:Text(old) == "ON LEADER CALL" and timer.active == nil, "Clock rollback preserved timing")
    clock = 105
    assert(timer:Text(old) == "ON LEADER CALL", "Clock recovery resurrected canceled GO")
    clock = 100
    assert(timer:Start(snapshot, plan, 5))
    old = timer:Build(snapshot, plan)
    timer:Cancel()
    assert(timer:Text(old) == "ON LEADER CALL", "Manual cancel retained copied cue")
    local ordered = KWR.Util:Copy(plan)
    ordered.assignments = {
        { actorGUID = "A", verb = "Subdue", targetGUID = "H1" },
        { actorGUID = "B", verb = "Disrupt", targetGUID = "H2" },
    }
    assert(timer:Start(snapshot, ordered, 5))
    local orderedID = timer:Build(snapshot, ordered).id
    ordered.assignments[1], ordered.assignments[2] = ordered.assignments[2], ordered.assignments[1]
    assert(timer:Build(snapshot, ordered).id == orderedID, "Assignment order canceled timer")
    UnitIsGroupLeader = function() return false end
    assert(timer:Build(snapshot, ordered).state == "UNTIMED", "Leadership loss retained cue")
    UnitIsGroupLeader = function() return true end
    local savedEnabled, savedAvailable = KWR.CommandAudio.IsEnabled, KWR.SafeSpeechAdapter.IsAvailable
    KWR.CommandAudio.IsEnabled, KWR.SafeSpeechAdapter.IsAvailable = function() return true end, function() return true end
    assert(timer:Start(snapshot, plan, 5))
    local packet = { countdown = timer:Build(snapshot, plan), audible = true, authoritative = true, spokenText = "Go in 5" }
    assert(KWR.CommandAudio:CanSpeak(packet), "Fresh explicitly timed speech rejected")
    clock = 101
    assert(not KWR.CommandAudio:CanSpeak(packet), "Delayed speech retained obsolete remaining time")
    clock = 105
    packet.countdown, packet.spokenText = timer:Build(snapshot, plan), "Go now"
    assert(KWR.CommandAudio:CanSpeak(packet), "Current GO speech rejected")
    timer:Cancel()
    assert(not KWR.CommandAudio:CanSpeak(packet), "Canceled GO speech remained eligible")
    local savedAfter, savedSpeak, savedStop = C_Timer.After, KWR.SafeSpeechAdapter.Speak, KWR.SafeSpeechAdapter.Stop
    local savedLastSpoken, savedSignature = KWR.CommandAudio.lastSpokenAt, KWR.CommandAudio.lastSignature
    local queued, spoken = nil, 0
    C_Timer.After = function(_, callback) queued = callback end
    KWR.SafeSpeechAdapter.Speak = function() spoken = spoken + 1; return true end
    KWR.SafeSpeechAdapter.Stop = function() end
    clock = 100
    assert(timer:Start(snapshot, plan, 5))
    clock = 105
    packet.countdown, packet.signature = timer:Build(snapshot, plan), "countdown-fixture-queued"
    KWR.CommandAudio.lastSpokenAt, KWR.CommandAudio.lastSignature = clock, nil
    assert(KWR.CommandAudio:SpeakPacket(packet, false) and queued, "GO speech was not queued for fixture")
    clock = 112
    queued()
    assert(spoken == 0, "Queued callback spoke an expired GO")
    local savedStoreGet = KWR.Store.Get
    local replacement = KWR.Util:Copy(packet)
    packet.commandId, packet.commandRevision, packet.signature = "audio-old", 1, "audio-old-packet"
    replacement.commandId, replacement.commandRevision, replacement.signature = "audio-new", 2, "audio-new-packet"
    clock = 100
    assert(timer:Start(snapshot, plan, 5))
    packet.countdown, packet.spokenText = timer:Build(snapshot, plan), "Go in 5"
    KWR.Store.Get = function()
        return { command = { commandId = "audio-new", commandRevision = 2 },
            snapshot = { executionCommand = replacement } }
    end
    KWR.CommandAudio.lastSpokenAt, KWR.CommandAudio.lastSignature = clock, nil
    assert(KWR.CommandAudio:SpeakPacket(packet, false) and queued,
        "Lifecycle-audio fixture did not queue the old packet")
    queued()
    assert(spoken == 0, "Queued audio spoke after its command lifecycle was replaced")
    KWR.Store.Get = savedStoreGet
    C_Timer.After, KWR.SafeSpeechAdapter.Speak, KWR.SafeSpeechAdapter.Stop = savedAfter, savedSpeak, savedStop
    KWR.CommandAudio.lastSpokenAt, KWR.CommandAudio.lastSignature = savedLastSpoken, savedSignature
    KWR.CommandAudio.IsEnabled, KWR.SafeSpeechAdapter.IsAvailable = savedEnabled, savedAvailable
    clock = 100
    local savedGet, savedRefresh, savedPrint = KWR.Store.Get, KWR.MatchRuntime.ForceRefresh, KWR.Print
    local refreshes = 0
    local commandSnapshot = KWR.Util:Copy(snapshot)
    commandSnapshot.teamfight = plan
    KWR.Store.Get = function() return { snapshot = commandSnapshot } end
    KWR.MatchRuntime.ForceRefresh = function() refreshes = refreshes + 1 end
    KWR.Print = function() end
    SlashCmdList.KWR("countdown 5")
    assert(timer.active and timer.active.deadline == 105 and refreshes == 1, "Slash start did not bind deadline")
    SlashCmdList.KWR("countdown cancel")
    assert(timer.active == nil and refreshes == 2, "Slash cancel failed")
    SlashCmdList.KWR("countdown 1.5")
    assert(timer.active == nil and refreshes == 2, "Slash accepted fractional duration")
    KWR.Store.Get, KWR.MatchRuntime.ForceRefresh, KWR.Print = savedGet, savedRefresh, savedPrint
    local namespace = { CountdownState = timer, Util = KWR.Util, RegisterModule = function() end }
    assert(loadfile(ResolveAddonPath("Runtime/MatchRuntime.lua")))("KnomercyWarRoom", namespace)
    assert(timer:Start(snapshot, plan, 5))
    namespace.MatchRuntime:ResetTransientTruth()
    assert(timer.active == nil, "Runtime reset retained timing")
    assert(timer:Start(snapshot, plan, 5))
    namespace.MatchRuntime:Stop()
    assert(timer.active == nil, "Runtime stop retained timing")
    GetTime, UnitIsGroupLeader = savedTime, savedLeader
end
