local _, KWR = ...

local MainWindowLauncher = {}
KWR.MainWindowLauncher = MainWindowLauncher

local function singleLine(font)
    if not font then return end
    if font.SetWordWrap then font:SetWordWrap(false) end
    if font.SetNonSpaceWrap then font:SetNonSpaceWrap(false) end
    if font.SetMaxLines then font:SetMaxLines(1) end
end

function MainWindowLauncher:Create(owner)
    if owner.launcher then return end
    local profile = KWR.db.profile.launcher
    local button = CreateFrame("Button", "KWR_Launcher", UIParent, "BackdropTemplate")
    -- The launcher sits just outside the minimap; make the affordance readable
    -- at normal UI scale without covering the map itself.
    button:SetSize(42, 42)
    button:SetFrameStrata("HIGH")
    KWR.Theme:Style(button, "background", "borderHi")
    button.shadow = button:CreateTexture(nil, "BACKGROUND")
    button.shadow:SetPoint("TOPLEFT", 2, -2)
    button.shadow:SetPoint("BOTTOMRIGHT", -2, 2)
    button.shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.shadow:SetVertexColor(0, 0, 0, 0.42)

    button.outer = button:CreateTexture(nil, "ARTWORK")
    button.outer:SetPoint("TOPLEFT", 3, -3)
    button.outer:SetPoint("BOTTOMRIGHT", -3, 3)
    button.outer:SetTexture("Interface\\Buttons\\WHITE8X8")

    button.inner = button:CreateTexture(nil, "OVERLAY")
    button.inner:SetPoint("TOPLEFT", 5, -5)
    button.inner:SetPoint("BOTTOMRIGHT", -5, 5)
    button.inner:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.brand = button:CreateTexture(nil, "ARTWORK")
    button.brand:SetPoint("CENTER", 0, 1)
    button.brand:SetSize(24, 24)
    if KWR.Icons then
        KWR.Icons:ApplyBrand(button.brand, "sigil")
    end

    button.disc = button:CreateTexture(nil, "BORDER")
    button.disc:SetPoint("TOPLEFT", 7, -7)
    button.disc:SetPoint("BOTTOMRIGHT", -7, 7)
    button.disc:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.disc:SetVertexColor(0.015, 0.018, 0.022, 0.96)
    button.pulse = button:CreateTexture(nil, "OVERLAY")
    button.pulse:SetPoint("BOTTOMLEFT", 7, 7)
    button.pulse:SetPoint("BOTTOMRIGHT", -7, 7)
    button.pulse:SetHeight(2)
    button.pulse:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints(button.inner)
    button.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.highlight:SetVertexColor(1, 0.72, 0.08, 0.08)
    button.text = KWR.Theme:Title(button, 10, "CENTER")
    button.text:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
    button.text:SetText("")
    button.tag = KWR.Theme:Font(button, 5, "gold", "CENTER", "OUTLINE")
    button.tag:SetPoint("TOP", button, "BOTTOM", 0, 1)
    button.tag:SetWidth(52)
    button.tag:SetHeight(8)
    button.tag:Hide()
    button.statusDot = button:CreateTexture(nil, "OVERLAY")
    button.statusDot:SetPoint("TOPRIGHT", -4, -4)
    button.statusDot:SetSize(7, 7)
    button.statusDot:SetTexture("Interface\\Buttons\\WHITE8X8")
    owner.launcher = button
    owner:PositionLauncher()
    owner:UpdateLauncherVisual(KWR.Store and KWR.Store.Get and KWR.Store:Get() or owner.lastState)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            owner:ToggleLauncherMenu()
        else
            if owner.launcherMenu then owner.launcherMenu:Hide() end
            owner:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        if not IsShiftKeyDown() or (InCombatLockdown and InCombatLockdown()) then return end
        if Minimap then
            self.dragging = true
            self:SetScript("OnUpdate", function()
                local cursorX, cursorY = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                local centerX, centerY = Minimap:GetCenter()
                cursorX, cursorY = cursorX / scale, cursorY / scale
                local dx, dy = cursorX - centerX, cursorY - centerY
                local angle
                if math.atan2 then
                    angle = math.deg(math.atan2(dy, dx))
                elseif dx == 0 then
                    angle = dy >= 0 and 90 or -90
                else
                    angle = math.deg(math.atan(dy / dx))
                    if dx < 0 then angle = angle + 180 end
                end
                profile.angle = angle
                owner:PositionLauncher()
            end)
        else
            self:StartMoving()
        end
    end)
    button:SetScript("OnDragStop", function(self)
        if self.dragging then
            self.dragging = false
            self:SetScript("OnUpdate", nil)
        else
            self:StopMovingOrSizing()
            local point, _, relativePoint, x, y = self:GetPoint(1)
            profile.point, profile.relativePoint, profile.x, profile.y = point, relativePoint, x, y
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local current = owner.lastState or (KWR.Store and KWR.Store.Get and KWR.Store:Get()) or {}
        local context = current and current.snapshot and current.snapshot.context or {}
        local command = current and current.command or {}
        GameTooltip:AddLine("Knomercy War Room")
        GameTooltip:AddLine(KWR.Util:Text(context.mapName,
            context.inPvP and "Battleground live." or "RBG setup.", 80), 1, 0.82, 0.25)
        if context.inPvP then
            GameTooltip:AddLine("Status: " .. KWR.Util:Text(command.status, "LIVE", 18)
                .. " / " .. KWR.Util:Text(command.confidence, "NONE", 18) .. " read",
                0.91, 0.92, 0.94)
        elseif context.preview then
            GameTooltip:AddLine("Status: PREVIEW / NOT LIVE", 1, 0.49, 0.17)
        else
            GameTooltip:AddLine("Status: SETUP / IDLE", 0.72, 0.74, 0.78)
        end
        GameTooltip:AddLine("Left-click: Command Center", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Command menu", 1, 1, 1)
        GameTooltip:AddLine("Shift-drag: Move around minimap", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function MainWindowLauncher:CreateMenu(owner)
    if owner.launcherMenu then return end
    local menu = CreateFrame("Frame", "KWR_LauncherMenu", UIParent, "BackdropTemplate")
    menu:SetSize(254, 452)
    menu:SetPoint("TOPRIGHT", owner.launcher, "BOTTOMLEFT", -8, 0)
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    KWR.Theme:Style(menu, "background", "borderHi")
    menu:Hide()
    menu.title = KWR.Theme:Title(menu, 13, "CENTER")
    menu.title:SetPoint("TOPLEFT", 10, -10)
    menu.title:SetPoint("TOPRIGHT", -10, -10)
    menu.brand = menu:CreateTexture(nil, "ARTWORK")
    menu.brand:SetPoint("TOPLEFT", 14, -12)
    menu.brand:SetSize(16, 16)
    if KWR.Icons then
        KWR.Icons:ApplyBrand(menu.brand, "mark")
    end
    menu.title:SetText("KWR COMMAND MENU")
    menu.stateBadge = KWR.Theme:Badge(menu, "muted", "IDLE", 88, 16)
    menu.stateBadge:SetPoint("TOP", menu, "TOP", -48, -34)
    menu.truthBadge = KWR.Theme:Badge(menu, "muted", "SETUP", 88, 16)
    menu.truthBadge:SetPoint("LEFT", menu.stateBadge, "RIGHT", 8, 0)
    menu.summary = KWR.Theme:Font(menu, 8, "soft", "LEFT", "OUTLINE")
    menu.summary:SetPoint("TOPLEFT", 14, -56)
    menu.summary:SetPoint("TOPRIGHT", -14, -56)
    menu.summary:SetHeight(40)
    menu.rule = menu:CreateTexture(nil, "ARTWORK")
    menu.rule:SetColorTexture(KWR.Theme:Color("border"))
    menu.rule:SetPoint("TOPLEFT", 14, -94)
    menu.rule:SetPoint("TOPRIGHT", -14, -94)
    menu.rule:SetHeight(1)
    local items = {
        { "WAR ROOM", "commander", function() owner:Show("TACTICAL") end },
        { "FIGHT NOW", "hold", function() KWR.HUD:Toggle() end },
        { "TEAM BOARD", "friendly", function() owner:Show("TEAM") end },
        { "MAP / SHIFT-M", "observed", function()
            KWR:Print("Press Shift-M for Blizzard's battlefield map.", true)
        end },
        { "ENEMY BOARD", "enemy", function() owner:Show("ENEMIES") end },
        { "REVIEW / AAR", "priority", function() owner:Show("INTEL") end },
        { "AAR EXPORT", "assignment", function() owner:Show("INTEL") end },
        { "VERIFY", "ready", function()
            KWR.CopyDialog:ShowText("KWR Live Verification", KWR.Verification:CurrentReport(), {
                note = "Summary first, raw details below. Scroll to inspect the full verification report.",
            })
        end },
    }
    menu.buttons = {}
    for index, item in ipairs(items) do
        local action = item[3]
        local button = KWR.Theme:Button(menu, item[1], 224, 29, function()
            menu:Hide()
            action()
        end)
        button:SetPoint("TOPLEFT", 14, -106 - ((index - 1) * 35))
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("LEFT", 8, 0)
        button.icon:SetSize(14, 14)
        if KWR.Icons then
            KWR.Icons:Apply(button.icon, item[2], 16)
        end
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
        button.label:SetPoint("RIGHT", -8, 0)
        button.label:SetJustifyH("LEFT")
        singleLine(button.label)
        menu.buttons[index] = button
    end
    menu.footerRule = menu:CreateTexture(nil, "ARTWORK")
    menu.footerRule:SetColorTexture(KWR.Theme:Color("border"))
    menu.footerRule:SetPoint("BOTTOMLEFT", 14, 54)
    menu.footerRule:SetPoint("BOTTOMRIGHT", -14, 54)
    menu.footerRule:SetHeight(1)
    local settings = KWR.Theme:Button(menu, "SETTINGS", 108, 26, function()
        menu:Hide()
        KWR.Options:Toggle()
    end)
    settings:SetPoint("BOTTOMLEFT", 14, 14)
    local close = KWR.Theme:Button(menu, "CLOSE MENU", 108, 26, function() menu:Hide() end)
    close:SetPoint("BOTTOMRIGHT", -14, 14)
    menu.settingsButton = settings
    menu.closeButton = close
    owner.launcherMenu = menu
end

function MainWindowLauncher:ToggleMenu(owner, helpers)
    local state = owner.lastState or (KWR.Store and KWR.Store.Get and KWR.Store:Get()) or {}
    if not KWR.Util:AllowsCommandSurfaces(state)
        or KWR.Util:IsArenaContext(state) then
        if owner.launcherMenu then owner.launcherMenu:Hide() end
        return
    end
    self:CreateMenu(owner)
    local tone, tag = helpers.commandBadgeState(state)
    owner.launcherMenu.stateBadge:SetTone(tone)
    owner.launcherMenu.stateBadge:SetText(tag)
    owner.launcherMenu.truthBadge:SetTone(state.snapshot.context.preview and "orange"
        or (helpers.truthLabel(state.snapshot.objectives.source) == "LIVE UI" and "green"
            or (helpers.truthLabel(state.snapshot.objectives.source) == "OBSERVED" and "yellow" or "muted")))
    owner.launcherMenu.truthBadge:SetText(state.snapshot.context.preview and "PREVIEW"
        or helpers.truthLabel(state.snapshot.objectives.source))
    owner.launcherMenu.summary:SetText(KWR.MainWindowShell:LauncherMenuSummary(state))
    owner.launcherMenu:SetShown(not owner.launcherMenu:IsShown())
end