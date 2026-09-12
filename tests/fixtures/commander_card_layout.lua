return function(KWR, input)
    local saved = { layout = KWR.db.profile.hud.cardLayout, wide = KWR.db.profile.hud.cardWide,
        lastState = KWR.HUD.lastState, cursor = _G.GetCursorPosition, mark = KWR.AAR.MarkFollowthrough }
    local host = KWR.HUD:Create()
    local card = KWR.CommanderCard:Create(host)
    local measurements = 0
    local function metrics(font)
        font.SetFont = function(self, _, size) self.metricSize = size end
        font.GetStringHeight = function(self)
            measurements = measurements + 1
            local size, width = self.metricSize or 13, self:GetWidth()
            local height = 0
            -- Conservative offline font mock. This tests production allocation,
            -- not native WoW glyph rasterization (a separate client gate).
            for line in (self:GetText() .. "\n"):gmatch("(.-)\n") do
                local pixels = 0
                for glyph in line:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                    pixels = pixels + size * (#glyph >= 3 and 1.0 or 0.64)
                end
                height = height + math.max(1, math.ceil(pixels / math.max(1, width * 0.9))) * size * 1.2
            end
            return height
        end
    end
    for _, font in ipairs({ card.title, card.context, card.timeLine, card.notice, card.feedbackValue }) do metrics(font) end
    for _, section in pairs(card.sections) do metrics(section.heading) metrics(section.value) end
    KWR.db.profile.hud.cardLayout = "COMPLETE"
    KWR.db.profile.hud.cardWide = false
    local state = KWR.Util:Copy(input)
    state.snapshot.capturedAt = GetTime()
    state.snapshot.executionCommand.generatedAt = GetTime()
    KWR.HUD:Update(state)
    assert(host.cardActive and card:IsShown() and not host.kill:IsShown(), "HUD did not select the complete production surface")
    local rows = {}
    local function boundsCheck()
        for key, box in pairs(card.bounds) do
            local section = card.sections[key]
            assert(section:GetHeight() + 0.01 >= box.headingHeight + box.valueHeight + 25 / card.testScale,
                "Measured text exceeds section height: " .. key)
            assert(box.x >= 0 and box.y >= 0 and box.x + box.width <= card.layoutWidth + 0.1,
                "Section crossed the card's horizontal bounds: " .. key)
            assert(box.y + box.height <= card.contentHeight, "Section fell below the card: " .. key)
            for otherKey, other in pairs(card.bounds) do
                if key ~= otherKey then
                    local overlapX = box.x < other.x + other.width - 0.1 and other.x < box.x + box.width - 0.1
                    local overlapY = box.y < other.y + other.height - 0.1 and other.y < box.y + box.height - 0.1
                    assert(not (overlapX and overlapY), "Overlapping sections: " .. key .. " / " .. otherKey)
                end
            end
        end
    end
    local stress = KWR.Util:Copy(state)
    stress.command.activePlay.movers, stress.command.activePlay.stayers = {}, {}
    stress.snapshot.roster, stress.assignments = {}, {}
    for index = 1, 10 do
        local name = index % 2 == 0 and ("\195\137l\195\169vation" .. index .. "-LongUnbrokenRealmName")
            or ("Commander" .. index .. "-AnotherLongUnbrokenRealm")
        stress.snapshot.roster[index] = { name = name, guid = "Member-" .. index }
        stress.assignments[index] = { name = name, guid = "Member-" .. index,
            role = index > 7 and "Defender" or "Reinforce", location = index > 7 and "Farm" or "Blacksmith" }
        local list = index > 7 and stress.command.activePlay.stayers or stress.command.activePlay.movers
        list[#list + 1] = name
    end
    stress.snapshot.executionCommand.localFight.controls = {}
    for index = 1, 4 do
        stress.snapshot.executionCommand.localFight.controls[index] = {
            actor = stress.snapshot.roster[index].name, actorGUID = stress.snapshot.roster[index].guid,
            target = "\230\149\181\227\129\174\229\155\158\229\190\169\229\189\185" .. index .. "-LongEnemyRealm", targetGUID = "Healer-" .. index,
            verb = "Subdue", location = "Blacksmith", timing = "On leader call", state = "ACTIVE", assigned = true }
    end
    for _, scenario in ipairs({ { name = "normal", state = state }, { name = "ten-player-four-control", state = stress } }) do
        card.view = KWR.CommandView:CommanderCard(scenario.state)
        for _, size in ipairs({ { 1920, 1080 }, { 2560, 1440 }, { 3840, 2160 } }) do
            for _, scale in ipairs({ 0.65, 0.8, 1.0 }) do
                card.testScale = scale
                local fit = KWR.CommanderCard:Layout(card, size[1] / scale, size[2] / scale, scale)
                assert(fit, scenario.name .. " did not fit " .. size[1] .. "x" .. size[2] .. " @ " .. scale
                    .. ": height=" .. card.contentHeight * scale)
                boundsCheck()
                local model = KWR.CommanderCard:Content(card.view)
                for _, duty in ipairs(card.view.duties) do
                    assert(model.duties:find(duty.actor.name, 1, true) and model.speech:find(duty.actor.name, 1, true),
                        "An issued actor disappeared from the primary card")
                end
                rows[#rows + 1] = { scenario = scenario.name, screenWidth = size[1], screenHeight = size[2],
                    scale = scale, mode = card.layoutMode, width = card.layoutWidth, height = card.contentHeight,
                    bounds = KWR.Util:Copy(card.bounds), labels = KWR.Util:Copy(KWR.CommandView.CardStrings),
                    feedback = card.feedbackValue:GetText(), feedbackY = card.feedbackY, buttonY = card.buttonY,
                    contextText = card.context:GetText(), clockText = card.timeLine:GetText(),
                    phase = card.view.phase, fit = fit }
            end
        end
    end
    -- A resolved command can get shorter after a target dies or a control row
    -- clears. Its card must retain the established live geometry rather than
    -- shrinking under the caller and then expanding on the next update.
    card.view = KWR.CommandView:CommanderCard(stress)
    assert(KWR.CommanderCard:Layout(card, 1920, 1080, 1), "Stress geometry did not fit the stable-card probe")
    local tallHeight = card.contentHeight
    card.view = KWR.CommandView:CommanderCard(state)
    assert(KWR.CommanderCard:Layout(card, 1920, 1080, 1), "Shortened call did not fit the stable-card probe")
    assert(card.contentHeight >= tallHeight,
        "Commander card shrank after a shorter live call instead of retaining stable geometry")
    local bodyHeight = card.sections.speech:GetHeight()
    card.sections.speech:SetHeight(1)
    assert(not pcall(boundsCheck), "Layout test failed to detect deliberate section truncation")
    card.sections.speech:SetHeight(bodyHeight)
    assert(not KWR.CommanderCard:Layout(card, 400, 300, 1), "Unsupported viewport silently passed geometry")
    card.view = KWR.CommandView:CommanderCard(state)
    card.focus = { matchId = "input-test", calloutId = "call-1", calloutRevision = 1 }
    card.fit = true
    local marks, mouseX = {}, 100
    _G.GetCursorPosition = function() return mouseX, 100 end
    KWR.AAR.MarkFollowthrough = function(_, focus, mark)
        marks[#marks + 1] = { focus = focus, state = mark }
        return true, "Accepted test mark"
    end
    for _, pair in ipairs({ { "LeftButton", "NOT_FOLLOWED" }, { "RightButton", "FOLLOWED" } }) do
        card:GetScript("OnMouseDown")(card, pair[1])
        card:GetScript("OnMouseUp")(card, pair[1])
        assert(marks[#marks].state == pair[2], "Background click mapping is reversed")
    end
    local before = #marks
    card:GetScript("OnMouseDown")(card, "LeftButton")
    card:GetScript("OnDragStart")(card)
    card:GetScript("OnMouseUp")(card, "LeftButton")
    assert(#marks == before, "Dragging generated feedback")
    card:GetScript("OnMouseDown")(card, "LeftButton")
    mouseX = 110
    card:GetScript("OnMouseUp")(card, "LeftButton")
    assert(#marks == before, "Pointer movement generated feedback")
    card:GetScript("OnMouseDown")(card, "LeftButton")
    card.copy:GetScript("OnMouseUp")(card.copy, "LeftButton")
    card:GetScript("OnMouseUp")(card, "LeftButton")
    assert(#marks == before, "A child control completed background feedback")
    card:GetScript("OnMouseDown")(card, "RightButton")
    card.view.callKey = card.view.callKey .. "changed"
    card:GetScript("OnMouseUp")(card, "RightButton")
    assert(#marks == before and card.message == "Call changed - mark again", "Revision race retargeted the click")
    card.notFollowed:GetScript("OnMouseDown")(card.notFollowed, "LeftButton")
    card.notFollowed:GetScript("OnMouseUp")(card.notFollowed, "LeftButton")
    assert(marks[#marks].state == "NOT_FOLLOWED", "Explicit mark control is inert")
    card.pending, card.focus, card.lastMarkedFocus, card.message = nil, nil, nil, nil
    KWR.AAR.MarkFollowthrough, _G.GetCursorPosition = saved.mark, saved.cursor
    KWR.db.profile.hud.cardLayout, KWR.db.profile.hud.cardWide = saved.layout, saved.wide
    KWR.HUD.lastState = saved.lastState
    KWR.CommanderCard:Hide(host)
    print("KWR_COMMANDER_CARD_LAYOUT_PASS cases=" .. #rows .. " measurements=" .. measurements .. " native=false")
    return rows
end
