local _, KWR = ...

local CursorRing = {}
KWR.CursorRing = CursorRing

function CursorRing:Create()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KWR_CursorRing", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9000)
    frame:EnableMouse(false)
    frame:Hide()

    local outer = frame:CreateTexture(nil, "ARTWORK")
    outer:SetAllPoints()
    outer:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    outer:SetBlendMode("ADD")
    outer:SetVertexColor(0.15, 0.75, 1, 1)
    frame.outer = outer

    local inner = frame:CreateTexture(nil, "OVERLAY")
    inner:SetPoint("CENTER")
    inner:SetTexture("Interface\\Cooldown\\star4")
    inner:SetBlendMode("ADD")
    inner:SetVertexColor(1, 0.72, 0.18, 0.35)
    frame.inner = inner

    frame:SetScript("OnUpdate", function(_, elapsed)
        CursorRing:OnUpdate(elapsed)
    end)
    self.frame = frame
    return frame
end

function CursorRing:Apply()
    local profile = KWR.db.profile.cursor
    local frame = self:Create()
    local size = KWR.Util:Clamp(profile.size or 96, 56, 180)
    profile.size = size
    frame:SetSize(size, size)
    frame.inner:SetSize(math.floor(size * 0.18), math.floor(size * 0.18))
    frame:SetAlpha(KWR.Util:Clamp(profile.alpha or 0.95, 0.2, 1))
    frame:SetShown(profile.enabled == true)
end

function CursorRing:OnUpdate(elapsed)
    if not self.frame or not self.frame:IsShown() then return end
    self.elapsed = (self.elapsed or 0) + (KWR.Util:Number(elapsed, 0) or 0)
    if self.elapsed < (1 / 30) then return end
    self.elapsed = 0
    local x, y = KWR.Util:Call(GetCursorPosition)
    x, y = KWR.Util:Number(x, nil), KWR.Util:Number(y, nil)
    if not x or not y then return end
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    x, y = x / scale, y / scale
    if x ~= self.lastX or y ~= self.lastY then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        self.lastX, self.lastY = x, y
    end
end

function CursorRing:SetEnabled(enabled)
    KWR.db.profile.cursor.enabled = enabled == true
    self:Apply()
end

function CursorRing:Toggle()
    self:SetEnabled(not KWR.db.profile.cursor.enabled)
    KWR:Print("Cursor Ring " .. (KWR.db.profile.cursor.enabled and "enabled." or "disabled."), true)
end

function CursorRing:OnInitialize()
    if KWR.db.profile.cursor.enabled == true then self:Apply() end
end

KWR:RegisterModule("CursorRing", CursorRing)
