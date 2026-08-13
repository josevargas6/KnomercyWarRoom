local _, Sentinel = ...

local Observer = { lastState = "", lastVisible = "", lastCast = "" }
Sentinel.Observer = Observer

-- Retail objective auras are stable spell identifiers.  We intentionally use
-- IDs rather than localized aura names and emit only an observed carrier.
local CARRIER_AURAS = {
    [23333] = { kind = "FLAG", label = "Alliance Flag" },
    [23335] = { kind = "FLAG", label = "Horde Flag" },
    [34976] = { kind = "FLAG", label = "Netherstorm Flag" },
    [121164] = { kind = "ORB", label = "Blue Orb" },
    [121175] = { kind = "ORB", label = "Green Orb" },
    [121176] = { kind = "ORB", label = "Orange Orb" },
    [121177] = { kind = "ORB", label = "Purple Orb" },
}

local function clean(value, maximum)
    return tostring(value or ""):gsub("[^%w%._%-]", "_"):sub(1, maximum or 64)
end

local function encode(value, maximum)
    value = tostring(value or ""):sub(1, maximum or 64)
    return (value:gsub("[^%w%._%-]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function unitIdentity(unit)
    if type(UnitFullName) == "function" then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            return realm and realm ~= "" and (name .. "-" .. realm) or name
        end
    end
    local name, realm = UnitName(unit)
    return name and realm and realm ~= "" and (name .. "-" .. realm) or name
end

local function targetObservation()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return nil end
    local name = encode(unitIdentity("target"), 64)
    if name == "" then return nil end
    local visible = UnitIsVisible and UnitIsVisible("target") and "1" or "0"
    -- Retail can protect range checks. Commander already treats reach as
    -- evidence-limited, so preserve that truth rather than poll a protected
    -- API every observer tick.
    return "enemy=" .. name .. ";visible=" .. visible .. ";range=UNKNOWN;engaged=0"
end

local function castObservation()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return nil end
    local _, _, _, _, _, _, _, spellID = UnitCastingInfo("target")
    if not spellID then _, _, _, _, _, _, _, spellID = UnitChannelInfo("target") end
    if not tonumber(spellID) then return nil end
    return "enemy=" .. encode(unitIdentity("target"), 64) .. ";spell=" .. tostring(spellID) .. ";state=START"
end

function Observer:SendHello()
    if not Sentinel:TransportEnabled() then return false end
    local _, class = UnitClass("player")
    Sentinel.Comm:Send("HELLO", "addon=" .. clean(Sentinel.version, 24)
        .. ";class=" .. clean(class, 24) .. ";role=UNKNOWN;caps=1;epoch="
        .. clean(Sentinel.Comm.epoch, 32))
end

function Observer:Tick()
    -- Outside an instance/group channel no observation can be delivered.
    -- Skip the target/cast scans entirely instead of doing recurring work
    -- that Comm will discard.
    if not Sentinel:TransportEnabled() or not Sentinel.Comm or not Sentinel.Comm:Distribution() then return end
    -- Commander may reload without the remote client receiving a roster event.
    -- Comm's HELLO throttle keeps this bounded while restoring its handshake.
    self:SendHello()
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") == true
    local state = "alive=" .. (dead and "0" or "1") .. ";connected=1;reach=UNKNOWN"
    Sentinel.Comm:Send("STATE", state)
    self.lastState = state
    local visible = targetObservation()
    if visible then Sentinel.Comm:Send("OBS_VISIBLE", visible) end
    self.lastVisible = visible or ""
    local cast = castObservation()
    if cast then Sentinel.Comm:Send("OBS_CAST", cast) end
    self.lastCast = cast or ""
    -- OBS_PRESSURE remains disabled until a measured local-fight collector
    -- exists; never publish fabricated pressure into Commander truth.
end

function Observer:ObserveCarrier(name, kind, label, source)
    if not Sentinel.Comm then return false end
    return Sentinel.Comm:Send("OBS_CARRIER", "carrier=" .. encode(name, 64)
        .. ";kind=" .. clean(kind, 16) .. ";label=" .. clean(label, 32)
        .. ";source=" .. clean(source, 24))
end

function Observer:ObserveCarrierUnit(unit, source)
    if not Sentinel:TransportEnabled() or not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
    local identity = unitIdentity(unit)
    if not identity then return false end
    for index = 1, 40 do
        local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
            and C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL") or nil
        if not aura then break end
        local carrier = CARRIER_AURAS[aura.spellId]
        if carrier then
            return self:ObserveCarrier(identity, carrier.kind, carrier.label, source or "UNIT_AURA")
        end
    end
    return false
end

function Observer:OnInitialize()
    self.frame = CreateFrame("Frame", "KWRSentinel_ObserverFrame")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.frame:RegisterEvent("UNIT_AURA")
    self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.frame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" or event == "NAME_PLATE_UNIT_ADDED" then
            Observer:ObserveCarrierUnit(unit, event)
            return
        end
        Observer:SendHello()
    end)
end

function Observer:OnEnable()
    self:SendHello()
    self.ticker = C_Timer and C_Timer.NewTicker and C_Timer.NewTicker(2, function()
        Observer:Tick()
    end) or nil
end

function Observer:OnDisable()
    if self.ticker then self.ticker:Cancel() end
    self.ticker = nil
end

Sentinel:RegisterModule("Observer", Observer)
