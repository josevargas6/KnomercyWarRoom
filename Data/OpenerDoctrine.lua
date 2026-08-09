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
        reviewed({
            id = mapKey .. "_OPEN_BALANCED_MIRROR",
            branch = "BALANCED_MIRROR",
            action = "Secure " .. terms.anchor .. ", contest " .. terms.primary .. " with the complete core, and keep the reserve hidden until the mirror fight declares a weak lane.",
            when = "Both teams present a balanced opening shape.",
            assignments = "anchor, objective core, hidden reserve",
            followup = "Use the reserve only to turn the first confirmed disadvantage at " .. terms.weak .. ".",
            antiThrow = "Do not mirror every enemy rotation or spend the reserve on an even fight.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_STEALTH_VS_BUNKER",
            branch = "STEALTH_VS_BUNKER",
            action = "Anchor " .. terms.anchor .. ", show a compact contest at " .. terms.primary .. ", and send the stealth package through " .. terms.weak .. " to pull the bunker shell apart.",
            when = "Friendly stealth meets an enemy bunker or carrier-defense shell.",
            assignments = "anchor, minimum contest, stealth package, reserve",
            followup = "Collapse onto " .. terms.primary .. " only after bunker support leaves the weak lane.",
            antiThrow = "Do not reveal every stealth player into the bunker front.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_ROT_VS_MELEE",
            branch = "ROT_VS_MELEE",
            action = "Hold " .. terms.anchor .. ", spread the rot line around " .. terms.primary .. ", and make the melee core cross peel and control before committing to a kill.",
            when = "Friendly attrition pressure faces a compact melee opener.",
            assignments = "anchor, spread pressure line, peel shell, reserve",
            followup = "Take " .. terms.weak .. " when their melee core fully commits to the primary fight.",
            antiThrow = "Do not accept their stacked burst fight without a retreat path.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_RANGED_VS_ROTATION",
            branch = "RANGED_VS_ROTATION",
            action = "Plant the ranged line at " .. terms.primary .. ", retain " .. terms.anchor .. ", and use the reserve to punish the first rotation that leaves a lane unsupported.",
            when = "Friendly ranged control faces high-mobility enemy rotation.",
            assignments = "anchor, ranged line, anti-rotation reserve",
            followup = "Shift the reserve to " .. terms.weak .. " only after the enemy route is visible.",
            antiThrow = "Do not chase fast movement with the full ranged line.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_MELEE_VS_RANGED",
            branch = "MELEE_VS_RANGED",
            action = "Secure " .. terms.anchor .. ", use terrain and a compact approach into " .. terms.primary .. ", and hold the reserve for the ranged line's retreat path.",
            when = "Friendly melee pressure faces a ranged-control opener.",
            assignments = "anchor, approach core, peel reserve",
            followup = "Pivot to " .. terms.weak .. " if the ranged line gives ground instead of committing.",
            antiThrow = "Do not run the whole melee core through open control without support.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_ROTATION_VS_ROT",
            branch = "ROTATION_VS_ROT",
            action = "Keep " .. terms.anchor .. " covered, refuse the prolonged fight at " .. terms.primary .. ", and use faster arrivals to force the rot team to answer " .. terms.weak .. ".",
            when = "Friendly mobility faces enemy attrition pressure.",
            assignments = "anchor, pressure show, mobile strike package, reserve",
            followup = "Rejoin at " .. terms.primary .. " after the enemy rot line splits.",
            antiThrow = "Do not feed staggered players into the enemy's sustained pressure.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_BUNKER_VS_STEALTH",
            branch = "BUNKER_VS_STEALTH",
            action = "Build a paired shell around " .. terms.anchor .. ", maintain anti-stealth coverage at " .. terms.primary .. ", and keep one responder between both lanes.",
            when = "Friendly durable objective play faces stealth cross-cap pressure.",
            assignments = "paired anchor, anti-stealth scout, response reserve",
            followup = "Counterattack " .. terms.weak .. " only after the stealth package is identified.",
            antiThrow = "Do not unpair defenders or chase an unconfirmed stealth decoy.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_NODE_LOCKDOWN_VS_STEALTH",
            branch = "NODE_LOCKDOWN_VS_STEALTH",
            action = "Pair the independent defenders at " .. terms.anchor .. " and " .. terms.weak .. ", then send the control core through " .. terms.primary .. " with a preserved anti-stealth response.",
            when = "A qualified Node Lockdown roster faces enemy stealth pressure.",
            assignments = "paired defenders, control core, anti-stealth response",
            followup = "Release the response only after both defender pairs confirm coverage.",
            antiThrow = "Do not turn paired defense into isolated solo sitters.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_CASTER_SIEGE_VS_MELEE",
            branch = "CASTER_SIEGE_VS_MELEE",
            action = "Establish the caster control line at " .. terms.primary .. ", keep " .. terms.anchor .. " safe, and reserve peel before offering the melee team a committed target.",
            when = "A qualified Caster Siege roster faces enemy melee collapse.",
            assignments = "anchor, caster line, peel shell, reserve",
            followup = "Move pressure to " .. terms.weak .. " after the melee cooldown push fails.",
            antiThrow = "Do not expose the caster line without a protected retreat route.",
        }),
        reviewed({
            id = mapKey .. "_OPEN_FLAG_SPECIALIST_VS_BUNKER",
            branch = "FLAG_SPECIALIST_VS_BUNKER",
            action = "Protect " .. terms.anchor .. ", pressure the bunker support around " .. terms.primary .. ", and preserve the specialist package for the first verified scoring window.",
            when = "A qualified Flag Specialist roster faces a bunker or carrier-defense shell.",
            assignments = "anchor, support pressure, specialist package, reserve",
            followup = "Commit the specialist package toward " .. terms.weak .. " only after enemy support is separated.",
            antiThrow = "Do not trade the protected scoring package into an unbroken bunker.",
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
    local ourTier = context and context.ourTier and context.ourTier.id
    if ourTier == "NODE_LOCKDOWN" and enemyComposition == "STEALTH" then
        return KWR.Util:Copy(use[13])
    end
    if ourTier == "CASTER_SIEGE" and enemyComposition == "MELEE" then
        return KWR.Util:Copy(use[14])
    end
    if ourTier == "FLAG_SPECIALIST" and enemyComposition == "BUNKER" then
        return KWR.Util:Copy(use[15])
    end
    if ourComposition == "BALANCED" and enemyComposition == "BALANCED" then
        return KWR.Util:Copy(use[6])
    end
    if ourComposition == "STEALTH" and enemyComposition == "BUNKER" then
        return KWR.Util:Copy(use[7])
    end
    if ourComposition == "ROT" and enemyComposition == "MELEE" then
        return KWR.Util:Copy(use[8])
    end
    if ourComposition == "RANGED" and enemyComposition == "ROTATION" then
        return KWR.Util:Copy(use[9])
    end
    if ourComposition == "MELEE" and enemyComposition == "RANGED" then
        return KWR.Util:Copy(use[10])
    end
    if ourComposition == "ROTATION" and enemyComposition == "ROT" then
        return KWR.Util:Copy(use[11])
    end
    if ourComposition == "BUNKER" and enemyComposition == "STEALTH" then
        return KWR.Util:Copy(use[12])
    end
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
