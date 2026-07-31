local _, KWR = ...

local Builder = {}
KWR.ExecutionCommandBuilder = Builder

local ORB_HANDOFF_STACK_THRESHOLD = 300
local ORB_DROP_HEALTH_THRESHOLD = 35

local CONTROL_VERBS = {
    Subdue = true,
    Disrupt = true,
    Deny = true,
}

local HEALER_CONTROL_PROBLEMS = {
    FREE_CASTING_HEALER = true,
    CASTER_HEALER_SUPPORT = true,
    LOCAL_HEALER_CONTROL = true,
}

local PROTECTED_ROLES = {
    "Defender",
    "Sitter",
    "Carrier Healer",
    "Orb Carrier",
    "Flag Carrier",
    "Spin",
}

local function shortName(value)
    return KWR.Util:ShortName(KWR.Util:Text(value, "", 64))
end

local function callLabel(value)
    return KWR.Util:Text(value, "", 64)
end

local function identityKey(name, guid)
    return KWR.Util:CanonicalPlayerKey(name, guid)
        or shortName(name):lower()
end

local function isControl(assignment)
    return assignment and CONTROL_VERBS[assignment.verb] == true
end

local function isHealerControlProblem(problem)
    return problem and HEALER_CONTROL_PROBLEMS[problem.type] == true
end

local function isProtectedRole(role)
    role = KWR.Util:Text(role, "", 64)
    for _, token in ipairs(PROTECTED_ROLES) do
        if role:find(token, 1, true) then return true end
    end
    return false
end

local function rosterByIdentity(snapshot)
    local result = {}
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        local key = identityKey(player.name or player.shortName, player.guid)
        if key and key ~= "" then result[key] = player end
        local short = shortName(player.name or player.shortName):lower()
        if short ~= "" then result[short] = player end
    end
    return result
end

local function assignmentByIdentity(assignments)
    local result = {}
    for _, assignment in ipairs(assignments or {}) do
        local key = identityKey(assignment.name or assignment.shortName, assignment.guid)
        if key and key ~= "" then result[key] = assignment end
        local short = shortName(assignment.name or assignment.shortName):lower()
        if short ~= "" then result[short] = assignment end
    end
    return result
end

local function targetLabel(problem)
    local enemy = problem and problem.enemy or {}
    return callLabel(enemy.shortName or enemy.name)
end

local function healerProblems(teamfight)
    local result, seen = {}, {}
    for _, problem in ipairs(teamfight and teamfight.problems or {}) do
        local enemy = problem and problem.enemy or {}
        local role = KWR.CombatSpells:Role(enemy.spec, enemy.role)
        local target = targetLabel(problem)
        if role == "HEALER" and isHealerControlProblem(problem)
            and target ~= "" and not seen[target:lower()] then
            seen[target:lower()] = true
            result[#result + 1] = problem
            if #result >= 3 then break end
        end
    end
    return result
end

local function uniqueAssignmentMatch(assignments, problem, wanted, field)
    if wanted == "" then return nil end
    local match
    for _, assignment in ipairs(assignments or {}) do
        local assignmentType = callLabel(assignment.problemType)
        local typeMatches = assignmentType == "" or assignmentType == problem.type
        if isControl(assignment) and typeMatches and field(assignment) == wanted then
            if match then return nil end
            match = assignment
        end
    end
    return match
end

local function controlAssignment(teamfight, problem)
    local assignments = teamfight and teamfight.assignments or {}
    local enemy = problem and problem.enemy or {}
    local wantedGUID = KWR.Util:Text(enemy.guid, "", 96)
    local byGUID = uniqueAssignmentMatch(assignments, problem, wantedGUID,
        function(assignment)
            return KWR.Util:Text(assignment.targetGUID, "", 96)
        end)
    if byGUID then return byGUID end

    local wantedName = KWR.Util:CanonicalName(targetLabel(problem))
    local byName = uniqueAssignmentMatch(assignments, problem, wantedName,
        function(assignment)
            return KWR.Util:CanonicalName(assignment.target)
        end)
    if byName then return byName end

    local wantedShort = KWR.Util:CanonicalShortName(targetLabel(problem))
    return uniqueAssignmentMatch(assignments, problem, wantedShort,
        function(assignment)
            return KWR.Util:CanonicalShortName(assignment.target)
        end)
end

local function controlAssignments(teamfight)
    local result = {}
    for _, problem in ipairs(healerProblems(teamfight)) do
        local target = targetLabel(problem)
        local assignment = controlAssignment(teamfight, problem)
        result[#result + 1] = {
            actor = assignment and callLabel(assignment.actor or assignment.name) or "UNASSIGNED",
            actorGUID = assignment and assignment.actorGUID or nil,
            verb = assignment and assignment.verb or "Subdue",
            target = target,
            targetGUID = assignment and assignment.targetGUID
                or (problem.enemy and problem.enemy.guid),
            confidence = assignment and assignment.confidence
                or problem.confidence or "UNKNOWN",
            assigned = assignment ~= nil,
            targetStatus = assignment and assignment.targetStatus or "UNKNOWN",
            state = assignment and assignment.localState
                or problem.localState or "ACTIVE",
        }
    end
    return result
end

local function preserveProtectedAssignments(controls, assignments)
    local byIdentity = assignmentByIdentity(assignments)
    for _, control in ipairs(controls or {}) do
        local key = identityKey(control.actor, control.actorGUID)
        local short = shortName(control.actor):lower()
        local assignment = byIdentity[key] or byIdentity[short]
        if assignment and isProtectedRole(assignment.role) then
            control.actor = "UNASSIGNED"
            control.actorGUID = nil
            control.assigned = false
            control.protectedAssignment = assignment.role
        end
    end
    return controls
end

local function isCurrentLocalEnemy(enemy)
    return type(enemy) == "table"
        and enemy.dead ~= true
        and (enemy.localRange == true or enemy.localEngaged == true)
end

local function isRecentLocalEnemy(enemy)
    return type(enemy) == "table"
        and enemy.dead ~= true
        and not isCurrentLocalEnemy(enemy)
        and (enemy.recentLocalRange == true or enemy.recentLocalEngaged == true)
end

local function observedLocalEnemies(snapshot, includeRecent)
    local result = {}
    local seen = {}
    local function add(enemy)
        if not isCurrentLocalEnemy(enemy)
            and not (includeRecent and isRecentLocalEnemy(enemy)) then
            return
        end
        local key = identityKey(enemy.name or enemy.shortName, enemy.guid)
        if not key or key == "" then
            key = "ROW:" .. tostring(enemy)
        end
        if seen[key] then return end
        seen[key] = true
        result[#result + 1] = enemy
    end
    for _, enemy in ipairs(snapshot and snapshot.enemies or {}) do
        add(enemy)
    end
    local combat = snapshot and snapshot.combat or {}
    add(combat.localTarget)
    add(combat.killTarget)
    return result
end

local function uniqueIdentityMatch(candidates, wanted, field)
    if wanted == "" then return nil end
    local match
    for _, enemy in ipairs(candidates or {}) do
        local candidate = field(enemy)
        if candidate == wanted then
            if match then return nil end
            match = enemy
        end
    end
    return match
end

local function currentLocalEnemy(snapshot, name, guid)
    local candidates = observedLocalEnemies(snapshot, false)
    local wantedGUID = KWR.Util:Text(guid, "", 96)
    if wantedGUID ~= "" then
        local byGUID = uniqueIdentityMatch(candidates, wantedGUID, function(enemy)
            return KWR.Util:Text(enemy.guid, "", 96)
        end)
        if byGUID then return byGUID end
    end
    local wantedName = KWR.Util:CanonicalName(name)
    local byName = uniqueIdentityMatch(candidates, wantedName, function(enemy)
        return KWR.Util:CanonicalName(enemy.name or enemy.shortName)
    end)
    if byName then return byName end
    local wantedShort = KWR.Util:CanonicalShortName(name)
    return uniqueIdentityMatch(candidates, wantedShort, function(enemy)
        return KWR.Util:CanonicalShortName(enemy.shortName or enemy.name)
    end)
end

local function localControlEnemy(snapshot, name, guid)
    local candidates = observedLocalEnemies(snapshot, true)
    local wantedGUID = KWR.Util:Text(guid, "", 96)
    if wantedGUID ~= "" then
        local byGUID = uniqueIdentityMatch(candidates, wantedGUID, function(enemy)
            return KWR.Util:Text(enemy.guid, "", 96)
        end)
        if byGUID then return byGUID end
    end
    local wantedName = KWR.Util:CanonicalName(name)
    local byName = uniqueIdentityMatch(candidates, wantedName, function(enemy)
        return KWR.Util:CanonicalName(enemy.name or enemy.shortName)
    end)
    if byName then return byName end
    local wantedShort = KWR.Util:CanonicalShortName(name)
    return uniqueIdentityMatch(candidates, wantedShort, function(enemy)
        return KWR.Util:CanonicalShortName(enemy.shortName or enemy.name)
    end)
end

local function localKill(mode, enemy, source, reason)
    if not isCurrentLocalEnemy(enemy) then return nil end
    local location = KWR.Util:Text(enemy.location, "", 48)
    return {
        mode = mode,
        target = callLabel(enemy.shortName or enemy.name
            or (source and source.target)),
        targetGUID = enemy.guid or (source and source.targetGUID),
        healthPercent = KWR.Util:Number(enemy.healthPercent, nil),
        location = location ~= "" and location or nil,
        state = enemy.localEngaged == true and "ENGAGED" or "LOCAL",
        confidence = source and source.confidence
            or enemy.confidence or "CONFIRMED",
        reason = KWR.Util:Text(reason, "", 120),
    }
end

local function buildLocalFight(packet, snapshot)
    local kill
    if packet.primaryTarget then
        local enemy = currentLocalEnemy(snapshot, packet.primaryTarget.target,
            packet.primaryTarget.targetGUID)
        kill = localKill("KILL", enemy, packet.primaryTarget,
            "Synchronized local kill target.")
    end
    if not kill then
        local combat = snapshot and snapshot.combat or {}
        local fallback = isCurrentLocalEnemy(combat.localTarget)
            and combat.localTarget or combat.killTarget
        kill = localKill("PRESSURE", fallback, nil,
            combat.localTargetReason or combat.killReason)
    end

    local controls = {}
    local hasActiveControl = false
    for _, control in ipairs(packet.controls or {}) do
        local enemy = localControlEnemy(snapshot, control.target, control.targetGUID)
        if enemy and callLabel(control.target) ~= "" then
            local state = isCurrentLocalEnemy(enemy) and "ACTIVE" or "RECENT"
            controls[#controls + 1] = {
                actor = callLabel(control.actor),
                actorGUID = control.actorGUID,
                target = callLabel(control.target),
                targetGUID = control.targetGUID,
                verb = control.verb or "Subdue",
                assigned = control.assigned == true,
                state = state,
                confidence = control.confidence or "UNKNOWN",
            }
            if state == "ACTIVE" then hasActiveControl = true end
            if #controls >= 3 then break end
        end
    end
    return {
        phase = (kill or hasActiveControl) and "ACTIVE"
            or (#controls > 0 and "RECENT" or "CLEAR"),
        kill = kill,
        controls = controls,
        updatedAt = packet.generatedAt,
    }
end

local function highestFriendlyOrb(snapshot)
    local best
    for _, carrier in ipairs(snapshot and snapshot.objectives
        and snapshot.objectives.carriers or {}) do
        if carrier.owner == "FRIENDLY" and carrier.kind == "ORB" then
            local stacks = KWR.Util:Number(carrier.stacks, 0) or 0
            local bestStacks = best and (KWR.Util:Number(best.stacks, 0) or 0) or -1
            if not best or stacks > bestStacks
                or (stacks == bestStacks and tostring(carrier.objective) < tostring(best.objective)) then
                best = carrier
            end
        end
    end
    return best
end

local function existingReplacement(snapshot, assignments, carrier)
    local objective = KWR.Util:Text(carrier and carrier.objective, "", 48)
    for _, row in ipairs(snapshot and snapshot.assignmentIntegrity
        and snapshot.assignmentIntegrity.reassignments or {}) do
        if row.expected == objective and KWR.Util:Text(row.replacement, "", 64) ~= "" then
            return shortName(row.replacement), nil, "INTEGRITY_REPLACEMENT"
        end
    end
    for _, assignment in ipairs(assignments or {}) do
        if assignment.role == "Orb Pickup" and assignment.location == objective
            and shortName(assignment.name) ~= shortName(carrier and carrier.player) then
            return shortName(assignment.name), assignment.guid, "ORB_PICKUP_ASSIGNMENT"
        end
    end
    return nil
end

local function qualifiedReplacement(snapshot, assignments, carrier, excluded)
    local existing, existingGUID, source = existingReplacement(snapshot, assignments, carrier)
    if existing then return existing, existingGUID, source end

    local byIdentity = assignmentByIdentity(assignments)
    local carrierName = shortName(carrier and carrier.player):lower()
    local best, bestScore
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        local playerName = shortName(player.shortName or player.name)
        local key = identityKey(player.name or player.shortName, player.guid)
        local current = byIdentity[key] or byIdentity[playerName:lower()]
        local role = current and current.role or ""
        local effectiveRole = KWR.CombatSpells:Role(player.spec, player.role)
        local eligible = playerName ~= ""
            and playerName:lower() ~= carrierName
            and player.connected ~= false
            and player.dead ~= true
            and effectiveRole ~= "HEALER"
            and not excluded[key]
            and not excluded[playerName:lower()]
            and not isProtectedRole(role)
        if eligible then
            local score = KWR.Assignments:BattleValue(player, "float")
            if role == "Orb Pickup" then score = score + 50 end
            if role:find("Float", 1, true) then score = score + 24 end
            if role == "Carrier Hunter" then score = score + 18 end
            if player.inCombat then score = score - 12 end
            if not bestScore or score > bestScore
                or (score == bestScore and playerName < shortName(best.name)) then
                best, bestScore = player, score
            end
        end
    end
    if not best then return nil end
    return shortName(best.shortName or best.name), best.guid, "QUALIFIED_FLOAT"
end

local function objectiveHandoff(snapshot, assignments, controls)
    if not snapshot or not snapshot.context or snapshot.context.kind ~= "ORB" then
        return nil
    end
    local carrier = highestFriendlyOrb(snapshot)
    if not carrier then return nil end
    local stacks = KWR.Util:Number(carrier.stacks, 0) or 0
    local health = KWR.Util:Number(carrier.healthPercent, nil)
    if stacks < ORB_HANDOFF_STACK_THRESHOLD
        and not (health and health <= ORB_DROP_HEALTH_THRESHOLD) then
        return nil
    end

    local excluded = {}
    for _, control in ipairs(controls or {}) do
        if control.assigned then
            excluded[identityKey(control.actor, control.actorGUID)] = true
            excluded[shortName(control.actor):lower()] = true
        end
    end
    local actor, actorGUID, source = qualifiedReplacement(
        snapshot, assignments, carrier, excluded)
    if not actor then return nil end
    local objective = KWR.Util:Text(carrier.objective, "Orb", 48)
    return {
        actor = actor,
        actorGUID = actorGUID,
        verb = "Pickup",
        objective = objective,
        target = objective,
        carrier = shortName(carrier.player),
        stacks = stacks,
        healthPercent = health,
        urgency = health and health <= ORB_DROP_HEALTH_THRESHOLD and "DROP RISK" or "PREPARE",
        source = source,
        confidence = carrier.visible == true and "HIGH" or "MEDIUM",
    }
end

local function objectiveForKill(snapshot, killTarget)
    local wanted = shortName(killTarget and killTarget.target):lower()
    for _, carrier in ipairs(snapshot and snapshot.objectives
        and snapshot.objectives.carriers or {}) do
        if shortName(carrier.player):lower() == wanted then
            return KWR.Util:Text(carrier.objective, "", 48)
        end
    end
    return ""
end

local function personalJob(actor, guid, role, shortRole, location, target, verb, movement, detail)
    return {
        name = actor,
        shortName = shortName(actor),
        guid = guid,
        role = role,
        shortRole = shortRole,
        location = location,
        target = target,
        verb = verb,
        movement = movement,
        detail = detail,
        connected = true,
        source = "SYNCHRONIZED_EXECUTION",
        display = shortRole .. " -> " .. KWR.Util:Text(target or location, "HOLD", 64),
    }
end

local function addPersonal(packet, job)
    local key = identityKey(job.name, job.guid)
    if key and key ~= "" then packet.personalByKey[key] = job end
    local short = shortName(job.name):lower()
    if short ~= "" then packet.personalByKey[short] = job end
end

local function buildPersonal(packet, snapshot, assignments)
    if packet.objectiveHandoff then
        local handoff = packet.objectiveHandoff
        addPersonal(packet, personalJob(handoff.actor, handoff.actorGUID,
            "Orb Pickup", "PICKUP", handoff.objective, handoff.objective,
            "Pickup", "MOVE", "Prepare to take the next " .. handoff.objective .. "."))
    end
    for _, control in ipairs(packet.controls) do
        if control.assigned then
            addPersonal(packet, personalJob(control.actor, control.actorGUID,
                "Healer Control", "CONTROL", control.target, control.target,
                control.verb, "HOLD", "Control " .. control.target .. " for the kill window."))
        end
    end

    local baseAssignments = assignmentByIdentity(assignments)
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        local key = identityKey(player.name or player.shortName, player.guid)
        local short = shortName(player.name or player.shortName):lower()
        if not packet.personalByKey[key] and not packet.personalByKey[short] then
            local base = baseAssignments[key] or baseAssignments[short]
            if base and isProtectedRole(base.role) then
                addPersonal(packet, personalJob(
                    player.name or player.shortName, player.guid,
                    base.role, KWR.Assignments:CompactRole(base.role),
                    base.location, base.location, "Hold", "STAY",
                    base.directive or base.reason or "Maintain the protected objective role."))
            elseif packet.primaryTarget then
                addPersonal(packet, personalJob(
                    player.name or player.shortName, player.guid,
                    "Kill Team", "KILL", packet.primaryTarget.target,
                    packet.primaryTarget.target, "Kill", "COLLAPSE",
                    "Everyone else collapses on the synchronized kill target."))
            elseif base then
                addPersonal(packet, personalJob(
                    player.name or player.shortName, player.guid,
                    base.role, KWR.Assignments:CompactRole(base.role),
                    base.location, base.location, "Hold", "STAY",
                    base.directive or base.reason or "Maintain your objective assignment."))
            end
        end
    end
end

local function buildLines(packet)
    local lines, speech = {}, {}
    local handoff = packet.objectiveHandoff
    if handoff then
        local orb = handoff.objective:gsub(" Orb$", "")
        lines[#lines + 1] = string.format("NEXT ORB: %s -> PREP %s (%d%%)",
            handoff.actor, orb:upper(), handoff.stacks)
        speech[#speech + 1] = string.format("%s is at %d stacks", orb, handoff.stacks)
        speech[#speech + 1] = handoff.actor .. ", prepare " .. orb .. " pickup"
    end
    for _, control in ipairs(packet.controls) do
        if control.assigned then
            lines[#lines + 1] = string.format("CONTROL: %s -> %s",
                control.actor, control.target)
            speech[#speech + 1] = control.actor .. ", control " .. control.target
        else
            lines[#lines + 1] = "CONTROL: UNASSIGNED -> " .. control.target
            speech[#speech + 1] = control.target .. " is unassigned"
        end
    end
    if packet.primaryTarget then
        local suffix = packet.primaryTarget.objective ~= ""
            and (" [" .. packet.primaryTarget.objective .. "]") or ""
        lines[#lines + 1] = "KILL: EVERYONE ELSE -> "
            .. packet.primaryTarget.target .. suffix
        speech[#speech + 1] = "everyone else, kill " .. packet.primaryTarget.target
            .. (packet.primaryTarget.objective ~= ""
                and (", " .. packet.primaryTarget.objective) or "")
    end
    if packet.trigger ~= "" then
        lines[#lines + 1] = "TRIGGER: " .. packet.trigger
        speech[#speech + 1] = packet.trigger:lower()
    end
    packet.lines = lines
    packet.spokenText = #speech > 0 and (table.concat(speech, ". ") .. ".") or ""
end

function Builder:PersonalFor(packet, playerName, playerGUID)
    if type(packet) ~= "table" or type(packet.personalByKey) ~= "table" then
        return nil
    end
    local key = identityKey(playerName, playerGUID)
    return packet.personalByKey[key] or packet.personalByKey[shortName(playerName):lower()]
end

function Builder:Build(snapshot, prediction, assignments, command)
    snapshot = snapshot or {}
    local teamfight = snapshot.teamfight or {}
    local authoritative = snapshot.context and snapshot.context.inPvP == true
        and snapshot.context.preview ~= true
    local controls = teamfight.displayEligible == true
        and controlAssignments(teamfight) or {}
    controls = preserveProtectedAssignments(controls, assignments)
    local handoff = objectiveHandoff(snapshot, assignments, controls)
    local killTarget = teamfight.displayEligible == true and teamfight.killTarget or nil
    local packet = {
        source = "SYNCHRONIZED_EXECUTION",
        generatedAt = KWR.Util:Now(),
        authoritative = authoritative,
        active = handoff ~= nil or killTarget ~= nil or #controls > 0,
        objectiveHandoff = handoff,
        controls = controls,
        primaryTarget = killTarget and {
            target = callLabel(killTarget.target),
            targetGUID = killTarget.targetGUID,
            objective = objectiveForKill(snapshot, killTarget),
            confidence = killTarget.confidence or "UNKNOWN",
        } or nil,
        countdown = KWR.Util:Copy(teamfight.countdown
            or { seconds = 0, ticks = {}, state = "UNKNOWN" }),
        confidence = teamfight.displayEligible == true
            and (teamfight.confidence or "UNKNOWN")
            or (handoff and handoff.confidence) or "UNKNOWN",
        personalByKey = {},
        commandAction = KWR.Util:Text(command and command.action, "", 180),
        predictionCondition = KWR.Util:Text(prediction and prediction.condition, "", 180),
    }
    if handoff then
        packet.trigger = handoff.healthPercent
            and handoff.healthPercent <= ORB_DROP_HEALTH_THRESHOLD
            and ("GO ON " .. handoff.objective:upper() .. " DROP")
            or ("HOLD UNTIL " .. handoff.objective:upper() .. " DROPS")
    elseif packet.primaryTarget then
        packet.trigger = "GO IN " .. tostring(packet.countdown.seconds or 5)
    else
        packet.trigger = ""
    end
    packet.localFight = buildLocalFight(packet, snapshot)
    if packet.active then
        buildPersonal(packet, snapshot, assignments)
    end
    buildLines(packet)
    packet.audible = packet.authoritative and packet.active
        and packet.spokenText ~= ""
        and packet.confidence ~= "LOW"
        and packet.confidence ~= "UNKNOWN"
    local signatureParts = {
        handoff and handoff.actor or "",
        handoff and handoff.objective or "",
        handoff and handoff.stacks or 0,
        handoff and handoff.urgency or "",
    }
    for index = 1, 3 do
        local control = packet.controls[index] or {}
        signatureParts[#signatureParts + 1] = control.actor or ""
        signatureParts[#signatureParts + 1] = control.verb or ""
        signatureParts[#signatureParts + 1] = control.target or ""
        signatureParts[#signatureParts + 1] = control.assigned and "ASSIGNED" or "UNASSIGNED"
        signatureParts[#signatureParts + 1] = control.state or ""
    end
    signatureParts[#signatureParts + 1] = packet.primaryTarget
        and packet.primaryTarget.target or ""
    signatureParts[#signatureParts + 1] = packet.primaryTarget
        and packet.primaryTarget.objective or ""
    signatureParts[#signatureParts + 1] = packet.localFight.kill
        and packet.localFight.kill.mode or ""
    signatureParts[#signatureParts + 1] = packet.localFight.kill
        and packet.localFight.kill.target or ""
    signatureParts[#signatureParts + 1] = packet.localFight.kill
        and packet.localFight.kill.healthPercent or ""
    signatureParts[#signatureParts + 1] = packet.localFight.kill
        and packet.localFight.kill.location or ""
    signatureParts[#signatureParts + 1] = packet.localFight.phase
    signatureParts[#signatureParts + 1] = packet.trigger
    signatureParts[#signatureParts + 1] = packet.confidence
    packet.signature = KWR.Util:Signature(signatureParts)
    return packet
end

KWR:RegisterModule("ExecutionCommandBuilder", Builder)