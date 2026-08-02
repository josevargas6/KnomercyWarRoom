local _, Sentinel = ...

local Theme = {}
Sentinel.Theme = Theme

local COLORS = {
    background = { 0.043, 0.059, 0.078, 0.95 },
    panel = { 0.055, 0.076, 0.102, 0.92 },
    surface = { 0.071, 0.098, 0.133, 0.90 },
    raised = { 0.102, 0.141, 0.188, 0.96 },
    border = { 0.165, 0.212, 0.267, 0.95 },
    borderHi = { 0.788, 0.635, 0.133, 1.00 },
    hairline = { 0.165, 0.212, 0.267, 0.75 },
    active = { 0.706, 0.263, 0.263, 0.98 },
    forming = { 0.851, 0.557, 0.016, 0.98 },
    recovery = { 0.310, 0.639, 0.424, 0.98 },
    text = { 0.851, 0.886, 0.925, 1.0 },
    strong = { 0.965, 0.976, 0.988, 1.0 },
    muted = { 0.541, 0.592, 0.651, 1.0 },
    soft = { 0.820, 0.840, 0.880, 1.0 },
    accent = { 0.302, 0.494, 0.659, 1.0 },
    gold = { 0.788, 0.635, 0.133, 1.0 },
}

function Theme:Color(name)
    local color = COLORS[name] or COLORS.text
    return color[1], color[2], color[3], color[4]
end

function Theme:Font(parent, size, tone, justify, flags)
    local font = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    font:SetFont("Fonts\\FRIZQT__.TTF", size or 10, flags or "")
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    font:SetTextColor(self:Color(tone or "text"))
    font:SetShadowColor(0, 0, 0, 0.80)
    font:SetShadowOffset(1, -1)
    return font
end

function Theme:Title(parent, size, justify)
    local font = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    font:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    font:SetTextColor(self:Color("gold"))
    font:SetShadowColor(0, 0, 0, 0.82)
    font:SetShadowOffset(1, -1)
    return font
end

function Theme:Style(frame, tone, borderTone)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(self:Color(tone or "panel"))
    frame:SetBackdropBorderColor(self:Color(borderTone or "border"))
end

function Theme:Badge(parent, tone, text, width, height)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(width or 84, height or 16)
    badge.text = self:Font(badge, 8, "strong", "CENTER", "OUTLINE")
    badge.text:SetAllPoints()
    function badge:SetTone(value)
        value = value or "muted"
        if value == "recovery" or value == "green" then
            Theme:Style(self, "background", "recovery")
            self.text:SetTextColor(Theme:Color("recovery"))
        elseif value == "forming" or value == "orange" or value == "yellow" then
            Theme:Style(self, "background", "forming")
            self.text:SetTextColor(Theme:Color("forming"))
        elseif value == "active" or value == "red" then
            Theme:Style(self, "background", "active")
            self.text:SetTextColor(Theme:Color("active"))
        elseif value == "accent" or value == "blue" then
            Theme:Style(self, "background", "surface")
            self.text:SetTextColor(Theme:Color("accent"))
        elseif value == "gold" then
            Theme:Style(self, "background", "raised")
            self.text:SetTextColor(Theme:Color("gold"))
        else
            Theme:Style(self, "background", "panel")
            self.text:SetTextColor(Theme:Color("muted"))
        end
    end
    function badge:SetText(value)
        self.text:SetText(string.upper(tostring(value or "")))
    end
    badge:SetTone(tone)
    badge:SetText(text)
    return badge
end

function Theme:Button(parent, label, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 58, height or 20)
    self:Style(button, "panel", "border")
    button.fill = button:CreateTexture(nil, "BACKGROUND")
    button.fill:SetPoint("TOPLEFT", 1, -1)
    button.fill:SetPoint("BOTTOMRIGHT", -1, 1)
    button.fill:SetColorTexture(self:Color("gold"))
    button.fill:SetAlpha(0.10)
    button.fill:Hide()
    button.activeLine = button:CreateTexture(nil, "ARTWORK")
    button.activeLine:SetPoint("BOTTOMLEFT", 1, 1)
    button.activeLine:SetPoint("BOTTOMRIGHT", -1, 1)
    button.activeLine:SetHeight(2)
    button.activeLine:SetColorTexture(self:Color("gold"))
    button.activeLine:Hide()
    button.label = self:Font(button, 8, "soft", "CENTER", "OUTLINE")
    button.label:SetAllPoints()
    if button.label.SetJustifyV then
        button.label:SetJustifyV("MIDDLE")
    end
    button.label:SetText(label or "BTN")
    if onClick then
        button:SetScript("OnClick", onClick)
    end
    local function applyState(selfButton, hovered)
        Theme:Style(selfButton, hovered and "raised" or "panel",
            hovered and "borderHi" or "border")
        selfButton.label:SetTextColor(Theme:Color(hovered and "gold" or "soft"))
        selfButton.fill:SetShown(hovered)
        selfButton.activeLine:SetShown(hovered)
    end
    button:SetScript("OnEnter", function(selfButton)
        applyState(selfButton, true)
    end)
    button:SetScript("OnLeave", function(selfButton)
        applyState(selfButton, false)
    end)
    applyState(button, false)
    return button
end
