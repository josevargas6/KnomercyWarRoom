local _, KWR = ...

local SentinelIngress = {
    byPlayer = {}, byEnemy = {}, byObjective = {}, lastSeqBySender = {},
    diagnostics = { accepted = 0, duplicate = 0, malformed = 0, throttled = 0 },
}
KWR.SentinelIngress = SentinelIngress

local LIMITS = { HELLO = 20, STATE = 2, OBS_VISIBLE = 1, OBS_CAST = 0.2, OBS_CARRIER = 1 }

local function text(value, maximum)
    return KWR.Util:Text(value, "", maximum or 64)
end

local function senderKey(value)
    return text(value, 96):lower()
end

local function unescape(value)
    if type(value) ~= "string" or value:find("%%[^%x]", 1) or value:find("%%$", 1) then return nil end
    return value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

local function parseBody(body)
    local result, count = {}, 0
    for field in tostring(body or ""):gmatch("[^;]+") do
        local key, value = field:match("^([a-z_]+)=([%w%._%%%-]+)$")
        if not key or result[key] ~= nil then return nil end
        value = unescape(value)
        if value == nil then return nil end
        result[key] = value
        count = count + 1
    end
    return count > 0 and result or nil
end

local REQUIRED = {
    HELLO = { addon = true, class = true, role = true, caps = true, epoch = true },
    STATE = { alive = true, connected = true, reach = true },
    OBS_VISIBLE = { enemy = true, visible = true, range = true, engaged = true },
    OBS_CAST = { enemy = true, spell = true, state = true },
    OBS_CARRIER = { carrier = true, kind = true, label = true, source = true },
}

local function validBoolean(value)
    return value == "0" or value == "1"
end

local function validBody(kind, body)
    local required = REQUIRED[kind]
    if not required then return false end
    local count = 0
    for key, value in pairs(body) do
        if not required[key] or value == "" then return false end
        count = count + 1
    end
    local expected = 0
    for key in pairs(required) do
        if body[key] == nil then return false end
        expected = expected + 1
    end
    if count ~= expected then return false end
    if kind == "STATE" then
        return validBoolean(body.alive) and validBoolean(body.connected)
    end
    if kind == "OBS_VISIBLE" then
        return validBoolean(body.visible) and validBoolean(body.engaged)
    end
    if kind == "OBS_CAST" then return body.state == "START" end
    return true
end

function SentinelIngress:Accept(packet, sender, state)
    local body = parseBody(packet.body)
    if not body or not LIMITS[packet.kind] or not validBody(packet.kind, body) then
        self.diagnostics.malformed = self.diagnostics.malformed + 1
        return false
    end
    local key = senderKey(sender)
    local record = self.byPlayer[key] or { packets = {} }
    local helloEpoch = packet.kind == "HELLO" and text(body.epoch, 32) or ""
    if helloEpoch ~= "" and helloEpoch ~= record.epoch then
        record.packets = {}
        self.lastSeqBySender[key] = 0
        record.epoch = helloEpoch
    end
    local previous = self.lastSeqBySender[key] or 0
    if packet.sequence <= previous then
        self.diagnostics.duplicate = self.diagnostics.duplicate + 1
        return false
    end
    local lastAt = record.packets[packet.kind]
    if lastAt and KWR.Util:Now() - lastAt < LIMITS[packet.kind] then
        self.diagnostics.throttled = self.diagnostics.throttled + 1
        return false
    end
    record.name = text(sender, 96)
    record.updatedAt = KWR.Util:Now()
    record.packets[packet.kind] = record.updatedAt
    record[packet.kind] = { body = body, at = record.updatedAt }
    self.byPlayer[key] = record
    self.lastSeqBySender[key] = packet.sequence
    local enemy = text(body.enemy or body.carrier, 64)
    if enemy ~= "" and packet.kind:find("^OBS_") then
        -- Preserve each observation family and reporter independently. A
        -- target scan can publish visibility and a cast in the same tick;
        -- neither may overwrite the other before the merge consumes them.
        local enemyKey = enemy:lower()
        self.byEnemy[enemyKey] = self.byEnemy[enemyKey] or {}
        self.byEnemy[enemyKey][packet.kind] = self.byEnemy[enemyKey][packet.kind] or {}
        self.byEnemy[enemyKey][packet.kind][key] = {
            body = body, kind = packet.kind, at = record.updatedAt, sender = key,
        }
    end
    self.diagnostics.accepted = self.diagnostics.accepted + 1
    return true
end

function SentinelIngress:Expire()
    local now = KWR.Util:Now()
    for key, record in pairs(self.byPlayer) do
        if now - (record.updatedAt or 0) > 10 then self.byPlayer[key] = nil end
    end
    for enemyKey, families in pairs(self.byEnemy) do
        for kind, senders in pairs(families) do
            for sender, record in pairs(senders) do
                if now - (record.at or 0) > 3 then senders[sender] = nil end
            end
            if not next(senders) then families[kind] = nil end
        end
        if not next(families) then self.byEnemy[enemyKey] = nil end
    end
end

function SentinelIngress:Reset()
    self.byPlayer, self.byEnemy, self.byObjective, self.lastSeqBySender = {}, {}, {}, {}
end

KWR:RegisterModule("SentinelIngress", SentinelIngress)
