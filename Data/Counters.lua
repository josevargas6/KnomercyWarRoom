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

local TIER_DATA = {
    CONTROL_CLEAVE = {
        emphasis = "Break their control cadence by forcing the fight wide, then kill the exposed healer or mage after the first peel chain.",
        avoid = "Do not let Control Cleave stage the whole fight on one flag or in one choke.",
        sequence = {
            "Spread support lines so one fear / grip / stun chain cannot catch everyone.",
            "Name the control piece to peel first, then call the healer swap once trinket or mobility is gone.",
            "If their setup resets clean, rotate before the next full control cycle.",
        },
        success = "Their control chain lands on too few players to create a clean kill window.",
    },
    NODE_LOCKDOWN = {
        emphasis = "Keep anti-stealth coverage planted and trade into the lane their Rogues or floaters abandoned.",
        avoid = "Do not leave isolated sitters uncovered just to mirror every nuisance hit.",
        sequence = {
            "Track the two weakest defenders and reinforce them before the stealth package arrives.",
            "Use pets, dots, and paired defenders to deny the clean sap-cap chain.",
            "Counterpressure the node that lost real coverage while they float for the next steal.",
        },
        success = "Their cross-cap package is forced to reveal before any isolated node flips.",
    },
    MEAT_GRINDER = {
        emphasis = "Do not accept the front-door brawl; force their melee stack to travel and peel the first collapse before counterkilling.",
        avoid = "Do not stack healers and ranged on the same objective pixel.",
        sequence = {
            "Fight from wide lines and make the melee core cross slows, roots, and knockback before connecting.",
            "Peel the first hard engage instead of racing damage into their preferred kill box.",
            "Once movement tools are spent, counterburst the overextended attacker or abandon the deathball lane.",
        },
        success = "They never get full-value cleave on your whole support line at once.",
    },
    FLAG_SPECIALIST = {
        emphasis = "Protect your own route first, then build one fully synchronized return with healer control and route denial together.",
        avoid = "Do not trickle offense into a set bunker while your FC loses peel.",
        sequence = {
            "Name the carrier shell, route denial group, and return wave separately.",
            "Force externals or trinkets on the escort before committing to the carrier kill.",
            "Push the return only when your FC remains safe through the same window.",
        },
        success = "Their carrier bunker loses either escort depth or safe route control before your FC does.",
    },
    BLITZ_CONVERSION = {
        emphasis = "Slow the map down and make every fast rotation run into a planted defender or prepared crossfire lane.",
        avoid = "Do not chase the first ping and let the second arrival decide the map.",
        sequence = {
            "Plant the minimum safe defense at the score floor objective.",
            "Track the likely second move, not the first show of motion.",
            "Trade into the lane they vacated after the speed package commits.",
        },
        success = "Their mobility spends time instead of instantly changing the score path.",
    },
    DOUBLE_HUNTER = {
        emphasis = "Respect their ranged coverage, deny isolated sitter pressure, and force one Hunter to play defensively instead of freely scouting the whole map.",
        avoid = "Do not leave solo defenders exposed to pet, trap, and flare control without a response path.",
        sequence = {
            "Pair the weakest sitter and keep anti-stealth or anti-cap coverage active.",
            "Pressure one Hunter between turtle and disengage windows instead of accepting double free-cast lanes.",
            "Once one ranged anchor is displaced, break the objective they were stabilizing.",
        },
        success = "Their double ranged shell is forced to defend itself instead of controlling every lane.",
    },
    CASTER_SIEGE = {
        emphasis = "Use line of sight, fast collapses, and objective trades to deny free setup space.",
        avoid = "Do not walk into open ground in separate waves while they are already planted.",
        sequence = {
            "Approach from cover or through offset lanes, not one exposed bridge.",
            "Collapse on the ranged anchor or healer once the peel layer is spent.",
            "If the kill window fails, rotate off the planted caster zone instead of feeding another cycle.",
        },
        success = "Their core loses uninterrupted sight on the scoring objective.",
    },
    ROGUE_MAP_CHOKE = {
        emphasis = "Pair sitters, keep anti-stealth effects rolling, and refuse false panic rotations.",
        avoid = "Do not send both response players to the same fake opener.",
        sequence = {
            "Call which node is truly vulnerable and keep a second body there before the stealth vanish window.",
            "Force reveals with dots, pets, and paired coverage.",
            "Punish the lane their float group abandoned once the sap-cap line is denied.",
        },
        success = "Their Rogues spend cooldowns revealing pressure instead of securing free objectives.",
    },
    ANTI_HEALER = {
        emphasis = "Peel the train off your healers and counterpressure the exposed DPS instead of racing into their preferred target swap.",
        avoid = "Do not let every healer share the same melee access lane.",
        sequence = {
            "Pre-position healers on separate angles and assign one peel body to each likely collapse path.",
            "When the train commits, peel first and only then call the swap target.",
            "If they overextend without a kill, immediately counterburst the deepest attacker.",
        },
        success = "Their anti-healer train spends cooldowns surviving instead of finishing the support line.",
    },
    ENHANCE_BURST = {
        emphasis = "Track their synchronized melee burst window, peel the first connector, and counterpressure Enhancement once grounding or utility is spent.",
        avoid = "Do not overlap every defensive into their first fake go.",
        sequence = {
            "Pre-position healers and peelers on separate lines so one burst push cannot catch both.",
            "Trade the first wave of cooldowns, then counterburst the Enhancement or overextended train piece.",
            "If their cooldown cycle resets clean, disengage the neutral brawl and change the lane.",
        },
        success = "Their burst windows trade down in value while your counterkill window grows after the first go.",
    },
    ELEMENTAL_CONTROL = {
        emphasis = "Break line of sight, deny knockback terrain, and force the Elemental shell to move before accepting a full fight.",
        avoid = "Do not stand on ledges, bridges, or objective edges where their displacement control is highest value.",
        sequence = {
            "Approach from safer angles and force the Elemental core to split its knock or root usage.",
            "Once their control package is spent, collapse the exposed ranged anchor or healer.",
            "Reposition immediately after the kill window closes so they cannot reset the same zone.",
        },
        success = "Their control zone never gets to repeat on the same terrain with the same setup.",
    },
    TRIPLE_RANGED = {
        emphasis = "Shorten the fight, use cover, and force one ranged damage source off the firing line before committing fully.",
        avoid = "Do not walk in waves through open ground while all three ranged anchors still have clean sight.",
        sequence = {
            "Move through cover or staggered approach lines until one ranged player is isolated or displaced.",
            "Collapse that isolated target with hard peel on the remaining firing line.",
            "Either convert immediately or rotate off before the full ranged shell resets.",
        },
        success = "Their ranged line loses uninterrupted overlap before it can control the objective fight.",
    },
    MELEE_COLLAPSE = {
        emphasis = "Break the first collapse with peel and spacing, then punish the attacker who outruns their healer line.",
        avoid = "Do not accept a tight stacked brawl on the exact objective pixel they want.",
        sequence = {
            "Spread the support line before the melee wave lands so one stun chain cannot catch everyone.",
            "Peel the first connector instead of racing damage into their preferred engage.",
            "Counterkill the deepest melee once mobility is spent or trade the map if the fight shape stays bad.",
        },
        success = "Their collapse hits a partial target package instead of the full objective group.",
    },
    DK_KILL_BOX = {
        emphasis = "Keep wide spacing around objectives and never let the grip chain happen on your full support package.",
        avoid = "Do not stack near ledges, flags, carts, or orb carriers when grip tools are ready.",
        sequence = {
            "Spread the support line before entering their known setup zone.",
            "Track the first grip or stun commitment and peel the second connector immediately.",
            "Once the box fails, counterpressure the grip caller or rotate away from the setup terrain.",
        },
        success = "Their kill box catches one body instead of the entire objective group.",
    },
    AFFLICTION_ROT = {
        emphasis = "Do not donate a long neutral fight; build one sharp kill window or leave the lane before rot becomes the win condition.",
        avoid = "Do not stack and heal forever on a point that is not currently scoring for you.",
        sequence = {
            "Identify the fastest kill target and pre-control the recovery tools around it.",
            "Commit burst inside a short window before mana and spread pressure become the whole fight.",
            "If the burst fails, rotate or reset instead of soaking another full rot cycle.",
        },
        success = "The fight either ends quickly or relocates before rot pressure owns your healer resources.",
    },
    DEV_BURST = {
        emphasis = "Respect their sudden ranged spike, track when it is loaded, and use line or pressure timing to force it into bad targets.",
        avoid = "Do not stand exposed while the Devastation burst package and its setup partners are all ready together.",
        sequence = {
            "Spread targets and deny the easiest front-loaded burst connection.",
            "Pressure the Evoker or its setup partner between burst windows so their next go is defensive.",
            "Once their spike is committed or traded poorly, counterkill immediately.",
        },
        success = "Their burst cadence is spent stabilizing instead of cleanly converting a kill.",
    },
    RET_UTILITY = {
        emphasis = "Bait blessings and externals first, then swap or recommit once the protection layer is gone.",
        avoid = "Do not tunnel through obvious blessing coverage or protected targets.",
        sequence = {
            "Force the first utility response with controlled pressure, not the full commit.",
            "Swap or recommit into the exposed target after blessing or sac timing is spent.",
            "If utility resets clean, rotate away from the protected lane and score elsewhere.",
        },
        success = "Their utility saves one window instead of endlessly invalidating your kill calls.",
    },
    FERAL_STEALTH = {
        emphasis = "Pair weak sitters, keep passive damage on the lane, and deny the bleed-and-disappear pressure pattern before it snowballs.",
        avoid = "Do not let one defender eat the whole bleed opener without a nearby second body.",
        sequence = {
            "Plant anti-stealth coverage and one fast response at the most isolated node.",
            "Keep damage and reveal pressure rolling so stealth cannot reset freely after the opener.",
            "Counterpressure the objective they vacated when the stealth package is forced defensive.",
        },
        success = "Their stealth package reveals itself for pressure without getting a free reset or cap chain.",
    },
    DH_DISRUPTION = {
        emphasis = "Control their movement angles, deny easy resets, and punish over-dives rather than chasing every leap.",
        avoid = "Do not let the Demon Hunter package drag the whole team away from the score floor objective.",
        sequence = {
            "Keep the real scoring objective dressed and let only the named peel bodies answer the dive.",
            "Root, slow, and line the disruptors until their mobility is spent.",
            "Counterkill the deepest diver or trade the map behind their over-rotation.",
        },
        success = "Their disruption creates movement but not meaningful score gain.",
    },
    PUG_FRIENDLY = {
        emphasis = "Use the simplest score path, explicit assignments, and short travel routes that reduce confusion.",
        avoid = "Do not rely on multi-stage fake pressure or silent swaps.",
        sequence = {
            "Choose the score floor objective and state who sits, who floats, and who strikes.",
            "Prefer the safer conversion over the more creative one if both score similarly.",
            "When the first plan breaks, regroup fast and rebuild one clear lane instead of broad improvisation.",
        },
        success = "The enemy is forced to solve a clear, stable map instead of exploiting your confusion.",
    },
}

local function copyCounter(counter)
    return {
        emphasis = counter.emphasis,
        avoid = counter.avoid,
        sequence = KWR.Util:Copy(counter.sequence or {}),
        success = counter.success,
        source = counter.source,
        confidence = counter.confidence,
    }
end

function Counters:Get(archetype, tier)
    local tierID = type(tier) == "table" and tier.id or tier
    local tierCounter = tierID and TIER_DATA[tierID]
    if tierCounter then
        local result = copyCounter(tierCounter)
        if type(tier) == "table" then
            result.source = tier.source or "USER_REVIEWED_2026_06_29"
            result.confidence = tier.confidence or "HIGH"
            result.tier = tier.id
            result.tierName = tier.name
            local emphasis = KWR.Util:Text(tier.counter, "", 240)
            if emphasis ~= "" then result.emphasis = emphasis end
        else
            result.source = "USER_REVIEWED_2026_06_29"
            result.confidence = "HIGH"
            result.tier = tierID
        end
        return result
    end
    local result = copyCounter(DATA[archetype] or DATA.BALANCED)
    if type(tier) == "table" and tier.qualified then
        result.emphasis = tier.counter or result.emphasis
        result.avoid = "Do not let " .. (tier.name or tier.id or "the enemy comp") .. " execute: "
            .. (tier.win or result.avoid or "its preferred win path.")
        result.source = tier.source or result.source
        result.confidence = tier.confidence or result.confidence or "HIGH"
        result.tier = tier.id
        result.tierName = tier.name
    end
    return result
end

function Counters:Count()
    local count = 0
    for _ in pairs(DATA) do count = count + 1 end
    for _ in pairs(TIER_DATA) do count = count + 1 end
    return count
end

KWR:RegisterModule("Counters", Counters)