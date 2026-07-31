local _, KWR = ...

local Scorer = {}
KWR.AssignmentScorer = Scorer

local function traitMap(enemy)
    local profile = enemy and enemy.profile
    if (not profile or type(profile.traits) ~= "table")
        and KWR.OpponentModels and KWR.OpponentModels.Describe then
        profile = KWR.OpponentModels:Describe(enemy)
    end
    local result = {}
    for _, trait in ipairs(profile and profile.traits or {}) do
        result[trait.id] = trait
    end
    return result, profile
end

local function noteTags(enemy)
    if enemy and type(enemy.noteTags) == "table" then return enemy.noteTags end
    if enemy and enemy.key and KWR.EnemyIntel and KWR.EnemyIntel.NoteTags then
        return KWR.EnemyIntel:NoteTags(enemy.key)
    end
    return {}
end

function Scorer:Score(friendlyState, problem, snapshot)
    local profile = friendlyState and friendlyState.profile or {}
    local typeRow = KWR.EnemyProblemTypes[problem and problem.type or ""] or {}
    local counterplay = KWR.CounterplayMatrix and KWR.CounterplayMatrix:Resolve(problem and problem.type)
        or nil
    local capability = KWR.Util:Text((counterplay and counterplay.capability)
        or typeRow.capability, "pressure", 32)
    local score = KWR.Util:Number(problem and problem.severity, 0) or 0
    local reasons = {}
    if friendlyState and friendlyState.available == true then
        score = score + 12
        reasons[#reasons + 1] = "+ " .. KWR.Util:Text(friendlyState.name, "Player", 48)
            .. " is available"
    else
        score = score - 200
        reasons[#reasons + 1] = "- player unavailable"
    end
    local fit = KWR.Util:Number(profile[capability], 0) or 0
    score = score + fit
    reasons[#reasons + 1] = "+ " .. KWR.Util:Text(friendlyState and friendlyState.name,
        "Player", 48) .. " has " .. capability .. " profile " .. tostring(math.floor(fit))
    local role = KWR.CombatSpells:Role(problem and problem.enemy and problem.enemy.spec,
        problem and problem.enemy and problem.enemy.role)
    if role == "HEALER" then
        score = score + 14
        reasons[#reasons + 1] = "+ target is healer"
    end
    if problem and problem.objectiveValue then
        local value = KWR.Util:Number(problem.objectiveValue, 0) or 0
        score = score + value * 0.2
        reasons[#reasons + 1] = "+ objective value " .. tostring(math.floor(value))
    end
    if problem and problem.locality == "LOCAL" then
        score = score + 8
        reasons[#reasons + 1] = "+ problem is in the local fight"
    elseif problem and problem.locality == "MAP" then
        score = score - 6
        reasons[#reasons + 1] = "- problem is not locally confirmed"
    end
    if friendlyState and friendlyState.assignment and problem and problem.type == "BASE_UNDER_THREAT" then
        score = score + 8
        reasons[#reasons + 1] = "+ current assignment can protect objective coverage"
    end
    if problem and problem.confidence == "UNKNOWN" then
        local penalty = KWR.ComplianceGate and (KWR.ComplianceGate:Ruleset().unknownPenalty or 12) or 12
        score = score - penalty
        reasons[#reasons + 1] = "- problem state unknown"
    elseif problem and problem.confidence == "INFERRED" then
        score = score - 6
        reasons[#reasons + 1] = "- problem is inferred"
    end
    local drState = problem and problem.drState
    if drState and drState.state == "IMMUNE" then
        score = score - 80
        reasons[#reasons + 1] = "- subdue DR is immune"
    elseif drState and drState.state == "DIMINISHED" then
        score = score - 25
        reasons[#reasons + 1] = "- subdue DR is diminished"
    elseif drState and drState.state == "READY" then
        score = score + 8
        reasons[#reasons + 1] = "+ subdue DR is ready"
    elseif drState and drState.state == "UNKNOWN" then
        score = score - 4
        reasons[#reasons + 1] = "- subdue DR state unknown"
    end
    local weights = KWR.ObjectiveWeights and KWR.ObjectiveWeights:For(snapshot) or {}
    if problem and (problem.type == "KILLABLE_OVEREXTENDED"
        or problem.type == "KILL_TARGET_AVAILABLE") then
        score = score + (weights.killTarget or 0) * 0.15
        reasons[#reasons + 1] = "+ objective context supports kill pressure"
    elseif role == "HEALER" then
        score = score + (weights.healer or 0) * 0.12
        reasons[#reasons + 1] = "+ objective context values healer control"
    end
    local traits = traitMap(problem and problem.enemy)
    if problem and (problem.type == "KILLABLE_OVEREXTENDED"
        or problem.type == "KILL_TARGET_AVAILABLE") then
        if traits.OVEREXTENDS then
            score = score + 7
            reasons[#reasons + 1] = "+ learned model: target overextends"
        end
        if traits.DIES_IN_COMMIT then
            score = score + 6
            reasons[#reasons + 1] = "+ learned model: target dies in commits"
        end
    elseif problem and (problem.type == "FREE_CAST_HEALER"
        or problem.type == "CASTER_HEALER_SUPPORT") then
        if traits.PUNISHABLE_CASTS then
            score = score + 5
            reasons[#reasons + 1] = "+ learned model: punishable casts"
        elseif traits.FREECASTS then
            score = score + 3
            reasons[#reasons + 1] = "+ learned model: repeat freecasts"
        end
    elseif problem and problem.type == "OBJECTIVE_DENIAL" then
        local tags = noteTags(problem.enemy)
        if tags.SPINNER or tags.CARRIER then
            score = score + 5
            reasons[#reasons + 1] = "+ field note: objective threat tag"
        end
    end
    return score, reasons
end

KWR:RegisterModule("AssignmentScorer", Scorer)