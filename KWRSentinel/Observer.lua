local _, Sentinel = ...

local Observer = { lastState = "", lastVisible = "", lastCast = "" }
Sentinel.Observer = Observer

local function safeText(value, fallback, maximum)
    local ok, result = pcall(function()
        if type(issecretvalue) == "function" and issecretvalue(value) then
            return fallback or ""
        end
        local text = tostring(value or "")
        return text:sub(1, maximum or 64)
    end)
    return ok and result or (fallback or "")
end

local function clean(value, maximum)
    local value = safeText(value, "", maximum)
    return value:gsub("[^%w%._%-]", "_"):sub(1, maximum or 64)
end

local function encode(value, maximum)
    value = safeText(value, "", maximum)
    return (value:gsub("[^%w%._%-]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function unitIdentity(unit)
    local ok, identity = pcall(function()
        if type(UnitFullName) == "function" then
            local name, realm = UnitFullName(unit)
            name = safeText(name)
            realm = safeText(realm)
            if name ~= "" then
                return realm ~= "" and (name .. "-" .. realm) or name
            end
        end
        local name, realm = UnitName(unit)
        name = safeText(name)
        realm = safeText(realm)
        return name ~= "" and (realm ~= "" and (name .. "-" .. realm) or name) or nil
    end)
    return ok and identity or nil
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
    -- A protected cast can be returned as a secret value. Do not branch on
    -- or serialize it; skip only this sample and keep later public samples.
    if type(issecretvalue) == "function" and issecretvalue(spellID) then return nil end
    if not spellID then _, _, _, _, _, _, _, spellID = UnitChannelInfo("target") end
    if type(issecretvalue) == "function" and issecretvalue(spellID) then return nil end
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
    -- Retail can mark unit aura collections secret before addon code sees an
    -- individual aura. Calling GetAuraDataByIndex in that state taints the
    -- caller and produces a protected-action error; checking the returned
    -- value cannot make the call safe. Carrier truth must therefore come from
    -- an explicitly supported objective source, never from aura enumeration.
    -- Keep this no-op entry point for compatibility with any future legal
    -- source, but do not touch the protected unit/aura APIs here.
    return false
end

function Observer:OnInitialize()
    self.frame = CreateFrame("Frame", "KWRSentinel_ObserverFrame")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.frame:SetScript("OnEvent", function()
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
