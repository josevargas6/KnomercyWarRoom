local _, KWR = ...

local ObjectiveRules = {}
KWR.ObjectiveRules = ObjectiveRules

local DEFAULT_RULE = {
    family = "WORLD",
    defenderMinimum = 1,
    responseReserve = 1,
    minimumFight = 4,
    splitThreshold = 8,
    reinforceAtEnemy = 2,
    extraDefendersAtEnemy = 1,
    maxDefenders = 3,
    anchorMinimum = 1,
    legalActions = {
        HOLD = true,
    },
}

local KIND_RULES = {
    NODE = {
        family = "NODE",
        defenderMinimum = 1,
        responseReserve = 1,
        minimumFight = 5,
        splitThreshold = 8,
        reinforceAtEnemy = 2,
        extraDefendersAtEnemy = 1,
        maxDefenders = 3,
        legalActions = {
            HOLD = true,
            ROTATE = true,
            TRADE = true,
            TEAMFIGHT = true,
            SPLIT = true,
        },
    },
    HYBRID = {
        family = "HYBRID",
        defenderMinimum = 1,
        responseReserve = 1,
        minimumFight = 4,
        splitThreshold = 8,
        reinforceAtEnemy = 2,
        extraDefendersAtEnemy = 1,
        maxDefenders = 3,
        legalActions = {
            HOLD = true,
            ROTATE = true,
            TRADE = true,
            TEAMFIGHT = true,
            SPLIT = true,
        },
    },
    FLAG = {
        family = "FLAG",
        defenderMinimum = 2,
        responseReserve = 1,
        minimumFight = 5,
        splitThreshold = 10,
        reinforceAtEnemy = 1,
        extraDefendersAtEnemy = 1,
        maxDefenders = 4,
        anchorMinimum = 2,
        legalActions = {
            HOLD = true,
            ROTATE = true,
            TEAMFIGHT = true,
        },
    },
    ORB = {
        family = "ORB",
        defenderMinimum = 1,
        responseReserve = 1,
        minimumFight = 6,
        splitThreshold = 10,
        reinforceAtEnemy = 2,
        extraDefendersAtEnemy = 1,
        maxDefenders = 3,
        legalActions = {
            HOLD = true,
            ROTATE = true,
            TEAMFIGHT = true,
        },
    },
    CART = {
        family = "CART",
        defenderMinimum = 1,
        responseReserve = 1,
        minimumFight = 5,
        splitThreshold = 10,
        reinforceAtEnemy = 2,
        extraDefendersAtEnemy = 1,
        maxDefenders = 3,
        legalActions = {
            HOLD = true,
            ROTATE = true,
            TRADE = true,
            TEAMFIGHT = true,
        },
    },
    RESOURCE = {
        family = "RESOURCE",
        defenderMinimum = 1,
        responseReserve = 2,
        minimumFight = 6,
        splitThreshold = 8,
        reinforceAtEnemy = 2,
        extraDefendersAtEnemy = 1,
        maxDefenders = 3,
        legalActions = {
            HOLD = true,
            ROTATE = true,
            TEAMFIGHT = true,
            SPLIT = true,
        },
    },
}

local MAP_RULES = {
    ARATHI = {
        anchorMinimum = 1,
        responseReserve = 1,
        minimumFight = 5,
    },
    GILNEAS = {
        minimumFight = 5,
        splitThreshold = 8,
    },
    DEEPWIND = {
        anchorMinimum = 1,
        responseReserve = 1,
        minimumFight = 5,
    },
    EOTS = {
        minimumFight = 4,
        reinforceAtEnemy = 1,
    },
    WSG = {
        anchorMinimum = 2,
        minimumFight = 5,
    },
    TWINPEAKS = {
        anchorMinimum = 2,
        minimumFight = 5,
    },
    TEMPLE = {
        responseReserve = 1,
        minimumFight = 6,
    },
    SILVERSHARD = {
        responseReserve = 1,
        minimumFight = 5,
    },
    DEEPHAUL = {
        responseReserve = 1,
        minimumFight = 5,
    },
    SEETHING = {
        responseReserve = 2,
        minimumFight = 6,
    },
}

local function mergeTable(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            target[key] = target[key] or {}
            mergeTable(target[key], value)
        else
            target[key] = value
        end
    end
    return target
end

local function summarizeObjectives(snapshot)
    local summary = {
        friendly = 0,
        enemy = 0,
        neutral = 0,
    }
    for _, row in ipairs(snapshot and snapshot.objectives and snapshot.objectives.rows or {}) do
        if row.owner == "FRIENDLY" then
            summary.friendly = summary.friendly + 1
        elseif row.owner == "ENEMY" then
            summary.enemy = summary.enemy + 1
        else
            summary.neutral = summary.neutral + 1
        end
    end
    return summary
end

function ObjectiveRules:Get(mapKey)
    local definition = KWR.Maps:Get(mapKey)
    local kindRule = definition and KIND_RULES[definition.kind] or DEFAULT_RULE
    local rule = mergeTable({}, DEFAULT_RULE)
    mergeTable(rule, kindRule)
    mergeTable(rule, MAP_RULES[mapKey] or {})
    rule.mapKey = mapKey
    rule.kind = definition and definition.kind or "WORLD"
    rule.title = definition and definition.title or "World"
    return rule
end

function ObjectiveRules:RequiredObjectivesToWin(snapshot, resolved)
    resolved = resolved or self:Get(snapshot and snapshot.context and snapshot.context.mapKey)
    local definition = KWR.Maps:Get(resolved.mapKey)
    if resolved.kind == "NODE" or resolved.kind == "HYBRID" then
        return math.max(
            resolved.stableMinimum or 2,
            math.ceil((definition and definition.maxObjectives or 1) / 2))
    end
    if resolved.kind == "FLAG" then return 1 end
    if resolved.kind == "ORB" then return 2 end
    return 1
end

function ObjectiveRules:IsActionLegal(snapshot, actionID, resolved)
    resolved = resolved or self:Get(snapshot and snapshot.context and snapshot.context.mapKey)
    if not resolved.legalActions[actionID] then
        return false, "map family blocks " .. tostring(actionID)
    end
    if actionID == "HOLD" then return true end
    local summary = summarizeObjectives(snapshot or {})
    local reporter = snapshot and snapshot.reporter or {}
    local livePlayers = 0
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        if not player.dead and player.connected ~= false then
            livePlayers = livePlayers + 1
        end
    end
    if actionID == "TRADE" then
        if summary.enemy + summary.neutral <= 0 then
            return false, "no tradable objective exists"
        end
        return true
    end
    if actionID == "ROTATE" then
        if not reporter.hotspot and summary.friendly <= 0 then
            return false, "no friendly objective or hotspot needs a rotation"
        end
        return true
    end
    if actionID == "TEAMFIGHT" then
        if not reporter.hotspot and #(snapshot and snapshot.enemies or {}) <= 0 then
            return false, "no qualified local fight exists"
        end
        return true
    end
    if actionID == "SPLIT" then
        if livePlayers < (resolved.splitThreshold or 8) then
            return false, "not enough live players for a split"
        end
        if summary.enemy + summary.neutral < 2 then
            return false, "only one actionable lane exists"
        end
        return true
    end
    return true
end

function ObjectiveRules:Resolve(snapshot)
    local context = snapshot and snapshot.context or {}
    local resolved = self:Get(context.mapKey)
    local definition = KWR.Maps:Get(context.mapKey)
    local objectiveSummary = summarizeObjectives(snapshot or {})
    resolved.anchorObjective = definition and definition.home
        and definition.home[context.team and context.team.faction]
        or nil
    resolved.primaryObjective = definition and definition.priorities
        and definition.priorities[1] or nil
    resolved.minimumControlToWin = self:RequiredObjectivesToWin(snapshot, resolved)
    resolved.objectives = objectiveSummary
    resolved.legalActionList = {}
    resolved.impossibleActionList = {}
    for actionID in pairs(resolved.legalActions or {}) do
        local allowed = self:IsActionLegal(snapshot, actionID, resolved)
        if allowed then
            resolved.legalActionList[#resolved.legalActionList + 1] = actionID
        else
            resolved.impossibleActionList[#resolved.impossibleActionList + 1] = actionID
        end
    end
    table.sort(resolved.legalActionList)
    table.sort(resolved.impossibleActionList)
    return resolved
end

function ObjectiveRules:MinimumDefenders(snapshot, objectiveLabel, pressure)
    local resolved = self:Resolve(snapshot)
    local required = resolved.defenderMinimum or 1
    objectiveLabel = KWR.Util:Text(objectiveLabel, "", 48)
    pressure = pressure or {}
    if objectiveLabel ~= "" and objectiveLabel == resolved.anchorObjective then
        required = math.max(required, resolved.anchorMinimum or required)
    end
    local enemy = KWR.Util:Number(pressure.enemy, 0) or 0
    if enemy >= (resolved.reinforceAtEnemy or 2) then
        required = required + (resolved.extraDefendersAtEnemy or 1)
    end
    if enemy >= ((resolved.reinforceAtEnemy or 2) + 2) then
        required = required + 1
    end
    return KWR.Util:Clamp(required, 1, resolved.maxDefenders or 4)
end

-- Apply only an observed, typed transition.  This is intentionally a pure
-- function: ObjectiveIntel owns ingestion and a widget snapshot remains the
-- authority for rehydration after missed messages.  Unsupported event/family
-- pairs therefore stay UNKNOWN instead of borrowing a rule from another map.
function ObjectiveRules:Transition(previous, event, context)
    previous = type(previous) == "table" and previous or {}
    event = type(event) == "table" and event or {}
    local definition = KWR.Maps:Get(context and context.mapKey)
    local family = definition and definition.kind or "WORLD"
    local kind = KWR.Util:Upper(event.kind, "", 32)
    local objective = KWR.Util:Text(event.objective or previous.label, "", 64)
    local observedAt = KWR.Util:Number(event.at, nil)
    local priorObservedAt = KWR.Util:Number(previous.observedAt, nil)
    local base = {
        label = objective ~= "" and objective or nil,
        owner = previous.owner or "UNKNOWN",
        state = previous.state or "UNKNOWN",
        family = family,
        eventKind = kind ~= "" and kind or nil,
        observedAt = observedAt,
        accepted = false,
        reason = "UNSUPPORTED_TRANSITION",
    }
    if objective == "" or kind == "" then
        base.reason = "MISSING_TRANSITION_IDENTITY"
        return base
    end
    if not observedAt or observedAt < 0 or observedAt ~= observedAt or observedAt == math.huge then
        base.reason = "MISSING_TRANSITION_TIME"
        return base
    end
    if priorObservedAt and observedAt < priorObservedAt then
        base.reason = "STALE_TRANSITION"
        return base
    end
    if family == "NODE" or family == "HYBRID" then
        if kind == "ASSAULT" then
            base.state, base.contested, base.pendingState = "CONTESTED", true, "INCOMING"
            base.pendingBy = event.player
            base.accepted, base.reason = true, "OBSERVED_ASSAULT"
        end
    elseif family == "FLAG" then
        if kind == "PICKUP" then
            base.state, base.carrier = "CARRIED", event.player
            base.accepted, base.reason = true, "OBSERVED_PICKUP"
        elseif kind == "FLAG_RETURN" or kind == "FLAG_RESET" then
            base.state, base.carrier = "BASE", nil
            base.accepted, base.reason = true, "OBSERVED_RETURN"
        elseif kind == "FLAG_CAPTURE" then
            base.state, base.carrier = "CAPTURED", nil
            base.capturer = event.player
            base.accepted, base.reason = true, "OBSERVED_CAPTURE"
        end
    elseif family == "ORB" then
        if kind == "PICKUP" then
            base.state, base.carrier = "CARRIED", event.player
            base.accepted, base.reason = true, "OBSERVED_ORB_PICKUP"
        elseif kind == "RETURN" then
            base.state, base.carrier = "AVAILABLE", nil
            base.accepted, base.reason = true, "OBSERVED_ORB_RETURN"
        end
    elseif family == "RESOURCE" then
        if kind == "RESOURCE_SPAWN" then
            base.state, base.accepted, base.reason = "ACTIVE", true, "OBSERVED_RESOURCE_SPAWN"
        elseif kind == "RESOURCE_COLLECTED" then
            base.state, base.collector = "EXHAUSTED", event.player
            base.accepted, base.reason = true, "OBSERVED_RESOURCE_COLLECTION"
        end
    end
    return base
end

KWR:RegisterModule("ObjectiveRules", ObjectiveRules)
