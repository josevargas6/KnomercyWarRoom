local _, KWR = ...

local TacticalMap = {}
KWR.TacticalMap = TacticalMap

local function createMarker(parent)
    local marker = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    marker:SetSize(18, 18)
    KWR.Theme:Style(marker, "card", "white")
    marker.dot = marker:CreateTexture(nil, "ARTWORK")
    marker.dot:SetPoint("TOPLEFT", 3, -3)
    marker.dot:SetPoint("BOTTOMRIGHT", -3, 3)
    marker.dot:SetColorTexture(1, 1, 1, 1)
    marker.badge = KWR.Theme:Font(marker, 8, "white", "CENTER", "OUTLINE")
    marker.badge:SetAllPoints()
    marker.label = KWR.Theme:Font(marker, 8, "white", "CENTER", "OUTLINE")
    marker.label:SetPoint("TOP", marker, "BOTTOM", 0, -2)
    marker.label:SetWidth(100)
    marker.label:SetHeight(12)
    marker:Hide()
    return marker
end

function TacticalMap:Create(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    KWR.Theme:Style(frame, "map", "border")
    frame.tiles = {}
    frame.markers = {}
    frame.paths = {}
    frame.mapID = nil
    frame.art = CreateFrame("Frame", nil, frame)
    frame.art:SetPoint("TOPLEFT", 2, -2)
    frame.art:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.shade = frame.art:CreateTexture(nil, "ARTWORK")
    frame.shade:SetAllPoints()
    frame.shade:SetColorTexture(0, 0, 0, 0.18)
    frame.commandText = KWR.Theme:Font(frame, 9, "gold", "LEFT", "OUTLINE")
    frame.commandText:SetPoint("TOPLEFT", 8, -6)
    frame.commandText:SetPoint("TOPRIGHT", -8, -6)
    frame.commandText:SetHeight(16)
    frame.telemetryText = KWR.Theme:Font(frame, 8, "white", "LEFT", "OUTLINE")
    frame.telemetryText:SetPoint("BOTTOMLEFT", 8, 6)
    frame.telemetryText:SetPoint("BOTTOMRIGHT", -8, 6)
    frame.telemetryText:SetHeight(14)
    frame.empty = KWR.Theme:Title(frame, 16, "CENTER")
    frame.empty:SetPoint("CENTER", 0, 8)
    frame.empty:SetWidth(420)
    frame.empty:SetText("TACTICAL MAP STANDBY")
    frame.emptySub = KWR.Theme:Font(frame, 10, "muted", "CENTER")
    frame.emptySub:SetPoint("TOP", frame.empty, "BOTTOM", 0, -10)
    frame.emptySub:SetWidth(420)
    frame.emptySub:SetText("Enter a battleground or use /kwr preview.")

    frame.SetState = function(self, state)
        TacticalMap:Update(self, state)
    end
    frame:SetScript("OnSizeChanged", function(self)
        TacticalMap:LayoutArt(self)
        if self.lastState then
            TacticalMap:RefreshPaths(self, self.lastState)
            TacticalMap:RefreshMarkers(self, self.lastState)
        end
    end)
    return frame
end

function TacticalMap:ClearArt(frame)
    for _, tile in ipairs(frame.tiles) do
        tile:Hide()
        tile:SetTexture(nil)
    end
end

function TacticalMap:LayoutArt(frame)
    if not frame.artColumns or not frame.artRows then return end
    for index, tile in ipairs(frame.tiles) do
        if tile:IsShown() then
            local column = ((index - 1) % frame.artColumns) + 1
            local row = math.floor((index - 1) / frame.artColumns) + 1
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", frame.art, "TOPLEFT",
                ((column - 1) / frame.artColumns) * frame.art:GetWidth(),
                -((row - 1) / frame.artRows) * frame.art:GetHeight())
            tile:SetSize((frame.art:GetWidth() / frame.artColumns) + 1,
                (frame.art:GetHeight() / frame.artRows) + 1)
        end
    end
end

function TacticalMap:SetArt(frame, mapID)
    if frame.mapID == mapID and frame.hasArt then return true end
    frame.mapID = mapID
    frame.hasArt = false
    self:ClearArt(frame)
    if not mapID or not C_Map or type(C_Map.GetMapArtLayers) ~= "function"
        or type(C_Map.GetMapArtLayerTextures) ~= "function" then
        return false
    end
    local layers = KWR.Util:Call(C_Map.GetMapArtLayers, mapID)
    if type(layers) ~= "table" or KWR.Util:IsSecret(layers)
        or type(layers[1]) ~= "table" or KWR.Util:IsSecret(layers[1]) then return false end
    local layer = layers[1]
    local layerIndex = KWR.Util:Number(layer.layerIndex, 1)
    local textures = KWR.Util:Call(C_Map.GetMapArtLayerTextures, mapID, layerIndex)
    if type(textures) ~= "table" or KWR.Util:IsSecret(textures) or not textures[1] then return false end
    local tileWidth = KWR.Util:Number(layer.tileWidth, 256)
    local tileHeight = KWR.Util:Number(layer.tileHeight, 256)
    local layerWidth = KWR.Util:Number(layer.layerWidth, tileWidth * 3)
    local layerHeight = KWR.Util:Number(layer.layerHeight, tileHeight * 3)
    local columns = math.max(1, math.ceil(layerWidth / tileWidth))
    local rows = math.max(1, math.ceil(layerHeight / tileHeight))
    frame.artColumns, frame.artRows = columns, rows
    local index = 1
    for row = 1, rows do
        for column = 1, columns do
            local textureID = textures[index]
            if textureID then
                local tile = frame.tiles[index] or frame.art:CreateTexture(nil, "BACKGROUND")
                frame.tiles[index] = tile
                tile:SetTexture(textureID)
                tile:SetTexCoord(0, 1, 0, 1)
                tile:SetVertexColor(0.82, 0.82, 0.78, 0.92)
                tile:Show()
            end
            index = index + 1
        end
    end
    self:LayoutArt(frame)
    frame.hasArt = true
    return true
end

function TacticalMap:SetBestArt(frame, context)
    local definition = KWR.Maps:Get(context and context.mapKey)
    local candidates, seen = {}, {}
    local function add(mapID)
        mapID = KWR.Util:Number(mapID, nil)
        if mapID and not seen[mapID] then
            candidates[#candidates + 1] = mapID
            seen[mapID] = true
        end
    end
    add(context and context.mapID)
    for _, mapID in ipairs(definition and definition.artMapIDs or {}) do add(mapID) end
    for _, mapID in ipairs(definition and definition.mapIDs or {}) do add(mapID) end
    for _, mapID in ipairs(candidates) do
        if self:SetArt(frame, mapID) then return true end
    end
    return false
end

function TacticalMap:AcquireMarker(frame, index)
    if not frame.markers[index] then frame.markers[index] = createMarker(frame.art) end
    return frame.markers[index]
end

function TacticalMap:Place(frame, index, x, y, label, color, size, options)
    x, y = KWR.Util:Number(x, nil), KWR.Util:Number(y, nil)
    if not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return index end
    options = options or {}
    local marker = self:AcquireMarker(frame, index)
    marker:ClearAllPoints()
    marker:SetPoint("CENTER", frame.art, "TOPLEFT", x * frame.art:GetWidth(), -y * frame.art:GetHeight())
    marker:SetSize(size or 18, size or 18)
    marker.dot:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    local border = options.border or color
    marker:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    marker.badge:SetText(options.badge or "")
    marker.label:SetText(frame.compact and "" or (label or ""))
    marker:SetAlpha(options.alpha or 1)
    marker:Show()
    return index + 1
end

function TacticalMap:AcquirePath(frame, index, color)
    local line = frame.paths[index]
    if not line and type(frame.art.CreateLine) == "function" then
        line = frame.art:CreateLine(nil, "ARTWORK")
        if line then
            line:SetThickness(frame.compact and 1.5 or 2)
            frame.paths[index] = line
        end
    end
    if line then line:SetColorTexture(color[1], color[2], color[3], color[4] or 0.55) end
    return line
end

function TacticalMap:RefreshPaths(frame, state)
    local reporter = state.snapshot and state.snapshot.reporter
    local index = 1
    if type(reporter) == "table" then
        local function drawTrack(track, color)
            local points = track.points or {}
            local first = math.max(2, #points - (frame.compact and 2 or 5))
            for pointIndex = first, #points do
                local from, to = points[pointIndex - 1], points[pointIndex]
                local line = TacticalMap:AcquirePath(frame, index, color)
                if line and from and to then
                    line:SetStartPoint("CENTER", frame.art, "TOPLEFT",
                        from.x * frame.art:GetWidth(), -from.y * frame.art:GetHeight())
                    line:SetEndPoint("CENTER", frame.art, "TOPLEFT",
                        to.x * frame.art:GetWidth(), -to.y * frame.art:GetHeight())
                    line:Show()
                    index = index + 1
                end
            end
        end
        for _, track in ipairs(reporter.friendly or {}) do drawTrack(track, { 0.20, 0.52, 1.00, 0.50 }) end
        for _, track in ipairs(reporter.enemy or {}) do
            drawTrack(track, (track.age or 999) <= 10
                and { 1.00, 0.18, 0.18, 0.55 } or { 1.00, 0.70, 0.18, 0.40 })
        end
    end
    for pathIndex = index, #frame.paths do frame.paths[pathIndex]:Hide() end
end

function TacticalMap:RefreshMarkers(frame, state)
    local index = 1
    local snapshot = state.snapshot or {}
    local objectives = snapshot.objectives or {}
    local commandText = KWR.Util:Text(state.command and state.command.action, "", 160):lower()
    local hotspot = snapshot.reporter and snapshot.reporter.hotspot
    local function isPriority(label)
        label = KWR.Util:Text(label, "", 64)
        if label == "" then return false end
        if commandText:find(label:lower(), 1, true) then return true end
        return hotspot and hotspot.label == label and (hotspot.risk or 0) >= 55
    end
    for _, objective in ipairs(objectives.rows or {}) do
        local color = objective.owner == "FRIENDLY" and { 0.20, 0.50, 1.00, 1 }
            or (objective.owner == "ENEMY" and { 0.95, 0.16, 0.16, 1 } or { 0.90, 0.70, 0.20, 1 })
        local incoming = objective.state == "INCOMING"
        local priority = isPriority(objective.label)
        local badge = objective.owner == "FRIENDLY" and "F"
            or (objective.owner == "ENEMY" and "E" or "?")
        if incoming then badge = "!" end
        index = self:Place(frame, index, objective.x, objective.y, objective.label, color,
            priority and 28 or 24, {
                badge = badge,
                border = priority and { 1.00, 0.78, 0.20, 1 } or color,
            })
    end
    local reporter = snapshot.reporter
    local friendlyTracks = reporter and reporter.friendly or snapshot.roster or {}
    local enemyTracks = reporter and reporter.enemy or snapshot.enemies or {}
    for _, player in ipairs(friendlyTracks) do
        local badge = player.dead and "X"
            or (player.inCombat and "C"
            or (player.role == "TANK" and "T" or (player.role == "HEALER" and "H" or "F")))
        index = self:Place(frame, index, player.x, player.y, player.name or player.shortName,
            { 0.18, 0.55, 1.00, 1 }, 16, { badge = badge, alpha = player.dead and 0.45 or 1 })
    end
    local killName = snapshot.combat and snapshot.combat.killTarget
        and KWR.Util:ShortName(snapshot.combat.killTarget.name or ""):lower()
    for _, enemy in ipairs(enemyTracks) do
        local age = enemy.age
        local color = age and age > 30 and { 0.45, 0.45, 0.45, 0.95 }
            or (age and age > 10 and { 0.96, 0.70, 0.16, 1 } or { 0.95, 0.18, 0.18, 1 })
        local enemyName = KWR.Util:ShortName(enemy.name or enemy.shortName or ""):lower()
        local kill = killName and killName ~= "" and killName == enemyName
        local badge = kill and "K"
            or (enemy.dead and "X"
            or (enemy.inCombat and "C"
            or (enemy.role == "HEALER" and "H" or (enemy.role == "TANK" and "T" or "E"))))
        index = self:Place(frame, index, enemy.x, enemy.y, enemy.name or enemy.shortName,
            color, kill and 20 or 16, {
                badge = badge,
                alpha = enemy.dead and 0.38 or (age and age > 30 and 0.55 or 1),
                border = kill and { 1.00, 0.78, 0.20, 1 } or color,
            })
    end
    for _, flag in ipairs(objectives.flags or {}) do
        local texture = KWR.Util:Text(flag.texture, "", 80):lower()
        local color, badge, label = { 1.00, 0.85, 0.22, 1 }, "FLG", "FLAG"
        if texture:find("green", 1, true) then
            color, badge, label = { 0.20, 0.85, 0.30, 1 }, "G", "Green Orb"
        elseif texture:find("blue", 1, true) then
            color, badge, label = { 0.20, 0.55, 1.00, 1 }, "B", "Blue Orb"
        elseif texture:find("orange", 1, true) then
            color, badge, label = { 1.00, 0.48, 0.10, 1 }, "O", "Orange Orb"
        elseif texture:find("purple", 1, true) then
            color, badge, label = { 0.68, 0.28, 1.00, 1 }, "P", "Purple Orb"
        end
        index = self:Place(frame, index, flag.x, flag.y, label,
            color, 22, { badge = badge })
    end
    for _, carrier in ipairs(objectives.carriers or {}) do
        local colors = {
            Green = { 0.20, 0.85, 0.30, 1 },
            Blue = { 0.20, 0.55, 1.00, 1 },
            Orange = { 1.00, 0.48, 0.10, 1 },
            Purple = { 0.68, 0.28, 1.00, 1 },
            Alliance = { 0.20, 0.55, 1.00, 1 },
            Horde = { 0.95, 0.18, 0.18, 1 },
        }
        local badge = carrier.kind == "ORB"
            and KWR.Util:Text(carrier.color, "O", 1):upper() or "FC"
        if (carrier.stacks or 0) > 0 then badge = tostring(carrier.stacks) end
        index = self:Place(frame, index, carrier.x, carrier.y,
            carrier.player .. " - " .. carrier.objective,
            colors[carrier.color] or { 1.00, 0.85, 0.22, 1 }, 24, {
                badge = badge,
                border = carrier.owner == "ENEMY"
                    and { 1.00, 0.12, 0.12, 1 } or { 0.20, 0.65, 1.00, 1 },
            })
    end
    for markerIndex = index, #frame.markers do frame.markers[markerIndex]:Hide() end
end

function TacticalMap:Update(frame, state)
    frame.lastState = state
    local context = state.snapshot and state.snapshot.context or {}
    local hasArt = self:SetBestArt(frame, context)
    frame.empty:SetShown(not hasArt)
    frame.emptySub:SetShown(not hasArt)
    frame.empty:SetText(hasArt and "" or KWR.Util:Upper(context.mapName, "TACTICAL MAP", 48))
    frame.emptySub:SetText(hasArt and ""
        or "Map art unavailable; objective positions and live telemetry remain active.")
    local snapshot = state.snapshot or {}
    local reporter = snapshot.reporter or {}
    local command = state.command or {}
    frame.commandText:SetText("NEXT: " .. KWR.Util:Text(command.action, "Waiting for battlefield truth.", frame.compact and 58 or 110))
    local objectiveSource = snapshot.objectives and snapshot.objectives.source or "none"
    local coverage = reporter.coverage or {}
    frame.telemetryText:SetText(string.format(
        "RISK %d  |  TRACKS %dF/%dE  |  LOCATED %dF/%dE  |  ENGAGED %dF/%dE  |  OBJECTIVES %s",
        reporter.risk or 0,
        coverage.friendly or 0,
        coverage.enemy or 0,
        coverage.friendlyLocated or 0,
        coverage.enemyLocated or 0,
        coverage.friendlyCombat or 0,
        coverage.enemyCombat or 0,
        KWR.Util:Upper(objectiveSource, "NONE", 18)
    ))
    frame.commandText:SetTextColor(KWR.Theme:Color((command.urgency or 0) >= 85 and "red"
        or ((command.urgency or 0) >= 60 and "yellow" or "gold")))
    self:RefreshPaths(frame, state)
    self:RefreshMarkers(frame, state)
end

KWR:RegisterModule("TacticalMap", TacticalMap)
