return function(KWR)
    local snapshot = {
        context = { mapKey = "ARATHI" },
        objectives = { rows = { { label = "Farm", owner = "FRIENDLY" } } },
        assignments = {
            { name = "Anchor-Realm", guid = "Anchor", location = "Farm", connected = true, dead = false },
        },
    }
    local actor = { name = "Anchor-Realm", guid = "Anchor", location = "Farm",
        connected = true, dead = false, classFile = "ROGUE", spec = "Subtlety",
        locationSource = "Friendly Map Position" }
    local blocked = KWR.AssignmentFeasibility:Evaluate(actor, {
        targetLocation = "Lumber Mill", minimumRemainingCoverage = 1,
    }, snapshot)
    assert(blocked.outcome == "FORBIDDEN" and blocked.reason == "MANDATORY_COVERAGE",
        "A sole defender was allowed to abandon mandatory objective coverage")
    local traded = KWR.AssignmentFeasibility:Evaluate(actor, {
        targetLocation = "Lumber Mill", allowObjectiveTrade = true,
    }, snapshot)
    assert(traded.outcome == "ALLOWED" and traded.latestArrival >= traded.earliestArrival,
        "An explicit objective trade did not retain a feasible route interval")
    local deadlinePass = KWR.AssignmentFeasibility:Evaluate({
        name = "Mover-Realm", guid = "Mover", location = "Farm", connected = true, dead = false,
        classFile = "ROGUE", spec = "Subtlety", locationSource = "Friendly Map Position",
    }, { targetLocation = "Farm", deadlineSeconds = 0, interactionSeconds = 0, safetyMarginSeconds = 0 }, {
        context = { mapKey = "ARATHI" },
    })
    assert(deadlinePass.outcome == "ALLOWED", "On-station actor failed the zero deadline boundary")
    local deadlineFail = KWR.AssignmentFeasibility:Evaluate({
        name = "Late-Realm", guid = "Late", location = "Farm", connected = true, dead = false,
        classFile = "ROGUE", spec = "Subtlety", locationSource = "Friendly Map Position",
    }, { targetLocation = "Lumber Mill", deadlineSeconds = 1, interactionSeconds = 2, safetyMarginSeconds = 1 }, {
        context = { mapKey = "ARATHI" },
    })
    assert(deadlineFail.outcome == "FORBIDDEN" and deadlineFail.reason == "DEADLINE_MISSED",
        "Late modeled travel was not rejected at the guaranteed deadline boundary")
    local originalTravel = KWR.Maps.TravelEstimate
    KWR.Maps.TravelEstimate = function()
        return { seconds = 7, earliestSeconds = 6, latestSeconds = 8,
            source = "FIXTURE_ROUTE", basis = "REVIEWED_FIXTURE", revision = "fixture-r1" }
    end
    local intervalPass = KWR.AssignmentFeasibility:Evaluate(actor, {
        targetLocation = "Lumber Mill", allowObjectiveTrade = true,
        deadlineSeconds = 12, interactionSeconds = 2, safetyMarginSeconds = 1,
    }, snapshot)
    assert(intervalPass.outcome == "ALLOWED" and intervalPass.earliestArrival == 6
        and intervalPass.latestArrival == 8 and intervalPass.routeBasis == "REVIEWED_FIXTURE",
        "Reviewed route interval did not survive the feasibility projection")
    KWR.Maps.TravelEstimate = function()
        return { seconds = 8, earliestSeconds = 6, latestSeconds = 10,
            source = "FIXTURE_ROUTE", basis = "REVIEWED_FIXTURE", revision = "fixture-r1" }
    end
    local intervalFail = KWR.AssignmentFeasibility:Evaluate(actor, {
        targetLocation = "Lumber Mill", allowObjectiveTrade = true,
        deadlineSeconds = 12, interactionSeconds = 2, safetyMarginSeconds = 1,
    }, snapshot)
    KWR.Maps.TravelEstimate = originalTravel
    assert(intervalFail.outcome == "FORBIDDEN" and intervalFail.reason == "DEADLINE_MISSED",
        "Conservative route interval did not reject the 10-second latest arrival")
    local unknown = KWR.AssignmentFeasibility:Evaluate({
        name = "Unknown-Realm", guid = "Unknown", connected = true, dead = false,
    }, { targetLocation = "Lumber Mill" }, { context = { mapKey = "ARATHI" } })
    assert(unknown.outcome == "UNKNOWN" and unknown.reason == "ACTOR_LOCATION_UNKNOWN",
        "Unknown location was upgraded to a feasible movement order")
    local problem = { type = "LOCAL_HEALER_CONTROL", verb = "Subdue", severity = 100,
        confidence = "CONFIRMED", targetLocation = "Lumber Mill", deadlineSeconds = 1,
        enemy = { name = "Enemy", guid = "Enemy-1", role = "HEALER" } }
    local assignments = KWR.AssignmentOptimizer:Optimize({ friendlies = {
        { name = "Late-Realm", guid = "Late", location = "Farm", connected = true, dead = false,
            classFile = "ROGUE", spec = "Subtlety", locationSource = "Friendly Map Position" },
    } }, { problem }, { context = { mapKey = "ARATHI" } })
    assert(#assignments == 0 and #(KWR.AssignmentOptimizer.lastSearch.rejected or {}) == 1,
        "Optimizer scored a route-forbidden actor into an executable control assignment")

    local collectiveSnapshot = {
        context = { mapKey = "ARATHI" },
        objectives = { rows = { { label = "Farm", owner = "FRIENDLY" } } },
        assignments = {
            { name = "One-Realm", guid = "One", location = "Farm", connected = true },
            { name = "Two-Realm", guid = "Two", location = "Farm", connected = true },
        },
    }
    local twoProblems = {
        { type = "LOCAL_HEALER_CONTROL", verb = "Subdue", severity = 100, confidence = "CONFIRMED",
            targetLocation = "Lumber Mill", enemy = { name = "EnemyA", guid = "Enemy-A" } },
        { type = "LOCAL_HEALER_CONTROL", verb = "Subdue", severity = 99, confidence = "CONFIRMED",
            targetLocation = "Lumber Mill", enemy = { name = "EnemyB", guid = "Enemy-B" } },
    }
    local collective = KWR.AssignmentOptimizer:Optimize({ friendlies = {
        { name = "One-Realm", guid = "One", location = "Farm", connected = true, classFile = "ROGUE", spec = "Subtlety" },
        { name = "Two-Realm", guid = "Two", location = "Farm", connected = true, classFile = "ROGUE", spec = "Subtlety" },
    } }, twoProblems, collectiveSnapshot)
    assert(#collective <= 1, "Optimizer returned a collectively uncovered mandatory objective")
end
