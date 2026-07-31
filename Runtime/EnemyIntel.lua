local _, KWR = ...

local EnemyIntel = {
    records = {},
    sessionKey = nil,
    observedTokens = {},
    maxNotes = 320,
}
KWR.EnemyIntel = EnemyIntel

local friendlyIdentityMaps

local function keyFor(guid, name)
    return KWR.Util:CanonicalPlayerKey(name, guid)
        or ("NAME:" .. KWR.Util:CanonicalName(name or "unknown"))
end

local function classColor(classFile)
    local colors = type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS or nil
    local color = colors and colors[classFile]
    if color then return color.r or 0.7, color.g or 0.7, color.b or 0.7 end
    return 0.72, 0.72, 0.72
end

local CLASS_ID = {
    WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
    DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9, MONK = 10,
    DRUID = 11, DEMONHUNTER = 12, EVOKER = 13,
}
local RECENT_LOCAL_WINDOW = 8
local NOTE_TAGS = {
    { id = "KILL", label = "Kill" },
    { id = "SUBDUE", label = "Subdue" },
    { id = "PEEL", label = "Peel" },
    { id = "SPINNER", label = "Spinner" },
    { id = "CARRIER", label = "Carrier" },
    { id = "AVOID_TUNNEL", label = "Avoid Tunnel" },
}
EnemyIntel.noteTags = NOTE_TAGS

local function validTag(id)
    id = KWR.Util:Upper(id, "", 32)
    for _, tag in ipairs(NOTE_TAGS) do
        if tag.id == id then return tag end
    end
end

local function normalizeTags(tags)
    local result = {}
    if type(tags) == "table" then
        for key, value in pairs(tags) do
            local tag = value == true and validTag(key) or validTag(value)
            if tag then result[tag.id] = true end
        end
    end
    return result
end

local function tagSummary(tags)
    tags = normalizeTags(tags)
    local labels = {}
    for _, tag in ipairs(NOTE_TAGS) do
        if tags[tag.id] == true then labels[#labels + 1] = tag.label end
    end
    return #labels > 0 and table.concat(labels, ", ") or "No tags"
end

local function hasTags(tags)
    for _ in pairs(normalizeTags(tags)) do return true end
    return false
end

local function liveClassID(unit)
    if type(UnitClassBase) == "function" then
        local _, classID = KWR.Util:Call(UnitClassBase, unit)
        classID = KWR.Util:Number(classID, nil)
        if classID then return classID end
    end
    local _, classFile = KWR.Util:UnitClass(unit)
    return CLASS_ID[classFile]
end

function EnemyIntel:ResolveLiveRecord(unit, safeName, safeGUID)
    if safeGUID and safeGUID ~= "" and self.records[safeGUID] then
        return self.records[safeGUID]
    end
    if safeName and safeName ~= "" then
        local full = KWR.Util:CanonicalName(safeName)
        for _, record in pairs(self.records) do
            local recordName = KWR.Util:Text(record.name, "", 64)
            if KWR.Util:CanonicalName(recordName) == full then
                return record
            end
        end
    end
    local classID = liveClassID(unit)
    if not classID then return nil end
    local candidates = {}
    for _, record in pairs(self.records) do
        if CLASS_ID[record.classFile] == classID then candidates[#candidates + 1] = record end
    end
    if #candidates == 1 then return candidates[1] end
    if #candidates == 0 then return nil end

    local race = KWR.Util:Text(KWR.Util:Call(UnitRace, unit), "", 32)
    if race ~= "" then
        local filtered = {}
        for _, record in ipairs(candidates) do
            if record.raceName == race then filtered[#filtered + 1] = record end
        end
        if #filtered == 1 then return filtered[1] end
        if #filtered > 1 then candidates = filtered end
    end
    local gender = type(UnitSexBase) == "function"
        and KWR.Util:Number(KWR.Util:Call(UnitSexBase, unit), nil) or nil
    if gender ~= nil then
        local filtered = {}
        for _, record in ipairs(candidates) do
            if record.gender == gender then filtered[#filtered + 1] = record end
        end
        if #filtered == 1 then return filtered[1] end
        if #filtered > 1 then candidates = filtered end
    end
    local honor = type(UnitHonorLevel) == "function"
        and KWR.Util:Number(KWR.Util:Call(UnitHonorLevel, unit), nil) or nil
    if honor and honor > 0 then
        local filtered = {}
        for _, record in ipairs(candidates) do
            if record.honorLevel == honor then filtered[#filtered + 1] = record end
        end
        if #filtered == 1 then return filtered[1] end
    end
    return nil
end

function EnemyIntel:PruneFriendlyRoster(roster)
    local friendlyKeys, friendlyGuids, friendlyNames = friendlyIdentityMaps(roster)
    for key, record in pairs(self.records) do
        local recordKey = KWR.Util:Text(record.key, key, 96)
        local recordGuid = KWR.Util:Text(record.guid, "", 96)
        local recordName = KWR.Util:Text(record.name, "", 64)
        local isFriendly = (recordKey ~= "" and friendlyKeys[recordKey] == true)
            or (recordGuid ~= "" and friendlyGuids[recordGuid] == true)
            or (recordName ~= "" and friendlyNames[KWR.Util:CanonicalName(recordName)] == true)
        if isFriendly then
            self.records[key] = nil
        end
    end
end

local function nearestLocation(mapID, x, y)
    local definition = KWR.Maps:Resolve(mapID, "")
    local best, bestDistance
    for label, position in pairs(definition and definition.positions or {}) do
        local px = KWR.Util:Number(position[1], nil)
        local py = KWR.Util:Number(position[2], nil)
        if px and py and x and y then
            local dx, dy = px - x, py - y
            local distance = (dx * dx) + (dy * dy)
            if not bestDistance or distance < bestDistance then
                best, bestDistance = label, distance
            end
        end
    end
    return best
end

local function sourceUnitForTarget(unit)
    local source = unit and unit:match("^(raid%d+)target$")
        or (unit and unit:match("^(party%d+)target$"))
    if source then return source end
    local raidPet = unit and unit:match("^raidpet(%d+)target$")
    if raidPet then return "raid" .. raidPet end
    local partyPet = unit and unit:match("^partypet(%d+)target$")
    if partyPet then return "party" .. partyPet end
end

local function usableLocation(location)
    location = KWR.Util:Text(location, "", 48)
    return location ~= "" and location ~= "Formation"
        and location ~= "Position restricted"
        and location ~= "Unknown"
        and location ~= "Unassigned"
        and location ~= "Team Engagement"
        and location ~= "Team Position"
        and location ~= "Team Assignment"
end

local function recentAt(now, timestamp)
    timestamp = KWR.Util:Number(timestamp, nil)
    return timestamp ~= nil and math.max(0, now - timestamp) <= RECENT_LOCAL_WINDOW
end

function friendlyIdentityMaps(roster)
    local friendlyKeys, friendlyGuids, friendlyNames = {}, {}, {}
    for _, player in ipairs(roster or {}) do
        local key = KWR.Util:Text(player.key, "", 96)
        local guid = KWR.Util:Text(player.guid, "", 96)
        local name = KWR.Util:Text(player.name, "", 64)
        if key ~= "" then friendlyKeys[key] = true end
        if guid ~= "" then friendlyGuids[guid] = true end
        if name ~= "" then friendlyNames[KWR.Util:CanonicalName(name)] = true end
    end
    return friendlyKeys, friendlyGuids, friendlyNames
end

local function publishedTruthScore(enemy)
    local score = 0
    if enemy.visible == true then score = score + 100 end
    if enemy.localEngaged == true then score = score + 80 end
    if enemy.localRange == true then score = score + 50 end
    if KWR.Util:Text(enemy.unit, "", 24) ~= "" then
        score = score + 40
    end
    if KWR.Util:Text(enemy.guid, "", 96) ~= "" then
        score = score + 25
    end
    if KWR.Util:Text(enemy.key, "", 96) ~= "" then
        score = score + 15
    end
    if enemy.healthPercent ~= nil or enemy.healthMax ~= nil then
        score = score + 10
    end
    if enemy.spec and enemy.spec ~= ""
        and enemy.spec ~= "Unknown" then
        score = score + 5
    end
    if enemy.age ~= nil then
        score = score + math.max(0, 5 - math.min(5, enemy.age))
    end
    return score
end

function EnemyIntel:FilterPublishedTruth(
    roster, enemies, friendlyScoreFaction)
    local friendlyKeys, friendlyGuids, friendlyNames =
        friendlyIdentityMaps(roster)
    friendlyScoreFaction =
        KWR.Util:Number(friendlyScoreFaction, nil)
    local aliasIndex = {}
    local filtered = {}

    for _, enemy in ipairs(enemies or {}) do
        local key = KWR.Util:Text(enemy.key, "", 96)
        local guid = KWR.Util:Text(enemy.guid, "", 96)
        local name = KWR.Util:CanonicalName(
            enemy.name or enemy.shortName)
        local faction = KWR.Util:Number(enemy.faction, nil)
        local aliases = {}
        if key ~= "" then
            aliases[#aliases + 1] = "KEY:" .. key
        end
        if guid ~= "" then
            aliases[#aliases + 1] = "GUID:" .. guid
        end
        if name ~= "" then
            aliases[#aliases + 1] = "NAME:" .. name
        end
        local isFriendly =
            (key ~= "" and friendlyKeys[key] == true)
            or (guid ~= "" and friendlyGuids[guid] == true)
            or (name ~= "" and friendlyNames[name] == true)
            or (friendlyScoreFaction ~= nil and faction ~= nil
                and faction == friendlyScoreFaction)
        if not isFriendly and #aliases > 0 then
            local index
            for _, alias in ipairs(aliases) do
                if aliasIndex[alias] then
                    index = aliasIndex[alias]
                    break
                end
            end
            if not index then
                index = #filtered + 1
                filtered[index] = enemy
            elseif publishedTruthScore(enemy)
                > publishedTruthScore(filtered[index]) then
                filtered[index] = enemy
            end
            for _, alias in ipairs(aliases) do
                aliasIndex[alias] = index
            end
        end
    end
    return filtered
end

local function engagementContext(sourceUnit, mapID)
    if not sourceUnit then return nil end
    local sourceName = KWR.Util:UnitName(sourceUnit)
    local state = KWR.Store and KWR.Store:Get()
    local definition = KWR.Maps:Resolve(mapID, "")
    local context = state and state.snapshot and state.snapshot.context
    if not state or not context or not definition
        or context.mapKey ~= definition.key then return nil end
    local result = {
        unit = sourceUnit,
        name = sourceName,
    }
    for _, player in ipairs(state.snapshot.roster or {}) do
        if player.unit == sourceUnit
            or (sourceName and KWR.Util:CanonicalName(player.name) == KWR.Util:CanonicalName(sourceName)) then
            if usableLocation(player.location)
                and player.locationSource == "Friendly Map Position" then
                result.location = player.location
                result.locationSource = "Team Position"
                result.inferred = true
            end
            break
        end
    end
    for _, assignment in ipairs(state.assignments or {}) do
        if sourceName and KWR.Util:CanonicalName(assignment.name) == KWR.Util:CanonicalName(sourceName) then
            result.role = assignment.role
            result.assignmentLocation = usableLocation(assignment.location)
                and assignment.location or nil
            if not result.location and result.assignmentLocation then
                result.location = result.assignmentLocation
                result.locationSource = "Team Assignment"
                result.inferred = true
            end
            break
        end
    end
    return result
end

local function mapPosition(mapID, unit)
    if not mapID or not unit or not C_Map
        or type(C_Map.GetPlayerMapPosition) ~= "function" then return nil, nil end
    local position = KWR.Util:Call(C_Map.GetPlayerMapPosition, mapID, unit)
    if not position or KWR.Util:IsSecret(position) then return nil, nil end
    local getter
    local ok = pcall(function() getter = position.GetXY end)
    if not ok or type(getter) ~= "function" then return nil, nil end
    local x, y = KWR.Util:Call(getter, position)
    return KWR.Util:Number(x, nil), KWR.Util:Number(y, nil)
end

function EnemyIntel:Reset(sessionKey)
    self.records = {}
    self.sessionKey = sessionKey
    self.friendlyScoreFaction = nil
    self.observedTokens = {}
end

function EnemyIntel:ObserveToken(unit, source)
    unit = KWR.Util:Text(unit, "", 32)
    if unit == "" then return end
    self.observedTokens[unit] = KWR.Util:Text(source, "Observed Unit", 32)
end

function EnemyIntel:ForgetToken(unit)
    unit = KWR.Util:Text(unit, "", 32)
    if unit ~= "" then self.observedTokens[unit] = nil end
end

function EnemyIntel:Upsert(data, visible)
    local name = KWR.Util:Text(data.name, "", 48)
    if name == "" then return end
    local guid = KWR.Util:Text(data.guid, "", 80)
    local key = keyFor(guid, name)
    local nameRecordKey = keyFor(nil, name)
    local record = self.records[key] or self.records[nameRecordKey]
    if not record then
        local wanted = KWR.Util:CanonicalName(name)
        local wantedClass = KWR.Util:Upper(data.classFile, "", 24)
        local candidate, candidates = nil, 0
        for existingKey, existing in pairs(self.records) do
            local existingName = KWR.Util:Text(existing.name, "", 48)
            local sameName = KWR.Util:CanonicalName(existingName) == wanted
            local existingClass = KWR.Util:Upper(existing.classFile, "", 24)
            local classCompatible = wantedClass == "" or existingClass == ""
                or wantedClass == existingClass
            if sameName and classCompatible then
                candidate, nameRecordKey = existing, existingKey
                candidates = candidates + 1
            end
        end
        if candidates == 1 then record = candidate end
    end
    record = record or {
        key = key,
        firstKnownAt = KWR.Util:Now(),
        priority = 0,
    }
    if guid ~= "" and record.key ~= key then
        local previousKey = record.key or nameRecordKey
        self.records[previousKey] = nil
        if KWR.db and KWR.db.enemyNotes and KWR.db.enemyNotes[previousKey]
            and not KWR.db.enemyNotes[key] then
            KWR.db.enemyNotes[key] = KWR.db.enemyNotes[previousKey]
            KWR.db.enemyNotes[previousKey] = nil
        end
        record.key = key
    end
    record.name = name
    record.shortName = KWR.Util:ShortName(name)
    record.guid = guid ~= "" and guid or record.guid
    record.class = KWR.Util:Text(data.class, record.class or "Unknown", 32)
    record.classFile = KWR.Util:Upper(data.classFile, record.classFile or "UNKNOWN", 24)
    record.faction = KWR.Util:Number(data.faction, record.faction)
    record.spec = KWR.Util:Text(data.spec, record.spec or "Unknown", 32)
    if record.spec ~= "Unknown" then
        record.specSource = KWR.Util:Text(data.specSource,
            data.source == "Scoreboard" and "scoreboard" or record.specSource or "observed", 24)
    end
    record.role = KWR.CombatSpells:Role(record.spec, data.role or record.role)
    record.raceName = KWR.Util:Text(data.raceName, record.raceName or "", 32)
    record.honorLevel = KWR.Util:Number(data.honorLevel, record.honorLevel)
    record.gender = KWR.Util:Number(data.gender, record.gender)
    record.source = KWR.Util:Text(data.source, record.source or "Roster", 32)
    record.dead = KWR.Util:Boolean(data.dead, record.dead)
    record.rosterKnown = true
    record.rosterAt = KWR.Util:Now()
    if visible then
        local seenAt = KWR.Util:Now()
        record.lastSeenAt = seenAt
        record.visibleAt = seenAt
        record.visible = true
        record.health = KWR.Util:Number(data.health, record.health)
        record.healthMax = KWR.Util:Number(data.healthMax, record.healthMax)
        if record.health and record.healthMax and record.healthMax > 0 then
            record.lastHealthPercent = KWR.Util:Clamp(
                (record.health / record.healthMax) * 100, 0, 100)
        end
        record.x = KWR.Util:Number(data.x, record.x)
        record.y = KWR.Util:Number(data.y, record.y)
        record.location = KWR.Util:Text(data.location, "", 40)
        record.locationSource = KWR.Util:Text(data.locationSource, record.locationSource or data.source, 32)
        record.locationInferred = data.locationInferred == true
        record.coordinateProvenance = KWR.Util:Text(
            data.coordinateProvenance, record.coordinateProvenance or "", 48)
        record.engagementUnit = KWR.Util:Text(
            data.engagementUnit, record.engagementUnit, 24)
        record.engagementPlayer = KWR.Util:Text(
            data.engagementPlayer, record.engagementPlayer, 64)
        record.engagementRole = KWR.Util:Text(
            data.engagementRole, record.engagementRole, 48)
        record.lastSeenLocation = record.location
        record.lastSeenLocationSource = record.locationSource
        record.lastSeenLocationInferred = record.locationInferred
        record.lastSeenEngagementPlayer = record.engagementPlayer
        record.lastSeenEngagementRole = record.engagementRole
        record.lastSeenX = record.x
        record.lastSeenY = record.y
        record.unit = KWR.Util:Text(data.unit, record.unit or "", 24)
        record.localRange = data.localRange == true
        record.localEngaged = data.localEngaged == true
        if record.localRange then record.lastLocalRangeAt = seenAt end
        if record.localEngaged then record.lastLocalEngagedAt = seenAt end
        record.inCombat = KWR.Util:Boolean(data.inCombat, record.inCombat)
    end
    local legacyShortKey = KWR.Util:LegacyShortKey(name)
    local note = KWR.db and KWR.db.enemyNotes and (
        KWR.db.enemyNotes[key]
        or KWR.db.enemyNotes[nameRecordKey]
        or (legacyShortKey and KWR.db.enemyNotes[legacyShortKey] or nil)
    )
    record.priority = note and KWR.Util:Number(note.priority, record.priority) or record.priority
    record.note = note and KWR.Util:Text(note.text, "", 80) or record.note
    record.noteTags = note and normalizeTags(note.tags) or record.noteTags
    record.noteTagSummary = tagSummary(record.noteTags)
    local r, g, b = classColor(record.classFile)
    record.r, record.g, record.b = r, g, b
    self.records[record.key] = record
end

function EnemyIntel:ScanScoreboard(assigned, rows, roster)
    if assigned and assigned.scoreFaction ~= nil then
        if self.friendlyScoreFaction ~= nil
            and self.friendlyScoreFaction ~= assigned.scoreFaction then
            self.records = {}
        end
        self.friendlyScoreFaction = assigned.scoreFaction
    end
    if self.friendlyScoreFaction == nil then
        local playerGUID, playerName = "", ""
        for _, player in ipairs(roster or {}) do
            if player.unit == "player" then
                playerGUID = KWR.Util:Text(player.guid, "", 80)
                playerName = KWR.Util:CanonicalName(player.name)
                break
            end
        end
        for _, row in ipairs(rows or {}) do
            local rowGuid = KWR.Util:Text(row.guid, "", 80)
            local rowName = KWR.Util:CanonicalName(row.name)
            local isPlayer = (playerGUID ~= "" and rowGuid ~= "" and rowGuid == playerGUID)
                or (playerName ~= "" and rowName == playerName)
            if isPlayer and row.faction ~= nil then
                self.friendlyScoreFaction = row.faction
                break
            end
        end
    end
    local _, friendlyGuids, friendlyNames =
        friendlyIdentityMaps(roster)
    if self.friendlyScoreFaction == nil then return end
    for _, row in ipairs(rows or {}) do
        local rowGuid = KWR.Util:Text(row.guid, "", 80)
        local rowName = KWR.Util:Text(row.name, "", 64)
        local isFriendly = (rowGuid ~= "" and friendlyGuids[rowGuid] == true)
            or (rowName ~= "" and friendlyNames[KWR.Util:CanonicalName(rowName)] == true)
        if row.faction ~= self.friendlyScoreFaction and not isFriendly then
            row.source = "Scoreboard"
            self:Upsert(row, false)
        end
    end
end

function EnemyIntel:ScanUnit(unit, mapID, source)
    if not KWR.Util:Boolean(KWR.Util:Call(UnitExists, unit), false) then return end
    if type(UnitIsFriend) == "function"
        and KWR.Util:Boolean(KWR.Util:Call(UnitIsFriend, "player", unit), false) then return end
    local name = KWR.Util:UnitName(unit)
    local localizedClass, classFile = KWR.Util:UnitClass(unit)
    local health = KWR.Util:Number(KWR.Util:Call(UnitHealth, unit), nil)
    local healthMax = KWR.Util:Number(KWR.Util:Call(UnitHealthMax, unit), nil)
    local guid = KWR.Util:Text(KWR.Util:Call(UnitGUID, unit), "", 80)
    local matched = self:ResolveLiveRecord(unit, name, guid)
    if matched then
        name = matched.name
        guid = KWR.Util:Text(matched.guid, guid, 80)
        localizedClass = matched.class or localizedClass
        classFile = matched.classFile or classFile
    elseif name == "" then
        return
    end
    local localRange = false
    if type(CheckInteractDistance) == "function" then
        for index = 1, 4 do
            if KWR.Util:Boolean(KWR.Util:Call(CheckInteractDistance, unit, index), false) then
                localRange = true
                break
            end
        end
    end
    if not localRange and C_Item and type(C_Item.IsItemInRange) == "function" then
        localRange = KWR.Util:Boolean(KWR.Util:Call(C_Item.IsItemInRange, 140786, unit), false)
    end
    local x, y = mapPosition(mapID, unit)
    local locationSource = source
    local locationInferred = false
    local coordinateProvenance = (x and y) and "observed_enemy_unit" or nil
    local engagement
    if not x or not y then
        local sourceUnit = sourceUnitForTarget(unit)
        if not sourceUnit and (source == "Target" or source == "Focus"
            or source == "Mouseover" or source == "Soft Target"
            or source == "Nameplate" or unit:find("^nameplate")) then
            sourceUnit = "player"
        end
        if sourceUnit then
            engagement = engagementContext(sourceUnit, mapID)
            if engagement and engagement.location then
                locationSource = engagement.locationSource
                locationInferred = engagement.inferred == true
            else
                locationSource = "Team Engagement"
            end
        end
    end
    local location = nearestLocation(mapID, x, y)
    if not location and engagement and engagement.location then
        location = engagement.location
    end
    self:Upsert({
        name = name,
        guid = guid,
        class = localizedClass,
        classFile = classFile,
        source = source,
        location = location,
        locationSource = locationSource,
        locationInferred = locationInferred,
        coordinateProvenance = coordinateProvenance,
        engagementUnit = engagement and engagement.unit,
        engagementPlayer = engagement and engagement.name,
        engagementRole = engagement and engagement.role,
        health = health,
        healthMax = healthMax,
        dead = KWR.Util:Call(UnitIsDeadOrGhost, unit),
        inCombat = KWR.Util:Call(UnitAffectingCombat, unit),
        x = x,
        y = y,
        unit = unit,
        localRange = localRange,
        localEngaged = KWR.Util:Boolean(KWR.Util:Call(UnitAffectingCombat, unit), false)
            and (localRange or source == "Target" or source == "Focus"
                or source == "Soft Target" or source == "Nameplate"
                or unit:find("^nameplate") ~= nil),
        spec = matched and matched.spec or nil,
        specSource = matched and matched.specSource or nil,
        role = matched and matched.role or nil,
        raceName = matched and matched.raceName or nil,
        honorLevel = matched and matched.honorLevel or nil,
        gender = matched and matched.gender or nil,
    }, true)
end

function EnemyIntel:Rows()
    local now, result = KWR.Util:Now(), {}
    for _, record in pairs(self.records) do
        local copy = KWR.Util:Copy(record)
        copy.age = copy.lastSeenAt and math.max(0, now - copy.lastSeenAt) or nil
        copy.lastLocalRangeAge = copy.lastLocalRangeAt
            and math.max(0, now - copy.lastLocalRangeAt) or nil
        copy.lastLocalEngagedAge = copy.lastLocalEngagedAt
            and math.max(0, now - copy.lastLocalEngagedAt) or nil
        copy.recentLocalRange = recentAt(now, copy.lastLocalRangeAt)
        copy.recentLocalEngaged = recentAt(now, copy.lastLocalEngagedAt)
        copy.locationState = self:LocationState(copy)
        if copy.locationState == "LAST SEEN" then
            copy.location = copy.lastSeenLocation or copy.location
            copy.locationSource = copy.lastSeenLocationSource or copy.locationSource
            copy.locationInferred = copy.lastSeenLocationInferred == true
            copy.engagementPlayer = copy.lastSeenEngagementPlayer
                or copy.engagementPlayer
            copy.engagementRole = copy.lastSeenEngagementRole
                or copy.engagementRole
            copy.x = copy.lastSeenX or copy.x
            copy.y = copy.lastSeenY or copy.y
        end
        copy.locationText = self:LocationPrefix(copy)
            .. (copy.location and (" @ " .. copy.location) or "")
        copy.healthPercent = copy.visible and copy.health and copy.healthMax and copy.healthMax > 0
            and KWR.Util:Clamp((copy.health / copy.healthMax) * 100, 0, 100) or nil
        copy.healthEvidence = copy.healthPercent and "LIVE"
            or (copy.lastHealthPercent and "LAST_SEEN" or "UNAVAILABLE")
        if KWR.OpponentModels and KWR.OpponentModels.Describe then
            copy.profile = KWR.OpponentModels:Describe(copy)
            copy.noteDetail = copy.profile and copy.profile.noteSummary or nil
        end
        copy.noteTags = normalizeTags(copy.noteTags
            or (KWR.db.enemyNotes and KWR.db.enemyNotes[copy.key]
                and KWR.db.enemyNotes[copy.key].tags))
        copy.noteTagSummary = tagSummary(copy.noteTags)
        result[#result + 1] = copy
    end
    table.sort(result, function(a, b)
        if (a.priority or 0) ~= (b.priority or 0) then return (a.priority or 0) > (b.priority or 0) end
        if a.visible ~= b.visible then return a.visible == true end
        return (a.lastSeenAt or 0) > (b.lastSeenAt or 0)
    end)
    return result
end

function EnemyIntel:LocationState(record)
    if not record then return "ROSTER" end
    local age = KWR.Util:Number(record.age, nil)
    if record.visible and (record.localEngaged == true or record.inCombat == true) then
        return "ENGAGED"
    end
    if record.visible and record.localRange == true then
        return "LOCAL"
    end
    if record.visible then
        return "VISIBLE"
    end
    if record.lastSeenAt or (age and age > 0) then
        return "LAST SEEN"
    end
    return "ROSTER"
end

function EnemyIntel:LocationPrefix(record)
    local state = self:LocationState(record)
    if state == "LAST SEEN" then
        return "LAST " .. KWR.Util:Age(record and record.age or 0)
    end
    return state
end

function EnemyIntel:DescribeLocation(record, mapKey, compact)
    if not record then return "ROSTER" end
    local state = self:LocationState(record)
    local prefix = self:LocationPrefix(record)
    local location = usableLocation(record.location)
        and KWR.Maps:AbbreviateLocation(mapKey, record.location) or nil
    local teamEvidence = record.locationInferred == true
        or record.locationSource == "Team Engagement"
        or record.locationSource == "Team Position"
        or record.locationSource == "Team Assignment"
    if teamEvidence then
        local role = KWR.Util:Text(record.engagementRole, "Team", 48)
        if compact and KWR.Assignments then
            local assignmentLabel = KWR.Assignments:CompactLabel({
                role = role,
                location = location and record.location or nil,
            }, mapKey)
            if state == "ENGAGED" then
                return "ENGAGED WITH " .. assignmentLabel
            end
            if state == "LOCAL" or state == "VISIBLE" then
                return "SEEN WITH " .. assignmentLabel
            end
            if state == "LAST SEEN" then
                return "LAST " .. KWR.Util:Age(record and record.age or 0)
                    .. " WITH " .. assignmentLabel
            end
            return prefix .. " WITH " .. assignmentLabel
        else
            role = role:upper()
        end
        if location then
            return prefix .. " @ " .. location .. " | " .. role
        end
        return prefix .. " | " .. role
    end
    if compact then
        if state == "ENGAGED" then
            return location and ("ENGAGED " .. location) or "ENGAGED"
        end
        if state == "LOCAL" or state == "VISIBLE" then
            return location and ("SEEN " .. location) or "SEEN"
        end
        if state == "LAST SEEN" then
            return "LAST " .. KWR.Util:Age(record and record.age or 0)
                .. (location and (" " .. location) or "")
        end
    end
    return prefix .. (location and (" @ " .. location) or "")
end

function EnemyIntel:Capture(context, roster, assigned, scoreboardRows)
    context = context or {}
    local mapID = context.mapID
    if not context.inPvP then
        if self.sessionKey ~= nil then self:Reset(nil) end
        return {}
    end
    local sessionKey = KWR.Util:BattlefieldSessionKey(context)
    if self.sessionKey ~= sessionKey then self:Reset(sessionKey) end
    self:PruneFriendlyRoster(roster)
    for _, record in pairs(self.records) do
        record.visible = false
        record.localRange = false
        record.localEngaged = false
        record.unit = nil
    end

    self:ScanScoreboard(assigned, scoreboardRows, roster)
    self:ScanUnit("target", mapID, "Target")
    self:ScanUnit("focus", mapID, "Focus")
    self:ScanUnit("mouseover", mapID, "Mouseover")
    self:ScanUnit("softenemy", mapID, "Soft Target")
    self:ScanUnit("pettarget", mapID, "Pet Target")
    self:ScanUnit("targettarget", mapID, "Target Target")
    self:ScanUnit("focustarget", mapID, "Focus Target")
    self:ScanUnit("mouseovertarget", mapID, "Mouseover Target")
    for index = 1, 5 do
        self:ScanUnit("arena" .. index, mapID, "Arena Token")
        self:ScanUnit("boss" .. index, mapID, "Objective Unit")
    end
    for unit, source in pairs(self.observedTokens) do
        self:ScanUnit(unit, mapID, source)
    end
    self:PruneFriendlyRoster(roster)
    return self:Rows()
end

function EnemyIntel:SetPriority(key, priority)
    local record = self.records[key]
    if not record then return end
    priority = KWR.Util:Clamp(priority, 0, 3)
    KWR.db.enemyNotes[key] = KWR.db.enemyNotes[key] or {}
    KWR.db.enemyNotes[key].priority = priority
    KWR.db.enemyNotes[key].updatedAt = KWR.Util:Now()
    record.priority = priority
end

function EnemyIntel:CyclePriority(key)
    local record = self.records[key]
    if not record then return end
    self:SetPriority(key, ((record.priority or 0) + 1) % 4)
end

function EnemyIntel:SetNote(key, note)
    local record = self.records[key]
    if not record then return end
    KWR.db.enemyNotes[key] = KWR.db.enemyNotes[key] or {}
    KWR.db.enemyNotes[key].text = KWR.Util:Text(note, "", 80)
    KWR.db.enemyNotes[key].updatedAt = KWR.Util:Now()
    record.note = KWR.db.enemyNotes[key].text
end

function EnemyIntel:SetNoteTag(key, tagID, enabled)
    local record = self.records[key]
    if not record then return end
    local tag = validTag(tagID)
    if not tag then return end
    KWR.db.enemyNotes[key] = KWR.db.enemyNotes[key] or {}
    KWR.db.enemyNotes[key].tags = normalizeTags(KWR.db.enemyNotes[key].tags)
    if enabled == false then
        KWR.db.enemyNotes[key].tags[tag.id] = nil
    else
        KWR.db.enemyNotes[key].tags[tag.id] = true
    end
    KWR.db.enemyNotes[key].updatedAt = KWR.Util:Now()
    record.noteTags = normalizeTags(KWR.db.enemyNotes[key].tags)
    record.noteTagSummary = tagSummary(record.noteTags)
end

function EnemyIntel:ToggleNoteTag(key, tagID)
    local note = KWR.db.enemyNotes and KWR.db.enemyNotes[key] or nil
    local tags = normalizeTags(note and note.tags)
    local tag = validTag(tagID)
    if not tag then return end
    self:SetNoteTag(key, tag.id, tags[tag.id] ~= true)
end

function EnemyIntel:NoteTags(key)
    local record = self.records[key]
    local note = KWR.db.enemyNotes and KWR.db.enemyNotes[key] or nil
    return normalizeTags(record and record.noteTags or note and note.tags)
end

function EnemyIntel:NoteTagSummary(key)
    return tagSummary(self:NoteTags(key))
end

function EnemyIntel:PruneNotes()
    KWR.db.enemyNotes = type(KWR.db.enemyNotes) == "table" and KWR.db.enemyNotes or {}
    local rows = {}
    for key, note in pairs(KWR.db.enemyNotes) do
        local text = KWR.Util:Text(note and note.text, "", 80)
        local priority = KWR.Util:Number(note and note.priority, 0) or 0
        if text == "" and priority == 0 and not hasTags(note and note.tags) then
            KWR.db.enemyNotes[key] = nil
        else
            rows[#rows + 1] = {
                key = key,
                at = KWR.Util:Number(note and note.updatedAt, 0) or 0,
                priority = priority,
            }
        end
    end
    table.sort(rows, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        if a.at ~= b.at then return a.at > b.at end
        return a.key < b.key
    end)
    for index = self.maxNotes + 1, #rows do
        KWR.db.enemyNotes[rows[index].key] = nil
    end
end

function EnemyIntel:OnInitialize()
    if KWR.MemoryBudget then
        KWR.MemoryBudget:Bind(self, "EnemyIntel")
    end
    KWR.db.enemyNotes = type(KWR.db.enemyNotes) == "table" and KWR.db.enemyNotes or {}
    self:PruneNotes()
end

KWR:RegisterModule("EnemyIntel", EnemyIntel)