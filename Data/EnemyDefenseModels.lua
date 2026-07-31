local _, KWR = ...

local EnemyDefenseModels = {}
KWR.EnemyDefenseModels = EnemyDefenseModels

local MODELS = {
    SOLO_DURABLE = {
        id = "SOLO_DURABLE",
        avoid = { "slow damage-only assault" },
        preferredPunish = { "force hidden support to reveal", "swap before reinforcement stabilizes" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    SOLO_STEALTH = {
        id = "SOLO_STEALTH",
        avoid = { "blind cap interaction" },
        preferredPunish = { "anti-stealth screen", "force reveal before commit" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    DEFENDER_PLUS_FLOAT = {
        id = "DEFENDER_PLUS_FLOAT",
        avoid = { "slow two-player assault" },
        preferredPunish = { "force float reveal", "reverse onto the exposed lane" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    TWO_LAYER_NODE = {
        id = "TWO_LAYER_NODE",
        avoid = { "single-lane commitment" },
        preferredPunish = { "simultaneous probe", "draw reserve then trade" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    HEALER_BUNKER = {
        id = "HEALER_BUNKER",
        avoid = { "front-to-back attrition" },
        preferredPunish = { "split and isolate spinner", "abort slow assault" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    DEATHBALL_PERIMETER = {
        id = "DEATHBALL_PERIMETER",
        avoid = { "weaker mirror deathball" },
        preferredPunish = { "trade opposite", "pull reserve out of shell" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    ESCORT_SHELL = {
        id = "ESCORT_SHELL",
        avoid = { "carrier tunnel" },
        preferredPunish = { "escort kill first", "route cutoff" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    SPLIT_PRESSURE_SHELL = {
        id = "SPLIT_PRESSURE_SHELL",
        avoid = { "equal reactive split" },
        preferredPunish = { "collapse slower lane", "retain reserve" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    ROTATIONAL_TRAP = {
        id = "ROTATIONAL_TRAP",
        avoid = { "predictable direct assault" },
        preferredPunish = { "show and reverse", "commit only after reserve moves" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
    KNOCKBACK_FORTRESS = {
        id = "KNOCKBACK_FORTRESS",
        avoid = { "stacked edge approach" },
        preferredPunish = { "safe-angle entry", "multi-point pressure" },
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    },
}

function EnemyDefenseModels:Get(id)
    return MODELS[id]
end

function EnemyDefenseModels:All()
    return MODELS
end

function EnemyDefenseModels:Count()
    local count = 0
    for _ in pairs(MODELS) do count = count + 1 end
    return count
end

function EnemyDefenseModels:Select(snapshot, enemyComposition, currentState)
    local kind = snapshot and snapshot.context and snapshot.context.kind or "WORLD"
    local compositionID = type(enemyComposition) == "table"
        and enemyComposition.id or tostring(enemyComposition or "")
    local modelID = "DEFENDER_PLUS_FLOAT"
    if kind == "FLAG" then
        modelID = compositionID == "BUNKER" and "ESCORT_SHELL" or "DEATHBALL_PERIMETER"
    elseif kind == "ORB" then
        modelID = "KNOCKBACK_FORTRESS"
    elseif compositionID == "STEALTH" then
        modelID = "SOLO_STEALTH"
    elseif compositionID == "BUNKER" then
        modelID = "HEALER_BUNKER"
    elseif compositionID == "ROTATION" then
        modelID = currentState == "OPENING" and "ROTATIONAL_TRAP" or "SPLIT_PRESSURE_SHELL"
    elseif compositionID == "MELEE" then
        modelID = "DEATHBALL_PERIMETER"
    elseif compositionID == "RANGED" then
        modelID = "TWO_LAYER_NODE"
    end
    local entry = KWR.Util:Copy(MODELS[modelID] or MODELS.DEFENDER_PLUS_FLOAT)
    entry.compositionID = compositionID
    entry.selectedBy = "map_kind_and_enemy_composition"
    return entry
end

function EnemyDefenseModels:Validate()
    return self:Count() >= 10
end

KWR:RegisterModule("EnemyDefenseModels", EnemyDefenseModels)