-- Offline bounded-state soak. Run after installing fengari-node-cli or Lua 5.1+.
dofile("tests/smoke.lua")

KWR.db.profile.preview = true
for index = 1, 500 do
    assert(KWR.MatchRuntime:ForceRefresh("offline-soak-" .. tostring(index)),
        "Soak refresh failed at iteration " .. tostring(index))
end

assert(#KWR.MatchRuntime.durationSamples <= 120, "Runtime duration sample buffer grew without bound.")
assert(#KWR.Commander:GetHistory() <= 30, "Commander history grew without bound.")
assert(#KWR.Verification.ledger <= 60, "Verification ledger grew without bound.")
assert(#KWR.AAR:GetHistory() <= 30, "AAR history grew without bound.")
assert(#KWR.Reporter.events <= KWR.Reporter.maxEvents, "Reporter event buffer grew without bound.")
for _, team in pairs(KWR.Reporter.tracks) do
    for _, track in pairs(team) do
        assert(#(track.points or {}) <= KWR.Reporter.maxPoints,
            "Reporter movement track grew without bound.")
    end
end

print("KWR_SOAK_PASS refreshes=500 durationSamples="
    .. tostring(#KWR.MatchRuntime.durationSamples)
    .. " commanderHistory=" .. tostring(#KWR.Commander:GetHistory())
    .. " evidence=" .. tostring(#KWR.Verification.ledger))
