local _, KWR = ...

local CompThreats = {}
KWR.CompThreats = CompThreats

local THREATS = {
    DEATHBALL_CLEAVE = {
        id = "DEATHBALL_CLEAVE",
        wants = { "compact teamfight" },
        avoids = { "wide split pressure" },
        preferredResponses = { "spread before contact", "trade weak side" },
        counterWindow = "after enemy commitment",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    DURABLE_ATTRITION = {
        id = "DURABLE_ATTRITION",
        wants = { "extended objective fight" },
        avoids = { "rapid swaps" },
        preferredResponses = { "force movement", "avoid neutral brawl" },
        counterWindow = "after enemy cooldown overlap",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    RANGED_CONTROL = {
        id = "RANGED_CONTROL",
        wants = { "established firing line" },
        avoids = { "multi-angle collapse" },
        preferredResponses = { "use terrain", "force rotation" },
        counterWindow = "after line setup is broken",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    DOUBLE_STEALTH_ASSAULT = {
        id = "DOUBLE_STEALTH_ASSAULT",
        wants = { "isolated defender" },
        avoids = { "paired defense" },
        preferredResponses = { "two-layer coverage", "track reveal timing" },
        counterWindow = "after stealth reveal",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    HIGH_MOBILITY_SPLIT = {
        id = "HIGH_MOBILITY_SPLIT",
        wants = { "simultaneous weak lanes" },
        avoids = { "compact bunker" },
        preferredResponses = { "shorten rotations", "punish over-rotation" },
        counterWindow = "after reserve commits",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    CARRIER_ESCORT = {
        id = "CARRIER_ESCORT",
        wants = { "protected carrier route" },
        avoids = { "escort-first control" },
        preferredResponses = { "kill escorts first", "deny exits" },
        counterWindow = "after escort cooldowns overlap",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    BUNKER_DEFENSE = {
        id = "BUNKER_DEFENSE",
        wants = { "front-door assault" },
        avoids = { "cross-map trade" },
        preferredResponses = { "force float reveal", "abort slow assault" },
        counterWindow = "after bunker support leaves",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    KNOCKBACK_CONTROL = {
        id = "KNOCKBACK_CONTROL",
        wants = { "terrain edge contact" },
        avoids = { "wide spacing" },
        preferredResponses = { "safe-side approach", "track displacement" },
        counterWindow = "after knockback commits",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    HEALER_ASSASSINATION = {
        id = "HEALER_ASSASSINATION",
        wants = { "stationary healer exposure" },
        avoids = { "mobile peel shell" },
        preferredResponses = { "pre-position peel", "counterkill overextension" },
        counterWindow = "after opener dive",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    OBJECTIVE_TRADE = {
        id = "OBJECTIVE_TRADE",
        wants = { "predictable reinforcement" },
        avoids = { "retained reserve" },
        preferredResponses = { "protect mathematical minimum", "confirm commitment" },
        counterWindow = "after enemy commit is confirmed",
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
}

local COMPOSITION_TO_THREAT = {
    BALANCED = "OBJECTIVE_TRADE",
    STEALTH = "DOUBLE_STEALTH_ASSAULT",
    ROT = "DURABLE_ATTRITION",
    MELEE = "DEATHBALL_CLEAVE",
    RANGED = "RANGED_CONTROL",
    ROTATION = "HIGH_MOBILITY_SPLIT",
    BUNKER = "BUNKER_DEFENSE",
}

function CompThreats:Get(id)
    return THREATS[id]
end

function CompThreats:All()
    return THREATS
end

function CompThreats:Count()
    local count = 0
    for _ in pairs(THREATS) do count = count + 1 end
    return count
end

function CompThreats:Select(enemyComposition, enemyTier, mapKind)
    local compositionID = type(enemyComposition) == "table"
        and enemyComposition.id or tostring(enemyComposition or "")
    local threatID = COMPOSITION_TO_THREAT[compositionID] or "OBJECTIVE_TRADE"
    if mapKind == "FLAG" and compositionID == "BUNKER" then
        threatID = "CARRIER_ESCORT"
    elseif mapKind == "FLAG" and compositionID == "MELEE" then
        threatID = "HEALER_ASSASSINATION"
    elseif mapKind == "ORB" and compositionID == "MELEE" then
        threatID = "KNOCKBACK_CONTROL"
    end
    local entry = KWR.Util:Copy(THREATS[threatID] or THREATS.OBJECTIVE_TRADE)
    entry.compositionID = compositionID
    entry.enemyTier = enemyTier and enemyTier.id or nil
    entry.selectedBy = "enemy_composition"
    return entry
end

function CompThreats:Validate()
    return self:Count() >= 10
end

KWR:RegisterModule("CompThreats", CompThreats)