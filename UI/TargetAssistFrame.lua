local _, KWR = ...

local TargetAssist = {}
KWR.TargetAssistFrame = TargetAssist

function TargetAssist:Build(assignment)
    return {
        target = assignment and assignment.target or "UNKNOWN",
        status = assignment and assignment.targetStatus or "UNKNOWN",
        message = assignment and assignment.targetStatus == "MATCHED"
            and "Target match confirmed." or "Select the assigned target.",
    }
end

KWR:RegisterModule("TargetAssistFrame", TargetAssist)