local _, KWR = ...

local MainWindowPages = {}
KWR.MainWindowPages = MainWindowPages

local function aarSessionShort(entry)
    local value = KWR.Util:Text(entry and entry.feedback and entry.feedback.sessionType, "", 24)
    if value == "Commander" then return "CMD" end
    if value == "Spectator" then return "SPEC" end
    if value == "Diagnostic" then return "DIAG" end
    return ""
end

local function aarSessionLabel(entry)
    local value = KWR.Util:Text(entry and entry.feedback and entry.feedback.sessionType, "", 24)
    return value ~= "" and value or "Unlabeled"
end

local function beginRosterRowRender(row, signature)
    if row.renderSignature == signature then
        KWR.MainWindow.expandedRosterSkips =
            (KWR.MainWindow.expandedRosterSkips or 0) + 1
        return false
    end
    row.renderSignature = signature
    KWR.MainWindow.expandedRosterUpdates =
        (KWR.MainWindow.expandedRosterUpdates or 0) + 1
    return true
end

local function setShownChanged(frame, shown)
    shown = shown == true
    if frame:IsShown() ~= shown then
        frame:SetShown(shown)
    end
end

local function sortedRecords(records)
    local result = {}
    for _, row in pairs(records or {}) do
        result[#result + 1] = row
    end
    table.sort(result, function(a, b)
        local aName = KWR.Util:Text(a and (a.shortName or a.name), "Unknown", 64)
        local bName = KWR.Util:Text(b and (b.shortName or b.name), "Unknown", 64)
        return aName < bName
    end)
    return result
end

local function recentReviewEntry(state)
    if not KWR.AAR or not KWR.AAR.GetLatest then return nil end
    if state.snapshot.context and state.snapshot.context.inPvP then return nil end
    if state.command and state.command.status == "FORMING" then return nil end
    local latest = KWR.AAR:GetLatest()
    if type(latest) ~= "table" or latest.mapKey == "WORLD" then return nil end
    local endedAt = KWR.Util:Number(latest.endedAt, nil)
    if not endedAt then return nil end
    local now = type(time) == "function" and time() or math.floor(KWR.Util:Now())
    if now - endedAt > 600 then return nil end
    return latest
end

local function reviewAssignmentByName(entry)
    local result = {}
    for _, player in pairs(entry and entry.playerEvidence or {}) do
        local key = KWR.Util:Text(player.name, "", 64)
        if key ~= "" then
            result[key] = player
        end
    end
    return result
end

local function scrollRange(scroll)
    if not scroll or not scroll.GetVerticalScrollRange then return 0 end
    local ok, range = pcall(scroll.GetVerticalScrollRange, scroll)
    if not ok then return 0 end
    return math.max(0, tonumber(range) or 0)
end

local function clampScroll(scroll, value)
    if not scroll or not scroll.SetVerticalScroll then return end
    if scroll._kwrClamping then return end
    local current = value ~= nil and tonumber(value) or nil
    if current == nil and scroll.GetVerticalScroll then
        local scrollValue = scroll:GetVerticalScroll()
        current = scrollValue ~= nil and tonumber(scrollValue) or nil
    end
    local target = math.min(scrollRange(scroll), math.max(0, current or 0))
    local live = 0
    if scroll.GetVerticalScroll then
        live = tonumber(scroll:GetVerticalScroll()) or 0
    end
    if math.abs(live - target) < 0.5 then
        return
    end
    scroll._kwrClamping = true
    scroll:SetVerticalScroll(target)
    scroll._kwrClamping = false
end

function MainWindowPages:SetQuickCallsClosed(page, closed)
    local callsCard = page and page.callsCard
    if not callsCard then return false end
    closed = closed == true
    if InCombatLockdown and InCombatLockdown() then
        callsCard.pendingClosed = closed
        callsCard.pendingClosedQueued = true
        return false
    end
    for _, button in ipairs(callsCard.buttons or {}) do
        if closed then button:Disable() else button:Enable() end
    end
    callsCard.pendingClosed = closed
    callsCard.pendingClosedQueued = false
    return true
end

function MainWindowPages:FlushQuickCallState(page)
    local callsCard = page and page.callsCard
    if not callsCard or callsCard.pendingClosedQueued ~= true then return true end
    return self:SetQuickCallsClosed(page, callsCard.pendingClosed)
end

local function updateLogicCardBody(card, fallbackHeight)
    if not card or not card.scroll or not card.body or not card.value then return end
    local width = math.max((card.scroll:GetWidth() or 0) - 12, 248)
    card.value:SetWidth(width)
    local textHeight = card.value:GetStringHeight()
    if not textHeight or textHeight <= 0 then
        textHeight = fallbackHeight or 96
    else
        textHeight = textHeight + 8
    end
    card.value:SetHeight(math.max(textHeight, 1))
    local bodyHeight = math.max(card.scroll:GetHeight() or 0, card.value:GetHeight())
    card.body:SetSize(width, math.max(bodyHeight, 1))
    clampScroll(card.scroll)
end

local function formationCompLabel(comp, fallback)
    if type(comp) ~= "table" then
        return fallback or "Balanced Team Fight"
    end
    local tier = KWR.Util:Text(comp.tier, "", 16)
    local name = KWR.Util:Text(comp.name, fallback or "Balanced Team Fight", 96)
    local label = tier ~= "" and (tier .. " " .. name) or name
    if comp.metaStatus == "ADVISORY_PRE_LIVE" then
        label = label .. " [WATCH]"
    end
    return label
end

local function formationNeedSummary(formation)
    local needs = formation and formation.needs or {}
    local parts = {}
    if (needs.TANK or 0) > 0 then
        parts[#parts + 1] = tostring(needs.TANK) .. " TANK"
            .. ((needs.TANK or 0) == 1 and "" or "S")
    end
    if (needs.HEALER or 0) > 0 then
        parts[#parts + 1] = tostring(needs.HEALER) .. " HEALER"
            .. ((needs.HEALER or 0) == 1 and "" or "S")
    end
    if (needs.DAMAGER or 0) > 0 then
        parts[#parts + 1] = tostring(needs.DAMAGER) .. " DAMAGE"
    end
    if #parts == 0 then
        parts[1] = "ROSTER COMPLETE"
    end
    if (formation and formation.replacementsNeeded or 0) > 0 then
        parts[#parts + 1] = tostring(formation.replacementsNeeded) .. " REPLACEMENT"
            .. (formation.replacementsNeeded == 1 and "" or "S")
    end
    return table.concat(parts, " | ")
end

local function formationRecruitLine(recruit, index)
    if type(recruit) ~= "table" then return nil end
    local acquisition = tostring(recruit.acquisition or "OPEN SLOT")
    if acquisition == "OPEN SLOT" then
        acquisition = "OPEN"
    end
    return tostring(index) .. ". " .. tostring(recruit.label or "Unknown")
        .. "  [" .. tostring(recruit.role or "DAMAGER") .. " / " .. acquisition .. "]"
end

local function formationRequirementLines(formation)
    local grouped = { TANK = {}, HEALER = {}, DAMAGER = {} }
    for _, requirement in ipairs(formation and formation.buildRequirements or {}) do
        local role = grouped[requirement.role] and requirement.role or "DAMAGER"
        grouped[role][#grouped[role] + 1] = tostring(requirement.label or "Unknown")
    end
    local lines = {}
    if #grouped.TANK > 0 then
        lines[#lines + 1] = "TANK: " .. table.concat(grouped.TANK, " | ")
    end
    if #grouped.HEALER > 0 then
        lines[#lines + 1] = "HEALERS: " .. table.concat(grouped.HEALER, " | ")
    end
    if #grouped.DAMAGER > 0 then
        lines[#lines + 1] = "DAMAGE: " .. table.concat(grouped.DAMAGER, " | ")
    end
    return lines
end

local function formationBuildFitLines(formation)
    local recommendations = formation and formation.recommendations or {}
    local requirements = formation and formation.buildRequirements or {}
    local open, replacements = 0, 0
    for _, recruit in ipairs(recommendations) do
        if tostring(recruit.acquisition or "") == "OPEN SLOT" then
            open = open + 1
        else
            replacements = replacements + 1
        end
    end
    local targetSize = #requirements > 0 and #requirements
        or (formation and formation.targetSize or 10)
    local matched = math.max(0, targetSize - #recommendations)
    local needs = formation and formation.needs or {}
    return {
        "TARGET MATCH: " .. tostring(matched) .. " / " .. tostring(targetSize),
        "OPEN SLOTS: " .. tostring(open),
        "REPLACEMENTS: " .. tostring(replacements),
        "CORE NEED: " .. tostring(needs.TANK or 0) .. " T | "
            .. tostring(needs.HEALER or 0) .. " H | "
            .. tostring(needs.DAMAGER or 0) .. " D",
    }
end

local function formationTargetNeedSummary(formation)
    local recommendations = formation and formation.recommendations or {}
    if #(formation and formation.buildRequirements or {}) == 0 then
        return formationNeedSummary(formation)
    end
    if #recommendations == 0 then
        return "TARGET ROSTER COMPLETE"
    end
    local open, replacements = 0, 0
    for _, recruit in ipairs(recommendations) do
        if tostring(recruit.acquisition or "") == "OPEN SLOT" then
            open = open + 1
        else
            replacements = replacements + 1
        end
    end
    local parts = { tostring(#recommendations) .. " TARGET SPEC"
        .. (#recommendations == 1 and "" or "S") }
    if open > 0 then
        parts[#parts + 1] = tostring(open) .. " OPEN"
    end
    if replacements > 0 then
        parts[#parts + 1] = tostring(replacements) .. " REPLACEMENT"
            .. (replacements == 1 and "" or "S")
    end
    return table.concat(parts, " | ")
end

function MainWindowPages:RenderTactical(page, state, helpers)
    local snapshot, command, prediction = state.snapshot, state.command, state.prediction
    local teamfight = snapshot.teamfight
    local _, _, line3 = KWR.CommandView:SummaryLines(state)
    local primaryLines = KWR.CommandView:PrimaryLines(state, "Play objective")
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local short = definition and definition.short or "WORLD"
    local formation = snapshot.formation or {}
    local formationMode = not snapshot.context.inPvP
    page.eventsCard.heading:SetText(formationMode and "TARGET ROSTER" or "LAST EVENTS")
    page.nextCard.heading:SetText(formationMode and "ROSTER ACTION"
        or (snapshot.reassessment and "PIVOT" or "NEXT"))
    page.targetCard.heading:SetText(formationMode and "BUILD FIT" or "KILL / CC")
    page.winCard.heading:SetText(formationMode and "COMPOSITION PLAN" or "WIN PATH")
    page.callerCard.heading:SetText(formationMode and "LEADERSHIP SETUP" or "CALL TEAM")
    page.focusCard.heading:SetText(formationMode and "READY CHECK" or "NEXT")
    if not snapshot.context.inPvP then
        page.scoreCard.value:SetText(string.format("|cff4f8cffSETUP %d|r / %d",
            formation.players or 0, formation.targetSize or 10))
    else
        page.scoreCard.value:SetText(string.format("|cff4f8cff%s %d|r  -  |cffff3333%d|r",
            short, snapshot.score.friendly or 0, snapshot.score.enemy or 0))
    end
    page.scoreCard.status:SetText(KWR.CommandView:CommandStatusText(command))
    page.scoreCard.status:SetTextColor(KWR.Theme:Color(helpers.statusColor(command.status)))
    if formationMode then
        local nextRecruit = formation.recommendations and formation.recommendations[1]
        page.nextCard.value:SetText((formation.action or ("Recruit " .. (formation.needText or "Roster complete") .. "."))
            .. (nextRecruit and ("\nNEXT: " .. nextRecruit.label) or ""))
    else
        if teamfight and teamfight.displayEligible == true then
            local card = KWR.TeamfightCommandCard:Build(teamfight)
            page.nextCard.value:SetText(table.concat(card.lines or KWR.CommandView:CompactPrimaryLines(
                state, "Play objective"), "\n"))
        else
            page.nextCard.value:SetText(table.concat(
                KWR.CommandView:CompactPrimaryLines(state, "Play objective"), "\n"))
        end
    end
    local mine = helpers.selfAssignment(state)
    page.mineCard.value:SetText(mine and (mine.role .. "\n|cffb7bdc7" .. mine.location .. "|r")
        or "Setup assignment pending.")
    local enemy = helpers.primaryEnemy(state)
    local localReason = snapshot.combat
        and (snapshot.combat.localTargetReason or snapshot.combat.killReason)
    if not snapshot.context.inPvP then
        page.targetCard.value:SetText("|cffffd05a"
            .. table.concat(formationBuildFitLines(formation), "\n") .. "|r")
    elseif enemy then
        page.targetCard.value:SetText(enemy.shortName .. "  |  " .. enemy.spec .. "\n"
            .. KWR.EnemyIntel:DescribeLocation(enemy, snapshot.context.mapKey, true)
            .. "\n|cff8ea3bb" .. KWR.Util:Text(
                teamfight and teamfight.displayEligible == true
                    and teamfight.summary or localReason,
                enemy.age and ("Last seen " .. KWR.Util:Age(enemy.age) .. " ago")
                    or "Kill target from roster only.",
                120) .. "|r"
            .. (enemy.note and enemy.note ~= "" and ("\n|cffffd05a" .. enemy.note .. "|r") or ""))
    else
        page.targetCard.value:SetText("No kill target in sight.")
    end
    local eventLines = {}
    local objectiveEvents = snapshot.objectives and snapshot.objectives.events or {}
    for index = #objectiveEvents, math.max(1, #objectiveEvents - 5), -1 do
        eventLines[#eventLines + 1] = objectiveEvents[index].text
    end
    local current = KWR.AAR and KWR.AAR.active
    if #eventLines == 0 and current then
        for index = #current.events, math.max(1, #current.events - 5), -1 do
            eventLines[#eventLines + 1] = current.events[index].text
        end
    end
    if #eventLines == 0 and snapshot.lastMessage and snapshot.lastMessage ~= "" then
        eventLines[1] = snapshot.lastMessage
    end

    page.battlefieldCard.mapName:SetText(snapshot.context.mapName .. "  |  " .. command.status)
    local reporter = snapshot.reporter or {}
    page.battlefieldCard.heading:SetText(formationMode and "RBG SETUP BOARD"
        or "LIVE BATTLEFIELD VIEW")
    page.battlefieldCard.map:SetShown(not formationMode)
    page.battlefieldCard.legend:SetShown(not formationMode)
    page.battlefieldCard.formation:SetShown(formationMode)
    if formationMode then
        local tierMatch = formation.tierMatch and formation.tierMatch.qualified
            and formation.tierMatch or nil
        local currentComp = formation.currentComp
            or tierMatch
            or formation.archetype
        local buildTarget = formation.buildTarget
        local currentName = currentComp and currentComp.name or "Balanced Team Fight"
        local currentTier = currentComp and currentComp.tier or nil
        local targetName = buildTarget and buildTarget.name or currentName
        local targetTier = buildTarget and buildTarget.tier or nil
        local currentLabel = formationCompLabel(currentComp, "Balanced Team Fight")
        local targetLabel = formationCompLabel(buildTarget or currentComp, currentName)
        local targetSummary = buildTarget and (buildTarget.win or buildTarget.description)
            or (currentComp and (currentComp.win or currentComp.description))
            or "Build a complete command unit."
        local choiceLines = { "|cffffd05aRECOMMENDED BUILD TARGETS|r" }
        local choices = formation.availableComps or {}
        local selectedID = buildTarget and buildTarget.id or nil
        local selectedIndex = 1
        for index, comp in ipairs(choices) do
            if comp.id == selectedID then
                selectedIndex = index
                break
            end
        end
        local windowStart = math.max(1, math.min(selectedIndex - 2, math.max(1, #choices - 4)))
        local windowEnd = math.min(#choices, windowStart + 4)
        for index = windowStart, windowEnd do
            local comp = choices[index]
            local active = comp.id == selectedID
            choiceLines[#choiceLines + 1] = (active and "|cffffd05a> " or "  ")
                .. (comp.mapFit and "" or "|cff8ea3bb")
                .. tostring(comp.tier or "")
                .. " " .. tostring(comp.name or "")
                .. (comp.metaStatus == "ADVISORY_PRE_LIVE" and " |cff8ea3bbWATCH|r" or "")
                .. (active and "|r  |cff49dd49SELECTED|r"
                    or (comp.mapFit and "|r" or "|r  |cff8ea3bbOFF-MAP|r"))
        end
        choiceLines[#choiceLines + 1] = ""
        choiceLines[#choiceLines + 1] = "|cffffd05aRECRUIT PRIORITY|r"
        local recruitLines = {}
        for index, recruit in ipairs(formation.recommendations or {}) do
            recruitLines[#recruitLines + 1] = formationRecruitLine(recruit, index)
        end
        if #recruitLines == 0 then
            recruitLines[#recruitLines + 1] = "Roster roles are complete."
        end
        local positionLines = { "|cffffd05a" .. tostring(formation.positioningTitle
            or "POSITIONING KEYS") .. "|r" }
        for index, text in ipairs(formation.positioning or {}) do
            positionLines[#positionLines + 1] = tostring(index) .. ". " .. text
        end
        page.battlefieldCard.formation.title:SetText(targetLabel)
        page.battlefieldCard.formation.summary:SetText((formation.players or 0) .. " / "
            .. (formation.targetSize or 10) .. " PLAYERS\n"
            .. "NEED: " .. formationNeedSummary(formation) .. "\n"
            .. "CURRENT ROSTER: " .. currentLabel .. "\n"
            .. "TARGET BUILD: " .. targetLabel
            .. ((buildTarget and buildTarget.seasonNote) and ("\n|cff8ea3bb" .. buildTarget.seasonNote .. "|r") or "")
            .. "\n" .. targetSummary)
        page.battlefieldCard.formation.autoButton:SetSelected(formation.selectedCompID == nil)
        page.battlefieldCard.formation.recruits:SetText(table.concat(choiceLines, "\n")
            .. "\n" .. table.concat(recruitLines, "\n"))
        page.battlefieldCard.formation.positioning:SetText(table.concat(positionLines, "\n"))
    end
    page.battlefieldCard.reporterStatus:SetText(not snapshot.context.inPvP
        and KWR.Util:Text(formation.reason, "Build the command unit.", 110)
        or (reporter.summary or "Battlefield intelligence standing by."))
    page.battlefieldCard.reporterSummary:SetText(not snapshot.context.inPvP
        and (snapshot.context.preview and "PREVIEW  |  BATTLEFIELD INTELLIGENCE  |  SYNTHETIC DATA"
            or "RBG SETUP  |  PRESS SHIFT-M FOR THE BATTLEFIELD MAP")
        or helpers.reporterFooterText(reporter, snapshot.context.mapKey))
    page.battlefieldCard.reporterStatus:SetTextColor(KWR.Theme:Color((reporter.risk or 0) >= 70 and "red"
        or ((reporter.risk or 0) >= 45 and "yellow" or "gold")))
    if not formationMode then page.battlefieldCard.map:SetState(state) end
    local strategy = snapshot.strategy or {}
    local formationTier = formation.currentComp
        or (formation.tierMatch and formation.tierMatch.qualified and formation.tierMatch or nil)
    if formationMode then
        local formationName = formationCompLabel(formationTier or formation.archetype, "Balanced Team Fight")
        local targetName = formationCompLabel(formation.buildTarget or formationTier
            or formation.archetype, "Balanced Team Fight")
        page.winCard.value:SetText("NEED: " .. formationNeedSummary(formation)
            .. "\nCURRENT: " .. formationName
            .. "\nTARGET: " .. targetName)
    else
        page.winCard.value:SetText((teamfight and teamfight.displayEligible == true
                and KWR.Util:Text(teamfight.summary,
                    prediction.condition or "Waiting for live battleground data.", 220)
            or (prediction.condition or "Waiting for live battleground data."))
            .. "\n|cffffd05a" .. (command.action
                or strategy.action or prediction.action or "") .. "|r"
            .. (KWR.db.profile.guidanceMode == "LEARNING" and strategy.switchIf
                and ("\n|cff8ea3bbSWITCH: " .. KWR.Util:Text(strategy.switchIf, "", 80) .. "|r")
                or ""))
    end
    local changes = snapshot.reassessment and snapshot.reassessment.changes
    page.assignmentCard.heading:SetText(changes and #changes > 0
        and "TEAM SWAP" or "TEAM JOBS")
    for index, row in ipairs(page.assignmentCard.rows) do
        local change = changes and changes[index]
        local assignment = state.assignments[index]
        row:SetText(change and ("|cff4f8cff" .. change.name .. "|r | "
                .. KWR.Assignments:CompactRole(change.fromRole)
                .. "@" .. KWR.Maps:AbbreviateLocation(
                    snapshot.context.mapKey, change.fromLocation)
                .. " -> |cffffd05a"
                .. KWR.Assignments:CompactRole(change.toRole)
                .. "@" .. KWR.Maps:AbbreviateLocation(
                    snapshot.context.mapKey, change.toLocation) .. "|r")
            or (assignment and ("|cff4f8cff" .. assignment.shortName .. "|r | "
                .. assignment.role .. " -> |cffffd05a" .. assignment.location .. "|r") or ""))
    end
    if formationMode then
        page.callerCard.value:SetText("Target caller | backup\nBase calls | route calls\nVoice ready")
        page.focusCard.value:SetText("Voice check | PvP talents | gear\nConsumables ready")
    else
        if teamfight and teamfight.displayEligible == true then
            page.callerCard.value:SetText(table.concat({
                "WHO: " .. tostring(#(teamfight.assignments or {})) .. " local assignments",
                "HOLD: " .. KWR.Util:Text(teamfight.killTarget and teamfight.killTarget.target
                    or "local target", "local target", 64),
                "READ: " .. tostring(teamfight.confidence or "UNKNOWN"),
            }, "\n"))
            page.focusCard.value:SetText(KWR.Util:Text(teamfight.summary,
                "Collapse now.", 180))
        else
            page.callerCard.value:SetText("WHO: " .. KWR.CommandView:CallMovers(command)
                .. "\n|cffb7bdc7" .. KWR.CommandView:TriggerLine(command, state,
                    "WHEN: " .. tostring(command.when or "NOW")) .. "|r")
            page.focusCard.value:SetText(helpers.nextMoveText(state)
                or "Hold your lane until the next swing.")
        end
    end

    if formationMode then
        -- The right-side composition card already owns CURRENT / TARGET / NEED.
        -- Use this left card for the actionable target roster instead of
        -- repeating the same three labels in two places.
        local targetRows = formationRequirementLines(formation)
        if #targetRows == 0 then
            targetRows[1] = formationNeedSummary(formation)
        end
        for index, row in ipairs(page.eventsCard.rows) do
            row:SetText(targetRows[index] or "")
        end
    else
        for index, row in ipairs(page.eventsCard.rows) do
            row:SetText(eventLines[index]
                or (index == 1 and "No fresh map events." or ""))
        end
    end

    local history = KWR.Commander:GetHistory()
    local visible = {}
    for index = math.max(1, #history - 3), #history do
        if history[index] then
            visible[#visible + 1] = history[index]
        end
    end
    if #visible == 0 then
        visible[1] = { status = "WAIT", action = "No recent calls." }
    end
    local gap = 8
    local contentWidth = math.max(150, (page.timelineCard:GetWidth() or 658) - 20)
    local rowWidth
    if #visible == 1 then
        rowWidth = 260
    elseif #visible == 2 then
        rowWidth = math.floor((contentWidth - gap) / 2)
    else
        rowWidth = math.floor((contentWidth - ((#visible - 1) * gap)) / #visible)
    end
    for index, row in ipairs(page.timelineCard.rows) do
        local item = visible[index]
        if item then
            row:Show()
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", page.timelineCard, "TOPLEFT",
                10 + ((index - 1) * (rowWidth + gap)), -30)
            row:SetSize(rowWidth, 52)
            row.badge:SetTone(helpers.statusColor(item.status))
            row.badge:SetText(KWR.Util:Text(item.status, "WAIT", 12))
            row.value:SetText(KWR.CommandView:CompactMapText(snapshot.context.mapKey,
                item.action, "Hold current plan.", #visible == 1 and 72 or 56))
            row.value:SetTextColor(KWR.Theme:Color(index == 1 and "gold" or "soft"))
        else
            row:Hide()
        end
    end
end

function MainWindowPages:RenderObjectives(page, state, helpers)
    local snapshot, prediction = state.snapshot, state.prediction
    local complete = snapshot.context and snapshot.context.matchComplete == true
    local finalStatus = complete and KWR.Util:Text(state.command and state.command.status,
        "COMPLETE", 16) or nil
    local friendly, enemy, friendlyIncoming, enemyIncoming =
        helpers.objectiveCounts(snapshot)
    page.statusCard.heading:SetText(snapshot.context.isBlitz
        and "MAP STATUS - BLITZ" or "MAP STATUS - STANDARD")
    page.summaryCard.heading:SetText(complete and "MATCH COMPLETE" or ((snapshot.objectives.carriers
        and #snapshot.objectives.carriers > 0)
        or (snapshot.objectives.timers and #snapshot.objectives.timers > 0))
        and "MAP SUMMARY - LIVE OBJECTIVES" or "MAP SUMMARY - QUIET")
    page.scoreCard.stateBadge:SetTone(complete and helpers.statusColor(finalStatus)
        or (snapshot.context.inPvP and helpers.statusColor(prediction.status) or "muted"))
    page.scoreCard.stateBadge:SetText(finalStatus or tostring(prediction.status or "WAIT"))
    local objectiveTruth = helpers.truthLabel(snapshot.objectives.source)
    page.scoreCard.truthBadge:SetTone(objectiveTruth == "LIVE" and "green"
        or (objectiveTruth == "OBSERVED" and "yellow" or "muted"))
    page.scoreCard.truthBadge:SetText(objectiveTruth)
    if helpers.hasLiveScore(snapshot.context) then
        page.scoreCard.value:SetText(string.format("|cff4f8cff%d|r  -  |cffff3333%d|r",
            snapshot.score.friendly or 0, snapshot.score.enemy or 0))
        page.scoreCard.detail:SetText(snapshot.context.mapName .. "  |  MAX "
            .. helpers.noDataText(snapshot.score.max, "NO DATA"))
    else
        page.scoreCard.value:SetText("NO DATA")
        page.scoreCard.detail:SetText(snapshot.context.mapName .. "  |  MAX NO DATA")
    end
    local statusRows = {
        "Friendly controlled: " .. friendly,
        "Enemy controlled: " .. enemy,
        "Friendly incoming: " .. friendlyIncoming,
        "Enemy incoming: " .. enemyIncoming,
        "Carriers known: " .. tostring(#(snapshot.objectives.carriers or {})),
        "Assigned team: " .. tostring(snapshot.context.team and snapshot.context.team.faction or "Unknown"),
        "Score source: " .. helpers.truthLabel(snapshot.score.source),
        "Objective source: " .. helpers.truthLabel(snapshot.objectives.source),
        "Ruleset: " .. (snapshot.context.isBlitz and "BLITZ" or "STANDARD"),
    }
    for index, row in ipairs(page.statusCard.rows) do
        row:SetText(statusRows[index] or "")
    end
    local summaryLines = {
        "MATCH STATE: " .. (finalStatus or tostring(prediction.status)),
        "Friendly clock: " .. (complete and "FINAL" or (prediction.friendlyTime and KWR.Util:Clock(prediction.friendlyTime) or "NO DATA")),
        "Enemy clock: " .. (complete and "FINAL" or (prediction.enemyTime and KWR.Util:Clock(prediction.enemyTime) or "NO DATA")),
        complete and "Next step: Open Review / AAR" or ("Urgency: " .. tostring(prediction.urgency or 0)),
        "Confidence: " .. tostring(prediction.confidence or "NONE"),
    }
    for _, carrier in ipairs(snapshot.objectives.carriers or {}) do
        summaryLines[#summaryLines + 1] = string.format("%s: %s  %s%s",
            carrier.objective, carrier.player, carrier.owner,
            (carrier.stacks or 0) > 0 and (" x" .. tostring(carrier.stacks)) or "")
    end
    for _, timer in ipairs(snapshot.objectives.timers or {}) do
        summaryLines[#summaryLines + 1] = timer.objective .. " contested  "
            .. KWR.Util:Clock(timer.remaining)
    end
    page.summaryCard.value:SetText(table.concat(summaryLines, "\n"))
    for index, row in ipairs(page.truthCard.rows) do
        local objective = snapshot.objectives.rows and snapshot.objectives.rows[index]
        row:SetShown(objective ~= nil)
        if objective then
            row.objective:SetText(KWR.Util:Text(objective.label, "Objective", 32))
            row.owner:SetText(KWR.Util:Text(objective.owner, "UNKNOWN", 12))
            row.owner:SetTextColor(KWR.Theme:Color(objective.owner == "FRIENDLY" and "blue"
                or (objective.owner == "ENEMY" and "red" or "yellow")))
            row.state:SetText(helpers.objectiveStateText(objective))
            row.source:SetText(helpers.truthLabel(objective.pendingSource or objective.source))
            row.source:SetTextColor(KWR.Theme:Color(helpers.truthLabel(
                objective.pendingSource or objective.source) == "LIVE" and "green"
                or (helpers.truthLabel(objective.pendingSource or objective.source) == "OBSERVED"
                    and "yellow" or "muted")))
        end
    end
    page.truthCard.empty:SetShown(not snapshot.context.inPvP
        or not snapshot.objectives.rows or #snapshot.objectives.rows == 0)
    page.conditionCard.urgencyBadge:SetTone(complete and "green" or helpers.urgencyTone(prediction.urgency))
    page.conditionCard.urgencyBadge:SetText(complete and "FINAL" or ("URG " .. tostring(prediction.urgency or 0)))
    page.conditionCard.confidenceBadge:SetTone(prediction.confidence == "HIGH" and "green"
        or (prediction.confidence == "MEDIUM" and "yellow"
        or (prediction.confidence == "LOW" and "orange" or "muted")))
    page.conditionCard.confidenceBadge:SetText(tostring(prediction.confidence or "NONE"))
    page.conditionCard.value:SetText(complete
        and ("Match complete.\n\n|cff49dd49" .. (finalStatus or "FINAL")
            .. " - open Review / AAR to capture the lesson.|r")
        or ((prediction.condition or "Waiting.")
            .. "\n\n|cffffd05a" .. (prediction.action or "") .. "|r"))
    page.callsCard.helper:SetText(complete and "MATCH COMPLETE - REVIEW / AAR NEXT"
        or (snapshot.context.preview and "PREVIEW CALLS - SAFE TO TEST"
        or (snapshot.context.inPvP and "CLICK TO SEND OR COPY"
            or "SETUP CALLS - COPY ONLY")))
    page.callsCard.statusBadge:SetTone(complete and "muted" or (snapshot.context.inPvP and "green"
        or (snapshot.context.preview and "orange" or "muted")))
    page.callsCard.statusBadge:SetText(complete and "CLOSED" or (snapshot.context.inPvP and "LIVE"
        or (snapshot.context.preview and "PREVIEW" or "READY")))
    page.callsCard.statusText:SetText(complete and "TACTICAL CALLS CLOSED AFTER MATCH END"
        or (snapshot.context.inPvP
        and "LEFT SENDS  |  RIGHT COPIES"
        or "COPY ONLY OUTSIDE BATTLEGROUNDS"))
    self:SetQuickCallsClosed(page, complete)
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local infoRows = {
        snapshot.context.mapName,
        helpers.noDataText(snapshot.context.kind, "NO DATA"),
        definition and helpers.noDataText(definition.short, "NO DATA") or "NO DATA",
        helpers.hasLiveScore(snapshot.context)
            and helpers.noDataText(snapshot.score.max, "NO DATA") or "NO DATA",
        definition and #(definition.priorities or {}) > 0
            and table.concat(definition.priorities or {}, ", ") or "NO DATA",
    }
    for index, row in ipairs(page.infoCard.rows) do
        row.value:SetText(infoRows[index] or "NO DATA")
    end
    local showEvent = snapshot.context.inPvP and snapshot.lastMessage ~= ""
    page.infoCard.eventLabel:SetShown(showEvent)
    page.infoCard.eventValue:SetShown(showEvent)
    page.infoCard.eventValue:SetText(showEvent and snapshot.lastMessage or "")
end

function MainWindowPages:RenderAssignments(page, state, helpers)
    local audit = KWR.Assignments:Audit(state.snapshot, state.assignments)
    local _, _, line3 = KWR.CommandView:SummaryLines(state)
    local formation = state.snapshot.formation or {}
    local commandAction = state.command and state.command.action or nil
    local review = recentReviewEntry(state)
    if review then
        local assignmentRows = sortedRecords(review.playerEvidence)
        local assignmentByPlayer = reviewAssignmentByName(review)
        local mineName = UnitName and UnitName("player") or nil
        local mine = assignmentByPlayer[mineName] or assignmentByPlayer.Verite
        page.commandCard.value:SetText("Match ended. Capture the AAR and review the final swing.")
        page.commandCard.stateBadge:SetTone(review.result == "VICTORY" and "green"
            or (review.result == "DEFEAT" and "red" or "yellow"))
        page.commandCard.stateBadge:SetText(KWR.Util:Text(review.result, "REVIEW", 12))
        page.commandCard.coverageBadge:SetTone("green")
        page.commandCard.coverageBadge:SetText("AAR READY")
        page.commandCard.detail:SetText(table.concat({
            "MAP: " .. KWR.Util:Text(review.mapName or review.mapKey, "Unknown", 48),
            "SCORE: " .. tostring(review.scoreEnd and review.scoreEnd.friendly or 0)
                .. "-" .. tostring(review.scoreEnd and review.scoreEnd.enemy or 0),
            "REVIEW NOW",
        }, "  |  "))
        for index, row in ipairs(page.boardCard.rows) do
            local player = assignmentRows[index]
            row:SetShown(player ~= nil)
            if player then
                row.player:SetText(KWR.Util:Text(player.name, "Unknown", 28))
                row.player:SetTextColor(helpers.classColor(player.classFile or player.class))
                row.class:SetText(KWR.Util:Text(player.spec, "Unknown spec", 26)
                    .. " / " .. KWR.Util:Text(player.role, "Unknown", 16))
                row.assignment:SetText(KWR.Util:Text(player.assignedRole, "Review", 32))
                row.location:SetText(KWR.Util:Text(player.assignedLocation, "Unknown", 24))
                row.priority:SetText(player.deathsObserved and player.deathsObserved > 0
                    and "REVIEW" or "FINAL")
            end
        end
        page.mineCard.lockBadge:SetTone("muted")
        page.mineCard.lockBadge:SetText("REVIEW")
        page.mineCard.value:SetText(mine and table.concat({
            KWR.Util:Text(mine.name, "You", 28),
            KWR.Util:Text(mine.assignedRole, "Assignment", 36),
            "|cffffd05a" .. KWR.Util:Text(mine.assignedLocation, "Unknown", 32) .. "|r",
            "|cff8ea3bb"
                .. KWR.Util:Text((mine.deathsObserved or 0) > 0
                    and "Deaths were recorded during the match."
                    or "No death event was recorded in the journal.",
                    "", 88)
                .. "|r",
        }, "\n") or "Open the AAR to review your final assignment.")
        page.logicCard.heading:SetText("REVIEW SNAPSHOT")
        page.logicCard.value:SetText(table.concat({
            "FINAL RESULT: " .. KWR.Util:Text(review.result, "Unknown", 24),
            "DURATION: " .. (review.duration and KWR.Util:Clock(review.duration) or "Unknown"),
            "FINAL CALL: " .. KWR.Util:Text(
                review.finalCommand and review.finalCommand.action,
                "No final command recorded.", 128),
            "",
            "NEXT STEP: Save the lesson, review the swing, and export evidence if needed.",
        }, "\n"))
        updateLogicCardBody(page.logicCard, 96)
        return
    end
    page.commandCard.value:SetText(not state.snapshot.context.inPvP
        and ("Recruit: " .. (formation.needText or "Roster complete"))
        or KWR.Util:Text(commandAction, "Play objective.", 116))
    page.commandCard.stateBadge:SetTone(helpers.statusColor(state.command.status))
    page.commandCard.stateBadge:SetText(KWR.Util:Text(state.command.status, "LIVE", 12))
    page.commandCard.coverageBadge:SetTone(audit.ok and "green" or "yellow")
    page.commandCard.coverageBadge:SetText(audit.ok and "READY" or "CHECK TEAM")
    page.commandCard.detail:SetText(table.concat({
        "WHO: " .. KWR.Util:Text(state.command.who, "Team", 80),
        "CONF: " .. KWR.Util:Text(state.command.confidence, "NONE", 18),
        audit.ok and "Team covered" or "Coverage needs a check",
    }, "  |  "))
    for index, row in ipairs(page.boardCard.rows) do
        local assignment = state.assignments[index]
        row:SetShown(assignment ~= nil)
        if assignment then
            row.player:SetText(assignment.shortName .. (assignment.dead and "  DEAD" or ""))
            row.player:SetTextColor(helpers.classColor(assignment.classFile))
            local spec = KWR.Util:Text(assignment.spec, "Unknown spec", 28)
            if assignment.specSource == "historical" then spec = spec .. " (HIST)" end
            row.class:SetText(spec .. " " .. assignment.class .. " / "
                .. helpers.roleText(assignment.groupRole))
            row.assignment:SetText(assignment.role
                .. (assignment.manualOverride and "  [LOCK]" or ""))
            row.location:SetText(assignment.location)
            row.priority:SetText(assignment.dead and "DEAD"
                or helpers.assignmentPriority(assignment.priority))
        end
    end
    local mine = helpers.selfAssignment(state)
    page.mineCard.value:SetText(mine and (mine.shortName .. "\n" .. helpers.roleText(mine.role)
        .. "\n|cffffd05a" .. mine.location
        .. "|r\n" .. helpers.assignmentPriority(mine.priority)
        .. (mine.manualOverride and "\n|cff49dd49MANUAL HOLD|r" or "")
        .. (mine.handoff and ("\n|cff8ea3bb" .. KWR.Util:Text(mine.handoff, "", 92) .. "|r") or ""))
        or "Assignment pending.")
    local definition = KWR.Maps:Get(state.snapshot.context.mapKey)
    local strategy = state.snapshot.strategy or {}
    local counter = strategy.counter or {}
    local decision = strategy.objectiveDecision or {}
    local counterSteps = counter.sequence and table.concat(counter.sequence, " -> ") or nil
    local response = state.snapshot.responsePackage or {}
    local overrides = KWR.AssignmentOverrides and KWR.AssignmentOverrides:DescribeActive(
        state.snapshot, state.assignments) or {}
    page.mineCard.lockBadge:SetTone(mine and mine.manualOverride and "green" or "muted")
    page.mineCard.lockBadge:SetText(mine and mine.manualOverride and "MANUAL HOLD" or "AUTO")
    page.logicCard.heading:SetText(#overrides > 0
        and "WHY THIS PLAN - MANUAL HOLDS ACTIVE" or "WHY THIS PLAN")
    if not state.snapshot.context.inPvP then
        local targetComp = formation.buildTarget or formation.currentComp
            or (formation.tierMatch and formation.tierMatch.qualified
                and formation.tierMatch or nil)
            or formation.archetype
        page.logicCard.value:SetText(table.concat({
            "|cffffd05aTARGET BUILD|r",
            formationCompLabel(targetComp, "Balanced Team Fight"),
            "",
            "|cffffd05aROSTER NEED|r",
            formationNeedSummary(formation),
            "",
            "|cffffd05aASSIGNMENT RULE|r",
            "One player | one job | one location",
            "Formation updates as the roster changes.",
            "",
            "|cffffd05aCOVERAGE|r",
            audit.ok and (tostring(audit.coverage) .. " / " .. tostring(audit.roster)
                .. " READY") or table.concat(audit.issues, "; "),
            "",
            "|cffffd05aMANUAL HOLDS|r",
            #overrides > 0 and table.concat(overrides, "\n") or "None",
        }, "\n"))
        updateLogicCardBody(page.logicCard, 180)
        return
    end
    page.logicCard.value:SetText(table.concat({
        "MAP: " .. KWR.Util:Text(definition and definition.title, definition and definition.kind or "RBG", 40),
        "PLAN: " .. KWR.Util:Text(strategy.state or "SETUP", "SETUP", 28),
        "FOCUS: " .. KWR.Util:Text(helpers.weightedFocusText(strategy), "Play the objective.", 92),
        "WIN: " .. KWR.Util:Text(
            decision.success, "Confirm the objective state changes.", 108),
        "RESET: " .. KWR.Util:Text(
            decision.abort, "Reassess when the scoring path changes.", 108),
        "",
        "ACTION: " .. KWR.Util:Text(response.action, "Hold current plan.", 96),
        "WHO: " .. KWR.Util:Text(response.moverText, "Team", 84),
        "HOLD: " .. KWR.Util:Text(response.stayerText, "Assigned defenders", 84),
        string.format("READY: %s | CONF: %s | VALUE %d",
            response.qualified and "YES" or "NO",
            tostring(response.confidence or "NONE"),
            response.score or 0),
        "",
        "ENEMY PLAN: " .. KWR.Util:Text(
            counter.emphasis, "Collecting enemy composition.", 116),
        counterSteps and ("IF THEY SET UP: " .. KWR.Util:Text(counterSteps, "", 144)) or "",
        "AVOID: " .. KWR.Util:Text(
            counter.avoid, "Do not split without a scoring reason.", 112),
        "",
        "MANUAL HOLDS: " .. (#overrides > 0 and tostring(#overrides) or "none"),
        #overrides > 0 and table.concat(overrides, "\n") or "No manual holds active.",
        "",
        audit.ok and ("COVERAGE CHECKED " .. tostring(audit.coverage)
            .. "/" .. tostring(audit.roster))
            or ("CHECK: " .. table.concat(audit.issues, "; ")),
    }, "\n"))
    updateLogicCardBody(page.logicCard, 220)
end

function MainWindowPages:RenderTeam(page, state, helpers)
    local roster = state.snapshot.roster or {}
    local review = recentReviewEntry(state)
    if review then
        local team = sortedRecords(review.friendlyTeam)
        local assignmentByPlayer = reviewAssignmentByName(review)
        local tanks, healers, damage = 0, 0, 0
        for _, player in ipairs(team) do
            local role = KWR.Util:Text(player.role, "UNKNOWN", 16)
            if role == "TANK" then
                tanks = tanks + 1
            elseif role == "HEALER" then
                healers = healers + 1
            else
                damage = damage + 1
            end
        end
        page.summaryCard.value:SetText(string.format(
            "POST-MATCH   |   %d PLAYERS   |   %d TANK   |   %d HEALERS   |   %d DAMAGE",
            #team, tanks, healers, damage))
        page.summaryCard.readyBadge:SetTone(review.result == "VICTORY" and "green"
            or (review.result == "DEFEAT" and "red" or "yellow"))
        page.summaryCard.readyBadge:SetText(KWR.Util:Text(review.result, "REVIEW", 18))
        page.summaryCard.openBadge:SetTone("muted")
        page.summaryCard.openBadge:SetText("SNAPSHOT")
        page.summaryCard.detail:SetText(
            "Recent battleground roster snapshot. Open AAR for the full breakdown.")
        for index, row in ipairs(page.rosterCard.rows) do
            local player = team[index]
            local assignment = player
                and assignmentByPlayer[player.name] or nil
            local signature = player and KWR.Util:Signature({
                "REVIEW", player.guid, player.name,
                player.classFile or player.class,
                player.spec, player.role,
                assignment and assignment.assignedRole,
                assignment and assignment.assignedLocation,
            }) or "EMPTY"
            if beginRosterRowRender(row, signature) then
                setShownChanged(row, player ~= nil)
                if player then
                    row.displayUnit = nil
                    helpers.setClassIcon(row.icon, player.classFile or player.class)
                    row.player:SetText(KWR.Util:Text(player.name, "Unknown", 24))
                    row.player:SetTextColor(
                        helpers.classColor(player.classFile or player.class))
                    row.spec:SetText(KWR.Util:Text(player.spec, "Unknown spec", 26))
                    row.role:SetText(helpers.roleText(
                        KWR.Util:Text(player.role, "UNKNOWN", 16)))
                    row.health:SetValue(0)
                    row.health:SetStatusBarColor(KWR.Theme:Color("dim"))
                    row.healthText:SetText("FINAL")
                    row.life:SetText("RECORDED")
                    row.life:SetTextColor(KWR.Theme:Color("soft"))
                    row.position:SetText(assignment and (KWR.Util:Text(
                        assignment.assignedRole, "Review", 24)
                        .. " -> " .. KWR.Util:Text(
                            assignment.assignedLocation, "Unknown", 24))
                        or "RECORDED")
                else
                    row.displayUnit = nil
                    row.health:SetValue(0)
                    row.player:SetText("")
                    row.spec:SetText("")
                    row.role:SetText("")
                    row.healthText:SetText("")
                    row.life:SetText("")
                    row.position:SetText("")
                end
            end
        end
        page.doctrineCard.heading:SetText("MATCH PLAN")
        page.doctrineCard.value:SetText(table.concat({
            KWR.Util:Text(review.mapName or review.mapKey, "Recent battleground", 48),
            "",
            "RESULT",
            KWR.Util:Text(review.result, "Unknown", 24),
            "",
            "FINAL CALL",
            KWR.Util:Text(review.finalCommand and review.finalCommand.action,
                "No final command recorded.", 148),
        }, "\n"))
        page.readinessCard.heading:SetText("ROSTER SNAPSHOT")
        page.readinessCard.value:SetText(string.format(
            "%d PLAYERS  |  %d-%d  |  %s  |  %s",
            #team,
            review.scoreEnd and review.scoreEnd.friendly or 0,
            review.scoreEnd and review.scoreEnd.enemy or 0,
            review.duration and KWR.Util:Clock(review.duration) or "NO TIME",
            (review.feedback and next(review.feedback)) and "REVIEWED" or "OPEN"))
        page.readinessCard.stateBadge:SetTone("muted")
        page.readinessCard.stateBadge:SetText("POST MATCH")
        updateLogicCardBody(page.doctrineCard, 100)
        return
    end
    local tanks, healers, damage, dead = 0, 0, 0, 0
    for _, player in ipairs(roster) do
        local role = KWR.CombatSpells:Role(player.spec, player.role)
        if role == "TANK" then
            tanks = tanks + 1
        elseif role == "HEALER" then
            healers = healers + 1
        else
            damage = damage + 1
        end
        if player.dead then
            dead = dead + 1
        end
    end
    local formation = state.snapshot.formation or {}
    local mapKey = state.snapshot.context.mapKey
    local assignmentByName = {}
    for _, assignment in ipairs(state.assignments or {}) do
        assignmentByName[assignment.name] = assignment
        assignmentByName[assignment.shortName] = assignment
    end
    local displayCapacity = math.max(#roster, formation.targetSize or 0)
    page.summaryCard.value:SetText(string.format(
        "%d / %d PLAYERS   |   %d TANK   |   %d HEALERS   |   %d DAMAGE",
        #roster, displayCapacity, tanks, healers, damage))
    page.summaryCard.readyBadge:SetTone(helpers.readinessTone(dead, formation.openSlots))
    page.summaryCard.readyBadge:SetText(dead == 0 and "READY" or (tostring(dead) .. " UNAVAILABLE"))
    page.summaryCard.openBadge:SetTone((formation.openSlots or 0) > 0 and "yellow" or "green")
    page.summaryCard.openBadge:SetText((formation.openSlots or 0) > 0
        and (tostring(formation.openSlots or 0) .. " OPEN") or "FULL")
    page.summaryCard.detail:SetText((dead == 0 and "Command unit ready."
        or (tostring(dead) .. " players down."))
        .. " Assignments use role, specialization capabilities, and map doctrine.")
    for index, row in ipairs(page.rosterCard.rows) do
        local player = roster[index]
        local assignment = player and (
            assignmentByName[player.name]
            or assignmentByName[player.shortName]) or nil
        local signature = player and KWR.Util:Signature({
            "LIVE", player.key, player.guid,
            player.name, player.shortName, player.unit,
            player.classFile, player.spec,
            player.specSource, player.role,
            player.healthPercent, player.lastHealthPercent,
            player.dead, player.connected,
            assignment and assignment.role,
            assignment and assignment.shortRole,
            assignment and assignment.location,
            assignment and assignment.display,
            assignment and assignment.movement,
        }) or "EMPTY"
        if beginRosterRowRender(row, signature) then
            setShownChanged(row, player ~= nil)
            if player then
                row.displayUnit = player.unit
                helpers.setClassIcon(row.icon, player.classFile)
                row.player:SetText(player.shortName)
                row.player:SetTextColor(helpers.classColor(player.classFile))
                row.spec:SetText(helpers.specLabel(player))
                row.role:SetText(helpers.roleText(
                    KWR.CombatSpells:Role(player.spec, player.role)))
                local health = player.healthPercent
                row.health:SetValue(health or 0)
                row.health:SetStatusBarColor(helpers.healthColor(health))
                local direct = not health and helpers.applyDirectHealth(
                    row.health, player.unit, row.healthText)
                if health then
                    row.healthText:SetText(
                        tostring(math.floor(health + 0.5)) .. "%")
                elseif not direct then
                    row.healthText:SetText("UNKNOWN")
                end
                local critical = health and health <= 35 and not player.dead
                row.life:SetText(player.dead and "DEAD"
                    or (player.connected == false and "OFFLINE"
                    or (critical and "CRITICAL" or "READY")))
                row.life:SetTextColor(KWR.Theme:Color(player.dead and "red"
                    or (critical and "orange" or "green")))
                row.position:SetText(assignment
                    and KWR.Assignments:CompactLabel(assignment, mapKey)
                    or "UNASSIGNED")
            else
                row.displayUnit = nil
                row.health:SetValue(0)
                row.player:SetText("")
                row.spec:SetText("")
                row.role:SetText("")
                row.healthText:SetText("")
                row.life:SetText("")
                row.position:SetText("")
            end
        end
    end
    local definition = KWR.Maps:Get(state.snapshot.context.mapKey)
    local doctrine = KWR.Doctrine:Get(state.snapshot.context.mapKey)
    if not state.snapshot.context.inPvP then
        page.doctrineCard.heading:SetText("SETUP PLAN")
        local currentComp = formation.currentComp
            or (formation.tierMatch and formation.tierMatch.qualified
                and formation.tierMatch or nil)
        local targetComp = formation.buildTarget
        local currentLabel = formationCompLabel(currentComp,
            formation.archetype and formation.archetype.name or "Balanced Team Fight")
        local targetLabel = targetComp
            and formationCompLabel(targetComp, targetComp.name)
            or "AUTO TARGET: HYBRID"
        local recruits = {}
        for index = 1, math.min(4, #(formation.recommendations or {})) do
            local acquisition = tostring(formation.recommendations[index].acquisition or "OPEN SLOT")
            if acquisition == "OPEN SLOT" then
                acquisition = "OPEN"
            end
            recruits[#recruits + 1] = formation.recommendations[index].label
                .. " [" .. acquisition .. "]"
        end
        local plan = {
            "|cffffd05aCURRENT|r",
            currentLabel,
            "|cffffd05aTARGET|r",
            targetLabel,
        }
        local requirements = formationRequirementLines(formation)
        if #requirements > 0 then
            plan[#plan + 1] = "|cffffd05aTARGET ROSTER|r"
            for _, line in ipairs(requirements) do
                plan[#plan + 1] = line
            end
        end
        plan[#plan + 1] = "|cffffd05aTARGET NEED|r"
        plan[#plan + 1] = formationTargetNeedSummary(formation)
        plan[#plan + 1] = "|cffffd05aRECRUIT PRIORITY|r"
        plan[#plan + 1] = #recruits > 0
            and table.concat(recruits, " | ") or "ROSTER COMPLETE"
        if targetComp and targetComp.assignments then
            plan[#plan + 1] = "|cffffd05aCOMP JOBS|r"
            plan[#plan + 1] = targetComp.assignments
        end
        page.doctrineCard.value:SetText(table.concat(plan, "\n"))
    else
        page.doctrineCard.heading:SetText("MAP PLAN")
        page.doctrineCard.value:SetText(table.concat({
            definition and definition.title or "Formation",
            "",
            "WHEN WINNING", doctrine.win,
            "",
            "WHEN TIED", doctrine.even,
            "",
            "WHEN LOSING", doctrine.lose,
        }, "\n"))
    end
    updateLogicCardBody(page.doctrineCard, 100)
    page.readinessCard.value:SetText(string.format(
        "%d CONNECTED  |  %d DOWN  |  %d JOBS  |  %d OPEN",
        #roster, dead, #(state.assignments or {}),
        formation.openSlots or 0))
    page.readinessCard.stateBadge:SetTone((formation.openSlots or 0) > 0 and "yellow"
        or helpers.readinessTone(dead, formation.openSlots))
    page.readinessCard.stateBadge:SetText((formation.openSlots or 0) > 0 and "RECRUITING"
        or (dead > 0 and "PRESSURED" or "STABLE"))
    page.readinessCard.heading:SetText("ROSTER STATUS")
end

local function priorityLabel(priority)
    local labels = {
        [0] = "OBSERVE",
        [1] = "MONITOR",
        [2] = "PRESSURE",
        [3] = "KILL",
    }
    return labels[priority or 0] or "OBSERVE"
end

function MainWindowPages:RenderEnemies(page, state, helpers)
    local review = recentReviewEntry(state)
    if review then
        local threats = sortedRecords(review.enemyThreats)
        page.toolbar.liveBadge:SetTone("muted")
        page.toolbar.liveBadge:SetText("POST MATCH")
        page.toolbar.mode:SetText("RECORDED REVIEW DATA")
        page.toolbar.summary:SetText(string.format(
            "RECORDED %d  |  SNAPSHOT TRUTH  |  AAR AVAILABLE",
            #threats))
        setShownChanged(page.trackerCard.empty, #threats == 0)
        for index, row in ipairs(page.trackerCard.rows) do
            local threat = threats[index]
            local signature = threat and KWR.Util:Signature({
                "REVIEW", threat.name, threat.shortName,
                threat.classFile, threat.class,
                threat.spec, threat.role, threat.sightings,
                threat.hotspot, threat.lastObjective,
            }) or "EMPTY"
            if beginRosterRowRender(row, signature) then
                setShownChanged(row, threat ~= nil)
                row.enemyKey = nil
                row.enemyData = nil
                row.displayUnit = nil
                if threat then
                    row.priority:SetText("O")
                    row.seen:SetText((threat.sightings or 0) > 1
                        and (tostring(threat.sightings) .. "x") or "RECORDED")
                    row.seen:SetTextColor(KWR.Theme:Color("muted"))
                    helpers.setClassIcon(
                        row.icon, threat.classFile or threat.class)
                    row.name:SetText(
                        KWR.Util:Text(threat.name, "Unknown", 24))
                    row.name:SetTextColor(
                        helpers.classColor(threat.classFile or threat.class))
                    row.spec:SetText(
                        KWR.Util:Text(threat.spec, "Unknown spec", 24)
                        .. " | "
                        .. KWR.Util:Text(threat.role, "Unknown", 14))
                    row.health:SetMinMaxValues(0, 100)
                    row.health:SetValue(0)
                    row.health:SetStatusBarColor(KWR.Theme:Color("dim"))
                    row.healthText:SetText("RECORDED")
                    row.location:SetText(KWR.Util:Text(
                        threat.hotspot or threat.lastObjective or "RECORDED",
                        "RECORDED", 26))
                    row.cooldown:SetText("AAR SNAPSHOT")
                    row.cooldown:SetTextColor(KWR.Theme:Color("muted"))
                    row.note:SetText("AAR")
                    KWR.Theme:Style(row.note, "card", "border")
                    row.note.label:SetTextColor(KWR.Theme:Color("soft"))
                    KWR.Theme:Style(
                        row, index % 2 == 0 and "panel" or "card", "panel")
                end
            end
        end
        local threat = threats[1]
        local detailSignature = threat and KWR.Util:Signature({
            "REVIEW", threat.name, threat.class,
            threat.spec, threat.role, threat.hotspot,
            threat.sightings,
        }) or "EMPTY"
        if page.detailSignature ~= detailSignature then
            page.detailSignature = detailSignature
            page.detailCard.identity:SetText(threat
                and KWR.Util:Text(threat.name, "Unknown enemy", 48)
                or "NO RECORDED ENEMY")
            page.detailCard.summary:SetText(threat and table.concat({
                KWR.Util:Text(threat.role, "UNKNOWN ROLE", 18),
                KWR.Util:Text(threat.spec, "UNKNOWN SPEC", 28),
                KWR.Util:Text(
                    threat.hotspot or threat.lastObjective,
                    "NO LOCATION", 34),
            }, "  |  ") or "No enemy snapshot was recorded.")
            page.detailCard.note:SetText(threat
                and "Review the AAR for the evidence captured during this match."
                or "Enemy intelligence will appear after a battleground feed is observed.")
            page.detailCard.truthBadge:SetTone("muted")
            page.detailCard.truthBadge:SetText("RECORDED")
            page.detailCard.priorityBadge:SetTone("muted")
            page.detailCard.priorityBadge:SetText("AAR")
            setShownChanged(page.detailCard.edit, false)
        end
        return
    end

    local snapshot = state.snapshot or {}
    local context = snapshot.context or {}
    local enemies = snapshot.enemies or {}
    local roster = KWR.TeamResolver:NormalizePublishedRoster(
        snapshot.roster or {})
    local friendlyScoreFaction = context.team
        and context.team.scoreFaction
    enemies = KWR.EnemyIntel:FilterPublishedTruth(
        roster, enemies, friendlyScoreFaction)
    local sessionKey = KWR.Util:Text(
        context.sessionKey,
        KWR.Util:BattlefieldSessionKey(context), 96)
    if page.lastSessionKey ~= sessionKey then
        page.lastSessionKey = sessionKey
        page.enemySlotKeys = {}
        page.detailSignature = nil
        for _, row in ipairs(page.trackerCard.rows) do
            row.renderSignature = nil
        end
    end
    local stableEnemies =
        KWR.CombatRosterState:StableEnemyRows(page, enemies)
    page.toolbar.liveBadge:SetTone(context.preview and "orange"
        or (context.inPvP and "green" or "muted"))
    page.toolbar.liveBadge:SetText(context.preview and "PREVIEW"
        or (context.inPvP and "LIVE INTEL" or "NO FEED"))
    page.toolbar.mode:SetText(context.preview
        and "PREVIEW DATA"
        or (context.inPvP and "LIVE DATA"
            or "SETUP DATA"))
    page.toolbar.summary:SetText(helpers.enemyTrackerSummary(enemies))
    setShownChanged(page.trackerCard.empty, #enemies == 0)

    local selectedEnemy
    for _, enemy in ipairs(enemies) do
        if enemy.key == KWR.MainWindow.selectedEnemyKey then
            selectedEnemy = enemy
            break
        end
    end
    if not selectedEnemy then
        selectedEnemy = enemies[1]
        KWR.MainWindow.selectedEnemyKey =
            selectedEnemy and selectedEnemy.key or nil
    end

    local mapKey = context.mapKey
    local focusTarget = helpers.activeCombatTarget(snapshot.combat)
    for index, row in ipairs(page.trackerCard.rows) do
        local enemy = stableEnemies[index]
        local selected = enemy
            and enemy.key == KWR.MainWindow.selectedEnemyKey
        local action =
            KWR.RosterPresentation:EnemyAction(
                enemy, nil, mapKey, false)
        local actionText, actionTone =
            action.text, action.tone
        local signature = enemy and KWR.Util:Signature({
            "LIVE", enemy.key, enemy.guid,
            enemy.name, enemy.shortName, enemy.unit,
            enemy.classFile, enemy.class,
            enemy.spec, enemy.specSource,
            enemy.role, enemy.metaRank, enemy.metaCaptured,
            enemy.priority, enemy.age, enemy.visible,
            enemy.healthPercent, enemy.lastHealthPercent,
            enemy.locationState, enemy.location,
            enemy.locationSource, enemy.locationInferred,
            enemy.engagementRole, enemy.lastObjective,
            enemy.carrier, enemy.carrierStacks,
            enemy.trinketState, enemy.cooldownText,
            enemy.priorityCast and enemy.priorityCast.spellID,
            enemy.priorityCast and enemy.priorityCast.name,
            enemy.defensivesActive and enemy.defensivesActive[1]
                and enemy.defensivesActive[1].spellID,
            enemy.note, enemy.noteTagSummary,
            enemy.profile and enemy.profile.label,
            actionText, selected,
            focusTarget and focusTarget.key == enemy.key,
        }) or "EMPTY"
        if beginRosterRowRender(row, signature) then
            setShownChanged(row, enemy ~= nil)
            if enemy then
                row.enemyKey = enemy.key
                row.enemyData = enemy
                row.displayUnit = enemy.unit
                local marks = {
                    [0] = "O",
                    [1] = "M",
                    [2] = "H",
                    [3] = "K",
                }
                row.priority:SetText(marks[enemy.priority or 0] or "O")
                row.seen:SetText(
                    enemy.age and KWR.Util:Age(enemy.age) or "ROSTER")
                row.seen:SetTextColor(
                    KWR.Theme:Color(helpers.enemySeenTone(enemy)))
                helpers.setClassIcon(row.icon, enemy.classFile)
                row.name:SetText(KWR.Util:Text(
                    enemy.shortName or enemy.name, "Unknown", 24))
                local red, green, blue =
                    helpers.classColor(enemy.classFile)
                row.name:SetTextColor(
                    enemy.r or red,
                    enemy.g or green,
                    enemy.b or blue)
                local specText = helpers.specLabel(enemy)
                    .. " " .. KWR.Util:Text(enemy.class, "", 20)
                if enemy.role == "HEALER" or enemy.role == "TANK" then
                    specText = enemy.role .. " | " .. specText
                end
                row.spec:SetText(specText)
                local health = enemy.healthPercent
                local lastHealth =
                    KWR.Util:Number(enemy.lastHealthPercent, nil)
                local displayHealth = health or lastHealth
                row.health:SetMinMaxValues(0, 100)
                row.health:SetValue(displayHealth or 0)
                local barColor = not health and "dim"
                    or (health > 70 and "green"
                    or (health > 35 and "yellow" or "red"))
                row.health:SetStatusBarColor(
                    KWR.Theme:Color(barColor))
                local direct = not health and helpers.applyDirectHealth(
                    row.health, enemy.unit, row.healthText)
                if health then
                    row.healthText:SetText(
                        tostring(math.floor(health + 0.5)) .. "%")
                elseif lastHealth and not direct then
                    row.healthText:SetText(
                        "~" .. tostring(math.floor(lastHealth + 0.5)) .. "%")
                elseif not direct then
                    row.healthText:SetText("--")
                end
                row.location:SetText(
                    KWR.EnemyIntel:DescribeLocation(
                        enemy, mapKey, false))
                row.cooldown:SetText(actionText)
                row.cooldown:SetTextColor(
                    KWR.Theme:Color(actionTone))
                row.note:SetText(
                    enemy.note and enemy.note ~= "" and "NOTE" or "VIEW")
                KWR.Theme:Style(
                    row.note,
                    selected and "raised" or "card",
                    selected and "gold"
                        or helpers.trustTone(enemy.profile))
                row.note.label:SetTextColor(KWR.Theme:Color(
                    selected and "gold"
                        or (enemy.note and enemy.note ~= ""
                            and "white" or "soft")))
                local kill =
                    focusTarget and focusTarget.key == enemy.key
                KWR.Theme:Style(
                    row,
                    index % 2 == 0 and "panel" or "card",
                    kill and "red"
                        or (selected and "gold" or "panel"))
            else
                row.enemyKey = nil
                row.enemyData = nil
                row.displayUnit = nil
            end
        end
    end

    local selectedProjection =
        KWR.RosterPresentation:EnemyAction(
            selectedEnemy, nil, mapKey, false)
    local selectedAction, selectedTone =
        selectedProjection.text, selectedProjection.tone
    local detailSignature = selectedEnemy and KWR.Util:Signature({
        selectedEnemy.key, selectedEnemy.shortName,
        selectedEnemy.class, selectedEnemy.classFile,
        selectedEnemy.spec, selectedEnemy.specSource,
        selectedEnemy.role, selectedEnemy.priority,
        selectedEnemy.age, selectedEnemy.visible,
        selectedEnemy.locationState, selectedEnemy.location,
        selectedEnemy.locationSource,
        selectedEnemy.locationInferred,
        selectedEnemy.engagementRole,
        selectedEnemy.lastObjective,
        selectedEnemy.note, selectedEnemy.noteTagSummary,
        selectedEnemy.profile and selectedEnemy.profile.label,
        selectedEnemy.profile and selectedEnemy.profile.commanderTakeaway,
        selectedAction,
    }) or "EMPTY"
    if page.detailSignature ~= detailSignature then
        page.detailSignature = detailSignature
        page.detailCard.identity:SetText(selectedEnemy
            and (KWR.Util:Text(
                selectedEnemy.shortName or selectedEnemy.name,
                "Unknown enemy", 40)
                .. "  |  "
                .. helpers.specLabel(selectedEnemy)
                .. " "
                .. KWR.Util:Text(selectedEnemy.class, "", 20))
            or "NO ENEMY SELECTED")
        local profile = selectedEnemy and selectedEnemy.profile
        page.detailCard.summary:SetText(selectedEnemy and table.concat({
            KWR.Util:Text(
                selectedEnemy.role, "UNKNOWN ROLE", 18),
            KWR.EnemyIntel:DescribeLocation(
                selectedEnemy, mapKey, true),
            selectedAction,
            KWR.Util:Text(
                profile and profile.commanderTakeaway,
                "Profile is thin; rely on live evidence.", 84),
        }, "  |  ") or
            "Enemy intelligence will appear when Blizzard exposes it.")
        local note = selectedEnemy
            and KWR.Util:Text(selectedEnemy.note, "", 180) or ""
        if note == "" and selectedEnemy
            and selectedEnemy.noteTagSummary
            and selectedEnemy.noteTagSummary ~= "No tags" then
            note = "TAGS: " .. KWR.Util:Text(
                selectedEnemy.noteTagSummary, "", 140)
        end
        page.detailCard.note:SetText(note ~= ""
            and ("FIELD NOTE: " .. note)
            or "No field note. Select EDIT NOTE to record a durable observation.")
        page.detailCard.truthBadge:SetTone(
            helpers.enemySeenTone(selectedEnemy))
        page.detailCard.truthBadge:SetText(selectedEnemy
            and (selectedEnemy.visible and "VISIBLE"
                or (selectedEnemy.age
                    and ("SEEN " .. KWR.Util:Age(selectedEnemy.age))
                    or "ROSTER"))
            or "NO FEED")
        page.detailCard.priorityBadge:SetTone(
            (selectedEnemy and selectedEnemy.priority or 0) >= 3 and "red"
            or ((selectedEnemy and selectedEnemy.priority or 0) >= 2
                and "orange" or selectedTone))
        page.detailCard.priorityBadge:SetText(
            priorityLabel(selectedEnemy and selectedEnemy.priority))
        setShownChanged(page.detailCard.edit, selectedEnemy ~= nil)
    end
end

function MainWindowPages:RenderIntel(page, state, helpers)
    local history = KWR.AAR:GetHistory()
    local insights = KWR.AAR:GetInsights()
    local latest = history[#history]
    local topMapDefinition = KWR.Maps:Get(insights.topMap)
    local topMapLabel = topMapDefinition and (topMapDefinition.title or topMapDefinition.name)
        or insights.topMap
    page.summaryCard.value:SetText(string.format(
        "%d MATCHES   |   %d%% WIN RATE   |   %d REVIEWED",
        insights.matches, insights.winRate, insights.reviewed))
    page.summaryCard.detail:SetText(
        "Every match strengthens the command record. Feedback remains local in your SavedVariables.")
    page.summaryCard.matchesBadge:SetTone("blue")
    page.summaryCard.matchesBadge:SetText(tostring(insights.matches) .. " MATCHES")
    page.summaryCard.reviewBadge:SetTone(insights.reviewed > 0 and "green" or "yellow")
    page.summaryCard.reviewBadge:SetText(tostring(insights.reviewed) .. " REVIEWED")
    page.summaryCard.latestBadge:SetTone(latest and helpers.statusColor(latest.result) or "muted")
    page.summaryCard.latestBadge:SetText(latest and KWR.Util:Text(latest.result, "LATEST", 10) or "NO MATCH")
    for index, row in ipairs(page.historyCard.rows) do
        local entry = history[#history - index + 1]
        row:SetShown(entry ~= nil)
        if entry then
            local dateText = type(date) == "function"
                and date("%m/%d %H:%M", entry.startedAt)
                or tostring(entry.startedAt)
            row.date:SetText(dateText)
            row.map:SetText(entry.mapName or entry.mapKey)
            row.result:SetText(entry.result or "UNKNOWN")
            row.result:SetTextColor(KWR.Theme:Color(helpers.statusColor(entry.result)))
            row.score:SetText(string.format("%d - %d",
                entry.scoreEnd and entry.scoreEnd.friendly or 0,
                entry.scoreEnd and entry.scoreEnd.enemy or 0))
            local reviewed = entry.feedback and next(entry.feedback)
            local session = aarSessionShort(entry)
            row.review:SetText(reviewed and ("DONE" .. (session ~= "" and (" " .. session) or ""))
                or "OPEN")
            row.command:SetText(entry.finalCommand
                and KWR.Util:Text(entry.finalCommand.action, "", 34) or "--")
        end
    end
    page.historyCard.note:SetText(string.format("Showing latest %d of %d matches",
        math.min(#page.historyCard.rows, #history), #history))
    page.insightCard.value:SetText(table.concat({
        "MATCHES RECORDED        " .. tostring(insights.matches),
        "VICTORIES               " .. tostring(insights.wins),
        "DEFEATS                 " .. tostring(insights.losses),
        "REVIEW COMPLETION       " .. tostring(insights.reviewed),
        "COMMANDER REVIEWS       " .. tostring(insights.commander or 0),
        "SPECTATOR REVIEWS       " .. tostring(insights.spectator or 0),
        "DIAGNOSTIC REVIEWS      " .. tostring(insights.diagnostic or 0),
        "MOST PLAYED MAP         " .. tostring(topMapLabel),
        "",
        "Learning is evidence-based:",
        "match result, score, command transitions,",
        "battleground events, and your review.",
        "",
        "RBG meta snapshot: " .. KWR.MetaSnapshot.captured,
        "Patch " .. KWR.MetaSnapshot.patch .. " | " .. tostring(KWR.MetaSnapshot:Count()) .. " specs",
        "",
        insights.matches == 0 and "Complete a battleground to begin."
            or "Keep reviewing matches to build reliable trends.",
    }, "\n"))
    local doctrine = KWR.Doctrine:Get(state.snapshot.context.mapKey)
    page.doctrineCard.value:SetText("WHEN WINNING  " .. doctrine.win
        .. "\n\nWHEN TIED  " .. doctrine.even
        .. "\n\nWHEN LOSING  " .. doctrine.lose
        .. "\n\nDO NOT  " .. doctrine.stop)
    page.reviewCard.value:SetText(latest and ("Latest match: " .. latest.mapName .. "  |  " .. latest.result
        .. "\nContext: " .. aarSessionLabel(latest)
        .. "\nReview the swing, save the lesson, and export evidence if needed."
        .. "\n"
        .. (latest.feedback and next(latest.feedback)
            and "Manual review complete." or "Manual review still open."))
        or "No completed match is available yet.")
    page.reviewCard.resultBadge:SetTone(latest and helpers.statusColor(latest.result) or "muted")
    page.reviewCard.resultBadge:SetText(latest and KWR.Util:Text(latest.result, "NO MATCH", 10) or "NO MATCH")
    page.reviewCard.reviewBadge:SetTone(latest and helpers.aarReviewTone(latest) or "muted")
    page.reviewCard.reviewBadge:SetText(latest
        and ((latest.feedback and next(latest.feedback)) and "REVIEW DONE" or "REVIEW OPEN")
        or "REVIEW")
    page.reviewCard.exportBadge:SetTone(latest and "gold" or "muted")
    page.reviewCard.exportBadge:SetText(latest and "EXPORT READY" or "EXPORT")
    page.reviewCard.open:SetShown(latest ~= nil)
    page.reviewCard.export:SetShown(latest ~= nil)
end
