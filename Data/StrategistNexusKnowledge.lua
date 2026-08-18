local _, KWR = ...

local StrategistNexusKnowledge = {}
KWR.StrategistNexusKnowledge = StrategistNexusKnowledge

local CONTRACT = {
    schemaVersion = 1,
    status = "PRODUCTION_ACTIVE",
    authority = "REVIEWED_KNOWLEDGE_WITH_BOUNDED_SIMULATION_COVERAGE_AND_GATED_LIVE_AAR",
    developerGate = "APPROVED_2026_08_16",
    patch = "12.1.0",
    activation = "IMMEDIATE_THEORY_FIRST",
    simulationAuthority = "THEORY_BRANCH_ACTIVATION_NON_EMPIRICAL",
    liveEvidenceRole = "REFINE_OR_DISPROVE_NOT_ACTIVATE",
    livePromotion = "PLAYER_REVIEW_REQUIRED",
    sources = {
        "ObjectiveRules",
        "Capabilities",
        "Compositions",
        "BattlePlans",
        "ScenarioCalibration",
        "ScenarioAdversarialCalibration",
        "ScenarioExpertCorpus",
        "DoctrineComparisons",
        "Counters",
        "StrategistNexusCorpus coverage index",
        "reviewed AAR Learning",
    },
}

function StrategistNexusKnowledge:Status()
    return CONTRACT.status
end

function StrategistNexusKnowledge:Patch()
    return CONTRACT.patch
end

function StrategistNexusKnowledge:Coverage(mapKey, phase)
    local expert = KWR.ScenarioExpertCorpus
        and KWR.ScenarioExpertCorpus:GetMapPhaseSummary(mapKey, phase) or nil
    local calibration = KWR.ScenarioCalibration
        and KWR.ScenarioCalibration:GetMapPhaseSummary(mapKey, phase) or nil
    local adversarial = KWR.ScenarioAdversarialCalibration
        and KWR.ScenarioAdversarialCalibration:GetMapPhaseSummary(mapKey, phase) or nil
    local comparisons = KWR.DoctrineComparisons
        and KWR.DoctrineComparisons:Count(mapKey) or 0
    local responses = KWR.DoctrineComparisons
        and KWR.DoctrineComparisons:CountResponses(mapKey) or 0
    return {
        available = expert ~= nil and calibration ~= nil and adversarial ~= nil,
        authority = CONTRACT.authority,
        status = CONTRACT.status,
        patch = CONTRACT.patch,
        expertReviewConfidence = expert and expert.reviewConfidence or "NONE",
        reviewedLabels = expert and expert.reviewedLabels or 0,
        reviewedCases = calibration and calibration.reviewedCases or 0,
        adversarialCases = adversarial and adversarial.adversarialCases or 0,
        doctrineComparisons = comparisons,
        doctrineResponses = responses,
    }
end

function StrategistNexusKnowledge:LiveEvidence()
    local aar = KWR.AAR and KWR.AAR.GetInsights and KWR.AAR:GetInsights() or {}
    local learning = KWR.Learning and KWR.Learning.Summary
        and KWR.Learning:Summary() or {}
    return {
        capturedMatches = aar.matches or 0,
        reviewedMatches = aar.reviewed or 0,
        reviewedLearningSamples = learning.samples or 0,
        learnedPlans = learning.plans or 0,
        patch = learning.patch or (KWR.PatchData and KWR.PatchData.activePatch),
        promotion = CONTRACT.livePromotion,
    }
end

function StrategistNexusKnowledge:Shared()
    return KWR.Util:Copy(CONTRACT)
end

KWR:RegisterModule("StrategistNexusKnowledge", StrategistNexusKnowledge)
