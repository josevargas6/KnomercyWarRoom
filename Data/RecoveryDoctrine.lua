local _, KWR = ...

local RecoveryDoctrine = {}
KWR.RecoveryDoctrine = RecoveryDoctrine

local function reviewed(entry)
    entry.reviewStatus = "THEORY_REVIEWED"
    entry.evidenceGrade = "C"
    entry.requiresMatchValidation = true
    return entry
end

local function targetTerms(mapKey)
    local terms = {
        ARATHI = { target = "center", trade = "outer node", shell = "two-base shell" },
        GILNEAS = { target = "Waterworks", trade = "outer node", shell = "two-base clock" },
        DEEPWIND = { target = "central node", trade = "outer flank", shell = "three-node triangle" },
        EOTS = { target = "mid flag", trade = "enemy tower", shell = "tower-count projection" },
        WSG = { target = "enemy carrier route", trade = "midfield", shell = "carrier state" },
        TWINPEAKS = { target = "enemy carrier route", trade = "intercept route", shell = "carrier state" },
        TEMPLE = { target = "current orb lane", trade = "next pickup", shell = "scoring carrier shell" },
        SILVERSHARD = { target = "recoverable cart", trade = "alternate cart", shell = "cart race" },
        DEEPHAUL = { target = "enemy cart lane", trade = "crystal lane", shell = "cart race" },
        SEETHING = { target = "active extractor", trade = "next public spawn", shell = "resource race" },
    }
    return terms[mapKey] or { target = "contested objective", trade = "trade lane", shell = "score shell" }
end

local function entries(mapKey)
    local terms = targetTerms(mapKey)
    return {
        reviewed({
            id = mapKey .. "_REC_ABANDON",
            branch = "ABANDON",
            action = "Abandon " .. terms.target .. " early when it will resolve before a complete wave can arrive.",
            when = "Arrival occurs after resolution or the fight is fully stabilized by the enemy.",
            assignmentContinuity = "Regroup survivors and preload the next meaningful lane.",
            abortOrSwitch = "Re-enter only if the objective becomes contestable again.",
        }),
        reviewed({
            id = mapKey .. "_REC_REINFORCE",
            branch = "REINFORCE",
            action = "Reinforce " .. terms.target .. " with one complete wave while the interaction remains live.",
            when = "The objective is still contestable, anchors are stable, and arrivals beat resolution.",
            assignmentContinuity = "Send one healer-led wave and preserve the anchor/reserve chain.",
            abortOrSwitch = "Abort if coverage breaks or the event resolves before arrival.",
        }),
        reviewed({
            id = mapKey .. "_REC_TRADE",
            branch = "TRADE",
            action = "Trade into " .. terms.trade .. " while the enemy overcommits to " .. terms.target .. ".",
            when = "The trade improves the score shell and friendly anchors can survive.",
            assignmentContinuity = "Compact strike group attacks while reserve protects " .. terms.shell .. ".",
            abortOrSwitch = "Reset if enemy reserve remains uncommitted.",
        }),
        reviewed({
            id = mapKey .. "_REC_RESET",
            branch = "RESET",
            action = "Stop staggered entries, restore assignments, and rebuild one complete action around " .. terms.shell .. ".",
            when = "Neither reinforce nor trade has positive expected value.",
            assignmentContinuity = "Regroup the resurrection wave, restore vacancies, then select a fresh branch.",
            abortOrSwitch = "Do not restart until a complete wave and legal objective exist.",
        }),
    }
end

function RecoveryDoctrine:Get(mapKey)
    return entries(mapKey)
end

function RecoveryDoctrine:Count(mapKey)
    if mapKey then return #entries(mapKey) end
    local total = 0
    for key in pairs(KWR.Maps:All()) do total = total + #entries(key) end
    return total
end

function RecoveryDoctrine:Select(mapKey, flags)
    local use = self:Get(mapKey)
    if flags and flags.arrivalAfterResolution then
        return KWR.Util:Copy(use[1])
    end
    if flags and flags.objectiveContestable and flags.waveAdvantage and flags.anchorsStable then
        return KWR.Util:Copy(use[2])
    end
    if flags and flags.enemyOvercommit and flags.anchorsStable then
        return KWR.Util:Copy(use[3])
    end
    return KWR.Util:Copy(use[4])
end

KWR:RegisterModule("RecoveryDoctrine", RecoveryDoctrine)