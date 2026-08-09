local addonName, KWR = ...

KWR = KWR or {}
_G.KWR = KWR

KWR.name = addonName or "KnomercyWarRoom"
KWR.version = "6.1.0-alpha.40"
KWR.schemaVersion = 60129
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
            audio = {
                enabled = true,
                voiceID = nil,
                rate = 0,
                volume = 75,
                minimumInterval = 6,
            },
        },
        options = {
            locked = false,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 360,
            y = 18,
        },
        copyDialog = {
            locked = false,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 60,
        },
        aarWindow = {
            locked = false,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
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
        formation = {
            selectedCompID = nil,
        },
        cursor = {
            enabled = false,
            size = 96,
            alpha = 0.95,
            reticleEnabled = true,
            reticleSize = 92,
            reticleAlpha = 0.84,
            reticleGuides = true,
            battlefieldOrbs = true,
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
            advancedOpen = false,
            advancedTab = "READ",
        },
        combatRoster = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 140,
            layoutVersion = 3,
            locked = false,
            shown = false,
            mode = "BOTH",
            teamShown = false,
            enemyShown = false,
            autoShowInPvP = true,
            combatVisuals = true,
            teamMini = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = -170,
                y = 140,
            },
            enemyMini = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = 170,
                y = 140,
            },
        },
        presentation = {
            enabled = true,
            hideTopWidgets = true,
            hideObjectiveTracker = true,
            hideMinimap = true,
            hideStatusTracking = true,
            -- KWR never controls Blizzard-owned raid frames. Keep this legacy
            -- preference inert so profile migration remains non-destructive.
            hideRaidFrames = false,
            autoReporter = false,
            autoRoster = true,
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
    assignmentOverrides = {
        players = {},
    },
    opponentModels = {
        players = {},
        processedMatches = {},
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

local function copyTable(source)
    if type(source) ~= "table" then
        return source
    end
    local target = {}
    for key, value in pairs(source) do
        target[key] = copyTable(value)
    end
    return target
end

local function normalizeAgainstDefaults(current, defaults)
    if type(defaults) ~= "table" then
        if defaults == nil then
            return current
        end
        if type(current) == type(defaults) then
            return current
        end
        return defaults
    end
    if type(current) ~= "table" then
        return copyTable(defaults)
    end
    local normalized = {}
    for key, value in pairs(current) do
        normalized[key] = value
    end
    for key, value in pairs(defaults) do
        normalized[key] = normalizeAgainstDefaults(current[key], value)
    end
    return normalized
end

local function boundedList(source)
    if type(source) ~= "table" then
        return {}
    end
    local list = {}
    for index = 1, #source do
        list[#list + 1] = source[index]
    end
    return list
end

local function normalizePointBucket(bucket, defaults)
    bucket = normalizeAgainstDefaults(bucket, defaults)
    bucket.point = KWR.Util:Text(bucket.point, defaults.point, 24)
    bucket.relativePoint = KWR.Util:Text(bucket.relativePoint, defaults.relativePoint, 24)
    bucket.x = KWR.Util:Number(bucket.x, defaults.x)
    bucket.y = KWR.Util:Number(bucket.y, defaults.y)
    if defaults.locked ~= nil then
        bucket.locked = KWR.Util:Boolean(bucket.locked, defaults.locked)
    end
    return bucket
end

local function normalizeProfile(profile)
    local defaults = DEFAULTS.profile
    local rawCombatRoster = type(profile) == "table"
        and type(profile.combatRoster) == "table"
        and profile.combatRoster or nil
    local combatRosterLayoutVersion = rawCombatRoster ~= nil
        and (KWR.Util:Number(rawCombatRoster.layoutVersion, 0) or 0) or 0
    local migrateRosterLayout = rawCombatRoster ~= nil
        and combatRosterLayoutVersion < 3
    profile = normalizeAgainstDefaults(profile, defaults)
    profile.hud = normalizePointBucket(profile.hud, defaults.hud)
    profile.options = normalizePointBucket(profile.options, defaults.options)
    profile.copyDialog = normalizePointBucket(profile.copyDialog, defaults.copyDialog)
    profile.aarWindow = normalizePointBucket(profile.aarWindow, defaults.aarWindow)
    profile.main = normalizePointBucket(profile.main, defaults.main)
    profile.main.page = KWR.Util:Text(profile.main.page, defaults.main.page, 24)
    profile.launcher = normalizePointBucket(profile.launcher, defaults.launcher)
    profile.launcher.angle = KWR.Util:Number(profile.launcher.angle, defaults.launcher.angle)
    profile.reporter = normalizePointBucket(profile.reporter, defaults.reporter)
    profile.reporter.advancedOpen = KWR.Util:Boolean(
        profile.reporter.advancedOpen, defaults.reporter.advancedOpen)
    profile.reporter.advancedTab = KWR.Util:Upper(
        profile.reporter.advancedTab, defaults.reporter.advancedTab, 12)
    profile.formation = type(profile.formation) == "table" and profile.formation or {}
    if profile.formation.selectedCompID ~= nil then
        profile.formation.selectedCompID =
            KWR.Util:Text(profile.formation.selectedCompID, nil, 64)
    end
    profile.cursor = normalizeAgainstDefaults(profile.cursor, defaults.cursor)
    profile.cursor.enabled = KWR.Util:Boolean(profile.cursor.enabled, defaults.cursor.enabled)
    profile.cursor.size = KWR.Util:Number(profile.cursor.size, defaults.cursor.size)
    profile.cursor.alpha = KWR.Util:Number(profile.cursor.alpha, defaults.cursor.alpha)
    profile.cursor.reticleEnabled = KWR.Util:Boolean(
        profile.cursor.reticleEnabled, defaults.cursor.reticleEnabled)
    profile.cursor.reticleSize = KWR.Util:Number(
        profile.cursor.reticleSize, defaults.cursor.reticleSize)
    profile.cursor.reticleAlpha = KWR.Util:Number(
        profile.cursor.reticleAlpha, defaults.cursor.reticleAlpha)
    profile.cursor.reticleGuides = KWR.Util:Boolean(
        profile.cursor.reticleGuides, defaults.cursor.reticleGuides)
    profile.cursor.battlefieldOrbs = KWR.Util:Boolean(
        profile.cursor.battlefieldOrbs, defaults.cursor.battlefieldOrbs)
    profile.combatRoster = normalizePointBucket(profile.combatRoster, defaults.combatRoster)
    if migrateRosterLayout then
        local legacyAnchor
        local legacyMode = KWR.Util:Upper(
            rawCombatRoster.mode, "BOTH", 16)
        if legacyMode == "TEAM"
            and type(rawCombatRoster.solo) == "table" then
            legacyAnchor = rawCombatRoster.solo.team
        elseif legacyMode == "ENEMY"
            and type(rawCombatRoster.solo) == "table" then
            legacyAnchor = rawCombatRoster.solo.enemy
        elseif type(rawCombatRoster.panes) == "table"
            and type(rawCombatRoster.panes.team) == "table"
            and rawCombatRoster.panes.team.anchorSpace == "SCREEN" then
            legacyAnchor = rawCombatRoster.panes.team
        end
        if type(legacyAnchor) == "table" then
            profile.combatRoster.point = KWR.Util:Text(
                legacyAnchor.point,
                profile.combatRoster.point, 24)
            profile.combatRoster.relativePoint = KWR.Util:Text(
                legacyAnchor.relativePoint,
                profile.combatRoster.relativePoint, 24)
            profile.combatRoster.x = KWR.Util:Number(
                legacyAnchor.x, profile.combatRoster.x)
            profile.combatRoster.y = KWR.Util:Number(
                legacyAnchor.y, profile.combatRoster.y)
        end
        local basePoint = profile.combatRoster.point
        local baseRelativePoint = profile.combatRoster.relativePoint
        local baseX = profile.combatRoster.x
        local baseY = profile.combatRoster.y
        local teamMini = copyTable(defaults.combatRoster.teamMini)
        local enemyMini = copyTable(defaults.combatRoster.enemyMini)
        teamMini.point = basePoint
        teamMini.relativePoint = baseRelativePoint
        teamMini.y = baseY
        enemyMini.point = basePoint
        enemyMini.relativePoint = baseRelativePoint
        enemyMini.y = baseY
        if legacyMode == "TEAM" then
            teamMini.x = baseX
            enemyMini.x = baseX + 340
        elseif legacyMode == "ENEMY" then
            teamMini.x = baseX - 340
            enemyMini.x = baseX
        else
            teamMini.x = baseX - 170
            enemyMini.x = baseX + 170
        end
        profile.combatRoster.teamMini = teamMini
        profile.combatRoster.enemyMini = enemyMini
    end
    profile.combatRoster.teamMini = normalizePointBucket(
        profile.combatRoster.teamMini, defaults.combatRoster.teamMini)
    profile.combatRoster.enemyMini = normalizePointBucket(
        profile.combatRoster.enemyMini, defaults.combatRoster.enemyMini)
    profile.combatRoster.layoutVersion = 3
    profile.combatRoster.anchorSpace = nil
    profile.combatRoster.panes = nil
    profile.combatRoster.splitToolbar = nil
    profile.combatRoster.solo = nil
    profile.combatRoster.shown = KWR.Util:Boolean(
        profile.combatRoster.shown, defaults.combatRoster.shown)
    profile.combatRoster.mode = KWR.Util:Text(
        profile.combatRoster.mode, defaults.combatRoster.mode, 16)
    profile.combatRoster.teamShown = KWR.Util:Boolean(
        profile.combatRoster.teamShown,
        profile.combatRoster.shown and profile.combatRoster.mode ~= "ENEMY")
    profile.combatRoster.enemyShown = KWR.Util:Boolean(
        profile.combatRoster.enemyShown,
        profile.combatRoster.shown and profile.combatRoster.mode ~= "TEAM")
    profile.combatRoster.autoShowInPvP = KWR.Util:Boolean(
        profile.combatRoster.autoShowInPvP, defaults.combatRoster.autoShowInPvP)
    profile.combatRoster.combatVisuals = KWR.Util:Boolean(
        profile.combatRoster.combatVisuals, defaults.combatRoster.combatVisuals)
    profile.presentation = normalizeAgainstDefaults(profile.presentation, defaults.presentation)
    for key, value in pairs(defaults.presentation) do
        profile.presentation[key] = KWR.Util:Boolean(profile.presentation[key], value)
    end
    profile.showLoadMessage = KWR.Util:Boolean(
        profile.showLoadMessage, defaults.showLoadMessage)
    profile.preview = KWR.Util:Boolean(profile.preview, defaults.preview)
    profile.aar = normalizeAgainstDefaults(profile.aar, defaults.aar)
    profile.aar.enabled = KWR.Util:Boolean(profile.aar.enabled, defaults.aar.enabled)
    profile.aar.autoOpen = KWR.Util:Boolean(profile.aar.autoOpen, defaults.aar.autoOpen)
    profile.guidanceMode = KWR.Util:Text(profile.guidanceMode, defaults.guidanceMode, 24)
    return profile
end

local function normalizeRootBranches(database)
    database.journal = type(database.journal) == "table" and database.journal or {}
    database.journal.history = boundedList(database.journal.history)
    database.journal.interrupted = type(database.journal.interrupted) == "table"
        and database.journal.interrupted or nil
    database.enemyNotes = type(database.enemyNotes) == "table" and database.enemyNotes or {}
    database.encounters = type(database.encounters) == "table" and database.encounters or {}
    database.encounters.players = type(database.encounters.players) == "table"
        and database.encounters.players or {}
    database.learning = type(database.learning) == "table" and database.learning or {}
    database.learning.plans = type(database.learning.plans) == "table"
        and database.learning.plans or {}
    database.assignmentOverrides = type(database.assignmentOverrides) == "table"
        and database.assignmentOverrides or {}
    database.assignmentOverrides.players =
        type(database.assignmentOverrides.players) == "table"
        and database.assignmentOverrides.players or {}
    database.assignmentOverrides.legacyPlayers =
        type(database.assignmentOverrides.legacyPlayers) == "table"
        and database.assignmentOverrides.legacyPlayers or {}
    database.assignmentOverrides.ambiguousLegacy =
        type(database.assignmentOverrides.ambiguousLegacy) == "table"
        and database.assignmentOverrides.ambiguousLegacy or {}
    database.opponentModels = type(database.opponentModels) == "table"
        and database.opponentModels or {}
    database.opponentModels.players = type(database.opponentModels.players) == "table"
        and database.opponentModels.players or {}
    database.opponentModels.processedMatches =
        type(database.opponentModels.processedMatches) == "table"
        and database.opponentModels.processedMatches or {}
    return database
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
    self.persistenceDisabled = false
    self.compatibilityStatus = nil
    if previousSchema > self.schemaVersion then
        local source = copyTable(KWR_DB)
        local working = normalizeAgainstDefaults(source, DEFAULTS)
        working.profile = normalizeProfile(source.profile)
        working = normalizeRootBranches(working)
        working.schemaVersion = previousSchema
        working.compatibility = {
            mode = "FUTURE_SCHEMA_READ_ONLY",
            futureSchema = true,
            storedSchemaVersion = previousSchema,
            supportedSchemaVersion = self.schemaVersion,
        }
        self.db = working
        self.persistenceDisabled = true
        self.compatibilityStatus = working.compatibility
        return
    end
    local storedProfile = KWR_DB.profile
    KWR_DB = normalizeAgainstDefaults(KWR_DB, DEFAULTS)
    KWR_DB.profile = normalizeProfile(storedProfile)
    KWR_DB = normalizeRootBranches(KWR_DB)
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
    KWR_DB = normalizeRootBranches(KWR_DB)
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
        "MainWindow", "CombatRoster", "AARWindow",
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
        if KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentBuild() then
            KWR:Print("KWR DEVELOPMENT BUILD - NOT FOR PRODUCTION USE", true)
        end
        if KWR.compatibilityStatus and KWR.compatibilityStatus.futureSchema then
            KWR:Print("SavedVariables were created by a newer KWR schema. Running in read-only compatibility mode; persisted data will not be downgraded.", true)
        end
        if KWR.db.profile.showLoadMessage ~= false then
            KWR:Print(KWR.version .. " loaded. Knowledge freshness gating, commander overrides, doctrine-aware assignments, and PvP presentation cleanup are active.", true)
        end
    elseif event == "PLAYER_LOGOUT" then
        KWR:DisableModules()
    end
end)
