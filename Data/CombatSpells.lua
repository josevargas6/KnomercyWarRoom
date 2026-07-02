local _, KWR = ...

local CombatSpells = {}
KWR.CombatSpells = CombatSpells

-- Patch 12.0.7 baseline windows. Cooldowns are advisory because talents and
-- specialization modifiers can shorten them; KWR only reports spells it has
-- actually observed and never treats an unobserved defensive as ready.
local DEFENSIVES = {
    -- Death Knight
    [48707] = { name = "Anti-Magic Shell", active = 5, cooldown = 40, weight = 18 },
    [48792] = { name = "Icebound Fortitude", active = 8, cooldown = 120, weight = 32 },
    [51052] = { name = "Anti-Magic Zone", active = 10, cooldown = 180, weight = 22 },
    [55233] = { name = "Vampiric Blood", active = 10, cooldown = 90, weight = 20 },

    -- Demon Hunter
    [196718] = { name = "Darkness", active = 8, cooldown = 180, weight = 36 },
    [198589] = { name = "Blur", active = 10, cooldown = 60, weight = 24 },
    [196555] = { name = "Netherwalk (Devourer)", active = 2.5, cooldown = 60, weight = 42,
        defensiveClass = "IMMUNITY", response = "SWAP" },

    -- Druid
    [22812] = { name = "Barkskin", active = 12, cooldown = 60, weight = 18 },
    [61336] = { name = "Survival Instincts", active = 6, cooldown = 180, weight = 34 },
    [102342] = { name = "Ironbark", active = 12, cooldown = 90, weight = 28 },

    -- Evoker
    [363916] = { name = "Obsidian Scales", active = 12, cooldown = 90, weight = 26 },
    [374227] = { name = "Zephyr", active = 8, cooldown = 120, weight = 20 },

    -- Hunter
    [186265] = { name = "Aspect of the Turtle", active = 8, cooldown = 150, weight = 42,
        defensiveClass = "IMMUNITY", response = "SWAP" },
    [109304] = { name = "Exhilaration", active = 0, cooldown = 120, weight = 16 },
    [264735] = { name = "Survival of the Fittest", active = 6, cooldown = 90, weight = 28 },

    -- Mage
    [45438] = { name = "Ice Block", active = 10, cooldown = 180, weight = 46,
        defensiveClass = "IMMUNITY", response = "SWAP" },
    [342245] = { name = "Alter Time", active = 10, cooldown = 50, weight = 24 },
    [110959] = { name = "Greater Invisibility", active = 3, cooldown = 120, weight = 28 },
    [414658] = { name = "Ice Cold", active = 6, cooldown = 240, weight = 38 },

    -- Monk
    [115203] = { name = "Fortifying Brew", active = 15, cooldown = 90, weight = 36 },
    [122470] = { name = "Touch of Karma", active = 10, cooldown = 90, weight = 34 },
    [116849] = { name = "Life Cocoon", active = 12, cooldown = 75, weight = 38,
        defensiveClass = "ABSORB", response = "HOLD_DAMAGE" },

    -- Paladin
    [642] = { name = "Divine Shield", active = 8, cooldown = 210, weight = 50,
        defensiveClass = "IMMUNITY", response = "SWAP" },
    [1022] = { name = "Blessing of Protection", active = 10, cooldown = 240, weight = 38,
        defensiveClass = "PHYSICAL_IMMUNITY", response = "SWAP_OR_MAGIC" },
    [204018] = { name = "Blessing of Spellwarding", active = 6, cooldown = 240, weight = 38,
        defensiveClass = "MAGIC_IMMUNITY", response = "SWAP_OR_PHYSICAL" },
    [633] = { name = "Lay on Hands", active = 0, cooldown = 420, weight = 36 },
    [6940] = { name = "Blessing of Sacrifice", active = 12, cooldown = 60, weight = 24 },
    [498] = { name = "Divine Protection", active = 8, cooldown = 60, weight = 20 },
    [31850] = { name = "Ardent Defender", active = 8, cooldown = 84, weight = 34 },
    [86659] = { name = "Guardian of Ancient Kings", active = 8, cooldown = 300, weight = 42 },

    -- Priest
    [19236] = { name = "Desperate Prayer", active = 0, cooldown = 70, weight = 16 },
    [586] = { name = "Fade", active = 1, cooldown = 20, weight = 12 },
    [47585] = { name = "Dispersion", active = 6, cooldown = 90, weight = 40,
        defensiveClass = "MAJOR_MITIGATION", response = "SWAP" },
    [33206] = { name = "Pain Suppression", active = 8, cooldown = 180, weight = 36 },
    [47788] = { name = "Guardian Spirit", active = 10, cooldown = 180, weight = 38 },

    -- Rogue
    [31224] = { name = "Cloak of Shadows", active = 5, cooldown = 120, weight = 30 },
    [5277] = { name = "Evasion", active = 10, cooldown = 120, weight = 26 },
    [1856] = { name = "Vanish", active = 3, cooldown = 120, weight = 28 },

    -- Shaman
    [108271] = { name = "Astral Shift", active = 12, cooldown = 90, weight = 26 },
    [204336] = { name = "Grounding Totem", active = 3, cooldown = 24, weight = 16 },
    [409293] = { name = "Burrow", active = 5, cooldown = 120, weight = 42,
        defensiveClass = "IMMUNITY", response = "SWAP" },
    [98008] = { name = "Spirit Link Totem", active = 6, cooldown = 174, weight = 34 },

    -- Warlock
    [104773] = { name = "Unending Resolve", active = 8, cooldown = 180, weight = 34 },
    [108416] = { name = "Dark Pact", active = 20, cooldown = 45, weight = 24 },
    [212295] = { name = "Nether Ward", active = 3, cooldown = 45, weight = 20 },

    -- Warrior
    [97462] = { name = "Rallying Cry", active = 10, cooldown = 180, weight = 24 },
    [23920] = { name = "Spell Reflection", active = 5, cooldown = 24, weight = 18 },
    [118038] = { name = "Die by the Sword", active = 8, cooldown = 85, weight = 36 },
    [184364] = { name = "Enraged Regeneration", active = 8, cooldown = 114, weight = 30 },
    [871] = { name = "Shield Wall", active = 8, cooldown = 120, weight = 38 },
    [12975] = { name = "Last Stand", active = 15, cooldown = 180, weight = 28 },
}

local TRINKETS = {
    [42292] = { name = "PvP Trinket", cooldown = 120 },
    [195710] = { name = "Honorable Medallion", cooldown = 180 },
    [208683] = { name = "Gladiator's Medallion", cooldown = 120 },
    [336126] = { name = "Gladiator's Medallion", cooldown = 120 },
}

-- Small, reviewed battlefield-defining catalog. These entries reuse the
-- existing observed-spell pipeline and describe tactical windows only; they
-- do not claim that an unobserved ability is available.
local ABILITIES = {
    [212182] = {
        name = "Smoke Bomb", window = 5, importance = 36,
        tags = { killWindow = true, objectiveThreat = true },
    },
    [359053] = {
        name = "Smoke Bomb", window = 5, importance = 36,
        tags = { killWindow = true, objectiveThreat = true },
    },
    [33786] = {
        name = "Cyclone", window = 6, importance = 28,
        tags = { hardCC = true, captureDenial = true },
    },
    [49576] = {
        name = "Death Grip", window = 3, importance = 24,
        tags = { displacement = true, killSetup = true },
    },
    [78675] = {
        name = "Solar Beam", window = 8, importance = 26,
        tags = { silence = true, captureDenial = true },
    },
    [116844] = {
        name = "Ring of Peace", window = 5, importance = 24,
        tags = { displacement = true, objectiveThreat = true },
    },
}

-- Reviewed casts are presentation hints only. A row is accented only after
-- Blizzard emits a cast/channel event for an attackable player unit. KWR does
-- not infer interruptibility, cooldown readiness, or an unobserved cast.
local PRIORITY_CASTS = {
    [118] = { name = "Polymorph", priority = "MUST_STOP", response = "STOP", duration = 2 },
    [605] = { name = "Mind Control", priority = "MUST_STOP", response = "STOP", duration = 2 },
    [5782] = { name = "Fear", priority = "MUST_STOP", response = "STOP", duration = 1.7 },
    [20066] = { name = "Repentance", priority = "MUST_STOP", response = "STOP", duration = 1.7 },
    [33786] = { name = "Cyclone", priority = "MUST_STOP", response = "STOP", duration = 1.7 },
    [51514] = { name = "Hex", priority = "MUST_STOP", response = "STOP", duration = 1.7 },
    [32375] = { name = "Mass Dispel", priority = "ADVANTAGE", response = "STOP", duration = 1.5 },
    [116858] = { name = "Chaos Bolt", priority = "ADVANTAGE", response = "STOP", duration = 2.5 },
    [198898] = { name = "Song of Chi-Ji", priority = "MUST_STOP", response = "STOP", duration = 1.8 },
    [263165] = { name = "Void Torrent", priority = "ADVANTAGE", response = "STOP", duration = 3 },
    [305483] = { name = "Lightning Lasso", priority = "MUST_STOP", response = "STOP", duration = 5 },
    [360806] = { name = "Sleep Walk", priority = "MUST_STOP", response = "STOP", duration = 1.7 },
    [391528] = { name = "Convoke the Spirits", priority = "ADVANTAGE", response = "STOP", duration = 4 },
    [421453] = { name = "Ultimate Penitence", priority = "ADVANTAGE", response = "STOP", duration = 4 },
}

local HEALER_SPECS = {
    ["discipline"] = true, ["holy"] = true, ["restoration"] = true,
    ["mistweaver"] = true, ["preservation"] = true,
}

local TANK_SPECS = {
    ["blood"] = true, ["protection"] = true, ["guardian"] = true,
    ["brewmaster"] = true, ["vengeance"] = true,
}

function CombatSpells:Get(spellID)
    spellID = KWR.Util:Number(spellID, nil)
    if not spellID then return nil end
    if DEFENSIVES[spellID] then
        local data = KWR.Util:Copy(DEFENSIVES[spellID])
        data.cooldown = KWR.PatchData:Cooldown(spellID, data.cooldown)
        data.kind = "DEFENSIVE"
        data.spellID = spellID
        return data
    end
    if TRINKETS[spellID] then
        local data = KWR.Util:Copy(TRINKETS[spellID])
        data.kind = "TRINKET"
        data.spellID = spellID
        return data
    end
    if ABILITIES[spellID] then
        local data = KWR.Util:Copy(ABILITIES[spellID])
        data.kind = "ABILITY"
        data.spellID = spellID
        return data
    end
end

function CombatSpells:Role(spec, assigned)
    assigned = KWR.Util:Upper(assigned, "", 16)
    if assigned == "TANK" or assigned == "HEALER" or assigned == "DAMAGER" then return assigned end
    local numeric = KWR.Util:Number(assigned, nil)
    if numeric then
        if math.floor(numeric / 4) % 2 == 1 then return "HEALER" end
        if math.floor(numeric / 2) % 2 == 1 then return "TANK" end
        if math.floor(numeric / 8) % 2 == 1 then return "DAMAGER" end
    end
    spec = KWR.Util:Text(spec, "", 32):lower()
    if HEALER_SPECS[spec] then return "HEALER" end
    if TANK_SPECS[spec] then return "TANK" end
    return spec ~= "" and "DAMAGER" or "NONE"
end

function CombatSpells:GetCast(spellID)
    spellID = KWR.Util:Number(spellID, nil)
    local cast = spellID and PRIORITY_CASTS[spellID]
    if not cast then return nil end
    local result = KWR.Util:Copy(cast)
    result.spellID = spellID
    return result
end

function CombatSpells:AllDefensives()
    return DEFENSIVES
end

function CombatSpells:AllAbilities()
    return ABILITIES
end

function CombatSpells:AllPriorityCasts()
    return PRIORITY_CASTS
end

KWR:RegisterModule("CombatSpells", CombatSpells)
