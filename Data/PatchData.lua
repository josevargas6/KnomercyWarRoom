local _, KWR = ...

local PatchData = {
    activePatch = "12.1.0",
}
KWR.PatchData = PatchData

-- New patches should add or replace a data pack here. Runtime engines consume
-- the normalized pack and do not require strategy code rewrites.
local PACKS = {
    -- The installed Retail client is 12.1.0. The official Season 2 schedule
    -- and PvP hotfix ledger have been reviewed, but no numerical capability
    -- overlay is inferred from directional tuning. Static ladder/meta data is
    -- freshness-gated separately by KnowledgeManifest.
    ["12.1.0"] = {
        interface = 120100,
        season = "Midnight Season 2",
        captured = "2026-08-27",
        officialHotfixReviewed = "2026-08-26",
        source = "BLIZZARD_HOTFIXES",
        reviewed = true,
        cooldowns = {},
        capabilities = {},
        disabledPlans = {},
        hotfixWatchlist = {
            status = "OFFICIAL_UNMODELED",
            effectiveDate = "2026-08-26",
            source = "Blizzard official hotfix notes",
            sourceURL = "https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-august-26-2026",
            policy = "Advisory only. KWR does not alter capability ratings, predictions, or doctrine until player-reviewed Retail evidence supports a bounded update.",
            affected = {
                "Will of the Forsaken: PvP trinket cooldown display corrected after breaking Mind Control",
                "Demon Hunter: Demon Muzzle and Glimpse mitigation reduced in PvP",
                "Mistweaver Monk: Way of the Crane clumped-target healing reduced in PvP",
                "Discipline and Holy Priest: PvP healing increased; Holy Fire damage increased for Holy",
                "Restoration Shaman: Riptide healing increased in PvP",
                "August 13: Gorgoneion Gaze no longer petrifies indefinitely; Sparks of War correction",
                "August 18: PvP trinket set primary stat is 20% for damage dealers and tanks (was 15%)",
                "August 18: Devourer Fury, Restoration Druid, Fire Mage, Holy/Retribution Paladin, Restoration Shaman, and Destruction tuning reviewed",
                "August 19: Conqueror's Venomous Lacquer now applies PvP item level to tier shoulders",
                "August 17-20 class mechanics fixes are recorded for field observation, not inferred as cooldown or capability changes",
                "August 25: direct PvP tuning affects Demon Hunter, Druid, Evoker, Hunter, Mage, Monk, Paladin, Priest, Rogue, Shaman, Warlock, and Warrior specializations",
                "August 26: Training Grounds Arena matches now end when game-controlled opponents surrender; this is lifecycle evidence only, not an RBG rules or capability change",
            },
        },
        seasonPrepCorpus = {
            active = true,
            mode = "IMMEDIATE_THEORY_FIRST",
            activationAuthority = "USER_APPROVED_2026_08_17",
            requiresRetailValidation = true,
        },
        notes = {
            "12.1 Season 2 compatibility and theory-first branch selection are active.",
            "Blizzard schedules PvP Season 2 for 2026-08-18 and confirms two weapon tokens at 2,500 Conquest.",
            "Official PvP hotfix notes were reviewed through 2026-08-26; direct class tuning and Training Grounds lifecycle corrections remain advisory and do not invent numerical capability weights.",
            "August 18 PvP tuning is a field-observation watch, not a capability, cooldown, or target-priority override.",
            "August 17-20 class mechanics fixes require observed Retail behavior before KWR changes any spell or cooldown interpretation.",
            "August 25 direct PvP class tuning is acknowledged, but no cooldown, capability, target-priority, or doctrine override is inferred without reviewed Retail evidence.",
            "The August 26 Training Grounds surrender correction is lifecycle evidence only and does not alter RBG objectives, capabilities, target priority, or doctrine.",
            "The Will of the Forsaken PvP-trinket display change is presentation evidence only; KWR never invents or starts a trinket cooldown without observing the trinket itself.",
            "The 12.0.7 static ladder snapshot remains excluded from Season 2 meta influence until a separately reviewed 12.1 snapshot exists.",
            "Season-preparation gearing, simulation cases, and provisional compositions still require Retail validation before stable strategic certification.",
        },
    },
    ["12.0.7"] = {
        interface = 120007,
        season = "Midnight Season 1",
        captured = "2026-06-30",
        officialHotfixReviewed = "2026-06-22",
        source = "BLIZZARD_HOTFIXES",
        reviewed = true,
        cooldowns = {},
        capabilities = {
            ["DEMONHUNTER:devourer"] = {
                ratings = { burst = 4, killConfirm = 4 },
            },
            ["DRUID:balance"] = {
                ratings = { burst = 4, killConfirm = 4 },
            },
            ["HUNTER:beast mastery"] = {
                ratings = { pressure = 4 },
            },
            ["HUNTER:marksmanship"] = {
                ratings = { burst = 4, pressure = 3, killConfirm = 4 },
            },
            ["MAGE:arcane"] = {
                ratings = { burst = 4 },
            },
            ["MAGE:fire"] = {
                ratings = { burst = 4, pressure = 4 },
            },
            ["MAGE:frost"] = {
                ratings = { pressure = 3, ccPotential = 5 },
            },
            ["MONK:brewmaster"] = {
                ratings = { pressure = 2 },
            },
            ["PALADIN:holy"] = {
                ratings = { manaEndurance = 4, recovery = 4 },
            },
            ["PRIEST:shadow"] = {
                ratings = { burst = 4, killConfirm = 4 },
            },
            ["ROGUE:outlaw"] = {
                ratings = { burst = 3, pressure = 3 },
            },
            ["SHAMAN:restoration"] = {
                ratings = { recovery = 5 },
            },
            ["WARLOCK:destruction"] = {
                ratings = { burst = 4, pressure = 4 },
            },
        },
        disabledPlans = {},
        seasonPrepCorpus = {
            active = true,
            mode = "ADVISORY",
            activationAuthority = "USER_APPROVED_ALPHA40",
            requiresRetailValidation = true,
        },
        notes = {
            "Midnight secret-value safety enabled.",
            "Defensive baseline reviewed against field-tested PvP addons.",
            "Arathi and Deepwind standard/Blitz resource rates reviewed 2026-06-28.",
            "Eye of the Storm Blitz uses the Midnight restored four-base scoring model.",
            "Official PvP tuning and battleground-entry behavior reviewed through the 2026-06-22 Blizzard hotfix notes.",
            "The global Gladiator's Distinction stamina increase is documented but does not distort relative specialization scoring.",
            "Guardian Wild Guardian is cleared on battleground entry; formation logic never assumes a pre-stacked effect.",
        },
    },
}

function PatchData:Get()
    return PACKS[self.activePatch]
end

function PatchData:Cooldown(spellID, fallback)
    local pack = self:Get()
    return pack and pack.cooldowns[spellID] or fallback
end

function PatchData:Capability(key)
    local pack = self:Get()
    return pack and pack.capabilities[key]
end

function PatchData:PlanEnabled(planID)
    local pack = self:Get()
    return not (pack and pack.disabledPlans[planID])
end

function PatchData:SeasonPrepCorpusActive()
    local pack = self:Get()
    return pack and pack.seasonPrepCorpus and pack.seasonPrepCorpus.active == true
end

function PatchData:SeasonPrepCorpusMode()
    local pack = self:Get()
    return pack and pack.seasonPrepCorpus and pack.seasonPrepCorpus.mode or "DISABLED"
end

function PatchData:HotfixWatchlist()
    local pack = self:Get()
    return pack and pack.hotfixWatchlist or nil
end

function PatchData:Validate(interface)
    local pack = self:Get()
    return pack and pack.reviewed == true and pack.interface == interface
end

KWR:RegisterModule("PatchData", PatchData)
