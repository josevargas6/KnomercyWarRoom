local _, KWR = ...

local Assignments = {
    integrity = {
        sessionKey = nil,
        records = {},
    },
}
KWR.Assignments = Assignments

local function isClass(player, ...)
    local wanted = { ... }
    for _, classFile in ipairs(wanted) do
        if player.classFile == classFile then return true end
    end
    return false
end

local function selectFirst(roster, used, predicate, allowFallback)
    for index, player in ipairs(roster) do
        if not used[index] and predicate(player) then
            used[index] = true
            return index, player
        end
    end
    if allowFallback then
        for index, player in ipairs(roster) do
            if not used[index] then
                used[index] = true
                return index, player
            end
        end
    end
end

local function effectiveRole(player)
    return KWR.CombatSpells:Role(player.spec, player.role)
end

local function capability(player)
    return KWR.Capabilities:Resolve(player.classFile, player.spec, player.heroTalent) or {
        role = effectiveRole(player),
        range = nil,
        tags = {},
        jobs = {},
    }
end

local function value(player, job)
    local cap = capability(player)
    local tags = cap.tags or {}
    local role = cap.role or effectiveRole(player)
    local score = 0
    local weights = {
        defend = { baseDefense = 48, sustain = 18, stealth = 14, control = 12, peel = 10 },
        spin = { sustain = 42, baseDefense = 22, mobility = 10, control = 10, immunity = 8 },
        fight = { teamfight = 36, burst = 15, pressure = 14, cleave = 14, rot = 13,
            antiHeal = 10, damageSupport = 9, control = 8 },
        float = { rotation = 34, mobility = 28, crossCap = 20, stealth = 16, control = 10 },
        assault = { baseAssault = 38, crossCap = 30, stealth = 22, burst = 12, control = 12 },
        carry = { flagCarry = 52, mobility = 24, sustain = 18 },
        heal = { healing = 50, external = 16, mobility = 10, teamfight = 8 },
    }
    for tag, weight in pairs(weights[job] or {}) do
        if tags[tag] then score = score + weight end
    end
    local preferredJobs = {
        defend = { "DEFENDER", "ANCHOR" },
        spin = { "ANCHOR", "DEFENDER" },
        fight = { "ASSASSIN", "SUPPORT", "HARASSER" },
        float = { "FLOATER", "ROAMER" },
        assault = { "ASSASSIN", "HARASSER" },
        carry = { "CARRIER", "ESCORT" },
        heal = { "SUPPORT", "ESCORT" },
    }
    local ratingWeights = {
        defend = { nodeDefense = 1.0, survivability = 0.8, ccPotential = 0.6 },
        spin = { survivability = 1.0, nodeDefense = 0.8, objectiveUtility = 0.7 },
        fight = { teamfight = 1.0, pressure = 0.8, killConfirm = 0.7 },
        float = { mobility = 1.0, recovery = 0.7, objectiveUtility = 0.6 },
        assault = { splitPush = 1.0, burst = 0.8, ccPotential = 0.7 },
        carry = { flagCarry = 1.0, survivability = 0.8, mobility = 0.7 },
        heal = { recovery = 1.0, manaEndurance = 0.8, peel = 0.7 },
    }
    local preference = 0
    for _, preferred in ipairs(preferredJobs[job] or {}) do
        preference = math.max(preference, KWR.Util:Number(cap.jobs and cap.jobs[preferred], 0))
    end
    -- Capability preferences refine the proven tag model without taking it over.
    score = score + math.min(18, preference * 0.18)
    local ratingScore, ratingWeight = 0, 0
    for rating, weight in pairs(ratingWeights[job] or {}) do
        ratingScore = ratingScore + ((cap.ratings and cap.ratings[rating] or 1) - 1) * weight
        ratingWeight = ratingWeight + weight
    end
    if ratingWeight > 0 then
        score = score + math.min(12, (ratingScore / ratingWeight) * 3)
    end
    if job == "defend" then
        if role == "HEALER" then score = score - 80 end
        if cap.range == "RANGED" then score = score + 12 end
    elseif job == "spin" then
        if role == "TANK" then score = score + 45 end
        if role == "HEALER" then score = score - 25 end
    elseif job == "fight" then
        if role == "HEALER" then score = score + 60 end
        if cap.range == "RANGED" then score = score + 8 end
    elseif job == "carry" and role == "TANK" then
        score = score + 45
    elseif job == "heal" and role == "HEALER" then
        score = score + 60
    end
    return score
end

function Assignments:BattleValue(player, job)
    return value(player or {}, job)
end

local function selectBest(roster, used, job, predicate, allowFallback)
    local bestIndex, bestPlayer, bestScore
    for index, player in ipairs(roster) do
        if not used[index] and (not predicate or predicate(player)) then
            local score = value(player, job)
            if bestScore == nil or score > bestScore
                or (score == bestScore and tostring(player.name) < tostring(bestPlayer.name)) then
                bestIndex, bestPlayer, bestScore = index, player, score
            end
        end
    end
    if not bestPlayer and allowFallback then
        for index, player in ipairs(roster) do
            if not used[index] then
                local score = value(player, job)
                if bestScore == nil or score > bestScore then
                    bestIndex, bestPlayer, bestScore = index, player, score
                end
            end
        end
    end
    if bestIndex then used[bestIndex] = true end
    return bestIndex, bestPlayer, bestScore
end

local function add(result, player, role, location, priority, detail)
    if not player then return end
    local groupRole = effectiveRole(player)
    result[#result + 1] = {
        name = player.name,
        shortName = player.shortName,
        guid = player.guid,
        class = player.class,
        classFile = player.classFile,
        spec = player.spec,
        specID = player.specID,
        specSource = player.specSource,
        evidence = player.evidence,
        groupRole = groupRole,
        role = role,
        location = location,
        priority = priority or 50,
        battleWeight = detail and detail.battleWeight,
        job = detail and detail.job,
        backupRole = detail and detail.backupRole,
        coverageWeight = detail and detail.coverageWeight,
        assignmentConfidence = detail and detail.assignmentConfidence,
        stayCommitted = detail and detail.stayCommitted,
        coverageEffect = detail and detail.coverageEffect,
        reason = detail and detail.reason,
        handoff = detail and detail.handoff,
        abandonIf = detail and detail.abandonIf,
        successCondition = detail and detail.successCondition,
        abortCondition = detail and (detail.abortCondition
            or detail.abandonIf),
        dead = player.dead,
        connected = player.connected,
    }
end

local function remaining(roster, used, result, role, location, priority)
    for index, player in ipairs(roster) do
        if not used[index] then
            used[index] = true
            add(result, player, role, location, priority)
        end
    end
end

local function applyCounterDirectives(assignments, strategy)
    local enemyShape = strategy and strategy.enemyComposition
        and strategy.enemyComposition.id or "BALANCED"
    for _, assignment in ipairs(assignments or {}) do
        local role = assignment.role or ""
        local directive
        if enemyShape == "STEALTH" then
            if role:find("Defender", 1, true)
                or role:find("Float", 1, true) then
                directive = "Pair isolated coverage and report missing stealth."
            end
        elseif enemyShape == "ROT" then
            if role == "Main Fight" or role == "Strike Team" then
                directive = "Commit one short kill window; rotate if it closes."
            end
        elseif enemyShape == "MELEE" then
            if assignment.groupRole == "HEALER"
                or role:find("Peel", 1, true) then
                directive = "Maintain a spread support line and peel first contact."
            end
        elseif enemyShape == "RANGED" then
            if role == "Main Fight" or role == "Strike Team" then
                directive = "Approach through cover as one timed wave."
            end
        elseif enemyShape == "ROTATION" then
            if role:find("Defender", 1, true) then
                directive = "Hold the scoring requirement; do not chase roads."
            elseif role:find("Strike", 1, true)
                or role:find("Float", 1, true) then
                directive = "Trade into the lightly held lane."
            end
        elseif enemyShape == "BUNKER" then
            if role:find("Strike", 1, true)
                or role:find("Float", 1, true) then
                directive = "Threaten a second lane before committing."
            end
        end
        if directive then
            assignment.counterDirective = directive
            assignment.handoff = assignment.handoff
                and (assignment.handoff .. " " .. directive) or directive
        end
    end
end

local function assignBest(roster, used, result, job, role, location, priority, detail, predicate, allowFallback)
    if allowFallback == nil then allowFallback = true end
    local _, player, score = selectBest(roster, used, job, predicate, allowFallback)
    detail = detail or {}
    detail.battleWeight = score
    add(result, player, role, location, priority, detail)
    return player
end

local function assignGroup(roster, used, result, count, role, location, priority, reason)
    local assigned = 0
    while assigned < count do
        local _, player, score = selectBest(roster, used, "fight", nil, false)
        if not player then break end
        add(result, player, role, location, priority, {
            battleWeight = score,
            reason = reason,
        })
        assigned = assigned + 1
    end
end

local function openingNode(roster, definition, context)
    local result, used = {}, {}
    local faction = context and context.team and context.team.faction
    local home = definition.home and definition.home[faction]
        or definition.locations[1] or "Home"
    local key = definition.key
    if key == "EOTS" then
        local friendlyA = faction == "Horde" and "Blood Elf Tower" or "Mage Tower"
        local friendlyB = faction == "Horde" and "Fel Reaver" or "Draenei Ruins"
        local enemyTower = faction == "Horde" and "Draenei Ruins" or "Fel Reaver"
        assignBest(roster, used, result, "defend", "Tower Sitter", friendlyA, 96, {
            reason = "Highest independent defense value protects the first scoring tower.",
            handoff = "Float only after a named replacement confirms coverage.",
        })
        assignBest(roster, used, result, "defend", "Tower Sitter", friendlyB, 95, {
            reason = "Second independent defender preserves the two-tower score floor.",
            handoff = "Join mid only after relief reaches the tower.",
        })
        local midStart = #result
        assignBest(roster, used, result, "heal", "Mid / Flag Control", "Flag", 90, {
            reason = "Mid healer supports flag control while both towers remain covered.",
        }, function(player) return effectiveRole(player) == "HEALER" end, false)
        local midAssigned = #result - midStart
        assignBest(roster, used, result, "heal", "Tower Strike", enemyTower, 89, {
            reason = "Strike healer keeps enemy-tower pressure independent from mid.",
        }, function(player) return effectiveRole(player) == "HEALER" end, false)
        assignGroup(roster, used, result, math.max(0, 4 - midAssigned),
            "Mid / Flag Control", "Flag", 88,
            "Balanced control group spins mid without stripping both towers.")
        remaining(roster, used, result, "Tower Strike", enemyTower, 84)
        return result
    end

    local main = definition.priorities[1] or "Objective"
    if key == "GILNEAS" then main = "Waterworks"
    elseif key == "DEEPWIND" then main = "Market"
    elseif key == "ARATHI" then main = "Blacksmith" end

    if key == "ARATHI" then
        assignBest(roster, used, result, "spin", "Blacksmith Spinner", "Blacksmith", 97, {
            reason = "Highest spin value buys time without consuming the best ranged kill pressure.",
            handoff = "If Blacksmith needs damage, rotate to home and release the ranged defender into Blacksmith.",
            abandonIf = "Leave only when Blacksmith cannot be converted and two safer bases are stable.",
        }, function(player) return effectiveRole(player) ~= "HEALER" end)
    end

    assignBest(roster, used, result, "defend", "Anchor Defender", home, 96, {
        reason = "Best independent defender protects guaranteed opening score.",
        handoff = key == "ARATHI"
            and "If Blacksmith lacks damage, receive the spinner at Stables/Farm, then reinforce Blacksmith."
            or "Leave only after the floater or another named defender confirms relief.",
    })

    if key == "ARATHI" then
        local outer = faction == "Horde" and "Mine" or "Lumber Mill"
        assignBest(roster, used, result, "assault", "Outer Cap / Float", outer, 90, {
            reason = "Mobile capture threat creates a second scoring lane.",
            handoff = "After capture, hold until a weighted defender or floater confirms the handoff.",
            abandonIf = "Cap-and-abandon only when the main fight is decisive and recapture risk is lower than lost team-fight value.",
        })
    elseif key == "GILNEAS" then
        local enemyHome = faction == "Horde" and "Lighthouse" or "Mine"
        assignBest(roster, used, result, "assault", "Enemy-Home Scout", enemyHome, 84, {
            reason = "Pressure scout reports defense and joins Waterworks if the fight is understrength.",
            abandonIf = "Do not remain in an equal or reinforced side fight.",
        })
    elseif key == "DEEPWIND" then
        local flank = faction == "Horde" and "Shrine" or "Ruins"
        assignBest(roster, used, result, "defend", "Flank Defender", flank, 88, {
            reason = "Second reliable defender covers the favorable opening lane.",
            handoff = "Collapse with the floater on a confirmed enemy commitment.",
        })
        assignBest(roster, used, result, "float", "Response Floater", main, 86, {
            reason = "Highest rotation value remains uncommitted for the first real pressure.",
        })
    end
    remaining(roster, used, result, "Main Fight", main, 82)
    return result
end

local function friendlyControlled(snapshot, definition, context)
    local result, seen = {}, {}
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local location = row.label
        if row.owner == "FRIENDLY" and row.state == "CONTROLLED"
            and definition.positions and definition.positions[location] and not seen[location] then
            seen[location] = true
            result[#result + 1] = location
        end
    end
    local faction = context and context.team and context.team.faction
    local home = definition.home and definition.home[faction]
    local rank = {}
    if home then rank[home] = 0 end
    for index, location in ipairs(definition.priorities or {}) do
        if rank[location] == nil then rank[location] = index end
    end
    table.sort(result, function(left, right)
        local leftRank, rightRank = rank[left] or 99, rank[right] or 99
        if leftRank ~= rightRank then return leftRank < rightRank end
        return left < right
    end)
    return result
end

local function assaultTarget(snapshot, definition)
    local enemy, available = {}, {}
    for _, row in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        if definition.positions and definition.positions[row.label] then
            if row.owner == "ENEMY" then enemy[row.label] = true
            elseif row.owner ~= "FRIENDLY" then available[row.label] = true end
        end
    end
    for _, location in ipairs(definition.priorities or {}) do
        if enemy[location] then return location end
    end
    for _, location in ipairs(definition.locations or {}) do
        if enemy[location] then return location end
    end
    for _, location in ipairs(definition.priorities or {}) do
        if available[location] then return location end
    end
    for _, location in ipairs(definition.locations or {}) do
        if available[location] then return location end
    end
    return definition.priorities[1] or "Objective"
end

local function buildNode(roster, definition, snapshot)
    local context = snapshot.context or {}
    local rules = KWR.ObjectiveRules and KWR.ObjectiveRules:Resolve(snapshot) or {}
    local controlled = friendlyControlled(snapshot, definition, context)
    if snapshot.strategy and snapshot.strategy.state == "OPENING" or #controlled == 0 then
        return openingNode(roster, definition, context)
    end

    local result, used = {}, {}
    local minimumFight = math.min(6, math.max(rules.minimumFight or 3, #roster - 1))
    local defenderLimit = math.min(#controlled, math.max(
        rules.defenderMinimum or 1,
        #roster - minimumFight - (rules.responseReserve or 1) + 1))
    local faction = context.team and context.team.faction
    local home = definition.home and definition.home[faction]
    for index = 1, defenderLimit do
        local location = controlled[index]
        local role = location == home and "Anchor Defender" or "Node Defender"
        assignBest(roster, used, result, "defend", role, location, 94 - index, {
            reason = "Weighted independent defender preserves score without consuming core fight value.",
            handoff = "Call relief before leaving; the nearest floater confirms coverage.",
        })
    end
    if #controlled >= 3 and #roster - #result > minimumFight then
        assignBest(roster, used, result, "float", "Defense Floater",
            controlled[1], 89, {
                reason = "Mobile reserve supports simultaneous incoming calls without permanent double-sitting.",
                handoff = "Shadow the most exposed node; do not become a static second sitter.",
            })
    end
    local fight = assaultTarget(snapshot, definition)
    remaining(roster, used, result, "Strike Team", fight, 82)
    return result
end

local function buildFlag(roster, definition)
    local result, used = {}, {}
    local _, carrier = selectFirst(roster, used, function(player) return effectiveRole(player) == "TANK" end, true)
    add(result, carrier, "Flag Carrier", "Home", 100)
    local _, carrierHealer = selectFirst(roster, used, function(player) return effectiveRole(player) == "HEALER" end, false)
    add(result, carrierHealer, "Carrier Healer", "Our FC", 95)
    local _, returnHealer = selectFirst(roster, used, function(player) return effectiveRole(player) == "HEALER" end, false)
    add(result, returnHealer, "Return Healer", "Enemy FC", 85)
    for _ = 1, 2 do
        local _, peel = selectFirst(roster, used, function(player)
            return isClass(player, "MAGE", "WARLOCK", "HUNTER", "PALADIN")
        end, true)
        add(result, peel, "Peel Team", "Our FC", 88)
    end
    remaining(roster, used, result, "Return Team", "Enemy FC", 80)
    return result
end

local function buildOrb(roster, opening)
    local result, used = {}, {}
    if opening then
        local lanes = { "Green Orb", "Blue Orb", "Orange Orb", "Purple Orb" }
        for _, location in ipairs(lanes) do
            assignBest(roster, used, result, "float", "Orb Pickup", location, 94, {
                reason = "Named pickup lane prevents duplicate routes and missed opening orbs.",
                handoff = "Converge toward Center only after the orb is secured.",
            })
        end
        for _ = 1, math.min(3, #roster - #result) do
            assignBest(roster, used, result, "heal", "Center Healer", "Center", 90, {
                reason = "Central healing supports multiple carriers without stacking every orb.",
            }, function(player) return effectiveRole(player) == "HEALER" end, false)
        end
        remaining(roster, used, result, "Carrier Peel", "Center", 82)
        return result
    end
    for index = 1, 2 do
        local _, carrier = selectFirst(roster, used, function(player)
            return effectiveRole(player) == "TANK" or isClass(player, "DEMONHUNTER", "MONK", "DRUID")
        end, true)
        add(result, carrier, "Orb Carrier", index == 1 and "Center" or "Outer", 95)
    end
    for _ = 1, 3 do
        local _, healer = selectFirst(roster, used, function(player) return effectiveRole(player) == "HEALER" end, false)
        add(result, healer, "Carrier Healer", "Center", 90)
    end
    remaining(roster, used, result, "Carrier Hunter", "Enemy Carrier", 80)
    return result
end

local function buildCart(roster, definition, opening)
    local result, used = {}, {}
    if opening and definition.key == "SILVERSHARD" then
        local routes = { "Lava", "Water", "Top" }
        local sizes = #roster >= 10 and { 3, 3, 3 } or { 2, 2, 2 }
        for index, location in ipairs(routes) do
            local before = #result
            assignBest(roster, used, result, "heal", location .. " Team",
                location, 91 - index, {
                    reason = "One healer per cart lane prevents an opening group from inheriting every healer.",
                }, function(player) return effectiveRole(player) == "HEALER" end, false)
            assignGroup(roster, used, result, math.max(0, sizes[index] - (#result - before)),
                location .. " Team",
                location, 88 - index,
                "Named cart group maintains presence on a scoring route.")
        end
        if #result < #roster then
            assignBest(roster, used, result, "float", "Cart Floater", "Mid", 91, {
                reason = "Mobile reserve reinforces the first cart facing meaningful enemy numbers.",
                abandonIf = "Leave a completed or mathematically unrecoverable cart immediately.",
            })
        end
        remaining(roster, used, result, "Cart Floater", "Mid", 84)
        return result
    elseif opening and definition.key == "DEEPHAUL" then
        assignBest(roster, used, result, "heal", "Enemy Cart Delay", "Enemy Cart", 92, {
            reason = "Delay group receives independent healing instead of feeding into the enemy cart.",
        }, function(player) return effectiveRole(player) == "HEALER" end, false)
        local delaySeed = #result
        assignGroup(roster, used, result, math.min(3, math.max(0, #roster - 6)),
            "Enemy Cart Delay", "Enemy Cart", 88,
            "Grouped delay turns enemy progress instead of feeding individually.")
        local delayCount = #result - delaySeed + 1
        assignGroup(roster, used, result, math.min(6, #roster - #result),
            "Our Cart Escort", "Our Cart", 91,
            "Primary group advances the friendly cart with enough healing and control.")
        assignGroup(roster, used, result, math.max(0, 4 - delayCount),
            "Enemy Cart Delay", "Enemy Cart", 88,
            "Grouped delay turns enemy progress instead of feeding individually.")
        remaining(roster, used, result, "Crystal Floater", "Crystal", 84)
        return result
    end
    local _, anchor = selectFirst(roster, used, function(player) return effectiveRole(player) == "TANK" end, true)
    add(result, anchor, "Cart Anchor", definition.key == "DEEPHAUL" and "Our Cart" or "Primary Cart", 100)
    for _ = 1, 2 do
        local _, healer = selectFirst(roster, used, function(player) return effectiveRole(player) == "HEALER" end, false)
        add(result, healer, "Cart Healer", "Primary Cart", 90)
    end
    local _, delay = selectFirst(roster, used, function(player)
        return isClass(player, "ROGUE", "DRUID", "MAGE", "HUNTER")
    end, true)
    add(result, delay, "Delay", "Enemy Route", 88)
    remaining(roster, used, result, "Cart Team", definition.priorities[1] or "Active Cart", 78)
    return result
end

local function buildResource(roster)
    local result, used = {}, {}
    for _ = 1, 3 do
        local _, scout = selectFirst(roster, used, function(player)
            return isClass(player, "ROGUE", "DRUID", "DEMONHUNTER", "HUNTER")
        end, true)
        add(result, scout, "Scout / Fast Cap", "Next Spawn", 90)
    end
    for _ = 1, 3 do
        local _, healer = selectFirst(roster, used, function(player) return effectiveRole(player) == "HEALER" end, false)
        add(result, healer, "Team Healer", "Main Team", 85)
    end
    remaining(roster, used, result, "Capture Team", "Active Node", 75)
    return result
end

local function allowedLocations(definition, context)
    local allowed = {}
    local function allow(location)
        if type(location) == "string" and location ~= "" then
            allowed[location] = true
        end
    end
    for _, location in ipairs(definition and definition.locations or {}) do allow(location) end
    for _, location in ipairs(definition and definition.priorities or {}) do allow(location) end
    for _, location in pairs(definition and definition.home or {}) do allow(location) end
    local kind = definition and definition.kind
    if kind == "FLAG" then
        allow("Home")
        allow("Our FC")
        allow("Enemy FC")
    elseif kind == "ORB" then
        allow("Center")
        allow("Outer")
        allow("Enemy Carrier")
    elseif kind == "CART" then
        allow("Our Cart")
        allow("Primary Cart")
        allow("Enemy Route")
        allow("Active Cart")
    elseif kind == "RESOURCE" then
        allow("Next Spawn")
        allow("Main Team")
        allow("Active Node")
    elseif kind == "NODE" or kind == "HYBRID" then
        allow("Home")
        allow("Objective")
    end
    if not context or not context.inPvP then allow("Formation") end
    return allowed
end

function Assignments:Build(snapshot)
    local roster = snapshot.roster or {}
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    if #roster == 0 then return {} end
    if not definition or not snapshot.context.inPvP then
        local result = {}
        for _, player in ipairs(roster) do
            local role = effectiveRole(player)
            add(result, player, role == "HEALER" and "Healer" or (role == "TANK" and "Tank" or "Damage"), "Formation", 50)
        end
        return result
    end
    local opening = snapshot.strategy and snapshot.strategy.state == "OPENING"
    local result
    if definition.kind == "NODE" or definition.kind == "HYBRID" then
        result = buildNode(roster, definition, snapshot)
    elseif definition.kind == "FLAG" then
        result = buildFlag(roster, definition)
    elseif definition.kind == "ORB" then
        result = buildOrb(roster, opening)
    elseif definition.kind == "CART" then
        result = buildCart(roster, definition, opening)
    elseif definition.kind == "RESOURCE" then
        result = buildResource(roster)
    end
    result = result or {}
    for _, carrier in ipairs(snapshot.objectives and snapshot.objectives.carriers or {}) do
        if carrier.owner == "FRIENDLY" then
            local wanted = KWR.Util:ShortName(carrier.player):lower()
            for _, assignment in ipairs(result) do
                if KWR.Util:ShortName(assignment.name):lower() == wanted then
                    assignment.role = carrier.kind == "FLAG" and "Flag Carrier" or "Orb Carrier"
                    assignment.location = carrier.kind == "FLAG" and "Our FC" or carrier.objective
                    assignment.priority = 100
                    assignment.reason = "Verified live objective carrier; protect and plan the handoff."
                    assignment.carrierStacks = carrier.stacks
                    break
                end
            end
        end
    end
    local rosterIndex = {}
    for _, player in ipairs(roster) do
        if player.guid then rosterIndex[player.guid] = player end
        if player.name then rosterIndex[player.name] = player end
    end
    if KWR.AssignmentDoctrine and KWR.AssignmentDoctrine.Decorate then
        for _, assignment in ipairs(result) do
            local player = rosterIndex[assignment.guid]
                or rosterIndex[assignment.name]
            KWR.AssignmentDoctrine:Decorate(snapshot, assignment, player)
        end
    end
    if KWR.AssignmentOverrides and KWR.AssignmentOverrides.Apply then
        KWR.AssignmentOverrides:Apply(snapshot, result)
    end
    applyCounterDirectives(result, snapshot.strategy)
    return result
end

function Assignments:Audit(snapshot, assignments)
    snapshot = snapshot or {}
    assignments = assignments or {}
    local roster = snapshot.roster or {}
    local context = snapshot.context or {}
    local definition = KWR.Maps:Get(context.mapKey)
    local allowed = allowedLocations(definition, context)
    local issues, assigned = {}, {}
    local rosterKeys = {}
    for _, player in ipairs(roster) do
        if player.guid then rosterKeys[player.guid] = true end
        if player.name then rosterKeys[player.name] = true end
        if player.shortName then rosterKeys[player.shortName] = true end
    end

    if #assignments ~= #roster then
        issues[#issues + 1] = string.format(
            "Assignment coverage %d/%d", #assignments, #roster)
    end
    for _, assignment in ipairs(assignments) do
        local identity = assignment.guid or assignment.name
            or assignment.shortName
        local key = KWR.Util:Text(identity, "", 80)
        if key == "" then
            issues[#issues + 1] = "Assignment has no player identity"
        elseif assigned[key] then
            issues[#issues + 1] = "Duplicate primary assignment for " .. key
        else
            assigned[key] = true
        end
        if key ~= "" and not rosterKeys[identity]
            and not rosterKeys[assignment.name]
            and not rosterKeys[assignment.shortName] then
            issues[#issues + 1] = "Assignment references non-roster player "
                .. key
        end
        if KWR.Util:Text(assignment.role, "", 48) == "" then
            issues[#issues + 1] = "Assignment has no job for " .. (key ~= "" and key or "unknown")
        end
        if KWR.Util:Text(assignment.role, "", 48):find("Healer", 1, true)
            and assignment.groupRole ~= "HEALER" then
            issues[#issues + 1] = "Role-incompatible healer assignment for "
                .. (key ~= "" and key or "unknown")
        end
        if assignment.role == "Flag Carrier"
            and assignment.groupRole ~= "TANK" then
            issues[#issues + 1] = "Flag Carrier is not assigned to a tank: "
                .. (key ~= "" and key or "unknown")
        end
        local priority = KWR.Util:Number(assignment.priority, nil)
        if not priority or priority < 0 or priority > 100 then
            issues[#issues + 1] = "Invalid assignment priority for "
                .. (key ~= "" and key or "unknown")
        end
        local location = KWR.Util:Text(assignment.location, "", 48)
        if location == "" then
            issues[#issues + 1] = "Assignment has no location for " .. (key ~= "" and key or "unknown")
        elseif context.inPvP and location == "Formation" then
            issues[#issues + 1] = "Formation assignment leaked into active PvP"
        elseif definition and not allowed[location] then
            issues[#issues + 1] = "Invalid " .. definition.key .. " location: " .. location
        end
    end
    return {
        ok = #issues == 0,
        issues = issues,
        coverage = #assignments,
        roster = #roster,
    }
end

local function integrityJob(role)
    role = KWR.Util:Text(role, "", 48)
    if role:find("Defender", 1, true) or role == "Tower Sitter" then return "defend" end
    if role:find("Carrier", 1, true) and not role:find("Hunter", 1, true) then return "carry" end
    if role:find("Healer", 1, true) then return "heal" end
    if role:find("Float", 1, true) then return "float" end
    if role:find("Strike", 1, true) or role:find("Cap", 1, true) then return "assault" end
    return "fight"
end

local function assignmentObjective(snapshot, location)
    for _, objective in ipairs(snapshot.objectives
        and snapshot.objectives.rows or {}) do
        if objective.label == location then return objective end
    end
end

local function pressureAt(snapshot, location)
    for _, pressure in ipairs(snapshot.reporter
        and snapshot.reporter.pressure or {}) do
        if pressure.label == location then return pressure end
    end
end

local function assignmentTravel(snapshot, player, expected)
    local actual = KWR.Util:Text(player.location, "", 48)
    if actual == "" or actual == "Unknown"
        or actual == "Position restricted" then return nil end
    local capability = KWR.Capabilities:Resolve(
        player.classFile, player.spec)
    return KWR.Maps:TravelEstimate(
        snapshot.context and snapshot.context.mapKey,
        actual, expected, {
            mobility = capability and capability.ratings
                and capability.ratings.mobility or 2,
            inCombat = player.inCombat,
            observed = player.locationSource == "Friendly Map Position",
        })
end

function Assignments:Integrity(snapshot, assignments)
    local context = snapshot.context or {}
    local sessionKey = KWR.Util:BattlefieldSessionKey(context)
    if self.integrity.sessionKey ~= sessionKey then
        self.integrity = { sessionKey = sessionKey, records = {} }
    end
    local now = KWR.Util:Now()
    local players = {}
    for _, player in ipairs(snapshot.roster or {}) do
        players[player.guid or player.name] = player
        players[player.name] = player
    end
    local assignmentByPlayer, assignedByLocation = {}, {}
    for _, assignment in ipairs(assignments or {}) do
        local identity = assignment.guid or assignment.name
        assignmentByPlayer[identity] = assignment
        assignmentByPlayer[assignment.name] = assignment
        local location = assignment.location
        assignedByLocation[location] = assignedByLocation[location] or {}
        assignedByLocation[location][#assignedByLocation[location] + 1] =
            assignment
    end
    local result = {
        checkedAt = now,
        onStation = 0,
        moving = 0,
        completed = 0,
        unverified = 0,
        abandoned = 0,
        impossible = 0,
        reassignments = {},
        rows = {},
        coverageLedger = {},
        uncovered = 0,
        overcommitted = 0,
    }
    for _, assignment in ipairs(assignments or {}) do
        local key = assignment.guid or assignment.name
        local player = players[key] or players[assignment.name] or {}
        local record = self.integrity.records[key]
        if not record or record.role ~= assignment.role
            or record.location ~= assignment.location then
            record = {
                role = assignment.role,
                location = assignment.location,
                issuedAt = now,
            }
            self.integrity.records[key] = record
        end
        local age = math.max(0, now - (record.issuedAt or now))
        local actual = KWR.Util:Text(player.location, "", 48)
        local expected = KWR.Util:Text(assignment.location, "", 48)
        local job = integrityJob(assignment.role)
        local route = assignmentTravel(snapshot, player, expected)
        local expectedTravel = route and route.seconds or 12
        record.expectedBy = (record.issuedAt or now) + expectedTravel + 5
        record.routeSource = route and route.source or "UNVERIFIED"
        local comparable = actual ~= "" and actual ~= "Unknown"
            and actual ~= "Position restricted"
        local matches = comparable and (actual:lower():find(expected:lower(), 1, true)
            or expected:lower():find(actual:lower(), 1, true))
        local objective = assignmentObjective(snapshot, expected)
        local completed = matches and objective
            and objective.owner == "FRIENDLY"
            and (job == "assault" or job == "carry")
        local status
        if player.dead then
            status = "UNAVAILABLE_DEAD"
            result.impossible = result.impossible + 1
        elseif player.connected == false then
            status = "UNAVAILABLE_DISCONNECTED"
            result.impossible = result.impossible + 1
        elseif completed then
            status = "COMPLETED"
            result.completed = result.completed + 1
            record.lastConfirmedAt = now
        elseif matches then
            status = "ON_STATION"
            result.onStation = result.onStation + 1
            record.lastConfirmedAt = now
        elseif not comparable then
            status = "UNVERIFIED"
            result.unverified = result.unverified + 1
        elseif now >= (record.expectedBy or now + 1)
            and age >= math.max(20, expectedTravel + 8) then
            status = "ABANDONED"
            result.abandoned = result.abandoned + 1
        else
            status = "EN_ROUTE"
            result.moving = result.moving + 1
        end
        assignment.integrityStatus = status
        assignment.assignmentAge = age
        assignment.actualLocation = comparable and actual or nil
        local row = {
            name = assignment.shortName or assignment.name,
            role = assignment.role,
            expected = expected,
            actual = comparable and actual or "UNKNOWN",
            age = age,
            status = status,
            issuedAt = record.issuedAt,
            expectedBy = record.expectedBy,
            lastConfirmedAt = record.lastConfirmedAt,
            travelSeconds = route and route.seconds or nil,
            travelBand = route and route.band or "UNKNOWN",
            evidenceSource = comparable
                and (player.locationSource or "group_unit") or "unknown",
            evidenceConfidence = matches and "HIGH"
                or (comparable and "MEDIUM" or "NONE"),
            successCondition = assignment.successCondition
                or (job == "defend"
                    and (expected .. " remains covered and scoring.")
                    or (job == "assault"
                        and ("Secure " .. expected .. " with coverage intact.")
                        or ("Complete " .. assignment.role .. " at " .. expected .. "."))),
            abortCondition = assignment.abortCondition
                or assignment.abandonIf
                or ("Abort if " .. expected
                    .. " becomes unreachable or required coverage breaks."),
        }
        if status == "ABANDONED" or status == "UNAVAILABLE_DEAD"
            or status == "UNAVAILABLE_DISCONNECTED" then
            local replacement, replacementScore
            for _, candidate in ipairs(snapshot.roster or {}) do
                if candidate.connected ~= false and not candidate.dead
                    and (candidate.guid or candidate.name) ~= key then
                    local current = assignmentByPlayer[
                        candidate.guid or candidate.name]
                    local currentJob = current
                        and integrityJob(current.role) or nil
                    local stripsOnlyDefender = currentJob == "defend"
                        and current.location ~= expected
                        and #(assignedByLocation[current.location] or {}) <= 1
                    if not stripsOnlyDefender then
                        local score = value(candidate, job)
                        if candidate.location == expected then score = score + 40 end
                        if currentJob == "float" then score = score + 18 end
                        if candidate.inCombat then score = score - 12 end
                        if currentJob == "assault" then
                            score = score - math.max(0,
                                (current.battleWeight or 50) - 65) * 0.35
                        end
                        if not replacementScore or score > replacementScore then
                            replacement, replacementScore = candidate, score
                        end
                    end
                end
            end
            row.replacement = replacement and (replacement.shortName or replacement.name)
            row.replacementScore = replacementScore
            result.reassignments[#result.reassignments + 1] = row
        end
        result.rows[#result.rows + 1] = row
    end
    local profile = KWR.Maps:OperationalProfile(
        snapshot.context and snapshot.context.mapKey)
    for _, objective in ipairs(snapshot.objectives
        and snapshot.objectives.rows or {}) do
        if objective.owner == "FRIENDLY" then
            local locationAssignments = assignedByLocation[objective.label] or {}
            local available, names = 0, {}
            for _, assignment in ipairs(locationAssignments) do
                local player = players[assignment.guid or assignment.name]
                    or players[assignment.name] or {}
                if player.connected ~= false and not player.dead then
                    available = available + 1
                    names[#names + 1] =
                        assignment.shortName or assignment.name
                end
            end
            local pressure = pressureAt(snapshot, objective.label) or {}
            local required = profile.defenderMinimum or 1
            if KWR.ObjectiveRules and KWR.ObjectiveRules.MinimumDefenders then
                required = KWR.ObjectiveRules:MinimumDefenders(
                    snapshot, objective.label, pressure)
            elseif (pressure.enemy or 0) >= 2 then
                required = required + 1
            end
            local reserve
            for _, assignment in ipairs(assignments or {}) do
                local reserveJob = integrityJob(assignment.role)
                if reserveJob == "float"
                    and assignment.location ~= objective.label then
                    reserve = assignment.shortName or assignment.name
                    break
                end
            end
            local ledger = {
                location = objective.label,
                required = required,
                assigned = available,
                defenders = names,
                backup = reserve,
                enemyKnown = pressure.enemy or 0,
                state = available < required and "UNCOVERED"
                    or (available > required + 2 and "OVERCOMMITTED"
                    or "COVERED"),
            }
            if ledger.state == "UNCOVERED" then
                result.uncovered = result.uncovered + 1
            elseif ledger.state == "OVERCOMMITTED" then
                result.overcommitted = result.overcommitted + 1
            end
            result.coverageLedger[#result.coverageLedger + 1] = ledger
        end
    end
    result.reassignmentRequired = #result.reassignments > 0
        or result.uncovered > 0
    return result
end

function Assignments:SelectForCommand(assignments, prediction)
    local wanted = {}
    if prediction.status == "WIN" then
        wanted = { ["Anchor Defender"] = true, ["Node Defender"] = true,
            ["Defense Floater"] = true, ["Tower Sitter"] = true,
            ["Peel Team"] = true, ["Carrier Healer"] = true, ["Cart Anchor"] = true }
    else
        wanted = { ["Strike Team"] = true, ["Main Fight"] = true,
            ["Tower Strike"] = true, ["Blacksmith Spinner"] = true,
            ["Return Team"] = true, ["Carrier Hunter"] = true,
            ["Delay"] = true, ["Enemy Cart Delay"] = true, ["Capture Team"] = true }
    end
    local names = {}
    for _, assignment in ipairs(assignments or {}) do
        if wanted[assignment.role] and not assignment.dead and assignment.connected ~= false then
            names[#names + 1] = assignment.shortName
        end
    end
    if #names == 0 then
        for _, assignment in ipairs(assignments or {}) do
            if not assignment.dead and assignment.connected ~= false then
                names[#names + 1] = assignment.shortName
            end
        end
    end
    return #names > 0 and table.concat(names, ", ") or "Team"
end

local compactRoles = {
    ["Tank"] = "T",
    ["Healer"] = "H",
    ["Damage"] = "DPS",
    ["Anchor Defender"] = "DEFEND",
    ["Node Defender"] = "DEFEND",
    ["Defense Floater"] = "FLOAT",
    ["Tower Sitter"] = "DEFEND",
    ["Tower Strike"] = "STRIKE",
    ["Blacksmith Spinner"] = "SPIN",
    ["Outer Cap / Float"] = "CAP",
    ["Enemy-Home Scout"] = "SCOUT",
    ["Flank Defender"] = "DEFEND",
    ["Response Floater"] = "FLOAT",
    ["Main Fight"] = "MAIN",
    ["Strike Team"] = "STRIKE",
    ["Flag Carrier"] = "FC",
    ["Carrier Healer"] = "FC-H",
    ["Return Healer"] = "EFC-H",
    ["Peel Team"] = "PEEL",
    ["Return Team"] = "EFC",
    ["Orb Pickup"] = "ORB",
    ["Center Healer"] = "MID-H",
    ["Carrier Peel"] = "PEEL",
    ["Orb Carrier"] = "ORB",
    ["Carrier Hunter"] = "KILL",
    ["Cart Anchor"] = "CART",
    ["Cart Healer"] = "CART-H",
    ["Cart Team"] = "CART",
    ["Cart Floater"] = "FLOAT",
    ["Enemy Cart Delay"] = "DELAY",
    ["Delay"] = "DELAY",
    ["Crystal Floater"] = "FLOAT",
    ["Scout / Fast Cap"] = "SCOUT",
    ["Team Healer"] = "TEAM-H",
    ["Capture Team"] = "CAP",
}

function Assignments:CompactRole(role)
    role = KWR.Util:Text(role, "JOB", 48)
    return compactRoles[role] or KWR.Util:Text(role, "JOB", 12)
end

function Assignments:CompactLabel(assignment, mapKey)
    if not assignment then return "UNASSIGNED" end
    local role = self:CompactRole(assignment.role)
    local location = KWR.Maps:AbbreviateLocation(
        mapKey, assignment.location)
    if location == "" or location == "Formation" or location == "FORM" then
        return role
    end
    return role .. " -> " .. location
end

function Assignments:CompactExport(assignments, mapKey)
    local groups, order = {}, {}
    local definition = KWR.Maps:Get(mapKey)
    local header = definition and definition.short or "FORM"
    for _, assignment in ipairs(assignments or {}) do
        local role = self:CompactRole(assignment.role)
        local location = KWR.Maps:AbbreviateLocation(mapKey, assignment.location)
        local key = role .. (location ~= "FORM" and ("@" .. location) or "")
        if not groups[key] then
            groups[key] = {}
            order[#order + 1] = key
        end
        groups[key][#groups[key] + 1] = KWR.Util:Text(
            assignment.shortName or assignment.name, "?", 16)
    end
    local parts = { header }
    for _, key in ipairs(order) do
        parts[#parts + 1] = key .. ":" .. table.concat(groups[key], ",")
    end
    return table.concat(parts, " | ")
end

function Assignments:LineExport(assignments, mapKey)
    local rows = {}
    for _, assignment in ipairs(assignments or {}) do
        local name = KWR.Util:Text(assignment.shortName or assignment.name, "?", 24)
        local label = self:CompactLabel(assignment, mapKey)
        rows[#rows + 1] = name .. " - " .. label
    end
    return table.concat(rows, "\n")
end

function Assignments:ChatExport(assignments, mapKey)
    local groups, order = {}, {}
    for _, assignment in ipairs(assignments or {}) do
        local role = self:CompactRole(assignment.role)
        local location = KWR.Maps:AbbreviateLocation(mapKey, assignment.location)
        local name = KWR.Util:Text(assignment.shortName or assignment.name, "?", 24)
        local key
        local label
        if location == "" or location == "Formation" or location == "FORM" then
            key = role
            label = role
        else
            key = role .. "@" .. location
            label = role .. " " .. location
        end
        if not groups[key] then
            groups[key] = {
                label = label,
                names = {},
            }
            order[#order + 1] = key
        end
        groups[key].names[#groups[key].names + 1] = name
    end
    local rows = {}
    for _, key in ipairs(order) do
        local group = groups[key]
        rows[#rows + 1] = group.label .. ": " .. table.concat(group.names, ", ")
    end
    return table.concat(rows, " | ")
end

local function commanderBucket(role)
    role = KWR.Util:Text(role, "", 48)
    if role:find("Defender", 1, true) or role == "Tower Sitter"
        or role == "Flank Defender" or role == "Cart Anchor" then
        return "SIT"
    end
    if role:find("Float", 1, true) or role == "Response Floater"
        or role == "Cart Floater" or role == "Outer Cap / Float" then
        return "FLOAT"
    end
    if role == "Main Fight" then
        return "PRESS"
    end
    if role == "Strike Team" or role == "Tower Strike"
        or role == "Blacksmith Spinner" or role == "Return Team"
        or role == "Carrier Hunter" or role == "Enemy-Home Scout"
        or role == "Capture Team" or role == "Enemy Cart Delay" then
        return "STRIKE"
    end
    if role:find("Carrier", 1, true) then
        return "CARRY"
    end
    return nil
end

function Assignments:CommandGroups(assignments, mapKey)
    local buckets = {}
    local bucketOrder = { "SIT", "FLOAT", "STRIKE", "PRESS", "CARRY" }
    local lines = {}
    local function add(bucket, location, name)
        if not buckets[bucket] then
            buckets[bucket] = { order = {}, groups = {} }
        end
        location = KWR.Util:Text(location, "MAP", 24)
        if not buckets[bucket].groups[location] then
            buckets[bucket].groups[location] = {}
            buckets[bucket].order[#buckets[bucket].order + 1] = location
        end
        buckets[bucket].groups[location][#buckets[bucket].groups[location] + 1] =
            KWR.Util:Text(name, "?", 18)
    end
    for _, assignment in ipairs(assignments or {}) do
        if assignment.connected ~= false and not assignment.dead then
            local bucket = commanderBucket(assignment.role)
            if bucket then
                add(bucket, KWR.Maps:AbbreviateLocation(mapKey, assignment.location),
                    assignment.shortName or assignment.name)
            end
        end
    end
    for _, bucket in ipairs(bucketOrder) do
        local payload = buckets[bucket]
        if payload then
            local parts = {}
            for _, location in ipairs(payload.order) do
                parts[#parts + 1] = location .. " "
                    .. table.concat(payload.groups[location], ", ")
            end
            lines[#lines + 1] = bucket .. ": " .. table.concat(parts, "; ")
        end
    end
    return {
        lines = lines,
        text = #lines > 0 and table.concat(lines, "\n")
            or "SIT: pending\nSTRIKE: pending",
    }
end

function Assignments:Diff(previous, current)
    local oldByKey, changes = {}, {}
    for _, assignment in ipairs(previous or {}) do
        local key = assignment.guid or assignment.name or assignment.shortName
        if key then oldByKey[key] = assignment end
    end
    for _, assignment in ipairs(current or {}) do
        local key = assignment.guid or assignment.name or assignment.shortName
        local old = key and oldByKey[key]
        if not old or old.role ~= assignment.role or old.location ~= assignment.location then
            changes[#changes + 1] = {
                name = assignment.shortName,
                fromRole = old and old.role or "UNASSIGNED",
                fromLocation = old and old.location or "--",
                toRole = assignment.role,
                toLocation = assignment.location,
                reason = assignment.reason or assignment.handoff,
            }
        end
    end
    return changes
end

function Assignments:SummarizeChanges(changes, mapKey)
    if #(changes or {}) == 0 then return "Assignments confirmed; no changes." end
    local parts = {}
    for index = 1, #changes do
        local change = changes[index]
        parts[#parts + 1] = KWR.Util:Text(change.name, "Player", 16)
            .. " -> " .. self:CompactRole(change.toRole)
            .. "@" .. KWR.Maps:AbbreviateLocation(
                mapKey, change.toLocation)
    end
    return table.concat(parts, "; ")
end

function Assignments:ResponsePackage(snapshot, assignments)
    local strategy = snapshot.strategy or {}
    local execution = strategy.executionAssessment or {}
    local opportunity = execution.actionOpportunity or {}
    local decision = strategy.objectiveDecision or {}
    local integrity = snapshot.assignmentIntegrity or {}
    local actionID = KWR.Util:Text(opportunity.action, "HOLD_PLAN", 32)
    local rawTarget = KWR.Util:Text(opportunity.target
        or decision.target, "current objective", 48)
    local mapKey = snapshot.context and snapshot.context.mapKey
    local target = KWR.ObjectiveIntel
        and KWR.ObjectiveIntel:CanonicalCommandTarget(
            mapKey, rawTarget, snapshot.context)
        or rawTarget
    local targetNeedsVerification = target == "VERIFY"
    if targetNeedsVerification then
        actionID = "HOLD_PLAN"
    end
    local shortTarget = KWR.Maps:AbbreviateLocation(mapKey, target)
    local movers, stayers = {}, {}
    local stayerGroups, stayerOrder = {}, {}
    local moverRoles = {
        ["Strike Team"] = true, ["Main Fight"] = true,
        ["Tower Strike"] = true, ["Defense Floater"] = true,
        ["Response Floater"] = true, ["Cart Floater"] = true,
        ["Outer Cap / Float"] = true, ["Capture Team"] = true,
        ["Return Team"] = true, ["Carrier Hunter"] = true,
    }
    for _, assignment in ipairs(assignments or {}) do
        if assignment.connected ~= false and not assignment.dead then
            local name = assignment.shortName or assignment.name
            local role = assignment.role or ""
            if role:find("Defender", 1, true)
                or role == "Tower Sitter" or role == "Cart Anchor" then
                stayers[#stayers + 1] = name
                local location = KWR.Maps:AbbreviateLocation(
                    mapKey, assignment.location)
                if not stayerGroups[location] then
                    stayerGroups[location] = {}
                    stayerOrder[#stayerOrder + 1] = location
                end
                stayerGroups[location][#stayerGroups[location] + 1] = name
            elseif moverRoles[role] then
                movers[#movers + 1] = name
            end
        end
    end
    if #movers == 0 then
        for _, assignment in ipairs(assignments or {}) do
            if assignment.connected ~= false and not assignment.dead then
                movers[#movers + 1] =
                    assignment.shortName or assignment.name
            end
        end
    end
    local stayerCalls = {}
    for _, location in ipairs(stayerOrder) do
        stayerCalls[#stayerCalls + 1] = location .. ": "
            .. table.concat(stayerGroups[location], ", ")
    end

    local actionText = {
        REINFORCE = "REINFORCE " .. shortTarget,
        REALLOCATE = "PEEL EXCESS FROM " .. shortTarget,
        CONTAIN_TRADE = "CONTAIN " .. shortTarget .. "; TAKE EXPOSED OBJECTIVE",
        PREPARE_PRESSURE = "PREPARE DEFENSE AT " .. shortTarget,
        ROTATE = "ROTATE TO " .. shortTarget,
        DISENGAGE_RESET = "DISENGAGE, RESET, AND REGROUP",
        STALL_OR_TRADE = "STALL; TRADE THE EXPOSED OBJECTIVE",
        RESET_REASSIGN = "RESET POSITIONS AND CONFIRM ASSIGNMENTS",
        HOLD_PLAN = "HOLD CURRENT PLAN",
    }
    local confidence = KWR.Util:Text(execution.confidence, "NONE", 12)
    local qualified = opportunity.score
        and opportunity.score >= 85
        and (confidence == "MEDIUM" or confidence == "HIGH")
    local criticalGap
    local releaseTarget
    for _, row in ipairs(integrity.coverageLedger or {}) do
        if row.state == "OVERCOMMITTED" then
            releaseTarget = row
            break
        end
    end
    for _, row in ipairs(integrity.coverageLedger or {}) do
        if row.state == "UNCOVERED" then
            criticalGap = row
            break
        end
    end
    local recoverySummary = criticalGap
        and (criticalGap.location .. " needs "
            .. tostring(math.max(0, (criticalGap.required or 0)
                - (criticalGap.assigned or 0))) .. " more.")
        or (releaseTarget and (releaseTarget.location .. " can release "
            .. tostring(math.max(0, (releaseTarget.assigned or 0)
                - (releaseTarget.required or 0))) .. ".")
            or "Coverage is currently stable.")
    return {
        active = execution.active == true,
        qualified = qualified == true,
        actionID = actionID,
        action = actionText[actionID] or "HOLD CURRENT PLAN",
        target = target,
        shortTarget = shortTarget,
        movers = movers,
        stayers = stayers,
        moverText = #movers > 0 and table.concat(movers, ", ") or "Team",
        stayerText = #stayerCalls > 0 and table.concat(stayerCalls, "; ")
            or "Assigned defenders",
        confidence = confidence,
        score = opportunity.score or 0,
        reason = opportunity.reason or "No stronger execution veto.",
        success = decision.success or "Objective state changes as called.",
        abort = decision.abort or "Scoring path or manpower changes.",
        recovery = {
            criticalGap = criticalGap and criticalGap.location or nil,
            releaseTarget = releaseTarget and releaseTarget.location or nil,
            replacement = integrity.reassignments and integrity.reassignments[1]
                and integrity.reassignments[1].replacement or nil,
            summary = recoverySummary,
            urgent = criticalGap ~= nil
                or (integrity.reassignments and #integrity.reassignments > 0),
        },
    }
end

KWR:RegisterModule("Assignments", Assignments)
