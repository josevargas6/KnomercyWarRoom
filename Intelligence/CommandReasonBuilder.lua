local _, KWR = ...

local Builder = {}
KWR.CommandReasonBuilder = Builder

function Builder:ForAssignment(assignment)
    local reasons = {}
    for _, reason in ipairs(assignment.problemReasons or {}) do
        reasons[#reasons + 1] = "+ " .. reason
    end
    for _, reason in ipairs(assignment.reasons or {}) do
        reasons[#reasons + 1] = reason
    end
    if assignment.drState then
        reasons[#reasons + 1] = "+ DR state: " .. KWR.Util:Text(assignment.drState.state, "UNKNOWN", 24)
            .. " (" .. KWR.Util:Text(assignment.drState.confidence, "UNKNOWN", 16) .. ")"
    end
    if not assignment.drState or assignment.drState.state == "UNKNOWN" then
        reasons[#reasons + 1] = "- enemy defensive state unknown"
    end
    return reasons
end

function Builder:Summary(plan)
    local parts = {}
    for _, assignment in ipairs(plan and plan.assignments or {}) do
        parts[#parts + 1] = KWR.CommandVocabulary:FormatAssignment(
            assignment.actor, assignment.verb, assignment.target)
    end
    if plan and plan.killTarget then
        parts[#parts + 1] = KWR.CommandVocabulary:FormatAssignment(
            "Team", "Kill", plan.killTarget.target) .. " in 5"
    end
    return table.concat(parts, " | ")
end

KWR:RegisterModule("CommandReasonBuilder", Builder)