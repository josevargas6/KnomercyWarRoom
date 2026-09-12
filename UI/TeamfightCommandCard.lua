local _, KWR = ...

local Card = {}
KWR.TeamfightCommandCard = Card

local function commanderSummary(state)
    if not state or not KWR.CommandView or type(KWR.CommandView.CommanderCard) ~= "function" then
        return nil
    end
    local call = KWR.CommandView:CommanderCard(state)
    if not call or call.phase ~= "LIVE" then return nil end
    local lines = {
        "CURRENT ORDER: " .. call.now.action .. " @ " .. call.now.location,
        "POSITION: " .. call.position.text,
        "NEXT / NOT ISSUED: " .. call.next.action .. " @ " .. call.next.location,
    }
    if call.localFight and call.localFight.target then
        lines[#lines + 1] = "LOCAL " .. call.localFight.intent .. ": "
            .. call.localFight.target.name .. " @ " .. call.localFight.location
    end
    return {
        lines = lines,
        confidence = "STRUCTURED",
        countdown = call.countdown,
        unknownSafe = true,
        scope = "COMMANDER_CARD_SUMMARY",
        activeCallAuthority = false,
        callKey = call.callKey,
        speech = call.speech,
        fullCardAvailable = true,
    }
end

function Card:Build(plan, state)
    -- This small legacy surface must never formulate a competing call.  When
    -- the commander projection is available it shows a compact, labeled view
    -- of that exact projection; the complete HUD card retains every duty/CC.
    local summary = commanderSummary(state)
    if summary then return summary end
    local lines = { KWR.Util:Text(plan and plan.title, "LOCAL TEAMFIGHT CALL", 48) }
    for _, assignment in ipairs(plan and plan.assignments or {}) do
        lines[#lines + 1] = KWR.CommandVocabulary:FormatAssignment(
            assignment.actor, assignment.verb, assignment.target)
    end
    if plan and plan.killTarget then
        lines[#lines + 1] = KWR.CommandVocabulary:FormatAssignment(
            "Team", "Kill", plan.killTarget.target) .. " - " .. KWR.CountdownState:Text(plan.countdown)
    end
    return {
        lines = lines,
        confidence = plan and plan.confidence or "UNKNOWN",
        countdown = plan and plan.countdown,
        unknownSafe = true,
        scope = "LOCAL_TEAMFIGHT",
        activeCallAuthority = false,
    }
end

KWR:RegisterModule("TeamfightCommandCard", Card)
