local _, KWR = ...

local CommanderComm = {
    PREFIX = "KWRSync1",
    VERSION = "2",
    MAX_BYTES = 240,
    sequence = 0,
    epoch = "",
    relay = {},
    diagnostics = { received = 0, rejected = 0, sent = 0 },
}
KWR.CommanderComm = CommanderComm

local ALLOWED_KIND = {
    HELLO = true,
    STATE = true,
    OBS_VISIBLE = true,
    OBS_CAST = true,
    OBS_CARRIER = true,
    RELAY_ASSIGN = true,
    RELAY_CONTROL = true,
    RELAY_ACTION = true,
}

local ENVELOPE_FIELDS = {
    v = true, sid = true, seq = true, kind = true,
    ts = true, ep = true, src = true, body = true,
}
local MAX_EXACT_INTEGER = 9007199254740991

local function text(value, fallback, maximum)
    return KWR.Util:Text(value, fallback or "", maximum or 96)
end

local function escape(value)
    -- Bound the finished envelope in Encode. Truncating an individual field
    -- can cut a percent escape or silently turn a complete relay into a
    -- different command.
    return (tostring(value or ""):gsub("[^%w%._%-]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

-- Both standalone transports use the same bounded UTF-8 protocol vectors.
local function validText(value)
    if value:find("[%z\1-\31\127]") then return false end
    local index = 1
    while index <= #value do
        local first = value:byte(index)
        local trailing, minimum, maximum = 0, 128, 191
        if first < 128 then
            trailing = 0
        elseif first >= 194 and first <= 223 then
            trailing = 1
        elseif first >= 224 and first <= 239 then
            trailing = 2
            if first == 224 then minimum = 160 end
            if first == 237 then maximum = 159 end
        elseif first >= 240 and first <= 244 then
            trailing = 3
            if first == 240 then minimum = 144 end
            if first == 244 then maximum = 143 end
        else
            return false
        end
        for offset = 1, trailing do
            local byte = value:byte(index + offset)
            local lower = offset == 1 and minimum or 128
            local upper = offset == 1 and maximum or 191
            if not byte or byte < lower or byte > upper then return false end
        end
        index = index + trailing + 1
    end
    return true
end

local function unescape(value)
    if type(value) ~= "string" then return nil end
    if value:gsub("%%(%x%x)", ""):find("%%") then return nil end
    local decoded = value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return validText(decoded) and decoded or nil
end

local function now()
    return KWR.Util:Now()
end

local function shortName(value)
    return KWR.Util:ShortName(text(value, "", 64)):lower()
end

local function identity(unit)
    if type(UnitFullName) == "function" then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            return realm and realm ~= "" and (name .. "-" .. realm) or name
        end
    end
    return UnitName and UnitName(unit) or ""
end

local function canonical(value)
    return text(value, "", 96):lower()
end

function CommanderComm:SessionKey(state)
    local context = state and state.snapshot and state.snapshot.context or {}
    if context.inPvP ~= true then return "world" end
    return "pvp-" .. tostring(KWR.Util:Number(context.mapID, 0) or 0)
        .. "-" .. tostring(KWR.Util:Number(context.instanceID, 0) or 0)
end

function CommanderComm:Encode(kind, body, state)
    if not ALLOWED_KIND[kind] then return nil end
    self.sequence = self.sequence + 1
    local fields = {
        "v=" .. self.VERSION,
        "sid=" .. escape(self:SessionKey(state)),
        "seq=" .. tostring(self.sequence),
        "kind=" .. kind,
        "ts=" .. tostring(math.floor(now())),
        "ep=" .. escape(self.epoch),
        "src=" .. escape(identity("player")),
        "body=" .. escape(body or ""),
    }
    local payload = table.concat(fields, "|")
    return #payload <= self.MAX_BYTES and payload or nil
end

function CommanderComm:Decode(payload)
    if KWR.Util:IsSecret(payload) or type(payload) ~= "string"
        or #payload == 0 or #payload > self.MAX_BYTES then
        return nil, "size"
    end
    if payload:sub(1, 1) == "|" or payload:sub(-1) == "|"
        or payload:find("||", 1, true) then return nil, "shape" end
    local values, count = {}, 0
    for field in payload:gmatch("[^|]+") do
        local key, value = field:match("^([a-z]+)=(.*)$")
        if not ENVELOPE_FIELDS[key] or values[key] ~= nil then return nil, "shape" end
        values[key] = value
        count = count + 1
    end
    if count ~= 8 or values.v ~= self.VERSION or not ALLOWED_KIND[values.kind]
        or not values.sid or not values.seq or not values.ts
        or not values.seq:match("^%d+$") or not values.ts:match("^%d+$")
        or not values.ep or not values.src or values.body == nil then
        return nil, "schema"
    end
    local sequence, timestamp = tonumber(values.seq), tonumber(values.ts)
    if not sequence or sequence < 1 or sequence > MAX_EXACT_INTEGER
        or not timestamp or timestamp < 0 or timestamp > MAX_EXACT_INTEGER then
        return nil, "number"
    end
    local decoded = {
        version = values.v,
        session = unescape(values.sid),
        sequence = sequence,
        kind = values.kind,
        timestamp = timestamp,
        epoch = unescape(values.ep),
        source = unescape(values.src),
        body = unescape(values.body),
    }
    if not decoded.session or not decoded.epoch or not decoded.source or decoded.body == nil
        or decoded.session == "" or decoded.epoch == "" or decoded.source == "" then
        return nil, "encoding"
    end
    return decoded
end

function CommanderComm:IsRosterSender(sender, state)
    local wanted = canonical(sender)
    if wanted == "" then return false end
    for _, row in ipairs(state and state.snapshot and state.snapshot.roster or {}) do
        if wanted == canonical(row.name) then return true end
    end
    return false
end

function CommanderComm:Distribution(state)
    local context = state and state.snapshot and state.snapshot.context or {}
    if context.inPvP then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

function CommanderComm:TransportEnabled()
    return KWR.db and KWR.db.profile
        and KWR.db.profile.sentinelTransportEnabled == true
end

function CommanderComm:SetTransportEnabled(enabled)
    if not KWR.db or not KWR.db.profile then return false end
    KWR.db.profile.sentinelTransportEnabled = enabled == true
    if not enabled then
        if KWR.SentinelIngress then KWR.SentinelIngress:Reset() end
        -- Do not let an OFF period preserve throttled relay state and make a
        -- subsequent explicit re-enable look like it has sent current state.
        self.relay = {}
    end
    return true
end

function CommanderComm:Send(kind, body, state)
    -- This is the final outbound boundary.  Callers can retain peer state or
    -- write the profile directly, so ingress cleanup alone is not a transport
    -- OFF guarantee.
    if not self:TransportEnabled() then return false end
    local distribution = self:Distribution(state)
    local payload = distribution and self:Encode(kind, body, state)
    if not payload or not C_ChatInfo or type(C_ChatInfo.SendAddonMessage) ~= "function" then
        return false
    end
    local result = KWR.Util:Call(C_ChatInfo.SendAddonMessage, self.PREFIX, payload, distribution)
    -- Retail returns Enum.SendAddonMessageResult.Success (currently 0), not
    -- boolean true. Treat both valid success representations as sent.
    local success = result == true
        or (Enum and Enum.SendAddonMessageResult and result == Enum.SendAddonMessageResult.Success)
    if success then self.diagnostics.sent = self.diagnostics.sent + 1 end
    return success
end

function CommanderComm:Receive(prefix, payload, distribution, sender)
    if not self:TransportEnabled() or prefix ~= self.PREFIX
        or (distribution ~= "INSTANCE_CHAT" and distribution ~= "RAID" and distribution ~= "PARTY") then
        return false
    end
    local packet, reason = self:Decode(payload)
    local state = KWR.Store and KWR.Store:Get() or nil
    if not packet or not state or packet.kind:find("^RELAY_")
        or packet.session ~= self:SessionKey(state)
        or canonical(sender) ~= canonical(packet.source)
        or not self:IsRosterSender(sender, state) then
        self.diagnostics.rejected = self.diagnostics.rejected + 1
        return false, reason or "sender"
    end
    if not KWR.SentinelIngress or not KWR.SentinelIngress:Accept(packet, sender, state) then
        self.diagnostics.rejected = self.diagnostics.rejected + 1
        return false, "ingress"
    end
    self.diagnostics.received = self.diagnostics.received + 1
    if KWR.MatchRuntime then KWR.MatchRuntime:Queue("sentinel-" .. packet.kind, 0.15) end
    return true
end

function CommanderComm:Relay(state)
    if not self:TransportEnabled() or not KWR.SentinelRelay or not state then return end
    for _, player in ipairs(state.snapshot and state.snapshot.roster or {}) do
        local playerName = text(player.name or player.shortName, "", 64)
        local sentinel = KWR.SentinelIngress and KWR.SentinelIngress.byPlayer
            and KWR.SentinelIngress.byPlayer[canonical(playerName)]
        if sentinel and sentinel.HELLO then
            local relay = KWR.SentinelRelay:Build(playerName, state)
            for kind, body in pairs(relay or {}) do
                local signature = kind .. "|" .. body
                local previous = self.relay[playerName .. "|" .. kind]
                local changed = not previous or previous.signature ~= signature
                local elapsed = now() - (previous and previous.sentAt or -100)
                if (changed and elapsed >= 1) or elapsed >= 8 then
                    if self:Send(kind, body, state) then
                        self.relay[playerName .. "|" .. kind] = {
                            signature = signature,
                            sentAt = now(),
                        }
                    end
                end
            end
        end
    end
end

function CommanderComm:OnInitialize()
    self.epoch = tostring(math.floor(now() * 1000))
    self.frame = CreateFrame("Frame", "KWR_CommanderCommFrame")
    self.frame:RegisterEvent("CHAT_MSG_ADDON")
    self.frame:SetScript("OnEvent", function(_, _, prefix, payload, distribution, sender)
        CommanderComm:Receive(prefix, payload, distribution, sender)
    end)
    if C_ChatInfo and type(C_ChatInfo.RegisterAddonMessagePrefix) == "function" then
        KWR.Util:Call(C_ChatInfo.RegisterAddonMessagePrefix, self.PREFIX)
    end
end

KWR:RegisterModule("CommanderComm", CommanderComm)
