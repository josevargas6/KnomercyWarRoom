return function(KWR)
    local originalTime, originalCombat, originalRefresh, originalRead, originalSecret = GetTime,
        InCombatLockdown, UpdateAddOnMemoryUsage, GetAddOnMemoryUsage, issecretvalue
    local clock, locked, scans, reads, reading = 0, true, 0, 0, 20480
    local refreshThrows, readThrows = false, false
    local opaque = {}
    GetTime = function() return clock end
    InCombatLockdown = function() return locked end
    issecretvalue = function(value) return rawequal(value, opaque) end
    local function refresh()
        scans = scans + 1
        if refreshThrows then error("refresh unavailable") end
    end
    UpdateAddOnMemoryUsage = refresh
    GetAddOnMemoryUsage = function()
        reads = reads + 1
        if readThrows then error("read unavailable") end
        return reading
    end
    local namespace = setmetatable({ RegisterModule = function() end }, { __index = KWR })
    assert(loadfile(ResolveAddonPath("Runtime/MemoryBudget.lua")))("KnomercyWarRoom", namespace)
    local budget = namespace.MemoryBudget
    local trims = 0
    budget.Trim = function(_, _, force) if force then trims = trims + 1 end end
    local initial = budget:Summary(true)
    assert(initial.currentMB == nil and initial.sampleStatus == "UNAVAILABLE"
        and initial.sampledAt == nil and scans == 0 and reads == 0,
        "Initial combat memory was reported as zero or freshly measured")
    locked, clock = false, 1
    local measured = budget:Summary(true)
    assert(measured.currentMB == 20 and measured.sampleStatus == "MEASURED"
        and measured.sampledAt == 1 and scans == 1 and reads == 1,
        "Explicit memory refresh did not record a successful measurement")
    for second = 1, 30 do
        clock = second
        for _ = 1, 10 do
            budget:Sample(nil, false)
            budget:Update({ revision = 20, snapshot = { context = { inPvP = true } } })
        end
    end
    assert(scans == 1 and reads == 1 and budget.lastMeasuredAt == 1,
        "Recurring callers bypassed the shared memory sampling interval")
    clock = 31
    budget:Sample(nil, false)
    assert(scans == 2 and budget.lastMeasuredAt == 31, "Routine measurement did not resume at its deadline")
    clock = 32
    budget:Summary(true)
    assert(scans == 3 and budget.lastMeasuredAt == 32, "Explicit refresh was blocked by routine throttling")
    locked, clock = true, 37
    local cached = budget:Summary(true)
    assert(cached.currentMB == 20 and cached.sampleStatus == "CACHED"
        and cached.sampledAt == 32 and cached.sampleAgeSeconds == 5
        and cached.sampleReason == "COMBAT_DEFERRED" and scans == 3,
        "Combat re-stamped or refreshed cached memory")
    locked, clock, refreshThrows = false, 40, true
    cached = budget:Summary(true)
    assert(cached.sampledAt == 32 and cached.sampleReason == "REFRESH_FAILED" and reads == 3,
        "A failed refresh advanced memory provenance or read stale API data")
    clock = 41
    budget:Sample(nil, false)
    assert(scans == 4 and budget:Summary().sampleReason == "REFRESH_FAILED",
        "A failed recurring sample retried without a bound or lost its failure reason")
    refreshThrows, readThrows, clock = false, true, 42
    assert(budget:Summary(true).sampleReason == "READ_FAILED" and budget.lastMeasuredAt == 32,
        "A failed memory read advanced successful measurement time")
    readThrows, clock = false, 43
    UpdateAddOnMemoryUsage = nil
    assert(budget:Summary(true).sampleReason == "API_UNAVAILABLE" and budget.lastMeasuredAt == 32,
        "Missing memory API was treated as a fresh measurement")
    UpdateAddOnMemoryUsage = refresh
    for _, invalid in ipairs({ opaque, -1, math.huge, 0 / 0, "invalid" }) do
        clock = clock + 1
        reading = invalid
        assert(budget:Summary(true).sampleReason == "INVALID_READING" and budget.lastMeasuredAt == 32,
            "Invalid or protected memory advanced measurement time")
    end
    reading, clock = 40960, 50
    budget:Sample({ revision = 40, snapshot = { context = { inPvP = true } } }, true, true)
    assert(budget.lastMeasuredAt == 50 and budget.lastPressure == "FAIL" and trims == 1
        and budget.degradationMode == "CRITICAL_LIVE_ONLY"
        and budget:Cap("opponentProcessedMatches", 0) == 80,
        "Recovery lost hard-pressure handling or processed-match retention")
    local originalBudget = KWR.MemoryBudget
    KWR.MemoryBudget = budget
    locked, clock = true, 55
    local _, report = KWR.MainWindowReports:BuildPerformancePayload(KWR.Store:Get())
    assert(report:find("CACHED; age 5.0s; COMBAT_DEFERRED", 1, true)
        and not report:find("fresh GetAddOnMemoryUsage sample", 1, true),
        "Performance report called cached memory fresh")
    budget.lastMeasuredAt, budget.lastMeasuredMB = nil, 0
    local _, missing = KWR.MainWindowReports:BuildPerformancePayload(KWR.Store:Get())
    assert(missing:find("KWR addon memory now: unavailable", 1, true),
        "Performance report substituted a historical or zero value for unavailable current memory")
    KWR.MemoryBudget = originalBudget
    GetTime, InCombatLockdown, UpdateAddOnMemoryUsage, GetAddOnMemoryUsage, issecretvalue = originalTime,
        originalCombat, originalRefresh, originalRead, originalSecret
end
