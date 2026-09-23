return function(KWR)
    local savedMetrics = KWR.Commander.metrics
    local savedContext = KWR.db.profile.fieldReviewContext
    local savedLearning = KWR.Util:Copy(KWR.db.learning)
    local savedLearningDisabled = KWR.Learning.disabled
    KWR.db.learning = { schemaVersion = 2, plans = {}, processedEpisodes = {}, retiredThrough = 0 }
    KWR.Learning.disabled = false
    local savedTime, savedEpoch = GetTime, time
    GetTime = function() return 100 end
    time = function() return 100 end
    local review = KWR.CommandReview
    local savedCommand = KWR.Commander.lastCommand
    local savedActive = KWR.AAR.active
    local savedCheckpointAt = KWR.AAR.lastCheckpointAt
    local savedInterrupted = KWR.Util:Copy(KWR.db.journal.interrupted)
    local first = { signature = "hold", action = "Hold Farm", mapKey = "ARATHI", inPvP = true,
        sessionKey = "ARATHI:field-a" }
    KWR.Commander:AttachReviewIdentity(first)
    local state = { command = first, assignments = {}, prediction = {}, snapshot = {
        context = { inPvP = true, mapKey = "ARATHI", sessionKey = "ARATHI:field-a", phase = "ACTIVE", team = { side = 1 } },
        score = { friendly = 400, enemy = 300, source = "ui_widget" },
        objectives = { rows = {}, events = {} }, roster = {}, enemies = {},
        reporter = {}, combat = {},
    } }
    KWR.Commander.lastCommand = KWR.Util:Copy(first)
    for _, context in ipairs({ "Diagnostic", "Spectator" }) do
        KWR.db.profile.fieldReviewContext = context
        assert(not KWR.Commander:AttestDelivery(state, first.commandId, first.commandRevision),
            "Non-commander confirmation accepted")
    end
    KWR.db.profile.fieldReviewContext = "Commander"
    state.snapshot.context.preview = true
    assert(not KWR.Commander:AttestDelivery(state, first.commandId, first.commandRevision),
        "Preview delivery accepted")
    state.snapshot.context.preview = nil
    KWR.AAR.active = nil
    KWR.AAR:Record(state)
    assert(KWR.Commander:AttestDelivery(state, first.commandId, first.commandRevision),
        "Explicit current call confirmation rejected")
    assert(first.delivery == nil, "Confirmation mutated a published snapshot")
    assert(not KWR.Commander:AttestDelivery(state, first.commandId, first.commandRevision),
        "Duplicate delivery accepted")
    state.snapshot.context.sessionKey = "ARATHI:field-b"
    assert(not KWR.Commander:AttestDelivery(state, first.commandId, first.commandRevision),
        "Prior battlefield session accepted delivery attestation")
    state.snapshot.context.sessionKey = "ARATHI:field-a"
    local retained = { signature = "hold", mapKey = "ARATHI", action = "Hold Farm", sessionKey = "ARATHI:field-a" }
    KWR.Commander:AttachReviewIdentity(retained, KWR.Commander.lastCommand)
    assert(retained.commandId == first.commandId and review:DeliveryEligible(retained),
        "Stable call lost its confirmation")
    state.command = retained
    KWR.AAR:Record(state)
    assert(#KWR.AAR.active.commands == 1 and review:DeliveryEligible(KWR.AAR.active.commands[1]),
        "AAR throttled confirmation or duplicated the call")
    assert(not review:ExecutionEligible(KWR.AAR.active.commands[1]),
        "Capture manufactured team execution")
    local crossSession = { signature = "hold", mapKey = "ARATHI", action = "Hold Farm",
        sessionKey = "ARATHI:field-b" }
    KWR.Commander:AttachReviewIdentity(crossSession, KWR.Commander.lastCommand)
    assert(crossSession.commandId ~= first.commandId and crossSession.delivery == nil,
        "A command carried delivery identity across battlefield sessions")
    local export = KWR.AAR:Export(KWR.AAR.active)
    assert(export:find("LEADER_ATTESTED (explicit local confirmation)", 1, true)
        and export:find("Execution: UNVERIFIED", 1, true),
        "Export hid the distinction between confirmation and execution")
    local initialCheckpoint = KWR.db.journal.interrupted
    KWR.AAR:PersistActive()
    assert(KWR.db.journal.interrupted == initialCheckpoint,
        "Unchanged checkpoint was copied within its budget")
    GetTime = function() return 130 end
    KWR.AAR:PersistActive()
    assert(KWR.db.journal.interrupted ~= initialCheckpoint
        and review:DeliveryEligible(KWR.db.journal.interrupted.commands[1]),
        "Periodic checkpoint missed the confirmed call")
    local periodicCheckpoint = KWR.db.journal.interrupted
    KWR.AAR:PersistActive(true)
    assert(KWR.db.journal.interrupted ~= periodicCheckpoint,
        "Forced checkpoint was throttled")
    GetTime = function() return 100 end
    local replacement = { signature = "rotate", mapKey = "ARATHI", inPvP = true, sessionKey = "ARATHI:field-a" }
    KWR.Commander:AttachReviewIdentity(replacement, KWR.Commander.lastCommand)
    assert(replacement.commandId ~= first.commandId and replacement.delivery == nil,
        "Replacement inherited previous call delivery")
    KWR.Commander.lastCommand = replacement
    assert(not KWR.Commander:AttestDelivery(state, first.commandId, first.commandRevision),
        "Stale displayed call was confirmed after replacement")
    KWR.Commander.lastCommand = savedCommand
    KWR.AAR.active = savedActive
    KWR.AAR.lastCheckpointAt = savedCheckpointAt
    KWR.db.journal.interrupted = savedInterrupted
    local command = { commandId = "session:call", commandRevision = 1, sessionKey = "ARATHI:field-a",
        action = "Hold Farm", decisionScore = 90, confidenceScore = 90 }
    for _, context in ipairs({ "Diagnostic", "Spectator", "Commander" }) do
        KWR.db.profile.fieldReviewContext = context
        assert(not review:DeliveryEligible(command), "Mode setting manufactured delivery")
        KWR.Commander.metrics = { issued = 8, replacements = 0 }
        local metrics = KWR.Commander:GetStabilityMetrics()
        assert(metrics.generatorCertificationStatus == "READY"
            and metrics.certificationStatus == "DELIVERY_UNVERIFIED"
            and metrics.commandHealth == "NOT_SCORED",
            "Generated calls received a delivery certification")
    end
    command.delivery = { commandId = command.commandId, commandRevision = 1,
        generatedAt = 90, deliveredAt = 95, context = "Commander",
        state = "LEADER_ATTESTED", source = "EXPLICIT_LEADER_CONFIRMATION",
        schemaVersion = 1, clock = "UNIX_SECONDS" }
    assert(review:DeliveryEligible(command), "Valid explicit attestation was lost")
    local changed = KWR.Util:Copy(command)
    changed.commandRevision = 2
    assert(not review:DeliveryEligible(changed), "Old attestation survived a command revision")
    for _, source in ipairs({ "CLIPBOARD", "MODE_SETTING", "GENERATED" }) do
        changed = KWR.Util:Copy(command)
        changed.delivery.source = source
        assert(not review:DeliveryEligible(changed), "Non-delivery action qualified")
    end
    for _, at in ipairs({ -1, 101, math.huge, 0 / 0, 89 }) do
        changed = KWR.Util:Copy(command)
        changed.delivery.deliveredAt = at
        assert(not review:DeliveryEligible(changed), "Invalid delivery time qualified")
    end
    assert(not review:ExecutionEligible(command), "Delivery alone proved execution")
    command.executionObservation = { commandId = command.commandId, commandRevision = 1,
        source = "PUBLIC_FACTS", observedAt = 98, evidenceIds = { "objective:farm:98" },
        outcome = "SUCCESS", sessionKey = "ARATHI:field-a", schemaVersion = 1, clock = "UNIX_SECONDS" }
    assert(review:ExecutionEligible(command), "Bound public execution evidence was lost")
    changed = KWR.Util:Copy(command)
    changed.executionObservation.sessionKey = "ARATHI:other-session"
    assert(not review:ExecutionEligible(changed), "Other session's observation qualified")
    changed = KWR.Util:Copy(command)
    changed.executionObservation.commandId = "other"
    assert(not review:ExecutionEligible(changed), "Other command's observation qualified")
    local generated = { action = "Hold Farm", decisionScore = 90 }
    local legacy = { commands = { generated }, result = "VICTORY",
        decisionReviews = { { decisionQuality = "STRONG", outcomeAligned = true } },
        commandStability = { issued = 8, certificationStatus = "READY" } }
    KWR.AAR:CompactEntry(legacy)
    assert(legacy.legacyReview.decisionReviews[1].outcomeAligned == true
        and legacy.decisionReviews[1].outcomeAligned == nil
        and legacy.commandStability.certificationStatus == "DELIVERY_UNVERIFIED",
        "Legacy AAR either erased history or retained false credit")
    local originalReview = legacy.legacyReview
    KWR.AAR:CompactEntry(legacy)
    assert(legacy.legacyReview == originalReview, "AAR migration repeated")
    local future = { provenanceVersion = 2, commands = "future shape" }
    assert(KWR.AAR:CompactEntry(future) == future and future.commands == "future shape",
        "AAR migration rewrote future schema")
    assert(KWR.AAR:BuildDecisionReviews({ false, { decisionScore = "bad" } }, "VICTORY")[2]
        .decisionQuality == "NOT_SCORED", "Malformed legacy score crashed review")
    local aar = KWR.AAR:BuildDecisionReviews({ generated }, "VICTORY")[1]
    assert(aar.decisionQuality == "NOT_SCORED" and aar.executionQuality == "NOT_ISSUED"
        and aar.outcomeAligned == nil, "Match victory credited an unissued recommendation")
    changed = KWR.Util:Copy(command)
    changed.executionObservation = nil
    aar = KWR.AAR:BuildDecisionReviews({ changed }, "VICTORY")[1]
    assert(aar.executionQuality == "NOT_OBSERVED" and aar.outcomeAligned == nil,
        "Attestation alone credited execution")
    KWR.db.learning.plans = {}
    local entry = { id = "test-match", primaryPlanID = "TEST_PLAN", mapKey = "ARATHI",
        truthQualified = true, result = "VICTORY", feedback = { sessionType = "Commander" },
        commands = { generated }, endedAt = 99 }
    assert(not KWR.Learning:RecordReviewed(entry)
        and KWR.Learning:Summary().samples == 0, "Unissued call entered learning")
    entry.commands = { command }
    entry.partial = true
    assert(not KWR.Learning:RecordReviewed(entry), "Interrupted match entered learning")
    KWR.Commander.metrics = savedMetrics
    KWR.db.profile.fieldReviewContext = savedContext
    KWR.db.learning = savedLearning
    KWR.Learning.disabled = savedLearningDisabled
    GetTime = savedTime
    time = savedEpoch
end
