local _, KWR = ...

-- AAR owns the retained call snapshots and manual corrections. Rendering only
-- reads this boundary; neither a click nor a repaint delivers a gameplay call.
local AAR = KWR.AAR

local function focusFor(callout)
    local focus = {}
    for _, key in ipairs({ "candidateId", "matchId", "sessionKey", "commandId", "commandRevision",
        "calloutId", "calloutRevision", "identity", "speech" }) do
        focus[key] = callout[key]
    end
    return focus
end

local function sameView(callout, view)
    return callout.candidateId == view.candidateId and callout.sessionKey == view.sessionKey
        and callout.commandId == view.commandId and callout.commandRevision == view.commandRevision
        and callout.identity == view.callIdentity and callout.speech == view.speech
end

function AAR:CaptureCallout(state)
    local entry = self.active
    local command = entry and entry.commands[#entry.commands]
    if not command or not state.command or command.commandId ~= state.command.commandId
        or command.commandRevision ~= state.command.commandRevision then return end
    local view = KWR.CommandView:CommanderCard(state)
    if not view.eligible then return end
    local at = KWR.Util:Number(KWR.Util:Call(time), nil)
    if not at or at < 0 or at ~= at or at == math.huge then return end
    if command.calloutSchemaVersion and command.calloutSchemaVersion ~= 1 then return end
    command.calloutSchemaVersion = 1
    command.callouts = command.callouts or {}
    if KWR.CommandReview:NormalizeCallouts(command) == false then return end
    local last = command.callouts[#command.callouts]
    if last and sameView(last, view) then return end
    entry.calloutSerial = (entry.calloutSerial or 0) + 1
    local revision = entry.calloutSerial
    local callout = { schemaVersion = 1, clock = "UNIX_SECONDS",
        candidateId = view.candidateId, matchId = entry.id, sessionKey = view.sessionKey,
        commandId = view.commandId, commandRevision = view.commandRevision,
        calloutId = entry.id .. ":call:" .. tostring(revision), calloutRevision = revision,
        generatedAt = at, identity = view.callIdentity, speech = view.speech,
        context = KWR.Util:Text(KWR.db.profile.fieldReviewContext, "Diagnostic", 24),
        eventSerial = 0, events = {} }
    command.callouts[#command.callouts + 1] = callout
    while #command.callouts > KWR.CommandReview.maxCallouts do
        local evicted = table.remove(command.callouts, 1)
        if KWR.CommandReview:EffectiveFollowthrough(evicted) == "NOT_FOLLOWED" then
            -- Cannot later prove that an evicted correction was undone. Keep a
            -- conservative exclusion, not a falsely unmarked execution episode.
            command.evictedNotFollowed = true
        end
        command.evictedCallouts = (command.evictedCallouts or 0) + 1
    end
end

function AAR:FeedbackFocus(view)
    if not view or not view.eligible or not self.active then return nil end
    local commands = self.active.commands
    local command = commands and commands[#commands]
    local callouts = command and command.callouts
    local last = callouts and callouts[#callouts]
    if last and last.context == "Commander" and sameView(last, view) then return focusFor(last) end
end

function AAR:FindFeedbackCall(focus)
    if type(focus) ~= "table" then return nil end
    local entry = self:GetByID(focus.matchId)
    if not entry or entry.candidateID ~= focus.candidateId then return nil end
    for _, command in ipairs(entry.commands or {}) do
        if command.commandId == focus.commandId and command.commandRevision == focus.commandRevision then
            for _, callout in ipairs(command.callouts or {}) do
                if callout.calloutId == focus.calloutId and callout.calloutRevision == focus.calloutRevision
                    and callout.candidateId == focus.candidateId and callout.sessionKey == focus.sessionKey
                    and callout.identity == focus.identity and callout.speech == focus.speech then
                    return callout, command, entry
                end
            end
        end
    end
end

function AAR:FollowthroughState(focus)
    local callout = self:FindFeedbackCall(focus)
    return callout and KWR.CommandReview:EffectiveFollowthrough(callout) or "UNMARKED"
end

function AAR:MarkFollowthrough(focus, mark, currentOnly)
    local callout, command, entry = self:FindFeedbackCall(focus)
    if not callout or focus.candidateId ~= KWR.BuildInfo.candidateID then
        return false, "Call changed - mark again"
    end
    if KWR.db.profile.fieldReviewContext ~= "Commander" or callout.context ~= "Commander"
        or entry.reviewContext ~= "Commander" then return false, "Feedback is disabled outside Commander context." end
    if currentOnly then
        local state = KWR.Store:Get()
        local view = KWR.CommandView:CommanderCard(state)
        local current = self:FeedbackFocus(view)
        if not current or current.calloutId ~= focus.calloutId or self.active ~= entry
            or not view.eligible or not sameView(callout, view) then
            return false, "Call changed - mark again"
        end
    end
    -- Pre-feature aggregates have no reversible contribution ledger. They
    -- cannot receive new qualifying corrections under a guessed attribution.
    if entry.learned and KWR.Learning and KWR.Learning.CanCorrectFollowthrough
        and not KWR.Learning:CanCorrectFollowthrough(entry, command) then
        return false, "This older learned record has no reversible feedback ledger."
    end
    local ok, message, event = KWR.CommandReview:AppendFollowthrough(callout, mark)
    if not ok then return false, message end
    if entry.endedAt and KWR.Learning then
        -- Reconcile finalized qualified episodes in the AAR owner's batch, not
        -- in a UI handler or by incrementing a success counter from a click.
        entry.followthroughPending = true
        self:QueueFollowthroughReview()
    end
    return true, message, event
end

function AAR:UndoFollowthrough(focus, eventId)
    local callout = self:FindFeedbackCall(focus)
    local last = callout and callout.events and callout.events[#callout.events]
    if not last or last.eventId ~= eventId then return false, "Feedback changed - review the selected call." end
    local previous = last.previousState
    if previous ~= "FOLLOWED" and previous ~= "NOT_FOLLOWED" and previous ~= "UNMARKED" then
        return false, "Previous mark is not retained; use an explicit correction."
    end
    local ok, message, event = self:MarkFollowthrough(focus, previous, false)
    if ok then
        event.undoOfEventId = eventId
        return true, "Last mark undone; audit history retained.", event
    end
    return false, message
end

function AAR:QueueFollowthroughReview()
    if self.followthroughReviewQueued then return end
    self.followthroughReviewQueued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, function() AAR:ReconcileFollowthrough() end)
    end
end

function AAR:ReconcileFollowthrough()
    self.followthroughReviewQueued = nil
    for _, entry in ipairs(self:GetHistory()) do
        if entry.followthroughPending then
            if KWR.Learning and KWR.Learning.RecordReviewed then
                KWR.Learning:RecordReviewed(entry)
            end
            entry.followthroughPending = nil
        end
    end
end

function AAR:FollowthroughReview(focus)
    local callout, command = self:FindFeedbackCall(focus)
    if not callout then return "The selected call is no longer retained." end
    local outcome = KWR.CommandReview:OutcomeObserved(command)
        and command.executionObservation.outcome or "UNKNOWN"
    return "Candidate: " .. callout.candidateId .. "\nMatch: " .. callout.matchId
        .. "\nCall: " .. callout.calloutId .. "\nAdherence: " .. KWR.CommandReview:EffectiveFollowthrough(callout)
        .. " (leader report)\nObserved strategic outcome: " .. outcome
        .. "\nLocal call outcome: UNKNOWN (not independently qualified)"
        .. "\nDelivery: " .. (KWR.CommandReview:DeliveryEligible(command) and "LEADER_ATTESTED" or "UNVERIFIED")
        .. "\nFollowed is not successful; no causal match-win credit.\n\n" .. callout.speech
end
