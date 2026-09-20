-- Attribution only: instrumented host preview, not a Retail budget verdict.
dofile("tests/smoke.lua")
local clock = os.clock
local workload = arg and arg[1] or "preview"
local liveWorkload = workload == "live-node" or workload == "live-cart"
local sampleTime, tick = KWR.Util:Now(), 0
local savedTime, savedCapture = GetTime, KWR.Sensors.Capture
if liveWorkload then
    local fixture = KWR.Preview:Build()
    fixture.context.preview, fixture.context.inPvP = false, true
    fixture.context.mapKey = workload == "live-cart" and "SILVERSHARD" or "ARATHI"
    fixture.context.kind = workload == "live-cart" and "CART" or "NODE"
    fixture.context.sessionKey = "profile-" .. workload
    if workload == "live-cart" then
        fixture.objectives.rows = {
            { label = "Lava", owner = "FRIENDLY", state = "CONTROLLED", x = 0.3, y = 0.6 },
            { label = "Water", owner = "ENEMY", state = "CONTROLLED", x = 0.6, y = 0.4 },
            { label = "Top", owner = "UNKNOWN", state = "AVAILABLE", x = 0.4, y = 0.2 },
        }
    end
    GetTime = function() return sampleTime end
    KWR.Sensors.Capture = function()
        local snapshot = KWR.Util:Copy(fixture)
        snapshot.capturedAt = sampleTime
        snapshot.score.friendly = 900 + tick * 3
        snapshot.score.enemy = 950 + tick * 2
        snapshot.score.observedAt, snapshot.objectives.observedAt = sampleTime, sampleTime
        for _, rows in ipairs({snapshot.roster, snapshot.enemies}) do
            for index, row in ipairs(rows) do
                row.lastSeenAt, row.observedAt = sampleTime, sampleTime
                row.dead = index == 2 and tick % 3 == 0
                row.healthPercent = 45 + tick % 50
            end
        end
        return snapshot
    end
end
local totals, stack = {}, {}
local originals = {}
local function instrument(moduleName, method)
    local module = KWR[moduleName]
    if not module or type(module[method]) ~= "function" then return end
    local original = module[method]
    local key = moduleName .. ":" .. method
    originals[#originals + 1] = { module, method, original }
    totals[key] = { ms = 0, calls = 0, tables = 0 }
    module[method] = function(self, ...)
        local started = clock()
        stack[#stack + 1] = key
        local result = original(self, ...)
        stack[#stack] = nil
        local row = totals[key]
        row.ms, row.calls = row.ms + (clock() - started) * 1000, row.calls + 1
        return result
    end
end
for _, pair in ipairs({
    {"Sensors", "Capture"}, {"Preview", "Build"},
    {"MatchRuntime", "RememberQualifiedTruth"}, {"MatchRuntime", "AnnotateRosterPresentation"},
    {"SentinelMerge", "Apply"}, {"EncounterHistory", "Enrich"}, {"KnowledgeManifest", "Status"},
    {"ObjectiveIntel", "Apply"}, {"FormationAdvisor", "Evaluate"}, {"CombatIntel", "Analyze"},
    {"TeamfightCommandPlanner", "Plan"}, {"Reporter", "Observe"}, {"Verification", "Contract"},
    {"Predictor", "Evaluate"}, {"Strategist", "Evaluate"}, {"Strategist", "AssessExecution"},
    {"Assignments", "Build"}, {"Assignments", "Integrity"}, {"Assignments", "ResponsePackage"},
    {"Commander", "Compose"}, {"Commander", "ObservePublicExecution"},
    {"ExecutionCommandBuilder", "Build"}, {"CommandEmphasis", "Build"}, {"Store", "Publish"},
}) do instrument(pair[1], pair[2]) end
local copy = KWR.Util.Copy
local totalTables = 0
KWR.Util.Copy = function(self, value)
    if type(value) == "table" then
        totalTables = totalTables + 1
        local key = stack[#stack]
        if key then totals[key].tables = totals[key].tables + 1 end
    end
    return copy(self, value)
end
KWR.db.profile.preview = not liveWorkload
local started = clock()
for index = 1, 20 do
    tick, sampleTime = index, sampleTime + 1
    assert(KWR.MatchRuntime:ForceRefresh("manual"), "Profile refresh failed")
    if liveWorkload then
        assert(KWR.MatchRuntime:RefreshTactical("UNIT_SPELLCAST_START"), "Profile tactical refresh failed")
        local state, jobs = KWR.Store:Get(), {}
        for _, assignment in ipairs(state.assignments or {}) do
            jobs[#jobs + 1] = tostring(assignment.name) .. ":" .. tostring(assignment.role) .. ":" .. tostring(assignment.location)
        end
        table.sort(jobs)
        print("KWR_PROFILE_DECISION " .. index .. "|" .. tostring(state.snapshot.strategy.planID)
            .. "|" .. tostring(state.command.action) .. "|" .. table.concat(jobs, ";"))
    end
end
local elapsed = (clock() - started) * 1000
KWR.Util.Copy = copy
for _, row in ipairs(originals) do row[1][row[2]] = row[3] end
GetTime, KWR.Sensors.Capture = savedTime, savedCapture
local rows = {}
for key, row in pairs(totals) do row.key = key; rows[#rows + 1] = row end
table.sort(rows, function(a, b) return a.ms > b.ms end)
for _, row in ipairs(rows) do
    print(string.format("PROFILE %s calls=%d inclusiveMs=%.3f copiedTables=%d", row.key, row.calls, row.ms, row.tables))
end
print(string.format("KWR_RUNTIME_PROFILE_PASS refreshes=20 elapsedMs=%.3f copiedTables=%d scope=instrumented-host-%s", elapsed, totalTables, workload))
