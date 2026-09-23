-- Exercise the built companion, with ordinary API mocks and real module code.
unpack = unpack or table.unpack
local companionRoot = assert(arg[1], "Companion staging root required")
local commanderRoot = assert(arg[2], "Commander root required")
local expectedVersion = assert(arg[3], "Expected Commander version required")
local KWR = { version = expectedVersion, modules = {}, db = { profile = {} } }
_G.KWR = KWR
local subscriptions, subscribeCalls, bindCalls = {}, 0, 0
local combat, loaderMode, loaderCalls = false, "missing", 0
function GetTime() return 100 end
function InCombatLockdown() return combat end
function KWR:RegisterModule(name, module) self.modules[name] = module end
function KWR:GetModule(name) return self.modules[name] end
function KWR:CallModule(module, method)
    if type(module[method]) ~= "function" then return true end
    return pcall(module[method], module)
end
KWR.Store = {
    Subscribe = function(_, owner, callback)
        subscribeCalls = subscribeCalls + 1
        subscriptions[owner] = callback
    end,
    Unsubscribe = function(_, owner) subscriptions[owner] = nil end,
}
KWR.MemoryBudget = { Bind = function() bindCalls = bindCalls + 1 end }
local function loadCommander(path)
    assert(loadfile(commanderRoot .. "/" .. path))("KnomercyWarRoom", KWR)
end
loadCommander("Core/Util.lua")
loadCommander("Core/BuildInfo.lua")
loadCommander("Runtime/TruthContract.lua")
local contract = KWR.Verification.Contract
assert(KWR.BuildInfo:SetDevelopmentMode(false) == true and KWR.Verification.ledger == nil,
    "Disabling absent developer tools created a production capture ledger")
assert(KWR.Verification:Contract({}).aggressiveCommitAllowed == false,
    "Production truth gate must reject absent evidence without developer tools")

local function loadCompanion()
    for _, file in ipairs({ "DevBootstrap", "Diagnostics", "Preview", "Verification", "Season2Readiness", "DevActivate" }) do
        assert(loadfile(companionRoot .. "/" .. file .. ".lua"))("KWR_DevTools", {})
    end
end
C_AddOns = { LoadAddOn = function(name)
    assert(name == "KWR_DevTools", "Loader requested an unexpected addon")
    loaderCalls = loaderCalls + 1
    if loaderMode == "throw" then error("loader failure") end
    if loaderMode == "missing" then return nil, "MISSING" end
    loadCompanion()
    if loaderMode == "mismatch" then KWR.DevTools.version = "older-version" end
    return true
end }
combat = true
assert(KWR.BuildInfo:SetDevelopmentMode(true) == false and loaderCalls == 0,
    "Companion loading must defer in combat")
combat = false
loaderMode = "throw"
local ok, message = KWR.BuildInfo:SetDevelopmentMode(true)
assert(ok == false and message:find("loader failure", 1, true), "Loader exception escaped or lost its reason")
loaderMode = "missing"
ok, message = KWR.BuildInfo:SetDevelopmentMode(true)
assert(ok == false and message:find("MISSING", 1, true), "Missing companion was treated as ready")
loaderMode = "mismatch"
assert(KWR.BuildInfo:SetDevelopmentMode(true) == false
    and KWR.db.profile.developmentMode == false and subscribeCalls == 0,
    "Mismatched companion activated diagnostics")
assert(KWR.Verification.Contract == contract, "Companion replaced the production truth gate")
KWR.DevTools.version = expectedVersion
assert(KWR.BuildInfo:SetDevelopmentMode(true) == true and KWR.BuildInfo:HasPreview()
    and subscriptions[KWR.Verification] and bindCalls == 1 and subscribeCalls == 1,
    "Matching companion did not initialize and subscribe once")
KWR.BuildInfo.channel = "development"
combat = true
assert(KWR.BuildInfo:EnsureDeveloperTools() == false,
    "Already-loaded Developer Tools bypassed the combat arming guard")
combat = false
KWR.BuildInfo.channel = "production"
assert(KWR.BuildInfo:SetDevelopmentMode(true) == true and bindCalls == 1 and subscribeCalls == 1,
    "Repeated enable duplicated initialization or subscriptions")
KWR.db.profile.preview = true
assert(KWR.BuildInfo:SetDevelopmentMode(false) == true and not KWR.BuildInfo:IsDevelopmentMode()
    and KWR.db.profile.preview == false and not subscriptions[KWR.Verification]
    and KWR.Verification.Contract == contract,
    "Disabling tools left capture active or removed the truth gate")
assert(KWR.BuildInfo:SetDevelopmentMode(true) == true and bindCalls == 1 and subscribeCalls == 2,
    "Re-enabling tools did not restore capture without reinitialization")
KWR.BuildInfo:SetDevelopmentMode(false)
local enable = KWR.Verification.OnEnable
KWR.Verification.OnEnable = function(self)
    enable(self)
    error("activation failure after subscribing")
end
ok, message = KWR.BuildInfo:SetDevelopmentMode(true)
assert(ok == false and message:find("activation failed", 1, true)
    and KWR.db.profile.developmentMode == false and not next(subscriptions),
    "Failed activation left partial subscriptions or an enabled profile")
KWR.Verification.OnEnable = enable
assert(KWR.BuildInfo:SetDevelopmentMode(true) == true, "Activation could not recover after failure")
KWR.modules.Season2Readiness = nil
assert(KWR.BuildInfo:SetDevelopmentMode(true) == false and not next(subscriptions),
    "Incomplete companion retained active capture")
assert(KWR.Verification.Contract == contract
    and KWR.Verification:Contract({}).aggressiveCommitAllowed == false,
    "Lifecycle failures changed the production truth gate")
print("KWR_DEVTOOLS_PASS load version lifecycle rollback truth-gate")
