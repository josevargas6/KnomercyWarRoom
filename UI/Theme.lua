local _, KWR = ...

local function rgba(r, g, b, a)
    return { r, g, b, a or 1 }
end

local Theme = {
    fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    titleFontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    tokens = {
        colors = {
            KWR_COLOR_BG = rgba(0.043, 0.059, 0.078, 0.80),
            KWR_COLOR_SHELL = rgba(0.043, 0.059, 0.078, 0.95),
            KWR_COLOR_SURFACE = rgba(0.071, 0.098, 0.133, 0.90),
            KWR_COLOR_SURFACE_RAISED = rgba(0.102, 0.141, 0.188, 0.96),
            KWR_COLOR_SURFACE_FIELD = rgba(0.055, 0.076, 0.102, 0.88),
            KWR_COLOR_BORDER = rgba(0.165, 0.212, 0.267, 0.95),
            KWR_COLOR_BORDER_HI = rgba(0.788, 0.635, 0.133, 1.00),
            KWR_COLOR_PRIMARY = rgba(0.788, 0.635, 0.133, 1.00),
            KWR_COLOR_SECONDARY = rgba(0.302, 0.494, 0.659, 1.00),
            KWR_COLOR_SUCCESS = rgba(0.310, 0.639, 0.424, 1.00),
            KWR_COLOR_WARNING = rgba(0.851, 0.557, 0.016, 1.00),
            KWR_COLOR_DANGER = rgba(0.706, 0.263, 0.263, 1.00),
            KWR_COLOR_INFERRED = rgba(0.851, 0.557, 0.016, 1.00),
            KWR_COLOR_CONTROL = rgba(0.435, 0.235, 0.612, 1.00),
            KWR_COLOR_TEXT = rgba(0.851, 0.886, 0.925, 1.00),
            KWR_COLOR_TEXT_SOFT = rgba(0.820, 0.840, 0.880, 1.00),
            KWR_COLOR_TEXT_MUTED = rgba(0.541, 0.592, 0.651, 1.00),
            KWR_COLOR_TEXT_DIM = rgba(0.380, 0.400, 0.440, 1.00),
            KWR_COLOR_TEXT_INVERSE = rgba(0.965, 0.976, 0.988, 1.00),
            KWR_COLOR_MAP = rgba(0.039, 0.051, 0.067, 0.84),
        },
        typography = {
            KWR_FONT_HEADER = {
                path = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
                flags = "OUTLINE",
            },
            KWR_FONT_BODY = {
                path = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
                flags = "",
            },
            KWR_FONT_SIZE_WINDOW_TITLE = 20,
            KWR_FONT_SIZE_SECTION_TITLE = 14,
            KWR_FONT_SIZE_CARD_TITLE = 12,
            KWR_FONT_SIZE_BODY = 11,
            KWR_FONT_SIZE_META = 10,
            KWR_FONT_SIZE_TINY = 9,
        },
        radius = {
            KWR_RADIUS_SM = 8,
            KWR_RADIUS_MD = 10,
        },
        spacing = {
            KWR_SPACING_4 = 4,
            KWR_SPACING_8 = 8,
            KWR_SPACING_12 = 12,
            KWR_SPACING_16 = 16,
            KWR_SPACING_24 = 24,
            KWR_SPACING_32 = 32,
        },
        shadow = {
            KWR_SHADOW_SOFT = {
                color = rgba(0, 0, 0, 0.72),
                offsetX = 1,
                offsetY = -1,
            },
        },
        icon = {
            KWR_ICON_SIZE_SM = 14,
            KWR_ICON_SIZE_MD = 18,
        },
    },
    colorAliases = {
        background = "KWR_COLOR_BG",
        commandCenter = "KWR_COLOR_SHELL",
        panel = "KWR_COLOR_SURFACE",
        card = "KWR_COLOR_SURFACE_FIELD",
        raised = "KWR_COLOR_SURFACE_RAISED",
        map = "KWR_COLOR_MAP",
        border = "KWR_COLOR_BORDER",
        borderHi = "KWR_COLOR_BORDER_HI",
        gold = "KWR_COLOR_PRIMARY",
        blue = "KWR_COLOR_SECONDARY",
        green = "KWR_COLOR_SUCCESS",
        red = "KWR_COLOR_DANGER",
        orange = "KWR_COLOR_INFERRED",
        purple = "KWR_COLOR_CONTROL",
        yellow = "KWR_COLOR_WARNING",
        white = "KWR_COLOR_TEXT_INVERSE",
        soft = "KWR_COLOR_TEXT_SOFT",
        muted = "KWR_COLOR_TEXT_MUTED",
        dim = "KWR_COLOR_TEXT_DIM",
    },
    -- One combat language for the cursor ring, target reticle, battlefield
    -- identifiers, compact HUD, and combat roster. Text labels remain required;
    -- these colors reinforce meaning but never replace it.
    combatColors = {
        NEUTRAL = {
            outer = { 0.15, 0.75, 1.00 },
            inner = { 1.00, 0.72, 0.18 },
            alpha = 0.92,
            hex = "26bfff",
        },
        MOVE = {
            outer = { 0.20, 0.55, 1.00 },
            inner = { 0.55, 0.82, 1.00 },
            alpha = 0.92,
            hex = "338cff",
        },
        RECOVERY = {
            outer = { 0.20, 0.95, 0.24 },
            inner = { 0.62, 1.00, 0.45 },
            alpha = 0.92,
            hex = "33f23d",
        },
        UNKNOWN = {
            outer = { 0.68, 0.36, 0.98 },
            inner = { 0.82, 0.66, 1.00 },
            alpha = 0.84,
            hex = "ad5cfa",
        },
        TARGET = {
            outer = { 0.94, 0.96, 1.00 },
            inner = { 0.82, 0.90, 1.00 },
            alpha = 0.92,
            hex = "f0f5ff",
        },
        KILL = {
            outer = { 1.00, 0.16, 0.12 },
            inner = { 1.00, 0.64, 0.16 },
            alpha = 0.92,
            hex = "ff291f",
        },
        STOP = {
            outer = { 1.00, 0.44, 0.08 },
            inner = { 1.00, 0.84, 0.18 },
            alpha = 0.88,
            hex = "ff700d",
        },
        SWAP = {
            outer = { 1.00, 0.22, 0.18 },
            inner = { 0.98, 0.32, 0.96 },
            alpha = 0.86,
            hex = "ff382e",
        },
        IMMUNE = {
            outer = { 0.82, 0.40, 1.00 },
            inner = { 0.90, 0.74, 1.00 },
            alpha = 0.84,
            hex = "d166ff",
        },
        CARRY = {
            outer = { 1.00, 0.72, 0.18 },
            inner = { 1.00, 0.92, 0.46 },
            alpha = 0.86,
            hex = "ffb82e",
        },
        TEAM = {
            outer = { 0.20, 0.55, 1.00 },
            inner = { 0.64, 0.82, 1.00 },
            alpha = 0.82,
            hex = "338cff",
        },
        HEALER = {
            outer = { 0.22, 0.95, 0.32 },
            inner = { 0.78, 1.00, 0.84 },
            alpha = 0.82,
            hex = "38f252",
        },
        TANK = {
            outer = { 0.26, 0.74, 1.00 },
            inner = { 0.82, 0.95, 1.00 },
            alpha = 0.82,
            hex = "42bdff",
        },
        DAMAGE = {
            outer = { 1.00, 0.74, 0.22 },
            inner = { 1.00, 0.92, 0.50 },
            alpha = 0.82,
            hex = "ffbd38",
        },
        STALE = {
            outer = { 0.46, 0.48, 0.54 },
            inner = { 0.74, 0.76, 0.82 },
            alpha = 0.62,
            hex = "757a8a",
        },
    },
}

Theme.colors = {}
for legacyName, tokenName in pairs(Theme.colorAliases) do
    Theme.colors[legacyName] = Theme.tokens.colors[tokenName]
end
KWR.Theme = Theme

Theme.backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

function Theme:Color(name)
    local tokenName = self.colorAliases[name] or name or "white"
    local color = self.tokens.colors[tokenName] or self.colors.white
    return color[1], color[2], color[3], color[4]
end

function Theme:Token(name)
    if not name then return nil end
    if self.tokens.colors[name] then return self.tokens.colors[name] end
    if self.tokens.typography[name] then return self.tokens.typography[name] end
    if self.tokens.radius[name] then return self.tokens.radius[name] end
    if self.tokens.spacing[name] then return self.tokens.spacing[name] end
    if self.tokens.shadow[name] then return self.tokens.shadow[name] end
    if self.tokens.icon[name] then return self.tokens.icon[name] end
    local alias = self.colorAliases[name]
    if alias then return self.tokens.colors[alias] end
    return nil
end

function Theme:Metric(name, fallback)
    local value = self:Token(name)
    if type(value) == "number" then return value end
    return fallback
end

function Theme:CombatColor(name, layer)
    local colors = self.combatColors[name] or self.combatColors.NEUTRAL
    local color = colors[layer or "outer"] or colors.outer
    return color[1], color[2], color[3], colors.alpha or 1
end

function Theme:CombatText(name, value)
    local colors = self.combatColors[name] or self.combatColors.NEUTRAL
    return "|cff" .. colors.hex .. tostring(value or "") .. "|r"
end

function Theme:Style(frame, background, border)
    frame:SetBackdrop(self.backdrop)
    frame:SetBackdropColor(self:Color(background or "panel"))
    frame:SetBackdropBorderColor(self:Color(border or "border"))
end

function Theme:Font(parent, size, color, justify, flags)
    local font = parent:CreateFontString(nil, "OVERLAY")
    local typography = self.tokens.typography.KWR_FONT_BODY
    local shadow = self.tokens.shadow.KWR_SHADOW_SOFT
    font:SetFont(typography.path or self.fontPath, size or 11, flags or typography.flags or "")
    font:SetTextColor(self:Color(color or "white"))
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    font:SetWordWrap(true)
    font:SetShadowColor(unpack(shadow.color))
    font:SetShadowOffset(shadow.offsetX, shadow.offsetY)
    return font
end

function Theme:Title(parent, size, justify)
    local font = parent:CreateFontString(nil, "OVERLAY")
    local typography = self.tokens.typography.KWR_FONT_HEADER
    local shadow = self.tokens.shadow.KWR_SHADOW_SOFT
    font:SetFont(
        typography.path or self.titleFontPath,
        size or self.tokens.typography.KWR_FONT_SIZE_SECTION_TITLE,
        typography.flags or "OUTLINE")
    font:SetTextColor(self:Color("gold"))
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    font:SetShadowColor(0, 0, 0, 0.80)
    font:SetShadowOffset(shadow.offsetX, shadow.offsetY)
    return font
end

function Theme:Button(parent, label, width, height, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 100, height or 24)
    self:Style(button, "card", "border")
    button.fill = button:CreateTexture(nil, "BACKGROUND")
    button.fill:SetPoint("TOPLEFT", 1, -1)
    button.fill:SetPoint("BOTTOMRIGHT", -1, 1)
    button.fill:SetColorTexture(self:Color("KWR_COLOR_PRIMARY"))
    button.fill:SetAlpha(0.10)
    button.fill:Hide()
    button.activeLine = button:CreateTexture(nil, "ARTWORK")
    button.activeLine:SetPoint("BOTTOMLEFT", 1, 1)
    button.activeLine:SetPoint("BOTTOMRIGHT", -1, 1)
    button.activeLine:SetHeight(2)
    button.activeLine:SetColorTexture(self:Color("gold"))
    button.activeLine:Hide()
    button.label = self:Font(button, 10, "soft", "CENTER")
    button.label:SetPoint("TOPLEFT", 4, -1)
    button.label:SetPoint("BOTTOMRIGHT", -4, 1)
    if button.label.SetWordWrap then
        button.label:SetWordWrap(false)
    end
    button.label:SetText(label)
    button.SetText = function(self, value) self.label:SetText(value) end
    local function applyState(self, hovered)
        local selected = self.selected == true
        Theme:Style(self, selected and "raised" or (hovered and "raised" or "card"),
            selected and "borderHi" or (hovered and "borderHi" or "border"))
        self.label:SetTextColor(Theme:Color(selected and "gold"
            or (hovered and "gold" or "soft")))
        self.fill:SetShown(selected)
        self.activeLine:SetShown(selected)
    end
    button.SetSelected = function(self, selected)
        self.selected = selected == true
        applyState(self, false)
    end
    button:SetScript("OnClick", callback or function() end)
    button:SetScript("OnEnter", function(self)
        applyState(self, true)
    end)
    button:SetScript("OnLeave", function(self)
        applyState(self, false)
    end)
    applyState(button, false)
    return button
end

function Theme:Card(parent, title)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    -- Cards are hard visual boundaries. Without clipping, wrapped font strings
    -- can paint into the adjacent card when a live call is longer than its
    -- reserved block (the most visible failure in the command-center view).
    if card.SetClipsChildren then card:SetClipsChildren(true) end
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

function Theme:Badge(parent, tone, text, width, height)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(width or 84, height or 16)
    badge.text = self:Font(badge, 8, "white", "CENTER", "OUTLINE")
    badge.text:SetAllPoints()
    function badge:SetTone(value)
        local use = value or "muted"
        if use == "green" then
            Theme:Style(self, "background", "green")
            self.text:SetTextColor(Theme:Color("green"))
        elseif use == "red" then
            Theme:Style(self, "background", "red")
            self.text:SetTextColor(Theme:Color("red"))
        elseif use == "orange" then
            Theme:Style(self, "background", "orange")
            self.text:SetTextColor(Theme:Color("orange"))
        elseif use == "yellow" then
            Theme:Style(self, "background", "yellow")
            self.text:SetTextColor(Theme:Color("yellow"))
        elseif use == "purple" then
            Theme:Style(self, "background", "purple")
            self.text:SetTextColor(Theme:Color("purple"))
        elseif use == "blue" then
            Theme:Style(self, "background", "blue")
            self.text:SetTextColor(Theme:Color("blue"))
        elseif use == "gold" then
            Theme:Style(self, "background", "borderHi")
            self.text:SetTextColor(Theme:Color("gold"))
        else
            Theme:Style(self, "background", "border")
            self.text:SetTextColor(Theme:Color("muted"))
        end
        self.tone = use
    end
    function badge:SetText(value)
        self.text:SetText(Theme and KWR and KWR.Util
            and KWR.Util:Upper(value, "", 24) or string.upper(tostring(value or "")))
    end
    badge:SetTone(tone)
    badge:SetText(text)
    return badge
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