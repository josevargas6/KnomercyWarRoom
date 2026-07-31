local _, KWR = ...

local AssignmentOverrides = {}
KWR.AssignmentOverrides = AssignmentOverrides

local function now()
    return KWR.Util:Now()
end

local function clean(value, fallback, limit)
    return KWR.Util:Text(value, fallback, limit or 64)
end

local function canonicalID(name, guid)
    return KWR.Util:CanonicalPlayerKey(name, guid)
end

local function legacyKey(name)
    return KWR.Util:LegacyShortKey(name)
end

local function normalized(value)
    return clean(value, "", 64):lower():gsub("[^%w]", "")
end

local function db()
    KWR.db.assignmentOverrides = type(KWR.db.assignmentOverrides) == "table"
        and KWR.db.assignmentOverrides or {}
    KWR.db.assignmentOverrides.players =
        type(KWR.db.assignmentOverrides.players) == "table"
        and KWR.db.assignmentOverrides.players or {}
    KWR.db.assignmentOverrides.legacyPlayers =
        type(KWR.db.assignmentOverrides.legacyPlayers) == "table"
        and KWR.db.assignmentOverrides.legacyPlayers or {}
    KWR.db.assignmentOverrides.ambiguousLegacy =
        type(KWR.db.assignmentOverrides.ambiguousLegacy) == "table"
        and KWR.db.assignmentOverrides.ambiguousLegacy or {}
    return KWR.db.assignmentOverrides.players
end

local function storage()
    db()
    return KWR.db.assignmentOverrides
end

local function ensureRecord(name, guid)
    local players = db()
    local playerKey = canonicalID(name, guid)
    if not playerKey then return nil end
    players[playerKey] = players[playerKey] or {
        key = playerKey,
        name = clean(name, "Unknown", 64),
        guid = clean(guid, nil, 96),
        identity = playerKey,
        updatedAt = now(),
    }
    return players[playerKey]
end

local function resolveRecord(query)
    local players = db()
    local wantedID = canonicalID(query, nil)
    local wantedName = KWR.Util:CanonicalName(query)
    local wantedLegacy = legacyKey(query)
    local shortMatches = {}
    if wantedID and players[wantedID] then
        return players[wantedID]
    end
    for _, record in pairs(players) do
        if wantedName ~= "" and KWR.Util:CanonicalName(record.name) == wantedName then
            return record
        end
        if wantedLegacy and legacyKey(record.name) == wantedLegacy then
            shortMatches[#shortMatches + 1] = record
        end
    end
    if #shortMatches == 1 then return shortMatches[1] end
    if #shortMatches > 1 then return false, "AMBIGUOUS_SHORT_NAME" end
    if wantedLegacy then
        local legacy = storage().legacyPlayers[wantedLegacy]
        if legacy then return legacy end
    end
    return nil
end

local function currentMap(snapshot)
    return snapshot and snapshot.context and clean(snapshot.context.mapKey, "WORLD", 24)
end

local function resolveAssignment(assignments, query)
    local wantedID = canonicalID(query, nil)
    local wantedName = KWR.Util:CanonicalName(query)
    local wantedLegacy = legacyKey(query)
    local shortMatches = {}
    for _, assignment in ipairs(assignments or {}) do
        local assignmentID = canonicalID(assignment.name, assignment.guid)
        if wantedID and assignmentID == wantedID then
            return assignment
        end
        local assignmentName = KWR.Util:CanonicalName(assignment.name)
        if wantedName ~= "" and assignmentName == wantedName then return assignment end
        if wantedLegacy and legacyKey(assignment.name) == wantedLegacy then
            shortMatches[#shortMatches + 1] = assignment
        end
    end
    if #shortMatches == 1 then return shortMatches[1] end
    if #shortMatches > 1 then return false, "AMBIGUOUS_SHORT_NAME" end
end

local function knownLocations(snapshot, assignments)
    local result, seen = {}, {}
    local definition = KWR.Maps:Get(snapshot and snapshot.context and snapshot.context.mapKey)
    local function add(location)
        location = clean(location, nil, 64)
        if location and not seen[location] then
            seen[location] = true
            result[#result + 1] = location
        end
    end
    for _, location in ipairs(definition and definition.locations or {}) do add(location) end
    for _, location in ipairs(definition and definition.priorities or {}) do add(location) end
    for _, location in pairs(definition and definition.home or {}) do add(location) end
    for _, row in ipairs(snapshot and snapshot.objectives and snapshot.objectives.rows or {}) do
        add(row.label)
    end
    for _, assignment in ipairs(assignments or {}) do
        add(assignment.location)
    end
    return result
end

local function resolveLocation(snapshot, assignments, query)
    query = clean(query, "", 64)
    if query == "" then return nil end
    local wanted = normalized(query)
    local partial
    for _, location in ipairs(knownLocations(snapshot, assignments)) do
        local candidate = normalized(location)
        if candidate == wanted then return location end
        if candidate:find(wanted, 1, true) == 1
            or wanted:find(candidate, 1, true) == 1 then
            if partial and partial ~= location then return nil end
            partial = location
        end
    end
    return partial
end

local function activeLock(snapshot, entity)
    local profile = storage()
    local record = db()[canonicalID(entity and entity.name or entity, entity and entity.guid or nil)]
    if not record and entity and entity.name then
        local fallback = legacyKey(entity.name)
        record = fallback and profile.legacyPlayers[fallback] or nil
    end
    local lock = record and record.lock
    if not lock then return nil end
    if lock.mapKey ~= currentMap(snapshot) then return nil end
    return record, lock
end

local function formatLock(record, lock)
    local parts = {
        clean(record.shortName or record.name, "Unknown", 32),
        lock.role and ("role " .. clean(lock.role, "Unknown", 48)) or nil,
        lock.location and ("@ " .. clean(lock.location, "Unknown", 48)) or nil,
        "map " .. clean(lock.mapKey, "WORLD", 24),
    }
    local compact = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then compact[#compact + 1] = part end
    end
    return table.concat(compact, " | ")
end

local function copyLock(lock)
    if type(lock) ~= "table" then return nil end
    return {
        mapKey = clean(lock.mapKey, nil, 24),
        role = clean(lock.role, nil, 48),
        location = clean(lock.location, nil, 48),
        priority = KWR.Util:Number(lock.priority, 90) or 90,
        source = clean(lock.source, "LEGACY", 24),
        updatedAt = KWR.Util:Number(lock.updatedAt, now()) or now(),
    }
end

local function migrateLegacyForAssignment(assignment)
    local profile = storage()
    local fallback = legacyKey(assignment and assignment.name)
    if not fallback then return nil end
    local legacy = profile.legacyPlayers[fallback]
    if not legacy or not legacy.lock then return nil end
    local record = ensureRecord(assignment.name, assignment.guid)
    if not record then return nil end
    if not record.lock then
        record.lock = copyLock(legacy.lock)
    end
    record.name = clean(assignment.name, record.name, 64)
    record.shortName = clean(assignment.shortName or assignment.name, record.shortName, 32)
    record.guid = clean(assignment.guid, record.guid, 96)
    record.updatedAt = now()
    legacy.migratedTo = record.key
    legacy.updatedAt = record.updatedAt
    return record
end

function AssignmentOverrides:Pin(snapshot, assignments, query)
    local assignment, reason = resolveAssignment(assignments, query)
    if assignment == false and reason == "AMBIGUOUS_SHORT_NAME" then
        return false, "Override pin failed: short-name query matched multiple players. Use the full name."
    end
    if not assignment then
        return false, "Override pin failed: player assignment not found in the current plan."
    end
    local record = ensureRecord(assignment.name or query, assignment.guid)
    record.name = clean(assignment.name, record.name, 64)
    record.shortName = clean(assignment.shortName or assignment.name, record.shortName, 32)
    record.guid = clean(assignment.guid, record.guid, 96)
    record.identity = canonicalID(assignment.name, assignment.guid)
    record.lock = {
        mapKey = currentMap(snapshot),
        role = clean(assignment.role, nil, 48),
        location = clean(assignment.location, nil, 48),
        priority = KWR.Util:Number(assignment.priority, 90) or 90,
        source = "PIN",
        updatedAt = now(),
    }
    record.updatedAt = record.lock.updatedAt
    return true, "Pinned override: " .. formatLock(record, record.lock)
end

function AssignmentOverrides:SetLocation(snapshot, assignments, query, wantedLocation)
    local assignment, reason = resolveAssignment(assignments, query)
    if assignment == false and reason == "AMBIGUOUS_SHORT_NAME" then
        return false, "Override location failed: short-name query matched multiple players. Use the full name."
    end
    if not assignment then
        return false, "Override location failed: player assignment not found in the current plan."
    end
    local location = resolveLocation(snapshot, assignments, wantedLocation)
    if not location then
        return false, "Override location failed: location did not match a known battleground objective."
    end
    local record = ensureRecord(assignment.name or query, assignment.guid)
    record.name = clean(assignment.name, record.name, 64)
    record.shortName = clean(assignment.shortName or assignment.name, record.shortName, 32)
    record.guid = clean(assignment.guid, record.guid, 96)
    record.identity = canonicalID(assignment.name, assignment.guid)
    record.lock = record.lock or {}
    record.lock.mapKey = currentMap(snapshot)
    record.lock.role = record.lock.role or clean(assignment.role, nil, 48)
    record.lock.location = location
    record.lock.priority = math.max(
        KWR.Util:Number(record.lock.priority, 0) or 0,
        KWR.Util:Number(assignment.priority, 90) or 90)
    record.lock.source = "LOCATION"
    record.lock.updatedAt = now()
    record.updatedAt = record.lock.updatedAt
    return true, "Location override: " .. formatLock(record, record.lock)
end

function AssignmentOverrides:SetRole(snapshot, assignments, query, wantedRole)
    wantedRole = clean(wantedRole, "", 48)
    if wantedRole == "" then
        return false, "Override role failed: a battlefield role label is required."
    end
    local assignment, reason = resolveAssignment(assignments, query)
    if assignment == false and reason == "AMBIGUOUS_SHORT_NAME" then
        return false, "Override role failed: short-name query matched multiple players. Use the full name."
    end
    if not assignment then
        return false, "Override role failed: player assignment not found in the current plan."
    end
    local record = ensureRecord(assignment.name or query, assignment.guid)
    record.name = clean(assignment.name, record.name, 64)
    record.shortName = clean(assignment.shortName or assignment.name, record.shortName, 32)
    record.guid = clean(assignment.guid, record.guid, 96)
    record.identity = canonicalID(assignment.name, assignment.guid)
    record.lock = record.lock or {}
    record.lock.mapKey = currentMap(snapshot)
    record.lock.role = wantedRole
    record.lock.location = record.lock.location or clean(assignment.location, nil, 48)
    record.lock.priority = math.max(
        KWR.Util:Number(record.lock.priority, 0) or 0,
        KWR.Util:Number(assignment.priority, 90) or 90)
    record.lock.source = "ROLE"
    record.lock.updatedAt = now()
    record.updatedAt = record.lock.updatedAt
    return true, "Role override: " .. formatLock(record, record.lock)
end

function AssignmentOverrides:Clear(query)
    local record, reason = resolveRecord(query)
    if record == false and reason == "AMBIGUOUS_SHORT_NAME" then
        return false, "Override clear failed: short-name query matched multiple players. Use the full name."
    end
    if not record or not record.lock then
        return false, "No commander override exists for " .. clean(query, "that player", 32) .. "."
    end
    record.lock = nil
    record.updatedAt = now()
    return true, "Cleared commander override for " .. clean(query, "that player", 32) .. "."
end

function AssignmentOverrides:ClearAll()
    local cleared = 0
    for _, record in pairs(db()) do
        if record.lock then
            record.lock = nil
            record.updatedAt = now()
            cleared = cleared + 1
        end
    end
    if cleared == 0 then
        return false, "No commander overrides were active."
    end
    return true, string.format("Cleared %d commander override%s.",
        cleared, cleared == 1 and "" or "s")
end

function AssignmentOverrides:Apply(snapshot, assignments)
    for _, assignment in ipairs(assignments or {}) do
        migrateLegacyForAssignment(assignment)
        local record, lock = activeLock(snapshot, assignment)
        if lock then
            if lock.role then assignment.role = lock.role end
            if lock.location then assignment.location = lock.location end
            assignment.priority = math.max(
                KWR.Util:Number(assignment.priority, 0) or 0,
                KWR.Util:Number(lock.priority, 90) or 90)
            assignment.manualOverride = true
            assignment.overrideMode = clean(lock.source, "LOCK", 16)
            assignment.overrideSummary = formatLock(record, lock)
            assignment.overrideUpdatedAt = lock.updatedAt
            assignment.reason = (assignment.reason and (assignment.reason .. " ") or "")
                .. "Commander override is active for this assignment."
        end
    end
    return assignments
end

function AssignmentOverrides:OnInitialize()
    local profile = storage()
    for key, record in pairs(profile.players) do
        if type(record) == "table" and not string.find(tostring(key), "^NAME:", 1, false)
            and not string.find(tostring(key), "^Player%-", 1, false) then
            profile.legacyPlayers[key] = profile.legacyPlayers[key] or KWR.Util:Copy(record)
        end
    end
end

function AssignmentOverrides:DescribeActive(snapshot, assignments)
    local relevant = {}
    local roster = {}
    for _, player in ipairs(snapshot and snapshot.roster or {}) do
        local identity = canonicalID(player.name, player.guid)
        if identity then roster[identity] = true end
    end
    for _, assignment in ipairs(assignments or {}) do
        local identity = canonicalID(assignment.name, assignment.guid)
        if identity then roster[identity] = true end
    end
    for _, record in pairs(db()) do
        local lock = record.lock
        if lock and lock.mapKey == currentMap(snapshot)
            and (next(roster) == nil or roster[record.key]) then
            relevant[#relevant + 1] = formatLock(record, lock)
        end
    end
    for _, record in pairs(storage().legacyPlayers or {}) do
        local lock = record.lock
        if lock and lock.mapKey == currentMap(snapshot)
            and not record.migratedTo then
            relevant[#relevant + 1] = formatLock(record, lock) .. " | LEGACY KEY"
        end
    end
    table.sort(relevant)
    return relevant
end

function AssignmentOverrides:Export(snapshot, assignments)
    local lines = self:DescribeActive(snapshot, assignments)
    if #lines == 0 then
        lines[1] = "No active commander assignment overrides."
    end
    return table.concat({
        "KWR COMMANDER OVERRIDES",
        "Map: " .. clean(currentMap(snapshot), "WORLD", 24),
        "",
        table.concat(lines, "\n"),
    }, "\n")
end

function AssignmentOverrides:HandleSlash(rawInput, state)
    local snapshot = state and state.snapshot or KWR.Store:Get().snapshot
    local assignments = state and state.assignments or KWR.Store:Get().assignments
    local body = clean(rawInput, "", 160)
    body = body:gsub("^override%s*", "")
    local first, second = body:match("^(%S+)%s*(.-)$")
    first = clean(first, "", 24):lower()
    second = clean(second, "", 120)
    if first == "" or first == "help" then
        return {
            title = "KWR Commander Overrides",
            text = table.concat({
                "/kwr override list",
                "/kwr override pin <player>",
                "/kwr override hold <player> <location>",
                "/kwr override role <player> <role>",
                "/kwr override clear <player>",
                "/kwr override clearall",
            }, "\n"),
        }
    end
    if first == "list" then
        return {
            title = "KWR Commander Overrides",
            text = self:Export(snapshot, assignments),
        }
    end
    if first == "clearall" then
        local ok, message = self:ClearAll()
        return { changed = ok, message = message }
    end
    local player, tail = second:match("^(%S+)%s*(.-)$")
    player = clean(player, "", 64)
    tail = clean(tail, "", 96)
    if player == "" then
        return { message = "Override command requires a player name. Use /kwr override help.", changed = false }
    end
    if first == "pin" then
        local ok, message = self:Pin(snapshot, assignments, player)
        return { changed = ok, message = message }
    elseif first == "hold" then
        local ok, message = self:SetLocation(snapshot, assignments, player, tail)
        return { changed = ok, message = message }
    elseif first == "role" then
        local ok, message = self:SetRole(snapshot, assignments, player, tail)
        return { changed = ok, message = message }
    elseif first == "clear" then
        local ok, message = self:Clear(player)
        return { changed = ok, message = message }
    end
    return { message = "Unknown override command. Use /kwr override help.", changed = false }
end

KWR:RegisterModule("AssignmentOverrides", AssignmentOverrides)