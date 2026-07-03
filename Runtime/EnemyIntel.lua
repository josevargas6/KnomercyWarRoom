local _, KWR = ...

local EnemyIntel = {
    records = {},
    sessionKey = nil,
    observedTokens = {},
}
KWR.EnemyIntel = EnemyIntel

local function keyFor(guid, name)
    return guid and guid ~= "" and guid or ("NAME:" .. string.lower(name or "unknown"))
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
        local full = safeName:lower()
        local short = KWR.Util:ShortName(safeName):lower()
        for _, record in pairs(self.records) do
            local recordName = KWR.Util:Text(record.name, "", 64)
            if recordName:lower() == full
                or KWR.Util:ShortName(recordName):lower() == short then
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
            or (sourceName and (player.name == sourceName
                or player.shortName == KWR.Util:ShortName(sourceName))) then
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
        if sourceName and (assignment.name == sourceName
            or assignment.shortName == KWR.Util:ShortName(sourceName)) then
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
        local wanted = name:lower()
        local wantedShort = KWR.Util:ShortName(name):lower()
        local wantedClass = KWR.Util:Upper(data.classFile, "", 24)
        local candidate, candidates = nil, 0
        for existingKey, existing in pairs(self.records) do
            local existingName = KWR.Util:Text(existing.name, "", 48)
            local sameName = existingName:lower() == wanted
                or KWR.Util:ShortName(existingName):lower() == wantedShort
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
        record.lastSeenAt = KWR.Util:Now()
        record.visibleAt = record.lastSeenAt
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
        record.inCombat = KWR.Util:Boolean(data.inCombat, record.inCombat)
    end
    local note = KWR.db and KWR.db.enemyNotes and KWR.db.enemyNotes[key]
    record.priority = note and KWR.Util:Number(note.priority, record.priority) or record.priority
    record.note = note and KWR.Util:Text(note.text, "", 80) or record.note
    local r, g, b = classColor(record.classFile)
    record.r, record.g, record.b = r, g, b
    self.records[record.key] = record
end

function EnemyIntel:ScanScoreboard(assigned, rows)
    if assigned and assigned.scoreFaction ~= nil then
        self.friendlyScoreFaction = assigned.scoreFaction
    end
    if self.friendlyScoreFaction == nil then return end
    for _, row in ipairs(rows or {}) do
        if row.faction ~= self.friendlyScoreFaction then
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
    if not matched then return end
    name = matched.name
    guid = KWR.Util:Text(matched.guid, guid, 80)
    localizedClass = matched.class or localizedClass
    classFile = matched.classFile or classFile
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
            x, y = mapPosition(mapID, sourceUnit)
            if x and y then
                locationSource = "Team Position"
                locationInferred = true
            elseif engagement and engagement.location then
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
        spec = matched.spec,
        role = matched.role,
        raceName = matched.raceName,
        honorLevel = matched.honorLevel,
        gender = matched.gender,
    }, true)
end

function EnemyIntel:Rows()
    local now, result = KWR.Util:Now(), {}
    for _, record in pairs(self.records) do
        local copy = KWR.Util:Copy(record)
        copy.age = copy.lastSeenAt and math.max(0, now - copy.lastSeenAt) or nil
        if copy.visible then
            copy.locationState = "VISIBLE"
        elseif copy.lastSeenAt then
            copy.locationState = "LAST SEEN"
            copy.location = copy.lastSeenLocation or copy.location
            copy.locationSource = copy.lastSeenLocationSource or copy.locationSource
            copy.locationInferred = copy.lastSeenLocationInferred == true
            copy.engagementPlayer = copy.lastSeenEngagementPlayer
                or copy.engagementPlayer
            copy.engagementRole = copy.lastSeenEngagementRole
                or copy.engagementRole
            copy.x = copy.lastSeenX or copy.x
            copy.y = copy.lastSeenY or copy.y
        else
            copy.locationState = "ROSTER"
        end
        copy.locationText = copy.locationState
            .. (copy.location and (" @ " .. copy.location) or "")
        copy.healthPercent = copy.visible and copy.health and copy.healthMax and copy.healthMax > 0
            and KWR.Util:Clamp((copy.health / copy.healthMax) * 100, 0, 100) or nil
        copy.healthEvidence = copy.healthPercent and "LIVE"
            or (copy.lastHealthPercent and "LAST_SEEN" or "UNAVAILABLE")
        result[#result + 1] = copy
    end
    table.sort(result, function(a, b)
        if (a.priority or 0) ~= (b.priority or 0) then return (a.priority or 0) > (b.priority or 0) end
        if a.visible ~= b.visible then return a.visible == true end
        return (a.lastSeenAt or 0) > (b.lastSeenAt or 0)
    end)
    return result
end

function EnemyIntel:DescribeLocation(record, mapKey, compact)
    if not record then return "ROSTER" end
    local prefix
    if record.visible and record.inCombat then
        prefix = "ENGAGED"
    elseif record.visible then
        prefix = "VISIBLE"
    elseif record.age then
        prefix = "LAST " .. KWR.Util:Age(record.age)
    else
        prefix = "ROSTER"
    end
    local location = usableLocation(record.location)
        and KWR.Maps:AbbreviateLocation(mapKey, record.location) or nil
    local teamEvidence = record.locationInferred == true
        or record.locationSource == "Team Engagement"
        or record.locationSource == "Team Position"
        or record.locationSource == "Team Assignment"
    if teamEvidence then
        local role = KWR.Util:Text(record.engagementRole, "Team", 48)
        if compact and KWR.Assignments then
            role = KWR.Assignments:CompactRole(role)
        else
            role = role:upper()
        end
        return prefix .. " WITH " .. role
            .. (location and (" -> " .. location) or "")
    end
    return prefix .. (location and (" @ " .. location) or "")
end

function EnemyIntel:Capture(mapID, inPvP, roster, assigned, scoreboardRows)
    if not inPvP then
        if self.sessionKey ~= nil then self:Reset(nil) end
        return {}
    end
    local sessionKey = tostring(mapID or "unknown")
    if self.sessionKey ~= sessionKey then self:Reset(sessionKey) end
    for _, record in pairs(self.records) do
        record.visible = false
        record.localRange = false
        record.localEngaged = false
        record.unit = nil
    end

    self:ScanScoreboard(assigned, scoreboardRows)
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
    return self:Rows()
end

function EnemyIntel:SetPriority(key, priority)
    local record = self.records[key]
    if not record then return end
    priority = KWR.Util:Clamp(priority, 0, 3)
    KWR.db.enemyNotes[key] = KWR.db.enemyNotes[key] or {}
    KWR.db.enemyNotes[key].priority = priority
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
    record.note = KWR.db.enemyNotes[key].text
end

function EnemyIntel:OnInitialize()
    KWR.db.enemyNotes = type(KWR.db.enemyNotes) == "table" and KWR.db.enemyNotes or {}
end

KWR:RegisterModule("EnemyIntel", EnemyIntel)
