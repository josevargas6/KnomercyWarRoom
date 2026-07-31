local _, KWR = ...

local MainWindow = {
    pages = {},
    tabs = {},
}
KWR.MainWindow = MainWindow

local PAGE_ORDER = {
    { key = "TACTICAL", label = "TACTICAL MAP" },
    { key = "OBJECTIVES", label = "OBJECTIVES" },
    { key = "TEAM", label = "TEAM" },
    { key = "ENEMIES", label = "ENEMIES" },
    { key = "ASSIGNMENTS", label = "ASSIGNMENTS" },
    { key = "INTEL", label = "REVIEW / AAR" },
}

local LIST_ROW_INSET = 8
local TEAM_COLUMNS = {
    { key = "player", label = "PLAYER", x = 34, width = 230 },
    { key = "spec", label = "SPEC", x = 274, width = 180 },
    { key = "role", label = "ROLE", x = 464, width = 90 },
    { key = "health", label = "HEALTH", x = 564, width = 150 },
    { key = "life", label = "STATE", x = 724, width = 90 },
    { key = "position", label = "ASSIGNMENT", x = 824, width = 360 },
}

local function previewAvailable()
    return KWR.BuildInfo and KWR.BuildInfo:HasPreview()
end

local function diagnosticsAvailable()
    return KWR.BuildInfo and KWR.BuildInfo:HasDiagnostics()
end

local function createPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page:Hide()
    return page
end

local function placeCard(parent, title, x, y, width, height)
    local card = KWR.Theme:Card(parent, title)
    card:SetPoint("TOPLEFT", x, y)
    card:SetSize(width, height)
    return card
end

local function addValue(card, color, size, top, justify)
    local value = KWR.Theme:Font(card, size or 11, color or "white", justify or "LEFT")
    value:SetPoint("TOPLEFT", 10, top or -36)
    value:SetPoint("BOTTOMRIGHT", -10, 8)
    return value
end

local function configureWrappedBlock(font, maxLines)
    if not font then return end
    font:SetJustifyV("TOP")
    if font.SetWordWrap then font:SetWordWrap(true) end
    if font.SetNonSpaceWrap then font:SetNonSpaceWrap(true) end
    if maxLines and font.SetMaxLines then
        font:SetMaxLines(maxLines)
    end
end

local function configureCardHeader(card, title, badges, options)
    options = options or {}
    local top = options.top or -8
    local right = options.right or 10
    local gap = options.gap or 8
    local dividerY = options.dividerY or -30
    if title then
        card.heading:SetText(string.upper(title))
    end
    if badges and #badges > 0 then
        local totalWidth = 0
        for _, badge in ipairs(badges) do
            totalWidth = totalWidth + (badge:GetWidth() or 0)
        end
        totalWidth = totalWidth + (math.max(0, #badges - 1) * gap)
        local anchor
        for index = #badges, 1, -1 do
            local badge = badges[index]
            badge:ClearAllPoints()
            if not anchor then
                badge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -right, top)
            else
                badge:SetPoint("RIGHT", anchor, "LEFT", -gap, 0)
            end
            anchor = badge
        end
        card.heading:ClearAllPoints()
        card.heading:SetPoint("TOPLEFT", 10, top)
        card.heading:SetPoint("TOPRIGHT", -(totalWidth + right + gap + 6), top)
    else
        card.heading:ClearAllPoints()
        card.heading:SetPoint("TOPLEFT", 10, top)
        card.heading:SetPoint("TOPRIGHT", -10, top)
    end
    card.heading:SetHeight(16)
    card.divider:ClearAllPoints()
    card.divider:SetPoint("TOPLEFT", 8, dividerY)
    card.divider:SetPoint("TOPRIGHT", -8, dividerY)
    card.divider:SetHeight(1)
end

local function roleText(role)
    role = KWR.Util:Text(role, "UNKNOWN", 18)
    if role == "DAMAGER" or role == "DPS" then
        return "DAMAGE"
    end
    return role
end

local function noDataText(value, fallback)
    if value == nil or value == "" or value == "--" then
        return fallback or "NO DATA"
    end
    return tostring(value)
end

local function hasLiveScore(context)
    return context and context.inPvP == true
end

local function classColor(classFile)
    local color = type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[classFile]
    if color then return color.r or 0.75, color.g or 0.75, color.b or 0.75 end
    return KWR.Theme:Color("soft")
end

local function healthColor(percent)
    if not percent then return KWR.Theme:Color("dim") end
    if percent <= 35 then return KWR.Theme:Color("red") end
    if percent <= 70 then return KWR.Theme:Color("orange") end
    return KWR.Theme:Color("green")
end

local function specLabel(entity)
    return KWR.RosterPresentation:SpecLabel(entity)
end

local function applyDirectHealth(statusBar, unit, healthText)
    if not unit or unit == "" or type(UnitExists) ~= "function"
        or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false) then return false end
    if type(UnitHealth) == "function" and type(UnitHealthMax) == "function" then
        local ok = pcall(function()
            local health = UnitHealth(unit)
            local healthMax = UnitHealthMax(unit)
            statusBar:SetMinMaxValues(0, healthMax)
            statusBar:SetValue(health)
            if healthText then
                if healthMax and healthMax > 0 then
                    healthText:SetText(tostring(math.floor(((health / healthMax) * 100) + 0.5)) .. "%")
                elseif type(AbbreviateNumbers) == "function" then
                    healthText:SetText(AbbreviateNumbers(health))
                else
                    healthText:SetText("LIVE")
                end
            end
        end)
        if ok then return true end
    end
    if type(UnitHealthPercent) ~= "function" or not CurveConstants
        or not CurveConstants.ScaleTo100 then return false end
    local ok = pcall(function()
        statusBar:SetValue(UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
    end)
    return ok
end

local function statusColor(status)
    return KWR.CommandView:StatusColor(status)
end

local function commandBadgeState(state)
    return KWR.CommandView:BadgeState(state)
end

local function compactCommandText(state)
    return KWR.CommandView:CompactCommandText(state)
end

local function updateToken(owner, state)
    local allowed = KWR.Util:AllowsCommandSurfaces(state)
    local arena = KWR.Util:IsArenaContext(state)
    local launcherShown = owner.launcher and owner.launcher:IsShown() or false
    local frameShown = owner.frame and owner.frame:IsShown() or false
    if not frameShown then
        return KWR.Util:Signature({ allowed, arena, launcherShown })
    end
    local snapshot = state and state.snapshot or {}
    local context = snapshot.context or {}
    local parts = {
        true,
        owner.activePage or "TACTICAL",
        context.sessionKey,
        context.mapKey,
        context.inPvP,
        context.preview,
        context.matchComplete,
        snapshot.score and snapshot.score.friendly,
        snapshot.score and snapshot.score.enemy,
        state and state.command and state.command.signature,
        state and state.prediction and state.prediction.status,
    }
    if owner.activePage == "TEAM" then
        for _, player in ipairs(snapshot.roster or {}) do
            parts[#parts + 1] = KWR.Util:Signature({
                player.key, player.guid, player.name, player.unit,
                player.classFile, player.role, player.spec,
                player.specSource, player.healthPercent,
                player.lastHealthPercent, player.dead,
                player.connected, player.location,
                player.carrier, player.carrierStacks,
            })
        end
        for _, assignment in ipairs(
            state and state.assignments or {}) do
            parts[#parts + 1] = KWR.Util:Signature({
                assignment.key, assignment.name,
                assignment.role, assignment.shortRole,
                assignment.location, assignment.display,
                assignment.movement, assignment.target,
            })
        end
        local formation = snapshot.formation or {}
        parts[#parts + 1] = KWR.Util:Signature({
            formation.targetSize, formation.openSlots,
            formation.replacementsNeeded,
            formation.needs and formation.needs.TANK,
            formation.needs and formation.needs.HEALER,
            formation.needs and formation.needs.DAMAGER,
            formation.archetype and formation.archetype.name,
            formation.currentComp and formation.currentComp.id,
            formation.tierMatch and formation.tierMatch.id,
            formation.buildTarget and formation.buildTarget.id,
            formation.buildTarget and formation.buildTarget.name,
            formation.buildTarget and formation.buildTarget.assignments,
        })
        for _, recommendation in ipairs(
            formation.recommendations or {}) do
            parts[#parts + 1] = KWR.Util:Signature({
                recommendation.label,
                recommendation.role,
                recommendation.acquisition,
            })
        end
        for _, requirement in ipairs(
            formation.buildRequirements or {}) do
            parts[#parts + 1] = KWR.Util:Signature({
                requirement.label,
                requirement.role,
            })
        end
    elseif owner.activePage == "ENEMIES" then
        for _, enemy in ipairs(snapshot.enemies or {}) do
            parts[#parts + 1] = KWR.Util:Signature({
                enemy.key, enemy.guid, enemy.name, enemy.unit,
                enemy.classFile, enemy.role, enemy.spec,
                enemy.specSource, enemy.healthPercent,
                enemy.lastHealthPercent, enemy.dead,
                enemy.visible, enemy.localRange,
                enemy.localEngaged,
                enemy.age and math.floor(enemy.age / 2),
                enemy.locationState, enemy.location,
                enemy.locationSource, enemy.priority,
                enemy.engagementRole,
                enemy.locationInferred,
                enemy.carrier, enemy.carrierStacks,
                enemy.trinketState, enemy.cooldownText,
                enemy.note, enemy.noteTagSummary,
                enemy.priorityCast and enemy.priorityCast.spellID,
                enemy.priorityCast and enemy.priorityCast.name,
                enemy.priorityCast and enemy.priorityCast.response,
                enemy.defensivesActive
                    and enemy.defensivesActive[1]
                    and enemy.defensivesActive[1].spellID,
                enemy.defensivesActive
                    and enemy.defensivesActive[1]
                    and enemy.defensivesActive[1].name,
                enemy.defensivesActive
                    and enemy.defensivesActive[1]
                    and enemy.defensivesActive[1].response,
                enemy.profile and enemy.profile.label,
                enemy.profile and enemy.profile.score,
                enemy.profile and enemy.profile.commanderTakeaway,
            })
        end
        local combat = snapshot.combat or {}
        parts[#parts + 1] = combat.localTarget
            and (combat.localTarget.key
                or combat.localTarget.name)
    else
        parts[#parts + 1] = state and state.revision or 0
    end
    return KWR.Util:Signature(parts)
end

local function assignmentPriority(priority)
    priority = KWR.Util:Number(priority, 0) or 0
    if priority >= 95 then return "PRIMARY" end
    if priority >= 85 then return "HIGH" end
    if priority >= 70 then return "SUPPORT" end
    return "SETUP"
end

local function weightedFocusText(strategy)
    local rows = {}
    for category, weight in pairs(strategy and strategy.weightedFocus or {}) do
        rows[#rows + 1] = { category = category, weight = weight }
    end
    table.sort(rows, function(a, b)
        if a.weight ~= b.weight then return a.weight > b.weight end
        return a.category < b.category
    end)
    local parts = {}
    for index = 1, math.min(3, #rows) do
        parts[#parts + 1] = rows[index].category
    end
    return #parts > 0 and table.concat(parts, " + ") or "baseline"
end

local function truthLabel(source)
    source = KWR.Util:Text(source, "none", 24)
    if source == "preview" then return "PREVIEW" end
    if source == "ui_widget" then return "LIVE" end
    if source == "bg_system" or source == "carrier" or source == "battlefield_flag" then
        return "OBSERVED"
    end
    if source == "area_poi" then return "MAP" end
    return "UNKNOWN"
end

local function objectiveStateText(objective)
    local timerRemaining = KWR.Util:Number(objective and objective.timerRemaining, nil)
    if objective and objective.pendingState == "INCOMING" and timerRemaining and timerRemaining > 0 then
        if objective.state == "INCOMING" then
            return "INCOMING " .. KWR.Util:Clock(timerRemaining)
        end
        return "CONTEST " .. KWR.Util:Clock(timerRemaining)
    end
    return KWR.Util:Text(objective and objective.state, "WATCH", 12)
end

local function reporterFooterText(reporter, mapKey)
    reporter = reporter or {}
    local coverage = reporter.coverage or {}
    local intent = reporter.enemyIntent or {}
    local hotspot = reporter.hotspot
    local parts = {
        string.format("%d SEEN / %d RECENT / %d LAST SEEN",
            coverage.enemyVisible or 0,
            (coverage.enemyVisible or 0) + (coverage.enemyRecent or 0),
            coverage.enemyStale or 0),
    }
    if intent.target and intent.target ~= "" then
        parts[#parts + 1] = "INC "
            .. KWR.Maps:AbbreviateLocation(mapKey, intent.target)
            .. (intent.eta and (" " .. KWR.Util:Clock(intent.eta)) or "")
    elseif hotspot and (hotspot.key or hotspot.label) then
        parts[#parts + 1] = "HOT "
            .. KWR.Maps:AbbreviateLocation(mapKey, hotspot.key or hotspot.label)
    end
    return table.concat(parts, "  |  ")
end

local function nextMoveText(state)
    return KWR.CommandView:NextMoveText(state,
        "Hold your lane. Check again on the next swing.")
end

local function selfAssignment(state)
    local teamfight = state and state.snapshot and state.snapshot.teamfight
    if teamfight and teamfight.displayEligible == true then
        local playerName = KWR.Util:UnitName("player")
        local shortName = playerName and KWR.Util:ShortName(playerName)
        for _, assignment in ipairs(teamfight.assignments or {}) do
            if assignment.name == playerName or assignment.shortName == shortName
                or assignment.actor == playerName or assignment.actor == shortName then
                return assignment
            end
        end
        return teamfight.assignments and teamfight.assignments[1]
    end
    local playerName = KWR.Util:UnitName("player")
    local shortName = playerName and KWR.Util:ShortName(playerName)
    for _, assignment in ipairs(state.assignments or {}) do
        if assignment.name == playerName or assignment.shortName == shortName then return assignment end
    end
    return state.assignments and state.assignments[1]
end

local function primaryEnemy(state)
    local plan = state and state.snapshot and state.snapshot.teamfight
    if plan and plan.displayEligible == true then
        local targetGUID = plan.killTarget and plan.killTarget.targetGUID
            or (plan.assignments and plan.assignments[1] and plan.assignments[1].targetGUID)
        local targetName = plan.killTarget and plan.killTarget.target
            or (plan.assignments and plan.assignments[1] and plan.assignments[1].target)
        for _, enemy in ipairs(state.snapshot.enemies or {}) do
            if (targetGUID and enemy.guid == targetGUID)
                or (targetName and KWR.Util:ShortName(enemy.name) == targetName) then
                return enemy
            end
        end
    end
    return state.snapshot.combat and (state.snapshot.combat.localTarget
        or state.snapshot.combat.killTarget)
        or (state.snapshot.enemies and state.snapshot.enemies[1])
end

local function activeCombatTarget(combat)
    if type(combat) ~= "table" then return nil end
    return combat.localTarget or combat.killTarget
end

local function profileBadge(profile)
    local label = profile and KWR.Util:Text(profile.label, "NONE", 12) or "NONE"
    if label == "HIGH" then return "KNOWN" end
    if label == "MEDIUM" then return "SEEN" end
    if label == "LOW" then return "LIGHT" end
    return "NEW"
end

local function noteButtonText(enemy)
    local hasNote = enemy and enemy.note and enemy.note ~= ""
    local hasTags = enemy and enemy.noteTagSummary and enemy.noteTagSummary ~= "No tags"
    local label = hasNote and "NOTE"
        or (hasTags and "TAG" or "ADD")
    return label .. " [" .. profileBadge(enemy and enemy.profile) .. "]"
end

local function trustTone(profile)
    local label = profile and KWR.Util:Text(profile.label, "NONE", 12) or "NONE"
    if label == "HIGH" then return "green" end
    if label == "MEDIUM" then return "yellow" end
    if label == "LOW" then return "orange" end
    return "muted"
end

local function enemySeenTone(enemy)
    if not enemy or not enemy.age then return "muted" end
    if enemy.age < 10 then return "green" end
    if enemy.age < 30 then return "yellow" end
    return "orange"
end

local function enemyTrackerSummary(enemies)
    local direct, recent, stale, notes = 0, 0, 0, 0
    for _, enemy in ipairs(enemies or {}) do
        if enemy.note and enemy.note ~= "" then notes = notes + 1 end
        if enemy.visible == true then
            direct = direct + 1
        elseif enemy.age and enemy.age <= 30 then
            recent = recent + 1
        else
            stale = stale + 1
        end
    end
    return string.format("SEEN %d  |  RECENT %d  |  LAST SEEN %d  |  NOTES %d",
        direct, recent, stale, notes)
end

local function aarReviewTone(entry)
    if not entry then return "muted" end
    if entry.feedback and next(entry.feedback) then return "green" end
    return "yellow"
end

local function urgencyTone(value)
    value = KWR.Util:Number(value, 0) or 0
    if value >= 85 then return "red" end
    if value >= 60 then return "yellow" end
    return "green"
end

local function readinessTone(dead, openSlots)
    if (dead or 0) > 0 then return "orange" end
    if (openSlots or 0) > 0 then return "yellow" end
    return "green"
end

local function profileSummaryText(profile)
    if not profile or profile.label == "NONE" then
        return "PLAYER PROFILE: NEW\nNo reliable pattern recorded yet."
    end
    local traits = profile.traitSummary and profile.traitSummary ~= ""
        and profile.traitSummary or "No learned trait yet."
    local strengths = profile.strengths and #profile.strengths > 0
        and table.concat(profile.strengths, "; ")
        or "No repeated strength pattern logged."
    local weaknesses = profile.weaknesses and #profile.weaknesses > 0
        and table.concat(profile.weaknesses, "; ")
        or "No repeated weakness pattern logged."
    local routes = {}
    for _, row in ipairs(profile.topLocations or {}) do
        routes[#routes + 1] = row.key .. " x" .. tostring(row.count)
    end
    return table.concat({
        "PLAYER PROFILE: " .. KWR.Util:Text(profile.label, "NONE", 12)
            .. " (" .. tostring(profile.score or 0) .. ")",
        "SAMPLES: " .. tostring(profile.sessions or 0)
            .. " | GAMES: " .. tostring(profile.matches or 0),
        #routes > 0 and ("COMMON ROUTES: " .. table.concat(routes, ", "))
            or "COMMON ROUTES: none logged.",
        "TRAITS: " .. traits,
        "STRENGTHS: " .. strengths,
        "WEAKNESSES: " .. weaknesses,
        "TAKEAWAY: " .. KWR.Util:Text(profile.commanderTakeaway, "Advisory only.", 120),
        "NOTES: " .. KWR.Util:Text(profile.reason, "No profile.", 180),
    }, "\n")
end

local function updateEnemyNoteTags(frame, key)
    if not frame or not key or not KWR.EnemyIntel then return end
    local tags = KWR.EnemyIntel:NoteTags(key)
    for _, button in ipairs(frame.tagButtons or {}) do
        button:SetSelected(tags[button.tagID] == true)
    end
    if frame.tagSummary then
        frame…10024 tokens truncated…:Font(review, 10, "soft")
    review.value:SetPoint("TOPLEFT", 12, -44)
    review.value:SetPoint("TOPRIGHT", -12, -44)
    review.value:SetHeight(84)
    review.open = KWR.Theme:Button(review, "OPEN REVIEW", 128, 27, function()
        local latest = KWR.AAR:GetHistory()[#KWR.AAR:GetHistory()]
        if latest then KWR.AARWindow:Show(latest.id) end
    end)
    review.open:SetPoint("BOTTOMLEFT", 50, 16)
    review.export = KWR.Theme:Button(review, "COPY EXPORT", 128, 27, function()
        MainWindow:ShowAARExport()
    end)
    review.export:SetPoint("BOTTOMRIGHT", -50, 16)

    page.summaryCard, page.historyCard = summary, history
    page.insightCard, page.doctrineCard, page.reviewCard = insights, doctrine, review
end

function MainWindow:CreateEnemyNoteEditor()
    if self.noteEditor then return end
    local frame = CreateFrame("Frame", "KWR_EnemyNoteEditor", UIParent, "BackdropTemplate")
    frame:SetSize(540, 430)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    frame:Hide()
    frame.title = KWR.Theme:Title(frame, 15)
    frame.title:SetPoint("TOPLEFT", 14, -12)
    frame.title:SetText("ENEMY FIELD NOTE")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    frame.edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.edit:SetPoint("TOPLEFT", 14, -48)
    frame.edit:SetSize(512, 70)
    frame.edit:SetMultiLine(true)
    frame.edit:SetAutoFocus(false)
    frame.noteLabel = KWR.Theme:SectionLabel(frame, "MANUAL NOTE", 16, -36, 180)
    frame.help = KWR.Theme:Font(frame, 9, "muted")
    frame.help:SetPoint("TOPLEFT", 16, -122)
    frame.help:SetPoint("TOPRIGHT", -16, -122)
    frame.help:SetHeight(24)
    frame.help:SetText("Persisted locally. No note is transmitted automatically.")
    frame.truthBadge = KWR.Theme:Badge(frame, "muted", "UNKNOWN", 92, 16)
    frame.truthBadge:SetPoint("TOPLEFT", 16, -148)
    frame.trustBadge = KWR.Theme:Badge(frame, "muted", "NO MODEL", 104, 16)
    frame.trustBadge:SetPoint("LEFT", frame.truthBadge, "RIGHT", 8, 0)
    frame.takeawayLabel = KWR.Theme:SectionLabel(frame, "COMMANDER TAKEAWAY", 16, -168, 220)
    frame.takeaway = KWR.Theme:Font(frame, 10, "white")
    frame.takeaway:SetPoint("TOPLEFT", 16, -190)
    frame.takeaway:SetPoint("TOPRIGHT", -16, -190)
    frame.takeaway:SetHeight(34)
    frame.tagLabel = KWR.Theme:SectionLabel(frame, "NOTE TAGS", 16, -226, 140)
    frame.tagSummary = KWR.Theme:Font(frame, 8, "muted")
    frame.tagSummary:SetPoint("TOPRIGHT", -16, -228)
    frame.tagSummary:SetWidth(280)
    frame.tagSummary:SetHeight(14)
    frame.tagSummary:SetJustifyH("RIGHT")
    frame.tagButtons = {}
    for index, tag in ipairs(KWR.EnemyIntel.noteTags or {}) do
        local tagID, tagLabel = tag.id, tag.label
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        local button = KWR.Theme:Button(frame, tagLabel, 156, 24, function()
            if not frame.enemyKey then return end
            KWR.EnemyIntel:SetNote(frame.enemyKey, frame.edit:GetText())
            KWR.EnemyIntel:ToggleNoteTag(frame.enemyKey, tagID)
            updateEnemyNoteTags(frame, frame.enemyKey)
            if KWR.MatchRuntime then KWR.MatchRuntime:ForceRefresh("enemy-note-tag") end
        end)
        button.tagID = tagID
        button:SetPoint("TOPLEFT", 16 + (column * 170), -250 - (row * 30))
        frame.tagButtons[#frame.tagButtons + 1] = button
    end
    frame.modelLabel = KWR.Theme:SectionLabel(frame, "LEARNED PROFILE", 16, -314, 180)
    frame.profile = KWR.Theme:Font(frame, 9, "soft")
    frame.profile:SetPoint("TOPLEFT", 16, -336)
    frame.profile:SetPoint("TOPRIGHT", -16, -336)
    frame.profile:SetHeight(66)
    local save = KWR.Theme:Button(frame, "SAVE NOTE", 108, 26, function()
        if frame.enemyKey then
            KWR.EnemyIntel:SetNote(frame.enemyKey, frame.edit:GetText())
            KWR.MatchRuntime:ForceRefresh("enemy-note")
        end
        frame:Hide()
    end)
    save:SetPoint("BOTTOMRIGHT", -14, 12)
    self.noteEditor = frame
end

function MainWindow:ShowEnemyNote(key)
    self:CreateEnemyNoteEditor()
    local enemy
    for _, row in ipairs(KWR.Store:Get().snapshot.enemies or {}) do
        if row.key == key then enemy = row break end
    end
    if not enemy then return end
    local profile = enemy.profile or (KWR.OpponentModels
        and KWR.OpponentModels:Describe(enemy)) or nil
    self.noteEditor.enemyKey = key
    self.noteEditor.title:SetText("ENEMY FIELD NOTE  |  " .. enemy.shortName)
    self.noteEditor.edit:SetText(enemy.note or "")
    self.noteEditor.truthBadge:SetTone(enemySeenTone(enemy))
    self.noteEditor.truthBadge:SetText(enemy.age and ("SEEN " .. KWR.Util:Age(enemy.age)) or "ROSTER")
    self.noteEditor.trustBadge:SetTone(trustTone(profile))
    self.noteEditor.trustBadge:SetText(profileBadge(profile))
    self.noteEditor.help:SetText("Persisted locally. "
        .. KWR.EnemyIntel:DescribeLocation(enemy, KWR.Store:Get().snapshot.context.mapKey, true))
    self.noteEditor.takeaway:SetText(KWR.Util:Text(profile and profile.commanderTakeaway,
        "Takeaway: profile is thin; use as advisory only.", 160))
    self.noteEditor.profile:SetText(profileSummaryText(profile))
    updateEnemyNoteTags(self.noteEditor, key)
    self.noteEditor:Show()
end

function MainWindow:SetPage(key)
    if not self.pages[key] then key = "TACTICAL" end
    if not self:EnsurePageBuilt(key) then
        KWR:Print(
            "That Command Center page will finish loading when combat ends.",
            true)
        return false
    end
    for pageKey, page in pairs(self.pages) do
        page:SetShown(pageKey == key)
        local tab = self.tabs[pageKey]
        if tab then
            if tab.SetSelected then
                tab:SetSelected(pageKey == key)
            else
                KWR.Theme:Style(tab, pageKey == key and "raised" or "card",
                    pageKey == key and "borderHi" or "border")
                tab.label:SetTextColor(KWR.Theme:Color(pageKey == key and "gold" or "soft"))
            end
        end
    end
    KWR.db.profile.main.page = key
    self.activePage = key
    self:Update(KWR.Store:Get())
    return true
end

function MainWindow:UpdateTactical(state)
    KWR.MainWindowPages:RenderTactical(self.pages.TACTICAL, state, {
        statusColor = statusColor,
        selfAssignment = selfAssignment,
        primaryEnemy = primaryEnemy,
        reporterFooterText = reporterFooterText,
        nextMoveText = nextMoveText,
    })
    local page = self.pages.TACTICAL
    if page and page.altButton then
        page.altButton:SetText(state.snapshot.context.inPvP and "ALTS" or "MENU")
    end
end

function MainWindow:Explain()
    local title, text = KWR.MainWindowReports:BuildExplainPayload(KWR.Store:Get(), {
        weightedFocusText = weightedFocusText,
    })
    KWR.CopyDialog:ShowText(title, text, {
        note = "Explanation is a local review tool. Scroll to inspect details and copy manually if needed.",
    })
end

function MainWindow:ShowAlternatives()
    local state = KWR.Store:Get()
    local title, text = KWR.MainWindowReports:BuildAlternativesPayload(state)
    KWR.CopyDialog:ShowText(title, text, {
        note = "Alternate plans stay local. Review them, then choose the call you want to make.",
    })
end

function MainWindow:ShowPerformance()
    local title, text = KWR.MainWindowReports:BuildPerformancePayload(KWR.Store:Get())
    KWR.CopyDialog:ShowText(title, text, {
        note = "Performance telemetry is local to this client and current session.",
    })
end

function MainWindow:UpdateObjectives(state)
    KWR.MainWindowPages:RenderObjectives(self.pages.OBJECTIVES, state, {
        statusColor = statusColor,
        truthLabel = truthLabel,
        hasLiveScore = hasLiveScore,
        noDataText = noDataText,
        objectiveStateText = objectiveStateText,
        urgencyTone = urgencyTone,
        objectiveCounts = objectiveCounts,
    })
end

function MainWindow:UpdateTeam(state)
    KWR.MainWindowPages:RenderTeam(self.pages.TEAM, state, {
        readinessTone = readinessTone,
        setClassIcon = setClassIcon,
        classColor = classColor,
        specLabel = specLabel,
        roleText = roleText,
        healthColor = healthColor,
        applyDirectHealth = applyDirectHealth,
    })
end

function MainWindow:UpdateHealthForUnit(unit)
    if not unit or unit == "" then return false end
    local matched = false
    for _, pageKey in ipairs({ "TEAM", "ENEMIES" }) do
        local page = self.pages[pageKey]
        local card
        if page then
            if pageKey == "TEAM" then
                card = page.rosterCard
            else
                card = page.trackerCard
            end
        end
        for _, row in ipairs(card and card.rows or {}) do
            if row.displayUnit == unit then
                if applyDirectHealth(
                    row.health, unit, row.healthText) then
                    matched = true
                end
            end
        end
    end
    return matched
end

function MainWindow:UpdateEnemies(state)
    KWR.MainWindowPages:RenderEnemies(self.pages.ENEMIES, state, {
        enemyTrackerSummary = enemyTrackerSummary,
        enemySeenTone = enemySeenTone,
        setClassIcon = setClassIcon,
        classColor = classColor,
        specLabel = specLabel,
        applyDirectHealth = applyDirectHealth,
        noteButtonText = noteButtonText,
        trustTone = trustTone,
        activeCombatTarget = activeCombatTarget,
    })
end

function MainWindow:UpdateAssignments(state)
    KWR.MainWindowPages:RenderAssignments(self.pages.ASSIGNMENTS, state, {
        statusColor = statusColor,
        classColor = classColor,
        roleText = roleText,
        assignmentPriority = assignmentPriority,
        selfAssignment = selfAssignment,
        weightedFocusText = weightedFocusText,
    })
end

function MainWindow:UpdateIntel(state)
    KWR.MainWindowPages:RenderIntel(self.pages.INTEL, state, {
        statusColor = statusColor,
        aarReviewTone = aarReviewTone,
    })
end

function MainWindow:Update(state)
    self.lastState = state
    local allowed = KWR.Util:AllowsCommandSurfaces(state)
    local arenaSuppressed = KWR.Util:IsArenaContext(state)
    if self.launcher then self.launcher:SetShown(allowed and not arenaSuppressed) end
    if self.launcher then self:UpdateLauncherVisual(state) end
    if not allowed or arenaSuppressed then
        if self.launcherMenu then self.launcherMenu:Hide() end
        if self.frame and self.frame:IsShown() then
            if InCombatLockdown and InCombatLockdown() then
                self.pendingVisibility = { shown = false }
            else
                self.frame:Hide()
            end
        end
        return
    end
    if not self.frame then return end
    if not self.frame:IsShown() then return end
    local context = state.snapshot.context
    KWR.MainWindowShell:UpdateHeader(self.frame, state, {
        commandBadgeState = commandBadgeState,
        truthLabel = truthLabel,
    })
    if self.activePage == "TACTICAL" then self:UpdateTactical(state)
    elseif self.activePage == "OBJECTIVES" then self:UpdateObjectives(state)
    elseif self.activePage == "TEAM" then self:UpdateTeam(state)
    elseif self.activePage == "ENEMIES" then self:UpdateEnemies(state)
    elseif self.activePage == "ASSIGNMENTS" then self:UpdateAssignments(state)
    elseif self.activePage == "INTEL" then self:UpdateIntel(state)
    end
end

function MainWindow:Show(page)
    local state = self.lastState or KWR.Store:Get()
    if not KWR.Util:AllowsCommandSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        if self.frame and self.frame:IsShown() then
            if InCombatLockdown and InCombatLockdown() then
                self.pendingVisibility = { shown = false }
            else
                self.frame:Hide()
            end
        end
        if self.launcher then self.launcher:Hide() end
        if self.launcherMenu then self.launcherMenu:Hide() end
        return false
    end
    if (not self.frame) and InCombatLockdown and InCombatLockdown() then
        self.pendingVisibility = { shown = true, page = page }
        KWR:Print("War Room will open when combat ends; secure controls are created out of combat.", true)
        return
    end
    local createdFrame = self.frame == nil
    self:Create(page)
    if InCombatLockdown and InCombatLockdown() and not self.frame:IsShown() then
        self.pendingVisibility = { shown = true, page = page }
        KWR:Print("War Room will open when combat ends; secure controls cannot change visibility in combat.", true)
        return
    end
    self:SuppressCompactSurfaces()
    if page and not createdFrame then
        if InCombatLockdown and InCombatLockdown() then
            self.pendingPage = page
            KWR:Print(
                "That Command Center page will open when combat ends.",
                true)
        else
            self:SetPage(page)
        end
    end
    self.frame:Show()
    self:Update(KWR.Store:Get())
end

function MainWindow:SetFormationBuildTarget(compID)
    local state = self.lastState or KWR.Store:Get()
    if not state or not state.snapshot or not state.snapshot.context
        or state.snapshot.context.inPvP then
        return false
    end
    KWR.db.profile.formation.selectedCompID = compID or nil
    local ok = KWR.MatchRuntime:ForceRefresh("formation-build-target")
    local updated = KWR.Store:Get()
    if ok and updated and updated.snapshot and updated.snapshot.formation then
        self.lastState = updated
        if self.frame and self.frame:IsShown() then
            self:Update(updated)
        end
        local target = updated.snapshot.formation.buildTarget
        if compID and target then
            KWR:Print("Build target: " .. tostring(target.tier or "")
                .. " " .. tostring(target.name or ""), true)
        else
            KWR:Print("Build target returned to automatic selection.", true)
        end
    end
    return ok
end

function MainWindow:CycleFormationBuildTarget(step)
    local state = self.lastState or KWR.Store:Get()
    if not state or not state.snapshot or not state.snapshot.context
        or state.snapshot.context.inPvP then
        return false
    end
    local choices = KWR.Compositions:BuildTargets(state.snapshot.context.mapKey)
    if #choices == 0 then return false end
    local currentID = KWR.db.profile.formation.selectedCompID
        or (state.snapshot.formation and state.snapshot.formation.buildTarget
            and state.snapshot.formation.buildTarget.id)
    local currentIndex = 1
    for index, comp in ipairs(choices) do
        if comp.id == currentID then
            currentIndex = index
            break
        end
    end
    local nextIndex = currentIndex + (step or 1)
    if nextIndex < 1 then
        nextIndex = #choices
    elseif nextIndex > #choices then
        nextIndex = 1
    end
    return self:SetFormationBuildTarget(choices[nextIndex].id)
end

function MainWindow:SuppressCompactSurfaces()
    KWR.MainWindowShell:SuppressCompactSurfaces(self)
end

function MainWindow:RestoreCompactSurfaces()
    KWR.MainWindowShell:RestoreCompactSurfaces(self, self.lastState or KWR.Store:Get())
end

function MainWindow:Hide()
    if self.frame and InCombatLockdown and InCombatLockdown() then
        self.pendingVisibility = { shown = false }
        KWR:Print("War Room will close when combat ends; secure controls cannot change visibility in combat.", true)
        return
    end
    if self.frame then self.frame:Hide() else self:RestoreCompactSurfaces() end
end

function MainWindow:FlushCombatVisibility()
    if InCombatLockdown and InCombatLockdown() then return end
    local pendingPage = self.pendingPage
    self.pendingPage = nil
    local pending = self.pendingVisibility
    self.pendingVisibility = nil
    if pending then
        if pending.shown then self:Show(pending.page) else self:Hide() end
    elseif pendingPage and self.frame and self.frame:IsShown() then
        self:SetPage(pendingPage)
    elseif self.frame and self.frame:IsShown() and self.compactRestore
        and KWR.CombatRoster and KWR.CombatRoster:AnyShown() then
        KWR.CombatRoster:Request(false, nil, false)
    end
end

function MainWindow:MinimizeTo(surface, mode)
    KWR.MainWindowShell:ShowMinimizedSurface(
        self, surface, mode, self.lastState or KWR.Store:Get())
end

function MainWindow:Toggle(page)
    if self.frame and self.frame:IsShown() and not page then
        self:Hide()
    else
        self:Show(page)
    end
end

function MainWindow:PositionLauncher()
    KWR.MainWindowShell:PositionLauncher(self.launcher, KWR.db.profile.launcher)
end

function MainWindow:UpdateLauncherVisual(state)
    KWR.MainWindowShell:UpdateLauncherVisual(self.launcher, state or self.lastState or KWR.Store:Get())
end

function MainWindow:CreateLauncher()
    KWR.MainWindowLauncher:Create(self)
end

function MainWindow:CreateLauncherMenu()
    KWR.MainWindowLauncher:CreateMenu(self)
end

function MainWindow:ToggleLauncherMenu()
    KWR.MainWindowLauncher:ToggleMenu(self, {
        commandBadgeState = commandBadgeState,
        truthLabel = truthLabel,
    })
end

function MainWindow:TogglePreview()
    if not previewAvailable() then
        KWR.db.profile.preview = false
        KWR:Print("Preview is available only in the developer build.", true)
        return
    end
    local state = KWR.Store:Get()
    if state.snapshot.context.inPvP and not state.snapshot.context.preview then
        KWR:Print("Preview cannot replace live battleground data.", true)
        return
    end
    KWR.db.profile.preview = not KWR.db.profile.preview
    KWR.MatchRuntime:ForceRefresh("preview-toggle")
    self:Show("TACTICAL")
    KWR:Print(KWR.db.profile.preview and "Design preview enabled. Data is clearly marked NOT LIVE."
        or "Design preview disabled. Live battleground data restored.", true)
end

function MainWindow:ArmFieldTest()
    KWR.db.profile.preview = false
    KWR.db.profile.guidanceMode = "COMMAND"
    KWR.db.profile.aar.autoOpen = true
    KWR.db.profile.aar.enabled = true
    KWR.db.profile.hud.enabled = true
    KWR.db.profile.presentation.enabled = true
    KWR.db.profile.combatRoster.shown = true
    KWR.db.profile.combatRoster.mode = "BOTH"
    KWR.db.profile.combatRoster.teamShown = true
    KWR.db.profile.combatRoster.enemyShown = true
    KWR.HUD:SetEnabled(true)
    KWR.CombatRoster:Show("BOTH")
    if KWR.Presentation then KWR.Presentation:RefreshNow() end
    KWR.MatchRuntime:ForceRefresh("field-test-arm")
    KWR:Print("Field test armed: live HUD, team/enemy roster, automatic AAR, and command mode are active.", true)
    KWR:Print("Next: run /kwr verify now, /kwr perf during combat, and /kwr aar copy after the match.", true)
end

function MainWindow:ShowAARExport()
    local export, message = KWR.AAR:Export()
    if not export then
        KWR:Print(message or "No completed AAR export is available.", true)
        self:Show("INTEL")
        return
    end
    KWR.CopyDialog:ShowText("KWR Match Evidence Export", export, {
        note = "Evidence export stays local until you manually copy it from this window.",
    })
end

function MainWindow:RegisterCommands()
    KWR.MainWindowCommands:Register(self, {
        previewAvailable = previewAvailable,
        diagnosticsAvailable = diagnosticsAvailable,
        compactCommandText = compactCommandText,
    })
end

function MainWindow:OnInitialize()
    self:CreateLauncher()
    self:RegisterCommands()
    KWR.Store:SubscribeFiltered(self, self.Update, updateToken)
end

function MainWindow:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("MainWindow", MainWindow)