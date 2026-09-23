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
local driverRoot = tostring(rawget(_G, "KWR_TEST_DRIVER_ROOT") or "tests"):gsub("\\", "/")
local checkEnvelope = assert(loadfile(driverRoot .. "/fixtures/sync_envelope.lua"))()
assert(checkEnvelope(Comm) >= 300, "Sentinel parser vectors did not run")
Comm:OnInitialize()
-- Exercise the actual HUD formatter without creating any WoW frames. Its
-- local formatter is an upvalue, so no test-only runtime API is needed.
assert(loadfile(sentinelRoot .. "/HUD.lua"))("KWRSentinel", Sentinel)
local scoreHeadline
for index = 1, 40 do
    local name, fn = debug.getupvalue(Sentinel.HUD.Update, index)
    if not name then break end
    if name == "scoreHeadline" then scoreHeadline = fn end
end
assert(scoreHeadline, "Sentinel score formatter was not exercised.")
assert(scoreHeadline({mode="LIVE",score={known=false,friendly=0,enemy=0,status="WINNING"}}):find("UNKNOWN | UNKNOWN",1,true),
    "Unknown score retained a stale win/tie badge.")
assert(scoreHeadline({mode="LIVE",score={known=true,friendly=0,enemy=0,status="WAITING"}}):find("0 - 0 | TIED",1,true),
    "Observed zero-zero score lost its valid tie presentation.")
Sentinel.HUD = { Update = function() Sentinel.hudUpdates = Sentinel.hudUpdates + 1 end }
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

local oldIsInInstance = IsInInstance
IsInInstance = function() error("protected instance context") end
assert(Comm:SessionKey() == nil and Comm:Distribution() == nil,
    "errored instance context did not fail closed")
local sentBeforeUnknownContext = #sent
clock = clock + 100
assert(not Comm:Send("STATE", "x=1") and #sent == sentBeforeUnknownContext,
    "errored instance context reached addon transport")
IsInInstance = function() return secret, "pvp" end
assert(Comm:SessionKey() == nil and Comm:Distribution() == nil,
    "secret instance context did not fail closed")
IsInInstance = oldIsInInstance
issecretvalue = nil

-- Every Sentinel drag completion must defer the protected Retail stop call
-- until combat has ended. This is intentionally tested at the shared Core
-- gate rather than one particular frame so HUD, options, and helper panels
-- cannot regress independently.
do
    local oldSentinel = rawget(_G, "Sentinel")
    local oldLockdown = rawget(_G, "InCombatLockdown")
    local oldSlashCmdList = rawget(_G, "SlashCmdList")
    local uiSentinel = { modules = {}, moduleOrder = {} }
    function uiSentinel:RegisterModule(name, module)
        self.modules[name] = module
        self.moduleOrder[#self.moduleOrder + 1] = name
    end
    local locked = true
    InCombatLockdown = function() return locked end
    SlashCmdList = {}
    assert(loadfile(sentinelRoot .. "/Core.lua"))("KWRSentinel", uiSentinel)
    local stopCalls, completed = 0, 0
    local frame = {
        StopMovingOrSizing = function() stopCalls = stopCalls + 1 end,
    }
    assert(not uiSentinel:FinishMove(frame, function() completed = completed + 1 end)
        and stopCalls == 0 and completed == 0,
        "Sentinel called protected StopMovingOrSizing during combat lockdown")
    locked = false
    uiSentinel:FlushPendingMoveStops()
    assert(stopCalls == 1 and completed == 1,
        "Sentinel did not complete the deferred drag after combat")
    _G.Sentinel = oldSentinel
    InCombatLockdown = oldLockdown
    SlashCmdList = oldSlashCmdList
end

do
    assert(loadfile(sentinelRoot .. "/Observer.lua"))("KWRSentinel", Sentinel)
    local observer = assert(Sentinel.Observer)
    local saved, names = {}, { "UnitExists", "UnitCanAttack", "UnitFullName", "UnitIsVisible",
        "UnitClass", "UnitCastingInfo", "UnitChannelInfo", "issecretvalue" }
    for _, name in ipairs(names) do saved[name] = rawget(_G, name) end
    local send = Comm.Send
    local castBody, castSends, channelCalls = nil, 0, 0
    Comm.Send = function(_, kind, body)
        if kind == "OBS_CAST" then castBody, castSends = body, castSends + 1 end
        return true
    end
    UnitExists = function() return true end
    UnitCanAttack = function() return true end
    UnitFullName = function(unit) return unit == "target" and "Enemy" or "Sentinel", "Realm" end
    UnitIsVisible = function() return true end
    UnitClass = function() return "Mage", "MAGE" end
    local opaque = setmetatable({}, { __tostring = function() error("secret serialized") end })
    issecretvalue = function(value) return rawequal(value, opaque) end
    UnitChannelInfo = function() channelCalls = channelCalls + 1 end
    for _, interruptible in ipairs({ false, true, opaque }) do
        UnitCastingInfo = function()
            return "Cast", nil, nil, nil, nil, nil, "cast-guid", interruptible, 118
        end
        castBody = nil
        observer:Tick()
        assert(castBody == "enemy=Enemy%2DRealm;spell=118;state=START"
            or castBody == "enemy=Enemy-Realm;spell=118;state=START",
            "Casting observation did not use return nine independently of interruptibility")
    end
    assert(channelCalls == 0, "Valid casting spell unexpectedly read channel data")
    UnitCastingInfo = function() return nil end
    UnitChannelInfo = function()
        channelCalls = channelCalls + 1
        return "Channel", nil, nil, nil, nil, nil, false, 15407
    end
    castBody = nil
    observer:Tick()
    assert(castBody and castBody:find("spell=15407", 1, true), "Channel spell did not use return eight")
    UnitCastingInfo = nil
    castBody = nil
    observer:Tick()
    assert(castBody and castBody:find("spell=15407", 1, true), "Missing casting API blocked public channel fallback")

    local function noCast(message)
        local before = castSends
        observer:Tick()
        assert(castSends == before and observer.lastCast == "", message)
    end
    UnitChannelInfo = nil
    noCast("Missing cast APIs emitted an observation")
    UnitCastingInfo = function() error("cast API unavailable in this context") end
    local errors = observer.castReadErrors
    noCast("Throwing casting API emitted an observation")
    assert(observer.castReadErrors == errors + 1, "Cast API failure was not diagnosed")
    UnitCastingInfo = function() return nil end
    UnitChannelInfo = function() error("channel unavailable") end
    noCast("Throwing channel API emitted an observation")
    UnitChannelInfo = function() return nil end
    for _, spellID in ipairs({ false, 0, -1, 1.5, math.huge, 0 / 0, "118" }) do
        UnitCastingInfo = function() return nil, nil, nil, nil, nil, nil, nil, false, spellID end
        noCast("Invalid casting spell ID emitted an observation")
    end
    local protected = observer.protectedCastSamples
    UnitCastingInfo = function() return nil, nil, nil, nil, nil, nil, nil, false, opaque end
    UnitChannelInfo = function() error("must not fall back from a secret cast") end
    errors = observer.castReadErrors
    noCast("Secret casting spell was serialized")
    assert(observer.castReadErrors == errors, "Secret cast fell back to another API")
    UnitCastingInfo = function() return nil end
    UnitChannelInfo = function() return nil, nil, nil, nil, nil, nil, false, opaque end
    noCast("Secret channel spell was serialized")
    assert(observer.protectedCastSamples == protected + 2, "Protected samples were not diagnosed")
    UnitCastingInfo = function() return nil, nil, nil, nil, nil, nil, nil, false, 118 end
    castBody = nil
    observer:Tick()
    assert(castBody and castBody:find("spell=118", 1, true), "Public casts did not recover after rejected samples")
    Sentinel.transport = false
    local before = castSends
    observer:Tick()
    assert(castSends == before, "Disabled transport still emitted a cast observation")
    Sentinel.transport = true
    Comm.Send = send
    for _, name in ipairs(names) do _G[name] = saved[name] end
end

print("KWR_SENTINEL_TRANSPORT_PASS accepted=" .. tostring(Comm.diagnostics.received)
    .. " rejected=" .. tostring(Comm.diagnostics.rejected)
    .. " hud=" .. tostring(Sentinel.hudUpdates))
