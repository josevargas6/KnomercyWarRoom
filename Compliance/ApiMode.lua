local _, KWR = ...

local ApiMode = {
    mode = "Retail_Current",
}
KWR.ApiMode = ApiMode

function ApiMode:Set(mode)
    mode = KWR.Util:Text(mode, "Retail_Current", 32)
    if mode ~= "Retail_Current" and mode ~= "PTR_12_1" and mode ~= "Strict_Future" then
        mode = "Retail_Current"
    end
    self.mode = mode
    if KWR.RulesetLoader then KWR.RulesetLoader:SetMode(mode) end
end

function ApiMode:Get()
    return self.mode
end

KWR:RegisterModule("ApiMode", ApiMode)