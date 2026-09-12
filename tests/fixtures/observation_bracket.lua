return function(KWR)
    local assault = KWR.ObjectiveRules:Transition({ label = "Farm", owner = "FRIENDLY",
        state = "CONTROLLED" }, { kind = "ASSAULT", objective = "Farm", player = "Enemy", at = 10 },
        { mapKey = "ARATHI" })
    assert(assault.accepted and assault.state == "CONTESTED" and assault.owner == "FRIENDLY",
        "Observed node assault did not retain owner while projecting contested transition")
    local captured = KWR.ObjectiveRules:Transition({ label = "Horde Flag", state = "CARRIED" },
        { kind = "FLAG_CAPTURE", objective = "Horde Flag", player = "Verite", at = 11 },
        { mapKey = "WSG" })
    assert(captured.accepted and captured.state == "CAPTURED" and captured.capturer == "Verite",
        "Flag capture did not preserve its typed observed transition")
    local invalid = KWR.ObjectiveRules:Transition({ label = "Farm", state = "CONTROLLED" },
        { kind = "FLAG_CAPTURE", objective = "Farm", at = 12 }, { mapKey = "ARATHI" })
    assert(invalid.accepted == false and invalid.state == "CONTROLLED",
        "A cross-family transition fabricated node state")
    local stale = KWR.ObjectiveRules:Transition({ label = "Farm", owner = "FRIENDLY",
        state = "CONTROLLED", observedAt = 20 }, { kind = "ASSAULT", objective = "Farm", at = 19 },
        { mapKey = "ARATHI" })
    assert(stale.accepted == false and stale.reason == "STALE_TRANSITION"
        and stale.state == "CONTROLLED",
        "An out-of-order objective transition advanced current state")
    local savedTime, savedPvp, savedInstance, savedSecret, savedRegistry = GetTime, C_PvP,
        IsInInstance, issecretvalue, EventRegistry
    local clock = 100
    GetTime = function() return clock end
    local snapshot = { context = { inPvP = true, capturedAt = 5 },
        enemies = { { name = "Old-Enemy", observedAt = 10, visible = true } },
        roster = { { name = "Unknown-Friendly" } } }
    local first = KWR.FactStore:FromSnapshot(snapshot)
    clock = 200
    local second = KWR.FactStore:FromSnapshot(snapshot)
    assert(first.facts[2].observedAt == 10 and second.facts[2].observedAt == 10
        and first.generatedAt == 100 and second.generatedAt == 200,
        "Reprocessing re-stamped an unchanged observation")
    assert(second.facts[3].observedAt == nil and second.facts[3].confidence == "UNKNOWN",
        "Roster presence confirmed unknown friendly fields")
    assert(first.facts[1].observedAt == 5 and second.facts[1].observedAt == 5,
        "Context projection replaced captured time with processing time")
    for _, invalid in ipairs({ -1, math.huge, 0 / 0, "invalid", false }) do
        snapshot.enemies[1].observedAt = invalid
        snapshot.enemies[1].confidence = "CONFIRMED"
        local row = KWR.FactStore:FromSnapshot(snapshot).facts[2]
        assert(row.observedAt == nil and row.confidence == "UNKNOWN",
            "Invalid observation time granted confirmation")
    end
    snapshot.enemies[1].observedAt = nil
    snapshot.enemies[1].lastSeenAt = 15
    assert(KWR.FactStore:FromSnapshot(snapshot).facts[2].observedAt == 15,
        "Last-seen observation time was lost")
    snapshot.enemies[1].lastSeenAt = nil
    snapshot.enemies[1].capturedAt = 20
    assert(KWR.FactStore:FromSnapshot(snapshot).facts[2].observedAt == 20,
        "Row capture time was lost")
    snapshot.enemies[1].observedAt = 300
    local future = KWR.FactStore:FromSnapshot(snapshot).facts[2]
    assert(future.observedAt == 300 and future.confidence == "UNKNOWN",
        "Future observation was silently re-stamped or confirmed")

    -- A scoreboard reorder or localized objective label is presentation only.
    -- It must not mint new evidence identities or alter Board consumers.
    local identitySnapshot = {
        context = { inPvP = true, capturedAt = 25, sessionKey = "identity-generation" },
        enemies = {
            { guid = "Enemy-A", name = "Alpha-LongRealm", observedAt = 25, visible = true },
            { guid = "Enemy-B", name = "Bravo-LongRealm", observedAt = 25, visible = true },
        },
        roster = {
            { guid = "Friendly-A", name = "Aster-HomeRealm", observedAt = 25 },
            { guid = "Friendly-B", name = "Beryl-HomeRealm", observedAt = 25 },
        },
        objectives = { rows = {
            { objectiveID = "ARATHI:FARM", label = "Farm", observedAt = 25, owner = "FRIENDLY" },
        } },
    }
    local firstFacts = KWR.FactStore:FromSnapshot(identitySnapshot)
    local firstBoard = KWR.BoardStateBuilder:Build(identitySnapshot, firstFacts)
    identitySnapshot.enemies[1], identitySnapshot.enemies[2] = identitySnapshot.enemies[2], identitySnapshot.enemies[1]
    identitySnapshot.roster[1], identitySnapshot.roster[2] = identitySnapshot.roster[2], identitySnapshot.roster[1]
    identitySnapshot.objectives.rows[1].label = "Farm (localized)"
    local secondFacts = KWR.FactStore:FromSnapshot(identitySnapshot)
    local secondBoard = KWR.BoardStateBuilder:Build(identitySnapshot, secondFacts)
    local function ids(rows, field)
        local result = {}
        for _, row in ipairs(rows) do result[#result + 1] = row[field] end
        table.sort(result)
        return table.concat(result, "|")
    end
    assert(ids(firstFacts.facts, "id") == ids(secondFacts.facts, "id")
        and ids(firstBoard.enemies, "evidenceID") == ids(secondBoard.enemies, "evidenceID")
        and ids(firstBoard.friendlies, "evidenceID") == ids(secondBoard.friendlies, "evidenceID")
        and firstBoard.objectives[1].id == secondBoard.objectives[1].id,
        "Scoreboard order or localized labels changed canonical fact identity")
    identitySnapshot.context.sessionKey = "identity-generation-rematch"
    local rematchFacts = KWR.FactStore:FromSnapshot(identitySnapshot)
    local rematchBoard = KWR.BoardStateBuilder:Build(identitySnapshot, rematchFacts)
    assert(ids(firstFacts.facts, "id") ~= ids(rematchFacts.facts, "id")
        and ids(firstBoard.enemies, "evidenceID") ~= ids(rematchBoard.enemies, "evidenceID")
        and ids(firstBoard.friendlies, "evidenceID") ~= ids(rematchBoard.friendlies, "evidenceID")
        and firstBoard.objectives[1].id == rematchBoard.objectives[1].id,
        "Same-map rematch reused an old fact generation or changed objective identity")

    local resolver = KWR.TeamResolver
    C_PvP = {}
    assert(resolver:BlitzIndicator(true) == nil, "Missing bracket APIs implied a known bracket")
    C_PvP.IsRatedSoloRBG = function() error("unavailable") end
    assert(resolver:BlitzIndicator(true) == nil, "Throwing bracket API did not remain unknown")
    local opaque = {}
    issecretvalue = function(value) return rawequal(value, opaque) end
    C_PvP.IsRatedSoloRBG = function() return opaque end
    assert(resolver:BlitzIndicator(true) == nil, "Protected bracket result implied confirmation")
    for _, provider in ipairs({ "IsRatedSoloRBG", "IsBrawlSoloRBG", "IsSoloRBG" }) do
        C_PvP = { [provider] = function() return true end }
        local value, source = resolver:BlitzIndicator(true)
        assert(value == true and source == "C_PvP." .. provider,
            "Explicit Solo RBG indicator did not identify its source")
    end
    C_PvP = { IsRatedSoloRBG = function() return false end,
        IsBrawlSoloRBG = function() return false end, IsSoloRBG = function() return false end }
    assert(resolver:BlitzIndicator(true) == false, "Public negative bracket evidence stayed unknown")

    -- Exercise the actual capture method in an isolated module instance. Other
    -- sensor adapters use the smoke APIs; only scoreboard and enemy storage are isolated.
    local rows = {}
    local testResolver = setmetatable({ Capture = function()
        return { side = "left", scoreFaction = 0, faction = "Horde", source = "fixture" }, rows
    end }, { __index = resolver })
    local namespace = setmetatable({ RegisterModule = function() end,
        TeamResolver = testResolver, EnemyIntel = { Capture = function() return {} end } }, { __index = KWR })
    assert(loadfile(ResolveAddonPath("Runtime/Sensors.lua")))("KnomercyWarRoom", namespace)
    EventRegistry = nil
    namespace.Sensors:OnInitialize()
    EventRegistry = savedRegistry
    IsInInstance = function() return true, "pvp" end
    local function scoreboard(size)
        rows = {}
        for faction = 0, 1 do
            for index = 1, size do
                rows[#rows + 1] = { faction = faction, guid = "Fixture-" .. faction .. "-" .. index,
                    name = "Fixture" .. faction .. index .. "-Realm" }
            end
        end
    end
    scoreboard(8)
    local partial = namespace.Sensors:Capture().context
    scoreboard(10)
    local full = namespace.Sensors:Capture().context
    assert(not partial.isBlitz and not full.isBlitz and partial.blitzKnown and full.blitzKnown
        and partial.blitzHint == "scoreboard_8v8",
        "Hydrating a standard roster latched Blitz rules")
    rows = {}
    C_PvP.IsRatedSoloRBG = function() return true end
    local rated = namespace.Sensors:Capture().context
    assert(rated.isBlitz and rated.isRated and rated.blitzKnown
        and rated.blitzSource == "C_PvP.IsRatedSoloRBG",
        "Rated Blitz capture depended on scoreboard size or lost rated provenance")
    C_PvP.IsRatedSoloRBG = function() return false end
    local corrected = namespace.Sensors:Capture().context
    assert(corrected.blitzKnown and not corrected.isBlitz,
        "Contradictory public evidence failed to clear Blitz state")
    C_PvP.IsBrawlSoloRBG = function() return true end
    assert(namespace.Sensors:Capture().context.isBlitz, "Solo RBG brawl capture was lost")
    IsInInstance = function() return false, "none" end
    assert(not namespace.Sensors:Capture().context.isBlitz, "World exit retained Blitz state")
    IsInInstance = function() return true, "pvp" end
    C_PvP = {}
    scoreboard(8)
    local unknown = namespace.Sensors:Capture().context
    assert(not unknown.isBlitz and not unknown.blitzKnown and unknown.blitzSource == "unconfirmed",
        "Unknown API state reused a previous Blitz classification")
    GetTime, C_PvP, IsInInstance, issecretvalue, EventRegistry = savedTime, savedPvp,
        savedInstance, savedSecret, savedRegistry
end
