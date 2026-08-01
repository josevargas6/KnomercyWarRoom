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
        frame.tagSummary:SetText("Tags: " .. KWR.EnemyIntel:NoteTagSummary(key))
    end
end

local function objectiveCounts(snapshot)
    local objectives = snapshot.objectives or {}
    return objectives.friendly or 0, objectives.enemy or 0,
        objectives.friendlyIncoming or 0, objectives.enemyIncoming or 0
end

local function setRowBackground(row, index)
    KWR.Theme:Style(row, index % 2 == 0 and "panel" or "card", "panel")
end

local function setClassIcon(texture, classFile)
    texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local coords = type(CLASS_ICON_TCOORDS) == "table" and CLASS_ICON_TCOORDS[classFile]
    if coords then
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        texture:SetVertexColor(1, 1, 1, 1)
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertexColor(0.65, 0.65, 0.65, 1)
    end
end

local function createListRow(parent, index, y, width, height)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", 8, y)
    row:SetSize(width - 16, height)
    setRowBackground(row, index)
    return row
end

local function addColumnHeaders(parent, definitions, y)
    parent.headers = {}
    for _, definition in ipairs(definitions) do
        local header = KWR.Theme:Font(parent, definition.size or 8, "muted",
            definition.justify or "LEFT", "OUTLINE")
        header:SetPoint("TOPLEFT", definition.x, y or -36)
        header:SetWidth(definition.width)
        header:SetHeight(14)
        header:SetText(definition.label)
        parent.headers[#parent.headers + 1] = header
    end
end

function MainWindow:EnsurePageBuilt(key)
    local page = self.pages[key]
    if not page or page.built == true then
        return page
    end
    if InCombatLockdown and InCombatLockdown() then
        self.pendingPage = key
        return nil
    end
    if key == "TACTICAL" then
        self:BuildTacticalPage(page)
    elseif key == "OBJECTIVES" then
        self:BuildObjectivesPage(page)
    elseif key == "TEAM" then
        self:BuildTeamPage(page)
    elseif key == "ENEMIES" then
        self:BuildEnemiesPage(page)
    elseif key == "ASSIGNMENTS" then
        self:BuildAssignmentsPage(page)
    elseif key == "INTEL" then
        self:BuildIntelPage(page)
    else
        return nil
    end
    page.built = true
    self.builtPageCount = (self.builtPageCount or 0) + 1
    return page
end

function MainWindow:Create(initialPage)
    if self.frame then return self.frame end
    local profile = KWR.db.profile.main
    local frame = CreateFrame("Frame", "KWR_MainWindow", UIParent, "BackdropTemplate")
    frame:SetSize(1240, 800)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    -- Keep the command board above the game world, but below Blizzard modal
    -- windows such as the spellbook, map, and options panels.
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "commandCenter", "borderHi")
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()

    frame.logo = KWR.Theme:Title(frame, 24)
    frame.brand = frame:CreateTexture(nil, "ARTWORK")
    frame.brand:SetPoint("TOPLEFT", 18, -14)
    frame.brand:SetSize(20, 20)
    if KWR.Icons then
        KWR.Icons:ApplyBrand(frame.brand, "mark")
    end
    frame.logo:SetPoint("LEFT", frame.brand, "RIGHT", 8, 0)
    frame.logo:SetText("KWR COMMAND CENTER")
    frame.subtitle = KWR.Theme:Font(frame, 10, "soft", "LEFT", "OUTLINE")
    frame.subtitle:SetPoint("LEFT", frame.logo, "RIGHT", 12, -1)
    frame.subtitle:SetText("EXPANDED TACTICAL COMMAND CENTER")
    frame.commandBadge = KWR.Theme:Badge(frame, "gold", "COMMAND", 88, 16)
    frame.commandBadge:SetPoint("TOPLEFT", 18, -44)
    frame.commandBadge.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.commandBadge.icon:SetPoint("LEFT", frame.commandBadge, "LEFT", 6, 0)
    frame.commandBadge.icon:SetSize(12, 12)
    if KWR.Icons then
        KWR.Icons:Apply(frame.commandBadge.icon, "commander", 16)
    end
    frame.truthBadge = KWR.Theme:Badge(frame, "muted", "SOURCE", 84, 16)
    frame.truthBadge:SetPoint("LEFT", frame.commandBadge, "RIGHT", 8, 0)
    frame.truthBadge.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.truthBadge.icon:SetPoint("LEFT", frame.truthBadge, "LEFT", 6, 0)
    frame.truthBadge.icon:SetSize(12, 12)
    if KWR.Icons then
        KWR.Icons:Apply(frame.truthBadge.icon, "observed", 16)
    end
    frame.reporterBadge = KWR.Theme:Badge(frame, "muted", "SEEN", 90, 16)
    frame.reporterBadge:SetPoint("LEFT", frame.truthBadge, "RIGHT", 8, 0)
    frame.reporterBadge.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.reporterBadge.icon:SetPoint("LEFT", frame.reporterBadge, "LEFT", 6, 0)
    frame.reporterBadge.icon:SetSize(12, 12)
    if KWR.Icons then
        KWR.Icons:Apply(frame.reporterBadge.icon, "observed", 16)
    end
    frame.doctrineBadge = KWR.Theme:Badge(frame, "muted", "PLAN", 98, 16)
    frame.doctrineBadge:SetPoint("LEFT", frame.reporterBadge, "RIGHT", 8, 0)
    frame.doctrineBadge.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.doctrineBadge.icon:SetPoint("LEFT", frame.doctrineBadge, "LEFT", 6, 0)
    frame.doctrineBadge.icon:SetSize(12, 12)
    if KWR.Icons then
        KWR.Icons:Apply(frame.doctrineBadge.icon, "assignment", 16)
    end
    frame.tagline = KWR.Theme:Font(frame, 9, "gold")
    frame.tagline:SetPoint("TOPLEFT", 18, -66)
    frame.tagline:SetHeight(16)
    frame.context = KWR.Theme:Font(frame, 10, "muted", "RIGHT", "OUTLINE")
    frame.context:SetPoint("TOPRIGHT", -48, -18)
    frame.context:SetWidth(370)
    frame.tagline:SetPoint("RIGHT", frame.context, "LEFT", -10, 0)
    frame.score = KWR.Theme:Font(frame, 15, "white", "RIGHT", "OUTLINE")
    frame.score:SetPoint("TOPRIGHT", -48, -40)
    frame.score:SetWidth(370)
    frame.headerRule = frame:CreateTexture(nil, "ARTWORK")
    frame.headerRule:SetColorTexture(KWR.Theme:Color("border"))
    frame.headerRule:SetPoint("TOPLEFT", 18, -86)
    frame.headerRule:SetPoint("TOPRIGHT", -18, -86)
    frame.headerRule:SetHeight(1)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() MainWindow:Hide() end)
    frame:SetScript("OnHide", function() MainWindow:RestoreCompactSurfaces() end)

    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", 18, -94)
    tabBar:SetSize(1204, 28)
    self.tabBar = tabBar
    local contentViewport = CreateFrame("ScrollFrame", nil, frame)
    contentViewport:SetPoint("TOPLEFT", 18, -124)
    contentViewport:SetPoint("BOTTOMRIGHT", -18, 20)
    contentViewport:EnableMouseWheel(true)
    contentViewport:SetScript("OnMouseWheel", function(self, delta)
        if (self.IsMouseEnabled and not self:IsMouseEnabled())
            or not self.GetVerticalScrollRange
            or self:GetVerticalScrollRange() <= 0 then
            return
        end
        self:SetVerticalScroll(math.max(0, (self:GetVerticalScroll() or 0) - (delta * 48)))
    end)
    local content = CreateFrame("Frame", nil, contentViewport)
    content:SetSize(1204, 700)
    contentViewport:SetScrollChild(content)
    self.contentViewport = contentViewport
    self.content = content

    for index, pageInfo in ipairs(PAGE_ORDER) do
        local key = pageInfo.key
        local button = KWR.Theme:Button(tabBar, pageInfo.label, 194, 27, function()
            MainWindow:SetPage(key)
        end)
        button:SetPoint("TOPLEFT", (index - 1) * 202, 0)
        self.tabs[key] = button
        self.pages[key] = createPage(content)
    end

    self.frame = frame
    local requestedPage = initialPage or profile.page or "TACTICAL"
    self:EnsurePageBuilt(requestedPage)
    self:SetPage(requestedPage)
    return frame
end

function MainWindow:BuildTacticalPage(page)
    local score = placeCard(page, "MATCH STATUS", 0, 0, 226, 88)
    score.value = KWR.Theme:Font(score, 18, "white", "CENTER", "OUTLINE")
    score.value:SetPoint("TOPLEFT", 8, -34)
    score.value:SetPoint("TOPRIGHT", -8, -34)
    score.value:SetHeight(24)
    score.status = KWR.Theme:Font(score, 9, "green", "CENTER")
    score.status:SetPoint("TOPLEFT", 8, -62)
    score.status:SetPoint("TOPRIGHT", -8, -62)

    local nextCard = placeCard(page, "NEXT", 0, -96, 226, 108)
    nextCard.value = addValue(nextCard, "white", 11, -34)
    configureWrappedBlock(nextCard.value, 5)
    if nextCard.value.SetSpacing then nextCard.value:SetSpacing(2) end
    local mine = placeCard(page, "MY ASSIGNMENT", 0, -212, 226, 90)
    mine.value = addValue(mine, "blue", 11, -34)
    configureWrappedBlock(mine.value, 3)
    if mine.value.SetSpacing then mine.value:SetSpacing(2) end
    local target = placeCard(page, "KILL / CC", 0, -310, 226, 126)
    target.value = addValue(target, "red", 11, -34)
    configureWrappedBlock(target.value, 6)
    if target.value.SetSpacing then target.value:SetSpacing(2) end
    local events = placeCard(page, "LAST EVENTS", 0, -444, 226, 172)
    events.rows = {}
    local eventOffsets = { 34, 50, 78, 94, 122, 138 }
    for index = 1, 6 do
        local row = KWR.Theme:Font(events, 9, index % 2 == 0 and "muted" or "gold")
        row:SetPoint("TOPLEFT", 10, -eventOffsets[index])
        row:SetPoint("TOPRIGHT", -10, -eventOffsets[index])
        row:SetHeight(index % 2 == 0 and 22 or 14)
        events.rows[index] = row
    end

    local mapCard = placeCard(page, "LIVE BATTLEFIELD VIEW", 236, 0, 658, 514)
    mapCard.mapName = KWR.Theme:Font(mapCard, 11, "white", "RIGHT", "OUTLINE")
    mapCard.mapName:SetPoint("TOPRIGHT", -10, -8)
    mapCard.mapName:SetWidth(300)
    mapCard.map = KWR.TacticalMap:Create(mapCard)
    mapCard.map:SetPoint("TOPLEFT", 10, -34)
    mapCard.map:SetPoint("BOTTOMRIGHT", -10, 78)
    mapCard.reporterSummary = KWR.Theme:Font(mapCard, 8, "soft", "CENTER")
    mapCard.reporterSummary:SetPoint("BOTTOMLEFT", 10, 48)
    mapCard.reporterSummary:SetPoint("BOTTOMRIGHT", -10, 48)
    mapCard.reporterSummary:SetHeight(16)
    configureWrappedBlock(mapCard.reporterSummary, 2)
    mapCard.legend = KWR.Theme:Font(mapCard, 9, "muted", "CENTER")
    mapCard.reporterStatus = KWR.Theme:Font(mapCard, 9, "gold", "CENTER", "OUTLINE")
    mapCard.reporterStatus:SetPoint("BOTTOMLEFT", 10, 24)
    mapCard.reporterStatus:SetPoint("BOTTOMRIGHT", -10, 24)
    mapCard.reporterStatus:SetHeight(24)
    configureWrappedBlock(mapCard.reporterStatus, 2)
    mapCard.legend:SetPoint("BOTTOMLEFT", 10, 9)
    mapCard.legend:SetPoint("BOTTOMRIGHT", -10, 9)
    mapCard.legend:SetHeight(24)
    mapCard.legend:SetText("|cff4f8cffBlue rings = team players|r   |cffff3333Red rings = enemy players|r   |cffffd05aGold = target / priority|r   |cffd7b25cSquares = objectives|r   |cff888888X = dead|r")
    mapCard.formation = CreateFrame("Frame", nil, mapCard, "BackdropTemplate")
    mapCard.formation:SetPoint("TOPLEFT", 10, -34)
    mapCard.formation:SetPoint("BOTTOMRIGHT", -10, 78)
    KWR.Theme:Style(mapCard.formation, "background", "border")
    mapCard.formation.title = KWR.Theme:Title(mapCard.formation, 20, "CENTER")
    mapCard.formation.title:SetPoint("TOPLEFT", 20, -24)
    mapCard.formation.title:SetPoint("TOPRIGHT", -20, -24)
    mapCard.formation.title:SetHeight(28)
    mapCard.formation.summary = KWR.Theme:Font(mapCard.formation, 11, "soft", "CENTER")
    mapCard.formation.summary:SetPoint("TOPLEFT", 30, -60)
    mapCard.formation.summary:SetPoint("TOPRIGHT", -30, -60)
    mapCard.formation.summary:SetHeight(70)
    configureWrappedBlock(mapCard.formation.summary, 5)
    if mapCard.formation.summary.SetSpacing then mapCard.formation.summary:SetSpacing(2) end
    mapCard.formation.autoButton = KWR.Theme:Button(mapCard.formation, "AUTO", 58, 20, function()
        MainWindow:SetFormationBuildTarget(nil)
    end)
    mapCard.formation.autoButton:SetPoint("TOP", 0, -138)
    mapCard.formation.prevButton = KWR.Theme:Button(mapCard.formation, "PREV", 58, 20, function()
        MainWindow:CycleFormationBuildTarget(-1)
    end)
    mapCard.formation.prevButton:SetPoint("RIGHT", mapCard.formation.autoButton, "LEFT", -8, 0)
    mapCard.formation.nextButton = KWR.Theme:Button(mapCard.formation, "NEXT", 58, 20, function()
        MainWindow:CycleFormationBuildTarget(1)
    end)
    mapCard.formation.nextButton:SetPoint("LEFT", mapCard.formation.autoButton, "RIGHT", 8, 0)
    mapCard.formation.recruits = KWR.Theme:Font(mapCard.formation, 10, "white", "LEFT")
    mapCard.formation.recruits:SetPoint("TOPLEFT", 34, -174)
    -- Balance both columns so the strategic jobs are readable instead of being squeezed
    -- into clipped fragments on the right side of the setup board.
    mapCard.formation.recruits:SetWidth(300)
    mapCard.formation.recruits:SetHeight(250)
    configureWrappedBlock(mapCard.formation.recruits, 18)
    if mapCard.formation.recruits.SetSpacing then mapCard.formation.recruits:SetSpacing(2) end
    mapCard.formation.positioning = KWR.Theme:Font(mapCard.formation, 10, "soft", "LEFT")
    mapCard.formation.positioning:SetPoint("TOPLEFT", 340, -174)
    mapCard.formation.positioning:SetPoint("TOPRIGHT", -30, -174)
    mapCard.formation.positioning:SetHeight(250)
    configureWrappedBlock(mapCard.formation.positioning, 18)
    if mapCard.formation.positioning.SetSpacing then mapCard.formation.positioning:SetSpacing(2) end
    mapCard.formation:Hide()

    local timeline = placeCard(page, "RECENT CALLS", 236, -522, 658, 94)
    timeline.rows = {}
    for index = 1, 4 do
        local lane = CreateFrame("Frame", nil, timeline, "BackdropTemplate")
        lane:SetPoint("TOPLEFT", 10 + ((index - 1) * 159), -30)
        lane:SetSize(150, 52)
        KWR.Theme:Style(lane, "panel", "border")
        lane.badge = KWR.Theme:Badge(lane, "muted", "--", 66, 14)
        lane.badge:SetPoint("TOPLEFT", 8, -8)
        lane.value = KWR.Theme:Font(lane, 9, index == 1 and "gold" or "soft", "LEFT")
        lane.value:SetPoint("TOPLEFT", 8, -26)
        lane.value:SetPoint("TOPRIGHT", -8, -26)
        lane.value:SetHeight(20)
        configureWrappedBlock(lane.value, 2)
        timeline.rows[index] = lane
    end

    local win = placeCard(page, "WIN PATH", 904, 0, 300, 102)
    win.value = addValue(win, "white", 12, -42)
    configureWrappedBlock(win.value, 4)
    if win.value.SetSpacing then win.value:SetSpacing(2) end
    -- Keep all ten roster jobs inside the card; the last line previously sat on the bottom border.
    local assignments = placeCard(page, "TEAM JOBS", 904, -106, 300, 194)
    assignments.rows = {}
    for index = 1, 10 do
        local row = KWR.Theme:Font(assignments, 9, index == 1 and "blue" or "soft")
        row:SetPoint("TOPLEFT", 10, -30 - ((index - 1) * 16))
        row:SetPoint("TOPRIGHT", -10, -30 - ((index - 1) * 16))
        row:SetHeight(14)
        assignments.rows[index] = row
    end
    local caller = placeCard(page, "CALL TEAM", 904, -300, 300, 94)
    if caller.SetClipsChildren then caller:SetClipsChildren(true) end
    caller.value = addValue(caller, "purple", 10, -34)
    configureWrappedBlock(caller.value, 4)
    if caller.value.SetSpacing then caller.value:SetSpacing(2) end
    local focus = placeCard(page, "NEXT", 904, -402, 300, 132)
    if focus.SetClipsChildren then focus:SetClipsChildren(true) end
    focus.value = addValue(focus, "red", 11, -34)
    configureWrappedBlock(focus.value, 7)
    if focus.value.SetSpacing then focus.value:SetSpacing(2) end
    local controls = placeCard(page, "CONTROLS", 904, -542, 300, 74)
    local refresh = KWR.Theme:Button(controls, "PIVOT", 54, 23, function()
        KWR.MatchRuntime:Reassess()
    end)
    refresh:SetPoint("TOPLEFT", 10, -39)
    local rescan = KWR.Theme:Button(controls, "RESCAN", 58, 23, function()
        KWR.MatchRuntime:RescanRoster()
    end)
    rescan:SetPoint("LEFT", refresh, "RIGHT", 4, 0)
    local copy = KWR.Theme:Button(controls, "COPY", 40, 23, function()
        local command = KWR.Store:Get().command
        KWR.CopyDialog:ShowCompact("KWR Compact Call", compactCommandText(KWR.Store:Get()))
    end)
    copy:SetPoint("LEFT", rescan, "RIGHT", 4, 0)
    local mini = KWR.Theme:Button(controls, "MINI", 40, 23, function()
        MainWindow:MinimizeTo("COMMAND")
    end)
    mini:SetPoint("LEFT", copy, "RIGHT", 4, 0)
    local options = KWR.Theme:Button(controls, "MENU", 56, 23, function()
        local state = KWR.Store:Get()
        if state.snapshot and state.snapshot.context and state.snapshot.context.inPvP then
            MainWindow:ShowAlternatives()
            return
        end
        KWR.Options:Toggle()
    end)
    options:SetPoint("LEFT", mini, "RIGHT", 4, 0)

    page.scoreCard, page.nextCard, page.mineCard = score, nextCard, mine
    page.targetCard, page.eventsCard, page.battlefieldCard = target, events, mapCard
    page.timelineCard, page.winCard = timeline, win
    page.assignmentCard, page.callerCard, page.focusCard = assignments, caller, focus
    page.controlsCard = controls
    page.altButton = options
end

function MainWindow:BuildObjectivesPage(page)
    local score = placeCard(page, "BG SCORE", 0, 0, 286, 116)
    score.stateBadge = KWR.Theme:Badge(score, "muted", "STATE", 88, 16)
    score.truthBadge = KWR.Theme:Badge(score, "muted", "SOURCE", 88, 16)
    configureCardHeader(score, "BG SCORE", { score.stateBadge, score.truthBadge })
    score.value = KWR.Theme:Font(score, 25, "white", "CENTER", "OUTLINE")
    score.value:SetPoint("TOPLEFT", 10, -42)
    score.value:SetPoint("TOPRIGHT", -10, -42)
    score.value:SetHeight(34)
    score.detail = KWR.Theme:Font(score, 10, "soft", "CENTER")
    score.detail:SetPoint("TOPLEFT", 10, -82)
    score.detail:SetPoint("TOPRIGHT", -10, -82)

    local status = placeCard(page, "MAP STATUS", 0, -124, 286, 292)
    status.rows = {}
    for index = 1, 9 do
        local row = KWR.Theme:Font(status, 11, index % 2 == 0 and "muted" or "soft")
        row:SetPoint("TOPLEFT", 10, -36 - ((index - 1) * 27))
        row:SetPoint("TOPRIGHT", -10, -36 - ((index - 1) * 27))
        row:SetHeight(22)
        status.rows[index] = row
    end
    local summary = placeCard(page, "MAP SUMMARY", 0, -424, 286, 208)
    summary.value = addValue(summary, "white", 11, -36)

    local truth = placeCard(page, "OBJECTIVE CONTROL - AUTHORITATIVE PUBLIC DATA", 296, 0, 602, 632)
    addColumnHeaders(truth, {
        { label = "OBJECTIVE", x = 16, width = 225 },
        { label = "OWNER", x = 248, width = 95 },
        { label = "STATE", x = 353, width = 95 },
        { label = "CONFIDENCE", x = 460, width = 125 },
    })
    truth.rows = {}
    for index = 1, 16 do
        local row = createListRow(truth, index, -54 - ((index - 1) * 33), 602, 29)
        row.objective = KWR.Theme:Font(row, 10, "white")
        row.objective:SetPoint("LEFT", 8, 0)
        row.objective:SetWidth(225)
        row.owner = KWR.Theme:Font(row, 9, "blue")
        row.owner:SetPoint("LEFT", 240, 0)
        row.owner:SetWidth(95)
        row.state = KWR.Theme:Font(row, 9, "gold")
        row.state:SetPoint("LEFT", 345, 0)
        row.state:SetWidth(95)
        row.source = KWR.Theme:Font(row, 8, "muted")
        row.source:SetPoint("LEFT", 452, 0)
        row.source:SetWidth(125)
        truth.rows[index] = row
    end
    truth.empty = KWR.Theme:Font(truth, 12, "soft", "CENTER")
    truth.empty:SetPoint("CENTER", 0, 14)
    truth.empty:SetWidth(340)
    truth.empty:SetText("NO OBJECTIVE DATA\n\nEnter a battleground to populate objective ownership and confidence.")

    local conditions = placeCard(page, "WIN CALL", 908, 0, 296, 144)
    conditions.urgencyBadge = KWR.Theme:Badge(conditions, "muted", "URGENCY", 96, 16)
    conditions.confidenceBadge = KWR.Theme:Badge(conditions, "muted", "CONF", 88, 16)
    configureCardHeader(conditions, "WIN CALL", { conditions.urgencyBadge, conditions.confidenceBadge })
    conditions.value = addValue(conditions, "white", 11, -36)
    local calls = placeCard(page, "QUICK CALLS", 908, -152, 296, 214)
    calls.buttons = {}
    calls.pressureBadge = KWR.Theme:Badge(calls, "red", "PRESSURE", 82, 16)
    calls.pressureBadge:SetPoint("TOPLEFT", 10, -36)
    calls.stabilizeBadge = KWR.Theme:Badge(calls, "blue", "STABILIZE", 88, 16)
    calls.stabilizeBadge:SetPoint("LEFT", calls.pressureBadge, "RIGHT", 6, 0)
    calls.tempoBadge = KWR.Theme:Badge(calls, "gold", "TEMPO", 70, 16)
    calls.tempoBadge:SetPoint("LEFT", calls.stabilizeBadge, "RIGHT", 6, 0)
    calls.helper = KWR.Theme:Font(calls, 10, "soft", "CENTER", "OUTLINE")
    calls.helper:SetPoint("TOPLEFT", 10, -60)
    calls.helper:SetPoint("TOPRIGHT", -10, -60)
    calls.helper:SetHeight(16)
    calls.helper:SetText("REVIEWED FIXED CALLS ONLY")
    calls.statusBadge = KWR.Theme:Badge(calls, "muted", "READY", 74, 16)
    -- Reserve a dedicated status strip below the final button row. The old
    -- 18px bottom offset put READY/COPY feedback on top of the third row.
    calls.statusBadge:SetPoint("BOTTOMLEFT", 10, 8)
    calls.statusText = KWR.Theme:Font(calls, 9, "muted", "LEFT")
    calls.statusText:SetPoint("LEFT", calls.statusBadge, "RIGHT", 8, 0)
    calls.statusText:SetPoint("RIGHT", -10, 0)
    calls.statusText:SetPoint("TOP", calls.statusBadge, "TOP", 0, 0)
    calls.statusText:SetHeight(16)
    calls.statusText:SetText("LEFT SENDS  |  RIGHT COPIES")
    calls.status = {
        badge = calls.statusBadge,
        message = calls.statusText,
    }
    for index, label in ipairs(KWR.QuickCalls:Definitions()) do
        local button = KWR.QuickCalls:CreateButton(calls, label, 132, 32, calls.status)
        button:SetPoint("TOPLEFT", 10 + (((index - 1) % 2) * 140), -84 - (math.floor((index - 1) / 2) * 34))
        calls.buttons[index] = button
    end
    local info = placeCard(page, "MAP INFO", 908, -374, 296, 198)
    info.rows = {}
    for index, label in ipairs({ "Map", "Type", "Short name", "Maximum score", "Priority" }) do
        local row = CreateFrame("Frame", nil, info)
        row:SetPoint("TOPLEFT", 12, -36 - ((index - 1) * 22))
        row:SetPoint("TOPRIGHT", -12, -36 - ((index - 1) * 22))
        row:SetHeight(18)
        row.label = KWR.Theme:Font(row, 10, "muted")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetWidth(96)
        row.label:SetText(label)
        row.value = KWR.Theme:Font(row, 10, "soft")
        row.value:SetPoint("LEFT", 104, 0)
        row.value:SetPoint("RIGHT", 0, 0)
        info.rows[index] = row
    end
    info.eventLabel = KWR.Theme:Font(info, 9, "gold")
    info.eventLabel:SetPoint("TOPLEFT", 12, -148)
    info.eventLabel:SetText("Last event")
    info.eventValue = KWR.Theme:Font(info, 9, "soft")
    info.eventValue:SetPoint("TOPLEFT", 12, -162)
    info.eventValue:SetPoint("TOPRIGHT", -12, -162)
    info.eventValue:SetHeight(30)
    configureWrappedBlock(info.eventValue, 2)
    if info.eventValue.SetSpacing then info.eventValue:SetSpacing(2) end
    local source = placeCard(page, "DATA SOURCES", 908, -580, 296, 52)
    source.value = addValue(source, "muted", 9, -36)
    configureWrappedBlock(source.value, 3)
    if source.value.SetSpacing then source.value:SetSpacing(2) end
    source.value:SetText("Score and objective control come from Blizzard public widgets. Unknown stays unknown. Fixed quick calls require an explicit player click.")

    page.scoreCard, page.statusCard, page.summaryCard = score, status, summary
    page.truthCard, page.conditionCard, page.callsCard, page.infoCard = truth, conditions, calls, info
    page.sourceCard = source
end

function MainWindow:BuildTeamPage(page)
    local summary = placeCard(page, "COMMAND UNIT", 0, 0, 1204, 92)
    summary.readyBadge = KWR.Theme:Badge(summary, "muted", "READY", 88, 16)
    summary.openBadge = KWR.Theme:Badge(summary, "muted", "OPEN", 88, 16)
    configureCardHeader(summary, "COMMAND UNIT", { summary.readyBadge, summary.openBadge })
    summary.value = KWR.Theme:Font(summary, 17, "white", "CENTER", "OUTLINE")
    summary.value:SetPoint("TOPLEFT", 10, -38)
    summary.value:SetPoint("TOPRIGHT", -10, -38)
    summary.value:SetHeight(24)
    summary.detail = KWR.Theme:Font(summary, 10, "soft", "CENTER")
    summary.detail:SetPoint("TOPLEFT", 10, -66)
    summary.detail:SetPoint("TOPRIGHT", -10, -66)

    local roster = placeCard(page, "TEAM ROSTER", 0, -100, 1204, 390)
    roster.headers = {}
    for _, definition in ipairs(TEAM_COLUMNS) do
        local header = KWR.Theme:Font(roster, 9, "muted")
        header:SetPoint("TOPLEFT", LIST_ROW_INSET + definition.x, -36)
        header:SetWidth(definition.width)
        header:SetHeight(14)
        header:SetText(definition.label)
        roster.headers[#roster.headers + 1] = header
    end
    roster.rows = {}
    for index = 1, 10 do
        local row = createListRow(
            roster, index, -54 - ((index - 1) * 30),
            1204, 27)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 7, 0)
        row.icon:SetSize(20, 20)
        row.player = KWR.Theme:Font(row, 10, "white")
        row.player:SetPoint("LEFT", TEAM_COLUMNS[1].x, 0)
        row.player:SetWidth(TEAM_COLUMNS[1].width)
        row.spec = KWR.Theme:Font(row, 10, "soft")
        row.spec:SetPoint("LEFT", TEAM_COLUMNS[2].x, 0)
        row.spec:SetWidth(TEAM_COLUMNS[2].width)
        row.role = KWR.Theme:Font(row, 9, "gold")
        row.role:SetPoint("LEFT", TEAM_COLUMNS[3].x, 0)
        row.role:SetWidth(TEAM_COLUMNS[3].width)
        row.health = CreateFrame("StatusBar", nil, row, "BackdropTemplate")
        row.health:SetPoint("LEFT", TEAM_COLUMNS[4].x, 0)
        row.health:SetSize(TEAM_COLUMNS[4].width, 18)
        row.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        row.health:SetMinMaxValues(0, 100)
        KWR.Theme:Style(row.health, "background", "border")
        row.healthText = KWR.Theme:Font(row.health, 8, "white", "CENTER", "OUTLINE")
        row.healthText:SetAllPoints()
        row.life = KWR.Theme:Font(row, 9, "green")
        row.life:SetPoint("LEFT", TEAM_COLUMNS[5].x, 0)
        row.life:SetWidth(TEAM_COLUMNS[5].width)
        row.position = KWR.Theme:Font(row, 9, "blue")
        row.position:SetPoint("LEFT", TEAM_COLUMNS[6].x, 0)
        row.position:SetWidth(TEAM_COLUMNS[6].width)
        roster.rows[index] = row
    end

    local doctrine = placeCard(page, "TEAM CONTEXT", 0, -498, 850, 118)
    doctrine.scroll = CreateFrame("ScrollFrame", nil, doctrine, "UIPanelScrollFrameTemplate")
    doctrine.scroll:SetPoint("TOPLEFT", 10, -34)
    doctrine.scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    doctrine.body = CreateFrame("Frame", nil, doctrine.scroll)
    doctrine.body:SetSize(1, 1)
    doctrine.scroll:SetScrollChild(doctrine.body)
    doctrine.value = KWR.Theme:Font(doctrine.body, 10, "soft", "LEFT")
    doctrine.value:SetPoint("TOPLEFT", 0, 0)
    doctrine.value:SetPoint("TOPRIGHT", 0, 0)
    configureWrappedBlock(doctrine.value)
    if doctrine.value.SetSpacing then doctrine.value:SetSpacing(2) end
    local readiness = placeCard(
        page, "ROSTER STATUS", 860, -498, 344, 54)
    readiness.stateBadge = KWR.Theme:Badge(readiness, "muted", "STATE", 88, 16)
    configureCardHeader(readiness, "ROSTER STATUS", { readiness.stateBadge })
    readiness.value = addValue(readiness, "white", 9, -34)
    configureWrappedBlock(readiness.value, 1)
    if readiness.value.SetSpacing then readiness.value:SetSpacing(2) end
    local controls = placeCard(
        page, "ROSTER CONTROLS", 860, -558, 344, 58)
    local rescan = KWR.Theme:Button(
        controls, "RESCAN", 74, 24, function()
        KWR.MatchRuntime:RescanRoster()
    end)
    rescan:SetPoint("TOPLEFT", 10, -31)
    local refresh = KWR.Theme:Button(
        controls, "REFRESH", 74, 24, function()
        KWR.MatchRuntime:ForceRefresh("roster")
    end)
    refresh:SetPoint("LEFT", rescan, "RIGHT", 6, 0)
    local copy = KWR.Theme:Button(
        controls, "COPY", 74, 24, function()
        local state = KWR.Store:Get()
        KWR.CopyDialog:ShowText("KWR Setup Assignments",
            KWR.Assignments:LineExport(state.assignments, state.snapshot.context.mapKey), {
                note = "One player per line. Copy this setup list manually if you want to share it.",
            })
    end)
    copy:SetPoint("LEFT", refresh, "RIGHT", 6, 0)
    local mini = KWR.Theme:Button(
        controls, "MINI", 74, 24, function()
        MainWindow:MinimizeTo("ROSTER", "BOTH")
    end)
    mini:SetPoint("LEFT", copy, "RIGHT", 6, 0)

    page.summaryCard, page.rosterCard = summary, roster
    page.doctrineCard, page.readinessCard = doctrine, readiness
    page.controlsCard = controls
end

function MainWindow:BuildEnemiesPage(page)
    local toolbar = placeCard(page, "ENEMY TRACKER", 0, 0, 1204, 58)
    toolbar.liveBadge = KWR.Theme:Badge(toolbar, "muted", "IDLE", 86, 16)
    toolbar.liveBadge:SetPoint("TOPLEFT", 12, -34)
    toolbar.mode = KWR.Theme:Font(toolbar, 9, "gold", "RIGHT", "OUTLINE")
    toolbar.mode:SetWidth(230)
    toolbar.summary = KWR.Theme:Font(toolbar, 9, "muted", "RIGHT", "OUTLINE")
    toolbar.summary:SetPoint("LEFT", toolbar.liveBadge, "RIGHT", 10, 0)
    toolbar.summary:SetWidth(500)
    toolbar.summary:SetJustifyH("LEFT")
    toolbar.minimize = KWR.Theme:Button(toolbar, "MINIMIZE", 92, 23, function()
        MainWindow:MinimizeTo("ROSTER", "BOTH")
    end)
    toolbar.minimize:SetPoint("TOPRIGHT", -10, -31)
    toolbar.mode:SetPoint("RIGHT", toolbar.minimize, "LEFT", -10, 0)

    local tracker = placeCard(
        page, "ENEMY INTELLIGENCE", 0, -66, 1204, 410)
    page.maxRows = 10
    page.enemySlotKeys = {}
    addColumnHeaders(tracker, {
        { label = "PRI", x = 12, width = 32, justify = "CENTER" },
        { label = "SEEN", x = 49, width = 56, justify = "CENTER" },
        { label = "ENEMY", x = 142, width = 190 },
        { label = "HEALTH", x = 342, width = 130, justify = "CENTER" },
        { label = "LOCATION", x = 482, width = 190 },
        { label = "WINDOW", x = 682, width = 362, justify = "CENTER" },
        { label = "DETAIL", x = 1070, width = 100, justify = "CENTER" },
    })
    tracker.rows = {}
    for index = 1, 10 do
        local row = createListRow(
            tracker, index, -48 - ((index - 1) * 35),
            1204, 32)
        row.priority = KWR.Theme:Button(row, "O", 32, 28, function()
            if row.enemyKey and not KWR.Store:Get().snapshot.context.preview then
                KWR.EnemyIntel:CyclePriority(row.enemyKey)
                KWR.MatchRuntime:ForceRefresh("enemy-priority")
            end
        end)
        row.priority:SetPoint("LEFT", 4, 0)
        row.seen = KWR.Theme:Font(row, 9, "green", "CENTER")
        row.seen:SetPoint("LEFT", 41, 0)
        row.seen:SetWidth(56)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 102, 0)
        row.icon:SetSize(26, 26)
        row.name = KWR.Theme:Font(row, 10, "white")
        row.name:SetPoint("TOPLEFT", 134, -3)
        row.name:SetWidth(198)
        row.spec = KWR.Theme:Font(row, 8, "muted")
        row.spec:SetPoint("BOTTOMLEFT", 134, 3)
        row.spec:SetWidth(198)
        row.health = CreateFrame("StatusBar", nil, row, "BackdropTemplate")
        row.health:SetPoint("LEFT", 334, 0)
        row.health:SetSize(130, 18)
        row.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        KWR.Theme:Style(row.health, "background", "border")
        row.healthText = KWR.Theme:Font(row.health, 8, "white", "CENTER", "OUTLINE")
        row.healthText:SetAllPoints()
        row.location = KWR.Theme:Font(row, 9, "gold")
        row.location:SetPoint("LEFT", 474, 0)
        row.location:SetWidth(190)
        row.cooldown = KWR.Theme:Font(
            row, 9, "muted", "CENTER", "OUTLINE")
        row.cooldown:SetPoint("LEFT", 674, 0)
        row.cooldown:SetWidth(362)
        row.note = KWR.Theme:Button(row, "VIEW", 100, 24, function()
            if row.enemyKey then
                MainWindow:SelectEnemy(row.enemyKey)
            end
        end)
        row.note:SetPoint("LEFT", 1062, 0)
        tracker.rows[index] = row
    end
    tracker.empty = KWR.Theme:Font(tracker, 13, "soft", "CENTER")
    tracker.empty:SetPoint("CENTER", 0, 0)
    tracker.empty:SetWidth(600)
    tracker.empty:SetText(
        "NO ENEMY DATA YET\n"
        .. "Enemy roster data appears when Blizzard exposes "
        .. "the battleground scoreboard.")

    local detail = placeCard(
        page, "SELECTED ENEMY", 0, -484, 1204, 132)
    detail.truthBadge =
        KWR.Theme:Badge(detail, "muted", "ROSTER", 92, 16)
    detail.truthBadge:SetPoint("TOPRIGHT", -118, -8)
    detail.priorityBadge =
        KWR.Theme:Badge(detail, "muted", "OBSERVE", 96, 16)
    detail.priorityBadge:SetPoint(
        "RIGHT", detail.truthBadge, "LEFT", -8, 0)
    detail.identity = KWR.Theme:Font(
        detail, 13, "white", "LEFT", "OUTLINE")
    detail.identity:SetPoint("TOPLEFT", 12, -38)
    detail.identity:SetWidth(350)
    detail.summary = KWR.Theme:Font(detail, 10, "soft")
    detail.summary:SetPoint("TOPLEFT", 12, -64)
    detail.summary:SetPoint("TOPRIGHT", -132, -64)
    detail.summary:SetHeight(28)
    detail.note = KWR.Theme:Font(detail, 9, "gold")
    detail.note:SetPoint("TOPLEFT", 12, -98)
    detail.note:SetPoint("TOPRIGHT", -132, -98)
    detail.note:SetHeight(34)
    configureWrappedBlock(detail.note, 2)
    detail.edit = KWR.Theme:Button(
        detail, "EDIT NOTE", 104, 26, function()
            if MainWindow.selectedEnemyKey then
                MainWindow:ShowEnemyNote(
                    MainWindow.selectedEnemyKey)
            end
        end)
    detail.edit:SetPoint("BOTTOMRIGHT", -12, 12)

    page.toolbar = toolbar
    page.trackerCard = tracker
    page.detailCard = detail
end

function MainWindow:SelectEnemy(key)
    self.selectedEnemyKey = key
    if self.activePage == "ENEMIES" then
        self:UpdateEnemies(KWR.Store:Get())
    end
end

function MainWindow:BuildAssignmentsPage(page)
    local command = placeCard(page, "SMART ASSIGNMENTS", 0, 0, 1204, 92)
    command.stateBadge = KWR.Theme:Badge(command, "muted", "COMMAND", 96, 16)
    command.coverageBadge = KWR.Theme:Badge(command, "muted", "COVERAGE", 104, 16)
    configureCardHeader(command, "SMART ASSIGNMENTS", { command.stateBadge, command.coverageBadge })
    command.value = KWR.Theme:Font(command, 15, "white", "CENTER", "OUTLINE")
    command.value:SetPoint("TOPLEFT", 10, -38)
    command.value:SetPoint("TOPRIGHT", -10, -38)
    command.value:SetHeight(40)
    if command.value.SetWordWrap then command.value:SetWordWrap(true) end
    if command.value.SetSpacing then command.value:SetSpacing(2) end
    command.detail = KWR.Theme:Font(command, 10, "soft", "CENTER")
    command.detail:SetPoint("TOPLEFT", 10, -66)
    command.detail:SetPoint("TOPRIGHT", -10, -66)

    local board = placeCard(page, "ONE PLAYER - ONE JOB - ONE LOCATION", 0, -100, 886, 532)
    addColumnHeaders(board, {
        { label = "PLAYER", x = 16, width = 200 },
        { label = "SPEC / CLASS / ROLE", x = 226, width = 190 },
        { label = "BATTLEFIELD JOB", x = 426, width = 200 },
        { label = "LOCATION", x = 636, width = 150 },
        { label = "STATE", x = 796, width = 70, justify = "CENTER" },
    })
    board.rows = {}
    for index = 1, 15 do
        local row = createListRow(board, index, -54 - ((index - 1) * 30), 886, 27)
        row.player = KWR.Theme:Font(row, 10, "white")
        row.player:SetPoint("LEFT", 8, 0)
        row.player:SetWidth(200)
        row.class = KWR.Theme:Font(row, 9, "muted")
        row.class:SetPoint("LEFT", 218, 0)
        row.class:SetWidth(190)
        row.assignment = KWR.Theme:Font(row, 10, "gold")
        row.assignment:SetPoint("LEFT", 418, 0)
        row.assignment:SetWidth(200)
        row.location = KWR.Theme:Font(row, 10, "blue")
        row.location:SetPoint("LEFT", 628, 0)
        row.location:SetWidth(150)
        row.priority = KWR.Theme:Font(row, 9, "soft", "CENTER")
        row.priority:SetPoint("LEFT", 788, 0)
        row.priority:SetWidth(70)
        board.rows[index] = row
    end

    local mine = placeCard(page, "MY ASSIGNMENT", 896, -100, 308, 146)
    mine.lockBadge = KWR.Theme:Badge(mine, "muted", "UNLOCKED", 104, 16)
    configureCardHeader(mine, "MY ASSIGNMENT", { mine.lockBadge })
    mine.value = addValue(mine, "blue", 13, -38)
    configureWrappedBlock(mine.value, 6)
    if mine.value.SetSpacing then mine.value:SetSpacing(3) end
    local logic = placeCard(page, "WHY THIS PLAN", 896, -254, 308, 246)
    logic.scroll = CreateFrame("ScrollFrame", nil, logic, "UIPanelScrollFrameTemplate")
    logic.scroll:SetPoint("TOPLEFT", 12, -36)
    logic.scroll:SetPoint("BOTTOMRIGHT", -28, 12)
    logic.body = CreateFrame("Frame", nil, logic.scroll)
    logic.body:SetSize(1, 1)
    logic.scroll:SetScrollChild(logic.body)
    logic.value = KWR.Theme:Font(logic.body, 10, "soft")
    logic.value:SetPoint("TOPLEFT", 0, 0)
    logic.value:SetPoint("TOPRIGHT", 0, 0)
    configureWrappedBlock(logic.value)
    if logic.value.SetSpacing then logic.value:SetSpacing(2) end
    local controls = placeCard(page, "MANUAL HANDOFF", 896, -508, 308, 124)
    local copy = KWR.Theme:Button(controls, "COPY COMMAND CALL", 180, 28, function()
        local state = KWR.Store:Get()
        KWR.CopyDialog:ShowCompact("KWR Assignment Handoff",
            KWR.Assignments:ChatExport(state.assignments, state.snapshot.context.mapKey), {
                note = "Chat-safe single line. WoW chat collapses pasted line breaks, so KWR prepares this handoff in one readable line.",
            })
    end)
    copy:SetPoint("TOP", 0, -40)
    controls.note = KWR.Theme:Font(controls, 10, "soft", "CENTER")
    controls.note:SetPoint("TOPLEFT", 10, -80)
    controls.note:SetPoint("TOPRIGHT", -10, -80)
    if controls.note.SetSpacing then controls.note:SetSpacing(2) end
    controls.note:SetText("KWR prepares text. Commander locks: /kwr override help")

    page.commandCard, page.boardCard = command, board
    page.mineCard, page.logicCard = mine, logic
end

function MainWindow:BuildIntelPage(page)
    local summary = placeCard(page, "MATCH RECORD", 0, 0, 1204, 90)
    summary.value = KWR.Theme:Font(summary, 16, "white", "CENTER", "OUTLINE")
    summary.value:SetPoint("TOPLEFT", 10, -34)
    summary.value:SetPoint("TOPRIGHT", -10, -34)
    summary.value:SetHeight(23)
    summary.detail = KWR.Theme:Font(summary, 10, "soft", "CENTER")
    summary.detail:SetPoint("TOPLEFT", 10, -62)
    summary.detail:SetPoint("TOPRIGHT", -10, -62)
    summary.matchesBadge = KWR.Theme:Badge(summary, "blue", "MATCHES", 92, 16)
    summary.reviewBadge = KWR.Theme:Badge(summary, "gold", "REVIEWS", 92, 16)
    summary.latestBadge = KWR.Theme:Badge(summary, "muted", "LATEST", 92, 16)
    configureCardHeader(summary, "MATCH RECORD", {
        summary.matchesBadge, summary.reviewBadge, summary.latestBadge
    })

    local history = placeCard(page, "MATCH HISTORY", 0, -98, 820, 338)
    addColumnHeaders(history, {
        { label = "DATE", x = 16, width = 90 },
        { label = "MAP", x = 116, width = 160 },
        { label = "RESULT", x = 286, width = 82 },
        { label = "FINAL SCORE", x = 378, width = 100 },
        { label = "REVIEW", x = 488, width = 75 },
        { label = "LAST COMMAND", x = 573, width = 230 },
    })
    history.rows = {}
    for index = 1, 8 do
        local row = createListRow(history, index, -54 - ((index - 1) * 33), 820, 29)
        row.date = KWR.Theme:Font(row, 9, "muted")
        row.date:SetPoint("LEFT", 8, 0)
        row.date:SetWidth(90)
        row.map = KWR.Theme:Font(row, 9, "white")
        row.map:SetPoint("LEFT", 108, 0)
        row.map:SetWidth(160)
        row.result = KWR.Theme:Font(row, 9, "green")
        row.result:SetPoint("LEFT", 278, 0)
        row.result:SetWidth(82)
        row.score = KWR.Theme:Font(row, 9, "blue")
        row.score:SetPoint("LEFT", 370, 0)
        row.score:SetWidth(100)
        row.review = KWR.Theme:Font(row, 9, "gold")
        row.review:SetPoint("LEFT", 480, 0)
        row.review:SetWidth(75)
        row.command = KWR.Theme:Font(row, 8, "soft")
        row.command:SetPoint("LEFT", 565, 0)
        row.command:SetWidth(230)
        history.rows[index] = row
    end
    history.note = KWR.Theme:Font(history, 9, "muted", "RIGHT")
    history.note:SetPoint("BOTTOMRIGHT", -10, 10)
    history.note:SetWidth(250)

    local insights = placeCard(page, "AAR INSIGHTS", 830, -98, 374, 338)
    insights.value = addValue(insights, "soft", 12, -34)
    local doctrine = placeCard(page, "MAP DOCTRINE", 0, -444, 820, 188)
    doctrine.value = addValue(doctrine, "soft", 11, -36)
    local review = placeCard(page, "AAR", 830, -444, 374, 188)
    review.resultBadge = KWR.Theme:Badge(review, "muted", "NO MATCH", 96, 16)
    review.reviewBadge = KWR.Theme:Badge(review, "muted", "REVIEW", 104, 16)
    review.exportBadge = KWR.Theme:Badge(review, "gold", "EXPORT", 84, 16)
    configureCardHeader(review, "AAR", {
        review.resultBadge, review.reviewBadge, review.exportBadge
    })
    review.value = KWR.Theme:Font(review, 10, "soft")
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
