local _, KWR = ...

local Reporter = {
    sessionKey = nil,
    tracks = { friendly = {}, enemy = {} },
    events = {},
    sequence = 0,
    maxPoints = 8,
    maxEvents = 20,
    exportPoints = 4,
    memory = { rotations = {}, routes = {}, revision = 0 },
}
KWR.Reporter = Reporter

local function distance(x1, y1, x2, y2)
    x1, y1 = KWR.Util:Number(x1, nil), KWR.Util:Number(y1, nil)
    x2, y2 = KWR.Util:Number(x2, nil), KWR.Util:Number(y2, nil)
    if not x1 or not y1 or not x2 or not y2 then return nil end
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt((dx * dx) + (dy * dy))
end

local function direction(dx, dy)
    if math.abs(dx) < 0.004 and math.abs(dy) < 0.004 then return "HOLDING" end
    local vertical = dy < -0.004 and "N" or (dy > 0.004 and "S" or "")
    local horizontal = dx > 0.004 and "E" or (dx < -0.004 and "W" or "")
    return vertical .. horizontal
end

local function entityKey(entity, fallback)
    return KWR.Util:Text(entity.key or entity.guid or entity.name, fallback, 80)
end

local function locationPosition(mapKey, label)
    local definition = KWR.Maps:Get(mapKey)
    local canonical = KWR.Maps:CanonicalLocation(mapKey, label)
    local position = definition and definition.positions and definition.positions[canonical]
    if position then
        return KWR.Util:Number(position[1], nil), KWR.Util:Number(position[2], nil), "map_location"
    end
    return nil, nil, nil
end

local function objectivePosition(snapshot, label)
    local mapKey = snapshot and snapshot.context and snapshot.context.mapKey
    local wanted = KWR.Maps:CanonicalLocation(mapKey, label)
    for _, objective in ipairs(snapshot and snapshot.objectives and snapshot.objectives.rows or {}) do
        if KWR.Maps:CanonicalLocation(mapKey, objective.label) == wanted then
            return KWR.Util:Number(objective.x, nil),
                KWR.Util:Number(objective.y, nil),
                "objective_row"
        end
    end
    return nil, nil, nil
end

local function confidenceValue(label)
    if label == "HIGH" then return 3 end
    if label == "MEDIUM" then return 2 end
    if label == "LOW" then return 1 end
    return 0
end

local function objectiveEvidenceFresh(snapshot)
    local context = snapshot and snapshot.context or {}
    if context.inPvP ~= true or context.preview == true then return true end
    local objectives = snapshot and snapshot.objectives or {}
    local source = KWR.Util:Text(objectives.source, "none", 32):lower()
    local observedAt = KWR.Util:Number(objectives.observedAt, nil)
    if source == "none" or source == "unknown" or not observedAt then return false end
    local age = KWR.Util:Now() - observedAt
    return age >= 0 and age <= 8
end

local function topCounts(values, limit)
    local rows = {}
    for key, count in pairs(values or {}) do
        rows[#rows + 1] = { key = key, count = count }
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.key < b.key
    end)
    local result = {}
    for index = 1, math.min(limit or 3, #rows) do
        result[#result + 1] = {
            key = rows[index].key,
            count = rows[index].count,
        }
    end
    return result
end

local function freshnessWeight(track)
    if not track then return 0 end
    if track.visible == true then return 1 end
    local age = KWR.Util:Number(track.age, 999) or 999
    if age <= 5 then return 0.8 end
    if age <= 10 then return 0.6 end
    if age <= 20 then return 0.35 end
    return 0.1
end

local function copyRecentPoints(points, maximum)
    if type(points) ~= "table" or #points == 0 then return nil end
    local startIndex = math.max(1, #points - math.max(maximum or 0, 1) + 1)
    local result = {}
    for index = startIndex, #points do
        local point = points[index]
        result[#result + 1] = {
            x = point.x,
            y = point.y,
            at = point.at,
        }
    end
    return result
end

local function projectTrack(track, includePoints, pointLimit)
    if type(track) ~= "table" then return nil end
    local projected = {
        key = track.key,
        team = track.team,
        name = track.name,
        shortName = track.shortName,
        classFile = track.classFile,
        x = track.x,
        y = track.y,
        age = track.age,
        visible = track.visible,
        ttl = track.ttl,
        evidenceState = track.evidenceState,
        confidence = track.confidence,
        location = track.location,
        locationSource = track.locationSource,
        mapSource = track.mapSource,
        positionSource = track.positionSource,
        positionObservedAt = track.positionObservedAt,
        locationState = track.locationState,
        located = track.located,
        dead = track.dead,
        inCombat = track.inCombat,
        role = track.role,
        healthPercent = track.healthPercent,
        carrier = track.carrier,
        carrierStacks = track.carrierStacks,
        direction = track.direction,
        distance = track.distance,
        speed = track.speed,
    }
    projected.points = includePoints and (copyRecentPoints(track.points, pointLimit) or {}) or {}
    return projected
end

local function copyRecentEvents(events, maximum)
    if type(events) ~= "table" or #events == 0 then return {} end
    local startIndex = math.max(1, #events - math.max(maximum or 1, 1) + 1)
    local result = {}
    for index = startIndex, #events do
        local event = events[index]
        result[#result + 1] = {
            id = event.id,
            at = event.at,
            kind = event.kind,
            text = event.text,
            x = event.x,
            y = event.y,
        }
    end
    return result
end

function Reporter:Reset(sessionKey)
    self.sessionKey = sessionKey
    self.tracks = { friendly = {}, enemy = {} }
    self.events = {}
    self.sequence = 0
    self.hotspotKey = nil
    self.memory = { rotations = {}, routes = {}, revision = 0 }
    self.lastScore = nil
end

function Reporter:AddEvent(kind, text, x, y)
    text = KWR.Util:Text(text, "", 140)
    if text == "" then return end
    local last = self.events[#self.events]
    if last and last.kind == kind and last.text == text and (KWR.Util:Now() - last.at) < 5 then return end
    self.sequence = self.sequence + 1
    self.events[#self.events + 1] = {
        id = self.sequence,
        at = KWR.Util:Now(),
        kind = kind,
        text = text,
        x = KWR.Util:Number(x, nil),
        y = KWR.Util:Number(y, nil),
    }
    while #self.events > self.maxEvents do table.remove(self.events, 1) end
end

function Reporter:Track(team, entity, observedAt, now)
    local x, y = KWR.Util:Number(entity.x, nil), KWR.Util:Number(entity.y, nil)
    local key = entityKey(entity, team .. ":unknown")
    local track = self.tracks[team][key] or {
        key = key,
        team = team,
        name = KWR.Util:Text(entity.shortName or entity.name, "Unknown", 40),
        classFile = KWR.Util:Upper(entity.classFile, "UNKNOWN", 24),
        points = {},
        direction = "HOLDING",
        distance = 0,
    }
    local previousLocation = track.location
    local at = KWR.Util:Number(observedAt, KWR.Util:Now())
    if x and y then
        local last = track.points[#track.points]
        if not last or last.at ~= at then
            local moved = last and distance(last.x, last.y, x, y) or 0
            if not last or moved >= 0.002 or (at - last.at) >= 5 then
                track.points[#track.points + 1] = { x = x, y = y, at = at }
                while #track.points > self.maxPoints do table.remove(track.points, 1) end
                if last then
                    track.dx, track.dy = x - last.x, y - last.y
                    track.distance = moved or 0
                    track.direction = direction(track.dx, track.dy)
                    local elapsed = math.max(at - last.at, 0.1)
                    track.speed = KWR.Util:Clamp((moved or 0) / elapsed, 0, 0.12)
                    track.velocityX = track.dx / elapsed
                    track.velocityY = track.dy / elapsed
                end
            end
        end
        track.x, track.y = x, y
        track.positionSource = "OBSERVED"
        track.positionObservedAt = at
        track.mapSource = KWR.Util:Text(entity.mapSource, "unit_position", 32)
    end
    track.observedAt = at
    track.age = math.max(0, (now or KWR.Util:Now()) - at)
    track.visible = entity.visible == true or team == "friendly"
    track.ttl = team == "friendly" and 10 or (track.visible and 8 or 20)
    track.expiresAt = at + track.ttl
    track.evidenceState = track.age <= track.ttl
        and (track.visible and "VISIBLE" or "RECENT") or "STALE"
    track.confidence = track.visible and "HIGH"
        or (track.age <= 10 and "MEDIUM"
        or (track.age <= track.ttl and "LOW" or "NONE"))
    track.location = KWR.Util:Text(entity.location, track.location or "Unknown", 48)
    track.locationSource = KWR.Util:Text(
        entity.locationSource, track.locationSource or "Observed Unit", 32)
    track.locationState = KWR.Util:Text(
        entity.locationState, track.visible and "VISIBLE" or "LAST SEEN", 16)
    track.located = track.x ~= nil and track.y ~= nil
    track.dead = entity.dead == true
    track.inCombat = entity.inCombat == true
    track.role = KWR.Util:Upper(entity.role or entity.groupRole, track.role or "NONE", 16)
    track.healthPercent = KWR.Util:Number(entity.healthPercent, track.healthPercent)
    track.spec = KWR.Util:Text(entity.spec, track.spec or "Unknown", 32)
    if team == "enemy" and previousLocation and previousLocation ~= "Unknown"
        and track.location ~= "Unknown" and previousLocation ~= track.location
        and (not track.lastMemoryAt or at - track.lastMemoryAt >= 3) then
        local route = previousLocation .. " -> " .. track.location
        self.memory.routes[route] = (self.memory.routes[route] or 0) + 1
        self.memory.rotations[track.location] =
            (self.memory.rotations[track.location] or 0) + 1
        self.memory.revision = (self.memory.revision or 0) + 1
        track.lastMemoryAt = at
    end
    self.tracks[team][key] = track
    return track
end

function Reporter:FallbackTrackPositions(snapshot)
    local mapKey = snapshot and snapshot.context and snapshot.context.mapKey
    if not mapKey then return end
    -- A track may be observed without exact coordinates (for example, from
    -- roster/spec data). Resolve both teams to the best known objective or
    -- map location so the tactical map can still show the player. This is an
    -- estimate, never fabricated positioning: unknown locations remain hidden.
    for _, team in ipairs({ "friendly", "enemy" }) do
        for _, track in pairs(self.tracks[team] or {}) do
            if not track.x or not track.y then
                local px, py, source = objectivePosition(snapshot, track.location)
                if not px or not py then
                    px, py, source = locationPosition(mapKey, track.location)
                end
                if px and py then
                    track.x, track.y = px, py
                    track.located = true
                    track.mapSource = source or "location_fallback"
                    track.positionSource = "ESTIMATED"
                    track.positionObservedAt = nil
                end
            end
        end
    end
end

function Reporter:PruneTracks(snapshot, now)
    local roster = snapshot and snapshot.roster or {}
    local presentFriendly = {}
    for _, player in ipairs(roster) do
        presentFriendly[entityKey(player, "friendly:unknown")] = true
    end
    if #roster > 0 then
        for key in pairs(self.tracks.friendly or {}) do
            if presentFriendly[key] ~= true then
                self.tracks.friendly[key] = nil
            end
        end
    end
end

local function travelSpeed(track)
    if track.speed and track.speed >= 0.003 then
        return KWR.Util:Clamp(track.speed, 0.008, 0.08), "OBSERVED"
    end
    local capability = KWR.Capabilities:Resolve(track.classFile, track.spec)
    local mobility = capability and capability.ratings
        and capability.ratings.mobility or 2
    local speed = 0.018 + (mobility * 0.004)
    if track.inCombat then speed = speed * 0.72 end
    return speed, "ESTIMATED"
end

function Reporter:ObjectiveETAs(snapshot)
    local result = {}
    if not objectiveEvidenceFresh(snapshot) then return result end
    local mapKey = snapshot.context and snapshot.context.mapKey
    for _, objective in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local x, y = KWR.Util:Number(objective.x, nil), KWR.Util:Number(objective.y, nil)
        if x and y then
            local row = {
                label = objective.label,
                owner = objective.owner,
                friendlyETA = nil,
                enemyETA = nil,
                friendlyCount = 0,
                enemyCount = 0,
                observedSpeeds = 0,
                observedPositions = 0,
                estimatedRoutes = 0,
            }
            for team, tracks in pairs(self.tracks) do
                for _, track in pairs(tracks) do
                    local maxAge = team == "friendly" and 10 or 30
                    if not track.dead and (track.age or 999) <= maxAge then
                        local positionObserved = track.positionSource == "OBSERVED"
                            and (track.age or 999) <= 10
                        local range = track.x and track.y
                            and distance(track.x, track.y, x, y) or nil
                        local speed, source = travelSpeed(track)
                        local eta = range and math.ceil(range / math.max(speed, 0.001)) or nil
                        local etaSource = positionObserved and source == "OBSERVED"
                            and "OBSERVED_POSITION_SPEED" or "ESTIMATED_POSITION_OR_SPEED"
                        if not eta and track.location
                            and track.location ~= "Unknown" then
                            local capability = KWR.Capabilities:Resolve(
                                track.classFile, track.spec)
                            local route = KWR.Maps:TravelEstimate(
                                mapKey, track.location, objective.label, {
                                    mobility = capability and capability.ratings
                                        and capability.ratings.mobility or 2,
                                    inCombat = track.inCombat,
                                    observed = false,
                                })
                            if route then
                                eta = route.seconds
                                source = route.source
                                etaSource = "MAP_ROUTE_ESTIMATE"
                            end
                        end
                        if eta then
                            local field = team == "friendly" and "friendlyETA" or "enemyETA"
                            local countField = team == "friendly" and "friendlyCount" or "enemyCount"
                            row[field] = not row[field] and eta or math.min(row[field], eta)
                            row[countField] = row[countField] + 1
                            if source == "OBSERVED" then
                                row.observedSpeeds = row.observedSpeeds + 1
                            end
                            if positionObserved then
                                row.observedPositions = row.observedPositions + 1
                            end
                            if etaSource ~= "OBSERVED_POSITION_SPEED" then
                                row.estimatedRoutes = row.estimatedRoutes + 1
                            end
                            local sourceField = team == "friendly"
                                and "friendlySource" or "enemySource"
                            if row[field] == eta then
                                row[sourceField] = etaSource
                            end
                        end
                    end
                end
            end
            if row.friendlyETA or row.enemyETA then
                row.estimatedAdvantage = row.friendlyETA and row.enemyETA
                    and (row.enemyETA - row.friendlyETA) or nil
                row.advantageQualified = row.friendlySource == "OBSERVED_POSITION_SPEED"
                    and row.enemySource == "OBSERVED_POSITION_SPEED"
                row.advantage = row.advantageQualified and row.estimatedAdvantage or nil
                local coverage = row.friendlyCount + row.enemyCount
                row.confidence = row.advantageQualified and row.observedSpeeds >= 2 and "HIGH"
                    or (coverage >= 3 and "LOW" or "NONE")
                row.observedAt = KWR.Util:Now()
                row.expiresAt = row.observedAt + 8
                result[#result + 1] = row
            end
        end
    end
    table.sort(result, function(a, b)
        local left = math.min(a.friendlyETA or 999, a.enemyETA or 999)
        local right = math.min(b.friendlyETA or 999, b.enemyETA or 999)
        if left ~= right then return left < right end
        return a.label < b.label
    end)
    return result
end

function Reporter:PredictIntent(snapshot, etas)
    local ranked = {}
    for _, objective in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local x, y = KWR.Util:Number(objective.x, nil), KWR.Util:Number(objective.y, nil)
        if x and y then
            local score, group, eta, evidence = 0, 0, nil, {}
            local commitment, approachWeight, stalePenalty = 0, 0, 0
            local anchored, visibleTracks = 0, 0
            for _, track in pairs(self.tracks.enemy) do
                if track.x and track.y and not track.dead and (track.age or 999) <= 20 then
                    local freshness = freshnessWeight(track)
                    local current = distance(track.x, track.y, x, y)
                    local projected = track.velocityX and distance(
                        track.x + track.velocityX * 5,
                        track.y + track.velocityY * 5, x, y) or current
                    if current and current <= 0.24 then
                        group = group + 1
                        score = score + math.floor((6 * freshness) + 0.5)
                        if track.visible then visibleTracks = visibleTracks + 1 end
                        if current <= 0.12 then
                            commitment = commitment + freshness
                        end
                        if current <= 0.08 and (track.inCombat or track.direction == "HOLDING") then
                            anchored = anchored + 1
                            score = score + math.floor((5 * freshness) + 0.5)
                        end
                        if freshness < 0.5 then
                            stalePenalty = stalePenalty + math.floor((1 - freshness) * 8)
                        end
                    end
                    if current and projected and projected < current - 0.004 then
                        score = score + math.floor((14 * freshness) + 0.5)
                        approachWeight = approachWeight + freshness
                        evidence[#evidence + 1] = track.name .. " moving toward"
                    end
                    local speed = travelSpeed(track)
                    if current then
                        local trackETA = math.ceil(current / math.max(speed, 0.001))
                        eta = eta and math.min(eta, trackETA) or trackETA
                    end
                end
            end
            if objective.owner == "FRIENDLY" then score = score + 10 end
            local repeated = self.memory.rotations[objective.label] or 0
            score = score + math.min(12, repeated * 3)
            if repeated > 0 then evidence[#evidence + 1] = "match pattern x" .. repeated end
            if group > 0 then evidence[#evidence + 1] = tostring(group) .. " nearby" end
            if commitment >= 2 then
                score = score + 8
                evidence[#evidence + 1] = "multiple committed tracks"
            end
            if anchored >= 2 then
                score = score + 6
                evidence[#evidence + 1] = "enemy anchored"
            end
            local etaRow
            for _, row in ipairs(etas or {}) do
                if row.label == objective.label then
                    etaRow = row
                    break
                end
            end
            if etaRow and etaRow.enemyETA and etaRow.enemyETA <= 12 then
                score = score + 6
                evidence[#evidence + 1] = "fast enemy ETA"
            end
            ranked[#ranked + 1] = {
                target = objective.label,
                score = score,
                groupSize = group,
                eta = eta,
                evidence = evidence,
                commitmentScore = KWR.Util:Clamp(
                    math.floor((commitment * 22)
                        + (approachWeight * 8)
                        + (visibleTracks * 3)
                        - stalePenalty + 0.5),
                    0, 100),
                commitment = commitment,
                anchored = anchored,
                visibleTracks = visibleTracks,
                stalePenalty = stalePenalty,
            }
        end
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.target < b.target
    end)
    local best = ranked[1]
    local second = ranked[2]
    local candidateSummary = {}
    for index = 1, math.min(3, #ranked) do
        candidateSummary[#candidateSummary + 1] = {
            target = ranked[index].target,
            score = ranked[index].score,
            eta = ranked[index].eta,
            groupSize = ranked[index].groupSize,
        }
    end
    if not best or best.score < 12 then
        return {
            target = nil,
            confidence = "NONE",
            score = best and best.score or 0,
            candidates = candidateSummary,
        }
    end
    local separation = best.score - (second and second.score or 0)
    best.confidenceScore = KWR.Util:Clamp(20 + best.score + math.min(10, separation), 0, 90)
    if (best.commitmentScore or 0) < 35 then
        best.confidenceScore = math.max(15, best.confidenceScore - 10)
        best.evidence[#best.evidence + 1] = "commitment still soft"
    end
    if (best.stalePenalty or 0) >= 8 then
        best.confidenceScore = math.max(15, best.confidenceScore - 8)
        best.evidence[#best.evidence + 1] = "stale movement evidence"
    end
    if second and separation <= 6 then
        best.confidenceScore = math.max(20, best.confidenceScore - 14)
        best.evidence[#best.evidence + 1] = "split enemy options"
        best.decoyTarget = second.target
        best.decoyScore = second.score
    end
    best.confidence = best.confidenceScore >= 70 and "HIGH"
        or (best.confidenceScore >= 45 and "MEDIUM" or "LOW")
    best.observedAt = KWR.Util:Now()
    best.expiresAt = best.observedAt + 10
    best.separation = separation
    best.candidates = candidateSummary
    return best
end

function Reporter:Momentum(snapshot, pressure)
    local friendlyDead, enemyDead, friendlyHealers, enemyHealers = 0, 0, 0, 0
    for _, player in ipairs(snapshot.roster or {}) do
        if player.dead then friendlyDead = friendlyDead + 1 end
        if player.role == "HEALER" and not player.dead then friendlyHealers = friendlyHealers + 1 end
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if enemy.dead then enemyDead = enemyDead + 1 end
        if enemy.role == "HEALER" and not enemy.dead then enemyHealers = enemyHealers + 1 end
    end
    local value = (enemyDead - friendlyDead) * 9
        + (friendlyHealers - enemyHealers) * 5
    local hotspot = pressure and pressure[1]
    if hotspot then value = value + (hotspot.friendly - hotspot.enemy) * 6 end
    local score = snapshot.score or {}
    if self.lastScore then
        value = value + KWR.Util:Clamp(
            ((score.friendly or 0) - (self.lastScore.friendly or 0))
                - ((score.enemy or 0) - (self.lastScore.enemy or 0)), -20, 20)
    end
    self.lastScore = { friendly = score.friendly, enemy = score.enemy }
    value = KWR.Util:Clamp(value, -100, 100)
    return {
        value = value,
        state = value >= 20 and "FRIENDLY"
            or (value <= -20 and "ENEMY" or "EVEN"),
        friendlyDead = friendlyDead,
        enemyDead = enemyDead,
        friendlyHealers = friendlyHealers,
        enemyHealers = enemyHealers,
        confidence = (#(snapshot.roster or {}) >= 8 and #(snapshot.enemies or {}) >= 8)
            and "MEDIUM" or "LOW",
    }
end

function Reporter:ObjectivePressure(snapshot)
    local pressure = {}
    if not objectiveEvidenceFresh(snapshot) then return pressure end
    for _, objective in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local x, y = KWR.Util:Number(objective.x, nil), KWR.Util:Number(objective.y, nil)
        if x and y then
            local row = {
                key = KWR.Util:Text(objective.label, "Objective", 48),
                label = KWR.Util:Text(objective.label, "Objective", 48),
                owner = KWR.Util:Text(objective.owner, "UNKNOWN", 12),
                x = x,
                y = y,
                friendly = 0,
                enemy = 0,
                friendlyCombat = 0,
                enemyCombat = 0,
                friendlyEstimated = 0,
                enemyEstimated = 0,
            }
            for _, track in pairs(self.tracks.friendly) do
                local range = distance(track.x, track.y, x, y)
                if range and range <= 0.12 and not track.dead
                    and track.positionSource == "OBSERVED"
                    and (track.age or 999) <= 10 then
                    row.friendly = row.friendly + 1
                    if track.inCombat then row.friendlyCombat = row.friendlyCombat + 1 end
                elseif range and range <= 0.12 and not track.dead then
                    row.friendlyEstimated = row.friendlyEstimated + 1
                end
            end
            for _, track in pairs(self.tracks.enemy) do
                local range = distance(track.x, track.y, x, y)
                if range and range <= 0.12 and (track.age or 999) <= 10
                    and not track.dead and track.positionSource == "OBSERVED" then
                    row.enemy = row.enemy + 1
                    if track.inCombat then row.enemyCombat = row.enemyCombat + 1 end
                elseif range and range <= 0.12 and not track.dead then
                    row.enemyEstimated = row.enemyEstimated + 1
                end
            end
            row.delta = row.enemy - row.friendly
            row.total = row.enemy + row.friendly
            row.observedAt = KWR.Util:Now()
            row.expiresAt = row.observedAt + 8
            row.confidence = row.total >= 4 and "MEDIUM"
                or (row.total > 0 and "LOW" or "NONE")
            row.state = row.owner == "FRIENDLY" and row.delta >= 2 and "UNDERDEFENDED"
                or (row.owner == "FRIENDLY" and row.friendly >= row.enemy + 3 and row.enemy <= 1
                    and "STABLE")
                or (row.owner == "ENEMY" and row.enemy >= row.friendly + 3 and "ENEMY_STACKED")
                or (row.total >= 3 and "CONTESTED")
                or "QUIET"
            row.risk = KWR.Util:Clamp(
                35 + (row.delta * 18) + (row.enemy * 7)
                    + (row.enemyCombat * 6) + (row.friendlyCombat * 2),
                0, 100)
            pressure[#pressure + 1] = row
        end
    end
    table.sort(pressure, function(a, b)
        if a.risk ~= b.risk then return a.risk > b.risk end
        return a.total > b.total
    end)
    return pressure
end

function Reporter:TrustProfile(snapshot, pressure, etas, intent)
    local coverage = {
        friendly = 0, enemy = 0,
        friendlyLocated = 0, enemyLocated = 0,
        friendlyEstimated = 0, enemyEstimated = 0,
    }
    local staleEnemy = 0
    for _, track in pairs(self.tracks.friendly) do
        coverage.friendly = coverage.friendly + 1
        if track.located then coverage.friendlyLocated = coverage.friendlyLocated + 1 end
        if track.located and track.positionSource == "ESTIMATED" then
            coverage.friendlyEstimated = coverage.friendlyEstimated + 1
        end
    end
    for _, track in pairs(self.tracks.enemy) do
        coverage.enemy = coverage.enemy + 1
        if track.located then coverage.enemyLocated = coverage.enemyLocated + 1 end
        if track.located and track.positionSource == "ESTIMATED" then
            coverage.enemyEstimated = coverage.enemyEstimated + 1
        end
        if track.visible ~= true and (track.age or 999) > 10 then
            staleEnemy = staleEnemy + 1
        end
    end
    local coverageScore = coverage.friendlyLocated + coverage.enemyLocated
    local topPressure = pressure and pressure[1] or nil
    local etaConfidence = etas and etas[1] and confidenceValue(etas[1].confidence) or 0
    local intentConfidence = confidenceValue(intent and intent.confidence)
    local commitmentScore = KWR.Util:Number(intent and intent.commitmentScore, 0) or 0
    local hiddenRisk = math.max(0,
        math.max(0, coverage.enemy - coverage.enemyLocated) * 8
            + (staleEnemy * 4)
            + ((topPressure and topPressure.enemy or 0) >= 3 and 10 or 0)
            + (intent and intent.decoyTarget and 14 or 0)
            + (intent and intent.target and commitmentScore < 35 and 8 or 0))
    local score = KWR.Util:Clamp(
        coverageScore * 8
            + etaConfidence * 8
            + intentConfidence * 10
            + math.min(12, math.floor(commitmentScore / 10))
            - hiddenRisk,
        0, 100)
    local label = score >= 75 and "HIGH"
        or (score >= 50 and "MEDIUM" or (score >= 30 and "LOW" or "NONE"))
    local pace = label == "HIGH" and "COMMIT_OK"
        or (label == "MEDIUM" and "PROBE_OK" or "VERIFY_FIRST")
    local reasons = {}
    reasons[#reasons + 1] = string.format("%dF/%dE located",
        coverage.friendlyLocated or 0, coverage.enemyLocated or 0)
    if intent and intent.target then
        reasons[#reasons + 1] = tostring(intent.confidence or "LOW")
            .. " intent on " .. tostring(intent.target)
    end
    if intent and intent.target then
        reasons[#reasons + 1] = "commit " .. tostring(intent.commitmentScore or 0)
    end
    if intent and intent.decoyTarget then
        reasons[#reasons + 1] = "decoy risk " .. tostring(intent.decoyTarget)
    end
    if staleEnemy > 0 then
        reasons[#reasons + 1] = tostring(staleEnemy) .. " stale enemy tracks"
    end
    if topPressure and topPressure.state ~= "QUIET" then
        reasons[#reasons + 1] = topPressure.label .. " " .. topPressure.state
    end
    return {
        score = score,
        label = label,
        pace = pace,
        hiddenRisk = hiddenRisk,
        reason = table.concat(reasons, ", "),
        commitAuthorized = pace == "COMMIT_OK",
        decoyTarget = intent and intent.decoyTarget or nil,
    }
end

function Reporter:BattlefieldRead(summary, callHint, trust, hotspot, intent)
    local confidence = KWR.Util:Text(trust and trust.label, "NONE", 16)
    local status = "Needs eyes"
    if intent and intent.target and intent.confidence == "HIGH" then
        status = "Likely rotation"
    elseif hotspot and hotspot.enemy and hotspot.enemy >= 2 and hotspot.delta > 0 then
        status = "Observed pressure"
    elseif hotspot and hotspot.total and hotspot.total > 0 then
        status = "Active cluster"
    elseif confidence == "LOW" or confidence == "NONE" then
        status = "Needs eyes"
    end
    local action = KWR.Util:Text(callHint, "", 140)
    if action == "" then
        if status == "Needs eyes" then
            action = "Hold current assignment and gather safe observations."
        elseif hotspot and hotspot.label then
            action = "Keep assignments aligned around " .. hotspot.label .. "."
        else
            action = "Hold the current call."
        end
    end
    return {
        status = status,
        confidence = confidence,
        headline = KWR.Util:Text(summary, "Reporter is waiting for safe battlefield facts.", 180),
        action = action,
        hotspot = hotspot and hotspot.label or nil,
        intent = intent and intent.target or nil,
        risk = hotspot and hotspot.risk or 0,
        source = (intent and intent.target and "intent")
            or (hotspot and hotspot.label and "hotspot")
            or "coverage",
    }
end

function Reporter:Snapshot(snapshot)
    local now = KWR.Util:Now()
    local includeMapDetail = snapshot.context and (snapshot.context.preview == true
        or snapshot.context.inPvP ~= true)
        or (KWR.MainWindow and KWR.MainWindow.frame
            and KWR.MainWindow.frame:IsShown()
            and KWR.MainWindow.activePage == "TACTICAL")
    local friendly, enemy = {}, {}
    for _, track in pairs(self.tracks.friendly) do
        friendly[#friendly + 1] = projectTrack(track, includeMapDetail, self.exportPoints)
    end
    for _, track in pairs(self.tracks.enemy) do
        enemy[#enemy + 1] = projectTrack(track, includeMapDetail, self.exportPoints)
    end
    table.sort(friendly, function(a, b) return a.name < b.name end)
    table.sort(enemy, function(a, b)
        if (a.age or 999) ~= (b.age or 999) then return (a.age or 999) < (b.age or 999) end
        return a.name < b.name
    end)
    local friendlyCombat, enemyCombat = 0, 0
    local enemyVisible, enemyRecent, enemyStale = 0, 0, 0
    for _, track in ipairs(friendly) do
        if track.inCombat and not track.dead then friendlyCombat = friendlyCombat + 1 end
    end
    for _, track in ipairs(enemy) do
        if track.inCombat and not track.dead and (track.age or 999) <= 10 then
            enemyCombat = enemyCombat + 1
        end
        if track.visible == true then
            enemyVisible = enemyVisible + 1
        elseif (track.age or 999) <= 10 then
            enemyRecent = enemyRecent + 1
        else
            enemyStale = enemyStale + 1
        end
    end

    local pressure = self:ObjectivePressure(snapshot)
    local etas = self:ObjectiveETAs(snapshot)
    local intent = self:PredictIntent(snapshot, etas)
    local momentum = self:Momentum(snapshot, pressure)
    local trust = self:TrustProfile(snapshot, pressure, etas, intent)
    local hotspot = pressure[1]
    local risk = hotspot and hotspot.risk or 0
    local routes = topCounts(self.memory and self.memory.routes, 3)
    local summary, callHint
    if trust.pace == "VERIFY_FIRST" and hotspot and hotspot.total > 0 then
        summary = string.format("%s is active but confidence is %s: verify before a full commit.",
            hotspot.label, trust.label)
        callHint = "Hold the score floor and verify " .. hotspot.label .. " before over-rotating."
    elseif intent and intent.target and intent.confidence == "HIGH" then
        summary = string.format("High-confidence enemy hit likely %s in %ss.",
            intent.target, intent.eta or 0)
        callHint = "Pre-position for " .. intent.target .. " and keep the score floor intact."
    elseif hotspot and hotspot.enemy >= 2 and hotspot.delta > 0 then
        summary = string.format("%s under observed pressure: %d friendly / %d enemy-known / %d engaged.",
            hotspot.label, hotspot.friendly, hotspot.enemy,
            (hotspot.friendlyCombat or 0) + (hotspot.enemyCombat or 0))
        callHint = "Reinforce " .. hotspot.label .. " from the nearest assignment."
    elseif hotspot and hotspot.total > 0 then
        summary = string.format("%s is the active movement cluster: %d friendly / %d enemy-known.",
            hotspot.label, hotspot.friendly, hotspot.enemy)
        callHint = "Keep the team aligned with " .. hotspot.label .. "."
    elseif #friendly > 0 or #enemy > 0 then
        summary = string.format("Movement coverage: %d friendly / %d enemy tracks.", #friendly, #enemy)
        callHint = "Hold the current call while Reporter builds movement confidence."
    else
        summary = "Live objectives active. Player coordinates are restricted in instanced PvP."
        callHint = nil
    end

    if hotspot and hotspot.key ~= self.hotspotKey then
        self.hotspotKey = hotspot.key
        self:AddEvent("HOTSPOT", summary, hotspot.x, hotspot.y)
    end
    local battlefieldRead = self:BattlefieldRead(summary, callHint, trust, hotspot, intent)

    return {
        active = snapshot.context.inPvP == true,
        preview = snapshot.context.preview == true,
        mapID = snapshot.context.mapID,
        updatedAt = KWR.Util:Now(),
        friendly = friendly,
        enemy = enemy,
        pressure = pressure,
        etas = etas,
        enemyIntent = intent,
        momentum = momentum,
        trust = trust,
        matchMemory = {
            revision = self.memory and self.memory.revision or 0,
        },
        hotspot = hotspot and {
            key = hotspot.key,
            label = hotspot.label,
            x = hotspot.x,
            y = hotspot.y,
            risk = hotspot.risk,
            total = hotspot.total,
            state = hotspot.state,
            friendly = hotspot.friendly,
            enemy = hotspot.enemy,
            delta = hotspot.delta,
        } or nil,
        risk = risk,
        summary = summary,
        callHint = callHint,
        battlefieldRead = battlefieldRead,
        routes = routes,
        coverage = {
            friendly = #friendly,
            enemy = #enemy,
            friendlyCombat = friendlyCombat,
            enemyCombat = enemyCombat,
            enemyVisible = enemyVisible,
            enemyRecent = enemyRecent,
            enemyStale = enemyStale,
            friendlyLocated = (function()
                local count = 0
                for _, track in ipairs(friendly) do if track.located then count = count + 1 end end
                return count
            end)(),
            enemyLocated = (function()
                local count = 0
                for _, track in ipairs(enemy) do if track.located then count = count + 1 end end
                return count
            end)(),
        },
        events = copyRecentEvents(self.events, includeMapDetail and 6 or 1),
    }
end

function Reporter:Observe(snapshot)
    if not snapshot or not snapshot.context or not snapshot.context.inPvP then
        if self.sessionKey ~= nil then self:Reset(nil) end
        return {
            active = false,
            friendly = {},
            enemy = {},
            pressure = {},
            events = {},
            risk = 0,
            summary = "Reporter standing by. Enter a battleground to build movement knowledge.",
            coverage = { friendly = 0, enemy = 0 },
        }
    end

    local sessionKey = KWR.Util:BattlefieldSessionKey(snapshot.context)
    if self.sessionKey ~= sessionKey then
        self:Reset(sessionKey)
        self:AddEvent("SESSION", "Reporter movement session started.")
    end

    local now = KWR.Util:Now()
    local capturedAt = KWR.Util:Number(snapshot.capturedAt, now)
    for _, player in ipairs(snapshot.roster or {}) do
        self:Track("friendly", player, player.lastSeenAt or capturedAt, now)
    end
    for _, enemy in ipairs(snapshot.enemies or {}) do
        local observedAt = enemy.lastSeenAt
        if enemy.visible and not observedAt then observedAt = capturedAt end
        if observedAt then self:Track("enemy", enemy, observedAt, now) end
    end
    self:PruneTracks(snapshot, now)
    self:FallbackTrackPositions(snapshot)
    return self:Snapshot(snapshot)
end

function Reporter:Distance(x1, y1, x2, y2)
    return distance(x1, y1, x2, y2)
end

function Reporter:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "Reporter")
    end
end

KWR:RegisterModule("Reporter", Reporter)
