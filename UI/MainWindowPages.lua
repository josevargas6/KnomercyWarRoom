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
    return tier ~= "" and (tier .. " " .. name) or name
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
        page.callerCard.value:SetText("Ta…7987 tokens truncated…ty or 0] or "OBSERVE"
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