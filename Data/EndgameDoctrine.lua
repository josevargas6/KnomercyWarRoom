local _, KWR = ...

local EndgameDoctrine = {}
KWR.EndgameDoctrine = EndgameDoctrine

local function reviewed(entry)
    entry.reviewStatus = "THEORY_REVIEWED"
    entry.evidenceGrade = "C"
    entry.requiresMatchValidation = true
    return entry
end

local UNIVERSAL = {
    reviewed({ id = "NO_CHASE_WINNING_CLOCK", condition = "projectedWin", require = "protect scoring minimum", prohibit = "chase away from decisive objective" }),
    reviewed({ id = "MINIMUM_STALL_FORCE", condition = "delayWins", require = "send minimum viable stall", prohibit = "convert stall into full-team reinforcement" }),
    reviewed({ id = "ABANDON_UNRECOVERABLE", condition = "arrivalAfterResolution", require = "rotate before resolution", prohibit = "late feed" }),
    reviewed({ id = "HIGH_VARIANCE_ONLY_BEHIND", condition = "projectedLoss", require = "select highest-upside legal branch", prohibit = "low-impact safe play" }),
    reviewed({ id = "PRESERVE_ONLY_DEFENDER", condition = "onlyDefenderWouldMove", require = "name replacement before movement", prohibit = "uncovered objective" }),
}

local function mapTerms(mapKey)
    local terms = {
        ARATHI = { protect = "winning base count", stall = "center stall", punish = "outer-node punish", force = "score-changing cap" },
        GILNEAS = { protect = "two-base clock", stall = "Waterworks stall", punish = "outer-node punish", force = "score-changing cap" },
        DEEPWIND = { protect = "three-node shell", stall = "central stall", punish = "outer-flank punish", force = "score-changing cap" },
        EOTS = { protect = "tower minimum", stall = "flag stall", punish = "tower punish", force = "score-changing tower flip" },
        WSG = { protect = "carrier state", stall = "carrier peel stall", punish = "escort punish", force = "return-and-cap" },
        TWINPEAKS = { protect = "carrier state", stall = "carrier peel stall", punish = "escort punish", force = "return-and-cap" },
        TEMPLE = { protect = "scoring carrier shell", stall = "pickup denial stall", punish = "isolated carrier punish", force = "high-value pickup denial" },
        SILVERSHARD = { protect = "winning cart race", stall = "junction stall", punish = "weaker cart punish", force = "decisive cart turn" },
        DEEPHAUL = { protect = "winning cart distance", stall = "enemy-cart stall", punish = "cart race punish", force = "decisive cart reversal" },
        SEETHING = { protect = "resource lead", stall = "channel stall", punish = "spawn punish", force = "decisive deposit denial" },
    }
    return terms[mapKey] or { protect = "winning state", stall = "stall branch", punish = "punish branch", force = "decisive event" }
end

local function entries(mapKey)
    local terms = mapTerms(mapKey)
    return {
        reviewed({
            id = mapKey .. "_END_PROTECT",
            branch = "PROTECT",
            condition = "projectedWin",
            action = "Protect " .. terms.protect .. " and reinforce only the lane whose loss breaks the winning clock.",
            antiThrow = "No chase, greed assault, or vanity reassignment may expose the winning minimum.",
            fallback = "Freeze optional pressure and move only the named reserve when the anchor destabilizes.",
        }),
        reviewed({
            id = mapKey .. "_END_STALL",
            branch = "STALL",
            condition = "delayWins",
            action = "Send the minimum viable stall to create time while every other player protects " .. terms.protect .. ".",
            antiThrow = "Do not transform a clock stall into a wipeable full-team fight.",
            fallback = "When the stall fails or the event resolves, preload the next decisive lane immediately.",
        }),
        reviewed({
            id = mapKey .. "_END_PUNISH",
            branch = "PUNISH",
            condition = "enemyOvercommit",
            action = "Punish the enemy overcommit through " .. terms.punish .. " while preserving " .. terms.protect .. ".",
            antiThrow = "Launch only after anchor coverage and enemy commitment are both confirmed.",
            fallback = "Abort if the enemy reserve remains free or the winning anchor calls instability.",
        }),
        reviewed({
            id = mapKey .. "_END_FORCE",
            branch = "FORCE_SCORE",
            condition = "oneScoringEventRequired",
            action = "Concentrate enough force to create " .. terms.force .. " now.",
            antiThrow = "Do not split interaction across objectives that cannot individually change the result.",
            fallback = "If the event becomes unrecoverable, switch immediately without staggered reinforcements.",
        }),
        reviewed({
            id = mapKey .. "_END_DESPERATION",
            branch = "DESPERATION",
            condition = "projectedLoss",
            action = "Run the highest-upside legal branch and accept variance only because the score path already loses otherwise.",
            antiThrow = "Every lane in the desperation branch must be capable of changing the final result.",
            fallback = "Collapse onto the first lane that creates a real interaction, denial, or cap window.",
        }),
    }
end

function EndgameDoctrine:Get(mapKey)
    return entries(mapKey)
end

function EndgameDoctrine:Universal()
    return UNIVERSAL
end

function EndgameDoctrine:Count(mapKey)
    if mapKey then return #entries(mapKey) end
    local total = #UNIVERSAL
    for key in pairs(KWR.Maps:All()) do total = total + #entries(key) end
    return total
end

function EndgameDoctrine:Select(mapKey, flags)
    local use = self:Get(mapKey)
    if flags and flags.projectedLoss then
        return KWR.Util:Copy(use[5])
    end
    if flags and flags.oneScoringEventRequired then
        return KWR.Util:Copy(use[4])
    end
    if flags and flags.enemyOvercommit then
        return KWR.Util:Copy(use[3])
    end
    if flags and flags.delayWins then
        return KWR.Util:Copy(use[2])
    end
    return KWR.Util:Copy(use[1])
end

KWR:RegisterModule("EndgameDoctrine", EndgameDoctrine)