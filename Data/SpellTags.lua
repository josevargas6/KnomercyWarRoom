local _, KWR = ...

local SpellTags = {
    semanticOnly = true,
    tags = {
        control = "Player-selected control or disruption tool.",
        subdue = "Player-selected single-target stop.",
        pressure = "Player-selected damage commitment.",
        deny = "Player-selected objective denial.",
        peel = "Player-selected friendly protection.",
    },
}

KWR.SpellTags = SpellTags
KWR:RegisterModule("SpellTags", SpellTags)