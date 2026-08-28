local _, KWR = ...

local KnowledgeManifest = {
    schema = 2,
    patch = "12.1.0",
    season = "Midnight Season 2",
    reviewedAt = "2026-08-27",
    sources = {
        "Blizzard in-game public APIs",
        "Battle.net Game Data/Profile reference",
        "Official World of Warcraft hotfix notes",
        "Official Midnight Season 2 schedule and PvP rewards",
        "Murlok RBG meta snapshot",
        "Field-tested addon architecture review",
        "KWR curated RBG doctrine",
    },
}
KWR.KnowledgeManifest = KnowledgeManifest

function KnowledgeManifest:Summary()
    return {
        capabilities = KWR.Capabilities:Count(),
        sources = KWR.SourceRegistry:Count(),
        archetypes = 7,
        plans = KWR.BattlePlans:Count(),
        scenarios = KWR.ScenarioLibrary:Count(),
        counters = KWR.Counters:Count(),
        metaSpecs = KWR.MetaSnapshot:Count(),
        capabilityRatings = 14,
        capabilityEffects = 42,
        counterSequences = KWR.Counters:Count() * 3,
        rbgProfiles = KWR.RBGMapProfiles and KWR.RBGMapProfiles:Count() or 0,
        scenarioCalibrations = KWR.ScenarioCalibration and KWR.ScenarioCalibration:Count() or 0,
        scenarioAdversarialCalibrations = KWR.ScenarioAdversarialCalibration
            and KWR.ScenarioAdversarialCalibration:Count() or 0,
        scenarioExpertReviews = KWR.ScenarioExpertCorpus
            and KWR.ScenarioExpertCorpus:Count() or 0,
        doctrineComparisons = KWR.DoctrineComparisons and KWR.DoctrineComparisons:Count() or 0,
        doctrineResponses = KWR.DoctrineComparisons and KWR.DoctrineComparisons:CountResponses() or 0,
        battlefieldAbilities = (function()
            local count = 0
            for _ in pairs(KWR.CombatSpells:AllAbilities()) do count = count + 1 end
            return count
        end)(),
        patch = self.patch,
        season = self.season,
        reviewedAt = self.reviewedAt,
    }
end

function KnowledgeManifest:Status(snapshot)
    snapshot = snapshot or {}
    local patch = KWR.PatchData:Get() or {}
    local metaAgeDays = KWR.Util:DaysSinceDate(KWR.MetaSnapshot.captured)
    local reviewedAgeDays = KWR.Util:DaysSinceDate(self.reviewedAt)
    local hotfixAgeDays = KWR.Util:DaysSinceDate(patch.officialHotfixReviewed)
    local friendly = KWR.Capabilities:Summarize(snapshot.roster or {})
    local enemy = KWR.Capabilities:Summarize(snapshot.enemies or {})
    local friendlyHistorical, enemyHistorical = 0, 0
    for _, player in ipairs(snapshot.roster or {}) do
        if player.specSource == "historical" then
            friendlyHistorical = friendlyHistorical + 1
        end
    end
    for _, player in ipairs(snapshot.enemies or {}) do
        if player.specSource == "historical" then
            enemyHistorical = enemyHistorical + 1
        end
    end
    local patchAligned = self.patch == KWR.PatchData.activePatch
        and patch.reviewed == true
    local metaAligned = patchAligned and self.patch == KWR.MetaSnapshot.patch
    local score = 0
    if patchAligned then score = score + 30 end
    if reviewedAgeDays ~= nil then
        score = score + (reviewedAgeDays <= 7 and 18
            or (reviewedAgeDays <= 14 and 10 or 0))
    else
        score = score + 8
    end
    if metaAgeDays ~= nil then
        score = score + (metaAgeDays <= 5 and 16
            or (metaAgeDays <= 10 and 8 or 0))
    else
        score = score + 6
    end
    score = score + math.floor((friendly.coverage or 0) * 16 + 0.5)
    score = score + math.floor((enemy.coverage or 0) * 20 + 0.5)
    score = score - (friendlyHistorical * 2) - (enemyHistorical * 3)
    if hotfixAgeDays and hotfixAgeDays > 14 then
        score = score - 8
    end
    score = KWR.Util:Clamp(score, 0, 100)
    local label = score >= 80 and "HIGH"
        or (score >= 55 and "MEDIUM" or (score >= 30 and "LOW" or "NONE"))
    local reasons = {}
    reasons[#reasons + 1] = patchAligned and "patch aligned" or "patch review mismatch"
    reasons[#reasons + 1] = metaAligned and "meta aligned" or "meta snapshot excluded"
    reasons[#reasons + 1] = string.format("spec certainty F:%d%% E:%d%%",
        math.floor((friendly.coverage or 0) * 100 + 0.5),
        math.floor((enemy.coverage or 0) * 100 + 0.5))
    if enemyHistorical > 0 then
        reasons[#reasons + 1] = tostring(enemyHistorical) .. " enemy specs historical"
    end
    if metaAgeDays then
        reasons[#reasons + 1] = "meta " .. tostring(metaAgeDays) .. "d"
    end
    if reviewedAgeDays then
        reasons[#reasons + 1] = "review " .. tostring(reviewedAgeDays) .. "d"
    end
    return {
        patchAligned = patchAligned,
        metaAligned = metaAligned,
        reviewed = patch.reviewed == true,
        reviewedAgeDays = reviewedAgeDays,
        metaAgeDays = metaAgeDays,
        hotfixAgeDays = hotfixAgeDays,
        friendlyCoverage = friendly.coverage or 0,
        enemyCoverage = enemy.coverage or 0,
        friendlyUnknown = friendly.unknownSpecs or 0,
        enemyUnknown = enemy.unknownSpecs or 0,
        friendlyHistorical = friendlyHistorical,
        enemyHistorical = enemyHistorical,
        score = score,
        label = label,
        reason = table.concat(reasons, ", "),
        compositionAuthorized = patchAligned
            and (enemy.coverage or 0) >= 0.7
            and enemyHistorical <= 3
            and label ~= "NONE",
        metaInfluenceAllowed = metaAligned
            and (metaAgeDays == nil or metaAgeDays <= 10),
    }
end

KWR:RegisterModule("KnowledgeManifest", KnowledgeManifest)
