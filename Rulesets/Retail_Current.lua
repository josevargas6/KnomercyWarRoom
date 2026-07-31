local _, KWR = ...

KWR.RetailCurrentRuleset = {
    id = "Retail_Current",
    drResetSeconds = 18,
    slowTiers = { light = 30, heavy = 50, root = 100 },
    auraVisibility = "SAFE_ADAPTER_ONLY",
    targetAssist = "DISPLAY_ONLY",
    addonComms = false,
    confidence = { high = 80, medium = 55, low = 35 },
    decisionPolicy = {
        localTarget = { confidence = 80, maxAge = 2 },
        assignment = { confidence = 55, maxAge = 8 },
        command = { confidence = 80, maxAge = 5 },
    },
    assignmentLimits = { problems = 6, candidatesPerProblem = 4, searchNodes = 5000 },
    unknownState = "PENALIZE_AND_EXPLAIN",
    unknownPenalty = 12,
    objectiveWeightMode = "CURRENT_RETAIL",
}

KWR:RegisterModule("RetailCurrentRuleset", KWR.RetailCurrentRuleset)