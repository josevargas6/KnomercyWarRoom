local addonName, Sentinel = ...

Sentinel = Sentinel or {}
_G.KWRSentinel = Sentinel

Sentinel.name = addonName or "KWRSentinel"
Sentinel.version = "6.1.0-alpha.38"
Sentinel.modules = {}
Sentinel.moduleOrder = {}
Sentinel.ready = false

local DEFAULTS = {
    profile = {
        hud = {
            enabled = true,
            locked = false,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 360,
            y = -58,
            utilityButtons = true,
        },
        targetCue = {
            enabled = true,
        },
        panels = {
            locked = false,
            status = {
                enabled = true,
                point = "CENTER",
                relativePoint = "CENTER",
                x = 360,
                y = -300,
            },
        },
        minimap = {
            enabled = true,
            angle = 225,
        },
        loadMessage = true,
    },
}

Sentinel.defaults = DEFAULTS

local function mergeDefaults(target, defaults)
    target = type(target) == "table" and target or {}
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = mergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

function Sentinel:RegisterModule(name, module)
    if type(name) ~= "string" or name == "" or type(module) ~= "table" then
        return
    end
    if not self.modules[name] then
        self.moduleOrder[#self.moduleOrder + 1] = name
    end
    module.name = name
    self.modules[name] = module
end

function Sentinel:CallModule(module, method, ...)
    if type(module) ~= "table" or type(module[method]) ~= "function" then
        return true
    end
    local arguments = { ... }
    local ok, result = xpcall(function()
        return module[method](module, unpack(arguments))
    end, geterrorhandler())
    if not ok then
        self:Print("Error in " .. tostring(module.name or "module") .. "." .. tostring(method) .. ": " .. tostring(result), true)
        return false
    end
    return true, result
end

function Sentinel:Print(message, force)
    if not DEFAULT_CHAT_FRAME or not DEFAULT_CHAT_FRAME.AddMessage then
        return
    end
    if not force and self.db and self.db.profile and self.db.profile.loadMessage == false then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff7fd7ffSentinel|r " .. tostring(message or ""))
end

function Sentinel:InitializeDatabase()
    KWR_SENTINEL_DB = type(KWR_SENTINEL_DB) == "table" and KWR_SENTINEL_DB or {}
    KWR_SENTINEL_DB = mergeDefaults(KWR_SENTINEL_DB, DEFAULTS)
    self.db = KWR_SENTINEL_DB
end

function Sentinel:InitializeModules()
    for _, name in ipairs(self.moduleOrder) do
        self:CallModule(self.modules[name], "OnInitialize")
    end
end

function Sentinel:EnableModules()
    for _, name in ipairs(self.moduleOrder) do
        self:CallModule(self.modules[name], "OnEnable")
    end
end

function Sentinel:DisableModules()
    for index = #self.moduleOrder, 1, -1 do
        self:CallModule(self.modules[self.moduleOrder[index]], "OnDisable")
    end
end

SLASH_KWRSENTINEL1 = "/sentinel"
SLASH_KWRSENTINEL2 = "/kwrs"
SlashCmdList.KWRSENTINEL = function(message)
    message = tostring(message or ""):lower()
    if message == "reset" and Sentinel.HUD then
        Sentinel.HUD:ResetPosition()
        if Sentinel.Panels and Sentinel.Panels.ResetPositions then
            Sentinel.Panels:ResetPositions()
        end
        Sentinel:Print("Execution card position reset.", true)
        return
    end
    if message == "map" and Sentinel.NativeUI then
        Sentinel.NativeUI:ToggleMap()
        return
    end
    if message == "score" and Sentinel.NativeUI then
        Sentinel.NativeUI:ToggleScore()
        return
    end
    if message == "options" and Sentinel.Options then
        Sentinel.Options:Toggle()
        return
    end
    if message == "show" and Sentinel.HUD then
        Sentinel.db.profile.hud.enabled = true
        Sentinel.HUD:Update()
        Sentinel:Print("Execution card shown.", true)
        return
    end
    if message == "hide" and Sentinel.HUD then
        Sentinel.db.profile.hud.enabled = false
        Sentinel.HUD:Update()
        Sentinel:Print("Execution card hidden.", true)
        return
    end
    if Sentinel.HUD then
        Sentinel.HUD:Toggle()
    end
end

local frame = CreateFrame("Frame", "KWRSentinel_BootstrapFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= Sentinel.name then
            return
        end
        Sentinel:InitializeDatabase()
        Sentinel:InitializeModules()
        Sentinel.ready = true
    elseif event == "PLAYER_LOGIN" then
        Sentinel:EnableModules()
        if Sentinel.db.profile.loadMessage ~= false then
            Sentinel:Print("Compact commander-linked execution card and target confirmation are active.", true)
        end
    elseif event == "PLAYER_LOGOUT" then
        Sentinel:DisableModules()
    end
end)
