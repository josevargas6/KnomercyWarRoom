local _, KWR = ...

local ReporterMap = {}
KWR.ReporterMap = ReporterMap

function ReporterMap:Create()
    if self.frame then return self.frame end
    local profile = KWR.db.profile.reporter
    local frame = CreateFrame("Frame", "KWR_ReporterMiniMap", UIParent, "BackdropTemplate")
    frame:SetSize(410, 310)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()

    frame.title = KWR.Theme:Title(frame, 12)
    frame.title:SetPoint("TOPLEFT", 10, -8)
    frame.title:SetText("KWR REPORTER")
    frame.status = KWR.Theme:Font(frame, 8, "muted", "RIGHT", "OUTLINE")
    frame.status:SetPoint("TOPRIGHT", -62, -10)
    frame.status:SetWidth(190)

    local expand = KWR.Theme:Button(frame, "EXPAND", 56, 20, function()
        KWR.MainWindow:Show("TACTICAL")
    end)
    expand:SetPoint("TOPRIGHT", -4, -4)

    frame.map = KWR.TacticalMap:Create(frame)
    frame.map.compact = true
    frame.map:SetPoint("TOPLEFT", 6, -32)
    frame.map:SetPoint("BOTTOMRIGHT", -6, 6)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            KWR.MainWindow:Show("TACTICAL")
        end
    end)
    self.frame = frame
    return frame
end

function ReporterMap:Update(state)
    self.lastState = state
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    local reporter = state.snapshot.reporter or {}
    frame.title:SetText("KWR REPORTER  |  " .. state.snapshot.context.mapName)
    frame.status:SetText(string.format("R%d | %dF/%dE | LOC %d/%d | %dC",
        reporter.risk or 0,
        reporter.coverage and reporter.coverage.friendly or 0,
        reporter.coverage and reporter.coverage.enemy or 0,
        reporter.coverage and reporter.coverage.friendlyLocated or 0,
        reporter.coverage and reporter.coverage.enemyLocated or 0,
        (reporter.coverage and reporter.coverage.friendlyCombat or 0)
            + (reporter.coverage and reporter.coverage.enemyCombat or 0)))
    frame.status:SetTextColor(KWR.Theme:Color((reporter.risk or 0) >= 70 and "red"
        or ((reporter.risk or 0) >= 45 and "yellow" or "green")))
    frame.map:SetState(state)
end

function ReporterMap:Show()
    if KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown() then
        KWR.MainWindow:MinimizeTo("REPORTER")
        return
    end
    local frame = self:Create()
    frame:Show()
    self:Update(KWR.Store:Get())
end

function ReporterMap:Toggle()
    local frame = self:Create()
    if frame:IsShown() then frame:Hide() else self:Show() end
end

function ReporterMap:OnInitialize()
    KWR.Store:Subscribe(self, self.Update)
end

function ReporterMap:OnDisable()
    KWR.Store:Unsubscribe(self)
end

KWR:RegisterModule("ReporterMap", ReporterMap)


