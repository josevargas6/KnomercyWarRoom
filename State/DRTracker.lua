local _, KWR = ...

local DRTracker = {}
KWR.DRTracker = DRTracker

function DRTracker:StateFor(enemy, category)
    local state = "UNKNOWN"
    local confidence = "UNKNOWN"
    local remaining
    local source = "none"
    local categoryKey = category or "subdue"
    local dr = enemy and enemy.dr
    if type(dr) == "table" then
        local row = dr[categoryKey] or dr.subdue or dr.control
        if type(row) == "table" then
            state = KWR.Util:Text(row.state, "UNKNOWN", 24)
            confidence = KWR.BoardStateTypes and KWR.BoardStateTypes:Confidence(row.confidence)
                or KWR.Util:Text(row.confidence, "UNKNOWN", 16)
            remaining = KWR.Util:Number(row.remaining, nil)
            source = KWR.Util:Text(row.source, "safe_fact", 32)
        elseif type(row) == "string" then
            state = KWR.Util:Text(row, "UNKNOWN", 24)
            confidence = "INFERRED"
            source = "safe_fact"
        end
    elseif enemy and enemy.drImmune == true then
        state = "IMMUNE"
        confidence = "INFERRED"
        source = "safe_flag"
    elseif enemy and enemy.drDiminished == true then
        state = "DIMINISHED"
        confidence = "INFERRED"
        source = "safe_flag"
    end
    return {
        subject = enemy and (enemy.guid or enemy.name),
        category = categoryKey,
        state = state,
        confidence = confidence,
        remaining = remaining,
        source = source,
    }
end

KWR:RegisterModule("DRTracker", DRTracker)