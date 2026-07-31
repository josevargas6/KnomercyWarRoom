local _, KWR = ...

local IconRegistry = {
    availableSizes = { 16, 20, 24, 32 },
    roleMap = {
        TANK = "tank",
        HEALER = "healer",
        DAMAGER = "dps",
    },
    stateMap = {
        FRIENDLY = "friendly",
        ENEMY = "enemy",
        UNKNOWN = "unknown",
        DISABLED = "disabled",
        NOT_LIVE = "not_live",
    },
    icons = {
        assignment = true,
        blocked = true,
        cart = true,
        cart_enemy = true,
        cart_friendly = true,
        cart_moving = true,
        cart_stopped = true,
        commander = true,
        contest = true,
        control = true,
        cooldown = true,
        danger = true,
        defend = true,
        disabled = true,
        dps = true,
        enemy = true,
        flag_dropped = true,
        flag_enemy = true,
        flag_friendly = true,
        flag_return = true,
        friendly = true,
        healer = true,
        hold = true,
        inferred = true,
        kill = true,
        node_assault = true,
        node_contested = true,
        node_defended = true,
        node_enemy = true,
        node_friendly = true,
        node_incoming = true,
        not_live = true,
        observed = true,
        orb_blue = true,
        orb_blue_carrier_enemy = true,
        orb_blue_carrier_friendly = true,
        orb_blue_dropped = true,
        orb_blue_unknown = true,
        orb_green = true,
        orb_green_carrier_enemy = true,
        orb_green_carrier_friendly = true,
        orb_green_dropped = true,
        orb_green_unknown = true,
        orb_orange = true,
        orb_orange_carrier_enemy = true,
        orb_orange_carrier_friendly = true,
        orb_orange_dropped = true,
        orb_orange_unknown = true,
        orb_purple = true,
        orb_purple_carrier_enemy = true,
        orb_purple_carrier_friendly = true,
        orb_purple_dropped = true,
        orb_purple_unknown = true,
        peel = true,
        priority = true,
        push = true,
        ready = true,
        rotate = true,
        tank = true,
        threat = true,
        timer = true,
        unknown = true,
    },
}
KWR.Icons = IconRegistry

local function roundSize(size)
    size = KWR.Util:Number(size, 20) or 20
    local chosen = IconRegistry.availableSizes[1]
    local distance = math.abs(size - chosen)
    for _, candidate in ipairs(IconRegistry.availableSizes) do
        local candidateDistance = math.abs(size - candidate)
        if candidateDistance < distance then
            chosen = candidate
            distance = candidateDistance
        end
    end
    return chosen
end

function IconRegistry:TexturePath(iconID, size)
    iconID = KWR.Util:Text(iconID, "", 64):lower()
    if iconID == "" or self.icons[iconID] ~= true then return nil end
    local iconSize = roundSize(size)
    return "Interface\\AddOns\\" .. KWR.name
        .. "\\Assets\\Icons\\" .. tostring(iconSize)
        .. "\\kwr_icon_" .. iconID .. "_" .. tostring(iconSize) .. ".png"
end

function IconRegistry:BrandPath(kind)
    kind = KWR.Util:Text(kind, "", 64):lower()
    if kind == "minimap" then
        return "Interface\\AddOns\\" .. KWR.name .. "\\Assets\\Brand\\Minimap\\kwr_minimap_icon_32.png"
    end
    if kind == "micro" then
        return "Interface\\AddOns\\" .. KWR.name .. "\\Assets\\Brand\\Minimap\\kwr_micro_icon_16.png"
    end
    if kind == "sigil" then
        return "Interface\\AddOns\\" .. KWR.name .. "\\Assets\\Brand\\Sigils\\kwr_sigil_32.png"
    end
    if kind == "sigil_large" then
        return "Interface\\AddOns\\" .. KWR.name .. "\\Assets\\Brand\\Sigils\\kwr_sigil_64.png"
    end
    if kind == "logo" then
        return "Interface\\AddOns\\" .. KWR.name .. "\\Assets\\Brand\\Logos\\kwr_primary_logo.png"
    end
    if kind == "mark" then
        return "Interface\\AddOns\\" .. KWR.name .. "\\Assets\\Brand\\Logos\\kwr_compact_mark.png"
    end
    return nil
end

function IconRegistry:RoleIcon(role, size)
    return self:TexturePath(self.roleMap[KWR.Util:Upper(role, "", 16)], size)
end

function IconRegistry:StateIcon(state, size)
    return self:TexturePath(self.stateMap[KWR.Util:Upper(state, "", 24)], size)
end

function IconRegistry:Apply(texture, iconID, size, vertexColor)
    if not texture then return false end
    local path = self:TexturePath(iconID, size)
    if not path then
        texture:SetTexture(nil)
        texture:Hide()
        return false
    end
    texture:SetTexture(path)
    if type(vertexColor) == "table" then
        texture:SetVertexColor(
            vertexColor[1] or 1,
            vertexColor[2] or 1,
            vertexColor[3] or 1,
            vertexColor[4] or 1)
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end
    texture:Show()
    return true
end

function IconRegistry:ApplyBrand(texture, kind, vertexColor)
    if not texture then return false end
    local path = self:BrandPath(kind)
    if not path then
        texture:SetTexture(nil)
        texture:Hide()
        return false
    end
    texture:SetTexture(path)
    if type(vertexColor) == "table" then
        texture:SetVertexColor(
            vertexColor[1] or 1,
            vertexColor[2] or 1,
            vertexColor[3] or 1,
            vertexColor[4] or 1)
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end
    texture:Show()
    return true
end

KWR:RegisterModule("IconRegistry", IconRegistry)