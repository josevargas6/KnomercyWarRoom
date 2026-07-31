local _, KWR = ...

local Selector = {}
KWR.KillTargetSelector = Selector

local function label(enemy)
    return KWR.Util:Text(enemy and (enemy.shortName or enemy.name), "target", 64)
end

local function isSupportControl(assignment)
    return assignment and (assignment.verb == "Subdue"
        or assignment.verb == "Disrupt"
        or assignment.verb == "Deny")
end

local function controlCoverage(assignments)
    local coverage = 0
    for _, assignment in ipairs(assignments or {}) do
        if isSupportControl(assignment) then
            coverage = coverage + 1
        end
    end
    return coverage
end

function Selector:Select(problems, assignments)
    local best
    local coverage = controlCoverage(assignments)
    for _, problem in ipairs(problems or {}) do
        if problem.verb == "Kill" and (not best or (problem.severity or 0) > (best.severity or 0)) then
            best = problem
        end
    end
    if not best then return nil end
    local score = (best.severity or 0) + (coverage * 8)
    local confidence = best.confidence == "CONFIRMED" and "HIGH" or "MEDIUM"
    if coverage == 0 and best.confidence ~= "CONFIRMED" then
        confidence = "LOW"
    end
    return {
        actor = "Team",
        verb = "Kill",
        target = label(best.enemy),
        targetGUID = best.enemy and best.enemy.guid,
        score = score,
        confidence = confidence,
        window = "Go in 5",
        objective = "Convert kill pressure after support is subdued.",
        reasons = KWR.Util:Copy(best.reasons or {}),
        supportCoverage = coverage,
    }
end

KWR:RegisterModule("KillTargetSelector", Selector)