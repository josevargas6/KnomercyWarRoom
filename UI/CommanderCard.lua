local _, KWR = ...

local Card = {}
KWR.CommanderCard = Card

local LEGACY_KEYS = { "dragHandle", "brand", "mode", "rescan", "request", "refresh", "reassess",
    "score", "status", "timer", "alertBadge", "truthBadge", "alert", "win", "next", "mine", "caller", "kill" }
local LEFT = { "now", "position", "next", "duties" }
local RIGHT = { "localFight", "controls", "speech" }
local ALL = { "now", "position", "next", "duties", "localFight", "controls", "speech" }

local function number(value, fallback)
    value = KWR.Util:Number(value, nil)
    return value and value == value and value > 0 and value < math.huge and value or fallback
end

local function cursor()
    local x, y = KWR.Util:Call(GetCursorPosition)
    return KWR.Util:Number(x, 0) or 0, KWR.Util:Number(y, 0) or 0
end

local function measure(font, value, width, size)
    font:SetFont(KWR.Theme.fontPath, size, "")
    font:SetWidth(width)
    font:SetHeight(0)
    font:SetWordWrap(true)
    font:SetNonSpaceWrap(true)
    font:SetSpacing(size * 0.15)
    font:SetText(value)
    local height = number(font:GetStringHeight(), nil)
    -- A missing engine measurement is not a passing geometry result.
    font:SetHeight(height or size * 1.2)
    return height or size * 1.2, height ~= nil
end

local function joinNames(rows)
    local names = {}
    for _, actor in ipairs(rows or {}) do names[#names + 1] = actor.label or actor.name end
    return table.concat(names, ", ")
end

function Card:Content(view)
    local labels = KWR.CommandView.CardStrings
    local duties, controls = {}, {}
    for _, duty in ipairs(view.duties) do
        duties[#duties + 1] = duty.group .. " | " .. (duty.actor.label or duty.actor.name)
            .. "\n" .. duty.job .. " -> " .. duty.location
    end
    for _, control in ipairs(view.controls) do
        controls[#controls + 1] = (control.actor.label or control.actor.name) .. "\n"
            .. control.verb .. " -> " .. (control.target.label or control.target.name)
            .. "\n" .. control.status .. " | " .. control.location .. " | " .. control.timing
    end
    local now = view.now.action .. "\nAT: " .. view.now.location .. " | " .. view.now.timing
    if view.now.condition ~= "" then now = now .. "\n" .. view.now.condition end
    if view.now.abort ~= "" then now = now .. "\nABORT: " .. view.now.abort end
    local nextMove = view.next.action .. "\nTO: " .. view.next.location .. "\nTRIGGER: " .. view.next.trigger
    if #view.next.movers > 0 then nextMove = nextMove .. "\nWHO: " .. joinNames(view.next.movers) end
    if view.next.abort ~= "" then nextMove = nextMove .. "\nABORT: " .. view.next.abort end
    local fight = view.localFight
    local localText = fight.target and (fight.intent .. " -> " .. fight.target.name
        .. "\n" .. fight.location .. " | " .. fight.timing) or labels.noTarget
    if view.phase == "STALE" or view.phase == "ENDED" then
        now, nextMove, duties, controls = view.speech, labels.noNext, {}, {}
    end
    return { now = now, position = view.position.text, next = nextMove,
        duties = #duties > 0 and table.concat(duties, "\n\n") or "No named current duties",
        localFight = localText,
        controls = #controls > 0 and table.concat(controls, "\n\n") or labels.noControl,
        speech = view.speech }
end

function Card:ClockText(view)
    if view.phase ~= "LIVE" and view.phase ~= "PREVIEW" then return "Timers unavailable" end
    local now, parts = KWR.Util:Now(), {}
    if view.countdown then
        local seconds = math.ceil(view.countdown.deadline - now)
        if seconds > 0 then parts[#parts + 1] = "GO IN " .. tostring(seconds)
        elseif now < view.countdown.deadline + 1 then parts[#parts + 1] = "GO NOW" end
    end
    if view.objectiveClock and view.objectiveClock.deadline > now then
        parts[#parts + 1] = view.objectiveClock.label .. " " .. KWR.Util:Clock(view.objectiveClock.deadline - now)
            .. " (" .. view.objectiveClock.source .. ")"
    end
    if view.next.deadline then
        parts[#parts + 1] = view.next.deadline > now and ("NEXT deadline " .. KWR.Util:Clock(view.next.deadline - now))
            or "NEXT deadline passed - await a new order"
    end
    return #parts > 0 and table.concat(parts, " | ") or "No confirmed countdown or objective timer"
end

function Card:BeginFeedback(frame, button, mark)
    frame.pending = nil
    if button ~= "LeftButton" and button ~= "RightButton" then return end
    if not frame.focus or not frame.view or not frame.view.eligible or not frame.fit then return end
    local x, y = cursor()
    frame.pending = { focus = KWR.Util:Copy(frame.focus), key = frame.view.callKey,
        button = button, mark = mark or (button == "RightButton" and "FOLLOWED" or "NOT_FOLLOWED"), x = x, y = y }
end

function Card:EndFeedback(frame, button)
    local pending = frame.pending
    frame.pending = nil
    if not pending or pending.button ~= button then return false end
    local x, y = cursor()
    if math.abs(x - pending.x) > 4 or math.abs(y - pending.y) > 4 then return false end
    if not frame.view or frame.view.callKey ~= pending.key then
        frame.message = "Call changed - mark again"
        self:FeedbackText(frame)
        return false
    end
    if not KWR.AAR or not KWR.AAR.MarkFollowthrough then return false end
    local ok, message, event = KWR.AAR:MarkFollowthrough(pending.focus, pending.mark, true)
    frame.message = message
    if ok then
        frame.lastMarkedFocus = pending.focus
        frame.lastMarkedEventId = event and event.eventId
    end
    self:FeedbackText(frame)
    return ok
end

function Card:FeedbackText(frame)
    local state = "UNMARKED"
    if frame.focus and KWR.AAR and KWR.AAR.FollowthroughState then
        state = KWR.AAR:FollowthroughState(frame.focus)
    end
    frame.feedbackValue:SetText((frame.focus and ("Call " .. tostring(frame.focus.calloutRevision))
        or "Feedback unavailable") .. " | " .. state
        .. "\nLeft: Not followed  |  Right: Followed\nFollowed does not mean successful"
        .. (frame.message and ("\n" .. frame.message) or ""))
    local eligible = frame.focus ~= nil and frame.view and frame.view.eligible and frame.fit == true
    frame.notFollowed:SetEnabled(eligible == true)
    frame.followed:SetEnabled(eligible == true)
    frame.undo:SetEnabled(frame.lastMarkedEventId ~= nil)
    frame.review:SetEnabled(frame.lastMarkedFocus ~= nil)
end

function Card:Create(host)
    if host.commanderCard then return host.commanderCard end
    local frame = CreateFrame("Frame", nil, host, "BackdropTemplate")
    host.commanderCard = frame
    frame:SetAllPoints(host)
    frame:EnableMouse(true)
    if frame.SetPropagateMouseClicks then frame:SetPropagateMouseClicks(false) end
    frame:RegisterForDrag("LeftButton")
    frame.sections = {}
    frame.host = host
    KWR.Theme:Style(frame, "background", "borderHi")
    frame:SetBackdropColor(0.025, 0.035, 0.055, 0.97)
    frame.title = KWR.Theme:Font(frame, 17, "white", "LEFT")
    frame.context = KWR.Theme:Font(frame, 13, "gold", "LEFT")
    frame.timeLine = KWR.Theme:Font(frame, 13, "soft", "LEFT")
    frame.notice = KWR.Theme:Font(frame, 13, "yellow", "LEFT")
    frame.drag = CreateFrame("Frame", nil, frame)
    frame.drag:EnableMouse(true)
    frame.drag:RegisterForDrag("LeftButton")
    frame.drag:SetScript("OnMouseDown", function() frame.pending = nil end)
    frame.drag:SetScript("OnDragStart", function()
        frame.pending = nil
        local profile = KWR.db.profile.hud
        if profile.locked or (InCombatLockdown and InCombatLockdown()) then return end
        host:StartMoving()
    end)
    frame.drag:SetScript("OnDragStop", function() KWR.Theme:FinishMove(host, KWR.db.profile.hud) end)
    frame:SetScript("OnMouseDown", function(_, button) Card:BeginFeedback(frame, button) end)
    frame:SetScript("OnMouseUp", function(_, button) Card:EndFeedback(frame, button) end)
    frame:SetScript("OnDragStart", function() frame.pending = nil end)
    frame:SetScript("OnHide", function() frame.pending = nil end)
    frame.menu = KWR.Theme:Button(frame, "MENU", 70, 26, function()
        frame.pending = nil
        KWR.MainWindow:Show("TACTICAL")
    end)
    frame.wide = KWR.Theme:Button(frame, "WIDE", 70, 26, function()
        frame.pending = nil
        local profile = KWR.db.profile.hud
        profile.cardWide = not profile.cardWide
        Card:Render(host, KWR.HUD.lastState)
    end)
    frame.copy = KWR.Theme:Button(frame, "COPY CALL", 110, 26, function()
        frame.pending = nil
        if frame.view then KWR.CopyDialog:ShowText("SAY NOW - " .. frame.view.phase, frame.view.speech) end
    end)
    for _, key in ipairs(ALL) do
        local section = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        section:EnableMouse(false)
        KWR.Theme:Style(section, "panel", "border")
        section.heading = KWR.Theme:Font(section, 12, key == "localFight" and "orange" or "gold", "LEFT")
        section.value = KWR.Theme:Font(section, 13, "white", "LEFT")
        section.value:SetJustifyV("TOP")
        frame.sections[key] = section
    end
    frame.feedbackValue = KWR.Theme:Font(frame, 13, "soft", "LEFT")
    for _, pair in ipairs({ { "notFollowed", "NOT FOLLOWED", "NOT_FOLLOWED" }, { "followed", "FOLLOWED", "FOLLOWED" } }) do
        local mark = pair[3]
        local button = KWR.Theme:Button(frame, pair[2], 132, 28, function() end)
        button:SetScript("OnMouseDown", function(_, mouse) Card:BeginFeedback(frame, mouse, mark) end)
        button:SetScript("OnMouseUp", function(_, mouse) Card:EndFeedback(frame, mouse) end)
        frame[pair[1]] = button
    end
    frame.undo = KWR.Theme:Button(frame, "UNDO", 70, 28, function()
        frame.pending = nil
        if not frame.lastMarkedFocus or not frame.lastMarkedEventId then return end
        local ok, message = KWR.AAR:UndoFollowthrough(frame.lastMarkedFocus, frame.lastMarkedEventId)
        if ok then frame.lastMarkedEventId = nil end
        frame.message = message
        Card:FeedbackText(frame)
    end)
    frame.review = KWR.Theme:Button(frame, "LAST MARK", 110, 28, function()
        frame.pending = nil
        if frame.lastMarkedFocus and KWR.AAR and KWR.AAR.FollowthroughReview then
            KWR.CopyDialog:ShowText("LAST MARK - previous call, not the current order",
                KWR.AAR:FollowthroughReview(frame.lastMarkedFocus))
        end
    end)
    for _, key in ipairs({ "menu", "wide", "copy", "undo", "review" }) do
        frame[key]:SetScript("OnMouseDown", function() frame.pending = nil end)
        frame[key]:SetScript("OnMouseUp", function() frame.pending = nil end)
    end
    return frame
end

function Card:Layout(frame, viewportWidth, viewportHeight, scale)
    scale = number(scale, 1)
    viewportWidth, viewportHeight = number(viewportWidth, 1920), number(viewportHeight, 1080)
    local unit = 1 / scale
    local pad, gap, bodySize = 10 * unit, 8 * unit, 13 * unit
    local availableWidth, availableHeight = viewportWidth - 24 * unit, viewportHeight - 24 * unit
    local maxWidth = math.min(availableWidth, 1800 * unit)
    local labels = KWR.CommandView.CardStrings
    local content = self:Content(frame.view)
    frame.bounds = {}
    local function place(key, x, y, width)
        local section = frame.sections[key]
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
        section:SetWidth(width)
        section.heading:ClearAllPoints()
        section.heading:SetPoint("TOPLEFT", section, "TOPLEFT", pad, -pad)
        local headingHeight, headingOK = measure(section.heading, labels[key], width - 2 * pad, 12 * unit)
        section.value:ClearAllPoints()
        section.value:SetPoint("TOPLEFT", section, "TOPLEFT", pad, -(pad + headingHeight + 5 * unit))
        local valueSize = key == "now" and 16 * unit or (key == "localFight" and 15 * unit or bodySize)
        local valueHeight, valueOK = measure(section.value, content[key], width - 2 * pad, valueSize)
        local naturalHeight = pad * 2 + headingHeight + 5 * unit + valueHeight
        -- Calls may legitimately get shorter as a target dies or an assignment
        -- clears.  Do not let that make the live card shrink, grow again, and
        -- appear to jump around its saved anchor.  Floors are per resolved
        -- column width, so an intentional WIDE toggle or UI-scale change can
        -- still receive a fresh, correct measurement.
        local floors = frame.sectionHeightFloors[frame.floorKey]
        local height = math.max(naturalHeight, floors[key] or 0)
        floors[key] = height
        section:SetHeight(height)
        section:Show()
        frame.measurementOK = frame.measurementOK and headingOK and valueOK
        frame.bounds[key] = { x = x, y = y, width = width, height = height,
            valueHeight = valueHeight, headingHeight = headingHeight, text = content[key] }
        frame.bounds[key].fontSize = valueSize
        return y + height + gap
    end
    local function arrange(width, wide, showFailure)
        frame.floorKey = string.format("%d:%d:%s", math.floor(width + 0.5),
            math.floor(unit * 1000 + 0.5), wide and "wide" or "compact")
        frame.sectionHeightFloors = frame.sectionHeightFloors or {}
        frame.sectionHeightFloors[frame.floorKey] = frame.sectionHeightFloors[frame.floorKey] or {}
        frame.contentHeightFloors = frame.contentHeightFloors or {}
        frame.measurementOK = true
        frame.title:ClearAllPoints()
        frame.title:SetPoint("TOPLEFT", pad, -pad)
        measure(frame.title, "KWR / COMMANDER", width - 2 * pad - 300 * unit, 17 * unit)
        frame.context:ClearAllPoints()
        frame.context:SetPoint("TOPLEFT", pad, -44 * unit)
        local contextHeight = measure(frame.context, frame.view.map .. " | " .. frame.view.bracket
            .. " | " .. frame.view.phase .. "\nSCORE " .. frame.view.score .. " | " .. frame.view.winPath
            .. (showFailure and ("\n" .. labels.fitFailure) or ""), width - 2 * pad, bodySize)
        frame.timeLine:ClearAllPoints()
        frame.timeLine:SetPoint("TOPLEFT", pad, -(44 * unit + contextHeight + 4 * unit))
        local clockHeight = measure(frame.timeLine, self:ClockText(frame.view), width - 2 * pad, bodySize)
        clockHeight = math.max(clockHeight, 36 * unit)
        frame.timeLine:SetHeight(clockHeight)
        local top = 44 * unit + contextHeight + 4 * unit + clockHeight + gap
        local y = top
        if wide then
            local column = (width - 2 * pad - gap) / 2
            local leftY, rightY = top, top
            for _, key in ipairs(LEFT) do leftY = place(key, pad, leftY, column) end
            for _, key in ipairs(RIGHT) do rightY = place(key, pad + column + gap, rightY, column) end
            y = math.max(leftY, rightY)
        else
            for _, key in ipairs(ALL) do y = place(key, pad, y, width - 2 * pad) end
        end
        frame.feedbackValue:ClearAllPoints()
        frame.feedbackY = y
        frame.feedbackValue:SetPoint("TOPLEFT", pad, -y)
        self:FeedbackText(frame)
        measure(frame.feedbackValue, frame.feedbackValue:GetText(), width - 2 * pad, bodySize)
        -- Reserve a complete confirmation line; a click never changes card geometry.
        frame.feedbackValue:SetHeight(96 * unit)
        y = y + 102 * unit
        frame.buttonY = y
        local x = pad
        for _, key in ipairs({ "notFollowed", "followed", "undo", "review" }) do
            local button = frame[key]
            local pixels = (key == "notFollowed" or key == "followed") and 132 or (key == "undo" and 70 or 110)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
            button:SetSize(pixels * unit, 28 * unit)
            button.label:SetFont(KWR.Theme.fontPath, 12 * unit, "")
            x = x + (pixels + 6) * unit
        end
        local naturalContentHeight = y + 28 * unit + pad
        local contentFloor = frame.contentHeightFloors[frame.floorKey] or 0
        frame.contentHeight = math.max(naturalContentHeight, contentFloor)
        frame.contentHeightFloors[frame.floorKey] = frame.contentHeight
        frame.layoutMode = wide and "WIDE" or "COMPACT"
        frame.layoutWidth = width
        return frame.contentHeight
    end
    local wide = KWR.db.profile.hud.cardWide == true
    local width = math.min(maxWidth, (wide and 1050 or 590) * unit)
    local height = arrange(width, wide)
    if height > availableHeight and not wide then
        wide, width = true, math.min(maxWidth, 1050 * unit)
        height = arrange(width, wide)
    end
    if height > availableHeight and width < maxWidth then
        width = maxWidth
        height = arrange(width, true)
    end
    frame.fit = frame.measurementOK and #frame.view.errors == 0 and height <= availableHeight and width >= 510 * unit
    if not frame.fit then height = arrange(width, wide, true) end
    frame.notice:Hide()
    frame.host:SetSize(width, height)
    self:FeedbackText(frame)
    frame.host:SetClampedToScreen(true)
    frame.drag:ClearAllPoints()
    frame.drag:SetPoint("TOPLEFT", 0, 0)
    frame.drag:SetSize(math.max(40 * unit, width - 300 * unit), 38 * unit)
    for index, key in ipairs({ "menu", "wide", "copy" }) do
        frame[key]:ClearAllPoints()
        frame[key]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(pad + (index - 1) * 90 * unit), -pad)
        frame[key]:SetSize((key == "copy" and 100 or 78) * unit, 26 * unit)
        frame[key].label:SetFont(KWR.Theme.fontPath, 12 * unit, "")
    end
    return frame.fit
end

function Card:Render(host, state)
    local frame = self:Create(host)
    if not host.cardActive then host.legacyCardWidth = host:GetWidth() end
    local view = KWR.CommandView:CommanderCard(state)
    frame.view = view
    frame.focus = KWR.AAR and KWR.AAR.FeedbackFocus and KWR.AAR:FeedbackFocus(view) or nil
    host.cardActive = true
    for _, key in ipairs(LEGACY_KEYS) do if host[key] then host[key]:Hide() end end
    host.timerEndAt = nil
    host:RegisterForDrag() -- Only the dedicated header handle moves the card.
    local scale = number(host:GetEffectiveScale(), 1)
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local parts = { view.phase, view.map, view.bracket, view.score, view.winPath,
        tostring(view.objectiveClock and view.objectiveClock.deadline), tostring(view.next.deadline),
        tostring(width), tostring(height), tostring(scale),
        tostring(KWR.db.profile.hud.cardWide), view.callKey }
    local content = self:Content(view)
    for _, key in ipairs(ALL) do
        local value = content[key]
        parts[#parts + 1] = tostring(#value) .. ":" .. value
    end
    local layoutKey = table.concat(parts, "\030")
    if frame.lastLayoutKey ~= layoutKey then
        self:Layout(frame, width, height, scale)
        frame.lastLayoutKey = layoutKey
    else
        self:FeedbackText(frame)
    end
    frame:Show()
    host:Show()
    return view
end

function Card:Hide(host)
    if not host or not host.cardActive then return end
    host.cardActive = nil
    host.commanderCard.sectionHeightFloors = nil
    host.commanderCard.contentHeightFloors = nil
    host.commanderCard.lastLayoutKey = nil
    host:SetWidth(number(host.legacyCardWidth, 432))
    host.commanderCard:Hide()
    host:RegisterForDrag("LeftButton")
    for _, key in ipairs(LEGACY_KEYS) do if host[key] then host[key]:Show() end end
end

function Card:Tick(host)
    if not host or not host.cardActive or not host:IsShown() then return end
    local frame = host.commanderCard
    local view = frame.view
    local now = KWR.Util:Now()
    -- Only invalidate a retired/freshness boundary, not rerun the planner or
    -- remeasure all text at the countdown cadence.
    if view and view.phase == "LIVE" and view.capturedAt and now - view.capturedAt > 5 then
        self:Render(host, KWR.HUD.lastState)
    elseif view and view.countdown and now >= view.countdown.deadline + 1 then
        self:Render(host, KWR.HUD.lastState)
    end
    if frame.view then frame.timeLine:SetText(self:ClockText(frame.view)) end
end
