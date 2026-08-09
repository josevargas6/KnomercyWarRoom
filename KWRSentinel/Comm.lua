local _, Sentinel = ...

local Comm = {
    PREFIX = "KWRSync1",
    VERSION = "1",
    MAX_BYTES = 240,
    sequence = 0,
    sentAt = {},
    diagnostics = { sent = 0, received = 0, rejected = 0, throttled = 0 },
}
Sentinel.Comm = Comm

local ALLOWED = {
    HELLO = true, STATE = true, OBS_VISIBLE = true, OBS_CAST = true,
    OBS_CARRIER = true, OBS_PRESSURE = true, RELAY_ASSIGN = true,
    RELAY_CONTROL = true, RELAY_ACTION = true,
}
local LIMITS = { HELLO = 20, STATE = 2, OBS_VISIBLE = 1, OBS_CAST = 0.2, OBS_CARRIER = 1, OBS_PRESSURE = 2 }

local function text(value, fallback, maximum)
    value = value ~= nil and tostring(value) or ""
    if value == "" then value = fallback or "" end
    return value:sub(1, maximum or 96)
end

local function shortName(value)
    value = text(value, "", 64)
    local dash = value:find("-", 1, true)
    return (dash and value:sub(1, dash - 1) or value):lower()
end

local function escape(value)
    return (text(value, "", 120):gsub("[^%w%._%-]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function unescape(value)
    if type(value) ~= "string" or value:find("%%[^%x]", 1) or value:find("%%$", 1) then return nil end
    return value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
end

local function now()
    return GetTime and GetTime() or 0
end

function Comm:SessionKey()
    local inside, kind = IsInInstance and IsInInstance() or false, "none"
    if not inside or kind ~= "pvp" then return "world" end
    local _, _, _, _, _, _, _, instance = GetInstanceInfo()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or 0
    return "pvp-" .. tostring(tonumber(mapID) or 0) .. "-" .. tostring(tonumber(instance) or 0)
end

function Comm:Distribution()
    local inside, kind = IsInInstance and IsInInstance() or false, "none"
    if inside and kind == "pvp" then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

function Comm:Encode(kind, body)
    if not ALLOWED[kind] then return nil end
    self.sequence = self.sequence + 1
    local payload = table.concat({
        "v=" .. self.VERSION, "sid=" .. escape(self:SessionKey()),
        "seq=" .. tostring(self.sequence), "kind=" .. kind,
        "ts=" .. tostring(math.floor(now())),
        "src=" .. escape(shortName(UnitName and UnitName("player"))),
        "body=" .. escape(body or ""),
    }, "|")
    return #payload <= self.MAX_BYTES and payload or nil
end

function Comm:Decode(payload)
    if type(payload) ~= "string" or #payload == 0 or #payload > self.MAX_BYTES then return nil end
    local fields, count = {}, 0
    for field in payload:gmatch("[^|]+") do
        local key, value = field:match("^([a-z]+)=(.*)$")
        if not key or fields[key] ~= nil then return nil end
        fields[key], count = value, count + 1
    end
    if count ~= 7 or fields.v ~= self.VERSION or not ALLOWED[fields.kind]
        or not fields.seq:match("^%d+$") or not fields.ts:match("^%d+$") then return nil end
    local packet = { kind = fields.kind, session = unescape(fields.sid),
        sequence = tonumber(fields.seq), source = unescape(fields.src), body = unescape(fields.body) }
    return packet.session and packet.source and packet.body and packet or nil
end

function Comm:Send(kind, body)
    local distribution = self:Distribution()
    local minimum = LIMITS[kind] or 0
    if not distribution or now() - (self.sentAt[kind] or -100) < minimum then
        self.diagnostics.throttled = self.diagnostics.throttled + 1
        return false
    end
    local payload = self:Encode(kind, body)
    if not payload or not C_ChatInfo or type(C_ChatInfo.SendAddonMessage) ~= "function" then return false end
    local ok = pcall(C_ChatInfo.SendAddonMessage, self.PREFIX, payload, distribution)
    if ok then self.sentAt[kind], self.diagnostics.sent = now(), self.diagnostics.sent + 1 end
    return ok
end

function Comm:Receive(prefix, payload, distribution, sender)
    if prefix ~= self.PREFIX or distribution == "WHISPER" then return false end
    local packet = self:Decode(payload)
    if not packet or packet.session ~= self:SessionKey()
        or shortName(sender) ~= packet.source or not packet.kind:find("^RELAY_") then
        self.diagnostics.rejected = self.diagnostics.rejected + 1
        return false
    end
    if Sentinel.Relay and Sentinel.Relay:Accept(packet, sender) then
        self.diagnostics.received = self.diagnostics.received + 1
        return true
    end
    self.diagnostics.rejected = self.diagnostics.rejected + 1
    return false
end

function Comm:OnInitialize()
    self.frame = CreateFrame("Frame", "KWRSentinel_CommFrame")
    self.frame:RegisterEvent("CHAT_MSG_ADDON")
    self.frame:SetScript("OnEvent", function(_, _, prefix, payload, distribution, sender)
        Comm:Receive(prefix, payload, distribution, sender)
    end)
    if C_ChatInfo and type(C_ChatInfo.RegisterAddonMessagePrefix) == "function" then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, self.PREFIX)
    end
end

Sentinel:RegisterModule("Comm", Comm)
