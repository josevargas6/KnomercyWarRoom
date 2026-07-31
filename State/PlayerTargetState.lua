local _, KWR = ...

local PlayerTargetState = {}
KWR.PlayerTargetState = PlayerTargetState

function PlayerTargetState:Match(player, target)
    local current = player and player.currentTargetGUID
    local wanted = target and target.guid
    if current and wanted and current == wanted then
        return "MATCHED"
    end
    if wanted then return "NOT_TARGETED" end
    return "UNKNOWN"
end

KWR:RegisterModule("PlayerTargetState", PlayerTargetState)