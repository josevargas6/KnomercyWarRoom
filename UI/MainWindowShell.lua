local _, KWR = ...

local MainWindowShell = {}
KWR.MainWindowShell = MainWindowShell

function MainWindowShell:UpdateHeader(frame, state, helpers)
    local context = state.snapshot.context
    local commandTone, commandTag = helpers.commandBadgeState(state)
    local objectiveSource = state.snapshot.objectives and state.snapshot.objectives.source or "none"
    local reporter = state.snapshot.reporter or {}
    local reporterTrust = reporter.trust or {}
    local reporterCoverage = reporter.coverage or {}
    local doctrineClass = state.doctrineClass
        or (state.snapshot.strategy and state.snapshot.strategy.state) or "LIVE"

    frame.commandBadge:SetTone(commandTone)
    frame.commandBadge:SetText(commandTag)
    if frame.commandBadge.icon and KWR.Icons then
        KWR.Icons:Apply(frame.commandBadge.icon, "commander", 16)
    end
    frame.truthBadge:SetTone(context.preview and "orange"
        or (helpers.truthLabel(objectiveSource) == "LIVE UI" and "green"
            or (helpers.truthLabel(objectiveSource) == "OBSERVED" and "yellow" or "muted")))
    frame.truthBadge:SetText(context.preview and "PREVIEW" or helpers.truthLabel(objectiveSource))
    if frame.truthBadge.icon and KWR.Icons then
        KWR.Icons:Apply(frame.truthBadge.icon,
            context.preview and "not_live"
                or (helpers.truthLabel(objectiveSource) == "LIVE UI" and "ready"
                or (helpers.truthLabel(objectiveSource) == "OBSERVED" and "observed" or "disabled")),
            16)
    end
    frame.reporterBadge:SetTone(context.preview and "orange"
        or (reporterTrust.label == "HIGH" and "green"
            or (reporterTrust.label == "MEDIUM" and "yellow"
            or (reporterTrust.label == "LOW" and "orange" or "muted"))))
    frame.reporterBadge:SetText(string.format("SEEN %d/%d",
        reporterCoverage.enemyVisible or 0,
        (reporterCoverage.enemyVisible or 0) + (reporterCoverage.enemyRecent or 0)))
    if frame.reporterBadge.icon and KWR.Icons then
        KWR.Icons:Apply(frame.reporterBadge.icon,
            (reporterCoverage.enemyVisible or 0) > 0 and "observed" or "disabled",
            16)
    end
    frame.doctrineBadge:SetTone(context.preview and "orange"
        or (doctrineClass == "RECOVERY" and "green"
            or (doctrineClass == "ENDGAME" and "red"
            or (doctrineClass == "OPENING" and "blue" or "gold"))))
    frame.doctrineBadge:SetText(KWR.Util:Text(doctrineClass, "LIVE", 10))
    if frame.doctrineBadge.icon and KWR.Icons then
        local doctrineIcon = "assignment"
        if doctrineClass == "RECOVERY" then
            doctrineIcon = "hold"
        elseif doctrineClass == "ENDGAME" then
            doctrineIcon = "priority"
        elseif doctrineClass == "OPENING" then
            doctrineIcon = "rotate"
        end
        KWR.Icons:Apply(frame.doctrineBadge.icon, doctrineIcon, 16)
    end
    frame.tagline:SetText(KWR.CommandView:TaglineText(state, "Hold current lane.", 140))
    frame.tagline:SetTextColor(KWR.Theme:Color(context.preview and "orange"
        or (context.inPvP and "gold" or "muted")))
    frame.context:SetText((context.preview and "DESIGN PREVIEW - NOT LIVE"
        or (context.inPvP and "LIVE BATTLEGROUND" or "RBG SETUP"))
        .. "  |  " .. context.mapName
        .. (context.inPvP and ("  |  " .. (context.isBlitz and "BLITZ" or "STANDARD")
            .. "  |  " .. tostring(context.team and context.team.faction or "TEAM PENDING")) or "")
        .. "  |  REV " .. tostring(state.revision or 0))
    frame.context:SetTextColor(KWR.Theme:Color(context.preview and "orange"
        or (context.inPvP and "green" or "muted")))
    if context.inPvP then
        frame.score:SetText(string.format("|cff4f8cff%d|r  -  |cffff3333%d|r",
            state.snapshot.score.friendly or 0, state.snapshot.score.enemy or 0))
    elseif context.preview then
        frame.score:SetText("PREVIEW")
    else
        frame.score:SetText("NO SCORE")
    end
end

function MainWindowShell:SuppressCompactSurfaces(owner)
    if owner.compactRestore then return end
    owner.compactRestore = {
        roster = KWR.CombatRoster and KWR.CombatRoster:AnyShown() or false,
        teamShown = KWR.CombatRoster and KWR.CombatRoster:IsShown("TEAM") or false,
        enemyShown = KWR.CombatRoster and KWR.CombatRoster:IsShown("ENEMY") or false,
    }
    if KWR.HUD and KWR.HUD.SetSuppressed then
        KWR.HUD:SetSuppressed(true)
    end
    if owner.compactRestore.roster and KWR.CombatRoster then
        KWR.CombatRoster:Request(false, nil, false)
    end
    if GameTooltip then GameTooltip:Hide() end
end

function MainWindowShell:RestoreCompactSurfaces(owner, state)
    local restore = owner.compactRestore
    if not restore then return end
    owner.compactRestore = nil
    if KWR.HUD and KWR.HUD.SetSuppressed then
        KWR.HUD:SetSuppressed(false)
    end
    if not KWR.Util:AllowsCommandSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        return
    end
    local minimizingTo = owner.minimizingTo
    owner.minimizingTo = nil
    if minimizingTo then
        return
    end
    if restore.roster and KWR.CombatRoster then
        KWR.CombatRoster:RequestVisibility(
            restore.teamShown == true,
            restore.enemyShown == true,
            false)
    end
end

function MainWindowShell:ShowMinimizedSurface(owner, surface, mode, state)
    owner.minimizingTo = surface
    owner:Hide()
    if surface == "COMMAND" then
        if KWR.HUD then
            KWR.HUD:Invalidate()
            KWR.HUD:Update(KWR.Store:Get())
        end
        return
    end
    if surface == "ROSTER" and KWR.CombatRoster
        and KWR.Util:AllowsCompactBattlefieldSurfaces(state) then
        KWR.CombatRoster:Show(mode or "BOTH", false)
    end
end

function MainWindowShell:PositionLauncher(button, profile)
    if not button then return end
    button:ClearAllPoints()
    if Minimap then
        local angle = math.rad(profile.angle or 225)
        local width = KWR.Util:Number(KWR.Util:Call(Minimap.GetWidth, Minimap), 140)
        local height = KWR.Util:Number(KWR.Util:Call(Minimap.GetHeight, Minimap), width)
        local radius = (math.max(width or 140, height or 140) * 0.5) + 18
        button:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(angle) * radius, math.sin(angle) * radius)
        if type(Minimap.GetFrameLevel) == "function" then
            button:SetFrameLevel((KWR.Util:Number(KWR.Util:Call(
                Minimap.GetFrameLevel, Minimap), 0) or 0) + 8)
        end
    else
        button:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    end
end

function MainWindowShell:UpdateLauncherVisual(button, state)
    if not button then return end
    state = state or KWR.Store:Get()
    local context = state and state.snapshot and state.snapshot.context or {}
    local command = state and state.command or {}
    local urgency = KWR.Util:Number(command.urgency, 0) or 0
    local outer = { 0.93, 0.68, 0.25, 0.96 }
    local inner = { 0.28, 0.58, 1.00, 0.86 }
    local pulse = { 0.93, 0.68, 0.25, 0.16 }
    local tagColor = { 0.93, 0.68, 0.25, 1.00 }
    local tagText = "IDLE"

    if context.preview == true then
        outer = { 1.00, 0.49, 0.17, 0.98 }
        inner = { 0.70, 0.38, 0.98, 0.90 }
        pulse = { 1.00, 0.49, 0.17, 0.22 }
        tagColor = { 1.00, 0.49, 0.17, 1.00 }
        tagText = "PREVIEW"
    elseif context.inPvP == true then
        if urgency >= 85 then
            outer = { 0.95, 0.20, 0.20, 1.00 }
            inner = { 1.00, 0.49, 0.17, 0.92 }
            pulse = { 0.95, 0.20, 0.20, 0.26 }
            tagColor = { 0.95, 0.20, 0.20, 1.00 }
        elseif urgency >= 60 then
            outer = { 0.96, 0.84, 0.24, 0.98 }
            inner = { 1.00, 0.49, 0.17, 0.90 }
            pulse = { 0.96, 0.84, 0.24, 0.20 }
            tagColor = { 0.96, 0.84, 0.24, 1.00 }
        else
            outer = { 0.32, 0.88, 0.32, 0.98 }
            inner = { 0.28, 0.58, 1.00, 0.88 }
            pulse = { 0.32, 0.88, 0.32, 0.18 }
            tagColor = { 0.32, 0.88, 0.32, 1.00 }
        end
        tagText = KWR.Util:Text(command.status, "LIVE", 10)
    end

    button:SetBackdropColor(0.010, 0.012, 0.016, 0.96)
    button:SetBackdropBorderColor(outer[1], outer[2], outer[3], 1)
    button.outer:SetVertexColor(outer[1], outer[2], outer[3], 0.14)
    button.inner:SetVertexColor(inner[1], inner[2], inner[3], 0.16)
    button.disc:SetVertexColor(0.015, 0.018, 0.022, 0.96)
    button.pulse:SetVertexColor(pulse[1], pulse[2], pulse[3], math.max(0.18, pulse[4]))
    button.statusDot:SetVertexColor(tagColor[1], tagColor[2], tagColor[3], tagColor[4])
    button.text:SetTextColor(0.94, 0.95, 0.98, 1)
    if button.tag then
        button.tag:SetText(KWR.Util:Text(tagText, "IDLE", 10))
        button.tag:SetTextColor(tagColor[1], tagColor[2], tagColor[3], 1)
        button.tag:Hide()
    end
end

function MainWindowShell:LauncherMenuSummary(state, helpers)
    if state.snapshot.context.preview then
        return "Preview only. KWR is not reading live battleground data."
    end
    if state.snapshot.context.inPvP then
        return KWR.Util:Text(state.command.action, "Hold current lane.", 88)
    end
    return "RBG setup. Use command surfaces to set assignments."
end