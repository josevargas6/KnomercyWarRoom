local _, KWR = ...

local Learning = {}
KWR.Learning = Learning

local function bucketKey(mapKey, planID)
    return KWR.Util:Text(mapKey, "WORLD", 24) .. ":" .. KWR.Util:Text(planID, "NONE", 64)
end

function Learning:OnInitialize()
    KWR.db.learning = type(KWR.db.learning) == "table" and KWR.db.learning or {}
    KWR.db.learning.plans = type(KWR.db.learning.plans) == "table" and KWR.db.learning.plans or {}
end

function Learning:RecordReviewed(entry)
    if not entry or entry.learned or not entry.primaryPlanID then return false end
    if entry.truthQualified ~= true then return false end
    if entry.result ~= "VICTORY" and entry.result ~= "DEFEAT" then return false end
    if not entry.feedback or not next(entry.feedback) then return false end
    local key = bucketKey(entry.mapKey, entry.primaryPlanID)
    local bucket = KWR.db.learning.plans[key] or {
        mapKey = entry.mapKey,
        planID = entry.primaryPlanID,
        wins = 0,
        losses = 0,
        samples = 0,
        patch = KWR.PatchData.activePatch,
    }
    if bucket.patch ~= KWR.PatchData.activePatch then
        bucket.previousSamples = bucket.samples
        bucket.wins, bucket.losses, bucket.samples = 0, 0, 0
        bucket.patch = KWR.PatchData.activePatch
    end
    bucket.samples = bucket.samples + 1
    if entry.result == "VICTORY" then bucket.wins = bucket.wins + 1
    else bucket.losses = bucket.losses + 1 end
    bucket.updatedAt = entry.endedAt
    KWR.db.learning.plans[key] = bucket
    entry.learned = true
    return true
end

function Learning:Adjustment(mapKey, planID)
    local bucket = KWR.db and KWR.db.learning and KWR.db.learning.plans
        and KWR.db.learning.plans[bucketKey(mapKey, planID)]
    if not bucket or bucket.patch ~= KWR.PatchData.activePatch or (bucket.samples or 0) < 5 then return 0 end
    local estimate = ((bucket.wins or 0) + 2) / ((bucket.samples or 0) + 4)
    local limit = bucket.samples >= 20 and 8 or 3
    return KWR.Util:Clamp((estimate - 0.5) * 2 * limit, -limit, limit)
end

function Learning:Summary()
    local plans, samples = 0, 0
    for _, bucket in pairs(KWR.db.learning.plans or {}) do
        plans = plans + 1
        samples = samples + (bucket.samples or 0)
    end
    return { plans = plans, samples = samples, patch = KWR.PatchData.activePatch }
end

function Learning:Reset()
    KWR.db.learning.plans = {}
end

KWR:RegisterModule("Learning", Learning)
