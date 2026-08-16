local _, KWR = ...

local Options = {}
KWR.Options = Options

local ACCESSIBILITY_RELOAD_POPUP = "KWR_ACCESSIBILITY_RELOAD"

local function requestAccessibilityReload()
    Options.reloadRequested = true
    if type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then
        KWR:Print("Reload the UI to apply high-contrast colors to every open KWR surface.", true)
        return
    end
    if not StaticPopupDialogs[ACCESSIBILITY_RELOAD_POPUP] then
        StaticPopupDialogs[ACCESSIBILITY_RELOAD_POPUP] = {
            text = "Reload the UI now to apply high-contrast colors to every KWR window?",
            button1 = ACCEPT or "Reload UI",
            button2 = CANCEL or "Later",
            OnAccept = function()
                if type(ReloadUI) == "function" then ReloadUI() end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show(ACCESSIBILITY_RELOAD_POPUP)
end

local function createOptionCard(parent, title, summary, x, y, width, height)
    local card = KWR.Theme:Card(parent, title)
    card:SetPoint("TOPLEFT", x, y)
    card:SetSize(width, height)
    card.kwrGeometry = { title = title, x = x, y = y, width = width, height = height }
    if type(parent.kwrCards) == "table" then
        parent.kwrCards[#parent.kwrCards + 1] = card.kwrGeometry
    end
    card.summary = KWR.Theme:Font(card, 8, "muted", "LEFT")
    card.summary:SetPoint("TOPLEFT", 10, -34)
    card.summary:SetPoint("TOPRIGHT", -10, -34)
    card.summary:SetHeight(30)
    if card.summary.SetWordWrap then card.summary:SetWordWrap(true) end
    if card.summary.SetNonSpaceWrap then card.summary:SetNonSpaceWrap(true) end
    card.summary:SetText(summary)
    return card
end

local function registerCheck(self, key, check, getter, setter, options)
    self.checks = self.checks or {}
    self.namedChecks = self.namedChecks or {}
    local entry = {
        key = key,
        check = check,
        getter = getter,
        setter = setter,
        label = options and options.label or key,
        group = options and options.group or "",
        summary = options and options.summary or "",
        unavailableText = options and options.unavailableText or nil,
        available = options and options.available or nil,
        allowToggleWhenUnavailable = options and options.allowToggleWhenUnavailable == true,
    }
    self.checks[#self.checks + 1] = entry
    self.namedChecks[key] = entry
    check:SetScript("OnClick", function(button)
        if button.kwrDisabled == true then
            button:SetChecked(getter() == true)
            return
        end
        local value = button:GetChecked() == true
        if setter(value) == false then
            button:SetChecked(not value)
            return
        end
        button:SetChecked(getter() == true)
    end)
end

local function createCheck(self, parent, key, label, summary, y, getter, setter, options)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 10, y)
    check:SetSize(24, 24)
    check.label = KWR.Theme:Font(parent, 10, "white")
    check.label:SetPoint("TOPLEFT", check, "TOPRIGHT", 8, -1)
    check.label:SetWidth((parent:GetWidth() or 300) - 52)
    check.label:SetHeight(16)
    check.label:SetText(label)
    check.summary = KWR.Theme:Font(parent, 8, "muted")
    check.summary:SetPoint("TOPLEFT", check.label, "BOTTOMLEFT", 0, -1)
    check.summary:SetPoint("TOPRIGHT", -10, 0)
    check.summary:SetHeight(30)
    if check.summary.SetNonSpaceWrap then
        check.summary:SetNonSpaceWrap(true)
    end
    check.summary:SetText(summary)
    registerCheck(self, key, check, getter, setter, {
        label = label,
        group = parent and parent.heading and parent.heading:GetText() or "",
        summary = summary,
        unavailableText = options and options.unavailableText or nil,
        available = options and options.available or nil,
        allowToggleWhenUnavailable = options and options.allowToggleWhenUnavailable == true,
    })
    return check
end

function Options:Refresh()
    for _, entry in ipairs(self.checks or {}) do
        entry.check:SetChecked(entry.getter() == true)
        local available = true
        if type(entry.available) == "function" then
            available = entry.available() ~= false
        end
        entry.check.kwrDisabled = available ~= true
            and entry.allowToggleWhenUnavailable ~= true
        if entry.check.label and entry.check.label.SetTextColor then
            local labelTone = (available or entry.allowToggleWhenUnavailable)
                and "white" or "muted"
            entry.check.label:SetTextColor(KWR.Theme:Color(labelTone))
        end
        if entry.check.summary and entry.check.summary.SetText then
            entry.check.summary:SetText(available and entry.summary
                or KWR.Util:Text(entry.unavailableText, entry.summary, 120))
            if entry.check.summary.SetTextColor then
                entry.check.summary:SetTextColor(KWR.Theme:Color(available and "muted" or "orange"))
            end
        end
    end
end

function Options:Close()
    local frame = self.frame
    if frame and frame:IsShown() then
        frame:Hide()
    end
end

function Options:PrepareModal()
    -- The launcher is an optional command surface. Keeping it open behind the
    -- settings dialog makes the two KWR windows compete for clicks and puts
    -- the close button beneath unrelated UI during combat.
    local launcher = KWR.MainWindow and KWR.MainWindow.launcherMenu
    if launcher and launcher:IsShown() then
        launcher:Hide()
    end
end

function Options:Create()
    if self.frame then return self.frame end

    local profile = KWR.db.profile.options
    local frame = CreateFrame("Frame", "KWR_OptionsWindow", UIParent, "BackdropTemplate")
    frame:SetSize(780, 980)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "gold")
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()

    frame.title = KWR.Theme:Title(frame, 17)
    frame.title:SetPoint("TOPLEFT", 16, -14)
    frame.title:SetText("KWR COMMAND CENTER OPTIONS")
    frame.subtitle = KWR.Theme:Font(frame, 9, "soft", "LEFT", "OUTLINE")
    frame.subtitle:SetPoint("TOPLEFT", 18, -38)
    frame.subtitle:SetText("RBG-focused controls only. PvE and arena stay silent.")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        Options:Close()
    end)
    frame.closeButton = close

    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 14, -66)
    frame.scroll:SetPoint("BOTTOMRIGHT", -30, 16)
    if frame.scroll.EnableMouseWheel then
        frame.scroll:EnableMouseWheel(true)
        frame.scroll:SetScript("OnMouseWheel", function(self, delta)
            if not self.GetVerticalScroll or not self.SetVerticalScroll then return end
            local current = self:GetVerticalScroll() or 0
            self:SetVerticalScroll(math.max(0, current - (delta * 32)))
        end)
    end

    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.content:SetSize(724, 1228)
    frame.content.kwrCards = {}
    if frame.scroll.SetScrollChild then
        frame.scroll:SetScrollChild(frame.content)
    end

    local content = frame.content

    local commandCard = createOptionCard(content,
        "Command Surfaces",
        "Core commander windows, call density, and review text behavior.",
        0, 0, 342, 390)
    createCheck(self, commandCard,
        "hudEnabled",
        "Show compact command center",
        "Shows the compact KWR command-center view in battlegrounds and world/group-build setup, but not arena or PvE instances.",
        -72,
        function() return KWR.db.profile.hud.enabled end,
        function(value) KWR.HUD:SetEnabled(value) end)
    createCheck(self, commandCard,
        "hudLocked",
        "Lock compact center position",
        "Prevents accidental drag movement of the compact command-center window.",
        -122,
        function() return KWR.db.profile.hud.locked end,
        function(value) KWR.db.profile.hud.locked = value end)
    createCheck(self, commandCard,
        "mainLocked",
        "Lock command center position",
        "Prevents drag movement of the main tactical board.",
        -172,
        function() return KWR.db.profile.main.locked end,
        function(value) KWR.db.profile.main.locked = value end)
    createCheck(self, commandCard,
        "learningMode",
        "Show learning explanations",
        "Adds switch and rationale language to command views for review.",
        -222,
        function() return KWR.db.profile.guidanceMode == "LEARNING" end,
        function(value)
            KWR.db.profile.guidanceMode = value and "LEARNING" or "COMMAND"
            KWR.MatchRuntime:ForceRefresh("guidance-mode")
        end)
    createCheck(self, commandCard,
        "commandAudio",
        "Speak synchronized command calls",
        "Speaks authoritative pickup, healer-control, kill-target, and trigger changes once per synchronized command revision.",
        -272,
        function() return KWR.CommandAudio and KWR.CommandAudio:IsEnabled() end,
        function(value) return KWR.CommandAudio and KWR.CommandAudio:SetEnabled(value) end,
        {
            available = function()
                return KWR.SafeSpeechAdapter and KWR.SafeSpeechAdapter:IsAvailable()
            end,
            unavailableText = "WoW text-to-speech playback is unavailable on this client.",
            allowToggleWhenUnavailable = true,
        })
    createCheck(self, commandCard,
        "sentinelTransport",
        "Enable Sentinel team bridge",
        "Accepts roster-validated Sentinel observations and sends personal relays. Turning it off clears all remote bridge state immediately.",
        -322,
        function() return KWR.CommanderComm and KWR.CommanderComm:TransportEnabled() end,
        function(value) return KWR.CommanderComm and KWR.CommanderComm:SetTransportEnabled(value) end)
    createCheck(self, commandCard,
        "hudFocusMode",
        "Use minimal live combat mode",
        "Shows only your next action and an actionable local target/peel cue during battleground combat.",
        -372,
        function() return KWR.db.profile.hud.focusMode == true end,
        function(value)
            KWR.db.profile.hud.focusMode = value == true
            if KWR.HUD then KWR.HUD:Invalidate(); KWR.HUD:Update(KWR.Store:Get()) end
        end)

    local targetCard = createOptionCard(content,
        "Targeting And Overlays",
        "Cursor ring, reticle, guide lines, and live nameplate overlays.",
        366, 0, 342, 550)
    createCheck(self, targetCard,
        "cursorEnabled",
        "Enable cursor ring",
        "Shows the battlefield cursor ring while KWR is active.",
        -72,
        function() return KWR.db.profile.cursor.enabled end,
        function(value) KWR.CursorRing:SetEnabled(value) end)
    createCheck(self, targetCard,
        "reticleEnabled",
        "Enable target command reticle",
        "Shows the target reticle on your current enemy target.",
        -126,
        function() return KWR.db.profile.cursor.reticleEnabled ~= false end,
        function(value) KWR.CursorRing:SetReticleEnabled(value) end,
        {
            available = function() return KWR.db.profile.cursor.enabled == true end,
            unavailableText = "Requires cursor ring.",
            allowToggleWhenUnavailable = true,
        })
    createCheck(self, targetCard,
        "reticleGuides",
        "Show target-axis guides",
        "Shows one subtle horizontal and vertical axis through the selected target lock.",
        -180,
        function() return KWR.db.profile.cursor.reticleGuides ~= false end,
        function(value) KWR.CursorRing:SetReticleGuides(value) end,
        {
            available = function()
                return KWR.db.profile.cursor.enabled == true
                    and KWR.db.profile.cursor.reticleEnabled ~= false
            end,
            unavailableText = "Requires cursor ring and reticle.",
            allowToggleWhenUnavailable = true,
        })
    createCheck(self, targetCard,
        "focusNameplates",
        "Focus target health bar only",
        "Hides non-target hostile health/name readouts and keeps class shields visible.",
        -234,
        function() return KWR.db.profile.cursor.focusNameplates ~= false end,
        function(value)
            KWR.db.profile.cursor.focusNameplates = value == true
            KWR.CursorRing:RefreshOrbs()
        end,
        {
            available = function() return KWR.db.profile.cursor.enabled == true end,
            unavailableText = "Requires cursor ring.",
            allowToggleWhenUnavailable = true,
        })
    createCheck(self, targetCard,
        "battlefieldOrbs",
        "Show always-on player identity markers",
        "Shows circular class icons above every visible player. Friendly healers use a role icon; orb and flag carriers replace the normal identity icon. Blizzard nameplates remain visible.",
        -288,
        function() return KWR.db.profile.cursor.battlefieldOrbs ~= false end,
        function(value) KWR.CursorRing:SetBattlefieldOrbs(value) end)
    createCheck(self, targetCard,
        "assignmentBadges",
        "Show tactical assignment badges",
        "Shows a compact DEFEND, STRIKE, ESCORT, ROTATE, RESERVE, HEAL, or CARRY badge on assigned friendly nameplates.",
        -342,
        function() return KWR.db.profile.cursor.assignmentBadges ~= false end,
        function(value) KWR.CursorRing:SetAssignmentBadges(value) end)
    createCheck(self, targetCard,
        "combatVisuals",
        "Show target spotlight and cast accents",
        "Enables kill-target glow and must-stop cast accents on the roster.",
        -396,
        function() return KWR.db.profile.combatRoster.combatVisuals ~= false end,
        function(value)
            KWR.db.profile.combatRoster.combatVisuals = value
            if KWR.CombatRoster and (KWR.CombatRoster.teamFrame or KWR.CombatRoster.enemyFrame) then
                KWR.CombatRoster:Layout(KWR.db.profile.combatRoster.mode or "BOTH")
            end
        end)
    createCheck(self, targetCard,
        "arenaLightweight",
        "Keep lightweight target layer in arenas",
        "Hides Commander boards and rosters while retaining only legal player nameplate markers and the target reticle.",
        -450,
        function() return KWR.db.profile.cursor.arenaLightweight ~= false end,
        function(value) KWR.CursorRing:SetArenaLightweight(value) end)
    createCheck(self, targetCard,
        "worldPvPReticle",
        "Keep target reticle in world PvP",
        "Shows the KWR target reticle only for attackable player targets outside instances. It never changes TAB bindings or targets mobs/pets.",
        -504,
        function() return KWR.db.profile.cursor.worldPvPReticle ~= false end,
        function(value) KWR.CursorRing:SetWorldPvPReticle(value) end)

    local reviewCard = createOptionCard(content,
        "Review And AAR",
        "Controls onboarding messages, manual evidence capture, and safe preview behavior.",
        0, -408, 342, 316)
    createCheck(self, reviewCard,
        "showLoadMessage",
        "Show login message",
        "Shows a KWR chat message when the addon initializes.",
        -72,
        function() return KWR.db.profile.showLoadMessage end,
        function(value) KWR.db.profile.showLoadMessage = value end)
    createCheck(self, reviewCard,
        "aarAutoOpen",
        "Auto-open After Action Review",
        "Opens the AAR window automatically when a battleground ends.",
        -122,
        function() return KWR.db.profile.aar.autoOpen end,
        function(value) KWR.db.profile.aar.autoOpen = value end,
        {
            available = function() return KWR.db.profile.aar.enabled ~= false end,
            unavailableText = "Requires AAR evidence capture. Re-enable manual AAR exports first.",
        })
    createCheck(self, reviewCard,
        "aarEnabled",
        "Record manual AAR evidence exports",
        "Keeps the manual evidence export path available for reviewed match capture.",
        -172,
        function() return KWR.db.profile.aar.enabled end,
        function(value)
            KWR.db.profile.aar.enabled = value
            if not value and KWR.AAR and KWR.AAR.CommitInterrupted then
                KWR.AAR:CommitInterrupted(
                    "AAR capture was disabled before battleground completion.")
            end
        end)
    if KWR.BuildInfo and KWR.BuildInfo:HasPreview() then
        createCheck(self, reviewCard,
            "previewEnabled",
            "Enable design preview outside battlegrounds",
            "Allows preview mode only outside live battleground data.",
            -222,
            function() return KWR.db.profile.preview end,
            function(value)
                local context = KWR.Store:Get().snapshot.context
                if value and context.inPvP and not context.preview then
                    KWR.db.profile.preview = false
                    KWR:Print("Preview cannot replace live battleground data.", true)
                    return false
                end
                KWR.db.profile.preview = value
                KWR.MatchRuntime:ForceRefresh("options-preview")
                KWR.MainWindow:Show("TACTICAL")
            end)
    end

    local presentationCard = createOptionCard(content,
        "Battleground Auto-Show",
        "Auto-manages KWR command surfaces. Use Shift-M for the native battlefield map.",
        0, -742, 342, 196)
    createCheck(self, presentationCard,
        "presentationEnabled",
        "Auto-manage compact battleground surfaces",
        "Lets KWR auto-show and restore its compact command surfaces during RBG play.",
        -72,
        function() return KWR.db.profile.presentation.enabled ~= false end,
        function(value)
            KWR.db.profile.presentation.enabled = value
            if KWR.Presentation then KWR.Presentation:RefreshNow() end
        end)
    local rosterCard = createOptionCard(content,
        "Combat Roster",
        "Controls the combat-roster auto-show owner and position locks.",
        366, -574, 342, 216)
    createCheck(self, rosterCard,
        "rosterAutoShow",
        "Auto-show combat roster when battleground begins",
        "This is the single owner for combat-roster auto-show during battleground play.",
        -72,
        function() return KWR.db.profile.combatRoster.autoShowInPvP end,
        function(value) KWR.db.profile.combatRoster.autoShowInPvP = value end)
    createCheck(self, rosterCard,
        "rosterLocked",
        "Lock compact combat roster position",
        "Prevents drag movement of compact roster windows.",
        -132,
        function() return KWR.db.profile.combatRoster.locked end,
        function(value) KWR.db.profile.combatRoster.locked = value end)
    local utilityCard = createOptionCard(content,
        "Utilities",
        "Reset positions and tune readability for KWR-owned windows.",
        366, -868, 342, 220)
    local reset = KWR.Theme:Button(utilityCard, "Reset Window Positions", 168, 28, function()
        if KWR.LayoutCoordinator and KWR.LayoutCoordinator.Reset then
            KWR.LayoutCoordinator:Reset()
            return
        end
        local main = KWR.db.profile.main
        main.point, main.relativePoint, main.x, main.y = "CENTER", "CENTER", 0, 0
        if KWR.MainWindow and KWR.MainWindow.frame then
            KWR.MainWindow.frame:ClearAllPoints()
            KWR.MainWindow.frame:SetPoint("CENTER")
        end

        local hud = KWR.db.profile.hud
        hud.point, hud.relativePoint, hud.x, hud.y = "CENTER", "CENTER", -440, 0
        if KWR.HUD and KWR.HUD.frame then
            KWR.HUD.frame:ClearAllPoints()
            KWR.HUD.frame:SetPoint("CENTER", UIParent, "CENTER", -440, 0)
        end

        local launcher = KWR.db.profile.launcher
        launcher.angle = 225
        if KWR.MainWindow and KWR.MainWindow.launcher then
            KWR.MainWindow:PositionLauncher()
        end

        local roster = KWR.db.profile.combatRoster
        roster.point, roster.relativePoint, roster.x, roster.y = "CENTER", "CENTER", 0, 140
        roster.layoutVersion = 3
        roster.teamMini.point, roster.teamMini.relativePoint = "CENTER", "CENTER"
        roster.teamMini.x, roster.teamMini.y = -170, 140
        roster.enemyMini.point, roster.enemyMini.relativePoint = "CENTER", "CENTER"
        roster.enemyMini.x, roster.enemyMini.y = 170, 140
        if KWR.CombatRoster and (KWR.CombatRoster.teamFrame or KWR.CombatRoster.enemyFrame) then
            if KWR.CombatRoster.teamFrame then
                KWR.CombatRoster.teamFrame:ClearAllPoints()
                KWR.CombatRoster.teamFrame:SetPoint("CENTER", UIParent, "CENTER", -170, 140)
            end
            if KWR.CombatRoster.enemyFrame then
                KWR.CombatRoster.enemyFrame:ClearAllPoints()
                KWR.CombatRoster.enemyFrame:SetPoint("CENTER", UIParent, "CENTER", 170, 140)
            end
            KWR.CombatRoster:Layout(KWR.db.profile.combatRoster.mode or "BOTH")
        end
    end)
    reset:SetPoint("TOPLEFT", 10, -74)
    createCheck(self, utilityCard,
        "highContrast",
        "Use high-contrast text",
        "Brightens secondary text and panel boundaries. Requires a UI reload; KWR will ask first.",
        -120,
        function() return KWR.db.profile.accessibility.highContrast == true end,
        function(value)
            value = value == true
            if KWR.db.profile.accessibility.highContrast ~= value then
                KWR.db.profile.accessibility.highContrast = value
                requestAccessibilityReload()
            end
        end)
    local diagnostics = KWR.Theme:Button(utilityCard, "Copy Field Diagnostic", 168, 28, function()
        if KWR.Verification and KWR.Verification.FieldReport then
            KWR.CopyDialog:ShowText("KWR Field Diagnostic",
                KWR.Verification:FieldReport(), {
                    note = "Local diagnostic only. It records data coverage, refresh health, and safe observation state for field testing.",
                })
        end
    end)
    diagnostics:SetPoint("TOPLEFT", 10, -174)

    local footerCard = createOptionCard(content,
        "Policy",
        "KWR safety and visibility rules stay fixed regardless of battleground setup.",
        0, -1102, 708, 112)
    frame.note = KWR.Theme:Font(footerCard, 9, "muted")
    frame.note:SetPoint("TOPLEFT", 10, -40)
    frame.note:SetPoint("TOPRIGHT", -10, -40)
    frame.note:SetHeight(42)
    frame.note:SetText("KWR never sends chat automatically, changes keybinds, or invents combat facts. Arena and PvE instance behavior stay silent.")
    frame.footerCard = footerCard

    frame:SetScript("OnShow", function()
        Options:PrepareModal()
        Options:Refresh()
    end)

    if type(UISpecialFrames) == "table" then
        local known = false
        for _, name in ipairs(UISpecialFrames) do
            if name == frame:GetName() then
                known = true
                break
            end
        end
        if not known then table.insert(UISpecialFrames, frame:GetName()) end
    end

    self.frame = frame
    return frame
end

function Options:Inventory()
    local rows = {}
    for _, entry in ipairs(self.checks or {}) do
        local available = true
        if type(entry.available) == "function" then
            available = entry.available() ~= false
        end
        rows[#rows + 1] = {
            key = entry.key,
            label = entry.label,
            group = entry.group,
            enabled = entry.getter() == true,
            available = available,
            summary = entry.summary,
            unavailableText = entry.unavailableText,
        }
    end
    return rows
end

function Options:LayoutAudit()
    local cards = self.frame and self.frame.content and self.frame.content.kwrCards or {}
    local issues = {}
    for i = 1, #cards do
        local a = cards[i]
        for j = i + 1, #cards do
            local b = cards[j]
            local separateX = (a.x + a.width) <= b.x or (b.x + b.width) <= a.x
            local aTop, aBottom = a.y, a.y - a.height
            local bTop, bBottom = b.y, b.y - b.height
            local separateY = aBottom >= bTop or bBottom >= aTop
            if not separateX and not separateY then
                issues[#issues + 1] = a.title .. " overlaps " .. b.title
            end
        end
    end
    return {
        cards = #cards,
        issues = issues,
        ok = #issues == 0,
    }
end

function Options:Toggle()
    local frame = self:Create()
    if frame:IsShown() then
        self:Close()
    else
        self:PrepareModal()
        frame:Show()
        self:Refresh()
    end
end

function Options:OnInitialize()
    -- Created on first open.
end

KWR:RegisterModule("Options", Options)
