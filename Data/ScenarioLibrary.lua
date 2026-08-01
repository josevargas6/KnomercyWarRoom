local _, KWR = ...

local ScenarioLibrary = {}
KWR.ScenarioLibrary = ScenarioLibrary

local PHASES = { "OPENING", "STABILIZE", "PRESSURE", "RECOVERY", "ENDGAME" }
local PRESSURES = { "QUIET", "SINGLE", "SPLIT", "WIPE" }
local SHAPES = { "FAVORABLE", "UNFAVORABLE" }

local MAP_ACTIONS = {
    ARATHI = {
        OPENING = "Secure home, spin Blacksmith, and threaten the favorable outer node.",
        STABILIZE = "Plant weighted defenders, keep a mobile floater, and preserve six for the decisive fight.",
        PRESSURE = "Show Blacksmith pressure while the strike team attacks the weakest outer defender.",
        RECOVERY = "Regroup, create one numbers advantage, capture the recoverable outer node, then stabilize.",
        ENDGAME = "Defend the minimum winning bases and abandon road fights that cannot change the clock.",
    },
    GILNEAS = {
        OPENING = "Secure home and commit decisive numbers to Waterworks with one conditional pressure scout.",
        STABILIZE = "Hold two with early incoming calls and one response route.",
        PRESSURE = "Show Waterworks while a compact control team tests the weaker side node.",
        RECOVERY = "Regroup off the road and capture one isolated spinner with synchronized control.",
        ENDGAME = "Protect two-base scoring and refuse an unnecessary third-base chase.",
    },
    DEEPWIND = {
        OPENING = "Secure home and one flank while the central team and named floater remain connected.",
        STABILIZE = "Defend three with a mobile reserve instead of scattering across five equal fights.",
        PRESSURE = "Pull defenders central, then strike the weak outside lane.",
        RECOVERY = "Collapse onto one recoverable flank and rebuild a three-node response triangle.",
        ENDGAME = "Defend the scoring minimum and rotate before simultaneous outer assaults connect.",
    },
    EOTS = {
        OPENING = "Plant two tower sitters, control mid with four, and pressure an enemy tower with four.",
        STABILIZE = "Preserve tower score first and value the flag only at useful tower ownership.",
        PRESSURE = "Threaten the flag while the strike team forces an enemy-tower response.",
        RECOVERY = "Recover a tower before investing in a low-value flag delivery.",
        ENDGAME = "Calculate flag value against the tower clock and protect only the scoring requirement.",
    },
    WSG = {
        OPENING = "Name the carrier route, escort, home peel, and one grouped return team.",
        STABILIZE = "Protect our carrier, scout enemy offense, and assemble one synchronized return.",
        PRESSURE = "Control enemy healers and push the stacked carrier as a single wave.",
        RECOVERY = "Stop trickling, regroup offense, and restore carrier peel before the next return attempt.",
        ENDGAME = "Protect the winning flag state and synchronize return with an immediate capture.",
    },
    TWINPEAKS = {
        OPENING = "Own one carrier route, deny the enemy approach, and keep offense grouped.",
        STABILIZE = "Bunker our carrier without abandoning route vision or return pressure.",
        PRESSURE = "Force the enemy carrier through a controlled choke with healer control ready.",
        RECOVERY = "Regroup at the route, rebuild peel, then push one complete return wave.",
        ENDGAME = "Preserve carrier safety and refuse unrelated mid kills.",
    },
    TEMPLE = {
        OPENING = "Assign four pickup lanes, keep healers central, and converge into supported scoring space.",
        STABILIZE = "Spread carriers enough to avoid shared pressure while maintaining center support.",
        PRESSURE = "Delete the most actionable enemy carrier and pre-position the replacement pickup.",
        RECOVERY = "Recover loose orbs as a group and rebuild center control before stacking carriers.",
        ENDGAME = "Protect the highest-value carrier and deny the next enemy pickup.",
    },
    SILVERSHARD = {
        OPENING = "Split into named cart groups with one mobile response player.",
        STABILIZE = "Escort scoring carts and rotate before completed routes consume players.",
        PRESSURE = "Delay the enemy turn-in while reinforcing the shortest recoverable cart.",
        RECOVERY = "Abandon unrecoverable routes, regroup on the best score trade, and arrive early.",
        ENDGAME = "Commit only to carts that can alter the final score.",
    },
    DEEPHAUL = {
        OPENING = "Commit six to escort and four to grouped enemy-cart delay.",
        STABILIZE = "Keep both carts covered before contesting Crystal.",
        PRESSURE = "Turn the enemy cart while the escort preserves friendly progress.",
        RECOVERY = "Regroup the delay team and reverse enemy progress before any secondary fight.",
        ENDGAME = "Protect the decisive cart distance and ignore Crystal unless it changes the race.",
    },
    SEETHING = {
        OPENING = "Send mobile scouts to reveal spawns while the main group remains intact.",
        STABILIZE = "Protect the active channel and leave exhausted nodes immediately.",
        PRESSURE = "Deny one enemy channel while pre-rotating toward the next public spawn.",
        RECOVERY = "Regroup for the next spawn instead of feeding into completed nodes.",
        ENDGAME = "Contest only deposits that can change the final resource race.",
    },
}

local MAP_COUNTERPLAY = {
    ARATHI = {
        counter = "Enemy stacks Blacksmith while stealth pressure attacks an outer node.",
        response = "Spin Blacksmith with minimum durable presence; keep one outer defender and send the compact strike team to the exposed lane.",
    },
    GILNEAS = {
        counter = "Enemy overloads Waterworks and tries to isolate the home defender.",
        response = "Preserve home coverage, contest Waterworks only with synchronized numbers, and pressure the abandoned third base.",
    },
    DEEPWIND = {
        counter = "Enemy creates simultaneous outer-node pressure around a central anchor.",
        response = "Maintain a three-node response triangle and trade the farthest exposed node instead of scattering five ways.",
    },
    EOTS = {
        counter = "Enemy uses mid pressure to pull both tower defenders.",
        response = "Keep tower sitters planted, value the flag by tower count, and send only the named strike group to the weak enemy tower.",
    },
    WSG = {
        counter = "Enemy bunkers its carrier and sends staggered control into our escort.",
        response = "Stop trickling, rebuild one return wave, preserve our carrier peel, and commit on a real stack or resource window.",
    },
    TWINPEAKS = {
        counter = "Enemy controls the carrier choke and splits healers between bunker and intercept.",
        response = "Choose one route, deny the intercept group, and push a synchronized return only after peel coverage is confirmed.",
    },
    TEMPLE = {
        counter = "Enemy stacks center pressure while rotating fresh orb replacements.",
        response = "Spread friendly carriers, delete one actionable enemy carrier, and pre-position the replacement pickup before committing.",
    },
    SILVERSHARD = {
        counter = "Enemy abandons a low-value cart to create numbers on the next junction.",
        response = "Leave completed or unrecoverable routes early and reinforce only carts that can still change the projected score.",
    },
    DEEPHAUL = {
        counter = "Enemy escorts with a bunker group while feeding delay into our cart.",
        response = "Keep the delay team grouped, preserve friendly cart presence, and contest Crystal only when both cart obligations are covered.",
    },
    SEETHING = {
        counter = "Enemy channels one node while pre-rotating mobile players to the next spawn.",
        response = "Do not feed a completed node; preserve the main group and contest the next public spawn with an arrival advantage.",
    },
}

local function modifier(pressure, shape, hotspot)
    local location = hotspot and hotspot.label or "the scoring objective"
    if pressure == "WIPE" then
        return " Stop movement, regroup the resurrection wave, and do not trickle."
    elseif pressure == "SPLIT" then
        return " Protect the real scoring requirement and trade the least valuable exposed objective."
    elseif pressure == "SINGLE" then
        return " Reinforce " .. location .. " from the nearest floater without stripping every defender."
    elseif shape == "UNFAVORABLE" then
        return " Avoid their preferred full-team fight; use split pressure, spacing, and route timing."
    end
    return " Keep initiative with a compact strike team while defenders confirm coverage."
end

local function objectiveRows(snapshot)
    local friendly, enemy, available = {}, {}, {}
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        if row.owner == "FRIENDLY" then friendly[#friendly + 1] = row.label
        elseif row.owner == "ENEMY" then enemy[#enemy + 1] = row.label
        else available[#available + 1] = row.label end
    end
    return friendly, enemy, available
end

local function firstPriority(definition, candidates)
    local present = {}
    for _, candidate in ipairs(candidates or {}) do present[candidate] = true end
    for _, location in ipairs(definition and definition.priorities or {}) do
        if present[location] then return location end
    end
    return candidates and candidates[1]
end

local function objectiveDecision(snapshot, prediction, phase)
    local kind = snapshot.context.kind
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local friendly, enemy, available = objectiveRows(snapshot)
    local decision = {
        intent = phase,
        target = nil,
        protect = friendly[1],
        success = nil,
        abort = nil,
    }
    if kind == "NODE" or kind == "HYBRID" then
        decision.target = firstPriority(definition, enemy)
            or firstPriority(definition, available)
        if prediction.status == "WIN" then
            decision.verb = "HOLD"
            decision.target = #friendly > 0 and table.concat(friendly, " + ")
                or "winning objectives"
            decision.success = "winning objective count remains controlled"
            decision.abort = "two held objectives become contested together"
        else
            decision.verb = "TAKE"
            decision.success = decision.target and ("capture " .. decision.target) or "stop enemy scoring"
            decision.abort = "the target is reinforced before the grouped capture window"
        end
    elseif kind == "FLAG" then
        local friendlyCarrier, enemyCarrier
        for _, carrier in ipairs(snapshot.objectives and snapshot.objectives.carriers or {}) do
            if carrier.owner == "FRIENDLY" then friendlyCarrier = carrier
            elseif carrier.owner == "ENEMY" then enemyCarrier = carrier end
        end
        decision.verb = enemyCarrier and "RETURN" or "ESCORT"
        decision.target = enemyCarrier and enemyCarrier.player
            or (friendlyCarrier and friendlyCarrier.player or "flag")
        decision.protect = friendlyCarrier and friendlyCarrier.player or nil
        decision.success = enemyCarrier and "return and immediate capture" or "secure flag pickup and route"
        decision.abort = "offense is split or carrier peel is uncovered"
    elseif kind == "ORB" then
        decision.verb = "DENY"
        decision.target = "enemy carrier"
        decision.protect = "highest-value friendly carrier"
        decision.success = "recover the loose orb into supported scoring space"
        decision.abort = "the target gains major defenses away from the next pickup"
    elseif kind == "CART" then
        decision.verb = prediction.status == "LOSE" and "TURN" or "ESCORT"
        decision.target = prediction.status == "LOSE" and "enemy cart" or "scoring cart"
        decision.protect = "friendly cart presence"
        decision.success = "change the cart race before the next junction"
        decision.abort = "the route can no longer alter the projected score"
    elseif kind == "RESOURCE" then
        decision.verb = "CAP"
        decision.target = "next active node"
        decision.protect = "channel"
        decision.success = "complete the resource channel"
        decision.abort = "the node is exhausted or another spawn becomes decisive"
    end
    local prefix = decision.verb and decision.target
        and (decision.verb .. " " .. decision.target .. ". ") or ""
    return decision, prefix
end

local function responseContract(snapshot, phase, pressure, shape, decision, strategy)
    local kind = snapshot.context.kind
    local mode = strategy.recommendationMode or "HOLD"
    local selected = strategy.selectedAction or {}
    local playersNeeded = mode == "HOLD" and 2
        or (mode == "ROTATE" and 3
        or (mode == "TEAMFIGHT" and 6
        or (mode == "SPLIT" and 3 or 4)))
    local rolesNeeded = kind == "FLAG"
        and { "carrier support", "return control", "healer" }
        or (kind == "ORB"
            and { "carrier", "pickup replacement", "healer" }
        or (kind == "CART"
            and { "cart presence", "delay", "healer" }
        or (kind == "RESOURCE"
            and { "channel control", "mobile scout", "healer" }
        or { "defender", "floater", "strike pressure" })))
    local reviewed = MAP_COUNTERPLAY[snapshot.context.mapKey]
    local likelyCounter = reviewed and reviewed.counter
        or (pressure == "SPLIT"
        and "Enemy trades the opposite objective."
        or (shape == "UNFAVORABLE"
            and "Enemy commits its preferred full-team fight."
        or (mode == "HOLD"
            and "Enemy creates simultaneous pressure."
        or "Enemy reinforces the called objective.")))
    local counterResponse = reviewed and reviewed.response
        or (pressure == "SPLIT"
        and "Preserve the scoring minimum and release only the named reserve."
        or (shape == "UNFAVORABLE"
            and "Refuse the full-team shape; widen pressure and use route timing."
        or (mode == "HOLD"
            and "Keep primary defenders planted and send the response reserve."
        or "Abort on reinforcement disadvantage and take the exposed lane.")))
    return {
        trigger = table.concat({ phase, pressure, shape }, " / "),
        requiredEvidence = {
            "current score and win path",
            "objective ownership",
            "friendly coverage",
            mode == "HOLD" and "defender confirmation"
                or "arrival or pressure advantage",
        },
        playersNeeded = playersNeeded,
        rolesNeeded = rolesNeeded,
        playersWhoStay = {
            kind == "NODE" or kind == "HYBRID"
                and "minimum objective defenders"
                or "objective protection group",
            "one response reserve when available",
        },
        success = selected.success or decision.success,
        abort = selected.abort or decision.abort,
        likelyCounter = likelyCounter,
        counterResponse = counterResponse,
        confidenceGate = selected.reversible and "LOW"
            or "MEDIUM",
    }
end

function ScenarioLibrary:Count(mapKey)
    if mapKey then return MAP_ACTIONS[mapKey] and 40 or 0 end
    local count = 0
    for _ in pairs(MAP_ACTIONS) do count = count + 40 end
    return count
end

function ScenarioLibrary:Select(snapshot, prediction, strategy)
    local mapKey = snapshot.context.mapKey
    local actions = MAP_ACTIONS[mapKey]
    if not actions then return nil end
    local score = snapshot.score or {}
    local maxScore = score.max or 0
    local remaining = math.min(score.friendlyNeeded or maxScore, score.enemyNeeded or maxScore)
    local phase = strategy.state == "OPENING" and "OPENING"
        or (maxScore > 0 and remaining <= maxScore * 0.15 and "ENDGAME")
        or (strategy.state == "RECOVERY" and "RECOVERY")
        or (strategy.state == "STABILIZE" and "STABILIZE")
        or "PRESSURE"
    local reporter = snapshot.reporter or {}
    local coverage = reporter.coverage or {}
    local alive = 0
    for _, player in ipairs(snapshot.roster or {}) do
        if not player.dead and player.connected ~= false then alive = alive + 1 end
    end
    local pressure = alive > 0 and alive <= math.max(4, math.floor(#(snapshot.roster or {}) / 2))
        and "WIPE"
        or (#(reporter.pressure or {}) >= 2
            and (reporter.pressure[1].enemy or 0) > 0
            and (reporter.pressure[2].enemy or 0) > 0 and "SPLIT")
        or (reporter.hotspot and (reporter.hotspot.enemy or 0) > 0 and "SINGLE")
        or "QUIET"
    local ourFight = strategy.ourSummary and strategy.ourSummary.tags.teamfight or 0
    local enemyFight = strategy.enemySummary and strategy.enemySummary.tags.teamfight or 0
    local shape = enemyFight > ourFight and "UNFAVORABLE" or "FAVORABLE"
    local decision, directive = objectiveDecision(snapshot, prediction, phase)
    local selected = strategy.selectedAction or {}
    if selected.target then decision.target = selected.target end
    if selected.success then decision.success = selected.success end
    if selected.abort then decision.abort = selected.abort end
    if strategy.recommendationMode == "HOLD" then
        decision.verb = "HOLD"
    elseif strategy.recommendationMode == "ROTATE" then
        decision.verb = "REINFORCE"
    elseif strategy.recommendationMode == "TRADE" then
        decision.verb = "TRADE FOR"
    elseif strategy.recommendationMode == "TEAMFIGHT" then
        decision.verb = "COLLAPSE"
    elseif strategy.recommendationMode == "SPLIT" then
        decision.verb = "SPLIT PRESSURE"
    end
    directive = decision.verb and decision.target
        and (decision.verb .. " " .. decision.target .. ". ") or ""
    local contract = responseContract(
        snapshot, phase, pressure, shape, decision, strategy)
    return {
        id = table.concat({ mapKey, phase, pressure, shape }, "_"),
        phase = phase,
        pressure = pressure,
        shape = shape,
        action = directive .. actions[phase] .. modifier(pressure, shape, reporter.hotspot),
        objectiveDecision = decision,
        responseContract = contract,
        reviewed = true,
        coverage = coverage,
    }
end

KWR:RegisterModule("ScenarioLibrary", ScenarioLibrary)
