local _, KWR = ...

local SentinelIngress = {
    byPlayer = {}, byEnemy = {}, byObjective = {}, lastSeqBySender = {},
    diagnostics = { accepted = 0, duplicate = 0, malformed = 0, throttled = 0 },
}
KWR.SentinelIngress = SentinelIngress

local LIMITS = { HELLO = 20, STATE = 2, OBS_VISIBLE = 1, OBS_CAST = 0.2, OBS_CARRIER = 1, OBS_PRESSURE = 2 }

local function text(value, maximum)
    return KWR.Util:Text(value, "", maximum or 64)
end

local function parseBody(body)
    local result, count = {}, 0
    for field in tostring(body or ""):gmatch("[^;]+") do
        local key, value = field:match("^([a-z_]+)=([%w%._%-]+)$")
        if not key or result[key] ~= nil then return nil end
        result[key] = value
        count = count + 1
    end
    return count > 0 and result or nil
end

function SentinelIngress:Accept(packet, sender, state)
    local body = parseBody(packet.body)
    if not body or not LIMITS[packet.kind] then
        self.diagnostics.malformed = self.diagnostics.malformed + 1
        return false
    end
    local key = KWR.Util:ShortName(sender):lower()
    local previous = self.lastSeqBySender[key] or 0
    if packet.sequence <= previous then
        self.diagnostics.duplicate = self.diagnostics.duplicate + 1
        return false
    end
    local record = self.byPlayer[key] or { packets = {} }
    local lastAt = record.packets[packet.kind] or 0
    if KWR.Util:Now() - lastAt < LIMITS[packet.kind] then
        self.diagnostics.throttled = self.diagnostics.throttled + 1
        return false
    end
    record.name = KWR.Util:ShortName(sender)
    record.updatedAt = KWR.Util:Now()
    record.packets[packet.kind] = record.updatedAt
    record[packet.kind] = { body = body, at = record.updatedAt }
    self.byPlayer[key] = record
    self.lastSeqBySender[key] = packet.sequence
    local enemy = text(body.enemy or body.carrier, 64)
    if enemy ~= "" and packet.kind:find("^OBS_") then
        self.byEnemy[enemy:lower()] = { body = body, kind = packet.kind, at = record.updatedAt, sender = key }
    end
    self.diagnostics.accepted = self.diagnostics.accepted + 1
    return true
end

function SentinelIngress:Expire()
    local now = KWR.Util:Now()
    for key, record in pairs(self.byPlayer) do
        if now - (record.updatedAt or 0) > 10 then self.byPlayer[key] = nil end
    end
    for key, record in pairs(self.byEnemy) do
        if now - (record.at or 0) > 3 then self.byEnemy[key] = nil end
    end
end

function SentinelIngress:Reset()
    self.byPlayer, self.byEnemy, self.byObjective, self.lastSeqBySender = {}, {}, {}, {}
end

KWR:RegisterModule("SentinelIngress", SentinelIngress)
