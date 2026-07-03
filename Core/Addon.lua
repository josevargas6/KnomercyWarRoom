local addonName, KWR = ...

KWR = KWR or {}
_G.KWR = KWR

KWR.name = addonName or "KnomercyWarRoom"
KWR.version = "6.1.0-alpha.15"
KWR.schemaVersion = 60115
KWR.modules = {}
KWR.moduleOrder = {}
KWR.ready = false
KWR.bootDiagnostics = {
    moduleMs = {},
    initializeMs = 0,
    eagerFrames = {},
}

local DEFAULTS = {
    profile = {
        hud = {
            enabled = true,
            locked = false,
            point = "CENTER",
            relativePoint = "CENTER",
            x = -440,
            y = 0,
        },
        main = {
            locked = false,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
            page = "TACTICAL",
        },
        cursor = {
            enabled = false,
            size = 96,
            alpha = 0.95,
        },
        launcher = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = -520,
            y = 0,
            angle = 225,
        },
        reporter = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 430,
            y = 0,
            locked = false,
        },
        combatRoster = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 140,
            locked = false,
            shown = false,
            mode = "BOTH",
            autoShowInPvP = true,
            combatVisuals = true,
        },
        showLoadMessage = true,
        preview = false,
        aar = {
            enabled = true,
            autoOpen = true,
        },
        guidanceMode = "COMMAND",
    },
    journal = {
        history = {},
    },
    enemyNotes = {},
    encounters = {
        players = {},
    },
    learning = {
        plans = {},
    },
}

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

function KWR:RegisterModule(name, module)
    if type(name) ~= "string" or name == "" or type(module) ~= "table" then
        return
    end
    if not self.modules[name] then
        self.moduleOrder[#self.moduleOrder + 1] = name
    end
    module.name = name
    self.modules[name] = module
end

function KWR:GetModule(name)
    return self.modules[name]
end

function KWR:CallModule(module, method, ...)
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

function KWR:Print(message, force)
    if not DEFAULT_CHAT_FRAME or not DEFAULT_CHAT_FRAME.AddMessage then
        return
    end
    if not force and self.db and self.db.profile and self.db.profile.showLoadMessage == false then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffKWR|r " .. tostring(message or ""))
end

function KWR:InitializeDatabase()
    KWR_DB = type(KWR_DB) == "table" and KWR_DB or {}
    local previousSchema = tonumber(KWR_DB.schemaVersion) or 0
    KWR_DB = mergeDefaults(KWR_DB, DEFAULTS)
    if previousSchema > 0 and previousSchema < 60002 then
        local main = KWR_DB.profile.main
        if main.page == "COMMAND" or main.page == "BATTLEFIELD" or main.page == "GUIDE" then
            main.page = "TACTICAL"
        end
        local hud = KWR_DB.profile.hud
        if hud.point == "TOP" and hud.relativePoint == "TOP" and hud.x == 0 and hud.y == -180 then
            hud.point, hud.relativePoint, hud.x, hud.y = "CENTER", "CENTER", -440, 0
        end
        KWR_DB.profile.preview = false
    end
    KWR_DB.schemaVersion = self.schemaVersion
    self.db = KWR_DB
end

function KWR:InitializeModules()
    local totalStarted = type(debugprofilestop) == "function" and debugprofilestop() or 0
    for _, name in ipairs(self.moduleOrder) do
        local started = type(debugprofilestop) == "function" and debugprofilestop() or 0
        self:CallModule(self.modules[name], "OnInitialize")
        if started > 0 and type(debugprofilestop) == "function" then
            self.bootDiagnostics.moduleMs[name] = math.max(0, debugprofilestop() - started)
        end
    end
    if totalStarted > 0 and type(debugprofilestop) == "function" then
        self.bootDiagnostics.initializeMs = math.max(0, debugprofilestop() - totalStarted)
    end
    self.bootDiagnostics.eagerFrames = {}
    for _, name in ipairs({
        "MainWindow", "ReporterMap", "CombatRoster", "AARWindow",
        "CopyDialog", "Options",
    }) do
        local module = self.modules[name]
        if module and module.frame then
            self.bootDiagnostics.eagerFrames[#self.bootDiagnostics.eagerFrames + 1] = name
        end
    end
end

function KWR:EnableModules()
    for _, name in ipairs(self.moduleOrder) do
        self:CallModule(self.modules[name], "OnEnable")
    end
end

function KWR:DisableModules()
    for index = #self.moduleOrder, 1, -1 do
        self:CallModule(self.modules[self.moduleOrder[index]], "OnDisable")
    end
end

local frame = CreateFrame("Frame", "KWR_BootstrapFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= KWR.name then
            return
        end
        KWR:InitializeDatabase()
        KWR:InitializeModules()
        KWR.ready = true
    elseif event == "PLAYER_LOGIN" then
        KWR:EnableModules()
        if KWR.db.profile.showLoadMessage ~= false then
        KWR:Print("6.1 Alpha 15 loaded. Full spoken calls and transition-safe roster convergence are active.", true)
        end
    elseif event == "PLAYER_LOGOUT" then
        KWR:DisableModules()
    end
end)
