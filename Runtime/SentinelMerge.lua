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
    for _, families in pairs(KWR.SentinelIngress.byEnemy or {}) do
        for _, senders in pairs(families) do
            for _, record in pairs(senders) do
        local body = record.body or {}
        local applied = KWR.EnemyIntel and KWR.EnemyIntel:ObserveRemote(
            body, record.kind, record.sender, record.at) == true
        local observedName = KWR.Util:CanonicalName(text(body.enemy or body.carrier, "", 64))
        for _, enemy in ipairs(snapshot.enemies or {}) do
            if observedName ~= "" and KWR.Util:CanonicalName(enemy.name or "") == observedName then
                if record.kind == "OBS_VISIBLE" then
                    -- Remote visibility can enrich a stale/unknown row but
                    -- may never negate the stronger local sensor result that
                    -- was already captured for this snapshot.
                    if body.visible == "1" then
                        enemy.visible = true
                        enemy.lastSeenAt = record.at
                    end
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
        end
    end
    for _, senders in pairs(KWR.SentinelIngress.byObjective or {}) do
        for _, record in pairs(senders) do
            local body = record.body or {}
            local carrier = KWR.ObjectiveIntel and KWR.ObjectiveIntel:ObserveRemoteCarrier(body, record.at)
            if carrier then
                local owner = "UNKNOWN"
                local observed = KWR.Util:CanonicalName(carrier.player)
                for _, player in ipairs(snapshot.roster or {}) do
                    if KWR.Util:CanonicalName(player.name or "") == observed then owner = "FRIENDLY"; break end
                end
                if owner == "UNKNOWN" then
                    for _, enemy in ipairs(snapshot.enemies or {}) do
                        if KWR.Util:CanonicalName(enemy.name or "") == observed then owner = "ENEMY"; enemy.carrier = true; break end
                    end
                end
                carrier.owner = owner
                snapshot.objectives = snapshot.objectives or {}
                snapshot.objectives.carriers = snapshot.objectives.carriers or {}
                local replaced = false
                for index, current in ipairs(snapshot.objectives.carriers) do
                    if current.objective == carrier.objective then snapshot.objectives.carriers[index] = carrier; replaced = true; break end
                end
                if not replaced then snapshot.objectives.carriers[#snapshot.objectives.carriers + 1] = carrier end
                remote[#remote + 1] = { name = carrier.player, kind = record.kind,
                    age = math.max(0, KWR.Util:Now() - (record.at or 0)), source = "REMOTE_SENTINEL",
                    sender = record.sender, applied = true }
            end
        end
    end
    snapshot.sentinelRemote = {
        count = #remote,
        observations = remote,
        diagnostics = KWR.SentinelIngress.diagnostics,
    }
    return snapshot
end

KWR:RegisterModule("SentinelMerge", SentinelMerge)
