return function(KWR, input)
    assert(type(KWR.AAR.FeedbackFocus) == "function", "P14 owner-bound feedback path is missing")
    local saved = { active = KWR.AAR.active, journal = KWR.db.journal, context = KWR.db.profile.fieldReviewContext,
        time = _G.time, getTime = _G.GetTime, get = KWR.Store.Get, checkpoint = KWR.AAR.lastCheckpointAt }
    local at = 1000
    _G.time = function() return at end
    _G.GetTime = function() return 100 end
    KWR.db.journal = { history = {} }
    KWR.db.profile.fieldReviewContext = "Commander"
    KWR.AAR.active = nil
    local state = KWR.Util:Copy(input)
    state.snapshot.capturedAt = 100
    state.snapshot.executionCommand.generatedAt = 100
    state.snapshot.score = { source = "none" }
    state.snapshot.objectives = { rows = {} }
    state.command.signature = "feedback-test"
    state.command.generatedAt = at
    state.command.status = "WAIT"
    KWR.Store.Get = function() return state end
    KWR.AAR:Record(state)
    local focus = KWR.AAR:FeedbackFocus(KWR.CommandView:CommanderCard(state))
    assert(focus and focus.matchId == KWR.AAR.active.id, "Feedback did not bind the owner match identity")
    local entry = KWR.AAR.active
    local command = entry.commands[#entry.commands]
    local callout = command.callouts[#command.callouts]
    assert(KWR.AAR:FollowthroughState(focus) == "UNMARKED", "An unclicked call was marked")
    assert(KWR.AAR:MarkFollowthrough(focus, "NOT_FOLLOWED", true), "Not-followed click was rejected")
    assert(KWR.CommandReview:HasNotFollowed(command), "Ignored call was eligible for execution effectiveness")
    assert(not state.command.delivery and not command.delivery and not command.executionObservation,
        "Follow-through manufactured delivery or observed execution")
    local count = #callout.events
    assert(not KWR.AAR:MarkFollowthrough(focus, "NOT_FOLLOWED", true) and #callout.events == count,
        "Repeated mark appended duplicate feedback")
    assert(KWR.AAR:MarkFollowthrough(focus, "FOLLOWED", true), "Correction to followed failed")
    assert(KWR.AAR:FollowthroughState(focus) == "FOLLOWED" and not KWR.CommandReview:OutcomeObserved(command),
        "Followed was treated as a verified success")
    assert(KWR.AAR:MarkFollowthrough(focus, "UNMARKED", false), "Undo failed")
    assert(#callout.events == 3 and callout.events[3].supersedesEventId == callout.events[2].eventId,
        "Undo destroyed correction evidence")
    for index = 1, 24 do
        assert(KWR.AAR:MarkFollowthrough(focus, index % 2 == 0 and "FOLLOWED" or "NOT_FOLLOWED", true))
    end
    assert(#callout.events == KWR.CommandReview.maxFollowthroughEvents and callout.eventSerial == 27,
        "Feedback producer bounds or stable event sequence failed")
    local undoEventId = callout.events[#callout.events].eventId
    assert(KWR.AAR:UndoFollowthrough(focus, undoEventId)
        and KWR.AAR:FollowthroughState(focus) == "NOT_FOLLOWED", "Undo did not restore the prior mark")
    assert(not KWR.AAR:UndoFollowthrough(focus, undoEventId), "An old Undo reversed a newer event")
    local wrong = KWR.Util:Copy(focus)
    wrong.candidateId = "wrong-package"
    assert(not KWR.AAR:MarkFollowthrough(wrong, "NOT_FOLLOWED", true), "Wrong candidate feedback was accepted")
    state.snapshot.executionCommand.localFight.controls[1].targetGUID = "Enemy-new"
    state.snapshot.executionCommand.localFight.controls[1].target = "NewHealer-NewRealm"
    KWR.AAR:Record(state)
    assert(not KWR.AAR:MarkFollowthrough(focus, "NOT_FOLLOWED", true), "A changed CC call received a stale click")
    assert(#command.callouts == 2, "AAR throttle dropped a tactical-only call revision")
    local current = KWR.AAR:FeedbackFocus(KWR.CommandView:CommanderCard(state))
    assert(current and current.calloutId ~= focus.calloutId, "Tactical-only change did not get an immutable reference")
    KWR.db.profile.fieldReviewContext = "Diagnostic"
    assert(not KWR.AAR:MarkFollowthrough(current, "FOLLOWED", true), "Diagnostic click qualified as Commander feedback")
    KWR.db.profile.fieldReviewContext = "Commander"
    assert(KWR.AAR:MarkFollowthrough(current, "FOLLOWED", true))
    local exported = KWR.AAR:Export(entry)
    assert(exported:find("manual adherence; not outcome", 1, true)
        and exported:find("NewHealer", 1, true)
        and not exported:find("NewRealm", 1, true),
        "AAR export lost adherence or retained a realm-qualified spoken name")
    KWR.AAR:PersistActive(true)
    assert(KWR.db.journal.interrupted.commands[#entry.commands].callouts[2].events[1].state == "FOLLOWED",
        "Checkpoint lost feedback")
    local retainedCallout = command.callouts[2]
    retainedCallout.events[#retainedCallout.events + 1] = { schemaVersion = 1, state = "FOLLOWED" }
    assert(KWR.CommandReview:NormalizeCallouts(command)
        and #retainedCallout.events == 1,
        "Malformed persisted follow-through event was not rejected at the owner boundary")
    local reloaded = KWR.Util:Copy(entry)
    local reloadedCommand = reloaded.commands[#reloaded.commands]
    reloadedCommand.callouts[1].events = "corrupt persisted events"
    reloadedCommand.callouts[2].schemaVersion = 2
    KWR.AAR:CompactEntry(reloaded)
    assert(#reloadedCommand.callouts == 1
        and type(reloadedCommand.callouts[1].events) == "table",
        "AAR load compaction retained corrupt or future-schema callout data")
    local futureCallout = KWR.Util:Copy(reloadedCommand.callouts[1])
    futureCallout.schemaVersion = 2
    assert(not KWR.CommandReview:AppendFollowthrough(futureCallout, "FOLLOWED"),
        "A future persisted callout schema accepted a new feedback event")
    local lastEvent = command.callouts[2].events[1]
    local future = KWR.Util:Copy(lastEvent)
    future.recordedAt = at + 1
    assert(not KWR.CommandReview:FollowthroughEligible(command.callouts[2], future), "Future feedback qualified")
    KWR.AAR:Start(state)
    assert(KWR.AAR.active.id ~= entry.id, "Same-second rematch reused a match identity")
    assert(not KWR.AAR:MarkFollowthrough(current, "NOT_FOLLOWED", true), "Rematch accepted the old call")
    _G.time, _G.GetTime, KWR.Store.Get = saved.time, saved.getTime, saved.get
    KWR.AAR.active, KWR.db.journal = saved.active, saved.journal
    KWR.AAR.lastCheckpointAt = saved.checkpoint
    KWR.db.profile.fieldReviewContext = saved.context
    print("KWR_COMMAND_FOLLOWTHROUGH_PASS")
end
