local _, Sentinel = ...

local MinimapButton = {}
Sentinel.MinimapButton = MinimapButton

local ICON_TEXTURE = "Interface\\Icons\\Ability_Rogue_TricksOftheTrade"
local BRAND_TEXTURE = "Interface\\AddOns\\KnomercyWarRoom\\Assets\\Brand\\Minimap\\kwr_minimap_icon_32.png"
local DEFAULT_ANGLE = 225
local RADIUS = 96
local MENU_FRAME_NAME = "KWRSentinel_MinimapMenu"

local function profile()
    local db = Sentinel.db and Sentinel.db.profile
    db.minimap = type(db.minimap) == "table" and db.minimap or {}
    if db.minimap.enabled == nil then
        db.minimap.enabled = true
    end
    db.minimap.angle = tonumber(db.minimap.angle or DEFAULT_ANGLE) or DEFAULT_ANGLE
    return db.minimap
end

local function setHudEnabled(enabled)
    if not Sentinel.db or not Sentinel.db.profile then
        return
    end
    Sentinel.db.profile.hud.enabled = enabled == true
    if Sentinel.HUD then
        Sentinel.HUD:Update()
    end
    if Sentinel.MinimapButton then
        Sentinel.MinimapButton:Refresh()
    end
end

local function setTargetCueEnabled(enabled)
    if not Sentinel.db or not Sentinel.db.profile then
        return
    end
    Sentinel.db.profile.targetCue.enabled = enabled == true
    if Sentinel.HUD then
        Sentinel.HUD:Update()
    end
end

local function setPanelEnabled(kind, enabled)
    if not Sentinel.db or not Sentinel.db.profile or not Sentinel.db.profile.panels then
        return
    end
    Sentinel.db.profile.panels[kind].enabled = enabled == true
    if Sentinel.Panels then
        Sentinel.Panels:Update()
    end
end

local function menuChecked(getter)
    return function()
        return getter() == true
    end
end

local function buildMenu(button)
    return {
        {
            text = "KWR Sentinel",
            isTitle = true,
            notCheckable = true,
        },
        {
            text = "Show execution card",
            keepShownOnClick = true,
            isNotRadio = true,
            checked = menuChecked(function()
                return Sentinel.db.profile.hud.enabled == true
            end),
            func = function()
                setHudEnabled(not (Sentinel.db.profile.hud.enabled == true))
            end,
        },
        {
            text = "Show crosshair cue",
            keepShownOnClick = true,
            isNotRadio = true,
            checked = menuChecked(function()
                return Sentinel.db.profile.targetCue.enabled ~= false
            end),
            func = function()
                setTargetCueEnabled(not (Sentinel.db.profile.targetCue.enabled ~= false))
            end,
        },
        {
            text = "Show status helper",
            keepShownOnClick = true,
            isNotRadio = true,
            checked = menuChecked(function()
                return Sentinel.db.profile.panels.status.enabled == true
            end),
            func = function()
                setPanelEnabled("status", not (Sentinel.db.profile.panels.status.enabled == true))
            end,
        },
        {
            text = "Show team tracker",
            keepShownOnClick = true,
            isNotRadio = true,
            checked = menuChecked(function()
                return Sentinel.db.profile.panels.team.enabled == true
            end),
            func = function()
                setPanelEnabled("team", not (Sentinel.db.profile.panels.team.enabled == true))
            end,
        },
        {
            text = "Show enemy tracker",
            keepShownOnClick = true,
            isNotRadio = true,
            checked = menuChecked(function()
                return Sentinel.db.profile.panels.enemy.enabled == true
            end),
            func = function()
                setPanelEnabled("enemy", not (Sentinel.db.profile.panels.enemy.enabled == true))
            end,
        },
        {
            text = "Open full options",
            notCheckable = true,
            func = function()
                if Sentinel.Options then
                    Sentinel.Options:Toggle()
                end
            end,
        },
        {
            text = "Reset minimap position",
            notCheckable = true,
            func = function()
                profile().angle = DEFAULT_ANGLE
                positionButton(button)
            end,
        },
    }
end

local function showMenu(button)
    if type(EasyMenu) ~= "function" then
        if Sentinel.Options then
            Sentinel.Options:Toggle()
        end
        return
    end
    local menuFrame = _G[MENU_FRAME_NAME]
    if not menuFrame then
        menuFrame = CreateFrame("Frame", MENU_FRAME_NAME, UIParent, "UIDropDownMenuTemplate")
    end
    EasyMenu(buildMenu(button), menuFrame, "cursor", 0, 0, "MENU")
end

local function positionButton(button)
    local settings = profile()
    local angle = math.rad(settings.angle or DEFAULT_ANGLE)
    local x = math.cos(angle) * RADIUS
    local y = math.sin(angle) * RADIUS
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function updateDragPosition(button)
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale
    local atan = math.atan2 or math.atan
    local angle = math.deg(atan(cursorY - centerY, cursorX - centerX))
    profile().angle = angle
    positionButton(button)
end

function MinimapButton:Create()
    if self.button then return self.button end

    local button = CreateFrame("Button", "KWRSentinel_MinimapButton", Minimap)
    button:SetSize(26, 26)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")

    button.ring = button:CreateTexture(nil, "BACKGROUND")
    button.ring:SetAllPoints()
    button.ring:SetTexture("Interface\\Cooldown\\ping4")
    button.ring:SetBlendMode("ADD")
    button.ring:SetVertexColor(0.30, 0.49, 0.66, 0.45)

    button.back = button:CreateTexture(nil, "BORDER")
    button.back:SetPoint("TOPLEFT", 4, -4)
    button.back:SetPoint("BOTTOMRIGHT", -4, 4)
    button.back:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.back:SetVertexColor(0.043, 0.059, 0.078, 0.62)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("CENTER")
    button.icon:SetSize(16, 16)
    button.icon:SetTexture(BRAND_TEXTURE)

    button.fallback = button:CreateTexture(nil, "ARTWORK")
    button.fallback:SetPoint("CENTER")
    button.fallback:SetSize(16, 16)
    button.fallback:SetTexture(ICON_TEXTURE)
    button.fallback:Hide()

    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetPoint("CENTER")
    button.glow:SetSize(20, 20)
    button.glow:SetTexture("Interface\\Cooldown\\star4")
    button.glow:SetBlendMode("ADD")
    button.glow:SetVertexColor(0.788, 0.635, 0.133, 0.18)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetPoint("TOPLEFT", 3, -3)
    button.border:SetPoint("BOTTOMRIGHT", -3, 3)
    button.border:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.border:SetVertexColor(0.165, 0.212, 0.267, 0.82)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            showMenu(button)
            return
        end
        local enabled = Sentinel.db
            and Sentinel.db.profile
            and Sentinel.db.profile.hud
            and Sentinel.db.profile.hud.enabled == true
        setHudEnabled(not enabled)
    end)
    button:SetScript("OnDragStart", function()
        button:SetScript("OnUpdate", updateDragPosition)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
        positionButton(button)
    end)
    button:SetScript("OnEnter", function()
        if not GameTooltip then return end
        button.ring:SetVertexColor(0.788, 0.635, 0.133, 0.55)
        button.border:SetVertexColor(0.788, 0.635, 0.133, 0.98)
        button.glow:SetVertexColor(0.788, 0.635, 0.133, 0.32)
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetText("KWR Sentinel")
        GameTooltip:AddLine("Left-click: show/hide execution card", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Sentinel quick options", 1, 1, 1)
        GameTooltip:AddLine("Drag: move button", 0.72, 0.82, 0.92)
        GameTooltip:AddLine("Menu toggles: crosshair, status, team, enemy", 0.72, 0.82, 0.92)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        button.ring:SetVertexColor(0.30, 0.49, 0.66, 0.45)
        button.border:SetVertexColor(0.165, 0.212, 0.267, 0.95)
        button.glow:SetVertexColor(0.788, 0.635, 0.133, 0.18)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    self.button = button
    positionButton(button)
    self:Refresh()
    return button
end

function MinimapButton:Refresh()
    local button = self.button
    if not button then return end
    local settings = profile()
    button:SetShown(settings.enabled == true)
    local hudEnabled = Sentinel.db
        and Sentinel.db.profile
        and Sentinel.db.profile.hud
        and Sentinel.db.profile.hud.enabled == true
    local useBrand = type(button.icon.GetTexture) == "function"
        and button.icon:GetTexture() ~= nil
    button.icon:SetShown(useBrand)
    button.fallback:SetShown(not useBrand)
    if hudEnabled then
        button.icon:SetVertexColor(1, 1, 1, 1)
        button.fallback:SetVertexColor(1, 1, 1, 1)
        button.glow:SetShown(true)
    else
        button.icon:SetVertexColor(0.62, 0.68, 0.74, 0.82)
        button.fallback:SetVertexColor(0.62, 0.68, 0.74, 0.82)
        button.glow:SetShown(false)
    end
end

function MinimapButton:OnInitialize()
    self:Create()
end

Sentinel:RegisterModule("MinimapButton", MinimapButton)