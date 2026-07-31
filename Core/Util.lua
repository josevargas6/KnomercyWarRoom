local _, KWR = ...

local Util = {}
KWR.Util = Util

function Util:IsSecret(value)
    if type(issecretvalue) ~= "function" then
        return false
    end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == true
end

function Util:Number(value, fallback)
    if value == nil or self:IsSecret(value) then
        return fallback
    end
    if type(value) ~= "number" and type(value) ~= "string" then
        return fallback
    end
    local ok, number = pcall(tonumber, value)
    if not ok or number == nil or self:IsSecret(number) then
        return fallback
    end
    return number
end

function Util:Boolean(value, fallback)
    if value == nil or self:IsSecret(value) or type(value) ~= "boolean" then
        return fallback == true
    end
    return value == true
end

function Util:Text(value, fallback, maxLength)
    fallback = fallback or ""
    if value == nil or self:IsSecret(value) then
        return fallback
    end
    local valueType = type(value)
    if valueType ~= "string" and valueType ~= "number" and valueType ~= "boolean" then
        return fallback
    end
    local ok, text = pcall(tostring, value)
    if not ok or self:IsSecret(text) then
        return fallback
    end
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("[\r\n;]", " "):gsub("%s+", " ")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if maxLength and #text > maxLength then
        text = text:sub(1, math.max(1, maxLength - 3)) .. "..."
    end
    return text ~= "" and text or fallback
end

function Util:TextClip(value, fallback, maxLength)
    local text = self:Text(value, fallback)
    if maxLength and #text > maxLength then
        text = text:sub(1, math.max(1, maxLength))
        text = text:gsub("%s+$", "")
    end
    return text
end

function Util:Upper(value, fallback, maxLength)
    local text = self:Text(value, fallback, maxLength)
    local ok, upper = pcall(string.upper, text)
    return ok and upper or (fallback or "")
end

function Util:Call(callable, ...)
    if type(callable) ~= "function" then
        return nil
    end
    local results = { pcall(callable, ...) }
    if not results[1] then
        return nil
    end
    table.remove(results, 1)
    return unpack(results)
end

function Util:Now()
    return type(GetTime) == "function" and GetTime() or 0
end

function Util:Clamp(value, minimum, maximum)
    value = self:Number(value, minimum) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Util:Clock(seconds)
    seconds = math.max(0, math.floor(self:Number(seconds, 0) or 0))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function Util:Age(seconds)
    seconds = math.max(0, math.floor(self:Number(seconds, 0) or 0))
    if seconds < 60 then return tostring(seconds) .. "s" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m" end
    return tostring(math.floor(seconds / 3600)) .. "h"
end

function Util:DateEpoch(text)
    text = self:Text(text, "", 16)
    local year, month, day = text:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
    year, month, day = self:Number(year, nil), self:Number(month, nil), self:Number(day, nil)
    if not year or not month or not day or type(time) ~= "function" then return nil end
    local ok, epoch = pcall(time, {
        year = year,
        month = month,
        day = day,
        hour = 12,
        min = 0,
        sec = 0,
    })
    return ok and self:Number(epoch, nil) or nil
end

function Util:DaysSinceDate(text, nowEpoch)
    local thenEpoch = self:DateEpoch(text)
    if not thenEpoch then return nil end
    if nowEpoch == nil then
        if type(time) ~= "function" then return nil end
        local ok, value = pcall(time)
        nowEpoch = ok and self:Number(value, nil) or nil
    end
    nowEpoch = self:Number(nowEpoch, nil)
    if not nowEpoch then return nil end
    return math.max(0, math.floor((nowEpoch - thenEpoch) / 86400))
end

function Util:Evidence(value, source, observedAt, ttl, confidence, verified)
    local now = self:Now()
    observedAt = self:Number(observedAt, nil)
    ttl = math.max(0, self:Number(ttl, 0) or 0)
    local known = value ~= nil and not self:IsSecret(value)
    local age = observedAt and math.max(0, now - observedAt) or nil
    local fresh = known and observedAt ~= nil and (ttl == 0 or age <= ttl)
    return {
        value = known and self:Copy(value) or nil,
        source = self:Text(source, "unknown", 40),
        observedAt = observedAt,
        age = age,
        ttl = ttl,
        expiresAt = observedAt and ttl > 0 and (observedAt + ttl) or nil,
        confidence = self:Upper(confidence,
            fresh and "MEDIUM" or "NONE", 12),
        verified = verified == true,
        state = not known and "UNKNOWN"
            or (not observedAt and "UNVERIFIED"
            or (fresh and (verified and "VERIFIED" or "OBSERVED") or "STALE")),
        fresh = fresh == true,
    }
end

function Util:EvidenceUsable(record, minimumConfidence)
    if type(record) ~= "table" or record.fresh ~= true then return false end
    local rank = { NONE = 0, LOW = 1, MEDIUM = 2, HIGH = 3 }
    local actual = rank[self:Upper(record.confidence, "NONE", 12)] or 0
    local required = rank[self:Upper(minimumConfidence, "LOW", 12)] or 1
    return actual >= required
end

function Util:Copy(source)
    if type(source) ~= "table" then
        return source
    end
    local target = {}
    for key, value in pairs(source) do
        target[key] = self:Copy(value)
    end
    return target
end

function Util:ShortName(name)
    name = self:Text(name, "Unknown", 48)
    return name:gsub("%-.*$", "")
end

function Util:CanonicalName(name)
    return self:Text(name, "", 96):lower()
end

function Util:CanonicalShortName(name)
    local short = self:ShortName(name)
    return self:Text(short, "", 48):lower()
end

function Util:CanonicalPlayerKey(name, guid)
    guid = self:Text(guid, "", 96)
    if guid ~= "" then return guid end
    local canonical = self:CanonicalName(name)
    if canonical == "" then return nil end
    return "NAME:" .. canonical
end

function Util:LegacyShortKey(name)
    local short = self:CanonicalShortName(name)
    return short ~= "" and short or nil
end

function Util:DeepEqual(left, right, seen)
    if left == right then return true end
    local leftType, rightType = type(left), type(right)
    if leftType ~= rightType then return false end
    if leftType ~= "table" then return false end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] ~= nil then
        return seen[left][right] == true
    end
    seen[left][right] = true
    local compared = {}
    for key, leftValue in pairs(left) do
        compared[key] = true
        if not self:DeepEqual(leftValue, right[key], seen) then
            seen[left][right] = false
            return false
        end
    end
    for key in pairs(right) do
        if not compared[key] then
            seen[left][right] = false
            return false
        end
    end
    return true
end

function Util:UnitName(unit)
    if type(UnitExists) == "function" then
        local exists = self:Call(UnitExists, unit)
        if not self:Boolean(exists, false) then return nil end
    end
    local name, realm = self:Call(UnitName, unit)
    name = self:Text(name, "", 32)
    realm = self:Text(realm, "", 32)
    if name == "" then return nil end
    return realm ~= "" and (name .. "-" .. realm) or name
end

function Util:UnitClass(unit)
    local localized, classFile = self:Call(UnitClass, unit)
    return self:Text(localized, "Unknown", 24), self:Upper(classFile, "UNKNOWN", 24)
end

function Util:TeamSide()
    local faction = self:Text(self:Call(UnitFactionGroup, "player"), "Alliance", 16)
    return faction == "Horde" and "right" or "left", faction or "Alliance"
end

function Util:TeamValue(left, right, team)
    local playerSide = self:TeamSide()
    if team == "friendly" then
        return playerSide == "left" and left or right
    end
    return playerSide == "left" and right or left
end

function Util:BattlefieldSessionKey(context)
    context = type(context) == "table" and context or {}
    local mapKey = self:Text(
        context.mapKey,
        self:Boolean(context.inPvP, false) and "UNKNOWN" or "WORLD",
        32)
    local mapID = self:Number(context.mapID, 0) or 0
    local instanceID = self:Number(context.instanceID, 0) or 0
    local phase = self:Boolean(context.inPvP, false) and "PVP" or "WORLD"
    local mode = self:Boolean(context.preview, false) and "PREVIEW" or "LIVE"
    return table.concat({
        mapKey,
        tostring(mapID),
        tostring(instanceID),
        phase,
        mode,
    }, ":")
end

function Util:Signature(parts)
    local normalized = {}
    for index, value in ipairs(parts or {}) do
        normalized[index] = self:Text(value, "", 160):lower()
    end
    return table.concat(normalized, "\031")
end

function Util:Context(input)
    if type(input) ~= "table" then return {} end
    if input.snapshot and type(input.snapshot) == "table" then
        return input.snapshot.context or {}
    end
    if input.context and type(input.context) == "table" then
        return input.context
    end
    return input
end

function Util:IsArenaContext(input)
    local context = self:Context(input)
    return self:Text(context.instanceType, "none", 16) == "arena"
end

function Util:IsBattlegroundContext(input)
    local context = self:Context(input)
    return self:Boolean(context.inPvP, false)
        and self:Text(context.instanceType, "none", 16) == "pvp"
end

function Util:IsPvEInstanceContext(input)
    local context = self:Context(input)
    local instanceType = self:Text(context.instanceType, "none", 16)
    if instanceType == "none" or instanceType == "" then
        return false
    end
    if instanceType == "pvp" or instanceType == "arena" then
        return false
    end
    return self:Boolean(context.inPvP, false) ~= true
end

function Util:AllowsCommandSurfaces(input)
    local context = self:Context(input)
    if self:Boolean(context.preview, false) == true then
        return true
    end
    if self:IsBattlegroundContext(context) then
        return true
    end
    return not self:IsPvEInstanceContext(context)
end

function Util:AllowsCompactBattlefieldSurfaces(input)
    local context = self:Context(input)
    -- The developer preview is a complete synthetic battleground snapshot.
    -- Treat it like a battlefield for compact-surface gating, while keeping
    -- the explicit PREVIEW marker on every surface so it can never be mistaken
    -- for live data.
    if self:Boolean(context.preview, false) == true then
        return true
    end
    return self:IsBattlegroundContext(context)
end

function Util:CallReadout(trust, urgency, input)
    local context = self:Context(input)
    local label = self:Upper(trust and trust.label, "NONE", 12)
    local pace = self:Upper(trust and trust.pace, "VERIFY_FIRST", 18)
    urgency = self:Number(urgency, 0) or 0
    if self:Boolean(context.preview, false) == true then
        return "orange", "PREVIEW"
    end
    if self:IsBattlegroundContext(context) ~= true then
        return "muted", "SETUP"
    end
    if label == "HIGH" and pace ~= "VERIFY_FIRST" then
        return "green", "SEND"
    end
    if urgency >= 60 or label == "MEDIUM" then
        return "yellow", "SETUP"
    end
    if label == "LOW" or pace == "VERIFY_FIRST" then
        return "orange", "CHECK"
    end
    return "muted", "HOLD"
end

function Util:ObjectiveSourceLabel(source)
    local value = self:Upper(source, "NONE", 24)
    if value == "PREVIEW" then
        return "PREVIEW"
    end
    if value:find("WIDGET", 1, true) or value:find("PUBLIC", 1, true)
        or value:find("BG_SYSTEM", 1, true) or value:find("BATTLEFIELD_FLAG", 1, true)
        or value:find("CARRIER", 1, true) then
        return "LIVE UI"
    end
    if value == "AREA_POI" then
        return "MAP"
    end
    if value == "NONE" or value == "UNKNOWN" then
        return "NONE"
    end
    return "OBSERVED"
end

function Util:AllowsBattlefieldSurfaces(input)
    return self:AllowsCompactBattlefieldSurfaces(input)
end

KWR:RegisterModule("Util", Util)