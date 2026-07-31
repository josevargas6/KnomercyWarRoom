local _, KWR = ...

local ProblemTypes = {
    FREE_CASTING_HEALER = {
        verb = "Subdue",
        baseSeverity = 94,
        capability = "singleTargetSubdue",
        description = "Free-casting healer creating support value.",
    },
    FREE_CAST_HEALER = {
        verb = "Subdue",
        baseSeverity = 86,
        capability = "singleTargetSubdue",
        alias = "FREE_CASTING_HEALER",
        description = "Legacy alias for free-casting healer support.",
    },
    CASTER_HEALER_SUPPORT = {
        verb = "Subdue",
        baseSeverity = 78,
        capability = "healerDisruption",
        description = "Secondary healer or caster support problem.",
    },
    LOCAL_HEALER_CONTROL = {
        verb = "Subdue",
        baseSeverity = 82,
        capability = "singleTargetSubdue",
        description = "Confirmed local healer requiring control during the kill window.",
    },
    KILLABLE_OVEREXTENDED = {
        verb = "Kill",
        baseSeverity = 82,
        capability = "pressure",
        alias = "KILL_TARGET_AVAILABLE",
        description = "Overextended kill target during the setup window.",
    },
    KILL_TARGET_AVAILABLE = {
        verb = "Kill",
        baseSeverity = 90,
        capability = "pressure",
        description = "Kill target is available if support is controlled.",
    },
    FLAG_CARRIER_ESCAPING = {
        verb = "Collapse",
        baseSeverity = 96,
        capability = "deny",
        description = "Enemy carrier route can become a score.",
    },
    BASE_UNDER_THREAT = {
        verb = "Spin",
        baseSeverity = 92,
        capability = "deny",
        description = "Base or node needs immediate denial.",
    },
    STEALTH_THREAT_MISSING = {
        verb = "Deny",
        baseSeverity = 74,
        capability = "deny",
        description = "Missing stealth threat can punish weak coverage.",
    },
    FRIENDLY_HEALER_UNDER_PRESSURE = {
        verb = "Peel",
        baseSeverity = 86,
        capability = "peel",
        description = "Friendly healer needs relief to keep the fight playable.",
    },
    OBJECTIVE_CARRIER_EXPOSED = {
        verb = "Kill",
        baseSeverity = 92,
        capability = "pressure",
        description = "Objective carrier is exposed enough to punish.",
    },
    NODE_SPIN_REQUIRED = {
        verb = "Spin",
        baseSeverity = 90,
        capability = "deny",
        description = "Node needs delay until reinforcement arrives.",
    },
    ROTATION_GAP_DETECTED = {
        verb = "Rotate",
        baseSeverity = 76,
        capability = "mobility",
        description = "Coverage gap needs a rotation.",
    },
    ENEMY_COOLDOWN_WINDOW = {
        verb = "Pressure",
        baseSeverity = 80,
        capability = "killWindowSetup",
        description = "Enemy defensive gap creates a pressure window.",
    },
    RESPAWN_WAVE_ADVANTAGE = {
        verb = "Collapse",
        baseSeverity = 84,
        capability = "pressure",
        description = "Numbers window exists before the enemy regroups.",
    },
    OBJECTIVE_DENIAL = {
        verb = "Deny",
        baseSeverity = 90,
        capability = "deny",
        description = "Objective action can swing the map state.",
    },
}

KWR.EnemyProblemTypes = ProblemTypes
KWR:RegisterModule("EnemyProblemTypes", ProblemTypes)