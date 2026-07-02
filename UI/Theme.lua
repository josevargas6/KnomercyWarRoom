local _, KWR = ...

local Theme = {
    fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    colors = {
        background = { 0.006, 0.007, 0.009, 0.985 },
        panel = { 0.018, 0.020, 0.024, 0.975 },
        card = { 0.030, 0.032, 0.038, 0.975 },
        raised = { 0.052, 0.054, 0.062, 0.98 },
        map = { 0.010, 0.012, 0.014, 1.00 },
        border = { 0.32, 0.27, 0.15, 0.95 },
        borderHi = { 0.70, 0.54, 0.22, 1.00 },
        gold = { 0.93, 0.68, 0.25, 1.00 },
        blue = { 0.28, 0.58, 1.00, 1.00 },
        green = { 0.32, 0.88, 0.32, 1.00 },
        red = { 0.95, 0.20, 0.20, 1.00 },
        orange = { 1.00, 0.49, 0.17, 1.00 },
        purple = { 0.70, 0.38, 0.98, 1.00 },
        yellow = { 0.96, 0.84, 0.24, 1.00 },
        white = { 0.91, 0.92, 0.94, 1.00 },
        soft = { 0.72, 0.74, 0.78, 1.00 },
        muted = { 0.46, 0.49, 0.54, 1.00 },
        dim = { 0.25, 0.27, 0.30, 1.00 },
    },
}
KWR.Theme = Theme

Theme.backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

function Theme:Color(name)
    local color = self.colors[name] or self.colors.white
    return color[1], color[2], color[3], color[4]
end

function Theme:Style(frame, background, border)
    frame:SetBackdrop(self.backdrop)
    frame:SetBackdropColor(self:Color(background or "panel"))
    frame:SetBackdropBorderColor(self:Color(border or "border"))
end

function Theme:Font(parent, size, color, justify, flags)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(self.fontPath, size or 11, flags or "")
    font:SetTextColor(self:Color(color or "white"))
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    font:SetWordWrap(true)
    return font
end

function Theme:Title(parent, size, justify)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(self.fontPath, size or 16, "OUTLINE")
    font:SetTextColor(self:Color("gold"))
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    return font
end

function Theme:Button(parent, label, width, height, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 100, height or 24)
    self:Style(button, "card", "border")
    button.label = self:Font(button, 10, "soft", "CENTER")
    button.label:SetAllPoints()
    button.label:SetText(label)
    button.SetText = function(self, value) self.label:SetText(value) end
    button:SetScript("OnClick", callback or function() end)
    button:SetScript("OnEnter", function(self)
        Theme:Style(self, "raised", "borderHi")
        self.label:SetTextColor(Theme:Color("gold"))
    end)
    button:SetScript("OnLeave", function(self)
        Theme:Style(self, self.selected and "raised" or "card", self.selected and "borderHi" or "border")
        self.label:SetTextColor(Theme:Color(self.selected and "gold" or "soft"))
    end)
    return button
end

function Theme:Card(parent, title)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    self:Style(card, "panel", "border")
    card.heading = self:Font(card, 10, "gold", "LEFT", "OUTLINE")
    card.heading:SetPoint("TOPLEFT", 10, -8)
    card.heading:SetPoint("TOPRIGHT", -10, -8)
    card.heading:SetHeight(16)
    card.heading:SetText(string.upper(title or ""))
    local line = card:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(self:Color("border"))
    line:SetPoint("TOPLEFT", 8, -28)
    line:SetPoint("TOPRIGHT", -8, -28)
    line:SetHeight(1)
    card.divider = line
    return card
end

function Theme:SectionLabel(parent, text, x, y, width)
    local label = self:Font(parent, 9, "gold", "LEFT", "OUTLINE")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 180)
    label:SetHeight(14)
    label:SetText(string.upper(text or ""))
    return label
end

function Theme:MakeMovable(frame, profile)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if profile.locked or (InCombatLockdown and InCombatLockdown()) then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        profile.point, profile.relativePoint, profile.x, profile.y = point, relativePoint, x, y
    end)
end

KWR:RegisterModule("Theme", Theme)
