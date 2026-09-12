return function(KWR)
    local store = KWR.Store
    local saved = {
        state = store.state, listeners = store.listeners, sequence = store.listenerSequence,
        queue = store.notifyQueue, index = store.notifyIndex, previous = store.notifyPrevious,
        notifyState = store.notifyState, generation = store.notifyGeneration,
        pass = store.notifyPassGeneration, scheduled = store.notifyScheduled,
        flushing = store.notifyFlushing,
    }
    store.state, store.listeners, store.listenerSequence = nil, {}, 0
    store.notifyQueue, store.notifyIndex, store.notifyPrevious, store.notifyState = nil, 1, nil, nil
    store.notifyGeneration, store.notifyPassGeneration, store.notifyScheduled, store.notifyFlushing = 0, 0, false, false
    local order, revisions = {}, {}
    local ownerA, ownerB, ownerC = {}, {}, {}
    store:Subscribe(ownerA, function(_, state) order[#order + 1] = "A"; revisions[#revisions + 1] = state.revision end)
    store:Subscribe(ownerB, function(_, state) order[#order + 1] = "B"; revisions[#revisions + 1] = state.revision end)
    store:Subscribe(ownerC, function(_, state) order[#order + 1] = "C"; revisions[#revisions + 1] = state.revision end)
    local snapshot = { context = { mapKey = "ARATHI", nested = { owner = "Alliance" } },
        score = { friendly = 100 }, objectives = { rows = { { label = "Farm" } } } }
    local prediction = { score = { value = 1 } }
    local assignments = { { name = "Alpha", job = { location = "Farm" } } }
    local command = { action = "Hold Farm", activePlay = { id = "Farm" } }
    local diagnostics = { stage = { name = "first" } }
    local first = store:Publish(snapshot, prediction, assignments, command, diagnostics)
    snapshot.context.nested.owner = "Mutated"
    prediction.score.value = 99
    assignments[1].job.location = "Mutated"
    command.activePlay.id = "Mutated"
    diagnostics.stage.name = "Mutated"
    assert(first.snapshot.context.nested.owner == "Alliance"
        and first.prediction.score.value == 1 and first.assignments[1].job.location == "Farm"
        and first.activePlay.id == "Farm" and first.diagnostics.stage.name == "first",
        "Store retained a producer-owned nested branch")
    local nextSnapshot = { context = { mapKey = "ARATHI" }, score = { friendly = 200 }, objectives = { rows = {} } }
    local second = store:Publish(nextSnapshot, { score = { value = 2 } }, {},
        { action = "Rotate", activePlay = { id = "Lumber Mill" } }, { stage = { name = "second" } })
    assert(first.revision == 1 and first.snapshot.context.nested.owner == "Alliance"
        and second.snapshot.context.nested == nil,
        "Store changed the previous snapshot or retained a removed field")
    assert(table.concat(order, "") == "ABCABC" and revisions[#revisions] == 2,
        "Store listener delivery order or latest generation changed")
    local filtered, filterOwner = 0, {}
    store:SubscribeFiltered(filterOwner, function() filtered = filtered + 1 end,
        function(_, state) return state.command.action end)
    store:Publish(nextSnapshot, { score = { value = 2 } }, {},
        { action = "Rotate", activePlay = { id = "Lumber Mill" } }, { stage = { name = "second" } })
    store:Publish(nextSnapshot, { score = { value = 3 } }, {},
        { action = "Hold", activePlay = { id = "Farm" } }, { stage = { name = "third" } })
    assert(filtered == 2, "Filtered listener did not suppress unchanged command domain")
    store.state, store.listeners, store.listenerSequence = saved.state, saved.listeners, saved.sequence
    store.notifyQueue, store.notifyIndex, store.notifyPrevious, store.notifyState = saved.queue, saved.index, saved.previous, saved.notifyState
    store.notifyGeneration, store.notifyPassGeneration, store.notifyScheduled, store.notifyFlushing = saved.generation, saved.pass, saved.scheduled, saved.flushing
end
