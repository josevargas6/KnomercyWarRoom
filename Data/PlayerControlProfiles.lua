local _, KWR = ...

local Profiles = {}
KWR.PlayerControlProfiles = Profiles

local ROLE_BASE = {
    HEALER = { peel = 82, healerDisruption = 45, singleTargetSubdue = 35 },
    TANK = { peel = 70, deny = 70, singleTargetSubdue = 45 },
    DAMAGER = { pressure = 70, killWindowSetup = 60, singleTargetSubdue = 55 },
}

function Profiles:Resolve(player)
    player = player or {}
    local role = KWR.CombatSpells:Role(player.spec, player.role)
    local resolved = KWR.Util:Copy(ROLE_BASE[role] or {})
    resolved.role = role
    resolved.roleKnown = ROLE_BASE[role] ~= nil
    resolved.player = player.name
    if not resolved.roleKnown then return resolved end
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
    return resolved
end

KWR:RegisterModule("PlayerControlProfiles", Profiles)
