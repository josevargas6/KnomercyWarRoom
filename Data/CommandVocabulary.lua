local _, KWR = ...

local Vocabulary = {}
KWR.CommandVocabulary = Vocabulary

local APPROVED = {
    Subdue = true,
    Disrupt = true,
    Deny = true,
    Peel = true,
    Pressure = true,
    Kill = true,
    Hold = true,
    Rotate = true,
    Escort = true,
    Spin = true,
    Collapse = true,
}

local FORBIDDEN_WORDS = {
    "Kidney", "Solar Beam", "Kick", "Blind", "Press", "Macro", "Cast",
    "Focus", "TargetUnit", "RunMacro",
}

function Vocabulary:IsApprovedVerb(verb)
    return APPROVED[KWR.Util:Text(verb, "", 24)] == true
end

function Vocabulary:NormalizeVerb(verb, fallback)
    verb = KWR.Util:Text(verb, fallback or "Pressure", 24)
    if self:IsApprovedVerb(verb) then return verb end
    return fallback or "Pressure"
end

function Vocabulary:ContainsForbiddenLanguage(text)
    text = KWR.Util:Text(text, "", 240)
    for _, word in ipairs(FORBIDDEN_WORDS) do
        if text:find(word, 1, true) then return true, word end
    end
    return false, nil
end

function Vocabulary:FormatAssignment(actor, verb, target)
    verb = self:NormalizeVerb(verb, "Pressure")
    return KWR.Util:Text(actor, "Team", 48) .. " -> " .. verb .. " "
        .. KWR.Util:Text(target, "target", 64)
end

KWR:RegisterModule("CommandVocabulary", Vocabulary)