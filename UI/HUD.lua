local _, KWR = ...

local HUD = {}
KWR.HUD = HUD

local HUD_WIDTH = 432
local HUD_HEIGHT = 548
local HUD_EXECUTION_HEIGHT = 500
local HUD_FOCUS_HEIGHT = 292
local HEADER_INSET = 12
local SECTION_LEFT = 8
local SECTION_RIGHT = -8

local function currentState(fallback)
    if fallback then
        return fallback
    end
    if KWR.Store and type(KWR.Store.Get) == "function" then
        return KWR.Store:Get()
    end
    return nil
end

local function addSection(frame, key, title, y, height)
    local section = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    section:SetPoint("TOPLEFT", SECTION_LEFT, y)
    section:SetPoint("TOPRIGHT", SECTION_RIGHT, y)
    section:SetHeight(height)
    KWR.Theme:Style(section, "panel", "border")
    section.heading = KWR.Theme:Font(section, 8, "gold", "LEFT", "OUTLINE")
    section.heading:SetPoint("TOPLEFT", 8, -5)
    section.heading:SetText(title)
    section.value = KWR.Theme:Font(section, 10, "white", "LEFT")
    section.value:SetPoint("TOPLEFT", 8, -20)
    section.value:SetPoint("BOTTOMRIGHT", -8, 5)
    section.value:SetJustifyV("TOP")
    frame[key] = section
end

local function placeSection(section, y, height)
    section:ClearAllPoints()
    section:SetPoint("TOPLEFT", SECTION_LEFT, y)
    section:SetPoint("TOPRIGHT", SECTION_RIGHT, y)
    section:SetHeight(height)
end

local function compactList(text, maxItems, itemLimit)
    local source = KWR.Util:Text(text, "", 240)
    if source == "" then return "" end
    local items = {}
    for token in source:gmatch("([^,;]+)") do
        local clean = token:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then items[#items + 1] = clean end
    end
    if #items == 0 then
        return KWR.Util:Text(source, "", itemLimit or 64)
    end
    local visible = {}
    local limit = math.min(#items, maxItems or #items)
    for index = 1, limit do
        visible[#visible + 1] = KWR.Util:Text(items[index], "", itemLimit or 28)
    end
    if #items > limit then
        for index = limit + 1, #items do
            visible[#visible + 1] = KWR.Util:Text(items[index], "", itemLimit or 28)
        end
    end
    return table.concat(visible, ", ")
end

local function splitRosterNames(source)
    local items = {}
    if type(source) == "table" then
        for _, value in ipairs(source) do
            local clean = KWR.Util:Text(value, "", 64)
            if clean ~= "" and not clean:match("^%+%d+$") then
                items[#items + 1] = clean
            end
        end
        return items
    end
    local text = KWR.Util:Text(source, "", 480)
    for token in text:gmatch("([^,;]+)") do
        local clean = token:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" and not clean:match("^%+%d+$") then
            items[#items + 1] = clean
        end
    end
    return items
end

local function stackedNames(label, source, fallback, maxChars)
    local items = splitRosterNames(source)
    if #items == 0 then
        return label .. " " .. KWR.Util:TextClip(fallback or "TEAM", "TEAM", maxChars or 56)
    end
    local lines = {}
    local firstPrefix = label .. " "
    local nextPrefix = string.rep(" ", #label + 1)
    local current = firstPrefix .. items[1]
    for index = 2, #items do
        local candidate = current .. ", " .. items[index]
        if #candidate <= (maxChars or 56) then
            current = candidate
        else
            lines[#lines + 1] = current
            current = nextPrefix .. items[index]
        end
    end
    lines[#lines + 1] = current
    return table.concat(lines, "\n")
end

local function stackedValue(label, value, fallback, maxChars)
    local text = KWR.Util:TextClip(value, fallback or "", 160)
    if text == "" then
        text = fallback or ""
    end
    local parts = {}
    for token in tostring(text):gmatch("([^,;]+)") do
        local clean = token:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then
            parts[#parts + 1] = clean
        end
    end
    if #parts <= 1 then
        return label .. " " .. KWR.Util:TextClip(text, fallback or "", maxChars or 56)
    end
    return stackedNames(label, parts, fallback, maxChars)
end

local function localFightText(localFight, mapKey)
    localFight = localFight or {}
    local lines = {}
    local kill = localFight.kill
    if kill and KWR.Util:Text(kill.target, "", 64) ~= "" then
        local details = { KWR.Util:TextClip(kill.target, "Enemy", 24) }
        local health = KWR.Util:Number(kill.healthPercent, nil)
        if health then
            details[#details + 1] = tostring(math.floor(health + 0.5)) .. "%"
        end
        local location = KWR.Util:TextClip(kill.location, "", 48)
        if location ~= "" then
            details[#details + 1] = "@ "
                .. KWR.Maps:AbbreviateLocation(mapKey, location)
        end
        local mode = kill.mode == "PRESSURE" and "PRESS" or "KILL"
        local tone = kill.mode == "PRESSURE" and "STOP" or "KILL"
        lines[#lines + 1] = KWR.Theme:CombatText(tone, mode .. ":")
            .. " " .. table.concat(details, " | ")
    else
        lines[#lines + 1] = KWR.Theme:CombatText("STALE", "KILL:")
            .. " HOLD"
    end

    local controls = localFight.controls or {}
    for index = 1, math.min(#controls, 3) do
        local control = controls[index]
        local actor = control.assigned == true
            and KWR.Util:TextClip(control.actor, "UNASSIGNED", 20) or "UNASSIGNED"
        local target = KWR.Util:TextClip(control.target, "LOCAL HEALER", 20)
        local prefix = index == 1 and "CC:" or ("CC" .. tostring(index) .. ":")
        lines[#lines + 1] = KWR.Theme:CombatText("STOP", prefix)
            .. " " .. actor .. " -> " .. target
    end
    if #controls == 0 then
        lines[#lines + 1] = KWR.Theme:CombatText("STALE", "CC:")
            .. " NONE"
    end
    return table.concat(lines, "\n")
end

local function focusFightText(localFight, mapKey)
    localFight = localFight or {}
    local kill = localFight.kill
    if kill and KWR.Util:Text(kill.target, "", 64) ~= "" then
        local details = { KWR.Util:TextClip(kill.target, "Enemy", 24) }
        local health = KWR.Util:Number(kill.healthPercent, nil)
        if health then details[#details + 1] = tostring(math.floor(health + 0.5)) .. "%" end
        local location = KWR.Util:TextClip(kill.location, "", 48)
        if location ~= "" then
            details[#details + 1] = "@ " .. KWR.Maps:AbbreviateLocation(mapKey, location)
        end
        local mode = kill.mode == "PRESSURE" and "PRESS" or "KILL"
        local tone = kill.mode == "PRESSURE" and "STOP" or "KILL"
        return KWR.Theme:CombatText(tone, mode .. ":") .. " " .. table.concat(details, " | ")
    end
    for _, control in ipairs(localFight.controls or {}) do
        if control.assigned == true then
            local actor = KWR.Util:CanonicalShortName(control.actor)
            local player = KWR.Util:CanonicalShortName(KWR.Util:UnitName("player"))
            if actor ~= "" and actor == player then
                return KWR.Theme:CombatText("STOP", "PEEL:") .. " "
                    .. KWR.Util:TextClip(control.target, "LOCAL TARGET", 24)
            end
        end
    end
    return nil
end

local function callTone(call)
    local what = KWR.Util:Upper(call and call.what, "", 24)
    if what == "HOLD" or what == "RESET" then return "RECOVERY" end
    if what == "STOP" or what == "CC" then return "STOP" end
    if what == "KILL" then return "KILL" end
    return "MOVE"
end

local function fightCallText(call)
    call = call or {}
    local tone = callTone(call)
    return table.concat({
        KWR.Theme:CombatText(tone, "CALL:") .. " "
            .. KWR.Util:Upper(call.what, "HOLD", 24),
        KWR.Theme:CombatText("TARGET", stackedNames("WHO:", call.who, "TEAM", 56)),
        KWR.Theme:CombatText("MOVE", "WHERE:") .. " "
            .. KWR.Util:Upper(call.where, "FIELD", 24),
        KWR.Theme:CombatText("CARRY", "WHEN:") .. " "
            .. KWR.Util:Upper(call.when, "NOW", 24),
    }, "\n")
end

local function fightPostureText(model)
    return KWR.Theme:CombatText("TARGET",
            stackedValue("DEF:", model and model.defense, "ASSIGNED DEF", 56))
        .. "\n" .. KWR.Theme:CombatText("MOVE",
            stackedValue("OFF:", model and model.offense, "TEAM -> FIELD", 56))
end

local function applySetupLayout(frame)
    frame.rescan:ClearAllPoints()
    frame.rescan:SetPoint("TOPRIGHT", -138, -8)
    frame.refresh:Show()
    frame.reassess:Show()
    frame.alertBadge:Show()
    frame.truthBadge:Show()
    frame.alert:Show()
    placeSection(frame.win, -114, 52)
    placeSection(frame.next, -172, 124)
    placeSection(frame.mine, -302, 52)
    placeSection(frame.caller, -360, 88)
    placeSection(frame.kill, -454, 72)
end

local function applyFightNowLayout(frame)
    frame.rescan:ClearAllPoints()
    frame.rescan:SetPoint("TOPRIGHT", -10, -8)
    frame.refresh:Hide()
    frame.reassess:Hide()
    frame.alertBadge:Hide()
    frame.truthBadge:Hide()
    frame.alert:Hide()
    placeSection(frame.win, -88, 46)
    placeSection(frame.next, -138, 100)
    placeSection(frame.mine, -242, 100)
    placeSection(frame.caller, -346, 68)
    placeSection(frame.kill, -418, 72)
end

local function applyFocusLayout(frame)
    frame.rescan:ClearAllPoints()
    frame.rescan:SetPoint("TOPRIGHT", -10, -8)
    frame.refresh:Hide()
    frame.reassess:Hide()
    frame.alertBadge:Hide()
    frame.truthBadge:Hide()
    frame.alert:Hide()
    placeSection(frame.next, -88, 104)
    placeSection(frame.kill, -198, 72)
end

local function commandCoverage(state)
    return KWR.Assignments:CommandGroups(
        state.assignments, state.snapshot.context.mapKey).text
end

local function commandObjective(state)
    local snapshot = state.snapshot or {}
    local command = state.command or {}
    local response = snapshot.responsePackage or {}
    local mapKey = snapshot.context and snapshot.context.mapKey
    local primary = command.action or "Queue or join your team."
    local lines = {
        KWR.CommandView:CompactMapText(mapKey, primary, "Queue or join your team.", 92),
    }
    local movers = (response.moverText and response.moverText ~= ""
            and response.moverText ~= "Team" and response.moverText)
        or (KWR.CommandView:CallMovers(command) ~= "Team"
            and KWR.CommandView:CallMovers(command))
        or (command.who and command.who ~= "" and command.who ~= "Team" and command.who)
    if movers then
        lines[#lines + 1] = KWR.CommandView:CallVerb(command, snapshot.context)
            .. ": " .. compactList(movers, 4, 16)
    end
    if response.qualified == true and response.stayerText and response.stayerText ~= ""
        and response.stayerText ~= "Assigned defenders" then
        lines[#lines + 1] = "HOLD: "
            .. KWR.CommandView:CompactMapText(mapKey, response.stayerText, "", 74)
    elseif command.switchIf and command.switchIf ~= "" then
        lines[#lines + 1] = "SWITCH: "
            .. KWR.CommandView:CompactMapText(mapKey, command.switchIf, "", 74)
    else
        lines[#lines + 1] = "WHEN: " .. tostring(command.when or "NOW")
    end
    return table.concat(lines, "\n")
end

local function alertState(state)
    local snapshot = state.snapshot or {}
    local command = state.command or {}
    local prediction = state.prediction or {}
    local response = snapshot.responsePackage or {}
    local formation = snapshot.formation or {}
    if not snapshot.context or snapshot.context.inPvP ~= true then
        if formation.complete then
            return "SETUP", "Roster ready. Confirm leaders and queue.", "green"
        end
        return "SETUP", "Recruit " .. (formation.needText or "the open roles") .. ".", "gold"
    end
    local latestMessage = KWR.Util:Text(snapshot.lastMessage, "", 96)
    if latestMessage ~= "" then
        return "SWING", latestMessage, "gold"
    end
    if command.reassessment then
        return "PIVOT", "New read changed the call.", "orange"
    end
    if (prediction.urgency or 0) >= 85 then
        return "URGENT", "High urgency: the next score swing can decide the game.", "red"
    end
    if response.qualified == false then
        return "HOLD", KWR.Util:Text(response.action,
            "Hold for one more read.", 96), "yellow"
    end
    return "SET", "Current call is set. Recheck on the next swing.", "muted"
end

local function showStatusTooltip(owner, title, lines)
    if not GameTooltip or not GameTooltip.SetOwner then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, 1, 0.84, 0.24)
    for _, line in ipairs(lines or {}) do
        GameTooltip:AddLine(line, 0.78, 0.80, 0.84, true)
    end
    GameTooltip:Show()
end

local function hideStatusTooltip()
    if GameTooltip and GameTooltip.Hide then
        GameTooltip:Hide()
    end
end

local function alertTooltipLines(tag)
    if tag == "SETUP" then
        return {
            "The compact center is showing RBG roster-building information.",
            "Open the Command Center for the full composition and recruiting plan.",
        }
    end
    if tag == "SWING" then
        return {
            "A fresh event changed the fight lane.",
            "Read the live call before moving the team.",
        }
    end
    if tag == "PIVOT" then
        return {
            "KWR changed the plan because the read changed.",
            "Use the live call and move on timing.",
        }
    end
    if tag == "URGENT" then
        return {
            "The next fight or score swing is likely decisive.",
            "Treat the current call as time-sensitive.",
        }
    end
    if tag == "HOLD" then
        return {
            "The team is not cleared for a full send yet.",
            "Hold until the next clean read confirms the path.",
        }
    end
    return {
        "The current call is set.",
        "Recheck when the fight, score, or map state swings.",
    }
end

local function truthTooltipLines(tag)
    if tag == "PREVIEW" then
        return {
            "The HUD is showing design preview data only.",
            "Nothing in this view is live battleground data.",
        }
    end
    if tag == "LIVE" then
        return {
            "Live battleground score or objective widgets are confirmed.",
            "This is the strongest live data state for the fight card.",
        }
    end
    if tag == "PARTIAL" then
        return {
            "Some battleground data is present, but not every live source is confirmed yet.",
            "Use Refresh if the call still feels incomplete.",
        }
    end
    return {
        "You are outside a live battleground.",
        "The HUD is in setup mode and only showing formation or queue-building information.",
    }
end

local function teamfightAssignment(plan)
    local playerName = KWR.Util:UnitName("player")
    local shortName = playerName and KWR.Util:ShortName(playerName)
    for _, assignment in ipairs(plan and plan.assignments or {}) do
        if assignment.name == playerName or assignment.shortName == shortName
            or assignment.actor == playerName or assignment.actor == shortName then
            return assignment
        end
    end
    return nil
end

local function executionAssignment(snapshot)
    local packet = snapshot and snapshot.executionCommand
    if not packet or not KWR.ExecutionCommandBuilder then return nil end
    local playerName = KWR.Util:UnitName("player")
    local playerGUID = type(UnitGUID) == "function"
        and KWR.Util:Text(KWR.Util:Call(UnitGUID, "player"), "", 96) or nil
    return KWR.ExecutionCommandBuilder:PersonalFor(packet, playerName, playerGUID)
end

local TRANSITION_REFRESH_DELAYS = { 0.15, 0.75, 2.00 }
local MATCH_COMPLETE_REFRESH_DELAYS = { 0.20, 0.90, 2.40 }
local COMBAT_RELEASE_REFRESH_DELAYS = { 0.10 }

function HUD:RequestAuthoritativeRefresh(reason, settleDelay)
    if not KWR.MatchRuntime or type(KWR.MatchRuntime.Queue) ~= "function" then
        return
    end
    -- The compact HUD is a pure Store view. When it is restored or enabled,
    -- ask the single runtime owner for one coalesced refresh instead of
    -- reintroducing a surface-owned ticker.
    KWR.MatchRuntime:Queue(reason or "hud-sync", 0.02, settleDelay or 0.35)
end

function HUD:Create()
    if self.frame then return self.frame end
    local profile = KWR.db.profile.hud
    local frame = CreateFrame("Frame", "KWR_CommandHUD", UIParent, "BackdropTemplate")
    frame:SetSize(HUD_WIDTH, HUD_HEIGHT)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    KWR.Theme:MakeMovable(frame, profile)

    frame.dragHandle = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.dragHandle:SetPoint("TOPLEFT", 8, -6)
    frame.dragHandle:SetPoint("TOPRIGHT", -220, -6)
    frame.dragHandle:SetHeight(26)
    frame.dragHandle:EnableMouse(true)
    frame.dragHandle:RegisterForDrag("LeftButton")
    frame.dragHandle:SetScript("OnDragStart", function()
        if profile.locked or (InCombatLockdown and InCombatLockdown()) then return end
        frame:StartMoving()
    end)
    frame.dragHandle:SetScript("OnDragStop", function()
        -- A drag may end after combat starts; Retail protects frame movement then.
        if InCombatLockdown and InCombatLockdown() then return end
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint(1)
        profile.point, profile.relativePoint, profile.x, profile.y = point, relativePoint, x, y
    end)

    frame.brand = KWR.Theme:Title(frame, 14)
    frame.brand:SetPoint("TOPLEFT", HEADER_INSET, -9)
    frame.brand:SetText("KWR COMMAND CARD")
    frame.mode = KWR.Theme:Font(frame, 8, "muted", "LEFT", "OUTLINE")
    frame.mode:SetPoint("TOPLEFT", HEADER_INSET, -27)
    frame.mode:SetWidth(168)
    frame.rescan = KWR.Theme:Button(frame, "RESCAN", 58, 18, function()
        local state = currentState()
        if state and state.snapshot and state.snapshot.context
            and state.snapshot.context.inPvP then
            if KWR.CommandAudio then KWR.CommandAudio:Repeat() end
        else
            KWR.MatchRuntime:RescanRoster()
        end
    end)
    frame.rescan:SetPoint("TOPRIGHT", -138, -8)
    frame.refresh = KWR.Theme:Button(frame, "REFRESH", 58, 18, function()
        KWR.MatchRuntime:ForceRefresh("hud-refresh")
    end)
    frame.refresh:SetPoint("TOPRIGHT", -74, -8)
    frame.reassess = KWR.Theme:Button(frame, "PIVOT", 58, 18, function()
        KWR.MatchRuntime:Reassess()
    end)
    frame.reassess:SetPoint("TOPRIGHT", -10, -8)
    frame.score = KWR.Theme:Font(frame, 16, "white", "CENTER", "OUTLINE")
    frame.score:SetPoint("TOPLEFT", 8, -50)
    frame.score:SetPoint("TOPRIGHT", -8, -50)
    frame.score:SetHeight(24)
    frame.status = KWR.Theme:Font(frame, 8, "green", "CENTER")
    frame.status:SetPoint("TOPLEFT", 8, -74)
    frame.status:SetPoint("TOPRIGHT", -8, -74)
    frame.alertBadge = KWR.Theme:Badge(frame, "muted", "SET", 76, 16)
    frame.alertBadge:SetPoint("TOPLEFT", 10, -92)
    frame.alertBadge:EnableMouse(true)
    frame.alertBadge:SetScript("OnEnter", function(self)
        showStatusTooltip(self, "Call State", alertTooltipLines(self.currentTag))
    end)
    frame.alertBadge:SetScript("OnLeave", hideStatusTooltip)
    frame.truthBadge = KWR.Theme:Badge(frame, "muted", "NOT LIVE", 84, 16)
    frame.truthBadge:SetPoint("LEFT", frame.alertBadge, "RIGHT", 8, 0)
    frame.truthBadge:EnableMouse(true)
    frame.truthBadge:SetScript("OnEnter", function(self)
        showStatusTooltip(self, "Data State", truthTooltipLines(self.currentTag))
    end)
    frame.truthBadge:SetScript("OnLeave", hideStatusTooltip)
    frame.alert = KWR.Theme:Font(frame, 8, "muted", "CENTER")
    frame.alert:SetPoint("TOPLEFT", 174, -92)
    frame.alert:SetPoint("TOPRIGHT", -10, -92)
    frame.alert:SetHeight(16)

    addSection(frame, "win", "WIN PATH", -114, 52)
    addSection(frame, "next", "NOW", -172, 124)
    addSection(frame, "mine", "NEXT", -302, 52)
    addSection(frame, "caller", "POSTURE", -360, 88)
    addSection(frame, "kill", "KILL / CC", -454, 72)
    for _, key in ipairs({ "next", "mine", "caller", "kill" }) do
        local section = frame[key]
        if section and section.value and section.value.SetSpacing then
            section.value:SetSpacing(2)
        end
    end

    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then KWR.MainWindow:Show("TACTICAL") end
    end)
    self.frame = frame
    return frame
end

function HUD:Invalidate()
    self.lastRenderRevision = nil
    self.lastRenderSignature = nil
end

function HUD:QueueRefresh(delay)
    local token = (self.refreshToken or 0) + 1
    self.refreshToken = token
    local function run()
        if token ~= HUD.refreshToken then return end
        HUD:Update(currentState(HUD.lastState))
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 0.05, run)
    else
        run()
    end
end

function HUD:QueueRefreshBurst(delays)
    self.refreshBurstToken = (self.refreshBurstToken or 0) + 1
    local token = self.refreshBurstToken
    for _, delay in ipairs(delays or {}) do
        local function run()
            if token ~= HUD.refreshBurstToken then return end
            HUD:Update(currentState(HUD.lastState))
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(delay, run)
        else
            run()
        end
    end
end

local function truthBadgeState(snapshot)
    local context = snapshot and snapshot.context or {}
    local scoreSource = KWR.Util:Upper(snapshot and snapshot.score and snapshot.score.source, "NONE", 18)
    local objectiveSource = KWR.Util:Upper(snapshot and snapshot.objectives and snapshot.objectives.source, "NONE", 18)
    if context.preview == true then return "orange", "PREVIEW" end
    if context.inPvP ~= true then return "muted", "NOT LIVE" end
    if scoreSource:find("WIDGET", 1, true) or objectiveSource:find("WIDGET", 1, true)
        or objectiveSource:find("PUBLIC", 1, true) then
        return "green", "LIVE"
    end
    if scoreSource == "NONE" and objectiveSource == "NONE" then
        return "muted", "SETUP"
    end
    return "yellow", "PARTIAL"
end

local function updateToken(owner, state)
    local allowed = KWR.Util:AllowsCommandSurfaces(state)
    local arena = KWR.Util:IsArenaContext(state)
    if owner.suppressed == true or KWR.db.profile.hud.enabled ~= true then
        return KWR.Util:Signature({ allowed, arena, owner.suppressed, KWR.db.profile.hud.enabled })
    end
    local shown = owner.frame and owner.frame:IsShown() or false
    if not shown then
        return KWR.Util:Signature({ allowed, arena, shown, KWR.db.profile.hud.enabled })
    end
    local snapshot = state and state.snapshot or {}
    local command = state and state.command or {}
    local combat = snapshot.combat or {}
    local target = combat.localTarget or combat.killTarget or {}
    return KWR.Util:Signature({
        true,
        state and state.revision or 0,
        snapshot.context and snapshot.context.sessionKey,
        snapshot.context and snapshot.context.mapKey,
        snapshot.context and snapshot.context.inPvP,
        command.signature,
        command.status,
        state and state.prediction and state.prediction.status,
        state and state.prediction and state.prediction.urgency,
        target.key or target.name,
    })
end

function HUD:Update(state)
    self.lastState = state
    if not self.ready then return end
    if not state then
        if self.frame then self.frame:Hide() end
        return
    end
    if not KWR.Util:AllowsCommandSurfaces(state) or KWR.Util:IsArenaContext(state) then
        if self.frame then self.frame:Hide() end
        return
    end
    if self.suppressed then
        if self.frame then self.frame:Hide() end
        return
    end
    if KWR.db.profile.hud.enabled ~= true then
        if self.frame then self.frame:Hide() end
        return
    end
    local frame = self:Create()
    local snapshot, command = state.snapshot, state.command
    local formationMode = snapshot.context.inPvP ~= true
    local matchComplete = snapshot.context.matchComplete == true
    local focusMode = not formationMode
        and not matchComplete
        and KWR.db.profile.hud.focusMode == true
    local formation = snapshot.formation or {}
    local sessionKey = KWR.Util:Text(snapshot and snapshot.context
        and snapshot.context.sessionKey,
        snapshot and snapshot.context
            and KWR.Util:BattlefieldSessionKey(snapshot.context), 96)
    if sessionKey ~= self.lastSessionKey then
        self.lastSessionKey = sessionKey
        self:Invalidate()
    end
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local short = definition and definition.short or "WORLD"
    local teamfight = snapshot.teamfight
    local execution = snapshot.executionCommand or {}
    local localFight = execution.localFight or {}
    local localFightCall = not matchComplete
        and localFightText(localFight, snapshot.context.mapKey) or nil
    local focusFightCall = not matchComplete
        and focusFightText(localFight, snapshot.context.mapKey) or nil
    local fightNow = KWR.CommandView:FightNow(state)
    local synchronizedMine = executionAssignment(snapshot)
    local mine
    for _, assignment in ipairs(state.assignments or {}) do
        if assignment.name == KWR.Util:UnitName("player")
            or assignment.shortName == KWR.Util:ShortName(KWR.Util:UnitName("player")) then
            mine = assignment
            break
        end
    end
    if synchronizedMine then
        mine = synchronizedMine
    elseif teamfight and teamfight.displayEligible == true then
        mine = mine or teamfightAssignment(teamfight)
    end
    local personalAction = synchronizedMine and synchronizedMine.display
        or (mine and KWR.Assignments:CompactLabel(
            mine, snapshot.context.mapKey) or nil)
    local enemy = snapshot.combat and (snapshot.combat.localTarget
        or snapshot.combat.killTarget)
        or (snapshot.enemies and snapshot.enemies[1])
    if teamfight and teamfight.displayEligible == true then
        local targetGUID = teamfight.killTarget and teamfight.killTarget.targetGUID
            or (teamfight.assignments and teamfight.assignments[1]
                and teamfight.assignments[1].targetGUID)
        local targetName = teamfight.killTarget and teamfight.killTarget.target
            or (teamfight.assignments and teamfight.assignments[1]
                and teamfight.assignments[1].target)
        for _, candidate in ipairs(snapshot.enemies or {}) do
            if (targetGUID and candidate.guid == targetGUID)
                or (targetName and KWR.Util:ShortName(candidate.name) == targetName) then
                enemy = candidate
                break
            end
        end
    end
    local localReason = snapshot.combat
        and (snapshot.combat.localTargetReason or snapshot.combat.killReason)
    local response = snapshot.responsePackage or {}
    local coverage = commandCoverage(state)
    local objectiveText = commandObjective(state)
    local pivotText = teamfight and teamfight.displayEligible == true
        and KWR.Util:Text(teamfight.summary, "Collapse now.", 120)
        or KWR.CommandView:NextMoveText(state,
            "Hold your lane until the next swing.")
    local line1, line2, line3 = KWR.CommandView:SummaryLines(state)
    local primaryLines = KWR.CommandView:PrimaryLines(state,
        "Hold current assignment.")
    local spokenCall = KWR.CommandView:SpokenCall(command, snapshot.context)
    local callMovers = KWR.CommandView:CallMovers(command)
    local revision = KWR.Util:Number(state.revision, 0) or 0
    local renderSignature = KWR.Util:Signature({
        revision,
        sessionKey,
        snapshot.context and snapshot.context.inPvP,
        focusMode,
        snapshot.context and snapshot.context.mapName,
        snapshot.context and snapshot.context.isBlitz,
        snapshot.context and snapshot.context.matchComplete,
        snapshot.context and snapshot.context.team and snapshot.context.team.faction,
        command and command.signature,
        execution.signature,
        localFightCall,
        command and command.status,
        command and command.action,
        spokenCall,
        line1,
        line2,
        line3,
        callMovers,
        command and command.when,
        command and command.switchIf,
        command and command.reassessment and true or false,
        objectiveText,
        coverage,
        pivotText,
        response.moverText,
        response.stayerText,
        response.qualified,
        response.score,
        state.prediction and state.prediction.condition,
        state.prediction and state.prediction.status,
        state.prediction and state.prediction.urgency,
        snapshot.score and snapshot.score.friendly,
        snapshot.score and snapshot.score.enemy,
        snapshot.score and snapshot.score.source,
        snapshot.objectives and snapshot.objectives.source,
        snapshot.lastMessage,
        mine and mine.role,
        mine and (mine.location or mine.window),
        synchronizedMine and synchronizedMine.display,
        enemy and enemy.key,
        enemy and enemy.age and math.floor(enemy.age),
        enemy and enemy.location,
        fightNow.score,
        fightNow.projection,
        fightNow.winPath,
        fightNow.nextObjective,
        fightNow.current and fightNow.current.what,
        fightNow.current and fightNow.current.who,
        fightNow.current and fightNow.current.where,
        fightNow.current and fightNow.current.when,
        fightNow.next and fightNow.next.what,
        fightNow.next and fightNow.next.who,
        fightNow.next and fightNow.next.where,
        fightNow.next and fightNow.next.when,
        fightNow.defense,
        fightNow.offense,
    })
    if self.lastRenderSignature == renderSignature and frame:IsShown() then
        self.renderSkips = (self.renderSkips or 0) + 1
        return
    end
    self.renderUpdates = (self.renderUpdates or 0) + 1
    self.lastRenderRevision = revision
    self.lastRenderSignature = renderSignature
    frame.brand:SetText(snapshot.context.inPvP and "KWR FIGHT NOW" or "KWR SETUP CENTER")
    frame.rescan:SetText(snapshot.context.inPvP and "REPEAT" or "RESCAN")
    frame.mode:SetText(snapshot.context.preview and "DESIGN PREVIEW"
        or (snapshot.context.inPvP and "LIVE BATTLEGROUND" or "QUEUE / SETUP"))
    if formationMode then
        applySetupLayout(frame)
        frame.score:SetText("RBG SETUP")
        frame.status:SetText(string.format("FORMING  |  %d OPEN", formation.openSlots or 0))
        frame.status:SetTextColor(KWR.Theme:Color(KWR.CommandView:StatusColor(command.status)))
    elseif matchComplete then
        applyFightNowLayout(frame)
        frame.score:SetText(KWR.Theme:CombatText("MOVE", fightNow.score)
            .. "  |  " .. KWR.Theme:CombatText(
                fightNow.projectionTone, fightNow.projection))
        frame.status:SetText("")
    elseif focusMode then
        applyFocusLayout(frame)
        frame.score:SetText(KWR.Theme:CombatText("MOVE", fightNow.score)
            .. "  |  " .. KWR.Theme:CombatText(fightNow.projectionTone, fightNow.projection))
        frame.status:SetText("")
    else
        applyFightNowLayout(frame)
        frame.score:SetText(KWR.Theme:CombatText("MOVE", fightNow.score)
            .. "  |  " .. KWR.Theme:CombatText(
                fightNow.projectionTone, fightNow.projection))
        frame.status:SetText("")
    end
    local alertTag, alert, alertColor = alertState(state)
    local truthTone, truthTag = truthBadgeState(snapshot)
    frame.alertBadge:SetTone(alertColor)
    frame.alertBadge:SetText(alertTag)
    frame.alertBadge.currentTag = alertTag
    frame.truthBadge:SetTone(truthTone)
    frame.truthBadge:SetText(truthTag)
    frame.truthBadge.currentTag = truthTag
    frame.alert:SetText(KWR.CommandView:CompactMapText(snapshot.context.mapKey, alert, "", 64))
    frame.alert:SetTextColor(KWR.Theme:Color(alertColor))
    frame.win.heading:SetText(formationMode and "SETUP GOAL"
        or (matchComplete and "RESULT" or "WIN PATH"))
    frame.win.value:SetText(matchComplete
        and KWR.Util:Text(command.action,
            "Match complete. Open Review / AAR.", 180)
        or (formationMode
        and (formation.complete
            and "Roster complete. Confirm leaders and queue readiness."
            or "Build to 10 players, assign leaders, then queue.")
        or (KWR.Theme:CombatText("CARRY", "TO WIN:")
            .. " " .. fightNow.winPath
            .. "\n" .. KWR.Theme:CombatText("MOVE", "NEXT:")
            .. " " .. fightNow.nextObjective)))
    local learning = KWR.db.profile.guidanceMode == "LEARNING"
    if formationMode then
        local currentComp = formation.currentComp or formation.archetype or {}
        local buildTarget = formation.buildTarget
        local currentName = ((currentComp.tier and (currentComp.tier .. " ") or "")
            .. (currentComp.name or "Current shell"))
        local targetName = buildTarget and (((buildTarget.tier and (buildTarget.tier .. " ") or "")
            .. (buildTarget.name or "Recommended target"))) or nil
        local nextRecruit = formation.recommendations and formation.recommendations[1]
        frame.next.heading:SetText("RECRUITING PLAN")
        frame.next.value:SetText(table.concat({
            "CURRENT: " .. currentName,
            targetName and targetName ~= currentName and ("TARGET: " .. targetName)
                or "TARGET: Work the current shell",
            "NEED: " .. (formation.needText or "Roster complete"),
            nextRecruit and ("NEXT: " .. nextRecruit.label .. " (" .. nextRecruit.role .. ")")
                or "NEXT: Confirm roster readiness",
        }, "\n"))
    elseif matchComplete then
        frame.next.heading:SetText("REVIEW / AAR")
        frame.next.value:SetText(KWR.Util:Text(
            command.action, "Open Review / AAR and capture the lesson.", 180))
    elseif focusMode then
        frame.next.heading:SetText(personalAction and "MY NEXT ACTION" or "TEAM CALL")
        frame.next.value:SetText(personalAction or fightCallText(fightNow.current))
    else
        frame.next.heading:SetText("NOW")
        frame.next.value:SetText(fightCallText(fightNow.current))
    end

    if formationMode then
        frame.mine.heading:SetText("MY ASSIGNMENT")
        frame.mine.value:SetText(synchronizedMine
            and synchronizedMine.display
            or (mine and KWR.Assignments:CompactLabel(
                mine, snapshot.context.mapKey) or "Assignment pending."))
        frame.caller.heading:SetText("QUEUE CHECK")
        frame.caller.value:SetText(
            "Target caller + backup\nBase / route lead\nVoice / talents / gear\nQueue leader")
    elseif matchComplete then
        frame.mine.heading:SetText("NEXT STEP")
        frame.mine.value:SetText("Capture the result, key swing, and adjustment before the next queue.")
        frame.caller.heading:SetText("POST MATCH")
        frame.caller.value:SetText("Open Review / AAR\nSave evidence\nRecord the lesson")
    elseif focusMode then
        frame.kill.heading:SetText("LOCAL ACTION")
        frame.kill.value:SetText(focusFightCall or "")
    else
        frame.mine.heading:SetText("NEXT")
        frame.mine.value:SetText(fightCallText(fightNow.next))
        frame.caller.heading:SetText("POSTURE")
        frame.caller.value:SetText(fightPostureText(fightNow))
    end

    frame.kill.heading:SetText(formationMode and "NEXT STEP"
        or (matchComplete and "MATCH COMPLETE"
        or (focusMode and "LOCAL ACTION" or "KILL / CC")))
    if formationMode then
        frame.kill.value:SetText(formation.complete
            and "Confirm setup, then queue for an RBG."
            or ("Recruit " .. (formation.needText or "the open roles")
                .. ".\n|cff8ea3bbOpen Command Center for the full setup plan.|r"))
    elseif matchComplete then
        frame.kill.value:SetText("Tactical calls closed. Capture the AAR before the next queue.")
    elseif focusMode then
        frame:SetHeight(HUD_FOCUS_HEIGHT)
        frame.win:Hide()
        frame.mine:Hide()
        frame.caller:Hide()
        frame.kill:SetShown(focusFightCall ~= nil)
    else
        frame.kill.value:SetText(localFightCall or "")
    end
    if formationMode then
        frame:SetHeight(HUD_HEIGHT)
        frame.win:Show()
        frame.mine:Show()
        frame.caller:Show()
        frame.kill:Show()
    elseif focusMode then
        frame:SetHeight(HUD_FOCUS_HEIGHT)
        frame.win:Hide()
        frame.mine:Hide()
        frame.caller:Hide()
        frame.kill:SetShown(focusFightCall ~= nil)
    else
        frame:SetHeight(HUD_EXECUTION_HEIGHT)
        frame.win:Show()
        frame.mine:Show()
        frame.caller:Show()
        frame.kill:Show()
    end
    frame:Show()
end

function HUD:SetSuppressed(suppressed)
    self.suppressed = suppressed == true
    if self.suppressed then
        if self.frame then self.frame:Hide() end
    else
        self:Invalidate()
        self:Update(currentState(self.lastState))
        self:RequestAuthoritativeRefresh("hud-restore", 0.50)
        self:QueueRefreshBurst(TRANSITION_REFRESH_DELAYS)
    end
end

function HUD:SetEnabled(enabled)
    KWR.db.profile.hud.enabled = enabled == true
    self.ready = true
    self:Invalidate()
    self:Update(currentState())
    if enabled == true then
        self:RequestAuthoritativeRefresh("hud-enable", 0.75)
        self:QueueRefreshBurst(TRANSITION_REFRESH_DELAYS)
    end
end

function HUD:Toggle()
    self:SetEnabled(not KWR.db.profile.hud.enabled)
end

function HUD:OnInitialize()
    self.eventFrame = CreateFrame("Frame", "KWR_HUDEvents")
    for _, event in ipairs({
        "PLAYER_ENTERING_WORLD",
        "ZONE_CHANGED_NEW_AREA",
        "UPDATE_BATTLEFIELD_STATUS",
        "PVP_MATCH_COMPLETE",
        "PLAYER_REGEN_ENABLED",
    }) do
        self.eventFrame:RegisterEvent(event)
    end
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PVP_MATCH_COMPLETE" then
            HUD:QueueRefreshBurst(MATCH_COMPLETE_REFRESH_DELAYS)
        elseif event == "PLAYER_REGEN_ENABLED" then
            HUD:QueueRefreshBurst(COMBAT_RELEASE_REFRESH_DELAYS)
        else
            HUD:QueueRefreshBurst(TRANSITION_REFRESH_DELAYS)
        end
    end)
    if KWR.Store and KWR.Store.SubscribeFiltered then
        KWR.Store:SubscribeFiltered(self, self.Update, updateToken)
    end
end

function HUD:OnEnable()
    HUD.ready = true
    HUD:Invalidate()
    HUD:Update(currentState(HUD.lastState))
    HUD:RequestAuthoritativeRefresh("hud-login", 0.75)
    HUD:QueueRefreshBurst(TRANSITION_REFRESH_DELAYS)
end

function HUD:OnDisable()
    self:Invalidate()
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
end

KWR:RegisterModule("HUD", HUD)
