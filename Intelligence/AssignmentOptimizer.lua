local _, KWR = ...

local Optimizer = {}
KWR.AssignmentOptimizer = Optimizer

local MAX_PROBLEMS = 6
local MAX_CANDIDATES_PER_PROBLEM = 4
local MAX_NODES = 5000

local function limits()
    local ruleset = KWR.ComplianceGate and KWR.ComplianceGate:Ruleset() or {}
    local row = ruleset.assignmentLimits or {}
    return {
        problems = KWR.Util:Number(row.problems, MAX_PROBLEMS) or MAX_PROBLEMS,
        candidatesPerProblem = KWR.Util:Number(row.candidatesPerProblem, MAX_CANDIDATES_PER_PROBLEM)
            or MAX_CANDIDATES_PER_PROBLEM,
        searchNodes = KWR.Util:Number(row.searchNodes, MAX_NODES) or MAX_NODES,
    }
end

local function label(unit)
    return KWR.Util:Text(unit and (unit.shortName or unit.name), "target", 64)
end

local function confidenceFor(score)
    if score >= 175 then return "HIGH" end
    if score >= 130 then return "MEDIUM" end
    return "LOW"
end

local function isKillProblem(problem)
    return problem and (problem.verb == "Kill"
        or problem.type == "KILL_TARGET_AVAILABLE"
        or problem.type == "KILLABLE_OVEREXTENDED"
        or problem.type == "OBJECTIVE_CARRIER_EXPOSED")
end

local function confidencePenalty(problem)
    if not problem then return 0 end
    if problem.confidence == "UNKNOWN" then return 18 end
    if problem.confidence == "INFERRED" then return 7 end
    return 0
end

local function buildAssignment(candidate)
    local problem = candidate.problem
    return KWR.AssignmentState:Build({
        actor = label(candidate.player),
        actorGUID = candidate.player.guid,
        verb = KWR.CommandVocabulary:NormalizeVerb(problem.verb, "Subdue"),
        target = label(problem.enemy),
        targetGUID = problem.enemy and problem.enemy.guid,
        targetStatus = KWR.PlayerTargetState:Match(candidate.player, problem.enemy),
        problemType = problem.type,
        score = math.floor(candidate.score + 0.5),
        confidence = confidenceFor(candidate.score),
        window = "Go in 5",
        objective = problem.objective or (KWR.CounterplayMatrix
            and KWR.CounterplayMatrix:Objective(problem.type))
            or "Create value during the kill window.",
        reasons = candidate.reasons,
        problemReasons = problem.reasons,
        evidenceIDs = problem.evidenceIDs,
        drState = problem.drState,
        localState = problem.localState,
    })
end

function Optimizer:Optimize(localState, problems, snapshot)
    local ruleLimits = limits()
    local problemRows = {}
    for _, problem in ipairs(problems or {}) do
        if not isKillProblem(problem) then
            problemRows[#problemRows + 1] = problem
            if #problemRows >= ruleLimits.problems then break end
        end
    end

    local candidateSets = {}
    for _, problem in ipairs(problemRows) do
        local set = {}
        for _, player in ipairs(localState and localState.friendlies or {}) do
            local friendly = KWR.FriendlyRoleState:Build(player)
            local score, reasons = KWR.AssignmentScorer:Score(friendly, problem, snapshot)
            score = score - confidencePenalty(problem)
            set[#set + 1] = {
                player = player,
                friendly = friendly,
                problem = problem,
                score = score,
                reasons = reasons,
            }
        end
        table.sort(set, function(a, b)
            if a.score == b.score then
                return label(a.player) < label(b.player)
            end
            return a.score > b.score
        end)
        local trimmed = {}
        for index = 1, math.min(#set, ruleLimits.candidatesPerProblem) do
            trimmed[#trimmed + 1] = set[index]
        end
        candidateSets[#candidateSets + 1] = trimmed
    end

    local bestScore, bestSet, nodeCount = -1000000, {}, 0
    local function search(index, usedPlayers, selected, score)
        nodeCount = nodeCount + 1
        if nodeCount > ruleLimits.searchNodes then return end
        if index > #candidateSets then
            if score > bestScore then
                bestScore = score
                bestSet = KWR.Util:Copy(selected)
            end
            return
        end

        search(index + 1, usedPlayers, selected, score)

        for _, candidate in ipairs(candidateSets[index]) do
            local playerKey = candidate.player.guid or candidate.player.name
            if playerKey and not usedPlayers[playerKey] and candidate.score > 0 then
                usedPlayers[playerKey] = true
                selected[#selected + 1] = candidate
                search(index + 1, usedPlayers, selected, score + candidate.score)
                selected[#selected] = nil
                usedPlayers[playerKey] = nil
            end
        end
    end

    search(1, {}, {}, 0)

    table.sort(bestSet, function(a, b)
        if (a.problem.severity or 0) == (b.problem.severity or 0) then
            return label(a.player) < label(b.player)
        end
        return (a.problem.severity or 0) > (b.problem.severity or 0)
    end)

    local assignments = {}
    for _, candidate in ipairs(bestSet) do
        assignments[#assignments + 1] = buildAssignment(candidate)
    end
    self.lastSearch = {
        nodes = nodeCount,
        score = bestScore,
        problems = #problemRows,
        limit = ruleLimits.searchNodes,
    }
    return assignments
end

KWR:RegisterModule("AssignmentOptimizer", Optimizer)