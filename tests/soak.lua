-- Offline bounded-state soak. Run after installing fengari-node-cli or Lua 5.1+.
local testRoot = rawget(_G, "KWR_TEST_DRIVER_ROOT") or "tests"
dofile((tostring(testRoot):gsub("\\", "/")) .. "/smoke.lua")

local profileMs = 200000
local pendingCostMs = 0.10
local profilePhase = "start"
function debugprofilestop()
    if profilePhase == "start" then
        profilePhase = "stop"
        return profileMs
    end
    profileMs = profileMs + pendingCostMs
    profilePhase = "start"
    return profileMs
end

do
    local savedStoreState = KWR.Store.state
    local savedActive = KWR.MatchRuntime.active
    local savedPending = KWR.MatchRuntime.pending
    local savedTacticalPending = KWR.MatchRuntime.tacticalPending
    local savedAfter = C_Timer.After
    local scheduled = {}
    C_Timer.After = function(_, callback)
        scheduled[#scheduled + 1] = callback
    end

    local liveState = KWR.Store:Get()
    local laneSnapshot = KWR.Util:Copy(liveState.snapshot)
    laneSnapshot.context = KWR.Util:Copy(laneSnapshot.context or {})
    laneSnapshot.context.inPvP = true
    laneSnapshot.context.preview = false
    laneSnapshot.context.matchComplete = false
    laneSnapshot.context.sessionKey = "SOAK-RUNTIME-LANES"
    laneSnapshot.context.team = laneSnapshot.context.team or {
        scoreFaction = 0,
    }
    KWR.Store:Publish(
        laneSnapshot,
        liveState.prediction,
        liveState.assignments,
        liveState.command,
        liveState.diagnostics)
    KWR.MatchRuntime.active = true
    KWR.MatchRuntime.pending = false
    KWR.MatchRuntime.tacticalPending = false
    KWR.MatchRuntime.lastTacticalStrategicSignature = nil

    local strategicBefore = KWR.MatchRuntime.diagnostics.strategicRefreshes or 0
    local tacticalBefore = KWR.MatchRuntime.diagnostics.tacticalRefreshes or 0
    local commandSignature = KWR.Store:Get().command.signature
    for _ = 1, 20 do
        local scheduledBefore = #scheduled
        for _ = 1, 25 do
            KWR.MatchRuntime:HandleEvent("UNIT_SPELLCAST_SUCCEEDED", "player", nil, 1)
        end
        assert(KWR.MatchRuntime.tacticalPending == true
            and #scheduled == scheduledBefore + 1,
            "Combat-event batch did not coalesce into one tactical refresh.")
        scheduled[#scheduled]()
    end
    assert((KWR.MatchRuntime.diagnostics.strategicRefreshes or 0) == strategicBefore,
        "Equivalent combat-event storm executed the strategic pipeline.")
    assert((KWR.MatchRuntime.diagnostics.tacticalRefreshes or 0) == tacticalBefore + 20,
        "Coalesced combat-event storm did not execute one refresh per bounded batch.")
    assert(KWR.Store:Get().command.signature == commandSignature,
        "Tactical refresh recomposed the current strategic command.")
    assert((KWR.MatchRuntime.diagnostics.tacticalQueueReasons.UNIT_SPELLCAST_SUCCEEDED or 0)
        >= 250,
        "Tactical queue telemetry did not attribute the combat-event storm.")
    assert((KWR.MatchRuntime.diagnostics.tacticalDurationSampleCount or 0) >= 20
        and type(KWR.MatchRuntime.diagnostics.p95TacticalDurationMs) == "number",
        "Tactical lane did not retain an independently measurable P95 sample.")

    KWR.MatchRuntime.tacticalTimerToken =
        (KWR.MatchRuntime.tacticalTimerToken or 0) + 1
    KWR.MatchRuntime.timerToken = (KWR.MatchRuntime.timerToken or 0) + 1
    KWR.MatchRuntime.pending = savedPending
    KWR.MatchRuntime.tacticalPending = savedTacticalPending
    KWR.MatchRuntime.active = savedActive
    KWR.Store.state = savedStoreState
    C_Timer.After = savedAfter
end

profilePhase = "start"
KWR.db.profile.preview = true
for index = 1, 500 do
    if index % 100 == 0 then
        pendingCostMs = 3.20
    elseif index % 25 == 0 then
        pendingCostMs = 1.60
    elseif index % 10 == 0 then
        pendingCostMs = 0.80
    else
        pendingCostMs = 0.10
    end
    assert(KWR.MatchRuntime:ForceRefresh("manual"),
        "Soak refresh failed at iteration " .. tostring(index))
end

local diagnostics = KWR.MatchRuntime.diagnostics or {}
assert(#KWR.MatchRuntime.durationSamples <= 120, "Runtime duration sample buffer grew without bound.")
assert(#KWR.MatchRuntime.tacticalDurationSamples <= 120,
    "Tactical duration sample buffer grew without bound.")
assert(#KWR.Commander:GetHistory() <= 30, "Commander history grew without bound.")
assert(#KWR.Verification.ledger <= 60, "Verification ledger grew without bound.")
assert(#KWR.AAR:GetHistory() <= 30, "AAR history grew without bound.")
assert(#KWR.Reporter.events <= KWR.Reporter.maxEvents, "Reporter event buffer grew without bound.")
assert((diagnostics.averageDurationMs or 0) <= 1.5,
    "Average refresh duration exceeded the offline budget.")
assert((diagnostics.p95DurationMs or 0) <= 4.0,
    "p95 refresh duration exceeded the offline budget.")
assert((diagnostics.maxDurationMs or 0) <= 10.0,
    "Worst-case refresh duration exceeded the offline budget.")
assert((diagnostics.averageDurationMs or 0) >= 0.10,
    "Average refresh duration did not record the injected benchmark cost.")
assert((diagnostics.p95DurationMs or 0) >= 0.79,
    "p95 refresh duration did not retain the injected percentile slowdown.")
assert((diagnostics.maxDurationMs or 0) >= 3.19,
    "Worst-case refresh duration did not retain the injected slowdown peak.")
assert((diagnostics.errors or 0) == 0,
    "Runtime diagnostics recorded refresh errors during soak.")
for _, team in pairs(KWR.Reporter.tracks) do
    for _, track in pairs(team) do
        assert(#(track.points or {}) <= KWR.Reporter.maxPoints,
            "Reporter movement track grew without bound.")
    end
end

print("KWR_SOAK_PASS refreshes=500 durationSamples="
    .. tostring(#KWR.MatchRuntime.durationSamples)
    .. " avgMs=" .. tostring(diagnostics.averageDurationMs or 0)
    .. " p95Ms=" .. tostring(diagnostics.p95DurationMs or 0)
    .. " maxMs=" .. tostring(diagnostics.maxDurationMs or 0)
    .. " commanderHistory=" .. tostring(#KWR.Commander:GetHistory())
    .. " evidence=" .. tostring(#KWR.Verification.ledger))
