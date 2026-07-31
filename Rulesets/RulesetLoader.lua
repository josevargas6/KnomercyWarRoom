local _, KWR = ...

local Loader = {
    activeMode = "Retail_Current",
}
KWR.RulesetLoader = Loader

local function copyRuleset(ruleset)
    return KWR.Util:Copy(ruleset or KWR.RetailCurrentRuleset or {})
end

function Loader:SetMode(mode)
    mode = KWR.Util:Text(mode, "Retail_Current", 32)
    if mode ~= "Retail_Current" and mode ~= "PTR_12_1" and mode ~= "Strict_Future" then
        mode = "Retail_Current"
    end
    self.activeMode = mode
end

function Loader:Get()
    if self.activeMode == "PTR_12_1" then
        return copyRuleset(KWR.PTR121Ruleset)
    elseif self.activeMode == "Strict_Future" then
        return copyRuleset(KWR.StrictFutureRuleset)
    end
    return copyRuleset(KWR.RetailCurrentRuleset)
end

KWR:RegisterModule("RulesetLoader", Loader)