local _, KWR = ...

local FactStore = {}
KWR.FactStore = FactStore

local function add(facts, fact)
    local ok = not KWR.ComplianceGate or KWR.ComplianceGate:AllowFact(fact)
    if ok then facts[#facts + 1] = fact end
end

function FactStore:FromSnapshot(snapshot)
    local facts = {}
    add(facts, KWR.SafeBattlegroundAdapter and KWR.SafeBattlegroundAdapter:ContextFact(snapshot)
        or { type = "BATTLEGROUND_CONTEXT", source = "internal" })
    for _, enemy in ipairs(snapshot and snapshot.enemies or {}) do
        add(facts, {
            type = "ENEMY",
            source = KWR.ComplianceGate and KWR.ComplianceGate:NormalizeSource(
                KWR.Util:Text(enemy.source, enemy.visible and "nameplate" or "scoreboard", 32))
                or KWR.Util:Text(enemy.source, enemy.visible and "nameplate" or "scoreboard", 32),
            subject = enemy.guid or enemy.name,
            enemy = enemy,
            confidence = enemy.visible and "CONFIRMED" or "INFERRED",
            observedAt = KWR.Util:Now(),
        })
    end
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        add(facts, {
            type = "FRIENDLY",
            source = "scoreboard",
            subject = player.guid or player.name,
            player = player,
            confidence = "CONFIRMED",
            observedAt = KWR.Util:Now(),
        })
    end
    return {
        facts = facts,
        generatedAt = KWR.Util:Now(),
        ruleset = KWR.ComplianceGate and KWR.ComplianceGate:Ruleset() or {},
    }
end

KWR:RegisterModule("FactStore", FactStore)