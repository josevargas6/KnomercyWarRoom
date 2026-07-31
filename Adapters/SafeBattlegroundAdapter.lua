local _, KWR = ...

local Adapter = {}
KWR.SafeBattlegroundAdapter = Adapter

function Adapter:ContextFact(snapshot)
    local context = snapshot and snapshot.context or {}
    return {
        type = "BATTLEGROUND_CONTEXT",
        source = "internal",
        mapKey = context.mapKey,
        kind = context.kind,
        inPvP = context.inPvP == true,
        confidence = context.inPvP and "CONFIRMED" or "UNKNOWN",
        observedAt = KWR.Util:Now(),
    }
end

KWR:RegisterModule("SafeBattlegroundAdapter", Adapter)