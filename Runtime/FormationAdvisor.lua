local _, KWR = ...

local FormationAdvisor = {
    cache = nil,
    cacheHits = 0,
    cacheMisses = 0,
}
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
    "Tank/anchor: front route, inside healer line.",
    "Healers: spread triangle, overlap range, split control exposure.",
    "Ranged: line of sight, crossfire, no stack on healer triangle.",
    "Melee: collapse on the call, then peel or return objective.",
    "Stealth/float: off-angle, report missing, pressure weak objective.",
    "Defender: off flag, deny one-chain free cap.",
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
        local classFile = KWR.Util:Upper(player.classFile, "", 24)
        local spec = KWR.Util:Text(player.spec, "", 32)
        if classFile ~= "" and spec ~= ""
            and spec ~= "Unknown" and spec ~= "Unknown spec" then
            local key = classFile .. ":" .. spec:lower()
            result[key] = (result[key] or 0) + 1
        end
    end
    return result
end

local function tokenParts(token)
    local classFile, spec = tostring(token or ""):match("^([^:]+):(.+)$")
    if not classFile or not spec then return end
    return classFile:upper(), title(spec)
end

local function tokenKey(token)
    local classFile, spec = tokenParts(token)
    if not classFile or not spec then return nil end
    return classFile .. ":" .. spec:lower()
end

local function roleForSpec(classFile, spec)
    local capability = KWR.Capabilities:Resolve(classFile, spec)
    local role = capability and capability.role or KWR.CombatSpells:Role(spec, nil)
    return role or "DAMAGER"
end

local function compRequirements(comp)
    local requirements = {}
    for _, token in ipairs(comp and comp.specs or {}) do
        local classFile, spec = tokenParts(token)
        if classFile and spec then
            requirements[#requirements + 1] = {
                role = roleForSpec(classFile, spec),
                classFile = classFile,
                spec = spec,
                label = spec .. " " .. (CLASS_NAMES[classFile] or classFile),
            }
        end
    end
    return requirements
end

local function compPositioning(comp)
    local positions = {}
    local assignments = comp and comp.assignments
    if type(assignments) ~= "string" or assignments == "" then
        return KWR.Util:Copy(POSITIONING), "POSITIONING KEYS"
    end
    for clause in assignments:gmatch("[^;]+") do
        local text = clause:match("^%s*(.-)%s*$")
        if text and text ~= "" then
            if not text:match("[.!?]$") then text = text .. "." end
            positions[#positions + 1] = text
        end
    end
    return #positions > 0 and positions or KWR.Util:Copy(POSITIONING), "COMP JOBS"
end

local function replaceRolePool(overages)
    return KWR.Util:Copy(overages or {})
end

local function takeReplacementRole(pool)
    for index = #ROLE_ORDER, 1, -1 do
        local role = ROLE_ORDER[index]
        if (pool[role] or 0) > 0 then
            pool[role] = pool[role] - 1
            return role
        end
    end
    return "EXCESS ROLE"
end

local function rosterReplacementCandidates(comp, roster)
    local wanted = {}
    for _, token in ipairs(comp and comp.specs or {}) do
        local key = tokenKey(token)
        if key then wanted[key] = (wanted[key] or 0) + 1 end
    end
    local candidates = {}
    for index, player in ipairs(roster or {}) do
        local classFile = KWR.Util:Upper(player.classFile, "", 24)
        local spec = KWR.Util:Text(player.spec, "", 32)
        local known = classFile ~= "" and spec ~= ""
            and spec ~= "Unknown" and spec ~= "Unknown spec"
        local key = known and (classFile .. ":" .. spec:lower()) or nil
        if key and (wanted[key] or 0) > 0 then
            wanted[key] = wanted[key] - 1
        else
            candidates[#candidates + 1] = {
                index = index,
                name = KWR.Util:Text(player.shortName or player.name, "Unknown", 64),
                role = KWR.CombatSpells:Role(player.spec, player.role) or "DAMAGER",
                classFile = classFile,
                spec = spec,
                known = known,
            }
        end
    end
    return candidates
end

local function takeReplacementPlayer(candidates, preferredRole, fallbackRole)
    local bestIndex, bestScore
    for index, candidate in ipairs(candidates or {}) do
        local score = 30
        if preferredRole and candidate.role == preferredRole then
            score = 0
        elseif fallbackRole and fallbackRole ~= "EXCESS ROLE"
            and candidate.role == fallbackRole then
            score = 10
        elseif candidate.role == "DAMAGER" then
            score = 20
        end
        if not candidate.known then score = score - 1 end
        if not bestScore or score < bestScore then
            bestIndex, bestScore = index, score
        end
    end
    return bestIndex and table.remove(candidates, bestIndex) or nil
end

local function targetRecommendations(comp, roster, openSlots, overages, needs)
    local missing = {}
    local existing = existingSpecs(roster)
    for targetOrder, token in ipairs(comp and comp.specs or {}) do
        local key = tokenKey(token)
        if key and (existing[key] or 0) > 0 then
            existing[key] = existing[key] - 1
        else
            local classFile, spec = tokenParts(token)
            if classFile and spec then
                missing[#missing + 1] = {
                    targetOrder = targetOrder,
                    role = roleForSpec(classFile, spec),
                    classFile = classFile,
                    spec = spec,
                    label = spec .. " " .. (CLASS_NAMES[classFile] or classFile),
                }
            end
        end
    end
    local remainingOpenSlots = openSlots
    local roleNeeds = KWR.Util:Copy(needs or {})
    for _, requirement in ipairs(missing) do
        if remainingOpenSlots > 0 and (roleNeeds[requirement.role] or 0) > 0 then
            requirement.open = true
            remainingOpenSlots = remainingOpenSlots - 1
            roleNeeds[requirement.role] = roleNeeds[requirement.role] - 1
        end
    end
    for _, requirement in ipairs(missing) do
        if remainingOpenSlots > 0 and not requirement.open then
            requirement.open = true
            remainingOpenSlots = remainingOpenSlots - 1
        end
    end
    local recommendations = {}
    local replacementPool = replaceRolePool(overages)
    local replacementCandidates = rosterReplacementCandidates(comp, roster)
    for _, requirement in ipairs(missing) do
        local acquisition, replacedRole, replaceName, replacement
        if requirement.open then
            acquisition = "OPEN SLOT"
        else
            local fallbackRole = takeReplacementRole(replacementPool)
            replacement = takeReplacementPlayer(replacementCandidates,
                requirement.role, fallbackRole)
            replacedRole = replacement and replacement.role or fallbackRole
            replaceName = replacement and replacement.name or nil
            acquisition = "REPLACE " .. tostring(replaceName or replacedRole)
        end
        recommendations[#recommendations + 1] = {
            targetOrder = requirement.targetOrder,
            role = requirement.role,
            classFile = requirement.classFile,
            spec = requirement.spec,
            label = requirement.label,
            acquisition = acquisition,
            replacedRole = replacedRole,
            replaceName = replaceName,
            replaceSpec = replacement and replacement.spec or nil,
            reason = requirement.open
                and ("Open slot; recruit " .. requirement.label .. " for the selected "
                    .. tostring(comp.name or "meta build") .. ".")
                or ("Replace " .. tostring(replaceName or replacedRole) .. " with "
                    .. requirement.label .. " for the selected "
                    .. tostring(comp.name or "meta build") .. "."),
        }
    end
    table.sort(recommendations, function(a, b)
        local aOpen = a.acquisition == "OPEN SLOT"
        local bOpen = b.acquisition == "OPEN SLOT"
        if aOpen ~= bOpen then return aOpen end
        return (a.targetOrder or 99) < (b.targetOrder or 99)
    end)
    return recommendations
end

local function hybridComp(archetype)
    local profile = KWR.Compositions:Get(archetype) or KWR.Compositions:Get("BALANCED") or {}
    return {
        id = "HYBRID_" .. tostring(archetype or "BALANCED"),
        tier = "HYBRID",
        name = (profile.name or "Balanced Team Fight") .. " Field Shell",
        win = profile.description or "Work from the roster you have and stabilize the core roles first.",
        assignments = "Use flexible capability-weighted jobs until the roster core is stable.",
        counter = "Do not force a reviewed shell before the roster core is real.",
        source = "AUTO_HYBRID",
        synthetic = true,
    }
end

local function currentCompRead(tierMatch, archetype)
    if tierMatch and tierMatch.qualified then
        return KWR.Compositions:FindTier(tierMatch.id) or KWR.Util:Copy(tierMatch), "TIER_MATCH"
    end
    return hybridComp(archetype), "ARCHETYPE"
end

local function autoBuildTarget(availableComps, roster, mapKey)
    local actual = existingSpecs(roster)
    local best
    for _, comp in ipairs(availableComps or {}) do
        local wanted = 0
        local matched = 0
        for _, token in ipairs(comp.specs or {}) do
            wanted = wanted + 1
            local key = tokenKey(token)
            if key and (actual[key] or 0) > 0 then
                matched = matched + 1
                actual[key] = actual[key] - 1
            end
        end
        for _, token in ipairs(comp.specs or {}) do
            local key = tokenKey(token)
            if key and actual[key] ~= nil then
                actual[key] = actual[key] + math.min(actual[key] >= 0 and 0 or 0, 0)
            end
        end
        local score = (matched * 100)
            + ((comp.mapFit == true or mapKey == "WORLD") and 20 or 0)
            + ((comp.mapCount or 0) * 0.1)
        if not best or score > best.score
            or (score == best.score and tostring(comp.id) < tostring(best.id)) then
            best = {
                comp = comp,
                matched = matched,
                score = score,
            }
        end
        actual = existingSpecs(roster)
    end
    return best
end

local function resolveBuildTarget(snapshot, tierMatch, archetype)
    local mapKey = snapshot.context and snapshot.context.mapKey or "WORLD"
    local availableComps = KWR.Compositions:BuildTargets(mapKey)
    local selectedID = KWR.db.profile.formation
        and KWR.db.profile.formation.selectedCompID or nil
    local selectedComp
    if selectedID then
        for _, candidate in ipairs(availableComps) do
            if candidate.id == selectedID then
                selectedComp = candidate
                break
            end
        end
    end
    if selectedComp then
        return KWR.Util:Copy(selectedComp), availableComps, "SELECTED", selectedID
    end
    if tierMatch and tierMatch.qualified then
        local current = KWR.Compositions:FindTier(tierMatch.id) or KWR.Util:Copy(tierMatch)
        return current, availableComps, "CURRENT_ROSTER", nil
    end
    local autoChoice = autoBuildTarget(availableComps, snapshot.roster or {}, mapKey)
    if not autoChoice then
        return nil, availableComps, "HYBRID", nil
    end
    return KWR.Util:Copy(autoChoice.comp), availableComps, "AUTO", nil
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

local function formationCompLabel(comp, fallback)
    if type(comp) ~= "table" then
        return fallback or "Balanced Team Fight"
    end
    local tier = KWR.Util:Text(comp.tier, "", 16)
    local name = KWR.Util:Text(comp.name, fallback or "Balanced Team Fight", 96)
    return tier ~= "" and (tier .. " " .. name) or name
end

local function formationSignature(snapshot)
    local context = snapshot and snapshot.context or {}
    local profile = KWR.db and KWR.db.profile and KWR.db.profile.formation or {}
    local parts = {
        KWR.Util:Text(context.mapKey, "WORLD", 32),
        KWR.Util:Text(profile.selectedCompID, "AUTO", 64),
    }
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        parts[#parts + 1] = table.concat({
            KWR.Util:Text(player.guid or player.name, "?", 96),
            KWR.Util:Text(player.classFile, "UNKNOWN", 24),
            KWR.Util:Text(player.spec, "Unknown", 48),
            KWR.Util:Text(player.role, "NONE", 16),
            player.dead == true and "DEAD" or "ALIVE",
            player.connected == false and "OFFLINE" or "ONLINE",
        }, ":")
    end
    table.sort(parts)
    return table.concat(parts, "\031")
end

function FormationAdvisor:Evaluate(snapshot)
    local signature = formationSignature(snapshot)
    if self.cache and self.cache.signature == signature then
        self.cacheHits = self.cacheHits + 1
        return KWR.Util:Copy(self.cache.result)
    end
    self.cacheMisses = self.cacheMisses + 1
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
    local currentComp, currentCompSource = currentCompRead(tierMatch, archetype)
    local buildTarget, availableComps, buildTargetSource, selectedCompID =
        resolveBuildTarget(snapshot, tierMatch, archetype)
    local recommendations = {}
    if buildTarget and buildTarget.specs and #buildTarget.specs > 0 then
        recommendations = targetRecommendations(buildTarget, roster, openSlots, overages, needs)
    end
    if #recommendations == 0 then
        local existing = existingSpecs(roster)
        local remainingOpenSlots = openSlots
        local replacementPool = replaceRolePool(overages)
        local replacementCandidates = rosterReplacementCandidates(nil, roster)
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
                    local acquisition, replacedRole, replaceName, replacement
                    if remainingOpenSlots > 0 then
                        acquisition = "OPEN SLOT"
                        remainingOpenSlots = remainingOpenSlots - 1
                    else
                        replacedRole = takeReplacementRole(replacementPool)
                        replacement = takeReplacementPlayer(replacementCandidates,
                            nil, replacedRole)
                        replaceName = replacement and replacement.name or nil
                        replacedRole = replacement and replacement.role or replacedRole
                        acquisition = "REPLACE " .. tostring(replaceName or replacedRole)
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
                        replaceName = replaceName,
                        replaceSpec = replacement and replacement.spec or nil,
                        reason = replaceName
                            and ("Replace " .. replaceName .. " with " .. title(candidate.spec)
                                .. " " .. (CLASS_NAMES[candidate.classFile] or candidate.classFile)
                                .. " to fill the " .. role:lower() .. " need.")
                            or (acquisition:lower() .. "; fills " .. role:lower()
                                .. " need and supports " .. KWR.Compositions:Get(archetype).name),
                    }
                    existing[candidate.classFile .. ":" .. candidate.spec] = 1
                end
            end
        end
    end
    if buildTargetSource ~= "SELECTED" and buildTargetSource ~= "CURRENT_ROSTER" then
        table.sort(recommendations, function(a, b)
            local order = { TANK = 1, HEALER = 2, DAMAGER = 3 }
            if a.role ~= b.role then return order[a.role] < order[b.role] end
            return (a.score or 0) > (b.score or 0)
        end)
    end
    local targetReplacementCount = 0
    for _, recommendation in ipairs(recommendations) do
        if recommendation.acquisition ~= "OPEN SLOT" then
            targetReplacementCount = targetReplacementCount + 1
        end
    end
    local action
    if totalNeeds == 0 and openSlots == 0 then
        if targetReplacementCount > 0 and recommendations[1] then
            action = recommendations[1].reason
        else
            action = "Roster complete: confirm roles, voice, target caller, and first-map assignments."
        end
    elseif replacementsNeeded > 0 then
        action = "Fill " .. tostring(openSlots) .. " open slot" .. (openSlots == 1 and "" or "s")
            .. ", then replace " .. tostring(replacementsNeeded)
            .. " excess role" .. (replacementsNeeded == 1 and "" or "s")
            .. " to reach " .. roleText(needs) .. "."
    else
        action = "Recruit " .. roleText(needs) .. "."
        if targetReplacementCount > 0 then
            action = action .. " Then make " .. tostring(targetReplacementCount)
                .. " target replacement" .. (targetReplacementCount == 1 and "" or "s") .. "."
        end
    end
    local needText = roleText(needs)
    if replacementsNeeded > 0 then
        needText = needText .. " | " .. tostring(replacementsNeeded) .. " replacement"
            .. (replacementsNeeded == 1 and "" or "s") .. " required"
    end
    local reason = "CURRENT ROSTER: "
        .. formationCompLabel(currentComp, KWR.Compositions:Get(archetype).name)
    if buildTargetSource == "SELECTED" and buildTarget then
        reason = "TARGET BUILD: " .. formationCompLabel(buildTarget, buildTarget.name)
        if tierMatch and tierMatch.qualified and tierMatch.id ~= buildTarget.id then
            reason = reason .. "  |  CURRENT ROSTER: " .. formationCompLabel(tierMatch, tierMatch.name)
        end
    elseif tierMatch and tierMatch.qualified then
        reason = "CURRENT ROSTER: " .. formationCompLabel(tierMatch, tierMatch.name)
    elseif buildTargetSource == "AUTO" and buildTarget then
        reason = "CURRENT ROSTER: "
            .. formationCompLabel(currentComp, "HYBRID")
            .. "  |  AUTO TARGET: " .. formationCompLabel(buildTarget, buildTarget.name)
    elseif buildTargetSource == "HYBRID" then
        reason = "CURRENT ROSTER: "
            .. formationCompLabel(currentComp, "HYBRID")
            .. "  |  AUTO TARGET: HYBRID"
    end
    local positioning, positioningTitle = compPositioning(buildTarget)
    local result = {
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
        currentComp = KWR.Util:Copy(currentComp),
        currentCompSource = currentCompSource,
        tierMatch = KWR.Util:Copy(tierMatch),
        buildTarget = KWR.Util:Copy(buildTarget),
        buildRequirements = compRequirements(buildTarget),
        buildTargetSource = buildTargetSource,
        selectedCompID = selectedCompID,
        availableComps = KWR.Util:Copy(availableComps),
        recommendations = recommendations,
        positioning = positioning,
        positioningTitle = positioningTitle,
        action = action,
        reason = reason,
    }
    self.cache = {
        signature = signature,
        result = KWR.Util:Copy(result),
    }
    return result
end

KWR:RegisterModule("FormationAdvisor", FormationAdvisor)
