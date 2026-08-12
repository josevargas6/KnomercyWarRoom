local _, KWR = ...

local SentinelMerge = {}
KWR.SentinelMerge = SentinelMerge

local function text(value, fallback, maximum)
    return KWR.Util:Text(value, fallback or "", maximum or 64)
end

function SentinelMerge:Apply(snapshot)
    if not snapshot or not KWR.SentinelIngress then return snapshot end
    KWR.SentinelIngress:Expire()
    local remote = {}
    for _, record in pairs(KWR.SentinelIngress.byEnemy or {}) do
        local body = record.body or {}
        local applied = KWR.EnemyIntel and KWR.EnemyIntel:ObserveRemote(
            body, record.kind, record.sender) == true
        local observedName = KWR.Util:CanonicalName(text(body.enemy or body.carrier, "", 64))
        for _, enemy in ipairs(snapshot.enemies or {}) do
            if observedName ~= "" and KWR.Util:CanonicalName(enemy.name or "") == observedName then
                if record.kind == "OBS_VISIBLE" then
                    enemy.visible = body.visible == "1"
                    if enemy.visible then enemy.lastSeenAt = record.at end
                elseif record.kind == "OBS_CARRIER" then
                    enemy.carrier = true
                end
                break
            end
        end
        remote[#remote + 1] = {
            name = text(body.enemy or body.carrier, "unknown", 64),
            kind = record.kind,
            age = math.max(0, KWR.Util:Now() - (record.at or 0)),
            source = "REMOTE_SENTINEL",
            sender = record.sender,
            applied = applied,
        }
    end
    snapshot.sentinelRemote = {
        count = #remote,
        observations = remote,
        diagnostics = KWR.SentinelIngress.diagnostics,
    }
    return snapshot
end

KWR:RegisterModule("SentinelMerge", SentinelMerge)
