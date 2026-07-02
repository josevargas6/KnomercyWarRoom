local _, KWR = ...

local CopyDialog = {}
KWR.CopyDialog = CopyDialog

function CopyDialog:Create()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KWR_CopyDialog", UIParent, "BackdropTemplate")
    frame:SetSize(620, 240)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "gold")
    frame:Hide()

    frame.title = KWR.Theme:Title(frame, 16)
    frame.title:SetPoint("TOPLEFT", 16, -14)
    frame.title:SetText("KWR Manual Copy")

    local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetPoint("TOPLEFT", 16, -46)
    edit:SetPoint("BOTTOMRIGHT", -16, 46)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    frame.edit = edit

    local highlight = KWR.Theme:Button(frame, "Highlight", 90, 24, function()
        edit:SetFocus()
        edit:HighlightText()
    end)
    highlight:SetPoint("BOTTOMRIGHT", -94, 14)

    local close = KWR.Theme:Button(frame, "Close", 70, 24, function()
        edit:ClearFocus()
        frame:Hide()
    end)
    close:SetPoint("BOTTOMRIGHT", -16, 14)

    self.frame = frame
    return frame
end

function CopyDialog:ShowText(title, value)
    local frame = self:Create()
    frame:SetSize(620, 240)
    frame.title:SetText(title or "KWR Manual Copy")
    frame.edit:SetMultiLine(true)
    frame.edit:SetText(value or "")
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

function CopyDialog:ShowCompact(title, value)
    local frame = self:Create()
    frame:SetSize(460, 126)
    frame.title:SetText(title or "KWR Quick Call")
    frame.edit:SetMultiLine(false)
    frame.edit:SetText(value or "")
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

function CopyDialog:OnInitialize()
    -- Created only when the user requests an export or report.
end

KWR:RegisterModule("CopyDialog", CopyDialog)
