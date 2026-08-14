local _, KWR = ...

local CursorRing = {}
KWR.CursorRing = CursorRing

local function currentState(fallback)
    if fallback then
        return fallback
    end
    if KWR.Store and type(KWR.Store.Get) == "function" then
        return KWR.Store:Get()
    end
    return nil
end

local COMBAT_COLORS = KWR.Theme.combatColors

local MODE_COLORS = {
    NEUTRAL = COMBAT_COLORS.NEUTRAL,
    DANGER = COMBAT_COLORS.KILL,
    CAUTION = COMBAT_COLORS.STOP,
    ROTATE = COMBAT_COLORS.MOVE,
    RECOVERY = COMBAT_COLORS.RECOVERY,
    UNKNOWN = COMBAT_COLORS.UNKNOWN,
}

local RETICLE_COLORS = {
    TARGET = COMBAT_COLORS.TARGET,
    KILL = COMBAT_COLORS.KILL,
    STOP = COMBAT_COLORS.STOP,
    SWAP = COMBAT_COLORS.SWAP,
    IMMUNE = COMBAT_COLORS.IMMUNE,
    CARRY = COMBAT_COLORS.CARRY,
}

local ORB_COLORS = {
    TEAM = COMBAT_COLORS.TEAM,
    HEALER = COMBAT_COLORS.HEALER,
    TANK = COMBAT_COLORS.TANK,
    DAMAGE = COMBAT_COLORS.DAMAGE,
    KILL = COMBAT_COLORS.KILL,
    STOP = COMBAT_COLORS.STOP,
    IMMUNE = COMBAT_COLORS.IMMUNE,
    CARRY = COMBAT_COLORS.CARRY,
    STALE = COMBAT_COLORS.STALE,
}

local ROLE_ICON_TCOORDS = {
    TANK = { 0 / 256, 65 / 256, 0 / 256, 66 / 256 },
    HEALER = { 67 / 256, 132 / 256, 0 / 256, 66 / 256 },
    DAMAGER = { 134 / 256, 199 / 256, 0 / 256, 66 / 256 },
}

local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local ROLE_ICON_TEXTURE = "Interface\\LFGFRAME\\UI-LFG-ICON-PORTRAITROLES"
local ORB_ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Orb_05"
local ENEMY_RING_ATLAS = "charactercreate-ring-select"
local TEAM_BADGE_TEXTURE = "Interface\\Buttons\\UI-Quickslot2"
local CARRIER_COLORS = {
    ALLIANCE = { 0.22, 0.55, 1.00 },
    HORDE = { 0.95, 0.18, 0.16 },
    BLUE = { 0.18, 0.52, 1.00 },
    GREEN = { 0.18, 0.88, 0.36 },
    ORANGE = { 1.00, 0.46, 0.08 },
    PURPLE = { 0.68, 0.34, 0.96 },
}

local MARKER_MODES = {
    NATIVE = true,
    TACTICAL_ONLY = true,
    OFF = true,
}

local function roleIconCoords(role)
    if type(GetTexCoordsForRoleSmallCircle) == "function" then
        local left, right, top, bottom = KWR.Util:Call(
            GetTexCoordsForRoleSmallCircle, role)
        if left then return { left, right, top, bottom } end
    end
    return ROLE_ICON_TCOORDS[role]
end

-- These are explicit PvP practice NPCs, not a broad training-dummy name
-- match. The IDs keep the preview exception locale-independent and prevent
-- the reticle from appearing on ordinary PvE targets.
local PVP_TRAINING_DUMMY_IDS = {
    [114832] = true,
    [114840] = true,
    [197834] = true,
    [219250] = true,
    [219251] = true,
    [243211] = true,
    [243212] = true,
    [255824] = true,
    [255825] = true,
}

local function creatureIDFromGUID(guid)
    if type(guid) ~= "string" or not guid:find("^Creature%-") then
        return nil
    end
    local parts = {}
    for part in guid:gmatch("[^%-]+") do parts[#parts + 1] = part end
    return tonumber(parts[#parts - 1])
end

local function isPreviewPvPTrainingDummy(state, unit)
    local context = state and state.snapshot and state.snapshot.context or {}
    if context.preview ~= true or unit ~= "target" or type(UnitGUID) ~= "function" then
        return false
    end
    local guid = KWR.Util:Call(UnitGUID, unit)
    return PVP_TRAINING_DUMMY_IDS[creatureIDFromGUID(guid)] == true
end

-- Nameplate markers must remain legible in battleground movement and against
-- the default health-bar scale. Keep these centralized so the ring, icon,
-- label, and health strip scale as one visual unit.
local ENEMY_ICON_SIZE = 42
local FRIENDLY_ROLE_ICON_SIZE = 32
local ORB_RING_SIZE = 48
local ORB_FRAME_WIDTH = 52
local ORB_FRAME_HEIGHT = 52

local function applyEnemyRingTexture(texture)
    -- This Retail atlas is the native circular selection ring. Fall back to a
    -- built-in round texture on clients or test harnesses without atlas APIs.
    if type(texture.SetAtlas) == "function"
        and pcall(texture.SetAtlas, texture, ENEMY_RING_ATLAS, false) then
        texture:SetSize(ORB_RING_SIZE, ORB_RING_SIZE)
        return
    end
    texture:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
end

local function sameTargetRecord(record)
    if not record then return false end
    if record.unit and type(UnitIsUnit) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsUnit, record.unit, "target"), false) then
        return true
    end
    local targetName = KWR.Util:UnitName("target")
    local shortTarget = targetName and KWR.Util:ShortName(targetName):lower()
    local shortRecord = KWR.Util:Text(record.shortName or record.name, "", 64):lower()
    return shortTarget and shortRecord ~= "" and shortTarget == shortRecord
end

local function sameRecordUnit(record, unit)
    if not record or not unit then return false end
    if record.unit and type(UnitIsUnit) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsUnit, record.unit, unit), false) then
        return true
    end
    local unitName = KWR.Util:UnitName(unit)
    local shortUnit = unitName and KWR.Util:ShortName(unitName):lower()
    local shortRecord = KWR.Util:Text(record.shortName or record.name, "", 64):lower()
    return shortUnit and shortRecord ~= "" and shortUnit == shortRecord
end

local function classColor(classFile)
    local color = type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[classFile]
    if color then return color.r or 0.7, color.g or 0.7, color.b or 0.7 end
    return 0.72, 0.72, 0.72
end

local function healthBarColor(percent, fallback)
    percent = KWR.Util:Number(percent, nil)
    if not percent then
        return fallback and fallback[1] or 0.26,
            fallback and fallback[2] or 0.28,
            fallback and fallback[3] or 0.31
    end
    if percent <= 35 then return 0.92, 0.12, 0.10 end
    if percent <= 70 then return 0.92, 0.58, 0.10 end
    return 0.18, 0.72, 0.20
end

local function sameEntity(left, right)
    if not left or not right then return false end
    local leftKey = KWR.Util:Text(left.guid or left.key, "", 96):lower()
    local rightKey = KWR.Util:Text(right.guid or right.key, "", 96):lower()
    if leftKey ~= "" and rightKey ~= "" and leftKey == rightKey then return true end
    local leftName = KWR.Util:ShortName(KWR.Util:Text(
        left.shortName or left.name or left.target, "", 80)):lower()
    local rightName = KWR.Util:ShortName(KWR.Util:Text(
        right.shortName or right.name or right.target, "", 80)):lower()
    return leftName ~= "" and rightName ~= "" and leftName == rightName
end

local function carrierVisual(record)
    if not record or record.carrier ~= true then return nil end
    local objective = KWR.Util:Upper(record.carriedObjective, "", 48)
    local colorKey = objective:match("^(%S+)") or ""
    local colors = CARRIER_COLORS[colorKey] or ORB_COLORS.CARRY.outer
    if objective:find("ORB", 1, true) then
        return {
            kind = "ORB",
            texture = ORB_ICON_TEXTURE,
            colors = colors,
            tint = colors,
            badge = "O",
        }
    end
    local texture = colorKey == "ALLIANCE"
        and "Interface\\WorldStateFrame\\AllianceFlag"
        or (colorKey == "HORDE" and "Interface\\WorldStateFrame\\HordeFlag" or nil)
    return {
        kind = "FLAG",
        texture = texture,
        colors = colors,
        tint = texture and { 1, 1, 1 } or colors,
        badge = "F",
    }
end

function CursorRing:CreateCursorFrame()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KWR_CursorRing", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9000)
    frame:EnableMouse(false)
    frame:Hide()

    local outer = frame:CreateTexture(nil, "ARTWORK")
    outer:SetAllPoints()
    outer:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    outer:SetBlendMode("ADD")
    outer:SetVertexColor(0.15, 0.75, 1, 1)
    frame.outer = outer

    local inner = frame:CreateTexture(nil, "OVERLAY")
    inner:SetPoint("CENTER")
    inner:SetTexture("Interface\\Cooldown\\star4")
    inner:SetBlendMode("ADD")
    inner:SetVertexColor(1, 0.72, 0.18, 0.35)
    frame.inner = inner

    self.frame = frame
    return frame
end

function CursorRing:CreateReticleFrame()
    if self.reticle then return self.reticle end
    local frame = CreateFrame("Frame", "KWR_TargetReticle", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9050)
    frame:EnableMouse(false)
    frame:Hide()

    frame.hLine = frame:CreateTexture(nil, "BACKGROUND")
    frame.hLine:SetPoint("CENTER")
    frame.hLine:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.vLine = frame:CreateTexture(nil, "BACKGROUND")
    frame.vLine:SetPoint("CENTER")
    frame.vLine:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.outer = frame:CreateTexture(nil, "ARTWORK")
    frame.outer:SetPoint("CENTER")
    frame.outer:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    frame.outer:SetBlendMode("ADD")

    frame.inner = frame:CreateTexture(nil, "OVERLAY")
    frame.inner:SetPoint("CENTER")
    frame.inner:SetTexture("Interface\\Cooldown\\star4")
    frame.inner:SetBlendMode("ADD")

    frame.targetIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.targetIcon:SetPoint("CENTER")
    frame.targetIcon:SetSize(28, 28)
    frame.targetIcon:Hide()

    frame.pulse = frame:CreateTexture(nil, "OVERLAY")
    frame.pulse:SetPoint("CENTER")
    frame.pulse:SetTexture("Interface\\Cooldown\\star4")
    frame.pulse:SetBlendMode("ADD")

    frame.labelPlate = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    KWR.Theme:Style(frame.labelPlate, "panel", "borderHi")
    frame.labelPlate:SetBackdropColor(0, 0, 0, 0)
    frame.labelPlate:SetPoint("RIGHT", frame, "LEFT", -8, 0)
    frame.labelPlate:SetSize(78, 16)
    frame.label = KWR.Theme:Title(frame.labelPlate, 9, "RIGHT")
    frame.label:SetAllPoints()
    frame.detailPlate = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    KWR.Theme:Style(frame.detailPlate, "panel", "border")
    frame.detailPlate:SetBackdropColor(0, 0, 0, 0)
    frame.detailPlate:SetPoint("RIGHT", frame.labelPlate, "LEFT", -4, 0)
    frame.detailPlate:SetSize(126, 14)
    frame.detail = KWR.Theme:Font(frame.detailPlate, 8, "soft", "CENTER", "OUTLINE")
    frame.detail:SetAllPoints()

    self.reticle = frame
    return frame
end

function CursorRing:CreateOrbFrame(unit)
    self.orbFrames = self.orbFrames or {}
    local frame = self.orbFrames[unit]
    if frame then return frame end

    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9040)
    frame:EnableMouse(false)
    frame:SetSize(ORB_FRAME_WIDTH, ORB_FRAME_HEIGHT)
    frame:Hide()

    frame.ring = frame:CreateTexture(nil, "ARTWORK")
    frame.ring:SetPoint("CENTER", frame, "CENTER", 0, 8)
    frame.ring:SetSize(ORB_RING_SIZE, ORB_RING_SIZE)
    applyEnemyRingTexture(frame.ring)
    frame.ring:SetBlendMode("ADD")

    frame.square = frame:CreateTexture(nil, "ARTWORK")
    frame.square:SetPoint("CENTER", frame.ring, "CENTER")
    frame.square:SetSize(42, 42)
    frame.square:SetTexture(TEAM_BADGE_TEXTURE)
    frame.square:SetBlendMode("ADD")
    frame.square:Hide()

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetPoint("CENTER", frame.ring, "CENTER")
    frame.icon:SetSize(ENEMY_ICON_SIZE, ENEMY_ICON_SIZE)

    frame.badge = KWR.Theme:Title(frame, 10, "CENTER")
    frame.badge:SetPoint("CENTER", frame.ring, "CENTER", 0, 0)
    frame.badge:SetWidth(24)
    frame.badge:SetHeight(16)

    frame.name = KWR.Theme:Font(frame, 10, "white", "LEFT", "OUTLINE")
    frame.name:SetPoint("TOP", frame.ring, "BOTTOM", 0, -3)
    frame.name:SetWidth(ORB_FRAME_WIDTH)
    frame.name:SetHeight(16)

    frame.health = CreateFrame("StatusBar", nil, frame)
    frame.health:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 10, 11)
    frame.health:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -10, 11)
    frame.health:SetHeight(5)
    frame.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    frame.health:SetMinMaxValues(0, 100)
    frame.health:SetValue(0)
    frame.health:Hide()

    frame.healthText = KWR.Theme:Font(frame, 7, "white", "RIGHT", "OUTLINE")
    frame.healthText:SetPoint("BOTTOMRIGHT", frame.health, "TOPRIGHT", 0, 1)
    frame.healthText:SetWidth(30)
    frame.healthText:SetHeight(10)

    frame.cast = CreateFrame("StatusBar", nil, frame)
    frame.cast:SetPoint("TOPLEFT", frame.health, "BOTTOMLEFT", 0, -1)
    frame.cast:SetPoint("TOPRIGHT", frame.health, "BOTTOMRIGHT", 0, -1)
    frame.cast:SetHeight(4)
    frame.cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    frame.cast:SetStatusBarColor(0.86, 0.38, 1.00, 0.88)
    frame.cast:SetMinMaxValues(0, 8)
    frame.cast:SetValue(0)
    frame.cast:Hide()

    frame.castText = KWR.Theme:Font(frame, 7, "gold", "LEFT", "OUTLINE")
    frame.castText:SetPoint("BOTTOMLEFT", frame.cast, "TOPLEFT", 0, 1)
    frame.castText:SetWidth(84)
    frame.castText:SetHeight(10)
    frame.castText:Hide()

    self.orbFrames[unit] = frame
    return frame
end

function CursorRing:CreateTacticalBadgeFrame(unit)
    self.tacticalBadgeFrames = self.tacticalBadgeFrames or {}
    local frame = self.tacticalBadgeFrames[unit]
    if frame then return frame end

    frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9041)
    frame:EnableMouse(false)
    frame:SetSize(64, 14)
    KWR.Theme:Style(frame, "panel", "borderHi")
    frame:SetBackdropColor(0, 0, 0, 0.64)
    frame.text = KWR.Theme:Title(frame, 8, "CENTER")
    frame.text:SetAllPoints()
    frame:Hide()
    self.tacticalBadgeFrames[unit] = frame
    return frame
end

function CursorRing:HideOrb(unit)
    if self.orbFrames and self.orbFrames[unit] then
        self.orbFrames[unit]:Hide()
    end
end

function CursorRing:HideTacticalBadge(unit)
    if self.tacticalBadgeFrames and self.tacticalBadgeFrames[unit] then
        self.tacticalBadgeFrames[unit]:Hide()
    end
end

function CursorRing:HideAllOrbs()
    if not self.orbFrames then return end
    self.orbVisibleCount = 0
    for _, frame in pairs(self.orbFrames) do frame:Hide() end
    for _, frame in pairs(self.tacticalBadgeFrames or {}) do frame:Hide() end
end

function CursorRing:FindFriendlyRecord(unit, state)
    if not unit or not state then return nil end
    for _, player in ipairs(state.snapshot and state.snapshot.roster or {}) do
        if sameRecordUnit(player, unit) then return player end
    end
    return nil
end

function CursorRing:FindEnemyRecord(unit, state)
    if not unit or not state then return nil end
    for _, enemy in ipairs(state.snapshot and state.snapshot.enemies or {}) do
        if sameRecordUnit(enemy, unit) then return enemy end
    end
    return nil
end

function CursorRing:AssignmentFor(name)
    if not self.assignmentIndex then return nil end
    local key = KWR.Util:Text(name, "", 64):lower()
    if key == "" then return nil end
    return self.assignmentIndex[key]
end

function CursorRing:ResolveMarkerMode()
    local profile = KWR.db.profile.cursor or {}
    local mode = KWR.Util:Upper(profile.markerMode, "NATIVE", 20)
    return MARKER_MODES[mode] and mode or "NATIVE"
end

local function assignmentBadgeText(assignment)
    local role = KWR.Util:Upper(assignment and assignment.role, "", 48)
    local job = KWR.Util:Upper(assignment and assignment.job, "", 24)
    if role:find("CARRIER", 1, true) then return "CARRY" end
    if role:find("DEFEND", 1, true) or job == "DEFEND" then return "DEFEND" end
    if role:find("HEAL", 1, true) or job == "HEAL" then return "HEAL" end
    if role:find("ESCORT", 1, true) then return "ESCORT" end
    if role:find("RESERVE", 1, true) then return "RESERVE" end
    if role:find("ROTAT", 1, true) or job == "ROTATE" then return "ROTATE" end
    if role:find("ASSAULT", 1, true) or role:find("STRIKE", 1, true)
        or job == "FIGHT" or job == "SPIN" then
        return "STRIKE"
    end
    return ""
end

function CursorRing:RefreshTacticalBadgeForUnit(unit, plate, record, isFriend, mode)
    local profile = KWR.db.profile.cursor or {}
    local frame = self:CreateTacticalBadgeFrame(unit)
    if profile.battlefieldOrbs == false or profile.assignmentBadges == false
        or mode == "OFF" or not isFriend or not record then
        frame:Hide()
        return
    end
    local assignment = self:AssignmentFor(record.name)
        or self:AssignmentFor(record.shortName)
    local text = assignmentBadgeText(assignment)
    if text == "" then
        frame:Hide()
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOP", plate, "BOTTOM", 0, -2)
    frame.text:SetText(text)
    frame:SetShown(true)
end

function CursorRing:BuildIdentifierModel(record, isFriend, state, currentTarget)
    record = record or {}
    local role = KWR.Util:Upper(record.role or record.groupRole, "UNKNOWN", 12)
    if role == "DAMAGE" then role = "DAMAGER" end
    local classFile = KWR.Util:Upper(record.classFile, "", 24)
    local carrier = carrierVisual(record)
    local priorityCast = type(record.priorityCast) == "table"
        and KWR.Util:Number(record.priorityCast.remaining, 0) > 0
        and record.priorityCast or nil
    local model = {
        name = KWR.Util:Text(record.shortName or record.name, "Unknown", 22),
        badge = nil,
        texture = nil,
        texCoords = nil,
        iconTint = { 1, 1, 1 },
        iconSize = isFriend and FRIENDLY_ROLE_ICON_SIZE or ENEMY_ICON_SIZE,
        frameShape = isFriend and "SQUARE" or "CIRCLE",
        ringColor = ORB_COLORS.STALE.outer,
        nameColor = { classColor(classFile) },
        -- The Blizzard nameplate retains identity and health information. KWR
        -- adds one compact, non-duplicating tactical token above it.
        showHealth = false,
        showCast = false,
        cast = priorityCast,
    }
    if carrier then
        model.kind = carrier.kind
        model.texture = carrier.texture
        model.iconTint = carrier.tint
        model.ringColor = carrier.colors
        model.badge = carrier.texture and nil or carrier.badge
    elseif isFriend then
        model.kind = "ROLE"
        model.texCoords = roleIconCoords(role)
        model.texture = model.texCoords and ROLE_ICON_TEXTURE or nil
        model.ringColor = ORB_COLORS[role == "DAMAGER" and "DAMAGE" or role]
            and ORB_COLORS[role == "DAMAGER" and "DAMAGE" or role].outer
            or ORB_COLORS.TEAM.outer
        model.badge = nil
    else
        model.kind = "CLASS"
        model.texCoords = type(CLASS_ICON_TCOORDS) == "table"
            and CLASS_ICON_TCOORDS[classFile] or nil
        model.texture = model.texCoords and CLASS_ICON_TEXTURE or nil
        model.ringColor = { classColor(classFile) }
        model.badge = model.texCoords and nil or "?"
    end
    local combat = state and state.snapshot and state.snapshot.combat or {}
    if not isFriend and (sameEntity(record, combat.localTarget)
        or sameEntity(record, combat.killTarget)) then
        model.ringColor = ORB_COLORS.KILL.outer
    elseif priorityCast then
        model.ringColor = ORB_COLORS.STOP.outer
    end
    return model
end

function CursorRing:ApplyIdentifierVisual(frame, model, percent)
    local ring = model.ringColor or ORB_COLORS.STALE.outer
    frame.ring:SetVertexColor(ring[1], ring[2], ring[3], 0.92)
    frame.square:SetVertexColor(ring[1], ring[2], ring[3], 0.96)
    frame.ring:SetShown(model.frameShape ~= "SQUARE")
    frame.square:SetShown(model.frameShape == "SQUARE")
    frame.name:Hide()

    if model.texture then
        frame.icon:SetTexture(model.texture)
        local iconSize = KWR.Util:Clamp(model.iconSize or ENEMY_ICON_SIZE, 16, ENEMY_ICON_SIZE)
        frame.icon:SetSize(iconSize, iconSize)
        if model.texCoords then
            frame.icon:SetTexCoord(unpack(model.texCoords))
        else
            frame.icon:SetTexCoord(0, 1, 0, 1)
        end
        frame.icon:SetVertexColor(model.iconTint[1], model.iconTint[2], model.iconTint[3], 1)
        frame.icon:Show()
    else
        frame.icon:Hide()
    end
    frame.badge:SetText(KWR.Util:Text(model.badge, "", 4))
    frame.badge:SetShown(model.badge ~= nil)

    local showHealth = false
    frame.health:Hide()
    frame.healthText:SetShown(false)

    local cast = nil
    frame.cast:Hide()
    frame.castText:SetShown(false)
    frame:SetSize(ORB_FRAME_WIDTH, ORB_FRAME_HEIGHT)
end

function CursorRing:RefreshOrbForUnit(unit, state)
    local profile = KWR.db.profile.cursor or {}
    local frame = self:CreateOrbFrame(unit)
    local inPvP = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    if profile.battlefieldOrbs == false or not inPvP then
        frame:Hide()
        return false
    end
    if type(UnitExists) ~= "function" then
        frame:Hide()
        return false
    end
    if not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false) then
        frame:Hide()
        return false
    end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit
        and KWR.Util:Call(C_NamePlate.GetNamePlateForUnit, unit) or nil
    if not plate then
        frame:Hide()
        return false
    end
    local isFriend = type(UnitIsFriend) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsFriend, "player", unit), false)
    local record = isFriend and self:FindFriendlyRecord(unit, state)
        or self:FindEnemyRecord(unit, state)
    local mode = self:ResolveMarkerMode()
    self:RefreshTacticalBadgeForUnit(unit, plate, record, isFriend, mode)
    if mode == "OFF" or mode == "TACTICAL_ONLY" then
        frame:Hide()
        return false
    end
    -- The target reticle is the single authoritative target identifier. Keep
    -- the ordinary enemy marker hidden for that unit so the two 28/42px
    -- tokens never stack over the native nameplate.
    if not isFriend and record and sameTargetRecord(record)
        and profile.reticleEnabled ~= false then
        frame:Hide()
        return false
    end
    frame:SetParent(plate)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOM", plate, "TOP", 0, 4)
    if isFriend then
        if not record then
            frame:Hide()
            return false
        end
        self:ApplyIdentifierVisual(frame,
            self:BuildIdentifierModel(record, true, state, false), nil)
    else
        if not record then
            frame:Hide()
            return false
        end
        local currentTarget = sameTargetRecord(record)
        local percent = nil
        if currentTarget then
            local health = KWR.Util:Number(KWR.Util:Call(UnitHealth, unit), nil)
            local maxHealth = KWR.Util:Number(KWR.Util:Call(UnitHealthMax, unit), nil)
            if health and maxHealth and maxHealth > 0 then
                percent = KWR.Util:Clamp((health / maxHealth) * 100, 0, 100)
            end
        end
        self:ApplyIdentifierVisual(frame,
            self:BuildIdentifierModel(record, false, state, currentTarget), percent)
    end

    frame:Show()
    return true
end

function CursorRing:RefreshOrbs()
    local state = currentState(self.lastState)
    local inPvP = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    if not inPvP or KWR.db.profile.cursor.battlefieldOrbs == false then
        self:HideAllOrbs()
        return
    end
    self.orbVisibleCount = 0
    for unit in pairs(self.activePlates or {}) do
        if self:RefreshOrbForUnit(unit, state) then
            self.orbVisibleCount = self.orbVisibleCount + 1
        end
    end
end

function CursorRing:Create()
    if self.driver then return self.driver end
    self:CreateCursorFrame()
    self:CreateReticleFrame()
    self.activePlates = self.activePlates or {}
    local driver = CreateFrame("Frame", "KWR_CursorRingDriver", UIParent)
    driver:Hide()
    for _, event in ipairs({
        "PLAYER_TARGET_CHANGED",
        "NAME_PLATE_UNIT_ADDED",
        "NAME_PLATE_UNIT_REMOVED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVING_WORLD",
        "ZONE_CHANGED_NEW_AREA",
    }) do
        pcall(driver.RegisterEvent, driver, event)
    end
    driver:SetScript("OnEvent", function(_, event, unit)
        CursorRing:OnEvent(event, unit)
    end)
    driver:SetScript("OnUpdate", function(_, elapsed)
        CursorRing:OnUpdate(elapsed)
    end)
    self.driver = driver
    return driver
end

function CursorRing:RefreshDriver()
    if not self.driver then return end
    if KWR.Util:IsArenaContext(currentState(self.lastState)) then
        self.driver:Hide()
        return
    end
    local cursorEnabled = KWR.db.profile.cursor.enabled == true
    local reticleEnabled = KWR.db.profile.cursor.reticleEnabled ~= false
    local state = currentState(self.lastState)
    local inPvP = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    local reticleAllowed = inPvP or isPreviewPvPTrainingDummy(state, "target")
    local hasTarget = reticleAllowed and reticleEnabled and type(UnitExists) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitExists, "target"), false)
    self.driver:SetShown(cursorEnabled
        or self.reticlePending == true
        or (self.reticle and self.reticle:IsShown())
        or hasTarget
        or (self.orbVisibleCount or 0) > 0)
end

function CursorRing:Apply()
    local profile = KWR.db.profile.cursor
    local frame = self:CreateCursorFrame()
    local size = KWR.Util:Clamp(profile.size or 104, 56, 180)
    profile.size = size
    frame:SetSize(size, size)
    frame.inner:SetSize(math.floor(size * 0.18), math.floor(size * 0.18))
    frame:SetAlpha(KWR.Util:Clamp(profile.alpha or 0.95, 0.2, 1))
    self:ApplyMode(self.mode or "NEUTRAL")
    frame:SetShown(profile.enabled == true)
    self:RefreshDriver()
end

function CursorRing:ApplyReticle()
    local profile = KWR.db.profile.cursor
    local frame = self:CreateReticleFrame()
    local size = KWR.Util:Clamp(profile.reticleSize or 104, 56, 156)
    local alpha = KWR.Util:Clamp(profile.reticleAlpha or 0.92, 0.2, 1)
    local visualSize = math.floor(size * 0.84)
    frame:SetSize(visualSize, visualSize)
    frame.hLine:SetSize(1600, 3)
    frame.vLine:SetSize(3, 1200)
    frame.outer:SetSize(visualSize, visualSize)
    frame.inner:SetSize(math.floor(visualSize * 0.58), math.floor(visualSize * 0.58))
    frame.pulse:SetSize(math.floor(visualSize * 0.74), math.floor(visualSize * 0.74))
    frame.labelPlate:SetSize(math.max(78, math.floor(visualSize * 0.92)), 16)
    frame.detailPlate:SetSize(math.max(126, math.floor(visualSize * 1.46)), 14)
    frame.baseAlpha = alpha
    frame.hLine:SetShown(profile.reticleGuides ~= false)
    frame.vLine:SetShown(profile.reticleGuides ~= false)
    self:ApplyReticleState(self.reticleState or {
        mode = "TARGET",
        label = "TARGET",
        detail = "",
        pulse = false,
    })
    self:RefreshDriver()
end

function CursorRing:ApplyMode(mode)
    if not self.frame then return end
    local colors = MODE_COLORS[mode] or MODE_COLORS.NEUTRAL
    self.frame.outer:SetVertexColor(
        colors.outer[1], colors.outer[2], colors.outer[3], 1)
    self.frame.inner:SetVertexColor(
        colors.inner[1], colors.inner[2], colors.inner[3], 0.45)
    self.mode = mode
end

function CursorRing:ApplyReticleState(state)
    local frame = self.reticle
    if not frame then return end
    local profile = KWR.db.profile.cursor or {}
    local colors = RETICLE_COLORS[state.mode] or RETICLE_COLORS.TARGET
    local alpha = KWR.Util:Clamp(profile.reticleAlpha or 0.92, 0.2, 1)
    frame.baseAlpha = alpha
    frame.hLine:SetVertexColor(colors.outer[1], colors.outer[2], colors.outer[3], alpha * 0.34)
    frame.vLine:SetVertexColor(colors.outer[1], colors.outer[2], colors.outer[3], alpha * 0.34)
    frame.outer:SetVertexColor(
        colors.outer[1], colors.outer[2], colors.outer[3],
        math.min(1, math.max(colors.alpha or alpha, alpha * 0.90)))
    frame.inner:SetVertexColor(colors.inner[1], colors.inner[2], colors.inner[3], alpha * 0.68)
    frame.pulse:SetVertexColor(colors.inner[1], colors.inner[2], colors.inner[3], alpha * 0.24)
    local classFile = KWR.Util:Upper(state.classFile, "", 24)
    local texCoords = type(CLASS_ICON_TCOORDS) == "table"
        and CLASS_ICON_TCOORDS[classFile] or nil
    if texCoords then
        frame.targetIcon:SetTexture(CLASS_ICON_TEXTURE)
        frame.targetIcon:SetTexCoord(unpack(texCoords))
        frame.targetIcon:SetVertexColor(1, 1, 1, alpha)
        frame.targetIcon:Show()
    else
        frame.targetIcon:Hide()
    end
    frame.labelPlate:SetBackdropBorderColor(colors.outer[1], colors.outer[2], colors.outer[3], 0.94)
    frame.detailPlate:SetBackdropBorderColor(colors.inner[1], colors.inner[2], colors.inner[3], 0.72)
    frame.label:SetText(KWR.Util:Text(state.label, "TARGET", 24))
    local detail = KWR.Util:Text(state.detail, "", 64)
    frame.detail:SetText(detail)
    frame.detailPlate:SetShown(detail ~= "")
    frame.pulseActive = state.pulse == true
    self.reticleState = state
end

function CursorRing:ResolveReticleState(state)
    local snapshot = state and state.snapshot or {}
    local combat = snapshot.combat or {}
    local mapKey = snapshot.context and snapshot.context.mapKey
    local targetRecord
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if sameTargetRecord(enemy) then
            targetRecord = enemy
            break
        end
    end
    local localTarget = combat.localTarget
    local commandTarget = combat.killTarget
    local localKill = targetRecord and localTarget and localTarget.key == targetRecord.key
    local commandKill = targetRecord and commandTarget and commandTarget.key == targetRecord.key
    local wrongLocal = targetRecord and localTarget and localTarget.key ~= targetRecord.key
    local wrongCommand = targetRecord and commandTarget and commandTarget.key ~= targetRecord.key
    local cast = targetRecord and targetRecord.priorityCast or nil
    local defensive = targetRecord and targetRecord.defensivesActive
        and targetRecord.defensivesActive[1] or nil
    local targetClass = KWR.Util:Upper(targetRecord and targetRecord.classFile, "", 24)

    if defensive then
        return {
            mode = "IMMUNE",
            label = "DEF UP",
            detail = KWR.Util:Text(defensive.name, "DEFENSIVE", 30),
            pulse = true,
            classFile = targetClass,
        }
    end
    if cast then
        return {
            mode = "STOP",
            label = "CAST",
            detail = KWR.Util:Text(cast.name, "FREE CAST", 30),
            pulse = cast.priority == "MUST_STOP",
            classFile = targetClass,
        }
    end
    if targetRecord and targetRecord.carrier then
        return {
            mode = "CARRY",
            label = "CARRY",
            detail = ((targetRecord.carrierStacks or 0) > 0
                and ("Stacks x" .. tostring(targetRecord.carrierStacks))
                or "Objective carrier"),
            pulse = true,
            classFile = targetClass,
        }
    end
    if localKill then
        return {
            mode = "KILL",
            label = "KILL",
            detail = KWR.Util:Text(combat.localTargetReason or combat.killReason,
                "Local kill target", 32),
            pulse = true,
            classFile = targetClass,
        }
    end
    if commandKill then
        return {
            mode = "KILL",
            label = "FOCUS",
            detail = KWR.Util:Text(combat.killReason or combat.localTargetReason,
                "Priority target", 32),
            pulse = true,
            classFile = targetClass,
        }
    end
    if wrongLocal then
        return {
            mode = "SWAP",
            label = "SWAP",
            detail = "Suggested: " .. KWR.Util:Text(
                localTarget and localTarget.shortName, "local target", 20),
            pulse = true,
            classFile = targetClass,
        }
    end
    if wrongCommand then
        return {
            mode = "SWAP",
            label = "PIVOT",
            detail = "Suggested: " .. KWR.Util:Text(
                commandTarget and commandTarget.shortName, "command target", 20),
            pulse = true,
            classFile = targetClass,
        }
    end
    local observed = KWR.Util:Text(targetRecord and targetRecord.spec, "Observed target", 24)
    if targetRecord and targetRecord.location and mapKey then
        observed = observed .. "  "
            .. KWR.Maps:AbbreviateLocation(mapKey, targetRecord.location)
    end
    if targetRecord and targetRecord.locationState and targetRecord.locationState ~= "" then
        observed = KWR.Util:Text(targetRecord.locationState, "OBSERVED", 14) .. "  " .. observed
    end
    if targetRecord and targetRecord.age and targetRecord.visible ~= true then
        observed = observed .. "  " .. KWR.Util:Age(targetRecord.age)
    end
    return {
        mode = "TARGET",
        label = "TARGET",
        detail = KWR.Util:Text(observed, "Observed target", 28),
        pulse = false,
        classFile = targetClass,
    }
end

function CursorRing:RefreshReticle()
    if not self.reticle then return end
    local profile = KWR.db.profile.cursor or {}
    local state = currentState(self.lastState)
    local inPvP = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    local previewDummy = isPreviewPvPTrainingDummy(state, "target")
    if not inPvP and not previewDummy then
        self.reticle:Hide()
        self.reticlePlate = nil
        self.reticlePending = false
        self:RefreshDriver()
        return
    end
    if profile.reticleEnabled == false then
        self.reticle:Hide()
        self.reticlePlate = nil
        self:RefreshDriver()
        return
    end
    local exists = type(UnitExists) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitExists, "target"), false)
    local attackable = type(UnitCanAttack) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitCanAttack, "player", "target"), false)
    local isPlayerTarget = type(UnitIsPlayer) ~= "function"
        or KWR.Util:Boolean(KWR.Util:Call(UnitIsPlayer, "target"), false)
    if not exists or not attackable or (not isPlayerTarget and not previewDummy) then
        self.reticle:Hide()
        self.reticlePlate = nil
        self:RefreshDriver()
        return
    end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit
        and KWR.Util:Call(C_NamePlate.GetNamePlateForUnit, "target") or nil
    if not plate then
        self.reticle:Hide()
        self.reticlePlate = nil
        self.reticlePending = true
        self:RefreshDriver()
        return
    end
    self.reticlePending = false
    self.reticlePlate = plate
    self.reticle:ClearAllPoints()
    -- The centered class icon belongs above the native nameplate, not on top
    -- of Blizzard's target name/health information.
    self.reticle:SetPoint("BOTTOM", plate, "TOP", 0, 6)
    self:ApplyReticleState(self:ResolveReticleState(currentState(self.lastState)))
    self.reticle:SetShown(true)
    self:RefreshDriver()
end

function CursorRing:Update(state)
    self.lastState = state
    if KWR.Util:IsArenaContext(state) then
        if self.frame then self.frame:Hide() end
        if self.reticle then self.reticle:Hide() end
        self:HideAllOrbs()
        self:RefreshDriver()
        return
    end
    self.assignmentIndex = {}
    for _, assignment in ipairs(state.assignments or {}) do
        local full = KWR.Util:Text(assignment.name, "", 64):lower()
        local short = KWR.Util:Text(assignment.shortName, "", 64):lower()
        if full ~= "" then self.assignmentIndex[full] = assignment end
        if short ~= "" then self.assignmentIndex[short] = assignment end
    end
    if KWR.db.profile.cursor.enabled == true then
        local snapshot = state.snapshot or {}
        local combat = snapshot.combat or {}
        local execution = snapshot.strategy
            and snapshot.strategy.executionAssessment or {}
        local collapse = execution.collapse or {}
        local pressure = execution.pressureForecast or {}
        local recovery = execution.recovery or {}
        local action = execution.actionOpportunity or {}
        local mode = "NEUTRAL"
        if combat.priorityCast and combat.priorityCast.priority == "MUST_STOP" then
            mode = "DANGER"
        elseif collapse.state == "CRITICAL" then
            mode = "DANGER"
        elseif combat.priorityCast or pressure.state == "RISING" then
            mode = "CAUTION"
        elseif action.action == "ROTATE" or action.action == "REALLOCATE" then
            mode = "ROTATE"
        elseif recovery.open then
            mode = "RECOVERY"
        elseif execution.active and execution.confidence == "NONE" then
            mode = "UNKNOWN"
        end
        if mode ~= self.mode then self:ApplyMode(mode) end
    end
    self:RefreshReticle()
    self:RefreshOrbs()
    self:RefreshDriver()
end

local function updateToken(_, state)
    local arena = KWR.Util:IsArenaContext(state)
    if KWR.db.profile.cursor.enabled ~= true then
        return KWR.Util:Signature({
            arena,
            false,
            KWR.db.profile.cursor.reticleEnabled,
            KWR.db.profile.cursor.battlefieldOrbs,
            KWR.db.profile.cursor.markerMode,
            KWR.db.profile.cursor.assignmentBadges,
        })
    end
    local snapshot = state and state.snapshot or {}
    local combat = snapshot.combat or {}
    local execution = snapshot.strategy and snapshot.strategy.executionAssessment or {}
    local cast = combat.priorityCast or {}
    local target = combat.localTarget or combat.killTarget or {}
    return KWR.Util:Signature({
        arena,
        true,
        state and state.revision or 0,
        snapshot.context and snapshot.context.sessionKey,
        snapshot.context and snapshot.context.mapKey,
        cast.priority,
        cast.spellID,
        execution.active,
        execution.confidence,
        execution.collapse and execution.collapse.state,
        execution.pressureForecast and execution.pressureForecast.state,
        execution.actionOpportunity and execution.actionOpportunity.action,
        execution.recovery and execution.recovery.open,
        target.key or target.name,
        KWR.db.profile.cursor.markerMode,
        KWR.db.profile.cursor.assignmentBadges,
    })
end

function CursorRing:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + (KWR.Util:Number(elapsed, 0) or 0)
    if self.elapsed < (1 / 30) then return end
    self.elapsed = 0
    if self.frame and self.frame:IsShown() then
        local x, y = KWR.Util:Call(GetCursorPosition)
        x, y = KWR.Util:Number(x, nil), KWR.Util:Number(y, nil)
        if x and y then
            local scale = UIParent:GetEffectiveScale()
            if not scale or scale == 0 then scale = 1 end
            x, y = x / scale, y / scale
            if x ~= self.lastX or y ~= self.lastY then
                self.frame:ClearAllPoints()
                self.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
                self.lastX, self.lastY = x, y
            end
        end
    end
    if self.reticle and self.reticle:IsShown() and self.reticle.pulseActive then
        self.reticlePulse = (self.reticlePulse or 0) + elapsed
        local pulse = 0.18 + (math.sin(self.reticlePulse * 6.2) + 1) * 0.16
        self.reticle.pulse:SetAlpha(pulse)
    elseif self.reticle then
        self.reticlePulse = 0
        self.reticle.pulse:SetAlpha(0.12)
    end
    self.reticleRetry = (self.reticleRetry or 0) + elapsed
    if self.reticleRetry >= 0.20 then
        self.reticleRetry = 0
        if (self.reticlePending or (self.reticle and self.reticle:IsShown()))
            and (KWR.db.profile.cursor.reticleEnabled ~= false) then
            self:RefreshReticle()
        end
    end
    self.orbRetry = (self.orbRetry or 0) + elapsed
    if self.orbRetry >= 0.25 then
        self.orbRetry = 0
        if KWR.db.profile.cursor.battlefieldOrbs ~= false then
            self:RefreshOrbs()
            self:RefreshDriver()
        end
    end
end

function CursorRing:SetEnabled(enabled)
    KWR.db.profile.cursor.enabled = enabled == true
    self:Apply()
    if enabled then self:Update(currentState()) end
end

function CursorRing:SetReticleEnabled(enabled)
    KWR.db.profile.cursor.reticleEnabled = enabled == true
    self:ApplyReticle()
    self:RefreshReticle()
end

function CursorRing:SetReticleGuides(enabled)
    KWR.db.profile.cursor.reticleGuides = enabled == true
    self:ApplyReticle()
    self:RefreshReticle()
end

function CursorRing:SetBattlefieldOrbs(enabled)
    KWR.db.profile.cursor.battlefieldOrbs = enabled == true
    self:RefreshOrbs()
    self:RefreshDriver()
end

function CursorRing:SetAssignmentBadges(enabled)
    KWR.db.profile.cursor.assignmentBadges = enabled == true
    self:RefreshOrbs()
    self:RefreshDriver()
end

function CursorRing:ToggleReticle()
    self:SetReticleEnabled(KWR.db.profile.cursor.reticleEnabled == false)
    KWR:Print("Command reticle "
        .. ((KWR.db.profile.cursor.reticleEnabled ~= false) and "enabled." or "disabled."), true)
end

function CursorRing:Toggle()
    self:SetEnabled(not KWR.db.profile.cursor.enabled)
    KWR:Print("Cursor Ring " .. (KWR.db.profile.cursor.enabled and "enabled." or "disabled."), true)
end

function CursorRing:OnEvent(event, unit)
    if event == "PLAYER_TARGET_CHANGED" or unit == "target" then
        self:RefreshReticle()
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        self.activePlates = self.activePlates or {}
        if event == "NAME_PLATE_UNIT_ADDED" and unit then
            self.activePlates[unit] = true
        elseif event == "NAME_PLATE_UNIT_REMOVED" and unit then
            self.activePlates[unit] = nil
            self:HideOrb(unit)
            self:HideTacticalBadge(unit)
        end
        self:RefreshReticle()
        self:RefreshOrbs()
    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_LEAVING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
        self.activePlates = {}
        self:HideAllOrbs()
        self.reticlePending = true
        self:RefreshReticle()
    end
    self:RefreshDriver()
end

function CursorRing:OnInitialize()
    self:Create()
    if KWR.Store and KWR.Store.SubscribeFiltered then
        KWR.Store:SubscribeFiltered(self, self.Update, updateToken)
    end
    self:Apply()
    self:ApplyReticle()
    self:RefreshReticle()
end

function CursorRing:OnDisable()
    if KWR.Store and KWR.Store.Unsubscribe then
        KWR.Store:Unsubscribe(self)
    end
    self:HideAllOrbs()
    if self.reticle then self.reticle:Hide() end
end

KWR:RegisterModule("CursorRing", CursorRing)
