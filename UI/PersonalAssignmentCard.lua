local _, KWR = ...

local Card = {}
KWR.PersonalAssignmentCard = Card

function Card:Build(assignment)
    assignment = assignment or {}
    return {
        title = "YOUR JOB",
        job = KWR.CommandVocabulary:FormatAssignment(
            "You", assignment.verb or "Pressure", assignment.target or "target"),
        objective = assignment.objective or "Execute the assigned battlefield job.",
        targetStatus = assignment.targetStatus or "UNKNOWN",
        window = assignment.window or "When called",
        confidence = assignment.confidence or "UNKNOWN",
    }
end

KWR:RegisterModule("PersonalAssignmentCard", Card)