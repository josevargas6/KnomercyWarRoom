local _, KWR = ...

local RosterPresentation = {}
KWR.RosterPresentation = RosterPresentation

local function trackerText(value, fallback, maxLength)
    return KWR.Util:TextClip(value, fallback, maxLength)
end

function RosterPresentation:SpecLabel(entity)
    local spec = KWR.Util:Text(
        entity and entity.spec, "Unknown", 28)
    if entity and entity.specSource == "historical" then
        return spec .. " (HIST)"
    end
    return spec
end

function RosterPresentation:EnemyAction(
    enemy, assignment, mapKey, includeObserved)
    local cast = enemy and enemy.priorityCast
    if cast then
        return {
            text = trackerText(cast.response, "STOP", 10)
                .. ": "
                .. trackerText(
                    cast.name, "PRIORITY CAST", 38),
            tone = "red",
            combatTone = "STOP",
            border = "STOP",
            kind = "CAST",
        }
    end

    local defensive = enemy and enemy.defensivesActive
        and enemy.defensivesActive[1]
    if defensive then
        return {
            text = trackerText(
                defensive.response, "WAIT", 10)
                .. ": "
                .. trackerText(
                    defensive.name, "DEFENSIVE ACTIVE", 38),
            tone = "orange",
            combatTone = "IMMUNE",
            border = "IMMUNE",
            kind = "DEFENSIVE",
        }
    end

    local fightMode = assignment and assignment.fightMode
    if fightMode == "KILL" then
        return {
            text = "KILL",
            tone = "red",
            combatTone = "KILL",
            border = "KILL",
            kind = "KILL",
        }
    end
    if fightMode == "PRESS" then
        return {
            text = "PRESS",
            tone = "orange",
            combatTone = "STOP",
            border = "STOP",
            kind = "PRESS",
        }
    end
    if assignment and assignment.ccActor then
        return {
            text = "CC "
                .. trackerText(
                    assignment.ccActor, "OPEN", 14),
            tone = "purple",
            combatTone = "STOP",
            border = "STOP",
            kind = "CONTROL",
        }
    end

    if enemy and enemy.carrier then
        return {
            text = "CARRIER"
                .. ((enemy.carrierStacks or 0) > 0
                    and (" x"
                        .. tostring(enemy.carrierStacks))
                    or ""),
            tone = "gold",
            combatTone = "CARRY",
            border = "CARRY",
            kind = "CARRIER",
        }
    end
    if enemy and enemy.trinketState == "ON_COOLDOWN" then
        return {
            text = "TRINKET DOWN",
            tone = "green",
            border = "border",
            kind = "TRINKET",
        }
    end

    local cooldown = trackerText(
        enemy and enemy.cooldownText, "", 56)
    if cooldown ~= "" and cooldown ~= "UNKNOWN"
        and cooldown ~= "NO SAFE FEED" then
        return {
            text = cooldown,
            tone = "yellow",
            border = "border",
            kind = "COOLDOWN",
        }
    end

    if includeObserved then
        return {
            text = KWR.EnemyIntel:DescribeLocation(
                enemy, mapKey, true),
            tone = "muted",
            border = "border",
            kind = "OBSERVED",
        }
    end
    return {
        text = "--",
        tone = "muted",
        border = "border",
        kind = "NONE",
    }
end