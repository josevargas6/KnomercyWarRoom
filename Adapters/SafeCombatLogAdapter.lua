local _, KWR = ...

local Adapter = {
    enabled = false,
}
KWR.SafeCombatLogAdapter = Adapter

function Adapter:IsEnabled()
    return false
end

function Adapter:Normalize()
    return nil, "combat log unavailable under current policy"
end

KWR:RegisterModule("SafeCombatLogAdapter", Adapter)