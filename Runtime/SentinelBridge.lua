local _, KWR = ...

local SentinelBridge = {}
KWR.SentinelBridge = SentinelBridge

local function text(value, fallback, maximum)
    return KWR.Util:Text(value, fallback or "", maximum or 180)
end

local function number(value, fallback)
    return KWR.Util:Number(value, fallback)
end

local function shortName(value)
    return KWR.Util:ShortName(text(value, "", 64))
end

local function clockOrUnknown(value)
    value = number(value, nil)
    return value and KWR.Util:Clock(value) or "unknown"
end

local function assignmentFor(assignments, playerName)
    local wanted = shortName(playerName):lower()
    if wanted == "" then return nil end
    for _, assignment in ipairs(assignments or {}) do
        if shortName(assignment.name):lower() == wanted
            or shortName(assignment.shortName):lower() == wanted then
            return assignment
        end
    end
    return nil
end

local function locationText(mapKey, value)
    local clean = text(value, "", 64)
    if clean == "" then return "unknown" end
    return KWR.Maps:AbbreviateLocation(mapKey, clean)
end

local function auraSummary(auras)
    local lines = {}
    for index = 1, math.min(3, #(auras or {})) do
        local aura = auras[index]
        local name = text(aura and aura.name, "", 48)
        if name ~= "" then
            local stacks = number(aura and aura.stacks, 0) or 0
            lines[#lines + 1] = name .. (stacks > 0 and (" x" .. tostring(stacks)) or "")
        end
    end
    return #lines > 0 and table.concat(lines, ", ") or "none observed"
end

local function synchronizedAssignment(snapshot, playerName)
    local packet = snapshot and snapshot.executionCommand
    if not packet or not KWR.ExecutionCommandBuilder then return nil end
    return KWR.ExecutionCommandBuilder:PersonalFor(packet, playerName, nil)
end

local function playerRecord(snapshot, playerName)
    local wanted = shortName(playerName):lower()
    if wanted == "" then return nil end
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        if shortName(player.name):lower() == wanted
            or shortName(player.shortName):lower() == wanted then
            return player
        end
    end
    return nil
end

local function buildAssignment(snapshot, assignments, playerName)
    local synchronized = synchronizedAssignment(snapshot, playerName)
    local assignment = synchronized or assignmentFor(assignments, playerName)
    if not assignment then
        return {
            role = "Unassigned",
            shortRole = "NONE",
            location = "Await commander sync",
            detail = "No player assignment is available yet.",
            connected = false,
        }
    end
    local result = {
        name = text(assignment.name, playerName, 64),
        shortName = text(assignment.shortName, shortName(playerName), 32),
        role = text(assignment.role, "Unassigned", 48),
        shortRole = KWR.Assignments:CompactRole(assignment.role),
        location = locationText(snapshot.context and snapshot.context.mapKey, assignment.location),
        detail = text(assignment.directive or assignment.reason
            or assignment.coverageEffect or assignment.backupRole,
            "Assignment is live.", 160),
        connected = assignment.connected ~= false,
        dead = assignment.dead == true,
        manualOverride = assignment.manualOverride == true,
        carrierStacks = number(assignment.carrierStacks, 0) or 0,
        target = text(assignment.target, "", 64),
        targetGUID = text(assignment.targetGUID, "", 96),
        verb = text(assignment.verb, "", 24),
        movement = text(assignment.movement, "", 24),
        source = text(assignment.source,
            synchronized and "SYNCHRONIZED_EXECUTION" or "COMMANDER", 32),
    }
    if synchronized then
        result.shortRole = text(synchronized.shortRole, result.shortRole, 24)
        result.location = locationText(
            snapshot.context and snapshot.context.mapKey,
            synchronized.location)
        result.detail = text(synchronized.detail, result.detail, 160)
        result.executionSignature = text(snapshot.executionCommand.signature, "", 240)
    end
    return result
end

local function buildScore(state)
    local snapshot = state.snapshot or {}
    local prediction = state.prediction or {}
    local score = snapshot.score or {}
    local command = state.command or {}
    local mapKey = snapshot.context and snapshot.context.mapKey
    local definition = KWR.Maps:Get(mapKey)
    return {
        mapKey = mapKey,
        mapName = text(snapshot.context and snapshot.context.mapName, "World", 64),
        mapShort = definition and definition.short or text(mapKey, "WORLD", 16),
        status = text(prediction.status
            or (snapshot.context and snapshot.context.inPvP and "WAITING" or "WORLD"),
            "WAITING", 16),
        friendly = number(score.friendly, 0) or 0,
        enemy = number(score.enemy, 0) or 0,
        max = number(score.max, 0) or 0,
        timeToWin = clockOrUnknown(prediction.timeToWin),
        friendlyTime = clockOrUnknown(prediction.friendlyTime),
        enemyTime = clockOrUnknown(prediction.enemyTime),
        commandWhen = text(command.when, "WAIT", 32),
        condition = text(prediction.condition, "Waiting for live battleground data.", 160),
        action = text(command.action or prediction.action, "Play the objective.", 180),
    }
end

local function buildRequirement(state, assignment)
    local command = state.command or {}
    local prediction = state.prediction or {}
    local detail = text(assignment and assignment.detail, "", 160)
    local holdLine = text(command.action
        or prediction.condition
        or detail, "Hold current assignment.", 160)
    local winLine = text(prediction.action
        or command.line2
        or detail, "Win the next objective exchange.", 160)
    return {
        holdLine = holdLine,
        winLine = winLine,
    }
end

local function buildDeathZone(snapshot)
    local execution = snapshot.strategy and snapshot.strategy.executionAssessment or {}
    local collapse = execution.collapse or {}
    local forecast = execution.pressureForecast or {}
    local recovery = execution.recovery or {}
    local hotspot = snapshot.reporter and snapshot.reporter.hotspot or {}
    local label = locationText(snapshot.context and snapshot.context.mapKey,
        forecast.target or hotspot.label or "current fight")

    if collapse.state == "CRITICAL" then
        return {
            state = "ACTIVE",
            label = label,
            score = number(collapse.score, 0) or 0,
            response = text(collapse.response, "DISENGAGE_RESET", 32),
            detail = text(table.concat(collapse.evidence or {}, ", "),
                "Collapse risk is critical.", 160),
        }
    end
    if forecast.state == "RISING" then
        return {
            state = "BUILDING",
            label = label,
            score = number(forecast.score, 0) or 0,
            response = "PREPARE",
            detail = text(table.concat(forecast.evidence or {}, ", "),
                "Pressure is building at the current hotspot.", 160),
        }
    end
    if recovery.open == true then
        return {
            state = "RECOVERY",
            label = label,
            score = number(recovery.score, 0) or 0,
            response = text(recovery.response, "RESET_REASSIGN", 32),
            detail = "Collapse pressure has eased; recovery window is open.",
        }
    end
    return {
        state = "NONE",
        label = label,
        score = 0,
        response = "HOLD_PLAN",
        detail = "No qualified death-zone signal is active.",
    }
end

local function buildWatch(snapshot, personal)
    local combat = snapshot.combat or {}
    local watch = combat.localTarget or combat.killTarget
    local priorityCast = combat.priorityCast
    if watch and watch.priorityCast then
        priorityCast = watch.priorityCast
    end
    local personalTarget = personal and text(personal.target, "", 64) or ""
    if personalTarget ~= "" and (personal.shortRole == "CONTROL" or personal.shortRole == "KILL") then
        local wanted = personalTarget:lower()
        local matched
        for _, enemy in ipairs(snapshot.enemies or {}) do
            if text(enemy.shortName or enemy.name, "", 64):lower() == wanted
                or (personal.targetGUID ~= "" and enemy.guid == personal.targetGUID) then
                matched = enemy
                break
            end
        end
        watch = KWR.Util:Copy(matched or {
            name = personalTarget,
            shortName = personalTarget,
            guid = personal.targetGUID,
        })
        watch.mode = personal.shortRole == "CONTROL" and "CONTROL" or "KILL"
        watch.reason = personal.detail
    end
    if not watch then
        return {
            name = "No local target",
            role = "UNKNOWN",
            healthPercent = nil,
            castName = nil,
            castPriority = nil,
            reason = text(combat.localTargetReason or combat.killReason,
                "No safely observed enemy in local fight range.", 160),
            cooldownText = nil,
        }
    end
    return {
        key = text(watch.key or watch.guid or watch.name, "", 96),
        name = text(watch.name, "Unknown", 64),
        shortName = text(watch.shortName or shortName(watch.name), "Unknown", 32),
        role = text(watch.role, "UNKNOWN", 24),
        healthPercent = number(watch.healthPercent, nil),
        cooldownText = text(watch.cooldownText, "", 64),
        castName = text(priorityCast and priorityCast.name, "", 64),
        castPriority = text(priorityCast and priorityCast.priority, "", 24),
        castSource = text(priorityCast and priorityCast.source, "", 32),
        reason = text(watch.reason or combat.localTargetReason or combat.killReason,
            "Local target data is available.", 160),
        carrier = watch.carrier == true,
        unit = text(watch.unit, "", 32),
        trinket = text(watch.trinket, "", 32),
        mode = text(watch.mode or watch.targetMode, "", 24),
        target = text(watch.target or watch.shortName or watch.name, "", 64),
    }
end

local function buildCarriers(snapshot)
    local carriers = {}
    for _, carrier in ipairs(snapshot.objectives and snapshot.objectives.carriers or {}) do
        carriers[#carriers + 1] = {
            objective = text(carrier.objective, "Objective", 48),
            owner = text(carrier.owner, "UNKNOWN", 16),
            player = text(carrier.player, "Unknown", 64),
            healthPercent = number(carrier.healthPercent, nil),
            stacks = number(carrier.stacks, 0) or 0,
            visible = carrier.visible == true,
            location = carrier.visible == true and "VISIBLE"
                or text(carrier.mapSource, "LAST KNOWN", 24),
            auraText = auraSummary(carrier.auras),
        }
    end
    return carriers
end

local function teamSummaryRow(snapshot, player, assignment, isSelf)
    local mapKey = snapshot.context and snapshot.context.mapKey
    local label = assignment and KWR.Assignments:CompactLabel(assignment, mapKey) or "UNASSIGNED"
    return {
        key = text(player.key or player.guid or player.name, "", 96),
        name = text(player.shortName or player.name, "Unknown", 64),
        classFile = text(player.classFile, "", 24),
        spec = text(player.spec, "", 32),
        healthPercent = number(player.healthPercent, nil),
        connected = player.connected ~= false,
        dead = player.dead == true,
        detail = text(label, "UNASSIGNED", 96),
        assignmentRole = text(assignment and assignment.shortRole, "", 24),
        assignmentLocation = locationText(mapKey, assignment and assignment.location),
        isSelf = isSelf == true,
    }
end

local function buildTeamSummary(snapshot, assignments, playerName)
    local rows = {}
    local byName = {}
    for _, assignment in ipairs(assignments or {}) do
        local full = shortName(assignment.name):lower()
        local short = shortName(assignment.shortName):lower()
        if full ~= "" then byName[full] = assignment end
        if short ~= "" then byName[short] = assignment end
    end
    local selfKey = shortName(playerName):lower()
    local pending = {}
    for _, player in ipairs(snapshot.roster or {}) do
        local key = shortName(player.name or player.shortName):lower()
        local row = teamSummaryRow(snapshot, player, byName[key], key == selfKey)
        if key == selfKey then
            rows[#rows + 1] = row
        else
            pending[#pending + 1] = row
        end
    end
    table.sort(pending, function(left, right)
        local leftDead = left.dead == true and 1 or 0
        local rightDead = right.dead == true and 1 or 0
        if leftDead ~= rightDead then return leftDead < rightDead end
        local leftHealth = number(left.healthPercent, -1) or -1
        local rightHealth = number(right.healthPercent, -1) or -1
        if leftHealth ~= rightHealth then return leftHealth > rightHealth end
        return left.name < right.name
    end)
    for index = 1, math.min(#pending, 7) do
        rows[#rows + 1] = pending[index]
    end
    return rows
end

local function enemyStatus(enemy)
    if enemy.dead == true then return "DEAD" end
    if enemy.localEngaged == true then return "ENGAGED" end
    if enemy.localRange == true then return "LOCAL" end
    if enemy.visible == true then return "SEEN" end
    return text(enemy.locationState, "TRACKED", 24)
end

local function enemyDetail(enemy, mapKey)
    local location = locationText(mapKey, enemy.location)
    local age = number(enemy.lastSeenAge, nil)
    local ageText = age and tostring(math.floor(age + 0.5)) or nil
    if enemy.priorityCast and enemy.priorityCast.name then
        return "CAST " .. text(enemy.priorityCast.name, "CAST", 48)
    end
    if enemy.cooldownText and enemy.cooldownText ~= "" then
        return text(enemy.cooldownText, "TRACKED", 64)
    end
    if enemy.localEngaged == true then
        return location ~= "unknown" and ("LIVE " .. location) or "LIVE"
    end
    if enemy.localRange == true or enemy.visible == true then
        return location ~= "unknown" and ("SEEN " .. location) or "SEEN"
    end
    if ageText and location ~= "unknown" then
        return "LAST " .. ageText .. " " .. location
    end
    if location ~= "unknown" then
        return "LAST " .. location
    end
    return text(KWR.EnemyIntel:DescribeLocation(enemy, mapKey, true), "TRACKED", 64)
end

local function enemyIntent(personal, enemy)
    local role = text(personal and personal.shortRole, "", 24)
    local wantedGUID = text(personal and personal.targetGUID, "", 96)
    local wantedName = shortName(personal and personal.target):lower()
    local enemyName = shortName(enemy.shortName or enemy.name):lower()
    local match = (wantedGUID ~= "" and wantedGUID == text(enemy.guid, "", 96))
        or (wantedName ~= "" and wantedName == enemyName)
    if match ~= true then
        return nil
    end
    if role == "KILL" then
        return "KILL"
    end
    if role == "CONTROL" then
        return "CC"
    end
    return nil
end

local function buildEnemySummary(snapshot, personal)
    local mapKey = snapshot.context and snapshot.context.mapKey
    local rows = {}
    local watchedKey = text(personal and personal.targetGUID, "", 96)
    local watchedName = shortName(personal and personal.target):lower()
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local match = (watchedKey ~= "" and enemy.guid == watchedKey)
            or (watchedName ~= "" and shortName(enemy.shortName or enemy.name):lower() == watchedName)
        rows[#rows + 1] = {
            key = text(enemy.key or enemy.guid or enemy.name, "", 96),
            name = text(enemy.shortName or enemy.name, "Unknown", 64),
            classFile = text(enemy.classFile, "", 24),
            spec = text(enemy.spec, "", 32),
            unit = text(enemy.unit, "", 32),
            guid = text(enemy.guid, "", 96),
            healthPercent = number(enemy.healthPercent, nil),
            detail = enemyDetail(enemy, mapKey),
            status = enemyStatus(enemy),
            watched = match,
            dead = enemy.dead == true,
            visible = enemy.visible == true,
            localEngaged = enemy.localEngaged == true,
            localRange = enemy.localRange == true,
            location = locationText(mapKey, enemy.location),
            lastSeenAge = number(enemy.lastSeenAge, nil),
            intent = enemyIntent(personal, enemy),
        }
    end
    table.sort(rows, function(left, right)
        local leftWatched = left.watched == true and 1 or 0
        local rightWatched = right.watched == true and 1 or 0
        if leftWatched ~= rightWatched then return leftWatched > rightWatched end
        local order = {
            ENGAGED = 5,
            LOCAL = 4,
            SEEN = 3,
            ["LAST SEEN"] = 2,
            TRACKED = 1,
            DEAD = 0,
        }
        local leftOrder = order[left.status] or 0
        local rightOrder = order[right.status] or 0
        if leftOrder ~= rightOrder then return leftOrder > rightOrder end
        local leftHealth = number(left.healthPercent, -1) or -1
        local rightHealth = number(right.healthPercent, -1) or -1
        if leftHealth ~= rightHealth then return leftHealth < rightHealth end
        return left.name < right.name
    end)
    while #rows > 8 do
        table.remove(rows)
    end
    return rows
end

function SentinelBridge:BuildView(playerName, state)
    state = state or (KWR.Store and KWR.Store:Get())
    if not state or type(state) ~= "table" or type(state.snapshot) ~= "table" then
        return nil
    end
    local snapshot = state.snapshot
    local _, line2, line3 = KWR.CommandView:SummaryLines(state)
    local assignment = buildAssignment(snapshot, state.assignments, playerName)
    local execution = snapshot.executionCommand or {}
    return {
        source = "KWR",
        revision = number(state.revision, 0) or 0,
        mode = text(state.mode,
            snapshot.context and snapshot.context.preview and "PREVIEW" or "LIVE",
            24),
        mapKey = text(snapshot.context and snapshot.context.mapKey, "WORLD", 24),
        assignment = assignment,
        trustState = "LOCAL KWR",
        score = buildScore(state),
        requirement = buildRequirement(state, assignment),
        deathZone = buildDeathZone(snapshot),
        watch = buildWatch(snapshot, assignment),
        carriers = buildCarriers(snapshot),
        roster = {
            self = teamSummaryRow(snapshot, playerRecord(snapshot, playerName) or {}, assignment, true),
            team = buildTeamSummary(snapshot, state.assignments, playerName),
            enemy = buildEnemySummary(snapshot, assignment),
        },
        command = {
            line2 = text(line2, "", 220),
            line3 = text(line3, "", 220),
            action = text(state.command and state.command.action, "", 180),
        },
        execution = {
            source = text(execution.source, "", 32),
            signature = text(execution.signature, "", 240),
            confidence = text(execution.confidence, "UNKNOWN", 24),
            trigger = text(execution.trigger, "", 96),
            active = execution.active == true,
        },
    }
end

KWR:RegisterModule("SentinelBridge", SentinelBridge)