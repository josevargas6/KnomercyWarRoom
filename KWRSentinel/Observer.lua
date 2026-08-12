local _, Sentinel = ...

local Observer = { lastState = "", lastVisible = "", lastCast = "" }
Sentinel.Observer = Observer

local function clean(value, maximum)
    return tostring(value or ""):gsub("[^%w%._%-]", "_"):sub(1, maximum or 64)
end

local function encode(value, maximum)
    value = tostring(value or ""):sub(1, maximum or 64)
    return (value:gsub("[^%w%._%-]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function targetObservation()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return nil end
    local name = encode(UnitName("target"), 64)
    if name == "" then return nil end
    local visible = UnitIsVisible and UnitIsVisible("target") and "1" or "0"
    -- Retail can protect range checks. Commander already treats reach as
    -- evidence-limited, so preserve that truth rather than poll a protected
    -- API every observer tick.
    return "enemy=" .. name .. ";visible=" .. visible .. ";range=UNKNOWN;engaged=0"
end

local function castObservation()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return nil end
    local name = UnitCastingInfo("target")
    if not name then name = UnitChannelInfo("target") end
    if not name then return nil end
    return "enemy=" .. encode(UnitName("target"), 64) .. ";spell=" .. encode(name, 64) .. ";state=START"
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
    if visible then
        Sentinel.Comm:Send("OBS_PRESSURE", "friendly=UNKNOWN;enemy=UNKNOWN;healer=UNKNOWN;state=WATCH;target=LOCAL")
    end
end

function Observer:ObserveCarrier(name, kind, label, source)
    if not Sentinel.Comm then return false end
    return Sentinel.Comm:Send("OBS_CARRIER", "carrier=" .. encode(name, 64)
        .. ";kind=" .. clean(kind, 16) .. ";label=" .. clean(label, 32)
        .. ";source=" .. clean(source, 24))
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
