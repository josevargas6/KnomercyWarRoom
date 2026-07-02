local _, KWR = ...

local CursorRing = {}
KWR.CursorRing = CursorRing

local MODE_COLORS = {
    NEUTRAL = { outer = { 0.15, 0.75, 1.00 }, inner = { 1.00, 0.72, 0.18 } },
    DANGER = { outer = { 1.00, 0.08, 0.04 }, inner = { 1.00, 0.26, 0.08 } },
    CAUTION = { outer = { 1.00, 0.42, 0.05 }, inner = { 1.00, 0.78, 0.12 } },
    ROTATE = { outer = { 0.20, 0.55, 1.00 }, inner = { 0.55, 0.82, 1.00 } },
    RECOVERY = { outer = { 0.20, 0.95, 0.24 }, inner = { 0.62, 1.00, 0.45 } },
    UNKNOWN = { outer = { 0.68, 0.36, 0.98 }, inner = { 0.82, 0.66, 1.00 } },
}

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
    self:ApplyMode(self.mode or "NEUTRAL")
    frame:SetShown(profile.enabled == true)
end

function CursorRing:ApplyMode(mode)
    if not self.frame then return end
    local colors = MODE_COLORS[mode] or MODE_COLORS.NEUTRAL
    self.frame.outer:SetVertexColor(
        colors.outer[1], colors.outer[2], colors.outer[3], 1)
    self.frame.inner:SetVertexColor(
        colors.inner[1], colors.inner[2], colors.inner[3], 0.45)
    self.mode = mode
end

function CursorRing:Update(state)
    if not KWR.db.profile.cursor.enabled then return end
    local snapshot = state.snapshot or {}
    local combat = snapshot.combat or {}
    local execution = snapshot.strategy
        and snapshot.strategy.executionAssessment or {}
    local collapse = execution.collapse or {}
    local pressure = execution.pressureForecast or {}
    local recovery = execution.recovery or {}
    local action = execution.actionOpportunity or {}
    local mode = "NEUTRAL"
    if combat.priorityCast and combat.priorityCast.priority == "MUST_STOP" then
        mode = "DANGER"
    elseif collapse.state == "CRITICAL" then
        mode = "DANGER"
    elseif combat.priorityCast or pressure.state == "RISING" then
        mode = "CAUTION"
    elseif action.action == "ROTATE" or action.action == "REALLOCATE" then
        mode = "ROTATE"
    elseif recovery.open then
        mode = "RECOVERY"
    elseif execution.active and execution.confidence == "NONE" then
        mode = "UNKNOWN"
    end
    if mode ~= self.mode then self:ApplyMode(mode) end
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
    if enabled then self:Update(KWR.Store:Get()) end
end

function CursorRing:Toggle()
    self:SetEnabled(not KWR.db.profile.cursor.enabled)
    KWR:Print("Cursor Ring " .. (KWR.db.profile.cursor.enabled and "enabled." or "disabled."), true)
end

function CursorRing:OnInitialize()
    KWR.Store:Subscribe(self, self.Update)
    if KWR.db.profile.cursor.enabled == true then self:Apply() end
end

function CursorRing:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("CursorRing", CursorRing)
