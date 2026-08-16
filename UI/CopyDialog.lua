local _, KWR = ...

local CopyDialog = {}
KWR.CopyDialog = CopyDialog

local function safeNumber(value, fallback)
    local number = tonumber(value)
    return number ~= nil and number or fallback
end

local function scrollRange(scroll)
    if not scroll or not scroll.GetVerticalScrollRange then return 0 end
    local ok, range = pcall(scroll.GetVerticalScrollRange, scroll)
    return ok and math.max(0, safeNumber(range, 0)) or 0
end

local function clampScroll(scroll, value)
    if not scroll or not scroll.SetVerticalScroll then return end
    if scroll._kwrClamping then return end
    local current = safeNumber(value, scroll.GetVerticalScroll and scroll:GetVerticalScroll() or 0)
    local target = math.min(scrollRange(scroll), math.max(0, current))
    local live = safeNumber(scroll.GetVerticalScroll and scroll:GetVerticalScroll() or 0, 0)
    if math.abs(live - target) < 0.5 then
        return
    end
    scroll._kwrClamping = true
    scroll:SetVerticalScroll(target)
    scroll._kwrClamping = false
end

local function setScrollBody(frame)
    if not frame or not frame.edit or not frame.scrollChild then return end
    if frame._sizing then return end
    frame._sizing = true
    local width = math.max(240, (frame.scroll:GetWidth() or 520) - 12)
    if (frame.edit:GetWidth() or 0) ~= width then
        frame.edit:SetWidth(width)
    end
    local stringHeight = 0
    if frame.edit.GetStringHeight then
        local ok, height = pcall(frame.edit.GetStringHeight, frame.edit)
        if ok then
            stringHeight = safeNumber(height, 0)
        end
    end
    local height = math.max(frame.scroll:GetHeight() or 220, stringHeight + 20)
    if (frame.edit:GetHeight() or 0) ~= height then
        frame.edit:SetHeight(height)
    end
    if frame.body then
        frame.body:SetSize(width, height)
    end
    if (frame.scrollChild:GetWidth() or 0) ~= width
        or (frame.scrollChild:GetHeight() or 0) ~= height then
        frame.scrollChild:SetSize(width, height)
    end
    clampScroll(frame.scroll)
    frame._sizing = false
end

local function focusAndSelectAll(edit)
    if not edit then return end
    edit:SetFocus()
    edit:SetCursorPosition(0)
    edit:HighlightText(0, -1)
end

function CopyDialog:Create()
    if self.frame then return self.frame end

    local profile = KWR.db.profile.copyDialog or {}
    local frame = CreateFrame("Frame", "KWR_CopyDialog", UIParent, "BackdropTemplate")
    frame:SetSize(820, 560)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    frame:SetBackdropColor(0.01, 0.02, 0.04, 0.97)
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()

    frame.title = KWR.Theme:Title(frame, 16)
    frame.title:SetPoint("TOPLEFT", 16, -14)
    frame.title:SetPoint("TOPRIGHT", -44, -14)
    frame.title:SetText("KWR Manual Copy")

    frame.note = KWR.Theme:Font(frame, 9, "soft")
    frame.note:SetPoint("TOPLEFT", 16, -38)
    frame.note:SetPoint("TOPRIGHT", -16, -38)
    frame.note:SetHeight(40)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)

    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 16, -84)
    frame.scroll:SetPoint("BOTTOMRIGHT", -32, 54)
    if frame.scroll.EnableMouseWheel then
        frame.scroll:EnableMouseWheel(true)
        frame.scroll:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll() or 0
            clampScroll(self, current - (delta * 36))
        end)
    end
    frame.scroll:SetScript("OnScrollRangeChanged", function(self)
        clampScroll(self)
    end)

    frame.scrollChild = CreateFrame("Frame", nil, frame.scroll)
    frame.scrollChild:SetSize(740, 240)
    frame.scroll:SetScrollChild(frame.scrollChild)

    frame.body = CreateFrame("Frame", nil, frame.scrollChild, "BackdropTemplate")
    frame.body:SetPoint("TOPLEFT", 0, 0)
    frame.body:SetPoint("TOPRIGHT", 0, 0)
    KWR.Theme:Style(frame.body, "panel", "border")
    frame.body:SetBackdropColor(0.01, 0.02, 0.04, 0.97)
    frame.body:SetBackdropBorderColor(0, 0, 0, 0)

    local edit = CreateFrame("EditBox", nil, frame.body)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetMultiLine(true)
    edit:SetPoint("TOPLEFT", 8, -8)
    edit:SetPoint("BOTTOMRIGHT", -8, 8)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    if edit.SetTextInsets then
        edit:SetTextInsets(2, 2, 2, 2)
    end
    if type(edit.Left) == "table" and edit.Left.Hide then edit.Left:Hide() end
    if type(edit.Middle) == "table" and edit.Middle.Hide then edit.Middle:Hide() end
    if type(edit.Right) == "table" and edit.Right.Hide then edit.Right:Hide() end
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    edit:SetScript("OnMouseUp", function(self)
        self:SetFocus()
    end)
    edit:SetScript("OnTextChanged", function()
        if frame._sizing then return end
        setScrollBody(frame)
    end)
    frame.edit = edit

    local selectAll = KWR.Theme:Button(frame, "SELECT ALL", 96, 26, function()
        focusAndSelectAll(edit)
    end)
    selectAll:SetPoint("BOTTOMRIGHT", -102, 16)

    local close = KWR.Theme:Button(frame, "CLOSE", 78, 26, function()
        edit:ClearFocus()
        frame:Hide()
    end)
    close:SetPoint("BOTTOMRIGHT", -16, 16)

    self.frame = frame
    return frame
end

function CopyDialog:ShowText(title, value, options)
    local frame = self:Create()
    options = options or {}
    frame:ClearAllPoints()
    local profile = KWR.db.profile.copyDialog or {}
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetSize(options.width or 820, options.height or 560)
    frame.title:SetText(title or "KWR Manual Copy")
    frame.note:SetText(options.note
        or "Scroll to review the full text. Copy stays manual from this window.")
    frame.note:Show()
    frame.edit:SetMultiLine(true)
    frame.edit:SetText(value or "")
    frame:Show()
    if KWR.CursorRing and KWR.CursorRing.RefreshReticle then KWR.CursorRing:RefreshReticle() end
    setScrollBody(frame)
    clampScroll(frame.scroll, 0)
    focusAndSelectAll(frame.edit)
end

function CopyDialog:ShowCompact(title, value, options)
    local frame = self:Create()
    options = options or {}
    frame:ClearAllPoints()
    local profile = KWR.db.profile.copyDialog or {}
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetSize(options.width or 620, options.height or 220)
    frame.title:SetText(title or "KWR Quick Call")
    frame.note:SetText(options.note or "Manual copy only. Select the full call, then copy it from this window.")
    frame.note:Show()
    frame.edit:SetMultiLine(true)
    frame.edit:SetText(value or "")
    frame:Show()
    if KWR.CursorRing and KWR.CursorRing.RefreshReticle then KWR.CursorRing:RefreshReticle() end
    setScrollBody(frame)
    clampScroll(frame.scroll, 0)
    focusAndSelectAll(frame.edit)
end

function CopyDialog:OnInitialize()
    -- Created only when the user requests an export or report.
end

KWR:RegisterModule("CopyDialog", CopyDialog)
