local _, KWR = ...

KWR.StrictFutureRuleset = {
    id = "Strict_Future",
    drResetSeconds = 18,
    slowTiers = { light = 30, heavy = 50, root = 100 },
    auraVisibility = "UNKNOWN_ONLY",
    targetAssist = "DISPLAY_ONLY",
    addonComms = false,
    confidence = { high = 85, medium = 65, low = 45 },
    decisionPolicy = {
        localTarget = { confidence = 85, maxAge = 2 },
        assignment = { confidence = 65, maxAge = 6 },
        command = { confidence = 85, maxAge = 4 },
    },
    assignmentLimits = { problems = 5, candidatesPerProblem = 3, searchNodes = 3000 },
    unknownState = "HOLD_OR_EXPLAIN",
    unknownPenalty = 22,
    objectiveWeightMode = "STRICT_UNKNOWN",
}

KWR:RegisterModule("StrictFutureRuleset", KWR.StrictFutureRuleset)