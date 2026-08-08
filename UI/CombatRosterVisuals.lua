local _, KWR = ...

local CombatRosterVisuals = {}
KWR.CombatRosterVisuals = CombatRosterVisuals

local function trackerText(value, fallback, maxLength)
    return KWR.Util:TextClip(value, fallback, maxLength)
end

local function brightClassColor(r, g, b)
    return math.min(1, (r or 0.7) * 1.22 + 0.04),
        math.min(1, (g or 0.7) * 1.22 + 0.04),
        math.min(1, (b or 0.7) * 1.22 + 0.04)
end

local function emphasizeHealthText(font)
    if not font then return end
    font:SetTextColor(1, 1, 1, 1)
    if font.SetDrawLayer then font:SetDrawLayer("OVERLAY", 7) end
end

local function applyIcon(texture, iconID)
    if not texture then return false end
    if KWR.Icons then
        return KWR.Icons:Apply(texture, iconID, 16)
    end
    texture:SetTexture(nil)
    texture:Hide()
    return false
end

local function enemyActionIcon(action)
    if type(action) ~= "table" then return "observed" end
    local kind = KWR.Util:Upper(action.kind, "NONE", 24)
    if kind == "CAST" then return "control" end
    if kind == "DEFENSIVE" then return "blocked" end
    if kind == "KILL" then return "kill" end
    if kind == "PRESS" then return "push" end
    if kind == "CONTROL" then return "control" end
    if kind == "CARRIER" then return "priority" end
    if kind == "TRINKET" or kind == "COOLDOWN" then return "cooldown" end
    return "observed"
end

local function teamActionIcon(assignment)
    if type(assignment) ~= "table" then return "hold" end
    local shortRole = KWR.Util:Upper(assignment.shortRole, "", 24)
    local movement = KWR.Util:Upper(assignment.movement, "", 24)
    local role = KWR.Util:Upper(assignment.role, "", 48)
    if shortRole == "CONTROL" or assignment.ccActor then return "control" end
    if shortRole == "KILL" then return "kill" end
    if shortRole == "PICKUP" or role:find("FLAG", 1, true) then return "priority" end
    if role:find("PEEL", 1, true) then return "peel" end
    if movement == "MOVE" or movement == "COLLAPSE" then return "rotate" end
    if role:find("DEF", 1, true) or role:find("SIT", 1, true) then return "defend" end
    if role:find("HEAL", 1, true) then return "ready" end
    return "hold"
end

local function sameCallTarget(enemy, call)
    if type(enemy) ~= "table" or type(call) ~= "table" then return false end
    local enemyGUID = KWR.Util:Text(enemy.guid, "", 96)
    local callGUID = KWR.Util:Text(call.targetGUID, "", 96)
    if enemyGUID ~= "" and callGUID ~= "" then
        return enemyGUID == callGUID
    end
    local enemyName = KWR.Util:CanonicalShortName(enemy.name or enemy.shortName)
    local callName = KWR.Util:CanonicalShortName(call.target)
    return enemyName ~= "" and callName ~= "" and enemyName == callName
end

local function shortInitial(value)
    local short = KWR.Util:ShortName(KWR.Util:Text(value, "", 64))
    local initial = string.sub(short, 1, 1)
    return initial ~= "" and string.upper(initial) or "?"
end

local function classLabel(enemy)
    if type(enemy) ~= "table" then return "UNKNOWN" end
    local label = KWR.Util:Text(enemy.class, "", 32)
    if label == "" then
        label = KWR.Util:Text(enemy.classFile, "UNKNOWN", 24)
        label = string.lower(label)
        label = string.upper(string.sub(label, 1, 1)) .. string.sub(label, 2)
    end
    return label
end

local function callEnemy(enemies, call)
    if type(call) ~= "table" then return nil end
    for _, enemy in ipairs(enemies or {}) do
        if sameCallTarget(enemy, call) then return enemy end
    end
    return nil
end

local function countdownText(countdown)
    local values = {}
    for _, tick in ipairs(countdown and countdown.ticks or {}) do
        if tick ~= "GO" then values[#values + 1] = tostring(tick) end
    end
    if #values == 0 then values = { "5", "4", "3", "2", "1" } end
    return "SWITCH IN " .. table.concat(values, " ")
end

local function knownCallTarget(value)
    if type(value) ~= "string" then return false end
    local normalized = string.upper(value:gsub("^%s+", ""):gsub("%s+$", ""))
    return normalized ~= "" and normalized ~= "U"
        and normalized ~= "UNKNOWN" and normalized ~= "UNKNOWN TARGET"
end

local function setFontSize(fontString, size)
    local path, _, flags = fontString:GetFont()
    if path then fontString:SetFont(path, size, flags) end
end

local function applySpotlightTextLayout(spotlight, nameRightInset)
    spotlight.nameText:ClearAllPoints()
    spotlight.nameText:SetPoint("TOPLEFT", 10, -4)
    spotlight.nameText:SetPoint("TOPRIGHT", -(nameRightInset or 10), -4)
    spotlight.nameText:SetHeight(16)
    spotlight.nameText:SetJustifyH("LEFT")
    setFontSize(spotlight.nameText, 13)
    spotlight.detailText:ClearAllPoints()
    spotlight.detailText:SetPoint("TOPLEFT", 10, -27)
    spotlight.detailText:SetPoint("TOPRIGHT", -10, -27)
    spotlight.detailText:SetHeight(16)
    spotlight.detailText:SetJustifyH("LEFT")
    setFontSize(spotlight.detailText, 11)
    spotlight.actionText:ClearAllPoints()
    spotlight.actionText:SetPoint("BOTTOMLEFT", 10, 4)
    spotlight.actionText:SetPoint("BOTTOMRIGHT", -10, 4)
    spotlight.actionText:SetHeight(16)
    spotlight.actionText:SetJustifyH("LEFT")
    setFontSize(spotlight.actionText, 11)
end

local function renderTargetCard(spotlight, target, currentTarget, recentLocal,
    cast, defensive, kill, pressure)
    applySpotlightTextLayout(spotlight, 72)
    spotlight.nameText:SetText("TARGET: "
        .. trackerText(target.shortName or target.name, "UNKNOWN", 20))
    spotlight.nameText:SetTextColor(KWR.Theme:Color("white"))

    local statusText = "STATUS: TRACKED"
    local statusTone = "muted"
    if currentTarget and target.visible == true then
        statusText = "STATUS: TARGETED | LIVE"
        statusTone = "green"
    elseif recentLocal then
        statusText = "STATUS: HERE"
        statusTone = "yellow"
    elseif target.visible == true then
        statusText = "STATUS: LIVE"
        statusTone = "green"
    elseif target.age then
        statusText = "STATUS: LAST " .. KWR.Util:Age(target.age)
    end
    spotlight.detailText:SetText(statusText)
    spotlight.detailText:SetTextColor(KWR.Theme:Color(statusTone))

    local actionText = currentTarget and "ACTION: YOUR TARGET" or "ACTION: WATCH"
    local actionTone = currentTarget and "TARGET" or "STALE"
    if cast then
        actionText = "STOP: " .. trackerText(cast.name, "PRIORITY CAST", 20)
        actionTone = "STOP"
    elseif defensive then
        actionText = "DEFENSIVE: " .. trackerText(defensive.name, "ACTIVE", 18)
        actionTone = "IMMUNE"
    elseif target.carrier then
        actionText = "CARRIER"
            .. ((target.carrierStacks or 0) > 0
                and (" x" .. tostring(target.carrierStacks)) or "")
        actionTone = "CARRY"
    elseif kill then
        actionText = "ACTION: KILL NOW"
        actionTone = "KILL"
    elseif pressure then
        actionText = "ACTION: PRESS NOW"
        actionTone = "STOP"
    end
    spotlight.actionText:SetText(actionText)
    spotlight.actionText:SetTextColor(KWR.Theme:CombatColor(actionTone))
    spotlight.actionText:Show()
    spotlight.statusBadge:Hide()
    spotlight.truthBadge:Hide()
    spotlight.stateIcon:Hide()
    spotlight.health:Show()
    spotlight.healthText:Show()
end

local function renderCallCard(spotlight, enemies, localFight, countdown)
    local controls = localFight and localFight.controls or {}
    local control
    for _, candidate in ipairs(controls) do
        if candidate.assigned == true then
            control = candidate
            break
        end
    end
    control = control or controls[1]
    local kill = localFight and localFight.kill
    if not control and not kill then return false end

    local controlEnemy = callEnemy(enemies, control)
    local killEnemy = callEnemy(enemies, kill)
    local validControl = control and control.assigned == true
        and controlEnemy ~= nil
    local validKill = killEnemy ~= nil
    if not validControl and not validKill then return false end
    local controlName = control and KWR.Util:ShortName(control.actor) or nil
    local controlTarget = controlEnemy
        and (controlEnemy.shortName or controlEnemy.name) or (control and control.target)
    local killTarget = killEnemy
        and (killEnemy.shortName or killEnemy.name) or (kill and kill.target)

    applySpotlightTextLayout(spotlight, 10)
    local ccText = "CC: NONE"
    if validControl and controlName and knownCallTarget(controlTarget) then
        ccText = controlName .. " CC - " .. classLabel(controlEnemy)
            .. " " .. shortInitial(controlTarget)
    end
    spotlight.nameText:SetText(ccText)
    spotlight.nameText:SetTextColor(KWR.Theme:Color("white"))
    local killText = "KILL: NONE"
    if validKill and knownCallTarget(killTarget) then
        killText = "KILL: " .. classLabel(killEnemy) .. " "
            .. shortInitial(killTarget)
    end
    spotlight.detailText:SetText(killText)
    spotlight.detailText:SetTextColor(KWR.Theme:CombatColor("KILL"))
    spotlight.actionText:SetText(countdownText(countdown))
    spotlight.actionText:SetTextColor(KWR.Theme:Color("gold"))
    spotlight.actionText:Show()
    spotlight.statusBadge:Hide()
    spotlight.truthBadge:Hide()
    spotlight.stateIcon:Hide()
    spotlight.health:Hide()
    spotlight.healthText:Hide()
    spotlight.scrim:SetColorTexture(0.01, 0.015, 0.025, 0.92)
    spotlight.scrim:SetShown(true)
    spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor("KILL"))
    return true
end

local function hasCallData(enemies, localFight)
    if not localFight then return false end
    if callEnemy(enemies, localFight.kill) then return true end
    for _, control in ipairs(localFight.controls or {}) do
        if control.assigned == true and callEnemy(enemies, control) then
            return true
        end
    end
    return false
end

local function callCardSignature(localFight, countdown)
    local control = localFight and localFight.controls
        and localFight.controls[1] or nil
    return KWR.Util:Signature({
        "CALL_CARD",
        localFight and localFight.updatedAt or 0,
        localFight and localFight.kill and localFight.kill.target or "",
        localFight and localFight.kill and localFight.kill.targetGUID or "",
        control and control.actor or "",
        control and control.target or "",
        control and control.targetGUID or "",
        table.concat(countdown and countdown.ticks or {}, ","),
    })
end

function CombatRosterVisuals:DirectHealth(owner, row, unit)
    if not unit or unit == "" or type(UnitExists) ~= "function"
        or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false) then return end
    row.displayUnit = unit
    if type(UnitHealth) == "function" and type(UnitHealthMax) == "function" then
        local ok = pcall(function()
            local health = UnitHealth(unit)
            local maximum = UnitHealthMax(unit)
            row.health:SetMinMaxValues(0, maximum)
            row.health:SetValue(health)
            -- Direct native display is legal; arithmetic/string conversion
            -- would be unsafe when Retail returns secret health values.
            row.healthText:SetText("LIVE")
            emphasizeHealthText(row.healthText)
        end)
        if ok then return end
    end
    if type(UnitHealthPercent) == "function" and CurveConstants and CurveConstants.ScaleTo100 then
        pcall(function()
            row.health:SetValue(UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
        end)
    end
end

function CombatRosterVisuals:DirectSpotlightHealth(owner, data)
    local spotlight = owner.enemyFrame and owner.enemyFrame.targetSpotlight
    if not spotlight then return end
    local percent = KWR.Util:Number(data and data.healthPercent, nil)
    spotlight.health:SetMinMaxValues(0, 100)
    spotlight.health:SetValue(percent or 0)
    spotlight.healthText:SetText(percent
        and (tostring(math.floor(percent + 0.5)) .. "%") or "--")
    if type(UnitExists) ~= "function"
        or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, "target"), false) then
        return
    end
    if type(UnitHealth) == "function" and type(UnitHealthMax) == "function" then
        pcall(function()
            local health = UnitHealth("target")
            local maximum = UnitHealthMax("target")
            spotlight.health:SetMinMaxValues(0, maximum)
            spotlight.health:SetValue(health)
            spotlight.healthText:SetText("LIVE")
        end)
    end
end

function CombatRosterVisuals:UpdateSpotlight(owner, enemies, combat, localFight,
    countdown, helpers)
    local spotlight = owner.enemyFrame and owner.enemyFrame.targetSpotlight
    if not spotlight
        or KWR.db.profile.combatRoster.combatVisuals == false then return end
    local target
    for _, enemy in ipairs(enemies or {}) do
        if enemy.dead ~= true and helpers.sameUnitOrName(enemy.unit, enemy.name, "target") then
            target = enemy
            break
        end
    end
    local currentTarget = target ~= nil
    local focusTarget = helpers.activeCombatTarget(combat)
    if target then
        owner.lastSpotlightKey = target.key
    elseif focusTarget and focusTarget.key then
        for _, enemy in ipairs(enemies or {}) do
            if enemy.key == focusTarget.key and enemy.dead ~= true then
                target = enemy
                owner.lastSpotlightKey = enemy.key
                break
            end
        end
    end
    if not target and owner.lastSpotlightKey then
        for _, enemy in ipairs(enemies or {}) do
            if enemy.dead ~= true and enemy.key == owner.lastSpotlightKey
                and enemy.age and enemy.age <= 8
                and helpers.spotlightFallbackRank(enemy) > 0 then
                target = enemy
                break
            end
        end
    end
    if not target then
        local bestRank = 0
        for _, enemy in ipairs(enemies or {}) do
            local rank = helpers.spotlightFallbackRank(enemy)
            if rank > bestRank then
                bestRank = rank
                target = enemy
            end
        end
        if target then owner.lastSpotlightKey = target.key end
    end
    if not target then
        if hasCallData(enemies, localFight) then
            local signature = callCardSignature(localFight, countdown)
            if owner.lastSpotlightSignature == signature then
                owner.spotlightSkips = (owner.spotlightSkips or 0) + 1
                return
            end
            owner.lastSpotlightSignature = signature
            owner.spotlightUpdates = (owner.spotlightUpdates or 0) + 1
            helpers.setSpotlightIdle(spotlight)
            renderCallCard(spotlight, enemies, localFight, countdown)
            return
        end
        owner.lastSpotlightKey = nil
        if owner.lastSpotlightSignature ~= "IDLE" then
            owner.lastSpotlightSignature = "IDLE"
            owner.spotlightUpdates =
                (owner.spotlightUpdates or 0) + 1
            helpers.setSpotlightIdle(spotlight)
        else
            owner.spotlightSkips =
                (owner.spotlightSkips or 0) + 1
        end
        return
    end

    local spotlightSignature = KWR.Util:Signature({
        "SPOTLIGHT",
        callCardSignature(localFight, countdown),
        target.key or "", target.guid or "", target.name or "",
        target.shortName or "", target.classFile or "", target.role or "",
        target.healthPercent or "", target.lastHealthPercent or "",
        target.visible == true and "VISIBLE" or "HIDDEN",
        target.dead == true and "DEAD" or "ALIVE",
        target.age and math.floor(target.age) or "",
        target.localEngaged == true and "ENGAGED" or "",
        target.localRange == true and "LOCAL" or "",
        target.recentLocalEngaged == true and "RECENT_ENGAGED" or "",
        target.recentLocalRange == true and "RECENT_LOCAL" or "",
        target.carrier == true and "CARRIER" or "",
        target.carrierStacks or "",
        target.priorityCast and target.priorityCast.spellID or "",
        target.priorityCast and target.priorityCast.priority or "",
        target.defensivesActive and target.defensivesActive[1]
            and target.defensivesActive[1].spellID or "",
        helpers.activeCombatReason(combat) or "",
        currentTarget,
    })
    if owner.lastSpotlightSignature == spotlightSignature then
        owner.spotlightSkips = (owner.spotlightSkips or 0) + 1
        if target.visible == true then
            owner:DirectSpotlightHealth(target)
        end
        return
    end
    owner.lastSpotlightSignature = spotlightSignature
    owner.spotlightUpdates = (owner.spotlightUpdates or 0) + 1

    spotlight.nameText:ClearAllPoints()
    spotlight.nameText:SetPoint("LEFT", spotlight.stateIcon, "RIGHT", 6, 0)
    spotlight.nameText:SetWidth(170)
    spotlight.nameText:SetHeight(14)
    spotlight.nameText:SetJustifyH("LEFT")
    setFontSize(spotlight.nameText, 12)
    spotlight.detailText:ClearAllPoints()
    spotlight.detailText:SetPoint("LEFT", spotlight.truthBadge, "RIGHT", 8, 0)
    spotlight.detailText:SetPoint("RIGHT", -126, 0)
    spotlight.detailText:SetHeight(14)
    spotlight.detailText:SetJustifyH("LEFT")
    setFontSize(spotlight.detailText, 9)
    spotlight.actionText:ClearAllPoints()
    spotlight.actionText:SetPoint("BOTTOMRIGHT", -10, 3)
    spotlight.actionText:SetWidth(116)
    spotlight.actionText:SetHeight(14)
    spotlight.actionText:SetJustifyH("RIGHT")
    setFontSize(spotlight.actionText, 9)
    local r, g, b = helpers.classColor(target.classFile)
    spotlight.statusBadge:Show()
    spotlight.truthBadge:Show()
    spotlight.actionText:Show()
    spotlight.nameText:SetText(trackerText(target.shortName or target.name, "TARGET", 24))
    spotlight.nameText:SetTextColor(KWR.Theme:Color("white"))
    spotlight.health:SetStatusBarColor(r, g, b, 0.26)
    local cast = target.priorityCast
    local defensive = target.defensivesActive and target.defensivesActive[1] or nil
    local focusReason = helpers.activeCombatReason(combat)
    local reviewed = localFight and sameCallTarget(target, localFight.kill)
        and localFight.kill or nil
    local kill = reviewed and reviewed.mode ~= "PRESSURE"
    local pressure = reviewed and reviewed.mode == "PRESSURE"
    local recentLocal = target.localEngaged == true or target.localRange == true
        or target.recentLocalEngaged == true or target.recentLocalRange == true
    spotlight.actionText:Hide()
    spotlight.health:Show()
    spotlight.healthText:Show()
    spotlight.detailText:SetText(
        currentTarget and "TARGETED NOW" or "WATCHED ENEMY")
    applyIcon(spotlight.stateIcon, currentTarget and "kill" or "enemy")
    if currentTarget and target.visible == true then
        spotlight.truthBadge:SetTone("green")
        spotlight.truthBadge:SetText(kill and "KILL" or (pressure and "PRESS" or "LIVE"))
    elseif recentLocal then
        spotlight.truthBadge:SetTone("yellow")
        spotlight.truthBadge:SetText("HERE")
    elseif target.visible == true then
        spotlight.truthBadge:SetTone("green")
        spotlight.truthBadge:SetText("LIVE")
    else
        spotlight.truthBadge:SetTone(helpers.truthTone(target.age and target.age > 8 and "LAST" or "TRACKED"))
        spotlight.truthBadge:SetText("LAST")
    end
    if not currentTarget and target.visible ~= true then
        applyIcon(spotlight.stateIcon, "observed")
        spotlight.statusBadge:SetTone("muted")
        spotlight.statusBadge:SetText("LAST")
        spotlight.actionText:SetText(KWR.Util:Age(target.age or 0))
        spotlight.actionText:SetTextColor(KWR.Theme:Color("muted"))
        spotlight.actionText:Show()
        spotlight.detailText:SetText("LAST KNOWN ENEMY")
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("borderHi"))
    elseif cast then
        applyIcon(spotlight.stateIcon, "control")
        spotlight.statusBadge:SetTone(cast.priority == "MUST_STOP" and "red" or "orange")
        spotlight.statusBadge:SetText("CAST")
        spotlight.actionText:SetText(trackerText(cast.name, "CAST", 16))
        spotlight.actionText:SetTextColor(KWR.Theme:CombatColor("STOP"))
        spotlight.detailText:SetText(
            trackerText(cast.name, "STOP PRIORITY CAST", 40))
        spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor("STOP"))
    elseif defensive then
        applyIcon(spotlight.stateIcon, "blocked")
        spotlight.statusBadge:SetTone("purple")
        spotlight.statusBadge:SetText("DEF")
        spotlight.actionText:SetText(trackerText(defensive.name, "ACTIVE", 16))
        spotlight.actionText:SetTextColor(KWR.Theme:CombatColor("IMMUNE"))
        spotlight.detailText:SetText(
            trackerText(defensive.name, "DEFENSIVE ACTIVE", 40))
        spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor("IMMUNE"))
    elseif target.carrier then
        applyIcon(spotlight.stateIcon, "priority")
        spotlight.statusBadge:SetTone("orange")
        spotlight.statusBadge:SetText("CARRY")
        spotlight.actionText:SetText("CARRIER"
            .. ((target.carrierStacks or 0) > 0 and (" x" .. tostring(target.carrierStacks)) or ""))
        spotlight.actionText:SetTextColor(KWR.Theme:CombatColor("CARRY"))
        spotlight.detailText:SetText("OBJECTIVE CARRIER")
        spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor("CARRY"))
    elseif kill then
        applyIcon(spotlight.stateIcon, "kill")
        spotlight.statusBadge:SetTone("red")
        spotlight.statusBadge:SetText("FOCUS")
        spotlight.actionText:SetText("KILL WINDOW")
        spotlight.actionText:SetTextColor(KWR.Theme:CombatColor("KILL"))
        spotlight.detailText:SetText(
            trackerText(focusReason, "REVIEWED KILL WINDOW", 48))
        spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor("KILL"))
    elseif pressure then
        applyIcon(spotlight.stateIcon, "push")
        spotlight.statusBadge:SetTone("orange")
        spotlight.statusBadge:SetText("PRESS")
        spotlight.actionText:SetText("PRESS NOW")
        spotlight.actionText:SetTextColor(KWR.Theme:CombatColor("STOP"))
        spotlight.detailText:SetText(
            trackerText(focusReason, "REVIEWED PRESSURE", 48))
        spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor("STOP"))
    else
        applyIcon(spotlight.stateIcon, currentTarget and "kill" or "observed")
        spotlight.statusBadge:SetTone(currentTarget and "gold" or "muted")
        spotlight.statusBadge:SetText(currentTarget and "TARGET" or "LIVE")
        spotlight.actionText:SetText(currentTarget and "YOUR TARGET" or "WATCH")
        spotlight.actionText:SetTextColor(KWR.Theme:CombatColor(
            currentTarget and "TARGET" or "STALE"))
        spotlight:SetBackdropBorderColor(KWR.Theme:CombatColor(
            currentTarget and "TARGET" or "STALE"))
    end
    spotlight.scrim:SetShown(not currentTarget)
    if kill then
        spotlight.scrim:SetColorTexture(0.04, 0.01, 0.01, 0.28)
    elseif pressure or cast then
        spotlight.scrim:SetColorTexture(0.05, 0.03, 0.01, 0.26)
    elseif defensive then
        spotlight.scrim:SetColorTexture(0.04, 0.02, 0.06, 0.28)
    elseif target.carrier then
        spotlight.scrim:SetColorTexture(0.06, 0.04, 0.01, 0.24)
    else
        spotlight.scrim:SetColorTexture(0.02, 0.03, 0.05, 0.46)
    end
    if target.visible == true then
        owner:DirectSpotlightHealth(target)
    else
        local lastHealth = KWR.Util:Number(target.lastHealthPercent, nil)
        spotlight.health:SetMinMaxValues(0, 100)
        spotlight.health:SetValue(lastHealth or 0)
        spotlight.healthText:SetText(lastHealth
            and ("~" .. tostring(math.floor(lastHealth + 0.5)) .. "%")
            or "--")
        spotlight.health:SetStatusBarColor(0.26, 0.28, 0.31, 0.24)
    end
    renderTargetCard(spotlight, target, currentTarget, recentLocal,
        cast, defensive, kill, pressure)
    renderCallCard(spotlight, enemies, localFight, countdown)
end

function CombatRosterVisuals:ApplyRole(owner, row, role, helpers)
    row.role:Hide()
    if row.roleBadge then
        local tone, text = helpers.roleBadgeStyle(role)
        if role then
            KWR.Theme:Style(row.roleBadge, "background", tone == "gold" and "borderHi" or tone)
            local applied = row.roleBadge.icon and KWR.Icons
                and KWR.Icons:Apply(row.roleBadge.icon, KWR.Icons.roleMap[KWR.Util:Upper(role, "", 16)], 16)
            row.roleBadge.text:SetText(text)
            row.roleBadge.text:SetTextColor(KWR.Theme:Color(tone == "gold" and "gold" or tone))
            row.roleBadge.text:SetShown(not applied)
            if row.roleBadge.icon then
                row.roleBadge.icon:SetShown(applied == true)
            end
            row.roleBadge:Show()
        else
            if row.roleBadge.icon then row.roleBadge.icon:Hide() end
            row.roleBadge:Hide()
        end
    end
    local left, right, top, bottom = helpers.roleCoords(role)
    if left then
        row.role:SetTexCoord(left, right, top, bottom)
        if row.roleBadge and row.roleBadge:IsShown() then
            row.role:Hide()
        end
    else
        row.role:Hide()
    end
end

function CombatRosterVisuals:ApplyBinding(owner, row, data, team)
    if InCombatLockdown and InCombatLockdown() then return false end
    local desired = {
        unit = false,
        type1 = false,
        type2 = false,
        macrotext1 = false,
        macrotext2 = false,
    }
    if team == "TEAM" and data.unit then
        desired.unit = data.unit
        desired.type1 = "target"
        desired.type2 = "macro"
        desired.macrotext2 = "/focus [mod:shift,@" .. data.unit .. "]"
    elseif team == "ENEMY" then
        local targetName = KWR.Util:Text(data.name or data.shortName, "", 64)
        if type(Ambiguate) == "function" then
            local safeName = KWR.Util:Call(Ambiguate, targetName, "none")
            targetName = KWR.Util:Text(safeName, targetName, 64)
        end
        if targetName ~= "" then
            desired.type1 = "macro"
            desired.type2 = "macro"
            desired.macrotext1 = "/cleartarget\n/targetexact " .. targetName
            desired.macrotext2 = "/targetexact " .. targetName
                .. " [mod:shift]\n/focus [mod:shift]\n/targetlasttarget [mod:shift]"
        end
    end
    for attribute, value in pairs(desired) do
        if row:GetAttribute(attribute) ~= value then row:SetAttribute(attribute, value) end
    end
    return true
end

function CombatRosterVisuals:Visual(owner, row, data, team, combat, assignment, helpers)
    local displayIdentity = data.name or data.shortName
    local targeted = helpers.sameUnitOrName(data.unit, displayIdentity, "target")
    local focused = helpers.sameUnitOrName(data.unit, displayIdentity, "focus")
    local focusTarget = helpers.activeCombatTarget(combat)
    local focusReason = helpers.activeCombatReason(combat)
    local assignmentSignature = KWR.Util:Signature({
        KWR.Util:Text(assignment and assignment.role, "", 32),
        KWR.Util:Text(assignment and assignment.location, "", 32),
        KWR.Util:Text(assignment and assignment.shortRole, "", 32),
        KWR.Util:Text(assignment and assignment.movement, "", 32),
        KWR.Util:Text(assignment and assignment.target, "", 64),
        KWR.Util:Text(assignment and assignment.display, "", 64),
        KWR.Util:Text(assignment and assignment.fightMode, "", 16),
        KWR.Util:Text(assignment and assignment.ccActor, "", 64),
    })
    local signature = KWR.Util:Signature({
        assignmentSignature,
        data.key, data.name, data.shortName, data.classFile, data.role or data.groupRole,
        data.spec, data.specSource, data.healthPercent, data.lastHealthPercent,
        data.dead, data.connected,
        data.visible, data.localRange, data.age and math.floor(data.age / 2),
        data.locationState, data.location, data.locationSource,
        data.locationInferred, data.engagementRole,
        data.carrier, data.carrierStacks, data.cooldownText, data.trinketState,
        data.priorityCast and data.priorityCast.spellID,
        data.priorityCast and data.priorityCast.name,
        data.priorityCast and data.priorityCast.response,
        data.priorityCast and data.priorityCast.priority,
        data.defensivesActive and data.defensivesActive[1]
            and data.defensivesActive[1].spellID,
        data.defensivesActive and data.defensivesActive[1]
            and data.defensivesActive[1].name,
        data.defensivesActive and data.defensivesActive[1]
            and data.defensivesActive[1].response,
        focusTarget and focusTarget.key, focusReason,
        targeted, focused,
    })
    if row.visualSignature == signature then
        owner.renderSkips = (owner.renderSkips or 0) + 1
        if data.unit then owner:DirectHealth(row, data.unit) end
        return
    end
    owner.renderUpdates = (owner.renderUpdates or 0) + 1
    row.visualSignature = signature
    row.reset = false
    row.boundKey = data.key or data.name or data.shortName
    row.boundName = data.name or data.shortName
    row.boundTeam = team
    row.displayName = trackerText(data.shortName or data.name, "Unknown", 20)
    row.displayUnit = data.unit
    row.nameText:SetText(row.displayName)
    local r, g, b = brightClassColor(helpers.classColor(data.classFile))
    row.classR, row.classG, row.classB = r, g, b
    row.nameText:SetTextColor(r, g, b, 1)
    row.detailText:SetTextColor(KWR.Theme:Color("soft"))
    owner:ApplyRole(row, data.role or data.groupRole)

    local percent = KWR.Util:Number(data.healthPercent, nil)
    local lastPercent = KWR.Util:Number(data.lastHealthPercent, nil)
    local displayPercent = percent or lastPercent
    row.health:SetValue(displayPercent or 0)
    local hr, hg, hb = helpers.healthColor(percent)
    row.health:SetStatusBarColor(hr, hg, hb, 0.72)
    row.healthText:SetText(percent and (tostring(math.floor(percent + 0.5)) .. "%")
        or (data.unit and "LIVE"
        or (lastPercent and ("~" .. tostring(math.floor(lastPercent + 0.5)) .. "%")
        or "--")))
    emphasizeHealthText(row.healthText)
    row.danger:SetShown(percent ~= nil and percent <= 35 and not data.dead)
    if data.unit then owner:DirectHealth(row, data.unit) end
    local role = KWR.Util:Text(data.role or data.groupRole, "NONE", 16)
    local spec = KWR.RosterPresentation:SpecLabel(data)
    if data.carrier then
        spec = spec .. " | " .. KWR.Util:Text(data.carriedObjective, "CARRIER", 24)
            .. ((data.carrierStacks or 0) > 0 and (" x" .. tostring(data.carrierStacks)) or "")
    end
    row.tooltipDetail = role .. " | " .. spec
    row.tooltipHealth = percent and ("Observed health: "
        .. tostring(math.floor(percent + 0.5)) .. "%")
        or (lastPercent and ("Last safely observed health: "
            .. tostring(math.floor(lastPercent + 0.5)) .. "%")
        or "Health percentage unavailable")
    row.tooltipState = nil

    if team == "ENEMY" then
        local active = data.defensivesActive and #data.defensivesActive > 0
        local defensive = active and data.defensivesActive[1] or nil
        local trinket = data.trinketState == "ON_COOLDOWN"
        local fightMode = assignment and assignment.fightMode
        local kill = fightMode == "KILL"
        local pressure = fightMode == "PRESS"
        local mapKey = owner.lastState and owner.lastState.snapshot
            and owner.lastState.snapshot.context.mapKey
        local observed = KWR.EnemyIntel:DescribeLocation(data, mapKey, true)
        local action = KWR.RosterPresentation:EnemyAction(
            data, assignment, mapKey, true)
        applyIcon(row.detailIcon, enemyActionIcon(action))
        row.detailText:SetText(trackerText(action.text, "--", 28))
        if action.combatTone then
            row.detailText:SetTextColor(
                KWR.Theme:CombatColor(action.combatTone))
        else
            row.detailText:SetTextColor(
                KWR.Theme:Color(action.tone))
        end
        row:SetAlpha(data.localRange and 1 or (data.visible and 0.72 or 0.42))
        row.killReason = (kill or pressure) and focusReason or nil
        row.tooltipState = active and ("Active defensive: " .. KWR.Util:Text(data.cooldownText, "Observed", 64))
            or (trinket and "Observed PvP trinket is on cooldown"
            or ("Observation: " .. observed
                .. (data.locationSource and (" via " .. data.locationSource) or "")))
        row.glow:SetShown((kill or pressure) and not defensive)
        local border = targeted and "gold"
            or (focused and "purple" or "border")
        if not targeted and not focused then
            border = action.border
        end
        if KWR.Theme.combatColors[border] then
            row:SetBackdropBorderColor(KWR.Theme:CombatColor(border))
        else
            row:SetBackdropBorderColor(KWR.Theme:Color(border))
        end
    else
        local mapKey = owner.lastState and owner.lastState.snapshot
            and owner.lastState.snapshot.context.mapKey
        local assignmentText = assignment and KWR.Util:Text(
            assignment.display, "", 64) or ""
        if assignmentText == "" and assignment then
            assignmentText = KWR.Assignments:CompactLabel(assignment, mapKey)
        end
        applyIcon(row.detailIcon, teamActionIcon(assignment))
        row.detailText:SetText(
            trackerText(assignmentText ~= "" and assignmentText or "HOLD", "HOLD", 28))
        local assignmentTone = assignment and assignment.shortRole == "CONTROL" and "STOP"
            or (assignment and assignment.shortRole == "KILL" and "KILL"
            or (assignment and assignment.shortRole == "PICKUP" and "CARRY"
            or (assignment and assignment.movement == "MOVE" and "MOVE"
            or (assignment and assignment.movement == "COLLAPSE" and "MOVE"
            or "TARGET"))))
        row.detailText:SetTextColor(KWR.Theme:CombatColor(assignmentTone))
        row.tooltipState = assignment and ("Assignment: "
            .. KWR.Assignments:CompactLabel(assignment, mapKey))
            or (data.dead and "Player is dead" or (data.connected == false and "Player is offline" or "Ready"))
        if data.location then
            row.tooltipState = row.tooltipState .. "\nObserved: " .. data.location
        end
        row:SetAlpha(data.connected == false and 0.4 or 1)
        row.killReason = nil
        row.glow:Hide()
        row:SetBackdropBorderColor(KWR.Theme:Color(targeted and "gold" or (focused and "purple" or "border")))
    end
end

function CombatRosterVisuals:UpdateRows(owner, rows, data, team, combat, assignments, allowBinding, shown)
    for index, row in ipairs(rows) do
        local entry = data[index]
        if entry then
            if allowBinding then owner:ApplyBinding(row, entry, team) end
            owner:Visual(row, entry, team, combat, assignments and assignments[entry.name])
            if allowBinding and row:IsShown() ~= (shown == true) then
                row:SetShown(shown == true)
            end
        elseif allowBinding then
            owner:ApplyBinding(row, {}, team)
            if row.reset ~= true or row:IsShown() then
                owner:ResetRow(row, true)
            else
                owner.renderSkips = (owner.renderSkips or 0) + 1
            end
        end
    end
end

function CombatRosterVisuals:UpdateBoundRows(owner, rows, data, team, combat, assignments)
    local byUnit, byKey, byName = {}, {}, {}
    local shortCounts = {}
    for index = 1, owner.maxRows do
        local entry = data and data[index]
        if entry then
            if entry.unit then byUnit[entry.unit] = entry end
            local key = entry.key or entry.name or entry.shortName
            if key then byKey[key] = entry end
            local name = KWR.Util:CanonicalName(
                entry.name or entry.shortName)
            if name ~= "" then byName[name] = entry end
            local shortName = KWR.Util:CanonicalShortName(
                entry.shortName or entry.name)
            if shortName ~= "" then
                shortCounts[shortName] = (shortCounts[shortName] or 0) + 1
            end
        end
    end
    local used = {}
    for _, row in ipairs(rows) do
        -- Secure unit attributes cannot be changed in combat, but raidN/partyN
        -- can acquire a new occupant. Keep visuals aligned with what clicks target.
        local boundUnit = row:GetAttribute("unit") or row.displayUnit
        local entry
        if boundUnit then
            entry = byUnit[boundUnit]
            -- For friendly secure rows, a bound raid/party token is the source
            -- of truth. If the new occupant has not stabilized yet, avoid
            -- repainting the old player into the slot.
            if not entry and team ~= "TEAM" then
                entry = (row.boundKey and byKey[row.boundKey])
                    or (row.boundName and byName[KWR.Util:CanonicalName(row.boundName)])
            end
        else
            entry = (row.boundKey and byKey[row.boundKey])
                or (row.boundName and byName[KWR.Util:CanonicalName(row.boundName)])
        end
        if entry then
            local aliases = {}
            local guid = KWR.Util:Text(entry.guid, "", 96)
            local key = KWR.Util:Text(entry.key, "", 96)
            local name = KWR.Util:CanonicalName(entry.name or entry.shortName)
            if guid ~= "" then aliases[#aliases + 1] = "GUID:" .. guid end
            if key ~= "" then aliases[#aliases + 1] = "KEY:" .. key end
            if name ~= "" then aliases[#aliases + 1] = "NAME:" .. name end
            local shortName = KWR.Util:CanonicalShortName(
                entry.shortName or entry.name)
            if team == "TEAM" and shortName ~= ""
                and shortCounts[shortName] == 1 then
                aliases[#aliases + 1] = "SHORT:" .. shortName
            end
            local duplicate = false
            for _, alias in ipairs(aliases) do
                if used[alias] then duplicate = true break end
            end
            if duplicate then
                entry = nil
            else
                for _, alias in ipairs(aliases) do used[alias] = true end
            end
        end
        if entry then
            owner:Visual(row, entry, team, combat, assignments and assignments[entry.name])
        elseif row:IsShown()
            and row.visualSignature ~= "WAITING_FOR_SECURE_REFRESH" then
            row.visualSignature = "WAITING_FOR_SECURE_REFRESH"
            row.displayUnit = nil
            row.displayName = nil
            row.health:SetMinMaxValues(0, 100)
            row.health:SetValue(0)
            row.health:SetStatusBarColor(0.22, 0.24, 0.27, 0.45)
            row.healthText:SetText("--")
            row.healthText:SetTextColor(KWR.Theme:Color("muted"))
            row.nameText:SetText("")
            row.detailText:SetText("ROSTER SETTLING")
            row.glow:Hide()
            row.danger:Hide()
            row:SetAlpha(0.32)
            owner.rebindPending = true
            owner.renderUpdates = (owner.renderUpdates or 0) + 1
        elseif row:IsShown() then
            owner.renderSkips = (owner.renderSkips or 0) + 1
        end
    end
end
