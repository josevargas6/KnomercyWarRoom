local _, KWR = ...

local Panel = {}
KWR.DebugReasonPanel = Panel

function Panel:Build(plan)
    local rows = {}
    for _, assignment in ipairs(plan and plan.assignments or {}) do
        rows[#rows + 1] = {
            command = KWR.CommandVocabulary:FormatAssignment(
                assignment.actor, assignment.verb, assignment.target),
            score = assignment.score or 0,
            reasons = assignment.debugReasons or {},
        }
    end
    if plan and plan.killTarget then
        rows[#rows + 1] = {
            command = KWR.CommandVocabulary:FormatAssignment(
                "Team", "Kill", plan.killTarget.target),
            score = plan.killTarget.score or 0,
            reasons = plan.killTarget.debugReasons or {},
        }
    end
    return rows
end

KWR:RegisterModule("DebugReasonPanel", Panel)