local _, KWR = ...

local Capabilities = {}
KWR.Capabilities = Capabilities

local RATING_RULES = {
    burst = { burst = 5, antiHeal = 3, grip = 3, control = 2 },
    pressure = { pressure = 5, rot = 5, cleave = 4, sustain = 3, damageSupport = 2 },
    mobility = { mobility = 5, rotation = 4, stealth = 3, gateway = 3 },
    survivability = { sustain = 5, immunity = 5, external = 3, flagCarry = 4, mobility = 2 },
    peel = { peel = 5, control = 4, knockback = 4, grip = 4, external = 3 },
    teamfight = { teamfight = 5, cleave = 4, rot = 4, healing = 4, damageSupport = 3 },
    nodeDefense = { baseDefense = 5, stealth = 3, sustain = 3, control = 3, antiCaster = 2 },
    flagCarry = { flagCarry = 5, mobility = 3, sustain = 3, immunity = 3 },
    splitPush = { crossCap = 5, baseAssault = 5, stealth = 4, rotation = 3, mobility = 2 },
    objectiveUtility = {
        control = 4, knockback = 5, grip = 5, gateway = 4, purge = 3,
        rotation = 2,
    },
    recovery = { healing = 4, external = 5, mobility = 3, peel = 3, support = 3 },
    manaEndurance = { healing = 4, sustain = 3, external = 3, support = 3, mobility = 2 },
    killConfirm = { burst = 5, antiHeal = 4, grip = 4, control = 3, purge = 2 },
    ccPotential = { control = 5, knockback = 4, grip = 4, stealth = 3, antiCaster = 3 },
}

local RATING_NAMES = {
    "burst", "pressure", "mobility", "survivability", "peel", "teamfight",
    "nodeDefense", "flagCarry", "splitPush", "objectiveUtility", "recovery",
    "manaEndurance", "killConfirm", "ccPotential",
}

-- Each weighted category has at least three explicit battlefield effects.
-- These descriptions are knowledge metadata and explain how a rating should
-- influence a command without claiming a specific talent is currently active.
local CATEGORY_EFFECTS = {
    burst = { "short kill window", "carrier execution", "spinner removal" },
    pressure = { "sustained team-fight value", "healer mana tax", "anti-bunker attrition" },
    mobility = { "early objective arrival", "fast reinforcement", "safe disengage" },
    survivability = { "objective uptime", "carrier safety", "stall duration" },
    peel = { "carrier protection", "healer stabilization", "enemy-go denial" },
    teamfight = { "main-fight conversion", "choke control", "numbers advantage" },
    nodeDefense = { "solo sit safety", "spin duration", "incoming-call time" },
    flagCarry = { "route survival", "stack tolerance", "capture conversion" },
    splitPush = { "cross-cap threat", "weak-side pressure", "enemy-team separation" },
    objectiveUtility = { "capture denial", "forced displacement", "route control" },
    recovery = { "post-wipe reset", "low-health stabilization", "re-engage readiness" },
    manaEndurance = { "extended hold", "long team fight", "repeated defense cycle" },
    killConfirm = { "low-health finish", "defensive swap timing", "return-team execution" },
    ccPotential = { "spinner control", "healer lockout", "capture-channel protection" },
}

local JOB_RULES = {
    ANCHOR = { baseDefense = 45, sustain = 25, flagCarry = 20, control = 10 },
    FLOATER = { rotation = 45, mobility = 35, healing = 12, stealth = 10 },
    ESCORT = { healing = 30, external = 30, peel = 25, support = 15 },
    DEFENDER = { baseDefense = 50, control = 20, sustain = 15, stealth = 10 },
    ASSASSIN = { burst = 35, antiHeal = 25, stealth = 20, grip = 15 },
    CARRIER = { flagCarry = 55, mobility = 25, sustain = 20 },
    ROAMER = { mobility = 35, rotation = 30, crossCap = 25, stealth = 15 },
    SUPPORT = { healing = 35, external = 30, support = 25, peel = 15 },
    HARASSER = { baseAssault = 35, crossCap = 30, rot = 20, control = 15 },
}

local HERO_MODIFIERS = {
    ["DEATHKNIGHT:deathbringer"] = {
        confidence = "ADVISORY",
        ratings = { burst = 1, pressure = 1, killConfirm = 1 },
        jobs = { ASSASSIN = 10 },
    },
    ["DEATHKNIGHT:rider of the apocalypse"] = {
        confidence = "ADVISORY",
        ratings = { mobility = 1, objectiveUtility = 1 },
        jobs = { FLOATER = 10, ROAMER = 10 },
    },
}

local resolvedCache = {}
local cacheHits, cacheMisses = 0, 0

local function deriveRatings(tags, role)
    local ratings = {}
    for rating, rules in pairs(RATING_RULES) do
        local score = 1
        for tag, value in pairs(rules) do
            if tags[tag] then score = math.max(score, value) end
        end
        ratings[rating] = score
    end
    if role == "TANK" then
        ratings.survivability = math.max(ratings.survivability, 4)
        ratings.nodeDefense = math.max(ratings.nodeDefense, 4)
    elseif role == "HEALER" then
        ratings.recovery = math.max(ratings.recovery, 4)
        ratings.manaEndurance = math.max(ratings.manaEndurance, 4)
        ratings.teamfight = math.max(ratings.teamfight, 4)
    end
    return ratings
end

local function deriveJobs(tags, role)
    local jobs = {}
    for job, rules in pairs(JOB_RULES) do
        local score = 0
        for tag, value in pairs(rules) do
            if tags[tag] then score = score + value end
        end
        jobs[job] = math.min(score, 100)
    end
    if role == "HEALER" then jobs.SUPPORT = math.max(jobs.SUPPORT, 75) end
    if role == "TANK" then
        jobs.ANCHOR = math.max(jobs.ANCHOR, 70)
        jobs.CARRIER = math.max(jobs.CARRIER, 55)
    end
    return jobs
end

local function row(role, range, confidence, tags)
    local indexed = {}
    for _, tag in ipairs(tags or {}) do indexed[tag] = true end
    return {
        role = role,
        range = range,
        confidence = confidence or "REVIEWED",
        tags = indexed,
        ratings = deriveRatings(indexed, role),
        jobs = deriveJobs(indexed, role),
    }
end

-- Semantic battlefield capabilities, not talent claims. A tag means the
-- specialization commonly supports that plan family; live observations and
-- player choices still determine whether a specific tool is available.
local DATA = {
    ["DEATHKNIGHT:blood"] = row("TANK", "MELEE", "REVIEWED",
        { "flagCarry", "sustain", "grip", "antiCaster", "teamfight", "baseDefense" }),
    ["DEATHKNIGHT:frost"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "burst", "cleave", "grip", "antiCaster", "teamfight" }),
    ["DEATHKNIGHT:unholy"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "rot", "antiHeal", "grip", "sustain", "teamfight" }),

    ["DEMONHUNTER:havoc"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "mobility", "burst", "cleave", "teamfight", "rotation" }),
    ["DEMONHUNTER:devourer"] = row("DAMAGER", "MELEE", "PROVISIONAL",
        { "mobility", "burst", "teamfight" }),
    ["DEMONHUNTER:vengeance"] = row("TANK", "MELEE", "REVIEWED",
        { "flagCarry", "mobility", "control", "rotation", "teamfight" }),

    ["DRUID:balance"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "rot", "control", "knockback", "stealth", "teamfight", "baseDefense" }),
    ["DRUID:feral"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "stealth", "crossCap", "burst", "mobility", "rotation", "baseDefense" }),
    ["DRUID:guardian"] = row("TANK", "MELEE", "REVIEWED",
        { "flagCarry", "stealth", "mobility", "sustain", "baseDefense" }),
    ["DRUID:restoration"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "mobility", "stealth", "sustain", "rotation" }),

    ["EVOKER:devastation"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "burst", "mobility", "control", "teamfight" }),
    ["EVOKER:preservation"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "mobility", "external", "teamfight" }),
    ["EVOKER:augmentation"] = row("DAMAGER", "RANGED", "PROVISIONAL",
        { "support", "mobility", "teamfight" }),

    ["HUNTER:beast mastery"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "pressure", "antiHeal", "baseDefense", "mobility", "peel" }),
    ["HUNTER:marksmanship"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "burst", "antiHeal", "baseDefense", "control", "knockback" }),
    ["HUNTER:survival"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "pressure", "antiHeal", "mobility", "control", "baseDefense" }),

    ["MAGE:arcane"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "burst", "mobility", "control", "peel", "rotation" }),
    ["MAGE:fire"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "burst", "control", "peel", "teamfight" }),
    ["MAGE:frost"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "control", "peel", "teamfight", "baseDefense", "sustain" }),

    ["MONK:brewmaster"] = row("TANK", "MELEE", "REVIEWED",
        { "flagCarry", "mobility", "control", "knockback", "rotation" }),
    ["MONK:mistweaver"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "mobility", "peel", "external", "rotation" }),
    ["MONK:windwalker"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "burst", "mobility", "cleave", "control", "rotation" }),

    ["PALADIN:holy"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "external", "immunity", "support", "teamfight" }),
    ["PALADIN:protection"] = row("TANK", "MELEE", "REVIEWED",
        { "flagCarry", "external", "immunity", "support", "baseDefense" }),
    ["PALADIN:retribution"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "burst", "external", "immunity", "support", "teamfight" }),

    ["PRIEST:discipline"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "external", "purge", "damageSupport", "teamfight" }),
    ["PRIEST:holy"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "external", "control", "teamfight" }),
    ["PRIEST:shadow"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "rot", "control", "purge", "antiCaster", "teamfight" }),

    ["ROGUE:assassination"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "stealth", "crossCap", "antiHeal", "control", "baseAssault" }),
    ["ROGUE:outlaw"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "stealth", "crossCap", "control", "mobility", "baseAssault" }),
    ["ROGUE:subtlety"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "stealth", "crossCap", "burst", "control", "baseAssault" }),

    ["SHAMAN:elemental"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "burst", "knockback", "purge", "control", "teamfight" }),
    ["SHAMAN:enhancement"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "burst", "purge", "support", "mobility", "teamfight" }),
    ["SHAMAN:restoration"] = row("HEALER", "RANGED", "REVIEWED",
        { "healing", "purge", "knockback", "external", "teamfight" }),

    ["WARLOCK:affliction"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "rot", "control", "sustain", "teamfight", "gateway" }),
    ["WARLOCK:demonology"] = row("DAMAGER", "RANGED", "PROVISIONAL",
        { "pressure", "control", "sustain", "teamfight", "gateway" }),
    ["WARLOCK:destruction"] = row("DAMAGER", "RANGED", "REVIEWED",
        { "burst", "control", "teamfight", "gateway", "baseDefense" }),

    ["WARRIOR:arms"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "antiHeal", "burst", "teamfight", "control", "support" }),
    ["WARRIOR:fury"] = row("DAMAGER", "MELEE", "REVIEWED",
        { "pressure", "mobility", "sustain", "teamfight" }),
    ["WARRIOR:protection"] = row("TANK", "MELEE", "REVIEWED",
        { "flagCarry", "control", "mobility", "teamfight", "baseDefense" }),
}

local function key(classFile, spec)
    return KWR.Util:Upper(classFile, "", 24) .. ":"
        .. KWR.Util:Text(spec, "", 32):lower()
end

function Capabilities:Get(classFile, spec, heroTalent)
    local lookup = key(classFile, spec)
    local heroName = KWR.Util:Text(heroTalent, "", 48):lower()
    local cacheKey = lookup .. ":" .. heroName
    if resolvedCache[cacheKey] then
        cacheHits = cacheHits + 1
        return KWR.Util:Copy(resolvedCache[cacheKey])
    end
    cacheMisses = cacheMisses + 1
    local base = DATA[lookup]
    if not base then return nil end
    local result = KWR.Util:Copy(base)
    local overlay = KWR.PatchData:Capability(lookup)
    if overlay then
        for field, value in pairs(overlay) do
            if type(value) == "table" and type(result[field]) == "table" then
                for nested, nestedValue in pairs(value) do
                    result[field][nested] = KWR.Util:Copy(nestedValue)
                end
            else
                result[field] = KWR.Util:Copy(value)
            end
        end
    end
    local heroKey = KWR.Util:Upper(classFile, "", 24) .. ":" .. heroName
    local hero = HERO_MODIFIERS[heroKey]
    if hero then
        for rating, delta in pairs(hero.ratings or {}) do
            result.ratings[rating] = math.max(1, math.min(5,
                (result.ratings[rating] or 1) + delta))
        end
        for job, delta in pairs(hero.jobs or {}) do
            result.jobs[job] = math.max(0, math.min(100,
                (result.jobs[job] or 0) + delta))
        end
        result.heroTalent = KWR.Util:Text(heroTalent, "", 48)
        result.heroConfidence = hero.confidence
    end
    resolvedCache[cacheKey] = result
    return KWR.Util:Copy(result)
end

-- Hot-path accessor. Callers must treat the returned table as read-only.
function Capabilities:Resolve(classFile, spec, heroTalent)
    local lookup = key(classFile, spec)
    local heroName = KWR.Util:Text(heroTalent, "", 48):lower()
    local cacheKey = lookup .. ":" .. heroName
    if resolvedCache[cacheKey] then
        cacheHits = cacheHits + 1
    else
        self:Get(classFile, spec, heroTalent)
    end
    return resolvedCache[cacheKey]
end

function Capabilities:CacheStats()
    local entries = 0
    for _ in pairs(resolvedCache) do entries = entries + 1 end
    return { hits = cacheHits, misses = cacheMisses, entries = entries }
end

function Capabilities:RatingNames()
    return RATING_NAMES
end

function Capabilities:CategoryEffects()
    return CATEGORY_EFFECTS
end

function Capabilities:CategoryAudit()
    local result = {}
    for _, rating in ipairs(RATING_NAMES) do
        local signals = 0
        for _ in pairs(RATING_RULES[rating] or {}) do signals = signals + 1 end
        result[rating] = {
            signals = signals,
            effects = #(CATEGORY_EFFECTS[rating] or {}),
        }
    end
    return result
end

function Capabilities:Count()
    local count = 0
    for _ in pairs(DATA) do count = count + 1 end
    return count
end

function Capabilities:Summarize(roster)
    local summary = {
        players = 0, tanks = 0, healers = 0, damage = 0,
        melee = 0, ranged = 0, knownSpecs = 0, provisional = 0,
        tags = {}, ratings = {}, ratingPeak = {}, jobs = {},
    }
    for _, player in ipairs(roster or {}) do
        summary.players = summary.players + 1
        local capability = self:Resolve(player.classFile, player.spec, player.heroTalent)
        local role = capability and capability.role or KWR.CombatSpells:Role(player.spec, player.role)
        if role == "TANK" then summary.tanks = summary.tanks + 1
        elseif role == "HEALER" then summary.healers = summary.healers + 1
        else summary.damage = summary.damage + 1 end
        if capability then
            summary.knownSpecs = summary.knownSpecs + 1
            if capability.range == "MELEE" then summary.melee = summary.melee + 1
            elseif capability.range == "RANGED" then summary.ranged = summary.ranged + 1 end
            if capability.confidence == "PROVISIONAL" then summary.provisional = summary.provisional + 1 end
            if player.specSource == "historical" then
                summary.likelySpecs = (summary.likelySpecs or 0) + 1
            else
                summary.confirmedSpecs = (summary.confirmedSpecs or 0) + 1
            end
            for tag in pairs(capability.tags) do
                summary.tags[tag] = (summary.tags[tag] or 0) + 1
            end
            for _, rating in ipairs(RATING_NAMES) do
                local score = capability.ratings[rating] or 1
                summary.ratings[rating] = (summary.ratings[rating] or 0) + score
                summary.ratingPeak[rating] = math.max(summary.ratingPeak[rating] or 0, score)
            end
            for job, score in pairs(capability.jobs or {}) do
                summary.jobs[job] = (summary.jobs[job] or 0) + score
            end
        end
    end
    summary.coverage = summary.players > 0 and summary.knownSpecs / summary.players or 0
    summary.unknownSpecs = summary.players - summary.knownSpecs
    for _, rating in ipairs(RATING_NAMES) do
        summary.ratings[rating] = summary.knownSpecs > 0
            and (summary.ratings[rating] or 0) / summary.knownSpecs or 0
    end
    for job, score in pairs(summary.jobs) do
        summary.jobs[job] = summary.knownSpecs > 0 and score / summary.knownSpecs or 0
    end
    summary.confidence = summary.knownSpecs == 0 and "UNKNOWN"
        or ((summary.confirmedSpecs or 0) == summary.players and "CONFIRMED"
        or (summary.coverage >= 0.8 and "LIKELY" or "ESTIMATED"))
    return summary
end

KWR:RegisterModule("Capabilities", Capabilities)
