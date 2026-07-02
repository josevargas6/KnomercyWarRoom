local _, KWR = ...

local Reporter = {
    sessionKey = nil,
    tracks = { friendly = {}, enemy = {} },
    events = {},
    sequence = 0,
    maxPoints = 12,
    maxEvents = 40,
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
    end
    track.observedAt = at
    track.age = math.max(0, (now or KWR.Util:Now()) - at)
    track.visible = entity.visible == true or team == "friendly"
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
            }
            for team, tracks in pairs(self.tracks) do
                for _, track in pairs(tracks) do
                    local maxAge = team == "friendly" and 10 or 30
                    if track.x and track.y and not track.dead
                        and (track.age or 999) <= maxAge then
                        local range = distance(track.x, track.y, x, y)
                        local speed, source = travelSpeed(track)
                        local eta = range and math.ceil(range / math.max(speed, 0.001)) or nil
                        if eta then
                            local field = team == "friendly" and "friendlyETA" or "enemyETA"
                            local countField = team == "friendly" and "friendlyCount" or "enemyCount"
                            row[field] = not row[field] and eta or math.min(row[field], eta)
                            row[countField] = row[countField] + 1
                            if source == "OBSERVED" then
                                row.observedSpeeds = row.observedSpeeds + 1
                            end
                        end
                    end
                end
            end
            if row.friendlyETA or row.enemyETA then
                row.advantage = row.friendlyETA and row.enemyETA
                    and (row.enemyETA - row.friendlyETA) or nil
                local coverage = row.friendlyCount + row.enemyCount
                row.confidence = row.observedSpeeds >= 2 and "HIGH"
                    or (coverage >= 3 and "MEDIUM" or "LOW")
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
    local best
    for _, objective in ipairs(snapshot.objectives and snapshot.objectives.rows or {}) do
        local x, y = KWR.Util:Number(objective.x, nil), KWR.Util:Number(objective.y, nil)
        if x and y then
            local score, group, eta, evidence = 0, 0, nil, {}
            for _, track in pairs(self.tracks.enemy) do
                if track.x and track.y and not track.dead and (track.age or 999) <= 20 then
                    local current = distance(track.x, track.y, x, y)
                    local projected = track.velocityX and distance(
                        track.x + track.velocityX * 5,
                        track.y + track.velocityY * 5, x, y) or current
                    if current and current <= 0.24 then
                        group = group + 1
                        score = score + 8
                    end
                    if current and projected and projected < current - 0.004 then
                        score = score + 14
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
            if not best or score > best.score then
                best = {
                    target = objective.label,
                    score = score,
                    groupSize = group,
                    eta = eta,
                    evidence = evidence,
                }
            end
        end
    end
    if not best or best.score < 12 then
        return { target = nil, confidence = "NONE", score = best and best.score or 0 }
    end
    best.confidenceScore = KWR.Util:Clamp(20 + best.score, 0, 90)
    best.confidence = best.confidenceScore >= 70 and "HIGH"
        or (best.confidenceScore >= 45 and "MEDIUM" or "LOW")
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
            }
            for _, track in pairs(self.tracks.friendly) do
                local range = distance(track.x, track.y, x, y)
                if range and range <= 0.12 and not track.dead then
                    row.friendly = row.friendly + 1
                    if track.inCombat then row.friendlyCombat = row.friendlyCombat + 1 end
                end
            end
            for _, track in pairs(self.tracks.enemy) do
                local range = distance(track.x, track.y, x, y)
                if range and range <= 0.12 and (track.age or 999) <= 30 and not track.dead then
                    row.enemy = row.enemy + 1
                    if track.inCombat then row.enemyCombat = row.enemyCombat + 1 end
                end
            end
            row.delta = row.enemy - row.friendly
            row.total = row.enemy + row.friendly
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

function Reporter:Snapshot(snapshot)
    local now = KWR.Util:Now()
    local friendly, enemy = {}, {}
    for _, track in pairs(self.tracks.friendly) do friendly[#friendly + 1] = KWR.Util:Copy(track) end
    for _, track in pairs(self.tracks.enemy) do enemy[#enemy + 1] = KWR.Util:Copy(track) end
    table.sort(friendly, function(a, b) return a.name < b.name end)
    table.sort(enemy, function(a, b)
        if (a.age or 999) ~= (b.age or 999) then return (a.age or 999) < (b.age or 999) end
        return a.name < b.name
    end)
    local friendlyCombat, enemyCombat = 0, 0
    for _, track in ipairs(friendly) do
        if track.inCombat and not track.dead then friendlyCombat = friendlyCombat + 1 end
    end
    for _, track in ipairs(enemy) do
        if track.inCombat and not track.dead and (track.age or 999) <= 10 then
            enemyCombat = enemyCombat + 1
        end
    end

    local pressure = self:ObjectivePressure(snapshot)
    local etas = self:ObjectiveETAs(snapshot)
    local intent = self:PredictIntent(snapshot, etas)
    local momentum = self:Momentum(snapshot, pressure)
    local hotspot = pressure[1]
    local risk = hotspot and hotspot.risk or 0
    local summary, callHint
    if hotspot and hotspot.enemy >= 2 and hotspot.delta > 0 then
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
        matchMemory = KWR.Util:Copy(self.memory),
        hotspot = hotspot and KWR.Util:Copy(hotspot) or nil,
        risk = risk,
        summary = summary,
        callHint = callHint,
        coverage = {
            friendly = #friendly,
            enemy = #enemy,
            friendlyCombat = friendlyCombat,
            enemyCombat = enemyCombat,
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
        events = KWR.Util:Copy(self.events),
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

    local sessionKey = tostring(snapshot.context.mapID or snapshot.context.mapKey)
        .. (snapshot.context.preview and ":preview" or ":live")
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
    return self:Snapshot(snapshot)
end

function Reporter:Distance(x1, y1, x2, y2)
    return distance(x1, y1, x2, y2)
end

KWR:RegisterModule("Reporter", Reporter)
