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

local META = {
    ["INC PRIMARY"] = {
        group = "PRESSURE",
        hint = "Collapse on the current best supported kill lane.",
    },
    ["HELP HOME"] = {
        group = "STABILIZE",
        hint = "Reinforce the threatened home base before the loss is confirmed.",
    },
    ["STOP FLAG"] = {
        group = "PRESSURE",
        hint = "Commit local control to stop the enemy carrier or flag touch.",
    },
    ["PEEL CARRIER"] = {
        group = "STABILIZE",
        hint = "Bodyguard the friendly carrier and deny enemy reach.",
    },
    ["ROTATE NOW"] = {
        group = "TEMPO",
        hint = "Shift lanes immediately while momentum still exists.",
    },
    ["HOLD POSITION"] = {
        group = "TEMPO",
        hint = "Stop drift and preserve the current assignment structure.",
    },
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

local function statusTagTone(color)
    if color == "red" then return "BLOCKED" end
    if color == "green" then return "SENT" end
    if color == "yellow" then return "SETUP" end
    return "READY"
end

local function statusTextFrame(status)
    return status and (status.message or status)
end

local function setStatus(status, tag, message, color)
    if not status then return end
    local label = statusTextFrame(status)
    if not label or type(label.SetText) ~= "function" then return end
    local now = (KWR.Util and type(KWR.Util.Now) == "function")
        and KWR.Util:Now() or 0
    local previousToken = rawget(status, "quickCallStatusToken") or 0
    local token = previousToken + 1
    rawset(status, "quickCallStatusToken", token)
    rawset(status, "quickCallResetAt", now + 3)
    rawset(status, "quickCallDefault", rawget(status, "quickCallDefault")
        or KWR.Util:Text(label:GetText(), "", 120)
    )
    rawset(status, "quickCallDefaultTag", rawget(status, "quickCallDefaultTag")
        or (status.badge and KWR.Util:Text(status.badge.text and status.badge.text:GetText(),
            "READY", 24) or nil)
    )
    label:SetText(tag and (tag .. ": " .. KWR.Util:Text(message, "", 120))
        or (message or ""))
    if label.SetTextColor then
        label:SetTextColor(KWR.Theme:Color(color or "muted"))
    end
    if status.badge then
        status.badge:SetTone(color or "muted")
        status.badge:SetText(tag or statusTagTone(color))
    end
    if not message or message == "" then return end
    if C_Timer and C_Timer.After then
        C_Timer.After(3.0, function()
            if rawget(status, "quickCallStatusToken") ~= token then return end
            local current = (KWR.Util and type(KWR.Util.Now) == "function")
                and KWR.Util:Now() or 0
            if current < (rawget(status, "quickCallResetAt") or 0) then return end
            label:SetText(rawget(status, "quickCallDefault") or "")
            if label.SetTextColor then
                label:SetTextColor(KWR.Theme:Color("muted"))
            end
            if status.badge then
                status.badge:SetTone("muted")
                status.badge:SetText(rawget(status, "quickCallDefaultTag") or "READY")
            end
        end)
    end
end

local function showTooltip(button)
    if not GameTooltip or not GameTooltip.SetOwner then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(button.callText or "KWR Quick Call")
    if button.callMeta and button.callMeta.group then
        GameTooltip:AddLine("Intent: " .. button.callMeta.group, 1.00, 0.82, 0.24)
    end
    if button.callMeta and button.callMeta.hint then
        GameTooltip:AddLine(button.callMeta.hint, 0.78, 0.82, 0.88, true)
    end
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
    button:SetSize(width or 132, height or 38)
    KWR.Theme:Style(button, "card", "border")
    button.label = KWR.Theme:Font(button, 11, "soft", "CENTER")
    button.label:SetAllPoints()
    button.label:SetText(label)
    button.callText = label
    button.callMeta = META[label]
    -- Keep the intent metadata available to diagnostics and tests, but do not
    -- render a second line inside the compact button where it competes with
    -- the required action label at narrow UI scales.
    if button.callMeta and button.callMeta.group then
        button.groupText = KWR.Theme:Font(button, 7, "muted", "LEFT", "OUTLINE")
        button.groupText:SetText(KWR.Util:Text(button.callMeta.group, "", 14))
        button.groupText:Hide()
    end
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
            setStatus(status, "BLOCKED", "UNREVIEWED QUICK CALL", "red")
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
            setStatus(status, "COPY READY",
                "OPEN BOARD OUT OF COMBAT FOR ONE-CLICK SEND", "gold")
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
            setStatus(status, "COPY READY", self.callText, "gold")
        elseif isBattleground() then
            setStatus(status, "SENT", self.callText, "green")
        else
            setStatus(status, "NOT SENT", "INSTANCE CHAT REQUIRES A BATTLEGROUND", "gold")
        end
    end)
    button.quickCallSecure = true
    return button
end

function QuickCalls:Definitions()
    return KWR.Util:Copy(DEFINITIONS)
end

function QuickCalls:GetMeta(callText)
    return META[tostring(callText or "")]
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
