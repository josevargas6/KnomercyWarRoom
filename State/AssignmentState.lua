local _, KWR = ...

local AssignmentState = {}
KWR.AssignmentState = AssignmentState

function AssignmentState:Build(row)
    row = row or {}
    row.confidence = row.confidence or "UNKNOWN"
    row.targetStatus = row.targetStatus or "UNKNOWN"
    return row
end

KWR:RegisterModule("AssignmentState", AssignmentState)