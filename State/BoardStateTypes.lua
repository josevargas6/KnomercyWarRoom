local _, KWR = ...

local Types = {}
KWR.BoardStateTypes = Types

Types.CONFIDENCE = {
    CONFIRMED = true,
    INFERRED = true,
    UNKNOWN = true,
}

Types.DEFAULT_LIMITS = {
    enemies = 16,
    friendlies = 10,
    objectives = 8,
    facts = 80,
}

function Types:Confidence(value)
    value = KWR.Util:Text(value, "UNKNOWN", 16)
    if self.CONFIDENCE[value] then return value end
    return "UNKNOWN"
end

function Types:Limit(name)
    return self.DEFAULT_LIMITS[name] or 16
end

function Types:AddBounded(target, value, limitName)
    if type(target) ~= "table" or value == nil then return end
    if #target >= self:Limit(limitName) then return end
    target[#target + 1] = value
end

function Types:EvidenceID(prefix, subject, index)
    return KWR.Util:Text(prefix, "evidence", 24) .. ":"
        .. KWR.Util:Text(subject, "unknown", 64) .. ":"
        .. tostring(index or 0)
end

KWR:RegisterModule("BoardStateTypes", Types)