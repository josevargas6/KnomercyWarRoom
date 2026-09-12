return function(KWR)
    local learning = KWR.Learning
    local saved = KWR.db.learning
    local savedEpoch = time
    local savedBuckets, savedEpisodes = learning.maxBuckets, learning.maxProcessedEpisodes
    time = function() return 100 end
    local old = { plans = { legacy = { wins = 99, samples = 100 }, malformed = false } }
    KWR.db.learning = old
    learning:OnInitialize()
    local migrated = KWR.db.learning
    assert(migrated.schemaVersion == 2 and migrated.legacy.data == old
        and old.plans.legacy.wins == 99 and old.plans.malformed == false,
        "Migration erased or relabeled historical learning")
    learning:OnInitialize()
    assert(KWR.db.learning == migrated and learning:Summary().samples == 0,
        "Migration repeated or allowed unproven aggregates into live learning")
    local future = { schemaVersion = 3, plans = "future format" }
    KWR.db.learning = future
    learning:OnInitialize()
    assert(KWR.db.learning == future and future.plans == "future format"
        and learning:Adjustment("ARATHI", "PLAN") == 0,
        "Future learning schema was changed or scored")
    KWR.db.learning = migrated
    local snapshot = { context = { inPvP = true, isRated = true, isBlitz = true, mapKey = "ARATHI" }, roster = {} }
    for index = 1, 8 do snapshot.roster[index] = { guid = "Player-" .. index } end
    local scope = learning:Context(snapshot)
    assert(scope and scope.bracket == "RBG_8", "Rated eight-player scope missing")
    local key = learning:ContextKey(scope, "PLAN")
    snapshot.roster[1], snapshot.roster[8] = snapshot.roster[8], snapshot.roster[1]
    assert(learning:ContextKey(learning:Context(snapshot), "PLAN") == key,
        "Roster enumeration order changed learning identity")
    snapshot.roster[1].guid = snapshot.roster[2].guid
    assert(learning:Context(snapshot) == nil, "Duplicate identities qualified a team")
    snapshot.roster[1].guid = "Player-8"
    snapshot.context.isBlitz = false
    assert(learning:Context(snapshot) == nil, "Incomplete ten-player roster qualified")
    snapshot.roster[9], snapshot.roster[10] = { guid = "Player-9" }, { guid = "Player-10" }
    assert(learning:Context(snapshot).bracket == "RBG_10", "Ten-player scope missing")
    local command = {
        commandId = "call-1", commandRevision = 1, sessionKey = "ARATHI:test-session", planID = "PLAN", learningContext = scope,
        delivery = { schemaVersion = 1, clock = "UNIX_SECONDS", commandId = "call-1",
            commandRevision = 1, generatedAt = 90, deliveredAt = 95, context = "Commander",
            state = "LEADER_ATTESTED", source = "EXPLICIT_LEADER_CONFIRMATION" },
        executionObservation = { schemaVersion = 1, clock = "UNIX_SECONDS", commandId = "call-1",
            commandRevision = 1, observedAt = 98, source = "PUBLIC_FACTS",
            evidenceIds = { "farm:capture:98" }, outcome = "SUCCESS", sessionKey = "ARATHI:test-session" },
    }
    local entry = { id = "match-1", mapKey = "ARATHI", endedAt = 99,
        truthQualified = true, reviewContext = "Commander", result = "DEFEAT",
        feedback = { sessionType = "Commander" }, commands = { command, { action = "Unissued" } } }
    assert(learning:RecordReviewed(entry) and learning:Summary().samples == 1,
        "Observed successful episode in a lost match did not train independently")
    local replayed = KWR.Util:Copy(entry)
    replayed.learned = nil
    learning:OnInitialize()
    assert(not learning:RecordReviewed(replayed) and learning:Summary().samples == 1,
        "Reconstructed AAR trained twice after reload")
    for index = 2, 5 do
        local nextEntry = KWR.Util:Copy(entry)
        nextEntry.id = "match-" .. index
        assert(learning:RecordReviewed(nextEntry), "New eligible episode was rejected")
    end
    local adjustment = learning:Adjustment("ARATHI", "PLAN", scope)
    assert(adjustment > 0 and adjustment <= 3, "Minimum sample or bounded adjustment failed")
    local valid = KWR.Util:Copy(migrated.plans[key])
    migrated.plans.bad = false
    migrated.plans[key].updatedAt = "99"
    learning:Prune()
    assert(migrated.plans.bad == nil and migrated.plans[key] == nil
        and #migrated.quarantinedPlans == 2,
        "Malformed current buckets were neither isolated nor preserved")
    learning:Prune()
    assert(#migrated.quarantinedPlans == 2, "Malformed bucket quarantine duplicated on reload")
    migrated.plans[key] = valid
    for _, field in ipairs({ "teamKey", "bracket", "patch", "planRevision", "mapKey" }) do
        local other = KWR.Util:Copy(scope)
        other[field] = field == "bracket" and "RBG_10" or (other[field] .. "-other")
        assert(learning:Adjustment("ARATHI", "PLAN", other) == 0,
            "Incompatible " .. field .. " pooled episode learning")
    end
    assert(learning:Adjustment("ARATHI", "OTHER_PLAN", scope) == 0,
        "Different doctrine plan pooled learning")
    for _, change in ipairs({ "partial", "Diagnostic", "Spectator", "unknown-outcome", "no-delivery" }) do
        local rejected = KWR.Util:Copy(entry)
        rejected.id = "reject-" .. change
        if change == "partial" then rejected.partial = true
        elseif change == "unknown-outcome" then rejected.commands[1].executionObservation.outcome = nil
        elseif change == "no-delivery" then rejected.commands[1].delivery = nil
        else rejected.reviewContext = change end
        assert(not learning:RecordReviewed(rejected), "Ineligible " .. change .. " episode trained")
    end
    learning.maxBuckets, learning.maxProcessedEpisodes = 2, 2
    learning:Prune()
    assert(migrated.retiredThrough == 99, "Pruned ledger lacks a replay rejection watermark")
    local evicted = KWR.Util:Copy(entry)
    evicted.learned = nil
    assert(not learning:RecordReviewed(evicted), "Evicted episode replay retrained")
    for index = 1, 3 do
        local nextEntry = KWR.Util:Copy(entry)
        nextEntry.id, nextEntry.endedAt = "new-" .. index, 100
        nextEntry.commands[1].planID = "PLAN_" .. index
        assert(learning:RecordReviewed(nextEntry), "Newer episode rejected by old watermark")
    end
    local plans, episodes = 0, 0
    for _ in pairs(migrated.plans) do plans = plans + 1 end
    for _ in pairs(migrated.processedEpisodes) do episodes = episodes + 1 end
    assert(plans <= 2 and episodes <= 2, "Learning write bounds were exceeded")
    learning:Reset()
    assert(learning:Summary().samples == 0 and not learning:RecordReviewed(evicted),
        "Reset re-enabled historical replay training")
    migrated.processedEpisodes.corrupt = "bad"
    learning:OnInitialize()
    assert(migrated.processedEpisodes.corrupt == "bad" and learning:Summary().unavailable
        and not learning:RecordReviewed(entry), "Corrupt ledger was erased or allowed training")
    KWR.db.learning = saved
    time = savedEpoch
    learning.maxBuckets, learning.maxProcessedEpisodes = savedBuckets, savedEpisodes
end
