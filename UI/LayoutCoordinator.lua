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

function LayoutCoordinator:Apply()
    self:ApplyStrata()
    self:ApplyMainWindow()
    self:ApplyHUD()
    self:ApplyOptions()
    local launcher = KWR.MainWindow and KWR.MainWindow.launcherMenu
    self:Clamp(launcher, self:Profile().margin)
end

function LayoutCoordinator:Reset()
    if KWR.db and KWR.db.profile then
        local profile = KWR.db.profile
        profile.main.point, profile.main.relativePoint, profile.main.x, profile.main.y = "CENTER", "CENTER", 0, 0
        profile.hud.point, profile.hud.relativePoint, profile.hud.x, profile.hud.y = "CENTER", "CENTER", -440, 0
        profile.options.point, profile.options.relativePoint, profile.options.x, profile.options.y = "CENTER", "CENTER", 0, 0
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
    self:Apply()
end

function LayoutCoordinator:OnInitialize()
    self.eventFrame = CreateFrame("Frame", "KWR_LayoutCoordinatorEvents")
    self.eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    self.eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    self.eventFrame:SetScript("OnEvent", function() LayoutCoordinator:Apply() end)
    self.eventFrame:SetScript("OnUpdate", function(_, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.25 then return end
        self.elapsed = 0
        self:Apply()
    end)
end

KWR:RegisterModule("LayoutCoordinator", LayoutCoordinator)
