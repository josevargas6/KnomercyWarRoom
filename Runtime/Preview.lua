local _, KWR = ...

local Preview = {}
KWR.Preview = Preview

local rosterSeed = {
    { "Knomercy", "Death Knight", "DEATHKNIGHT", "DAMAGER", 0.52, 0.50, "Unholy" },
    { "Verite", "Warrior", "WARRIOR", "DAMAGER", 0.38, 0.41, "Arms" },
    { "Crimson", "Priest", "PRIEST", "HEALER", 0.46, 0.58, "Discipline" },
    { "Affyou", "Rogue", "ROGUE", "DAMAGER", 0.29, 0.62, "Subtlety" },
    { "Syraelina", "Monk", "MONK", "HEALER", 0.62, 0.44, "Mistweaver" },
    { "Haazt", "Warrior", "WARRIOR", "TANK", 0.72, 0.54, "Protection" },
    { "Frostholt", "Mage", "MAGE", "DAMAGER", 0.56, 0.32, "Frost" },
    { "Bighealz", "Shaman", "SHAMAN", "HEALER", 0.42, 0.70, "Restoration" },
    { "Sneakyclown", "Rogue", "ROGUE", "DAMAGER", 0.67, 0.68, "Assassination" },
    { "Judgemeplz", "Paladin", "PALADIN", "DAMAGER", 0.77, 0.37, "Retribution" },
}

local enemySeed = {
    { "Bloodz", "Death Knight", "DEATHKNIGHT", "Unholy", "DAMAGER", 100, 0, 3, 0.68, 0.35, "Lumber Mill" },
    { "Syraelina", "Priest", "PRIEST", "Discipline", "HEALER", 87, 4, 2, 0.58, 0.52, "Blacksmith" },
    { "Zugzugz", "Warrior", "WARRIOR", "Arms", "DAMAGER", 62, 11, 1, 0.42, 0.46, "Lumber Mill" },
    { "Thugonomicz", "Druid", "DRUID", "Balance", "DAMAGER", 45, 18, 0, 0.74, 0.67, "Waterworks" },
    { "Frostholt", "Mage", "MAGE", "Frost", "DAMAGER", 89, 22, 0, 0.50, 0.58, "Mid" },
    { "Sneakyclown", "Rogue", "ROGUE", "Subtlety", "DAMAGER", 76, 27, 0, 0.35, 0.64, "Lumber Mill" },
    { "Judgemeplz", "Paladin", "PALADIN", "Holy", "HEALER", 100, 30, 0, 0.61, 0.41, "Blacksmith" },
    { "Totemlyfe", "Shaman", "SHAMAN", "Restoration", "HEALER", 54, 35, 0, 0.45, 0.72, "Lumber Mill" },
    { "Bighealz", "Monk", "MONK", "Mistweaver", "HEALER", 93, 41, 0, 0.25, 0.55, "Mid" },
    { "Lockdown", "Warlock", "WARLOCK", "Affliction", "DAMAGER", 28, 48, 0, 0.79, 0.48, "Waterworks" },
}

function Preview:Build()
    local now = KWR.Util:Now()
    local roster, enemies = {}, {}
    local rosterHealth = { 100, 82, 74, 91, 66, 48, 88, 59, 96, 34 }
    for index, seed in ipairs(rosterSeed) do
        roster[index] = {
            unit = index == 1 and "player" or ("raid" .. index),
            name = seed[1],
            shortName = seed[1],
            class = seed[2],
            classFile = seed[3],
            spec = seed[7],
            role = seed[4],
            dead = false,
            connected = true,
            healthPercent = rosterHealth[index],
            x = seed[5],
            y = seed[6],
        }
    end
    for index, seed in ipairs(enemySeed) do
        local colors = RAID_CLASS_COLORS and RAID_CLASS_COLORS[seed[3]]
        enemies[index] = {
            key = "PREVIEW:" .. seed[1],
            name = seed[1],
            shortName = seed[1],
            class = seed[2],
            classFile = seed[3],
            spec = seed[4],
            role = seed[5],
            healthPercent = seed[6],
            lastSeenAt = now - seed[7],
            age = seed[7],
            priority = seed[8],
            x = seed[9],
            y = seed[10],
            location = seed[11],
            source = seed[7] == 0 and "Nameplate" or "Ally Target",
            visible = seed[7] < 5,
            localRange = seed[7] < 10,
            localEngaged = seed[7] < 10,
            inCombat = seed[7] < 10,
            dead = false,
            r = colors and colors.r or 0.7,
            g = colors and colors.g or 0.7,
            b = colors and colors.b or 0.7,
            note = index == 2 and "Focus CC" or "",
        }
    end
    return {
        context = {
            inPvP = true,
            preview = true,
            instanceType = "preview",
            mapID = 1366,
            mapKey = "ARATHI",
            mapName = "Arathi Basin",
            kind = "NODE",
            phase = "PREVIEW",
            capturedAt = now,
        },
        score = {
            friendly = 1240, enemy = 980, max = 1500,
            friendlyNeeded = 260, enemyNeeded = 520, source = "preview",
        },
        objectives = {
            friendly = 3, enemy = 2, friendlyActive = 3, enemyActive = 2,
            friendlyIncoming = 0, enemyIncoming = 0, source = "preview",
            rows = {
                { label = "Blacksmith", owner = "FRIENDLY", state = "CONTROLLED", x = 0.48, y = 0.52, source = "preview" },
                { label = "Lumber Mill", owner = "FRIENDLY", state = "CONTROLLED", x = 0.58, y = 0.28, source = "preview" },
                { label = "Gold Mine", owner = "FRIENDLY", state = "CONTROLLED", x = 0.35, y = 0.72, source = "preview" },
                { label = "Farm", owner = "ENEMY", state = "CONTROLLED", x = 0.75, y = 0.46, source = "preview" },
                { label = "Stables", owner = "ENEMY", state = "CONTROLLED", x = 0.66, y = 0.72, source = "preview" },
            },
            flags = {},
            vehicles = {},
        },
        roster = roster,
        enemies = enemies,
        lastMessage = "Preview: enemy pressure building from Farm toward Blacksmith.",
        capturedAt = now,
    }
end

KWR:RegisterModule("Preview", Preview)