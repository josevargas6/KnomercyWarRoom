local _, KWR = ...

local CombatRoster = {
    teamRows = {},
    enemyRows = {},
    pending = nil,
    maxRows = 10,
}
KWR.CombatRoster = CombatRoster

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

local function sameUnitOrName(unit, name, comparison)
    if unit and type(UnitIsUnit) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsUnit, unit, comparison), false) then
        return true
    end
    local comparisonName = KWR.Util:UnitName(comparison)
    return comparisonName and KWR.Util:ShortName(comparisonName):lower()
        == KWR.Util:ShortName(KWR.Util:Text(name, "", 64)):lower()
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

local function createSecureRow(parent, name)
    local row = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate,BackdropTemplate")
    row:SetSize(282, 31)
    row:RegisterForClicks("AnyUp")
    KWR.Theme:Style(row, "card", "border")

    row.glow = row:CreateTexture(nil, "BACKGROUND")
    row.glow:SetAllPoints()
    row.glow:SetColorTexture(1, 0.06, 0.02, 0.20)
    row.glow:Hide()

    row.danger = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.danger:SetAllPoints()
    row.danger:SetColorTexture(1, 0.03, 0.02, 0.16)
    row.danger:Hide()

    row.health = CreateFrame("StatusBar", nil, row)
    row.health:SetPoint("TOPLEFT", 2, -2)
    row.health:SetPoint("BOTTOMRIGHT", -2, 2)
    row.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    row.health:SetMinMaxValues(0, 100)
    row.health:SetValue(0)
    row.health:SetAlpha(0.48)

    row.role = row:CreateTexture(nil, "OVERLAY")
    row.role:SetPoint("LEFT", 6, 0)
    row.role:SetSize(19, 19)
    row.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
    row.role:Hide()

    row.nameText = KWR.Theme:Font(row, 10, "white", "LEFT", "OUTLINE")
    row.nameText:SetPoint("TOPLEFT", 30, -3)
    row.nameText:SetWidth(160)
    row.nameText:SetHeight(14)
    row.detailText = KWR.Theme:Font(row, 8, "soft", "LEFT", "OUTLINE")
    row.detailText:SetPoint("BOTTOMLEFT", 30, 3)
    row.detailText:SetWidth(168)
    row.detailText:SetHeight(12)
    row.healthText = KWR.Theme:Font(row, 9, "white", "RIGHT", "OUTLINE")
    row.healthText:SetPoint("TOPRIGHT", -6, -3)
    row.healthText:SetWidth(76)
    row.healthText:SetHeight(14)
    row.stateText = KWR.Theme:Font(row, 8, "soft", "RIGHT", "OUTLINE")
    row.stateText:SetPoint("BOTTOMRIGHT", -6, 3)
    row.stateText:SetWidth(82)
    row.stateText:SetHeight(12)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.displayName or "Unit", self.classR or 1, self.classG or 1, self.classB or 1)
        if self.tooltipDetail then GameTooltip:AddLine(self.tooltipDetail, 0.75, 0.77, 0.82) end
        if self.tooltipHealth then GameTooltip:AddLine(self.tooltipHealth, 1, 1, 1) end
        if self.tooltipState then GameTooltip:AddLine(self.tooltipState, 1, 0.78, 0.25, true) end
        GameTooltip:AddLine("Left-click: target", 1, 1, 1)
        GameTooltip:AddLine("Right-click: focus", 1, 1, 1)
        if self.killReason then GameTooltip:AddLine("KWR: " .. self.killReason, 1, 0.72, 0.2, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:Hide()
    return row
end

function CombatRoster:Create()
    if self.frame then return self.frame end
    local profile = KWR.db.profile.combatRoster
    local frame = CreateFrame("Frame", "KWR_CombatRoster", UIParent, "BackdropTemplate")
    frame:SetSize(528, 288)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()

    frame.title = KWR.Theme:Title(frame, 11)
    frame.title:SetPoint("TOPLEFT", 8, -8)
    frame.title:SetText("KWR COMBAT ROSTER")
    frame.teamHeading = KWR.Theme:Font(frame, 9, "blue", "CENTER", "OUTLINE")
    frame.enemyHeading = KWR.Theme:Font(frame, 9, "red", "CENTER", "OUTLINE")

    local spotlight = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    spotlight:SetPoint("TOPLEFT", 8, -27)
    spotlight:SetPoint("TOPRIGHT", -8, -27)
    spotlight:SetHeight(43)
    KWR.Theme:Style(spotlight, "raised", "borderHi")
    spotlight.health = CreateFrame("StatusBar", nil, spotlight)
    spotlight.health:SetPoint("TOPLEFT", 2, -2)
    spotlight.health:SetPoint("BOTTOMRIGHT", -2, 2)
    spotlight.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    spotlight.health:SetMinMaxValues(0, 100)
    spotlight.health:SetValue(0)
    spotlight.health:SetStatusBarColor(0.26, 0.28, 0.31, 0.62)
    spotlight.nameText = KWR.Theme:Font(spotlight, 13, "white", "LEFT", "OUTLINE")
    spotlight.nameText:SetPoint("TOPLEFT", 10, -4)
    spotlight.nameText:SetWidth(240)
    spotlight.detailText = KWR.Theme:Font(spotlight, 9, "soft", "LEFT", "OUTLINE")
    spotlight.detailText:SetPoint("BOTTOMLEFT", 10, 4)
    spotlight.detailText:SetWidth(300)
    spotlight.healthText = KWR.Theme:Font(spotlight, 12, "white", "RIGHT", "OUTLINE")
    spotlight.healthText:SetPoint("TOPRIGHT", -10, -4)
    spotlight.healthText:SetWidth(110)
    spotlight.actionText = KWR.Theme:Font(spotlight, 10, "gold", "RIGHT", "OUTLINE")
    spotlight.actionText:SetPoint("BOTTOMRIGHT", -10, 4)
    spotlight.actionText:SetWidth(250)
    spotlight.nameText:SetText("NO ENEMY TARGET")
    spotlight.detailText:SetText("Select an enemy to establish local target truth.")
    spotlight.healthText:SetText("--")
    spotlight.actionText:SetText("OBSERVE")
    frame.targetSpotlight = spotlight

    local teamMode = KWR.Theme:Button(frame, "TEAM", 44, 19, function() CombatRoster:Show("TEAM") end)
    teamMode:SetPoint("TOPRIGHT", -224, -4)
    local enemyMode = KWR.Theme:Button(frame, "ENEMY", 50, 19, function() CombatRoster:Show("ENEMY") end)
    enemyMode:SetPoint("LEFT", teamMode, "RIGHT", 3, 0)
    local bothMode = KWR.Theme:Button(frame, "BOTH", 42, 19, function() CombatRoster:Show("BOTH") end)
    bothMode:SetPoint("LEFT", enemyMode, "RIGHT", 3, 0)
    local expand = KWR.Theme:Button(frame, "EXPAND", 55, 19, function() CombatRoster:Expand() end)
    expand:SetPoint("LEFT", bothMode, "RIGHT", 3, 0)
    local close = KWR.Theme:Button(frame, "X", 20, 19, function() CombatRoster:Hide() end)
    close:SetPoint("TOPRIGHT", -4, -4)
    frame.modeButtons = {
        TEAM = teamMode,
        ENEMY = enemyMode,
        BOTH = bothMode,
    }

    for index = 1, self.maxRows do
        self.teamRows[index] = createSecureRow(frame, "KWR_CompactTeamRow" .. index)
        self.enemyRows[index] = createSecureRow(frame, "KWR_CompactEnemyRow" .. index)
    end

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
                    CombatRoster.lastState.snapshot.combat)
            end
        end
    end)

    self.frame = frame
    self:Layout(profile.mode or "BOTH")
    return frame
end

function CombatRoster:DirectHealth(row, unit)
    if not unit or unit == "" or type(UnitExists) ~= "function"
        or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false) then return end
    row.displayUnit = unit
    if type(UnitHealth) == "function" and type(UnitHealthMax) == "function" then
        local ok = pcall(function()
            local health = UnitHealth(unit)
            local maximum = UnitHealthMax(unit)
            row.health:SetMinMaxValues(0, maximum)
            row.health:SetValue(health)
            if type(AbbreviateNumbers) == "function" then
                row.healthText:SetText(AbbreviateNumbers(health))
            else
                row.healthText:SetText("LIVE")
            end
        end)
        if ok then return end
    end
    if type(UnitHealthPercent) == "function" and CurveConstants and CurveConstants.ScaleTo100 then
        pcall(function()
            row.health:SetValue(UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
        end)
    end
end

function CombatRoster:DirectSpotlightHealth(data)
    local spotlight = self.frame and self.frame.targetSpotlight
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
            spotlight.healthText:SetText(type(AbbreviateNumbers) == "function"
                and AbbreviateNumbers(health) or "LIVE")
        end)
    end
end

function CombatRoster:UpdateSpotlight(enemies, combat)
    local spotlight = self.frame and self.frame.targetSpotlight
    if not spotlight
        or KWR.db.profile.combatRoster.combatVisuals == false then return end
    local target
    for _, enemy in ipairs(enemies or {}) do
        if sameUnitOrName(enemy.unit, enemy.name, "target") then
            target = enemy
            break
        end
    end
    local currentTarget = target ~= nil
    if target then
        self.lastSpotlightKey = target.key
    elseif self.lastSpotlightKey then
        for _, enemy in ipairs(enemies or {}) do
            if enemy.key == self.lastSpotlightKey
                and enemy.age and enemy.age <= 5 then
                target = enemy
                break
            end
        end
    end
    if not target then
        self.lastSpotlightKey = nil
        spotlight.nameText:SetText("NO ENEMY TARGET")
        spotlight.nameText:SetTextColor(KWR.Theme:Color("soft"))
        spotlight.detailText:SetText("Select an enemy to establish local target truth.")
        spotlight.actionText:SetText("OBSERVE")
        spotlight.actionText:SetTextColor(KWR.Theme:Color("muted"))
        spotlight.healthText:SetText("--")
        spotlight.health:SetMinMaxValues(0, 100)
        spotlight.health:SetValue(0)
        spotlight.health:SetStatusBarColor(0.26, 0.28, 0.31, 0.62)
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("borderHi"))
        return
    end

    local r, g, b = classColor(target.classFile)
    spotlight.nameText:SetText(target.shortName or target.name or "TARGET")
    spotlight.nameText:SetTextColor(r, g, b, 1)
    spotlight.health:SetStatusBarColor(r, g, b, 0.72)
    local role = KWR.Util:Text(target.role, "NONE", 16)
    local spec = KWR.Util:Text(target.spec, "Unknown spec", 32)
    spotlight.detailText:SetText(role .. " | " .. spec)

    local cast = target.priorityCast
    local defensive = target.defensivesActive
        and target.defensivesActive[1] or nil
    local kill = combat and combat.killTarget
        and combat.killTarget.key == target.key
    if not currentTarget then
        spotlight.actionText:SetText("LAST LOCAL  "
            .. KWR.Util:Age(target.age or 0))
        spotlight.actionText:SetTextColor(KWR.Theme:Color("muted"))
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("borderHi"))
    elseif cast then
        spotlight.actionText:SetText(
            KWR.Util:Text(cast.response, "STOP", 16)
                .. ": " .. KWR.Util:Text(cast.name, "HIGH-VALUE CAST", 36))
        spotlight.actionText:SetTextColor(KWR.Theme:Color(
            cast.priority == "MUST_STOP" and "red" or "orange"))
        spotlight:SetBackdropBorderColor(KWR.Theme:Color(
            cast.priority == "MUST_STOP" and "red" or "orange"))
    elseif defensive then
        spotlight.actionText:SetText(
            KWR.Util:Text(defensive.response, "DEFENSIVE", 20)
                .. ": " .. KWR.Util:Text(defensive.name, "ACTIVE", 36))
        spotlight.actionText:SetTextColor(KWR.Theme:Color("purple"))
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("purple"))
    elseif target.carrier then
        spotlight.actionText:SetText("CARRIER"
            .. ((target.carrierStacks or 0) > 0
                and (" x" .. tostring(target.carrierStacks)) or ""))
        spotlight.actionText:SetTextColor(KWR.Theme:Color("orange"))
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("orange"))
    elseif kill then
        spotlight.actionText:SetText("KILL TARGET")
        spotlight.actionText:SetTextColor(KWR.Theme:Color("red"))
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("red"))
    else
        spotlight.actionText:SetText("CURRENT TARGET")
        spotlight.actionText:SetTextColor(KWR.Theme:Color("gold"))
        spotlight:SetBackdropBorderColor(KWR.Theme:Color("gold"))
    end
    if currentTarget then
        self:DirectSpotlightHealth(target)
    else
        local lastHealth = KWR.Util:Number(target.lastHealthPercent, nil)
        spotlight.health:SetMinMaxValues(0, 100)
        spotlight.health:SetValue(lastHealth or 0)
        spotlight.healthText:SetText(lastHealth
            and ("~" .. tostring(math.floor(lastHealth + 0.5)) .. "%")
            or "--")
        spotlight.health:SetStatusBarColor(0.26, 0.28, 0.31, 0.62)
    end
end

function CombatRoster:UpdateHealthForUnit(unit)
    for _, rows in ipairs({ self.teamRows, self.enemyRows }) do
        for _, row in ipairs(rows) do
            if row.displayUnit == unit then self:DirectHealth(row, unit) end
        end
    end
end

function CombatRoster:ApplyRole(row, role)
    local left, right, top, bottom = roleCoords(role)
    if left then
        row.role:SetTexCoord(left, right, top, bottom)
        row.role:Show()
    else
        row.role:Hide()
    end
end

function CombatRoster:ApplyBinding(row, data, team)
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
        desired.type2 = "focus"
    elseif team == "ENEMY" then
        local targetName = KWR.Util:Text(data.name, "", 64)
        if type(Ambiguate) == "function" then
            local safeName = KWR.Util:Call(Ambiguate, targetName, "none")
            targetName = KWR.Util:Text(safeName, targetName, 64)
        end
        if targetName ~= "" then
            desired.type1 = "macro"
            desired.type2 = "macro"
            desired.macrotext1 = "/cleartarget\n/targetexact " .. targetName
            desired.macrotext2 = "/targetexact " .. targetName .. "\n/focus\n/targetlasttarget"
        end
    end
    for attribute, value in pairs(desired) do
        if row:GetAttribute(attribute) ~= value then row:SetAttribute(attribute, value) end
    end
    return true
end

function CombatRoster:Visual(row, data, team, combat, assignment)
    local targeted = sameUnitOrName(data.unit, data.name, "target")
    local focused = sameUnitOrName(data.unit, data.name, "focus")
    local signature = KWR.Util:Signature({
        data.key, data.name, data.classFile, data.role or data.groupRole,
        data.spec, data.specSource, data.healthPercent, data.lastHealthPercent,
        data.dead, data.connected,
        data.visible, data.localRange, data.age and math.floor(data.age / 2),
        data.locationState, data.location, data.locationSource,
        data.carrier, data.carrierStacks, data.cooldownText, data.trinketState,
        data.priorityCast and data.priorityCast.spellID,
        data.priorityCast and data.priorityCast.priority,
        combat and combat.killTarget and combat.killTarget.key,
        assignment and assignment.role, assignment and assignment.location,
        targeted, focused,
    })
    if row.visualSignature == signature then
        self.renderSkips = (self.renderSkips or 0) + 1
        if data.unit then self:DirectHealth(row, data.unit) end
        return
    end
    self.renderUpdates = (self.renderUpdates or 0) + 1
    row.visualSignature = signature
    row.boundKey = data.key or data.name
    row.boundName = data.name
    row.boundTeam = team
    row.displayName = data.shortName or data.name
    row.displayUnit = data.unit
    row.nameText:SetText(row.displayName)
    local r, g, b = classColor(data.classFile)
    row.classR, row.classG, row.classB = r, g, b
    row.nameText:SetTextColor(r, g, b, 1)
    self:ApplyRole(row, data.role or data.groupRole)

    local percent = KWR.Util:Number(data.healthPercent, nil)
    local lastPercent = KWR.Util:Number(data.lastHealthPercent, nil)
    local displayPercent = percent or lastPercent
    row.health:SetValue(displayPercent or 0)
    local hr, hg, hb = healthColor(percent)
    row.health:SetStatusBarColor(hr, hg, hb, 0.72)
    row.healthText:SetText(percent and (tostring(math.floor(percent + 0.5)) .. "%")
        or (data.unit and "LIVE"
        or (lastPercent and ("~" .. tostring(math.floor(lastPercent + 0.5)) .. "%")
        or "--")))
    row.healthText:SetTextColor(hr, hg, hb, 1)
    row.danger:SetShown(percent ~= nil and percent <= 35 and not data.dead)
    if data.unit then self:DirectHealth(row, data.unit) end
    local role = KWR.Util:Text(data.role or data.groupRole, "NONE", 16)
    local spec = KWR.Util:Text(data.spec, "Unknown spec", 28)
    if data.specSource == "historical" then spec = spec .. " (HIST)" end
    if data.carrier then
        spec = spec .. " | " .. KWR.Util:Text(data.carriedObjective, "CARRIER", 24)
            .. ((data.carrierStacks or 0) > 0 and (" x" .. tostring(data.carrierStacks)) or "")
    end
    row.detailText:SetText(role .. " | " .. spec)
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
        local cast = data.priorityCast
        local trinket = data.trinketState == "ON_COOLDOWN"
        local kill = combat and combat.killTarget and combat.killTarget.key == data.key
        local mapKey = self.lastState and self.lastState.snapshot
            and self.lastState.snapshot.context.mapKey
        local observed = KWR.EnemyIntel:DescribeLocation(
            data, mapKey, true)
        if data.localRange and not data.locationInferred then
            observed = "LOCAL" .. (data.location
                and (" @ " .. KWR.Maps:AbbreviateLocation(
                    mapKey, data.location)) or "")
        end
        local stateText = observed
        if trinket then stateText = "TRINKET USED" end
        if active then stateText = "DEF ACTIVE" end
        if kill then stateText = "KILL" end
        if data.carrier then
            stateText = "CARRIER"
                .. ((data.carrierStacks or 0) > 0
                    and (" x" .. tostring(data.carrierStacks)) or "")
        end
        if defensive and defensive.response then
            stateText = KWR.Util:Text(defensive.response, "DEF", 10)
                .. " " .. KWR.Util:Text(defensive.name, "ACTIVE", 15)
        end
        if cast then
            stateText = KWR.Util:Text(cast.response, "STOP", 10)
                .. " " .. KWR.Util:Text(cast.name, "CAST", 15)
        end
        row.stateText:SetText(stateText)
        row:SetAlpha(data.localRange and 1 or (data.visible and 0.72 or 0.42))
        row.killReason = combat and combat.killTarget and combat.killTarget.key == data.key and combat.killReason or nil
        row.tooltipState = active and ("Active defensive: " .. KWR.Util:Text(data.cooldownText, "Observed", 64))
            or (trinket and "Observed PvP trinket is on cooldown"
            or ("Observation: " .. observed
                .. (data.locationSource and (" via " .. data.locationSource) or "")))
        row.glow:SetShown(kill == true and not defensive)
        local border = targeted and "gold"
            or (focused and "purple" or "border")
        if kill then border = "red" end
        if defensive then border = "purple" end
        if cast then
            border = cast.priority == "MUST_STOP" and "red" or "orange"
        end
        row:SetBackdropBorderColor(KWR.Theme:Color(border))
    else
        local mapKey = self.lastState and self.lastState.snapshot
            and self.lastState.snapshot.context.mapKey
        local assignmentText = assignment
            and KWR.Assignments:CompactLabel(assignment, mapKey) or ""
        row.stateText:SetText(data.carrier and ("CARRIER"
            .. ((data.carrierStacks or 0) > 0 and (" x" .. tostring(data.carrierStacks)) or ""))
            or (data.dead and "DEAD"
            or (data.connected == false and "OFFLINE"
            or (assignmentText ~= "" and assignmentText or "READY"))))
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

function CombatRoster:EnemyOrder(enemies, combat)
    local result = {}
    for _, enemy in ipairs(enemies or {}) do result[#result + 1] = enemy end
    local killKey = combat and combat.killTarget and combat.killTarget.key
    table.sort(result, function(a, b)
        if (a.carrier == true) ~= (b.carrier == true) then return a.carrier == true end
        if (a.key == killKey) ~= (b.key == killKey) then return a.key == killKey end
        if a.visible ~= b.visible then return a.visible == true end
        if a.localRange ~= b.localRange then return a.localRange == true end
        if (a.role == "HEALER") ~= (b.role == "HEALER") then return a.role == "HEALER" end
        return (a.killScore or -999) > (b.killScore or -999)
    end)
    return result
end

function CombatRoster:UpdateRows(rows, data, team, combat, assignments, allowBinding, shown)
    for index, row in ipairs(rows) do
        local entry = data[index]
        if entry then
            if allowBinding then self:ApplyBinding(row, entry, team) end
            self:Visual(row, entry, team, combat, assignments and assignments[entry.name])
            if allowBinding then row:SetShown(shown == true) end
        elseif allowBinding then
            self:ApplyBinding(row, {}, team)
            row.boundKey, row.displayUnit = nil, nil
            row.visualSignature = nil
            row:Hide()
        end
    end
end

function CombatRoster:UpdateBoundRows(rows, data, team, combat, assignments)
    local byKey, byName = {}, {}
    for _, entry in ipairs(data or {}) do
        byKey[entry.key or entry.name] = entry
        byName[KWR.Util:Text(entry.name, "", 64):lower()] = entry
    end
    for _, row in ipairs(rows) do
        local entry = row.boundKey and byKey[row.boundKey]
            or (row.boundName and byName[KWR.Util:Text(row.boundName, "", 64):lower()])
        if entry then self:Visual(row, entry, team, combat, assignments and assignments[entry.name]) end
    end
end

function CombatRoster:Update(state)
    self.lastState = state
    local inPvP = state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    local enteredPvP = inPvP and self.inPvP ~= true
    self.inPvP = inPvP
    if enteredPvP and KWR.db.profile.combatRoster.autoShowInPvP == true then
        KWR.db.profile.combatRoster.shown = true
    end
    if not self.frame then
        if inPvP
            and not (InCombatLockdown and InCombatLockdown()) then
            self:Create()
        else
            return
        end
    end
    if KWR.db.profile.combatRoster.shown
        and not self.frame:IsShown()
        and not (KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown())
        and not (InCombatLockdown and InCombatLockdown()) then
        self.frame:Show()
    end
    local frameShown = self.frame:IsShown()
    local enemies = self:EnemyOrder(state.snapshot.enemies, state.snapshot.combat)
    self:UpdateSpotlight(enemies, state.snapshot.combat)
    local assignments = {}
    for _, assignment in ipairs(state.assignments or {}) do
        assignments[assignment.name] = assignment
    end
    local alive, localEnemies = 0, 0
    for _, player in ipairs(state.snapshot.roster or {}) do
        if not player.dead and player.connected ~= false then alive = alive + 1 end
    end
    for _, enemy in ipairs(enemies) do
        if enemy.localRange and not enemy.dead then localEnemies = localEnemies + 1 end
    end
    self.frame.teamHeading:SetText("TEAM  " .. tostring(alive) .. "/" .. tostring(#(state.snapshot.roster or {})) .. " READY")
    self.frame.enemyHeading:SetText("ENEMY  " .. tostring(localEnemies) .. " LOCAL / " .. tostring(#enemies) .. " KNOWN")
    if InCombatLockdown and InCombatLockdown() then
        self:UpdateBoundRows(self.teamRows, state.snapshot.roster, "TEAM", state.snapshot.combat, assignments)
        self:UpdateBoundRows(self.enemyRows, enemies, "ENEMY", state.snapshot.combat, assignments)
        return
    end
    local mode = KWR.db.profile.combatRoster.mode or "BOTH"
    self:UpdateRows(self.teamRows, state.snapshot.roster or {}, "TEAM", state.snapshot.combat,
        assignments, true, frameShown and mode ~= "ENEMY")
    self:UpdateRows(self.enemyRows, enemies, "ENEMY", state.snapshot.combat,
        assignments, true, frameShown and mode ~= "TEAM")
end

function CombatRoster:Layout(mode)
    if InCombatLockdown and InCombatLockdown() then
        self.pending = { shown = self.frame:IsShown(), mode = mode }
        return
    end
    mode = mode == "TEAM" and "TEAM" or (mode == "ENEMY" and "ENEMY" or "BOTH")
    KWR.db.profile.combatRoster.mode = mode
    for key, button in pairs(self.frame.modeButtons or {}) do
        button.selected = key == mode
        KWR.Theme:Style(button, button.selected and "raised" or "card",
            button.selected and "borderHi" or "border")
        button.label:SetTextColor(KWR.Theme:Color(button.selected and "gold" or "soft"))
    end
    local both = mode == "BOTH"
    local visuals = KWR.db.profile.combatRoster.combatVisuals ~= false
    local visualOffset = visuals and 48 or 0
    self.frame.targetSpotlight:SetShown(visuals)
    self.frame:SetSize(both and 598 or 300, 378 + visualOffset)
    self.frame.teamHeading:ClearAllPoints()
    self.frame.enemyHeading:ClearAllPoints()
    self.frame.teamHeading:SetShown(mode ~= "ENEMY")
    self.frame.enemyHeading:SetShown(mode ~= "TEAM")
    if mode ~= "ENEMY" then
        self.frame.teamHeading:SetPoint("TOPLEFT", 8, -28 - visualOffset)
        self.frame.teamHeading:SetWidth(282)
        self.frame.teamHeading:SetText("TEAM")
    end
    if mode ~= "TEAM" then
        self.frame.enemyHeading:SetPoint("TOPLEFT", both and 308 or 8,
            -28 - visualOffset)
        self.frame.enemyHeading:SetWidth(282)
        self.frame.enemyHeading:SetText("ENEMY")
    end
    for index = 1, self.maxRows do
        local y = -43 - visualOffset - ((index - 1) * 33)
        self.teamRows[index]:ClearAllPoints()
        self.enemyRows[index]:ClearAllPoints()
        self.teamRows[index]:SetPoint("TOPLEFT", 8, y)
        self.enemyRows[index]:SetPoint("TOPLEFT", both and 308 or 8, y)
        if mode == "ENEMY" then self.teamRows[index]:Hide() end
        if mode == "TEAM" then self.enemyRows[index]:Hide() end
    end
    if self.lastState then self:Update(self.lastState) end
end

function CombatRoster:Request(shown, mode)
    self:Create()
    if InCombatLockdown and InCombatLockdown() then
        self.pending = { shown = shown, mode = mode or KWR.db.profile.combatRoster.mode }
        KWR:Print("Combat roster layout change queued until combat ends.", true)
        return false
    end
    if mode then self:Layout(mode) end
    KWR.db.profile.combatRoster.shown = shown == true
    self.frame:SetShown(shown == true)
    if shown then self:Update(KWR.Store:Get()) end
    return true
end

function CombatRoster:Show(mode)
    if KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown() then
        KWR.MainWindow:MinimizeTo("ROSTER", mode)
        return
    end
    self:Request(true, mode)
end

function CombatRoster:Hide()
    self:Request(false)
end

function CombatRoster:Toggle(mode)
    self:Create()
    self:Request(not self.frame:IsShown(), mode)
end

function CombatRoster:Expand()
    local mode = KWR.db.profile.combatRoster.mode
    KWR.MainWindow:Show(mode == "TEAM" and "TEAM" or (mode == "ENEMY" and "ENEMIES" or "TACTICAL"))
end

function CombatRoster:FlushPending()
    if not self.pending then return end
    local pending = self.pending
    self.pending = nil
    self:Request(pending.shown, pending.mode)
end

function CombatRoster:OnInitialize()
    KWR.Store:Subscribe(self, self.Update)
end

function CombatRoster:OnEnable()
    if KWR.db.profile.combatRoster.shown then self:Show(KWR.db.profile.combatRoster.mode) end
end

function CombatRoster:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("CombatRoster", CombatRoster)
