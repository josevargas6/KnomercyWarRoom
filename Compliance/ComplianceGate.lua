local _, KWR = ...

local Gate = {}
KWR.ComplianceGate = Gate

local SAFE_FACT_SOURCES = {
    ui_widget = true,
    area_poi = true,
    vignette = true,
    scoreboard = true,
    target = true,
    focus = true,
    mouseover = true,
    nameplate = true,
    ally_target = true,
    fixture = true,
    internal = true,
}

local SOURCE_ALIASES = {
    Scoreboard = "scoreboard",
    Target = "target",
    Focus = "focus",
    Mouseover = "mouseover",
    Nameplate = "nameplate",
    ["Soft Target"] = "target",
    ["Arena Token"] = "nameplate",
    ["Objective Unit"] = "nameplate",
    ["Pet Target"] = "target",
    ["Target Target"] = "ally_target",
    ["Focus Target"] = "ally_target",
    ["Mouseover Target"] = "ally_target",
}

function Gate:Ruleset()
    return KWR.RulesetLoader and KWR.RulesetLoader:Get() or {}
end

function Gate:NormalizeSource(source)
    source = KWR.Util:Text(source, "internal", 32)
    return SOURCE_ALIASES[source] or source:lower()
end

function Gate:AllowFact(fact)
    fact = fact or {}
    local source = self:NormalizeSource(fact.source)
    fact.source = source
    if not SAFE_FACT_SOURCES[source] then
        return false, "unsupported fact source"
    end
    if fact.action == "AUTO_TARGET" or fact.action == "AUTO_CAST" then
        return false, "forbidden automated action"
    end
    return true, "allowed"
end

function Gate:Confidence(label, score)
    if label == "CONFIRMED" then return "CONFIRMED" end
    if label == "INFERRED" then return "INFERRED" end
    if (KWR.Util:Number(score, 0) or 0) >= 80 then return "CONFIRMED" end
    if (KWR.Util:Number(score, 0) or 0) >= 45 then return "INFERRED" end
    return "UNKNOWN"
end

KWR:RegisterModule("ComplianceGate", Gate)