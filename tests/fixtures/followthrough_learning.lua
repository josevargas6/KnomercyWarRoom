return function(KWR)
    local saved = { db = KWR.db.learning, time = _G.time, limit = KWR.Learning.maxProcessedEpisodes,
        disabled = KWR.Learning.disabled }
    local at = 102
    _G.time = function() return at end
    KWR.db.learning = { schemaVersion = 2, plans = {}, processedEpisodes = {}, retiredThrough = 0 }
    KWR.Learning.disabled = false
    local context = { schemaVersion = 1, teamKey = "test-team", bracket = "RBG_10", mapKey = "ARATHI",
        patch = KWR.PatchData.activePatch, planRevision = KWR.version }
    local command = { commandId = "call", commandRevision = 1, sessionKey = "ARATHI:test-session", planID = "HOLD", learningContext = context,
        delivery = { schemaVersion = 1, clock = "UNIX_SECONDS", commandId = "call", commandRevision = 1,
            generatedAt = 90, deliveredAt = 91, state = "LEADER_ATTESTED", source = "EXPLICIT_LEADER_CONFIRMATION", context = "Commander" },
        executionObservation = { schemaVersion = 1, clock = "UNIX_SECONDS", commandId = "call", commandRevision = 1,
            observedAt = 98, outcome = "SUCCESS", source = "PUBLIC_FACTS", sessionKey = "ARATHI:test-session", evidenceIds = { "public-objective" } },
        callouts = { { schemaVersion = 1, clock = "UNIX_SECONDS", candidateId = KWR.BuildInfo.candidateID,
            matchId = "feedback-match", commandId = "call", commandRevision = 1, calloutId = "callout",
            calloutRevision = 1, sessionKey = "test-session", context = "Commander", generatedAt = 90,
            speech = "Hold Farm", eventSerial = 0, events = {} } } }
    local entry = { id = "feedback-match", mapKey = "ARATHI", endedAt = 99, truthQualified = true,
        result = "DEFEAT", reviewContext = "Commander", feedback = { sessionType = "Commander" }, commands = { command } }
    assert(KWR.Learning:RecordReviewed(entry) and KWR.Learning:Summary().samples == 1,
        "Unmarked independently observed episode lost existing eligibility")
    assert(KWR.CommandReview:AppendFollowthrough(command.callouts[1], "NOT_FOLLOWED"))
    assert(KWR.Learning:Summary().samples == 1, "Click mutated finalized learning outside qualified intake")
    assert(KWR.Learning:RecordReviewed(entry) and KWR.Learning:Summary().samples == 0,
        "Post-intake not-followed correction left stale execution credit")
    assert(KWR.CommandReview:AppendFollowthrough(command.callouts[1], "UNMARKED"))
    assert(KWR.Learning:RecordReviewed(entry) and KWR.Learning:Summary().samples == 1,
        "Undo did not restore exactly one qualified contribution")
    assert(not KWR.Learning:RecordReviewed(KWR.Util:Copy(entry)) and KWR.Learning:Summary().samples == 1,
        "Reconstructed correction double counted an episode")
    assert(KWR.CommandReview:AppendFollowthrough(command.callouts[1], "FOLLOWED"))
    assert(not KWR.Learning:RecordReviewed(entry) and KWR.Learning:Summary().samples == 1,
        "Followed manufactured another sample")
    KWR.Learning.maxProcessedEpisodes = 1
    local nextEntry = KWR.Util:Copy(entry)
    nextEntry.id, nextEntry.endedAt = "next-match", 100
    nextEntry.commands[1].callouts = nil
    assert(KWR.Learning:RecordReviewed(nextEntry) and KWR.Learning:Summary().samples == 1,
        "Evicted correction identity left unreviewable aggregate credit")
    assert(not KWR.Learning:RecordReviewed(entry), "Ledger eviction permitted replayed feedback to train twice")
    _G.time, KWR.db.learning, KWR.Learning.maxProcessedEpisodes, KWR.Learning.disabled =
        saved.time, saved.db, saved.limit, saved.disabled
    print("KWR_FOLLOWTHROUGH_LEARNING_PASS")
end
