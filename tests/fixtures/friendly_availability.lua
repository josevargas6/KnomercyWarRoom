return function(KWR)
    local names = { "UnitIsDeadOrGhost", "UnitIsConnected", "UnitIsVisible",
        "UnitAffectingCombat", "UnitGroupRolesAssigned", "UnitGUID", "UnitIsUnit",
        "IsInRaid", "IsInGroup", "IsInInstance", "GetNumGroupMembers", "GetRaidRosterInfo",
        "GetSpecialization", "GetInspectSpecialization", "C_Map", "C_PvP", "EventRegistry", "issecretvalue" }
    local saved = {}
    for _, name in ipairs(names) do saved[name] = _G[name] end
    local opaque = {}
    issecretvalue = function(value) return rawequal(value, opaque) end
    IsInRaid, IsInGroup = function() return false end, function() return false end
    IsInInstance = function() return false, "none" end
    UnitIsUnit = function() return false end
    UnitGUID = function() return "Friendly-Availability-1" end
    GetSpecialization, GetInspectSpecialization = nil, nil
    C_Map, C_PvP, EventRegistry = nil, {}, nil
    local role, unitName = "DAMAGER", "FriendlyActor-Realm"
    UnitGroupRolesAssigned = function() return role end
    local namespace = setmetatable({
        RegisterModule = function() end,
        Util = setmetatable({
            UnitName = function() return unitName end,
            UnitClass = function() return "Rogue", "ROGUE" end,
        }, { __index = KWR.Util }),
        TeamResolver = setmetatable({ Capture = function() return {}, {} end }, { __index = KWR.TeamResolver }),
        EnemyIntel = { Capture = function() return {} end },
    }, { __index = KWR })
    assert(loadfile(ResolveAddonPath("Runtime/Sensors.lua")))("KnomercyWarRoom", namespace)
    namespace.Sensors:OnInitialize()
    local function capture()
        local snapshot = namespace.Sensors:Capture()
        assert(#snapshot.roster == 1, "Unknown readings removed roster identity")
        return snapshot.roster[1], snapshot
    end
    local problem = { type = "LOCAL_HEALER_CONTROL", verb = "Subdue", severity = 1000000,
        confidence = "CONFIRMED", enemy = { name = "Enemy", guid = "Enemy-1", role = "HEALER" } }
    local function assignments(player)
        return KWR.AssignmentOptimizer:Optimize({ friendlies = { player } }, { problem }, {})
    end
    local cases = {
        { label = "absent" }, { label = "invalid", value = "true" },
        { label = "number", value = 1 }, { label = "protected", value = opaque },
        { label = "throws", throws = true },
    }
    for _, case in ipairs(cases) do
        local function read()
            if case.throws then error("fixture unavailable") end
            return case.value
        end
        UnitIsDeadOrGhost, UnitIsConnected, UnitIsVisible, UnitAffectingCombat = read, read, read, read
        local player, snapshot = capture()
        local state = KWR.FriendlyRoleState:Build(player)
        local board = KWR.BoardState:FromSnapshot(snapshot, KWR.FactStore:FromSnapshot(snapshot))
        assert(player.dead == nil and player.connected == nil and player.visible == nil
            and player.inCombat == nil, case.label .. " sensor reading became a boolean")
        assert(board.friendlies[1].dead == nil and board.friendlies[1].connected == nil
            and board.friendlies[1].visible == nil, case.label .. " board defaulted unknown")
        assert(state.available == nil and state.availability == "UNKNOWN"
            and state.confidence == "UNKNOWN", case.label .. " availability became confirmed")
        assert(#assignments(player) == 0, case.label .. " unknown actor received a high-scoring job")
    end
    UnitIsDeadOrGhost, UnitIsConnected, UnitIsVisible, UnitAffectingCombat = nil, nil, nil, nil
    assert(capture().connected == nil, "Missing API defaulted to online")
    UnitIsDeadOrGhost = function() return true end
    local player = capture()
    assert(KWR.FriendlyRoleState:Build(player).available == false and #assignments(player) == 0,
        "Known dead must exclude even with unknown connection")
    UnitIsDeadOrGhost = function() return nil end
    UnitIsConnected = function() return false end
    player = capture()
    assert(KWR.FriendlyRoleState:Build(player).available == false and #assignments(player) == 0,
        "Known offline must exclude even with unknown death state")
    UnitIsConnected = function() return true end
    assert(#assignments(capture()) == 0, "Online alone implied alive")
    UnitIsDeadOrGhost = function() return false end
    UnitIsConnected = nil
    assert(#assignments(capture()) == 0, "Alive alone implied online")
    UnitIsConnected, UnitIsVisible, UnitAffectingCombat = function() return true end,
        function() return false end, function() return false end
    player = capture()
    assert(player.visible == false and player.inCombat == false, "Public false readings were lost")
    assert(KWR.FriendlyRoleState:Build(player).available == true and #assignments(player) == 1,
        "Later known alive/online actor did not recover")
    role = "NONE"
    namespace.Sensors.specCache = {}
    player = capture()
    local unknownRole = KWR.FriendlyRoleState:Build(player)
    assert(unknownRole.role == "NONE" and unknownRole.roleKnown == false
        and unknownRole.profile.pressure == nil and unknownRole.confidence == "UNKNOWN",
        "Unknown role gained a damage-role capability profile")
    assert(#assignments(player) == 0, "Unknown role received an executable control job")
    role = "DAMAGER"
    assert(#assignments(capture()) == 1, "Known role did not restore assignment eligibility")
    IsInRaid = function() return true end
    GetNumGroupMembers = function() return 1 end
    GetRaidRosterInfo = function()
        return "DifferentActor-Realm", 0, 1, 80, "Rogue", "ROGUE", nil, nil, nil, "DAMAGER"
    end
    UnitIsVisible = function() return true end
    player = capture()
    assert(player.name == "DifferentActor-Realm" and player.unitStable == false
        and player.visible == nil and player.dead == nil and player.connected == nil,
        "Unstable raid token leaked another player's known unit state")
    assert(#assignments(player) == 0, "Unhydrated raid actor received an executable job")
    unitName = "DifferentActor-Realm"
    player = capture()
    assert(player.unitStable == true and player.visible == true and #assignments(player) == 1,
        "Hydrated raid token failed to recover public availability")
    local scoreRows = {
        { name = "Offline-Realm", guid = "Offline-1", faction = 0, role = "DAMAGER" },
        { name = "ScoreOnly-Realm", guid = "ScoreOnly-1", faction = 0, role = "DAMAGER",
            connected = true, dead = false, visible = true },
    }
    local repaired, hydration = KWR.TeamResolver:ReconcileFriendlyRoster({
        { name = "Offline-Realm", guid = "Offline-1", role = "DAMAGER", connected = false,
            dead = false, visible = false },
    }, { scoreFaction = 0 }, scoreRows, 2)
    assert(hydration.source == "scoreboard_complete" and #repaired == 2,
        "Fixture did not exercise scoreboard roster repair")
    local byGUID = {}
    for _, row in ipairs(repaired) do byGUID[row.guid] = row end
    assert(byGUID["Offline-1"].connected == false and byGUID["Offline-1"].dead == false
        and byGUID["Offline-1"].visible == false, "Scoreboard repair lost known public false readings")
    assert(byGUID["ScoreOnly-1"].connected == nil and byGUID["ScoreOnly-1"].dead == nil
        and byGUID["ScoreOnly-1"].visible == nil, "Scoreboard identity invented physical state")
    assert(#assignments(byGUID["Offline-1"]) == 0 and #assignments(byGUID["ScoreOnly-1"]) == 0,
        "Repaired offline or scoreboard-only actor received an executable job")
    local equalProblem = { type = "LOCAL_HEALER_CONTROL", verb = "Subdue", severity = 100,
        confidence = "CONFIRMED", enemy = { name = "Enemy", guid = "Enemy-1", role = "HEALER" } }
    local firstActor = { name = "Zulu-Realm", guid = "Actor-B", role = "DAMAGER", classFile = "ROGUE",
        spec = "Subtlety", dead = false, connected = true }
    local secondActor = { name = "Alpha-Realm", guid = "Actor-A", role = "DAMAGER", classFile = "ROGUE",
        spec = "Subtlety", dead = false, connected = true }
    local function choose(rows)
        return KWR.AssignmentOptimizer:Optimize({ friendlies = rows }, { equalProblem }, {})[1]
    end
    local firstChoice = choose({ firstActor, secondActor })
    firstActor.name, secondActor.name = "Changed-First", "Changed-Second"
    local reorderedChoice = choose({ secondActor, firstActor })
    assert(firstChoice and reorderedChoice and firstChoice.actorGUID == "Actor-A"
        and reorderedChoice.actorGUID == "Actor-A",
        "Equal assignment tie-break depended on display name or roster order")
    for _, name in ipairs(names) do _G[name] = saved[name] end
end
