local _, KWR = ...

local Options = {}
KWR.Options = Options

local function createCheck(parent, label, y, getter, setter)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 18, y)
    check:SetSize(24, 24)
    check.label = KWR.Theme:Font(parent, 11, "white")
    check.label:SetPoint("LEFT", check, "RIGHT", 8, 0)
    check.label:SetText(label)
    check:SetChecked(getter())
    check:SetScript("OnClick", function(self)
        local value = self:GetChecked() == true
        if setter(value) == false then self:SetChecked(not value) end
    end)
    return check
end

function Options:Create()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KWR_OptionsWindow", UIParent, "BackdropTemplate")
    frame:SetSize(460, 620)
    frame:SetPoint("CENTER", UIParent, "CENTER", 360, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "gold")
    frame:Hide()

    frame.title = KWR.Theme:Title(frame, 17)
    frame.title:SetPoint("TOPLEFT", 16, -14)
    frame.title:SetText("KWR OPTIONS")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    createCheck(frame, "Show command HUD", -52,
        function() return KWR.db.profile.hud.enabled end,
        function(value) KWR.HUD:SetEnabled(value) end)

    createCheck(frame, "Lock HUD position", -84,
        function() return KWR.db.profile.hud.locked end,
        function(value) KWR.db.profile.hud.locked = value end)

    createCheck(frame, "Lock Command Center position", -116,
        function() return KWR.db.profile.main.locked end,
        function(value) KWR.db.profile.main.locked = value end)

    createCheck(frame, "Enable Cursor Ring", -148,
        function() return KWR.db.profile.cursor.enabled end,
        function(value) KWR.CursorRing:SetEnabled(value) end)

    createCheck(frame, "Show login message", -180,
        function() return KWR.db.profile.showLoadMessage end,
        function(value) KWR.db.profile.showLoadMessage = value end)

    createCheck(frame, "Auto-open After Action Review", -212,
        function() return KWR.db.profile.aar.autoOpen end,
        function(value) KWR.db.profile.aar.autoOpen = value end)

    createCheck(frame, "Record manual AAR evidence exports", -244,
        function() return KWR.db.profile.aar.enabled end,
        function(value)
            KWR.db.profile.aar.enabled = value
            if not value then KWR.AAR.active = nil end
        end)

    createCheck(frame, "Enable design preview outside battlegrounds", -276,
        function() return KWR.db.profile.preview end,
        function(value)
            local context = KWR.Store:Get().snapshot.context
            if value and context.inPvP and not context.preview then
                KWR.db.profile.preview = false
                KWR:Print("Preview cannot replace live battleground truth.", true)
                return false
            end
            KWR.db.profile.preview = value
            KWR.MatchRuntime:ForceRefresh("options-preview")
            KWR.MainWindow:Show("TACTICAL")
        end)

    createCheck(frame, "Lock Reporter mini-map position", -308,
        function() return KWR.db.profile.reporter.locked end,
        function(value) KWR.db.profile.reporter.locked = value end)

    createCheck(frame, "Auto-show combat roster when battleground begins", -340,
        function() return KWR.db.profile.combatRoster.autoShowInPvP end,
        function(value) KWR.db.profile.combatRoster.autoShowInPvP = value end)

    createCheck(frame, "Lock compact combat roster position", -372,
        function() return KWR.db.profile.combatRoster.locked end,
        function(value) KWR.db.profile.combatRoster.locked = value end)

    createCheck(frame, "Show target spotlight and priority-cast accents", -404,
        function() return KWR.db.profile.combatRoster.combatVisuals ~= false end,
        function(value)
            KWR.db.profile.combatRoster.combatVisuals = value
            if KWR.CombatRoster.frame then
                KWR.CombatRoster:Layout(
                    KWR.db.profile.combatRoster.mode or "BOTH")
            end
        end)

    createCheck(frame, "Show learning explanations in command views", -436,
        function() return KWR.db.profile.guidanceMode == "LEARNING" end,
        function(value)
            KWR.db.profile.guidanceMode = value and "LEARNING" or "COMMAND"
            KWR.MatchRuntime:ForceRefresh("guidance-mode")
        end)

    local reset = KWR.Theme:Button(frame, "Reset Window Positions", 170, 28, function()
        local main = KWR.db.profile.main
        main.point, main.relativePoint, main.x, main.y = "CENTER", "CENTER", 0, 0
        KWR.MainWindow.frame:ClearAllPoints()
        KWR.MainWindow.frame:SetPoint("CENTER")
        local hud = KWR.db.profile.hud
        hud.point, hud.relativePoint, hud.x, hud.y = "CENTER", "CENTER", -440, 0
        KWR.HUD.frame:ClearAllPoints()
        KWR.HUD.frame:SetPoint("CENTER", UIParent, "CENTER", -440, 0)
        local launcher = KWR.db.profile.launcher
        launcher.angle = 225
        if KWR.MainWindow.launcher then
            KWR.MainWindow:PositionLauncher()
        end
        local reporter = KWR.db.profile.reporter
        reporter.point, reporter.relativePoint, reporter.x, reporter.y = "CENTER", "CENTER", 430, 0
        if KWR.ReporterMap and KWR.ReporterMap.frame then
            KWR.ReporterMap.frame:ClearAllPoints()
            KWR.ReporterMap.frame:SetPoint("CENTER", UIParent, "CENTER", 430, 0)
        end
        local roster = KWR.db.profile.combatRoster
        roster.point, roster.relativePoint, roster.x, roster.y = "CENTER", "CENTER", 0, 140
        if KWR.CombatRoster and KWR.CombatRoster.frame then
            KWR.CombatRoster.frame:ClearAllPoints()
            KWR.CombatRoster.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
        end
    end)
    reset:SetPoint("TOPLEFT", 18, -488)

    frame.note = KWR.Theme:Font(frame, 10, "muted")
    frame.note:SetPoint("TOPLEFT", 18, -536)
    frame.note:SetPoint("TOPRIGHT", -18, -536)
    frame.note:SetText("KWR never sends chat, changes keybinds, or invents combat facts. Compact row clicks use Blizzard secure buttons and require your hardware click. Preview is always marked NOT LIVE.")

    self.frame = frame
    return frame
end

function Options:Toggle()
    local frame = self:Create()
    frame:SetShown(not frame:IsShown())
end

function Options:OnInitialize()
    -- Created on first open.
end

KWR:RegisterModule("Options", Options)
