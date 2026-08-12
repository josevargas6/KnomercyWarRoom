local _, KWR = ...

local CommanderComm = {
    PREFIX = "KWRSync1",
    VERSION = "1",
    MAX_BYTES = 240,
    sequence = 0,
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
    OBS_PRESSURE = true,
    RELAY_ASSIGN = true,
    RELAY_CONTROL = true,
    RELAY_ACTION = true,
}

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

local function unescape(value)
    if type(value) ~= "string" then return nil end
    if value:find("%%[^%x]", 1) or value:find("%%$", 1) then return nil end
    return value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
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
        "src=" .. escape(identity("player")),
        "body=" .. escape(body or ""),
    }
    local payload = table.concat(fields, "|")
    return #payload <= self.MAX_BYTES and payload or nil
end

function CommanderComm:Decode(payload)
    if type(payload) ~= "string" or #payload == 0 or #payload > self.MAX_BYTES then
        return nil, "size"
    end
    local values, count = {}, 0
    for field in payload:gmatch("[^|]+") do
        local key, value = field:match("^([a-z]+)=(.*)$")
        if not key or values[key] ~= nil then return nil, "shape" end
        values[key] = value
        count = count + 1
    end
    if count ~= 7 or values.v ~= self.VERSION or not ALLOWED_KIND[values.kind]
        or not values.sid or not values.seq:match("^%d+$")
        or not values.ts:match("^%d+$") or not values.src or values.body == nil then
        return nil, "schema"
    end
    local decoded = {
        version = values.v,
        session = unescape(values.sid),
        sequence = tonumber(values.seq),
        kind = values.kind,
        timestamp = tonumber(values.ts),
        source = unescape(values.src),
        body = unescape(values.body),
    }
    if not decoded.session or not decoded.source or decoded.body == nil
        or decoded.source == "" then
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

function CommanderComm:Send(kind, body, state)
    local distribution = self:Distribution(state)
    local payload = distribution and self:Encode(kind, body, state)
    if not payload or not C_ChatInfo or type(C_ChatInfo.SendAddonMessage) ~= "function" then
        return false
    end
    local ok = KWR.Util:Call(C_ChatInfo.SendAddonMessage, self.PREFIX, payload, distribution)
    if ok then self.diagnostics.sent = self.diagnostics.sent + 1 end
    return ok == true
end

function CommanderComm:Receive(prefix, payload, distribution, sender)
    if prefix ~= self.PREFIX
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
    if not KWR.SentinelRelay or not state then return end
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
