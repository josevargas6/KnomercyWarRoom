local _, KWR = ...

local Planner = {}
KWR.TeamfightCommandPlanner = Planner

function Planner:Plan(snapshot)
    local factStore = KWR.FactStore:FromSnapshot(snapshot)
    local board = KWR.BoardState and KWR.BoardState:FromSnapshot(snapshot, factStore) or nil
    local localState = KWR.LocalTeamfightState:Build(factStore, snapshot, board)
    local problems = KWR.EnemyProblemDetector:Detect(localState)
    local assignments = KWR.AssignmentOptimizer:Optimize(localState, problems, snapshot)
    local killTarget = KWR.KillTargetSelector:Select(problems, assignments)
    local countdown = KWR.CountdownState:Build(5)
    local authoritative = snapshot
        and snapshot.context
        and snapshot.context.inPvP == true
        and snapshot.context.preview ~= true
    local displayEligible = false
    if authoritative then
        for _, problem in ipairs(problems or {}) do
            if problem.confidence == "CONFIRMED"
                or (problem.evidenceIDs and #problem.evidenceIDs > 0) then
                displayEligible = true
                break
            end
        end
    end
    local plan = {
        active = (#assignments > 0 or killTarget ~= nil),
        title = "LOCAL TEAMFIGHT CALL",
        assignments = assignments,
        killTarget = killTarget,
        countdown = countdown,
        problems = problems,
        boardRevision = board and board.revision,
        boardSummary = board and board.summary,
        optimizer = KWR.AssignmentOptimizer.lastSearch,
        confidence = (#assignments >= 2 and killTarget) and "HIGH"
            or (#assignments > 0 and "MEDIUM" or "UNKNOWN"),
        generatedAt = KWR.Util:Now(),
        authoritative = authoritative == true,
        displayEligible = displayEligible == true and (#assignments > 0 or killTarget ~= nil),
        compliance = {
            apiMode = KWR.ApiMode and KWR.ApiMode:Get() or "Retail_Current",
            targetAssist = "DISPLAY_ONLY",
            automation = "FORBIDDEN",
        },
    }
    for _, assignment in ipairs(assignments) do
        assignment.debugReasons = KWR.CommandReasonBuilder:ForAssignment(assignment)
    end
    if killTarget then
        killTarget.debugReasons = KWR.CommandReasonBuilder:ForAssignment({
            problemReasons = killTarget.reasons,
            reasons = { "+ killable target selected after support assignments" },
        })
    end
    plan.summary = KWR.CommandReasonBuilder:Summary(plan)
    if plan.displayEligible ~= true then
        plan.summary = "No local teamfight call."
    end
    return plan
end

KWR:RegisterModule("TeamfightCommandPlanner", Planner)