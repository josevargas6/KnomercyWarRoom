return function(KWR)
    local history = KWR.EncounterHistory
    local savedDatabase = KWR.Util:Copy(KWR.db.encounters)
    local savedSession, savedSeen = history.sessionKey, history.sessionSeen
    local savedMax, savedAge = history.maxPlayers, history.maxAgeSeconds
    local savedTime, savedPvP = time, C_PvP
    local now, seasonCalls = 1000, 0
    time = function() return now end
    C_PvP = { GetActiveSeason = function() seasonCalls = seasonCalls + 1 return 9 end }
    KWR.db.encounters = { players = {}, quarantine = {} }
    history.sessionKey, history.sessionSeen = nil, {}
    local player = { guid = "Player-Alpha", name = "Alpha-Realm", shortName = "Alpha",
        class = "Priest", classFile = "PRIEST", spec = "Holy", role = "HEALER" }
    local snapshot = { context = { mapKey = "ARATHI", inPvP = true }, roster = { player }, enemies = {} }
    history:Enrich(snapshot)
    local first = KWR.db.encounters.players["guid:Player-Alpha"]
    assert(first and first.encounters == 1 and first.firstSeenAt == now and first.lastSeenAt == now,
        "Initial encounter did not create the stable identity record")
    now = now + 5
    history:Enrich(snapshot)
    assert(KWR.db.encounters.players["guid:Player-Alpha"] == first
        and first.lastSeenAt == now and first.encounters == 1 and seasonCalls == 2,
        "Repeated observation allocated or called season more than once per capture")
    player.role = "DAMAGER"
    now = now + 5
    history:Enrich(snapshot)
    local changed = KWR.db.encounters.players["guid:Player-Alpha"]
    assert(changed ~= first and changed.role == "DAMAGER" and changed.encounters == 1,
        "Meaningful role update did not rebuild the record")
    player.spec = "Shadow"
    now = now + 5
    history:Enrich(snapshot)
    assert(KWR.db.encounters.players["guid:Player-Alpha"].spec == "Shadow"
        and KWR.db.encounters.players["guid:Player-Alpha"] ~= first,
        "Spec change was not recorded")
    history.sessionKey = "new-session"
    history.sessionSeen = {}
    now = now + 5
    history:Observe(player, "FRIENDLY", "ARATHI", 9, now)
    assert(KWR.db.encounters.players["guid:Player-Alpha"].encounters == 2,
        "New session did not increment encounter count")
    local unknown = { guid = "Player-Alpha", name = "Alpha-Realm", classFile = "PRIEST", spec = "Unknown" }
    history:Apply(unknown, 9)
    assert(unknown.spec == "Shadow" and unknown.specSource == "historical", "Historical record did not enrich unknown spec")
    local mismatch = { guid = "Player-Alpha", name = "Alpha-Realm", classFile = "MAGE", spec = "Unknown" }
    history:Apply(mismatch, 9)
    assert(mismatch.spec == "Unknown", "Different class accepted historical spec")
    local legacy = { name = "Legacy-Realm", shortName = "Legacy", classFile = "MAGE", class = "Mage",
        spec = "Frost", role = "DAMAGER", team = "ENEMY", mapKey = "ARATHI", season = 9, observedAt = now }
    KWR.db.encounters.players["legacy-realm"] = legacy
    local legacyEntity = { guid = "Player-Legacy", name = "Legacy-Realm", classFile = "MAGE", spec = "Unknown" }
    history:Apply(legacyEntity, 9)
    assert(legacyEntity.spec == "Frost", "Legacy name-keyed encounter did not remain readable")
    legacyEntity.spec = "Frost"
    now = now + 2
    history:Observe(legacyEntity, "ENEMY", "ARATHI", 9, now)
    assert(KWR.db.encounters.players["legacy-realm"] == nil
        and KWR.db.encounters.players["guid:Player-Legacy"], "Legacy record did not migrate to GUID identity")
    KWR.db.encounters.players.bad = { name = "Broken", spec = "Unknown" }
    KWR.db.encounters.players.old = { name = "Old", spec = "Fire", lastSeenAt = 1 }
    history.maxAgeSeconds = 10
    history:Prune(now)
    assert(KWR.db.encounters.players.bad == nil and KWR.db.encounters.quarantine.bad
        and KWR.db.encounters.players.old == nil,
        "Malformed or expired encounter entries were not isolated/pruned")
    for index = 1, 4 do
        KWR.db.encounters.players["guid:Cap-" .. index] = {
            identityKey = "guid:Cap-" .. index, name = "Cap" .. index, spec = "Fire",
            lastSeenAt = now + index, observedAt = now + index,
        }
    end
    history.maxPlayers = 2
    history.maxAgeSeconds = 9999
    history:Prune(now)
    assert(history:Count() <= 2 and KWR.db.encounters.players["guid:Cap-4"],
        "Encounter cap did not retain most recently observed records")
    C_PvP, time = savedPvP, savedTime
    KWR.db.encounters = savedDatabase
    history.sessionKey, history.sessionSeen = savedSession, savedSeen
    history.maxPlayers, history.maxAgeSeconds = savedMax, savedAge
end
