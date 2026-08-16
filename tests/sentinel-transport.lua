-- Deterministic KWRSync1 recipient-side transport coverage.  This runs the
-- real Sentinel Comm/Relay modules against a bounded ten-client roster model;
-- it never talks to the game network.

local clock = 100
local leaders = {}
local sent = {}
local registered = {}

local roster = {}
for index = 1, 10 do
    roster[index] = "Commander" .. index .. "-TestRealm"
end

function GetTime() return clock end
function IsInInstance() return true, "pvp" end
function GetInstanceInfo() return nil, nil, nil, nil, nil, nil, nil, 777 end
C_Map = { GetBestMapForUnit = function() return 123 end }
function IsInRaid() return true end
function IsInGroup() return true end
function GetNumGroupMembers() return #roster end
function GetNumSubgroupMembers() return 0 end
function UnitExists(unit) return unit == "player" or unit:match("^raid%d+$") ~= nil end
function UnitFullName(unit)
    if unit == "player" then return "Sentinel", "TestRealm" end
    local index = tonumber(unit:match("^raid(%d+)$"))
    if index and roster[index] then
        local name, realm = roster[index]:match("^([^%-]+)%-(.+)$")
        return name, realm
    end
    return nil
end
function UnitName(unit)
    local name = UnitFullName(unit)
    return name
end
function UnitIsGroupLeader(unit)
    return leaders[unit] == true
end

C_ChatInfo = {
    RegisterAddonMessagePrefix = function(prefix) registered[prefix] = true end,
    SendAddonMessage = function(prefix, payload, distribution)
        sent[#sent + 1] = { prefix = prefix, payload = payload, distribution = distribution }
        return 0
    end,
}
Enum = { SendAddonMessageResult = { Success = 0 } }

function CreateFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

local Sentinel = { modules = {}, transport = true, hudUpdates = 0 }
function Sentinel:RegisterModule(name, module) self.modules[name] = module end
function Sentinel:TransportEnabled() return self.transport end
Sentinel.HUD = { Update = function() Sentinel.hudUpdates = Sentinel.hudUpdates + 1 end }

local sentinelRoot = tostring(rawget(_G, "KWR_SENTINEL_TEST_ROOT") or "KWRSentinel"):gsub("\\", "/")
assert(loadfile(sentinelRoot .. "/Comm.lua"))("KWRSentinel", Sentinel)
assert(loadfile(sentinelRoot .. "/Relay.lua"))("KWRSentinel", Sentinel)

local Comm = assert(Sentinel.Comm)
local Relay = assert(Sentinel.Relay)
Comm:OnInitialize()
assert(registered.KWRSync1, "Sentinel transport did not register its KWRSync1 prefix")

local function setLeader(index)
    leaders = {}
    leaders["raid" .. index] = true
end

local function packet(kind, sequence, source, body, session, epoch)
    return table.concat({
        "v=2", "sid=" .. (session or Comm:SessionKey()), "seq=" .. tostring(sequence),
        "kind=" .. kind, "ts=" .. tostring(math.floor(clock)), "ep=" .. (epoch or "epoch"),
        "src=" .. source, "body=" .. body,
    }, "|")
end

local function relayBody(kind)
    if kind == "RELAY_ASSIGN" then return "to=Sentinel-TestRealm;role=Anchor;where=Farm;move=Hold" end
    if kind == "RELAY_CONTROL" then return "to=Sentinel-TestRealm;target=Enemy;mode=watch;fixed=1" end
    return "to=Sentinel-TestRealm;action=press;when=now;sig=focus" 
end

-- Ten possible Commander clients take leadership one at a time.  A legitimate
-- relay is accepted from each, then the old authority is rejected.  The cache
-- must remain bounded to the current authority only.
for index = 1, 10 do
    setLeader(index)
    local sender = roster[index]
    local kind = ({ "RELAY_ASSIGN", "RELAY_CONTROL", "RELAY_ACTION" })[((index - 1) % 3) + 1]
    assert(Comm:Receive("KWRSync1", packet(kind, index, sender, relayBody(kind), nil, "epoch" .. index), "INSTANCE_CHAT", sender),
        "valid relay from leader " .. index .. " was rejected")
    local count = 0
    for _ in pairs(Comm.relaySequence) do count = count + 1 end
    assert(count == 1 and Comm.relayAuthority == sender:lower(), "relay authority cache must stay bounded after leader rotation")
    if index > 1 then
        local prior = roster[index - 1]
        assert(not Comm:Receive("KWRSync1", packet("RELAY_ASSIGN", 99, prior, relayBody("RELAY_ASSIGN")), "INSTANCE_CHAT", prior),
            "former commander remained trusted after leadership changed")
    end
end

setLeader(10)
local commander = roster[10]
assert(not Comm:Receive("KWRSync1", packet("RELAY_ASSIGN", 10, commander, relayBody("RELAY_ASSIGN"), "wrong-session"), "INSTANCE_CHAT", commander),
    "wrong session relay was accepted")
assert(not Comm:Receive("KWRSync1", packet("RELAY_ASSIGN", 10, "Forged-TestRealm", relayBody("RELAY_ASSIGN")), "INSTANCE_CHAT", commander),
    "sender/source mismatch relay was accepted")
assert(not Comm:Receive("KWRSync1", "v=2|sid=pvp-123-777|seq=1|kind=RELAY_ASSIGN", "INSTANCE_CHAT", commander),
    "malformed relay was accepted")
assert(not Comm:Receive("KWRSync1", packet("RELAY_ASSIGN", 10, commander, relayBody("RELAY_ASSIGN"), nil, "epoch10"), "INSTANCE_CHAT", commander),
    "duplicate relay sequence was accepted")
assert(not Comm:Receive("KWRSync1", packet("RELAY_ASSIGN", 11, commander, "to=Sentinel-TestRealm;role=;where=Farm;move=Hold", nil, "epoch10"), "INSTANCE_CHAT", commander),
    "invalid relay body was accepted")

-- Relay facts have explicit expiries and never survive a stale UI refresh.
assert(Relay:View(), "accepted relay did not produce a recipient view")
assert(Relay:Status().state == "REMOTE LIVE", "live relay status was not reported")
clock = clock + 13
assert(Relay:View() == nil, "expired relay remained visible")
assert(Relay:Status().state == "REMOTE STALE", "expired relay did not enter stale state")
Relay:Clear()
assert(Relay:View() == nil and Relay:Status().state == "NO REMOTE",
    "relay clear did not immediately remove cached remote state")

-- Outbound sends are bounded by kind-specific limits even during rapid refresh.
clock = clock + 1
assert(Comm:Send("STATE", "x=1"), "first state observation was not sent")
assert(not Comm:Send("STATE", "x=2"), "rate-limited state observation was sent")
assert(#sent == 1 and sent[1].distribution == "INSTANCE_CHAT", "outbound transport used an unexpected route")

-- A protected API rejection must not consume the per-family send budget.
C_ChatInfo.SendAddonMessage = function() return 1 end
clock = clock + 1
assert(not Comm:Send("HELLO", "x=1"), "failed addon-message result was recorded as sent")
assert(Comm.sentAt.HELLO == nil, "failed addon-message result advanced the family throttle")

-- Secret values must fail closed before serialization or transport. This
-- fixture marks opaque tables as protected without relying on Retail APIs.
local secret = {}
issecretvalue = function(value) return value == secret end
local protectedBefore = Comm.diagnostics.protected or 0
assert(Comm:Encode("STATE", secret) == nil,
    "secret observer body was serialized")
local oldMapForUnit = C_Map.GetBestMapForUnit
C_Map.GetBestMapForUnit = function() return secret end
assert(Comm:Encode("STATE", "x=1") == nil,
    "secret battleground session identifier was serialized")
C_Map.GetBestMapForUnit = oldMapForUnit
local oldFullName = UnitFullName
UnitFullName = function(unit)
    if unit == "player" then return secret, nil end
    return oldFullName(unit)
end
assert(Comm:Encode("STATE", "x=1") == nil,
    "secret player identity was serialized")
UnitFullName = oldFullName
assert((Comm.diagnostics.protected or 0) == protectedBefore + 3,
    "secret transport rejections were not diagnosed")
issecretvalue = nil

print("KWR_SENTINEL_TRANSPORT_PASS accepted=" .. tostring(Comm.diagnostics.received)
    .. " rejected=" .. tostring(Comm.diagnostics.rejected)
    .. " hud=" .. tostring(Sentinel.hudUpdates))
