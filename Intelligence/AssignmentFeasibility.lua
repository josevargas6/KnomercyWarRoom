local _, KWR = ...

-- A single conservative gate for executable assignment proposals.  Scores may
-- rank feasible candidates; they must never turn missing route/coverage facts
-- into permission to issue a move.
local Feasibility = {}
KWR.AssignmentFeasibility = Feasibility

local function text(value)
    return KWR.Util:Text(value, "", 64)
end

local function outcome(state, reason, details)
    details = details or {}
    details.outcome = state
    details.reason = reason
    return details
end

local function assignmentIdentity(row)
    return KWR.Util:CanonicalPlayerKey(row and row.name, row and row.guid)
end

local function leavesMandatoryCoverage(player, snapshot, request)
    if request and request.allowObjectiveTrade == true then return false end
    local from = text(player and (player.location or player.assignmentLocation))
    local to = text(request and request.targetLocation)
    if from == "" or from == to then return false end
    local controlled = false
    for _, objective in ipairs(snapshot and snapshot.objectives and snapshot.objectives.rows or {}) do
        if objective.owner == "FRIENDLY" and objective.label == from then
            controlled = true
            break
        end
    end
    if not controlled then return false end

    local actorID = assignmentIdentity(player)
    local remaining = 0
    for _, assignment in ipairs(snapshot and snapshot.assignments or {}) do
        if assignment.location == from and assignment.dead ~= true and assignment.connected ~= false
            and assignmentIdentity(assignment) ~= actorID then
            remaining = remaining + 1
        end
    end
    return remaining < (KWR.Util:Number(request and request.minimumRemainingCoverage, 1) or 1)
end

-- request.deadlineSeconds is a duration relative to this evaluation.  Callers
-- that only know a display ETA must not populate it.  A route estimate is
-- deliberately widened: it is modeled travel, not a navigation guarantee.
function Feasibility:Evaluate(player, request, snapshot)
    request = request or {}
    if not player or player.dead == true or player.connected == false then
        return outcome("FORBIDDEN", "ACTOR_UNAVAILABLE")
    end
    if leavesMandatoryCoverage(player, snapshot, request) then
        return outcome("FORBIDDEN", "MANDATORY_COVERAGE", { from = player.location })
    end

    local target = text(request.targetLocation or request.location or request.objectiveLocation)
    if target == "" then
        return outcome("ALLOWED", "NO_ROUTE_OBLIGATION")
    end
    local from = text(player.location)
    if from == target then
        return outcome("ALLOWED", "ALREADY_ON_STATION", {
            from = from, target = target, earliestArrival = 0, latestArrival = 0,
        })
    end
    if from == "" or from == "Unknown" or from == "Position restricted" then
        return outcome("UNKNOWN", "ACTOR_LOCATION_UNKNOWN", { target = target })
    end
    local capability = KWR.Capabilities:Resolve(player.classFile, player.spec) or {}
    local route = KWR.Maps:TravelEstimate(snapshot and snapshot.context and snapshot.context.mapKey,
        from, target, {
            mobility = capability.ratings and capability.ratings.mobility or 2,
            inCombat = player.inCombat == true,
            observed = player.locationSource == "Friendly Map Position",
        })
    if not route or not route.seconds then
        return outcome("UNKNOWN", "ROUTE_UNAVAILABLE", { from = from, target = target })
    end
    local seconds = KWR.Util:Number(route.seconds, nil)
    if not seconds or seconds < 0 then
        return outcome("UNKNOWN", "ROUTE_INVALID", { from = from, target = target })
    end
    local earliest = KWR.Util:Number(route.earliestSeconds, nil)
        or math.max(0, math.floor(seconds * 0.8))
    local latest = KWR.Util:Number(route.latestSeconds, nil)
        or math.ceil(seconds * 1.25)
    if earliest < 0 or latest < earliest then
        return outcome("UNKNOWN", "ROUTE_INTERVAL_INVALID", { from = from, target = target })
    end
    local observedAt = KWR.Util:Number(player.observedAt or player.lastSeenAt, nil)
    local evidenceAge = observedAt and math.max(0, KWR.Util:Now() - observedAt) or nil
    local details = {
        from = from,
        target = target,
        routeID = table.concat({ snapshot and snapshot.context and snapshot.context.mapKey or "UNKNOWN", from, target }, ":"),
        routeSource = route.source or "MAP_ROUTE_ESTIMATE",
        routeBasis = route.basis or "MODELED",
        routeRevision = route.revision or "UNVERSIONED",
        routeConstraints = route.constraints,
        routeConfidence = route.confidence or "LOW",
        evidenceAgeSeconds = evidenceAge,
        earliestArrival = earliest,
        latestArrival = latest,
        interactionSeconds = KWR.Util:Number(request.interactionSeconds, 0) or 0,
        safetyMarginSeconds = KWR.Util:Number(request.safetyMarginSeconds, 0) or 0,
    }
    local deadline = KWR.Util:Number(request.deadlineSeconds, nil)
    if deadline then
        details.deadlineSeconds = deadline
        details.guaranteed = latest + details.interactionSeconds + details.safetyMarginSeconds <= deadline
        if not details.guaranteed then
            return outcome("FORBIDDEN", "DEADLINE_MISSED", details)
        end
    end
    return outcome("ALLOWED", "ROUTE_FEASIBLE", details)
end

KWR:RegisterModule("AssignmentFeasibility", Feasibility)
