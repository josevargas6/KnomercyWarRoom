local _, KWR = ...

local TacticalMap = {}
KWR.TacticalMap = TacticalMap

local HEADER_HEIGHT = 56
local FOOTER_HEIGHT = 22

local function trustTone(label)
    local value = KWR.Util:Upper(label, "NONE", 24)
    if value == "HIGH" or value == "STRONG" or value == "VERIFIED" then return "green" end
    if value == "MEDIUM" or value == "MIXED" or value == "TRACKED" then return "yellow" end
    if value == "LOW" or value == "THIN" then return "orange" end
    return "muted"
end

local function objectiveTone(source)
    local value = KWR.Util:Upper(source, "NONE", 24)
    if value:find("WIDGET", 1, true) or value:find("PUBLIC", 1, true)
        or value:find("DIRECT", 1, true) then
        return "green"
    end
    if value:find("DERIVED", 1, true) or value:find("PREDICT", 1, true) then
        return "yellow"
    end
    if value == "NONE" or value == "UNKNOWN" then return "muted" end
    return "orange"
end

local function objectiveTag(source)
    return KWR.Util:ObjectiveSourceLabel(source)
end

local function coverageTone(coverage)
    local visible = KWR.Util:Number(coverage and coverage.enemyVisible, 0) or 0
    local recent = KWR.Util:Number(coverage and coverage.enemyRecent, 0) or 0
    local stale = KWR.Util:Number(coverage and coverage.enemyStale, 0) or 0
    if visible >= 3 then return "green" end
    if visible + recent >= 3 then return "yellow" end
    if stale > 0 then return "orange" end
    return "muted"
end

local function commandTone(state)
    return KWR.CommandView:BadgeState(state)
end

local function callBadge(state)
    local reporter = state and state.snapshot and state.snapshot.reporter or {}
    return KWR.Util:CallReadout(reporter.trust, state and state.prediction
        and state.prediction.urgency, state)
end

local function markerName(record)
    if type(record) ~= "table" then return "" end
    return KWR.Util:Text(record.shortName or record.name, "", 48)
end

local function locationLabel(mapKey, label)
    label = KWR.Util:Text(label, "", 48)
    if label == "" then return "" end
    return KWR.Maps:AbbreviateLocation(mapKey, label)
end

local function trackPositionLine(track)
    if track and track.positionSource == "ESTIMATED" then
        return "Position: estimated (" .. KWR.Util:Text(track.location, "Unknown", 48) .. ")"
    end
    return track and track.positionSource == "OBSERVED"
        and "Position: observed" or "Position: unknown"
end

local function bestTrackList(primary, fallback)
    if type(primary) == "table" and #primary > 0 then
        return primary
    end
    if type(fallback) == "table" then
        return fallback
    end
    return {}
end


local function createMarker(parent)
    local marker = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    marker:SetSize(16, 16)
    KWR.Theme:Style(marker, "card", "white")
    marker.ring = marker:CreateTexture(nil, "ARTWORK")
    marker.ring:SetPoint("TOPLEFT", -3, 3)
    marker.ring:SetPoint("BOTTOMRIGHT", 3, -3)
    marker.ring:SetTexture("Interface\\Cooldown\\ping4")
    marker.ring:SetBlendMode("ADD")
    marker.ring:Hide()
    marker.dot = marker:CreateTexture(nil, "ARTWORK")
    marker.dot:SetPoint("TOPLEFT", 2, -2)
    marker.dot:SetPoint("BOTTOMRIGHT", -2, 2)
    marker.dot:SetColorTexture(1, 1, 1, 1)
    marker.icon = marker:CreateTexture(nil, "OVERLAY")
    marker.icon:SetPoint("TOPLEFT", 2, -2)
    marker.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    marker.icon:Hide()
    marker.badge = KWR.Theme:Font(marker, 7, "white", "CENTER", "OUTLINE")
    marker.badge:SetAllPoints()
    marker.label = KWR.Theme:Font(marker, 7, "white", "CENTER", "OUTLINE")
    marker.label:SetPoint("TOP", marker, "BOTTOM", 0, -2)
    marker.label:SetWidth(96)
    marker.label:SetHeight(18)
    marker:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.tooltipTitle then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tooltipTitle, 1, 0.84, 0.24)
        for _, line in ipairs(self.tooltipLines or {}) do
            GameTooltip:AddLine(line, 0.78, 0.80, 0.84, true)
        end
        GameTooltip:Show()
    end)
    marker:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
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
    frame.headerBand = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.headerBand:SetPoint("TOPLEFT", 2, -2)
    frame.headerBand:SetPoint("TOPRIGHT", -2, -2)
    frame.headerBand:SetHeight(HEADER_HEIGHT)
    KWR.Theme:Style(frame.headerBand, "panel", "border")
    frame.footerBand = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.footerBand:SetPoint("BOTTOMLEFT", 2, 2)
    frame.footerBand:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.footerBand:SetHeight(FOOTER_HEIGHT)
    KWR.Theme:Style(frame.footerBand, "panel", "border")
    frame.art = CreateFrame("Frame", nil, frame)
    frame.art:SetPoint("TOPLEFT", frame.headerBand, "BOTTOMLEFT", 0, -2)
    frame.art:SetPoint("BOTTOMRIGHT", frame.footerBand, "TOPRIGHT", 0, 2)
    frame.art:SetClipsChildren(true)
    frame.shade = frame.art:CreateTexture(nil, "ARTWORK")
    frame.shade:SetAllPoints()
    frame.shade:SetColorTexture(0.03, 0.04, 0.06, 0.34)
    frame.canvas = CreateFrame("Frame", nil, frame.art)
    frame.canvas:SetPoint("CENTER")
    frame.canvas:SetSize(1, 1)
    frame.commandText = KWR.Theme:Font(frame.headerBand, 9, "gold", "LEFT", "OUTLINE")
    frame.commandText:SetPoint("TOPLEFT", 8, -28)
    frame.commandText:SetPoint("TOPRIGHT", -8, -28)
    frame.commandText:SetHeight(16)
    frame.contextText = KWR.Theme:Font(frame.headerBand, 8, "soft", "LEFT", "OUTLINE")
    frame.contextText:SetPoint("TOPLEFT", 8, -44)
    frame.contextText:SetPoint("TOPRIGHT", -8, -44)
    frame.contextText:SetHeight(14)
    frame.telemetryText = KWR.Theme:Font(frame.footerBand, 8, "white", "LEFT", "OUTLINE")
    frame.telemetryText:SetPoint("TOPLEFT", 8, -4)
    frame.telemetryText:SetPoint("TOPRIGHT", -8, -4)
    frame.telemetryText:SetHeight(14)
    frame.stateBadge = KWR.Theme:Badge(frame.headerBand, "muted", "SETUP", 80, 16)
    frame.stateBadge:SetPoint("TOPLEFT", 8, -8)
    frame.trustBadge = KWR.Theme:Badge(frame.headerBand, "muted", "HOLD", 88, 16)
    frame.trustBadge:SetPoint("LEFT", frame.stateBadge, "RIGHT", 8, 0)
    frame.coverageBadge = KWR.Theme:Badge(frame.headerBand, "muted", "SEEN 0", 90, 16)
    frame.coverageBadge:SetPoint("LEFT", frame.trustBadge, "RIGHT", 8, 0)
    frame.objectiveBadge = KWR.Theme:Badge(frame.headerBand, "muted", "SOURCE", 88, 16)
    frame.objectiveBadge:SetPoint("LEFT", frame.coverageBadge, "RIGHT", 8, 0)
    frame.empty = KWR.Theme:Title(frame, 16, "CENTER")
    frame.empty:SetPoint("CENTER", 0, 8)
    frame.empty:SetWidth(420)
    frame.empty:SetText("TACTICAL MAP READY")
    frame.emptySub = KWR.Theme:Font(frame, 10, "muted", "CENTER")
    frame.emptySub:SetPoint("TOP", frame.empty, "BOTTOM", 0, -10)
    frame.emptySub:SetWidth(420)
    frame.emptySub:SetText((KWR.BuildInfo and KWR.BuildInfo:HasPreview())
        and "Enter a battleground or use /kwr preview."
        or "Enter a battleground to begin.")

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
    local columns = frame.visibleArtColumns or frame.artColumns
    local rows = frame.visibleArtRows or frame.artRows
    if not columns or not rows then return end
    local viewportWidth = math.max(1, frame.art:GetWidth() or 1)
    local viewportHeight = math.max(1, frame.art:GetHeight() or 1)
    local mapWidth = math.max(1, KWR.Util:Number(frame.mapPixelWidth, columns) or columns)
    local mapHeight = math.max(1, KWR.Util:Number(frame.mapPixelHeight, rows) or rows)
    local viewportRatio = viewportWidth / viewportHeight
    local mapRatio = mapWidth / mapHeight
    local canvasWidth, canvasHeight
    if viewportRatio >= mapRatio then
        canvasWidth = viewportWidth
        canvasHeight = canvasWidth / mapRatio
    else
        canvasHeight = viewportHeight
        canvasWidth = canvasHeight * mapRatio
    end
    frame.canvas:ClearAllPoints()
    frame.canvas:SetPoint("CENTER", frame.art, "CENTER", 0, 0)
    frame.canvas:SetSize(canvasWidth, canvasHeight)
    for index, tile in ipairs(frame.tiles) do
        if tile:IsShown() then
            local column = ((index - 1) % columns) + 1
            local row = math.floor((index - 1) / columns) + 1
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", frame.canvas, "TOPLEFT",
                ((column - 1) / columns) * canvasWidth,
                -((row - 1) / rows) * canvasHeight)
            tile:SetSize((canvasWidth / columns) + 1,
                (canvasHeight / rows) + 1)
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
    frame.visibleArtColumns, frame.visibleArtRows = columns, rows
    local index = 1
    local lastVisibleColumn, lastVisibleRow = 1, 1
    for row = 1, rows do
        for column = 1, columns do
            local textureID = textures[index]
            if textureID then
                local tile = frame.tiles[index] or frame.canvas:CreateTexture(nil, "BACKGROUND")
                frame.tiles[index] = tile
                tile:SetTexture(textureID)
                tile:SetTexCoord(0, 1, 0, 1)
                tile:SetVertexColor(0.82, 0.82, 0.78, 0.92)
                tile:Show()
                lastVisibleColumn = math.max(lastVisibleColumn, column)
                lastVisibleRow = math.max(lastVisibleRow, row)
            end
            index = index + 1
        end
    end
    frame.visibleArtColumns = lastVisibleColumn
    frame.visibleArtRows = lastVisibleRow
    frame.mapPixelWidth = lastVisibleColumn * tileWidth
    frame.mapPixelHeight = lastVisibleRow * tileHeight
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
    if not frame.markers[index] then frame.markers[index] = createMarker(frame.canvas) end
    return frame.markers[index]
end

function TacticalMap:Place(frame, index, x, y, label, color, size, options)
    x, y = KWR.Util:Number(x, nil), KWR.Util:Number(y, nil)
    if not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return index end
    options = options or {}
    local marker = self:AcquireMarker(frame, index)
    marker:ClearAllPoints()
    local canvasWidth = frame.canvas:GetWidth()
    local canvasHeight = frame.canvas:GetHeight()
    marker:SetPoint("CENTER", frame.canvas, "TOPLEFT", x * canvasWidth, -y * canvasHeight)
    marker:SetSize(size or 18, size or 18)
    local shape = options.shape or "square"
    local ring = options.ring or options.border or color
    marker.dot:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    local iconSize = options.iconSize or (size or 18)
    local showIcon = options.icon and KWR.Icons and KWR.Icons:Apply(marker.icon, options.icon, iconSize)
    if not showIcon then marker.icon:Hide() end
    marker.dot:SetAlpha(showIcon and (options.fillAlpha or 0.12) or 1)
    local border = options.border or color
    if shape == "circle" then
        local dotOnly = options.dotOnly == true
        marker.ring:SetVertexColor(ring[1], ring[2], ring[3], ring[4] or 0.90)
        marker.ring:SetShown(not dotOnly)
        marker:SetBackdropColor(0, 0, 0, 0)
        marker:SetBackdropBorderColor(0, 0, 0, 0)
        marker.dot:SetPoint("TOPLEFT", dotOnly and 1 or 4, dotOnly and -1 or -4)
        marker.dot:SetPoint("BOTTOMRIGHT", dotOnly and -1 or 4, dotOnly and 1 or -4)
        marker.dot:SetTexture("Interface\\Buttons\\WHITE8X8")
        marker.dot:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    else
        marker.ring:Hide()
        marker:SetBackdropColor(KWR.Theme:Color("card"))
        marker:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        marker.dot:SetPoint("TOPLEFT", 2, -2)
        marker.dot:SetPoint("BOTTOMRIGHT", -2, 2)
        marker.dot:SetTexture("Interface\\Buttons\\WHITE8X8")
        marker.dot:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end
    marker.badge:SetText(options.badge or "")
    marker.badge:SetShown(KWR.Util:Text(options.badge, "", 12) ~= "")
    local showLabel = options.showLabel == true or ((frame.compact ~= true) and options.showLabel ~= false)
    local text = showLabel and (label or "") or ""
    local multiline = text:find("\n", 1, true) ~= nil
    marker.label:SetWidth(options.labelWidth or (frame.reporterMode and (multiline and 88 or 76)
        or ((options.emphasis or options.showLabel == true) and 90 or 78)))
    marker.label:SetHeight(multiline and 24 or 16)
    marker.label:SetText(text)
    marker:SetAlpha(options.alpha or 1)
    marker.tooltipTitle = options.tooltipTitle
    marker.tooltipLines = options.tooltipLines
    marker:Show()
    return index + 1
end

function TacticalMap:AcquirePath(frame, index, color)
    local line = frame.paths[index]
    if not line and type(frame.canvas.CreateLine) == "function" then
        line = frame.canvas:CreateLine(nil, "ARTWORK")
        if line then
            line:SetThickness(frame.compact and 1.5 or 2)
            frame.paths[index] = line
        end
    end
    if line then
        line:SetThickness(frame.liveMode and 1 or (frame.compact and 1.5 or 2))
        line:SetColorTexture(color[1], color[2], color[3], color[4] or 0.55)
    end
    return line
end

function TacticalMap:RefreshPaths(frame, state)
    local reporter = state.snapshot and state.snapshot.reporter
    local index = 1
    -- Keep live trails balanced between friendlies and enemies: a full friendly
    -- roster must not crowd the enemy movement signal off the map.
    local maximumTracks = frame.liveMode and 4 or nil
    local drawnTracks = 0
    if type(reporter) == "table" then
        local function drawTrack(track, color)
            if maximumTracks and drawnTracks >= maximumTracks then return end
            if frame.liveMode and track.positionSource ~= "OBSERVED" then return end
            local points = track.points or {}
            local first = math.max(2, #points - (frame.liveMode and 2 or (frame.compact and 2 or 5)))
            local drew = false
            for pointIndex = first, #points do
                local from, to = points[pointIndex - 1], points[pointIndex]
                local line = TacticalMap:AcquirePath(frame, index, color)
                if line and from and to then
                    line:SetStartPoint("CENTER", frame.canvas, "TOPLEFT",
                        from.x * frame.canvas:GetWidth(), -from.y * frame.canvas:GetHeight())
                    line:SetEndPoint("CENTER", frame.canvas, "TOPLEFT",
                        to.x * frame.canvas:GetWidth(), -to.y * frame.canvas:GetHeight())
                    line:Show()
                    index = index + 1
                    drew = true
                end
            end
            if drew then drawnTracks = drawnTracks + 1 end
        end
        for _, track in ipairs(reporter.friendly or {}) do drawTrack(track, { 0.20, 0.52, 1.00, 0.50 }) end
        drawnTracks = 0
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
    local mapKey = snapshot.context and snapshot.context.mapKey
    local objectives = snapshot.objectives or {}
    local reporter = snapshot.reporter or {}
    local commandText = KWR.CommandView:ActionText(state.command, "", 160):lower()
    local liveDots = frame.liveMode == true
    local hotspot = reporter.hotspot
    local pressureByLabel, etaByLabel = {}, {}
    for _, row in ipairs(reporter.pressure or {}) do
        pressureByLabel[KWR.Util:Text(row.label, "", 64)] = row
    end
    for _, row in ipairs(reporter.etas or {}) do
        etaByLabel[KWR.Util:Text(row.label, "", 64)] = row
    end
    local function isPriority(label)
        label = KWR.Util:Text(label, "", 64)
        if label == "" then return false end
        if commandText:find(label:lower(), 1, true) then return true end
        return hotspot and hotspot.label == label and (hotspot.risk or 0) >= 55
    end
    local function objectiveIcon(objective)
        if objective.pendingState == "INCOMING" or objective.state == "INCOMING" then
            return "node_incoming"
        end
        if objective.pendingState == "CONTESTED" or objective.state == "CONTESTED" then
            return "node_contested"
        end
        if objective.pendingState == "ASSAULT" or objective.state == "ASSAULT" then
            return "node_assault"
        end
        if objective.owner == "FRIENDLY" then return "node_friendly" end
        if objective.owner == "ENEMY" then return "node_enemy" end
        return "contest"
    end
    local function playerIcon(unit, team)
        if unit.dead then return "disabled" end
        if unit.role == "HEALER" then return "healer" end
        if unit.role == "TANK" then return "tank" end
        if unit.role == "DAMAGER" then return "dps" end
        if team == "TEAM" then return "friendly" end
        return "enemy"
    end
    local function teamBorder(team, emphasis)
        if emphasis then
            return { KWR.Theme:CombatColor("CARRY") }
        end
        if team == "TEAM" then
            return { KWR.Theme:CombatColor("TEAM") }
        end
        return { KWR.Theme:CombatColor("KILL") }
    end
    local function objectiveFreeIcon(texture)
        texture = KWR.Util:Text(texture, "", 80):lower()
        if texture:find("green", 1, true) then return "orb_green" end
        if texture:find("blue", 1, true) then return "orb_blue" end
        if texture:find("orange", 1, true) then return "orb_orange" end
        if texture:find("purple", 1, true) then return "orb_purple" end
        return "flag_dropped"
    end
    local function carrierIcon(carrier)
        local color = KWR.Util:Text(carrier.color, "", 24)
        local owner = KWR.Util:Upper(carrier.owner, "", 16)
        if carrier.kind == "ORB" then
            local tone = color:lower()
            if tone == "green" or tone == "blue" or tone == "orange" or tone == "purple" then
                return "orb_" .. tone .. "_carrier_" .. (owner == "ENEMY" and "enemy" or "friendly")
            end
        end
        return owner == "ENEMY" and "flag_enemy" or "flag_friendly"
    end
    for _, objective in ipairs(objectives.rows or {}) do
        local pressure = pressureByLabel[KWR.Util:Text(objective.label, "", 64)]
        local eta = etaByLabel[KWR.Util:Text(objective.label, "", 64)]
        local color = objective.owner == "FRIENDLY" and { 0.20, 0.50, 1.00, 1 }
            or (objective.owner == "ENEMY" and { 0.95, 0.16, 0.16, 1 } or { 0.90, 0.70, 0.20, 1 })
        local incoming = objective.pendingState == "INCOMING"
            or objective.state == "INCOMING"
        local priority = isPriority(objective.label)
        local badge = incoming and "!" or ""
        local label = locationLabel(mapKey, objective.label)
        if frame.reporterMode then
            local details = {}
            local timerRemaining = KWR.Util:Number(objective.timerRemaining, nil)
            if timerRemaining and timerRemaining > 0 then
                details[#details + 1] = KWR.Util:Clock(timerRemaining)
            end
            if pressure and pressure.total and pressure.total > 0 then
                details[#details + 1] = tostring(pressure.friendly or 0)
                    .. "F/" .. tostring(pressure.enemy or 0) .. "E"
            elseif eta and (eta.friendlyETA or eta.enemyETA) then
                details[#details + 1] = "ETA "
                    .. KWR.Util:Clock(eta.friendlyETA or 0)
                    .. "/" .. KWR.Util:Clock(eta.enemyETA or 0)
            end
            if #details > 0 then
                label = label .. "\n" .. table.concat(details, "  ")
            end
        end
        local tooltipLines = {
            "Owner: " .. KWR.Util:Text(objective.owner, "UNKNOWN", 16),
            "State: " .. KWR.Util:Text(objective.state, "WATCH", 20),
            "Source: " .. KWR.Util:Text(objective.source
                or objective.pendingSource, "unknown", 24),
        }
        if pressure and pressure.total and pressure.total > 0 then
            tooltipLines[#tooltipLines + 1] = string.format(
                "Pressure: %dF / %dE",
                pressure.friendly or 0, pressure.enemy or 0)
        elseif eta and (eta.friendlyETA or eta.enemyETA) then
            tooltipLines[#tooltipLines + 1] = string.format(
                "ETA: %ss F / %ss E",
                tostring(eta.friendlyETA or "?"),
                tostring(eta.enemyETA or "?"))
        end
        if priority then
            tooltipLines[#tooltipLines + 1] = "Commander priority node."
        end
        index = self:Place(frame, index, objective.x, objective.y, label, color,
            priority and (frame.compact and 14 or (liveDots and 17 or 24))
                or (frame.compact and 10 or (liveDots and 13 or 20)), {
                badge = badge,
                icon = objectiveIcon(objective),
                iconSize = priority and (frame.compact and 14 or (liveDots and 15 or 20))
                    or (frame.compact and 10 or (liveDots and 11 or 16)),
                fillAlpha = 0.10,
                shape = "square",
                border = priority and { 1.00, 0.78, 0.20, 1 } or color,
                showLabel = frame.reporterMode == true or priority,
                emphasis = priority,
                tooltipTitle = KWR.Util:Text(objective.label, "Objective", 48),
                tooltipLines = tooltipLines,
            })
    end
    local friendlyTracks = bestTrackList(reporter and reporter.friendly, snapshot.roster)
    local enemyTracks = bestTrackList(reporter and reporter.enemy, snapshot.enemies)
    for _, player in ipairs(friendlyTracks) do
        local badge = player.dead and "X" or ""
        local estimated = player.positionSource == "ESTIMATED"
        index = self:Place(frame, index, player.x, player.y, markerName(player),
            player.role == "HEALER" and { 0.18, 0.82, 0.32, 1 } or { 0.18, 0.55, 1.00, 1 },
            frame.compact and 7 or (liveDots and (estimated and 6 or 8) or 14),
            {
                badge = badge,
                icon = not liveDots and playerIcon(player, "TEAM") or nil,
                iconSize = frame.compact and 12 or 18,
                fillAlpha = liveDots and 1 or 0.16,
                shape = "circle",
                dotOnly = liveDots,
                ring = teamBorder("TEAM", false),
                alpha = player.dead and 0.45 or (estimated and 0.55 or 1),
                border = teamBorder("TEAM", false),
                showLabel = frame.reporterMode == true and frame.compact ~= true,
                tooltipTitle = KWR.Util:Text(player.name or player.shortName, "Friendly", 48),
                tooltipLines = {
                    "Role: " .. KWR.Util:Text(player.role, "UNKNOWN", 16),
                    "Health: " .. (player.healthPercent
                        and (tostring(math.floor(player.healthPercent + 0.5)) .. "%")
                        or "Unknown"),
                    "State: " .. (player.dead and "Dead"
                        or (player.inCombat and "In combat" or "Seen")),
                    trackPositionLine(player),
                },
            })
    end
    local localTarget = snapshot.combat and (snapshot.combat.localTarget
        or snapshot.combat.killTarget) or nil
    local killName = localTarget
        and KWR.Util:ShortName(localTarget.name or ""):lower()
    for _, enemy in ipairs(enemyTracks) do
        local age = enemy.age
        local color = age and age > 30 and { 0.45, 0.45, 0.45, 0.95 }
            or (age and age > 10 and { 0.96, 0.70, 0.16, 1 } or { 0.95, 0.18, 0.18, 1 })
        local enemyName = KWR.Util:ShortName(enemy.name or enemy.shortName or ""):lower()
        local kill = killName and killName ~= "" and killName == enemyName
        local badge = enemy.dead and "X" or ""
        local estimated = enemy.positionSource == "ESTIMATED"
        index = self:Place(frame, index, enemy.x, enemy.y, markerName(enemy),
            enemy.role == "HEALER" and not kill
                and { 0.24, 0.96, 0.40, 1 } or color,
            kill and (frame.compact and 10 or (liveDots and 14 or 18))
                or (frame.compact and 7 or (liveDots and (estimated and 6 or 8) or 14)), {
                badge = badge,
                icon = kill and "kill" or (not liveDots and playerIcon(enemy, "ENEMY") or nil),
                iconSize = kill and (frame.compact and 16 or 22) or (frame.compact and 12 or 18),
                fillAlpha = liveDots and 1 or 0.16,
                shape = "circle",
                dotOnly = liveDots and not kill,
                ring = teamBorder("ENEMY", kill),
                alpha = enemy.dead and 0.38 or (estimated and 0.55 or (age and age > 30 and 0.55 or 1)),
                border = teamBorder("ENEMY", kill),
                showLabel = frame.reporterMode == true or kill,
                emphasis = kill,
                tooltipTitle = KWR.Util:Text(enemy.name or enemy.shortName, "Enemy", 48),
                tooltipLines = {
                    "Role: " .. KWR.Util:Text(enemy.role, "UNKNOWN", 16)
                        .. " | Spec: " .. KWR.Util:Text(enemy.spec, "Unknown", 28),
                    "Seen: " .. (age and KWR.Util:Age(age) or "Roster only"),
                    "Location: " .. KWR.Util:Text(enemy.location, "Unknown", 48),
                    trackPositionLine(enemy),
                    kill and "Current local target." or "Observed enemy contact.",
                },
            })
    end
    for _, flag in ipairs(objectives.flags or {}) do
        local texture = KWR.Util:Text(flag.texture, "", 80):lower()
        local color, badge, label = { 1.00, 0.85, 0.22, 1 }, "", "FLAG"
        if texture:find("green", 1, true) then
            color, badge, label = { 0.20, 0.85, 0.30, 1 }, "", "Green Orb"
        elseif texture:find("blue", 1, true) then
            color, badge, label = { 0.20, 0.55, 1.00, 1 }, "", "Blue Orb"
        elseif texture:find("orange", 1, true) then
            color, badge, label = { 1.00, 0.48, 0.10, 1 }, "", "Orange Orb"
        elseif texture:find("purple", 1, true) then
            color, badge, label = { 0.68, 0.28, 1.00, 1 }, "", "Purple Orb"
        end
        index = self:Place(frame, index, flag.x, flag.y, label,
            color, frame.compact and 12 or (liveDots and 14 or 20), {
                badge = badge,
                icon = objectiveFreeIcon(texture),
                iconSize = frame.compact and 14 or (liveDots and 14 or 20),
                fillAlpha = 0.10,
                shape = "square",
                showLabel = frame.reporterMode == true,
                tooltipTitle = label,
                tooltipLines = {
                    "Free objective marker.",
                    "Color: " .. badge,
                },
            })
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
        local badge = ""
        if (carrier.stacks or 0) > 0 then badge = tostring(carrier.stacks) end
        index = self:Place(frame, index, carrier.x, carrier.y,
            carrier.player .. " - " .. carrier.objective,
            colors[carrier.color] or { 1.00, 0.85, 0.22, 1 },
            frame.compact and 14 or (liveDots and 16 or 22), {
                badge = badge,
                icon = carrierIcon(carrier),
                iconSize = frame.compact and 16 or (liveDots and 16 or 22),
                fillAlpha = 0.16,
                shape = "circle",
                ring = carrier.owner == "ENEMY"
                    and teamBorder("ENEMY", false) or teamBorder("TEAM", false),
                border = carrier.owner == "ENEMY"
                    and teamBorder("ENEMY", false) or teamBorder("TEAM", false),
                showLabel = frame.reporterMode == true,
                tooltipTitle = KWR.Util:Text(carrier.player, "Carrier", 48),
                tooltipLines = {
                    "Objective: " .. KWR.Util:Text(carrier.objective, "Unknown", 48),
                    "Owner: " .. KWR.Util:Text(carrier.owner, "UNKNOWN", 16),
                    "Stacks: " .. tostring(carrier.stacks or 0),
                },
            })
    end
    for _, vehicle in ipairs(objectives.vehicles or {}) do
        index = self:Place(frame, index, vehicle.x, vehicle.y,
            vehicle.name or "Vehicle",
            { 0.88, 0.88, 0.92, 1 },
            frame.compact and 9 or (liveDots and 11 or 16),
            {
                badge = "V",
                border = { 0.74, 0.74, 0.78, 1 },
                showLabel = frame.reporterMode == true,
                tooltipTitle = KWR.Util:Text(vehicle.name, "Vehicle", 48),
                tooltipLines = {
                    "Objective vehicle.",
                },
            })
    end
    for markerIndex = index, #frame.markers do frame.markers[markerIndex]:Hide() end
end

function TacticalMap:Update(frame, state)
    frame.lastState = state
    local context = state.snapshot and state.snapshot.context or {}
    frame.liveMode = context.inPvP == true and context.preview ~= true
    local hasArt = self:SetBestArt(frame, context)
    frame.empty:SetShown(not hasArt)
    frame.emptySub:SetShown(not hasArt)
    frame.empty:SetText(hasArt and "" or KWR.Util:Upper(context.mapName, "TACTICAL MAP", 48))
    frame.emptySub:SetText(hasArt and ""
        or "Map art unavailable; objective positions and live telemetry remain active.")
    local snapshot = state.snapshot or {}
    local reporter = snapshot.reporter or {}
    local command = state.command or {}
    local tone, tag = commandTone(state)
    local objectiveSource = snapshot.objectives and snapshot.objectives.source or "none"
    local coverage = reporter.coverage or {}
    local emphasis = snapshot.commandEmphasis or {}
    local localTarget = snapshot.combat and snapshot.combat.localTarget
    local commandTarget = snapshot.combat and snapshot.combat.killTarget
    local hotspot = reporter.hotspot
    local callTone, callTag = callBadge(state)
    frame.headerBand:SetHeight(HEADER_HEIGHT)
    frame.footerBand:SetHeight(FOOTER_HEIGHT)
    frame.commandText:SetPoint("TOPLEFT", 8, -28)
    frame.commandText:SetPoint("TOPRIGHT", -8, -28)
    frame.contextText:SetPoint("TOPLEFT", 8, -44)
    frame.contextText:SetPoint("TOPRIGHT", -8, -44)
    frame.stateBadge:SetSize(80, 16)
    frame.trustBadge:SetSize(88, 16)
    frame.coverageBadge:SetSize(90, 16)
    frame.objectiveBadge:SetSize(88, 16)
    frame.stateBadge:SetTone(tone)
    frame.stateBadge:SetText(tag)
    frame.trustBadge:SetTone(callTone)
    frame.trustBadge:SetText(callTag)
    frame.coverageBadge:SetTone(coverageTone(coverage))
    frame.coverageBadge:SetText("SEEN " .. tostring(coverage.enemyVisible or 0)
        .. "/" .. tostring(coverage.enemyRecent or 0))
    frame.objectiveBadge:SetTone(objectiveTone(objectiveSource))
    frame.objectiveBadge:SetText(objectiveTag(objectiveSource))
    frame.commandText:SetText("CALL: " .. KWR.Util:Text(emphasis.action,
        KWR.CommandView:ActionText(command, "Waiting for live battleground data.", 110),
        frame.compact and 56 or 110))
    local threat = emphasis.threat and emphasis.threat.label or nil
    local route = emphasis.route
    local timer = emphasis.timer
    frame.contextText:SetText(table.concat({
        threat and ("THREAT " .. KWR.Util:Text(threat, "", 20)) or "THREAT NONE",
        route and ("ROUTE " .. KWR.Util:Text(route.target, "", 18)
            .. " " .. tostring(route.friendlyETA or "?") .. "s") or "ROUTE VERIFY",
        timer and ("TIMER " .. KWR.Util:Clock(timer.seconds)) or "TIMER NONE",
    }, "  |  "))
    frame.telemetryText:SetText(string.format(
        "%d SEEN  |  %d RECENT  |  %s  |  %s",
        coverage.enemyVisible or 0,
        (coverage.enemyVisible or 0) + (coverage.enemyRecent or 0),
        localTarget and ("KILL " .. KWR.Util:ShortName(localTarget.name or localTarget.shortName or "TARGET"))
            or "NO KILL TARGET",
        objectiveTag(objectiveSource) .. " | CMD "
            .. (emphasis.consistency and emphasis.consistency.ok and "SYNC" or "VERIFY")
    ))
    frame.commandText:SetTextColor(KWR.Theme:Color((command.urgency or 0) >= 85 and "red"
        or ((command.urgency or 0) >= 60 and "yellow" or "gold")))
    frame.contextText:SetTextColor(KWR.Theme:Color(localTarget and "soft" or "muted"))
    self:RefreshPaths(frame, state)
    self:RefreshMarkers(frame, state)
end

KWR:RegisterModule("TacticalMap", TacticalMap)
