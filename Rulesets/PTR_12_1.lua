local _, KWR = ...

KWR.PTR121Ruleset = {
    id = "PTR_12_1",
    drResetSeconds = 18,
    slowTiers = { light = 30, heavy = 50, root = 100 },
    auraVisibility = "REDUCED",
    targetAssist = "DISPLAY_ONLY",
    addonComms = false,
    confidence = { high = 82, medium = 58, low = 38 },
    decisionPolicy = {
        localTarget = { confidence = 82, maxAge = 2 },
        assignment = { confidence = 58, maxAge = 7 },
        command = { confidence = 82, maxAge = 5 },
    },
    assignmentLimits = { problems = 6, candidatesPerProblem = 4, searchNodes = 5000 },
    unknownState = "PENALIZE_AND_EXPLAIN",
    unknownPenalty = 16,
    objectiveWeightMode = "PTR_RESTRICTED",
}

KWR:RegisterModule("PTR121Ruleset", KWR.PTR121Ruleset)