local _, KWR = ...

local CommandView = {}
KWR.CommandView = CommandView

local SHORT_ACTIONS = {
    REINFORCE = "REINFORCE",
    REALLOCATE = "PEEL",
    CONTAIN_TRADE = "STALL + TRADE",
    PREPARE_PRESSURE = "SET DEF",
    ROTATE = "ROTATE",
    DISENGAGE_RESET = "RESET",
    STALL_OR_TRADE = "STALL + TRADE",
    RESET_REASSIGN = "RESET",
    HOLD_PLAN = "HOLD",
}

local function shortAction(action, actionID)
    local fixed = SHORT_ACTIONS[KWR.Util:Upper(actionID, "", 32)]
    if fixed then return fixed end
    local upper = KWR.Util:Upper(action, "", 220)
    if upper:find("PEEL", 1, true)
        or upper:find("PROTECT OUR CARRIER", 1, true)
        or upper:find("COVER OUR FC", 1, true) then
        return "PEEL"
    end
    if upper:find("ESCORT", 1, true) then return "ESCORT" end
    if upper:find("RETURN", 1, true) or upper:find("COLLAPSE ON EFC", 1, true) then
        return "RETURN"
    end
    if upper:find("REINFORCE", 1, true) then return "REINFORCE" end
    if upper:find("ROTATE", 1, true) then return "ROTATE" end
    if upper:find("RESET", 1, true) or upper:find("REGROUP", 1, true) then
        return "RESET"
    end
    if upper:find("STALL", 1, true) then return "STALL" end
    if upper:find("CONTAIN", 1, true) or upper:find("TRADE", 1, true) then
        return "STALL + TRADE"
    end
    if upper:find("PREPARE DEFENSE", 1, true) then return "SET DEF" end
    if upper:find("DEFEND", 1, true) or upper:find("HOLD", 1, true)
        or upper:find("PRESERVE", 1, true) then
        return "HOLD"
    end
    if upper:find("CAPTURE", 1, true) or upper:find("TAKE ", 1, true) then
        return "CAP"
    end
    if upper:find("STOP", 1, true) or upper:find("DENY", 1, true) then
        return "STOP"
    end
    if upper:find("PUSH", 1, true) or upper:find("PRESS", 1, true)
        or upper:find("COLLAPSE", 1, true) then
        return "PRESS"
    end
    return "PLAY OBJ"
end

local function compactNames(value, maxItems)
    local items = {}
    if type(value) == "table" then
        for _, name in ipairs(value) do
            local clean = KWR.Util:Text(name, "", 64)
            if clean ~= "" and not clean:match("^%+%d+$") then
                items[#items + 1] = clean
            end
        end
    else
        local source = KWR.Util:Text(value, "", 480)
        for token in source:gmatch("([^,;]+)") do
            local clean = token:gsub("^%s+", ""):gsub("%s+$", "")
            if clean ~= "" and not clean:match("^%+%d+$") then
                items[#items + 1] = clean
            end
        end
    end
    if #items == 0 then return "TEAM" end
    if #items == 1 and items[1]:upper() == "TEAM" then return "TEAM" end
    local visible = {}
    local limit = maxItems and math.min(#items, maxItems) or #items
    for index = 1, limit do
        visible[#visible + 1] = KWR.Util:TextClip(items[index], "", 32)
    end
    if maxItems and #items > limit then
        for index = limit + 1, #items do
            visible[#visible + 1] = KWR.Util:TextClip(items[index], "", 32)
        end
    end
    return table.concat(visible, ", ")
end

local function safeLocation(mapKey, location, action)
    local value = KWR.Util:Text(location, "", 64)
    local lower = value:lower()
    if value == "" or lower == "unknown" or lower == "current objective"
        or lower:find(" has been ", 1, true)
        or lower:find(" was picked ", 1, true)
        or lower:find(" was dropped ", 1, true)
        or lower:find(" was returned ", 1, true) then
        local upperAction = KWR.Util:Upper(action, "", 220)
        if upperAction:find("EFC", 1, true)
            or upperAction:find("ENEMY CARRIER", 1, true) then
            return "EFC"
        end
        if upperAction:find("OUR FC", 1, true)
            or upperAction:find("OUR CARRIER", 1, true) then
            return "OFC"
        end
        if upperAction:find("HOME", 1, true) then return "HOME" end
        return "FIELD"
    end
    return KWR.Util:Upper(KWR.Maps:AbbreviateLocation(mapKey, value), "FIELD", 24)
end

local function callWhen(play, command, current)
    if current then
        return KWR.Util:Upper(command and command.when, "NOW", 20)
    end
    local arrival = KWR.Util:Number(play and play.expectedArrivalAt, nil)
    if arrival then
        local seconds = math.max(0, math.ceil(arrival - KWR.Util:Now()))
        return seconds > 0 and ("IN " .. KWR.Util:Clock(seconds)) or "NOW"
    end
    return "NEXT FIGHT"
end

local function callModel(play, command, response, mapKey, current, moverLimit)
    play = type(play) == "table" and play or {}
    response = type(response) == "table" and response or {}
    local action = KWR.Util:Text(play.action or command.action, "Play objective.", 220)
    local where = safeLocation(mapKey,
        play.objective or response.target or response.shortTarget
            or (command.objectiveDecision and command.objectiveDecision.target),
        action)
    local movers = play.movers and #play.movers > 0 and play.movers or nil
    if not movers and type(response.movers) == "table" and #response.movers > 0 then
        movers = response.movers
    end
    local who = compactNames(movers or response.moverText or command.who, moverLimit)
    return {
        what = shortAction(action, current and response.actionID or nil),
        who = who,
        where = where,
        when = callWhen(play, command, current),
    }
end

local function projectionText(status)
    status = KWR.Util:Upper(status, "WAIT", 16)
    if status == "VICTORY" then return "LOCK WIN", "RECOVERY" end
    if status == "DEFEAT" then return "LOCK LOSS", "KILL" end
    if status == "WIN" then return "LIKELY WIN", "RECOVERY" end
    if status == "LOSE" then return "LIKELY LOSS", "KILL" end
    if status == "TIE" then return "TOSS UP", "CARRY" end
    return "WAIT", "STALE"
end

local function winPath(kind, status, prediction)
    kind = KWR.Util:Upper(kind, "BG", 16)
    status = KWR.Util:Upper(status, "WAIT", 16)
    if status == "VICTORY" then return "WIN SECURED" end
    if status == "DEFEAT" then return "MATCH COMPLETE" end
    if kind == "FLAG" then
        if status == "WIN" then return "PROTECT LEAD" end
        if status == "LOSE" then return "RETURN + CAP" end
        return "WIN NEXT CAP"
    end
    if kind == "NODE" or kind == "HYBRID" then
        local friendly = KWR.Util:Number(prediction.friendlyObjectives, nil)
        local needed = KWR.Util:Number(prediction.neededObjectives, nil)
        if status == "WIN" and friendly then return "HOLD " .. tostring(friendly) end
        if status == "LOSE" and needed and needed > 0 then
            return "TAKE +" .. tostring(needed)
        end
        return status == "LOSE" and "STOP INC + CAP" or "WIN NEXT BASE"
    end
    if kind == "ORB" then
        return status == "WIN" and "HOLD ORBS"
            or (status == "LOSE" and "WIN MID + ORBS" or "WIN NEXT ORB")
    end
    if kind == "CART" then
        return status == "WIN" and "HOLD CART LEAD"
            or (status == "LOSE" and "FLIP CART COUNT" or "WIN NEXT CART")
    end
    if kind == "RESOURCE" then
        return status == "WIN" and "HOLD NODE LEAD"
            or (status == "LOSE" and "WIN NEXT NODE" or "WIN NEXT SCORE")
    end
    return status == "WIN" and "HOLD LEAD"
        or (status == "LOSE" and "WIN NEXT SCORE" or "BREAK TIE")
end

local function knownLocalTarget(value)
    local target = KWR.Util:Text(value, "", 64)
    local upper = target:upper()
    return target ~= "" and upper ~= "U" and upper ~= "UNKNOWN"
        and upper ~= "UNKNOWN TARGET"
end

local function localFightCall(snapshot, current)
    local execution = snapshot and snapshot.executionCommand or {}
    local localFight = execution.localFight or {}
    local kill = localFight.phase == "ACTIVE" and localFight.kill or nil
    if not kill or not knownLocalTarget(kill.target) then return nil end
    local result = KWR.Util:Copy(current)
    result.what = kill.mode == "PRESSURE" and "PRESS" or "KILL"
    result.where = safeLocation(snapshot.context and snapshot.context.mapKey,
        kill.location, result.what)
    result.when = "NOW"
    result.localTarget = KWR.Util:ShortName(kill.target)
    result.source = "LOCAL_FIGHT"
    return result
end

function CommandView:CompactMapText(mapKey, text, fallback, limit)
    local value = KWR.Util:Text(text, fallback or "", limit or 96)
    if mapKey and KWR.Maps and type(KWR.Maps.AbbreviateText) == "function" then
        value = KWR.Maps:AbbreviateText(mapKey, value)
    end
    return KWR.Util:Text(value, fallback or "", limit or 96)
end

function CommandView:FightNow(state)
    state = state or {}
    local snapshot = state.snapshot or {}
    local context = snapshot.context or {}
    local command = state.command or {}
    local prediction = state.prediction or {}
    local response = snapshot.responsePackage or command.responsePackage or {}
    local activePlay = command.activePlay or state.activePlay or {}
    local candidate = command.activePlayCandidate or {}
    local strategicCurrent = callModel(
        activePlay, command, response, context.mapKey, true, nil)
    local current = localFightCall(snapshot, strategicCurrent) or strategicCurrent
    local nextCall
    if current.source == "LOCAL_FIGHT" then
        nextCall = KWR.Util:Copy(strategicCurrent)
        nextCall.when = "AFTER FIGHT"
    elseif candidate.id and activePlay.id and candidate.id ~= activePlay.id then
        nextCall = callModel(candidate, command, response, context.mapKey, false, nil)
    else
        nextCall = {
            what = "HOLD",
            who = current.who,
            where = current.where,
            when = "UNTIL CHANGE",
        }
    end
    local definition = KWR.Maps and KWR.Maps:Get(context.mapKey)
    local shortMap = definition and definition.short or "BG"
    local score = snapshot.score or {}
    local projection, projectionTone = projectionText(prediction.status or command.status)
    local defense = KWR.Util:Text(response.stayerText, "", 160)
    if defense == "" or defense == "Assigned defenders" then
        defense = "ASSIGNED DEF"
    else
        defense = KWR.Maps:AbbreviateText(context.mapKey, defense)
    end
    return {
        score = string.format("%s %d - %d", shortMap,
            KWR.Util:Number(score.friendly, 0) or 0,
            KWR.Util:Number(score.enemy, 0) or 0),
        projection = projection,
        projectionTone = projectionTone,
        winPath = winPath(context.kind, prediction.status or command.status, prediction),
        nextObjective = nextCall.where ~= "FIELD" and nextCall.where or current.where,
        current = current,
        next = nextCall,
        defense = KWR.Util:Upper(defense, "ASSIGNED DEF", 72),
        offense = current.who .. " -> " .. current.where,
    }
end

function CommandView:DisplayCallVerb(verb, context)
    local label = KWR.Util:Upper(verb, "", 16)
    if context and context.inPvP ~= true then
        return "ASSIGN"
    end
    if label == "CONFIRM" then return "ASSIGN" end
    if label == "SCOUT" then return "CHECK" end
    if label == "PUSH" or label == "GO" or label == "HOLD"
        or label == "ROTATE" or label == "PEEL" or label == "SEND" then
        return label
    end
    return label ~= "" and label or "SEND"
end

function CommandView:RawCallVerb(command, context)
    command = command or {}
    if context and context.inPvP ~= true then
        return "CONFIRM"
    end
    return command.status == "WIN" and "HOLD" or "SEND"
end

function CommandView:CallVerb(command, context)
    return self:DisplayCallVerb(self:RawCallVerb(command, context), context)
end

function CommandView:CallMovers(command)
    return tostring(command and command.who or "Team")
end

function CommandView:CallStayers(command)
    local response = command and command.responsePackage or {}
    local stayerText = KWR.Util:Text(response.stayerText, "", 480)
    if response.qualified == true and stayerText ~= ""
        and stayerText ~= "Assigned defenders" then
        return stayerText
    end
end

function CommandView:StatusColor(status)
    if status == "WIN" or status == "VICTORY" then return "green" end
    if status == "LOSE" or status == "DEFEAT" then return "red" end
    if status == "TIE" then return "yellow" end
    return "gold"
end

function CommandView:BadgeState(state)
    local context = state and state.snapshot and state.snapshot.context or {}
    local command = state and state.command or {}
    local urgency = KWR.Util:Number(command.urgency, 0) or 0
    if context.preview == true then return "orange", "PREVIEW" end
    if context.inPvP ~= true then return "muted", "SETUP" end
    if command.reassessment then return "orange", "UPDATED" end
    if urgency >= 85 then return "red", "URGENT" end
    if urgency >= 60 then return "yellow", "PRESSURE" end
    return self:StatusColor(command.status), KWR.Util:Text(command.status, "LIVE", 12)
end

function CommandView:ActionText(command, fallback, limit)
    command = command or {}
    return KWR.Util:Text(command.action, fallback or "", limit or 180)
end

function CommandView:MapActionText(command, mapKey, fallback, limit)
    return self:CompactMapText(mapKey,
        self:ActionText(command, fallback or "", limit or 96),
        fallback or "", limit or 96)
end

function CommandView:CommandStatusText(command)
    command = command or {}
    return KWR.Util:Text(command.status, "LIVE", 18)
        .. "  |  " .. tostring(command.confidence or "NONE") .. " CONFIDENCE"
end

function CommandView:TimingConfidenceText(command)
    command = command or {}
    return "WHEN: " .. tostring(command.when or "NOW")
end

function CommandView:ActionLine(command, fallback, limit)
    return "ACTION: " .. self:ActionText(command, fallback or "PLAY OBJECTIVE", limit or 220)
end

function CommandView:AssignmentLine(command)
    command = command or {}
    return "WHO: " .. KWR.Util:Text(command.who, "Team", 220)
end

function CommandView:TriggerLine(command, state, fallback)
    command = command or {}
    local objectiveDecision = command.objectiveDecision or {}
    local mapKey = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.mapKey
    if command.switchIf and command.switchIf ~= "" then
        return "TRIGGER: " .. self:CompactMapText(mapKey, command.switchIf, "", 120)
    end
    if objectiveDecision.success and objectiveDecision.success ~= "" then
        return "TRIGGER: " .. self:CompactMapText(mapKey, objectiveDecision.success, "", 120)
    end
    if objectiveDecision.abort and objectiveDecision.abort ~= "" then
        return "ABORT: " .. self:CompactMapText(mapKey, objectiveDecision.abort, "", 120)
    end
    return fallback or ("TRIGGER: " .. tostring(command.when or "NOW"))
end

function CommandView:SummaryLines(state)
    state = state or {}
    local snapshot = state.snapshot or {}
    local context = snapshot.context or {}
    local command = state.command or {}
    local score = snapshot.score or {}
    local formation = snapshot.formation or {}
    local definition = KWR.Maps and KWR.Maps.Get and KWR.Maps:Get(context.mapKey) or nil
    local shortMap = definition and definition.short or (context.inPvP and "BG" or "WORLD")
    local scoreText = not context.inPvP and
        (tostring(formation.players or 0) .. "/" .. tostring(formation.targetSize or 10))
        or score.max and score.max > 0
        and (tostring(score.friendly or 0) .. "-" .. tostring(score.enemy or 0))
        or "NO SCORE"
    local line1 = KWR.Util:Text((context.preview and "PREVIEW " or "")
        .. shortMap .. " " .. scoreText .. " "
        .. KWR.Util:Text(command.status, "LIVE", 18), "KWR READY", 64)
    return line1,
        self:ActionLine(command, "PLAY OBJECTIVE", 260),
        self:AssignmentLine(command)
end

function CommandView:PrimaryLines(state, fallback)
    state = state or {}
    local command = state.command or {}
    return {
        self:ActionLine(command, fallback or "PLAY OBJECTIVE", 220),
        self:AssignmentLine(command),
        self:TriggerLine(command, state),
    }
end

function CommandView:CompactPrimaryLines(state, fallback)
    state = state or {}
    local command = state.command or {}
    local lines = {
        self:ActionLine(command, fallback or "PLAY OBJECTIVE", 88),
    }
    local movers = self:CallMovers(command)
    if movers and movers ~= "" and movers ~= "Team" then
        lines[#lines + 1] = "WHO: " .. KWR.Util:Text(movers, "", 56)
    end
    return lines
end

function CommandView:SpokenCall(command, context, actionLimit)
    command = command or {}
    context = context or {}
    local action = KWR.Util:Text(command.action, "", actionLimit or 180)
    local movers = self:CallMovers(command)
    local stayers = self:CallStayers(command)
    local firstMover = movers:match("^[^,]+")
    local actionNamesMovers = firstMover and firstMover ~= "Team"
        and action:find(firstMover, 1, true) ~= nil
    local lines = { action }
    if context.inPvP and not actionNamesMovers then
        lines[#lines + 1] = self:CallVerb(command, context) .. ": " .. movers
    end
    if stayers then
        lines[#lines + 1] = "STAY: " .. stayers
    end
    if context.inPvP and command.verificationReason then
        lines[#lines + 1] = "CHECK: " .. KWR.Util:Text(command.verificationReason, "", 110)
    end
    if context.inPvP and command.knowledgeReason then
        lines[#lines + 1] = "KNOWLEDGE: " .. KWR.Util:Text(command.knowledgeReason, "", 110)
    end
    return table.concat(lines, "\n")
end

function CommandView:CallerText(command, context, actionLimit)
    command = command or {}
    local fallbackState = {
        snapshot = {
            context = context or {},
        },
    }
    return "WHO: " .. self:CallMovers(command)
        .. "\n|cffb7bdc7" .. self:TriggerLine(command, fallbackState,
            "TRIGGER: " .. tostring(command.when or "NOW")) .. "|r"
        .. "\nACTION: " .. KWR.Util:Text(command.action, "", actionLimit or 180)
end

function CommandView:TaglineText(state, fallback, limit)
    state = state or {}
    local context = state.snapshot and state.snapshot.context or {}
    local command = state.command or {}
    if context.preview then
        return "Preview only. KWR is showing synthetic battleground data."
    end
    if context.inPvP then
        return KWR.Util:Text(command.action, fallback or "Hold current lane.", limit or 132)
            .. "  |  " .. tostring(command.when or "NOW")
    end
    return KWR.Util:Text(command.action
        or "Build the command unit for battleground launch.", "", limit or 140)
end

function CommandView:CompactCommandText(state)
    local mapKey = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.mapKey
    local lines = self:PrimaryLines(state, "PLAY OBJECTIVE")
    return self:CompactMapText(mapKey, table.concat(lines, " | "))
end

local function tightNextText(mapKey, value)
    local text = KWR.Util:Text(value, "", 220)
    if text == "" then return "" end
    text = KWR.Maps:AbbreviateText(mapKey, text)
    text = text:gsub("^Abort if%s+", "")
    text = text:gsub("^abort if%s+", "")
    text = text:gsub("^If%s+", "")
    text = text:gsub("required objectives remain controlled through the next scoring window",
        "keep control through next tick")
    text = text:gsub("Required objectives remain controlled through the next scoring window",
        "Keep control through next tick")
    text = text:gsub("the enemy reserve remains free", "enemy reserve stays free")
    text = text:gsub("The enemy reserve remains free", "Enemy reserve stays free")
    text = text:gsub("the winning anchor calls instability", "the anchor breaks")
    text = text:gsub("The winning anchor calls instability", "The anchor breaks")
    text = text:gsub("through the next scoring window", "through next tick")
    text = text:gsub("next scoring window", "next tick")
    text = text:gsub("%.$", "")
    return KWR.Util:TextClip(text, "", 48)
end

function CommandView:NextMoveText(state, fallback)
    state = state or {}
    local command = state.command or {}
    local objectiveDecision = command.objectiveDecision or {}
    local mapKey = state.snapshot and state.snapshot.context and state.snapshot.context.mapKey
    local lines = {}
    local pivotText = tightNextText(mapKey, command.switchIf)
    local successText = tightNextText(mapKey, objectiveDecision.success)
    local abortText = tightNextText(mapKey, objectiveDecision.abort)
    if command.switchIf and command.switchIf ~= "" then
        lines[#lines + 1] = "PIVOT: " .. pivotText
    end
    if objectiveDecision.success and objectiveDecision.success ~= "" and successText ~= pivotText then
        lines[#lines + 1] = "WIN IF: " .. successText
    end
    if #lines == 0 and objectiveDecision.abort and objectiveDecision.abort ~= "" then
        lines[#lines + 1] = "STOP IF: " .. abortText
    elseif objectiveDecision.abort and objectiveDecision.abort ~= ""
        and abortText ~= pivotText and abortText ~= successText then
        lines[#lines + 1] = "STOP IF: " .. abortText
    end
    if #lines == 0 then
        lines[1] = fallback or "Hold current assignment. Check again on the next fight."
    elseif #lines > 2 then
        lines = { lines[1], lines[2] }
    end
    return table.concat(lines, "\n")
end
