local _, KWR = ...

local StrategistNexusPolicy = {}
KWR.StrategistNexusPolicy = StrategistNexusPolicy

local CANDIDATE_FOCUS = {
    HOLD = { nodeDefense = 1.0, survivability = 0.8, peel = 0.7, manaEndurance = 0.5 },
    ROTATE = { mobility = 1.0, recovery = 0.7, objectiveUtility = 0.6 },
    TRADE = { splitPush = 1.0, mobility = 0.8, nodeDefense = 0.4 },
    TEAMFIGHT = { teamfight = 1.0, burst = 0.7, pressure = 0.7, killConfirm = 0.6 },
    SPLIT = { splitPush = 1.0, mobility = 0.8, survivability = 0.5, ccPotential = 0.5 },
}

local ARCHETYPE_ADJUSTMENTS = {
    BALANCED = { HOLD = 1, ROTATE = 2, TRADE = 1, TEAMFIGHT = 0, SPLIT = 1 },
    STEALTH = { HOLD = 3, ROTATE = -2, TRADE = 1, TEAMFIGHT = -1, SPLIT = 2 },
    ROT = { HOLD = -1, ROTATE = 3, TRADE = 2, TEAMFIGHT = -4, SPLIT = 3 },
    MELEE = { HOLD = 1, ROTATE = 2, TRADE = 1, TEAMFIGHT = -1, SPLIT = 2 },
    RANGED = { HOLD = 1, ROTATE = 2, TRADE = 2, TEAMFIGHT = -2, SPLIT = 1 },
    ROTATION = { HOLD = 3, ROTATE = -1, TRADE = 4, TEAMFIGHT = -2, SPLIT = 1 },
    BUNKER = { HOLD = 0, ROTATE = 1, TRADE = 3, TEAMFIGHT = -4, SPLIT = 5 },
}

local SCORE_ADJUSTMENTS = {
    SAFE_DEFAULT = { HOLD = 2, ROTATE = 1, TRADE = -1, TEAMFIGHT = 0, SPLIT = 0 },
    FAVORABLE = { HOLD = 5, ROTATE = 1, TRADE = -4, TEAMFIGHT = -2, SPLIT = -2 },
    UNFAVORABLE = { HOLD = -3, ROTATE = 2, TRADE = 4, TEAMFIGHT = 2, SPLIT = 3 },
    TIED = { HOLD = 0, ROTATE = 2, TRADE = 1, TEAMFIGHT = 2, SPLIT = 1 },
    EMERGENCY = { HOLD = -4, ROTATE = 2, TRADE = 5, TEAMFIGHT = 4, SPLIT = 3 },
}

local FAMILIES = {
    OPENING = {
        HOLD = "scout-confirm", ROTATE = "reserve-route", TRADE = "anti-stealth",
        TEAMFIGHT = "first-contact", SPLIT = "anti-stealth",
    },
    STABILIZE = {
        HOLD = "score-floor", ROTATE = "rotation-discipline", TRADE = "defender-pair",
        TEAMFIGHT = "healer-triangle", SPLIT = "defender-pair",
    },
    PRESSURE = {
        HOLD = "ranged-sightline", ROTATE = "weak-side-pivot", TRADE = "grip-window",
        TEAMFIGHT = "control-chain", SPLIT = "weak-side-pivot",
    },
    RECOVERY = {
        HOLD = "regroup", ROTATE = "regroup", TRADE = "cross-map-trade",
        TEAMFIGHT = "post-wipe", SPLIT = "objective-denial",
    },
    ENDGAME = {
        HOLD = "clock-protection", ROTATE = "last-window", TRADE = "safe-cap",
        TEAMFIGHT = "last-window", SPLIT = "deny-throw",
    },
}

local RESPONSE_CATEGORIES = {
    HOLD_SECOND_LANE_PRESSURE = "EXPECTED",
    ROTATION_MIRROR = "EXPECTED",
    TEAMFIGHT_REINFORCE = "EXPECTED",
    MULTI_POINT_PRESSURE = "OVERCOMMIT",
    SCORE_FLOOR_BREAK = "BAIT",
    TRUTH_BAIT_OVERCOMMIT = "BAIT",
    COUNTER_TRADE_RACE = "CROSSMAP_PIVOT",
    SPAWN_VALUE_RACE = "CROSSMAP_PIVOT",
    LATE_ROTATION_PUNISH = "FAILED_CONNECT",
    SPLIT_COLLAPSE_PUNISH = "FAILED_CONNECT",
    DECORATIVE_FIGHT_TRAP = "FAILED_CONNECT",
    CARRIER_ROUTE_SWAP = "CROSSMAP_PIVOT",
    FLAG_OVERCHASE_PUNISH = "BAIT",
}

local ARCHETYPE_WATCH = {
    BALANCED = "HUNTER_DK_PRESSURE",
    STEALTH = "ROGUE_AFFLICTION_SPLIT",
    ROT = "ARMS_AFFLICTION_CONTROL",
    MELEE = "HUNTER_RET_TEMPO",
    RANGED = "HUNTER_DK_PRESSURE",
    ROTATION = "HUNTER_RET_TEMPO",
    BUNKER = "ARMS_AFFLICTION_CONTROL",
}

local WATCHES = {
    HUNTER_DK_PRESSURE = true,
    ARMS_AFFLICTION_CONTROL = true,
    HUNTER_RET_TEMPO = true,
    ROGUE_AFFLICTION_SPLIT = true,
}

function StrategistNexusPolicy:Focus(candidateID)
    return CANDIDATE_FOCUS[candidateID] or {}
end

function StrategistNexusPolicy:ArchetypeAdjustment(archetype, candidateID)
    local row = ARCHETYPE_ADJUSTMENTS[archetype] or ARCHETYPE_ADJUSTMENTS.BALANCED
    return row[candidateID] or 0
end

function StrategistNexusPolicy:ScoreAdjustment(scoreState, candidateID)
    local row = SCORE_ADJUSTMENTS[scoreState] or SCORE_ADJUSTMENTS.SAFE_DEFAULT
    return row[candidateID] or 0
end

function StrategistNexusPolicy:Family(phase, candidateID)
    local row = FAMILIES[phase]
    return row and row[candidateID] or nil
end

function StrategistNexusPolicy:ResponseCategory(responseID)
    return RESPONSE_CATEGORIES[responseID] or "EXPECTED"
end

function StrategistNexusPolicy:CompWatch(enemyTier, enemyArchetype)
    local tierID = enemyTier and enemyTier.id
    if tierID then
        tierID = tostring(tierID):gsub("^S2_", "")
        if WATCHES[tierID] then return tierID, "TIER_MATCH" end
    end
    return ARCHETYPE_WATCH[enemyArchetype] or "HUNTER_DK_PRESSURE", "ARCHETYPE_PROXY"
end

function StrategistNexusPolicy:Shared()
    return {
        schemaVersion = 1,
        activation = "IMMEDIATE_THEORY_FIRST",
        maxCapabilityAdjustment = 8,
        maxTotalAdjustment = 16,
        candidateFocus = CANDIDATE_FOCUS,
        archetypeAdjustments = ARCHETYPE_ADJUSTMENTS,
        scoreAdjustments = SCORE_ADJUSTMENTS,
    }
end

KWR:RegisterModule("StrategistNexusPolicy", StrategistNexusPolicy)
