local _, KWR = ...

local BuildInfo = {}
KWR.BuildInfo = BuildInfo

BuildInfo.channel = "production"
BuildInfo.productName = "KWR Commander"
BuildInfo.watermark = nil

function BuildInfo:HasPreview()
    return KWR.Preview and type(KWR.Preview.Build) == "function"
end

function BuildInfo:HasDiagnostics()
    return KWR.Diagnostics and type(KWR.Diagnostics.ShowReport) == "function"
end

function BuildInfo:IsDeveloperBuild()
    return self:HasPreview() or self:HasDiagnostics()
end

function BuildInfo:IsReleaseBuild()
    return self.channel == "production" and not self:IsDeveloperBuild()
end

function BuildInfo:IsDevelopmentBuild()
    return self.channel == "development" or self.channel == "local"
end