local _, KWR = ...

local Counters = {}
KWR.Counters = Counters

local DATA = {
    BALANCED = {
        emphasis = "Create a specific numbers or timing advantage instead of mirroring every fight.",
        avoid = "Do not accept equal fights on every objective.",
        sequence = {
            "Show enough players to hold their main group.",
            "Create a one-player advantage at the scoring objective.",
            "Convert the advantage, plant coverage, and leave before reinforcement.",
        },
        success = "One scoring objective changes without exposing the held requirement.",
    },
    STEALTH = {
        emphasis = "Keep scouts planted, confirm replacements, and call missing stealth pressure early.",
        avoid = "Do not leave isolated defenders without a response path.",
        sequence = {
            "Track missing stealth classes and protect the most isolated sitter.",
            "Force stealth reveals with paired coverage and safe spacing.",
            "Counterpressure the objective their stealth group abandoned.",
        },
        success = "Stealth pressure is revealed before the capture-control chain begins.",
    },
    ROT = {
        emphasis = "Shorten fights with coordinated burst or rotate away from their sustained pressure.",
        avoid = "Do not remain in a long neutral team fight that does not score.",
        sequence = {
            "Identify the shortest kill window and pre-control recovery tools.",
            "Commit burst together before rot pressure compounds.",
            "Disengage or rotate immediately if the kill window closes.",
        },
        success = "The fight ends or relocates before sustained pressure controls healer mana.",
    },
    MELEE = {
        emphasis = "Spread approaches, layer peel, and force the collapse through control before committing.",
        avoid = "Do not stack vulnerable healers in one melee connection point.",
        sequence = {
            "Spread healers and ranged across separate approach lines.",
            "Root, displace, and peel the first melee connection.",
            "Counterburst the isolated attacker after movement tools are spent.",
        },
        success = "Melee cannot maintain simultaneous contact on the same support line.",
    },
    RANGED = {
        emphasis = "Use line of sight and high-mobility collapse to deny free opening pressure.",
        avoid = "Do not walk through open ground in separate waves.",
        sequence = {
            "Approach through cover as one timed wave.",
            "Collapse on the exposed ranged anchor or healer.",
            "Rotate behind line of sight before their free-cast pattern resets.",
        },
        success = "Their ranged formation loses uninterrupted sight on the scoring area.",
    },
    ROTATION = {
        emphasis = "Defend the real scoring requirement and punish their lightly held objective.",
        avoid = "Do not chase rotations that have already disengaged.",
        sequence = {
            "Name the objective that must remain held.",
            "Track their rotation destination instead of following the road.",
            "Trade into the lightly held objective and replant defenders.",
        },
        success = "Their movement spends time without improving their scoring clock.",
    },
    BUNKER = {
        emphasis = "Create split pressure, force visible defensive reactions, and swap when the bunker overcommits.",
        avoid = "Do not repeat the same attack into a stable bunker without changing pressure or numbers.",
        sequence = {
            "Threaten two scoring lanes so the bunker must reveal coverage.",
            "Force a major defensive without overcommitting the full team.",
            "Swap to the exposed lane during the defensive recovery window.",
        },
        success = "The bunker loses either defensive cooldown depth or objective coverage.",
    },
}

function Counters:Get(archetype)
    return DATA[archetype] or DATA.BALANCED
end

function Counters:Count()
    local count = 0
    for _ in pairs(DATA) do count = count + 1 end
    return count
end

KWR:RegisterModule("Counters", Counters)
