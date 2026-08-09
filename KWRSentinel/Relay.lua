local _, Sentinel = ...

local Relay = { state = {}, receivedAt = 0 }
Sentinel.Relay = Relay

local function shortName(value)
    value = tostring(value or "")
    local dash = value:find("-", 1, true)
    return (dash and value:sub(1, dash - 1) or value):lower()
end

local function parse(body)
    local result = {}
    for field in tostring(body or ""):gmatch("[^;]+") do
        local key, value = field:match("^([a-z_]+)=([%w%._%-]+)$")
        if not key or result[key] then return nil end
        result[key] = value
    end
    return result.to and result or nil
end

function Relay:Accept(packet)
    local body = parse(packet.body)
    if not body or shortName(body.to) ~= shortName(UnitName and UnitName("player")) then return false end
    self.state[packet.kind] = { body = body, at = GetTime and GetTime() or 0 }
    self.receivedAt = GetTime and GetTime() or 0
    if Sentinel.HUD then Sentinel.HUD:Update() end
    return true
end

function Relay:View()
    local now = GetTime and GetTime() or 0
    local assign = self.state.RELAY_ASSIGN
    local control = self.state.RELAY_CONTROL
    local action = self.state.RELAY_ACTION
    if action and now - action.at > 5 then action = nil; self.state.RELAY_ACTION = nil end
    if assign and now - assign.at > 10 then assign = nil; self.state.RELAY_ASSIGN = nil end
    if control and now - control.at > 10 then control = nil; self.state.RELAY_CONTROL = nil end
    if not assign and not control and not action then return nil end
    return { assignment = assign and { role = assign.body.role, location = assign.body.where, movement = assign.body.move } or {},
        watch = control and { name = control.body.target, mode = control.body.mode } or {},
        command = action and { action = action.body.action, when = action.body.when } or {},
        trustState = "REMOTE COMMANDER", source = "REMOTE_KWR" }
end

Sentinel:RegisterModule("Relay", Relay)
