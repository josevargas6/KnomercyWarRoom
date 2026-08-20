local _, KWR = ...

local Emphasis = {}
KWR.CommandEmphasis = Emphasis

local function attention(snapshot)
    local counts, names = {}, {}
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if enemy.guid then names[enemy.guid] = enemy.shortName or enemy.name end
    end
    for _, player in ipairs(snapshot.roster or {}) do
        local guid = player.currentTargetGUID
        if guid and names[guid] then counts[guid] = (counts[guid] or 0) + 1 end
    end
    local bestGUID, bestCount
    for guid, count in pairs(counts) do
        if not bestCount or count > bestCount
            or (count == bestCount and guid < bestGUID) then
            bestGUID, bestCount = guid, count
        end
    end
    return {
        target = bestGUID and KWR.Util:ShortName(names[bestGUID]) or nil,
        count = bestCount or 0,
        source = "observed_friendly_unit_targets",
        secondary = true,
        selectionAuthority = false,
    }
end

local function qualifiedRoute(snapshot, target)
    for _, eta in ipairs(snapshot.reporter and snapshot.reporter.etas or {}) do
        if eta.advantageQualified == true
            and (not target or KWR.Maps:CanonicalLocation(
                snapshot.context and snapshot.context.mapKey, eta.label)
                == KWR.Maps:CanonicalLocation(
                    snapshot.context and snapshot.context.mapKey, target)) then
            return {
                target = eta.label,
                friendlyETA = eta.friendlyETA,
                enemyETA = eta.enemyETA,
                advantage = eta.advantage,
                source = "observed_position_speed",
                confidence = eta.confidence,
            }
        end
    end
    return nil
end

function Emphasis:Build(snapshot, prediction, assignments, command)
    snapshot, prediction, command = snapshot or {}, prediction or {}, command or {}
    local objective = command.objectiveDecision and command.objectiveDecision.target
        or snapshot.responsePackage and snapshot.responsePackage.target
        or prediction.hotspot
    local localTarget = snapshot.combat and snapshot.combat.localTarget
    local hotspot = snapshot.reporter and snapshot.reporter.hotspot
    local threat
    if localTarget and (localTarget.name or localTarget.shortName) then
        threat = {
            label = KWR.Util:ShortName(localTarget.name or localTarget.shortName),
            source = "observed_local_target",
            confidence = localTarget.confidence or "HIGH",
        }
    elseif hotspot and (hotspot.total or 0) > 0 and hotspot.confidence ~= "NONE" then
        threat = {
            label = hotspot.label,
            source = "fresh_observed_pressure",
            confidence = hotspot.confidence,
        }
    end
    local timerSeconds = prediction.captureDeadline or prediction.timeToWin
    local execution = snapshot.executionCommand or {}
    local commandSignature = KWR.Util:Text(command.signature, "", 240)
    local consistent = commandSignature ~= ""
        and execution.canonicalCommandSignature == commandSignature
        and execution.commandAction == command.action
    return {
        source = "canonical_command",
        canonicalSignature = commandSignature,
        action = KWR.Util:Text(command.action, "Verify battlefield state.", 180),
        objective = KWR.Util:Text(objective, "", 48),
        threat = threat,
        route = qualifiedRoute(snapshot, objective),
        timer = timerSeconds and {
            seconds = math.max(0, timerSeconds),
            source = prediction.timeModel and "verified_or_reviewed_score_model"
                or "verified_prediction",
            confidence = prediction.confidence or "NONE",
        } or nil,
        attention = attention(snapshot),
        confidence = command.confidence or prediction.confidence or "NONE",
        consistency = {
            ok = consistent,
            canonicalSignature = commandSignature,
            executionSignature = execution.signature,
            suppressedSecondary = not consistent,
        },
    }
end

KWR:RegisterModule("CommandEmphasis", Emphasis)
