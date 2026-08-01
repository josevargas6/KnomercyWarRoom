local _, KWR = ...

local ScenarioFixtures = {}
KWR.ScenarioFixtures = ScenarioFixtures

local function push(rows, mapKey, fixtureClass, expectedBranch, state)
    rows[#rows + 1] = {
        id = mapKey .. "_" .. fixtureClass .. "_" .. tostring(#rows + 1),
        mapKey = mapKey,
        fixtureClass = fixtureClass,
        expectedBranch = expectedBranch,
        state = state,
        deterministic = true,
        reviewStatus = "SCENARIO_VALIDATED",
    }
end

local function build()
    local rows = {}
    for mapKey in pairs(KWR.Maps:All()) do
        push(rows, mapKey, "OPENER", mapKey .. "_OPEN_ANTI_BUNKER", {
            phase = "OPENING",
            enemyComposition = "BUNKER",
        })
        push(rows, mapKey, "OPENER", mapKey .. "_OPEN_ANTI_SPLIT", {
            phase = "OPENING",
            enemyComposition = "ROTATION",
        })
        push(rows, mapKey, "RECOVERY", mapKey .. "_REC_ABANDON", {
            phase = "RECOVERY",
            arrivalAfterResolution = true,
        })
        push(rows, mapKey, "RECOVERY", mapKey .. "_REC_REINFORCE", {
            phase = "RECOVERY",
            objectiveContestable = true,
            waveAdvantage = true,
            anchorsStable = true,
        })
        push(rows, mapKey, "ENDGAME", mapKey .. "_END_PROTECT", {
            phase = "ENDGAME",
            projectedWin = true,
        })
    end
    table.sort(rows, function(a, b) return a.id < b.id end)
    return rows
end

function ScenarioFixtures:All()
    return build()
end

function ScenarioFixtures:Count(mapKey)
    if not mapKey then return #build() end
    local count = 0
    for _, row in ipairs(build()) do
        if row.mapKey == mapKey then count = count + 1 end
    end
    return count
end

KWR:RegisterModule("ScenarioFixtures", ScenarioFixtures)
