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
_G.__kwrProfileTimeMs = _G.__kwrProfileTimeMs or 100000
local mockPvP = false
local mockInstanceType = "none"
local mockCombat = false
local mockLocale = "enUS"
local mockInspectSpec
local mockLeftScore, mockRightScore = 900, 1000
local mockWidgetOverrides = {}
local scoreRequests = 0
function GetTime() return currentTime end
function GetLocale() return mockLocale end
function debugprofilestop()
    local runtimeMs
    if type(os) == "table" and type(os.clock) == "function" then
        runtimeMs = os.clock() * 1000
    end
    if type(runtimeMs) == "number" and runtimeMs > _G.__kwrProfileTimeMs then
        _G.__kwrProfileTimeMs = runtimeMs
    else
        _G.__kwrProfileTimeMs = _G.__kwrProfileTimeMs + 0.05
    end
    return _G.__kwrProfileTimeMs
end
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
    elseif key == "SetWidth" then
        return function(self, width) self.width = width end
    elseif key == "SetHeight" then
        return function(self, height) self.height = height end
    elseif key == "SetBackdropColor" then
        return function(self, ...)
            self.backdropColor = { ... }
        end
    elseif key == "SetBackdropBorderColor" then
        return function(self, ...)
            self.backdropBorderColor = { ... }
        end
    elseif key == "SetTextColor" then
        return function(self, ...)
            self.textColor = { ... }
        end
    elseif key == "SetVertexColor" then
        return function(self, ...)
            self.vertexColor = { ... }
        end
    elseif key == "GetWidth" then
        return function(self) return rawget(self, "width") or 0 end
    elseif key == "GetHeight" then
        return function(self) return rawget(self, "height") or 0 end
    elseif key == "SetMultiLine" then
        return function(self, enabled)
            self.multiLine = enabled == true
        end
    elseif key == "SetSpacing" then
        return function(self, spacing) self.spacing = spacing end
    end
    return function() end
end

function CreateFrame(frameType, name, parent, template)
    local frame = setmetatable({
        shown = true,
        scripts = {},
        events = {},
        frameType = frameType,
        parent = parent,
        template = template,
    }, Object)
    if name then _G[name] = frame end
    return frame
end

UIParent = CreateFrame("Frame", "UIParent")
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GameTooltip = setmetatable({}, Object)
CompactRaidFrameManager = CreateFrame("Frame", "CompactRaidFrameManager")
CompactRaidFrameContainer = CreateFrame("Frame", "CompactRaidFrameContainer")
local compactRaidManagerSettings = {
    IsShown = true,
}
function CompactRaidFrameManager_SetSetting(key, value)
    compactRaidManagerSettings[key] = value
end

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
local mockScoreboardRows
C_PvP = {
    GetScoreInfo = function(index)
        if not mockPvP then return nil end
        return mockScoreboardRows[index]
    end,
}

function IsInInstance()
    if mockPvP then
        return true, mockInstanceType == "arena" and "arena" or "pvp"
    end
    if mockInstanceType ~= "none" then
        return true, mockInstanceType
    end
    return false, "none"
end
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
mockScoreboardRows = {
    {
        name = "TestPlayer",
        guid = "Player-1-SELF",
        className = "Warrior",
        classToken = "WARRIOR",
        talentSpec = "Arms",
        roleAssigned = 8,
        faction = 0,
    },
    {
        name = "EnemyHealer-OtherRealm",
        guid = "Player-2-ENEMY",
        className = "Priest",
        classToken = "PRIEST",
        talentSpec = "Discipline",
        roleAssigned = 4,
        faction = 1,
    },
}
function GetNumBattlefieldScores() return mockPvP and #mockScoreboardRows or 0 end
function RequestBattlefieldScoreData() scoreRequests = scoreRequests + 1 end
local mockLiveEnemies = {}
local function mockLiveEnemy(unit)
    return unit and mockLiveEnemies[unit] or nil
end
function UnitExists(unit)
    return unit == "player"
        or (mockRaid and unit and unit:find("^raid%d+$") ~= nil)
        or mockLiveEnemy(unit) ~= nil
end
function UnitName(unit)
    if unit == "player" then return "TestPlayer", "TestRealm" end
    if mockRaid and unit and unit:find("^raid%d+$") then
        local index = tonumber(unit:match("%d+"))
        return mockRaidTokensStable and mockRaidNames[index] or "Alpha", "TestRealm"
    end
    local enemy = mockLiveEnemy(unit)
    if enemy then return enemy.name, enemy.realm end
end
function UnitClass(unit)
    if unit == "player" then return "Warrior", "WARRIOR", 1 end
    if mockRaid and unit and unit:find("^raid%d+$") then
        return "Warrior", "WARRIOR", 1
    end
    local enemy = mockLiveEnemy(unit)
    if enemy then return enemy.className, enemy.classFile, enemy.classID or 1 end
end
function UnitClassBase(unit)
    if unit == "player" then return "WARRIOR", 1 end
    local enemy = mockLiveEnemy(unit)
    if enemy then return enemy.classFile, enemy.classID or 1 end
end
function UnitIsFriend(_, unit) return unit == "player" end
function UnitCanAttack(_, unit) return unit ~= "player" and mockLiveEnemy(unit) ~= nil end
function UnitIsPlayer(unit) return unit == "player" or mockLiveEnemy(unit) ~= nil end
function UnitRace(unit) local enemy = mockLiveEnemy(unit); if enemy then return enemy.raceName end end
function UnitSexBase(unit) local enemy = mockLiveEnemy(unit); if enemy then return enemy.gender or 1 end end
function UnitHonorLevel(unit) local enemy = mockLiveEnemy(unit); if enemy then return enemy.honorLevel or 0 end end
function UnitHealth(unit) local enemy = mockLiveEnemy(unit); return enemy and enemy.health or 1000 end
function UnitHealthMax(unit) local enemy = mockLiveEnemy(unit); return enemy and enemy.healthMax or 1000 end
function UnitGroupRolesAssigned() return "DAMAGER" end
function UnitIsDeadOrGhost(unit) local enemy = mockLiveEnemy(unit); return enemy and enemy.dead == true or false end
function UnitIsConnected() return true end
function UnitAffectingCombat(unit) local enemy = mockLiveEnemy(unit); return enemy and enemy.inCombat == true or false end
function UnitFactionGroup() return "Alliance" end
local mockMercenary = false
function UnitIsMercenary() return mockMercenary end
function UnitGUID(unit)
    if unit == "player" then return "Player-1-SELF" end
    if mockRaid and unit and unit:find("^raid%d+$") then
        return "Player-1-RAID" .. tostring(unit:match("%d+"))
    end
    local enemy = mockLiveEnemy(unit)
    if enemy then return enemy.guid end
end
local mockDirectPlayerSpec = false
function GetSpecialization() if mockDirectPlayerSpec then return 1 end end
function GetSpecializationInfo(index)
    if mockDirectPlayerSpec and index == 1 then return 252, "Unholy", "", 0, "DAMAGER" end
end
inspectNotifications = {}
clearedInspectPlayers = 0
function CanInspect(unit)
    return unit ~= nil and unit ~= "" and unit ~= "player"
end
function NotifyInspect(unit)
    inspectNotifications[#inspectNotifications + 1] = unit
end
function ClearInspectPlayer()
    clearedInspectPlayers = clearedInspectPlayers + 1
end
function GetInspectSpecialization(unit)
    if unit == "player" or (unit and unit:find("^raid%d+$")) or (unit and unit:find("^party%d+$")) then
        return mockInspectSpec
    end
end
function GetSpecializationInfoByID(specID)
    if specID == 258 then return 258, "Shadow" end
    if specID == 257 then return 257, "Holy" end
end
function GetRealZoneText() return mockPvP and "Arathi Basin" or "Stormwind City" end
function GetZoneText() return mockPvP and "Arathi Basin" or "Stormwind City" end
function GetCursorPosition() return 100, 100 end
function InCombatLockdown() return mockCombat end
function IsShiftKeyDown() return false end

local files = {
    "Core/Addon.lua",
    "Core/BuildInfo.lua",
    "Core/CommandView.lua",
    "Core/Util.lua",
    "Core/CommandReview.lua",
    "Core/Store.lua",
    "Data/Maps.lua",
    "Data/RBGMapProfiles.lua",
    "Data/ObjectiveRules.lua",
    "Data/AssignmentDoctrine.lua",
    "Data/Doctrine.lua",
    "Data/MetaSnapshot.lua",
    "Data/SourceRegistry.lua",
    "Data/PatchData.lua",
    "Data/CombatSpells.lua",
    "Data/SpellTags.lua",
    "Data/CommandVocabulary.lua",
    "Data/PlayerControlProfiles.lua",
    "Data/EnemyProblemTypes.lua",
    "Data/ProblemSignalRegistry.lua",
    "Data/CounterplayMatrix.lua",
    "Data/ObjectiveWeights.lua",
    "Data/Capabilities.lua",
    "Data/Compositions.lua",
    "Data/BattlePlans.lua",
    "Data/ScenarioLibrary.lua",
    "Data/ScenarioCalibration.lua",
    "Data/ScenarioAdversarialCalibration.lua",
    "Data/ScenarioExpertCorpus.lua",
    "Data/CompThreats.lua",
    "Data/EnemyDefenseModels.lua",
    "Data/OpenerDoctrine.lua",
    "Data/RecoveryDoctrine.lua",
    "Data/EndgameDoctrine.lua",
    "Data/DoctrineComparisons.lua",
    "Data/ScenarioFixtures.lua",
    "Data/Counters.lua",
    "Data/KnowledgeManifest.lua",
    "Rulesets/Retail_Current.lua",
    "Rulesets/PTR_12_1.lua",
    "Rulesets/Strict_Future.lua",
    "Rulesets/RulesetLoader.lua",
    "Compliance/ApiMode.lua",
    "Compliance/ComplianceGate.lua",
    "Adapters/SafeAuraAdapter.lua",
    "Adapters/SafeCombatLogAdapter.lua",
    "Adapters/SafeUnitAdapter.lua",
    "Adapters/SafeBattlegroundAdapter.lua",
    "Adapters/SafeSpeechAdapter.lua",
    "State/FactStore.lua",
    "State/BoardStateTypes.lua",
    "State/BoardStateBuilder.lua",
    "State/BoardState.lua",
    "State/LocalTeamfightState.lua",
    "State/EnemyProblemState.lua",
    "State/FriendlyRoleState.lua",
    "State/AssignmentState.lua",
    "State/CountdownState.lua",
    "State/PlayerTargetState.lua",
    "State/DRTracker.lua",
    "Intelligence/EnemyProblemDetector.lua",
    "Intelligence/AssignmentScorer.lua",
    "Intelligence/AssignmentOptimizer.lua",
    "Intelligence/KillTargetSelector.lua",
    "Intelligence/CommandReasonBuilder.lua",
    "Intelligence/TeamfightCommandPlanner.lua",
    "Intelligence/ExecutionCommandBuilder.lua",
    "Runtime/TeamResolver.lua",
    "Runtime/EncounterHistory.lua",
    "Runtime/OpponentModels.lua",
    "Runtime/Sensors.lua",
    "Runtime/RosterInspector.lua",
    "Runtime/EnemyIntel.lua",
    "Runtime/ObjectiveIntel.lua",
    "Runtime/FormationAdvisor.lua",
    "Runtime/CombatIntel.lua",
    "Runtime/Preview.lua",
    "Runtime/Reporter.lua",
    "Runtime/Predictor.lua",
    "Runtime/EnemyResponsePlanner.lua",
    "Runtime/Strategist.lua",
    "Runtime/AssignmentOverrides.lua",
    "Runtime/Assignments.lua",
    "Runtime/Commander.lua",
    "Runtime/Learning.lua",
    "Runtime/AAR.lua",
    "Runtime/Verification.lua",
    "Runtime/MemoryBudget.lua",
    "Runtime/SentinelBridge.lua",
    "Runtime/CommandAudio.lua",
    "Runtime/MatchRuntime.lua",
    "UI/Theme.lua",
    "UI/IconRegistry.lua",
    "Features/CursorRing.lua",
    "UI/CopyDialog.lua",
    "UI/QuickCalls.lua",
    "UI/TeamfightCommandCard.lua",
    "UI/PersonalAssignmentCard.lua",
    "UI/CrosshairPresenter.lua",
    "UI/TargetAssistFrame.lua",
    "UI/CountdownFrame.lua",
    "UI/DebugReasonPanel.lua",
    "UI/TacticalMap.lua",
    "UI/RosterPresentation.lua",
    "UI/CombatRosterVisuals.lua",
    "UI/CombatRosterState.lua",
    "UI/CombatRoster.lua",
    "UI/HUD.lua",
    "UI/MainWindowReports.lua",
    "UI/MainWindowShell.lua",
    "UI/MainWindowLauncher.lua",
    "UI/MainWindowCommands.lua",
    "UI/MainWindowPages.lua",
    "UI/MainWindow.lua",
    "UI/AARWindow.lua",
    "UI/Options.lua",
    "Core/Diagnostics.lua",
}

local namespace = {}
local releaseOnly = rawget(_G, "KWR_TEST_RELEASE_ONLY") == true
local optionalFiles = {
    ["Core/Diagnostics.lua"] = true,
    ["Runtime/Preview.lua"] = true,
}
function ResolveAddonPath(path)
    if (rawget(_G, "KWR_TEST_ROOT") or ".") == "." then
        return path
    end
    local normalizedRoot = tostring(rawget(_G, "KWR_TEST_ROOT")):gsub("\\", "/")
    if normalizedRoot:sub(-1) == "/" then
        return normalizedRoot .. path
    end
    return normalizedRoot .. "/" .. path
end
for _, path in ipairs(files) do
    local chunk, message = loadfile(ResolveAddonPath(path))
    if not chunk and releaseOnly and optionalFiles[path] then
        message = tostring(message or "")
        if message:find("cannot open", 1, true) then
            chunk = false
        else
            assert(chunk, path .. ": " .. tostring(message))
        end
    else
        assert(chunk, path .. ": " .. tostring(message))
    end
    if chunk then
        chunk("KnomercyWarRoom", namespace)
        namespace = _G.KWR or namespace
    end
end

local bootstrap = assert(_G.KWR_BootstrapFrame, "Bootstrap frame was not created.")
assert(bootstrap.scripts.OnEvent, "Bootstrap OnEvent handler was not registered.")
bootstrap.scripts.OnEvent(bootstrap, "ADDON_LOADED", "KnomercyWarRoom")
bootstrap.scripts.OnEvent(bootstrap, "PLAYER_LOGIN")

local function smokeBootstrapExports()
    return {
        KWR = KWR,
        now = function()
            return currentTime
        end,
        setTime = function(value)
            currentTime = value
        end,
        advanceTime = function(delta)
            currentTime = currentTime + (tonumber(delta) or 0)
            return currentTime
        end,
        resetCommander = function()
            if KWR.Commander and KWR.Commander.ResetSession then
                KWR.Commander:ResetSession()
            end
        end,
    }
end

if rawget(_G, "KWR_SMOKE_BOOTSTRAP_ONLY") == true then
    return smokeBootstrapExports()
end

local previewState
do
assert(KWR.ready == true, "KWR did not become ready.")
…59717 tokens truncated…                dead = false,
                currentTargetGUID = "Enemy-Priest-V",
            },
            {
                name = "Stan",
                guid = "Player-Stan",
                role = "DAMAGER",
                spec = "Balance",
                connected = true,
                dead = false,
                currentTargetGUID = "Enemy-Warrior-Z",
            },
        },
        enemies = {
            {
                name = "Priest-V",
                shortName = "Priest-V",
                guid = "Enemy-Priest-V",
                role = "HEALER",
                spec = "Discipline",
                visible = true,
                localRange = true,
                freeCasting = true,
                dr = {
                    subdue = {
                        state = "READY",
                        confidence = "CONFIRMED",
                        remaining = 0,
                    },
                },
                source = "nameplate",
            },
            {
                name = "Priest-M",
                shortName = "Priest-M",
                guid = "Enemy-Priest-M",
                role = "HEALER",
                spec = "Holy",
                visible = true,
                localRange = true,
                freeCasting = true,
                source = "nameplate",
            },
            {
                name = "Warrior-Z",
                shortName = "Warrior-Z",
                guid = "Enemy-Warrior-Z",
                role = "DAMAGER",
                spec = "Arms",
                visible = true,
                localRange = true,
                overextended = true,
                killable = true,
                healthPercent = 32,
                source = "nameplate",
            },
        },
    }
    local plan = KWR.TeamfightCommandPlanner:Plan(teamfightSnapshot)
    local byActor = {}
    for _, assignment in ipairs(plan.assignments or {}) do
        byActor[assignment.actor] = assignment
    end
    assert(plan.active == true, "Teamfight planner did not activate for local fight replay.")
    assert(plan.boardSummary and plan.boardSummary.enemyCount == 3
        and plan.boardSummary.friendlyCount == 2,
        "BoardState summary did not preserve local fight roster counts.")
    assert(plan.optimizer and plan.optimizer.nodes <= 5000
        and plan.optimizer.problems >= 2,
        "Assignment optimizer did not expose bounded search diagnostics.")
    assert(byActor.Knomercy and byActor.Knomercy.verb == "Subdue"
        and byActor.Knomercy.target == "Priest-V",
        "Knomercy was not assigned to subdue Priest-V.")
    assert(byActor.Knomercy.drState and byActor.Knomercy.drState.state == "READY",
        "Assignment did not preserve safe DR confidence state.")
    assert(byActor.Stan and byActor.Stan.verb == "Subdue"
        and byActor.Stan.target == "Priest-M",
        "Stan was not assigned to subdue Priest-M.")
    assert(plan.killTarget and plan.killTarget.verb == "Kill"
        and plan.killTarget.target == "Warrior-Z",
        "Warrior-Z was not selected as the coordinated kill target.")
    assert(plan.killTarget.supportCoverage == 2,
        "Kill target did not account for resolved support-control assignments.")
    teamfightSnapshot.teamfight = plan
    do (function()
    local executionPacket = KWR.ExecutionCommandBuilder:Build(
        teamfightSnapshot, {}, {}, { action = "Collapse now." })
    assert(executionPacket.active == true
        and #executionPacket.controls == 2
        and executionPacket.primaryTarget.target == "Warrior-Z",
        "Synchronized execution packet lost control lanes or kill target: active="
            .. tostring(executionPacket.active) .. " controls="
            .. tostring(#executionPacket.controls) .. " target="
            .. tostring(executionPacket.primaryTarget and executionPacket.primaryTarget.target))
    assert(KWR.ExecutionCommandBuilder:PersonalFor(
        executionPacket, "Knomercy", "Player-Knomercy").target == "Priest-V",
        "Synchronized packet did not route Knomercy's personal control target.")
    assert(KWR.ExecutionCommandBuilder:PersonalFor(
        executionPacket, "Unknown", "Player-Unknown") == nil,
        "Personal routing leaked another player's assignment through fallback.")
    local repeatPacket = KWR.ExecutionCommandBuilder:Build(
        teamfightSnapshot, {}, {}, { action = "Collapse now." })
    assert(repeatPacket.signature == executionPacket.signature,
        "Equivalent execution inputs did not produce a stable signature.")
    assert(executionPacket.localFight
        and executionPacket.localFight.kill
        and executionPacket.localFight.kill.target == "Warrior-Z"
        and #executionPacket.localFight.controls == 2,
        "Local-fight packet did not preserve independent kill and healer-control truth.")

    do (function()
    local passiveSnapshot = KWR.Util:Copy(teamfightSnapshot)
    passiveSnapshot.enemies[1].freeCasting = false
    passiveSnapshot.enemies[2].freeCasting = false
    passiveSnapshot.enemies[#passiveSnapshot.enemies + 1] = {
        name = "Remote-Priest",
        shortName = "Remote-Priest",
        guid = "Enemy-Remote-Priest",
        role = "HEALER",
        spec = "Holy",
        visible = true,
        localRange = false,
        freeCasting = true,
        source = "scoreboard",
    }
    passiveSnapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(passiveSnapshot)
    local passivePacket = KWR.ExecutionCommandBuilder:Build(
        passiveSnapshot, {}, {}, { action = "Collapse now." })
    local passiveTargets = {}
    for _, control in ipairs(passivePacket.localFight.controls or {}) do
        passiveTargets[control.target] = true
    end
    assert(passiveTargets["Priest-V"] == true
        and passiveTargets["Priest-M"] == true,
        "Confirmed local healers did not retain control lanes between casts.")
    assert(passiveTargets["Remote-Priest"] ~= true,
        "Remote scoreboard healer incorrectly received a local control lane.")

    local prioritySnapshot = KWR.Util:Copy(passiveSnapshot)
    prioritySnapshot.enemies[2].freeCasting = true
    prioritySnapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(prioritySnapshot)
    local priorityPacket = KWR.ExecutionCommandBuilder:Build(
        prioritySnapshot, {}, {}, { action = "Collapse now." })
    assert(priorityPacket.localFight.controls[1]
        and priorityPacket.localFight.controls[1].target == "Priest-M",
        "Free-casting healer control did not outrank passive local healer control.")

    local recentSnapshot = KWR.Util:Copy(passiveSnapshot)
    for _, enemy in ipairs(recentSnapshot.enemies) do
        enemy.localRange = false
        enemy.localEngaged = false
        enemy.freeCasting = false
        enemy.recentLocalRange = enemy.role == "HEALER"
            and enemy.guid ~= "Enemy-Remote-Priest"
    end
    recentSnapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(recentSnapshot)
    local recentPacket = KWR.ExecutionCommandBuilder:Build(
        recentSnapshot, {}, {}, { action = "Hold." })
    assert(recentPacket.localFight.phase == "RECENT"
        and #recentPacket.localFight.controls == 2
        and recentPacket.localFight.controls[1].state == "RECENT"
        and recentPacket.localFight.kill == nil,
        "Recent healer-control truth did not persist without retaining an expired kill target: phase="
            .. tostring(recentPacket.localFight.phase)
            .. " controls=" .. tostring(#recentPacket.localFight.controls)
            .. " state=" .. tostring(recentPacket.localFight.controls[1]
                and recentPacket.localFight.controls[1].state)
            .. " kill=" .. tostring(recentPacket.localFight.kill
                and recentPacket.localFight.kill.target))

    local clearedSnapshot = KWR.Util:Copy(recentSnapshot)
    for _, enemy in ipairs(clearedSnapshot.enemies) do
        enemy.recentLocalRange = false
        enemy.recentLocalEngaged = false
    end
    clearedSnapshot.teamfight = KWR.TeamfightCommandPlanner:Plan(clearedSnapshot)
    local clearedPacket = KWR.ExecutionCommandBuilder:Build(
        clearedSnapshot, {}, {}, { action = "Hold." })
    assert(clearedPacket.localFight.phase == "CLEAR"
        and clearedPacket.localFight.kill == nil
        and #clearedPacket.localFight.controls == 0,
        "Expired local-fight actors were retained after local evidence cleared.")

    local protectedPacket = KWR.ExecutionCommandBuilder:Build(
        teamfightSnapshot, {}, {
            {
                name = "Knomercy",
                guid = "Player-Knomercy",
                role = "Anchor Defender",
                location = "Farm",
            },
        }, { action = "Collapse now." })
    local protectedJob = KWR.ExecutionCommandBuilder:PersonalFor(
        protectedPacket, "Knomercy", "Player-Knomercy")
    assert(protectedJob
        and protectedJob.role == "Anchor Defender"
        and protectedPacket.controls[1]
        and protectedPacket.controls[1].assigned == false
        and protectedPacket.controls[1].protectedAssignment == "Anchor Defender",
        "Synchronized healer control overrode a protected objective assignment.")
    end)() end

    teamfightSnapshot.executionCommand = executionPacket
    local sentinelView = KWR.SentinelBridge:BuildView("Knomercy", {
        revision = 4,
        snapshot = teamfightSnapshot,
        assignments = {},
        prediction = {},
        command = {},
        mode = "LIVE",
    })
    assert(sentinelView.assignment.source == "SYNCHRONIZED_EXECUTION"
        and sentinelView.assignment.target == "Priest-V"
        and sentinelView.watch.mode == "CONTROL"
        and sentinelView.execution.signature == executionPacket.signature,
        "SentinelBridge did not relay the synchronized personal assignment and revision: source="
            .. tostring(sentinelView.assignment.source) .. " target="
            .. tostring(sentinelView.assignment.target) .. " mode="
            .. tostring(sentinelView.watch.mode) .. " signature="
            .. tostring(sentinelView.execution.signature == executionPacket.signature))
    end)() end
    local seenExpandedType = false
    for _, problem in ipairs(plan.problems or {}) do
        if problem.type == "FREE_CASTING_HEALER" then
            seenExpandedType = true
            assert(problem.evidenceIDs and #problem.evidenceIDs > 0,
                "Expanded enemy problem did not preserve evidence IDs.")
        end
    end
    assert(seenExpandedType == true,
        "Enemy problem detector did not emit the future-proof healer problem type.")
    local signalSummary = KWR.ProblemSignalRegistry:Summary()
    assert(signalSummary.total >= 10
        and signalSummary.supported >= 8
        and signalSummary.disabled >= 1
        and signalSummary.legacyAliases >= 3
        and signalSummary.auditOK == true,
        "Problem signal registry summary drifted away from the ET-01 contract.")
    local freeCastRow = KWR.ProblemSignalRegistry:Describe("FREE_CAST_HEALER")
    assert(freeCastRow
        and freeCastRow.key == "FREE_CASTING_HEALER"
        and freeCastRow.fullCoverage == true,
        "Problem signal registry did not canonicalize the free-cast healer alias.")
    local disabledRow = KWR.ProblemSignalRegistry:Describe("RESPAWN_WAVE_ADVANTAGE")
    assert(disabledRow
        and disabledRow.enabled == false
        and disabledRow.disabledReason ~= nil,
        "Problem signal registry did not preserve disabled advanced-problem truth.")
    local signalAudit = KWR.ProblemSignalRegistry:Audit(plan.problems)
    assert(signalAudit.auditOK == true
        and signalAudit.active > 0
        and signalAudit.activeUnsupported == 0
        and signalAudit.activeDisabled == 0
        and signalAudit.activeUnknown == 0,
        "Active teamfight problems were not fully covered by the signal registry.")
    assert(plan.countdown and plan.countdown.ticks[1] == 5
        and plan.countdown.ticks[#plan.countdown.ticks] == "GO",
        "Teamfight planner did not generate the five-second countdown.")
    assert(byActor.Knomercy.debugReasons and #byActor.Knomercy.debugReasons > 0
        and byActor.Stan.debugReasons and #byActor.Stan.debugReasons > 0,
        "Teamfight planner did not produce debug reasons.")
    assert(byActor.Knomercy.targetStatus == "MATCHED"
        and byActor.Stan.targetStatus == "NOT_TARGETED",
        "Target-assist state did not distinguish matched and unmatched targets.")
    assert(KWR.TeamfightCommandCard:Build(plan).lines[2]
        == "Knomercy -> Subdue Priest-V",
        "Teamfight command card did not expose the commander job intent.")
    assert(KWR.PersonalAssignmentCard:Build(byActor.Knomercy).targetStatus == "MATCHED",
        "Personal assignment card did not preserve target-match state.")
    assert(#KWR.CrosshairPresenter:Markers(plan) == 3,
        "Crosshair presenter did not produce assignment and kill-target markers.")
    assert(KWR.TargetAssistFrame:Build(byActor.Stan).message == "Select the assigned target.",
        "Target assist presenter produced the wrong manual guidance.")
    assert(KWR.CountdownFrame:Build(plan.countdown).ticks[6] == "GO",
        "Countdown presenter did not preserve the GO tick.")
    assert(#KWR.DebugReasonPanel:Build(plan) == 3,
        "Debug reason panel did not expose all command reasons.")
    local forbidden = KWR.CommandVocabulary:ContainsForbiddenLanguage(plan.summary)
    assert(forbidden == false,
        "Teamfight command used spell-specific or automation language.")
    local unknownCard = KWR.PersonalAssignmentCard:Build(nil)
    assert(unknownCard.targetStatus == "UNKNOWN" and unknownCard.confidence == "UNKNOWN",
        "Personal assignment card did not tolerate UNKNOWN state.")

    do (function()
    local orbSnapshot = {
        context = {
            inPvP = true,
            preview = false,
            mapKey = "TEMPLE",
            mapName = "Temple of Kotmogu",
            kind = "ORB",
            phase = "LIVE",
        },
        roster = {
            { name = "Krysm", guid = "Player-Krysm", role = "DAMAGER", spec = "Frost",
                connected = true, dead = false },
            { name = "Max", guid = "Player-Max", role = "DAMAGER", spec = "Havoc",
                connected = true, dead = false },
        },
        enemies = {},
        objectives = {
            carriers = {
                { player = "Krysm", owner = "FRIENDLY", kind = "ORB",
                    objective = "Blue Orb", stacks = 510, healthPercent = 31, visible = true },
            },
        },
        teamfight = {
            displayEligible = false,
            assignments = {},
            problems = {},
            confidence = "UNKNOWN",
            countdown = KWR.CountdownState:Build(5),
        },
    }
    local orbAssignments = {
        { name = "Krysm", guid = "Player-Krysm", role = "Orb Carrier", location = "Blue Orb" },
        { name = "Max", guid = "Player-Max", role = "Carrier Hunter", location = "Enemy Carrier" },
    }
    local orbPacket = KWR.ExecutionCommandBuilder:Build(
        orbSnapshot, {}, orbAssignments, {})
    assert(orbPacket.objectiveHandoff
        and orbPacket.objectiveHandoff.actor == "Max"
        and orbPacket.objectiveHandoff.stacks == 510
        and orbPacket.trigger == "GO ON BLUE ORB DROP",
        "High-risk orb did not produce a qualified synchronized handoff.")
    assert(KWR.ExecutionCommandBuilder:PersonalFor(
        orbPacket, "Max", "Player-Max").shortRole == "PICKUP",
        "Sentinel personal routing did not prioritize the orb handoff.")
    assert(orbPacket.spokenText:find("Max, prepare Blue pickup", 1, true),
        "Visual orb handoff and canonical spoken call drifted.")

    local threeLaneSnapshot = KWR.Util:Copy(teamfightSnapshot)
    threeLaneSnapshot.roster[#threeLaneSnapshot.roster + 1] = {
        name = "Rogue-One", guid = "Player-Rogue-One", role = "DAMAGER",
        spec = "Assassination", connected = true, dead = false,
    }
    threeLaneSnapshot.teamfight = KWR.Util:Copy(plan)
    threeLaneSnapshot.teamfight.problems[#threeLaneSnapshot.teamfight.problems + 1] = {
        type = "CASTER_HEALER_SUPPORT",
        enemy = { name = "Priest-B", shortName = "Priest-B", guid = "Enemy-Priest-B",
            role = "HEALER", spec = "Holy" },
    }
    threeLaneSnapshot.teamfight.assignments[#threeLaneSnapshot.teamfight.assignments + 1] = {
        actor = "Rogue-One", actorGUID = "Player-Rogue-One", verb = "Subdue",
        target = "Priest-B", targetGUID = "Enemy-Priest-B", confidence = "HIGH",
    }
    local threeLanePacket = KWR.ExecutionCommandBuilder:Build(
        threeLaneSnapshot, {}, {}, {})
    assert(#threeLanePacket.controls == 3
        and threeLanePacket.controls[3].actor == "Rogue-One",
        "Synchronized command packet did not preserve three healer-control lanes.")

    local oldAvailable = KWR.SafeSpeechAdapter.IsAvailable
    local oldSpeak = KWR.SafeSpeechAdapter.Speak
    local oldStop = KWR.SafeSpeechAdapter.Stop
    local spoken = 0
    KWR.SafeSpeechAdapter.IsAvailable = function() return true end
    KWR.SafeSpeechAdapter.Speak = function() spoken = spoken + 1 return true end
    KWR.SafeSpeechAdapter.Stop = function() end
    KWR.db.profile.hud.audio.enabled = true
    KWR.CommandAudio.lastSignature = nil
    KWR.CommandAudio.lastSpokenAt = -100
    local audioPacket = KWR.ExecutionCommandBuilder:Build(
        teamfightSnapshot, {}, {}, { action = "Collapse now." })
    KWR.CommandAudio:SpeakPacket(audioPacket, false)
    KWR.CommandAudio:SpeakPacket(audioPacket, false)
    assert(spoken == 1, "Unchanged synchronized command signature replayed audio.")

    local function silentCopy(suffix)
        return {
            active = audioPacket.active,
            authoritative = audioPacket.authoritative,
            audible = audioPacket.audible,
            confidence = audioPacket.confidence,
            signature = audioPacket.signature .. suffix,
            spokenText = audioPacket.spokenText,
        }
    end
    local silentPacket = silentCopy(":preview")
    silentPacket.authoritative = false
    KWR.CommandAudio:SpeakPacket(silentPacket, true)
    assert(spoken == 1, "Preview synchronized command produced audio.")

    silentPacket = silentCopy(":low")
    silentPacket.confidence = "LOW"
    silentPacket.audible = false
    KWR.CommandAudio:SpeakPacket(silentPacket, true)
    assert(spoken == 1, "Low-confidence synchronized command produced audio.")

    KWR.db.profile.hud.audio.enabled = false
    silentPacket = silentCopy(":disabled")
    KWR.CommandAudio:SpeakPacket(silentPacket, true)
    assert(spoken == 1, "Disabled synchronized command audio still spoke.")

    KWR.db.profile.hud.audio.enabled = true
    KWR.SafeSpeechAdapter.IsAvailable = function() return false end
    silentPacket.signature = audioPacket.signature .. ":unavailable"
    KWR.CommandAudio:SpeakPacket(silentPacket, true)
    assert(spoken == 1, "Unavailable text-to-speech did not fail silent.")

    KWR.SafeSpeechAdapter.IsAvailable = oldAvailable
    KWR.SafeSpeechAdapter.Speak = oldSpeak
    KWR.SafeSpeechAdapter.Stop = oldStop
    end)() end
end
end

local result = { passed = 0, failed = 0 }
if KWR.Diagnostics and type(KWR.Diagnostics.Run) == "function" then
    result = KWR.Diagnostics:Run()
    if result.failed > 0 then
        local report = KWR.Diagnostics:Report()
        error(report)
    end
end

print("KWR_SMOKE_PASS checks=" .. tostring(result.passed))