local _, KWR = ...

local QuickCalls = {}
KWR.QuickCalls = QuickCalls

local DEFINITIONS = {
    "INC PRIMARY",
    "HELP HOME",
    "STOP FLAG",
    "PEEL CARRIER",
    "ROTATE NOW",
    "HOLD POSITION",
}

local APPROVED = {}
for _, phrase in ipairs(DEFINITIONS) do
    APPROVED[phrase] = true
end

local function isBattleground()
    if type(IsInInstance) ~= "function" then
        return false
    end
    local inside, instanceType = IsInInstance()
    return inside == true and instanceType == "pvp"
end

local function setStatus(status, message, color)
    if not status then return end
    status:SetText(message or "")
    if status.SetTextColor then
        status:SetTextColor(KWR.Theme:Color(color or "muted"))
    end
end

local function showTooltip(button)
    if not GameTooltip or not GameTooltip.SetOwner then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(button.callText or "KWR Quick Call")
    GameTooltip:AddLine("Left-click: send to Instance Chat.", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Right-click: open a compact copy field.", 0.65, 0.65, 0.65)
    GameTooltip:Show()
end

local function hideTooltip()
    if GameTooltip and GameTooltip.Hide then
        GameTooltip:Hide()
    end
end

local function decorate(button, label, width, height)
    button:SetSize(width or 132, height or 25)
    KWR.Theme:Style(button, "card", "border")
    button.label = KWR.Theme:Font(button, 10, "soft", "CENTER")
    button.label:SetAllPoints()
    button.label:SetText(label)
    button.callText = label
    button:SetScript("OnEnter", function(self)
        KWR.Theme:Style(self, "raised", "borderHi")
        self.label:SetTextColor(KWR.Theme:Color("gold"))
        showTooltip(self)
    end)
    button:SetScript("OnLeave", function(self)
        KWR.Theme:Style(self, "card", "border")
        self.label:SetTextColor(KWR.Theme:Color("soft"))
        hideTooltip()
    end)
end

function QuickCalls:CreateButton(parent, label, width, height, status)
    local callText = tostring(label or "")
    if not APPROVED[callText] then
        local rejected = KWR.Theme:Button(parent, "UNAVAILABLE", width, height, function()
            setStatus(status, "BLOCKED - UNREVIEWED QUICK CALL", "red")
        end)
        rejected.quickCallRejected = true
        return rejected
    end

    -- Secure attributes cannot be created or changed during combat. If the
    -- expanded board is first constructed in combat, retain a compact manual
    -- fallback instead of risking a protected-action failure.
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        local fallback = KWR.Theme:Button(parent, callText, width, height, function()
            KWR.CopyDialog:ShowCompact("KWR Quick Call", callText)
            setStatus(status, "COPY FALLBACK - OPEN BOARD OUT OF COMBAT TO ARM ONE-CLICK CALLS", "gold")
        end)
        fallback.quickCallFallback = true
        return fallback
    end

    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,BackdropTemplate")
    decorate(button, callText, width, height)
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext1", "/instance " .. callText)
    button:SetScript("PostClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            KWR.CopyDialog:ShowCompact("KWR Quick Call", self.callText)
            setStatus(status, "READY TO COPY: " .. self.callText, "gold")
        elseif isBattleground() then
            setStatus(status, "CALL ACTIVATED: " .. self.callText, "green")
        else
            setStatus(status, "NOT SENT - INSTANCE CHAT IS AVAILABLE IN A BATTLEGROUND", "gold")
        end
    end)
    button.quickCallSecure = true
    return button
end

function QuickCalls:Definitions()
    return KWR.Util:Copy(DEFINITIONS)
end

function QuickCalls:IsApproved(callText)
    return APPROVED[tostring(callText or "")] == true
end

function QuickCalls:Validate()
    if #DEFINITIONS ~= 6 then return false, "Expected six fixed calls." end
    local seen = {}
    for _, phrase in ipairs(DEFINITIONS) do
        if phrase == "" or seen[phrase] or not APPROVED[phrase] then
            return false, "Quick Call allowlist is invalid."
        end
        seen[phrase] = true
    end
    return true
end

function QuickCalls:OnInitialize()
    -- Buttons are created with the lazy Objectives page. Their fixed secure
    -- attributes are assigned once, outside combat, and never mutated.
end

KWR:RegisterModule("QuickCalls", QuickCalls)
