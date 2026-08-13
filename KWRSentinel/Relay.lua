local _, Sentinel = ...

local Relay = { state = {}, receivedAt = 0 }
Sentinel.Relay = Relay

local function canonical(value)
    return tostring(value or ""):lower()
end

local function identity(unit)
    if type(UnitFullName) == "function" then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            return realm and realm ~= "" and (name .. "-" .. realm) or name
        end
    end
    return type(UnitName) == "function" and UnitName(unit) or ""
end

local function unescape(value)
    if type(value) ~= "string" or value:find("%%[^%x]", 1) or value:find("%%$", 1) then return nil end
    return value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
end

local function parse(body)
    local result = {}
    for field in tostring(body or ""):gmatch("[^;]+") do
        local key, value = field:match("^([a-z_]+)=(.*)$")
        if not key or result[key] then return nil end
        value = unescape(value)
        if value == nil then return nil end
        result[key] = value
    end
    return result
end

local REQUIRED = {
    RELAY_ASSIGN = { to = true, role = true, where = true, move = true },
    RELAY_CONTROL = { to = true, target = true, mode = true, fixed = true },
    RELAY_ACTION = { to = true, action = true, when = true, sig = true },
}

local function valid(kind, body)
    local required = REQUIRED[kind]
    if not required then return false end
    local count, expected = 0, 0
    for key, value in pairs(body) do
        if not required[key] or value == "" then return false end
        count = count + 1
    end
    for key in pairs(required) do
        if body[key] == nil then return false end
        expected = expected + 1
    end
    return count == expected and (kind ~= "RELAY_CONTROL" or body.fixed == "0" or body.fixed == "1")
end

function Relay:Accept(packet)
    local body = parse(packet.body)
    if not body or not valid(packet.kind, body)
        or canonical(body.to) ~= canonical(identity("player")) then return false end
    self.state[packet.kind] = { body = body, at = GetTime and GetTime() or 0 }
    self.receivedAt = GetTime and GetTime() or 0
    if Sentinel.HUD then Sentinel.HUD:Update() end
    return true
end

function Relay:Clear()
    self.state = {}
    self.receivedAt = 0
end

function Relay:View()
    local now = GetTime and GetTime() or 0
    local assign = self.state.RELAY_ASSIGN
    local control = self.state.RELAY_CONTROL
    local action = self.state.RELAY_ACTION
    if action and now - action.at > 12 then action = nil; self.state.RELAY_ACTION = nil end
    if assign and now - assign.at > 10 then assign = nil; self.state.RELAY_ASSIGN = nil end
    if control and now - control.at > 10 then control = nil; self.state.RELAY_CONTROL = nil end
    if not assign and not control and not action then return nil end
    local view = { trustState = "REMOTE COMMANDER", source = "REMOTE_KWR" }
    if assign then
        view.assignment = { role = assign.body.role, location = assign.body.where, movement = assign.body.move }
    end
    if control then
        view.watch = { name = control.body.target, mode = control.body.mode }
    end
    if action then
        view.command = { action = action.body.action, when = action.body.when }
    end
    return view
end

function Relay:Status()
    local now = GetTime and GetTime() or 0
    local view = self:View()
    local age = self.receivedAt > 0 and math.max(0, now - self.receivedAt) or nil
    return {
        connected = view ~= nil,
        state = view and "REMOTE LIVE" or (self.receivedAt > 0 and "REMOTE STALE" or "NO REMOTE"),
        age = age,
        expiresIn = view and math.max(0, 10 - (age or 0)) or 0,
    }
end

Sentinel:RegisterModule("Relay", Relay)
