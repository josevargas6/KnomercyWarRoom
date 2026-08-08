local _, KWR = ...

local AARWindow = {
    selected = {},
}
KWR.AARWindow = AARWindow

local function text(value, fallback, limit)
    return KWR.Util:Text(value, fallback or "", limit or 160)
end

local function yesNo(value)
    return value and "YES" or "NO"
end

local function countEvidenceNotes(entry)
    local total = 0
    for _, player in pairs(entry and entry.playerEvidence or {}) do
        total = total + #(player.notes or {})
    end
    return total
end

local function statusColor(status)
    if status == "WIN" or status == "VICTORY" then return "green" end
    if status == "LOSE" or status == "DEFEAT" then return "red" end
    if status == "TIE" then return "yellow" end
    return "muted"
end

local function latestDecisionReview(entry)
    local reviews = entry and entry.decisionReviews or {}
    return reviews[#reviews]
end

local function cardText(card, color)
    card.value = KWR.Theme:Font(card, 9, color or "soft", "LEFT")
    card.value:SetPoint("TOPLEFT", 10, -32)
    card.value:SetPoint("BOTTOMRIGHT", -10, 8)
    if card.value.SetWordWrap then card.value:SetWordWrap(true) end
    if card.value.SetNonSpaceWrap then card.value:SetNonSpaceWrap(true) end
    return card.value
end

local function createEntry(parent, x, y, width, height, multiLine)
    local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    holder:SetPoint("TOPLEFT", x, y)
    holder:SetSize(width, height)
    KWR.Theme:Style(holder, "panel", "border")
    holder:SetBackdropColor(0.01, 0.02, 0.04, 0.92)

    local edit = CreateFrame("EditBox", nil, holder)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetPoint("TOPLEFT", 8, -8)
    edit:SetPoint("BOTTOMRIGHT", -8, 8)
    edit:SetMultiLine(multiLine == true)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    if edit.SetTextInsets then
        edit:SetTextInsets(2, 2, 2, 2)
    end
    edit:SetTextColor(KWR.Theme:Color("white"))
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    holder.edit = edit
    return holder, edit
end

local function sessionTypeText(entry)
    local value = text(entry and entry.feedback and entry.feedback.sessionType, "", 24)
    return value ~= "" and value or "Unlabeled"
end

local function snapshotText(entry)
    local stability = entry and entry.commandStability or {}
    local latestCommand = entry and entry.commands and entry.commands[#entry.commands] or {}
    local activePlay = latestCommand.activePlay or {}
    local activeDecision = latestCommand.activePlayDecision or {}
    local replacementScore = activeDecision.replacementScore or {}
    return table.concat({
        "RESULT  " .. text(entry.result, "UNKNOWN", 20),
        "SESSION  " .. sessionTypeText(entry),
        "FINAL  " .. ((entry.scoreEnd and entry.scoreEnd.friendly and entry.scoreEnd.enemy)
            and (tostring(entry.scoreEnd.friendly) .. " - " .. tostring(entry.scoreEnd.enemy))
            or "Unknown"),
        "DURATION  " .. KWR.Util:Clock(entry.duration or 0),
        "ISSUED  " .. tostring(stability.issued or 0),
        "RETAINED  " .. tostring(stability.retainedRecords or #(entry.commands or {})),
        "SWAPS  " .. tostring(stability.replacements or 0),
        "STABILITY  " .. text(stability.commandHealth, "UNKNOWN", 16),
        "AVG LIFE  " .. (((stability.averageLifetime or 0) > 0
                and KWR.Util:Clock(stability.averageLifetime))
            or "Unknown"),
        "PLAN LANE  " .. text(activePlay.objective, "Current lane", 36),
        "COMMIT  " .. tostring(math.floor((activePlay.commitmentSeconds or 0) + 0.5)) .. "s"
            .. " / NEED " .. tostring(math.floor((replacementScore.requiredDuration or 0) + 0.5)) .. "s",
        "PLAN  " .. text(entry.primaryPlanID, "No primary plan", 48),
        "RATING  " .. tostring(entry.ratingChange or "Unknown"),
    }, "\n")
end

local function decisionText(entry)
    local review = latestDecisionReview(entry)
    local latestCommand = entry and entry.commands and entry.commands[#entry.commands] or {}
    local activeDecision = latestCommand.activePlayDecision or {}
    local activeOutcome = latestCommand.activePlayOutcome or {}
    local activeTransition = latestCommand.activePlayTransition or {}
    local replacementScore = activeDecision.replacementScore or {}
    if not review then
        return "No qualified decision review recorded."
    end
    return table.concat({
        "CALL  " .. text(review.recommendation, "Unknown", 72),
        "CONTEXT  " .. sessionTypeText(entry),
        "MODE  " .. text(review.recommendationMode, "UNKNOWN", 24),
        "EXPECT  " .. text(review.expectedOutcome, "Unknown", 52),
        "CALL GRADE  " .. text(review.decisionQuality, "UNKNOWN", 24),
        "EXECUTION  " .. text(review.executionQuality, "UNKNOWN", 24),
        "TRUTH  " .. text(review.truthQuality, "UNKNOWN", 24),
        "ENEMY ANSWER  " .. text(review.enemyReadQuality, "UNKNOWN", 24),
        "LOSS TYPE  " .. text(review.failureMode, "NONE", 24),
        "OUTCOME  " .. text(activeOutcome.status, "LIVE", 20)
            .. " / " .. text(activeOutcome.bucket, "PRE_ARRIVAL", 20),
        "TRANSITION  " .. text(activeTransition.trigger, "STEADY", 20)
            .. " / " .. text(activeTransition.fromPhase, "NONE", 16)
            .. " -> " .. text(activeTransition.toPhase, "UNKNOWN", 16),
        "HELD  " .. tostring(math.floor((replacementScore.observedDuration or 0) + 0.5))
            .. " / " .. tostring(math.floor((replacementScore.requiredDuration or 0) + 0.5)) .. "s",
        "ALT  " .. text(review.competingOption, "No logged alternative", 52),
    }, "\n")
end

local function evidenceText(entry)
    local lastObjective = entry and entry.objectiveTimeline
        and entry.objectiveTimeline[#entry.objectiveTimeline] or nil
    local stability = entry and entry.commandStability or {}
    local latestOverride = stability.latestOverride
    local latestCommand = entry and entry.commands and entry.commands[#entry.commands] or {}
    local activePlay = latestCommand.activePlay or {}
    return table.concat({
        "OBJ EVENTS  " .. tostring(#(entry.objectiveTimeline or {})),
        "PLAYER NOTES  " .. tostring(countEvidenceNotes(entry)),
        "THREATS  " .. tostring(#(entry.enemyThreats or {})),
        "REVIEW  " .. yesNo(entry.feedback and next(entry.feedback)),
        "ACTIVEPLAY SWITCHES  " .. tostring(stability.overrides or 0),
        "TRAVEL / USE  " .. tostring(math.floor((activePlay.travelSeconds or 0) + 0.5))
            .. " / " .. tostring(math.floor((activePlay.interactionSeconds or 0) + 0.5)) .. "s",
        lastObjective and ("LAST EVENT  " .. text(lastObjective.text, "Unknown", 52))
            or "LAST EVENT  No qualified objective transition recorded.",
        latestOverride and ("LAST SWITCH  " .. text(latestOverride.replacementReason, "Unknown", 52))
            or "LAST SWITCH  No override recorded.",
    }, "\n")
end

local function lessonText(entry)
    local review = latestDecisionReview(entry)
    if review and review.recommendedLesson and review.recommendedLesson ~= "" then
        return "NEXT LESSON  " .. text(review.recommendedLesson, "Review the key swing.", 96)
    end
    if entry and entry.feedback and entry.feedback.gameChanger
        and entry.feedback.gameChanger ~= "" then
        return "NEXT LESSON  " .. text(entry.feedback.gameChanger, "Review the key swing.", 96)
    end
    if review and review.competingOption and review.competingOption ~= "" then
        return "NEXT LESSON  Revisit " .. text(review.competingOption, "the alternate line", 84)
    end
    if review and review.expectedOutcome and review.expectedOutcome ~= "" then
        return "NEXT LESSON  " .. text(review.expectedOutcome, "Review the expected outcome.", 96)
    end
    return "NEXT LESSON  No reviewed next lesson logged yet."
end

local function sessionInterpretationText(entry)
    local value = sessionTypeText(entry)
    if value == "Commander" then
        return "Context: live command session. Judge call quality and whether the team followed it."
    end
    if value == "Spectator" then
        return "Context: observer session. Use this as watch evidence, not command-follow proof."
    end
    if value == "Diagnostic" then
        return "Context: diagnostic run. Use this to validate KWR behavior, not player compliance."
    end
    return "Context: session type was not tagged."
end

local function choiceGroup(parent, title, options, x, y, width)
    width = width or 246
    local group = KWR.Theme:Card(parent, title)
    group:SetPoint("TOPLEFT", x, y or -72)
    group:SetSize(width, 138)
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
        local button = KWR.Theme:Button(group, label, width - 20, 24, function(self)
            group:SetValue(label)
        end)
        button.choiceValue = label
        button:SetPoint("TOPLEFT", 10, -34 - ((index - 1) * 29))
        group.buttons[index] = button
    end
    return group
end

function AARWindow:Create()
    if self.frame then return self.frame end
    local profile = KWR.db.profile.aarWindow or {}
    local frame = CreateFrame("Frame", "KWR_AARWindow", UIParent, "BackdropTemplate")
    frame:SetSize(960, 780)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    KWR.Theme:Style(frame, "background", "borderHi")
    frame:SetBackdropColor(0.01, 0.02, 0.04, 0.97)
    KWR.Theme:MakeMovable(frame, profile)
    frame:Hide()
    frame.title = KWR.Theme:Title(frame, 17, "CENTER")
    frame.title:SetPoint("TOPLEFT", 18, -14)
    frame.title:SetPoint("TOPRIGHT", -46, -14)
    frame.title:SetText("KWR AFTER ACTION REVIEW")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    frame.resultBadge = KWR.Theme:Badge(frame, "muted", "RESULT", 110, 18)
    frame.resultBadge:SetPoint("TOPLEFT", 18, -48)
    frame.reviewBadge = KWR.Theme:Badge(frame, "muted", "REVIEW OPEN", 120, 18)
    frame.reviewBadge:SetPoint("LEFT", frame.resultBadge, "RIGHT", 8, 0)
    frame.exportBadge = KWR.Theme:Badge(frame, "gold", "EXPORT READY", 118, 18)
    frame.exportBadge:SetPoint("LEFT", frame.reviewBadge, "RIGHT", 8, 0)

    frame.help = KWR.Theme:Font(frame, 9, "soft")
    frame.help:SetPoint("TOPLEFT", 18, -76)
    frame.help:SetPoint("TOPRIGHT", -18, -76)
    frame.help:SetHeight(30)
    frame.help:SetText("Review stays local. Save the lesson you want to keep, then copy export only if you need it.")

    frame.wonBy = choiceGroup(frame, "WIN FACTOR", { "Team Fights", "Objectives", "Rotations" }, 18, -110, 210)
    frame.strength = choiceGroup(frame, "BEST EDGE", { "Coordination", "Calls", "Healing" }, 252, -110, 210)
    frame.heldBack = choiceGroup(frame, "MAIN DRAG", { "Rotations", "Focus Fire", "Defense" }, 486, -110, 210)
    frame.sessionType = choiceGroup(frame, "SESSION", { "Commander", "Spectator", "Diagnostic" }, 720, -110, 222)

    frame.gameChangerLabel = KWR.Theme:SectionLabel(frame, "KEY SWING", 18, -268, 200)
    frame.gameChangerBox, frame.gameChanger = createEntry(frame, 18, -290, 438, 38, false)
    frame.notesLabel = KWR.Theme:SectionLabel(frame, "NOTES", 470, -268, 200)
    frame.notesBox, frame.notes = createEntry(frame, 470, -290, 472, 82, true)

    frame.snapshotCard = KWR.Theme:Card(frame, "SNAPSHOT")
    frame.snapshotCard:SetPoint("TOPLEFT", 18, -388)
    frame.snapshotCard:SetSize(292, 196)
    cardText(frame.snapshotCard, "white")

    frame.reviewCard = KWR.Theme:Card(frame, "COMMAND REVIEW")
    frame.reviewCard:SetPoint("TOPLEFT", 334, -388)
    frame.reviewCard:SetSize(292, 196)
    cardText(frame.reviewCard, "soft")

    frame.evidenceCard = KWR.Theme:Card(frame, "EVIDENCE")
    frame.evidenceCard:SetPoint("TOPLEFT", 650, -388)
    frame.evidenceCard:SetSize(292, 196)
    cardText(frame.evidenceCard, "muted")

    frame.lessonCard = KWR.Theme:Card(frame, "NEXT LESSON")
    frame.lessonCard:SetPoint("TOPLEFT", 18, -596)
    frame.lessonCard:SetSize(924, 58)
    cardText(frame.lessonCard, "gold")

    local submit = KWR.Theme:Button(frame, "SAVE REVIEW", 160, 30, function()
        local ok = KWR.AAR:SaveFeedback(frame.entryID, {
            sessionType = frame.sessionType.value,
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
    submit:SetPoint("BOTTOMLEFT", 274, 18)
    local export = KWR.Theme:Button(frame, "COPY EXPORT", 160, 30, function()
        local text, message = KWR.AAR:Export(KWR.AAR:GetByID(frame.entryID))
        if text then
            KWR.CopyDialog:ShowText("KWR Match Evidence Export", text, {
                note = "Review or copy the evidence export from this window. It remains local unless you manually copy it.",
            })
        else
            KWR:Print(message or "No completed AAR export is available.", true)
        end
    end)
    export:SetPoint("BOTTOMRIGHT", -274, 18)
    self.frame = frame
    return frame
end

function AARWindow:Show(entryID)
    local frame = self:Create()
    local entry = KWR.AAR:GetByID(entryID) or KWR.AAR.lastCompleted
    if not entry then return end
    frame.entryID = entry.id
    frame.title:SetText("KWR AAR  |  " .. entry.mapName)
    frame.resultBadge:SetTone(statusColor(entry.result))
    frame.resultBadge:SetText(text(entry.result, "UNKNOWN", 14))
    frame.reviewBadge:SetTone(entry.feedback and next(entry.feedback) and "green" or "yellow")
    frame.reviewBadge:SetText(entry.feedback and next(entry.feedback) and "REVIEW DONE" or "REVIEW OPEN")
    frame.exportBadge:SetTone("gold")
    frame.exportBadge:SetText("EXPORT READY")
    frame.snapshotCard.value:SetText(snapshotText(entry))
    frame.reviewCard.value:SetText(decisionText(entry))
    frame.evidenceCard.value:SetText(evidenceText(entry))
    frame.lessonCard.value:SetText(lessonText(entry) .. "\n" .. sessionInterpretationText(entry))
    frame.gameChanger:SetText(entry.feedback and entry.feedback.gameChanger or "")
    frame.notes:SetText(entry.feedback and entry.feedback.notes or "")
    frame.sessionType:SetValue(entry.feedback and entry.feedback.sessionType or nil)
    frame.wonBy:SetValue(entry.feedback and entry.feedback.wonBy or nil)
    frame.strength:SetValue(entry.feedback and entry.feedback.strength or nil)
    frame.heldBack:SetValue(entry.feedback and entry.feedback.heldBack or nil)
    frame:Show()
end

function AARWindow:OnInitialize()
    -- Created on first completed-review open; it is not part of the login path.
end

KWR:RegisterModule("AARWindow", AARWindow)
