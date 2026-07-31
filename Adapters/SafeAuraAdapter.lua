local _, KWR = ...

local Adapter = {}
KWR.SafeAuraAdapter = Adapter

function Adapter:GetAura(unit, index, filter)
    if not unit or not C_UnitAuras
        or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return nil
    end
    local aura = KWR.Util:Call(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
    if type(aura) ~= "table" or KWR.Util:IsSecret(aura) then return nil end
    return aura
end

KWR:RegisterModule("SafeAuraAdapter", Adapter)