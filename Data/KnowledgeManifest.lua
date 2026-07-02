local _, KWR = ...

local KnowledgeManifest = {
    schema = 2,
    patch = "12.0.7",
    season = "Midnight Season 1",
    reviewedAt = "2026-06-30",
    sources = {
        "Blizzard in-game public APIs",
        "Battle.net Game Data/Profile reference",
        "Official World of Warcraft hotfix notes",
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

KWR:RegisterModule("KnowledgeManifest", KnowledgeManifest)
