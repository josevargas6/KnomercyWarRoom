local _, KWR = ...

local Compositions = {}
KWR.Compositions = Compositions

local ARCHETYPES = {
    BALANCED = {
        name = "Balanced Team Fight",
        description = "Flexible team fight with enough healing, control, and objective coverage.",
        favorable = { "stable defense", "measured rotations" },
        vulnerable = { "specialized split pressure" },
    },
    STEALTH = {
        name = "Stealth Cross-Cap",
        description = "Creates uneven fights and objective swaps through stealth pressure.",
        favorable = { "node maps", "isolated defenders" },
        vulnerable = { "disciplined scouts", "stacked defense" },
    },
    ROT = {
        name = "Rot / Attrition",
        description = "Wins extended grouped fights through distributed pressure.",
        favorable = { "sustained team fights", "carrier pressure" },
        vulnerable = { "fast rotations", "clean burst windows" },
    },
    MELEE = {
        name = "Melee Collapse",
        description = "Converts mobility and coordinated burst into short kill windows.",
        favorable = { "exposed healers", "tight objective spaces" },
        vulnerable = { "peel", "kiting", "spread control" },
    },
    RANGED = {
        name = "Ranged Control",
        description = "Controls approaches and creates pressure before contact.",
        favorable = { "open approaches", "defensive positions" },
        vulnerable = { "line-of-sight breaks", "high mobility collapse" },
    },
    ROTATION = {
        name = "High-Mobility Rotation",
        description = "Wins through earlier arrivals, cross-map pressure, and disengages.",
        favorable = { "wide node maps", "resource spawns" },
        vulnerable = { "forced bunker fights" },
    },
    BUNKER = {
        name = "Carrier / Objective Bunker",
        description = "Stacks sustain and externals around one scoring unit or position.",
        favorable = { "flag maps", "protectable objectives" },
        vulnerable = { "external cooldown exhaustion", "split pressure" },
    },
}

local function tierComp(id, tier, name, specs, win, assignments, counter, maps)
    return {
        id = id,
        tier = tier,
        name = name,
        specs = specs,
        win = win,
        assignments = assignments,
        counter = counter,
        maps = maps or {},
        source = "USER_REVIEWED_2026_06_29",
    }
end

local TIER_COMPS = {
    tierComp("CONTROL_CLEAVE", "S+", "Control Cleave Commander",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "ROGUE:Subtlety", "HUNTER:Marksmanship", "DEATHKNIGHT:Unholy",
          "MAGE:Frost", "WARLOCK:Affliction" },
        "Chain control into Rogue setups while Balance/Affliction rot and DK grips punish positioning.",
        "Tank anchors; Disc fights; MW floats; Pres saves; Rogue creates kills; DK grips; MM executes; Mage peels.",
        "Split their control pieces, pull Rogue/Mage away from the main fight, and hit the weak objective.",
        { "ARATHI", "GILNEAS", "DEEPWIND", "EOTS", "WSG", "TWINPEAKS", "TEMPLE", "SILVERSHARD", "DEEPHAUL", "SEETHING" }),
    tierComp("NODE_LOCKDOWN", "S+", "Node Lockdown Prime",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "ROGUE:Subtlety", "ROGUE:Outlaw", "HUNTER:Marksmanship",
          "MAGE:Frost", "DEATHKNIGHT:Unholy" },
        "Use double-Rogue pressure and safe ranged sitters to create and hold a three-node map.",
        "Guardian anchors; Rogues rotate; Hunter/Balance defend; Mage delays; DK punishes rotations.",
        "Pair vulnerable sitters, maintain anti-stealth coverage, and refuse fake over-rotations.",
        { "ARATHI", "GILNEAS", "DEEPWIND" }),
    tierComp("MEAT_GRINDER", "S+", "Teamfight Meat Grinder",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "WARRIOR:Arms", "DEATHKNIGHT:Unholy", "HUNTER:Marksmanship",
          "EVOKER:Devastation", "MAGE:Frost" },
        "Win the first decisive teamfight with grip, cleave, and ranged burst, then snowball the objective.",
        "Prot leads; Disc/Pres hold the fight; MW floats; DK/Arms/MM/Dev execute; Balance/Mage control.",
        "Avoid their preferred deathball, trade the map, and force slow rotations.",
        { "GILNEAS", "TEMPLE", "DEEPHAUL" }),
    tierComp("DOUBLE_HUNTER", "S", "Double Hunter Map Control",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "ROGUE:Subtlety", "HUNTER:Marksmanship", "HUNTER:Beast Mastery",
          "DEATHKNIGHT:Unholy", "MAGE:Frost" },
        "Control wide maps with pets, traps, anti-stealth coverage, and ranged pressure.",
        "Hunters defend and peel; Rogue floats; Guardian anchors; DK/Mage set kills; Balance pressures the map.",
        "Train exposed Hunters, force disengages and turtle, then swap into a healer.",
        { "ARATHI", "DEEPWIND", "SEETHING" }),
    tierComp("CASTER_SIEGE", "S", "Caster Siege",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "MAGE:Frost", "WARLOCK:Affliction", "EVOKER:Devastation",
          "SHAMAN:Elemental", "ROGUE:Subtlety" },
        "Own space with rot, slows, ranged control, and a Rogue-created kill window.",
        "Tank protects casters; Disc/Pres hold; MW floats; Rogue creates the kill; casters control mid.",
        "Hard split the map and refuse to fight inside the established caster zone.",
        { "EOTS", "SILVERSHARD", "DEEPHAUL" }),
    tierComp("DK_KILL_BOX", "S", "DK Kill Box",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DEATHKNIGHT:Unholy", "DEATHKNIGHT:Frost", "DRUID:Balance", "HUNTER:Marksmanship",
          "MAGE:Frost", "ROGUE:Subtlety" },
        "Chain grips into coordinated stuns and ranged burst to erase one exposed target.",
        "DKs call grips; Rogue controls the healer; MM/Mage/Balance burst; Guardian carries or anchors.",
        "Spread, pre-position healers, and avoid stacking near ledges or objective circles.",
        { "WSG", "TWINPEAKS", "TEMPLE", "SILVERSHARD" }),
    tierComp("ROGUE_MAP_CHOKE", "S", "Rogue Map Choke",
        { "MONK:Brewmaster", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "ROGUE:Subtlety", "ROGUE:Outlaw", "HUNTER:Marksmanship",
          "WARLOCK:Affliction", "WARRIOR:Arms" },
        "Force bad rotations with double-Rogue objective theft while the ranged core pressures.",
        "Brew/Disc anchor; Rogues split the map; Affliction/Balance rot; Hunter supplies stealth defense.",
        "Pair sitters, keep pets and damage on flags, and do not overreact to fake hits.",
        { "ARATHI", "GILNEAS", "DEEPWIND" }),
    tierComp("ANTI_HEALER", "S", "Anti-Healer Train",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "WARRIOR:Arms", "DEATHKNIGHT:Unholy", "ROGUE:Subtlety", "HUNTER:Marksmanship",
          "DRUID:Balance", "DEMONHUNTER:Havoc" },
        "Stack mortal pressure, grips, stuns, and burst on healers until the objective fight collapses.",
        "DK/Arms/Havoc/Rogue train; MM/Balance assist; healers move with the melee push.",
        "Peel the melee train, drag it off objective, and counterkill the overextended DPS.",
        { "GILNEAS", "TEMPLE" }),
    tierComp("FLAG_SPECIALIST", "S", "Flag Map Specialist",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "ROGUE:Subtlety", "HUNTER:Marksmanship", "MAGE:Frost",
          "DEATHKNIGHT:Unholy", "EVOKER:Devastation" },
        "Keep Guardian alive while Rogue, DK, MM, and Mage create the enemy-carrier kill window.",
        "Guardian carries; MW/Pres support FC; Disc goes offense; Rogue/DK/MM/Mage hunt EFC.",
        "Kill escorts first and force the FC healer's trinket before committing to the carrier.",
        { "WSG", "TWINPEAKS" }),
    tierComp("BLITZ_CONVERSION", "S", "Blitz Conversion Comp",
        { "DEMONHUNTER:Vengeance", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "ROGUE:Subtlety", "HUNTER:Marksmanship", "DEMONHUNTER:Havoc",
          "MAGE:Frost", "DEATHKNIGHT:Unholy" },
        "Win through tempo, first arrival, and rapid weak-side pivots rather than slow objective trades.",
        "VDH moves first; Havoc/Rogue hit weak spots; MW follows; ranged punish late rotations.",
        "Slow the map down, hold strong objectives, and punish their over-rotations.",
        { "TWINPEAKS", "DEEPHAUL", "SEETHING" }),
    tierComp("ENHANCE_BURST", "S-", "Enhance Burst Variant",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "SHAMAN:Enhancement", "WARRIOR:Arms", "ROGUE:Subtlety",
          "HUNTER:Marksmanship", "MAGE:Frost" },
        "Use synchronized melee burst and Shaman utility to close short kill windows.",
        "Enhancement assists the kill and grounds; Arms trains; Rogue controls; ranged protect the setup.",
        "Train Enhancement between cooldowns and force defensive overlap.",
        { "GILNEAS", "TEMPLE" }),
    tierComp("ELEMENTAL_CONTROL", "S-", "Elemental Control Variant",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "SHAMAN:Elemental", "MAGE:Frost", "WARLOCK:Affliction",
          "ROGUE:Subtlety", "DEATHKNIGHT:Unholy" },
        "Apply spread pressure and knock control until Rogue/DK can isolate the kill.",
        "Elemental/Mage/Balance/Affliction control zones; Rogue attacks sitters; Guardian anchors.",
        "Avoid ledges and chokes; split pressure and force the casters to move.",
        { "EOTS", "SILVERSHARD" }),
    tierComp("TRIPLE_RANGED", "S-", "Triple Ranged Hammer",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "HUNTER:Marksmanship", "HUNTER:Beast Mastery", "MAGE:Frost",
          "EVOKER:Devastation", "ROGUE:Subtlety" },
        "Control lanes with layered ranged pressure while Rogue manages the weak objective.",
        "Rogue floats; ranged control lanes; tank anchors; healers maintain the firing line.",
        "Hard engage one ranged player, force the line backward, and cap behind the retreat.",
        { "EOTS", "SILVERSHARD", "DEEPHAUL" }),
    tierComp("MELEE_COLLAPSE", "S-", "Melee Collapse",
        { "MONK:Brewmaster", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "WARRIOR:Arms", "WARRIOR:Fury", "DEATHKNIGHT:Unholy", "DEMONHUNTER:Havoc",
          "ROGUE:Subtlety", "DRUID:Balance" },
        "Collapse the entire melee core onto one target and finish before peel stabilizes it.",
        "Melee stack the call; Rogue controls healer; Balance supports; Brew holds the front.",
        "Kite, root, knock, and trade objectives instead of accepting a tight-space brawl.",
        { "TEMPLE", "GILNEAS" }),
    tierComp("AFFLICTION_ROT", "S-", "Affliction Rot Core",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "WARLOCK:Affliction", "DRUID:Balance", "MAGE:Frost", "DEATHKNIGHT:Unholy",
          "HUNTER:Marksmanship", "ROGUE:Subtlety" },
        "Win long holds through distributed pressure and healer mana exhaustion.",
        "Affliction/Balance spread rot; DK/Mage peel; Rogue stops caps; Guardian anchors.",
        "Make fast swaps and hard kills; never allow Affliction to free-cast.",
        { "ARATHI", "GILNEAS", "DEEPWIND" }),
    tierComp("DEV_BURST", "S-", "Dev Evoker Burst Map",
        { "WARRIOR:Protection", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "EVOKER:Devastation", "HUNTER:Marksmanship", "DRUID:Balance", "MAGE:Frost",
          "ROGUE:Subtlety", "WARRIOR:Arms" },
        "Create sudden ranged burst windows against scattered or rotating teams.",
        "Dev/MM/Balance burst; Rogue controls; Arms follows; Pres stabilizes.",
        "Track burst windows, line Dev/MM, and pressure them between goes.",
        { "EOTS", "DEEPHAUL", "SEETHING" }),
    tierComp("RET_UTILITY", "A+ / S-", "Ret Utility Variant",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "PALADIN:Retribution", "WARRIOR:Arms", "DRUID:Balance", "HUNTER:Marksmanship",
          "ROGUE:Subtlety", "MAGE:Frost" },
        "Convert blessings, burst, and protection utility into safer objective kills.",
        "Ret protects FC/healers; Arms trains; Rogue floats; ranged maintain control.",
        "Bait blessings, swap after utility, and do not tunnel protected targets.",
        { "WSG", "TWINPEAKS", "GILNEAS" }),
    tierComp("FERAL_STEALTH", "A+ / S-", "Feral Stealth Pressure",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Feral", "ROGUE:Subtlety", "DRUID:Balance", "HUNTER:Marksmanship",
          "MAGE:Frost", "DEATHKNIGHT:Unholy" },
        "Use paired stealth pressure and bleeds to create weak-node advantages.",
        "Feral/Rogue attack bases; Guardian anchors; DK/MM/Mage form the kill team.",
        "Use anti-stealth sitters and keep damage on the stealth attackers.",
        { "ARATHI", "GILNEAS", "DEEPWIND" }),
    tierComp("DH_DISRUPTION", "A+", "Demon Hunter Disruption",
        { "DEMONHUNTER:Vengeance", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DEMONHUNTER:Havoc", "DEMONHUNTER:Devourer", "DRUID:Balance",
          "HUNTER:Marksmanship", "ROGUE:Subtlety", "MAGE:Frost" },
        "Win through mobility, backline disruption, and rapid chaos pivots.",
        "VDH/Havoc/Devourer disrupt; Rogue attacks weak objectives; ranged finish exposed targets.",
        "Root and slow the Demon Hunters, deny resets, and punish over-dives.",
        { "TWINPEAKS", "DEEPHAUL", "SEETHING" }),
    tierComp("PUG_FRIENDLY", "A+", "PUG-Friendly S Shell",
        { "DRUID:Guardian", "PRIEST:Discipline", "MONK:Mistweaver", "EVOKER:Preservation",
          "DRUID:Balance", "HUNTER:Marksmanship", "HUNTER:Beast Mastery",
          "DEATHKNIGHT:Unholy", "MAGE:Frost", "ROGUE:Subtlety" },
        "Win with simple, explicit jobs, strong ranged pressure, and safe objective assignments.",
        "Guardian anchors; Disc fights; MW floats; Pres saves; Rogue floats; Balance/Hunters defend; DK/Mage kill.",
        "Pressure the weakest sitter and force communication-heavy rotations.",
        { "ARATHI", "GILNEAS", "DEEPWIND", "EOTS", "WSG", "TWINPEAKS", "TEMPLE", "SILVERSHARD", "DEEPHAUL", "SEETHING" }),
}

local TIER_ORDER = {
    ["S+"] = 5,
    ["S"] = 4,
    ["S-"] = 3,
    ["A+ / S-"] = 2,
    ["A+"] = 1,
}

local function amount(summary, tag)
    return summary and summary.tags and summary.tags[tag] or 0
end

function Compositions:Detect(summary)
    summary = summary or { tags = {} }
    local scores = {
        BALANCED = 20 + math.min(summary.healers or 0, 3) * 5,
        STEALTH = amount(summary, "stealth") * 14 + amount(summary, "crossCap") * 10,
        ROT = amount(summary, "rot") * 15 + amount(summary, "sustain") * 4,
        MELEE = (summary.melee or 0) * 8 + amount(summary, "burst") * 5,
        RANGED = (summary.ranged or 0) * 8 + amount(summary, "control") * 4,
        ROTATION = amount(summary, "mobility") * 7 + amount(summary, "rotation") * 9,
        BUNKER = amount(summary, "flagCarry") * 18 + amount(summary, "external") * 8
            + amount(summary, "sustain") * 4,
    }
    local ranked = {}
    for id, score in pairs(scores) do ranked[#ranked + 1] = { id = id, score = score } end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.id < b.id
    end)
    local best = ranked[1] or { id = "BALANCED", score = 0 }
    return {
        id = best.id,
        name = ARCHETYPES[best.id].name,
        score = best.score,
        ranked = ranked,
        description = ARCHETYPES[best.id].description,
        coverage = summary.coverage or 0,
    }
end

local function specKey(entity)
    local classFile = KWR.Util:Upper(entity and entity.classFile, "", 24)
    local spec = KWR.Util:Text(entity and entity.spec, "", 32)
    if classFile == "" or spec == "" or spec == "Unknown" or spec == "Unknown spec" then
        return nil
    end
    return classFile .. ":" .. spec:lower()
end

local function countSpecs(values)
    local counts = {}
    for _, value in ipairs(values or {}) do
        local key
        if type(value) == "table" then
            key = specKey(value)
        else
            local classFile, spec = tostring(value):match("^([^:]+):(.+)$")
            key = classFile and (classFile:upper() .. ":" .. spec:lower()) or nil
        end
        if key then counts[key] = (counts[key] or 0) + 1 end
    end
    return counts
end

local function containsMap(comp, mapKey)
    for _, candidate in ipairs(comp.maps or {}) do
        if candidate == mapKey then return true end
    end
    return false
end

local function tierWeight(tier)
    return TIER_ORDER[tier] or 0
end

local function worldContext(mapKey)
    return mapKey == nil or mapKey == "" or mapKey == "WORLD"
end

function Compositions:MatchTier(roster, mapKey)
    local actual = countSpecs(roster)
    local known = 0
    for _, count in pairs(actual) do known = known + count end
    if known == 0 then return nil end
    local best
    for _, comp in ipairs(TIER_COMPS) do
        local wanted = countSpecs(comp.specs)
        local matched, missing = 0, {}
        for key, count in pairs(wanted) do
            local have = actual[key] or 0
            matched = matched + math.min(have, count)
            if have < count then
                missing[#missing + 1] = key .. (count - have > 1 and (" x" .. (count - have)) or "")
            end
        end
        local score = matched / #comp.specs
        local mapFit = not mapKey or mapKey == "WORLD" or containsMap(comp, mapKey)
        local candidate = {
            id = comp.id,
            tier = comp.tier,
            name = comp.name,
            win = comp.win,
            assignments = comp.assignments,
            counter = comp.counter,
            maps = KWR.Util:Copy(comp.maps),
            source = comp.source,
            matched = matched,
            known = known,
            total = #comp.specs,
            score = score,
            mapFit = mapFit,
            missing = missing,
            exact = #roster == #comp.specs and known == #comp.specs and matched == #comp.specs,
        }
        candidate.qualified = #roster == #comp.specs and known >= 8 and score >= 0.8
        candidate.confidence = candidate.exact and "EXACT"
            or (candidate.qualified and "LIKELY" or "PARTIAL")
        if not best or candidate.matched > best.matched
            or (candidate.matched == best.matched and candidate.mapFit and not best.mapFit)
            or (candidate.matched == best.matched and candidate.mapFit == best.mapFit
                and candidate.id < best.id) then
            best = candidate
        end
    end
    return best
end

function Compositions:TierAll()
    return TIER_COMPS
end

function Compositions:FindTier(id)
    for _, comp in ipairs(TIER_COMPS) do
        if comp.id == id then
            return KWR.Util:Copy(comp)
        end
    end
end

function Compositions:BuildTargets(mapKey)
    local targets = {}
    local useWorldContext = worldContext(mapKey)
    for _, comp in ipairs(TIER_COMPS) do
        local candidate = KWR.Util:Copy(comp)
        candidate.mapFit = useWorldContext or containsMap(comp, mapKey)
        candidate.mapCount = #(comp.maps or {})
        targets[#targets + 1] = candidate
    end
    table.sort(targets, function(a, b)
        if a.mapFit ~= b.mapFit then return a.mapFit end
        if tierWeight(a.tier) ~= tierWeight(b.tier) then
            return tierWeight(a.tier) > tierWeight(b.tier)
        end
        if a.mapCount ~= b.mapCount then return a.mapCount > b.mapCount end
        return a.id < b.id
    end)
    return targets
end

function Compositions:Get(id)
    return ARCHETYPES[id]
end

function Compositions:All()
    return ARCHETYPES
end

KWR:RegisterModule("Compositions", Compositions)