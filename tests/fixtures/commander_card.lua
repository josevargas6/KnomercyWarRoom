return function(KWR)
    local mover = "LongCommanderName-LongUnbrokenRealmName"
    local defender = "LongCommanderName-AnotherUnbrokenRealmName"
    local target = "FullEnemyIdentity-EnemyHomeRealm"
    local healer = "FullHealerIdentity-SecondEnemyRealm"
    local state = {
        command = {
            commandId = "card-test", commandRevision = 1, generatedAt = 100,
            action = "Hold Blacksmith until the release call", when = "NOW",
            activePlay = { id = "hold", objective = "Blacksmith", movers = { mover },
                stayers = { defender }, action = "Hold Blacksmith until the release call" },
            activePlayCandidate = { id = "next", objective = "Lumber Mill", action = "Reinforce Lumber Mill",
                movers = { mover }, trigger = "Only after a verified release", abortRules = { "Abort if Farm is uncovered" } },
        },
        assignments = {
            { name = mover, guid = "Player-1", role = "Anchor", location = "Blacksmith" },
            { name = defender, guid = "Player-2", role = "Defender", location = "Farm" },
        },
        snapshot = {
            capturedAt = GetTime(),
            context = { inPvP = true, mapKey = "ARATHI", mapName = "Arathi Basin", sessionKey = "card-session" },
            roster = { { name = mover, guid = "Player-1" }, { name = defender, guid = "Player-2" } },
            enemies = { { name = target, guid = "Enemy-1" }, { name = healer, guid = "Enemy-2" } },
            executionCommand = { generatedAt = GetTime(), localFight = {
                phase = "ACTIVE", kill = { mode = "PRESSURE", target = target, targetGUID = "Enemy-1", location = "Blacksmith" },
                controls = { { actor = mover, actorGUID = "Player-1", target = healer, targetGUID = "Enemy-2",
                    verb = "Subdue", assigned = true, state = "ACTIVE" } },
            } },
        },
    }
    -- Legacy producer reproduction: source formatting already destroys the realm.
    local old = KWR.CommandView:FightNow(state)
    assert(not old.current.who:find(mover, 1, true), "Legacy truncation reproduction changed; review fixture")
    assert(type(KWR.CommandView.CommanderCard) == "function", "P13 structured commander card is missing")
    local card = KWR.CommandView:CommanderCard(state)
    assert(card.now.location == "Blacksmith" and card.now.action == state.command.action,
        "Local fight replaced the strategic NOW order")
    assert(card.next.location == "Lumber Mill" and card.next.trigger == "Only after a verified release",
        "NEXT lost its separate destination or release condition")
    for _, token in ipairs({ "LongCommanderName", "FullEnemyIdentity", "FullHealerIdentity",
        "Subdue", "Blacksmith", "Farm" }) do
        assert(card.speech:find(token, 1, true), "Current verbal bundle lost: " .. token)
    end
    assert(not card.speech:find("LongUnbrokenRealmName", 1, true)
        and not card.speech:find("EnemyHomeRealm", 1, true),
        "Commander-facing speech retained an unneeded realm name")
    assert(not card.speech:find("Lumber Mill", 1, true), "Speculative NEXT was issued in SAY NOW")
    assert(card.position.status == "UNKNOWN", "Assignment was presented as observed presence")
    assert(card.duties[1].actor.name == "LongCommanderName"
        and card.duties[1].actor.canonicalName == mover
        and card.duties[1].actor.guid == "Player-1",
        "Player-facing short name lost its retained canonical identity")
    local labels = {}
    for _, duty in ipairs(card.duties) do labels[duty.actor.label] = true end
    assert(labels["LongCommanderName [1]"] and labels["LongCommanderName [2]"]
        and not card.speech:find("LongCommanderName [", 1, true),
        "Duplicate player names were not visibly disambiguated without changing commander speech")
    local display = KWR.CommanderCard:Content(card)
    assert(display.duties:find("LongCommanderName [1]", 1, true)
        and display.duties:find("LongCommanderName [2]", 1, true),
        "Duplicate player-name labels did not reach the rendered card content")
    assert(card.localFight.intent == "PRESSURE", "Pressure became an unverified kill call")
    local originalKey = card.callKey
    state.snapshot.executionCommand.localFight.controls[1].target = "AnotherHealer-DifferentRealm"
    state.snapshot.executionCommand.localFight.controls[1].targetGUID = "Enemy-3"
    local changed = KWR.CommandView:CommanderCard(state)
    assert(changed.callKey ~= originalKey, "Local control revision did not change exact verbal-call identity")
    state.command.activePlayCandidate.objective = "Stables"
    assert(KWR.CommandView:CommanderCard(state).callKey == changed.callKey,
        "Unissued NEXT incorrectly changed the current feedback reference")
    state.command.activePlayCandidate.objective = "Lumber Mill"
    local compact = KWR.TeamfightCommandCard:Build({ title = "Legacy local call" }, state)
    assert(compact.scope == "COMMANDER_CARD_SUMMARY" and compact.callKey == changed.callKey,
        "Legacy mini-call did not consume the current commander-card projection")
    assert(compact.lines[1]:find(card.now.action, 1, true)
        and compact.lines[3]:find("NOT ISSUED", 1, true),
        "Legacy mini-call lost NOW/NEXT semantic separation")
    assert(compact.speech:find("LongCommanderName", 1, true)
        and compact.speech:find("AnotherHealer", 1, true),
        "Legacy mini-call lost the complete full-identity commander call")
    print("KWR_COMMANDER_CARD_PROJECTION_PASS")
    return state
end
