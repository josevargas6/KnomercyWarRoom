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
    assert(KWR.MatchRuntime:ForceRefresh("offline-soak-" .. tostring(index)),
        "Soak refresh failed at iteration " .. tostring(index))
end

local diagnostics = KWR.MatchRuntime.diagnostics or {}
assert(#KWR.MatchRuntime.durationSamples <= 120, "Runtime duration sample buffer grew without bound.")
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