local _, KWR = ...

local CombatRoster = {
    teamRows = {},
    enemyRows = {},
    enemySlotKeys = {},
    pending = nil,
    maxRows = 10,
    autoVisible = false,
    lastSessionKey = nil,
}
KWR.CombatRoster = CombatRoster

local ROW_HEIGHT = 28
local ROW_SPACING = 30
local ROW_TOP = 26
local LANE_BOTTOM_PADDING = 8
local FRAME_PADDING = 8
local TOOLBAR_HEIGHT = 26
local COMMAND_HEIGHT = 70
local SECTION_GAP = 6
local SOLO_WIDTH = 336

local function currentState(fallback)
    if fallback then
        return fallback
    end
    if KWR.Store and type(KWR.Store.Get) == "function" then
        return KWR.Store:Get()
    end
    return nil
end

local function classColor(classFile)
    local color = type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[classFile]
    if color then return color.r or 0.7, color.g or 0.7, color.b or 0.7 end
    return 0.55, 0.58, 0.62
end

local function healthColor(percent)
    if not percent then return 0.26, 0.28, 0.31 end
    if percent <= 35 then return 0.92, 0.12, 0.10 end
    if percent <= 70 then return 0.92, 0.58, 0.10 end
    return 0.18, 0.72, 0.20
end

local function truthTone(seen)
    seen = KWR.Util:Upper(seen, "NONE", 24)
    if seen == "DIRECT" or seen == "CURRENT" or seen == "LOCAL" or seen == "HERE" then return "green" end
    if seen == "TRACKED" or seen == "RECENT" or seen == "WATCH" then return "yellow" end
    if seen == "LAST" or seen == "STALE" then return "orange" end
    return "muted"
end

local function sameUnitOrName(unit, name, comparison)
    if unit and type(UnitIsUnit) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsUnit, unit, comparison), false) then
        return true
    end
    local comparisonName = KWR.Util:UnitName(comparison)
    return comparisonName and KWR.Util:ShortName(comparisonName):lower()
        == KWR.Util:ShortName(KWR.Util:Text(name, "", 64)):lower()
end

local function spotlightFallbackRank(enemy)
    if not enemy or enemy.dead == true then return 0 end
    if enemy.localEngaged == true then return 6 end
    if enemy.localRange == true then return 5 end
    if enemy.recentLocalEngaged == true then return 4 end
    if enemy.recentLocalRange == true then return 3 end
    if enemy.visible == true then return 2 end
    return 0
end

local function activeCombatTarget(combat)
    if type(combat) ~= "table" then return nil end
    return combat.localTarget or combat.killTarget
end

local function activeCombatReason(combat)
    if type(combat) ~= "table" then return nil end
    return combat.localTargetReason or combat.killReason
end

local function laneHeight()
    return ROW_TOP + ((CombatRoster.maxRows - 1) * ROW_SPACING)
        + ROW_HEIGHT + LANE_BOTTOM_PADDING
end

local function frameHeight(showCommand)
    return FRAME_PADDING + TOOLBAR_HEIGHT + SECTION_GAP
        + (showCommand and (COMMAND_HEIGHT + SECTION_GAP) or 0)
        + laneHeight() + FRAME_PADDING
end

local function applyRowMetrics(row, width)
    if not row then return end
    width = KWR.Util:Number(width, 306) or 306
    local healthWidth = 48
    local nameWidth = width >= 306 and 104 or 92
    local detailWidth = math.max(76, width - 30 - nameWidth - healthWidth - 36)
    row.nameText:ClearAllPoints()
    row.nameText:SetPoint("LEFT", 30, 0)
    row.nameText:SetWidth(nameWidth)
    row.nameText:SetHeight(ROW_HEIGHT - 4)
    if row.detailIcon then
        row.detailIcon:ClearAllPoints()
        row.detailIcon:SetPoint("LEFT", row.nameText, "RIGHT", 6, 0)
        row.detailIcon:SetSize(14, 14)
    end
    row.detailText:ClearAllPoints()
    row.detailText:SetPoint("LEFT", row.nameText, "RIGHT", 24, 0)
    row.detailText:SetWidth(detailWidth)
    row.detailText:SetHeight(ROW_HEIGHT - 4)
    row.healthText:ClearAllPoints()
    row.healthText:SetPoint("RIGHT", -6, 0)
    row.healthText:SetWidth(healthWidth)
    row.healthText:SetHeight(ROW_HEIGHT - 4)
    row.stateText:Hide()
end

local function singleLine(font)
    if not font then return end
    if font.SetWordWrap then font:SetWordWrap(false) end
    if font.SetNonSpaceWrap then font:SetNonSpaceWrap(false) end
    if font.SetMaxLines then font:SetMaxLines(1) end
end

local function createSecureRow(parent, name)
    local row = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate,BackdropTemplate")
    row:SetSize(306, ROW_HEIGHT)
    row:RegisterForClicks("AnyUp")
    KWR.Theme:Style(row, "card", "border")

    row.glow = row:CreateTexture(nil, "BACKGROUND")
    row.glow:SetAllPoints()
    row.glow:SetColorTexture(1, 0.06, 0.02, 0.10)
    row.glow:Hide()

    row.danger = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.danger:SetAllPoints()
    row.danger:SetColorTexture(1, 0.03, 0.02, 0.08)
    row.danger:Hide()

    row.health = CreateFrame("StatusBar", nil, row)
    row.health:SetPoint("TOPLEFT", 2, -2)
    row.health:SetPoint("BOTTOMRIGHT", -2, 2)
    row.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    row.health:SetMinMaxValues(0, 100)
    row.health:SetValue(0)
    row.health:SetAlpha(0.36)

    row.role = row:CreateTexture(nil, "OVERLAY")
    row.role:SetPoint("LEFT", 6, 0)
    row.role:SetSize(19, 19)
    row.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
    row.role:Hide()
    row.roleBadge = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.roleBadge:SetPoint("LEFT", 6, 0)
    row.roleBadge:SetSize(18, 18)
    KWR.Theme:Style(row.roleBadge, "panel", "border")
    row.roleBadge.icon = row.roleBadge:CreateTexture(nil, "ARTWORK")
    row.roleBadge.icon:SetPoint("TOPLEFT", 1, -1)
    row.roleBadge.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    row.roleBadge.icon:Hide()
    row.roleBadge.text = KWR.Theme:Font(row.roleBadge, 8, "white", "CENTER", "OUTLINE")
    row.roleBadge.text:SetAllPoints()
    row.roleBadge:Hide()

    row.nameText = KWR.Theme:Font(row, 10, "white", "LEFT", "OUTLINE,THICKOUTLINE")
    row.detailIcon = row:CreateTexture(nil, "ARTWORK")
    row.detailIcon:Hide()
    row.detailText = KWR.Theme:Font(row, 9, "soft", "RIGHT", "OUTLINE")
    row.healthText = KWR.Theme:Font(row, 9, "white", "RIGHT", "OUTLINE,THICKOUTLINE")
    row.stateText = KWR.Theme:Font(row, 8, "soft", "RIGHT", "OUTLINE")
    if row.nameText.SetDrawLayer then row.nameText:SetDrawLayer("OVERLAY", 7) end
    if row.healthText.SetDrawLayer then row.healthText:SetDrawLayer("OVERLAY", 7) end
    if row.health.SetFrameLevel then row.health:SetFrameLevel(0) end
    singleLine(row.nameText)
    singleLine(row.detailText)
    singleLine(row.healthText)
    singleLine(row.stateText)
    applyRowMetrics(row, 306)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.displayName or "Unit", self.classR or 1, self.classG or 1, self.classB or 1)
        if self.tooltipDetail then GameTooltip:AddLine(self.tooltipDetail, 0.75, 0.77, 0.82) end
        if self.tooltipHealth then GameTooltip:AddLine(self.tooltipHealth, 1, 1, 1) end
        if self.tooltipState then GameTooltip:AddLine(self.tooltipState, 1, 0.78, 0.25, true) end
        GameTooltip:AddLine("Left-click: target", 1, 1, 1)
        GameTooltip:AddLine("Shift+Right-click: focus", 1, 1, 1)
        if self.killReason then GameTooltip:AddLine("KWR: " .. self.killReason, 1, 0.72, 0.2, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:Hide()
    return row
end

local function roleCoords(role)
    if type(GetTexCoordsForRoleSmallCircle) == "function" then
        local left, right, top, bottom = KWR.Util:Call(GetTexCoordsForRoleSmallCircle, role)
        if left then return left, right, top, bottom end
    end
    if role == "TANK" then return 0, 0.25, 0, 1 end
    if role == "HEALER" then return 0.25, 0.50, 0, 1 end
    if role == "DAMAGER" then return 0.50, 0.75, 0, 1 end
end

local function roleBadgeStyle(role)
    if role == "TANK" then return "blue", "T" end
    if role == "HEALER" then return "green", "H" end
    if role == "DAMAGER" then return "gold", "D" end
    return "muted", "?"
end

local function formatTeamHeading(count, total)
    return "|cffd7b25cTEAM|r  "
        .. "|cffffffff" .. tostring(count) .. "/" .. tostring(total) .. "|r"
end

local function formatEnemyHeading(localEnemies, visibleEnemies, staleEnemies)
    return "|cffd7b25cENEMY|r  "
        .. tostring(localEnemies) .. " |cffff7a52HERE|r"
        .. "  |  " .. tostring(visibleEnemies) .. " |cff7db8ffLIVE|r"
        .. "  |  " .. tostring(staleEnemies) .. " |cffffc15aLAST|r"
end

local function setSpotlightIdle(spotlight)
    local function resize(fontString, size)
        local path, _, flags = fontString:GetFont()
        if path then fontString:SetFont(path, size, flags) end
    end
    spotlight.nameText:ClearAllPoints()
    spotlight.nameText:SetPoint("TOPLEFT", 10, -4)
    spotlight.nameText:SetPoint("TOPRIGHT", -10, -4)
    spotlight.nameText:SetHeight(16)
    spotlight.nameText:SetJustifyH("LEFT")
    resize(spotlight.nameText, 13)
    spotlight.detailText:ClearAllPoints()
    spotlight.detailText:SetPoint("TOPLEFT", 10, -27)
    spotlight.detailText:SetPoint("TOPRIGHT", -10, -27)
    spotlight.detailText:SetHeight(16)
    spotlight.detailText:SetJustifyH("LEFT")
    resize(spotlight.detailText, 11)
    spotlight.actionText:ClearAllPoints()
    spotlight.actionText:SetPoint("BOTTOMLEFT", 10, 4)
    spotlight.actionText:SetPoint("BOTTOMRIGHT", -10, 4)
    spotlight.actionText:SetHeight(16)
    spotlight.actionText:SetJustifyH("LEFT")
    resize(spotlight.actionText, 11)
    spotlight.nameText:SetText("NO ENEMY TARGET")
    spotlight.nameText:SetTextColor(KWR.Theme:Color("soft"))
    spotlight.detailText:SetText("Tab or click an enemy player.")
    spotlight.detailText:SetTextColor(KWR.Theme:Color("muted"))
    spotlight.statusBadge:SetTone("muted")
    spotlight.statusBadge:SetText("WATCH")
    spotlight.truthBadge:SetTone("muted")
    spotlight.truthBadge:SetText("NO TARGET")
    spotlight.statusBadge:Hide()
    spotlight.truthBadge:Hide()
    spotlight.actionText:SetText("ACTION: SELECT TARGET")
    spotlight.actionText:SetTextColor(KWR.Theme:Color("gold"))
    spotlight.actionText:Show()
    spotlight.healthText:SetText("--")
    spotlight.healthText:Hide()
    if spotlight.stateIcon then spotlight.stateIcon:Hide() end
    spotlight.health:SetMinMaxValues(0, 100)
    spotlight.health:SetValue(0)
    spotlight.health:SetStatusBarColor(0.26, 0.28, 0.31, 0.62)
    spotlight.health:Hide()
    spotlight.scrim:SetColorTexture(0.01, 0.015, 0.025, 0.92)
    spotlight.scrim:SetShown(true)
    spotlight:SetBackdropBorderColor(KWR.Theme:Color("borderHi"))
end

local function updateToken(owner, state)
    local allowed = KWR.Util:AllowsCompactBattlefieldSurfaces(state)
    local arena = KWR.Util:IsArenaContext(state)
    local shown = owner:AnyShown()
    if not shown then
        return KWR.Util:Signature({
            allowed, arena, owner.autoVisible,
            KWR.db.profile.combatRoster.teamShown,
            KWR.db.profile.combatRoster.enemyShown,
        })
    end
    local snapshot = state and state.snapshot or {}
    local context = snapshot.context or {}
    local combat = snapshot.combat or {}
    local parts = {
        true,
        KWR.db.profile.combatRoster.teamShown,
        KWR.db.profile.combatRoster.enemyShown,
        context.sessionKey,
        context.inPvP,
        context.mapKey,
        context.rosterHydration and context.rosterHydration.expected,
        combat.localTarget and (combat.localTarget.key or combat.localTarget.name),
        combat.killTarget and (combat.killTarget.key or combat.killTarget.name),
    }
    for _, player in ipairs(snapshot.roster or {}) do
        parts[#parts + 1] = KWR.Util:Signature({
            player.key, player.guid, player.name, player.unit,
            player.classFile, player.role, player.spec,
            player.specSource, player.healthPercent,
            player.lastHealthPercent, player.dead, player.connected,
            player.carrier, player.carrierStacks, player.unitStable,
        })
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        parts[#parts + 1] = KWR.Util:Signature({
            enemy.key, enemy.guid, enemy.name, enemy.unit,
            enemy.classFile, enemy.role, enemy.spec,
            enemy.healthPercent, enemy.lastHealthPercent,
            enemy.dead, enemy.visible, enemy.localRange,
            enemy.localEngaged,
            enemy.age and math.floor(enemy.age / 2),
            enemy.locationState, enemy.location,
            enemy.carrier, enemy.carrierStacks,
            enemy.trinketState, enemy.cooldownText,
            enemy.priorityCast and enemy.priorityCast.spellID,
            enemy.priorityCast and enemy.priorityCast.priority,
        })
    end
    for _, assignment in ipairs(state and state.assignments or {}) do
        parts[#parts + 1] = KWR.Util:Signature({
            assignment.key, assignment.name, assignment.role,
            assignment.shortRole, assignment.location,
            assignment.movement, assignment.target,
            assignment.display, assignment.fightMode,
            assignment.ccActor,
        })
    end
    local execution = snapshot.executionCommand or {}
    local localFight = execution.localFight or {}
    parts[#parts + 1] = localFight.updatedAt
    parts[#parts + 1] = localFight.phase
    parts[#parts + 1] = KWR.Util:Signature({
        "LOCAL_FIGHT",
        localFight.kill and localFight.kill.mode or "",
        localFight.kill and localFight.kill.target or "",
        localFight.kill and localFight.kill.targetGUID or "",
        localFight.kill and localFight.kill.location or "",
    })
    for _, control in ipairs(localFight.controls or {}) do
        parts[#parts + 1] = KWR.Util:Signature({
            "LOCAL_CONTROL",
            control.actor or "", control.actorGUID or "",
            control.target or "", control.targetGUID or "",
            control.assigned == true and "ASSIGNED" or "OPEN",
            control.state or "",
        })
    end
    return KWR.Util:Signature(parts)
end

local function frameProfile(kind)
    local profile = KWR.db.profile.combatRoster or {}
    if kind == "TEAM" then
        return profile.teamMini or profile
    end
    return profile.enemyMini or profile
end

local function syncVisibilityProfile(profile)
    profile.teamShown = profile.teamShown == true
    profile.enemyShown = profile.enemyShown == true
    profile.shown = profile.teamShown or profile.enemyShown
    if profile.teamShown and profile.enemyShown then
        profile.mode = "BOTH"
    elseif profile.teamShown then
        profile.mode = "TEAM"
    elseif profile.enemyShown then
        profile.mode = "ENEMY"
    end
end

local function anchorFrame(frame, profile)
    frame:ClearAllPoints()
    frame:SetPoint(
        profile.point or "CENTER",
        UIParent,
        profile.relativePoint or "CENTER",
        profile.x or 0,
        profile.y or 140)
end

local function rememberFrameAnchor(frame, profile)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    profile.point = point or "CENTER"
    profile.relativePoint = relativePoint or profile.point
    profile.x = x or 0
    profile.y = y or 0
    profile.anchorSpace = nil
end

local function makeFrameMovable(frame, handle, kind)
    frame:SetMovable(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        local profile = KWR.db.profile.combatRoster or {}
        if profile.locked or (InCombatLockdown and InCombatLockdown()) then return end
        frame:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        rememberFrameAnchor(frame, frameProfile(kind))
    end)
end

local function createSpotlight(parent)
    local spotlight = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    spotlight:SetHeight(COMMAND_HEIGHT)
    KWR.Theme:Style(spotlight, "card", "border")
    spotlight.health = CreateFrame("StatusBar", nil, spotlight)
    spotlight.health:SetPoint("TOPLEFT", 2, -2)
    spotlight.health:SetPoint("BOTTOMRIGHT", -2, 2)
    spotlight.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    spotlight.health:SetMinMaxValues(0, 100)
    spotlight.health:SetValue(0)
    spotlight.health:SetStatusBarColor(0.26, 0.28, 0.31, 0.24)
    spotlight.scrim = spotlight:CreateTexture(nil, "ARTWORK", nil, 2)
    spotlight.scrim:SetPoint("TOPLEFT", 2, -2)
    spotlight.scrim:SetPoint("BOTTOMRIGHT", -2, 2)
    spotlight.scrim:SetColorTexture(0.02, 0.03, 0.05, 0.46)
    spotlight.rule = spotlight:CreateTexture(nil, "ARTWORK")
    spotlight.rule:SetColorTexture(KWR.Theme:Color("border"))
    spotlight.rule:SetPoint("TOPLEFT", 10, -20)
    spotlight.rule:SetPoint("TOPRIGHT", -10, -20)
    spotlight.rule:SetHeight(1)
    spotlight.nameText = KWR.Theme:Font(spotlight, 12, "white", "LEFT", "OUTLINE")
    spotlight.stateIcon = spotlight:CreateTexture(nil, "ARTWORK")
    spotlight.stateIcon:SetPoint("TOPLEFT", 10, -4)
    spotlight.stateIcon:SetSize(14, 14)
    spotlight.stateIcon:Hide()
    spotlight.nameText:SetPoint("LEFT", spotlight.stateIcon, "RIGHT", 6, 0)
    spotlight.nameText:SetWidth(170)
    singleLine(spotlight.nameText)
    spotlight.detailText = KWR.Theme:Font(spotlight, 9, "soft", "LEFT", "OUTLINE")
    singleLine(spotlight.detailText)
    spotlight.statusBadge = KWR.Theme:Badge(spotlight, "muted", "OBSERVE", 72, 14)
    spotlight.statusBadge:SetPoint("BOTTOMLEFT", 10, 3)
    spotlight.truthBadge = KWR.Theme:Badge(spotlight, "muted", "NO DATA", 66, 14)
    spotlight.truthBadge:SetPoint("LEFT", spotlight.statusBadge, "RIGHT", 6, 0)
    spotlight.detailText:SetPoint("LEFT", spotlight.truthBadge, "RIGHT", 8, 0)
    spotlight.detailText:SetPoint("RIGHT", -126, 0)
    spotlight.detailText:SetHeight(14)
    spotlight.healthText = KWR.Theme:Font(spotlight, 11, "white", "RIGHT", "OUTLINE")
    spotlight.healthText:SetPoint("TOPRIGHT", -10, -4)
    spotlight.healthText:SetWidth(96)
    singleLine(spotlight.healthText)
    spotlight.actionText = KWR.Theme:Font(spotlight, 9, "gold", "RIGHT", "OUTLINE")
    spotlight.actionText:SetPoint("BOTTOMRIGHT", -10, 3)
    spotlight.actionText:SetWidth(116)
    singleLine(spotlight.actionText)
    setSpotlightIdle(spotlight)
    return spotlight
end

local function createTrackerFrame(owner, kind)
    local lower = kind == "TEAM" and "Team" or "Enemy"
    local frame = CreateFrame("Frame", "KWR_CombatRoster" .. lower, UIParent, "BackdropTemplate")
    local profile = frameProfile(kind)
    anchorFrame(frame, profile)
    -- CombatRoster contains protected secure rows. Keep its layer fixed at
    -- creation time; LayoutCoordinator must never mutate it after creation.
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    frame:Hide()

    frame.toolbar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.toolbar:SetPoint("TOPLEFT", FRAME_PADDING, -FRAME_PADDING)
    frame.toolbar:SetPoint("TOPRIGHT", -FRAME_PADDING, -FRAME_PADDING)
    frame.toolbar:SetHeight(TOOLBAR_HEIGHT)
    KWR.Theme:Style(frame.toolbar, "raised", "border")
    makeFrameMovable(frame, frame.toolbar, kind)

    frame.title = KWR.Theme:Title(frame.toolbar, 10)
    frame.title:SetText(kind == "TEAM" and "TEAM" or "ENEMY")
    frame.brand = frame.toolbar:CreateTexture(nil, "ARTWORK")
    frame.brand:SetPoint("LEFT", 6, 0)
    frame.brand:SetSize(14, 14)
    if KWR.Icons then
        KWR.Icons:ApplyBrand(frame.brand, "mark")
    end
    frame.title:SetPoint("LEFT", frame.brand, "RIGHT", 6, 0)
    frame.title:SetWidth(100)
    singleLine(frame.title)

    frame.expandButton = KWR.Theme:Button(frame.toolbar, "EXPAND", 60, 20, function()
        owner:Expand(kind)
    end)
    frame.expandButton:SetPoint("RIGHT", -26, 0)
    frame.closeButton = KWR.Theme:Button(frame.toolbar, "X", 20, 20, function()
        owner:Hide(kind)
    end)
    frame.closeButton:SetPoint("RIGHT", -4, 0)
    frame.linkButton = KWR.Theme:Button(
        frame.toolbar,
        kind == "TEAM" and "ENEMY" or "TEAM",
        52,
        20,
        function()
            owner:Show(kind == "TEAM" and "ENEMY" or "TEAM")
        end)
    frame.linkButton:SetPoint("RIGHT", frame.expandButton, "LEFT", -2, 0)
    frame.linkButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(kind == "TEAM"
            and "Open Enemy tracker"
            or "Open Team tracker", 1, 0.84, 0.24)
        GameTooltip:Show()
    end)
    frame.linkButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.pane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    KWR.Theme:Style(frame.pane, "panel", "border")
    frame.headingIcon = frame.pane:CreateTexture(nil, "ARTWORK")
    frame.headingIcon:SetPoint("TOPLEFT", 8, -7)
    frame.headingIcon:SetSize(12, 12)
    if KWR.Icons then
        KWR.Icons:Apply(frame.headingIcon, kind == "TEAM" and "friendly" or "enemy", 16)
    end
    frame.heading = KWR.Theme:Font(frame.pane, 9, "white", "LEFT", "OUTLINE")
    frame.heading:SetPoint("LEFT", frame.headingIcon, "RIGHT", 5, 0)
    frame.heading:SetPoint("TOP", frame.headingIcon, "TOP", 0, 1)
    frame.heading:SetPoint("TOPRIGHT", -8, -6)
    frame.heading:SetHeight(16)
    singleLine(frame.heading)

    if kind == "ENEMY" then
        frame.targetSpotlight = createSpotlight(frame)
    end

    return frame
end

function CombatRoster:AnyShown()
    return (self.teamFrame and self.teamFrame:IsShown())
        or (self.enemyFrame and self.enemyFrame:IsShown()) or false
end

function CombatRoster:IsShown(mode)
    if mode == "TEAM" then
        return self.teamFrame and self.teamFrame:IsShown() or false
    end
    if mode == "ENEMY" then
        return self.enemyFrame and self.enemyFrame:IsShown() or false
    end
    return self:AnyShown()
end

function CombatRoster:ShownMode()
    local teamShown = self:IsShown("TEAM")
    local enemyShown = self:IsShown("ENEMY")
    if teamShown and enemyShown then return "BOTH" end
    if teamShown then return "TEAM" end
    if enemyShown then return "ENEMY" end
    return KWR.db.profile.combatRoster.mode or "BOTH"
end

function CombatRoster:ResetRow(row, hide)
    if not row then return end
    row.visualSignature = nil
    row.boundKey = nil
    row.boundName = nil
    row.boundTeam = nil
    row.displayUnit = nil
    row.displayName = nil
    row.tooltipDetail = nil
    row.tooltipHealth = nil
    row.tooltipState = nil
    row.killReason = nil
    row.classR, row.classG, row.classB = nil, nil, nil
    row.health:SetMinMaxValues(0, 100)
    row.health:SetValue(0)
    row.health:SetStatusBarColor(0.22, 0.24, 0.27, 0.45)
    row.healthText:SetText("--")
    row.healthText:SetTextColor(KWR.Theme:Color("muted"))
    row.nameText:SetText("")
    if row.detailIcon then
        row.detailIcon:SetTexture(nil)
        row.detailIcon:Hide()
    end
    row.detailText:SetText("")
    row.stateText:SetText("")
    row.glow:Hide()
    row.danger:Hide()
    row.role:Hide()
    if row.roleBadge then row.roleBadge:Hide() end
    row:SetAlpha(1)
    row:SetBackdropBorderColor(KWR.Theme:Color("border"))
    if hide then row:Hide() end
    row.reset = true
end

function CombatRoster:ResetVisualCache(hideRows)
    self.lastSpotlightKey = nil
    self.lastSpotlightSignature = nil
    self.teamHeadingSignature = nil
    self.enemyHeadingSignature = nil
    self.enemySlotKeys = {}
    self.rebindPending = false
    for _, rows in ipairs({ self.teamRows, self.enemyRows }) do
        for _, row in ipairs(rows) do
            self:ResetRow(row, hideRows == true)
        end
    end
    local spotlight = self.enemyFrame and self.enemyFrame.targetSpotlight
    if spotlight then
        setSpotlightIdle(spotlight)
    end
end

function CombatRoster:Create()
    if self.teamFrame and self.enemyFrame then return self.enemyFrame end
    self.teamFrame = self.teamFrame or createTrackerFrame(self, "TEAM")
    self.enemyFrame = self.enemyFrame or createTrackerFrame(self, "ENEMY")
    self.frame = self.enemyFrame

    for index = 1, self.maxRows do
        self.teamRows[index] = self.teamRows[index]
            or createSecureRow(self.teamFrame.pane, "KWR_CompactTeamRow" .. index)
        self.enemyRows[index] = self.enemyRows[index]
            or createSecureRow(self.enemyFrame.pane, "KWR_CompactEnemyRow" .. index)
    end

    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame", "KWR_CombatRosterEvents")
        for _, event in ipairs({
            "PLAYER_REGEN_ENABLED", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
            "UNIT_HEALTH", "UNIT_MAXHEALTH",
        }) do
            pcall(self.eventFrame.RegisterEvent, self.eventFrame, event)
        end
        self.eventFrame:SetScript("OnEvent", function(_, event, unit)
            if event == "PLAYER_REGEN_ENABLED" then
                CombatRoster:FlushPending()
            elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
                if CombatRoster.lastState then CombatRoster:Update(CombatRoster.lastState) end
            elseif unit then
                CombatRoster:UpdateHealthForUnit(unit)
                if unit == "target" and CombatRoster.lastState then
                    CombatRoster:UpdateSpotlight(
                        CombatRoster.lastState.snapshot.enemies,
                        CombatRoster.lastState.snapshot.combat,
                        CombatRoster.lastState.snapshot.executionCommand
                            and CombatRoster.lastState.snapshot.executionCommand.localFight,
                        CombatRoster.lastState.snapshot.executionCommand
                            and CombatRoster.lastState.snapshot.executionCommand.countdown)
                end
            end
        end)
    end

    self:Layout()
    return self.enemyFrame
end

function CombatRoster:DirectHealth(row, unit)
    KWR.CombatRosterVisuals:DirectHealth(self, row, unit)
end

function CombatRoster:DirectSpotlightHealth(data)
    KWR.CombatRosterVisuals:DirectSpotlightHealth(self, data)
end

function CombatRoster:UpdateSpotlight(enemies, combat, localFight, countdown)
    KWR.CombatRosterVisuals:UpdateSpotlight(self, enemies, combat, localFight,
        countdown, {
        sameUnitOrName = sameUnitOrName,
        activeCombatTarget = activeCombatTarget,
        activeCombatReason = activeCombatReason,
        spotlightFallbackRank = spotlightFallbackRank,
        setSpotlightIdle = setSpotlightIdle,
        classColor = classColor,
        truthTone = truthTone,
    })
end

function CombatRoster:UpdateHealthForUnit(unit)
    local matched = false
    for _, rows in ipairs({ self.teamRows, self.enemyRows }) do
        for _, row in ipairs(rows) do
            if row.displayUnit == unit then
                self:DirectHealth(row, unit)
                matched = true
            end
        end
    end
    if matched or not self.lastState or not unit then return end

    local resolved
    local function resolve(collection)
        for _, entry in ipairs(collection or {}) do
            if entry.unit == unit then
                resolved = entry
                return true
            end
        end
        return false
    end
    if not resolve(self.lastState.snapshot and self.lastState.snapshot.roster) then
        resolve(self.lastState.snapshot and self.lastState.snapshot.enemies)
    end
    if not resolved then return end

    for _, rows in ipairs({ self.teamRows, self.enemyRows }) do
        for _, row in ipairs(rows) do
            if (row.boundKey and resolved.key and row.boundKey == resolved.key)
                or (row.boundName and resolved.name
                    and KWR.Util:Text(row.boundName, "", 64):lower()
                        == KWR.Util:Text(resolved.name, "", 64):lower()) then
                row.displayUnit = unit
                self:DirectHealth(row, unit)
            end
        end
    end
end

function CombatRoster:ApplyRole(row, role)
    KWR.CombatRosterVisuals:ApplyRole(self, row, role, {
        roleBadgeStyle = roleBadgeStyle,
        roleCoords = roleCoords,
    })
end

function CombatRoster:ApplyBinding(row, data, team)
    return KWR.CombatRosterVisuals:ApplyBinding(self, row, data, team)
end

function CombatRoster:Visual(row, data, team, combat, assignment)
    KWR.CombatRosterVisuals:Visual(self, row, data, team, combat, assignment, {
        sameUnitOrName = sameUnitOrName,
        activeCombatTarget = activeCombatTarget,
        activeCombatReason = activeCombatReason,
        classColor = classColor,
        healthColor = healthColor,
    })
end

function CombatRoster:UpdateRows(rows, data, team, combat, assignments, allowBinding, shown)
    KWR.CombatRosterVisuals:UpdateRows(
        self, rows, data, team, combat, assignments, allowBinding, shown)
end

function CombatRoster:UpdateBoundRows(rows, data, team, combat, assignments)
    KWR.CombatRosterVisuals:UpdateBoundRows(
        self, rows, data, team, combat, assignments)
end

function CombatRoster:Update(state)
    KWR.CombatRosterState:Update(self, state, {
        formatTeamHeading = formatTeamHeading,
        formatEnemyHeading = formatEnemyHeading,
    })
end

function CombatRoster:Layout(mode)
    KWR.CombatRosterState:Layout(self, mode, {
        applyRowMetrics = applyRowMetrics,
        laneHeight = laneHeight,
        frameHeight = frameHeight,
        ROW_SPACING = ROW_SPACING,
        ROW_TOP = ROW_TOP,
        FRAME_PADDING = FRAME_PADDING,
        TOOLBAR_HEIGHT = TOOLBAR_HEIGHT,
        COMMAND_HEIGHT = COMMAND_HEIGHT,
        SECTION_GAP = SECTION_GAP,
        SOLO_WIDTH = SOLO_WIDTH,
    })
end

function CombatRoster:PersistedTeamShown()
    local profile = KWR.db.profile.combatRoster or {}
    return profile.teamShown == true
end

function CombatRoster:PersistedEnemyShown()
    local profile = KWR.db.profile.combatRoster or {}
    return profile.enemyShown == true
end

function CombatRoster:RequestVisibility(teamShown, enemyShown, persist)
    local state = currentState(self.lastState)
    if not KWR.Util:AllowsCompactBattlefieldSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        if self.teamFrame then self.teamFrame:Hide() end
        if self.enemyFrame then self.enemyFrame:Hide() end
        self.autoVisible = false
        return false
    end
    if not self.teamFrame and InCombatLockdown and InCombatLockdown() then
        self.pending = {
            teamShown = teamShown,
            enemyShown = enemyShown,
            persist = persist,
        }
        KWR:Print("Combat roster creation queued until combat ends.", true)
        return false
    end
    self:Create()
    if InCombatLockdown and InCombatLockdown() then
        self.pending = {
            teamShown = teamShown,
            enemyShown = enemyShown,
            persist = persist,
        }
        KWR:Print("Combat roster layout change queued until combat ends.", true)
        return false
    end

    local profile = KWR.db.profile.combatRoster
    if persist == false then
        self.autoVisible = teamShown == true or enemyShown == true
    else
        profile.teamShown = teamShown == true
        profile.enemyShown = enemyShown == true
        syncVisibilityProfile(profile)
        if not profile.shown then
            self.autoVisible = false
        end
    end

    self.teamFrame:SetShown(teamShown == true)
    self.enemyFrame:SetShown(enemyShown == true)
    self:Layout(self:ShownMode())
    if teamShown == true or enemyShown == true then
        self:Update(currentState())
    end
    return true
end

function CombatRoster:Request(shown, mode, persist)
    if shown ~= true then
        return self:RequestVisibility(false, false, persist)
    end
    mode = mode == "TEAM" and "TEAM" or (mode == "ENEMY" and "ENEMY" or "BOTH")
    if mode == "TEAM" then
        return self:RequestVisibility(true, false, persist)
    end
    if mode == "ENEMY" then
        return self:RequestVisibility(false, true, persist)
    end
    return self:RequestVisibility(true, true, persist)
end

function CombatRoster:Show(mode, persist)
    local state = currentState(self.lastState)
    if not KWR.Util:AllowsCompactBattlefieldSurfaces(state)
        or KWR.Util:IsArenaContext(state) then return false end
    if KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown() then
        KWR.MainWindow:MinimizeTo("ROSTER", mode)
        return
    end
    return self:Request(true, mode, persist)
end

function CombatRoster:Hide(mode, persist)
    if mode == "TEAM" then
        return self:RequestVisibility(false, self:IsShown("ENEMY"), persist)
    end
    if mode == "ENEMY" then
        return self:RequestVisibility(self:IsShown("TEAM"), false, persist)
    end
    return self:Request(false, nil, persist)
end

function CombatRoster:Toggle(mode)
    local state = currentState(self.lastState)
    if not KWR.Util:AllowsCompactBattlefieldSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        if self.teamFrame then self.teamFrame:Hide() end
        if self.enemyFrame then self.enemyFrame:Hide() end
        return false
    end
    if mode == "TEAM" then
        return self:RequestVisibility(not self:IsShown("TEAM"), self:IsShown("ENEMY"), true)
    end
    if mode == "ENEMY" then
        return self:RequestVisibility(self:IsShown("TEAM"), not self:IsShown("ENEMY"), true)
    end
    local show = not (self:IsShown("TEAM") and self:IsShown("ENEMY"))
    return self:RequestVisibility(show, show, true)
end

function CombatRoster:Expand(mode)
    mode = mode or self:ShownMode()
    KWR.MainWindow:Show(mode == "TEAM" and "TEAM" or (mode == "ENEMY" and "ENEMIES" or "TACTICAL"))
end

function CombatRoster:FlushPending()
    if self.pending then
        local pending = self.pending
        self.pending = nil
        self:RequestVisibility(pending.teamShown, pending.enemyShown, pending.persist)
    end
    if self.lastState and not (InCombatLockdown and InCombatLockdown()) then
        self:Update(currentState())
    end
end

function CombatRoster:OnInitialize()
    if KWR.Store and KWR.Store.SubscribeFiltered then
        KWR.Store:SubscribeFiltered(self, self.Update, updateToken)
    end
end

function CombatRoster:OnEnable()
    local profile = KWR.db.profile.combatRoster
    if profile.teamShown or profile.enemyShown then
        self:RequestVisibility(profile.teamShown, profile.enemyShown, false)
    end
end

function CombatRoster:OnDisable()
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
end

KWR:RegisterModule("CombatRoster", CombatRoster)
