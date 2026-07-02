local _, KWR = ...

local Maps = {
    byKey = {},
    byMapID = {},
    byName = {},
}
KWR.Maps = Maps

local definitions = {
    ARATHI = {
        title = "Arathi Basin", short = "AB", kind = "NODE",
        mapIDs = { 1366 }, maxScore = 1500, maxObjectives = 5,
        artMapIDs = { 1366 },
        scoreWidget = 1671, objectiveWidget = 1645, tickSeconds = 2, captureSeconds = 60,
        pointsPerTick = { [0]=0, [1]=2, [2]=3, [3]=4, [4]=7, [5]=60 },
        blitzCaptureSeconds = 30,
        blitzPointsPerTick = { [0]=0, [1]=7, [2]=10, [3]=15, [4]=50, [5]=65 },
        locations = { "Blacksmith", "Lumber Mill", "Mine", "Farm", "Stables" },
        abbreviations = {
            Blacksmith = "BS", ["Lumber Mill"] = "LM", Mine = "GM",
            Farm = "FARM", Stables = "ST",
        },
        aliases = { ["gold mine"] = "Mine", ["gold mines"] = "Mine", ["gm"] = "Mine" },
        positions = {
            Blacksmith = { 0.50, 0.50 }, ["Lumber Mill"] = { 0.33, 0.30 },
            Mine = { 0.68, 0.30 }, Farm = { 0.68, 0.72 }, Stables = { 0.32, 0.72 },
        },
        home = { Alliance = "Stables", Horde = "Farm" },
        priorities = { "Blacksmith", "Lumber Mill", "Mine" },
    },
    GILNEAS = {
        title = "Battle for Gilneas", short = "BFG", kind = "NODE",
        mapIDs = { 275 }, maxScore = 1500, maxObjectives = 3,
        artMapIDs = { 275 },
        scoreWidget = 1671, objectiveWidget = 1670, tickSeconds = 1, captureSeconds = 60,
        pointsPerTick = { [0]=0, [1]=1, [2]=3, [3]=30 },
        blitzCaptureSeconds = 30,
        blitzPointsPerTick = { [0]=0, [1]=2, [2]=5, [3]=30 },
        locations = { "Lighthouse", "Waterworks", "Mine" },
        abbreviations = { Lighthouse = "LH", Waterworks = "WW", Mine = "M" },
        aliases = { ["mines"] = "Mine", ["the mine"] = "Mine", ["the lighthouse"] = "Lighthouse" },
        positions = {
            Lighthouse = { 0.27, 0.28 }, Waterworks = { 0.50, 0.52 }, Mine = { 0.73, 0.74 },
        },
        home = { Alliance = "Lighthouse", Horde = "Mine" },
        priorities = { "Lighthouse", "Mine", "Waterworks" },
    },
    DEEPWIND = {
        title = "Deepwind Gorge", short = "DWG", kind = "NODE",
        mapIDs = { 1576, 519 }, maxScore = 1500, maxObjectives = 5,
        artMapIDs = { 1576, 519 },
        scoreWidget = 2074, objectiveWidget = 2339, tickSeconds = 2, captureSeconds = 60,
        pointsPerTick = { [0]=0, [1]=2, [2]=3, [3]=4, [4]=7, [5]=60 },
        blitzCaptureSeconds = 30,
        blitzPointsPerTick = { [0]=0, [1]=7, [2]=10, [3]=15, [4]=50, [5]=65 },
        locations = { "Market", "Ruins", "Shrine", "Quarry", "Farm" },
        abbreviations = { Market = "MKT", Ruins = "R", Shrine = "S", Quarry = "Q", Farm = "F" },
        aliases = { ["the market"] = "Market", ["the ruins"] = "Ruins", ["the shrine"] = "Shrine" },
        positions = {
            Market = { 0.50, 0.23 }, Ruins = { 0.28, 0.39 }, Shrine = { 0.72, 0.39 },
            Quarry = { 0.30, 0.73 }, Farm = { 0.70, 0.73 },
        },
        priorities = { "Market", "Ruins", "Shrine" },
    },
    EOTS = {
        title = "Eye of the Storm", short = "EOTS", kind = "HYBRID",
        mapIDs = { 112, 397 }, maxScore = 1500, maxObjectives = 4,
        artMapIDs = { 112, 397 }, poiMapID = 397,
        scoreWidget = 1671, objectiveWidget = 1672, tickSeconds = 2, captureSeconds = 60,
        pointsPerTick = { [0]=0, [1]=2, [2]=4, [3]=10, [4]=20 },
        flagValue = { [0]=0, [1]=75, [2]=85, [3]=100, [4]=500 },
        -- Midnight restored the normal four-base EOTS model to Blitz.
        blitzPointsPerTick = { [0]=0, [1]=2, [2]=4, [3]=10, [4]=20 },
        blitzFlagValue = { [0]=0, [1]=75, [2]=85, [3]=100, [4]=500 },
        locations = { "Mage Tower", "Draenei Ruins", "Fel Reaver", "Blood Elf Tower", "Flag" },
        abbreviations = {
            ["Mage Tower"] = "MT", ["Draenei Ruins"] = "DR",
            ["Fel Reaver"] = "FRR", ["Blood Elf Tower"] = "BET", Flag = "FLAG",
        },
        aliases = {
            ["fel reaver ruins"] = "Fel Reaver", ["fel reaver"] = "Fel Reaver",
            ["blood elf tower"] = "Blood Elf Tower", ["mage tower"] = "Mage Tower",
            ["draenei ruins"] = "Draenei Ruins", ["center flag"] = "Flag",
        },
        positions = {
            ["Mage Tower"] = { 0.28, 0.28 }, ["Draenei Ruins"] = { 0.28, 0.72 },
            ["Fel Reaver"] = { 0.72, 0.28 }, ["Blood Elf Tower"] = { 0.72, 0.72 },
            Flag = { 0.50, 0.50 },
        },
        home = { Alliance = "Mage Tower", Horde = "Blood Elf Tower" },
        priorities = { "Mage Tower", "Draenei Ruins", "Flag" },
    },
    WSG = {
        title = "Warsong Gulch", short = "WSG", kind = "FLAG",
        mapIDs = { 1339 }, maxScore = 3, scoreWidget = 2, objectiveWidget = 1640,
        artMapIDs = { 1339 },
        stackSeconds = 30,
        locations = { "Home", "Mid", "Enemy Flag Room" },
        abbreviations = { Home = "HOME", Mid = "MID", ["Enemy Flag Room"] = "EFR" },
        aliases = { ["flag room"] = "Enemy Flag Room", ["enemy base"] = "Enemy Flag Room" },
        positions = {
            Home = { 0.23, 0.78 }, Mid = { 0.50, 0.50 }, ["Enemy Flag Room"] = { 0.77, 0.22 },
        },
        priorities = { "Home", "Enemy Flag Room", "Mid" },
    },
    TWINPEAKS = {
        title = "Twin Peaks", short = "TP", kind = "FLAG",
        mapIDs = { 206 }, maxScore = 3, scoreWidget = 2, objectiveWidget = 1640,
        artMapIDs = { 206 },
        stackSeconds = 30,
        locations = { "Home", "Mid", "Enemy Flag Room" },
        abbreviations = { Home = "HOME", Mid = "MID", ["Enemy Flag Room"] = "EFR" },
        aliases = { ["flag room"] = "Enemy Flag Room", ["enemy base"] = "Enemy Flag Room" },
        positions = {
            Home = { 0.25, 0.76 }, Mid = { 0.50, 0.50 }, ["Enemy Flag Room"] = { 0.75, 0.24 },
        },
        priorities = { "Home", "Enemy Flag Room", "Mid" },
    },
    TEMPLE = {
        title = "Temple of Kotmogu", short = "TOK", kind = "ORB",
        mapIDs = { 417 }, maxScore = 1500, scoreWidget = 1671, objectiveWidget = 1683,
        artMapIDs = { 417 },
        maxObjectives = 4,
        locations = { "Center", "Green Orb", "Blue Orb", "Orange Orb", "Purple Orb" },
        abbreviations = {
            Center = "MID", ["Green Orb"] = "G", ["Blue Orb"] = "B",
            ["Orange Orb"] = "O", ["Purple Orb"] = "P",
        },
        aliases = { ["green"] = "Green Orb", ["blue"] = "Blue Orb", ["orange"] = "Orange Orb", ["purple"] = "Purple Orb" },
        positions = {
            Center = { 0.50, 0.50 }, ["Green Orb"] = { 0.31, 0.31 },
            ["Blue Orb"] = { 0.69, 0.31 }, ["Orange Orb"] = { 0.31, 0.69 },
            ["Purple Orb"] = { 0.69, 0.69 },
        },
        priorities = { "Center", "Enemy Carrier", "Loose Orb" },
    },
    SILVERSHARD = {
        title = "Silvershard Mines", short = "SSM", kind = "CART",
        mapIDs = { 423 }, maxScore = 1500, scoreWidget = 1671, objectiveWidget = 1700,
        artMapIDs = { 423 },
        maxObjectives = 3,
        locations = { "Lava", "Water", "Top", "Mid" },
        abbreviations = { Lava = "LAVA", Water = "WATER", Top = "TOP", Mid = "MID" },
        aliases = {
            ["lava cart"] = "Lava", ["water cart"] = "Water",
            ["top cart"] = "Top", ["north cart"] = "Top",
        },
        positions = {
            Lava = { 0.30, 0.72 }, Water = { 0.52, 0.56 }, Top = { 0.70, 0.28 }, Mid = { 0.50, 0.50 },
        },
        priorities = { "Lava", "Top", "Water" },
    },
    DEEPHAUL = {
        title = "Deephaul Ravine", short = "DHR", kind = "CART",
        mapIDs = { 2345 }, maxScore = 1500, scoreWidget = 1671,
        artMapIDs = { 2345 },
        maxObjectives = 2,
        locations = { "Our Cart", "Enemy Cart", "Crystal", "Mid" },
        abbreviations = { ["Our Cart"] = "OC", ["Enemy Cart"] = "EC", Crystal = "CRY", Mid = "MID" },
        aliases = {
            ["friendly cart"] = "Our Cart", ["alliance cart"] = "Our Cart",
            ["horde cart"] = "Enemy Cart", ["power crystal"] = "Crystal",
        },
        positions = {
            ["Our Cart"] = { 0.26, 0.74 }, ["Enemy Cart"] = { 0.74, 0.26 },
            Crystal = { 0.50, 0.50 }, Mid = { 0.50, 0.50 },
        },
        priorities = { "Our Cart", "Enemy Cart", "Crystal" },
    },
    SEETHING = {
        title = "Seething Shore", short = "SHORE", kind = "RESOURCE",
        mapIDs = { 907 }, maxScore = 1500, scoreWidget = 1671,
        artMapIDs = { 907 },
        locations = { "North", "East", "Center", "West", "South" },
        abbreviations = { North = "N", East = "E", Center = "MID", West = "W", South = "S" },
        aliases = { ["northern"] = "North", ["eastern"] = "East", ["western"] = "West", ["southern"] = "South" },
        positions = {
            North = { 0.50, 0.18 }, East = { 0.78, 0.48 }, Center = { 0.50, 0.50 },
            West = { 0.22, 0.48 }, South = { 0.50, 0.82 },
        },
        priorities = { "Next Spawn", "Active Node", "Team" },
    },
}

local genericAbbreviations = {
    ["Formation"] = "FORM",
    ["Our FC"] = "OFC",
    ["Enemy FC"] = "EFC",
    ["Enemy Carrier"] = "E-CARRY",
    ["Loose Orb"] = "LOOSE",
    ["Primary Cart"] = "PC",
    ["Enemy Route"] = "ER",
    ["Active Cart"] = "CART",
    ["Next Spawn"] = "NEXT",
    ["Active Node"] = "NODE",
    ["Main Team"] = "TEAM",
    ["Center"] = "MID",
    ["Outer"] = "OUT",
    ["Flag"] = "FLAG",
    ["Home"] = "HOME",
    ["Mid"] = "MID",
}

local function escapedPattern(value)
    return (value:gsub("(%W)", "%%%1"))
end

function Maps:OnInitialize()
    self.byKey = definitions
    self.byMapID = {}
    self.byName = {}
    for key, definition in pairs(definitions) do
        definition.key = key
        for _, mapID in ipairs(definition.mapIDs or {}) do
            self.byMapID[mapID] = definition
        end
        self.byName[definition.title] = definition
    end
end

function Maps:Get(key)
    return self.byKey[key]
end

function Maps:Resolve(mapID, zoneName)
    mapID = KWR.Util:Number(mapID, nil)
    if mapID and self.byMapID[mapID] then
        return self.byMapID[mapID]
    end
    zoneName = KWR.Util:Text(zoneName, "", 80)
    if self.byName[zoneName] then
        return self.byName[zoneName]
    end
    local lower = zoneName:lower()
    for name, definition in pairs(self.byName) do
        if lower:find(name:lower(), 1, true) then
            return definition
        end
    end
    return nil
end

function Maps:All()
    return self.byKey
end

function Maps:OperationalProfile(mapKey)
    local definition = self:Get(mapKey)
    if not definition then
        return {
            stableMinimum = 0,
            defenderMinimum = 0,
            responseReserve = 0,
            planningHorizon = 15,
        }
    end
    local byKind = {
        NODE = { stableMinimum = math.max(2,
            math.ceil((definition.maxObjectives or 3) / 2)),
            defenderMinimum = 1, responseReserve = 1, planningHorizon = 18 },
        HYBRID = { stableMinimum = 2, defenderMinimum = 1,
            responseReserve = 1, planningHorizon = 18 },
        FLAG = { stableMinimum = 1, defenderMinimum = 2,
            responseReserve = 1, planningHorizon = 15 },
        ORB = { stableMinimum = 2, defenderMinimum = 1,
            responseReserve = 1, planningHorizon = 12 },
        CART = { stableMinimum = 1, defenderMinimum = 1,
            responseReserve = 1, planningHorizon = 16 },
        RESOURCE = { stableMinimum = 1, defenderMinimum = 1,
            responseReserve = 2, planningHorizon = 14 },
    }
    return KWR.Util:Copy(byKind[definition.kind] or {
        stableMinimum = 1, defenderMinimum = 1,
        responseReserve = 1, planningHorizon = 15,
    })
end

function Maps:TravelEstimate(mapKey, fromLocation, toLocation, options)
    local definition = self:Get(mapKey)
    options = options or {}
    if not definition or not definition.positions then return nil end
    local from = definition.positions[fromLocation]
    local target = definition.positions[toLocation]
    if not from or not target then return nil end
    local dx, dy = target[1] - from[1], target[2] - from[2]
    local normalizedDistance = math.sqrt(dx * dx + dy * dy)
    local mobility = KWR.Util:Clamp(options.mobility or 2, 1, 5)
    local secondsPerMap = options.inCombat and 78 or (options.mounted and 38 or 54)
    secondsPerMap = secondsPerMap * (1 - ((mobility - 2) * 0.055))
    local seconds = math.max(2, math.ceil(normalizedDistance * secondsPerMap))
    return {
        seconds = seconds,
        band = seconds <= 6 and "IMMEDIATE"
            or (seconds <= 12 and "NEAR"
            or (seconds <= 20 and "ROTATION" or "LONG")),
        source = "MAP_ROUTE_ESTIMATE",
        confidence = options.observed and "MEDIUM" or "LOW",
        distance = normalizedDistance,
    }
end

function Maps:AbbreviateLocation(mapKey, location)
    location = KWR.Util:Text(location, "", 48)
    local definition = self:Get(mapKey)
    return definition and definition.abbreviations
        and definition.abbreviations[location]
        or genericAbbreviations[location]
        or location
end

function Maps:AbbreviateText(mapKey, value)
    value = KWR.Util:Text(value, "", 255)
    local replacements = {}
    local definition = self:Get(mapKey)
    for full, short in pairs(genericAbbreviations) do
        replacements[#replacements + 1] = { full = full, short = short }
    end
    for full, short in pairs(definition and definition.abbreviations or {}) do
        replacements[#replacements + 1] = { full = full, short = short }
    end
    table.sort(replacements, function(left, right)
        return #left.full > #right.full
    end)
    for _, replacement in ipairs(replacements) do
        value = value:gsub(escapedPattern(replacement.full), replacement.short)
    end
    return value
end

KWR:RegisterModule("Maps", Maps)
