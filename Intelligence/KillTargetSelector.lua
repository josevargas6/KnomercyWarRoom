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

local function observedKillEligible(problem)
    local enemy = problem and problem.enemy or {}
    local intent = KWR.Util:Text(enemy.targetIntent
        or (enemy.combat and enemy.combat.targetIntent), "", 32)
    if enemy.killable ~= true and not (enemy.combat and enemy.combat.killable == true) then
        return false
    end
    return intent == "" or intent == "NONE" or intent == "OBSERVED_KILL_WINDOW"
end

local function confidenceFromEvidence(problem)
    local confidence = KWR.Util:Text(problem and problem.confidence, "UNKNOWN", 24)
    if confidence == "CONFIRMED" then return "HIGH" end
    if confidence == "HIGH" or confidence == "MEDIUM" or confidence == "LOW" then
        return confidence
    end
    return "LOW"
end

function Selector:Select(problems, assignments)
    local best
    local coverage = controlCoverage(assignments)
    for _, problem in ipairs(problems or {}) do
        if problem.verb == "Kill" and observedKillEligible(problem)
            and (not best or (problem.severity or 0) > (best.severity or 0)) then
            best = problem
        end
    end
    if not best then return nil end
    local score = (best.severity or 0) + (coverage * 8)
    return {
        actor = "Team",
        verb = "Kill",
        target = label(best.enemy),
        targetGUID = best.enemy and best.enemy.guid,
        score = score,
        confidence = confidenceFromEvidence(best),
        window = "ON LEADER CALL",
        objective = "Convert the observed kill window after support is subdued.",
        reasons = KWR.Util:Copy(best.reasons or {}),
        supportCoverage = coverage,
    }
end

KWR:RegisterModule("KillTargetSelector", Selector)
