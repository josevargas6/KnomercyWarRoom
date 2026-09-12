local savedVariablesPath = arg and arg[1]
if type(savedVariablesPath) ~= "string" or savedVariablesPath == "" then
    error("SavedVariables path is required.")
end

local function clean(value)
    local text = tostring(value == nil and "" or value)
    return text:gsub("[\t\r\n]", " ")
end

local function number(value)
    return tonumber(value) or 0
end

local function count(records)
    local total = 0
    for _ in pairs(type(records) == "table" and records or {}) do
        total = total + 1
    end
    return total
end

-- This is a diagnostic size approximation, not a serializer and not an
-- evidence substitute for the exact file-byte budget.  It deliberately emits
-- only structure and lengths so a local footprint receipt cannot expose player
-- names, notes, call text, or other retained content.
local function approximateBytes(value, seen)
    local valueType = type(value)
    if valueType == "string" then return #value + 2 end
    if valueType == "number" then return #tostring(value) end
    if valueType == "boolean" then return value and 4 or 5 end
    if valueType ~= "table" then return 0 end
    seen = seen or {}
    if seen[value] then return 0 end
    seen[value] = true
    local total = 4
    for key, child in pairs(value) do
        total = total + approximateBytes(key, seen) + approximateBytes(child, seen) + 4
    end
    return total
end

local function emit(...)
    local values = { ... }
    for index = 1, #values do
        values[index] = clean(values[index])
    end
    print(table.concat(values, "\t"))
end

dofile(savedVariablesPath)
if type(KWR_DB) ~= "table" then
    error("KWR_DB was not defined by the SavedVariables file.")
end

local journal = type(KWR_DB.journal) == "table" and KWR_DB.journal or {}
local history = type(journal.history) == "table" and journal.history or {}
emit("META", KWR_DB.schemaVersion, #history, journal.interrupted and "YES" or "NO")

local rootKeys = {}
for key in pairs(KWR_DB) do
    rootKeys[#rootKeys + 1] = tostring(key)
end
table.sort(rootKeys)
for _, key in ipairs(rootKeys) do
    local value = KWR_DB[key]
    emit("FOOTPRINT", key, type(value) == "table" and count(value) or 0,
        approximateBytes(value))
end

for index, entry in ipairs(history) do
    local stability = type(entry.commandStability) == "table" and entry.commandStability or {}
    local score = type(entry.scoreEnd) == "table" and entry.scoreEnd or {}
    emit(
        "MATCH",
        index,
        entry.id,
        entry.mapKey,
        entry.mapName,
        entry.result,
        entry.startedAt,
        entry.endedAt,
        entry.duration,
        stability.certificationStatus,
        stability.commandHealth,
        stability.replacements,
        stability.reversals,
        stability.preMovementInvalidations,
        stability.successfulPlays,
        score.friendly,
        score.enemy,
        count(entry.friendlyTeam),
        count(entry.enemyTeam),
        #(type(entry.commands) == "table" and entry.commands or {}),
        #(type(entry.events) == "table" and entry.events or {}),
        entry.addonVersion,
        entry.schemaVersion,
        entry.performance and entry.performance.samples,
        entry.performance and entry.performance.maxRefreshMs,
        entry.performance and entry.performance.maxP95Ms,
        entry.performance and entry.performance.firstMemoryKB,
        entry.performance and entry.performance.lastMemoryKB,
        entry.performance and entry.performance.maxMemoryKB,
        entry.performance and entry.performance.maxTransitionMs,
        entry.performance and entry.performance.errors,
        entry.safety and entry.safety.blocked,
        entry.safety and entry.safety.forbidden,
        entry.safety and entry.safety.total
    )
end
