local _, KWR = ...

local FriendlyRoleState = {}
KWR.FriendlyRoleState = FriendlyRoleState

function FriendlyRoleState:Build(player)
    local profile = KWR.PlayerControlProfiles:Resolve(player)
    local dead = KWR.Util:OptionalBoolean(player and player.dead)
    local connected = KWR.Util:OptionalBoolean(player and player.connected)
    local available
    if dead == true or connected == false then
        available = false
    elseif dead == false and connected == true then
        available = true
    end
    return {
        player = player,
        name = player and player.name,
        role = profile.role,
        profile = profile,
        available = available,
        availability = available == true and "AVAILABLE"
            or (available == false and "UNAVAILABLE" or "UNKNOWN"),
        roleKnown = profile.roleKnown,
        assignment = player and player.assignment,
        location = player and player.location,
        currentTargetGUID = player and player.currentTargetGUID,
        confidence = available ~= nil and profile.roleKnown and "CONFIRMED" or "UNKNOWN",
    }
end

KWR:RegisterModule("FriendlyRoleState", FriendlyRoleState)
