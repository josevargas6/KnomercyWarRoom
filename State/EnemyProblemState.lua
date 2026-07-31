local _, KWR = ...

local EnemyProblemState = {}
KWR.EnemyProblemState = EnemyProblemState

function EnemyProblemState:New(problem)
    problem = problem or {}
    problem.confidence = problem.confidence or "UNKNOWN"
    problem.reasons = problem.reasons or {}
    problem.suppressionReasons = problem.suppressionReasons or {}
    problem.requiredJobs = problem.requiredJobs or {}
    problem.evidenceIDs = problem.evidenceIDs or {}
    problem.createdAt = problem.createdAt or KWR.Util:Now()
    problem.expiresAt = problem.expiresAt or (problem.createdAt + 8)
    local row = KWR.CounterplayMatrix and KWR.CounterplayMatrix:Resolve(problem.type)
    problem.verb = KWR.CommandVocabulary:NormalizeVerb(problem.verb or (row and row.verbs and row.verbs[1]), "Pressure")
    problem.objective = problem.objective or (row and row.objective)
    return problem
end

KWR:RegisterModule("EnemyProblemState", EnemyProblemState)