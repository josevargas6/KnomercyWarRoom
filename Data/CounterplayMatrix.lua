local _, KWR = ...

local Matrix = {}
KWR.CounterplayMatrix = Matrix

local ROWS = {
    FREE_CASTING_HEALER = {
        verbs = { "Subdue", "Disrupt", "Pressure" },
        capability = "singleTargetSubdue",
        objective = "Stop healer value during kill window.",
        killSupport = true,
    },
    CASTER_HEALER_SUPPORT = {
        verbs = { "Subdue", "Disrupt" },
        capability = "healerDisruption",
        objective = "Stop secondary support value during kill window.",
        killSupport = true,
    },
    LOCAL_HEALER_CONTROL = {
        verbs = { "Subdue", "Disrupt" },
        capability = "singleTargetSubdue",
        objective = "Keep the confirmed local healer controlled during the kill window.",
        killSupport = true,
    },
    KILL_TARGET_AVAILABLE = {
        verbs = { "Kill", "Pressure" },
        capability = "pressure",
        objective = "Convert kill pressure after support is controlled.",
    },
    FLAG_CARRIER_ESCAPING = {
        verbs = { "Collapse", "Deny", "Pressure" },
        capability = "deny",
        objective = "Stop the carrier route before it becomes a score.",
    },
    BASE_UNDER_THREAT = {
        verbs = { "Spin", "Deny", "Hold" },
        capability = "deny",
        objective = "Prevent the objective from flipping.",
    },
    STEALTH_THREAT_MISSING = {
        verbs = { "Deny", "Spin", "Hold" },
        capability = "deny",
        objective = "Protect the weak base from a stealth play.",
    },
    FRIENDLY_HEALER_UNDER_PRESSURE = {
        verbs = { "Peel", "Disrupt" },
        capability = "peel",
        objective = "Keep friendly healing active.",
    },
    OBJECTIVE_CARRIER_EXPOSED = {
        verbs = { "Kill", "Collapse", "Deny" },
        capability = "pressure",
        objective = "Convert carrier exposure into objective value.",
    },
    NODE_SPIN_REQUIRED = {
        verbs = { "Spin", "Hold" },
        capability = "deny",
        objective = "Delay the capture until help arrives.",
    },
    ROTATION_GAP_DETECTED = {
        verbs = { "Rotate", "Hold" },
        capability = "mobility",
        objective = "Close the coverage gap before the enemy arrives.",
    },
    ENEMY_COOLDOWN_WINDOW = {
        verbs = { "Pressure", "Kill" },
        capability = "killWindowSetup",
        objective = "Use the enemy cooldown gap before it closes.",
    },
    RESPAWN_WAVE_ADVANTAGE = {
        verbs = { "Collapse", "Pressure" },
        capability = "pressure",
        objective = "Use the numbers window before the enemy regroups.",
    },
}

local LEGACY = {
    FREE_CAST_HEALER = "FREE_CASTING_HEALER",
    KILLABLE_OVEREXTENDED = "KILL_TARGET_AVAILABLE",
    OBJECTIVE_DENIAL = "BASE_UNDER_THREAT",
}

function Matrix:Resolve(problemType)
    problemType = KWR.Util:Text(problemType, "", 48)
    local key = LEGACY[problemType] or problemType
    return ROWS[key] or {
        verbs = { "Pressure" },
        capability = "pressure",
        objective = "Create useful pressure without overcommitting.",
    }, key
end

function Matrix:PrimaryVerb(problemType)
    local row = self:Resolve(problemType)
    return row.verbs[1] or "Pressure"
end

function Matrix:Capability(problemType)
    local row = self:Resolve(problemType)
    return row.capability or "pressure"
end

function Matrix:Objective(problemType)
    local row = self:Resolve(problemType)
    return row.objective or "Create useful pressure."
end

KWR:RegisterModule("CounterplayMatrix", Matrix)