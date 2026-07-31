local _, KWR = ...

local ObjectiveWeights = {}
KWR.ObjectiveWeights = ObjectiveWeights

local DEFAULTS = {
    WORLD = { healer = 55, killTarget = 60, objective = 50 },
    NODE = { healer = 70, killTarget = 72, objective = 85 },
    FLAG = { healer = 78, killTarget = 82, objective = 90, carrier = 95 },
    ORB = { healer = 72, killTarget = 86, objective = 88, carrier = 94 },
    CART = { healer = 70, killTarget = 78, objective = 90 },
    RESOURCE = { healer = 68, killTarget = 76, objective = 92 },
}

function ObjectiveWeights:For(snapshot)
    local kind = KWR.Util:Text(snapshot and snapshot.context and snapshot.context.kind,
        "WORLD", 24)
    return DEFAULTS[kind] or DEFAULTS.WORLD
end

KWR:RegisterModule("ObjectiveWeights", ObjectiveWeights)