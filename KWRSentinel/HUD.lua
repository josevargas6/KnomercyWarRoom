local _, Sentinel = ...

local HUD = {}
Sentinel.HUD = HUD

local WIN_TONES = {
    WINNING = "recovery",
    LOSING = "active",
    EVEN = "forming",
    SETUP = "border",
}

local TRUST_TONES = {
    ["RAID CMD ONLINE"] = "recovery",
    ["LOCAL KWR"] = "accent",
    ["NO COMMANDER"] = "border",
    STALE = "forming",
    MISMATCH = "active",
}

local MAX_LINE = 64

local function clean(value, fallback)
    value = value ~= nil and tostring(value) or ""
    if value == "" then
        return fallback or ""
    end
    return value
end

local function upper(value, fallback)
    return clean(value, fallback):upper()
end

local function shortName(value)
    value = clean(value, "")
    local dash = value:find("-", 1, true)
    return dash and value:sub(1, dash - 1) or value
end

local function trim(value)
    value = clean(value, "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    value = value:gsub("%s+", " ")
    return value
end

local function stripCommanderPrefix(value)
    value = trim(value)
    value = value:gsub("^ACTION:%s*", "")
    value = value:gsub("^WHO:%s*[^.]+%.%s*", "")
    value = value:gsub("^TRIGGER:%s*[^.]+%.%s*", "")
    value = value:gsub("^SWITCH:%s*[^.]+%.%s*", "")
    value = value:gsub("^CALL READ:%s*", "")
    return trim(value)
end

local function compactLine(value, fallback, maximum)
    value = stripCommanderPrefix(value)
    fallback = fallback or ""
    maximum = maximum or MAX_LINE
    if value == "" then
        value = fallback
    end
    value = value:gsub("Protect the current scoring requirement", "Hold scoring edge")
    value = value:gsub("verify enemy movement", "watch reserve")
    value = value:gsub("then reassess", "then reassess")
    value = value:gsub("If the enemy reserve remains free or the winning anchor calls instability", "Abort on free reserve or anchor instability")
    value = value:gsub("the current scoring requirement", "scoring edge")
    value = value:gsub("current objective edge", "objective edge")
    value = trim(value)
    if #value > maximum then
        local sentence = value:match("^(.-)%.%s")
        if sentence and sentence ~= "" and #sentence <= maximum then
            return sentence .. "."
        end
        return value:sub(1, maximum - 3):gsub("%s+%S*$", "") .. "..."
    end
    return value
end

local function setFontColor(font, tone)
    font:SetTextColor(Sentinel.Theme:Color(tone or "text"))
end

local function setTone(frame, tone)
    if frame.SetTone then
        frame:SetTone(tone)
        return
    end
    Sentinel.Theme:Style(frame, "panel", tone or "border")
end

local function makeLabel(parent, text, x, y, width)
    local label = Sentinel.Theme:Font(parent, 8, "gold", "LEFT", "OUTLINE")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 84)
    label:SetText(text)
    return label
end

local function makeValue(parent, x, y, width, height, size, tone)
    local value = Sentinel.Theme:Font(parent, size or 12, "text", "LEFT", "OUTLINE")
    value:SetPoint("TOPLEFT", x, y)
    value:SetWidth(width or 180)
    value:SetHeight(height or 18)
    value:SetTextColor(Sentinel.Theme:Color(tone or "text"))
    if value.SetWordWrap then
        value:SetWordWrap(true)
    end
    return value
end

local function badge(parent, width, height)
    local frame = Sentinel.Theme:Badge(parent, "muted", "", width or 82, height or 18)
    return frame
end

local function hairline(parent, y)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetColorTexture(Sentinel.Theme:Color("hairline"))
    line:SetPoint("TOPLEFT", 10, y)
    line:SetPoint("TOPRIGHT", -10, y)
    line:SetHeight(1)
    return line
end

local function winBadgeText(winState)
    if winState == "WINNING" then return "LIKELY WIN" end
    if winState == "LOSING" then return "LIKELY LOSS" end
    if winState == "EVEN" then return "TIED" end
    return "SETUP"
end

local function deriveWinState(view)
    local score = view.score or {}
    local status = upper(score.status, "")
    if status == "WINNING" or status == "LOSING" or status == "EVEN" or status == "SETUP" then
        return status
    end
    local friendly = tonumber(score.friendly or 0) or 0
    local enemy = tonumber(score.enemy or 0) or 0
    if friendly > enemy then return "WINNING" end
    if enemy > friendly then return "LOSING" end
    if view.mode == "LIVE" then return "EVEN" end
    return "SETUP"
end

local function scoreHeadline(view)
    local score = view.score or {}
    local mapShort = clean(score.mapShort, "WORLD")
    local friendly = tonumber(score.friendly or 0) or 0
    local enemy = tonumber(score.enemy or 0) or 0
    local winState = deriveWinState(view)
    return string.format("%s %d - %d | %s",
        mapShort,
        friendly,
        enemy,
        winBadgeText(winState))
end

local function scoreSubline(view)
    local score = view.score or {}
    return string.format("%s | %s",
        clean(score.mapName, "World"),
        clean(score.timeToWin, "unknown"))
end

local function trustState(view)
    if view.trustState then
        return upper(view.trustState, "NO COMMANDER")
    end
    if view.source == "KWR" then
        return "LOCAL KWR"
    end
    return "NO COMMANDER"
end

local function movement(view)
    local assignment = view.assignment or {}
    local deathZone = view.deathZone or {}
    local raw = upper(assignment.movement or assignment.move or "", "")
    if raw ~= "" then return raw end
    if deathZone.state == "ACTIVE" then return "RESET" end
    if deathZone.state == "BUILDING" or deathZone.state == "FORMING" then return "COLLAPSE" end
    if assignment.connected == false then return "STAY" end
    return "STAY"
end

local function jobText(view)
    local assignment = view.assignment or {}
    local role = clean(assignment.shortRole, "")
    if role == "" or role == "NONE" then
        role = clean(assignment.role, "UNASSIGNED")
    end
    local location = clean(assignment.location, "")
    if location ~= "" and location ~= "unknown" then
        return upper(role .. " " .. location, "UNASSIGNED")
    end
    return upper(role, "UNASSIGNED")
end

local livePvpContext

local function targetText(view)
    local watch = view.watch or {}
    if not livePvpContext(view) then
        return "NO REVIEWED TARGET"
    end
    if watch.localFallbackTarget == true then
        return "NO REVIEWED TARGET"
    end
    local mode = upper(watch.mode or watch.targetMode or "", "")
    if mode == "" or mode == "UNKNOWN" then
        if watch.castName and watch.castName ~= "" then
            mode = "KICK"
        elseif watch.name and watch.name ~= "No tracked enemy" and watch.name ~= "No local target" then
            mode = "WATCH"
        end
    end
    local name = shortName(watch.name or watch.target or "")
    if mode == "" or name == "" or name == "No tracked enemy" or name == "No local target" then
        return "NO REVIEWED TARGET"
    end
    return mode .. " " .. name
end

local function matchStateText(view, winState)
    local score = view.score or {}
    local condition = clean(score.condition, "")
    if condition ~= "" and condition ~= "Waiting for live battleground data." then
        return compactLine(condition, "", 68)
    end
    if winState == "WINNING" then return "Ahead. Preserve the current objective edge." end
    if winState == "LOSING" then return "Behind. Recover the next objective window." end
    if winState == "EVEN" then return "Even. Follow the next commander move." end
    return "Setup. Waiting for reviewed battleground state."
end

local function holdLine(view, winState)
    local assignment = view.assignment or {}
    local score = view.score or {}
    if view.requirement and view.requirement.holdLine then
        return compactLine(view.requirement.holdLine, "Hold current assignment.", 62)
    end
    if winState == "WINNING" then
        return compactLine(score.action or assignment.detail, "Hold current assignment.", 62)
    end
    return compactLine(assignment.detail, "Do not leave without commander authority.", 62)
end

local function winLine(view, winState)
    local command = view.command or {}
    local score = view.score or {}
    if view.requirement and view.requirement.winLine then
        return compactLine(view.requirement.winLine, "Win the next objective exchange.", 62)
    end
    if winState == "LOSING" or winState == "EVEN" then
        return compactLine(command.action or score.action, "Win the next objective exchange.", 62)
    end
    return compactLine(command.line2 or score.commandWhen, "Keep the lead stable.", 62)
end

local function footerLine(view)
    local healer = view.healer or {}
    local watch = view.watch or {}
    if healer.range == "OUT OF RANGE" then
        return "HEALER OUT OF RANGE"
    end
    if watch.liveCast and watch.liveCast.name then
        return "CAST LIVE " .. clean(watch.liveCast.name, "")
    end
    if view.revision and view.revision > 0 then
        return "CARD LIVE"
    end
    return "LOCAL FALLBACK"
end

function livePvpContext(view)
    if type(IsInInstance) == "function" then
        local _, instanceType = IsInInstance()
        if instanceType == "pvp" then
            return true
        end
        if instanceType and instanceType ~= "" then
            return false
        end
    end
    local score = view.score or {}
    local status = upper(score.status, "")
    local mapKey = upper(view.mapKey or score.mapKey or "", "")
    return mapKey ~= "" and mapKey ~= "WORLD" and status ~= "WORLD" and status ~= "SETUP"
end

local function expectedTarget(view)
    local watch = view.watch or {}
    if not livePvpContext(view) then
        return nil
    end
    if watch.localFallbackTarget == true then
        return nil
    end
    local name = watch.target or watch.name or watch.shortName
    name = shortName(name)
    if name == "" or name == "No tracked enemy" or name == "No local target" then
        return nil
    end
    return name:lower()
end

local function targetState(view)
    local expected = expectedTarget(view)
    if not expected then
        return "MUTED"
    end
    if not UnitExists or not UnitExists("target") or not UnitCanAttack("player", "target") then
        return "RED"
    end
    local actual = shortName(UnitName("target")):lower()
    return actual == expected and "WHITE" or "RED"
end

local function unitMatchesExpected(unit, expected)
    if not unit or expected == nil or not UnitExists or not UnitExists(unit) then
        return false
    end
    if UnitCanAttack and not UnitCanAttack("player", unit) then
        return false
    end
    return shortName(UnitName(unit)):lower() == expected
end

local function nameplateForUnit(unit)
    if not unit or type(C_NamePlate) ~= "table"
        or type(C_NamePlate.GetNamePlateForUnit) ~= "function" then
        return nil
    end
    return C_NamePlate.GetNamePlateForUnit(unit)
end

local function targetCueNameplate(view)
    local expected = expectedTarget(view)
    if not expected then
        return nil
    end
    local watch = view.watch or {}
    if unitMatchesExpected(watch.unit, expected) then
        return nameplateForUnit(watch.unit)
    end
    for _, unit in ipairs({ "target", "focus", "mouseover" }) do
        if unitMatchesExpected(unit, expected) then
            return nameplateForUnit(unit)
        end
    end
    for index = 1, 40 do
        local unit = "nameplate" .. tostring(index)
        if unitMatchesExpected(unit, expected) then
            return nameplateForUnit(unit)
        end
    end
    return nil
end

local TARGET_CUE_COLORS = {
    WHITE = {
        outer = { 0.94, 0.96, 1.00 },
        inner = { 0.82, 0.90, 1.00 },
        alpha = 0.92,
        pulse = 0.18,
    },
    RED = {
        outer = { 1.00, 0.16, 0.12 },
        inner = { 1.00, 0.64, 0.16 },
        alpha = 0.94,
        pulse = 0.34,
    },
    MUTED = {
        outer = { 0.46, 0.52, 0.58 },
        inner = { 0.70, 0.76, 0.82 },
        alpha = 0.44,
        pulse = 0.08,
    },
}

local function readinessSummary()
    if InCombatLockdown and InCombatLockdown() then
        return nil
    end
    local hard = "UNKNOWN"
    local fit = "NOT EVALUABLE"
    local total, equipped
    if type(GetAverageItemLevel) == "function" then
        equipped, total = GetAverageItemLevel()
    end
    if equipped and equipped > 0 then
        hard = "READY"
        if total and total - equipped > 25 then
            hard = "PVP GEAR WARNING"
        end
    end
    if type(C_SpecializationInfo) == "table"
        and type(C_SpecializationInfo.GetAllSelectedPvpTalentIDs) == "function" then
        local talents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
        if type(talents) == "table" and #talents > 0 then
            fit = "MATCHED"
        elseif hard == "READY" then
            hard = "PVP TALENT WARNING"
        end
    end
    return hard, fit
end

function HUD:Create()
    if self.frame then return self.frame end
    local profile = Sentinel.db.profile.hud
    local frame = CreateFrame("Frame", "KWRSentinel_HUD", UIParent, "BackdropTemplate")
    frame:SetSize(388, 276)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    Sentinel.Theme:Style(frame, "background", "borderHi")

    frame.headerBand = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.headerBand:SetPoint("TOPLEFT", 8, -6)
    frame.headerBand:SetPoint("TOPRIGHT", -8, -6)
    frame.headerBand:SetHeight(28)
    Sentinel.Theme:Style(frame.headerBand, "raised", "border")

    frame.brand = frame.headerBand:CreateTexture(nil, "ARTWORK")
    frame.brand:SetPoint("LEFT", 6, 0)
    frame.brand:SetSize(14, 14)
    if type(_G.KWR) == "table" and _G.KWR.Icons and _G.KWR.Icons.ApplyBrand then
        _G.KWR.Icons:ApplyBrand(frame.brand, "mark")
    else
        frame.brand:SetTexture("Interface\\Icons\\Ability_Rogue_TricksOftheTrade")
    end

    frame.title = Sentinel.Theme:Title(frame.headerBand, 12)
    frame.title:SetPoint("LEFT", frame.brand, "RIGHT", 6, 0)
    frame.title:SetText("KWR SENTINEL")

    frame.winBadge = badge(frame, 62, 18)
    frame.winBadge:SetPoint("TOPRIGHT", -118, -10)
    frame.trustBadge = badge(frame, 104, 18)
    frame.trustBadge:SetPoint("TOPRIGHT", -10, -10)

    frame.scoreLine = Sentinel.Theme:Font(frame, 16, "strong", "LEFT", "OUTLINE")
    frame.scoreLine:SetPoint("TOPLEFT", 12, -40)
    frame.scoreLine:SetSize(364, 20)

    frame.header = Sentinel.Theme:Font(frame, 8, "soft", "LEFT", "OUTLINE")
    frame.header:SetPoint("TOPLEFT", 12, -58)
    frame.header:SetSize(364, 12)

    frame.topLine = hairline(frame, -76)
    frame.jobLabel = makeLabel(frame, "MY JOB", 12, -86, 58)
    frame.job = makeValue(frame, 78, -84, 292, 34, 15, "strong")
    frame.job:SetJustifyV("TOP")
    frame.moveLabel = makeLabel(frame, "MOVE", 12, -120, 58)
    frame.move = makeValue(frame, 78, -118, 292, 20, 15, "strong")
    frame.targetLabel = makeLabel(frame, "TARGET", 12, -146, 58)
    frame.target = makeValue(frame, 78, -144, 292, 20, 13, "strong")
    frame.midLine = hairline(frame, -170)
    frame.stateLabel = makeLabel(frame, "MATCH", 12, -182, 58)
    frame.state = makeValue(frame, 78, -180, 292, 22, 10, "text")
    frame.holdLabel = makeLabel(frame, "TO HOLD", 12, -208, 58)
    frame.hold = makeValue(frame, 78, -206, 292, 24, 10, "text")
    frame.winLabel = makeLabel(frame, "TO WIN", 12, -234, 58)
    frame.win = makeValue(frame, 78, -232, 292, 28, 10, "text")
    frame.footer = Sentinel.Theme:Font(frame, 8, "muted", "LEFT", "OUTLINE")
    frame.footer:SetPoint("BOTTOMLEFT", 12, 7)
    frame.footer:SetSize(252, 12)

    frame.map = Sentinel.Theme:Button(frame, "MAP", 42, 20, function() Sentinel.NativeUI:ToggleMap() end)
    frame.map:SetPoint("BOTTOMRIGHT", -96, 4)
    frame.score = Sentinel.Theme:Button(frame, "SCORE", 58, 20, function() Sentinel.NativeUI:ToggleScore() end)
    frame.score:SetPoint("BOTTOMRIGHT", -28, 4)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        if Sentinel.db.profile.hud.locked then return end
        profile.layoutManaged = false
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = selfFrame:GetPoint(1)
        profile.point, profile.relativePoint, profile.x, profile.y = point, relativePoint, x, y
    end)
    self.frame = frame
    return frame
end

function HUD:ResetPosition()
    local defaults = Sentinel.defaults and Sentinel.defaults.profile and Sentinel.defaults.profile.hud
    if not defaults or not Sentinel.db or not Sentinel.db.profile then
        return
    end
    local profile = Sentinel.db.profile.hud
    profile.layoutManaged = true
    profile.point = defaults.point
    profile.relativePoint = defaults.relativePoint
    profile.x = defaults.x
    profile.y = defaults.y
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
        self:Update()
    end
end

function HUD:CreateTargetCue()
    if self.targetCue then return self.targetCue end
    local cue = CreateFrame("Frame", "KWRSentinel_TargetCue", UIParent)
    cue:SetSize(78, 42)
    cue:SetFrameStrata("TOOLTIP")
    cue:SetFrameLevel(9050)
    cue:EnableMouse(false)

    cue.hLine = cue:CreateTexture(nil, "BACKGROUND")
    cue.hLine:SetPoint("CENTER")
    cue.hLine:SetSize(92, 2)
    cue.hLine:SetTexture("Interface\\Buttons\\WHITE8X8")

    cue.vLine = cue:CreateTexture(nil, "BACKGROUND")
    cue.vLine:SetPoint("CENTER")
    cue.vLine:SetSize(2, 54)
    cue.vLine:SetTexture("Interface\\Buttons\\WHITE8X8")

    cue.outer = cue:CreateTexture(nil, "ARTWORK")
    cue.outer:SetPoint("CENTER")
    cue.outer:SetSize(58, 58)
    cue.outer:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    cue.outer:SetBlendMode("ADD")

    cue.inner = cue:CreateTexture(nil, "OVERLAY")
    cue.inner:SetPoint("CENTER")
    cue.inner:SetSize(34, 34)
    cue.inner:SetTexture("Interface\\Cooldown\\star4")
    cue.inner:SetBlendMode("ADD")

    cue.pulse = cue:CreateTexture(nil, "OVERLAY")
    cue.pulse:SetPoint("CENTER")
    cue.pulse:SetSize(46, 46)
    cue.pulse:SetTexture("Interface\\Cooldown\\star4")
    cue.pulse:SetBlendMode("ADD")

    self.targetCue = cue
    return cue
end

function HUD:ShowReadinessAlert()
    if self.readinessShown then
        return
    end
    local hard, fit = readinessSummary()
    if not hard then
        return
    end
    self.readinessShown = true
    local alert = self.readinessAlert
    if not alert then
        alert = CreateFrame("Frame", "KWRSentinel_ReadinessAlert", UIParent, "BackdropTemplate")
        alert:SetSize(260, 54)
        alert:SetPoint("TOP", UIParent, "TOP", 0, -140)
        alert:SetFrameStrata("DIALOG")
        Sentinel.Theme:Style(alert, "background", "forming")
        alert.title = Sentinel.Theme:Font(alert, 10, "accent", "CENTER", "OUTLINE")
        alert.title:SetPoint("TOPLEFT", 8, -8)
        alert.title:SetPoint("TOPRIGHT", -8, -8)
        alert.body = Sentinel.Theme:Font(alert, 9, "text", "CENTER", "OUTLINE")
        alert.body:SetPoint("TOPLEFT", 8, -26)
        alert.body:SetPoint("TOPRIGHT", -8, -26)
        self.readinessAlert = alert
    end
    alert.title:SetText("SENTINEL READINESS")
    alert.body:SetText(hard .. " | " .. fit)
    alert:Show()
    C_Timer.After(8, function()
        if alert then alert:Hide() end
    end)
end

function HUD:UpdateTargetCue(view)
    local cue = self:CreateTargetCue()
    if Sentinel.db.profile.targetCue
        and Sentinel.db.profile.targetCue.enabled == false then
        cue:Hide()
        return
    end
    local state = targetState(view)
    if state == "MUTED" then
        cue:Hide()
        return
    end
    local nameplate = targetCueNameplate(view)
    if not nameplate then
        cue:Hide()
        return
    end
    cue:ClearAllPoints()
    cue:SetPoint("CENTER", nameplate, "CENTER", 0, 0)
    local colors = TARGET_CUE_COLORS[state] or TARGET_CUE_COLORS.MUTED
    cue.hLine:SetVertexColor(colors.outer[1], colors.outer[2], colors.outer[3], colors.alpha * 0.32)
    cue.vLine:SetVertexColor(colors.outer[1], colors.outer[2], colors.outer[3], colors.alpha * 0.32)
    cue.outer:SetVertexColor(colors.outer[1], colors.outer[2], colors.outer[3], colors.alpha)
    cue.inner:SetVertexColor(colors.inner[1], colors.inner[2], colors.inner[3], colors.alpha * 0.68)
    cue.pulse:SetVertexColor(colors.inner[1], colors.inner[2], colors.inner[3], colors.pulse)
    cue:Show()
end

function HUD:Update()
    local hudEnabled = Sentinel.db.profile.hud.enabled == true
    local cueEnabled = Sentinel.db.profile.targetCue
        and Sentinel.db.profile.targetCue.enabled ~= false
    if hudEnabled ~= true and cueEnabled ~= true then
        if self.frame then self.frame:Hide() end
        if self.targetCue then self.targetCue:Hide() end
        if Sentinel.Panels then Sentinel.Panels:Update(nil) end
        return
    end
    if Sentinel:OverlaySuppressed() then
        if self.frame then self.frame:Hide() end
        if self.targetCue then self.targetCue:Hide() end
        if Sentinel.Panels then Sentinel.Panels:Update(nil) end
        return
    end
    local view = Sentinel.Bridge:BuildView() or {}
    local frame = self:Create()
    local winState = deriveWinState(view)
    local trust = trustState(view)
    local score = view.score or {}
        frame.map:SetShown(Sentinel.db.profile.hud.utilityButtons ~= false)
    frame.score:SetShown(Sentinel.db.profile.hud.utilityButtons ~= false)
    if hudEnabled then
        frame.scoreLine:SetText(scoreHeadline(view))
        frame.header:SetText(scoreSubline(view))
        frame.winBadge.text:SetText(winBadgeText(winState))
        frame.trustBadge.text:SetText(trust)
        setTone(frame.winBadge, WIN_TONES[winState] or "border")
        setTone(frame.trustBadge, TRUST_TONES[trust] or "border")
        frame.job:SetText(jobText(view))
        frame.move:SetText(movement(view))
        frame.target:SetText(targetText(view))
        frame.state:SetText(matchStateText(view, winState))
        frame.hold:SetText(holdLine(view, winState))
        frame.win:SetText(winLine(view, winState))
        frame.footer:SetText(footerLine(view))
        setFontColor(frame.move, winState == "LOSING" and "forming" or "strong")
        setFontColor(frame.target, targetState(view) == "RED" and "active" or "strong")
        frame:Show()
    else
        frame:Hide()
    end
    self:UpdateTargetCue(view)
    if Sentinel.Panels then
        Sentinel.Panels:Update(view)
    end
end

function HUD:Toggle()
    local frame = self:Create()
    if frame:IsShown() then
        Sentinel.db.profile.hud.enabled = false
        frame:Hide()
        if self.targetCue then self.targetCue:Hide() end
    else
        Sentinel.db.profile.hud.enabled = true
        self:Update()
    end
    if Sentinel.MinimapButton then
        Sentinel.MinimapButton:Refresh()
    end
end

function HUD:OnInitialize()
    self.frame = self:Create()
    self.frame:Hide()
    self:CreateTargetCue():Hide()
    self.pulse = CreateFrame("Frame", "KWRSentinel_HUDPulse")
    self.pulse.elapsed = 0
    self.pulse:SetScript("OnUpdate", function(_, elapsed)
        HUD.pulse.elapsed = HUD.pulse.elapsed + elapsed
        if HUD.pulse.elapsed >= 0.25 then
            HUD.pulse.elapsed = 0
            HUD:Update()
        end
    end)
end

function HUD:OnEnable()
    if Sentinel.db.profile.hud.enabled then
        self:Update()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(4, function()
            if select(2, IsInInstance()) == "pvp" then
                HUD:ShowReadinessAlert()
            end
        end)
    end
end

Sentinel:RegisterModule("HUD", HUD)
