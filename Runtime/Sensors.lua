local _, KWR = ...

local Sensors = {
    specCache = {},
    scoreWidgetByMap = {},
    objectiveWidgetByMap = {},
    scoreSession = nil,
    blitzSessionKey = nil,
    blitzSource = nil,
    lastScoreRequestAt = -999,
}
KWR.Sensors = Sensors

local Util
local SCOREBOARD_REQUEST_INTERVAL = 10

local function number(value, fallback)
    return Util:Number(value, fallback)
end

local function text(value, fallback, maximum)
    return Util:Text(value, fallback, maximum)
end

local function readDoubleStatus(widgetID)
    if not widgetID or not C_UIWidgetManager or not C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo then
        return nil
    end
    local info = Util:Call(C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo, widgetID)
    if type(info) ~= "table" then return nil end
    local left = number(info.leftBarValue, nil)
    local right = number(info.rightBarValue, nil)
    local leftMax = number(info.leftBarMax, nil)
    local rightMax = number(info.rightBarMax, nil)
    if left == nil or right == nil then return nil end
    return {
        left = left,
        right = right,
        max = math.max(leftMax or 0, rightMax or 0),
    }
end

local function validScoreWidget(widget, definition)
    if not widget or not definition then return false end
    if widget.left < 0 or widget.right < 0 then return false end
    local expected = number(definition.maxScore, 0)
    local maximum = number(widget.max, 0)
    if expected > 0 then
        if widget.left > expected or widget.right > expected then return false end
        if maximum > 0 and maximum ~= expected then return false end
    end
    return true
end

local function safeArrayLength(array)
    if type(array) ~= "table" then return 0 end
    local ok, count = pcall(function() return #array end)
    return ok and number(count, 0) or 0
end

local function evidenceTTL(source, field)
    if source == "ui_widget" then
        return (field == "owner" or field == "state") and 5 or 8
    end
    if source == "area_poi" then
        return field == "position" and 20 or 12
    end
    if source == "vignette" then
        return field == "position" and 10 or 8
    end
    if source == "map_definition" then
        return 3600
    end
    return 10
end

local function evidenceConfidence(source, field)
    if source == "ui_widget" then
        return (field == "owner" or field == "state") and 100 or 90
    end
    if source == "area_poi" then
        return field == "position" and 85 or 70
    end
    if source == "vignette" then
        return field == "position" and 75 or 65
    end
    if source == "map_definition" then
        return 40
    end
    return 50
end

local function sourceAuthority(field, source)
    if field == "owner" or field == "state" then
        if source == "ui_widget" then return 400 end
        if source == "area_poi" then return 220 end
        if source == "vignette" then return 180 end
        if source == "map_definition" then return 40 end
        return 0
    end
    if field == "position" then
        if source == "area_poi" then return 320 end
        if source == "vignette" then return 300 end
        if source == "ui_widget" then return 250 end
        if source == "map_definition" then return 80 end
        return 0
    end
    return 0
end

local function lineageRoot(source, subject, revision)
    return table.concat({
        tostring(source or "unknown"),
        tostring(subject or "unknown"),
        tostring(revision or "0"),
    }, ":")
end

local function ensureObjectiveEvidence(row)
    row.evidence = row.evidence or {}
    row.resolution = row.resolution or {}
    return row.evidence, row.resolution
end

local function recordObjectiveEvidence(row, sourceKey, fact, value, observedAt, field, revision, extra)
    local evidence = ensureObjectiveEvidence(row)
    evidence[sourceKey] = evidence[sourceKey] or {}
    local entry = {
        id = table.concat({
            tostring(row.label or "objective"),
            tostring(sourceKey or "source"),
            tostring(field or fact or "fact"),
        }, ":"),
        fact = fact,
        subject = row.label,
        value = value,
        class = sourceKey == "map_definition" and "REFERENCE" or "OBSERVED",
        confidence = evidenceConfidence(sourceKey, field),
        observedAt = observedAt,
        expiresAt = observedAt and (observedAt + evidenceTTL(sourceKey, field)) or nil,
        source = {
            system = sourceKey,
        },
        lineage = {
            root = lineageRoot(sourceKey, row.label, revision),
            family = string.upper(tostring(sourceKey or "unknown")),
        },
        conflicts = {},
    }
    if type(extra) == "table" then
        for key, extraValue in pairs(extra) do
            entry[key] = extraValue
        end
    end
    evidence[sourceKey][field or fact] = entry
    return entry
end

local function resolveObjectiveField(row, field, value, sourceKey, observedAt, revision, extra)
    if value == nil then return false end
    local _, resolution = ensureObjectiveEvidence(row)
    local current = resolution[field]
    local authority = sourceAuthority(field, sourceKey)
    local entry = recordObjectiveEvidence(row, sourceKey, field, value, observedAt, field, revision, extra)
    if not current then
        resolution[field] = {
            value = value,
            selectedSource = sourceKey,
            confidence = entry.confidence,
            status = "RESOLVED",
            observedAt = observedAt,
            authority = authority,
        }
        return true
    end
    if current.value == value then
        if authority >= (current.authority or 0) then
            current.selectedSource = sourceKey
            current.confidence = math.max(current.confidence or 0, entry.confidence or 0)
            current.observedAt = observedAt or current.observedAt
            current.authority = authority
        end
        return authority >= (current.authority or 0)
    end
    current.status = "CONFLICTED"
    current.conflict = {
        otherSource = sourceKey,
        otherValue = value,
        observedAt = observedAt,
        ageDifference = current.observedAt and observedAt
            and math.abs(observedAt - current.observedAt) or nil,
    }
    entry.conflicts[#entry.conflicts + 1] = {
        selectedSource = current.selectedSource,
        selectedValue = current.value,
    }
    if authority > (current.authority or 0) then
        current.value = value
        current.selectedSource = sourceKey
        current.confidence = entry.confidence
        current.observedAt = observedAt
        current.authority = authority
        return true
    end
    return false
end

local function semanticForObjective(definition, owner, state, kind, native)
    local family = definition and definition.kind or "WORLD"
    owner = text(owner, "UNKNOWN", 16)
    state = text(state, "UNKNOWN", 24)
    kind = text(kind, "OBJECTIVE", 16)
    if kind == "FLAG" then
        if state == "CARRIED" then return owner .. "_FLAG_ACTIVE" end
        if state == "AVAILABLE" then return "FLAG_AVAILABLE" end
    end
    if family == "NODE" or family == "RESOURCE" then
        if state == "CONTROLLED" then return owner .. "_CONTROLLED" end
        if state == "INCOMING" then return owner .. "_ASSAULTING" end
        if state == "MAP" then return "MAP_REFERENCE" end
    elseif family == "CART" then
        if state == "ACTIVE" then return "CART_ACTIVE" end
        if state == "CONTROLLED" then return owner .. "_CART_CONTROL" end
    elseif family == "ORB" then
        if state == "CARRIED" then return owner .. "_ORB_HELD" end
    elseif family == "HYBRID" then
        if native and native.atlas and native.atlas ~= "" then
            return text(native.atlas, "HYBRID_ACTIVE", 40)
        end
        if state == "CARRIED" then return owner .. "_FLAG_ACTIVE" end
        if state == "CONTROLLED" then return owner .. "_CONTROLLED" end
        if state == "INCOMING" then return owner .. "_ASSAULTING" end
    end
    return owner .. "_" .. state
end

local function canonicalLocation(label, definition, fallback)
    label = text(label, "", 96)
    local lower = label:lower()
    for alias, canonical in pairs(definition and definition.aliases or {}) do
        if lower == alias or lower:find(alias, 1, true) then return canonical end
    end
    for _, location in ipairs(definition and definition.locations or {}) do
        if lower:find(location:lower(), 1, true) then return location end
    end
    return label ~= "" and label or fallback
end

local function mergeObjectiveRow(result, incoming)
    if not incoming or not incoming.label then return end
    local observedAt = incoming.observedAt or Util:Now()
    local revision = incoming.revision or 0
    for _, row in ipairs(result.rows or {}) do
        if row.label == incoming.label then
            if incoming.x and incoming.y and resolveObjectiveField(row, "position",
                { x = incoming.x, y = incoming.y },
                incoming.mapSource or incoming.source,
                observedAt,
                revision,
                { source = { system = incoming.mapSource or incoming.source, poiID = incoming.poiID, vignetteGUID = incoming.vignetteGUID } }) then
                row.x, row.y = incoming.x, incoming.y
                row.mapSource = incoming.mapSource or incoming.source
            end
            if incoming.poiID then row.poiID = incoming.poiID end
            if incoming.vignetteGUID then row.vignetteGUID = incoming.vignetteGUID end
            if incoming.owner and resolveObjectiveField(row, "owner", incoming.owner,
                incoming.source, observedAt, revision,
                { source = { system = incoming.source, widgetID = incoming.widgetID, iconState = incoming.iconState } }) then
                row.owner = incoming.owner
            end
            if incoming.state and resolveObjectiveField(row, "state", incoming.state,
                incoming.source, observedAt, revision,
                { source = { system = incoming.source, widgetID = incoming.widgetID, iconState = incoming.iconState } }) then
                row.state = incoming.state
            end
            if incoming.native then row.native = incoming.native end
            row.selectedSource = row.resolution and row.resolution.state
                and row.resolution.state.selectedSource or row.selectedSource or incoming.source
            return row
        end
    end
    incoming.selectedSource = incoming.source
    if incoming.owner then
        resolveObjectiveField(incoming, "owner", incoming.owner, incoming.source,
            observedAt, revision,
            { source = { system = incoming.source, widgetID = incoming.widgetID, iconState = incoming.iconState } })
    end
    if incoming.state then
        resolveObjectiveField(incoming, "state", incoming.state, incoming.source,
            observedAt, revision,
            { source = { system = incoming.source, widgetID = incoming.widgetID, iconState = incoming.iconState } })
    end
    if incoming.x and incoming.y then
        resolveObjectiveField(incoming, "position", { x = incoming.x, y = incoming.y },
            incoming.mapSource or incoming.source, observedAt, revision,
            { source = { system = incoming.mapSource or incoming.source, poiID = incoming.poiID, vignetteGUID = incoming.vignetteGUID } })
    end
    result.rows[#result.rows + 1] = incoming
    return incoming
end

local function countIcons(icons, labelPrefix, definition, sideKey, widgetID, revision)
    local controlled, incoming, flagActive = 0, 0, 0
    local rows = {}
    for index = 1, safeArrayLength(icons) do
        local icon = icons[index]
        if type(icon) == "table" and not Util:IsSecret(icon) then
            local state = number(icon.iconState, -1)
            local label = state == 1 and text(icon.state1Tooltip, "", 96)
                or text(icon.state2Tooltip, "", 96)
            if label == "" then
                label = state == 1 and text(icon.state2Tooltip, "", 96)
                    or text(icon.state1Tooltip, "", 96)
            end
            label = canonicalLocation(label, definition, labelPrefix .. " " .. tostring(index))
            local isFlag = definition and definition.kind == "HYBRID"
                and label:lower():find("flag", 1, true) ~= nil
            if isFlag and state == 1 then
                flagActive = flagActive + 1
            elseif not isFlag and state == 2 then
                controlled = controlled + 1
            elseif not isFlag and state == 1 then
                incoming = incoming + 1
            end
            rows[#rows + 1] = {
                label = label,
                state = isFlag and (state == 1 and "CARRIED" or "AVAILABLE")
                    or (state == 2 and "CONTROLLED" or (state == 1 and "INCOMING" or "AVAILABLE")),
                kind = isFlag and "FLAG" or "OBJECTIVE",
                source = "ui_widget",
                observedAt = Util:Now(),
                revision = revision,
                widgetID = widgetID,
                iconState = state,
                native = {
                    widgetID = widgetID,
                    widgetType = "DOUBLE_STATE_ICON_ROW",
                    iconState = state,
                    side = sideKey,
                    tooltip = state == 1 and text(icon.state1Tooltip, "", 96)
                        or text(icon.state2Tooltip, "", 96),
                    rawLabel = label,
                    mapFamily = definition and definition.kind or "WORLD",
                },
            }
        end
    end
    return controlled, incoming, rows, flagActive
end

local function readPosition(position)
    if not position or Util:IsSecret(position) then return nil, nil end
    if type(position) == "table" then
        local x, y = number(position.x, nil), number(position.y, nil)
        if x and y then return x, y end
    end
    local getter
    local ok = pcall(function() getter = position.GetXY end)
    if not ok or type(getter) ~= "function" then return nil, nil end
    local x, y = Util:Call(getter, position)
    return number(x, nil), number(y, nil)
end

local function readIconObjectives(definition, assigned, objectiveWidget)
    local result = {
        friendly = 0,
        enemy = 0,
        friendlyIncoming = 0,
        enemyIncoming = 0,
        rows = {},
        source = "none",
    }
    objectiveWidget = objectiveWidget or (definition and definition.objectiveWidget)
    if not definition or not objectiveWidget
        or not C_UIWidgetManager
        or not C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo then
        return result
    end

    local info = Util:Call(C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo, objectiveWidget)
    if type(info) ~= "table" then return result end
    result.widgetID = objectiveWidget
    local observedAt = Util:Now()
    local revision = math.floor(observedAt * 1000 + 0.5)

    local leftOwned, leftIncoming, leftRows, leftFlag =
        countIcons(info.leftIcons, "Alliance", definition, "LEFT", objectiveWidget, revision)
    local rightOwned, rightIncoming, rightRows, rightFlag =
        countIcons(info.rightIcons, "Horde", definition, "RIGHT", objectiveWidget, revision)
    result.friendly = KWR.TeamResolver:Value(leftOwned, rightOwned, "friendly", assigned) or 0
    result.enemy = KWR.TeamResolver:Value(leftOwned, rightOwned, "enemy", assigned) or 0
    result.friendlyIncoming = KWR.TeamResolver:Value(leftIncoming, rightIncoming, "friendly", assigned) or 0
    result.enemyIncoming = KWR.TeamResolver:Value(leftIncoming, rightIncoming, "enemy", assigned) or 0
    result.leftActive = leftOwned + leftIncoming
    result.rightActive = rightOwned + rightIncoming
    result.friendlyActive = KWR.TeamResolver:Value(result.leftActive, result.rightActive, "friendly", assigned) or 0
    result.enemyActive = KWR.TeamResolver:Value(result.leftActive, result.rightActive, "enemy", assigned) or 0
    result.friendlyFlagActive = KWR.TeamResolver:Value(leftFlag, rightFlag, "friendly", assigned) or 0
    result.enemyFlagActive = KWR.TeamResolver:Value(leftFlag, rightFlag, "enemy", assigned) or 0
    result.source = "ui_widget"

    local side = assigned and assigned.side
    local friendlyRows = side == "left" and leftRows or (side == "right" and rightRows or {})
    local enemyRows = side == "left" and rightRows or (side == "right" and leftRows or {})
    local merged = {}
    local function mergeRows(rows, owner)
        for _, row in ipairs(rows) do
            if row.state ~= "AVAILABLE" then
                local existing = merged[row.label]
                if not existing or existing.state == "AVAILABLE" then
                    row.owner = owner
                    row.native = row.native or {}
                    row.native.leftStateCount = leftOwned + leftIncoming
                    row.native.rightStateCount = rightOwned + rightIncoming
                    row.native.semantic = semanticForObjective(
                        definition, owner, row.state, row.kind, row.native)
                    merged[row.label] = row
                end
            end
        end
    end
    mergeRows(friendlyRows, "FRIENDLY")
    mergeRows(enemyRows, "ENEMY")
    for _, location in ipairs(definition.locations or {}) do
        if location ~= "Flag" then
            local row = merged[location] or {
                label = location,
                state = "AVAILABLE",
                owner = "UNKNOWN",
                kind = "OBJECTIVE",
                source = "ui_widget",
                observedAt = observedAt,
                revision = revision,
                widgetID = objectiveWidget,
                native = {
                    widgetID = objectiveWidget,
                    widgetType = "DOUBLE_STATE_ICON_ROW",
                    iconState = 0,
                    semantic = "UNOBSERVED",
                    mapFamily = definition and definition.kind or "WORLD",
                },
            }
            result.rows[#result.rows + 1] = row
        end
    end
    for label, row in pairs(merged) do
        local known = false
        for _, location in ipairs(definition.locations or {}) do
            if label == location then known = true break end
        end
        if not known then result.rows[#result.rows + 1] = row end
    end
    for _, row in ipairs(result.rows) do
        local rowObservedAt = row.observedAt or observedAt
        local rowRevision = row.revision or revision
        if row.owner then
            resolveObjectiveField(row, "owner", row.owner, row.source, rowObservedAt, rowRevision, {
                source = { system = row.source, widgetID = row.widgetID, iconState = row.iconState },
            })
        end
        if row.state then
            resolveObjectiveField(row, "state", row.state, row.source, rowObservedAt, rowRevision, {
                source = { system = row.source, widgetID = row.widgetID, iconState = row.iconState },
            })
        end
        row.selectedSource = row.resolution and row.resolution.state
            and row.resolution.state.selectedSource or row.source
    end
    return result
end

local function appendPublicPOIs(result, mapID, definition)
    if not mapID or not C_AreaPoiInfo or not C_AreaPoiInfo.GetAreaPOIForMap or not C_AreaPoiInfo.GetAreaPOIInfo then
        return
    end
    local poiIDs = Util:Call(C_AreaPoiInfo.GetAreaPOIForMap, mapID)
    if type(poiIDs) ~= "table" then return end
    local seen = {}
    for _, row in ipairs(result.rows) do
        seen[row.label] = row
    end
    for index = 1, math.min(safeArrayLength(poiIDs), 30) do
        local poiID = number(poiIDs[index], nil)
        local info = poiID and Util:Call(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
        if type(info) == "table" then
            local label = text(info.name, "", 96)
            if label =…1649 tokens truncated…dVehicles) ~= "function"
        or not C_PvP or not C_PvP.GetBattlefieldVehicleInfo then
        return
    end
    local count = number(Util:Call(GetNumBattlefieldVehicles), 0)
    result.vehicles = {}
    for index = 1, math.min(count, 12) do
        local info = Util:Call(C_PvP.GetBattlefieldVehicleInfo, index, mapID)
        if type(info) == "table" and not Util:IsSecret(info)
            and Util:Boolean(info.isAlive, false) and not Util:Boolean(info.isPlayer, false) then
            result.vehicles[#result.vehicles + 1] = {
                name = text(info.name, "Vehicle", 40),
                x = number(info.x, nil),
                y = number(info.y, nil),
                atlas = text(info.atlas, "", 80),
            }
        end
    end
end

local function resolveSpecialization(unit)
    if unit == "player" and type(GetSpecialization) == "function"
        and type(GetSpecializationInfo) == "function" then
        local index = number(Util:Call(GetSpecialization), nil)
        if index and index > 0 then
            local specID, specName, _, _, specRole = Util:Call(GetSpecializationInfo, index)
            specID = number(specID, nil)
            specName = text(specName, "", 32)
            if specID and specName ~= "" then
                return specID, specName, text(specRole, "NONE", 12), "player_spec"
            end
        end
    end
    local specID = number(Util:Call(GetInspectSpecialization, unit), nil)
    if specID and specID > 0 and type(GetSpecializationInfoByID) == "function" then
        local _, specName, _, _, specRole = Util:Call(GetSpecializationInfoByID, specID)
        specName = text(specName, "", 32)
        if specName ~= "" then
            return specID, specName, text(specRole, "NONE", 12), "inspect"
        end
    end
end

function Sensors:ResolveSpecialization(unit)
    return resolveSpecialization(unit)
end

local function raidUnitMatchesRosterName(rosterName, unitName, shortCounts)
    local rosterFull = Util:CanonicalName(rosterName)
    local unitFull = Util:CanonicalName(unitName)
    if rosterFull == "" or unitFull == "" then return false end
    if rosterFull == unitFull then return true end

    local rosterShort = Util:CanonicalShortName(rosterName)
    local unitShort = Util:CanonicalShortName(unitName)
    if rosterShort == "" or rosterShort ~= unitShort then return false end

    -- A realm-qualified mismatch is a different player. Blizzard may omit a
    -- same-realm suffix on one feed, so a unique short name remains a safe
    -- transitional match only when at least one side is unqualified.
    local rosterQualified = rosterFull:find("-", 1, true) ~= nil
    local unitQualified = unitFull:find("-", 1, true) ~= nil
    if rosterQualified and unitQualified then return false end
    return (shortCounts[rosterShort] or 0) == 1
end

local function captureRoster(mapID)
    local roster = {}
    local units = {}
    local raidNames = {}
    local raidLocalizedClasses = {}
    local raidClasses = {}
    local raidRoles = {}
    local raidConnected = {}
    local raidDead = {}
    local definition = mapID and KWR.Maps:Resolve(mapID, "") or nil
    local observedAt = Util:Now()
    local inRaid = type(IsInRaid) == "function" and IsInRaid()
    if inRaid then
        local count = math.min(number(Util:Call(GetNumGroupMembers), 0), 40)
        for index = 1, count do
            units[#units + 1] = "raid" .. index
            if type(GetRaidRosterInfo) == "function" then
                local rosterName, _, _, _, localizedClass, classFile, _,
                    online, isDead, rosterRole =
                    Util:Call(GetRaidRosterInfo, index)
                rosterName = text(rosterName, "", 64)
                if rosterName ~= "" then raidNames[index] = rosterName end
                localizedClass = text(localizedClass, "", 24)
                if localizedClass ~= "" then
                    raidLocalizedClasses[index] = localizedClass
                end
                classFile = text(classFile, "", 24)
                if classFile ~= "" then raidClasses[index] = classFile:upper() end
                if type(online) == "boolean" then raidConnected[index] = online end
                if type(isDead) == "boolean" then raidDead[index] = isDead end
                rosterRole = text(rosterRole, "", 12)
                if rosterRole ~= "" and rosterRole ~= "NONE" then
                    raidRoles[index] = rosterRole
                end
            end
        end
    elseif type(IsInGroup) == "function" and IsInGroup() then
        units[#units + 1] = "player"
        local count = math.min(number(Util:Call(GetNumSubgroupMembers), 0), 4)
        for index = 1, count do units[#units + 1] = "party" .. index end
    else
        units[1] = "player"
    end

    local raidShortCounts = {}
    if inRaid then
        for _, rosterName in pairs(raidNames) do
            local shortName = Util:CanonicalShortName(rosterName)
            if shortName ~= "" then
                raidShortCounts[shortName] = (raidShortCounts[shortName] or 0) + 1
            end
        end
    end

    local seenIdentity, seenName = {}, {}
    for unitIndex, unit in ipairs(units) do
        local unitName = Util:UnitName(unit)
        -- GetRaidRosterInfo owns raid-slot identity. If that slot has not
        -- hydrated yet, omit it for this refresh instead of filling it with a
        -- transient UnitName(raidN), which can temporarily resolve to self.
        local name
        if inRaid then
            name = raidNames[unitIndex]
        else
            name = unitName
        end
        if name then
            local unitStable = not inRaid
                or raidUnitMatchesRosterName(name, unitName, raidShortCounts)
            local localizedClass, classFile
            if unitStable then
                localizedClass, classFile = Util:UnitClass(unit)
            end
            if raidLocalizedClasses[unitIndex] then
                localizedClass = raidLocalizedClasses[unitIndex]
            end
            if raidClasses[unitIndex] then
                classFile = raidClasses[unitIndex]
            end
            localizedClass = text(localizedClass, "Unknown", 24)
            classFile = text(classFile, "UNKNOWN", 24):upper()
            local guid = unitStable
                and text(Util:Call(UnitGUID, unit), "", 80) or ""
            local role = raidRoles[unitIndex]
                or (unitStable
                    and text(Util:Call(UnitGroupRolesAssigned, unit), "NONE", 12)
                    or "NONE")
            local identity = guid ~= "" and guid or name:lower()
            local normalizedName = name:lower()
            local duplicate = seenIdentity[identity] == true
                or seenName[normalizedName] == true
            if not duplicate then
                seenIdentity[identity] = true
                seenName[normalizedName] = true
            end
            if not duplicate then
            local specID, specName, specRole, specSource
            if unitStable then
                specID, specName, specRole, specSource =
                    resolveSpecialization(unit)
            end
            if role == "NONE" and specRole and specRole ~= "NONE" then role = specRole end
            local cacheKey = guid ~= "" and guid or name:lower()
            local cacheRecord
            if specName and specName ~= "" then
                cacheRecord = {
                    id = specID,
                    name = specName,
                    role = specRole,
                    observedAt = Util:Now(),
                }
                Sensors.specCache[cacheKey] = cacheRecord
            else
                local cached = Sensors.specCache[cacheKey] or Sensors.specCache[name:lower()]
                if cached then
                    specID, specName, specRole = cached.id, cached.name, cached.role
                    cacheRecord = cached
                end
            end
            if role == "NONE" and specRole and specRole ~= "NONE" then role = specRole end
            if cacheRecord then
                Sensors.specCache[cacheKey] = cacheRecord
                Sensors.specCache[name:lower()] = cacheRecord
            end
            local dead = raidDead[unitIndex]
            if dead == nil and unitStable then
                dead = Util:Boolean(Util:Call(UnitIsDeadOrGhost, unit), false)
            end
            dead = dead == true
            local connected = raidConnected[unitIndex]
            if connected == nil and unitStable then
                connected = Util:Boolean(Util:Call(UnitIsConnected, unit), true)
            end
            if connected == nil then connected = true end
            local health = unitStable
                and number(Util:Call(UnitHealth, unit), nil) or nil
            local healthMax = unitStable
                and number(Util:Call(UnitHealthMax, unit), nil) or nil
            local x, y
            if unitStable and mapID and C_Map and C_Map.GetPlayerMapPosition then
                local position = Util:Call(C_Map.GetPlayerMapPosition, mapID, unit)
                x, y = readPosition(position)
            end
            local location = x and y and nearestDefinedLocation(definition, x, y) or nil
            local targetGUID
            if unitStable then
                local targetUnit = unit .. "target"
                if Util:Boolean(Util:Call(UnitExists, targetUnit), false)
                    and Util:Boolean(Util:Call(UnitCanAttack, "player", targetUnit), false) then
                    targetGUID = text(Util:Call(UnitGUID, targetUnit), "", 80)
                end
            end
            roster[#roster + 1] = {
                unit = unitStable and unit or nil,
                guid = guid,
                name = name,
                shortName = Util:ShortName(name),
                class = localizedClass,
                classFile = classFile,
                specID = specID,
                spec = specName,
                specSource = specSource or (cacheRecord and "cache" or nil),
                role = role,
                dead = dead,
                connected = connected,
                inCombat = unitStable
                    and Util:Boolean(Util:Call(UnitAffectingCombat, unit), false)
                    or false,
                health = health,
                healthMax = healthMax,
                healthPercent = health and healthMax and healthMax > 0
                    and Util:Clamp((health / healthMax) * 100, 0, 100) or nil,
                x = x,
                y = y,
                visible = true,
                lastSeenAt = observedAt,
                location = location or (mapID and "Position restricted" or "Formation"),
                locationSource = location and "Friendly Map Position" or "Group Unit",
                unitStable = unitStable,
                currentTargetGUID = targetGUID ~= "" and targetGUID or nil,
            }
            end
        end
    end
    table.sort(roster, function(a, b)
        if a.role ~= b.role then
            local order = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }
            return (order[a.role] or 9) < (order[b.role] or 9)
        end
        return a.name < b.name
    end)
    return roster, #units
end

function Sensors:OnInitialize()
    Util = KWR.Util
    if EventRegistry and type(EventRegistry.RegisterFrameEventAndCallback) == "function" then
        for _, event in ipairs({ "INSPECT_READY", "PLAYER_SPECIALIZATION_CHANGED" }) do
            local eventName = event
            EventRegistry:RegisterFrameEventAndCallback(eventName, function()
                if KWR.MatchRuntime then KWR.MatchRuntime:Queue(eventName, 0.05) end
            end, self)
        end
    end
end

function Sensors:ObserveWidget(widgetInfo)
    if type(widgetInfo) ~= "table" or Util:IsSecret(widgetInfo) then return end
    local widgetID = number(widgetInfo.widgetID, nil)
    if not widgetID then return end
    local state = KWR.Store and KWR.Store:Get()
    local mapKey = state and state.snapshot and state.snapshot.context
        and state.snapshot.context.mapKey
    if mapKey and mapKey ~= "WORLD" and mapKey ~= "UNKNOWN" then
        local definition = KWR.Maps:Get(mapKey)
        local widget = readDoubleStatus(widgetID)
        if validScoreWidget(widget, definition) then
            local verifiedID = definition and definition.scoreWidget
            if widgetID == verifiedID
                or not validScoreWidget(readDoubleStatus(verifiedID), definition) then
                self.scoreWidgetByMap[mapKey] = widgetID
            end
        end
        if C_UIWidgetManager and type(C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo) == "function" then
            local info = Util:Call(C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo, widgetID)
            if type(info) == "table"
                and (type(info.leftIcons) == "table" or type(info.rightIcons) == "table") then
                self.objectiveWidgetByMap[mapKey] = widgetID
            end
        end
    end
end

function Sensors:TrackScore(context, score)
    if not context.inPvP then
        self.scoreSession = nil
        return
    end
    if score.source ~= "ui_widget" then return end
    local now = Util:Now()
    local sessionKey = text(
        context.sessionKey,
        Util:BattlefieldSessionKey(context),
        96)
    if not self.scoreSession or self.scoreSession.sessionKey ~= sessionKey then
        self.scoreSession = {
            sessionKey = sessionKey,
            friendly = score.friendly,
            enemy = score.enemy,
            lastCapture = nil,
            observedAt = score.observedAt,
            changedAt = now,
        }
    else
        if score.friendly < (self.scoreSession.friendly or 0)
            or score.enemy < (self.scoreSession.enemy or 0) then
            score.regressionRejected = true
            score.friendly = self.scoreSession.friendly or score.friendly
            score.enemy = self.scoreSession.enemy or score.enemy
            score.observedAt = self.scoreSession.observedAt
            score.changedAt = self.scoreSession.changedAt
            score.lastCapture = self.scoreSession.lastCapture
            return
        end
        if score.friendly > (self.scoreSession.friendly or 0) then
            self.scoreSession.lastCapture = "FRIENDLY"
        elseif score.enemy > (self.scoreSession.enemy or 0) then
            self.scoreSession.lastCapture = "ENEMY"
        end
        if score.friendly ~= self.scoreSession.friendly
            or score.enemy ~= self.scoreSession.enemy then
            self.scoreSession.changedAt = now
        end
        self.scoreSession.friendly = score.friendly
        self.scoreSession.enemy = score.enemy
        self.scoreSession.observedAt = score.observedAt
    end
    score.lastCapture = self.scoreSession.lastCapture
    score.changedAt = self.scoreSession.changedAt
end

function Sensors:Capture(lastMessage)
    local inInstance, instanceType = Util:Call(IsInInstance)
    instanceType = text(instanceType, "none", 16)
    local inPvP = Util:Boolean(inInstance, false) and instanceType == "pvp"
    local _, _, _, _, _, _, _, instanceID = Util:Call(GetInstanceInfo)
    local zoneName = text(Util:Call(GetRealZoneText), text(Util:Call(GetZoneText), "World", 80), 80)
    local mapID = C_Map and C_Map.GetBestMapForUnit and number(Util:Call(C_Map.GetBestMapForUnit, "player"), nil) or nil
    local definition = KWR.Maps:Resolve(mapID, zoneName)
    if inPvP then
        requestScoreboard(false)
    else
        self.lastScoreRequestAt = -999
    end

    local directBlitz = inPvP and C_PvP
        and type(C_PvP.IsBrawlSoloRBG) == "function"
        and Util:Boolean(Util:Call(C_PvP.IsBrawlSoloRBG), false) or false
    local context = {
        inPvP = inPvP,
        instanceType = instanceType,
        mapID = mapID,
        mapKey = definition and definition.key or (inPvP and "UNKNOWN" or "WORLD"),
        mapName = definition and definition.title or zoneName,
        kind = definition and definition.kind or (inPvP and "UNKNOWN" or "WORLD"),
        phase = inPvP and "ACTIVE" or "WORLD",
        instanceID = number(instanceID, nil),
        isBlitz = directBlitz,
        capturedAt = Util:Now(),
    }
    context.sessionKey = Util:BattlefieldSessionKey(context)
    if not inPvP then
        self.blitzSessionKey = nil
        self.blitzSource = nil
    elseif self.blitzSessionKey ~= context.sessionKey then
        self.blitzSessionKey = context.sessionKey
        self.blitzSource = nil
    end
    local roster, expectedRosterCount = captureRoster(inPvP and mapID or nil)
    local assigned, scoreboardRows = KWR.TeamResolver:Capture(
        inPvP, roster, context.sessionKey)
    local scoreboardBlitz, blitzEvidence =
        KWR.TeamResolver:DetectBlitz(scoreboardRows)
    if directBlitz then
        self.blitzSource = "C_PvP.IsBrawlSoloRBG"
    elseif scoreboardBlitz then
        self.blitzSource = blitzEvidence.source
    end
    context.isBlitz = self.blitzSource ~= nil
    context.blitzSource = self.blitzSource or "unconfirmed"
    roster, context.rosterHydration = KWR.TeamResolver:ReconcileFriendlyRoster(
        roster, assigned, scoreboardRows, expectedRosterCount)
    context.team = KWR.Util:Copy(assigned)

    local score = {
        friendly = 0,
        enemy = 0,
        max = definition and definition.maxScore or 0,
        source = "none",
    }
    if inPvP and definition then
        local scoreWidgetID = definition.scoreWidget
        local widget = readDoubleStatus(scoreWidgetID)
        if not validScoreWidget(widget, definition) then
            local discoveredWidget = self.scoreWidgetByMap[definition.key]
            scoreWidgetID = discoveredWidget
            widget = readDoubleStatus(discoveredWidget)
        end
        if validScoreWidget(widget, definition) then
            score.friendly = KWR.TeamResolver:Value(widget.left, widget.right, "friendly", assigned) or 0
            score.enemy = KWR.TeamResolver:Value(widget.left, widget.right, "enemy", assigned) or 0
            score.rawLeft = widget.left
            score.rawRight = widget.right
            score.widgetID = scoreWidgetID
            score.max = widget.max > 0 and widget.max or definition.maxScore
            score.source = assigned and assigned.side and "ui_widget" or "team_unresolved"
            score.observedAt = Util:Now()
            score.widgetAuthority = scoreWidgetID == definition.scoreWidget
                and "verified_map_widget" or "validated_fallback_widget"
        end
    end
    self:TrackScore(context, score)
    score.friendlyNeeded = math.max((score.max or 0) - score.friendly, 0)
    score.enemyNeeded = math.max((score.max or 0) - score.enemy, 0)

    local objectiveWidget = definition and (self.objectiveWidgetByMap[definition.key]
        or definition.objectiveWidget)
    local objectives = inPvP and readIconObjectives(definition, assigned, objectiveWidget) or {
        friendly = 0, enemy = 0, friendlyIncoming = 0, enemyIncoming = 0,
        rows = {}, source = "none",
    }
    if objectives.source == "ui_widget" then
        objectives.observedAt = Util:Now()
    end
    if inPvP then
        appendPublicPOIs(objectives, definition and definition.poiMapID or mapID, definition)
        appendVignettes(objectives, mapID, definition)
        appendFlags(objectives, mapID)
        appendVehicles(objectives, mapID)
        applyFallbackPositions(objectives, definition)
    end

    local enemies = KWR.EnemyIntel
        and KWR.EnemyIntel:Capture(context, roster, assigned, scoreboardRows) or {}
    return {
        context = context,
        score = score,
        objectives = objectives,
        roster = roster,
        enemies = enemies,
        lastMessage = text(lastMessage, "", 160),
        capturedAt = Util:Now(),
    }
end

KWR:RegisterModule("Sensors", Sensors)