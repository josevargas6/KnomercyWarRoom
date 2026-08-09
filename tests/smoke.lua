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
    elseif key == "SetFrameStrata" then
        return function(self, strata) self.frameStrata = strata end
    elseif key == "GetFrameStrata" then
        return function(self) return self.frameStrata end
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
mockParty = false
mockPartyLeaderAlias = false
function IsInRaid() return mockRaid end
function IsInGroup() return mockRaid or mockParty end
function GetNumGroupMembers() return mockRaid and 3 or 1 end
function GetNumSubgroupMembers() return mockParty and 2 or 0 end
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
        or (mockParty and unit and unit:find("^party%d+$") ~= nil)
        or mockLiveEnemy(unit) ~= nil
end
function UnitName(unit)
    if unit == "player" then return "TestPlayer", "TestRealm" end
    if mockRaid and unit and unit:find("^raid%d+$") then
        local index = tonumber(unit:match("%d+"))
        return mockRaidTokensStable and mockRaidNames[index] or "Alpha", "TestRealm"
    end
    if mockParty and unit == "party1" and mockPartyLeaderAlias then
        return "TestPlayer-LoadingAlias", "TestRealm"
    end
    if mockParty and unit and unit:find("^party%d+$") then
        return "Party" .. tostring(unit:match("%d+")), "TestRealm"
    end
    local enemy = mockLiveEnemy(unit)
    if enemy then return enemy.name, enemy.realm end
end
function UnitClass(unit)
    if unit == "player" then return "Warrior", "WARRIOR", 1 end
    if mockRaid and unit and unit:find("^raid%d+$") then
        return "Warrior", "WARRIOR", 1
    end
    if mockParty and unit and unit:find("^party%d+$") then
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
function UnitIsUnit(left, right)
    if left == right then return true end
    return mockParty and mockPartyLeaderAlias
        and left == "party1" and right == "player"
end
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
    if mockParty and unit == "party1" and mockPartyLeaderAlias then
        return "Player-1-SELF-TRANSIENT"
    end
    if mockParty and unit and unit:find("^party%d+$") then
        return "Player-1-PARTY" .. tostring(unit:match("%d+"))
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
    "Runtime/SafetyMonitor.lua",
    "Runtime/AAR.lua",
    "Runtime/Verification.lua",
    "Runtime/MemoryBudget.lua",
    "Runtime/SentinelBridge.lua",
    "Runtime/CommandAudio.lua",
    "Runtime/MatchRuntime.lua",
    "UI/Theme.lua",
    "UI/IconRegistry.lua",
    "UI/LayoutCoordinator.lua",
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
assert(KWR.SafetyMonitor and KWR.SafetyMonitor.frame
    and KWR.SafetyMonitor.frame:IsEventRegistered("ADDON_ACTION_BLOCKED")
    and KWR.SafetyMonitor.frame:IsEventRegistered("ADDON_ACTION_FORBIDDEN"),
    "Retail safety monitor did not register both restricted-action events.")
KWR.SafetyMonitor.__testBefore = KWR.SafetyMonitor:Snapshot()
KWR.SafetyMonitor.frame.scripts.OnEvent(
    KWR.SafetyMonitor.frame, "ADDON_ACTION_BLOCKED", "tainted", "TargetUnit")
KWR.SafetyMonitor.__testAfter = KWR.SafetyMonitor:Snapshot()
assert(KWR.SafetyMonitor.__testAfter.blocked == KWR.SafetyMonitor.__testBefore.blocked + 1
    and KWR.SafetyMonitor.__testAfter.total == KWR.SafetyMonitor.__testBefore.total + 1
    and KWR.SafetyMonitor.__testAfter.recent[#KWR.SafetyMonitor.__testAfter.recent].action == "TargetUnit",
    "Retail safety monitor did not capture bounded blocked-action evidence.")
KWR.SafetyMonitor.__testBefore = nil
KWR.SafetyMonitor.__testAfter = nil

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
assert(KWR.db.profile.main.page == "TACTICAL", "Legacy command page did not migrate.")
do
    local savedDb = KWR.Util:Copy(KWR_DB)
    KWR_DB = {
        schemaVersion = 60001,
        profile = {
            hud = "bad",
            main = {
                page = true,
                x = "bad",
            },
            cursor = {
                enabled = "bad",
                reticleEnabled = "bad",
                battlefieldOrbs = "bad",
            },
            combatRoster = {
                panes = {
                    team = "bad",
                },
            },
            presentation = "bad",
            aar = {
                enabled = "bad",
                autoOpen = "bad",
            },
            showLoadMessage = "bad",
        },
        journal = {
            history = {
                "bad-row",
                { id = "kept-row", commands = "bad", events = "bad" },
            },
            interrupted = "bad",
        },
        learning = "bad",
        encounters = {
            players = "bad",
        },
        assignmentOverrides = "bad",
        opponentModels = "bad",
    }
    KWR:InitializeDatabase()
    assert(type(KWR.db.profile.hud) == "table"
        and KWR.db.profile.hud.point == "CENTER"
        and KWR.db.profile.main.page == "TACTICAL"
        and KWR.db.profile.main.x == 0
        and KWR.db.profile.cursor.enabled == false
        and KWR.db.profile.cursor.reticleEnabled == true
        and KWR.db.profile.cursor.battlefieldOrbs == true
        and KWR.db.profile.combatRoster.layoutVersion == 3
        and KWR.db.profile.combatRoster.panes == nil
        and KWR.db.profile.combatRoster.splitToolbar == nil
        and KWR.db.profile.combatRoster.solo == nil
        and type(KWR.db.profile.combatRoster.teamMini) == "table"
        and type(KWR.db.profile.combatRoster.enemyMini) == "table"
        and type(KWR.db.profile.presentation) == "table"
        and KWR.db.profile.aar.enabled == true
        and KWR.db.profile.aar.autoOpen == true
        and KWR.db.profile.showLoadMessage == true
        and type(KWR.db.journal.history) == "table"
        and #KWR.db.journal.history == 2
        and KWR.db.journal.interrupted == nil
        and type(KWR.db.learning.plans) == "table"
        and type(KWR.db.encounters.players) == "table"
        and type(KWR.db.assignmentOverrides.players) == "table"
        and type(KWR.db.opponentModels.players) == "table",
        "SavedVariables type normalization did not recover malformed fields safely.")
    KWR_DB = savedDb
    KWR:InitializeDatabase()
end
do
    local savedDb = KWR.Util:Copy(KWR_DB)
    KWR_DB = {
        schemaVersion = 60128,
        profile = {
            combatRoster = {
                mode = "BOTH",
                panes = {
                    team = {
                        point = "TOPLEFT",
                        relativePoint = "TOPLEFT",
                        x = 246,
                        y = -118,
                        anchorSpace = "SCREEN",
                    },
                },
            },
        },
    }
    KWR:InitializeDatabase()
    assert(KWR.db.profile.combatRoster.layoutVersion == 3
        and KWR.db.profile.combatRoster.teamMini.point == "TOPLEFT"
        and KWR.db.profile.combatRoster.teamMini.relativePoint == "TOPLEFT"
        and KWR.db.profile.combatRoster.teamMini.x == 76
        and KWR.db.profile.combatRoster.teamMini.y == -118
        and KWR.db.profile.combatRoster.enemyMini.point == "TOPLEFT"
        and KWR.db.profile.combatRoster.enemyMini.relativePoint == "TOPLEFT"
        and KWR.db.profile.combatRoster.enemyMini.x == 416
        and KWR.db.profile.combatRoster.enemyMini.y == -118
        and KWR.db.profile.combatRoster.panes == nil,
        "Legacy split-roster position did not migrate to separate team and enemy anchors: "
            .. tostring(KWR.db.profile.combatRoster.layoutVersion) .. "/"
            .. tostring(KWR.db.profile.combatRoster.teamMini.point) .. "/"
            .. tostring(KWR.db.profile.combatRoster.teamMini.relativePoint) .. "/"
            .. tostring(KWR.db.profile.combatRoster.teamMini.x) .. "/"
            .. tostring(KWR.db.profile.combatRoster.teamMini.y) .. "/"
            .. tostring(KWR.db.profile.combatRoster.panes))
    KWR_DB = savedDb
    KWR:InitializeDatabase()
end
do
    local savedDb = KWR.Util:Copy(KWR_DB)
    KWR_DB = {
        schemaVersion = KWR.schemaVersion + 50,
        profile = {
            showLoadMessage = false,
            hud = {
                point = "CENTER",
                x = -123,
                y = 45,
            },
        },
        journal = {
            history = {
                { id = "future-entry" },
            },
        },
    }
    KWR:InitializeDatabase()
    KWR.db.profile.showLoadMessage = true
    KWR.db.journal.history[1].id = "mutated-working-copy"
    assert(KWR.persistenceDisabled == true
        and KWR.compatibilityStatus
        and KWR.compatibilityStatus.futureSchema == true
        and KWR.compatibilityStatus.storedSchemaVersion == (KWR.schemaVersion + 50)
        and KWR_DB.schemaVersion == (KWR.schemaVersion + 50)
        and KWR_DB.profile.showLoadMessage == false
        and KWR_DB.journal.history[1].id == "future-entry",
        "Future-schema compatibility mode did not preserve persisted SavedVariables from downgrade or mutation.")
    KWR_DB = savedDb
    KWR:InitializeDatabase()
end

assert(KWR.CompThreats:Select({ id = "BUNKER" }, nil, "FLAG").id == "CARRIER_ESCORT",
    "Comp threat selection did not remap bunker pressure for flag maps.")
assert(KWR.EnemyDefenseModels:Select({ context = { kind = "NODE" } }, { id = "ROTATION" }, "OPENING").id
    == "ROTATIONAL_TRAP",
    "Enemy defense model selection did not identify the rotational opening shell.")
assert(KWR.OpenerDoctrine:Select("ARATHI", {
    ourComposition = { id = "BALANCED" },
    enemyComposition = { id = "BUNKER" },
    compThreat = { id = "BUNKER_DEFENSE" },
    enemyDefenseModel = { id = "HEALER_BUNKER" },
}).branch == "ANTI_BUNKER",
    "Opener doctrine did not select the anti-bunker branch.")
assert(KWR.RecoveryDoctrine:Select("ARATHI", {
    arrivalAfterResolution = true,
    objectiveContestable = false,
}).branch == "ABANDON",
    "Recovery doctrine did not select the abandon branch.")
assert(KWR.EndgameDoctrine:Select("ARATHI", {
    projectedWin = true,
    delayWins = true,
}).branch == "STALL",
    "Endgame doctrine did not select the stall branch.")
assert(KWR.db.profile.hud.point == "CENTER" and KWR.db.profile.hud.x == -440,
    "Legacy HUD placement did not migrate.")
assert(KWR.Store:Get().command, "Command state was not published.")
assert(KWR.Store:Get().snapshot.formation.openSlots == 9, "Formation advisor did not count open slots.")
assert(KWR.Store:Get().command.status == "FORMING", "World mode did not publish formation guidance.")
do
    local calls = 0
    local owner = {}
    KWR.Store:SubscribeFiltered(owner, function()
        calls = calls + 1
    end, function(_, state)
        return state and state.command and state.command.status
    end)
    local baseline = KWR.Store:Get()
    KWR.Store:Publish(baseline.snapshot, baseline.prediction, baseline.assignments, baseline.command, baseline.diagnostics)
    KWR.Store:Publish(baseline.snapshot, baseline.prediction, baseline.assignments, baseline.command, baseline.diagnostics)
    local updatedCommand = KWR.Util:Copy(baseline.command)
    updatedCommand.status = "FILTER_TEST"
    KWR.Store:Publish(baseline.snapshot, baseline.prediction, baseline.assignments, updatedCommand, baseline.diagnostics)
    KWR.Store:Unsubscribe(owner)
    assert(calls == 2, "Filtered Store subscription did not suppress unchanged view tokens.")
end
do
    local calls = 0
    local owner = {}
    KWR.Store:SubscribeFiltered(owner, function()
        calls = calls + 1
    end, function(_, state)
        return state and state.snapshot and state.snapshot.context
            and state.snapshot.context.mapName
    end)
    local baseline = KWR.Store:Get()
    local updatedSnapshot = KWR.Util:Copy(baseline.snapshot)
    updatedSnapshot.context = KWR.Util:Copy(updatedSnapshot.context or {})
    updatedSnapshot.context.mapName = "Nested Store Change"
    KWR.Store:Publish(updatedSnapshot, baseline.prediction,
        baseline.assignments, baseline.command, baseline.diagnostics)
    KWR.Store:Publish(updatedSnapshot, baseline.prediction,
        baseline.assignments, baseline.command, baseline.diagnostics)
    KWR.Store:Unsubscribe(owner)
    assert(calls == 1,
        "Store reconciliation did not detect an exact nested snapshot change or suppressed it incorrectly.")
end
do
    KWR.ObjectiveIntel:Reset("WSG:true")
    KWR.ObjectiveIntel.carriers = {
        ["Alliance Flag"] = {
            objective = "Alliance Flag",
            kind = "FLAG",
            color = "Alliance",
            player = "EnemyCarrier",
            playerKey = "enemycarrier",
        },
        ["Horde Flag"] = {
            objective = "Horde Flag",
            kind = "FLAG",
            color = "Horde",
            player = "FriendlyCarrier",
            playerKey = "friendlycarrier",
        },
    }
    KWR.ObjectiveIntel:ObserveMessage("The Alliance flag was returned to its base!", "WSG")
    assert(KWR.ObjectiveIntel.carriers["Alliance Flag"] == nil
        and KWR.ObjectiveIntel.carriers["Horde Flag"] ~= nil,
        "ObjectiveIntel returned-message handling cleared unrelated flag carriers.")
    KWR.ObjectiveIntel:ObserveMessage("Verite captured the Horde flag!", "WSG")
    assert(KWR.ObjectiveIntel.carriers["Horde Flag"] == nil,
        "ObjectiveIntel capture-message handling did not clear the captured flag carrier.")
    KWR.ObjectiveIntel.carriers = {
        ["Alliance Flag"] = {
            objective = "Alliance Flag",
            kind = "FLAG",
            color = "Alliance",
            player = "EnemyCarrier",
            playerKey = "enemycarrier",
        },
        ["Horde Flag"] = {
            objective = "Horde Flag",
            kind = "FLAG",
            color = "Horde",
            player = "FriendlyCarrier",
            playerKey = "friendlycarrier",
        },
    }
    KWR.ObjectiveIntel:ObserveMessage("The flags are now placed at their bases.", "WSG")
    assert(next(KWR.ObjectiveIntel.carriers) == nil,
        "ObjectiveIntel global reset message did not clear all flag carriers.")
end
do
    local savedLocale = mockLocale
    mockLocale = "deDE"
    KWR.ObjectiveIntel:Reset("WSG:true")
    KWR.ObjectiveIntel:ObserveMessage("Verite hat die Flagge der Horde aufgenommen!", "WSG")
    assert(KWR.ObjectiveIntel.carriers["Horde Flag"]
        and KWR.ObjectiveIntel.carriers["Horde Flag"].player == "Verite",
        "ObjectiveIntel did not resolve the reviewed German flag pickup grammar.")
    KWR.ObjectiveIntel:ObserveMessage("Verite hat die Flagge der Horde erobert!", "WSG")
    assert(KWR.ObjectiveIntel.carriers["Horde Flag"] == nil,
        "ObjectiveIntel did not resolve the reviewed German flag capture grammar.")
    local allianceContext = { team = { faction = "Alliance" } }
    local hordeContext = { team = { faction = "Horde" } }
    assert(KWR.ObjectiveIntel:CanonicalCommandTarget(
        "WSG", "Alliance Flag has been picked up", allianceContext) == "Our FC",
        "Alliance assigned-side flag pickup did not normalize to Our FC.")
    assert(KWR.ObjectiveIntel:CanonicalCommandTarget(
        "WSG", "Alliance Flag has been picked up", hordeContext) == "Enemy FC",
        "Horde assigned-side flag pickup did not normalize Alliance as enemy.")
    assert(KWR.ObjectiveIntel:CanonicalCommandTarget(
        "WSG", "Horde Flag was returned to its base", allianceContext) == "Enemy Flag Room",
        "Returned enemy flag did not retain its canonical affected flag target.")
    assert(KWR.ObjectiveIntel:CanonicalCommandTarget(
        "WSG", "Alliance flag has been picked up", allianceContext) ~=
        "Alliance Flag has been picked up",
        "Raw flag prose crossed the canonical action-target boundary.")
    assert(KWR.ObjectiveIntel:CanonicalCommandTarget(
        "WSG", "unrecognized localized widget label", allianceContext) == "VERIFY",
        "Unknown flag target did not fall back to VERIFY.")
    KWR.ObjectiveIntel:ObserveMessage("Priest hat den Hof angegriffen!", "ARATHI")
    assert(KWR.ObjectiveIntel.timers["Hof"]
        and KWR.ObjectiveIntel.timers["Hof"].assaulter == "Priest",
        "ObjectiveIntel did not resolve the reviewed German assault grammar.")
    mockLocale = savedLocale
end
do
    local savedHistory = KWR.Util:Copy(KWR.db.journal.history)
    local savedInterrupted = KWR.Util:Copy(KWR.db.journal.interrupted)
    local savedLastCompleted = KWR.Util:Copy(KWR.AAR.lastCompleted)
    local savedActive = KWR.Util:Copy(KWR.AAR.active)
    local syntheticState = {
        snapshot = {
            context = {
                mapKey = "ARATHI",
                mapName = "Arathi Basin",
                team = { faction = "Alliance", side = 1 },
                phase = "ACTIVE",
                matchComplete = false,
            },
            score = { friendly = 400, enemy = 350, max = 1500, source = "ui_widget" },
            objectives = { friendly = 2, enemy = 1, rows = {}, events = {} },
            roster = {},
            enemies = {},
            reporter = {},
            combat = {},
        },
        assignments = {},
        command = {
            signature = "synthetic-interruption",
            objectiveTarget = "Blacksmith",
            who = "Synthetic Player",
            action = "Rotate Blacksmith",
            confidence = "HIGH",
        },
        prediction = {},
    }
    KWR.db.journal.history = {}
    KWR.db.journal.interrupted = nil
    KWR.AAR.active = nil
    KWR.AAR.lastCompleted = nil
    KWR.AAR:Record(syntheticState)
    assert(KWR.AAR.active ~= nil and KWR.db.journal.interrupted ~= nil,
        "Active AAR checkpoint did not persist during an in-progress match.")
    assert(KWR.AAR:CommitInterrupted("Synthetic reload.") == true,
        "AAR interruption commit failed.")
    assert(#KWR.db.journal.history == 1
        and KWR.db.journal.history[1].result == "INTERRUPTED"
        and KWR.db.journal.history[1].partial == true
        and KWR.db.journal.history[1].interruptionReason == "Synthetic reload."
        and KWR.db.journal.interrupted == nil
        and KWR.AAR.active == nil,
        "AAR interruption policy did not persist a single explicit interrupted record.")
    KWR.db.journal.history = savedHistory
    KWR.db.journal.interrupted = savedInterrupted
    KWR.AAR.lastCompleted = savedLastCompleted
    KWR.AAR.active = savedActive
end
do
    local savedHistory = KWR.Util:Copy(KWR.db.journal.history)
    local savedInterrupted = KWR.Util:Copy(KWR.db.journal.interrupted)
    local savedActive = KWR.Util:Copy(KWR.AAR.active)
    local savedLastCompleted = KWR.Util:Copy(KWR.AAR.lastCompleted)
    local savedListeners = KWR.Store.listeners[KWR.AAR]
    KWR.db.journal.history = {}
    KWR.db.journal.interrupted = nil
    KWR.AAR.lastCompleted = nil
    KWR.AAR.active = {
        id = "disable-interrupt",
        partial = true,
        result = "INTERRUPTED",
        commands = {},
        events = {},
        friendlyTeam = {},
        enemyTeam = {},
        enemyThreats = {},
        playerEvidence = {},
        objectiveTimeline = {},
        planUsage = {},
        startedAt = currentTime - 30,
        endedAt = currentTime,
        mapKey = "WSG",
        mapName = "Warsong Gulch",
        team = { faction = "Alliance", side = 1 },
        finalCommand = { action = "Hold tunnel" },
    }
    KWR.Store.listeners[KWR.AAR] = { callback = KWR.AAR.Update, selector = nil, lastToken = nil }
    KWR.AAR:OnDisable()
    assert(#KWR.db.journal.history == 1
        and KWR.db.journal.history[1].result == "INTERRUPTED"
        and KWR.db.journal.history[1].interruptionReason
            == "Reload, relog, or addon disable interrupted the live match journal."
        and KWR.AAR.active == nil
        and KWR.Store.listeners[KWR.AAR] == nil,
        "AAR OnDisable did not commit one interrupted record and unsubscribe cleanly.")
    KWR.db.journal.history = savedHistory
    KWR.db.journal.interrupted = savedInterrupted
    KWR.AAR.active = savedActive
    KWR.AAR.lastCompleted = savedLastCompleted
    KWR.Store.listeners[KWR.AAR] = savedListeners
end
do
    local active = { friendlyTeam = {}, enemyTeam = {} }
    KWR.AAR:CaptureTeams(active, {
        roster = {
            { name = "Identity-TestRealm", spec = "Unknown", role = "DAMAGER" },
        },
        enemies = {
            {
                key = "Enemy-1-A",
                guid = "Enemy-1-A",
                name = "Enemy-TestRealm",
                shortName = "Enemy",
                classFile = "ROGUE",
                role = "DAMAGER",
                location = "Farm",
                visible = true,
                lastSeenAt = KWR.Util:Now(),
            },
        },
    })
    KWR.AAR:CaptureTeams(active, {
        roster = {
            {
                guid = "Player-1-IDENTITY",
                name = "Identity-TestRealm",
                spec = "Unholy",
                role = "DAMAGER",
                class = "Death Knight",
            },
        },
        enemies = {},
    })
    local count, stored = 0, nil
    for _, player in pairs(active.friendlyTeam) do
        count = count + 1
        stored = player
    end
    assert(count == 1 and stored.guid == "Player-1-IDENTITY"
        and stored.spec == "Unholy",
        "AAR identity promotion duplicated a name-only player when GUID truth arrived.")
end
do
    local savedHistory = KWR.Util:Copy(KWR.db.journal.history)
    local savedInterrupted = KWR.Util:Copy(KWR.db.journal.interrupted)
    local savedLastCompleted = KWR.Util:Copy(KWR.AAR.lastCompleted)
    local savedActive = KWR.Util:Copy(KWR.AAR.active)
    local live = {
        snapshot = {
            context = {
                inPvP = true,
                preview = false,
                mapKey = "GILNEAS",
                mapName = "Battle for Gilneas",
                phase = "ACTIVE",
                team = { faction = "Alliance", side = 1 },
                matchComplete = false,
            },
            score = { friendly = 100, enemy = 90, max = 1500, source = "ui_widget" },
            objectives = { friendly = 1, enemy = 2, rows = {}, events = {} },
            roster = {},
            enemies = {},
            reporter = {},
            combat = {},
            assignmentIntegrity = {},
        },
        assignments = {},
        command = { signature = "aar-complete-regression", action = "Hold Lighthouse" },
        prediction = {},
    }
    KWR.db.journal.history = {}
    KWR.db.journal.interrupted = nil
    KWR.AAR.active = nil
    KWR.AAR.lastCompleted = nil
    KWR.AAR:Update(live, nil)
    local complete = KWR.Util:Copy(live)
    complete.snapshot.context.matchComplete = true
    complete.snapshot.context.phase = "COMPLETE"
    complete.snapshot.score.friendly = 1120
    complete.snapshot.score.enemy = 1500
    KWR.AAR:Update(complete, live)
    assert(KWR.AAR.active == nil and #KWR.db.journal.history == 1
        and KWR.db.journal.history[1].result == "DEFEAT",
        "AAR did not finalize the current match on PVP_MATCH_COMPLETE truth.")
    KWR.db.journal.history = savedHistory
    KWR.db.journal.interrupted = savedInterrupted
    KWR.AAR.lastCompleted = savedLastCompleted
    KWR.AAR.active = savedActive
end
do
    local savedTruth = KWR.Util:Copy(KWR.MatchRuntime.postMatchTruth)
    local savedComplete = KWR.MatchRuntime.matchComplete
    local fullRoster = {}
    for index = 1, 8 do
        fullRoster[index] = {
            guid = "PostMatch-" .. index,
            name = "PostMatch" .. index .. "-TestRealm",
        }
    end
    local qualified = {
        context = {
            inPvP = true,
            preview = false,
            sessionKey = "post-match-regression",
            isBlitz = true,
            blitzSource = "scoreboard_8v8",
            team = { faction = "Alliance", side = 1, source = "scoreboard_self" },
        },
        score = { source = "ui_widget", friendly = 1120, enemy = 1500 },
        objectives = { source = "ui_widget", rows = {} },
        roster = fullRoster,
        enemies = {
            {
                key = "Enemy-1-A",
                guid = "Enemy-1-A",
                name = "Enemy-TestRealm",
                shortName = "Enemy",
                classFile = "ROGUE",
                role = "DAMAGER",
                location = "Farm",
                visible = true,
                lastSeenAt = KWR.Util:Now(),
            },
        },
    }
    KWR.MatchRuntime.postMatchTruth = nil
    KWR.MatchRuntime.matchComplete = false
    KWR.MatchRuntime:RememberQualifiedTruth(qualified)
    KWR.MatchRuntime.matchComplete = true
    local collapsed = KWR.Util:Copy(qualified)
    collapsed.context.isBlitz = false
    collapsed.context.blitzSource = "unconfirmed"
    collapsed.roster = { fullRoster[1] }
    collapsed = KWR.MatchRuntime:ApplyMatchCompleteFallback(collapsed)
    assert(#collapsed.roster == 8 and collapsed.context.isBlitz == true
        and collapsed.context.rosterPostMatchFrozen == true,
        "Post-match fallback did not preserve the last complete roster and Blitz truth.")
    KWR.MatchRuntime.postMatchTruth = savedTruth
    KWR.MatchRuntime.matchComplete = savedComplete
end
do
    local savedDb = KWR.Util:Copy(KWR_DB)
    local matrix = {
        {
            version = 60001,
            page = "COMMAND",
            expectPage = "TACTICAL",
            hud = { point = "TOP", relativePoint = "TOP", x = 0, y = -180 },
            expectHud = { point = "CENTER", relativePoint = "CENTER", x = -440, y = 0 },
        },
        {
            version = 60002,
            page = "TACTICAL",
            expectPage = "TACTICAL",
            hud = { point = "BOTTOM", relativePoint = "BOTTOM", x = 11, y = 22 },
            expectHud = { point = "BOTTOM", relativePoint = "BOTTOM", x = 11, y = 22 },
        },
        {
            version = KWR.schemaVersion - 1,
            page = "TACTICAL",
            expectPage = "TACTICAL",
            hud = { point = "LEFT", relativePoint = "LEFT", x = 33, y = 44 },
            expectHud = { point = "LEFT", relativePoint = "LEFT", x = 33, y = 44 },
        },
    }
    for _, case in ipairs(matrix) do
        KWR_DB = {
            schemaVersion = case.version,
            profile = {
                main = { page = case.page },
                hud = KWR.Util:Copy(case.hud),
            },
        }
        KWR:InitializeDatabase()
        assert(KWR.db.profile.main.page == case.expectPage
            and KWR.db.profile.hud.point == case.expectHud.point
            and KWR.db.profile.hud.relativePoint == case.expectHud.relativePoint
            and KWR.db.profile.hud.x == case.expectHud.x
            and KWR.db.profile.hud.y == case.expectHud.y,
            "SavedVariables schema matrix did not preserve the reviewed migration boundary at "
                .. tostring(case.version) .. ".")
    end
    KWR_DB = savedDb
    KWR:InitializeDatabase()
end
assert(KWR.MemoryBudget:PressureLevel(24.9) == "OK", "Memory budget did not classify under-cap memory correctly.")
assert(KWR.MemoryBudget:PressureLevel(25.1) == "SOFT", "Memory budget did not classify soft pressure correctly.")
assert(KWR.MemoryBudget:PressureLevel(28.1) == "WARNING", "Memory budget did not classify warning pressure correctly.")
assert(KWR.MemoryBudget:PressureLevel(32.1) == "FAIL", "Memory budget did not classify fail pressure correctly.")
do
    local calls = 0
    local originalMeasureMB = KWR.MemoryBudget.MeasureMB
    local originalTrim = KWR.MemoryBudget.Trim
    KWR.MemoryBudget.MeasureMB = function()
        calls = calls + 1
        return 26
    end
    KWR.MemoryBudget.Trim = function() end
    KWR.MemoryBudget:Update({
        revision = 20,
        snapshot = { context = { inPvP = false } },
    }, {
        revision = 19,
        snapshot = { context = { inPvP = false } },
    })
    KWR.MemoryBudget.MeasureMB = originalMeasureMB
    KWR.MemoryBudget.Trim = originalTrim
    assert(calls == 1,
        "MemoryBudget did not measure against the current Store state callback payload.")
end
assert(KWR.MatchRuntime.frame:IsEventRegistered("UPDATE_UI_WIDGET"),
    "Active events were not registered during initialization.")
local worldRefreshes = KWR.MatchRuntime.diagnostics.refreshes
KWR.MatchRuntime:HandleEvent("UPDATE_UI_WIDGET")
assert(KWR.MatchRuntime.diagnostics.refreshes == worldRefreshes,
    "Inactive runtime processed a battleground-only event.")

mockRaid = true
mockRaidNames = { "Alpha", nil, "Charlie" }
assert(KWR.MatchRuntime:ForceRefresh("smoke-raid-missing-slot"),
    "Partially hydrated raid capture failed.")
local missingSlotRoster = KWR.Store:Get().snapshot.roster
local missingSlotHydration = KWR.Store:Get().snapshot.context.rosterHydration
local missingSlotNames = {}
for _, player in ipairs(missingSlotRoster) do
    missingSlotNames[player.shortName] = true
end
assert(#missingSlotRoster == 2
    and missingSlotNames.Alpha and missingSlotNames.Charlie
    and not missingSlotNames.Bravo
    and missingSlotHydration.expected == 3,
    "Missing raid-roster identity was filled with a transient player unit.")

mockRaidNames = { "Alpha-OtherRealm", "Bravo", "Charlie" }
assert(KWR.MatchRuntime:ForceRefresh("smoke-raid-realm-mismatch"),
    "Realm-mismatched raid capture failed.")
for _, player in ipairs(KWR.Store:Get().snapshot.roster) do
    assert(player.unit == nil and player.guid == "",
        "Realm-mismatched raid identity retained unit-bound GUID or targeting authority.")
end

mockRaidNames = { "Alpha", "Bravo", "Charlie" }
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
    if player.unit == nil then
        assert(player.guid == "",
            "Unstable raid identity retained a GUID from another unit token.")
    end
end
assert(resolvingBindings == 1,
    "Mismatched raid identities retained unsafe loading-screen bindings.")
do
    local normalized = KWR.TeamResolver:NormalizePublishedRoster({
        { name = "Alpha-TestRealm", guid = "Player-1-Alpha", role = "DAMAGER" },
        { name = "Alpha-OtherRealm", guid = "Player-2-Alpha", role = "HEALER" },
    })
    assert(#normalized == 2
        and normalized[1].guid ~= normalized[2].guid,
        "Combat roster normalization collapsed distinct same-short-name teammates.")
    local transitional = KWR.TeamResolver:NormalizePublishedRoster({
        {
            key = "TRANSITIONAL-OLD",
            guid = "Player-1-Transition",
            name = "Transition-TestRealm",
            role = "DAMAGER",
        },
        {
            key = "TRANSITIONAL-CURRENT",
            guid = "Player-1-Transition",
            name = "Transition-TestRealm",
            unit = "raid1",
            role = "DAMAGER",
        },
    })
    assert(#transitional == 1 and transitional[1].unit == "raid1",
        "Combat roster retained duplicate transitional identities for one teammate.")
    local shortOnly = KWR.TeamResolver:NormalizePublishedRoster({
        { key = "SHORT-OLD", guid = "SHORT-GUID-OLD", shortName = "Verite",
            spec = "Unholy", role = "DAMAGER" },
        { key = "SHORT-CURRENT", guid = "SHORT-GUID-CURRENT", shortName = "Verite",
            unit = "raid10", spec = "Unholy", role = "DAMAGER" },
    })
    assert(#shortOnly == 1 and shortOnly[1].unit == "raid10",
        "Combat roster retained duplicate short-name-only records for one teammate.")
    local transientProfile = KWR.TeamResolver:NormalizePublishedRoster({
        { name = "Verite-OldRealm", guid = "STALE-VERITE-1", shortName = "Verite",
            role = "DAMAGER", spec = "Frost", classFile = "MAGE", healthPercent = 52 },
        { name = "Verite-CurrentRealm", guid = "STALE-VERITE-2", shortName = "Verite",
            role = "DAMAGER", spec = "Frost", classFile = "MAGE", healthPercent = 88 },
    })
    assert(#transientProfile == 1,
        "Combat roster retained duplicate transient same-profile short-name records.")
    local stableSameShort = KWR.TeamResolver:NormalizePublishedRoster({
        { name = "Verite-OldRealm", guid = "STABLE-VERITE-1", shortName = "Verite",
            unit = "raid1", role = "DAMAGER", spec = "Frost", classFile = "MAGE" },
        { name = "Verite-CurrentRealm", guid = "STABLE-VERITE-2", shortName = "Verite",
            unit = "raid2", role = "DAMAGER", spec = "Frost", classFile = "MAGE" },
    })
    assert(#stableSameShort == 2,
        "Combat roster collapsed distinct stable same-short-name teammates.")
    local qualifiedAndShort = KWR.TeamResolver:NormalizePublishedRoster({
        { name = "Valorite-Area52", guid = "VALORITE-GUID", role = "DAMAGER" },
        { shortName = "Valorite", key = "VALORITE-SHORT", spec = "Devastation", role = "DAMAGER" },
    })
    assert(#qualifiedAndShort == 1
        and qualifiedAndShort[1].guid == "VALORITE-GUID",
        "Combat roster did not merge qualified and unique short-name records for one teammate.")
end
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

mockParty = true
mockPartyLeaderAlias = true
assert(KWR.MatchRuntime:ForceRefresh("smoke-party-leader-hydration"),
    "Leader-first party hydration capture failed.")
KWR._testLeaderHydrationRoster = KWR.Store:Get().snapshot.roster
assert(#KWR._testLeaderHydrationRoster == 2
    and (KWR._testLeaderHydrationRoster[1].unit == "player"
        or KWR._testLeaderHydrationRoster[2].unit == "player"),
    "Leader-first roster hydration added a transient duplicate of the player.")
KWR._testLeaderHydrationRoster = nil
mockParty = false
mockPartyLeaderAlias = false
assert(KWR.MatchRuntime:ForceRefresh("smoke-party-leader-reset"),
    "Leader-first party hydration reset failed.")

mockPvP = true
mockInstanceType = "pvp"
mockMercenary = true
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
assert(KWR.RBGMapProfiles:Count() == 10,
    "All-RBG foundation did not expose ten supported profiles.")
assert(KWR.RBGMapProfiles:Get("TWINPEAKS").family == "FLAG",
    "Twin Peaks foundation family drifted.")
assert(#KWR.RBGMapProfiles.shared.doctrineLayers == 7,
    "Shared all-RBG doctrine layer count drifted.")
assert(KWR.ScenarioCalibration:Count() == 200,
    "Scenario calibration did not expose one reviewed row per current base RBG scenario.")
assert(KWR.ScenarioAdversarialCalibration:Count() == 200,
    "Scenario adversarial calibration did not expose one fail-closed row per current base RBG scenario.")
assert(KWR.ScenarioExpertCorpus:Count() == 1200,
    "Scenario expert corpus did not expose the current reviewed and season-prep scenario set.")
assert(KWR.DoctrineComparisons:Count() == 200,
    "Doctrine comparison library did not expose equal map-wide comparison coverage.")
assert(KWR.DoctrineComparisons:CountResponses() == 200,
    "Doctrine comparison library did not expose equal map-wide enemy-response coverage.")
local twinPeaksComparison = KWR.DoctrineComparisons:GetComparison("TWINPEAKS", 1)
assert(twinPeaksComparison
    and twinPeaksComparison.optionA == "Peel our carrier"
    and type(twinPeaksComparison.preferWhy) == "string",
    "Doctrine comparison library did not expose Twin Peaks tradeoff guidance.")
local gilneasResponse = KWR.DoctrineComparisons:GetResponse("GILNEAS", 2)
assert(gilneasResponse
    and gilneasResponse.enemyPattern == "Enemy wants a long Waterworks sustain trap."
    and type(gilneasResponse.safestCounter) == "string",
    "Doctrine comparison library did not expose Gilneas safe-counter guidance.")
local twinPeaksExpertComparison = KWR.DoctrineComparisons:GetComparison("TWINPEAKS", 20)
assert(twinPeaksExpertComparison
    and twinPeaksExpertComparison.optionA == "Protect the score floor first"
    and type(twinPeaksExpertComparison.preferWhy) == "string",
    "Doctrine comparison library did not expose expanded expert branch depth.")
local gilneasExpertResponse = KWR.DoctrineComparisons:GetResponse("GILNEAS", 20)
assert(gilneasExpertResponse
    and gilneasExpertResponse.enemyPattern:find("final desperation route", 1, true)
    and type(gilneasExpertResponse.safestCounter) == "string",
    "Doctrine comparison library did not expose expanded expert safe-counter depth.")
local liveStrategy = KWR.Store:Get().snapshot.strategy or {}
assert(liveStrategy.doctrineComparisonID
    and liveStrategy.enemyResponseGuidanceID
    and type(liveStrategy.comparisonChoice) == "string"
    and type(liveStrategy.safeCounterAction) == "string",
    "Strategist did not surface doctrine comparison and safe-counter guidance.")
local liveCommand = KWR.Store:Get().command or {}
assert(type(liveCommand.branchChoice) == "string"
    and type(liveCommand.safeCounter) == "string"
    and liveCommand.branchChoice ~= ""
    and liveCommand.safeCounter ~= "",
    "Commander did not surface branch choice and safe-counter guidance.")
local tpCalibration = KWR.ScenarioCalibration:Get("tp-recovery-route-rebuild")
assert(tpCalibration
    and tpCalibration.reviewedCases >= 5
    and tpCalibration.topFailure == "EXECUTION_ERROR"
    and type(tpCalibration.doctrineComparisons) == "table"
    and tpCalibration.doctrineComparisons["TWINPEAKS_RECOVER_VS_TRICKLE"] ~= nil
    and type(tpCalibration.doctrineResponses) == "table"
    and tpCalibration.doctrineResponses["TWINPEAKS_RESP_RECOVER_REBAIT"] ~= nil
    and type(tpCalibration.outcomeDrivers) == "table"
    and tpCalibration.outcomeDrivers["EXECUTION_BREAK"] ~= nil
    and type(tpCalibration.lessonPatterns) == "table"
    and type(tpCalibration.disciplineRule) == "string",
    "Scenario calibration did not expose reviewed discipline data for Twin Peaks recovery.")
local tpMapCalibration = KWR.ScenarioCalibration:GetMapSummary("TWINPEAKS")
assert(tpMapCalibration
    and tpMapCalibration.scenarios == 20
    and tpMapCalibration.reviewedCases >= 50
    and type(tpMapCalibration.doctrineComparisons) == "table"
    and type(tpMapCalibration.doctrineResponses) == "table"
    and type(tpMapCalibration.phaseSummaries) == "table",
    "Scenario calibration did not expose Twin Peaks map summary depth.")
local tpEndgameCalibration = KWR.ScenarioCalibration:GetMapPhaseSummary("TWINPEAKS", "ENDGAME")
assert(tpEndgameCalibration
    and tpEndgameCalibration.scenarios == 3
    and tpEndgameCalibration.reviewedCases >= 10,
    "Scenario calibration did not expose Twin Peaks endgame summary depth.")
local tpAdversarialCalibration = KWR.ScenarioAdversarialCalibration:Get("tp-recovery-route-rebuild")
assert(tpAdversarialCalibration
    and tpAdversarialCalibration.adversarialCases >= 1
    and tpAdversarialCalibration.forbiddenCommit == "CALL:FULL_COMMIT"
    and type(tpAdversarialCalibration.doctrineComparisons) == "table"
    and tpAdversarialCalibration.doctrineComparisons["TWINPEAKS_RECOVER_VS_TRICKLE"] ~= nil
    and type(tpAdversarialCalibration.doctrineResponses) == "table"
    and tpAdversarialCalibration.doctrineResponses["TWINPEAKS_RESP_RECOVER_REBAIT"] ~= nil
    and tpAdversarialCalibration.truthDisciplinePatterns ~= nil
    and type(tpAdversarialCalibration.disciplineRule) == "string",
    "Scenario adversarial calibration did not expose fail-closed discipline data.")
local tpMapAdversarial = KWR.ScenarioAdversarialCalibration:GetMapSummary("TWINPEAKS")
assert(tpMapAdversarial
    and tpMapAdversarial.scenarios == 20
    and tpMapAdversarial.adversarialCases >= 10
    and type(tpMapAdversarial.doctrineComparisons) == "table"
    and type(tpMapAdversarial.doctrineResponses) == "table"
    and type(tpMapAdversarial.phaseSummaries) == "table",
    "Scenario adversarial calibration did not expose Twin Peaks map summary depth.")
local tpEndgameAdversarial = KWR.ScenarioAdversarialCalibration:GetMapPhaseSummary("TWINPEAKS", "ENDGAME")
assert(tpEndgameAdversarial
    and tpEndgameAdversarial.scenarios == 3
    and tpEndgameAdversarial.adversarialCases >= 2,
    "Scenario adversarial calibration did not expose Twin Peaks endgame fail-closed depth.")
local wsgExpertReview = KWR.ScenarioExpertCorpus:Get("wsg-opening-route-and-return")
assert(wsgExpertReview
    and wsgExpertReview.reviewedLabels >= 5
    and wsgExpertReview.consensusPrimaryAction == "PLAN:OPENING"
    and wsgExpertReview.preferredComparisonId == "WSG_HOLD_VS_ROTATE"
    and wsgExpertReview.preferredResponseId == "WSG_RESP_ESCORT_SHELL"
    and type(wsgExpertReview.safestCounter) == "string",
    "Scenario expert corpus did not expose reviewed opening doctrine for Warsong Gulch.")
assert(KWR.ScenarioExpertCorpus:Get("arathi-season-prep-opening-01").seasonStatus == "PENDING_SEASON_REVIEW",
    "Season-prep scenario corpus entry lost its pending-review guard.")
assert(KWR.ScenarioExpertCorpus:GetByMapAndPhase("ARATHI", "OPENING").seasonStatus ~= "PENDING_SEASON_REVIEW",
    "Season-prep scenario entered live expert selection before review.")
local tpMapExpertReview = KWR.ScenarioExpertCorpus:GetMapSummary("TWINPEAKS")
assert(tpMapExpertReview
    and tpMapExpertReview.scenarios == 120
    and tpMapExpertReview.reviewedLabels >= 200
    and type(tpMapExpertReview.phaseSummaries) == "table",
    "Scenario expert corpus did not expose Twin Peaks map review depth.")
local tpEndgameExpertReview = KWR.ScenarioExpertCorpus:GetMapPhaseSummary("TWINPEAKS", "ENDGAME")
assert(tpEndgameExpertReview
    and tpEndgameExpertReview.scenarios == 23
    and tpEndgameExpertReview.reviewedLabels >= 35,
    "Scenario expert corpus did not expose Twin Peaks endgame review depth.")
mockLeftScore, mockRightScore = 900, 1000
assert(KWR.MatchRuntime:Reassess(), "Manual battlefield reassessment failed.")
assert(type(KWR.Store:Get().snapshot.reassessment) == "table"
    and type(KWR.Store:Get().snapshot.reassessment.changes) == "table",
    "Manual battlefield reassessment did not publish assignment changes.")
mockLiveEnemies = {
    nameplate7 = {
        name = "EnemyHealer",
        realm = "OtherRealm",
        guid = "Player-2-ENEMY",
        className = "Priest",
        classFile = "PRIEST",
        classID = 5,
        raceName = "Human",
        gender = 1,
        honorLevel = 100,
        health = 550,
        healthMax = 1000,
        inCombat = true,
    },
}
KWR.MatchRuntime:HandleEvent("NAME_PLATE_UNIT_ADDED", "nameplate7")
assert(KWR.EnemyIntel.observedTokens.nameplate7 == "Nameplate",
    "Enemy observer did not retain the active nameplate token.")
local observedEnemy = KWR.Store:Get().snapshot.enemies[1]
assert(observedEnemy and observedEnemy.shortName == "EnemyHealer"
    and observedEnemy.unit == "nameplate7"
    and math.abs((observedEnemy.healthPercent or 0) - 55) < 0.01
    and observedEnemy.localEngaged == true
    and observedEnemy.locationState == "ENGAGED",
    "Restricted live enemy token did not bind to the unique scoreboard identity: "
        .. tostring(observedEnemy and observedEnemy.shortName) .. "/"
        .. tostring(observedEnemy and observedEnemy.unit) .. "/"
        .. tostring(observedEnemy and observedEnemy.healthPercent) .. "/"
        .. tostring(observedEnemy and observedEnemy.localEngaged) .. "/"
        .. tostring(observedEnemy and observedEnemy.locationState))
assert(KWR.EnemyIntel:DescribeLocation(observedEnemy, "ARATHI", true):match("^ENGAGED WITH"),
    "Local enemy truth did not promote to ENGAGED commander language.")
assert(KWR.Store:Get().snapshot.combat.killTarget
    and KWR.Store:Get().snapshot.combat.killTarget.shortName == "EnemyHealer",
    "Local in-combat enemy was not selected as the kill target.")
mockScoreboardRows = {
    mockScoreboardRows[1],
    mockScoreboardRows[2],
    {
        name = "EnemyMage-OtherRealm",
        guid = "Player-3-ENEMY",
        className = "Mage",
        classToken = "MAGE",
        talentSpec = "Frost",
        roleAssigned = 8,
        faction = 1,
    },
}
mockLiveEnemies.nameplate8 = {
    name = "EnemyMage",
    realm = "OtherRealm",
    guid = "Player-3-ENEMY",
    className = "Mage",
    classFile = "MAGE",
    classID = 8,
    raceName = "Human",
    gender = 1,
    honorLevel = 80,
    health = 850,
    healthMax = 1000,
    inCombat = true,
}
KWR.MatchRuntime:HandleEvent("NAME_PLATE_UNIT_ADDED", "nameplate8")
local contestedState = KWR.Store:Get()
assert(contestedState.snapshot.combat.killTarget
    and contestedState.snapshot.combat.killTarget.shortName == "EnemyHealer",
    "Higher-priority engaged healer did not remain the kill target while a second enemy was live.")
mockLiveEnemies.nameplate7 = nil
KWR.MatchRuntime:HandleEvent("NAME_PLATE_UNIT_REMOVED", "nameplate7")
assert(KWR.EnemyIntel.observedTokens.nameplate7 == nil,
    "Enemy observer did not release the removed nameplate token.")
local promotedState = KWR.Store:Get()
assert(promotedState.snapshot.combat.killTarget
    and promotedState.snapshot.combat.killTarget.shortName == "EnemyMage",
    "Next-best engaged target did not promote after the prior kill target disappeared.")
assert(promotedState.snapshot.enemies[1]
    and promotedState.snapshot.enemies[1].shortName == "EnemyMage"
    and promotedState.snapshot.enemies[1].locationState == "ENGAGED",
    "Remaining live enemy did not retain engaged truth during kill-target promotion.")
mockLiveEnemies = {}
KWR.MatchRuntime:HandleEvent("NAME_PLATE_UNIT_REMOVED", "nameplate8")
mockScoreboardRows = {
    mockScoreboardRows[1],
    mockScoreboardRows[2],
}
local liveState = KWR.Store:Get()
assert(liveState.snapshot.context.mapKey == "ARATHI", "Sensor did not resolve Arathi Basin.")
assert(liveState.snapshot.context.team.side == "right"
    and liveState.snapshot.context.team.faction == "Horde",
    "Assigned Horde battlefield team did not override native Alliance faction.")
assert(liveState.snapshot.score.friendly == 1000 and liveState.snapshot.score.enemy == 900,
    "Widget score was not normalized to the assigned Horde team.")
assert(liveState.snapshot.objectives.friendly == 3 and liveState.snapshot.objectives.enemy == 2,
    "Objective ownership was not normalized to the assigned Horde team.")
local objectiveRow = liveState.snapshot.objectives.rows and liveState.snapshot.objectives.rows[1]
assert(objectiveRow
    and type(objectiveRow.native) == "table"
    and type(objectiveRow.native.semantic) == "string"
    and type(objectiveRow.evidence) == "table"
    and type(objectiveRow.resolution) == "table"
    and type(objectiveRow.selectedSource) == "string"
    and type(objectiveRow.resolution.state) == "table"
    and type(objectiveRow.resolution.state.selectedSource) == "string",
    "Objective rows did not preserve native semantics and source-resolution evidence.")
assert(liveState.assignments[1].role == "Anchor Defender"
    and liveState.assignments[1].location == "Farm",
    "Horde Arathi anchor was not assigned to the Horde home objective.")
local objectiveRules = KWR.ObjectiveRules:Resolve(liveState.snapshot)
assert(objectiveRules.family == "NODE"
    and objectiveRules.minimumControlToWin == 3,
    "Objective rules did not resolve Arathi node control requirements.")
assert(KWR.ObjectiveRules:IsActionLegal(liveState.snapshot, "TRADE", objectiveRules),
    "Node objective rules incorrectly blocked a legal trade action.")
assert(liveState.snapshot.strategy.minimumControlToWin == 3
    and type(liveState.snapshot.strategy.legalActions) == "table"
    and #liveState.snapshot.strategy.legalActions > 0,
    "Strategist did not expose the resolved objective rule contract.")
assert(type(liveState.snapshot.reporter.trust) == "table"
    and type(liveState.snapshot.reporter.trust.label) == "string",
    "Reporter did not expose a trust profile.")
assert(type(liveState.snapshot.knowledgeStatus) == "table"
    and type(liveState.snapshot.knowledgeStatus.label) == "string"
    and liveState.snapshot.knowledgeStatus.patchAligned == true,
    "Knowledge status did not expose patch-aligned certainty.")
assert(type(liveState.snapshot.strategy.trust) == "table"
    and type(liveState.snapshot.strategy.trust.mode) == "string",
    "Strategist did not expose a strategy trust model.")
assert(type(liveState.snapshot.strategy.scenarioCalibration) == "table"
    and liveState.snapshot.strategy.scenarioCalibration.reviewedCases >= 5
    and type(liveState.snapshot.strategy.reviewDisciplineRule) == "string",
    "Strategist did not attach reviewed scenario calibration.")
assert(type(liveState.snapshot.strategy.scenarioAdversarialCalibration) == "table"
    and liveState.snapshot.strategy.scenarioAdversarialCalibration.adversarialCases >= 1
    and type(liveState.snapshot.strategy.adversarialDisciplineRule) == "string",
    "Strategist did not attach adversarial scenario calibration.")
assert(type(liveState.snapshot.strategy.scenarioExpertReview) == "table"
    and liveState.snapshot.strategy.scenarioExpertReview.reviewedLabels >= 5
    and type(liveState.snapshot.strategy.expertPreferredAction) == "string"
    and type(liveState.snapshot.strategy.expertSafestCounter) == "string",
    "Strategist did not attach reviewed expert scenario guidance.")
assert(type(liveState.snapshot.strategy.enemyResponsePlan) == "table"
    and type(liveState.snapshot.strategy.enemyResponsePlan.responseID) == "string"
    and type(liveState.snapshot.strategy.enemyResponsePlan.safestReply) == "string"
    and type(liveState.snapshot.strategy.consequenceScore) == "number",
    "Strategist did not attach bounded enemy-response planning.")
assert(type(liveState.snapshot.strategy.executionAssessment) == "table"
    and type(liveState.snapshot.strategy.executionAssessment.organization) == "table"
    and liveState.snapshot.strategy.executionAssessment.organization.uncovered
        == liveState.snapshot.assignmentIntegrity.uncovered
    and liveState.snapshot.strategy.executionAssessment.organization.abandoned
        == liveState.snapshot.assignmentIntegrity.abandoned
    and liveState.snapshot.strategy.executionAssessment.organization.moving
        == liveState.snapshot.assignmentIntegrity.moving,
    "Strategist did not evaluate against the final assignment-integrity state.")
local conflictedSnapshot = KWR.Util:Copy(liveState.snapshot)
conflictedSnapshot.objectives = KWR.Util:Copy(conflictedSnapshot.objectives)
conflictedSnapshot.objectives.rows = KWR.Util:Copy(conflictedSnapshot.objectives.rows or {})
if conflictedSnapshot.objectives.rows[1] then
    conflictedSnapshot.objectives.rows[1].resolution =
        KWR.Util:Copy(conflictedSnapshot.objectives.rows[1].resolution or {})
    conflictedSnapshot.objectives.rows[1].resolution.state =
        KWR.Util:Copy(conflictedSnapshot.objectives.rows[1].resolution.state or {})
    conflictedSnapshot.objectives.rows[1].resolution.state.conflict = {
        otherSource = "area_poi",
        otherValue = "CONTROLLED",
    }
end
local conflictedStrategy = KWR.Strategist:Evaluate(
    conflictedSnapshot, KWR.Predictor:Evaluate(conflictedSnapshot))
assert(conflictedStrategy.trust
    and conflictedStrategy.trust.commitAuthorized == false
    and conflictedStrategy.trust.reason == "Objective truth has conflicting public signals.",
    "Strategist did not suppress hard commits when objective evidence conflicted.")
assert(liveState.assignments[1].backupRole == "Defense Floater"
    and liveState.assignments[1].assignmentConfidence == "HIGH"
    and type(liveState.assignments[1].coverageEffect) == "string",
    "Assignment doctrine did not decorate the anchor assignment.")
do
    local ambiguousAssignments = {
        {
            name = "Verite-TestRealm",
            guid = "Player-1-TEST",
            role = "Anchor Defender",
            location = "Farm",
            priority = 95,
        },
        {
            name = "Verite-OtherRealm",
            guid = "Player-2-TEST",
            role = "Defense Floater",
            location = "Lumber Mill",
            priority = 90,
        },
    }
    local ok, message = KWR.AssignmentOverrides:Pin(
        liveState.snapshot, ambiguousAssignments, "Verite")
    assert(ok == false
        and message:find("short%-name query matched multiple players", 1, false),
        "Commander override pin did not reject an ambiguous short-name query.")
end
local pinnedName = liveState.assignments[1].name
local pinnedRole = liveState.assignments[1].role
local pinnedPriority = liveState.assignments[1].priority
local pinnedOK, pinnedMessage = KWR.AssignmentOverrides:Pin(
    liveState.snapshot, liveState.assignments, pinnedName)
assert(pinnedOK == true and pinnedMessage:find("Pinned override:", 1, true),
    "Commander pin override did not persist the current assignment.")
local heldOK, heldMessage = KWR.AssignmentOverrides:SetLocation(
    liveState.snapshot, liveState.assignments, pinnedName, "Lumber Mill")
assert(heldOK == true and heldMessage:find("Location override:", 1, true),
    "Commander location override did not accept a known battleground objective.")
KWR.MatchRuntime:ForceRefresh("override-test")
local updatedState = KWR.Store:Get()
liveState = updatedState
local overrideAssignments = updatedState.assignments
assert(overrideAssignments[1].manualOverride == true
    and overrideAssignments[1].role == pinnedRole
    and overrideAssignments[1].location == "Lumber Mill"
    and overrideAssignments[1].priority == pinnedPriority,
    "Commander overrides did not apply back into assignment generation.")
local overrideLines = KWR.AssignmentOverrides:DescribeActive(
    updatedState.snapshot, overrideAssignments)
assert(#overrideLines == 1 and overrideLines[1]:find("Lumber Mill", 1, true),
    "Commander override export omitted the active map lock.")
mockMercenary = false
local verificationReport = KWR.Verification:CurrentReport()
assert(verificationReport:find("Assigned team: Horde / right", 1, true),
    "Live verification report omitted assigned-team evidence.")
assert(verificationReport:find("Data coverage:", 1, true)
    and verificationReport:find("Problem signals:", 1, true)
    and verificationReport:find("Problem coverage:", 1, true)
    and verificationReport:find("Command target:", 1, true)
    and verificationReport:find("Reporter confidence:", 1, true)
    and verificationReport:find("Doctrine:", 1, true)
    and verificationReport:find("Enemy model:", 1, true),
    "Live verification report omitted doctrine, problem-signal, data-coverage, command-target, or reporter-confidence evidence.")
assert(verificationReport:find("Score source: ui_widget", 1, true),
    "Live verification report omitted authoritative score evidence.")
assert(verificationReport:find("Command data:", 1, true)
    and verificationReport:find("Command stability:", 1, true)
    and verificationReport:find("Command churn:", 1, true)
    and verificationReport:find("Command stability budget:", 1, true)
    and verificationReport:find("Command field certification:", 1, true)
    and verificationReport:find("Command churn detail:", 1, true)
    and verificationReport:find("Command result quality:", 1, true)
    and verificationReport:find("Command overrides:", 1, true)
    and verificationReport:find("Command lifetime:", 1, true)
    and verificationReport:find("Active play:", 1, true)
    and verificationReport:find("Active play timing:", 1, true)
    and verificationReport:find("Active play outcome:", 1, true)
    and verificationReport:find("Active play transition:", 1, true)
    and verificationReport:find("Active play gate:", 1, true)
    and verificationReport:find("Persistence gate:", 1, true)
    and verificationReport:find("Active play state reason:", 1, true)
    and verificationReport:find("Active play override:", 1, true)
    and verificationReport:find("Active play override gate:", 1, true)
    and verificationReport:find("Active play override class:", 1, true)
    and verificationReport:find("Active play suppression:", 1, true)
    and verificationReport:find("Active play suppression gate:", 1, true)
    and verificationReport:find("Active play switch score:", 1, true)
    and verificationReport:find("Assignment audit: PASS", 1, true)
    and verificationReport:find("Reporter: ACTIVE", 1, true)
    and verificationReport:find("Transitions:", 1, true),
    "Live verification report omitted command, stability, assignment, Reporter, or transition evidence.")
assert(verificationReport:find("ASSIGN:", 1, true),
    "Live verification report omitted per-player assignment evidence.")
assert(verificationReport:find("PROBLEM:", 1, true),
    "Live verification report omitted active problem-signal evidence.")
assert(verificationReport:find("ActivePlay switches: 1 active", 1, true)
    and verificationReport:find("OVERRIDE:", 1, true),
    "Live verification report omitted commander override visibility.")
assert(verificationReport:find("Strategy confidence:", 1, true)
    and verificationReport:find("ALT:", 1, true),
    "Live verification report omitted strategy confidence or alternative comparison.")
assert(verificationReport:find("Knowledge:", 1, true),
    "Live verification report omitted knowledge freshness/certainty status.")
assert(verificationReport:find("Enemy visibility:", 1, true)
    and verificationReport:find("Local target:", 1, true),
    "Live verification report omitted enemy-visibility or local-target visibility.")
assert(verificationReport:find("OBJ: ", 1, true)
    and verificationReport:find("state ", 1, true)
    and verificationReport:find(" via ", 1, true)
    and verificationReport:find("Objective conflicts:", 1, true),
    "Live verification report omitted per-objective source-resolution evidence.")
local sentinelView = KWR.SentinelBridge:BuildView("TestPlayer", liveState)
assert(sentinelView and sentinelView.source == "KWR",
    "Sentinel bridge did not produce a player relay view.")
assert(sentinelView.assignment
    and sentinelView.assignment.role == overrideAssignments[1].role
    and sentinelView.assignment.location == KWR.Maps:AbbreviateLocation(
        liveState.snapshot.context.mapKey, overrideAssignments[1].location),
    "Sentinel bridge did not publish the current player's assignment: role="
        .. tostring(sentinelView.assignment and sentinelView.assignment.role)
        .. " expectedRole=" .. tostring(overrideAssignments[1].role)
        .. " location=" .. tostring(sentinelView.assignment
            and sentinelView.assignment.location)
        .. " expectedLocation=" .. tostring(KWR.Maps:AbbreviateLocation(
            liveState.snapshot.context.mapKey, overrideAssignments[1].location)))
assert(sentinelView.score
    and sentinelView.score.status == liveState.prediction.status
    and sentinelView.score.commandWhen == liveState.command.when,
    "Sentinel bridge did not publish score pace and command timing.")
local currentWatch = liveState.snapshot.combat
    and (liveState.snapshot.combat.localTarget
        or liveState.snapshot.combat.killTarget)
assert(sentinelView.watch and sentinelView.watch.reason ~= ""
    and ((currentWatch
        and (sentinelView.watch.key == currentWatch.key
            or sentinelView.watch.name == currentWatch.name
            or sentinelView.watch.shortName == currentWatch.shortName))
        or (not currentWatch and sentinelView.watch.name == "No local target")),
    "Sentinel bridge did not publish the current local watch target.")
local clearedOK = KWR.AssignmentOverrides:Clear(pinnedName)
assert(clearedOK == true, "Commander override clear did not remove the active player lock.")
assert(#KWR.Verification.ledger > 0, "Verification ledger did not record live transitions.")
do
    local savedLedger = KWR.Verification.ledger
    local savedLastSignature = KWR.Verification.lastSignature
    local savedBuildEntry = KWR.Verification.BuildEntry
    local buildCount = 0
    KWR.Verification.ledger = {}
    KWR.Verification.lastSignature = nil
    KWR.Verification.BuildEntry = function(self, state)
        buildCount = buildCount + 1
        return savedBuildEntry(self, state)
    end
    KWR.Verification:Update(liveState)
    KWR.Verification:Update(liveState)
    KWR.Verification.BuildEntry = savedBuildEntry
    KWR.Verification.ledger = savedLedger
    KWR.Verification.lastSignature = savedLastSignature
    assert(buildCount == 1,
        "Verification still built a full entry for duplicate live state.")
end
assert(liveState.prediction.status == "WIN", "Pipeline did not project the Arathi 3-2 win.")
assert(type(liveState.command.stability) == "table"
    and type(liveState.command.stabilitySummary) == "table"
    and type(liveState.command.stabilitySummary.issued) == "number",
    "Commander did not expose baseline stability telemetry.")
assert(type(liveState.activePlay) == "table"
    and type(liveState.command.activePlay) == "table"
    and liveState.activePlay.id == liveState.command.activePlay.id
    and type(liveState.activePlay.phase) == "string",
    "ActivePlay did not publish as the authoritative persistent command-state contract.")
do
    local savedCommanderMetrics = KWR.Commander.metrics
    KWR.Commander.metrics = {
        issued = 2,
        replacements = 0,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 0, count = 0 },
        lifetimes = { total = 0, count = 0, shortest = nil, longest = 0, samples = {} },
    }
    local insufficient = KWR.Commander:GetStabilityMetrics()
    assert(insufficient.certificationStatus == "INSUFFICIENT_SAMPLE"
        and insufficient.commandHealth == "PASS"
        and type(insufficient.preMovementInvalidationRate) == "number",
        "Commander certification gate did not preserve insufficient-sample PASS behavior.")

    KWR.Commander.metrics = {
        evaluations = 20,
        issued = 1,
        replacements = 0,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 0, count = 0 },
        lifetimes = { total = 0, count = 0, shortest = nil, longest = 0, samples = {} },
    }
    local evaluationOnly = KWR.Commander:GetStabilityMetrics()
    assert(evaluationOnly.certificationStatus == "INSUFFICIENT_SAMPLE"
        and evaluationOnly.evaluations == 20
        and evaluationOnly.issued == 1,
        "Commander certification still treated repeated evaluations as published command evidence.")

    KWR.Commander.metrics = {
        issued = 8,
        replacements = 0,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 0, count = 0 },
        lifetimes = { total = 0, count = 0, shortest = nil, longest = 0, samples = {} },
    }
    local ready = KWR.Commander:GetStabilityMetrics()
    assert(ready.certificationStatus == "READY"
        and ready.commandHealth == "PASS",
        "Commander certification gate did not mark a stable command sample ready.")

    KWR.Commander.metrics = {
        issued = 8,
        replacements = 3,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 12, count = 3 },
        lifetimes = { total = 30, count = 3, shortest = 8, longest = 12, samples = { 8, 10, 12 } },
    }
    local watch = KWR.Commander:GetStabilityMetrics()
    assert(watch.certificationStatus == "REVIEW_REQUIRED"
        and watch.commandHealth == "WATCH"
        and watch.medianLifetime == 10,
        "Commander certification gate did not flag short command lifetimes for review.")

    KWR.Commander.metrics = {
        issued = 20,
        replacements = 4,
        stabilized = 0,
        suppressed = 0,
        reversals = 2,
        preMovementInvalidations = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 16, count = 4 },
        lifetimes = { total = 100, count = 4, shortest = 20, longest = 30, samples = { 20, 25, 25, 30 } },
    }
    local failed = KWR.Commander:GetStabilityMetrics()
    assert(failed.certificationStatus == "FAIL_REVIEW"
        and failed.commandHealth == "REVIEW"
        and failed.reversalRate > 0.05,
        "Commander certification gate did not fail excessive reversal churn.")
    KWR.Commander.metrics = savedCommanderMetrics
end
do
    local savedPending = KWR.MatchRuntime.pending
    local savedPendingReason = KWR.MatchRuntime.pendingReason
    local savedPendingDueAt = KWR.MatchRuntime.pendingDueAt
    local savedFriendlySyncAt = KWR.MatchRuntime.lastFriendlyHealthSyncAt
    local beforeLightweight = KWR.MatchRuntime.diagnostics.lightweightEvents or 0
    KWR.MatchRuntime.pending = false
    KWR.MatchRuntime.pendingReason = nil
    KWR.MatchRuntime.pendingDueAt = nil
    KWR.MatchRuntime.lastFriendlyHealthSyncAt = nil
    KWR.MatchRuntime:HandleEvent("UNIT_HEALTH", "player")
    assert((KWR.MatchRuntime.diagnostics.lightweightEvents or 0) == beforeLightweight + 1
        and KWR.MatchRuntime.pending ~= true
        and KWR.MatchRuntime.pendingReason == nil
        and KWR.MatchRuntime.pendingDueAt == nil
        and KWR.MatchRuntime.lastFriendlyHealthSyncAt == nil,
        "Ordinary friendly health churn still queued a full runtime refresh.")
    KWR.MatchRuntime.pending = savedPending
    KWR.MatchRuntime.pendingReason = savedPendingReason
    KWR.MatchRuntime.pendingDueAt = savedPendingDueAt
    KWR.MatchRuntime.lastFriendlyHealthSyncAt = savedFriendlySyncAt
end
do
    local savedCommanderMetrics = KWR.Commander.metrics
    local savedLastCommand = KWR.Commander.lastCommand
    local savedLastSignature = KWR.Commander.lastSignature
    local savedLastActivePlay = KWR.Commander.lastActivePlay
    local savedHistory = KWR.Commander.history
    local savedStoreActivePlay = KWR.Store.state and KWR.Store.state.activePlay or nil
    local now = KWR.Util:Now()
    local signatureA = KWR.Util:Signature({ "FORMING", "RECRUIT A", "Full team" })
    local signatureB = KWR.Util:Signature({ "FORMING", "RECRUIT B", "Full team" })
    KWR.Commander.metrics = {
        issued = 2,
        replacements = 1,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        emergencyBypasses = 0,
        reassessmentBypasses = 0,
        responseBypasses = 0,
        candidateBypasses = 0,
        activePlayRetains = 0,
        suppressedAlternatives = 0,
        suppressedByPersistence = 0,
        suppressedBySuperiority = 0,
        overrides = 0,
        overridesBeforeArrival = 0,
        overridesAfterCommitment = 0,
        invalidations = 0,
        invalidationsBeforeArrival = 0,
        invalidationsAfterCommitment = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 0, count = 0 },
        lifetimes = { total = 0, count = 0, shortest = nil, longest = 0, samples = {} },
        recentSignatures = {
            { at = now - 6, signature = signatureA },
            { at = now - 2, signature = signatureB },
        },
    }
    KWR.Commander.lastSignature = signatureB
    KWR.Commander.lastCommand = {
        mapKey = "WORLD",
        status = "FORMING",
        urgency = 0,
        action = "RECRUIT B",
        who = "Full team",
        signature = signatureB,
        createdAt = now - 2,
        decisionAt = now - 2,
        stabilizationSignature = signatureB,
    }
    KWR.Commander.lastActivePlay = nil
    KWR.Commander.history = {}
    if KWR.Store.state then KWR.Store.state.activePlay = nil end
    local reversalCommand = KWR.Commander:Compose({
        context = { mapKey = "WORLD", inPvP = false },
        formation = { action = "RECRUIT A" },
    }, {
        status = "WORLD",
        urgency = 0,
    }, {})
    local reversalMetrics = KWR.Commander:GetStabilityMetrics()
    assert(reversalCommand.signature == signatureA
        and reversalMetrics.reversals == 1
        and reversalMetrics.reversalRate > 0,
        "Commander did not detect an A-B-A command reversal through the real publication path.")

    KWR.Commander.metrics = {
        issued = 1,
        replacements = 0,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        emergencyBypasses = 0,
        reassessmentBypasses = 0,
        responseBypasses = 0,
        candidateBypasses = 0,
        activePlayRetains = 0,
        suppressedAlternatives = 0,
        suppressedByPersistence = 0,
        suppressedBySuperiority = 0,
        overrides = 0,
        overridesBeforeArrival = 0,
        overridesAfterCommitment = 0,
        invalidations = 0,
        invalidationsBeforeArrival = 0,
        invalidationsAfterCommitment = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 0, count = 0 },
        lifetimes = { total = 0, count = 0, shortest = nil, longest = 0, samples = {} },
        recentSignatures = {
            { at = now - 1, signature = signatureA },
        },
    }
    KWR.Commander.lastSignature = signatureA
    local preMoveIssuedAt = KWR.Util:Now() - 1
    KWR.Commander.lastCommand = {
        mapKey = "WORLD",
        status = "FORMING",
        urgency = 0,
        action = "RECRUIT A",
        who = "Full team",
        signature = signatureA,
        createdAt = preMoveIssuedAt,
        decisionAt = preMoveIssuedAt,
        stabilizationSignature = signatureA,
    }
    local preMoveCommand = KWR.Commander:Compose({
        context = { mapKey = "WORLD", inPvP = false },
        formation = { action = "RECRUIT B" },
    }, {
        status = "WORLD",
        urgency = 0,
    }, {})
    local preMoveMetrics = KWR.Commander:GetStabilityMetrics()
    assert(preMoveCommand.signature ~= signatureA
        and preMoveMetrics.replacements == 1
        and preMoveMetrics.preMovementInvalidations == 1
        and preMoveMetrics.preMovementInvalidationRate == 1,
        "Commander did not count a command replaced before movement could begin.")

    KWR.Commander.metrics = {
        issued = 0,
        replacements = 0,
        stabilized = 0,
        suppressed = 0,
        reversals = 0,
        preMovementInvalidations = 0,
        emergencyBypasses = 0,
        reassessmentBypasses = 0,
        responseBypasses = 0,
        candidateBypasses = 0,
        activePlayRetains = 0,
        suppressedAlternatives = 0,
        suppressedByPersistence = 0,
        suppressedBySuperiority = 0,
        overrides = 0,
        overridesBeforeArrival = 0,
        overridesAfterCommitment = 0,
        invalidations = 0,
        invalidationsBeforeArrival = 0,
        invalidationsAfterCommitment = 0,
        successfulPlays = 0,
        switchAdvantages = { total = 0, count = 0 },
        lifetimes = { total = 0, count = 0, shortest = nil, longest = 0, samples = {} },
        recentSignatures = {},
    }
    local emergencyIssuedAt = KWR.Util:Now() - 9
    local emergencyActivePlay = {
        id = "EMERGENCY_FARM_HOLD",
        family = "NODE",
        action = "HOLD FARM",
        objective = "Farm",
        movers = { "Verite", "Holic" },
        stayers = { "Nrrdy", "Lymrith" },
        issuedAt = emergencyIssuedAt,
        minimumCommitUntil = KWR.Util:Now() + 18,
        reviewAt = KWR.Util:Now() - 5,
        expectedArrivalAt = KWR.Util:Now() - 2,
        expectedResolutionAt = KWR.Util:Now() + 20,
        hardDeadlineAt = KWR.Util:Now() + 28,
        phase = "COMMITTED",
        remainingValue = 78,
    }
    KWR.Store.state.activePlay = KWR.Util:Copy(emergencyActivePlay)
    KWR.Commander.lastActivePlay = KWR.Util:Copy(emergencyActivePlay)
    KWR.Commander.lastSignature = "EMERGENCY_FARM_HOLD"
    KWR.Commander.lastCommand = {
        mapKey = "ARATHI",
        status = "WIN",
        urgency = 20,
        action = "HOLD FARM",
        who = "Verite, Holic",
        signature = "EMERGENCY_FARM_HOLD",
        createdAt = emergencyIssuedAt,
        decisionAt = emergencyIssuedAt,
        stabilizationSignature = "EMERGENCY_FARM_HOLD",
    }
    local emergencyCommand = KWR.Commander:Compose({
        context = { mapKey = "ARATHI", mapName = "Arathi Basin", kind = "NODE", inPvP = true },
        score = { friendly = 900, enemy = 880, max = 1500 },
        objectives = {
            rows = {
                { label = "Farm", owner = "FRIENDLY", state = "CONTROLLED" },
                { label = "Blacksmith", owner = "ENEMY", state = "CONTROLLED" },
            },
        },
        strategy = {
            planID = "ARATHI_EMERGENCY_BS",
            action = "TAKE BLACKSMITH NOW",
            confidence = "HIGH",
            objectiveDecision = {
                target = "Blacksmith",
                success = "Blacksmith flips before the enemy clock ends.",
                abort = "Hold Farm if Blacksmith becomes impossible.",
            },
        },
    }, {
        status = "LOSE",
        urgency = 96,
        confidence = "HIGH",
        emergency = "TAKE BLACKSMITH NOW",
    }, {})
    local emergencyMetrics = KWR.Commander:GetStabilityMetrics()
    local emergencyEvidence = emergencyCommand.overrideRecord
        and emergencyCommand.overrideRecord.evidence or {}
    local hasEmergencyEvidence = false
    for _, evidence in ipairs(emergencyEvidence) do
        if evidence == "emergency_urgency" then hasEmergencyEvidence = true end
    end
    assert(emergencyCommand.activePlayDecision
        and emergencyCommand.activePlayDecision.replacementAllowed == true
        and emergencyCommand.activePlayDecision.replacementReason == "EMERGENCY_URGENCY"
        and emergencyCommand.activePlayDecision.gateClass == "REPLACEMENT"
        and emergencyCommand.overrideRecord
        and emergencyCommand.overrideRecord.gateClass == "REPLACEMENT"
        and hasEmergencyEvidence == true
        and emergencyMetrics.emergencyBypasses == 1
        and emergencyMetrics.overrides == 1
        and emergencyMetrics.overridesAfterCommitment == 1,
        "Commander emergency urgency did not override a committed play with auditable evidence.")
    KWR.Commander.metrics = savedCommanderMetrics
    KWR.Commander.lastCommand = savedLastCommand
    KWR.Commander.lastSignature = savedLastSignature
    KWR.Commander.lastActivePlay = savedLastActivePlay
    KWR.Commander.history = savedHistory
    if KWR.Store.state then KWR.Store.state.activePlay = savedStoreActivePlay end
end
local replacementSnapshot = KWR.Util:Copy(liveState.snapshot)
replacementSnapshot.reassessment = nil
local stabilityState = KWR.Store:Get()
stabilityState.command = KWR.Util:Copy(liveState.command)
stabilityState.command.action = "HOLD FARM"
stabilityState.command.who = "Verite, Holic"
stabilityState.command.when = "NEXT FIGHT"
stabilityState.command.reason = "Hold the current 3-node structure."
stabilityState.command.signature = KWR.Util:Signature({
    "WIN", "HOLD FARM", "Verite, Holic",
})
stabilityState.activePlay = {
    id = "ACTIVE_FARM_HOLD",
    family = "NODE",
    action = "HOLD FARM",
    objective = "Farm",
    movers = { "Verite", "Holic" },
    stayers = { "Nrrdy", "Lymrith" },
    issuedAt = KWR.Util:Now() - 2,
    minimumCommitUntil = KWR.Util:Now() + 30,
    reviewAt = KWR.Util:Now() + 1,
    expectedArrivalAt = KWR.Util:Now() + 6,
    expectedResolutionAt = KWR.Util:Now() + 18,
    hardDeadlineAt = KWR.Util:Now() + 24,
    phase = "MOVING",
    scoreAtIssue = 70,
    remainingValue = 68,
    successRules = {},
    abortRules = { "Farm is lost." },
    invalidationRules = { "Map ends." },
    sourceEvidence = { "baseline" },
    confidence = 80,
}
replacementSnapshot.strategy = KWR.Util:Copy(replacementSnapshot.strategy or {})
replacementSnapshot.strategy.action = "Rotate to Blacksmith immediately."
replacementSnapshot.strategy.planID = "ARATHI_FORCE_ROTATE"
replacementSnapshot.strategy.objectiveDecision = {
    target = "Blacksmith",
    success = "Blacksmith becomes friendly controlled.",
    abort = "Arrival misses the contest window.",
}
replacementSnapshot.responsePackage = KWR.Util:Copy(replacementSnapshot.responsePackage or {})
replacementSnapshot.responsePackage.qualified = false
replacementSnapshot.responsePackage.target = "Blacksmith"
replacementSnapshot.responsePackage.moverText = "Verite, Chosen, Holic"
replacementSnapshot.responsePackage.stayerText = "Farm: Nrrdy, Lymrith"
local replacementPrediction = KWR.Util:Copy(liveState.prediction)
replacementPrediction.urgency = 40
local heldCommand = KWR.Commander:Compose(
    replacementSnapshot, replacementPrediction, liveState.assignments)
assert(heldCommand.activePlayDecision
    and heldCommand.activePlayDecision.retained == true
    and heldCommand.action == "HOLD FARM"
    and heldCommand.activePlay.id == "ACTIVE_FARM_HOLD"
    and heldCommand.activePlayDecision.replacementAllowed ~= true
    and heldCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE"
    and heldCommand.activePlayDecision.gateClass == "PERSISTENCE_HOLD"
    and heldCommand.activePlayOutcome
    and heldCommand.activePlayOutcome.status == "HELD"
    and heldCommand.activePlayOutcome.bucket == "COMMITTED",
    "Commander did not retain the active play when a fresh alternative lacked persistence.")
assert(heldCommand.activePlayTransition
    and heldCommand.activePlayTransition.trigger == "HELD"
    and heldCommand.activePlayTransition.fromPhase == "MOVING"
    and heldCommand.activePlayTransition.toPhase == "COMMITTED",
    "Held active play did not publish a clear execution transition.")
local heldSuppressionLog = KWR.Commander:GetSuppressionLog()
local latestHeldSuppression = heldSuppressionLog[#heldSuppressionLog]
assert(type(latestHeldSuppression) == "table"
    and latestHeldSuppression.gateClass == "PERSISTENCE_HOLD"
    and latestHeldSuppression.currentObjective == "Farm"
    and latestHeldSuppression.candidateObjective == "Blacksmith",
    "Suppressed active-play replacement was not logged with persistence gate detail.")
assert(heldCommand.status == "WIN", "Commander did not publish the projected status.")
local stableTrendState = KWR.Store:Get()
stableTrendState.activePlay.issuedAt = KWR.Util:Now() - 5
stableTrendState.activePlay.minimumCommitUntil = KWR.Util:Now() - 1
local candidateId = KWR.Util:Signature({
    "NODE",
    "ARATHI_FORCE_ROTATE",
    "Blacksmith",
    "Rotate to Blacksmith immediately.",
    replacementSnapshot.responsePackage.moverText,
})
KWR.Commander.candidateTrends = KWR.Commander.candidateTrends or {}
KWR.Commander.candidateTrends[candidateId] = {
    signature = candidateId,
    firstPreferredAt = KWR.Util:Now() - 12,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 4,
    minimumAdvantage = 2,
}
local superiorCandidate = KWR.Commander:Compose(
    replacementSnapshot, replacementPrediction, liveState.assignments)
local switchScore = superiorCandidate.activePlayDecision
    and superiorCandidate.activePlayDecision.replacementScore
assert(superiorCandidate.activePlayDecision
    and superiorCandidate.activePlayDecision.retained == true
    and (superiorCandidate.activePlayDecision.replacementReason == "NOT_MATERIALLY_SUPERIOR"
        or superiorCandidate.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE")
    and type(switchScore) == "table"
    and type(switchScore.switchCost) == "table"
    and (switchScore.switchCost.total or 0) > 0,
    "Commander did not retain a non-superior replacement after the minimum commitment window.")
assert((switchScore.switchCost.total or 0) >= 20,
    "Arathi held-node replacement did not carry the stronger outer/structure switch-cost posture.")
local invalidatedSnapshot = KWR.Util:Copy(replacementSnapshot)
local invalidatedState = KWR.Store:Get()
invalidatedState.activePlay.reviewAt = KWR.Util:Now() - 6
invalidatedState.activePlay.expectedArrivalAt = KWR.Util:Now() - 1
invalidatedState.activePlay.expectedResolutionAt = KWR.Util:Now() + 12
invalidatedState.activePlay.hardDeadlineAt = KWR.Util:Now() + 18
invalidatedState.activePlay.minimumCommitUntil = KWR.Util:Now() + 8
invalidatedState.activePlay.phase = "COMMITTED"
invalidatedSnapshot.objectives = KWR.Util:Copy(invalidatedSnapshot.objectives or {})
invalidatedSnapshot.objectives.rows = KWR.Util:Copy(invalidatedSnapshot.objectives.rows or {})
for _, row in ipairs(invalidatedSnapshot.objectives.rows) do
    if row.label == "Farm" then
        row.owner = "ENEMY"
        row.state = "CONTROLLED"
    end
end
local invalidatedCommand = KWR.Commander:Compose(
    invalidatedSnapshot, replacementPrediction, liveState.assignments)
assert(invalidatedCommand.activePlayDecision
    and invalidatedCommand.activePlayDecision.invalidation == "HELD_NODE_LOST"
    and invalidatedCommand.activePlayDecision.invalidationFamily == "NODE"
    and invalidatedCommand.activePlayDecision.gateClass == "INVALIDATION"
    and invalidatedCommand.activePlayDecision.replacementAllowed == true
    and invalidatedCommand.activePlayOutcome
    and invalidatedCommand.activePlayOutcome.status == "FAILED",
    "Commander did not invalidate a committed node play when its held node was lost.")
local invalidationOverrideLog = KWR.Commander:GetOverrideLog()
local latestInvalidationOverride = invalidationOverrideLog[#invalidationOverrideLog]
assert(type(latestInvalidationOverride) == "table"
    and latestInvalidationOverride.gateClass == "INVALIDATION"
    and latestInvalidationOverride.invalidation == "HELD_NODE_LOST"
    and latestInvalidationOverride.invalidationFamily == "NODE"
    and latestInvalidationOverride.currentObjective == "Farm"
    and latestInvalidationOverride.candidateObjective == "Blacksmith"
    and (latestInvalidationOverride.lostCommitmentTime or 0) > 0,
    "Invalidated active-play replacement was not logged with override evidence and lost commitment time.")
local gilneasPreviousState = {
    activePlay = {
        id = "ACTIVE_WW_HOLD",
        family = "NODE",
        action = "HOLD WATERWORKS",
        objective = "Waterworks",
        movers = { "Verite", "Chosen", "Holic" },
        stayers = { "Nrrdy", "Lymrith" },
        issuedAt = KWR.Util:Now() - 9,
        minimumCommitUntil = KWR.Util:Now() + 12,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 16,
        hardDeadlineAt = KWR.Util:Now() + 24,
        phase = "COMMITTED",
        remainingValue = 70,
    },
    command = {
        action = "HOLD WATERWORKS",
        who = "Verite, Chosen, Holic",
        when = "NOW",
        reason = "Protect the 2-base hold.",
        signature = "ACTIVE_WW_HOLD",
        decisionAt = KWR.Util:Now() - 9,
    },
}
local gilneasSnapshot = {
    context = {
        mapKey = "GILNEAS",
        mapName = "Battle for Gilneas",
        kind = "NODE",
        inPvP = true,
    },
    score = { friendly = 1100, enemy = 900 },
    objectives = {
        rows = {
            { label = "Lighthouse", owner = "FRIENDLY", state = "CONTROLLED" },
            { label = "Waterworks", owner = "FRIENDLY", state = "CONTROLLED" },
            { label = "Mine", owner = "ENEMY", state = "CONTROLLED" },
        },
        friendly = 2,
        enemy = 1,
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 82,
        planID = "BFG_GREED_MINE",
        action = "Rotate to Mine and pressure the recap.",
        objectiveDecision = {
            target = "Mine",
            success = "Mine becomes friendly controlled.",
            abort = "Keep the 2-base hold if the hit slows.",
        },
        trust = { reason = "Two bases already controlled." },
    },
    responsePackage = {
        qualified = false,
        target = "Mine",
        moverText = "Verite, Chosen, Holic",
        stayerText = "Waterworks: Nrrdy, Lymrith",
    },
}
local gilneasPrediction = {
    urgency = 35,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(gilneasPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(gilneasPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(gilneasPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(gilneasPreviousState.command)
local gilneasCandidateId = KWR.Util:Signature({
    "NODE",
    "BFG_GREED_MINE",
    "Mine",
    "Rotate to Mine and pressure the recap.",
    "Verite, Chosen, Holic",
})
KWR.Commander.candidateTrends[gilneasCandidateId] = {
    signature = gilneasCandidateId,
    firstPreferredAt = KWR.Util:Now() - 14,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 5,
    averageAdvantage = 18,
    minimumAdvantage = 12,
}
local gilneasCommand = KWR.Commander:Compose(
    gilneasSnapshot, gilneasPrediction, liveState.assignments)
local gilneasScore = gilneasCommand.activePlayDecision
    and gilneasCommand.activePlayDecision.replacementScore
assert(gilneasCommand.activePlayDecision
    and gilneasCommand.activePlayDecision.retained == true
    and (gilneasCommand.activePlayDecision.replacementReason == "NOT_MATERIALLY_SUPERIOR"
        or gilneasCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE")
    and type(gilneasScore) == "table"
    and (gilneasScore.margin or 0) >= 24
    and type(gilneasScore.switchCost) == "table"
    and (gilneasScore.switchCost.total or 0) >= 18,
    "Gilneas 2-base structure did not enforce the stronger hold-versus-greed node policy.")
assert(gilneasCommand.activePlay
    and gilneasCommand.activePlay.milestone == "OBJECTIVE_SECURED"
    and gilneasCommand.activePlay.phase == "COMMITTED",
    "Node-family active play did not promote the secured objective milestone into phase state.")
local deepwindPreviousState = {
    activePlay = {
        id = "ACTIVE_DWG_MARKET_HOLD",
        family = "NODE",
        action = "HOLD MARKET",
        objective = "Market",
        movers = { "Verite", "Chosen", "Holic" },
        stayers = { "Nrrdy", "Lymrith" },
        issuedAt = KWR.Util:Now() - 8,
        minimumCommitUntil = KWR.Util:Now() + 14,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 18,
        hardDeadlineAt = KWR.Util:Now() + 26,
        phase = "COMMITTED",
        remainingValue = 72,
    },
    command = {
        action = "HOLD MARKET",
        who = "Verite, Chosen, Holic",
        when = "NOW",
        reason = "Market anchors the central route structure.",
        signature = "ACTIVE_DWG_MARKET_HOLD",
        decisionAt = KWR.Util:Now() - 8,
    },
}
local deepwindSnapshot = {
    context = {
        mapKey = "DEEPWIND",
        mapName = "Deepwind Gorge",
        kind = "NODE",
        inPvP = true,
    },
    score = { friendly = 920, enemy = 860 },
    objectives = {
        rows = {
            { label = "Market", owner = "FRIENDLY", state = "CONTROLLED" },
            { label = "Ruins", owner = "FRIENDLY", state = "CONTROLLED" },
            { label = "Shrine", owner = "ENEMY", state = "CONTROLLED" },
            { label = "Quarry", owner = "ENEMY", state = "CONTROLLED" },
            { label = "Farm", owner = "ENEMY", state = "CONTROLLED" },
        },
        friendly = 2,
        enemy = 3,
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 80,
        planID = "DWG_OUTER_FARM_GREED",
        action = "ROTATE TO FARM",
        objectiveDecision = {
            target = "Farm",
            success = "Farm becomes friendly controlled.",
            abort = "Hold Market if the route is late.",
        },
        trust = { reason = "Market hold is still live." },
    },
    responsePackage = {
        qualified = false,
        target = "Farm",
        moverText = "Verite, Chosen, Holic",
        stayerText = "Market: Nrrdy, Lymrith",
    },
}
local deepwindPrediction = {
    urgency = 38,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(deepwindPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(deepwindPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(deepwindPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(deepwindPreviousState.command)
local deepwindCandidateId = KWR.Util:Signature({
    "NODE",
    "DWG_OUTER_FARM_GREED",
    "Farm",
    "ROTATE TO FARM",
    "Verite, Chosen, Holic",
})
KWR.Commander.candidateTrends[deepwindCandidateId] = {
    signature = deepwindCandidateId,
    firstPreferredAt = KWR.Util:Now() - 12,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 16,
    minimumAdvantage = 10,
}
local deepwindCommand = KWR.Commander:Compose(
    deepwindSnapshot, deepwindPrediction, liveState.assignments)
local deepwindScore = deepwindCommand.activePlayDecision
    and deepwindCommand.activePlayDecision.replacementScore
assert(deepwindCommand.activePlayDecision
    and deepwindCommand.activePlayDecision.retained == true
    and type(deepwindScore) == "table"
    and (deepwindScore.margin or 0) >= 22
    and type(deepwindScore.switchCost) == "table"
    and (deepwindScore.switchCost.total or 0) >= 12,
    "Deepwind central-node hold did not resist a low-value outer-node rotation.")
local eotsPreviousState = {
    activePlay = {
        id = "ACTIVE_EOTS_MT_HOLD",
        family = "HYBRID",
        action = "HOLD MAGE TOWER",
        objective = "Mage Tower",
        movers = { "Verite", "Chosen" },
        stayers = { "Nrrdy", "Lymrith" },
        issuedAt = KWR.Util:Now() - 7,
        minimumCommitUntil = KWR.Util:Now() + 12,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 16,
        hardDeadlineAt = KWR.Util:Now() + 24,
        phase = "COMMITTED",
        remainingValue = 68,
    },
    command = {
        action = "HOLD MAGE TOWER",
        who = "Verite, Chosen",
        when = "NOW",
        reason = "Hold the two-base structure before flag greed.",
        signature = "ACTIVE_EOTS_MT_HOLD",
        decisionAt = KWR.Util:Now() - 7,
    },
}
local eotsSnapshot = {
    context = {
        mapKey = "EOTS",
        mapName = "Eye of the Storm",
        kind = "HYBRID",
        inPvP = true,
    },
    score = { friendly = 780, enemy = 720 },
    objectives = {
        rows = {
            { label = "Mage Tower", owner = "FRIENDLY", state = "CONTROLLED" },
            { label = "Draenei Ruins", owner = "FRIENDLY", state = "CONTROLLED" },
            { label = "Fel Reaver", owner = "ENEMY", state = "CONTROLLED" },
            { label = "Blood Elf Tower", owner = "ENEMY", state = "CONTROLLED" },
            { label = "Flag", owner = "UNKNOWN", state = "ACTIVE" },
        },
        friendly = 2,
        enemy = 2,
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 82,
        planID = "EOTS_FLAG_GREED",
        action = "TAKE FLAG",
        objectiveDecision = {
            target = "Flag",
            success = "Flag converts with two bases.",
            abort = "Hold bases if the flag route exposes a tower.",
        },
        trust = { reason = "Two-base structure is still active." },
    },
    responsePackage = {
        qualified = false,
        target = "Flag",
        moverText = "Verite, Chosen",
        stayerText = "Mage Tower: Nrrdy, Lymrith",
    },
}
local eotsPrediction = {
    urgency = 42,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(eotsPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(eotsPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(eotsPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(eotsPreviousState.command)
local eotsCandidateId = KWR.Util:Signature({
    "HYBRID",
    "EOTS_FLAG_GREED",
    "Flag",
    "TAKE FLAG",
    "Verite, Chosen",
})
KWR.Commander.candidateTrends[eotsCandidateId] = {
    signature = eotsCandidateId,
    firstPreferredAt = KWR.Util:Now() - 11,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 14,
    minimumAdvantage = 9,
}
local eotsCommand = KWR.Commander:Compose(
    eotsSnapshot, eotsPrediction, liveState.assignments)
local eotsScore = eotsCommand.activePlayDecision
    and eotsCommand.activePlayDecision.replacementScore
assert(eotsCommand.activePlayDecision
    and eotsCommand.activePlayDecision.retained == true
    and eotsCommand.activePlayDecision.invalidationFamily == "NONE"
    and type(eotsScore) == "table"
    and (eotsScore.margin or 0) >= 24,
    "EOTS stable two-base structure did not restrain a low-value flag pivot.")
local travelCommitState = {
    activePlay = {
        id = "ACTIVE_HOLD_LIGHTHOUSE",
        family = "NODE",
        action = "HOLD LIGHTHOUSE",
        objective = "Lighthouse",
        movers = { "Verite", "Chosen" },
        stayers = { "Nrrdy" },
        issuedAt = KWR.Util:Now() - 6,
        minimumCommitUntil = KWR.Util:Now() + 10,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 14,
        hardDeadlineAt = KWR.Util:Now() + 20,
        phase = "COMMITTED",
        remainingValue = 66,
    },
    command = {
        action = "HOLD LIGHTHOUSE",
        who = "Verite, Chosen",
        when = "NOW",
        reason = "Hold Lighthouse until the next rotation is actually worth it.",
        signature = "ACTIVE_HOLD_LIGHTHOUSE",
        decisionAt = KWR.Util:Now() - 6,
    },
}
local longRotateSnapshot = KWR.Util:Copy(gilneasSnapshot)
longRotateSnapshot.strategy.planID = "BFG_ROTATE_MINE"
longRotateSnapshot.strategy.action = "ROTATE TO MINE"
longRotateSnapshot.strategy.objectiveDecision = {
    target = "Mine",
    success = "Arrive first and secure Mine.",
    abort = "Hold the current structure if the route closes.",
}
longRotateSnapshot.responsePackage = {
    qualified = false,
    target = "Mine",
    moverText = "Verite, Chosen",
    stayerText = "Lighthouse: Nrrdy",
}
KWR.Store.state.activePlay = KWR.Util:Copy(travelCommitState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(travelCommitState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(travelCommitState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(travelCommitState.command)
local travelCommitCommand = KWR.Commander:Compose(
    longRotateSnapshot, gilneasPrediction, liveState.assignments)
assert(travelCommitCommand.activePlayCandidate
    and (travelCommitCommand.activePlayCandidate.travelSeconds or 0) > 0
    and (travelCommitCommand.activePlayCandidate.commitmentSeconds or 0) > 18
    and math.abs((travelCommitCommand.activePlayCandidate.minimumCommitUntil - travelCommitCommand.createdAt)
        - (travelCommitCommand.activePlayCandidate.commitmentSeconds or 0)) < 0.001,
    "ActivePlay commitment window did not incorporate reviewed travel and execution timing on a long node rotation.")
local travelPersistenceState = KWR.Util:Copy(travelCommitState)
KWR.Store.state.activePlay = KWR.Util:Copy(travelPersistenceState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(travelPersistenceState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(travelPersistenceState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(travelPersistenceState.command)
local travelCandidateId = KWR.Util:Signature({
    "NODE",
    "BFG_ROTATE_MINE",
    "Mine",
    "ROTATE TO MINE",
    "Verite, Chosen",
})
KWR.Commander.candidateTrends[travelCandidateId] = {
    signature = travelCandidateId,
    firstPreferredAt = KWR.Util:Now() - 9,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 14,
    minimumAdvantage = 10,
}
local travelPersistenceCommand = KWR.Commander:Compose(
    longRotateSnapshot, gilneasPrediction, liveState.assignments)
local travelPersistenceScore = travelPersistenceCommand.activePlayDecision
    and travelPersistenceCommand.activePlayDecision.replacementScore
assert(travelPersistenceCommand.activePlayDecision
    and travelPersistenceCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE"
    and type(travelPersistenceScore) == "table"
    and (travelPersistenceScore.requiredDuration or 0) > 8
    and (travelPersistenceScore.observedDuration or 0) < (travelPersistenceScore.requiredDuration or 0),
    "Persistence gating did not scale up for a long reviewed node rotation candidate.")
local nodeCaptureSuccessState = {
    activePlay = {
        id = "ACTIVE_TAKE_MINE",
        family = "NODE",
        action = "TAKE MINE",
        objective = "Mine",
        movers = { "Verite", "Chosen", "Holic" },
        stayers = { "Nrrdy" },
        issuedAt = KWR.Util:Now() - 8,
        minimumCommitUntil = KWR.Util:Now() + 8,
        reviewAt = KWR.Util:Now() - 3,
        expectedArrivalAt = KWR.Util:Now() - 2,
        expectedResolutionAt = KWR.Util:Now() + 4,
        hardDeadlineAt = KWR.Util:Now() + 10,
        phase = "RESOLVING",
        remainingValue = 72,
    },
    command = {
        action = "TAKE MINE",
        who = "Verite, Chosen, Holic",
        when = "NOW",
        reason = "Finish the Mine capture.",
        signature = "ACTIVE_TAKE_MINE",
        decisionAt = KWR.Util:Now() - 8,
    },
}
local nodeCaptureSuccessSnapshot = KWR.Util:Copy(gilneasSnapshot)
nodeCaptureSuccessSnapshot.objectives.rows = {
    { label = "Lighthouse", owner = "FRIENDLY", state = "CONTROLLED", kind = "OBJECTIVE" },
    { label = "Waterworks", owner = "FRIENDLY", state = "CONTROLLED", kind = "OBJECTIVE" },
    { label = "Mine", owner = "FRIENDLY", state = "CONTROLLED", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(nodeCaptureSuccessState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(nodeCaptureSuccessState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(nodeCaptureSuccessState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(nodeCaptureSuccessState.command)
local succeededNodeCommand = KWR.Commander:Compose(
    nodeCaptureSuccessSnapshot, gilneasPrediction, liveState.assignments)
assert(succeededNodeCommand.activePlayDecision
    and succeededNodeCommand.activePlayDecision.invalidation == "PLAY_SUCCEEDED"
    and succeededNodeCommand.activePlayDecision.invalidationFamily == "SHARED"
    and succeededNodeCommand.activePlayDecision.gateClass == "INVALIDATION"
    and succeededNodeCommand.activePlayDecision.replacementAllowed == true
    and succeededNodeCommand.activePlayOutcome
    and succeededNodeCommand.activePlayOutcome.status == "SUCCEEDED",
    "Node-family assault/capture play did not resolve as succeeded when the target node was actually secured.")
assert(succeededNodeCommand.activePlayTransition
    and succeededNodeCommand.activePlayTransition.trigger == "SUCCESS"
    and succeededNodeCommand.activePlayTransition.rule == "PLAY_SUCCEEDED",
    "Succeeded active play did not publish a success transition.")
local postSuccessStability = KWR.Commander:GetStabilityMetrics()
assert((postSuccessStability.successfulPlays or 0) >= 1
    and type(postSuccessStability.successRate) == "number"
    and type(postSuccessStability.averageSwitchAdvantage) == "number",
    "Commander stability metrics did not track play success and switch advantage.")
local flagPreviousState = {
    activePlay = {
        id = "ACTIVE_ESCORT_OFC",
        family = "FLAG",
        action = "ESCORT OUR FC",
        objective = "Our FC",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 6,
        minimumCommitUntil = KWR.Util:Now() + 14,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 18,
        hardDeadlineAt = KWR.Util:Now() + 26,
        phase = "COMMITTED",
        remainingValue = 74,
    },
    command = {
        action = "ESCORT OUR FC",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Keep escort stable until the flag state changes.",
        signature = "ACTIVE_ESCORT_OFC",
        decisionAt = KWR.Util:Now() - 6,
    },
}
local flagSnapshot = {
    context = {
        mapKey = "WSG",
        mapName = "Warsong Gulch",
        kind = "FLAG",
        inPvP = true,
    },
    score = { friendly = 1, enemy = 1, max = 3, lastCapture = nil },
    objectives = {
        friendlyFlagActive = 1,
        enemyFlagActive = 1,
        flags = {
            { index = 1, x = 0.52, y = 0.48, texture = "flag" },
        },
        rows = {
            { label = "Home", owner = "UNKNOWN", state = "CARRIED", kind = "FLAG" },
            { label = "Enemy Flag Room", owner = "UNKNOWN", state = "CARRIED", kind = "FLAG" },
        },
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 78,
        planID = "WSG_PRESS_MID",
        action = "PRESS MID TO CREATE A PICK WINDOW",
        objectiveDecision = {
            target = "Mid",
            success = "Create a pick window without dropping escort.",
            abort = "Return to escort if the route opens.",
        },
        trust = { reason = "Both flags active; preserve escort discipline." },
    },
    responsePackage = {
        qualified = false,
        target = "Mid",
        moverText = "Verite, Holic, Lymrith",
        stayerText = "Our FC: Chosen, Nrrdy",
    },
}
local flagPrediction = {
    urgency = 42,
    status = "TIE",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(flagPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(flagPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(flagPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(flagPreviousState.command)
local flagCandidateId = KWR.Util:Signature({
    "FLAG",
    "WSG_PRESS_MID",
    "Mid",
    "PRESS MID TO CREATE A PICK WINDOW",
    "Verite, Holic, Lymrith",
})
KWR.Commander.candidateTrends[flagCandidateId] = {
    signature = flagCandidateId,
    firstPreferredAt = KWR.Util:Now() - 10,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 16,
    minimumAdvantage = 10,
}
local heldFlagCommand = KWR.Commander:Compose(
    flagSnapshot, flagPrediction, liveState.assignments)
local heldFlagScore = heldFlagCommand.activePlayDecision
    and heldFlagCommand.activePlayDecision.replacementScore
assert(heldFlagCommand.activePlayDecision
    and heldFlagCommand.activePlayDecision.retained == true
    and (heldFlagCommand.activePlayDecision.replacementReason == "NOT_MATERIALLY_SUPERIOR"
        or heldFlagCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE")
    and type(heldFlagScore) == "table"
    and (heldFlagScore.margin or 0) >= 24
    and type(heldFlagScore.switchCost) == "table"
    and (heldFlagScore.switchCost.total or 0) >= 18,
    "Flag-map escort play did not resist a low-value field-pressure switch while both flags were active.")
assert(heldFlagCommand.activePlay
    and heldFlagCommand.activePlay.milestone == "FC_STANDOFF"
    and heldFlagCommand.activePlay.phase == "COMMITTED"
    and type(heldFlagCommand.activePlayDecision.phaseReason) == "string"
    and heldFlagCommand.activePlayDecision.phaseReason:find("Both flags remain out", 1, true),
    "Flag-family active play did not reflect the live flag-stand-off milestone.")
local expiredEscortState = KWR.Util:Copy(flagPreviousState)
expiredEscortState.activePlay.expectedResolutionAt = KWR.Util:Now() - 10
expiredEscortState.activePlay.hardDeadlineAt = KWR.Util:Now() - 4
expiredEscortState.activePlay.phase = "COMMITTED"
KWR.Store.state.activePlay = KWR.Util:Copy(expiredEscortState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(expiredEscortState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(expiredEscortState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(expiredEscortState.command)
local heldExpiredEscortCommand = KWR.Commander:Compose(
    flagSnapshot, flagPrediction, liveState.assignments)
assert(heldExpiredEscortCommand.activePlayDecision
    and heldExpiredEscortCommand.activePlayDecision.invalidation == nil
    and heldExpiredEscortCommand.activePlay.phase == "COMMITTED",
    "Flag-family escort hold incorrectly expired just because a generic deadline elapsed.")
local invalidatedFlagSnapshot = KWR.Util:Copy(flagSnapshot)
invalidatedFlagSnapshot.score.lastCapture = nil
invalidatedFlagSnapshot.objectives.friendlyFlagActive = 0
invalidatedFlagSnapshot.objectives.enemyFlagActive = 1
invalidatedFlagSnapshot.objectives.rows = {
    { label = "Home", owner = "UNKNOWN", state = "AVAILABLE", kind = "FLAG" },
    { label = "Enemy Flag Room", owner = "UNKNOWN", state = "CARRIED", kind = "FLAG" },
}
local invalidatedFlagCommand = KWR.Commander:Compose(
    invalidatedFlagSnapshot, flagPrediction, liveState.assignments)
assert(invalidatedFlagCommand.activePlayDecision
    and invalidatedFlagCommand.activePlayDecision.invalidation == "FRIENDLY_FLAG_STATE_CHANGED"
    and invalidatedFlagCommand.activePlayDecision.replacementAllowed == true,
    "Flag-map escort play did not invalidate when the friendly flag state changed decisively.")
do
local flagReturnCommitState = {
    activePlay = {
        id = "ACTIVE_RETURN_EFC_HOLD",
        family = "FLAG",
        action = "RETURN ENEMY FC",
        objective = "Enemy FC",
        movers = { "Verite", "Chosen", "Nrrdy" },
        stayers = { "Holic", "Lymrith" },
        issuedAt = KWR.Util:Now() - 7,
        minimumCommitUntil = KWR.Util:Now() + 10,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 16,
        hardDeadlineAt = KWR.Util:Now() + 24,
        phase = "COMMITTED",
        remainingValue = 70,
    },
    command = {
        action = "RETURN ENEMY FC",
        who = "Verite, Chosen, Nrrdy",
        when = "NOW",
        reason = "Stay on the enemy flag carrier until the flag state changes.",
        signature = "ACTIVE_RETURN_EFC_HOLD",
        decisionAt = KWR.Util:Now() - 7,
    },
}
local twinPeaksSnapshot = KWR.Util:Copy(flagSnapshot)
twinPeaksSnapshot.context.mapKey = "TWINPEAKS"
twinPeaksSnapshot.context.mapName = "Twin Peaks"
twinPeaksSnapshot.strategy.planID = "TP_PRESS_MID"
twinPeaksSnapshot.strategy.action = "PRESS MID"
twinPeaksSnapshot.strategy.objectiveDecision = {
    target = "Mid",
    success = "Control midfield after the return team finishes.",
    abort = "Stay on EFC if the carrier state remains live.",
}
twinPeaksSnapshot.responsePackage = {
    qualified = false,
    target = "Mid",
    moverText = "Verite, Chosen, Nrrdy",
    stayerText = "Our FC: Holic, Lymrith",
}
KWR.Store.state.activePlay = KWR.Util:Copy(flagReturnCommitState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(flagReturnCommitState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(flagReturnCommitState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(flagReturnCommitState.command)
local twinCandidateId = KWR.Util:Signature({
    "FLAG",
    "TP_PRESS_MID",
    "Mid",
    "PRESS MID",
    "Verite, Chosen, Nrrdy",
})
KWR.Commander.candidateTrends[twinCandidateId] = {
    signature = twinCandidateId,
    firstPreferredAt = KWR.Util:Now() - 11,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 5,
    averageAdvantage = 18,
    minimumAdvantage = 12,
}
local twinReturnCommand = KWR.Commander:Compose(
    twinPeaksSnapshot, flagPrediction, liveState.assignments)
local twinReturnScore = twinReturnCommand.activePlayDecision
    and twinReturnCommand.activePlayDecision.replacementScore
local twinReturnRoutePenalty = 0
for _, component in ipairs(twinReturnScore and twinReturnScore.switchCost
    and twinReturnScore.switchCost.components or {}) do
    if component.label == "flag_route" then
        twinReturnRoutePenalty = component.value or 0
    end
end
assert(twinReturnCommand.activePlayDecision
    and twinReturnCommand.activePlayDecision.retained == true
    and type(twinReturnScore) == "table"
    and twinReturnRoutePenalty >= 4
    and (twinReturnScore.margin or 0) >= 28,
    "Twin Peaks return play did not apply route/base commitment cost against ordinary midfield pressure.")
local resetState = KWR.Util:Copy(flagReturnCommitState)
resetState.activePlay.id = "ACTIVE_RESET_FLAGS"
resetState.activePlay.action = "RESET FLAGS"
resetState.activePlay.objective = "Home"
resetState.activePlay.phase = "MOVING"
resetState.command.action = "RESET FLAGS"
resetState.command.signature = "ACTIVE_RESET_FLAGS"
KWR.Store.state.activePlay = KWR.Util:Copy(resetState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(resetState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(resetState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(resetState.command)
local twinResetCommand = KWR.Commander:Compose(
    twinPeaksSnapshot, flagPrediction, liveState.assignments)
local twinResetScore = twinResetCommand.activePlayDecision
    and twinResetCommand.activePlayDecision.replacementScore
local twinResetRoutePenalty = 0
local twinResetResetPenalty = 0
for _, component in ipairs(twinResetScore and twinResetScore.switchCost
    and twinResetScore.switchCost.components or {}) do
    if component.label == "flag_route" then
        twinResetRoutePenalty = component.value or 0
    elseif component.label == "flag_reset" then
        twinResetResetPenalty = component.value or 0
    end
end
assert(twinResetCommand.activePlayDecision
    and twinResetCommand.activePlayDecision.retained == true
    and type(twinResetScore) == "table"
    and twinResetResetPenalty >= 6
    and twinResetRoutePenalty >= 3,
    "Twin Peaks reset play did not resist a non-reset pivot while flags were still unsettled.")
end
local returnSuccessState = {
    activePlay = {
        id = "ACTIVE_RETURN_EFC",
        family = "FLAG",
        action = "RETURN ENEMY FC",
        objective = "Enemy FC",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 6,
        minimumCommitUntil = KWR.Util:Now() + 12,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 10,
        hardDeadlineAt = KWR.Util:Now() + 18,
        phase = "COMMITTED",
        remainingValue = 76,
    },
    command = {
        action = "RETURN ENEMY FC",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Return the enemy flag before pivoting.",
        signature = "ACTIVE_RETURN_EFC",
        decisionAt = KWR.Util:Now() - 6,
    },
}
local returnSuccessSnapshot = KWR.Util:Copy(flagSnapshot)
returnSuccessSnapshot.objectives.friendlyFlagActive = 0
returnSuccessSnapshot.objectives.enemyFlagActive = 0
returnSuccessSnapshot.objectives.rows = {
    { label = "Home", owner = "UNKNOWN", state = "AVAILABLE", kind = "FLAG" },
    { label = "Enemy Flag Room", owner = "UNKNOWN", state = "CARRIED", kind = "FLAG" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(returnSuccessState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(returnSuccessState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(returnSuccessState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(returnSuccessState.command)
local successMetricsBefore = KWR.Commander:GetStabilityMetrics()
local succeededReturnCommand = KWR.Commander:Compose(
    returnSuccessSnapshot, flagPrediction, liveState.assignments)
assert(succeededReturnCommand.activePlayDecision
    and succeededReturnCommand.activePlayDecision.invalidation == "PLAY_SUCCEEDED"
    and succeededReturnCommand.activePlayDecision.replacementAllowed == true,
    "Flag-family return play did not resolve as succeeded when the enemy flag was no longer active and home reset was available.")
local successMetricsAfter = KWR.Commander:GetStabilityMetrics()
assert(successMetricsAfter.successfulPlays == (successMetricsBefore.successfulPlays or 0) + 1
    and successMetricsAfter.invalidations == (successMetricsBefore.invalidations or 0) + 1
    and successMetricsAfter.successRate > 0,
    "Commander success accounting did not record a resolved ActivePlay for field certification.")
local orbPreviousState = {
    activePlay = {
        id = "ACTIVE_CENTER_CONTROL",
        family = "ORB",
        action = "CONTROL CENTER WITH ORB SUPPORT",
        objective = "Center",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 5,
        minimumCommitUntil = KWR.Util:Now() + 10,
        reviewAt = KWR.Util:Now() - 1,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 14,
        hardDeadlineAt = KWR.Util:Now() + 20,
        phase = "COMMITTED",
        remainingValue = 72,
    },
    command = {
        action = "CONTROL CENTER WITH ORB SUPPORT",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Keep carrier support stable until orb ownership changes.",
        signature = "ACTIVE_CENTER_CONTROL",
        decisionAt = KWR.Util:Now() - 5,
    },
}
local orbSnapshot = {
    context = {
        mapKey = "TEMPLE",
        mapName = "Temple of Kotmogu",
        kind = "ORB",
        inPvP = true,
    },
    score = { friendly = 900, enemy = 820, max = 1500 },
    objectives = {
        carriers = {
            {
                objective = "Green Orb",
                owner = "FRIENDLY",
                player = "Verite",
                healthPercent = 78,
                stacks = 4,
                kind = "ORB",
            },
            {
                objective = "Purple Orb",
                owner = "ENEMY",
                player = "EnemyCarrier",
                healthPercent = 62,
                stacks = 3,
                kind = "ORB",
            },
        },
        rows = {
            { label = "Center", owner = "UNKNOWN", state = "ACTIVE", kind = "OBJECTIVE" },
            { label = "Green Orb", owner = "FRIENDLY", state = "CARRIED", kind = "OBJECTIVE" },
            { label = "Purple Orb", owner = "ENEMY", state = "CARRIED", kind = "OBJECTIVE" },
        },
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 76,
        planID = "TEMPLE_HUNT_PURPLE",
        action = "FOCUS ENEMY CARRIER ON THE NEXT WINDOW",
        objectiveDecision = {
            target = "Enemy Carrier",
            success = "Force a clean orb drop.",
            abort = "Keep center support if the enemy carrier stays covered.",
        },
        trust = { reason = "Two active carriers; preserve scoring shape until the kill window is real." },
    },
    responsePackage = {
        qualified = false,
        target = "Enemy Carrier",
        moverText = "Verite, Holic, Lymrith",
        stayerText = "Center: Chosen, Nrrdy",
    },
}
local orbPrediction = {
    urgency = 46,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(orbPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(orbPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(orbPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(orbPreviousState.command)
local orbCandidateId = KWR.Util:Signature({
    "ORB",
    "TEMPLE_HUNT_PURPLE",
    "Enemy Carrier",
    "FOCUS ENEMY CARRIER ON THE NEXT WINDOW",
    "Verite, Holic, Lymrith",
})
KWR.Commander.candidateTrends[orbCandidateId] = {
    signature = orbCandidateId,
    firstPreferredAt = KWR.Util:Now() - 9,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 12,
    minimumAdvantage = 8,
}
local heldOrbCommand = KWR.Commander:Compose(
    orbSnapshot, orbPrediction, liveState.assignments)
local heldOrbScore = heldOrbCommand.activePlayDecision
    and heldOrbCommand.activePlayDecision.replacementScore
assert(heldOrbCommand.activePlayDecision
    and heldOrbCommand.activePlayDecision.retained == true
    and (heldOrbCommand.activePlayDecision.replacementReason == "NOT_MATERIALLY_SUPERIOR"
        or heldOrbCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE")
    and type(heldOrbScore) == "table"
    and (heldOrbScore.margin or 0) >= 18
    and type(heldOrbScore.switchCost) == "table"
    and (heldOrbScore.switchCost.total or 0) >= 10,
    "Orb-map center/carrier control did not resist a low-value hunt switch during stable orb ownership.")
assert(heldOrbCommand.activePlay
    and heldOrbCommand.activePlay.milestone == "CENTER_CONTEST"
    and heldOrbCommand.activePlay.phase == "COMMITTED",
    "Orb-family active play did not reflect the live center/carrier milestone.")
local invalidatedOrbSnapshot = KWR.Util:Copy(orbSnapshot)
invalidatedOrbSnapshot.objectives.carriers = {
    {
        objective = "Purple Orb",
        owner = "ENEMY",
        player = "EnemyCarrier",
        healthPercent = 58,
        stacks = 4,
        kind = "ORB",
    },
}
local invalidatedOrbCommand = KWR.Commander:Compose(
    invalidatedOrbSnapshot, orbPrediction, liveState.assignments)
assert(invalidatedOrbCommand.activePlayDecision
    and (invalidatedOrbCommand.activePlayDecision.invalidation == "ORBS_RESET"
        or invalidatedOrbCommand.activePlayDecision.invalidation == "FRIENDLY_ORB_STATE_CHANGED")
    and invalidatedOrbCommand.activePlayDecision.replacementAllowed == true,
    "Orb-map center/carrier play did not invalidate when friendly orb ownership changed decisively.")
local orbPickupState = {
    activePlay = {
        id = "ACTIVE_PICKUP_PURPLE",
        family = "ORB",
        action = "PICK UP PURPLE ORB",
        objective = "Purple Orb",
        movers = { "Verite", "Holic" },
        stayers = { "Chosen" },
        issuedAt = KWR.Util:Now() - 4,
        minimumCommitUntil = KWR.Util:Now() + 8,
        reviewAt = KWR.Util:Now() - 1,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 10,
        hardDeadlineAt = KWR.Util:Now() + 14,
        phase = "MOVING",
        remainingValue = 58,
    },
    command = {
        action = "PICK UP PURPLE ORB",
        who = "Verite, Holic",
        when = "NOW",
        reason = "Secure the free purple orb before rotating back center.",
        signature = "ACTIVE_PICKUP_PURPLE",
        decisionAt = KWR.Util:Now() - 4,
    },
}
local orbPickupSnapshot = KWR.Util:Copy(orbSnapshot)
orbPickupSnapshot.objectives.carriers = {}
orbPickupSnapshot.objectives.rows = {
    { label = "Purple Orb", owner = "ENEMY", state = "CARRIED", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(orbPickupState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(orbPickupState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(orbPickupState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(orbPickupState.command)
local invalidatedOrbPickupCommand = KWR.Commander:Compose(
    orbPickupSnapshot, orbPrediction, liveState.assignments)
assert(invalidatedOrbPickupCommand.activePlayDecision
    and invalidatedOrbPickupCommand.activePlayDecision.invalidation == "FRIENDLY_ORB_STATE_CHANGED"
    and invalidatedOrbPickupCommand.activePlayDecision.replacementAllowed == true,
    "Orb pickup play did not invalidate when the targeted orb was no longer free.")
local cartPreviousState = {
    activePlay = {
        id = "ACTIVE_ESCORT_LAVA",
        family = "CART",
        action = "ESCORT LAVA CART",
        objective = "Lava",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 6,
        minimumCommitUntil = KWR.Util:Now() + 12,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 16,
        hardDeadlineAt = KWR.Util:Now() + 24,
        phase = "COMMITTED",
        remainingValue = 70,
    },
    command = {
        action = "ESCORT LAVA CART",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Keep the scoring cart stable until the lane state changes.",
        signature = "ACTIVE_ESCORT_LAVA",
        decisionAt = KWR.Util:Now() - 6,
    },
}
local cartSnapshot = {
    context = {
        mapKey = "SILVERSHARD",
        mapName = "Silvershard Mines",
        kind = "CART",
        inPvP = true,
    },
    score = { friendly = 1200, enemy = 1090, max = 1500 },
    objectives = {
        vehicles = {
            { name = "Lava Cart", x = 0.30, y = 0.72, atlas = "cart" },
            { name = "Water Cart", x = 0.52, y = 0.56, atlas = "cart" },
        },
        rows = {
            { label = "Lava", owner = "FRIENDLY", state = "CONTROLLED", kind = "OBJECTIVE" },
            { label = "Water", owner = "ENEMY", state = "ACTIVE", kind = "OBJECTIVE" },
            { label = "Top", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
        },
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 74,
        planID = "SSM_SWAP_TOP",
        action = "ROTATE TO TOP AND CONTEST THE NEXT CART",
        objectiveDecision = {
            target = "Top",
            success = "Create a better contest lane without dropping current progress.",
            abort = "Stay on Lava if the escort lane remains live.",
        },
        trust = { reason = "Current escort lane is still scoring; do not abandon it casually." },
    },
    responsePackage = {
        qualified = false,
        target = "Top",
        moverText = "Verite, Holic, Lymrith",
        stayerText = "Lava: Chosen, Nrrdy",
    },
}
local cartPrediction = {
    urgency = 48,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(cartPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(cartPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(cartPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(cartPreviousState.command)
local cartCandidateId = KWR.Util:Signature({
    "CART",
    "SSM_SWAP_TOP",
    "Top",
    "ROTATE TO TOP AND CONTEST THE NEXT CART",
    "Verite, Holic, Lymrith",
})
KWR.Commander.candidateTrends[cartCandidateId] = {
    signature = cartCandidateId,
    firstPreferredAt = KWR.Util:Now() - 10,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 13,
    minimumAdvantage = 8,
}
local heldCartCommand = KWR.Commander:Compose(
    cartSnapshot, cartPrediction, liveState.assignments)
local heldCartScore = heldCartCommand.activePlayDecision
    and heldCartCommand.activePlayDecision.replacementScore
assert(heldCartCommand.activePlayDecision
    and heldCartCommand.activePlayDecision.retained == true
    and (heldCartCommand.activePlayDecision.replacementReason == "NOT_MATERIALLY_SUPERIOR"
        or heldCartCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE")
    and type(heldCartScore) == "table"
    and (heldCartScore.margin or 0) >= 18
    and type(heldCartScore.switchCost) == "table"
    and (heldCartScore.switchCost.total or 0) >= 10,
    "Cart-map escort play did not resist a low-value lane swap while the current cart lane stayed live.")
assert(heldCartCommand.activePlay
    and heldCartCommand.activePlay.milestone == "FRIENDLY_CART_LIVE"
    and heldCartCommand.activePlay.phase == "COMMITTED",
    "Cart-family active play did not reflect the live escort-lane milestone.")
local expiredEscortCartState = KWR.Util:Copy(cartPreviousState)
expiredEscortCartState.activePlay.expectedResolutionAt = KWR.Util:Now() - 8
expiredEscortCartState.activePlay.hardDeadlineAt = KWR.Util:Now() - 3
expiredEscortCartState.activePlay.phase = "COMMITTED"
KWR.Store.state.activePlay = KWR.Util:Copy(expiredEscortCartState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(expiredEscortCartState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(expiredEscortCartState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(expiredEscortCartState.command)
local heldExpiredCartEscortCommand = KWR.Commander:Compose(
    cartSnapshot, cartPrediction, liveState.assignments)
assert(heldExpiredCartEscortCommand.activePlayDecision
    and heldExpiredCartEscortCommand.activePlayDecision.invalidation == nil
    and heldExpiredCartEscortCommand.activePlay.phase == "COMMITTED",
    "Cart-family escort hold incorrectly expired just because a generic deadline elapsed.")
local invalidatedCartSnapshot = KWR.Util:Copy(cartSnapshot)
invalidatedCartSnapshot.objectives.vehicles = {}
invalidatedCartSnapshot.objectives.rows = {
    { label = "Lava", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
    { label = "Water", owner = "ENEMY", state = "CONTROLLED", kind = "OBJECTIVE" },
    { label = "Top", owner = "UNKNOWN", state = "ACTIVE", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(cartPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(cartPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(cartPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(cartPreviousState.command)
local invalidatedCartCommand = KWR.Commander:Compose(
    invalidatedCartSnapshot, cartPrediction, liveState.assignments)
assert(invalidatedCartCommand.activePlayDecision
    and invalidatedCartCommand.activePlayDecision.invalidation == "FRIENDLY_CART_STATE_CHANGED"
    and invalidatedCartCommand.activePlayDecision.replacementAllowed == true,
    "Cart-map escort play did not invalidate when the friendly cart lane state changed decisively.")
local shiftedCartSnapshot = KWR.Util:Copy(cartSnapshot)
shiftedCartSnapshot.objectives.vehicles = {
    { name = "Water Cart", x = 0.52, y = 0.56, atlas = "cart" },
}
shiftedCartSnapshot.objectives.rows = {
    { label = "Lava", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
    { label = "Water", owner = "ENEMY", state = "ACTIVE", kind = "OBJECTIVE" },
    { label = "Top", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(cartPreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(cartPreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(cartPreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(cartPreviousState.command)
local shiftedCartCommand = KWR.Commander:Compose(
    shiftedCartSnapshot, cartPrediction, liveState.assignments)
assert(shiftedCartCommand.activePlayDecision
    and shiftedCartCommand.activePlayDecision.invalidation == "FRIENDLY_CART_STATE_CHANGED"
    and shiftedCartCommand.activePlayDecision.replacementAllowed == true,
    "Cart escort play did not invalidate when its targeted lane died even though another cart remained active.")
do
local deephaulCartState = {
    activePlay = {
        id = "ACTIVE_ESCORT_OUR_CART",
        family = "CART",
        action = "ESCORT OUR CART",
        objective = "Our Cart",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 6,
        minimumCommitUntil = KWR.Util:Now() + 12,
        reviewAt = KWR.Util:Now() - 2,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 16,
        hardDeadlineAt = KWR.Util:Now() + 24,
        phase = "COMMITTED",
        remainingValue = 72,
    },
    command = {
        action = "ESCORT OUR CART",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Keep the cart moving unless the crystal is actually worth the switch.",
        signature = "ACTIVE_ESCORT_OUR_CART",
        decisionAt = KWR.Util:Now() - 6,
    },
}
local deephaulSnapshot = {
    context = {
        mapKey = "DEEPHAUL",
        mapName = "Deephaul Ravine",
        kind = "CART",
        inPvP = true,
    },
    score = { friendly = 900, enemy = 860, max = 1500 },
    objectives = {
        vehicles = {
            { name = "Friendly Cart", x = 0.30, y = 0.70, atlas = "cart" },
            { name = "Enemy Cart", x = 0.72, y = 0.28, atlas = "cart" },
        },
        rows = {
            { label = "Our Cart", owner = "FRIENDLY", state = "CONTROLLED", kind = "OBJECTIVE" },
            { label = "Enemy Cart", owner = "ENEMY", state = "ACTIVE", kind = "OBJECTIVE" },
            { label = "Crystal", owner = "UNKNOWN", state = "ACTIVE", kind = "OBJECTIVE" },
        },
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 74,
        planID = "DHR_CRYSTAL_PIVOT",
        action = "TAKE CRYSTAL",
        objectiveDecision = {
            target = "Crystal",
            success = "Secure crystal without dropping cart progress.",
            abort = "Stay with the cart if the crystal is not decisive.",
        },
        trust = { reason = "Crystal is useful, but cart progress is already live." },
    },
    responsePackage = {
        qualified = false,
        target = "Crystal",
        moverText = "Verite, Holic, Lymrith",
        stayerText = "Our Cart: Chosen, Nrrdy",
    },
}
local deephaulPrediction = {
    urgency = 42,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(deephaulCartState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(deephaulCartState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(deephaulCartState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(deephaulCartState.command)
local deephaulCrystalCandidateId = KWR.Util:Signature({
    "CART",
    "DHR_CRYSTAL_PIVOT",
    "Crystal",
    "TAKE CRYSTAL",
    "Verite, Holic, Lymrith",
})
KWR.Commander.candidateTrends[deephaulCrystalCandidateId] = {
    signature = deephaulCrystalCandidateId,
    firstPreferredAt = KWR.Util:Now() - 10,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 14,
    minimumAdvantage = 9,
}
local heldDeephaulCartCommand = KWR.Commander:Compose(
    deephaulSnapshot, deephaulPrediction, liveState.assignments)
local heldDeephaulCartScore = heldDeephaulCartCommand.activePlayDecision
    and heldDeephaulCartCommand.activePlayDecision.replacementScore
local deephaulCrystalOpportunityPenalty = 0
for _, component in ipairs(heldDeephaulCartScore and heldDeephaulCartScore.switchCost
    and heldDeephaulCartScore.switchCost.components or {}) do
    if component.label == "cart_crystal_opportunity" then
        deephaulCrystalOpportunityPenalty = component.value or 0
    end
end
assert(heldDeephaulCartCommand.activePlayDecision
    and heldDeephaulCartCommand.activePlayDecision.retained == true
    and type(heldDeephaulCartScore) == "table"
    and deephaulCrystalOpportunityPenalty >= 6
    and (heldDeephaulCartScore.margin or 0) >= 24,
    "Deephaul cart play did not resist a non-decisive crystal pivot while cart progress was live.")
local deephaulCrystalState = KWR.Util:Copy(deephaulCartState)
deephaulCrystalState.activePlay.id = "ACTIVE_TAKE_CRYSTAL"
deephaulCrystalState.activePlay.action = "TAKE CRYSTAL"
deephaulCrystalState.activePlay.objective = "Crystal"
deephaulCrystalState.activePlay.phase = "COMMITTED"
deephaulCrystalState.command.action = "TAKE CRYSTAL"
deephaulCrystalState.command.signature = "ACTIVE_TAKE_CRYSTAL"
local deephaulCartPivotSnapshot = KWR.Util:Copy(deephaulSnapshot)
deephaulCartPivotSnapshot.strategy.planID = "DHR_CART_PIVOT"
deephaulCartPivotSnapshot.strategy.action = "ESCORT OUR CART"
deephaulCartPivotSnapshot.strategy.objectiveDecision = {
    target = "Our Cart",
    success = "Return to cart after crystal control is settled.",
    abort = "Stay on crystal if it is still active.",
}
deephaulCartPivotSnapshot.responsePackage = {
    qualified = false,
    target = "Our Cart",
    moverText = "Verite, Holic, Lymrith",
    stayerText = "Crystal: Chosen, Nrrdy",
}
KWR.Store.state.activePlay = KWR.Util:Copy(deephaulCrystalState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(deephaulCrystalState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(deephaulCrystalState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(deephaulCrystalState.command)
local deephaulCartCandidateId = KWR.Util:Signature({
    "CART",
    "DHR_CART_PIVOT",
    "Our Cart",
    "ESCORT OUR CART",
    "Verite, Holic, Lymrith",
})
KWR.Commander.candidateTrends[deephaulCartCandidateId] = {
    signature = deephaulCartCandidateId,
    firstPreferredAt = KWR.Util:Now() - 8,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 12,
    minimumAdvantage = 8,
}
local heldDeephaulCrystalCommand = KWR.Commander:Compose(
    deephaulCartPivotSnapshot, deephaulPrediction, liveState.assignments)
local heldDeephaulCrystalScore = heldDeephaulCrystalCommand.activePlayDecision
    and heldDeephaulCrystalCommand.activePlayDecision.replacementScore
local deephaulCrystalHoldPenalty = 0
for _, component in ipairs(heldDeephaulCrystalScore and heldDeephaulCrystalScore.switchCost
    and heldDeephaulCrystalScore.switchCost.components or {}) do
    if component.label == "cart_crystal_opportunity" then
        deephaulCrystalHoldPenalty = component.value or 0
    end
end
assert(heldDeephaulCrystalCommand.activePlayDecision
    and heldDeephaulCrystalCommand.activePlayDecision.retained == true
    and type(heldDeephaulCrystalScore) == "table"
    and deephaulCrystalHoldPenalty >= 4,
    "Deephaul crystal play did not resist an ordinary cart pivot while the crystal was still active.")
end
local resourcePreviousState = {
    activePlay = {
        id = "ACTIVE_CAPTURE_NODE",
        family = "RESOURCE",
        action = "CAPTURE ACTIVE NODE",
        objective = "Active Node",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 5,
        minimumCommitUntil = KWR.Util:Now() + 10,
        reviewAt = KWR.Util:Now() - 1,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 14,
        hardDeadlineAt = KWR.Util:Now() + 20,
        phase = "COMMITTED",
        remainingValue = 69,
    },
    command = {
        action = "CAPTURE ACTIVE NODE",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Finish the live node before pivoting to the next spawn.",
        signature = "ACTIVE_CAPTURE_NODE",
        decisionAt = KWR.Util:Now() - 5,
    },
}
local resourceSnapshot = {
    context = {
        mapKey = "SEETHING",
        mapName = "Seething Shore",
        kind = "RESOURCE",
        inPvP = true,
    },
    score = { friendly = 1180, enemy = 1100, max = 1500 },
    objectives = {
        rows = {
            { label = "Active Node", owner = "UNKNOWN", state = "ACTIVE", kind = "OBJECTIVE" },
            { label = "Next Spawn", owner = "UNKNOWN", state = "ACTIVE", kind = "OBJECTIVE" },
            { label = "Center", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
        },
    },
    strategy = {
        confidence = "HIGH",
        decisionScore = 73,
        planID = "SHORE_SWAP_NEXT",
        action = "ROTATE EARLY TO THE NEXT SPAWN",
        objectiveDecision = {
            target = "Next Spawn",
            success = "Arrive first without dropping the current node for free.",
            abort = "Finish the live node if the active contest remains viable.",
        },
        trust = { reason = "Live node remains active; do not abandon it for a speculative next spawn." },
    },
    responsePackage = {
        qualified = false,
        target = "Next Spawn",
        moverText = "Verite, Holic, Lymrith",
        stayerText = "Active Node: Chosen, Nrrdy",
    },
}
local resourcePrediction = {
    urgency = 44,
    status = "WIN",
    confidence = "HIGH",
}
KWR.Store.state.activePlay = KWR.Util:Copy(resourcePreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(resourcePreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(resourcePreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(resourcePreviousState.command)
local resourceCandidateId = KWR.Util:Signature({
    "RESOURCE",
    "SHORE_SWAP_NEXT",
    "Next Spawn",
    "ROTATE EARLY TO THE NEXT SPAWN",
    "Verite, Holic, Lymrith",
})
KWR.Commander.candidateTrends[resourceCandidateId] = {
    signature = resourceCandidateId,
    firstPreferredAt = KWR.Util:Now() - 9,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 11,
    minimumAdvantage = 7,
}
local heldResourceCommand = KWR.Commander:Compose(
    resourceSnapshot, resourcePrediction, liveState.assignments)
local heldResourceScore = heldResourceCommand.activePlayDecision
    and heldResourceCommand.activePlayDecision.replacementScore
local resourceSpawnOpportunityPenalty = 0
for _, component in ipairs(heldResourceScore and heldResourceScore.switchCost
    and heldResourceScore.switchCost.components or {}) do
    if component.label == "resource_spawn_opportunity" then
        resourceSpawnOpportunityPenalty = component.value or 0
    end
end
assert(heldResourceCommand.activePlayDecision
    and heldResourceCommand.activePlayDecision.retained == true
    and (heldResourceCommand.activePlayDecision.replacementReason == "NOT_MATERIALLY_SUPERIOR"
        or heldResourceCommand.activePlayDecision.replacementReason == "INSUFFICIENT_PERSISTENCE")
    and type(heldResourceScore) == "table"
    and resourceSpawnOpportunityPenalty >= 5
    and (heldResourceScore.margin or 0) >= 18
    and type(heldResourceScore.switchCost) == "table"
    and (heldResourceScore.switchCost.total or 0) >= 8,
    "Resource-map active-node play did not resist a low-value early next-spawn swap.")
assert(heldResourceCommand.activePlay
    and heldResourceCommand.activePlay.milestone == "ACTIVE_NODE_LIVE"
    and heldResourceCommand.activePlay.phase == "COMMITTED",
    "Resource-family active play did not reflect the live active-node milestone.")
local invalidatedResourceSnapshot = KWR.Util:Copy(resourceSnapshot)
invalidatedResourceSnapshot.objectives.rows = {
    { label = "Active Node", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
    { label = "Center", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(resourcePreviousState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(resourcePreviousState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(resourcePreviousState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(resourcePreviousState.command)
local invalidatedResourceCommand = KWR.Commander:Compose(
    invalidatedResourceSnapshot, resourcePrediction, liveState.assignments)
assert(invalidatedResourceCommand.activePlayDecision
    and invalidatedResourceCommand.activePlayDecision.invalidation == "ACTIVE_NODE_STATE_CHANGED"
    and invalidatedResourceCommand.activePlayDecision.replacementAllowed == true,
    "Resource-map active-node play did not invalidate when the live node state changed decisively.")
local specificResourceState = {
    activePlay = {
        id = "ACTIVE_CAPTURE_CENTER",
        family = "RESOURCE",
        action = "CAPTURE CENTER NODE",
        objective = "Center",
        movers = { "Verite", "Holic", "Lymrith" },
        stayers = { "Chosen", "Nrrdy" },
        issuedAt = KWR.Util:Now() - 4,
        minimumCommitUntil = KWR.Util:Now() + 8,
        reviewAt = KWR.Util:Now() - 1,
        expectedArrivalAt = KWR.Util:Now() - 1,
        expectedResolutionAt = KWR.Util:Now() + 12,
        hardDeadlineAt = KWR.Util:Now() + 18,
        phase = "COMMITTED",
        remainingValue = 62,
    },
    command = {
        action = "CAPTURE CENTER NODE",
        who = "Verite, Holic, Lymrith",
        when = "NOW",
        reason = "Finish the Center node before rotating elsewhere.",
        signature = "ACTIVE_CAPTURE_CENTER",
        decisionAt = KWR.Util:Now() - 4,
    },
}
local shiftedSpecificResourceSnapshot = KWR.Util:Copy(resourceSnapshot)
shiftedSpecificResourceSnapshot.objectives.rows = {
    { label = "Center", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
    { label = "South", owner = "UNKNOWN", state = "ACTIVE", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(specificResourceState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(specificResourceState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(specificResourceState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(specificResourceState.command)
local shiftedSpecificResourceCommand = KWR.Commander:Compose(
    shiftedSpecificResourceSnapshot, resourcePrediction, liveState.assignments)
assert(shiftedSpecificResourceCommand.activePlayDecision
    and shiftedSpecificResourceCommand.activePlayDecision.invalidation == "ACTIVE_NODE_STATE_CHANGED"
    and shiftedSpecificResourceCommand.activePlayDecision.replacementAllowed == true,
    "Resource active-node play did not invalidate when its specific target node died even though another node remained active.")
do
local spawnHoldState = {
    activePlay = {
        id = "ACTIVE_ROTATE_NEXT_SPAWN",
        family = "RESOURCE",
        action = "ROTATE TO NEXT SPAWN",
        objective = "Next Spawn",
        movers = { "Verite", "Holic" },
        stayers = { "Chosen" },
        issuedAt = KWR.Util:Now() - 3,
        minimumCommitUntil = KWR.Util:Now() + 9,
        reviewAt = KWR.Util:Now() - 1,
        expectedArrivalAt = KWR.Util:Now() + 2,
        expectedResolutionAt = KWR.Util:Now() + 12,
        hardDeadlineAt = KWR.Util:Now() + 16,
        phase = "MOVING",
        remainingValue = 60,
    },
    command = {
        action = "ROTATE TO NEXT SPAWN",
        who = "Verite, Holic",
        when = "NEXT FIGHT",
        reason = "Beat the enemy to the next spawn before returning to an active node.",
        signature = "ACTIVE_ROTATE_NEXT_SPAWN",
        decisionAt = KWR.Util:Now() - 3,
    },
}
local spawnHoldSnapshot = KWR.Util:Copy(resourceSnapshot)
spawnHoldSnapshot.strategy.planID = "SHORE_BACK_TO_ACTIVE"
spawnHoldSnapshot.strategy.action = "CAPTURE ACTIVE NODE"
spawnHoldSnapshot.strategy.objectiveDecision = {
    target = "Active Node",
    success = "Finish the live node after the spawn route is no longer valuable.",
    abort = "Keep moving to the spawn if it remains active.",
}
spawnHoldSnapshot.responsePackage = {
    qualified = false,
    target = "Active Node",
    moverText = "Verite, Holic",
    stayerText = "Next Spawn: Chosen",
}
KWR.Store.state.activePlay = KWR.Util:Copy(spawnHoldState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(spawnHoldState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(spawnHoldState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(spawnHoldState.command)
local spawnHoldCandidateId = KWR.Util:Signature({
    "RESOURCE",
    "SHORE_BACK_TO_ACTIVE",
    "Active Node",
    "CAPTURE ACTIVE NODE",
    "Verite, Holic",
})
KWR.Commander.candidateTrends[spawnHoldCandidateId] = {
    signature = spawnHoldCandidateId,
    firstPreferredAt = KWR.Util:Now() - 7,
    lastPreferredAt = KWR.Util:Now() - 1,
    consecutiveWins = 4,
    averageAdvantage = 10,
    minimumAdvantage = 7,
}
local heldSpawnCommand = KWR.Commander:Compose(
    spawnHoldSnapshot, resourcePrediction, liveState.assignments)
local heldSpawnScore = heldSpawnCommand.activePlayDecision
    and heldSpawnCommand.activePlayDecision.replacementScore
local heldSpawnOpportunityPenalty = 0
for _, component in ipairs(heldSpawnScore and heldSpawnScore.switchCost
    and heldSpawnScore.switchCost.components or {}) do
    if component.label == "resource_spawn_opportunity" then
        heldSpawnOpportunityPenalty = component.value or 0
    end
end
assert(heldSpawnCommand.activePlayDecision
    and heldSpawnCommand.activePlayDecision.retained == true
    and type(heldSpawnScore) == "table"
    and heldSpawnOpportunityPenalty >= 4,
    "Seething next-spawn play did not resist an ordinary active-node pivot while the spawn remained live.")
end
local spawnResourceState = {
    activePlay = {
        id = "ACTIVE_ROTATE_SOUTH_SPAWN",
        family = "RESOURCE",
        action = "ROTATE TO SOUTH SPAWN",
        objective = "South",
        movers = { "Verite", "Holic" },
        stayers = { "Chosen" },
        issuedAt = KWR.Util:Now() - 3,
        minimumCommitUntil = KWR.Util:Now() + 7,
        reviewAt = KWR.Util:Now() - 1,
        expectedArrivalAt = KWR.Util:Now() + 2,
        expectedResolutionAt = KWR.Util:Now() + 10,
        hardDeadlineAt = KWR.Util:Now() + 14,
        phase = "MOVING",
        remainingValue = 54,
    },
    command = {
        action = "ROTATE TO SOUTH SPAWN",
        who = "Verite, Holic",
        when = "NEXT FIGHT",
        reason = "Beat the enemy to the South spawn.",
        signature = "ACTIVE_ROTATE_SOUTH_SPAWN",
        decisionAt = KWR.Util:Now() - 3,
    },
}
local deadSpawnResourceSnapshot = KWR.Util:Copy(resourceSnapshot)
deadSpawnResourceSnapshot.objectives.rows = {
    { label = "South", owner = "ENEMY", state = "CONTROLLED", kind = "OBJECTIVE" },
    { label = "Center", owner = "UNKNOWN", state = "AVAILABLE", kind = "OBJECTIVE" },
}
KWR.Store.state.activePlay = KWR.Util:Copy(spawnResourceState.activePlay)
KWR.Store.state.command = KWR.Util:Copy(spawnResourceState.command)
KWR.Commander.lastActivePlay = KWR.Util:Copy(spawnResourceState.activePlay)
KWR.Commander.lastCommand = KWR.Util:Copy(spawnResourceState.command)
local deadSpawnResourceCommand = KWR.Commander:Compose(
    deadSpawnResourceSnapshot, resourcePrediction, liveState.assignments)
assert(deadSpawnResourceCommand.activePlayDecision
    and deadSpawnResourceCommand.activePlayDecision.invalidation == "NEXT_SPAWN_STATE_CHANGED"
    and deadSpawnResourceCommand.activePlayDecision.replacementAllowed == true,
    "Resource spawn play did not invalidate when its specific target spawn was no longer free.")
local liveLine1, liveLine2 = KWR.CommandView:SummaryLines(liveState)
assert(liveLine2:find("ACTION:", 1, true), "Commander view did not publish an ACTION line.")
local healerSeen, friendlyLeak = false, false
for _, enemy in ipairs(liveState.snapshot.enemies or {}) do
    if enemy.shortName == "EnemyHealer" then healerSeen = true end
    if enemy.shortName == "TestPlayer" then friendlyLeak = true end
end
assert(healerSeen and not friendlyLeak,
    "Scoreboard faction detection did not follow the assigned team.")
local filteredEnemies = KWR.EnemyIntel:FilterPublishedTruth({
    { key = "ALLY-1", guid = "ALLY-1", name = "FriendlyOne-TestRealm" },
}, {
    { key = "ALLY-1", guid = "ALLY-1", name = "FriendlyOne-TestRealm", faction = 0 },
    { key = "ROW-ALLY", guid = "ROW-ALLY", name = "MysteryFriendly-TestRealm", faction = 0 },
    { key = "ROW-ENEMY", guid = "ROW-ENEMY", name = "ActualEnemy-TestRealm", faction = 1 },
    { key = "TARGET-ENEMY", guid = "TARGET-ENEMY", name = "ActualEnemy-TestRealm",
        faction = 1, visible = true, localEngaged = true },
}, liveState.snapshot.context.team.scoreFaction)
assert(#filteredEnemies == 1 and filteredEnemies[1].key == "TARGET-ENEMY"
    and filteredEnemies[1].localEngaged == true,
    "Enemy filter did not remove friendlies or collapse transient aliases to the best truth record.")
do
    local blitzRows = {}
    for faction = 0, 1 do
        for index = 1, 8 do
            blitzRows[#blitzRows + 1] = {
                faction = faction,
                guid = string.format("Player-%d-%d", faction, index),
                name = string.format("Player%d%d-TestRealm", faction, index),
            }
        end
    end
    local detected, evidence = KWR.TeamResolver:DetectBlitz(blitzRows)
    assert(detected == true and evidence.horde == 8 and evidence.alliance == 8,
        "Exact 8v8 scoreboard truth did not identify a Blitz session.")
    table.remove(blitzRows)
    assert(KWR.TeamResolver:DetectBlitz(blitzRows) == false,
        "Partial scoreboard truth incorrectly identified a Blitz session.")

    local friendlyRows = {}
    for index = 1, 8 do
        friendlyRows[index] = {
            faction = 0,
            guid = "Friendly-" .. index,
            name = "Friendly" .. index .. "-TestRealm",
            class = "Warrior",
            classFile = "WARRIOR",
            role = "DAMAGER",
        }
    end
    local staleRoster = {}
    for index = 1, 8 do
        staleRoster[index] = {
            guid = index == 1 and "Friendly-1" or "Duplicate-Verite",
            name = index == 1 and "Friendly1-TestRealm" or "Verite-TestRealm",
            role = "DAMAGER",
        }
    end
    local reconciled, hydration = KWR.TeamResolver:ReconcileFriendlyRoster(
        staleRoster, { scoreFaction = 0 }, friendlyRows, 8)
    local unique = {}
    for _, player in ipairs(reconciled) do unique[player.guid] = true end
    local uniqueCount = 0
    for _ in pairs(unique) do uniqueCount = uniqueCount + 1 end
    assert(#reconciled == 8 and uniqueCount == 8
        and hydration.source == "scoreboard_complete" and hydration.repaired >= 1,
        "Complete friendly scoreboard truth did not repair a duplicated transition roster.")

    local duplicateFriendlyRows = KWR.Util:Copy(friendlyRows)
    duplicateFriendlyRows[#duplicateFriendlyRows + 1] = KWR.Util:Copy(friendlyRows[1])
    duplicateFriendlyRows[#duplicateFriendlyRows].guid = "Transient-Duplicate-GUID"
    local deduped, dedupedHydration = KWR.TeamResolver:ReconcileFriendlyRoster(
        staleRoster, { scoreFaction = 0 }, duplicateFriendlyRows, 8)
    local dedupedUnique = {}
    for _, player in ipairs(deduped) do dedupedUnique[player.guid] = true end
    local dedupedCount = 0
    for _ in pairs(dedupedUnique) do dedupedCount = dedupedCount + 1 end
    assert(#deduped == 8 and dedupedCount == 8
        and dedupedHydration.source == "scoreboard_complete",
        "Duplicate friendly scoreboard rows polluted authoritative roster hydration.")

    local authoritativeRoster = {}
    for index = 1, 8 do
        authoritativeRoster[index] = {
            unit = "raid" .. index,
            unitStable = true,
            guid = "Group-" .. index,
            name = "Group" .. index .. "-TestRealm",
            classFile = "WARRIOR",
            role = "DAMAGER",
        }
    end
    local pollutedRows = KWR.Util:Copy(friendlyRows)
    pollutedRows[7] = {
        faction = 0,
        guid = "Stale-Friendly-1-A",
        name = "Friendly1-TestRealm",
        spec = "Frost",
        role = "NONE",
    }
    pollutedRows[8] = {
        faction = 0,
        guid = "Stale-Friendly-1-B",
        name = "Friendly1-TestRealm",
        spec = "Frost",
        role = "DAMAGER",
    }
    local protected, protectedHydration = KWR.TeamResolver:ReconcileFriendlyRoster(
        authoritativeRoster, { scoreFaction = 0 }, pollutedRows, 8)
    local protectedNames = {}
    for _, player in ipairs(protected) do protectedNames[player.name] = true end
    assert(#protected == 8
        and protectedNames["Group7-TestRealm"]
        and protectedNames["Group8-TestRealm"]
        and protectedHydration.source == "group_authoritative"
        and protectedHydration.scoreboardHadDuplicates == true,
        "Stale duplicate scoreboard identities displaced authoritative group members.")

    local partialRows = {}
    for index = 1, 5 do partialRows[index] = KWR.Util:Copy(friendlyRows[index]) end
    local degraded, degradedHydration = KWR.TeamResolver:ReconcileFriendlyRoster(
        staleRoster, { scoreFaction = 0 }, partialRows, 8)
    local degradedNames = {}
    for _, player in ipairs(degraded) do degradedNames[player.name] = true end
    local degradedCount = 0
    for _ in pairs(degradedNames) do degradedCount = degradedCount + 1 end
    assert(#degraded == degradedCount
        and #degraded < 8
        and degradedHydration.source == "scoreboard_partial",
        "Incomplete roster feeds padded the team tracker with duplicate identities.")
end
do
    local originalRecords = KWR.Util:Copy(KWR.EnemyIntel.records)
    local originalTokens = KWR.Util:Copy(KWR.EnemyIntel.observedTokens)
    KWR.EnemyIntel:Upsert({
        name = "EnemyGhost-OtherRealm",
        guid = "Player-9-ENEMY",
        source = "Target",
        location = "Farm",
        locationSource = "Team Engagement",
        locationInferred = true,
        coordinateProvenance = nil,
        x = nil,
        y = nil,
        unit = "target",
        localEngaged = true,
        inCombat = true,
        health = 900,
        healthMax = 1000,
    }, true)
    local enemyKey = KWR.Util:CanonicalPlayerKey("EnemyGhost-OtherRealm", "Player-9-ENEMY")
    local observed = enemyKey and KWR.EnemyIntel.records[enemyKey] or nil
    assert(observed
        and observed.x == nil and observed.y == nil
        and observed.coordinateProvenance ~= "observed_enemy_unit"
        and observed.locationSource ~= nil,
        "Enemy truth storage fabricated enemy coordinates from engagement-only location context.")
    KWR.EnemyIntel.records = originalRecords
    KWR.EnemyIntel.observedTokens = originalTokens
end
do
    local originalSessionKey = KWR.Reporter.sessionKey
    local originalTracks = KWR.Util:Copy(KWR.Reporter.tracks)
    local originalEvents = KWR.Util:Copy(KWR.Reporter.events)
    local originalSequence = KWR.Reporter.sequence
    local originalMemory = KWR.Util:Copy(KWR.Reporter.memory)
    local reporterSnapshot = {
        capturedAt = KWR.Util:Now(),
        context = {
            inPvP = true,
            mapKey = "ARATHI",
            mapID = 529,
            instanceID = 77,
            side = "right",
            bracket = "RATED",
        },
        objectives = { rows = {} },
        roster = {
            {
                key = "Player-1-A",
                guid = "Player-1-A",
                name = "Alpha-TestRealm",
                shortName = "Alpha",
                classFile = "WARRIOR",
                x = 0.30,
                y = 0.40,
                role = "DAMAGER",
                lastSeenAt = KWR.Util:Now(),
            },
        },
        enemies = {
            {
                key = "Enemy-1-A",
                guid = "Enemy-1-A",
                name = "Enemy-TestRealm",
                shortName = "Enemy",
                classFile = "ROGUE",
                role = "DAMAGER",
                location = "Farm",
                visible = true,
                lastSeenAt = KWR.Util:Now(),
            },
        },
    }
    local observedA = KWR.Reporter:Observe(reporterSnapshot)
    reporterSnapshot.roster = {
        {
            key = "Player-1-B",
            guid = "Player-1-B",
            name = "Bravo-TestRealm",
            shortName = "Bravo",
            classFile = "PRIEST",
            x = 0.32,
            y = 0.43,
            role = "HEALER",
            lastSeenAt = KWR.Util:Now(),
        },
    }
    local observedB = KWR.Reporter:Observe(reporterSnapshot)
    KWR.Reporter.sessionKey = originalSessionKey
    KWR.Reporter.tracks = originalTracks
    KWR.Reporter.events = originalEvents
    KWR.Reporter.sequence = originalSequence
    KWR.Reporter.memory = originalMemory
    assert(observedA.coverage and observedA.coverage.friendly == 1
        and observedB.coverage and observedB.coverage.friendly == 1
        and observedB.friendly and #observedB.friendly == 1
        and observedB.friendly[1].name == "Bravo",
        "Reporter retained absent friendly members after the roster changed.")
    assert(observedA.enemy and #observedA.enemy == 1
        and observedA.enemy[1].x == 0.68 and observedA.enemy[1].y == 0.72
        and observedA.enemy[1].mapSource == "map_location",
        "Reporter did not resolve an enemy location-only track for the tactical map.")
end
assert(KWR.AAR.active ~= nil, "AAR did not open a live match journal.")
assert(KWR.AAR:DetermineResult({
    matchComplete = true,
    scoreEnd = { friendly = 2, enemy = 1, max = 3 },
}) == "VICTORY", "Time-limit match completion did not resolve the winning team.")

mockRightScore = 1500
assert(KWR.MatchRuntime:ForceRefresh("smoke-pvp-complete-score"), "Final PvP score refresh failed.")
mockPvP = false
mockInstanceType = "none"
if not releaseOnly then
    KWR.db.profile.preview = true
    assert(KWR.MatchRuntime:ForceRefresh("smoke-preview"), "Preview pipeline refresh failed.")
    previewState = KWR.Store:Get()
    assert(previewState.snapshot.context.preview == true, "Preview was not explicitly labeled.")
    assert(previewState.mode == "PREVIEW", "Store did not publish preview mode.")
    assert(KWR.Util:AllowsCompactBattlefieldSurfaces(previewState) == true,
        "Preview state did not allow compact battlefield surfaces.")
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
else
    previewState = KWR.Store:Get()
    assert(KWR.db.profile.preview ~= true,
        "Release-pruned package left preview enabled in the active profile.")
end
do
    local package = KWR.Assignments:ResponsePackage({
        context = { mapKey = "ARATHI" },
        strategy = {
            executionAssessment = {
                active = false,
                confidence = "NONE",
                actionOpportunity = { action = "HOLD_PLAN", score = 0 },
            },
            objectiveDecision = {},
        },
        assignmentIntegrity = {
            coverageLedger = {
                { location = "Farm", required = 1, assigned = 1, state = "STABLE" },
            },
            reassignments = {},
        },
    }, {})
    assert(package.recovery
        and package.recovery.urgent == false
        and package.recovery.summary == "Coverage is currently stable.",
        "Assignments response package still emitted a fake urgent gap when coverage was already satisfied.")
end
if not releaseOnly then
    assert(previewState.snapshot.strategy.planID ~= nil, "Strategy engine did not select a battle plan.")
    assert(previewState.snapshot.formation.complete == true, "Full preview roster was not formation-ready.")
    assert(previewState.command.planID == previewState.snapshot.strategy.planID, "Commander did not publish the selected plan.")
end
assert(KWR.MetaSnapshot:Count() == 40, "RBG meta snapshot is incomplete.")
assert(KWR.MetaSnapshot:Lookup("PRIEST", "Discipline").rank == 1, "RBG meta snapshot lookup failed.")
if not releaseOnly then
    assert(#KWR.AAR:GetHistory() == 1, "Completed match was not committed to the AAR journal.")
    local completed = KWR.AAR:GetHistory()[1]
    assert(completed.result == "VICTORY", "AAR did not record the assigned Horde team's victory.")
    assert(completed.addonVersion == KWR.version
        and completed.schemaVersion == KWR.schemaVersion
        and completed.performance and completed.performance.samples > 0
        and completed.performance.maxRefreshMs >= 0
        and completed.safety and completed.safety.total == 0,
        "AAR did not bind version, performance, and safety evidence to the completed match.")
    completed.primaryPlanID = completed.primaryPlanID or "AB_STABLE_THREE"
    completed.result = "VICTORY"
    KWR.AAR:SaveFeedback(completed.id, { wonBy = "Objectives", notes = "Reviewed smoke match." })
    KWR.AARWindow:Show(completed.id)
    assert(KWR.AARWindow.frame.wonBy.value == "Objectives"
        and KWR.AARWindow.frame.wonBy.buttons[2].selected == true,
        "Saved AAR selection did not remain visibly selected.")
    assert(KWR.AARWindow.frame.snapshotCard.value.value:find("RESULT", 1, true)
        and KWR.AARWindow.frame.snapshotCard.value.value:find("STABILITY", 1, true)
        and KWR.AARWindow.frame.reviewCard.value.value:find("CALL GRADE", 1, true)
        and KWR.AARWindow.frame.reviewCard.value.value:find("EXECUTION", 1, true)
        and KWR.AARWindow.frame.reviewCard.value.value:find("TRANSITION", 1, true)
        and KWR.AARWindow.frame.evidenceCard.value.value:find("OBJ EVENTS", 1, true)
        and KWR.AARWindow.frame.snapshotCard.value.value:find("SWAPS", 1, true)
        and KWR.AARWindow.frame.evidenceCard.value.value:find("ACTIVEPLAY SWITCHES", 1, true),
        "AAR window did not surface snapshot, decision-review, and evidence summaries.")
    assert(KWR.AARWindow.frame.resultBadge.text.value == "VICTORY"
        and KWR.AARWindow.frame.reviewBadge.text.value == "REVIEW DONE"
        and KWR.AARWindow.frame.lessonCard.value.value:find("NEXT LESSON", 1, true),
        "AAR window did not expose the result/review summary hierarchy.")
    local strengthButton = KWR.AARWindow.frame.strength.buttons[1]
    strengthButton.scripts.OnClick(strengthButton)
    strengthButton.scripts.OnLeave(strengthButton)
    assert(strengthButton.selected == true
        and KWR.AARWindow.frame.strength.value == "Coordination",
        "Clicked AAR selection did not retain its selected state.")
    assert(KWR.Learning:Summary().samples == 1, "Reviewed AAR did not enter bounded learning.")
    assert(KWR.Learning:Adjustment(completed.mapKey, completed.primaryPlanID) == 0,
        "Learning affected decisions before the minimum sample size.")
    local exportText = KWR.AAR:Export(completed)
    assert(type(exportText) == "string"
        and exportText:find("Command Stability:", 1, true)
        and exportText:find("Stability budget:", 1, true)
        and exportText:find("Field certification:", 1, true)
        and exportText:find("Churn detail:", 1, true)
        and exportText:find("Bypass detail:", 1, true)
        and not exportText:find("suppress persistence Unknown", 1, true)
        and not exportText:find("overrides pre-arrival Unknown", 1, true)
        and not exportText:find("invalidations pre-arrival Unknown", 1, true)
        and not exportText:find("Bypass detail: response Unknown", 1, true)
        and exportText:find("Result quality:", 1, true)
        and exportText:find("Outcome attribution:", 1, true)
        and exportText:find("Recommended lesson:", 1, true)
        and exportText:find("Latest active play:", 1, true)
        and exportText:find("Latest persistence gate:", 1, true)
        and exportText:find("Play outcome:", 1, true)
        and exportText:find("Transition:", 1, true)
        and exportText:find("Gate class:", 1, true)
        and exportText:find("Latest override:", 1, true)
        and not exportText:match("Latest override:.-%([Uu]nknown%)")
        and exportText:find("Latest suppression:", 1, true),
        "AAR export did not include command-stability evidence.")
    local _, perfText = KWR.MainWindowReports:BuildPerformancePayload(KWR.Store:Get())
    assert(type(perfText) == "string"
        and perfText:find("COMMAND STABILITY:", 1, true)
        and perfText:find("Budget ", 1, true)
        and perfText:find("Field certification ", 1, true)
        and perfText:find("ACTIVE PLAY:", 1, true)
        and perfText:find("Timing commit", 1, true)
        and perfText:find("Persistence observed", 1, true)
        and perfText:find("Transition ", 1, true)
        and perfText:find("Gate ", 1, true)
        and perfText:find("Suppression persistence", 1, true)
        and perfText:find("Invalidations pre-arrival", 1, true)
        and perfText:find("Successes ", 1, true)
        and perfText:find("Latest override:", 1, true)
        and perfText:find("Latest suppression:", 1, true),
        "Performance payload did not expose command-stability and active-play telemetry.")
else
    assert(type(KWR.AAR:GetHistory()) == "table",
        "Release-pruned package did not expose a bounded AAR history collection.")
end
local missingScoreSnapshot = {
    context = {
        inPvP = true,
        matchComplete = true,
        mapKey = "GILNEAS",
        kind = "NODE",
    },
    strategy = {
        action = "Hold Lighthouse.",
    },
}
local missingScoreOK, missingScoreCommand = pcall(function()
    return KWR.Commander:Compose(missingScoreSnapshot, {
        status = "WIN",
        action = "Hold Lighthouse.",
        urgency = 55,
    }, {})
end)
assert(missingScoreOK and missingScoreCommand and missingScoreCommand.status == "COMPLETE"
    and missingScoreCommand.reason:find("FINAL SCORE 0%-0", 1) ~= nil,
    "Commander did not degrade safely when final match score data was missing.")
local partialScoreOK, partialScoreCommand = pcall(function()
    return KWR.Commander:Compose({
        context = {
            inPvP = true,
            matchComplete = true,
            mapKey = "GILNEAS",
            kind = "NODE",
        },
        score = {
            friendly = 1500,
        },
        strategy = {
            action = "Hold Lighthouse.",
        },
    }, {
        status = "WIN",
        action = "Hold Lighthouse.",
        urgency = 55,
    }, {})
end)
assert(partialScoreOK and partialScoreCommand and partialScoreCommand.status == "COMPLETE"
    and partialScoreCommand.reason:find("FINAL SCORE 1500%-0", 1) ~= nil,
    "Commander did not tolerate partial final score data.")
if releaseOnly then
    print("KWR_SMOKE_PASS checks=0")
    return
end
local noteEnemy = KWR.Store:Get().snapshot.enemies and KWR.Store:Get().snapshot.enemies[1]
assert(noteEnemy and noteEnemy.key, "Enemy tracker did not expose an enemy note target.")
assert(KWR.MainWindow.frame == nil
    and KWR.MainWindow.builtPageCount == nil
    and next(KWR.MainWindow.pages) == nil,
    "Expanded Command Center eagerly built inactive pages.")
KWR.MainWindow:Show("ENEMIES")
assert(KWR.MainWindow.builtPageCount == 1
    and KWR.MainWindow.pages.ENEMIES.built == true,
    "Enemy page did not build exactly once when first requested.")
do
    KWR.MainWindow:UpdateEnemies(KWR.Store:Get())
    local enemyUpdates =
        KWR.MainWindow.expandedRosterUpdates or 0
    local enemySkips =
        KWR.MainWindow.expandedRosterSkips or 0
    KWR.MainWindow:UpdateEnemies(KWR.Store:Get())
    assert((KWR.MainWindow.expandedRosterUpdates or 0)
            == enemyUpdates
        and (KWR.MainWindow.expandedRosterSkips or 0)
            >= enemySkips
                + #KWR.MainWindow.pages.ENEMIES.trackerCard.rows,
        "Expanded Enemy tracker repainted unchanged row visuals.")
end
KWR.MainWindow:ShowEnemyNote(noteEnemy.key)
local noteProfileText = rawget(KWR.MainWindow.noteEditor.profile, "value") or ""
local noteBadgeText = rawget(KWR.MainWindow.pages.ENEMIES.trackerCard.rows[1].note.label, "value") or ""
local enemyToolbarBadge = rawget(KWR.MainWindow.pages.ENEMIES.toolbar.liveBadge.text, "value") or ""
local enemyToolbarSummary = rawget(KWR.MainWindow.pages.ENEMIES.toolbar.summary, "value") or ""
    assert(KWR.MainWindow.noteEditor.enemyKey == noteEnemy.key
        and (noteBadgeText == "VIEW" or noteBadgeText == "NOTE")
        and (noteProfileText == "" or noteProfileText:find("PLAYER PROFILE:", 1, true) ~= nil)
        and enemyToolbarBadge ~= ""
        and enemyToolbarSummary:find("SEEN", 1, true) ~= nil
        and KWR.MainWindow.pages.ENEMIES.detailCard.identity.value ~= ""
        and KWR.MainWindow.pages.ENEMIES.detailCard.edit:IsShown()
        and KWR.MainWindow.noteEditor.truthBadge.text.value ~= ""
    and KWR.MainWindow.noteEditor.trustBadge.text.value ~= "",
    "Enemy note flow did not expose note badge or model-summary context.")
KWR.MainWindow.noteEditor:Hide()
KWR.MainWindow.frame:Hide()
KWR.MainWindow:RestoreCompactSurfaces()
KWR.MainWindow:Show("INTEL")
assert(KWR.MainWindow.builtPageCount == 2
    and KWR.MainWindow.pages.INTEL.built == true,
    "Intel page did not build lazily when first requested.")
assert(KWR.MainWindow.pages.INTEL.summaryCard.matchesBadge.text.value ~= ""
    and KWR.MainWindow.pages.INTEL.reviewCard.resultBadge.text.value ~= ""
    and KWR.MainWindow.pages.INTEL.reviewCard.reviewBadge.text.value ~= "",
    "Intel page did not surface the summary/review badges.")
KWR.MainWindow.frame:Hide()
KWR.MainWindow:RestoreCompactSurfaces()

if not releaseOnly then
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
end
do
    mockRaid = true
    mockRaidTokensStable = true
    mockInspectSpec = 258
    assert(KWR.MatchRuntime:ForceRefresh("smoke-inspect-observed"), "Observed-spec refresh failed.")
    assert(KWR.Store:Get().snapshot.roster[1].spec == "Shadow", "Observed teammate spec was not captured.")
    mockInspectSpec = nil
    assert(KWR.MatchRuntime:ForceRefresh("smoke-inspect-retained"), "Retained-spec refresh failed.")
    assert(KWR.Store:Get().snapshot.roster[1].spec == "Shadow",
        "Observed teammate spec was discarded after inspection changed.")
    inspectNotifications = {}
    mockInspectSpec = 257
    local rescanGuid = KWR.Store:Get().snapshot.roster[1].guid
    assert(KWR.MatchRuntime:RescanRoster(), "Manual roster rescan failed.")
    assert(inspectNotifications[1] == "raid1",
        "Manual roster rescan did not request a fresh teammate inspection.")
    KWR.RosterInspector:InspectReady(rescanGuid)
    assert(KWR.Store:Get().snapshot.roster[1].spec == "Holy",
        "Manual roster rescan did not rebuild the friendly spec cache after inspection.")
    mockInspectSpec = nil
    mockRaid = false
    mockRaidTokensStable = false
end
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
mockPvP = true
mockInstanceType = "pvp"
assert(KWR.MatchRuntime:ForceRefresh("smoke-roster-layout-bg"), "Battleground layout refresh failed.")

local refreshesBeforeRosterShow =
    KWR.MatchRuntime.diagnostics.refreshes or 0
KWR.CombatRoster:Show("TEAM")
assert((KWR.MatchRuntime.diagnostics.refreshes or 0)
    == refreshesBeforeRosterShow,
    "Opening the combat roster forced an unnecessary strategy rebuild.")
do
    local savedState = KWR.Store:Get()
    local boundState = KWR.Util:Copy(savedState)
    boundState.snapshot.roster = {
        {
            key = "BOUND-OLD-1",
            guid = "Player-1-BoundOld1",
            name = "Boundoldone-TestRealm",
            shortName = "Boundoldone",
            unit = "raid1",
            unitStable = true,
            role = "DAMAGER",
            connected = true,
        },
        {
            key = "BOUND-OLD-2",
            guid = "Player-1-BoundOld2",
            name = "Boundoldtwo-TestRealm",
            shortName = "Boundoldtwo",
            unit = "raid2",
            unitStable = true,
            role = "HEALER",
            connected = true,
        },
    }
    boundState.assignments = {}
    KWR.CombatRoster:Update(boundState)
    local loadingState = KWR.Util:Copy(boundState)
    loadingState.snapshot.context.rosterHydration = { expected = 3 }
    KWR.CombatRoster:Update(loadingState)
    assert(KWR.CombatRoster.teamFrame.heading.value:find("2/3", 1, true)
        and not KWR.CombatRoster.teamFrame.heading.value:find("LOADING", 1, true),
        "Combat roster added technical hydration language to the team count.")
    KWR.CombatRoster:Update(boundState)
    assert(KWR.CombatRoster.teamFrame.heading.value:find("2/2", 1, true)
        and not KWR.CombatRoster.teamFrame.heading.value:find("UP", 1, true),
        "Combat roster added readiness language to the live team count.")
    local changedState = KWR.Util:Copy(boundState)
    changedState.revision = (boundState.revision or 0) + 1
    changedState.snapshot.roster[1].key = "BOUND-NEW-1"
    changedState.snapshot.roster[1].guid = "Player-1-BoundNew1"
    changedState.snapshot.roster[1].name = "Boundnewone-TestRealm"
    changedState.snapshot.roster[1].shortName = "Boundnewone"
    changedState.snapshot.roster[2].key = "BOUND-NEW-2"
    changedState.snapshot.roster[2].guid = "Player-1-BoundNew2"
    changedState.snapshot.roster[2].name = "Boundnewtwo-TestRealm"
    changedState.snapshot.roster[2].shortName = "Boundnewtwo"
    mockCombat = true
    KWR.CombatRoster:Update(changedState)
    assert(KWR.CombatRoster.teamRows[1].nameText.value == "Boundnewone"
        and KWR.CombatRoster.teamRows[2].nameText.value == "Boundnewtwo",
        "Combat roster visuals did not follow changed secure raid-unit occupants.")
    local unstableState = KWR.Util:Copy(changedState)
    unstableState.revision = changedState.revision + 1
    unstableState.snapshot.roster[2].unit = nil
    unstableState.snapshot.roster[2].unitStable = false
    KWR.CombatRoster:Update(unstableState)
    assert(KWR.CombatRoster.teamRows[2].detailText.value == "ROSTER SETTLING"
        and KWR.CombatRoster.teamRows[2].nameText.value == "",
        "Combat roster reused a stale friendly identity while the secure unit occupant was still settling.")
    local reducedState = KWR.Util:Copy(changedState)
    reducedState.revision = changedState.revision + 1
    reducedState.snapshot.roster[2] = nil
    KWR.CombatRoster:Update(reducedState)
    assert(KWR.CombatRoster.rebindPending == true,
        "Combat roster did not mark a removed secure row for post-combat rebind.")
    KWR.Store.state = reducedState
    mockCombat = false
    KWR.CombatRoster:FlushPending()
    assert(KWR.CombatRoster.rebindPending == false
        and not KWR.CombatRoster.teamRows[2]:IsShown(),
        "Combat roster did not clear stale secure rows after combat ended.")
    KWR.Store.state = savedState
    KWR.CombatRoster:Update(savedState)
end
    assert(KWR.CombatRoster.teamFrame.width == 336
        and KWR.CombatRoster.teamFrame.height == 380
        and KWR.CombatRoster.teamFrame.pane.width == 320
        and KWR.CombatRoster.teamFrame.pane.height == 332
        and KWR.CombatRoster.teamFrame.brand.texture ~= nil
        and KWR.CombatRoster.teamFrame.headingIcon.texture ~= nil
        and not KWR.CombatRoster.enemyFrame:IsShown(),
        "Team-only combat roster did not use the split ten-row geometry.")
KWR.CombatRoster:Show("BOTH")
do
    local slotOwner = {
        maxRows = 10,
        enemySlotKeys = {},
    }
    local firstOrder = KWR.CombatRosterState:StableEnemyRows(slotOwner, {
        { key = "ENEMY-A", shortName = "Alpha" },
        { key = "ENEMY-B", shortName = "Bravo" },
    })
    local reversedTruth = KWR.CombatRosterState:StableEnemyRows(slotOwner, {
        { key = "ENEMY-B", shortName = "Bravo" },
        { key = "ENEMY-A", shortName = "Alpha" },
    })
    assert(firstOrder[1].key == "ENEMY-A"
        and firstOrder[2].key == "ENEMY-B"
        and reversedTruth[1].key == "ENEMY-A"
        and reversedTruth[2].key == "ENEMY-B",
        "Enemy rows changed visual slots when truth order changed.")
end
function RunLateSmokeChecks()
if previewState and previewState.snapshot and previewState.snapshot.context
    and previewState.snapshot.context.preview == true then
    KWR.CombatRoster:Update(previewState)
    assert(KWR.CombatRoster.teamFrame.width == 336
        and KWR.CombatRoster.teamFrame.height == 380
        and KWR.CombatRoster.teamFrame.pane.width == 320
        and KWR.CombatRoster.teamFrame.pane.height == 332
        and KWR.CombatRoster.enemyFrame.width == 336
        and KWR.CombatRoster.enemyFrame.height == 456
        and KWR.CombatRoster.enemyFrame.pane.width == 320
        and KWR.CombatRoster.enemyFrame.pane.height == 332,
        "Split battle trackers did not size their lanes consistently.")
    assert(KWR.CombatRoster.teamFrame.heading.value:find("TEAM", 1, true)
        and not KWR.CombatRoster.teamFrame.heading.value:find("LOADING", 1, true)
        and KWR.CombatRoster.enemyFrame.heading.value:find("HERE", 1, true)
        and KWR.CombatRoster.enemyFrame.heading.value:find("LIVE", 1, true)
        and KWR.CombatRoster.enemyFrame.brand.texture ~= nil
        and KWR.CombatRoster.enemyFrame.headingIcon.texture ~= nil
        and (((KWR.CombatRoster.enemyFrame.targetSpotlight.nameText.value:find(
            " CC -", 1, true)
            or KWR.CombatRoster.enemyFrame.targetSpotlight.nameText.value
                == "CC: NONE")
            and KWR.CombatRoster.enemyFrame.targetSpotlight.detailText.value:find(
                "KILL", 1, true))
            or (KWR.CombatRoster.enemyFrame.targetSpotlight.statusBadge.text.value ~= ""
                and KWR.CombatRoster.enemyFrame.targetSpotlight.truthBadge.text.value ~= "")),
        "Combat trackers did not surface the higher-clarity heading or call card: "
            .. tostring(KWR.CombatRoster.teamFrame.heading.value) .. " | "
            .. tostring(KWR.CombatRoster.enemyFrame.heading.value) .. " | "
            .. tostring(KWR.CombatRoster.enemyFrame.targetSpotlight.statusBadge.text.value) .. " | "
            .. tostring(KWR.CombatRoster.enemyFrame.targetSpotlight.truthBadge.text.value))
end
KWR.CombatRoster:Show("BOTH")
local enemyToolbarPoint = KWR.CombatRoster.enemyFrame.toolbar.points
    and KWR.CombatRoster.enemyFrame.toolbar.points[1]
assert(enemyToolbarPoint
    and KWR.CombatRoster.enemyFrame.toolbar.parent == KWR.CombatRoster.enemyFrame
    and KWR.CombatRoster.teamFrame.toolbar.parent == KWR.CombatRoster.teamFrame
    and KWR.CombatRoster.enemyFrame.toolbar.height == 26
    and KWR.db.profile.combatRoster.layoutVersion == 3
    and KWR.db.profile.combatRoster.panes == nil
    and KWR.db.profile.combatRoster.splitToolbar == nil
    and KWR.db.profile.combatRoster.solo == nil,
    "Battle trackers retained a legacy combined surface.")
KWR.CombatRoster:Show("ENEMY")
assert(KWR.CombatRoster.enemyFrame ~= nil,
    "Enemy-only combat roster frame was not available.")
KWR.CombatRoster:ResetVisualCache()
    assert(KWR.CombatRoster.enemyFrame.targetSpotlight.height == 70
        and KWR.CombatRoster.enemyFrame.targetSpotlight.rule.height == 1
        and KWR.CombatRoster.enemyFrame.targetSpotlight.nameText.value == "NO ENEMY TARGET"
        and KWR.CombatRoster.enemyFrame.targetSpotlight.detailText.value
        == "Tab or click an enemy player."
        and KWR.CombatRoster.enemyFrame.targetSpotlight.actionText.value
        == "ACTION: SELECT TARGET",
        "Combat spotlight idle copy did not stay aligned with local-target truth.")
KWR.CombatRoster:Show("TEAM")
KWR.HUD.ready = true
KWR.db.profile.hud.enabled = true
local coordinationState = KWR.Store:Get()
do
    local fightNowState = KWR.Util:Copy(coordinationState)
    local now = KWR.Util:Now()
    fightNowState.snapshot.context.mapKey = "TWINPEAKS"
    fightNowState.snapshot.context.mapName = "Twin Peaks"
    fightNowState.snapshot.context.kind = "FLAG"
    fightNowState.snapshot.context.inPvP = true
    fightNowState.snapshot.score = { friendly = 0, enemy = 1, max = 3 }
    fightNowState.snapshot.responsePackage = {
        actionID = "ROTATE",
        target = "Enemy FC",
        shortTarget = "EFC",
        movers = { "Jade", "Orcatar", "Jedithotflash", "Lilslimjimmy", "Verite", "Skinrunner" },
        moverText = "Jade, Orcatar, Jedithotflash, Lilslimjimmy, Verite, Skinrunner",
        stayerText = "HOME: Cinder",
    }
    fightNowState.prediction = { status = "LOSE" }
    fightNowState.command.when = "NOW"
    fightNowState.command.activePlay = {
        id = "CURRENT",
        action = "Rotate to Enemy FC",
        objective = "Enemy FC",
        movers = { "Jade", "Orcatar", "Jedithotflash", "Lilslimjimmy", "Verite", "Skinrunner" },
    }
    fightNowState.command.activePlayCandidate = {
        id = "NEXT",
        action = "Peel our carrier",
        objective = "Our FC",
        movers = { "Cinder" },
        expectedArrivalAt = now + 8,
    }
    local fightNow = KWR.CommandView:FightNow(fightNowState)
    assert(fightNow.score == "TP 0 - 1"
        and fightNow.projection == "LIKELY LOSS"
        and fightNow.winPath == "RETURN + CAP"
        and fightNow.current.what == "ROTATE"
        and fightNow.current.who == "Jade, Orcatar, Jedithotflash, Lilslimjimmy, Verite, Skinrunner"
        and fightNow.current.where == "EFC"
        and fightNow.current.when == "NOW"
        and fightNow.next.what == "PEEL"
        and fightNow.next.who == "Cinder"
        and fightNow.next.where == "OFC"
        and fightNow.next.when:find("IN ", 1, true)
        and fightNow.nextObjective == "OFC"
        and fightNow.defense == "HOME: CINDER"
        and fightNow.offense == "Jade, Orcatar, Jedithotflash, Lilslimjimmy, Verite, Skinrunner -> EFC",
        "Fight-Now model did not preserve WHAT, WHO, WHERE, WHEN, posture, and BG win-path direction.")
    coordinationState = fightNowState
end
KWR.HUD:Update(coordinationState)
assert(KWR.HUD.frame:IsShown(),
    "Compact HUD did not open for coordination test.")
assert(KWR.HUD.frame.width == 432 and KWR.HUD.frame.height == 500
    and KWR.HUD.frame.caller:IsShown()
    and KWR.HUD.frame.kill:IsShown(),
    "Live Fight-Now card did not show its complete compact direction stack: width="
        .. tostring(KWR.HUD.frame.width)
        .. " height=" .. tostring(KWR.HUD.frame.height)
        .. " caller=" .. tostring(KWR.HUD.frame.caller:IsShown())
        .. " kill=" .. tostring(KWR.HUD.frame.kill:IsShown()))
assert(KWR.HUD.frame.next.heading.value == "NOW"
    and KWR.HUD.frame.mine.heading.value == "NEXT"
    and KWR.HUD.frame.caller.heading.value == "POSTURE"
    and KWR.HUD.frame.kill.heading.value == "KILL / CC"
    and KWR.HUD.frame.next.value.value:find("CALL:", 1, true)
    and KWR.HUD.frame.next.value.value:find("WHO:", 1, true)
    and KWR.HUD.frame.next.value.value:find("WHERE:", 1, true)
    and KWR.HUD.frame.next.value.value:find("WHEN:", 1, true)
    and KWR.HUD.frame.mine.value.value:find("CALL:", 1, true)
    and KWR.HUD.frame.caller.value.value:find("DEF:", 1, true)
    and KWR.HUD.frame.caller.value.value:find("OFF:", 1, true)
    and KWR.HUD.frame.kill.value.value:find("KILL:", 1, true)
    and KWR.HUD.frame.kill.value.value:find("CC:", 1, true)
    and KWR.HUD.frame.next.value.value:find("Jedithotflash", 1, true)
    and KWR.HUD.frame.next.value.value:find("Lilslimjimmy", 1, true)
    and KWR.HUD.frame.next.value.value:find("Verite", 1, true)
    and KWR.HUD.frame.next.value.value:find("Skinrunner", 1, true)
    and not KWR.HUD.frame.next.value.value:find("%+%d")
    and not KWR.HUD.frame.mine.value.value:find("%+%d")
    and not KWR.HUD.frame.caller.value.value:find("%+%d"),
    "Live Fight-Now card did not expose current/next calls, posture, kill, and CC direction.")
assert(not KWR.HUD.frame.alertBadge:IsShown()
    and not KWR.HUD.frame.truthBadge:IsShown()
    and not KWR.HUD.frame.refresh:IsShown()
    and not KWR.HUD.frame.reassess:IsShown()
    and not KWR.HUD.frame.next.value.value:find("CONFIDENCE", 1, true)
    and not KWR.HUD.frame.next.value.value:find("LIVE UI", 1, true),
    "Live Fight-Now card retained technical trust or maintenance clutter.")
do (function()
local localFightHudState = KWR.Util:Copy(coordinationState)
localFightHudState.revision = (coordinationState.revision or 0) + 1
localFightHudState.snapshot.executionCommand = localFightHudState.snapshot.executionCommand or {}
localFightHudState.snapshot.executionCommand.signature = "LOCAL-FIGHT-HUD"
localFightHudState.snapshot.executionCommand.localFight = {
    phase = "ACTIVE",
    kill = {
        mode = "KILL",
        target = "Warrior-Z",
        healthPercent = 32,
        location = "Lumber Mill",
        state = "ENGAGED",
    },
    controls = {
        {
            actor = "Knomercy",
            target = "Priest-V",
            assigned = true,
            state = "ACTIVE",
        },
    },
}
localFightHudState.snapshot.context.mapKey = "ARATHI"
localFightHudState.snapshot.context.mapName = "Arathi Basin"
localFightHudState.snapshot.context.kind = "NODE"
local rosterPlayer = localFightHudState.snapshot.roster[1]
local personalJob = {
    role = "CONTROL",
    shortRole = "CONTROL",
    target = "Priest-V",
    location = "MID",
    movement = "MOVE",
    display = "CC -> Priest-V",
}
local personalKey = KWR.Util:CanonicalPlayerKey(
    rosterPlayer.name or rosterPlayer.shortName, rosterPlayer.guid)
localFightHudState.snapshot.executionCommand.personalByKey = {}
for _, player in ipairs(localFightHudState.snapshot.roster) do
    local playerKey = KWR.Util:CanonicalPlayerKey(
        player.name or player.shortName, player.guid)
    if playerKey then
        localFightHudState.snapshot.executionCommand.personalByKey[playerKey] = personalJob
    end
    localFightHudState.snapshot.executionCommand.personalByKey[
        KWR.Util:ShortName(player.name or player.shortName):lower()] = personalJob
end
assert(KWR.ExecutionCommandBuilder:PersonalFor(
    localFightHudState.snapshot.executionCommand,
    rosterPlayer.name or rosterPlayer.shortName,
    rosterPlayer.guid) == personalJob,
    "Smoke fixture did not route the synchronized personal job.")
for _, normalizedPlayer in ipairs(
    KWR.TeamResolver:NormalizePublishedRoster(
        localFightHudState.snapshot.roster)) do
    assert(KWR.ExecutionCommandBuilder:PersonalFor(
        localFightHudState.snapshot.executionCommand,
        normalizedPlayer.name or normalizedPlayer.shortName,
        normalizedPlayer.guid) == personalJob,
        "Normalized roster identity did not resolve its synchronized personal job: "
            .. tostring(normalizedPlayer.name or normalizedPlayer.shortName)
            .. " | " .. tostring(normalizedPlayer.guid))
end
localFightHudState.snapshot.enemies[#localFightHudState.snapshot.enemies + 1] = {
    key = "fight-kill-target",
    guid = "Enemy-Fight-Kill",
    name = "Warrior-Z",
    shortName = "Warrior-Z",
    classFile = "WARRIOR",
    role = "DAMAGER",
    spec = "Arms",
    visible = true,
    localRange = true,
    age = 0,
    healthPercent = 32,
}
localFightHudState.snapshot.enemies[#localFightHudState.snapshot.enemies + 1] = {
    key = "fight-cc-target",
    guid = "Enemy-Fight-Control",
    name = "Priest-V",
    shortName = "Priest-V",
    classFile = "PRIEST",
    role = "HEALER",
    spec = "Discipline",
    visible = true,
    localRange = true,
    age = 0,
    healthPercent = 71,
}
localFightHudState.snapshot.executionCommand.localFight.kill.targetGUID = "Enemy-Fight-Kill"
localFightHudState.snapshot.executionCommand.localFight.controls[1].targetGUID = "Enemy-Fight-Control"
KWR.HUD:Invalidate()
KWR.HUD:Update(localFightHudState)
assert(KWR.HUD.frame.kill:IsShown()
    and KWR.HUD.frame.kill.value.value:find("KILL:", 1, true)
    and KWR.HUD.frame.kill.value.value:find("Warrior-Z", 1, true)
    and KWR.HUD.frame.kill.value.value:find("CC:", 1, true)
    and KWR.HUD.frame.kill.value.value:find("Knomercy -> Priest-V", 1, true)
    and KWR.HUD.frame.kill.value.value:find(
        KWR.Theme.combatColors.KILL.hex, 1, true)
    and KWR.HUD.frame.kill.value.value:find(
        KWR.Theme.combatColors.STOP.hex, 1, true),
    "Live local-fight card did not render synchronized kill and CC actors.")
KWR.CombatRoster:Update(localFightHudState)
assert(KWR.CombatRoster.enemyFrame.targetSpotlight.nameText.value
    == "Knomercy CC - Priest P"
    and KWR.CombatRoster.enemyFrame.targetSpotlight.detailText.value
    == "KILL: Warrior W"
    and KWR.CombatRoster.enemyFrame.targetSpotlight.actionText.value
    == "SWITCH IN 5 4 3 2 1",
    "Enemy tracker call card did not expose the CC actor, target classes, initials, and switch countdown.")
local localFightView = KWR.CommandView:FightNow(localFightHudState)
assert(localFightView.current.what == "KILL"
    and localFightView.current.where == "LM"
    and localFightView.current.when == "NOW"
    and localFightView.current.source == "LOCAL_FIGHT"
    and localFightView.next.when == "AFTER FIGHT",
    "Fight Now did not synchronize its current recommendation with the confirmed local fight.")
local unresolvedFightState = KWR.Util:Copy(localFightHudState)
unresolvedFightState.revision = localFightHudState.revision + 1
unresolvedFightState.snapshot.executionCommand.signature = "UNRESOLVED-LOCAL-FIGHT"
unresolvedFightState.snapshot.executionCommand.localFight = {
    phase = "ACTIVE",
    kill = { mode = "KILL", target = "S" },
    controls = {
        { actor = "OPEN", target = "U", assigned = false, state = "ACTIVE" },
    },
}
KWR.CombatRoster:Update(unresolvedFightState)
assert(not KWR.CombatRoster.enemyFrame.targetSpotlight.nameText.value:find(
        "UNKNOWN", 1, true)
    and not KWR.CombatRoster.enemyFrame.targetSpotlight.detailText.value:find(
        "UNKNOWN", 1, true)
    and KWR.CombatRoster.enemyFrame.targetSpotlight.actionText.value
        ~= "SWITCH IN 5 4 3 2 1",
    "Enemy tracker promoted unresolved placeholder identities into a call card: "
        .. tostring(KWR.CombatRoster.enemyFrame.targetSpotlight.nameText.value)
        .. " | "
        .. tostring(KWR.CombatRoster.enemyFrame.targetSpotlight.detailText.value)
        .. " | "
        .. tostring(KWR.CombatRoster.enemyFrame.targetSpotlight.actionText.value))
KWR.CombatRoster:Update(localFightHudState)
local personalRow
local killRow
local controlRow
local teamRowDebug = {}
for _, row in ipairs(KWR.CombatRoster.teamRows) do
    if row.displayName then
        teamRowDebug[#teamRowDebug + 1] = tostring(row.displayName)
            .. "=" .. tostring(row.detailText.value)
    end
    if row.displayName == KWR.Util:ShortName(rosterPlayer.name or rosterPlayer.shortName) then
        personalRow = row
        break
    end
end
for _, row in ipairs(KWR.CombatRoster.enemyRows) do
    if row.displayName == "Warrior-Z" then killRow = row end
    if row.displayName == "Priest-V" then controlRow = row end
end
assert(personalRow and personalRow.detailText.value == "CC -> Priest-V",
    "Friendly health row did not inherit the synchronized current assignment: "
        .. tostring(personalRow and personalRow.displayName) .. " | "
        .. tostring(personalRow and personalRow.detailText.value) .. " | "
        .. tostring(personalKey) .. " | " .. table.concat(teamRowDebug, ", "))
assert(personalRow:GetAttribute("type1") == "target"
    and personalRow:GetAttribute("type2") == "macro"
    and personalRow:GetAttribute("macrotext2")
        == "/focus [mod:shift,@" .. tostring(personalRow:GetAttribute("unit")) .. "]",
    "Friendly tracker binding did not preserve left-click target and modified right-click focus.")
assert(killRow:GetAttribute("type1") == "macro"
    and killRow:GetAttribute("type2") == "macro"
    and killRow:GetAttribute("macrotext1")
        == "/cleartarget\n/targetexact Warrior-Z"
    and killRow:GetAttribute("macrotext2")
        == "/targetexact [mod:shift] Warrior-Z\n/focus [mod:shift]\n/targetlasttarget [mod:shift]",
    "Enemy tracker binding did not preserve left-click target and Shift+Right-Click focus only.")
assert(killRow and killRow.detailText.value == "KILL"
    and controlRow and controlRow.detailText.value == "CC Knomercy"
    and killRow.detailIcon.texture ~= nil
    and controlRow.detailIcon.texture ~= nil
    and not personalRow.displayName:find("%.%.%.", 1)
    and not personalRow.detailText.value:find("%.%.%.", 1)
    and not controlRow.detailText.value:find("%.%.%.", 1)
    and personalRow.detailText.textColor[1]
        == KWR.Theme.combatColors.STOP.outer[1]
    and killRow.backdropBorderColor[1]
        == KWR.Theme.combatColors.KILL.outer[1],
    "Compact tracker rows did not expose clean reviewed local KILL and CC calls.")
local clearedFightHudState = KWR.Util:Copy(localFightHudState)
clearedFightHudState.revision = localFightHudState.revision + 1
clearedFightHudState.snapshot.executionCommand.signature = "LOCAL-FIGHT-CLEAR"
clearedFightHudState.snapshot.executionCommand.localFight = {
    phase = "CLEAR",
    kill = nil,
    controls = {},
}
clearedFightHudState.snapshot.executionCommand.personalByKey = {}
KWR.HUD:Invalidate()
KWR.HUD:Update(clearedFightHudState)
assert(KWR.HUD.frame.kill:IsShown()
    and KWR.HUD.frame.kill.value.value:find("KILL:", 1, true)
    and KWR.HUD.frame.kill.value.value:find("HOLD", 1, true)
    and KWR.HUD.frame.kill.value.value:find("CC:", 1, true)
    and KWR.HUD.frame.kill.value.value:find("NONE", 1, true)
    and not KWR.HUD.frame.kill.value.value:find("Warrior-Z", 1, true)
    and not KWR.HUD.frame.kill.value.value:find("Priest-V", 1, true),
    "Cleared local-fight card retained stale actors or hid its explicit placeholders.")
KWR.CombatRoster:Update(clearedFightHudState)
assert(personalRow.detailText.value ~= "CC -> Priest-V"
    and killRow.detailText.value ~= "KILL"
    and not controlRow.detailText.value:find("CC ", 1, true),
    "Cleared execution packet left stale jobs on friendly or enemy health rows.")
end)() end
local setupHudState = KWR.Util:Copy(coordinationState)
setupHudState.snapshot.context.inPvP = false
setupHudState.snapshot.context.mapKey = "WORLD"
setupHudState.snapshot.context.mapName = "World"
setupHudState.snapshot.context.instanceType = "none"
KWR.HUD:Invalidate()
KWR.HUD:Update(setupHudState)
assert(KWR.HUD.frame.score.value == "RBG SETUP"
    and KWR.HUD.frame.height == 548
    and KWR.HUD.frame.caller:IsShown()
    and KWR.HUD.frame.kill:IsShown()
    and KWR.HUD.frame.status.value:find("OPEN", 1, true)
    and KWR.HUD.frame.alertBadge.text.value == "SETUP"
    and KWR.HUD.frame.alertBadge:IsShown()
    and KWR.HUD.frame.truthBadge:IsShown()
    and KWR.HUD.frame.refresh:IsShown()
    and KWR.HUD.frame.reassess:IsShown()
    and KWR.HUD.frame.win.heading.value == "SETUP GOAL"
    and KWR.HUD.frame.next.heading.value == "RECRUITING PLAN"
    and KWR.HUD.frame.next.value.value:find("CURRENT:", 1, true)
    and KWR.HUD.frame.next.value.value:find("NEED:", 1, true)
    and KWR.HUD.frame.caller.heading.value == "QUEUE CHECK"
    and not KWR.HUD.frame.caller.value.value:find("CALL READ", 1, true)
    and KWR.HUD.frame.kill.heading.value == "NEXT STEP"
    and not KWR.HUD.frame.kill.value.value:find("local target", 1, true),
    "Out-of-combat HUD mixed live score, confidence, or target language into setup mode.")
KWR.HUD:Invalidate()
KWR.HUD:Update(coordinationState)
KWR.MainWindow:Show("TEAM")
assert(KWR.MainWindow.builtPageCount == 3
    and KWR.MainWindow.pages.TEAM.built == true,
    "Team page did not build lazily when first requested.")
assert(not KWR.CombatRoster:AnyShown() and not KWR.HUD.frame:IsShown(),
    "Expanded mode did not suppress compact surfaces.")
assert(KWR.db.profile.combatRoster.shown == true,
    "Expanded mode suppression should not persistently disable the combat roster.")
Minimap = CreateFrame("Frame", "Minimap")
Minimap:SetSize(140, 140)
KWR.MainWindow:PositionLauncher()
local launcherPoint = KWR.MainWindow.launcher.points
    and KWR.MainWindow.launcher.points[1]
assert(KWR.MainWindow.launcher.width == 42
    and launcherPoint
    and math.floor(math.sqrt((launcherPoint[4] * launcherPoint[4])
        + (launcherPoint[5] * launcherPoint[5])) + 0.5) == 88,
    "Minimap launcher is not compact or positioned outside the map ring.")
local teamCard = KWR.MainWindow.pages.TEAM.rosterCard
do
    local updatesBefore =
        KWR.MainWindow.expandedRosterUpdates or 0
    KWR.MainWindow:UpdateTeam(KWR.Store:Get())
    local updatesAfterFirst =
        KWR.MainWindow.expandedRosterUpdates or 0
    local skipsAfterFirst =
        KWR.MainWindow.expandedRosterSkips or 0
    KWR.MainWindow:UpdateTeam(KWR.Store:Get())
    assert(updatesAfterFirst >= updatesBefore
        and (KWR.MainWindow.expandedRosterUpdates or 0)
            == updatesAfterFirst
        and (KWR.MainWindow.expandedRosterSkips or 0)
            >= skipsAfterFirst + #teamCard.rows,
        "Expanded Team roster repainted unchanged row visuals.")
end
assert(KWR.MainWindow:UpdateHealthForUnit("player"),
    "Expanded Team health did not use the lightweight direct update path.")
local directHealthVisible = false
for _, row in ipairs(teamCard.rows) do
    if row.displayUnit == "player"
        and row.healthText.value == "LIVE" then
        directHealthVisible = true
        break
    end
end
assert(directHealthVisible,
    "Expanded Team health did not display its bounded direct-live state.")
for index, rowField in ipairs({ "player", "spec", "role", "health", "life", "position" }) do
    local headerPoint = teamCard.headers[index].points
        and teamCard.headers[index].points[1]
    local rowPoint = teamCard.rows[1][rowField].points
        and teamCard.rows[1][rowField].points[1]
    assert(headerPoint and rowPoint
        and headerPoint[2] == rowPoint[2] + 8,
        "Team header and row field are not aligned: " .. rowField)
end
KWR.MainWindow:Show("TACTICAL")
assert(KWR.MainWindow.builtPageCount == 4
    and KWR.MainWindow.pages.TACTICAL.built == true
    and KWR.MainWindow.pages.TACTICAL.targetCard.height == 126
    and KWR.MainWindow.pages.TACTICAL.callerCard.height == 94
    and KWR.MainWindow.pages.TACTICAL.focusCard.height == 132
    and KWR.MainWindow.pages.TACTICAL.battlefieldCard.height == 514
    and KWR.MainWindow.pages.TACTICAL.timelineCard.height == 94
    and KWR.MainWindow.pages.TACTICAL.controlsCard.height == 74
    and KWR.MainWindow.pages.TACTICAL.assignmentCard.height == 194
    and #KWR.MainWindow.pages.TACTICAL.assignmentCard.rows == 10
    and KWR.MainWindow.pages.TACTICAL.battlefieldCard.heading.value == "LIVE BATTLEFIELD VIEW"
    and KWR.MainWindow.pages.TACTICAL.battlefieldCard.formation.summary.height == 70
    and KWR.MainWindow.pages.TACTICAL.battlefieldCard.formation.recruits.width == 300,
    "Tactical dashboard cards did not preserve the expanded local-target layout.")
local tacticalContentLimit = 616
for _, card in ipairs({
    KWR.MainWindow.pages.TACTICAL.eventsCard,
    KWR.MainWindow.pages.TACTICAL.timelineCard,
    KWR.MainWindow.pages.TACTICAL.controlsCard,
}) do
    local point = card.points and card.points[1]
    local topOffset = point and point[3] or 0
    assert(math.abs(topOffset) + card.height <= tacticalContentLimit,
        "Tactical dashboard card extended below the content frame.")
end
assert(KWR.MainWindow.pages.TEAM.doctrineCard.value.spacing == 2
    and KWR.MainWindow.pages.TEAM.readinessCard.value.spacing == 2
    and KWR.MainWindow.pages.TEAM.doctrineCard.scroll
    and KWR.MainWindow.pages.TEAM.doctrineCard.body,
    "Team setup rows did not preserve readable line spacing.")
assert(KWR.MainWindow.pages.ASSIGNMENTS.built ~= true,
    "Assignment page was built before it was requested.")
local tacticalPreviewState
if not releaseOnly then
    tacticalPreviewState = KWR.Util:Copy(KWR.Store:Get())
    tacticalPreviewState.snapshot = KWR.Preview:Build()
    tacticalPreviewState.command = tacticalPreviewState.command or {}
    tacticalPreviewState.command.action = tacticalPreviewState.command.action or "Preview command"
    tacticalPreviewState.command.urgency = tacticalPreviewState.command.urgency or 0
    tacticalPreviewState.command.when = tacticalPreviewState.command.when or "NOW"
    tacticalPreviewState.command.confidence = tacticalPreviewState.command.confidence or "HIGH"
    KWR.MainWindow:UpdateTactical(tacticalPreviewState)
    KWR.MainWindow:Update(tacticalPreviewState)
    KWR.MainWindow.pages.TACTICAL.battlefieldCard.map:SetState(tacticalPreviewState)
    local tacticalMarker = KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.markers[1]
    assert(tacticalMarker and tacticalMarker.tooltipTitle ~= nil
        and type(tacticalMarker.tooltipLines) == "table"
        and #tacticalMarker.tooltipLines > 0
        and tacticalMarker.icon.texture ~= nil,
        "Tactical map markers did not expose hover context.")
    assert(KWR.MainWindow.pages.TACTICAL.battlefieldCard.reporterSummary.value
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.reporterSummary.value:find("SEEN", 1, true),
        "Tactical dashboard did not surface the reporter summary footer.")
    assert(KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.headerBand.height == 56
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.footerBand.height == 22
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.stateBadge.text.value ~= ""
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.trustBadge.text.value ~= ""
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.coverageBadge.text.value:find("SEEN", 1, true)
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.objectiveBadge.text.value ~= ""
        and KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.contextText.value ~= "",
        "Tactical map did not reserve the premium header/footer rails.")
    local tacticalLiveFallbackState = KWR.Util:Copy(tacticalPreviewState)
    tacticalLiveFallbackState.snapshot.context.preview = false
    tacticalLiveFallbackState.snapshot.reporter = tacticalLiveFallbackState.snapshot.reporter or {}
    tacticalLiveFallbackState.snapshot.reporter.friendly = {}
    tacticalLiveFallbackState.snapshot.reporter.enemy = {}
    tacticalLiveFallbackState.snapshot.roster = {
        {
            name = "Fallbackfriendly-TestRealm",
            shortName = "Fallbackfriendly",
            role = "HEALER",
            x = 0.25,
            y = 0.25,
            inCombat = true,
            healthPercent = 91,
        },
    }
    tacticalLiveFallbackState.snapshot.enemies = {
        {
            name = "Fallbackenemy-TestRealm",
            shortName = "Fallbackenemy",
            role = "DAMAGER",
            spec = "Arms",
            x = 0.75,
            y = 0.75,
            age = 4,
            location = "Blacksmith",
        },
    }
    KWR.MainWindow.pages.TACTICAL.battlefieldCard.map:SetState(tacticalLiveFallbackState)
    local fallbackFriendlySeen, fallbackEnemySeen = false, false
    for _, marker in ipairs(KWR.MainWindow.pages.TACTICAL.battlefieldCard.map.markers or {}) do
        if marker and marker:IsShown() then
            if marker.tooltipTitle == "Fallbackfriendly-TestRealm" then
                fallbackFriendlySeen = true
                assert(marker.icon.texture ~= nil,
                    "Fallback friendly tactical marker did not render an icon-first marker.")
            elseif marker.tooltipTitle == "Fallbackenemy-TestRealm" then
                fallbackEnemySeen = true
                assert(marker.icon.texture ~= nil,
                    "Fallback enemy tactical marker did not render an icon-first marker.")
            end
        end
    end
    assert(fallbackFriendlySeen and fallbackEnemySeen,
        "Tactical map did not fall back to live roster/enemy positions when reporter tracks were empty.")
    assert(KWR.MainWindow.frame.commandBadge.text.value == "PREVIEW"
        and KWR.MainWindow.frame.truthBadge.text.value ~= ""
        and KWR.MainWindow.frame.reporterBadge.text.value:find("SEEN", 1, true)
        and KWR.MainWindow.frame.doctrineBadge.text.value ~= ""
        and KWR.MainWindow.frame.tagline.value:find("Preview only", 1, true),
        "Main dashboard header did not surface the expanded command/truth/doctrine rail.")
end
KWR.MainWindow:Show("OBJECTIVES")
assert(KWR.MainWindow.builtPageCount == 5
    and KWR.MainWindow.pages.OBJECTIVES.built == true,
    "Objectives page did not build lazily when first requested.")
local quickCall = KWR.MainWindow.pages.OBJECTIVES.callsCard.buttons[1]
assert(quickCall.quickCallSecure == true
    and quickCall:GetAttribute("type1") == "macro"
    and quickCall:GetAttribute("macrotext1") == "/instance INC PRIMARY",
    "Quick Call was not armed as a fixed player-click secure action.")
assert(quickCall.callMeta and quickCall.callMeta.group == "PRESSURE"
    and quickCall.groupText.value == "PRESSURE"
    and not quickCall.groupText:IsShown()
    and KWR.MainWindow.pages.OBJECTIVES.callsCard.pressureBadge.text.value == "PRESSURE"
    and KWR.MainWindow.pages.OBJECTIVES.callsCard.helper.value ~= "",
    "Quick Calls did not expose grouped commander intent guidance.")
KWR.MainWindow:Show("OBJECTIVES")
KWR.MainWindow:UpdateObjectives(KWR.Store:Get())
assert(KWR.MainWindow.pages.OBJECTIVES.scoreCard.stateBadge.text.value ~= ""
    and KWR.MainWindow.pages.OBJECTIVES.conditionCard.urgencyBadge.text.value ~= ""
    and KWR.MainWindow.pages.OBJECTIVES.conditionCard.confidenceBadge.text.value ~= "",
    "Objectives page did not surface the new state/urgency/confidence badges.")
KWR.MainWindow:Show("TEAM")
KWR.MainWindow:UpdateTeam(KWR.Store:Get())
assert(KWR.MainWindow.pages.TEAM.summaryCard.readyBadge.text.value ~= ""
    and KWR.MainWindow.pages.TEAM.summaryCard.openBadge.text.value ~= ""
    and KWR.MainWindow.pages.TEAM.readinessCard.stateBadge.text.value ~= "",
    "Team page did not surface the new readiness badges.")
KWR.MainWindow:Show("ASSIGNMENTS")
KWR.MainWindow:UpdateAssignments(KWR.Store:Get())
assert(KWR.MainWindow.builtPageCount == 6
    and KWR.MainWindow.pages.ASSIGNMENTS.commandCard.stateBadge.text.value ~= ""
    and KWR.MainWindow.pages.ASSIGNMENTS.commandCard.coverageBadge.text.value ~= ""
    and KWR.MainWindow.pages.ASSIGNMENTS.mineCard.lockBadge.text.value ~= ""
    and KWR.MainWindow.pages.ASSIGNMENTS.mineCard.value.spacing == 3
    and KWR.MainWindow.pages.ASSIGNMENTS.logicCard.value.spacing == 2,
    "Assignments page did not surface the new command/coverage/lock badges.")
KWR.MainWindow:Show("OBJECTIVES")
mockPvP = true
quickCall.scripts.PostClick(quickCall, "LeftButton")
assert(KWR.MainWindow.pages.OBJECTIVES.callsCard.statusText.value == "SENT: INC PRIMARY"
    and KWR.MainWindow.pages.OBJECTIVES.callsCard.statusBadge.text.value == "SENT",
    "Quick Call did not provide visible battleground confirmation.")
mockPvP = false
mockInstanceType = "none"
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
assert(KWR.CopyDialog.frame.width == 520 and KWR.CopyDialog.frame.height == 170
    and KWR.CopyDialog.frame.edit.multiLine == false,
    "Single-line copy did not use the compact dialog geometry.")
KWR.CopyDialog:ShowText("Report Test", "LINE 1\nLINE 2")
assert(KWR.CopyDialog.frame.width == 820 and KWR.CopyDialog.frame.height == 560
    and KWR.CopyDialog.frame.edit.multiLine == true
    and rawget(KWR.CopyDialog.frame.edit, "template") == nil,
    "Report copy did not restore the multiline dialog geometry.")
local chatExport = KWR.Assignments:ChatExport(
    KWR.Store:Get().assignments, KWR.Store:Get().snapshot.context.mapKey)
assert(chatExport ~= ""
    and chatExport:find("\n", 1, true) == nil,
    "Assignment handoff chat export did not stay on one readable chat-safe line.")
local originalGetStringHeight = KWR.CopyDialog.frame.edit.GetStringHeight
KWR.CopyDialog.frame.edit.GetStringHeight = nil
KWR.CopyDialog:ShowText("Report Test", "LINE 1\nLINE 2")
assert(KWR.CopyDialog.frame.scrollChild.width ~= nil
    and KWR.CopyDialog.frame.scrollChild.height ~= nil,
    "Copy dialog did not tolerate a missing string-height API.")
KWR.CopyDialog.frame.edit.GetStringHeight = originalGetStringHeight
local explainTitle, explainText = KWR.MainWindowReports:BuildExplainPayload(KWR.Store:Get(), mainHelpers)
assert(explainTitle == "KWR Command Review"
    and explainText:find("BOTTOM LINE:", 1, true)
    and explainText:find("ACTION:", 1, true)
    and explainText:find("WHO:", 1, true)
    and not explainText:find("\nMOVE:", 1, true),
    "Explain payload did not promote the command-first review layout.")
local alternativesTitle, alternativesText = KWR.MainWindowReports:BuildAlternativesPayload(KWR.Store:Get())
assert(alternativesTitle == "KWR Alternate Plans"
    and alternativesText:find("CURRENT CALL:", 1, true)
    and alternativesText:find("OTHER REVIEWED PATHS:", 1, true),
    "Alternate-plan payload did not summarize the current call and fallback paths.")
KWR.MainWindow:ShowAlternatives()
assert(KWR.CopyDialog.frame.title:GetText() == "KWR Alternate Plans"
    and KWR.CopyDialog.frame.edit:GetText():find("CURRENT CALL:", 1, true),
    "Alternate-plan review did not open in the copy dialog.")
SlashCmdList.KWR("alts")
assert(KWR.CopyDialog.frame.title:GetText() == "KWR Alternate Plans"
    and KWR.CopyDialog.frame.edit:GetText():find("OTHER REVIEWED PATHS:", 1, true),
    "Slash alternatives command did not open the alternate-plan review.")
KWR.MainWindow:UpdateTactical(KWR.Store:Get())
assert(KWR.MainWindow.pages.TACTICAL.altButton.label:GetText() == "ALTS",
    "Tactical controls did not relabel the commander alternatives button during PvP.")
KWR.CopyDialog.frame:Hide()
KWR.db.profile.presentation.enabled = false
KWR.db.profile.cursor.enabled = false
KWR.db.profile.cursor.reticleEnabled = true
KWR.db.profile.aar.enabled = false
KWR.Options:Create()
KWR.Options:Refresh()
assert(KWR.Options.namedChecks.autoReporter == nil
    and KWR.Options.namedChecks.reticleEnabled.check.kwrDisabled == false
    and KWR.Options.namedChecks.battlefieldOrbs.check.kwrDisabled == false
    and KWR.Options.namedChecks.aarAutoOpen.check.kwrDisabled == true,
    "Options window did not separate advisory overlay dependencies from hard dependencies.")
KWR.Options.namedChecks.reticleEnabled.check:SetChecked(false)
KWR.Options.namedChecks.reticleEnabled.check.scripts.OnClick(
    KWR.Options.namedChecks.reticleEnabled.check)
KWR.Options.namedChecks.battlefieldOrbs.check:SetChecked(false)
KWR.Options.namedChecks.battlefieldOrbs.check.scripts.OnClick(
    KWR.Options.namedChecks.battlefieldOrbs.check)
assert(KWR.db.profile.cursor.reticleEnabled == false
    and KWR.db.profile.cursor.battlefieldOrbs == false,
    "Disabled cursor-ring dependencies prevented overlay preferences from being unchecked.")
KWR.db.profile.cursor.reticleEnabled = true
KWR.db.profile.cursor.battlefieldOrbs = true
KWR.db.profile.presentation.enabled = true
KWR.db.profile.cursor.enabled = true
KWR.db.profile.aar.enabled = true
KWR.Options:Refresh()
local optionsInventory = KWR.Options:Inventory()
local optionsAudit = KWR.Options:LayoutAudit()
assert(#optionsInventory >= 12 and optionsAudit.ok == true,
    "Options window did not expose a complete auditable inventory or clean card geometry.")
do
    local originalRecords = KWR.Util:Copy(KWR.EnemyIntel.records)
    local originalNotes = KWR.Util:Copy(KWR.db.enemyNotes)
    local originalProfiles = KWR.Util:Copy(KWR.db.opponentModels.players)
    local enemyKey = "Player-Trait"
    KWR.EnemyIntel.records[enemyKey] = {
        key = enemyKey,
        guid = enemyKey,
        name = "TraitTarget-Realm",
        shortName = "TraitTarget",
        spec = "Discipline",
        role = "HEALER",
    }
    KWR.db.opponentModels.players[enemyKey] = {
        key = enemyKey,
        name = "TraitTarget-Realm",
        shortName = "TraitTarget",
        sessions = 4,
        matches = 2,
        sightings = 8,
        localEngagements = 6,
        isolatedEngagements = 5,
        groupedEngagements = 1,
        deathsObserved = 4,
        priorityCastObserved = 4,
        carrierObserved = 0,
        locations = { Farm = 5 },
        updatedAt = KWR.Util:Now(),
    }
    local profile = KWR.OpponentModels:Describe(KWR.EnemyIntel.records[enemyKey])
    assert(profile.commanderTakeaway
        and profile.traits and profile.traits[1]
        and profile.traitSummary:find("Overextends", 1, true),
        "Opponent model did not expose structured traits and commander takeaway.")
    KWR.EnemyIntel:SetNoteTag(enemyKey, "SUBDUE", true)
    KWR.EnemyIntel:SetNote(enemyKey, "")
    KWR.EnemyIntel:PruneNotes()
    assert(KWR.EnemyIntel:NoteTags(enemyKey).SUBDUE == true
        and KWR.EnemyIntel:NoteTagSummary(enemyKey):find("Subdue", 1, true),
        "Enemy note tags did not persist or survive pruning.")
    local problem = {
        type = "FREE_CAST_HEALER",
        severity = 80,
        confidence = "CONFIRMED",
        enemy = KWR.EnemyIntel.records[enemyKey],
    }
    local scored, reasons = KWR.AssignmentScorer:Score({
        name = "Knomercy",
        available = true,
        profile = { singleTargetSubdue = 30 },
    }, problem, { context = { mapKey = "ARATHI" } })
    local hasTraitReason = false
    for _, reason in ipairs(reasons or {}) do
        if reason:find("learned model", 1, true) then hasTraitReason = true end
    end
    assert(scored > 120 and hasTraitReason,
        "Assignment scorer did not consume learned opponent traits conservatively.")
    KWR.EnemyIntel.records = originalRecords
    KWR.db.enemyNotes = originalNotes
    KWR.db.opponentModels.players = originalProfiles
end
do
    local read = KWR.Reporter:BattlefieldRead("Mine under observed pressure.",
        "Reinforce Mine from nearest assignment.",
        { label = "MEDIUM" },
        { label = "Mine", enemy = 3, delta = 2, total = 4, risk = 70 },
        nil)
    assert(read.status == "Observed pressure"
        and read.action == "Reinforce Mine from nearest assignment."
        and read.confidence == "MEDIUM",
        "Reporter battlefield read did not expose the plain user-facing summary.")
end
local buildTargets = KWR.Compositions:BuildTargets("WORLD")
assert(#buildTargets > 0 and buildTargets[1].id ~= nil,
    "Composition target catalog did not expose reviewed build options.")
assert(KWR.MatchRuntime:ForceRefresh("formation-comp-test"),
    "Formation comp test refresh did not complete.")
KWR.MainWindow:UpdateTactical(KWR.Store:Get())
KWR.MainWindow:UpdateAssignments(KWR.Store:Get())
assert(not KWR.MainWindow.pages.TACTICAL.nextCard.value.value:find("center board", 1, true)
    and KWR.MainWindow.pages.TACTICAL.battlefieldCard.formation.summary.value:find(
        "CURRENT ROSTER:", 1, true)
    and KWR.MainWindow.pages.TACTICAL.battlefieldCard.formation.summary.value:find(
        "TARGET BUILD:", 1, true)
    and KWR.MainWindow.pages.TACTICAL.winCard.value.value:find("NEED:", 1, true),
    "Setup tactical page did not expose current roster, target build, and need directly.")
assert(KWR.MainWindow.pages.TACTICAL.targetCard.heading.value == "BUILD FIT"
    and KWR.MainWindow.pages.TACTICAL.targetCard.value.value:find("TARGET MATCH", 1, true)
    and KWR.MainWindow.pages.TACTICAL.targetCard.value.value:find("OPEN SLOTS", 1, true)
    and KWR.MainWindow.pages.TACTICAL.targetCard.value.value:find("REPLACEMENTS", 1, true)
    and not KWR.MainWindow.pages.TACTICAL.targetCard.value.value:find("Protection Warrior", 1, true),
    "Setup dashboard duplicated recruit priority instead of showing build fit.")
assert(KWR.MainWindow.pages.TACTICAL.eventsCard.heading.value == "TARGET ROSTER"
    and not KWR.MainWindow.pages.TACTICAL.eventsCard.rows[1].value:find("CURRENT", 1, true),
    "Setup dashboard repeated current/target labels instead of showing the target roster.")
assert(KWR.MainWindow.pages.ASSIGNMENTS.commandCard.value.value:find("Recruit:", 1, true)
    and not KWR.MainWindow.pages.ASSIGNMENTS.commandCard.value.value:find("\n", 1, true),
    "Setup assignment header did not use a complete single-line recruitment call.")
if not releaseOnly then
    KWR.MainWindow:UpdateTactical(tacticalPreviewState)
end
assert(KWR.MainWindow:SetFormationBuildTarget("CONTROL_CLEAVE"),
    "Formation build target selection did not refresh cleanly.")
local selectedFormation = KWR.Store:Get().snapshot.formation
KWR.MainWindow:UpdateTactical(KWR.Store:Get())
assert(KWR.db.profile.formation.selectedCompID == "CONTROL_CLEAVE"
    and selectedFormation.buildTarget
    and selectedFormation.buildTarget.id == "CONTROL_CLEAVE"
    and #(selectedFormation.buildRequirements or {}) == 10
    and selectedFormation.positioningTitle == "COMP JOBS"
    and selectedFormation.positioning[5] == "Rogue creates kills."
    and selectedFormation.positioning[#selectedFormation.positioning] == "Mage peels."
    and selectedFormation.recommendations[1]
    and selectedFormation.recommendations[1].label:find("Protection Warrior", 1, true),
    "Formation setup did not pivot recruiting toward the selected meta comp.")
assert(KWR.MainWindow.pages.TACTICAL.battlefieldCard.formation.title.value:find(
        "Control Cleave", 1, true)
    and KWR.MainWindow.pages.TACTICAL.winCard.value.value:find(
        "TARGET:", 1, true)
    and KWR.MainWindow.pages.TACTICAL.winCard.value.value:find(
        "Control Cleave", 1, true),
    "Visible setup board did not repaint to the selected build target.")
assert((function()
    local evaluated = KWR.FormationAdvisor:Evaluate({
        context = { mapKey = "WORLD", inPvP = false },
        roster = {
            { shortName = "TankOne", classFile = "WARRIOR", spec = "Protection", role = "TANK" },
            { shortName = "DiscOne", classFile = "PRIEST", spec = "Discipline", role = "HEALER" },
            { shortName = "HolyOne", classFile = "PRIEST", spec = "Holy", role = "HEALER" },
            { shortName = "RestoOne", classFile = "SHAMAN", spec = "Restoration", role = "HEALER" },
            { shortName = "BalanceOne", classFile = "DRUID", spec = "Balance", role = "DAMAGER" },
            { shortName = "HavocOne", classFile = "DEMONHUNTER", spec = "Havoc", role = "DAMAGER" },
            { shortName = "UnholyOne", classFile = "DEATHKNIGHT", spec = "Unholy", role = "DAMAGER" },
            { shortName = "FrostOne", classFile = "MAGE", spec = "Frost", role = "DAMAGER" },
            { shortName = "AffOne", classFile = "WARLOCK", spec = "Affliction", role = "DAMAGER" },
        },
    })
    local openDamage, named = false, {}
    for _, recommendation in ipairs(evaluated.recommendations or {}) do
        if recommendation.acquisition == "OPEN SLOT" and recommendation.role == "DAMAGER" then
            openDamage = true
        elseif recommendation.acquisition ~= "OPEN SLOT" then
            if not recommendation.replaceName
                or recommendation.acquisition ~= "REPLACE " .. recommendation.replaceName then
                return false
            end
            named[recommendation.replaceName] = true
        end
    end
    return openDamage and named.HolyOne and named.RestoOne and named.HavocOne
end)(), "Formation replacements did not name specific swap-out players or preserve the open role need.")
KWR.MainWindow:UpdateTeam(KWR.Store:Get())
local setupPlan = KWR.MainWindow.pages.TEAM.doctrineCard.value.value
assert(setupPlan:find("TARGET ROSTER", 1, true)
    and setupPlan:find("Protection Warrior", 1, true)
    and setupPlan:find("Discipline Priest", 1, true)
    and setupPlan:find("TARGET NEED", 1, true)
    and setupPlan:find("TARGET SPECS", 1, true)
    and setupPlan:find("COMP JOBS", 1, true)
    and setupPlan:find(selectedFormation.buildTarget.assignments, 1, true)
    and not setupPlan:find("POSITIONING", 1, true),
    "Setup plan did not render the selected comp's full roster and jobs.")
assert(KWR.MainWindow:CycleFormationBuildTarget(1),
    "Formation build target cycle did not advance cleanly.")
local cycledFormation = KWR.Store:Get().snapshot.formation
KWR.MainWindow:UpdateTactical(KWR.Store:Get())
assert(cycledFormation.buildTarget
    and cycledFormation.buildTarget.id ~= "CONTROL_CLEAVE",
    "Formation build target cycle did not move to the next reviewed comp.")
assert(not KWR.MainWindow.pages.TACTICAL.battlefieldCard.formation.title.value:find(
        "Control Cleave", 1, true),
    "Visible setup board did not repaint after cycling to the next build target.")
assert(KWR.MainWindow:SetFormationBuildTarget(nil),
    "Formation build target reset did not restore automatic selection.")
KWR.MainWindow:Hide()
local persistedRosterShown = KWR.db.profile.combatRoster.shown
KWR.db.profile.combatRoster.shown = false
if KWR.Presentation then
    local nativeRaidManager = CompactRaidFrameManager
    local nativeRaidContainer = CompactRaidFrameContainer
    CompactRaidFrameManager = {
        IsShown = function()
            error("Presentation must not inspect addon-managed raid frames")
        end,
    }
    CompactRaidFrameContainer = {
        IsShown = function()
            error("Presentation must not inspect addon-managed raid frames")
        end,
    }
    KWR.Presentation.session = nil
    KWR.Presentation.active = false
    KWR.Presentation.lastState = KWR.Store:Get()
    KWR.Presentation:Activate(KWR.Store:Get())
    assert(KWR.Presentation.session
        and KWR.Presentation.session.nativeRaidFramesUntouched == true
        and compactRaidManagerSettings.IsShown == true,
        "Presentation activate should leave addon-managed native raid frames untouched.")
    KWR.Presentation:Deactivate()
    assert(compactRaidManagerSettings.IsShown == true,
        "Presentation deactivate should leave addon-managed native raid frames untouched.")
    KWR.Presentation.session = {
        rosterShown = true,
        teamShown = true,
        enemyShown = true,
    }
    KWR.Presentation.lastState = KWR.Store:Get()
    KWR.Presentation:RestoreSurfaces()
    assert(KWR.db.profile.combatRoster.shown == false
        and KWR.CombatRoster:AnyShown(),
        "Presentation restore should temporarily restore compact roster visibility without persisting it.")
    mockInstanceType = "party"
    assert(KWR.MatchRuntime:ForceRefresh("presentation-hide-pve"), "Presentation PvE refresh failed.")
    KWR.Presentation.session = {
        rosterShown = true,
        teamShown = true,
        enemyShown = true,
    }
    KWR.Presentation.lastState = KWR.Store:Get()
    KWR.Presentation:RestoreSurfaces()
    assert(not KWR.CombatRoster:AnyShown(),
        "Presentation restore should hide compact RBG surfaces outside battlegrounds.")
    mockInstanceType = "pvp"
    assert(KWR.MatchRuntime:ForceRefresh("presentation-restore-pvp"), "Presentation battleground refresh failed.")
    CompactRaidFrameManager = nativeRaidManager
    CompactRaidFrameContainer = nativeRaidContainer
end
KWR.db.profile.combatRoster.shown = persistedRosterShown
assert(KWR.ReporterMap == nil,
    "Retired KWR Support HUD was still loaded in the production module graph.")
end
RunLateSmokeChecks()
do
local identifierState = {
    snapshot = {
        combat = {},
    },
}
local friendlyHealerIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Friendly-Healer",
    shortName = "Friendly",
    role = "HEALER",
    classFile = "PRIEST",
    healthPercent = 41,
}, true, identifierState, false)
assert(friendlyHealerIdentifier.kind == "ROLE"
    and friendlyHealerIdentifier.showHealth == false
    and friendlyHealerIdentifier.showCast == false,
    "Friendly battlefield identifier did not stay role-and-name only.")
local friendlyUnknownIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Friendly-Unknown",
}, true, identifierState, false)
assert(friendlyUnknownIdentifier.texture == nil
    and friendlyUnknownIdentifier.badge == "?",
    "Unknown friendly role fabricated a role icon instead of degrading safely.")
local orbCarrierIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Orb-Carrier",
    role = "DAMAGER",
    classFile = "MAGE",
    carrier = true,
    carriedObjective = "Purple Orb",
}, true, identifierState, false)
assert(orbCarrierIdentifier.kind == "ORB"
    and orbCarrierIdentifier.texture ~= nil
    and orbCarrierIdentifier.showHealth == false,
    "Orb carrier identifier did not replace the teammate role marker.")
local enemyIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Enemy-Mage",
    shortName = "Enemy",
    classFile = "MAGE",
    healthPercent = 72,
}, false, identifierState, false)
assert(enemyIdentifier.kind == "CLASS"
    and enemyIdentifier.showHealth == false
    and enemyIdentifier.showCast == false,
    "Enemy battlefield identifier exposed default health or cast clutter.")
local reviewedEnemy = {
    key = "shared-palette-target",
    name = "Enemy-Warrior",
    shortName = "Enemy",
    classFile = "WARRIOR",
}
identifierState.snapshot.combat.localTarget = reviewedEnemy
local reviewedIdentifier = KWR.CursorRing:BuildIdentifierModel(
    reviewedEnemy, false, identifierState, false)
assert(reviewedIdentifier.ringColor[1] == KWR.Theme.combatColors.KILL.outer[1]
    and reviewedIdentifier.ringColor[2] == KWR.Theme.combatColors.KILL.outer[2]
    and reviewedIdentifier.ringColor[3] == KWR.Theme.combatColors.KILL.outer[3],
    "Battlefield identifier kill color diverged from the shared crosshair palette.")
assert(KWR.Theme:Color("KWR_COLOR_PRIMARY") == KWR.Theme:Color("gold")
    and KWR.Theme:Color("KWR_COLOR_SURFACE") == KWR.Theme:Color("panel")
    and KWR.Theme.tokens.colors.KWR_COLOR_BG[1] > 0
    and KWR.Theme.tokens.spacing.KWR_SPACING_12 == 12
    and KWR.Theme:Metric("KWR_RADIUS_MD") == 10
    and type(KWR.Theme:Token("KWR_FONT_HEADER")) == "table",
    "Theme token contract drifted from the locked KWR design-system names.")
assert(KWR.modules.IconRegistry
    and KWR.Icons
    and KWR.Icons.icons.kill == true
    and KWR.Icons.roleMap.TANK == "tank"
    and type(KWR.Icons.TexturePath) == "function"
    and type(KWR.Icons.BrandPath) == "function",
    "KWR icon registry did not load into the shared addon module graph.")
identifierState.snapshot.combat.localTarget = nil
local activeCastIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Enemy-Priest",
    classFile = "PRIEST",
    priorityCast = { name = "Priority Cast", remaining = 2.4 },
}, false, identifierState, true)
assert(activeCastIdentifier.showHealth == true
    and activeCastIdentifier.showCast == true,
    "Current priority-cast target did not enable the bounded health and cast strips.")
local expiredCastIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Enemy-Priest",
    classFile = "PRIEST",
    priorityCast = { name = "Expired Cast", remaining = 0 },
}, false, identifierState, false)
assert(expiredCastIdentifier.showCast == false,
    "Expired priority cast remained visible on the battlefield identifier.")
local flagCarrierIdentifier = KWR.CursorRing:BuildIdentifierModel({
    name = "Flag-Carrier",
    classFile = "DRUID",
    carrier = true,
    carriedObjective = "Horde Flag",
}, false, identifierState, false)
assert(flagCarrierIdentifier.kind == "FLAG"
    and flagCarrierIdentifier.texture ~= nil,
    "Flag carrier identifier did not replace the enemy class marker.")
end
if previewState and previewState.snapshot and previewState.snapshot.context
    and previewState.snapshot.context.preview == true then
    local reticlePreviewState = KWR.Util:Copy(previewState)
    local targetEnemy = reticlePreviewState.snapshot.enemies[1]
    local pivotEnemy = reticlePreviewState.snapshot.enemies[2]
    targetEnemy.priorityCast = nil
    targetEnemy.defensivesActive = nil
    targetEnemy.carrier = nil
    pivotEnemy.priorityCast = nil
    pivotEnemy.defensivesActive = nil
    pivotEnemy.carrier = nil
    reticlePreviewState.snapshot.combat.localTarget = targetEnemy
    reticlePreviewState.snapshot.combat.killTarget = pivotEnemy
    reticlePreviewState.snapshot.combat.localTargetReason = "Closer local kill"
    mockLiveEnemies.target = {
        name = targetEnemy.shortName or KWR.Util:ShortName(targetEnemy.name),
        realm = "OtherRealm",
        guid = "Player-9-TARGET",
        className = targetEnemy.className or "Priest",
        classFile = targetEnemy.classFile or "PRIEST",
        classID = targetEnemy.classID or 5,
        health = 820,
        healthMax = 1000,
    }
    local reticleLocal = KWR.CursorRing:ResolveReticleState(reticlePreviewState)
    assert(reticleLocal.label == "KILL",
        "Reticle did not distinguish the current local target from generic kill state.")
    KWR.CursorRing:ApplyReticleState(reticleLocal)
    assert(KWR.CursorRing.reticle.outer.vertexColor[1]
        == KWR.Theme.combatColors.KILL.outer[1]
        and KWR.CursorRing.reticle.outer.vertexColor[2]
            == KWR.Theme.combatColors.KILL.outer[2]
        and KWR.CursorRing.reticle.outer.vertexColor[3]
            == KWR.Theme.combatColors.KILL.outer[3],
        "Target reticle kill color diverged from the shared crosshair palette.")
    KWR.CursorRing:ApplyReticle()
    assert(KWR.CursorRing.reticle.labelPlate.width >= 150
        and KWR.CursorRing.reticle.detailPlate.width >= 210,
        "Reticle polish did not provision readable caption plates.")
    assert(KWR.CursorRing.reticle.labelPlate.backdropColor[4] == 0
        and KWR.CursorRing.reticle.detailPlate.backdropColor[4] == 0,
        "Reticle caption plates painted an opaque background over the battlefield.")
    reticlePreviewState.snapshot.combat.localTarget = pivotEnemy
    reticlePreviewState.snapshot.combat.killTarget = pivotEnemy
    local reticleSwap = KWR.CursorRing:ResolveReticleState(reticlePreviewState)
    assert(reticleSwap.label == "SWAP",
        "Reticle did not call for a local target swap when the current target was wrong.")
    reticlePreviewState.snapshot.combat.localTarget = nil
    reticlePreviewState.snapshot.combat.killTarget = nil
    local reticleObserved = KWR.CursorRing:ResolveReticleState(reticlePreviewState)
    assert(reticleObserved.label == "TARGET"
        and reticleObserved.detail ~= "",
        "Reticle did not carry observed target-state context when no command target applied.")
    mockLiveEnemies.target = nil
end
KWR.MainWindow:ToggleLauncherMenu()
assert(KWR.MainWindow.launcherMenu.stateBadge.text.value ~= ""
    and KWR.MainWindow.launcherMenu.truthBadge.text.value ~= ""
    and KWR.MainWindow.launcherMenu.summary.value ~= ""
    and KWR.MainWindow.launcherMenu.brand.texture ~= nil
    and KWR.MainWindow.frame.brand.texture ~= nil
    and KWR.MainWindow.frame.commandBadge.icon.texture ~= nil
    and KWR.MainWindow.frame.truthBadge.icon.texture ~= nil
    and KWR.MainWindow.frame.reporterBadge.icon.texture ~= nil
    and KWR.MainWindow.frame.doctrineBadge.icon.texture ~= nil
    and KWR.MainWindow.tabs.INTEL.label.value == "REVIEW / AAR"
    and KWR.MainWindow.launcherMenu.settingsButton.label.value == "SETTINGS"
    and KWR.MainWindow.launcherMenu.closeButton.label.value == "CLOSE MENU"
    and KWR.MainWindow.launcherMenu.buttons[1].label.value == "WAR ROOM"
    and KWR.MainWindow.launcherMenu.buttons[2].label.value == "FIGHT NOW"
    and KWR.MainWindow.launcherMenu.buttons[3].label.value == "TEAM BOARD"
    and KWR.MainWindow.launcherMenu.buttons[4].label.value == "MAP / SHIFT-M"
    and KWR.MainWindow.launcherMenu:GetFrameStrata() == "HIGH"
    and KWR.MainWindow.launcherMenu.buttons[3].icon.texture ~= nil,
    "Launcher menu or top-level shell naming drifted from the command-center contract.")
KWR.MainWindow.launcherMenu.buttons[3].scripts.OnClick()
assert(KWR.MainWindow.activePage == "TEAM"
    and not KWR.CombatRoster:AnyShown(),
    "Launcher Team Roster action opened the compact popup instead of the full Team page.")
KWR.MainWindow.launcherMenu:Hide()
KWR.MainWindow:RestoreCompactSurfaces()
assert(KWR.HUD.frame:IsShown(),
    "Compact HUD was not restored after expanded mode.")
KWR.MainWindow.frame:Hide()

mockPvP = false
mockInstanceType = "arena"
assert(KWR.MatchRuntime:ForceRefresh("smoke-arena"), "Arena capture refresh failed.")
assert(KWR.Store:Get().snapshot.context.instanceType == "arena"
    and KWR.Store:Get().snapshot.context.inPvP ~= true,
    "Arena context was not captured as a non-battleground surface.")
assert(KWR.MainWindow:Show("TACTICAL") == false,
    "Expanded War Room should refuse to open in arena.")
assert(KWR.CombatRoster:Show("TEAM") == false
    and not KWR.CombatRoster:AnyShown(),
    "Combat roster should remain hidden in arena.")
KWR.HUD:Update(KWR.Store:Get())
assert(not KWR.HUD.frame:IsShown(),
    "Compact HUD should remain hidden in arena.")
assert(KWR.MainWindow.launcher:IsShown() == false,
    "Launcher should hide while arena suppression is active.")
mockInstanceType = "party"
local partyInInstance, partyInstanceType = IsInInstance()
assert(partyInInstance == true and partyInstanceType == "party",
    "PvE fixture did not expose party instance truth before refresh: "
        .. tostring(mockPvP) .. "/" .. tostring(mockInstanceType) .. "/"
        .. tostring(partyInInstance) .. "/" .. tostring(partyInstanceType))
assert(KWR.MatchRuntime:ForceRefresh("smoke-party"), "PvE instance refresh failed.")
local partyContext = KWR.Store:Get().snapshot.context
assert(partyContext.instanceType == "party"
    and partyContext.inPvP ~= true
    and partyContext.preview ~= true,
    "PvE instance context was not captured as non-preview truth: "
        .. tostring(partyContext.instanceType) .. "/"
        .. tostring(partyContext.inPvP) .. "/"
        .. tostring(partyContext.preview))
assert(KWR.MainWindow:Show("TACTICAL") == false,
    "Expanded War Room should refuse to open in PvE instances.")
assert(KWR.CombatRoster:Show("TEAM") == false
    and not KWR.CombatRoster:AnyShown(),
    "Combat roster should remain hidden in PvE instances.")
KWR.HUD:Update(KWR.Store:Get())
assert(not KWR.HUD.frame:IsShown(),
    "Compact HUD should remain hidden in PvE instances.")
assert(KWR.MainWindow.launcher:IsShown() == false,
    "Launcher should hide in PvE instances.")
mockInstanceType = "none"
assert(KWR.MatchRuntime:ForceRefresh("smoke-world-restore"), "World restore refresh failed.")
assert(KWR.MainWindow.launcher:IsShown() == true,
    "Launcher did not restore after leaving arena suppression.")

local originalAfter = C_Timer.After
local scheduled = {}
C_Timer.After = function(delay, callback)
    scheduled[#scheduled + 1] = { delay = delay, callback = callback }
end
do
    local saved = {
        listeners = KWR.Store.listeners,
        notifyScheduled = KWR.Store.notifyScheduled,
        notifyQueue = KWR.Store.notifyQueue,
        notifyIndex = KWR.Store.notifyIndex,
        notifyPrevious = KWR.Store.notifyPrevious,
        notifyState = KWR.Store.notifyState,
        notifyGeneration = KWR.Store.notifyGeneration,
        notifyPassGeneration = KWR.Store.notifyPassGeneration,
        notifyFlushing = KWR.Store.notifyFlushing,
    }
    KWR.Store.listeners = {}
    KWR.Store.notifyScheduled = false
    KWR.Store.notifyQueue = nil
    KWR.Store.notifyIndex = 1
    KWR.Store.notifyPrevious = nil
    KWR.Store.notifyState = nil
    KWR.Store.notifyGeneration = 0
    KWR.Store.notifyPassGeneration = 0
    KWR.Store.notifyFlushing = false
    local delivered = {}
    for index = 1, 10 do
        local owner = { index = index }
        KWR.Store:Subscribe(owner, function(self, state)
            delivered[self.index] = state.revision
        end)
    end
    KWR.Store:QueueNotifications(
        { revision = 0, diagnostics = {} },
        { revision = 1, diagnostics = {} })
    assert(#scheduled == 1,
        "Store notification batching did not defer its remaining listeners.")
    KWR.Store:QueueNotifications(
        { revision = 1, diagnostics = {} },
        { revision = 2, diagnostics = {} })
    local timerIndex = 1
    while scheduled[timerIndex] do
        scheduled[timerIndex].callback()
        timerIndex = timerIndex + 1
    end
    for index = 1, 10 do
        assert(delivered[index] == 2,
            "Store notification batching stranded a listener on an older revision.")
    end
    KWR.Store.listeners = saved.listeners
    KWR.Store.notifyScheduled = saved.notifyScheduled
    KWR.Store.notifyQueue = saved.notifyQueue
    KWR.Store.notifyIndex = saved.notifyIndex
    KWR.Store.notifyPrevious = saved.notifyPrevious
    KWR.Store.notifyState = saved.notifyState
    KWR.Store.notifyGeneration = saved.notifyGeneration
    KWR.Store.notifyPassGeneration = saved.notifyPassGeneration
    KWR.Store.notifyFlushing = saved.notifyFlushing
    scheduled = {}
end
KWR.HUD.eventFrame.scripts.OnEvent(KWR.HUD.eventFrame, "PVP_MATCH_COMPLETE")
assert(#scheduled == 3,
    "HUD did not schedule bounded match-complete refreshes.")
scheduled = {}
KWR.HUD.eventFrame.scripts.OnEvent(KWR.HUD.eventFrame, "PLAYER_ENTERING_WORLD")
assert(#scheduled == 3,
    "HUD did not schedule bounded transition refreshes.")
scheduled = {}
KWR.HUD.eventFrame.scripts.OnEvent(KWR.HUD.eventFrame, "PLAYER_REGEN_ENABLED")
assert(#scheduled == 1,
    "HUD did not schedule a post-combat refresh.")
scheduled = {}
KWR.MatchRuntime.timerToken = (KWR.MatchRuntime.timerToken or 0) + 1
KWR.MatchRuntime.pending = false
KWR.MatchRuntime.pendingDueAt = nil
KWR.MatchRuntime.pendingRevision = nil
KWR.MatchRuntime.pendingReason = nil
KWR.MatchRuntime.pendingSettle = nil
KWR.MatchRuntime.requiredSettleAt = nil
KWR.MatchRuntime.followupChainCount = 0
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
KWR.MatchRuntime.timerToken = (KWR.MatchRuntime.timerToken or 0) + 1
KWR.MatchRuntime.pending = false
KWR.MatchRuntime.pendingDueAt = nil
KWR.MatchRuntime.pendingRevision = nil
KWR.MatchRuntime.pendingReason = nil
KWR.MatchRuntime.pendingSettle = nil
KWR.MatchRuntime.requiredSettleAt = currentTime + 20
KWR.MatchRuntime.followupChainCount = 0
local queueFollowups = KWR.MatchRuntime.diagnostics.queueFollowups or 0
KWR.MatchRuntime:Queue("queue-storm-1", 0.02)
KWR.MatchRuntime:Queue("queue-storm-2", 0.02)
currentTime = currentTime + 1
scheduled[1].callback()
assert(#scheduled == 2,
    "Runtime queue did not schedule a single bounded follow-up under churn.")
KWR.MatchRuntime:Queue("queue-storm-3", 0.02)
currentTime = currentTime + 1
scheduled[2].callback()
assert(#scheduled == 3
    and (KWR.MatchRuntime.diagnostics.queueFollowups or 0) == queueFollowups + 1,
    "Runtime queue chained more than one coalesced follow-up before settling.")
currentTime = currentTime + 20
scheduled[3].callback()
assert(KWR.MatchRuntime.pending == false
    and KWR.MatchRuntime.followupChainCount == 0,
    "Runtime queue did not clear follow-up chain state after settle refresh.")
KWR.MatchRuntime.requiredSettleAt = nil
scheduled = {}
KWR.MatchRuntime:ScheduleTransitionSweep("transition-test", false)
assert(#scheduled == 6,
    "Zone transition did not schedule six bounded truth-settle passes.")
scheduled = {}
KWR.MatchRuntime:ScheduleTransitionSweep("transition-roster-test", true)
assert(#scheduled == 4,
    "Roster transition did not schedule four bounded truth-settle passes.")
KWR.MatchRuntime.transitionToken = KWR.MatchRuntime.transitionToken + 1
C_Timer.After = originalAfter

KWR.Commander.lastCommand = { signature = "STALE_COMMAND" }
KWR.Commander.lastSignature = "STALE_COMMAND"
KWR.Commander.lastActivePlay = { id = "STALE_ACTIVE_PLAY" }
KWR.Commander.metrics = {
    issued = 12,
    replacements = 3,
    lifetimes = { samples = { 12, 24, 36 } },
}
KWR.Commander.candidateTrends = {
    STALE_CANDIDATE = { consecutiveWins = 5 },
}
KWR.Commander.overrideLog = {
    { gateClass = "INVALIDATION" },
}
KWR.Commander.suppressionLog = {
    { gateClass = "PERSISTENCE_HOLD" },
}
KWR.Commander.history = {
    { signature = "STALE_COMMAND" },
}
KWR.MatchRuntime:ResetTransientTruth()
assert(KWR.Commander.lastCommand == nil
    and KWR.Commander.lastSignature == nil
    and KWR.Commander.lastActivePlay == nil
    and KWR.Commander.metrics == nil
    and KWR.Commander.candidateTrends == nil
    and #KWR.Commander:GetOverrideLog() == 0
    and #KWR.Commander:GetSuppressionLog() == 0
    and #KWR.Commander:GetHistory() == 0,
    "Runtime transient reset did not clear Commander session stability state.")

do
    local teamfightSnapshot = {
        context = {
            inPvP = true,
            instanceType = "pvp",
            mapKey = "ARATHI",
            mapName = "Arathi Basin",
            kind = "NODE",
            phase = "LIVE",
        },
        roster = {
            {
                name = "Knomercy",
                guid = "Player-Knomercy",
                role = "DAMAGER",
                spec = "Subtlety",
                connected = true,
                dead = false,
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

KWR.db.profile.launcher.angle = 10
KWR.db.profile.combatRoster.teamMini.x = 99
KWR.db.profile.combatRoster.enemyMini.x = 101
KWR.LayoutCoordinator:Reset()
assert(KWR.db.profile.launcher.angle == 225
    and KWR.db.profile.combatRoster.teamMini.x == -170
    and KWR.db.profile.combatRoster.enemyMini.x == 170,
    "Coordinated layout reset did not restore launcher and combat-roster positions.")

local result = { passed = 0, failed = 0 }
if KWR.Diagnostics and type(KWR.Diagnostics.Run) == "function" then
    result = KWR.Diagnostics:Run()
    if result.failed > 0 then
        local report = KWR.Diagnostics:Report()
        error(report)
    end
end

print("KWR_SMOKE_PASS checks=" .. tostring(result.passed))
