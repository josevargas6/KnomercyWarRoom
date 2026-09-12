local _, KWR = ...

-- The HUD's lossless projection extends CommandView; it is not a second planner.
local View = KWR.CommandView
View.CardLimits = { actors = 10, controls = 10, identityBytes = 192, speechBytes = 16384 }
View.CardStrings = {
    now = "NOW / ORDERED POSITION", position = "POSITION / OBSERVED",
    next = "NEXT MOVE / NOT YET ISSUED", duties = "MOVE / STAY / RESERVE",
    localFight = "LOCAL FIGHT", controls = "CC / CONTROL", speech = "SAY NOW",
    feedback = "FOLLOW-THROUGH", unknownPosition = "Position unconfirmed",
    noNext = "No separate next movement issued", release = "Only on a new leader release call",
    noTarget = "No confirmed local target", noControl = "No current control assignment",
    unknownLocation = "Location unconfirmed", unknownActor = "Actor unconfirmed",
    noOrder = "No current order", noTrigger = "Timing unconfirmed",
    fitFailure = "Card does not fit. Use Wide layout or reduce UI scale. Do not rely on hidden rows.",
}

local function finite(value)
    if KWR.Util:IsSecret(value) or type(value) ~= "number" then return nil end
    if value >= 0 and value < math.huge and value == value then return value end
end

local function record(value)
    return not KWR.Util:IsSecret(value) and type(value) == "table" and value or {}
end

local function text(value, fallback, maximum, errors)
    if KWR.Util:IsSecret(value) or type(value) ~= "string" then return fallback or "" end
    if #value > (maximum or 512) then
        if errors then errors[#errors + 1] = "CONTENT_LIMIT" end
        return "[Unsupported overlength content]"
    end
    -- Strip UI escapes, but never clip a character or realm. Reject oversized
    -- inputs before normalization so a malformed input cannot hide truncation.
    return KWR.Util:Text(value, fallback):gsub("|", "")
end

local function packed(parts)
    local result = {}
    for _, value in ipairs(parts) do
        value = tostring(value)
        result[#result + 1] = tostring(#value) .. ":" .. value
    end
    return table.concat(result, "|")
end

local function fullIdentity(value, guid, rows, errors)
    local supplied = text(value, "", View.CardLimits.identityBytes, errors)
    local wantedGUID = text(guid, "", 96, errors)
    local match, count = nil, 0
    for _, row in ipairs(rows or {}) do
        local name = text(row.fullName or row.name, "", View.CardLimits.identityBytes, errors)
        local exactGUID = wantedGUID ~= "" and text(row.guid, "", 96) == wantedGUID
        local exactName = wantedGUID == "" and supplied ~= "" and name == supplied
        if exactGUID or exactName then match, count = row, count + 1 end
    end
    if count == 1 then
        supplied = text(match.fullName or match.name, supplied, View.CardLimits.identityBytes, errors)
        wantedGUID = text(match.guid, wantedGUID, 96, errors)
    end
    -- The commander calls player names, not long realm-qualified identities.
    -- Keep the canonical full name and GUID out of display prose so duplicate
    -- short names cannot be rebound or collapse feedback/review identity.
    local canonical = supplied ~= "" and supplied or View.CardStrings.unknownActor
    return {
        name = KWR.Util:ShortName(canonical),
        canonicalName = canonical,
        guid = wantedGUID ~= "" and wantedGUID or nil,
    }
end

local function actors(values, roster, errors)
    local result = {}
    if type(values) == "string" then
        local list = {}
        for name in values:gmatch("([^,;]+)") do list[#list + 1] = name end
        values = list
    end
    values = record(values)
    if #values > View.CardLimits.actors then errors[#errors + 1] = "ACTOR_LIMIT" end
    for index = 1, math.min(#values, View.CardLimits.actors) do
        local value = values[index]
        local row = record(value)
        local actor = fullIdentity(type(value) == "string" and value
            or row.fullName or row.name or row.actor, row.guid or row.actorGUID, roster, errors)
        actor.job = text(row.role or row.verb, "", 128, errors)
        actor.location = text(row.location, "", 160, errors)
        result[#result + 1] = actor
    end
    return result
end

local function nonempty(values)
    return type(values) == "table" and #values > 0 and values or nil
end

local function rules(values, fallback, errors)
    local result = {}
    for index, value in ipairs(record(values)) do
        if index > 8 then errors[#errors + 1] = "CONDITION_LIMIT" break end
        result[#result + 1] = text(value, "", 512, errors)
    end
    return #result > 0 and table.concat(result, "; ") or text(fallback, "", 512, errors)
end

local function dutyFor(actor, assignments)
    local found, count = nil, 0
    for _, row in ipairs(assignments or {}) do
        if (actor.guid and (row.guid or row.actorGUID) == actor.guid)
            or (not actor.guid and (row.name or row.actor) == actor.canonicalName) then
            found, count = row, count + 1
        end
    end
    return count == 1 and found or {}
end

local function addDuties(result, members, group, assignments, defaultLocation, errors)
    for _, actor in ipairs(members) do
        local assignment = dutyFor(actor, assignments)
        result[#result + 1] = { actor = actor, group = group,
            job = actor.job ~= "" and actor.job or text(assignment.role or assignment.verb, group, 128, errors),
            location = actor.location ~= "" and actor.location or text(assignment.location, defaultLocation, 160, errors) }
    end
end

-- Realm-qualified identity stays internal, while commander speech intentionally
-- uses only the player's short name.  When two identities share that name, the
-- visual card receives a stable ordinal rather than leaking a realm suffix or
-- making the assignment ambiguous.
local function labelVisibleActors(duties, controls)
    local names = {}
    local function add(actor)
        if type(actor) ~= "table" then return end
        local name = actor.name
        local identity = actor.guid or actor.canonicalName
        if type(name) ~= "string" or name == "" or type(identity) ~= "string" then return end
        names[name] = names[name] or {}
        names[name][identity] = names[name][identity] or {}
        names[name][identity][#names[name][identity] + 1] = actor
    end
    for _, duty in ipairs(duties or {}) do add(duty.actor) end
    for _, control in ipairs(controls or {}) do add(control.actor); add(control.target) end
    for _, identities in pairs(names) do
        local ordered = {}
        for identity in pairs(identities) do ordered[#ordered + 1] = identity end
        table.sort(ordered)
        if #ordered > 1 then
            for index, identity in ipairs(ordered) do
                for _, actor in ipairs(identities[identity]) do
                    actor.label = actor.name .. " [" .. tostring(index) .. "]"
                end
            end
        end
    end
end

function View:CommanderCard(state)
    state = record(state)
    local snapshot, command = record(state.snapshot), record(state.command)
    local context, errors = record(snapshot.context), {}
    local strings = self.CardStrings
    local play = record(command.activePlay or state.activePlay)
    local candidate = record(command.activePlayCandidate)
    local response = record(snapshot.responsePackage or command.responsePackage)
    local execution = record(snapshot.executionCommand)
    local localFight = record(execution.localFight)
    local now = finite(KWR.Util:Now())
    local capturedAt = finite(snapshot.capturedAt)
    local stale = context.inPvP == true and context.preview ~= true
        and (not now or not capturedAt or capturedAt > now or now - capturedAt > 5)
    local phase = context.matchComplete == true and "ENDED"
        or (context.preview == true and "PREVIEW") or (context.inPvP ~= true and "SETUP")
        or (stale and "STALE") or "LIVE"
    local card = {
        schemaVersion = 1, errors = errors, phase = phase,
        candidateId = text(KWR.BuildInfo and KWR.BuildInfo.candidateID, "UNBOUND", 128),
        sessionKey = text(context.sessionKey, "", 192),
        commandId = text(command.commandId, "", 512), commandRevision = finite(command.commandRevision),
        map = text(context.mapName or context.mapKey, "Map unconfirmed", 160, errors),
        bracket = context.isBlitz == true and "8v8" or (context.isRated == true and "10v10" or "Bracket unconfirmed"),
        capturedAt = capturedAt, duties = {}, controls = {},
        position = { status = "UNKNOWN", text = strings.unknownPosition },
    }
    local scoreEvidence = KWR.Verification and KWR.Verification:ScoreEvidence(snapshot)
    local scoreKnown = scoreEvidence and KWR.Util:EvidenceUsable(scoreEvidence, "HIGH")
    card.score = scoreKnown and (tostring(scoreEvidence.value.friendly) .. " - " .. tostring(scoreEvidence.value.enemy)) or "-- - --"
    card.winPath = self:StrategicWinPath(state, scoreKnown == true)
    for _, objective in ipairs(record(record(snapshot.objectives).rows)) do
        local deadline = finite(objective.timerEndAt)
        if not deadline and capturedAt and finite(objective.timerRemaining) then
            deadline = capturedAt + objective.timerRemaining
        end
        if deadline and now and deadline > now and deadline - now <= 3600
            and (not card.objectiveClock or deadline < card.objectiveClock.deadline) then
            card.objectiveClock = { deadline = deadline,
                label = text(objective.timerLabel or objective.label or objective.name, "OBJECTIVE", 160, errors),
                source = text(objective.timerSource or objective.source, "UNKNOWN", 64, errors) }
        end
    end
    card.now = { action = text(play.action or command.action, strings.noOrder, 512, errors),
        location = text(play.objective or response.target or record(command.objectiveDecision).target,
            strings.unknownLocation, 160, errors),
        timing = text(command.when, "On leader call", 128, errors),
        condition = text(command.condition, "", 512, errors),
        abort = rules(play.abortRules, command.abort, errors) }
    local movers = actors(nonempty(play.moverActors) or nonempty(play.movers)
        or nonempty(response.moverActors) or nonempty(response.movers)
        or response.moverText or command.who, snapshot.roster, errors)
    local stayers = actors(nonempty(play.stayerActors) or nonempty(response.stayerActors)
        or nonempty(response.stayers) or nonempty(play.stayers), snapshot.roster, errors)
    local reserves = actors(response.reserve or play.reserve, snapshot.roster, errors)
    addDuties(card.duties, movers, "MOVE", state.assignments, card.now.location, errors)
    addDuties(card.duties, stayers, "STAY", state.assignments, strings.unknownLocation, errors)
    addDuties(card.duties, reserves, "RESERVE", state.assignments, strings.unknownLocation, errors)
    local assigned = actors(play.actorAssignments or response.actorAssignments or state.assignments, snapshot.roster, errors)
    for _, actor in ipairs(assigned) do
        local found = false
        for _, duty in ipairs(card.duties) do
            if (actor.guid and actor.guid == duty.actor.guid)
                or actor.canonicalName == duty.actor.canonicalName then
                found = true
                break
            end
        end
        if not found then addDuties(card.duties, { actor }, "ASSIGNED", {}, strings.unknownLocation, errors) end
    end
    if #card.duties > self.CardLimits.actors then errors[#errors + 1] = "DUTY_LIMIT" end
    local dutyOrder = { MOVE = 1, STAY = 2, RESERVE = 3, ASSIGNED = 4 }
    table.sort(card.duties, function(a, b)
        if a.group ~= b.group then return dutyOrder[a.group] < dutyOrder[b.group] end
        if a.job ~= b.job then return a.job < b.job end
        if a.location ~= b.location then return a.location < b.location end
        return (a.actor.guid or a.actor.canonicalName) < (b.actor.guid or b.actor.canonicalName)
    end)
    -- Position fields are not yet typed with a separate observation timestamp
    -- for cached coordinates. Do not promote lastSeenAt or an assignment to presence.
    card.next = { action = strings.noNext, location = strings.unknownLocation,
        trigger = strings.release, movers = {}, abort = "" }
    if candidate.id and play.id and candidate.id ~= play.id then
        card.next = { action = text(candidate.action, strings.noNext, 512, errors),
            location = text(candidate.objective, strings.unknownLocation, 160, errors),
            trigger = text(candidate.trigger, strings.release, 512, errors),
            movers = actors(candidate.moverActors or candidate.movers, snapshot.roster, errors),
            abort = rules(candidate.abortRules, nil, errors),
            deadline = finite(candidate.hardDeadlineAt) }
    end
    local kill = localFight.phase == "ACTIVE" and record(localFight.kill) or {}
    card.localFight = { intent = "UNKNOWN", timing = strings.noTrigger,
        location = strings.unknownLocation, reason = strings.noTarget }
    local executionAt = finite(execution.generatedAt)
    local localFresh = context.preview == true or (now and executionAt
        and executionAt <= now and now - executionAt <= 5)
    if localFresh and kill.target and (kill.mode == "PRESSURE" or kill.mode == "KILL") then
        card.localFight = { intent = kill.mode,
            target = fullIdentity(kill.targetFullName or kill.target, kill.targetGUID, snapshot.enemies, errors),
            location = text(kill.location, strings.unknownLocation, 160, errors),
            timing = kill.mode == "PRESSURE" and "Now; kill window not confirmed" or "On leader call",
            reason = text(kill.reason, "", 512, errors) }
        local countdown = record(execution.countdown)
        local active = KWR.CountdownState and KWR.CountdownState.active
        if kill.mode == "KILL" and active and countdown.id == active.id
            and now and finite(active.startedAt) and finite(active.deadline)
            and now >= active.startedAt and now < active.deadline + 1 then
            card.localFight.timing = "On the shared leader countdown"
            card.countdown = { id = active.id, startedAt = active.startedAt, deadline = active.deadline }
        end
    end
    if #record(localFight.controls) > self.CardLimits.controls then errors[#errors + 1] = "CONTROL_LIMIT" end
    for index = 1, math.min(#record(localFight.controls), self.CardLimits.controls) do
        local control = record(localFight.controls[index])
        card.controls[#card.controls + 1] = {
            actor = fullIdentity(control.actorFullName or control.actor, control.actorGUID, snapshot.roster, errors),
            target = fullIdentity(control.targetFullName or control.target, control.targetGUID, snapshot.enemies, errors),
            verb = text(control.verb, "Control", 128, errors),
            location = text(control.location, strings.unknownLocation, 160, errors),
            timing = text(control.timing or control.trigger, "On leader call", 512, errors),
            status = localFresh and control.assigned == true and control.state == "ACTIVE"
                and "ASSIGNED" or "UNCONFIRMED",
        }
    end
    labelVisibleActors(card.duties, card.controls)
    local speech = { card.now.action .. " - " .. card.now.location .. ". " .. card.now.timing .. "." }
    local identities = { card.candidateId, card.sessionKey, card.commandId, card.commandRevision or 0 }
    if card.now.condition ~= "" then speech[#speech + 1] = card.now.condition end
    local groups, groupOrder = {}, {}
    for _, duty in ipairs(card.duties) do
        local key = packed({ duty.group, duty.job, duty.location })
        if not groups[key] then
            groups[key] = { names = {}, group = duty.group, job = duty.job, location = duty.location }
            groupOrder[#groupOrder + 1] = key
        end
        local group = groups[key]
        group.names[#group.names + 1] = duty.actor.name
        identities[#identities + 1] = duty.actor.guid or duty.actor.canonicalName
    end
    for _, key in ipairs(groupOrder) do
        local group = groups[key]
        speech[#speech + 1] = group.group .. ": " .. table.concat(group.names, ", ")
            .. " - " .. group.job .. " at " .. group.location .. "."
    end
    if card.now.abort ~= "" then speech[#speech + 1] = "Abort: " .. card.now.abort end
    if card.localFight.target then
        local fight = card.localFight
        speech[#speech + 1] = fight.intent .. ": " .. fight.target.name .. " at " .. fight.location .. "; " .. fight.timing .. "."
        identities[#identities + 1] = fight.target.guid or fight.target.canonicalName
    end
    for _, control in ipairs(card.controls) do
        local prefix = control.status == "ASSIGNED" and "" or "Unconfirmed assignment - "
        speech[#speech + 1] = prefix .. control.actor.name .. ": " .. control.verb .. " -> " .. control.target.name
            .. "; " .. control.location .. "; " .. control.timing .. "."
        identities[#identities + 1] = control.actor.guid or control.actor.canonicalName
        identities[#identities + 1] = control.target.guid or control.target.canonicalName
    end
    card.speech = table.concat(speech, "\n")
    if #card.speech > self.CardLimits.speechBytes then errors[#errors + 1] = "SPEECH_LIMIT" end
    identities[#identities + 1] = card.countdown and card.countdown.id or "UNTIMED"
    card.callIdentity = packed(identities)
    card.callKey = packed({ card.callIdentity, card.speech }) -- No lossy signature helper.
    card.eligible = phase == "LIVE" and #errors == 0 and card.commandId ~= ""
        and card.commandRevision ~= nil and card.commandRevision >= 1
        and card.commandRevision == math.floor(card.commandRevision) and card.sessionKey ~= ""
    if phase == "ENDED" or phase == "STALE" then
        card.speech = phase == "ENDED" and "Match ended. Tactical calls closed." or "Call expired. Verify the current order."
        card.localFight = { intent = "UNKNOWN", reason = strings.noTarget, timing = strings.noTrigger,
            location = strings.unknownLocation }
        card.controls = {}
    end
    return card
end
