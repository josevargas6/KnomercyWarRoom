-- Offline load and diagnostic smoke test for KWR.
-- Run from the addon root with a Lua 5.1+ interpreter or fengari-node-cli.

unpack = unpack or table.unpack
SlashCmdList = {}
KWR_DB = {
    schemaVersion = 60001,
    profile = {
        main = { page = "COMMAND" },
        hud = { point = "TOP", relativePoint = "TOP", x = 0, y = -180 },
    },
}

local currentTime = 100
local mockPvP = false
local mockCombat = false
local mockInspectSpec
local mockLeftScore, mockRightScore = 900, 1000
local mockWidgetOverrides = {}
local scoreRequests = 0
function GetTime() return currentTime end
function debugprofilestop() return currentTime * 1000 end
function geterrorhandler()
    return function(message)
        return debug.traceback(tostring(message), 2)
    end
end

local Object = {}
Object.__index = function(tableValue, key)
    if key == "SetScript" then
        return function(self, scriptName, callback)
            self.scripts = self.scripts or {}
            self.scripts[scriptName] = callback
        end
    elseif key == "GetScript" then
        return function(self, scriptName)
            return self.scripts and self.scripts[scriptName]
        end
    elseif key == "RegisterEvent" or key == "RegisterUnitEvent" then
        return function(self, event)
            self.events = self.events or {}
            self.events[event] = true
        end
    elseif key == "UnregisterEvent" then
        return function(self, event)
            if self.events then self.events[event] = nil end
        end
    elseif key == "IsEventRegistered" then
        return function(self, event)
            return self.events and self.events[event] == true or false
        end
    elseif key == "CreateFontString" or key == "CreateTexture" then
        return function()
            return setmetatable({ shown = true }, Object)
        end
    elseif key == "SetText" then
        return function(self, value) self.value = value end
    elseif key == "GetText" then
        return function(self) return self.value end
    elseif key == "SetShown" then
        return function(self, shown) self.shown = shown == true end
    elseif key == "SetPoint" then
        return function(self, ...)
            local points = rawget(self, "points")
            if type(points) ~= "table" then
                points = {}
                rawset(self, "points", points)
            end
            points[#points + 1] = { ... }
        end
    elseif key == "ClearAllPoints" then
        return function(self) rawset(self, "points", {}) end
    elseif key == "Show" then
        return function(self) self.shown = true end
    elseif key == "Hide" then
        return function(self) self.shown = false end
    elseif key == "IsShown" then
        return function(self) return self.shown == true end
    elseif key == "SetChecked" then
        return function(self, checked) self.checked = checked == true end
    elseif key == "GetChecked" then
        return function(self) return self.checked == true end
    elseif key == "GetPoint" then
        return function(self, index)
            local points = rawget(self, "points")
            local point = points and points[index or 1]
            if point then return unpack(point) end
            return "CENTER", UIParent, "CENTER", 0, 0
        end
    elseif key == "GetEffectiveScale" then
        return function() return 1 end
    elseif key == "GetChildren" then
        return function() return nil end
    elseif key == "SetAttribute" then
        return function(self, attribute, value)
            local attributes = rawget(self, "attributes")
            if not attributes then
                attributes = {}
                rawset(self, "attributes", attributes)
            end
            attributes[attribute] = value
        end
    elseif key == "GetAttribute" then
        return function(self, attribute)
            local attributes = rawget(self, "attributes")
            return attributes and attributes[attribute]
        end
    elseif key == "RegisterForClicks" then
        return function(self, ...)
            self.registeredClicks = { ... }
        end
    elseif key == "SetSize" then
        return function(self, width, height)
            self.width, self.height = width, height
        end
    elseif key == "GetWidth" then
        return function(self) return rawget(self, "width") or 0 end
    elseif key == "GetHeight" then
        return function(self) return rawget(self, "height") or 0 end
    elseif key == "SetMultiLine" then
        return function(self, enabled)
            self.multiLine = enabled == true
        end
    end
    return function() end
end

function CreateFrame(_, name)
    local frame = setmetatable({ shown = true, scripts = {}, events = {} }, Object)
    if name then _G[name] = frame end
    return frame
end

UIParent = CreateFrame("Frame", "UIParent")
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GameTooltip = setmetatable({}, Object)

C_Timer = {
    After = function(_, callback) callback() end,
}
C_Timer["NewTicker"] = function(_, callback)
    return { Cancel = function() end, callback = callback }
end

C_Map = {
    GetBestMapForUnit = function() return mockPvP and 1366 or nil end,
    GetPlayerMapPosition = function() return nil end,
}
C_UIWidgetManager = {
    GetDoubleStatusBarWidgetVisualizationInfo = function(widgetID)
        if not mockPvP then return nil end
        local override = mockWidgetOverrides[widgetID]
        if override then
            return {
                leftBarValue = override.left,
                rightBarValue = override.right,
                leftBarMax = override.max,
                rightBarMax = override.max,
            }
        end
        return {
            leftBarValue = mockLeftScore,
            rightBarValue = mockRightScore,
            leftBarMax = 1500,
            rightBarMax = 1500,
        }
    end,
    GetDoubleStateIconRowVisualizationInfo = function()
        if not mockPvP then return nil end
        return {
            leftIcons = {
                { iconState = 2, state2Tooltip = "Blacksmith" },
                { iconState = 2, state2Tooltip = "Lumber Mill" },
            },
            rightIcons = {
                { iconState = 2, state2Tooltip = "Farm" },
                { iconState = 2, state2Tooltip = "Stables" },
                { iconState = 2, state2Tooltip = "Mine" },
            },
        }
    end,
}
C_PvP = {
    GetScoreInfo = function(index)
        if not mockPvP then return nil end
        if index == 1 then
            return {
                name = "TestPlayer",
                guid = "Player-1-SELF",
                className = "Warrior",
                classToken = "WARRIOR",
                talentSpec = "Arms",
                roleAssigned = 8,
                faction = 0,
            }
        end
        if index == 2 then
            return {
                name = "EnemyHealer-OtherRealm",
                guid = "Player-2-ENEMY",
                className = "Priest",
                classToken = "PRIEST",
                talentSpec = "Discipline",
                roleAssigned = 4,
                faction = 1,
            }
        end
    end,
}

function IsInInstance() return mockPvP, mockPvP and "pvp" or "none" end
local mockRaid = false
local mockRaidTokensStable = false
local mockRaidNames = { "Alpha", "Bravo", "Charlie" }
function IsInRaid() return mockRaid end
function IsInGroup() return mockRaid end
function GetNumGroupMembers() return mockRaid and 3 or 1 end
function GetNumSubgroupMembers() return 0 end
function GetRaidRosterInfo(index)
    if not mockRaid then return nil end
    return mockRaidNames[index], 0, 1, 90, "Warrior", "WARRIOR",
        "Stormwind City", true, false, "DAMAGER"
end
function GetNumBattlefieldScores() return mockPvP and 2 or 0 end
function RequestBattlefieldScoreData() scoreRequests = scoreRequests + 1 end
local mockLiveEnemy = false
function UnitExists(unit)
    return unit == "player"
        or (mockRaid and unit and unit:find("^raid%d+$") ~= nil)
        or (mockLiveEnemy and unit == "nameplate7")
end
function UnitName(unit)
    if unit == "player" then return "TestPlayer", "TestRealm" end
    if mockRaid and unit and unit:find("^raid%d+$") then
        local index = tonumber(unit:match("%d+"))
        return mockRaidTokensStable and mockRaidNames[index] or "Alpha", "TestRealm"
    end
end
function UnitClass(unit)
    if unit == "player" then return "Warrior", "WARRIOR", 1 end
    if mockRaid and unit and unit:find("^raid%d+$") then
        return "Warrior", "WARRIOR", 1
    end
    if mockLiveEnemy and unit == "nameplate7" then return "Priest", "PRIEST", 5 end
end
function UnitClassBase(unit)
    if unit == "player" then return "WARRIOR", 1 end
    if mockLiveEnemy and unit == "nameplate7" then return "PRIEST", 5 end
end
function UnitIsFriend(_, unit) return unit == "player" end
function UnitRace(unit) if mockLiveEnemy and unit == "nameplate7" then return "Human" end end
function UnitSexBase(unit) if mockLiveEnemy and unit == "nameplate7" then return 1 end end
function UnitHonorLevel(unit) if mockLiveEnemy and unit == "nameplate7" then return 100 end end
function UnitHealth(unit) return mockLiveEnemy and unit == "nameplate7" and 550 or 1000 end
function UnitHealthMax() return 1000 end
function UnitGroupRolesAssigned() return "DAMAGER" end
function UnitIsDeadOrGhost() return false end
function UnitIsConnected() return true end
function UnitAffectingCombat(unit) return mockLiveEnemy and unit == "nameplate7" or false end
function UnitFactionGroup() return "Alliance" end
function UnitGUID(unit)
    if unit == "player" then return "Player-1-SELF" end
    if mockRaid and unit and unit:find("^raid%d+$") then
        return "Player-1-RAID" .. tostring(unit:match("%d+"))
    end
end
local mockDirectPlayerSpec = false
function GetSpecialization() if mockDirectPlayerSpec then return 1 end end
function GetSpecializationInfo(index)
    if mockDirectPlayerSpec and index == 1 then return 252, "Unholy", "", 0, "DAMAGER" end
end
function GetInspectSpecialization(unit) if unit == "player" then return mockInspectSpec end end
function GetSpecializationInfoByID(specID)
    if specID == 258 then return 258, "Shadow" end
end
function GetRealZoneText() return mockPvP and "Arathi Basin" or "Stormwind City" end
function GetZoneText() return mockPvP and "Arathi Basin" or "Stormwind City" end
function GetCursorPosition() return 100, 100 end
function InCombatLockdown() return mockCombat end
function IsShiftKeyDown() return false end

local files = {
    "Core/Addon.lua",
    "Core/Util.lua",
    "Core/Store.lua",
    "Data/Maps.lua",
    "Data/Doctrine.lua",
    "Data/MetaSnapshot.lua",
    "Data/SourceRegistry.lua",
    "Data/PatchData.lua",
    "Data/CombatSpells.lua",
    "Data/Capabilities.lua",
    "Data/Compositions.lua",
    "Data/BattlePlans.lua",
    "Data/ScenarioLibrary.lua",
    "Data/Counters.lua",
    "Data/KnowledgeManifest.lua",
    "Runtime/TeamResolver.lua",
    "Runtime/EncounterHistory.lua",
    "Runtime/Sensors.lua",
    "Runtime/RosterInspector.lua",
    "Runtime/EnemyIntel.lua",
    "Runtime/ObjectiveIntel.lua",
    "Runtime/FormationAdvisor.lua",
    "Runtime/CombatIntel.lua",
    "Runtime/Preview.lua",
    "Runtime/Reporter.lua",
    "Runtime/Predictor.lua",
    "Runtime/Strategist.lua",
    "Runtime/Assignments.lua",
    "Runtime/Commander.lua",
    "Runtime/Learning.lua",
    "Runtime/AAR.lua",
    "Runtime/Verification.lua",
    "Runtime/MatchRuntime.lua",
    "Features/CursorRing.lua",
    "UI/Theme.lua",
    "UI/CopyDialog.lua",
    "UI/QuickCalls.lua",
    "UI/TacticalMap.lua",
    "UI/ReporterMap.lua",
    "UI/CombatRoster.lua",
    "UI/HUD.lua",
    "UI/MainWindow.lua",
    "UI/AARWindow.lua",
    "UI/Options.lua",
    "Core/Diagnostics.lua",
}

local namespace = {}
for _, path in ipairs(files) do
    local chunk, message = loadfile(path)
    assert(chunk, path .. ": " .. tostring(message))
    chunk("KnomercyWarRoom", namespace)
    namespace = _G.KWR or namespace
end

local bootstrap = assert(_G.KWR_BootstrapFrame, "Bootstrap frame was not created.")
assert(bootstrap.scripts.OnEvent, "Bootstrap OnEvent handler was not registered.")
bootstrap.scripts.OnEvent(bootstrap, "ADDON_LOADED", "KnomercyWarRoom")
bootstrap.scripts.OnEvent(bootstrap, "PLAYER_LOGIN")

assert(KWR.ready == true, "KWR did not become ready.")
assert(KWR.db.profile.main.page == "TACTICAL", "Legacy command page did not migrate.")
assert(KWR.db.profile.hud.point == "CENTER" and KWR.db.profile.hud.x == -440,
    "Legacy HUD placement did not migrate.")
assert(KWR.Store:Get().command, "Command state was not published.")
assert(KWR.Store:Get().snapshot.formation.openSlots == 9, "Formation advisor did not count open slots.")
assert(KWR.Store:Get().command.status == "FORMING", "World mode did not publish formation guidance.")
assert(KWR.MatchRuntime.frame:IsEventRegistered("UPDATE_UI_WIDGET"),
    "Active events were not registered during initialization.")
local worldRefreshes = KWR.MatchRuntime.diagnostics.refreshes
KWR.MatchRuntime:HandleEvent("UPDATE_UI_WIDGET")
assert(KWR.MatchRuntime.diagnostics.refreshes == worldRefreshes,
    "Inactive runtime processed a battleground-only event.")

mockRaid = true
assert(KWR.MatchRuntime:ForceRefresh("smoke-raid-resolving"),
    "Resolving raid capture failed.")
local resolvingRoster = KWR.Store:Get().snapshot.roster
assert(#resolvingRoster == 3
    and resolvingRoster[1].shortName ~= resolvingRoster[2].shortName
    and resolvingRoster[2].shortName ~= resolvingRoster[3].shortName,
    "Raid-roster identity did not prevent duplicate loading-screen names.")
local resolvingBindings = 0
for _, player in ipairs(resolvingRoster) do
    if player.unit then resolvingBindings = resolvingBindings + 1 end
end
assert(resolvingBindings == 1,
    "Mismatched raid identities retained unsafe loading-screen bindings.")
mockRaidTokensStable = true
assert(KWR.MatchRuntime:ForceRefresh("smoke-raid-stable"),
    "Stable raid capture failed.")
for _, player in ipairs(KWR.Store:Get().snapshot.roster) do
    assert(player.unit ~= nil and player.unitStable == true,
        "Resolved raid identity did not restore its unit binding.")
end
mockRaid = false
mockRaidTokensStable = false
assert(KWR.MatchRuntime:ForceRefresh("smoke-solo-reset"),
    "Solo roster reset failed.")

mockPvP = true
assert(KWR.MatchRuntime:ForceRefresh("smoke-pvp"), "PvP pipeline refresh failed.")
assert(KWR.MatchRuntime:ForceRefresh("smoke-pvp-team-confirm"), "PvP team confirmation refresh failed.")
assert(scoreRequests >= 1, "PvP capture did not request fresh scoreboard identity data.")
mockWidgetOverrides[9999] = { left = 210, right = 20, max = 1500 }
KWR.Sensors:ObserveWidget({ widgetID = 9999 })
mockLeftScore, mockRightScore = 250, 34
assert(KWR.MatchRuntime:ForceRefresh("smoke-score-authority"),
    "Verified score widget refresh failed.")
assert(KWR.Store:Get().snapshot.score.rawLeft == 250
    and KWR.Store:Get().snapshot.score.rawRight == 34
    and KWR.Store:Get().snapshot.score.widgetID == KWR.Maps:Get("ARATHI").scoreWidget,
    "A dynamic widget displaced the map's verified score source.")
mockLeftScore, mockRightScore = 900, 1000
assert(KWR.MatchRuntime:Reassess(), "Manual battlefield reassessment failed.")
assert(type(KWR.Store:Get().snapshot.reassessment) == "table"
    and type(KWR.Store:Get().snapshot.reassessment.changes) == "table",
    "Manual battlefield reassessment did not publish assignment changes.")
mockLiveEnemy = true
KWR.MatchRuntime:HandleEvent("NAME_PLATE_UNIT_ADDED", "nameplate7")
assert(KWR.EnemyIntel.observedTokens.nameplate7 == "Nameplate",
    "Enemy observer did not retain the active nameplate token.")
local observedEnemy = KWR.Store:Get().snapshot.enemies[1]
assert(observedEnemy and observedEnemy.shortName == "EnemyHealer"
    and observedEnemy.unit == "nameplate7"
    and math.abs((observedEnemy.healthPercent or 0) - 55) < 0.01
    and observedEnemy.localEngaged == true,
    "Restricted live enemy token did not bind to the unique scoreboard identity: "
        .. tostring(observedEnemy and observedEnemy.shortName) .. "/"
        .. tostring(observedEnemy and observedEnemy.unit) .. "/"
        .. tostring(observedEnemy and observedEnemy.healthPercent) .. "/"
        .. tostring(observedEnemy and observedEnemy.localEngaged))
assert(KWR.Store:Get().snapshot.combat.killTarget
    and KWR.Store:Get().snapshot.combat.killTarget.shortName == "EnemyHealer",
    "Local in-combat enemy was not selected as the kill target.")
KWR.MatchRuntime:HandleEvent("NAME_PLATE_UNIT_REMOVED", "nameplate7")
mockLiveEnemy = false
assert(KWR.EnemyIntel.observedTokens.nameplate7 == nil,
    "Enemy observer did not release the removed nameplate token.")
local liveState = KWR.Store:Get()
assert(liveState.snapshot.context.mapKey == "ARATHI", "Sensor did not resolve Arathi Basin.")
assert(liveState.snapshot.context.team.side == "right"
    and liveState.snapshot.context.team.faction == "Horde",
    "Assigned Horde battlefield team did not override native Alliance faction.")
assert(liveState.snapshot.score.friendly == 1000 and liveState.snapshot.score.enemy == 900,
    "Widget score was not normalized to the assigned Horde team.")
assert(liveState.snapshot.objectives.friendly == 3 and liveState.snapshot.objectives.enemy == 2,
    "Objective ownership was not normalized to the assigned Horde team.")
assert(liveState.assignments[1].role == "Anchor Defender"
    and liveState.assignments[1].location == "Farm",
    "Horde Arathi anchor was not assigned to the Horde home objective.")
local verificationReport = KWR.Verification:CurrentReport()
assert(verificationReport:find("Assigned team: Horde / right", 1, true),
    "Live verification report omitted assigned-team evidence.")
assert(verificationReport:find("Score source: ui_widget", 1, true),
    "Live verification report omitted authoritative score evidence.")
assert(verificationReport:find("Command evidence:", 1, true)
    and verificationReport:find("Assignment audit: PASS", 1, true)
    and verificationReport:find("Reporter: ACTIVE", 1, true)
    and verificationReport:find("Transitions:", 1, true),
    "Live verification report omitted command, assignment, Reporter, or transition evidence.")
assert(verificationReport:find("ASSIGN:", 1, true),
    "Live verification report omitted per-player assignment evidence.")
assert(#KWR.Verification.ledger > 0, "Verification ledger did not record live transitions.")
assert(liveState.prediction.status == "WIN", "Pipeline did not project the Arathi 3-2 win.")
assert(liveState.command.status == "WIN", "Commander did not publish the projected status.")
assert(liveState.command.line2:find("NEXT:", 1, true), "Commander did not publish a NEXT line.")
assert(#liveState.snapshot.enemies == 1 and liveState.snapshot.enemies[1].shortName == "EnemyHealer",
    "Scoreboard faction detection did not follow the assigned team.")
assert(KWR.AAR.active ~= nil, "AAR did not open a live match journal.")
assert(KWR.AAR:DetermineResult({
    matchComplete = true,
    scoreEnd = { friendly = 2, enemy = 1, max = 3 },
}) == "VICTORY", "Time-limit match completion did not resolve the winning team.")

mockRightScore = 1500
assert(KWR.MatchRuntime:ForceRefresh("smoke-pvp-complete-score"), "Final PvP score refresh failed.")
mockPvP = false
KWR.db.profile.preview = true
assert(KWR.MatchRuntime:ForceRefresh("smoke-preview"), "Preview pipeline refresh failed.")
local previewState = KWR.Store:Get()
assert(previewState.snapshot.context.preview == true, "Preview was not explicitly labeled.")
assert(previewState.mode == "PREVIEW", "Store did not publish preview mode.")
assert(#previewState.snapshot.enemies == 10, "Preview enemy tracker was not populated.")
assert(#previewState.assignments == 10, "Preview assignments were not generated.")
assert(previewState.snapshot.reporter.active == true, "Reporter did not run in the background pipeline.")
assert(previewState.snapshot.reporter.coverage.friendly == 10, "Reporter missed friendly movement tracks.")
assert(previewState.snapshot.reporter.coverage.enemy == 10, "Reporter missed enemy movement tracks.")
assert(type(previewState.prediction.movementEvidence) == "string", "Prediction did not receive Reporter evidence.")
assert(previewState.snapshot.combat.killTarget ~= nil, "Combat intelligence did not select a local kill target.")
assert(previewState.snapshot.combat.killTarget.shortName == "Syraelina", "Combat intelligence did not prefer the exposed healer.")
assert(previewState.snapshot.combat.killTarget.localKillTarget == true, "Selected kill target was not marked for the compact glow.")
assert(previewState.snapshot.combat.killReason:find("trinket used", 1, true), "Observed trinket use did not affect kill reasoning.")
assert(previewState.snapshot.strategy.planID ~= nil, "Strategy engine did not select a battle plan.")
assert(previewState.snapshot.formation.complete == true, "Full preview roster was not formation-ready.")
assert(previewState.command.planID == previewState.snapshot.strategy.planID, "Commander did not publish the selected plan.")
assert(KWR.MetaSnapshot:Count() == 40, "RBG meta snapshot is incomplete.")
assert(KWR.MetaSnapshot:Lookup("PRIEST", "Discipline").rank == 1, "RBG meta snapshot lookup failed.")
assert(#KWR.AAR:GetHistory() == 1, "Completed match was not committed to the AAR journal.")
local completed = KWR.AAR:GetHistory()[1]
assert(completed.result == "VICTORY", "AAR did not record the assigned Horde team's victory.")
completed.primaryPlanID = completed.primaryPlanID or "AB_STABLE_THREE"
completed.result = "VICTORY"
KWR.AAR:SaveFeedback(completed.id, { wonBy = "Objectives", notes = "Reviewed smoke match." })
KWR.AARWindow:Show(completed.id)
assert(KWR.AARWindow.frame.wonBy.value == "Objectives"
    and KWR.AARWindow.frame.wonBy.buttons[2].selected == true,
    "Saved AAR selection did not remain visibly selected.")
local strengthButton = KWR.AARWindow.frame.strength.buttons[1]
strengthButton.scripts.OnClick(strengthButton)
strengthButton.scripts.OnLeave(strengthButton)
assert(strengthButton.selected == true
    and KWR.AARWindow.frame.strength.value == "Coordination",
    "Clicked AAR selection did not retain its selected state.")
assert(KWR.Learning:Summary().samples == 1, "Reviewed AAR did not enter bounded learning.")
assert(KWR.Learning:Adjustment(completed.mapKey, completed.primaryPlanID) == 0,
    "Learning affected decisions before the minimum sample size.")

currentTime = 101
local movedPreview = KWR.Preview:Build()
movedPreview.roster[1].x = movedPreview.roster[1].x + 0.03
local movedReport = KWR.Reporter:Observe(movedPreview)
local playerTrack
for _, track in ipairs(movedReport.friendly) do
    if track.name == "Knomercy" then playerTrack = track break end
end
assert(playerTrack and #playerTrack.points >= 2, "Reporter did not retain bounded movement history.")
assert(playerTrack.direction ~= "HOLDING", "Reporter did not derive a movement direction.")
assert(type(movedReport.pressure) == "table", "Reporter did not analyze objective pressure.")

KWR.db.profile.preview = false
mockInspectSpec = 258
assert(KWR.MatchRuntime:ForceRefresh("smoke-inspect-observed"), "Observed-spec refresh failed.")
assert(KWR.Store:Get().snapshot.roster[1].spec == "Shadow", "Observed teammate spec was not captured.")
mockInspectSpec = nil
assert(KWR.MatchRuntime:ForceRefresh("smoke-inspect-retained"), "Retained-spec refresh failed.")
assert(KWR.Store:Get().snapshot.roster[1].spec == "Shadow",
    "Observed teammate spec was discarded after inspection changed.")
mockDirectPlayerSpec = true
assert(KWR.MatchRuntime:ForceRefresh("smoke-player-spec"), "Direct player-spec refresh failed.")
assert(KWR.Store:Get().snapshot.roster[1].spec == "Unholy"
    and KWR.Store:Get().snapshot.roster[1].role == "DAMAGER"
    and KWR.Store:Get().snapshot.roster[1].specSource == "player_spec",
    "Player specialization did not use the direct specialization API.")
assert(KWR.MatchRuntime:ForceRefresh("smoke-world"), "World pipeline refresh failed.")
assert(KWR.Store:Get().snapshot.context.preview ~= true, "Preview did not turn off cleanly.")
assert(KWR.MatchRuntime.active == false, "Runtime remained active after leaving PvP.")
assert(KWR.MatchRuntime.frame:IsEventRegistered("UPDATE_UI_WIDGET"),
    "Stopping the runtime mutated its event subscriptions.")

KWR.CombatRoster:Show("TEAM")
KWR.HUD.ready = true
KWR.db.profile.hud.enabled = true
KWR.HUD:Update(KWR.Store:Get())
assert(KWR.CombatRoster.frame:IsShown() and KWR.HUD.frame:IsShown(),
    "Compact surfaces did not open for coordination test.")
KWR.MainWindow:Show("TEAM")
assert(not KWR.CombatRoster.frame:IsShown() and not KWR.HUD.frame:IsShown(),
    "Expanded mode did not suppress compact surfaces.")
Minimap = CreateFrame("Frame", "Minimap")
Minimap:SetSize(140, 140)
KWR.MainWindow:PositionLauncher()
local launcherPoint = KWR.MainWindow.launcher.points
    and KWR.MainWindow.launcher.points[1]
assert(KWR.MainWindow.launcher.width == 32
    and launcherPoint
    and math.floor(math.sqrt((launcherPoint[4] * launcherPoint[4])
        + (launcherPoint[5] * launcherPoint[5])) + 0.5) == 82,
    "Minimap launcher is not compact or positioned outside the map ring.")
local teamCard = KWR.MainWindow.pages.TEAM.rosterCard
for index, rowField in ipairs({ "player", "spec", "role", "health", "life", "position" }) do
    local headerPoint = teamCard.headers[index].points
        and teamCard.headers[index].points[1]
    local rowPoint = teamCard.rows[1][rowField].points
        and teamCard.rows[1][rowField].points[1]
    assert(headerPoint and rowPoint
        and headerPoint[2] == rowPoint[2] + 8,
        "Team header and row field are not aligned: " .. rowField)
end
local quickCall = KWR.MainWindow.pages.OBJECTIVES.callsCard.buttons[1]
assert(quickCall.quickCallSecure == true
    and quickCall:GetAttribute("type1") == "macro"
    and quickCall:GetAttribute("macrotext1") == "/instance INC PRIMARY",
    "Quick Call was not armed as a fixed player-click secure action.")
mockPvP = true
quickCall.scripts.PostClick(quickCall, "LeftButton")
assert(KWR.MainWindow.pages.OBJECTIVES.callsCard.status.value == "CALL ACTIVATED: INC PRIMARY",
    "Quick Call did not provide visible battleground confirmation.")
mockPvP = false
mockCombat = true
local combatFallback = KWR.QuickCalls:CreateButton(UIParent, "HELP HOME", 132, 25)
assert(combatFallback.quickCallFallback == true
    and combatFallback:GetAttribute("macrotext1") == nil,
    "A first-created in-combat Quick Call did not remain a non-secure fallback.")
mockCombat = false
mockCombat = true
KWR.MainWindow:Hide()
assert(KWR.MainWindow.frame:IsShown()
    and KWR.MainWindow.pendingVisibility
    and KWR.MainWindow.pendingVisibility.shown == false,
    "Protected expanded window hide was not deferred during combat.")
mockCombat = false
KWR.MainWindow:FlushCombatVisibility()
assert(not KWR.MainWindow.frame:IsShown(),
    "Deferred expanded window hide did not complete after combat.")
KWR.MainWindow:Show("TEAM")
local rejectedCall = KWR.QuickCalls:CreateButton(UIParent, "DYNAMIC UNREVIEWED CALL", 132, 25)
assert(rejectedCall.quickCallRejected == true
    and rejectedCall:GetAttribute("macrotext1") == nil,
    "An unreviewed Quick Call reached the secure binding path.")
KWR.CopyDialog:ShowCompact("Compact Test", "ONE LINE")
assert(KWR.CopyDialog.frame.width == 460 and KWR.CopyDialog.frame.height == 126
    and KWR.CopyDialog.frame.edit.multiLine == false,
    "Single-line copy did not use the compact dialog geometry.")
KWR.CopyDialog:ShowText("Report Test", "LINE 1\nLINE 2")
assert(KWR.CopyDialog.frame.width == 620 and KWR.CopyDialog.frame.height == 240
    and KWR.CopyDialog.frame.edit.multiLine == true,
    "Report copy did not restore the multiline dialog geometry.")
KWR.CopyDialog.frame:Hide()
KWR.MainWindow:RestoreCompactSurfaces()
assert(KWR.CombatRoster.frame:IsShown() and KWR.HUD.frame:IsShown(),
    "Compact surfaces were not restored after expanded mode.")
KWR.MainWindow.frame:Hide()

local originalAfter = C_Timer.After
local scheduled = {}
C_Timer.After = function(delay, callback)
    scheduled[#scheduled + 1] = { delay = delay, callback = callback }
end
KWR.MatchRuntime.timerToken = (KWR.MatchRuntime.timerToken or 0) + 1
KWR.MatchRuntime.pending = false
KWR.MatchRuntime.pendingDueAt = nil
KWR.MatchRuntime.requiredSettleAt = nil
local queueRefreshes = KWR.MatchRuntime.diagnostics.refreshes
KWR.MatchRuntime:Queue("queue-first", 0.02)
KWR.MatchRuntime:Queue("queue-newest", 0.02)
assert(#scheduled == 1 and KWR.MatchRuntime.pending == true,
    "Runtime queue did not coalesce simultaneous refresh requests.")
currentTime = currentTime + 1
scheduled[1].callback()
assert(#scheduled == 2
    and KWR.MatchRuntime.diagnostics.refreshes == queueRefreshes + 1,
    "Runtime queue discarded the newest coalesced truth update.")
currentTime = currentTime + 1
scheduled[2].callback()
assert(KWR.MatchRuntime.pending == false
    and KWR.MatchRuntime.diagnostics.refreshes == queueRefreshes + 2,
    "Runtime queue did not complete its bounded follow-up refresh.")
scheduled = {}
KWR.MatchRuntime:ScheduleTransitionSweep("transition-test", false)
assert(#scheduled == 4,
    "Zone transition did not schedule four bounded truth-settle passes.")
KWR.MatchRuntime.transitionToken = KWR.MatchRuntime.transitionToken + 1
C_Timer.After = originalAfter

local result = KWR.Diagnostics:Run()
if result.failed > 0 then
    local report = KWR.Diagnostics:Report()
    error(report)
end

print("KWR_SMOKE_PASS checks=" .. tostring(result.passed))
