local _, KWR = ...

local AARWindow = {
    selected = {},
}
KWR.AARWindow = AARWindow

local function choiceGroup(parent, title, options, x)
    local group = KWR.Theme:Card(parent, title)
    group:SetPoint("TOPLEFT", x, -54)
    group:SetSize(205, 128)
    group.buttons = {}
    group.SetValue = function(self, value)
        self.value = value
        for _, button in ipairs(self.buttons) do
            button.selected = button.choiceValue == value
            KWR.Theme:Style(button, button.selected and "raised" or "card",
                button.selected and "borderHi" or "border")
            button.label:SetTextColor(KWR.Theme:Color(button.selected and "gold" or "soft"))
        end
    end
    for index, label in ipairs(options) do
        local button = KWR.Theme:Button(group, label, 185, 23, function(self)
            group:SetValue(label)
        end)
        button.choiceValue = label
        button:SetPoint("TOPLEFT", 10, -34 - ((index - 1) * 27))
        group.buttons[index] = button
    end
    return group
end

function AARWindow:Create()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "KWR_AARWindow", UIParent, "BackdropTemplate")
    frame:SetSize(690, 420)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    frame:Hide()
    frame.title = KWR.Theme:Title(frame, 17, "CENTER")
    frame.title:SetPoint("TOPLEFT", 18, -14)
    frame.title:SetPoint("TOPRIGHT", -46, -14)
    frame.title:SetText("KWR AFTER ACTION REVIEW")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    frame.wonBy = choiceGroup(frame, "WHAT WON THIS MATCH?", { "Team Fights", "Objectives", "Rotations" }, 14)
    frame.strength = choiceGroup(frame, "OUR BIGGEST STRENGTH", { "Coordination", "Calls", "Healing" }, 242)
    frame.heldBack = choiceGroup(frame, "WHAT HELD US BACK?", { "Rotations", "Focus Fire", "Defense" }, 470)

    frame.gameChangerLabel = KWR.Theme:SectionLabel(frame, "GAME CHANGER", 18, -198, 180)
    frame.gameChanger = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.gameChanger:SetPoint("TOPLEFT", 18, -218)
    frame.gameChanger:SetSize(310, 28)
    frame.gameChanger:SetAutoFocus(false)
    frame.notesLabel = KWR.Theme:SectionLabel(frame, "ADDITIONAL NOTES", 350, -198, 180)
    frame.notes = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.notes:SetPoint("TOPLEFT", 350, -218)
    frame.notes:SetSize(320, 110)
    frame.notes:SetMultiLine(true)
    frame.notes:SetAutoFocus(false)

    frame.summary = KWR.Theme:Font(frame, 10, "muted")
    frame.summary:SetPoint("TOPLEFT", 18, -262)
    frame.summary:SetSize(310, 78)

    local submit = KWR.Theme:Button(frame, "SAVE MANUAL REVIEW", 190, 30, function()
        local ok = KWR.AAR:SaveFeedback(frame.entryID, {
            wonBy = frame.wonBy.value,
            strength = frame.strength.value,
            heldBack = frame.heldBack.value,
            gameChanger = frame.gameChanger:GetText(),
            notes = frame.notes:GetText(),
        })
        if ok then
            frame:Hide()
            if KWR.MainWindow and KWR.MainWindow.frame and KWR.MainWindow.frame:IsShown() then
                KWR.MainWindow:Update(KWR.Store:Get())
            end
        end
    end)
    submit:SetPoint("BOTTOMLEFT", 142, 16)
    local export = KWR.Theme:Button(frame, "COPY EVIDENCE EXPORT", 190, 30, function()
        local text, message = KWR.AAR:Export(KWR.AAR:GetByID(frame.entryID))
        if text then
            KWR.CopyDialog:ShowText("KWR Match Evidence Export", text)
        else
            KWR:Print(message or "No completed AAR export is available.", true)
        end
    end)
    export:SetPoint("BOTTOMRIGHT", -142, 16)
    self.frame = frame
    return frame
end

function AARWindow:Show(entryID)
    local frame = self:Create()
    local entry = KWR.AAR:GetByID(entryID) or KWR.AAR.lastCompleted
    if not entry then return end
    frame.entryID = entry.id
    frame.title:SetText("KWR AFTER ACTION REVIEW  |  " .. entry.mapName)
    frame.summary:SetText(string.format(
        "%s  |  %s\nFinal score: %d - %d\nCommands recorded: %d",
        entry.result or "UNKNOWN",
        KWR.Util:Clock(entry.duration or 0),
        entry.scoreEnd and entry.scoreEnd.friendly or 0,
        entry.scoreEnd and entry.scoreEnd.enemy or 0,
        #(entry.commands or {})
    ))
    frame.gameChanger:SetText(entry.feedback and entry.feedback.gameChanger or "")
    frame.notes:SetText(entry.feedback and entry.feedback.notes or "")
    frame.wonBy:SetValue(entry.feedback and entry.feedback.wonBy or nil)
    frame.strength:SetValue(entry.feedback and entry.feedback.strength or nil)
    frame.heldBack:SetValue(entry.feedback and entry.feedback.heldBack or nil)
    frame:Show()
end

function AARWindow:OnInitialize()
    -- Created on first completed-review open; it is not part of the login path.
end

KWR:RegisterModule("AARWindow", AARWindow)
