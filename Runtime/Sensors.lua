local _, KWR = ...

local Sensors = {
    specCache = {},
    scoreWidgetByMap = {},
    objectiveWidgetByMap = {},
    scoreSession = nil,
    lastScoreRequestAt = -999,
}
KWR.Sensors = Sensors

local Util

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
    for _, row in ipairs(result.rows or {}) do
        if row.label == incoming.label then
            if incoming.x and incoming.y then
                row.x, row.y = incoming.x, incoming.y
                row.mapSource = incoming.mapSource or incoming.source
            end
            if incoming.poiID then row.poiID = incoming.poiID end
            if incoming.vignetteGUID then row.vignetteGUID = incoming.vignetteGUID end
            if (row.owner == nil or row.owner == "UNKNOWN") and incoming.owner then
                row.owner = incoming.owner
            end
            if (row.state == nil or row.state == "AVAILABLE" or row.state == "MAP")
                and incoming.state then
                row.state = incoming.state
            end
            return row
        end
    end
    result.rows[#result.rows + 1] = incoming
    return incoming
end

local function countIcons(icons, labelPrefix, definition)
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
                source = "widget",
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

    local leftOwned, leftIncoming, leftRows, leftFlag =
        countIcons(info.leftIcons, "Alliance", definition)
    local rightOwned, rightIncoming, rightRows, rightFlag =
        countIcons(info.rightIcons, "Horde", definition)
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
                source = "widget",
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
            if label == "" then label = text(info.description, "", 96) end
            label = canonicalLocation(label, definition, label)
            if label ~= "" then
                local x, y = readPosition(info.position)
                local row = mergeObjectiveRow(result, {
                    label = label,
                    state = "MAP",
                    owner = "UNKNOWN",
                    source = "area_poi",
                    mapSource = "area_poi",
                    poiID = poiID,
                    x = x,
                    y = y,
                })
                seen[label] = row
            end
        end
    end
end

local function nearestDefinedLocation(definition, x, y)
    local best, bestDistance
    for label, position in pairs(definition and definition.positions or {}) do
        local px, py = number(position[1], nil), number(position[2], nil)
        if px and py then
            local dx, dy = px - x, py - y
            local distance = (dx * dx) + (dy * dy)
            if not bestDistance or distance < bestDistance then
                best, bestDistance = label, distance
            end
        end
    end
    return best
end

local function appendVignettes(result, mapID, definition)
    if not mapID or not C_VignetteInfo
        or type(C_VignetteInfo.GetVignettes) ~= "function"
        or type(C_VignetteInfo.GetVignetteInfo) ~= "function"
        or type(C_VignetteInfo.GetVignettePosition) ~= "function" then
        return
    end
    local vignetteGUIDs = Util:Call(C_VignetteInfo.GetVignettes)
    if type(vignetteGUIDs) ~= "table" then return end
    for index = 1, math.min(safeArrayLength(vignetteGUIDs), 40) do
        local vignetteGUID = vignetteGUIDs[index]
        local info = Util:Call(C_VignetteInfo.GetVignetteInfo, vignetteGUID)
        local position = Util:Call(C_VignetteInfo.GetVignettePosition, vignetteGUID, mapID)
        if type(info) == "table" and position and not Util:IsSecret(info) then
            local x, y = readPosition(position)
            if x and y then
                local rawLabel = text(info.name, "", 96)
                local label = canonicalLocation(rawLabel, definition, "")
                local known = false
                for _, location in ipairs(definition and definition.locations or {}) do
                    if label == location then known = true break end
                end
                if not known and definition
                    and (definition.kind == "CART" or definition.kind == "RESOURCE") then
                    label = nearestDefinedLocation(definition, x, y) or rawLabel
                    known = label ~= nil and label ~= ""
                end
                if known then
                    mergeObjectiveRow(result, {
                        label = label,
                        state = "ACTIVE",
                        owner = "UNKNOWN",
                        source = "vignette",
                        mapSource = "vignette",
                        vignetteGUID = tostring(vignetteGUID),
                        atlas = text(info.atlasName, "", 80),
                        x = x,
                        y = y,
                    })
                end
            end
        end
    end
end

local function applyFallbackPositions(result, definition)
    if not definition then return end
    local byLabel = {}
    for _, row in ipairs(result.rows or {}) do byLabel[row.label] = row end
    for _, label in ipairs(definition.locations or {}) do
        local position = definition.positions and definition.positions[label]
        local row = byLabel[label]
        if not row then
            row = {
                label = label,
                state = "MAP",
                owner = "UNKNOWN",
                kind = label == "Flag" and "FLAG" or "OBJECTIVE",
                source = "map_definition",
            }
            result.rows[#result.rows + 1] = row
            byLabel[label] = row
        end
        if position and (not row.x or not row.y) then
            row.x = number(position[1], nil)
            row.y = number(position[2], nil)
            row.mapSource = "map_definition"
        end
    end
end

local function requestScoreboard()
    local now = Util:Now()
    if now - (Sensors.lastScoreRequestAt or -999) < 2 then return end
    Sensors.lastScoreRequestAt = now
    if type(RequestBattlefieldScoreData) == "function" then
        Util:Call(RequestBattlefieldScoreData)
    end
end

local function appendFlags(result, mapID)
    if type(GetNumBattlefieldFlagPositions) ~= "function"
        or not C_PvP or not C_PvP.GetBattlefieldFlagPosition then
        return
    end
    local count = number(Util:Call(GetNumBattlefieldFlagPositions), 0)
    result.flags = {}
    for index = 1, math.min(count, 8) do
        local x, y, texture = Util:Call(C_PvP.GetBattlefieldFlagPosition, index, mapID)
        x, y = number(x, nil), number(y, nil)
        if x and y then
            result.flags[#result.flags + 1] = {
                index = index,
                x = x,
                y = y,
                texture = text(texture, "", 80),
            }
        end
    end
end

local function appendVehicles(result, mapID)
    if type(GetNumBattlefieldVehicles) ~= "function"
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

local function captureRoster(mapID)
    local roster = {}
    local units = {}
    local definition = mapID and KWR.Maps:Resolve(mapID, "") or nil
    local observedAt = Util:Now()
    if type(IsInRaid) == "function" and IsInRaid() then
        local count = math.min(number(Util:Call(GetNumGroupMembers), 0), 40)
        for index = 1, count do units[#units + 1] = "raid" .. index end
    elseif type(IsInGroup) == "function" and IsInGroup() then
        units[#units + 1] = "player"
        local count = math.min(number(Util:Call(GetNumSubgroupMembers), 0), 4)
        for index = 1, count do units[#units + 1] = "party" .. index end
    else
        units[1] = "player"
    end

    for _, unit in ipairs(units) do
        local name = Util:UnitName(unit)
        if name then
            local localizedClass, classFile = Util:UnitClass(unit)
            local guid = text(Util:Call(UnitGUID, unit), "", 80)
            local role = text(Util:Call(UnitGroupRolesAssigned, unit), "NONE", 12)
            local specID, specName, specRole, specSource = resolveSpecialization(unit)
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
            local dead = Util:Boolean(Util:Call(UnitIsDeadOrGhost, unit), false)
            local connected = Util:Boolean(Util:Call(UnitIsConnected, unit), true)
            local health = number(Util:Call(UnitHealth, unit), nil)
            local healthMax = number(Util:Call(UnitHealthMax, unit), nil)
            local x, y
            if mapID and C_Map and C_Map.GetPlayerMapPosition then
                local position = Util:Call(C_Map.GetPlayerMapPosition, mapID, unit)
                x, y = readPosition(position)
            end
            local location = x and y and nearestDefinedLocation(definition, x, y) or nil
            roster[#roster + 1] = {
                unit = unit,
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
                inCombat = Util:Boolean(Util:Call(UnitAffectingCombat, unit), false),
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
            }
        end
    end
    table.sort(roster, function(a, b)
        if a.role ~= b.role then
            local order = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }
            return (order[a.role] or 9) < (order[b.role] or 9)
        end
        return a.name < b.name
    end)
    return roster
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
    if not self.scoreSession or self.scoreSession.mapKey ~= context.mapKey then
        self.scoreSession = {
            mapKey = context.mapKey,
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
    local zoneName = text(Util:Call(GetRealZoneText), text(Util:Call(GetZoneText), "World", 80), 80)
    local mapID = C_Map and C_Map.GetBestMapForUnit and number(Util:Call(C_Map.GetBestMapForUnit, "player"), nil) or nil
    local definition = KWR.Maps:Resolve(mapID, zoneName)
    if inPvP then requestScoreboard() end

    local context = {
        inPvP = inPvP,
        instanceType = instanceType,
        mapID = mapID,
        mapKey = definition and definition.key or (inPvP and "UNKNOWN" or "WORLD"),
        mapName = definition and definition.title or zoneName,
        kind = definition and definition.kind or (inPvP and "UNKNOWN" or "WORLD"),
        phase = inPvP and "ACTIVE" or "WORLD",
        isBlitz = inPvP and C_PvP and type(C_PvP.IsBrawlSoloRBG) == "function"
            and Util:Boolean(Util:Call(C_PvP.IsBrawlSoloRBG), false) or false,
        capturedAt = Util:Now(),
    }
    local roster = captureRoster(inPvP and mapID or nil)
    local assigned, scoreboardRows = KWR.TeamResolver:Capture(inPvP, roster)
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
        and KWR.EnemyIntel:Capture(mapID, inPvP, roster, assigned, scoreboardRows) or {}
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
