local _, KWR = ...

local FormationAdvisor = {}
KWR.FormationAdvisor = FormationAdvisor

local TARGET_SIZE = 10
local TARGET_ROLES = { TANK = 1, HEALER = 3, DAMAGER = 6 }
local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }

local ARCHETYPE_TAGS = {
    BALANCED = { "control", "mobility", "baseDefense", "external", "stealth" },
    STEALTH = { "stealth", "crossCap", "baseAssault", "mobility", "control" },
    ROT = { "rot", "sustain", "control", "healing", "external" },
    MELEE = { "burst", "mobility", "antiHeal", "control", "external" },
    RANGED = { "control", "peel", "burst", "knockback", "baseDefense" },
    ROTATION = { "mobility", "rotation", "stealth", "baseDefense", "healing" },
    BUNKER = { "flagCarry", "external", "healing", "sustain", "peel" },
}

local POSITIONING = {
    "Tank/anchor: front of the objective route, never isolated from healer line.",
    "Healers: form a spread triangle with overlapping range and separate crowd-control exposure.",
    "Ranged: use line of sight and crossfire; do not stack on the healer triangle.",
    "Melee: collapse together on the called window, then return to peel or objective.",
    "Stealth/float: stay off-angle, report missing enemies, and pressure the weak objective.",
    "Defender: stand away from the capture point so one control chain cannot grant a free cap.",
}

local CLASS_NAMES = {
    DEATHKNIGHT = "Death Knight", DEMONHUNTER = "Demon Hunter", DRUID = "Druid",
    EVOKER = "Evoker", HUNTER = "Hunter", MAGE = "Mage", MONK = "Monk",
    PALADIN = "Paladin", PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman",
    WARLOCK = "Warlock", WARRIOR = "Warrior",
}

local function title(spec)
    return (spec:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function existingSpecs(roster)
    local result = {}
    for _, player in ipairs(roster or {}) do
        local key = KWR.Util:Upper(player.classFile, "", 24) .. ":"
            .. KWR.Util:Text(player.spec, "", 32):lower()
        result[key] = (result[key] or 0) + 1
    end
    return result
end

local function candidateScore(candidate, archetype, existing)
    local score = math.max(0, 30 - (candidate.rank or 30))
    local capability = KWR.Capabilities:Resolve(candidate.classFile, candidate.spec)
    for _, tag in ipairs(ARCHETYPE_TAGS[archetype] or ARCHETYPE_TAGS.BALANCED) do
        if capability and capability.tags[tag] then score = score + 8 end
    end
    local key = candidate.classFile .. ":" .. candidate.spec
    score = score - ((existing[key] or 0) * 10)
    if capability and capability.confidence == "PROVISIONAL" then score = score - 8 end
    return score
end

local function roleText(needs)
    local parts = {}
    if needs.TANK > 0 then parts[#parts + 1] = tostring(needs.TANK) .. " tank" end
    if needs.HEALER > 0 then parts[#parts + 1] = tostring(needs.HEALER) .. " healer" .. (needs.HEALER == 1 and "" or "s") end
    if needs.DAMAGER > 0 then parts[#parts + 1] = tostring(needs.DAMAGER) .. " damage" end
    return #parts > 0 and table.concat(parts, " + ") or "roster complete"
end

function FormationAdvisor:Evaluate(snapshot)
    local roster = snapshot.roster or {}
    local summary = KWR.Capabilities:Summarize(roster)
    local detected = KWR.Compositions:Detect(summary)
    local tierMatch = KWR.Compositions:MatchTier(roster,
        snapshot.context and snapshot.context.mapKey)
    local archetype = #roster >= 4 and detected.id or "BALANCED"
    local needs = {
        TANK = math.max(TARGET_ROLES.TANK - summary.tanks, 0),
        HEALER = math.max(TARGET_ROLES.HEALER - summary.healers, 0),
        DAMAGER = math.max(TARGET_ROLES.DAMAGER - summary.damage, 0),
    }
    local overages = {
        TANK = math.max(summary.tanks - TARGET_ROLES.TANK, 0),
        HEALER = math.max(summary.healers - TARGET_ROLES.HEALER, 0),
        DAMAGER = math.max(summary.damage - TARGET_ROLES.DAMAGER, 0),
    }
    local openSlots = math.max(TARGET_SIZE - #roster, 0)
    local totalNeeds = needs.TANK + needs.HEALER + needs.DAMAGER
    local replacementsNeeded = math.max(totalNeeds - openSlots, 0)
    local existing = existingSpecs(roster)
    local recommendations = {}
    local remainingOpenSlots = openSlots
    local replacementPool = KWR.Util:Copy(overages)
    local function takeReplacementRole()
        for index = #ROLE_ORDER, 1, -1 do
            local role = ROLE_ORDER[index]
            if replacementPool[role] > 0 then
                replacementPool[role] = replacementPool[role] - 1
                return role
            end
        end
        return "EXCESS ROLE"
    end
    for _, role in ipairs(ROLE_ORDER) do
        local needed = needs[role]
        if needed > 0 then
            local candidates = KWR.MetaSnapshot:All(role)
            for _, candidate in ipairs(candidates) do
                candidate.score = candidateScore(candidate, archetype, existing)
            end
            table.sort(candidates, function(a, b)
                if a.score ~= b.score then return a.score > b.score end
                return a.rank < b.rank
            end)
            for index = 1, math.min(needed, #candidates) do
                local candidate = candidates[index]
                local acquisition, replacedRole
                if remainingOpenSlots > 0 then
                    acquisition = "OPEN SLOT"
                    remainingOpenSlots = remainingOpenSlots - 1
                else
                    replacedRole = takeReplacementRole()
                    acquisition = "REPLACE " .. replacedRole
                end
                recommendations[#recommendations + 1] = {
                    role = role,
                    classFile = candidate.classFile,
                    spec = title(candidate.spec),
                    label = title(candidate.spec) .. " " .. (CLASS_NAMES[candidate.classFile] or candidate.classFile),
                    rank = candidate.rank,
                    score = candidate.score,
                    acquisition = acquisition,
                    replacedRole = replacedRole,
                    reason = acquisition:lower() .. "; fills " .. role:lower() .. " need and supports "
                        .. KWR.Compositions:Get(archetype).name,
                }
                existing[candidate.classFile .. ":" .. candidate.spec] = 1
            end
        end
    end
    table.sort(recommendations, function(a, b)
        local order = { TANK = 1, HEALER = 2, DAMAGER = 3 }
        if a.role ~= b.role then return order[a.role] < order[b.role] end
        return a.score > b.score
    end)
    local action
    if totalNeeds == 0 and openSlots == 0 then
        action = "Roster complete: confirm roles, voice, target caller, and first-map assignments."
    elseif replacementsNeeded > 0 then
        action = "Fill " .. tostring(openSlots) .. " open slot" .. (openSlots == 1 and "" or "s")
            .. ", then replace " .. tostring(replacementsNeeded)
            .. " excess role" .. (replacementsNeeded == 1 and "" or "s")
            .. " to reach " .. roleText(needs) .. "."
    else
        action = "Recruit " .. roleText(needs) .. "."
    end
    local needText = roleText(needs)
    if replacementsNeeded > 0 then
        needText = needText .. " | " .. tostring(replacementsNeeded) .. " replacement"
            .. (replacementsNeeded == 1 and "" or "s") .. " required"
    end
    local reason = "Current roster best aligns with " .. KWR.Compositions:Get(archetype).name .. "."
    if tierMatch and tierMatch.qualified then
        reason = tierMatch.confidence .. " " .. tierMatch.tier .. " composition match: "
            .. tierMatch.name .. ". " .. tierMatch.win
    end
    return {
        targetSize = TARGET_SIZE,
        players = #roster,
        openSlots = openSlots,
        complete = openSlots == 0 and needs.TANK == 0 and needs.HEALER == 0 and needs.DAMAGER == 0,
        needs = needs,
        overages = overages,
        replacementsNeeded = replacementsNeeded,
        needText = needText,
        summary = summary,
        archetypeID = archetype,
        archetype = KWR.Compositions:Get(archetype),
        tierMatch = KWR.Util:Copy(tierMatch),
        recommendations = recommendations,
        positioning = KWR.Util:Copy(POSITIONING),
        action = action,
        reason = reason,
    }
end

KWR:RegisterModule("FormationAdvisor", FormationAdvisor)
