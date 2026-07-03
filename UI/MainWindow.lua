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
    { key = "INTEL", label = "INTEL / AAR" },
}

local LIST_ROW_INSET = 8
local TEAM_COLUMNS = {
    { key = "player", label = "PLAYER", x = 34, width = 202 },
    { key = "spec", label = "SPEC", x = 246, width = 146 },
    { key = "role", label = "ROLE", x = 402, width = 82 },
    { key = "health", label = "HEALTH", x = 494, width = 128 },
    { key = "life", label = "STATE", x = 632, width = 70 },
    { key = "position", label = "ASSIGNMENT", x = 712, width = 120 },
}

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
    value:SetPoint("TOPLEFT", 10, top or -34)
    value:SetPoint("BOTTOMRIGHT", -10, 8)
    return value
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
    local spec = KWR.Util:Text(entity and entity.spec, "Unknown", 28)
    if entity and entity.specSource == "historical" then
        return spec .. " (HIST)"
    end
    return spec
end

local function applyDirectHealth(statusBar, unit, healthText)
    if not unit or unit == "" or type(UnitExists) ~= "function"
        or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false) then return false end
    if type(UnitHealth) == "function" and type(UnitHealthMax) == "function" then
        local ok = pcall(function()
            local health = UnitHealth(unit)
            statusBar:SetMinMaxValues(0, UnitHealthMax(unit))
            statusBar:SetValue(health)
            if healthText then
                if type(AbbreviateNumbers) == "function" then
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
    if status == "WIN" or status == "VICTORY" then return "green" end
    if status == "LOSE" or status == "DEFEAT" then return "red" end
    if status == "TIE" then return "yellow" end
    return "gold"
end

local function compactCommandText(state)
    local command = state.command
    local mapKey = state.snapshot and state.snapshot.context
        and state.snapshot.context.mapKey
    return KWR.Maps:AbbreviateText(mapKey,
        table.concat({ command.line1, command.line2, command.line3 }, " | "))
end

local function assignmentPriority(priority)
    priority = KWR.Util:Number(priority, 0) or 0
    if priority >= 95 then return "PRIMARY" end
    if priority >= 85 then return "HIGH" end
    if priority >= 70 then return "SUPPORT" end
    return "FORMING"
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
    if source == "ui_widget" or source == "preview" then return "VERIFIED" end
    if source == "area_poi" then return "MAP ONLY" end
    return "UNKNOWN"
end

local function selfAssignment(state)
    local playerName = KWR.Util:UnitName("player")
    local shortName = playerName and KWR.Util:ShortName(playerName)
    for _, assignment in ipairs(state.assignments or {}) do
        if assignment.name == playerName or assignment.shortName == shortName then return assignment end
    end
    return state.assignments and state.assignments[1]
end

local function primaryEnemy(state)
    return state.snapshot.combat and state.snapshot.combat.killTarget
        or (state.snapshot.enemies and state.snapshot.enemies[1])
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

function MainWindow:Create()
    if self.frame then return self.frame end
    local profile = KWR.db.profile.main
    local frame = CreateFrame("Frame", "KWR_MainWindow", UIParent, "BackdropTemplate")
    frame:SetSize(1240, 760)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("FULLSCREEN")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()

    frame.logo = KWR.Theme:Title(frame, 24)
    frame.logo:SetPoint("TOPLEFT", 18, -12)
    frame.logo:SetText("KWR WAR ROOM")
    frame.subtitle = KWR.Theme:Font(frame, 10, "soft", "LEFT", "OUTLINE")
    frame.subtitle:SetPoint("LEFT", frame.logo, "RIGHT", 12, -1)
    frame.subtitle:SetText("EXPANDED TACTICAL COMMAND BOARD")
    frame.tagline = KWR.Theme:Font(frame, 9, "gold")
    frame.tagline:SetPoint("TOPLEFT", 20, -42)
    frame.tagline:SetText("GATHER. ANALYZE. ASSIGN. WIN.")
    frame.context = KWR.Theme:Font(frame, 10, "muted", "RIGHT", "OUTLINE")
    frame.context:SetPoint("TOPRIGHT", -48, -18)
    frame.context:SetWidth(370)
    frame.score = KWR.Theme:Font(frame, 15, "white", "RIGHT", "OUTLINE")
    frame.score:SetPoint("TOPRIGHT", -48, -40)
    frame.score:SetWidth(370)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() MainWindow:Hide() end)
    frame:SetScript("OnHide", function() MainWindow:RestoreCompactSurfaces() end)

    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", 18, -66)
    tabBar:SetSize(1204, 28)
    self.tabBar = tabBar
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 18, -100)
    content:SetPoint("BOTTOMRIGHT", -18, 20)
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

    self:BuildTacticalPage(self.pages.TACTICAL)
    self:BuildObjectivesPage(self.pages.OBJECTIVES)
    self:BuildTeamPage(self.pages.TEAM)
    self:BuildEnemiesPage(self.pages.ENEMIES)
    self:BuildAssignmentsPage(self.pages.ASSIGNMENTS)
    self:BuildIntelPage(self.pages.INTEL)
    self:CreateEnemyNoteEditor()

    self.frame = frame
    self:SetPage(profile.page or "TACTICAL")
    return frame
end

function MainWindow:BuildTacticalPage(page)
    local score = placeCard(page, "MATCH STATUS", 0, 0, 226, 92)
    score.value = KWR.Theme:Font(score, 18, "white", "CENTER", "OUTLINE")
    score.value:SetPoint("TOPLEFT", 8, -34)
    score.value:SetPoint("TOPRIGHT", -8, -34)
    score.value:SetHeight(24)
    score.status = KWR.Theme:Font(score, 9, "green", "CENTER")
    score.status:SetPoint("TOPLEFT", 8, -62)
    score.status:SetPoint("TOPRIGHT", -8, -62)

    local nextCard = placeCard(page, "NEXT OBJECTIVE", 0, -100, 226, 94)
    nextCard.value = addValue(nextCard, "white", 11, -34)
    local mine = placeCard(page, "MY ASSIGNMENT", 0, -202, 226, 94)
    mine.value = addValue(mine, "blue", 11, -34)
    local target = placeCard(page, "KILL TARGET", 0, -304, 226, 110)
    target.value = addValue(target, "red", 11, -34)
    local events = placeCard(page, "LAST EVENTS", 0, -422, 226, 210)
    events.rows = {}
    for index = 1, 6 do
        local row = KWR.Theme:Font(events, 9, index % 2 == 0 and "muted" or "soft")
        row:SetPoint("TOPLEFT", 10, -34 - ((index - 1) * 27))
        row:SetPoint("TOPRIGHT", -10, -34 - ((index - 1) * 27))
        row:SetHeight(23)
        events.rows[index] = row
    end

    local mapCard = placeCard(page, "KWR REPORTER - LIVE BATTLEFIELD MOVEMENT", 236, 0, 674, 556)
    mapCard.mapName = KWR.Theme:Font(mapCard, 11, "white", "RIGHT", "OUTLINE")
    mapCard.mapName:SetPoint("TOPRIGHT", -10, -8)
    mapCard.mapName:SetWidth(300)
    mapCard.map = KWR.TacticalMap:Create(mapCard)
    mapCard.map:SetPoint("TOPLEFT", 10, -34)
    mapCard.map:SetPoint("BOTTOMRIGHT", -10, 38)
    mapCard.legend = KWR.Theme:Font(mapCard, 9, "muted", "CENTER")
    mapCard.reporterStatus = KWR.Theme:Font(mapCard, 9, "gold", "CENTER", "OUTLINE")
    mapCard.reporterStatus:SetPoint("BOTTOMLEFT", 10, 23)
    mapCard.reporterStatus:SetPoint("BOTTOMRIGHT", -10, 23)
    mapCard.legend:SetPoint("BOTTOMLEFT", 10, 7)
    mapCard.legend:SetPoint("BOTTOMRIGHT", -10, 7)
    mapCard.legend:SetText("|cff4f8cff[F] Friendly|r   |cffff3333[E] Enemy|r   |cffffd05a[!] Incoming / priority|r   |cffffd05a[K] Kill target|r   |cff888888[X] Dead|r")
    mapCard.formation = CreateFrame("Frame", nil, mapCard, "BackdropTemplate")
    mapCard.formation:SetPoint("TOPLEFT", 10, -34)
    mapCard.formation:SetPoint("BOTTOMRIGHT", -10, 38)
    KWR.Theme:Style(mapCard.formation, "background", "border")
    mapCard.formation.title = KWR.Theme:Title(mapCard.formation, 20, "CENTER")
    mapCard.formation.title:SetPoint("TOPLEFT", 20, -24)
    mapCard.formation.title:SetPoint("TOPRIGHT", -20, -24)
    mapCard.formation.title:SetHeight(28)
    mapCard.formation.summary = KWR.Theme:Font(mapCard.formation, 11, "soft", "CENTER")
    mapCard.formation.summary:SetPoint("TOPLEFT", 30, -60)
    mapCard.formation.summary:SetPoint("TOPRIGHT", -30, -60)
    mapCard.formation.summary:SetHeight(48)
    mapCard.formation.recruits = KWR.Theme:Font(mapCard.formation, 11, "white", "LEFT")
    mapCard.formation.recruits:SetPoint("TOPLEFT", 34, -135)
    mapCard.formation.recruits:SetWidth(270)
    mapCard.formation.recruits:SetHeight(270)
    mapCard.formation.positioning = KWR.Theme:Font(mapCard.formation, 10, "soft", "LEFT")
    mapCard.formation.positioning:SetPoint("TOPLEFT", 330, -135)
    mapCard.formation.positioning:SetPoint("TOPRIGHT", -30, -135)
    mapCard.formation.positioning:SetHeight(300)
    mapCard.formation:Hide()

    local timeline = placeCard(page, "COMMAND TIMELINE", 236, -564, 674, 68)
    timeline.rows = {}
    for index = 1, 5 do
        local row = KWR.Theme:Font(timeline, 8, index == 1 and "gold" or "muted", "CENTER")
        row:SetPoint("TOPLEFT", 10 + ((index - 1) * 130), -35)
        row:SetWidth(122)
        row:SetHeight(22)
        timeline.rows[index] = row
    end

    local win = placeCard(page, "WIN CONDITION", 920, 0, 284, 102)
    win.value = addValue(win, "white", 12, -34)
    local assignments = placeCard(page, "TEAM ASSIGNMENTS", 920, -110, 284, 224)
    assignments.rows = {}
    for index = 1, 6 do
        local row = KWR.Theme:Font(assignments, 9, index == 1 and "blue" or "soft")
        row:SetPoint("TOPLEFT", 10, -34 - ((index - 1) * 28))
        row:SetPoint("TOPRIGHT", -10, -34 - ((index - 1) * 28))
        row:SetHeight(22)
        assignments.rows[index] = row
    end
    local caller = placeCard(page, "TARGET CALLER", 920, -342, 284, 116)
    caller.value = addValue(caller, "purple", 11, -34)
    local focus = placeCard(page, "FOCUS TARGET", 920, -466, 284, 92)
    focus.value = addValue(focus, "red", 11, -34)
    local controls = placeCard(page, "COMMAND CONTROLS", 920, -566, 284, 66)
    local refresh = KWR.Theme:Button(controls, "REASSESS", 72, 23, function()
        KWR.MatchRuntime:Reassess()
    end)
    refresh:SetPoint("TOPLEFT", 10, -35)
    local copy = KWR.Theme:Button(controls, "COPY", 48, 23, function()
        local command = KWR.Store:Get().command
        KWR.CopyDialog:ShowCompact("KWR Compact Call", compactCommandText(KWR.Store:Get()))
    end)
    copy:SetPoint("LEFT", refresh, "RIGHT", 6, 0)
    local mini = KWR.Theme:Button(controls, "MINI", 54, 23, function()
        MainWindow:MinimizeTo("REPORTER")
    end)
    mini:SetPoint("LEFT", copy, "RIGHT", 6, 0)
    local options = KWR.Theme:Button(controls, "OPTIONS", 66, 23, function() KWR.Options:Toggle() end)
    options:SetPoint("LEFT", mini, "RIGHT", 6, 0)

    page.scoreCard, page.nextCard, page.mineCard = score, nextCard, mine
    page.targetCard, page.eventsCard, page.mapCard = target, events, mapCard
    page.timelineCard, page.winCard = timeline, win
    page.assignmentCard, page.callerCard, page.focusCard = assignments, caller, focus
end

function MainWindow:BuildObjectivesPage(page)
    local score = placeCard(page, "BATTLEFIELD SCORE", 0, 0, 286, 116)
    score.value = KWR.Theme:Font(score, 25, "white", "CENTER", "OUTLINE")
    score.value:SetPoint("TOPLEFT", 10, -38)
    score.value:SetPoint("TOPRIGHT", -10, -38)
    score.value:SetHeight(34)
    score.detail = KWR.Theme:Font(score, 9, "muted", "CENTER")
    score.detail:SetPoint("TOPLEFT", 10, -78)
    score.detail:SetPoint("TOPRIGHT", -10, -78)

    local status = placeCard(page, "MAP STATUS", 0, -124, 286, 292)
    status.rows = {}
    for index = 1, 9 do
        local row = KWR.Theme:Font(status, 10, index % 2 == 0 and "muted" or "soft")
        row:SetPoint("TOPLEFT", 10, -36 - ((index - 1) * 27))
        row:SetPoint("TOPRIGHT", -10, -36 - ((index - 1) * 27))
        row:SetHeight(22)
        status.rows[index] = row
    end
    local summary = placeCard(page, "MAP SUMMARY", 0, -424, 286, 208)
    summary.value = addValue(summary, "white", 10, -36)

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

    local conditions = placeCard(page, "WIN CONDITION", 908, 0, 296, 144)
    conditions.value = addValue(conditions, "white", 11, -36)
    local calls = placeCard(page, "QUICK CALLS", 908, -152, 296, 174)
    calls.buttons = {}
    calls.status = KWR.Theme:Font(calls, 8, "muted", "CENTER")
    calls.status:SetPoint("BOTTOMLEFT", 10, 8)
    calls.status:SetPoint("BOTTOMRIGHT", -10, 8)
    calls.status:SetHeight(14)
    calls.status:SetText("LEFT CLICK SENDS  |  RIGHT CLICK COPIES")
    for index, label in ipairs(KWR.QuickCalls:Definitions()) do
        local button = KWR.QuickCalls:CreateButton(calls, label, 132, 25, calls.status)
        button:SetPoint("TOPLEFT", 10 + (((index - 1) % 2) * 140), -36 - (math.floor((index - 1) / 2) * 34))
        calls.buttons[index] = button
    end
    local info = placeCard(page, "MAP INFO", 908, -334, 296, 180)
    info.value = addValue(info, "soft", 10, -36)
    local source = placeCard(page, "TRUTH CONTRACT", 908, -522, 296, 110)
    source.value = addValue(source, "muted", 9, -36)
    source.value:SetText("Score and objective control come from Blizzard public widgets. Unknown stays unknown. Fixed quick calls require an explicit player click.")

    page.scoreCard, page.statusCard, page.summaryCard = score, status, summary
    page.truthCard, page.conditionCard, page.callsCard, page.infoCard = truth, conditions, calls, info
end

function MainWindow:BuildTeamPage(page)
    local summary = placeCard(page, "COMMAND UNIT COMPOSITION", 0, 0, 1204, 92)
    summary.value = KWR.Theme:Font(summary, 17, "white", "CENTER", "OUTLINE")
    summary.value:SetPoint("TOPLEFT", 10, -35)
    summary.value:SetPoint("TOPRIGHT", -10, -35)
    summary.value:SetHeight(24)
    summary.detail = KWR.Theme:Font(summary, 9, "muted", "CENTER")
    summary.detail:SetPoint("TOPLEFT", 10, -63)
    summary.detail:SetPoint("TOPRIGHT", -10, -63)

    local roster = placeCard(page, "TEAM ROSTER", 0, -100, 850, 532)
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
    for index = 1, 15 do
        local row = createListRow(roster, index, -54 - ((index - 1) * 30), 850, 27)
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

    local doctrine = placeCard(page, "FORMATION DOCTRINE", 860, -100, 344, 252)
    doctrine.value = addValue(doctrine, "soft", 10, -36)
    local readiness = placeCard(page, "READINESS", 860, -360, 344, 142)
    readiness.value = addValue(readiness, "white", 11, -36)
    local controls = placeCard(page, "ROSTER CONTROLS", 860, -510, 344, 122)
    local refresh = KWR.Theme:Button(controls, "REFRESH", 92, 26, function()
        KWR.MatchRuntime:ForceRefresh("roster")
    end)
    refresh:SetPoint("TOPLEFT", 12, -40)
    local copy = KWR.Theme:Button(controls, "COPY", 92, 26, function()
        local lines = { "KWR FORMATION" }
        for _, assignment in ipairs(KWR.Store:Get().assignments or {}) do
            lines[#lines + 1] = assignment.shortName .. " - " .. assignment.role
        end
        KWR.CopyDialog:ShowText("KWR Formation", table.concat(lines, "\n"))
    end)
    copy:SetPoint("LEFT", refresh, "RIGHT", 10, 0)
    local mini = KWR.Theme:Button(controls, "MINIMIZE", 106, 26, function()
        MainWindow:MinimizeTo("ROSTER", "TEAM")
    end)
    mini:SetPoint("LEFT", copy, "RIGHT", 10, 0)
    controls.note = KWR.Theme:Font(controls, 9, "muted", "CENTER")
    controls.note:SetPoint("TOPLEFT", 12, -78)
    controls.note:SetPoint("TOPRIGHT", -12, -78)
    controls.note:SetText("Roster truth is collected once by the runtime and rendered here.")

    page.summaryCard, page.rosterCard = summary, roster
    page.doctrineCard, page.readinessCard = doctrine, readiness
end

function MainWindow:BuildEnemiesPage(page)
    local toolbar = placeCard(page, "KWR ENEMY TRACKER - ALL IN ONE", 0, 0, 1204, 58)
    toolbar.brand = KWR.Theme:Font(toolbar, 10, "soft")
    toolbar.brand:SetPoint("TOPLEFT", 12, -36)
    toolbar.brand:SetText("PRIORITY CLICK   |   LAST SEEN   |   CLASS / SPEC   |   HEALTH   |   LOCATION   |   COOLDOWNS   |   NOTES")
    toolbar.mode = KWR.Theme:Font(toolbar, 9, "gold", "RIGHT", "OUTLINE")
    toolbar.mode:SetPoint("TOPRIGHT", -12, -36)
    toolbar.mode:SetWidth(250)
    toolbar.minimize = KWR.Theme:Button(toolbar, "MINIMIZE", 92, 23, function()
        MainWindow:MinimizeTo("ROSTER", "ENEMY")
    end)
    toolbar.minimize:SetPoint("TOPRIGHT", -10, -31)
    toolbar.mode:ClearAllPoints()
    toolbar.mode:SetPoint("RIGHT", toolbar.minimize, "LEFT", -10, 0)
    toolbar.mode:SetWidth(240)

    local tracker = placeCard(page, "ENEMY INTELLIGENCE", 0, -66, 902, 566)
    addColumnHeaders(tracker, {
        { label = "PRI", x = 12, width = 32, justify = "CENTER" },
        { label = "SEEN", x = 49, width = 56, justify = "CENTER" },
        { label = "SPEC / NAME", x = 142, width = 150 },
        { label = "HEALTH", x = 300, width = 130, justify = "CENTER" },
        { label = "LOCATION", x = 440, width = 105 },
        { label = "TRINKET", x = 550, width = 76, justify = "CENTER" },
        { label = "DEFENSIVES", x = 632, width = 102, justify = "CENTER" },
        { label = "NOTE", x = 742, width = 142, justify = "CENTER" },
    })
    tracker.rows = {}
    for index = 1, 12 do
        local row = createListRow(tracker, index, -52 - ((index - 1) * 40), 902, 36)
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
        row.name:SetPoint("TOPLEFT", 134, -5)
        row.name:SetWidth(150)
        row.spec = KWR.Theme:Font(row, 8, "muted")
        row.spec:SetPoint("BOTTOMLEFT", 134, 5)
        row.spec:SetWidth(150)
        row.health = CreateFrame("StatusBar", nil, row, "BackdropTemplate")
        row.health:SetPoint("LEFT", 292, 0)
        row.health:SetSize(130, 18)
        row.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        KWR.Theme:Style(row.health, "background", "border")
        row.healthText = KWR.Theme:Font(row.health, 8, "white", "CENTER", "OUTLINE")
        row.healthText:SetAllPoints()
        row.location = KWR.Theme:Font(row, 9, "gold")
        row.location:SetPoint("LEFT", 432, 0)
        row.location:SetWidth(105)
        row.trinket = KWR.Theme:Font(row, 9, "muted", "CENTER")
        row.trinket:SetPoint("LEFT", 542, 0)
        row.trinket:SetWidth(76)
        row.cooldown = KWR.Theme:Font(row, 8, "muted", "CENTER")
        row.cooldown:SetPoint("LEFT", 624, 0)
        row.cooldown:SetWidth(102)
        row.note = KWR.Theme:Button(row, "ADD NOTE", 142, 26, function()
            if row.enemyKey then MainWindow:ShowEnemyNote(row.enemyKey) end
        end)
        row.note:SetPoint("LEFT", 734, 0)
        tracker.rows[index] = row
    end
    tracker.empty = KWR.Theme:Font(tracker, 13, "muted", "CENTER")
    tracker.empty:SetPoint("CENTER", 0, 0)
    tracker.empty:SetWidth(600)
    tracker.empty:SetText("NO ENEMY INTELLIGENCE YET\nEnemy roster data appears when Blizzard exposes the battleground scoreboard.")

    local contract = placeCard(page, "COLUMN EXPLANATION", 912, -66, 292, 214)
    contract.value = addValue(contract, "soft", 9, -36)
    contract.value:SetText(table.concat({
        "|cffffd05a1  Priority|r - manual command mark",
        "|cffffd05a2  Last Seen|r - observed unit age",
        "|cffffd05a3  Spec / Name|r - scoreboard truth",
        "|cffffd05a4  Health|r - visible units only",
        "|cffffd05a5  Location|r - observation source",
        "|cffffd05a6  Cooldowns|r - unknown unless proven",
        "|cffffd05a7  Notes|r - your persisted field note",
    }, "\n"))
    local priority = placeCard(page, "PRIORITY SYSTEM", 912, -288, 292, 132)
    priority.value = addValue(priority, "soft", 10, -36)
    priority.value:SetText("|cffffd43b[K]|r Kill / CC priority\n|cffff6a2f[H]|r High priority\n|cff49dd49[M]|r Medium priority\n|cff777777[O]|r Observe")
    local tracking = placeCard(page, "TRACKING CONTRACT", 912, -428, 292, 204)
    tracking.value = addValue(tracking, "muted", 9, -36)
    tracking.value:SetText(table.concat({
        "Roster: Blizzard PvP scoreboard",
        "Seen: target, focus, mouseover,",
        "nameplates and ally targets",
        "",
        "Cooldown and aura fields never",
        "claim data the client did not expose.",
        "",
        "Clicks use pre-bound secure buttons.",
        "No automatic targeting or actions.",
    }, "\n"))

    page.toolbar, page.trackerCard = toolbar, tracker
end

function MainWindow:BuildAssignmentsPage(page)
    local command = placeCard(page, "SMART ASSIGNMENTS - KNOW YOUR JOB. DO IT. WIN.", 0, 0, 1204, 92)
    command.value = KWR.Theme:Font(command, 15, "white", "CENTER", "OUTLINE")
    command.value:SetPoint("TOPLEFT", 10, -36)
    command.value:SetPoint("TOPRIGHT", -10, -36)
    command.value:SetHeight(22)
    command.detail = KWR.Theme:Font(command, 9, "muted", "CENTER")
    command.detail:SetPoint("TOPLEFT", 10, -64)
    command.detail:SetPoint("TOPRIGHT", -10, -64)

    local board = placeCard(page, "ONE PLAYER - ONE JOB - ONE LOCATION", 0, -100, 886, 532)
    addColumnHeaders(board, {
        { label = "PLAYER", x = 16, width = 200 },
        { label = "SPEC / CLASS / ROLE", x = 226, width = 190 },
        { label = "BATTLEFIELD JOB", x = 426, width = 200 },
        { label = "LOCATION", x = 636, width = 150 },
        { label = "PRI", x = 796, width = 70, justify = "CENTER" },
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
    mine.value = addValue(mine, "blue", 13, -38)
    local logic = placeCard(page, "ASSIGNMENT LOGIC", 896, -254, 308, 246)
    logic.value = addValue(logic, "soft", 10, -36)
    local controls = placeCard(page, "MANUAL HANDOFF", 896, -508, 308, 124)
    local copy = KWR.Theme:Button(controls, "COPY COMPACT CALL", 180, 28, function()
        local state = KWR.Store:Get()
        KWR.CopyDialog:ShowCompact("KWR Compact Assignments",
            KWR.Assignments:CompactExport(state.assignments,
                state.snapshot.context.mapKey))
    end)
    copy:SetPoint("TOP", 0, -40)
    controls.note = KWR.Theme:Font(controls, 9, "muted", "CENTER")
    controls.note:SetPoint("TOPLEFT", 10, -80)
    controls.note:SetPoint("TOPRIGHT", -10, -80)
    controls.note:SetText("KWR prepares text. You choose when and where to send it.")

    page.commandCard, page.boardCard = command, board
    page.mineCard, page.logicCard = mine, logic
end

function MainWindow:BuildIntelPage(page)
    local summary = placeCard(page, "KWR LEARNING LIBRARY", 0, 0, 1204, 90)
    summary.value = KWR.Theme:Font(summary, 16, "white", "CENTER", "OUTLINE")
    summary.value:SetPoint("TOPLEFT", 10, -34)
    summary.value:SetPoint("TOPRIGHT", -10, -34)
    summary.value:SetHeight(23)
    summary.detail = KWR.Theme:Font(summary, 9, "muted", "CENTER")
    summary.detail:SetPoint("TOPLEFT", 10, -62)
    summary.detail:SetPoint("TOPRIGHT", -10, -62)

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

    local insights = placeCard(page, "AAR INSIGHTS", 830, -98, 374, 338)
    insights.value = addValue(insights, "soft", 11, -38)
    local doctrine = placeCard(page, "MAP DOCTRINE", 0, -444, 820, 188)
    doctrine.value = addValue(doctrine, "soft", 10, -36)
    local review = placeCard(page, "AFTER ACTION REVIEW", 830, -444, 374, 188)
    review.value = KWR.Theme:Font(review, 10, "soft")
    review.value:SetPoint("TOPLEFT", 12, -38)
    review.value:SetPoint("TOPRIGHT", -12, -38)
    review.value:SetHeight(78)
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
    frame:SetSize(440, 190)
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
    frame.edit:SetSize(412, 80)
    frame.edit:SetMultiLine(true)
    frame.edit:SetAutoFocus(false)
    frame.help = KWR.Theme:Font(frame, 9, "muted")
    frame.help:SetPoint("TOPLEFT", 16, -132)
    frame.help:SetText("Persisted locally. No note is transmitted automatically.")
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
    local enemy
    for _, row in ipairs(KWR.Store:Get().snapshot.enemies or {}) do
        if row.key == key then enemy = row break end
    end
    if not enemy then return end
    self.noteEditor.enemyKey = key
    self.noteEditor.title:SetText("ENEMY FIELD NOTE  |  " .. enemy.shortName)
    self.noteEditor.edit:SetText(enemy.note or "")
    self.noteEditor:Show()
end

function MainWindow:SetPage(key)
    if not self.pages[key] then key = "TACTICAL" end
    for pageKey, page in pairs(self.pages) do
        page:SetShown(pageKey == key)
        local tab = self.tabs[pageKey]
        if tab then
            KWR.Theme:Style(tab, pageKey == key and "raised" or "card", pageKey == key and "borderHi" or "border")
            tab.label:SetTextColor(KWR.Theme:Color(pageKey == key and "gold" or "soft"))
        end
    end
    KWR.db.profile.main.page = key
    self.activePage = key
    self:Update(KWR.Store:Get())
end

function MainWindow:UpdateTactical(state)
    local page = self.pages.TACTICAL
    local snapshot, command, prediction = state.snapshot, state.command, state.prediction
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    local short = definition and definition.short or "WORLD"
    local formation = snapshot.formation or {}
    local formationMode = not snapshot.context.inPvP
    page.nextCard.heading:SetText(formationMode and "ROSTER ACTION"
        or (snapshot.reassessment and "REASSESS RESULT" or "NEXT OBJECTIVE"))
    page.targetCard.heading:SetText(formationMode and "RECRUIT PRIORITY" or "KILL TARGET")
    page.winCard.heading:SetText(formationMode and "COMPOSITION PLAN" or "WIN CONDITION")
    page.callerCard.heading:SetText(formationMode and "LEADERSHIP SETUP" or "TARGET CALLER")
    page.focusCard.heading:SetText(formationMode and "READY CHECK" or "FOCUS TARGET")
    if not snapshot.context.inPvP then
        page.scoreCard.value:SetText(string.format("|cff4f8cffFORMATION %d|r / %d",
            formation.players or 0, formation.targetSize or 10))
    else
        page.scoreCard.value:SetText(string.format("|cff4f8cff%s %d|r  -  |cffff3333%d|r",
            short, snapshot.score.friendly or 0, snapshot.score.enemy or 0))
    end
    page.scoreCard.status:SetText(command.status .. "  |  " .. tostring(command.confidence) .. " CONFIDENCE")
    page.scoreCard.status:SetTextColor(KWR.Theme:Color(statusColor(command.status)))
    page.nextCard.value:SetText(command.action .. "\n|cff777b83" .. command.when .. "|r")
    local mine = selfAssignment(state)
    page.mineCard.value:SetText(mine and (mine.role .. "\n|cffb7bdc7" .. mine.location .. "|r") or "Formation assignment pending.")
    local enemy = primaryEnemy(state)
    if not snapshot.context.inPvP and formation.recommendations and formation.recommendations[1] then
        local recruits = {}
        for index = 1, math.min(3, #formation.recommendations) do
            local recruit = formation.recommendations[index]
            recruits[#recruits + 1] = recruit.label .. " (" .. recruit.role .. ")"
        end
        page.targetCard.value:SetText("RECRUIT NEXT\n|cffffd05a" .. table.concat(recruits, "\n") .. "|r")
    elseif enemy then
        page.targetCard.value:SetText(enemy.shortName .. "  |  " .. enemy.spec .. "\n"
            .. (enemy.age and ("Last seen " .. KWR.Util:Age(enemy.age) .. " ago") or "Roster known")
            .. (enemy.note and enemy.note ~= "" and ("\n|cffffd05a" .. enemy.note .. "|r") or ""))
    else
        page.targetCard.value:SetText("No enemy intelligence acquired.")
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
    if #eventLines == 0 and snapshot.lastMessage and snapshot.lastMessage ~= "" then eventLines[1] = snapshot.lastMessage end
    for index, row in ipairs(page.eventsCard.rows) do
        row:SetText(eventLines[index] or (index == 1 and "No battleground system events observed." or ""))
    end

    page.mapCard.mapName:SetText(snapshot.context.mapName .. "  |  " .. command.status)
    local reporter = snapshot.reporter or {}
    page.mapCard.heading:SetText(formationMode and "COMMAND UNIT - FORMATION BRIEFING"
        or "KWR REPORTER - LIVE BATTLEFIELD MOVEMENT")
    page.mapCard.map:SetShown(not formationMode)
    page.mapCard.legend:SetShown(not formationMode)
    page.mapCard.formation:SetShown(formationMode)
    if formationMode then
        local tierMatch = formation.tierMatch and formation.tierMatch.qualified
            and formation.tierMatch or nil
        local recruitLines = { "|cffffd05aBEST-FIT RECRUITS|r" }
        for index, recruit in ipairs(formation.recommendations or {}) do
            recruitLines[#recruitLines + 1] = tostring(index) .. ". " .. recruit.label
                .. "  [" .. recruit.role .. " / " .. tostring(recruit.acquisition or "OPEN SLOT") .. "]"
        end
        if #recruitLines == 1 then recruitLines[#recruitLines + 1] = "Roster roles are complete." end
        local positionLines = { "|cffffd05aPOSITIONING KEYS|r" }
        for index, text in ipairs(formation.positioning or {}) do
            positionLines[#positionLines + 1] = tostring(index) .. ". " .. text
        end
        page.mapCard.formation.title:SetText(tierMatch
            and (tierMatch.tier .. "  " .. tierMatch.name)
            or (formation.archetype and formation.archetype.name or "Balanced Team Fight"))
        page.mapCard.formation.summary:SetText((formation.players or 0) .. " / "
            .. (formation.targetSize or 10) .. " PLAYERS  |  NEED: "
            .. (formation.needText or "Roster complete") .. "\n"
            .. (tierMatch and (tierMatch.confidence .. ": " .. tierMatch.win)
                or (formation.archetype and formation.archetype.description
                    or "Build a complete command unit.")))
        page.mapCard.formation.recruits:SetText(table.concat(recruitLines, "\n\n"))
        page.mapCard.formation.positioning:SetText(table.concat(positionLines, "\n\n"))
    end
    page.mapCard.reporterStatus:SetText(not snapshot.context.inPvP
        and ((formation.reason or "Build the command unit.")
            .. " " .. (formation.positioning and formation.positioning[1] or ""))
        or (reporter.summary or "Reporter standing by."))
    page.mapCard.reporterStatus:SetTextColor(KWR.Theme:Color((reporter.risk or 0) >= 70 and "red"
        or ((reporter.risk or 0) >= 45 and "yellow" or "gold")))
    if not formationMode then page.mapCard.map:SetState(state) end
    local strategy = snapshot.strategy or {}
    local formationTier = formation.tierMatch and formation.tierMatch.qualified
        and formation.tierMatch or nil
    page.winCard.value:SetText((not snapshot.context.inPvP
        and (formationTier
            and (formationTier.tier .. " " .. formationTier.name .. ": " .. formationTier.win)
            or ((formation.archetype and formation.archetype.name or "Balanced Team Fight")
                .. ": " .. (formation.archetype and formation.archetype.description
                    or "Build a complete roster.")))
        or (prediction.condition or "Waiting for battlefield truth."))
        .. "\n|cffffd05a" .. (command.action
            or strategy.action or prediction.action or "") .. "|r"
        .. (KWR.db.profile.guidanceMode == "LEARNING" and strategy.switchIf
            and ("\n|cff8ea3bbSWITCH: " .. KWR.Util:Text(strategy.switchIf, "", 80) .. "|r") or ""))
    local changes = snapshot.reassessment and snapshot.reassessment.changes
    page.assignmentCard.heading:SetText(changes and #changes > 0
        and "REASSESSMENT - ASSIGNMENT CHANGES" or "TEAM ASSIGNMENTS")
    for index, row in ipairs(page.assignmentCard.rows) do
        local change = changes and changes[index]
        local assignment = state.assignments[index]
        row:SetText(change and ("|cff4f8cff" .. change.name .. "|r  "
                .. KWR.Assignments:CompactRole(change.fromRole)
                .. "@" .. KWR.Maps:AbbreviateLocation(
                    snapshot.context.mapKey, change.fromLocation)
                .. " -> |cffffd05a"
                .. KWR.Assignments:CompactRole(change.toRole)
                .. "@" .. KWR.Maps:AbbreviateLocation(
                    snapshot.context.mapKey, change.toLocation) .. "|r")
            or (assignment and ("|cff4f8cff" .. assignment.shortName .. "|r  "
                .. assignment.role .. "  ->  |cffffd05a" .. assignment.location .. "|r") or ""))
    end
    if formationMode then
        page.callerCard.value:SetText("Assign target caller + backup\nAssign base/route lead\nConfirm voice discipline")
        page.focusCard.value:SetText("Voice | PvP talents | gear\nConsumables | queue leader")
    else
        page.callerCard.value:SetText((command.callVerb or "SEND") .. ": "
            .. (command.callMovers or command.who or "Team")
            .. "\n|cffb7bdc7WHEN: " .. tostring(command.when or "NOW")
            .. " | " .. tostring(command.confidence or "NONE") .. "|r"
            .. "\nCALL: " .. KWR.Util:Text(command.action, "", 110))
        page.focusCard.value:SetText(enemy and (enemy.shortName .. "\nFocus CC / kill pressure") or "No focus target selected.")
    end

    local history = KWR.Commander:GetHistory()
    local start = math.max(1, #history - 4)
    for index, row in ipairs(page.timelineCard.rows) do
        local item = history[start + index - 1]
        row:SetText(item and (item.status .. "\n" .. KWR.Util:Text(item.action, "", 18)) or "--")
    end
end

function MainWindow:Explain()
    local state = KWR.Store:Get()
    local command = state.command
    local strategy = state.snapshot.strategy or {}
    local formation = state.snapshot.formation or {}
    if not state.snapshot.context.inPvP then
        local recruits, positioning = {}, {}
        local tierMatch = formation.tierMatch and formation.tierMatch.qualified
            and formation.tierMatch or nil
        for _, recruit in ipairs(formation.recommendations or {}) do
            recruits[#recruits + 1] = recruit.label .. " [" .. tostring(recruit.acquisition or "OPEN SLOT")
                .. "] - " .. recruit.reason
        end
        for index, text in ipairs(formation.positioning or {}) do
            positioning[#positioning + 1] = tostring(index) .. ". " .. text
        end
        KWR.CopyDialog:ShowText("KWR Formation Plan", table.concat({
            "COMMAND UNIT FORMATION",
            tostring(formation.players or 0) .. " / " .. tostring(formation.targetSize or 10) .. " players",
            "NEED: " .. tostring(formation.needText or "Roster complete"),
            "ARCHETYPE: " .. tostring(tierMatch
                and (tierMatch.tier .. " " .. tierMatch.name)
                or (formation.archetype and formation.archetype.name or "Balanced Team Fight")),
            "MATCH: " .. tostring(tierMatch and tierMatch.confidence or "GENERIC"),
            "HOW IT WINS: " .. tostring(tierMatch and tierMatch.win
                or (formation.archetype and formation.archetype.description
                    or "Flexible objective play.")),
            "ROLE PACKAGE: " .. tostring(tierMatch and tierMatch.assignments
                or "Use capability-weighted formation roles."),
            "",
            "BEST RECRUITS:",
            #recruits > 0 and table.concat(recruits, "\n") or "Roster complete.",
            "",
            "POSITIONING KEYS:",
            table.concat(positioning, "\n"),
        }, "\n"))
        return
    end
    local alternatives = {}
    for _, alternative in ipairs(strategy.alternatives or {}) do
        alternatives[#alternatives + 1] = (alternative.feasible and "READY  " or "BLOCKED  ")
            .. alternative.id .. " - " .. alternative.action
    end
    local learning = KWR.Learning:Summary()
    local decision = strategy.objectiveDecision or {}
    local counter = strategy.counter or {}
    local confidenceEvidence = {}
    for _, item in ipairs(strategy.confidenceBudget
        and strategy.confidenceBudget.evidence or {}) do
        confidenceEvidence[#confidenceEvidence + 1] =
            (item.available and "YES " or "NO  ") .. item.name
            .. " [" .. tostring(item.points or 0) .. "]"
            .. (item.detail and (" - " .. tostring(item.detail)) or "")
    end
    local simulations = {}
    for _, candidate in ipairs(strategy.simulations or {}) do
        simulations[#simulations + 1] = string.format(
            "%s score %d [%s] @ %s - %s RISK: %s",
            candidate.id, candidate.decisionScore
                or candidate.probability or 0,
            candidate.projection or "UNKNOWN",
            candidate.target or "unverified",
            candidate.outcome or "Unknown",
            candidate.risk or "Unknown")
    end
    local reporter = state.snapshot.reporter or {}
    local etaLines = {}
    for index = 1, math.min(3, #(reporter.etas or {})) do
        local eta = reporter.etas[index]
        etaLines[#etaLines + 1] = string.format(
            "%s F:%s E:%s edge:%s [%s]",
            eta.label,
            eta.friendlyETA and (tostring(eta.friendlyETA) .. "s") or "?",
            eta.enemyETA and (tostring(eta.enemyETA) .. "s") or "?",
            eta.advantage and (tostring(eta.advantage) .. "s") or "?",
            eta.confidence or "LOW")
    end
    local opportunity = strategy.opportunity or {}
    local intent = reporter.enemyIntent or {}
    local momentum = reporter.momentum or {}
    local resources = state.snapshot.combat
        and state.snapshot.combat.resourceEconomy or {}
    local integrity = state.snapshot.assignmentIntegrity or {}
    local execution = strategy.executionAssessment or {}
    local executionAction = execution.actionOpportunity or {}
    local commitment = execution.commitment or {}
    local pressureForecast = execution.pressureForecast or {}
    local reinforcement = execution.reinforcement or {}
    local rotationEconomy = execution.rotationEconomy or {}
    local collapse = execution.collapse or {}
    local recovery = execution.recovery or {}
    local organization = execution.organization or {}
    local response = state.snapshot.responsePackage or {}
    local truth = state.snapshot.truth or {}
    local truthSummary = truth.summary or {}
    local responseContract = strategy.responseContract or {}
    local horizons = execution.horizons or {}
    local integrityLines = {}
    for _, row in ipairs(integrity.reassignments or {}) do
        integrityLines[#integrityLines + 1] = row.name .. " " .. row.status
            .. " @ " .. row.actual .. " -> " .. row.expected
            .. " | replace: " .. tostring(row.replacement or "nearest floater")
    end
    local coverageLines = {}
    for _, row in ipairs(integrity.coverageLedger or {}) do
        coverageLines[#coverageLines + 1] = string.format(
            "%s %s | %d/%d | backup %s | enemy-known %d",
            row.location or "Unknown", row.state or "UNKNOWN",
            row.assigned or 0, row.required or 0,
            row.backup or "none", row.enemyKnown or 0)
    end
    KWR.CopyDialog:ShowText("KWR Decision Explanation", table.concat({
        command.line1,
        command.line2,
        command.line3,
        "",
        "PLAN: " .. tostring(command.planID or "No reviewed plan"),
        "OUR COMPOSITION: " .. tostring(command.ourComposition or "Unknown"),
        "ENEMY COMPOSITION: " .. tostring(command.enemyComposition or "Unknown"),
        "WHY: " .. tostring(command.reason),
        string.format("DECISION: %s | score %s/100 [%s; heuristic] | confidence %s/100 %s | risk %s",
            tostring(strategy.recommendationMode or "HOLD"),
            tostring(strategy.decisionScore or 0),
            tostring(strategy.projection or "UNKNOWN"),
            tostring(strategy.confidenceBudget and strategy.confidenceBudget.score or 0),
            tostring(strategy.confidence or "NONE"),
            tostring(strategy.risk or "HIGH")),
        "EXPECTED: " .. tostring(strategy.expectedOutcome or "Unknown"),
        "COUNTERPLAY: " .. tostring(command.counterplay or "No composition counter available."),
        "WEIGHTED FOCUS: " .. weightedFocusText(strategy),
        "SUCCESS WHEN: " .. tostring(decision.success or "The objective changes as called."),
        "ABORT WHEN: " .. tostring(decision.abort or "The scoring path or commitment changes."),
        "COUNTER SEQUENCE: " .. tostring(counter.sequence
            and table.concat(counter.sequence, " -> ") or "No reviewed sequence available."),
        "SWITCH IF: " .. tostring(command.switchIf or "Authoritative state changes."),
        "DO NOT: " .. tostring(command.avoid or "Take low-value fights."),
        string.format("TRUTH: %d%% usable | verified %d | stale %d | aggressive commit %s",
            truthSummary.coverage or 0, truthSummary.verified or 0,
            truthSummary.stale or 0,
            truth.aggressiveCommitAllowed and "ALLOWED" or "GATED"),
        "SCENARIO TRIGGER: " .. tostring(
            responseContract.trigger or "Unverified"),
        "LIKELY COUNTER: " .. tostring(
            responseContract.likelyCounter or "Unknown"),
        "COUNTER RESPONSE: " .. tostring(
            responseContract.counterResponse or "Verify then reassess."),
        "",
        "CONFIDENCE EVIDENCE:",
        #confidenceEvidence > 0 and table.concat(confidenceEvidence, "\n")
            or "No qualified evidence.",
        "",
        "CANDIDATE SIMULATION:",
        #simulations > 0 and table.concat(simulations, "\n") or "Unavailable.",
        "",
        "TIMING / INTENT:",
        #etaLines > 0 and table.concat(etaLines, "\n") or "No legal coordinate ETA.",
        "Enemy intent: " .. tostring(intent.target or "Unknown")
            .. " | " .. tostring(intent.confidence or "NONE")
            .. " | ETA " .. tostring(intent.eta or "?") .. "s",
        "Momentum: " .. tostring(momentum.state or "UNKNOWN")
            .. " " .. tostring(momentum.value or 0)
            .. " | " .. tostring(momentum.confidence or "LOW"),
        "",
        "OPPORTUNITY WINDOW: " .. (opportunity.open and "OPEN" or "CLOSED")
            .. " | " .. tostring(opportunity.duration or 0) .. "s | "
            .. tostring(opportunity.confidence or "LOW"),
        #(opportunity.evidence or {}) > 0 and table.concat(opportunity.evidence, ", ")
            or "No verified temporary advantage.",
        string.format("RESOURCE ECONOMY: edge %d | %s | enemy trinkets %d, defensives used %d, active %d",
            resources.advantage or 0, resources.confidence or "NONE",
            resources.enemy and resources.enemy.trinketsUsed or 0,
            resources.enemy and resources.enemy.defensivesUsed or 0,
            resources.enemy and resources.enemy.activeDefensives or 0),
        "",
        "EXECUTION ASSESSMENT:",
        string.format("Best action: %s @ %s | score %d | confidence %s/%d",
            tostring(executionAction.action or "UNKNOWN"),
            tostring(executionAction.target or commitment.objective or "Unknown"),
            executionAction.score or 0,
            tostring(execution.confidence or "NONE"),
            execution.confidenceScore or 0),
        "Reason: " .. tostring(executionAction.reason
            or "No qualified execution veto."),
        string.format("Commitment: %s @ %s | excess %d",
            tostring(commitment.state or "UNKNOWN"),
            tostring(commitment.objective or "Unknown"),
            commitment.excess or 0),
        string.format("Pressure: %s @ %s | score %d | enemy ETA %s",
            tostring(pressureForecast.state or "UNKNOWN"),
            tostring(pressureForecast.target or "Unknown"),
            pressureForecast.score or 0,
            pressureForecast.eta and (tostring(pressureForecast.eta) .. "s")
                or "Unknown"),
        string.format("Reinforcement: %s | friendly %s | enemy %s | edge %s",
            tostring(reinforcement.side or "UNKNOWN"),
            reinforcement.friendlyETA
                and (tostring(reinforcement.friendlyETA) .. "s") or "Unknown",
            reinforcement.enemyETA
                and (tostring(reinforcement.enemyETA) .. "s") or "Unknown",
            reinforcement.advantage
                and (tostring(reinforcement.advantage) .. "s") or "Unknown"),
        string.format("Rotation: %s | value %d | leaving cost %s",
            tostring(rotationEconomy.state or "UNKNOWN"),
            rotationEconomy.value or 0,
            tostring(rotationEconomy.leavingCost or "Unknown")),
        string.format("Collapse: %s %d | response %s | Recovery: %s %d",
            tostring(collapse.state or "UNKNOWN"), collapse.score or 0,
            tostring(collapse.response or "HOLD_PLAN"),
            recovery.open and "OPEN" or "CLOSED", recovery.score or 0),
        string.format("Organization: %s | entropy %d",
            tostring(organization.state or "UNKNOWN"),
            organization.entropy or 0),
        string.format("Response package: %s | qualified %s",
            tostring(response.action or "HOLD CURRENT PLAN"),
            response.qualified and "YES" or "NO"),
        string.format("Horizons: 5s %s | 15s %s @ %s | 30s %s",
            horizons.immediate and horizons.immediate.state or "UNKNOWN",
            horizons.engagement and horizons.engagement.state or "UNKNOWN",
            horizons.engagement and horizons.engagement.target or "Unknown",
            horizons.strategic and horizons.strategic.state or "UNKNOWN"),
        "MOVE: " .. tostring(response.moverText or "Team"),
        "STAY: " .. tostring(response.stayerText or "Assigned defenders"),
        "",
        "ASSIGNMENT INTEGRITY:",
        string.format("on station %d | moving %d | unknown %d | abandoned %d | impossible %d",
            integrity.onStation or 0, integrity.moving or 0,
            integrity.unverified or 0, integrity.abandoned or 0,
            integrity.impossible or 0),
        #integrityLines > 0 and table.concat(integrityLines, "\n")
            or "No reassignment required.",
        #coverageLines > 0 and table.concat(coverageLines, "\n")
            or "No verified objective coverage ledger.",
        "",
        "ALTERNATIVES:",
        #alternatives > 0 and table.concat(alternatives, "\n") or "None",
        "",
        "LEARNING: " .. tostring(learning.samples) .. " reviewed samples across "
            .. tostring(learning.plans) .. " plans.",
    }, "\n"))
end

function MainWindow:ShowPerformance()
    local diagnostics = KWR.Store:Get().diagnostics or {}
    local boot = KWR.bootDiagnostics or {}
    local capabilityCache = KWR.Capabilities:CacheStats()
    local decisionCache = KWR.Strategist:CacheStats()
    local moduleTimes = {}
    for name, duration in pairs(boot.moduleMs or {}) do
        moduleTimes[#moduleTimes + 1] = { name = name, duration = duration }
    end
    table.sort(moduleTimes, function(a, b) return a.duration > b.duration end)
    local slowModules = {}
    for index = 1, math.min(5, #moduleTimes) do
        slowModules[#slowModules + 1] = string.format("%s %.3f ms",
            moduleTimes[index].name, moduleTimes[index].duration)
    end
    KWR.CopyDialog:ShowText("KWR Performance", table.concat({
        "KWR PERFORMANCE TELEMETRY",
        string.format("Boot module initialization: %.3f ms", boot.initializeMs or 0),
        "Slowest initialization: " .. (#slowModules > 0 and table.concat(slowModules, ", ") or "unavailable"),
        string.format("Last world transition refresh: %.3f ms", diagnostics.lastTransitionDurationMs or 0),
        "Transition refreshes: " .. tostring(diagnostics.transitionRefreshes or 0),
        "Lightweight health/aura events: " .. tostring(diagnostics.lightweightEvents or 0),
        "",
        "Refreshes: " .. tostring(diagnostics.refreshes or 0),
        "Events: " .. tostring(diagnostics.events or 0),
        "Coalesced events: " .. tostring(diagnostics.coalesced or 0),
        "Newest-truth followups: " .. tostring(
            diagnostics.queueFollowups or 0),
        "Earlier refresh preemptions: " .. tostring(
            diagnostics.queuePreemptions or 0),
        "Load/widget settle refreshes: " .. tostring(
            diagnostics.settleRefreshes or 0),
        string.format("Last: %.3f ms", diagnostics.lastDurationMs or 0),
        string.format("Average: %.3f ms", diagnostics.averageDurationMs or 0),
        string.format("P95: %.3f ms", diagnostics.p95DurationMs or 0),
        string.format("Maximum: %.3f ms", diagnostics.maxDurationMs or 0),
        string.format("Lua memory: %.1f KB", diagnostics.memoryKB or 0),
        string.format("Capability cache: %d hits / %d misses / %d entries",
            capabilityCache.hits or 0, capabilityCache.misses or 0,
            capabilityCache.entries or 0),
        string.format("Decision cache: %d hits / %d misses",
            decisionCache.hits or 0, decisionCache.misses or 0),
        string.format("Execution cache: %d hits / %d misses",
            decisionCache.executionHits or 0,
            decisionCache.executionMisses or 0),
        string.format("HUD renders skipped: %d / updated: %d",
            KWR.HUD.renderSkips or 0, KWR.HUD.renderUpdates or 0),
        string.format("Roster row renders skipped: %d / updated: %d",
            KWR.CombatRoster.renderSkips or 0, KWR.CombatRoster.renderUpdates or 0),
        "Runtime errors: " .. tostring(diagnostics.errors or 0),
        "",
        "Testing target: P95 < 2 ms, routine max < 4 ms, stable memory.",
    }, "\n"))
end

function MainWindow:UpdateObjectives(state)
    local page = self.pages.OBJECTIVES
    local snapshot, prediction = state.snapshot, state.prediction
    local friendly, enemy, friendlyIncoming, enemyIncoming = objectiveCounts(snapshot)
    page.scoreCard.value:SetText(string.format("|cff4f8cff%d|r  -  |cffff3333%d|r",
        snapshot.score.friendly or 0, snapshot.score.enemy or 0))
    page.scoreCard.detail:SetText(snapshot.context.mapName .. "  |  MAX " .. tostring(snapshot.score.max or 0))
    local rows = {
        "Friendly controlled: " .. friendly,
        "Enemy controlled: " .. enemy,
        "Friendly incoming: " .. friendlyIncoming,
        "Enemy incoming: " .. enemyIncoming,
        "Carriers known: " .. tostring(#(snapshot.objectives.carriers or {})),
        "Assigned team: " .. tostring(snapshot.context.team and snapshot.context.team.faction or "Unknown"),
        "Score confidence: " .. truthLabel(snapshot.score.source),
        "Objective confidence: " .. truthLabel(snapshot.objectives.source),
        "Ruleset: " .. (snapshot.context.isBlitz and "BLITZ" or "STANDARD"),
    }
    for index, row in ipairs(page.statusCard.rows) do row:SetText(rows[index] or "") end
    local summaryLines = {
        "PROJECTED STATE  " .. tostring(prediction.status),
        "",
        "Friendly clock  " .. (prediction.friendlyTime and KWR.Util:Clock(prediction.friendlyTime) or "--"),
        "Enemy clock     " .. (prediction.enemyTime and KWR.Util:Clock(prediction.enemyTime) or "--"),
        "",
        "Urgency         " .. tostring(prediction.urgency or 0),
        "Confidence      " .. tostring(prediction.confidence or "NONE"),
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
            row.state:SetText(KWR.Util:Text(objective.state, "WATCH", 12))
            row.source:SetText(truthLabel(objective.source))
        end
    end
    page.conditionCard.value:SetText((prediction.condition or "Waiting.")
        .. "\n\n|cffffd05a" .. (prediction.action or "") .. "|r")
    local definition = KWR.Maps:Get(snapshot.context.mapKey)
    page.infoCard.value:SetText(table.concat({
        "Map       " .. snapshot.context.mapName,
        "Type      " .. snapshot.context.kind,
        "Short     " .. (definition and definition.short or "--"),
        "Max score " .. tostring(snapshot.score.max or 0),
        "Priority  " .. (definition and table.concat(definition.priorities or {}, ", ") or "--"),
        "",
        "Last event",
        snapshot.lastMessage ~= "" and snapshot.lastMessage or "None observed.",
    }, "\n"))
end

function MainWindow:UpdateTeam(state)
    local page = self.pages.TEAM
    local roster = state.snapshot.roster or {}
    local tanks, healers, damage, dead = 0, 0, 0, 0
    for _, player in ipairs(roster) do
        local role = KWR.CombatSpells:Role(player.spec, player.role)
        if role == "TANK" then tanks = tanks + 1
        elseif role == "HEALER" then healers = healers + 1
        else damage = damage + 1 end
        if player.dead then dead = dead + 1 end
    end
    local formation = state.snapshot.formation or {}
    local mapKey = state.snapshot.context.mapKey
    local assignmentByName = {}
    for _, assignment in ipairs(state.assignments or {}) do
        assignmentByName[assignment.name] = assignment
        assignmentByName[assignment.shortName] = assignment
    end
    page.summaryCard.value:SetText(string.format(
        "%d / %d PLAYERS   |   %d TANK   |   %d HEALERS   |   %d DAMAGE",
        #roster, formation.targetSize or 10, tanks, healers, damage))
    page.summaryCard.detail:SetText((dead == 0 and "Command unit ready." or (tostring(dead) .. " players down."))
        .. " Assignments use role, specialization capabilities, and map doctrine.")
    for index, row in ipairs(page.rosterCard.rows) do
        local player = roster[index]
        row:SetShown(player ~= nil)
        if player then
            setClassIcon(row.icon, player.classFile)
            row.player:SetText(player.shortName)
            row.player:SetTextColor(classColor(player.classFile))
            row.spec:SetText(specLabel(player))
            row.role:SetText(KWR.CombatSpells:Role(player.spec, player.role))
            local health = player.healthPercent
            row.health:SetValue(health or 0)
            row.health:SetStatusBarColor(healthColor(health))
            local direct = not health and applyDirectHealth(row.health, player.unit, row.healthText)
            if health then
                row.healthText:SetText(tostring(math.floor(health + 0.5)) .. "%")
            elseif not direct then
                row.healthText:SetText("UNKNOWN")
            end
            local critical = health and health <= 35 and not player.dead
            row.life:SetText(player.dead and "DEAD"
                or (player.connected == false and "OFFLINE"
                or (critical and "CRITICAL" or "READY")))
            row.life:SetTextColor(KWR.Theme:Color(player.dead and "red"
                or (critical and "orange" or "green")))
            local assignment = assignmentByName[player.name] or assignmentByName[player.shortName]
            row.position:SetText(assignment
                and KWR.Assignments:CompactLabel(assignment, mapKey)
                or "UNASSIGNED")
        end
    end
    local definition = KWR.Maps:Get(state.snapshot.context.mapKey)
    local doctrine = KWR.Doctrine:Get(state.snapshot.context.mapKey)
    if not state.snapshot.context.inPvP then
        local positioning = formation.positioning or {}
        local tierMatch = formation.tierMatch and formation.tierMatch.qualified
            and formation.tierMatch or nil
        local recruits = {}
        for index = 1, math.min(4, #(formation.recommendations or {})) do
            recruits[#recruits + 1] = formation.recommendations[index].label
                .. " [" .. tostring(formation.recommendations[index].acquisition or "OPEN SLOT") .. "]"
        end
        page.doctrineCard.value:SetText(table.concat({
            tierMatch and (tierMatch.tier .. " " .. tierMatch.name)
                or (formation.archetype and formation.archetype.name or "Balanced Team Fight"),
            tierMatch and tierMatch.win
                or (formation.archetype and formation.archetype.description or "Build a complete roster."),
            tierMatch and ("ROLES: " .. tierMatch.assignments) or "",
            "",
            "RECRUIT",
            formation.needText or "Roster complete",
            #recruits > 0 and table.concat(recruits, " / ") or "Confirm current roster",
            "",
            "POSITIONING",
            positioning[1] or "",
            positioning[2] or "",
            positioning[3] or "",
        }, "\n"))
    else
        page.doctrineCard.value:SetText(table.concat({
            (definition and definition.title or "Formation"),
            "",
            "WINNING", doctrine.win,
            "", "EVEN", doctrine.even,
            "", "LOSING", doctrine.lose,
        }, "\n"))
    end
    page.readinessCard.value:SetText(table.concat({
        "Connected     " .. tostring(#roster),
        "Unavailable   " .. tostring(dead),
        "Assignments   " .. tostring(#(state.assignments or {})),
        "Open slots    " .. tostring(formation.openSlots or 0),
        "Truth rev.    " .. tostring(state.revision or 0),
    }, "\n"))
end

function MainWindow:UpdateEnemies(state)
    local page = self.pages.ENEMIES
    local enemies = state.snapshot.enemies or {}
    page.toolbar.mode:SetText(state.snapshot.context.preview and "DESIGN PREVIEW - NOT LIVE"
        or (state.snapshot.context.inPvP and "LIVE BATTLEFIELD INTEL" or "FORMATION / NO FEED"))
    page.trackerCard.empty:SetShown(#enemies == 0)
    local mapKey = state.snapshot.context.mapKey
    for index, row in ipairs(page.trackerCard.rows) do
        local enemy = enemies[index]
        row:SetShown(enemy ~= nil)
        if enemy then
            row.enemyKey = enemy.key
            local marks = { [0] = "O", [1] = "M", [2] = "H", [3] = "K" }
            row.priority:SetText(marks[enemy.priority or 0] or "O")
            row.seen:SetText(enemy.age and KWR.Util:Age(enemy.age) or "ROSTER")
            row.seen:SetTextColor(KWR.Theme:Color(not enemy.age and "muted"
                or (enemy.age < 10 and "green" or (enemy.age < 30 and "yellow" or "orange"))))
            setClassIcon(row.icon, enemy.classFile)
            row.name:SetText(enemy.shortName)
            row.name:SetTextColor(enemy.r or classColor(enemy.classFile), enemy.g or 0.75, enemy.b or 0.75)
            row.spec:SetText(specLabel(enemy) .. " " .. enemy.class)
            if enemy.role == "HEALER" or enemy.role == "TANK" then
                row.spec:SetText(enemy.role .. " | " .. specLabel(enemy) .. " " .. enemy.class)
            end
            if enemy.metaRank then
                row.spec:SetText(row.spec:GetText() .. " | RBG #" .. tostring(enemy.metaRank))
            end
            local health = enemy.healthPercent
            local lastHealth = KWR.Util:Number(enemy.lastHealthPercent, nil)
            local displayHealth = health or lastHealth
            row.health:SetMinMaxValues(0, 100)
            row.health:SetValue(displayHealth or 0)
            local healthColor = not health and "dim"
                or (health > 70 and "green" or (health > 35 and "yellow" or "red"))
            row.health:SetStatusBarColor(KWR.Theme:Color(healthColor))
            local direct = not health and applyDirectHealth(row.health, enemy.unit, row.healthText)
            if health then
                row.healthText:SetText(tostring(math.floor(health + 0.5)) .. "%")
            elseif lastHealth and not direct then
                row.healthText:SetText("LAST " .. tostring(
                    math.floor(lastHealth + 0.5)) .. "%")
            elseif not direct then
                row.healthText:SetText("NOT VISIBLE")
            end
            row.location:SetText(KWR.EnemyIntel:DescribeLocation(
                enemy, mapKey, false))
            row.trinket:SetText(enemy.trinket or "UNKNOWN")
            row.cooldown:SetText(enemy.cooldownText or "NO SAFE FEED")
            row.note:SetText(enemy.note and enemy.note ~= "" and KWR.Util:Text(enemy.note, "", 18) or "ADD NOTE")
            local kill = state.snapshot.combat and state.snapshot.combat.killTarget
                and state.snapshot.combat.killTarget.key == enemy.key
            KWR.Theme:Style(row, index % 2 == 0 and "panel" or "card", kill and "red" or "panel")
        else
            row.enemyKey = nil
        end
    end
end

function MainWindow:UpdateAssignments(state)
    local page = self.pages.ASSIGNMENTS
    page.commandCard.value:SetText(state.command.line2)
    page.commandCard.detail:SetText(state.command.line3 .. "  |  " .. tostring(state.command.confidence) .. " confidence")
    for index, row in ipairs(page.boardCard.rows) do
        local assignment = state.assignments[index]
        row:SetShown(assignment ~= nil)
        if assignment then
            row.player:SetText(assignment.shortName .. (assignment.dead and "  DEAD" or ""))
            row.player:SetTextColor(classColor(assignment.classFile))
            local spec = KWR.Util:Text(assignment.spec, "Unknown spec", 28)
            if assignment.specSource == "historical" then spec = spec .. " (HIST)" end
            row.class:SetText(spec .. " " .. assignment.class .. " / " .. assignment.groupRole)
            row.assignment:SetText(assignment.role)
            row.location:SetText(assignment.location)
            row.priority:SetText(assignmentPriority(assignment.priority))
        end
    end
    local mine = selfAssignment(state)
    page.mineCard.value:SetText(mine and (mine.role .. "\n|cffffd05a" .. mine.location
        .. "|r\n" .. assignmentPriority(mine.priority)
        .. (mine.handoff and ("\n|cff8ea3bb" .. KWR.Util:Text(mine.handoff, "", 92) .. "|r") or ""))
        or "Assignment pending.")
    local definition = KWR.Maps:Get(state.snapshot.context.mapKey)
    local strategy = state.snapshot.strategy or {}
    local counter = strategy.counter or {}
    local decision = strategy.objectiveDecision or {}
    local counterSteps = counter.sequence and table.concat(counter.sequence, " -> ") or nil
    local audit = KWR.Assignments:Audit(state.snapshot, state.assignments)
    local response = state.snapshot.responsePackage or {}
    page.logicCard.value:SetText(table.concat({
        "Map family: " .. (definition and definition.kind or "FORMATION"),
        "Plan: " .. KWR.Util:Text(strategy.planID, strategy.state or "FORMATION", 38),
        "Our shape: " .. (strategy.ourTier and strategy.ourTier.qualified
            and (strategy.ourTier.tier .. " " .. strategy.ourTier.name)
            or (strategy.ourComposition and strategy.ourComposition.name or "Unknown")),
        "Enemy shape: " .. (strategy.enemyTier and strategy.enemyTier.qualified
            and (strategy.enemyTier.tier .. " " .. strategy.enemyTier.name)
            or (strategy.enemyComposition and strategy.enemyComposition.name or "Unknown")),
        "Weighted focus: " .. weightedFocusText(strategy),
        "Success: " .. KWR.Util:Text(decision.success, "Confirm the objective state changes.", 120),
        "Abort: " .. KWR.Util:Text(decision.abort, "Reassess when the scoring path changes.", 120),
        "",
        "RESPONSE PACKAGE: " .. KWR.Util:Text(
            response.action, "Hold current plan.", 100),
        "MOVE: " .. KWR.Util:Text(response.moverText, "Team", 90),
        "STAY: " .. KWR.Util:Text(
            response.stayerText, "Assigned defenders", 90),
        string.format("QUALIFIED: %s | confidence %s | score %d",
            response.qualified and "YES" or "NO",
            tostring(response.confidence or "NONE"),
            response.score or 0),
        "",
        "COUNTER: " .. KWR.Util:Text(counter.emphasis, "Collecting enemy composition.", 130),
        counterSteps and ("SEQUENCE: " .. KWR.Util:Text(counterSteps, "", 170)) or "",
        "AVOID: " .. KWR.Util:Text(counter.avoid, "Do not split without a scoring reason.", 130),
        "",
        audit.ok and ("Coverage verified " .. tostring(audit.coverage) .. "/" .. tostring(audit.roster))
            or ("CHECK: " .. table.concat(audit.issues, "; ")),
    }, "\n"))
end

function MainWindow:UpdateIntel(state)
    local page = self.pages.INTEL
    local history = KWR.AAR:GetHistory()
    local insights = KWR.AAR:GetInsights()
    page.summaryCard.value:SetText(string.format(
        "%d MATCHES   |   %d%% WIN RATE   |   %d REVIEWED",
        insights.matches, insights.winRate, insights.reviewed))
    page.summaryCard.detail:SetText("Every match strengthens the command record. Feedback remains local in your SavedVariables.")
    for index, row in ipairs(page.historyCard.rows) do
        local entry = history[#history - index + 1]
        row:SetShown(entry ~= nil)
        if entry then
            local dateText = type(date) == "function" and date("%m/%d %H:%M", entry.startedAt) or tostring(entry.startedAt)
            row.date:SetText(dateText)
            row.map:SetText(entry.mapName or entry.mapKey)
            row.result:SetText(entry.result or "UNKNOWN")
            row.result:SetTextColor(KWR.Theme:Color(statusColor(entry.result)))
            row.score:SetText(string.format("%d - %d",
                entry.scoreEnd and entry.scoreEnd.friendly or 0,
                entry.scoreEnd and entry.scoreEnd.enemy or 0))
            row.review:SetText(entry.feedback and next(entry.feedback) and "DONE" or "OPEN")
            row.command:SetText(entry.finalCommand and KWR.Util:Text(entry.finalCommand.action, "", 34) or "--")
        end
    end
    page.insightCard.value:SetText(table.concat({
        "MATCHES RECORDED        " .. tostring(insights.matches),
        "VICTORIES               " .. tostring(insights.wins),
        "DEFEATS                 " .. tostring(insights.losses),
        "REVIEW COMPLETION       " .. tostring(insights.reviewed),
        "MOST PLAYED MAP         " .. tostring(insights.topMap),
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
    page.doctrineCard.value:SetText("WINNING  " .. doctrine.win
        .. "\n\nEVEN  " .. doctrine.even
        .. "\n\nLOSING  " .. doctrine.lose
        .. "\n\nSTOP RULE  " .. doctrine.stop)
    local latest = history[#history]
    page.reviewCard.value:SetText(latest and (latest.mapName .. "  |  " .. latest.result
        .. "\nEvidence export ready. "
        .. (latest.feedback and next(latest.feedback)
            and "Manual review complete." or "Manual review optional."))
        or "No completed match is available yet.")
    page.reviewCard.open:SetShown(latest ~= nil)
    page.reviewCard.export:SetShown(latest ~= nil)
end

function MainWindow:Update(state)
    if not self.frame then return end
    if not self.frame:IsShown() then return end
    local context = state.snapshot.context
    self.frame.context:SetText((context.preview and "DESIGN PREVIEW - NOT LIVE" or (context.inPvP and "LIVE COMMAND" or "FORMATION MODE"))
        .. "  |  " .. context.mapName
        .. (context.inPvP and ("  |  " .. (context.isBlitz and "BLITZ" or "STANDARD")
            .. "  |  " .. tostring(context.team and context.team.faction or "TEAM PENDING")) or "")
        .. "  |  REV " .. tostring(state.revision or 0))
    self.frame.context:SetTextColor(KWR.Theme:Color(context.preview and "orange" or (context.inPvP and "green" or "muted")))
    self.frame.score:SetText(string.format("|cff4f8cff%d|r  -  |cffff3333%d|r   %s",
        state.snapshot.score.friendly or 0, state.snapshot.score.enemy or 0, state.command.status))
    if self.activePage == "TACTICAL" then self:UpdateTactical(state)
    elseif self.activePage == "OBJECTIVES" then self:UpdateObjectives(state)
    elseif self.activePage == "TEAM" then self:UpdateTeam(state)
    elseif self.activePage == "ENEMIES" then self:UpdateEnemies(state)
    elseif self.activePage == "ASSIGNMENTS" then self:UpdateAssignments(state)
    elseif self.activePage == "INTEL" then self:UpdateIntel(state)
    end
end

function MainWindow:Show(page)
    self:Create()
    if InCombatLockdown and InCombatLockdown() and not self.frame:IsShown() then
        self.pendingVisibility = { shown = true, page = page }
        KWR:Print("War Room will open when combat ends; secure controls cannot change visibility in combat.", true)
        return
    end
    self:SuppressCompactSurfaces()
    if page and (not InCombatLockdown or not InCombatLockdown()) then self:SetPage(page) end
    self.frame:Show()
    self:Update(KWR.Store:Get())
end

function MainWindow:SuppressCompactSurfaces()
    if self.compactRestore then return end
    self.compactRestore = {
        roster = KWR.CombatRoster.frame and KWR.CombatRoster.frame:IsShown() or false,
        reporter = KWR.ReporterMap.frame and KWR.ReporterMap.frame:IsShown() or false,
    }
    KWR.HUD:SetSuppressed(true)
    if KWR.CombatRoster.frame and (not InCombatLockdown or not InCombatLockdown()) then
        KWR.CombatRoster.frame:Hide()
    end
    if KWR.ReporterMap.frame then KWR.ReporterMap.frame:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end

function MainWindow:RestoreCompactSurfaces()
    local restore = self.compactRestore
    if not restore then return end
    self.compactRestore = nil
    KWR.HUD:SetSuppressed(false)
    if restore.roster and KWR.CombatRoster.frame
        and (not InCombatLockdown or not InCombatLockdown()) then
        KWR.CombatRoster.frame:Show()
        KWR.CombatRoster:Update(KWR.Store:Get())
    end
    if restore.reporter and KWR.ReporterMap.frame then
        KWR.ReporterMap.frame:Show()
        KWR.ReporterMap:Update(KWR.Store:Get())
    end
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
    local pending = self.pendingVisibility
    self.pendingVisibility = nil
    if pending then
        if pending.shown then self:Show(pending.page) else self:Hide() end
    elseif self.frame and self.frame:IsShown() and self.compactRestore
        and KWR.CombatRoster.frame and KWR.CombatRoster.frame:IsShown() then
        KWR.CombatRoster.frame:Hide()
    end
end

function MainWindow:MinimizeTo(surface, mode)
    self:Hide()
    if surface == "REPORTER" then
        KWR.ReporterMap:Show()
    elseif surface == "ROSTER" then
        KWR.CombatRoster:Show(mode or "BOTH")
    end
end

function MainWindow:Toggle(page)
    self:Create()
    if self.frame:IsShown() and not page then
        self:Hide()
    else
        self:Show(page)
    end
end

function MainWindow:PositionLauncher()
    local button = self.launcher
    if not button then return end
    local profile = KWR.db.profile.launcher
    button:ClearAllPoints()
    if Minimap then
        local angle = math.rad(profile.angle or 225)
        local width = KWR.Util:Number(KWR.Util:Call(
            Minimap.GetWidth, Minimap), 140)
        local height = KWR.Util:Number(KWR.Util:Call(
            Minimap.GetHeight, Minimap), width)
        local radius = (math.max(width or 140, height or 140) * 0.5) + 12
        button:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(angle) * radius, math.sin(angle) * radius)
        if type(Minimap.GetFrameLevel) == "function" then
            button:SetFrameLevel((KWR.Util:Number(KWR.Util:Call(
                Minimap.GetFrameLevel, Minimap), 0) or 0) + 8)
        end
    else
        button:SetPoint(profile.point, UIParent, profile.relativePoint,
            profile.x, profile.y)
    end
end

function MainWindow:CreateLauncher()
    if self.launcher then return end
    local profile = KWR.db.profile.launcher
    local button = CreateFrame("Button", "KWR_Launcher", UIParent)
    button:SetSize(32, 32)
    button:SetFrameStrata("HIGH")
    button.disc = button:CreateTexture(nil, "BACKGROUND")
    button.disc:SetPoint("CENTER")
    button.disc:SetSize(26, 26)
    button.disc:SetColorTexture(0.015, 0.018, 0.022, 0.96)
    if type(button.CreateMaskTexture) == "function" then
        local mask = button:CreateMaskTexture()
        if mask then
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
            mask:SetAllPoints(button.disc)
            button.disc:AddMaskTexture(mask)
            button.mask = mask
        end
    end
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetPoint("CENTER")
    button.border:SetSize(42, 42)
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetPoint("CENTER")
    button.highlight:SetSize(28, 28)
    button.highlight:SetColorTexture(1, 0.72, 0.08, 0.18)
    if button.mask then button.highlight:AddMaskTexture(button.mask) end
    button.text = KWR.Theme:Title(button, 8, "CENTER")
    button.text:SetPoint("CENTER")
    button.text:SetText("KWR")
    self.launcher = button
    self:PositionLauncher()
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            MainWindow:ToggleLauncherMenu()
        else
            if MainWindow.launcherMenu then MainWindow.launcherMenu:Hide() end
            MainWindow:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        if not IsShiftKeyDown() or (InCombatLockdown and InCombatLockdown()) then return end
        if Minimap then
            self.dragging = true
            self:SetScript("OnUpdate", function()
                local cursorX, cursorY = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                local centerX, centerY = Minimap:GetCenter()
                cursorX, cursorY = cursorX / scale, cursorY / scale
                local dx, dy = cursorX - centerX, cursorY - centerY
                local angle
                if math.atan2 then
                    angle = math.deg(math.atan2(dy, dx))
                elseif dx == 0 then
                    angle = dy >= 0 and 90 or -90
                else
                    angle = math.deg(math.atan(dy / dx))
                    if dx < 0 then angle = angle + 180 end
                end
                profile.angle = angle
                MainWindow:PositionLauncher()
            end)
        else
            self:StartMoving()
        end
    end)
    button:SetScript("OnDragStop", function(self)
        if self.dragging then
            self.dragging = false
            self:SetScript("OnUpdate", nil)
        else
            self:StopMovingOrSizing()
            local point, _, relativePoint, x, y = self:GetPoint(1)
            profile.point, profile.relativePoint, profile.x, profile.y = point, relativePoint, x, y
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Knomercy War Room")
        GameTooltip:AddLine("Left-click: AI Commander Dashboard", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Command menu", 1, 1, 1)
        GameTooltip:AddLine("Shift-drag: Move around minimap", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function MainWindow:CreateLauncherMenu()
    if self.launcherMenu then return end
    local menu = CreateFrame("Frame", "KWR_LauncherMenu", UIParent, "BackdropTemplate")
    menu:SetSize(224, 358)
    menu:SetPoint("TOPRIGHT", self.launcher, "BOTTOMLEFT", -8, 0)
    menu:SetFrameStrata("DIALOG")
    KWR.Theme:Style(menu, "background", "borderHi")
    menu:Hide()
    menu.title = KWR.Theme:Title(menu, 13, "CENTER")
    menu.title:SetPoint("TOPLEFT", 10, -10)
    menu.title:SetPoint("TOPRIGHT", -10, -10)
    menu.title:SetText("KWR COMMAND MENU")
    local items = {
        { "OPEN TACTICAL MAP", function() MainWindow:Show("TACTICAL") end },
        { "REPORTER MINI MAP", function() KWR.ReporterMap:Toggle() end },
        { "COMBAT ROSTER", function() KWR.CombatRoster:Toggle("BOTH") end },
        { "COMPACT SCOUT HUD", function() KWR.HUD:Toggle() end },
        { "ENEMY TRACKER", function() MainWindow:Show("ENEMIES") end },
        { "LEARNING LIBRARY", function() MainWindow:Show("INTEL") end },
        { "AAR / EXPORT", function() MainWindow:Show("INTEL") end },
        { "CAPTURE VERIFICATION", function()
            KWR.CopyDialog:ShowText("KWR Live Verification", KWR.Verification:CurrentReport())
        end },
        { "KWR OPTIONS", function() KWR.Options:Toggle() end },
    }
    for index, item in ipairs(items) do
        local action = item[2]
        local button = KWR.Theme:Button(menu, item[1], 196, 25, function()
            menu:Hide()
            action()
        end)
        button:SetPoint("TOPLEFT", 14, -40 - ((index - 1) * 32))
    end
    local close = KWR.Theme:Button(menu, "CLOSE", 196, 25, function() menu:Hide() end)
    close:SetPoint("BOTTOMLEFT", 14, 12)
    self.launcherMenu = menu
end

function MainWindow:ToggleLauncherMenu()
    self:CreateLauncherMenu()
    self.launcherMenu:SetShown(not self.launcherMenu:IsShown())
end

function MainWindow:TogglePreview()
    local state = KWR.Store:Get()
    if state.snapshot.context.inPvP and not state.snapshot.context.preview then
        KWR:Print("Preview cannot replace live battleground truth.", true)
        return
    end
    KWR.db.profile.preview = not KWR.db.profile.preview
    KWR.MatchRuntime:ForceRefresh("preview-toggle")
    self:Show("TACTICAL")
    KWR:Print(KWR.db.profile.preview and "Design preview enabled. Data is clearly marked NOT LIVE."
        or "Design preview disabled. Live truth restored.", true)
end

function MainWindow:ArmFieldTest()
    KWR.db.profile.preview = false
    KWR.db.profile.guidanceMode = "COMMAND"
    KWR.db.profile.aar.autoOpen = true
    KWR.db.profile.aar.enabled = true
    KWR.db.profile.hud.enabled = true
    KWR.db.profile.combatRoster.shown = true
    KWR.db.profile.combatRoster.mode = "BOTH"
    KWR.HUD:SetEnabled(true)
    KWR.CombatRoster:Show("BOTH")
    KWR.MatchRuntime:ForceRefresh("field-test-arm")
    KWR:Print("Field test armed: Scout HUD, Team/Enemy roster, live command, "
        .. "manual reassess, evidence ledger, and automatic AAR are active.", true)
end

function MainWindow:ShowAARExport()
    local export, message = KWR.AAR:Export()
    if not export then
        KWR:Print(message or "No completed AAR export is available.", true)
        self:Show("INTEL")
        return
    end
    KWR.CopyDialog:ShowText("KWR Match Evidence Export", export)
end

function MainWindow:RegisterCommands()
    SLASH_KWR1 = "/kwr"
    SlashCmdList.KWR = function(input)
        input = KWR.Util:Text(input, "", 40):lower()
        if input == "" or input == "open" then MainWindow:Toggle()
        elseif input == "map" or input == "tactical" or input == "command" then MainWindow:Show("TACTICAL")
        elseif input == "reporter" or input == "report" then KWR.ReporterMap:Toggle()
        elseif input == "roster" or input == "combat" then KWR.CombatRoster:Toggle("BOTH")
        elseif input == "teammini" then KWR.CombatRoster:Toggle("TEAM")
        elseif input == "enemymini" then KWR.CombatRoster:Toggle("ENEMY")
        elseif input == "objectives" then MainWindow:Show("OBJECTIVES")
        elseif input == "team" then MainWindow:Show("TEAM")
        elseif input == "enemies" or input == "enemy" then MainWindow:Show("ENEMIES")
        elseif input == "assignments" then MainWindow:Show("ASSIGNMENTS")
        elseif input == "intel" or input == "history" then MainWindow:Show("INTEL")
        elseif input == "aar" then
            MainWindow:Show("INTEL")
            local latest = KWR.AAR:GetLatest()
            KWR:Print(latest and "Latest AAR evidence is ready. Use /kwr aar copy."
                or "No completed AAR evidence is available.", true)
        elseif input == "aar copy" then
            MainWindow:ShowAARExport()
        elseif input == "aar clear" then
            local cleared, message = KWR.AAR:ClearCompleted()
            KWR:Print(cleared and "Completed AAR evidence cleared."
                or (message or "AAR evidence was not cleared."), true)
        elseif input == "preview" or input == "demo" then MainWindow:TogglePreview()
        elseif input == "hud" then KWR.HUD:Toggle()
        elseif input == "copy" then
            KWR.CopyDialog:ShowCompact("KWR Compact Call",
                compactCommandText(KWR.Store:Get()))
        elseif input == "refresh" then KWR.MatchRuntime:ForceRefresh("slash")
        elseif input == "reassess" then KWR.MatchRuntime:Reassess()
        elseif input == "field" or input == "fieldtest" or input == "ready" then
            MainWindow:ArmFieldTest()
        elseif input == "options" then KWR.Options:Toggle()
        elseif input == "cursor" then KWR.CursorRing:Toggle()
        elseif input == "test" then KWR.Diagnostics:ShowReport()
        elseif input == "explain" or input == "why" then MainWindow:Explain()
        elseif input == "perf" or input == "performance" then MainWindow:ShowPerformance()
        elseif input == "verify" or input == "capture" then
            KWR.CopyDialog:ShowText("KWR Live Verification", KWR.Verification:CurrentReport())
        elseif input == "bug" or input == "fieldreport" then
            KWR.CopyDialog:ShowText("KWR Field Defect Bundle", KWR.Verification:FieldReport())
        elseif input == "evidence" or input == "ledger" then
            KWR.CopyDialog:ShowText("KWR Match Evidence Ledger", KWR.Verification:LedgerReport())
        elseif input == "mode" or input == "learnmode" then
            KWR.db.profile.guidanceMode = KWR.db.profile.guidanceMode == "LEARNING" and "COMMAND" or "LEARNING"
            KWR.MatchRuntime:ForceRefresh("guidance-mode")
            KWR:Print("Guidance mode: " .. KWR.db.profile.guidanceMode, true)
        elseif input == "status" then
            local state = KWR.Store:Get()
            KWR:Print(state.command.line1 .. " | " .. state.command.line2, true)
        else
            KWR:Print("Commands: /kwr, field, bug, tactical, reporter, roster, teammini, enemymini, objectives, team, enemies, assignments, intel, aar, aar copy, aar clear, preview, hud, copy, explain, perf, verify, evidence, mode, refresh, reassess, options, cursor, test, status", true)
        end
    end
end

function MainWindow:OnInitialize()
    self:CreateLauncher()
    self:RegisterCommands()
    KWR.Store:Subscribe(self, self.Update)
end

function MainWindow:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("MainWindow", MainWindow)
