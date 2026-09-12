return function(KWR)
    local review = KWR.CommandReview
    local commander = KWR.Commander
    local savedCurrent = commander.lastCommand
    local savedEpoch = time
    time = function() return 100 end
    local delivered = {
        commandId = "call:assault", commandRevision = 1, signature = "assault-farm",
        mapKey = "ARATHI", sessionKey = "ARATHI:field-a", inPvP = true,
        objectiveDecision = { target = "Farm" },
        delivery = { schemaVersion = 1, clock = "UNIX_SECONDS", commandId = "call:assault",
            commandRevision = 1, generatedAt = 90, deliveredAt = 95, context = "Commander",
            state = "LEADER_ATTESTED", source = "EXPLICIT_LEADER_CONFIRMATION" },
    }
    local function state(events)
        return { command = KWR.Util:Copy(delivered), snapshot = {
            context = { inPvP = true, mapKey = "ARATHI", sessionKey = "ARATHI:field-a" },
            objectives = { events = events or {} },
        } }
    end
    commander.lastCommand = KWR.Util:Copy(delivered)
    local live = state({ { id = "bg:98:7", kind = "ASSAULT", source = "BG_SYSTEM",
        objective = "Farm", observedAt = 98 } })
    local observed = commander:ObservePublicExecution(live.snapshot, live.command)
    assert(review:ExecutionEligible(observed)
        and observed.executionObservation.outcome == "OBSERVED"
        and observed.executionObservation.evidenceIds[1] == "bg:98:7",
        "Exact public assault did not bind execution observation")
    assert(not review:OutcomeObserved(observed), "Public activity manufactured causal outcome")
    local classified = KWR.AAR:BuildDecisionReviews({ observed }, "VICTORY")[1]
    assert(classified.executionQuality == "OBSERVED" and classified.decisionQuality == "NOT_SCORED"
        and classified.outcomeAligned == nil,
        "Observed activity received match-result credit")
    local current = commander.lastCommand
    assert(review:ExecutionEligible(current), "Observation was not retained for stable command refresh")
    local wrongCases = {
        { id = "bg:98:8", kind = "PICKUP", source = "BG_SYSTEM", objective = "Farm", observedAt = 98 },
        { id = "bg:98:9", kind = "ASSAULT", source = "BG_SYSTEM", objective = "Lumber Mill", observedAt = 98 },
        { id = "bg:94:10", kind = "ASSAULT", source = "BG_SYSTEM", objective = "Farm", observedAt = 94 },
        { id = "bg:98:11", kind = "ASSAULT", source = "REMOTE", objective = "Farm", observedAt = 98 },
    }
    for _, event in ipairs(wrongCases) do
        commander.lastCommand = KWR.Util:Copy(delivered)
        local candidate = state({ event })
        candidate.command.executionObservation = nil
        local result = commander:ObservePublicExecution(candidate.snapshot, candidate.command)
        assert(not review:ExecutionEligible(result), "Unqualified public fact bound execution")
    end
    commander.lastCommand = KWR.Util:Copy(delivered)
    local preview = state({ { id = "bg:98:12", kind = "ASSAULT", source = "BG_SYSTEM",
        objective = "Farm", observedAt = 98 } })
    preview.snapshot.context.preview = true
    assert(not review:ExecutionEligible(commander:ObservePublicExecution(preview.snapshot, preview.command)),
        "Preview event bound execution")
    commander.lastCommand = KWR.Util:Copy(delivered)
    local changedSession = state({ { id = "bg:98:13", kind = "ASSAULT", source = "BG_SYSTEM",
        objective = "Farm", observedAt = 98 } })
    changedSession.snapshot.context.sessionKey = "ARATHI:field-b"
    assert(not review:ExecutionEligible(commander:ObservePublicExecution(changedSession.snapshot, changedSession.command)),
        "A previous battlefield session bound a fresh observation")
    local flagDelivered = KWR.Util:Copy(delivered)
    flagDelivered.commandId, flagDelivered.signature = "call:capture", "capture-horde-flag"
    flagDelivered.mapKey, flagDelivered.action = "WSG", "CAPTURE ENEMY FLAG"
    flagDelivered.sessionKey = "WSG:field-a"
    flagDelivered.objectiveDecision = { target = "Enemy FC" }
    flagDelivered.delivery.commandId = flagDelivered.commandId
    local flagState = { command = KWR.Util:Copy(flagDelivered), snapshot = {
        context = { inPvP = true, mapKey = "WSG", sessionKey = "WSG:field-a",
            team = { faction = "Alliance" } },
        objectives = { events = { { id = "bg:99:flag", kind = "FLAG_CAPTURE", source = "BG_SYSTEM",
            objective = "Horde Flag", player = "Verite", observedAt = 99 } } },
    } }
    commander.lastCommand = KWR.Util:Copy(flagDelivered)
    local captured = commander:ObservePublicExecution(flagState.snapshot, flagState.command)
    assert(review:OutcomeObserved(captured)
        and captured.executionObservation.outcome == "SUCCESS"
        and captured.executionObservation.factKind == "BG_SYSTEM_FLAG_CAPTURE",
        "Exact post-delivery enemy-flag capture did not qualify a completed public outcome")
    flagState.command.executionObservation = nil
    flagState.snapshot.objectives.events[1].objective = "Alliance Flag"
    commander.lastCommand = KWR.Util:Copy(flagDelivered)
    assert(not review:ExecutionEligible(commander:ObservePublicExecution(flagState.snapshot, flagState.command)),
        "Friendly-flag capture qualified an enemy-flag capture command")
    commander.lastCommand = savedCurrent
    time = savedEpoch
end
