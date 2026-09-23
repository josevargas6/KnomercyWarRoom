return function(KWR)
    local savedTime, savedSecret = GetTime, issecretvalue
    local clock = 100
    local opaque = {}
    GetTime = function() return clock end
    issecretvalue = function(value) return rawequal(value, opaque) end
    local util = KWR.Util
    local no = util:Evidence(false, "group_units", 100, 5, "HIGH", true)
    local zero = util:Evidence(0, "ui_widget", 100, 5, "HIGH", true)
    assert(no.value == false and zero.value == 0 and util:EvidenceUsable(no, "HIGH")
        and util:EvidenceUsable(zero, "HIGH"), "False or zero evidence was lost")
    for _, invalid in ipairs({ -1, math.huge, 0/0, "invalid", opaque }) do
        local time = util:Evidence(true, "fixture", invalid, 5, "HIGH", true)
        local ttl = util:Evidence(true, "fixture", 100, invalid, "HIGH", true)
        assert(time.state == "UNVERIFIED" and not time.fresh and not util:EvidenceUsable(time),
            "Invalid observation time was accepted")
        assert(ttl.state == "UNVERIFIED" and not ttl.fresh and not util:EvidenceUsable(ttl),
            "Invalid TTL became an unlimited lifetime")
    end
    local missing = util:Evidence(true, "fixture", nil, 5, "HIGH", true)
    local missingTTL = util:Evidence(true, "fixture", 100, nil, "HIGH", true)
    local future = util:Evidence(true, "fixture", 101, 5, "HIGH", true)
    assert(not missing.fresh and not missingTTL.fresh and not future.fresh
        and future.observedAt == 101 and future.age == nil, "Missing/future evidence became current")
    assert(util:Evidence(nil, "fixture", 100, 5, "HIGH", true).state == "UNKNOWN"
        and util:Evidence(opaque, "fixture", 100, 5, "HIGH", true).state == "UNKNOWN",
        "Unknown or protected value became observed")
    clock = 105
    assert(util:EvidenceUsable(no, "HIGH"), "Exact TTL boundary changed")
    clock = 105.001
    assert(not util:EvidenceUsable(no, "HIGH"), "Cached fresh flag outlived observation TTL")
    assert(no.observedAt == 100 and no.age == 0 and no.fresh == true and no.value == false,
        "Use-time freshness check mutated construction-time evidence")
    clock = 99
    assert(not util:EvidenceUsable(no, "HIGH"), "Clock rollback accepted future evidence")
    clock = 100
    local reference = util:Evidence("reference", "map_definition", 100, 0, "LOW", false)
    clock = 10000
    assert(util:EvidenceUsable(reference, "LOW") and not util:EvidenceUsable(reference, "HIGH"),
        "Explicit zero-TTL reference or confidence threshold changed")
    clock = math.huge
    assert(not util:Evidence(true, "fixture", 100, 5, "HIGH", true).fresh
        and not util:EvidenceUsable(no), "Invalid clock was accepted")
    clock = 100
    local snapshot = {
        capturedAt = 100,
        context = { inPvP = true, mapKey = "WSG", kind = "FLAG", capturedAt = 100,
            team = { faction = "Horde", side = "right", source = "scoreboard" } },
        score = { friendly = 1, enemy = 0, max = 3, source = "ui_widget", observedAt = 100 },
        objectives = { source = "ui_widget", observedAt = 100, rows = {} },
        roster = { {} }, enemies = { {} },
        reporter = { updatedAt = 100, coverage = { friendlyLocated = 3, enemyLocated = 1 } },
    }
    local current = KWR.Verification:Contract(snapshot)
    assert(current.coreFresh and current.aggressiveCommitAllowed, "Fixture lacks usable core evidence")
    snapshot.score.observedAt = 101
    local futureContract = KWR.Verification:Contract(snapshot)
    assert(not futureContract.coreFresh and not futureContract.aggressiveCommitAllowed,
        "Production truth gate accepted a future score observation")
    snapshot.score.observedAt = 100
    clock = 106
    local expired = KWR.Verification:Contract(snapshot)
    assert(not expired.coreFresh and not expired.aggressiveCommitAllowed
        and expired.facts.score.state == "STALE", "Production truth gate accepted expired score truth")
    assert(not util:EvidenceUsable(current.facts.score, "HIGH"), "Previously built contract retained score authority")
    GetTime, issecretvalue = savedTime, savedSecret
end
