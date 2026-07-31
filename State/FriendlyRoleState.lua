local _, KWR = ...

local FriendlyRoleState = {}
KWR.FriendlyRoleState = FriendlyRoleState

function FriendlyRoleState:Build(player)
    local profile = KWR.PlayerControlProfiles:Resolve(player)
    return {
        player = player,
        name = player and player.name,
        role = profile.role,
        profile = profile,
        available = player and player.dead ~= true and player.connected ~= false,
        assignment = player and player.assignment,
        location = player and player.location,
        currentTargetGUID = player and player.currentTargetGUID,
        confidence = player and "CONFIRMED" or "UNKNOWN",
    }
end

KWR:RegisterModule("FriendlyRoleState", FriendlyRoleState)