return function(KWR)
    local active = false
    local function equal(left, right)
        if type(left) ~= type(right) then return false end
        if type(left) ~= "table" then return left == right end
        for key, value in pairs(left) do
            if not equal(value, right[key]) then return false end
        end
        for key in pairs(right) do
            if left[key] == nil then return false end
        end
        return true
    end
    local function loadModule(name, reverse)
        local seen = {}
        local environment = setmetatable({}, { __index = _G })
        environment.pairs = function(rows)
            local keys = {}
            for key, row in pairs(rows) do
                keys[#keys + 1] = key
                if type(row) == "table" and row.scenarioId and row.mapKey and row.phase then
                    seen[row.scenarioId] = { mapKey = row.mapKey, phase = row.phase }
                end
            end
            table.sort(keys, function(left, right)
                if reverse then return tostring(left) > tostring(right) end
                return tostring(left) < tostring(right)
            end)
            local index = 0
            return function()
                index = index + 1
                local key = keys[index]
                if key ~= nil then return key, rows[key] end
            end
        end
        local namespace = {
            Util = KWR.Util,
            RegisterModule = function() end,
            PatchData = {
                SeasonPrepCorpusActive = function() return active end,
                SeasonPrepCorpusMode = function() return active and "FIELD" or "DISABLED" end,
            },
        }
        local chunk = assert(loadfile(ResolveAddonPath("Data/" .. name .. ".lua"), "t", environment))
        if setfenv then setfenv(chunk, environment) end
        chunk("KnomercyWarRoom", namespace)
        return namespace[name], seen
    end
    local modules = { "ScenarioCalibration", "ScenarioAdversarialCalibration", "ScenarioExpertCorpus" }
    for _, name in ipairs(modules) do
        active = false
        local forward, scenarios = loadModule(name, false)
        local reverse = loadModule(name, true)
        assert(forward:Count() >= 200 and forward:Count() == reverse:Count(), name .. " scenario count")
        local mapPhases, minimumIDs = {}, {}
        local count = 0
        for id, location in pairs(scenarios) do
            count = count + 1
            local key = location.mapKey .. ":" .. location.phase
            mapPhases[key] = location
            if not minimumIDs[key] or id < minimumIDs[key] then minimumIDs[key] = id end
            local row, summary = forward:Get(id), forward:GetSummary(id)
            assert(row and summary and summary.scenarioId == id, name .. " direct lookup " .. id)
            assert(equal(row, reverse:Get(id)) and equal(summary, reverse:GetSummary(id)), name .. " direct data parity")
            row.scenarioId, summary.scenarioId = "mutated", "mutated"
            assert(forward:Get(id).scenarioId == id and forward:GetSummary(id).scenarioId == id, name .. " copy isolation")
        end
        assert(count == forward:Count(), name .. " traversed complete corpus")
        for _, enabled in ipairs({ false, true, false }) do
            active = enabled
            for key, location in pairs(mapPhases) do
                local full = forward:GetByMapAndPhase(location.mapKey, location.phase)
                local summary = forward:GetSummaryByMapAndPhase(location.mapKey, location.phase)
                -- Start with the summary API in the reverse module, exercising
                -- either entry point as the lazy index builder.
                local reversedSummary = reverse:GetSummaryByMapAndPhase(location.mapKey, location.phase)
                local reversedFull = reverse:GetByMapAndPhase(location.mapKey, location.phase)
                assert(equal(full, reversedFull) and equal(summary, reversedSummary), name .. " traversal independence " .. key)
                assert((full == nil) == (summary == nil), name .. " fallback availability parity")
                if full then
                    assert(full.scenarioId == summary.scenarioId, name .. " full/compact identity " .. key)
                    if name ~= "ScenarioExpertCorpus" then
                        assert(full.scenarioId == minimumIDs[key], name .. " stable ID tie break " .. key)
                    elseif not active then
                        assert(full.seasonStatus ~= "ACTIVE_THEORY_FIELD" and full.reviewConfidence == "HIGH", "Expert inactive eligibility")
                    end
                    local before = forward:GetSummaryByMapAndPhase(location.mapKey, location.phase)
                    if type(summary.mustStay) == "table" then summary.mustStay[1] = "mutated" end
                    if type(summary.requiredCapabilities) == "table" then summary.requiredCapabilities[1] = "mutated" end
                    assert(equal(before, forward:GetSummaryByMapAndPhase(location.mapKey, location.phase)), name .. " nested summary isolation")
                end
                local map = forward:GetMapSummary(location.mapKey)
                local phase = forward:GetMapPhaseSummary(location.mapKey, location.phase)
                assert(map and phase and equal(map, reverse:GetMapSummary(location.mapKey)), name .. " map metadata retained")
                assert(equal(phase, reverse:GetMapPhaseSummary(location.mapKey, location.phase)), name .. " phase metadata retained")
                map.fixtureMutation, phase.fixtureMutation = true, true
                assert(not forward:GetMapSummary(location.mapKey).fixtureMutation, name .. " map copy isolation")
                assert(not forward:GetMapPhaseSummary(location.mapKey, location.phase).fixtureMutation, name .. " phase copy isolation")
            end
            if name == "ScenarioExpertCorpus" then
                local row = forward:Get("arathi-season-prep-opening-01")
                assert(row.seasonStatus == (active and "ACTIVE_THEORY_FIELD" or "PENDING_SEASON_REVIEW"), "Expert direct season status")
                local fallback = forward:GetByMapAndPhase("ARATHI", "OPENING")
                if active then
                    assert(fallback and fallback.seasonStatus == "ACTIVE_THEORY_FIELD", "Expert season-prep priority")
                    assert(fallback.evidenceStatus == "THEORY_AWAITING_FIELD_FEEDBACK", "Expert theory remains labeled")
                end
            end
        end
        assert(forward:Get("missing-id") == nil and forward:GetSummary("missing-id") == nil, name .. " unknown ID")
        assert(forward:GetByMapAndPhase("missing-map", "OPENING") == nil, name .. " unknown map")
        assert(forward:GetSummaryByMapAndPhase("WSG", "missing-phase") == nil, name .. " unknown phase")
        assert(forward:GetByMapAndPhase(nil, nil) == nil, name .. " absent map/phase")
    end
end
