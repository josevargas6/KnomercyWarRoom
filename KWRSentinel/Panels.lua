local _, Sentinel = ...

local Panels = {}
Sentinel.Panels = Panels

local function profile(kind)
    local db = Sentinel.db.profile.panels
    db[kind] = type(db[kind]) == "table" and db[kind] or {}
    return db[kind]
end

local function trim(value)
    value = value ~= nil and tostring(value) or ""
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    value = value:gsub("%s+", " ")
    return value
end

local function short(value, fallback, limit)
    value = trim(value)
    if value == "" then
        value = fallback or ""
    end
    limit = limit or 28
    if #value > limit then
        return value:sub(1, limit - 3):gsub("%s+%S*$", "") .. "..."
    end
    return value
end

local function healthText(value, dead)
    if dead == true then return "DEAD" end
    value = tonumber(value or 0)
    if value <= 0 then return "--" end
    return tostring(math.floor(value + 0.5)) .. "%"
end

local function toneForHealth(value, dead)
    if dead == true then return "active" end
    value = tonumber(value or 0)
    if value <= 35 then return "active" end
    if value <= 70 then return "forming" end
    return "recovery"
end

local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS or {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE = { 0.25, 0.49609375, 0, 0.25 },
    ROGUE = { 0.49609375, 0.7421875, 0, 0.25 },
    DRUID = { 0.7421875, 0.98828125, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    SHAMAN = { 0.25, 0.49609375, 0.25, 0.5 },
    PRIEST = { 0.49609375, 0.7421875, 0.25, 0.5 },
    WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
    DEATHKNIGHT = { 0.25, 0.49609375, 0.5, 0.75 },
    MONK = { 0.49609375, 0.7421875, 0.5, 0.75 },
    DEMONHUNTER = { 0.7421875, 0.98828125, 0.5, 0.75 },
    EVOKER = { 0, 0.25, 0.75, 1 },
}

local function classColor(classFile)
    classFile = trim(classFile):upper()
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
        local color = RAID_CLASS_COLORS[classFile]
        return color.r or 1, color.g or 1, color.b or 1
    end
    return Sentinel.Theme:Color("text")
end

local function applyClassVisuals(row, classFile)
    classFile = trim(classFile):upper()
    local coords = CLASS_ICON_TCOORDS[classFile]
    if coords then
        row.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        row.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        row.icon:Show()
    else
        row.icon:Hide()
    end
    row.name:SetTextColor(classColor(classFile))
end

local function applyIntentVisuals(row, intent)
    if intent == "KILL" then
        row.intentIcon:SetTexture("Interface\\Icons\\INV_Sword_04")
        row.intentIcon:SetVertexColor(0.95, 0.18, 0.16, 1)
        row.intentIcon:Show()
        row.intentText:SetText("K")
        row.intentText:SetTextColor(0.95, 0.18, 0.16, 1)
        row.intentText:Show()
        return
    end
    if intent == "CC" then
        row.intentIcon:SetTexture("Interface\\Icons\\Spell_Frost_ChainsOfIce")
        row.intentIcon:SetVertexColor(0.32, 0.74, 0.98, 1)
        row.intentIcon:Show()
        row.intentText:SetText("C")
        row.intentText:SetTextColor(0.32, 0.74, 0.98, 1)
        row.intentText:Show()
        return
    end
    row.intentIcon:Hide()
    row.intentText:Hide()
end

local function enemyStateText(data)
    if data.intent == "KILL" then return "KILL" end
    if data.intent == "CC" then return "CC" end
    if data.dead == true then return "DEAD" end
    if data.localEngaged == true then return "LIVE" end
    if data.localRange == true or data.visible == true then return "SEEN" end
    if tonumber(data.lastSeenAge or 0) and tonumber(data.lastSeenAge or 0) > 0 then
        return "LAST"
    end
    return "--"
end

local function enemyStateTone(data)
    if data.intent == "KILL" then return "active" end
    if data.intent == "CC" then return "accent" end
    if data.dead == true then return "muted" end
    if data.localEngaged == true then return "recovery" end
    if data.localRange == true or data.visible == true then return "forming" end
    if tonumber(data.lastSeenAge or 0) and tonumber(data.lastSeenAge or 0) > 0 then
        return "text"
    end
    return "muted"
end

local function canShow(frame, setting)
    local settings = profile(setting)
    return settings.enabled == true
end

local function applyAnchor(frame, setting)
    local settings = profile(setting)
    frame:ClearAllPoints()
    frame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.x, settings.y)
end

local function saveAnchor(frame, setting)
    local settings = profile(setting)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    settings.point = point
    settings.relativePoint = relativePoint
    settings.x = x
    settings.y = y
end

local function createShell(name, title, width, height, setting)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    Sentinel.Theme:Style(frame, "background", "borderHi")
    applyAnchor(frame, setting)

    frame.headerBand = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.headerBand:SetPoint("TOPLEFT", 8, -6)
    frame.headerBand:SetPoint("TOPRIGHT", -8, -6)
    frame.headerBand:SetHeight(24)
    Sentinel.Theme:Style(frame.headerBand, "raised", "border")

    frame.brand = frame.headerBand:CreateTexture(nil, "ARTWORK")
    frame.brand:SetPoint("LEFT", 6, 0)
    frame.brand:SetSize(12, 12)
    frame.brand:SetTexture("Interface\\AddOns\\KnomercyWarRoom\\Assets\\Brand\\Logos\\kwr_compact_mark.png")

    frame.title = Sentinel.Theme:Title(frame.headerBand, 10, "LEFT")
    frame.title:SetPoint("LEFT", frame.brand, "RIGHT", 6, 0)
    frame.title:SetText(title)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        if Sentinel.db.profile.panels.locked == true then return end
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        saveAnchor(selfFrame, setting)
    end)
    return frame
end

local function makeKeyValue(parent, label, y)
    local key = Sentinel.Theme:Font(parent, 8, "gold", "LEFT", "OUTLINE")
    key:SetPoint("TOPLEFT", 10, y)
    key:SetWidth(78)
    key:SetText(label)

    local value = Sentinel.Theme:Font(parent, 10, "strong", "LEFT", "OUTLINE")
    value:SetPoint("TOPLEFT", 82, y + 1)
    value:SetPoint("TOPRIGHT", -10, y + 1)
    value:SetHeight(14)
    return value
end

local function secureTargetName(name)
    name = trim(name)
    if name == "" then return "" end
    if type(Ambiguate) == "function" then
        local safe = Ambiguate(name, "none")
        if type(safe) == "string" and safe ~= "" then
            return safe
        end
    end
    return name
end

local function locateEnemyUnit(data)
    if type(data) ~= "table" then return nil end
    local wantedGUID = trim(data.guid or "")
    local wantedName = trim(data.name or "")
    local shortWanted = secureTargetName(wantedName):lower()
    local function matches(unit)
        if not unit or type(UnitExists) ~= "function" or not UnitExists(unit) then
            return false
        end
        if type(UnitCanAttack) == "function" and not UnitCanAttack("player", unit) then
            return false
        end
        if wantedGUID ~= "" and type(UnitGUID) == "function" and UnitGUID(unit) == wantedGUID then
            return true
        end
        if shortWanted ~= "" and type(UnitName) == "function" then
            return secureTargetName(UnitName(unit) or ""):lower() == shortWanted
        end
        return false
    end
    for _, unit in ipairs({ data.unit, "target", "focus", "mouseover" }) do
        if matches(unit) then
            return unit
        end
    end
    for index = 1, 40 do
        local unit = "nameplate" .. tostring(index)
        if matches(unit) then
            return unit
        end
    end
    return nil
end

local function bindEnemyRow(row, data)
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local resolvedUnit = locateEnemyUnit(data)
    local targetName = secureTargetName(data and (data.name or data.shortName) or "")
    local desired = {
        unit = resolvedUnit or false,
        type1 = false,
        type2 = false,
        macrotext1 = false,
        macrotext2 = false,
    }
    if resolvedUnit then
        desired.type1 = "target"
        desired.type2 = "focus"
    elseif targetName ~= "" then
        desired.type1 = "macro"
        desired.type2 = "macro"
        desired.macrotext1 = "/cleartarget\n/targetexact " .. targetName
        desired.macrotext2 = "/targetexact " .. targetName .. "\n/focus\n/targetlasttarget"
    end
    for attribute, value in pairs(desired) do
        if row:GetAttribute(attribute) ~= value then
            row:SetAttribute(attribute, value)
        end
    end
    row.boundUnit = resolvedUnit
    row.boundName = targetName
end

local function resetEnemyRowBinding(row)
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    for _, attribute in ipairs({ "unit", "type1", "type2", "macrotext1", "macrotext2" }) do
        if row:GetAttribute(attribute) ~= false then
            row:SetAttribute(attribute, false)
        end
    end
    row.boundUnit = nil
    row.boundName = nil
end

local function makeRow(parent, y, clickable)
    local template = clickable == true
        and "SecureUnitButtonTemplate,BackdropTemplate"
        or "BackdropTemplate"
    local row = CreateFrame(clickable == true and "Button" or "Frame", nil, parent, template)
    row:SetPoint("TOPLEFT", 8, y)
    row:SetPoint("TOPRIGHT", -8, y)
    row:SetHeight(18)
    if clickable == true and row.RegisterForClicks then
        row:RegisterForClicks("AnyUp")
    end
    Sentinel.Theme:Style(row, "panel", "hairline")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetSize(14, 14)
    row.icon:Hide()

    row.name = Sentinel.Theme:Font(row, 9, "text", "LEFT", "OUTLINE")
    row.name:SetPoint("LEFT", 20, 0)
    row.name:SetWidth(78)

    row.detail = Sentinel.Theme:Font(row, 8, "muted", "LEFT", "OUTLINE")
    row.detail:SetPoint("LEFT", 100, 0)
    row.detail:SetWidth(102)

    row.intentIcon = row:CreateTexture(nil, "OVERLAY")
    row.intentIcon:SetPoint("RIGHT", -54, 0)
    row.intentIcon:SetSize(12, 12)
    row.intentIcon:Hide()

    row.intentText = Sentinel.Theme:Font(row, 7, "text", "CENTER", "OUTLINE")
    row.intentText:SetPoint("CENTER", row.intentIcon, "CENTER", 0, 0)
    row.intentText:Hide()

    row.state = Sentinel.Theme:Font(row, 8, "text", "RIGHT", "OUTLINE")
    row.state:SetPoint("RIGHT", -2, 0)
    row.state:SetWidth(54)
    if clickable == true then
        row:SetScript("OnEnter", function(selfRow)
            if not GameTooltip then return end
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:SetText(selfRow.name:GetText() or "Enemy")
            GameTooltip:AddLine("Left-click: target", 1, 1, 1)
            GameTooltip:AddLine("Right-click: focus", 1, 1, 1)
            if selfRow.boundUnit then
                GameTooltip:AddLine("Mouseover cast: available while this row is bound to a live unit.", 0.70, 0.84, 0.96, true)
            else
                GameTooltip:AddLine("Mouseover cast: unavailable until the enemy is a live local unit.", 0.90, 0.65, 0.22, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
    end
    return row
end

function Panels:CreateStatus()
    if self.statusFrame then return self.statusFrame end
    local frame = createShell("KWRSentinel_StatusPanel", "SENTINEL STATUS", 320, 168, "status")
    frame.assignment = makeKeyValue(frame, "ASSIGN", -40)
    frame.stage = makeKeyValue(frame, "STAGE", -62)
    frame.trinket = makeKeyValue(frame, "TRINKET", -84)
    frame.kick = makeKeyValue(frame, "KICK", -106)
    frame.cc = makeKeyValue(frame, "CC", -128)
    frame.rez = makeKeyValue(frame, "RESPAWN", -150)
    self.statusFrame = frame
    return frame
end

function Panels:CreateTracker(kind)
    local key = kind == "team" and "teamFrame" or "enemyFrame"
    if self[key] then return self[key] end
    local title = kind == "team" and "TEAM TRACKER" or "ENEMY TRACKER"
    local name = kind == "team" and "KWRSentinel_TeamTracker" or "KWRSentinel_EnemyTracker"
    local frame = createShell(name, title, 292, 206, kind)
    frame.rows = {}
    for index = 1, 8 do
        frame.rows[index] = makeRow(frame, -30 - (index * 20), kind == "enemy")
    end
    self[key] = frame
    return frame
end

local function fillRow(row, left, center, right, rightTone)
    row.name:SetText(short(left, "--", 16))
    row.detail:SetText(short(center, "--", 20))
    row.state:SetText(short(right, "--", 10))
    row.state:SetTextColor(Sentinel.Theme:Color(rightTone or "text"))
    row:Show()
end

function Panels:UpdateStatus(view)
    local frame = self:CreateStatus()
    if canShow(frame, "status") ~= true then
        frame:Hide()
        return
    end
    local assignment = view and view.assignment or {}
    local status = view and view.playerStatus or {}
    frame.assignment:SetText(short((assignment.shortRole or assignment.role or "UNASSIGNED")
        .. " " .. (assignment.location or ""), "UNASSIGNED", 30))
    frame.stage:SetText(short(status.stage ~= "" and status.stage or status.movement, "STAY", 24))
    frame.trinket:SetText(short(status.trinket, "UNKNOWN", 26))
    frame.kick:SetText(short(status.kick, "UNKNOWN", 26))
    frame.cc:SetText(short(status.cc, "UNKNOWN", 26))
    frame.rez:SetText(short(status.rez, "ALIVE", 20))
    frame:Show()
end

function Panels:UpdateTracker(kind, rows)
    local frame = self:CreateTracker(kind)
    if canShow(frame, kind) ~= true then
        frame:Hide()
        return
    end
    rows = rows or {}
    for index, row in ipairs(frame.rows) do
        local data = rows[index]
        if data then
            local detail = data.detail or data.assignmentLocation or data.status or "--"
            local state = kind == "team"
                and healthText(data.healthPercent, data.dead)
                or enemyStateText(data)
            local tone = kind == "team"
                and toneForHealth(data.healthPercent, data.dead)
                or enemyStateTone(data)
            fillRow(row, data.isSelf == true and ("[" .. data.name .. "]") or data.name,
                detail, state, tone)
            applyClassVisuals(row, data.classFile)
            if kind == "enemy" then
                applyIntentVisuals(row, data.intent)
                bindEnemyRow(row, data)
            else
                row.intentIcon:Hide()
                row.intentText:Hide()
            end
        else
            if kind == "enemy" then
                resetEnemyRowBinding(row)
            end
            row.icon:Hide()
            row.intentIcon:Hide()
            row.intentText:Hide()
            row.name:SetTextColor(Sentinel.Theme:Color("text"))
            row:Hide()
        end
    end
    frame:Show()
end

function Panels:Update(view)
    if not Sentinel.db or not Sentinel.db.profile then
        return
    end
    view = view or (Sentinel.Bridge and Sentinel.Bridge:BuildView()) or {}
    self:UpdateStatus(view)
    local roster = view.roster or {}
    self:UpdateTracker("team", roster.team)
    self:UpdateTracker("enemy", roster.enemy)
end

function Panels:ResetPositions()
    local defaults = Sentinel.defaults
        and Sentinel.defaults.profile
        and Sentinel.defaults.profile.panels
    if not defaults then return end
    for _, kind in ipairs({ "status", "team", "enemy" }) do
        local source = defaults[kind]
        local target = Sentinel.db.profile.panels[kind]
        target.point = source.point
        target.relativePoint = source.relativePoint
        target.x = source.x
        target.y = source.y
    end
    if self.statusFrame then applyAnchor(self.statusFrame, "status") end
    if self.teamFrame then applyAnchor(self.teamFrame, "team") end
    if self.enemyFrame then applyAnchor(self.enemyFrame, "enemy") end
    self:Update()
end

function Panels:OnInitialize()
    self:CreateStatus():Hide()
    self:CreateTracker("team"):Hide()
    self:CreateTracker("enemy"):Hide()
end

function Panels:OnEnable()
    self:Update()
end

Sentinel:RegisterModule("Panels", Panels)