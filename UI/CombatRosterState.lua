local _, KWR = ...

local CombatRosterState = {}
KWR.CombatRosterState = CombatRosterState

local function indexAssignment(index, player, assignment)
    if not player or not assignment then return end
    local name = KWR.Util:Text(player.name, "", 96)
    local shortName = KWR.Util:Text(player.shortName, "", 64)
    if name ~= "" then index[name] = assignment end
    if shortName ~= "" then index[shortName] = assignment end
end

local function sameCallTarget(enemy, call)
    if not enemy or not call then return false end
    local enemyGUID = KWR.Util:Text(enemy.guid, "", 96)
    local callGUID = KWR.Util:Text(call.targetGUID, "", 96)
    if enemyGUID ~= "" and callGUID ~= "" then
        return enemyGUID == callGUID
    end
    local enemyName = KWR.Util:CanonicalShortName(enemy.name or enemy.shortName)
    local callName = KWR.Util:CanonicalShortName(call.target)
    return enemyName ~= "" and callName ~= "" and enemyName == callName
end

local function friendlyAssignments(state, roster)
    local index = {}
    for _, assignment in ipairs(state.assignments or {}) do
        indexAssignment(index, assignment, assignment)
    end
    local packet = state.snapshot and state.snapshot.executionCommand
    if packet and KWR.ExecutionCommandBuilder then
        for _, player in ipairs(roster or {}) do
            local personal = KWR.ExecutionCommandBuilder:PersonalFor(
                packet, player.name or player.shortName, player.guid)
            if personal then
                indexAssignment(index, player, personal)
            end
        end
    end
    return index
end

local function enemyCalls(snapshot, enemies)
    local index = {}
    local localFight = snapshot and snapshot.executionCommand
        and snapshot.executionCommand.localFight or {}
    for _, enemy in ipairs(enemies or {}) do
        local call
        if sameCallTarget(enemy, localFight.kill) then
            call = {
                fightMode = localFight.kill.mode == "PRESSURE" and "PRESS" or "KILL",
                target = localFight.kill.target,
            }
        end
        for _, control in ipairs(localFight.controls or {}) do
            if sameCallTarget(enemy, control) then
                call = call or {
                    fightMode = "CC",
                    target = control.target,
                }
                call.ccActor = control.assigned == true
                    and KWR.Util:ShortName(control.actor) or "OPEN"
                break
            end
        end
        if call then indexAssignment(index, enemy, call) end
    end
    return index
end

local function enemyKey(enemy)
    return KWR.Util:Text(
        enemy and (enemy.key or enemy.guid or enemy.name
            or enemy.shortName),
        "", 96)
end

function CombatRosterState:StableEnemyRows(owner, enemies)
    owner.enemySlotKeys = type(owner.enemySlotKeys) == "table"
        and owner.enemySlotKeys or {}
    local byKey = {}
    local placed = {}
    for _, enemy in ipairs(enemies or {}) do
        local key = enemyKey(enemy)
        if key ~= "" then byKey[key] = enemy end
    end

    local result = {}
    local availableSlots = {}
    for index = 1, owner.maxRows do
        local key = owner.enemySlotKeys[index]
        local enemy = key and byKey[key] or nil
        if enemy then
            result[index] = enemy
            placed[key] = true
        else
            availableSlots[#availableSlots + 1] = index
        end
    end
    local availableIndex = 1
    for _, enemy in ipairs(enemies or {}) do
        local key = enemyKey(enemy)
        if key ~= "" and not placed[key] then
            local index = availableSlots[availableIndex]
            if index then
                owner.enemySlotKeys[index] = key
                result[index] = enemy
                placed[key] = true
                availableIndex = availableIndex + 1
            end
        end
    end
    return result
end

function CombatRosterState:Update(owner, state, helpers)
    owner.lastState = state
    if not KWR.Util:AllowsCompactBattlefieldSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        owner.inPvP = false
        owner.autoVisible = false
        if owner.teamFrame or owner.enemyFrame then owner:Request(false, nil, false) end
        return
    end
    local context = state.snapshot and state.snapshot.context or {}
    local sessionKey = KWR.Util:Text(context.sessionKey,
        KWR.Util:BattlefieldSessionKey(context), 96)
    if sessionKey ~= owner.lastSessionKey then
        owner.lastSessionKey = sessionKey
        if owner.teamFrame or owner.enemyFrame then
            owner:ResetVisualCache(false)
        end
    end
    local inPvP = state.snapshot and state.snapshot.context
        and state.snapshot.context.inPvP == true
    local enteredPvP = inPvP and owner.inPvP ~= true
    local leftPvP = owner.inPvP == true and not inPvP
    owner.inPvP = inPvP
    if enteredPvP and KWR.db.profile.combatRoster.autoShowInPvP == true then
        owner.autoVisible = true
    elseif leftPvP then
        owner.autoVisible = false
        owner.lastSessionKey = nil
        if owner.teamFrame or owner.enemyFrame then
            owner:ResetVisualCache(false)
        end
        if owner:AnyShown()
            and KWR.db.profile.combatRoster.shown ~= true then
            owner:Request(false, nil, false)
        end
    end
    if not owner.teamFrame or not owner.enemyFrame then
        if inPvP and not (InCombatLockdown and InCombatLockdown()) then
            owner:Create()
        else
            return
        end
    end
    local desiredTeamShown = KWR.db.profile.combatRoster.teamShown
    local desiredEnemyShown = KWR.db.profile.combatRoster.enemyShown
    if owner.autoVisible and not desiredTeamShown and not desiredEnemyShown then
        desiredTeamShown = true
        desiredEnemyShown = true
    end
    if (desiredTeamShown or desiredEnemyShown)
        and not owner:AnyShown()
        and not (KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown())
        and not (InCombatLockdown and InCombatLockdown()) then
        owner:RequestVisibility(desiredTeamShown, desiredEnemyShown, false)
    end
    local teamShown = owner:IsShown("TEAM")
    local enemyShown = owner:IsShown("ENEMY")
    local roster = KWR.TeamResolver:NormalizePublishedRoster(
        state.snapshot.roster or {})
    local friendlyScoreFaction = state.snapshot.context and state.snapshot.context.team
        and state.snapshot.context.team.scoreFaction
    local enemies = KWR.EnemyIntel:FilterPublishedTruth(
        roster,
        state.snapshot.enemies,
        friendlyScoreFaction)
    local stableEnemies = self:StableEnemyRows(owner, enemies)
    owner:UpdateSpotlight(enemies, state.snapshot.combat,
        state.snapshot.executionCommand and state.snapshot.executionCommand.localFight)
    local assignments = friendlyAssignments(state, roster)
    local fightCalls = enemyCalls(state.snapshot, enemies)
    local alive, localEnemies, visibleEnemies, staleEnemies = 0, 0, 0, 0
    for _, player in ipairs(roster) do
        if not player.dead and player.connected ~= false then alive = alive + 1 end
    end
    for _, enemy in ipairs(enemies) do
        if enemy.localRange and not enemy.dead then localEnemies = localEnemies + 1 end
        if enemy.visible and not enemy.dead then visibleEnemies = visibleEnemies + 1 end
        if enemy.visible ~= true and enemy.age and enemy.age > 8 then staleEnemies = staleEnemies + 1 end
    end
    local expectedRoster = #roster
    if inPvP then
        local hydration = type(context.rosterHydration) == "table"
            and context.rosterHydration or {}
        expectedRoster = math.max(#roster,
            KWR.Util:Number(hydration.expected, #roster) or #roster)
    end
    local rosterBindingsStable = true
    for _, player in ipairs(roster) do
        if player.unitStable ~= true then
            rosterBindingsStable = false
            break
        end
    end
    local rosterLoading = inPvP
        and (#roster < expectedRoster or not rosterBindingsStable)
    local headingCount = rosterLoading and #roster or alive
    local teamHeading = helpers.formatTeamHeading(
        headingCount, expectedRoster)
    if owner.teamHeadingSignature ~= teamHeading then
        owner.teamHeadingSignature = teamHeading
        owner.teamFrame.heading:SetText(teamHeading)
    end
    local enemyHeading = helpers.formatEnemyHeading(
        localEnemies, visibleEnemies, staleEnemies)
    if owner.enemyHeadingSignature ~= enemyHeading then
        owner.enemyHeadingSignature = enemyHeading
        owner.enemyFrame.heading:SetText(enemyHeading)
    end
    if InCombatLockdown and InCombatLockdown() then
        owner:UpdateBoundRows(owner.teamRows, roster, "TEAM", state.snapshot.combat, assignments)
        owner:UpdateBoundRows(
            owner.enemyRows, stableEnemies, "ENEMY",
            state.snapshot.combat, fightCalls)
        return
    end
    owner.rebindPending = false
    owner:UpdateRows(owner.teamRows, roster, "TEAM", state.snapshot.combat,
        assignments, true, teamShown)
    owner:UpdateRows(owner.enemyRows, stableEnemies, "ENEMY", state.snapshot.combat,
        fightCalls, true, enemyShown)
end

function CombatRosterState:Layout(owner, mode, helpers)
    if not owner.teamFrame or not owner.enemyFrame then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        owner.pending = {
            teamShown = owner:IsShown("TEAM"),
            enemyShown = owner:IsShown("ENEMY"),
            persist = false,
        }
        return
    end
    mode = mode == "TEAM" and "TEAM" or (mode == "ENEMY" and "ENEMY" or "BOTH")
    KWR.db.profile.combatRoster.mode = mode

    local visuals = KWR.db.profile.combatRoster.combatVisuals ~= false
    local teamFrame = owner.teamFrame
    local enemyFrame = owner.enemyFrame
    local teamPane = teamFrame.pane
    local enemyPane = enemyFrame.pane
    local spotlight = enemyFrame.targetSpotlight
    local rowWidth = helpers.SOLO_WIDTH - (helpers.FRAME_PADDING * 2) - 16

    teamFrame:SetSize(helpers.SOLO_WIDTH, helpers.frameHeight(false))
    teamFrame:EnableMouse(true)
    KWR.Theme:Style(teamFrame, "background", "borderHi")
    teamPane:ClearAllPoints()
    teamPane:SetPoint(
        "TOPLEFT", teamFrame, "TOPLEFT",
        helpers.FRAME_PADDING,
        -(helpers.FRAME_PADDING + helpers.TOOLBAR_HEIGHT + helpers.SECTION_GAP))
    teamPane:SetSize(helpers.SOLO_WIDTH - (helpers.FRAME_PADDING * 2), helpers.laneHeight())

    enemyFrame:SetSize(helpers.SOLO_WIDTH, helpers.frameHeight(visuals))
    enemyFrame:EnableMouse(true)
    KWR.Theme:Style(enemyFrame, "background", "borderHi")
    spotlight:ClearAllPoints()
    spotlight:SetShown(visuals)
    local enemyContentTop = -(helpers.FRAME_PADDING + helpers.TOOLBAR_HEIGHT + helpers.SECTION_GAP)
    if visuals then
        spotlight:SetPoint(
            "TOPLEFT", enemyFrame, "TOPLEFT",
            helpers.FRAME_PADDING, enemyContentTop)
        spotlight:SetPoint(
            "TOPRIGHT", enemyFrame, "TOPRIGHT",
            -helpers.FRAME_PADDING, enemyContentTop)
        enemyContentTop = enemyContentTop - helpers.COMMAND_HEIGHT - helpers.SECTION_GAP
    end
    enemyPane:ClearAllPoints()
    enemyPane:SetPoint(
        "TOPLEFT", enemyFrame, "TOPLEFT",
        helpers.FRAME_PADDING, enemyContentTop)
    enemyPane:SetSize(helpers.SOLO_WIDTH - (helpers.FRAME_PADDING * 2), helpers.laneHeight())

    for index = 1, owner.maxRows do
        local teamRow = owner.teamRows[index]
        local enemyRow = owner.enemyRows[index]
        teamRow:ClearAllPoints()
        enemyRow:ClearAllPoints()
        teamRow:SetWidth(rowWidth)
        enemyRow:SetWidth(rowWidth)
        helpers.applyRowMetrics(teamRow, rowWidth)
        helpers.applyRowMetrics(enemyRow, rowWidth)
        teamRow:SetPoint(
            "TOPLEFT", teamPane, "TOPLEFT", 8,
            -helpers.ROW_TOP - ((index - 1) * helpers.ROW_SPACING))
        enemyRow:SetPoint(
            "TOPLEFT", enemyPane, "TOPLEFT", 8,
            -helpers.ROW_TOP - ((index - 1) * helpers.ROW_SPACING))
    end
end