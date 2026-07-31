local _, KWR = ...

local Doctrine = {}
KWR.Doctrine = Doctrine

local doctrine = {
    ARATHI = {
        win = "Keep three defenders planted and float toward the first incoming assault.",
        even = "Create a three-base edge through Blacksmith or the weak outer node.",
        lose = "Group the strike team; cross-cap before the enemy clock becomes safe.",
        emergency = "Take four or interrupt scoring immediately. Do not feed staggered fights.",
        stop = "Do not abandon two stable nodes for a road chase.",
    },
    GILNEAS = {
        win = "Hold two, scout the enemy exit, and avoid the Waterworks trap.",
        even = "Pressure the weak side with one coordinated strike.",
        lose = "CC the spinner and capture; kills away from the flag do not recover the game.",
        emergency = "Three-cap or stop enemy scoring now.",
        stop = "Do not grind indefinitely into Waterworks sustain.",
    },
    DEEPWIND = {
        win = "Defend three and keep one mobile response group.",
        even = "Attack the ghosted side; avoid splitting into equal losing fights.",
        lose = "Create a coordinated base swing through Market or the weak flank.",
        emergency = "Take four or interrupt the scoring clock immediately.",
        stop = "Do not leave a stable defender without a replacement.",
    },
    EOTS = {
        win = "Stabilize towers before investing heavily in the flag.",
        even = "Win the next tower swing; take flag only at useful tower value.",
        lose = "Towers first. A low-value flag does not repair a tower deficit.",
        emergency = "Create a tower swing now; use the flag only if it changes the score path.",
        stop = "Do not tunnel the flag while losing tower control.",
    },
    WSG = {
        win = "Protect our carrier and preserve a clean return team.",
        even = "Coordinate EFC pressure with healer control; keep peel on our carrier.",
        lose = "Group on the enemy carrier and convert the next return into a cap.",
        emergency = "Kill EFC now. Random mid kills no longer matter.",
        stop = "Do not send the entire team away from our carrier.",
    },
    TWINPEAKS = {
        win = "Protect our carrier and deny the enemy offense route.",
        even = "Collapse on EFC with healer control while maintaining carrier peel.",
        lose = "Group offense; secure return and escort the cap.",
        emergency = "Kill EFC now and trade defense only for a real cap window.",
        stop = "Do not split offense into separate routes.",
    },
    TEMPLE = {
        win = "Protect carriers near high-value space and prepare replacement pickups.",
        even = "Control center and secure the next loose orb.",
        lose = "Kill the highest-value enemy carrier, recover the orb, then regroup center.",
        emergency = "Delete an enemy carrier and deny center ticks immediately.",
        stop = "Do not stack every friendly carrier in one kill zone.",
    },
    SILVERSHARD = {
        win = "Escort the scoring cart and rotate before the next cart becomes active.",
        even = "Fight on the cart; control switches before the enemy route locks.",
        lose = "Delay the enemy scoring cart and take the shortest recoverable route.",
        emergency = "Stop the final turn-in. Leave dead carts immediately.",
        stop = "Do not fight off-cart after the route is decided.",
    },
    DEEPHAUL = {
        win = "Stay with our cart and assign a separate delay group.",
        even = "Escort ours, threaten theirs, and use Crystal only as a force multiplier.",
        lose = "Turn the enemy cart before investing in secondary objectives.",
        emergency = "Stop enemy cart progress now; abandon low-value side fights.",
        stop = "Do not leave our cart for Crystal without coverage.",
    },
    SEETHING = {
        win = "Rotate early to clean spawns and protect the cap channel.",
        even = "Split only after the next spawn is known.",
        lose = "Group for the next active node and deny free channels.",
        emergency = "Reach the next spawn first; road fights cannot recover the score.",
        stop = "Do not remain at an exhausted node.",
    },
}

function Doctrine:Get(mapKey)
    return doctrine[mapKey] or {
        win = "Protect the current win condition.",
        even = "Win the next objective cleanly.",
        lose = "Regroup and take the next objective.",
        emergency = "Play the objective immediately.",
        stop = "Avoid low-value fights.",
    }
end

function Doctrine:Recommend(mapKey, status, urgency)
    local entry = self:Get(mapKey)
    if (urgency or 0) >= 90 then return entry.emergency end
    if status == "WIN" then return entry.win end
    if status == "LOSE" then return entry.lose end
    return entry.even
end

KWR:RegisterModule("Doctrine", Doctrine)