local _, KWR = ...

local OpponentModels = {
    sessionKey = nil,
    sessionSeen = {},
    sampleTokens = {},
    deathState = {},
    maxProfiles = 240,
    maxProcessedMatches = 120,
}
KWR.OpponentModels = OpponentModels

local function stamp()
    if type(time) == "function" then
        return KWR.Util:Number(KWR.Util:Call(time), 0) or 0
    end
    return math.floor(KWR.Util:Now())
end

local function currentSeason()
    if C_PvP and type(C_PvP.GetActiveSeason) == "function" then
        return KWR.Util:Number(KWR.Util:Call(C_PvP.GetActiveSeason), nil)
    end
end

local function profileKey(entity)
    local guid = KWR.Util:Text(entity and entity.guid, "", 96)
    if guid ~= "" then return guid end
    local name = KWR.Util:Text(entity and entity.name, "", 64):lower()
    return name ~= "" and ("name:" .. name) or nil
end

local function cleanLocation(location)
    location = KWR.Util:Text(location, "", 48)
    if location == "" or location == "Unknown" or location == "Position restricted"
        or location == "Formation" or location == "Unassigned" then
        return nil
    end
    return location
end

local function bump(bucket, key, amount)
    if type(bucket) ~= "table" or not key or key == "" then return end
    bucket[key] = (bucket[key] or 0) + (amount or 1)
end

local function totalCounts(bucket)
    local total = 0
    for _, count in pairs(bucket or {}) do
        total = total + (KWR.Util:Number(count, 0) or 0)
    end
    return total
end

local function topCounts(bucket, maximum)
    local rows = {}
    for key, count in pairs(bucket or {}) do
        rows[#rows + 1] = { key = key, count = KWR.Util:Number(count, 0) or 0 }
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.key < b.key
    end)
    local result = {}
    for index = 1, math.min(maximum or 2, #rows) do
        result[#result + 1] = rows[index]
    end
    return result
end

local function daysSince(thenAt, nowAt)
    thenAt = KWR.Util:Number(thenAt, nil)
    nowAt = KWR.Util:Number(nowAt, stamp()) or stamp()
    if not thenAt or thenAt <= 0 then return nil end
    return math.max(0, math.floor((nowAt - thenAt) / 86400))
end

local function traitConfidence(count)
    count = KWR.Util:Number(count, 0) or 0
    if count >= 6 then return "HIGH" end
    if count >= 3 then return "MEDIUM" end
    return "LOW"
end

local function addTrait(traits, id, label, kind, count, action, scoreHint)
    traits[#traits + 1] = {
        id = id,
        label = label,
        kind = kind,
        count = KWR.Util:Number(count, 0) or 0,
        confidence = traitConfidence(count),
        action = action,
        scoreHint = scoreHint or 0,
    }
end

local function traitLabels(traits, maximum)
    local labels = {}
    for index, trait in ipairs(traits or {}) do
        if index > (maximum or 4) then break end
        labels[#labels + 1] = trait.label
    end
    return labels
end

local function buildTraits(profile, strongestLocation, strongestShare)
    local traits = {}
    if (profile.carrierObserved or 0) >= 3 then
        addTrait(traits, "CARRIER_THREAT", "Carrier threat", "strength",
            profile.carrierObserved, "Assign escort/return pressure when this player carries.", 4)
    end
    if (profile.stealthPressureObserved or 0) >= 3 then
        addTrait(traits, "STEALTH_FLANK", "Stealth flank", "strength",
            profile.stealthPressureObserved, "Keep eyes on weak bases and call spin early.", 3)
    end
    if (profile.healerSupportedEngagements or 0) >= 4
        and (profile.healerSupportedEngagements or 0)
            >= ((profile.isolatedEngagements or 0) + 2) then
        addTrait(traits, "HEALER_BACKED_PUSH", "Healer-backed push", "strength",
            profile.healerSupportedEngagements, "Do not feed solo pressure into this push.", 3)
    end
    if (profile.hotspotPresence or 0) >= 4 then
        addTrait(traits, "PRESSURE_LANE", "Pressure lane regular", "strength",
            profile.hotspotPresence, "Expect this player near the main fight.", 2)
    end
    if strongestLocation and strongestShare >= 0.45 and strongestLocation.count >= 3 then
        addTrait(traits, "FAVORS_LOCATION",
            "Favors " .. KWR.Util:Text(strongestLocation.key, "one lane", 32),
            "pattern", strongestLocation.count, "Pre-position eyes before the route repeats.", 2)
    end
    if (profile.isolatedEngagements or 0) >= 3
        and (profile.isolatedEngagements or 0)
            >= ((profile.groupedEngagements or 0) + 1) then
        addTrait(traits, "OVEREXTENDS", "Overextends", "weakness",
            profile.isolatedEngagements, "Punish when separated from support.", 7)
    end
    if (profile.deathsObserved or 0) >= 3
        and (profile.localEngagements or 0) > 0
        and ((profile.deathsObserved or 0) / math.max(profile.localEngagements, 1)) >= 0.35 then
        addTrait(traits, "DIES_IN_COMMIT", "Dies in commit", "weakness",
            profile.deathsObserved, "Collapse during coordinated kill windows.", 6)
    end
    if strongestLocation and strongestShare >= 0.60 and strongestLocation.count >= 4 then
        addTrait(traits, "PREDICTABLE_ROUTE",
            "Predictable " .. KWR.Util:Text(strongestLocation.key, "route", 32),
            "weakness", strongestLocation.count, "Intercept the repeated route.", 4)
    end
    if (profile.priorityCastObserved or 0) >= 3
        and (profile.deathsObserved or 0) >= 2 then
        addTrait(traits, "PUNISHABLE_CASTS", "Punishable casts", "weakness",
            profile.priorityCastObserved, "Assign subdue/disrupt when they freecast.", 5)
    elseif (profile.priorityCastObserved or 0) >= 3 then
        addTrait(traits, "FREECASTS", "Freecasts under pressure", "pattern",
            profile.priorityCastObserved, "Assign disruption before the kill window.", 3)
    end
    table.sort(traits, function(a, b)
        if (a.scoreHint or 0) ~= (b.scoreHint or 0) then
            return (a.scoreHint or 0) > (b.scoreHint or 0)
        end
        if (a.count or 0) ~= (b.count or 0) then return (a.count or 0) > (b.count or 0) end
        return tostring(a.id) < tostring(b.id)
    end)
    return traits
end

local function commanderTakeaway(traits, label)
    for _, trait in ipairs(traits or {}) do
        if trait.kind == "weakness" then
            return "Takeaway: " .. KWR.Util:Text(trait.action, "Punish repeat weakness.", 90)
        end
    end
    for _, trait in ipairs(traits or {}) do
        if trait.kind == "strength" then
            return "Takeaway: " .. KWR.Util:Text(trait.action, "Respect repeat strength.", 90)
        end
    end
    if label == "LOW" or label == "NONE" then
        return "Takeaway: profile is thin; use as advisory only."
    end
    return "Takeaway: no dominant repeat trait yet."
end

local function distance(x1, y1, x2, y2)
    x1, y1 = KWR.Util:Number(x1, nil), KWR.Util:Number(y1, nil)
    x2, y2 = KWR.Util:Number(x2, nil), KWR.Util:Number(y2, nil)
    if not x1 or not y1 or not x2 or not y2 then return nil end
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt((dx * dx) + (dy * dy))
end

local function localSupport(snapshot, enemy)
    local support = { allies = 0, healerSupport = 0 }
    local x, y = KWR.Util:Number(enemy and enemy.x, nil), KWR.Util:Number(enemy and enemy.y, nil)
    if not x or not y then return support end
    for _, other in ipairs(snapshot and snapshot.enemies or {}) do
        if other ~= enemy and other.dead ~= true
            and (other.visible == true or (other.lastSeenAge or 999) <= 6) then
            local range = distance(x, y, other.x, other.y)
            if range and range <= 0.09 then
                support.allies = support.allies + 1
                if KWR.CombatSpells:Role(other.spec, other.role) == "HEALER" then
                    support.healerSupport = support.healerSupport + 1
                end
            end
        end
    end
    return support
end

function OpponentModels:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "OpponentModels")
    end
    KWR.db.opponentModels = type(KWR.db.opponentModels) == "table"
        and KWR.db.opponentModels or {}
    KWR.db.opponentModels.players = type(KWR.db.opponentModels.players) == "table"
        and KWR.db.opponentModels.players or {}
    KWR.db.opponentModels.processedMatches =
        type(KWR.db.opponentModels.processedMatches) == "table"
        and KWR.db.opponentModels.processedMatches or {}
end

function OpponentModels:ResetSession(sessionKey)
    self.sessionKey = sessionKey
    self.sessionSeen = {}
    self.sampleTokens = {}
    self.deathState = {}
end

function OpponentModels:Prune()
    local players = KWR.db.opponentModels.players or {}
    local count = 0
    for _ in pairs(players) do count = count + 1 end
    while count > self.maxProfiles do
        local oldestKey, oldestAt
        for key, profile in pairs(players) do
            local updatedAt = KWR.Util:Number(profile.updatedAt, 0) or 0
            if oldestAt == nil or updatedAt < oldestAt then
                oldestKey, oldestAt = key, updatedAt
            end
        end
        if not oldestKey then break end
        players[oldestKey] = nil
        count = count - 1
    end
end

function OpponentModels:PruneProcessedMatches()
    local processed = KWR.db.opponentModels.processedMatches or {}
    local rows = {}
    for id, at in pairs(processed) do
        rows[#rows + 1] = {
            id = id,
            at = KWR.Util:Number(at, 0) or 0,
        }
    end
    table.sort(rows, function(a, b)
        if a.at ~= b.at then return a.at > b.at end
        return a.id < b.id
    end)
    for index = self.maxProcessedMatches + 1, #rows do
        processed[rows[index].id] = nil
    end
end

function OpponentModels:Ensure(entity)
    local key = profileKey(entity)
    if not key then return nil end
    local players = KWR.db.opponentModels.players
    local profile = players[key] or {
        key = key,
        createdAt = stamp(),
        sessions = 0,
        matches = 0,
        sightings = 0,
        localEngagements = 0,
        isolatedEngagements = 0,
        groupedEngagements = 0,
        healerSupportedEngagements = 0,
        carrierObserved = 0,
        stealthPressureObserved = 0,
        hotspotPresence = 0,
        healerPressureObserved = 0,
        priorityCastObserved = 0,
        deathsObserved = 0,
        locations = {},
        hotspotLocations = {},
        maps = {},
    }
    local season = currentSeason()
    if season and profile.season and profile.season ~= season then
        local createdAt = profile.createdAt
        profile = {
            key = key,
            createdAt = createdAt,
            sessions = 0,
            matches = 0,
            sightings = 0,
            localEngagements = 0,
            isolatedEngagements = 0,
            groupedEngagements = 0,
            healerSupportedEngagements = 0,
            carrierObserved = 0,
            stealthPressureObserved = 0,
            hotspotPresence = 0,
            healerPressureObserved = 0,
            priorityCastObserved = 0,
            deathsObserved = 0,
            locations = {},
            hotspotLocations = {},
            maps = {},
        }
    end
    profile.name = KWR.Util:Text(entity.name, profile.name or "Unknown", 64)
    profile.shortName = KWR.Util:Text(entity.shortName, profile.shortName
        or KWR.Util:ShortName(profile.name), 32)
    profile.guid = KWR.Util:Text(entity.guid, profile.guid or "", 96)
    profile.classFile = KWR.Util:Upper(entity.classFile, profile.classFile or "UNKNOWN", 24)
    profile.class = KWR.Util:Text(entity.class, profile.class or profile.classFile, 32)
    profile.spec = KWR.Util:Text(entity.spec, profile.spec or "Unknown", 32)
    profile.role = KWR.CombatSpells:Role(entity.spec, entity.role or profile.role)
    profile.season = season or profile.season
    profile.updatedAt = stamp()
    players[key] = profile
    return profile
end

function OpponentModels:Throttle(profile, token, interval)
    if not profile or token == "" then return false end
    local at = KWR.Util:Number(KWR.Util:Now(), 0) or 0
    self.sampleTokens[profile.key] = self.sampleTokens[profile.key] or {}
    local last = self.sampleTokens[profile.key][token]
    if last and (at - last) < (interval or 8) then return false end
    self.sampleTokens[profile.key][token] = at
    return true
end

function OpponentModels:ObserveEnemy(snapshot, enemy)
    local profile = self:Ensure(enemy)
    if not profile then return nil end
    local mapKey = KWR.Util:Text(snapshot and snapshot.context and snapshot.context.mapKey,
        "WORLD", 24)
    -- Persist the match identity on the profile as well as the transient
    -- session set. A brief context reset must not turn one battleground into
    -- hundreds of "samples" and falsely authorize a learned counterplan.
    if self.sessionSeen[profile.key] ~= true then
        self.sessionSeen[profile.key] = true
        if profile.lastSessionKey ~= self.sessionKey then
            profile.sessions = (profile.sessions or 0) + 1
            profile.lastSessionKey = self.sessionKey
        end
    end
    if enemy.visible == true and self:Throttle(profile, "sighting", 10) then
        profile.sightings = (profile.sightings or 0) + 1
    end
    local location = cleanLocation(enemy.location)
    if location and self:Throttle(profile, "location:" .. location, 12) then
        bump(profile.locations, location, 1)
    end
    if mapKey ~= "WORLD" and self:Throttle(profile, "map:" .. mapKey, 18) then
        bump(profile.maps, mapKey, 1)
    end
    if enemy.localEngaged == true and self:Throttle(profile, "engage", 8) then
        profile.localEngagements = (profile.localEngagements or 0) + 1
        local support = localSupport(snapshot, enemy)
        if support.allies <= 0 then
            profile.isolatedEngagements = (profile.isolatedEngagements or 0) + 1
        else
            profile.groupedEngagements = (profile.groupedEngagements or 0) + 1
        end
        if support.healerSupport > 0 then
            profile.healerSupportedEngagements =
                (profile.healerSupportedEngagements or 0) + 1
        end
        if KWR.CombatSpells:Role(enemy.spec, enemy.role) == "HEALER" then
            profile.healerPressureObserved =
                (profile.healerPressureObserved or 0) + 1
        end
    end
    if enemy.priorityCast and self:Throttle(profile, "priority-cast", 10) then
        profile.priorityCastObserved = (profile.priorityCastObserved or 0) + 1
    end
    if enemy.carrier == true and self:Throttle(profile, "carrier", 12) then
        profile.carrierObserved = (profile.carrierObserved or 0) + 1
    end
    if (enemy.classFile == "ROGUE" or enemy.spec == "Feral")
        and location and self:Throttle(profile, "stealth:" .. location, 15) then
        profile.stealthPressureObserved =
            (profile.stealthPressureObserved or 0) + 1
    end
    local hotspot = snapshot and snapshot.reporter and snapshot.reporter.hotspot
    if location and hotspot and hotspot.label == location
        and hotspot.enemy and hotspot.enemy > 0
        and self:Throttle(profile, "hotspot:" .. location, 10) then
        profile.hotspotPresence = (profile.hotspotPresence or 0) + 1
        bump(profile.hotspotLocations, location, 1)
    end
    local dead = enemy.dead == true
    if dead and self.deathState[profile.key] ~= true then
        profile.deathsObserved = (profile.deathsObserved or 0) + 1
        self.deathState[profile.key] = true
    elseif not dead then
        self.deathState[profile.key] = false
    end
    return profile
end

function OpponentModels:Observe(snapshot)
    if not snapshot or not snapshot.context or snapshot.context.inPvP ~= true then
        if self.sessionKey ~= nil then self:ResetSession(nil) end
        return {
            summary = {
                knownProfiles = 0,
                trustedProfiles = 0,
                score = 0,
                label = "NONE",
                reason = "No live opponent model session.",
                authorized = false,
            },
            profiles = {},
        }
    end
    local sessionKey = KWR.Util:BattlefieldSessionKey(snapshot.context)
    if self.sessionKey ~= sessionKey then
        self:ResetSession(sessionKey)
    end
    local profiles = {}
    local trustedProfiles, knownProfiles, totalScore = 0, 0, 0
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local profile = self:ObserveEnemy(snapshot, enemy)
        local summary = profile and self:Describe(enemy) or nil
        if summary then
            profiles[summary.key] = summary
            knownProfiles = knownProfiles + 1
            totalScore = totalScore + (summary.score or 0)
            if summary.authorized == true then
                trustedProfiles = trustedProfiles + 1
            end
        end
    end
    self:Prune()
    local averageScore = knownProfiles > 0 and (totalScore / knownProfiles) or 0
    local score = KWR.Util:Clamp(
        math.floor(averageScore * 0.6 + trustedProfiles * 8 + 0.5), 0, 100)
    local label = score >= 70 and "HIGH"
        or (score >= 45 and "MEDIUM" or (score >= 20 and "LOW" or "NONE"))
    local reason = trustedProfiles >= 3 and "Multiple enemy profiles have repeat evidence."
        or (trustedProfiles >= 1 and "At least one enemy profile has usable repeat evidence.")
        or (knownProfiles > 0 and "Profiles are still thin and should not drive high-trust calls.")
        or "No enemy profiles collected yet."
    return {
        summary = {
            knownProfiles = knownProfiles,
            trustedProfiles = trustedProfiles,
            score = score,
            label = label,
            reason = reason,
            authorized = trustedProfiles >= 1 and label ~= "LOW" and label ~= "NONE",
        },
        profiles = profiles,
    }
end

function OpponentModels:RecordMatch(entry)
    if not entry or not entry.id then return false end
    local processed = KWR.db.opponentModels.processedMatches
    if processed[entry.id] ~= nil then return false end
    processed[entry.id] = KWR.Util:Number(entry.endedAt, stamp()) or stamp()
    for _, threat in pairs(entry.enemyThreats or {}) do
        local profile = self:Ensure(threat)
        if profile then
            profile.matches = (profile.matches or 0) + 1
            profile.updatedAt = KWR.Util:Number(entry.endedAt, stamp()) or stamp()
            if cleanLocation(threat.lastSeenLocation) then
                bump(profile.locations, threat.lastSeenLocation, 1)
            end
            if threat.flags and threat.flags.carrier then
                profile.carrierObserved = (profile.carrierObserved or 0) + 1
            end
            if threat.flags and threat.flags.stealth then
                profile.stealthPressureObserved =
                    (profile.stealthPressureObserved or 0) + 1
            end
            if threat.flags and threat.flags.healer then
                profile.healerPressureObserved =
                    (profile.healerPressureObserved or 0) + 1
            end
            profile.sightings = (profile.sightings or 0)
                + (KWR.Util:Number(threat.sightings, 0) or 0)
        end
    end
    self:Prune()
    self:PruneProcessedMatches()
    return true
end

function OpponentModels:Describe(entity)
    local key = profileKey(entity)
    local profile = key and KWR.db.opponentModels.players[key] or nil
    if not profile then
        return {
            key = key,
            score = 0,
            label = "NONE",
            reason = "No persistent opponent profile collected.",
            strengths = {},
            weaknesses = {},
            topLocations = {},
            authorized = false,
            traits = {},
            traitSummary = "No learned trait yet.",
            commanderTakeaway = "Takeaway: profile is thin; use as advisory only.",
            noteSummary = "No persistent tendency model collected yet.",
        }
    end
    local now = stamp()
    local sessions = KWR.Util:Number(profile.sessions, 0) or 0
    local matches = KWR.Util:Number(profile.matches, 0) or 0
    local sightings = KWR.Util:Number(profile.sightings, 0) or 0
    local days = daysSince(profile.updatedAt, now) or 0
    local freshnessPenalty = days >= 45 and 25 or (days >= 21 and 12 or (days >= 10 and 4 or 0))
    local score = KWR.Util:Clamp(
        (sessions * 10)
            + (matches * 8)
            + math.min(24, sightings * 2)
            + math.min(12, (profile.localEngagements or 0) * 2)
            - freshnessPenalty,
        0, 100)
    local label = score >= 72 and "HIGH"
        or (score >= 45 and "MEDIUM" or (score >= 20 and "LOW" or "NONE"))
    local topLocations = topCounts(profile.locations, 2)
    local totalLocations = totalCounts(profile.locations)
    local strongestLocation = topLocations[1]
    local strongestShare = strongestLocation and totalLocations > 0
        and (strongestLocation.count / totalLocations) or 0
    local strengths, weaknesses = {}, {}
    if (profile.carrierObserved or 0) >= 3 then
        strengths[#strengths + 1] = "frequent objective carrier"
    end
    if (profile.stealthPressureObserved or 0) >= 3 then
        strengths[#strengths + 1] = "repeats stealth flank pressure"
    end
    if (profile.healerSupportedEngagements or 0) >= 4
        and (profile.healerSupportedEngagements or 0)
            >= ((profile.isolatedEngagements or 0) + 2) then
        strengths[#strengths + 1] = "usually pushes with healer support"
    end
    if (profile.hotspotPresence or 0) >= 4 then
        strengths[#strengths + 1] = "shows up in primary pressure lanes"
    end
    if strongestLocation and strongestShare >= 0.45 and strongestLocation.count >= 3 then
        strengths[#strengths + 1] =
            "favors " .. KWR.Util:Text(strongestLocation.key, "one lane", 32)
    end
    if (profile.isolatedEngagements or 0) >= 3
        and (profile.isolatedEngagements or 0)
            >= ((profile.groupedEngagements or 0) + 1) then
        weaknesses[#weaknesses + 1] = "frequent unsupported pressure"
    end
    if (profile.deathsObserved or 0) >= 3
        and (profile.localEngagements or 0) > 0
        and ((profile.deathsObserved or 0) / math.max(profile.localEngagements, 1)) >= 0.35 then
        weaknesses[#weaknesses + 1] = "dies during pressured commits"
    end
    if strongestLocation and strongestShare >= 0.60 and strongestLocation.count >= 4 then
        weaknesses[#weaknesses + 1] =
            "predictable " .. KWR.Util:Text(strongestLocation.key, "lane", 32) .. " preference"
    end
    if (profile.priorityCastObserved or 0) >= 3
        and (profile.deathsObserved or 0) >= 2 then
        weaknesses[#weaknesses + 1] = "high-value casts have been punishable"
    end
    local traits = buildTraits(profile, strongestLocation, strongestShare)
    local traitSummaryList = traitLabels(traits, 4)
    local traitSummary = #traitSummaryList > 0 and table.concat(traitSummaryList, ", ")
        or "No learned trait yet."
    local takeaway = commanderTakeaway(traits, label)
    local reason = label == "HIGH" and "Repeat enemy behavior is well-sampled."
        or (label == "MEDIUM" and "Repeat enemy behavior is usable with caution.")
        or (label == "LOW" and "Enemy behavior profile is thin and advisory only.")
        or "No trustworthy human-nuance profile yet."
    local locationText = {}
    for _, row in ipairs(topLocations) do
        locationText[#locationText + 1] = row.key .. " x" .. tostring(row.count)
    end
    local summaryParts = {
        "Trust " .. label .. " (" .. tostring(score) .. ")",
        tostring(sessions) .. " sessions",
        tostring(matches) .. " match records",
    }
    if #locationText > 0 then
        summaryParts[#summaryParts + 1] =
            "Routes: " .. table.concat(locationText, ", ")
    end
    if #strengths > 0 then
        summaryParts[#summaryParts + 1] =
            "Strengths: " .. table.concat(strengths, "; ")
    end
    if #weaknesses > 0 then
        summaryParts[#summaryParts + 1] =
            "Weaknesses: " .. table.concat(weaknesses, "; ")
    end
    if #traitSummaryList > 0 then
        summaryParts[#summaryParts + 1] = "Traits: " .. traitSummary
    end
    summaryParts[#summaryParts + 1] = takeaway
    summaryParts[#summaryParts + 1] = "Reason: " .. reason
    local noteSummary = table.concat(summaryParts, " | ")
    return {
        key = profile.key,
        name = profile.name,
        score = score,
        label = label,
        reason = reason,
        sessions = sessions,
        matches = matches,
        strengths = strengths,
        weaknesses = weaknesses,
        topLocations = topLocations,
        traits = traits,
        traitSummary = traitSummary,
        commanderTakeaway = takeaway,
        authorized = label == "HIGH" or (label == "MEDIUM" and sessions >= 2),
        noteSummary = noteSummary,
        daysSinceSeen = days,
    }
end

function OpponentModels:TooltipLines(entity)
    local summary = self:Describe(entity)
    local lines = {
        "PROFILE DATA: " .. KWR.Util:Text(summary.label, "NONE", 12)
            .. " (" .. tostring(summary.score or 0) .. ")",
        "SESSIONS: " .. tostring(summary.sessions or 0)
            .. " | MATCH RECORDS: " .. tostring(summary.matches or 0),
    }
    if summary.topLocations and summary.topLocations[1] then
        local routes = {}
        for _, row in ipairs(summary.topLocations) do
            routes[#routes + 1] = row.key .. " x" .. tostring(row.count)
        end
        lines[#lines + 1] = "ROUTES: " .. table.concat(routes, ", ")
    end
    if summary.strengths and #summary.strengths > 0 then
        lines[#lines + 1] = "STRENGTHS: " .. table.concat(summary.strengths, "; ")
    end
    if summary.weaknesses and #summary.weaknesses > 0 then
        lines[#lines + 1] = "WEAKNESSES: " .. table.concat(summary.weaknesses, "; ")
    end
    if summary.traitSummary and summary.traitSummary ~= "" then
        lines[#lines + 1] = "TRAITS: " .. summary.traitSummary
    end
    if summary.commanderTakeaway then
        lines[#lines + 1] = KWR.Util:Text(summary.commanderTakeaway, "", 120)
    end
    lines[#lines + 1] = "READ: " .. KWR.Util:Text(summary.reason, "No profile.", 120)
    return lines, summary
end

KWR:RegisterModule("OpponentModels", OpponentModels)
