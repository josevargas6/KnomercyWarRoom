local _, KWR = ...

local OpenerDoctrine = {}
KWR.OpenerDoctrine = OpenerDoctrine

local function reviewed(entry)
    entry.reviewStatus = "THEORY_REVIEWED"
    entry.evidenceGrade = "C"
    entry.requiresMatchValidation = true
    return entry
end

local function mapTerms(mapKey)
    local terms = {
        ARATHI = { anchor = "home base", primary = "Blacksmith", weak = "weak outer node" },
        GILNEAS = { anchor = "home node", primary = "Waterworks", weak = "outer node" },
        DEEPWIND = { anchor = "home node", primary = "central node", weak = "outer flank" },
        EOTS = { anchor = "friendly tower", primary = "mid flag", weak = "enemy tower" },
        WSG = { anchor = "our carrier route", primary = "enemy flag carrier route", weak = "escort shell" },
        TWINPEAKS = { anchor = "our carrier route", primary = "enemy carrier route", weak = "intercept side" },
        TEMPLE = { anchor = "supported scoring space", primary = "high-value orb lane", weak = "replacement pickup" },
        SILVERSHARD = { anchor = "friendly scoring cart", primary = "junction fight", weak = "recoverable cart" },
        DEEPHAUL = { anchor = "friendly cart", primary = "enemy cart lane", weak = "cart race lane" },
        SEETHING = { anchor = "active extractor", primary = "current spawn", weak = "next public spawn" },
    }
    return terms[mapKey] or { anchor = "anchor objective", primary = "primary objective", weak = "weak lane" }
end

local function entries(mapKey)
    local terms = mapTerms(mapKey)
    return {
        reviewed({
            id = mapKey .. "_OPEN_STANDARD",
            branch = "STANDARD",
            action = "Secure " .. terms.anchor .. ", establish presence at " .. terms.primary .. ", and keep one mobile reserve unspent.",
            when = "Enemy opener is not yet resolved.",
            assignments = "anchor, objective core, reserve",
            followup = "Shift pressure toward " .. terms.weak .. " when enemy commitment is confirmed.",
            antiThrow = "Do not consume the reserve before distribution is known.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_WEAKSIDE",
            branch = "WEAKSIDE",
            action = "Show enough pressure at " .. terms.primary .. " to pin the response, then probe " .. terms.weak .. " with the compact strike package.",
            when = "Friendly mobility or stealth is strong enough to create an uneven opener.",
            assignments = "anchor, pressure show, strike package, reserve",
            followup = "Collapse back to " .. terms.primary .. " if the weak-side lane is paired before control lands.",
            antiThrow = "Do not turn both lanes into unsupported full fights.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_ANTI_BUNKER",
            branch = "ANTI_BUNKER",
            action = "Delay " .. terms.primary .. " with minimum presence while attacking the weak side of the bunker shell.",
            when = "Enemy comp or early shape indicates durable static defense.",
            assignments = "minimum stall, strike package, reserve",
            followup = "Return to " .. terms.primary .. " only after bunker support leaves.",
            antiThrow = "Do not fight front-to-back into stacked sustain.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_ANTI_SPLIT",
            branch = "ANTI_SPLIT",
            action = "Protect " .. terms.anchor .. ", shorten rotation distance, and deny simultaneous weak-lane pressure before selecting one counterattack.",
            when = "Enemy comp indicates high-mobility split pressure.",
            assignments = "anchor, compact shell, response reserve",
            followup = "Counterattack " .. terms.weak .. " after one enemy lane is confirmed unsupported.",
            antiThrow = "Do not chase a decoy off the scoring requirement.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_ANTI_MELEE",
            branch = "ANTI_MELEE",
            action = "Fight around " .. terms.primary .. " from spread positions and force melee commitment through peel and crossfire instead of a stacked flag brawl.",
            when = "Enemy comp prefers a compact front-loaded team fight.",
            assignments = "anchor, ranged line, peel shell, reserve",
            followup = "Trade toward " .. terms.weak .. " if the melee core hard-commits.",
            antiThrow = "Do not stack every healer and ranged player into one collapse point.",
        }),
    }
end

function OpenerDoctrine:Get(mapKey)
    return entries(mapKey)
end

function OpenerDoctrine:Count(mapKey)
    if mapKey then return #entries(mapKey) end
    local total = 0
    for key in pairs(KWR.Maps:All()) do total = total + #entries(key) end
    return total
end

function OpenerDoctrine:Select(mapKey, context)
    local use = self:Get(mapKey)
    local enemyComposition = context and context.enemyComposition and context.enemyComposition.id
    local ourComposition = context and context.ourComposition and context.ourComposition.id
    local compThreat = context and context.compThreat and context.compThreat.id
    local defenseModel = context and context.enemyDefenseModel and context.enemyDefenseModel.id
    if defenseModel == "HEALER_BUNKER" or enemyComposition == "BUNKER" then
        return KWR.Util:Copy(use[3])
    end
    if compThreat == "HIGH_MOBILITY_SPLIT" or enemyComposition == "ROTATION" then
        return KWR.Util:Copy(use[4])
    end
    if compThreat == "DEATHBALL_CLEAVE" or enemyComposition == "MELEE" then
        return KWR.Util:Copy(use[5])
    end
    if ourComposition == "STEALTH" or ourComposition == "ROTATION" then
        return KWR.Util:Copy(use[2])
    end
    return KWR.Util:Copy(use[1])
end

KWR:RegisterModule("OpenerDoctrine", OpenerDoctrine)