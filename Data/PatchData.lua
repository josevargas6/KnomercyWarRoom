local _, KWR = ...

local PatchData = {
    activePatch = "12.0.7",
}
KWR.PatchData = PatchData

-- New patches should add or replace a data pack here. Runtime engines consume
-- the normalized pack and do not require strategy code rewrites.
local PACKS = {
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

function PatchData:Validate(interface)
    local pack = self:Get()
    return pack and pack.reviewed == true and pack.interface == interface
end

KWR:RegisterModule("PatchData", PatchData)
