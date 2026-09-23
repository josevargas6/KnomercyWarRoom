return function(KWR)
    local ingress = KWR.SentinelIngress
    local savedPlayers, savedEnemies, savedObjectives, savedSequences = ingress.byPlayer,
        ingress.byEnemy, ingress.byObjective, ingress.lastSeqBySender
    local savedDiagnostics = KWR.Util:Copy(ingress.diagnostics)
    local savedTime = GetTime
    local clock = 100
    GetTime = function() return clock end
    ingress:Reset()
    ingress.diagnostics = { accepted = 0, duplicate = 0, malformed = 0, throttled = 0 }
    for index = 1, 30 do
        local sender = "Flood" .. index .. "-Realm"
        assert(ingress:Accept({ kind = "HELLO", timestamp = clock, sequence = 1,
            body = "addon=KWR;class=ROGUE;role=DAMAGER;caps=1;epoch=epoch" .. index }, sender, {}),
            "Valid bounded sender packet was rejected")
        clock = clock + 1
    end
    local count = 0
    for _ in pairs(ingress.byPlayer) do count = count + 1 end
    assert(count == 20 and ingress.lastSeqBySender["flood1-realm"] == nil
        and ingress.lastSeqBySender["flood30-realm"] == 1,
        "Sentinel ingress sender cache did not evict oldest invented identities")
    clock = clock + 11
    ingress:Expire()
    assert(next(ingress.byPlayer) == nil and next(ingress.lastSeqBySender) == nil
        and next(ingress.byEnemy) == nil and next(ingress.byObjective) == nil,
        "Expired Sentinel senders retained an unbounded sequence or observation cache")
    ingress.byPlayer, ingress.byEnemy, ingress.byObjective, ingress.lastSeqBySender = savedPlayers,
        savedEnemies, savedObjectives, savedSequences
    ingress.diagnostics = savedDiagnostics
    GetTime = savedTime
end
