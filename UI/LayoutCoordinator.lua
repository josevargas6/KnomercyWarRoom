local _, KWR = ...

local LayoutCoordinator = {}
KWR.LayoutCoordinator = LayoutCoordinator

local PROFILES = {
    WIDE = { name = "WIDE", margin = 24, optionsWidth = 780, scale = 1.08 },
    STANDARD = { name = "STANDARD", margin = 18, optionsWidth = 740, scale = 1.00 },
    COMPACT = { name = "COMPACT", margin = 14, optionsWidth = 680, scale = 0.90 },
    NARROW = { name = "NARROW", margin = 10, optionsWidth = 620, scale = 0.82 },
}

local BLIZZARD_WINDOWS = {
    "SettingsPanel",
    "InterfaceOptionsFrame",
    "PlayerSpellsFrame",
    "SpellBookFrame",
    "WorldMapFrame",
    "QuestLogFrame",
    "QuestMapFrame",
    "CharacterFrame",
    "DressUpFrame",
    "CollectionsJournal",
    "EncounterJournal",
    "GameMenuFrame",
    "ContainerFrameCombinedBags",
}

local MAX_CONTAINER_FRAMES = 13
local lastScreenWidth, lastScreenHeight = 1920, 1080

local KWR_STRATA = {
    { "MainWindow", "HIGH" },
    { "HUD", "HIGH" },
    { "Options", "HIGH" },
    { "CopyDialog", "HIGH" },
}

local function screenSize()
    local width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1920
    local height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 1080
    -- Retail can expose a 1px transitional UIParent geometry while changing
    -- displays/instances.  Treat it as unavailable rather than scaling or
    -- clamping every managed surface against that value.
    if type(width) == "number" and type(height) == "number" and width >= 640 and height >= 480 then
        lastScreenWidth, lastScreenHeight = width, height
    end
    return lastScreenWidth, lastScreenHeight
end

function LayoutCoordinator:AutoProfile()
    local width, height = screenSize()
    if width >= 2200 or width / height >= 2.15 then
        return PROFILES.WIDE
    end
    if width >= 1800 and height >= 900 then
        return PROFILES.STANDARD
    end
    if width >= 1450 and height >= 800 then
        return PROFILES.COMPACT
    end
    return PROFILES.NARROW
end

function LayoutCoordinator:Profile()
    local mode = KWR.db and KWR.db.profile and KWR.db.profile.layoutMode or "AUTO"
    if mode == "COMPACT" then return PROFILES.COMPACT end
    if mode == "STANDARD" then return PROFILES.STANDARD end
    if mode == "LARGE" then return PROFILES.WIDE end
    return self:AutoProfile()
end

local function applyScale(frame, scale)
    if not frame or not frame.SetScale then return end
    if frame:GetScale() ~= scale then frame:SetScale(scale) end
end

local function visibleScale(frame, requested, margin)
    if not frame or not frame.GetWidth or not frame.GetHeight then return requested end
    local width, height = screenSize()
    local frameWidth, frameHeight = frame:GetWidth(), frame:GetHeight()
    if not frameWidth or not frameHeight or frameWidth <= 0 or frameHeight <= 0 then
        return requested
    end
    local maximum = math.min((width - (margin * 2)) / frameWidth,
        (height - (margin * 2)) / frameHeight)
    return math.min(requested, maximum)
end

local function moveBy(frame, dx, dy)
    if not frame or not frame.GetCenter then return end
    local centerX, centerY = frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if not centerX or not centerY or not parentX or not parentY then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER",
        (centerX - parentX) + dx, (centerY - parentY) + dy)
end

function LayoutCoordinator:Clamp(frame, margin)
    if not frame or not frame.IsShown or not frame:IsShown() then return end
    if frame.KWRDragging then return end
    local width, height = screenSize()
    -- A failed/incomplete render can leave a frame with impossible geometry.
    -- Let the owning surface repair that state rather than asking Blizzard's
    -- backdrop logic to clamp invalid dimensions.
    local frameWidth, frameHeight = frame:GetWidth(), frame:GetHeight()
    if not frameWidth or not frameHeight or frameWidth <= 0 or frameHeight <= 0
        or frameWidth > width * 2 or frameHeight > height * 2 then return end
    local left, right = frame:GetLeft(), frame:GetRight()
    local bottom, top = frame:GetBottom(), frame:GetTop()
    if not left or not right or not bottom or not top then return end
    local dx, dy = 0, 0
    margin = margin or 8
    if left < margin then dx = margin - left end
    if right > width - margin then dx = (width - margin) - right end
    if bottom < margin then dy = margin - bottom end
    if top > height - margin then dy = (height - margin) - top end
    if dx ~= 0 or dy ~= 0 then moveBy(frame, dx, dy) end
    frame:SetClampedToScreen(true)
end

local function shown(name)
    local frame = _G[name]
    return frame and frame.IsShown and frame:IsShown()
end

local function moduleSurfaceShown(name)
    local module = KWR[name]
    return module and module.frame and module.frame.IsShown and module.frame:IsShown()
end

local function intersectionArea(a, b)
    local left = math.max(a.left, b.left)
    local right = math.min(a.right, b.right)
    local bottom = math.max(a.bottom, b.bottom)
    local top = math.min(a.top, b.top)
    if left >= right or bottom >= top then return 0 end
    return (right - left) * (top - bottom)
end

local function frameRect(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then return nil end
    local left, right = frame:GetLeft(), frame:GetRight()
    local bottom, top = frame:GetBottom(), frame:GetTop()
    if not left or not right or not bottom or not top then return nil end
    return { left = left, right = right, bottom = bottom, top = top }
end

local function setSentinelAnchor(settings, point, x, y)
    if not settings or (settings.point == point and settings.relativePoint == point
        and settings.x == x and settings.y == y) then return false end
    settings.point = point
    settings.relativePoint = point
    settings.x = x
    settings.y = y
    return true
end

function LayoutCoordinator:BlizzardOptionsOpen()
    return shown("SettingsPanel") or shown("InterfaceOptionsFrame")
end

function LayoutCoordinator:BlizzardWindowOpen()
    for _, name in ipairs(BLIZZARD_WINDOWS) do
        if shown(name) then return true end
    end
    for index = 1, MAX_CONTAINER_FRAMES do
        if shown("ContainerFrame" .. index) then return true end
    end
    return false
end

function LayoutCoordinator:ApplyStrata()
    if InCombatLockdown and InCombatLockdown() then
        self.pendingApply = true
        return false
    end
    local lowered = self:BlizzardWindowOpen()
    local strata = lowered and "MEDIUM" or nil
    for _, entry in ipairs(KWR_STRATA) do
        local module = KWR[entry[1]]
        local frames = {}
        if module then
            frames[#frames + 1] = module.frame
        end
        for _, frame in ipairs(frames) do
            if frame and frame.SetFrameStrata then
                local desired = strata or entry[2]
                if not frame.GetFrameStrata or frame:GetFrameStrata() ~= desired then
                    frame:SetFrameStrata(desired)
                end
            end
        end
    end
    local launcher = KWR.MainWindow and KWR.MainWindow.launcher
    if launcher and launcher.SetFrameStrata then
        launcher:SetFrameStrata(lowered and "MEDIUM" or "HIGH")
    end
    local menu = KWR.MainWindow and KWR.MainWindow.launcherMenu
    if menu and menu.SetFrameStrata then
        menu:SetFrameStrata(lowered and "MEDIUM" or "HIGH")
    end
    return true
end

function LayoutCoordinator:ApplyMainWindow()
    local main = KWR.MainWindow and KWR.MainWindow.frame
    if not main then return end
    local width, height = screenSize()
    local profile = self:Profile()
    -- The internal command board is a fixed logical canvas. Scale the whole
    -- canvas instead of squeezing cards and tabs into narrower columns.
    local targetWidth = 1240
    -- Normal displays get enough vertical room for the complete card stack.
    -- Scrolling remains a deliberate compact-mode fallback only.
    local targetHeight = math.min(800, math.max(640, height - (profile.margin * 2)))
    if main:GetWidth() ~= targetWidth or main:GetHeight() ~= targetHeight then
        main:SetSize(targetWidth, targetHeight)
    end
    applyScale(main, visibleScale(main, profile.scale, profile.margin))
    if KWR.MainWindow.contentViewport then
        KWR.MainWindow.contentViewport:SetPoint("TOPLEFT", 18, -124)
        KWR.MainWindow.contentViewport:SetPoint("BOTTOMRIGHT", -18, 20)
        local compactViewport = targetHeight < 820
        KWR.MainWindow.contentViewport:EnableMouseWheel(compactViewport)
        if not compactViewport and KWR.MainWindow.contentViewport.SetVerticalScroll then
            KWR.MainWindow.contentViewport:SetVerticalScroll(0)
        end
    end
    if KWR.MainWindow.tabBar then
        KWR.MainWindow.tabBar:SetWidth(targetWidth - 36)
    end
    self:Clamp(main, profile.margin)
end

function LayoutCoordinator:ApplyHUD()
    local hud = KWR.HUD and KWR.HUD.frame
    if not hud then return end
    -- CommanderCard owns the host's measured size, viewport fallback and
    -- clamping while its complete live surface is active.  Calling GetWidth
    -- here can force Blizzard's nine-slice layout on an incomplete render;
    -- that is the Texture:SetTextCoord out-of-range path reported in field.
    if hud.cardActive then return end
    local profile = self:Profile()
    applyScale(hud, visibleScale(hud, profile.scale, profile.margin))
    -- HUD.lua owns its geometry.  In particular, polling Clamp here compares
    -- effective-scale coordinates to UIParent coordinates and can walk the
    -- Setup Center from one side of the screen to the other.  A saved anchor
    -- must remain stable until the operator drags it or explicitly resets it.
end

function LayoutCoordinator:ApplyOptions()
    local options = KWR.Options and KWR.Options.frame
    if not options then return end
    local width, height = screenSize()
    local profile = self:Profile()
    local targetWidth = math.min(780, math.max(600,
        math.min(profile.optionsWidth, width - (profile.margin * 2))))
    local targetHeight = math.max(560, math.min(980, height - (profile.margin * 2)))
    if options:GetWidth() ~= targetWidth or options:GetHeight() ~= targetHeight then
        options:SetSize(targetWidth, targetHeight)
    end
    applyScale(options, visibleScale(options, profile.scale, profile.margin))
    self:Clamp(options, profile.margin)
end

function LayoutCoordinator:ApplySentinel()
    local sentinel = _G.KWRSentinel
    local sentinelProfile = sentinel and sentinel.db and sentinel.db.profile
    if not sentinelProfile or not sentinel.HUD then return end
    local hud = sentinel.HUD.frame
    local status = sentinel.Panels and sentinel.Panels.statusFrame
    if not hud then return end
    local margin = self:Profile().margin
    -- Sentinel's old candidate search re-anchored the panel whenever a KWR
    -- surface appeared or disappeared.  That makes it sweep between screen
    -- sides and still cannot account for Blizzard bags/minimap.  Retain the
    -- user/default anchor; positioning is now explicit drag/reset behavior.
    applyScale(hud, visibleScale(hud, self:Profile().scale, margin))
    applyScale(status, visibleScale(status, self:Profile().scale, margin))
end

function LayoutCoordinator:Apply()
    if InCombatLockdown and InCombatLockdown() then
        self.pendingApply = true
        return false
    end
    -- Native frame relationships can protect strata as well as anchors.
    -- Apply deferred layout work after PLAYER_REGEN_ENABLED.
    self.pendingApply = nil
    self:ApplyStrata()
    self:ApplyMainWindow()
    self:ApplyHUD()
    self:ApplyOptions()
    self:ApplySentinel()
    local launcher = KWR.MainWindow and KWR.MainWindow.launcherMenu
    self:Clamp(launcher, self:Profile().margin)
    return true
end

function LayoutCoordinator:Reset()
    if InCombatLockdown and InCombatLockdown() then
        self.pendingReset = true
        return false
    end
    if KWR.db and KWR.db.profile then
        local profile = KWR.db.profile
        profile.main.point, profile.main.relativePoint, profile.main.x, profile.main.y = "CENTER", "CENTER", 0, 0
        profile.hud.point, profile.hud.relativePoint, profile.hud.x, profile.hud.y = "CENTER", "CENTER", -440, 0
        profile.options.point, profile.options.relativePoint, profile.options.x, profile.options.y = "CENTER", "CENTER", 0, 0
        profile.launcher.angle = 225
        local roster = profile.combatRoster
        roster.point, roster.relativePoint, roster.x, roster.y = "CENTER", "CENTER", 0, 140
        roster.layoutVersion = 3
        roster.teamMini.point, roster.teamMini.relativePoint = "CENTER", "CENTER"
        roster.teamMini.x, roster.teamMini.y = -170, 140
        roster.enemyMini.point, roster.enemyMini.relativePoint = "CENTER", "CENTER"
        roster.enemyMini.x, roster.enemyMini.y = 170, 140
    end
    for _, frame in ipairs({
        KWR.MainWindow and KWR.MainWindow.frame,
        KWR.HUD and KWR.HUD.frame,
        KWR.Options and KWR.Options.frame,
    }) do
        if frame then frame:ClearAllPoints() end
    end
    if KWR.MainWindow and KWR.MainWindow.frame then KWR.MainWindow.frame:SetPoint("CENTER") end
    if KWR.HUD and KWR.HUD.frame then KWR.HUD.frame:SetPoint("CENTER", UIParent, "CENTER", -440, 0) end
    if KWR.Options and KWR.Options.frame then KWR.Options.frame:SetPoint("CENTER") end
    if KWR.MainWindow and KWR.MainWindow.launcher then
        KWR.MainWindow:PositionLauncher()
    end
    if KWR.CombatRoster then
        if KWR.CombatRoster.teamFrame then
            KWR.CombatRoster.teamFrame:ClearAllPoints()
            KWR.CombatRoster.teamFrame:SetPoint("CENTER", UIParent, "CENTER", -170, 140)
        end
        if KWR.CombatRoster.enemyFrame then
            KWR.CombatRoster.enemyFrame:ClearAllPoints()
            KWR.CombatRoster.enemyFrame:SetPoint("CENTER", UIParent, "CENTER", 170, 140)
        end
        if KWR.CombatRoster.teamFrame or KWR.CombatRoster.enemyFrame then
            KWR.CombatRoster:Layout(KWR.db.profile.combatRoster.mode or "BOTH")
        end
    end
    self:Apply()
    return true
end

function LayoutCoordinator:OnInitialize()
    self.eventFrame = CreateFrame("Frame", "KWR_LayoutCoordinatorEvents")
    self.eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    self.eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and LayoutCoordinator.pendingReset then
            LayoutCoordinator.pendingReset = nil
            LayoutCoordinator:Reset()
            return
        end
        LayoutCoordinator:Apply()
    end)
    self.eventFrame:SetScript("OnUpdate", function(_, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        -- Layout is event-driven for scale/display changes.  Keep a slow
        -- safety clamp for frames moved by Blizzard, rather than re-running
        -- every quarter second while the addon is idle.
        if self.elapsed < 1.0 then return end
        self.elapsed = 0
        local active = (KWR.MainWindow and KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown())
            or (KWR.MainWindow and KWR.MainWindow.launcher and KWR.MainWindow.launcher:IsShown())
            or (KWR.MainWindow and KWR.MainWindow.launcherMenu and KWR.MainWindow.launcherMenu:IsShown())
            or (KWR.HUD and KWR.HUD.frame and KWR.HUD.frame:IsShown())
            or (KWR.Options and KWR.Options.frame and KWR.Options.frame:IsShown())
            or moduleSurfaceShown("AARWindow")
            or moduleSurfaceShown("CopyDialog")
            or (_G.KWRSentinel and _G.KWRSentinel.HUD and _G.KWRSentinel.HUD.frame
                and _G.KWRSentinel.HUD.frame:IsShown())
            or (_G.KWRSentinel and _G.KWRSentinel.Panels
                and _G.KWRSentinel.Panels.statusFrame
                and _G.KWRSentinel.Panels.statusFrame:IsShown())
        if not active then return end
        self:Apply()
    end)
end

KWR:RegisterModule("LayoutCoordinator", LayoutCoordinator)
