local _, KWR = ...

local Builder = {}
KWR.BoardStateBuilder = Builder

local function keyFor(row)
    return KWR.Util:Text(row and (row.guid or row.name or row.label), "unknown", 80)
end

local function shortLabel(row, fallback)
    return KWR.Util:Text(row and (row.shortName or row.name or row.label), fallback, 64)
end

local function roleOf(row)
    return KWR.CombatSpells:Role(row and row.spec, row and row.role)
end

local function confidenceFor(row, fallback)
    if not row then return "UNKNOWN" end
    if row.confidence then return KWR.BoardStateTypes:Confidence(row.confidence) end
    if row.visible == true or row.localRange == true or row.localEngaged == true then
        return "CONFIRMED"
    end
    return fallback or "INFERRED"
end

function Builder:Build(snapshot, factStore)
    snapshot = snapshot or {}
    local facts = factStore and factStore.facts or {}
    local board = {
        revision = snapshot.revision or snapshot.capturedAt or KWR.Util:Now(),
        generatedAt = KWR.Util:Now(),
        context = KWR.Util:Copy(snapshot.context or {}),
        score = KWR.Util:Copy(snapshot.score or {}),
        objectives = {},
        enemies = {},
        friendlies = {},
        facts = {},
        summary = {},
    }

    for index, fact in ipairs(facts) do
        KWR.BoardStateTypes:AddBounded(board.facts, {
            id = fact.id or KWR.BoardStateTypes:EvidenceID(fact.type, fact.subject, index),
            type = fact.type,
            subject = fact.subject,
            confidence = KWR.BoardStateTypes:Confidence(fact.confidence),
            observedAt = fact.observedAt,
            source = fact.source,
        }, "facts")
    end

    for index, objective in ipairs(snapshot.objectives or {}) do
        KWR.BoardStateTypes:AddBounded(board.objectives, {
            id = keyFor(objective),
            label = shortLabel(objective, "Objective"),
            owner = KWR.Util:Text(objective.owner, "UNKNOWN", 24),
            state = KWR.Util:Text(objective.state, "UNKNOWN", 32),
            kind = KWR.Util:Text(objective.kind, board.context.kind or "OBJECTIVE", 32),
            priority = KWR.Util:Number(objective.priority, index) or index,
            confidence = confidenceFor(objective, "UNKNOWN"),
            evidenceID = KWR.BoardStateTypes:EvidenceID("objective", keyFor(objective), index),
            x = KWR.Util:Number(objective.x, nil),
            y = KWR.Util:Number(objective.y, nil),
        }, "objectives")
    end

    for index, enemy in ipairs(snapshot.enemies or {}) do
        KWR.BoardStateTypes:AddBounded(board.enemies, {
            source = enemy,
            id = keyFor(enemy),
            guid = enemy.guid,
            name = enemy.name,
            shortName = shortLabel(enemy, "Enemy"),
            role = roleOf(enemy),
            spec = enemy.spec,
            classFile = enemy.classFile,
            visible = enemy.visible == true,
            localRange = enemy.localRange == true or enemy.localEngaged == true,
            localEngaged = enemy.localEngaged == true,
            healthPercent = KWR.Util:Number(enemy.healthPercent, nil),
            freeCasting = enemy.freeCasting == true
                or (enemy.currentCast and enemy.currentCast.freeCasting == true)
                or enemy.priorityCast ~= nil
                or (enemy.combat and enemy.combat.priorityCast ~= nil),
            killable = enemy.killable == true
                or (enemy.combat and enemy.combat.killable == true),
            overextended = enemy.overextended == true
                or (enemy.combat and enemy.combat.overextended == true),
            carrier = enemy.carrier == true,
            objectiveThreat = enemy.objectiveThreat == true or enemy.nearObjective == true,
            stealthThreat = enemy.stealthThreat == true or enemy.missingStealth == true,
            healerPressure = enemy.healerPressure == true,
            cooldownWindow = enemy.cooldownWindow == true,
            confidence = confidenceFor(enemy, "INFERRED"),
            evidenceID = KWR.BoardStateTypes:EvidenceID("enemy", keyFor(enemy), index),
        }, "enemies")
    end

    for index, player in ipairs(snapshot.roster or {}) do
        KWR.BoardStateTypes:AddBounded(board.friendlies, {
            source = player,
            id = keyFor(player),
            guid = player.guid,
            name = player.name,
            shortName = shortLabel(player, "Player"),
            role = roleOf(player),
            spec = player.spec,
            classFile = player.classFile,
            dead = player.dead == true,
            connected = player.connected ~= false,
            assignment = player.assignment,
            location = player.location,
            currentTargetGUID = player.currentTargetGUID,
            confidence = confidenceFor(player, "CONFIRMED"),
            evidenceID = KWR.BoardStateTypes:EvidenceID("friendly", keyFor(player), index),
        }, "friendlies")
    end

    board.summary = {
        enemyCount = #board.enemies,
        friendlyCount = #board.friendlies,
        objectiveCount = #board.objectives,
        mapKey = board.context.mapKey or "UNKNOWN",
        mapKind = board.context.kind or "UNKNOWN",
    }
    return board
end

KWR:RegisterModule("BoardStateBuilder", Builder)