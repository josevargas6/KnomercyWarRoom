local _, KWR = ...

local BuildInfo = {}
KWR.BuildInfo = BuildInfo

BuildInfo.channel = "production"
BuildInfo.productName = "KWR Commander"
BuildInfo.watermark = nil
-- External deployment receipts map this ID to exact ZIP/file hashes. Do not
-- embed an archive's own hash in its payload (that would be circular).
BuildInfo.candidateID = "alpha18-contained-setup-card-20260913-1"

function BuildInfo:HasBundledDeveloperTools()
    return self.channel ~= "production"
        and KWR.Preview and KWR.Verification and KWR.Verification.CurrentReport
        and KWR.Season2Readiness
end

function BuildInfo:IsDevelopmentMode()
    return self.channel == "development" or self.channel == "local"
        or (KWR.db and KWR.db.profile and KWR.db.profile.developmentMode == true
            and KWR.DevTools and KWR.DevTools.active == true
            and KWR.DevTools.version == KWR.version) or false
end

function BuildInfo:EnsureDeveloperTools()
    if InCombatLockdown and InCombatLockdown() then
        return false, "Enable Developer Tools outside combat."
    end
    if self:HasBundledDeveloperTools() then return true end
    if not (KWR.DevTools and KWR.DevTools.loaded) then
        local loader = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
        if type(loader) ~= "function" then
            return false, "Developer Tools could not load: addon loader unavailable."
        end
        local ok, loaded, reason = pcall(loader, "KWR_DevTools")
        if not ok or not (KWR.DevTools and KWR.DevTools.loaded) then
            return false, "Developer Tools could not load: "
                .. KWR.Util:Text(ok and reason or loaded, "install KWR_DevTools", 120)
        end
    end
    if KWR.DevTools.version ~= KWR.version then
        return false, "Developer Tools version does not match Commander. Install matching packages."
    end
    return true
end

function BuildInfo:SetDevelopmentMode(enabled)
    if not (KWR.db and KWR.db.profile) then
        return false, "Commander settings are not initialized."
    end
    if enabled then
        local loaded, message = self:EnsureDeveloperTools()
        if loaded and KWR.DevTools then
            loaded, message = KWR.DevTools:Activate()
        end
        if not loaded and KWR.DevTools and KWR.DevTools.Deactivate then
            KWR.DevTools:Deactivate()
        end
        KWR.db.profile.developmentMode = loaded == true
        return loaded, message
    end
    KWR.db.profile.developmentMode = false
    KWR.db.profile.preview = false
    if KWR.DevTools then KWR.DevTools:Deactivate() end
    if KWR.MatchRuntime and KWR.MatchRuntime.ClearDeveloperDiagnostics then
        KWR.MatchRuntime:ClearDeveloperDiagnostics()
    end
    if KWR.Verification and KWR.Verification.ledger then
        KWR.Verification.ledger = {}
        KWR.Verification.lastSignature = nil
    end
    return true
end

function BuildInfo:RestoreDeveloperTools()
    if KWR.db and KWR.db.profile and KWR.db.profile.developmentMode then
        return self:SetDevelopmentMode(true)
    end
    return true
end

function BuildInfo:HasPreview()
    return self:IsDevelopmentMode() and KWR.Preview
        and type(KWR.Preview.Build) == "function"
end

function BuildInfo:HasDiagnostics()
    return self:IsDevelopmentMode() and KWR.Diagnostics
        and type(KWR.Diagnostics.ShowReport) == "function"
end

function BuildInfo:IsDeveloperBuild()
    return self:IsDevelopmentMode()
end

function BuildInfo:IsReleaseBuild()
    return self.channel == "production" and not self:IsDeveloperBuild()
end

function BuildInfo:IsDevelopmentBuild()
    return self.channel == "development" or self.channel == "local"
end
