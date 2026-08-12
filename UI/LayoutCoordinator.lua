local _, KWR = ...

local LayoutCoordinator = {}
KWR.LayoutCoordinator = LayoutCoordinator

local PROFILES = {
    WIDE = { name = "WIDE", margin = 24, optionsWidth = 780 },
    STANDARD = { name = "STANDARD", margin = 18, optionsWidth = 740 },
    COMPACT = { name = "COMPACT", margin = 14, optionsWidth = 680 },
    NARROW = { name = "NARROW", margin = 10, optionsWidth = 620 },
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
}

local KWR_STRATA = {
    { "MainWindow", "HIGH" },
    { "HUD", "HIGH" },
    { "Options", "HIGH" },
    { "AARWindow", "HIGH" },
    { "CopyDialog", "HIGH" },
}

local function screenSize()
    local width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1920
    local height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 1080
    return math.max(1, width), math.max(1, height)
end

function LayoutCoordinator:Profile()
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
    local width, height = screenSize()
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
    return false
end

function LayoutCoordinator:ApplyStrata()
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
end

function LayoutCoordinator:ApplyMainWindow()
    local main = KWR.MainWindow and KWR.MainWindow.frame
    if not main then return end
    local width, height = screenSize()
    local profile = self:Profile()
    local targetWidth = math.min(1240, math.max(1240, width - (profile.margin * 2)))
    -- Normal displays get enough vertical room for the complete card stack.
    -- Scrolling remains a deliberate compact-mode fallback only.
    local targetHeight = math.min(800, math.max(640, height - (profile.margin * 2)))
    if main:GetWidth() ~= targetWidth or main:GetHeight() ~= targetHeight then
        main:SetSize(targetWidth, targetHeight)
    end
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
    local profile = self:Profile()
    -- HUD.lua owns the deliberate 548px setup / 500px fight-mode sizes.
    -- The coordinator only keeps the active mode's frame inside the viewport.
    self:Clamp(hud, profile.margin)
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
    self:Clamp(options, profile.margin)
end

function LayoutCoordinator:ApplySentinel()
    local sentinel = _G.KWRSentinel
    local sentinelProfile = sentinel and sentinel.db and sentinel.db.profile
    if not sentinelProfile or not sentinel.HUD or not sentinel.Panels then return end
    local hud = sentinel.HUD.frame
    local status = sentinel.Panels.statusFrame
    if not hud then return end

    local hudProfile = sentinelProfile.hud
    local panelsProfile = sentinelProfile.panels
    local manageHud = hudProfile.layoutManaged ~= false
    local manageStatus = status and panelsProfile.layoutManaged ~= false
    if not manageHud and not manageStatus then
        self:Clamp(hud, self:Profile().margin)
        self:Clamp(status, self:Profile().margin)
        return
    end

    local width, height = screenSize()
    local margin = self:Profile().margin
    local hudWidth, hudHeight = hud:GetWidth(), hud:GetHeight()
    local statusWidth = status and status:GetWidth() or 320
    local statusHeight = status and status:GetHeight() or 168
    local gap = 12
    local occupied = {}
    for _, frame in ipairs({
        KWR.MainWindow and KWR.MainWindow.frame,
        KWR.MainWindow and KWR.MainWindow.launcherMenu,
        KWR.HUD and KWR.HUD.frame,
        KWR.CombatRoster and KWR.CombatRoster.teamFrame,
        KWR.CombatRoster and KWR.CombatRoster.enemyFrame,
    }) do
        local rect = frameRect(frame)
        if rect then occupied[#occupied + 1] = rect end
    end
    if not manageHud then
        local rect = frameRect(hud)
        if rect then occupied[#occupied + 1] = rect end
    end
    if status and not manageStatus then
        local rect = frameRect(status)
        if rect then occupied[#occupied + 1] = rect end
    end

    local candidates = {
        { side = "RIGHT", top = height - margin },
        { side = "LEFT", top = height - margin },
        { side = "RIGHT", top = hudHeight + statusHeight + gap + margin },
        { side = "LEFT", top = hudHeight + statusHeight + gap + margin },
    }
    local best
    for _, candidate in ipairs(candidates) do
        local hudLeft = candidate.side == "RIGHT" and width - margin - hudWidth or margin
        local statusLeft = candidate.side == "RIGHT" and width - margin - statusWidth or margin
        local statusTop = candidate.top - hudHeight - gap
        local hudRect = { left = hudLeft, right = hudLeft + hudWidth,
            bottom = candidate.top - hudHeight, top = candidate.top }
        local statusRect = { left = statusLeft, right = statusLeft + statusWidth,
            bottom = statusTop - statusHeight, top = statusTop }
        local overlap = manageHud and manageStatus
            and intersectionArea(hudRect, statusRect) or 0
        for _, rect in ipairs(occupied) do
            if manageHud then overlap = overlap + intersectionArea(hudRect, rect) end
            if manageStatus then overlap = overlap + intersectionArea(statusRect, rect) end
        end
        if not best or overlap < best.overlap then
            best = { overlap = overlap, hud = hudRect, status = statusRect }
        end
    end
    if not best then return end
    if manageHud then
        if setSentinelAnchor(hudProfile, "TOPLEFT", best.hud.left, best.hud.top - height) then
            hud:ClearAllPoints()
            hud:SetPoint(hudProfile.point, UIParent, hudProfile.relativePoint,
                hudProfile.x, hudProfile.y)
        end
    end
    if manageStatus then
        local statusProfile = panelsProfile.status
        if setSentinelAnchor(statusProfile, "TOPLEFT", best.status.left, best.status.top - height) then
            status:ClearAllPoints()
            status:SetPoint(statusProfile.point, UIParent, statusProfile.relativePoint,
                statusProfile.x, statusProfile.y)
        end
    end
    self:Clamp(hud, margin)
    self:Clamp(status, margin)
end

function LayoutCoordinator:Apply()
    -- Layout changes re-anchor frames and scroll containers. Retail can mark
    -- those operations protected while combat is active, so no periodic or
    -- display-change layout work may run until PLAYER_REGEN_ENABLED.
    if InCombatLockdown and InCombatLockdown() then
        self.pendingApply = true
        return false
    end
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
        if self.elapsed < 0.25 then return end
        self.elapsed = 0
        self:Apply()
    end)
end

KWR:RegisterModule("LayoutCoordinator", LayoutCoordinator)
