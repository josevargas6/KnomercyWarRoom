local _, KWR = ...

local Learning = { maxBuckets = 120, maxProcessedEpisodes = 120 }
KWR.Learning = Learning
local SCHEMA_VERSION = 2

local function textID(value, limit)
    if KWR.Util:IsSecret(value) or type(value) ~= "string"
        or #value == 0 or #value > limit then return nil end
    return value
end

local function count(value)
    if KWR.Util:IsSecret(value) or type(value) ~= "number" then return nil end
    local number = KWR.Util:Number(value, nil)
    if not number or number < 0 or number ~= math.floor(number)
        or number > 9007199254740991 then return nil end
    return number
end

local function packed(values)
    local parts = {}
    for _, value in ipairs(values) do
        parts[#parts + 1] = tostring(#value) .. ":" .. value
    end
    return table.concat(parts, "|")
end

-- Schema-1 aggregates cannot prove issued-call delivery or observed execution,
-- so they must never become live doctrine. Keep a small migration receipt
-- instead of a verbatim archive: SavedVariables otherwise preserve an
-- unbounded, private legacy branch forever even though no consumer may read it.
local function legacyReceipt(value, sourceSchemaVersion)
    local entries = 0
    if type(value) == "table" then
        for _ in pairs(value) do
            entries = entries + 1
            if entries >= 10000 then break end
        end
    end
    return {
        schemaVersion = 1,
        reason = "UNVERIFIED_DELIVERY_AND_EXECUTION",
        sourceSchemaVersion = sourceSchemaVersion or 0,
        valueType = type(value),
        topLevelEntries = entries,
        retainedRawPayload = false,
    }
end

local function database()
    local db = KWR.db and KWR.db.learning
    if type(db) ~= "table" or db.schemaVersion ~= SCHEMA_VERSION
        or type(db.plans) ~= "table" or type(db.processedEpisodes) ~= "table"
        or count(db.retiredThrough) == nil then return nil end
    return db
end

local function validBucket(bucket)
    return type(bucket) == "table" and bucket.schemaVersion == SCHEMA_VERSION
        and count(bucket.successes) ~= nil and count(bucket.failures) ~= nil
        and count(bucket.samples) ~= nil
        and bucket.samples == bucket.successes + bucket.failures
        and count(bucket.updatedAt) ~= nil
end

local function retract(db, contribution)
    if not contribution or contribution.active ~= true then return false end
    local bucket = db.plans[contribution.key]
    if bucket then
        local field = contribution.outcome == "SUCCESS" and "successes" or "failures"
        if not validBucket(bucket) or bucket[field] < 1 or bucket.samples < 1 then
            db.integrityFailure = "INVALID_FEEDBACK_CONTRIBUTION"
            return false
        end
        bucket.samples = bucket.samples - 1
        bucket[field] = bucket[field] - 1
    end
    contribution.active = false
    return true
end

function Learning:CanCorrectFollowthrough(entry, command)
    if self.disabled then return false end
    local db = database()
    if not db or db.integrityFailure then return false end
    local episode = packed({ entry.id, command.commandId, tostring(command.commandRevision) })
    return not db.processedEpisodes[episode]
        or (type(db.episodeContributions) == "table" and db.episodeContributions[episode] ~= nil)
end

function Learning:Context(snapshot)
    if self.disabled then return nil end
    local context = snapshot and snapshot.context or {}
    if context.inPvP ~= true or context.isRated ~= true or context.preview == true then return nil end
    local expected = context.isBlitz == true and 8 or 10
    local roster = snapshot and snapshot.roster
    if type(roster) ~= "table" or #roster ~= expected then return nil end
    local members, seen = {}, {}
    for _, player in ipairs(roster) do
        local guid = type(player) == "table" and textID(player.guid, 96)
        if not guid or seen[guid] then return nil end
        seen[guid] = true
        members[#members + 1] = guid
    end
    table.sort(members)
    return {
        schemaVersion = 1, teamKey = packed(members),
        bracket = expected == 8 and "RBG_8" or "RBG_10",
        mapKey = context.mapKey, patch = KWR.PatchData.activePatch,
        -- Product version changes invalidate prior doctrine adjustments.
        planRevision = KWR.version,
    }
end

function Learning:ContextKey(context, planID)
    if type(context) ~= "table" or context.schemaVersion ~= 1 then return nil end
    local team = textID(context.teamKey, 1200)
    local map = textID(context.mapKey, 32)
    local patch = textID(context.patch, 48)
    local revision = textID(context.planRevision, 48)
    local plan = textID(planID, 96)
    if not team or not map or not patch or not revision or not plan
        or (context.bracket ~= "RBG_8" and context.bracket ~= "RBG_10") then return nil end
    return packed({ team, context.bracket, map, patch, revision, plan })
end

function Learning:OnInitialize()
    if KWR.db.profile.persistentLearning ~= true then
        KWR.db.learning = nil
        self.disabled = true
        return
    end
    self.disabled = false
    if KWR.MemoryBudget then KWR.MemoryBudget:Bind(self, "Learning") end
    local existing = KWR.db.learning
    local version = type(existing) == "table" and KWR.Util:Number(existing.schemaVersion, 0) or 0
    if version > SCHEMA_VERSION then return end
    if version ~= SCHEMA_VERSION then
        -- Transfer ownership once; never relabel historical aggregates as proof.
        KWR.db.learning = {
            schemaVersion = SCHEMA_VERSION,
            plans = {}, processedEpisodes = {}, retiredThrough = 0,
            legacy = legacyReceipt(existing, version),
        }
    end
    self:Prune()
end

function Learning:RecordReviewed(entry)
    if self.disabled then return false end
    local db = database()
    if not db or db.integrityFailure or type(entry) ~= "table" or entry.partial == true
        or entry.truthQualified ~= true or entry.reviewContext ~= "Commander"
        or (entry.result ~= "VICTORY" and entry.result ~= "DEFEAT")
        or type(entry.feedback) ~= "table" or entry.feedback.sessionType ~= "Commander"
        or type(entry.commands) ~= "table"
        or #entry.commands > (KWR.AAR and KWR.AAR.maxCommands or 18) then return false end
    local matchID = textID(entry.id, 256)
    local endedAt = count(entry.endedAt)
    local now = count(KWR.Util:Call(time))
    if not matchID or not endedAt or not now or endedAt > now
        or endedAt <= db.retiredThrough then return false end
    if db.episodeContributions ~= nil and type(db.episodeContributions) ~= "table" then return false end
    db.episodeContributions = db.episodeContributions or {}
    local recorded = false
    for _, command in ipairs(entry.commands) do
        local episode = command.commandId and command.commandRevision
            and packed({ matchID, command.commandId, tostring(command.commandRevision) })
        local contribution = episode and db.episodeContributions[episode]
        local excluded = KWR.CommandReview:HasNotFollowed(command)
        if excluded and contribution then
            recorded = retract(db, contribution) or recorded
        end
        if not excluded and KWR.CommandReview:ExecutionEligible(command) then
            local scope = command.learningContext
            local key = self:ContextKey(scope, command.planID)
            local observed = command.executionObservation
            local outcome = observed.outcome
            if key and scope.patch == KWR.PatchData.activePatch
                and scope.planRevision == KWR.version and scope.mapKey == entry.mapKey
                and observed.observedAt <= endedAt
                and (outcome == "SUCCESS" or outcome == "FAILURE")
                and (not db.processedEpisodes[episode] or (contribution and contribution.active == false
                    and contribution.key == key and contribution.outcome == outcome)) then
                local bucket = db.plans[key]
                if bucket == nil or (validBucket(bucket)
                    and self:ContextKey(bucket.context, bucket.planID) == key) then
                    bucket = bucket or {
                        schemaVersion = SCHEMA_VERSION,
                        context = KWR.Util:Copy(scope), planID = command.planID,
                        successes = 0, failures = 0, samples = 0, updatedAt = endedAt,
                    }
                    bucket.samples = bucket.samples + 1
                    if outcome == "SUCCESS" then bucket.successes = bucket.successes + 1
                    else bucket.failures = bucket.failures + 1 end
                    bucket.updatedAt = math.max(bucket.updatedAt, endedAt)
                    db.plans[key] = bucket
                    db.processedEpisodes[episode] = endedAt
                    db.episodeContributions[episode] = { schemaVersion = 1, key = key,
                        outcome = outcome, active = true, at = endedAt }
                    recorded = true
                end
            end
        end
    end
    self:Prune()
    if recorded then entry.learned = true end
    return recorded
end

function Learning:Prune()
    local db = database()
    if not db then return end
    local rows, invalid = {}, {}
    for key, bucket in pairs(db.plans) do
        if type(key) == "string" and validBucket(bucket)
            and self:ContextKey(bucket.context, bucket.planID) == key then
            rows[#rows + 1] = { key = key, at = bucket.updatedAt, samples = bucket.samples }
        else
            invalid[#invalid + 1] = { key = key, value = bucket }
        end
    end
    if #invalid > 0 then
        if db.quarantinedPlans ~= nil and type(db.quarantinedPlans) ~= "table" then
            db.integrityFailure = "INVALID_QUARANTINE"
            return
        end
        db.quarantinedPlans = db.quarantinedPlans or {}
        for _, row in ipairs(invalid) do
            db.quarantinedPlans[#db.quarantinedPlans + 1] = row
            db.plans[row.key] = nil
        end
    end
    table.sort(rows, function(a, b)
        if a.samples ~= b.samples then return a.samples > b.samples end
        if a.at ~= b.at then return a.at > b.at end
        return a.key < b.key
    end)
    for index = self.maxBuckets + 1, #rows do db.plans[rows[index].key] = nil end
    local episodes = {}
    for key, at in pairs(db.processedEpisodes) do
        if type(key) ~= "string" or count(at) == nil then
            -- Ignoring a corrupt ledger could double-count an old episode.
            db.integrityFailure = "INVALID_EPISODE_LEDGER"
            return
        end
        episodes[#episodes + 1] = { key = key, at = at }
    end
    table.sort(episodes, function(a, b)
        if a.at ~= b.at then return a.at > b.at end
        return a.key < b.key
    end)
    for index = self.maxProcessedEpisodes + 1, #episodes do
        local row = episodes[index]
        -- New reversible contributions form a bounded evidence window. Forget
        -- their aggregate credit when forgetting the retraction identity.
        if type(db.episodeContributions) == "table" then
            retract(db, db.episodeContributions[row.key])
            db.episodeContributions[row.key] = nil
        end
        db.retiredThrough = math.max(db.retiredThrough, row.at)
        db.processedEpisodes[row.key] = nil
    end
end

function Learning:Adjustment(mapKey, planID, context)
    if self.disabled then return 0 end
    if KWR.AAR and KWR.AAR.followthroughReviewQueued then return 0 end
    local db = database()
    local key = self:ContextKey(context, planID)
    if not db or db.integrityFailure or not key or context.mapKey ~= mapKey
        or context.patch ~= KWR.PatchData.activePatch or context.planRevision ~= KWR.version then return 0 end
    local bucket = db.plans[key]
    if not validBucket(bucket) or self:ContextKey(bucket.context, bucket.planID) ~= key
        or bucket.samples < 5 then return 0 end
    local estimate = (bucket.successes + 2) / (bucket.samples + 4)
    local limit = bucket.samples >= 20 and 8 or 3
    return KWR.Util:Clamp((estimate - 0.5) * 2 * limit, -limit, limit)
end

function Learning:Summary()
    if self.disabled then
        return { plans = 0, samples = 0, patch = KWR.PatchData.activePatch,
            scope = "DISABLED", quarantined = false, unavailable = true }
    end
    local db = database()
    local plans, samples = 0, 0
    for _, bucket in pairs(db and db.plans or {}) do
        if validBucket(bucket) then
            plans = plans + 1
            samples = samples + bucket.samples
        end
    end
    return { plans = plans, samples = samples, patch = KWR.PatchData.activePatch,
        scope = "LOCAL_TEAM_EPISODES", quarantined = db and db.legacy ~= nil or false,
        unavailable = not db or db.integrityFailure ~= nil }
end

function Learning:Reset()
    if self.disabled then return end
    local db = database()
    if db then db.plans = {} end
    -- Keep deduplication so old exports cannot retrain after reset.
end

KWR:RegisterModule("Learning", Learning)
