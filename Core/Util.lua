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

function Util:Signature(parts)
    local normalized = {}
    for index, value in ipairs(parts or {}) do
        normalized[index] = self:Text(value, "", 160):lower()
    end
    return table.concat(normalized, "\031")
end

KWR:RegisterModule("Util", Util)
