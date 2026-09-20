return function(KWR)
    local ns = setmetatable({ RegisterModule = function() end }, { __index = KWR })
    local function load(path)
        assert(loadfile(ResolveAddonPath(path)))("KnomercyWarRoom", ns)
    end
    load("Core/Store.lua")
    ns.Store.QueueNotifications = function() end
    local input = { context = { inPvP = true },
        stable = { nested = { value = 1 } }, changing = { value = 1, removed = true },
        rows = { { name = "one" }, { name = "two" } } }
    local first = ns.Store:Publish(input, {}, {}, {}, {})
    local incoming = KWR.Util:Copy(input)
    incoming.changing.value, incoming.changing.removed = 2, nil
    incoming.rows[2] = nil
    incoming.added = { nested = { value = 3 } }
    local second = ns.Store:Publish(incoming, {}, {}, {}, {})
    assert(second.snapshot.stable == first.snapshot.stable
        and second.snapshot.changing ~= first.snapshot.changing
        and first.snapshot.changing.value == 1 and first.snapshot.changing.removed
        and second.snapshot.changing.value == 2 and second.snapshot.changing.removed == nil
        and #second.snapshot.rows == 1 and #first.snapshot.rows == 2,
        "Publication lost structural sharing, removals or prior-state isolation")
    incoming.added.nested.value = 99
    incoming.stable.nested.value = 99
    assert(second.snapshot.added.nested.value == 3 and second.snapshot.stable.nested.value == 1,
        "Publication retained a producer-owned mutable branch")
    local copy = KWR.Util.Copy
    local copied = 0
    local identical = copy(KWR.Util, second.snapshot)
    KWR.Util.Copy = function(self, value)
        if type(value) == "table" then copied = copied + 1 end
        return copy(self, value)
    end
    local third = ns.Store:Publish(identical, {}, {}, {}, {})
    KWR.Util.Copy = copy
    assert(copied == 0 and third.snapshot == second.snapshot,
        "Equal publication still deep-copied the snapshot")
    local finalized, notified = false, false
    ns.Store.QueueNotifications = function(_, _, state)
        assert(finalized and state.diagnostics.measuredAfterProjection == true,
            "Store notified before runtime diagnostics were finalized")
        notified = true
    end
    ns.Store:Publish(identical, {}, {}, {}, {}, function()
        finalized = true
        return { measuredAfterProjection = true }
    end)
    assert(notified, "Finalized diagnostics suppressed publication")

    local patch = {}
    ns.PatchData = { Get = function() return patch end,
        Capability = function() return patch.overlay end }
    load("Data/Capabilities.lua")
    local roster = { { classFile = "MAGE", spec = "Frost", role = "DAMAGER" } }
    local resolves, resolve = 0, ns.Capabilities.Resolve
    ns.Capabilities.Resolve = function(self, ...)
        resolves = resolves + 1
        return resolve(self, ...)
    end
    local summary = ns.Capabilities:Summarize(roster)
    summary.ratings.mobility = -100
    for _ = 1, 100 do
        assert(ns.Capabilities:Summarize(roster).ratings.mobility ~= -100)
    end
    assert(resolves == 1, "Identical summaries rebuilt static capability aggregation")
    roster[1].specSource = "historical"
    assert(ns.Capabilities:Summarize(roster).likelySpecs == 1 and resolves == 2,
        "Summary cache hid historical provenance changes")
    patch = { overlay = { role = "HEALER" } }
    assert(ns.Capabilities:Summarize(roster).healers == 1 and resolves == 3,
        "Summary cache hid a changed reviewed patch pack")
    for index = 1, 5 do
        ns.Capabilities:Summarize({ { classFile = "UNKNOWN", spec = "unknown" .. index } })
    end
    local before = resolves
    ns.Capabilities:Summarize(roster)
    assert(resolves == before + 1, "Summary cache retained more than four compositions")

    ns.Capabilities = KWR.Capabilities
    -- Independent reference ranking: ensure compiling static spec counts and
    -- projecting only the winner preserve all map-specific tie breakers.
    local function counts(rows, tokens)
        local result = {}
        for _, row in ipairs(rows) do
            local key = tokens and row:lower() or (row.classFile .. ":" .. row.spec):lower()
            result[key] = (result[key] or 0) + 1
        end
        return result
    end
    for _, comp in ipairs(KWR.Compositions:TierAll()) do
        local team = {}
        for index, token in ipairs(comp.specs) do
            local class, spec = token:match("^([^:]+):(.+)$")
            team[index] = { classFile = class, spec = spec }
        end
        for _, map in ipairs({ "ARATHI", "SILVERSHARD", "WSG", "WORLD" }) do
            local actual, expected = counts(team)
            for _, candidate in ipairs(KWR.Compositions:TierAll()) do
                local matched, fits = 0, map == "WORLD"
                for _, candidateMap in ipairs(candidate.maps) do
                    if map == candidateMap then fits = true end
                end
                for key, count in pairs(counts(candidate.specs, true)) do
                    matched = matched + math.min(actual[key] or 0, count)
                end
                if not expected or matched > expected.matched
                    or (matched == expected.matched and fits and not expected.mapFit)
                    or (matched == expected.matched and fits == expected.mapFit and candidate.id < expected.id) then
                    expected = { id = candidate.id, matched = matched, mapFit = fits }
                end
            end
            local matched = KWR.Compositions:MatchTier(team, map)
            assert(matched.id == expected.id and matched.matched == expected.matched
                and matched.mapFit == expected.mapFit, "Composition optimization changed reviewed ranking")
        end
    end
    load("Runtime/Reporter.lua")
    ns.Reporter.tracks = { friendly = {
        a = { x = 0.1, y = 0.1, classFile = "MAGE", spec = "Frost", age = 0,
            positionSource = "OBSERVED" },
    }, enemy = {} }
    local capResolve = KWR.Capabilities.Resolve
    local movementResolves = 0
    KWR.Capabilities.Resolve = function(self, ...)
        movementResolves = movementResolves + 1
        return capResolve(self, ...)
    end
    local etas = ns.Reporter:ObjectiveETAs({ context = { preview = true, mapKey = "ARATHI" },
        objectives = { rows = {
            { label = "Blacksmith", x = 0.5, y = 0.5 },
            { label = "Farm", x = 0.8, y = 0.8 },
            { label = "Lumber Mill", x = 0.3, y = 0.3 },
        } } })
    KWR.Capabilities.Resolve = capResolve
    assert(#etas == 3 and movementResolves == 1,
        "Reporter repeated actor movement resolution for every objective")

    load("Intelligence/AssignmentOptimizer.lua")
    local friendlyBuilds = 0
    ns.FriendlyRoleState = { Build = function(_, player)
        friendlyBuilds = friendlyBuilds + 1
        return { available = false, player = player }
    end }
    ns.AssignmentOptimizer:Optimize({ friendlies = { {}, {}, {} } }, {
        { type = "FREE_CASTING_HEALER", enemy = {} },
        { type = "LOCAL_HEALER_CONTROL", enemy = {} },
    }, {})
    assert(friendlyBuilds == 3, "Optimizer repeated actor profiles per problem")

    load("Runtime/EncounterHistory.lua")
    ns.db = { encounters = { players = {}, quarantine = {} } }
    ns.EncounterHistory.maxPlayers = 2
    local prune, prunes = ns.EncounterHistory.Prune, 0
    ns.EncounterHistory.Prune = function(self, ...)
        prunes = prunes + 1
        return prune(self, ...)
    end
    local savedTime = time
    local now = 1000
    time = function() return now end
    local historySnapshot = { context = { mapKey = "ARATHI", inPvP = true },
        roster = { { guid = "one", name = "one", spec = "Frost", classFile = "MAGE" } } }
    ns.EncounterHistory:Enrich(historySnapshot)
    for _ = 1, 100 do ns.EncounterHistory:Enrich(historySnapshot) end
    assert(prunes == 1, "Unchanged history sorted on every refresh")
    for index = 2, 3 do
        historySnapshot.roster[#historySnapshot.roster + 1] = {
            guid = tostring(index), name = tostring(index), spec = "Frost", classFile = "MAGE" }
    end
    ns.EncounterHistory:Enrich(historySnapshot)
    assert(prunes == 2 and ns.EncounterHistory:Count() == 2, "New identities failed immediate capacity enforcement")
    historySnapshot.roster = {}
    now = now + 5
    ns.EncounterHistory:Enrich(historySnapshot)
    assert(prunes == 3, "History aging never pruned")
    time = savedTime
    print("KWR_RUNTIME_PROJECTION_COST_PASS unchangedPublicationCopies=0 summaryResolves=1 movementResolves=1 actorProfiles=3")
end
