local _, KWR = ...

local Adapter = {}
KWR.SafeUnitAdapter = Adapter

function Adapter:EnemyUnitFact(unit, source)
    if not unit or not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false)
        or not KWR.Util:Boolean(KWR.Util:Call(UnitIsPlayer, unit), false)
        or not KWR.Util:Boolean(KWR.Util:Call(UnitCanAttack, "player", unit), false) then
        return nil
    end
    return {
        type = "ENEMY_UNIT",
        source = source or unit,
        name = KWR.Util:UnitName(unit),
        guid = KWR.Util:Text(KWR.Util:Call(UnitGUID, unit), "", 80),
        confidence = "CONFIRMED",
        observedAt = KWR.Util:Now(),
    }
end

KWR:RegisterModule("SafeUnitAdapter", Adapter)