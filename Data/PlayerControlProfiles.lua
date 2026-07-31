local _, KWR = ...

local Profiles = {}
KWR.PlayerControlProfiles = Profiles

local NAMED = {
    knomercy = {
        singleTargetSubdue = 96,
        healerDisruption = 82,
        killWindowSetup = 76,
        notes = "High single-target subdue profile.",
    },
    stan = {
        singleTargetSubdue = 82,
        healerDisruption = 94,
        casterDisruption = 92,
        notes = "High caster and healer disruption profile.",
    },
}

local ROLE_BASE = {
    HEALER = { peel = 82, healerDisruption = 45, singleTargetSubdue = 35 },
    TANK = { peel = 70, deny = 70, singleTargetSubdue = 45 },
    DAMAGER = { pressure = 70, killWindowSetup = 60, singleTargetSubdue = 55 },
}

local function keyFor(player)
    local name = KWR.Util:ShortName(KWR.Util:Text(player and player.name, "", 64))
    return name:lower()
end

function Profiles:Resolve(player)
    player = player or {}
    local role = KWR.CombatSpells:Role(player.spec, player.role)
    local resolved = KWR.Util:Copy(ROLE_BASE[role] or ROLE_BASE.DAMAGER)
    local named = NAMED[keyFor(player)]
    if named then
        for key, value in pairs(named) do resolved[key] = value end
    end
    local cap = KWR.Capabilities and KWR.Capabilities.Resolve
        and KWR.Capabilities:Resolve(player.classFile, player.spec, player.heroTalent) or nil
    if cap and cap.ratings then
        resolved.peel = math.max(resolved.peel or 0, (cap.ratings.peel or 1) * 14)
        resolved.pressure = math.max(resolved.pressure or 0, (cap.ratings.pressure or 1) * 14)
        resolved.killWindowSetup = math.max(resolved.killWindowSetup or 0,
            (cap.ratings.killConfirm or 1) * 14)
        resolved.singleTargetSubdue = math.max(resolved.singleTargetSubdue or 0,
            (cap.ratings.ccPotential or 1) * 14)
    end
    resolved.role = role
    resolved.player = player.name
    return resolved
end

KWR:RegisterModule("PlayerControlProfiles", Profiles)