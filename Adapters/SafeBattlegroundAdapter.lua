local _, KWR = ...

local Adapter = {}
KWR.SafeBattlegroundAdapter = Adapter

function Adapter:ContextFact(snapshot)
    local context = snapshot and snapshot.context or {}
    local observedAt = KWR.Util:Number(context.capturedAt, nil)
        or KWR.Util:Number(snapshot and snapshot.capturedAt, nil)
    if observedAt and (observedAt ~= observedAt or observedAt < 0 or observedAt == math.huge) then
        observedAt = nil
    end
    return {
        type = "BATTLEGROUND_CONTEXT",
        source = "internal",
        mapKey = context.mapKey,
        kind = context.kind,
        inPvP = context.inPvP == true,
        confidence = context.inPvP == true and observedAt and observedAt <= KWR.Util:Now()
            and "CONFIRMED" or "UNKNOWN",
        observedAt = observedAt,
    }
end

KWR:RegisterModule("SafeBattlegroundAdapter", Adapter)
