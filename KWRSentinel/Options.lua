local _, Sentinel = ...

local Options = {}
Sentinel.Options = Options

local function createCheck(parent, text, x, y, getter, setter)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", x, y)
    check.label = Sentinel.Theme:Font(parent, 10, "text", "LEFT", "OUTLINE")
    check.label:SetPoint("LEFT", check, "RIGHT", 6, 0)
    check.label:SetText(text)
    check.getter = getter
    check.setter = setter
    check:SetScript("OnClick", function(selfButton)
        selfButton.setter(selfButton:GetChecked() == true)
        Options:Refresh()
    end)
    return check
end

local function section(parent, title, x, y, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", x, y)
    frame:SetSize(width, height)
    Sentinel.Theme:Style(frame, "panel", "border")
    frame.title = Sentinel.Theme:Font(frame, 10, "accent", "LEFT", "OUTLINE")
    frame.title:SetPoint("TOPLEFT", 10, -8)
    frame.title:SetText(title)
    return frame
end

function Options:Refresh()
    for _, check in ipairs(self.checks or {}) do
        check:SetChecked(check.getter() == true)
    end
    if self.frame and self.frame.note then
        local pvpTabTarget = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("PVPTabTarget")
        local tabLine = pvpTabTarget
            and "PvP Tab Target addon detected: keep using it separately. Sentinel will not override Tab."
            or "PvP Tab Target is not built into Sentinel. Sentinel will not override Tab."
        self.frame.note:SetText("Crosshair cue is supported as a local visual aid. "
            .. tabLine
            .. " Protected targeting automation remains disabled by design and by repository validation.")
    end
end

function Options:Create()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KWRSentinel_OptionsWindow", UIParent, "BackdropTemplate")
    frame:SetSize(520, 404)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame) selfFrame:StartMoving() end)
    frame:SetScript("OnDragStop", function(selfFrame) selfFrame:StopMovingOrSizing() end)
    Sentinel.Theme:Style(frame, "background", "accent")
    frame:Hide()

    frame.title = Sentinel.Theme:Font(frame, 14, "accent", "LEFT", "OUTLINE")
    frame.title:SetPoint("TOPLEFT", 14, -12)
    frame.title:SetText("KWR SENTINEL OPTIONS")
    frame.subtitle = Sentinel.Theme:Font(frame, 8, "muted", "LEFT", "OUTLINE")
    frame.subtitle:SetPoint("TOPLEFT", 14, -32)
    frame.subtitle:SetText("Player-safe commander-linked helper surfaces only.")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    self.checks = {}

    local surfaces = section(frame, "SURFACES", 12, -54, 238, 186)
    self.checks[#self.checks + 1] = createCheck(surfaces, "Show execution card", 8, -30,
        function() return Sentinel.db.profile.hud.enabled == true end,
        function(value) Sentinel.db.profile.hud.enabled = value; Sentinel.HUD:Update() end)
    self.checks[#self.checks + 1] = createCheck(surfaces, "Show crosshair cue", 8, -58,
        function() return Sentinel.db.profile.targetCue.enabled ~= false end,
        function(value) Sentinel.db.profile.targetCue.enabled = value; Sentinel.HUD:Update() end)
    self.checks[#self.checks + 1] = createCheck(surfaces, "Show status helper", 8, -86,
        function() return Sentinel.db.profile.panels.status.enabled == true end,
        function(value) Sentinel.db.profile.panels.status.enabled = value; Sentinel.Panels:Update() end)
    local utility = section(frame, "UTILITY", 266, -54, 238, 186)
    self.checks[#self.checks + 1] = createCheck(utility, "Show minimap button", 8, -30,
        function() return Sentinel.db.profile.minimap.enabled == true end,
        function(value) Sentinel.db.profile.minimap.enabled = value; Sentinel.MinimapButton:Refresh() end)
    self.checks[#self.checks + 1] = createCheck(utility, "Show HUD map/score buttons", 8, -58,
        function() return Sentinel.db.profile.hud.utilityButtons ~= false end,
        function(value) Sentinel.db.profile.hud.utilityButtons = value; Sentinel.HUD:Update() end)
    self.checks[#self.checks + 1] = createCheck(utility, "Lock execution card", 8, -86,
        function() return Sentinel.db.profile.hud.locked == true end,
        function(value) Sentinel.db.profile.hud.locked = value end)
    self.checks[#self.checks + 1] = createCheck(utility, "Lock helper panels", 8, -114,
        function() return Sentinel.db.profile.panels.locked == true end,
        function(value) Sentinel.db.profile.panels.locked = value end)
    self.checks[#self.checks + 1] = createCheck(utility, "Show login message", 8, -142,
        function() return Sentinel.db.profile.loadMessage ~= false end,
        function(value) Sentinel.db.profile.loadMessage = value end)

    frame.noteShell = section(frame, "POLICY", 12, -252, 492, 94)
    frame.note = Sentinel.Theme:Font(frame.noteShell, 9, "muted", "LEFT")
    frame.note:SetPoint("TOPLEFT", 10, -28)
    frame.note:SetPoint("TOPRIGHT", -10, -28)
    frame.note:SetHeight(56)

    frame.commands = Sentinel.Theme:Font(frame, 8, "muted", "LEFT", "OUTLINE")
    frame.commands:SetPoint("BOTTOMLEFT", 14, 12)
    frame.commands:SetText("/kwrs options   /kwrs reset   /kwrs map   /kwrs score")

    self.frame = frame
    return frame
end

function Options:Toggle()
    local frame = self:Create()
    frame:SetShown(not frame:IsShown())
    if frame:IsShown() then
        self:Refresh()
    end
end

function Options:OnInitialize()
    -- Created on first open.
end

Sentinel:RegisterModule("Options", Options)
