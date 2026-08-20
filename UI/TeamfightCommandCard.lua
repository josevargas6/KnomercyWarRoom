local _, KWR = ...

local Card = {}
KWR.TeamfightCommandCard = Card

function Card:Build(plan)
    local lines = { KWR.Util:Text(plan and plan.title, "LOCAL TEAMFIGHT CALL", 48) }
    for _, assignment in ipairs(plan and plan.assignments or {}) do
        lines[#lines + 1] = KWR.CommandVocabulary:FormatAssignment(
            assignment.actor, assignment.verb, assignment.target)
    end
    if plan and plan.killTarget then
        lines[#lines + 1] = KWR.CommandVocabulary:FormatAssignment(
            "Team", "Kill", plan.killTarget.target) .. " in 5"
    end
    return {
        lines = lines,
        confidence = plan and plan.confidence or "UNKNOWN",
        countdown = plan and plan.countdown,
        unknownSafe = true,
        scope = "LOCAL_TEAMFIGHT",
        activeCallAuthority = false,
    }
end

KWR:RegisterModule("TeamfightCommandCard", Card)
